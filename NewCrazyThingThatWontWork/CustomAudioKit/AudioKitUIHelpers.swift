//
//  AudioKitUIHelpers.swift
//  MultiSegmentPlayer
//
//  Created by Gavin Kwon on 7/26/23.
//

import Accelerate
import AVFoundation
import SwiftUI


public enum AudioHelpers {

    /// Get the RMS values from an audio file URL
    /// - Parameters:
    ///   - url: Audio file URL
    ///   - windowSize: Number of samples per window
    /// - Returns: An array of RMS values (float)
    public static func getRMSValues(url: URL, windowSize: Int) -> [Float] {
        if let audioInformation = loadAudioSignal(audioURL: url) {
            let signal = audioInformation.signal

            guard windowSize < signal.count else { return [] }

            return createRMSAnalysisArray(signal: signal, windowSize: windowSize)
        }
        return []
    }

    /// Get the RMS values from an audio file URL
    /// - Parameters:
    ///   - url: Audio file URL
    ///   - rmsFramesPerSecond: number of rms frames per seconds
    /// - Returns: An array of RMS values (float)
    public static func getRMSValues(url: URL, rmsFramesPerSecond: Double) -> [Float] {
        if let audioInformation = loadAudioSignal(audioURL: url) {
            let signal = audioInformation.signal
            let windowSize = Int(audioInformation.rate / rmsFramesPerSecond)

            guard windowSize < signal.count else { return [] }

            return createRMSAnalysisArray(signal: signal, windowSize: windowSize)
        }
        return []
    }

    private static func createRMSAnalysisArray(signal: [Float], windowSize: Int) -> [Float] {
        let numberOfSamples = signal.count
        let numberOfOutputArrays = numberOfSamples / windowSize
        var outputArray: [Float] = []
        for index in 0 ... numberOfOutputArrays - 1 {
            let startIndex = index * windowSize
            let endIndex = startIndex + windowSize >= signal.count ? signal.count - 1 : startIndex + windowSize
            let arrayToAnalyze = Array(signal[startIndex ..< endIndex])
            var rms: Float = 0
            vDSP_rmsqv(arrayToAnalyze, 1, &rms, UInt(windowSize))
            outputArray.append(rms)
        }
        return outputArray
    }
}
