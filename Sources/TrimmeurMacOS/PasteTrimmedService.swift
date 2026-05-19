import AppKit
import TrimmeurCore

final class PasteTrimmedService {
    enum PasteResult: Equatable {
        case pasted
        case clipboardHasNoString
        case couldNotCreatePasteEvent
    }

    private let pasteboard: NSPasteboard
    private let pasteEventSender: PasteEventSender
    private let restoreDelay: TimeInterval

    init(
        pasteboard: NSPasteboard = .general,
        pasteEventSender: PasteEventSender = SystemPasteEventSender(),
        restoreDelay: TimeInterval = 0.8
    ) {
        self.pasteboard = pasteboard
        self.pasteEventSender = pasteEventSender
        self.restoreDelay = restoreDelay
    }

    func pasteTrimmedClipboard() -> PasteResult {
        guard let clipboardText = pasteboard.string(forType: .string) else {
            return .clipboardHasNoString
        }

        let snapshot = PasteboardSnapshot.capture(from: pasteboard)
        let trimmedText = TextTrimmer.removingIndentation(from: clipboardText)

        pasteboard.clearContents()
        pasteboard.setString(trimmedText, forType: .string)
        let trimmedChangeCount = pasteboard.changeCount

        guard pasteEventSender.sendPaste() else {
            restore(snapshot: snapshot, expectedChangeCount: trimmedChangeCount)
            return .couldNotCreatePasteEvent
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + restoreDelay) { [weak self] in
            self?.restore(snapshot: snapshot, expectedChangeCount: trimmedChangeCount)
        }

        return .pasted
    }

    private func restore(snapshot: PasteboardSnapshot, expectedChangeCount: Int) {
        guard pasteboard.changeCount == expectedChangeCount else {
            return
        }

        pasteboard.clearContents()
        pasteboard.writeObjects(snapshot.items)
    }
}

protocol PasteEventSender {
    func sendPaste() -> Bool
}

struct SystemPasteEventSender: PasteEventSender {
    func sendPaste() -> Bool {
        let keyCodeForV: CGKeyCode = 9

        guard let keyDown = CGEvent(keyboardEventSource: nil, virtualKey: keyCodeForV, keyDown: true),
              let keyUp = CGEvent(keyboardEventSource: nil, virtualKey: keyCodeForV, keyDown: false) else {
            return false
        }

        keyDown.flags = .maskCommand
        keyUp.flags = .maskCommand
        keyDown.post(tap: .cghidEventTap)
        keyUp.post(tap: .cghidEventTap)
        return true
    }
}

struct PasteboardSnapshot {
    let items: [NSPasteboardItem]

    static func capture(from pasteboard: NSPasteboard) -> PasteboardSnapshot {
        let items: [NSPasteboardItem] = pasteboard.pasteboardItems?.map { sourceItem in
            let item = NSPasteboardItem()
            for type in sourceItem.types {
                if let data = sourceItem.data(forType: type) {
                    item.setData(data, forType: type)
                }
            }
            return item
        } ?? []

        return PasteboardSnapshot(items: items)
    }
}
