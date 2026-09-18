import AppKit
import Highlightr
import Markdown
import SwiftUI

// Markdown module also declares `Text`; keep unqualified `Text` as SwiftUI.
typealias Text = SwiftUI.Text

struct ContentView: View {
    @EnvironmentObject var vm: ChatViewModel
    @EnvironmentObject var serverManager: ServerManager
    @Environment(\.openWindow) private var openWindow
    @State private var input = ""
    @State private var showSettings = false
    @AppStorage("chat_font_size") private var fontSize: Double = 15
    @AppStorage("input_height") private var inputHeight: Double = 60
    @FocusState private var inputFocused: Bool

    private var foregroundColor: Color {
        OneDarkPro.text
    }

    private var foregroundNSColor: NSColor {
        OneDarkPro.nsText
    }

    var body: some View {
        VStack(spacing: 0) {
            // Chat area
            GeometryReader { geo in
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 12) {
                ForEach(vm.messages) { msg in
                    MessageRow(
                        msg: msg,
                        foregroundColor: foregroundColor,
                        foregroundNSColor: foregroundNSColor,
                        containerWidth: geo.size.width,
                        fontSize: fontSize,
                        snapshot: vm.snapshotForMessage(msg.id),
                        onInsert: { vm.insertSelection(for: msg.id) }
                    )
                        .id(msg.id)
                }
                        Color.clear.frame(height: 1).id("bottom")
                    }
                    .padding()
                    .font(.system(size: fontSize))
                }
                .onChange(of: vm.messages.count) { _, _ in
                    scrollToBottom(proxy)
                }
                .onChange(of: vm.streamingContent) { _, _ in
                    scrollToBottom(proxy)
                }
                if !vm.streamingContent.isEmpty {
                    StreamingBubble(content: vm.streamingContent, foregroundColor: foregroundColor, foregroundNSColor: foregroundNSColor, containerWidth: geo.size.width, fontSize: fontSize)
                }
            }
            }

            // Drag handle
            foregroundColor.opacity(0.25)
                .frame(height: 1)
                .padding(.vertical, 4)
                .contentShape(Rectangle())
                .onHover { hovering in
                    if hovering { NSCursor.resizeUpDown.push() } else { NSCursor.pop() }
                }
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            inputHeight = max(40, min(300, inputHeight - value.translation.height))
                        }
                )

            // Input area
            HStack(alignment: .top, spacing: 8) {
                ChatInputField(text: $input, fontSize: fontSize, foregroundColor: foregroundColor, backgroundColor: OneDarkPro.background, onSubmit: sendMessage)
                    .focused($inputFocused)

                if vm.isLoading {
                    Button(action: vm.stop) {
                        Label("Stop", systemImage: "stop.fill")
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .keyboardShortcut(".", modifiers: .command)
                }
            }
            .frame(height: inputHeight)
            .padding(.vertical, 8)
            .padding(.horizontal, 16)
        }
        .background(OneDarkPro.background)
        .frame(minWidth: 300, minHeight: 300)
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button(action: { vm.reset() }) {
                    Text("New chat")
                }
                .keyboardShortcut("r", modifiers: [.command, .shift])
                .disabled(vm.messages.isEmpty && vm.streamingContent.isEmpty)

                Menu {
                    ForEach(vm.models) { model in
                        Button(model.label) { vm.selectedModel = model }
                    }
                } label: {
                    Text(vm.selectedModel.label)
                }

                Menu {
                    ForEach(ServerKind.allCases) { kind in
                        Button(kind.label) { serverManager.server = kind }
                    }
                } label: {
                    Text(serverManager.server.label)
                }

                if serverManager.isRunning {
                    Button { serverManager.stop() } label: {
                        Label("Stop server", systemImage: "stop.fill")
                            .labelStyle(.iconOnly)
                    }
                } else {
                    Button { serverManager.start(model: vm.selectedModel.id) } label: {
                        Label("Start server", systemImage: "play.fill")
                            .labelStyle(.iconOnly)
                    }
                }

                Button { openWindow(id: "server-log") } label: {
                    Label("Server log", systemImage: "terminal")
                }

                Button(action: { showSettings.toggle() }) {
                    Label("Settings", systemImage: "gearshape")
                }
            }
        }
        .onAppear { inputFocused = true }
        .background {
            // Hidden buttons to capture Cmd+= and Cmd+-
            Button("") { fontSize = min(fontSize + 2, 32) }
                .keyboardShortcut("+", modifiers: .command)
                .hidden()
            Button("") { fontSize = min(fontSize + 2, 32) }
                .keyboardShortcut("=", modifiers: .command)
                .hidden()
            Button("") { fontSize = max(fontSize - 2, 10) }
                .keyboardShortcut("-", modifiers: .command)
                .hidden()
            Button("") { fontSize = 15 }
                .keyboardShortcut("0", modifiers: .command)
                .hidden()
            Button("") { showSettings = true }
                .keyboardShortcut(",", modifiers: .command)
                .hidden()
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
                .environmentObject(vm)
        }
    }

    private func sendMessage() {
        guard !vm.isLoading else { return }
        let text = input
        input = ""
        vm.send(text)
    }

    private func scrollToBottom(_ proxy: ScrollViewProxy) {
        Task {
            try? await Task.sleep(for: .milliseconds(50))
        }
        proxy.scrollTo("bottom", anchor: .bottom)
    }
}

struct StreamingBubble: View {
    let content: String
    let foregroundColor: Color
    let foregroundNSColor: NSColor
    let containerWidth: CGFloat
    let fontSize: Double
    var body: some View {
        MessageBubble(role: "assistant", content: content, blocks: nil, foregroundColor: foregroundColor, foregroundNSColor: foregroundNSColor, containerWidth: containerWidth, fontSize: fontSize)
    }
}

func copyToClipboard(_ string: String) {
    NSPasteboard.general.clearContents()
    NSPasteboard.general.setString(string, forType: .string)
}

struct MessageRow: View {
    let msg: ChatMessage
    let foregroundColor: Color
    let foregroundNSColor: NSColor
    var containerWidth: CGFloat = 600
    var fontSize: Double = 15
    var snapshot: SelectionSnapshot?
    var onInsert: () -> Void
    @EnvironmentObject var vm: ChatViewModel

    @State private var feedback: Feedback = .none
    @State private var copied = false

    enum Feedback { case none, like, dislike }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            MessageBubble(role: msg.role, content: msg.content, blocks: msg.parsedBlocks, foregroundColor: foregroundColor, foregroundNSColor: foregroundNSColor, containerWidth: containerWidth, fontSize: fontSize)
            if let stats = msg.statsLine {
                Text(stats)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(.secondary)
            }
                if msg.role == "assistant" {
                    HStack(spacing: 14) {
                        Button {
                            copyToClipboard(msg.content)
                            copied = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { copied = false }
                        } label: {
                            Label(copied ? "Copied" : "Copy", systemImage: copied ? "checkmark" : "doc.on.doc")
                        }
                        if snapshot != nil {
                            Button {
                                onInsert()
                            } label: {
                                Label("Insert Selection", systemImage: "arrow.down.circle")
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }
                        Button {
                            feedback = (feedback == .like) ? .none : .like
                        } label: {
                            Label("Like", systemImage: feedback == .like ? "hand.thumbsup.fill" : "hand.thumbsup")
                        }
                        .foregroundStyle(feedback == .like ? foregroundColor : .secondary)
                        Button {
                            feedback = (feedback == .dislike) ? .none : .dislike
                        } label: {
                            Label("Dislike", systemImage: feedback == .dislike ? "hand.thumbsdown.fill" : "hand.thumbsdown")
                        }
                        .foregroundStyle(feedback == .dislike ? foregroundColor : .secondary)
                    }
                    .buttonStyle(.plain)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    if let err = vm.insertionError {
                        Text(err)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .onAppear { vm.insertionError = nil }
                    }
                }
        }
    }
}

struct MessageBubble: View {
    let role: String
    let content: String
    let blocks: [Markdown.Markup]?
    let foregroundColor: Color
    let foregroundNSColor: NSColor
    var containerWidth: CGFloat = 600
    var fontSize: Double = 15

    private var isNarrow: Bool { containerWidth < 500 }

    private var textMaxWidth: CGFloat {
        max(200, containerWidth - 32 - 20 - (isNarrow ? 0 : 60))
    }

    var body: some View {
        HStack {
            if role == "user" { Spacer(minLength: isNarrow ? 0 : 60) }

            VStack(alignment: .leading, spacing: 8) {
                MarkdownBlockContent(blocks: blocks, text: content, fontSize: fontSize, foregroundColor: foregroundColor, foregroundNSColor: foregroundNSColor, maxWidth: textMaxWidth)
            }
            .padding(10)
            .background(foregroundColor.opacity(role == "user" ? 0.18 : 0.0))
            .cornerRadius(10)

            if role == "assistant" && !isNarrow { Spacer(minLength: 60) }
        }
    }
}

struct MarkdownBlockContent: View {
    let blocks: [Markdown.Markup]?
    let text: String
    let fontSize: Double
    let foregroundColor: Color
    let foregroundNSColor: NSColor
    let maxWidth: CGFloat

    var body: some View {
        Group {
            if let blocks = blocks {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(Array(blocks.enumerated()), id: \.offset) { _, block in
                        MarkdownBlockView(markup: block, fontSize: fontSize, foregroundColor: foregroundColor, foregroundNSColor: foregroundNSColor, maxWidth: maxWidth)
                    }
                }
            } else {
                Text(text)
                    .textSelection(.enabled)
                    .foregroundStyle(foregroundColor)
            }
        }
    }
}

struct MarkdownBlockView: View {
    let markup: Markdown.Markup
    let fontSize: Double
    let foregroundColor: Color
    let foregroundNSColor: NSColor
    let maxWidth: CGFloat

    var body: some View {
        Group {
            if let heading = markup as? Markdown.Heading {
                RichParagraph(container: heading, fontSize: headingSize(heading.level), bold: true, foreground: foregroundNSColor, maxWidth: maxWidth)
            } else if let paragraph = markup as? Markdown.Paragraph {
                RichParagraph(container: paragraph, fontSize: fontSize, bold: false, foreground: foregroundNSColor, maxWidth: maxWidth)
            } else if let codeBlock = markup as? Markdown.CodeBlock,
                      !codeBlock.code.trimmingCharacters(in: .newlines).isEmpty {
                CodeCardView(code: codeBlock.code.trimmingCharacters(in: .newlines), language: codeBlock.language, foregroundColor: foregroundColor)
            } else if let quote = markup as? Markdown.BlockQuote {
                HStack(alignment: .top, spacing: 8) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(foregroundColor.opacity(0.4))
                        .frame(width: 3)
                    childBlocks(Array(quote.children), maxWidth: maxWidth - 14)
                }
            } else if let list = markup as? Markdown.UnorderedList {
                listView(items: Array(list.children), orderedFrom: nil)
            } else if let list = markup as? Markdown.OrderedList {
                listView(items: Array(list.children), orderedFrom: Int(list.startIndex))
            } else if markup is Markdown.ThematicBreak {
                Divider()
            } else if let html = markup as? Markdown.HTMLBlock {
                Text(html.rawHTML)
                    .textSelection(.enabled)
                    .foregroundStyle(foregroundColor)
            } else if let table = markup as? Markdown.Table {
                tableView(table)
            } else if markup.childCount > 0 {
                childBlocks(Array(markup.children), maxWidth: maxWidth)
            }
        }
    }

    private func headingSize(_ level: Int) -> Double {
        switch level {
        case 1: return fontSize * 1.5
        case 2: return fontSize * 1.3
        default: return fontSize * 1.15
        }
    }

    private func childBlocks(_ blocks: [Markdown.Markup], maxWidth: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(Array(blocks.enumerated()), id: \.offset) { _, block in
                MarkdownBlockView(markup: block, fontSize: fontSize, foregroundColor: foregroundColor, foregroundNSColor: foregroundNSColor, maxWidth: maxWidth)
            }
        }
    }

    private func listView(items: [Markdown.Markup], orderedFrom start: Int?) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                HStack(alignment: .top, spacing: 6) {
                    Text(listMarker(index: index, start: start))
                        .foregroundStyle(foregroundColor)
                        .frame(minWidth: 20, alignment: .trailing)
                    if item.childCount > 0 {
                        childBlocks(Array(item.children), maxWidth: maxWidth - 30)
                    }
                }
            }
        }
    }

    private func listMarker(index: Int, start: Int?) -> String {
        if let start { return "\(start + index)." }
        return "•"
    }

    private func tableView(_ table: Markdown.Table) -> some View {
        let head = table.children.compactMap { $0 as? Markdown.Table.Head }.first
        let headerCells = head?.children.compactMap({ $0 as? Markdown.Table.Cell }).map(cellText) ?? []
        let bodyRows = table.children.compactMap { $0 as? Markdown.Table.Body }
            .flatMap { body in body.children.compactMap({ $0 as? Markdown.Table.Row }).map(cells(of:)) }
        return VStack(spacing: 0) {
            if !headerCells.isEmpty {
                HStack(spacing: 0) {
                    ForEach(Array(headerCells.enumerated()), id: \.offset) { _, cell in
                        Text(cell)
                            .font(.system(size: fontSize).bold())
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(6)
                            .background(foregroundColor.opacity(0.12))
                            .overlay(Rectangle().stroke(foregroundColor.opacity(0.3), lineWidth: 0.5))
                    }
                }
                .frame(maxWidth: .infinity)
            }
            ForEach(Array(bodyRows.enumerated()), id: \.offset) { _, cells in
                HStack(spacing: 0) {
                    ForEach(Array(cells.enumerated()), id: \.offset) { _, cell in
                        Text(cell)
                            .font(.system(size: fontSize))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(6)
                            .overlay(Rectangle().stroke(foregroundColor.opacity(0.2), lineWidth: 0.5))
                    }
                }
                .frame(maxWidth: .infinity)
                .fixedSize(horizontal: false, vertical: true)
            }
        }
        .textSelection(.enabled)
    }

    private func cells(of row: Markdown.Table.Row) -> [String] {
        row.children.compactMap { $0 as? Markdown.Table.Cell }.map(cellText)
    }

    private func cellText(_ cell: Markdown.Table.Cell) -> String {
        RichInline.plainString(cell).trimmingCharacters(in: .whitespaces)
    }
}

enum RichInline {
    static func attributed(_ container: Markdown.Markup, base: NSFont, fg: NSColor, monoSize: Double, pillBG: NSColor) -> NSAttributedString {
        let out = NSMutableAttributedString()
        appendChildren(of: container, font: base, fg: fg, monoSize: monoSize, pillBG: pillBG, into: out)
        return out
    }

    static func plainString(_ markup: Markdown.Markup) -> String {
        if let text = markup as? Markdown.Text { return text.string }
        if markup is Markdown.SoftBreak || markup is Markdown.LineBreak { return " " }
        return markup.children.map(plainString).joined()
    }

    private static func append(_ markup: Markdown.Markup, font: NSFont, fg: NSColor, monoSize: Double, pillBG: NSColor, into out: NSMutableAttributedString) {
        if let text = markup as? Markdown.Text {
            out.append(NSAttributedString(string: text.string, attributes: [.font: font, .foregroundColor: fg]))
        } else if markup is Markdown.Emphasis {
            appendChildren(of: markup, font: font.italicVariant, fg: fg, monoSize: monoSize, pillBG: pillBG, into: out)
        } else if markup is Markdown.Strong {
            appendChildren(of: markup, font: font.boldVariant, fg: fg, monoSize: monoSize, pillBG: pillBG, into: out)
        } else if let code = markup as? Markdown.InlineCode {
            out.append(NSAttributedString(string: code.code, attributes: [
                .font: NSFont.monospacedSystemFont(ofSize: monoSize, weight: .regular),
                .foregroundColor: fg,
                .backgroundColor: pillBG
            ]))
        } else if let link = markup as? Markdown.Link {
            let start = out.length
            appendChildren(of: markup, font: font, fg: fg, monoSize: monoSize, pillBG: pillBG, into: out)
            let range = NSRange(location: start, length: out.length - start)
            out.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: range)
            if let dest = link.destination, let url = URL(string: dest) {
                out.addAttribute(.link, value: url, range: range)
            }
        } else if markup is Markdown.SoftBreak || markup is Markdown.LineBreak {
            out.append(NSAttributedString(string: "\n", attributes: [.font: font, .foregroundColor: fg]))
        } else if let html = markup as? Markdown.InlineHTML {
            out.append(NSAttributedString(string: html.rawHTML, attributes: [.font: font, .foregroundColor: fg]))
        } else if let image = markup as? Markdown.Image {
            let alt = plainString(image)
            out.append(NSAttributedString(string: alt.isEmpty ? "[image]" : alt, attributes: [.font: font, .foregroundColor: fg]))
        } else {
            appendChildren(of: markup, font: font, fg: fg, monoSize: monoSize, pillBG: pillBG, into: out)
        }
    }

    private static func appendChildren(of markup: Markdown.Markup, font: NSFont, fg: NSColor, monoSize: Double, pillBG: NSColor, into out: NSMutableAttributedString) {
        for child in markup.children {
            append(child, font: font, fg: fg, monoSize: monoSize, pillBG: pillBG, into: out)
        }
    }
}

extension NSFont {
    var italicVariant: NSFont { NSFontManager.shared.convert(self, toHaveTrait: .italicFontMask) }
    var boldVariant: NSFont { NSFontManager.shared.convert(self, toHaveTrait: .boldFontMask) }
}

enum CodeHighlight {
    static let shared: Highlightr? = {
        guard let hl = Highlightr() else { return nil }
        hl.setTheme(to: "atom-one-dark")
        hl.theme.setCodeFont(.monospacedSystemFont(ofSize: 13, weight: .regular))
        return hl
    }()

    static func attributed(_ code: String, language: String?) -> AttributedString? {
        let lang = (language?.isEmpty == false) ? language : nil
        guard let hl = shared, let ns = hl.highlight(code, as: lang) else { return nil }
        return AttributedString(ns)
    }
}

struct CodeCardView: View {
    let code: String
    let language: String?
    let foregroundColor: Color

    @State private var copied = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text((language?.isEmpty == false) ? language! : "code")
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundStyle(.secondary)
                Spacer()
                Button {
                    copyToClipboard(code)
                    copied = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { copied = false }
                } label: {
                    Label(copied ? "Copied" : "Copy", systemImage: copied ? "checkmark" : "doc.on.doc")
                        .font(.system(size: 12))
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            Divider()
            ScrollView(.horizontal, showsIndicators: false) {
                codeBody
                    .padding(10)
            }
        }
        .background(foregroundColor.opacity(0.10))
        .cornerRadius(8)
    }

    @ViewBuilder
    private var codeBody: some View {
        if let highlighted = CodeHighlight.attributed(code, language: language) {
            Text(highlighted)
                .textSelection(.enabled)
        } else {
            Text(code)
                .textSelection(.enabled)
                .foregroundStyle(foregroundColor)
                .font(.system(size: 13, design: .monospaced))
        }
    }
}

struct RichParagraph: View {
    let container: Markdown.Markup
    let fontSize: Double
    let bold: Bool
    let foreground: NSColor
    let maxWidth: CGFloat

    @State private var height: CGFloat = 24

    var body: some View {
        RichTextView(attributed: build(), maxWidth: maxWidth, height: $height)
            .frame(height: height)
    }

    private func build() -> NSAttributedString {
        let base: NSFont = bold ? .boldSystemFont(ofSize: fontSize) : .systemFont(ofSize: fontSize)
        return RichInline.attributed(container, base: base, fg: foreground, monoSize: fontSize, pillBG: foreground.withAlphaComponent(0.14))
    }
}

struct RichTextView: NSViewRepresentable {
    let attributed: NSAttributedString
    let maxWidth: CGFloat
    @Binding var height: CGFloat

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator {
        let storage = NSTextStorage()
        let manager = NSLayoutManager()
        let container = NSTextContainer(containerSize: .zero)
        init() {
            container.lineFragmentPadding = 0
            manager.addTextContainer(container)
            storage.addLayoutManager(manager)
        }
    }

    func makeNSView(context: Context) -> NSTextView {
        let tv = NSTextView()
        tv.isEditable = false
        tv.isSelectable = true
        tv.drawsBackground = false
        tv.textContainerInset = .zero
        tv.textContainer?.lineFragmentPadding = 0
        return tv
    }

    func updateNSView(_ tv: NSTextView, context: Context) {
        tv.textStorage?.setAttributedString(attributed)
        let c = context.coordinator
        c.container.containerSize = NSSize(width: max(maxWidth, 50), height: .greatestFiniteMagnitude)
        c.storage.setAttributedString(attributed)
        c.manager.ensureLayout(for: c.container)
        let h = ceil(c.manager.usedRect(for: c.container).height)
        if abs(height - h) > 0.5 {
            DispatchQueue.main.async { height = h }
        }
    }
}

struct ServerLogView: View {
    @EnvironmentObject var serverManager: ServerManager

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading) {
                    Text(serverManager.log)
                        .font(.system(size: 12, design: .monospaced))
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Color.clear.frame(height: 1).id("bottom")
                }
                .padding()
            }
            .onChange(of: serverManager.log) { _, _ in
                proxy.scrollTo("bottom", anchor: .bottom)
            }
        }
        .background(OneDarkPro.background)
        .foregroundStyle(OneDarkPro.text)
        .frame(minWidth: 500, minHeight: 300)
    }
}
