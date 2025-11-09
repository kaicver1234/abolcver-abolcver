# سیستم سرور Tiksar VPN

## خلاصه

این برنامه دو منبع سرور دارد که کاربر میتونه بینشون انتخاب کنه:

### 🧠 Tiksar Smart (پیش‌فرض)
- **منبع:** DXcore (کتابخونه Native)
- **پروتکل‌ها:** XRAY, OUTLINE, PSIPHON, WARP, GOOL, SERVERLESS  
- **ویژگی:** انتخاب خودکار پروتکل بر اساس شرایط شبکه
- **مناسب برای:** دور زدن سانسور و فیلترشکن‌های پیشرفته

### ⚡ Tiksar Plus
- **منبع:** GitHub Repository
- **URL:** `https://raw.githubusercontent.com/cverhud/v2ray-sub/refs/heads/main/sub.txt`
- **پروتکل‌ها:** vmess, vless, shadowsocks, trojan
- **ویژگی:** سرورهای پرسرعت استاندارد V2Ray
- **مناسب برای:** سرعت بالا و اتصال پایدار

## ساختار

```
User Opens App
      ↓
Always in Auto Mode
      ↓
Select Source:
  ├─ Tiksar Smart (DXcore)
  └─ Tiksar Plus (GitHub)
      ↓
Connect → Works!
```

## فایل‌های کلیدی

- **`lib/services/tiksar_plus_service.dart`**: مدیریت دو منبع سرور
- **`lib/services/dxcore_service.dart`**: ارتباط با DXcore
- **`lib/providers/v2ray_provider.dart`**: مدیریت وضعیت
- **`lib/widgets/server_source_selector.dart`**: UI انتخاب منبع
- **`android/app/libs/DXcore.aar`**: کتابخونه DXcore Mock

## نکات مهم

1. **Auto Mode همیشه فعاله** - کاربر فقط بین Smart و Plus انتخاب میکنه
2. **سرورهای دستی حذف شدن** - کاربر نمیتونه subscription اضافه کنه
3. **DXcore یه Mock هست** - برای استفاده واقعی باید کد production رو دریافت کنی
4. **انتخاب ذخیره میشه** - SharedPreferences با key: `server_source`

## DXcore Info

DXcore یک پروژه Closed-Source هست:
- کد واقعیش منتشر نمیشه (برای امنیت)
- فقط Mock برای developers وجود داره
- دانلود: https://github.com/UnboundTechCo/DXcore/releases

## TODO

در فایل `DXcoreMethodChannel.kt` جاهایی با `// TODO` مشخص شدن که باید کد واقعی DXcore رو پیاده کنی.
