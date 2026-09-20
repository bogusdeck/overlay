package main

import (
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"strconv"
	"strings"
)

type Config struct {
	Leader      string  `json:"leader"`
	Opacity     float64 `json:"opacity"`      // Translucency percentage 0-100 (default 88.0)
	FontFamily  string  `json:"font_family"`  // e.g. "Menlo", "SF Mono", "Monaco", "Courier", "system"
	FontSize    float64 `json:"font_size"`    // e.g. 11.5
	OllamaModel string  `json:"ollama_model"` // e.g. "qwen2.5-coder" or ""
	AgyModel    string  `json:"agy_model"`    // e.g. "gemini-3.1-pro-high"
	AgyEffort   string  `json:"agy_effort"`   // e.g. "high", "medium", "low"
	AgyCmd      string  `json:"agy_cmd"`      // e.g. "agy"
}

func defaultConfig() Config {
	return Config{
		Leader:      "ctrl+cmd+fn",
		Opacity:     88.0,
		FontFamily:  "Menlo",
		FontSize:    11.5,
		OllamaModel: "",
		AgyModel:    "gemini-3.1-pro-high",
		AgyEffort:   "high",
		AgyCmd:      "agy",
	}
}

func getConfigPath() string {
	home, err := os.UserHomeDir()
	if err != nil {
		home = os.Getenv("HOME")
	}
	dir := filepath.Join(home, ".config", "overlay")
	_ = os.MkdirAll(dir, 0755)
	return filepath.Join(dir, "config.json")
}

func loadConfig() Config {
	cfg := defaultConfig()
	data, err := os.ReadFile(getConfigPath())
	if err != nil {
		return cfg
	}
	_ = json.Unmarshal(data, &cfg)

	if strings.TrimSpace(cfg.Leader) == "" {
		cfg.Leader = "ctrl+cmd+fn"
	}
	if cfg.Opacity <= 0 || cfg.Opacity > 100 {
		cfg.Opacity = 88.0
	}
	if strings.TrimSpace(cfg.FontFamily) == "" {
		cfg.FontFamily = "Menlo"
	}
	if cfg.FontSize <= 0 {
		cfg.FontSize = 11.5
	}
	if strings.TrimSpace(cfg.AgyModel) == "" {
		cfg.AgyModel = "gemini-3.1-pro-high"
	}
	if strings.TrimSpace(cfg.AgyEffort) == "" {
		cfg.AgyEffort = "high"
	}
	if strings.TrimSpace(cfg.AgyCmd) == "" {
		cfg.AgyCmd = "agy"
	}
	return cfg
}

func saveConfig(cfg Config) error {
	data, err := json.MarshalIndent(cfg, "", "  ")
	if err != nil {
		return err
	}
	return os.WriteFile(getConfigPath(), data, 0644)
}

func applyFullConfig(cfg Config) {
	cmd, ctrl, fn, alt, shift := parseLeaderKey(cfg.Leader)
	platformSetLeaderModifiers(cmd, ctrl, fn, alt, shift)
	platformSetHUDOpacity(cfg.Opacity)
	platformSetHUDFontConfig(cfg.FontFamily, cfg.FontSize)

	if cfg.OllamaModel != "" {
		ollamaModel = cfg.OllamaModel
	}
	if cfg.AgyModel != "" {
		agyModel = cfg.AgyModel
	}
	if cfg.AgyEffort != "" {
		agyEffort = cfg.AgyEffort
	}
	if cfg.AgyCmd != "" {
		agyPath = cfg.AgyCmd
	}
}

func parseLeaderKey(leaderStr string) (cmd, ctrl, fn, alt, shift bool) {
	parts := strings.Split(strings.ToLower(leaderStr), "+")
	for _, p := range parts {
		p = strings.TrimSpace(p)
		switch p {
		case "cmd", "command":
			cmd = true
		case "ctrl", "control":
			ctrl = true
		case "fn", "function":
			fn = true
		case "alt", "option", "opt":
			alt = true
		case "shift":
			shift = true
		}
	}
	return
}

func handleConfigCommand(args []string) {
	if len(args) == 0 || args[0] == "show" {
		cfg := loadConfig()
		fmt.Printf("Overlay Configuration:\n")
		fmt.Printf("  Leader Key:        %s\n", cfg.Leader)
		fmt.Printf("  Translucency/Opacity: %.0f%%\n", cfg.Opacity)
		fmt.Printf("  Font Family:       %s\n", cfg.FontFamily)
		fmt.Printf("  Font Size:         %.1f pt\n", cfg.FontSize)
		fmt.Printf("  Ollama Model:      %s (auto-detect if empty)\n", cfg.OllamaModel)
		fmt.Printf("  Antigravity Model: %s\n", cfg.AgyModel)
		fmt.Printf("  Antigravity Effort:%s\n", cfg.AgyEffort)
		fmt.Printf("  Antigravity Command:%s\n", cfg.AgyCmd)
		fmt.Printf("  Config File Path:  %s\n", getConfigPath())
		return
	}

	sub := args[0]
	cfg := loadConfig()

	switch sub {
	case "leader":
		if len(args) < 2 {
			fmt.Println("Usage: overlay --config leader \"ctrl+cmd+fn\"")
			os.Exit(1)
		}
		cfg.Leader = strings.TrimSpace(args[1])
		_ = saveConfig(cfg)
		fmt.Printf("✅ Leader key updated to: %s\n", cfg.Leader)

	case "opacity", "translucency":
		if len(args) < 2 {
			fmt.Println("Usage: overlay --config opacity 85")
			os.Exit(1)
		}
		val, err := strconv.ParseFloat(args[1], 64)
		if err != nil || val <= 0 || val > 100 {
			fmt.Println("Error: Opacity must be a percentage between 1 and 100.")
			os.Exit(1)
		}
		cfg.Opacity = val
		_ = saveConfig(cfg)
		fmt.Printf("✅ Translucency opacity updated to: %.0f%%\n", val)

	case "font":
		if len(args) < 2 {
			fmt.Println("Usage: overlay --config font \"SF Mono\"")
			os.Exit(1)
		}
		cfg.FontFamily = strings.TrimSpace(args[1])
		_ = saveConfig(cfg)
		fmt.Printf("✅ Font family updated to: %s\n", cfg.FontFamily)

	case "font-size":
		if len(args) < 2 {
			fmt.Println("Usage: overlay --config font-size 12.0")
			os.Exit(1)
		}
		val, err := strconv.ParseFloat(args[1], 64)
		if err != nil || val < 8 || val > 36 {
			fmt.Println("Error: Font size must be between 8.0 and 36.0 pt.")
			os.Exit(1)
		}
		cfg.FontSize = val
		_ = saveConfig(cfg)
		fmt.Printf("✅ Font size updated to: %.1f pt\n", val)

	case "model-ollama":
		if len(args) < 2 {
			fmt.Println("Usage: overlay --config model-ollama \"qwen2.5-coder\"")
			os.Exit(1)
		}
		cfg.OllamaModel = strings.TrimSpace(args[1])
		_ = saveConfig(cfg)
		fmt.Printf("✅ Ollama model updated to: %s\n", cfg.OllamaModel)

	case "model-agy":
		if len(args) < 2 {
			fmt.Println("Usage: overlay --config model-agy \"gemini-3.1-pro-high\"")
			os.Exit(1)
		}
		cfg.AgyModel = strings.TrimSpace(args[1])
		_ = saveConfig(cfg)
		fmt.Printf("✅ Antigravity model updated to: %s\n", cfg.AgyModel)

	case "agy-effort":
		if len(args) < 2 {
			fmt.Println("Usage: overlay --config agy-effort \"high\"")
			os.Exit(1)
		}
		cfg.AgyEffort = strings.TrimSpace(args[1])
		_ = saveConfig(cfg)
		fmt.Printf("✅ Antigravity effort updated to: %s\n", cfg.AgyEffort)

	case "agy-cmd":
		if len(args) < 2 {
			fmt.Println("Usage: overlay --config agy-cmd \"agy\"")
			os.Exit(1)
		}
		cfg.AgyCmd = strings.TrimSpace(args[1])
		_ = saveConfig(cfg)
		fmt.Printf("✅ Antigravity CLI command updated to: %s\n", cfg.AgyCmd)

	case "reset":
		cfg = defaultConfig()
		_ = saveConfig(cfg)
		fmt.Println("✅ Configuration reset to default settings.")

	default:
		fmt.Printf("Unknown config option: %s\n", sub)
		fmt.Println("Usage: overlay --config [show | leader | opacity | font | font-size | model-ollama | model-agy | agy-effort | agy-cmd | reset]")
		os.Exit(1)
	}

	fmt.Println("Restart the overlay daemon (`overlay --stop && overlay --start`) to apply changes.")
}
