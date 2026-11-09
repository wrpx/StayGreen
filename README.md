# ☕ StayGreen

A lightweight, native macOS Menu Bar utility written in Swift that prevents your display from sleeping and keeps Microsoft Teams / Slack status active (**Available / Green**) without interrupting your workflow.

---

## ✨ Features

- **Menu Bar Only (`LSUIElement`)** — Lives quietly in your macOS menu bar with zero Dock clutter.
- **Smart Idle Detection** — Checks system-wide HID idle time (`CGEventSource.secondsSinceLastEventType`) every 2 seconds. It only nudges the cursor by 1px and back when your Mac has been completely idle for **55 seconds** (so it never interferes while you're actually using the mouse).
- **Display Sleep Prevention** — Uses native `IOKit` power assertions (`kIOPMAssertionTypePreventUserIdleDisplaySleep`) while active.
- **Customizable Menu Bar Icons** — Switch anytime between 5 SF Symbol presets (saved automatically via `UserDefaults`):
  - ☕ Cup (`cup.and.saucer.fill`)
  - ⚡ Bolt (`bolt.fill`)
  - 🖱️ Mouse (`computermouse.fill`)
  - • Minimal Dot (`smallcircle.filled.circle`)
  - 👁️ Eye (`eye.fill`)
- **Live Status & Counter** — Click the menu bar icon to inspect current idle seconds (`Idle: 12s / 55s`) and total idle resets.

---

## 🛠️ Build & Install

### Requirements
- macOS 12.0+ (Monterey or later)
- Xcode Command Line Tools (`xcode-select --install`)

### Quick Install
```bash
# Build StayGreen.app, install to /Applications, and launch it
make run
```

### Other Commands
```bash
make build    # Build build/StayGreen.app only
make install  # Build and copy StayGreen.app to /Applications
make clean    # Remove build artifacts
```

> **VS Code Tip:** Open this folder in VS Code and press `Cmd + Shift + B` to build, install, and launch `StayGreen.app` in one step.

---

## 🔐 Accessibility Permission (macOS)

To simulate the subtle 1px mouse movement that resets Microsoft Teams idle status, macOS requires **Accessibility** permission:

1. Open **System Settings** → **Privacy & Security** → **Accessibility**
2. Enable **StayGreen** (if you rebuilt the app, toggle it off & on once)

---

## 📁 Project Structure

```text
StayGreen/
├── Sources/
│   └── main.swift              # Core menu bar app, IOKit power assertion & HID jiggler
├── Resources/
│   ├── Info.plist              # App bundle metadata (LSUIElement = true)
│   └── AppIcon.icns            # Native macOS app icon
├── scripts/
│   └── generate-icon.swift     # Generates AppIcon.icns programmatically
├── .vscode/
│   └── tasks.json              # Cmd+Shift+B build task for VS Code
└── Makefile                    # Build, sign, install, and run targets
```
