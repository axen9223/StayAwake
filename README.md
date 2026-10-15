# ☕ StayAwake

A lightweight, native macOS menu bar utility designed to temporarily prevent your Mac from sleeping, dimming its display, or locking itself.

---

## 📌 Features

* **One-Click Sleep Toggle**:
  * **Turn ON**: Executes `sudo pmset -a disablesleep 1` via AppleScript. Your Mac stays awake even with the display or lid closed.
  * **Turn OFF**: Executes `sudo pmset -a disablesleep 0` to restore macOS's default power-saving schedule.
* **Pure Menu Bar Utility**: Runs as an accessory (`LSUIElement = true`) without cluttering your Dock or the `⌘+Tab` App Switcher.
* **Custom Coffee Cup Logo**:
  * **Idle Mode (Sleep Allowed)**: Clean monochrome coffee cup with sunbeams.
  * **Active Mode (Awake Mode ON)**: Lights up in vibrant **amber/orange** in the menu bar.
* **Compact HUD Card**: Clicking the menu bar icon drops down a sleek dark frosted-glass card (`210 × 105 pt`) featuring a native `NSSwitch` and a **Quit** button.
* **Single-Instance Protection**: Uses kernel-level file locking (`flock`) to guarantee only one instance can run at a time, preventing duplicate menu bar icons.
* **Safe Exit**: Quitting the app automatically restores normal sleep before terminating so your Mac is never accidentally left awake permanently.
* **Draggable Status Item**: Hold `⌘` (Command) and click-and-drag the coffee cup icon to place it anywhere along your menu bar.

---

## 🚀 How to Run

The compiled application bundle is located at:
```
StayAwake/build/StayAwake.app
```

### 1. Run via Finder
Double-click `StayAwake.app` inside the `build/` folder.

### 2. Run via Terminal
```bash
open build/StayAwake.app
```

### 3. Install to Applications (Optional)
Drag `StayAwake.app` to your `/Applications` folder to launch it anytime via Spotlight or Launchpad.

> **Note on Permissions**:  
> macOS requires administrator rights to change sleep settings (`pmset`). When toggling sleep prevention ON for the first time, macOS will prompt for your password/Touch ID once. macOS caches this authorization for the session.

---

## 🔨 How to Build

### Method A: Command-Line Build (No full Xcode required)
You only need Apple's Command Line Tools (`swiftc`):

```bash
set -e

APP_DIR="build/StayAwake.app"
mkdir -p "$APP_DIR/Contents/MacOS" "$APP_DIR/Contents/Resources"

# 1. Copy icon assets and Info.plist
cp StayAwake/AppIcon.icns "$APP_DIR/Contents/Resources/"
cp StayAwake/Assets/stayAwake_logo.png "$APP_DIR/Contents/Resources/"
cp StayAwake/Info.plist "$APP_DIR/Contents/"

# 2. Compile Swift sources
swiftc \
  -sdk $(xcrun --show-sdk-path) \
  -target arm64-apple-macos13.0 \
  -module-name StayAwake \
  -parse-as-library \
  StayAwake/AppDelegate.swift \
  StayAwake/StatusBarController.swift \
  StayAwake/PopoverViewController.swift \
  StayAwake/SleepManager.swift \
  StayAwake/EventMonitor.swift \
  -o "$APP_DIR/Contents/MacOS/StayAwake"

# 3. Ad-hoc codesign
codesign --force --deep --sign - "$APP_DIR"
xattr -cr "$APP_DIR"

echo "Build complete: $APP_DIR"
```

### Method B: Xcode Project
Open `StayAwake.xcodeproj` in Xcode and press `⌘R` (Run) or `⌘B` (Build).

---

## 📦 How to Share

To share the app with friends or colleagues:

1. **Compress the app bundle into a zip**:
   ```bash
   ditto -c -k --sequesterRsrc --keepParent build/StayAwake.app ~/Downloads/StayAwake.zip
   ```
2. **First-time launch on another Mac**:  
   Because this app is ad-hoc signed, macOS Gatekeeper may show a verification prompt on first launch. Tell the recipient to:
   * **Right-click (Control-click) `StayAwake.app` → Open → Click "Open"**.

---

## 📁 Project Structure

```
StayAwake/
├── README.md                  # Project documentation & walkthrough
├── StayAwake.xcodeproj/       # Xcode project file
├── build/
│   └── StayAwake.app/         # Standalone compiled application ready to run
└── StayAwake/
    ├── AppDelegate.swift       # Lifecycle, delegate & single-instance lock
    ├── StatusBarController.swift # NSStatusItem, menu bar icon state & popover presentation
    ├── PopoverViewController.swift # Frosted-glass HUD card with NSSwitch & Quit
    ├── SleepManager.swift      # pmset disablesleep executor via AppleScript
    ├── EventMonitor.swift      # Global click monitor to auto-dismiss popover
    ├── Info.plist              # Bundle metadata (LSUIElement=true, AppIcon link)
    ├── AppIcon.icns            # Application icon generated from custom logo
    └── Assets/
        └── stayAwake_logo.png  # Transparent template image for the menu bar
```
