# Meal Analysis Setup Guide

## OpenAI API Key Configuration

To enable meal analysis functionality in your Numa app, you need to configure an OpenAI API key.

### For Development Testing:

1. **Get OpenAI API Key:**
   - Go to [OpenAI Platform](https://platform.openai.com/api-keys)
   - Create an account or sign in
   - Generate a new API key
   - Copy the key (starts with `sk-...`)

2. **Add to Info.plist:**
   - Open `App/Numa/Numa/Info.plist` in Xcode
   - Add a new row with:
     - **Key**: `OPENAI_API_KEY`
     - **Type**: `String`
     - **Value**: Your OpenAI API key

3. **Security Note:**
   - ⚠️ **Never commit API keys to version control**
   - Add `Info.plist` to `.gitignore` if it contains sensitive keys
   - For production, use a secure key management system

### Alternative Configuration Methods:

#### Option 1: Environment Variables (Recommended for Production)
```swift
// Update getOpenAIAPIKey() method in MealAnalysisService.swift
private func getOpenAIAPIKey() -> String? {
    // Check environment variable first
    if let apiKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"] {
        return apiKey
    }
    
    // Fallback to Info.plist for development
    // ... existing code
}
```

#### Option 2: Keychain Storage (Most Secure)
```swift
// Store API key in Keychain for production apps
// Implementation would require Keychain services
```

## Testing the Feature

1. **Build and run** the app
2. **Complete onboarding** if not already done
3. **Take or select** a meal photo from the home screen
4. **Wait for analysis** to complete (may take 10-30 seconds)
5. **View results** including calories, macros, and ingredients
6. **Save meal** to Firebase Firestore

## Troubleshooting

### Common Issues:

- **"API configuration error"**: API key not found or invalid
- **"No internet connection"**: Check network connectivity
- **"Analysis service temporarily unavailable"**: OpenAI API might be down
- **"Too many requests"**: Hit rate limits, wait and try again
- **"No food detected"**: Image doesn't contain recognizable food

### Debug Steps:

1. Check Xcode console for detailed error messages
2. Verify API key is correctly added to Info.plist
3. Test with clear, well-lit food photos
4. Ensure good internet connection

## API Usage & Costs

- Uses **GPT-4 Vision Preview** model
- Approximate cost: **$0.01-0.03 per image analysis**
- Rate limits apply based on your OpenAI plan
- Monitor usage in [OpenAI Dashboard](https://platform.openai.com/usage)

## Firebase Integration

Analysis results are automatically saved to:
```
/users/{user_uuid}/meals/{meal_id}
```

Each meal document contains:
- `id`: Unique meal identifier
- `timestamp`: When the meal was analyzed
- `ingredients`: Array of detected ingredients
- `estimated_calories`: Calorie estimate
- `macros`: Protein, carbs, fat breakdown
- `confidence`: AI confidence level (0.0-1.0)
- `analysis_text`: Optional AI description 