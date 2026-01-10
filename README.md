# Cruises Mobile - AI Travel Planning Assistant

An autonomous travel planning assistant mobile application with embedded LLM capabilities for Android and iOS platforms.

[![Flutter](https://img.shields.io/badge/Flutter-3.19.0-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.2.0-0175C2?logo=dart)](https://dart.dev)
[![License](https://img.shields.io/badge/License-Proprietary-red.svg)](LICENSE)

## 📑 Table of Contents

- [Overview](#overview)
- [Key Features](#key-features)
- [Technology Stack](#technology-stack)
- [Architecture](#architecture)
- [Getting Started](#getting-started)
  - [Prerequisites](#prerequisites)
  - [Quick Start](#quick-start)
  - [LLM Model Setup](#llm-model-setup)
- [Building](#building)
- [CI/CD](#cicd)
- [Documentation](#documentation)
- [Development Roadmap](#development-roadmap)
- [Testing](#testing)
- [Project Status](#project-status)
- [License](#license)

## Overview

Cruises Mobile is a Flutter-based mobile application that provides intelligent travel planning assistance using a locally-running Large Language Model (LLM). The app features a ChatGPT-like interface with support for text, voice, and file inputs.

**Key Highlights:**
- 🎯 **Privacy-First**: All AI processing happens on-device
- 🚀 **High Performance**: Optimized for mobile with 82 tok/s on NPU
- 🌍 **Multilingual**: Supports 8 languages (EN, AR, ZH, FR, DE, JA, KO, ES)
- 📱 **Cross-Platform**: Native Android and iOS support

## Key Features

- 🤖 **Local LLM Integration**: Uses LiquidAI LFM2.5-1.2B-Instruct model for offline AI assistance
- 💬 **Chat Interface**: Clean, modern chat UI with light and dark themes
- 🎤 **Voice Input**: Speech-to-text functionality for hands-free interaction
- 📸 **Media Support**: Send photos and files from your device
- 🌐 **Offline-First**: AI processing happens locally on your device
- 🎨 **Modern UI**: ChatGPT-inspired design with Material Design 3
- ⚡ **Fast Inference**: Optimized with llama.cpp for mobile performance
- 🔒 **Privacy**: No data leaves your device

## Technology Stack

| Category | Technology |
|----------|------------|
| **Framework** | Flutter 3.19.0 |
| **Language** | Dart 3.2.0+ |
| **State Management** | Riverpod 2.x |
| **Local Storage** | Hive |
| **Network** | Dio |
| **LLM Runtime** | llama.cpp (via llama_cpp_dart) |
| **LLM Model** | LiquidAI LFM2.5-1.2B-Instruct (GGUF Q4_K_M) |
| **Code Generation** | build_runner, freezed, json_serializable |
| **Dependency Injection** | get_it, injectable |

## Architecture

The project follows **Clean Architecture** principles with a feature-based structure:

```
lib/
├── core/                    # Core functionality and utilities
│   ├── di/                 # Dependency injection setup
│   ├── theme/              # Theme configuration
│   ├── constants/          # App-wide constants
│   ├── services/           # Core services (LLM, storage)
│   └── utils/              # Utility functions (chat template)
├── features/               # Feature modules
│   ├── chat/              # Chat functionality
│   │   ├── data/          # Data layer (repositories, models)
│   │   ├── domain/        # Domain layer (entities, use cases)
│   │   └── presentation/  # UI layer (widgets, providers)
│   └── model_management/  # LLM model management
│       ├── data/
│       ├── domain/
│       └── presentation/
└── main.dart              # App entry point
```

**Design Patterns:**
- Repository Pattern for data abstraction
- Use Case Pattern for business logic
- Provider Pattern for state management
- Dependency Injection for loose coupling

📖 **Detailed documentation**: [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)

## Getting Started

### Prerequisites

- **Flutter SDK**: 3.19.0 or higher
- **Dart SDK**: 3.2.0 or higher
- **Android Studio** / **Xcode** for platform-specific builds
- **Git**
- **llama.cpp library** (see [docs/LLAMA_CPP_SETUP.md](docs/LLAMA_CPP_SETUP.md))

### Quick Start

1. **Clone the repository:**
   ```bash
   git clone <repository-url>
   cd cruises-mobile
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Run code generation:**
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

4. **Download LLM model** (~700 MB):
   ```bash
   cd models
   wget https://huggingface.co/LiquidAI/LFM2.5-1.2B-Instruct-GGUF/resolve/main/lfm2.5-1.2b-instruct-q4_k_m.gguf
   ```

5. **Setup llama.cpp library:**
   - See [docs/LLAMA_CPP_SETUP.md](docs/LLAMA_CPP_SETUP.md) for platform-specific instructions

6. **Run the app:**
   ```bash
   flutter run
   ```

📖 **Detailed setup**: [QUICKSTART.md](QUICKSTART.md)

### LLM Model Setup

The app uses **LiquidAI LFM2.5-1.2B-Instruct** model:

- **Size**: ~700 MB (GGUF Q4_K_M quantization)
- **Context**: 32,768 tokens
- **Performance**: 82 tok/s on mobile NPU, 239 tok/s on AMD CPU
- **Memory**: Runs under 1GB RAM

**Download options:**
1. **Manual**: Download from [HuggingFace](https://huggingface.co/LiquidAI/LFM2.5-1.2B-Instruct-GGUF) and place in `models/` directory
2. **Automatic**: App will download on first launch (future feature)

📖 **Model documentation**: [docs/LFM2.5_INTEGRATION.md](docs/LFM2.5_INTEGRATION.md)

## Building

### Android

```bash
# Debug APK
flutter build apk --debug

# Release APK
flutter build apk --release

# Release App Bundle (for Google Play)
flutter build appbundle --release
```

### iOS

```bash
# Debug build
flutter build ios --debug

# Release build
flutter build ios --release
```

📖 **Build documentation**: [docs/HOW_TO_BUILD.md](docs/HOW_TO_BUILD.md)

## CI/CD

The project uses **GitHub Actions** for automated builds with intelligent caching:

- ✅ **Manual trigger only** - full control over releases
- ✅ **Multi-job architecture** - parallel Android/iOS builds
- ✅ **Intelligent caching** - 68% faster builds (~10 min vs ~31 min)
- ✅ **Automatic releases** - GitHub releases with APK, AAB, and IPA

**Trigger a build:**
```bash
# Via GitHub CLI
gh workflow run build.yml --ref main

# Via GitHub UI
Actions → Build and Release → Run workflow
```

📖 **CI/CD documentation**:
- [docs/CI_CD.md](docs/CI_CD.md) - Overview
- [docs/CI_CD_OPTIMIZATION.md](docs/CI_CD_OPTIMIZATION.md) - Optimization details
- [docs/HOW_TO_BUILD.md](docs/HOW_TO_BUILD.md) - Build instructions

## Documentation

| Document | Description |
|----------|-------------|
| **[QUICKSTART.md](QUICKSTART.md)** | Quick start guide for developers |
| **[docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)** | Detailed architecture documentation |
| **[docs/LFM2.5_INTEGRATION.md](docs/LFM2.5_INTEGRATION.md)** | LLM model integration guide |
| **[docs/LLAMA_CPP_SETUP.md](docs/LLAMA_CPP_SETUP.md)** | llama.cpp compilation instructions |
| **[docs/CI_CD.md](docs/CI_CD.md)** | CI/CD pipeline overview |
| **[docs/CI_CD_OPTIMIZATION.md](docs/CI_CD_OPTIMIZATION.md)** | CI/CD optimization details |
| **[docs/HOW_TO_BUILD.md](docs/HOW_TO_BUILD.md)** | Build and release instructions |
| **[docs/ROADMAP.md](docs/ROADMAP.md)** | Development roadmap and milestones |
| **[docs/TESTING.md](docs/TESTING.md)** | Testing strategy and guidelines |
| **[scripts/README.md](scripts/README.md)** | Build scripts documentation |

## Development Roadmap

See [docs/ROADMAP.md](docs/ROADMAP.md) for detailed development plan with milestones and tasks.

**Current Phase**: Foundation & Core Features (Q1 2026)

## Testing

The project includes comprehensive testing:

- ✅ **Unit Tests**: Core utilities and business logic
- 🚧 **Widget Tests**: UI components (in progress)
- 🚧 **Integration Tests**: End-to-end flows (planned)

**Run tests:**
```bash
# All tests
flutter test

# Specific test file
flutter test test/core/utils/chat_template_test.dart

# With coverage
flutter test --coverage
```

📖 **Testing documentation**: [docs/TESTING.md](docs/TESTING.md)

## Project Status

🚀 **Active Development** - Foundation Phase

**Completed:**
- ✅ Project structure and architecture
- ✅ LFM2.5 model integration
- ✅ Chat template implementation
- ✅ CI/CD pipeline with optimization
- ✅ Core documentation

**In Progress:**
- 🚧 Chat UI implementation
- 🚧 LLM service integration
- 🚧 Model initialization flow

**Planned:**
- 📋 Voice input integration
- 📋 Media support
- 📋 Conversation history
- 📋 Advanced features (RAG, function calling)

## License

Proprietary - All rights reserved

## Contact

For questions or support, please contact the development team.

