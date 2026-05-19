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

            if scalar == "\n" || scalar == "\r" {
                isAtLineStart = true
            }
        }

        return result
    }
}

private extension Unicode.Scalar {
    var isIndentationScalar: Bool {
        self == " " || self == "\t"
    }
}
