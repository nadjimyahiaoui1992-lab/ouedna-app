import 'package:flutter/material.dart';

import '../../../core/localization/ouedna_localization.dart';
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
  Widget build(BuildContext context) {
    final strings = OuednaStrings.of(context);
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/branding/welcome_bg.jpg',
            fit: BoxFit.cover,
            alignment: Alignment.center,
            semanticLabel: strings.text('discover_el_oued'),
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xD9231B17),
                  Color(0x6630241B),
                  Color(0xED231B17),
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
                      const LanguageSelector(
                          foregroundColor: Color(0xFFFFF7EA)),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0x33D58B2D),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFD58B2D)),
                    ),
                    child: Text(
                      strings.text('official_platform'),
                      style: const TextStyle(
                        color: Color(0xFFFFF7EA),
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const Spacer(flex: 4),
                  Text(
                    strings.appName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 48,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1.0,
                    ),
                  ),
                  Text(
                    strings.text('desert_heart'),
                    style: const TextStyle(
                      color: Color(0xFFD58B2D),
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    strings.text('welcome_intro'),
                    style: const TextStyle(
                      color: Color(0xFFF6E6CA),
                      fontSize: 15,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _WelcomeValue(
                    icon: Icons.auto_awesome_outlined,
                    text: strings.text('smart_guide'),
                  ),
                  const SizedBox(height: 12),
                  _WelcomeValue(
                    icon: Icons.history_edu_rounded,
                    text: strings.text('heritage_archive'),
                  ),
                  const SizedBox(height: 12),
                  _WelcomeValue(
                    icon: Icons.map_outlined,
                    text: strings.text('interactive_maps'),
                  ),
                  const Spacer(flex: 3),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFD58B2D),
                        foregroundColor: const Color(0xFF30241B),
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        textStyle: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                        ),
                      ),
                      onPressed: onContinue,
                      child: Text(strings.text('start_exploring')),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: TextButton(
                      onPressed: onContinue,
                      style:
                          TextButton.styleFrom(foregroundColor: Colors.white70),
                      child: Text(strings.text('enter_as_guest')),
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
}

class _BrandMark extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(
                color: Colors.black26, blurRadius: 10, offset: Offset(0, 4)),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Image.asset('assets/branding/icon.png', fit: BoxFit.cover),
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
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: Color(0x26D58B2D),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: const Color(0xFFD58B2D)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Color(0xFFFFF7EA),
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
        ],
      );
}
