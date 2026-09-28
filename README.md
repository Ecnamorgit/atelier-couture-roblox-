# Atelier de couture — prototype Roblox

Prototype jouable d'un jeu de couture sur Roblox, inspiré de *Dressmaker* (Cozy Lives / Free Lives, 2026).
Sur Roblox, les jeux de mode existants (Dress to Impress, Fashion Famous…) font assembler des vêtements
déjà faits : ici, on **fabrique** le vêtement.

## Boucle de jeu

1. **Commande** : un client demande un vêtement (jupe, haut ou robe), une couleur et parfois une finition.
2. **Tissu** : on achète un coupon. Les tissus nobles (soie, velours, satin) coûtent plus cher mais augmentent la paie.
3. **Découpe** : on place les pièces du patron sur le coupon (grille de 12 × 10 cases).
   - Des pièces qui se chevauchent sont mal coupées.
   - Une pièce pivotée ne suit plus le droit-fil : le vêtement tombe mal (note divisée par 2).
4. **Couture** : pour chaque couture, on appuie sur « Piquer ! » ou sur Espace quand l'aiguille passe dans la zone verte.
   La zone rétrécit et l'aiguille accélère au fil des coutures.
5. **Finitions** : dentelle, boutons, ruban, broderie (payantes).
6. **Livraison** : le serveur note couleur (25 %), découpe (30 %), couture (30 %) et finitions (15 %).
   Il en tire des étoiles, la paie (avec un pourboire pour 5 étoiles) et la réputation.

## Installation

### Option A — Rojo (recommandé)

```bash
rojo serve        # dans ce dossier, puis « Connect » depuis le plugin Rojo dans Roblox Studio
# ou
rojo build -o AtelierCouture.rbxl
```

### Option B — copier-coller dans Roblox Studio

| Fichier | Où le créer dans Studio | Type |
|---|---|---|
| `src/shared/CoutureData.luau` | `ReplicatedStorage` → dossier **`Couture`** → **`CoutureData`** | ModuleScript |
| `src/server/AtelierServer.server.luau` | `ServerScriptService` → `AtelierServer` | Script |
| `src/client/AtelierClient.client.luau` | `StarterPlayer` → `StarterPlayerScripts` → `AtelierClient` | LocalScript |

Les noms `Couture` et `CoutureData` doivent être exacts.

Lance ensuite **Play**. Tu peux ouvrir l'atelier de deux façons :
- le bouton **✂ Atelier** à gauche de l'écran ;
- l'établi en bois, créé automatiquement devant le point d'apparition, avec la touche **E**.

La sauvegarde (argent et réputation) passe par DataStore. Dans Studio, elle ne marche que si
*Game Settings → Security → Enable Studio Access to API Services* est activé. Sinon, le jeu tourne sans sauvegarder.

## Architecture

- `CoutureData` (partagé) : tissus, vêtements, finitions, phrases des clients et calcul de la note de découpe.
- `AtelierServer` : c'est lui qui fait foi. Il gère l'argent et les commandes, recalcule la découpe à partir
  des positions envoyées, borne les notes de couture, facture les finitions et calcule la paie.
- `AtelierClient` : toute l'interface, construite en code (aucun asset à importer) et adaptée aux petits écrans.

## Limites connues / pistes

- La note de couture vient du mini-jeu côté client : elle est bornée par le serveur, mais un tricheur peut envoyer 100 %.
- Pas de rendu 3D du vêtement sur un mannequin ou sur l'avatar. Étape suivante naturelle : générer un accessoire
  en couches (layered clothing), ou utiliser *Tailor Swiftly* (simulation de tissu de Roblox).
- Idées : défilé multijoueur avec votes (à la Dress to Impress), clients récurrents, amélioration de l'atelier,
  sabotage volontaire comme dans Dressmaker.
