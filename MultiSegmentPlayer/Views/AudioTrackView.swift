//
//  AudioTrackView.swift
//  UserAudioApp_0608
//
//  Created by Gavin Kwon on 6/8/23.
//

import SwiftUI

struct AudioTrackView: View {
    
    @StateObject var model = MainModel()
    
    // This array will save the newly downloaded audio file names
    @State var audioFiles: [String] = []
    
    // This array will save filePath of downloaded audio files
    @State private var fileURLs: [URL] = []
    
    // This variable will trigger fileImport modifier
    @State var openFiles = false
    
    // Show/Hide third row
    @State private var showThirdRow = false
    
    // Error messages
    @State private var errorMessage: String?
    
    @State private var isOnAppearCalled = false // for calling on appear only once
    
    @StateObject var global = GlobalModel
        
    var body: some View {
        
        GeometryReader { geo in
            
            VStack {
                
                //-------------------------------------------------- Audio Files
                
                AudioFilesView(geo: geo)
                
                ScrollView(showsIndicators: false) {
                    
                    VStack {
                        
                        //-------------------------------------------------- Songs
                        
                        SectionView(geo: geo)
                        
                        //-------------------------------------------------- Audio Player
                        
                        AudioPlayerView(geo: geo)
                        
                        //-------------------------------------------------- Reset Button
                        
                        AudioResetButton(geo: geo)
                        
                    }
                    
                }
            }
        }
        .onAppear(perform: {
            
            guard isOnAppearCalled == false else { return }
            isOnAppearCalled = true
            
            var sec: [SectionInfo] = []
            
            for track in model.tracks {
                sec.append(SectionInfo(title: track))
            }
            
            model.sections = sec

        })
        .onChange(of: model.tracks) { newValue in
            var sec: [SectionInfo] = []
            
            for track in model.tracks {
                sec.append(SectionInfo(title: track))
            }
            
            model.sections = sec
        }
        .onChange(of: global.playingUrl) { newValue in
            model.trackEnded(url: global.playingUrl)
        }
    }
    
}


// MARK: - Audio Files View Functions
// MARK: -
extension AudioTrackView {
    
    private func AudioFilesView(geo: GeometryProxy) -> some View {
        
        VStack {
            
            //-------------------------------------------------- Title
            
            AudioFilesTitleView(geo: geo)
            
            
            if errorMessage != nil {
                
                //-------------------------------------------------- Error Message
                
                ErrorMessageView(geo: geo)
            }
            
            
            if !audioFiles.isEmpty {
                
                //-------------------------------------------------- Selected Files List
                
                AudioFilesListView(geo: geo)
                
            }
            else {
                
                //-------------------------------------------------- Open iCloud Files Button
                
                SelectFilesButtonView(geo: geo)
                
            }
            
        }
        .padding([.horizontal, .top])
        //-------------------------------------------------- Audio Files Imported
        .fileImporter(isPresented: $openFiles, allowedContentTypes: [.audio], allowsMultipleSelection: true) { result in filesImported(result: result)}
        //-------------------------------------------------- Audio Files Changed
        .onChange(of: audioFiles) { _ in
            print(audioFiles)
            print(fileURLs)
        }
        .dropDestination(for: String.self) { values, _ in
            // main list of audio files at the top
            guard let receivedItem = values.first else { return true }
            removeFromAllSections(itemToRemove: receivedItem)
            audioFiles.append(receivedItem)
            audioFiles.sort()
            
            // reset the audio player view
            model.isPlaying = false
            model.endTime = 0
            model._timeStamp = 0
            model.createSegments()
            return true
        }

    }
    
    private func AudioFilesTitleView(geo: GeometryProxy) -> some View {
        
        HStack {
            
            //-------------------------------------------------- Title
            
            Text("AUDIO TRACKS")
                .font(Font.custom("Futura Medium", size: geo.size.width*0.04))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom)
            
            if !audioFiles.isEmpty {
                
                HStack(spacing: geo.size.width*0.04) {
                    
                    //-------------------------------------------------- Remove Files Button
                    
                    Button(action: {
                        audioFiles.removeAll()
                        fileURLs.removeAll()
                    }, label: {
                        Image(systemName: "xmark.circle")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: geo.size.width*0.07)
                    })
                    
                    //-------------------------------------------------- Add Files Button
                    
                    Button(action: {
                        openFiles.toggle()
                    }, label: {
                        Image(systemName: "folder.badge.plus")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: geo.size.width*0.08)
                    })
                }
                .bold()
                .opacity(0.6)
                .foregroundColor(Color("appColor7"))
            }
        }
    
    }
    
    private func ErrorMessageView(geo: GeometryProxy) -> some View {
        
        Text(errorMessage!)
            .font(Font.custom("Avenir Roman", size: geo.size.width*0.04))
            .foregroundColor(Color("appColor2"))
        
    }
    
    private func AudioFilesListView(geo: GeometryProxy) -> some View {
        
        ZStack {
            
            //-------------------------------------------------- Background Rectangle
            
            AudioFilesListBackgroundView()
            
            ScrollView {
                
                LazyVStack(spacing: geo.size.width*0.03) {
                    
                    //-------------------------------------------------- List of Files
                    
                    ForEach(audioFiles.indices, id: \.self) { r in
                        
                        //-------------------------------------------------- File Row View
                        
                        Text(audioFiles[r])
                            .font(Font.custom("Avenir Heavy", size: geo.size.width*0.035))
                            .padding(8)
                            .frame(maxWidth: .greatestFiniteMagnitude)
                            .background{ AudioFilesRowBackgroundView() }
                            .draggable(audioFiles[r]) { DragView(title: audioFiles[r], geo: geo) }
                    }
                }
                .padding()
                
            }
            
        }
        .frame(height: geo.size.height*0.2)
    }
    
    private func DragView(title: String, geo: GeometryProxy) -> some View {
        
        Text(title)
            .font(Font.custom("Avenir Heavy", size: geo.size.width*0.035))
            .padding(8)
            .background {
                Rectangle()
                    .foregroundColor(Color("bgColor4"))
                    .opacity(0.8)
            }
        
    }
    
    private func SelectFilesButtonView(geo: GeometryProxy) -> some View {
        
        Button(action: {
            openFiles.toggle()
        }, label: {
            
            VStack(spacing: geo.size.height*0.02) {
                
                //-------------------------------------------------- Icon
                
                Image(systemName: "folder.badge.plus")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: geo.size.width*0.1)
                    .bold()
                
                
                //-------------------------------------------------- Text
                
                Text("Select Audio Files from iCloud Drive")
                    .font(Font.custom("Avenir Roman", size: geo.size.width*0.04))
                
            }
            .frame(maxWidth: .greatestFiniteMagnitude)
            .frame(height: geo.size.height*0.2)
            .background{ AudioFilesListBackgroundView() }
            .foregroundColor(Color("appColor7"))
            
        })
    }
    
}


// MARK: - Song View Functions
// MARK: -
extension AudioTrackView {
    
    private func SectionView(geo: GeometryProxy) -> some View {
        
        Group {
            
            VStack {
                
                ForEach($model.sections) { sectionInfo in
                                        
                    VStack {
                        
                        //-------------------------------------------------- Heading
                        
                        SongHeadingView(geo: geo, name: sectionInfo.title.wrappedValue, songTitle: sectionInfo.selectedTrack.wrappedValue ?? "")
                            
                        //-------------------------------------------------- List
                            
                        SectionListView(geo: geo, sectionInfo: sectionInfo)
                            .frame(maxWidth: .greatestFiniteMagnitude)
                            .frame(height: geo.size.height*0.15)
                            .overlay(DragSongFilesView(geo: geo, name: sectionInfo.title.wrappedValue, count: sectionInfo.tracks.wrappedValue.count))
                            .background(SongInfoBackgroundView(geo: geo))
                            .padding(.bottom, geo.size.height*0.02)
                        
                    }
                    .padding(.horizontal)

                    
                }
                
            }
            .padding(.top)
            
        }
        
    }
    
    private func SectionListView(geo: GeometryProxy, sectionInfo: Binding<SectionInfo>) -> some View {
        
        ScrollView(.horizontal, showsIndicators: false){
            
            LazyHStack {
                
                ForEach(sectionInfo.tracks) { track in
                    
                    VStack(spacing: 0) {
                        
                        //-------------------------------------------------- Row 1
                        
                        SectionListRowView(
                            geo: geo,
                            trackTitle: track.wrappedValue.items[0].name,
                            url: track.wrappedValue.items[0].url?.absoluteString ?? "",
                            sectionInfo: sectionInfo)
                            .frame(maxHeight: .greatestFiniteMagnitude)
                        
                        
                        Divider()
                        
                        
                        //-------------------------------------------------- Row 2
                        
                        if track.wrappedValue.items.count > 1 {
                            SectionListRowView(
                                geo: geo,
                                trackTitle: track.wrappedValue.items[1].name,
                                url: track.wrappedValue.items[1].url?.absoluteString ?? "",
                                sectionInfo: sectionInfo)
                                .frame(maxHeight: .greatestFiniteMagnitude)
                        }
                        else {
                            Text("")
                                .frame(maxHeight: .greatestFiniteMagnitude)
                                .frame(width: geo.size.width/6.8)
                                .background(Color.red.opacity(0.01))
                                .opacity(0.01)
                        }
                        
                    }
                    .frame(maxHeight: .greatestFiniteMagnitude)
                    .dropDestination(for: String.self) { values, _ in
                        guard let receivedItem = values.first else { return true }
                        let trackId = track.wrappedValue.id
                        
                        // get index of the drop zone
                        guard let index = sectionInfo.wrappedValue.tracks.firstIndex(where: { $0.id == trackId }) else { return false }
                        
                        // check if the index where item is gonna be dropped already had 2 elements
                        guard sectionInfo.wrappedValue.tracks[index].items.count < 2 else { return false }
                        
                        // remove dragged item from all sections
                        removeFromAllSections(itemToRemove: receivedItem)
                        
                        // get new index of the drop zone after removing the item
                        guard let newIndex = sectionInfo.wrappedValue.tracks.firstIndex(where: { $0.id == trackId }) else { return false }
                        
                        // add item to the drop zone index
                        // save the dropped URL in the track's URL property
                        if let url = fileURLs.first(where: { $0.lastPathComponent == receivedItem }) {
                            
                            sectionInfo.wrappedValue.tracks[newIndex].items.append(SectionInfo.TrackInfo(name: receivedItem, url: url))
                        }
                        
                        model.createSegments()
                        printOnDebug(sectionInfo.wrappedValue)
                        
                        return true
                    }
                    
                    
                }
                
                Spacer()
                
            }
            .frame(maxHeight: .greatestFiniteMagnitude)
            .padding(.horizontal)
        }
        .dropDestination(for: String.self) { values, _ in
            guard let item = values.first else { return true }
            removeFromAllSections(itemToRemove: item)
            
            // save the dropped URL in the track's URL property
            if let fileUrl = fileURLs.first(where: { $0.lastPathComponent == item }) {
                let track = SectionInfo.Track(items: [SectionInfo.TrackInfo(name: item, url: fileUrl)])
                sectionInfo.wrappedValue.tracks.append(track)
                model.createSegments()
            }

            
            return true
        }

    }
    
    private func SectionListRowView(geo: GeometryProxy, trackTitle: String, url: String, sectionInfo:Binding<SectionInfo>) -> some View {
        
        Text(getIndex(trackTitle: trackTitle, tracks: sectionInfo.wrappedValue.tracks))
            .frame(height: 30)
            .frame(width: geo.size.width/6.8)
            .background(Color.gray.opacity(trackTitle == sectionInfo.wrappedValue.selectedTrack ? 0.5 : 0))
            .background(isCurrentlyPlaying(url: url) ? Color.pink : Color.clear)
            .background{ AudioFilesRowBackgroundView() }
            .cornerRadius(10)
            .contentShape(Rectangle())
            .onTapGesture {
                sectionInfo.wrappedValue.selectedTrack = trackTitle
            }
            .draggable(String(trackTitle)) {
                DragView(title: trackTitle, geo: geo)
            }
        
        
    }
    
    private func SongHeadingView(geo: GeometryProxy, name: String, songTitle: String) -> some View {
        
        HStack {
            
            Text(name) // Song Title
                .font(Font.custom("Avenir Roman", size: geo.size.width*0.04))
                .foregroundColor(.white)
            
            Spacer()
            
            Text(songTitle) // File Name
                .font(Font.custom("Avenir", size: geo.size.width*0.035))
                .foregroundColor(.white)

            
        }
        .frame(height: geo.size.height*0.04)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, geo.size.width*0.03)
        .background {
            Rectangle()
                .frame(height: geo.size.height*0.04)
                .cornerRadius(6)
                .foregroundColor(Color("textColor3"))
        }
        
        
    }
    
    private func DragSongFilesView(geo: GeometryProxy, name: String, count: Int) -> some View {
        Text("Drag Audio Files Here for\n<\(name)>")
            .font(Font.custom("Avenir Roman", size: geo.size.width*0.04))
            .multilineTextAlignment(.center)
            .foregroundColor(Color("appColor7"))
            .opacity(count > 0 ? 0 : 1)
            .allowsHitTesting(false)
    }
    
}


// MARK: - Audio Player Functions
// MARK: -
extension AudioTrackView {
    
    private func AudioPlayerView(geo: GeometryProxy) -> some View {
        
        Group {
            
            Divider()
            
            HStack {
                Text("AUDIO PLAYER")
                Spacer()
                if model.isPlaying {
                    Text("::: \(model.getSectionName())")
                }
            }
            .font(Font.custom("Futura Medium", size: geo.size.width*0.04))
            .frame(maxWidth: .infinity, alignment: .leading)
            
            CustomPlayerView(model: model, geo: geo)
            
        }
        .padding()
    }

}


// MARK: - Helper View Functions
// MARK: -
extension AudioTrackView {
    
    private func DividerView() -> some View {
        
        Group {
            Spacer()
            Divider()
            Spacer()
        }
        
    }
    
    private func AudioFilesListBackgroundView() -> some View {
        
        Rectangle()
            .cornerRadius(15)
            .foregroundColor(Color("mainColor"))
            .opacity(0.5)
            .shadow(color: Color("shadowColor"), radius: 10)
        
    }
    
    private func AudioFilesRowBackgroundView(cornerRadius: CGFloat = 10) -> some View {
        
        Rectangle()
            .cornerRadius(cornerRadius)
            .foregroundColor(Color("bgColor4"))
            .opacity(0.8)
//            .shadow(color: Color("selectedColor"), radius: 0.1, x: 2, y: 3)
        
    }
    
    private func SongInfoBackgroundView(geo: GeometryProxy) -> some View {
        Rectangle()
            .frame(height: geo.size.height*0.15)
            .cornerRadius(15)
            .shadow(color: Color("shadowColor"), radius: 10)
            .foregroundColor(Color("mainColor"))
            .opacity(0.5)
    }
    
}


// MARK: - Helper Functions
// MARK: -
extension AudioTrackView {
    
    private func getIndex(trackTitle: String, tracks: [SectionInfo.Track]) -> String {
        let index = tracks.firstIndex(where: { $0.items.map({ $0.name}).contains(trackTitle)}) ?? -1
        return "\(index + 1)"
    }
    
    private func filesImported(result: Result<[URL], Error>) {
        
        do {
            let fileURLs = try result.get()
            self.fileURLs = fileURLs
            self.audioFiles = fileURLs.map { $0.lastPathComponent }
            self.audioFiles.sort()
            
        } catch {
            errorMessage = error.localizedDescription
        }
        
    }
    
    private func removeFromAllSections(itemToRemove: String) {
        
        // looping through index of every section
        for sectionIndex in 0 ..< model.sections.count {
            
            // looping through index of every track
            for trackIndex in 0 ..< model.sections[sectionIndex].tracks.count {
                
                // remove selected track
                if itemToRemove == model.sections[sectionIndex].selectedTrack {
                    model.sections[sectionIndex].selectedTrack = ""
                }
                
                // remove all items matching the name of the song to remove
                model.sections[sectionIndex].tracks[trackIndex].items.removeAll(where: { $0.name == itemToRemove } )
                
            }
            
            // remove the tracks which have empty tracks
            model.sections[sectionIndex].tracks.removeAll(where: {$0.items.count == 0})
            
        }
        
        // remove from audio files
        audioFiles.removeAll(where: { $0 == itemToRemove })
        
    }
    
    private func isCurrentlyPlaying(url: String) -> Bool {
        
        // check if player is playing
        guard model.isPlaying else { return false }
        
        // handling for first track
        if global.playingUrl == "first track", url == model.segments2d[model.playingSegmentIndex].first?.audioFileURL.absoluteString ?? "" { return true }
        
        // get the index of the of the file that just finished playing
        guard let indexOfFinishedTrack = model.segments2d[model.playingSegmentIndex].firstIndex(where: {$0.audioFileURL.absoluteString == global.playingUrl }) else { return false }
        
        // index of the next track
        let nextTrackIndex = indexOfFinishedTrack + 1
        
        // return if its the last track
        guard nextTrackIndex < model.segments2d[model.playingSegmentIndex].count else { return false }
        
        return url == model.segments2d[safe: model.playingSegmentIndex]?[safe: nextTrackIndex]?.audioFileURL.absoluteString
        
    }
    
    private func resetAudioTracks() {
        
        var tracksNames = [String]()
        
        // get all tracks
        for section in model.sections {
            for track in section.tracks {
                tracksNames.append(contentsOf: track.items.map({$0.name}))
            }
        }
        
        // add tracks in audio files
        self.audioFiles.append(contentsOf: tracksNames)
        self.audioFiles.sort()
        
        // remove tracks from all sections
        for index in 0 ..< model.sections.count {
            model.sections[index].tracks.removeAll()
            model.sections[index].selectedTrack = nil
        }
        
        // remove all tracks from segments
        model.isPlaying = false
        model.segments2d.removeAll()
        model.createSegments()
        model.endTime = 0
        model._timeStamp = 0
        
    }


}

// MARK: Reset Button
extension AudioTrackView {
    
    private func AudioResetButton(geo: GeometryProxy) -> some View {
                  
        VStack {
            Button(action: {

                customAlertApple(title: "Reset Tracks?", message: "Are you sure you want to reset all tracks?", showDestructive: true) { success in
                    guard success else { return }
                    resetAudioTracks()
                }
                
            }, label: {
                
                ZStack {
                    
                    Rectangle()
                        .cornerRadius(10)
                        .foregroundColor(Color("appColor2"))
                    
                    
                    Text("Reset Audio Tracks")
                        .font(Font.custom("Avenir Roman", size: geo.size.width*0.04))
                        .foregroundColor(.white)
                        .padding(.vertical)
                    
                }
                
            })
            .padding()
            .padding(.top)
        }
        
    }

}


// MARK: Preview
// MARK: -
struct AudioTrackView_Previews: PreviewProvider {
    static var previews: some View {
        AudioTrackView()
            .environmentObject(MainModel())
    }
}
