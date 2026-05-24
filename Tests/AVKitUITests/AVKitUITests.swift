//
//  AVKitUITests.swift
//  AVKitUITexts
//
//  Created by Bradley Lindauer on 5/23/26.
//

import AVKit
import AppKit
import SwiftUI
import Testing
@testable import AVKitUI

// MARK: - Defaults & modifier semantics

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
func chainedModifiersAreLastWriteWins() {
    let view = PlayerView(player: AVPlayer())
        .controlsStyle(.inline)
        .controlsStyle(.floating)

    #expect(view.controlsStyle == .floating)
}

// MARK: - End-to-end modifier application

@MainActor
@Test
func modifierValuesPropagateToUnderlyingAVPlayerView() {
    let nsView = PlayerNSView()

    PlayerView(player: AVPlayer())
        .controlsStyle(.inline)
        .videoGravity(.resizeAspectFill)
        .showsFullScreenToggleButton(false)
        .showsFrameSteppingButtons(false)
        .showsSharingServiceButton(false)
        .updatesNowPlayingInfoCenter(true)
        .allowsVideoFrameAnalysis(true)
        .apply(to: nsView)

    #expect(nsView.controlsStyle == .inline)
    #expect(nsView.videoGravity == .resizeAspectFill)
    #expect(nsView.showsFullScreenToggleButton == false)
    #expect(nsView.showsFrameSteppingButtons == false)
    #expect(nsView.showsSharingServiceButton == false)
    #expect(nsView.updatesNowPlayingInfoCenter)
    #expect(nsView.allowsVideoFrameAnalysis)
}

@MainActor
@Test
func reapplyingOverwritesPreviousValues() {
    let nsView = PlayerNSView()

    PlayerView(player: AVPlayer())
        .controlsStyle(.inline)
        .videoGravity(.resizeAspectFill)
        .apply(to: nsView)

    #expect(nsView.controlsStyle == .inline)
    #expect(nsView.videoGravity == .resizeAspectFill)

    PlayerView(player: AVPlayer())
        .controlsStyle(.floating)
        .videoGravity(.resize)
        .apply(to: nsView)

    #expect(nsView.controlsStyle == .floating)
    #expect(nsView.videoGravity == .resize)
}

// MARK: - Menu building

@MainActor
@Test
func menuBuildingTranslatesAllItemKinds() throws {
    let nsView = PlayerNSView()
    nsView.menuItems = [
        .item(title: "Play", action: {}),
        .item(title: "Disabled", isEnabled: { false }, action: {}),
        .separator,
        .customView(viewProvider: { _ in NSView(frame: .zero) })
    ]

    let menu = try #require(nsView.buildMenu())
    #expect(menu.items.count == 4)

    #expect(menu.items[0].title == "Play")
    #expect(menu.items[0].isEnabled)
    #expect(menu.items[0].target === nsView)

    #expect(menu.items[1].title == "Disabled")
    #expect(menu.items[1].isEnabled == false)

    #expect(menu.items[2].isSeparatorItem)

    #expect(menu.items[3].view != nil)
}

@MainActor
@Test
func emptyMenuItemsReturnsNilMenu() {
    let nsView = PlayerNSView()
    // menuItems defaults to []
    #expect(nsView.buildMenu() == nil)
}

@MainActor
@Test
func selectingActionMenuItemInvokesItsClosure() throws {
    let fired = Box(false)
    let nsView = PlayerNSView()
    nsView.menuItems = [
        .item(title: "Fire") { fired.value = true }
    ]

    let menu = try #require(nsView.buildMenu())
    let item = try #require(menu.items.first)
    let target = try #require(item.target as? NSObject)
    let action = try #require(item.action)

    _ = target.perform(action, with: item)

    #expect(fired.value)
}

// MARK: - SwiftUI lifecycle

@MainActor
@Test
func swiftUILifecycleProducesConfiguredNSView() throws {
    let view = PlayerView(player: AVPlayer())
        .controlsStyle(.inline)
        .videoGravity(.resizeAspectFill)
        .showsFullScreenToggleButton(false)

    let hosting = NSHostingView(rootView: view)
    hosting.frame = NSRect(x: 0, y: 0, width: 200, height: 100)
    hosting.layoutSubtreeIfNeeded()

    // Walks past whatever SwiftUI wraps the representable in to find the NSView our
    // makeNSView returned. This proves the SwiftUI -> NSViewRepresentable wiring
    // actually instantiates and configures a PlayerNSView.
    let nsView = try #require(findDescendant(of: hosting, ofType: PlayerNSView.self))
    #expect(nsView.controlsStyle == .inline)
    #expect(nsView.videoGravity == .resizeAspectFill)
    #expect(nsView.showsFullScreenToggleButton == false)
}

// MARK: - Pointer activity translation

@MainActor
@Test
func mouseMovedTranslatesToMovedPointerActivity() throws {
    let captured = ActivityCapture()
    let nsView = PlayerNSView(frame: NSRect(x: 0, y: 0, width: 200, height: 100))
    nsView.onPointerActivity = { activity in
        captured.activity = activity
    }

    let event = try #require(makeMouseEvent(
        type: .mouseMoved,
        location: NSPoint(x: 50, y: 25),
        modifiers: [.command, .shift]
    ))
    nsView.notifyPointerActivity(with: event, phase: .moved)

    let activity = try #require(captured.activity)
    #expect(activity.phase == .moved)
    #expect(activity.modifiers.contains(.command))
    #expect(activity.modifiers.contains(.shift))
}

@MainActor
@Test
func mouseExitedTranslatesToExitedPointerActivity() throws {
    let captured = ActivityCapture()
    let nsView = PlayerNSView()
    nsView.onPointerActivity = { activity in
        captured.activity = activity
    }

    // NSEvent.mouseEvent does not synthesize enter/exit events, but notifyPointerActivity
    // only reads location + modifierFlags from the event — phase comes from the call site.
    let event = try #require(makeMouseEvent(
        type: .mouseMoved,
        location: .zero,
        modifiers: []
    ))
    nsView.notifyPointerActivity(with: event, phase: .exited)

    let activity = try #require(captured.activity)
    #expect(activity.phase == .exited)
    #expect(activity.modifiers.isEmpty)
}

// MARK: - Test helpers

private final class Box<Value>: @unchecked Sendable {
    var value: Value
    init(_ value: Value) { self.value = value }
}

private final class ActivityCapture: @unchecked Sendable {
    var activity: PlayerPointerActivity?
}

@MainActor
private func findDescendant<T: NSView>(of view: NSView, ofType: T.Type) -> T? {
    if let match = view as? T { return match }
    for subview in view.subviews {
        if let match = findDescendant(of: subview, ofType: ofType) {
            return match
        }
    }
    return nil
}

@MainActor
private func makeMouseEvent(
    type: NSEvent.EventType,
    location: NSPoint,
    modifiers: NSEvent.ModifierFlags
) -> NSEvent? {
    NSEvent.mouseEvent(
        with: type,
        location: location,
        modifierFlags: modifiers,
        timestamp: 0,
        windowNumber: 0,
        context: nil,
        eventNumber: 0,
        clickCount: 0,
        pressure: 0
    )
}
