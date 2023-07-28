//
//  AudioTrackView.swift
//  UserAudioApp_0608
//
//  Created by Gavin Kwon on 6/8/23.
//

import SwiftUI

struct SectionInfo: Identifiable, Equatable, Codable {
    
    var id = UUID().uuidString
    var title: String
    var tracks: [Track] = []
    var selectedTrack: String?
    
    struct Track: Identifiable, Equatable, Codable {
        var id = UUID().uuidString
        var items: [String] = []
    }
    
}

struct AudioTrackView: View {
    
    @EnvironmentObject var accountModel: AccountModel
    
    // This array already exists as String array of song titles
//    @State var tracks = ["test1", "test2"]
    
    // This array will save the newly downloaded audio file names
    @State var audioFiles: [String] = []
    
    // This array will save filePath of downloaded audio files
    @State private var fileURLs: [URL] = []
    
    // This variable will trigger fileImport modifier
    @State var openFiles = false
    
    // Audio Player on/off button
    @State private var isPlayerOn = false
    
    // Show/Hide third row
    @State private var showThirdRow = false
    
    // Error messages
    @State private var errorMessage: String?
    
    @State private var sections: [SectionInfo] = []
//    [
//        SectionInfo(title: "Song 1"),
//        SectionInfo(title: "Song 2"),
//        SectionInfo(title: "Song 3"),
//        SectionInfo(title: "Song 4")
//    ]
    
    @State private var isOnAppearCalled = false // for calling on appear only once
    
    
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
                        
                    }
                    
                }
            }
        }
        .onAppear(perform: {
            
            guard isOnAppearCalled == false else { return }
            isOnAppearCalled = true
            
            var sec: [SectionInfo] = []
            
            for track in accountModel.tracks {
                sec.append(SectionInfo(title: track))
            }
            
            self.sections = sec

        })
        .onChange(of: accountModel.tracks) { newValue in
            var sec: [SectionInfo] = []
            
            for track in accountModel.tracks {
                sec.append(SectionInfo(title: track))
            }
            
            self.sections = sec
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
            guard let receivedItem = values.first else { return true }
            removeFromAllSections(itemToRemove: receivedItem)
            audioFiles.append(receivedItem)
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
                
                ForEach($sections) { sectionInfo in
                                        
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
                            trackTitle: track.items[0].wrappedValue,
                            sectionInfo: sectionInfo)
                            .frame(maxHeight: .greatestFiniteMagnitude)
                        
                        
                        Divider()
                        
                        
                        //-------------------------------------------------- Row 2
                        
                        if track.wrappedValue.items.count > 1 {
                            SectionListRowView(
                                geo: geo,
                                trackTitle: track.items[1].wrappedValue,
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
                        
                        print("receivedItem: \(receivedItem)")
                        print("section info: \(sectionInfo.wrappedValue.toDictionary().toString())")
                        print(sectionInfo.wrappedValue)
                        
                        // get new index of the drop zone
                        guard let newIndex = sectionInfo.wrappedValue.tracks.firstIndex(where: { $0.id == trackId }) else { return false }
                        
                        // add item to the drop zone index
                        sectionInfo.wrappedValue.tracks[newIndex].items.append(receivedItem)
                        
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
            sectionInfo.wrappedValue.tracks.append(SectionInfo.Track(items: [item]))
            return true
        }

    }
    
    private func SectionListRowView(geo: GeometryProxy, trackTitle: String, sectionInfo: Binding<SectionInfo>) -> some View {
        
        Text(getIndex(trackTitle: trackTitle, tracks: sectionInfo.wrappedValue.tracks))
            .frame(height: 30)
            .frame(width: geo.size.width/6.8)
            .background(Color.gray.opacity(trackTitle == sectionInfo.wrappedValue.selectedTrack ? 0.5 : 0))
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
            
            Text("AUDIO PLAYER")
                .font(Font.custom("Futura Medium", size: geo.size.width*0.04))
                .frame(maxWidth: .infinity, alignment: .leading)
            
            ZStack {
                Rectangle()
                    .frame(height: geo.size.height*0.15)
                    .cornerRadius(15)
                    .shadow(color: Color("shadowColor"), radius: 10)
                    .foregroundColor(Color("selectedColor"))
                    .opacity(0.8)
                
                HStack(spacing: geo.size.width*0.08) {
                    Button(action: {}, label: {
                        Image(systemName: "backward.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: geo.size.width*0.12)
                            .foregroundColor(.white)
                    })
                    
                    Button(action: {
                        isPlayerOn.toggle()
                    }, label: {
                        Image(systemName: isPlayerOn ? "pause.circle.fill" : "play.circle.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: geo.size.width*0.17)
                            .foregroundColor(.white)
                    })
                    
                    Button(action: {}, label: {
                        Image(systemName: "forward.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: geo.size.width*0.12)
                            .foregroundColor(.white)
                    })
                }
            }
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
        let index = tracks.firstIndex(where: { $0.items.contains(trackTitle)}) ?? -1
        return "\(index + 1)"
    }
    
    private func filesImported(result: Result<[URL], Error>) {
        
        do {
            let fileURLs = try result.get()
            self.fileURLs = fileURLs
            self.audioFiles = fileURLs.map { $0.lastPathComponent }
        } catch {
            errorMessage = error.localizedDescription
        }
        
    }
    
    private func removeFromAllSections(itemToRemove: String) {
        
        // looping through index of every section
        for sectionIndex in 0 ..< self.sections.count {
            
            // looping through index of every track
            for trackIndex in 0 ..< sections[sectionIndex].tracks.count {
                
                // remove selected track
                if itemToRemove == sections[sectionIndex].selectedTrack {
                    sections[sectionIndex].selectedTrack = ""
                }
                
                // remove all items matching the name of the song to remove
                sections[sectionIndex].tracks[trackIndex].items.removeAll(where: { $0 == itemToRemove } )
                
            }
            
            // remove the tracks which have empty tracks
            sections[sectionIndex].tracks.removeAll(where: {$0.items.count == 0})
            
        }
        
        // remove from audio files
        audioFiles.removeAll(where: { $0 == itemToRemove })
        
    }

}


// MARK: Preview
// MARK: -
struct AudioTrackView_Previews: PreviewProvider {
    static var previews: some View {
        AudioTrackView()
            .environmentObject(AccountModel())
    }
}
