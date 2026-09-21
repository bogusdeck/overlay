package overlay

import (
	"fmt"
	"os"
	"sync"
	"time"

	"github.com/atotto/clipboard"
)

func Run() {
	_ = os.WriteFile(pidFile, []byte(fmt.Sprintf("%d", os.Getpid())), 0644)

	cfg := loadConfig()
	applyFullConfig(cfg)

	fmt.Printf("Starting Overlay HUD (Leader: %s, Font: %s %.1fpt, Opacity: %.0f%%)...\n", cfg.Leader, cfg.FontFamily, cfg.FontSize, cfg.Opacity)
	startHotkeyListener()

	platformRunLoop()
}

type HistoryCard struct {
	Prompt string
	Result string
}

var (
	historyLock         sync.Mutex
	historyCards        []HistoryCard
	currentHistoryIndex = -1
	currentActivePrompt string

	isRequestLoading   bool
	userViewingHistory bool
	currentActiveModel string
	currentActiveStart time.Time
)

func handleNextCard() {
	historyLock.Lock()
	defer historyLock.Unlock()

	if len(historyCards) == 0 {
		if isRequestLoading && userViewingHistory {
			userViewingHistory = false
			updateHUDDisplayLocked()
		}
		return
	}

	if currentHistoryIndex < len(historyCards)-1 {
		currentHistoryIndex++
		userViewingHistory = true
		updateHUDDisplayLocked()
	} else if isRequestLoading && userViewingHistory {
		userViewingHistory = false
		updateHUDDisplayLocked()
	}
}

func handlePrevCard() {
	historyLock.Lock()
	defer historyLock.Unlock()

	if len(historyCards) == 0 {
		return
	}

	userViewingHistory = true

	if currentHistoryIndex > 0 {
		currentHistoryIndex--
	}
	updateHUDDisplayLocked()
}

func handleInstantAgy() {
	historyLock.Lock()
	prompt := currentActivePrompt
	if prompt == "" && currentHistoryIndex >= 0 && currentHistoryIndex < len(historyCards) {
		prompt = historyCards[currentHistoryIndex].Prompt
	}
	historyLock.Unlock()

	if prompt == "" {
		platformShowHUDText("ℹ️ No active or history request to accelerate with Antigravity.")
		return
	}

	go processTranslationWithPrimary(prompt, true, "antigravity")
}

func updateHUDDisplay() {
	historyLock.Lock()
	defer historyLock.Unlock()
	updateHUDDisplayLocked()
}

func updateHUDDisplayLocked() {
	if isRequestLoading && !userViewingHistory {
		secs := int(time.Since(currentActiveStart).Seconds())
		loadingText := fmt.Sprintf("%s (%ds)...", currentActiveModel, secs)
		total := len(historyCards) + 1
		idxText := fmt.Sprintf("[%d/%d ⏳]", total, total)

		platformShowHUDText(loadingText)
		platformSetHUDIndexText(idxText)
		return
	}

	if currentHistoryIndex >= 0 && currentHistoryIndex < len(historyCards) {
		card := historyCards[currentHistoryIndex]
		total := len(historyCards)
		if isRequestLoading {
			total++
		}
		idxText := fmt.Sprintf("[%d/%d]", currentHistoryIndex+1, total)

		platformShowHUDText(card.Result)
		platformSetHUDIndexText(idxText)
	}
}

func processTranslation(text string, isRawPrompt bool) {
	processTranslationWithPrimary(text, isRawPrompt, preferredProvider)
}

func processTranslationWithPrimary(text string, isRawPrompt bool, primaryProvider string) {
	modelName := getModelNameForProvider(primaryProvider)

	historyLock.Lock()
	isRequestLoading = true
	userViewingHistory = false
	currentActivePrompt = text
	currentActiveModel = modelName
	currentActiveStart = time.Now()
	updateHUDDisplayLocked()
	historyLock.Unlock()

	stopTimer := make(chan struct{})

	go func() {
		ticker := time.NewTicker(1 * time.Second)
		defer ticker.Stop()

		for {
			select {
			case <-stopTimer:
				return
			case <-ticker.C:
				historyLock.Lock()
				if isRequestLoading && !userViewingHistory {
					updateHUDDisplayLocked()
				}
				historyLock.Unlock()
			}
		}
	}()

	result := translateTextWithPrimary(text, isRawPrompt, primaryProvider)
	close(stopTimer)

	historyLock.Lock()
	isRequestLoading = false
	historyCards = append(historyCards, HistoryCard{Prompt: text, Result: result})
	if !userViewingHistory {
		currentHistoryIndex = len(historyCards) - 1
	}
	currentActivePrompt = ""
	updateHUDDisplayLocked()
	historyLock.Unlock()
}

func onTranslateClipboard() {
	text, err := clipboard.ReadAll()
	if err != nil || text == "" {
		platformShowHUDText("⚠️ Clipboard is empty or unreadable.")
		return
	}
	go processTranslationWithPrimary(text, false, preferredProvider)
}
