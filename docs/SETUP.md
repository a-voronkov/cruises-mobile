# Setup Guide

This guide will help you set up the development environment and build the Cruises Mobile application.

## Prerequisites

### Required Software

1. **Flutter SDK** (3.2.0 or higher)
   - Download from: https://flutter.dev/docs/get-started/install
   - Add Flutter to your PATH

2. **Dart SDK** (3.2.0 or higher)
   - Included with Flutter

3. **Git**
   - Download from: https://git-scm.com/

### Platform-Specific Requirements

#### For Android Development

1. **Android Studio** (latest version)
   - Download from: https://developer.android.com/studio
   
2. **Android SDK**
   - API Level 24 (Android 7.0) minimum
   - API Level 34 (Android 14) target
   
3. **Java Development Kit (JDK)**
   - JDK 17 or higher
   
4. **Android NDK**
   - Version 25.1.8937393 (for native code support)

#### For iOS Development (macOS only)

1. **Xcode** (latest version)
   - Download from Mac App Store
   
2. **CocoaPods**
   ```bash
   sudo gem install cocoapods
   ```

3. **iOS Simulator** or physical iOS device

## Installation Steps

### 1. Clone the Repository

```bash
git clone <repository-url>
cd cruises-mobile
```

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Run Code Generation

The project uses code generation for dependency injection, JSON serialization, and state management:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

For continuous code generation during development:

```bash
flutter pub run build_runner watch --delete-conflicting-outputs
```

### 4. Verify Installation

Check that Flutter is properly installed and configured:

```bash
flutter doctor
```

Fix any issues reported by `flutter doctor` before proceeding.

## Running the Application

### Development Mode

#### Android
```bash
flutter run
```

Or select an Android device/emulator in your IDE and run.

#### iOS (macOS only)
```bash
flutter run
```

Or select an iOS simulator/device in your IDE and run.

### Release Mode

#### Android APK
```bash
flutter build apk --release
```

Output: `build/app/outputs/flutter-apk/app-release.apk`

#### Android App Bundle (for Play Store)
```bash
flutter build appbundle --release
```

Output: `build/app/outputs/bundle/release/app-release.aab`

#### iOS (requires code signing)
```bash
flutter build ios --release
```

Or for IPA:
```bash
flutter build ipa --release
```

## Configuration

### Model Download URL

Update the model download URL in `lib/core/constants/app_constants.dart`:

```dart
static const String modelDownloadUrl = 'https://your-server.com/models/$modelFileName';
```

### App Signing (Production)

#### Android

1. Create a keystore:
```bash
keytool -genkey -v -keystore ~/cruises-release-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias cruises
```

2. Create `android/key.properties`:
```properties
storePassword=<password>
keyPassword=<password>
keyAlias=cruises
storeFile=<path-to-keystore>
```

3. Update `android/app/build.gradle` to use the keystore.

#### iOS

1. Configure signing in Xcode
2. Create provisioning profiles
3. Update `ios/ExportOptions.plist`

## Troubleshooting

### Common Issues

1. **Build fails with "SDK not found"**
   - Run `flutter doctor` and fix any issues
   - Ensure Android SDK/Xcode is properly installed

2. **Code generation fails**
   - Delete generated files: `find . -name "*.g.dart" -delete`
   - Run build_runner again

3. **Gradle build fails**
   - Clean build: `cd android && ./gradlew clean`
   - Invalidate caches in Android Studio

4. **iOS build fails**
   - Clean build folder: `flutter clean`
   - Update pods: `cd ios && pod install`

5. **Dependencies conflict**
   - Delete `pubspec.lock`
   - Run `flutter pub get` again

### Getting Help

- Check the [Architecture Documentation](ARCHITECTURE.md)
- Review Flutter documentation: https://flutter.dev/docs
- Check GitHub Issues

## Development Workflow

1. Create a feature branch
2. Make changes
3. Run tests: `flutter test`
4. Run analyzer: `flutter analyze`
5. Format code: `flutter format .`
6. Commit and push
7. Create pull request

## Next Steps

- Read [ARCHITECTURE.md](ARCHITECTURE.md) to understand the project structure
- Read [CI_CD.md](CI_CD.md) to set up automated builds
- Start developing features!

