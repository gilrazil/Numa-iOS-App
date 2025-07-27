import SwiftUI

struct CompactMealResultsView: View {
    let mealImage: UIImage
    let analysis: MealAnalysis
    let isSaving: Bool
    let onSave: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var userService: UserService
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Header with close button
                HStack {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(Color("NumaPurple"))
                    
                    Spacer()
                    
                    Text("Meal Analysis")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    // Invisible placeholder for centering
                    Button("Close") {
                        dismiss()
                    }
                    .opacity(0)
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                
                // Main content - using available height efficiently
                VStack(spacing: geometry.size.height * 0.015) {
                    // Top section: Image and Score
                    HStack(spacing: 16) {
                        // Meal Image - smaller, rounded
                        Image(uiImage: mealImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: geometry.size.width * 0.35, height: geometry.size.width * 0.35)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        
                        // Score and Nutrition Overview
                        VStack(spacing: 8) {
                            // Overall Score
                            VStack(spacing: 4) {
                                Text("\(calculateNutritionScore())")
                                    .font(.system(size: 36, weight: .bold))
                                    .foregroundColor(scoreColor())
                                
                                Text("Nutrition Score")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(
                                Circle()
                                    .fill(scoreColor().opacity(0.1))
                                    .overlay(
                                        Circle()
                                            .stroke(scoreColor(), lineWidth: 2)
                                    )
                            )
                            
                            // Quick calories
                            Text("\(analysis.estimatedCalories) cal")
                                .font(.headline)
                                .fontWeight(.medium)
                                .foregroundColor(.orange)
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Macros Row - Compact horizontal layout
                    HStack(spacing: 12) {
                        MacroCompactCard(
                            title: "Protein",
                            value: "\(Int(analysis.macros.protein))g",
                            color: .red,
                            geometry: geometry
                        )
                        
                        MacroCompactCard(
                            title: "Carbs",
                            value: "\(Int(analysis.macros.carbs))g",
                            color: .blue,
                            geometry: geometry
                        )
                        
                        MacroCompactCard(
                            title: "Fat",
                            value: "\(Int(analysis.macros.fat))g",
                            color: .green,
                            geometry: geometry
                        )
                    }
                    .padding(.horizontal, 20)
                    
                    // Ingredients - Compact display
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "list.bullet")
                                .foregroundColor(Color("NumaPurple"))
                            Text("Ingredients")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Spacer()
                        }
                        
                        // Ingredients as comma-separated text to save space
                        Text(analysis.ingredients.prefix(6).joined(separator: ", "))
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(.systemGray6))
                    )
                    .padding(.horizontal, 20)
                    
                    // Personalized Tip
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Image(systemName: "lightbulb.fill")
                                .foregroundColor(.yellow)
                            Text("Tip for You")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        
                        Text(getPersonalizedTip())
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.yellow.opacity(0.1))
                    )
                    .padding(.horizontal, 20)
                    
                    Spacer()
                    
                    // Save Button - Prominent at bottom
                    Button(action: onSave) {
                        HStack {
                            if isSaving {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            }
                            
                            Image(systemName: "bookmark.fill")
                            Text(isSaving ? "Saving..." : "Save Meal")
                        }
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(isSaving ? Color.gray : Color("NumaPurple"))
                        )
                    }
                    .disabled(isSaving)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
            }
        }
        .background(Color(.systemBackground))
    }
    
    // MARK: - Helper Functions
    
    private func calculateNutritionScore() -> Int {
        guard let user = userService.currentUser,
              let goal = user.goal else { return 75 }
        
        var score = 50 // Base score
        
        // Calorie scoring based on reasonable ranges
        let calories = analysis.estimatedCalories
        if calories >= 300 && calories <= 600 {
            score += 20
        } else if calories >= 200 && calories <= 800 {
            score += 10
        }
        
        // Macro balance scoring
        let protein = analysis.macros.protein
        let carbs = analysis.macros.carbs
        let fat = analysis.macros.fat
        
        // Good protein content (15-30g)
        if protein >= 15 && protein <= 30 {
            score += 15
        } else if protein >= 10 {
            score += 8
        }
        
        // Reasonable carb content based on goal
        switch goal {
        case "lose_weight":
            if carbs <= 40 { score += 10 }
        case "gain_weight":
            if carbs >= 30 { score += 10 }
        case "maintain_weight":
            if carbs >= 20 && carbs <= 50 { score += 10 }
        default:
            if carbs >= 20 && carbs <= 50 { score += 10 }
        }
        
        // Healthy fat content (8-20g)
        if fat >= 8 && fat <= 20 {
            score += 15
        } else if fat >= 5 {
            score += 8
        }
        
        return min(100, max(30, score))
    }
    
    private func scoreColor() -> Color {
        let score = calculateNutritionScore()
        if score >= 80 { return .green }
        if score >= 60 { return .orange }
        return .red
    }
    
    private func getPersonalizedTip() -> String {
        guard let user = userService.currentUser,
              let goal = user.goal else {
            return "Keep tracking your meals for better insights!"
        }
        
        let protein = analysis.macros.protein
        let calories = analysis.estimatedCalories
        
        switch goal {
        case "lose_weight":
            if protein < 15 {
                return "Add more protein to help maintain muscle while losing weight."
            } else if calories > 600 {
                return "Consider smaller portions or lower-calorie options for weight loss."
            } else {
                return "Great balance for weight loss! Keep up the good work."
            }
            
        case "gain_weight":
            if calories < 400 {
                return "Try adding healthy fats or complex carbs to increase calories."
            } else if protein < 20 {
                return "Add more protein sources to support muscle growth."
            } else {
                return "Good calorie density! Perfect for healthy weight gain."
            }
            
        case "maintain_weight":
            if protein < 15 {
                return "Aim for more protein to maintain muscle mass."
            } else {
                return "Well-balanced meal! Great for maintaining your current weight."
            }
            
        default:
            return "Focus on balanced nutrition with adequate protein, healthy fats, and complex carbs."
        }
    }
}

// MARK: - Compact Macro Card

struct MacroCompactCard: View {
    let title: String
    let value: String
    let color: Color
    let geometry: GeometryProxy
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: geometry.size.width * 0.04, weight: .bold))
                .foregroundColor(color)
            
            Text(title)
                .font(.system(size: geometry.size.width * 0.025))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(color.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        )
    }
} 