//
//  SectionInfo.swift
//  MultiSegmentPlayer
//
//  Created by Sibtain Ali on 22-08-2023.
//

import Foundation

struct SectionInfo: Identifiable, Equatable, Codable {
    
    var id = UUID().uuidString
    var title: String
    var tracks: [Track] = []
    var selectedTrack: String?
    
    struct Track: Identifiable, Equatable, Codable {
        var id = UUID().uuidString
        var items: [String] = []
        var url: URL?
    }
    
}
