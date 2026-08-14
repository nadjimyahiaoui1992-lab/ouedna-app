# Ouedna — Mise en service de Firebase Analytics

## Objectif

Ouedna 2.0.3 enregistre, au démarrage de l’application, un événement Firebase Analytics nommé `ouedna_app_session` et un événement de présence anonyme dans Supabase. Les deux mécanismes sont complémentaires : **Supabase** alimente immédiatement la carte « installations vérifiées » et les utilisateurs actifs de la tablette Admin ; **Firebase / Google Analytics 4 (GA4)** fournit les rapports avancés d’audience, de rétention, de versions et d’événements.

Aucune donnée d’identité, de position, de nom, d’adresse électronique ou de contenu de visiteur n’est envoyée par la collecte ajoutée. Le signal Supabase utilise un identifiant d’installation aléatoire persistant. Firebase reçoit le nom d’événement, la version de l’application et la locale de l’appareil.

## Activation dans Firebase

1. Ouvrir le projet Firebase associé à l’application Android `com.ouedna.app` : <https://console.firebase.google.com>.
2. Depuis les paramètres du projet, vérifier que **Google Analytics** est activé et qu’une propriété GA4 est associée. Si ce n’est pas le cas, choisir **Intégrations** puis associer ou créer la propriété Analytics.
3. Vérifier que le fichier Android `google-services.json` correspond bien au package `com.ouedna.app`. Ce fichier est local et ne doit jamais être ajouté au dépôt Git.
4. Installer l’APK Ouedna 2.0.3 sur un appareil réel, ouvrir l’application, puis consulter **Analytics > DebugView** ou les événements. Les premières données des tableaux standards peuvent nécessiter jusqu’à 24 heures de traitement.

> Pour les essais immédiats, activer le mode de débogage Analytics sur un appareil relié en USB avec la commande `adb shell setprop debug.firebase.analytics.app com.ouedna.app`, ouvrir Ouedna, puis ouvrir DebugView. Désactiver ensuite avec `adb shell setprop debug.firebase.analytics.app .none.`.

## Rapports conseillés

| Question produit | Rapport Firebase / GA4 conseillé | Décision possible |
|---|---|---|
| Combien de visiteurs utilisent réellement Ouedna ? | Utilisateurs actifs, nouveaux utilisateurs et rétention | Mesurer l’adoption après une communication ou un événement local. |
| Les visiteurs restent-ils actifs ? | Rétention et engagement | Repérer les versions ou parcours qui demandent une amélioration. |
| Quelle version est utilisée ? | Dimension « App version » | Prioriser une annonce de mise à jour ou une compatibilité. |
| Quelles langues sont les plus employées ? | Dimension « Language » | Ajuster les contenus AR, FR et EN. |
| Le démarrage remonte-t-il correctement ? | Événement `ouedna_app_session` | Confirmer le bon fonctionnement de l’instrumentation. |

## Données visibles dans Ouedna Admin

Le tableau de bord Admin utilise déjà la fonction Supabase `get-admin-analytics`. Il présente notamment les installations uniques vérifiées, DAU, WAU, les nouvelles installations sur 30 jours et les téléchargements d’APK recensés par GitHub. Les compteurs commencent à se remplir dès que les utilisateurs installent et ouvrent **Ouedna 2.0.3 ou une version ultérieure**.

Les téléchargements GitHub représentent des fichiers téléchargés, pas des installations confirmées. Les installations vérifiées sont calculées séparément à partir des ouvertures anonymes remontées par l’application.

## Option : enrichir le tableau Admin avec GA4

Pour intégrer à terme des agrégats GA4 directement dans la fonction Supabase `get-admin-analytics`, ajouter les secrets suivants dans l’environnement des Edge Functions :

| Secret | Valeur attendue |
|---|---|
| `GA4_PROPERTY_ID` | Identifiant numérique de la propriété Google Analytics 4. |
| `GA4_SERVICE_ACCOUNT_JSON` | JSON complet du compte de service disposant d’un accès lecture à la propriété GA4. |

Ne jamais insérer le JSON du compte de service dans une application Android, dans Git ou dans un message de discussion. L’ajout de ces secrets reste facultatif : les statistiques Supabase présentes dans l’Admin fonctionnent indépendamment de GA4.

## Contrôle de confidentialité

La politique de confidentialité intégrée à Ouedna doit mentionner la mesure d’audience anonyme, sa finalité d’amélioration du service et l’absence de collecte volontaire de données personnelles par ce mécanisme. Toute évolution future, notamment l’ajout de données de localisation ou de profils identifiants, doit faire l’objet d’une révision juridique et d’une mise à jour explicite de cette politique.
