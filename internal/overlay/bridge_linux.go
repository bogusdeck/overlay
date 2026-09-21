//go:build linux && cgo

package overlay

/*
#cgo CFLAGS: -std=gnu99
#cgo LDFLAGS: -lrt -lpthread

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
