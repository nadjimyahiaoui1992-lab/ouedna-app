# Media Audit Notes

## Repository media visually verified

| Path | Finding | Decision |
| --- | --- | --- |
| `images/screenshot.png` | Legacy Palghar/Vasai tourism interface showing Suruchi, Vandri, INR prices and non-Souf locations. | Remove. |
| `images/logo.png` | Generic newspaper-style icon with no Souf or El Oued identity. | Remove. |

The legacy `lib/assets/images/` set was already removed during the application refactor. Its file names referenced Palghar/Vasai-area content rather than El Oued.

## Storage status

The `images` bucket contains generic object names only. File-level relevance cannot be inferred from a path, size or hash; visual classification is required before retaining any object. Current database references show one `heritage` image URL, but public `places` rows have no image URLs recorded in the query result.

## Storage visual classification: sheets 1–2

The first twelve distinct images depict Saharan/Algerian urban and heritage scenes, including traditional interiors, historic photographs, markets, mosques, palm groves and a hotel/pool. None are placeholders, but **their precise location cannot be authenticated from the image alone**. They must not be retained as “authentic El Oued” without a supported local reference or existing database provenance. Their filenames and Storage metadata are generic and do not establish location.

The only currently referenced heritage object belongs to the repeated hash group `36fec21d…`; it is shown in this set as a historic black-and-white heritage photograph. It remains a provisional candidate pending locality confirmation, not a verified Souf asset.

## Storage visual classification: sheets 3–4

These sheets contain hotels, restaurant interiors, hotel/pool imagery, markets, palm courtyards, mosques and a branded `La Gazelle d’Or` resort mark. They are not generic placeholders; however, the visual evidence alone cannot demonstrate that they are in El Oued province. The branding and architecture are insufficient proof of a Souf location. Under the requested **strictly authentic local** standard, these assets are therefore not eligible for retention unless corroborated by a reliable El Oued provenance record.

## Storage visual classification: sheets 5–6

The final sheets depict branded hotel rooms, spas, pools, banqueting spaces, mosques, market scenes and a `LOUSS HOTEL` entrance. The material appears regionally Saharan/North African but lacks trustworthy, object-level proof of El Oued province. Because the request requires only **authentic, relevant local tourism media**, the strict and defensible outcome is to remove all current Storage objects rather than retain media with unverified provenance. The application will use its intentional non-media fallback until verified El Oued imagery is supplied with source, place and rights metadata.

## Platform asset verification

The Android launcher graphic and iOS app-icon set are unmodified Flutter marks, not El Oued/Souf tourism assets. The generic web PWA icon set and favicon were also scaffold placeholders. They are being removed from the Android and web source; the iOS platform directory is removed as out of scope for the requested Android-only delivery.
