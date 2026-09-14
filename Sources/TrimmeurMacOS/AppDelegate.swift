import AppKit
import TrimmeurCore

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let appName = "Trimmeur"
    private var statusItem: NSStatusItem?
    private var pasteMenuItems: [NSMenuItem] = []
    private var pasteWithoutLineBreaksMenuItems: [NSMenuItem] = []
    private var preferencesWindowController: PreferencesWindowController?
    private let pasteHotKey = GlobalHotKey(identifier: 1)
    private let pasteWithoutLineBreaksHotKey = GlobalHotKey(identifier: 2)
    private let pasteService = PasteTrimmedService()
    private let preferences = TrimmeurPreferences()
    private var isRecordingShortcut = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        closeAlreadyRunningInstancesIfNeeded()
        setupMainMenu()
        setupStatusItem()
        registerHotKeys()
    }

    func applicationWillTerminate(_ notification: Notification) {
        unregisterHotKeys()
    }

    private func setupMainMenu() {
        let mainMenu = NSMenu()
        let appMenuItem = NSMenuItem(title: appName, action: nil, keyEquivalent: "")
        mainMenu.addItem(appMenuItem)

        let appMenu = NSMenu(title: appName)
        appMenuItem.submenu = appMenu
        appMenu.addItem(makePasteMenuItem())
        appMenu.addItem(makePasteWithoutLineBreaksMenuItem())
        addClipboardMenuItems(to: appMenu)
        appMenu.addItem(makeMenuItem(title: "Preferences...", action: #selector(openPreferences), keyEquivalent: ","))
        appMenu.addItem(.separator())
        appMenu.addItem(makeMenuItem(title: quitMenuItemTitle, action: #selector(quit), keyEquivalent: "q"))
        NSApp.mainMenu = mainMenu
    }

    private func setupStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        if let button = item.button {
            button.image = Self.makeStatusBarIcon()
            button.imagePosition = .imageOnly
            button.toolTip = appName
        }

        let menu = NSMenu()
        menu.addItem(makePasteMenuItem())
        menu.addItem(makePasteWithoutLineBreaksMenuItem())
        addClipboardMenuItems(to: menu)
        menu.addItem(makeMenuItem(title: "Preferences...", action: #selector(openPreferences), keyEquivalent: ""))
        menu.addItem(.separator())
        menu.addItem(makeMenuItem(title: accessibilityMenuTitle, action: #selector(requestAccessibilityPermission), keyEquivalent: ""))
        menu.addItem(.separator())
        menu.addItem(makeMenuItem(title: quitMenuItemTitle, action: #selector(quit), keyEquivalent: "q"))

        item.menu = menu
        statusItem = item
    }

    private func makePasteMenuItem() -> NSMenuItem {
        let item = makeMenuItem(title: "Paste Trimmed", action: #selector(pasteTrimmed), keyEquivalent: "")
        pasteMenuItems.append(item)
        configurePasteMenuItem(item)
        return item
    }

    private func configurePasteMenuItem(_ item: NSMenuItem) {
        let shortcut = preferences.pasteTrimmedShortcut
        item.title = shortcut.menuKeyEquivalent.isEmpty ? "Paste Trimmed (\(shortcut.displayString))" : "Paste Trimmed"
        item.keyEquivalent = shortcut.menuKeyEquivalent
        item.keyEquivalentModifierMask = shortcut.cocoaModifierFlags
    }

    private func makePasteWithoutLineBreaksMenuItem() -> NSMenuItem {
        let item = makeMenuItem(title: "Paste Without Line Breaks", action: #selector(pasteWithoutLineBreaks), keyEquivalent: "")
        pasteWithoutLineBreaksMenuItems.append(item)
        configurePasteWithoutLineBreaksMenuItem(item)
        return item
    }

    private func addClipboardMenuItems(to menu: NSMenu) {
        menu.addItem(.separator())
        menu.addItem(makeMenuItem(title: "Trim Clipboard", action: #selector(trimClipboard), keyEquivalent: ""))
        menu.addItem(makeMenuItem(title: "Trim Clipboard and Remove Line Breaks", action: #selector(trimClipboardAndRemoveLineBreaks), keyEquivalent: ""))
        menu.addItem(.separator())
    }

    private func makeMenuItem(title: String, action: Selector, keyEquivalent: String) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: keyEquivalent)
        item.target = self
        return item
    }

    private func configurePasteWithoutLineBreaksMenuItem(_ item: NSMenuItem) {
        let shortcut = preferences.pasteWithoutLineBreaksShortcut
        let title = "Paste Without Line Breaks"
        item.title = shortcut.menuKeyEquivalent.isEmpty ? "\(title) (\(shortcut.displayString))" : title
        item.keyEquivalent = shortcut.menuKeyEquivalent
        item.keyEquivalentModifierMask = shortcut.cocoaModifierFlags
    }

    private func registerHotKeys() {
        unregisterHotKeys()
        register(pasteHotKey, shortcut: preferences.pasteTrimmedShortcut, actionName: "Paste Trimmed") { [weak self] in
            self?.pasteTrimmed(nil)
        }
        register(pasteWithoutLineBreaksHotKey, shortcut: preferences.pasteWithoutLineBreaksShortcut, actionName: "Paste Without Line Breaks") { [weak self] in
            self?.pasteWithoutLineBreaks(nil)
        }
    }

    private func unregisterHotKeys() {
        pasteHotKey.unregister()
        pasteWithoutLineBreaksHotKey.unregister()
    }

    private func register(_ hotKey: GlobalHotKey, shortcut: KeyboardShortcut, actionName: String, handler: @escaping () -> Void) {
        do {
            try hotKey.register(shortcut: shortcut, handler: handler)
        } catch {
            let alert = NSAlert()
            alert.messageText = "Could not register \(shortcut.readableString)"
            alert.informativeText = "\(actionName): \(error.localizedDescription)"
            alert.alertStyle = .warning
            alert.addButton(withTitle: "OK")
            alert.runModal()
        }
    }

    private func refreshShortcut() {
        if !isRecordingShortcut {
            registerHotKeys()
        }
        for item in pasteMenuItems {
            configurePasteMenuItem(item)
        }
        for item in pasteWithoutLineBreaksMenuItems {
            configurePasteWithoutLineBreaksMenuItem(item)
        }
    }

    private func closeAlreadyRunningInstancesIfNeeded() {
        let runningApplications = SingleInstanceManager.alreadyRunningApplications()
        guard !runningApplications.isEmpty else { return }

        NSApp.activate(ignoringOtherApps: true)

        let alert = NSAlert()
        alert.messageText = "App already running. Closing already running instance."
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()

        SingleInstanceManager.close(runningApplications)
    }

    private var accessibilityMenuTitle: String {
        AccessibilityPermission.isTrusted(prompt: false)
            ? "Accessibility Permission Granted"
            : "Request Accessibility Permission..."
    }

    private var quitMenuItemTitle: String {
        AppVersion.quitMenuItemTitle(
            appName: appName,
            version: Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
        )
    }

    @objc private func pasteTrimmed(_ sender: Any?) {
        pasteClipboard(using: pasteService.pasteTrimmedClipboard)
    }

    @objc private func pasteWithoutLineBreaks(_ sender: Any?) {
        pasteClipboard(using: pasteService.pasteWithoutLineBreaksClipboard)
    }

    private func pasteClipboard(using paste: () -> PasteTrimmedService.PasteResult) {
        if !AccessibilityPermission.isTrusted(prompt: false) {
            _ = AccessibilityPermission.isTrusted(prompt: true)
            NSSound.beep()
            return
        }

        switch paste() {
        case .pasted:
            break
        case .clipboardHasNoString:
            NSSound.beep()
        case .couldNotCreatePasteEvent:
            NSSound.beep()
        }
    }

    @objc private func trimClipboard(_ sender: Any?) {
        updateClipboard(using: pasteService.trimClipboard)
    }

    @objc private func trimClipboardAndRemoveLineBreaks(_ sender: Any?) {
        updateClipboard(using: pasteService.trimClipboardAndRemoveLineBreaks)
    }

    private func updateClipboard(using update: () -> PasteTrimmedService.ClipboardUpdateResult) {
        switch update() {
        case .updated:
            break
        case .clipboardHasNoString, .couldNotWriteClipboard:
            NSSound.beep()
        }
    }

    @objc private func requestAccessibilityPermission() {
        _ = AccessibilityPermission.isTrusted(prompt: true)
        AccessibilityPermission.openSystemSettings()
    }

    @objc private func openPreferences() {
        if preferencesWindowController == nil {
            preferencesWindowController = PreferencesWindowController(
                preferences: preferences,
                onShortcutChanged: { [weak self] in
                    self?.refreshShortcut()
                },
                onShortcutRecordingChanged: { [weak self] isRecording in
                    self?.isRecordingShortcut = isRecording
                    if isRecording {
                        self?.unregisterHotKeys()
                    } else {
                        self?.registerHotKeys()
                    }
                }
            )
        }

        preferencesWindowController?.showWindow(nil)
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }

    static func makeStatusBarIcon() -> NSImage {
        if let image = NSImage(systemSymbolName: "scissors", accessibilityDescription: "Trimmeur") {
            image.isTemplate = true
            return image
        }

        let image = NSImage(size: NSSize(width: 18, height: 18))
        image.lockFocus()
        NSColor.labelColor.setStroke()
        let path = NSBezierPath()
        path.lineWidth = 1.8
        path.move(to: NSPoint(x: 4, y: 14))
        path.line(to: NSPoint(x: 14, y: 4))
        path.move(to: NSPoint(x: 4, y: 4))
        path.line(to: NSPoint(x: 14, y: 14))
        path.stroke()
        image.unlockFocus()
        image.isTemplate = true
        return image
    }
}
