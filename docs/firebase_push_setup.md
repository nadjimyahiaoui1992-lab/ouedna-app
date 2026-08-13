# تفعيل إشعارات تحديث وادنا عبر Firebase

تمت إضافة برمجة استقبال الإشعارات، تسجيل الأجهزة، وإرسال إشعار الإصدار من لوحة الإدارة. يبقى إعداد واحد تابع لمالك حساب Firebase، لأن مفاتيح مشروع Firebase وحساب الخدمة لا يمكن وضعها داخل التطبيق أو مشاركتها علناً.

## 1. إنشاء وربط مشروع Firebase

أنشئ مشروع Firebase أو استخدم مشروعاً قائماً، ثم أضف تطبيق Android بالمعرّف التالي:

```text
com.ouedna.app
```

نزّل ملف `google-services.json` من إعدادات تطبيق Android في Firebase وضعه هنا، من دون إضافته إلى GitHub:

```text
souf-tour/android/app/google-services.json
```

يحتوي Gradle في المشروع على تفعيل شرطي لإعداد Google Services؛ لذلك لن يتعطل البناء الحالي قبل وضع الملف، لكنه يصبح مفعلاً تلقائياً بمجرد إضافته.

## 2. إعداد صلاحية إرسال FCM في الخلفية

من Google Cloud Console المرتبط بمشروع Firebase، أنشئ **Service Account** مخصصاً للإرسال فقط، ثم أنشئ له مفتاح JSON. احتفظ به خاصاً؛ فهو مفتاح خادمي ولا يوضع مطلقاً في APK أو GitHub.

في صفحة **Supabase Dashboard → Edge Functions → Secrets** أضف القيمتين التاليتين:

| اسم السر | القيمة |
|---|---|
| `FIREBASE_PROJECT_ID` | معرّف مشروع Firebase، مثل `ouedna-production` |
| `FIREBASE_SERVICE_ACCOUNT_JSON` | كامل محتوى ملف JSON لمفتاح حساب الخدمة، في سطر واحد |

وظيفة `send-release-notification` تستخدم واجهة Firebase Cloud Messaging HTTP v1 وتتحقق من جلسة مدير وادنا قبل الإرسال. لا تُرسل أي مفاتيح إلى هاتف الزائر.

## 3. بناء وتثبيت تطبيق وادنا

بعد وضع `google-services.json`، ابنِ نسخة جديدة ووقّعها بنفس مفتاح الإنتاج. عند فتح التطبيق، يطلب من الزائر السماح بالإشعارات. بعد الموافقة يسجل التطبيق رمز الجهاز في جدول `push_devices` عبر وظيفة `register-push-device`.

## 4. إرسال إشعار إصدار جديد

في تطبيق **Ouedna Admin** افتح **إدارة تحديث التطبيق** ثم أدخل رقم الإصدار ورابط APK وبصمة SHA-256 وملاحظات الإصدار. في قسم **إشعار المستخدمين بالتحديث** اكتب العنوان والنص ثم اضغط **حفظ وإرسال إشعار**.

الضغط على الإشعار في تطبيق وادنا يفتح مركز التحديث داخل التطبيق. يسجل النظام نتيجة الإرسال في جدول `release_notification_log` ويحذف رموز الأجهزة غير الصالحة تلقائياً.

## 5. اختبار أولي مقترح

اختبر أولاً بجهاز واحد: ثبّت APK بعد ربط Firebase، وافق على الإشعارات، تحقق من ظهور سجل في `push_devices`، ثم أرسل إشعاراً تجريبياً من لوحة الإدارة. بعد نجاحه يمكن إرسال إشعار الإصدار إلى جميع المستخدمين.

## مراجع

- [إعداد Firebase Cloud Messaging لتطبيقات Flutter](https://firebase.google.com/docs/cloud-messaging/flutter/get-started)
- [إرسال الرسائل عبر واجهة FCM HTTP v1](https://firebase.google.com/docs/cloud-messaging/send/v1-api)
- [إدارة أسرار Supabase Edge Functions](https://supabase.com/docs/guides/functions/secrets)
