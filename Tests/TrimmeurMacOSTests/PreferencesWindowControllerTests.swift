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
                    self.shortcutsWhenRecordingEnded.append(self.preferences.pasteWithoutLineBreaksShortcut)
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

    func testChangingPasteWithoutLineBreaksShortcutPreservesPasteShortcutAndNotifiesApp() {
        let custom = KeyboardShortcut(keyCode: 8, modifiers: [.control, .option])

        XCTAssertTrue(controller.setShortcut(custom, for: .pasteWithoutLineBreaks))

        XCTAssertEqual(preferences.pasteWithoutLineBreaksShortcut, custom)
        XCTAssertEqual(preferences.pasteTrimmedShortcut, .defaultPasteTrimmed)
        XCTAssertEqual(changeCount, 1)
    }

    func testBothActionsRejectShortcutAlreadyUsedByOtherAction() {
        XCTAssertFalse(controller.setShortcut(.defaultPasteTrimmed, for: .pasteWithoutLineBreaks))
        XCTAssertFalse(controller.setShortcut(.defaultPasteWithoutLineBreaks, for: .pasteTrimmed))

        XCTAssertEqual(preferences.pasteTrimmedShortcut, .defaultPasteTrimmed)
        XCTAssertEqual(preferences.pasteWithoutLineBreaksShortcut, .defaultPasteWithoutLineBreaks)
        XCTAssertEqual(changeCount, 0)
    }

    func testResetCannotTakeShortcutAssignedToOtherAction() {
        let custom = KeyboardShortcut(keyCode: 8, modifiers: [.control, .option])
        XCTAssertTrue(controller.setShortcut(custom, for: .pasteWithoutLineBreaks))
        XCTAssertTrue(controller.setShortcut(.defaultPasteWithoutLineBreaks, for: .pasteTrimmed))

        let resetButton = controller.window?.contentView?.subviews.compactMap { $0 as? NSButton }.first {
            $0.title == "Reset" && $0.tag == PreferencesWindowController.ShortcutAction.pasteWithoutLineBreaks.rawValue
        }
        XCTAssertNotNil(resetButton)
        resetButton?.performClick(nil)

        XCTAssertEqual(preferences.pasteWithoutLineBreaksShortcut, custom)
        XCTAssertEqual(preferences.pasteTrimmedShortcut, .defaultPasteWithoutLineBreaks)
        XCTAssertEqual(changeCount, 2)
    }

    func testResetRestoresOnlySelectedShortcut() {
        let custom = KeyboardShortcut(keyCode: 8, modifiers: [.control, .option])
        preferences.pasteWithoutLineBreaksShortcut = custom
        preferences.pasteTrimmedShortcut = KeyboardShortcut(keyCode: 9, modifiers: [.control, .option])

        let resetButton = controller.window?.contentView?.subviews.compactMap { $0 as? NSButton }.first {
            $0.title == "Reset" && $0.tag == PreferencesWindowController.ShortcutAction.pasteWithoutLineBreaks.rawValue
        }
        XCTAssertNotNil(resetButton)
        resetButton?.performClick(nil)

        XCTAssertEqual(preferences.pasteWithoutLineBreaksShortcut, .defaultPasteWithoutLineBreaks)
        XCTAssertEqual(preferences.pasteTrimmedShortcut, KeyboardShortcut(keyCode: 9, modifiers: [.control, .option]))
        XCTAssertEqual(changeCount, 1)
    }

    func testLeavingPreferencesCancelsRecordingAndResumesHotKeys() throws {
        let button = try pasteWithoutLineBreaksShortcutButton()
        button.performClick(nil)
        XCTAssertEqual(recordingChanges, [true])

        controller.windowDidResignKey(Notification(name: NSWindow.didResignKeyNotification))
        controller.windowWillClose(Notification(name: NSWindow.willCloseNotification))

        XCTAssertEqual(recordingChanges, [true, false])
        XCTAssertEqual(button.title, KeyboardShortcut.defaultPasteWithoutLineBreaks.displayString)
        XCTAssertEqual(changeCount, 0)
    }

    func testAcceptingRecordedShortcutSavesBeforeResumingHotKeys() throws {
        let button = try pasteWithoutLineBreaksShortcutButton()
        button.performClick(nil)
        let custom = KeyboardShortcut(keyCode: 8, modifiers: [.control, .option])

        XCTAssertTrue(controller.setShortcut(custom, for: .pasteWithoutLineBreaks))

        XCTAssertEqual(recordingChanges, [true, false])
        XCTAssertEqual(shortcutsWhenRecordingEnded, [custom])
        XCTAssertEqual(button.title, custom.displayString)
        XCTAssertEqual(changeCount, 1)
    }

    func testPasteLowercaseDisplaysNoShortcutByDefault() throws {
        let button = try pasteLowercaseShortcutButton()

        XCTAssertNil(preferences.pasteLowercaseShortcut)
        XCTAssertEqual(button.title, "No Shortcut")
        XCTAssertNotNil(controller.window?.contentView?.subviews.compactMap { $0 as? NSTextField }.first {
            $0.stringValue == "Paste Lowercase"
        })
    }

    func testAssigningPasteLowercaseShortcutPreservesOtherShortcutsAndUpdatesButton() throws {
        let custom = KeyboardShortcut(keyCode: 8, modifiers: [.control, .option])
        let button = try pasteLowercaseShortcutButton()
        button.performClick(nil)

        XCTAssertTrue(controller.setShortcut(custom, for: .pasteLowercase))

        XCTAssertEqual(preferences.pasteLowercaseShortcut, custom)
        XCTAssertEqual(preferences.pasteTrimmedShortcut, .defaultPasteTrimmed)
        XCTAssertEqual(preferences.pasteWithoutLineBreaksShortcut, .defaultPasteWithoutLineBreaks)
        XCTAssertEqual(button.title, custom.displayString)
        XCTAssertEqual(changeCount, 1)
        XCTAssertEqual(recordingChanges, [true, false])
    }

    func testPasteLowercaseRejectsBothExistingShortcuts() {
        XCTAssertFalse(controller.setShortcut(.defaultPasteTrimmed, for: .pasteLowercase))
        XCTAssertFalse(controller.setShortcut(.defaultPasteWithoutLineBreaks, for: .pasteLowercase))

        XCTAssertNil(preferences.pasteLowercaseShortcut)
        XCTAssertEqual(changeCount, 0)
    }

    func testBothExistingActionsRejectPasteLowercaseShortcut() {
        let custom = KeyboardShortcut(keyCode: 8, modifiers: [.control, .option])
        XCTAssertTrue(controller.setShortcut(custom, for: .pasteLowercase))

        XCTAssertFalse(controller.setShortcut(custom, for: .pasteTrimmed))
        XCTAssertFalse(controller.setShortcut(custom, for: .pasteWithoutLineBreaks))

        XCTAssertEqual(preferences.pasteLowercaseShortcut, custom)
        XCTAssertEqual(preferences.pasteTrimmedShortcut, .defaultPasteTrimmed)
        XCTAssertEqual(preferences.pasteWithoutLineBreaksShortcut, .defaultPasteWithoutLineBreaks)
        XCTAssertEqual(changeCount, 1)
    }

    func testResetCannotTakeShortcutAssignedToPasteLowercase() throws {
        let custom = KeyboardShortcut(keyCode: 8, modifiers: [.control, .option])
        XCTAssertTrue(controller.setShortcut(custom, for: .pasteTrimmed))
        XCTAssertTrue(controller.setShortcut(.defaultPasteTrimmed, for: .pasteLowercase))
        let resetButton = try XCTUnwrap(controller.window?.contentView?.subviews.compactMap { $0 as? NSButton }.first {
            $0.title == "Reset" && $0.tag == PreferencesWindowController.ShortcutAction.pasteTrimmed.rawValue
        })

        resetButton.performClick(nil)

        XCTAssertEqual(preferences.pasteTrimmedShortcut, custom)
        XCTAssertEqual(preferences.pasteLowercaseShortcut, .defaultPasteTrimmed)
        XCTAssertEqual(changeCount, 2)
    }

    func testClearingPasteLowercaseShortcutRemovesAssignmentAndResumesHotKeys() throws {
        let custom = KeyboardShortcut(keyCode: 8, modifiers: [.control, .option])
        XCTAssertTrue(controller.setShortcut(custom, for: .pasteLowercase))
        let shortcutButton = try pasteLowercaseShortcutButton()
        shortcutButton.performClick(nil)
        let clearButton = try XCTUnwrap(controller.window?.contentView?.subviews.compactMap { $0 as? NSButton }.first {
            $0.title == "Clear" && $0.tag == PreferencesWindowController.ShortcutAction.pasteLowercase.rawValue
        })

        clearButton.performClick(nil)

        XCTAssertNil(TrimmeurPreferences(userDefaults: userDefaults).pasteLowercaseShortcut)
        XCTAssertEqual(preferences.pasteTrimmedShortcut, .defaultPasteTrimmed)
        XCTAssertEqual(preferences.pasteWithoutLineBreaksShortcut, .defaultPasteWithoutLineBreaks)
        XCTAssertEqual(shortcutButton.title, "No Shortcut")
        XCTAssertEqual(changeCount, 2)
        XCTAssertEqual(recordingChanges, [true, false])
        XCTAssertTrue(controller.setShortcut(custom, for: .pasteTrimmed))
    }

    func testCancelingPasteLowercaseRecordingLeavesItUnassigned() throws {
        let button = try pasteLowercaseShortcutButton()
        button.performClick(nil)

        controller.windowDidResignKey(Notification(name: NSWindow.didResignKeyNotification))

        XCTAssertNil(preferences.pasteLowercaseShortcut)
        XCTAssertEqual(button.title, "No Shortcut")
        XCTAssertEqual(recordingChanges, [true, false])
        XCTAssertEqual(changeCount, 0)
    }

    private func pasteLowercaseShortcutButton() throws -> NSButton {
        try XCTUnwrap(controller.window?.contentView?.subviews.compactMap { $0 as? NSButton }.first {
            $0.title != "Clear" && $0.tag == PreferencesWindowController.ShortcutAction.pasteLowercase.rawValue
        })
    }

    private func pasteWithoutLineBreaksShortcutButton() throws -> NSButton {
        try XCTUnwrap(controller.window?.contentView?.subviews.compactMap { $0 as? NSButton }.first {
            $0.title == preferences.pasteWithoutLineBreaksShortcut.displayString
                && $0.tag == PreferencesWindowController.ShortcutAction.pasteWithoutLineBreaks.rawValue
        })
    }
}

private struct StubAutoStartManager: AutoStartManaging {
    var isEnabled: Bool { false }
    func setEnabled(_ enabled: Bool) throws {}
}
