# Publication Android sécurisée — Ouedna

Ce document décrit la chaîne de signature de l’application Android **Ouedna** (`com.ouedna.app`). Le keystore et ses mots de passe sont des données secrètes : ils ne doivent jamais être ajoutés au dépôt Git, à un ticket public ou à une capture d’écran.

## Secrets GitHub Actions requis

Le workflow `.github/workflows/release.yml` lit les secrets suivants. Tous doivent être configurés avant de créer ou de pousser un tag de version.

| Secret | Valeur attendue | Rôle |
|---|---|---|
| `ANDROID_KEYSTORE_BASE64` | Contenu Base64 sans retour à la ligne de `ouedna-release.jks` | Restaure le keystore dans l’environnement CI |
| `ANDROID_KEY_ALIAS` | Alias de la clé de signature | Sélectionne la clé du keystore |
| `ANDROID_STORE_PASSWORD` | Mot de passe du keystore | Ouvre le keystore |
| `ANDROID_KEY_PASSWORD` | Mot de passe de la clé | Signe les artefacts Android |
| `SUPABASE_URL` | URL publique Supabase | Paramètre la connexion de production |
| `SUPABASE_PUBLISHABLE_KEY` | Clé publique Supabase | Paramètre la connexion de production |

Sur une machine sécurisée, produisez la valeur du premier secret ainsi :

```bash
base64 -w0 android/app/ouedna-release.jks > ouedna-release.jks.base64
```

Copiez ensuite le contenu de `ouedna-release.jks.base64` dans le secret `ANDROID_KEYSTORE_BASE64`. Les quatre valeurs de signature sont créées avec le keystore et doivent être conservées dans un gestionnaire de mots de passe, séparément du dépôt Git.

> Le keystore est irremplaçable pour mettre à jour une application déjà distribuée. Conservez au moins deux copies chiffrées, hors de GitHub et hors du téléphone utilisé pour les tests.

## Builds locaux

Avant un build release local, exportez les quatre variables de signature :

```bash
export OUEDNA_KEYSTORE_PATH="$PWD/android/app/ouedna-release.jks"
export OUEDNA_KEY_ALIAS="ouedna-release"
export OUEDNA_STORE_PASSWORD="…"
export OUEDNA_KEY_PASSWORD="…"
```

Le canal de distribution directe crée deux APK optimisés, un pour chaque architecture mobile réellement distribuée :

```bash
flutter build apk --flavor direct --release --split-per-abi \
  --target-platform android-arm,android-arm64 \
  --dart-define=OUEDNA_DIRECT_BUILD=true
```

Les fichiers attendus sont :

```text
build/app/outputs/flutter-apk/app-direct-armeabi-v7a-release.apk
build/app/outputs/flutter-apk/app-direct-arm64-v8a-release.apk
```

Pour une publication Google Play, utilisez un Android App Bundle signé :

```bash
flutter build appbundle --flavor play --release
```

La commande de contrôle générique ci-dessous reste aussi compatible ; elle produit un APK signé du canal Play :

```bash
flutter build apk --release
```

## Vérification de signature

Après chaque build, vérifiez la signature avec l’outil Android SDK :

```bash
apksigner verify --verbose --print-certs build/app/outputs/flutter-apk/app-direct-arm64-v8a-release.apk
```

Le certificat doit afficher `CN=Ouedna Release` et ne doit jamais indiquer `CN=Android Debug`.

## Permissions examinées

| Permission | Décision | Justification dans le code |
|---|---|---|
| `android.permission.RECORD_AUDIO` | Conservée | La page du guide touristique utilise `speech_to_text` pour la saisie vocale. |
| `android.permission.POST_NOTIFICATIONS` | Conservée | Firebase Messaging et les notifications locales demandent l’autorisation puis affichent les alertes de mises à jour et de contenus visiteurs. |
| `android.permission.REQUEST_INSTALL_PACKAGES` | Conservée uniquement dans `src/direct` | `AppUpdateService` télécharge un APK HTTPS, vérifie son SHA-256, puis ouvre l’installateur Android. Cette permission est absente du canal `play`. |

La dépendance `google_mlkit_translation` est conservée : la localisation utilise explicitement `OnDeviceTranslator` et ses modèles de traduction hors ligne. Sa bibliothèque native explique une part importante de la taille, mais sa suppression modifierait une fonctionnalité existante. Grâce aux APK par ABI, la taille de chaque APK distribué reste sous le seuil visé.
