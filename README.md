# Souf Tour

**Souf Tour** est une application Flutter Android de découverte culturelle et touristique d’El Oued. Elle associe une exploration de lieux publiés à un guide conversationnel exécuté côté serveur afin que les clés du fournisseur IA ne soient jamais incluses dans l’APK.

| Domaine | Choix de production |
| --- | --- |
| Client mobile | Flutter, Dart 3 et Material Design 3 |
| Données | Supabase avec RLS, privilèges explicites et contenus publiés seulement |
| Guide IA | Supabase Edge Function authentifiée, limitation par utilisateur et contexte des lieux publiés |
| Android | Java 17, AGP 8.5.2, Gradle 8.7, SDK cible 35 |
| Livraison | Analyse, tests, APK de validation et workflow de release GitHub |

## Architecture

Le code suit une séparation pragmatique inspirée de **Clean Architecture**. Les entités et contrats de dépôt sont dans `domain`, les adaptations Supabase dans `data`, et les écrans Flutter dans `presentation`. Cette frontière permet de tester l’application sans réseau et d’éviter que les widgets dépendent directement du SDK de données.

```text
lib/
├── app/                         # Composition et navigation de l’application
├── core/                        # Configuration, erreurs et thème partagé
└── features/
    ├── places/                  # Consultation des lieux publiés
    ├── explore/                 # Parcours d’exploration Material 3
    ├── tour_guide/              # Conversation avec l’Edge Function
    └── profile/                 # Transparence et confidentialité
```

## Démarrage local

La consultation des écrans peut fonctionner sans backend, en mode démonstration. Pour activer les données et le guide, transmettez l’URL Supabase et la **clé publique** au moment du build. Une clé publique est conçue pour être distribuée au client, mais elle doit toujours être associée à des politiques RLS strictes ; elle ne remplace jamais une clé de service côté serveur.[1]

```bash
flutter pub get
flutter run \
  --dart-define=SUPABASE_URL=https://<project-ref>.supabase.co \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=<sb_publishable_key>
```

N’ajoutez jamais de clé `service_role`, de clé OpenAI ni de fichier `key.properties` au dépôt. Les exclusons Git couvrent les fichiers de configuration sensibles et de signature.

## Configuration du guide IA

La fonction `tour-guide` est conçue pour rester authentifiée. L’application ouvre une session anonyme uniquement pour recevoir un JWT ; activez donc **Anonymous Sign-Ins** dans Supabase Auth avant d’utiliser le guide. Configurez ensuite les secrets de fonction suivants dans Supabase, et jamais dans Flutter ou GitHub :

| Secret de fonction | Rôle |
| --- | --- |
| `OPENAI_API_KEY` | Clé privée du fournisseur IA utilisée uniquement dans l’Edge Function |
| `OPENAI_MODEL` | Modèle à utiliser ; `gpt-4o-mini` est le repli prévu par le code |

La fonction contrôle la taille des requêtes, refuse certains motifs de données personnelles, vérifie le JWT, applique une limite de **12 requêtes par 10 minutes et par utilisateur**, et transmet au modèle uniquement le contexte des lieux dont le statut est `منشور`. Les réponses demandent explicitement la transparence lorsque l’information n’est pas disponible.

> Le guide fournit une aide de découverte. Les horaires, tarifs, transports et conditions de visite doivent être confirmés auprès des établissements ou autorités locales.

## Intégration Souf360

**Souf360** est la surface de gestion : les administrateurs y ajoutent, corrigent, publient et géolocalisent les المعالم. **Souf Tour** est l’application Android grand public : elle ne contient aucune interface d’administration et consomme uniquement le catalogue public soumis aux politiques RLS.

| Événement dans Souf360 | Effet dans Souf Tour |
| --- | --- |
| Un administrateur ajoute ou modifie un lieu | Le changement est enregistré dans `public.places`. |
| Le statut du lieu devient `منشور` | Le lieu devient lisible par les visiteurs conformément à la politique RLS. |
| La table `places` émet un changement | L’application reçoit le signal Realtime puis recharge la liste publiée automatiquement. |

L’application est configurée par défaut pour lire le même projet public que [Souf360](https://souf360.vercel.app). Les paramètres de développement peuvent encore être remplacés par `SUPABASE_URL` et `SUPABASE_PUBLISHABLE_KEY`, mais aucune clé de service n’est embarquée dans l’APK.

## Provenance des médias

Le dépôt ne contient plus aucun média photographique, vidéo ou audio issu de l’ancien modèle Palghar/Vasai ni aucune icône Flutter générique. L’interface exploite une dégradation visuelle explicite lorsqu’aucune image **authentifiée pour El Oued** n’est disponible. Les constats détaillés sont conservés dans [`docs/media_audit_notes.md`](docs/media_audit_notes.md).

L’inventaire de Supabase Storage a révélé des objets aux noms génériques et sans preuve de provenance à l’échelle de l’objet. Afin d’éviter des fichiers facturés mais orphelins, leur suppression doit passer exclusivement par l’API Storage ou le tableau de bord autorisé, et non par une requête SQL de métadonnées.[3] Cette dernière suppression est volontairement différée tant qu’un accès Storage authentifié n’est pas disponible.

## Sécurité Supabase

Les migrations versionnées dans `supabase/migrations/` appliquent un modèle par défaut fermé. Elles suppriment les écritures anonymes héritées, accordent uniquement la lecture des contenus publics nécessaires, déplacent la vérification d’administration dans un schéma `private`, retirent l’exécution RPC des fonctions internes et ajoutent une table privée de limitation de débit. Les fonctions `SECURITY DEFINER` utilisent un `search_path` déterministe et l’API de données combine privilèges SQL minimaux et politiques RLS, conformément au modèle recommandé par Supabase.[1]

Il reste une action de sécurité de console à effectuer une seule fois : activez **Leaked Password Protection** dans Supabase Auth. Cette option vérifie les mots de passe compromis lors des flux de mot de passe.[2]

## Qualité et CI/CD

Le workflow `Android quality gate` s’exécute sur les pull requests, `main` et les déclenchements manuels. Il formate le code, lance l’analyse statique, exécute les tests et publie un APK de validation comme artefact du workflow.

Le workflow `Publish Android release` s’exécute pour chaque tag `v*` et publie un APK signé dans une GitHub Release. Définissez ces secrets GitHub avant de créer le premier tag :

| Secret GitHub | Usage |
| --- | --- |
| `ANDROID_KEYSTORE_BASE64` | Keystore d’upload encodé en Base64 |
| `ANDROID_KEY_ALIAS` | Alias de la clé de signature |
| `ANDROID_KEY_PASSWORD` | Mot de passe de la clé |
| `ANDROID_STORE_PASSWORD` | Mot de passe du keystore |
| `SUPABASE_URL` | URL publique du projet Supabase |
| `SUPABASE_PUBLISHABLE_KEY` | Clé publique Supabase injectée au build |

```bash
# Vérification locale complète
flutter pub get
dart format --set-exit-if-changed lib test
flutter analyze
flutter test --coverage
flutter build apk --debug

# Publication après configuration des secrets GitHub
git tag v1.1.0
git push origin v1.1.0
```

## Vérifications réalisées

| Contrôle | Résultat |
| --- | --- |
| Analyse Flutter | Sans problème |
| Tests Flutter | Réussis |
| APK debug local | Généré avec succès |
| Migration RLS et privilèges | Appliquée au projet Supabase |
| Edge Function `tour-guide` | Déployée avec vérification JWT active |
| Analyse de sécurité Supabase | Alertes RLS et fonctions publiques résolues ; activation manuelle de la protection contre les mots de passe compromis restante |
| Médias sources | Images Palghar/Vasai, captures, icônes Flutter et scaffolding iOS supprimés ; aucun média non vérifié n’est embarqué |
| Supabase Storage | Inventorié et documenté ; suppression physique différée faute d’accès Storage authentifié, afin d’éviter des objets orphelins |

## Références

[1]: https://supabase.com/docs/guides/api/securing-your-api "Supabase — Securing your API"
[2]: https://supabase.com/docs/guides/auth/password-security "Supabase — Password security"
[3]: https://supabase.com/docs/guides/storage/management/delete-objects "Supabase — Delete Storage objects"
[4]: https://supabase.com/docs/guides/realtime/postgres-changes "Supabase — Postgres Changes"
