import Foundation
import AppKit

/// Listens system-wide for Control+Option+Command + any non-modifier key (listen-only,
/// does not consume the event) and fires onActivate on the main queue.
///
/// Requires Accessibility permission — the same one the Selection Assistant already
/// requests. While permission is missing, tapCreate returns nil and start() fails;
/// retry start() after the permission is granted.
final class GlobalActivationMonitor {
    var onActivate: (() -> Void)?

    /// App that was frontmost right before the last hotkey activation — the toggle target.
    private var previousApp: NSRunningApplication?

    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?

    /// Installs the tap. Returns false when Accessibility is not granted (no crash; retry later).
    @discardableResult
    func start() -> Bool {
        guard eventTap == nil else { return true }

        let mask: CGEventMask = (1 << CGEventType.keyDown.rawValue)
        let callback: CGEventTapCallBack = { _, _, event, userInfo in
            if let monitor = userInfo {
                let monitor = Unmanaged<GlobalActivationMonitor>.fromOpaque(monitor).takeUnretainedValue()
                monitor.handle(event: event)
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
            return false
        }

        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)

        eventTap = tap
        runLoopSource = source
        return true
    }

    func stop() {
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
            CFMachPortInvalidate(tap)
        }
        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
        }
        eventTap = nil
        runLoopSource = nil
    }

    private func handle(event: CGEvent) {
        let flags = event.flags
        let wanted: CGEventFlags = [.maskControl, .maskAlternate, .maskCommand]
        guard flags.contains(wanted), !flags.contains(.maskSecondaryFn) else { return }
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            if NSApp.isActive {
                // Toggle: hand focus back to the app the hotkey was summoned from.
                if let app = self.previousApp, app.processIdentifier != getpid() {
                    app.activate()
                    self.previousApp = nil
                }
            } else {
                self.previousApp = NSWorkspace.shared.frontmostApplication
                self.onActivate?()
            }
        }
    }
}
