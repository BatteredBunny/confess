package cmd

import (
	"encoding/json"
	"log"
	"net/http"
	"strconv"
	"strings"

	"slices"

	"github.com/gin-gonic/gin"
)

func (app *Application) setupRouter() {
	app.router = gin.Default()
	app.router.ForwardedByClientIP = app.behindReverseProxy
	app.router.SetTrustedProxies([]string{app.trustedProxy})

	app.router.StaticFile("/", app.staticPath+"/html/index.html")
	app.router.Static("/static", app.staticPath)
	app.router.POST("/api/confess", app.confess)
	app.router.POST("/api/react/:confessionId", app.addReaction)
	app.router.Any("/ws", func(c *gin.Context) {
		app.ws.HandleRequest(c.Writer, c.Request)
	})
}

// Curl command for testing
// curl 'http://localhost:3000/api/confess' --data-raw 'confession=I am confessing something'
type confessInput struct {
	Confession string `form:"confession" json:"confession"`
	Public     bool   `form:"public" default:"false" json:"public"`
	Background string `form:"background" json:"background"`
}

type reactionInput struct {
	Emoji string `json:"emoji"`
}

func (app *Application) confess(c *gin.Context) {
	var input confessInput
	if err := c.BindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, err.Error())
		return
	}

	rawConfession := strings.TrimSpace(input.Confession)
	if rawConfession == "" {
		c.String(http.StatusBadRequest, "confession cannot be empty")
		return
	} else if len(rawConfession) > MaxBodySize {
		c.String(http.StatusBadRequest, "confession cannot be longer than 1000 characters")
		return
	}

	// Validate background if provided
	background := ""
	if input.Background != "" {
		isValidBackground := false
		for _, validBg := range AvailableBackgrounds {
			if input.Background == validBg {
				isValidBackground = true
				background = input.Background
				break
			}
		}
		if !isValidBackground {
			c.String(http.StatusBadRequest, "invalid background image")
			return
		}
	}

	confession := confession{
		Confession: rawConfession,
		IpAddress:  c.ClientIP(),
		Public:     input.Public,
		Background: background,
	}

	if err := app.db.Create(&confession).Error; err != nil {
		log.Println("failed to add new confession:", err)
		c.String(http.StatusBadRequest, http.StatusText(http.StatusBadRequest))
		return
	}

	if err := app.sendNtfyNotification(confession); err != nil {
		log.Println("ntfy error:", err)
	}

	// Sends notification to all sessions
	if input.Public {
		bs, err := json.Marshal(newConfessionEvent(rawConfession, confession.CreatedAt, confession.ID, background))
		if err != nil {
			log.Println("failed to marshal json:", err)
		} else {
			if err := app.ws.Broadcast(bs); err != nil {
				log.Println("failed to send notification to websockets:", err)
			}
		}
	}

	c.String(http.StatusOK, http.StatusText(http.StatusOK))
}

func (app *Application) addReaction(c *gin.Context) {
	confessionIdStr := c.Param("confessionId")
	confessionId, err := strconv.ParseUint(confessionIdStr, 10, 32)
	if err != nil {
		c.String(http.StatusBadRequest, "invalid confession ID")
		return
	}

	var input reactionInput
	if err := c.BindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, err.Error())
		return
	}

	// validate emoji
	isValid := slices.Contains(ValidReactions, input.Emoji)
	if !isValid {
		c.String(http.StatusBadRequest, "invalid emoji")
		return
	}

	var confession confession
	if err := app.db.Where("id = ? AND public = true", confessionId).First(&confession).Error; err != nil {
		c.String(http.StatusNotFound, "confession not found")
		return
	}

	var existingReactions []reaction
	app.db.Where("confession_id = ? AND ip_address = ? AND emoji = ?",
		confessionId, c.ClientIP(), input.Emoji).Find(&existingReactions)

	if len(existingReactions) > 0 {
		if err := app.db.Delete(&existingReactions[0]).Error; err != nil {
			log.Println("failed to remove reaction:", err)
			c.String(http.StatusInternalServerError, "failed to remove reaction")
			return
		}
	} else {
		// check reaction count limit first
		var reactionCount int64
		app.db.Model(&reaction{}).Where("confession_id = ?", confessionId).Count(&reactionCount)
		if reactionCount >= MaxReactionsPerConfession {
			c.String(http.StatusTooManyRequests, "too many reactions on this confession")
			return
		}

		// add reaction
		newReaction := reaction{
			ConfessionID: uint(confessionId),
			Emoji:        input.Emoji,
			IpAddress:    c.ClientIP(),
		}

		if err := app.db.Create(&newReaction).Error; err != nil {
			log.Println("failed to add reaction:", err)
			c.String(http.StatusInternalServerError, "failed to add reaction")
			return
		}
	}

	// get reaction counts for this confession
	reactionCounts := app.getReactionCounts(uint(confessionId))

	// send reaction update via ws
	bs, err := json.Marshal(newReactionEvent(uint(confessionId), reactionCounts))
	if err != nil {
		log.Println("failed to marshal reaction json:", err)
	} else {
		if err := app.ws.Broadcast(bs); err != nil {
			log.Println("failed to send reaction notification to websockets:", err)
		}
	}

	c.JSON(http.StatusOK, gin.H{"reactions": reactionCounts})
}

func (app *Application) getReactionCounts(confessionId uint) map[string]int {
	reactionCounts := make(map[string]int)

	var reactions []reaction
	app.db.Where("confession_id = ?", confessionId).Find(&reactions)

	for _, r := range reactions {
		reactionCounts[r.Emoji]++
	}

	return reactionCounts
}
