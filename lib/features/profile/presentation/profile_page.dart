import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) => SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Votre espace',
              style: Theme.of(context)
                  .textTheme
                  .headlineMedium
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              'Souf Tour est conçu pour une découverte respectueuse et informée du territoire.',
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
                          Text('Explorateur Souf',
                              style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 4),
                          const Text(
                              'Aucun compte personnel n’est requis pour consulter les lieux publics.'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            const _PrivacyTile(),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('À propos de Souf Tour'),
              subtitle: const Text(
                  'Informations culturelles et suggestions de découverte.'),
              onTap: () => showAboutDialog(
                context: context,
                applicationName: 'Souf Tour',
                applicationVersion: '1.1.0',
                applicationLegalese:
                    'Application de tourisme dédiée à El Oued.',
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
        title: Text('Confidentialité par conception'),
        subtitle: Text(
            'Les conversations du guide ne doivent pas inclure de données personnelles sensibles.'),
      );
}
