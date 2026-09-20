package main

import (
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strconv"
	"strings"
	"syscall"
)

const pidFile = "/tmp/overlay.pid"

func getRunningPID() int {
	data, err := os.ReadFile(pidFile)
	if err != nil {
		return 0
	}
	pid, err := strconv.Atoi(strings.TrimSpace(string(data)))
	if err != nil {
		return 0
	}
	proc, err := os.FindProcess(pid)
	if err != nil {
		return 0
	}
	if err := proc.Signal(syscall.Signal(0)); err != nil {
		return 0
	}
	return pid
}

func startBackground() {
	if pid := getRunningPID(); pid != 0 {
		fmt.Printf("🛸 Overlay is already running in background (PID %d).\n", pid)
		return
	}

	exe, err := os.Executable()
	if err != nil {
		fmt.Printf("Error getting executable path: %v\n", err)
		return
	}

	logDir := filepath.Join(os.Getenv("HOME"), ".overlay")
	_ = os.MkdirAll(logDir, 0755)
	logPath := filepath.Join(logDir, "overlay.log")

	logFile, err := os.OpenFile(logPath, os.O_APPEND|os.O_CREATE|os.O_WRONLY, 0644)
	if err != nil {
		fmt.Printf("Error opening log file: %v\n", err)
		return
	}

	cmd := exec.Command(exe, "--daemon")
	cmd.Stdout = logFile
	cmd.Stderr = logFile
	cmd.SysProcAttr = &syscall.SysProcAttr{Setsid: true}

	if err := cmd.Start(); err != nil {
		fmt.Printf("Error starting background process: %v\n", err)
		return
	}

	_ = os.WriteFile(pidFile, []byte(strconv.Itoa(cmd.Process.Pid)), 0644)
	fmt.Printf("🛸 Overlay started in background (PID %d)!\n", cmd.Process.Pid)
	fmt.Printf("   Log file: %s\n", logPath)
	fmt.Println("   Use 'overlay --stop' or 'brew services stop overlay' to stop.")
}

func stopBackground() {
	stopped := false

	// If managed by Homebrew / launchd / systemd services, stop the service first to prevent auto-restart
	_ = exec.Command("brew", "services", "stop", "overlay").Run()
	_ = exec.Command("systemctl", "--user", "stop", "overlay").Run()

	if pid := getRunningPID(); pid != 0 {
		if proc, err := os.FindProcess(pid); err == nil {
			_ = proc.Signal(syscall.SIGTERM)
			fmt.Printf("🛑 Overlay (PID %d) stopped.\n", pid)
			stopped = true
		}
	}

	// Terminate any remaining overlay instances
	out, err := exec.Command("pgrep", "-f", "overlay").Output()
	if err == nil {
		myPID := os.Getpid()
		for _, line := range strings.Split(string(out), "\n") {
			line = strings.TrimSpace(line)
			if line != "" {
				if pid, err := strconv.Atoi(line); err == nil && pid != myPID {
					if proc, err := os.FindProcess(pid); err == nil {
						_ = proc.Signal(syscall.SIGTERM)
						stopped = true
					}
				}
			}
		}
	}

	_ = os.Remove(pidFile)

	if !stopped {
		fmt.Println("ℹ️  Overlay is not running.")
	}
}

func showStatus() {
	if pid := getRunningPID(); pid != 0 {
		fmt.Printf("🛸 Overlay is ACTIVE (PID %d).\n", pid)
	} else {
		fmt.Println("ℹ️  Overlay is INACTIVE.")
	}
}
