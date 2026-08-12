import 'package:flutter/material.dart';

class ImmersiveExperiencePage extends StatelessWidget {
  const ImmersiveExperiencePage(
      {super.key, required this.title, required this.subtitle, this.vrUrl});

  final String title;
  final String subtitle;
  final String? vrUrl;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('تجربة غامرة • $title'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 240,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: const LinearGradient(
                  colors: [Color(0xFF193F38), Color(0xFFD9A441)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: const Stack(
                alignment: Alignment.center,
                children: [
                  Icon(Icons.view_in_ar_rounded, size: 84, color: Colors.white),
                  Positioned(
                    bottom: 16,
                    child: Text(
                      'ALGERIA 360 Immersive Engine',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style:
                  Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5),
            ),
            const Spacer(),
            FilledButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content:
                          Text('تم تشغيل عرض الواقع المعزز والافتراضي بنجاح.')),
                );
              },
              icon: const Icon(Icons.play_circle_outline_rounded),
              label: const Text('بدء الجولة الافتراضية 360°'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_forward_rounded),
              label: const Text('العودة للاستكشاف'),
            ),
          ],
        ),
      ),
    );
  }
}
