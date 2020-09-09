package main

import (
	"fmt"
	"os"
	"sort"
	"sync"
	"time"
)

type statsRecord struct {
	time  time.Time
	value float64
}

type statsItem struct {
	records []statsRecord
	mutex   sync.Mutex
}

type stats struct {
	items  map[string]*statsItem
	gauges map[string]float64
	mutex  sync.Mutex
}

func NewStats() stats {
	return stats{
		items:  make(map[string]*statsItem),
		gauges: make(map[string]float64),
	}
}

func (s *stats) Observe(name string, value float64) {
	item := s.getItem(name)

	item.mutex.Lock()
	defer item.mutex.Unlock()

	now := time.Now()

	if len(item.records) > 0 && now.Sub(item.records[len(item.records)-1].time) < 100*time.Millisecond {
		item.records[len(item.records)-1].value += value
	} else {
		if len(item.records) > 0 {
			value += item.records[len(item.records)-1].value
		}

		item.records = append(item.records, statsRecord{
			time:  time.Now(),
			value: value,
		})
	}
}

func (s *stats) Set(name string, value float64) {
	s.mutex.Lock()
	defer s.mutex.Unlock()

	s.gauges[name] = value
}

func (s *stats) Increment(name string, value float64) {
	s.mutex.Lock()
	defer s.mutex.Unlock()

	s.gauges[name] = s.gauges[name] + value
}

func (s *stats) Report() {
	s.mutex.Lock()
	defer s.mutex.Unlock()

	var names []string
	for name := range s.items {
		names = append(names, name)
	}
	sort.Strings(names)

	for _, name := range names {
		item := s.items[name]
		fmt.Fprintf(os.Stderr, "%s: %v/s\n", name, item.ReportPerSecond())
	}

	names = make([]string, 0)
	for name := range s.gauges {
		names = append(names, name)
	}
	sort.Strings(names)

	for _, name := range names {
		item := s.gauges[name]
		fmt.Fprintf(os.Stderr, "%s: %v\n", name, item)
	}
}

func (s *stats) getItem(name string) *statsItem {
	s.mutex.Lock()
	defer s.mutex.Unlock()

	result, ok := s.items[name]
	if !ok {
		result = &statsItem{}
		s.items[name] = result
	}

	return result
}

func (s *statsItem) ReportPerSecond() float64 {
	s.mutex.Lock()
	defer s.mutex.Unlock()

	now := time.Now()
	s.pruneUntil(now.Add(-10 * time.Second))

	if len(s.records) == 0 {
		return 0
	}

	timeDiff := float64(now.Sub(s.records[0].time) / time.Second)
	if timeDiff < 0.001 {
		return 0
	}

	return (s.records[len(s.records)-1].value - s.records[0].value) / timeDiff
}

func (s *statsItem) pruneUntil(t time.Time) {
	index := s.lowerBound(t)
	if index < 0 {
		return
	}

	s.records = s.records[index:]
}

func (s *statsItem) lowerBound(t time.Time) int {
	if len(s.records) == 0 {
		return -1
	}

	low := 0
	high := len(s.records) - 1

	for low < high {
		mid := (low + high) / 2
		if s.records[mid].time.Before(t) {
			low = mid + 1
		} else {
			high = mid
		}
	}

	return low
}
