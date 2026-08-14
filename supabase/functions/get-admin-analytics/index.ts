import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });

const repository = "nadjimyahiaoui1992-lab/souf-tour";
const cacheKey = "github_release_asset_downloads";
const cacheLifetimeMs = 15 * 60 * 1000;

const isoDaysAgo = (days: number) =>
  new Date(Date.now() - days * 24 * 60 * 60 * 1000).toISOString();

async function isAdmin(
  supabase: ReturnType<typeof createClient>,
  authorization: string | null,
) {
  const token = authorization?.replace(/^Bearer\s+/i, "").trim();
  if (!token) return false;
  const { data: userData, error: userError } = await supabase.auth.getUser(token);
  if (userError || !userData.user) return false;
  const { data: profile, error: profileError } = await supabase
    .from("admin_profiles")
    .select("id")
    .eq("id", userData.user.id)
    .maybeSingle();
  return !profileError && profile != null;
}

async function getGithubDownloads(
  supabase: ReturnType<typeof createClient>,
) {
  const { data: cached } = await supabase
    .from("analytics_release_cache")
    .select("metric_value,payload,fetched_at")
    .eq("cache_key", cacheKey)
    .maybeSingle();

  const cachedAt = cached?.fetched_at ? Date.parse(cached.fetched_at) : 0;
  if (cachedAt && Date.now() - cachedAt < cacheLifetimeMs) {
    return {
      total: Number(cached.metric_value ?? 0),
      fetchedAt: cached.fetched_at,
      source: "cache",
    };
  }

  const response = await fetch(
    `https://api.github.com/repos/${repository}/releases?per_page=100`,
    {
      headers: {
        Accept: "application/vnd.github+json",
        "User-Agent": "Ouedna-Admin-Analytics",
      },
    },
  );
  if (!response.ok) {
    // Le dernier cache reste utilisable même si GitHub atteint une limite.
    if (cached) {
      return {
        total: Number(cached.metric_value ?? 0),
        fetchedAt: cached.fetched_at,
        source: "stale_cache",
      };
    }
    throw new Error(`github_status_${response.status}`);
  }

  const releases = await response.json();
  const assets = Array.isArray(releases)
    ? releases.flatMap((release) =>
        Array.isArray(release?.assets) ? release.assets : [],
      )
    : [];
  const ouednaAssets = assets.filter(
    (asset) => typeof asset?.name === "string" && asset.name.endsWith(".apk"),
  );
  const total = ouednaAssets.reduce(
    (sum, asset) => sum + Number(asset?.download_count ?? 0),
    0,
  );
  const now = new Date().toISOString();
  await supabase.from("analytics_release_cache").upsert(
    {
      cache_key: cacheKey,
      metric_value: total,
      payload: { asset_count: ouednaAssets.length, repository },
      fetched_at: now,
      updated_at: now,
    },
    { onConflict: "cache_key" },
  );
  return { total, fetchedAt: now, source: "github" };
}

Deno.serve(async (request) => {
  if (request.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  if (request.method !== "POST") {
    return json({ error: "method_not_allowed" }, 405);
  }

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
    if (!supabaseUrl || !serviceRoleKey) {
      return json({ error: "server_configuration_error" }, 500);
    }
    const supabase = createClient(supabaseUrl, serviceRoleKey, {
      auth: { autoRefreshToken: false, persistSession: false },
    });
    if (!(await isAdmin(supabase, request.headers.get("authorization")))) {
      return json({ error: "forbidden" }, 403);
    }

    const today = new Date().toISOString().slice(0, 10);
    const [installations, dau, wau, recentInstalls, github] = await Promise.all([
      supabase.from("app_installations").select("installation_id", { count: "exact", head: true }),
      supabase
        .from("app_activity_daily")
        .select("installation_id", { count: "exact", head: true })
        .eq("activity_date", today),
      supabase
        .from("app_activity_daily")
        .select("installation_id", { count: "exact", head: true })
        .gte("activity_date", isoDaysAgo(6).slice(0, 10)),
      supabase
        .from("app_installations")
        .select("installation_id", { count: "exact", head: true })
        .gte("first_seen_at", isoDaysAgo(30)),
      getGithubDownloads(supabase),
    ]);

    for (const result of [installations, dau, wau, recentInstalls]) {
      if (result.error) throw result.error;
    }

    const firebaseAnalyticsReady = Boolean(
      Deno.env.get("GA4_PROPERTY_ID") &&
        Deno.env.get("GA4_SERVICE_ACCOUNT_JSON"),
    );

    return json({
      installations: installations.count ?? 0,
      daily_active_users: dau.count ?? 0,
      weekly_active_users: wau.count ?? 0,
      new_installations_30d: recentInstalls.count ?? 0,
      github_asset_downloads: github.total,
      github_downloads_fetched_at: github.fetchedAt,
      github_downloads_source: github.source,
      firebase_analytics_ready: firebaseAnalyticsReady,
      generated_at: new Date().toISOString(),
    });
  } catch (error) {
    console.error("get-admin-analytics", error);
    return json({ error: "unable_to_load_analytics" }, 500);
  }
});
