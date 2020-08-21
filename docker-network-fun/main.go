package main

import (
	"bytes"
	"context"
	"flag"
	"fmt"
	"os"
	"os/signal"
	"strings"
	"sync"
	"time"

	"github.com/streadway/amqp"
)

const (
	backoff           = 100 * time.Millisecond
	operationTimeout  = 1 * time.Second
	connectionTimeout = 5 * time.Second
	maxRetry          = -1
)

type stringListFlagType []string

var (
	endpointsFlag          stringListFlagType
	queuesFlag             stringListFlagType
	publishRateFlag        *float64
	consumeRateFlag        *float64
	publisherConfirmFlag   *bool
	messageSizeFlag        *int
	prefetchFlag           *int
	incrementalPublishFlag *bool
	maxPublishCountFlag    *int
	maxConsumeCountFlag    *int
	checkDataLossFlag      *bool

	wg            sync.WaitGroup
	reporterWg    sync.WaitGroup
	globalContext context.Context
	publishMsg    amqp.Publishing
	appStatus     stats
)

func (i *stringListFlagType) String() string {
	return fmt.Sprint(*i)
}

func (i *stringListFlagType) Set(value string) error {
	for _, value := range strings.Split(value, ",") {
		value = strings.TrimSpace(value)
		*i = append(*i, value)
	}

	return nil
}

func init() {
	flag.Var(&endpointsFlag, "endpoint", "comma-seperated list of endpoints")
	flag.Var(&queuesFlag, "queue", "comma-seperated list of queues")
	publishRateFlag = flag.Float64("publishrate", 0, "publish rate to queues")
	consumeRateFlag = flag.Float64("consumerate", 0, "consume rate from queues")
	prefetchFlag = flag.Int("prefetch", 0, "amount of prefetch from queue")
	publisherConfirmFlag = flag.Bool("confirm", false, "enable publisher confirms")
	messageSizeFlag = flag.Int("size", 5, "size of messages published to rabbitmq")
	incrementalPublishFlag = flag.Bool("incrementalpublish", false, "publish messages with a incrementally increasing prefix counter")
	maxPublishCountFlag = flag.Int("maxpublishcount", 0, "publish at most this number of messages to each queue+endpoint")
	maxConsumeCountFlag = flag.Int("maxconsumecount", 0, "consume at most this number of messages from each queue+endpoint")
	checkDataLossFlag = flag.Bool("checkdataloss", false, "publish/consume such at we could check for data loss.")

	publishMsg = amqp.Publishing{
		DeliveryMode: 2,
		Body:         []byte("Hello"),
	}

	appStatus = NewStats()

	flag.Usage = func(original func()) func() {
		return func() {
			original()

			fmt.Println()
			fmt.Println("Examples:")
			fmt.Println()
			fmt.Println("Publish 1KB messages at rate of 10,000 message/persec to queue `all.queue`")
			fmt.Println("\tgo run ./ -endpoint 192.168.240.3 -queue all.queue -publishrate 10000 -size 1000")
			fmt.Println()
			fmt.Println("Publish & consume at the same time, checking for data losses with publisher confirms")
			fmt.Println("\tgo run ./ -endpoint $(rabbitmq_virtual_ip_address 0) -queue all.queue -checkdataloss -maxpublishcount 1000000000 -consumerate 100 -prefetch 10 -publishrate 2000 -size 2048 -confirm")
		}
	}(flag.Usage)
}

func consumerOnEndpointQueue(endpoint string, queue string, rate float64, prefetch int, maxCount int, checkDataLoss bool) {
	defer wg.Done()

	counter := 0

	metricPrefix := fmt.Sprintf("%s_%s", endpoint, queue)
	metricConsume := fmt.Sprintf("%s_consume", metricPrefix)
	metricDataLoss := fmt.Sprintf("%s_data_loss", metricPrefix)

	if checkDataLoss {
		appStatus.Set(metricDataLoss, 0.0)
	}

	fmt.Fprintf(os.Stderr, "Attemting to make session to %s\n", endpoint)
	session, err := NewConsumer(globalContext, endpoint, "guest", "guest", "", queue, prefetch, connectionTimeout, backoff, maxRetry, operationTimeout)
	if err != nil {
		if err != context.DeadlineExceeded && err != context.Canceled {
			panic(fmt.Sprintf("could not create session to %s with %v", endpoint, err))
		}
		return
	}

	session = NewConsumerRateLimiter(session, rate)

	session = NewConsumerMonitoring(session, func(event string) {
		if event == "event_consume" {
			appStatus.Observe(metricConsume, 1.0)
		}
		appStatus.Increment(fmt.Sprintf("%s_%s", metricPrefix, event), 1.0)
	})

	defer session.Close()
	fmt.Fprintf(os.Stderr, "Session established to %s\n", endpoint)

	fmt.Fprintf(os.Stderr, "Attemting to make consume channel to %s\n", endpoint)
	ch, err := session.Consume(globalContext)
	if err != nil {
		if err != context.DeadlineExceeded && err != context.Canceled {
			panic(fmt.Sprintf("could not create session to %s with %v", endpoint, err))
		}
		return
	}

	foundFirstPacket := false

	for {
		select {
		case <-globalContext.Done():
			return

		case delivery, ok := <-ch:
			if !ok {
				select {
				case <-globalContext.Done():
					return

				default:
					panic(fmt.Sprintf("consumer channel got closed"))
				}
			}

			reject := false
			if checkDataLoss {
				msg := string(delivery.Body)
				if !foundFirstPacket {
					if count, err := fmt.Sscanf(msg, "HEAD:%d:", &maxCount); err != nil || count != 1 {
						fmt.Fprintf(os.Stderr, "Can not find data checking head, found: %v...\n", msg[:10])
						reject = true
						appStatus.Increment(metricDataLoss, 1.0)
					} else {
						foundFirstPacket = true
					}
				} else {
					if counter+1 < maxCount {
						var n int
						if count, err := fmt.Sscanf(msg, "ITEM:%d:", &n); err != nil || count != 1 {
							fmt.Fprintf(os.Stderr, "Expected packet <ITEM> but found: %v...\n", msg[:10])
							reject = true
							appStatus.Increment(metricDataLoss, 1.0)
						} else if n != counter {
							fmt.Fprintf(os.Stderr, "Expected packet number %v but found: %v...\n", counter, n)
							reject = true
							appStatus.Increment(metricDataLoss, 1.0)
						}
					} else if strings.Index(msg, "TAIL:") != 0 {
						fmt.Fprintf(os.Stderr, "Can not find data checking tail, found: %v...\n", msg[:10])
						reject = true
						appStatus.Increment(metricDataLoss, 1.0)
					}
				}
			}

			if !reject {
				err := session.Acknowledge(globalContext, delivery)
				if err != nil {
					if err != context.DeadlineExceeded && err != context.Canceled {
						panic(fmt.Sprintf("could not acknowledge message to %s with %v", endpoint, err))
					}
					return
				}
			} else {
				err := session.Reject(globalContext, delivery)
				if err != nil {
					if err != context.DeadlineExceeded && err != context.Canceled {
						panic(fmt.Sprintf("could not reject message to %s with %v", endpoint, err))
					}
					return
				}
			}

			counter = counter + 1

			if maxCount > 0 && counter >= maxCount {
				return
			}
		}
	}
}

func publisherOnEndpointQueue(endpoint string, queue string, rate float64, confirm bool, incremental bool, maxCount int, checkDataLoss bool) {
	defer wg.Done()

	counter := 0

	metricPrefix := fmt.Sprintf("%s_%s", endpoint, queue)
	metricPublish := fmt.Sprintf("%s_publish", metricPrefix)
	metricReturned := fmt.Sprintf("%s_returned", metricPrefix)

	deliveryReturned := func(amqp.Return) {
		appStatus.Increment(metricReturned, 1.0)
	}

	fmt.Fprintf(os.Stderr, "Attemting to make session to %s\n", endpoint)
	session, err := NewPublisher(globalContext, endpoint, "guest", "guest", "", confirm, deliveryReturned, connectionTimeout, backoff, maxRetry, operationTimeout)
	if err != nil {
		if err != context.DeadlineExceeded && err != context.Canceled {
			panic(fmt.Sprintf("could not create session to %s with %v", endpoint, err))
		}
		return
	}

	session = NewPublishRateLimiter(session, rate)

	session = NewPublisherMonitoring(session, func(event string) {
		if event == "event_publish_ok" {
			appStatus.Observe(metricPublish, 1.0)
		}
		appStatus.Increment(fmt.Sprintf("%s_%s", metricPrefix, event), 1.0)
	})

	defer session.Close()

	fmt.Fprintf(os.Stderr, "Session established to %s\n", endpoint)

	for {
		select {
		case <-globalContext.Done():
			return

		default:
		}

		publishing := makePublishing(incremental, counter, maxCount, checkDataLoss)
		err = session.Publish(globalContext, "", queue, publishing)
		if err != nil {
			if err != context.DeadlineExceeded && err != ErrClosed {
				panic(fmt.Sprintf("could not publish to %s with %v", endpoint, err))
			}
			return
		}

		counter = counter + 1

		if maxCount > 0 && counter >= maxCount {
			return
		}
	}
}

func makePublishing(incremental bool, counter int, maxCount int, checkDataLoss bool) amqp.Publishing {
	if !incremental && !checkDataLoss {
		return publishMsg
	}

	result := publishMsg
	var prefix string

	if checkDataLoss && counter == 0 {
		prefix = fmt.Sprintf("HEAD:%v:", maxCount)
	} else if checkDataLoss && counter+1 == maxCount {
		prefix = fmt.Sprintf("TAIL:")
	} else {
		prefix = fmt.Sprintf("ITEM:%v:", counter)
	}

	result.Body = make([]byte, 0, len(publishMsg.Body))
	result.Body = append(result.Body, []byte(prefix)...)
	if len(result.Body) < len(publishMsg.Body) {
		result.Body = append(result.Body, publishMsg.Body[len(result.Body):]...)
	} else if len(result.Body) > len(publishMsg.Body) {
		panicMsg := fmt.Sprintf("FATAL ERR: CONSTRUCTED MESSAGE TOO LARGE, CONSIDER ADDING `-size %v` TO SEND MESSAGES AT LEAST %v SIZE BIG\n", len(result.Body), len(result.Body))
		panic(panicMsg)
	}

	return result
}

func reporter() {
	defer reporterWg.Done()

	t := time.NewTicker(2 * time.Second)
	defer t.Stop()

	for {
		select {
		case <-globalContext.Done():
			report()
			return

		case <-t.C:
			report()
		}
	}
}

func report() {
	fmt.Fprintf(os.Stderr, "------------------\n")
	appStatus.Report()
	fmt.Fprintf(os.Stderr, "------------------\n")
}

func generateString(length int) string {
	var buff bytes.Buffer
	hello := "Hello, World!;"

	for i := 0; i < length; i++ {
		buff.WriteByte(hello[i%len(hello)])
	}

	return buff.String()
}

func main() {
	flag.Parse()
	flagsAreSane := true

	if len(endpointsFlag) == 0 {
		fmt.Fprintf(os.Stderr, "ERR: No endpoints provided\n")
		flagsAreSane = false
	}

	if len(queuesFlag) == 0 {
		fmt.Fprintf(os.Stderr, "ERR: No queues provided\n")
		flagsAreSane = false
	}

	if *publishRateFlag <= 0.000001 && *consumeRateFlag <= 0.000001 {
		fmt.Fprintf(os.Stderr, "At least `-publishrate` or `-consumerate` should be provided to enable publisher/consumer operations\n")
		flagsAreSane = false
	}

	if *publishRateFlag <= 0.000001 {
		if *incrementalPublishFlag {
			fmt.Fprintf(os.Stderr, "-incrementalpublish provided but no -publishrate is provided\n")
			flagsAreSane = false
		}

		if *maxPublishCountFlag > 0 {
			fmt.Fprintf(os.Stderr, "-maxpublishcount provided but no -publishrate is provided\n")
			flagsAreSane = false
		}

		if *publisherConfirmFlag {
			fmt.Fprintf(os.Stderr, "-confirm provided but no -publishrate is provided\n")
			flagsAreSane = false
		}
	} else {
		if *maxPublishCountFlag < 0 {
			fmt.Fprintf(os.Stderr, "-publishrate provided but also -maxpublishcount should be provided with a positive value\n")
			flagsAreSane = false
		}

		if *incrementalPublishFlag && *checkDataLossFlag {
			fmt.Fprintf(os.Stderr, "-publishrate provided but also -incrementalpublish and -checkdataloss can not be used both at the same time\n")
			flagsAreSane = false
		}
		if *messageSizeFlag <= 0 {
			fmt.Fprintf(os.Stderr, "`-publishrate provided but also -size` should be provided with positive value\n")
			flagsAreSane = false
		}

		if *checkDataLossFlag && *maxPublishCountFlag == 0 {
			fmt.Fprintf(os.Stderr, "-publishrate provided but also -checkdataloss on publishers requires -maxpublishcount flag\n")
			flagsAreSane = false
		}
	}

	if *consumeRateFlag <= 0.000001 {
		if *prefetchFlag > 0 {
			fmt.Fprintf(os.Stderr, "-prefetch provided but no -consumerate is provided\n")
			flagsAreSane = false
		}
		if *maxConsumeCountFlag > 0 {
			fmt.Fprintf(os.Stderr, "-maxconsumecount provided but no -consumerate is provided\n")
			flagsAreSane = false
		}
	} else {
		if *prefetchFlag == 0 {
			fmt.Fprintf(os.Stderr, "-consumerate provided but also -prefetch should be provided\n")
			flagsAreSane = false
		}
		if *maxConsumeCountFlag > 0 && *checkDataLossFlag {
			fmt.Fprintf(os.Stderr, "-consumerate provided but -checkdataloss on consumers does not require -maxconsumecount and is done automatically\n")
			flagsAreSane = false
		}
	}

	if !flagsAreSane {
		flag.Usage()
		os.Exit(-1)
		return
	}

	var globalCancel context.CancelFunc
	globalContext, globalCancel = context.WithCancel(context.Background())

	publishMsg.Body = []byte(generateString(*messageSizeFlag))
	maxPublishCount := *maxPublishCountFlag

	if *checkDataLossFlag {
		maxPublishCount = maxPublishCount + 2
	}

	if *publishRateFlag > 0 {
		for _, endpoint := range endpointsFlag {
			for _, queue := range queuesFlag {
				wg.Add(1)
				go publisherOnEndpointQueue(endpoint, queue, *publishRateFlag, *publisherConfirmFlag, *incrementalPublishFlag, maxPublishCount, *checkDataLossFlag)
			}
		}
	}

	if *consumeRateFlag > 0 {
		for _, endpoint := range endpointsFlag {
			for _, queue := range queuesFlag {
				wg.Add(1)
				go consumerOnEndpointQueue(endpoint, queue, *consumeRateFlag, *prefetchFlag, *maxConsumeCountFlag, *checkDataLossFlag)
			}
		}
	}

	workersDone := make(chan struct{})
	go func() {
		wg.Wait()
		close(workersDone)
	}()

	reporterWg.Add(1)
	go reporter()

	var signalChannel chan os.Signal
	signalChannel = make(chan os.Signal, 1)
	signal.Notify(signalChannel, os.Interrupt)

	select {
	case <-workersDone:
		globalCancel()
		reporterWg.Wait()

	case <-signalChannel:
		globalCancel()
	}

	wg.Wait()
	reporterWg.Wait()
}
