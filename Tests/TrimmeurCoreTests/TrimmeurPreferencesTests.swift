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

    func testPasteLowercaseHasNoDefaultShortcut() {
        let preferences = TrimmeurPreferences(userDefaults: userDefaults)

        XCTAssertNil(preferences.pasteLowercaseShortcut)
    }

    func testPasteLowercaseShortcutPersistsIndependently() {
        let preferences = TrimmeurPreferences(userDefaults: userDefaults)
        let custom = KeyboardShortcut(keyCode: 8, modifiers: [.control, .option])

        preferences.pasteLowercaseShortcut = custom

        let reloadedPreferences = TrimmeurPreferences(userDefaults: userDefaults)
        XCTAssertEqual(reloadedPreferences.pasteLowercaseShortcut, custom)
        XCTAssertEqual(reloadedPreferences.pasteTrimmedShortcut, .defaultPasteTrimmed)
        XCTAssertEqual(reloadedPreferences.pasteWithoutLineBreaksShortcut, .defaultPasteWithoutLineBreaks)
    }

    func testClearingPasteLowercaseShortcutPreservesExistingSettings() {
        let preferences = TrimmeurPreferences(userDefaults: userDefaults)
        let custom = KeyboardShortcut(keyCode: 8, modifiers: [.control, .option])
        preferences.pasteTrimmedShortcut = custom
        preferences.pasteLowercaseShortcut = KeyboardShortcut(keyCode: 9, modifiers: [.control, .option])
        preferences.startOnLogin = true

        preferences.pasteLowercaseShortcut = nil

        let reloadedPreferences = TrimmeurPreferences(userDefaults: userDefaults)
        XCTAssertNil(reloadedPreferences.pasteLowercaseShortcut)
        XCTAssertNil(userDefaults.object(forKey: "pasteLowercaseShortcut"))
        XCTAssertEqual(reloadedPreferences.pasteTrimmedShortcut, custom)
        XCTAssertEqual(reloadedPreferences.pasteWithoutLineBreaksShortcut, .defaultPasteWithoutLineBreaks)
        XCTAssertTrue(reloadedPreferences.startOnLogin)
    }

    func testMalformedSavedPasteLowercaseShortcutLeavesItUnassigned() {
        userDefaults.set(Data("invalid shortcut".utf8), forKey: "pasteLowercaseShortcut")
        let preferences = TrimmeurPreferences(userDefaults: userDefaults)

        XCTAssertNil(preferences.pasteLowercaseShortcut)
    }

    func testResettingExistingShortcutsPreservesPasteLowercaseShortcut() {
        let preferences = TrimmeurPreferences(userDefaults: userDefaults)
        let custom = KeyboardShortcut(keyCode: 8, modifiers: [.control, .option])
        preferences.pasteLowercaseShortcut = custom
        preferences.pasteTrimmedShortcut = KeyboardShortcut(keyCode: 9, modifiers: [.control, .option])
        preferences.pasteWithoutLineBreaksShortcut = KeyboardShortcut(keyCode: 10, modifiers: [.control, .option])

        preferences.resetShortcut()
        preferences.resetPasteWithoutLineBreaksShortcut()

        let reloadedPreferences = TrimmeurPreferences(userDefaults: userDefaults)
        XCTAssertEqual(reloadedPreferences.pasteLowercaseShortcut, custom)
        XCTAssertEqual(reloadedPreferences.pasteTrimmedShortcut, .defaultPasteTrimmed)
        XCTAssertEqual(reloadedPreferences.pasteWithoutLineBreaksShortcut, .defaultPasteWithoutLineBreaks)
    }
}
