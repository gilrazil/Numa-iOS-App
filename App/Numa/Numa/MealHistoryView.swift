import SwiftUI

struct MealHistoryView: View {
    @EnvironmentObject var userService: UserService
    @Environment(\.dismiss) private var dismiss
    
    @State private var meals: [MealAnalysis] = []
    @State private var viewState: ViewState = .loading
    @State private var errorMessage: String = ""
    
    enum ViewState {
        case loading
        case loaded
        case empty
        case error
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                // Content
                Group {
                    switch viewState {
                    case .loading:
                        LoadingStateView()
                    case .loaded:
                        MealListView(meals: meals)
                    case .empty:
                        EmptyStateView()
                    case .error:
                        ErrorStateView(errorMessage: errorMessage) {
                            loadMealHistory()
                        }
                    }
                }
            }
            .navigationTitle(LocalizedStringKey("meal_history_title"))
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(LocalizedStringKey("back_button")) {
                        dismiss()
                    }
                    .foregroundColor(Color("NumaPurple"))
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    if viewState == .loaded || viewState == .error {
                        Button(LocalizedStringKey("refresh_button")) {
                            loadMealHistory()
                        }
                        .foregroundColor(Color("NumaPurple"))
                    }
                }
            }
        }
        .onAppear {
            loadMealHistory()
        }
    }
    
    // MARK: - Data Loading
    
    private func loadMealHistory() {
        viewState = .loading
        errorMessage = ""
        
        userService.getUserMeals { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let fetchedMeals):
                    self.meals = fetchedMeals
                    self.viewState = fetchedMeals.isEmpty ? .empty : .loaded
                    print("✅ Loaded \(fetchedMeals.count) meals from Firebase")
                    
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                    self.viewState = .error
                    print("❌ Failed to load meals: \(error.localizedDescription)")
                }
            }
        }
    }
}

// MARK: - Loading State View

struct LoadingStateView: View {
    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: Color("NumaPurple")))
                .scaleEffect(1.5)
            
            Text(LocalizedStringKey("loading_meal_history"))
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Meal List View

struct MealListView: View {
    let meals: [MealAnalysis]
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // Header Stats
                MealHistoryHeaderView(meals: meals)
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                
                // Meal Cards
                ForEach(Array(meals.enumerated()), id: \.element.id) { index, meal in
                    MealCardView(meal: meal, index: index)
                        .padding(.horizontal, 20)
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                        .animation(.easeInOut(duration: 0.3).delay(Double(index) * 0.1), value: meals.count)
                }
            }
            .padding(.bottom, 40)
        }
        .refreshable {
            // This will trigger the parent's loadMealHistory when user pulls to refresh
        }
    }
}

// MARK: - Empty State View

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 24) {
            // Illustration
            VStack(spacing: 16) {
                Image(systemName: "photo.on.rectangle.angled")
                    .font(.system(size: 60))
                    .foregroundColor(Color("NumaPurple").opacity(0.6))
                
                VStack(spacing: 8) {
                    Text(LocalizedStringKey("no_meals_yet"))
                        .font(.title2)
                        .fontWeight(.semibold)
                        .multilineTextAlignment(.center)
                    
                    Text(LocalizedStringKey("start_analyzing_meals"))
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            
            // Motivational Message
            VStack(spacing: 12) {
                Text(LocalizedStringKey("meal_tracking_benefits"))
                    .font(.headline)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)
                
                VStack(spacing: 8) {
                    FeatureBenefitRow(icon: "brain.head.profile", text: LocalizedStringKey("ai_nutritional_analysis"))
                    FeatureBenefitRow(icon: "chart.line.uptrend.xyaxis", text: LocalizedStringKey("track_your_progress"))
                    FeatureBenefitRow(icon: "target", text: LocalizedStringKey("reach_health_goals"))
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, 30)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct FeatureBenefitRow: View {
    let icon: String
    let text: LocalizedStringKey
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.body)
                .foregroundColor(Color("NumaPurple"))
                .frame(width: 20)
            
            Text(text)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.leading)
            
            Spacer()
        }
    }
}

// MARK: - Error State View

struct ErrorStateView: View {
    let errorMessage: String
    let onRetry: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 50))
                .foregroundColor(.orange)
            
            VStack(spacing: 12) {
                Text(LocalizedStringKey("failed_to_load_meals"))
                    .font(.title2)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                
                Text(errorMessage)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button(action: onRetry) {
                Text(LocalizedStringKey("try_again_button"))
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: 200)
                    .padding(.vertical, 12)
                    .background(Color("NumaPurple"))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            
            Spacer()
        }
        .padding(.horizontal, 30)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Header Stats View

struct MealHistoryHeaderView: View {
    let meals: [MealAnalysis]
    
    private var totalCalories: Int {
        meals.reduce(0) { $0 + $1.estimatedCalories }
    }
    
    private var averageCalories: Int {
        meals.isEmpty ? 0 : totalCalories / meals.count
    }
    
    private var totalMeals: Int {
        meals.count
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(LocalizedStringKey("your_meal_journey"))
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text(LocalizedStringKey("nutrition_insights"))
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            // Stats Cards
            HStack(spacing: 12) {
                StatCard(
                    title: LocalizedStringKey("total_meals"),
                    value: "\(totalMeals)",
                    icon: "fork.knife.circle.fill",
                    color: Color("NumaPurple")
                )
                
                StatCard(
                    title: LocalizedStringKey("total_calories"),
                    value: "\(totalCalories)",
                    icon: "flame.fill",
                    color: .orange
                )
                
                StatCard(
                    title: LocalizedStringKey("avg_calories"),
                    value: "\(averageCalories)",
                    icon: "chart.bar.fill",
                    color: .blue
                )
            }
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color("NumaPurple").opacity(0.2), lineWidth: 1)
                )
        )
    }
}

struct StatCard: View {
    let title: LocalizedStringKey
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.1))
        )
    }
}

// MARK: - Meal Card View

struct MealCardView: View {
    let meal: MealAnalysis
    let index: Int
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: meal.timestamp)
    }
    
    private var timeAgo: String {
        let timeInterval = Date().timeIntervalSince(meal.timestamp)
        
        if timeInterval < 3600 { // Less than 1 hour
            let minutes = Int(timeInterval / 60)
            return minutes <= 1 ? NSLocalizedString("just_now", comment: "") : String(format: NSLocalizedString("minutes_ago", comment: ""), minutes)
        } else if timeInterval < 86400 { // Less than 1 day
            let hours = Int(timeInterval / 3600)
            return hours == 1 ? NSLocalizedString("hour_ago", comment: "") : String(format: NSLocalizedString("hours_ago", comment: ""), hours)
        } else { // More than 1 day
            let days = Int(timeInterval / 86400)
            return days == 1 ? NSLocalizedString("day_ago", comment: "") : String(format: NSLocalizedString("days_ago", comment: ""), days)
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with date and calories
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(formattedDate)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text(timeAgo)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Calories Badge
                HStack(spacing: 6) {
                    Image(systemName: "flame.fill")
                        .font(.caption)
                        .foregroundColor(.orange)
                    
                    Text("\(meal.estimatedCalories)")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                    
                    Text(LocalizedStringKey("cal"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.orange.opacity(0.1))
                )
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            
            // Macros Section
            HStack(spacing: 0) {
                MacroBar(
                    title: LocalizedStringKey("protein"),
                    value: meal.macros.protein,
                    color: .red,
                    icon: "figure.strengthtraining.traditional"
                )
                
                Divider()
                    .frame(height: 40)
                
                MacroBar(
                    title: LocalizedStringKey("carbs"),
                    value: meal.macros.carbs,
                    color: .blue,
                    icon: "leaf.fill"
                )
                
                Divider()
                    .frame(height: 40)
                
                MacroBar(
                    title: LocalizedStringKey("fat"),
                    value: meal.macros.fat,
                    color: .green,
                    icon: "drop.fill"
                )
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            
            // Ingredients Section
            if !meal.ingredients.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "list.bullet")
                            .font(.body)
                            .foregroundColor(Color("NumaPurple"))
                        
                        Text(LocalizedStringKey("ingredients"))
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Spacer()
                        
                        // Confidence Badge
                        if meal.confidence > 0 {
                            HStack(spacing: 4) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.caption2)
                                    .foregroundColor(meal.confidence > 0.7 ? .green : .orange)
                                
                                Text("\(Int(meal.confidence * 100))%")
                                    .font(.caption2)
                                    .fontWeight(.medium)
                                    .foregroundColor(meal.confidence > 0.7 ? .green : .orange)
                            }
                        }
                    }
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 8) {
                        ForEach(Array(meal.ingredients.prefix(6).enumerated()), id: \.offset) { _, ingredient in
                            IngredientChip(ingredient: ingredient)
                        }
                        
                        if meal.ingredients.count > 6 {
                            Text(LocalizedStringKey("and_more"))
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.secondary.opacity(0.1))
                                )
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
}

struct MacroBar: View {
    let title: LocalizedStringKey
    let value: Double
    let color: Color
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.body)
                .foregroundColor(color)
            
            Text("\(value, specifier: "%.1f")")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(LocalizedStringKey("grams"))
                .font(.caption2)
                .foregroundColor(.secondary)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct IngredientChip: View {
    let ingredient: String
    
    var body: some View {
        Text(ingredient)
            .font(.caption)
            .fontWeight(.medium)
            .foregroundColor(Color("NumaPurple"))
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color("NumaPurple").opacity(0.1))
            )
            .lineLimit(1)
    }
}

#Preview {
    MealHistoryView()
        .environmentObject(UserService.shared)
} 