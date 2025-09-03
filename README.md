# ubx_practical_mobile
A new Flutter project.

## THIS APP CONTAINS PAGES AND DESIGNS AS REQUIRED ON TASKS
# Flutter Secure Mobile Application

## 🚀 Features

### Core Functionality
- **User Authentication** - Login and registration with secure credential storage
- **Profile Management** - User profile with photo capture/selection capabilities
- **Biometric Authentication** - Fingerprint/Face recognition with PIN fallback
- **App Lockout System** - Automatic app lock on pause/quit with re-authentication
- **Device Security** - Device unique ID integration for API requests

### Security Features
- **Data Encryption** - Encrypted local storage and HTTPS for API communications
- **Code Obfuscation** - Dart obfuscation to prevent reverse engineering
- **Secure Storage** - Flutter Secure Storage for sensitive data
- **Certificate Signing** - App signing with valid certificates

## Requirements

- Flutter SDK (3.0 or higher)
- Dart SDK (3.0 or higher)
- Android Studio / VS Code
- Android SDK (API level 21+)

## Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/iamgaspardev/ubx_mobile_practical_interview.git
   cd ubx_practical_mobile
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure environment**
   - Set up your development environment
   - Configure API endpoints if applicable
   - Set up signing certificates

4. **Run the application**
   flutter run

##  Dependencies

### Core Packages
```yaml
dependencies:
  flutter:
    sdk: flutter
  provider: ^6.1.1                    
  flutter_secure_storage: ^9.0.0    
  local_auth: ^2.1.6               
  device_info_plus: ^9.1.0          
  image_picker: ^1.0.4              
  http: ^1.1.0                       
```



## Security Implementation

### 1. Authentication & Authorization
- **Secure Login/Register** - Form validation with encrypted credential storage
- **JWT Token Management** - Secure token storage and refresh mechanisms
- **Session Management** - Automatic session timeout and renewal

### 2. Biometric Security

### 3. App Lockout System
- Automatic lock on app pause/background
- Biometric re-authentication required
- PIN fallback mechanism
- Configurable timeout settings

### 4. Data Protection
- **Local Storage** - All sensitive data encrypted using Flutter Secure Storage
- **API Communication** - HTTPS with certificate pinning
- **Device Binding** - Unique device ID included in all requests

### 5. Code Protection
- **Obfuscation** - Dart code obfuscation enabled for release builds
- **Certificate Signing** - Proper app signing for distribution

## Build & Deployment

### Development Build
```bash
flutter run --debug
```

### Release Build with Obfuscation
```bash
# Android
flutter build apk --release --obfuscate --split-debug-info=build/symbols

```

### Build Configuration
The app includes optimized build settings:
- Code obfuscation enabled
- Debug symbols separated
- ProGuard/R8 optimization
- Certificate signing configured


### Security Testing
- Biometric authentication flow
- App lockout mechanisms
- Secure storage validation
- API security headers

## 📱 Platform Support

| Feature              | Android | 
|---------             |---------|
| Biometric Auth       | ✅     |
| App Lockout          | ✅     |
| Secure Storage       | ✅     |
| Camera Access        | ✅     |
| Device ID            | ✅     |

##  Security Checklist

-  Form validation implemented
-  Secure credential storage
-  Biometric authentication
-  App lockout on pause/quit
-  Device unique ID integration
-  HTTPS/TLS for API calls
-  Code obfuscation enabled
-  Certificate signing configured
-  Sensitive data encryption
-  Session management


### Common Issues

**Biometric Authentication Not Working**
```dart
final bool isAvailable = await BiometricService.isAvailable();
```

**App Not Locking Properly**
- Verify lifecycle state management
- Check AppLockProvider implementation
- Ensure proper state persistence

**Build Issues with Obfuscation**
- Check ProGuard rules configuration
- Verify keep rules for Flutter classes
- Clean and rebuild project

### Debug Commands
```bash
flutter clean && flutter pub get

# Check for issues
flutter doctor

# Analyze code
flutter analyze
```


## signing certificate generation
KeyStore command i have used
& "C:\Program Files\Java\jdk-17\bin\keytool.exe" -genkey -v -keystore "G:\Projects@\Mobile@\ubx_mobile_practical_interview\keystore_file\upload-keystore.jks" -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 -alias upload

keystore password: UBX2025
key password for <upload>: UBX2025

# Obfuscation Setup
  - flutter build apk --release --obfuscate --split-debug-info=build/symbols