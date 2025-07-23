//
//  ContentView.swift
//  Numa
//
//  Created by GIl Raz on 21/07/2025.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text(LocalizedStringKey("hello_world"))
            
            // TEMPORARY: Developer reset button for testing
            Button("🔄 Reset Onboarding (Dev Only)") {
                UserDefaults.standard.removeObject(forKey: "onboarding_complete")
                UserDefaults.standard.removeObject(forKey: "user_goal")
                UserDefaults.standard.removeObject(forKey: "user_weight_current")
                UserDefaults.standard.removeObject(forKey: "user_weight_target")
                UserDefaults.standard.removeObject(forKey: "user_height")
                UserDefaults.standard.removeObject(forKey: "user_age")
                UserDefaults.standard.removeObject(forKey: "user_gender")
                UserDefaults.standard.removeObject(forKey: "user_activity_level")
                print("Onboarding reset! Restart app to see onboarding flow.")
            }
            .font(.caption)
            .foregroundColor(.gray)
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
