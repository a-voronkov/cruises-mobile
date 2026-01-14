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
  - [AI Model Setup](#ai-model-setup)
- [Building](#building)
- [CI/CD](#cicd)
- [Documentation](#documentation)
- [Development Roadmap](#development-roadmap)
- [Testing](#testing)
- [Project Status](#project-status)
- [License](#license)

## Overview

Cruises Mobile is a Flutter-based mobile application that provides intelligent travel planning assistance using AI-powered language models. The app features a ChatGPT-like interface with support for text, voice, and file inputs.

**Key Highlights:**
- 🤖 **AI-Powered**: Uses HuggingFace Inference API for state-of-the-art language models
- 🚀 **Cloud-Based**: Access to latest models without device limitations
- 🌍 **Multilingual**: Supports multiple languages through advanced LLMs
- 📱 **Cross-Platform**: Native Android and iOS support

## Key Features

- 🤖 **HuggingFace Integration**: Uses Llama-3.2-1B-Instruct and other models via HF API
- 💬 **Chat Interface**: Clean, modern chat UI with light and dark themes
- 🎤 **Voice Input**: Speech-to-text functionality for hands-free interaction
- 📸 **Media Support**: Send photos and files from your device
- 🌐 **Cloud-Powered**: Access to powerful AI models via HuggingFace
- 🎨 **Modern UI**: ChatGPT-inspired design with Material Design 3
- ⚡ **Streaming Responses**: Real-time text generation with SSE
- 🔄 **Model Selection**: Choose from various HuggingFace models

## Technology Stack

| Category | Technology |
|----------|------------|
| **Framework** | Flutter 3.38.6 |
| **Language** | Dart 3.7.0+ |
| **State Management** | Riverpod 2.x |
| **Local Storage** | Hive |
| **Network** | Dio, HTTP |
| **AI/ML** | HuggingFace Inference API + ONNX Runtime |
| **Cloud Model** | google/flan-t5-base (via HF API) |
| **Local Inference** | ONNX Runtime (requires tokenizer implementation) |
| **Error Tracking** | Bugsnag |
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

4. **Set up HuggingFace API key:**
   - Get your API key from [HuggingFace](https://huggingface.co/settings/tokens)
   - Add to GitHub Secrets as `HF_TOKEN` (for CI/CD)
   - Or configure in app settings (for local development)

5. **Run the app:**
   ```bash
   flutter run
   ```

📖 **Detailed setup**: [QUICKSTART.md](QUICKSTART.md)

### AI Model Setup

The app uses **HuggingFace Inference API** with **Llama-3.2-1B-Instruct** model:

- **API**: HuggingFace Inference API (cloud-based)
- **Model**: meta-llama/Llama-3.2-1B-Instruct
- **Context**: 128K tokens
- **Performance**: Real-time streaming responses
- **Cost**: Free tier available, pay-as-you-go for production

**Setup:**
1. **Get API Key**: Sign up at [HuggingFace](https://huggingface.co) and create an API token
2. **Configure**: Add `HF_TOKEN` to your environment or app settings
3. **Select Model**: Choose from various models in the app settings

📖 **API documentation**: [HuggingFace Inference API](https://huggingface.co/docs/api-inference/index)

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

