import SwiftUI

struct ChatInputField: View {
    @Binding var text: String
    var fontSize: Double
    var foregroundColor: Color
    var backgroundColor: Color
    var onSubmit: () -> Void

    @FocusState private var focused: Bool
    @State private var monitor: Any?

    var body: some View {
        TextEditor(text: $text)
            .font(.system(size: fontSize, design: .monospaced))
            .scrollContentBackground(.hidden)
            .background(backgroundColor)
            .foregroundStyle(foregroundColor)
            .focused($focused)
            .onAppear {
                if let m = monitor { NSEvent.removeMonitor(m); monitor = nil }
                focused = true
                monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
                    if event.keyCode == 36 && !event.modifierFlags.contains(.shift) {
                        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
                        if !trimmed.isEmpty {
                            onSubmit()
                        }
                        return nil
                    }
                    return event
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .focusPromptInput)) { _ in
                focused = true
            }
            .onDisappear {
                if let m = monitor {
                    NSEvent.removeMonitor(m)
                }
            }
    }
}
