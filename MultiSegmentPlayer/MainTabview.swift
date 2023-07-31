//
//  MainTabview.swift
//  MultiSegmentPlayer
//
//  Created by Gavin Kwon on 7/30/23.
//

import SwiftUI

struct MainTabview: View {
    
    @State private var selection: Int = 0
    
    var body: some View {
        TabView(selection: $selection) {
            MultiSegmentPlayerView()
                .tabItem {
                    VStack {
                        Image(systemName: "house.circle")
                        Text("Player")
                    }
                }
                .tag(0)
            AudioTrackView()
                .tabItem {
                    VStack {
                        Image(systemName: "building.2.crop.circle.fill")
                        Text("Audio")
                    }
                }
                .tag(1)
        }
    }
}

struct MainTabview_Previews: PreviewProvider {
    static var previews: some View {
        MainTabview()
    }
}
