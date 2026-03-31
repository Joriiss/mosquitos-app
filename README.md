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
- **Cartographie** : Mapbox (token public à renseigner dans `android/app/src/main/res/values/secrets.xml`)

### 4. Démarrage

Depuis la racine du projet :

```bash
cd mosquitos_app
flutter pub get
flutter run
```

Dans `/app/src/main/res/values/secrets.xml` : 
```xml
<resources>
    <string name="mapbox_access_token">pk.XXXXX</string>
</resources>
```
