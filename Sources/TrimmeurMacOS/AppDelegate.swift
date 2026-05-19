import AppKit
import TrimmeurCore

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private var pasteMenuItems: [NSMenuItem] = []
    private var preferencesWindowController: PreferencesWindowController?
    private let hotKey = GlobalHotKey()
    private let pasteService = PasteTrimmedService()
    private let preferences = TrimmeurPreferences()

    func applicationDidFinishLaunching(_ notification: Notification) {
        closeAlreadyRunningInstancesIfNeeded()
        setupMainMenu()
        setupStatusItem()
        registerHotKey()
    }

    func applicationWillTerminate(_ notification: Notification) {
        hotKey.unregister()
    }

    private func setupMainMenu() {
        let mainMenu = NSMenu()
        let appMenuItem = NSMenuItem(title: "Trimmeur", action: nil, keyEquivalent: "")
        mainMenu.addItem(appMenuItem)

        let appMenu = NSMenu(title: "Trimmeur")
        appMenuItem.submenu = appMenu
        appMenu.addItem(makePasteMenuItem())
        appMenu.addItem(makeMenuItem(title: "Preferences...", action: #selector(openPreferences), keyEquivalent: ","))
        appMenu.addItem(.separator())
        appMenu.addItem(makeMenuItem(title: "Quit Trimmeur", action: #selector(quit), keyEquivalent: "q"))
        NSApp.mainMenu = mainMenu
    }

    private func setupStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        if let button = item.button {
            button.image = Self.makeStatusBarIcon()
            button.imagePosition = .imageOnly
            button.toolTip = "Trimmeur"
        }

        let menu = NSMenu()
        menu.addItem(makePasteMenuItem())
        menu.addItem(makeMenuItem(title: "Preferences...", action: #selector(openPreferences), keyEquivalent: ""))
        menu.addItem(.separator())
        menu.addItem(makeMenuItem(title: accessibilityMenuTitle, action: #selector(requestAccessibilityPermission), keyEquivalent: ""))
        menu.addItem(.separator())
        menu.addItem(makeMenuItem(title: "Quit Trimmeur", action: #selector(quit), keyEquivalent: "q"))

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

    private func makeMenuItem(title: String, action: Selector, keyEquivalent: String) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: keyEquivalent)
        item.target = self
        return item
    }

    private func registerHotKey() {
        let shortcut = preferences.pasteTrimmedShortcut
        do {
            try hotKey.register(shortcut: shortcut) { [weak self] in
                self?.pasteTrimmed(nil)
            }
        } catch {
            let alert = NSAlert()
            alert.messageText = "Could not register \(shortcut.readableString)"
            alert.informativeText = error.localizedDescription
            alert.alertStyle = .warning
            alert.addButton(withTitle: "OK")
            alert.runModal()
        }
    }

    private func refreshShortcut() {
        registerHotKey()
        for item in pasteMenuItems {
            configurePasteMenuItem(item)
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

    @objc private func pasteTrimmed(_ sender: Any?) {
        if !AccessibilityPermission.isTrusted(prompt: false) {
            _ = AccessibilityPermission.isTrusted(prompt: true)
            NSSound.beep()
            return
        }

        switch pasteService.pasteTrimmedClipboard() {
        case .pasted:
            break
        case .clipboardHasNoString:
            NSSound.beep()
        case .couldNotCreatePasteEvent:
            NSSound.beep()
        }
    }

    @objc private func requestAccessibilityPermission() {
        _ = AccessibilityPermission.isTrusted(prompt: true)
        AccessibilityPermission.openSystemSettings()
    }

    @objc private func openPreferences() {
        if preferencesWindowController == nil {
            preferencesWindowController = PreferencesWindowController(preferences: preferences) { [weak self] in
                self?.refreshShortcut()
            }
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
