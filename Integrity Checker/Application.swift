//
//  Integrity_CheckerApp.swift
//  Integrity Checker
//
//  Created by Marvin Peter on 2024-05-18.
//

import SwiftUI

@main
struct Application: App {
    @StateObject var appState = AppState()

    var body: some Scene {
        WindowGroup("Integrity Checker") {
            ContentView()
                .environmentObject(appState)
        }
    }
}
