package overlay

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net/http"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"time"
)

var (
	preferredProvider = getEnvOrDefault("OVERLAY_PROVIDER", "ollama")
	ollamaURL         = getEnvOrDefault("OLLAMA_URL", "http://localhost:11434/api/generate")
	ollamaTagsURL     = getEnvOrDefault("OLLAMA_TAGS_URL", "http://localhost:11434/api/tags")
	ollamaModel       = getEnvOrDefault("OLLAMA_MODEL", "ollama")
	ollamaAPIKey      = os.Getenv("OLLAMA_API_KEY")

	agyModel  = getEnvOrDefault("AGY_MODEL", "gemini-3.1-pro-high")
	agyEffort = getEnvOrDefault("AGY_EFFORT", "high")
	agyPath   = resolveAgyPath()
)

const translateTextPrompt = `STRICT DIRECTIVE: Do NOT include any conversational intro, greetings, preamble, or filler text (such as "Sure!", "Here is", "Let's break down", "Certainly", etc.). Start IMMEDIATELY with the solution or code.

Provide:
1. A simple, clean, and easy-to-understand solution (use basic, optimal code).
2. A short, clear technical explanation (approach, time/space complexity).

Problem:
%s`

func stripConversationalPreamble(text string) string {
	lines := strings.Split(text, "\n")
	startIdx := 0
	for i, line := range lines {
		trimmed := strings.TrimSpace(line)
		if trimmed == "" {
			continue
		}
		lower := strings.ToLower(trimmed)
		if strings.HasPrefix(lower, "sure") ||
			strings.HasPrefix(lower, "certainly") ||
			strings.HasPrefix(lower, "here is") ||
			strings.HasPrefix(lower, "here's") ||
			strings.HasPrefix(lower, "let's") ||
			strings.HasPrefix(lower, "below is") ||
			strings.HasPrefix(lower, "i can help") ||
			strings.HasPrefix(lower, "of course") ||
			strings.HasPrefix(lower, "great!") ||
			strings.HasPrefix(lower, "ok,") ||
			strings.HasPrefix(lower, "okay,") {
			continue
		}
		startIdx = i
		break
	}
	if startIdx < len(lines) {
		return strings.TrimSpace(strings.Join(lines[startIdx:], "\n"))
	}
	return strings.TrimSpace(text)
}

func getEnvOrDefault(key, fallback string) string {
	if val := os.Getenv(key); val != "" {
		return val
	}
	return fallback
}

func resolveAgyPath() string {
	if p, err := exec.LookPath("agy"); err == nil {
		return p
	}
	homeAgy := filepath.Join(os.Getenv("HOME"), ".local", "bin", "agy")
	if _, err := os.Stat(homeAgy); err == nil {
		return homeAgy
	}
	return "agy"
}

type OllamaTagsResponse struct {
	Models []struct {
		Name string `json: "name"`
	} `json:"models"`
}

type OllamaGenerateRequest struct {
	Model  string `json:"model"`
	Prompt string `json:"prompt"`
	Stream bool   `json:"stream"`
}

type OllamaGenerateResponse struct {
	Response string `json:"response"`
}

func getAvailableOllamaModel() string {
	client := http.Client{Timeout: 5 * time.Second}
	resp, err := client.Get(ollamaTagsURL)
	if err == nil && resp.StatusCode == 200 {
		defer resp.Body.Close()
		var tags OllamaTagsResponse
		if err := json.NewDecoder(resp.Body).Decode(&tags); err == nil {
			var names []string
			for _, m := range tags.Models {
				if m.Name != "" {
					names = append(names, m.Name)
					if m.Name == ollamaModel || m.Name == ollamaModel+":latest" {
						return ollamaModel
					}
				}
			}
			for _, name := range names {
				if !strings.Contains(strings.ToLower(name), "embed") {
					log.Printf("Model '%s' not found on Ollama. Using available model '%s'", ollamaModel, name)
					return name
				}
			}
			if len(names) > 0 {
				return names[0]
			}
		}
	}
	return ollamaModel
}

func translateWithOllama(prompt string) (string, error) {
	modelName := getAvailableOllamaModel()
	log.Printf("Starting translation request to %s with model '%s'", ollamaURL, modelName)

	reqBody, err := json.Marshal(OllamaGenerateRequest{
		Model:  modelName,
		Prompt: prompt,
		Stream: false,
	})
	if err != nil {
		return "", err
	}

	req, err := http.NewRequest("POST", ollamaURL, bytes.NewBuffer(reqBody))
	if err != nil {
		return "", err
	}
	req.Header.Set("Content-Type", "application/json")
	if ollamaAPIKey != "" {
		req.Header.Set("Authorization", "Bearer "+ollamaAPIKey)
	}

	client := http.Client{Timeout: 30 * time.Second}
	resp, err := client.Do(req)
	if err != nil {
		return "", err
	}
	defer resp.Body.Close()

	if resp.StatusCode != 200 {
		body, _ := io.ReadAll(resp.Body)
		return "", fmt.Errorf("Ollama returned HTTP %d: %s", resp.StatusCode, string(body))
	}

	var genResp OllamaGenerateResponse
	if err := json.NewDecoder(resp.Body).Decode(&genResp); err != nil {
		return "", err
	}

	result := strings.TrimSpace(genResp.Response)
	if result == "" {
		return "", fmt.Errorf("Ollama returned an empty response")
	}
	return result, nil
}

func translateWithAntigravity(prompt string) (string, error) {
	args := []string{"--dangerously-skip-permissions"}
	if agyModel != "" {
		args = append(args, "--model", agyModel)
	}
	if agyEffort != "" && !strings.Contains(strings.ToLower(agyModel), "flash") {
		args = append(args, "--effort", agyEffort)
	}
	args = append(args, "-p", prompt)

	cmd := exec.Command(agyPath, args...)
	var stdout, stderr bytes.Buffer
	cmd.Stdout = &stdout
	cmd.Stderr = &stderr

	log.Printf("Executing prompt via Antigravity CLI (%s)...", agyPath)
	err := cmd.Run()
	if err == nil && strings.TrimSpace(stdout.String()) != "" {
		return strings.TrimSpace(stdout.String()), nil
	}

	errMsg := strings.TrimSpace(stderr.String())
	if errMsg == "" && err != nil {
		errMsg = err.Error()
	}
	return "", fmt.Errorf("Antigravity error: %s", errMsg)
}

func translateText(text string, isRawPrompt bool) string {
	return translateTextWithPrimary(text, isRawPrompt, preferredProvider)
}

func translateTextWithPrimary(text string, isRawPrompt bool, primaryProvider string) string {
	prompt := text
	if !isRawPrompt {
		prompt = fmt.Sprintf(translateTextPrompt, text)
	}

	type provider struct {
		name string
		fn   func(string) (string, error)
	}

	var providers []provider
	if primaryProvider == "antigravity" {
		providers = []provider{
			{"Antigravity", translateWithAntigravity},
			{"Ollama", translateWithOllama},
		}
	} else {
		providers = []provider{
			{"Ollama", translateWithOllama},
			{"Antigravity", translateWithAntigravity},
		}
	}

	var lastErr error
	for _, p := range providers {
		log.Printf("Attempting solution via provider: %s", p.name)
		res, err := p.fn(prompt)
		if err == nil && res != "" {
			return stripConversationalPreamble(res)
		}
		log.Printf("Provider %s failed: %v", p.name, err)
		lastErr = err
	}

	return fmt.Sprintf("Error generating response: %v", lastErr)
}

func askAntigravity(question string) string {
	result, err := translateWithAntigravity(question)
	if err != nil {
		return fmt.Sprintf("Antigravity error: %v", err)
	}
	return stripConversationalPreamble(result)
}

func getModelNameForProvider(provider string) string {
	if provider == "antigravity" {
		if agyModel != "" {
			return agyModel
		}
		return "gemini-3.1-pro-high"
	}
	return getAvailableOllamaModel()
}
