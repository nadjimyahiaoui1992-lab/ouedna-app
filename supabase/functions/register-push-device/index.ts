import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { corsHeadersFor, trustedClientKey } from "../_shared/publicEndpoint.ts";

const deviceTokenPattern = /^[A-Za-z0-9:_-]{32,4096}$/;

Deno.serve(async (request) => {
  const corsHeaders = corsHeadersFor(request);
  const json = (body: unknown, status = 200) =>
    new Response(JSON.stringify(body), { status, headers: corsHeaders });
  if (request.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (request.method !== "POST") return json({ error: "method_not_allowed" }, 405);

  try {
    const body = await request.json();
    const token = typeof body?.token === "string" ? body.token.trim() : "";
    const platform = body?.platform === "ios" ? "ios" : "android";
    const languageCode = ["ar", "fr", "en"].includes(body?.language_code)
      ? body.language_code
      : "ar";
    const appVersion = typeof body?.app_version === "string"
      ? body.app_version.trim().slice(0, 48)
      : null;

    if (!deviceTokenPattern.test(token)) {
      return json({ error: "invalid_device_token" }, 400);
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
        p_scope: "push-device-registration",
        p_client_key: await trustedClientKey(request),
        p_window_seconds: 3600,
        p_max_requests: 30,
      },
    );
    if (rateLimitError || permitted !== true) {
      return json({ error: "rate_limited", retry_after_seconds: 3600 }, 429);
    }
    const { error } = await supabase.from("push_devices").upsert(
      {
        token,
        platform,
        app_version: appVersion,
        language_code: languageCode,
        last_seen_at: new Date().toISOString(),
        updated_at: new Date().toISOString(),
      },
      { onConflict: "token" },
    );
    if (error) throw error;

    return json({ registered: true });
  } catch (error) {
    console.error("register-push-device", error);
    return json({ error: "unable_to_register_device" }, 500);
  }
});
