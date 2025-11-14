# نحوه استفاده از GitHub Actions برای Build ویندوز

## مزایا
- ✅ هیچ نیازی به نصب Visual Studio یا Build Tools نیست
- ✅ کاملا رایگان (۲۰۰۰ دقیقه رایگان در ماه برای repo های public)
- ✅ همیشه آخرین نسخه Flutter
- ✅ Build تمیز و بدون مشکل
- ✅ قابل دانلود برای همه

## مراحل استفاده

### روش 1: اجرای دستی (Manual Trigger)

1. برو به مخزن GitHub خودت
2. کلیک روی تب **Actions**
3. از لیست سمت چپ، انتخاب کن: **Build Windows Release**
4. کلیک روی **Run workflow** (دکمه سمت راست)
5. انتخاب branch (معمولا `main`)
6. کلیک روی **Run workflow** (دکمه سبز)

### روش 2: خودکار (Auto Trigger)

هر بار که تغییری در این فایل‌ها push میکنی، خودکار build میشه:
- `lib/**` (کدهای Dart)
- `windows/**` (کدهای Windows)
- `local_packages/**` (پلاگین‌ها)
- `pubspec.yaml`

### روش 3: با Tag (Release)

```bash
# برای ساخت release رسمی:
git tag -a v1.1.1 -m "Release version 1.1.1"
git push origin v1.1.1
```

این کار یک Release رسمی در GitHub میسازه و فایل ZIP رو بهش attach میکنه.

## دریافت فایل Build شده

### بعد از Build موفق:

1. برو به تب **Actions**
2. کلیک روی آخرین workflow اجرا شده (تیک سبز ✅)
3. اسکرول به پایین تا برسی به **Artifacts**
4. دو فایل میبینی:
   - **TiksarVPN-Windows-v1.1.1.zip** - فایل فشرده کامل (پیشنهادی)
   - **TiksarVPN-Windows-Release-Files** - فایل‌های جداگانه
5. دانلود کن و استخراج کن

## ساختار فایل دانلود شده

```
TiksarVPN-Windows-v1.1.1.zip
├── tiksarvpn.exe           # فایل اصلی برنامه
├── flutter_windows.dll     # کتابخانه Flutter
├── data/                   # داده‌های Flutter
│   └── flutter_assets/     # asset ها
├── *.dll                   # کتابخانه‌های Windows
└── BUILD_INFO.txt          # اطلاعات Build
```

## اجرای برنامه

1. استخراج ZIP
2. اجرای `tiksarvpn.exe`
3. (اختیاری) اگر V2Ray نیاز داری، `v2ray.exe` رو در همون پوشه قرار بده

## تنظیمات Workflow (پیشرفته)

### تغییر نسخه Flutter

در فایل `.github/workflows/windows-build.yml`:

```yaml
flutter-version: '3.24.0'  # نسخه مورد نظر
```

### تغییر Retention Days

```yaml
retention-days: 30  # تعداد روز نگهداری فایل (حداکثر ۹۰)
```

### غیرفعال کردن Analyze

اگر میخوای analyze نشه:

```yaml
- name: Analyze code
  run: flutter analyze
  continue-on-error: true  # این خط رو حذف کن تا اگه error بود، build نشه
```

## ایجاد Release خودکار

### 1. فعال‌سازی GitHub Releases

فایل workflow از قبل آمادست. فقط باید tag بزنی:

```bash
# ساخت tag جدید
git tag -a v1.1.2 -m "نسخه 1.1.2 - اضافه شدن ..."

# push tag
git push origin v1.1.2
```

### 2. Release یدستی

اگه خواستی یدستی release بسازی:

1. برو به **Releases** در GitHub
2. کلیک **Draft a new release**
3. انتخاب tag
4. آپلود فایل ZIP
5. نوشتن Release Notes
6. انتشار

## مشکلات رایج و راه‌حل

### Build ناموفق (Failed)

1. برو به Actions > workflow ناموفق
2. کلیک روی job که fail شده
3. باز کردن step هایی که error دارن
4. خوندن error message
5. رفع مشکل و push مجدد

### مشکلات رایج:

#### خطای Dependencies
```bash
# معمولا مربوط به pubspec.yaml
# بررسی کن که syntax درست باشه
```

#### خطای Windows Build
```bash
# معمولا مربوط به کدهای C++ در windows/ یا پلاگین‌ها
# بررسی CMakeLists.txt و فایل‌های .cpp
```

#### خطای Analyze
```bash
# میتونی continue-on-error: true رو حذف کنی
# یا مشکلات analyze رو رفع کنی
```

## محدودیت‌ها

### GitHub Free Plan:
- ۲۰۰۰ دقیقه رایگان در ماه
- هر build معمولا ۵-۱۰ دقیقه طول میکشه
- یعنی میتونی ~۲۰۰ build در ماه داشته باشی

### Private Repository:
- برای repo های خصوصی، محدودیت کمتره
- اما برای public، ۲۰۰۰ دقیقه کافیه

## بهینه‌سازی

### کم کردن زمان Build:

1. **فعال کردن Cache:**
```yaml
- uses: subosito/flutter-action@v2
  with:
    cache: true  # ✅ این خط رو اضافه کن
```

2. **Build فقط برای تغییرات خاص:**
```yaml
on:
  push:
    paths:
      - 'lib/**'      # فقط برای تغییرات کد
      - 'windows/**'   # فقط برای تغییرات Windows
```

## Secrets (برای قابلیت‌های پیشرفته)

اگه نیاز به signing یا API keys داشتی:

1. برو به **Settings** > **Secrets and variables** > **Actions**
2. کلیک **New repository secret**
3. اضافه کردن secret (مثلا `SIGNING_KEY`)
4. استفاده در workflow:

```yaml
env:
  MY_SECRET: ${{ secrets.SIGNING_KEY }}
```

## خلاصه

**مزایا:**
- ✅ هیچ نیازی به نصب چیزی روی سیستم خودت
- ✅ Build تمیز و استاندارد
- ✅ قابل اشتراک‌گذاری آسان
- ✅ رایگان

**مراحل:**
1. Push کد به GitHub
2. رفتن به Actions
3. اجرای workflow
4. دانلود artifact

**تمام!** 🎉
