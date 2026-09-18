import SwiftUI
import AppKit

/// Registry holding the app's main NSWindow. Strong on purpose: SwiftUI may release
/// the NSWindow after ⌘W even with isReleasedWhenClosed = false — the strong ref keeps
/// the object alive so a tray/hotkey click can bring it back.
enum WindowRegistry {
    static var mainWindow: NSWindow?
}

struct WindowAccessor: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            if let window = view.window {
                // Retire a stale window from a previous scene instance to avoid duplicates.
                if let old = WindowRegistry.mainWindow, old !== window {
                    old.orderOut(nil)
                }
                WindowRegistry.mainWindow = window
                window.isReleasedWhenClosed = false
                window.standardWindowButton(.zoomButton)?.isHidden = true
            }
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}
