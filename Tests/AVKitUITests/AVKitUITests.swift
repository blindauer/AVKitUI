import AVKit
import Testing
@testable import AVKitUI

@MainActor
@Test
func defaultModifierValuesMatchPackageIntent() {
    let view = PlayerView(player: AVPlayer())

    #expect(view.controlsStyle == .floating)
    #expect(view.videoGravity == .resizeAspect)
    #expect(view.showsFullScreenToggleButton)
    #expect(view.showsFrameSteppingButtons)
    #expect(view.showsSharingServiceButton)
    #expect(view.updatesNowPlayingInfoCenter == false)
    #expect(view.allowsVideoFrameAnalysis == false)
}

@MainActor
@Test
func modifiersOverrideDefaults() {
    let view = PlayerView(player: AVPlayer())
        .controlsStyle(.inline)
        .videoGravity(.resizeAspectFill)
        .showsFullScreenToggleButton(false)
        .updatesNowPlayingInfoCenter(true)

    #expect(view.controlsStyle == .inline)
    #expect(view.videoGravity == .resizeAspectFill)
    #expect(view.showsFullScreenToggleButton == false)
    #expect(view.updatesNowPlayingInfoCenter)
    // Unchanged values keep their defaults.
    #expect(view.showsFrameSteppingButtons)
}

@Test
func actionMenuItemsCanBeConstructedWithDynamicEnabledState() {
    let item = ContextMenuItem.item(
        title: "Pause",
        isEnabled: { false },
        action: {}
    )

    switch item {
    case .action(let title, let isEnabled, _):
        #expect(title == "Pause")
        #expect(isEnabled?() == false)
    default:
        Issue.record("Expected an action menu item")
    }
}

@MainActor
@Test
func customViewMenuItemsCanBeConstructed() {
    let item = ContextMenuItem.customView(viewProvider: { _ in
        NSView(frame: .zero)
    })

    switch item {
    case .customView(let viewProvider):
        let controller: (any PlayerContextMenuControlling)? = nil
        _ = viewProvider(controller)
        #expect(Bool(true))
    default:
        Issue.record("Expected a custom view menu item")
    }
}

@MainActor
@Test
func playerViewInitializerDoesNotRequireReadinessBinding() {
    let player = AVPlayer()
    _ = PlayerView(player: player)
    #expect(Bool(true))
}
