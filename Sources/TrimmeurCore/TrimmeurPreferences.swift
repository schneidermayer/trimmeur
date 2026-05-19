import Foundation

public final class TrimmeurPreferences {
    private enum Key {
        static let pasteTrimmedShortcut = "pasteTrimmedShortcut"
        static let startOnLogin = "startOnLogin"
    }

    private let userDefaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    public init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    public var pasteTrimmedShortcut: KeyboardShortcut {
        get {
            guard let data = userDefaults.data(forKey: Key.pasteTrimmedShortcut),
                  let shortcut = try? decoder.decode(KeyboardShortcut.self, from: data) else {
                return .defaultPasteTrimmed
            }

            return shortcut
        }
        set {
            if let data = try? encoder.encode(newValue) {
                userDefaults.set(data, forKey: Key.pasteTrimmedShortcut)
            }
        }
    }

    public var startOnLogin: Bool {
        get {
            userDefaults.bool(forKey: Key.startOnLogin)
        }
        set {
            userDefaults.set(newValue, forKey: Key.startOnLogin)
        }
    }

    public func resetShortcut() {
        userDefaults.removeObject(forKey: Key.pasteTrimmedShortcut)
    }
}
