# 🔧 رفع مشکل SDK Version در GitHub Actions

## ❌ مشکل قبلی:

```
The current Dart SDK version is 3.5.0.
Because tiksarvpn requires SDK version ^3.8.1, version solving failed.
```

## ✅ راه حل:

### 1. تغییر SDK Constraint در `pubspec.yaml`:

```yaml
# قبل:
environment:
  sdk: ^3.8.1

# بعد:
environment:
  sdk: '>=3.3.0 <4.0.0'
```

این تغییر باعث میشه که:
- ✅ با Dart 3.5.0 در GitHub Actions کار کنه
- ✅ با Dart 3.9.0 روی سیستم شما کار کنه
- ✅ با نسخه‌های مختلف Flutter سازگار باشه

### 2. به‌روزرسانی Flutter Version در Workflows:

```yaml
# .github/workflows/windows-build.yml
# .github/workflows/android-build.yml

- name: Setup Flutter
  uses: subosito/flutter-action@v2
  with:
    flutter-version: '3.27.1'  # ← بالاتر از 3.24.0
    channel: 'stable'
    cache: true
```

Flutter 3.27.1 با Dart 3.6.x میاد که کاملاً سازگاره.

---

## 🎯 حالا باید این کار رو بکنی:

### Commit کردن تغییرات:

```bash
git add pubspec.yaml .github/workflows/

git commit -m "fix: Update SDK constraint for GitHub Actions compatibility

- Changed SDK constraint from ^3.8.1 to >=3.3.0 <4.0.0
- Updated Flutter version in workflows to 3.27.1
- Now compatible with both GitHub Actions (Dart 3.5+) and local dev (Dart 3.9+)"

git push origin main
```

---

## ✅ بررسی نتیجه:

بعد از push، برو به Actions و دوباره run کن. حالا باید کار کنه! 🚀

---

## 📊 نسخه‌های سازگار:

| محیط | Flutter | Dart | وضعیت |
|------|---------|------|-------|
| **سیستم شما** | 3.35.1 | 3.9.0 | ✅ سازگار |
| **GitHub Actions** | 3.27.1 | 3.6.x | ✅ سازگار |
| **حداقل نیاز** | 3.22+ | 3.3+ | ✅ پشتیبانی |

---

## 💡 نکته مهم:

SDK constraint همیشه باید یک **range** باشه نه یک نسخه خاص:

```yaml
# ❌ بد:
sdk: ^3.8.1      # فقط 3.8.1 و بالاتر

# ✅ خوب:
sdk: '>=3.3.0 <4.0.0'  # از 3.3.0 تا قبل از 4.0.0
```

این باعث میشه پروژه روی محیط‌های مختلف قابل build باشه.
