//
//  ContentView.swift
//  Numa
//
//  Created by GIl Raz on 21/07/2025.
//

import SwiftUI
import AVFoundation
import Photos

struct ContentView: View {
    @EnvironmentObject var userService: UserService
    @State private var showingUserData = false
    @State private var showingImagePicker = false
    @State private var showingCamera = false
    @State private var selectedImage: UIImage?
    @State private var navigateToMealAnalysis = false
    @State private var showingMealHistory = false
    @State private var showingPermissionAlert = false
    @State private var permissionAlertMessage = ""
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    // Welcome Header
                    VStack(spacing: 12) {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 50))
                            .foregroundColor(Color("NumaPurple"))
                        
                        Text(LocalizedStringKey("welcome_home_title"))
                            .font(.title)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                        
                        Text(LocalizedStringKey("track_your_meals"))
                            .font(.title3)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 20)
                    
                    // Meal Photo Capture Section
                    VStack(spacing: 20) {
                        Text(LocalizedStringKey("capture_meal_title"))
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        VStack(spacing: 16) {
                            // Take Photo Button
                            Button(action: {
                                requestCameraPermission()
                            }) {
                                MealCaptureButton(
                                    icon: "camera.fill",
                                    title: LocalizedStringKey("take_photo_button"),
                                    subtitle: LocalizedStringKey("take_photo_subtitle"),
                                    color: Color("NumaPurple")
                                )
                            }
                            
                            // Choose from Library Button
                            Button(action: {
                                requestPhotoLibraryPermission()
                            }) {
                                MealCaptureButton(
                                    icon: "photo.on.rectangle",
                                    title: LocalizedStringKey("choose_photo_button"),
                                    subtitle: LocalizedStringKey("choose_photo_subtitle"),
                                    color: .blue
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Meal History Section
                    VStack(spacing: 16) {
                        VStack(spacing: 8) {
                            Text(LocalizedStringKey("meal_history_section"))
                                .font(.headline)
                                .fontWeight(.semibold)
                                .multilineTextAlignment(.center)
                            
                            Text(LocalizedStringKey("view_past_analyses"))
                                .font(.body)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        
                        // Meal History Button
                        Button(action: {
                            showingMealHistory = true
                        }) {
                            HStack(spacing: 16) {
                                Image(systemName: "clock.arrow.circlepath")
                                    .font(.title2)
                                    .foregroundColor(.white)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(LocalizedStringKey("meal_history_button"))
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.white)
                                    
                                    Text(LocalizedStringKey("view_nutrition_insights"))
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.8))
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.body)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white.opacity(0.7))
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(
                                        LinearGradient(
                                            colors: [Color("NumaPurple"), Color("NumaPurple").opacity(0.8)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .shadow(color: Color("NumaPurple").opacity(0.3), radius: 8, x: 0, y: 4)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(.white.opacity(0.2), lineWidth: 1)
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    
                    // Data verification section (for development)
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
                    .padding(.horizontal, 20)
                    
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
                    .padding(.bottom, 40)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarHidden(true)
            .navigationDestination(isPresented: $navigateToMealAnalysis) {
                if let image = selectedImage {
                    MealAnalysisView(mealImage: image)
                }
            }
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(image: $selectedImage, sourceType: .photoLibrary) {
                if selectedImage != nil {
                    navigateToMealAnalysis = true
                }
            }
        }
        .sheet(isPresented: $showingCamera) {
            ImagePicker(image: $selectedImage, sourceType: .camera) {
                if selectedImage != nil {
                    navigateToMealAnalysis = true
                }
            }
        }
        .sheet(isPresented: $showingMealHistory) {
            MealHistoryView()
        }
        .alert(LocalizedStringKey("permission_required"), isPresented: $showingPermissionAlert) {
            Button(LocalizedStringKey("open_settings")) {
                openSettings()
            }
            Button(LocalizedStringKey("cancel_button"), role: .cancel) { }
        } message: {
            Text(LocalizedStringKey(permissionAlertMessage))
        }
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
    
    // MARK: - Permission Handling
    private func requestCameraPermission() {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        
        switch status {
        case .authorized:
            showingCamera = true
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    if granted {
                        showingCamera = true
                    } else {
                        showPermissionAlert(for: "camera")
                    }
                }
            }
        case .denied, .restricted:
            showPermissionAlert(for: "camera")
        @unknown default:
            showPermissionAlert(for: "camera")
        }
    }
    
    private func requestPhotoLibraryPermission() {
        let status = PHPhotoLibrary.authorizationStatus()
        
        switch status {
        case .authorized, .limited:
            showingImagePicker = true
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization { status in
                DispatchQueue.main.async {
                    if status == .authorized || status == .limited {
                        showingImagePicker = true
                    } else {
                        showPermissionAlert(for: "photo_library")
                    }
                }
            }
        case .denied, .restricted:
            showPermissionAlert(for: "photo_library")
        @unknown default:
            showPermissionAlert(for: "photo_library")
        }
    }
    
    private func showPermissionAlert(for type: String) {
        permissionAlertMessage = type == "camera" ? "camera_permission_message" : "photo_library_permission_message"
        showingPermissionAlert = true
    }
    
    private func openSettings() {
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsUrl)
        }
    }
}
}

}

// MARK: - Supporting Components

struct MealCaptureButton: View {
    let icon: String
    let title: LocalizedStringKey
    let subtitle: LocalizedStringKey
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 44, height: 44)
                .background(
                    Circle()
                        .fill(color.opacity(0.1))
                )
            
            // Text Content
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Arrow
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(color.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    var sourceType: UIImagePickerController.SourceType
    var onImagePicked: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.image = image
                parent.onImagePicked()
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(UserService.shared)
}
