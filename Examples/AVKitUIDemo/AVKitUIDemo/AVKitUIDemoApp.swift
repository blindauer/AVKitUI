import SwiftUI
import AVKit
import AppKit
import AVKitUI

@main
struct AVKitUIDemoApp: App {
    var body: some Scene {
        WindowGroup("AVKitUI Demo") {
            DemoRootView()
                .frame(minWidth: 960, minHeight: 620)
        }
        .windowResizability(.contentSize)
    }
}

private struct DemoRootView: View {
    @State private var selectedURL: URL?
    @State private var player = AVPlayer()
    @State private var itemStatus: AVPlayerItem.Status = .unknown
    @State private var statusObservation: NSKeyValueObservation?
    @State private var controlsStyle: AVPlayerViewControlsStyle = .floating
    @State private var pointerSummary = "Move the pointer over the video surface."
    @State private var menuTint: NSColor = .systemBlue

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            content
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .onDisappear {
            statusObservation?.invalidate()
        }
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text("MacAVPlayerBridge Demo")
                    .font(.system(size: 28, weight: .semibold))
                Text("A minimal macOS SwiftUI app using AVPlayerView through the package.")
                    .foregroundStyle(.secondary)
                if let selectedURL {
                    Text(selectedURL.lastPathComponent)
                        .font(.system(.body, design: .monospaced))
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 12) {
                Button("Choose Video…", action: chooseVideo)
                    .buttonStyle(.borderedProminent)

                Picker("Controls", selection: $controlsStyle) {
                    Text("None").tag(AVPlayerViewControlsStyle.none)
                    Text("Inline").tag(AVPlayerViewControlsStyle.inline)
                    Text("Floating").tag(AVPlayerViewControlsStyle.floating)
                    if #available(macOS 12.0, *) {
                        Text("Minimal").tag(AVPlayerViewControlsStyle.minimal)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 280)
            }
        }
        .padding(24)
    }

    @ViewBuilder
    private var content: some View {
        HStack(spacing: 0) {
            playerSurface
            Divider()
            inspector
        }
    }

    private var playerSurface: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.black.opacity(0.92))

            PlayerView(player: player)
                .controlsStyle(controlsStyle)
                .contextMenuItems(contextMenuItems)
                .onPointerActivity { activity in
                    pointerSummary = pointerSummary(for: activity)
                }
                .clipShape(RoundedRectangle(cornerRadius: 18))

            if itemStatus != .readyToPlay {
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color.black.opacity(0.55))
                    .overlay {
                        VStack(spacing: 10) {
                            ProgressView()
                            Text(statusLabel(itemStatus))
                                .foregroundStyle(.white.opacity(0.9))
                        }
                    }
                    .allowsHitTesting(false)
            }
        }
        .padding(24)
    }

    private var inspector: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Live Signals")
                .font(.headline)

            signalRow(label: "Item status", value: statusLabel(itemStatus))
            signalRow(label: "Controls style", value: controlsStyleLabel)
            signalRow(label: "Pointer", value: pointerSummary)

            Divider()

            Text("Context Menu")
                .font(.headline)

            Text("Right-click the player to pause, play, jump to the beginning, or use a custom AppKit view inside the menu.")
                .foregroundStyle(.secondary)

            Spacer()
        }
        .padding(24)
        .frame(width: 300, alignment: .topLeading)
    }

    private func signalRow(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.system(.body, design: .monospaced))
        }
    }

    private var contextMenuItems: [ContextMenuItem] {
        [
            .item(title: "Play") {
                player.play()
            },
            .item(title: "Pause") {
                player.pause()
            },
            .item(title: "Restart") {
                player.seek(to: .zero)
                player.play()
            },
            .separator,
            .customView(viewProvider: { controller in
                DemoMenuTintView(color: $menuTint) {
                    controller?.closeMenu()
                }
            })
        ]
    }

    private var controlsStyleLabel: String {
        switch controlsStyle {
        case .none:
            return "none"
        case .inline:
            return "inline"
        case .floating:
            return "floating"
        default:
            return "other"
        }
    }

    private func chooseVideo() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.movie, .mpeg4Movie, .quickTimeMovie]
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false

        guard panel.runModal() == .OK, let url = panel.url else { return }
        setVideoURL(url)
    }

    private func setVideoURL(_ url: URL) {
        selectedURL = url
        let item = AVPlayerItem(url: url)
        player.replaceCurrentItem(with: item)
        bindStatus(to: item)
        player.play()
    }

    private func bindStatus(to item: AVPlayerItem) {
        statusObservation?.invalidate()
        itemStatus = item.status
        statusObservation = item.observe(\.status, options: [.initial, .new]) { observedItem, _ in
            DispatchQueue.main.async {
                itemStatus = observedItem.status
            }
        }
    }

    private func statusLabel(_ status: AVPlayerItem.Status) -> String {
        switch status {
        case .unknown:
            return "unknown"
        case .readyToPlay:
            return "readyToPlay"
        case .failed:
            return "failed"
        @unknown default:
            return "unknown-default"
        }
    }

    private func pointerSummary(for activity: PlayerPointerActivity) -> String {
        let x = Int(activity.location.x.rounded())
        let y = Int(activity.location.y.rounded())
        let phase: String
        switch activity.phase {
        case .moved:
            phase = "moved"
        case .entered:
            phase = "entered"
        case .exited:
            phase = "exited"
        case .modifiersChanged:
            phase = "modifiersChanged"
        }

        let modifiers = modifierSummary(activity.modifiers)
        return "\(phase) @ (\(x), \(y)) [\(modifiers)]"
    }

    private func modifierSummary(_ modifiers: NSEvent.ModifierFlags) -> String {
        guard !modifiers.isEmpty else { return "none" }

        var labels: [String] = []
        if modifiers.contains(.command) { labels.append("command") }
        if modifiers.contains(.option) { labels.append("option") }
        if modifiers.contains(.control) { labels.append("control") }
        if modifiers.contains(.shift) { labels.append("shift") }
        if modifiers.contains(.capsLock) { labels.append("capsLock") }
        if modifiers.contains(.function) { labels.append("function") }

        return labels.isEmpty ? "other" : labels.joined(separator: "+")
    }
}

private final class DemoMenuTintView: NSHostingView<DemoMenuTintContent> {
    init(color: Binding<NSColor>, closeMenu: @escaping () -> Void) {
        super.init(rootView: DemoMenuTintContent(color: color, closeMenu: closeMenu))
        frame = NSRect(x: 0, y: 0, width: 220, height: 72)
    }

    @available(*, unavailable)
    required init(rootView: DemoMenuTintContent) {
        fatalError("init(rootView:) has not been implemented")
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private struct DemoMenuTintContent: View {
    @Binding var color: NSColor
    let closeMenu: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Custom AppKit View")
                .font(.headline)
            HStack(spacing: 8) {
                Circle()
                    .fill(Color(nsColor: color))
                    .frame(width: 14, height: 14)
                Button("Cycle Tint") {
                    color = nextColor(after: color)
                    closeMenu()
                }
                .buttonStyle(.borderless)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(nsColor: .controlBackgroundColor))
    }

    private func nextColor(after current: NSColor) -> NSColor {
        let palette: [NSColor] = [.systemBlue, .systemPink, .systemGreen, .systemOrange]
        let currentIndex = palette.firstIndex(of: current) ?? 0
        let nextIndex = (currentIndex + 1) % palette.count
        return palette[nextIndex]
    }
}
