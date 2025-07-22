import SwiftUI

struct PersonalInfoView: View {
    @State private var currentWeight = ""
    @State private var targetWeight = ""
    @State private var height = ""
    @State private var age = ""
    @State private var selectedGender: Gender = .male
    @State private var navigateToActivityLevel = false
    
    enum Gender: String, CaseIterable {
        case male = "male"
        case female = "female"
        
        var displayKey: String {
            switch self {
            case .male: return "gender_male"
            case .female: return "gender_female"
            }
        }
    }
    
    private var isFormValid: Bool {
        !currentWeight.isEmpty &&
        !targetWeight.isEmpty &&
        !height.isEmpty &&
        !age.isEmpty &&
        Double(currentWeight) != nil &&
        Double(targetWeight) != nil &&
        Int(height) != nil &&
        Int(age) != nil
    }
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Header - Compact
                VStack(spacing: 8) {
                    Text(LocalizedStringKey("personal_info_title"))
                        .font(.title2)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                    
                    Text(LocalizedStringKey("personal_info_subtitle"))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(.top, 20)
                
                Spacer(minLength: 20)
                
                // Form - Compact Cards
                VStack(spacing: 16) {
                    // Weight Fields Card - More Compact
                    CompactInfoCard {
                        HStack(spacing: 16) {
                            CompactInputField(
                                titleKey: "field_current_weight",
                                text: $currentWeight,
                                placeholderKey: "placeholder_current_weight",
                                keyboardType: .numberPad
                            )
                            
                            Divider()
                                .frame(height: 40)
                            
                            CompactInputField(
                                titleKey: "field_target_weight",
                                text: $targetWeight,
                                placeholderKey: "placeholder_target_weight",
                                keyboardType: .numberPad
                            )
                        }
                    }
                    
                    // Height & Age Card - Horizontal Layout
                    CompactInfoCard {
                        HStack(spacing: 16) {
                            CompactInputField(
                                titleKey: "field_height",
                                text: $height,
                                placeholderKey: "placeholder_height",
                                keyboardType: .numberPad
                            )
                            
                            Divider()
                                .frame(height: 40)
                            
                            CompactInputField(
                                titleKey: "field_age",
                                text: $age,
                                placeholderKey: "placeholder_age",
                                keyboardType: .numberPad
                            )
                        }
                    }
                    
                    // Gender Selection Card - Compact
                    CompactInfoCard {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(LocalizedStringKey("field_gender"))
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                            
                            Picker(selection: $selectedGender, label: Text("")) {
                                ForEach(Gender.allCases, id: \.self) { gender in
                                    Text(LocalizedStringKey(gender.displayKey))
                                        .tag(gender)
                                }
                            }
                            .pickerStyle(.segmented)
                        }
                    }
                }
                .padding(.horizontal, 20)
                
                Spacer(minLength: 16)
                
                // Continue Button - Always Visible
                Button(action: {
                    savePersonalInfo()
                    navigateToActivityLevel = true
                }) {
                    Text(LocalizedStringKey("continue_button"))
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(isFormValid ? Color("NumaPurple") : Color(.systemGray4))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(!isFormValid)
                .padding(.horizontal, 20)
                .padding(.bottom, max(20, geometry.safeAreaInsets.bottom + 10))
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $navigateToActivityLevel) {
            ActivityLevelView()
        }
        .onTapGesture {
            hideKeyboard()
        }
    }
    
    private func savePersonalInfo() {
        UserDefaults.standard.set(Double(currentWeight) ?? 0.0, forKey: "user_weight_current")
        UserDefaults.standard.set(Double(targetWeight) ?? 0.0, forKey: "user_weight_target")
        UserDefaults.standard.set(Int(height) ?? 0, forKey: "user_height")
        UserDefaults.standard.set(Int(age) ?? 0, forKey: "user_age")
        UserDefaults.standard.set(selectedGender.rawValue, forKey: "user_gender")
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// Compact Card Component
struct CompactInfoCard<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(.separator), lineWidth: 0.5)
            )
            .shadow(
                color: Color.black.opacity(0.06),
                radius: 4,
                x: 0,
                y: 2
            )
    }
}

// Compact Input Field Component
struct CompactInputField: View {
    let titleKey: String
    @Binding var text: String
    let placeholderKey: String
    var keyboardType: UIKeyboardType = .default
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(LocalizedStringKey(titleKey))
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
            
            TextField(LocalizedStringKey(placeholderKey), text: $text)
                .font(.body)
                .keyboardType(keyboardType)
                .textFieldStyle(.roundedBorder)
        }
    }
}

#Preview {
    NavigationStack {
        PersonalInfoView()
    }
} 