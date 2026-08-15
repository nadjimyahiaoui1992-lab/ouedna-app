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
- [ ] Enregistrer l’application Android v2 dans Firebase et intégrer son fichier de configuration sécurisé.
- [ ] Construire, signer, vérifier et publier l’APK autonome avec les instructions d’installation.
