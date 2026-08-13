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
              'assets/branding/welcome_bg.jpg',
              fit: BoxFit.cover,
              alignment: Alignment.center,
              semanticLabel: 'غروب الشمس الساحر في وادي سوف',
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xCC102D28),
                    Color(0x66102D28),
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
                            'المنصة السياحية الرسمية',
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
                      'وادنا',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 48,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1.0,
                      ),
                    ),
                    const Text(
                      'قلب الصحراء ينبض هنا',
                      style: TextStyle(
                        color: Color(0xFFD9A441),
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'مرحباً بك في وادنا، دليلك الذكي لاستكشاف كنوز وادي سوف. من القباب التاريخية إلى الواحات الخضراء وسط الرمال الذهبية، نحن هنا لنرشدك في رحلة لا تُنسى.',
                      style: TextStyle(
                        color: Color(0xFFE0EEE7),
                        fontSize: 15,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const _WelcomeValue(icon: Icons.auto_awesome_outlined, text: 'مساعد ذكي للإرشاد السياحي (AI)'),
                    const SizedBox(height: 12),
                    const _WelcomeValue(icon: Icons.history_edu_rounded, text: 'أرشيف وذكريات وادي سوف التاريخية'),
                    const SizedBox(height: 12),
                    const _WelcomeValue(icon: Icons.map_outlined, text: 'خرائط تفاعلية ومسارات سياحية دقيقة'),
                    const Spacer(flex: 3),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFD9A441),
                          foregroundColor: const Color(0xFF102D28),
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          textStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                        ),
                        onPressed: onContinue,
                        child: const Text('ابدأ رحلة الاستكشاف'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: TextButton(
                        onPressed: onContinue,
                        style: TextButton.styleFrom(foregroundColor: Colors.white70),
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
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10, offset: const Offset(0, 4))],
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
            decoration: const BoxDecoration(color: Color(0x26D9A441), shape: BoxShape.circle),
            child: Icon(icon, size: 18, color: const Color(0xFFD9A441)),
          ),
          const SizedBox(width: 12),
          Text(
            text,
            style: const TextStyle(color: Color(0xFFFDF7EE), fontWeight: FontWeight.w700, fontSize: 14),
          ),
        ],
      );
}
