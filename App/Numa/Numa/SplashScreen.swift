import SwiftUI

struct SplashScreen: View {
    @State private var isActive = false
    @State private var shouldShowOnboarding = false
    
    var body: some View {
        if isActive {
            // Check if onboarding is complete
            if shouldShowOnboarding {
                GoalSelectionView()
            } else {
                ContentView()
            }
        } else {
            VStack(spacing: 20) {
                Image("Numa logo")
                    .renderingMode(.original)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 150, height: 150)
                    .accessibilityLabel("Numa Logo")

                Text("Your Health")
                    .font(.title2)
                    .foregroundColor(.white)
                    .bold()
                    .accessibilityLabel("Your Health")

                Text("One Click Away")
                    .font(.title3)
                    .foregroundColor(.white.opacity(0.85))
                    .accessibilityLabel("One Click Away")
                
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white.opacity(0.7)))
                    .scaleEffect(0.8)
                    .padding(.top, 20)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color("NumaPurple"))
            .ignoresSafeArea(.all)
            .onAppear {
                // TEMPORARY: Reset onboarding for testing
                UserDefaults.standard.removeObject(forKey: "onboarding_complete")
                
                // Check onboarding status
                let isOnboardingComplete = UserDefaults.standard.bool(forKey: "onboarding_complete")
                shouldShowOnboarding = !isOnboardingComplete
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        isActive = true
                    }
                }
            }
        }
    }
}

#Preview {
    SplashScreen()
} 