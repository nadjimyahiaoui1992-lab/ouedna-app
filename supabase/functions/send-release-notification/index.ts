import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { GoogleAuth } from "npm:google-auth-library@9.15.1";
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
    const authHeader = request.headers.get("Authorization");
    if (!authHeader) return json({ error: "unauthorized" }, 401);

    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
    const firebaseProjectId = Deno.env.get("FIREBASE_PROJECT_ID");
    const serviceAccountRaw = Deno.env.get("FIREBASE_SERVICE_ACCOUNT_JSON");
    if (!supabaseUrl || !serviceRoleKey || !firebaseProjectId || !serviceAccountRaw) {
      return json({ error: "push_provider_not_configured" }, 503);
    }

    const supabase = createClient(supabaseUrl, serviceRoleKey, {
      auth: { autoRefreshToken: false, persistSession: false },
    });
    const accessToken = authHeader.replace(/^Bearer\s+/i, "");
    const { data: authData, error: authError } = await supabase.auth.getUser(accessToken);
    if (authError || !authData.user) return json({ error: "unauthorized" }, 401);

    const { data: profile } = await supabase
      .from("admin_profiles")
      .select("id, role")
      .eq("id", authData.user.id)
      .maybeSingle();
    if (!profile || !["admin", "supervisor"].includes(profile.role)) {
      return json({ error: "forbidden" }, 403);
    }

    const body = await request.json();
    const releaseVersion = typeof body?.release_version === "string"
      ? body.release_version.trim().slice(0, 48)
      : "";
    const title = typeof body?.title === "string" ? body.title.trim().slice(0, 120) : "";
    const message = typeof body?.body === "string" ? body.body.trim().slice(0, 500) : "";
    if (!releaseVersion || !title || !message) {
      return json({ error: "invalid_notification_payload" }, 400);
    }

    const { data: log, error: logError } = await supabase
      .from("release_notification_log")
      .insert({
        release_version: releaseVersion,
        title,
        body: message,
        sent_by: authData.user.id,
        status: "queued",
      })
      .select("id")
      .single();
    if (logError) throw logError;

    const { data: devices, error: devicesError } = await supabase
      .from("push_devices")
      .select("token")
      .eq("platform", "android")
      .limit(5000);
    if (devicesError) throw devicesError;

    const serviceAccount = JSON.parse(serviceAccountRaw);
    const auth = new GoogleAuth({
      credentials: serviceAccount,
      scopes: ["https://www.googleapis.com/auth/firebase.messaging"],
    });
    const client = await auth.getClient();
    const tokenResponse = await client.getAccessToken();
    const bearerToken = tokenResponse.token;
    if (!bearerToken) throw new Error("unable_to_obtain_fcm_access_token");

    let sent = 0;
    let failures = 0;
    const invalidTokens: string[] = [];
    for (const device of devices ?? []) {
      const response = await fetch(
        `https://fcm.googleapis.com/v1/projects/${firebaseProjectId}/messages:send`,
        {
          method: "POST",
          headers: {
            Authorization: `Bearer ${bearerToken}`,
            "Content-Type": "application/json",
          },
          body: JSON.stringify({
            message: {
              token: device.token,
              notification: { title, body: message },
              data: { type: "app_update", release_version: releaseVersion },
              android: {
                priority: "high",
                notification: { channel_id: "ouedna_updates", sound: "default" },
              },
            },
          }),
        },
      );
      if (response.ok) {
        sent += 1;
      } else {
        failures += 1;
        if (["UNREGISTERED", "INVALID_ARGUMENT"].some((needle) => (await response.text()).includes(needle))) {
          invalidTokens.push(device.token);
        }
      }
    }

    if (invalidTokens.length > 0) {
      await supabase.from("push_devices").delete().in("token", invalidTokens);
    }
    const status = failures === 0 ? "sent" : sent > 0 ? "partial" : "failed";
    await supabase
      .from("release_notification_log")
      .update({
        recipient_count: sent,
        status,
        error_message: failures > 0 ? `${failures} devices could not receive the message` : null,
      })
      .eq("id", log.id);

    return json({ sent, failures, status });
  } catch (error) {
    console.error("send-release-notification", error);
    return json({ error: "unable_to_send_release_notification" }, 500);
  }
});
