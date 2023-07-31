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

    @Published var segments = [MockSegment]()
    var rmsFramesPerSecond: Double = 15
    var pixelsPerRMS: Double = 1

    @Published var isPlaying: Bool = false {
        didSet {
            if !isPlaying {
                player.stop()
                engine.stop()
                startAudioEngine()
                _timeStamp = 0
            } else {
                timePrevious = TimeInterval(DispatchTime.now().uptimeNanoseconds) * 1_000_000_000
                player.playSegments(audioSegments: segments, referenceTimeStamp: timeStamp)
            }
        }
    }

    init() {
        createSegments()
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

    func createSegments() {
        guard let audio1URL = Bundle.main.url(forResource: "FirstSong_1", withExtension: "mp3") else { return }
        guard let audio2URL = Bundle.main.url(forResource: "FirstSong_2", withExtension: "mp3") else { return }
        guard let audio3URL = Bundle.main.url(forResource: "FirstSong_3", withExtension: "mp3") else { return }

        guard let segment1 = try? MockSegment(audioFileURL: audio1URL,
                                              playbackStartTime: 0.0,
                                              rmsFramesPerSecond: rmsFramesPerSecond) else { return }

        guard let segment2 = try? MockSegment(audioFileURL: audio2URL,
                                              playbackStartTime: segment1.playbackEndTime - 0.07,
                                              rmsFramesPerSecond: rmsFramesPerSecond) else { return }

        guard let segment3 = try? MockSegment(audioFileURL: audio3URL,
                                              playbackStartTime: segment2.playbackEndTime - 0.07,
                                              rmsFramesPerSecond: rmsFramesPerSecond) else { return }

        segments = [segment1, segment2, segment3]
    }

    func setEndTime() {
        endTime = segments[segments.count - 1].playbackEndTime
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
            try Settings.session.setCategory(.playAndRecord, options: [.defaultToSpeaker, .mixWithOthers])
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
                TrackView(segments: conductor.segments,
                          rmsFramesPerSecond: conductor.rmsFramesPerSecond,
                          pixelsPerRMS: conductor.pixelsPerRMS)

                Rectangle()
                    .fill(.red)
                    .frame(width: playheadWidth)
                    .offset(x: currentPlayPosition)
            }
            .frame(height: 200)
            .padding()

            PlayPauseView(isPlaying: $conductor.isPlaying).frame(height: 30)

            Text(currentTimeText)
                .padding(.top)

            Spacer()
        }
    }

    struct PlayPauseView: View {
        @Binding var isPlaying: Bool

        var body: some View {
            Image(systemName: !isPlaying ? "play" : "pause")
                .resizable()
                .scaledToFit()
                .frame(width: 24)
                .contentShape(Rectangle())
                .onTapGesture { isPlaying.toggle() }
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
    }
}
