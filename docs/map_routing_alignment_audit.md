# Souf360 map and routing alignment audit

Date: 2026-08-12

## Verified website behaviour

The public Souf360 map at `https://souf360.vercel.app/map` uses Leaflet with OpenStreetMap tiles and queries the shared Supabase project `cwbenhuiextfoiyfboxo` for places. Its location controls use the browser Geolocation API:

- `navigator.geolocation.getCurrentPosition(...)` for a user-triggered current-location action;
- `navigator.geolocation.watchPosition(...)` for optional live tracking;
- high accuracy enabled, 10-second maximum cached position age, and a 5-second location request timeout.

The released web bundle contains no GraphHopper, OSRM, OpenRouteService, `geo:` URI, Google Maps URL, or in-app road-routing endpoint. The text translated as "View details & directions" is a navigation label for the platform experience, not proof of a road-routing provider.

## Android diagnosis

The Android app currently injects `SupabaseRoutingService` only after anonymous authentication. This service invokes the Supabase `routing` Edge Function. That function requires the `GRAPHHOPPER_API_KEY` secret; without it the app receives `routing_not_configured` and displays the user-facing unavailable-service card visible in the supplied screenshot.

The supplied map screenshot separately shows `خدمة تحديد الموقع غير مفعلة على الجهاز.` This is the app correctly reporting that Android system location is disabled. The manifest already contains foreground coarse and fine location permissions, but the UI has no direct action to open the device location settings and the one-shot request lacks a bounded timeout.

## Verified direct routing fallback

A live test of OSRM's public route endpoint for an El Oued coordinate pair returned `{"code":"Ok"}` together with route geometry and step data. The application can therefore call a keyless direct routing adapter to provide line geometry, distances, duration, turn steps and rerouting independently of the optional GraphHopper/Supabase Edge Function.

## Required correction

1. Inject a direct `OsrmRoutingService` by default, not the GraphHopper-dependent service.
2. Preserve the Supabase service source as an optional server-managed alternative.
3. Add a native external maps action as a dependable fallback.
4. Give location failures explicit recovery actions: device Location settings for a disabled service and application settings for a permanently denied permission.
5. Bound current-location acquisition and use high accuracy only after the visitor triggers a location-dependent action.
