//go:build !cgo

package overlay

import (
	"fmt"
	"log"
	"os"
	"os/exec"
	"os/signal"
	"strings"
	"syscall"
)

func platformRunLoop() {
	fmt.Println("🛸 Overlay daemon running (pure Go mode)... Press Ctrl+C to stop.")
	sigChan := make(chan os.Signal, 1)
	signal.Notify(sigChan, syscall.SIGINT, syscall.SIGTERM)
	<-sigChan
}

func platformSetupHUD() {
	log.Println("[Overlay] HUD initialized.")
}

func platformSetLeaderModifiers(cmd, ctrl, fn, alt, shift bool) {}

func platformSetHUDOpacity(opacity float64) {}

func platformSetHUDFontConfig(font string, size float64) {}

func platformShowHUDText(text string) {
	fmt.Printf("\n=== Overlay HUD Output ===\n%s\n==========================\n\n", text)
}

func platformSetHUDIndexText(text string) {
	if text != "" {
		fmt.Printf("[Overlay Card Index: %s]\n", text)
	}
}

func platformToggleHUDVisibility() {}

func platformMoveHUDWindow(dx, dy int) {}

func platformResizeHUDWindow(dw, dh int) {}

func platformSetHUDCursorStandard() {}

func platformPerformScreenCaptureOCR() {
	tmpImage := "/tmp/overlay_snap.png"
	tmpTxtFile := "/tmp/overlay_ocr.txt"
	_ = os.Remove(tmpImage)
	_ = os.Remove(tmpTxtFile)

	var cmd *exec.Cmd
	if _, err := exec.LookPath("maim"); err == nil {
		cmd = exec.Command("maim", tmpImage)
	} else if _, err := exec.LookPath("scrot"); err == nil {
		cmd = exec.Command("scrot", tmpImage)
	} else if _, err := exec.LookPath("import"); err == nil {
		cmd = exec.Command("import", "-window", "root", tmpImage)
	}

	if cmd == nil || cmd.Run() != nil {
		log.Println("[Overlay] Screen capture failed. Install 'maim', 'scrot', or 'ImageMagick'.")
		return
	}

	if _, err := exec.LookPath("tesseract"); err == nil {
		ocrCmd := exec.Command("tesseract", tmpImage, "/tmp/overlay_ocr")
		if ocrCmd.Run() == nil {
			if data, err := os.ReadFile(tmpTxtFile); err == nil && len(data) > 0 {
				processTranslationWithPrimary(strings.TrimSpace(string(data)), true, "antigravity")
			}
		}
	} else {
		log.Println("[Overlay] OCR skipped. Install 'tesseract' for screen OCR.")
	}
	_ = os.Remove(tmpImage)
	_ = os.Remove(tmpTxtFile)
}

func platformStartGlobalHotkeys() {
	log.Println("[Overlay] Global hotkeys active.")
}
