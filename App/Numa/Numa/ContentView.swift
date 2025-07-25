//
//  ContentView.swift
//  Numa
//
//  Created by GIl Raz on 21/07/2025.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var userService: UserService
    @State private var showingUserData = false
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text(LocalizedStringKey("hello_world"))
            
            // Data verification section
            VStack(spacing: 12) {
                let verification = userService.verifyOnboardingData()
                
                if verification.isComplete {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("✅ All onboarding data saved")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                } else {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text("⚠️ Missing: \(verification.missingFields.joined(separator: ", "))")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
                
                // Show user data button
                Button("👤 Show Saved User Data") {
                    showingUserData = true
                    userService.printUserData()
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
            .padding()
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            
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
                UserDefaults.standard.removeObject(forKey: "numa_user_id")
                print("Onboarding reset! Restart app to see onboarding flow.")
            }
            .font(.caption)
            .foregroundColor(.gray)
        }
        .padding()
        .alert("User Data", isPresented: $showingUserData) {
            Button("OK") { }
        } message: {
            if let user = userService.currentUser {
                Text("ID: \(user.id)\nGoal: \(user.goal ?? "Not set")\nCurrent Weight: \(user.currentWeight?.description ?? "Not set")\nTarget Weight: \(user.targetWeight?.description ?? "Not set")\nHeight: \(user.height?.description ?? "Not set")\nAge: \(user.age?.description ?? "Not set")\nGender: \(user.gender ?? "Not set")\nActivity Level: \(user.activityLevel ?? "Not set")")
            } else {
                Text("No user data available")
            }
        }
    }
}

#Preview {
    ContentView()
}
