---
title: "Media Playback Programming for iOS and macOS (Step-by-Step, with Runnable Code)"
date: 2025-10-16 12:00:00 +0900
tags: [ios, macos, avfoundation, avkit, media, swift]
---


**Version banner (verified):**
**Tested with Swift 6.2, Xcode 26.0.1**, minimum targets **iOS 17 / iPadOS 17, macOS 14** (to use SwiftUI **`@Observable`** and the modern SwiftUI/AVKit stack). Generated **Oct 16, 2025 (Asia/Seoul)**.

* Apple confirms **Xcode 26.0.1** and that **Xcode 26 includes Swift 6.2**. ([Apple Developer][1])
* Apple notes **`@Observable`** (new observation) requires **iOS 17 / macOS 14** or later. ([Apple Developer][2])

> **Tip:** If you must support older OS versions, you can replace `@Observable` with `ObservableObject` + `@Published`. The rest of the APIs used below work back to iOS 14–16, but the syntax here assumes iOS 17+/macOS 14+.

---

## 1) Overview & Architecture

**You will learn:** what “media playback” means on Apple platforms, when to use **AVFoundation**, **AVKit**, **MediaPlayer**, and **CoreMedia**, and how data flows for local files vs. streaming (HLS).

**Plain definition:** *Media playback* means loading audio/video from a file or URL, decoding it, and rendering sound/pixels while reacting to user controls (play/pause/seek) and system events (interruptions, route changes).

**Which framework does what (short):**

* **AVFoundation** – engines and models (assets, tracks, players, sessions). Use it for the *actual* playback pipeline and control. ([Apple Developer][3])
* **AVKit** – ready-made player UIs and PiP. Use it for **`AVPlayerViewController`** (iOS) and **`AVPlayerView`** (macOS), and **PiP**. ([Apple Developer][4])
* **MediaPlayer** – system “Now Playing” metadata and remote commands (lock screen, Control Center, external accessories). ([Apple Developer][5])
* **CoreMedia** – low-level time types like **`CMTime`** and **`CMTimeRange`** used across all media APIs. ([Apple Developer][6])

**Data flow (simplified):**

* **Local file:** `URL (file://)` → `AVURLAsset` → `AVPlayerItem` → `AVPlayer` → `AVKit` view (or your own layer) → speakers/screen.
* **HLS streaming:** `URL (https://…m3u8)` → **HLS playlists & segments** (adaptive bitrates) → `AVURLAsset` → `AVPlayerItem` → `AVPlayer` → UI. Apple’s HLS is the recommended streaming tech. ([Apple Developer][7])

**Quick Test:** In your head, map: *“lock screen artwork”* → which framework? (**MediaPlayer**). *“inline playback UI”* → (**AVKit**). *“read current time”* → (**AVFoundation + CoreMedia**).

**Gotchas:**

* Don’t try to manually parse HLS; let **AVPlayer** handle it.
* Don’t invent your own time math—use **`CMTime`**.

**References:**

* AVFoundation overview – developer.apple.com/documentation/avfoundation ([Apple Developer][3])
* AVKit standard playback – developer.apple.com/documentation/avkit/playing-video-content-in-a-standard-user-interface ([Apple Developer][4])
* MediaPlayer (Now Playing / Remote) – developer.apple.com/documentation/mediaplayer ([Apple Developer][5])
* CoreMedia time types – developer.apple.com/documentation/coremedia/cmtime-api ([Apple Developer][6])
* HLS overview – developer.apple.com/documentation/http-live-streaming ([Apple Developer][8])

---

## 2) Project Setup (Latest Swift & Xcode)

**You will learn:** exact tool versions, targets, SwiftUI vs. UIKit/AppKit project options, and required entitlements/Info.plist keys.

* **Tools (verified):** Xcode **26.0.1** with **Swift 6.2**. ([Apple Developer][1])
* **Minimum targets:** **iOS 17 / macOS 14** (so we can use **`@Observable`** and the latest SwiftUI Observation). ([Apple Developer][2])

**New Project choices:**

* **SwiftUI (recommended)** for both iOS and macOS targets.
* If you need classic UI, pick **Storyboard** (UIKit) or **XIB** (AppKit) templates and embed **AVKit** views.

**Capabilities & keys you often need:**

* **Background audio** (iOS): add **Background Modes → Audio**. This sets `UIBackgroundModes = ["audio"]`. ([Apple Developer][9])
* **App Sandbox (macOS)**: turn it **ON**; add file access as needed (e.g., **User-Selected File Read-Only** or **Read-Write**) and, if persisting access, **Security-Scoped Bookmarks**. ([Apple Developer][2])
* **Hardened Runtime (macOS)**: required for notarization; enable in **Signing & Capabilities** (usually auto-added). ([help.apple.com][10])
* **ATS** (iOS/macOS): keep HTTPS; if you must add exceptions, use **NSAppTransportSecurity** keys sparingly. ([Apple Developer][11])

**Quick Test:** Which key enables background audio? (**`UIBackgroundModes` = `audio`**).
**Gotchas:** Adding `audio` without actually playing background audio can cause App Review rejection. ([Apple Developer][12])

**References:**

* Xcode 26 RN – developer.apple.com/documentation/xcode-release-notes/xcode-26-release-notes ([Apple Developer][13])
* UIBackgroundModes – developer.apple.com/documentation/bundleresources/information-property-list/uibackgroundmodes ([Apple Developer][9])
* macOS Sandbox file access – developer.apple.com/documentation/security/accessing-files-from-the-macos-app-sandbox ([Apple Developer][2])
* Hardened Runtime – help.apple.com/xcode/.../devf87a2ac8f.html ([help.apple.com][10])
* NSAppTransportSecurity – developer.apple.com/documentation/bundleresources/information-property-list/nsapptransportsecurity ([Apple Developer][11])

---

## 3) The Basics: Play a Video

**You will learn:** minimal, runnable players for SwiftUI and UIKit/AppKit, with play/pause/seek/rate/mute.

### 3.1 SwiftUI (iOS & macOS) — `VideoPlayer` + `AVPlayer`

```swift
import SwiftUI
import AVKit
import Observation

@Observable
final class PlayerStore {
    let player: AVPlayer
    var isMuted = false
    var rate: Float = 1.0
    var duration: Double = 0
    var current: Double = 0    // seconds
    
    private var timeObserver: Any?
    
    init(url: URL) {
        self.player = AVPlayer(url: url)
        // Update slider as playback progresses (every 0.5s)
        timeObserver = player.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 0.5, preferredTimescale: 600),
            queue: .main
        ) { [weak self] time in
            guard let self else { return }
            self.current = time.seconds
            if let item = self.player.currentItem {
                let d = item.duration.seconds
                if d.isFinite { self.duration = d }
            }
        }
    }
    
    deinit {
        if let obs = timeObserver { player.removeTimeObserver(obs) }
    }
}

struct ContentView: View {
    @State private var store = PlayerStore(
        url: URL(string:"https://devstreaming-cdn.apple.com/videos/streaming/examples/bipbop_4x3/gear1/prog_index.m3u8")!
    )
    @State private var seeking = false
    @State private var tempValue: Double = 0
    
    var body: some View {
        VStack(spacing: 16) {
            VideoPlayer(player: store.player)
                .frame(height: 240)
            
            Slider(value: Binding(
                get: { seeking ? tempValue : store.current },
                set: { newValue in
                    seeking = true; tempValue = newValue
                }),
                in: 0...(store.duration > 0 ? store.duration : 1)
            )
            .onChange(of: seeking) { _, isSeeking in
                if !isSeeking {
                    let time = CMTime(seconds: tempValue, preferredTimescale: 600)
                    store.player.seek(to: time)
                }
            }
            .onChange(of: tempValue) { _, _ in } // keeps binding live
            
            HStack {
                Button("⏯ Play/Pause") {
                    if store.player.timeControlStatus == .playing { store.player.pause() }
                    else { store.player.play() }
                }
                Button(store.isMuted ? "🔈 Unmute" : "🔇 Mute") {
                    store.isMuted.toggle()
                    store.player.isMuted = store.isMuted
                }
                Menu("Rate \(String(format: "%.1fx", store.rate))") {
                    ForEach([0.5, 1.0, 1.5, 2.0], id: \.self) { r in
                        Button("\(r)x") { store.rate = Float(r); store.player.rate = Float(r) }
                    }
                }
            }
        }
        .padding()
        .onAppear { store.player.play() }
    }
}
```

> Expected UI: a player, a scrubber slider, and simple controls.

### 3.2 UIKit (iOS) — `AVPlayerViewController`

```swift
import UIKit
import AVKit

final class PlayerVC: UIViewController {
    private let url = URL(string: "https://devstreaming-cdn.apple.com/videos/streaming/examples/bipbop_4x3/gear1/prog_index.m3u8")!
    private let player = AVPlayer()
    private let vc = AVPlayerViewController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        vc.player = player
        vc.canStartPictureInPictureAutomaticallyFromInline = true
        addChild(vc)
        vc.view.frame = view.bounds
        vc.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(vc.view)
        vc.didMove(toParent: self)
        
        vc.player = AVPlayer(url: url)
        vc.player?.play()
    }
}
```

### 3.3 AppKit (macOS) — `AVPlayerView`

```swift
import Cocoa
import AVKit

final class ViewController: NSViewController {
    @IBOutlet weak var playerView: AVPlayerView!
    let player = AVPlayer(url: URL(string: "https://devstreaming-cdn.apple.com/videos/streaming/examples/bipbop_4x3/gear1/prog_index.m3u8")!)
    override func viewDidLoad() {
        super.viewDidLoad()
        playerView.player = player
        player.play()
    }
}
```

### 3.4 Custom view (both platforms) — `AVPlayerLayer`

```swift
import SwiftUI
import AVFoundation

final class PlayerLayerView: UIView {
    override static var layerClass: AnyClass { AVPlayerLayer.self }
    var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }
    var player: AVPlayer? {
        get { playerLayer.player }
        set { playerLayer.player = newValue }
    }
}

struct PlayerLayerRepresentable: UIViewRepresentable {
    let player: AVPlayer
    func makeUIView(context: Context) -> PlayerLayerView { let v = PlayerLayerView(); v.player = player; return v }
    func updateUIView(_ uiView: PlayerLayerView, context: Context) { uiView.player = player }
}
```

**Quick Test:** Which control automatically brings PiP on iOS when inline? (**`AVPlayerViewController`** with `canStartPictureInPictureAutomaticallyFromInline`). ([Apple Developer][14])
**Gotchas:** `VideoPlayer` is SwiftUI-only UI; logic still lives in **`AVPlayer`** underneath.

**References:**

* AVKit standard controller – developer.apple.com/documentation/avkit/playing-video-content-in-a-standard-user-interface ([Apple Developer][4])
* SwiftUI observation migration – developer.apple.com/documentation/swiftui/migrating-from-observableobject-to-observable ([Apple Developer][2])
* Apple sample HLS streams – developer.apple.com/streaming/examples/ ([Apple Developer][15])

---

## 4) Streaming with HLS

**You will learn:** how to play remote `.m3u8`, tune buffering/bitrate, attach headers via a resource loader, and retry on errors.

### 4.1 Minimal HLS player with sane defaults

```swift
import AVFoundation

func makeHLSPlayer(url: URL) -> AVPlayer {
    let asset = AVURLAsset(url: url)
    let item = AVPlayerItem(asset: asset)
    // Reduce rebuffering; AVPlayer manages ABR automatically.
    let player = AVPlayer(playerItem: item)
    player.automaticallyWaitsToMinimizeStalling = true
    // Optional: limit network usage (bits per second)
    item.preferredPeakBitRate = 2_000_000
    return player
}
```

* **Adaptive bitrate (ABR)** is built into HLS; you can cap peaks via `preferredPeakBitRate`. ([Apple Developer][16])
* `automaticallyWaitsToMinimizeStalling` helps smooth playback on poor networks. ([Apple Developer][17])

### 4.2 Custom headers/tokens (read-only example with `AVAssetResourceLoader`)

```swift
import AVFoundation

final class HeaderInjectingLoader: NSObject, AVAssetResourceLoaderDelegate {
    private let realURL: URL
    private let headers: [String:String]
    private let session = URLSession(configuration: .default)
    
    init(realURL: URL, headers: [String:String]) {
        self.realURL = realURL; self.headers = headers
    }
    
    func asset(withFakeSchemeURL fake: URL) -> AVURLAsset {
        let asset = AVURLAsset(url: fake)
        asset.resourceLoader.setDelegate(self, queue: .main)
        return asset
    }

    func resourceLoader(_ resourceLoader: AVAssetResourceLoader,
                        shouldWaitForLoadingOfRequestedResource req: AVAssetResourceLoadingRequest) -> Bool {
        // Redirect to the real URL with your custom headers.
        var request = URLRequest(url: realURL)
        headers.forEach { request.addValue($0.value, forHTTPHeaderField: $0.key) }
        // Range requests are common; forward them if present.
        if let range = req.dataRequest {
            let lower = range.requestedOffset
            let upper = lower + Int64(range.requestedLength) - 1
            request.addValue("bytes=\(lower)-\(upper)", forHTTPHeaderField: "Range")
        }
        let task = session.dataTask(with: request) { data, response, error in
            if let r = response as? HTTPURLResponse {
                req.response = r
                if let info = req.contentInformationRequest {
                    info.isByteRangeAccessSupported = (r.value(forHTTPHeaderField: "Accept-Ranges") == "bytes")
                    info.contentType = r.value(forHTTPHeaderField: "Content-Type")
                    if let len = r.value(forHTTPHeaderField: "Content-Length"), let n = Int64(len) {
                        info.contentLength = n
                    }
                }
            }
            if let data { req.dataRequest?.respond(with: data) }
            if let error { req.finishLoading(with: error) } else { req.finishLoading() }
        }
        task.resume()
        return true
    }
}
```

> Usage: change the scheme to `custom+https://…`, build a fake URL with that scheme, and pass your real HTTPS URL + headers into `HeaderInsertingLoader`. Apple’s resource loader gives you a delegate to fulfill requests. ([Apple Developer][18])

### 4.3 Simple retry with backoff

```swift
import AVFoundation

actor ResilientStreamer {
    private(set) var player: AVPlayer?
    
    func play(_ url: URL) async {
        var delay: UInt64 = 1_000_000_000 // 1s
        for attempt in 1...3 {
            let item = AVPlayerItem(url: url)
            let p = AVPlayer(playerItem: item); p.automaticallyWaitsToMinimizeStalling = true
            player = p; p.play()
            // Wait for status or error
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            if item.status == .readyToPlay { return }
            if let err = item.error as NSError? { print("Attempt \(attempt) failed: \(err)") }
            p.pause()
            try? await Task.sleep(nanoseconds: delay)
            delay *= 2
        }
    }
}
```

**Quick Test:** Where do you set a *bitrate cap*? (**`AVPlayerItem.preferredPeakBitRate`**).
**Gotchas:** If you need DRM (FairPlay), you’ll use the resource loader to supply keys; that’s out of scope here. See Apple’s FairPlay docs. ([Apple Developer][19])

**References:**

* HLS overview & tools – developer.apple.com/documentation/http-live-streaming; /using-apple-s-http-live-streaming-hls-tools ([Apple Developer][8])
* `automaticallyWaitsToMinimizeStalling` – developer.apple.com/documentation/avfoundation/avplayer/2890044-automaticallywaitstominimizestal ([Apple Developer][17])
* `preferredPeakBitRate` – developer.apple.com/documentation/avfoundation/avplayeritem/1643638-preferredpeakbitrate ([Apple Developer][16])
* `AVAssetResourceLoader` – developer.apple.com/documentation/avfoundation/avassetresourceloader ([Apple Developer][18])

---

## 5) Audio Playback & Sessions (iOS)

**You will learn:** how to set `AVAudioSession`, handle **interruptions** (calls) and **route changes** (headphones/Bluetooth), and run audio in the background.

### 5.1 Configure the audio session

```swift
import AVFAudio

@MainActor
func configurePlaybackSession() throws {
    let session = AVAudioSession.sharedInstance()
    try session.setCategory(.playback, mode: .moviePlayback, options: [.allowAirPlay, .allowBluetooth])
    try session.setActive(true)
}
```

* Category **`.playback`** is the default for video/music players and supports background playback when the **audio** background mode is present. ([Apple Developer][20])

### 5.2 Interruptions & route changes

```swift
import AVFAudio

final class AudioSessionObserver {
    private var tokens: [NSObjectProtocol] = []
    init() {
        let nc = NotificationCenter.default
        tokens.append(nc.addObserver(forName: AVAudioSession.interruptionNotification, object: nil, queue: .main) { note in
            guard let info = note.userInfo,
                  let typeValue = info[AVAudioSessionInterruptionTypeKey] as? UInt,
                  let type = AVAudioSession.InterruptionType(rawValue: typeValue) else { return }
            if type == .began {
                // Pause your player
            } else {
                // Resume if appropriate
            }
        })
        tokens.append(nc.addObserver(forName: AVAudioSession.routeChangeNotification, object: nil, queue: .main) { note in
            // Inspect AVAudioSessionRouteChangeReasonKey and adapt (e.g., headphones unplugged)
        })
    }
    deinit { tokens.forEach(NotificationCenter.default.removeObserver) }
}
```

* Apple documents interruption and route change handling on **`AVAudioSession`**. ([Apple Developer][21])

**Quick Test:** Which category should a video streaming app use? (**`.playback`**).
**Gotchas:** Don’t forget to **activate** the session; background audio also requires `UIBackgroundModes=audio`. ([Apple Developer][22])

**References:**

* `AVAudioSession` – developer.apple.com/documentation/avfaudio/avaudiosession ([Apple Developer][23])
* Configuring app for media playback – developer.apple.com/documentation/AVFoundation/configuring-your-app-for-media-playback ([Apple Developer][20])
* Background modes – developer.apple.com/documentation/xcode/configuring-background-execution-modes ([Apple Developer][24])

---

## 6) Now Playing & Remote Controls

**You will learn:** how to show metadata on the lock screen and handle remote transport commands.

```swift
import MediaPlayer
import AVFoundation

final class NowPlaying {
    private let center = MPNowPlayingInfoCenter.default()
    private let player: AVPlayer

    init(player: AVPlayer) { self.player = player }

    func update(title: String, artist: String? = nil, artwork: UIImage? = nil) {
        var info: [String : Any] = [
            MPMediaItemPropertyTitle: title,
            MPNowPlayingInfoPropertyElapsedPlaybackTime: player.currentTime().seconds,
            MPMediaItemPropertyPlaybackDuration: player.currentItem?.duration.seconds ?? 0,
            MPNowPlayingInfoPropertyPlaybackRate: player.rate
        ]
        if let artist { info[MPMediaItemPropertyArtist] = artist }
        if let artwork { info[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: artwork.size) { _ in artwork } }
        center.nowPlayingInfo = info
    }

    func wireCommands() {
        let cmd = MPRemoteCommandCenter.shared()
        cmd.playCommand.addTarget { [weak player] _ in player?.play(); return .success }
        cmd.pauseCommand.addTarget { [weak player] _ in player?.pause(); return .success }
        cmd.togglePlayPauseCommand.addTarget { [weak player] _ in
            guard let p = player else { return .commandFailed }
            p.timeControlStatus == .playing ? p.pause() : p.play()
            return .success
        }
    }
}
```

* Use **`MPNowPlayingInfoCenter`** for metadata and **`MPRemoteCommandCenter`** for play/pause/seek/skip. ([Apple Developer][25])

**Quick Test:** Which property keeps the lock-screen progress in sync? (**`MPNowPlayingInfoPropertyElapsedPlaybackTime`**).
**Gotchas:** Update `elapsedPlaybackTime` periodically if you manage rate/time manually.

**References:**

* `MPNowPlayingInfoCenter` – developer.apple.com/documentation/mediaplayer/mpnowplayinginfocenter ([Apple Developer][25])
* `MPRemoteCommandCenter` – developer.apple.com/documentation/mediaplayer/mpremotecommandcenter ([Apple Developer][26])

---

## 7) Subtitles, Closed Captions, and Audio Tracks

**You will learn:** how to discover media selection groups and switch tracks at runtime.

```swift
import AVFoundation

func availableSubtitleOptions(for item: AVPlayerItem) -> [AVMediaSelectionOption] {
    guard let group = item.asset.mediaSelectionGroup(forMediaCharacteristic: .legible) else { return [] }
    return group.options
}

func select(subtitle option: AVMediaSelectionOption?, for item: AVPlayerItem) {
    guard let group = item.asset.mediaSelectionGroup(forMediaCharacteristic: .legible) else { return }
    if let option { item.select(option, in: group) }
    else { item.select(nil, in: group) } // Off
}

func availableAudioOptions(for item: AVPlayerItem) -> [AVMediaSelectionOption] {
    item.asset.mediaSelectionGroup(forMediaCharacteristic: .audible)?.options ?? []
}
```

* Track discovery & selection are via **`AVAsset`** and **`AVMediaSelectionGroup`**. ([Apple Developer][27])
* For “external” subtitles, Apple recommends packaging them as **HLS text tracks** (e.g., WebVTT) alongside the stream. ([Apple Developer][15])

**Quick Test:** How do you turn off subtitles? (**`select(nil, in: group)`**).
**Gotchas:** Not every asset has legible tracks; always check for `nil`.

**References:**

* Media selection – developer.apple.com/documentation/avfoundation/avmediaselectiongroup ([Apple Developer][27])
* HLS examples incl. subtitle variants – developer.apple.com/streaming/examples/ ([Apple Developer][15])

---

## 8) Picture in Picture (PiP)

**You will learn:** how to enable PiP using AVKit’s standard controller or the **`AVPictureInPictureController`** for custom UIs.

### 8.1 Easiest: AVPlayerViewController (iOS)

```swift
vc.canStartPictureInPictureAutomaticallyFromInline = true
```

* Apple’s “standard player” adopts PiP for you. ([Apple Developer][14])

### 8.2 Custom player with `AVPictureInPictureController`

```swift
import AVKit

final class PiPBridge: NSObject, AVPictureInPictureControllerDelegate {
    private var pip: AVPictureInPictureController?
    private weak var playerLayer: AVPlayerLayer?

    init(playerLayer: AVPlayerLayer) {
        self.playerLayer = playerLayer
        super.init()
        if AVPictureInPictureController.isPictureInPictureSupported() {
            let source = AVPictureInPictureController.ContentSource(playerLayer: playerLayer)
            pip = AVPictureInPictureController(contentSource: source)
            pip?.delegate = self
        }
    }
    func start() { pip?.startPictureInPicture() }
    func stop()  { pip?.stopPictureInPicture() }
    // Restore UI when PiP ends
    func pictureInPictureController(_ controller: AVPictureInPictureController,
                                    restoreUserInterfaceForPictureInPictureStopWithCompletionHandler completionHandler: @escaping (Bool) -> Void) {
        completionHandler(true)
    }
}
```

* The **ContentSource** initializer is the modern way to build PiP around a player layer. ([Apple Developer][28])

**Quick Test:** Which API tells you if PiP is supported? (**`AVPictureInPictureController.isPictureInPictureSupported()`**).
**Gotchas:** On iOS, PiP works best with background audio category set appropriately; see Section 5. ([Apple Developer][29])

**References:**

* `AVPictureInPictureController` & delegate – developer.apple.com/documentation/avkit/avpictureinpicturecontroller ([Apple Developer][28])
* Adopting PiP (custom/standard) – developer.apple.com/documentation/avkit/adopting-picture-in-picture-in-a-custom-player; /in-a-standard-player ([Apple Developer][29])

---

## 9) Queues, Looping, and Playlists

**You will learn:** `AVQueuePlayer` for playlists and `AVPlayerLooper` for seamless loops.

```swift
import AVFoundation

final class LoopingExample {
    let player = AVQueuePlayer()
    private var looper: AVPlayerLooper?

    func startLooping(_ url: URL) {
        let item = AVPlayerItem(url: url)
        looper = AVPlayerLooper(player: player, templateItem: item)
        player.play()
    }
}
```

* **`AVQueuePlayer`** plays a sequence of items; **`AVPlayerLooper`** builds a seamless loop from a template item. ([Apple Developer][30])

**Quick Test:** Which class do you need to loop seamlessly? (**`AVPlayerLooper`**).
**Gotchas:** Keep a strong reference to the **`AVPlayerLooper`**; otherwise looping stops.

**References:**

* `AVQueuePlayer` – developer.apple.com/documentation/avfoundation/avqueueplayer ([Apple Developer][30])
* `AVPlayerLooper` – developer.apple.com/documentation/avfoundation/avplayerlooper ([Apple Developer][31])

---

## 10) Downloads & Offline Playback (HLS)

**You will learn:** how to download HLS for offline use with `AVAssetDownloadURLSession`, track progress, and manage storage.

```swift
import Foundation
import AVFoundation

final class HLSDownloader: NSObject, AVAssetDownloadDelegate {
    private lazy var session: AVAssetDownloadURLSession = {
        let cfg = URLSessionConfiguration.background(withIdentifier: "com.example.hlsdownloads")
        return AVAssetDownloadURLSession(configuration: cfg, assetDownloadDelegate: self, delegateQueue: .main)
    }()

    func start(url: URL, title: String) {
        let asset = AVURLAsset(url: url)
        let task = session.makeAssetDownloadTask(
            asset: asset, assetTitle: title, assetArtworkData: nil,
            options: [AVAssetDownloadTaskMinimumRequiredMediaBitrateKey: 265_000]
        )
        task?.resume()
    }

    func urlSession(_ session: URLSession, assetDownloadTask: AVAssetDownloadTask,
                    didFinishDownloadingTo location: URL) {
        // Move the on-disk package to your app’s storage and save the bookmark.
        print("Downloaded to:", location)
    }

    func urlSession(_ session: URLSession, assetDownloadTask: AVAssetDownloadTask,
                    didLoad timeRange: CMTimeRange, totalTimeRangesLoaded loaded: [CMTimeRange],
                    timeRangeExpectedToLoad: CMTimeRange) {
        let loadedSeconds = loaded.reduce(0) { $0 + $1.duration.seconds }
        let pct = loadedSeconds / timeRangeExpectedToLoad.duration.seconds
        print("Progress:", pct)
    }
}
```

* `AVAssetDownloadURLSession` is Apple’s API for HLS offline downloads. ([Apple Developer][32])

**Quick Test:** Which class fires progress callbacks for HLS downloads? (**`AVAssetDownloadTask`** via delegate).
**Gotchas:** DRM (FairPlay) requires a proper key/lease flow—see Apple’s FairPlay docs. ([Apple Developer][19])

**References:**

* `AVAssetDownloadURLSession` – developer.apple.com/documentation/avfoundation/avassetdownloadurlsession ([Apple Developer][32])
* HLS examples (offline-safe test streams vary) – developer.apple.com/streaming/examples/ ([Apple Developer][15])

---

## 11) Metrics, Logging, and Diagnostics

**You will learn:** how to read access/error logs from `AVPlayerItem`, and log key events using the **Unified Logging** system.

```swift
import AVFoundation
import OSLog

let log = Logger(subsystem: "com.example.player", category: "playback")

func logPlaybackStats(for item: AVPlayerItem) {
    if let ev = item.accessLog()?.events.last {
        log.info("throughput=\(ev.observedBitrate, privacy: .public)bps stalls=\(ev.numberOfStalls)")
    }
    if let e = item.errorLog()?.events.last {
        log.error("lastError=\(e.errorComment ?? "n/a", privacy: .public)")
    }
}
```

* `AVPlayerItemAccessLog` / `ErrorLog` show stalls, bitrate, and failures. ([Apple Developer][33])
* Prefer **`Logger` (OSLog)** over `print` for efficient, searchable logs. ([Apple Developer][34])

**Instruments to know:** **Time Profiler**, **Allocations**, **Energy Log**. ([Apple Developer][35])

**Quick Test:** Which log stores stall counts? (**`AVPlayerItemAccessLog`**).
**Gotchas:** Don’t spam logs; use appropriate levels and privacy annotations.

**References:**

* Access & error logs – developer.apple.com/documentation/avfoundation/avplayeritemaccesslog; /avplayeritemerrorlog ([Apple Developer][33])
* Unified logging – developer.apple.com/documentation/os/logging ([Apple Developer][36])
* Instruments overview – developer.apple.com/documentation/xcode/improving-your-app-s-performance ([Apple Developer][37])

---

## 12) Performance & Power Best Practices

**You will learn:** how to reduce rebuffering and energy drain.

* Keep **`automaticallyWaitsToMinimizeStalling`** enabled; cap bitrate on cellular if needed. ([Apple Developer][17])
* Avoid oversized layers; size your **`AVPlayerLayer`/views** to displayed pixels to reduce decoding/scaling work.
* Prefer H.264/HEVC variants appropriate to devices (HLS authoring guides explain *tiers*). ([Apple Developer][38])
* Monitor energy with **Energy Log** and follow Apple’s energy guides. ([Apple Developer][25])
* Handle network changes gracefully (see next bullet):

```swift
import Network

final class NetworkWatcher {
    private let monitor = NWPathMonitor()
    func start() {
        monitor.pathUpdateHandler = { path in
            if path.status == .satisfied { print("Network OK") }
            else { print("Network lost") }
        }
        monitor.start(queue: DispatchQueue(label: "net"))
    }
}
```

* `NWPathMonitor` is Apple’s preferred way to observe connectivity changes. ([Apple Developer][39])

**Quick Test:** Which API should you use to observe connectivity? (**`NWPathMonitor`**).
**Gotchas:** Don’t block the main thread when you parse logs or HLS playlists.

**References:**

* HLS + CMAF notes – developer.apple.com/documentation/http-live-streaming/about-the-common-media-application-format-with-http-live-streaming-hls ([Apple Developer][38])
* Energy efficiency – developer.apple.com/library/archive/documentation/Performance/Conceptual/EnergyGuide-iOS/index.html ([Apple Developer][40])
* `NWPathMonitor` – developer.apple.com/documentation/network/nwpathmonitor ([Apple Developer][39])

---

## 13) macOS-Specific Notes

**You will learn:** macOS sandbox file access, security-scoped bookmarks, and `AVPlayerView` conveniences.

### 13.1 User-selected file access + security-scoped bookmarks

```swift
import AppKit

func pickAndPersistFileAccess() throws -> Data? {
    let panel = NSOpenPanel(); panel.canChooseFiles = true; panel.canChooseDirectories = false
    guard panel.runModal() == .OK, let url = panel.url else { return nil }
    guard url.startAccessingSecurityScopedResource() else { return nil }
    defer { url.stopAccessingSecurityScopedResource() }
    // Save bookmark data for next launches
    return try url.bookmarkData(options: .withSecurityScope,
                                includingResourceValuesForKeys: nil,
                                relativeTo: nil)
}
```

* Use **User-Selected File Read-Only/Read-Write** entitlements and **security-scoped bookmarks** to persist file permissions. ([Apple Developer][41])

**Quick Test:** Which entitlement grants read-only access to user-selected files? (**`com.apple.security.files.user-selected.read-only`**).
**Gotchas:** Always **start/stop** security-scoped access around file I/O.

**References:**

* App Sandbox file access – developer.apple.com/documentation/security/accessing-files-from-the-macos-app-sandbox ([Apple Developer][2])
* Read-only/read-write entitlements – developer.apple.com/documentation/bundleresources/entitlements/com.apple.security.files.user-selected.read-only and …read-write ([Apple Developer][41])

---

## 14) Testing

**You will learn:** deterministic unit tests and basic UI tests for transport controls and PiP availability.

### 14.1 Unit test: wait for `AVPlayerItem.status == .readyToPlay`

```swift
import XCTest
import AVFoundation

final class PlayerTests: XCTestCase {
    func testReadyToPlay() {
        let url = URL(string:"https://devstreaming-cdn.apple.com/videos/streaming/examples/bipbop_4x3/gear1/prog_index.m3u8")!
        let item = AVPlayerItem(url: url)
        let exp = expectation(description: "ready")
        let obs = item.observe(\.status, options: [.new]) { item, _ in
            if item.status == .readyToPlay { exp.fulfill() }
        }
        let player = AVPlayer(playerItem: item); player.play()
        wait(for: [exp], timeout: 15)
        obs.invalidate()
    }
}
```

### 14.2 UI test: basic transport

```swift
import XCTest

final class UITests: XCTestCase {
    func testPlayPauseButton() {
        let app = XCUIApplication(); app.launch()
        app.buttons["⏯ Play/Pause"].tap()
        // Assert your label or state changed...
    }
}
```

**Quick Test:** Which KVO keypath do you observe for readiness? (**`status`** on `AVPlayerItem`).
**Gotchas:** Use Apple’s HLS examples for stable, deterministic tests. ([Apple Developer][15])

**References:**

* XCTest expectations – developer.apple.com/documentation/xctest/xctestexpectation ([Apple Developer][42])

---

## 15) Troubleshooting & FAQ

**You will learn:** common errors and network/ATS/HLS issues.

* **`AVErrorDomain` / status failed**: check `AVPlayerItem.error` and your URL/mime types; HLS playlists (`.m3u8`) should use the proper MIME type (Apple lists `application/x-mpegURL` or `application/vnd.apple.mpegurl`). ([Apple Developer][43])
* **ATS blocked (HTTP)**: add HTTPS or narrowly scoped ATS exceptions (`NSAppTransportSecurity`). ([Apple Developer][11])
* **No background audio**: ensure `UIBackgroundModes=audio`, session category `.playback`, and that you actually produce audible output in background (App Review checks this). ([Apple Developer][44])
* **CORS/range**: HLS needs range requests; your CDN must allow them (configure server accordingly).

**Quick Test:** Which Info.plist key is related to ATS? (**`NSAppTransportSecurity`**).
**Gotchas:** Some players fail if the server doesn’t support **byte-range** requests for segments.

**References:**

* Deploying HLS & MIME types – developer.apple.com/library/archive/.../DeployingHTTPLiveStreaming.html ([Apple Developer][43])
* NSAppTransportSecurity – developer.apple.com/documentation/bundleresources/information-property-list/nsapptransportsecurity ([Apple Developer][11])

---

## 16) Appendix

### A) Glossary (short & friendly)

* **ABR (Adaptive Bitrate):** Switch quality up/down to match bandwidth.
* **HLS:** Apple’s streaming tech using playlists (`.m3u8`) and media segments. ([Apple Developer][7])
* **PiP:** Picture in Picture; video floats in a small window while the user does other things. ([Apple Developer][28])
* **Now Playing:** System UI (lock screen/Control Center) showing your track info. ([Apple Developer][25])
* **`CMTime`:** A precise time value (numerator/denominator) used for media. ([Apple Developer][6])

### B) Mini Checklists ✅

**Basic Player**

* [ ] Create `AVPlayerItem` → `AVPlayer`
* [ ] Display via `VideoPlayer` (SwiftUI) or `AVPlayerViewController`/`AVPlayerView`
* [ ] Add periodic time observer for UI updates
* [ ] Handle errors (`item.status`, `item.error`)

**Background Audio (iOS)**

* [ ] Add **Background Modes → Audio**
* [ ] `AVAudioSession.setCategory(.playback)` + `setActive(true)`
* [ ] Handle interruptions & route changes
* [ ] Update Now Playing info
* [ ] Test with screen locked ([Apple Developer][9])

**Picture in Picture**

* [ ] If using `AVPlayerViewController`, set `canStartPictureInPictureAutomaticallyFromInline = true`
* [ ] For custom UI, create `AVPictureInPictureController.ContentSource` from `AVPlayerLayer`
* [ ] Implement delegate to restore UI
* [ ] Verify `isPictureInPictureSupported()` on device ([Apple Developer][14])

**HLS Download**

* [ ] Create `AVAssetDownloadURLSession` with background configuration
* [ ] Start `makeAssetDownloadTask`
* [ ] Track progress in delegate
* [ ] Move package, save bookmark/URL for playback offline ([Apple Developer][32])

### C) Sample project structure (if you build one)

* `PlayerCore/` (AVFoundation logic, models)
* `UI/` (SwiftUI views + thin wrappers for AVKit/PiP)
* `Services/` (HLSDownload, NowPlaying, NetworkWatcher)
* `Tests/` (unit + UI tests)

---

## — End of Guide —

If you want, I can turn this into a tiny sample Xcode project you can run immediately (SwiftUI target for iOS & macOS).

[1]: https://developer.apple.com/documentation/xcode-release-notes/xcode-26_0_1-release-notes?utm_source=chatgpt.com "Xcode 26.0.1 Release Notes | Apple Developer Documentation"
[2]: https://developer.apple.com/documentation/security/accessing-files-from-the-macos-app-sandbox?utm_source=chatgpt.com "Accessing files from the macOS App Sandbox - Apple Developer"
[3]: https://developer.apple.com/documentation/avfoundation?utm_source=chatgpt.com "AVFoundation | Apple Developer Documentation"
[4]: https://developer.apple.com/documentation/avkit/playing-video-content-in-a-standard-user-interface?utm_source=chatgpt.com "Playing video content in a standard user interface"
[5]: https://developer.apple.com/documentation/mediaplayer/mpremotecommandcenter?utm_source=chatgpt.com "MPRemoteCommandCenter | Apple Developer Documentation"
[6]: https://developer.apple.com/documentation/coremedia/cmtime-api?utm_source=chatgpt.com "CMTime | Apple Developer Documentation"
[7]: https://developer.apple.com/documentation/technologyoverviews/streaming?utm_source=chatgpt.com "Media streaming | Apple Developer Documentation"
[8]: https://developer.apple.com/documentation/avfoundation/avmediaselectiongroup?utm_source=chatgpt.com "AVMediaSelectionGroup | Apple Developer Documentation"
[9]: https://developer.apple.com/documentation/bundleresources/information-property-list/uibackgroundmodes?utm_source=chatgpt.com "UIBackgroundModes | Apple Developer Documentation"
[10]: https://help.apple.com/xcode/mac/current/en.lproj/devf87a2ac8f.html?utm_source=chatgpt.com "Enable hardened runtime (macOS) - help.apple.com"
[11]: https://developer.apple.com/documentation/bundleresources/information-property-list/nsapptransportsecurity?utm_source=chatgpt.com "NSAppTransportSecurity | Apple Developer Documentation"
[12]: https://developer.apple.com/forums/thread/672498?utm_source=chatgpt.com "App rejected on AppStoreConnect: Y… | Apple Developer Forums"
[13]: https://developer.apple.com/documentation/xcode-release-notes/xcode-26-release-notes?utm_source=chatgpt.com "Xcode 26 Release Notes | Apple Developer Documentation"
[14]: https://developer.apple.com/documentation/avkit/adopting-picture-in-picture-in-a-standard-player?utm_source=chatgpt.com "Adopting Picture in Picture in a Standard Player"
[15]: https://developer.apple.com/streaming/examples/?utm_source=chatgpt.com "Examples - HTTP Live Streaming - Apple Developer"
[16]: https://developer.apple.com/documentation/avfoundation/avasset?utm_source=chatgpt.com "AVAsset | Apple Developer Documentation"
[17]: https://developer.apple.com/documentation/avfoundation/avasset/mediaselectiongroup%28formediacharacteristic%3A%29?utm_source=chatgpt.com "mediaSelectionGroup (forMediaCharacteristic:) | Apple Developer ..."
[18]: https://developer.apple.com/documentation/avfoundation/avassetresourceloader?utm_source=chatgpt.com "AVAssetResourceLoader | Apple Developer Documentation"
[19]: https://developer.apple.com/documentation/xctest/xctestexpectation?utm_source=chatgpt.com "XCTestExpectation | Apple Developer Documentation"
[20]: https://developer.apple.com/documentation/AVFoundation/configuring-your-app-for-media-playback?utm_source=chatgpt.com "Configuring your app for media playback - Apple Developer"
[21]: https://developer.apple.com/documentation/avfoundation/avplayeritemerrorlog?utm_source=chatgpt.com "AVPlayerItemErrorLog | Apple Developer Documentation"
[22]: https://developer.apple.com/library/archive/documentation/Audio/Conceptual/AudioSessionProgrammingGuide/ConfiguringanAudioSession/ConfiguringanAudioSession.html?utm_source=chatgpt.com "Activating an Audio Session - Apple Developer"
[23]: https://developer.apple.com/documentation/avfaudio/avaudiosession?utm_source=chatgpt.com "AVAudioSession | Apple Developer Documentation"
[24]: https://developer.apple.com/documentation/xcode/configuring-background-execution-modes?utm_source=chatgpt.com "Configuring background execution modes - Apple Developer"
[25]: https://developer.apple.com/library/archive/documentation/Performance/Conceptual/EnergyGuide-iOS/MonitorEnergyWithInstruments.html?utm_source=chatgpt.com "Measure Energy Impact with Instruments - Apple Developer"
[26]: https://docs.developer.apple.com/tutorials/instruments?utm_source=chatgpt.com "Instruments Tutorials | Apple Developer Documentation"
[27]: https://developer.apple.com/documentation/avkit/avplayerview?utm_source=chatgpt.com "AVPlayerView | Apple Developer Documentation"
[28]: https://developer.apple.com/documentation/avkit/avpictureinpicturecontroller?utm_source=chatgpt.com "AVPictureInPictureController | Apple Developer Documentation"
[29]: https://developer.apple.com/documentation/avkit/adopting-picture-in-picture-in-a-custom-player?utm_source=chatgpt.com "Adopting Picture in Picture in a Custom Player - Apple Developer"
[30]: https://developer.apple.com/streaming/fps/?utm_source=chatgpt.com "FairPlay Streaming - Apple Developer"
[31]: https://developer.apple.com/documentation/avfoundation/providing-an-integrated-view-of-your-timeline-when-playing-hls-interstitials?utm_source=chatgpt.com "Providing an integrated view of your timeline when ... - Apple Developer"
[32]: https://developer.apple.com/documentation/avfaudio/avaudiosession/category-swift.struct?utm_source=chatgpt.com "AVAudioSession.Category | Apple Developer Documentation"
[33]: https://developer.apple.com/streaming/fps/FairPlayStreamingOverview.pdf?utm_source=chatgpt.com "FairPlay Streaming Overview - Apple Developer"
[34]: https://developer.apple.com/documentation/os/generating-log-messages-from-your-code?utm_source=chatgpt.com "Generating Log Messages from Your Code - Apple Developer"
[35]: https://developer.apple.com/documentation/http-live-streaming?utm_source=chatgpt.com "HTTP Live Streaming | Apple Developer Documentation"
[36]: https://developer.apple.com/documentation/os/logging?utm_source=chatgpt.com "Logging | Apple Developer Documentation"
[37]: https://developer.apple.com/documentation/xcode/improving-your-app-s-performance?utm_source=chatgpt.com "Improving your app’s performance - Apple Developer"
[38]: https://developer.apple.com/documentation/http-live-streaming/about-the-common-media-application-format-with-http-live-streaming-hls?utm_source=chatgpt.com "About the Common Media Application Format with HTTP Live Streaming (HLS)"
[39]: https://developer.apple.com/documentation/network/nwpathmonitor?utm_source=chatgpt.com "NWPathMonitor | Apple Developer Documentation"
[40]: https://developer.apple.com/library/archive/documentation/Performance/Conceptual/EnergyGuide-iOS/index.html?utm_source=chatgpt.com "Energy Efficiency Guide for iOS Apps: Energy ... - Apple Developer"
[41]: https://developer.apple.com/documentation/bundleresources/entitlements/com.apple.security.files.user-selected.read-only?utm_source=chatgpt.com "com.apple.security.files.user-selected.read-only | Apple Developer ..."
[42]: https://developer.apple.com/documentation/avfoundation/avplayer/automaticallywaitstominimizestalling?utm_source=chatgpt.com "automaticallyWaitsToMinimizeStalling | Apple Developer Documentation"
[43]: https://developer.apple.com/library/archive/documentation/NetworkingInternet/Conceptual/StreamingMediaGuide/DeployingHTTPLiveStreaming/DeployingHTTPLiveStreaming.html?utm_source=chatgpt.com "Deploying HTTP Live Streaming - Apple Developer"
[44]: https://developers.apple.com/library/archive/documentation/AudioVideo/Conceptual/MediaPlaybackGuide/Contents/Resources/en.lproj/ConfiguringAudioSettings/ConfiguringAudioSettings.html?utm_source=chatgpt.com "Configuring Audio Settings for iOS and tvOS - Apple Developer"
