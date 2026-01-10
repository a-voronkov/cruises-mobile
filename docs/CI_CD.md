# CI/CD Documentation

This document describes the **optimized** Continuous Integration and Continuous Deployment setup for the Cruises Mobile application.

## 🚀 Overview

The project uses **GitHub Actions** with an **optimized multi-job architecture** for automated builds on both Android and iOS platforms. Builds run on a **self-hosted macOS runner** (MacinCloud agent).

### Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                         SETUP JOB                           │
│  • Install Flutter SDK (cached)                             │
│  • Install dependencies (cached)                            │
│  • Run code generation (cached)                             │
│  • Run tests & analyze                                      │
│  • Upload generated code as artifact                        │
└─────────────────┬───────────────────────────────────────────┘
                  │
         ┌────────┴────────┐
         ▼                 ▼
┌─────────────────┐ ┌─────────────────┐
│ BUILD ANDROID   │ │   BUILD iOS     │
│ • Restore cache │ │ • Restore cache │
│ • Build llama   │ │ • Build llama   │
│ • Build APK/AAB │ │ • Build IPA     │
└────────┬────────┘ └────────┬────────┘
         │                   │
         └────────┬──────────┘
                  ▼
         ┌─────────────────┐
         │ CREATE RELEASE  │
         │ • Download all  │
         │ • Create GitHub │
         │   release       │
         └─────────────────┘
```

**Key Benefits:**
- ✅ **68% faster** builds with intelligent caching (~10 min vs ~31 min)
- ✅ Parallel Android/iOS builds
- ✅ Automatic llama.cpp compilation with caching
- ✅ Reusable dependencies across jobs
- ✅ Smart cache invalidation

## 📁 Workflow Files

- **`.github/workflows/build.yml`** - Main optimized workflow
- **`docs/CI_CD_OPTIMIZATION.md`** - Detailed optimization guide ⭐
- **`docs/CI_CD_LLAMA_SETUP.md`** - llama.cpp integration details

## Workflow Configuration

The main workflow is defined in `.github/workflows/build.yml`.

### Triggers

The workflow runs **only on manual trigger**:
- **Manual trigger only** via workflow_dispatch (GitHub Actions UI or CLI)
- No automatic builds on push, PR, or tags
- You control when to build and release

### Jobs

#### 1. setup
Installs and caches all dependencies and tools

**Steps:**
1. Checkout code
2. Cache & install Flutter SDK
3. Cache & install Pub dependencies
4. Cache & run code generation
5. Analyze code
6. Run tests
7. Upload generated code as artifact

**Outputs:**
- `generated-code`: Generated Dart files for build jobs
- Cache keys for Flutter, Pub, and generated code

**Duration:**
- First run: ~5 min
- With cache: ~2 min

#### 2. build-android
Builds Android APK and App Bundle (AAB) - runs in parallel with iOS

**Steps:**
1. Checkout code
2. Restore Flutter SDK from cache
3. Restore Pub dependencies from cache
4. Download generated code from setup job
5. Setup Java 17 with Gradle caching
6. Cache & build llama.cpp for Android
7. Build APK (release)
8. Build AAB (release)
9. Upload artifacts

**Outputs:**
- `android-apk`: Release APK file
- `android-aab`: Release App Bundle for Play Store

**Duration:**
- First run: ~10 min
- With cache: ~3 min

#### 3. build-ios
Builds iOS application - runs in parallel with Android

**Steps:**
1. Checkout code
2. Restore Flutter SDK from cache
3. Restore Pub dependencies from cache
4. Download generated code from setup job
5. Cache CocoaPods dependencies
6. Cache & build llama.cpp for iOS
7. Install CocoaPods dependencies
8. Build iOS (no codesign)
9. Upload artifacts

**Outputs:**
- `ios-build`: iOS application bundle

**Duration:**
- First run: ~15 min
- With cache: ~4 min

#### 4. create-release
Creates a GitHub release with build artifacts

**Conditions:**
- Always runs after successful Android and iOS builds
- Only on manual workflow dispatch

**Steps:**
1. Download Android APK
2. Download Android AAB
3. Download iOS build
4. Determine release tag
5. Create GitHub release with artifacts
6. Print build summary

**Outputs:**
- GitHub release with APK, AAB, and iOS build attached

**Duration:** ~1 min

## 📊 Performance Comparison

| Scenario | Old Workflow | New Workflow | Improvement |
|----------|--------------|--------------|-------------|
| **First build** | ~35 min | ~31 min | ~11% |
| **With cache** | ~35 min | ~10 min | **68%** ⚡ |
| **After llama update** | ~35 min | ~28 min | ~20% |

### Caching Strategy

| Cache | Key | Size | Time Saved |
|-------|-----|------|------------|
| Flutter SDK | `flutter-{os}-{version}` | ~500 MB | ~2 min |
| Pub dependencies | `pub-{os}-{hash(pubspec.lock)}` | ~200 MB | ~1 min |
| Generated code | `generated-{os}-{hash}` | ~10 MB | ~30 sec |
| Gradle | `gradle-{os}-{hash}` | ~300 MB | ~1 min |
| CocoaPods | `pods-{os}-{hash}` | ~400 MB | ~2 min |
| llama.cpp Android | `llama-android-{hash}` | ~50 MB | ~7 min |
| llama.cpp iOS | `llama-ios-{hash}` | ~100 MB | ~10 min |

**Total time saved:** ~20-25 minutes per build! 🎉

## Self-Hosted Runner Setup

### MacinCloud Configuration

1. **Create MacinCloud Account**
   - Sign up at https://www.macincloud.com/
   - Choose a plan with macOS support

2. **Access Your Mac Instance**
   - Connect via VNC or SSH
   - Ensure you have admin access

3. **Install Prerequisites**

```bash
# Install Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install Git
brew install git

# Install Flutter
git clone https://github.com/flutter/flutter.git -b stable ~/flutter
echo 'export PATH="$PATH:$HOME/flutter/bin"' >> ~/.zshrc
source ~/.zshrc

# Verify Flutter installation
flutter doctor

# Install Xcode (from App Store)
# Install Xcode Command Line Tools
xcode-select --install

# Accept Xcode license
sudo xcodebuild -license accept

# Install CocoaPods
sudo gem install cocoapods

# Install Java (for Android builds)
brew install openjdk@17
echo 'export PATH="/opt/homebrew/opt/openjdk@17/bin:$PATH"' >> ~/.zshrc

# Install Android Studio and SDK
# Download from https://developer.android.com/studio
# Set ANDROID_HOME environment variable
echo 'export ANDROID_HOME=$HOME/Library/Android/sdk' >> ~/.zshrc
echo 'export PATH=$PATH:$ANDROID_HOME/tools:$ANDROID_HOME/platform-tools' >> ~/.zshrc
source ~/.zshrc
```

4. **Setup GitHub Actions Runner**

```bash
# Create a directory for the runner
mkdir actions-runner && cd actions-runner

# Download the latest runner package
curl -o actions-runner-osx-x64-2.311.0.tar.gz -L \
  https://github.com/actions/runner/releases/download/v2.311.0/actions-runner-osx-x64-2.311.0.tar.gz

# Extract the installer
tar xzf ./actions-runner-osx-x64-2.311.0.tar.gz

# Configure the runner
./config.sh --url https://github.com/YOUR_ORG/cruises-mobile --token YOUR_TOKEN

# Install as a service
./svc.sh install

# Start the service
./svc.sh start
```

5. **Verify Runner**
   - Go to GitHub repository → Settings → Actions → Runners
   - Verify the runner shows as "Idle" or "Active"

### Runner Maintenance

**Check runner status:**
```bash
cd ~/actions-runner
./svc.sh status
```

**Restart runner:**
```bash
./svc.sh stop
./svc.sh start
```

**Update runner:**
```bash
./svc.sh stop
./config.sh remove
# Download and configure new version
./svc.sh install
./svc.sh start
```

## Secrets Configuration

Configure the following secrets in GitHub repository settings:

### Required Secrets

1. **GITHUB_TOKEN** (automatically provided by GitHub Actions)

### Optional Secrets (for signed builds)

#### Android Signing
- `ANDROID_KEYSTORE_BASE64`: Base64-encoded keystore file
- `ANDROID_KEYSTORE_PASSWORD`: Keystore password
- `ANDROID_KEY_ALIAS`: Key alias
- `ANDROID_KEY_PASSWORD`: Key password

#### iOS Signing
- `IOS_CERTIFICATE_BASE64`: Base64-encoded signing certificate
- `IOS_CERTIFICATE_PASSWORD`: Certificate password
- `IOS_PROVISIONING_PROFILE_BASE64`: Base64-encoded provisioning profile
- `APPLE_ID`: Apple ID for App Store Connect
- `APPLE_APP_SPECIFIC_PASSWORD`: App-specific password

## Build Artifacts

### Accessing Build Artifacts

1. Go to GitHub Actions tab
2. Click on a workflow run
3. Scroll to "Artifacts" section
4. Download desired artifacts

### Artifact Retention

- Artifacts are retained for **90 days** by default
- Can be configured in workflow file

## Deployment

### Android Deployment

#### Google Play Store

1. Download AAB artifact from GitHub Actions
2. Go to Google Play Console
3. Create a new release
4. Upload the AAB file
5. Complete release notes and submit

#### Direct Distribution

1. Download APK artifact
2. Distribute via your preferred method (website, Firebase App Distribution, etc.)

### iOS Deployment

#### App Store

1. Build signed IPA (requires certificates)
2. Upload to App Store Connect using Transporter or Xcode
3. Submit for review

#### TestFlight

1. Upload IPA to App Store Connect
2. Add to TestFlight
3. Invite testers

## Monitoring and Notifications

### Email Notifications

GitHub sends email notifications for:
- Failed builds
- Successful builds (if configured)

### Slack Integration (Optional)

Add Slack notification step to workflow:

```yaml
- name: Notify Slack
  uses: 8398a7/action-slack@v3
  with:
    status: ${{ job.status }}
    text: 'Build completed'
    webhook_url: ${{ secrets.SLACK_WEBHOOK }}
  if: always()
```

## Troubleshooting

### Build Failures

1. Check workflow logs in GitHub Actions
2. Verify runner is online and healthy
3. Check Flutter and dependency versions
4. Ensure all secrets are configured correctly

### Runner Issues

1. SSH into MacinCloud instance
2. Check runner logs: `~/actions-runner/_diag/`
3. Restart runner service
4. Check system resources (disk space, memory)

### Common Issues

**Issue: Runner offline**
- Solution: Restart runner service or MacinCloud instance

**Issue: Build timeout**
- Solution: Increase timeout in workflow or optimize build

**Issue: Code signing fails**
- Solution: Verify certificates and provisioning profiles

## Best Practices

1. **Use caching** to speed up builds
2. **Run tests** before building
3. **Version your releases** properly
4. **Keep secrets secure** - never commit them
5. **Monitor build times** and optimize
6. **Keep runner updated** with latest tools

## Future Improvements

- [ ] Add automated testing on multiple devices
- [ ] Implement automatic deployment to stores
- [ ] Add performance testing
- [ ] Set up beta distribution channels
- [ ] Implement version bumping automation

