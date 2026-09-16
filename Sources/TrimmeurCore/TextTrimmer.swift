import Foundation

public enum TextTrimmer {
    public static func removingIndentation(from text: String) -> String {
        guard !text.isEmpty else { return text }

        var result = String()
        result.reserveCapacity(text.count)

        var isAtLineStart = true

        for scalar in text.unicodeScalars {
            if isAtLineStart {
                if scalar.isIndentationScalar {
                    continue
                }

                isAtLineStart = false
            }

            result.unicodeScalars.append(scalar)

            if CharacterSet.newlines.contains(scalar) {
                isAtLineStart = true
            }
        }

        return result
    }

    public static func removingLineBreaks(from text: String) -> String {
        var result = String()
        result.reserveCapacity(text.count)

        var pendingSpaceCount = 0
        var hasLineBreakAfterSpaces = false

        for scalar in text.unicodeScalars {
            if CharacterSet.newlines.contains(scalar) {
                hasLineBreakAfterSpaces = pendingSpaceCount > 0
                continue
            }

            if scalar == " " {
                // Collapse only space runs that meet across a removed line break.
                pendingSpaceCount = hasLineBreakAfterSpaces ? 1 : pendingSpaceCount + 1
                continue
            }

            result.append(String(repeating: " ", count: pendingSpaceCount))
            pendingSpaceCount = 0
            hasLineBreakAfterSpaces = false
            result.unicodeScalars.append(scalar)
        }

        result.append(String(repeating: " ", count: pendingSpaceCount))
        return result
    }

    public static func removingIndentationAndLineBreaks(from text: String) -> String {
        removingLineBreaks(from: removingIndentation(from: text))
    }
}

private extension Unicode.Scalar {
    var isIndentationScalar: Bool {
        self == " " || self == "\t"
    }
}
