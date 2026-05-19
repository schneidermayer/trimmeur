import AppKit

enum SingleInstanceManager {
    static func alreadyRunningApplications(
        bundleIdentifier: String? = Bundle.main.bundleIdentifier,
        currentProcessIdentifier: pid_t = ProcessInfo.processInfo.processIdentifier
    ) -> [NSRunningApplication] {
        guard let bundleIdentifier, !bundleIdentifier.isEmpty else { return [] }

        return NSRunningApplication.runningApplications(withBundleIdentifier: bundleIdentifier)
            .filter { $0.processIdentifier != currentProcessIdentifier }
    }

    static func close(_ applications: [NSRunningApplication], timeout: TimeInterval = 2.0) {
        guard !applications.isEmpty else { return }

        for application in applications {
            application.terminate()
        }

        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline && applications.contains(where: { !$0.isTerminated }) {
            RunLoop.current.run(mode: .default, before: Date().addingTimeInterval(0.05))
        }

        for application in applications where !application.isTerminated {
            application.forceTerminate()
        }
    }
}
