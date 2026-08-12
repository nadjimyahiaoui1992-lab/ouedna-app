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
                    _BrandMark(),
                    const Spacer(flex: 5),
                    const Text(
                      'سوف 360',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 42,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'اكتشف وادي سوف من كل زاوية',
                      style: TextStyle(
                        color: Color(0xFFFDF7EE),
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'دليل سياحي عصري للمعالم المحلية والخريطة الذكية والتجارب التي ينشرها مجتمع سوف.',
                      style: TextStyle(
                        color: Color(0xFFE0EEE7),
                        fontSize: 16,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 22),
                    const _WelcomeValue(
                        icon: Icons.map_outlined,
                        text: 'خريطة تفاعلية ومعالم محلية'),
                    const SizedBox(height: 10),
                    const _WelcomeValue(
                        icon: Icons.explore_outlined,
                        text: 'مسار يناسب وقتك واهتماماتك'),
                    const SizedBox(height: 10),
                    const _WelcomeValue(
                        icon: Icons.auto_awesome_outlined,
                        text: 'دليل ذكي للمعلومات والنصائح'),
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
                        label: const Text('ابدأ الاستكشاف'),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Center(
                      child: TextButton(
                        onPressed: onContinue,
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFFFDF7EE),
                        ),
                        child: const Text('دخول كزائر'),
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
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: const Color(0xDDFBF7EF),
          borderRadius: BorderRadius.circular(17),
        ),
        child: const Icon(Icons.landscape_rounded,
            color: Color(0xFF193F38), size: 28),
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
                  color: Color(0xFFFDF7EE), fontWeight: FontWeight.w700)),
        ],
      );
}
