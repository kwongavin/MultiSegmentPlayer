//
//  TrackView.swift
//  MultiSegmentPlayer
//
//  Created by Gavin Kwon on 7/26/23.
//

import AVFoundation
import SwiftUI

public struct TrackView<Segment: ViewableSegment>: View {
    var segments: [Segment]
    var rmsFramesPerSecond: Double
    var pixelsPerRMS: Double

    public init(segments: [Segment], rmsFramesPerSecond: Double = 50, pixelsPerRMS: Double = 1) {
        self.segments = segments
        self.rmsFramesPerSecond = rmsFramesPerSecond
        self.pixelsPerRMS = pixelsPerRMS
    }

    public var body: some View {
        ZStack(alignment: .topLeading) {
            Color.gray.opacity(0.1)
            ForEach(segments) { segment in
                SegmentView<Segment>(segment: segment,
                                     rmsFramesPerSecond: rmsFramesPerSecond,
                                     pixelsPerRMS: pixelsPerRMS)
            }
        }
    }
}

struct SegmentView<Segment: ViewableSegment>: View {
    var segment: Segment
    var rmsFramesPerSecond: Double
    var pixelsPerRMS: Double

    var rmsValuesForRange: [Float] {
        let startingIndex = Int(segment.fileStartTime * rmsFramesPerSecond)
        let endingIndex = Int(segment.fileEndTime * rmsFramesPerSecond) - 1
        return Array(segment.rmsValues[startingIndex ... endingIndex])
    }

    var body: some View {
        AudioWaveform(rmsVals: rmsValuesForRange)
            .fill(Color.black)
            .background(Color.gray.opacity(0.1))
            .frame(width: pixelsPerRMS * Double(rmsValuesForRange.count))
            .offset(x: segment.playbackStartTime * rmsFramesPerSecond * pixelsPerRMS)
    }
}

public protocol ViewableSegment: Identifiable {
    var playbackStartTime: TimeInterval { get }
    var playbackEndTime: TimeInterval { get }
    var fileStartTime: TimeInterval { get }
    var fileEndTime: TimeInterval { get }
    var rmsValues: [Float] { get }
}

public struct MockSegment: ViewableSegment, StreamableAudioSegment {
    public var id = UUID()
    public var audioFile: AVAudioFile
    public var playbackStartTime: TimeInterval
    public var fileStartTime: TimeInterval = 0
    public var fileEndTime: TimeInterval
    public var completionHandler: AVAudioNodeCompletionHandler?
    public var rmsValues: [Float]
    var rmsFramesPerSecond: Double

    public var playbackEndTime: TimeInterval {
        let duration = fileEndTime - fileStartTime
        return playbackStartTime + duration
    }
    
    var audioFileURL: URL // Add this property

    public init(audioFileURL: URL, playbackStartTime: TimeInterval, rmsFramesPerSecond: Double) throws {
        do {
            self.audioFileURL = audioFileURL
            self.playbackStartTime = playbackStartTime
            self.rmsFramesPerSecond = rmsFramesPerSecond
            audioFile = try AVAudioFile(forReading: audioFileURL)
            rmsValues = AudioHelpers.getRMSValues(url: audioFileURL, rmsFramesPerSecond: rmsFramesPerSecond)
            fileEndTime = audioFile.duration
        } catch {
            throw error
        }
    }
}
