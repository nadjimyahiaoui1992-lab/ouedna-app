# توقيع Ouedna للإصدار على Google Play

إعدادات Gradle في المشروع تمنع الآن أي استخدام صامت لشهادة Android Debug في إصدار `release`. بقيت **مادة التوقيع** خارج المستودع وضمن مسؤولية مالك المشروع؛ وهي لا تُرسل عبر المحادثة أو GitHub.

## 1. إنشاء أو استعادة مفتاح الرفع

إذا لم يكن لديك مفتاح رفع سابق، أنشئه محلياً على جهاز موثوق واحتفظ بنسخة مشفّرة منه خارج المشروع:

```bash
keytool -genkeypair -v \
  -keystore android/app/upload-keystore.jks \
  -alias ouedna-upload \
  -keyalg RSA -keysize 4096 -validity 10000
```

> إذا كان تطبيق Ouedna منشوراً بالفعل، يجب استخدام **نفس** مفتاح الرفع المسجّل في Play Console، ولا يجوز إنشاء مفتاح بديل إلا عبر إجراء إعادة ضبط مفتاح الرفع في Google Play.

## 2. إنشاء `android/key.properties`

أنشئ الملف محلياً فقط؛ يحظره `.gitignore` ولا يجب رفعه:

```properties
storePassword=ضع_كلمة_مرور_المخزن
keyPassword=ضع_كلمة_مرور_المفتاح
keyAlias=ouedna-upload
storeFile=app/upload-keystore.jks
```

## 3. بناء حزمة Play Store الموقّعة

```bash
export PATH="$PATH:/home/ubuntu/flutter/bin"
cd /path/to/ouedna-app
flutter build appbundle --release --obfuscate --split-debug-info=build/symbols
```

الناتج المخصص للرفع هو:

```text
build/app/outputs/bundle/release/app-release.aab
```

## 4. إكمال روابط التطبيقات الموثقة

يعمل الرابط المخصص `ouedna://place/<id>` فور تثبيت التطبيق. لتجعل Android يفتح الرابط العام `https://ouedna.vercel.app/place/<id>` مباشرة في التطبيق، استخرج بصمة SHA-256 لمفتاح الرفع/التوقيع:

```bash
keytool -list -v \
  -keystore android/app/upload-keystore.jks \
  -alias ouedna-upload
```

ثم أضف البصمة الفعلية إلى ملف `assetlinks.json` المنشور تحت:

```text
https://ouedna.vercel.app/.well-known/assetlinks.json
```

الحزمة المطلوبة هي `com.ouedna.app`. لا تستخدم قيمة تخمينية أو بصمة شهادة Debug في هذا الملف.
