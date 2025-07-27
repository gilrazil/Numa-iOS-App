import SwiftUI

struct MealAnalysisView: View {
    let mealImage: UIImage
    @Environment(\.dismiss) private var dismiss
    
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
                    
                    // Analysis Status (Placeholder for Step 2)
                    VStack(spacing: 16) {
                        HStack {
                            Image(systemName: "brain.head.profile")
                                .font(.title2)
                                .foregroundColor(Color("NumaPurple"))
                            
                            Text(LocalizedStringKey("preparing_analysis"))
                                .font(.headline)
                                .fontWeight(.medium)
                        }
                        
                        Text(LocalizedStringKey("analysis_coming_soon"))
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
                                    .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                            )
                    )
                    .padding(.horizontal, 20)
                    
                    Spacer(minLength: 40)
                    
                    // Continue Button (Placeholder for now)
                    Button(action: {
                        // TODO: Navigate to analysis results in Step 2
                        dismiss()
                    }) {
                        Text(LocalizedStringKey("continue_button"))
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color("NumaPurple"))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
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
    }
}

#Preview {
    MealAnalysisView(mealImage: UIImage(systemName: "photo") ?? UIImage())
} 