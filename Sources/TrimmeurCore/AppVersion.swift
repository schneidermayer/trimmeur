import Foundation

public enum AppVersion {
    public static let initialVersion = "1.0"

    public static func quitMenuItemTitle(appName: String, version: String?) -> String {
        guard let version = version?.trimmingCharacters(in: .whitespacesAndNewlines),
              !version.isEmpty else {
            return "Quit \(appName)"
        }

        return "Quit \(appName) \(version)"
    }
}
