import Foundation
import Cocoa
import Carbon.HIToolbox

enum SelectionMode: String {
    case direct = "direct"
    case actionbar = "actionbar"
}

final class SelectionAssistantCoordinator {
    // AX constants not exported to Swift (HIServices C headers only).
    private static let axManualAccessibility = "AXManualAccessibility" as CFString
    private static let axStringForMarkerRange = "AXStringForMarkerRange" as CFString

    // Computed so Settings toggle takes effect immediately, not after relaunch.
    var isEnabled: Bool {
        get {
            if UserDefaults.standard.object(forKey: "selection_assistant_enabled") == nil { return true }
            return UserDefaults.standard.bool(forKey: "selection_assistant_enabled")
        }
        set { UserDefaults.standard.set(newValue, forKey: "selection_assistant_enabled") }
    }
    var selectionMode: SelectionMode {
        get { SelectionMode(rawValue: UserDefaults.standard.string(forKey: "selection_mode") ?? "actionbar") ?? .actionbar }
        set { UserDefaults.standard.set(newValue.rawValue, forKey: "selection_mode") }
    }
    var autoInvokeDelay: TimeInterval {
        let d = UserDefaults.standard.double(forKey: "auto_invoke_delay")
        return d > 0 ? d : 0.3
    }
    var presets: [PresetTemplate] {
        get { PresetStore.load() }
        set { PresetStore.save(newValue) }
    }

    private let triggerMonitor: SelectionAssistantTriggerMonitor
    private var panel: SelectionAssistantPanel?
    private(set) var pendingTrigger: Bool = false
    private var permissionNoticeShown = false

    init(triggerMonitor: SelectionAssistantTriggerMonitor) {
        self.triggerMonitor = triggerMonitor
        self.triggerMonitor.onTrigger = { [weak self] in self?.trigger() }
        self.triggerMonitor.autoInvokeDelayProvider = { [weak self] in self?.autoInvokeDelay ?? 0.3 }
        self.triggerMonitor.onDirectMode = { snapshot in
            NotificationCenter.default.post(name: .selectionAssistantDirect, object: nil, userInfo: ["snapshot": snapshot])
        }
        self.triggerMonitor.dismissMonitorAction = { [weak self] in
            self?.dismissPanelIfNeeded()
        }
    }

    func start() {
        guard isEnabled else { return }
        triggerMonitor.start()
    }

    /// Registers/unregisters triggers per current setting and prompts for Accessibility if needed.
    /// Safe to call repeatedly (hotkey install and mouse monitors are idempotent).
    func checkPermissionPromptIfNeeded() {
        if isEnabled {
            triggerMonitor.start()
            triggerMonitor.startMouseMonitors()
            if !AXIsProcessTrusted() {
                AXIsProcessTrustedWithOptions([kAXTrustedCheckOptionPrompt.takeRetainedValue(): true] as CFDictionary)
                if !permissionNoticeShown {
                    permissionNoticeShown = true
                    NotificationCenter.default.post(name: .selectionAssistantPermissionNeeded, object: nil)
                }
                pendingTrigger = true
            }
        } else {
            triggerMonitor.stop()
            pendingTrigger = false
        }
    }

    func markPendingTrigger() {
        pendingTrigger = true
    }

    func mouseMonitorsStarted() {
        triggerMonitor.startMouseMonitors()
    }

    func stop() {
        triggerMonitor.stop()
    }

    /// Re-registers the hotkey after the user changed the combination in Settings.
    func restartTriggerMonitor() {
        triggerMonitor.stop()
        if isEnabled {
            triggerMonitor.start()
        }
    }

    func trigger() {
        guard isEnabled else {
            return
        }
        Task { @MainActor in
            await handleTrigger()
        }
    }

    @MainActor
    private func handleTrigger() async {
        if !AXIsProcessTrusted() {
            AXIsProcessTrustedWithOptions([kAXTrustedCheckOptionPrompt.takeRetainedValue(): true] as CFDictionary)
            if !permissionNoticeShown {
                permissionNoticeShown = true
                NotificationCenter.default.post(name: .selectionAssistantPermissionNeeded, object: nil)
            }
            pendingTrigger = true
            return
        }
        pendingTrigger = false
        triggerMonitor.startMouseMonitors()
        // Permission just became usable (or already was): let listeners retry their own taps.
        NotificationCenter.default.post(name: .selectionAssistantCheckPermission, object: nil)
        guard let selectedText = readSelection() else {
            return
        }
        let trimmed = selectedText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return
        }
        let bundleID = NSWorkspace.shared.frontmostApplication?.bundleIdentifier ?? ""
        let pid = NSWorkspace.shared.frontmostApplication?.processIdentifier ?? 0
        let snapshot = SelectionSnapshot(
            selectedText: trimmed,
            appBundleIdentifier: bundleID,
            appPID: pid,
            canReplaceSelection: AXIsProcessTrusted()
        )
        switch selectionMode {
        case .direct:
            NotificationCenter.default.post(name: .selectionAssistantDirect, object: nil, userInfo: ["snapshot": snapshot])
        case .actionbar:
            showPanel(selectionText: trimmed, snapshot: snapshot)
        }
    }

    private func readSelection() -> String? {
        let app = NSWorkspace.shared.frontmostApplication
        guard let pid = app?.processIdentifier else {
            return readSelectionViaClipboard()
        }
        let axApp = AXUIElementCreateApplication(pid)
        // Safari answers AX calls with -25204 (cannotComplete) at default timeout.
        AXUIElementSetMessagingTimeout(axApp, 2.0)
        var rawFocused: AnyObject?
        _ = AXUIElementCopyAttributeValue(axApp, kAXFocusedUIElementAttribute as CFString, &rawFocused)
        guard let raw = rawFocused else {
            return readSelectionViaClipboard()
        }
        let element = bridgeToAXUIElement(raw)

        // 1) Plain selected text — works in native text views (Notes, TextEdit, …).
        var selectedText: AnyObject?
        _ = AXUIElementCopyAttributeValue(element, kAXSelectedTextAttribute as CFString, &selectedText)
        if let text = selectedText as? String, !text.isEmpty {
            return text
        }

        // 2) WebKit (Safari): marker ranges live on the AXWebArea ancestor, not on the
        //    focused web node. Climb up (max 6 levels), opt every node into manual
        //    accessibility, resolve the selection marker range where it appears.
        var resolvedText: String?
        var node = element
        for _ in 0..<6 {
            AXUIElementSetMessagingTimeout(node, 2.0)
            AXUIElementSetAttributeValue(node, Self.axManualAccessibility, kCFBooleanTrue)
            var markerRange: AnyObject?
            _ = AXUIElementCopyAttributeValue(node, kAXSelectedTextMarkerRangeAttribute as CFString, &markerRange)
            if let range = markerRange {
                var stringResult: AnyObject?
                _ = AXUIElementCopyParameterizedAttributeValue(
                    node,
                    Self.axStringForMarkerRange,
                    range,
                    &stringResult
                )
                if let text = stringResult as? String, !text.isEmpty {
                    resolvedText = text
                    break
                }
                // Leaf web nodes carry the marker range but don't support
                // AXStringForMarkerRange (-25213) — the AXWebArea ancestor does.
            }
            var role: AnyObject?
            AXUIElementCopyAttributeValue(node, kAXRoleAttribute as CFString, &role)
            let roleStr = role as? String ?? "?"
            if roleStr == "AXWebArea" && markerRange == nil {
                // reached but no marker range; continue climb
            }
            var parent: AnyObject?
            _ = AXUIElementCopyAttributeValue(node, kAXParentAttribute as CFString, &parent)
            guard let p = parent else {
                return readSelectionViaClipboard()
            }
            node = bridgeToAXUIElement(p)
        }

        guard let text = resolvedText else {
            return readSelectionViaClipboard()
        }
        return text
    }

    /// Safari exposes selection through neither AXSelectedText nor a usable
    /// AXStringForMarkerRange. Copy selection through the app's normal command
    /// path, then restore every original pasteboard item.
    private func readSelectionViaClipboard() -> String? {
        let pasteboard = NSPasteboard.general
        let originalItems = pasteboard.pasteboardItems?.map { item in
            item.types.compactMap { type -> (NSPasteboard.PasteboardType, Data)? in
                guard let data = item.data(forType: type) else { return nil }
                return (type, data)
            }
        } ?? []
        let changeCount = pasteboard.changeCount

        defer {
            pasteboard.clearContents()
            let restoredItems = originalItems.map { entries -> NSPasteboardItem in
                let item = NSPasteboardItem()
                for (type, data) in entries {
                    item.setData(data, forType: type)
                }
                return item
            }
            if !restoredItems.isEmpty {
                pasteboard.writeObjects(restoredItems)
            }
        }

        let source = CGEventSource(stateID: .combinedSessionState)
        let keyDown = CGEvent(keyboardEventSource: source, virtualKey: CGKeyCode(kVK_ANSI_C), keyDown: true)
        let keyUp = CGEvent(keyboardEventSource: source, virtualKey: CGKeyCode(kVK_ANSI_C), keyDown: false)
        keyDown?.flags = CGEventFlags.maskCommand
        keyUp?.flags = CGEventFlags.maskCommand
        keyDown?.post(tap: .cghidEventTap)
        keyUp?.post(tap: .cghidEventTap)

        // Safari updates pasteboard asynchronously after handling Command-C.
        usleep(80_000)
        guard pasteboard.changeCount != changeCount else {
            return nil
        }
        guard let text = pasteboard.string(forType: .string), !text.isEmpty else {
            return nil
        }
        return text
    }

    private func bridgeToAXUIElement(_ obj: AnyObject) -> AXUIElement {
        return obj as! AXUIElement
    }

    private func showPanel(selectionText: String, snapshot: SelectionSnapshot) {
        // Re-trigger (hotkey/drag) must replace the previous panel — otherwise
        // invisible panels accumulate and presets appear to stack up.
        dismissPanel()
        panel = SelectionAssistantPanel(
            presets: presets,
            onPresetSelected: { [weak self] template in
                NotificationCenter.default.post(name: .selectionAssistantDirect, object: nil, userInfo: ["snapshot": snapshot, "template": template])
                self?.panel?.dismiss()
                self?.panel = nil
            },
            onDismiss: { [weak self] in
                self?.panel = nil
            }
        )
        panel?.show(selectionText: selectionText, snapshot: snapshot)
    }

    private func dismissPanel() {
        panel?.dismiss()
        panel = nil
    }

    func dismissPanelIfNeeded() {
        panel?.dismissIfOutside()
    }
}
