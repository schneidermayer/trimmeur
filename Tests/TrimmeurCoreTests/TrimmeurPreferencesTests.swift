import XCTest
@testable import TrimmeurCore

final class TrimmeurPreferencesTests: XCTestCase {
    private var suiteName: String!
    private var userDefaults: UserDefaults!

    override func setUp() {
        super.setUp()
        suiteName = "TrimmeurPreferencesTests-\(UUID().uuidString)"
        userDefaults = UserDefaults(suiteName: suiteName)
        userDefaults.removePersistentDomain(forName: suiteName)
    }

    override func tearDown() {
        userDefaults.removePersistentDomain(forName: suiteName)
        userDefaults = nil
        suiteName = nil
        super.tearDown()
    }

    func testShortcutDefaultsToPasteTrimmedShortcut() {
        let preferences = TrimmeurPreferences(userDefaults: userDefaults)

        XCTAssertEqual(preferences.pasteTrimmedShortcut, .defaultPasteTrimmed)
    }

    func testShortcutPersists() {
        let preferences = TrimmeurPreferences(userDefaults: userDefaults)
        let shortcut = KeyboardShortcut(keyCode: 8, modifiers: [.control, .option])

        preferences.pasteTrimmedShortcut = shortcut

        XCTAssertEqual(TrimmeurPreferences(userDefaults: userDefaults).pasteTrimmedShortcut, shortcut)
    }

    func testStartOnLoginPersists() {
        let preferences = TrimmeurPreferences(userDefaults: userDefaults)

        preferences.startOnLogin = true

        XCTAssertTrue(TrimmeurPreferences(userDefaults: userDefaults).startOnLogin)
    }
}
