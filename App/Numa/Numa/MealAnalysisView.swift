import SwiftUI

struct MealAnalysisView: View {
    let mealImage: UIImage
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var userService: UserService
    
    @StateObject private var analysisService = MealAnalysisService.shared
    @State private var analysisState: AnalysisState = .initial
    @State private var mealAnalysis: MealAnalysis?
    @State private var errorMessage: String?
    @State private var isSavingToFirebase = false
    
    enum AnalysisState {
        case initial
        case analyzing
        case completed
        case error
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        Text(LocalizedStringKey("meal_analysis_title"))
                            .font(.title)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                        
                        Text(LocalizedStringKey("meal_analysis_subtitle"))
                            .font(.title3)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding(.top, 20)
                    
                    // Meal Image Display
                    VStack(spacing: 16) {
                        Image(uiImage: mealImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(maxWidth: .infinity)
                            .frame(height: 300)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                        
                        Text(LocalizedStringKey("meal_photo_captured"))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 20)
                    
                    // Analysis Content
                    Group {
                        switch analysisState {
                        case .initial:
                            InitialAnalysisView {
                                startAnalysis()
                            }
                        case .analyzing:
                            AnalyzingView()
                        case .completed:
                            if let analysis = mealAnalysis {
                                CompletedAnalysisView(analysis: analysis, isSaving: isSavingToFirebase)
                            }
                        case .error:
                            ErrorAnalysisView(errorMessage: errorMessage ?? "") {
                                startAnalysis()
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer(minLength: 40)
                    
                    // Action Button
                    actionButton
                        .padding(.horizontal, 20)
                        .padding(.bottom, 40)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(LocalizedStringKey("cancel_button")) {
                        dismiss()
                    }
                    .foregroundColor(Color("NumaPurple"))
                }
            }
        }
        .onAppear {
            // Auto-start analysis when view appears
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                if analysisState == .initial {
                    startAnalysis()
                }
            }
        }
    }
    
    // MARK: - Action Button
    
    @ViewBuilder
    private var actionButton: some View {
        switch analysisState {
        case .initial:
            Button(action: startAnalysis) {
                Text(LocalizedStringKey("start_analysis_button"))
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color("NumaPurple"))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
        case .analyzing:
            Button(action: {}) {
                HStack {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                    Text(LocalizedStringKey("analyzing_meal"))
                }
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.gray)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .disabled(true)
        case .completed:
            if mealAnalysis != nil {
                Button(action: saveMealAndDismiss) {
                    HStack {
                        if isSavingToFirebase {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        }
                        Text(LocalizedStringKey(isSavingToFirebase ? "saving_meal" : "save_meal_button"))
                    }
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(isSavingToFirebase ? Color.gray : Color("NumaPurple"))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .disabled(isSavingToFirebase)
            }
        case .error:
            Button(action: startAnalysis) {
                Text(LocalizedStringKey("try_again_button"))
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color("NumaPurple"))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
        }
    }
    
    // MARK: - Analysis Methods
    
    private func startAnalysis() {
        analysisState = .analyzing
        errorMessage = nil
        
        Task {
            do {
                let analysis = try await analysisService.analyzeMeal(image: mealImage)
                
                await MainActor.run {
                    self.mealAnalysis = analysis
                    self.analysisState = .completed
                }
                
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.analysisState = .error
                }
            }
        }
    }
    
    private func saveMealAndDismiss() {
        guard let analysis = mealAnalysis else { return }
        
        isSavingToFirebase = true
        
        userService.saveMealAnalysis(analysis) { [self] success in
            DispatchQueue.main.async {
                self.isSavingToFirebase = false
                
                if success {
                    print("✅ Meal analysis saved successfully")
                } else {
                    print("⚠️ Failed to save meal analysis, but continuing...")
                }
                
                // Dismiss regardless of Firebase save result
                dismiss()
            }
        }
    }
}

// MARK: - Supporting Views

struct InitialAnalysisView: View {
    let onStartAnalysis: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "brain.head.profile")
                    .font(.title2)
                    .foregroundColor(Color("NumaPurple"))
                
                Text(LocalizedStringKey("preparing_analysis"))
                    .font(.headline)
                    .fontWeight(.medium)
            }
            
            Text(LocalizedStringKey("tap_to_analyze"))
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color("NumaPurple").opacity(0.2), lineWidth: 1)
                )
        )
        .onTapGesture {
            onStartAnalysis()
        }
    }
}

struct AnalyzingView: View {
    var body: some View {
        VStack(spacing: 20) {
            // Animated AI Icon
            HStack {
                Image(systemName: "brain.head.profile")
                    .font(.title2)
                    .foregroundColor(Color("NumaPurple"))
                    .scaleEffect(1.2)
                    .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: true)
                
                Text(LocalizedStringKey("analyzing_your_meal"))
                    .font(.headline)
                    .fontWeight(.medium)
            }
            
            // Progress Indicator
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: Color("NumaPurple")))
                .scaleEffect(1.2)
            
            Text(LocalizedStringKey("this_may_take_moment"))
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 32)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color("NumaPurple").opacity(0.3), lineWidth: 1)
                )
        )
    }
}

struct CompletedAnalysisView: View {
    let analysis: MealAnalysis
    let isSaving: Bool
    
    var body: some View {
        VStack(spacing: 24) {
            // Success Header
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.green)
                    
                    Text(LocalizedStringKey("analysis_complete"))
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                
                Text(LocalizedStringKey("confidence_level"))
                    .font(.caption)
                    .foregroundColor(.secondary)
                + Text(": \(Int(analysis.confidence * 100))%")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(analysis.confidence > 0.7 ? .green : .orange)
            }
            
            // Nutritional Information
            VStack(spacing: 16) {
                // Calories
                NutritionCard(
                    icon: "flame.fill",
                    title: LocalizedStringKey("estimated_calories"),
                    value: "\(analysis.estimatedCalories)",
                    unit: LocalizedStringKey("cal"),
                    color: .orange
                )
                
                // Macros
                HStack(spacing: 12) {
                    MacroCard(
                        title: LocalizedStringKey("protein"),
                        value: analysis.macros.protein,
                        color: .red
                    )
                    
                    MacroCard(
                        title: LocalizedStringKey("carbs"),
                        value: analysis.macros.carbs,
                        color: .blue
                    )
                    
                    MacroCard(
                        title: LocalizedStringKey("fat"),
                        value: analysis.macros.fat,
                        color: .green
                    )
                }
            }
            
            // Ingredients
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "list.bullet")
                        .font(.title3)
                        .foregroundColor(Color("NumaPurple"))
                    
                    Text(LocalizedStringKey("ingredients"))
                        .font(.headline)
                        .fontWeight(.medium)
                }
                
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 8) {
                    ForEach(analysis.ingredients, id: \.self) { ingredient in
                        IngredientTag(ingredient: ingredient)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Analysis Text (if available)
            if let analysisText = analysis.analysisText, !analysisText.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text(LocalizedStringKey("ai_analysis"))
                        .font(.headline)
                        .fontWeight(.medium)
                    
                    Text(analysisText)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.green.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

struct ErrorAnalysisView: View {
    let errorMessage: String
    let onRetry: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.title2)
                    .foregroundColor(.orange)
                
                Text(LocalizedStringKey("analysis_failed"))
                    .font(.headline)
                    .fontWeight(.medium)
            }
            
            Text(errorMessage)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button(action: onRetry) {
                Text(LocalizedStringKey("tap_to_retry"))
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(Color("NumaPurple"))
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.orange.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

struct NutritionCard: View {
    let icon: String
    let title: LocalizedStringKey
    let value: String
    let unit: LocalizedStringKey
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack(alignment: .bottom, spacing: 4) {
                    Text(value)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text(unit)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.1))
        )
    }
}

struct MacroCard: View {
    let title: LocalizedStringKey
    let value: Double
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            VStack(spacing: 2) {
                Text("\(value, specifier: "%.1f")")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(color)
                
                Text(LocalizedStringKey("grams"))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.1))
        )
    }
}

struct IngredientTag: View {
    let ingredient: String
    
    var body: some View {
        Text(ingredient)
            .font(.caption)
            .fontWeight(.medium)
            .foregroundColor(Color("NumaPurple"))
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color("NumaPurple").opacity(0.1))
            )
    }
}

#Preview {
    MealAnalysisView(mealImage: UIImage(systemName: "photo") ?? UIImage())
        .environmentObject(UserService.shared)
} 