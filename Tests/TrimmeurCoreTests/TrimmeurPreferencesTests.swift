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

    func testTrimClipboardAndRemoveLineBreaksShortcutDefaultsToShiftOptionCommandT() {
        let preferences = TrimmeurPreferences(userDefaults: userDefaults)

        XCTAssertEqual(preferences.trimClipboardAndRemoveLineBreaksShortcut, .defaultTrimClipboardAndRemoveLineBreaks)
    }

    func testTrimClipboardAndRemoveLineBreaksShortcutPersistsIndependently() {
        let preferences = TrimmeurPreferences(userDefaults: userDefaults)
        let pasteShortcut = KeyboardShortcut(keyCode: 8, modifiers: [.control, .option])
        let trimShortcut = KeyboardShortcut(keyCode: 9, modifiers: [.shift, .control])

        preferences.pasteTrimmedShortcut = pasteShortcut
        preferences.trimClipboardAndRemoveLineBreaksShortcut = trimShortcut

        let reloadedPreferences = TrimmeurPreferences(userDefaults: userDefaults)
        XCTAssertEqual(reloadedPreferences.pasteTrimmedShortcut, pasteShortcut)
        XCTAssertEqual(reloadedPreferences.trimClipboardAndRemoveLineBreaksShortcut, trimShortcut)
    }

    func testResetPasteShortcutPreservesTrimClipboardAndRemoveLineBreaksShortcut() {
        let preferences = TrimmeurPreferences(userDefaults: userDefaults)
        let trimShortcut = KeyboardShortcut(keyCode: 9, modifiers: [.shift, .control])
        preferences.pasteTrimmedShortcut = KeyboardShortcut(keyCode: 8, modifiers: [.control, .option])
        preferences.trimClipboardAndRemoveLineBreaksShortcut = trimShortcut

        preferences.resetShortcut()

        let reloadedPreferences = TrimmeurPreferences(userDefaults: userDefaults)
        XCTAssertEqual(reloadedPreferences.pasteTrimmedShortcut, .defaultPasteTrimmed)
        XCTAssertEqual(reloadedPreferences.trimClipboardAndRemoveLineBreaksShortcut, trimShortcut)
    }

    func testResetTrimClipboardAndRemoveLineBreaksShortcutPreservesPasteShortcut() {
        let preferences = TrimmeurPreferences(userDefaults: userDefaults)
        let pasteShortcut = KeyboardShortcut(keyCode: 8, modifiers: [.control, .option])
        preferences.pasteTrimmedShortcut = pasteShortcut
        preferences.trimClipboardAndRemoveLineBreaksShortcut = KeyboardShortcut(keyCode: 9, modifiers: [.shift, .control])

        preferences.resetTrimClipboardAndRemoveLineBreaksShortcut()

        let reloadedPreferences = TrimmeurPreferences(userDefaults: userDefaults)
        XCTAssertEqual(reloadedPreferences.pasteTrimmedShortcut, pasteShortcut)
        XCTAssertEqual(reloadedPreferences.trimClipboardAndRemoveLineBreaksShortcut, .defaultTrimClipboardAndRemoveLineBreaks)
    }

    func testMalformedSavedTrimClipboardAndRemoveLineBreaksShortcutFallsBackToDefault() {
        userDefaults.set(Data("invalid shortcut".utf8), forKey: "trimClipboardAndRemoveLineBreaksShortcut")
        let preferences = TrimmeurPreferences(userDefaults: userDefaults)

        XCTAssertEqual(preferences.trimClipboardAndRemoveLineBreaksShortcut, .defaultTrimClipboardAndRemoveLineBreaks)
    }

    func testStartOnLoginPersists() {
        let preferences = TrimmeurPreferences(userDefaults: userDefaults)

        preferences.startOnLogin = true

        XCTAssertTrue(TrimmeurPreferences(userDefaults: userDefaults).startOnLogin)
    }
}
