//
//  PlayerView.swift
//  AVKitUI
//
//  Created by Bradley Lindauer on 5/23/26.
//

import SwiftUI
import AVKit

#if os(macOS)
import AppKit

public struct PlayerView: NSViewRepresentable {
    public let player: AVPlayer

    var controlsStyle: AVPlayerViewControlsStyle = .floating
    var videoGravity: AVLayerVideoGravity = .resizeAspect
    var showsFullScreenToggleButton: Bool = true
    var showsFrameSteppingButtons: Bool = true
    var showsSharingServiceButton: Bool = true
    var updatesNowPlayingInfoCenter: Bool = false
    var allowsVideoFrameAnalysis: Bool = false
    var contextMenuItems: [ContextMenuItem] = []
    var onPointerActivity: (@MainActor @Sendable (PlayerPointerActivity) -> Void)?
    var onPrimaryClick: (@MainActor @Sendable (PlayerPointerActivity) -> Void)?

    public init(player: AVPlayer) {
        self.player = player
    }

    public func makeNSView(context: Context) -> AVPlayerView {
        let view = PlayerNSView()
        apply(to: view)
        return view
    }

    public func updateNSView(_ nsView: AVPlayerView, context: Context) {
        guard let view = nsView as? PlayerNSView else { return }
        apply(to: view)
    }

    func apply(to view: PlayerNSView) {
        view.player = player
        view.controlsStyle = controlsStyle
        view.videoGravity = videoGravity
        view.menuItems = contextMenuItems
        view.onPointerActivity = onPointerActivity
        view.onPrimaryClick = onPrimaryClick
        view.showsFullScreenToggleButton = showsFullScreenToggleButton
        view.showsFrameSteppingButtons = showsFrameSteppingButtons
        view.showsSharingServiceButton = showsSharingServiceButton
        view.updatesNowPlayingInfoCenter = updatesNowPlayingInfoCenter
        if #available(macOS 13.0, *) {
            view.allowsVideoFrameAnalysis = allowsVideoFrameAnalysis
        }
    }
}

// MARK: - Modifiers

public extension PlayerView {
    func controlsStyle(_ style: AVPlayerViewControlsStyle) -> Self {
        var copy = self
        copy.controlsStyle = style
        return copy
    }

    func videoGravity(_ gravity: AVLayerVideoGravity) -> Self {
        var copy = self
        copy.videoGravity = gravity
        return copy
    }

    func showsFullScreenToggleButton(_ shows: Bool) -> Self {
        var copy = self
        copy.showsFullScreenToggleButton = shows
        return copy
    }

    func showsFrameSteppingButtons(_ shows: Bool) -> Self {
        var copy = self
        copy.showsFrameSteppingButtons = shows
        return copy
    }

    func showsSharingServiceButton(_ shows: Bool) -> Self {
        var copy = self
        copy.showsSharingServiceButton = shows
        return copy
    }

    func updatesNowPlayingInfoCenter(_ updates: Bool) -> Self {
        var copy = self
        copy.updatesNowPlayingInfoCenter = updates
        return copy
    }

    func allowsVideoFrameAnalysis(_ allows: Bool) -> Self {
        var copy = self
        copy.allowsVideoFrameAnalysis = allows
        return copy
    }

    func contextMenuItems(_ items: [ContextMenuItem]) -> Self {
        var copy = self
        copy.contextMenuItems = items
        return copy
    }

    func onPointerActivity(_ handler: @escaping @MainActor @Sendable (PlayerPointerActivity) -> Void) -> Self {
        var copy = self
        copy.onPointerActivity = handler
        return copy
    }

    /// Fires for single clicks on the video surface. Clicks on the playback controls
    /// (the floating bar, its buttons and sliders) are filtered out by hit-testing
    /// and behave normally.
    func onPrimaryClick(_ handler: @escaping @MainActor @Sendable (PlayerPointerActivity) -> Void) -> Self {
        var copy = self
        copy.onPrimaryClick = handler
        return copy
    }
}

final class PlayerNSView: AVPlayerView, NSGestureRecognizerDelegate {
    var menuItems: [ContextMenuItem] = []
    var onPointerActivity: (@MainActor @Sendable (PlayerPointerActivity) -> Void)?
    var onPrimaryClick: (@MainActor @Sendable (PlayerPointerActivity) -> Void)?

    private var clickRecognizer: NSClickGestureRecognizer?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)

        // AVPlayerView's internal content view consumes mouseDown, so a plain
        // override never sees clicks. A gesture recognizer observes events routed
        // to descendants; the delegate filters out clicks on the controls.
        let click = NSClickGestureRecognizer(target: self, action: #selector(handlePrimaryClick(_:)))
        click.numberOfClicksRequired = 1
        click.delegate = self
        addGestureRecognizer(click)
        clickRecognizer = click
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

    override func mouseExited(with event: NSEvent) {
        super.mouseExited(with: event)
        notifyPointerActivity(with: event, phase: .exited)
    }

    override func flagsChanged(with event: NSEvent) {
        super.flagsChanged(with: event)
        notifyPointerActivity(with: event, phase: .modifiersChanged)
    }

    func gestureRecognizer(_ gestureRecognizer: NSGestureRecognizer, shouldAttemptToRecognizeWith event: NSEvent) -> Bool {
        guard gestureRecognizer === clickRecognizer else { return true }
        guard onPrimaryClick != nil else { return false }
        return clickLandsOnVideoSurface(event)
    }

    @objc
    private func handlePrimaryClick(_ recognizer: NSClickGestureRecognizer) {
        guard recognizer.state == .ended else { return }
        onPrimaryClick?(
            PlayerPointerActivity(
                location: recognizer.location(in: self),
                modifiers: NSApp.currentEvent?.modifierFlags ?? [],
                phase: .clicked
            )
        )
    }

    /// True when the click hits the bare video surface rather than the playback
    /// controls, so control clicks keep their normal behavior.
    private func clickLandsOnVideoSurface(_ event: NSEvent) -> Bool {
        guard let superview else { return false }
        let hit = hitTest(superview.convert(event.locationInWindow, from: nil))
        var view = hit
        while let current = view, current !== self {
            if isControlsChrome(current) { return false }
            view = current.superview
        }
        // nil means the hit view wasn't inside our hierarchy at all.
        return view === self
    }

    /// Identifies the playback controls and their chrome. The buttons and scrubber
    /// are NSControls; AVKit's container class names mention "control"; and the
    /// floating bar itself is an AVMovableView whose background is glass/effect
    /// views, so those are matched by name. (Observed bar-background hit chain:
    /// NSView -> NSGlassEffectView ContentHolder -> NSGlassView ->
    /// NSGlassContainerView -> AVMovableView -> AVEventPassthroughView -> ...)
    private func isControlsChrome(_ view: NSView) -> Bool {
        if view is NSControl { return true }
        if view is NSVisualEffectView { return true }
        let name = view.className.lowercased()
        return name.contains("control")
            || name.contains("chrome")
            || name.contains("backdrop")
            || name.contains("glass")
            || name.contains("visualeffect")
            || name.contains("movable")
    }

    override func menu(for event: NSEvent) -> NSMenu? {
        buildMenu()
    }

    func notifyPointerActivity(with event: NSEvent, phase: PlayerPointerPhase) {
        let location = convert(event.locationInWindow, from: nil)
        onPointerActivity?(
            PlayerPointerActivity(
                location: location,
                modifiers: event.modifierFlags,
                phase: phase
            )
        )
    }

    func buildMenu() -> NSMenu? {
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

#endif
