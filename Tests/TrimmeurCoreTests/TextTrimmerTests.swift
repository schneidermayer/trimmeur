import XCTest
@testable import TrimmeurCore

final class TextTrimmerTests: XCTestCase {
    func testRemovesSpacesFromEveryLineStart() {
        let input = "    one\n  two\nthree"

        XCTAssertEqual(TextTrimmer.removingIndentation(from: input), "one\ntwo\nthree")
    }

    func testRemovesTabsAndSpaces() {
        let input = "\t  first\n\t\tsecond"

        XCTAssertEqual(TextTrimmer.removingIndentation(from: input), "first\nsecond")
    }

    func testPreservesInternalAndTrailingWhitespace() {
        let input = "  let value = \"two words\"  \n    next  "

        XCTAssertEqual(TextTrimmer.removingIndentation(from: input), "let value = \"two words\"  \nnext  ")
    }

    func testPreservesBlankLinesAndFinalNewline() {
        let input = "  first\n    \n  second\n"

        XCTAssertEqual(TextTrimmer.removingIndentation(from: input), "first\n\nsecond\n")
    }

    func testHandlesCRLFLineEndings() {
        let input = "  first\r\n\tsecond\r\n"

        XCTAssertEqual(TextTrimmer.removingIndentation(from: input), "first\r\nsecond\r\n")
    }

    func testWhitespaceOnlyInputBecomesEmpty() {
        XCTAssertEqual(TextTrimmer.removingIndentation(from: " \t  "), "")
    }
}
