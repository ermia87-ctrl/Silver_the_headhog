# گزارش شناسایی نوشته‌های Sonic 1 برای فارسی‌سازی

این گزارش از تطبیق ساختار ROM ارسالی با disassembly عمومی Sonic 1 (شاخه AS) تهیه شده است. هیچ بایت ROM در این مرحله تغییر نمی‌کند.

## نتیجهٔ شناسایی

نوشته‌های بازی یک رشتهٔ متنی ساده و یک‌جا نیستند؛ بخش مهمی از آن‌ها به شکل تصویر/کاشی گرافیکی (tile) و جدول چیدمان sprite ذخیره شده‌اند. بنابراین جایگزینی متن ASCII به‌تنهایی ترجمهٔ بازی را انجام نمی‌دهد.

موارد شناسایی‌شده در منبع disassembly:

| نوشته/بخش | محل نمایش | منبع مرتبط |
|---|---|---|
| PRESS START BUTTON | صفحهٔ عنوان | `_incObj/0E, 0F Title Screen - Sonic, Press Start, TM.asm`, `_maps/Press Start and TM.asm`, گرافیک `artnem/Title Screen Foreground.nem` |
| SONIC TEAM PRESENTS | پیش از صفحهٔ عنوان | `_incObj/8A Credits and Sonic Team Presents.asm`, `_maps/Credits.asm` |
| نوشته‌های تیتراژ و TRY AGAIN | پایان/صفحهٔ ادامه | `_maps/Credits.asm`, گرافیک `artnem/Ending - Credits.nem` |
| Level Select و Debug | منوی انتخاب مرحله/حالت دیباگ | گرافیک `artunc/Level Select & Debug Text.unc` |
| نوشته‌های HUD | داخل مرحله (SCORE/TIME/RINGS و اعداد) | `_maps/HUD.asm`, `artnem/HUD.nem` |

## ترتیب درست پیاده‌سازی

1. تأیید revision دقیق ROM با checksum هدر.
2. استخراج و بازکردن گرافیک‌های فشردهٔ Nemesis/Kosinski از محل‌های مشخص‌شده.
3. ساخت فونت فارسی پیکسلی با اندازه و پالت سازگار با بازی.
4. بازطراحی tileها و جدول‌های sprite/map برای هر رشته؛ در صورت نیاز اصلاح کد رسم برای جهت راست‌به‌چپ.
5. ساخت ROM آزمایشی و مقایسهٔ checksum/اندازه، سپس تست صفحهٔ عنوان، HUD، انتخاب مرحله و تیتراژ.

## محدودیت فعلی

تا وقتی فونت فارسی، داده‌های فشرده و جدول‌های چیدمان به‌درستی بازسازی نشده‌اند، ساخت یک ROM فارسیِ قابل اجرا قابل ادعا نیست. این مرحله فقط شناسایی نقاط متنی است؛ هنوز patch فارسی تولید نشده است.

منبع ساختاری: https://github.com/sonicretro/s1disasm/tree/AS
