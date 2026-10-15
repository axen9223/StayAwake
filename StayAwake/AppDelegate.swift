import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {

    private static var strongDelegate: AppDelegate?
    private static var lockFileDescriptor: Int32 = -1
    private var statusBarController: StatusBarController?

    static func main() {
        // Prevent multiple instances from running concurrently
        guard ensureSingleInstance() else {
            // Another instance is already active; exit cleanly
            exit(0)
        }

        let app = NSApplication.shared
        let delegate = AppDelegate()
        strongDelegate = delegate
        app.delegate = delegate
        app.run()
    }

    private static func ensureSingleInstance() -> Bool {
        // 1. POSIX advisory lock via flock (kernel-managed, automatically cleared on process exit/crash)
        let lockPath = "/tmp/com.stayawake.app.lock"
        let fd = open(lockPath, O_CREAT | O_RDWR, 0o666)
        if fd >= 0 {
            if flock(fd, LOCK_EX | LOCK_NB) != 0 {
                close(fd)
                activateExistingInstance()
                return false
            }
            lockFileDescriptor = fd // Keep open to retain lock for entire process lifetime
        }

        // 2. LaunchServices bundle check
        if let bundleId = Bundle.main.bundleIdentifier, !bundleId.isEmpty {
            let currentPID = ProcessInfo.processInfo.processIdentifier
            let running = NSRunningApplication.runningApplications(withBundleIdentifier: bundleId)
            if running.contains(where: { $0.processIdentifier != currentPID }) {
                activateExistingInstance()
                return false
            }
        }

        return true
    }

    private static func activateExistingInstance() {
        if let bundleId = Bundle.main.bundleIdentifier, !bundleId.isEmpty {
            let currentPID = ProcessInfo.processInfo.processIdentifier
            if let existing = NSRunningApplication.runningApplications(withBundleIdentifier: bundleId).first(where: { $0.processIdentifier != currentPID }) {
                existing.activate(options: [.activateIgnoringOtherApps])
            }
        }
    }

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Run as a pure menu-bar app — no Dock icon, no App Switcher entry
        NSApp.setActivationPolicy(.accessory)
        statusBarController = StatusBarController()
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        if AppDelegate.lockFileDescriptor >= 0 {
            close(AppDelegate.lockFileDescriptor)
            AppDelegate.lockFileDescriptor = -1
        }
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }
}
