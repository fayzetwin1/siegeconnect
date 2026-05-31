package core

import (
	"fmt"
	"os"
	"path/filepath"

	"github.com/metacubex/mihomo/config"
	"github.com/metacubex/mihomo/constant"
	"github.com/metacubex/mihomo/hub/executor"
)

var isRunning bool = false

func StartVpn(homeDir string, configName string) error {
	if isRunning {
		return fmt.Errorf("VPN is already running")
	}

	constant.SetHomeDir(homeDir)
	
	configPath := filepath.Join(homeDir, configName)
	b, err := os.ReadFile(configPath)
	if err != nil {
		return fmt.Errorf("failed to read config: %v", err)
	}

	cfg, err := config.Parse(b)
	if err != nil {
		return fmt.Errorf("failed to parse config: %v", err)
	}

	// Apply the configuration
	executor.ApplyConfig(cfg, true)

	isRunning = true
	return nil
}

func StopVpn() error {
	if !isRunning {
		return nil
	}
	// Shutdown logic for Mihomo goes here
	isRunning = false
	return nil
}
