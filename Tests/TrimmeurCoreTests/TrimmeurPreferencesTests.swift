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

    func testPasteWithoutLineBreaksShortcutDefaultsToShiftOptionCommandT() {
        let preferences = TrimmeurPreferences(userDefaults: userDefaults)

        XCTAssertEqual(preferences.pasteWithoutLineBreaksShortcut, .defaultPasteWithoutLineBreaks)
    }

    func testPasteWithoutLineBreaksShortcutPersistsIndependently() {
        let preferences = TrimmeurPreferences(userDefaults: userDefaults)
        let pasteShortcut = KeyboardShortcut(keyCode: 8, modifiers: [.control, .option])
        let pasteWithoutLineBreaksShortcut = KeyboardShortcut(keyCode: 9, modifiers: [.shift, .control])

        preferences.pasteTrimmedShortcut = pasteShortcut
        preferences.pasteWithoutLineBreaksShortcut = pasteWithoutLineBreaksShortcut

        let reloadedPreferences = TrimmeurPreferences(userDefaults: userDefaults)
        XCTAssertEqual(reloadedPreferences.pasteTrimmedShortcut, pasteShortcut)
        XCTAssertEqual(reloadedPreferences.pasteWithoutLineBreaksShortcut, pasteWithoutLineBreaksShortcut)
    }

    func testResetPasteShortcutPreservesPasteWithoutLineBreaksShortcut() {
        let preferences = TrimmeurPreferences(userDefaults: userDefaults)
        let pasteWithoutLineBreaksShortcut = KeyboardShortcut(keyCode: 9, modifiers: [.shift, .control])
        preferences.pasteTrimmedShortcut = KeyboardShortcut(keyCode: 8, modifiers: [.control, .option])
        preferences.pasteWithoutLineBreaksShortcut = pasteWithoutLineBreaksShortcut

        preferences.resetShortcut()

        let reloadedPreferences = TrimmeurPreferences(userDefaults: userDefaults)
        XCTAssertEqual(reloadedPreferences.pasteTrimmedShortcut, .defaultPasteTrimmed)
        XCTAssertEqual(reloadedPreferences.pasteWithoutLineBreaksShortcut, pasteWithoutLineBreaksShortcut)
    }

    func testResetPasteWithoutLineBreaksShortcutPreservesPasteShortcut() {
        let preferences = TrimmeurPreferences(userDefaults: userDefaults)
        let pasteShortcut = KeyboardShortcut(keyCode: 8, modifiers: [.control, .option])
        preferences.pasteTrimmedShortcut = pasteShortcut
        preferences.pasteWithoutLineBreaksShortcut = KeyboardShortcut(keyCode: 9, modifiers: [.shift, .control])

        preferences.resetPasteWithoutLineBreaksShortcut()

        let reloadedPreferences = TrimmeurPreferences(userDefaults: userDefaults)
        XCTAssertEqual(reloadedPreferences.pasteTrimmedShortcut, pasteShortcut)
        XCTAssertEqual(reloadedPreferences.pasteWithoutLineBreaksShortcut, .defaultPasteWithoutLineBreaks)
    }

    func testMalformedSavedPasteWithoutLineBreaksShortcutFallsBackToDefault() {
        userDefaults.set(Data("invalid shortcut".utf8), forKey: "pasteWithoutLineBreaksShortcut")
        let preferences = TrimmeurPreferences(userDefaults: userDefaults)

        XCTAssertEqual(preferences.pasteWithoutLineBreaksShortcut, .defaultPasteWithoutLineBreaks)
    }

    func testObsoleteTrimClipboardShortcutDoesNotConfigurePasteWithoutLineBreaks() throws {
        let obsoleteShortcut = KeyboardShortcut(keyCode: 9, modifiers: [.shift, .control])
        let savedShortcut = try JSONEncoder().encode(obsoleteShortcut)
        userDefaults.set(savedShortcut, forKey: "trimClipboardAndRemoveLineBreaksShortcut")
        let preferences = TrimmeurPreferences(userDefaults: userDefaults)

        XCTAssertEqual(preferences.pasteWithoutLineBreaksShortcut, .defaultPasteWithoutLineBreaks)
    }

    func testStartOnLoginPersists() {
        let preferences = TrimmeurPreferences(userDefaults: userDefaults)

        preferences.startOnLogin = true

        XCTAssertTrue(TrimmeurPreferences(userDefaults: userDefaults).startOnLogin)
    }
}
