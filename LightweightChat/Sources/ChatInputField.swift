import SwiftUI
import AppKit

struct ChatInputField: NSViewRepresentable {
    @Binding var text: String
    var fontSize: Double
    var foregroundColor: Color
    var onSubmit: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        let textView = SubmittableTextView()
        textView.delegate = context.coordinator
        textView.onSubmit = onSubmit
        textView.isRichText = false
        textView.allowsUndo = true
        textView.font = NSFont.monospacedSystemFont(ofSize: fontSize, weight: .regular)
        textView.textColor = NSColor(foregroundColor)
        textView.insertionPointColor = NSColor(foregroundColor)
        textView.backgroundColor = .clear
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.textContainer?.widthTracksTextView = true
        textView.textContainer?.lineFragmentPadding = 0

        scrollView.documentView = textView
        scrollView.hasVerticalScroller = false
        scrollView.drawsBackground = false
        scrollView.borderType = .noBorder

        context.coordinator.textView = textView
        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? SubmittableTextView else { return }
        if textView.string != text {
            textView.string = text
        }
        textView.font = NSFont.monospacedSystemFont(ofSize: fontSize, weight: .regular)
        textView.textColor = NSColor(foregroundColor)
        textView.insertionPointColor = NSColor(foregroundColor)
        textView.onSubmit = onSubmit
    }

    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: ChatInputField
        weak var textView: NSTextView?

        init(_ parent: ChatInputField) {
            self.parent = parent
        }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            parent.text = textView.string
        }
    }
}

class SubmittableTextView: NSTextView {
    var onSubmit: (() -> Void)?

    override func keyDown(with event: NSEvent) {
        let isReturn = event.keyCode == 36
        let shiftHeld = event.modifierFlags.contains(.shift)

        if isReturn && !shiftHeld {
            onSubmit?()
            return
        }

        super.keyDown(with: event)
    }

    override var intrinsicContentSize: NSSize {
        guard let container = textContainer, let manager = layoutManager else {
            return super.intrinsicContentSize
        }
        manager.ensureLayout(for: container)
        let rect = manager.usedRect(for: container)
        let lineHeight = font?.boundingRectForFont.height ?? 18
        let maxHeight = lineHeight * 5
        return NSSize(width: NSView.noIntrinsicMetric, height: min(rect.height + 4, maxHeight))
    }
}
