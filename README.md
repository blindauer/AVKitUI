# AVKitUI

`AVKitUI` gives SwiftUI apps a focused, reusable bridge to macOS `AVPlayerView`.

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

Add the package to your Xcode project via **File → Add Package Dependencies…** and paste the repository URL, or declare it in `Package.swift`:

```swift
.package(url: "https://github.com/blindauer/AVKitUI.git", from: "0.1.0")
```

If you're developing the package alongside a consuming app, you can point Xcode at a local checkout via **Add Local…**, or in `Package.swift`:

```swift
.package(path: "../AVKitUI")
```

## Demo App

The repo includes a small macOS sample app project at `Examples/AVKitUIDemo`.

Open `Examples/AVKitUIDemo/AVKitUIDemo.xcodeproj` in Xcode and run the `AVKitUIDemo` scheme.

The sample app lets you:

- open a local movie file with `NSOpenPanel`
- switch `AVPlayerView` control styles live
- inspect pointer activity and modifier flags
- exercise native AppKit context menu items, including a custom embedded menu view

## Usage

```swift
import SwiftUI
import AVKit
import AVKitUI

struct PlayerSurface: View {
    let player: AVPlayer

    var body: some View {
        PlayerView(player: player)
            .controlsStyle(.floating)
            .videoGravity(.resizeAspect)
            .contextMenuItems([
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
            ])
            .onPointerActivity { activity in
                if activity.modifiers.contains(.command) {
                    print("Pointer moved at \(activity.location)")
                }
            }
    }
}
```

Every modifier has a sensible default, so a minimal call site is just `PlayerView(player: player)`. Chain only the modifiers you need to override.

## API Overview

`PlayerView`

- wraps `AVPlayerView` in SwiftUI
- forwards pointer activity to SwiftUI
- supports native AppKit context menus

Modifiers on `PlayerView`:

- `.controlsStyle(_:)` — playback control style (default `.floating`)
- `.videoGravity(_:)` — layer gravity (default `.resizeAspect`)
- `.showsFullScreenToggleButton(_:)` — default `true`
- `.showsFrameSteppingButtons(_:)` — default `true`
- `.showsSharingServiceButton(_:)` — default `true`
- `.updatesNowPlayingInfoCenter(_:)` — default `false`
- `.allowsVideoFrameAnalysis(_:)` — default `false`
- `.contextMenuItems(_:)` — items shown in the AppKit context menu
- `.onPointerActivity(_:)` — closure invoked on pointer activity inside the player

`ContextMenuItem`

- separators
- action items with dynamic enabled state
- custom menu views backed by `NSView`

## Notes

Playback readiness is intentionally left to the host app. In practice that usually belongs closer to the player's `AVPlayerItem.status` or other app-specific loading policy than to the `AVPlayerView` bridge itself.
