import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.8";

const corsHeaders = {
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Content-Type": "application/json; charset=utf-8",
};

const maxRequestsPerWindow = 30;
const windowSeconds = 600;
const graphHopperEndpoint = "https://graphhopper.com/api/1/route";

type RoutingPayload = {
  place_id?: unknown;
  origin?: unknown;
  mode?: unknown;
  alternatives?: unknown;
};

type Point = { lat: number; lng: number };

Deno.serve(async (request) => {
  if (request.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (request.method !== "POST") return json({ error: "method_not_allowed" }, 405);

  const authorization = request.headers.get("Authorization");
  if (!authorization?.startsWith("Bearer ")) return json({ error: "unauthorized" }, 401);

  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY");
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  const graphHopperKey = Deno.env.get("GRAPHHOPPER_API_KEY");
  if (!supabaseUrl || !supabaseAnonKey || !serviceRoleKey) {
    return json({ error: "server_configuration_error" }, 503);
  }
  // Do not attempt a network request or fabricate a route while the provider
  // is intentionally unconfigured. The client presents an explicit state.
  if (!graphHopperKey) return json({ error: "routing_not_configured" }, 503);

  const userClient = createClient(supabaseUrl, supabaseAnonKey, {
    global: { headers: { Authorization: authorization } },
    auth: { persistSession: false, autoRefreshToken: false },
  });
  const { data: userData, error: userError } = await userClient.auth.getUser();
  if (userError || !userData.user) return json({ error: "unauthorized" }, 401);

  let payload: RoutingPayload;
  try {
    payload = await request.json();
  } catch {
    return json({ error: "invalid_json" }, 400);
  }

  const placeId = toPositiveInteger(payload.place_id);
  const origin = toPoint(payload.origin);
  const mode = toMode(payload.mode);
  const alternatives = payload.alternatives === true;
  if (!placeId || !origin || !mode) return json({ error: "invalid_request" }, 400);
  if (!isWithinAlgeria(origin)) return json({ error: "origin_out_of_region" }, 400);

  const serviceClient = createClient(supabaseUrl, serviceRoleKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });
  const { data: permitted, error: rateLimitError } = await serviceClient.rpc(
    "consume_public_endpoint_request",
    {
      p_scope: "routing",
      p_client_key: `user:${userData.user.id}`,
      p_window_seconds: windowSeconds,
      p_max_requests: maxRequestsPerWindow,
    },
  );
  if (rateLimitError || permitted !== true) return json({ error: "rate_limited" }, 429);

  const { data: place, error: placeError } = await serviceClient
    .from("places")
    .select("id,lat,lng")
    .eq("id", placeId)
    .eq("status", "منشور")
    .maybeSingle();
  if (placeError) return json({ error: "destination_unavailable" }, 503);

  const destination = toPoint({ lat: place?.lat, lng: place?.lng });
  if (!destination) return json({ error: "destination_unavailable" }, 422);

  const graphHopperResponse = await fetch(`${graphHopperEndpoint}?key=${encodeURIComponent(graphHopperKey)}`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      profile: mode,
      points: [
        [origin.lng, origin.lat],
        [destination.lng, destination.lat],
      ],
      points_encoded: false,
      instructions: true,
      locale: "en",
      algorithm: alternatives ? "alternative_route" : undefined,
      "alternative_route.max_paths": alternatives ? 2 : undefined,
    }),
  });

  if (!graphHopperResponse.ok) {
    const details = await graphHopperResponse.text();
    if (graphHopperResponse.status === 429) return json({ error: "provider_rate_limited" }, 429);
    if (graphHopperResponse.status >= 400 && graphHopperResponse.status < 500) {
      return json({ error: "no_route" }, 422);
    }
    console.error("GraphHopper error", graphHopperResponse.status, details.slice(0, 500));
    return json({ error: "routing_unavailable" }, 503);
  }

  try {
    const graphHopperBody = await graphHopperResponse.json();
    const routes = parsePaths(graphHopperBody?.paths);
    if (routes.length === 0) return json({ error: "no_route" }, 422);
    return json({ origin, destination, routes }, 200);
  } catch (error) {
    console.error("Routing response parse error", error);
    return json({ error: "routing_unavailable" }, 503);
  }
});

function parsePaths(rawPaths: unknown): Record<string, unknown>[] {
  if (!Array.isArray(rawPaths)) return [];
  return rawPaths.slice(0, 3).flatMap((path) => {
    if (!path || typeof path !== "object") return [];
    const value = path as Record<string, unknown>;
    const coordinates = (value.points as { coordinates?: unknown } | undefined)?.coordinates;
    if (!Array.isArray(coordinates)) return [];
    const geometry = coordinates.flatMap((coordinate) => {
      if (!Array.isArray(coordinate) || coordinate.length < 2) return [];
      const lng = Number(coordinate[0]);
      const lat = Number(coordinate[1]);
      return Number.isFinite(lat) && Number.isFinite(lng) ? [{ lat, lng }] : [];
    });
    if (geometry.length < 2) return [];
    const instructions = Array.isArray(value.instructions) ? value.instructions : [];
    const steps = instructions.slice(0, 80).flatMap((instruction) => {
      if (!instruction || typeof instruction !== "object") return [];
      const step = instruction as Record<string, unknown>;
      return [{
        distance_meters: safeNumber(step.distance),
        duration_seconds: safeNumber(step.time) / 1000,
        maneuver: maneuverFromSign(safeNumber(step.sign)),
        end_geometry_index: endGeometryIndex(step.interval),
        street_name: typeof step.street_name === "string" && step.street_name.trim()
          ? step.street_name.trim().slice(0, 160)
          : undefined,
      }];
    });
    return [{
      distance_meters: safeNumber(value.distance),
      duration_seconds: safeNumber(value.time) / 1000,
      geometry,
      steps,
    }];
  });
}

function endGeometryIndex(value: unknown): number {
  if (!Array.isArray(value) || value.length < 2) return 0;
  const index = Number(value[1]);
  return Number.isInteger(index) && index >= 0 ? index : 0;
}

function maneuverFromSign(sign: number): string {
  if (sign === 4) return "arrive";
  if (sign === -2) return "left";
  if (sign === 2) return "right";
  if (sign === -3) return "slight_left";
  if (sign === 3) return "slight_right";
  if (sign === -1) return "sharp_left";
  if (sign === 1) return "sharp_right";
  if (sign === -98 || sign === 98) return "u_turn";
  if (sign === 5 || sign === 6) return "roundabout";
  return "continue";
}

function toPositiveInteger(value: unknown): number | null {
  const parsed = typeof value === "number" ? value : Number(value);
  return Number.isInteger(parsed) && parsed > 0 && parsed <= 2147483647 ? parsed : null;
}

function toPoint(value: unknown): Point | null {
  if (!value || typeof value !== "object") return null;
  const input = value as Record<string, unknown>;
  const lat = Number(input.lat);
  const lng = Number(input.lng);
  if (!Number.isFinite(lat) || !Number.isFinite(lng) || Math.abs(lat) > 90 || Math.abs(lng) > 180) return null;
  return { lat, lng };
}

function toMode(value: unknown): "car" | "foot" | "bike" | null {
  return value === "car" || value === "foot" || value === "bike" ? value : null;
}

function isWithinAlgeria(point: Point): boolean {
  // The visitor location is transient and is never stored. A broad country
  // bound reduces abuse of the protected provider endpoint.
  return point.lat >= 18 && point.lat <= 38 && point.lng >= -9 && point.lng <= 13;
}

function safeNumber(value: unknown): number {
  const parsed = Number(value);
  return Number.isFinite(parsed) && parsed >= 0 ? parsed : 0;
}

function json(body: Record<string, unknown>, status: number): Response {
  return new Response(JSON.stringify(body), { status, headers: corsHeaders });
}
