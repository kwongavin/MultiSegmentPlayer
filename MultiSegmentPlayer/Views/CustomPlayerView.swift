//
//  MultiSegmentPlayerView.swift
//  MultiSegmentPlayer
//
//  Created by Gavin Kwon on 7/26/23.
//

import SwiftUI

struct CustomPlayerView: View {
    
    @ObservedObject var accountModel: AccountModel

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
    
    var geo: GeometryProxy

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
                        if accountModel.titleDisplayIndex > 0 {
                            accountModel.titleDisplayIndex -= 1
                        } else {
                            accountModel.titleDisplayIndex = accountModel.tracks.count - 1
                        }
                    }, label: {
                        Image(systemName: "backward.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: geo.size.width*0.12)
                            .foregroundColor(.white)
                    })
                    
                    Button(action: {
                        accountModel.isPlayerOn.toggle()
                        accountModel.createSegments()
                    }, label: {
                        Image(systemName: accountModel.isPlayerOn ? "pause.circle.fill" : "play.circle.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: geo.size.width*0.17)
                            .foregroundColor(.white)
                    })
                    
                    Button(action: {
                        accountModel.titleDisplayIndex = (accountModel.titleDisplayIndex + 1) % accountModel.tracks.count
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
