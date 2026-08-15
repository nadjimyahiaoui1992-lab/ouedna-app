# Suivi — validation d’accès administrateur

- [x] Définir les contrôles RLS exécutés sous une session administrateur simulée.
- [x] Créer un script de test en lecture seule et sans secret dans le dépôt.
- [ ] Exécuter le script contre Supabase et vérifier son code de sortie.
- [x] Documenter les variables requises et la commande d’utilisation.
- [x] Versionner et publier le script de contrôle.

## Mise à jour publique de l’application Ouedna

- [ ] Auditer les écrans publics et les modèles Supabase concernés par l’archive enrichie.
- [x] Ajouter le support des dates documentées et des galeries d’images dans l’archive visiteur.
- [x] Mettre à jour la version Android et vérifier les autorisations réellement utilisées.
- [ ] Rechercher de façon sûre les sauvegardes du keystore et des paramètres de signature d’origine.
- [ ] Exécuter l’analyse Flutter, les tests et la construction APK release.
- [ ] Publier le code source et livrer l’APK vérifié.

## Édition autonome Ouedna v2

- [x] Vérifier toutes les références Android, Firebase et liens profonds liées au package actuel.
- [x] Migrer l’édition autonome vers `com.ouedna.app.v2` et préparer le parcours de transition utilisateur.
- [x] Créer un nouveau keystore et configurer son circuit de signature sans l’ajouter au dépôt.
- [x] Enregistrer l’application Android v2 dans Firebase et intégrer son fichier de configuration sécurisé.
- [x] Construire, signer, vérifier et publier l’APK autonome avec les instructions d’installation.

## Publication depuis la console d’administration

- [ ] Vérifier la structure des mises à jour et notifications administrables existantes.
- [ ] Publier la fiche Ouedna الجديدة 2.1.1 avec le lien APK et le message de transition.
- [ ] Vérifier son affichage dans l’application Ouedna Admin.

## Gestion d’archives avec téléversement direct

- [x] Auditer les tables d’archive, les buckets Storage et les politiques RLS applicables.
- [x] Créer ou sécuriser le bucket dédié aux images d’archive avec validation de type et taille.
- [x] Ajouter la création et l’édition d’une archive avec sélection de plusieurs photos dans Ouedna Admin.
- [x] Enregistrer automatiquement les URLs publiques et le contenu de galerie dans Supabase.
- [x] Vérifier l’affichage des photos d’archive publiées dans l’application visiteur.
- [x] Tester et publier les mises à jour versionnées des applications concernées.

## Publication APK Ouedna Admin

- [x] Auditer le workflow, les secrets de signature et l’identité de l’application administrateur.
- [x] Confirmer que la transition requiert une application indépendante car l’APK historique est signé avec une clé debug indisponible.
- [x] Créer l’identité `com.ouedna.admin.v2` et la configuration Android de Ouedna Admin 2.
- [x] Créer une clé de release dédiée et un pipeline GitHub Actions sécurisé.
- [x] Autoriser l’enregistrement des secrets GitHub de signature pour le dépôt Ouedna Admin.
- [x] Construire, signer et vérifier l’APK Ouedna Admin 2 avec la gestion d’archives par upload direct.
- [x] Publier la release et remettre le lien d’installation.
- [x] Diagnostiquer et corriger le lien direct 404 de la release Ouedna Admin 2.

## Palette Dunes et Oasis — site et applications

- [x] Auditer les thèmes et constantes de couleur du site, de l’application visiteur et de l’administration.
- [x] Définir des jetons communs inspirés du sable, de l’argile, de l’oasis et du coucher de soleil.
- [x] Appliquer la palette aux surfaces, actions, états, cartes et éléments de navigation des trois interfaces.
- [x] Vérifier les contrastes, les analyses Flutter et les builds avant publication.
