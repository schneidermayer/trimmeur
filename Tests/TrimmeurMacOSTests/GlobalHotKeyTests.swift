import Carbon
import TrimmeurCore
import XCTest
@testable import TrimmeurMacOS

final class GlobalHotKeyTests: XCTestCase {
    private let signature = OSType(0x54524D52) // TRMR
    private let firstShortcut = KeyboardShortcut(
        keyCode: UInt32(kVK_F18),
        modifiers: [.control, .option, .shift, .command]
    )
    private let secondShortcut = KeyboardShortcut(
        keyCode: UInt32(kVK_F19),
        modifiers: [.control, .option, .shift, .command]
    )

    func testEachHotKeyReceivesOnlyItsOwnEventsThroughTheHandlerChain() throws {
        let first = GlobalHotKey(identifier: 1)
        let second = GlobalHotKey(identifier: 2)
        defer {
            first.unregister()
            second.unregister()
        }
        var firstCount = 0
        var secondCount = 0
        try first.register(shortcut: firstShortcut) { firstCount += 1 }
        try second.register(shortcut: secondShortcut) { secondCount += 1 }

        XCTAssertEqual(try sendHotKeyEvent(identifier: 1), noErr)
        XCTAssertEqual(firstCount, 1)
        XCTAssertEqual(secondCount, 0)

        XCTAssertEqual(try sendHotKeyEvent(identifier: 2), noErr)
        XCTAssertEqual(firstCount, 1)
        XCTAssertEqual(secondCount, 1)

        XCTAssertEqual(try sendHotKeyEvent(identifier: 3), OSStatus(eventNotHandledErr))
        XCTAssertEqual(
            try sendHotKeyEvent(identifier: 1, signature: OSType(0x54455354)),
            OSStatus(eventNotHandledErr)
        )
        XCTAssertEqual(firstCount, 1)
        XCTAssertEqual(secondCount, 1)
    }

    func testUnregisteringOneHotKeyLeavesTheOtherRegistered() throws {
        let first = GlobalHotKey(identifier: 1)
        let second = GlobalHotKey(identifier: 2)
        defer {
            first.unregister()
            second.unregister()
        }
        var firstCount = 0
        var secondCount = 0
        try first.register(shortcut: firstShortcut) { firstCount += 1 }
        try second.register(shortcut: secondShortcut) { secondCount += 1 }

        second.unregister()

        XCTAssertEqual(try sendHotKeyEvent(identifier: 2), OSStatus(eventNotHandledErr))
        XCTAssertEqual(try sendHotKeyEvent(identifier: 1), noErr)
        XCTAssertEqual(firstCount, 1)
        XCTAssertEqual(secondCount, 0)
    }

    func testReregisteringHotKeyReplacesItsHandlerAndKeepsOtherActionWorking() throws {
        let first = GlobalHotKey(identifier: 1)
        let second = GlobalHotKey(identifier: 2)
        defer {
            first.unregister()
            second.unregister()
        }
        var originalCount = 0
        var replacementCount = 0
        var secondCount = 0
        try first.register(shortcut: firstShortcut) { originalCount += 1 }
        try second.register(shortcut: secondShortcut) { secondCount += 1 }

        try first.register(shortcut: firstShortcut) { replacementCount += 1 }

        XCTAssertEqual(try sendHotKeyEvent(identifier: 2), noErr)
        XCTAssertEqual(try sendHotKeyEvent(identifier: 1), noErr)
        XCTAssertEqual(originalCount, 0)
        XCTAssertEqual(replacementCount, 1)
        XCTAssertEqual(secondCount, 1)
    }

    // Dispatch only inside the test process; no keyboard input or clipboard access.
    private func sendHotKeyEvent(identifier: UInt32, signature: OSType? = nil) throws -> OSStatus {
        var event: EventRef?
        let createStatus = CreateEvent(
            nil,
            OSType(kEventClassKeyboard),
            UInt32(kEventHotKeyPressed),
            GetCurrentEventTime(),
            EventAttributes(kEventAttributeNone),
            &event
        )
        XCTAssertEqual(createStatus, noErr)
        let createdEvent = try XCTUnwrap(event)
        defer { ReleaseEvent(createdEvent) }

        var hotKeyID = EventHotKeyID(signature: signature ?? self.signature, id: identifier)
        XCTAssertEqual(
            SetEventParameter(
                createdEvent,
                EventParamName(kEventParamDirectObject),
                EventParamType(typeEventHotKeyID),
                MemoryLayout<EventHotKeyID>.size,
                &hotKeyID
            ),
            noErr
        )
        return SendEventToEventTarget(createdEvent, GetApplicationEventTarget())
    }
}
