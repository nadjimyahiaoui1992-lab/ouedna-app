# توقيع Souf 360 للإصدار على Google Play

إعدادات Gradle في المشروع تمنع الآن أي استخدام صامت لشهادة Android Debug في إصدار `release`. بقيت **مادة التوقيع** خارج المستودع وضمن مسؤولية مالك المشروع؛ وهي لا تُرسل عبر المحادثة أو GitHub.

## 1. إنشاء أو استعادة مفتاح الرفع

إذا لم يكن لديك مفتاح رفع سابق، أنشئه محلياً على جهاز موثوق واحتفظ بنسخة مشفّرة منه خارج المشروع:

```bash
keytool -genkeypair -v \
  -keystore android/app/upload-keystore.jks \
  -alias souf360-upload \
  -keyalg RSA -keysize 4096 -validity 10000
```

> إذا كان تطبيق Souf 360 منشوراً بالفعل، يجب استخدام **نفس** مفتاح الرفع المسجّل في Play Console، ولا يجوز إنشاء مفتاح بديل إلا عبر إجراء إعادة ضبط مفتاح الرفع في Google Play.

## 2. إنشاء `android/key.properties`

أنشئ الملف محلياً فقط؛ يحظره `.gitignore` ولا يجب رفعه:

```properties
storePassword=ضع_كلمة_مرور_المخزن
keyPassword=ضع_كلمة_مرور_المفتاح
keyAlias=souf360-upload
storeFile=app/upload-keystore.jks
```

## 3. بناء حزمة Play Store الموقّعة

```bash
export PATH="$PATH:/home/ubuntu/flutter/bin"
cd /path/to/souf-tour
flutter build appbundle --release --obfuscate --split-debug-info=build/symbols
```

الناتج المخصص للرفع هو:

```text
build/app/outputs/bundle/release/app-release.aab
```

## 4. إكمال روابط التطبيقات الموثقة

يعمل الرابط المخصص `souf360://place/<id>` فور تثبيت التطبيق. لتجعل Android يفتح الرابط العام `https://souf360.vercel.app/place/<id>` مباشرة في التطبيق، استخرج بصمة SHA-256 لمفتاح الرفع/التوقيع:

```bash
keytool -list -v \
  -keystore android/app/upload-keystore.jks \
  -alias souf360-upload
```

ثم أضف البصمة الفعلية إلى ملف `assetlinks.json` المنشور تحت:

```text
https://souf360.vercel.app/.well-known/assetlinks.json
```

الحزمة المطلوبة هي `com.souf360.app`. لا تستخدم قيمة تخمينية أو بصمة شهادة Debug في هذا الملف.
