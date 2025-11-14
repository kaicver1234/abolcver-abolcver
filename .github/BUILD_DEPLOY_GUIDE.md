# راهنمای کامل Build و Deploy

## 🚀 Build روی GitHub Actions (بدون نصب چیزی)

### برای Windows:

1. برو به: `https://github.com/YOUR_USERNAME/YOUR_REPO/actions`
2. از منوی سمت چپ انتخاب کن: **Build Windows Release**
3. کلیک **Run workflow** > انتخاب branch `main` > **Run workflow**
4. منتظر بمون 5-10 دقیقه
5. بعد از تموم شدن، برو به اون workflow
6. اسکرول به پایین تا **Artifacts**
7. دانلود کن: **TiksarVPN-Windows-v1.1.1.zip**

### برای Android:

1. برو به: `https://github.com/YOUR_USERNAME/YOUR_REPO/actions`
2. از منوی سمت چپ انتخاب کن: **Build Android Release**
3. کلیک **Run workflow** > انتخاب branch `main` > **Run workflow**
4. منتظر بمون 3-5 دقیقه
5. بعد از تموم شدن، دو artifact خواهی داشت:
   - **TiksarVPN-Android-APKs-v1.1.1**: فایل‌های APK برای نصب مستقیم
   - **TiksarVPN-Android-AAB-v1.1.1**: فایل AAB برای Google Play

---

## 📱 فایل‌های Android

### APK Files:
- **arm64-v8a.apk** ← برای گوشی‌های جدید (64-bit) - **پیشنهادی** ✅
- **armeabi-v7a.apk** ← برای گوشی‌های قدیمی (32-bit)
- **x86_64.apk** ← برای دستگاه‌های x86 (نادر)

### AAB File:
- **app-release.aab** ← برای آپلود به Google Play Store

**توصیه:** اگه میخوای خودت نصب کنی، فایل **arm64-v8a.apk** رو دانلود کن.

---

## 💻 فایل‌های Windows

### فایل ZIP شامل:
- `tiksarvpn.exe` - فایل اصلی برنامه
- `flutter_windows.dll` - کتابخانه Flutter
- `data/` - Asset های برنامه
- سایر DLL ها

### نیاز داره:
- **V2Ray Core**: دانلود از [v2fly/v2ray-core releases](https://github.com/v2fly/v2ray-core/releases)
- فایل `v2ray.exe` رو در کنار `tiksarvpn.exe` قرار بده

---

## 🏷️ ساخت Release رسمی

### مرحله 1: ساخت Tag
```bash
# نسخه جدید مثلاً 1.1.2
git tag -a v1.1.2 -m "Release version 1.1.2 - اضافه شدن ..."
git push origin v1.1.2
```

### مرحله 2: خودکار!
- GitHub Actions خودکار اجرا میشه
- Build میکنه برای Windows و Android
- یک Release رسمی میسازه
- فایل‌ها رو attach میکنه

### مرحله 3: دانلود
- برو به: `https://github.com/YOUR_USERNAME/YOUR_REPO/releases`
- آخرین release رو ببین
- فایل‌ها رو دانلود کن

---

## 🔧 Build روی سیستم خودت (اختیاری)

### Android:
```bash
# APK برای نصب مستقیم
flutter build apk --release --split-per-abi

# AAB برای Google Play
flutter build appbundle --release

# فایل‌ها در:
# build/app/outputs/flutter-apk/
# build/app/outputs/bundle/release/
```

### Windows:
```bash
# نیاز به Visual Studio Build Tools

# Build
flutter build windows --release

# فایل‌ها در:
# build/windows/x64/runner/Release/
```

---

## 📊 مقایسه روش‌های Build

| روش | حجم نصب | زمان | سختی | توصیه |
|-----|---------|------|------|-------|
| **GitHub Actions** | 0 GB | 5-10 دقیقه | خیلی آسان | ⭐⭐⭐⭐⭐ |
| **Build Tools (Windows)** | 3 GB | 2 دقیقه | آسان | ⭐⭐⭐⭐ |
| **Android Studio** | 5+ GB | 2 دقیقه | متوسط | ⭐⭐⭐ |
| **Visual Studio (Windows)** | 20+ GB | 2 دقیقه | آسان | ⭐⭐ |

---

## 🎯 Workflow Status

### چک کردن وضعیت Build:

1. برو به: **Actions** tab در GitHub
2. ببین آخرین workflow چه وضعیتی داره:
   - ✅ سبز = موفق
   - ❌ قرمز = ناموفق
   - 🟡 زرد = در حال اجرا

3. کلیک روی workflow برای دیدن جزئیات

### اگر build ناموفق بود:

1. کلیک روی workflow قرمز
2. کلیک روی job که fail شده
3. باز کردن step هایی که error دارن
4. خوندن error و رفع مشکل
5. Push کردن fix
6. دوباره run workflow

---

## 🔐 امضای دیجیتال (اختیاری)

### Android Signing:

برای upload به Google Play نیاز به signing داری:

1. ساخت keystore:
```bash
keytool -genkey -v -keystore tiksar-release-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias tiksar
```

2. اضافه کردن به GitHub Secrets:
   - `KEYSTORE_BASE64` - keystore به base64
   - `KEY_ALIAS` - tiksar
   - `KEY_PASSWORD` - پسورد key
   - `STORE_PASSWORD` - پسورد keystore

3. Workflow خودکار sign میکنه

### Windows Signing:

برای signing در Windows نیاز به Certificate داری:
- میتونی از DigiCert یا Comodo خریداری کنی
- یا self-signed certificate بسازی (برای testing)

---

## ❓ سوالات متداول

### Q: چرا GitHub Actions رایگانه؟
A: برای repository های public، 2000 دقیقه در ماه رایگان هست.

### Q: چند وقت طول میکشه؟
A: 
- Android: 3-5 دقیقه
- Windows: 5-10 دقیقه

### Q: فایل‌ها چقدر نگه داشته میشن?
A: 
- APK: 30 روز
- AAB: 90 روز
- Windows ZIP: 30 روز

### Q: میتونم به صورت خودکار به Play Store آپلود کنم؟
A: بله! با اضافه کردن این action:
```yaml
- uses: r0adkll/upload-google-play@v1
```

### Q: چطور نسخه رو عوض کنم؟
A: فایل `pubspec.yaml` رو ویرایش کن:
```yaml
version: 1.1.2+7  # version+buildNumber
```

---

## 🎉 خلاصه

**برای build:**
1. Push کن
2. برو Actions
3. Run workflow
4. منتظر بمون
5. دانلود کن

**همین!** 🚀
