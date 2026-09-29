# Atelier de couture — jeu Roblox

Jeu de couture sur Roblox, inspiré des mécaniques de *Dressmaker* (Cozy Lives / Free Lives, 2026).
On ne choisit pas un vêtement tout fait : on **dessine**, **coupe**, **coud** et **décore** la robe,
et le tissu découpé se voit tel quel sur la robe en 3D.

Le jeu est en cours de refonte, sous-projet par sous-projet
(spec : `docs/superpowers/specs/2026-09-28-atelier-coeur-design.md`, plans : `docs/superpowers/plans/`).

## État actuel (plan 3a)

Jouable dans Studio, en solo, sans sauvegarde (l'état de la partie vit dans le client) :

1. **Commande** : la clochette fait entrer une cliente (taille S, M ou L) avec 1 à 3 exigences de style,
   de couleur, de qualité ou d'accessoire.
2. **Carnet de croquis** : corsage, manches, col et jupe au choix ; un tissu par pièce (24 tissus, filtre par style).
   Les jauges de style et l'état des exigences se mettent à jour en direct.
3. **Achat** : métrage conseillé par tissu, quantité réglable, coût au mètre.
4. **Table de découpe** : les pièces du patron se glissent (souris ou doigt) et se tournent sur le rouleau.
   Droit-fil aimanté, pièces pliées coupées en double au pli, chevauchements refusés, place proposée.
5. La suite (épinglage, couture, décorations, photo et livraison) arrive au plan 3b ; serveur, boutiques
   et sauvegarde au plan 4.

## Installation

```bash
rojo serve        # dans ce dossier, puis « Connect » depuis le plugin Rojo dans Roblox Studio
# ou
rojo build -o AtelierCouture.rbxl
```

Le fichier `AtelierCouture.rbxl` fourni est prêt à ouvrir. Après une modification du code, le régénérer avec
`rojo build -o AtelierCouture.rbxl`. Le rendu 3D des robes utilise les API EditableMesh / EditableImage :
dans un jeu publié, le compte propriétaire doit être vérifié (13 ans et plus) et avoir activé ces API.

## Architecture

- `src/shared/` (ReplicatedStorage.Couture) : logique partagée, sans interface.
  | Module | Rôle |
  |---|---|
  | `Polygone`, `Patron` | Géométrie 2D des pièces, enroulement 3D autour du corps |
  | `Catalogue` | Pièces, variantes, tissus, accessoires, constantes |
  | `Coupon`, `Metrage` | Rouleau de découpe (pli, chevauchements) et métrage conseillé |
  | `Notation`, `Commandes` | Droit-fil, couture, qualité, styles, exigences, paie ; commandes réalisables |
  | `Pixels` | Motifs de tissu, découpe exacte de l'image d'une pièce, silhouette du patron |
  | `Recette` | Recette d'une robe en JSON et validation complète (filtre du serveur au plan 4) |
  | `Maillage`, `Mannequin`, `Editables`, `ConstructeurRobe`, `Vitrines` | Robe 3D, mannequin, vitrines |
  | `EtatAtelier` | État de la commande et règles de chaque étape (repris par le serveur au plan 4) |
- `src/client/Atelier/` (LocalScript `Atelier` et ses modules) : l'interface.
  `Session` fait le lien avec l'état ; `TableDecoupe` est la logique pure de la table ; un module `Ecran…` par étape.

## Tests

`bash tests/lancer.sh` (Linux, macOS ou Windows via Git Bash, avec Python 3) exécute le code du jeu dans un
Roblox simulé, validé d'après les définitions officielles de l'API (luau-lsp 1.70.1) :
- les tests unitaires de `tests/unitaires/` (logique, géométrie, rendu avec doublures des API modifiables) ;
- `tests/scenario.luau` : une commande jouée de bout en bout en cliquant dans l'interface.

Ce qu'une simulation ne voit pas (rendu, glisser au doigt, tailles d'écran) se vérifie dans Studio :
bancs d'essai `tests/studio/` et rapport `docs/superpowers/spikes/2026-09-28-rendu-editable.md`.
