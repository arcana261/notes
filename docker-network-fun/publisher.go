package main

import (
	"context"
	"fmt"
	"io"
	"os"
	"sync"
	"time"

	"github.com/streadway/amqp"
	"golang.org/x/xerrors"
)

var (
	ErrPublisherConfirmFailed = xerrors.New("Publisher confirm failed")
	ErrDialFailed             = xerrors.New("Dial failed")
	ErrChannelOpenFailed      = xerrors.New("Channel open failed")
	ErrPublishFailed          = xerrors.New("Publish failed")
	ErrClosed                 = xerrors.New("Session closed")
)

const (
	hookDial                    = "hook_dial"
	hookRetry                   = "hook_retry"
	hookUndeliverable           = "hook_undeliverable"
	hookFlow                    = "hook_flow_closed"
	hookPublisherConfirmTimeout = "hook_publisher_confirm_timeout"
	hookConnectionBlocked       = "hook_connection_blocked"
	hookPublishTimeout          = "hook_publish_timeout"
)

type Publisher interface {
	io.Closer

	Publish(ctx context.Context, exchange string, routingKey string, publishing amqp.Publishing) error
	connection(ctx context.Context) (*amqp.Connection, error)
	channel(ctx context.Context) (*amqp.Channel, error)
	endpoint(ctx context.Context) (string, error)
	addHook(hookName string, fn hookFn) bool
}

type hookFn func(args ...interface{})

type publisherFactory interface {
	io.Closer

	New(ctx context.Context) (Publisher, error)
}

type publisherFactoryFn func(ctx context.Context) (Publisher, error)

type UndeliverableHandlerFn func(amqp.Return)

func (f publisherFactoryFn) New(ctx context.Context) (Publisher, error) {
	return f(ctx)
}

func (f publisherFactoryFn) Close() error {
	return nil
}

func NewPublisher(ctx context.Context, endpoint string, username string, password string, vhost string, confirm bool, undeliverableHandler UndeliverableHandlerFn, connectionTimeout time.Duration, backoff time.Duration, maxRetry int, perPublishTimeout time.Duration) (Publisher, error) {

	var publisherFactory publisherFactoryFn = func(ctx context.Context) (Publisher, error) {
		result, err := newBasicSession(ctx, endpoint, username, password, vhost)
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

		result, err = newUndeliverableCaptureSession(result, undeliverableHandler)
		if err != nil {
			return nil, err
		}
		if result == nil {
			return nil, context.Canceled
		}

		result = newPublishTimeoutSession(result, perPublishTimeout)

		return result, nil
	}

	result := newRetrySession(connectionTimeout, backoff, maxRetry, publisherFactory)

	return result, nil
}

type retrySession struct {
	factory             publisherFactory
	s                   Publisher
	m                   sync.Mutex
	newSessions         chan *retrySessionFactoryResult
	wg                  sync.WaitGroup
	done                context.Context
	doneCancel          context.CancelFunc
	connectionTimeout   time.Duration
	backoff             time.Duration
	newSessionAvailable chan struct{}
	maxRetry            int
	backoffTicker       *time.Ticker
	dialHooks           []hookFn
	retryHooks          []hookFn
	blockedHooks        []hookFn
	hookRequests        []retrySessionHookRequests
}

type retrySessionFactoryResult struct {
	s   Publisher
	err error
}

type retrySessionHookRequests struct {
	hookName string
	hook     hookFn
}

func newRetrySession(connectionTimeout time.Duration, backoff time.Duration, maxRetry int, factory publisherFactory) Publisher {
	result := &retrySession{
		factory:             factory,
		newSessions:         make(chan *retrySessionFactoryResult),
		connectionTimeout:   connectionTimeout,
		backoff:             backoff,
		newSessionAvailable: make(chan struct{}),
		maxRetry:            maxRetry,
		backoffTicker:       time.NewTicker(backoff),
	}
	result.done, result.doneCancel = context.WithCancel(context.Background())

	result.wg.Add(1)
	go result.makeConnections()

	return result
}

func (s *retrySession) Publish(ctx context.Context, exchange string, routingKey string, publishing amqp.Publishing) error {

	var err error

	for retry := 0; s.maxRetry < 0 || retry <= s.maxRetry; retry++ {
		if err != nil {
			for _, hook := range s.getRetryHookListeners() {
				hook(err)
			}
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

func (s *retrySession) publishNoRetry(ctx context.Context, exchange string, routingKey string, publishing amqp.Publishing) error {
	session, err := s.currentSession(ctx)
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

func (s *retrySession) currentSession(ctx context.Context) (Publisher, error) {
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

func (s *retrySession) asyncCloseSession(session Publisher) {
	go func() {
		err := session.Close()
		if err != nil {
			fmt.Fprintf(os.Stderr, "Failed to close session with: %v", err)
		}
	}()
}

func (s *retrySession) getSession() Publisher {
	s.m.Lock()
	defer s.m.Unlock()

	return s.s
}

func (s *retrySession) putSession(session Publisher) (Publisher, bool) {
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

func (s *retrySession) watchConnectionBlock(session Publisher) {
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

func (s *retrySession) watchChannelClose(session Publisher) {
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

func (s *retrySession) watchConnectionClose(session Publisher) {
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

func (s *retrySession) discardSession(session Publisher) {
	s.m.Lock()
	defer s.m.Unlock()

	if s.s == session {
		s.asyncCloseSession(session)
		s.s = nil
		s.newSessionAvailable = make(chan struct{})
	}
}

func (s *retrySession) notifyOnNewSession() chan struct{} {
	s.m.Lock()
	defer s.m.Unlock()

	return s.newSessionAvailable
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

	session, err := factory.New(ctx)
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

	if name == hookConnectionBlocked {
		s.blockedHooks = append(s.blockedHooks, fn)
		return true
	}

	s.hookRequests = append(s.hookRequests, retrySessionHookRequests{
		hookName: name,
		hook:     fn,
	})

	if s.s != nil {
		return s.s.addHook(name, fn)
	}

	return false
}

func (s *retrySession) getRetryHookListeners() []hookFn {
	s.m.Lock()
	defer s.m.Unlock()

	return s.retryHooks
}

func (s *retrySession) getDialHookListeners() []hookFn {
	s.m.Lock()
	defer s.m.Unlock()

	return s.dialHooks
}

func (s *retrySession) getFactory() publisherFactory {
	s.m.Lock()
	defer s.m.Unlock()

	return s.factory
}

type publishTimeoutSession struct {
	s          Publisher
	done       context.Context
	doneCancel context.CancelFunc
	wg         sync.WaitGroup
	pending    sync.WaitGroup
	closing    chan struct{}
	hooks      []hookFn
	m          sync.Mutex
	timeout    time.Duration
}

func newPublishTimeoutSession(s Publisher, timeout time.Duration) Publisher {
	result := &publishTimeoutSession{
		s:       s,
		timeout: timeout,
		closing: make(chan struct{}),
	}

	result.done, result.doneCancel = context.WithCancel(context.Background())

	return result
}

func (s *publishTimeoutSession) connection(ctx context.Context) (*amqp.Connection, error) {
	return s.s.connection(ctx)
}

func (s *publishTimeoutSession) channel(ctx context.Context) (*amqp.Channel, error) {
	return s.s.channel(ctx)
}

func (s *publishTimeoutSession) endpoint(ctx context.Context) (string, error) {
	return s.s.endpoint(ctx)
}

func (s *publishTimeoutSession) addPending() bool {
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

func (s *publishTimeoutSession) releasePending() {
	s.pending.Done()
}

func (s *publishTimeoutSession) Close() error {
	if !s.beginClose() {
		return nil
	}

	s.pending.Wait()
	s.doneCancel()
	s.wg.Wait()

	return s.s.Close()
}

func (s *publishTimeoutSession) beginClose() bool {
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

func (s *publishTimeoutSession) addHook(hookName string, fn hookFn) bool {
	s.m.Lock()
	defer s.m.Unlock()

	if hookName == hookPublishTimeout {
		s.hooks = append(s.hooks, fn)
		return true
	}

	return s.s.addHook(hookName, fn)
}

func (s *publishTimeoutSession) fireHook() {
	s.m.Lock()
	defer s.m.Unlock()

	for _, hook := range s.hooks {
		hook()
	}
}

func (s *publishTimeoutSession) Publish(ctx context.Context, exchange string, routingKey string, publishing amqp.Publishing) error {

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

		result <- s.s.Publish(newCtx, exchange, routingKey, publishing)
	}()

	select {
	case <-ctx.Done():
		if ctx.Err() == context.DeadlineExceeded {
			return context.DeadlineExceeded
		}
		return nil

	case <-newCtx.Done():
		if newCtx.Err() == context.DeadlineExceeded {
			s.fireHook()
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
}

func newUndeliverableCaptureSession(s Publisher, handler UndeliverableHandlerFn) (Publisher, error) {
	result := &undeliverableCaptureSession{
		s:       s,
		handler: handler,
	}

	result.done, result.doneCancel = context.WithCancel(context.Background())

	channel, err := s.channel(result.done)
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
	s.doneCancel()
	s.wg.Wait()

	return s.s.Close()
}

func (s *undeliverableCaptureSession) connection(ctx context.Context) (*amqp.Connection, error) {
	return s.s.connection(ctx)
}

func (s *undeliverableCaptureSession) channel(ctx context.Context) (*amqp.Channel, error) {
	return s.s.channel(ctx)
}

func (s *undeliverableCaptureSession) endpoint(ctx context.Context) (string, error) {
	return s.s.endpoint(ctx)
}

func (s *undeliverableCaptureSession) Publish(ctx context.Context, exchange string, routingKey string, publishing amqp.Publishing) error {
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
	}, nil
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
	return s.s.connection(ctx)
}

func (s *flowControlSession) channel(ctx context.Context) (*amqp.Channel, error) {
	return s.s.channel(ctx)
}

func (s *flowControlSession) endpoint(ctx context.Context) (string, error) {
	return s.s.endpoint(ctx)
}

func (s *flowControlSession) Close() error {
	return s.s.Close()
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
}

func newPublisherConfirmSession(ctx context.Context, s Publisher, confirm bool) (Publisher, error) {
	result := &publisherConfirmSession{
		s: s,
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

func (s *publisherConfirmSession) connection(ctx context.Context) (*amqp.Connection, error) {
	return s.s.connection(ctx)
}

func (s *publisherConfirmSession) channel(ctx context.Context) (*amqp.Channel, error) {
	return s.s.channel(ctx)
}

func (s *publisherConfirmSession) Close() error {
	return s.s.Close()
}

func (s *publisherConfirmSession) endpoint(ctx context.Context) (string, error) {
	return s.s.endpoint(ctx)
}

func (s *publisherConfirmSession) Publish(ctx context.Context, exchange string, routingKey string, publishing amqp.Publishing) error {
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

type publishRateLimiter struct {
	s          Publisher
	outgoing   chan publishRateLimiterOutgoing
	wg         sync.WaitGroup
	pending    sync.WaitGroup
	closing    chan struct{}
	t          *time.Ticker
	done       context.Context
	doneCancel context.CancelFunc
	m          sync.Mutex
}

type publishRateLimiterOutgoing struct {
	ctx        context.Context
	exchange   string
	queue      string
	publishing amqp.Publishing
	result     chan error
}

func newPublishRateLimiter(s Publisher, rate float64) Publisher {
	result := &publishRateLimiter{
		s:        s,
		outgoing: make(chan publishRateLimiterOutgoing, 1+int(rate)),
		t:        time.NewTicker(time.Duration(float64(time.Second) / rate)),
		closing:  make(chan struct{}),
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
	return s.s.connection(ctx)
}

func (s *publishRateLimiter) channel(ctx context.Context) (*amqp.Channel, error) {
	return s.s.channel(ctx)
}

func (s *publishRateLimiter) endpoint(ctx context.Context) (string, error) {
	return s.s.endpoint(ctx)
}

func (s *publishRateLimiter) Publish(ctx context.Context, exchange string, queue string, publishing amqp.Publishing) error {

	if !s.increasePending() {
		return ErrClosed
	}
	defer s.releasePending()

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
	amqpEndpoint   string
	amqpConnection *amqp.Connection
	amqpChannel    *amqp.Channel
}

func newBasicSession(ctx context.Context, endpoint string, username string, password string, vhost string) (Publisher, error) {
	result := &basicSession{
		amqpEndpoint: endpoint,
	}
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

func (s *basicSession) addHook(hookName string, hook hookFn) bool {
	return false
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

func (s *basicSession) closeInternal() {
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

	err := s.amqpChannel.Publish(exchange, routingKey, true, false, publishing)
	if err != nil {
		return xerrors.Errorf("ERR publishing to %s:%s:%s with %v: %w", s.endpoint, exchange, routingKey, err, ErrPublishFailed)
	}

	return nil
}

type monitoringSession struct {
	s        Publisher
	observer func(event string)
}

func newMonitoringSession(s Publisher, observer func(event string)) Publisher {
	result := &monitoringSession{
		s:        s,
		observer: observer,
	}

	s.addHook(hookDial, result.hookDial)
	s.addHook(hookRetry, result.hookRetry)
	s.addHook(hookUndeliverable, result.hookUndeliverable)
	s.addHook(hookFlow, result.hookFlow)
	s.addHook(hookPublisherConfirmTimeout, result.hookPublisherConfirmTimeout)
	s.addHook(hookConnectionBlocked, result.hookConnectionBlocked)
	s.addHook(hookPublishTimeout, result.hookPublishTimeout)

	return result
}

func (s *monitoringSession) addHook(hookName string, hook hookFn) bool {
	return s.s.addHook(hookName, hook)
}

func (s *monitoringSession) Publish(ctx context.Context, exchange string, routingKey string, publishing amqp.Publishing) error {
	err := s.s.Publish(ctx, exchange, routingKey, publishing)
	if err != nil {
		s.handleError("", err)
	}

	return err
}

func (s *monitoringSession) connection(ctx context.Context) (*amqp.Connection, error) {
	result, err := s.s.connection(ctx)
	if err != nil {
		s.handleError("", err)
	} else if result == nil {
		s.handleError("", context.Canceled)
	}

	return result, err
}

func (s *monitoringSession) channel(ctx context.Context) (*amqp.Channel, error) {
	result, err := s.s.channel(ctx)
	if err != nil {
		s.handleError("", err)
	} else if result == nil {
		s.handleError("", context.Canceled)
	}

	return result, err
}

func (s *monitoringSession) endpoint(ctx context.Context) (string, error) {
	result, err := s.s.endpoint(ctx)
	if err != nil {
		s.handleError("", err)
	} else if result == "" {
		s.handleError("", context.Canceled)
	}

	return result, err
}

func (s *monitoringSession) Close() error {
	err := s.s.Close()
	if err != nil {
		s.handleError("", err)
	}

	return err
}

func (s *monitoringSession) hookPublishTimeout(args ...interface{}) {
	s.observer("event_publish_timeout")
}

func (s *monitoringSession) hookDial(args ...interface{}) {
	s.observer("event_dial")
}

func (s *monitoringSession) hookRetry(args ...interface{}) {
	err := args[0].(error)
	s.handleError("event_retry_", err)
}

func (s *monitoringSession) hookUndeliverable(args ...interface{}) {
	s.observer("event_undeliverable_message")
}

func (s *monitoringSession) hookFlow(args ...interface{}) {
	flow := args[0].(bool)
	if flow {
		s.observer("event_flow_ok")
	} else {
		s.observer("event_flow_paused")
	}
}

func (s *monitoringSession) hookConnectionBlocked(args ...interface{}) {
	s.observer("event_connection_blocked")
}

func (s *monitoringSession) hookPublisherConfirmTimeout(args ...interface{}) {
	s.observer("event_publisher_confirm_timeout")
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
	}

	s.observer(prefix + event)
}
