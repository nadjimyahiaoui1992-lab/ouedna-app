import 'package:flutter/material.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('سياسة الخصوصية', style: TextStyle(fontWeight: FontWeight.w900)),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSection('مقدمة', 'نحن في تطبيق "وادنا" نلتزم بحماية خصوصيتك وبياناتك الشخصية. توضح هذه السياسة كيفية جمع واستخدام وحماية المعلومات التي تقدمها لنا.'),
              _buildSection('المعلومات التي نجمعها', '• الموقع الجغرافي: نطلب الوصول إليه فقط عند ضغطك على زر تحديد الموقع للملاحة أو عند اختيار مشاركة موقع الضحية في الطوارئ.\n• الصور: نطلب الوصول للمعرض فقط في حال رغبتك في اقتراح معلم جديد أو مشاركة تجربة سياحية.\n• ملفات التحديث: في الإصدار المباشر خارج المتجر فقط، قد ينزّل التطبيق ملف تحديث APK موثّقاً بعد طلبك الصريح.'),
              _buildSection('كيفية استخدام المعلومات', 'تُستخدم بيانات الموقع محلياً على جهازك ولا يتم تخزينها في خوادمنا لأغراض التتبع. عند اختيار مشاركة الموقع في حالة طارئة، يفتح التطبيق واجهة المشاركة التي تختارها أنت. الصور والمقترحات التي ترسلها يتم مراجعتها من قبل الإدارة قبل النشر لضمان جودة المحتوى.'),
              _buildSection('الأمان', 'نستخدم تقنيات Supabase السحابية لحماية البيانات المرسلة. في التوزيع المباشر، نتحقق من بصمة SHA-256 لملف APK قبل فتح مثبّت أندرويد، ولا يتم تثبيت أي تحديث دون تأكيد المستخدم.'),
              _buildSection('التواصل', 'إذا كان لديك أي استفسار حول سياسة الخصوصية، يمكنك التواصل معنا عبر لوحة الإدارة أو من خلال قنواتنا الرسمية.'),
              const SizedBox(height: 40),
              const Center(
                child: Text('آخر تحديث: 13 أغسطس 2026', style: TextStyle(color: Colors.grey, fontSize: 12)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF193F38))),
          const SizedBox(height: 8),
          Text(content, style: const TextStyle(fontSize: 14, height: 1.6, color: Color(0xFF475569))),
        ],
      ),
    );
  }
}
