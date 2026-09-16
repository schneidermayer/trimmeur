import AppKit
import TrimmeurCore
import XCTest
@testable import TrimmeurMacOS

final class AppDelegateTests: XCTestCase {
    func testUnassignedShortcutHasPlainTitleAndNoKeyEquivalent() {
        let item = NSMenuItem(title: "", action: nil, keyEquivalent: "")

        AppDelegate.configurePasteMenuItem(item, title: "Paste Lowercase", shortcut: nil)

        XCTAssertEqual(item.title, "Paste Lowercase")
        XCTAssertEqual(item.keyEquivalent, "")
        XCTAssertEqual(item.keyEquivalentModifierMask, [])
    }

    func testClearingAssignedShortcutRemovesMenuKeyEquivalent() {
        let item = NSMenuItem(title: "", action: nil, keyEquivalent: "")
        let shortcut = KeyboardShortcut(keyCode: 37, modifiers: [.option, .command])

        AppDelegate.configurePasteMenuItem(item, title: "Paste Lowercase", shortcut: shortcut)
        XCTAssertEqual(item.title, "Paste Lowercase")
        XCTAssertEqual(item.keyEquivalent, "l")
        XCTAssertEqual(item.keyEquivalentModifierMask, [.option, .command])

        AppDelegate.configurePasteMenuItem(item, title: "Paste Lowercase", shortcut: nil)
        XCTAssertEqual(item.title, "Paste Lowercase")
        XCTAssertEqual(item.keyEquivalent, "")
        XCTAssertEqual(item.keyEquivalentModifierMask, [])
    }

    func testUnsupportedMenuKeyEquivalentRemainsVisibleInTitle() {
        let item = NSMenuItem(title: "", action: nil, keyEquivalent: "")
        let shortcut = KeyboardShortcut(keyCode: 999, modifiers: [.control])

        AppDelegate.configurePasteMenuItem(item, title: "Paste Lowercase", shortcut: shortcut)

        XCTAssertEqual(item.title, "Paste Lowercase (\(shortcut.displayString))")
        XCTAssertEqual(item.keyEquivalent, "")
    }
}
