//go:build cgo

package overlay

/*
#include "overlay.h"
*/
import "C"
import "log"

//export goOnSubmitPrompt
func goOnSubmitPrompt(cText *C.char) {
	text := C.GoString(cText)
	if text == "" {
		return
	}
	log.Printf("User submitted prompt from HUD: %s", text)
	go processTranslationWithPrimary(text, true, "ollama")
}

//export goOnSubmitScreenCapture
func goOnSubmitScreenCapture(cText *C.char) {
	text := C.GoString(cText)
	if text == "" {
		return
	}
	log.Printf("User submitted screen capture OCR prompt: %s", text)
	go processTranslationWithPrimary(text, true, "antigravity")
}

//export goOnNextCard
func goOnNextCard() {
	handleNextCard()
}

//export goOnPrevCard
func goOnPrevCard() {
	handlePrevCard()
}

//export goOnInstantAgy
func goOnInstantAgy() {
	handleInstantAgy()
}

//export goHotkeyTranslate
func goHotkeyTranslate() {
	onTranslateClipboard()
}

//export goHotkeySnapOCR
func goHotkeySnapOCR() {
	platformPerformScreenCaptureOCR()
}

//export goHotkeyToggleOverlay
func goHotkeyToggleOverlay() {
	platformToggleHUDVisibility()
}

//export goHotkeyKillApp
func goHotkeyKillApp() {
	StopBackground()
}

//export goHotkeyInstantAgy
func goHotkeyInstantAgy() {
	handleInstantAgy()
}

//export goHotkeyNextCard
func goHotkeyNextCard() {
	handleNextCard()
}

//export goHotkeyPrevCard
func goHotkeyPrevCard() {
	handlePrevCard()
}

//export goHotkeyMoveLeft
func goHotkeyMoveLeft() {
	platformMoveHUDWindow(-40, 0)
}

//export goHotkeyMoveRight
func goHotkeyMoveRight() {
	platformMoveHUDWindow(40, 0)
}

//export goHotkeyMoveUp
func goHotkeyMoveUp() {
	platformMoveHUDWindow(0, 40)
}

//export goHotkeyMoveDown
func goHotkeyMoveDown() {
	platformMoveHUDWindow(0, -40)
}

//export goHotkeyReduceSize
func goHotkeyReduceSize() {
	platformResizeHUDWindow(-40, -30)
}

//export goHotkeyExpandSize
func goHotkeyExpandSize() {
	platformResizeHUDWindow(40, 30)
}
