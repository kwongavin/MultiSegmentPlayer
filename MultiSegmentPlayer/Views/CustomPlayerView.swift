//
//  MultiSegmentPlayerView.swift
//  MultiSegmentPlayer
//
//  Created by Gavin Kwon on 7/26/23.
//

import SwiftUI

struct CustomPlayerView: View {
    
    @ObservedObject var model: MainModel

    var currentTimeText: String {
        let currentTime = String(format: "%.1f", model.timeStamp)
        let endTime = String(format: "%.1f", model.endTime)
        return currentTime + " of " + endTime
    }

    var currentPlayPosition: CGFloat {
        let pixelsPerSecond = model.pixelsPerRMS * model.rmsFramesPerSecond
        return model.timeStamp * pixelsPerSecond - playheadWidth
    }

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
                    .offset(x: currentPlayPosition)
            }
            .frame(height: 200)
            .padding()

            
            ///////////////////////////////////////////////////////////////
            ///
            ///
            ///
            ///
            ///
            ///
            
            ZStack {
                
                Rectangle()
                    .frame(height: geo.size.height*0.15)
                    .cornerRadius(15)
                    .shadow(color: Color("shadowColor"), radius: 10)
                    .foregroundColor(Color("selectedColor"))
                    .opacity(0.8)
                
                HStack(spacing: geo.size.width*0.08) {
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
                    
                    Button(action: {
                        model.isPlayerOn.toggle()
                        model.createSegments()
                    }, label: {
                        Image(systemName: model.isPlayerOn ? "pause.circle.fill" : "play.circle.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: geo.size.width*0.17)
                            .foregroundColor(.white)
                    })
                    
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
            }
            
            
            
            
            /////////////////////////////////////////////////////////////////
            
            
            
            
            
            PlayPauseView(isPlaying: $model.isPlaying, model: model).frame(height: 30)

            Text(currentTimeText)
                .padding(.top)

            Spacer()
        }
    }

    struct PlayPauseView: View {
        @Binding var isPlaying: Bool
        @ObservedObject var model: MainModel

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


//struct MultiSegmentPlayerView_Previews: PreviewProvider {
//    static var previews: some View {
//        CustomPlayerView(accountModel: AccountModel(), geo: GeometryProxy())
//            .environmentObject(AccountModel())
//    }
//}
