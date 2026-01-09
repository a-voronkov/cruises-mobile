# Quick Start Guide

Get up and running with Cruises Mobile in minutes!

## Prerequisites

Before you begin, ensure you have:

- ✅ **Flutter SDK** 3.2.0+ installed ([Install Flutter](https://flutter.dev/docs/get-started/install))
- ✅ **Git** installed
- ✅ **Android Studio** (for Android) or **Xcode** (for iOS on macOS)
- ✅ A code editor (VS Code, Android Studio, or IntelliJ IDEA)
- ✅ **CMake** (for building llama.cpp library)
- ✅ **LFM2.5 Model File** (~700MB) - see setup instructions below

## Installation (5 minutes)

### 1. Clone the Repository

```bash
git clone <repository-url>
cd cruises-mobile
```

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Verify Setup

```bash
flutter doctor
```

Fix any issues reported before proceeding.

### 4. Setup LLM Model (Required for AI Features)

#### Download Model File

```bash
# Create models directory
mkdir models

# Download LFM2.5-1.2B-Instruct GGUF model (~700MB)
# Option 1: Using wget
wget -O models/lfm2.5-1.2b-instruct-q4_k_m.gguf \
  https://huggingface.co/LiquidAI/LFM2.5-1.2B-Instruct-GGUF/resolve/main/lfm2.5-1.2b-instruct-q4_k_m.gguf

# Option 2: Using curl
curl -L -o models/lfm2.5-1.2b-instruct-q4_k_m.gguf \
  https://huggingface.co/LiquidAI/LFM2.5-1.2B-Instruct-GGUF/resolve/main/lfm2.5-1.2b-instruct-q4_k_m.gguf
```

**Note**: The model file is excluded from git (see `.gitignore`). Each developer needs to download it locally.

#### Setup llama.cpp Library

See [LLAMA_CPP_SETUP.md](docs/LLAMA_CPP_SETUP.md) for detailed instructions on building/installing llama.cpp for your platform.

**Quick setup:**
- **Windows**: Place `llama.dll` in project root
- **macOS**: Place `libllama.dylib` in project root
- **Linux**: Place `libllama.so` in project root

### 5. Run Code Generation

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

## Running the App

### Option 1: Using Command Line

**For Android:**
```bash
flutter run
```

**For iOS (macOS only):**
```bash
flutter run
```

### Option 2: Using IDE

1. Open the project in your IDE
2. Select a device/emulator
3. Press the Run button (▶️)

## What You'll See

1. **First Launch**: Model Initialization Page
   - Shows LFM2.5 model information
   - Loading progress bar
   - Initialization status messages

2. **After Initialization**: Chat Interface
   - ChatGPT-like design
   - Light/dark theme toggle
   - Message input with attachment options
   - Real-time AI responses (streaming)

## Project Structure Overview

```
lib/
├── core/                    # Core utilities and configuration
│   ├── di/                  # Dependency injection
│   ├── theme/               # App themes
│   ├── constants/           # Constants
│   └── errors/              # Error handling
├── features/                # Feature modules
│   ├── chat/               # Chat functionality
│   └── model_management/   # AI model management
└── main.dart               # App entry point
```

## Key Files to Know

- **`lib/main.dart`**: App entry point
- **`lib/core/theme/app_theme.dart`**: Theme configuration
- **`lib/core/constants/app_constants.dart`**: App-wide constants
- **`pubspec.yaml`**: Dependencies and configuration
- **`docs/ARCHITECTURE.md`**: Detailed architecture guide

## Next Steps

### For Developers

1. **Read the Documentation**
   - [ARCHITECTURE.md](docs/ARCHITECTURE.md) - Understand the architecture
   - [SETUP.md](docs/SETUP.md) - Detailed setup instructions
   - [LLM_INTEGRATION.md](docs/LLM_INTEGRATION.md) - LLM integration guide

2. **LLM Integration** ✅ (Completed)
   - llama.cpp integration via `llama_cpp_dart`
   - LFM2.5-1.2B-Instruct model support
   - ChatML template formatting
   - See [LFM2.5_INTEGRATION.md](docs/LFM2.5_INTEGRATION.md) for details

3. **Complete Chat Functionality**
   - Add Hive database setup
   - Implement message persistence
   - Connect UI to actual data

4. **Add Voice & File Features**
   - Implement speech-to-text
   - Connect image/file pickers
   - Handle permissions

### For Testers

1. **Test the UI**
   - Try light/dark theme toggle
   - Test message input
   - Check attachment options
   - Verify responsive design

2. **Report Issues**
   - Create GitHub issues for bugs
   - Suggest improvements
   - Test on different devices

## Common Commands

```bash
# Install dependencies
flutter pub get

# Run code generation
flutter pub run build_runner build --delete-conflicting-outputs

# Run the app
flutter run

# Run tests
flutter test

# Analyze code
flutter analyze

# Format code
flutter format .

# Build APK (Android)
flutter build apk --release

# Build iOS (macOS only)
flutter build ios --release

# Clean build
flutter clean
```

## Troubleshooting

### "Flutter command not found"
- Ensure Flutter is in your PATH
- Run `flutter doctor` to verify installation

### "No devices found"
- Start an emulator/simulator
- Connect a physical device
- Run `flutter devices` to list available devices

### "Build failed"
- Run `flutter clean`
- Delete `pubspec.lock` and run `flutter pub get`
- Check `flutter doctor` for issues

### "Code generation failed"
- Delete all `*.g.dart` files
- Run build_runner again
- Check for syntax errors in your code

## Getting Help

- 📖 **Documentation**: Check the `docs/` folder
- 🐛 **Issues**: Create a GitHub issue
- 💬 **Discussions**: Use GitHub Discussions
- 📧 **Contact**: Reach out to the development team

## Development Workflow

1. Create a feature branch: `git checkout -b feature/my-feature`
2. Make your changes
3. Run tests: `flutter test`
4. Format code: `flutter format .`
5. Commit: `git commit -m "Add my feature"`
6. Push: `git push origin feature/my-feature`
7. Create a Pull Request

## What's Working

✅ Project structure and architecture
✅ UI components (chat interface, model setup)
✅ Theme system (light/dark)
✅ Navigation flow
✅ Build configuration (Android/iOS)
✅ CI/CD pipeline (GitHub Actions)
✅ LLM integration (llama.cpp + LFM2.5)
✅ Chat template formatting (ChatML)
✅ Model initialization system

## What's Next

🚧 Message persistence (Hive database)
🚧 Voice input implementation
🚧 File attachment handling
🚧 Model download service
🚧 Chat repository implementation

## Resources

- [Flutter Documentation](https://flutter.dev/docs)
- [Riverpod Documentation](https://riverpod.dev/)
- [Clean Architecture Guide](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)
- [llama.cpp GitHub](https://github.com/ggerganov/llama.cpp)

---

**Ready to contribute?** Check out [ROADMAP.md](docs/ROADMAP.md) to see what's planned!

