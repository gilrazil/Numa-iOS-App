import FirebaseCore
//  NumaApp.swift
//  Numa
//
//  Created by GIl Raz on 21/07/2025.
//

import SwiftUI

@main
struct NumaApp: App {
    init() {
        FirebaseApp.configure()
        print("🔥 Firebase configured: \(String(describing: FirebaseApp.app()?.options.projectID))")
    }
    var body: some Scene {
        WindowGroup {
            SplashScreen()
        }
    }
}
