# Ouedna App — وادنا

تطبيق Android عربي أولاً لاكتشاف معالم واحات وتراث ولاية الوادي، الجزائر. يتزامن التطبيق مع منصة [Ouedna Web](https://ouedna.vercel.app/) ولوحة إدارة Ouedna عبر Supabase، دون تضمين أي مفتاح إداري أو سري داخل APK.

## القدرات الرئيسية

| المجال | التنفيذ |
|---|---|
| المعالم والمجتمع | قراءة المعالم المنشورة فقط، المفضلة محلياً، واقتراحات وتجارب الزوار قيد المراجعة |
| الخريطة | OpenStreetMap، تحديد الموقع، الطبقة الفضائية، دبابيس الصور والمسارات الداخلية |
| الدليل والرحلة | مساعد سياحي ومخطط رحلة مبنيان على بيانات المنشورات الحية |
| التحديثات | مركز تحديثات وتنزيل APK وإشعارات اختيارية |
| الهوية | Flutter وMaterial 3 وRTL، حزمة Android `com.ouedna.app` |

## التشغيل والتحقق

يتطلب المشروع Flutter 3.24+ وAndroid SDK 35 وJava 17.

```bash
flutter pub get
dart format --set-exit-if-changed lib test
flutter analyze --fatal-infos
flutter test
flutter build apk --debug
```

يمكن حقن مفاتيح Supabase العامة أثناء البناء فقط:

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://<project-ref>.supabase.co \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=<publishable-key>
```

لا تُحفظ مفاتيح `service_role` أو مفاتيح مزود الذكاء الاصطناعي أو ملف توقيع الإصدار في Git. تُستعاد مفاتيح التوقيع من GitHub Actions Secrets وقت إصدار APK.

## الإصدار

```bash
flutter build apk --release
```

قبل إصدار عام، تحقّق من أن مفاتيح `OUEDNA_*` للتوقيع و`SUPABASE_*` العامة مُعدّة في بيئة CI، ثم راجع ناتج التحليل والاختبارات قبل إنشاء tag للإصدار.
