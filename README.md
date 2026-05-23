# MacAVPlayerBridge

`MacAVPlayerBridge` gives SwiftUI apps a focused, reusable bridge to macOS `AVPlayerView`.

SwiftUI's built-in video APIs are convenient, but they do not expose much of the interaction surface that makes `AVPlayerView` useful in desktop apps. This package keeps a SwiftUI-first API while preserving AppKit features that matter in real macOS software:

- observe pointer movement with modifier flags
- configure `AVPlayerView` controls and playback chrome
- provide AppKit-native context menus, including embedded custom `NSView` menu content

## Why this exists

This package was extracted from techniques developed in Mosaic, a macOS video browsing app that needed richer interaction than SwiftUI provides on its own.

## Requirements

- macOS 13+
- Swift 6+

## Installation

Add the package to your Xcode project via **File → Add Package Dependencies… → Add Local…**, or declare it in `Package.swift` using a path relative to your consuming package:

```swift
.package(path: "../MacAVPlayerBridge")
```

## Demo App

The repo includes a small macOS sample app project at `Examples/MacAVPlayerBridgeDemo`.

Open `Examples/MacAVPlayerBridgeDemo/MacAVPlayerBridgeDemo.xcodeproj` in Xcode and run the `MacAVPlayerBridgeDemo` scheme.

The sample app lets you:

- open a local movie file with `NSOpenPanel`
- switch `AVPlayerView` control styles live
- inspect pointer activity and modifier flags
- exercise native AppKit context menu items, including a custom embedded menu view

## Usage

```swift
import SwiftUI
import AVKit
import MacAVPlayerBridge

struct PlayerSurface: View {
    let player: AVPlayer

    var body: some View {
        MacAVPlayerView(
            player: player,
            configuration: .init(
                controlsStyle: .floating,
                videoGravity: .resizeAspect,
                showsFullScreenToggleButton: true,
                showsFrameSteppingButtons: true,
                showsSharingServiceButton: true
            ),
            menuItems: [
                .item(title: "Pause") {
                    player.pause()
                },
                .separator,
                .customView(viewProvider: { controller in
                    let button = NSButton(title: "Close Menu", target: nil, action: nil)
                    button.target = ClosureSleeve {
                        controller?.closeMenu()
                    }
                    button.action = #selector(ClosureSleeve.invoke)
                    return button
                })
            ],
            onPointerActivity: { activity in
                if activity.modifiers.contains(.command) {
                    print("Pointer moved at \(activity.location)")
                }
            }
        )
    }
}
```

## API Overview

`MacAVPlayerView`

- wraps `AVPlayerView` in SwiftUI
- forwards pointer activity to SwiftUI
- supports native AppKit context menus

`MacAVPlayerConfiguration`

- control style
- video gravity
- fullscreen toggle button visibility
- frame stepping controls
- sharing button visibility
- now-playing center behavior
- video frame analysis toggle

`ContextMenuItem`

- separators
- action items with dynamic enabled state
- custom menu views backed by `NSView`

## Notes

Playback readiness is intentionally left to the host app. In practice that usually belongs closer to the player's `AVPlayerItem.status` or other app-specific loading policy than to the `AVPlayerView` bridge itself.
