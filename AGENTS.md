# Project Overview
This repository contains the source code for a proprietary, cross-platform VPN client (Android, iOS, Windows, macOS, Linux). The application acts as a client for the Remnawave backend panel. It is designed to be fast, stable, and battery-efficient, hiding complex networking logic behind a clean, modern, and minimalist user interface.

# Core Technologies
- **Frontend / UI:** Flutter (Dart)
- **State Management:** Riverpod
- **Local Database:** Isar (for caching configs, saving user preferences, and split-tunneling app lists)
- **Networking:** Dio (for REST API communication with the Remnawave backend)
- **VPN Engine:** Mihomo (Clash.Meta) - Written in Go, compiled via `gomobile` to native shared libraries (`.aar` for Android, `.framework` for iOS).
- **Native OS Bridges:** Flutter MethodChannels (Kotlin/Java for Android, Swift for iOS).

# Architecture & Responsibilities
1. **Flutter (Dart):** Responsible ONLY for the UI, state management, API calls to the panel, and preparing the configuration file. It does NOT handle raw network packets.
2. **Go Core (Mihomo):** Runs as a background service. It is responsible for parsing the YAML configuration, managing connections via various protocols (AmneziaWG, Hysteria 2, VLESS, VMESS, Trojan), and handling domain/IP-based routing rules.
3. **Native OS Layer:** 
   - **Android:** Uses `VpnService` to capture device traffic and route it to the Mihomo local port. Handles app-level split tunneling (`addAllowedApplication` / `addDisallowedApplication`).
   - **iOS:** Uses `NetworkExtension` to establish the tunnel.

# Key Features & Implementation Specifics

## 1. Subscription & Config Retrieval
- The app fetches subscription nodes using a sub-link.
- **CRITICAL:** All HTTP GET requests to the sub-link MUST include the header `User-Agent: Clash.Meta`. This ensures the Remnawave backend returns a pre-formatted YAML file rather than Base64 encoded raw links.

## 2. YAML Merging & Geo-Routing (RU Bypass)
- The downloaded YAML must be parsed and modified locally before being passed to the Mihomo core.
- The app must inject custom routing rules to ensure specific regional traffic (e.g., Russian services) bypasses the VPN.
- **Required Injected Rules:**
  - `DOMAIN-SUFFIX,ru,DIRECT`
  - `GEOSITE,ru,DIRECT`
  - `GEOIP,ru,DIRECT`
  - `MATCH,PROXY` (Fallback rule)

## 3. Split Tunneling
- **App-Based (Android Only):** Handled natively. The Flutter UI provides a list of installed package names to the native Kotlin code via MethodChannel.
- **Domain/IP-Based (Cross-Platform):** Handled by dynamically updating the `rules` section in the Mihomo YAML configuration.

# AI Assistant Directives (Strict Rules)

## Code Generation
- **Dart:** Always write modern, null-safe Dart 3 code.
- **UI:** Use Material 3 guidelines. Keep widgets small, modular, and reusable. Avoid heavy animations to preserve battery life.
- **State:** Keep UI strictly separated from business logic. Use Riverpod `@riverpod` annotations (code generation) for state management. Do not mix UI logic with MethodChannel calls.

## Networking & VPN Context
- Never suggest implementing packet interception or raw sockets in Dart. All routing is delegated to Mihomo and Native OS APIs.
- Assume the developer has a strong background in Go, system administration, and microservices. When assisting with the Mihomo/`gomobile` integration, provide advanced, production-ready Go bindings and do not over-explain basic Go syntax.
- Ensure any modifications to the Clash configuration strict adherence to the official Clash.Meta / Mihomo YAML specification.

## Troubleshooting Focus
- If errors occur related to connection drops, prioritize checking:
  1. Background execution limits (e.g., Android battery optimization killing the Go process).
  2. YAML syntax errors during the merge process.
  3. Memory leaks in the MethodChannel bridging.