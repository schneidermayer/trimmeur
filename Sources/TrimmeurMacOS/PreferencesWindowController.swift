import AppKit
import TrimmeurCore

final class PreferencesWindowController: NSWindowController, NSWindowDelegate {
    enum ShortcutAction: Int, CaseIterable {
        case pasteTrimmed
        case pasteWithoutLineBreaks
        case pasteLowercase

        var title: String {
            switch self {
            case .pasteTrimmed: return "Paste Trimmed"
            case .pasteWithoutLineBreaks: return "Paste Without Line Breaks"
            case .pasteLowercase: return "Paste Lowercase"
            }
        }

        var defaultShortcut: KeyboardShortcut? {
            switch self {
            case .pasteTrimmed: return .defaultPasteTrimmed
            case .pasteWithoutLineBreaks: return .defaultPasteWithoutLineBreaks
            case .pasteLowercase: return nil
            }
        }
    }

    private let preferences: TrimmeurPreferences
    private let autoStartManager: AutoStartManaging
    private let onShortcutChanged: () -> Void
    private let onShortcutRecordingChanged: (Bool) -> Void
    private var recordingMonitor: Any?
    private var recordingAction: ShortcutAction?

    private var shortcutButtons: [ShortcutAction: NSButton] = [:]
    private let startOnLoginCheckbox = NSButton(checkboxWithTitle: "Start on login", target: nil, action: nil)
    private let statusLabel = NSTextField(labelWithString: "")

    init(
        preferences: TrimmeurPreferences,
        autoStartManager: AutoStartManaging = AutoStartManager(),
        onShortcutChanged: @escaping () -> Void,
        onShortcutRecordingChanged: @escaping (Bool) -> Void = { _ in }
    ) {
        self.preferences = preferences
        self.autoStartManager = autoStartManager
        self.onShortcutChanged = onShortcutChanged
        self.onShortcutRecordingChanged = onShortcutRecordingChanged

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 460, height: 380),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "Trimmeur Preferences"
        window.isReleasedWhenClosed = false
        window.center()

        super.init(window: window)

        window.delegate = self
        buildContent()
        refresh()
    }

    required init?(coder: NSCoder) {
        nil
    }

    override func showWindow(_ sender: Any?) {
        refresh()
        super.showWindow(sender)
        window?.makeKeyAndOrderFront(sender)
        NSApp.activate(ignoringOtherApps: true)
    }

    func windowWillClose(_ notification: Notification) {
        stopRecording()
    }

    func windowDidResignKey(_ notification: Notification) {
        stopRecording()
    }

    private func buildContent() {
        guard let contentView = window?.contentView else { return }

        var previousButton: NSButton?
        for action in ShortcutAction.allCases {
            let titleLabel = NSTextField(labelWithString: action.title)
            titleLabel.font = .boldSystemFont(ofSize: 14)

            let shortcutTitleLabel = NSTextField(labelWithString: "Shortcut")
            shortcutTitleLabel.alignment = .right

            let shortcutButton = NSButton(title: "", target: self, action: #selector(beginRecording(_:)))
            shortcutButton.bezelStyle = .rounded
            shortcutButton.tag = action.rawValue
            shortcutButtons[action] = shortcutButton

            let resetButton = NSButton(
                title: action.defaultShortcut == nil ? "Clear" : "Reset",
                target: self,
                action: #selector(resetShortcut(_:))
            )
            resetButton.bezelStyle = .rounded
            resetButton.tag = action.rawValue

            for view in [titleLabel, shortcutTitleLabel, shortcutButton, resetButton] {
                view.translatesAutoresizingMaskIntoConstraints = false
                contentView.addSubview(view)
            }

            NSLayoutConstraint.activate([
                titleLabel.topAnchor.constraint(equalTo: previousButton?.bottomAnchor ?? contentView.topAnchor, constant: 22),
                titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
                titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -24),

                shortcutTitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 14),
                shortcutTitleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
                shortcutTitleLabel.widthAnchor.constraint(equalToConstant: 86),

                shortcutButton.centerYAnchor.constraint(equalTo: shortcutTitleLabel.centerYAnchor),
                shortcutButton.leadingAnchor.constraint(equalTo: shortcutTitleLabel.trailingAnchor, constant: 12),
                shortcutButton.widthAnchor.constraint(equalToConstant: 180),

                resetButton.centerYAnchor.constraint(equalTo: shortcutButton.centerYAnchor),
                resetButton.leadingAnchor.constraint(equalTo: shortcutButton.trailingAnchor, constant: 8),
                resetButton.widthAnchor.constraint(equalToConstant: 76),
            ])
            previousButton = shortcutButton
        }

        startOnLoginCheckbox.target = self
        startOnLoginCheckbox.action = #selector(toggleStartOnLogin)

        statusLabel.textColor = .secondaryLabelColor
        statusLabel.lineBreakMode = .byWordWrapping
        statusLabel.maximumNumberOfLines = 2

        let doneButton = NSButton(title: "Done", target: self, action: #selector(closeWindow))
        doneButton.bezelStyle = .rounded
        doneButton.keyEquivalent = "\r"

        for view in [startOnLoginCheckbox, statusLabel, doneButton] {
            view.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview(view)
        }

        NSLayoutConstraint.activate([
            startOnLoginCheckbox.topAnchor.constraint(equalTo: previousButton!.bottomAnchor, constant: 20),
            startOnLoginCheckbox.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 122),

            statusLabel.topAnchor.constraint(equalTo: startOnLoginCheckbox.bottomAnchor, constant: 14),
            statusLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            statusLabel.trailingAnchor.constraint(equalTo: doneButton.leadingAnchor, constant: -16),

            doneButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            doneButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -18),
            doneButton.widthAnchor.constraint(equalToConstant: 86),
        ])
    }

    private func refresh() {
        for (action, button) in shortcutButtons {
            button.title = action == recordingAction ? "Press shortcut..." : shortcut(for: action)?.displayString ?? "No Shortcut"
        }
        startOnLoginCheckbox.state = autoStartManager.isEnabled ? .on : .off
        if statusLabel.stringValue.isEmpty {
            statusLabel.stringValue = "Click the shortcut button, then press the new key combination."
        }
    }

    private func shortcut(for action: ShortcutAction) -> KeyboardShortcut? {
        switch action {
        case .pasteTrimmed: return preferences.pasteTrimmedShortcut
        case .pasteWithoutLineBreaks: return preferences.pasteWithoutLineBreaksShortcut
        case .pasteLowercase: return preferences.pasteLowercaseShortcut
        }
    }

    @objc private func beginRecording(_ sender: NSButton) {
        guard let action = ShortcutAction(rawValue: sender.tag) else { return }
        stopRecording()
        recordingAction = action
        onShortcutRecordingChanged(true)
        refresh()
        statusLabel.stringValue = "Press a key with Command, Option, or Control. Escape cancels."
        window?.makeFirstResponder(nil)

        recordingMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.handleShortcutEvent(event)
            return nil
        }
    }

    private func handleShortcutEvent(_ event: NSEvent) {
        guard let action = recordingAction else { return }
        if event.keyCode == 53 {
            stopRecording()
            statusLabel.stringValue = "Shortcut recording canceled."
            refresh()
            return
        }

        guard let shortcut = KeyboardShortcut(event: event) else {
            statusLabel.stringValue = "Use Command, Option, or Control with a non-modifier key."
            return
        }

        _ = setShortcut(shortcut, for: action)
    }

    @discardableResult
    func setShortcut(_ shortcut: KeyboardShortcut, for action: ShortcutAction) -> Bool {
        if let conflictingAction = ShortcutAction.allCases.first(where: {
            $0 != action && shortcut == self.shortcut(for: $0)
        }) {
            statusLabel.stringValue = "Already used by \(conflictingAction.title). Choose another shortcut."
            return false
        }

        switch action {
        case .pasteTrimmed: preferences.pasteTrimmedShortcut = shortcut
        case .pasteWithoutLineBreaks: preferences.pasteWithoutLineBreaksShortcut = shortcut
        case .pasteLowercase: preferences.pasteLowercaseShortcut = shortcut
        }
        statusLabel.stringValue = "Shortcut set to \(shortcut.readableString)."
        refresh()
        onShortcutChanged()
        stopRecording()
        return true
    }

    private func stopRecording() {
        if let recordingMonitor {
            NSEvent.removeMonitor(recordingMonitor)
        }
        recordingMonitor = nil
        if recordingAction != nil {
            recordingAction = nil
            refresh()
            onShortcutRecordingChanged(false)
        }
    }

    @objc private func resetShortcut(_ sender: NSButton) {
        guard let action = ShortcutAction(rawValue: sender.tag) else { return }
        if let defaultShortcut = action.defaultShortcut {
            guard setShortcut(defaultShortcut, for: action) else { return }
            statusLabel.stringValue = "Shortcut reset to \(defaultShortcut.readableString)."
        } else {
            preferences.pasteLowercaseShortcut = nil
            statusLabel.stringValue = "Shortcut cleared."
            refresh()
            onShortcutChanged()
            stopRecording()
        }
    }

    @objc private func toggleStartOnLogin() {
        let shouldEnable = startOnLoginCheckbox.state == .on

        do {
            try autoStartManager.setEnabled(shouldEnable)
            preferences.startOnLogin = shouldEnable
            statusLabel.stringValue = shouldEnable ? "Trimmeur will start on login." : "Trimmeur will not start on login."
            refresh()
        } catch {
            startOnLoginCheckbox.state = autoStartManager.isEnabled ? .on : .off
            presentErrorAlert(message: "Could not update Start on login.", informativeText: error.localizedDescription)
        }
    }

    @objc private func closeWindow() {
        window?.close()
    }

    private func presentErrorAlert(message: String, informativeText: String) {
        let alert = NSAlert()
        alert.messageText = message
        alert.informativeText = informativeText
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        if let window {
            alert.beginSheetModal(for: window)
        } else {
            alert.runModal()
        }
    }
}
