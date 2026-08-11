# Souf 360 — سوف 360

**Souf 360** is a premium Arabic-first Android tourism companion for **El Oued (Wadi Souf), Algeria**. The application is designed for visitors and the public; the companion platform, [Souf360 Admin](https://souf360.vercel.app), remains the sole place where administrators create, edit, publish, and geolocate places.

> **Visitor promise:** *اكتشف وادي سوف من كل زاوية* — discover Wadi Souf from every angle.

| Area | Production choice |
| --- | --- |
| Mobile client | Flutter, Dart 3, Material Design 3, Arabic RTL as the primary locale |
| Android identity | Package `com.souf360.app`, target SDK 35, Java 17, Gradle 8.7 |
| Design system | Deep green `#193F38`, dark green `#102D28`, gold `#D9A441`, soft gold `#E5B65A`, ivory `#FBF7EF` |
| Catalogue | Existing Souf360 Supabase project only; no parallel database or mock catalogue |
| Synchronisation | Supabase queries, public read policies, and Realtime notifications for `places` |
| Cartographie et navigation | `flutter_map` et OpenStreetMap natifs ; itinéraire interne via le relais Supabase `routing`, sans WebView, Google Maps ni clé embarquée |
| Assistant | Authenticated `tour-guide` Supabase Edge Function; private AI credentials never enter the APK |

## How Souf360 Admin and Souf 360 work together

Souf360 Admin is the content-management surface. Souf 360 is deliberately a read-only visitor client. The Android app queries only places whose status is `منشور`, so an administrator can prepare a place privately before making it visible to visitors. A change notification on the shared `places` table causes the catalogue screens to refresh automatically; publishing a new place in the administration platform therefore makes it available in the app without an app update.

| Change made in Souf360 Admin | Result in Souf 360 Android |
| --- | --- |
| A place is added or corrected | The shared record is saved in the existing `public.places` table. |
| The status changes to `منشور` | The place becomes eligible for the public catalogue under Row Level Security. |
| Coordinates or category are changed | The place is refreshed in lists, category filters, and the native map. |
| Gallery records are changed | The place detail page reloads its Supabase gallery on the next open. |

The app does not create, alter, or delete tourism content. It uses the public Supabase key only; a `service_role` key, Edge Function secrets, and AI-provider keys must never be bundled in an APK.

## Visitor experience

The four primary destinations are **الرئيسية**, **المعالم**, **الخريطة**, and **المفضلة**. The home experience contains dynamic categories, featured places, latest additions, a search shortcut, and an entry point to the intelligent tour guide. The places experience supports Arabic search across a place’s name, description, category, address, district, and municipality; it also supports category filters, pull-to-refresh, lazy pagination, skeleton states, empty states, and retry states.

Each place has a premium detail experience with a gallery Supabase, a native mini-map, contact links, sharing, a local favourite button, and an in-app **الوصول إلى المكان** action. When published coordinates are present, the visitor enters Souf 360’s native navigation screen: the app asks for GPS permission only at that point, displays the real road geometry returned by the protected routing service, and can follow the visitor’s location after they explicitly start navigation. A place without published coordinates transparently reports that navigation is unavailable; no external map application, invented route, or fallback straight line is used.

| Capability | Behaviour |
| --- | --- |
| Offline mode | Published places are cached in `SharedPreferences`. If Souf360 is unavailable, cached results remain usable and the app explicitly shows that the data may not be current. |
| Favourites | Stored locally on the device; no registration, password, or backend write is needed. |
| Dark mode | A real dark Material 3 palette is available from the app shell. |
| Map | Native OpenStreetMap tiles, search, dynamic categories, nearby places on demand, image markers, clustering, place cards, a recenter control, and optional current location. |
| Navigation | In-app route panel with real provider geometry, distance, estimated duration, movement modes, voluntary GPS follow, off-route recalculation, and arrival feedback. |
| Guide IA | Arabic conversational interface backed by the authenticated `tour-guide` Edge Function. |
| Souf Compass | A local, offline-capable itinerary composer that ranks only real published places according to visitor-selected categories, available time and optional on-device location. It never fabricates a route or stop. |
| Assistance urgente | A confirmation sheet opens the Android dialer for Algeria Civil Protection (`14` or `1021`) without uploading the visitor’s location or contact data. |
| Accessibility | Arabic RTL layout, semantic labels on images, adequate controls, and material error/retry states. |

## Architecture

The repository uses a pragmatic **Clean Architecture** separation. Domain entities and repository contracts do not depend on Supabase or widgets. Data adapters are responsible for Supabase, local caching, and JSON mapping. Presentation layers compose Flutter pages and reusable widgets.

```text
lib/
├── app/                                  # Root MaterialApp, RTL shell, theme mode, 4 destinations
├── core/
│   ├── config/                           # Souf360 public client configuration
│   ├── location/                         # Permission-on-demand GPS access
│   ├── storage/                          # Local favourites controller
│   ├── theme/                            # Souf 360 Material 3 palettes
│   └── widgets/                          # Cross-screen offline notice
└── features/
    ├── home/                             # Dynamic home catalogue and visitor actions
    ├── compass/                          # Offline-capable personalised itinerary composer
    ├── favorites/                        # Device-local saved places
    ├── map/                              # Native map, search, proximity and clustered markers
    ├── routing/                           # Provider-neutral route contract, Supabase adapter and navigation UI
    ├── places/
    │   ├── domain/                       # Place, gallery, pagination, repository contracts
    │   ├── data/                         # Supabase repository and offline-first cache
    │   └── presentation/                 # Lists, cards, filters and place details
    └── tour_guide/                       # Edge Function client and Arabic chat UI
```

## Android branding

The project ships with a Souf 360 icon and launch experience built around the visual language of El Oued: golden dunes, a palm oasis, and a Saharan dome. Android resources under `android/app/src/main/res/` replace the previous generic launcher asset. The launch scene uses the ivory, green, and gold brand palette before Flutter renders its first frame.

## Local development

Flutter 3.24.5, Android SDK 35, and Java 17 are the validated baseline. The project is preconfigured for the existing Souf360 project. Developers can override the public endpoint and public key at build time when working with an authorised environment.

```bash
flutter pub get
flutter run \
  --dart-define=SUPABASE_URL=https://<project-ref>.supabase.co \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=<public-anon-or-publishable-key>
```

Run the complete local quality gate before opening a pull request:

```bash
dart format --set-exit-if-changed lib test
flutter analyze --fatal-infos
flutter test
flutter build apk --debug
```

The Android release build is generated with:

```bash
flutter build apk --release
cp build/app/outputs/flutter-apk/app-release.apk releases/Souf360.apk
```

A release delivered to Google Play must be signed with the product’s permanent upload keystore. For a local production signing build, create `android/key.properties` outside version control:

```properties
storePassword=<store password>
keyPassword=<key password>
keyAlias=<key alias>
storeFile=<path to upload keystore>
```

The repository falls back to the Android debug signer only when this file is absent, which is suitable for installable internal validation but **not** for a Play Store upload.

## Activating protected routing

The committed `supabase/functions/routing/index.ts` function is deployed with JWT verification. It accepts only a published place identifier, a transient GPS origin, a supported travel mode, and an alternatives flag. It obtains the destination coordinates from the existing Souf360 `places` table, keeps the provider key server-side, and does not write visitor locations to the database.

Set `GRAPHHOPPER_API_KEY` only as a Supabase Edge Function secret. Until this secret is configured, the function returns `routing_not_configured` and the Android screen shows a clear unavailable state instead of creating an estimated or straight-line route. This is intentional and prevents an API key from entering the APK.

## CI/CD and release signing

The **Android quality gate** runs formatting, static analysis, tests, and a debug APK build. The **Publish Android release** workflow runs for tags matching `v*`; it restores the permanent upload key, injects public Supabase configuration at build time, produces a signed release APK, and publishes it in GitHub Releases.

| GitHub Actions secret | Purpose |
| --- | --- |
| `ANDROID_KEYSTORE_BASE64` | Base64-encoded permanent Android upload keystore |
| `ANDROID_KEY_ALIAS` | Alias of the upload key |
| `ANDROID_KEY_PASSWORD` | Password of the selected key |
| `ANDROID_STORE_PASSWORD` | Password of the keystore |
| `SUPABASE_URL` | Public URL of the existing Souf360 Supabase project |
| `SUPABASE_PUBLISHABLE_KEY` | Public Supabase client key injected during release build |

```bash
git tag v1.2.0
# Review the tag before publishing it.
git push origin v1.2.0
```

## Security model

Supabase migration files in `supabase/migrations/` enforce a closed-by-default posture. Public users receive only the read access necessary for published tourism content; public writes are removed. Administrative checks and rate-limit state remain private. The `tour-guide` and `routing` functions verify a JWT; the routing function validates inputs, retrieves only published destination coordinates server-side, rate-limits access using the existing private control, and keeps the GraphHopper key outside the APK.

> A public Supabase client key identifies the client and is expected to be distributed in a mobile application. It remains safe only when combined with strict Row Level Security; it is never a replacement for a service-role secret.[1]

Before enabling password-based administrator accounts, enable **Leaked Password Protection** in Supabase Auth. This remains a console-side security setting rather than a mobile-app responsibility.[2]

## References

[1]: https://supabase.com/docs/guides/api/securing-your-api "Supabase — Securing your API"
[2]: https://supabase.com/docs/guides/auth/password-security "Supabase — Password security"
[3]: https://supabase.com/docs/guides/realtime/postgres-changes "Supabase — Postgres Changes"
[4]: https://www.poste.dz/philately/s/1629 "Algérie Poste — Numéros de la Protection Civile"
