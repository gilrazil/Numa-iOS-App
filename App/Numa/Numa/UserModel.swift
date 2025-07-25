import Foundation
import FirebaseFirestore
import FirebaseCore

// MARK: - User Data Model
struct User: Codable {
    var id: String = UUID().uuidString
    var goal: String?
    var currentWeight: Double?
    var targetWeight: Double?
    var height: Int?
    var age: Int?
    var gender: String?
    var activityLevel: String?
    var onboardingComplete: Bool = false
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    
    enum CodingKeys: String, CodingKey {
        case id
        case goal
        case currentWeight = "current_weight"
        case targetWeight = "target_weight"
        case height
        case age
        case gender
        case activityLevel = "activity_level"
        case onboardingComplete = "onboarding_complete"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - User Service
class UserService: ObservableObject {
    static let shared = UserService()
    private let db = Firestore.firestore()
    private let collectionName = "users"
    
    @Published var currentUser: User?
    
    private init() {
        loadUserFromDefaults()
    }
    
    // MARK: - User Management
    
    /// Creates a new user or loads existing user from UserDefaults
    func initializeUser() {
        if let existingUserId = UserDefaults.standard.string(forKey: "numa_user_id") {
            // Load existing user
            loadUser(userId: existingUserId) { [weak self] result in
                switch result {
                case .success(let user):
                    self?.currentUser = user
                    print("✅ User loaded from Firebase: \(user.id)")
                case .failure(let error):
                    print("❌ Failed to load user from Firebase: \(error)")
                    // Fallback to UserDefaults data
                    self?.loadUserFromDefaults()
                }
            }
        } else {
            // Create new user
            createNewUser()
        }
    }
    
    /// Creates a new user with a unique ID
    private func createNewUser() {
        let newUser = User()
        self.currentUser = newUser
        
        // Save user ID to UserDefaults for persistence
        UserDefaults.standard.set(newUser.id, forKey: "numa_user_id")
        
        // Save to Firebase
        saveUserToFirebase(user: newUser) { result in
            switch result {
            case .success():
                print("✅ New user created in Firebase: \(newUser.id)")
            case .failure(let error):
                print("❌ Failed to create user in Firebase: \(error)")
            }
        }
    }
    
    // MARK: - Firebase Operations
    
    /// Saves user data to Firebase Firestore
    func saveUserToFirebase(user: User, completion: @escaping (Result<Void, Error>) -> Void) {
        var updatedUser = user
        updatedUser.updatedAt = Date()
        
        do {
            try db.collection(collectionName).document(user.id).setData(from: updatedUser) { error in
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                }
            }
        } catch {
            completion(.failure(error))
        }
    }
    
    /// Loads user data from Firebase Firestore
    func loadUser(userId: String, completion: @escaping (Result<User, Error>) -> Void) {
        db.collection(collectionName).document(userId).getDocument { snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let snapshot = snapshot, snapshot.exists else {
                completion(.failure(NSError(domain: "UserService", code: 404, userInfo: [NSLocalizedDescriptionKey: "User not found"])))
                return
            }
            
            do {
                let user = try snapshot.data(as: User.self)
                completion(.success(user))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    // MARK: - Onboarding Data Management
    
    /// Saves onboarding data to both UserDefaults and Firebase
    func saveOnboardingData(
        goal: String? = nil,
        currentWeight: Double? = nil,
        targetWeight: Double? = nil,
        height: Int? = nil,
        age: Int? = nil,
        gender: String? = nil,
        activityLevel: String? = nil,
        completion: @escaping (Bool) -> Void
    ) {
        guard var user = currentUser else {
            initializeUser()
            completion(false)
            return
        }
        
        // Update user data
        if let goal = goal { user.goal = goal }
        if let currentWeight = currentWeight { user.currentWeight = currentWeight }
        if let targetWeight = targetWeight { user.targetWeight = targetWeight }
        if let height = height { user.height = height }
        if let age = age { user.age = age }
        if let gender = gender { user.gender = gender }
        if let activityLevel = activityLevel { user.activityLevel = activityLevel }
        
        // Update local user
        self.currentUser = user
        
        // Save to UserDefaults (for offline access)
        saveToUserDefaults(user: user)
        
        // Save to Firebase
        saveUserToFirebase(user: user) { result in
            switch result {
            case .success():
                print("✅ Onboarding data saved successfully")
                completion(true)
            case .failure(let error):
                print("❌ Failed to save onboarding data: \(error)")
                completion(false)
            }
        }
    }
    
    /// Mark onboarding as complete
    func completeOnboarding(completion: @escaping (Bool) -> Void) {
        guard var user = currentUser else {
            completion(false)
            return
        }
        
        user.onboardingComplete = true
        self.currentUser = user
        
        // Save to UserDefaults
        UserDefaults.standard.set(true, forKey: "onboarding_complete")
        
        // Save to Firebase
        saveUserToFirebase(user: user) { result in
            switch result {
            case .success():
                print("✅ Onboarding marked as complete")
                completion(true)
            case .failure(let error):
                print("❌ Failed to complete onboarding: \(error)")
                completion(false)
            }
        }
    }
    
    // MARK: - UserDefaults Integration
    
    /// Saves user data to UserDefaults for offline access
    private func saveToUserDefaults(user: User) {
        if let goal = user.goal {
            UserDefaults.standard.set(goal, forKey: "user_goal")
        }
        if let currentWeight = user.currentWeight {
            UserDefaults.standard.set(currentWeight, forKey: "user_weight_current")
        }
        if let targetWeight = user.targetWeight {
            UserDefaults.standard.set(targetWeight, forKey: "user_weight_target")
        }
        if let height = user.height {
            UserDefaults.standard.set(height, forKey: "user_height")
        }
        if let age = user.age {
            UserDefaults.standard.set(age, forKey: "user_age")
        }
        if let gender = user.gender {
            UserDefaults.standard.set(gender, forKey: "user_gender")
        }
        if let activityLevel = user.activityLevel {
            UserDefaults.standard.set(activityLevel, forKey: "user_activity_level")
        }
        UserDefaults.standard.set(user.onboardingComplete, forKey: "onboarding_complete")
    }
    
    /// Loads user data from UserDefaults
    private func loadUserFromDefaults() {
        guard let userId = UserDefaults.standard.string(forKey: "numa_user_id") else {
            createNewUser()
            return
        }
        
        var user = User()
        user.id = userId
        user.goal = UserDefaults.standard.string(forKey: "user_goal")
        user.currentWeight = UserDefaults.standard.object(forKey: "user_weight_current") as? Double
        user.targetWeight = UserDefaults.standard.object(forKey: "user_weight_target") as? Double  
        user.height = UserDefaults.standard.object(forKey: "user_height") as? Int
        user.age = UserDefaults.standard.object(forKey: "user_age") as? Int
        user.gender = UserDefaults.standard.string(forKey: "user_gender")
        user.activityLevel = UserDefaults.standard.string(forKey: "user_activity_level")
        user.onboardingComplete = UserDefaults.standard.bool(forKey: "onboarding_complete")
        
        self.currentUser = user
    }
    
    // MARK: - Data Verification
    
    /// Verifies that all onboarding data is properly saved
    func verifyOnboardingData() -> (isComplete: Bool, missingFields: [String]) {
        guard let user = currentUser else {
            return (false, ["User not initialized"])
        }
        
        var missingFields: [String] = []
        
        if user.goal == nil { missingFields.append("Goal") }
        if user.currentWeight == nil { missingFields.append("Current Weight") }
        if user.targetWeight == nil { missingFields.append("Target Weight") }
        if user.height == nil { missingFields.append("Height") }
        if user.age == nil { missingFields.append("Age") }
        if user.gender == nil { missingFields.append("Gender") }
        if user.activityLevel == nil { missingFields.append("Activity Level") }
        
        return (missingFields.isEmpty && user.onboardingComplete, missingFields)
    }
    
    // MARK: - Debug Helper
    func printUserData() {
        guard let user = currentUser else {
            print("❌ No user data available")
            return
        }
        
        print("👤 Current User Data:")
        print("   ID: \(user.id)")
        print("   Goal: \(user.goal ?? "Not set")")
        print("   Current Weight: \(user.currentWeight?.description ?? "Not set")")
        print("   Target Weight: \(user.targetWeight?.description ?? "Not set")")
        print("   Height: \(user.height?.description ?? "Not set")")
        print("   Age: \(user.age?.description ?? "Not set")")
        print("   Gender: \(user.gender ?? "Not set")")
        print("   Activity Level: \(user.activityLevel ?? "Not set")")
        print("   Onboarding Complete: \(user.onboardingComplete)")
        print("   Created: \(user.createdAt)")
        print("   Updated: \(user.updatedAt)")
    }
} 