//
//  MultiSegmentPlayerView.swift
//  MultiSegmentPlayer
//
//  Created by Gavin Kwon on 7/26/23.
//

import SwiftUI

struct MultiSegmentPlayerView: View {
//    @ObservedObject var conductor = MultiSegmentPlayerConductor()
    @EnvironmentObject var accountModel: AccountModel

    var currentTimeText: String {
        let currentTime = String(format: "%.1f", accountModel.timeStamp)
        let endTime = String(format: "%.1f", accountModel.endTime)
        return currentTime + " of " + endTime
    }

    var currentPlayPosition: CGFloat {
        let pixelsPerSecond = accountModel.pixelsPerRMS * accountModel.rmsFramesPerSecond
        return accountModel.timeStamp * pixelsPerSecond - playheadWidth
    }

    let playheadWidth: CGFloat = 2

    var body: some View {
        VStack {
            ZStack(alignment: .leading) {
                TrackView(segments: accountModel.segments,
                          rmsFramesPerSecond: accountModel.rmsFramesPerSecond,
                          pixelsPerRMS: accountModel.pixelsPerRMS)

                Rectangle()
                    .fill(.red)
                    .frame(width: playheadWidth)
                    .offset(x: currentPlayPosition)
            }
            .frame(height: 200)
            .padding()

            PlayPauseView(isPlaying: $accountModel.isPlaying, accountModel: accountModel).frame(height: 30)

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
