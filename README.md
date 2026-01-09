# Cruises Mobile - AI Travel Planning Assistant

An autonomous travel planning assistant mobile application with embedded LLM capabilities for Android and iOS platforms.

## Overview

Cruises Mobile is a Flutter-based mobile application that provides intelligent travel planning assistance using a locally-running Large Language Model (LLM). The app features a ChatGPT-like interface with support for text, voice, and file inputs.

## Key Features

- 🤖 **Local LLM Integration**: Uses HY-MT1.5-1.8B-GGUF (Q4_K_M) model for offline AI assistance
- 💬 **Chat Interface**: Clean, modern chat UI with light and dark themes
- 🎤 **Voice Input**: Speech-to-text functionality for hands-free interaction
- 📸 **Media Support**: Send photos and files from your device
- 🌐 **Offline-First**: AI processing happens locally on your device
- 🎨 **Modern UI**: ChatGPT-inspired design with Material Design 3

## Architecture

The project follows **Clean Architecture** principles with a feature-based structure:

```
lib/
├── core/                 # Core functionality and utilities
│   ├── di/              # Dependency injection setup
│   ├── theme/           # Theme configuration
│   ├── constants/       # App-wide constants
│   └── utils/           # Utility functions
├── features/            # Feature modules
│   ├── chat/           # Chat functionality
│   └── model_management/ # LLM model management
└── main.dart           # App entry point
```

For detailed architecture documentation, see [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md).

## Technology Stack

- **Framework**: Flutter 3.x
- **Language**: Dart 3.x
- **State Management**: Riverpod 2.x
- **Local Storage**: Hive
- **Network**: Dio
- **LLM Runtime**: llama.cpp (via FFI)

## Getting Started

### Prerequisites

- Flutter SDK 3.2.0 or higher
- Dart SDK 3.2.0 or higher
- Android Studio / Xcode for platform-specific builds
- Git

### Installation

1. Clone the repository:
```bash
git clone <repository-url>
cd cruises-mobile
```

2. Install dependencies:
```bash
flutter pub get
```

3. Run code generation:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

4. Run the app:
```bash
flutter run
```

For detailed setup instructions, see [docs/SETUP.md](docs/SETUP.md).

## Building

### Android
```bash
flutter build apk --release
```

### iOS
```bash
flutter build ios --release
```

## CI/CD

The project uses GitHub Actions for automated builds on both Android and iOS platforms using a custom macOS runner.

See [docs/CI_CD.md](docs/CI_CD.md) for details.

## Project Status

🚧 **In Development** - Initial setup phase

## License

Proprietary - All rights reserved

## Contact

For questions or support, please contact the development team.

