# Test automatisé d’accès administrateur

Le script `tools/test_admin_access.mjs` vérifie **en lecture seule** qu’un compte doté du rôle `admin` peut accéder aux ressources utilisées par l’application Ouedna Admin. Il valide d’abord le profil du compte connecté dans `admin_profiles`, puis interroge les données de configuration, les lieux, la galerie, les avis, les souvenirs, les retours et les suggestions. Aucun enregistrement n’est créé, modifié ou supprimé.

## Exécution locale

Le script s’exécute avec Node.js 18 ou une version ultérieure. Préparez les variables d’environnement sans les enregistrer dans Git. L’URL Supabase est déjà définie sur la production Ouedna ; elle peut être remplacée pour un environnement de test.

```bash
export OUEDNA_SUPABASE_ANON_KEY='clé-publique-supabase'
export OUEDNA_TEST_ADMIN_EMAIL='compte-admin-de-test@example.com'
export OUEDNA_TEST_ADMIN_PASSWORD='mot-de-passe-du-compte-de-test'
node tools/test_admin_access.mjs
```

Pour un contrôle ponctuel avec une session déjà ouverte, utilisez à la place un jeton d’accès temporaire. Le script décode uniquement son identifiant de sujet localement et ne l’affiche jamais.

```bash
export OUEDNA_SUPABASE_ANON_KEY='clé-publique-supabase'
export OUEDNA_ADMIN_ACCESS_TOKEN='jeton-d-acces-temporaire'
node tools/test_admin_access.mjs
```

Le résultat est un code de sortie `0` en cas de succès et `1` lorsqu’une authentification, un rôle ou une lecture RLS échoue. La sortie ne contient ni jeton, ni mot de passe, ni contenu métier des tables.

## Exécution dans GitHub Actions

Le workflow manuel `.github/workflows/admin-access-test.yml` est volontairement séparé de la CI standard : il ne s’exécute ni sur les pull requests ni sur les commits, afin que les identifiants de test ne soient utilisés que sur demande.

Configurez les trois secrets du dépôt suivants : `OUEDNA_SUPABASE_ANON_KEY`, `OUEDNA_TEST_ADMIN_EMAIL` et `OUEDNA_TEST_ADMIN_PASSWORD`. Utilisez un **compte administrateur de test dédié**, jamais le compte personnel du propriétaire. Lancez ensuite le workflow **Admin access RLS check** depuis l’onglet Actions.

> Le compte de test doit avoir une ligne `admin_profiles` avec `role = 'admin'`. Si le rôle ou les politiques RLS changent, adaptez `OUEDNA_EXPECTED_ADMIN_ROLE` dans le workflow ou l’environnement local.
