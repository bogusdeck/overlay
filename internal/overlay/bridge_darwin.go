//go:build darwin && cgo

package overlay

/*
#cgo CFLAGS: -x objective-c -Wno-deprecated-declarations -mmacosx-version-min=13.0
#cgo LDFLAGS: -framework Cocoa -framework QuartzCore -framework Vision -framework CoreGraphics -mmacosx-version-min=13.0

#include "overlay.h"
#include <stdlib.h>
*/
import "C"
import "unsafe"

func platformRunLoop() {
	C.RunAppKitLoop()
}

func platformSetupHUD() {
	C.SetupHUDWindow()
}

func platformSetLeaderModifiers(cmd, ctrl, fn, alt, shift bool) {
	C.SetLeaderModifiers(C.bool(cmd), C.bool(ctrl), C.bool(fn), C.bool(alt), C.bool(shift))
}

func platformSetHUDOpacity(opacity float64) {
	C.SetHUDOpacity(C.float(opacity))
}

func platformSetHUDFontConfig(font string, size float64) {
	cFont := C.CString(font)
	defer C.free(unsafe.Pointer(cFont))
	C.SetHUDFontConfig(cFont, C.float(size))
}

func platformShowHUDText(text string) {
	cText := C.CString(text)
	defer C.free(unsafe.Pointer(cText))
	C.ShowHUDText(cText)
}

func platformSetHUDIndexText(text string) {
	cText := C.CString(text)
	defer C.free(unsafe.Pointer(cText))
	C.SetHUDIndexText(cText)
}

func platformToggleHUDVisibility() {
	C.ToggleHUDVisibility()
}

func platformEnsureHUDVisible() {
	C.EnsureHUDVisible()
}

func platformMoveHUDWindow(dx, dy int) {
	C.MoveHUDWindow(C.int(dx), C.int(dy))
}

func platformResizeHUDWindow(dw, dh int) {
	C.ResizeHUDWindow(C.int(dw), C.int(dh))
}

func platformSetHUDCursorStandard() {
	C.SetHUDCursorStandard()
}

func platformPerformScreenCaptureOCR() {
	C.PerformScreenCaptureOCR()
}

func platformStartGlobalHotkeys() {
	C.StartGlobalHotkeys()
}
