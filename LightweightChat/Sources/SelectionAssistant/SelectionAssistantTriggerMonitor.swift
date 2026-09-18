import Foundation
import Cocoa
import Carbon.HIToolbox

/// Комбинации хоткея Selection Assistant. Выбираются в Settings
/// (UserDefaults `selection_hotkey`), действуют без перезапуска.
enum SelectionHotkey: String {
    case cmdShiftSpace = "cmd-shift-space"
    case ctrlOptCmdSpace = "ctrl-opt-cmd-space"
    case optShiftSpace = "opt-shift-space"

    static let current: SelectionHotkey = {
        SelectionHotkey(rawValue: UserDefaults.standard.string(forKey: "selection_hotkey") ?? "") ?? .cmdShiftSpace
    }()

    var keyCode: UInt32 { UInt32(kVK_Space) }

    var carbonModifiers: UInt32 {
        switch self {
        case .cmdShiftSpace: return UInt32(cmdKey | shiftKey)
        case .ctrlOptCmdSpace: return UInt32(controlKey | optionKey | cmdKey)
        case .optShiftSpace: return UInt32(optionKey | shiftKey)
        }
    }

    var cgFlags: CGEventFlags {
        switch self {
        case .cmdShiftSpace: return [.maskCommand, .maskShift]
        case .ctrlOptCmdSpace: return [.maskControl, .maskAlternate, .maskCommand]
        case .optShiftSpace: return [.maskAlternate, .maskShift]
        }
    }

    var displayName: String {
        switch self {
        case .cmdShiftSpace: return "⌘⇧Space"
        case .ctrlOptCmdSpace: return "⌃⌥⌘Space"
        case .optShiftSpace: return "⌥⇧Space"
        }
    }
}

final class SelectionAssistantTriggerMonitor {
    var onTrigger: (() -> Void)?
    var onDirectMode: ((SelectionSnapshot) -> Void)?
    var dismissMonitorAction: (() -> Void)?
    /// Провайдер debounce-задержки из настроек (auto_invoke_delay).
    var autoInvokeDelayProvider: (() -> TimeInterval)?

    private static let hotKeySignature: OSType = {
        let bytes: [UInt8] = [0x53, 0x45, 0x4C, 0x41] // "SELA"
        return (OSType(bytes[0]) << 24) | (OSType(bytes[1]) << 16) | (OSType(bytes[2]) << 8) | OSType(bytes[3])
    }()

    private var hotKeyRef: EventHotKeyRef?
    private var eventHandlerRef: EventHandlerRef?
    private var eventTap: CFMachPort?
    private var eventTapSource: CFRunLoopSource?
    private var mouseUpMonitor: Any?
    private var mouseDownMonitor: Any?
    private var dismissMonitor: Any?
    private var debounceWorkItem: DispatchWorkItem?
    private var mouseMonitorsActive = false

    private var mouseDownPoint: CGPoint = .zero

    func start() {
        installHotKey()
    }

    func startMouseMonitors() {
        guard !mouseMonitorsActive else { return }
        mouseMonitorsActive = true
        startMouseDownMonitor()
        startMouseUpMonitor()
        startDismissMonitor()
    }

    func stop() {
        uninstallHotKey()
        mouseUpMonitor = nil
        mouseDownMonitor = nil
        dismissMonitor = nil
        mouseMonitorsActive = false
        debounceWorkItem?.cancel()
        debounceWorkItem = nil
    }

    // Carbon RegisterEventHotKey works globally without Accessibility/Input Monitoring permission,
    // unlike NSEvent.addGlobalMonitorForEvents(.keyDown) which silently receives nothing until trusted.
    // OSStatus checked: on conflict we fall back to a listen-only CGEvent tap (needs Accessibility,
    // which the assistant already requires for reading the selection).
    private func installHotKey() {
        guard hotKeyRef == nil, eventTap == nil else { return }
        guard let appTarget = GetApplicationEventTarget() else {
            return
        }

        let hotkey = SelectionHotkey.current
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        let userData = Unmanaged.passUnretained(self).toOpaque()
        InstallEventHandler(
            appTarget,
            { _, _, userData in
                guard let userData else { return noErr }
                let monitor = Unmanaged<SelectionAssistantTriggerMonitor>.fromOpaque(userData).takeUnretainedValue()
                monitor.onTrigger?()
                return noErr
            },
            1,
            &eventType,
            userData,
            &eventHandlerRef
        )

        let hotKeyID = EventHotKeyID(signature: Self.hotKeySignature, id: 1)
        let status = RegisterEventHotKey(
            hotkey.keyCode,
            hotkey.carbonModifiers,
            hotKeyID,
            appTarget,
            0,
            &hotKeyRef
        )

        if status == noErr {
        } else {
            hotKeyRef = nil
            installEventTapFallback(for: hotkey)
        }
    }

    private func installEventTapFallback(for hotkey: SelectionHotkey) {
        let mask: CGEventMask = (1 << CGEventType.keyDown.rawValue)
        let callback: CGEventTapCallBack = { _, _, event, userInfo in
            if let monitor = userInfo {
                let monitor = Unmanaged<SelectionAssistantTriggerMonitor>.fromOpaque(monitor).takeUnretainedValue()
                monitor.handleTapEvent(event)
            }
            return Unmanaged.passUnretained(event)
        }
        let selfPtr = Unmanaged.passUnretained(self).toOpaque()
        guard let tap = CGEvent.tapCreate(
            tap: .cghidEventTap,
            place: .headInsertEventTap,
            options: .listenOnly,
            eventsOfInterest: mask,
            callback: callback,
            userInfo: selfPtr
        ) else {
            return
        }
        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        eventTap = tap
        eventTapSource = source
    }

    func handleTapEvent(_ event: CGEvent) {
        let hotkey = SelectionHotkey.current
        let modifierMask: CGEventFlags = [.maskCommand, .maskShift, .maskControl, .maskAlternate]
        let flags = event.flags
        guard !flags.contains(.maskSecondaryFn), flags.intersection(modifierMask) == hotkey.cgFlags else { return }
        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
        guard keyCode == Int64(hotkey.keyCode) else { return }
        DispatchQueue.main.async { [weak self] in self?.onTrigger?() }
    }

    private func uninstallHotKey() {
        if let hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
        }
        hotKeyRef = nil
        if let eventHandlerRef {
            RemoveEventHandler(eventHandlerRef)
        }
        eventHandlerRef = nil
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
            CFMachPortInvalidate(tap)
        }
        if let source = eventTapSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
        }
        eventTap = nil
        eventTapSource = nil
    }

    private func startMouseDownMonitor() {
        mouseDownMonitor = NSEvent.addGlobalMonitorForEvents(matching: .leftMouseDown) { [weak self] event in
            self?.mouseDownPoint = event.locationInWindow
            if event.clickCount >= 2 {
                self?.onTrigger?()
            }
        }
    }

    private func startMouseUpMonitor() {
        mouseUpMonitor = NSEvent.addGlobalMonitorForEvents(matching: .leftMouseUp) { [weak self] event in
            guard let self else { return }
            let dragDistance = abs(event.locationInWindow.x - self.mouseDownPoint.x)
            let dragVertical = abs(event.locationInWindow.y - self.mouseDownPoint.y)
            if dragDistance >= 3 || dragVertical >= 3 {
                self.scheduleAutomaticTrigger()
            }
        }
    }

    private func startDismissMonitor() {
        dismissMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            self?.dismissMonitorAction?()
        }
    }

    private func scheduleAutomaticTrigger() {
        let delay = autoInvokeDelayProvider?() ?? 0.3
        debounceWorkItem?.cancel()
        debounceWorkItem = DispatchWorkItem { [weak self] in
            self?.onTrigger?()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: debounceWorkItem!)
    }
}
