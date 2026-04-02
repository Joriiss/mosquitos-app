## Mosquitos App – Terrain & avaloirs

Application mobile Flutter développée pour le hackathon « cartographie et traitement des avaloirs ».

Backend associé : `[les-mosquitos](https://github.com/romain-sadar/les-mosquitos)`.

### 1. Fonctionnalités retenues (MVP)

- **Authentification simple** : connexion via identifiant / mot de passe pour accéder aux parcours et aux données terrain.  
- **Liste des cartographies existantes** : affichage des parcours déjà créés avec nom, date de création et nombre de points traités / restants.  
- **Carte globale interactive** : affichage des points enregistrés avec code couleur selon leur état (traité, à traiter, à vérifier).  
- **Consultation d’un point** : ouverture d’une fiche contenant photo, dernier traitement, étiquette, commentaire et accès à l’historique.  
- **Ajout d’un point** : création d’un point depuis la carte avec nom, étiquette, commentaire et photo.  
- **Marquage d’un point comme traité** : mise à jour rapide du statut d’un point depuis sa fiche.  
- **Historique d’un point** : consultation chronologique des interventions précédentes avec date, auteur et état enregistré.  
- **Création d’un parcours / mission** : génération d’une mission contenant un ensemble de points à traiter.  
- **Affichage d’un tracé** : visualisation d’un itinéraire reliant les points d’une mission.

### 2. Fonctionnalités prévues côté app

- **Authentification** auprès du backend Django.
- **Cartographie terrain** :
  - Afficher les points (avaloirs, trappes, etc.) sur une carte (Mapbox).
  - Ajouter de nouveaux points avec position GPS, étiquette, commentaire, photos.
- **Parcours de traitement** :
  - Lister les tournées de traitement générées par le backend.
  - Afficher l’ordre de passage et permettre à l’agent de marquer les points comme traités.
- **Historique** :
  - Afficher l’historique des interventions et l’activité utilisateur.

### 3. Stack technique

- **Framework** : Flutter
- **Langage** : Dart
- **Plateformes** : Android (et éventuellement Web / Desktop pour la démo)
- **API backend** : Django REST (`les-mosquitos`)
- **Cartographie** : Mapbox (token public géré côté Dart dans `lib/config/mapbox_config.local.dart`)

### 4. Structure du projet (Flutter)

- `lib/main.dart` : point d’entrée de l’app, configuration du thème et navigation initiale.
- `lib/config/` : configuration (ex. `mapbox_config.dart`).
- `lib/theme/` : thèmes partagés (ex. `app_colors.dart` avec les couleurs Figma).
- `lib/features/auth/presentation/login_page.dart` : vue de **login** (écran maquette Figma).
- `lib/features/map/presentation/map_page.dart` : vue **carte Mapbox** affichée après login.

### 5. Démarrage (pour un·e nouveau·elle dev)

Depuis la racine du dépôt hackathon :

```bash
cd mosquitos_app
flutter pub get
```

Ensuite :

1. **Créer le fichier de config Mapbox local** (`lib/config/mapbox_config.local.dart`) :

   ```dart
   class MapboxConfig {
     static const token = 'pk.VOTRE_TOKEN_PUBLIC_ICI';
   }
   ```

2. **Configurer l’URL du backend Django (local)** (`lib/config/api_config.local.dart`) :

   > Ce fichier est ignoré par Git. Chaque personne peut y mettre l’IP de son PC (Docker) sur le même Wi‑Fi.

   ```dart
   class ApiConfig {
     // Exemple (ton cas) : backend Docker accessible depuis le téléphone
     static const String baseUrl = 'http://192.168.1.22:8000/api';
   }
   ```

3. **Lancer l’app sur un device Android** :

   ```bash
   flutter run -d <id_appareil_android>
   ```

   (Vérifier que le mode développeur + débogage USB sont activés sur le téléphone.)


