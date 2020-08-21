package main

import (
	"context"
	"fmt"
	"io"
	"os"
	"strings"
	"sync"
	"time"

	"github.com/streadway/amqp"
	"github.com/thanhpk/randstr"
	"golang.org/x/xerrors"
)

var (
	ErrPublisherConfirmFailed = xerrors.New("Publisher confirm failed")
	ErrDialFailed             = xerrors.New("Dial failed")
	ErrChannelOpenFailed      = xerrors.New("Channel open failed")
	ErrPublishFailed          = xerrors.New("Publish failed")
	ErrClosed                 = xerrors.New("Session closed")
	ErrIncorrectConsumerId    = xerrors.New("Incorrect Consumer Id")
)

const (
	hookDial                        = "hook_dial"
	hookRetry                       = "hook_retry"
	hookRetryPublish                = "hook_retry_publish"
	hookRetryAcknowledge            = "hook_retry_acknowledge"
	hookRetryReject                 = "hook_retry_reject"
	hookRetryReQueue                = "hook_retry_requeue"
	hookRetryConsume                = "hook_retry_consume"
	hookUndeliverable               = "hook_undeliverable"
	hookFlow                        = "hook_flow_closed"
	hookPublisherConfirmTimeout     = "hook_publisher_confirm_timeout"
	hookConnectionBlocked           = "hook_connection_blocked"
	hookPublishTimeout              = "hook_publish_timeout"
	hookAcknowledgeTimeout          = "hook_acknowledge_timeout"
	hookRejectTimeout               = "hook_reject_timeout"
	hookReQueueTimeout              = "hook_requeue_timeout"
	hookConsumeTimeout              = "hook_consume_timeout"
	hookDeliveryCancelRequeue       = "hook_delivery_cancel_requeue"
	hookDeliveryCancelRequeueFailed = "hook_delivery_cancel_requeue_failed"
	hookDeliveryCancelRequeueOk     = "hook_delivery_cancel_requeue_ok"
	hookChannelReadTimeout          = "hook_channel_read_timeout"
	hookChannelCreationFailed       = "hook_channel_creation_failed"
	hookConsumerCreationFailed      = "hook_consumer_creation_failed"
	hookConsumerCreationCanceled    = "hook_consumer_creation_canceled"
	hookDeliveryCanceled            = "hook_delivery_canceled"
	hookDeliveryRetry               = "hook_delivery_retry"
)

type Session interface {
	io.Closer

	connection(ctx context.Context) (*amqp.Connection, error)
	channel(ctx context.Context) (*amqp.Channel, error)
	endpoint(ctx context.Context) (string, error)
	addHook(hookName string, fn hookFn) bool
}

type Publisher interface {
	Session

	Publish(ctx context.Context, exchange string, routingKey string, publishing amqp.Publishing) error
}

type Consumer interface {
	Session

	Consume(ctx context.Context) (<-chan Delivery, error)
	Acknowledge(ctx context.Context, delivery Delivery) error
	Reject(ctx context.Context, delivery Delivery) error
	ReQueue(ctx context.Context, delivery Delivery) error
}

type Delivery struct {
	Body        []byte
	ConsumerId  string
	DeliveryTag uint64
}

type communicator interface {
	Publisher
	Consumer
}

type hookFn func(args ...interface{})

type sessionFactoryFn func(ctx context.Context) (Session, error)

type UndeliverableHandlerFn func(amqp.Return)

func NewConsumer(ctx context.Context, endpoint string, username string, password string, vhost string, queue string, prefetch int, connectionTimeout time.Duration, backoff time.Duration, maxRetry int, perOperationTimeout time.Duration) (Consumer, error) {

	var sessionFactory sessionFactoryFn = func(ctx context.Context) (Session, error) {
		result, err := newBasicSession(ctx, endpoint, username, password, vhost, prefetch, queue)
		if err != nil {
			return nil, err
		}
		if result == nil {
			return nil, context.Canceled
		}

		result = newOperationTimeoutSession(nil, result, perOperationTimeout)

		return result, nil
	}

	result := newRetrySession(connectionTimeout, backoff, maxRetry, sessionFactory)

	return result, nil
}

func NewPublisher(ctx context.Context, endpoint string, username string, password string, vhost string, confirm bool, undeliverableHandler UndeliverableHandlerFn, connectionTimeout time.Duration, backoff time.Duration, maxRetry int, perPublishTimeout time.Duration) (Publisher, error) {

	var sessionFactory sessionFactoryFn = func(ctx context.Context) (Session, error) {
		var result Publisher

		result, err := newBasicSession(ctx, endpoint, username, password, vhost, 0, "")
		if err != nil {
			return nil, err
		}
		if result == nil {
			return nil, context.Canceled
		}

		if confirm {
			result, err = newPublisherConfirmSession(ctx, result, true)
			if err != nil {
				return nil, err
			}
			if result == nil {
				return nil, context.Canceled
			}
		}

		result, err = newFlowControlSession(ctx, result)
		if err != nil {
			return nil, err
		}
		if result == nil {
			return nil, context.Canceled
		}

		result, err = newUndeliverableCaptureSession(ctx, result, undeliverableHandler)
		if err != nil {
			return nil, err
		}
		if result == nil {
			return nil, context.Canceled
		}

		result = newOperationTimeoutSession(result, nil, perPublishTimeout)

		return result, nil
	}

	result := newRetrySession(connectionTimeout, backoff, maxRetry, sessionFactory)

	return result, nil
}

type retrySession struct {
	factory                         sessionFactoryFn
	s                               Session
	rawCh                           chan Delivery
	rawChConsumer                   Consumer
	rawChCanceler                   chan struct{}
	rawChWg                         sync.WaitGroup
	ch                              chan Delivery
	m                               sync.Mutex
	newSessions                     chan *retrySessionFactoryResult
	newChannels                     chan *retrySessionChannelResult
	wg                              sync.WaitGroup
	done                            context.Context
	doneCancel                      context.CancelFunc
	connectionTimeout               time.Duration
	backoff                         time.Duration
	newSessionAvailable             chan struct{}
	newChannelAvailable             chan struct{}
	maxRetry                        int
	backoffTicker                   *time.Ticker
	dialHooks                       []hookFn
	retryHooks                      []hookFn
	publishRetryHooks               []hookFn
	acknowledgeRetryHooks           []hookFn
	rejectRetryHooks                []hookFn
	requeueRetryHooks               []hookFn
	consumeRetryHooks               []hookFn
	blockedHooks                    []hookFn
	hookRequests                    []retrySessionHookRequests
	channelCreationFailedHooks      []hookFn
	consumerCreationFailedHooks     []hookFn
	consumerCreationCanceledHooks   []hookFn
	deliveryCanceledHooks           []hookFn
	hookDeliveryCancelRequeue       []hookFn
	hookDeliveryCancelRequeueFailed []hookFn
	hookDeliveryCancelRequeueOk     []hookFn
	deliveryRetryHooks              []hookFn
	pending                         sync.WaitGroup
	closing                         chan struct{}
}

type retrySessionFactoryResult struct {
	s   Session
	err error
}

type retrySessionChannelResult struct {
	consumer Consumer
	ch       <-chan Delivery
	err      error
}

type retrySessionHookRequests struct {
	hookName string
	hook     hookFn
}

func newRetrySession(connectionTimeout time.Duration, backoff time.Duration, maxRetry int, factory sessionFactoryFn) communicator {
	result := &retrySession{
		factory:             factory,
		newSessions:         make(chan *retrySessionFactoryResult),
		newChannels:         make(chan *retrySessionChannelResult),
		connectionTimeout:   connectionTimeout,
		backoff:             backoff,
		newSessionAvailable: make(chan struct{}),
		newChannelAvailable: make(chan struct{}),
		maxRetry:            maxRetry,
		backoffTicker:       time.NewTicker(backoff),
		closing:             make(chan struct{}),
	}
	result.done, result.doneCancel = context.WithCancel(context.Background())

	result.wg.Add(2)
	go result.makeConnections()
	go result.makeChannels()

	return result
}

func (s *retrySession) acquirePending() bool {
	s.m.Lock()
	defer s.m.Unlock()

	select {
	case <-s.closing:
		return false

	default:
		s.pending.Add(1)
		return true
	}
}

func (s *retrySession) releasePending() {
	s.pending.Done()
}

func (s *retrySession) ReQueue(ctx context.Context, delivery Delivery) error {

	if !s.acquirePending() {
		return ErrClosed
	}
	defer s.releasePending()

	var err error

	for retry := 0; s.maxRetry < 0 || retry <= s.maxRetry; retry++ {
		if err != nil {
			s.fireRetryHookListeners(err)
			s.fireRetryReQueueHookListeners(err)
		}

		select {
		case <-ctx.Done():
			if ctx.Err() == context.DeadlineExceeded {
				return context.DeadlineExceeded
			}
			return nil

		case <-s.done.Done():
			return ErrClosed

		default:
		}

		err = s.requeueNoRetry(ctx, delivery)
		if err == nil {
			return nil
		}

		s.cancelableSleep(ctx, s.backoff)
	}

	return err
}

func (s *retrySession) Reject(ctx context.Context, delivery Delivery) error {

	if !s.acquirePending() {
		return ErrClosed
	}
	defer s.releasePending()

	var err error

	for retry := 0; s.maxRetry < 0 || retry <= s.maxRetry; retry++ {
		if err != nil {
			s.fireRetryHookListeners(err)
			s.fireRetryRejectHookListeners(err)
		}

		select {
		case <-ctx.Done():
			if ctx.Err() == context.DeadlineExceeded {
				return context.DeadlineExceeded
			}
			return nil

		case <-s.done.Done():
			return ErrClosed

		default:
		}

		err = s.rejectNoRetry(ctx, delivery)
		if err == nil {
			return nil
		}

		s.cancelableSleep(ctx, s.backoff)
	}

	return err
}

func (s *retrySession) Consume(ctx context.Context) (<-chan Delivery, error) {
	if !s.acquirePending() {
		return nil, ErrClosed
	}
	defer s.releasePending()

	s.m.Lock()
	defer s.m.Unlock()

	if s.ch != nil {
		return s.ch, nil
	}

	s.ch = make(chan Delivery)
	s.wg.Add(1)
	go s.realDeliverer()

	return s.ch, nil
}

func (s *retrySession) realDeliverer() {
	defer s.wg.Done()

	for retry := 0; s.maxRetry < 0 || retry <= s.maxRetry; retry++ {
		if retry > 0 {
			s.fireDeliveryRetryHook()
		}

		consumer, source, err := s.currentChannel(context.Background())
		if err != nil {
			if xerrors.Is(err, ErrClosed) {
				s.discardSession(consumer)
			} else {
				fmt.Fprintf(os.Stderr, "failed to create channel on retry with %v", err)
			}
			continue
		}

		doConsume := true
		for doConsume {
			select {
			case <-s.done.Done():
				close(s.ch)
				s.ch = nil
				return

			case delivery, ok := <-source:
				if !ok {
					s.discardChannel(source)
					doConsume = false
				} else {
					select {
					case <-s.done.Done():
						s.recoverDelivery(consumer, delivery)
						close(s.ch)
						s.ch = nil
						return

					case s.ch <- delivery:
					}
				}
			}
		}
	}
}

func (s *retrySession) Acknowledge(ctx context.Context, delivery Delivery) error {
	if !s.acquirePending() {
		return ErrClosed
	}
	defer s.releasePending()

	var err error

	for retry := 0; s.maxRetry < 0 || retry <= s.maxRetry; retry++ {
		if err != nil {
			s.fireRetryHookListeners(err)
			s.fireRetryAcknowledgeHookListeners(err)
		}

		select {
		case <-ctx.Done():
			if ctx.Err() == context.DeadlineExceeded {
				return context.DeadlineExceeded
			}
			return nil

		case <-s.done.Done():
			return ErrClosed

		default:
		}

		err = s.acknowledgeNoRetry(ctx, delivery)
		if err == nil {
			return nil
		}

		s.cancelableSleep(ctx, s.backoff)
	}

	return err
}

func (s *retrySession) Publish(ctx context.Context, exchange string, routingKey string, publishing amqp.Publishing) error {

	if !s.acquirePending() {
		return ErrClosed
	}
	defer s.releasePending()

	var err error

	for retry := 0; s.maxRetry < 0 || retry <= s.maxRetry; retry++ {
		if err != nil {
			s.fireRetryHookListeners(err)
			s.fireRetryPublishHookListeners(err)
		}

		select {
		case <-ctx.Done():
			if ctx.Err() == context.DeadlineExceeded {
				return context.DeadlineExceeded
			}
			return nil

		case <-s.done.Done():
			return ErrClosed

		default:
		}

		err = s.publishNoRetry(ctx, exchange, routingKey, publishing)
		if err == nil {
			return nil
		}

		s.cancelableSleep(ctx, s.backoff)
	}

	return err
}

func (s *retrySession) cancelableSleep(ctx context.Context, t time.Duration) {
	startTime := time.Now()

	for {
		select {
		case <-s.backoffTicker.C:
			if time.Now().Sub(startTime) >= t {
				return
			}

		case <-s.done.Done():
			return

		case <-ctx.Done():
			return
		}
	}
}

func (s *retrySession) requeueNoRetry(ctx context.Context, delivery Delivery) error {
	session, err := s.currentConsumer(ctx)
	if err != nil {
		return err
	}
	if session == nil {
		return nil
	}

	err = session.ReQueue(ctx, delivery)
	if err != nil {
		s.discardSession(session)
		return err
	}

	return nil
}

func (s *retrySession) rejectNoRetry(ctx context.Context, delivery Delivery) error {
	session, err := s.currentConsumer(ctx)
	if err != nil {
		return err
	}
	if session == nil {
		return nil
	}

	err = session.Reject(ctx, delivery)
	if err != nil {
		s.discardSession(session)
		return err
	}

	return nil
}

func (s *retrySession) acknowledgeNoRetry(ctx context.Context, delivery Delivery) error {
	session, err := s.currentConsumer(ctx)
	if err != nil {
		return err
	}
	if session == nil {
		return nil
	}

	err = session.Acknowledge(ctx, delivery)
	if err != nil {
		s.discardSession(session)
		return err
	}

	return nil
}

func (s *retrySession) publishNoRetry(ctx context.Context, exchange string, routingKey string, publishing amqp.Publishing) error {
	session, err := s.currentPublisher(ctx)
	if err != nil {
		return err
	}
	if session == nil {
		return nil
	}

	err = session.Publish(ctx, exchange, routingKey, publishing)
	if err != nil {
		s.discardSession(session)
		return err
	}

	return nil
}

func (s *retrySession) connection(ctx context.Context) (*amqp.Connection, error) {
	if !s.acquirePending() {
		return nil, ErrClosed
	}
	defer s.releasePending()

	session, err := s.currentSession(ctx)
	if err != nil {
		return nil, err
	}
	if session == nil {
		return nil, nil
	}

	return session.connection(ctx)
}

func (s *retrySession) channel(ctx context.Context) (*amqp.Channel, error) {
	if !s.acquirePending() {
		return nil, ErrClosed
	}
	defer s.releasePending()

	session, err := s.currentSession(ctx)
	if err != nil {
		return nil, err
	}
	if session == nil {
		return nil, nil
	}

	return session.channel(ctx)
}

func (s *retrySession) endpoint(ctx context.Context) (string, error) {
	if !s.acquirePending() {
		return "", ErrClosed
	}
	defer s.releasePending()

	session, err := s.currentSession(ctx)
	if err != nil {
		return "", err
	}
	if session == nil {
		return "", nil
	}

	return session.endpoint(ctx)
}

func (s *retrySession) Close() error {
	if !s.beginClose() {
		return nil
	}

	s.pending.Wait()

	s.doneCancel()
	s.wg.Wait()

	s.m.Lock()
	defer s.m.Unlock()

	var err error

	s.backoffTicker.Stop()

	if s.s != nil {
		err = s.s.Close()

		s.s = nil
	}

	s.factory = nil

	return err
}

func (s *retrySession) beginClose() bool {
	s.m.Lock()
	defer s.m.Unlock()

	select {
	case <-s.closing:
		return false

	default:
		close(s.closing)
		return true
	}
}

func (s *retrySession) currentPublisher(ctx context.Context) (Publisher, error) {
	session, err := s.currentSession(ctx)
	if err != nil {
		return nil, err
	}

	return session.(Publisher), nil
}

func (s *retrySession) currentConsumer(ctx context.Context) (Consumer, error) {
	session, err := s.currentSession(ctx)
	if err != nil {
		return nil, err
	}

	return session.(Consumer), nil
}

func (s *retrySession) currentChannel(ctx context.Context) (Consumer, <-chan Delivery, error) {
	for {
		consumer, ch := s.getChannel()
		if ch != nil {
			return consumer, ch, nil
		}

		notifyNewChannel := s.notifyOnNewChannel()

		select {
		case result := <-s.newChannels:
			if result != nil {
				if result.err != nil {
					return nil, nil, result.err
				}

				resultChannel, ok := s.putChannel(result.consumer, result.ch)
				if !ok {
					s.asyncCloseSession(result.consumer)
				}

				return result.consumer, resultChannel, nil
			}

		case <-ctx.Done():
			if ctx.Err() == context.DeadlineExceeded {
				return nil, nil, context.DeadlineExceeded
			}
			return nil, nil, nil

		case <-s.done.Done():
			return nil, nil, nil

		case <-notifyNewChannel:
		}
	}
}

func (s *retrySession) currentSession(ctx context.Context) (Session, error) {
	for {
		session := s.getSession()
		if session != nil {
			return session, nil
		}

		notifyNewSession := s.notifyOnNewSession()

		select {
		case result := <-s.newSessions:
			if result != nil {
				if result.err != nil {
					return nil, result.err
				}

				resultSession, ok := s.putSession(result.s)
				if !ok {
					s.asyncCloseSession(result.s)
				}

				return resultSession, nil
			}

		case <-ctx.Done():
			if ctx.Err() == context.DeadlineExceeded {
				return nil, context.DeadlineExceeded
			}
			return nil, nil

		case <-notifyNewSession:
		}
	}
}

func (s *retrySession) asyncCloseSession(session Session) {
	go func() {
		err := session.Close()
		if err != nil {
			fmt.Fprintf(os.Stderr, "Failed to close session with: %v", err)
		}
	}()
}

func (s *retrySession) getChannel() (Consumer, <-chan Delivery) {
	s.m.Lock()
	defer s.m.Unlock()

	return s.rawChConsumer, s.rawCh
}

func (s *retrySession) putChannel(consumer Consumer, ch <-chan Delivery) (<-chan Delivery, bool) {
	s.m.Lock()
	defer s.m.Unlock()

	if s.rawCh != nil {
		return s.rawCh, false
	}

	s.rawChCanceler = make(chan struct{})
	s.rawCh = s.proxyChannel(consumer, ch)
	s.rawChConsumer = consumer

	s.wg.Add(1)
	go s.watchConsumerCancel(consumer, s.rawCh)

	close(s.newChannelAvailable)

	return s.rawCh, true
}

func (s *retrySession) proxyChannel(consumer Consumer, ch <-chan Delivery) chan Delivery {
	result := make(chan Delivery)

	s.wg.Add(1)
	s.rawChWg.Add(1)
	go func() {
		defer s.wg.Done()
		defer s.rawChWg.Done()

		for {
			select {
			case <-s.done.Done():
				close(result)
				return

			case <-s.rawChCanceler:
				return

			case delivery, ok := <-ch:
				if !ok {
					close(result)
					return
				}

				select {
				case <-s.rawChCanceler:
					s.recoverDelivery(consumer, delivery)
					close(result)
					return

				case <-s.done.Done():
					s.recoverDelivery(consumer, delivery)
					close(result)
					return

				case result <- delivery:
				}
			}
		}
	}()

	return result
}

func (s *retrySession) recoverDelivery(consumer Consumer, delivery Delivery) {
	go func() {
		s.fireDeliveryCancelRequeueHook()
		err := consumer.ReQueue(context.Background(), delivery)
		if err != nil {
			s.fireDeliveryCancelRequeueHookFailed()
			fmt.Fprintf(os.Stderr, "WARN failed to requeue message with %v\n", err)
		} else {
			s.fireDeliveryCancelRequeueHookOk()
		}
	}()
}

func (s *retrySession) watchConsumerCancel(session Session, ch <-chan Delivery) {
	defer s.wg.Done()

	channel, err := session.channel(s.done)
	if err != nil {
		if !xerrors.Is(err, ErrClosed) {
			fmt.Fprintf(os.Stderr, "can not obtain session channel: %v\n", err)
		}
		s.discardSession(session)
		return
	}
	if channel == nil {
		return
	}

	canceler := channel.NotifyCancel(make(chan string, 1))

	select {
	case <-s.done.Done():
		return

	case <-canceler:
		s.fireCanceled()

		s.discardChannel(ch)
		return
	}
}

func (s *retrySession) fireCanceled() {
	s.m.Lock()
	defer s.m.Unlock()

	for _, hook := range s.deliveryCanceledHooks {
		hook()
	}
}

func (s *retrySession) getSession() Session {
	s.m.Lock()
	defer s.m.Unlock()

	return s.s
}

func (s *retrySession) putSession(session Session) (Session, bool) {
	s.m.Lock()
	defer s.m.Unlock()

	if s.s != nil {
		return s.s, false
	}

	s.s = session
	s.wg.Add(3)
	go s.watchChannelClose(session)
	go s.watchConnectionClose(session)
	go s.watchConnectionBlock(session)

	for _, hookRequest := range s.hookRequests {
		session.addHook(hookRequest.hookName, hookRequest.hook)
	}

	close(s.newSessionAvailable)

	return session, true
}

func (s *retrySession) watchConnectionBlock(session Session) {
	defer s.wg.Done()

	connection, err := session.connection(s.done)
	if err != nil {
		fmt.Fprintf(os.Stderr, "can not obtain session connection: %v\n", err)
		s.discardSession(session)
		return
	}
	if connection == nil {
		return
	}

	ch := connection.NotifyBlocked(make(chan amqp.Blocking, 1))

	select {
	case <-s.done.Done():
		return

	case blocking := <-ch:
		s.fireBlocked(blocking.Reason)

		s.discardSession(session)
		return
	}
}

func (s *retrySession) fireBlocked(reason string) {
	s.m.Lock()
	defer s.m.Unlock()

	for _, hook := range s.blockedHooks {
		hook(reason)
	}
}

func (s *retrySession) watchChannelClose(session Session) {
	defer s.wg.Done()

	channel, err := session.channel(s.done)
	if err != nil {
		fmt.Fprintf(os.Stderr, "can not obtain session channel: %v\n", err)
		s.discardSession(session)
		return
	}
	if channel == nil {
		return
	}

	ch := channel.NotifyClose(make(chan *amqp.Error, 1))

	select {
	case <-s.done.Done():
		return

	case err := <-ch:
		if err.Server {
			fmt.Fprintf(os.Stderr, "channel closed suddenly: %s\n", err.Reason)
		}

		s.discardSession(session)
		return
	}
}

func (s *retrySession) watchConnectionClose(session Session) {
	defer s.wg.Done()

	connection, err := session.connection(s.done)
	if err != nil {
		fmt.Fprintf(os.Stderr, "can not obtain session connection: %v\n", err)
		s.discardSession(session)
		return
	}
	if connection == nil {
		return
	}

	ch := connection.NotifyClose(make(chan *amqp.Error, 1))

	select {
	case <-s.done.Done():
		return

	case err := <-ch:
		if err.Server {
			fmt.Fprintf(os.Stderr, "connection closed suddenly: %s\n", err.Reason)
		}

		s.discardSession(session)
		return
	}
}
func (s *retrySession) discardSession(session Session) {
	s.m.Lock()
	defer s.m.Unlock()

	s.discardSessionNoLock(session)
}

func (s *retrySession) discardSessionNoLock(session Session) bool {
	if s.s == session {
		if session != nil {
			s.asyncCloseSession(session)
		}
		s.s = nil
		s.newSessionAvailable = make(chan struct{})
		return true
	}

	return false
}

func (s *retrySession) discardChannel(ch <-chan Delivery) bool {
	s.m.Lock()
	defer s.m.Unlock()

	if s.rawCh == ch {
		s.discardSessionNoLock(s.rawChConsumer)

		close(s.rawChCanceler)
		s.rawChWg.Wait()

		s.rawCh = nil
		s.rawChConsumer = nil
		s.newChannelAvailable = make(chan struct{})

		return true
	}

	return false
}

func (s *retrySession) notifyOnNewSession() chan struct{} {
	s.m.Lock()
	defer s.m.Unlock()

	return s.newSessionAvailable
}

func (s *retrySession) notifyOnNewChannel() chan struct{} {
	s.m.Lock()
	defer s.m.Unlock()

	return s.newChannelAvailable
}

func (s *retrySession) makeChannels() {
	defer s.wg.Done()

	for {
		select {
		case <-s.done.Done():
			return

		default:
		}

		s.makeChannelsLoop()
	}
}

func (s *retrySession) makeChannelsLoop() {
	ctx, cancel := context.WithTimeout(s.done, s.connectionTimeout)
	defer cancel()

	select {
	case <-s.done.Done():
		return

	case s.newChannels <- nil:
	}

	consumer, err := s.currentConsumer(ctx)
	if err != nil {
		s.fireConsumerCreationFailed()
		return
	}

	ch, err := consumer.Consume(ctx)
	if err != nil {
		s.discardSession(consumer)
		s.fireConsumerCreationFailed()
		select {
		case <-s.done.Done():
			return

		case s.newChannels <- &retrySessionChannelResult{consumer: consumer, err: err}:
		}
		return
	}
	if ch == nil {
		s.discardSession(consumer)
		s.fireConsumerCreationCanceled()
		return
	}

	select {
	case <-s.done.Done():
		s.discardSession(consumer)
		return

	case s.newChannels <- &retrySessionChannelResult{consumer: consumer, ch: ch}:
	}
}

func (s *retrySession) makeConnections() {
	defer s.wg.Done()

	for {
		select {
		case <-s.done.Done():
			return

		default:
		}

		s.makeConnectionsLoop()
	}
}

func (s *retrySession) makeConnectionsLoop() {
	ctx, cancel := context.WithTimeout(s.done, s.connectionTimeout)
	defer cancel()

	factory := s.getFactory()
	if factory == nil {
		return
	}

	select {
	case <-s.done.Done():
		return

	case s.newSessions <- nil:
	}

	session, err := factory(ctx)
	for _, hook := range s.getDialHookListeners() {
		hook(err)
	}
	if err != nil {
		select {
		case <-s.done.Done():
			return

		case s.newSessions <- &retrySessionFactoryResult{err: err}:
		}
		return
	}
	if session == nil {
		return
	}

	select {
	case <-s.done.Done():
		go func() {
			err := session.Close()
			if err != nil {
				fmt.Fprintf(os.Stderr, "ERR: failed closing session with %v\n", err)
			}
		}()
		return

	case s.newSessions <- &retrySessionFactoryResult{s: session}:
	}
}

func (s *retrySession) addHook(name string, fn hookFn) bool {
	s.m.Lock()
	defer s.m.Unlock()

	if name == hookDial {
		s.dialHooks = append(s.dialHooks, fn)
		return true
	}

	if name == hookRetry {
		s.retryHooks = append(s.retryHooks, fn)
		return true
	}

	if name == hookRetryPublish {
		s.publishRetryHooks = append(s.publishRetryHooks, fn)
		return true
	}

	if name == hookRetryConsume {
		s.consumeRetryHooks = append(s.publishRetryHooks, fn)
		return true
	}

	if name == hookRetryAcknowledge {
		s.acknowledgeRetryHooks = append(s.publishRetryHooks, fn)
		return true
	}

	if name == hookRetryReject {
		s.rejectRetryHooks = append(s.publishRetryHooks, fn)
		return true
	}

	if name == hookRetryReQueue {
		s.requeueRetryHooks = append(s.publishRetryHooks, fn)
		return true
	}

	if name == hookConnectionBlocked {
		s.blockedHooks = append(s.blockedHooks, fn)
		return true
	}

	if name == hookChannelCreationFailed {
		s.channelCreationFailedHooks = append(s.channelCreationFailedHooks, fn)
		return true
	}

	if name == hookConsumerCreationFailed {
		s.consumerCreationFailedHooks = append(s.consumerCreationFailedHooks, fn)
		return true
	}

	if name == hookConsumerCreationCanceled {
		s.consumerCreationCanceledHooks = append(s.consumerCreationCanceledHooks, fn)
		return true
	}

	if name == hookDeliveryCanceled {
		s.deliveryCanceledHooks = append(s.deliveryCanceledHooks, fn)
		return true
	}

	if name == hookDeliveryRetry {
		s.deliveryRetryHooks = append(s.deliveryRetryHooks, fn)
		return true
	}

	result := false

	if name == hookDeliveryCancelRequeue {
		s.hookDeliveryCancelRequeue = append(s.hookDeliveryCancelRequeue, fn)
		result = true
	}

	if name == hookDeliveryCancelRequeueFailed {
		s.hookDeliveryCancelRequeueFailed = append(s.hookDeliveryCancelRequeueFailed, fn)
		result = true
	}

	if name == hookDeliveryCancelRequeueOk {
		s.hookDeliveryCancelRequeueOk = append(s.hookDeliveryCancelRequeueOk, fn)
		result = true
	}

	s.hookRequests = append(s.hookRequests, retrySessionHookRequests{
		hookName: name,
		hook:     fn,
	})

	if s.s != nil {
		return s.s.addHook(name, fn) || result
	}

	return result
}

func (s *retrySession) fireDeliveryRetryHook() {
	s.m.Lock()
	defer s.m.Unlock()

	for _, hook := range s.deliveryRetryHooks {
		hook()
	}
}

func (s *retrySession) fireChannelCreationFailed() {
	s.m.Lock()
	defer s.m.Unlock()

	for _, hook := range s.channelCreationFailedHooks {
		hook()
	}
}

func (s *retrySession) fireConsumerCreationFailed() {
	s.m.Lock()
	defer s.m.Unlock()

	for _, hook := range s.consumerCreationFailedHooks {
		hook()
	}
}

func (s *retrySession) fireConsumerCreationCanceled() {
	s.m.Lock()
	defer s.m.Unlock()

	for _, hook := range s.consumerCreationCanceledHooks {
		hook()
	}
}

func (s *retrySession) fireDeliveryCancelRequeueHook() {
	s.m.Lock()
	defer s.m.Unlock()

	for _, hook := range s.hookDeliveryCancelRequeue {
		hook()
	}
}

func (s *retrySession) fireDeliveryCancelRequeueHookOk() {
	s.m.Lock()
	defer s.m.Unlock()

	for _, hook := range s.hookDeliveryCancelRequeueOk {
		hook()
	}
}

func (s *retrySession) fireDeliveryCancelRequeueHookFailed() {
	s.m.Lock()
	defer s.m.Unlock()

	for _, hook := range s.hookDeliveryCancelRequeueFailed {
		hook()
	}
}

func (s *retrySession) fireRetryHookListeners(err error) {
	s.m.Lock()
	defer s.m.Unlock()

	for _, hook := range s.retryHooks {
		hook(err)
	}
}

func (s *retrySession) fireRetryPublishHookListeners(err error) {
	s.m.Lock()
	defer s.m.Unlock()

	for _, hook := range s.publishRetryHooks {
		hook(err)
	}
}

func (s *retrySession) fireRetryAcknowledgeHookListeners(err error) {
	s.m.Lock()
	defer s.m.Unlock()

	for _, hook := range s.acknowledgeRetryHooks {
		hook(err)
	}
}

func (s *retrySession) fireRetryRejectHookListeners(err error) {
	s.m.Lock()
	defer s.m.Unlock()

	for _, hook := range s.rejectRetryHooks {
		hook(err)
	}
}

func (s *retrySession) fireRetryReQueueHookListeners(err error) {
	s.m.Lock()
	defer s.m.Unlock()

	for _, hook := range s.requeueRetryHooks {
		hook(err)
	}
}

func (s *retrySession) fireRetryConsumeHookListeners(err error) {
	s.m.Lock()
	defer s.m.Unlock()

	for _, hook := range s.consumeRetryHooks {
		hook(err)
	}
}

func (s *retrySession) getDialHookListeners() []hookFn {
	s.m.Lock()
	defer s.m.Unlock()

	return s.dialHooks
}

func (s *retrySession) getFactory() sessionFactoryFn {
	s.m.Lock()
	defer s.m.Unlock()

	return s.factory
}

type operationTimeoutSession struct {
	publisher                       Publisher
	consumer                        Consumer
	done                            context.Context
	doneCancel                      context.CancelFunc
	wg                              sync.WaitGroup
	pending                         sync.WaitGroup
	closing                         chan struct{}
	publishHooks                    []hookFn
	acknowledgeHooks                []hookFn
	rejectHooks                     []hookFn
	requeueHooks                    []hookFn
	consumeHooks                    []hookFn
	hookDeliveryCancelRequeue       []hookFn
	hookDeliveryCancelRequeueFailed []hookFn
	hookDeliveryCancelRequeueOk     []hookFn
	hookChannelReadTimeout          []hookFn
	m                               sync.Mutex
	timeout                         time.Duration
	ch                              chan Delivery
}

func newOperationTimeoutSession(publisher Publisher, consumer Consumer, timeout time.Duration) communicator {
	result := &operationTimeoutSession{
		publisher: publisher,
		consumer:  consumer,
		timeout:   timeout,
		closing:   make(chan struct{}),
	}

	if consumer == nil && publisher == nil {
		panic("can not monitor both nil consumer,publisher")
	}

	if consumer != nil && publisher != nil && consumer.(Session) != publisher.(Session) {
		panic("two different publisher/consumers provided")
	}

	result.done, result.doneCancel = context.WithCancel(context.Background())

	return result
}

func (s *operationTimeoutSession) getSession() Session {
	if s.publisher != nil {
		return s.publisher
	}
	return s.consumer
}

func (s *operationTimeoutSession) connection(ctx context.Context) (*amqp.Connection, error) {
	if !s.addPending() {
		return nil, ErrClosed
	}
	defer s.releasePending()

	return s.getSession().connection(ctx)
}

func (s *operationTimeoutSession) channel(ctx context.Context) (*amqp.Channel, error) {
	if !s.addPending() {
		return nil, ErrClosed
	}
	defer s.releasePending()

	return s.getSession().channel(ctx)
}

func (s *operationTimeoutSession) endpoint(ctx context.Context) (string, error) {
	if !s.addPending() {
		return "", ErrClosed
	}
	defer s.releasePending()

	return s.getSession().endpoint(ctx)
}

func (s *operationTimeoutSession) addPending() bool {
	s.m.Lock()
	defer s.m.Unlock()

	select {
	case <-s.closing:
		return false

	default:
		s.pending.Add(1)
		return true
	}
}

func (s *operationTimeoutSession) releasePending() {
	s.pending.Done()
}

func (s *operationTimeoutSession) Close() error {
	if !s.beginClose() {
		return nil
	}

	s.pending.Wait()
	s.doneCancel()
	s.wg.Wait()

	return s.getSession().Close()
}

func (s *operationTimeoutSession) beginClose() bool {
	s.m.Lock()
	defer s.m.Unlock()

	select {
	case <-s.closing:
		return false

	default:
		close(s.closing)
		return true
	}
}

func (s *operationTimeoutSession) addHook(hookName string, fn hookFn) bool {
	s.m.Lock()
	defer s.m.Unlock()

	if hookName == hookPublishTimeout {
		s.publishHooks = append(s.publishHooks, fn)
		return true
	}

	if hookName == hookAcknowledgeTimeout {
		s.acknowledgeHooks = append(s.acknowledgeHooks, fn)
	}

	if hookName == hookRejectTimeout {
		s.rejectHooks = append(s.rejectHooks, fn)
	}

	if hookName == hookReQueueTimeout {
		s.requeueHooks = append(s.requeueHooks, fn)
	}

	if hookName == hookConsumeTimeout {
		s.consumeHooks = append(s.consumeHooks, fn)
	}

	if hookName == hookChannelReadTimeout {
		s.hookChannelReadTimeout = append(s.hookChannelReadTimeout, fn)
	}

	if hookName == hookDeliveryCancelRequeue {
		s.hookDeliveryCancelRequeue = append(s.hookDeliveryCancelRequeue, fn)
		s.getSession().addHook(hookName, fn)
		return true
	}

	if hookName == hookDeliveryCancelRequeueFailed {
		s.hookDeliveryCancelRequeueFailed = append(s.hookDeliveryCancelRequeueFailed, fn)
		s.getSession().addHook(hookName, fn)
		return true
	}

	if hookName == hookDeliveryCancelRequeueOk {
		s.hookDeliveryCancelRequeueOk = append(s.hookDeliveryCancelRequeueOk, fn)
		s.getSession().addHook(hookName, fn)
		return true
	}

	return s.getSession().addHook(hookName, fn)
}

func (s *operationTimeoutSession) fireChannelReadTimeout() {
	s.m.Lock()
	defer s.m.Unlock()

	for _, hook := range s.hookChannelReadTimeout {
		hook()
	}
}

func (s *operationTimeoutSession) fireDeliveryCancelRequeueHook() {
	s.m.Lock()
	defer s.m.Unlock()

	for _, hook := range s.hookDeliveryCancelRequeue {
		hook()
	}
}

func (s *operationTimeoutSession) fireDeliveryCancelRequeueHookOk() {
	s.m.Lock()
	defer s.m.Unlock()

	for _, hook := range s.hookDeliveryCancelRequeueOk {
		hook()
	}
}

func (s *operationTimeoutSession) fireDeliveryCancelRequeueHookFailed() {
	s.m.Lock()
	defer s.m.Unlock()

	for _, hook := range s.hookDeliveryCancelRequeueFailed {
		hook()
	}
}

func (s *operationTimeoutSession) firePublishHook() {
	s.m.Lock()
	defer s.m.Unlock()

	for _, hook := range s.publishHooks {
		hook()
	}
}

func (s *operationTimeoutSession) fireAcknowledgeHook() {
	s.m.Lock()
	defer s.m.Unlock()

	for _, hook := range s.acknowledgeHooks {
		hook()
	}
}

func (s *operationTimeoutSession) fireRejectHooks() {
	s.m.Lock()
	defer s.m.Unlock()

	for _, hook := range s.rejectHooks {
		hook()
	}
}

func (s *operationTimeoutSession) fireReQueueHooks() {
	s.m.Lock()
	defer s.m.Unlock()

	for _, hook := range s.requeueHooks {
		hook()
	}
}

func (s *operationTimeoutSession) fireConsumeHooks() {
	s.m.Lock()
	defer s.m.Unlock()

	for _, hook := range s.consumeHooks {
		hook()
	}
}

func (s *operationTimeoutSession) Consume(ctx context.Context) (<-chan Delivery, error) {

	if !s.addPending() {
		return nil, ErrClosed
	}
	defer s.releasePending()

	s.m.Lock()
	defer s.m.Unlock()

	if s.ch != nil {
		return s.ch, nil
	}

	newCtx, cancel := context.WithTimeout(ctx, s.timeout)
	defer cancel()

	type DeliveryCh <-chan Delivery
	result := make(chan DeliveryCh, 1)
	errChannel := make(chan error)

	s.wg.Add(1)
	go func() {
		defer s.wg.Done()

		ch, err := s.consumer.Consume(newCtx)
		result <- ch
		errChannel <- err
	}()

	select {
	case <-ctx.Done():
		if ctx.Err() == context.DeadlineExceeded {
			return nil, context.DeadlineExceeded
		}
		return nil, nil

	case <-newCtx.Done():
		if newCtx.Err() == context.DeadlineExceeded {
			s.fireConsumeHooks()
			return nil, context.DeadlineExceeded
		}
		return nil, nil

	case <-s.done.Done():
		return nil, ErrClosed

	case err := <-errChannel:
		if err != nil {
			return nil, err
		}
		source := <-result
		if source == nil {
			return nil, nil
		}
		s.ch = make(chan Delivery)
		s.wg.Add(1)
		go s.deliverer(source)

		return s.ch, nil
	}
}

func (s *operationTimeoutSession) deliverer(source <-chan Delivery) {
	defer s.wg.Done()

	lastDelivered := time.Now()

	t := time.NewTicker(s.timeout)
	defer t.Stop()

	for {
		select {
		case delivery, ok := <-source:
			if !ok {
				close(s.ch)
				s.ch = nil
				return
			}

			select {
			case s.ch <- delivery:
				lastDelivered = time.Now()

			case <-s.done.Done():
				s.recoverDelivery(delivery)
				close(s.ch)
				s.ch = nil
				return
			}

		case <-s.done.Done():
			close(s.ch)
			s.ch = nil
			return

		case <-t.C:
			if time.Now().Sub(lastDelivered) >= s.timeout {
				s.fireChannelReadTimeout()
				close(s.ch)
				s.ch = nil
				return
			}
		}
	}
}

func (s *operationTimeoutSession) recoverDelivery(delivery Delivery) {
	go func() {
		s.fireDeliveryCancelRequeueHook()
		err := s.consumer.ReQueue(context.Background(), delivery)
		if err != nil {
			s.fireDeliveryCancelRequeueHookFailed()
			fmt.Fprintf(os.Stderr, "WARN failed to requeue message with %v\n", err)
		} else {
			s.fireDeliveryCancelRequeueHookOk()
		}
	}()
}

func (s *operationTimeoutSession) ReQueue(ctx context.Context, delivery Delivery) error {

	if !s.addPending() {
		return ErrClosed
	}
	defer s.releasePending()

	newCtx, cancel := context.WithTimeout(ctx, s.timeout)
	defer cancel()

	result := make(chan error, 1)
	s.wg.Add(1)
	go func() {
		defer s.wg.Done()

		result <- s.consumer.ReQueue(newCtx, delivery)
	}()

	select {
	case <-ctx.Done():
		if ctx.Err() == context.DeadlineExceeded {
			return context.DeadlineExceeded
		}
		return nil

	case <-newCtx.Done():
		if newCtx.Err() == context.DeadlineExceeded {
			s.fireReQueueHooks()
			return context.DeadlineExceeded
		}
		return nil

	case <-s.done.Done():
		return ErrClosed

	case err := <-result:
		return err
	}
}

func (s *operationTimeoutSession) Reject(ctx context.Context, delivery Delivery) error {

	if !s.addPending() {
		return ErrClosed
	}
	defer s.releasePending()

	newCtx, cancel := context.WithTimeout(ctx, s.timeout)
	defer cancel()

	result := make(chan error, 1)
	s.wg.Add(1)
	go func() {
		defer s.wg.Done()

		result <- s.consumer.Reject(newCtx, delivery)
	}()

	select {
	case <-ctx.Done():
		if ctx.Err() == context.DeadlineExceeded {
			return context.DeadlineExceeded
		}
		return nil

	case <-newCtx.Done():
		if newCtx.Err() == context.DeadlineExceeded {
			s.fireRejectHooks()
			return context.DeadlineExceeded
		}
		return nil

	case <-s.done.Done():
		return ErrClosed

	case err := <-result:
		return err
	}
}

func (s *operationTimeoutSession) Acknowledge(ctx context.Context, delivery Delivery) error {

	if !s.addPending() {
		return ErrClosed
	}
	defer s.releasePending()

	newCtx, cancel := context.WithTimeout(ctx, s.timeout)
	defer cancel()

	result := make(chan error, 1)
	s.wg.Add(1)
	go func() {
		defer s.wg.Done()

		result <- s.consumer.Acknowledge(newCtx, delivery)
	}()

	select {
	case <-ctx.Done():
		if ctx.Err() == context.DeadlineExceeded {
			return context.DeadlineExceeded
		}
		return nil

	case <-newCtx.Done():
		if newCtx.Err() == context.DeadlineExceeded {
			s.fireAcknowledgeHook()
			return context.DeadlineExceeded
		}
		return nil

	case <-s.done.Done():
		return ErrClosed

	case err := <-result:
		return err
	}
}

func (s *operationTimeoutSession) Publish(ctx context.Context, exchange string, routingKey string, publishing amqp.Publishing) error {

	if !s.addPending() {
		return ErrClosed
	}
	defer s.releasePending()

	newCtx, cancel := context.WithTimeout(ctx, s.timeout)
	defer cancel()

	result := make(chan error, 1)
	s.wg.Add(1)
	go func() {
		defer s.wg.Done()

		result <- s.publisher.Publish(newCtx, exchange, routingKey, publishing)
	}()

	select {
	case <-ctx.Done():
		if ctx.Err() == context.DeadlineExceeded {
			return context.DeadlineExceeded
		}
		return nil

	case <-newCtx.Done():
		if newCtx.Err() == context.DeadlineExceeded {
			s.firePublishHook()
			return context.DeadlineExceeded
		}
		return nil

	case <-s.done.Done():
		return ErrClosed

	case err := <-result:
		return err
	}
}

type undeliverableCaptureSession struct {
	s          Publisher
	done       context.Context
	doneCancel context.CancelFunc
	wg         sync.WaitGroup
	handler    UndeliverableHandlerFn
	hooks      []hookFn
	m          sync.Mutex
	closing    chan struct{}
	pending    sync.WaitGroup
}

func newUndeliverableCaptureSession(ctx context.Context, s Publisher, handler UndeliverableHandlerFn) (Publisher, error) {
	result := &undeliverableCaptureSession{
		s:       s,
		handler: handler,
		closing: make(chan struct{}),
	}

	result.done, result.doneCancel = context.WithCancel(context.Background())

	channel, err := s.channel(ctx)
	if err != nil {
		return nil, err
	}
	if channel == nil {
		return nil, nil
	}

	returns := channel.NotifyReturn(make(chan amqp.Return, 1))

	result.wg.Add(1)
	go result.watchReturn(returns)

	return result, nil
}

func (s *undeliverableCaptureSession) acquirePending() bool {
	s.m.Lock()
	defer s.m.Unlock()

	select {
	case <-s.closing:
		return false

	default:
		s.pending.Add(1)
		return true
	}
}

func (s *undeliverableCaptureSession) releasePending() {
	s.pending.Done()
}

func (s *undeliverableCaptureSession) addHook(hookName string, hook hookFn) bool {
	s.m.Lock()
	defer s.m.Unlock()

	if hookName == hookUndeliverable {
		s.hooks = append(s.hooks, hook)
		return true
	}

	return s.s.addHook(hookName, hook)
}

func (s *undeliverableCaptureSession) getHookListeners() []hookFn {
	s.m.Lock()
	defer s.m.Unlock()

	return s.hooks
}

func (s *undeliverableCaptureSession) Close() error {
	if !s.beginClose() {
		return nil
	}

	s.pending.Wait()

	s.doneCancel()
	s.wg.Wait()

	return s.s.Close()
}

func (s *undeliverableCaptureSession) beginClose() bool {
	s.m.Lock()
	defer s.m.Unlock()

	select {
	case <-s.closing:
		return false

	default:
		close(s.closing)
		return true
	}
}

func (s *undeliverableCaptureSession) connection(ctx context.Context) (*amqp.Connection, error) {
	if !s.acquirePending() {
		return nil, ErrClosed
	}
	defer s.releasePending()

	return s.s.connection(ctx)
}

func (s *undeliverableCaptureSession) channel(ctx context.Context) (*amqp.Channel, error) {
	if !s.acquirePending() {
		return nil, ErrClosed
	}
	defer s.releasePending()

	return s.s.channel(ctx)
}

func (s *undeliverableCaptureSession) endpoint(ctx context.Context) (string, error) {
	if !s.acquirePending() {
		return "", ErrClosed
	}
	defer s.releasePending()

	return s.s.endpoint(ctx)
}

func (s *undeliverableCaptureSession) Publish(ctx context.Context, exchange string, routingKey string, publishing amqp.Publishing) error {
	if !s.acquirePending() {
		return ErrClosed
	}
	defer s.releasePending()

	return s.s.Publish(ctx, exchange, routingKey, publishing)
}

func (s *undeliverableCaptureSession) watchReturn(returns chan amqp.Return) {
	defer s.wg.Done()

	for {
		select {
		case <-s.done.Done():
			return

		case item := <-returns:
			for _, hook := range s.getHookListeners() {
				hook(item)
			}
			go s.handler(item)
		}
	}
}

type flowControlSession struct {
	s           Publisher
	currentFlow bool
	flows       <-chan bool
	hooks       []hookFn
	m           sync.Mutex
	closing     chan struct{}
	pending     sync.WaitGroup
}

func newFlowControlSession(ctx context.Context, s Publisher) (Publisher, error) {
	channel, err := s.channel(ctx)
	if err != nil {
		return nil, err
	}
	if channel == nil {
		return nil, nil
	}

	return &flowControlSession{
		s:           s,
		currentFlow: true,
		flows:       channel.NotifyFlow(make(chan bool, 1)),
		closing:     make(chan struct{}),
	}, nil
}

func (s *flowControlSession) acquirePending() bool {
	s.m.Lock()
	defer s.m.Unlock()

	select {
	case <-s.closing:
		return false

	default:
		s.pending.Add(1)
		return true
	}
}

func (s *flowControlSession) releasePending() {
	s.pending.Done()
}

func (s *flowControlSession) addHook(hookName string, hook hookFn) bool {
	s.m.Lock()
	defer s.m.Unlock()

	if hookName == hookFlow {
		s.hooks = append(s.hooks, hook)
		return true
	}

	return s.s.addHook(hookName, hook)
}

func (s *flowControlSession) connection(ctx context.Context) (*amqp.Connection, error) {
	if !s.acquirePending() {
		return nil, ErrClosed
	}
	defer s.releasePending()

	return s.s.connection(ctx)
}

func (s *flowControlSession) channel(ctx context.Context) (*amqp.Channel, error) {
	if !s.acquirePending() {
		return nil, ErrClosed
	}
	defer s.releasePending()

	return s.s.channel(ctx)
}

func (s *flowControlSession) endpoint(ctx context.Context) (string, error) {
	if !s.acquirePending() {
		return "", ErrClosed
	}
	defer s.releasePending()

	return s.s.endpoint(ctx)
}

func (s *flowControlSession) Close() error {
	if !s.beginClose() {
		return nil
	}

	s.pending.Wait()

	return s.s.Close()
}

func (s *flowControlSession) beginClose() bool {
	s.m.Lock()
	defer s.m.Unlock()

	select {
	case <-s.closing:
		return false

	default:
		close(s.closing)
		return true
	}
}

func (s *flowControlSession) getCurrentFlow() bool {
	s.m.Lock()
	defer s.m.Unlock()

	return s.currentFlow
}

func (s *flowControlSession) setCurrentFlow(flow bool) {
	s.m.Lock()
	defer s.m.Unlock()

	s.currentFlow = flow

	for _, hook := range s.hooks {
		hook(flow)
	}
}

func (s *flowControlSession) Publish(ctx context.Context, exchange string, routingKey string, publishing amqp.Publishing) error {

	if !s.acquirePending() {
		return ErrClosed
	}
	defer s.releasePending()

	select {
	case flow := <-s.flows:
		s.setCurrentFlow(flow)

	default:
	}

	for !s.getCurrentFlow() {
		select {
		case flow := <-s.flows:
			s.setCurrentFlow(flow)

		case <-ctx.Done():
			if ctx.Err() == context.DeadlineExceeded {
				return context.DeadlineExceeded
			}

			return nil
		}
	}

	return s.s.Publish(ctx, exchange, routingKey, publishing)
}

type publisherConfirmSession struct {
	s            Publisher
	confirms     <-chan amqp.Confirmation
	hookTimeouts []hookFn
	m            sync.Mutex
	closing      chan struct{}
	pending      sync.WaitGroup
}

func newPublisherConfirmSession(ctx context.Context, s Publisher, confirm bool) (Publisher, error) {
	result := &publisherConfirmSession{
		s:       s,
		closing: make(chan struct{}),
	}

	if confirm {
		channel, err := s.channel(ctx)
		if err != nil {
			return nil, err
		}
		if channel == nil {
			return nil, nil
		}

		err = channel.Confirm(false)
		if err != nil {
			return nil, err
		}

		result.confirms = channel.NotifyPublish(make(chan amqp.Confirmation, 1))
	}

	return result, nil
}

func (s *publisherConfirmSession) acquirePending() bool {
	s.m.Lock()
	defer s.m.Unlock()

	select {
	case <-s.closing:
		return false

	default:
		s.pending.Add(1)
		return true
	}
}

func (s *publisherConfirmSession) releasePending() {
	s.pending.Done()
}

func (s *publisherConfirmSession) connection(ctx context.Context) (*amqp.Connection, error) {
	if !s.acquirePending() {
		return nil, ErrClosed
	}
	defer s.releasePending()

	return s.s.connection(ctx)
}

func (s *publisherConfirmSession) channel(ctx context.Context) (*amqp.Channel, error) {
	if !s.acquirePending() {
		return nil, ErrClosed
	}
	defer s.releasePending()

	return s.s.channel(ctx)
}

func (s *publisherConfirmSession) Close() error {
	if !s.beginClose() {
		return nil
	}

	s.pending.Wait()

	return s.s.Close()
}

func (s *publisherConfirmSession) beginClose() bool {
	s.m.Lock()
	defer s.m.Unlock()

	select {
	case <-s.closing:
		return false

	default:
		close(s.closing)
		return true
	}
}

func (s *publisherConfirmSession) endpoint(ctx context.Context) (string, error) {
	if !s.acquirePending() {
		return "", ErrClosed
	}
	defer s.releasePending()

	return s.s.endpoint(ctx)
}

func (s *publisherConfirmSession) Publish(ctx context.Context, exchange string, routingKey string, publishing amqp.Publishing) error {
	if !s.acquirePending() {
		return ErrClosed
	}
	defer s.releasePending()

	err := s.s.Publish(ctx, exchange, routingKey, publishing)
	if err != nil {
		return err
	}

	if s.confirms != nil {
		select {
		case <-ctx.Done():
			if ctx.Err() == context.DeadlineExceeded {
				s.fireTimeout()
				return context.DeadlineExceeded
			}
			return nil

		case confirmation := <-s.confirms:
			if !confirmation.Ack {
				return xerrors.Errorf("ERR publisher confirm failed: %w", ErrPublisherConfirmFailed)
			}
			return nil
		}
	}

	return nil
}

func (s *publisherConfirmSession) fireTimeout() {
	s.m.Lock()
	defer s.m.Unlock()

	for _, hook := range s.hookTimeouts {
		hook()
	}
}

func (s *publisherConfirmSession) addHook(hookName string, hook hookFn) bool {
	s.m.Lock()
	defer s.m.Unlock()

	if hookName == hookPublisherConfirmTimeout {
		s.hookTimeouts = append(s.hookTimeouts, hook)
	}

	return s.s.addHook(hookName, hook)
}

type consumerRateLimiter struct {
	s                               Consumer
	wg                              sync.WaitGroup
	pending                         sync.WaitGroup
	done                            context.Context
	doneCancel                      context.CancelFunc
	t                               *time.Ticker
	m                               sync.Mutex
	ch                              chan Delivery
	closing                         chan struct{}
	hookDeliveryCancelRequeue       []hookFn
	hookDeliveryCancelRequeueFailed []hookFn
	hookDeliveryCancelRequeueOk     []hookFn
	consumeFirstDeliveryNoWait      chan struct{}
}

func NewConsumerRateLimiter(s Consumer, rate float64) Consumer {
	result := &consumerRateLimiter{
		s:                          s,
		t:                          time.NewTicker(time.Duration(float64(time.Second) / rate)),
		closing:                    make(chan struct{}),
		consumeFirstDeliveryNoWait: make(chan struct{}),
	}

	result.done, result.doneCancel = context.WithCancel(context.Background())

	return result
}

func (s *consumerRateLimiter) acquirePending() bool {
	s.m.Lock()
	defer s.m.Unlock()

	select {
	case <-s.closing:
		return false

	default:
		s.pending.Add(1)
		return true
	}
}

func (s *consumerRateLimiter) releasePending() {
	s.pending.Done()
}

func (s *consumerRateLimiter) Close() error {
	if !s.beginClose() {
		return nil
	}

	s.pending.Wait()
	s.doneCancel()
	s.wg.Wait()
	s.t.Stop()

	return s.s.Close()
}

func (s *consumerRateLimiter) beginClose() bool {
	s.m.Lock()
	defer s.m.Unlock()

	select {
	case <-s.closing:
		return false

	default:
		close(s.closing)
		return true
	}
}

func (s *consumerRateLimiter) addHook(hookName string, hook hookFn) bool {
	s.m.Lock()
	defer s.m.Unlock()

	if hookName == hookDeliveryCancelRequeue {
		s.hookDeliveryCancelRequeue = append(s.hookDeliveryCancelRequeue, hook)
		s.s.addHook(hookName, hook)
		return true
	}

	if hookName == hookDeliveryCancelRequeueFailed {
		s.hookDeliveryCancelRequeueFailed = append(s.hookDeliveryCancelRequeueFailed, hook)
		s.s.addHook(hookName, hook)
		return true
	}

	if hookName == hookDeliveryCancelRequeueOk {
		s.hookDeliveryCancelRequeueOk = append(s.hookDeliveryCancelRequeueOk, hook)
		s.s.addHook(hookName, hook)
		return true
	}

	return s.s.addHook(hookName, hook)
}

func (s *consumerRateLimiter) fireDeliveryCancelRequeueHook() {
	s.m.Lock()
	defer s.m.Unlock()

	for _, hook := range s.hookDeliveryCancelRequeue {
		hook()
	}
}

func (s *consumerRateLimiter) fireDeliveryCancelRequeueHookOk() {
	s.m.Lock()
	defer s.m.Unlock()

	for _, hook := range s.hookDeliveryCancelRequeueOk {
		hook()
	}
}

func (s *consumerRateLimiter) fireDeliveryCancelRequeueHookFailed() {
	s.m.Lock()
	defer s.m.Unlock()

	for _, hook := range s.hookDeliveryCancelRequeueFailed {
		hook()
	}
}

func (s *consumerRateLimiter) Consume(ctx context.Context) (<-chan Delivery, error) {
	if !s.acquirePending() {
		return nil, ErrClosed
	}
	defer s.releasePending()

	s.m.Lock()
	defer s.m.Unlock()

	if s.ch != nil {
		return s.ch, nil
	}

	delivery, err := s.s.Consume(ctx)
	if err != nil {
		return nil, err
	}
	if delivery == nil {
		return nil, nil
	}

	s.ch = make(chan Delivery)
	s.wg.Add(1)
	go s.deliverer(delivery)

	return s.ch, nil
}

func (s *consumerRateLimiter) isFirstDelivery() bool {
	s.m.Lock()
	defer s.m.Unlock()

	select {
	case <-s.consumeFirstDeliveryNoWait:
		return false

	default:
		close(s.consumeFirstDeliveryNoWait)
		return true
	}
}

func (s *consumerRateLimiter) connection(ctx context.Context) (*amqp.Connection, error) {
	if !s.acquirePending() {
		return nil, ErrClosed
	}
	defer s.releasePending()

	return s.s.connection(ctx)
}

func (s *consumerRateLimiter) channel(ctx context.Context) (*amqp.Channel, error) {
	if !s.acquirePending() {
		return nil, ErrClosed
	}
	defer s.releasePending()

	return s.s.channel(ctx)
}

func (s *consumerRateLimiter) endpoint(ctx context.Context) (string, error) {
	if !s.acquirePending() {
		return "", ErrClosed
	}
	defer s.releasePending()

	return s.s.endpoint(ctx)
}

func (s *consumerRateLimiter) deliverer(source <-chan Delivery) {
	defer s.wg.Done()

	for {
		select {
		case delivery, ok := <-source:
			if !ok {
				close(s.ch)
				s.ch = nil
				return
			}

			if s.isFirstDelivery() {
				if !s.doDelivery(delivery) {
					s.recoverDelivery(delivery)
					close(s.ch)
					s.ch = nil
					return
				}
			} else {
				select {
				case <-s.t.C:
					if !s.doDelivery(delivery) {
						s.recoverDelivery(delivery)
						close(s.ch)
						s.ch = nil
						return
					}

				case <-s.done.Done():
					close(s.ch)
					s.ch = nil
					return
				}
			}

		case <-s.done.Done():
			close(s.ch)
			s.ch = nil
			return
		}
	}
}

func (s *consumerRateLimiter) doDelivery(delivery Delivery) bool {
	select {
	case s.ch <- delivery:
		return true

	case <-s.done.Done():
		return false
	}
}

func (s *consumerRateLimiter) recoverDelivery(delivery Delivery) {
	go func() {
		s.fireDeliveryCancelRequeueHook()
		err := s.s.ReQueue(context.Background(), delivery)
		if err != nil {
			s.fireDeliveryCancelRequeueHookFailed()
			fmt.Fprintf(os.Stderr, "WARN failed to requeue message with %v\n", err)
		} else {
			s.fireDeliveryCancelRequeueHookOk()
		}
	}()
}

func (s *consumerRateLimiter) Acknowledge(ctx context.Context, delivery Delivery) error {
	if !s.acquirePending() {
		return ErrClosed
	}
	defer s.releasePending()

	return s.s.Acknowledge(ctx, delivery)
}

func (s *consumerRateLimiter) Reject(ctx context.Context, delivery Delivery) error {
	if !s.acquirePending() {
		return ErrClosed
	}
	defer s.releasePending()

	return s.s.Reject(ctx, delivery)
}

func (s *consumerRateLimiter) ReQueue(ctx context.Context, delivery Delivery) error {
	if !s.acquirePending() {
		return ErrClosed
	}
	defer s.releasePending()

	return s.s.ReQueue(ctx, delivery)
}

type publishRateLimiter struct {
	s                  Publisher
	outgoing           chan publishRateLimiterOutgoing
	wg                 sync.WaitGroup
	pending            sync.WaitGroup
	closing            chan struct{}
	t                  *time.Ticker
	done               context.Context
	doneCancel         context.CancelFunc
	m                  sync.Mutex
	firstPublishNoWait chan struct{}
}

type publishRateLimiterOutgoing struct {
	ctx        context.Context
	exchange   string
	queue      string
	publishing amqp.Publishing
	result     chan error
}

func NewPublishRateLimiter(s Publisher, rate float64) Publisher {
	result := &publishRateLimiter{
		s:                  s,
		outgoing:           make(chan publishRateLimiterOutgoing, 1+int(rate)),
		t:                  time.NewTicker(time.Duration(float64(time.Second) / rate)),
		closing:            make(chan struct{}),
		firstPublishNoWait: make(chan struct{}),
	}

	result.done, result.doneCancel = context.WithCancel(context.Background())
	result.wg.Add(1)
	go result.sender()

	return result
}

func (s *publishRateLimiter) addHook(hookName string, hook hookFn) bool {
	return s.s.addHook(hookName, hook)
}

func (s *publishRateLimiter) Close() error {
	if !s.beginClose() {
		return nil
	}

	s.doneCancel()
	s.wg.Wait()
	s.pending.Wait()

	return s.s.Close()
}

func (s *publishRateLimiter) beginClose() bool {
	s.m.Lock()
	defer s.m.Unlock()

	select {
	case <-s.closing:
		return false

	default:
		close(s.closing)
		return true
	}
}

func (s *publishRateLimiter) increasePending() bool {
	s.m.Lock()
	defer s.m.Unlock()

	select {
	case <-s.closing:
		return false

	default:
		s.pending.Add(1)
		return true
	}
}

func (s *publishRateLimiter) releasePending() {
	s.pending.Done()
}

func (s *publishRateLimiter) connection(ctx context.Context) (*amqp.Connection, error) {
	if !s.increasePending() {
		return nil, ErrClosed
	}
	defer s.releasePending()

	return s.s.connection(ctx)
}

func (s *publishRateLimiter) channel(ctx context.Context) (*amqp.Channel, error) {
	if !s.increasePending() {
		return nil, ErrClosed
	}
	defer s.releasePending()

	return s.s.channel(ctx)
}

func (s *publishRateLimiter) endpoint(ctx context.Context) (string, error) {
	if !s.increasePending() {
		return "", ErrClosed
	}
	defer s.releasePending()

	return s.s.endpoint(ctx)
}

func (s *publishRateLimiter) isFirstPublish() bool {
	s.m.Lock()
	defer s.m.Unlock()

	select {
	case <-s.firstPublishNoWait:
		return false

	default:
		close(s.firstPublishNoWait)
		return true
	}
}

func (s *publishRateLimiter) Publish(ctx context.Context, exchange string, queue string, publishing amqp.Publishing) error {

	if !s.increasePending() {
		return ErrClosed
	}
	defer s.releasePending()

	if s.isFirstPublish() {
		return s.s.Publish(ctx, exchange, queue, publishing)
	}

	result := make(chan error, 1)
	outgoing := publishRateLimiterOutgoing{
		ctx:        ctx,
		exchange:   exchange,
		queue:      queue,
		publishing: publishing,
		result:     result,
	}

	select {
	case <-s.done.Done():
		return ErrClosed

	case <-ctx.Done():
		if ctx.Err() == context.DeadlineExceeded {
			return context.DeadlineExceeded
		}
		return nil

	case s.outgoing <- outgoing:
		select {
		case <-s.done.Done():
			return ErrClosed

		case <-ctx.Done():
			if ctx.Err() == context.DeadlineExceeded {
				return context.DeadlineExceeded
			}
			return nil

		case err := <-result:
			return err
		}
	}
}

func (s *publishRateLimiter) sender() {
	defer s.wg.Done()

	for {
		select {
		case <-s.done.Done():
			return

		case <-s.t.C:
			select {
			case <-s.done.Done():
				return

			case outgoing := <-s.outgoing:
				go func() {
					outgoing.result <- s.s.Publish(outgoing.ctx, outgoing.exchange, outgoing.queue, outgoing.publishing)
				}()
			}
		}
	}
}

type basicSession struct {
	amqpEndpoint                    string
	amqpConnection                  *amqp.Connection
	amqpChannel                     *amqp.Channel
	prefetch                        int
	consumerId                      string
	ch                              chan Delivery
	m                               sync.Mutex
	wg                              sync.WaitGroup
	done                            context.Context
	doneCancel                      context.CancelFunc
	hookDeliveryCancelRequeue       []hookFn
	hookDeliveryCancelRequeueFailed []hookFn
	hookDeliveryCancelRequeueOk     []hookFn
	pending                         sync.WaitGroup
	closing                         chan struct{}
	queue                           string
}

func newBasicSession(ctx context.Context, endpoint string, username string, password string, vhost string, prefetch int, queue string) (communicator, error) {
	result := &basicSession{
		amqpEndpoint: endpoint,
		prefetch:     prefetch,
		closing:      make(chan struct{}),
		queue:        queue,
	}

	result.done, result.doneCancel = context.WithCancel(context.Background())

	errChannel := make(chan error, 1)

	go func() {
		var err error

		result.amqpConnection, err = amqp.Dial(fmt.Sprintf("amqp://%s:%s@%s/%s", username, password, endpoint, vhost))
		if err != nil {
			errChannel <- xerrors.Errorf("ERR Dialing %s failed with %v: %w", endpoint, err, ErrDialFailed)
			return
		}

		result.amqpChannel, err = result.amqpConnection.Channel()
		if err != nil {
			errChannel <- xerrors.Errorf("ERR opening channel to %s failed with %v: %w", endpoint, err, ErrChannelOpenFailed)
		}

		errChannel <- nil
	}()

	select {
	case <-ctx.Done():
		go func() {
			select {
			case <-errChannel:
				result.closeInternal()
			}
		}()
		if ctx.Err() == context.DeadlineExceeded {
			return nil, context.DeadlineExceeded
		}
		return nil, nil

	case err := <-errChannel:
		if err != nil {
			result.closeInternal()
			return nil, err
		}
		return result, nil
	}
}

func (s *basicSession) acquirePending() bool {
	s.m.Lock()
	defer s.m.Unlock()

	select {
	case <-s.closing:
		return false

	default:
		s.pending.Add(1)
		return true
	}
}

func (s *basicSession) releasePending() {
	s.pending.Done()
}

func (s *basicSession) addHook(hookName string, hook hookFn) bool {
	s.m.Lock()
	defer s.m.Unlock()

	if hookName == hookDeliveryCancelRequeue {
		s.hookDeliveryCancelRequeue = append(s.hookDeliveryCancelRequeue, hook)
		return true
	}

	if hookName == hookDeliveryCancelRequeueFailed {
		s.hookDeliveryCancelRequeueFailed = append(s.hookDeliveryCancelRequeueFailed)
		return true
	}

	if hookName == hookDeliveryCancelRequeueOk {
		s.hookDeliveryCancelRequeueOk = append(s.hookDeliveryCancelRequeueOk)
		return true
	}

	return false
}

func (s *basicSession) fireDeliveryCancelRequeueHook() {
	s.m.Lock()
	defer s.m.Unlock()

	for _, hook := range s.hookDeliveryCancelRequeue {
		hook()
	}
}

func (s *basicSession) fireDeliveryCancelRequeueHookOk() {
	s.m.Lock()
	defer s.m.Unlock()

	for _, hook := range s.hookDeliveryCancelRequeueOk {
		hook()
	}
}

func (s *basicSession) fireDeliveryCancelRequeueHookFailed() {
	s.m.Lock()
	defer s.m.Unlock()

	for _, hook := range s.hookDeliveryCancelRequeueFailed {
		hook()
	}
}

func (s *basicSession) connection(ctx context.Context) (*amqp.Connection, error) {
	return s.amqpConnection, nil
}

func (s *basicSession) channel(ctx context.Context) (*amqp.Channel, error) {
	return s.amqpChannel, nil
}

func (s *basicSession) endpoint(ctx context.Context) (string, error) {
	return s.amqpEndpoint, nil
}

func (s *basicSession) Close() error {
	s.closeInternal()
	return nil
}

func (s *basicSession) closeDelivery() {
	s.m.Lock()
	defer s.m.Unlock()

	s.doneCancel()
	s.wg.Wait()
}

func (s *basicSession) beginClose() bool {
	s.m.Lock()
	defer s.m.Unlock()

	select {
	case <-s.closing:
		return false

	default:
		close(s.closing)

		if s.ch != nil {
			err := s.amqpChannel.Cancel(s.consumerId, false)
			if err != nil {
				fmt.Fprintf(os.Stderr, "WARN: Can not cancel consumer on closing channel\n")
			}
		}

		return true
	}
}

func (s *basicSession) closeInternal() {
	if !s.beginClose() {
		return
	}

	s.pending.Wait()
	s.closeDelivery()

	go func(channel *amqp.Channel, connection *amqp.Connection) {
		var err error

		if s.amqpChannel != nil {
			err = s.amqpChannel.Close()
			if err != nil {
				fmt.Fprintf(os.Stderr, "WARN can not close channel to %s with %v", s.endpoint, err)
			}
		}

		if s.amqpConnection != nil {
			err = s.amqpConnection.Close()
			if err != nil {
				fmt.Fprintf(os.Stderr, "WARN can not close connection to %s with %v", s.endpoint, err)
			}
		}
	}(s.amqpChannel, s.amqpConnection)

	s.amqpChannel = nil
	s.amqpConnection = nil
}

func (s *basicSession) Publish(ctx context.Context, exchange string, routingKey string, publishing amqp.Publishing) error {
	if !s.acquirePending() {
		return ErrClosed
	}
	defer s.releasePending()

	err := s.amqpChannel.Publish(exchange, routingKey, true, false, publishing)
	if err != nil {
		return xerrors.Errorf("ERR publishing to %s:%s:%s with %v: %w", s.endpoint, exchange, routingKey, err, ErrPublishFailed)
	}

	return nil
}

func (s *basicSession) Consume(ctx context.Context) (<-chan Delivery, error) {
	if !s.acquirePending() {
		return nil, ErrClosed
	}
	defer s.releasePending()

	s.m.Lock()
	defer s.m.Unlock()

	if s.ch != nil {
		return s.ch, nil
	}

	err := s.amqpChannel.Qos(s.prefetch, 0, false)
	if err != nil {
		return nil, err
	}

	s.consumerId = randstr.Hex(8)
	rawDelivery, err := s.amqpChannel.Consume(s.queue, s.consumerId, false, false, false, false, nil)
	if err != nil {
		return nil, err
	}

	s.ch = make(chan Delivery)
	s.wg.Add(1)
	go s.deliverer(rawDelivery)

	return s.ch, nil
}

func (s *basicSession) deliverer(rawDelivery <-chan amqp.Delivery) {
	defer s.wg.Done()

	for {
		select {
		case delivery, ok := <-rawDelivery:
			if !ok {
				close(s.ch)
				s.ch = nil
				return
			}

			newDelivery := Delivery{
				Body:        delivery.Body,
				ConsumerId:  delivery.ConsumerTag,
				DeliveryTag: delivery.DeliveryTag,
			}

			select {
			case <-s.done.Done():
				go func() {
					s.fireDeliveryCancelRequeueHook()
					err := delivery.Reject(true)
					if err != nil {
						s.fireDeliveryCancelRequeueHookFailed()
						fmt.Fprintf(os.Stderr, "WARN failed to requeue message with %v\n", err)
					} else {
						s.fireDeliveryCancelRequeueHookOk()
					}
				}()

				close(s.ch)
				s.ch = nil
				return

			case s.ch <- newDelivery:
			}

		case <-s.done.Done():
			close(s.ch)
			s.ch = nil
			return
		}
	}
}

func (s *basicSession) Acknowledge(ctx context.Context, delivery Delivery) error {
	if !s.acquirePending() {
		return ErrClosed
	}
	defer s.releasePending()

	if !s.isCorrectDelivery(delivery) {
		return ErrIncorrectConsumerId
	}

	return s.amqpChannel.Ack(delivery.DeliveryTag, false)
}

func (s *basicSession) Reject(ctx context.Context, delivery Delivery) error {
	if !s.acquirePending() {
		return ErrClosed
	}
	defer s.releasePending()

	if !s.isCorrectDelivery(delivery) {
		return ErrIncorrectConsumerId
	}

	return s.amqpChannel.Reject(delivery.DeliveryTag, false)
}

func (s *basicSession) ReQueue(ctx context.Context, delivery Delivery) error {
	if !s.acquirePending() {
		return ErrClosed
	}
	defer s.releasePending()

	if !s.isCorrectDelivery(delivery) {
		return ErrIncorrectConsumerId
	}

	return s.amqpChannel.Reject(delivery.DeliveryTag, true)
}

func (s *basicSession) isCorrectDelivery(delivery Delivery) bool {
	s.m.Lock()
	defer s.m.Unlock()

	return s.consumerId == delivery.ConsumerId
}

type monitoringSession struct {
	publisher  Publisher
	consumer   Consumer
	observer   func(event string)
	done       context.Context
	doneCancel context.CancelFunc
	wg         sync.WaitGroup
	m          sync.Mutex
	ch         chan Delivery
	closing    chan struct{}
	pending    sync.WaitGroup
}

func NewPublisherMonitoring(s Publisher, observer func(event string)) Publisher {
	return newMonitoringSession(s, nil, observer)
}

func NewConsumerMonitoring(s Consumer, observer func(event string)) Consumer {
	return newMonitoringSession(nil, s, observer)
}

func newMonitoringSession(publisher Publisher, consumer Consumer, observer func(event string)) communicator {
	result := &monitoringSession{
		publisher: publisher,
		consumer:  consumer,
		observer:  observer,
		closing:   make(chan struct{}),
	}

	if consumer == nil && publisher == nil {
		panic("can not monitor both nil consumer,publisher")
	}

	if consumer != nil && publisher != nil && consumer.(Session) != publisher.(Session) {
		panic("two different publisher/consumers provided")
	}

	result.done, result.doneCancel = context.WithCancel(context.Background())

	result.registerHooks()

	return result
}

func (s *monitoringSession) beginPending() bool {
	s.m.Lock()
	defer s.m.Unlock()

	select {
	case <-s.closing:
		return false

	default:
		s.pending.Add(1)
		return true
	}
}

func (s *monitoringSession) releasePending() {
	s.pending.Done()
}

func (s *monitoringSession) registerHooks() {
	session := s.getSession()

	session.addHook(hookDial, s.hookDial)
	session.addHook(hookRetry, s.hookRetry)
	session.addHook(hookUndeliverable, s.hookUndeliverable)
	session.addHook(hookFlow, s.hookFlow)
	session.addHook(hookPublisherConfirmTimeout, s.hookPublisherConfirmTimeout)
	session.addHook(hookAcknowledgeTimeout, s.hookAcknowledgeTimeout)
	session.addHook(hookRejectTimeout, s.hookRejectTimeout)
	session.addHook(hookReQueueTimeout, s.hookReQueueTimeout)
	session.addHook(hookConsumeTimeout, s.hookConsumeTimeout)
	session.addHook(hookConnectionBlocked, s.hookConnectionBlocked)
	session.addHook(hookPublishTimeout, s.hookPublishTimeout)
	session.addHook(hookDeliveryCancelRequeue, s.hookDeliveryCancelRequeue)
	session.addHook(hookDeliveryCancelRequeueOk, s.hookDeliveryCancelRequeueOk)
	session.addHook(hookDeliveryCancelRequeueFailed, s.hookDeliveryCancelRequeueFailed)
	session.addHook(hookChannelReadTimeout, s.hookChannelReadTimeout)
	session.addHook(hookRetryPublish, s.hookRetryPublish)
	session.addHook(hookRetryAcknowledge, s.hookRetryAcknowledge)
	session.addHook(hookRetryReject, s.hookRetryReject)
	session.addHook(hookRetryReQueue, s.hookRetryReQueue)
	session.addHook(hookRetryConsume, s.hookRetryConsume)
	session.addHook(hookChannelCreationFailed, s.hookChannelCreationFailed)
	session.addHook(hookConsumerCreationFailed, s.hookConsumerCreationFailed)
	session.addHook(hookConsumerCreationCanceled, s.hookConsumerCreationCanceled)
	session.addHook(hookDeliveryCanceled, s.hookDeliveryCanceled)
	session.addHook(hookDeliveryRetry, s.hookDeliveryRetry)
}

func (s *monitoringSession) addHook(hookName string, hook hookFn) bool {
	return s.getSession().addHook(hookName, hook)
}

func (s *monitoringSession) Publish(ctx context.Context, exchange string, routingKey string, publishing amqp.Publishing) error {
	if !s.beginPending() {
		return ErrClosed
	}
	defer s.releasePending()

	s.fireObserver("event_publish")

	err := s.publisher.Publish(ctx, exchange, routingKey, publishing)
	if err != nil {
		s.handleError("publish", err)
		s.handleError("", err)
	} else {
		s.fireObserver("event_publish_ok")
	}

	return err
}

func (s *monitoringSession) connection(ctx context.Context) (*amqp.Connection, error) {
	if !s.beginPending() {
		return nil, ErrClosed
	}
	defer s.releasePending()

	result, err := s.getSession().connection(ctx)
	if err != nil {
		s.handleError("", err)
	} else if result == nil {
		s.handleError("", context.Canceled)
	}

	return result, err
}

func (s *monitoringSession) channel(ctx context.Context) (*amqp.Channel, error) {
	if !s.beginPending() {
		return nil, ErrClosed
	}
	defer s.releasePending()

	result, err := s.getSession().channel(ctx)
	if err != nil {
		s.handleError("", err)
	} else if result == nil {
		s.handleError("", context.Canceled)
	}

	return result, err
}

func (s *monitoringSession) endpoint(ctx context.Context) (string, error) {
	if !s.beginPending() {
		return "", ErrClosed
	}
	defer s.releasePending()

	result, err := s.getSession().endpoint(ctx)
	if err != nil {
		s.handleError("", err)
	} else if result == "" {
		s.handleError("", context.Canceled)
	}

	return result, err
}

func (s *monitoringSession) getSession() Session {
	if s.publisher != nil {
		return s.publisher
	}
	return s.consumer
}

func (s *monitoringSession) Close() error {
	if !s.beginClose() {
		return nil
	}
	s.pending.Wait()

	s.fireObserver("event_close")
	s.closeDelivery()

	err := s.getSession().Close()
	if err != nil {
		s.handleError("", err)
	} else {
		s.fireObserver("event_close_ok")
	}

	return err
}

func (s *monitoringSession) beginClose() bool {
	s.m.Lock()
	defer s.m.Unlock()

	select {
	case <-s.closing:
		return false

	default:
		close(s.closing)
		return true
	}
}

func (s *monitoringSession) closeDelivery() {
	s.m.Lock()
	defer s.m.Unlock()

	s.doneCancel()
	s.wg.Wait()
}

func (s *monitoringSession) Consume(ctx context.Context) (<-chan Delivery, error) {
	if !s.beginPending() {
		return nil, ErrClosed
	}
	defer s.releasePending()

	s.m.Lock()
	defer s.m.Unlock()

	s.fireObserver("event_consume_creation")

	if s.ch != nil {
		s.fireObserver("event_consume_ok")
		return s.ch, nil
	}

	result, err := s.consumer.Consume(ctx)

	if err != nil {
		s.handleError("consume", err)
		s.handleError("", err)
		s.fireObserver("event_channel_creation_failed")
		return nil, err
	}
	if result == nil {
		s.fireObserver("event_channel_creation_canceled")
		return nil, nil
	}

	s.ch = make(chan Delivery)
	s.wg.Add(1)
	go s.deliverer(result)

	return s.ch, err
}

func (s *monitoringSession) deliverer(source <-chan Delivery) {
	defer s.wg.Done()

	for {
		select {
		case <-s.done.Done():
			close(s.ch)
			s.ch = nil
			return

		case delivery, ok := <-source:
			if !ok {
				close(s.ch)
				s.ch = nil
				return
			}

			select {
			case <-s.done.Done():
				go func() {
					err := s.consumer.ReQueue(context.Background(), delivery)
					if err != nil {
						s.fireObserver("delivery_cancel_requeue_failed")
						fmt.Fprintf(os.Stderr, "ERR failed to requeue pending delivery with: %v\n", err)
					} else {
						s.fireObserver("delivery_cancel_requeue_ok")
					}
				}()

				close(s.ch)
				s.ch = nil
				return

			case s.ch <- delivery:
				s.fireObserver("event_consume")
			}
		}
	}
}

func (s *monitoringSession) Acknowledge(ctx context.Context, delivery Delivery) error {
	if !s.beginPending() {
		return ErrClosed
	}
	defer s.releasePending()

	s.fireObserver("event_acknowledge")

	err := s.consumer.Acknowledge(ctx, delivery)
	if err != nil {
		s.handleError("acknowledge", err)
		s.handleError("", err)
	} else {
		s.fireObserver("event_acknowledge_ok")
	}

	return err
}

func (s *monitoringSession) Reject(ctx context.Context, delivery Delivery) error {
	if !s.beginPending() {
		return ErrClosed
	}
	defer s.releasePending()

	s.fireObserver("event_reject")

	err := s.consumer.Reject(ctx, delivery)
	if err != nil {
		s.handleError("reject", err)
		s.handleError("", err)
	} else {
		s.fireObserver("event_reject_ok")
	}

	return err
}

func (s *monitoringSession) ReQueue(ctx context.Context, delivery Delivery) error {
	if !s.beginPending() {
		return ErrClosed
	}
	defer s.releasePending()

	s.fireObserver("event_requeue")

	err := s.consumer.ReQueue(ctx, delivery)
	if err != nil {
		s.handleError("requeue", err)
		s.handleError("", err)
	} else {
		s.fireObserver("event_requeue_ok")
	}

	return err
}

func (s *monitoringSession) hookPublishTimeout(args ...interface{}) {
	s.fireObserver("event_publish_timeout")
}

func (s *monitoringSession) hookAcknowledgeTimeout(args ...interface{}) {
	s.fireObserver("event_acknowledge_timeout")
}

func (s *monitoringSession) hookRejectTimeout(args ...interface{}) {
	s.fireObserver("event_reject_timeout")
}

func (s *monitoringSession) hookReQueueTimeout(args ...interface{}) {
	s.fireObserver("event_requeue_timeout")
}

func (s *monitoringSession) hookConsumeTimeout(args ...interface{}) {
	s.fireObserver("event_consume_timeout")
}

func (s *monitoringSession) hookDial(args ...interface{}) {
	s.fireObserver("event_dial")
}

func (s *monitoringSession) hookRetry(args ...interface{}) {
	err := args[0].(error)
	s.handleError("event_retry_", err)
}

func (s *monitoringSession) hookRetryPublish(args ...interface{}) {
	err := args[0].(error)
	s.handleError("event_retry_publish_", err)
}

func (s *monitoringSession) hookRetryAcknowledge(args ...interface{}) {
	err := args[0].(error)
	s.handleError("event_retry_acknowledge_", err)
}

func (s *monitoringSession) hookRetryReject(args ...interface{}) {
	err := args[0].(error)
	s.handleError("event_retry_reject_", err)
}

func (s *monitoringSession) hookRetryReQueue(args ...interface{}) {
	err := args[0].(error)
	s.handleError("event_retry_requeue_", err)
}

func (s *monitoringSession) hookRetryConsume(args ...interface{}) {
	err := args[0].(error)
	s.handleError("event_retry_consume_", err)
}

func (s *monitoringSession) hookUndeliverable(args ...interface{}) {
	s.fireObserver("event_undeliverable_message")
}

func (s *monitoringSession) hookDeliveryCancelRequeue(args ...interface{}) {
	s.fireObserver("event_delivery_cancel_requeue")
}

func (s *monitoringSession) hookDeliveryCancelRequeueFailed(args ...interface{}) {
	s.fireObserver("event_delivery_cancel_requeue_failed")
}

func (s *monitoringSession) hookDeliveryCancelRequeueOk(args ...interface{}) {
	s.fireObserver("event_delivery_cancel_requeue_ok")
}

func (s *monitoringSession) hookDeliveryRetry(args ...interface{}) {
	s.fireObserver("event_delivery_retry")
}

func (s *monitoringSession) hookChannelReadTimeout(args ...interface{}) {
	s.fireObserver("event_channel_read_timeout")
}

func (s *monitoringSession) hookChannelCreationFailed(args ...interface{}) {
	s.fireObserver("event_channel_creation_failed")
}

func (s *monitoringSession) hookConsumerCreationFailed(args ...interface{}) {
	s.fireObserver("event_consumer_creation_failed")
}

func (s *monitoringSession) hookConsumerCreationCanceled(args ...interface{}) {
	s.fireObserver("event_consumer_creation_canceled")
}

func (s *monitoringSession) hookDeliveryCanceled(args ...interface{}) {
	s.fireObserver("event_delivery_canceled")
}

func (s *monitoringSession) hookFlow(args ...interface{}) {
	flow := args[0].(bool)
	if flow {
		s.fireObserver("event_flow_ok")
	} else {
		s.fireObserver("event_flow_paused")
	}
}

func (s *monitoringSession) hookConnectionBlocked(args ...interface{}) {
	reason := args[0].(string)
	s.fireObserver("event_connection_blocked")
	s.fireObserver(fmt.Sprintf("event_connection_blocked_%s", strings.ReplaceAll(reason, " ", "_")))
}

func (s *monitoringSession) hookPublisherConfirmTimeout(args ...interface{}) {
	s.fireObserver("event_publisher_confirm_timeout")
}

func (s *monitoringSession) handleError(prefix string, err error) {
	event := "err_unknown"

	if xerrors.Is(err, ErrClosed) {
		event = "err_closed"
	} else if xerrors.Is(err, ErrPublishFailed) {
		event = "err_publish_failed"
	} else if xerrors.Is(err, ErrChannelOpenFailed) {
		event = "err_channel_open_failed"
	} else if xerrors.Is(err, ErrDialFailed) {
		event = "err_dial_failed"
	} else if xerrors.Is(err, ErrPublisherConfirmFailed) {
		event = "err_publisher_confirm_failed"
	} else if xerrors.Is(err, context.DeadlineExceeded) {
		event = "err_deadline_exceeded"
	} else if xerrors.Is(err, context.Canceled) {
		event = "err_canceled"
	} else if xerrors.Is(err, ErrIncorrectConsumerId) {
		event = "err_incorrect_consumer_id"
	}

	s.fireObserver(prefix + event)
}

func (s *monitoringSession) fireObserver(value string) {
	go s.observer(value)
}
