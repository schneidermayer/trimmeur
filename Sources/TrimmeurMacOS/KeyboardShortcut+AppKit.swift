import AppKit
import Carbon
import TrimmeurCore

extension KeyboardShortcut {
    init?(event: NSEvent) {
        let modifiers = ShortcutModifiers(cocoaFlags: event.modifierFlags)
        guard modifiers.contains(.command) || modifiers.contains(.option) || modifiers.contains(.control) else {
            return nil
        }

        let keyCode = UInt32(event.keyCode)
        guard !Self.modifierOnlyKeyCodes.contains(keyCode) else {
            return nil
        }

        self.init(keyCode: keyCode, modifiers: modifiers)
    }

    var carbonModifiers: UInt32 {
        modifiers.carbonModifiers
    }

    var cocoaModifierFlags: NSEvent.ModifierFlags {
        modifiers.cocoaModifierFlags
    }

    var menuKeyEquivalent: String {
        Self.menuKeyEquivalent(for: keyCode) ?? ""
    }

    private static let modifierOnlyKeyCodes: Set<UInt32> = [
        54, 55, 56, 57, 58, 59, 60, 61, 62,
    ]
}

extension ShortcutModifiers {
    init(cocoaFlags: NSEvent.ModifierFlags) {
        var modifiers: ShortcutModifiers = []
        if cocoaFlags.contains(.command) { modifiers.insert(.command) }
        if cocoaFlags.contains(.option) { modifiers.insert(.option) }
        if cocoaFlags.contains(.control) { modifiers.insert(.control) }
        if cocoaFlags.contains(.shift) { modifiers.insert(.shift) }
        self = modifiers
    }

    var cocoaModifierFlags: NSEvent.ModifierFlags {
        var flags: NSEvent.ModifierFlags = []
        if contains(.command) { flags.insert(.command) }
        if contains(.option) { flags.insert(.option) }
        if contains(.control) { flags.insert(.control) }
        if contains(.shift) { flags.insert(.shift) }
        return flags
    }

    var carbonModifiers: UInt32 {
        var flags = UInt32(0)
        if contains(.command) { flags |= UInt32(cmdKey) }
        if contains(.option) { flags |= UInt32(optionKey) }
        if contains(.control) { flags |= UInt32(controlKey) }
        if contains(.shift) { flags |= UInt32(shiftKey) }
        return flags
    }
}
