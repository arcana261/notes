package main

import (
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
	endpointsFlag   stringListFlagType
	queuesFlag      stringListFlagType
	publishRateFlag *float64
	wg              sync.WaitGroup
	done            chan struct{}
	publishMsg      amqp.Publishing
	appStatus       stats
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
	publishMsg = amqp.Publishing{
		DeliveryMode: 2,
		Body:         []byte("Hello"),
	}

	done = make(chan struct{})
	appStatus = stats{
		items: make(map[string]*statsItem),
	}
}

func publisherOnEndpointQueue(endpoint string, queue string, rate float64) {
	defer wg.Done()

	t := time.NewTicker(backoff)
	defer t.Stop()

	for {
		select {
		case <-done:
			return

		default:
		}

		publisherOnEndpointQueueLoop(endpoint, queue, rate)

		select {
		case <-done:
			return

		case <-t.C:
		}
	}
}

func publisherOnEndpointQueueLoop(endpoint string, queue string, rate float64) {
	fmt.Printf("Attemting to connect to %s\n", endpoint)

	connection, err := amqp.Dial(fmt.Sprintf("amqp://guest:guest@%s/", endpoint))
	if err != nil {
		fmt.Printf("ERR connecting to %s with %v\n", endpoint, err)
		return
	}
	defer connection.Close()

	fmt.Printf("Connection to %s succeeded!\n", endpoint)

	channel, err := connection.Channel()
	if err != nil {
		fmt.Printf("ERR opening channel to %s with %v\n", endpoint, err)
		return
	}
	defer channel.Close()

	sleep := time.Duration(float64(time.Second) / rate)
	t := time.NewTicker(sleep)
	defer t.Stop()

	statusName := fmt.Sprintf("Publish %s:%s", endpoint, queue)

	for {
		select {
		case <-done:
			return

		default:
		}

		fmt.Printf("Sending message...")

		err = channel.Publish("", queue, true, false, publishMsg)
		if err != nil {
			fmt.Printf("ERR publishing to %s with %v\n", endpoint, err)
			return
		}

		appStatus.Observe(statusName, 1.0)

		select {
		case <-done:
			return

		case <-t.C:
		}
	}
}

func reporter() {
	defer wg.Done()

	t := time.NewTicker(5 * time.Second)
	defer t.Stop()

	for {
		select {
		case <-done:
			return

		case <-t.C:
			report()
		}
	}
}

func report() {
	fmt.Printf("------------------\n")
	appStatus.Report()
	fmt.Printf("------------------\n")
}

func main() {
	flag.Parse()

	if len(endpointsFlag) == 0 || len(queuesFlag) == 0 || *publishRateFlag == 0 {
		flag.Usage()
		return
	}

	if *publishRateFlag > 0 {
		for _, endpoint := range endpointsFlag {
			for _, queue := range queuesFlag {
				wg.Add(1)
				go publisherOnEndpointQueue(endpoint, queue, *publishRateFlag)
			}
		}
	}

	wg.Add(1)
	go reporter()

	var signal_channel chan os.Signal
	signal_channel = make(chan os.Signal, 1)
	signal.Notify(signal_channel, os.Interrupt)

	<-signal_channel

	close(done)
	wg.Wait()
}
