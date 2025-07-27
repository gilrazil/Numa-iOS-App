import Foundation
import UIKit

// MARK: - Data Models

struct MealAnalysis: Codable {
    let id: String
    let timestamp: Date
    let ingredients: [String]
    let estimatedCalories: Int
    let macros: Macros
    let confidence: Double
    let analysisText: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case timestamp
        case ingredients
        case estimatedCalories = "estimated_calories"
        case macros
        case confidence
        case analysisText = "analysis_text"
    }
    
    init(ingredients: [String], estimatedCalories: Int, macros: Macros, confidence: Double = 0.8, analysisText: String? = nil) {
        self.id = UUID().uuidString
        self.timestamp = Date()
        self.ingredients = ingredients
        self.estimatedCalories = estimatedCalories
        self.macros = macros
        self.confidence = confidence
        self.analysisText = analysisText
    }
}

struct Macros: Codable {
    let protein: Double  // in grams
    let carbs: Double    // in grams
    let fat: Double      // in grams
    
    enum CodingKeys: String, CodingKey {
        case protein
        case carbs
        case fat
    }
}

// MARK: - Analysis Errors

enum MealAnalysisError: LocalizedError {
    case noInternetConnection
    case apiKeyMissing
    case imageProcessingFailed
    case apiRequestFailed(String)
    case invalidResponse
    case noFoodDetected
    case imageTooLarge
    case requestTimeout
    case rateLimitExceeded
    case unknown(String)
    
    var errorDescription: String? {
        switch self {
        case .noInternetConnection:
            return NSLocalizedString("analysis_error_no_internet", comment: "No internet connection error")
        case .apiKeyMissing:
            return NSLocalizedString("analysis_error_api_key", comment: "API key missing error")
        case .imageProcessingFailed:
            return NSLocalizedString("analysis_error_image_processing", comment: "Image processing failed error")
        case .apiRequestFailed(let message):
            return NSLocalizedString("analysis_error_api_request", comment: "API request failed error") + ": \(message)"
        case .invalidResponse:
            return NSLocalizedString("analysis_error_invalid_response", comment: "Invalid response error")
        case .noFoodDetected:
            return NSLocalizedString("analysis_error_no_food", comment: "No food detected error")
        case .imageTooLarge:
            return NSLocalizedString("analysis_error_image_too_large", comment: "Image too large error")
        case .requestTimeout:
            return NSLocalizedString("analysis_error_timeout", comment: "Request timeout error")
        case .rateLimitExceeded:
            return NSLocalizedString("analysis_error_rate_limit", comment: "Rate limit exceeded error")
        case .unknown(let message):
            return NSLocalizedString("analysis_error_unknown", comment: "Unknown error") + ": \(message)"
        }
    }
}

// MARK: - OpenAI Response Models

private struct OpenAIVisionResponse: Codable {
    let choices: [Choice]
    
    struct Choice: Codable {
        let message: Message
        
        struct Message: Codable {
            let content: String
        }
    }
}

private struct OpenAIRequest: Codable {
    let model: String
    let messages: [Message]
    let maxTokens: Int
    let temperature: Double
    
    enum CodingKeys: String, CodingKey {
        case model
        case messages
        case maxTokens = "max_tokens"
        case temperature
    }
    
    struct Message: Codable {
        let role: String
        let content: [Content]
        
        struct Content: Codable {
            let type: String
            let text: String?
            let imageUrl: ImageUrl?
            
            enum CodingKeys: String, CodingKey {
                case type
                case text
                case imageUrl = "image_url"
            }
            
            struct ImageUrl: Codable {
                let url: String
                let detail: String?
            }
        }
    }
}

// MARK: - Meal Analysis Service

class MealAnalysisService: ObservableObject {
    static let shared = MealAnalysisService()
    
    private let openAIBaseURL = "https://api.openai.com/v1/chat/completions"
    private let maxImageSize: Int = 20 * 1024 * 1024 // 20MB
    private let timeoutInterval: TimeInterval = 30.0
    
    private init() {}
    
    // MARK: - Public Methods
    
    /// Analyzes a meal image using OpenAI Vision API
    func analyzeMeal(image: UIImage) async throws -> MealAnalysis {
        print("🤖 Starting meal analysis...")
        
        // Check internet connectivity
        guard await isInternetAvailable() else {
            throw MealAnalysisError.noInternetConnection
        }
        
        // Get API key
        guard let apiKey = getOpenAIAPIKey() else {
            throw MealAnalysisError.apiKeyMissing
        }
        
        // Process and validate image
        let base64Image = try processImage(image)
        
        // Create request
        let request = try createOpenAIRequest(base64Image: base64Image, apiKey: apiKey)
        
        // Make API call
        let response = try await performAPIRequest(request)
        
        // Parse response
        let analysis = try parseAnalysisResponse(response)
        
        print("✅ Meal analysis completed successfully")
        return analysis
    }
    
    // MARK: - Private Methods
    
    private func getOpenAIAPIKey() -> String? {
        print("🔍 Looking for OpenAI API key...")
        
        // Try to get from environment variable first
        if let apiKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"],
           !apiKey.isEmpty {
            print("✅ Found API key in environment variable")
            return apiKey
        }
        
        // Try to get from config file
        if let path = Bundle.main.path(forResource: "Config", ofType: "plist"),
           let config = NSDictionary(contentsOfFile: path),
           let apiKey = config["OPENAI_API_KEY"] as? String,
           !apiKey.isEmpty {
            print("✅ Found API key in Config.plist")
            return apiKey
        }
        
        // Try to get from Bundle info dictionary (from build settings)
        if let apiKey = Bundle.main.object(forInfoDictionaryKey: "OPENAI_API_KEY") as? String,
           !apiKey.isEmpty {
            print("✅ Found API key in Bundle info dictionary")
            return apiKey
        }
        
        print("❌ No API key found. Please set OPENAI_API_KEY environment variable or add to Config.plist")
        return nil
    }
    
    private func processImage(_ image: UIImage) throws -> String {
        // Compress image if needed
        var compressionQuality: CGFloat = 0.8
        var imageData = image.jpegData(compressionQuality: compressionQuality)
        
        // Reduce quality if image is too large
        while let data = imageData, data.count > maxImageSize && compressionQuality > 0.1 {
            compressionQuality -= 0.1
            imageData = image.jpegData(compressionQuality: compressionQuality)
        }
        
        guard let finalImageData = imageData else {
            throw MealAnalysisError.imageProcessingFailed
        }
        
        if finalImageData.count > maxImageSize {
            throw MealAnalysisError.imageTooLarge
        }
        
        return finalImageData.base64EncodedString()
    }
    
    private func createOpenAIRequest(base64Image: String, apiKey: String) throws -> URLRequest {
        guard let url = URL(string: openAIBaseURL) else {
            throw MealAnalysisError.apiRequestFailed("Invalid URL")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = timeoutInterval
        
        let prompt = """
        Analyze this meal image and provide a detailed nutritional breakdown. Please respond in the following JSON format only:
        
        {
            "ingredients": ["ingredient1", "ingredient2", "ingredient3"],
            "estimated_calories": 450,
            "macros": {
                "protein": 25.5,
                "carbs": 35.2,
                "fat": 18.7
            },
            "confidence": 0.85,
            "analysis_text": "Brief description of the meal"
        }
        
        Be as accurate as possible. If you cannot identify food clearly, set confidence to 0.3 or lower. Include all visible ingredients.
        """
        
        let openAIRequest = OpenAIRequest(
            model: "gpt-4o",
            messages: [
                OpenAIRequest.Message(
                    role: "user",
                    content: [
                        OpenAIRequest.Message.Content(
                            type: "text",
                            text: prompt,
                            imageUrl: nil
                        ),
                        OpenAIRequest.Message.Content(
                            type: "image_url",
                            text: nil,
                            imageUrl: OpenAIRequest.Message.Content.ImageUrl(
                                url: "data:image/jpeg;base64,\(base64Image)",
                                detail: "high"
                            )
                        )
                    ]
                )
            ],
            maxTokens: 500,
            temperature: 0.1
        )
        
        do {
            request.httpBody = try JSONEncoder().encode(openAIRequest)
        } catch {
            throw MealAnalysisError.apiRequestFailed("Failed to encode request: \(error.localizedDescription)")
        }
        
        return request
    }
    
    private func performAPIRequest(_ request: URLRequest) async throws -> OpenAIVisionResponse {
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                switch httpResponse.statusCode {
                case 200:
                    break
                case 401:
                    throw MealAnalysisError.apiKeyMissing
                case 429:
                    throw MealAnalysisError.rateLimitExceeded
                case 408:
                    throw MealAnalysisError.requestTimeout
                default:
                    let errorMessage = String(data: data, encoding: .utf8) ?? "HTTP \(httpResponse.statusCode)"
                    throw MealAnalysisError.apiRequestFailed(errorMessage)
                }
            }
            
            do {
                let openAIResponse = try JSONDecoder().decode(OpenAIVisionResponse.self, from: data)
                return openAIResponse
            } catch {
                print("❌ Failed to decode OpenAI response: \(error)")
                print("Raw response: \(String(data: data, encoding: .utf8) ?? "nil")")
                throw MealAnalysisError.invalidResponse
            }
            
        } catch let error as MealAnalysisError {
            throw error
        } catch {
            if error.localizedDescription.contains("timeout") {
                throw MealAnalysisError.requestTimeout
            } else {
                throw MealAnalysisError.unknown(error.localizedDescription)
            }
        }
    }
    
    private func parseAnalysisResponse(_ response: OpenAIVisionResponse) throws -> MealAnalysis {
        guard let content = response.choices.first?.message.content else {
            throw MealAnalysisError.invalidResponse
        }
        
        // Extract JSON from the response content
        let jsonString = extractJSONFromContent(content)
        
        guard let jsonData = jsonString.data(using: .utf8) else {
            throw MealAnalysisError.invalidResponse
        }
        
        do {
            let decoder = JSONDecoder()
            let analysisResponse = try decoder.decode(MealAnalysisResponse.self, from: jsonData)
            
            // Check confidence level
            if analysisResponse.confidence < 0.3 {
                throw MealAnalysisError.noFoodDetected
            }
            
            return MealAnalysis(
                ingredients: analysisResponse.ingredients,
                estimatedCalories: analysisResponse.estimatedCalories,
                macros: analysisResponse.macros,
                confidence: analysisResponse.confidence,
                analysisText: analysisResponse.analysisText
            )
            
        } catch {
            print("❌ Failed to parse analysis response: \(error)")
            print("JSON content: \(jsonString)")
            throw MealAnalysisError.invalidResponse
        }
    }
    
    private func extractJSONFromContent(_ content: String) -> String {
        // Look for JSON content between ```json and ``` or just look for { and }
        if let startRange = content.range(of: "{"),
           let endRange = content.range(of: "}", options: .backwards) {
            let jsonStart = startRange.lowerBound
            let jsonEnd = content.index(after: endRange.lowerBound)
            return String(content[jsonStart..<jsonEnd])
        }
        
        return content.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private func isInternetAvailable() async -> Bool {
        // Simple internet connectivity check
        guard let url = URL(string: "https://www.google.com") else { return false }
        
        do {
            let (_, response) = try await URLSession.shared.data(from: url)
            return (response as? HTTPURLResponse)?.statusCode == 200
        } catch {
            return false
        }
    }
}

// MARK: - Helper Response Model

private struct MealAnalysisResponse: Codable {
    let ingredients: [String]
    let estimatedCalories: Int
    let macros: Macros
    let confidence: Double
    let analysisText: String?
    
    enum CodingKeys: String, CodingKey {
        case ingredients
        case estimatedCalories = "estimated_calories"
        case macros
        case confidence
        case analysisText = "analysis_text"
    }
} 