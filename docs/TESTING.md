# Testing Strategy

This document outlines the testing strategy for Cruises Mobile, including unit tests, widget tests, integration tests, and manual testing procedures.

## 📊 Testing Overview

### Testing Pyramid

```
        /\
       /  \      E2E Tests (5%)
      /    \     - Critical user flows
     /------\
    /        \   Integration Tests (15%)
   /          \  - Feature integration
  /------------\
 /              \ Unit Tests (80%)
/________________\ - Business logic, utilities
```

### Coverage Goals

| Test Type | Target Coverage | Current Coverage |
|-----------|----------------|------------------|
| **Unit Tests** | 80%+ | ~30% |
| **Widget Tests** | 60%+ | 0% |
| **Integration Tests** | Critical flows | 0% |

---

## 🧪 Unit Tests

Unit tests focus on testing individual functions, classes, and utilities in isolation.

### What to Test

1. **Core Utilities**
   - ✅ Chat template formatting
   - [ ] Date/time utilities
   - [ ] String utilities
   - [ ] Validation functions

2. **Business Logic**
   - [ ] LlamaService methods
   - [ ] Model initialization logic
   - [ ] Conversation management
   - [ ] Message processing

3. **Data Models**
   - [ ] Model serialization/deserialization
   - [ ] Model validation
   - [ ] Model equality
   - [ ] Model copying

4. **Repositories**
   - [ ] Conversation repository
   - [ ] Model storage repository
   - [ ] Settings repository

### Running Unit Tests

```bash
# Run all unit tests
flutter test

# Run specific test file
flutter test test/core/utils/chat_template_test.dart

# Run with coverage
flutter test --coverage

# View coverage report
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

### Writing Unit Tests

**Example:**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:cruises_mobile/core/utils/chat_template.dart';

void main() {
  group('ChatTemplate', () {
    test('formatUserMessage should format correctly', () {
      // Arrange
      const message = 'Hello, world!';

      // Act
      final result = ChatTemplate.formatUserMessage(message);

      // Assert
      expect(result, contains('<|im_start|>user'));
      expect(result, contains(message));
      expect(result, contains('<|im_end|>'));
    });

    test('formatMessages should handle multiple messages', () {
      // Arrange
      final messages = [
        {'role': 'user', 'content': 'Hi'},
        {'role': 'assistant', 'content': 'Hello'},
      ];

      // Act
      final result = ChatTemplate.formatMessages(messages: messages);

      // Assert
      expect(result, contains('<|im_start|>user'));
      expect(result, contains('<|im_start|>assistant'));
    });
  });
}
```

---

## 🎨 Widget Tests

Widget tests verify that UI components render correctly and respond to user interactions.

### What to Test

1. **Chat Components**
   - [ ] Message widget (user/assistant)
   - [ ] Chat input field
   - [ ] Typing indicator
   - [ ] Message list
   - [ ] Copy button

2. **Model Management**
   - [ ] Download progress widget
   - [ ] Model info display
   - [ ] Initialization screen

3. **Navigation**
   - [ ] App bar
   - [ ] Bottom navigation
   - [ ] Drawer menu

### Running Widget Tests

```bash
# Run all widget tests
flutter test test/features/

# Run specific widget test
flutter test test/features/chat/presentation/widgets/message_widget_test.dart


### Writing Integration Tests

**Example:**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:cruises_mobile/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('App Integration Tests', () {
    testWidgets('Complete chat flow', (tester) async {
      // Launch app
      app.main();
      await tester.pumpAndSettle();

      // Wait for initialization
      await tester.pumpAndSettle(Duration(seconds: 5));

      // Find and tap new conversation button
      final newConversationButton = find.byIcon(Icons.add);
      expect(newConversationButton, findsOneWidget);
      await tester.tap(newConversationButton);
      await tester.pumpAndSettle();

      // Enter message
      final inputField = find.byType(TextField);
      await tester.enterText(inputField, 'Plan a cruise to Alaska');
      await tester.pumpAndSettle();

      // Send message
      final sendButton = find.byIcon(Icons.send);
      await tester.tap(sendButton);
      await tester.pumpAndSettle();

      // Wait for response
      await tester.pumpAndSettle(Duration(seconds: 10));

      // Verify response appears
      expect(find.textContaining('Alaska'), findsWidgets);
    });
  });
}
```

---

## 📱 Manual Testing

Manual testing checklist for real device testing.

### Pre-Release Testing Checklist

#### Android Testing

**Devices to Test:**
- [ ] Android 8.0 (API 26) - Minimum supported
- [ ] Android 10 (API 29) - Common version
- [ ] Android 13 (API 33) - Latest stable
- [ ] Android 14 (API 34) - Latest

**Test Cases:**

1. **Installation & Setup**
   - [ ] App installs successfully
   - [ ] Permissions requested correctly
   - [ ] Model downloads successfully
   - [ ] Model loads without errors

2. **Chat Functionality**
   - [ ] Can send text messages
   - [ ] Receives AI responses
   - [ ] Streaming works smoothly
   - [ ] Can copy messages
   - [ ] Can create new conversations
   - [ ] Can delete conversations

3. **Performance**
   - [ ] App launches in < 3 seconds
   - [ ] Model loads in < 5 seconds
   - [ ] Inference speed > 50 tok/s
   - [ ] UI remains responsive
   - [ ] No memory leaks
   - [ ] Battery usage acceptable

4. **UI/UX**
   - [ ] Light theme works correctly
   - [ ] Dark theme works correctly
   - [ ] Animations smooth (60 FPS)
   - [ ] Text readable on all screen sizes
   - [ ] Touch targets adequate size

5. **Error Handling**
   - [ ] Handles network errors gracefully
   - [ ] Handles model loading errors
   - [ ] Handles inference errors
   - [ ] Shows helpful error messages

#### iOS Testing

**Devices to Test:**
- [ ] iPhone 8 (iOS 13) - Minimum supported
- [ ] iPhone 11 (iOS 14-15) - Common version
- [ ] iPhone 13 (iOS 16) - Recent
- [ ] iPhone 15 (iOS 17) - Latest

**Test Cases:** (Same as Android, plus iOS-specific)

1. **iOS-Specific**
   - [ ] App Store guidelines compliance
   - [ ] Privacy manifest correct
   - [ ] No private API usage
   - [ ] Accessibility features work

---

## 🔍 Performance Testing

### Metrics to Monitor

| Metric | Target | How to Measure |
|--------|--------|----------------|
| **App Launch Time** | < 3 sec | Manual timing |
| **Model Load Time** | < 5 sec | Logging |
| **Inference Speed** | > 50 tok/s | Logging |
| **Memory Usage** | < 500 MB | Android Studio Profiler |
| **Battery Drain** | < 5%/hour | Device battery stats |
| **APK Size** | < 50 MB | Build output |

### Performance Testing Tools

1. **Flutter DevTools**
   ```bash
   flutter pub global activate devtools
   flutter pub global run devtools
   ```

2. **Android Studio Profiler**
   - CPU profiling
   - Memory profiling
   - Network profiling

3. **Xcode Instruments**
   - Time Profiler
   - Allocations
   - Leaks

---

## 🐛 Bug Reporting

### Bug Report Template

```markdown
**Title:** Brief description of the bug

**Environment:**
- Device: [e.g., Pixel 7, iPhone 14]
- OS Version: [e.g., Android 13, iOS 17]
- App Version: [e.g., 1.0.0]

**Steps to Reproduce:**
1. Step 1
2. Step 2
3. Step 3

**Expected Behavior:**
What should happen

**Actual Behavior:**
What actually happens

**Screenshots/Logs:**
Attach relevant screenshots or logs

**Severity:**
- [ ] Critical (app crashes)
- [ ] High (major feature broken)
- [ ] Medium (minor feature broken)
- [ ] Low (cosmetic issue)
```

---

## 📋 Test Plan by Phase

### Phase 1: Foundation (Current)

- [x] Unit tests for chat template
- [ ] Unit tests for core utilities
- [ ] Widget tests for basic components

### Phase 2: LLM Integration

- [ ] Unit tests for LlamaService
- [ ] Integration tests for model loading
- [ ] Integration tests for inference
- [ ] Manual testing on real devices

### Phase 3: Chat Functionality

- [ ] Unit tests for conversation management
- [ ] Widget tests for chat UI
- [ ] Integration tests for chat flow
- [ ] Manual testing of chat features

### Phase 4: Advanced Features

- [ ] Unit tests for voice input
- [ ] Unit tests for media handling
- [ ] Integration tests for function calling
- [ ] Manual testing of all features

### Phase 5: Pre-Release

- [ ] Comprehensive unit test coverage (80%+)
- [ ] Comprehensive widget test coverage (60%+)
- [ ] All integration tests passing
- [ ] Manual testing on 10+ devices
- [ ] Performance testing
- [ ] Security audit
- [ ] Accessibility testing

---

## 🎯 Testing Best Practices

1. **Write Tests First (TDD)**
   - Write failing test
   - Implement feature
   - Make test pass
   - Refactor

2. **Keep Tests Simple**
   - One assertion per test
   - Clear test names
   - Arrange-Act-Assert pattern

3. **Mock External Dependencies**
   - Use mockito for mocking
   - Don't test external libraries
   - Focus on your code

4. **Run Tests Frequently**
   - Before committing
   - In CI/CD pipeline
   - Before releases

5. **Maintain Tests**
   - Update tests when code changes
   - Remove obsolete tests
   - Keep tests fast

---

## 🚀 Continuous Integration

### CI/CD Testing

The GitHub Actions workflow runs tests automatically:

```yaml
# In .github/workflows/build.yml
- name: Run tests
  run: flutter test --coverage

- name: Upload coverage
  uses: codecov/codecov-action@v3
  with:
    files: coverage/lcov.info
```

### Pre-Commit Hooks

Setup pre-commit hooks to run tests:

```bash
# .git/hooks/pre-commit
#!/bin/sh
flutter test
if [ $? -ne 0 ]; then
  echo "Tests failed. Commit aborted."
  exit 1
fi
```

---

## 📚 Resources

- [Flutter Testing Documentation](https://docs.flutter.dev/testing)
- [Widget Testing](https://docs.flutter.dev/cookbook/testing/widget/introduction)
- [Integration Testing](https://docs.flutter.dev/testing/integration-tests)
- [Mockito Package](https://pub.dev/packages/mockito)
- [Flutter Test Best Practices](https://flutter.dev/docs/testing/best-practices)

---

## 📝 Next Steps

1. **Immediate (This Week)**
   - Write unit tests for LlamaService
   - Write widget tests for chat components
   - Setup integration test framework

2. **Short Term (Next 2 Weeks)**
   - Achieve 60%+ unit test coverage
   - Write integration tests for critical flows
   - Setup CI/CD testing

3. **Long Term (Before Release)**
   - Achieve 80%+ unit test coverage
   - Achieve 60%+ widget test coverage
   - Complete manual testing on 10+ devices
   - Performance testing and optimization
