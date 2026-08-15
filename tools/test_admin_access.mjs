#!/usr/bin/env node

/**
 * Vérifie, exclusivement en lecture, qu'une session administrateur Ouedna peut
 * lire les ressources utilisées par le tableau de bord malgré les politiques RLS.
 *
 * Variables requises :
 *   OUEDNA_SUPABASE_ANON_KEY
 *   et soit OUEDNA_ADMIN_ACCESS_TOKEN, soit OUEDNA_TEST_ADMIN_EMAIL + OUEDNA_TEST_ADMIN_PASSWORD
 *
 * Variables facultatives :
 *   OUEDNA_SUPABASE_URL (défaut : production Ouedna)
 *   OUEDNA_EXPECTED_ADMIN_ROLE (défaut : admin)
 */

const DEFAULT_SUPABASE_URL = 'https://cwbenhuiextfoiyfboxo.supabase.co';
const DEFAULT_EXPECTED_ROLE = 'admin';
const REQUEST_TIMEOUT_MS = 15_000;
const DASHBOARD_TABLES = [
  'app_config',
  'feedback',
  'gallery',
  'memories',
  'places',
  'suggestions',
  'testimonials',
];

function required(name) {
  const value = process.env[name]?.trim();
  if (!value) {
    throw new Error(`La variable ${name} est requise.`);
  }
  return value;
}

function decodeJwtSubject(token) {
  try {
    const payload = token.split('.')[1];
    if (!payload) return null;
    const claims = JSON.parse(Buffer.from(payload, 'base64url').toString('utf8'));
    return typeof claims.sub === 'string' ? claims.sub : null;
  } catch {
    return null;
  }
}

function createUrl(baseUrl, pathname, query = {}) {
  const url = new URL(pathname, baseUrl);
  for (const [key, value] of Object.entries(query)) {
    url.searchParams.set(key, value);
  }
  return url;
}

async function request(url, options) {
  const response = await fetch(url, {
    ...options,
    signal: AbortSignal.timeout(REQUEST_TIMEOUT_MS),
  });
  const body = await response.text();
  let data = null;

  if (body) {
    try {
      data = JSON.parse(body);
    } catch {
      data = null;
    }
  }

  return { response, data };
}

function apiError(context, response, data) {
  const message = data?.message ?? data?.error_description ?? data?.hint ?? 'réponse sans détail exploitable';
  return new Error(`${context} a échoué (HTTP ${response.status}) : ${message}`);
}

async function authenticate({ supabaseUrl, anonKey }) {
  const suppliedToken = process.env.OUEDNA_ADMIN_ACCESS_TOKEN?.trim();
  if (suppliedToken) {
    const userId = decodeJwtSubject(suppliedToken);
    if (!userId) {
      throw new Error('OUEDNA_ADMIN_ACCESS_TOKEN ne contient pas un JWT Supabase valide.');
    }
    return { accessToken: suppliedToken, userId, mode: 'jeton existant' };
  }

  const email = required('OUEDNA_TEST_ADMIN_EMAIL');
  const password = required('OUEDNA_TEST_ADMIN_PASSWORD');
  const url = createUrl(supabaseUrl, '/auth/v1/token', { grant_type: 'password' });
  const { response, data } = await request(url, {
    method: 'POST',
    headers: {
      apikey: anonKey,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({ email, password }),
  });

  if (!response.ok || !data?.access_token || !data?.user?.id) {
    throw apiError('L’authentification du compte de test', response, data);
  }

  return { accessToken: data.access_token, userId: data.user.id, mode: 'identifiants de test' };
}

function restHeaders(anonKey, accessToken) {
  return {
    apikey: anonKey,
    Authorization: `Bearer ${accessToken}`,
    Prefer: 'count=exact',
  };
}

function totalFrom(response) {
  const contentRange = response.headers.get('content-range');
  const total = contentRange?.split('/')[1];
  return total && total !== '*' ? total : 'inconnu';
}

async function verifyProfile({ supabaseUrl, anonKey, accessToken, userId, expectedRole }) {
  const url = createUrl(supabaseUrl, '/rest/v1/admin_profiles', {
    select: 'id,role',
    id: `eq.${userId}`,
  });
  const { response, data } = await request(url, {
    headers: restHeaders(anonKey, accessToken),
  });

  if (!response.ok) {
    throw apiError('La lecture du profil administrateur', response, data);
  }

  if (!Array.isArray(data) || data.length !== 1 || data[0]?.role !== expectedRole) {
    throw new Error(`Le profil authentifié n’a pas le rôle attendu « ${expectedRole} » dans admin_profiles.`);
  }

  return { resource: 'admin_profiles', total: 1, status: response.status };
}

async function verifyTable({ table, supabaseUrl, anonKey, accessToken }) {
  const url = createUrl(supabaseUrl, `/rest/v1/${table}`, {
    select: 'id',
    limit: '1',
  });
  const { response, data } = await request(url, {
    headers: restHeaders(anonKey, accessToken),
  });

  if (!response.ok) {
    throw apiError(`La lecture de ${table}`, response, data);
  }

  if (!Array.isArray(data)) {
    throw new Error(`La lecture de ${table} a renvoyé un format inattendu.`);
  }

  return { resource: table, total: totalFrom(response), status: response.status };
}

async function main() {
  if (process.argv.includes('--help') || process.argv.includes('-h')) {
    console.log('Usage : node tools/test_admin_access.mjs');
    console.log('Consultez docs/admin-access-test.md pour la configuration.');
    return;
  }

  const supabaseUrl = (process.env.OUEDNA_SUPABASE_URL?.trim() || DEFAULT_SUPABASE_URL).replace(/\/$/, '');
  const anonKey = required('OUEDNA_SUPABASE_ANON_KEY');
  const expectedRole = process.env.OUEDNA_EXPECTED_ADMIN_ROLE?.trim() || DEFAULT_EXPECTED_ROLE;
  const session = await authenticate({ supabaseUrl, anonKey });

  const results = [];
  results.push(
    await verifyProfile({
      supabaseUrl,
      anonKey,
      accessToken: session.accessToken,
      userId: session.userId,
      expectedRole,
    }),
  );

  for (const table of DASHBOARD_TABLES) {
    results.push(await verifyTable({ table, supabaseUrl, anonKey, accessToken: session.accessToken }));
  }

  console.log(`Accès administrateur validé avec ${session.mode}.`);
  console.table(results);
}

main().catch((error) => {
  console.error(`ÉCHEC — ${error.message}`);
  process.exitCode = 1;
});
