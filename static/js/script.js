const confessional = document.getElementById('confessional')
const confessionalText = document.getElementById('confessional-text')
const submitConfession = document.getElementById('submit-confession')
const recentConfessions = document.getElementById('recent-confessions')
const confessionPublic = document.getElementById('confession-public')
const noConfessionsRecently = document.getElementById('no-confessions-recently')
const playMusic = document.getElementById('play-music')
const mascot = document.getElementById('mascot')

feather.replace();

const VALID_REACTIONS = ['❤️', '😭', '🐈']
const wsProtocol = window.location.protocol === 'https:' ? 'wss' : 'ws'
const wsUrl = `${wsProtocol}://${window.location.host}/ws`
const ws = new WebSocket(wsUrl)

const reactToConfetti = VALID_REACTIONS.reduce((acc, emoji) => {
  acc[emoji] = confetti.shapeFromText({ text: emoji });
  return acc;
}, {});

const explosionConfetti = confetti.shapeFromText({text: '🔥'})

mascot.addEventListener('click', function (e) {
    confetti({
        particleCount: 50,
        spread: 100,
        startVelocity: 15,
        flat: true,
        origin: {
            x: e.clientX / window.innerWidth,
            y: e.clientY / window.innerHeight
        },
        shapes: [explosionConfetti]
    })
})

const EVENT_TYPES = {
    INITIAL_DATA: 0,
    CONFESSION: 1,
    REACTION: 2
}

ws.onmessage = function (event) {
    const data = JSON.parse(event.data)

    if (data.type === EVENT_TYPES.INITIAL_DATA) {
        handleInitialData(data)
    } else if (data.type === EVENT_TYPES.CONFESSION) {
        handleNewConfession(data)
    } else if (data.type === EVENT_TYPES.REACTION) {
        handleReactionUpdate(data)
    }
}

function handleInitialData(data) {
    if (!data.confessions || data.confessions.length === 0) {
        noConfessionsRecently.classList.remove('hidden')
        return
    }

    data.confessions.forEach(confession => {
        recentConfessions.appendChild(createConfessionElement(confession))
    })
}

function handleNewConfession(confession) {
    noConfessionsRecently.classList.add('hidden')
    addConfession(confession)
}

function handleReactionUpdate(data) {
    const confessionCard = document.querySelector(`[data-confession-id="${data.confessionId}"]`)
    if (confessionCard) {
        updateReactionButtons(confessionCard, data.reactions, data.confessionId)
    }
}

function addConfession(confession) {
    recentConfessions.insertBefore(
        createConfessionElement(confession),
        recentConfessions.firstChild
    )

    while (recentConfessions.children.length > 5) {
        recentConfessions.removeChild(recentConfessions.lastChild)
    }
}

function createConfessionElement(confession) {
    const card = document.createElement('div')
    card.className = 'confession-card'
    card.setAttribute('data-confession-id', confession.id)

    if (confession.background) {
        card.style.backgroundImage = `url('/static/images/bg/${confession.background}')`
        card.classList.add('has-background')
    }

    const dateElement = document.createElement('div')
    dateElement.className = 'confession-date'
    dateElement.textContent = dayjs(confession.date).format('YYYY-MM-DD HH:mm:ss')

    const textElement = document.createElement('div')
    textElement.className = 'confession-text'
    textElement.textContent = confession.confession

    const reactionsContainer = document.createElement('div')
    reactionsContainer.className = 'confession-reactions'

    VALID_REACTIONS.forEach(emoji => {
        const button = createReactionButton(emoji, confession.reactions[emoji] || 0, confession.id)
        reactionsContainer.appendChild(button)
    })

    card.appendChild(dateElement)
    card.appendChild(textElement)
    card.appendChild(reactionsContainer)

    return card
}

function createReactionButton(emoji, count, confessionId) {
    const button = document.createElement('button')
    button.className = 'reaction-button'
    button.setAttribute('data-emoji', emoji)
    button.setAttribute('data-confession-id', confessionId)

    const emojiSpan = document.createElement('span')
    emojiSpan.className = 'reaction-emoji'
    emojiSpan.textContent = emoji

    const countSpan = document.createElement('span')
    countSpan.className = 'reaction-count'
    countSpan.textContent = count || ''

    button.appendChild(emojiSpan)
    if (count > 0) {
        button.appendChild(countSpan)
    }

    button.addEventListener('click', (e) => handleReaction(e, confessionId, emoji, button))

    return button
}

function updateReactionButtons(confessionCard, reactions, confessionId) {
    const reactionButtons = confessionCard.querySelectorAll('.reaction-button')

    reactionButtons.forEach(button => {
        const emoji = button.getAttribute('data-emoji')
        const count = reactions[emoji] || 0
        const countSpan = button.querySelector('.reaction-count')

        if (count > 0) {
            if (!countSpan) {
                const newCountSpan = document.createElement('span')
                newCountSpan.className = 'reaction-count'
                newCountSpan.textContent = count
                button.appendChild(newCountSpan)

                let rect = button.getBoundingClientRect()

                confetti({
                    particleCount: 15,
                    spread: 30,
                    startVelocity: 15,
                    origin: {
                        x: (rect.left + rect.width / 2) / window.innerWidth,
                        y: (rect.top + rect.height / 2) / window.innerHeight,
                    },
                    shapes: [reactToConfetti[emoji]]
                })
            } else if (countSpan.textContent != count) {
                countSpan.textContent = count
                confetti({
                    particleCount: 15,
                    spread: 30,
                    startVelocity: 15,
                    origin: {
                        x: (rect.left + rect.width / 2) / window.innerWidth,
                        y: (rect.top + rect.height / 2) / window.innerHeight,
                    },
                    shapes: [reactToConfetti[emoji]]
                })
            }
        } else {
            if (countSpan) {
                countSpan.remove()
            }
        }
    })
}

async function handleReaction(e, confessionId, emoji, button) {
    if (button.disabled) return
    button.disabled = true

    try {
        const response = await fetch(`/api/react/${confessionId}`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ emoji })
        })

        if (!response.ok) {
            const errorText = await response.text()
            console.log('Reaction failed:', errorText)
        }
    } catch (error) {
        console.error('Error handling reaction:', error)
    } finally {
        setTimeout(() => {
            button.disabled = false
        }, 100)
    }
}

confessional.addEventListener('submit', async function(event) {
    event.preventDefault()

    const text = confessionalText.value.trim()

    if (!text) {
        return
    }

    const selectedBackground = document.querySelector('input[name="background"]:checked').value

    try {
        const response = await fetch('/api/confess', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                confession: text,
                public: confessionPublic.checked,
                background: selectedBackground
            })
        })

        if (response.ok) {
            confessionalText.value = ''

            let rect = event.target.getBoundingClientRect()

            confetti({
                particleCount: 50,
                spread: 45,
                origin: {
                    x: (rect.left + rect.width / 2) / window.innerWidth,
                    y: rect.bottom / window.innerHeight,
                },
            })
        }
    } catch (error) {
        console.error('Error:', error)
    }
})

playMusic.addEventListener('click', function () {
    if (player.paused) {
        player.play()
    } else {
        player.pause()
    }

    playMusic.classList.remove("clickMe")
})

player.addEventListener('play', () => {
    playMusic.classList.add("playing")
});

player.addEventListener('pause', () => {
    playMusic.classList.remove("playing")
});