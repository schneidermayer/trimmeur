import AppKit
import TrimmeurCore

final class PreferencesWindowController: NSWindowController, NSWindowDelegate {
    private let preferences: TrimmeurPreferences
    private let autoStartManager: AutoStartManaging
    private let onShortcutChanged: () -> Void
    private var recordingMonitor: Any?

    private let shortcutButton = NSButton(title: "", target: nil, action: nil)
    private let resetShortcutButton = NSButton(title: "Reset", target: nil, action: nil)
    private let startOnLoginCheckbox = NSButton(checkboxWithTitle: "Start on login", target: nil, action: nil)
    private let statusLabel = NSTextField(labelWithString: "")

    init(
        preferences: TrimmeurPreferences,
        autoStartManager: AutoStartManaging = AutoStartManager(),
        onShortcutChanged: @escaping () -> Void
    ) {
        self.preferences = preferences
        self.autoStartManager = autoStartManager
        self.onShortcutChanged = onShortcutChanged

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 420, height: 190),
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

    private func buildContent() {
        guard let contentView = window?.contentView else { return }

        let titleLabel = NSTextField(labelWithString: "Paste Trimmed")
        titleLabel.font = .boldSystemFont(ofSize: 14)

        let shortcutTitleLabel = NSTextField(labelWithString: "Shortcut")
        shortcutTitleLabel.alignment = .right

        shortcutButton.bezelStyle = .rounded
        shortcutButton.target = self
        shortcutButton.action = #selector(beginRecording)

        resetShortcutButton.bezelStyle = .rounded
        resetShortcutButton.target = self
        resetShortcutButton.action = #selector(resetShortcut)

        startOnLoginCheckbox.target = self
        startOnLoginCheckbox.action = #selector(toggleStartOnLogin)

        statusLabel.textColor = .secondaryLabelColor
        statusLabel.lineBreakMode = .byWordWrapping
        statusLabel.maximumNumberOfLines = 2

        let doneButton = NSButton(title: "Done", target: self, action: #selector(closeWindow))
        doneButton.bezelStyle = .rounded
        doneButton.keyEquivalent = "\r"

        for view in [titleLabel, shortcutTitleLabel, shortcutButton, resetShortcutButton, startOnLoginCheckbox, statusLabel, doneButton] {
            view.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview(view)
        }

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 22),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),

            shortcutTitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 24),
            shortcutTitleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            shortcutTitleLabel.widthAnchor.constraint(equalToConstant: 86),

            shortcutButton.centerYAnchor.constraint(equalTo: shortcutTitleLabel.centerYAnchor),
            shortcutButton.leadingAnchor.constraint(equalTo: shortcutTitleLabel.trailingAnchor, constant: 12),
            shortcutButton.widthAnchor.constraint(equalToConstant: 160),

            resetShortcutButton.centerYAnchor.constraint(equalTo: shortcutButton.centerYAnchor),
            resetShortcutButton.leadingAnchor.constraint(equalTo: shortcutButton.trailingAnchor, constant: 8),
            resetShortcutButton.widthAnchor.constraint(equalToConstant: 76),

            startOnLoginCheckbox.topAnchor.constraint(equalTo: shortcutButton.bottomAnchor, constant: 20),
            startOnLoginCheckbox.leadingAnchor.constraint(equalTo: shortcutButton.leadingAnchor),

            statusLabel.topAnchor.constraint(equalTo: startOnLoginCheckbox.bottomAnchor, constant: 14),
            statusLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            statusLabel.trailingAnchor.constraint(equalTo: doneButton.leadingAnchor, constant: -16),

            doneButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            doneButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -18),
            doneButton.widthAnchor.constraint(equalToConstant: 86),
        ])
    }

    private func refresh() {
        shortcutButton.title = preferences.pasteTrimmedShortcut.displayString
        startOnLoginCheckbox.state = autoStartManager.isEnabled ? .on : .off
        if statusLabel.stringValue.isEmpty {
            statusLabel.stringValue = "Click the shortcut button, then press the new key combination."
        }
    }

    @objc private func beginRecording() {
        stopRecording()
        shortcutButton.title = "Press shortcut..."
        statusLabel.stringValue = "Press a key with Command, Option, or Control. Escape cancels."
        window?.makeFirstResponder(nil)

        recordingMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.handleShortcutEvent(event)
            return nil
        }
    }

    private func handleShortcutEvent(_ event: NSEvent) {
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

        preferences.pasteTrimmedShortcut = shortcut
        stopRecording()
        statusLabel.stringValue = "Shortcut set to \(shortcut.readableString)."
        refresh()
        onShortcutChanged()
    }

    private func stopRecording() {
        if let recordingMonitor {
            NSEvent.removeMonitor(recordingMonitor)
        }
        recordingMonitor = nil
    }

    @objc private func resetShortcut() {
        preferences.resetShortcut()
        statusLabel.stringValue = "Shortcut reset to \(KeyboardShortcut.defaultPasteTrimmed.readableString)."
        refresh()
        onShortcutChanged()
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
