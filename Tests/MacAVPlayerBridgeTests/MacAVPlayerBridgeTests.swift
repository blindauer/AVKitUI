import AVKit
import Testing
@testable import MacAVPlayerBridge

@Test
func defaultConfigurationMatchesPackageIntent() {
    let configuration = MacAVPlayerConfiguration()

    #expect(configuration.controlsStyle == .floating)
    #expect(configuration.videoGravity == .resizeAspect)
    #expect(configuration.showsFullScreenToggleButton)
    #expect(configuration.showsFrameSteppingButtons)
    #expect(configuration.showsSharingServiceButton)
    #expect(configuration.updatesNowPlayingInfoCenter == false)
    #expect(configuration.allowsVideoFrameAnalysis == false)
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
func macAVPlayerViewInitializerDoesNotRequireReadinessBinding() {
    let player = AVPlayer()
    _ = MacAVPlayerView(player: player)
    #expect(Bool(true))
}
