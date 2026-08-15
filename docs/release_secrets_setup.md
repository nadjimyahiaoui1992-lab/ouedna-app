# إعداد أسرار إصدار Ouedna Android

يتطلب نشر APK موقّع لتحديث التطبيق المثبت لدى الجمهور أسرار GitHub Actions التالية. لا تُرسل هذه القيم في المحادثة ولا تضعها داخل ملفات المشروع.

| اسم السر | الغرض |
|---|---|
| `ANDROID_KEYSTORE_BASE64` | محتوى ملف keystore الخاص بالإصدار بعد ترميزه Base64 في سطر واحد. |
| `ANDROID_KEY_ALIAS` | اسم المفتاح داخل keystore. |
| `ANDROID_KEY_PASSWORD` | كلمة مرور المفتاح. |
| `ANDROID_STORE_PASSWORD` | كلمة مرور keystore. |
| `GOOGLE_SERVICES_JSON_BASE64` | ملف `google-services.json` بعد ترميزه Base64 في سطر واحد. |
| `SUPABASE_URL` | عنوان مشروع Supabase الإنتاجي. |
| `SUPABASE_PUBLISHABLE_KEY` | المفتاح العام المنشور لمشروع Supabase. |

## من الهاتف عبر Termux

احفظ ملف keystore وملف `google-services.json` محلياً فقط، ثم أنشئ النصين Base64 من دون طبعات أسطر:

```bash
base64 -w 0 /المسار/إلى/ouedna-release.jks > keystore-base64.txt
base64 -w 0 /المسار/إلى/google-services.json > firebase-base64.txt
```

انسخ محتوى كل ملف إلى السر الذي يقابله في GitHub. لا ترفع الملفين إلى المستودع.

## في GitHub

افتح مستودع `ouedna-app`، ثم ادخل إلى **Settings → Secrets and variables → Actions → New repository secret**. أضف الأسرار السبعة بالاسم المطابق تماماً للجدول. بعد الحفظ، لا يظهر GitHub قيم الأسرار مرة أخرى؛ هذا طبيعي.

بعد اكتمال الإعداد، شغّل workflow باسم **Publish Android release** يدوياً مع الوسم `v2.1.0`. سيبني workflow ملفات APK المباشرة الموقعة لكل من `arm64-v8a` و`armeabi-v7a`، ويتحقق من توقيعها، ثم ينشرها في GitHub Release.
