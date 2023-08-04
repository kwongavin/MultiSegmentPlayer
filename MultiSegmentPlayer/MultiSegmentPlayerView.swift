//
//  MultiSegmentPlayerView.swift
//  MultiSegmentPlayer
//
//  Created by Gavin Kwon on 7/26/23.
//

import SwiftUI

class MultiSegmentPlayerConductor: ObservableObject {
    let engine = AudioEngine()
    let player = MultiSegmentAudioPlayer()
    let accountModel = AccountModel()

    var timer: Timer!
    var timePrevious: TimeInterval = .init(DispatchTime.now().uptimeNanoseconds) / 1_000_000_000
    @Published var endTime: TimeInterval = 0

    @Published var _timeStamp: TimeInterval = 0
    var timeStamp: TimeInterval {
        get {
            return _timeStamp
        }
        set {
            _timeStamp = newValue.clamped(to: 0 ... endTime)

            if newValue > endTime {
                isPlaying = false
                _timeStamp = 0
            }
        }
    }

    var rmsFramesPerSecond: Double = 15
    var pixelsPerRMS: Double = 1

    @Published var isPlaying: Bool = false {
        didSet {
            if !isPlaying {
                engine.stop()
                startAudioEngine()
                _timeStamp = 0
                // Stop accessing the security-scoped resource for all segments
                for segment in accountModel.segments {
                    segment.audioFileURL.stopAccessingSecurityScopedResource()
                }
            } else {
                timePrevious = TimeInterval(DispatchTime.now().uptimeNanoseconds) * 1_000_000_000
                // Start accessing the security-scoped resource for all segments
                for segment in accountModel.segments {
                    _ = segment.audioFileURL.startAccessingSecurityScopedResource()
                }
                player.playSegments(audioSegments: accountModel.segments, referenceTimeStamp: timeStamp)
            }
        }
    }


    init() {
//        accountModel.createSegments()
        setEndTime()
        setAudioSessionCategoriesWithOptions()
        routeAudioToOutput()
        startAudioEngine()
        timer = Timer.scheduledTimer(timeInterval: 0.05,
                                     target: self,
                                     selector: #selector(checkTime),
                                     userInfo: nil,
                                     repeats: true)
    }

    func setEndTime() {
        if accountModel.segments.count == 0 {
            endTime = 10.0
        } else {
            endTime = 8.0 // segments[segments.count - 1].playbackEndTime
        }
    }

    @objc func checkTime() {
        if isPlaying {
            let timeNow = TimeInterval(DispatchTime.now().uptimeNanoseconds) / 1_000_000_000
            timeStamp += (timeNow - timePrevious)
            timePrevious = timeNow
        }
    }

    func setAudioSessionCategoriesWithOptions() {
        do {
            try Settings.session.setCategory(.playAndRecord,
                                             options: [.defaultToSpeaker,
                                                       .mixWithOthers,
                                                       .allowBluetooth,
                                                       .allowBluetoothA2DP,
                                                       .allowAirPlay])
            try Settings.session.setActive(true)
        } catch {
            assertionFailure(error.localizedDescription)
        }
    }

    func routeAudioToOutput() {
        engine.output = player
    }

    func startAudioEngine() {
        do {
            try engine.start()
        } catch {
            assertionFailure(error.localizedDescription)
        }
    }

}

struct MultiSegmentPlayerView: View {
    @ObservedObject var conductor = MultiSegmentPlayerConductor()
    @EnvironmentObject var accountModel: AccountModel

    var currentTimeText: String {
        let currentTime = String(format: "%.1f", conductor.timeStamp)
        let endTime = String(format: "%.1f", conductor.endTime)
        return currentTime + " of " + endTime
    }

    var currentPlayPosition: CGFloat {
        let pixelsPerSecond = conductor.pixelsPerRMS * conductor.rmsFramesPerSecond
        return conductor.timeStamp * pixelsPerSecond - playheadWidth
    }

    let playheadWidth: CGFloat = 2

    var body: some View {
        VStack {
            ZStack(alignment: .leading) {
                TrackView(segments: accountModel.segments,
                          rmsFramesPerSecond: conductor.rmsFramesPerSecond,
                          pixelsPerRMS: conductor.pixelsPerRMS)

                Rectangle()
                    .fill(.red)
                    .frame(width: playheadWidth)
                    .offset(x: currentPlayPosition)
            }
            .frame(height: 200)
            .padding()

            PlayPauseView(isPlaying: $conductor.isPlaying, accountModel: accountModel).frame(height: 30)

            Text(currentTimeText)
                .padding(.top)

            Spacer()
        }
    }

    struct PlayPauseView: View {
        @Binding var isPlaying: Bool
        @ObservedObject var accountModel: AccountModel

        var body: some View {
            Image(systemName: !isPlaying ? "play" : "pause")
                .resizable()
                .scaledToFit()
                .frame(width: 24)
                .contentShape(Rectangle())
                .onTapGesture { isPlaying.toggle()
                    print("*** number of segments? : \(accountModel.segments.count)")
                }
        }
    }
}

// Duplicated from AudioKit
private extension Comparable {
    // ie: 5.clamped(to: 7...10)
    // ie: 5.0.clamped(to: 7.0...10.0)
    // ie: "a".clamped(to: "b"..."h")
    /// **OTCore:**
    /// Returns the value clamped to the passed range.
//    dynamic func clamped(to limits: ClosedRange<Self>) -> Self {
//        min(max(self, limits.lowerBound), limits.upperBound)
//    }
}


struct MultiSegmentPlayerView_Previews: PreviewProvider {
    static var previews: some View {
        MultiSegmentPlayerView()
            .environmentObject(AccountModel())
    }
}
