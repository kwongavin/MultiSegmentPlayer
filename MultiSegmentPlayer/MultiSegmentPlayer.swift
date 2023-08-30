//
//  NewCrazyThingThatWontWorkApp.swift
//  NewCrazyThingThatWontWork
//
//  Created by Gavin Kwon on 7/27/23.
//

import SwiftUI
import AVKit

@main
struct NewCrazyThingThatWontWorkApp: App {
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            AudioTrackView()
        }
    }
}



class AppDelegate: NSObject, UIApplicationDelegate {
    // Implement any necessary AppDelegate methods here
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        //initializeAudio()
        return true
    }
    
    
    func initializeAudio() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .default)
            try audioSession.setActive(true)
        } catch {
            print("Failed to configure audio session: \(error)")
        }
    }
    
    
}
