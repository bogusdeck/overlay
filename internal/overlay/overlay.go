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
)

func handleNextCard() {
	historyLock.Lock()
	defer historyLock.Unlock()

	if len(historyCards) == 0 {
		return
	}
	if currentHistoryIndex < len(historyCards)-1 {
		currentHistoryIndex++
		updateHUDDisplay()
	}
}

func handlePrevCard() {
	historyLock.Lock()
	defer historyLock.Unlock()

	if len(historyCards) == 0 {
		return
	}
	if currentHistoryIndex > 0 {
		currentHistoryIndex--
		updateHUDDisplay()
	}
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

	modelName := getModelNameForProvider("antigravity")
	stopTimer := make(chan struct{})

	go func() {
		start := time.Now()
		updateTimer := func() {
			secs := int(time.Since(start).Seconds())
			loadingText := fmt.Sprintf("%s (%ds)...", modelName, secs)
			platformShowHUDText(loadingText)
		}
		updateTimer()

		ticker := time.NewTicker(1 * time.Second)
		defer ticker.Stop()

		for {
			select {
			case <-stopTimer:
				return
			case <-ticker.C:
				updateTimer()
			}
		}
	}()

	go func(p string) {
		res := askAntigravity(p)
		close(stopTimer)

		historyLock.Lock()
		historyCards = append(historyCards, HistoryCard{Prompt: p, Result: res})
		currentHistoryIndex = len(historyCards) - 1
		historyLock.Unlock()
		updateHUDDisplay()
	}(prompt)
}

func updateHUDDisplay() {
	if currentHistoryIndex >= 0 && currentHistoryIndex < len(historyCards) {
		card := historyCards[currentHistoryIndex]
		idxText := fmt.Sprintf("[%d/%d]", currentHistoryIndex+1, len(historyCards))

		platformShowHUDText(card.Result)
		platformSetHUDIndexText(idxText)
	}
}

func processTranslation(text string, isRawPrompt bool) {
	processTranslationWithPrimary(text, isRawPrompt, preferredProvider)
}

func processTranslationWithPrimary(text string, isRawPrompt bool, primaryProvider string) {
	historyLock.Lock()
	currentActivePrompt = text
	historyLock.Unlock()

	modelName := getModelNameForProvider(primaryProvider)
	stopTimer := make(chan struct{})

	go func() {
		start := time.Now()
		updateTimer := func() {
			secs := int(time.Since(start).Seconds())
			loadingText := fmt.Sprintf("%s (%ds)...", modelName, secs)
			platformShowHUDText(loadingText)
		}
		updateTimer()

		ticker := time.NewTicker(1 * time.Second)
		defer ticker.Stop()

		for {
			select {
			case <-stopTimer:
				return
			case <-ticker.C:
				updateTimer()
			}
		}
	}()

	result := translateTextWithPrimary(text, isRawPrompt, primaryProvider)
	close(stopTimer)

	historyLock.Lock()
	historyCards = append(historyCards, HistoryCard{Prompt: text, Result: result})
	currentHistoryIndex = len(historyCards) - 1
	currentActivePrompt = ""
	historyLock.Unlock()

	updateHUDDisplay()
}

func onTranslateClipboard() {
	text, err := clipboard.ReadAll()
	if err != nil || text == "" {
		platformShowHUDText("⚠️ Clipboard is empty or unreadable.")
		return
	}
	go processTranslationWithPrimary(text, false, preferredProvider)
}
