# إعداد Ouedna لنشر نسخة iPhone عبر TestFlight

## ما تم تجهيزه داخل المشروع

تمت إضافة منصة iOS الرسمية إلى مشروع Flutter Ouedna. هوية التطبيق على iPhone هي:

| الإعداد | القيمة |
|---|---|
| اسم التطبيق الظاهر | `Ouedna` |
| Apple Bundle Identifier | `com.ouedna.app` |
| الحد الأدنى المدعوم | iOS 15.0 |
| النسخة الجاهزة للبناء | `2.0.4+31` |
| أذونات iOS المعرّفة | الموقع أثناء الاستخدام، الكاميرا، الصور والميكروفون |

كما تم تجهيز أيقونات Ouedna بجميع المقاسات المطلوبة من Apple، وملف CocoaPods للتكامل مع Flutter وFirebase. لا يتضمن المشروع ملف Firebase الخاص بـ iOS ولا أي شهادة Apple.

> لا يمكن إنتاج ملف IPA أو توقيعه على Linux؛ يتطلب بناء iOS برنامج Xcode على جهاز macOS [1].

## 1. إنشاء هوية Ouedna لدى Apple

يجب أن يكون لديك اشتراك نشط في Apple Developer Program وحساب App Store Connect. من بوابة Apple Developer افتح **Certificates, Identifiers & Profiles**، ثم أنشئ **App ID** من نوع Explicit بالقيمة التالية:

```text
com.ouedna.app
```

لا تغيّر هذا المعرف بعد إنشاء التطبيق في App Store Connect. معرف Bundle هو الهوية الفريدة لتطبيق iOS [2].

## 2. إضافة تطبيق iOS إلى Firebase

من Firebase Console، داخل مشروع `ouedna`، اختر **Add app** ثم **iOS** واكتب:

```text
Apple bundle ID: com.ouedna.app
App nickname: Ouedna iOS
```

نزّل الملف الناتج `GoogleService-Info.plist` وضعه محلياً في المسار التالي:

```text
souf-tour/ios/Runner/GoogleService-Info.plist
```

هذا الملف مستثنى من Git عمداً. لا ترفعه إلى GitHub ولا تشاركه في رسالة عامة. ملف Android `google-services.json` لا يصلح لنظام iOS؛ لكل منصة ملف Firebase مستقل [3].

## 3. إنشاء التطبيق في App Store Connect

من App Store Connect افتح **My Apps** ثم **New App**. اختر iOS، وعيّن الاسم `Ouedna`، واللغة الأساسية المناسبة، واختر Bundle ID `com.ouedna.app`. لا تضف الزوار بعد؛ سيتم ذلك من TestFlight عند رفع أول build [4].

## 4. البناء والتوقيع على Mac

على جهاز Mac مزود بـ Xcode، انسخ المشروع ثم نفّذ:

```bash
cd souf-tour
flutter pub get
open ios/Runner.xcworkspace
```

داخل Xcode اختر Target **Runner** ثم **Signing & Capabilities**، وحدد فريق Apple Developer الخاص بك. استخدم التوقيع التلقائي Automatic Signing. تأكد من وجود الملف `ios/Runner/GoogleService-Info.plist` قبل فتح المشروع.

بعدها ابنِ ملف IPA:

```bash
flutter build ipa --release
```

سيظهر الملف عادة في:

```text
build/ios/ipa/*.ipa
```

## 5. رفع النسخة إلى TestFlight

ارفع ملف IPA من Xcode Organizer أو تطبيق Transporter إلى App Store Connect. بعد أن تنتهي معالجة Apple للملف، افتح **TestFlight** وأضف المختبرين الداخليين. للاختبار الخارجي أضف مجموعة TestFlight وارسل الرابط أو البريد الإلكتروني للمختبرين. Apple تتيح رفع builds إلى App Store Connect باستخدام Xcode أو Transporter أو أدوات معتمدة أخرى [4].

## قائمة التحقق قبل إرسال الرابط للزوار

| التحقق | مطلوب |
|---|---|
| Bundle ID في Apple وFirebase وXcode هو `com.ouedna.app` | نعم |
| ملف `GoogleService-Info.plist` موجود محلياً فقط | نعم |
| Team في Xcode هو فريق Apple الصحيح | نعم |
| خريطة، موقع، صور، ملاحة وإشعارات تم اختبارها على iPhone حقيقي | نعم |
| معلومات الخصوصية في App Store Connect جاهزة | نعم |
| إصدار TestFlight يملك رقم build أعلى من السابق | نعم |

## ملاحظة أمنية

يحوي الملف `GoogleService-Info.plist` إعدادات تطبيق Firebase، لكنه لا يغني عن أسرار الخادم. مفاتيح Supabase ذات الصلاحيات المرتفعة وملف حساب خدمة GA4 تبقى في أسرار Supabase فقط ولا تدخل إطلاقاً في تطبيق iOS.

## المراجع

[1] [Flutter — Build and release an iOS app](https://docs.flutter.dev/deployment/ios)

[2] [Apple Developer — Register an App ID](https://developer.apple.com/help/account/identifiers/register-an-app-id/)

[3] [Firebase — Add Firebase to your Apple project](https://firebase.google.com/docs/ios/setup)

[4] [Apple — Upload builds to App Store Connect](https://developer.apple.com/help/app-store-connect/manage-builds/upload-builds/)
