package cmd

import (
	"bytes"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	"time"

	"github.com/stretchr/testify/assert"

	"gorm.io/driver/sqlite"
	"gorm.io/gorm"
)

func newTestApplication(t *testing.T) (app Application) {
	var err error

	app.databasePath = ":memory:"
	app.db, err = gorm.Open(sqlite.Open(app.databasePath), &gorm.Config{})
	assert.Nil(t, err)

	app.db.AutoMigrate(
		&confession{},
		&reaction{},
	)

	return
}

func TestAddReactionToOldConfession(t *testing.T) {
	app := newTestApplication(t)

	confession := confession{
		Confession: "2 week old test confession",
		IpAddress:  "127.0.0.1",
		Public:     true,
		Background: "background.png",
		Model: gorm.Model{
			CreatedAt: time.Now().Add(-24 * 7 * 2 * time.Hour),
		},
	}

	assert.Nil(t, app.db.Create(&confession).Error)

	app.setupRouter()
	w := httptest.NewRecorder()
	reactionInputJson, err := json.Marshal(reactionInput{Emoji: "❤️"})
	assert.Nil(t, err)
	req, _ := http.NewRequest("POST", "/api/react/1", bytes.NewReader(reactionInputJson))
	app.router.ServeHTTP(w, req)
	assert.Equal(t, http.StatusBadRequest, w.Code)
	assert.Equal(t, "confession too old", w.Body.String())
}

func TestAddReactionToConfession(t *testing.T) {
	app := newTestApplication(t)

	confession := confession{
		Confession: "day old test confession",
		IpAddress:  "127.0.0.1",
		Public:     true,
		Background: "background.png",
		Model: gorm.Model{
			CreatedAt: time.Now().Add(-24 * time.Hour),
		},
	}

	assert.Nil(t, app.db.Create(&confession).Error)

	app.setupRouter()
	w := httptest.NewRecorder()
	reactionInputJson, err := json.Marshal(reactionInput{Emoji: "❤️"})
	assert.Nil(t, err)
	req, _ := http.NewRequest("POST", "/api/react/1", bytes.NewReader(reactionInputJson))
	app.router.ServeHTTP(w, req)
	assert.Equal(t, http.StatusOK, w.Code)
	assert.Equal(t, "{\"reactions\":{\"❤️\":1}}", w.Body.String())
}
