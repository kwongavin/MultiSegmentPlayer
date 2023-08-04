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
    @Published var segments: [MockSegment] = []
    
    var rmsFramesPerSecond: Double = 15
    
    public func createSegments() {
        var newSegments: [MockSegment] = []
        
        for section in sections {
            for track in section.tracks {
                guard let url = track.url else { continue }
                let didStartAccessing = url.startAccessingSecurityScopedResource() // this allows display audio waveforms to display.
                
                if didStartAccessing {
                    // Make sure to call the stopAccessingSecurityScopedResource() method when you're done with the file
                    defer { url.stopAccessingSecurityScopedResource() }
                    
                    print("** these are URLs: \(url)")
                    let playbackStartTime = newSegments.last?.playbackEndTime ?? 0.0 - 0.07
                    if let segment = try? MockSegment(audioFileURL: url,
                                                      playbackStartTime: playbackStartTime,
                                                      rmsFramesPerSecond: rmsFramesPerSecond) {
                        newSegments.append(segment)
                    }
                } else {
                    print("Couldn't load file URL")
                }
            }
        }
        
        self.segments = newSegments
        print("** Accountmodel.createSegments() : \(self.segments)")
        print("** number of segments : \(self.segments.count)")
    }

}
