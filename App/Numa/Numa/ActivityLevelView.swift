import SwiftUI

struct ActivityLevelView: View {
    @EnvironmentObject var userService: UserService
    @State private var selectedActivityLevel: ActivityLevel? = nil
    @State private var navigateToContent = false
    @State private var isSaving = false
    
    enum ActivityLevel: String, CaseIterable {
        case sedentary = "sedentary"
        case light = "light"
        case moderate = "moderate"
        case active = "active"
        case veryActive = "very_active"
        
        var displayKey: String {
            switch self {
            case .sedentary: return "activity_sedentary"
            case .light: return "activity_light"
            case .moderate: return "activity_moderate"
            case .active: return "activity_active"
            case .veryActive: return "activity_very_active"
            }
        }
        
        var descriptionKey: String {
            switch self {
            case .sedentary: return "activity_sedentary_description"
            case .light: return "activity_light_description"
            case .moderate: return "activity_moderate_description"
            case .active: return "activity_active_description"
            case .veryActive: return "activity_very_active_description"
            }
        }
        
        var color: Color {
            switch self {
            case .sedentary: return .gray
            case .light: return .blue
            case .moderate: return .green
            case .active: return .orange
            case .veryActive: return .red
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                // Header
                VStack(spacing: 12) {
                    Text(LocalizedStringKey("activity_level_title"))
                        .font(.title)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                    
                    Text(LocalizedStringKey("activity_level_subtitle"))
                        .font(.title3)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(.top, 40)
                
                Spacer()
                
                // Activity Level Options
                VStack(spacing: 16) {
                    ForEach(ActivityLevel.allCases, id: \.self) { level in
                        ActivityLevelCard(
                            level: level,
                            isSelected: selectedActivityLevel == level
                        ) {
                            selectedActivityLevel = level
                        }
                    }
                }
                .padding(.horizontal, 20)
                
                Spacer()
                
                // Get Started Button
                Button(action: {
                    if let selectedActivityLevel = selectedActivityLevel {
                        completeOnboarding(with: selectedActivityLevel)
                    }
                }) {
                    HStack {
                        if isSaving {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        }
                        Text(LocalizedStringKey(isSaving ? "completing_onboarding_button" : "get_started_button"))
                    }
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background((selectedActivityLevel != nil && !isSaving) ? Color("NumaPurple") : Color(.systemGray4))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .disabled(selectedActivityLevel == nil || isSaving)
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(isPresented: $navigateToContent) {
                ContentView()
                    .navigationBarBackButtonHidden(true)
            }
        }
    }
    
    private func completeOnboarding(with activityLevel: ActivityLevel) {
        isSaving = true
        
        // First save activity level
        userService.saveOnboardingData(activityLevel: activityLevel.rawValue) { [self] success in
            if success {
                // Then mark onboarding as complete
                userService.completeOnboarding { [self] success in
                    DispatchQueue.main.async {
                        isSaving = false
                        if success {
                            print("✅ Onboarding completed successfully!")
                            // Verify all data was saved
                            let verification = userService.verifyOnboardingData()
                            if verification.isComplete {
                                print("✅ All onboarding data verified complete")
                            } else {
                                print("⚠️ Missing onboarding data: \(verification.missingFields.joined(separator: ", "))")
                            }
                            navigateToContent = true
                        } else {
                            print("❌ Failed to complete onboarding")
                            // Still navigate to continue
                            navigateToContent = true
                        }
                    }
                }
            } else {
                DispatchQueue.main.async {
                    isSaving = false
                    print("❌ Failed to save activity level")
                    // Still navigate to continue
                    navigateToContent = true
                }
            }
        }
    }
}

struct ActivityLevelCard: View {
    let level: ActivityLevelView.ActivityLevel
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Color indicator
                Circle()
                    .fill(level.color)
                    .frame(width: 16, height: 16)
                
                // Text
                VStack(alignment: .leading, spacing: 4) {
                    Text(LocalizedStringKey(level.displayKey))
                        .font(.headline)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                    
                    Text(LocalizedStringKey(level.descriptionKey))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                // Selection indicator
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundColor(isSelected ? Color("NumaPurple") : .secondary)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 18)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color("NumaPurple") : Color(.separator), lineWidth: isSelected ? 2 : 0.5)
            )
            .shadow(
                color: Color.black.opacity(0.1),
                radius: 6,
                x: 0,
                y: 2
            )
            .scaleEffect(isSelected ? 1.02 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isSelected)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ActivityLevelView()
} 