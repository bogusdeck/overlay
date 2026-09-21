package main

import (
	"fmt"
	"os"

	"github.com/bogusdeck/overlay/internal/overlay"
)

func main() {
	if len(os.Args) > 1 {
		switch os.Args[1] {
		case "--start":
			overlay.StartBackground()
			return
		case "--stop":
			overlay.StopBackground()
			return
		case "--status":
			overlay.ShowStatus()
			return
		case "--config":
			overlay.HandleConfigCommand(os.Args[2:])
			return
		case "-h", "--help":
			fmt.Println("Usage: overlay [--start | --stop | --status | --config leader \"ctrl+cmd+fn\"]")
			return
		}
	}

	overlay.Run()
}
