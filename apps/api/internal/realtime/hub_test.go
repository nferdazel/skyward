package realtime

import (
	"sync"
	"testing"
)

func TestHubRegisterUnregister(t *testing.T) {
	hub := NewHub(nil)
	c := NewClient(hub, "u1")

	hub.Register(c)
	if len(hub.clients) != 1 {
		t.Fatalf("expected 1 client, got %d", len(hub.clients))
	}

	hub.Subscribe(c, "ch1")
	hub.Subscribe(c, "ch2")

	if len(hub.channels["ch1"]) != 1 {
		t.Fatalf("expected 1 subscriber in ch1")
	}

	hub.Unregister(c)

	if len(hub.clients) != 0 {
		t.Fatalf("expected 0 clients after unregister")
	}
	if len(hub.channels["ch1"]) != 0 {
		t.Fatalf("expected 0 subscribers in ch1")
	}
	if len(hub.channels["ch2"]) != 0 {
		t.Fatalf("expected 0 subscribers in ch2")
	}
}

func TestHubConcurrentSubscribeUnregister(t *testing.T) {
	hub := NewHub(nil)
	var wg sync.WaitGroup

	clients := make([]*Client, 50)
	for i := range clients {
		clients[i] = NewClient(hub, "user")
		hub.Register(clients[i])
	}

	for _, c := range clients {
		wg.Add(3)
		go func(cl *Client) {
			defer wg.Done()
			hub.Subscribe(cl, "fleet_aircraft")
			hub.Subscribe(cl, "route_assignments")
		}(c)
		go func(cl *Client) {
			defer wg.Done()
			hub.Broadcast("fleet_aircraft", "UPDATE")
		}(c)
		go func(cl *Client) {
			defer wg.Done()
			hub.Unregister(cl)
		}(c)
	}

	wg.Wait()
}
