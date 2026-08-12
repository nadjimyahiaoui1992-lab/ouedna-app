# Dossier de Candidature : IA Tour Algérie 2026
## Projet : ALGERIA 360 AI
**Slogan:** Discover Algeria. Intelligently.  
**Flagship Initial:** Souf360 (Wadi Souf / El Oued)

---

### 1. Présentation Générale du Projet
**ALGERIA 360 AI** est une super-application touristique nationale propulsée par l'Intelligence Artificielle générative, les technologies immersives (AR/VR) et un moteur de routage intelligent hors-ligne. Conçue pour répondre aux ambitions de la stratégie nationale de numérisation du secteur touristique, la plateforme offre une expérience unifiée, moderne et personnalisée pour valoriser l'immense patrimoine culturel, naturel et cultuel de l'Algérie.

Le projet intègre comme première destination pilote **Souf360**, dédiée à la région d'El Oued (la wilaya aux mille et une coupoles), tout en posant une architecture évolutive (Clean Architecture) prête à accueillir l'ensemble des wilayas du pays (Ghardaïa, Djanet, Tamanrasset, Alger, Constantine, etc.).

---

### 2. Adéquation avec les Axes Thématiques du Concours
*   **Axe 01 (Rêve) :** Intégration de visites virtuelles 360°, de prévisualisations en réalité augmentée des monuments et de contenus visuels générés pour l'immersion dans les oasis et le Sahara algérien.
*   **Axe 02 (Sur-Mesure) :** Déploiement d'un concierge touristique intelligent (**AI Tourism Concierge**) basé sur un système RAG (Retrieval-Augmented Generation) strictement connecté aux bases de données officielles de la plateforme, garantissant des recommandations de séjours personnalisées (budget, durée, intérêts).
*   **Axe 03 (Performance) :** Tableau de bord administrateur en temps réel, synchronisation bidirectionnelle instantanée (Web, Mobile Admin, Application Touriste) et optimisation des flux touristiques locaux.

---

### 3. Innovation Technique et Architecture
*   **Backend & Sécurité :** Supabase (PostgreSQL, Row Level Security, Storage sécurisé pour les photos et médias).
*   **Intelligence Artificielle :** Edge Functions sécurisées avec authentification, limitation d'usage (rate-limiting) et stricte restriction contextuelle (zéro hallucination historique).
*   **Navigation & Cartographie :** Utilisation native de `flutter_map` avec OpenStreetMap et tuiles satellite, couplée à un service de routage OSRM intégré (calcul de distance, ETA et guidage sans dépendance payante externe).
*   **Application Mobile Admin (Souf360 Admin) :** Permet aux gestionnaires locaux et nationaux de modérer les expériences visiteurs, d'ajouter des lieux avec un formulaire complet et de piloter le contenu en mobilité.

---

### 4. Impact et Scalabilité
*   **Impact Direct :** Amélioration radicale de l'expérience du voyageur en Algérie, démocratisation de l'accès à l'information touristique certifiée, et soutien direct à l'artisanat local et aux structures hôtelières.
*   **Scalabilité :** L'architecture modulaire permet l'intégration rapide de nouvelles wilayas par simple ajout de données structurées dans la base de données nationale.
