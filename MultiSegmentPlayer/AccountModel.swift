//
//  AccountModel.swift
//  UserAudioApp_0608
//
//  Created by Gavin Kwon on 6/30/23.
//

import Foundation

class AccountModel: ObservableObject {
    
    // Track names, user can add-subtract this values at any time.
    @Published var tracks: [String] = ["Hey Jude", "Yesterday", "Come Together"]
    @Published var sections: [SectionInfo] = [] {
        didSet {
            createSegments()
        }
    }
    @Published var segments: [MockSegment] = [] {
        didSet {
            setEndTime()
        }
    }
    
    func createSegments() {
        var newSegments: [MockSegment] = []
        
        for section in sections {
            for track in section.tracks {
                guard let url = track.url else { continue }
                let didStartAccessing = url.startAccessingSecurityScopedResource()
                
                if didStartAccessing {
                    defer { url.stopAccessingSecurityScopedResource() }
                    
                    // The playback start time for each segment is the playback end time of the last segment, minus 0.07 (To avoid breaks).
                    // If there is no last segment (i.e., if this is the first segment), we default to 0.0.
                    let playbackStartTime = (newSegments.last?.playbackEndTime ?? 0.0) - 0.07
                    
                    if let segment = try? MockSegment(audioFileURL: url, playbackStartTime: playbackStartTime, rmsFramesPerSecond: rmsFramesPerSecond) {
                        newSegments.append(segment)
                    }
                } else {
                    print("Couldn't load file URL")
                }
            }
        }
        
        self.segments = newSegments
    }
    
    // Moving MultiSegmentPlayerConductor class to here to merge data
    
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

    var rmsFramesPerSecond: Double = 15
    var pixelsPerRMS: Double = 1
    
    @Published var isPlaying: Bool = false {
        didSet {
            if !isPlaying {
                engine.stop()
                startAudioEngine()
                _timeStamp = 0
                // Stop accessing the security-scoped resource for all segments
                for segment in segments {
                    segment.audioFileURL.stopAccessingSecurityScopedResource()
                }
            } else {
                timePrevious = TimeInterval(DispatchTime.now().uptimeNanoseconds) * 1_000_000_000
                // Start accessing the security-scoped resource for all segments
                for segment in segments {
                    _ = segment.audioFileURL.startAccessingSecurityScopedResource()
                }
                player.playSegments(audioSegments: segments, referenceTimeStamp: timeStamp)
            }
        }
    }
    
    init() {
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
        if segments.count == 0 {
            endTime = 0.0
        } else {
            endTime = segments[segments.count - 1].playbackEndTime
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
