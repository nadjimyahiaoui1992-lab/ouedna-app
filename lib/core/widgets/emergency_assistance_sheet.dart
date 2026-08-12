import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> showEmergencyAssistanceSheet(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 30),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.sos_rounded,
                      color: Color(0xFFB3261E), size: 34),
                  const SizedBox(width: 10),
                  Text(
                    'مساعدة عاجلة',
                    style: Theme.of(sheetContext)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.w900),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'هذه الخدمة مخصصة للحالات الطارئة والنجدة. سيُفتح تطبيق الاتصال على هاتفك مباشرة؛ لا يشارك Souf 360 موقعك أو بياناتك.',
                style: TextStyle(height: 1.55),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFB3261E)),
                  onPressed: () => _launchEmergencyDialer(sheetContext, '14'),
                  icon: const Icon(Icons.call_rounded),
                  label: const Text('الحماية المدنية — 14'),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF193F38),
                    side: const BorderSide(color: Color(0xFF193F38)),
                  ),
                  onPressed: () => _launchEmergencyDialer(sheetContext, '1055'),
                  icon: const Icon(Icons.local_police_rounded),
                  label: const Text('الشرطة (النجدة) — 1055'),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF193F38),
                    side: const BorderSide(color: Color(0xFF193F38)),
                  ),
                  onPressed: () => _launchEmergencyDialer(sheetContext, '1548'),
                  icon: const Icon(Icons.security_rounded),
                  label: const Text('الدرك الوطني — 1548'),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: () => _launchEmergencyDialer(sheetContext, '1021'),
                  icon: const Icon(Icons.phone_in_talk_rounded, size: 18),
                  label: const Text('رقم طوارئ الحماية البديل — 1021'),
                ),
              ),
            ],
          ),
        ),
      ),
    );

Future<void> _launchEmergencyDialer(BuildContext context, String number) async {
  final navigator = Navigator.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final opened = await launchUrl(
    Uri(scheme: 'tel', path: number),
    mode: LaunchMode.externalNonBrowserApplication,
  );
  if (opened) {
    navigator.pop();
  } else {
    messenger.showSnackBar(
      const SnackBar(content: Text('تعذر فتح تطبيق الاتصال على هذا الجهاز.')),
    );
  }
}
