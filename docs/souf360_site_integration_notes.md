# Souf360 Site Integration Notes

## Canonical site URL

The working website is **https://souf360.vercel.app/**. The un-dotted form `souf360vercel.app` does not resolve.

## Verified landing-page content

The website presents itself in Arabic as an official tourism platform for Oued Souf. The landing page includes a prominent hero, the title **«اكتشف سوف»**, and navigation to two primary routes:

| Route | User-facing role |
| --- | --- |
| `/explore` | Browse tourist landmarks |
| `/map` | View the map |

The landing page also claims a catalogue of more than 360 landmarks, 50 experiences and 100% verified places. The Android application should use Arabic as its primary product language and should mirror these site journeys instead of exposing build-time Supabase configuration.

## Verified explore and map journeys

The `/explore` page exposes four current, Arabic tourist/place records and uses Supabase Storage URLs under the `cwbenhuiextfoiyfboxo` project for their images. The visible records are:

| Name | Role on the website |
| --- | --- |
| الغزال الذهبي | Tourism and hospitality landmark |
| سوق الوادي | Historic and cultural market |
| مستشفى طب العيون الجزائر كوبا | Public-health landmark |
| الديوان المحلي للسياحة والصناعة التقليدية - سوف - بلدية الوادي | Local tourism promotion office |

The page provides Arabic search, favourite controls, detail/navigation actions, and a map action for each record. It also includes a heritage-memory item and a visitor-experience section.

The `/map` page uses Leaflet with OpenStreetMap tiles and displays four landmark markers. Its site navigation includes `/events`, `/restaurants`, `/hotels`, `/landmarks`, and `/map`; the mobile application should at minimum consume the shared landmark catalogue and deep-link users to matching web routes until native map and category modules are introduced.

## Verified data endpoint

The website loads its public landmark catalogue directly from Supabase REST:

```text
https://cwbenhuiextfoiyfboxo.supabase.co/rest/v1/places?select=*
```

The Supabase project reference and the publishable anonymous key are embedded in the website’s public JavaScript bundle, as required for its browser client. The Android application can therefore use the same public endpoint for read-only RLS-protected content; it must not use a service-role key.
