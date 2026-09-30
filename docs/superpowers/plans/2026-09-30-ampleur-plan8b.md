# Aiguille & Dentelle — Plan 8b : six variantes de patron

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Deuxième plan du sous-projet 4 : six variantes de patron (corsage cache-cœur, bustier, manches courtes et trois-quarts, col marin, jupe crayon), avec leurs pièces, leur rendu 3D et leurs styles ; un carnet qui montre cinq variantes par ligne ; un tirage des commandes qui écarte d'abord les tissus de la mauvaise teinte (500 croquis au lieu de 108).

**Architecture:**
- **Catalogue** : dix pièces de patron (contours en dm, coutures, enroulement existant) et six variantes ; le devant du cache-cœur se coud avec le dos droit.
- **Patron** : une forme de col de plus, « marin » (à plat sur les épaules comme le Claudine, il retombe de plus en plus vers le milieu du dos) ; la jupe crayon utilise un évasement négatif (resserrée sous les hanches).
- **Déblocages** : `Deblocages.PRESTIGE_VARIANTES` (manches courtes 6, jupe crayon 7 ; les quatre variantes promises à l'amitié des nouvelles clientes attendent le prestige 8 jusqu'au plan 8c).
- **Carnet** : boutons de variante plus étroits, le nom sur deux lignes au besoin.
- **Commandes** : `realisable` règle une fois pour toutes les accessoires et la teinte, puis ne compare plus que les styles, robe par robe.

**Tech Stack:** Luau, Rojo 7.7.0-rc.1, simulation Luau 0.650 (`tests/lancer.sh`), Roblox Studio via le connecteur MCP Studio.

**Spec:** `docs/superpowers/specs/2026-09-30-ampleur-contenu-design.md` (§4 variantes, §6 rapidité, §8 tests, §9 plan 8b). Amendée avec ce plan : §2 (le tulle reste opaque), §4 (les quatre variantes d'amitié au prestige 8 en attendant le plan 8c), §9 (le plan 8a a posé les huit accessoires de prestige ; les quatre d'amitié viennent au plan 8c).

## Décisions de ce plan

- **Pièces** : cache-cœur = devant à encolure croisée (plus basse d'un côté) et dos droit ; bustier = devant au haut en cœur et dos, hauts de 3 dm (4,2 pour les autres corsages : il s'arrête sous les épaules) ; manche courte (1,8 dm) et trois-quarts (4 dm), coupées pliées ; col marin coupé plié, étroit devant, large dans le dos ; jupe crayon, 5 dm en haut, 4,2 dm à l'ourlet. Le bustier mesure 3 dm plutôt que 3,2 : les tests existants parcourent les pièces en douzièmes de leur hauteur, et 3,2 × 12 / 12 déborde de la pièce d'un cheveu en virgule flottante.
- **Styles** : cache-cœur romantique 8, chic 4 ; bustier gothique 7, élégant 5 ; courtes décontracté 6, mignon 3 ; trois-quarts chic 6, élégant 4 ; marin mignon 5, décontracté 5 ; crayon chic 8, élégant 4, décontracté −2.
- **Conditions** : spec §4 pour les manches courtes (6) et la jupe crayon (7). Les quatre autres sont promises à l'amitié des clientes 7 à 10, qui arrivent au plan 8c : d'ici là, elles s'ouvrent au prestige 8 (jamais au départ) ; le plan 8c les rendra à l'amitié.
- **Carnet** : 78 px pour le nom de la famille, boutons de 87 px tous les 91 px (le cinquième finit à 531 px dans une colonne de 540 px), texte de 14 px sur deux lignes au besoin. Vérifié dans Studio : les 19 textes tiennent (`TextFits`).
- **Rapidité** : le catalogue passe de 108 à 500 croquis. `realisable` écarte d'abord les tissus fermés ou d'une autre teinte, et refuse d'emblée deux accessoires différents : même réponse et même témoin (test 54 : mille jeux d'exigences comparés au calcul complet). La suite passe de 16 s à environ 31 s (sous la minute de la spec §6) : l'équilibrage (20 parties) en prend 13, le métrage des 500 croquis et la référence du test 54 environ 5 chacun.
- **Équilibrage** : mesuré après ce plan, prestige 8 vers la 57e robe et « tout ouvert » vers la 63e (médianes ; de la 54e à la 78e), dans les bornes existantes.
- **Suites de la relecture du plan 8a** : les commandes aux prestiges 6, 7 et 8 sont maintenant testées avec ce qui est ouvert (46) ; README (onze matières) et commentaire de `Deblocages` corrigés.
- **Vérifié pendant la préparation** : le plan a été joué entièrement sur un brouillon tiré de `main` ; trois robes en variantes nouvelles ont été construites dans Studio (mode édition) et regardées : encolure croisée, bustier sans épaules, jupe resserrée, col qui retombe dans le dos ; neuf variantes du brouillon (col marin sans sa forme, jupe crayon évasée, jupe crayon sans style, manches courtes au prestige 5, col marin sans condition, boutons du carnet à l'ancienne largeur, noms sur une ligne, teinte ou accessoires vérifiés trop tard) échouent chacune sur la vérification qui les garde.

## Global Constraints

- **Dépôt** : `C:\dev\jeux\atelier-couture`, branche `ampleur-variantes`, créée depuis `main` (où le plan 8a est fusionné). Selon les règles du commanditaire : la branche testée et relue est fusionnée dans `main` et poussée sur GitHub.
- **Rojo** : `C:/dev/jeux/roblox-maker/rojo.exe`.
- **Contraintes des plans précédents toujours valables** : fins de ligne LF, commits en français terminés par `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`, textes d'au moins 14 px, le serveur fait foi.
- **Contenu original** : aucun nom ni motif de Dressmaker.

## Review Focus

- **Chaque croquis possible (500) se coupe dans un seul tissu.** Attendu : la disposition conseillée est acceptée, une robe tient dans 4 m. Test : `15_metrage`, « 500 croquis vérifiés ».
- **Pièces nouvelles portées en 3D, à toutes les tailles.** Attendu : positions finies, imprimé dans le bon sens, coutures de côté jointives, jupe hors des jambes, rien dans le corps. Tests : `03_patron` et `10_mannequin` (boucles sur toutes les pièces), « jupe crayon : resserrée à l'ourlet ».
- **Une variante nouvelle fermée touchée au carnet.** Attendu : ce qu'il faut pour l'ouvrir, le croquis ne change pas. Vérifié dans Studio (« Pas encore ouvert : Jupe crayon (Prestige 7). ») ; le scénario le teste déjà pour la jupe ample.
- **Commande avec une teinte ou deux accessoires.** Attendu : même réponse que le calcul complet. Test : `54_commandes_rapides`.
- **Une robe en variantes nouvelles jusqu'à la photo.** Attendu : choisie au carnet, montrée en 3D. Test : scénario, « robe en variantes nouvelles montrée en 3D à la photo ».

---

### Task 1: Six variantes au catalogue

**Files:**
- Modify: `src/shared/Catalogue.luau` (pièces, variantes), `src/shared/Patron.luau` (col marin), `src/shared/Deblocages.luau` (`PRESTIGE_VARIANTES`)
- Modify: `tests/unitaires/02_catalogue.luau`, `03_patron.luau`, `15_metrage.luau`, `45_deblocages.luau`

**Interfaces:**
- Consumes: `Catalogue.Pieces`, `Catalogue.Variantes`, `Patron.point`, `Deblocages.CONDITIONS`.
- Produces: variantes `corsage_cache_coeur`, `corsage_bustier`, `manches_courtes`, `manches_trois_quarts`, `col_marin`, `jupe_crayon` ; pièces `corsage_cache_coeur_devant`, `corsage_bustier_devant`, `corsage_bustier_dos`, `manche_courte`, `manche_trois_quarts`, `col_marin`, `jupe_crayon_devant`, `jupe_crayon_dos` ; forme de col `"marin"` ; `Deblocages.PRESTIGE_VARIANTES`.

- [ ] **Step 1: Écrire les tests**

Dans `tests/unitaires/02_catalogue.luau`, remplacer :

```lua
	U.verifier(e.type == "corsage" or e.type == "jupe" or e.type == "manche" or e.type == "col", id .. " : enroulement connu")
```

par :

```lua
	U.verifier(e.type == "corsage" or e.type == "jupe" or e.type == "manche" or e.type == "col", id .. " : enroulement connu")
	U.verifier(e.type ~= "col" or e.forme == "claudine" or e.forme == "montant" or e.forme == "marin", id .. " : forme de col connue")
```

Dans `tests/unitaires/02_catalogue.luau`, remplacer :

```lua
U.verifier(minimum == 4 and maximum == 6, ("4 à 6 pièces par robe (obtenu %d à %d)"):format(minimum, maximum))
```

par :

```lua
U.verifier(minimum == 4 and maximum == 6, ("4 à 6 pièces par robe (obtenu %d à %d)"):format(minimum, maximum))
-- Sous-projet 4 : dix-neuf variantes (cinq corsages, cinq manches, quatre cols, cinq jupes : 500 croquis)
local parFamille = {}
for _, v in ipairs(Catalogue.Variantes) do
	parFamille[v.famille] = (parFamille[v.famille] or 0) + 1
end
U.verifier(#Catalogue.Variantes == 19 and parFamille.corsage == 5 and parFamille.manches == 5 and parFamille.col == 4 and parFamille.jupe == 5, "19 variantes : cinq corsages, cinq manches, quatre cols, cinq jupes")
for _, id in ipairs({ "corsage_cache_coeur", "corsage_bustier", "manches_courtes", "manches_trois_quarts", "col_marin", "jupe_crayon" }) do
	local v = Catalogue.variante(id)
	local points = 0
	for _, p in pairs(v and v.style or {}) do
		points += p
	end
	U.verifier(v ~= nil and points >= 8, id .. " : variante nouvelle, avec du style")
end
```

Dans `tests/unitaires/03_patron.luau`, remplacer :

```lua
-- Les manches partent de l'épaule, au bord du corsage
```

par :

```lua
-- Sous-projet 4 : le col marin retombe plus bas dans le dos que devant ; la jupe crayon se resserre vers
-- l'ourlet ; le bustier s'arrête sous les épaules
local bMarin = Polygone.boite(Catalogue.piece("col_marin").contour)
local m0, m1 = Polygone.etendueLigne(Catalogue.piece("col_marin").contour, bMarin.maxY)
local marinDevant = Patron.point("col_marin", "droite", m0, bMarin.maxY, M)
local marinDos = Patron.point("col_marin", "droite", m1, bMarin.maxY, M)
U.verifier(marinDos.Y < marinDevant.Y - 0.5, "col marin : le bord retombe plus bas dans le dos que devant")
local function horizontale(p)
	return math.sqrt(p.X * p.X + p.Z * p.Z)
end
local crayonHanches = Patron.point("jupe_crayon_devant", "unique", 2.5, 1.8, M)
local crayonOurlet = Patron.point("jupe_crayon_devant", "unique", 2.5, 6, M)
local droiteOurlet = Patron.point("jupe_droite_devant", "unique", 2.5, 6, M)
U.verifier(horizontale(crayonOurlet) < horizontale(crayonHanches) - 0.1 and horizontale(crayonOurlet) < horizontale(droiteOurlet), "jupe crayon : resserrée à l'ourlet, plus que la jupe droite")
local hautBustier = Patron.point("corsage_bustier_devant", "unique", 1.2, 0, M)
U.verifier(hautBustier.Y < 3.5 and Patron.point("corsage_droit_devant", "unique", 1.2, 0, M).Y > 4, "bustier : il s'arrête sous les épaules")

-- Les manches partent de l'épaule, au bord du corsage
```

Dans `tests/unitaires/15_metrage.luau`, remplacer :

```lua
U.verifier(n == 108, "108 croquis vérifiés")
```

par :

```lua
U.verifier(n == 500, "500 croquis vérifiés")
```

Dans `tests/unitaires/45_deblocages.luau`, remplacer :

```lua
U.verifier(not Deblocages.toutOuvert(depart), "au départ : pas tout")
```

par :

```lua
U.verifier(not Deblocages.toutOuvert(depart), "au départ : pas tout")
-- Sous-projet 4 : les manches courtes au prestige 6, la jupe crayon au 7 ; les quatre variantes des nouvelles
-- clientes attendent le prestige 8 (le plan 8c les donnera à leur amitié)
for id, niveau in pairs({ manches_courtes = 6, jupe_crayon = 7, corsage_cache_coeur = 8, corsage_bustier = 8, manches_trois_quarts = 8, col_marin = 8 }) do
	U.verifier(Catalogue.variante(id) ~= nil and not Deblocages.ouvert(au(SEUILS_P[niveau] - 1), "variantes", id) and Deblocages.ouvert(au(SEUILS_P[niveau]), "variantes", id), id .. " : ouverte au prestige " .. niveau)
end
```

Dans `tests/unitaires/45_deblocages.luau`, remplacer :

```lua
U.verifier(resume6 == "les crêpes (4), les organzas (4), Papillon de soie, Galon argenté", "prestige 6 en une ligne : les crêpes et les organzas ensemble (" .. resume6 .. ")")
```

par :

```lua
U.verifier(resume6 == "Manches courtes, les crêpes (4), les organzas (4), Papillon de soie, Galon argenté", "prestige 6 en une ligne : les manches courtes, les crêpes et les organzas ensemble (" .. resume6 .. ")")
```

- [ ] **Step 2: Lancer les tests, vérifier l'échec**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT|attempt|membre" | head -3`
Expected: échec : une ligne qui finit par `ÉCHEC : 19 variantes : cinq corsages, cinq manches, quatre cols, cinq jupes`

- [ ] **Step 3: Écrire le code**

Dans `src/shared/Catalogue.luau`, remplacer :

```lua
local COL_CLAUDINE = { { x = 0, y = 0 }, { x = 2, y = 0 }, { x = 2.4, y = 0.4 }, { x = 2.2, y = 1.2 }, { x = 1, y = 1.4 }, { x = 0, y = 1.2 } }
```

par :

```lua
local COL_CLAUDINE = { { x = 0, y = 0 }, { x = 2, y = 0 }, { x = 2.4, y = 0.4 }, { x = 2.2, y = 1.2 }, { x = 1, y = 1.4 }, { x = 0, y = 1.2 } }
-- Sous-projet 4 : cache-cœur (encolure croisée, plus basse d'un côté), bustier (sans épaules, haut en cœur),
-- manches courte et trois-quarts, col marin (étroit devant, large dans le dos), jupe crayon (resserrée)
local CORSAGE_CACHE_COEUR = {
	{ x = 0, y = 0 }, { x = 1, y = 0 }, { x = 3, y = 2.6 }, { x = 3.8, y = 0 },
	{ x = 4.8, y = 0 }, { x = 4.8, y = 4.2 }, { x = 0, y = 4.2 },
}
local BUSTIER_DEVANT = {
	{ x = 0, y = 0.4 }, { x = 1.2, y = 0 }, { x = 2.4, y = 0.5 }, { x = 3.6, y = 0 },
	{ x = 4.8, y = 0.4 }, { x = 4.8, y = 3 }, { x = 0, y = 3 },
}
local MANCHE_COURTE = { { x = 0, y = 0.6 }, { x = 1.6, y = 0 }, { x = 3.2, y = 0.6 }, { x = 3, y = 1.8 }, { x = 0.2, y = 1.8 } }
local MANCHE_TROIS_QUARTS = { { x = 0, y = 0.6 }, { x = 1.6, y = 0 }, { x = 3.2, y = 0.6 }, { x = 2.9, y = 4 }, { x = 0.3, y = 4 } }
local COL_MARIN = { { x = 0, y = 0 }, { x = 2.2, y = 0 }, { x = 2.4, y = 1.6 }, { x = 0.8, y = 1.6 } }
local CRAYON = { { x = 0, y = 0 }, { x = 5, y = 0 }, { x = 4.6, y = 6 }, { x = 0.4, y = 6 } }
```

Dans `src/shared/Catalogue.luau`, remplacer :

```lua
	corsage_bretelles_dos = { nom = "Corsage dos (bretelles)", contour = CORSAGE_BRETELLES, coutures = { 7, 8, 9 },
		enroulement = { type = "corsage", cote = "dos" } },
```

par :

```lua
	corsage_bretelles_dos = { nom = "Corsage dos (bretelles)", contour = CORSAGE_BRETELLES, coutures = { 7, 8, 9 },
		enroulement = { type = "corsage", cote = "dos" } },
	corsage_cache_coeur_devant = { nom = "Corsage devant (cache-cœur)", contour = CORSAGE_CACHE_COEUR, coutures = { 5, 6, 7 },
		enroulement = { type = "corsage", cote = "devant" } },
	corsage_bustier_devant = { nom = "Bustier devant", contour = BUSTIER_DEVANT, coutures = { 5, 6, 7 },
		enroulement = { type = "corsage", cote = "devant" } },
	corsage_bustier_dos = { nom = "Bustier dos", contour = rectangle(4.8, 3), coutures = { 2, 3, 4 },
		enroulement = { type = "corsage", cote = "dos" } },
```

Dans `src/shared/Catalogue.luau`, remplacer :

```lua
	manche_longue = { nom = "Manche longue", contour = MANCHE_LONGUE, coutures = { 1, 2, 3, 5 }, pliee = true,
		enroulement = { type = "manche", bouffant = 0 } },
```

par :

```lua
	manche_longue = { nom = "Manche longue", contour = MANCHE_LONGUE, coutures = { 1, 2, 3, 5 }, pliee = true,
		enroulement = { type = "manche", bouffant = 0 } },
	manche_courte = { nom = "Manche courte", contour = MANCHE_COURTE, coutures = { 1, 2, 3, 5 }, pliee = true,
		enroulement = { type = "manche", bouffant = 0 } },
	manche_trois_quarts = { nom = "Manche trois-quarts", contour = MANCHE_TROIS_QUARTS, coutures = { 1, 2, 3, 5 }, pliee = true,
		enroulement = { type = "manche", bouffant = 0 } },
```

Dans `src/shared/Catalogue.luau`, remplacer :

```lua
	col_montant = { nom = "Col montant", contour = rectangle(2, 0.6), coutures = { 3 }, pliee = true,
		enroulement = { type = "col", forme = "montant" } },
```

par :

```lua
	col_montant = { nom = "Col montant", contour = rectangle(2, 0.6), coutures = { 3 }, pliee = true,
		enroulement = { type = "col", forme = "montant" } },
	-- Col marin : le bord haut (arête 1) est cousu à l'encolure ; le reste retombe, plus bas dans le dos
	col_marin = { nom = "Col marin", contour = COL_MARIN, coutures = { 1 }, pliee = true,
		enroulement = { type = "col", forme = "marin" } },
```

Dans `src/shared/Catalogue.luau`, remplacer :

```lua
	jupe_evasee_dos = { nom = "Jupe évasée dos", contour = EVASEE, coutures = { 1, 2, 4 }, biais = true,
		enroulement = { type = "jupe", cote = "dos", evasement = 0.45, fronces = 0 } },
```

par :

```lua
	jupe_evasee_dos = { nom = "Jupe évasée dos", contour = EVASEE, coutures = { 1, 2, 4 }, biais = true,
		enroulement = { type = "jupe", cote = "dos", evasement = 0.45, fronces = 0 } },
	-- Jupe crayon : un évasement négatif la resserre sous les hanches (elle reste hors des jambes)
	jupe_crayon_devant = { nom = "Jupe crayon devant", contour = CRAYON, coutures = { 1, 2, 4 },
		enroulement = { type = "jupe", cote = "devant", evasement = -0.04, fronces = 0 } },
	jupe_crayon_dos = { nom = "Jupe crayon dos", contour = CRAYON, coutures = { 1, 2, 4 },
		enroulement = { type = "jupe", cote = "dos", evasement = -0.04, fronces = 0 } },
```

Dans `src/shared/Catalogue.luau`, remplacer :

```lua
	{ id = "corsage_bretelles", famille = "corsage", nom = "À bretelles",
		pieces = { "corsage_bretelles_devant", "corsage_bretelles_dos" }, style = { decontracte = 8, mignon = 4 } },
```

par :

```lua
	{ id = "corsage_bretelles", famille = "corsage", nom = "À bretelles",
		pieces = { "corsage_bretelles_devant", "corsage_bretelles_dos" }, style = { decontracte = 8, mignon = 4 } },
	{ id = "corsage_cache_coeur", famille = "corsage", nom = "Cache-cœur",
		pieces = { "corsage_cache_coeur_devant", "corsage_droit_dos" }, style = { romantique = 8, chic = 4 } },
	{ id = "corsage_bustier", famille = "corsage", nom = "Bustier",
		pieces = { "corsage_bustier_devant", "corsage_bustier_dos" }, style = { gothique = 7, elegant = 5 } },
```

Dans `src/shared/Catalogue.luau`, remplacer :

```lua
	{ id = "manches_longues", famille = "manches", nom = "Longues", pieces = { "manche_longue" },
		style = { elegant = 5, gothique = 5, chic = 3 } },
```

par :

```lua
	{ id = "manches_longues", famille = "manches", nom = "Longues", pieces = { "manche_longue" },
		style = { elegant = 5, gothique = 5, chic = 3 } },
	{ id = "manches_courtes", famille = "manches", nom = "Courtes", pieces = { "manche_courte" },
		style = { decontracte = 6, mignon = 3 } },
	{ id = "manches_trois_quarts", famille = "manches", nom = "Trois-quarts", pieces = { "manche_trois_quarts" },
		style = { chic = 6, elegant = 4 } },
```

Dans `src/shared/Catalogue.luau`, remplacer :

```lua
	{ id = "col_montant", famille = "col", nom = "Montant", pieces = { "col_montant" }, style = { gothique = 6, elegant = 4 } },
```

par :

```lua
	{ id = "col_montant", famille = "col", nom = "Montant", pieces = { "col_montant" }, style = { gothique = 6, elegant = 4 } },
	{ id = "col_marin", famille = "col", nom = "Marin", pieces = { "col_marin" }, style = { mignon = 5, decontracte = 5 } },
```

Dans `src/shared/Catalogue.luau`, remplacer :

```lua
		pieces = { "jupe_evasee_devant", "jupe_evasee_dos" }, style = { elegant = 10, gothique = 4, decontracte = -4 } },
```

par :

```lua
		pieces = { "jupe_evasee_devant", "jupe_evasee_dos" }, style = { elegant = 10, gothique = 4, decontracte = -4 } },
	{ id = "jupe_crayon", famille = "jupe", nom = "Crayon",
		pieces = { "jupe_crayon_devant", "jupe_crayon_dos" }, style = { chic = 8, elegant = 4, decontracte = -2 } },
```

Dans `src/shared/Patron.luau`, remplacer :

```lua
	if e.forme == "claudine" then
		rayon, y = RAYON_COU + v * hauteur * 0.9, HAUTEUR_COU - v * hauteur * 0.35
```

par :

```lua
	if e.forme == "claudine" then
		rayon, y = RAYON_COU + v * hauteur * 0.9, HAUTEUR_COU - v * hauteur * 0.35
	elseif e.forme == "marin" then
		-- À plat sur les épaules comme le Claudine, mais il retombe de plus en plus vers le milieu du dos
		rayon, y = RAYON_COU + v * hauteur * 0.8, HAUTEUR_COU - v * hauteur * (0.3 + 0.6 * u)
```

Dans `src/shared/Deblocages.luau`, remplacer :

```lua
Deblocages.GENRES = { "variantes", "tissus", "accessoires" }
```

par :

```lua
-- Prestige qui ouvre des variantes (sous-projet 4) ; cache-cœur, bustier, trois-quarts et col marin attendent le
-- prestige 8 jusqu'à l'arrivée des nouvelles clientes (plan 8c), dont l'amitié les ouvrira
Deblocages.PRESTIGE_VARIANTES = {
	manches_courtes = 6,
	jupe_crayon = 7,
	corsage_cache_coeur = 8,
	corsage_bustier = 8,
	manches_trois_quarts = 8,
	col_marin = 8,
}
Deblocages.GENRES = { "variantes", "tissus", "accessoires" }
```

Dans `src/shared/Deblocages.luau`, remplacer :

```lua
for id, niveau in pairs(Deblocages.PRESTIGE_ACCESSOIRES) do
	CONDITIONS.accessoires[id] = { prestige = niveau }
end
```

par :

```lua
for id, niveau in pairs(Deblocages.PRESTIGE_ACCESSOIRES) do
	CONDITIONS.accessoires[id] = { prestige = niveau }
end
for id, niveau in pairs(Deblocages.PRESTIGE_VARIANTES) do
	CONDITIONS.variantes[id] = { prestige = niveau }
end
```

Dans `src/shared/Deblocages.luau`, remplacer :

```lua
-- Prestige qui ouvre chaque matière (cotons et lins sont ouverts au départ) et deux garnitures
```

par :

```lua
-- Prestige qui ouvre chaque matière (cotons, lins et jute sont ouverts au départ) et des décorations
```

- [ ] **Step 4: Lancer les tests**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT"`
Expected:
```
Unitaires : 157769 vérifications
TOUT EST VERT : 711 vérifications
```

- [ ] **Step 5: Commit**

```bash
git add src/shared/Catalogue.luau src/shared/Patron.luau src/shared/Deblocages.luau tests/unitaires/02_catalogue.luau tests/unitaires/03_patron.luau tests/unitaires/15_metrage.luau tests/unitaires/45_deblocages.luau
git commit -m "Six variantes : cache-cœur, bustier, manches courtes et trois-quarts, col marin, jupe crayon

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 2: Le carnet à cinq variantes par ligne, une robe nouvelle jusqu'à la photo

**Files:**
- Modify: `src/client/Atelier/EcranCarnet.luau`
- Modify: `tests/scenario.luau`

**Interfaces:**
- Consumes: les variantes de la tâche 1 ; `robeLibreALaPhoto` (scénario).
- Produces: boutons `Variante_<id>` de 87 px, `TextWrapped` ; `robeLibreALaPhoto(tissu, croquis?)` dans le scénario.

- [ ] **Step 1: Écrire les tests**

Dans `tests/scenario.luau`, remplacer :

```lua
verifier(boutonNomme("Variante_jupe_ample"):GetAttribute("Ferme") == false, "prestige et amitiés au plus haut : la jupe ample s'ouvre dans le carnet")
```

par :

```lua
verifier(boutonNomme("Variante_jupe_ample"):GetAttribute("Ferme") == false, "prestige et amitiés au plus haut : la jupe ample s'ouvre dans le carnet")
-- Sous-projet 4 : cinq variantes par ligne, dans la colonne de gauche, le nom sur deux lignes au besoin
local gaucheCarnet, debordent = fenetre.Contenu.Gauche, {}
for _, id in ipairs({ "corsage_bustier", "manches_trois_quarts", "col_marin", "jupe_crayon" }) do
	local b = boutonNomme("Variante_" .. id)
	if b:GetAttribute("Ferme") ~= false or b.Position.X.Offset + b.Size.X.Offset > gaucheCarnet.Size.X.Offset or not b.TextWrapped then
		table.insert(debordent, id)
	end
end
verifier(#debordent == 0, "cinq variantes par ligne, ouvertes, dans la colonne de gauche, le nom sur deux lignes au besoin (en défaut : " .. table.concat(debordent, ", ") .. ")")
```

Dans `tests/scenario.luau`, remplacer :

```lua
local function robeLibreALaPhoto(tissu)
	local e = serveur:atelier(joueur).etat
	e.croquis = { corsage = "corsage_droit", manches = "manches_sans", col = "col_sans", jupe = "jupe_droite" }
```

par :

```lua
local function robeLibreALaPhoto(tissu, croquis)
	local e = serveur:atelier(joueur).etat
	e.croquis = croquis or { corsage = "corsage_droit", manches = "manches_sans", col = "col_sans", jupe = "jupe_droite" }
```

Dans `tests/scenario.luau`, remplacer :

```lua
verifier(texte("Robe libre (taille S) : à ton idée.") ~= nil, "une autre robe libre, taille S")
robeLibreALaPhoto("toile_jute")
```

par :

```lua
verifier(texte("Robe libre (taille S) : à ton idée.") ~= nil, "une autre robe libre, taille S")
-- Celle-ci en variantes nouvelles (sous-projet 4) : choisies au carnet, cousues, montrées en 3D jusqu'à la photo
local croquisNouveau = { corsage = "corsage_cache_coeur", manches = "manches_trois_quarts", col = "col_marin", jupe = "jupe_crayon" }
for _, v in pairs(croquisNouveau) do
	cliquer("Variante_" .. v)
	verifier(boutonNomme("Variante_" .. v).BackgroundColor3 == Color3.fromRGB(214, 76, 128), v .. " choisie au carnet")
end
robeLibreALaPhoto("toile_jute", croquisNouveau)
local robeNouvelle, manquantes = scene:FindFirstChild("Robe"), {}
for _, nom in ipairs({ "Piece_corsage_cache_coeur_devant_unique", "Piece_manche_trois_quarts_gauche", "Piece_col_marin_droite", "Piece_jupe_crayon_dos_unique" }) do
	if not (robeNouvelle and robeNouvelle:FindFirstChild(nom, true)) then
		table.insert(manquantes, nom)
	end
end
verifier(#manquantes == 0, "robe en variantes nouvelles montrée en 3D à la photo (manquent : " .. table.concat(manquantes, ", ") .. ")")
```

- [ ] **Step 2: Lancer les tests, vérifier l'échec**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT|attempt|membre" | head -3`
Expected: échec : une ligne qui finit par `ÉCHEC : cinq variantes par ligne, ouvertes, dans la colonne de gauche, le nom sur deux lignes au besoin (en défaut : corsage_bustier, manches_trois_quarts, col_marin, jupe_crayon)`

- [ ] **Step 3: Écrire le code**

Dans `src/client/Atelier/EcranCarnet.luau`, remplacer :

```lua
	-- Colonne de gauche : variantes, puis pièces et tissus
```

par :

```lua
	-- Colonne de gauche : variantes (jusqu'à cinq par ligne, le nom sur deux lignes au besoin), puis pièces et tissus
```

Dans `src/client/Atelier/EcranCarnet.luau`, remplacer :

```lua
Position = UDim2.fromOffset(0, y + 8), Size = UDim2.fromOffset(90, 24), Parent = gauche })
```

par :

```lua
Position = UDim2.fromOffset(0, y + 8), Size = UDim2.fromOffset(78, 24), Parent = gauche })
```

Dans `src/client/Atelier/EcranCarnet.luau`, remplacer :

```lua
				TextSize = 14,
				Position = UDim2.fromOffset(90 + (k - 1) * 112, y),
				Size = UDim2.fromOffset(106, 38),
```

par :

```lua
				TextSize = 14,
				TextWrapped = true,
				Position = UDim2.fromOffset(80 + (k - 1) * 91, y),
				Size = UDim2.fromOffset(87, 38),
```

- [ ] **Step 4: Lancer les tests**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT"`
Expected:
```
Unitaires : 157769 vérifications
TOUT EST VERT : 729 vérifications
```

- [ ] **Step 5: Commit**

```bash
git add src/client/Atelier/EcranCarnet.luau tests/scenario.luau
git commit -m "Carnet à cinq variantes par ligne ; une robe en variantes nouvelles jusqu'à la photo

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 3: Le tirage écarte d'abord la mauvaise teinte, Studio, README

Le test de l'étape 1 est une caractérisation (les commandes aux prestiges 6 à 8 sont déjà réalisables : la relecture du plan 8a l'a vérifié à part) ; il passe dès qu'il est écrit. L'étape 3 est une réécriture sans changement de comportement, gardée par le test 54 (mille jeux d'exigences comparés au calcul complet, témoin compris).

**Files:**
- Modify: `tests/unitaires/46_deblocages_etat.luau`
- Modify: `src/shared/Commandes.luau` (`realisable`)
- Modify: `README.md`, `AtelierCouture.rbxl` (régénéré)

**Interfaces:**
- Consumes: tout ce qui précède.
- Produces: `Commandes.realisable(exigences, ouverts?)` inchangée pour ses appelants.

- [ ] **Step 1: Les commandes aux prestiges 6, 7 et 8**

Dans `tests/unitaires/46_deblocages_etat.luau`, remplacer :

```lua
		U.verifier(Commandes.realisable(commande.exigences, ouverts), c.id .. " : commande " .. n .. " réalisable dès son arrivée")
	end
end
```

par :

```lua
		U.verifier(Commandes.realisable(commande.exigences, ouverts), c.id .. " : commande " .. n .. " réalisable dès son arrivée")
	end
end
-- Plus tard aussi (prestiges 6, 7 et 8, amitié nulle ou au plus haut) : réalisables avec ce qui est ouvert
for _, prestige in ipairs({ 260, 380, 530 }) do
	for _, amitie in ipairs({ 0, 25 }) do
		for _, c in ipairs(Clientes.LISTE) do
			local progres = { prestige = prestige, clientes = { [c.id] = { amitie = amitie } } }
			local ouverts = Deblocages.ouverts(progres)
			local rng = Random.new(prestige + amitie)
			local ratees = 0
			for _ = 1, 10 do
				if not Commandes.realisable(Commandes.generer(rng, c, progres).exigences, ouverts) then
					ratees += 1
				end
			end
			U.verifier(ratees == 0, ("%s au prestige %d, amitié %d : commandes réalisables avec ce qui est ouvert"):format(c.id, prestige, amitie))
		end
	end
end
```

- [ ] **Step 2: Lancer les tests**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT"`
Expected:
```
Unitaires : 157805 vérifications
TOUT EST VERT : 729 vérifications
```

- [ ] **Step 3: La teinte et les accessoires d'abord**

Dans `src/shared/Commandes.luau`, remplacer :

```lua
	-- Styles, teinte et accessoires à vérifier (la qualité, au plus 0,9, est tenue d'office ; seul le dernier
	-- accessoire demandé est posé sur la robe témoin)
	local aVerifier = {}
	for _, e in ipairs(exigences) do
		if e.type ~= "qualite" then
			table.insert(aVerifier, e)
		end
	end
	local pa = pointsImpose(accessoireImpose)
```

par :

```lua
	-- Les exigences les plus fermées d'abord, une fois pour toutes : les accessoires (seul le dernier demandé est
	-- posé sur la robe témoin) et la teinte (seuls les tissus ouverts de cette teinte restent candidats) ;
	-- restent les styles, à vérifier robe par robe (la qualité, au plus 0,9, est tenue d'office)
	local aVerifier = {}
	for _, e in ipairs(exigences) do
		if e.type == "accessoire" and e.id ~= accessoireImpose then
			return false
		elseif e.type == "min" or e.type == "max" then
			table.insert(aVerifier, e)
		end
	end
	local tissus = {}
	for _, t in ipairs(Catalogue.Tissus) do
		local permis = not ouverts or ouverts.tissus[t.id]
		for _, e in ipairs(exigences) do
			if e.type == "teinte" and e.teinte ~= t.teinte then
				permis = false
			end
		end
		if permis then
			table.insert(tissus, t)
		end
	end
	if #tissus == 0 then
		return false
	end
	local pa = pointsImpose(accessoireImpose)
```

Dans `src/shared/Commandes.luau`, remplacer :

```lua
			for _, t in ipairs(Catalogue.Tissus) do
				if not ouverts or ouverts.tissus[t.id] then
					local pt = POINTS_TISSU[t.id]
					local ok = true
					for _, e in ipairs(aVerifier) do
						if e.type == "teinte" then
							ok = t.teinte == e.teinte
						elseif e.type == "accessoire" then
							ok = e.id == accessoireImpose
						else
							local v = math.clamp(pc[e.style] + pt[e.style] + pa[e.style], 0, 100)
							ok = if e.type == "min" then v >= e.valeur - 1e-9 else v <= e.valeur + 1e-9
						end
						if not ok then
							break
						end
					end
					if ok then
						return true, { croquis = croquis, tissu = t.id, accessoire = accessoireImpose }
					end
				end
			end
```

par :

```lua
			for _, t in ipairs(tissus) do
				local pt = POINTS_TISSU[t.id]
				local ok = true
				for _, e in ipairs(aVerifier) do
					local v = math.clamp(pc[e.style] + pt[e.style] + pa[e.style], 0, 100)
					ok = if e.type == "min" then v >= e.valeur - 1e-9 else v <= e.valeur + 1e-9
					if not ok then
						break
					end
				end
				if ok then
					return true, { croquis = croquis, tissu = t.id, accessoire = accessoireImpose }
				end
			end
```

- [ ] **Step 4: Lancer les tests**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Équilibrage|Unitaires|ÉCHEC|TOUT"`
Expected:
```
Équilibrage : 20 parties de 90 robes, une robe libre de jute vendue sur quatre, 40 commandes par lettre (médiane) : prestige 2 à la robe 3 au plus tard ; 5 de la 17 à la 23 (médiane 19) ; 8 à la 57 (médiane) ; tout ouvert de la 54 à la 78 (médiane 63) ; au plus bas 241 po
Unitaires : 157805 vérifications
TOUT EST VERT : 729 vérifications
```

- [ ] **Step 5: Dans Studio, par le connecteur MCP**

Construire le lieu du dépôt dans un dossier temporaire (`C:/dev/jeux/roblox-maker/rojo.exe build -o <dossier temporaire>/Plan8bDepot.rbxl`) et l'ouvrir dans Studio.

En mode édition, par `execute_luau` : dans un dossier de `workspace`, construire trois mannequins (`Mannequin.construire`, taille M) et trois robes (`ConstructeurRobe.construire`, pièces en x = 0, y = 0, angle 0, couture 0,9) : cache-cœur, trois-quarts, marin et crayon en crêpe bleu nuit ; bustier, sans manches, sans col et crayon en brocart bordeaux ; droit, courtes, marin et trapèze en coton blanc. Relever les noms des pièces construites, les regarder par `screen_capture` de face et de dos, puis détruire le dossier.

En Play : attendre 4 s, appuyer sur E, régler les rubans aux vraies mesures de Colette et valider ; au carnet, relever pour chaque bouton `Variante_*` sa place, `TextFits` et l'attribut `Ferme` ; toucher « Crayon » et lire le message.

Expected : les pièces de chaque croquis construites (8, 4 et 8 pièces), l'encolure croisée, le bustier sans épaules, la jupe resserrée, le col qui retombe dans le dos ; 19 boutons, cinq par ligne au plus, tous dans la colonne de gauche, `TextFits` vrai ; « Pas encore ouvert : Jupe crayon (Prestige 7). » ; aucune alerte de notre code (« Lieu non publié » et les messages internes de Roblox mis à part). Arrêter Play et fermer cette fenêtre de Studio (sans enregistrer).

- [ ] **Step 6: Mettre à jour le README**

Dans `README.md`, remplacer :

```markdown
2. **Carnet de croquis** : corsage, manches, col et jupe au choix ; un tissu par pièce (41 tissus en dix matières,
   filtre par style, dont la toile de jute, gratuite).
```

par :

```markdown
2. **Carnet de croquis** : corsage, manches, col et jupe au choix (19 variantes : cinq corsages dont le
   cache-cœur et le bustier, cinq manches, quatre cols dont le col marin, cinq jupes dont la jupe crayon) ; un
   tissu par pièce (41 tissus en onze matières, filtre par style, dont la toile de jute, gratuite).
```

Dans `README.md`, remplacer :

```markdown
   ruban noir (2), la dentelle noire (3) et deux décorations par niveau du 5 au 8 ; l'amitié de
```

par :

```markdown
   ruban noir (2), la dentelle noire (3) et deux décorations par niveau du 5 au 8 ; les manches courtes (6), la
   jupe crayon (7), et en attendant les nouvelles clientes, le cache-cœur, le bustier, les manches trois-quarts et
   le col marin (8) ; l'amitié de
```

Dans `README.md`, remplacer :

```markdown
jamais les styles robe par robe (les points de chaque croquis et de chaque tissu sont précalculés).
```

par :

```markdown
jamais les styles robe par robe (les points de chaque croquis et de chaque tissu sont précalculés ; les tissus
   d'une autre teinte que celle demandée sont écartés d'abord).
```

- [ ] **Step 7: Tests, lieu régénéré, commit**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT"`
Expected:
```
Unitaires : 157805 vérifications
TOUT EST VERT : 729 vérifications
```

```bash
C:/dev/jeux/roblox-maker/rojo.exe build -o AtelierCouture.rbxl
git add tests/unitaires/46_deblocages_etat.luau src/shared/Commandes.luau README.md AtelierCouture.rbxl
git commit -m "Plan 8b terminé : six variantes de patron, carnet à cinq par ligne, tirage qui écarte d'abord la mauvaise teinte

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```
