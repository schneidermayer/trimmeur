import Foundation

public final class TrimmeurPreferences {
    private enum Key {
        static let pasteTrimmedShortcut = "pasteTrimmedShortcut"
        static let pasteWithoutLineBreaksShortcut = "pasteWithoutLineBreaksShortcut"
        static let pasteLowercaseShortcut = "pasteLowercaseShortcut"
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

    public var pasteWithoutLineBreaksShortcut: KeyboardShortcut {
        get {
            guard let data = userDefaults.data(forKey: Key.pasteWithoutLineBreaksShortcut),
                  let shortcut = try? decoder.decode(KeyboardShortcut.self, from: data) else {
                return .defaultPasteWithoutLineBreaks
            }

            return shortcut
        }
        set {
            if let data = try? encoder.encode(newValue) {
                userDefaults.set(data, forKey: Key.pasteWithoutLineBreaksShortcut)
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

    public var pasteLowercaseShortcut: KeyboardShortcut? {
        get {
            guard let data = userDefaults.data(forKey: Key.pasteLowercaseShortcut) else {
                return nil
            }

            return try? decoder.decode(KeyboardShortcut.self, from: data)
        }
        set {
            guard let newValue else {
                userDefaults.removeObject(forKey: Key.pasteLowercaseShortcut)
                return
            }

            if let data = try? encoder.encode(newValue) {
                userDefaults.set(data, forKey: Key.pasteLowercaseShortcut)
            }
        }
    }

    public func resetShortcut() {
        userDefaults.removeObject(forKey: Key.pasteTrimmedShortcut)
    }

    public func resetPasteWithoutLineBreaksShortcut() {
        userDefaults.removeObject(forKey: Key.pasteWithoutLineBreaksShortcut)
    }
}
