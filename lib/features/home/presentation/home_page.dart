import 'package:flutter/material.dart';

import '../../../core/localization/ouedna_localization.dart';
import '../../../core/storage/favorites_controller.dart';
import '../../compass/presentation/compass_page.dart';
import '../../emergency/presentation/emergency_sheet.dart';
import '../../places/domain/repositories/place_repository.dart';
import '../../places/presentation/visitor_place_submission_page.dart';
import '../../routing/domain/routing_service.dart';

class HomePage extends StatelessWidget {
  const HomePage({
    super.key,
    required this.repository,
    required this.favorites,
    required this.routingService,
    required this.onExplore,
    required this.onMap,
    required this.onGuide,
  });

  final PlaceRepository? repository;
  final FavoritesController favorites;
  final RoutingService? routingService;
  final VoidCallback onExplore;
  final VoidCallback onMap;
  final VoidCallback onGuide;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final strings = OuednaStrings.of(context);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: scheme.primary,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                strings.appName,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    'assets/branding/welcome_bg.jpg',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        ColoredBox(color: scheme.primary),
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Color(0xDD163F3A)],
                      ),
                    ),
                  ),
                  PositionedDirectional(
                    start: 20,
                    end: 20,
                    bottom: 58,
                    child: Text(
                      strings.text('discover_el_oued'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        height: 1.1,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 36),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Text(
                  strings.text('start_your_journey'),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  strings.text('home_intro'),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                        height: 1.45,
                      ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: _ActionCard(
                        icon: Icons.explore_rounded,
                        title: strings.text('explore_places'),
                        subtitle: strings.text('nearby_places'),
                        onTap: onExplore,
                        color: scheme.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ActionCard(
                        icon: Icons.map_outlined,
                        title: strings.text('map'),
                        subtitle: strings.text('plan_route'),
                        onTap: onMap,
                        color: const Color(0xFFB57B2A),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _WideAction(
                  icon: Icons.add_location_alt_outlined,
                  title: strings.text('suggest_place'),
                  subtitle: repository == null
                      ? strings.text('database_required')
                      : strings.text('suggest_place_info'),
                  onTap: repository == null
                      ? null
                      : () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => VisitorPlaceSubmissionPage(
                                repository: repository!,
                              ),
                            ),
                          ),
                ),
                const SizedBox(height: 12),
                _WideAction(
                  icon: Icons.explore_outlined,
                  title: strings.text('my_itinerary'),
                  subtitle: strings.text('my_itinerary_info'),
                  onTap: repository == null
                      ? null
                      : () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => CompassPage(
                                repository: repository,
                                favorites: favorites,
                                routingService: routingService,
                                onMap: onMap,
                              ),
                            ),
                          ),
                ),
                const SizedBox(height: 12),
                _WideAction(
                  icon: Icons.auto_awesome_outlined,
                  title: 'المساعد السياحي',
                  subtitle: 'اسأل عن الأماكن والرحلات والنصائح العملية.',
                  onTap: repository == null ? null : onGuide,
                ),
                const SizedBox(height: 12),
                _WideAction(
                  icon: Icons.emergency_outlined,
                  title: strings.text('emergency_help'),
                  subtitle: strings.text('emergency_help_info'),
                  onTap: () => EmergencySheet.show(context),
                ),
                const SizedBox(height: 24),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Row(
                      children: [
                        const Icon(Icons.shield_outlined, size: 30),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            strings.text('live_data_notice'),
                            style: const TextStyle(
                              height: 1.45,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) => Card(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  child: Icon(icon),
                ),
                const SizedBox(height: 12),
                Text(title,
                    style: const TextStyle(fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
      );
}

class _WideAction extends StatelessWidget {
  const _WideAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Card(
        child: ListTile(
          onTap: onTap,
          leading: CircleAvatar(child: Icon(icon)),
          title:
              Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
          subtitle: Text(subtitle),
          trailing: const Icon(Icons.chevron_left_rounded),
        ),
      );
}
