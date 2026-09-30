# Aiguille & Dentelle — Plan 11 : le carnet de croquis dessiné

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rapprocher le carnet de croquis de celui de *Dressmaker* : une page de carnet où la robe choisie est dessinée au trait, de face, et se colorie des tissus choisis ; les modèles se choisissent par ◀ ▶, famille par famille ; les échantillons des tissus sont épinglés à la page ; toucher le dessin choisit le tissu de la partie touchée.

**Architecture:** un module partagé `Croquis` décrit la forme de face de chaque variante (polygones dans un repère de 100 × 130 unités, plis, mannequin esquissé) ; `Pixels.croquis` peint l'image (remplissage ligne par ligne, motif du tissu, trait de crayon au bord) ; `Vignettes.croquis` la fige en image statique et ne garde que les six dernières ; `EcranCarnet` est réécrit autour d'une page (dessin, lignes ◀ ▶, pièces, échantillons, « Tracer le patron ») et garde la fiche de commande à droite. Aucune règle ne change : le serveur reçoit le même croquis qu'avant.

**Tech Stack:** Luau, Rojo 7.7.0-rc.1, simulation Luau 0.650 (`tests/lancer.sh`), Roblox Studio via le connecteur MCP Studio.

**Spec:** `docs/superpowers/specs/2026-09-30-fidelite-dressmaker-design.md` (sections 2 et 5 ; plan 11 de la section 6).

## Décisions de ce plan

- **Formes** : chaque variante a sa forme dans `Croquis` (le test 56 le vérifie pour les 19) ; les manches et les cols Claudine et marin sont dessinés d'un côté et reportés en miroir. Ordre de dessin : jupe, corsage, manches, col ; toucher le dessin désigne la partie la plus haute.
- **Couleur du dessin** : chaque famille prend le tissu de sa première pièce (le devant) ; sans tissu, elle reste blanche. Un pixel du dessin couvre deux pixels du motif : on voit les pois, les fleurs, les carreaux.
- **Mémoire des images** : le client garde les six derniers dessins (`Vignettes.CROQUIS_GARDES`) ; si la mémoire des images est pleine, le dessin s'efface et un mot le remplace ; les modèles et les tissus se choisissent quand même.
- **Modèles fermés** : on peut les voir (◀ ▶ passent par tous, le dessin les montre), grisés, avec ce qu'il faut pour les ouvrir ; « Tracer le patron » les refuse avec le même message qu'avant.
- **Échantillons** : un carré par tissu choisi (quatre au plus), avec un liseré et une épingle ; pas de bords crantés (une forme dentelée demanderait une image par tissu, pour peu de chose).
- **Vérifié pendant la préparation** : le plan a été joué entièrement sur un brouillon tiré de `main` ; douze variantes du brouillon (manches sans miroir, toucher la partie du dessous, dessin sans trait, mannequin tracé sur la robe, dessins tous gardés, patron d'un modèle fermé tracé, ◀ ▶ qui s'arrêtent au bout, toucher décalé, échantillons en double, point du modèle jamais marqué, métrage figé, ancien dessin laissé quand la mémoire est pleine) échouent chacune sur la vérification qui les garde.

## Global Constraints

- **Dépôt** : `C:\dev\jeux\atelier-couture`, branche `carnet-croquis`, créée depuis `main` (où les plans 1 à 10 et les correctifs de l'avatar et de la bulle sont fusionnés). Selon les règles du commanditaire : la branche testée et relue est fusionnée dans `main` et poussée sur GitHub.
- **Rojo** : `C:/dev/jeux/roblox-maker/rojo.exe`.
- **Contenu original** : aucun nom, texte, image ni son de *Dressmaker*.
- **Contraintes des plans précédents toujours valables** : fins de ligne LF, commits en français terminés par `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`, textes d'au moins 14 px, le serveur fait foi.

## Review Focus

- **Toucher le dessin hors de la robe, ou entre deux parties.** Attendu : rien ne s'ouvre hors de la robe ; la partie du dessus sinon. Tests : `56_croquis` (« hors de la robe : rien », « toucher le col Claudine : il est dessus ») et scénario (« toucher la jupe dessinée »).
- **Changer de modèle de nombreuses fois (téléphone).** Attendu : la mémoire des images ne grossit pas sans fin. Test : `17_vignettes` (« on ne garde que les derniers »).
- **Mémoire des images pleine.** Attendu : un mot à la place du dessin, pas l'ancien dessin ; le carnet reste utilisable. Test : scénario (« mémoire des images pleine »).
- **Modèle fermé choisi par ▶.** Attendu : grisé, sa raison, patron refusé avec ce qu'il faut pour l'ouvrir. Test : scénario (« tracer le patron d'un modèle fermé »).
- **Robe longue (jupe évasée).** Attendu : dessinée jusqu'à la cheville, dans l'image. Test : `56_croquis` (« la jupe longue descend à la cheville »).

---

### Task 1: Le dessin de chaque modèle (`Croquis`)

**Files:**
- Create: `src/shared/Croquis.luau`
- Create: `tests/unitaires/56_croquis.luau`

**Interfaces:**
- Consumes: `Catalogue.Variantes`, `Catalogue.variante(id)`, `Catalogue.FAMILLES`, `Polygone.contient`, `Polygone.miroir`.
- Produces: `Croquis.LARGEUR` (100), `Croquis.HAUTEUR` (130), `Croquis.ORDRE` ; `Croquis.parties(croquis) -> { { famille, polygone } }` ; `Croquis.details(croquis) -> { { a, b } }` ; `Croquis.MANNEQUIN` (segments) ; `Croquis.partieA(croquis, x, y) -> famille?` ; `Croquis.connue(idVariante) -> boolean`.

- [ ] **Step 1: Écrire les tests**

Créer `tests/unitaires/56_croquis.luau` :

```lua
-- Le croquis du carnet (sous-projet 5) : la robe dessinée de face, variante par variante
local Croquis = U.module("Croquis")
local Catalogue = U.module("Catalogue")
local Polygone = U.module("Polygone")

-- Chaque variante du catalogue a sa forme, dans le dessin ; les corsages finissent à la taille, les jupes en
-- partent
for _, v in ipairs(Catalogue.Variantes) do
	local forme = Croquis.FORMES[v.id]
	U.verifier(forme ~= nil and Croquis.connue(v.id), v.id .. " : une forme dans le croquis")
	local dedans = true
	for _, polygone in ipairs(forme and forme.parties or {}) do
		local b = Polygone.boite(polygone)
		dedans = dedans and b.minX >= 0 and b.maxX <= Croquis.LARGEUR and b.minY >= 0 and b.maxY <= Croquis.HAUTEUR
		if v.famille == "jupe" then
			U.verifier(U.proche(b.minY, Croquis.TAILLE), v.id .. " : la jupe part de la taille")
		elseif v.famille == "corsage" then
			U.verifier(U.proche(b.maxY, Croquis.TAILLE), v.id .. " : le corsage finit à la taille")
		end
	end
	U.verifier(dedans, v.id .. " : la forme tient dans le dessin")
	local pieces = #v.pieces > 0
	U.verifier((#(forme and forme.parties or {}) > 0) == pieces, v.id .. " : dessinée si elle a des pièces (« sans » : rien)")
end

-- Les parties dans l'ordre de dessin : jupe, corsage, manches (deux, en miroir), col
local base = { corsage = "corsage_droit", manches = "manches_sans", col = "col_sans", jupe = "jupe_droite" }
local parties = Croquis.parties(base)
U.verifier(#parties == 2 and parties[1].famille == "jupe" and parties[2].famille == "corsage", "robe simple : la jupe puis le corsage")
local habillee = { corsage = "corsage_v", manches = "manches_ballon", col = "col_claudine", jupe = "jupe_ample" }
parties = Croquis.parties(habillee)
local familles = {}
for _, p in ipairs(parties) do
	table.insert(familles, p.famille)
end
U.verifier(table.concat(familles, ",") == "jupe,corsage,manches,manches,col,col", "manches et col en deux moitiés, dessinés par-dessus (" .. table.concat(familles, ",") .. ")")
local gauche, droite = Polygone.boite(parties[3].polygone), Polygone.boite(parties[4].polygone)
U.verifier(U.proche(gauche.minX, Croquis.LARGEUR - droite.maxX) and gauche.maxX <= Croquis.LARGEUR / 2 and droite.minX >= Croquis.LARGEUR / 2, "les deux manches se répondent en miroir")
U.verifier(#Croquis.details(habillee) == 3 and #Croquis.details(base) == 0, "les fronces de la jupe ample en traits de crayon")

-- Toucher le dessin : la partie sous le doigt
U.verifier(Croquis.partieA(base, 50, 60) == "jupe" and Croquis.partieA(base, 50, 32) == "corsage", "toucher la jupe, le corsage")
U.verifier(Croquis.partieA(base, 25, 25) == nil and Croquis.partieA(base, 5, 5) == nil, "sans manches : rien sur les côtés ; hors de la robe : rien")
U.verifier(Croquis.partieA(habillee, 27, 24) == "manches" and Croquis.partieA(habillee, 73, 24) == "manches", "toucher une manche, à gauche comme à droite")
U.verifier(Croquis.partieA(habillee, 43, 18) == "col" and Croquis.partieA(habillee, 57, 18) == "col", "toucher le col Claudine : il est dessus")
U.verifier(Croquis.partieA({ corsage = "corsage_droit", manches = "manches_sans", col = "col_sans", jupe = "jupe_evasee" }, 50, 120) == "jupe" and Croquis.partieA(base, 50, 120) == nil, "la jupe longue descend à la cheville, la droite s'arrête au genou")
```

- [ ] **Step 2: Lancer les tests, vérifier l'échec**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT|attempt|membre" | head -3`
Expected: échec : une ligne qui finit par `Croquis n'est pas un membre valide de Folder « Couture »`

- [ ] **Step 3: Écrire le module**

Créer `src/shared/Croquis.luau` :

```lua
-- Croquis (sous-projet 5) : la robe dessinée de face dans le carnet, comme sur une page de carnet de couturière.
-- Chaque variante a sa forme vue de face : des polygones dans un repère de dessin de 100 unités de large et 130 de
-- haut (x vers la droite, y vers le bas), posés sur un gabarit commun : cou (y 8 à 14), épaules (y 17, x 34 et 66),
-- taille (y 42, x 39 à 61). Les formes « symétriques » sont dessinées à gauche et reprises en miroir à droite.
-- Données, et deux fonctions pures : les parties à dessiner, et la partie sous un point (toucher le dessin).
local dossier = script.Parent
local Catalogue = require(dossier:WaitForChild("Catalogue"))
local Polygone = require(dossier:WaitForChild("Polygone"))

local Croquis = {}
Croquis.LARGEUR, Croquis.HAUTEUR = 100, 130
Croquis.TAILLE = 42 -- hauteur de la taille : la jupe en part, le corsage y finit
Croquis.ORDRE = { "jupe", "corsage", "manches", "col" } -- ordre de dessin (le dernier est dessus)

local function P(liste)
	local points = {}
	for i = 1, #liste, 2 do
		table.insert(points, { x = liste[i], y = liste[i + 1] })
	end
	return points
end

-- FORMES[idVariante] = { parties = { polygone, ... }, symetrique = bool, details = { { a, b }, ... } }
-- (details : traits de crayon sur la pièce, plis ou croisé ; repris en miroir si la forme est symétrique)
local FORMES = {
	-- Corsages : des épaules à la taille
	corsage_droit = { parties = { P({ 34, 17, 41, 17, 42, 22, 58, 22, 59, 17, 66, 17, 67, 24, 65, 32, 61, 42, 39, 42, 35, 32, 33, 24 }) } },
	corsage_v = { parties = { P({ 34, 17, 43, 17, 50, 31, 57, 17, 66, 17, 67, 24, 65, 32, 61, 42, 39, 42, 35, 32, 33, 24 }) } },
	corsage_bretelles = { parties = { P({ 37, 16, 40, 16, 41, 24, 59, 24, 60, 16, 63, 16, 66, 26, 65, 32, 61, 42, 39, 42, 35, 32, 34, 26 }) } },
	corsage_cache_coeur = {
		parties = { P({ 34, 17, 42, 17, 55, 33, 58, 17, 66, 17, 67, 24, 65, 32, 61, 42, 39, 42, 35, 32, 33, 24 }) },
		details = { { { x = 58, y = 17 }, { x = 44, y = 40 } } }, -- le pan croisé
	},
	corsage_bustier = { parties = { P({ 34, 27, 42, 23, 50, 27, 58, 23, 66, 27, 65, 32, 61, 42, 39, 42, 35, 32 }) } },
	-- Manches : parties de l'épaule gauche (reprises en miroir)
	manches_sans = { parties = {} },
	manches_ballon = { symetrique = true, parties = { P({ 34, 17, 29, 17, 25, 21, 24, 27, 28, 31, 34, 29, 35, 24 }) } },
	manches_longues = { symetrique = true, parties = { P({ 34, 17, 30, 18, 26, 30, 22, 52, 27, 53, 31, 34, 34, 25 }) } },
	manches_courtes = { symetrique = true, parties = { P({ 34, 17, 29, 18, 26, 26, 27, 30, 33, 29, 34, 24 }) } },
	manches_trois_quarts = { symetrique = true, parties = { P({ 34, 17, 30, 18, 26, 30, 23, 42, 28, 43, 31, 32, 34, 25 }) } },
	-- Cols : autour du cou
	col_sans = { parties = {} },
	col_claudine = { symetrique = true, parties = { P({ 46, 13, 41, 15, 39, 19, 42, 22, 47, 21, 50, 16 }) } },
	col_montant = { parties = { P({ 45, 9, 55, 9, 56, 15, 44, 15 }) } },
	col_marin = { symetrique = true, parties = { P({ 46, 13, 37, 16, 39, 22, 50, 32 }) } },
	-- Jupes : de la taille à l'ourlet
	jupe_droite = { parties = { P({ 39, 42, 61, 42, 64, 82, 36, 82 }) } },
	jupe_trapeze = { parties = { P({ 39, 42, 61, 42, 71, 84, 29, 84 }) } },
	jupe_ample = {
		parties = { P({ 39, 42, 61, 42, 68, 52, 77, 88, 23, 88, 32, 52 }) },
		details = { -- les fronces
			{ { x = 45, y = 46 }, { x = 38, y = 87 } },
			{ { x = 50, y = 46 }, { x = 50, y = 88 } },
			{ { x = 55, y = 46 }, { x = 62, y = 87 } },
		},
	},
	jupe_evasee = { parties = { P({ 39, 42, 61, 42, 66, 60, 81, 124, 19, 124, 34, 60 }) } },
	jupe_crayon = { parties = { P({ 39, 42, 61, 42, 63, 52, 61, 84, 39, 84, 37, 52 }) } },
}
Croquis.FORMES = FORMES

-- Le mannequin esquissé derrière la robe (traits gris clair) : tête, cou, buste, pied, trépied
Croquis.MANNEQUIN = {
	{ { x = 48, y = 2 }, { x = 52, y = 2 } },
	{ { x = 47, y = 5 }, { x = 47, y = 14 } },
	{ { x = 53, y = 5 }, { x = 53, y = 14 } },
	{ { x = 47, y = 14 }, { x = 34, y = 17 } },
	{ { x = 53, y = 14 }, { x = 66, y = 17 } },
	{ { x = 34, y = 17 }, { x = 34, y = 30 } },
	{ { x = 66, y = 17 }, { x = 66, y = 30 } },
	{ { x = 34, y = 30 }, { x = 39, y = 42 } },
	{ { x = 66, y = 30 }, { x = 61, y = 42 } },
	{ { x = 39, y = 42 }, { x = 35, y = 54 } },
	{ { x = 61, y = 42 }, { x = 65, y = 54 } },
	{ { x = 35, y = 54 }, { x = 65, y = 54 } },
	{ { x = 50, y = 54 }, { x = 50, y = 122 } },
	{ { x = 50, y = 122 }, { x = 40, y = 128 } },
	{ { x = 50, y = 122 }, { x = 60, y = 128 } },
}

local function miroirSegment(s)
	return { { x = Croquis.LARGEUR - s[1].x, y = s[1].y }, { x = Croquis.LARGEUR - s[2].x, y = s[2].y } }
end

-- Parties à dessiner pour un croquis { corsage, manches, col, jupe }, dans l'ordre de dessin :
-- { { famille, polygone } } (une manche ou un rabat de col symétrique donne deux parties)
function Croquis.parties(croquis)
	local out = {}
	for _, famille in ipairs(Croquis.ORDRE) do
		local forme = FORMES[croquis[famille]]
		assert(forme, "forme de croquis inconnue : " .. tostring(croquis[famille]))
		for _, polygone in ipairs(forme.parties) do
			table.insert(out, { famille = famille, polygone = polygone })
			if forme.symetrique then
				table.insert(out, { famille = famille, polygone = Polygone.miroir(polygone, Croquis.LARGEUR / 2) })
			end
		end
	end
	return out
end

-- Traits de détail (plis, croisé) du croquis : { { a, b } }
function Croquis.details(croquis)
	local out = {}
	for _, famille in ipairs(Croquis.ORDRE) do
		local forme = FORMES[croquis[famille]]
		for _, s in ipairs(forme.details or {}) do
			table.insert(out, s)
			if forme.symetrique then
				table.insert(out, miroirSegment(s))
			end
		end
	end
	return out
end

-- La famille dessinée sous le point (x, y) du dessin (la plus haute dans l'ordre de dessin), ou nil
function Croquis.partieA(croquis, x, y)
	local parties = Croquis.parties(croquis)
	for i = #parties, 1, -1 do
		if Polygone.contient(parties[i].polygone, x, y) then
			return parties[i].famille
		end
	end
	return nil
end

-- Chaque variante du catalogue a sa forme (vérifié par les tests) ; utile au chargement des écrans
function Croquis.connue(idVariante)
	return FORMES[idVariante] ~= nil and Catalogue.variante(idVariante) ~= nil
end

return Croquis
```

- [ ] **Step 4: Lancer les tests**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT"`
Expected:
```
Unitaires : 167721 vérifications
TOUT EST VERT : 746 vérifications
```

- [ ] **Step 5: Commit**

```bash
git add src/shared/Croquis.luau tests/unitaires/56_croquis.luau
git commit -m "Croquis : la forme de face de chaque modèle, pour dessiner la robe au carnet

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 2: Le dessin peint et colorié (`Pixels.croquis`, `Vignettes.croquis`)

**Files:**
- Modify: `src/shared/Pixels.luau`, `src/client/Atelier/Vignettes.luau`
- Modify: `tests/unitaires/56_croquis.luau`, `tests/unitaires/17_vignettes.luau`

**Interfaces:**
- Consumes: `Croquis.parties`, `Croquis.details`, `Croquis.MANNEQUIN` (tâche 1) ; `Pixels.motif(idTissu)`.
- Produces: `Pixels.croquis(croquis, tissus, largeur, hauteur) -> buffer, largeur, hauteur` (tissus = `{ [famille] = idTissu? }`) ; `Vignettes.croquis(croquis, tissus, largeur, hauteur) -> Content?` ; `Vignettes.CROQUIS_GARDES` (6).

- [ ] **Step 1: Écrire les tests**

Dans `tests/unitaires/56_croquis.luau`, remplacer :

```lua
U.verifier(Croquis.partieA({ corsage = "corsage_droit", manches = "manches_sans", col = "col_sans", jupe = "jupe_evasee" }, 50, 120) == "jupe" and Croquis.partieA(base, 50, 120) == nil, "la jupe longue descend à la cheville, la droite s'arrête au genou")
```

par :

```lua
U.verifier(Croquis.partieA({ corsage = "corsage_droit", manches = "manches_sans", col = "col_sans", jupe = "jupe_evasee" }, 50, 120) == "jupe" and Croquis.partieA(base, 50, 120) == nil, "la jupe longue descend à la cheville, la droite s'arrête au genou")

-- Le dessin peint (Pixels.croquis) : transparent hors de la robe, blanc sans tissu, la couleur d'un tissu uni,
-- un trait de crayon au bord, le mannequin esquissé sous la robe
local Pixels = U.module("Pixels")
local L, H = 200, 260
local buf, l, h = Pixels.croquis(base, {}, L, H)
local function pixel(x, y)
	local i, j = math.floor(x / Croquis.LARGEUR * L), math.floor(y / Croquis.HAUTEUR * H)
	local v = buffer.readu32(buf, (j * L + i) * 4)
	return v % 256, math.floor(v / 256) % 256, math.floor(v / 65536) % 256, math.floor(v / 16777216)
end
U.verifier(l == L and h == H and buffer.len(buf) == L * H * 4, "une image de la taille demandée")
local _, _, _, a = pixel(5, 5)
U.verifier(a == 0, "hors de la robe : transparent (le papier du carnet est derrière)")
local r, g, b, a2 = pixel(50, 62)
U.verifier(a2 == 255 and r >= 245 and g >= 245 and b >= 240, "une partie sans tissu est blanche")
local _, _, _, a3 = pixel(50, 100)
U.verifier(a3 > 0 and a3 < 255, "le pied du mannequin esquissé sous la jupe courte, en gris léger")
local uni
for _, t in ipairs(Catalogue.Tissus) do
	if t.motif.type == "uni" and t.motif.couleurs[1][1] < 200 then
		uni = t
		break
	end
end
buf = Pixels.croquis(base, { jupe = uni.id }, L, H)
r, g, b = pixel(50, 62)
local c = uni.motif.couleurs[1]
U.verifier(r == c[1] and g == c[2] and b == c[3], "la jupe prend la couleur de son tissu (" .. uni.nom .. ")")
r = pixel(50, 32)
U.verifier(r >= 245, "le corsage sans tissu reste blanc")
local trait = false
for di = -2, 2 do
	local rr, gg, bb, aa = pixel(37.5 + di * Croquis.LARGEUR / L, 62)
	trait = trait or (aa == 255 and rr < 100 and gg < 100 and bb < 100)
end
U.verifier(trait, "un trait de crayon foncé au bord de la jupe")
```

Dans `tests/unitaires/17_vignettes.luau`, remplacer :

```lua
local Vignettes = U.module("Vignettes")
```

par :

```lua
local Vignettes = U.module("Vignettes")

-- Croquis du carnet (sous-projet 5) : gardé en cache, les plus récents seulement (ils occupent la mémoire des images)
do
	local Pixels = U.module("Pixels")
	local croquis = { corsage = "corsage_droit", manches = "manches_sans", col = "col_sans", jupe = "jupe_droite" }
	local peints = 0
	local peindre = Pixels.croquis
	Pixels.croquis = function(...)
		peints += 1
		return peindre(...)
	end
	local premier = Vignettes.croquis(croquis, {}, 100, 130)
	U.verifier(premier ~= nil and premier.statique and Vignettes.croquis(croquis, {}, 100, 130) == premier and peints == 1, "croquis peint une fois, puis gardé")
	for _, id in ipairs({ "coton_blanc", "coton_rose_pois", "lin_naturel", "lin_bleu", "coton_bleu_carreaux", "lin_noir", "coton_jaune_fleurs" }) do
		Vignettes.croquis(croquis, { jupe = id }, 100, 130)
	end
	Vignettes.croquis(croquis, {}, 100, 130)
	U.verifier(peints == 9, "après sept autres croquis, le premier est repeint : on ne garde que les derniers (" .. peints .. " peints)")
	Pixels.croquis = peindre
end
```

- [ ] **Step 2: Lancer les tests, vérifier l'échec**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT|attempt|membre" | head -3`
Expected: échec : une ligne qui finit par `attempt to call a nil value`

- [ ] **Step 3: Écrire le code**

Dans `src/shared/Pixels.luau`, remplacer :

```lua
local Polygone = require(dossier:WaitForChild("Polygone"))
```

par :

```lua
local Polygone = require(dossier:WaitForChild("Polygone"))
local Croquis = require(dossier:WaitForChild("Croquis"))
```

Dans `src/shared/Pixels.luau`, remplacer :

```lua
	return buf, largeur, hauteur
end

return Pixels
```

par :

```lua
	return buf, largeur, hauteur
end

---------------------------------------------------------------------------
-- Croquis du carnet (sous-projet 5) : la robe de face, chaque partie remplie du motif de son tissu (blanche sans
-- tissu), un trait de crayon autour, les plis en traits fins, le mannequin esquissé derrière. Fond transparent :
-- le papier du carnet est dessous. tissus = { [famille] = idTissu ou nil }. Retourne buffer, largeur, hauteur.
---------------------------------------------------------------------------
local BLANC_CROQUIS = { 252, 250, 245 }
local CRAYON = { 64, 50, 56 }
local CRAYON_FIN = { 120, 100, 106 }
local ESQUISSE = { 175, 165, 165, 150 }
local MOTIF_PAR_PX = 2 -- un pixel du dessin couvre deux pixels du motif : on voit les dessins du tissu

function Pixels.croquis(croquis, tissus, largeur, hauteur)
	local parties = Croquis.parties(croquis)
	local ex, ey = largeur / Croquis.LARGEUR, hauteur / Croquis.HAUTEUR
	-- Numéro de la partie visible à chaque pixel (0 : rien), rempli ligne par ligne (la dernière partie gagne)
	local etiquettes = buffer.create(largeur * hauteur)
	for k, partie in ipairs(parties) do
		local poly = partie.polygone
		local n = #poly
		for j = 0, hauteur - 1 do
			local y = (j + 0.5) / ey
			local xs = {}
			for i = 1, n do
				local a, b = poly[i], poly[i % n + 1]
				if (a.y <= y and b.y > y) or (b.y <= y and a.y > y) then
					table.insert(xs, a.x + (y - a.y) * (b.x - a.x) / (b.y - a.y))
				end
			end
			table.sort(xs)
			for m = 1, #xs - 1, 2 do
				for i = math.max(0, math.ceil(xs[m] * ex - 0.5)), math.min(largeur - 1, math.floor(xs[m + 1] * ex - 0.5)) do
					buffer.writeu8(etiquettes, j * largeur + i, k)
				end
			end
		end
	end
	local function etiquette(i, j)
		if i < 0 or j < 0 or i >= largeur or j >= hauteur then
			return 0
		end
		return buffer.readu8(etiquettes, j * largeur + i)
	end
	local motifs = {}
	for _, id in pairs(tissus) do
		motifs[id] = motifs[id] or Pixels.motif(id)
	end
	local blanc = empaqueter(BLANC_CROQUIS[1], BLANC_CROQUIS[2], BLANC_CROQUIS[3])
	local crayon = empaqueter(CRAYON[1], CRAYON[2], CRAYON[3])
	local buf = buffer.create(largeur * hauteur * 4)
	for j = 0, hauteur - 1 do
		for i = 0, largeur - 1 do
			local k = buffer.readu8(etiquettes, j * largeur + i)
			local valeur = 0
			if k > 0 then
				if etiquette(i - 1, j) ~= k or etiquette(i + 1, j) ~= k or etiquette(i, j - 1) ~= k or etiquette(i, j + 1) ~= k then
					valeur = crayon
				else
					local motif = motifs[tissus[parties[k].famille]]
					valeur = if motif then buffer.readu32(motif, (((j * MOTIF_PAR_PX) % N) * N + (i * MOTIF_PAR_PX) % N) * 4) else blanc
				end
			end
			buffer.writeu32(buf, (j * largeur + i) * 4, valeur)
		end
	end
	-- Traits : plis et croisé sur la robe (crayon fin), mannequin esquissé là où la robe ne passe pas
	local function tracer(segment, couleur, surLaRobe)
		local a, b = segment[1], segment[2]
		local pas = math.max(1, math.ceil(math.sqrt(((b.x - a.x) * ex) ^ 2 + ((b.y - a.y) * ey) ^ 2) * 2))
		for t = 0, pas do
			local i = math.floor((a.x + (b.x - a.x) * t / pas) * ex)
			local j = math.floor((a.y + (b.y - a.y) * t / pas) * ey)
			if i >= 0 and j >= 0 and i < largeur and j < hauteur and (etiquette(i, j) > 0) == surLaRobe then
				buffer.writeu32(buf, (j * largeur + i) * 4, couleur)
			end
		end
	end
	local fin = empaqueter(CRAYON_FIN[1], CRAYON_FIN[2], CRAYON_FIN[3])
	for _, s in ipairs(Croquis.details(croquis)) do
		tracer(s, fin, true)
	end
	local esquisse = empaqueterAlpha(ESQUISSE[1], ESQUISSE[2], ESQUISSE[3], ESQUISSE[4])
	for _, s in ipairs(Croquis.MANNEQUIN) do
		tracer(s, esquisse, false)
	end
	return buf, largeur, hauteur
end

return Pixels
```

Dans `src/client/Atelier/Vignettes.luau`, remplacer :

```lua
-- Oublie les images des pièces découpées
```

par :

```lua
-- Croquis du carnet (sous-projet 5) : la robe dessinée, coloriée de ses tissus ; tissus = { [famille] = idTissu }.
-- Chaque choix en fait un nouveau : on ne garde que les derniers (ils occupent la mémoire des images).
Vignettes.CROQUIS_GARDES = 6
local croquisRecents = {}
function Vignettes.croquis(croquis, tissus, largeur, hauteur)
	local morceaux = {}
	for _, famille in ipairs(Catalogue.FAMILLES) do
		table.insert(morceaux, croquis[famille] .. "=" .. (tissus[famille] or ""))
	end
	local cle = ("croquis:%s:%dx%d"):format(table.concat(morceaux, ","), largeur, hauteur)
	local contenu = figer(cle, function()
		return Pixels.croquis(croquis, tissus, largeur, hauteur)
	end)
	if contenu then
		local deja = table.find(croquisRecents, cle)
		if deja then
			table.remove(croquisRecents, deja)
		end
		table.insert(croquisRecents, cle)
		while #croquisRecents > Vignettes.CROQUIS_GARDES do
			cache[table.remove(croquisRecents, 1)] = nil
		end
	end
	return contenu
end

-- Oublie les images des pièces découpées
```

- [ ] **Step 4: Lancer les tests**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT"`
Expected:
```
Unitaires : 167730 vérifications
TOUT EST VERT : 746 vérifications
```

- [ ] **Step 5: Commit**

```bash
git add src/shared/Pixels.luau src/client/Atelier/Vignettes.luau tests/unitaires/56_croquis.luau tests/unitaires/17_vignettes.luau
git commit -m "Croquis peint : chaque partie du motif de son tissu, trait de crayon, mannequin esquissé ; les six derniers gardés

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 3: La page du carnet (`EcranCarnet`)

**Files:**
- Modify: `src/client/Atelier/EcranCarnet.luau` (réécrit)
- Modify: `tests/scenario.luau`

**Interfaces:**
- Consumes: `Croquis.partieA`, `Croquis.LARGEUR`, `Croquis.HAUTEUR` (tâche 1) ; `Vignettes.croquis` (tâche 2) ; `Metrage.conseil`, `Deblocages.ouvert`, `Deblocages.raison`, `Deblocages.message`, `Notation.fourchette`, `session:validerCroquis` (existants).
- Produces: dans `fenetre.Contenu` : `Page` (`Dessin`, `SansDessin`, `Echantillons` et ses `Echantillon_k`, `Pieces` et ses `Tissu_<pièce>`, `Precedent_<famille>`, `Modele_<famille>` avec l'attribut `Ferme`, `Suivant_<famille>`, `Points_<famille>` et ses `Point<k>`, `Environ`, `Valider`), `Droite` (la fiche) ; `ChoixTissu` a l'attribut `Famille` quand il vient du dessin.

- [ ] **Step 1: Écrire les tests**

Dans `tests/scenario.luau`, remplacer :

```lua
verifier(titre() == "1. Carnet de croquis", "mesures prises : le carnet")
-- Déblocages : au départ, ce qui est fermé est grisé, avec ce qu'il faut pour l'ouvrir, et ne se choisit pas
local jupeAmple = boutonNomme("Variante_jupe_ample")
verifier(jupeAmple:GetAttribute("Ferme") == true and jupeAmple.TextColor3 == GRIS and boutonNomme("Variante_jupe_droite"):GetAttribute("Ferme") == false, "jupe ample fermée au départ : grisée ; la jupe droite ouverte")
cliquer("Variante_jupe_ample")
verifier(fenetre.Message.Visible and fenetre.Message.Text == "Pas encore ouvert : Jupe ample froncée (Amitié de Colette : 2)." and boutonNomme("Variante_jupe_droite").BackgroundColor3 == Color3.fromRGB(214, 76, 128), "toucher une variante fermée : ce qu'il faut pour l'ouvrir, la jupe droite reste choisie")
```

par :

```lua
verifier(titre() == "1. Carnet de croquis", "mesures prises : le carnet")
-- Sous-projet 5 : le carnet est une page de croquis. Chaque famille se choisit par ◀ ▶ ; le modèle choisi est
-- dessiné, colorié de ses tissus
local function choisirModele(id)
	local v = Catalogue.variante(id)
	for _ = 1, #Catalogue.variantesDe(v.famille) do
		if fenetre.Contenu.Page["Modele_" .. v.famille].Text:sub(1, #v.nom) == v.nom then
			return
		end
		cliquer("Suivant_" .. v.famille)
	end
	verifier(fenetre.Contenu.Page["Modele_" .. v.famille].Text:sub(1, #v.nom) == v.nom, "modèle trouvé par ▶ : " .. id)
end
do
	local page = fenetre.Contenu:FindFirstChild("Page")
	local dessin = page and page:FindFirstChild("Dessin")
	verifier(dessin ~= nil and dessin:IsA("ImageButton") and dessin.ImageContent ~= nil and dessin.ImageContent.statique, "le carnet montre la robe dessinée")
	verifier(page.Modele_corsage.Text == "Droit" and page.Modele_jupe.Text == "Droite" and #page.Points_jupe:GetChildren() >= #Catalogue.variantesDe("jupe"), "le modèle de chaque famille, et un point par modèle")
	local ACCENT = Color3.fromRGB(214, 76, 128)
	local environDroite = page.Environ.Text
	verifier(string.match(environDroite, "^Environ %d+,%d m de tissu$") ~= nil and page.Points_jupe.Point1.BackgroundColor3 == ACCENT and page.Points_jupe.Point2.BackgroundColor3 ~= ACCENT, "environ X m de tissu, et le point du modèle choisi est marqué (" .. environDroite .. ")")
	local dessinAvant = dessin.ImageContent
	cliquer("Suivant_jupe")
	verifier(page.Modele_jupe.Text == "Trapèze" and dessin.ImageContent ~= dessinAvant and page.Points_jupe.Point2.BackgroundColor3 == ACCENT and page.Points_jupe.Point1.BackgroundColor3 ~= ACCENT, "▶ : le modèle suivant, dessiné, son point marqué")
	cliquer("Precedent_jupe")
	verifier(page.Modele_jupe.Text == "Droite", "◀ : retour au modèle précédent")
	-- Mémoire des images pleine : un mot à la place du dessin (pas l'ancien), le carnet marche quand même
	local VignettesCarnet = requireModule(scriptClient.Vignettes)
	local peindre, colAvant = VignettesCarnet.croquis, page.Modele_col.Text
	VignettesCarnet.croquis = function()
		return nil
	end
	cliquer("Suivant_col")
	verifier(dessin.SansDessin.Visible and dessin.ImageTransparency == 1 and page.Modele_col.Text ~= colAvant, "mémoire des images pleine : un mot à la place du dessin, les modèles se choisissent quand même")
	VignettesCarnet.croquis = peindre
	cliquer("Precedent_col")
	verifier(not dessin.SansDessin.Visible and dessin.ImageTransparency == 0 and page.Modele_col.Text == colAvant, "le dessin revient")
	-- Déblocages : au départ, ce qui est fermé est grisé, avec ce qu'il faut pour l'ouvrir ; son patron ne se trace pas
	choisirModele("jupe_ample")
	verifier(page.Modele_jupe:GetAttribute("Ferme") == true and page.Modele_jupe.TextColor3 == GRIS and string.find(page.Modele_jupe.Text, "Amitié de Colette : 2", 1, true) ~= nil, "jupe ample fermée au départ : grisée, avec ce qu'il faut pour l'ouvrir")
	verifier(page.Environ.Text ~= environDroite, "le métrage suit le modèle : une jupe froncée demande plus de tissu (" .. page.Environ.Text .. ")")
	cliquer("Valider")
	verifier(fenetre.Message.Visible and fenetre.Message.Text == "Pas encore ouvert : Jupe ample froncée (Amitié de Colette : 2)." and titre() == "1. Carnet de croquis", "tracer le patron d'un modèle fermé : ce qu'il faut pour l'ouvrir")
	choisirModele("jupe_droite")
	verifier(page.Modele_jupe:GetAttribute("Ferme") == false, "la jupe droite, ouverte")
end
```

Dans `tests/scenario.luau`, remplacer :

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

par :

```lua
choisirModele("jupe_ample")
verifier(fenetre.Contenu.Page.Modele_jupe:GetAttribute("Ferme") == false and fenetre.Contenu.Page.Modele_jupe.Text == "Ample froncée", "prestige et amitiés au plus haut : la jupe ample s'ouvre dans le carnet")
choisirModele("jupe_droite")
do -- Les 19 modèles se parcourent, et ▶ revient au premier après le dernier
	local vus, nbVus = {}, 0
	for _, famille in ipairs(Catalogue.FAMILLES) do
		for _ = 1, #Catalogue.variantesDe(famille) do
			local nom = fenetre.Contenu.Page["Modele_" .. famille].Text
			if not vus[nom] then
				vus[nom], nbVus = true, nbVus + 1
			end
			cliquer("Suivant_" .. famille)
		end
	end
	verifier(nbVus == #Catalogue.Variantes and fenetre.Contenu.Page.Modele_corsage.Text == "Droit" and fenetre.Contenu.Page.Modele_jupe.Text == "Droite", "les " .. #Catalogue.Variantes .. " modèles se parcourent par ▶, qui revient au premier (" .. nbVus .. ")")
end
```

Dans `tests/scenario.luau`, remplacer :

```lua
-- Robe : décolleté en V, manches ballon, col Claudine, jupe trapèze
for _, v in ipairs({ "corsage_v", "manches_ballon", "col_claudine", "jupe_trapeze" }) do
	cliquer("Variante_" .. v)
	verifier(boutonNomme("Variante_" .. v).BackgroundColor3 == Color3.fromRGB(214, 76, 128), v .. " en surbrillance")
end
local pieces = fenetre.Contenu.Gauche.Pieces
```

par :

```lua
-- Robe : décolleté en V, manches ballon, col Claudine, jupe trapèze
for _, v in ipairs({ "corsage_v", "manches_ballon", "col_claudine", "jupe_trapeze" }) do
	choisirModele(v)
	verifier(fenetre.Contenu.Page["Modele_" .. Catalogue.variante(v).famille].Text == Catalogue.variante(v).nom, v .. " choisi")
end
-- Toucher le dessin : le choix du tissu de la partie touchée (ici la jupe, ses deux pièces)
do
	local d = fenetre.Contenu.Page.Dessin
	local point = Vector2.new(d.AbsolutePosition.X + d.AbsoluteSize.X * 0.5, d.AbsolutePosition.Y + d.AbsoluteSize.Y * 70 / 130)
	M.avancer(0.5)
	d.Activated:Fire({ Position = Vector3.new(point.X, point.Y, 0) }, 1)
	local ouvert = fenetre.Contenu:FindFirstChild("ChoixTissu")
	verifier(ouvert ~= nil and ouvert:GetAttribute("Famille") == "jupe", "toucher la jupe dessinée : le choix de son tissu")
	cliquer("FermerChoix")
end
local pieces = fenetre.Contenu.Page.Pieces
```

Dans `tests/scenario.luau`, remplacer :

```lua
local pastille = pieces:FindFirstChild("Pastille")
```

par :

```lua
local pastille
for _, d in ipairs(pieces:GetDescendants()) do
	pastille = pastille or (d.Name == "Pastille" and d or nil)
end
```

Dans `tests/scenario.luau`, remplacer :

```lua
local nbSoie = 0
for _, d in ipairs(pieces:GetChildren()) do
```

par :

```lua
local nbSoie = 0
for _, d in ipairs(pieces:GetDescendants()) do
```

Dans `tests/scenario.luau`, remplacer :

```lua
verifier(nbSoie == 6, "toute la robe en soie rose fleurie")
```

par :

```lua
verifier(nbSoie == 6, "toute la robe en soie rose fleurie")
verifier(fenetre.Contenu.Page.Echantillons:FindFirstChild("Echantillon_1") ~= nil and fenetre.Contenu.Page.Echantillons:FindFirstChild("Echantillon_2") == nil, "l'échantillon de la soie est épinglé à la page (un par tissu)")
```

Dans `tests/scenario.luau`, remplacer :

```lua
etatCarnet.argent = prixRobe - 10
cliquer("Variante_jupe_trapeze") -- même croquis : le carnet se redessine
```

par :

```lua
etatCarnet.argent = prixRobe - 10
cliquer("Suivant_jupe") -- aller et retour : même croquis, le carnet se redessine
cliquer("Precedent_jupe")
```

Dans `tests/scenario.luau`, remplacer :

```lua
etatCarnet.argent = argentVrai
cliquer("Variante_jupe_trapeze")
```

par :

```lua
etatCarnet.argent = argentVrai
cliquer("Suivant_jupe")
cliquer("Precedent_jupe")
```

Dans `tests/scenario.luau`, remplacer :

```lua
for _, v in pairs(croquisNouveau) do
	cliquer("Variante_" .. v)
	verifier(boutonNomme("Variante_" .. v).BackgroundColor3 == Color3.fromRGB(214, 76, 128), v .. " choisie au carnet")
end
```

par :

```lua
for _, v in pairs(croquisNouveau) do
	choisirModele(v)
	verifier(fenetre.Contenu.Page["Modele_" .. Catalogue.variante(v).famille].Text == Catalogue.variante(v).nom, v .. " choisie au carnet")
end
```

Dans `tests/scenario.luau`, remplacer :

```lua
for _, v in ipairs({ "corsage_v", "manches_ballon", "col_claudine", "jupe_trapeze" }) do
	cliquer("Variante_" .. v)
end
```

par :

```lua
for _, v in ipairs({ "corsage_v", "manches_ballon", "col_claudine", "jupe_trapeze" }) do
	choisirModele(v)
end
```

- [ ] **Step 2: Lancer les tests, vérifier l'échec**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT|attempt|membre" | head -3`
Expected: échec : une ligne qui finit par `ÉCHEC : le carnet montre la robe dessinée`

- [ ] **Step 3: Réécrire l'écran**

Créer `src/client/Atelier/EcranCarnet.luau` :

```lua
-- Écran du carnet de croquis (sous-projet 5 : une page de carnet, comme chez une couturière). À gauche, la page :
-- les échantillons des tissus choisis épinglés, la robe dessinée de face et coloriée de ses tissus (la toucher
-- choisit le tissu de la partie touchée), les pièces et leur tissu, une ligne ◀ modèle ▶ par famille, le tissu
-- qu'il faudra environ, et « Tracer le patron ». À droite, la fiche de commande : exigences, jauges de style,
-- métrage et coût du tissu à acheter. Tout se met à jour en direct.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Couture = ReplicatedStorage:WaitForChild("Couture")
local Catalogue = require(Couture:WaitForChild("Catalogue"))
local Patron = require(Couture:WaitForChild("Patron"))
local Notation = require(Couture:WaitForChild("Notation"))
local Metrage = require(Couture:WaitForChild("Metrage"))
local EtatAtelier = require(Couture:WaitForChild("EtatAtelier"))
local Clientes = require(Couture:WaitForChild("Clientes"))
local Deblocages = require(Couture:WaitForChild("Deblocages"))
local Croquis = require(Couture:WaitForChild("Croquis"))
local Vignettes = require(script.Parent:WaitForChild("Vignettes"))

local NOMS_FAMILLES = { corsage = "Corsage", manches = "Manches", col = "Col", jupe = "Jupe" }
local ORDRE_LIGNES = { "corsage", "col", "manches", "jupe" } -- comme sur la page d'un carnet : du haut vers le bas
local CROQUIS_DEPART = { corsage = "corsage_droit", manches = "manches_sans", col = "col_sans", jupe = "jupe_droite" }
local PAPIER = Color3.fromRGB(250, 245, 232)
local LISERE = Color3.fromRGB(196, 168, 150)
local CRAYON = Color3.fromRGB(110, 90, 96)
local L_DESSIN, H_DESSIN = 230, 299 -- pixels de l'image du dessin (100 × 130 unités de croquis)

return function(ctx)
	local UiKit, session, contenu = ctx.UiKit, ctx.session, ctx.contenu
	local C = UiKit.COULEURS
	local etat = session.etat
	local croquis = table.clone(etat.croquis or CROQUIS_DEPART)
	local tissus = table.clone(etat.tissus or {})
	local dernierTissu = nil
	local rafraichir, ouvrirChoix

	-- La page du carnet : papier, liseré, quelques notes au crayon dans la marge, un crayon posé
	local page = UiKit.arrondir(UiKit.creer("Frame", { Name = "Page", BackgroundColor3 = PAPIER, Size = UDim2.new(0, 540, 1, 0), Parent = contenu }), 10)
	UiKit.creer("UIStroke", { Color = LISERE, Thickness = 2, Parent = page })
	for _, note in ipairs({ { "poitrine", 14, 196 }, { "taille", 14, 216 }, { "ourlet", 14, 236 } }) do
		UiKit.texte({ Text = note[1], Font = Enum.Font.Kalam, TextSize = 14, TextColor3 = LISERE, Position = UDim2.fromOffset(note[2], note[3]), Size = UDim2.fromOffset(90, 18), Parent = page })
	end
	local crayon = UiKit.creer("Frame", { Name = "Crayon", BackgroundColor3 = Color3.fromRGB(214, 110, 140), BorderSizePixel = 0, Position = UDim2.fromOffset(80, 180), Size = UDim2.fromOffset(6, 110), Rotation = 12, Parent = page })
	UiKit.creer("Frame", { BackgroundColor3 = Color3.fromRGB(236, 206, 170), BorderSizePixel = 0, Position = UDim2.new(0, 0, 1, 0), Size = UDim2.fromOffset(6, 10), Parent = crayon })

	-- Les échantillons des tissus choisis, épinglés en haut à gauche
	local echantillons = UiKit.creer("Frame", { Name = "Echantillons", BackgroundTransparency = 1, Position = UDim2.fromOffset(10, 10), Size = UDim2.fromOffset(90, 180), Parent = page })

	-- La robe dessinée ; la toucher choisit le tissu de la partie touchée
	local dessin = UiKit.creer("ImageButton", { Name = "Dessin", BackgroundTransparency = 1, AutoButtonColor = false, Position = UDim2.fromOffset(100, 4), Size = UDim2.fromOffset(L_DESSIN, H_DESSIN), Parent = page })
	local sansDessin = UiKit.texte({ Name = "SansDessin", Text = "(le dessin ne peut pas s'afficher)", TextSize = 14, TextColor3 = CRAYON, TextXAlignment = Enum.TextXAlignment.Center, Size = UDim2.fromScale(1, 1), Visible = false, Parent = dessin })
	dessin.Activated:Connect(function(entree)
		local position = entree and entree.Position
		if not position or dessin.AbsoluteSize.X <= 0 then
			return
		end
		local u = (position.X - dessin.AbsolutePosition.X) / dessin.AbsoluteSize.X
		local v = (position.Y - dessin.AbsolutePosition.Y) / dessin.AbsoluteSize.Y
		local famille = Croquis.partieA(croquis, u * Croquis.LARGEUR, v * Croquis.HAUTEUR)
		if famille then
			ouvrirChoix(Catalogue.variante(croquis[famille]).pieces, famille)
		end
	end)

	-- Les pièces du croquis et leur tissu (une ligne par pièce : la toucher choisit son tissu)
	local listePieces = UiKit.creer("Frame", { Name = "Pieces", BackgroundTransparency = 1, Position = UDim2.fromOffset(334, 6), Size = UDim2.fromOffset(198, 300), Parent = page })

	-- Une ligne ◀ modèle ▶ par famille, avec un point par modèle
	local lignes = {}
	for i, famille in ipairs(ORDRE_LIGNES) do
		local y = 310 + (i - 1) * 28
		local modeles = Catalogue.variantesDe(famille)
		UiKit.texte({ Text = NOMS_FAMILLES[famille], Font = Enum.Font.GothamBold, TextSize = 14, TextColor3 = CRAYON, Position = UDim2.fromOffset(14, y + 3), Size = UDim2.fromOffset(70, 20), Parent = page })
		local function tourner(pas)
			local rang = 1
			for k, m in ipairs(modeles) do
				if m.id == croquis[famille] then
					rang = k
				end
			end
			croquis[famille] = modeles[(rang - 1 + pas) % #modeles + 1].id
			rafraichir()
		end
		UiKit.boutonDoux({ Name = "Precedent_" .. famille, Text = "◀", TextSize = 30, TextColor3 = Color3.fromRGB(196, 120, 60), Position = UDim2.fromOffset(86, y), Size = UDim2.fromOffset(34, 26), Parent = page }, function()
			tourner(-1)
		end)
		local nom = UiKit.texte({ Name = "Modele_" .. famille, Font = Enum.Font.GothamBold, TextSize = 16, TextXAlignment = Enum.TextXAlignment.Center, Position = UDim2.fromOffset(124, y), Size = UDim2.fromOffset(354, 18), Parent = page })
		UiKit.boutonDoux({ Name = "Suivant_" .. famille, Text = "▶", TextSize = 30, TextColor3 = Color3.fromRGB(196, 120, 60), Position = UDim2.fromOffset(482, y), Size = UDim2.fromOffset(34, 26), Parent = page }, function()
			tourner(1)
		end)
		local points = UiKit.creer("Frame", { Name = "Points_" .. famille, BackgroundTransparency = 1, Position = UDim2.fromOffset(124, y + 19), Size = UDim2.fromOffset(354, 7), Parent = page })
		UiKit.creer("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Center, Padding = UDim.new(0, 6), Parent = points })
		local pastilles = {}
		for k, m in ipairs(modeles) do
			pastilles[m.id] = UiKit.arrondir(UiKit.creer("Frame", { Name = "Point" .. k, BorderSizePixel = 0, Size = UDim2.fromOffset(7, 7), LayoutOrder = k, Parent = points }), 4)
		end
		lignes[famille] = { nom = nom, pastilles = pastilles }
	end
	local environ = UiKit.texte({ Name = "Environ", Font = Enum.Font.Kalam, TextSize = 16, TextColor3 = Color3.fromRGB(176, 70, 90), Position = UDim2.fromOffset(16, 434), Size = UDim2.fromOffset(270, 24), Parent = page })

	-- La fiche de commande, épinglée à droite : qui commande, exigences, jauges de style, métrage
	local droite = UiKit.arrondir(UiKit.creer("Frame", { Name = "Droite", BackgroundColor3 = C.panneau, Position = UDim2.new(1, -310, 0, 0), Size = UDim2.new(0, 310, 1, 0), Parent = contenu }), 10)
	UiKit.arrondir(UiKit.creer("Frame", { Name = "Epingle", BackgroundColor3 = C.accent, BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0, 4), Size = UDim2.fromOffset(10, 10), Parent = droite }), 5)
	local fiche = etat.commande.cliente and Clientes.get(etat.commande.cliente)
	local qui = fiche and fiche.nom:match("^(%S+)") or "La cliente"
	local entete = if etat.commande.libre then ("Robe libre (taille %s) : à ton idée."):format(etat.commande.taille) else ("%s (taille %s) veut :"):format(qui, etat.commande.taille)
	UiKit.texte({ Name = "Entete", Text = entete, Font = Enum.Font.GothamBold, Position = UDim2.fromOffset(12, 12), Size = UDim2.new(1, -24, 0, 22), Parent = droite })
	local lignesExigences = {}
	for i, e in ipairs(etat.commande.exigences) do
		lignesExigences[i] = UiKit.texte({ Name = "Exigence" .. i, TextSize = 14, Position = UDim2.fromOffset(12, 14 + i * 22), Size = UDim2.new(1, -24, 0, 20), Parent = droite })
	end
	local jauges = {}
	local y0 = 34 + #etat.commande.exigences * 22 + 12
	for i, style in ipairs(Catalogue.STYLES) do
		local y = y0 + (i - 1) * 30
		UiKit.texte({ Text = Catalogue.NOMS_STYLES[style], TextSize = 14, Position = UDim2.fromOffset(12, y), Size = UDim2.fromOffset(100, 20), Parent = droite })
		local fond = UiKit.arrondir(UiKit.creer("Frame", { Name = "Jauge_" .. style, BackgroundColor3 = C.secondaire, Position = UDim2.fromOffset(112, y + 4), Size = UDim2.fromOffset(180, 12), Parent = droite }), 6)
		local plage = UiKit.creer("Frame", { Name = "Plage", BackgroundColor3 = C.accent, BackgroundTransparency = 0.65, BorderSizePixel = 0, Parent = fond })
		local acquis = UiKit.creer("Frame", { Name = "Acquis", BackgroundColor3 = C.accent, BorderSizePixel = 0, Parent = fond })
		for _, e in ipairs(etat.commande.exigences) do
			if e.style == style then
				UiKit.creer("Frame", { Name = "Cible", BackgroundColor3 = C.texte, BorderSizePixel = 0, Position = UDim2.new(e.valeur / 100, -1, 0, -3), Size = UDim2.new(0, 2, 1, 6), Parent = fond })
			end
		end
		jauges[style] = { plage = plage, acquis = acquis }
	end
	-- Sous les jauges, en bas de la fiche : le tissu à acheter pour ce croquis, et son coût
	local metrage = UiKit.texte({ Name = "Metrage", TextSize = 14, AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 12, 1, -8), Size = UDim2.new(1, -24, 0, 46), Parent = droite })

	-- Choix du tissu de pièces (par-dessus le carnet), filtrable par style. Un bouton sans texte, pas un simple
	-- cadre : dans Roblox, un cadre (même Active) laisse passer l'appui aux boutons cachés dessous (modèles,
	-- « Tracer le patron »…), par exemple entre deux cartes de tissu
	local choix
	local function fermerChoix()
		if choix then
			choix:Destroy()
			choix = nil
		end
	end
	ouvrirChoix = function(pieces, famille)
		fermerChoix()
		choix = UiKit.arrondir(UiKit.creer("TextButton", { Name = "ChoixTissu", Text = "", AutoButtonColor = false, BackgroundColor3 = C.fond, Size = UDim2.fromScale(1, 1), ZIndex = 10, Parent = contenu }), 10)
		choix:SetAttribute("Famille", famille)
		UiKit.boutonDoux({ Name = "FermerChoix", Text = "Retour", Position = UDim2.new(1, -120, 0, 0), Size = UDim2.fromOffset(110, 34), ZIndex = 11, Parent = choix }, fermerChoix)
		local grille = UiKit.creer("ScrollingFrame", {
			Name = "Grille",
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Position = UDim2.fromOffset(0, 44),
			Size = UDim2.new(1, 0, 1, -44),
			CanvasSize = UDim2.new(),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			ScrollBarThickness = 6,
			ZIndex = 11,
			Parent = choix,
		})
		UiKit.creer("UIGridLayout", { CellSize = UDim2.fromOffset(200, 96), CellPadding = UDim2.fromOffset(8, 8), Parent = grille })
		local function remplir(filtre)
			for _, enfant in ipairs(grille:GetChildren()) do
				if enfant:IsA("TextButton") then
					enfant:Destroy()
				end
			end
			for _, t in ipairs(Catalogue.Tissus) do
				if not filtre or (t.style[filtre] or 0) > 0 then
					local ouvert = Deblocages.ouvert(etat, "tissus", t.id)
					local carte = UiKit.arrondir(UiKit.creer("TextButton", { Name = "Tissu_" .. t.id, Text = "", AutoButtonColor = ouvert, BackgroundColor3 = if ouvert then C.panneau else C.ferme, ZIndex = 12, Parent = grille }), 8)
					carte:SetAttribute("Ferme", not ouvert)
					local motif = Vignettes.motif(t.id)
					local echantillon = UiKit.arrondir(UiKit.creer("ImageLabel", {
						BackgroundColor3 = UiKit.couleur(t.motif.couleurs[1]),
						Position = UDim2.fromOffset(8, 8),
						Size = UDim2.fromOffset(56, 80),
						ScaleType = Enum.ScaleType.Tile,
						TileSize = UDim2.fromOffset(64, 64),
						ZIndex = 13,
						Parent = carte,
					}), 6)
					if motif then
						echantillon.ImageContent = motif
					end
					UiKit.texte({ Text = t.nom, Font = Enum.Font.GothamBold, TextSize = 14, Position = UDim2.fromOffset(72, 8), Size = UDim2.new(1, -80, 0, 36), ZIndex = 13, Parent = carte })
					local styles = {}
					for s, pts in pairs(t.style) do
						table.insert(styles, { s = s, pts = pts })
					end
					table.sort(styles, function(a, b)
						return a.pts > b.pts
					end)
					local etiquettes = {}
					for k = 1, math.min(2, #styles) do
						table.insert(etiquettes, Catalogue.NOMS_STYLES[styles[k].s])
					end
					if ouvert then
						UiKit.texte({ Text = (if t.prix == 0 then "Gratuit" else ("%d po/m"):format(t.prix)) .. " · " .. table.concat(etiquettes, ", "), TextSize = 14, TextColor3 = C.texteDoux, Position = UDim2.fromOffset(72, 50), Size = UDim2.new(1, -80, 0, 36), ZIndex = 13, Parent = carte })
					else
						UiKit.texte({ Name = "Raison", Text = Deblocages.raison("tissus", t.id), Font = Enum.Font.GothamBold, TextSize = 14, TextColor3 = C.texteDoux, Position = UDim2.fromOffset(72, 50), Size = UDim2.new(1, -80, 0, 36), ZIndex = 13, Parent = carte })
						echantillon.ImageTransparency, echantillon.BackgroundTransparency = 0.6, 0.6
					end
					carte.Activated:Connect(function()
						if not Deblocages.ouvert(etat, "tissus", t.id) then
							ctx.message(Deblocages.message("tissus", t.id), C.texteDoux)
							return
						end
						for _, id in ipairs(pieces) do
							tissus[id] = t.id
						end
						dernierTissu = t.id
						fermerChoix()
						rafraichir()
					end)
				end
			end
		end
		local filtres = { { nom = "Tous" } }
		for _, s in ipairs(Catalogue.STYLES) do
			table.insert(filtres, { nom = Catalogue.NOMS_STYLES[s], style = s })
		end
		for k, f in ipairs(filtres) do
			UiKit.boutonDoux({ Name = "Filtre_" .. (f.style or "tous"), Text = f.nom, TextSize = 14, Position = UDim2.fromOffset((k - 1) * 106, 0), Size = UDim2.fromOffset(100, 34), ZIndex = 11, Parent = choix }, function()
				remplir(f.style)
			end)
		end
		remplir(nil)
	end

	rafraichir = function()
		local pieces = Patron.piecesDuCroquis(croquis)
		-- Le modèle de chaque famille, grisé avec ce qu'il faut pour l'ouvrir s'il est fermé, et ses points
		for famille, ligne in pairs(lignes) do
			local id = croquis[famille]
			local ouvert = Deblocages.ouvert(etat, "variantes", id)
			ligne.nom.Text = if ouvert then Catalogue.variante(id).nom else ("%s · %s"):format(Catalogue.variante(id).nom, Deblocages.raison("variantes", id))
			ligne.nom.TextColor3 = if ouvert then C.texte else C.texteDoux
			ligne.nom:SetAttribute("Ferme", not ouvert)
			for m, pastille in pairs(ligne.pastilles) do
				pastille.BackgroundColor3 = if m == id then C.accent else LISERE
			end
		end
		-- La robe dessinée, coloriée du tissu de la pièce de devant de chaque famille
		local tissusDessin = {}
		for _, famille in ipairs(Catalogue.FAMILLES) do
			local premiere = Catalogue.variante(croquis[famille]).pieces[1]
			tissusDessin[famille] = premiere and tissus[premiere] or nil
		end
		local image = Vignettes.croquis(croquis, tissusDessin, L_DESSIN, H_DESSIN)
		if image then
			dessin.ImageContent = image
		end
		-- Mémoire des images pleine : pas de dessin (pas l'ancien non plus), un mot à la place ; le reste marche
		dessin.ImageTransparency = if image then 0 else 1
		sansDessin.Visible = image == nil
		-- Les échantillons épinglés : un par tissu choisi, dans l'ordre de la robe
		echantillons:ClearAllChildren()
		local deja = {}
		for _, id in ipairs(pieces) do
			local t = tissus[id] and Catalogue.tissu(tissus[id])
			if t and not deja[t.id] and #echantillons:GetChildren() < 4 then
				deja[t.id] = true
				local k = #echantillons:GetChildren() + 1
				local carre = UiKit.creer("ImageLabel", { Name = "Echantillon_" .. k, BackgroundColor3 = UiKit.couleur(t.motif.couleurs[1]), ScaleType = Enum.ScaleType.Tile, TileSize = UDim2.fromOffset(64, 64), Position = UDim2.fromOffset((k % 2 == 0) and 30 or 0, (k - 1) * 40), Size = UDim2.fromOffset(52, 52), Rotation = (k % 2 == 0) and 6 or -5, Parent = echantillons })
				UiKit.creer("UIStroke", { Color = LISERE, Thickness = 2, Parent = carre })
				UiKit.arrondir(UiKit.creer("Frame", { Name = "Epingle", BackgroundColor3 = C.accent, BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0, 3), Size = UDim2.fromOffset(8, 8), Parent = carre }), 4)
				local motif = Vignettes.motif(t.id)
				if motif then
					carre.ImageContent = motif
				end
			end
		end
		-- Les pièces et leur tissu : toucher une ligne choisit le tissu de cette pièce
		listePieces:ClearAllChildren()
		for i, id in ipairs(pieces) do
			local t = tissus[id] and Catalogue.tissu(tissus[id])
			local ligne = UiKit.arrondir(UiKit.creer("TextButton", { Name = "Tissu_" .. id, Text = "", AutoButtonColor = true, BackgroundColor3 = C.panneau, BackgroundTransparency = 0.3, Position = UDim2.fromOffset(0, (i - 1) * 36), Size = UDim2.fromOffset(198, 34), Parent = listePieces }), 6)
			ligne.Activated:Connect(function()
				ouvrirChoix({ id })
			end)
			local pastille = UiKit.arrondir(UiKit.creer("ImageLabel", { Name = "Pastille", BackgroundColor3 = t and UiKit.couleur(t.motif.couleurs[1]) or C.secondaire, ScaleType = Enum.ScaleType.Tile, TileSize = UDim2.fromOffset(64, 64), Position = UDim2.fromOffset(4, 4), Size = UDim2.fromOffset(26, 26), Parent = ligne }), 13)
			pastille.BackgroundTransparency = t and 0 or 0.5
			local motif = t and Vignettes.motif(t.id)
			if motif then
				pastille.ImageContent = motif
			end
			UiKit.texte({ Text = Catalogue.piece(id).nom, Font = Enum.Font.GothamBold, TextSize = 14, TextTruncate = Enum.TextTruncate.AtEnd, Position = UDim2.fromOffset(36, 1), Size = UDim2.fromOffset(158, 16), Parent = ligne })
			UiKit.texte({ Text = t and t.nom or "(aucun tissu)", TextSize = 14, TextColor3 = t and C.texte or C.texteDoux, TextTruncate = Enum.TextTruncate.AtEnd, Position = UDim2.fromOffset(36, 17), Size = UDim2.fromOffset(158, 16), Parent = ligne })
		end
		UiKit.boutonDoux({ Name = "ToutEnUnTissu", Text = "Même tissu pour toute la robe", TextSize = 14, Position = UDim2.fromOffset(0, #pieces * 36 + 4), Size = UDim2.fromOffset(198, 32), Parent = listePieces }, function()
			if dernierTissu then
				for _, id in ipairs(pieces) do
					tissus[id] = dernierTissu
				end
				rafraichir()
			else
				ouvrirChoix(pieces)
			end
		end)
		-- Le tissu qu'il faudra, à peu près
		environ.Text = ("Environ %s m de tissu"):format((("%.1f"):format(Metrage.conseil(pieces) / 10)):gsub("%.", ","))
		-- Jauges et exigences
		local choixPieces = {}
		for _, id in ipairs(pieces) do
			choixPieces[id] = tissus[id]
		end
		local fourchette = Notation.fourchette(croquis, choixPieces, Notation.accessoiresImposes(etat.commande.exigences), Deblocages.ouverts(etat).tissus)
		for style, j in pairs(jauges) do
			local f = fourchette[style]
			j.acquis.Size = UDim2.fromScale(f.min / 100, 1)
			j.plage.Size = UDim2.fromScale(f.max / 100, 1)
		end
		-- Tissu à acheter (le stock compte) et son coût
		local aAcheter, dm = Metrage.aAcheter(pieces, tissus, etat.stock)
		local prix = 0
		for _, t in ipairs(aAcheter) do
			prix += EtatAtelier.prix(t.tissu, t.manque)
		end
		if #aAcheter == 0 then
			metrage.Text, metrage.TextColor3 = "Choisis les tissus : le métrage et le coût s'affichent ici.", C.texteDoux
		elseif prix > etat.argent then
			metrage.Text = ("Tissu à acheter : %d dm, %d po — il te manque %d po."):format(dm, prix, prix - etat.argent)
			metrage.TextColor3 = C.erreur
		else
			metrage.Text, metrage.TextColor3 = ("Tissu à acheter : %d dm, %d po (tu as %d po)."):format(dm, prix, etat.argent), C.texte
		end
		local SYMBOLES = { ok = "✓", non = "×", ["?"] = "…" }
		local COULEURS_STATUT = { ok = C.ok, non = C.erreur, ["?"] = C.texteDoux }
		local ajustement = etat.commande.ajustement
		for i, e in ipairs(etat.commande.exigences) do
			local statut = Notation.prevision(e, croquis, choixPieces, fourchette, ajustement)
			local texte = UiKit.exigence(e, Catalogue)
			if e.type == "qualite" and ajustement and ajustement < 1 then
				texte ..= (" (ajustement %d %%)"):format(math.floor(ajustement * 100 + 0.5))
			end
			lignesExigences[i].Text = SYMBOLES[statut] .. "  " .. texte
			lignesExigences[i].TextColor3 = COULEURS_STATUT[statut]
		end
	end

	-- « Tracer le patron » : un modèle fermé ne se trace pas (on dit ce qu'il faut pour l'ouvrir)
	UiKit.bouton({ Name = "Valider", Text = "Tracer le patron", Position = UDim2.fromOffset(296, 428), Size = UDim2.fromOffset(230, 34), Parent = page }, function()
		for _, famille in ipairs(ORDRE_LIGNES) do
			if not Deblocages.ouvert(etat, "variantes", croquis[famille]) then
				ctx.message(Deblocages.message("variantes", croquis[famille]), C.texteDoux)
				return
			end
		end
		local pieces = Patron.piecesDuCroquis(croquis)
		local choixPieces = {}
		for _, id in ipairs(pieces) do
			choixPieces[id] = tissus[id]
		end
		local r = session:validerCroquis(croquis, choixPieces)
		if not r.ok then
			ctx.refus(r)
		end
	end)

	rafraichir()
	-- L'état peut changer sans action du carnet (réparé par le serveur) : argent et stock suivent
	local desabonner = session:surChangement(function(e)
		if e.etape == "carnet" then
			rafraichir()
		end
	end)
	return function()
		desabonner()
		fermerChoix()
	end
end
```

- [ ] **Step 4: Lancer les tests**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT"`
Expected:
```
Unitaires : 167730 vérifications
TOUT EST VERT : 787 vérifications
```

- [ ] **Step 5: Commit**

```bash
git add src/client/Atelier/EcranCarnet.luau tests/scenario.luau
git commit -m "Carnet : une page de croquis, la robe dessinée et coloriée, les modèles par ◀ ▶, les échantillons épinglés

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 4: Studio, README, lieu régénéré

**Files:**
- Modify: `README.md`, `AtelierCouture.rbxl` (régénéré)

**Interfaces:**
- Consumes: tout ce qui précède.
- Produces: rien de nouveau.

- [ ] **Step 1: Dans Studio, par le connecteur MCP**

Construire le lieu du dépôt dans un dossier temporaire (`C:/dev/jeux/roblox-maker/rojo.exe build -o <dossier temporaire>/Plan11Depot.rbxl`) et l'ouvrir dans Studio. En Play : attendre 4 s, appuyer sur E, régler les rubans aux vraies mesures de la cliente et valider ; au carnet, capturer l'écran (`screen_capture`) ; cliquer sur ▶ de la ligne « Jupe » puis sur la jupe dessinée (souris à la position absolue du dessin, à 50 % de sa largeur et 70/130 de sa hauteur) ; choisir un tissu ; capturer l'écran ; relever la console.

Expected : la page de carnet (papier, dessin de la robe au trait, lignes ◀ ▶ avec leurs points, liste des pièces, « Environ X m de tissu », « Tracer le patron », fiche à droite) ; ▶ change la jupe dessinée ; toucher la jupe ouvre le choix de son tissu ; le tissu choisi colorie la jupe et son échantillon est épinglé en haut de la page ; aucune alerte de notre code (« Lieu non publié » et les messages internes de Roblox mis à part). Arrêter Play et fermer cette fenêtre de Studio (sans enregistrer).

- [ ] **Step 2: Mettre à jour le README**

Dans `README.md`, remplacer :

```markdown
`docs/superpowers/specs/2026-09-30-ampleur-contenu-design.md` pour l'ampleur du catalogue et du quartier ; plans :
`docs/superpowers/plans/`).

## État actuel (sous-projet 4 terminé côté code, plans 8a à 9 : l'ampleur du catalogue et du quartier)
```

par :

```markdown
`docs/superpowers/specs/2026-09-30-ampleur-contenu-design.md` pour l'ampleur du catalogue et du quartier,
`docs/superpowers/specs/2026-09-30-fidelite-dressmaker-design.md` pour la fidélité à la présentation de
*Dressmaker* ; plans : `docs/superpowers/plans/`).

## État actuel (sous-projet 5 en cours, plan 11 : le carnet de croquis dessiné)
```

Dans `README.md`, remplacer :

```markdown
2. **Carnet de croquis** : corsage, manches, col et jupe au choix (19 variantes : cinq corsages dont le
   cache-cœur et le bustier, cinq manches, quatre cols dont le col marin, cinq jupes dont la jupe crayon) ; un
   tissu par pièce (41 tissus en onze matières, filtre par style, dont la toile de jute, gratuite).
   Les jauges de style, l'état des exigences, le métrage et le coût du tissu à acheter se mettent à jour en
   direct (la plage d'une jauge ne compte que les tissus ouverts). Ce qui n'est pas encore ouvert est grisé, avec ce qu'il faut pour l'ouvrir (« Prestige 3 »,
   « Amitié d'Hélène : 2 ») ; le serveur le refuse aussi.
```

par :

```markdown
2. **Carnet de croquis** : une page de carnet (papier, notes de tailleur, crayon). Au centre, la robe dessinée
   au trait, de face, sur un mannequin esquissé : elle change avec chaque modèle et se colorie du motif de chaque
   tissu choisi ; toucher une partie du dessin ouvre le choix de son tissu. Dessous, une ligne par famille
   (corsage, col, manches, jupe) : ◀ le nom du modèle ▶ et un point par modèle (19 variantes : cinq corsages dont
   le cache-cœur et le bustier, cinq manches, quatre cols dont le col marin, cinq jupes dont la jupe crayon).
   À côté du dessin, un tissu par pièce (41 tissus en onze matières, filtre par style, dont la toile de jute,
   gratuite) ; les échantillons des tissus choisis sont épinglés en haut de la page ; « Environ X m de tissu » ;
   « Tracer le patron ». La fiche de la commande, à droite : jauges de style, état des exigences, coût du tissu
   à acheter, à jour en direct (la plage d'une jauge ne compte que les tissus ouverts). Un modèle pas encore
   ouvert est grisé, avec ce qu'il faut pour l'ouvrir (« Prestige 3 », « Amitié d'Hélène : 2 ») ; son patron
   ne se trace pas, et le serveur le refuse aussi.
```

Dans `README.md`, remplacer :

```markdown
10. La suite : sous-projet 5 (porter la robe sur son avatar, défilés entre joueurs), à décider.
```

par :

```markdown
10. La suite : la fin du sous-projet 5 (paroles des clientes dans un encadré, avis en étoiles, réputation,
   confettis, gazette du quartier, affiche des nouveautés, chat de l'atelier) ; porter la robe sur son avatar et
   les défilés entre joueurs restent à décider.
```

Dans `README.md`, remplacer :

```markdown
  | `Pixels` | Motifs de tissu, découpe exacte de l'image d'une pièce, silhouette du patron |
```

par :

```markdown
  | `Croquis`, `Pixels` | Dessin de face de chaque modèle (formes des parties, plis, mannequin) ; motifs de tissu, découpe exacte de l'image d'une pièce, silhouette du patron, croquis colorié du carnet |
```

- [ ] **Step 3: Tests, lieu régénéré, commit**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT"`
Expected:
```
Unitaires : 167730 vérifications
TOUT EST VERT : 787 vérifications
```

```bash
C:/dev/jeux/roblox-maker/rojo.exe build -o AtelierCouture.rbxl
git add README.md AtelierCouture.rbxl
git commit -m "Plan 11 terminé : le carnet de croquis dessiné

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```
