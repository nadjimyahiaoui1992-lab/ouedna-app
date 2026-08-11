import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/config/app_config.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) => SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'دليلك لزيارة سوف',
              style: Theme.of(context)
                  .textTheme
                  .headlineMedium
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              'Souf Tour تطبيق مخصص للزوار. تُدار المعالم والصور والمعلومات المنشورة من منصة Souf360 وتصل إلى التطبيق تلقائياً.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      child: Icon(Icons.explore, size: 30),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'زائر Souf Tour',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'لا يلزم إنشاء حساب لاستكشاف المعالم والمعلومات العامة المنشورة.',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            ListTile(
              leading: const Icon(Icons.language_outlined),
              title: const Text('فتح منصة Souf360'),
              subtitle: const Text('الخريطة والمعالم والخدمات المحدثة'),
              trailing: const Icon(Icons.open_in_new),
              onTap: () => launchUrl(
                Uri.parse(AppConfig.siteUrl),
                mode: LaunchMode.externalApplication,
              ),
            ),
            const Divider(height: 1),
            const _PrivacyTile(),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('حول Souf Tour'),
              subtitle: const Text('دليل سياحي رقمي لمدينة وادي سوف.'),
              onTap: () => showAboutDialog(
                context: context,
                applicationName: 'Souf Tour',
                applicationVersion: '1.2.0',
                applicationLegalese: 'تطبيق سياحي مخصص لزوار وادي سوف.',
              ),
            ),
          ],
        ),
      );
}

class _PrivacyTile extends StatelessWidget {
  const _PrivacyTile();

  @override
  Widget build(BuildContext context) => const ListTile(
        leading: Icon(Icons.shield_outlined),
        title: Text('خصوصية افتراضية'),
        subtitle: Text(
          'التطبيق يقرأ المعالم العامة المنشورة فقط. لا تشارك بيانات شخصية حساسة مع الدليل الذكي.',
        ),
      );
}
