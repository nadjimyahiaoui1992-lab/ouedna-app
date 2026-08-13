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

Deno.serve(async (request) => {
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

    if (token.length < 32 || token.length > 4096) {
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
