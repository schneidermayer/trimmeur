import Carbon
import Foundation

final class GlobalHotKey {
    enum RegistrationError: LocalizedError {
        case couldNotInstallHandler(OSStatus)
        case couldNotRegisterHotKey(OSStatus)

        var errorDescription: String? {
            switch self {
            case .couldNotInstallHandler(let status):
                return "InstallEventHandler failed with status \(status)."
            case .couldNotRegisterHotKey(let status):
                return "RegisterEventHotKey failed with status \(status). Another app may already use this shortcut."
            }
        }
    }

    typealias Handler = () -> Void

    private let signature = OSType(0x54524D52) // TRMR
    private let hotKeyIdentifier = UInt32(1)
    private var hotKeyRef: EventHotKeyRef?
    private var eventHandlerRef: EventHandlerRef?
    private var handler: Handler?

    deinit {
        unregister()
    }

    func register(handler: @escaping Handler) throws {
        unregister()
        self.handler = handler

        var eventSpec = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: OSType(kEventHotKeyPressed)
        )

        let handlerStatus = InstallEventHandler(
            GetApplicationEventTarget(),
            { _, event, userData in
                guard let event, let userData else { return noErr }

                let hotKey = Unmanaged<GlobalHotKey>.fromOpaque(userData).takeUnretainedValue()
                var eventHotKeyID = EventHotKeyID()
                let status = GetEventParameter(
                    event,
                    EventParamName(kEventParamDirectObject),
                    EventParamType(typeEventHotKeyID),
                    nil,
                    MemoryLayout<EventHotKeyID>.size,
                    nil,
                    &eventHotKeyID
                )

                guard status == noErr else { return status }
                guard eventHotKeyID.signature == hotKey.signature,
                      eventHotKeyID.id == hotKey.hotKeyIdentifier else {
                    return noErr
                }

                hotKey.handler?()
                return noErr
            },
            1,
            &eventSpec,
            Unmanaged.passUnretained(self).toOpaque(),
            &eventHandlerRef
        )

        guard handlerStatus == noErr else {
            throw RegistrationError.couldNotInstallHandler(handlerStatus)
        }

        let hotKeyID = EventHotKeyID(signature: signature, id: hotKeyIdentifier)
        let registerStatus = RegisterEventHotKey(
            UInt32(kVK_ANSI_T),
            UInt32(cmdKey | optionKey),
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )

        guard registerStatus == noErr else {
            unregister()
            throw RegistrationError.couldNotRegisterHotKey(registerStatus)
        }
    }

    func unregister() {
        if let hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
        }

        if let eventHandlerRef {
            RemoveEventHandler(eventHandlerRef)
        }

        hotKeyRef = nil
        eventHandlerRef = nil
        handler = nil
    }
}
