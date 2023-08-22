//
//  MultiSegmentPlayerView.swift
//  MultiSegmentPlayer
//
//  Created by Gavin Kwon on 7/26/23.
//

import SwiftUI

struct CustomPlayerView: View {
    
    @ObservedObject var model: MainModel

    let playheadWidth: CGFloat = 2
    var geo: GeometryProxy

    var body: some View {
        
        VStack {
            
            ZStack(alignment: .leading) {
                TrackView(segments: model.segments,
                          rmsFramesPerSecond: model.rmsFramesPerSecond,
                          pixelsPerRMS: model.pixelsPerRMS)

                Rectangle()
                    .fill(.red)
                    .frame(width: playheadWidth)
                    .offset(x: currentPlayPosition())
            }
            .frame(height: 100)
            .padding()

            
            VStack {
                
                HStack(spacing: geo.size.width*0.08) {
                    
                    //-------------------------------------------------- Back
                    
                    BackwardButtonView()
                    
                    
                    //-------------------------------------------------- Play/pause
                    
                    PlayPauseButtonView()
                    
                    
                    //-------------------------------------------------- Forward
                    
                    ForwardButtonView()

                }
                
                //-------------------------------------------------- Time
                
                Text(currentTimeText())
                    .foregroundColor(.white)
                
            }
            .frame(maxWidth: .greatestFiniteMagnitude)
            .background(BackgroundRectangleView())

            Spacer()
        }
    }


}

// MARK: - View Functions
// MARK: -
extension CustomPlayerView {
    
    private func PlayPauseButtonView() -> some View {
        
        Button(action: {
            model.isPlaying.toggle()
            //model.createSegments()
        }, label: {
            Image(systemName: model.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: geo.size.width*0.17)
                .foregroundColor(.white)
        })
        
    }
    
    private func ForwardButtonView() -> some View {
        
        Button(action: {
            model.titleDisplayIndex = (model.titleDisplayIndex + 1) % model.tracks.count
        }, label: {
            Image(systemName: "forward.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: geo.size.width*0.12)
                .foregroundColor(.white)
        })
        
    }
    
    private func BackwardButtonView() -> some View {
        
        Button(action: {
            if model.titleDisplayIndex > 0 {
                model.titleDisplayIndex -= 1
            } else {
                model.titleDisplayIndex = model.tracks.count - 1
            }
        }, label: {
            Image(systemName: "backward.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: geo.size.width*0.12)
                .foregroundColor(.white)
        })
        
    }
    
    private func BackgroundRectangleView() -> some View {
        
        Rectangle()
            .frame(height: geo.size.height*0.17)
            .cornerRadius(15)
            .shadow(color: Color("shadowColor"), radius: 10)
            .foregroundColor(Color("selectedColor"))
            .opacity(0.8)
        
    }
    
}

// MARK: - Helper Functions
// MARK: -
extension CustomPlayerView {
    
    private func currentTimeText() -> String {
        let currentTime = String(format: "%.1f", model.timeStamp)
        let endTime = String(format: "%.1f", model.endTime)
        return currentTime + " of " + endTime
    }

    private func currentPlayPosition() -> CGFloat {
        let pixelsPerSecond = model.pixelsPerRMS * model.rmsFramesPerSecond
        return model.timeStamp * pixelsPerSecond - playheadWidth
    }
    
}
