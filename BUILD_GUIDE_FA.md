# راهنمای Build برای ویندوز (بدون Visual Studio کامل)

## روش ۱: استفاده از Build Tools (پیشنهادی و سبک‌ترین) ⭐

این روش **فقط ۲-۳ گیگابایت** حجم داره، نه ۲۰ گیگ!

### نصب Build Tools

```powershell
# روش اول: با WinGet (ساده‌ترین)
# PowerShell را به عنوان Administrator باز کنید
winget install Microsoft.VisualStudio.2022.BuildTools --silent --override "--wait --quiet --add ProductLang En-us --add Microsoft.VisualStudio.Workload.VCTools --includeRecommended"

# روش دوم: دانلود دستی
# برو به: https://aka.ms/vs/17/release/vs_BuildTools.exe
# دانلود کن و اجرا کن، سپس در نصب این موارد رو انتخاب کن:
# ✅ Desktop development with C++
# ✅ Windows 10 SDK (یا بالاتر)
```

### بعد از نصب Build Tools

```bash
# بررسی کن که درست نصب شده
flutter doctor -v

# باید ببینی:
# [✓] Visual Studio - develop Windows apps (Visual Studio Build Tools 2022 17.x.x)

# اگه نشد، دستور زیر رو اجرا کن:
flutter config --enable-windows-desktop

# حالا build کن
flutter build windows --release
```

---

## روش ۲: استفاده از GitHub Actions (بدون نصب چیزی روی سیستم خودت) 🚀

این روش اصلا نیازی به نصب چیزی روی سیستمت نداره! GitHub خودش build میکنه.

### مراحل:

#### ۱. ساخت فایل Workflow

فایل زیر رو بساز: `.github/workflows/windows-build.yml`

```yaml
name: Windows Build

on:
  workflow_dispatch:  # اجرای دستی
  push:
    branches: [ main ]
    paths:
      - 'lib/**'
      - 'windows/**'
      - 'pubspec.yaml'

jobs:
  build:
    runs-on: windows-latest
    
    steps:
    - name: Checkout code
      uses: actions/checkout@v3
      
    - name: Setup Flutter
      uses: subosito/flutter-action@v2
      with:
        flutter-version: '3.24.0'
        channel: 'stable'
        
    - name: Enable Windows Desktop
      run: flutter config --enable-windows-desktop
      
    - name: Get dependencies
      run: flutter pub get
      
    - name: Build Windows
      run: flutter build windows --release
      
    - name: Create ZIP
      run: |
        cd build/windows/x64/runner/Release
        Compress-Archive -Path * -DestinationPath ../../../../../TiksarVPN-Windows.zip
      
    - name: Upload artifact
      uses: actions/upload-artifact@v3
      with:
        name: TiksarVPN-Windows
        path: TiksarVPN-Windows.zip
```

#### ۲. استفاده:

1. فایل بالا رو commit و push کن
2. برو به: `GitHub Repository > Actions > Windows Build > Run workflow`
3. منتظر بمون تا build بشه (۵-۱۰ دقیقه)
4. فایل ZIP رو از بخش Artifacts دانلود کن

---

## روش ۳: استفاده از Docker (پیشرفته) 🐳

اگه Docker داری:

```dockerfile
# Dockerfile
FROM cirrusci/flutter:stable

WORKDIR /app
COPY . .

RUN flutter config --enable-windows-desktop
RUN flutter pub get
RUN flutter build windows --release

# خروجی در: build/windows/x64/runner/Release
```

```bash
# Build کردن
docker build -t tiksar-vpn-windows .
docker run -v ${PWD}/build:/app/build tiksar-vpn-windows
```

---

## مقایسه روش‌ها

| روش | حجم نصب | سرعت | سختی | پیشنهاد |
|-----|---------|------|------|---------|
| **Build Tools** | ~3 GB | سریع | آسان | ⭐⭐⭐⭐⭐ |
| **GitHub Actions** | 0 GB | متوسط | خیلی آسان | ⭐⭐⭐⭐⭐ |
| **Visual Studio کامل** | ~20 GB | سریع | آسان | ⭐⭐ |
| **Docker** | ~5 GB | کند | سخت | ⭐⭐ |

---

## ❓ مشکلات رایج

### خطا: Visual Studio not found

```bash
# راه حل 1: نصب Build Tools
winget install Microsoft.VisualStudio.2022.BuildTools

# راه حل 2: اگه Build Tools نصب کردی ولی Flutter نمیبینه:
flutter doctor -v
# مسیر Visual Studio رو پیدا کن و تنظیم کن
```

### خطا: Windows SDK not found

```bash
# دانلود و نصب Windows 10 SDK:
# https://developer.microsoft.com/en-us/windows/downloads/windows-sdk/

# یا در Visual Studio Installer:
# Individual components > Windows 10 SDK (10.0.19041.0 یا بالاتر)
```

### خطا: CMake not found

```bash
# Build Tools باید CMake رو نصب کنه، اگه نکرد:
winget install Kitware.CMake

# یا دانلود دستی:
# https://cmake.org/download/
```

---

## ✅ بررسی نصب صحیح

بعد از نصب Build Tools، این دستور رو بزن:

```bash
flutter doctor -v
```

باید ببینی:

```
[✓] Visual Studio - develop Windows apps (Visual Studio Build Tools 2022 17.x.x)
    • Visual Studio at C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools
    • Visual Studio Build Tools 2022 version 17.x.xxxxx.xxx
    • Windows 10 SDK version 10.0.xxxxx.x
```

اگه این رو دیدی، آمادی! ✅

---

## 🚀 Build نهایی

```bash
# 1. پاک کردن build قبلی
flutter clean

# 2. دریافت dependencies
flutter pub get

# 3. Build برای Windows
flutter build windows --release

# 4. فایل‌های خروجی در:
# build\windows\x64\runner\Release\

# 5. فایل‌های ضروری برای توزیع:
# - tiksarvpn.exe (فایل اصلی)
# - flutter_windows.dll
# - data\ (پوشه)
# - تمام فایل‌های .dll دیگر

# 6. (اختیاری) کپی V2Ray Core
# v2ray.exe رو در کنار tiksarvpn.exe قرار بده
```

---

## 📦 ساخت Installer (اختیاری)

### با Inno Setup (رایگان و آسان)

1. نصب Inno Setup: https://jrsoftware.org/isdl.php
2. فایل `installer.iss` بساز:

```iss
#define MyAppName "Tiksar VPN"
#define MyAppVersion "1.1.1"
#define MyAppPublisher "Tiksar VPN Team"
#define MyAppExeName "tiksarvpn.exe"

[Setup]
AppId={{YOUR-GUID-HERE}}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
DefaultDirName={autopf}\{#MyAppName}
DefaultGroupName={#MyAppName}
OutputDir=installer_output
OutputBaseFilename=TiksarVPN-Setup-{#MyAppVersion}
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
ArchitecturesAllowed=x64
ArchitecturesInstallIn64BitMode=x64

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"
Name: "farsi"; MessagesFile: "compiler:Languages\Farsi.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}";

[Files]
Source: "build\windows\x64\runner\Release\{#MyAppExeName}"; DestDir: "{app}"; Flags: ignoreversion
Source: "build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs
; اگه v2ray.exe داری:
; Source: "v2ray.exe"; DestDir: "{app}"; Flags: ignoreversion

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent
```

3. Compile کردن:
```bash
iscc installer.iss
```

---

## 💡 نکات مهم

1. **حجم کم**: Build Tools فقط ۲-۳ گیگ حجم داره، Visual Studio کامل ۲۰+ گیگ
2. **بدون نصب**: GitHub Actions اصلا نیازی به نصب ندارن
3. **سرعت**: Build Tools به اندازه Visual Studio کامل سریعه
4. **رایگان**: همه روش‌ها کاملا رایگان هستن

---

## 🎯 خلاصه (برای عجله‌ای‌ها)

**سریع‌ترین راه:**

```powershell
# 1. نصب Build Tools (فقط یک بار)
winget install Microsoft.VisualStudio.2022.BuildTools --silent --override "--wait --quiet --add Microsoft.VisualStudio.Workload.VCTools --includeRecommended"

# 2. بررسی
flutter doctor

# 3. Build
flutter build windows --release

# 4. فایل‌ها در: build\windows\x64\runner\Release\
```

**بدون نصب (GitHub Actions):**
- فایل workflow رو بساز
- Push کن
- منتظر build بمون
- دانلود کن

تمام! 🎉
