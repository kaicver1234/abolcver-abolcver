# Tiksar VPN - Windows Desktop Version 🚀

<div align="center">

![Tiksar VPN](assets/images/apk.png)

**نسخه دسکتاپ ویندوز برای Tiksar VPN**
کلاینت VPN مدرن، امن و سریع برای ویندوز

[فارسی](#فارسی) • [English](#english)

</div>

---

## فارسی

### ✨ ویژگی‌ها

- 🎨 **رابط کاربری مدرن**: طراحی بهینه‌شده برای دسکتاپ
- 🌐 **پشتیبانی کامل از فارسی**: رابط کاربری RTL
- 🔒 **امنیت بالا**: رمزنگاری AES-256
- ⚡ **سرعت بالا**: بهینه‌سازی شده برای ویندوز
- 📊 **آمار لحظه‌ای**: نمایش سرعت و مصرف ترافیک
- 🛠 **ابزارهای کاربردی**: تست سرعت، بررسی IP، Host Checker

### 🎯 پیش‌نیازها

برای کامپایل نسخه ویندوز، موارد زیر مورد نیاز است:

1. **Flutter SDK** (نسخه 3.35.1 یا بالاتر)
2. **Visual Studio 2019/2022** یا **Visual Studio Build Tools**
3. **Git for Windows**

### 🔧 نصب Visual Studio

#### گزینه 1: Visual Studio Community (پیشنهادی)
```bash
# دانلود از سایت رسمی
https://visualstudio.microsoft.com/vs/community/

# در زمان نصب، Workload زیر را انتخاب کنید:
✅ Desktop development with C++
```

#### گزینه 2: Visual Studio Build Tools
```bash
# دانلود Build Tools
https://visualstudio.microsoft.com/downloads/#build-tools-for-visual-studio-2022

# اجرای دستور از PowerShell (به عنوان Administrator):
winget install Microsoft.VisualStudio.2022.BuildTools
```

### 🚀 راه‌اندازی پروژه

```bash
# کلون پروژه
git clone <repository-url>
cd tiksa-vpn-MAIN

# بررسی Flutter Doctor
flutter doctor

# باید نتیجه زیر را ببینید:
# [✓] Visual Studio - develop Windows apps

# دریافت وابستگی‌ها
flutter pub get

# اجرا در حالت debug
flutter run -d windows

# ساخت نسخه release
flutter build windows --release
```

### 📁 ساختار فایل‌های مهم

```
lib/
├── utils/
│   └── platform_utils.dart          # کتابخانه تشخیص پلتفرم
├── widgets/
│   └── desktop_layout.dart          # کامپوننت‌های دسکتاپ
├── screens/
│   ├── desktop_home_screen.dart     # صفحه اصلی دسکتاپ
│   └── main_navigation_screen.dart  # مسیریابی پلتفرم
└── main.dart                        # فایل اصلی (بهینه شده برای ویندوز)

local_packages/flutter_v2ray/
└── windows/                         # پلاگین V2Ray برای ویندوز
    ├── CMakeLists.txt
    ├── flutter_v2ray_plugin.cpp
    └── include/

windows/                             # تنظیمات ویندوز Flutter
├── runner/
│   ├── main.cpp                     # Entry point
│   └── Runner.rc                    # منابع ویندوز
└── CMakeLists.txt
```

### 🎨 ویژگی‌های رابط کاربری دسکتاپ

- **Layout دو ستونه**: پنل اصلی + sidebar اطلاعات
- **آمار لحظه‌ای**: سرعت آپلود/دانلود، مدت اتصال
- **دسترسی سریع**: تست سرعت، اطلاعات IP، Host Checker
- **تطبیق با تم ویندوز**: حالت Dark/Light
- **پشتیبانی RTL**: برای زبان فارسی

### 🔧 عیب‌یابی

#### خطای Visual Studio Toolchain
```bash
# بررسی نصب Visual Studio
flutter doctor -v

# در صورت خطا، مراحل زیر را انجام دهید:
1. Visual Studio را مجدداً نصب کنید
2. Workload "Desktop development with C++" را اضافه کنید
3. Windows 10/11 SDK را نصب کنید
```

#### خطای Firebase (دسکتاپ)
```bash
# Firebase فقط برای موبایل فعال است
# در ویندوز به صورت خودکار غیرفعال می‌شود
```

### 📦 ساخت Installer

```bash
# 1. ساخت نسخه release
flutter build windows --release

# 2. فایل‌های خروجی در:
build/windows/x64/runner/Release/

# 3. برای ساخت installer از NSIS یا Inno Setup استفاده کنید
```

---

## English

### ✨ Features

- 🎨 **Modern Desktop UI**: Optimized design for desktop experience
- 🌐 **Full Persian Support**: RTL interface support
- 🔒 **High Security**: AES-256 encryption
- ⚡ **High Performance**: Windows-optimized performance
- 📊 **Real-time Stats**: Live speed and traffic monitoring
- 🛠 **Utility Tools**: Speed test, IP checker, Host checker

### 🎯 Prerequisites

To build the Windows version, you need:

1. **Flutter SDK** (version 3.35.1 or higher)
2. **Visual Studio 2019/2022** or **Visual Studio Build Tools**
3. **Git for Windows**

### 🔧 Visual Studio Installation

#### Option 1: Visual Studio Community (Recommended)
```bash
# Download from official site
https://visualstudio.microsoft.com/vs/community/

# During installation, select this workload:
✅ Desktop development with C++
```

#### Option 2: Visual Studio Build Tools
```bash
# Download Build Tools
https://visualstudio.microsoft.com/downloads/#build-tools-for-visual-studio-2022

# Run from PowerShell (as Administrator):
winget install Microsoft.VisualStudio.2022.BuildTools
```

### 🚀 Project Setup

```bash
# Clone the project
git clone <repository-url>
cd tiksa-vpn-MAIN

# Check Flutter Doctor
flutter doctor

# You should see:
# [✓] Visual Studio - develop Windows apps

# Get dependencies
flutter pub get

# Run in debug mode
flutter run -d windows

# Build release version
flutter build windows --release
```

### 📁 Important File Structure

```
lib/
├── utils/
│   └── platform_utils.dart          # Platform detection utilities
├── widgets/
│   └── desktop_layout.dart          # Desktop UI components
├── screens/
│   ├── desktop_home_screen.dart     # Main desktop interface
│   └── main_navigation_screen.dart  # Platform routing
└── main.dart                        # Main entry (Windows-optimized)

local_packages/flutter_v2ray/
└── windows/                         # V2Ray plugin for Windows
    ├── CMakeLists.txt
    ├── flutter_v2ray_plugin.cpp
    └── include/

windows/                             # Flutter Windows configuration
├── runner/
│   ├── main.cpp                     # Entry point
│   └── Runner.rc                    # Windows resources
└── CMakeLists.txt
```

### 🎨 Desktop UI Features

- **Two-column Layout**: Main panel + info sidebar
- **Real-time Stats**: Upload/download speeds, connection duration
- **Quick Access**: Speed test, IP info, Host checker
- **Windows Theme Integration**: Dark/Light mode support
- **RTL Support**: For Persian language

### 🔧 Troubleshooting

#### Visual Studio Toolchain Error
```bash
# Check Visual Studio installation
flutter doctor -v

# If error occurs, follow these steps:
1. Reinstall Visual Studio
2. Add "Desktop development with C++" workload
3. Install Windows 10/11 SDK
```

#### Firebase Error (Desktop)
```bash
# Firebase is mobile-only
# Automatically disabled on Windows
```

### 📦 Building Installer

```bash
# 1. Build release version
flutter build windows --release

# 2. Output files in:
build/windows/x64/runner/Release/

# 3. Use NSIS or Inno Setup to create installer
```

---

## 📞 پشتیبانی / Support

- **Telegram**: [@TiksarVPN](https://t.me/TiksarVPN)
- **Issues**: GitHub Issues
- **Documentation**: [Wiki](wiki-link)

---

**© 2025 Tiksar VPN - نسخه ویندوز با ❤️ ساخته شده**
