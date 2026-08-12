import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.8";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Content-Type": "application/json; charset=utf-8",
};

const allowedCategories = new Set([
  "معلم طبيعي",
  "معلم ديني",
  "معلم تراثي",
  "مرافق صحية",
  "مطاعم",
  "فنادق ومنتجعات",
  "أسواق",
  "متاجر ومحلات",
]);
const allowedImageExtensions = new Set(["jpg", "jpeg", "png", "webp"]);
const maxImageBytes = 4 * 1024 * 1024;
const maxRequestsPerDay = 3;
const rateLimitWindowSeconds = 24 * 60 * 60;

type SubmissionPayload = {
  name?: unknown;
  main_category?: unknown;
  sub_category?: unknown;
  description?: unknown;
  address?: unknown;
  municipality?: unknown;
  phone?: unknown;
  map_link?: unknown;
  opening_hours?: unknown;
  image_base64?: unknown;
  image_file_name?: unknown;
};

Deno.serve(async (request) => {
  if (request.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  if (request.method !== "POST") {
    return json({ error: "method_not_allowed" }, 405);
  }

  const contentLength = Number(request.headers.get("content-length") ?? "0");
  if (Number.isFinite(contentLength) && contentLength > 6 * 1024 * 1024) {
    return json({ error: "payload_too_large" }, 413);
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!supabaseUrl || !serviceRoleKey) {
    return json({ error: "server_configuration_error" }, 503);
  }

  let payload: SubmissionPayload;
  try {
    payload = await request.json();
  } catch {
    return json({ error: "invalid_json" }, 400);
  }

  const name = safeText(payload.name, 120);
  const mainCategory = safeText(payload.main_category, 80);
  if (!name || !allowedCategories.has(mainCategory)) {
    return json({ error: "invalid_submission" }, 400);
  }

  const mapLink = safeText(payload.map_link, 400);
  if (mapLink && !isHttpUrl(mapLink)) {
    return json({ error: "invalid_map_link" }, 400);
  }

  const clientIp = request.headers.get("x-forwarded-for")?.split(",")[0].trim() ||
    request.headers.get("x-real-ip") ||
    "anonymous";
  const clientKey = await hashClientKey(clientIp);
  const serviceClient = createClient(supabaseUrl, serviceRoleKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });

  const { data: permitted, error: rateLimitError } = await serviceClient.rpc(
    "consume_visitor_place_submission",
    {
      p_client_key: clientKey,
      p_window_seconds: rateLimitWindowSeconds,
      p_max_requests: maxRequestsPerDay,
    },
  );
  if (rateLimitError || permitted !== true) {
    return json(
      {
        error: "rate_limited",
        message: "لقد بلغت حد إرسال الاقتراحات اليومي. حاول مجدداً خلال 24 ساعة.",
      },
      429,
    );
  }

  let imageUrl: string | null = null;
  let uploadedPath: string | null = null;
  try {
    const image = decodeImage(payload.image_base64, payload.image_file_name);
    if (image) {
      const random = crypto.randomUUID().replace(/-/g, "");
      uploadedPath = `places/visitor/${new Date().toISOString().slice(0, 10)}/${random}.${image.extension}`;
      const { error: uploadError } = await serviceClient.storage
        .from("images")
        .upload(uploadedPath, image.bytes, {
          contentType: image.contentType,
          upsert: false,
        });
      if (uploadError) return json({ error: "image_upload_failed" }, 503);
      imageUrl = serviceClient.storage.from("images").getPublicUrl(uploadedPath).data.publicUrl;
    }

    const { data, error: insertError } = await serviceClient
      .from("places")
      .insert({
        name,
        main_category: mainCategory,
        sub_category: optionalText(payload.sub_category, 80),
        description: optionalText(payload.description, 1200),
        address: optionalText(payload.address, 160),
        municipality: optionalText(payload.municipality, 100),
        phone: optionalText(payload.phone, 40),
        map_link: mapLink || null,
        opening_hours: optionalText(payload.opening_hours, 160),
        image_url: imageUrl,
        status: "قيد المراجعة",
      })
      .select("id")
      .single();

    if (insertError || !data?.id) {
      if (uploadedPath) await serviceClient.storage.from("images").remove([uploadedPath]);
      return json({ error: "submission_failed" }, 503);
    }

    return json({ id: data.id, status: "قيد المراجعة" }, 201);
  } catch (error) {
    if (uploadedPath) await serviceClient.storage.from("images").remove([uploadedPath]);
    return json(
      { error: "invalid_submission", message: error instanceof Error ? error.message : undefined },
      400,
    );
  }
});

function decodeImage(value: unknown, fileName: unknown): {
  bytes: Uint8Array;
  extension: string;
  contentType: string;
} | null {
  if (value == null || value === "") return null;
  if (typeof value !== "string") throw new Error("invalid_image");
  const extension = typeof fileName === "string"
    ? fileName.trim().split(".").pop()?.toLowerCase() ?? ""
    : "";
  if (!allowedImageExtensions.has(extension)) throw new Error("unsupported_image_type");

  const binary = atob(value);
  if (binary.length === 0 || binary.length > maxImageBytes) {
    throw new Error("invalid_image_size");
  }
  const bytes = Uint8Array.from(binary, (character) => character.charCodeAt(0));
  return {
    bytes,
    extension,
    contentType: extension === "jpg" || extension === "jpeg" ? "image/jpeg" : `image/${extension}`,
  };
}

function optionalText(value: unknown, limit: number): string | null {
  const text = safeText(value, limit);
  return text || null;
}

function safeText(value: unknown, limit: number): string {
  return typeof value === "string"
    ? value.replace(/[\u0000-\u001F]/g, " ").trim().slice(0, limit)
    : "";
}

function isHttpUrl(value: string): boolean {
  try {
    const url = new URL(value);
    return url.protocol === "https:" || url.protocol === "http:";
  } catch {
    return false;
  }
}

async function hashClientKey(value: string): Promise<string> {
  const digest = await crypto.subtle.digest(
    "SHA-256",
    new TextEncoder().encode(`souf360-place-submission:${value}`),
  );
  return Array.from(new Uint8Array(digest), (byte) => byte.toString(16).padStart(2, "0")).join("");
}

function json(body: Record<string, unknown>, status: number): Response {
  return new Response(JSON.stringify(body), { status, headers: corsHeaders });
}
