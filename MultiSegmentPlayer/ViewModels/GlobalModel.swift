//
//  GlobalModel.swift
//  MultiSegmentPlayer
//
//  Created by Sibtain Ali on 24-08-2023.
//

import Foundation

let GlobalModel = GlobalViewModel.shared


class GlobalViewModel: ObservableObject {
    
    static let shared = GlobalViewModel()
    
    @Published var playingUrl: String = ""
    
    // initialization
    private init() {
        
    }
    
}


// MARK: - Helper Functions
// MARK: -
extension GlobalViewModel {
    
}

