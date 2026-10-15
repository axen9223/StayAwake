import Cocoa

final class StatusBarController {

    private let statusItem: NSStatusItem
    private let popover:    NSPopover
    private let popoverVC:  PopoverViewController
    private var eventMonitor: EventMonitor?

    init() {
        // ── Popover ───────────────────────────────────────────────────────────
        popoverVC = PopoverViewController()

        popover = NSPopover()
        popover.contentViewController = popoverVC
        popover.contentSize           = NSSize(width: 210, height: 105)
        popover.behavior              = .transient   // closes on outside click
        popover.animates              = true
        popover.appearance            = NSAppearance(named: .darkAqua)

        // ── Menu-bar status item ──────────────────────────────────────────────
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.autosaveName = "StayAwakeStatusItem"

        if let btn = statusItem.button {
            updateIcon(isActive: SleepManager.shared.isAwakeEnabled)
            btn.action = #selector(togglePopover(_:))
            btn.target = self

            // Automatically open popover on launch so the user immediately sees it
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                self?.showPopover()
            }
        }

        // ── Notifications ─────────────────────────────────────────────────────
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(onSleepStateChanged),
            name: .sleepStateChanged,
            object: nil
        )

        // Close popover when user clicks anywhere outside it
        eventMonitor = EventMonitor(mask: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            guard let self, self.popover.isShown else { return }
            self.closePopover()
        }
    }

    deinit { NotificationCenter.default.removeObserver(self) }

    // MARK: - Popover control

    @objc private func togglePopover(_ sender: AnyObject?) {
        popover.isShown ? closePopover() : showPopover()
    }

    private func showPopover() {
        guard let btn = statusItem.button else { return }
        popover.show(relativeTo: btn.bounds, of: btn, preferredEdge: .minY)
        eventMonitor?.start()
        NSApp.activate(ignoringOtherApps: true)
    }

    private func closePopover() {
        popover.performClose(nil)
        eventMonitor?.stop()
    }

    // MARK: - Icon

    @objc private func onSleepStateChanged() {
        updateIcon(isActive: SleepManager.shared.isAwakeEnabled)
    }

    private func updateIcon(isActive: Bool) {
        guard let btn = statusItem.button else { return }

        let logoImage: NSImage? = {
            if let path = Bundle.main.path(forResource: "stayAwake_logo", ofType: "png") {
                return NSImage(contentsOfFile: path)
            }
            let fallback = Bundle.main.bundlePath.appending("/Contents/Resources/stayAwake_logo.png")
            return NSImage(contentsOfFile: fallback)
        }()

        if let logo = logoImage {
            logo.size = NSSize(width: 18, height: 18)
            logo.isTemplate = true
            btn.image = logo
        } else {
            let symbolName = isActive ? "cup.and.saucer.fill" : "cup.and.saucer"
            let config = NSImage.SymbolConfiguration(pointSize: 16, weight: .semibold)
            let img = NSImage(systemSymbolName: symbolName, accessibilityDescription: "StayAwake")?.withSymbolConfiguration(config)
            img?.isTemplate = true
            btn.image = img
        }

        btn.contentTintColor = isActive ? NSColor.systemOrange : nil
        btn.imagePosition = .imageOnly
        btn.toolTip = isActive
            ? "StayAwake: ON — Keeping your Mac awake"
            : "StayAwake: OFF — Sleep is allowed (Click to toggle)"
    }
}
