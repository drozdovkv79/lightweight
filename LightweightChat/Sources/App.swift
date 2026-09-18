import SwiftUI
import AppKit

extension Notification.Name {
    static let selectionAssistantDirect = Notification.Name("SelectionAssistantDirect")
    static let selectionAssistantPermissionNeeded = Notification.Name("SelectionAssistantPermissionNeeded")
    static let selectionAssistantCheckPermission = Notification.Name("SelectionAssistantCheckPermission")
    static let selectionHotkeyChanged = Notification.Name("SelectionHotkeyChanged")
    static let focusPromptInput = Notification.Name("FocusPromptInput")
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    var coordinator: SelectionAssistantCoordinator?
    var triggerMonitor: SelectionAssistantTriggerMonitor?
    /// Assigned by the scene once the WindowGroup appears; kept here so
    /// `.selectionAssistantDirect` delivery works even with the window closed.
    weak var chatVM: ChatViewModel?
    private let activationMonitor = GlobalActivationMonitor()
    private var statusItem: NSStatusItem?
    private var trayImage: NSImage?

    func applicationWillFinishLaunching(_ notification: Notification) {
        NSWindow.allowsAutomaticWindowTabbing = false
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Process-wide defaults: fresh installs get actionbar mode + ⌘⇧Space hotkey
        // without overwriting values the user has explicitly set.
        UserDefaults.standard.register(defaults: [
            "selection_mode": SelectionMode.actionbar.rawValue,
            "selection_hotkey": SelectionHotkey.cmdShiftSpace.rawValue,
        ])
        DispatchQueue.main.async {
            guard let mainMenu = NSApp.mainMenu,
                  let viewMenuItem = mainMenu.items.first(where: { $0.submenu?.title == "View" })
            else { return }
            mainMenu.removeItem(viewMenuItem)
        }

        let triggerMonitor = SelectionAssistantTriggerMonitor()
        let coordinator = SelectionAssistantCoordinator(triggerMonitor: triggerMonitor)
        self.triggerMonitor = triggerMonitor
        self.coordinator = coordinator
        coordinator.start()
        NotificationCenter.default.addObserver(
            forName: .selectionAssistantPermissionNeeded,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.coordinator?.markPendingTrigger()
        }
        NotificationCenter.default.addObserver(
            forName: .selectionAssistantCheckPermission,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.coordinator?.checkPermissionPromptIfNeeded()
        }
        NotificationCenter.default.addObserver(
            forName: .selectionHotkeyChanged,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.coordinator?.restartTriggerMonitor()
        }
        // Selection delivery lives here, not on a window-scoped SwiftUI view:
        // the trigger must work with the main window closed.
        NotificationCenter.default.addObserver(
            forName: .selectionAssistantDirect,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let snapshot = notification.userInfo?["snapshot"] as? SelectionSnapshot else {
                return
            }
            let template = notification.userInfo?["template"] as? String
            Task { @MainActor in
                self?.chatVM?.send(selectionSnapshot: snapshot, template: template)
            }
            self?.activateMainWindow()
        }
        // Proactive Accessibility prompt at launch — do not wait for first hotkey press.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.coordinator?.checkPermissionPromptIfNeeded()
        }
        setupStatusItem()
        setupActivationMonitor()
    }

    /// Global Cmd+Ctrl+Opt+<key> → open window, focus prompt. Needs the same
    /// Accessibility permission as the Selection Assistant; retried when it is granted.
    private func setupActivationMonitor() {
        activationMonitor.onActivate = { [weak self] in
            self?.activateMainWindow()
            NotificationCenter.default.post(name: .focusPromptInput, object: nil)
        }
        if !activationMonitor.start() {
            // No Accessibility yet: retry whenever the permission flow reports progress.
            NotificationCenter.default.addObserver(
                forName: .selectionAssistantCheckPermission,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                _ = self?.activationMonitor.start()
            }
        }
    }

    // MARK: - Menu bar status item

    private func setupStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = item.button {
            button.image = makeTrayIcon()
            button.target = self
            button.action = #selector(statusItemClicked)
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
        statusItem = item
    }

    /// Tray icon from bundled locy_tray.jpeg, circular-masked (source JPEG has no alpha).
    private func makeTrayIcon() -> NSImage? {
        if let trayImage { return trayImage }
        let source: NSImage?
        if let url = Bundle.main.url(forResource: "locy_tray", withExtension: "jpeg") {
            source = NSImage(contentsOf: url)
        } else {
            source = NSApp.applicationIconImage
        }
        guard let source else { return nil }
        let size = NSSize(width: 18, height: 18)
        let image = NSImage(size: size)
        image.lockFocus()
        if let context = NSGraphicsContext.current?.cgContext {
            context.saveGState()
            NSBezierPath(ovalIn: CGRect(origin: .zero, size: size).insetBy(dx: 0.5, dy: 0.5)).addClip()
            source.draw(in: CGRect(origin: .zero, size: size), from: .zero, operation: .sourceOver, fraction: 1.0)
            context.restoreGState()
        }
        image.unlockFocus()
        image.isTemplate = false
        trayImage = image
        return image
    }

    @objc private func statusItemClicked() {
        if NSApp.currentEvent?.type == .rightMouseUp {
            showTrayMenu()
        } else {
            activateMainWindow()
        }
    }

    private func showTrayMenu() {
        let menu = NSMenu()
        let about = NSMenuItem(title: "About…", action: #selector(showAbout), keyEquivalent: "")
        about.target = self
        menu.addItem(about)
        let quit = NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "")
        quit.target = self
        menu.addItem(quit)
        // Temporarily assign the menu so performClick presents it; nil restores click-action behavior.
        statusItem?.menu = menu
        statusItem?.button?.performClick(nil)
        statusItem?.menu = nil
    }

    @objc private func showAbout() {
        MainActor.assumeIsolated {
            AboutPanel.show()
        }
    }

    @objc private func quitApp() {
        NSApp.terminate(nil)
    }

    // MARK: - Activation

    /// Brings the app to front, gives the main window keyboard focus.
    /// The window survives ⌘W (isReleasedWhenClosed = false), so it is always restorable.
    func activateMainWindow() {
        NSApp.activate(ignoringOtherApps: true)
        if let window = WindowRegistry.mainWindow ?? NSApp.windows.first(where: { $0.canBecomeMain && $0.isVisible }) {
            window.makeKeyAndOrderFront(nil)
        } else if let window = NSApp.windows.first(where: { $0.canBecomeMain }) {
            // Hidden after close — bring it back.
            window.makeKeyAndOrderFront(nil)
        }
    }
}

@main
struct LightweightChatApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var chatVM = ChatViewModel()
    @StateObject private var serverManager = ServerManager()
    @State private var showPermissionAlert = false

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(chatVM)
                .environmentObject(serverManager)
                .preferredColorScheme(.dark)
                .background(WindowAccessor())
                .onAppear {
                    // Hand the VM to the AppDelegate so direct-mode delivery
                    // survives closing the main window.
                    appDelegate.chatVM = chatVM
                }
                .onReceive(NotificationCenter.default.publisher(for: .selectionAssistantPermissionNeeded)) { _ in
                    showPermissionAlert = true
                }
                .alert("Accessibility Permission Needed", isPresented: $showPermissionAlert) {
                    Button("Open System Settings") {
                        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
                            NSWorkspace.shared.open(url)
                        }
                    }
                    Button("Later", role: .cancel) {}
                } message: {
                    Text("Lightweight needs Accessibility permission to read selected text in other apps.\n\nGrant it in System Settings → Privacy & Security → Accessibility, then press \(SelectionHotkey.current.displayName) again. If the permission was already granted, restart the app.")
                }
        }
        Window("Server Log", id: "server-log") {
            ServerLogView()
                .environmentObject(serverManager)
        }
        .defaultSize(width: 800, height: 700)
        .commands {
            CommandGroup(replacing: .appInfo) {
                Button("About Lightweight") {
                    AboutPanel.show()
                }
            }
        }
    }
}

private enum AboutPanel {
    @MainActor
    static func show() {
        let style = NSMutableParagraphStyle()
        style.alignment = .center

        let credits = NSMutableAttributedString(
            string: "Created by Peter Cooper\n",
            attributes: [
                .font: NSFont.systemFont(ofSize: NSFont.smallSystemFontSize),
                .paragraphStyle: style,
            ]
        )
        credits.append(NSAttributedString(
            string: "github.com/peterc/lightweight",
            attributes: [
                .font: NSFont.systemFont(ofSize: NSFont.smallSystemFontSize),
                .foregroundColor: NSColor.linkColor,
                .link: URL(string: "https://github.com/peterc/lightweight")!,
                .underlineStyle: NSUnderlineStyle.single.rawValue,
                .paragraphStyle: style,
            ]
        ))
        credits.append(NSAttributedString(
            string: "\n\nUses ",
            attributes: [
                .font: NSFont.systemFont(ofSize: NSFont.smallSystemFontSize),
                .paragraphStyle: style,
            ]
        ))
        credits.append(NSAttributedString(
            string: "OpenRouter",
            attributes: [
                .font: NSFont.systemFont(ofSize: NSFont.smallSystemFontSize),
                .foregroundColor: NSColor.linkColor,
                .link: URL(string: "https://openrouter.ai")!,
                .underlineStyle: NSUnderlineStyle.single.rawValue,
                .paragraphStyle: style,
            ]
        ))
        credits.append(NSAttributedString(
            string: ".\nOpenRouter is a trademark of OpenRouter, Inc.\nLightweight is not affiliated with or endorsed by OpenRouter.",
            attributes: [
                .font: NSFont.systemFont(ofSize: NSFont.smallSystemFontSize),
                .paragraphStyle: style,
            ]
        ))

        NSApp.orderFrontStandardAboutPanel(options: [.credits: credits])
        NSApp.activate(ignoringOtherApps: true)
    }
}
