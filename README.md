# ubx_practical_mobile

A new Flutter project.

## THIS APP CONTAINS PAGES AND DESIGNS AS REQUIRED ON TASKS


1: Login and Register Page

2: Profile Page

3: Biometric Authentication

4: App Lockout

5: Device Unique ID





KeyStore command i have used
& "C:\Program Files\Java\jdk-17\bin\keytool.exe" -genkey -v -keystore "G:\Projects@\Mobile@\ubx_mobile_practical_interview\keystore_file\upload-keystore.jks" -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 -alias upload

keystore password: UBX2025
key password for <upload>: UBX2025

# Obfuscation Setup
  - flutter build appbundle --release --obfuscate --split-debug-info=build/app/outputs/symbols
  - flutter build apk --release --obfuscate --split-debug-info=build/app/outputs/symbols