import Cocoa
import CoreGraphics
import IOKit.pwr_mgt

struct IconPreset {
    let name: String
    let activeSymbol: String
    let pausedSymbol: String
}

class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    var statusItem: NSStatusItem!
    var toggleMenuItem: NSMenuItem!
    var infoMenuItem: NSMenuItem!
    var timer: Timer?
    var isActive: Bool = true {
        didSet {
            updateUI()
            updatePowerAssertion()
        }
    }
    var assertionID: IOPMAssertionID = 0
    var hasAssertion: Bool = false
    var jiggleCount: Int = 0

    let presets: [IconPreset] = [
        IconPreset(name: "Cup (ถ้วยกาแฟ)", activeSymbol: "cup.and.saucer.fill", pausedSymbol: "cup.and.saucer"),
        IconPreset(name: "Bolt (สายฟ้า)", activeSymbol: "bolt.fill", pausedSymbol: "bolt.slash"),
        IconPreset(name: "Mouse (เมาส์)", activeSymbol: "computermouse.fill", pausedSymbol: "computermouse"),
        IconPreset(name: "Minimal Dot (จุดเล็ก)", activeSymbol: "smallcircle.filled.circle", pausedSymbol: "circle.dotted"),
        IconPreset(name: "Eye (ดวงตา)", activeSymbol: "eye.fill", pausedSymbol: "eye.slash")
    ]
    var selectedPresetIndex: Int = 0 {
        didSet {
            UserDefaults.standard.set(selectedPresetIndex, forKey: "SelectedIconPreset")
            updateUI()
            updatePresetMenuCheckmarks()
        }
    }
    var presetMenuItems: [NSMenuItem] = []

    func applicationDidFinishLaunching(_ notification: Notification) {
        if !CGPreflightPostEventAccess() {
            CGRequestPostEventAccess()
        }

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        let savedIndex = UserDefaults.standard.integer(forKey: "SelectedIconPreset")
        if savedIndex >= 0 && savedIndex < presets.count {
            selectedPresetIndex = savedIndex
        }

        let menu = NSMenu()
        menu.delegate = self

        infoMenuItem = NSMenuItem(title: "Active | Idle: 0s", action: nil, keyEquivalent: "")
        infoMenuItem.isEnabled = false
        menu.addItem(infoMenuItem)

        menu.addItem(NSMenuItem.separator())

        toggleMenuItem = NSMenuItem(title: "Pause", action: #selector(toggleActive), keyEquivalent: "p")
        toggleMenuItem.target = self
        menu.addItem(toggleMenuItem)

        let jiggleNowItem = NSMenuItem(title: "Reset Idle Now", action: #selector(jiggleNow), keyEquivalent: "r")
        jiggleNowItem.target = self
        menu.addItem(jiggleNowItem)

        let iconSubmenu = NSMenu()
        for (idx, preset) in presets.enumerated() {
            let item = NSMenuItem(title: preset.name, action: #selector(selectPreset(_:)), keyEquivalent: "")
            item.target = self
            item.tag = idx
            if let img = NSImage(systemSymbolName: preset.activeSymbol, accessibilityDescription: nil) {
                img.isTemplate = true
                item.image = img
            }
            iconSubmenu.addItem(item)
            presetMenuItems.append(item)
        }
        let iconMenuRoot = NSMenuItem(title: "Icon Style", action: nil, keyEquivalent: "")
        iconMenuRoot.submenu = iconSubmenu
        menu.addItem(iconMenuRoot)

        menu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(title: "Quit StayGreen", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem.menu = menu

        updatePresetMenuCheckmarks()
        updateUI()
        updatePowerAssertion()

        timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.tick()
        }
        RunLoop.current.add(timer!, forMode: .common)
    }

    @objc func selectPreset(_ sender: NSMenuItem) {
        selectedPresetIndex = sender.tag
    }

    func updatePresetMenuCheckmarks() {
        for (idx, item) in presetMenuItems.enumerated() {
            item.state = (idx == selectedPresetIndex) ? .on : .off
        }
    }

    func menuWillOpen(_ menu: NSMenu) {
        updateInfoText()
    }

    func getSystemIdleSeconds() -> Double {
        let anyEvent = CGEventType(rawValue: ~0)!
        return CGEventSource.secondsSinceLastEventType(.combinedSessionState, eventType: anyEvent)
    }

    func tick() {
        let idle = getSystemIdleSeconds()
        if isActive && idle >= 55.0 {
            performJiggle()
        }
        updateInfoText()
    }

    func updateInfoText() {
        let currentIdle = Int(getSystemIdleSeconds())
        let statusText = isActive ? "Active" : "Paused"
        infoMenuItem.title = "\(statusText)  •  Idle: \(currentIdle)s / 55s  •  Reset: \(jiggleCount)"
    }

    func performJiggle() {
        guard let loc = CGEvent(source: nil)?.location else { return }
        CGEvent(
            mouseEventSource: nil,
            mouseType: .mouseMoved,
            mouseCursorPosition: CGPoint(x: loc.x + 1, y: loc.y),
            mouseButton: .left
        )?.post(tap: .cghidEventTap)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            CGEvent(
                mouseEventSource: nil,
                mouseType: .mouseMoved,
                mouseCursorPosition: loc,
                mouseButton: .left
            )?.post(tap: .cghidEventTap)
        }
        jiggleCount += 1
    }

    @objc func toggleActive() {
        isActive.toggle()
        updateInfoText()
    }

    @objc func jiggleNow() {
        performJiggle()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
            self?.updateInfoText()
        }
    }

    func updateUI() {
        guard let button = statusItem?.button else { return }
        let preset = presets[selectedPresetIndex]
        let symbolName = isActive ? preset.activeSymbol : preset.pausedSymbol

        button.title = ""
        if let image = NSImage(systemSymbolName: symbolName, accessibilityDescription: nil) {
            let config = NSImage.SymbolConfiguration(pointSize: 13, weight: .regular)
            let configured = image.withSymbolConfiguration(config) ?? image
            configured.isTemplate = true
            button.image = configured
            button.alphaValue = isActive ? 1.0 : 0.45
        } else {
            button.title = isActive ? "•" : "◦"
        }
        toggleMenuItem?.title = isActive ? "Pause" : "Resume"
    }

    func updatePowerAssertion() {
        if isActive && !hasAssertion {
            let result = IOPMAssertionCreateWithName(
                kIOPMAssertionTypePreventUserIdleDisplaySleep as CFString,
                IOPMAssertionLevel(kIOPMAssertionLevelOn),
                "StayGreen Keep Display Awake" as CFString,
                &assertionID
            )
            if result == kIOReturnSuccess {
                hasAssertion = true
            }
        } else if !isActive && hasAssertion {
            IOPMAssertionRelease(assertionID)
            hasAssertion = false
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        if hasAssertion {
            IOPMAssertionRelease(assertionID)
            hasAssertion = false
        }
    }

    @objc func quitApp() {
        NSApplication.shared.terminate(nil)
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
