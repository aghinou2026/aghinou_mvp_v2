# Aghinou Release Checklist

## انجام‌شده در این بسته
- کد اصلی Flutter و اتصال Supabase حفظ شده است.
- ساختار Android موجود حفظ شده است.
- `web/index.html` اضافه شد تا نسخه Web بتواند نشان اینماد را روی دامنه `aghinou.ir` نمایش دهد.
- کد رسمی اینماد ارائه‌شده برای آگهینو بدون تغییر در شناسه و Code قرار گرفت.
- فایل‌های Supabase و تابع پرداخت زرین‌پال حفظ شدند و جدول‌های Profiles، Ads و Ad Images دوباره ساخته نمی‌شوند.

## قبل از انتشار نهایی باید در محیط دارای Flutter انجام شود
1. `flutter pub get`
2. `flutter analyze`
3. `flutter test`
4. `flutter build apk --release`
5. `flutter build web --release`
6. بررسی تنظیمات RLS و Storage در Supabase
7. تنظیم Secretهای Edge Function شامل `ZARINPAL_MERCHANT_ID` و `ZARINPAL_CALLBACK_URL`
8. اجرای یک پرداخت آزمایشی و بررسی callback و ثبت `payments`
9. انتشار نسخه Web روی `aghinou.ir` و بررسی نمایش اینماد

این بسته «نسخه آماده برای تست نهایی» است؛ تا زمانی که دستورات Flutter بالا روی یک محیط واقعی اجرا نشوند، نباید آن را APK نهایی و کاملاً تست‌شده تلقی کرد.


## اصلاحات این مرحله
- [x] جستجو و فیلتر دسته‌بندی در Flutter
- [x] Gate اشتراک در Flutter
- [x] RPC ثبت آگهی با کنترل سمت سرور
- [x] محدودیت ۹ آگهی سمت سرور
- [x] جلوگیری از درج مستقیم payment توسط کاربر
- [ ] اجرای migration امنیتی روی Supabase واقعی
- [ ] احراز هویت واقعی به جای Anonymous
- [ ] تست کامل پرداخت
