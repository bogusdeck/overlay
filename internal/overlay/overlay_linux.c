#include "overlay.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <signal.h>

static float gHUDOpacity = 0.88f;
static float gHUDFontSize = 11.5f;
static char gHUDFontName[64] = "Menlo";
static bool gHUDVisible = true;

void SetupHUDWindow(void) {
    printf("[Overlay Linux] Initialized HUD Window (Translucency: %.0f%%, Font: %s %.1fpt)\n",
           gHUDOpacity * 100.0f, gHUDFontName, gHUDFontSize);
}

void SetLeaderModifiers(bool cmd, bool ctrl, bool fn, bool alt, bool shift) {
    // Modifier config stored for hotkey checking
}

bool CheckLeaderModifiers(CGEventFlags flags) {
    return true;
}

void SetHUDOpacity(float opacityPercentage) {
    gHUDOpacity = opacityPercentage / 100.0f;
}

void SetHUDFontConfig(const char* fontName, float fontSize) {
    if (fontName && strlen(fontName) > 0) {
        strncpy(gHUDFontName, fontName, sizeof(gHUDFontName) - 1);
        gHUDFontName[sizeof(gHUDFontName) - 1] = '\0';
    }
    if (fontSize >= 8.0f && fontSize <= 36.0f) {
        gHUDFontSize = fontSize;
    }
}

void ShowHUDText(const char* text) {
    if (!text) return;
    printf("\n=== Overlay HUD Output ===\n%s\n==========================\n\n", text);
    fflush(stdout);
}

void SetHUDIndexText(const char* text) {
    if (text) {
        printf("[Overlay Card Index: %s]\n", text);
        fflush(stdout);
    }
}

void ToggleHUDVisibility(void) {
    gHUDVisible = !gHUDVisible;
    printf("[Overlay Linux] HUD Visibility toggled: %s\n", gHUDVisible ? "VISIBLE" : "HIDDEN");
    fflush(stdout);
}

void MoveHUDWindow(int dx, int dy) {
    printf("[Overlay Linux] Moved HUD window (dx: %d, dy: %d)\n", dx, dy);
    fflush(stdout);
}

void ResizeHUDWindow(int dw, int dh) {
    printf("[Overlay Linux] Resized HUD window (dw: %d, dh: %d)\n", dw, dh);
    fflush(stdout);
}

void SetHUDCursorStandard(void) {
    // Standard cursor on Linux
}

void PerformScreenCaptureOCR(void) {
    const char *tmpImage = "/tmp/overlay_snap.png";
    const char *tmpTxtBase = "/tmp/overlay_ocr";
    const char *tmpTxtFile = "/tmp/overlay_ocr.txt";

    // Attempt screenshot capture using maim, scrot, or import (ImageMagick)
    int ret = system("maim /tmp/overlay_snap.png 2>/dev/null || scrot /tmp/overlay_snap.png 2>/dev/null || import -window root /tmp/overlay_snap.png 2>/dev/null");
    if (ret != 0) {
        fprintf(stderr, "[Overlay Linux] Screen capture failed. Ensure 'maim', 'scrot', or 'ImageMagick (import)' is installed.\n");
        return;
    }

    // Run tesseract OCR if available
    char cmd[256];
    snprintf(cmd, sizeof(cmd), "tesseract %s %s >/dev/null 2>&1", tmpImage, tmpTxtBase);
    ret = system(cmd);

    if (ret == 0) {
        FILE *f = fopen(tmpTxtFile, "r");
        if (f) {
            fseek(f, 0, SEEK_END);
            long sz = ftell(f);
            fseek(f, 0, SEEK_SET);

            if (sz > 0) {
                char *buf = (char *)malloc(sz + 1);
                if (buf) {
                    size_t readBytes = fread(buf, 1, sz, f);
                    buf[readBytes] = '\0';
                    goOnSubmitScreenCapture(buf);
                    free(buf);
                }
            }
            fclose(f);
            unlink(tmpTxtFile);
        }
    } else {
        fprintf(stderr, "[Overlay Linux] OCR failed. Ensure 'tesseract' is installed for screen OCR capture.\n");
    }
    unlink(tmpImage);
}

void RunAppKitLoop(void) {
    printf("[Overlay Linux] Running Overlay daemon loop...\n");
    fflush(stdout);

    // POSIX signal pause loop for Linux daemon background mode
    sigset_t mask;
    sigemptyset(&mask);
    while (1) {
        sigsuspend(&mask);
    }
}
