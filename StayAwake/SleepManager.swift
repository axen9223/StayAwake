import Foundation
import AppKit

// MARK: - SleepManager

final class SleepManager {

    static let shared = SleepManager()

    // ── Persistence ──────────────────────────────────────────────────────────
    private let defaultsKey = "StayAwake_isEnabled"

    var isAwakeEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: defaultsKey) }
        set { UserDefaults.standard.set(newValue, forKey: defaultsKey) }
    }

    // Dedicated serial queue — NSAppleScript is not thread-safe; isolating it
    // here prevents concurrent executions while still keeping the UI responsive.
    private let queue = DispatchQueue(label: "com.stayawake.appleScript",
                                     qos: .userInitiated)

    private init() {}

    // ── Public API ────────────────────────────────────────────────────────────

    /// Disable macOS sleep (pmset disablesleep 1)
    func enable(completion: @escaping (Bool, String?) -> Void) {
        execute(value: 1, completion: completion)
    }

    /// Re-enable macOS sleep (pmset disablesleep 0)
    func disable(completion: @escaping (Bool, String?) -> Void) {
        execute(value: 0, completion: completion)
    }

    // ── Private ───────────────────────────────────────────────────────────────

    private func execute(value: Int, completion: @escaping (Bool, String?) -> Void) {
        // AppleScript prompts the user for their admin password exactly once
        // per session; macOS caches the authorisation for subsequent calls.
        let source = """
        do shell script "pmset -a disablesleep \(value)" with administrator privileges
        """

        queue.async {
            var errorDict: NSDictionary?
            NSAppleScript(source: source)?.executeAndReturnError(&errorDict)

            DispatchQueue.main.async {
                if let error = errorDict {
                    // Error code -128 means the user clicked Cancel — treat silently.
                    let code = error["NSAppleScriptErrorNumber"] as? Int
                    if code == -128 {
                        completion(false, nil)
                    } else {
                        let msg = error["NSAppleScriptErrorMessage"] as? String
                        completion(false, msg ?? "An unknown error occurred.")
                    }
                } else {
                    self.isAwakeEnabled = value == 1
                    completion(true, nil)
                }
            }
        }
    }
}

// MARK: - Notification

extension Notification.Name {
    static let sleepStateChanged = Notification.Name("com.stayawake.sleepStateChanged")
}
