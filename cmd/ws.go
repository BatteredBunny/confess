package cmd

import (
	"encoding/json"
	"log"
	"time"

	"github.com/olahol/melody"
)

type wsEventType uint

const (
	initialDataEventType wsEventType = iota
	confessionEventType
	reactionEventType
)

type wsEventCommons struct {
	Type wsEventType `json:"type"`
}

// Event used for sending the initial data on connect
type initialDataEventInner struct {
	ID         uint           `json:"id"`
	Confession string         `json:"confession"`
	Date       time.Time      `json:"date"`
	Reactions  map[string]int `json:"reactions"`
	Background string         `json:"background"`
}
type initialDataEvent struct {
	Confessions []initialDataEventInner `json:"confessions"`

	wsEventCommons
}

func newInitialDataEvent(Confessions []initialDataEventInner) initialDataEvent {
	return initialDataEvent{
		Confessions: Confessions,
		wsEventCommons: wsEventCommons{
			Type: initialDataEventType,
		},
	}
}

// Event sent when a new confession is encountered
type confessionEvent struct {
	ID         uint           `json:"id"`
	Confession string         `json:"confession"`
	Date       time.Time      `json:"date"`
	Reactions  map[string]int `json:"reactions"`
	Background string         `json:"background"`
	wsEventCommons
}

func newConfessionEvent(Confession string, Date time.Time, ID uint, Background string) confessionEvent {
	return confessionEvent{
		ID:         ID,
		Confession: Confession,
		Date:       Date,
		Reactions:  make(map[string]int), // new confessions start with no reactions
		Background: Background,
		wsEventCommons: wsEventCommons{
			Type: confessionEventType,
		},
	}
}

// event sent when reactions are updated
type reactionEvent struct {
	ConfessionID uint           `json:"confessionId"`
	Reactions    map[string]int `json:"reactions"`
	wsEventCommons
}

func newReactionEvent(ConfessionID uint, Reactions map[string]int) reactionEvent {
	return reactionEvent{
		ConfessionID: ConfessionID,
		Reactions:    Reactions,
		wsEventCommons: wsEventCommons{
			Type: reactionEventType,
		},
	}
}

func (app *Application) setupWebsocket() {
	app.ws = melody.New()
	app.ws.HandleConnect(app.handleConnectWs)
	app.ws.HandleDisconnect(app.handleDisconnectWs)
}

func (app *Application) handleConnectWs(s *melody.Session) {
	// Fetch 5 recent confessions in the last week
	var weekAgo = time.Now().Add(-7 * 24 * time.Hour)

	var confessions []confession
	if err := app.db.
		Preload("Reactions").
		Order("created_at desc").
		Where("public = true").
		Where("created_at > ?", weekAgo).
		Limit(5).
		Find(&confessions).Error; err != nil {
		log.Println("failed to fetch confessions:", err)
		return
	}

	var initialConfessions []initialDataEventInner
	for _, confession := range confessions {
		reactionCounts := make(map[string]int)
		for _, reaction := range confession.Reactions {
			reactionCounts[reaction.Emoji]++
		}

		initialConfessions = append(initialConfessions, initialDataEventInner{
			ID:         confession.ID,
			Confession: confession.Confession,
			Date:       confession.CreatedAt,
			Reactions:  reactionCounts,
			Background: confession.Background,
		})
	}

	bs, err := json.Marshal(newInitialDataEvent(initialConfessions))
	if err != nil {
		log.Println("failed to marshal json for initial event:", err)
		return
	}
	if err := s.Write(bs); err != nil {
		log.Println("failed to send initial info:", err)
	}
}

func (app *Application) handleDisconnectWs(s *melody.Session) {
}
