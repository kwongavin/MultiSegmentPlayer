//
//  AccountModel.swift
//  UserAudioApp_0608
//
//  Created by Gavin Kwon on 6/30/23.
//

import Foundation

class AccountModel: ObservableObject {
    
    // Track names, user can add-subtract this values at any time.
    @Published var tracks: [String] = ["Hey Jude", "Yesterday", "Come Together"]
    
}
