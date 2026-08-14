const allowedOrigins = new Set([
  "https://ouedna.vercel.app",
  "https://souf360.vercel.app",
]);

export function corsHeadersFor(request: Request): Record<string, string> {
  const origin = request.headers.get("origin");
  const allowedOrigin = origin && allowedOrigins.has(origin)
    ? origin
    : "https://ouedna.vercel.app";

  return {
    "Access-Control-Allow-Origin": allowedOrigin,
    "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
    "Access-Control-Allow-Methods": "POST, OPTIONS",
    "Content-Type": "application/json; charset=utf-8",
    "Vary": "Origin",
  };
}

export async function trustedClientKey(request: Request): Promise<string> {
  const forwardedFor = request.headers.get("x-forwarded-for");
  const clientAddress = forwardedFor?.split(",")[0]?.trim() || "unknown";
  const digest = await crypto.subtle.digest(
    "SHA-256",
    new TextEncoder().encode(clientAddress),
  );
  return Array.from(new Uint8Array(digest))
    .map((byte) => byte.toString(16).padStart(2, "0"))
    .join("");
}
