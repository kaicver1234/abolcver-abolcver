# Windows Debug Guide

## چطور خطاها رو ببینیم؟

### روش 1: اجرا از Command Prompt
```cmd
cd path\to\tiksa-vpn - MAIN\build\windows\x64\runner\Release
tiksarvpn.exe
```

### روش 2: اجرا با Flutter
```cmd
flutter run -d windows --release
```

### روش 3: چک کردن Debug Console
1. Build کن با debug mode:
```cmd
flutter build windows --debug
```

2. از Visual Studio Code اجرا کن و Console رو چک کن

## پیغام‌های Debug

برنامه الان Debug logging داره. وقتی اجرا می‌کنی، این پیغام‌ها رو می‌بینی:

```
🚀 Starting Tiksar VPN...
📱 Platform: windows
💻 Desktop platform detected - skipping Firebase
🌐 Initializing language provider...
✅ Language provider initialized
💾 Loading preferences...
✅ Preferences loaded: lang=false, privacy=false
🎨 Launching app...
🏗️ Building MyApp widget...
🎯 Platform: Desktop, NeedsSetup: true
🔧 Creating V2RayProvider...
🌍 Current language: en
📺 Loading WindowsSetupScreen...
✅ Home screen selected, building MaterialApp...
🎨 MaterialApp builder called
🪟 WindowsSetupScreen: initState
🎨 WindowsSetupScreen: build
🌐 Language set to: en
```

## مشکلات رایج

### 1. صفحه سیاه یا UI نمایش داده نمی‌شه
- چک کن که Visual C++ Runtime نصب باشه
- مطمئن شو که .NET Framework 4.7.2+ نصب باشه
- برنامه رو با Admin اجرا کن

### 2. Exception در startup
- Build folder رو پاک کن: `flutter clean`
- دوباره build کن: `flutter build windows --release`

### 3. V2Ray Plugin خطا می‌ده
- این عادیه برای Windows، proxy mode رو امتحان کن

## System Requirements

- Windows 10/11 (x64)
- Visual C++ Redistributable 2015-2022
- .NET Framework 4.7.2 یا بالاتر
- 4 GB RAM
- 500 MB فضای خالی

## Build از Source

```cmd
# 1. Dependencies رو نصب کن
flutter pub get

# 2. Build کن
flutter build windows --release

# 3. فایل خروجی اینجاست:
# build\windows\x64\runner\Release\tiksarvpn.exe
```

## Debug Commands

```cmd
# پاک کردن build cache
flutter clean

# دریافت dependencies جدید
flutter pub get

# اجرا در debug mode
flutter run -d windows

# اجرا در release mode
flutter run -d windows --release

# Build release
flutter build windows --release

# Build debug
flutter build windows --debug
```

## در صورت مشکل

1. فایل build رو پاک کن
2. `flutter clean` اجرا کن
3. `flutter pub get` اجرا کن
4. دوباره build کن
5. اگر باز کار نکرد، Issue بساز با:
   - نسخه Windows
   - نسخه Flutter (`flutter --version`)
   - Debug output کامل
