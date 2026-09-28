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
5. **Finitions** : dentelle, boutons, ruban, broderie (payantes). Un aperçu 3D du vêtement tourne à côté
   et change à chaque finition ajoutée.
6. **Livraison** : le serveur note couleur (25 %), découpe (30 %), couture (30 %) et finitions (15 %).
   Il en tire des étoiles, la paie (avec un pourboire pour 5 étoiles) et la réputation.
   Un critère raté (sous 40 %) plafonne la note à 3 étoiles, même si le reste est parfait.
7. **Vêtement en 3D** : la création est exposée sur le mannequin de l'atelier. Le bouton
   « Porter sur mon avatar » l'enfile sur ton personnage (R15 ou R6), et elle revient après une réapparition.
   Un travail bâclé se voit : pans de travers, longueurs inégales, couleur irrégulière si une pièce
   a été coupée hors du droit-fil.

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
| `src/shared/Rendu3D.luau` | `ReplicatedStorage` → dossier **`Couture`** → **`Rendu3D`** | ModuleScript |
| `src/server/AtelierServer.server.luau` | `ServerScriptService` → `AtelierServer` | Script |
| `src/client/AtelierClient.client.luau` | `StarterPlayer` → `StarterPlayerScripts` → `AtelierClient` | LocalScript |

Les noms `Couture`, `CoutureData` et `Rendu3D` doivent être exacts.

Option C, la plus simple : ouvrir directement le fichier `AtelierCouture.rbxl` fourni à la racine
du dépôt (le sol et le point d'apparition sont inclus). Après une modification du code,
le régénérer avec `rojo build -o AtelierCouture.rbxl`.

Lance ensuite **Play**. La fenêtre de l'atelier s'ouvre au démarrage. Tu peux la rouvrir de deux façons :
- le bouton **✂ Atelier** à gauche de l'écran ;
- l'établi en bois, créé automatiquement devant le point d'apparition, avec la touche **E**.

La sauvegarde (argent et réputation) passe par DataStore. Elle ne marche que sur un lieu publié, et dans Studio
seulement si *Game Settings → Security → Enable Studio Access to API Services* est activé. Sinon, le jeu tourne
sans sauvegarder. Si la lecture d'une sauvegarde échoue (panne passagère), le serveur ne la réécrit pas
à la déconnexion, pour ne pas écraser la vraie progression par l'argent de départ.

## Architecture

- `CoutureData` (partagé) : tissus, vêtements, finitions, phrases des clients, note de découpe
  et règles du mini-jeu de couture.
- `Rendu3D` (partagé) : fabrique le vêtement en pièces 3D soudées au corps (mannequin, avatar R15 ou R6),
  et le mannequin lui-même. Le serveur s'en sert pour le mannequin et l'avatar, le client pour l'aperçu.
- `AtelierServer` : c'est lui qui fait foi. Il gère l'argent et les commandes, valide la découpe à partir
  des positions des pièces, arbitre la couture, facture les finitions, calcule la paie et habille
  le mannequin et l'avatar.
- `AtelierClient` : toute l'interface, construite en code (aucun asset à importer), adaptée aux petits écrans.

## Anti-triche

- Le client n'envoie jamais de note. Il envoie la position des pièces (le serveur recalcule la découpe)
  et, pour chaque piqûre, le temps écoulé depuis le début de la couture.
- Le serveur tire lui-même la zone verte, la vitesse et le départ de l'aiguille, puis chronomètre chaque couture.
  Le temps annoncé par le client n'est accepté qu'à 0,08 s près (plus une marge liée au ping),
  ce qui absorbe le délai réseau sans permettre de choisir l'instant.
- Impossible de piquer pendant la pause entre deux coutures, de relancer une couture pour obtenir une zone
  plus facile, de livrer avant la fin, de payer deux fois une finition, ni d'appeler le serveur en rafale.
- Limite honnête : comme dans tout jeu de rythme, un programme qui appuierait au bon moment
  à la place du joueur réussirait. Mais il ne peut plus s'attribuer 100 %.

## Tests

`tests/lancer.sh` (Linux, macOS ou Windows via Git Bash, avec Python 3) exécute le vrai code du jeu dans un Roblox simulé, sans Studio.
Chaque propriété, événement et méthode est vérifié d'après les définitions officielles de l'API Roblox.
Le script :
- joue plusieurs parties complètes en cliquant dans l'interface (commande, tissu, découpe, couture au clavier
  et à la souris, finitions, livraison, porter / retirer, réapparition) ;
- contrôle 216 combinaisons de rendu 3D (3 vêtements × finitions × qualité × R15 / R6 / tourné / mannequin) :
  valeurs finies, repères orthonormés, soudures cohérentes, rien sous le sol, jupe hors des jambes ;
- tente de tricher (fausse précision, faux chronomètre, piqûres pendant la pause, finitions en double…).

Ce qu'une simulation ne peut pas garantir : le rendu visuel réel dans Roblox. Le premier essai dans Studio
reste nécessaire pour juger l'apparence.

## Pistes

- Défilé multijoueur avec votes (à la Dress to Impress), clients récurrents, amélioration de l'atelier,
  sabotage volontaire comme dans Dressmaker.
- Vêtements en maillage (layered clothing) pour un rendu plus fluide que les panneaux actuels.
