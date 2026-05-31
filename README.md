<div align="center">
  <img src="assets/images/logo.png" alt="SiegeConnect Logo" width="150" />
</div>

<h1 align="center">SiegeConnect</h1>

<p align="center">
  <strong>A modern, cross-platform VPN client powered by Flutter and Mihomo (Clash.Meta)</strong>
</p>

## Overview

SiegeConnect is a sleek, battery-efficient VPN client designed for maximum stability and speed. Built with Flutter for a beautiful, responsive UI and powered by a robust Go core (Mihomo), it seamlessly hides complex networking logic behind an intuitive user interface.

SiegeConnect acts as a dedicated client for the Remnawave backend panel, supporting a variety of modern protocols including AmneziaWG, Hysteria 2, VLESS, VMESS, and Trojan.

## Key Features

- 🌍 **Modern Protocols**: Full support for AmneziaWG, Hysteria 2, VLESS, VMESS, and Trojan out-of-the-box.
- 🎨 **Beautiful UI**: Modern Material 3 expressive design with a fully adaptive layout, smooth animations, and dark/light mode support.
- ⚡ **High Performance**: Built with a lightweight Flutter frontend and a blazing fast Go core (compiled natively via `gomobile`).
- 🛡️ **Smart Routing**: Built-in geo-routing and split tunneling. Automatically bypasses VPN for specific regional traffic.
- 🔋 **Battery Efficient**: Minimal background resource usage and optimized state management using Riverpod.
- 📱 **Cross-Platform**: Supports Android, iOS, Windows, macOS, and Linux from a single codebase.

## Architecture

SiegeConnect separates concerns effectively:
1. **Frontend (Dart/Flutter)**: Handles UI, state management (Riverpod), caching (Isar DB), and API communication with the Remnawave backend panel.
2. **Core (Go/Mihomo)**: Runs as a background service parsing YAML configurations and establishing secure tunnels.
3. **Native Bridges**: Uses Flutter MethodChannels (Kotlin/Swift/C++) to interact natively with OS-level VPN APIs (like Android `VpnService`).

## Building from Source

### Prerequisites
- Flutter SDK (latest stable)
- Go (1.21+)
- `gomobile` (for building mobile Go binaries)

### Installation
1. Clone the repository:
```bash
git clone https://github.com/fayzetwin1/siegeconnect.git
cd siegeconnect
```

2. Get Flutter dependencies:
```bash
flutter pub get
```

3. Build and run:
```bash
flutter run -d windows # For Windows
# or
flutter run -d android # For Android
```


