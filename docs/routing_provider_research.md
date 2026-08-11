# Décision de routage — Souf 360

## Option retenue

Souf 360 prépare un relais **GraphHopper** derrière une fonction Supabase authentifiée. La clé API est prévue exclusivement dans le secret serveur `GRAPHHOPPER_API_KEY`; elle n’est ni embarquée dans l’APK ni écrite dans le dépôt. Sans ce secret, la fonction doit répondre explicitement `routing_not_configured` et l’application ne doit fabriquer ni géométrie, ni distance, ni durée.

## Faits vérifiés

| Fournisseur | Capacités pertinentes vérifiées | Conséquence pour Souf 360 |
| --- | --- | --- |
| GraphHopper Directions API | Son API de routage renvoie des coordonnées de trajet, une distance, une durée et des instructions virage par virage. Elle accepte des profils, une option de routes alternatives et exige une clé API. | Convient au routage voiture, marche et vélo dans une fonction Supabase qui protège la clé. |
| OSRM | Son service `route` peut retourner la géométrie GeoJSON, les étapes, la durée, la distance et demander des alternatives. | Alternative sans clé possible pour une validation technique, mais non retenue comme service géré de production. |
| Valhalla | Son API de route prend des coordonnées et des modèles de coût tels que `auto`, `bicycle` et `pedestrian`, avec instructions de navigation. | Alternative auto-hébergée à considérer uniquement si l’exploitation d’un moteur de routage devient nécessaire. |

GraphHopper indique que le routage simple A-vers-B peut utiliser deux points, des instructions détaillées et que les réponses incluent des chemins, distance et durée. Son offre est basée sur une clé API et des crédits ; il ne faut pas supposer une capacité gratuite de production sans définir un compte et son quota.

## Références

[1]: https://docs.graphhopper.com/openapi/routing "GraphHopper Directions API — Routing"
[2]: https://project-osrm.org/docs/v5.24.0/api/ "OSRM API Documentation"
[3]: https://valhalla.github.io/valhalla/api/route/api-reference/ "Valhalla Route API Reference"
