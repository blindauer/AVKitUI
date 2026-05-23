import SwiftUI
import AVKit
import AppKit

public struct MacAVPlayerConfiguration {
    public var controlsStyle: AVPlayerViewControlsStyle
    public var videoGravity: AVLayerVideoGravity
    public var showsFullScreenToggleButton: Bool
    public var showsFrameSteppingButtons: Bool
    public var showsSharingServiceButton: Bool
    public var updatesNowPlayingInfoCenter: Bool
    public var allowsVideoFrameAnalysis: Bool

    public init(
        controlsStyle: AVPlayerViewControlsStyle = .floating,
        videoGravity: AVLayerVideoGravity = .resizeAspect,
        showsFullScreenToggleButton: Bool = true,
        showsFrameSteppingButtons: Bool = true,
        showsSharingServiceButton: Bool = true,
        updatesNowPlayingInfoCenter: Bool = false,
        allowsVideoFrameAnalysis: Bool = false
    ) {
        self.controlsStyle = controlsStyle
        self.videoGravity = videoGravity
        self.showsFullScreenToggleButton = showsFullScreenToggleButton
        self.showsFrameSteppingButtons = showsFrameSteppingButtons
        self.showsSharingServiceButton = showsSharingServiceButton
        self.updatesNowPlayingInfoCenter = updatesNowPlayingInfoCenter
        self.allowsVideoFrameAnalysis = allowsVideoFrameAnalysis
    }
}

public struct MacAVPlayerView: NSViewRepresentable {
    public let player: AVPlayer
    public let configuration: MacAVPlayerConfiguration
    public let menuItems: [ContextMenuItem]
    public let onPointerActivity: (@MainActor @Sendable (PlayerPointerActivity) -> Void)?

    public init(
        player: AVPlayer,
        configuration: MacAVPlayerConfiguration = .init(),
        menuItems: [ContextMenuItem] = [],
        onPointerActivity: (@MainActor @Sendable (PlayerPointerActivity) -> Void)? = nil
    ) {
        self.player = player
        self.configuration = configuration
        self.menuItems = menuItems
        self.onPointerActivity = onPointerActivity
    }

    public func makeNSView(context: Context) -> AVPlayerView {
        let view = BridgeAVPlayerView()
        configure(view, context: context)
        return view
    }

    public func updateNSView(_ nsView: AVPlayerView, context: Context) {
        guard let view = nsView as? BridgeAVPlayerView else { return }
        configure(view, context: context)
    }

    private func configure(_ view: BridgeAVPlayerView, context: Context) {
        view.player = player
        view.controlsStyle = configuration.controlsStyle
        view.videoGravity = configuration.videoGravity
        view.menuItems = menuItems
        view.onPointerActivity = onPointerActivity
        view.showsFullScreenToggleButton = configuration.showsFullScreenToggleButton
        view.showsFrameSteppingButtons = configuration.showsFrameSteppingButtons
        view.showsSharingServiceButton = configuration.showsSharingServiceButton
        view.updatesNowPlayingInfoCenter = configuration.updatesNowPlayingInfoCenter
        if #available(macOS 13.0, *) {
            view.allowsVideoFrameAnalysis = configuration.allowsVideoFrameAnalysis
        }
    }
}

final class BridgeAVPlayerView: AVPlayerView {
    var menuItems: [ContextMenuItem] = []
    var onPointerActivity: (@MainActor @Sendable (PlayerPointerActivity) -> Void)?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var acceptsFirstResponder: Bool {
        true
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        trackingAreas.forEach(removeTrackingArea)

        let options: NSTrackingArea.Options = [
            .mouseMoved,
            .mouseEnteredAndExited,
            .activeAlways,
            .inVisibleRect
        ]
        addTrackingArea(NSTrackingArea(rect: bounds, options: options, owner: self, userInfo: nil))
    }

    override func mouseMoved(with event: NSEvent) {
        super.mouseMoved(with: event)
        notifyPointerActivity(with: event, phase: .moved)
    }

    override func mouseEntered(with event: NSEvent) {
        super.mouseEntered(with: event)
        notifyPointerActivity(with: event, phase: .entered)
    }

    override func flagsChanged(with event: NSEvent) {
        super.flagsChanged(with: event)
        notifyPointerActivity(with: event, phase: .modifiersChanged)
    }

    override func menu(for event: NSEvent) -> NSMenu? {
        buildMenu()
    }

    private func notifyPointerActivity(with event: NSEvent, phase: PlayerPointerPhase) {
        let location = convert(event.locationInWindow, from: nil)
        onPointerActivity?(
            PlayerPointerActivity(
                location: location,
                modifiers: event.modifierFlags,
                phase: phase
            )
        )
    }

    private func buildMenu() -> NSMenu? {
        guard !menuItems.isEmpty else { return nil }

        let menu = NSMenu()
        menu.autoenablesItems = false
        let controller = MenuController(menu: menu)

        for item in menuItems {
            switch item {
            case .separator:
                menu.addItem(.separator())

            case .action(let title, let isEnabled, let action):
                let menuItem = NSMenuItem(title: title, action: #selector(contextMenuItemSelected(_:)), keyEquivalent: "")
                menuItem.target = self
                menuItem.representedObject = MenuActionBox(action: action)
                menuItem.isEnabled = isEnabled?() ?? true
                menu.addItem(menuItem)

            case .customView(let viewProvider):
                let menuItem = NSMenuItem()
                menuItem.view = viewProvider(controller)
                menu.addItem(menuItem)
            }
        }

        return menu
    }

    @objc
    private func contextMenuItemSelected(_ sender: NSMenuItem) {
        (sender.representedObject as? MenuActionBox)?.action()
    }
}

private final class MenuActionBox: NSObject {
    let action: () -> Void

    init(action: @escaping () -> Void) {
        self.action = action
    }
}
