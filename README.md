<div align="center">
  <img src="assets/pixel_eye.png" alt="Overlay Logo" width="220" />
</div>

# Overlay — macOS AI Assistant & Code HUD

Overlay is a lightweight, floating translucent HUD application for macOS written in Go + CGo (AppKit). It provides instant screen OCR capture, clipboard problem solving, rich Markdown syntax highlighting, and dual AI backend routing powered by Ollama and Antigravity (`agy`).

> [!NOTE]
> 🤫 **Where's the demo GIF preview?**  
> *Oops! We tried to record a demo video, but Overlay is so stealthy (`NSWindowSharingNone`) that screen recorders literally capture right through it! You'll just have to run it locally to see the magic.* 🪄

---

## Key Features

- **Automatic Full-Screen Capture & Vision OCR**:
  - Press `Cmd` + `Ctrl` + `Fn` + `S` (or click `📸`) to silently capture the full main screen.
  - Text is extracted instantly using Apple's native Vision framework (`VNRecognizeTextRequest`).
- **Screen-Share Invisibility**:
  - Window sharing type set to `NSWindowSharingNone` with no window shadow (`hasShadow: NO`) to remain invisible on screen shares and recordings.
- **Rich Markdown Syntax Highlighting**:
  - Native syntax highlighting for code blocks (Python, Go, JS/TS, C++, Java, etc.), bold text, headers, bullet points, and inline code capsules.
- **Live Model Timer & Clean Output**:
  - Real-time execution timer displaying active model and elapsed time (e.g. `gemini-3.1-pro-high (3s)...`).
  - Strict negative prompt directives and preamble filters to eliminate conversational filler (e.g. no *"Sure! Let's break down..."*).
- **Dual AI Provider Routing**:
  - **Screen Captures**: Antigravity (`agy`) primary $\rightarrow$ Ollama fallback.
  - **Text / Clipboard Prompts**: Ollama primary $\rightarrow$ Antigravity (`agy`) fallback.
  - **Instant Acceleration**: `Cmd` + `Ctrl` + `Fn` + `I` forces direct Antigravity execution.
- **Configurable Leader Keys & Styling (`overlay --config`)**:
  - Customize leader key combinations, translucency percentage, font style/size, and model defaults saved to `~/.config/overlay/config.json`.

---

## Installation

### Homebrew (Recommended)

```bash
brew tap bogusdeck/meowmeow https://github.com/bogusdeck/meowmeow.git
brew install overlay
```

#### Run as Background Service
```bash
brew services start overlay
```

#### CLI Daemon Commands
```bash
overlay --start
overlay --stop
overlay --status
```

### Manual Build

#### Prerequisites
- macOS 12+ (Apple Silicon or Intel)
- Go 1.20+
- Ollama and/or Antigravity CLI (`agy`)

#### Build Steps
```bash
git clone https://github.com/bogusdeck/meowmeow.git
cd meowmeow
go build -o overlay .
./overlay --start
```

---

## Configuration (`overlay --config`)

Overlay includes a built-in terminal configuration utility:

```bash
# View active configuration
overlay --config show

# Set custom leader key (default: ctrl+cmd+fn)
overlay --config leader "ctrl+cmd+fn"

# Set window translucency / opacity percentage (1-100%)
overlay --config opacity 85

# Set font family ("Menlo", "SF Mono", "Monaco", "Courier", "system")
overlay --config font "SF Mono"

# Set font size in points
overlay --config font-size 12.0

# Set specific Ollama model
overlay --config model-ollama "qwen2.5-coder"

# Set Antigravity model & effort
overlay --config model-agy "gemini-3.1-pro-high"
overlay --config agy-effort "high"

# Reset all settings to default
overlay --config reset
```

---

## Hotkeys Quick Reference (Default Leader: `Cmd + Ctrl + Fn`)

| Action | Shortcut | Top Bar Icon |
|---|---|---|
| **Full Screen Capture & OCR** | `Leader` + `S` | `📸` Camera |
| **Translate Clipboard** | `Leader` + `P` | `doc.on.clipboard` Paste |
| **Toggle Hide / Show Overlay** | `Leader` + `H` | - |
| **Kill / Stop Overlay Process** | `Leader` + `X` | `xmark.circle.fill` Close |
| **Accelerate with Antigravity**| `Leader` + `I` | - |
| **Next Response Card** | `Leader` + `.` (`>`) | `[1/1]` Counter |
| **Previous Response Card** | `Leader` + `,` (`<`) | `[1/1]` Counter |
| **Move Window Position** | `Leader` + `Arrows` | - |
| **Reduce Window Size** | `Leader` + `-` / `M` | - |
| **Expand Window Size** | `Leader` + `=` / `+` | - |