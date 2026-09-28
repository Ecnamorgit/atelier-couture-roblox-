# Cœur de l'atelier — Plan 2 : robe en 3D et vitrines

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Transformer une recette de robe en robe 3D fidèle, avec le motif découpé visible sur chaque pièce, sur un mannequin dimensionné selon les mesures. Exposer les robes dans des vitrines construites à proximité du joueur et libérées quand il s'éloigne.

**Architecture:** Chaîne de rendu côté client, en modules de `src/shared/` :
- `Recette` : JSON et validation ;
- `Maillage` : triangulation pure ;
- `Mannequin` : corps en pièces Roblox ;
- `Editables` : seul module qui touche aux API modifiables ;
- `ConstructeurRobe` : recette → robe ;
- `Vitrines` : construction par distance.

Chaque pièce suit la chaîne validée par le spike : maillage et image modifiables → contenu statique → MeshPart → destruction immédiate. Il n'y a donc jamais plus d'un maillage et d'une image modifiables vivants à la fois. Le simulateur de tests reçoit des doublures fidèles de ces API (budget, deux valeurs de retour, perte de forme sans conversion) et les définitions luau-lsp 1.70.1.

**Tech Stack:** Luau, Rojo 7.7.0-rc.1, simulation Luau 0.650 (`tests/lancer.sh`), Roblox Studio via le connecteur MCP Studio (vérification visuelle et mesures).

**Spec:** `docs/superpowers/specs/2026-09-28-atelier-coeur-design.md` (§2 recette, §5 rendu 3D, §9 performances). Mesures d'entrée : `docs/superpowers/spikes/2026-09-28-rendu-editable.md`.

## Global Constraints

- **Dépôt** : `C:\dev\jeux\atelier-couture`, branche `refonte-rendu`. Ne rien pousser sur GitHub sans demande.
- **Rojo** : `C:/dev/jeux/roblox-maker/rojo.exe` (7.7.0-rc.1).
- **Contraintes du plan 1 toujours valables** :
  - unité le dm ;
  - repère du corps (origine à la taille, Y vers le haut, devant −Z, droite +X) ;
  - fins de ligne LF ;
  - commits en français terminés par `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.
- **Échelle du rendu** : `Catalogue.STUDS_PAR_DM = 0.3`.
- **Règles du spike, à respecter partout** :
  - convertir en contenu statique (`CreateDataModelContentAsync`, qui renvoie `(Enum.CreateContentResult, Content)`) **avant** de détruire l'objet modifiable ;
  - une création modifiable peut renvoyer `nil` (budget atteint) ;
  - pas de `SurfaceAppearance` en jeu : le rendu passe par `Material` + `Reflectance`.
- **Finesse du maillage** : robe 12 × 16 cases, vitrine 6 × 8. Images de pièces plafonnées à 256 px (robe) et 128 px (vitrine).
- **Vitrines** :
  - construction à 60 studs ou moins, libération au-delà de 80 studs, vérification toutes les 0,5 s ;
  - une seule robe en construction à la fois ;
  - contrat avec le serveur : socles `BasePart` dans `workspace.Vitrines`, attribut `« Recette »` = `Recette.encoder(recette)`.
- **Extensions de la recette par rapport à la spec §2** (déjà validées) :
  - champ `croquis` (plan 1) ;
  - champ `copie` facultatif pour un accessoire sur pièce pliée (défaut : première copie) ;
  - `(u, v)` d'un accessoire = position dans la boîte du patron (0,0 en haut à gauche), comme les UV des images.
- **Mesures acceptées** : poitrine 7–13 dm, taille 5,5–12 dm, hanches 8–14 dm, et la taille ne dépasse ni la poitrine ni les hanches.
- **Performance** : génération étalée sur plusieurs images (une pièce par image, option `etaler`). L'écart avec l'objectif §9 est connu et à décider par le commanditaire (voir le rapport du spike). Ce plan mesure, il ne promet pas le chiffre.
- **L'ancien jeu reste en place** et son scénario reste vert (`TOUT EST VERT : 181072 vérifications`).

## Review Focus

- **Robe ou socle détruit pendant une génération étalée** (`task.wait()` entre les pièces). La doublure de `task.wait` n'existe pas dans le simulateur. Attendu : la construction s'arrête sans erreur et aucun objet modifiable ne reste vivant. À vérifier dans le code et en jeu (tâche 9).
- **Joueur qui s'éloigne puis revient pendant qu'une vitrine se construit.** Attendu : l'exposition quittée est libérée, `enCours` redevient faux à la fin de la construction interrompue, puis la vitrine est reconstruite normalement.
- **Huit vitrines à portée sur un téléphone.** Attendu : une seule construction à la fois (~0,5 s chacune sur PC) et jamais de gel de l'image. La simulation ne le mesure pas ; c'est la tâche 9 et le test sur téléphone du commanditaire.
- **Recette d'attribut issue d'un ancien format** (sans `croquis`, ou mesures hors bornes). Attendu : vitrine ignorée avec un seul avertissement (testé pour « illisible » et « invalide ») ; les migrations de format viennent au plan 4.
- **Image d'une pièce vue de l'extérieur.** Attendu : ni retournée ni en miroir. Les tests ne peuvent pas voir l'écran : c'est l'essai d'orientation de la tâche 9 (bande bleue en haut, rouge du côté de la bille verte).

## Structure des fichiers

| Fichier | Rôle |
|---|---|
| `tests/lancer.sh` (réécrit) | Télécharge les définitions luau-lsp 1.70.1 (sécurité « None ») dans un fichier daté |
| `tests/gen_api.py` (modifié) | Lit les deux formats de définitions ; ajoute `AssetService` aux classes simulées |
| `tests/mock.luau` (modifié) | Doublures des API modifiables, `Content`, service `AssetService` |
| `tests/build.py` (modifié) | `Content` dans l'environnement ; avertissements remis à zéro avant le scénario |
| `src/shared/Catalogue.luau` (modifié) | `STUDS_PAR_DM`, matériau Roblox par matière, apparence 3D des accessoires |
| `src/shared/Recette.luau` | JSON d'une recette, validation complète, copie par défaut d'un accessoire |
| `src/shared/Maillage.luau` | Triangulation d'une pièce enroulée (positions, normales, UV, faces tournées vers l'extérieur) |
| `src/shared/Mannequin.luau` | Mannequin de couturière (buste, taille, bassin, épaules, cou, pied, socle) selon les mesures |
| `src/shared/Editables.luau` | Création d'images et de maillages modifiables, conversion en contenu statique, MeshPart |
| `src/shared/ConstructeurRobe.luau` | Recette → robe 3D (pièces et accessoires), repli en couleur unie |
| `src/shared/Vitrines.luau` | Construction et libération des vitrines selon la distance |
| `tests/unitaires/08_recette.luau` … `13_vitrines.luau` | Tests unitaires, un fichier par module |
| `tests/studio/banc_rendu.luau` | Banc d'essai Studio (temps réels, essai d'orientation), lancé à la main |
| `docs/superpowers/spikes/2026-09-28-rendu-editable.md` (complété) | Mesures du banc du plan 2 |
| `README.md` (complété) | Nouveaux modules |

**Commande de test** : `bash tests/lancer.sh`. La sortie affiche `Unitaires : N vérifications`, puis `TOUT EST VERT : 181072 vérifications` pour l'ancien jeu.

**Appliquer un patch d'une étape** : enregistrer le bloc `diff` dans un fichier (par exemple `/tmp/etape.diff`), puis lancer `git apply /tmp/etape.diff` depuis la racine du dépôt.

---

### Task 1: Définitions de l'API Roblox 1.70.1 dans le simulateur

**Files:**
- Modify: `tests/lancer.sh` (réécriture complète)
- Modify: `tests/gen_api.py`

**Interfaces:**
- Consumes: rien.
- Produces: `tests/.cache/globalTypes.d.luau` = définitions luau-lsp **1.70.1** (sécurité des scripts de jeu). `gen_api.py` accepte `declare class …` et `declare extern type … with`, y compris les méthodes indentées de deux tabulations (`@deprecated`). Les tâches 6 à 8 s'appuient sur `AssetService`, `MeshPart.TextureContent` et `Enum.CreateContentResult`, présents seulement dans ces définitions.

- [ ] **Step 1: Réécrire `tests/lancer.sh`**

```bash
#!/usr/bin/env bash
# Lance la simulation complète du jeu hors de Roblox Studio (Linux, macOS, ou Windows via Git Bash).
# Télécharge au premier lancement : Luau 0.650 et les définitions de l'API Roblox
# (luau-lsp 1.70.1, niveau de sécurité des scripts de jeu).
set -euo pipefail
ICI="$(cd "$(dirname "$0")" && pwd)"
CACHE="$ICI/.cache"
mkdir -p "$CACHE/sim"
case "$(uname -s)" in
  Linux*) PAQUET=luau-ubuntu.zip; LUAU="$CACHE/luau" ;;
  Darwin*) PAQUET=luau-macos.zip; LUAU="$CACHE/luau" ;;
  MINGW*|MSYS*|CYGWIN*) PAQUET=luau-windows.zip; LUAU="$CACHE/luau.exe" ;;
  *) echo "Système non pris en charge : $(uname -s)" >&2; exit 1 ;;
esac
PYTHON="$(command -v python3 || command -v python)"
if [ ! -f "$LUAU" ]; then
  curl -sSL -o "$CACHE/luau.zip" "https://github.com/luau-lang/luau/releases/download/0.650/$PAQUET"
  unzip -o -q "$CACHE/luau.zip" -d "$CACHE"
fi
DEFINITIONS="$CACHE/globalTypes-1.70.1.None.d.luau"
if [ ! -f "$DEFINITIONS" ]; then
  curl -sSL -o "$DEFINITIONS" https://raw.githubusercontent.com/JohnnyMorganz/luau-lsp/1.70.1/scripts/globalTypes.None.d.luau
fi
cp "$DEFINITIONS" "$CACHE/globalTypes.d.luau"
cp "$ICI/mock.luau" "$ICI/scenario.luau" "$CACHE/sim/"
"$PYTHON" "$ICI/gen_api.py" "$CACHE" "$ICI/../src"
"$PYTHON" "$ICI/build.py" "$CACHE" "$ICI/../src"
"$LUAU" "$CACHE/sim/run.luau"
```

- [ ] **Step 2: Constater l'échec avec l'ancien analyseur**

Run: `bash tests/lancer.sh 2>&1 | grep -c "CLASSE INCONNUE"`
Expected: un nombre supérieur à 0. L'ancien `gen_api.py` ne reconnaît pas `declare extern type` et ne trouve plus les classes.

- [ ] **Step 3: Adapter `tests/gen_api.py`**

```diff
diff --git a/tests/gen_api.py b/tests/gen_api.py
index 4f41b3c..e5b782e 100644
--- a/tests/gen_api.py
+++ b/tests/gen_api.py
@@ -4,7 +4,8 @@ lines = open(S + "/globalTypes.d.luau", encoding="utf-8").read().split("\n")
 classes = {}; enums = {}
 cur = None
 for ln in lines:
-    m = re.match(r"^declare class (\w+)(?: extends (\w+))?(.*)$", ln)
+    # Deux formats : « declare class X extends Y » (luau-lsp 1.5x) et « declare extern type X extends Y with » (1.6x et plus)
+    m = re.match(r"^declare (?:class|extern type) (\w+)(?: extends (\w+))?(?: with)?(.*)$", ln)
     if m:
         name, parent, rest = m.group(1), m.group(2), m.group(3)
         cur = {"parent": parent, "props": {}, "methods": set()}
@@ -17,7 +18,7 @@ for ln in lines:
         continue
     if cur is None: continue
     if ln.startswith("end"): cur = None; continue
-    m = re.match(r"^\t(?:function (\w+)\(.*|(\w+): (.+))$", ln)
+    m = re.match(r"^\t+(?:function (\w+)\(.*|(\w+): (.+))$", ln)
     if m:
         if m.group(1): cur["methods"].add(m.group(1))
         else: cur["props"][m.group(2)] = m.group(3).strip()
```

- [ ] **Step 4: Lancer les tests**

Run: `bash tests/lancer.sh 2>&1 | grep -E "ENUM CHECK|CLASSE|Unitaires|ÉCHEC|TOUT"`
Expected:
```
ENUM CHECK: OK
Unitaires : 14409 vérifications
TOUT EST VERT : 181072 vérifications
```

- [ ] **Step 5: Commit**

```bash
git add tests/lancer.sh tests/gen_api.py
git commit -m "Tests : définitions de l'API Roblox luau-lsp 1.70.1

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 2: Données de rendu dans le catalogue

**Files:**
- Modify: `src/shared/Catalogue.luau`
- Test: `tests/unitaires/02_catalogue.luau`

**Interfaces:**
- Consumes: le catalogue du plan 1.
- Produces :
  - `Catalogue.STUDS_PAR_DM = 0.3` ;
  - `Catalogue.MATIERES[matiere].materiau` : `"Fabric"` ou `"SmoothPlastic"`, à côté de `reflet` ;
  - `accessoire.apparence` : pour un objet `{ forme = "boule"|"bloc"|"cylindre"|"noeud"|"fleur"|"croix", taille (dm ≤ 1), couleur = {r, g, b}, reflet }`, pour une garniture `{ largeur (dm ≤ 0,5), couleur, transparence }`.

- [ ] **Step 1: Ajouter les tests**

```diff
diff --git a/tests/unitaires/02_catalogue.luau b/tests/unitaires/02_catalogue.luau
index 6cd9f36..84f86a4 100644
--- a/tests/unitaires/02_catalogue.luau
+++ b/tests/unitaires/02_catalogue.luau
@@ -95,3 +95,20 @@ for _, a in ipairs(Catalogue.Accessoires) do
 	U.verifier(a.prix > 0, a.id .. " : prix positif")
 	stylesValides(a.style, a.id)
 end
+
+-- Plan 2 : rendu 3D
+U.verifier(Catalogue.STUDS_PAR_DM > 0, "échelle du rendu positive")
+for nom, m in pairs(Catalogue.MATIERES) do
+	U.verifier(m.materiau == "Fabric" or m.materiau == "SmoothPlastic", nom .. " : matériau Roblox connu")
+	U.verifier(m.reflet >= 0 and m.reflet <= 1, nom .. " : reflet entre 0 et 1")
+end
+local FORMES = { boule = true, bloc = true, cylindre = true, noeud = true, fleur = true, croix = true }
+for _, a in ipairs(Catalogue.Accessoires) do
+	local ap = a.apparence
+	U.verifier(type(ap) == "table" and #ap.couleur == 3, a.id .. " : apparence avec couleur")
+	if a.genre == "objet" then
+		U.verifier(FORMES[ap.forme] == true and ap.taille > 0 and ap.taille <= 1, a.id .. " : forme connue, taille ≤ 1 dm")
+	else
+		U.verifier(ap.largeur > 0 and ap.largeur <= 0.5 and ap.transparence >= 0 and ap.transparence < 1, a.id .. " : largeur et transparence valides")
+	end
+end
```

- [ ] **Step 2: Vérifier qu'ils échouent**

Run: `bash tests/lancer.sh 2>&1 | grep -m1 -E "ÉCHEC|error"`
Expected: `ÉCHEC : échelle du rendu positive` (ou une erreur de comparaison sur `STUDS_PAR_DM` absent).

- [ ] **Step 3: Compléter le catalogue**

```diff
diff --git a/src/shared/Catalogue.luau b/src/shared/Catalogue.luau
index 76a5f36..ee5f9b7 100644
--- a/src/shared/Catalogue.luau
+++ b/src/shared/Catalogue.luau
@@ -13,6 +13,7 @@ Catalogue.VALEUR_COUTURE = 0.15 -- décalage du trajet de couture vers l'intéri
 Catalogue.PAS_MESURE_COUTURE = 0.1 -- une mesure d'écart tous les 0,1 dm de trajet
 Catalogue.K = { pieces = 1, tissu = 2, accessoires = 0.5 } -- poids des jauges de style
 Catalogue.PLAFOND_ASSISTANCE = 0.85
+Catalogue.STUDS_PAR_DM = 0.3 -- échelle du rendu 3D : 1 dm de patron = 0,3 stud
 
 Catalogue.STYLES = { "elegant", "mignon", "romantique", "gothique", "chic", "decontracte" }
 Catalogue.NOMS_STYLES = {
@@ -188,42 +189,56 @@ Catalogue.Tissus = {
 		{ type = "pois", couleurs = { { 120, 70, 160 }, { 230, 210, 250 } }, periode = 0.5, rayon = 0.1 }, { mignon = 10, gothique = 8 }),
 }
 
--- Rendu 3D par matière (utilisé au sous-projet de rendu)
+-- Rendu 3D par matière : matériau Roblox et reflet (SurfaceAppearance est interdite en jeu, voir le spike)
 Catalogue.MATIERES = {
-	coton = { rugosite = 0.9, reflet = 0 },
-	lin = { rugosite = 1, reflet = 0 },
-	laine = { rugosite = 1, reflet = 0 },
-	soie = { rugosite = 0.35, reflet = 0.1 },
-	velours = { rugosite = 0.8, reflet = 0 },
-	satin = { rugosite = 0.25, reflet = 0.15 },
+	coton = { rugosite = 0.9, reflet = 0, materiau = "Fabric" },
+	lin = { rugosite = 1, reflet = 0, materiau = "Fabric" },
+	laine = { rugosite = 1, reflet = 0, materiau = "Fabric" },
+	soie = { rugosite = 0.35, reflet = 0.1, materiau = "SmoothPlastic" },
+	velours = { rugosite = 0.8, reflet = 0, materiau = "Fabric" },
+	satin = { rugosite = 0.25, reflet = 0.15, materiau = "SmoothPlastic" },
 }
 
 ---------------------------------------------------------------------------
 -- Accessoires : objets (prix à l'unité) et garnitures (prix au dm, points par tranche de 5 dm)
 ---------------------------------------------------------------------------
-local function objet(id, nom, prix, style)
-	return { id = id, nom = nom, genre = "objet", prix = prix, style = style }
+-- apparence : forme 3D ("boule", "bloc", "cylindre", "noeud", "fleur", "croix"), taille (dm), couleur, reflet
+local function objet(id, nom, prix, style, apparence)
+	return { id = id, nom = nom, genre = "objet", prix = prix, style = style, apparence = apparence }
 end
-local function garniture(id, nom, prix, style)
-	return { id = id, nom = nom, genre = "garniture", prix = prix, style = style }
+-- apparence d'une garniture : largeur du ruban (dm), couleur, transparence
+local function garniture(id, nom, prix, style, apparence)
+	return { id = id, nom = nom, genre = "garniture", prix = prix, style = style, apparence = apparence }
 end
 
 Catalogue.Accessoires = {
-	objet("bouton_nacre", "Bouton nacré", 1, { chic = 2, elegant = 1 }),
-	objet("bouton_dore", "Bouton doré", 2, { elegant = 2, chic = 1 }),
-	objet("noeud_satin", "Nœud de satin", 3, { mignon = 4, romantique = 2 }),
-	objet("noeud_velours", "Nœud de velours", 4, { gothique = 3, elegant = 2 }),
-	objet("fleur_rose", "Fleur rose", 3, { romantique = 4, mignon = 2 }),
-	objet("fleur_blanche", "Fleur blanche", 3, { romantique = 3, elegant = 2 }),
-	objet("broche_camee", "Broche camée", 8, { elegant = 5, gothique = 2 }),
-	objet("perle", "Perle", 1, { elegant = 2, romantique = 1 }),
-	objet("etoile_brodee", "Étoile brodée", 2, { mignon = 3 }),
-	objet("croix_argent", "Croix d'argent", 5, { gothique = 5 }),
-	garniture("dentelle_blanche", "Dentelle blanche", 2, { romantique = 3, elegant = 2 }),
-	garniture("dentelle_noire", "Dentelle noire", 2, { gothique = 4, elegant = 1 }),
-	garniture("ruban_rose", "Ruban rose", 1, { mignon = 3 }),
-	garniture("galon_dore", "Galon doré", 3, { elegant = 3, chic = 2 }),
-	garniture("ruban_noir", "Ruban noir", 1, { gothique = 2, chic = 2 }),
+	objet("bouton_nacre", "Bouton nacré", 1, { chic = 2, elegant = 1 },
+		{ forme = "boule", taille = 0.25, couleur = { 248, 244, 236 }, reflet = 0.3 }),
+	objet("bouton_dore", "Bouton doré", 2, { elegant = 2, chic = 1 },
+		{ forme = "cylindre", taille = 0.28, couleur = { 214, 170, 60 }, reflet = 0.4 }),
+	objet("noeud_satin", "Nœud de satin", 3, { mignon = 4, romantique = 2 },
+		{ forme = "noeud", taille = 0.9, couleur = { 240, 150, 190 }, reflet = 0.15 }),
+	objet("noeud_velours", "Nœud de velours", 4, { gothique = 3, elegant = 2 },
+		{ forme = "noeud", taille = 0.9, couleur = { 60, 20, 40 }, reflet = 0 }),
+	objet("fleur_rose", "Fleur rose", 3, { romantique = 4, mignon = 2 },
+		{ forme = "fleur", taille = 0.6, couleur = { 250, 140, 180 }, reflet = 0 }),
+	objet("fleur_blanche", "Fleur blanche", 3, { romantique = 3, elegant = 2 },
+		{ forme = "fleur", taille = 0.6, couleur = { 250, 250, 245 }, reflet = 0 }),
+	objet("broche_camee", "Broche camée", 8, { elegant = 5, gothique = 2 },
+		{ forme = "cylindre", taille = 0.55, couleur = { 240, 200, 180 }, reflet = 0.2 }),
+	objet("perle", "Perle", 1, { elegant = 2, romantique = 1 },
+		{ forme = "boule", taille = 0.18, couleur = { 250, 246, 240 }, reflet = 0.5 }),
+	objet("etoile_brodee", "Étoile brodée", 2, { mignon = 3 },
+		{ forme = "bloc", taille = 0.4, couleur = { 250, 220, 90 }, reflet = 0 }),
+	objet("croix_argent", "Croix d'argent", 5, { gothique = 5 },
+		{ forme = "croix", taille = 0.6, couleur = { 200, 200, 210 }, reflet = 0.5 }),
+	garniture("dentelle_blanche", "Dentelle blanche", 2, { romantique = 3, elegant = 2 },
+		{ largeur = 0.3, couleur = { 250, 248, 240 }, transparence = 0.15 }),
+	garniture("dentelle_noire", "Dentelle noire", 2, { gothique = 4, elegant = 1 },
+		{ largeur = 0.3, couleur = { 30, 25, 30 }, transparence = 0.15 }),
+	garniture("ruban_rose", "Ruban rose", 1, { mignon = 3 }, { largeur = 0.2, couleur = { 240, 150, 190 }, transparence = 0 }),
+	garniture("galon_dore", "Galon doré", 3, { elegant = 3, chic = 2 }, { largeur = 0.15, couleur = { 214, 170, 60 }, transparence = 0 }),
+	garniture("ruban_noir", "Ruban noir", 1, { gothique = 2, chic = 2 }, { largeur = 0.2, couleur = { 30, 25, 30 }, transparence = 0 }),
 }
 
 ---------------------------------------------------------------------------
```

- [ ] **Step 4: Lancer les tests**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT"`
Expected:
```
Unitaires : 14452 vérifications
TOUT EST VERT : 181072 vérifications
```

- [ ] **Step 5: Commit**

```bash
git add src/shared/Catalogue.luau tests/unitaires/02_catalogue.luau
git commit -m "Catalogue : échelle, matériaux et apparence 3D des accessoires

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 3: Module `Recette` (JSON et validation)

**Files:**
- Create: `src/shared/Recette.luau`
- Test: `tests/unitaires/08_recette.luau`

**Interfaces:**
- Consumes: `Catalogue.tissu`, `accessoire` ; `Patron.piecesDuCroquis`, `Patron.copies`.
- Produces :
  - constantes `Recette.MAX_ACCESSOIRES = 300`, `MAX_POINTS_GARNITURE = 64`, `ANGLE_MAX = 3600`, `ECHELLE_MIN = 0.5`, `ECHELLE_MAX = 3`, `POITRINE = {7, 13}`, `TAILLE = {5.5, 12}`, `HANCHES = {8, 14}` ;
  - `Recette.encoder(recette) -> string` : JSON, clés triées, nombres finis seulement (erreur sinon) ;
  - `Recette.decoder(texte) -> (valeur | nil, message?)` : ne lève jamais d'erreur ;
  - `Recette.valider(recette) -> (ok: boolean, message: string?)` ;
  - `Recette.copieAccessoire(recette, accessoire) -> "unique" | "gauche" | "droite"`.

- [ ] **Step 1: Écrire les tests**

`tests/unitaires/08_recette.luau` :

```lua
local Catalogue = U.module("Catalogue")
local Recette = U.module("Recette")

local function exemple()
	return {
		croquis = { corsage = "corsage_v", manches = "manches_ballon", col = "col_sans", jupe = "jupe_trapeze" },
		mesures = table.clone(Catalogue.TAILLES.M),
		pieces = {
			{ id = "corsage_v_devant", tissu = "soie_rose_fleurs", x = 3.2, y = 2.5, angle = 45, couture = 0.92 },
			{ id = "corsage_droit_dos", tissu = "soie_rose_fleurs", x = 9.1, y = 2.5, angle = 0, couture = 1 },
			{ id = "manche_ballon", tissu = "satin_rose", x = 2, y = 7, angle = -90, couture = 0.5 },
			{ id = "jupe_trapeze_devant", tissu = "coton_blanc", x = 3.5, y = 12, angle = 0, couture = 0.75 },
			{ id = "jupe_trapeze_dos", tissu = "coton_blanc", x = 10, y = 12, angle = 180, couture = 0.8 },
		},
		accessoires = {
			{ id = "noeud_satin", piece = 1, u = 0.5, v = 0.9, echelle = 1.2, angle = 15 },
			{ id = "bouton_nacre", piece = 3, copie = "droite", u = 0.3, v = 0.4, echelle = 1, angle = 0 },
			{ id = "dentelle_blanche", piece = 4, trajet = { { u = 0, v = 1 }, { u = 0.5, v = 1 }, { u = 1, v = 1 } } },
		},
	}
end

local function egal(a, b, chemin)
	if type(a) ~= type(b) then
		return false, chemin
	end
	if type(a) == "table" then
		for k, v in pairs(a) do
			local ok, ou = egal(v, b[k], chemin .. "." .. tostring(k))
			if not ok then
				return false, ou
			end
		end
		for k in pairs(b) do
			if a[k] == nil then
				return false, chemin .. "." .. tostring(k)
			end
		end
		return true
	elseif type(a) == "number" then
		return math.abs(a - b) <= 1e-9 * math.max(1, math.abs(a)), chemin
	end
	return a == b, chemin
end

-- Aller-retour JSON
local r = exemple()
local texte = Recette.encoder(r)
U.verifier(type(texte) == "string" and texte:sub(1, 1) == "{", "encodage en objet JSON")
local relu = Recette.decoder(texte)
local ok, ou = egal(r, relu, "recette")
U.verifier(ok, "aller-retour JSON sans perte (écart en " .. tostring(ou) .. ")")
U.verifier(Recette.encoder(relu) == texte, "encodage stable (clés triées)")
U.verifier(Recette.decoder(Recette.encoder({ texte = 'a"b\\c\n', liste = {}, vrai = true, faux = false })).texte == 'a"b\\c\n',
	"caractères spéciaux préservés")
U.verifier(not pcall(Recette.encoder, { x = 0 / 0 }), "un nombre non fini ne s'encode pas")

-- Textes invalides : nil et un message, jamais d'erreur
for _, mauvais in ipairs({ "", "{", '{"a":}', '{"a":1}x', "nan", '"sans fin', "[1,2", '{"a" 1}', "-", 12, nil }) do
	local v, message = Recette.decoder(mauvais)
	U.verifier(v == nil and type(message) == "string", "texte invalide refusé : " .. tostring(mauvais))
end
U.verifier(Recette.decoder(string.rep("[", 50) .. string.rep("]", 50)) == nil, "imbrication démesurée refusée")

-- Validation
U.verifier(Recette.valider(exemple()), "recette d'exemple valide")
local cas = {
	{ "pas une table", function() return "x" end },
	{ "croquis invalide", function(x) x.croquis.jupe = "corsage_droit" end },
	{ "pièces absentes", function(x) table.remove(x.pieces) end },
	{ "pièce hors croquis", function(x) x.pieces[1].id = "corsage_droit_devant" end },
	{ "tissu inconnu", function(x) x.pieces[2].tissu = "papier" end },
	{ "x non fini", function(x) x.pieces[1].x = 0 / 0 end },
	{ "angle démesuré", function(x) x.pieces[1].angle = 1e18 end },
	{ "couture > 1", function(x) x.pieces[1].couture = 2 end },
	{ "mesure hors limites", function(x) x.mesures.taille = 40 end },
	{ "mesure manquante", function(x) x.mesures.hanches = nil end },
	{ "taille plus large que la poitrine", function(x) x.mesures.taille = x.mesures.poitrine + 0.5 end },
	{ "accessoire inconnu", function(x) x.accessoires[1].id = "diamant" end },
	{ "pièce 0", function(x) x.accessoires[1].piece = 0 end },
	{ "pièce 1,5", function(x) x.accessoires[1].piece = 1.5 end },
	{ "copie invalide", function(x) x.accessoires[2].copie = "milieu" end },
	{ "u non fini", function(x) x.accessoires[1].u = 0 / 0 end },
	{ "échelle démesurée", function(x) x.accessoires[1].echelle = 10 end },
	{ "garniture d'un point", function(x) x.accessoires[3].trajet = { { u = 0, v = 0 } } end },
	{ "garniture hors pièce", function(x) x.accessoires[3].trajet[2].u = 1.5 end },
	{ "garniture de 65 points", function(x)
		local t = {}
		for k = 1, 65 do
			t[k] = { u = k / 65, v = 0.5 }
		end
		x.accessoires[3].trajet = t
	end },
	{ "301 accessoires", function(x)
		for _ = 1, 298 do
			table.insert(x.accessoires, { id = "perle", piece = 1, u = 0.5, v = 0.5, echelle = 1, angle = 0 })
		end
	end },
}
for _, c in ipairs(cas) do
	local x = exemple()
	local remplace = c[2](x)
	local okV, message = Recette.valider(remplace or x)
	U.verifier(not okV and type(message) == "string", "recette refusée : " .. c[1])
end
local limite = exemple()
for _ = 1, 297 do
	table.insert(limite.accessoires, { id = "perle", piece = 1, u = 0.5, v = 0.5, echelle = 1, angle = 0 })
end
U.verifier(Recette.valider(limite), "300 accessoires acceptés")

-- Copie par défaut d'un accessoire
local e = exemple()
U.verifier(Recette.copieAccessoire(e, e.accessoires[1]) == "unique", "pièce non pliée : copie unique")
U.verifier(Recette.copieAccessoire(e, e.accessoires[2]) == "droite", "copie donnée explicitement")
U.verifier(Recette.copieAccessoire(e, { id = "perle", piece = 3 }) == "gauche", "pièce pliée : copie gauche par défaut")
```

- [ ] **Step 2: Vérifier qu'ils échouent**

Run: `bash tests/lancer.sh 2>&1 | grep -m1 "membre valide"`
Expected: `Recette n'est pas un membre valide de Folder « Couture »`

- [ ] **Step 3: Écrire le module**

`src/shared/Recette.luau` :

```lua
-- Recette : encodage JSON d'une recette de robe (pour les attributs des vitrines et la sauvegarde)
-- et validation complète d'une recette venue du réseau ou d'une sauvegarde.
local dossier = script.Parent
local Catalogue = require(dossier:WaitForChild("Catalogue"))
local Patron = require(dossier:WaitForChild("Patron"))

local Recette = {}

Recette.MAX_ACCESSOIRES = 300
Recette.MAX_POINTS_GARNITURE = 64
Recette.ANGLE_MAX = 3600
Recette.ECHELLE_MIN, Recette.ECHELLE_MAX = 0.5, 3
-- Tours acceptés (dm) ; la taille ne dépasse ni la poitrine ni les hanches
Recette.POITRINE = { 7, 13 }
Recette.TAILLE = { 5.5, 12 }
Recette.HANCHES = { 8, 14 }

local function fini(n)
	return type(n) == "number" and n == n and n ~= math.huge and n ~= -math.huge
end

---------------------------------------------------------------------------
-- JSON (sous-ensemble : tables, chaînes, nombres finis, booléens)
---------------------------------------------------------------------------
local function estTableau(t)
	local n = #t
	for cle in pairs(t) do
		if type(cle) ~= "number" or cle < 1 or cle > n or cle ~= math.floor(cle) then
			return false
		end
	end
	return true
end

local function encoderChaine(s)
	return '"' .. s:gsub('[%c"\\]', function(c)
		if c == '"' then
			return '\\"'
		elseif c == "\\" then
			return "\\\\"
		end
		return string.format("\\u%04x", string.byte(c))
	end) .. '"'
end

local function encoderValeur(v, profondeur)
	assert(profondeur < 20, "recette trop profonde")
	local t = type(v)
	if t == "number" then
		assert(fini(v), "nombre non fini dans la recette")
		if v == math.floor(v) and math.abs(v) < 1e15 then
			return string.format("%d", v)
		end
		return string.format("%.10g", v)
	elseif t == "string" then
		return encoderChaine(v)
	elseif t == "boolean" then
		return v and "true" or "false"
	elseif t == "table" then
		local parties = {}
		if estTableau(v) then
			for _, e in ipairs(v) do
				table.insert(parties, encoderValeur(e, profondeur + 1))
			end
			return "[" .. table.concat(parties, ",") .. "]"
		end
		local cles = {}
		for cle in pairs(v) do
			assert(type(cle) == "string", "clé non textuelle dans la recette")
			table.insert(cles, cle)
		end
		table.sort(cles) -- encodage stable
		for _, cle in ipairs(cles) do
			table.insert(parties, encoderChaine(cle) .. ":" .. encoderValeur(v[cle], profondeur + 1))
		end
		return "{" .. table.concat(parties, ",") .. "}"
	end
	error("valeur non encodable : " .. t)
end

function Recette.encoder(recette)
	return encoderValeur(recette, 0)
end

-- Décodeur : retourne la valeur, ou nil et un message si le texte est invalide
local function decoder(texte)
	local i = 1
	local function espaces()
		i = texte:find("[^ \t\r\n]", i) or #texte + 1
	end
	local valeur
	local function chaine()
		i += 1
		local morceaux = {}
		while true do
			local c = texte:sub(i, i)
			if c == "" then
				error("chaîne non terminée")
			elseif c == '"' then
				i += 1
				return table.concat(morceaux)
			elseif c == "\\" then
				local e = texte:sub(i + 1, i + 1)
				if e == "u" then
					local code = tonumber(texte:sub(i + 2, i + 5), 16)
					assert(code, "échappement \\u invalide")
					table.insert(morceaux, utf8.char(code))
					i += 6
				else
					local simples = { ['"'] = '"', ["\\"] = "\\", ["/"] = "/", n = "\n", t = "\t", r = "\r", b = "\b", f = "\f" }
					assert(simples[e], "échappement invalide")
					table.insert(morceaux, simples[e])
					i += 2
				end
			else
				table.insert(morceaux, c)
				i += 1
			end
		end
	end
	function valeur(profondeur)
		assert(profondeur < 20, "texte trop profond")
		espaces()
		local c = texte:sub(i, i)
		if c == "{" then
			i += 1
			local t = {}
			espaces()
			if texte:sub(i, i) == "}" then
				i += 1
				return t
			end
			while true do
				espaces()
				assert(texte:sub(i, i) == '"', "clé attendue")
				local cle = chaine()
				espaces()
				assert(texte:sub(i, i) == ":", "« : » attendu")
				i += 1
				t[cle] = valeur(profondeur + 1)
				espaces()
				local s = texte:sub(i, i)
				i += 1
				if s == "}" then
					return t
				end
				assert(s == ",", "« , » ou « } » attendu")
			end
		elseif c == "[" then
			i += 1
			local t = {}
			espaces()
			if texte:sub(i, i) == "]" then
				i += 1
				return t
			end
			while true do
				table.insert(t, valeur(profondeur + 1))
				espaces()
				local s = texte:sub(i, i)
				i += 1
				if s == "]" then
					return t
				end
				assert(s == ",", "« , » ou « ] » attendu")
			end
		elseif c == '"' then
			return chaine()
		elseif texte:sub(i, i + 3) == "true" then
			i += 4
			return true
		elseif texte:sub(i, i + 4) == "false" then
			i += 5
			return false
		end
		local nombre = texte:match("^-?%d+%.?%d*[eE]?[-+]?%d*", i)
		assert(nombre and #nombre > 0, "valeur attendue")
		i += #nombre
		local n = tonumber(nombre)
		assert(fini(n), "nombre invalide")
		return n
	end
	local resultat = valeur(0)
	espaces()
	assert(i > #texte, "texte en trop")
	return resultat
end

function Recette.decoder(texte)
	if type(texte) ~= "string" then
		return nil, "pas un texte"
	end
	local ok, resultat = pcall(decoder, texte)
	if not ok then
		return nil, tostring(resultat)
	end
	return resultat
end

---------------------------------------------------------------------------
-- Validation d'une recette (données venues d'un client, d'un attribut ou d'une sauvegarde)
---------------------------------------------------------------------------
local function dans(n, a, b)
	return fini(n) and n >= a and n <= b
end

function Recette.valider(r)
	if type(r) ~= "table" or type(r.croquis) ~= "table" or type(r.pieces) ~= "table" or type(r.mesures) ~= "table" then
		return false, "Recette incomplète."
	end
	local ok, attendues = pcall(Patron.piecesDuCroquis, r.croquis)
	if not ok then
		return false, "Croquis invalide."
	end
	local m = r.mesures
	if not dans(m.poitrine, Recette.POITRINE[1], Recette.POITRINE[2]) or not dans(m.taille, Recette.TAILLE[1], Recette.TAILLE[2])
		or not dans(m.hanches, Recette.HANCHES[1], Recette.HANCHES[2]) or m.taille > m.poitrine or m.taille > m.hanches then
		return false, "Mesures invalides."
	end
	if #r.pieces ~= #attendues then
		return false, "Pièces différentes du croquis."
	end
	for i, p in ipairs(r.pieces) do
		if type(p) ~= "table" or p.id ~= attendues[i] then
			return false, "Pièces différentes du croquis."
		end
		if type(p.tissu) ~= "string" or not Catalogue.tissu(p.tissu) then
			return false, "Tissu inconnu."
		end
		if not fini(p.x) or not fini(p.y) or not dans(p.angle, -Recette.ANGLE_MAX, Recette.ANGLE_MAX) then
			return false, "Position de pièce invalide."
		end
		if not dans(p.couture, 0, 1) then
			return false, "Note de couture invalide."
		end
	end
	local accessoires = r.accessoires or {}
	if type(accessoires) ~= "table" or #accessoires > Recette.MAX_ACCESSOIRES then
		return false, "Trop d'accessoires."
	end
	for _, a in ipairs(accessoires) do
		local def = type(a) == "table" and type(a.id) == "string" and Catalogue.accessoire(a.id)
		if not def then
			return false, "Accessoire inconnu."
		end
		local piece = type(a.piece) == "number" and r.pieces[a.piece]
		if not piece or a.piece ~= math.floor(a.piece) then
			return false, "Accessoire sur une pièce inexistante."
		end
		if a.copie ~= nil and not table.find(Patron.copies(piece.id), a.copie) then
			return false, "Copie de pièce invalide."
		end
		if def.genre == "objet" then
			if not dans(a.u, 0, 1) or not dans(a.v, 0, 1) or not dans(a.echelle, Recette.ECHELLE_MIN, Recette.ECHELLE_MAX)
				or not dans(a.angle, -360, 360) then
				return false, "Accessoire mal placé."
			end
		else
			if type(a.trajet) ~= "table" or #a.trajet < 2 or #a.trajet > Recette.MAX_POINTS_GARNITURE then
				return false, "Garniture invalide."
			end
			for _, pt in ipairs(a.trajet) do
				if type(pt) ~= "table" or not dans(pt.u, 0, 1) or not dans(pt.v, 0, 1) then
					return false, "Garniture mal placée."
				end
			end
		end
	end
	return true
end

-- Copie d'une pièce sur laquelle est posé un accessoire (la première par défaut)
function Recette.copieAccessoire(r, a)
	return a.copie or Patron.copies(r.pieces[a.piece].id)[1]
end

return Recette
```

- [ ] **Step 4: Lancer les tests**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT"`
Expected:
```
Unitaires : 14494 vérifications
TOUT EST VERT : 181072 vérifications
```

- [ ] **Step 5: Commit**

```bash
git add src/shared/Recette.luau tests/unitaires/08_recette.luau
git commit -m "Ajoute Recette : JSON et validation complète d'une recette

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 4: Module `Maillage` (triangulation d'une pièce)

**Files:**
- Create: `src/shared/Maillage.luau`
- Test: `tests/unitaires/09_maillage.luau`

**Interfaces:**
- Consumes: `Catalogue.piece` ; `Polygone.boite`, `etendueLigne`, `contient` ; `Patron.point`, `Patron.normale`.
- Produces :
  - `Maillage.FINESSES = { robe = { colonnes = 12, lignes = 16 }, vitrine = { colonnes = 6, lignes = 8 } }` ;
  - `Maillage.piece(idPiece, copie, mesures, finesse) -> { positions: {Vector3}, normales: {Vector3}, uvs: { {u, v} }, patron: { {x, y} }, faces: { {i1, i2, i3} } }`. Positions en dm, repère du corps ; faces tournées vers l'extérieur ; uv dans la boîte du patron ;
  - `Maillage.boite(donnees) -> (centre: Vector3, taille: Vector3)` en dm.

- [ ] **Step 1: Écrire les tests**

`tests/unitaires/09_maillage.luau` :

```lua
local Catalogue = U.module("Catalogue")
local Polygone = U.module("Polygone")
local Patron = U.module("Patron")
local Maillage = U.module("Maillage")

local M = Catalogue.TAILLES.M

for id, def in pairs(Catalogue.Pieces) do
	for _, copie in ipairs(Patron.copies(id)) do
		local m = Maillage.piece(id, copie, M, "robe")
		local nSommets, nFaces = #m.positions, #m.faces
		U.verifier(nSommets <= 13 * 17 and nSommets == #m.normales and nSommets == #m.uvs, id .. " : sommets cohérents")
		U.verifier(nFaces >= 20, id .. " : au moins 20 triangles")
		local aireMaillage = 0
		for _, f in ipairs(m.faces) do
			for _, k in ipairs(f) do
				U.verifier(k >= 1 and k <= nSommets, id .. " : indice de sommet valide")
			end
			-- Centre du triangle dans la pièce (en coordonnées du patron)
			local a, b, c = m.patron[f[1]], m.patron[f[2]], m.patron[f[3]]
			U.verifier(Polygone.contient(def.contour, (a.x + b.x + c.x) / 3, (a.y + b.y + c.y) / 3), id .. " : triangle dans la pièce")
			aireMaillage += math.abs((b.x - a.x) * (c.y - a.y) - (c.x - a.x) * (b.y - a.y)) / 2
			-- Tourné vers l'extérieur
			local P = m.positions
			local n = (P[f[2]] - P[f[1]]):Cross(P[f[3]] - P[f[1]])
			U.verifier(n.Magnitude > 1e-9, id .. " : triangle non dégénéré")
			U.verifier(n:Dot(m.normales[f[1]] + m.normales[f[2]] + m.normales[f[3]]) > 0, id .. " : triangle tourné vers l'extérieur")
		end
		for _, uv in ipairs(m.uvs) do
			U.verifier(uv[1] >= -1e-9 and uv[1] <= 1 + 1e-9 and uv[2] >= -1e-9 and uv[2] <= 1 + 1e-9, id .. " : UV dans [0, 1]")
		end
		-- Le maillage couvre la pièce (encoches approchées : à 20 % près)
		local aire = Polygone.aire(def.contour)
		U.verifier(math.abs(aireMaillage - aire) / aire < 0.2, ("%s : couverture %.0f %%"):format(id, 100 * aireMaillage / aire))
	end
end

-- Le décolleté en V retire des triangles ; aucun triangle au fond du V
local v = Maillage.piece("corsage_v_devant", "unique", M, "robe")
local droit = Maillage.piece("corsage_droit_devant", "unique", M, "robe")
U.verifier(#v.faces < #droit.faces, "le décolleté en V retire des triangles")
for _, f in ipairs(v.faces) do
	local a, b, c = v.patron[f[1]], v.patron[f[2]], v.patron[f[3]]
	local cx, cy = (a.x + b.x + c.x) / 3, (a.y + b.y + c.y) / 3
	U.verifier(not (cy < 1.5 and math.abs(cx - 2.4) < 0.5), "aucun triangle dans le V")
end

-- Finesse de vitrine : moins de sommets
local fin, grossier = Maillage.piece("jupe_ample_devant", "unique", M, "robe"), Maillage.piece("jupe_ample_devant", "unique", M, "vitrine")
U.verifier(#grossier.positions < #fin.positions and #grossier.positions <= 7 * 9, "la vitrine a un maillage plus léger")
U.verifier(not pcall(Maillage.piece, "jupe_ample_devant", "unique", M, "ultra"), "finesse inconnue refusée")

-- Boîte englobante
local centre, taille = Maillage.boite(fin)
U.verifier(taille.X > 0 and taille.Y > 0 and taille.Z > 0, "boîte de taille positive")
U.verifier(centre.Y < 0, "une jupe est sous la taille")
```

- [ ] **Step 2: Vérifier qu'ils échouent**

Run: `bash tests/lancer.sh 2>&1 | grep -m1 "membre valide"`
Expected: `Maillage n'est pas un membre valide de Folder « Couture »`

- [ ] **Step 3: Écrire le module**

`src/shared/Maillage.luau` :

```lua
-- Maillage : quadrillage d'une pièce de patron en triangles, enroulée autour du corps.
-- Données pures (dm, repère du corps) : le client les copie ensuite dans un EditableMesh.
-- Chaque ligne du quadrillage va d'un bord à l'autre de la pièce : les bords de côté,
-- le haut et le bas suivent exactement le contour ; les encoches (décolleté) sont approchées
-- en retirant les triangles dont le centre tombe hors de la pièce.
local dossier = script.Parent
local Catalogue = require(dossier:WaitForChild("Catalogue"))
local Polygone = require(dossier:WaitForChild("Polygone"))
local Patron = require(dossier:WaitForChild("Patron"))

local Maillage = {}

Maillage.FINESSES = {
	robe = { colonnes = 12, lignes = 16 },
	vitrine = { colonnes = 6, lignes = 8 },
}

-- Retourne { positions = {Vector3}, normales = {Vector3}, uvs = { {u, v} }, patron = { {x, y} },
--            faces = { {i1, i2, i3} } } ; faces tournées vers l'extérieur.
-- uv : coordonnées dans la boîte du patron (0,0 en haut à gauche), comme l'image de Pixels.imagePiece.
function Maillage.piece(idPiece, copie, mesures, finesse)
	local def = Catalogue.piece(idPiece)
	assert(def, "pièce inconnue : " .. tostring(idPiece))
	local grille = Maillage.FINESSES[finesse or "robe"]
	assert(grille, "finesse inconnue : " .. tostring(finesse))
	local b = Polygone.boite(def.contour)
	local l, h = b.maxX - b.minX, b.maxY - b.minY
	local out = { positions = {}, normales = {}, uvs = {}, patron = {}, faces = {} }
	local indices = {}
	for j = 0, grille.lignes do
		local y = b.minY + h * j / grille.lignes
		local x0, x1 = Polygone.etendueLigne(def.contour, y)
		indices[j] = {}
		if x0 then
			for i = 0, grille.colonnes do
				local x = x0 + (x1 - x0) * i / grille.colonnes
				table.insert(out.positions, (Patron.point(idPiece, copie, x, y, mesures)))
				table.insert(out.normales, Patron.normale(idPiece, copie, x, y, mesures))
				table.insert(out.uvs, { (x - b.minX) / l, (y - b.minY) / h })
				table.insert(out.patron, { x = x, y = y })
				indices[j][i] = #out.positions
			end
		end
	end
	local function ajouter(a, c, d)
		local pa, pc, pd = out.patron[a], out.patron[c], out.patron[d]
		if not Polygone.contient(def.contour, (pa.x + pc.x + pd.x) / 3, (pa.y + pc.y + pd.y) / 3) then
			return
		end
		local P = out.positions
		local n = (P[c] - P[a]):Cross(P[d] - P[a])
		if n.Magnitude < 1e-9 then
			return -- triangle dégénéré (ligne réduite à un point)
		end
		local moyenne = out.normales[a] + out.normales[c] + out.normales[d]
		if n:Dot(moyenne) < 0 then
			c, d = d, c
		end
		table.insert(out.faces, { a, c, d })
	end
	for j = 0, grille.lignes - 1 do
		for i = 0, grille.colonnes - 1 do
			local a, bb = indices[j][i], indices[j][i + 1]
			local c, d = indices[j + 1][i], indices[j + 1][i + 1]
			if a and bb and c and d then
				ajouter(a, c, bb)
				ajouter(bb, c, d)
			end
		end
	end
	return out
end

-- Boîte englobante des positions (dm) : centre et taille
function Maillage.boite(donnees)
	local mn = Vector3.new(math.huge, math.huge, math.huge)
	local mx = Vector3.new(-math.huge, -math.huge, -math.huge)
	for _, p in ipairs(donnees.positions) do
		mn = Vector3.new(math.min(mn.X, p.X), math.min(mn.Y, p.Y), math.min(mn.Z, p.Z))
		mx = Vector3.new(math.max(mx.X, p.X), math.max(mx.Y, p.Y), math.max(mx.Z, p.Z))
	end
	return (mn + mx) / 2, mx - mn
end

return Maillage
```

- [ ] **Step 4: Lancer les tests**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT"`
Expected:
```
Unitaires : 66489 vérifications
TOUT EST VERT : 181072 vérifications
```

- [ ] **Step 5: Commit**

```bash
git add src/shared/Maillage.luau tests/unitaires/09_maillage.luau
git commit -m "Ajoute Maillage : triangulation des pièces enroulées autour du corps

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 5: Module `Mannequin`

**Files:**
- Create: `src/shared/Mannequin.luau`
- Test: `tests/unitaires/10_mannequin.luau`

**Interfaces:**
- Consumes: `Catalogue.STUDS_PAR_DM`.
- Produces :
  - `Mannequin.HAUTEUR_TAILLE = 9` (dm entre le sol et la taille) ;
  - `Mannequin.formes(mesures) -> { { nom, forme = "ellipsoide" | "cylindre", centre: Vector3 (dm), taille: Vector3 (dm), couleur } }`, dans l'ordre : Buste, Taille, Bassin, EpauleDroite, EpauleGauche, Cou, Bouton, Pied, Socle ;
  - `Mannequin.construire(mesures, cadre: CFrame, parent) -> Model` (pièces ancrées, ellipsoïdes par `SpecialMesh` sphère).

  Le corps (0,95 × les tours) reste à l'intérieur des corsages et des jupes pour toutes les mesures acceptées par `Recette.valider`. Le test couvre les tailles S/M/L et toutes les silhouettes extrêmes.

- [ ] **Step 1: Écrire les tests**

`tests/unitaires/10_mannequin.luau` :

```lua
local Catalogue = U.module("Catalogue")
local Polygone = U.module("Polygone")
local Patron = U.module("Patron")
local Mannequin = U.module("Mannequin")

local function dansEllipsoide(p, f)
	local a = f.taille / 2
	local d = p - f.centre
	return (d.X / a.X) ^ 2 + (d.Y / a.Y) ^ 2 + (d.Z / a.Z) ^ 2 < 1
end

-- Tailles du catalogue et silhouettes extrêmes acceptées par Recette.valider
local Recette = U.module("Recette")
local tailles = table.clone(Catalogue.TAILLES)
for _, P in ipairs({ Recette.POITRINE[1], Recette.POITRINE[2] }) do
	for _, T in ipairs({ Recette.TAILLE[1], Recette.TAILLE[2] }) do
		for _, H in ipairs({ Recette.HANCHES[1], Recette.HANCHES[2] }) do
			if T <= P and T <= H then
				tailles[("P%g-T%g-H%g"):format(P, T, H)] = { poitrine = P, taille = T, hanches = H }
			end
		end
	end
end
for nomTaille, mesures in pairs(tailles) do
	local formes = Mannequin.formes(mesures)
	for _, f in ipairs(formes) do
		U.verifier(f.taille.X > 0 and f.taille.Y > 0 and f.taille.Z > 0, f.nom .. " : taille positive")
	end
	-- Aucun point des corsages et des jupes à l'intérieur du buste, de la taille ou du bassin
	local corps = { formes[1], formes[2], formes[3] }
	for id, def in pairs(Catalogue.Pieces) do
		local t = def.enroulement.type
		if t == "corsage" or t == "jupe" then
			local b = Polygone.boite(def.contour)
			for j = 0, 12 do
				local y = b.minY + (b.maxY - b.minY) * j / 12
				local x0, x1 = Polygone.etendueLigne(def.contour, y)
				for i = 0, 8 do
					local p = Patron.point(id, "unique", x0 + (x1 - x0) * i / 8, y, mesures)
					for _, f in ipairs(corps) do
						U.verifier(not dansEllipsoide(p, f), ("%s (%s) : le %s ne traverse pas le tissu"):format(id, nomTaille, f.nom))
					end
				end
			end
		end
	end
	-- Le socle touche le sol
	local socle = formes[#formes]
	U.verifier(U.proche(socle.centre.Y - socle.taille.Y / 2, -Mannequin.HAUTEUR_TAILLE), nomTaille .. " : socle posé au sol")
end

-- Construction (pièces ancrées, sphères déformées en ellipsoïdes)
M.initialiser()
local cadre = CFrame.new(10, Mannequin.HAUTEUR_TAILLE * Catalogue.STUDS_PAR_DM, 5)
local modele = Mannequin.construire(Catalogue.TAILLES.M, cadre, M.services.Workspace)
local formes = Mannequin.formes(Catalogue.TAILLES.M)
U.verifier(modele.Parent == M.services.Workspace and #modele:GetChildren() == #formes, "une pièce par forme")
for _, f in ipairs(formes) do
	local p = modele:FindFirstChild(f.nom)
	U.verifier(p ~= nil and p.Anchored, f.nom .. " : pièce ancrée")
	if f.forme == "ellipsoide" then
		U.verifier(p:FindFirstChild("SpecialMesh") ~= nil, f.nom .. " : sphère déformée")
		U.verifier(U.proche((p.Size - f.taille * Catalogue.STUDS_PAR_DM).Magnitude, 0), f.nom .. " : taille en studs")
	end
end
U.verifier(U.proche(modele.Socle.CFrame.Position.Y, 0.15 * Catalogue.STUDS_PAR_DM, 1e-6), "le socle est au niveau du sol du monde")
```

- [ ] **Step 2: Vérifier qu'ils échouent**

Run: `bash tests/lancer.sh 2>&1 | grep -m1 "membre valide"`
Expected: `Mannequin n'est pas un membre valide de Folder « Couture »`

- [ ] **Step 3: Écrire le module**

`src/shared/Mannequin.luau` :

```lua
-- Mannequin : buste de couturière sur pied, dimensionné selon les mesures de la cliente.
-- Repère du corps (dm) comme Patron : origine au centre de la taille, Y vers le haut, devant vers −Z.
-- Le corps est un peu plus fin que les vêtements (aisance de Patron) : rien ne traverse le tissu.
local dossier = script.Parent
local Catalogue = require(dossier:WaitForChild("Catalogue"))

local Mannequin = {}

Mannequin.HAUTEUR_TAILLE = 9 -- dm entre le sol et la taille
local EX, EZ = 1.12, 0.88 -- même ellipse que Patron
local FINESSE = 0.95 -- le corps est 5 % plus fin que les tours mesurés
local CREME = { 236, 222, 200 }
local BOIS = { 120, 84, 56 }

-- Formes du mannequin : { nom, forme = "ellipsoide" | "cylindre", centre (dm), taille (dm), couleur }
-- Un cylindre est vertical : taille.Y = hauteur, taille.X = diamètre.
function Mannequin.formes(mesures)
	local rP = mesures.poitrine / (2 * math.pi) * FINESSE
	local rT = mesures.taille / (2 * math.pi) * FINESSE
	local rH = mesures.hanches / (2 * math.pi) * FINESSE
	local epaule = rP * EX + 0.25
	local bas = Mannequin.HAUTEUR_TAILLE
	-- Trois ellipsoïdes (buste, taille, bassin) : la silhouette suit aussi une taille très marquée
	return {
		{ nom = "Buste", forme = "ellipsoide", centre = Vector3.new(0, 2.4, 0), taille = Vector3.new(2 * rP * EX, 3.8, 2 * rP * EZ), couleur = CREME },
		{ nom = "Taille", forme = "ellipsoide", centre = Vector3.new(0, 0, 0), taille = Vector3.new(2 * rT * EX, 2, 2 * rT * EZ), couleur = CREME },
		{ nom = "Bassin", forme = "ellipsoide", centre = Vector3.new(0, -2, 0), taille = Vector3.new(2 * rH * EX, 3, 2 * rH * EZ), couleur = CREME },
		{ nom = "EpauleDroite", forme = "ellipsoide", centre = Vector3.new(epaule, 3.9, 0), taille = Vector3.new(0.9, 0.9, 0.9), couleur = CREME },
		{ nom = "EpauleGauche", forme = "ellipsoide", centre = Vector3.new(-epaule, 3.9, 0), taille = Vector3.new(0.9, 0.9, 0.9), couleur = CREME },
		{ nom = "Cou", forme = "cylindre", centre = Vector3.new(0, 4.55, 0), taille = Vector3.new(0.9, 0.9, 0.9), couleur = CREME },
		{ nom = "Bouton", forme = "ellipsoide", centre = Vector3.new(0, 5.15, 0), taille = Vector3.new(0.7, 0.5, 0.7), couleur = BOIS },
		{ nom = "Pied", forme = "cylindre", centre = Vector3.new(0, -(3.5 + bas) / 2, 0), taille = Vector3.new(0.4, bas - 3.5, 0.4), couleur = BOIS },
		{ nom = "Socle", forme = "cylindre", centre = Vector3.new(0, -bas + 0.15, 0), taille = Vector3.new(4, 0.3, 4), couleur = BOIS },
	}
end

-- Construit le mannequin (pièces ancrées) ; cadre = CFrame de la taille dans le monde (studs)
function Mannequin.construire(mesures, cadre, parent)
	local e = Catalogue.STUDS_PAR_DM
	local modele = Instance.new("Model")
	modele.Name = "Mannequin"
	for _, f in ipairs(Mannequin.formes(mesures)) do
		local p = Instance.new("Part")
		p.Name = f.nom
		p.Anchored = true
		p.CanCollide = f.nom == "Socle"
		p.CanTouch = false
		p.Material = Enum.Material.SmoothPlastic
		p.Color = Color3.fromRGB(f.couleur[1], f.couleur[2], f.couleur[3])
		if f.forme == "cylindre" then
			p.Shape = Enum.PartType.Cylinder -- l'axe du cylindre est X : on le couche à la verticale
			p.Size = Vector3.new(f.taille.Y, f.taille.X, f.taille.Z) * e
			p.CFrame = cadre * CFrame.new(f.centre * e) * CFrame.Angles(0, 0, math.pi / 2)
		else
			p.Size = f.taille * e
			p.CFrame = cadre * CFrame.new(f.centre * e)
			local sphere = Instance.new("SpecialMesh")
			sphere.MeshType = Enum.MeshType.Sphere
			sphere.Parent = p
		end
		p.Parent = modele
	end
	modele.Parent = parent
	return modele
end

return Mannequin
```

- [ ] **Step 4: Lancer les tests**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT"`
Expected:
```
Unitaires : 103096 vérifications
TOUT EST VERT : 181072 vérifications
```

- [ ] **Step 5: Commit**

```bash
git add src/shared/Mannequin.luau tests/unitaires/10_mannequin.luau
git commit -m "Ajoute Mannequin : buste de couturière dimensionné selon les mesures

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 6: Module `Editables` et doublures des API modifiables

**Files:**
- Modify: `tests/mock.luau`
- Modify: `tests/build.py`
- Modify: `tests/gen_api.py`
- Create: `src/shared/Editables.luau`
- Test: `tests/unitaires/11_editables.luau`

**Interfaces:**
- Consumes: `Maillage.boite` ; dans le simulateur, les définitions 1.70.1 de la tâche 1.
- Produces :
  - simulateur : `M.budget = { images, maillages }`, `M.editables = { images, maillages, maxImages, maxMaillages }` (objets vivants et maximum observé). `Content.fromObject`, `AssetService:CreateEditableImage`, `CreateEditableMesh`, `CreateDataModelContentAsync` et `CreateMeshPartAsync` se comportent comme mesuré par le spike. Le `MeshPart` créé garde la trace de son contenu (`rawget(part, "__contenu")`) ;
  - `Editables.image(buf, largeur, hauteur) -> EditableImage?` ;
  - `Editables.maillage(donnees, echelle) -> (EditableMesh?, centre: Vector3 studs)` : maillage centré sur sa boîte, avec doublure ;
  - `Editables.figer(objet) -> Content?` ;
  - `Editables.piece(contenuMaillage) -> MeshPart?`.

- [ ] **Step 1: Écrire les tests**

`tests/unitaires/11_editables.luau` :

```lua
local Catalogue = U.module("Catalogue")
local Maillage = U.module("Maillage")
local Editables = U.module("Editables")

local e = Catalogue.STUDS_PAR_DM
M.budget.images, M.budget.maillages = 64, 7

-- Image
local buf = buffer.create(4 * 3 * 4)
local img = Editables.image(buf, 4, 3)
U.verifier(img ~= nil and img.pixels == buf and img.Size.X == 4, "image remplie avec le buffer")
img:Destroy()
M.budget.images = 0
U.verifier(Editables.image(buf, 4, 3) == nil, "mémoire des images pleine : nil, sans erreur")
M.budget.images = 64

-- Maillage : doublure, normales, centrage
local donnees = Maillage.piece("jupe_trapeze_devant", "unique", Catalogue.TAILLES.M, "vitrine")
local em, centre = Editables.maillage(donnees, e)
U.verifier(em ~= nil and #em.sommets == #donnees.positions, "un sommet par point du maillage")
U.verifier(#em.faces == 2 * #donnees.faces, "chaque triangle a sa doublure")
local centreDm = Maillage.boite(donnees)
U.verifier(U.proche((centre - centreDm * e).Magnitude, 0), "centre en studs")
local mn, mx = Vector3.new(math.huge, math.huge, math.huge), Vector3.new(-math.huge, -math.huge, -math.huge)
for _, p in ipairs(em.sommets) do
	mn = Vector3.new(math.min(mn.X, p.X), math.min(mn.Y, p.Y), math.min(mn.Z, p.Z))
	mx = Vector3.new(math.max(mx.X, p.X), math.max(mx.Y, p.Y), math.max(mx.Z, p.Z))
end
U.verifier(U.proche(((mn + mx) / 2).Magnitude, 0, 1e-9), "maillage centré sur sa boîte (indépendant du recentrage de Roblox)")
for f = 1, #em.faces, 2 do
	local exterieur, doublure = em.faces[f], em.faces[f + 1]
	U.verifier(exterieur[1] == doublure[1] and exterieur[2] == doublure[3] and exterieur[3] == doublure[2], "doublure = triangle inversé")
	local nExt = em.normales[em.normalesFaces[f][1]]
	local nInt = em.normales[em.normalesFaces[f + 1][1]]
	U.verifier(U.proche((nExt + nInt).Magnitude, 0), "normales de la doublure opposées")
	U.verifier(em.uvsFaces[f] ~= nil and em.uvsFaces[f + 1] ~= nil, "UV sur les deux faces")
end

-- Conversion en contenu statique, puis destruction : la pièce garde sa forme
local contenu = Editables.figer(em)
U.verifier(contenu ~= nil and contenu.statique, "contenu statique obtenu")
em:Destroy()
local part = Editables.piece(contenu)
U.verifier(part ~= nil and part.ClassName == "MeshPart", "MeshPart créé depuis le contenu statique")
U.verifier(rawget(part, "__contenu").statique, "la forme vient d'un contenu statique")
U.verifier(U.proche((part.Size - (mx - mn)).Magnitude, 0, 1e-9), "taille du MeshPart = boîte du maillage")

-- Mémoire des maillages pleine : nil et le centre, sans erreur
M.budget.maillages = 0
local vide, c2 = Editables.maillage(donnees, e)
U.verifier(vide == nil and c2 ~= nil, "mémoire des maillages pleine : nil, sans erreur")
M.budget.maillages = 7
U.verifier(M.editables.images == 0 and M.editables.maillages == 0, "aucun objet modifiable oublié")
```

- [ ] **Step 2: Vérifier qu'ils échouent**

Run: `bash tests/lancer.sh 2>&1 | grep -m1 -E "membre valide|ÉCHEC|error"`
Expected: `Editables n'est pas un membre valide de Folder « Couture »`

- [ ] **Step 3: Ajouter les doublures au simulateur**

`tests/mock.luau` :

```diff
diff --git a/tests/mock.luau b/tests/mock.luau
index cbcf376..7a1a2a9 100644
--- a/tests/mock.luau
+++ b/tests/mock.luau
@@ -660,6 +660,7 @@ function M.initialiser()
 		"ContextActionService",
 		"ProximityPromptService",
 		"ServerScriptService",
+		"AssetService",
 	}) do
 		local s = nouvelleInstance(nom)
 		s.Parent = game
@@ -724,6 +725,141 @@ function M.nouveauJoueur(nom)
 	return joueur
 end
 
+---------------------------------------------------------------------------
+-- API modifiables (EditableImage, EditableMesh) et contenu statique, comme mesuré par le spike :
+-- - CreateEditableImage / CreateEditableMesh renvoient nil quand le budget est atteint ;
+-- - CreateDataModelContentAsync renvoie deux valeurs : Enum.CreateContentResult, puis le Content ;
+-- - un MeshPart créé depuis un EditableMesh (sans conversion) perd sa forme quand celui-ci est détruit.
+---------------------------------------------------------------------------
+M.budget = { images = 64, maillages = 7 }
+M.editables = { images = 0, maillages = 0, maxImages = 0, maxMaillages = 0 }
+
+local CONTENU = { __type = "Content" }
+CONTENU.__index = CONTENU
+local Content = {}
+function Content.fromObject(objet)
+	assert(type(objet) == "table" and rawget(objet, "__editable"), "Content.fromObject attend un objet modifiable")
+	assert(not objet.__detruit, "Content.fromObject : objet détruit")
+	return setmetatable({ objet = objet }, CONTENU)
+end
+Content.none = setmetatable({ vide = true }, CONTENU)
+M.Content = Content
+
+local function compter(genre, delta)
+	local e = M.editables
+	e[genre] += delta
+	if genre == "images" then
+		e.maxImages = math.max(e.maxImages, e.images)
+	else
+		e.maxMaillages = math.max(e.maxMaillages, e.maillages)
+	end
+end
+
+local IMAGE = { __type = "Object" }
+IMAGE.__index = IMAGE
+function IMAGE:WritePixelsBuffer(position, taille, buf)
+	assert(not self.__detruit, "EditableImage détruite")
+	assert(typeDe(position) == "Vector2" and typeDe(taille) == "Vector2", "WritePixelsBuffer : Vector2 attendus")
+	assert(type(buf) == "buffer" and buffer.len(buf) == taille.X * taille.Y * 4, "WritePixelsBuffer : taille du buffer incorrecte")
+	assert(taille.X <= self.Size.X and taille.Y <= self.Size.Y, "WritePixelsBuffer : dépasse l'image")
+	self.pixels = buf
+end
+function IMAGE:Destroy()
+	if not self.__detruit then
+		self.__detruit = true
+		compter("images", -1)
+	end
+end
+
+local MAILLAGE = { __type = "Object" }
+MAILLAGE.__index = MAILLAGE
+local function ajouterA(liste, valeur)
+	table.insert(liste, valeur)
+	return #liste
+end
+function MAILLAGE:AddVertex(p)
+	assert(not self.__detruit and typeDe(p) == "Vector3", "AddVertex : Vector3 attendu")
+	return ajouterA(self.sommets, p)
+end
+function MAILLAGE:AddUV(uv)
+	assert(not self.__detruit and typeDe(uv) == "Vector2", "AddUV : Vector2 attendu")
+	return ajouterA(self.uvs, uv)
+end
+function MAILLAGE:AddNormal(n)
+	assert(not self.__detruit and typeDe(n) == "Vector3", "AddNormal : Vector3 attendu")
+	return ajouterA(self.normales, n)
+end
+function MAILLAGE:AddTriangle(a, b, c)
+	for _, k in ipairs({ a, b, c }) do
+		assert(self.sommets[k], "AddTriangle : sommet inconnu")
+	end
+	return ajouterA(self.faces, { a, b, c })
+end
+function MAILLAGE:SetFaceUVs(f, ids)
+	assert(self.faces[f] and #ids == 3, "SetFaceUVs : face ou identifiants invalides")
+	for _, k in ipairs(ids) do
+		assert(self.uvs[k], "SetFaceUVs : UV inconnu")
+	end
+	self.uvsFaces[f] = ids
+end
+function MAILLAGE:SetFaceNormals(f, ids)
+	assert(self.faces[f] and #ids == 3, "SetFaceNormals : face ou identifiants invalides")
+	for _, k in ipairs(ids) do
+		assert(self.normales[k], "SetFaceNormals : normale inconnue")
+	end
+	self.normalesFaces[f] = ids
+end
+function MAILLAGE:Destroy()
+	if not self.__detruit then
+		self.__detruit = true
+		compter("maillages", -1)
+	end
+end
+
+function methodes.CreateEditableImage(_, options)
+	local taille = options and options.Size
+	assert(typeDe(taille) == "Vector2" and taille.X >= 1 and taille.Y >= 1 and taille.X <= 1024 and taille.Y <= 1024,
+		"CreateEditableImage : Size invalide")
+	if M.editables.images >= M.budget.images then
+		return nil
+	end
+	compter("images", 1)
+	return setmetatable({ __editable = "image", Size = taille }, IMAGE)
+end
+function methodes.CreateEditableMesh(_, _options)
+	if M.editables.maillages >= M.budget.maillages then
+		return nil
+	end
+	compter("maillages", 1)
+	return setmetatable({ __editable = "maillage", sommets = {}, uvs = {}, normales = {}, faces = {}, uvsFaces = {}, normalesFaces = {} }, MAILLAGE)
+end
+function methodes.CreateDataModelContentAsync(_, contenu, _options)
+	assert(typeDe(contenu) == "Content" and contenu.objet and not contenu.objet.__detruit, "CreateDataModelContentAsync : objet invalide")
+	local o = contenu.objet
+	local cliche = { genre = o.__editable }
+	if o.__editable == "image" then
+		cliche.taille, cliche.pixels = o.Size, o.pixels
+	else
+		cliche.sommets, cliche.faces = table.clone(o.sommets), table.clone(o.faces)
+		cliche.uvsFaces, cliche.normalesFaces = table.clone(o.uvsFaces), table.clone(o.normalesFaces)
+	end
+	return Enum.CreateContentResult.Success, setmetatable({ statique = true, cliche = cliche }, CONTENU)
+end
+function methodes.CreateMeshPartAsync(_, contenu, _options)
+	assert(typeDe(contenu) == "Content", "CreateMeshPartAsync : Content attendu")
+	local sommets = contenu.statique and contenu.cliche.sommets or (contenu.objet and contenu.objet.sommets)
+	assert(sommets and #sommets > 0, "CreateMeshPartAsync : maillage vide")
+	local mn, mx = v3(math.huge, math.huge, math.huge), v3(-math.huge, -math.huge, -math.huge)
+	for _, p in ipairs(sommets) do
+		mn = v3(math.min(mn.X, p.X), math.min(mn.Y, p.Y), math.min(mn.Z, p.Z))
+		mx = v3(math.max(mx.X, p.X), math.max(mx.Y, p.Y), math.max(mx.Z, p.Z))
+	end
+	local part = nouvelleInstance("MeshPart")
+	rawget(part, "__props").Size = mx - mn
+	rawset(part, "__contenu", contenu) -- les tests vérifient que la forme vient d'un contenu statique
+	return part
+end
+
 M.env = {
 	Vector3 = Vector3,
 	Vector2 = Vector2,
@@ -736,6 +872,7 @@ M.env = {
 	Instance = { new = nouvelleInstance },
 	typeof = typeDe,
 	task = task,
+	Content = Content,
 }
 
 return M
```

`tests/build.py` (`Content` dans l'environnement des modules) :

```diff
diff --git a/tests/build.py b/tests/build.py
index ed0210a..01e927e 100644
--- a/tests/build.py
+++ b/tests/build.py
@@ -4,8 +4,8 @@ ICI = os.path.dirname(os.path.abspath(__file__))
 sim = S + "/sim/"
 def lire(p): return open(p, encoding="utf-8").read()
 def nom(chemin): return os.path.basename(chemin)[: -len(".luau")]
-ENTETE = """local game, workspace, os, Vector3, Vector2, CFrame, Color3, UDim, UDim2, Enum, Random, Instance, typeof, task, require, warn =
-	M.game, M.services and M.services.Workspace, M.os, G.Vector3, G.Vector2, G.CFrame, G.Color3, G.UDim, G.UDim2, G.Enum, G.Random, G.Instance, G.typeof, G.task, requireModule, avertir
+ENTETE = """local game, workspace, os, Vector3, Vector2, CFrame, Color3, UDim, UDim2, Enum, Random, Instance, typeof, task, require, warn, Content =
+	M.game, M.services and M.services.Workspace, M.os, G.Vector3, G.Vector2, G.CFrame, G.Color3, G.UDim, G.UDim2, G.Enum, G.Random, G.Instance, G.typeof, G.task, requireModule, avertir, G.Content
 """
 OUTILS_UNITAIRES = """local U = { compte = 0 }
 function U.verifier(condition, message)
```

`tests/gen_api.py` (`AssetService` parmi les classes simulées) :

```diff
diff --git a/tests/gen_api.py b/tests/gen_api.py
index e5b782e..0f5b4da 100644
--- a/tests/gen_api.py
+++ b/tests/gen_api.py
@@ -38,7 +38,7 @@ print("ENUM CHECK:", "OK" if not bad else bad, file=sys.stderr)
 needed = set(re.findall(r'Instance\.new\("(\w+)"', src_all)) | set(re.findall(r'creer\(\s*"(\w+)"', src_all))
 needed |= {"Workspace","Players","ReplicatedStorage","DataStoreService","UserInputService","RunService",
            "ContextActionService","ProximityPromptService","Player","Model","Folder","ModuleScript","Script",
-           "LocalScript","Camera","Humanoid","Part","MeshPart","PlayerGui","DataModel","IntValue","RemoteFunction","ServerScriptService","StarterPlayer","StarterPlayerScripts","SpawnLocation"}
+           "LocalScript","Camera","Humanoid","Part","MeshPart","AssetService","PlayerGui","DataModel","IntValue","RemoteFunction","ServerScriptService","StarterPlayer","StarterPlayerScripts","SpawnLocation"}
 def anc(c):
     out = []
     while c:
```

- [ ] **Step 4: Écrire le module**

`src/shared/Editables.luau` :

```lua
-- Editables : le seul module qui touche aux API modifiables de Roblox (client uniquement).
-- Règles tirées du spike (docs/superpowers/spikes/2026-09-28-rendu-editable.md) :
-- - une création renvoie nil quand le budget mémoire est atteint (7 maillages sur PC) ;
-- - CreateDataModelContentAsync renvoie (Enum.CreateContentResult, Content) ;
-- - il faut convertir en contenu statique AVANT de détruire l'objet modifiable.
local AssetService = game:GetService("AssetService")
local dossier = script.Parent
local Maillage = require(dossier:WaitForChild("Maillage"))

local Editables = {}

-- Image modifiable remplie avec un buffer RVBA ; nil si la mémoire est pleine
function Editables.image(buf, largeur, hauteur)
	local ok, image = pcall(function()
		return AssetService:CreateEditableImage({ Size = Vector2.new(largeur, hauteur) })
	end)
	if not ok or not image then
		return nil
	end
	image:WritePixelsBuffer(Vector2.new(0, 0), Vector2.new(largeur, hauteur), buf)
	return image
end

-- Maillage modifiable à partir des données de Maillage.piece (dm), mis à l'échelle (studs par dm)
-- et centré sur sa boîte. Ajoute la doublure (faces inversées, normales opposées).
-- Retourne le maillage (ou nil si la mémoire est pleine) et le centre de la boîte en studs.
function Editables.maillage(donnees, echelle)
	local centreDm = Maillage.boite(donnees)
	local centre = centreDm * echelle
	local ok, em = pcall(function()
		return AssetService:CreateEditableMesh()
	end)
	if not ok or not em then
		return nil, centre
	end
	local sommets, uvs, dehors, dedans = {}, {}, {}, {}
	for i, p in ipairs(donnees.positions) do
		sommets[i] = em:AddVertex(p * echelle - centre)
		uvs[i] = em:AddUV(Vector2.new(donnees.uvs[i][1], donnees.uvs[i][2]))
		dehors[i] = em:AddNormal(donnees.normales[i])
		dedans[i] = em:AddNormal(-donnees.normales[i])
	end
	for _, f in ipairs(donnees.faces) do
		local a, b, c = f[1], f[2], f[3]
		local face = em:AddTriangle(sommets[a], sommets[b], sommets[c])
		em:SetFaceUVs(face, { uvs[a], uvs[b], uvs[c] })
		em:SetFaceNormals(face, { dehors[a], dehors[b], dehors[c] })
		local doublure = em:AddTriangle(sommets[a], sommets[c], sommets[b])
		em:SetFaceUVs(doublure, { uvs[a], uvs[c], uvs[b] })
		em:SetFaceNormals(doublure, { dedans[a], dedans[c], dedans[b] })
	end
	return em, centre
end

-- Contenu statique d'un objet modifiable (l'objet peut ensuite être détruit) ; nil en cas d'échec
function Editables.figer(objet)
	local ok, resultat, contenu = pcall(function()
		return AssetService:CreateDataModelContentAsync(Content.fromObject(objet))
	end)
	if ok and resultat == Enum.CreateContentResult.Success and contenu then
		return contenu
	end
	return nil
end

-- MeshPart à partir d'un contenu statique de maillage ; nil en cas d'échec
function Editables.piece(contenuMaillage)
	local ok, part = pcall(function()
		return AssetService:CreateMeshPartAsync(contenuMaillage)
	end)
	return ok and part or nil
end

return Editables
```

- [ ] **Step 5: Lancer les tests**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT"`
Expected:
```
Unitaires : 103396 vérifications
TOUT EST VERT : 181072 vérifications
```

- [ ] **Step 6: Commit**

```bash
git add tests/mock.luau tests/build.py tests/gen_api.py src/shared/Editables.luau tests/unitaires/11_editables.luau
git commit -m "Ajoute Editables et les doublures des API modifiables de Roblox

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 7: Module `ConstructeurRobe`

**Files:**
- Create: `src/shared/ConstructeurRobe.luau`
- Test: `tests/unitaires/12_constructeur.luau`
- Modify: `tests/build.py` (isolation des avertissements, étape 5)

**Interfaces:**
- Consumes: `Catalogue` (`tissu`, `piece`, `accessoire`, `MATIERES`, `STUDS_PAR_DM`) ; `Polygone.boite` ; `Patron.copies`, `point`, `normale` ; `Pixels.motif`, `imagePiece` ; `Maillage.piece`, `boite` ; `Recette.valider`, `copieAccessoire` ; `Editables.*`.
- Produces : `ConstructeurRobe.construire(recette, cadre: CFrame, parent: Instance, options?) -> Model « Robe »`.
  - options = `{ finesse = "robe" | "vitrine", etaler = boolean, surProgres = function(fait, total) }` ;
  - la robe est parentée dès le départ. Enfants : `MeshPart` nommés `Piece_<id>_<copie>`, et `Model` nommés `Accessoire_<id>` ;
  - erreur si la recette est invalide ;
  - si la mémoire manque, un seul avertissement par cause, sans erreur.

- [ ] **Step 1: Écrire les tests**

`tests/unitaires/12_constructeur.luau` :

```lua
local Catalogue = U.module("Catalogue")
local Patron = U.module("Patron")
local Maillage = U.module("Maillage")
local ConstructeurRobe = U.module("ConstructeurRobe")

local function exemple()
	return {
		croquis = { corsage = "corsage_v", manches = "manches_ballon", col = "col_sans", jupe = "jupe_trapeze" },
		mesures = table.clone(Catalogue.TAILLES.M),
		pieces = {
			{ id = "corsage_v_devant", tissu = "soie_rose_fleurs", x = 3.2, y = 2.5, angle = 45, couture = 0.92 },
			{ id = "corsage_droit_dos", tissu = "soie_rose_fleurs", x = 9.1, y = 2.5, angle = 0, couture = 1 },
			{ id = "manche_ballon", tissu = "satin_rose", x = 2, y = 7, angle = -90, couture = 0.5 },
			{ id = "jupe_trapeze_devant", tissu = "coton_blanc", x = 3.5, y = 12, angle = 0, couture = 0.75 },
			{ id = "jupe_trapeze_dos", tissu = "coton_blanc", x = 10, y = 12, angle = 180, couture = 0.8 },
		},
		accessoires = {
			{ id = "noeud_satin", piece = 1, u = 0.5, v = 0.9, echelle = 1.2, angle = 15 },
			{ id = "bouton_nacre", piece = 3, copie = "droite", u = 0.3, v = 0.4, echelle = 1, angle = 0 },
			{ id = "dentelle_blanche", piece = 4, trajet = { { u = 0, v = 1 }, { u = 0.5, v = 1 }, { u = 1, v = 1 } } },
		},
	}
end

M.initialiser()
M.budget.images, M.budget.maillages = 64, 7
M.editables.maxImages, M.editables.maxMaillages = 0, 0
local e = Catalogue.STUDS_PAR_DM
local cadre = CFrame.new(0, 3, -10)
local progres = {}
local robe = ConstructeurRobe.construire(exemple(), cadre, M.services.Workspace, {
	surProgres = function(fait, total)
		table.insert(progres, { fait, total })
	end,
})

-- 6 pièces (la manche ballon est coupée pliée : deux copies) et 3 accessoires
local pieces, accessoires = {}, {}
for _, enfant in ipairs(robe:GetChildren()) do
	if enfant.ClassName == "MeshPart" then
		pieces[enfant.Name] = enfant
	elseif enfant.Name:sub(1, 11) == "Accessoire_" then
		table.insert(accessoires, enfant)
	end
end
local noms = {}
for nom in pairs(pieces) do
	table.insert(noms, nom)
end
U.verifier(#noms == 6, "6 pièces de tissu (obtenu " .. #noms .. ")")
U.verifier(pieces["Piece_manche_ballon_gauche"] ~= nil and pieces["Piece_manche_ballon_droite"] ~= nil, "deux manches")
U.verifier(#accessoires == 3, "3 accessoires")
U.verifier(robe.Parent == M.services.Workspace and robe.Name == "Robe", "robe rangée sous le parent donné")

-- Chaque pièce : forme et texture statiques, ancrée, sans collision, bien placée
for nom, part in pairs(pieces) do
	U.verifier(rawget(part, "__contenu").statique, nom .. " : forme issue d'un contenu statique")
	U.verifier(part.TextureContent ~= nil and part.TextureContent.statique, nom .. " : texture statique")
	U.verifier(part.Anchored and not part.CanCollide and not part.CanTouch, nom .. " : ancrée, sans collision")
end
local satin = pieces["Piece_manche_ballon_droite"]
U.verifier(satin.Material == Enum.Material.SmoothPlastic and U.proche(satin.Reflectance, 0.15), "satin : lisse et brillant")
U.verifier(pieces["Piece_jupe_trapeze_devant_unique"].Material == Enum.Material.Fabric, "coton : matière tissu")
local donnees = Maillage.piece("jupe_trapeze_devant", "unique", Catalogue.TAILLES.M, "robe")
local centre = Maillage.boite(donnees) * e
local attendu = cadre * CFrame.new(centre)
U.verifier(U.proche((pieces["Piece_jupe_trapeze_devant_unique"].CFrame.Position - attendu.Position).Magnitude, 0, 1e-9),
	"pièce placée au centre de son maillage, dans le repère de la taille")
local image = pieces["Piece_jupe_trapeze_devant_unique"].TextureContent.cliche
U.verifier(image.taille.X <= 256 and image.taille.Y <= 256, "image de robe ≤ 256 px")

-- Mémoire : jamais plus d'un maillage et d'une image modifiables vivants, rien d'oublié
U.verifier(M.editables.maxMaillages == 1 and M.editables.maxImages == 1, "un seul objet modifiable à la fois")
U.verifier(M.editables.maillages == 0 and M.editables.images == 0, "tous les objets modifiables sont détruits")

-- Progression
U.verifier(#progres == 9 and progres[9][1] == 9 and progres[9][2] == 9, "progression : 6 pièces + 3 accessoires")

-- Accessoires : le nœud est posé sur le devant du corsage
local noeud = robe:FindFirstChild("Accessoire_noeud_satin")
local pos, n = Patron.point("corsage_v_devant", "unique", 0.5 * 4.8, 0.9 * 4.2, Catalogue.TAILLES.M)
local voulu = cadre * ((pos + n * 0.05) * e)
local centreNoeud = Vector3.new(0, 0, 0)
local enfants = noeud:GetChildren()
for _, p in ipairs(enfants) do
	centreNoeud += p.CFrame.Position
end
centreNoeud /= #enfants
U.verifier((centreNoeud - voulu).Magnitude < 0.1, "nœud posé sur le corsage")
U.verifier(voulu.Z < cadre.Position.Z, "le nœud est sur le devant (−Z)")
local dentelle = robe:FindFirstChild("Accessoire_dentelle_blanche")
U.verifier(#dentelle:GetChildren() >= 10, "dentelle en ruban de plaques")
for _, plaque in ipairs(dentelle:GetChildren()) do
	U.verifier(U.proche(plaque.Transparency, 0.15), "dentelle légèrement transparente")
end

-- Vitrine : images plus petites
local vitrine = ConstructeurRobe.construire(exemple(), cadre, M.services.Workspace, { finesse = "vitrine" })
local img = vitrine:FindFirstChild("Piece_jupe_trapeze_devant_unique").TextureContent.cliche
U.verifier(img.taille.X <= 128 and img.taille.Y <= 128, "image de vitrine ≤ 128 px")

-- Mémoire des images pleine : pièces en couleur unie, un seul avertissement
M.avertissements = {}
M.budget.images = 0
local unie = ConstructeurRobe.construire(exemple(), cadre, M.services.Workspace, {})
local blanche = unie:FindFirstChild("Piece_jupe_trapeze_devant_unique")
U.verifier(blanche.TextureContent == nil and blanche.Color == Color3.fromRGB(246, 242, 234), "sans image : couleur du tissu")
U.verifier(#M.avertissements == 1, "un seul avertissement pour toute la robe")
M.budget.images = 64

-- Mémoire des maillages pleine : aucune pièce, pas d'erreur
M.budget.maillages = 0
local vide = ConstructeurRobe.construire(exemple(), cadre, M.services.Workspace, {})
local nb = 0
for _, enfant in ipairs(vide:GetChildren()) do
	if enfant.ClassName == "MeshPart" then
		nb += 1
	end
end
U.verifier(nb == 0, "sans mémoire de maillage : aucune pièce, pas d'erreur")
M.budget.maillages = 7

-- Recette invalide refusée
local mauvaise = exemple()
mauvaise.pieces[1].tissu = "papier"
U.verifier(not pcall(ConstructeurRobe.construire, mauvaise, cadre, M.services.Workspace, {}), "recette invalide refusée")

-- Accessoire là où la normale est presque verticale (dessus du col Claudine) : repère sans NaN
local col = exemple()
col.croquis.col = "col_claudine"
table.insert(col.pieces, 4, { id = "col_claudine", tissu = "coton_blanc", x = 2, y = 9, angle = 0, couture = 1 })
col.accessoires = { { id = "perle", piece = 4, copie = "droite", u = 0.5, v = 0.95, echelle = 1, angle = 30 } }
local robeCol = ConstructeurRobe.construire(col, cadre, M.services.Workspace, {})
local perle = robeCol:FindFirstChild("Accessoire_perle"):GetChildren()[1]
local p = perle.CFrame.Position
local l = perle.CFrame.LookVector
U.verifier(p.X == p.X and p.Y == p.Y and p.Z == p.Z and l.X == l.X and l.Y == l.Y and l.Z == l.Z, "perle sur le col : repère fini")
```

- [ ] **Step 2: Vérifier qu'ils échouent**

Run: `bash tests/lancer.sh 2>&1 | grep -m1 "membre valide"`
Expected: `ConstructeurRobe n'est pas un membre valide de Folder « Couture »`

- [ ] **Step 3: Écrire le module**

`src/shared/ConstructeurRobe.luau` :

```lua
-- ConstructeurRobe : construit une robe 3D à partir d'une recette (client uniquement).
-- Chaîne par pièce (voir le spike) : maillage et image modifiables → contenu statique → MeshPart,
-- puis destruction immédiate des objets modifiables : jamais plus d'un maillage et d'une image vivants.
local dossier = script.Parent
local Catalogue = require(dossier:WaitForChild("Catalogue"))
local Polygone = require(dossier:WaitForChild("Polygone"))
local Patron = require(dossier:WaitForChild("Patron"))
local Pixels = require(dossier:WaitForChild("Pixels"))
local Maillage = require(dossier:WaitForChild("Maillage"))
local Recette = require(dossier:WaitForChild("Recette"))
local Editables = require(dossier:WaitForChild("Editables"))

local ConstructeurRobe = {}

local PLAFONDS = { robe = 256, vitrine = 128 } -- taille maximale des images de pièces (px)
local DECOLLEMENT = 0.05 -- dm : les accessoires sont posés juste au-dessus du tissu
local PAS_GARNITURE = 0.4 -- dm entre deux points d'une garniture
local JAUNE = Color3.fromRGB(255, 214, 90)

---------------------------------------------------------------------------
-- Motifs de tissu en cache (8 au plus)
---------------------------------------------------------------------------
local motifs, ordreMotifs = {}, {}
local function motif(idTissu)
	if not motifs[idTissu] then
		motifs[idTissu] = Pixels.motif(idTissu)
		table.insert(ordreMotifs, idTissu)
		if #ordreMotifs > 8 then
			motifs[table.remove(ordreMotifs, 1)] = nil
		end
	end
	return motifs[idTissu]
end

local avertis = {}
local function avertirUneFois(cle, message)
	if not avertis[cle] then
		avertis[cle] = true
		warn("[Atelier] " .. message)
	end
end

local function couleur(c)
	return Color3.fromRGB(c[1], c[2], c[3])
end

---------------------------------------------------------------------------
-- Pièces de tissu
---------------------------------------------------------------------------
local function construirePiece(p, copie, mesures, cadre, finesse)
	local tissu = Catalogue.tissu(p.tissu)
	local em, centre = Editables.maillage(Maillage.piece(p.id, copie, mesures, finesse), Catalogue.STUDS_PAR_DM)
	if not em then
		avertirUneFois("maillage", "Mémoire des maillages pleine : pièce non affichée.")
		return nil
	end
	local contenuMaillage = Editables.figer(em)
	em:Destroy()
	local part = contenuMaillage and Editables.piece(contenuMaillage)
	if not part then
		avertirUneFois("figer", "Conversion du maillage impossible : pièce non affichée.")
		return nil
	end
	local buf, largeur, hauteur = Pixels.imagePiece(motif(p.tissu), p.id, p, copie, PLAFONDS[finesse])
	local image = Editables.image(buf, largeur, hauteur)
	local contenuImage = image and Editables.figer(image)
	if image then
		image:Destroy()
	end
	if contenuImage then
		part.TextureContent = contenuImage
	else
		part.Color = couleur(tissu.motif.couleurs[1])
		avertirUneFois("image", "Mémoire des images pleine : pièce en couleur unie.")
	end
	local matiere = Catalogue.MATIERES[tissu.matiere]
	part.Material = Enum.Material[matiere.materiau]
	part.Reflectance = matiere.reflet
	part.Name = ("Piece_%s_%s"):format(p.id, copie)
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CFrame = cadre * CFrame.new(centre)
	return part
end

---------------------------------------------------------------------------
-- Accessoires
---------------------------------------------------------------------------
-- Fonction (u, v) → position et normale (dm, repère du corps) sur la pièce de l'accessoire
local function surPiece(recette, a)
	local p = recette.pieces[a.piece]
	local copie = Recette.copieAccessoire(recette, a)
	local b = Polygone.boite(Catalogue.piece(p.id).contour)
	return function(u, v)
		local x, y = b.minX + u * (b.maxX - b.minX), b.minY + v * (b.maxY - b.minY)
		return Patron.point(p.id, copie, x, y, recette.mesures), Patron.normale(p.id, copie, x, y, recette.mesures)
	end
end

-- Repère posé sur le tissu : face avant (−Z) tournée vers l'extérieur
local function repere(cadre, pos, normale)
	local e = Catalogue.STUDS_PAR_DM
	local ici = cadre * ((pos + normale * DECOLLEMENT) * e)
	local direction = cadre * ((pos + normale * (DECOLLEMENT + 1)) * e) - ici
	local haut = math.abs(direction.Unit.Y) > 0.99 and Vector3.new(0, 0, 1) or Vector3.new(0, 1, 0)
	return CFrame.lookAt(ici, ici + direction, haut)
end

local function bloc(parent, taille, cf, teinte, reflet, forme)
	local part = Instance.new("Part")
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.Material = Enum.Material.SmoothPlastic
	if forme then
		part.Shape = forme
	end
	part.Size = taille
	part.CFrame = cf
	part.Color = teinte
	part.Reflectance = reflet or 0
	part.Parent = parent
	return part
end

local FORMES = {}
function FORMES.boule(g, cf, s, c, r)
	bloc(g, Vector3.new(s, s, s), cf, c, r, Enum.PartType.Ball)
end
function FORMES.bloc(g, cf, s, c, r)
	bloc(g, Vector3.new(s, s, s * 0.3), cf, c, r)
end
function FORMES.cylindre(g, cf, s, c, r)
	bloc(g, Vector3.new(s * 0.3, s, s), cf * CFrame.Angles(0, math.pi / 2, 0), c, r, Enum.PartType.Cylinder)
end
function FORMES.noeud(g, cf, s, c, r)
	bloc(g, Vector3.new(s * 0.45, s * 0.3, s * 0.12), cf * CFrame.new(-s * 0.25, 0, 0) * CFrame.Angles(0, 0, 0.35), c, r)
	bloc(g, Vector3.new(s * 0.45, s * 0.3, s * 0.12), cf * CFrame.new(s * 0.25, 0, 0) * CFrame.Angles(0, 0, -0.35), c, r)
	bloc(g, Vector3.new(s * 0.16, s * 0.16, s * 0.16), cf * CFrame.new(0, 0, -s * 0.03), c, r, Enum.PartType.Ball)
end
function FORMES.fleur(g, cf, s, c, r)
	for k = 0, 4 do
		local a = k * 2 * math.pi / 5
		bloc(g, Vector3.new(s * 0.4, s * 0.4, s * 0.4), cf * CFrame.new(math.cos(a) * s * 0.28, math.sin(a) * s * 0.28, 0), c, r, Enum.PartType.Ball)
	end
	bloc(g, Vector3.new(s * 0.3, s * 0.3, s * 0.3), cf * CFrame.new(0, 0, -s * 0.05), JAUNE, 0, Enum.PartType.Ball)
end
function FORMES.croix(g, cf, s, c, r)
	bloc(g, Vector3.new(s * 0.2, s, s * 0.1), cf, c, r)
	bloc(g, Vector3.new(s * 0.6, s * 0.2, s * 0.1), cf * CFrame.new(0, s * 0.2, 0), c, r)
end

local function construireAccessoire(recette, a, cadre, parent)
	local def = Catalogue.accessoire(a.id)
	local ap = def.apparence
	local groupe = Instance.new("Model")
	groupe.Name = "Accessoire_" .. a.id
	local surface = surPiece(recette, a)
	local e = Catalogue.STUDS_PAR_DM
	if def.genre == "objet" then
		local pos, n = surface(a.u, a.v)
		local cf = repere(cadre, pos, n) * CFrame.Angles(0, 0, math.rad(a.angle))
		FORMES[ap.forme](groupe, cf, ap.taille * a.echelle * e, couleur(ap.couleur), ap.reflet)
	else
		-- Garniture : ruban de petites plaques qui suivent le tissu, la face large contre la pièce
		local points = {}
		for k = 1, #a.trajet - 1 do
			local p0, p1 = a.trajet[k], a.trajet[k + 1]
			local b = Polygone.boite(Catalogue.piece(recette.pieces[a.piece].id).contour)
			local du, dv = (p1.u - p0.u) * (b.maxX - b.minX), (p1.v - p0.v) * (b.maxY - b.minY)
			local etapes = math.max(1, math.ceil(math.sqrt(du * du + dv * dv) / PAS_GARNITURE))
			for s = (k == 1 and 0 or 1), etapes do
				local t = s / etapes
				local pos, n = surface(p0.u + (p1.u - p0.u) * t, p0.v + (p1.v - p0.v) * t)
				table.insert(points, { ici = cadre * ((pos + n * DECOLLEMENT) * e), haut = cadre * ((pos + n * (DECOLLEMENT + 1)) * e) })
			end
		end
		for k = 1, #points - 1 do
			local q0, q1 = points[k].ici, points[k + 1].ici
			local longueur = (q1 - q0).Magnitude
			if longueur > 1e-6 then
				local milieu = (q0 + q1) / 2
				local normale = points[k].haut - points[k].ici
				local part = bloc(groupe, Vector3.new(ap.largeur * e, 0.02, longueur), CFrame.lookAt(milieu, q1, normale), couleur(ap.couleur), 0)
				part.Transparency = ap.transparence
			end
		end
	end
	groupe.Parent = parent
	return groupe
end

---------------------------------------------------------------------------
-- Robe complète
---------------------------------------------------------------------------
-- recette : recette valide (Recette.valider). cadre : CFrame de la taille du mannequin (studs).
-- options : { finesse = "robe" | "vitrine", etaler = bool (une pièce par image),
--             surProgres = function(fait, total) }
-- Retourne le Model « Robe » (parenté tout de suite : les pièces apparaissent au fur et à mesure).
function ConstructeurRobe.construire(recette, cadre, parent, options)
	local ok, erreur = Recette.valider(recette)
	assert(ok, "recette invalide : " .. tostring(erreur))
	options = options or {}
	local finesse = options.finesse or "robe"
	assert(PLAFONDS[finesse], "finesse inconnue : " .. tostring(finesse))
	local modele = Instance.new("Model")
	modele.Name = "Robe"
	modele.Parent = parent
	local copies = {}
	for _, p in ipairs(recette.pieces) do
		for _, copie in ipairs(Patron.copies(p.id)) do
			table.insert(copies, { piece = p, copie = copie })
		end
	end
	local accessoires = recette.accessoires or {}
	local total = #copies + #accessoires
	for k, c in ipairs(copies) do
		local part = construirePiece(c.piece, c.copie, recette.mesures, cadre, finesse)
		if part then
			part.Parent = modele
		end
		if options.surProgres then
			options.surProgres(k, total)
		end
		if options.etaler then
			task.wait()
		end
		if modele.Parent == nil then
			return modele -- robe détruite pendant la construction (vitrine quittée)
		end
	end
	for k, a in ipairs(accessoires) do
		construireAccessoire(recette, a, cadre, modele)
		if options.surProgres then
			options.surProgres(#copies + k, total)
		end
	end
	return modele
end

return ConstructeurRobe
```

- [ ] **Step 4: Lancer les tests et constater la fuite d'avertissements**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT"`
Expected:
```
Unitaires : 103450 vérifications
TOUT EST VERT : 181074 vérifications
```

Les tests unitaires passent. Le scénario de l'ancien jeu compte 2 vérifications de trop : il parcourt `M.avertissements` et y trouve les avertissements laissés par `12_constructeur`.

- [ ] **Step 5: Isoler le scénario des avertissements des tests unitaires**

```diff
diff --git a/tests/build.py b/tests/build.py
index 01e927e..4593fa6 100644
--- a/tests/build.py
+++ b/tests/build.py
@@ -60,5 +60,6 @@ out.append(OUTILS_UNITAIRES)
 for f in sorted(glob.glob(ICI + "/unitaires/*.luau")):
     out.append("do\n" + ENTETE + lire(f) + "\nend")
 out.append("print((\"Unitaires : %d vérifications\"):format(U.compte))")
+out.append("M.avertissements = {} -- le scénario ne voit pas les avertissements des tests unitaires")
 out.append("do\n" + ENTETE + lire(sim + "scenario.luau") + "\nend")
 open(sim + "run.luau", "w", encoding="utf-8").write("\n".join(out))
```

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT"`
Expected:
```
Unitaires : 103450 vérifications
TOUT EST VERT : 181072 vérifications
```

- [ ] **Step 6: Commit**

```bash
git add src/shared/ConstructeurRobe.luau tests/unitaires/12_constructeur.luau tests/build.py
git commit -m "Ajoute ConstructeurRobe : robe 3D à partir d'une recette

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 8: Module `Vitrines`

**Files:**
- Create: `src/shared/Vitrines.luau`
- Test: `tests/unitaires/13_vitrines.luau`

**Interfaces:**
- Consumes: `Catalogue.STUDS_PAR_DM` ; `Recette.decoder`, `valider` ; `Mannequin.HAUTEUR_TAILLE`, `construire` ; `ConstructeurRobe.construire` ; `RunService.RenderStepped`.
- Produces :
  - `Vitrines.RAYON_CONSTRUIRE = 60`, `RAYON_LIBERER = 80`, `PERIODE = 0.5` ;
  - `Vitrines.cadre(socle) -> CFrame` (taille du mannequin posé sur le socle) ;
  - `Vitrines.nouveau(dossier, position: () -> Vector3, options?) -> { mettreAJour, arreter }`, avec options = `{ etaler = boolean }` (vrai par défaut). Chaque vitrine construite est un `Model « Exposition »` enfant du socle, qui contient le `Mannequin` et la `Robe`.

- [ ] **Step 1: Écrire les tests**

`tests/unitaires/13_vitrines.luau` :

```lua
local Catalogue = U.module("Catalogue")
local Recette = U.module("Recette")
local Vitrines = U.module("Vitrines")

local function recette(tissu)
	return {
		croquis = { corsage = "corsage_droit", manches = "manches_sans", col = "col_sans", jupe = "jupe_droite" },
		mesures = table.clone(Catalogue.TAILLES.S),
		pieces = {
			{ id = "corsage_droit_devant", tissu = tissu, x = 3, y = 3, angle = 0, couture = 1 },
			{ id = "corsage_droit_dos", tissu = tissu, x = 9, y = 3, angle = 0, couture = 1 },
			{ id = "jupe_droite_devant", tissu = tissu, x = 3, y = 10, angle = 0, couture = 1 },
			{ id = "jupe_droite_dos", tissu = tissu, x = 9, y = 10, angle = 0, couture = 1 },
		},
		accessoires = {},
	}
end

M.initialiser()
M.budget.images, M.budget.maillages = 64, 7
local ws = M.services.Workspace
local dossier = Instance.new("Folder")
dossier.Name = "Vitrines"
dossier.Parent = ws
local function socle(nom, x)
	local p = Instance.new("Part")
	p.Name = nom
	p.Size = Vector3.new(4, 1, 4)
	p.CFrame = CFrame.new(x, 0.5, 0)
	p.Parent = dossier
	return p
end
local proche, loin = socle("Proche", 10), socle("Loin", 200)
proche:SetAttribute("Recette", Recette.encoder(recette("lin_bleu")))
loin:SetAttribute("Recette", Recette.encoder(recette("soie_rouge")))
socle("SansRecette", 5)

local joueur = Vector3.new(0, 3, 0)
local v = Vitrines.nouveau(dossier, function()
	return joueur
end, { etaler = false })

local function robeDe(s)
	local expo = s:FindFirstChild("Exposition")
	return expo and expo:FindFirstChild("Robe")
end

-- Près du joueur : construite ; loin : rien ; socle sans recette : rien
M.avancer(0.6)
U.verifier(robeDe(proche) ~= nil, "la vitrine proche est construite")
U.verifier(proche.Exposition:FindFirstChild("Mannequin") ~= nil, "avec son mannequin")
U.verifier(robeDe(loin) == nil, "la vitrine lointaine n'est pas construite")
U.verifier(dossier.SansRecette:FindFirstChild("Exposition") == nil, "un socle sans recette reste vide")
local piece = robeDe(proche):FindFirstChild("Piece_jupe_droite_devant_unique")
U.verifier(piece.TextureContent.cliche.taille.X <= 128, "robe de vitrine en images réduites")
U.verifier(M.editables.maillages == 0 and M.editables.images == 0, "aucun objet modifiable gardé")

-- Mannequin posé sur le socle
local cadre = Vitrines.cadre(proche)
U.verifier(U.proche(cadre.Position.Y, 1 + 9 * Catalogue.STUDS_PAR_DM), "taille du mannequin à 2,7 studs au-dessus du socle")

-- Le joueur s'éloigne au-delà de 80 studs : libérée ; il revient : reconstruite
joueur = Vector3.new(100, 3, 0)
M.avancer(0.6)
U.verifier(proche:FindFirstChild("Exposition") == nil, "vitrine libérée au-delà de 80 studs")
joueur = Vector3.new(70, 3, 0) -- entre 60 et 80 : on ne construit pas encore
M.avancer(0.6)
U.verifier(proche:FindFirstChild("Exposition") == nil, "pas de construction entre 60 et 80 studs")
joueur = Vector3.new(0, 3, 0)
M.avancer(0.6)
U.verifier(robeDe(proche) ~= nil, "vitrine reconstruite au retour du joueur")

-- Nouvelle recette : la vitrine est refaite avec le nouveau tissu
proche:SetAttribute("Recette", Recette.encoder(recette("velours_noir")))
M.avancer(0.6)
local nouvelle = robeDe(proche):FindFirstChild("Piece_jupe_droite_devant_unique")
U.verifier(nouvelle ~= piece and nouvelle.Material == Enum.Material.Fabric, "vitrine refaite après changement de recette")
U.verifier(#proche:GetChildren() == 1, "l'ancienne exposition est supprimée")

-- Recette illisible ou invalide : ignorée avec un seul avertissement, sans erreur
M.avertissements = {}
proche:SetAttribute("Recette", "{pas du json")
M.avancer(0.6)
M.avancer(0.6)
U.verifier(proche:FindFirstChild("Exposition") == nil and #M.avertissements == 1, "recette illisible ignorée, un avertissement")
local triche = recette("lin_bleu")
triche.pieces[1].angle = 1e18
proche:SetAttribute("Recette", Recette.encoder(triche))
M.avancer(0.6)
U.verifier(proche:FindFirstChild("Exposition") == nil and #M.avertissements == 2, "recette invalide ignorée")

-- Socle retiré, puis arrêt : tout est libéré
proche:SetAttribute("Recette", Recette.encoder(recette("lin_bleu")))
M.avancer(0.6)
U.verifier(robeDe(proche) ~= nil, "vitrine reconstruite")
v.arreter()
U.verifier(proche:FindFirstChild("Exposition") == nil, "arrêt : vitrines libérées")
M.avancer(0.6)
U.verifier(proche:FindFirstChild("Exposition") == nil, "arrêt : plus de mise à jour")

-- Socle supprimé : l'exposition disparaît avec lui, sans erreur à la mise à jour suivante
local v2 = Vitrines.nouveau(dossier, function()
	return Vector3.new(0, 3, 0)
end, { etaler = false })
local autre = socle("Autre", 15)
autre:SetAttribute("Recette", Recette.encoder(recette("coton_blanc")))
M.avancer(0.6)
U.verifier(robeDe(autre) ~= nil, "vitrine « Autre » construite")
autre:Destroy()
M.avancer(0.6)
U.verifier(autre:FindFirstChild("Exposition") == nil, "socle supprimé : exposition libérée")
v2.arreter()
```

- [ ] **Step 2: Vérifier qu'ils échouent**

Run: `bash tests/lancer.sh 2>&1 | grep -m1 "membre valide"`
Expected: `Vitrines n'est pas un membre valide de Folder « Couture »`

- [ ] **Step 3: Écrire le module**

`src/shared/Vitrines.luau` :

```lua
-- Vitrines : construit les robes exposées près du joueur et les libère quand il s'éloigne (client).
-- Contrat avec le serveur (plan 4) : chaque socle de vitrine est une BasePart rangée dans un dossier
-- (workspace.Vitrines), avec l'attribut « Recette » = Recette.encoder(recette). Le mannequin est posé
-- sur le dessus du socle, face à l'avant du socle (−Z).
local dossierModules = script.Parent
local Catalogue = require(dossierModules:WaitForChild("Catalogue"))
local Recette = require(dossierModules:WaitForChild("Recette"))
local Mannequin = require(dossierModules:WaitForChild("Mannequin"))
local ConstructeurRobe = require(dossierModules:WaitForChild("ConstructeurRobe"))

local Vitrines = {}
Vitrines.RAYON_CONSTRUIRE = 60 -- studs
Vitrines.RAYON_LIBERER = 80
Vitrines.PERIODE = 0.5 -- secondes entre deux vérifications

-- Cadre de la taille du mannequin posé sur un socle
function Vitrines.cadre(socle)
	local hauteur = socle.Size.Y / 2 + Mannequin.HAUTEUR_TAILLE * Catalogue.STUDS_PAR_DM
	return socle.CFrame * CFrame.new(0, hauteur, 0)
end

-- dossier : Instance qui contient les socles. position : fonction qui renvoie la position du joueur.
-- options : { etaler = bool (défaut vrai) }. Retourne { mettreAJour = function(), arreter = function() }.
function Vitrines.nouveau(dossier, position, options)
	options = options or {}
	local etats = {} -- [socle] = { texte, groupe? }
	local enCours = false
	local avertis = {}

	local function liberer(socle)
		local etat = etats[socle]
		if etat and etat.groupe then
			etat.groupe:Destroy()
		end
		etats[socle] = nil
	end

	local function construire(socle, texte)
		local recette = Recette.decoder(texte)
		local ok, erreur = false, "texte illisible"
		if recette then
			ok, erreur = Recette.valider(recette)
		end
		if not ok then
			etats[socle] = { texte = texte } -- on ne réessaie pas tant que le texte ne change pas
			if not avertis[texte] then
				avertis[texte] = true
				warn("[Atelier] Vitrine ignorée : " .. tostring(erreur))
			end
			return
		end
		local groupe = Instance.new("Model")
		groupe.Name = "Exposition"
		groupe.Parent = socle
		etats[socle] = { texte = texte, groupe = groupe }
		local cadre = Vitrines.cadre(socle)
		Mannequin.construire(recette.mesures, cadre, groupe)
		enCours = true
		task.spawn(function()
			local okC, err = pcall(ConstructeurRobe.construire, recette, cadre, groupe, {
				finesse = "vitrine",
				etaler = options.etaler ~= false,
			})
			enCours = false
			if not okC then
				warn("[Atelier] Vitrine non construite : " .. tostring(err))
			end
		end)
	end

	local function mettreAJour()
		local ici = position()
		for socle in pairs(etats) do
			if socle.Parent ~= dossier then
				liberer(socle)
			end
		end
		for _, socle in ipairs(dossier:GetChildren()) do
			if socle:IsA("BasePart") then
				local distance = (socle.CFrame.Position - ici).Magnitude
				local texte = socle:GetAttribute("Recette")
				local etat = etats[socle]
				if etat and (distance > Vitrines.RAYON_LIBERER or etat.texte ~= texte) then
					liberer(socle)
					etat = nil
				end
				-- Une seule robe en construction à la fois : budget mémoire et fluidité
				if not etat and not enCours and distance <= Vitrines.RAYON_CONSTRUIRE and type(texte) == "string" then
					construire(socle, texte)
				end
			end
		end
	end

	local cumul = 0
	local connexion = game:GetService("RunService").RenderStepped:Connect(function(dt)
		cumul += dt
		if cumul >= Vitrines.PERIODE then
			cumul = 0
			mettreAJour()
		end
	end)

	return {
		mettreAJour = mettreAJour,
		arreter = function()
			connexion:Disconnect()
			for socle in pairs(etats) do
				liberer(socle)
			end
		end,
	}
end

return Vitrines
```

- [ ] **Step 4: Lancer les tests**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT"`
Expected:
```
Unitaires : 103469 vérifications
TOUT EST VERT : 181072 vérifications
```

- [ ] **Step 5: Commit**

```bash
git add src/shared/Vitrines.luau tests/unitaires/13_vitrines.luau
git commit -m "Ajoute Vitrines : robes exposées construites selon la distance

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 9: Banc d'essai dans Studio, rapport et README

**Files:**
- Create: `tests/studio/banc_rendu.luau`
- Modify: `docs/superpowers/spikes/2026-09-28-rendu-editable.md` (section ajoutée à la fin)
- Modify: `README.md` (lignes ajoutées au tableau de la refonte)
- Modify: `AtelierCouture.rbxl` (régénéré)

**Interfaces:**
- Consumes: tous les modules des tâches 2 à 8, chargés dans Studio.
- Produces: mesures réelles et vérification visuelle. C'est le point de départ du plan 3 (postes de jeu).

- [ ] **Step 1: Écrire le banc d'essai**

`tests/studio/banc_rendu.luau` :

```lua
-- Banc d'essai du rendu, à exécuter dans Roblox Studio en mode Play, côté client
-- (connecteur MCP Studio : execute_luau, datamodel « Client »). Il n'est pas lancé par tests/lancer.sh.
-- Construit, à 30 studs du point d'apparition :
--   1. une robe complète sur un mannequin (mesure du temps de génération) ;
--   2. un devant de jupe avec une image d'essai : moitié u < 0,5 rouge, quart du haut bleu,
--      et une bille verte au point (0,3 ; 0,3) du patron. Attendu, vu de face : bleu en haut,
--      rouge du côté de la bille verte (à gauche). Sinon, l'image est retournée ou en miroir.
local RS = game:GetService("ReplicatedStorage"):WaitForChild("Couture")
local Catalogue = require(RS.Catalogue)
local Patron = require(RS.Patron)
local Maillage = require(RS.Maillage)
local Mannequin = require(RS.Mannequin)
local Editables = require(RS.Editables)
local ConstructeurRobe = require(RS.ConstructeurRobe)

local e = Catalogue.STUDS_PAR_DM
local ancien = workspace:FindFirstChild("BancRendu")
if ancien then
	ancien:Destroy()
end
local banc = Instance.new("Folder")
banc.Name = "BancRendu"
banc.Parent = workspace
local function cadreAuSol(x, z)
	return CFrame.new(x, 0, z) * CFrame.Angles(0, math.pi, 0) * CFrame.new(0, Mannequin.HAUTEUR_TAILLE * e, 0)
end

-- 1. Robe complète
local recette = {
	croquis = { corsage = "corsage_v", manches = "manches_ballon", col = "col_claudine", jupe = "jupe_trapeze" },
	mesures = table.clone(Catalogue.TAILLES.M),
	pieces = {
		{ id = "corsage_v_devant", tissu = "soie_rose_fleurs", x = 3.2, y = 2.5, angle = 0, couture = 0.92 },
		{ id = "corsage_droit_dos", tissu = "soie_rose_fleurs", x = 9.1, y = 2.5, angle = 0, couture = 1 },
		{ id = "manche_ballon", tissu = "satin_rose", x = 2, y = 7, angle = 0, couture = 0.5 },
		{ id = "col_claudine", tissu = "coton_blanc", x = 2, y = 9, angle = 0, couture = 1 },
		{ id = "jupe_trapeze_devant", tissu = "soie_rose_fleurs", x = 3.5, y = 12, angle = 45, couture = 0.75 },
		{ id = "jupe_trapeze_dos", tissu = "soie_rose_fleurs", x = 10, y = 12, angle = 45, couture = 0.8 },
	},
	accessoires = {
		{ id = "noeud_satin", piece = 1, u = 0.5, v = 0.95, echelle = 1.2, angle = 0 },
		{ id = "bouton_nacre", piece = 1, u = 0.5, v = 0.6, echelle = 1, angle = 0 },
		{ id = "fleur_blanche", piece = 5, u = 0.3, v = 0.5, echelle = 1, angle = 0 },
		{ id = "dentelle_blanche", piece = 5, trajet = { { u = 0, v = 1 }, { u = 0.5, v = 1 }, { u = 1, v = 1 } } },
	},
}
local cadre = cadreAuSol(30, -34)
Mannequin.construire(recette.mesures, cadre, banc)
local t0 = os.clock()
local robe = ConstructeurRobe.construire(recette, cadre, banc, { finesse = "robe", etaler = false })
local robeMs = (os.clock() - t0) * 1000
local pieces = 0
for _, c in ipairs(robe:GetChildren()) do
	if c:IsA("MeshPart") then
		pieces += 1
	end
end
t0 = os.clock()
ConstructeurRobe.construire(recette, cadreAuSol(40, -34), banc, { finesse = "vitrine", etaler = false })
local vitrineMs = (os.clock() - t0) * 1000

-- 2. Test d'orientation de l'image
local cadre2 = cadreAuSol(36, -34)
Mannequin.construire(recette.mesures, cadre2, banc)
local em, centre = Editables.maillage(Maillage.piece("jupe_droite_devant", "unique", recette.mesures, "robe"), e)
local contenu = Editables.figer(em)
em:Destroy()
local part = Editables.piece(contenu)
local L, H = 64, 64
local buf = buffer.create(L * H * 4)
for j = 0, H - 1 do
	for i = 0, L - 1 do
		local r, g, b = 240, 240, 240
		if i < L / 2 then
			r, g, b = 220, 30, 30
		end
		if j < H / 4 then
			r, g, b = 30, 60, 220
		end
		buffer.writeu32(buf, (j * L + i) * 4, r + g * 256 + b * 65536 + 255 * 16777216)
	end
end
local image = Editables.image(buf, L, H)
part.TextureContent = Editables.figer(image)
image:Destroy()
part.Anchored = true
part.CFrame = cadre2 * CFrame.new(centre)
part.Name = "TestOrientation"
part.Parent = banc
local bille = Instance.new("Part")
bille.Shape = Enum.PartType.Ball
bille.Size = Vector3.new(0.15, 0.15, 0.15)
bille.Anchored = true
bille.Material = Enum.Material.Neon
bille.Color = Color3.new(0, 1, 0)
bille.CFrame = cadre2 * CFrame.new(Patron.point("jupe_droite_devant", "unique", 0.3, 0.3, recette.mesures) * e)
bille.Parent = banc

return ("robeMs=%.0f pieces=%d vitrineMs=%.0f"):format(robeMs, pieces, vitrineMs)
```

- [ ] **Step 2: Lancer le banc dans Studio**

1. Construire le lieu : `C:/dev/jeux/roblox-maker/rojo.exe build -o AtelierCouture.rbxl`, puis l'ouvrir dans Studio. Autre possibilité : une instance déjà synchronisée par `rojo serve`.
2. Lancer Play (`start_stop_play`), puis exécuter le contenu de `tests/studio/banc_rendu.luau` avec `execute_luau` (datamodel « Client »).

Expected: `robeMs=<nombre> pieces=8 vitrineMs=<nombre>`. Sur le PC de référence, le passage de préparation a donné robeMs ≈ 620 à 670 et vitrineMs ≈ 530.

- [ ] **Step 3: Vérifier à l'écran**

Placer une caméra scriptée face aux mannequins (x = 30 à 40, z = −34, face à +Z). Voici une façon de la tenir malgré la remise à zéro faite par le connecteur :

```lua
local cam = workspace.CurrentCamera
_G.vue = CFrame.lookAt(Vector3.new(34, 3.4, -26.5), Vector3.new(34, 2.3, -34))
_G.cam = _G.cam or game:GetService("RunService").RenderStepped:Connect(function()
	cam.CameraType = Enum.CameraType.Scriptable
	cam.CFrame = _G.vue
end)
```

Expected, à noter dans le rapport :
- **robe complète (x = 30)** : corsage en V et jupe fleuris, manches ballon en satin, col Claudine blanc, nœud, bouton, fleur et dentelle en place ; rien du mannequin ne traverse le tissu ;
- **essai d'orientation (x = 36)** : bande bleue en haut (à la taille), moitié rouge du même côté que la bille verte ;
- **robe de vitrine (x = 40)** : même robe, plus grossière.

- [ ] **Step 4: Compléter le rapport**

Ajouter à la fin de `docs/superpowers/spikes/2026-09-28-rendu-editable.md` la section suivante, avec les valeurs mesurées :

```markdown
## Banc du plan 2 (Studio, PC) — chaîne de rendu complète

Mesuré avec `tests/studio/banc_rendu.luau` (Studio en mode Play, côté client) :

| Mesure | Valeur |
|---|---|
| Robe complète, finesse « robe » (8 pièces + 4 accessoires, sans étalement) | … ms |
| Même robe, finesse « vitrine » | … ms |
| Pièces créées | 8 |

Vérifications visuelles :
- Robe complète : … (pièces jointives, imprimé à l'endroit, accessoires posés, mannequin invisible sous le tissu)
- Essai d'orientation : bande bleue en haut, rouge du côté de la bille verte → **image ni retournée ni en miroir** : oui / non
- Robe de vitrine : …

Écart avec la spec §9 (génération < 200 ms sur PC) : toujours non atteint, pour la raison du spike (appels asynchrones
de Roblox). La génération étalée (une pièce par image) évite le gel de l'image. **La décision reste au commanditaire.**
```

- [ ] **Step 5: Compléter le README**

Dans `README.md`, section « Refonte en cours », ajouter ces lignes au tableau, après la ligne `Pixels` :

```markdown
| `Recette` | Recette de robe en JSON (attributs, sauvegarde) et validation complète |
| `Maillage` | Triangulation d'une pièce enroulée autour du corps |
| `Mannequin` | Mannequin de couturière dimensionné selon les mesures |
| `Editables` | Seul accès aux API modifiables de Roblox (conversion en contenu statique) |
| `ConstructeurRobe` | Robe 3D à partir d'une recette : pièces texturées et accessoires |
| `Vitrines` | Robes exposées construites près du joueur, libérées quand il s'éloigne |
```

- [ ] **Step 6: Lancer toute la suite et commit**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT"`
Expected:
```
Unitaires : 103469 vérifications
TOUT EST VERT : 181072 vérifications
```

```bash
C:/dev/jeux/roblox-maker/rojo.exe build -o AtelierCouture.rbxl
git add tests/studio/banc_rendu.luau docs/superpowers/spikes/2026-09-28-rendu-editable.md README.md AtelierCouture.rbxl
git commit -m "Plan 2 terminé : robe 3D et vitrines vérifiées dans Studio

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```
