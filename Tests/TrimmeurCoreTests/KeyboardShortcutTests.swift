import XCTest
@testable import TrimmeurCore

final class KeyboardShortcutTests: XCTestCase {
    func testDefaultPasteTrimmedShortcutIsOptionCommandT() {
        let shortcut = KeyboardShortcut.defaultPasteTrimmed

        XCTAssertEqual(shortcut.keyCode, 17)
        XCTAssertEqual(shortcut.modifiers, [.option, .command])
        XCTAssertEqual(shortcut.displayString, "⌥⌘T")
        XCTAssertEqual(shortcut.readableString, "Option-Command-T")
        XCTAssertEqual(KeyboardShortcut.menuKeyEquivalent(for: shortcut.keyCode), "t")
    }

    func testUnknownKeyCodeStillHasReadableDisplay() {
        let shortcut = KeyboardShortcut(keyCode: 999, modifiers: [.control, .shift])

        XCTAssertEqual(shortcut.displayString, "⌃⇧Key 999")
        XCTAssertEqual(shortcut.readableString, "Control-Shift-Key 999")
        XCTAssertNil(KeyboardShortcut.menuKeyEquivalent(for: shortcut.keyCode))
    }
}
