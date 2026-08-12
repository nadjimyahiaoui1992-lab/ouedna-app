import 'package:flutter/material.dart';

import '../../places/domain/repositories/place_repository.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({
    super.key,
    required this.repository,
    required this.onContinue,
  });

  final PlaceRepository? repository;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/branding/souf360_oasis_sunset.jpg',
              fit: BoxFit.cover,
              alignment: Alignment.center,
              semanticLabel: 'واحة في الصحراء عند غروب الشمس',
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xE6102D28),
                    Color(0x99102D28),
                    Color(0xEE102D28),
                  ],
                  stops: [0, .45, 1],
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 22, 24, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _BrandMark(),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0x33D9A441),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFD9A441)),
                          ),
                          child: const Text(
                            'المنصة الرسمية لوادي سوف',
                            style: TextStyle(
                              color: Color(0xFFFBF7EF),
                              fontWeight: FontWeight.w900,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(flex: 4),
                    const Text(
                      'اكتشف سوف',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 38,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'عاصمة الألف قبة وقبة',
                      style: TextStyle(
                        color: Color(0xFFD9A441),
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'اكتشف سحر الوادي... حيث تبدأ الحكاية وتنتهي الذكريات. كثبان ذهبية، وغيطان ونخيل، وواحات وأراضٍ فلاحية تخضّرُ وسط الصحراء.',
                      style: TextStyle(
                        color: Color(0xFFE0EEE7),
                        fontSize: 15,
                        height: 1.55,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const _WelcomeValue(
                        icon: Icons.auto_awesome_outlined,
                        text: 'مساعد سياحي ذكي مدمج (AI Concierge)'),
                    const SizedBox(height: 10),
                    const _WelcomeValue(
                        icon: Icons.map_outlined,
                        text: 'خرائط وملاحة ذكية مع طبقة الأقمار الصناعية'),
                    const SizedBox(height: 10),
                    const _WelcomeValue(
                        icon: Icons.forum_outlined,
                        text: 'مجتمع الزوار وتجارب الرحلات الموثقة'),
                    const Spacer(flex: 3),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFE5B65A),
                          foregroundColor: const Color(0xFF102D28),
                          padding: const EdgeInsets.symmetric(vertical: 17),
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 17,
                          ),
                        ),
                        onPressed: onContinue,
                        icon: const Icon(Icons.arrow_back_rounded),
                        label: const Text('ابدأ الاستكشاف الذكي'),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Center(
                      child: TextButton(
                        onPressed: onContinue,
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFFFDF7EE),
                        ),
                        child: const Text('دخول مباشر كزائر'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
}

class _BrandMark extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: const Color(0xDDFBF7EF),
          borderRadius: BorderRadius.circular(17),
        ),
        child: const Icon(Icons.travel_explore_rounded,
            color: Color(0xFF193F38), size: 30),
      );
}

class _WelcomeValue extends StatelessWidget {
  const _WelcomeValue({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: const BoxDecoration(
                color: Color(0x26E5B65A), shape: BoxShape.circle),
            child: Icon(icon, size: 17, color: const Color(0xFFE5B65A)),
          ),
          const SizedBox(width: 10),
          Text(text,
              style: const TextStyle(
                  color: Color(0xFFFDF7EE), fontWeight: FontWeight.w700, fontSize: 13.5)),
        ],
      );
}
