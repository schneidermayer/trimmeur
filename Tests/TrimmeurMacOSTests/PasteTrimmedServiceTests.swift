import AppKit
import XCTest
@testable import TrimmeurMacOS

final class PasteTrimmedServiceTests: XCTestCase {
    private var pasteboard: NSPasteboard!
    private var pasteEventSender: StubPasteEventSender!
    private var service: PasteTrimmedService!

    override func setUp() {
        super.setUp()
        pasteboard = NSPasteboard(name: NSPasteboard.Name("TrimmeurTests.\(UUID().uuidString)"))
        pasteboard.clearContents()
        pasteEventSender = StubPasteEventSender()
        service = PasteTrimmedService(
            pasteboard: pasteboard,
            pasteEventSender: pasteEventSender,
            restoreDelay: 0
        )
    }

    override func tearDown() {
        service = nil
        pasteEventSender = nil
        pasteboard.releaseGlobally()
        pasteboard = nil
        super.tearDown()
    }

    func testPasteLowercasePreservesWhitespaceAndRestoresOriginalFormatting() {
        let original = " \tHELLO ÄÖÜ STRAẞE\r\n  CAFÉ Ελληνικά\n\tПРИВЕТ 👋\u{00A0}\u{2028}WORLD  "
        let expectedPaste = " \thello äöü straße\r\n  café ελληνικά\n\tпривет 👋\u{00A0}\u{2028}world  "
        setTextWithFormatting(original)
        let originalFormatting = pasteboard.data(forType: .rtf)
        let pasteboard = self.pasteboard!
        pasteEventSender.onSendPaste = {
            XCTAssertEqual(pasteboard.string(forType: .string), expectedPaste)
            XCTAssertNil(pasteboard.data(forType: .rtf))
        }

        XCTAssertEqual(service.pasteLowercaseClipboard(), .pasted)
        XCTAssertEqual(pasteboard.string(forType: .string), expectedPaste)
        XCTAssertEqual(pasteEventSender.sendCount, 1)

        waitForPendingMainQueueWork()

        XCTAssertEqual(pasteboard.string(forType: .string), original)
        XCTAssertEqual(pasteboard.data(forType: .rtf), originalFormatting)
        XCTAssertEqual(pasteEventSender.sendCount, 1)
    }

    func testPasteLowercasePreservesNonTextClipboardContents() {
        let originalData = Data([0x01, 0x02, 0x03])
        XCTAssertTrue(pasteboard.setData(originalData, forType: .png))
        let originalChangeCount = pasteboard.changeCount

        XCTAssertEqual(service.pasteLowercaseClipboard(), .clipboardHasNoString)

        XCTAssertEqual(pasteboard.data(forType: .png), originalData)
        XCTAssertEqual(pasteboard.changeCount, originalChangeCount)
        XCTAssertEqual(pasteEventSender.sendCount, 0)
    }

    func testPasteLowercaseRestoresOriginalFormattingWhenPasteEventFails() {
        let original = "  ORIGINAL\n\tTEXT"
        setTextWithFormatting(original)
        let originalFormatting = pasteboard.data(forType: .rtf)
        pasteEventSender.shouldSendPaste = false

        XCTAssertEqual(service.pasteLowercaseClipboard(), .couldNotCreatePasteEvent)

        XCTAssertEqual(pasteboard.string(forType: .string), original)
        XCTAssertEqual(pasteboard.data(forType: .rtf), originalFormatting)
        XCTAssertEqual(pasteEventSender.sendCount, 1)
    }

    func testPendingPasteLowercaseRestorationPreservesNewerClipboardContents() {
        setTextWithFormatting("  ORIGINAL\n\tTEXT")
        XCTAssertEqual(service.pasteLowercaseClipboard(), .pasted)

        pasteboard.clearContents()
        let newerText = "  NEWER COPY\n\tWITH UPPERCASE"
        setTextWithFormatting(newerText)
        let newerFormatting = pasteboard.data(forType: .rtf)
        let newerChangeCount = pasteboard.changeCount

        waitForPendingMainQueueWork()

        XCTAssertEqual(pasteboard.string(forType: .string), newerText)
        XCTAssertEqual(pasteboard.data(forType: .rtf), newerFormatting)
        XCTAssertEqual(pasteboard.changeCount, newerChangeCount)
        XCTAssertEqual(pasteEventSender.sendCount, 1)
    }

    func testPasteWithoutLineBreaksPreservesOtherWhitespaceAndRestoresOriginalFormatting() {
        let original = " \tfirst  \n\tsecond\r\n  third\rfourth\u{000B}\tfifth\u{000C} sixth\u{0085}\u{00A0}seventh\u{2028} eighth\u{2029}  "
        let expectedPaste = " \tfirst  \tsecond  thirdfourth\tfifth sixth\u{00A0}seventh eighth  "
        setTextWithFormatting(original)
        let originalFormatting = pasteboard.data(forType: .rtf)
        let pasteboard = self.pasteboard!
        pasteEventSender.onSendPaste = {
            XCTAssertEqual(pasteboard.string(forType: .string), expectedPaste)
            XCTAssertNil(pasteboard.data(forType: .rtf))
        }

        XCTAssertEqual(service.pasteWithoutLineBreaksClipboard(), .pasted)
        XCTAssertEqual(pasteboard.string(forType: .string), expectedPaste)
        XCTAssertEqual(pasteEventSender.sendCount, 1)

        waitForPendingMainQueueWork()

        XCTAssertEqual(pasteboard.string(forType: .string), original)
        XCTAssertEqual(pasteboard.data(forType: .rtf), originalFormatting)
        XCTAssertEqual(pasteEventSender.sendCount, 1)
    }

    func testPasteWithoutLineBreaksCollapsesJoinedSpacesAndRestoresOriginalFormatting() {
        let original = "first  value  \r\n   second \n \n third  value"
        let expectedPaste = "first  value second third  value"
        setTextWithFormatting(original)
        let originalFormatting = pasteboard.data(forType: .rtf)
        let pasteboard = self.pasteboard!
        pasteEventSender.onSendPaste = {
            XCTAssertEqual(pasteboard.string(forType: .string), expectedPaste)
            XCTAssertNil(pasteboard.data(forType: .rtf))
        }

        XCTAssertEqual(service.pasteWithoutLineBreaksClipboard(), .pasted)
        XCTAssertEqual(pasteboard.string(forType: .string), expectedPaste)
        XCTAssertEqual(pasteEventSender.sendCount, 1)

        waitForPendingMainQueueWork()

        XCTAssertEqual(pasteboard.string(forType: .string), original)
        XCTAssertEqual(pasteboard.data(forType: .rtf), originalFormatting)
        XCTAssertEqual(pasteEventSender.sendCount, 1)
    }

    func testPendingPasteWithoutLineBreaksRestorationPreservesNewerClipboardContents() {
        setTextWithFormatting("  original\n\ttext")
        XCTAssertEqual(service.pasteWithoutLineBreaksClipboard(), .pasted)

        pasteboard.clearContents()
        let newerText = "  newer copy\n\twith line breaks"
        setTextWithFormatting(newerText)
        let newerFormatting = pasteboard.data(forType: .rtf)
        let newerChangeCount = pasteboard.changeCount

        waitForPendingMainQueueWork()

        XCTAssertEqual(pasteboard.string(forType: .string), newerText)
        XCTAssertEqual(pasteboard.data(forType: .rtf), newerFormatting)
        XCTAssertEqual(pasteboard.changeCount, newerChangeCount)
        XCTAssertEqual(pasteEventSender.sendCount, 1)
    }

    func testTrimClipboardKeepsLineBreaksAndWritesPlainTextWithoutPastingOrRestoring() {
        setTextWithFormatting("  first  \n\tsecond\r\n")

        XCTAssertEqual(service.trimClipboard(), .updated)
        XCTAssertEqual(pasteboard.string(forType: .string), "first  \nsecond\r\n")
        XCTAssertNil(pasteboard.data(forType: .rtf))
        XCTAssertEqual(pasteEventSender.sendCount, 0)

        waitForPendingMainQueueWork()
        XCTAssertEqual(pasteboard.string(forType: .string), "first  \nsecond\r\n")
    }

    func testTrimClipboardAndRemoveLineBreaksWritesPlainTextWithoutPastingOrRestoring() {
        setTextWithFormatting("  first \n\tsecond\r\n  third\u{2028}")

        XCTAssertEqual(service.trimClipboardAndRemoveLineBreaks(), .updated)
        XCTAssertEqual(pasteboard.string(forType: .string), "first secondthird")
        XCTAssertNil(pasteboard.data(forType: .rtf))
        XCTAssertEqual(pasteEventSender.sendCount, 0)

        waitForPendingMainQueueWork()
        XCTAssertEqual(pasteboard.string(forType: .string), "first secondthird")
    }

    func testClipboardActionsPreserveNonTextClipboardContents() {
        let originalData = Data([0x01, 0x02, 0x03])
        XCTAssertTrue(pasteboard.setData(originalData, forType: .png))
        let originalChangeCount = pasteboard.changeCount

        XCTAssertEqual(service.trimClipboard(), .clipboardHasNoString)
        XCTAssertEqual(service.trimClipboardAndRemoveLineBreaks(), .clipboardHasNoString)

        XCTAssertEqual(pasteboard.data(forType: .png), originalData)
        XCTAssertEqual(pasteboard.changeCount, originalChangeCount)
        XCTAssertEqual(pasteEventSender.sendCount, 0)
    }

    func testPendingPasteRestorationDoesNotUndoTrimClipboard() {
        XCTAssertTrue(pasteboard.setString("  first\n  second", forType: .string))
        XCTAssertEqual(service.pasteTrimmedClipboard(), .pasted)

        XCTAssertEqual(service.trimClipboard(), .updated)
        waitForPendingMainQueueWork()

        XCTAssertEqual(pasteboard.string(forType: .string), "first\nsecond")
        XCTAssertEqual(pasteEventSender.sendCount, 1)
    }

    func testPendingPasteRestorationDoesNotUndoTrimClipboardAndRemoveLineBreaks() {
        XCTAssertTrue(pasteboard.setString("  first\n  second", forType: .string))
        XCTAssertEqual(service.pasteTrimmedClipboard(), .pasted)

        XCTAssertEqual(service.trimClipboardAndRemoveLineBreaks(), .updated)
        waitForPendingMainQueueWork()

        XCTAssertEqual(pasteboard.string(forType: .string), "firstsecond")
        XCTAssertEqual(pasteEventSender.sendCount, 1)
    }

    private func setTextWithFormatting(_ text: String) {
        let item = NSPasteboardItem()
        XCTAssertTrue(item.setString(text, forType: .string))
        XCTAssertTrue(item.setData(Data("{\\rtf1 formatted text}".utf8), forType: .rtf))
        XCTAssertTrue(pasteboard.writeObjects([item]))
    }

    private func waitForPendingMainQueueWork() {
        let completed = expectation(description: "Pending clipboard restoration has run")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
            completed.fulfill()
        }
        wait(for: [completed], timeout: 1)
    }
}

private final class StubPasteEventSender: PasteEventSender {
    private(set) var sendCount = 0
    var shouldSendPaste = true
    var onSendPaste: (() -> Void)?

    func sendPaste() -> Bool {
        sendCount += 1
        onSendPaste?()
        return shouldSendPaste
    }
}
