import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { corsHeadersFor, trustedClientKey } from "../_shared/publicEndpoint.ts";

const uuidPattern =
  /^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;

Deno.serve(async (request) => {
  const corsHeaders = corsHeadersFor(request);
  const json = (body: unknown, status = 200) =>
    new Response(JSON.stringify(body), { status, headers: corsHeaders });
  if (request.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  if (request.method !== "POST") {
    return json({ error: "method_not_allowed" }, 405);
  }

  try {
    const body = await request.json();
    const installationId =
      typeof body?.installation_id === "string"
        ? body.installation_id.trim()
        : "";
    const appVersion =
      typeof body?.app_version === "string"
        ? body.app_version.trim().slice(0, 48)
        : null;
    const localeCode = ["ar", "fr", "en"].includes(body?.locale_code)
      ? body.locale_code
      : "ar";

    if (!uuidPattern.test(installationId)) {
      return json({ error: "invalid_installation_id" }, 400);
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
    if (!supabaseUrl || !serviceRoleKey) {
      return json({ error: "server_configuration_error" }, 500);
    }

    const supabase = createClient(supabaseUrl, serviceRoleKey, {
      auth: { autoRefreshToken: false, persistSession: false },
    });
    const { data: permitted, error: rateLimitError } = await supabase.rpc(
      "consume_public_endpoint_request",
      {
        p_scope: "app-activity",
        p_client_key: await trustedClientKey(request),
        p_window_seconds: 3600,
        p_max_requests: 120,
      },
    );
    if (rateLimitError || permitted !== true) {
      return json({ error: "rate_limited", retry_after_seconds: 3600 }, 429);
    }
    const now = new Date().toISOString();
    const activityDate = now.slice(0, 10);

    // first_seen_at est uniquement défini à l'insertion ; le conflit ne met à
    // jour que les champs ci-dessous et préserve donc la date d'installation.
    const { error: installationError } = await supabase
      .from("app_installations")
      .upsert(
        {
          installation_id: installationId,
          last_seen_at: now,
          updated_at: now,
          app_version: appVersion,
          platform: "android",
          locale_code: localeCode,
        },
        { onConflict: "installation_id" },
      );
    if (installationError) throw installationError;

    // Une seule présence par installation et par jour UTC : les indicateurs
    // DAU/WAU sont des décomptes distincts et non des clics artificiels.
    const { error: activityError } = await supabase
      .from("app_activity_daily")
      .upsert(
        {
          installation_id: installationId,
          activity_date: activityDate,
          app_version: appVersion,
        },
        { onConflict: "installation_id,activity_date", ignoreDuplicates: true },
      );
    if (activityError) throw activityError;

    return json({ recorded: true, activity_date: activityDate });
  } catch (error) {
    console.error("track-app-activity", error);
    return json({ error: "unable_to_record_activity" }, 500);
  }
});
