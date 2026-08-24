# راه‌اندازی پرداخت واقعی آگهینو

درگاه انتخاب‌شده: ZarinPal REST API v4.

## 1) ساخت جدول
فایل `Aghinou_payments.sql` را در Supabase SQL Editor اجرا کن.

## 2) ساخت Edge Function
فایل `zarinpal-payment/index.ts` را به عنوان Edge Function با نام:
`zarinpal-payment`
قرار بده.

## 3) Secretهای لازم در Supabase
این Secret را تنظیم کن:
- `ZARINPAL_MERCHANT_ID` = Merchant ID واقعی حساب پذیرنده

این مقدار اختیاری است ولی بهتر است صریحاً تنظیم شود:
- `ZARINPAL_CALLBACK_URL` =
  `https://<PROJECT-REF>.supabase.co/functions/v1/zarinpal-payment`

Supabase خودش `SUPABASE_URL`, `SUPABASE_ANON_KEY` و `SUPABASE_SERVICE_ROLE_KEY` را برای Edge Function فراهم می‌کند.

## 4) نکته مبلغ
اشتراک 35,000 تومان در این پیاده‌سازی به صورت 350,000 ریال ارسال می‌شود.

## 5) روند پرداخت
Flutter -> Edge Function -> ZarinPal -> Callback -> Verify -> payments.paid

Merchant ID نباید داخل Flutter یا GitHub قرار بگیرد.

منابع API:
- نمونه رسمی/سازمانی ZarinPal REST API: https://github.com/ZarinPal-Lab/Zarinpal-RestAPI-Sample-php
- API v4 request: https://api.zarinpal.com/pg/v4/payment/request.json
- API v4 verify: https://api.zarinpal.com/pg/v4/payment/verify.json


## 6) اعمال محدودیت سمت سرور
پس از ساخت جدول پرداخت، فایل `Aghinou_PRODUCTION_HARDENING.sql` را اجرا کنید.
این فایل:
- ثبت آگهی را به اشتراک پرداخت‌شده و منقضی‌نشده وابسته می‌کند.
- سقف ۹ آگهی را در سمت سرور اعمال می‌کند.
- درج مستقیم payment توسط کاربر را نمی‌دهد.
- ایندکس‌های لازم برای بررسی اشتراک و تعداد آگهی را اضافه می‌کند.

این migration را بعد از بررسی ساختار واقعی جدول `ads` اجرا کنید.
