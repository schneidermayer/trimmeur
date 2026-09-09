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

    func testRemovingLineBreaksHandlesEmptyInput() {
        XCTAssertEqual(TextTrimmer.removingLineBreaks(from: ""), "")
    }

    func testRemovingLineBreaksJoinsLinesWithoutAddingSpaces() {
        XCTAssertEqual(TextTrimmer.removingLineBreaks(from: "one\ntwo\rthree\r\nfour"), "onetwothreefour")
    }

    func testRemovingLineBreaksRemovesRepeatedAndBoundaryBreaks() {
        let input = "\r\n\none\n\n\r\ntwo\r\n\n"

        XCTAssertEqual(TextTrimmer.removingLineBreaks(from: input), "onetwo")
    }

    func testRemovingLineBreaksRemovesAllUnicodeNewlineCharacters() {
        let lineBreaks = ["\n", "\r", "\r\n", "\u{000B}", "\u{000C}", "\u{0085}", "\u{2028}", "\u{2029}"]

        for lineBreak in lineBreaks {
            XCTAssertEqual(TextTrimmer.removingLineBreaks(from: "before\(lineBreak)after"), "beforeafter")
        }

        XCTAssertEqual(TextTrimmer.removingLineBreaks(from: lineBreaks.joined()), "")
    }

    func testRemovingLineBreaksPreservesOtherWhitespaceAndUnicode() {
        let input = " \tCaf\u{0065}\u{0301}\u{00A0}\n\t👩🏽‍💻\u{2003}\r\n  日本語\u{202F} "
        let expected = " \tCaf\u{0065}\u{0301}\u{00A0}\t👩🏽‍💻\u{2003}  日本語\u{202F} "

        XCTAssertEqual(TextTrimmer.removingLineBreaks(from: input), expected)
    }

    func testRemovingLineBreaksPreservesTextWithoutLineBreaks() {
        let input = " \tfirst  second\t "

        XCTAssertEqual(TextTrimmer.removingLineBreaks(from: input), input)
    }
}
