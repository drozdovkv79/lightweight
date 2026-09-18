import Foundation
import Cocoa

final class SelectionAssistantPanel {
    private enum Metrics {
        static let padding: CGFloat = 8
        static let buttonHeight: CGFloat = 28
        static let buttonSpacing: CGFloat = 4
        static let minPanelWidth: CGFloat = 180
        static let buttonInnerPadding: CGFloat = 20
        static let cornerRadius: CGFloat = 10
    }

    private let panel: NSPanel
    private var presetButtons: [NSButton] = []

    private let presets: [PresetTemplate]
    private let onPresetSelected: (String) -> Void
    private let onDismiss: () -> Void

    init(
        presets: [PresetTemplate],
        onPresetSelected: @escaping (String) -> Void,
        onDismiss: @escaping () -> Void
    ) {
        self.presets = presets
        self.onPresetSelected = onPresetSelected
        self.onDismiss = onDismiss
        panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: Metrics.minPanelWidth, height: 100),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.level = .statusBar
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.isReleasedWhenClosed = false
        panel.hasShadow = true
        panel.orderOut(nil)
        buildUI(presets: presets)
    }

    private func buildUI(presets: [PresetTemplate]) {
        let effectView = NSVisualEffectView()
        effectView.material = .hudWindow
        effectView.blendingMode = .behindWindow
        effectView.state = .active
        effectView.wantsLayer = true
        effectView.layer?.cornerRadius = Metrics.cornerRadius
        effectView.layer?.masksToBounds = true
        effectView.translatesAutoresizingMaskIntoConstraints = false

        let stackView = NSStackView()
        stackView.orientation = .vertical
        stackView.alignment = .leading
        stackView.spacing = Metrics.buttonSpacing
        stackView.translatesAutoresizingMaskIntoConstraints = false

        let titleFont = NSFont.systemFont(ofSize: 13, weight: .medium)
        for preset in presets {
            let button = NSButton(title: preset.name, target: self, action: #selector(presetClicked(_:)))
            button.isBordered = false
            button.wantsLayer = true
            button.layer?.backgroundColor = NSColor.white.withAlphaComponent(0.12).cgColor
            button.layer?.cornerRadius = 6
            button.attributedTitle = NSAttributedString(
                string: preset.name,
                attributes: [
                    .foregroundColor: NSColor.white,
                    .font: titleFont,
                ]
            )
            button.translatesAutoresizingMaskIntoConstraints = false
            button.heightAnchor.constraint(equalToConstant: Metrics.buttonHeight).isActive = true
            stackView.addArrangedSubview(button)
            presetButtons.append(button)
        }

        panel.contentView = effectView
        effectView.addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: effectView.topAnchor, constant: Metrics.padding),
            stackView.leadingAnchor.constraint(equalTo: effectView.leadingAnchor, constant: Metrics.padding),
            effectView.trailingAnchor.constraint(equalTo: stackView.trailingAnchor, constant: Metrics.padding),
            effectView.bottomAnchor.constraint(equalTo: stackView.bottomAnchor, constant: Metrics.padding),
        ])
    }

    private func sizePanel() {
        let count = CGFloat(presets.count)
        guard count > 0 else { return }
        let titleFont = NSFont.systemFont(ofSize: 13, weight: .medium)
        let maxTitleWidth = presets.map {
            ($0.name as NSString).size(withAttributes: [.font: titleFont]).width
        }.max() ?? 0
        let width = max(
            Metrics.minPanelWidth,
            maxTitleWidth + Metrics.buttonInnerPadding + Metrics.padding * 2
        )
        let height = Metrics.padding * 2
            + count * Metrics.buttonHeight
            + max(0, count - 1) * Metrics.buttonSpacing
        panel.setContentSize(NSSize(width: width, height: height))
    }

    @objc private func presetClicked(_ sender: NSButton) {
        guard let index = presetButtons.firstIndex(of: sender), presets.indices.contains(index) else { return }
        onPresetSelected(presets[index].template)
    }

    func show(selectionText: String, snapshot: SelectionSnapshot) {
        let mouseLoc = NSEvent.mouseLocation
        guard let screen = NSScreen.screens.first(where: { NSMouseInRect(mouseLoc, $0.frame, false) }) ?? NSScreen.main else {
            return
        }
        sizePanel()
        let size = panel.frame.size
        let originX = min(max(mouseLoc.x, screen.frame.minX + 8), screen.frame.maxX - size.width - 8)
        let originY = max(mouseLoc.y - size.height, screen.frame.minY + 8)
        panel.setFrameOrigin(NSPoint(x: originX, y: originY))
        updatePresetButtons(snapshot.canReplaceSelection)
        panel.orderFrontRegardless()
    }

    private func updatePresetButtons(_ enabled: Bool) {
        for button in presetButtons {
            button.isEnabled = enabled
        }
    }

    func dismiss() {
        panel.close()
        onDismiss()
    }

    func dismissIfOutside() {
        let mouseLoc = NSEvent.mouseLocation
        let panelFrame = panel.frame
        if !panelFrame.contains(mouseLoc) && panel.isVisible {
            dismiss()
        }
    }
}
