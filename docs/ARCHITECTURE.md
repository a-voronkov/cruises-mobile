# Architecture Documentation

## Overview

Cruises Mobile follows **Clean Architecture** principles combined with a **feature-based** folder structure. This approach ensures:

- **Separation of Concerns**: Clear boundaries between business logic, data, and presentation
- **Testability**: Easy to write unit tests for each layer
- **Maintainability**: Changes in one layer don't affect others
- **Scalability**: Easy to add new features without affecting existing code

## Architecture Layers

### 1. Presentation Layer
- **Responsibility**: UI components, user interactions, state management
- **Components**:
  - `pages/`: Full-screen views
  - `widgets/`: Reusable UI components
  - `providers/`: Riverpod state providers
- **Dependencies**: Can depend on Domain layer only

### 2. Domain Layer
- **Responsibility**: Business logic, use cases, entities
- **Components**:
  - `entities/`: Core business objects (immutable)
  - `repositories/`: Abstract repository interfaces
  - `usecases/`: Business logic operations
- **Dependencies**: No dependencies on other layers (pure Dart)

### 3. Data Layer
- **Responsibility**: Data sources, API calls, local storage
- **Components**:
  - `models/`: Data transfer objects (DTOs)
  - `datasources/`: Remote and local data sources
  - `repositories/`: Repository implementations
- **Dependencies**: Implements Domain layer interfaces

## Project Structure

```
lib/
├── core/
│   ├── di/
│   │   ├── injection.dart              # GetIt setup
│   │   └── injection.config.dart       # Generated DI config
│   ├── theme/
│   │   ├── app_theme.dart              # Theme definitions
│   │   └── app_colors.dart             # Color palette
│   ├── constants/
│   │   ├── app_constants.dart          # App-wide constants
│   │   └── api_constants.dart          # API endpoints
│   ├── utils/
│   │   ├── logger.dart                 # Logging utility
│   │   └── validators.dart             # Input validators
│   └── errors/
│       ├── failures.dart               # Error types
│       └── exceptions.dart             # Exception types
│
├── features/
│   ├── chat/
│   │   ├── data/
│   │   │   ├── models/
│   │   │   │   ├── message_model.dart
│   │   │   │   └── conversation_model.dart
│   │   │   ├── datasources/
│   │   │   │   ├── chat_local_datasource.dart
│   │   │   │   └── llm_inference_datasource.dart
│   │   │   └── repositories/
│   │   │       └── chat_repository_impl.dart
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   ├── message.dart
│   │   │   │   └── conversation.dart
│   │   │   ├── repositories/
│   │   │   │   └── chat_repository.dart
│   │   │   └── usecases/
│   │   │       ├── send_message.dart
│   │   │       ├── get_conversations.dart
│   │   │       └── delete_conversation.dart
│   │   └── presentation/
│   │       ├── providers/
│   │       │   ├── chat_provider.dart
│   │       │   └── theme_provider.dart
│   │       ├── widgets/
│   │       │   ├── message_bubble.dart
│   │       │   ├── chat_input.dart
│   │       │   └── voice_input_button.dart
│   │       └── pages/
│   │           ├── chat_page.dart
│   │           └── conversations_page.dart
│   │
│   └── model_management/
│       ├── data/
│       │   ├── models/
│       │   │   └── model_info_model.dart
│       │   ├── datasources/
│       │   │   ├── model_download_datasource.dart
│       │   │   └── model_storage_datasource.dart
│       │   └── repositories/
│       │       └── model_repository_impl.dart
│       ├── domain/
│       │   ├── entities/
│       │   │   └── model_info.dart
│       │   ├── repositories/
│       │   │   └── model_repository.dart
│       │   └── usecases/
│       │       ├── download_model.dart
│       │       ├── load_model.dart
│       │       └── check_model_status.dart
│       └── presentation/
│           ├── providers/
│           │   └── model_provider.dart
│           ├── widgets/
│           │   └── download_progress.dart
│           └── pages/
│               └── model_setup_page.dart
│
└── main.dart
```

## Key Design Patterns

### 1. Repository Pattern
Abstracts data sources from business logic. Domain layer defines interfaces, Data layer implements them.

### 2. Use Case Pattern
Each business operation is encapsulated in a single use case class with a clear `call()` method.

### 3. Dependency Injection
Uses `get_it` with `injectable` for automatic dependency registration.

### 4. State Management
Riverpod providers for reactive state management with proper separation of concerns.

## Data Flow

```
User Interaction → Widget → Provider → Use Case → Repository → Data Source → External API/DB
                                                                                      ↓
User sees result ← Widget ← Provider ← Use Case ← Repository ← Data Source ← Response
```

## LLM Integration Architecture

The LLM integration uses a native bridge approach:

1. **Model Download**: Downloads GGUF model file from server on first launch
2. **Model Storage**: Stores model in app's documents directory
3. **Model Loading**: Loads model into memory using llama.cpp via FFI
4. **Inference**: Processes user messages locally and streams responses

## Error Handling

- **Failures**: Domain-level errors (business logic failures)
- **Exceptions**: Data-level errors (network, storage, etc.)
- All errors are typed and handled gracefully with user-friendly messages

## Testing Strategy

- **Unit Tests**: Domain layer (use cases, entities)
- **Widget Tests**: Presentation layer (UI components)
- **Integration Tests**: Full feature flows
- **Mock Data**: Use cases and repositories are easily mockable

## Performance Considerations

- **Lazy Loading**: Models and heavy resources loaded on demand
- **Caching**: Hive for local data caching
- **Streaming**: LLM responses streamed for better UX
- **Background Processing**: Heavy operations run in isolates

## Security

- **Local Processing**: All AI inference happens on-device
- **Data Privacy**: No user data sent to external servers
- **Secure Storage**: Sensitive data encrypted with Hive

## Future Enhancements

- Multi-model support
- Cloud sync (optional)
- Advanced travel planning features
- Offline maps integration
- Itinerary management

