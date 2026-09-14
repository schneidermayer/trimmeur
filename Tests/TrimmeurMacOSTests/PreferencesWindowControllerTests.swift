import AppKit
import TrimmeurCore
import XCTest
@testable import TrimmeurMacOS

final class PreferencesWindowControllerTests: XCTestCase {
    private var suiteName: String!
    private var userDefaults: UserDefaults!
    private var preferences: TrimmeurPreferences!
    private var controller: PreferencesWindowController!
    private var changeCount = 0
    private var recordingChanges: [Bool] = []
    private var shortcutsWhenRecordingEnded: [KeyboardShortcut] = []

    override func setUp() {
        super.setUp()
        _ = NSApplication.shared
        suiteName = "TrimmeurShortcutUITests-\(UUID().uuidString)"
        userDefaults = UserDefaults(suiteName: suiteName)
        preferences = TrimmeurPreferences(userDefaults: userDefaults)
        changeCount = 0
        recordingChanges = []
        shortcutsWhenRecordingEnded = []
        controller = PreferencesWindowController(
            preferences: preferences,
            autoStartManager: StubAutoStartManager(),
            onShortcutChanged: { [weak self] in self?.changeCount += 1 },
            onShortcutRecordingChanged: { [weak self] isRecording in
                guard let self else { return }
                self.recordingChanges.append(isRecording)
                if !isRecording {
                    self.shortcutsWhenRecordingEnded.append(self.preferences.trimClipboardAndRemoveLineBreaksShortcut)
                }
            }
        )
    }

    override func tearDown() {
        controller.close()
        controller = nil
        preferences = nil
        userDefaults.removePersistentDomain(forName: suiteName)
        userDefaults = nil
        suiteName = nil
        super.tearDown()
    }

    func testChangingClipboardShortcutPreservesPasteShortcutAndNotifiesApp() {
        let custom = KeyboardShortcut(keyCode: 8, modifiers: [.control, .option])

        XCTAssertTrue(controller.setShortcut(custom, for: .trimClipboardAndRemoveLineBreaks))

        XCTAssertEqual(preferences.trimClipboardAndRemoveLineBreaksShortcut, custom)
        XCTAssertEqual(preferences.pasteTrimmedShortcut, .defaultPasteTrimmed)
        XCTAssertEqual(changeCount, 1)
    }

    func testBothActionsRejectShortcutAlreadyUsedByOtherAction() {
        XCTAssertFalse(controller.setShortcut(.defaultPasteTrimmed, for: .trimClipboardAndRemoveLineBreaks))
        XCTAssertFalse(controller.setShortcut(.defaultTrimClipboardAndRemoveLineBreaks, for: .pasteTrimmed))

        XCTAssertEqual(preferences.pasteTrimmedShortcut, .defaultPasteTrimmed)
        XCTAssertEqual(preferences.trimClipboardAndRemoveLineBreaksShortcut, .defaultTrimClipboardAndRemoveLineBreaks)
        XCTAssertEqual(changeCount, 0)
    }

    func testResetCannotTakeShortcutAssignedToOtherAction() {
        let custom = KeyboardShortcut(keyCode: 8, modifiers: [.control, .option])
        XCTAssertTrue(controller.setShortcut(custom, for: .trimClipboardAndRemoveLineBreaks))
        XCTAssertTrue(controller.setShortcut(.defaultTrimClipboardAndRemoveLineBreaks, for: .pasteTrimmed))

        let resetButton = controller.window?.contentView?.subviews.compactMap { $0 as? NSButton }.first {
            $0.title == "Reset" && $0.tag == PreferencesWindowController.ShortcutAction.trimClipboardAndRemoveLineBreaks.rawValue
        }
        XCTAssertNotNil(resetButton)
        resetButton?.performClick(nil)

        XCTAssertEqual(preferences.trimClipboardAndRemoveLineBreaksShortcut, custom)
        XCTAssertEqual(preferences.pasteTrimmedShortcut, .defaultTrimClipboardAndRemoveLineBreaks)
        XCTAssertEqual(changeCount, 2)
    }

    func testResetRestoresOnlySelectedShortcut() {
        let custom = KeyboardShortcut(keyCode: 8, modifiers: [.control, .option])
        preferences.trimClipboardAndRemoveLineBreaksShortcut = custom
        preferences.pasteTrimmedShortcut = KeyboardShortcut(keyCode: 9, modifiers: [.control, .option])

        let resetButton = controller.window?.contentView?.subviews.compactMap { $0 as? NSButton }.first {
            $0.title == "Reset" && $0.tag == PreferencesWindowController.ShortcutAction.trimClipboardAndRemoveLineBreaks.rawValue
        }
        XCTAssertNotNil(resetButton)
        resetButton?.performClick(nil)

        XCTAssertEqual(preferences.trimClipboardAndRemoveLineBreaksShortcut, .defaultTrimClipboardAndRemoveLineBreaks)
        XCTAssertEqual(preferences.pasteTrimmedShortcut, KeyboardShortcut(keyCode: 9, modifiers: [.control, .option]))
        XCTAssertEqual(changeCount, 1)
    }

    func testLeavingPreferencesCancelsRecordingAndResumesHotKeys() throws {
        let button = try clipboardShortcutButton()
        button.performClick(nil)
        XCTAssertEqual(recordingChanges, [true])

        controller.windowDidResignKey(Notification(name: NSWindow.didResignKeyNotification))
        controller.windowWillClose(Notification(name: NSWindow.willCloseNotification))

        XCTAssertEqual(recordingChanges, [true, false])
        XCTAssertEqual(button.title, KeyboardShortcut.defaultTrimClipboardAndRemoveLineBreaks.displayString)
        XCTAssertEqual(changeCount, 0)
    }

    func testAcceptingRecordedShortcutSavesBeforeResumingHotKeys() throws {
        let button = try clipboardShortcutButton()
        button.performClick(nil)
        let custom = KeyboardShortcut(keyCode: 8, modifiers: [.control, .option])

        XCTAssertTrue(controller.setShortcut(custom, for: .trimClipboardAndRemoveLineBreaks))

        XCTAssertEqual(recordingChanges, [true, false])
        XCTAssertEqual(shortcutsWhenRecordingEnded, [custom])
        XCTAssertEqual(button.title, custom.displayString)
        XCTAssertEqual(changeCount, 1)
    }

    private func clipboardShortcutButton() throws -> NSButton {
        try XCTUnwrap(controller.window?.contentView?.subviews.compactMap { $0 as? NSButton }.first {
            $0.title == preferences.trimClipboardAndRemoveLineBreaksShortcut.displayString
                && $0.tag == PreferencesWindowController.ShortcutAction.trimClipboardAndRemoveLineBreaks.rawValue
        })
    }
}

private struct StubAutoStartManager: AutoStartManaging {
    var isEnabled: Bool { false }
    func setEnabled(_ enabled: Bool) throws {}
}
