#ifndef OVERLAY_H
#define OVERLAY_H

#ifdef __APPLE__
#import <Cocoa/Cocoa.h>
#else
#include <stdbool.h>
#include <stdint.h>
typedef uint64_t CGEventFlags;
#endif

#ifdef __cplusplus
extern "C" {
#endif

void SetupHUDWindow(void);
void SetLeaderModifiers(bool cmd, bool ctrl, bool fn, bool alt, bool shift);
bool CheckLeaderModifiers(CGEventFlags flags);
void SetHUDOpacity(float opacityPercentage);
void SetHUDFontConfig(const char* fontName, float fontSize);
void ShowHUDText(const char* text);
void SetHUDIndexText(const char* text);
void ToggleHUDVisibility(void);
void EnsureHUDVisible(void);
void MoveHUDWindow(int dx, int dy);
void ResizeHUDWindow(int dw, int dh);
void SetHUDCursorStandard(void);
void RunAppKitLoop(void);
void PerformScreenCaptureOCR(void);
void StartGlobalHotkeys(void);

void goHotkeyTranslate(void);
void goHotkeySnapOCR(void);
void goHotkeyToggleOverlay(void);
void goHotkeyKillApp(void);
void goHotkeyInstantAgy(void);
void goHotkeyNextCard(void);
void goHotkeyPrevCard(void);
void goHotkeyMoveLeft(void);
void goHotkeyMoveRight(void);
void goHotkeyMoveUp(void);
void goHotkeyMoveDown(void);
void goHotkeyReduceSize(void);
void goHotkeyExpandSize(void);

#ifdef __cplusplus
}
#endif

#endif
