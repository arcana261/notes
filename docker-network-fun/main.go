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
	publishTimeout    = 1 * time.Second
	connectionTimeout = 5 * time.Second
	maxRetry          = -1
)

type stringListFlagType []string

var (
	endpointsFlag          stringListFlagType
	queuesFlag             stringListFlagType
	publishRateFlag        *float64
	publisherConfirmFlag   *bool
	messageSizeFlag        *int
	incrementalPublishFlag *bool
	maxPublishCountFlag    *int
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
	publisherConfirmFlag = flag.Bool("confirm", false, "enable publisher confirms")
	messageSizeFlag = flag.Int("size", 5, "size of messages published to rabbitmq")
	incrementalPublishFlag = flag.Bool("incrementalpublish", false, "publish messages with a incrementally increasing prefix counter")
	maxPublishCountFlag = flag.Int("maxpublishcount", 0, "publish at most this number of messages to each queue+endpoint")
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
		}
	}(flag.Usage)
}

func publisherOnEndpointQueue(endpoint string, queue string, rate float64, confirm bool, incremental bool, maxCount int, checkDataLoss bool) {
	defer wg.Done()

	counter := 0

	fmt.Fprintf(os.Stderr, "Attemting to make session to %s\n", endpoint)
	session, err := NewPublisher(globalContext, endpoint, "guest", "guest", "", confirm, func(amqp.Return) {}, connectionTimeout, backoff, maxRetry, publishTimeout)
	if err != nil {
		if err != context.DeadlineExceeded && err != context.Canceled {
			panic(fmt.Sprintf("could not create session to %s with %v", endpoint, err))
		}
		return
	}

	session = newPublishRateLimiter(session, rate)
	if session == nil {
		return
	}

	metricPrefix := fmt.Sprintf("%s_%s", endpoint, queue)
	session = newMonitoringSession(session, func(event string) {
		appStatus.Increment(fmt.Sprintf("%s_%s", metricPrefix, event), 1.0)
	})
	if session == nil {
		return
	}

	defer session.Close()

	fmt.Fprintf(os.Stderr, "Session established to %s\n", endpoint)

	metricPublish := fmt.Sprintf("%s_publish", metricPrefix)

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
		appStatus.Observe(metricPublish, 1.0)

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
		prefix = fmt.Sprintf("HEAD:%v", maxCount)
	} else if checkDataLoss && counter+1 == maxCount {
		prefix = fmt.Sprintf("TAIL:")
	} else {
		prefix = fmt.Sprintf("%v:", counter)
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

	if *publishRateFlag <= 0.000001 {
		fmt.Fprintf(os.Stderr, "At least `-publishrate` or `-consumerate` should be provided to enable publisher/consumer operations\n")
		flagsAreSane = false
	}

	if *maxPublishCountFlag < 0 {
		fmt.Fprintf(os.Stderr, "-maxpublishcount should be provided with a positive value\n")
		flagsAreSane = false
	}

	if *publishRateFlag <= 0.000001 {
		if !*incrementalPublishFlag {
			fmt.Fprintf(os.Stderr, "-incrementalpublish provided but no -publishrate is provided\n")
			flagsAreSane = false
		}

		if *maxPublishCountFlag > 0 {
			fmt.Fprintf(os.Stderr, "-maxpublishcount provided but no -publishrate is provided\n")
			flagsAreSane = false
		}
	}

	if *incrementalPublishFlag && *checkDataLossFlag {
		fmt.Fprintf(os.Stderr, "-incrementalpublish and -checkdataloss can not be used both at the same time\n")
		flagsAreSane = false
	}

	if *messageSizeFlag <= 0 {
		fmt.Fprintf(os.Stderr, "`-size` should be provided with positive value\n")
		flagsAreSane = false
	}

	if *checkDataLossFlag && *publishRateFlag > 0.000001 && *maxPublishCountFlag == 0 {
		fmt.Fprintf(os.Stderr, "-checkdataloss on publishers requires -maxpublishcount flag\n")
		flagsAreSane = false
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
