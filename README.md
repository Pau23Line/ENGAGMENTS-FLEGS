# Engagements promo F&L

Application web pour suivre les engagements promo fruits et légumes du magasin : TG fruit 1 (pomme), TG fruit 2 (banane), TG légumes, podium entrée et engagements en rayon, avec les colis du mardi au samedi, le récap de fin de semaine, les anciennes promos et la météo de Maisons-Alfort.

- **Hébergement** : GitHub Pages (gratuit).
- **Données partagées** : Supabase (gratuit), protégé par un **code magasin**.
- **Météo** : chargée automatiquement depuis Open-Meteo, sans clé ni compte.

Les collègues n'ont besoin **d'aucun compte** : le lien de l'app et le code magasin suffisent.

---

## Installation (environ 15 minutes, une seule fois)

### Étape 1 — Créer la base de données Supabase

1. Allez sur **https://supabase.com** et cliquez sur **Start your project**.
2. Connectez-vous avec **votre compte GitHub** (bouton *Continue with GitHub*).
3. Cliquez sur **New project** :
   - *Name* : `engagements-promo`
   - *Database Password* : cliquez sur *Generate a password* (vous n'en aurez pas besoin ensuite)
   - *Region* : **West EU (Paris)** si proposé, sinon *Central EU (Frankfurt)*
   - Plan : **Free**
4. Attendez 1 à 2 minutes que le projet soit prêt.

### Étape 2 — Installer les tables et choisir le code magasin

1. Dans le menu de gauche, ouvrez **SQL Editor**, puis **New query**.
2. Ouvrez le fichier [`supabase/setup.sql`](supabase/setup.sql), copiez **tout** son contenu et collez-le.
3. Tout en bas (étape 5 du script), remplacez **`CHANGEZ-MOI`** par votre code magasin.
   Gardez les apostrophes : `extensions.crypt('MonCode2026', ...)`.
4. Cliquez sur **Run**. Le message *Success. No rows returned* indique que tout est prêt.

### Étape 3 — Relier l'app à la base

1. Dans Supabase, ouvrez **Project Settings** (roue crantée), puis **API** (parfois nommé *Data API* ou *API Keys*).
2. Copiez :
   - le **Project URL** (du type `https://abcdefgh.supabase.co`) ;
   - la clé **anon public** (ou **publishable**, qui commence par `sb_publishable_`).
   ⚠️ Ne prenez **jamais** la clé *service_role* ou *secret*.
3. Ouvrez [`config.js`](config.js) et collez ces deux valeurs à la place des textes `COLLEZ-ICI-…`.

La clé *anon / publishable* peut être visible de tous : sans le code magasin, elle ne donne accès à aucune donnée.

### Étape 4 — Publier l'app avec GitHub Pages

1. Sur GitHub, dans le dépôt qui contient ces fichiers : **Settings**, puis **Pages**.
2. *Source* : **Deploy from a branch**. *Branch* : **main**, dossier **/ (root)**, puis **Save**.
3. Après 1 à 2 minutes, le lien de l'app s'affiche en haut de la page :
   `https://VOTRE-COMPTE.github.io/NOM-DU-DEPOT/`

> Avec un compte GitHub gratuit, GitHub Pages ne fonctionne que si le dépôt est **public**. Ce n'est pas un problème : le code magasin n'est écrit nulle part dans le dépôt (seule sa version chiffrée est stockée, dans Supabase).

---

## Utilisation

- **Partager** : envoyez le lien et le code magasin aux collègues. Chacun entre le code une fois, avec son prénom s'il le souhaite ; l'app s'en souvient sur son téléphone ou son ordinateur.
- **Sur téléphone** : ouvrez le lien puis choisissez *Ajouter à l'écran d'accueil* pour l'avoir comme une application.
- **Mise à jour** : les données se rafraîchissent automatiquement toutes les 20 secondes et à chaque retour sur l'app.
- **Météo** : chargée automatiquement pour la semaine en cours, la suivante et la semaine choisie dans Suivi. Les corrections faites à la main avec « Corriger la météo » ne sont jamais écrasées.

## Changer le code magasin

Dans Supabase, **SQL Editor**, lancez cette ligne avec le nouveau code :

```sql
update public.app_secret set code_hash = extensions.crypt('NouveauCode', extensions.gen_salt('bf')) where id = 1;
```

Les personnes déjà connectées devront saisir le nouveau code.

## Bon à savoir

- **Pause du projet gratuit** : Supabase met en pause un projet gratuit resté **7 jours sans aucune visite**. Tant que l'app est ouverte au moins une fois par semaine, cela n'arrive pas. Si l'app affiche « Impossible de joindre la base de données », connectez-vous à Supabase et cliquez sur **Restore project**. Les données sont conservées.
- **Sauvegarde** : dans Supabase, **Table Editor**, table `docs`, puis **Export to CSV**.

## Fichiers

| Fichier | Rôle |
|---|---|
| `index.html` | L'application (une seule page) |
| `config.js` | Adresse et clé publique de la base Supabase |
| `supabase/setup.sql` | Création des tables, du code magasin et des fonctions protégées |
