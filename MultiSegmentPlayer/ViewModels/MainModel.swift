//
//  AccountModel.swift
//  UserAudioApp_0608
//
//  Created by Gavin Kwon on 6/30/23.
//

import Foundation
import MediaPlayer

class MainModel: ObservableObject {
    
    // Track names, user can add-subtract this values at any time.
    @Published var tracks: [String] = ["Hey Jude", "Yesterday", "Come Together"]
    @Published var sections: [SectionInfo] = []
    @Published var titleDisplayIndex = 0
    
    // For Audio Player
    // TODO: - Rename to segments2dArray
    @Published var segments2d: [[MockSegment]] = [] //{ didSet { setEndTime() }}
    @Published var playingSegmentIndex = 0
    
    @Published var endTime: TimeInterval = 0
    @Published var _timeStamp: TimeInterval = 0
    @Published var isPlaying: Bool = false { didSet { isPlayingDidSet() } }
    
    let engine = AudioEngine()
    let player = MultiSegmentAudioPlayer()
    
    var timer: Timer!
    var timePrevious: TimeInterval = .init(DispatchTime.now().uptimeNanoseconds) / 1_000_000_000
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
    
    
    init() {
        setEndTime()
        setAudioSessionCategoriesWithOptions()
        routeAudioToOutput()
        startAudioEngine()
        setMediaPlayer()
        timer = Timer.scheduledTimer(timeInterval: 0.05,
                                     target: self,
                                     selector: #selector(checkTime),
                                     userInfo: nil,
                                     repeats: true)
    }

}

// MARK: - Initial Functions
// MARK: -
extension MainModel {
    
    func setEndTime() {
        guard segments2d.isNotEmpty else { return }
        let count = segments2d[playingSegmentIndex].count
        if count == 0 {
            endTime = 0.0
        } else {
            endTime = segments2d[playingSegmentIndex][count - 1].playbackEndTime
        }
    }
    
    func setAudioSessionCategoriesWithOptions() {
        do {
            try Settings.session.setCategory(.playback)
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
    
    func setMediaPlayer() {
        
        // Declare an instance of MPRemoteCommandCenter
        let commandCenter = MPRemoteCommandCenter.shared()

        // Play
        commandCenter.playCommand.addTarget { [weak self] _ in
            self?.isPlaying = true
            return .success
        }

        // Pause
        commandCenter.pauseCommand.addTarget { [weak self] _ in
            self?.isPlaying = false
            return .success
        }
        
        // Next
        commandCenter.nextTrackCommand.addTarget { [weak self] _ in
            self?.forwardButtonTapped()
            return .success
        }
        
        // Back
        commandCenter.previousTrackCommand.addTarget { [weak self] _ in
            self?.backButtonTapped()
            return .success
        }
        
    }
    
    
    
}


// MARK: - Helper Functions
// MARK: -
extension MainModel {
    
    func createSegments() {
        
        self.segments2d = []
        self.playingSegmentIndex = 0
        
        for section in sections {
            
            var newSegments: [MockSegment] = []
            
            // check if section has tracks
            if section.tracks.isEmpty { continue }
            
            for track in section.tracks {
                guard let url = track.items.randomElement()?.url else { continue }
                let didStartAccessing = url.startAccessingSecurityScopedResource()
                
                if didStartAccessing {
                    defer { url.stopAccessingSecurityScopedResource() }
                    
                    // The playback start time for each segment is the playback end time of the last segment, minus 0.07 (To avoid breaks).
                    // If there is no last segment (i.e., if this is the first segment), we default to 0.0.
                    let playbackStartTime = (newSegments.last?.playbackEndTime ?? 0.0) - 0.05
                    
                    if let segment = try? MockSegment(
                        audioFileURL: url,
                        playbackStartTime: playbackStartTime,
                        rmsFramesPerSecond: rmsFramesPerSecond
                    ) {
                        newSegments.append(segment)
                    }
                } else {
                    print("Couldn't load file URL")
                }
            }
            
            self.segments2d.append(newSegments)
            
        }
        
        setEndTime()
        
    }
    
    private func isPlayingDidSet() {
        
        guard let segments = segments2d[safe: playingSegmentIndex] else { return }
        
        if !isPlaying {
            engine.stop()
            //startAudioEngine() // this is temporary solution, should be player.stop()
            player.stop()
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
            
            // for highlighting the first track
            startAudioEngine()
            GlobalModel.playingUrl = "first track"
            player.playSegments(audioSegments: segments, referenceTimeStamp: timeStamp)
            updateMediaPlayer()
        }
        
    }

    @objc func checkTime() {
        if isPlaying {
            let timeNow = TimeInterval(DispatchTime.now().uptimeNanoseconds) / 1_000_000_000
            timeStamp += (timeNow - timePrevious)
            timePrevious = timeNow
        }
    }
    
    func trackEnded(url: String) {
        
        // check if first track
        guard url != "first track" else { return }
        
        // get segment
        guard let segments = segments2d[safe: playingSegmentIndex] else { return }
        
        // check if last track of audio file
        guard url == segments.last?.audioFileURL.absoluteString else { return }
        
        // stop playing
        isPlaying = false
        
        
        // set next segment
        if playingSegmentIndex == segments2d.count - 1 {
            playingSegmentIndex = 0
            setEndTime()
            return
        }
        else {
            isPlaying = false
            playingSegmentIndex += 1
        }
        
        // play the next segment
        setEndTime()
        isPlaying = true
        
    }
    
    func forwardButtonTapped() {
        
        
        // if last segment
        if playingSegmentIndex == segments2d.count - 1 {
            return
        }
        else {
            isPlaying = false
            playingSegmentIndex += 1
        }
        
        // play the next segment
        GlobalModel.playingUrl = "first track"
        setEndTime()
        isPlaying = true
        
    }
    
    func backButtonTapped() {
        
        // if is first segment
        if playingSegmentIndex == 0 {
            return
        }
        else {
            isPlaying = false
            playingSegmentIndex -= 1
        }
        
        // play the next segment
        GlobalModel.playingUrl = "first track"
        setEndTime()
        isPlaying = true
        
    }
    
    func updateMediaPlayer() {
        
        let nowPlayingInfoCenter = MPNowPlayingInfoCenter.default()
        var nowPlayingInfo = [String: Any]() // Set the appropriate metadata for your audio
        nowPlayingInfo[MPMediaItemPropertyTitle] = "Title"
        nowPlayingInfo[MPMediaItemPropertyArtist] = "Artist"
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = 1.0 // Set the correct playback rate
        nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = 5
        nowPlayingInfoCenter.nowPlayingInfo = nowPlayingInfo
        
    }
    
}
