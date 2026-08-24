# آگهینو — Production Ready v4

نسخه یکپارچه آگهینو بر پایه کد MASTER موجود.

## وضعیت
- Flutter app code: موجود
- Supabase + ZarinPal files: موجود
- Android host structure: موجود
- Web host structure: موجود
- نماد اعتماد الکترونیکی: کد رسمی ارائه‌شده برای `aghinou.ir` در `web/index.html` قرار گرفت.
- تست نهایی Flutter/Android/Web باید روی محیط دارای Flutter SDK انجام شود.

## Supabase
ساختار موجود Profiles، Ads و Ad Images حفظ شده و دوباره ساخته نشده است.
قبل از انتشار عمومی، RLS، Storage Policies و Secretهای Edge Function را بررسی کنید.


## اصلاحات Production در این نسخه
- جستجوی واقعی در فهرست آگهی‌ها و فیلتر دسته‌بندی اضافه شد.
- ثبت آگهی در رابط کاربری به اشتراک فعال وابسته شد.
- مسیر ثبت آگهی از RPC امن `publish_ad` عبور می‌کند تا اشتراک و سقف ۹ آگهی سمت سرور نیز اعمال شود.
- منطق نمایش وضعیت اشتراک به‌روزرسانی شد.
- Migration امنیتی `supabase/Aghinou_PRODUCTION_HARDENING.sql` اضافه شد.

## مواردی که هنوز نیازمند سرویس/محیط واقعی هستند
- احراز هویت واقعی کاربر (OTP/ایمیل) و تنظیمات Provider
- اجرای migration روی پروژه واقعی Supabase
- بررسی RLS و Storage Policies و اصلاح ناسازگاری نام Bucket
- تست واقعی درگاه و callback
- `flutter analyze`, `flutter test`, `flutter build apk --release`, `flutter build web --release` (محیط Flutter در دسترس این جلسه نیست)
- امضای Android و انتشار Web


## اصلاحات دور سوم
- ورود با OTP ایمیلی جایگزین ورود Anonymous شد؛ پس از فعال بودن Email OTP در Supabase، کاربر با کد یک‌بارمصرف وارد می‌شود.
- پرداخت Edge Function برای وب CORS دارد و کاربر anonymous را از ایجاد پرداخت مسدود می‌کند.
- تمدید اشتراک بر اساس بیشترین انقضای فعال کاربر محاسبه می‌شود.
- RLS برای Ads و Ad Images به‌صراحت فعال شد و مدیریت آگهی فقط برای مالک مجاز است.
- پاک‌سازی آگهی در صورت شکست آپلود تصویر اکنون با policy مالکیت سازگار است.
- تصاویر اولین آگهی در فهرست آگهی‌ها نمایش داده می‌شوند.
