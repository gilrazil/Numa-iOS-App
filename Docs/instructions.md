# 🧭 Instructions for Numa iOS App Development

These are the technical and functional guidelines for developing the Numa app.

---

## ✅ Core Platform Rules
- App is **iOS-only (iPhone)**.
- No support for Android, iPad, or Web – now or in the future.
- App must be built using **native Swift** and **SwiftUI**.
- Do **not** use Expo, React Native, Flutter, or any cross-platform framework.

---

## 📦 Dependencies

Use only the following technologies and libraries:

### 🔧 Native Frameworks
- Swift
- SwiftUI
- Combine
- Foundation (URLSession, Codable, etc.)
- PhotosUI
- SF Symbols

### ☁️ Firebase SDKs
- Firebase Core
- Firebase Firestore – to store meal analysis, history, and metadata
- Firebase Storage – to upload and store meal images
- Firebase Auth (optional) – for user identification and sync

### 🧠 AI APIs
- OpenAI GPT-4o – for nutritional insights and tip generation
- Replicate API – for food image classification

---

## 🔐 Security and API Access
- API keys (OpenAI, Replicate, Firebase config) must be stored securely.
- Do **not** hardcode secrets – use `Secrets.plist` or Xcode build settings.
- User data must be stored under authenticated Firebase users or anonymous sessions.

---

## 🧠 Architecture – MVP Scope

### ✅ Flow:
`Onboarding → Take or upload meal photo → Upload to Firebase Storage → Analyze via API → Save result to Firestore → Show nutrition tip + history`

### 🔄 Data Storage:
- Meal data: stored in Firebase Firestore (date, tags, tip, nutrition info)
- Meal image: uploaded to Firebase Storage
- Optional: authentication via Firebase Auth (anonymous or Apple ID)

---

## 🧪 Testing & Deployment
- Use **TestFlight** for internal and external app testing.
- Prepare provisioning profiles and app identifiers via Apple Developer Console.
- App should be signed and built via Xcode.

---

## 🛠️ Development Tools
- Preferred code editor: **Cursor** (AI-assisted code completion).
- Project must be managed in **Xcode**.
- Version control: **Git**, integrated with **GitHub**.

---

## ⚠️ AI Code Assistance Policy
Any AI-generated code or assistance (ChatGPT, Copilot, Cursor, etc.) must:
- Adhere to these instructions.
- Follow the technologies and architecture defined in `project_con_
