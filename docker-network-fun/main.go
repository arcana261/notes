package main

import (
	"bytes"
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
	backoff = 5 * time.Second
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

	wg         sync.WaitGroup
	reporterWg sync.WaitGroup
	done       chan struct{}
	publishMsg amqp.Publishing
	appStatus  stats
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

	done = make(chan struct{})
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

	t := time.NewTicker(backoff)
	defer t.Stop()

	counter := 0
	reconnectionStatusName := fmt.Sprintf("Publish Reconnection  %s:%s", endpoint, queue)

	for {
		select {
		case <-done:
			return

		default:
		}

		counter = publisherOnEndpointQueueLoop(endpoint, queue, rate, confirm, incremental, counter, maxCount, checkDataLoss)

		if maxCount > 0 && counter >= maxCount {
			return
		}

		select {
		case <-done:
			return

		case <-t.C:
		}

		appStatus.Increment(reconnectionStatusName, 1.0)
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

func publisherOnEndpointQueueLoop(endpoint string, queue string, rate float64, confirm bool, incremental bool, counter int, maxCount int, checkDataLoss bool) int {
	fmt.Fprintf(os.Stderr, "Attemting to connect to %s\n", endpoint)

	var err error
	var connection *amqp.Connection
	var channel *amqp.Channel

	defer func() {
		go func() {
			if channel != nil {
				err = channel.Close()
				if err != nil {
					fmt.Fprintf(os.Stderr, "WARN can not close channel to %s with %v", endpoint, err)
				}
			}

			if connection != nil {
				err = connection.Close()
				if err != nil {
					fmt.Fprintf(os.Stderr, "WARN can not close connection to %s with %v", endpoint, err)
				}
			}
		}()
	}()

	connection, err = amqp.Dial(fmt.Sprintf("amqp://guest:guest@%s/", endpoint))
	if err != nil {
		fmt.Fprintf(os.Stderr, "ERR connecting to %s with %v\n", endpoint, err)
		return counter
	}

	fmt.Fprintf(os.Stderr, "Connection to %s succeeded!\n", endpoint)

	channel, err = connection.Channel()
	if err != nil {
		fmt.Fprintf(os.Stderr, "ERR opening channel to %s with %v\n", endpoint, err)
		return counter
	}

	var confirms chan amqp.Confirmation

	if confirm {
		confirms = channel.NotifyPublish(make(chan amqp.Confirmation, 1))

		if err := channel.Confirm(false); err != nil {
			fmt.Fprintf(os.Stderr, "ERR putting channel into confirmation mode on %s with %v", endpoint, err)
			return counter
		}
	}

	notifyBlock := connection.NotifyBlocked(make(chan amqp.Blocking, 1))

	sleep := time.Duration(float64(time.Second) / rate)
	t := time.NewTicker(sleep)
	defer t.Stop()

	rateStatusName := fmt.Sprintf("Publish Rate %s:%s", endpoint, queue)
	countStatusName := fmt.Sprintf("Publish Count %s:%s", endpoint, queue)
	blockingStatusName := fmt.Sprintf("Publish Blocking %s:%s", endpoint, queue)

	appStatus.Set(blockingStatusName, 0.0)

	eventMonitor := make(chan struct{})
	defer close(eventMonitor)

	ignoreBlockedPublished := make(chan struct{})

	go func() {
		for {
			select {
			case <-eventMonitor:
				return

			case blocking := <-notifyBlock:
				fmt.Fprintf(os.Stderr, "ERR: Publishing blocked on %s with `%v`\n", endpoint, blocking.Reason)
				appStatus.Set(blockingStatusName, 1.0)
				close(ignoreBlockedPublished)
			}
		}
	}()

	var publishing amqp.Publishing

	for {
		select {
		case <-done:
			return counter

		default:
		}

		errChannel := make(chan error, 1)

		go func() {
			publishing = makePublishing(incremental, counter, maxCount, checkDataLoss)
			err = channel.Publish("", queue, true, false, publishing)
			if err != nil {
				errChannel <- fmt.Errorf("%w: ERR publishing to %s", err, endpoint)
				return
			}

			if confirm {
				select {
				case <-ignoreBlockedPublished:
					errChannel <- nil
					return

				case confirmed := <-confirms:
					if !confirmed.Ack {
						errChannel <- fmt.Errorf("%w: ERR publisher confirm failed to %s", err, endpoint)
						return
					}
				}

				errChannel <- nil
			}
		}()

		select {
		case <-ignoreBlockedPublished:
			return counter

		case err = <-errChannel:
			if err != nil {
				fmt.Fprintf(os.Stderr, "%v\n", err)
				return counter
			}
		}

		counter = counter + 1
		appStatus.Observe(rateStatusName, 1.0)

		if incremental {
			appStatus.Set(countStatusName, float64(counter))
		}

		if maxCount > 0 && counter >= maxCount {
			return counter
		}

		select {
		case <-done:
			return counter

		case <-t.C:
		}
	}
}

func reporter() {
	defer reporterWg.Done()

	t := time.NewTicker(2 * time.Second)
	defer t.Stop()

	for {
		select {
		case <-done:
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
		close(done)
		reporterWg.Wait()

	case <-signalChannel:
		close(done)
		wg.Wait()
		reporterWg.Wait()
	}
}
