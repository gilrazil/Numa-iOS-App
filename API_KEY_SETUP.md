# OpenAI API Key Setup

## For Local Development

To enable meal analysis functionality, you need to provide your OpenAI API key. The app supports multiple secure methods:

### Method 1: Config.plist (Recommended for development)

1. **Copy the template:**
   ```bash
   cp App/Numa/Numa/Config.template.plist App/Numa/Numa/Config.plist
   ```

2. **Add your API key:**
   - Open `App/Numa/Numa/Config.plist`
   - Replace `your-openai-api-key-here` with your actual OpenAI API key
   - The file is automatically gitignored, so your key won't be committed

### Method 2: Environment Variable

Set the `OPENAI_API_KEY` environment variable in Xcode:

1. **Edit Scheme** in Xcode (`Product` → `Scheme` → `Edit Scheme...`)
2. **Go to "Run"** → **"Arguments"** tab
3. **Add Environment Variable:**
   - Name: `OPENAI_API_KEY`
   - Value: `your-openai-api-key-here`

## Getting Your OpenAI API Key

1. **Visit:** https://platform.openai.com/api-keys
2. **Sign in** or create an account
3. **Click "Create new secret key"**
4. **Copy the key** (starts with `sk-...`)

## Security Notes

- ✅ Config.plist is gitignored and won't be committed
- ✅ Environment variables are not stored in source code
- ❌ Never hardcode API keys in source files
- 🔒 Keep your API key secure and don't share it

## Troubleshooting

If meal analysis shows "API configuration error":

1. **Check debug console** for API key detection messages
2. **Verify your API key** is valid and has sufficient credits
3. **Ensure proper file placement** of Config.plist
4. **Check environment variable** spelling and scope 