import SwiftUI

struct GoalSelectionView: View {
    @EnvironmentObject var userService: UserService
    @State private var selectedGoal: WeightGoal? = nil
    @State private var navigateToPersonalInfo = false
    @State private var isSaving = false
    
    enum WeightGoal: String, CaseIterable {
        case lose = "lose_weight"
        case gain = "gain_weight" 
        case maintain = "maintain_weight"
        
        var displayTextKey: String {
            switch self {
            case .lose: return "goal_lose_weight"
            case .gain: return "goal_gain_weight"
            case .maintain: return "goal_maintain_weight"
            }
        }
        
        var descriptionKey: String {
            switch self {
            case .lose: return "goal_lose_description"
            case .gain: return "goal_gain_description"
            case .maintain: return "goal_maintain_description"
            }
        }
        
        var icon: String {
            switch self {
            case .lose: return "arrow.down.circle.fill"
            case .gain: return "arrow.up.circle.fill"
            case .maintain: return "equal.circle.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .lose: return .red
            case .gain: return .green
            case .maintain: return .blue
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                // Header
                VStack(spacing: 12) {
                    Text(LocalizedStringKey("goal_selection_title"))
                        .font(.title)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                    
                    Text(LocalizedStringKey("goal_selection_subtitle"))
                        .font(.title3)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(.top, 40)
                
                Spacer()
                
                // Goal Options
                VStack(spacing: 16) {
                    ForEach(WeightGoal.allCases, id: \.self) { goal in
                        GoalOptionCard(
                            goal: goal,
                            isSelected: selectedGoal == goal
                        ) {
                            selectedGoal = goal
                        }
                    }
                }
                .padding(.horizontal, 20)
                
                Spacer()
                
                // Continue Button
                Button(action: {
                    // Save goal using UserService
                    if let selectedGoal = selectedGoal {
                        isSaving = true
                        userService.saveOnboardingData(goal: selectedGoal.rawValue) { success in
                            DispatchQueue.main.async {
                                isSaving = false
                                if success {
                                    print("✅ Goal saved successfully: \(selectedGoal.rawValue)")
                                    navigateToPersonalInfo = true
                                } else {
                                    print("❌ Failed to save goal")
                                    // Still navigate to continue onboarding
                                    navigateToPersonalInfo = true
                                }
                            }
                        }
                    }
                }) {
                    HStack {
                        if isSaving {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        }
                        Text(LocalizedStringKey(isSaving ? "saving_button" : "continue_button"))
                    }
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background((selectedGoal != nil && !isSaving) ? Color("NumaPurple") : Color(.systemGray4))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .disabled(selectedGoal == nil || isSaving)
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarHidden(true)
            .navigationDestination(isPresented: $navigateToPersonalInfo) {
                PersonalInfoView()
            }
        }
    }
}

struct GoalOptionCard: View {
    let goal: GoalSelectionView.WeightGoal
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Icon
                Image(systemName: goal.icon)
                    .font(.title2)
                    .foregroundColor(goal.color)
                    .frame(width: 32)
                
                // Text
                VStack(alignment: .leading, spacing: 4) {
                    Text(LocalizedStringKey(goal.displayTextKey))
                        .font(.headline)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                    
                    Text(LocalizedStringKey(goal.descriptionKey))
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
            .padding(.vertical, 16)
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
    GoalSelectionView()
} 