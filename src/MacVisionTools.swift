//Copyright 2026 Ioannis Christofilogiannis
//
//Licensed under the Apache License, Version 2.0 (the "License");
//you may not use this file except in compliance with the License.
//You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
//Unless required by applicable law or agreed to in writing, software
//distributed under the License is distributed on an "AS IS" BASIS,
//WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//See the License for the specific language governing permissions and
//limitations under the License.

// MacVisionTools.swift
// App entry point and AppDelegate

import SwiftUI

@main
struct MacVisionToolsApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    var body: some Scene { Settings { EmptyView() } }
}

// MARK: - App Delegate
class AppDelegate: NSObject, NSApplicationDelegate, ObservableObject {
    var statusItem: NSStatusItem?
    var popover: NSPopover?
    var detectionManager: DetectionManager!
    var overlayWindow: OverlayWindow?
    var detectionWindowController: DetectionWindowController?
    var currentDisplayMode: DisplayMode = .window
    
    var emotionState = EmotionVibesState()
    var focusState = FocusTimerState()
    var privacyState = PrivacyGuardState()
    var modelPaths = ModelPathStorage()
    @Published var currentAppMode: AppMode = .standard
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        #if DEBUG
        if UserDefaults.standard.bool(forKey: "PerceptRenderScreenshots") {
            ScreenshotHarness.run()
            return
        }
        #endif

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "eye.circle", accessibilityDescription: "Percept")
            button.action = #selector(togglePopover); button.target = self
        }
        
        detectionManager = DetectionManager()
        detectionManager.focusState = focusState
        detectionManager.currentAppMode = currentAppMode
        detectionManager.onDetectionsUpdated = { [weak self] detections, frame, isFromCamera in
            DispatchQueue.main.async {
                self?.handleDetections(detections)
                self?.overlayWindow?.updateDetections(detections, isFromCamera: isFromCamera)
                self?.detectionWindowController?.updateContent(detections: detections, frame: frame, isFromCamera: isFromCamera)
            }
        }
        
        overlayWindow = OverlayWindow()
        detectionWindowController = DetectionWindowController()
        
        popover = NSPopover()
        popover?.contentSize = NSSize(width: 320, height: 560)
        popover?.behavior = .transient
        popover?.contentViewController = NSHostingController(
            rootView: ControlPanelView(
                manager: detectionManager, emotionState: emotionState, focusState: focusState,
                privacyState: privacyState, modelPaths: modelPaths, appDelegate: self,
                onDisplayModeChanged: { [weak self] mode in self?.handleDisplayModeChange(mode) },
                onSourceChanged: { [weak self] source, rate in self?.handleSourceChange(source, refreshRate: rate) }
            )
        )
        
        // Auto-load bundled model for default mode
        if let bundled = BundledModel.suggested(for: currentAppMode),
           !modelPaths.isUsingCustom(for: currentAppMode),
           let url = bundled.bundleURL {
            Task { await detectionManager.loadModel(from: url) }
        }
    }
    
    private func handleDetections(_ detections: [Detection]) {
        let filtered = detections.filter { d in !ignoredClasses.contains(where: { $0.lowercased() == d.className.lowercased() }) }
        
        switch currentAppMode {
        case .standard: break
        case .emotionVibes:
            if let top = filtered.first {
                emotionState.recordEmotion(top.className, confidence: top.confidence)
            }
        case .privacyGuard:
            privacyState.updatePersonCount(filtered.filter { $0.className.lowercased() == "person" }.count)
        case .focusTimer:
            // Native face tracking handles this in DetectionManager
            break
        }
    }
    
    func clearModeState() {
        emotionState.clear()
        privacyState.clear()
    }
    
    func updateStatusBarIcon() {
        statusItem?.button?.image = NSImage(systemSymbolName: currentAppMode.icon, accessibilityDescription: currentAppMode.rawValue)
    }
    
    @objc func togglePopover() {
        guard let button = statusItem?.button, let popover = popover else { return }
        if popover.isShown { popover.performClose(nil) }
        else { popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY); NSApp.activate(ignoringOtherApps: true) }
    }
    
    func handleDisplayModeChange(_ mode: DisplayMode) {
        currentDisplayMode = mode
        if mode == .overlay { detectionWindowController?.window?.orderOut(nil); overlayWindow?.orderFrontRegardless() }
        else { overlayWindow?.orderOut(nil); detectionWindowController?.showWindowed() }
    }
    
    func handleSourceChange(_ source: CaptureSource, refreshRate: RefreshRate) {
        if detectionManager.isRunning {
            detectionManager.stopDetection()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.handleDisplayModeChange(self.currentDisplayMode)
                self.detectionManager.startDetection(source: source, refreshRate: refreshRate)
            }
        }
    }
}

#if DEBUG
// MARK: - Screenshot Harness (Debug builds only)
// Renders the real ControlPanelView for each mode to PNGs for App Store/marketing assets.
// Run: open Percept.app --args -PerceptRenderScreenshots YES
// Output: ~/Library/Containers/<bundle id>/Data/Documents/screenshots/, or -PerceptScreenshotDir <path>
// (a custom path needs an unsandboxed build: xcodebuild ... CODE_SIGN_ENTITLEMENTS= ENABLE_APP_SANDBOX=NO)
@MainActor
enum ScreenshotHarness {
    static func run() {
        Task { @MainActor in
            let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let outDir = UserDefaults.standard.string(forKey: "PerceptScreenshotDir").map { URL(fileURLWithPath: $0, isDirectory: true) }
                ?? docs.appendingPathComponent("screenshots", isDirectory: true)
            try? FileManager.default.createDirectory(at: outDir, withIntermediateDirectories: true)
            for mode in AppMode.allCases {
                await render(mode: mode, to: outDir.appendingPathComponent("panel-\(slug(mode)).png"))
            }
            print("Screenshots written to \(outDir.path)")
            NSApp.terminate(nil)
        }
    }

    static func slug(_ mode: AppMode) -> String {
        switch mode { case .standard: return "standard"; case .emotionVibes: return "emotion"; case .privacyGuard: return "privacy"; case .focusTimer: return "focus" }
    }

    static func render(mode: AppMode, to url: URL) async {
        let manager = DetectionManager()
        manager.currentAppMode = mode
        let emotion = EmotionVibesState()
        let focus = FocusTimerState()
        let privacy = PrivacyGuardState()
        let paths = ModelPathStorage()
        paths.useBundled(for: mode)

        if mode == .focusTimer {
            manager.statusMessage = "Ready (Native Face Tracking)"
        } else if let url = BundledModel.suggested(for: mode)?.bundleURL {
            await manager.loadModel(from: url)
        }

        // Representative sample state so each mode's panel shows its live readout.
        switch mode {
        case .standard: break
        case .emotionVibes:
            for (label, conf) in [("Neutral", 0.71), ("Neutral", 0.66), ("Happy", 0.58), ("Happy", 0.81), ("Surprise", 0.52), ("Happy", 0.88), ("Happy", 0.9), ("Neutral", 0.6), ("Happy", 0.86)] {
                emotion.recordEmotion(label, confidence: Float(conf))
                try? await Task.sleep(nanoseconds: 2_000_000)
            }
        case .privacyGuard:
            privacy.isArmed = true
            privacy.updatePersonCount(1)
        case .focusTimer:
            focus.startSession()
            focus.currentFocusTime = 18 * 60 + 42
        }

        let view = ControlPanelView(
            manager: manager, emotionState: emotion, focusState: focus,
            privacyState: privacy, modelPaths: paths, appDelegate: nil,
            onDisplayModeChanged: { _ in }, onSourceChanged: { _, _ in },
            initialMode: mode
        )
        .background(Color(nsColor: NSColor(calibratedWhite: 0.16, alpha: 1)))
        .environment(\.colorScheme, .dark)

        let host = NSHostingView(rootView: view)
        host.frame = NSRect(x: 0, y: 0, width: 300, height: 560)
        let window = NSWindow(contentRect: host.frame, styleMask: [.borderless], backing: .buffered, defer: false)
        window.appearance = NSAppearance(named: .darkAqua)
        window.contentView = host
        window.setFrameOrigin(NSPoint(x: 40, y: 40))
        window.orderFrontRegardless()
        try? await Task.sleep(nanoseconds: 600_000_000)
        host.layoutSubtreeIfNeeded()
        host.display()

        guard let rep = host.bitmapImageRepForCachingDisplay(in: host.bounds) else { return }
        host.cacheDisplay(in: host.bounds, to: rep)
        try? rep.representation(using: .png, properties: [:])?.write(to: url)
        window.orderOut(nil)
    }
}
#endif
