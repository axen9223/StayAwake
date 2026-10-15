import Cocoa

// MARK: - PopoverViewController

final class PopoverViewController: NSViewController {

    // ── Subviews ──────────────────────────────────────────────────────────────
    private var logoImageView: NSImageView!
    private var titleLabel:   NSTextField!
    private var quitBtn:      NSButton!
    private var toggleSwitch: NSSwitch!
    private var statusLabel:  NSTextField!
    private var hintLabel:    NSTextField!

    // ── Colours ───────────────────────────────────────────────────────────────
    private let amber = NSColor(calibratedRed: 1.0, green: 0.584, blue: 0.0, alpha: 1.0)

    // MARK: - Lifecycle

    override func loadView() {
        let fx = NSVisualEffectView(frame: NSRect(x: 0, y: 0, width: 210, height: 105))
        fx.material     = .hudWindow
        fx.blendingMode = .behindWindow
        fx.state        = .active
        view = fx
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        buildUI()
        refresh()
    }

    // MARK: - UI Construction

    private func buildUI() {
        // ── Header: Logo, Title & Quit ────────────────────────────────────
        logoImageView = NSImageView()
        logoImageView.imageScaling = .scaleProportionallyUpOrDown
        let logoImage: NSImage? = {
            if let path = Bundle.main.path(forResource: "stayAwake_logo", ofType: "png") {
                return NSImage(contentsOfFile: path)
            }
            let fallback = Bundle.main.bundlePath.appending("/Contents/Resources/stayAwake_logo.png")
            return NSImage(contentsOfFile: fallback)
        }()
        if let img = logoImage {
            img.isTemplate = true
            logoImageView.image = img
            logoImageView.contentTintColor = amber
        }
        logoImageView.translatesAutoresizingMaskIntoConstraints = false

        titleLabel = makeLabel("StayAwake", size: 13, weight: .bold)

        quitBtn = NSButton(title: "Quit", target: self, action: #selector(handleQuit))
        quitBtn.bezelStyle = .inline
        quitBtn.isBordered = false
        quitBtn.font = .systemFont(ofSize: 11, weight: .regular)
        quitBtn.contentTintColor = .secondaryLabelColor
        quitBtn.translatesAutoresizingMaskIntoConstraints = false

        // ── Middle: Status & Switch ───────────────────────────────────────
        statusLabel = makeLabel("Prevent Sleep", size: 12.5, weight: .medium)

        toggleSwitch = NSSwitch()
        toggleSwitch.target = self
        toggleSwitch.action = #selector(handleToggle)
        toggleSwitch.translatesAutoresizingMaskIntoConstraints = false

        // ── Bottom: Hint ──────────────────────────────────────────────────
        hintLabel = makeLabel("Sleep allowed", size: 10, weight: .regular)
        hintLabel.textColor = .tertiaryLabelColor

        [logoImageView, titleLabel, quitBtn, statusLabel, toggleSwitch, hintLabel].forEach {
            view.addSubview($0)
        }

        applyConstraints()
    }

    private func applyConstraints() {
        NSLayoutConstraint.activate([
            // Header
            logoImageView.topAnchor.constraint(equalTo: view.topAnchor, constant: 11),
            logoImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 14),
            logoImageView.widthAnchor.constraint(equalToConstant: 18),
            logoImageView.heightAnchor.constraint(equalToConstant: 18),

            titleLabel.centerYAnchor.constraint(equalTo: logoImageView.centerYAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: logoImageView.trailingAnchor, constant: 6),

            quitBtn.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            quitBtn.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),

            // Middle row
            statusLabel.topAnchor.constraint(equalTo: logoImageView.bottomAnchor, constant: 14),
            statusLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 14),

            toggleSwitch.centerYAnchor.constraint(equalTo: statusLabel.centerYAnchor),
            toggleSwitch.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -14),
            toggleSwitch.leadingAnchor.constraint(greaterThanOrEqualTo: statusLabel.trailingAnchor, constant: 8),

            // Hint
            hintLabel.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 6),
            hintLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 14),
            hintLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -14),
            hintLabel.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -12)
        ])
    }

    // MARK: - Helpers

    private func makeLabel(_ text: String, size: CGFloat, weight: NSFont.Weight) -> NSTextField {
        let lbl = NSTextField(labelWithString: text)
        lbl.font = .systemFont(ofSize: size, weight: weight)
        lbl.textColor = .labelColor
        lbl.isEditable = false
        lbl.isSelectable = false
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }

    // MARK: - State

    func refresh() {
        let isOn = SleepManager.shared.isAwakeEnabled
        toggleSwitch.state = isOn ? .on : .off
        statusLabel.stringValue = isOn ? "Awake Mode" : "Prevent Sleep"
        statusLabel.textColor   = isOn ? amber : .labelColor
        hintLabel.stringValue   = isOn ? "Mac sleep is prevented" : "Normal sleep is allowed"
    }

    // MARK: - Actions

    @objc private func handleToggle() {
        let willBeOn = toggleSwitch.state == .on
        toggleSwitch.isEnabled = false
        hintLabel.stringValue = "Applying changes…"
        hintLabel.textColor = .secondaryLabelColor

        let done: (Bool, String?) -> Void = { [weak self] ok, err in
            guard let self else { return }
            self.toggleSwitch.isEnabled = true

            if ok {
                self.refresh()
                NotificationCenter.default.post(name: .sleepStateChanged, object: nil)
            } else {
                // Revert
                self.toggleSwitch.state = willBeOn ? .off : .on
                self.refresh()

                if let msg = err {
                    let alert = NSAlert()
                    alert.messageText     = "StayAwake — Error"
                    alert.informativeText = msg
                    alert.alertStyle      = .warning
                    alert.runModal()
                }
            }
        }

        if willBeOn {
            SleepManager.shared.enable(completion: done)
        } else {
            SleepManager.shared.disable(completion: done)
        }
    }

    @objc private func handleQuit() {
        if SleepManager.shared.isAwakeEnabled {
            SleepManager.shared.disable { _, _ in NSApp.terminate(nil) }
        } else {
            NSApp.terminate(nil)
        }
    }
}
