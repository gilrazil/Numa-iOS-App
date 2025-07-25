import FirebaseCore
import FirebaseFirestore
//  NumaApp.swift
//  Numa
//
//  Created by GIl Raz on 21/07/2025.
//

import SwiftUI

@main
struct NumaApp: App {
    @StateObject private var userService = UserService.shared
    
    init() {
        FirebaseApp.configure()
        print("🔥 Firebase configured: \(String(describing: FirebaseApp.app()?.options.projectID))")
    }
    
    var body: some Scene {
        WindowGroup {
            SplashScreen()
                .environmentObject(userService)
                .onAppear {
                    // Initialize user service when app launches
                    userService.initializeUser()
                    print("👤 UserService initialized")
                }
        }
    }
}
