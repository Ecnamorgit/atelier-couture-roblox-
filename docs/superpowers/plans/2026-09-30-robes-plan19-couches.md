# Aiguille & Dentelle — Plan 19 : des robes à couches (volant, basque)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Des robes plus riches, comme dans *Dressmaker* : des couches posées par-dessus la robe (un volant froncé sous la jupe, une basque sous la taille), chacune avec ses pièces, son tissu et sa partie du dessin, sans changer les quatre lignes du carnet.

**Architecture:** l'enroulement « jupe » de `Patron` gagne `depart` (dm sous la taille), `couche` (écart de 0,2 dm par couche) et `ampleur` (évasement depuis le haut de la pièce) ; `Maillage` accepte une grille propre à la pièce. `Catalogue` ajoute quatre pièces (volant et basque, devant et dos, de poids 0,5) et deux variantes (jupe à volant, corsage à basque, ouvertes aux prestiges 4 et 5) sans toucher aux variantes d'avant. `Notation.poids` pèse les pièces dans la paie. Une partie du croquis peut porter ses pièces : elle prend leur tissu, et la toucher ne choisit que le leur ; la liste des pièces du carnet défile.

**Tech Stack:** Luau, Rojo 7.7.0-rc.1, simulation Luau 0.650 (`tests/lancer.sh`), Roblox Studio via le connecteur MCP Studio.

**Spec:** `docs/superpowers/specs/2026-09-30-robes-gouts-design.md` (section 2 ; plan 19 de la section 6).

## Décisions de ce plan

- **Couches** : chaque couche écarte la pièce de 0,2 dm (0,06 d'air, plus les fronces du dessous, 0,14 dm au plus) ; un test vérifie, pour toutes les tailles et silhouettes extrêmes, que la couche du dessus passe au moins 0,03 dm au-dessus de celle du dessous partout où elles se recouvrent : le volant sur la jupe droite, la basque sur toutes les jupes. Un autre vérifie que chaque paire de couches d'un croquis possible est de celles-là.
- **Volant** : bande de 9 × 1,6 dm (sa longueur fait le tour, froncée), cousue par le haut (comme un col), coupée à 0° (droit-fil parfait : le fil suit la hauteur du patron) ; il part à 5 dm sous la taille, par-dessus la jupe droite, et descend 0,6 dm sous son ourlet ; grille 32 × 3 (16 × 2 en vitrine) pour suivre les fronces.
- **Basque** : trapèze de 4,8 à 6,4 dm sur 1,2 dm, cousue par le haut, en couche 1 depuis la taille.
- **Variantes** : `jupe_volant` (jupe droite + volant) et `corsage_basque` (corsage droit + basque) ; les pièces d'une variante d'avant ne changent jamais (les recettes des vitrines et des sauvegardes restent valides) ; une robe a 10 pièces et 12 copies au plus (plafond de la spec : 12 et 16).
- **Paie** : `Notation.base(poids, …)` compte le poids des pièces (volant et basque : 0,5) ; le prix de vente d'une robe libre et sa main d'œuvre aussi. Les robes d'avant gardent leur paie (poids 1).
- **Déblocages** : jupe à volant au prestige 4, corsage à basque au prestige 5 (les annonces des niveaux 3 et 6, que le scénario vérifie, ne changent pas) ; l'équilibrage reste dans ses cibles (tout s'ouvre vers la 126e robe au lieu de la 123e).
- **Arrondi** : `1,6 × 3 / 3` donne un peu plus que 1,6 ; la dernière ligne d'un maillage est posée exactement sur le bord (sinon le volant perdait un tiers de ses triangles), et deux tests existants (mannequin, jambes) ne sortent plus de la pièce.
- **Vérifié pendant la préparation** : le plan a été joué entièrement sur un brouillon tiré de `main` ; quatorze variantes du brouillon échouent chacune sur la vérification qui les garde ; la robe (corsage à basque, manches ballon, col Claudine, jupe à volant) a été construite dans Studio : la basque s'évase sous la taille, le volant froncé par-dessus l'ourlet, sans traverser la jupe ; 883 ms pour 12 copies et le mannequin, sur PC.

## Global Constraints

- **Dépôt** : `C:\dev\jeux\atelier-couture`, branche `couches`, créée depuis `main` (où le sous-projet 6 est fusionné). Selon les règles du commanditaire : la branche testée et relue est fusionnée dans `main` et poussée sur GitHub.
- **Rojo** : `C:/dev/jeux/roblox-maker/rojo.exe`.
- **Contenu original** : aucun nom, texte, image ni son de *Dressmaker*.
- **Équilibrage** : les cibles de `48_equilibrage` doivent tenir.
- **Contraintes des plans précédents toujours valables** : fins de ligne LF, commits en français terminés par `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`, textes d'au moins 14 px (et aucun texte laissé à « Label »), le serveur fait foi.

## Review Focus

- **Une silhouette extrême (hanches 14, taille 5,5) avec une jupe ample sous une basque.** Attendu : la basque passe au-dessus des fronces. Test : `67_couches` (toutes les silhouettes).
- **Une recette d'avant (vitrine, sauvegarde).** Attendu : toujours valide. Test : `68_variantes_couches` (« les variantes d'avant gardent leurs pièces »).
- **Toucher le volant dans le dessin.** Attendu : le choix du tissu des seuls volants ; le dessin se colorie de ce tissu. Test : scénario.
- **Une robe à dix pièces au carnet.** Attendu : la liste des pièces défile sans passer sur les lignes ◀ ▶. Test : scénario.
- **La paie d'une robe à volant.** Attendu : le poids (6 pour corsage à basque et jupe à volant), pas le nombre de pièces (8). Test : `68_variantes_couches`.

---

### Task 1: Les couches (`Patron`, `Maillage`, `Catalogue`)

**Files:**
- Modify: `src/shared/Patron.luau`, `src/shared/Maillage.luau`, `src/shared/Catalogue.luau`
- Create: `tests/unitaires/67_couches.luau`
- Modify: `tests/unitaires/10_mannequin.luau`, `tests/unitaires/03_patron.luau`

**Interfaces:**
- Consumes: `Patron.point`, `Maillage.piece`, `Catalogue.piece` (existants).
- Produces: `Patron.ELLIPSE = { x, z }`, `Patron.ECART_COUCHE` (0,2) ; l'enroulement « jupe » lit `depart`, `couche`, `ampleur` ; les pièces `volant_devant`, `volant_dos`, `basque_devant`, `basque_dos` (champs `poids` et `grille`) ; `Maillage.piece` lit `def.grille[finesse]`.

- [ ] **Step 1: Écrire les tests**

Créer `tests/unitaires/67_couches.luau` :

```lua
-- Sous-projet 7 : des couches. Une pièce de jupe peut partir plus bas que la taille (depart), se poser par-dessus
-- d'autres (couche) et s'évaser depuis son propre haut (ampleur) : le volant, la basque. Une couche ne traverse jamais
-- celle du dessous : partout où deux pièces du même côté sont à la même hauteur, celle du dessus est plus loin du corps
-- d'au moins 0,03 dm.
local Catalogue = U.module("Catalogue")
local Patron = U.module("Patron")
local Polygone = U.module("Polygone")
local Maillage = U.module("Maillage")
local Recette = U.module("Recette")

-- Point (u, v) d'une pièce (u d'un bord à l'autre de la ligne, v du haut au bas), et son rayon (dm, dans l'ellipse)
local function point(id, u, v, mesures)
	local b = Polygone.boite(Catalogue.piece(id).contour)
	local y = b.minY + v * (b.maxY - b.minY)
	local x0, x1 = Polygone.etendueLigne(Catalogue.piece(id).contour, y)
	return Patron.point(id, "unique", x0 + u * (x1 - x0), y, mesures)
end
local function rayon(p)
	return math.sqrt((p.X / Patron.ELLIPSE.x) ^ 2 + (p.Z / Patron.ELLIPSE.z) ^ 2)
end
local function hauteur(id)
	local b = Polygone.boite(Catalogue.piece(id).contour)
	return b.maxY - b.minY
end

-- Tailles du catalogue et silhouettes extrêmes qu'accepte une recette
local tailles = table.clone(Catalogue.TAILLES)
for _, P in ipairs(Recette.POITRINE) do
	for _, T in ipairs(Recette.TAILLE) do
		for _, H in ipairs(Recette.HANCHES) do
			if T <= P and T <= H then
				tailles[("P%g-T%g-H%g"):format(P, T, H)] = { poitrine = P, taille = T, hanches = H }
			end
		end
	end
end

-- Le plus petit écart (dm de rayon) entre « dessus » et « dessous » là où ils sont à la même hauteur (nil : jamais)
local function ecartMin(dessus, dessous, mesures)
	local eD, eS = Catalogue.piece(dessus).enroulement, Catalogue.piece(dessous).enroulement
	local hD, hS = hauteur(dessus), hauteur(dessous)
	local pire
	for j = 0, 16 do
		local yd = (eD.depart or 0) + hD * j / 16
		local vS = (yd - (eS.depart or 0)) / hS
		if vS >= 0 and vS <= 1 then
			for i = 0, 32 do
				local e = rayon(point(dessus, i / 32, j / 16, mesures)) - rayon(point(dessous, i / 32, vS, mesures))
				pire = if pire then math.min(pire, e) else e
			end
		end
	end
	return pire
end

---------------------------------------------------------------------------
-- Un volant part plus bas que la taille, et descend plus bas que sa jupe
---------------------------------------------------------------------------
local M = Catalogue.TAILLES.M
local haut, bas = point("volant_devant", 0.5, 0, M), point("volant_devant", 0.5, 1, M)
U.verifier(math.abs(haut.Y + 5) < 1e-9 and math.abs(bas.Y + 6.6) < 1e-9, ("le volant part à 5 dm sous la taille, jusqu'à 6,6 dm (%.2f, %.2f)"):format(-haut.Y, -bas.Y))
U.verifier(rayon(bas) > rayon(haut) + 0.3, "le volant s'évase depuis son haut")

---------------------------------------------------------------------------
-- Une couche ne traverse pas celle du dessous : le volant sur la jupe droite, la basque sur toutes les jupes
---------------------------------------------------------------------------
local paires = { { "volant_devant", "jupe_droite_devant" }, { "volant_dos", "jupe_droite_dos" } }
for id, def in pairs(Catalogue.Pieces) do
	if def.enroulement.type == "jupe" and not def.enroulement.couche then
		table.insert(paires, { "basque_" .. def.enroulement.cote, id })
	end
end
table.sort(paires, function(a, b)
	return a[1] .. a[2] < b[1] .. b[2]
end)
local recouvertes, ratees = 0, {}
for _, paire in ipairs(paires) do
	for nom, mesures in pairs(tailles) do
		local e = ecartMin(paire[1], paire[2], mesures)
		if e then
			recouvertes += 1
			if e < 0.03 then
				table.insert(ratees, ("%s sur %s (%s) : %.3f"):format(paire[1], paire[2], nom, e))
			end
		end
	end
end
U.verifier(recouvertes >= #paires and #ratees == 0, ("chaque couche passe au moins 0,03 dm au-dessus de celle du dessous (%d cas ; en défaut : %s)"):format(recouvertes, table.concat(ratees, " ; ")))

---------------------------------------------------------------------------
-- Une grille propre à la pièce : le volant, froncé serré, en 32 × 3 (16 × 2 en vitrine)
---------------------------------------------------------------------------
local maillage = Maillage.piece("volant_devant", "unique", M, "robe")
local vitrine = Maillage.piece("volant_devant", "unique", M, "vitrine")
local jupe = Maillage.piece("jupe_droite_devant", "unique", M, "robe")
U.verifier(#maillage.positions == 33 * 4 and #vitrine.positions == 17 * 3 and #jupe.positions == 13 * 17, ("grille du volant : 33 × 4 points (vitrine 17 × 3) ; la jupe garde 13 × 17 (%d, %d, %d)"):format(#maillage.positions, #vitrine.positions, #jupe.positions))
U.verifier(not pcall(Maillage.piece, "volant_devant", "unique", M, "inconnue"), "une finesse inconnue est refusée")

---------------------------------------------------------------------------
-- Les petites pièces ajoutées pèsent moitié ; les autres, un
---------------------------------------------------------------------------
U.verifier(Catalogue.piece("volant_devant").poids == 0.5 and Catalogue.piece("basque_dos").poids == 0.5 and Catalogue.piece("jupe_droite_devant").poids == nil, "volant et basque : poids 0,5 ; les autres pièces, sans poids (1)")
```

Dans `tests/unitaires/10_mannequin.luau`, remplacer :

```lua
			for j = 0, 12 do
				local y = b.minY + (b.maxY - b.minY) * j / 12
```

par :

```lua
			for j = 0, 12 do
				local y = math.min(b.minY + (b.maxY - b.minY) * j / 12, b.maxY) -- (l'arrondi ne sort pas de la pièce)
```

Dans `tests/unitaires/03_patron.luau`, remplacer :

```lua
			for k = 0, 20 do
				local y = b.minY + (b.maxY - b.minY) * k / 20
```

par :

```lua
			for k = 0, 20 do
				local y = math.min(b.minY + (b.maxY - b.minY) * k / 20, b.maxY) -- (l'arrondi ne sort pas de la pièce)
```

- [ ] **Step 2: Lancer les tests, vérifier l'échec**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT|attempt|membre" | head -3`
Expected: échec : une ligne qui finit par `attempt to index nil with 'contour'`

- [ ] **Step 3: Les couches**

Dans `src/shared/Patron.luau`, remplacer :

```lua
local HAUTEUR_COU, RAYON_COU = 4.3, 0.62
local INCLINAISON_BRAS = math.rad(12)
```

par :

```lua
local HAUTEUR_COU, RAYON_COU = 4.3, 0.62
local INCLINAISON_BRAS = math.rad(12)
Patron.ELLIPSE = { x = EX, z = EZ }
-- Sous-projet 7 : écart de rayon par couche (0,06 dm d'air, plus les fronces du dessous, 0,14 dm au plus)
Patron.ECART_COUCHE = 0.2
```

Dans `src/shared/Patron.luau`, remplacer :

```lua
local function jupe(e, u, v, hauteur, m)
	local yd = v * hauteur
	local rT = m.taille / (2 * math.pi) + 0.12
	local rH = m.hanches / (2 * math.pi) + 0.15
	local phi = angleCote(e.cote, u)
	local r = rT + (rH - rT) * lisse(yd / LIGNE_HANCHES) + e.evasement * math.max(0, yd - LIGNE_HANCHES)
```

par :

```lua
-- Jupe : de la taille vers le bas. Sous-projet 7 : une pièce peut partir plus bas (depart, dm sous la taille), se
-- poser par-dessus d'autres (couche : chaque couche l'écarte de ECART_COUCHE) et s'évaser depuis son propre haut
-- (ampleur, dm de rayon par dm de hauteur) : un volant, une basque
local function jupe(e, u, v, hauteur, m)
	local yd = (e.depart or 0) + v * hauteur
	local rT = m.taille / (2 * math.pi) + 0.12
	local rH = m.hanches / (2 * math.pi) + 0.15
	local phi = angleCote(e.cote, u)
	local r = rT + (rH - rT) * lisse(yd / LIGNE_HANCHES) + e.evasement * math.max(0, yd - LIGNE_HANCHES)
		+ (e.ampleur or 0) * v * hauteur + (e.couche or 0) * Patron.ECART_COUCHE
```

Dans `src/shared/Maillage.luau`, remplacer :

```lua
-- uv : coordonnées dans la boîte du patron (0,0 en haut à gauche), comme l'image de Pixels.imagePiece.
function Maillage.piece(idPiece, copie, mesures, finesse)
	local def = Catalogue.piece(idPiece)
	assert(def, "pièce inconnue : " .. tostring(idPiece))
	local grille = Maillage.FINESSES[finesse or "robe"]
	assert(grille, "finesse inconnue : " .. tostring(finesse))
```

par :

```lua
-- uv : coordonnées dans la boîte du patron (0,0 en haut à gauche), comme l'image de Pixels.imagePiece.
-- Une pièce peut avoir sa propre grille par finesse (sous-projet 7 : un volant, long et bas, froncé serré).
function Maillage.piece(idPiece, copie, mesures, finesse)
	local def = Catalogue.piece(idPiece)
	assert(def, "pièce inconnue : " .. tostring(idPiece))
	assert(Maillage.FINESSES[finesse or "robe"], "finesse inconnue : " .. tostring(finesse))
	local grille = def.grille and def.grille[finesse or "robe"] or Maillage.FINESSES[finesse or "robe"]
```

Dans `src/shared/Catalogue.luau`, remplacer :

```lua
-- pliee : coupée dans le tissu plié → deux copies miroir (gauche, droite)
-- biais : prévue pour être coupée à 45°
```

par :

```lua
-- pliee : coupée dans le tissu plié → deux copies miroir (gauche, droite)
-- biais : prévue pour être coupée à 45°
-- Sous-projet 7 : poids (dans la paie, 1 par défaut ; 0,5 pour une petite pièce ajoutée : volant, basque), grille
-- (quadrillage propre à la pièce, par finesse : voir Maillage)
```

Dans `src/shared/Catalogue.luau`, remplacer :

```lua
local CRAYON = { { x = 0, y = 0 }, { x = 5, y = 0 }, { x = 4.6, y = 6 }, { x = 0.4, y = 6 } }
```

par :

```lua
local CRAYON = { { x = 0, y = 0 }, { x = 5, y = 0 }, { x = 4.6, y = 6 }, { x = 0.4, y = 6 } }
-- Sous-projet 7 : la basque, courte et évasée, sous la taille, par-dessus la jupe
local BASQUE = { { x = 0.8, y = 0 }, { x = 5.6, y = 0 }, { x = 6.4, y = 1.2 }, { x = 0, y = 1.2 } }
-- Un volant froncé : une bande longue (sa longueur fait le tour, froncée) et basse, cousue par le haut
local GRILLE_VOLANT = { robe = { colonnes = 32, lignes = 3 }, vitrine = { colonnes = 16, lignes = 2 } }
local GRILLE_BASQUE = { robe = { colonnes = 12, lignes = 4 }, vitrine = { colonnes = 6, lignes = 2 } }
```

Dans `src/shared/Catalogue.luau`, remplacer :

```lua
	jupe_crayon_dos = { nom = "Jupe crayon dos", contour = CRAYON, coutures = { 1, 2, 4 },
		enroulement = { type = "jupe", cote = "dos", evasement = -0.04, fronces = 0 } },
}
```

par :

```lua
	jupe_crayon_dos = { nom = "Jupe crayon dos", contour = CRAYON, coutures = { 1, 2, 4 },
		enroulement = { type = "jupe", cote = "dos", evasement = -0.04, fronces = 0 } },
	-- Sous-projet 7 : des couches. Le volant, cousu d'un bord (le haut), part à 5 dm sous la taille, par-dessus la jupe
	-- droite, et descend 0,6 dm plus bas qu'elle ; la basque, par-dessus la jupe, s'évase depuis la taille
	volant_devant = { nom = "Volant devant", contour = rectangle(9, 1.6), coutures = { 1 }, poids = 0.5, grille = GRILLE_VOLANT,
		enroulement = { type = "jupe", cote = "devant", depart = 5, couche = 1, evasement = 0.03, ampleur = 0.3, fronces = 0.35 } },
	volant_dos = { nom = "Volant dos", contour = rectangle(9, 1.6), coutures = { 1 }, poids = 0.5, grille = GRILLE_VOLANT,
		enroulement = { type = "jupe", cote = "dos", depart = 5, couche = 1, evasement = 0.03, ampleur = 0.3, fronces = 0.35 } },
	basque_devant = { nom = "Basque devant", contour = BASQUE, coutures = { 1 }, poids = 0.5, grille = GRILLE_BASQUE,
		enroulement = { type = "jupe", cote = "devant", depart = 0, couche = 1, evasement = 0, ampleur = 0.35, fronces = 0 } },
	basque_dos = { nom = "Basque dos", contour = BASQUE, coutures = { 1 }, poids = 0.5, grille = GRILLE_BASQUE,
		enroulement = { type = "jupe", cote = "dos", depart = 0, couche = 1, evasement = 0, ampleur = 0.35, fronces = 0 } },
}
```

Dans `src/shared/Maillage.luau`, remplacer :

```lua
	for j = 0, grille.lignes do
		local y = b.minY + h * j / grille.lignes
```

par :

```lua
	for j = 0, grille.lignes do
		-- (la dernière ligne exactement sur le bord : 1,6 × 3 / 3 donne un peu plus que 1,6, hors de la pièce)
		local y = if j == grille.lignes then b.maxY else b.minY + h * j / grille.lignes
```

- [ ] **Step 4: Lancer les tests**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT"`
Expected:
```
Unitaires : 184590 vérifications
TOUT EST VERT : 975 vérifications
```

- [ ] **Step 5: Commit**

```bash
git add src/shared/Patron.luau src/shared/Maillage.luau src/shared/Catalogue.luau tests/unitaires/67_couches.luau tests/unitaires/10_mannequin.luau tests/unitaires/03_patron.luau
git commit -m "Des couches : une pièce de jupe peut partir plus bas, se poser par-dessus et s'évaser depuis son haut ; le volant et la basque

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 2: La jupe à volant et le corsage à basque

**Files:**
- Modify: `src/shared/Catalogue.luau`, `src/shared/Deblocages.luau`, `src/shared/Notation.luau`, `src/shared/EtatAtelier.luau`, `src/shared/Croquis.luau`, `src/shared/Pixels.luau`
- Create: `tests/unitaires/68_variantes_couches.luau`
- Modify: `tests/unitaires/02_catalogue.luau`, `tests/unitaires/15_metrage.luau`, `tests/unitaires/56_croquis.luau`

**Interfaces:**
- Consumes: les pièces de la tâche 1.
- Produces: les variantes `jupe_volant`, `corsage_basque` ; `Notation.poids(pieces) -> nombre` (identifiants ou pièces d'une recette) ; `Notation.base(poids, nbExigences)` ; une partie de `Croquis.parties` peut avoir `pieces` ; `Croquis.partieA(croquis, x, y) -> famille, pieces` ; `Pixels.croquis` lit `tissus[idPiece]` pour une telle partie.

- [ ] **Step 1: Écrire les tests**

Créer `tests/unitaires/68_variantes_couches.luau` :

```lua
-- Sous-projet 7 : la jupe à volant et le corsage à basque. Les variantes d'avant ne changent pas de pièces (les
-- recettes gardées restent valides) ; une robe a 12 pièces et 16 copies au plus ; le dessin colorie le volant de son
-- tissu ; la paie compte le poids des pièces ; une robe à volant se fait de bout en bout.
local Catalogue = U.module("Catalogue")
local Patron = U.module("Patron")
local Croquis = U.module("Croquis")
local Pixels = U.module("Pixels")
local Notation = U.module("Notation")
local Metrage = U.module("Metrage")
local Deblocages = U.module("Deblocages")
local EtatAtelier = U.module("EtatAtelier")
local Clientes = U.module("Clientes")

---------------------------------------------------------------------------
-- Les variantes d'avant gardent leurs pièces
---------------------------------------------------------------------------
local AVANT = {
	corsage_droit = { "corsage_droit_devant", "corsage_droit_dos" },
	corsage_v = { "corsage_v_devant", "corsage_droit_dos" },
	corsage_bretelles = { "corsage_bretelles_devant", "corsage_bretelles_dos" },
	corsage_cache_coeur = { "corsage_cache_coeur_devant", "corsage_droit_dos" },
	corsage_bustier = { "corsage_bustier_devant", "corsage_bustier_dos" },
	manches_sans = {},
	manches_ballon = { "manche_ballon" },
	manches_longues = { "manche_longue" },
	manches_courtes = { "manche_courte" },
	manches_trois_quarts = { "manche_trois_quarts" },
	col_sans = {},
	col_claudine = { "col_claudine" },
	col_montant = { "col_montant" },
	col_marin = { "col_marin" },
	jupe_droite = { "jupe_droite_devant", "jupe_droite_dos" },
	jupe_trapeze = { "jupe_trapeze_devant", "jupe_trapeze_dos" },
	jupe_ample = { "jupe_ample_devant", "jupe_ample_dos" },
	jupe_evasee = { "jupe_evasee_devant", "jupe_evasee_dos" },
	jupe_crayon = { "jupe_crayon_devant", "jupe_crayon_dos" },
}
local changees = {}
for id, pieces in pairs(AVANT) do
	local v = Catalogue.variante(id)
	if not v or table.concat(v.pieces, ",") ~= table.concat(pieces, ",") then
		table.insert(changees, id)
	end
end
table.sort(changees)
U.verifier(#changees == 0, "les variantes d'avant gardent leurs pièces (changées : " .. table.concat(changees, ", ") .. ")")
U.verifier(Catalogue.variante("jupe_volant").famille == "jupe" and Catalogue.variante("corsage_basque").famille == "corsage", "deux nouvelles variantes : la jupe à volant, le corsage à basque")

---------------------------------------------------------------------------
-- 12 pièces et 16 copies au plus ; chaque paire de couches d'un croquis est de celles que 67_couches vérifie
---------------------------------------------------------------------------
local listes = {}
for _, famille in ipairs(Catalogue.FAMILLES) do
	listes[famille] = Catalogue.variantesDe(famille)
end
local maxPieces, maxCopies, inconnues = 0, 0, {}
for _, co in ipairs(listes.corsage) do
	for _, ma in ipairs(listes.manches) do
		for _, cl in ipairs(listes.col) do
			for _, ju in ipairs(listes.jupe) do
				local pieces = Patron.piecesDuCroquis({ corsage = co.id, manches = ma.id, col = cl.id, jupe = ju.id })
				local copies = 0
				for _, id in ipairs(pieces) do
					copies += #Patron.copies(id)
				end
				maxPieces, maxCopies = math.max(maxPieces, #pieces), math.max(maxCopies, copies)
				for _, dessus in ipairs(pieces) do
					local eD = Catalogue.piece(dessus).enroulement
					for _, dessous in ipairs(pieces) do
						local eS = Catalogue.piece(dessous).enroulement
						if eD.type == "jupe" and eS.type == "jupe" and eD.cote == eS.cote and (eD.couche or 0) > (eS.couche or 0) then
							local verifiee = (dessus:match("^basque_") and not eS.couche) or (dessus:match("^volant_") and dessous:match("^jupe_droite_"))
							if not verifiee then
								inconnues[dessus .. " sur " .. dessous] = true
							end
						end
					end
				end
			end
		end
	end
end
local noms = {}
for n in pairs(inconnues) do
	table.insert(noms, n)
end
U.verifier(maxPieces <= 12 and maxCopies <= 16, ("une robe : 12 pièces et 16 copies au plus (%d, %d)"):format(maxPieces, maxCopies))
U.verifier(#noms == 0, "chaque couche d'un croquis est vérifiée par 67_couches (non vérifiées : " .. table.concat(noms, ", ") .. ")")

---------------------------------------------------------------------------
-- Le dessin : le volant a sa partie, son tissu, et le toucher choisit le tissu des volants
---------------------------------------------------------------------------
local AVEC_VOLANT = { corsage = "corsage_basque", manches = "manches_sans", col = "col_sans", jupe = "jupe_volant" }
local volant
for _, p in ipairs(Croquis.parties(AVEC_VOLANT)) do
	if p.pieces and p.pieces[1] == "volant_devant" then
		volant = p
	end
end
U.verifier(volant ~= nil and volant.famille == "jupe" and #volant.pieces == 2, "le volant est une partie du dessin, qui porte ses pièces")
local fam, pieces = Croquis.partieA(AVEC_VOLANT, 50, 83)
local famJupe, piecesJupe = Croquis.partieA(AVEC_VOLANT, 50, 60)
local famBasque, piecesBasque = Croquis.partieA(AVEC_VOLANT, 50, 47)
U.verifier(fam == "jupe" and table.concat(pieces, ",") == "volant_devant,volant_dos", "toucher le volant : ses deux pièces")
U.verifier(famJupe == "jupe" and table.concat(piecesJupe, ",") == "jupe_droite_devant,jupe_droite_dos,volant_devant,volant_dos", "toucher la jupe : toutes les pièces de la variante")
U.verifier(famBasque == "corsage" and table.concat(piecesBasque, ",") == "basque_devant,basque_dos", "toucher la basque : ses deux pièces")
local function pixel(buf, largeur, x, y)
	return buffer.readu32(buf, (y * largeur + x) * 4)
end
local memes = Pixels.croquis(AVEC_VOLANT, { jupe = "coton_blanc", volant_devant = "coton_blanc" }, 100, 130)
local autre = Pixels.croquis(AVEC_VOLANT, { jupe = "coton_blanc", volant_devant = "velours_noir" }, 100, 130)
U.verifier(pixel(memes, 100, 52, 81) == pixel(memes, 100, 50, 60) and pixel(autre, 100, 52, 81) ~= pixel(autre, 100, 50, 60) and pixel(autre, 100, 50, 60) == pixel(memes, 100, 50, 60), "le volant prend le tissu de ses pièces, la jupe garde le sien")

---------------------------------------------------------------------------
-- La paie compte le poids des pièces ; les robes d'avant gardent la leur
---------------------------------------------------------------------------
U.verifier(Notation.poids({ "jupe_droite_devant", "jupe_droite_dos" }) == 2 and Notation.poids(Patron.piecesDuCroquis(AVEC_VOLANT)) == 6, "poids : 2 pour une jupe droite ; 6 pour corsage à basque et jupe à volant (4 pièces et 4 demi-pièces)")
U.verifier(Notation.poids({ { id = "volant_dos" } }) == 0.5, "le poids se lit aussi sur les pièces d'une recette")
U.verifier(Notation.base(2, 1) == 20 + 20 + 15, "Notation.base : 20 + 10 par poids + 15 par exigence")

---------------------------------------------------------------------------
-- Ouvertes au prestige 4 (jupe à volant) et 5 (corsage à basque)
---------------------------------------------------------------------------
local e = EtatAtelier.nouveau()
e.prestige = 49 -- niveau 3
U.verifier(not Deblocages.ouvert(e, "variantes", "jupe_volant") and Deblocages.raison("variantes", "jupe_volant") == "Prestige 4", "la jupe à volant s'ouvre au prestige 4")
U.verifier(Deblocages.raison("variantes", "corsage_basque") == "Prestige 5", "le corsage à basque, au prestige 5")

---------------------------------------------------------------------------
-- Une robe à volant et à basque, de bout en bout : coupée, épinglée, cousue, livrée, payée selon son poids
---------------------------------------------------------------------------
local r = EtatAtelier.nouveau(1000)
U.commander(r, Random.new(3))
local ids = Patron.piecesDuCroquis(AVEC_VOLANT)
local tissus = {}
for _, id in ipairs(ids) do
	tissus[id] = "coton_blanc"
end
assert(r:validerCroquis(AVEC_VOLANT, tissus).ok)
local placements, longueur = Metrage.disposition(ids)
assert(r:acheter("coton_blanc", longueur).ok and r:commencerDecoupe().ok)
for _, id in ipairs(ids) do
	local c = r:couper(id, placements[id])
	assert(c.ok, id .. " : " .. tostring(c.erreur))
end
for _, id in ipairs(ids) do
	assert(r:epingler(id).ok, id)
end
for _, id in ipairs(ids) do
	local _, l = Patron.trajetCouture(id)
	assert(r:rendreCouture(id, table.create(math.round(l / 0.1), 0.02), l).ok, id)
end
assert(r:decorer({}).ok)
r.commande.exigences = { { type = "qualite", valeur = 0.1 } }
local acompte, bilan = r.commande.acompte, r:bilan()
local l = r:livrer()
U.verifier(l.ok and l.reussie and l.paie == Notation.paie(6, 1, bilan.qualite) and l.verse == l.paie - acompte, ("robe à volant et à basque livrée : payée pour un poids de 6 (%s po)"):format(tostring(l.paie)))
U.verifier(Clientes ~= nil, "(modules chargés)")
```

Dans `tests/unitaires/02_catalogue.luau`, remplacer :

```lua
-- Chaque robe possible compte 4 à 6 pièces à poser
```

par :

```lua
-- Chaque robe possible compte 4 à 10 pièces à poser (sous-projet 7 : le corsage à basque et la jupe à volant en ont quatre)
```

Dans `tests/unitaires/02_catalogue.luau`, remplacer :

```lua
U.verifier(minimum == 4 and maximum == 6, ("4 à 6 pièces par robe (obtenu %d à %d)"):format(minimum, maximum))
```

par :

```lua
U.verifier(minimum == 4 and maximum == 10, ("4 à 10 pièces par robe (obtenu %d à %d)"):format(minimum, maximum))
```

Dans `tests/unitaires/02_catalogue.luau`, remplacer :

```lua
U.verifier(#Catalogue.Variantes == 19 and parFamille.corsage == 5 and parFamille.manches == 5 and parFamille.col == 4 and parFamille.jupe == 5, "19 variantes : cinq corsages, cinq manches, quatre cols, cinq jupes")
```

par :

```lua
U.verifier(#Catalogue.Variantes == 21 and parFamille.corsage == 6 and parFamille.manches == 5 and parFamille.col == 4 and parFamille.jupe == 6, "21 variantes : six corsages, cinq manches, quatre cols, six jupes")
```

Dans `tests/unitaires/15_metrage.luau`, remplacer :

```lua
U.verifier(n == 500, "500 croquis vérifiés")
```

par :

```lua
U.verifier(n == 720, "720 croquis vérifiés (sous-projet 7 : avec le corsage à basque et la jupe à volant)")
```

Dans `tests/unitaires/56_croquis.luau`, remplacer :

```lua
		dedans = dedans and b.minX >= 0 and b.maxX <= Croquis.LARGEUR and b.minY >= 0 and b.maxY <= Croquis.HAUTEUR
		if v.famille == "jupe" then
```

par :

```lua
		dedans = dedans and b.minX >= 0 and b.maxX <= Croquis.LARGEUR and b.minY >= 0 and b.maxY <= Croquis.HAUTEUR
		if polygone.pieces then
			-- (sous-projet 7) une couche qui porte ses pièces, sous la taille : une basque en part, un volant plus bas
			U.verifier(b.minY >= Croquis.TAILLE - 1e-9, v.id .. " : sa couche est sous la taille")
		elseif v.famille == "jupe" then
```

- [ ] **Step 2: Lancer les tests, vérifier l'échec**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT|attempt|membre" | head -3`
Expected: échec : une ligne qui finit par `ÉCHEC : 4 à 10 pièces par robe (obtenu 4 à 6)`

- [ ] **Step 3: Les variantes, la paie, le dessin**

Dans `src/shared/Catalogue.luau`, remplacer :

```lua
	{ id = "jupe_crayon", famille = "jupe", nom = "Crayon",
		pieces = { "jupe_crayon_devant", "jupe_crayon_dos" }, style = { chic = 8, elegant = 4, decontracte = -2 } },
}
```

par :

```lua
	{ id = "jupe_crayon", famille = "jupe", nom = "Crayon",
		pieces = { "jupe_crayon_devant", "jupe_crayon_dos" }, style = { chic = 8, elegant = 4, decontracte = -2 } },
	-- Sous-projet 7 : des couches. (Une variante ne change jamais de pièces : les robes gardées et les recettes des
	-- vitrines resteraient invalides ; on en ajoute de nouvelles.)
	{ id = "corsage_basque", famille = "corsage", nom = "À basque",
		pieces = { "corsage_droit_devant", "corsage_droit_dos", "basque_devant", "basque_dos" }, style = { elegant = 6, chic = 6, romantique = 2 } },
	{ id = "jupe_volant", famille = "jupe", nom = "À volant",
		pieces = { "jupe_droite_devant", "jupe_droite_dos", "volant_devant", "volant_dos" }, style = { romantique = 8, mignon = 6 } },
}
```

Dans `src/shared/Deblocages.luau`, remplacer :

```lua
Deblocages.PRESTIGE_VARIANTES = {
	manches_courtes = 6,
	jupe_crayon = 7,
}
```

par :

```lua
Deblocages.PRESTIGE_VARIANTES = {
	manches_courtes = 6,
	jupe_crayon = 7,
	jupe_volant = 4, -- (sous-projet 7)
	corsage_basque = 5,
}
```

Dans `src/shared/Notation.luau`, remplacer :

```lua
function Notation.base(nbPieces, nbExigences)
	return 20 + 10 * nbPieces + 15 * nbExigences
end

function Notation.paie(nbPieces, nbExigences, qualite)
	return math.floor(Notation.base(nbPieces, nbExigences) * (0.5 + qualite) + 0.5)
end
```

par :

```lua
-- Sous-projet 7 : le poids des pièces d'une robe (une petite pièce ajoutée, volant ou basque, pèse 0,5 ; les autres 1).
-- pieces : identifiants, ou pièces d'une recette ({ id = … })
function Notation.poids(pieces)
	local total = 0
	for _, p in ipairs(pieces) do
		total += Catalogue.piece(if type(p) == "table" then p.id else p).poids or 1
	end
	return total
end

-- poids : le poids des pièces de la robe (Notation.poids ; leur nombre, pour une robe sans petites pièces)
function Notation.base(poids, nbExigences)
	return 20 + 10 * poids + 15 * nbExigences
end

function Notation.paie(poids, nbExigences, qualite)
	return math.floor(Notation.base(poids, nbExigences) * (0.5 + qualite) + 0.5)
end
```

Dans `src/shared/EtatAtelier.luau`, remplacer :

```lua
	local paie = Notation.paie(#recette.pieces, #self.commande.exigences, bilan.qualite)
```

par :

```lua
	local paie = Notation.paie(Notation.poids(recette.pieces), #self.commande.exigences, bilan.qualite)
```

Dans `src/shared/EtatAtelier.luau`, remplacer :

```lua
	local base = (self.commande.matieres or 0) + EtatAtelier.prixDecorations(recette.pieces, self.accessoires) + EtatAtelier.MAIN_OEUVRE * #recette.pieces
```

par :

```lua
	local base = (self.commande.matieres or 0) + EtatAtelier.prixDecorations(recette.pieces, self.accessoires) + EtatAtelier.MAIN_OEUVRE * Notation.poids(recette.pieces)
```

Dans `src/shared/EtatAtelier.luau`, remplacer :

```lua
	local mainOeuvre = math.round(EtatAtelier.MAIN_OEUVRE * #recette.pieces * (0.5 + bilan.qualite) * (1 + bonus))
```

par :

```lua
	local mainOeuvre = math.round(EtatAtelier.MAIN_OEUVRE * Notation.poids(recette.pieces) * (0.5 + bilan.qualite) * (1 + bonus))
```

Dans `src/shared/Croquis.luau`, remplacer :

```lua
local function P(liste)
	local points = {}
	for i = 1, #liste, 2 do
		table.insert(points, { x = liste[i], y = liste[i + 1] })
	end
	return points
end
```

par :

```lua
local function P(liste)
	local points = {}
	for i = 1, #liste, 2 do
		table.insert(points, { x = liste[i], y = liste[i + 1] })
	end
	return points
end

-- Sous-projet 7 : une partie qui porte ses pièces (un volant, une basque) prend leur tissu, et la toucher choisit le
-- tissu de ces pièces seulement ; sans pièces, une partie prend le tissu de la première pièce de la variante
local function avecPieces(pieces, polygone)
	polygone.pieces = pieces
	return polygone
end
```

Dans `src/shared/Croquis.luau`, remplacer :

```lua
	jupe_crayon = { parties = { P({ 39, 42, 61, 42, 63, 52, 61, 84, 39, 84, 37, 52 }) } },
}
```

par :

```lua
	jupe_crayon = { parties = { P({ 39, 42, 61, 42, 63, 52, 61, 84, 39, 84, 37, 52 }) } },
	-- Sous-projet 7 : des couches, dessinées par-dessus (un volant sous la jupe droite, une basque sous le corsage droit)
	corsage_basque = {
		parties = {
			P({ 34, 17, 41, 17, 42, 22, 58, 22, 59, 17, 66, 17, 67, 24, 65, 32, 61, 42, 39, 42, 35, 32, 33, 24 }),
			avecPieces({ "basque_devant", "basque_dos" }, P({ 39, 42, 61, 42, 67, 50, 33, 50 })),
		},
	},
	jupe_volant = {
		parties = {
			P({ 39, 42, 61, 42, 64, 82, 36, 82 }),
			avecPieces({ "volant_devant", "volant_dos" }, P({ 36, 75, 64, 75, 69, 86, 31, 86 })),
		},
		details = { -- les fronces du volant
			{ { x = 40, y = 77 }, { x = 37, y = 85 } },
			{ { x = 45, y = 77 }, { x = 44, y = 85 } },
			{ { x = 50, y = 77 }, { x = 50, y = 85 } },
			{ { x = 55, y = 77 }, { x = 56, y = 85 } },
			{ { x = 60, y = 77 }, { x = 63, y = 85 } },
		},
	},
}
```

Dans `src/shared/Croquis.luau`, remplacer :

```lua
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
```

par :

```lua
-- Parties à dessiner pour un croquis { corsage, manches, col, jupe }, dans l'ordre de dessin :
-- { { famille, polygone, pieces? } } (une manche ou un rabat de col symétrique donne deux parties ; pieces : celles
-- d'une partie qui porte les siennes)
function Croquis.parties(croquis)
	local out = {}
	for _, famille in ipairs(Croquis.ORDRE) do
		local forme = FORMES[croquis[famille]]
		assert(forme, "forme de croquis inconnue : " .. tostring(croquis[famille]))
		for _, polygone in ipairs(forme.parties) do
			table.insert(out, { famille = famille, polygone = polygone, pieces = polygone.pieces })
			if forme.symetrique then
				table.insert(out, { famille = famille, polygone = Polygone.miroir(polygone, Croquis.LARGEUR / 2), pieces = polygone.pieces })
			end
		end
	end
	return out
end
```

Dans `src/shared/Croquis.luau`, remplacer :

```lua
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
```

par :

```lua
-- La famille dessinée sous le point (x, y) du dessin (la plus haute dans l'ordre de dessin), ou nil ; et les pièces de
-- cette partie : les siennes (un volant), sinon celles de la variante
function Croquis.partieA(croquis, x, y)
	local parties = Croquis.parties(croquis)
	for i = #parties, 1, -1 do
		if Polygone.contient(parties[i].polygone, x, y) then
			local p = parties[i]
			return p.famille, p.pieces or Catalogue.variante(croquis[p.famille]).pieces
		end
	end
	return nil
end
```

Dans `src/shared/Pixels.luau`, remplacer :

```lua
-- le papier du carnet est dessous. tissus = { [famille] = idTissu ou nil }. Retourne buffer, largeur, hauteur.
```

par :

```lua
-- le papier du carnet est dessous. tissus = { [famille] = idTissu ou nil } (sous-projet 7 : et [idPiece] pour une
-- partie qui porte ses pièces, un volant). Retourne buffer, largeur, hauteur.
```

Dans `src/shared/Pixels.luau`, remplacer :

```lua
	local tissuDe = {}
	for famille, id in pairs(tissus) do
		tissuDe[famille] = Catalogue.tissu(id)
	end
```

par :

```lua
	local tissuDe = {}
	for cle, id in pairs(tissus) do
		tissuDe[cle] = Catalogue.tissu(id)
	end
```

Dans `src/shared/Pixels.luau`, remplacer :

```lua
					local t = tissuDe[parties[k].famille]
```

par :

```lua
					local partie = parties[k]
					local t = tissuDe[if partie.pieces then partie.pieces[1] else partie.famille]
```

- [ ] **Step 4: Lancer les tests**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT"`
Expected:
```
Unitaires : 192954 vérifications
TOUT EST VERT : 979 vérifications
```

- [ ] **Step 5: Commit**

```bash
git add src/shared/Catalogue.luau src/shared/Deblocages.luau src/shared/Notation.luau src/shared/EtatAtelier.luau src/shared/Croquis.luau src/shared/Pixels.luau tests/unitaires/68_variantes_couches.luau tests/unitaires/02_catalogue.luau tests/unitaires/15_metrage.luau tests/unitaires/56_croquis.luau
git commit -m "La jupe à volant et le corsage à basque : leurs couches dessinées de leur tissu ; la paie compte le poids des pièces

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 3: Le carnet : toucher une couche, la liste des pièces

**Files:**
- Modify: `src/client/Atelier/EcranCarnet.luau`, `src/client/Atelier/Vignettes.luau`
- Modify: `tests/scenario.luau`

**Interfaces:**
- Consumes: `Croquis.partieA -> famille, pieces`, `Croquis.parties` (tâche 2).
- Produces: `ChoixTissu` porte l'attribut `Pieces` (« volant_devant,volant_dos ») ; `Pieces` du carnet est une liste qui défile ; la clé d'un dessin dans `Vignettes` compte le tissu d'une partie qui porte ses pièces.

- [ ] **Step 1: Écrire les tests**

Dans `tests/scenario.luau`, remplacer :

```lua
	verifier(fenetre.Contenu:FindFirstChild("ChoixTissu") == nil and fenetre.Contenu.Page.Pieces.Tissu_jupe_trapeze_devant.Tissu.Text == "Coton blanc", "double clic sur un tissu : choisi, et le second appui ne rouvre pas le choix")
end
```

par :

```lua
	verifier(fenetre.Contenu:FindFirstChild("ChoixTissu") == nil and fenetre.Contenu.Page.Pieces.Tissu_jupe_trapeze_devant.Tissu.Text == "Coton blanc", "double clic sur un tissu : choisi, et le second appui ne rouvre pas le choix")
end
do -- Sous-projet 7 : une jupe à volant et un corsage à basque ; leurs couches ont leurs pièces, leur tissu, leur partie du dessin
	choisirModele("jupe_volant")
	choisirModele("corsage_basque")
	local page = fenetre.Contenu.Page
	local liste = page.Pieces
	local lignes = 0
	for _, e in ipairs(liste:GetChildren()) do
		lignes += if e.Name:sub(1, 6) == "Tissu_" then 1 else 0
	end
	verifier(liste:IsA("ScrollingFrame") and lignes == 10 and liste.CanvasSize.Y.Offset >= 10 * 36 and liste.Position.Y.Offset + liste.Size.Y.Offset <= page.Precedent_corsage.Position.Y.Offset, ("dix pièces : la liste défile, au-dessus des lignes des modèles (%d)"):format(lignes))
	local d = page.Dessin
	local function toucher(x, y)
		M.avancer(0.5)
		d.Activated:Fire({ Position = Vector3.new(d.AbsolutePosition.X + d.AbsoluteSize.X * x / 100, d.AbsolutePosition.Y + d.AbsoluteSize.Y * y / 130, 0) }, 1)
	end
	local imageAvant = d.ImageContent
	toucher(52, 81)
	local ouvert = fenetre.Contenu:FindFirstChild("ChoixTissu")
	verifier(ouvert ~= nil and ouvert:GetAttribute("Pieces") == "volant_devant,volant_dos", "toucher le volant dessiné : le choix du tissu de ses deux pièces")
	M.avancer(0.5)
	fenetre.Contenu.ChoixTissu.Grille.Tissu_velours_noir.Activated:Fire()
	verifier(liste.Tissu_volant_devant.Tissu.Text == "Velours noir" and liste.Tissu_volant_dos.Tissu.Text == "Velours noir" and liste.Tissu_jupe_droite_devant.Tissu.Text ~= "Velours noir", "le volant prend le velours noir, la jupe garde son tissu")
	verifier(d.ImageContent ~= nil and d.ImageContent ~= imageAvant, "le dessin se colorie du tissu du volant")
	toucher(50, 47)
	verifier(fenetre.Contenu.ChoixTissu:GetAttribute("Pieces") == "basque_devant,basque_dos", "toucher la basque dessinée : ses deux pièces")
	cliquer("FermerChoix")
	choisirModele("corsage_v")
	choisirModele("jupe_trapeze")
end
```

- [ ] **Step 2: Lancer les tests, vérifier l'échec**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT|attempt|membre" | head -3`
Expected: échec : une ligne qui finit par `ÉCHEC : dix pièces : la liste défile, au-dessus des lignes des modèles (10)`

- [ ] **Step 3: Le carnet**

Dans `src/client/Atelier/EcranCarnet.luau`, remplacer :

```lua
		local famille = Croquis.partieA(croquis, u * Croquis.LARGEUR, v * Croquis.HAUTEUR)
		if famille then
			ouvrirChoix(Catalogue.variante(croquis[famille]).pieces, famille)
		end
```

par :

```lua
		-- (sous-projet 7 : une couche, un volant, ne choisit que le tissu de ses pièces)
		local famille, piecesTouchees = Croquis.partieA(croquis, u * Croquis.LARGEUR, v * Croquis.HAUTEUR)
		if famille then
			ouvrirChoix(piecesTouchees, famille)
		end
```

Dans `src/client/Atelier/EcranCarnet.luau`, remplacer :

```lua
	local listePieces = UiKit.creer("Frame", { Name = "Pieces", BackgroundTransparency = 1, Position = UDim2.fromOffset(334, 6), Size = UDim2.fromOffset(198, 300), Parent = page })
```

par :

```lua
	-- (une liste qui défile, au-dessus des lignes ◀ ▶ : une robe à couches a jusqu'à dix pièces)
	local listePieces = UiKit.creer("ScrollingFrame", { Name = "Pieces", BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 4, ScrollingDirection = Enum.ScrollingDirection.Y, Position = UDim2.fromOffset(334, 6), Size = UDim2.fromOffset(198, HAUT_LIGNES - 6), Parent = page })
```

Dans `src/client/Atelier/EcranCarnet.luau`, remplacer :

```lua
		choix:SetAttribute("Famille", famille)
```

par :

```lua
		choix:SetAttribute("Famille", famille)
		choix:SetAttribute("Pieces", table.concat(pieces, ","))
```

Dans `src/client/Atelier/EcranCarnet.luau`, remplacer :

```lua
			local ligne = UiKit.arrondir(UiKit.creer("TextButton", { Name = "Tissu_" .. id, Text = "", AutoButtonColor = true, BackgroundColor3 = C.panneau, BackgroundTransparency = 0.3, Position = UDim2.fromOffset(0, (i - 1) * 36), Size = UDim2.fromOffset(198, 34), Parent = listePieces }), 6)
```

par :

```lua
			local ligne = UiKit.arrondir(UiKit.creer("TextButton", { Name = "Tissu_" .. id, Text = "", AutoButtonColor = true, BackgroundColor3 = C.panneau, BackgroundTransparency = 0.3, Position = UDim2.fromOffset(0, (i - 1) * 36), Size = UDim2.fromOffset(192, 34), Parent = listePieces }), 6)
```

Dans `src/client/Atelier/EcranCarnet.luau`, remplacer :

```lua
		UiKit.boutonDoux({ Name = "ToutEnUnTissu", Text = "Même tissu pour toute la robe", TextSize = 14, Position = UDim2.fromOffset(0, #pieces * 36 + 4), Size = UDim2.fromOffset(198, 32), Parent = listePieces }, function()
```

par :

```lua
		listePieces.CanvasSize = UDim2.fromOffset(0, #pieces * 36 + 40)
		UiKit.boutonDoux({ Name = "ToutEnUnTissu", Text = "Même tissu pour toute la robe", TextSize = 14, Position = UDim2.fromOffset(0, #pieces * 36 + 4), Size = UDim2.fromOffset(192, 32), Parent = listePieces }, function()
```

Dans `src/client/Atelier/EcranCarnet.luau`, remplacer :

```lua
		for _, famille in ipairs(Catalogue.FAMILLES) do
			local premiere = Catalogue.variante(croquis[famille]).pieces[1]
			tissusDessin[famille] = premiere and tissus[premiere] or nil
		end
```

par :

```lua
		for _, famille in ipairs(Catalogue.FAMILLES) do
			local premiere = Catalogue.variante(croquis[famille]).pieces[1]
			tissusDessin[famille] = premiere and tissus[premiere] or nil
		end
		-- (sous-projet 7) une partie qui porte ses pièces, un volant, prend le tissu de la première
		for _, partie in ipairs(Croquis.parties(croquis)) do
			if partie.pieces then
				tissusDessin[partie.pieces[1]] = tissus[partie.pieces[1]]
			end
		end
```

Dans `src/client/Atelier/Vignettes.luau`, remplacer :

```lua
	local morceaux = {}
	for _, famille in ipairs(Catalogue.FAMILLES) do
		table.insert(morceaux, croquis[famille] .. "=" .. (tissus[famille] or ""))
	end
```

par :

```lua
	local morceaux = {}
	for _, famille in ipairs(Catalogue.FAMILLES) do
		table.insert(morceaux, croquis[famille] .. "=" .. (tissus[famille] or ""))
	end
	-- (sous-projet 7) le tissu d'une partie qui porte ses pièces, un volant, compte aussi
	local pieces = {}
	for cle in pairs(tissus) do
		if not table.find(Catalogue.FAMILLES, cle) then
			table.insert(pieces, cle)
		end
	end
	table.sort(pieces)
	for _, cle in ipairs(pieces) do
		table.insert(morceaux, cle .. "=" .. tissus[cle])
	end
```

- [ ] **Step 4: Lancer les tests**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT"`
Expected:
```
Unitaires : 192954 vérifications
TOUT EST VERT : 997 vérifications
```

- [ ] **Step 5: Commit**

```bash
git add src/client/Atelier/EcranCarnet.luau src/client/Atelier/Vignettes.luau tests/scenario.luau
git commit -m "Carnet : toucher un volant ne choisit que son tissu ; la liste des pièces défile

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

Construire le lieu du dépôt dans un dossier temporaire (`C:/dev/jeux/roblox-maker/rojo.exe build -o <dossier temporaire>/Plan19Depot.rbxl`) et l'ouvrir dans Studio. En édition (`execute_luau`, Edit), dans un dossier d'essai du `Workspace` : construire le mannequin (`Mannequin.construire`) et la robe (`ConstructeurRobe.construire`) d'une recette corsage à basque (basque à carreaux), manches ballon, col Claudine, jupe à volant (volant noir), taille M, pièces aux places de `Metrage.disposition`, en mesurant le temps (`os.clock`) ; capturer de face (`screen_capture` avec `camera_position` et `look_at_position` : la robe mesure 0,3 stud par dm), puis de près. Puis en Play : attendre 4 s, relever la console.

Expected : la basque s'évase sous la taille et le volant froncé par-dessus l'ourlet, sans traverser la jupe ; moins de 1,5 s pour la robe et le mannequin ; aucune alerte de notre code (« Lieu non publié » et les messages internes de Roblox mis à part). Arrêter Play, supprimer le dossier d'essai et fermer cette fenêtre de Studio (sans enregistrer).

- [ ] **Step 2: Mettre à jour le README**

Dans `README.md`, remplacer :

```markdown
## État actuel (sous-projet 6 terminé côté code, plans 15 à 18 : les mesures à molettes, la mercerie, le tissu entamé)
```

par :

```markdown
## État actuel (sous-projet 7 en cours, plan 19 : des robes à couches, volant et basque)
```

Dans `README.md`, remplacer :

```markdown
   (corsage, col, manches, jupe) : ◀ le nom du modèle ▶ et un point par modèle (19 variantes : cinq corsages dont
   le cache-cœur et le bustier, cinq manches, quatre cols dont le col marin, cinq jupes dont la jupe crayon).
```

par :

```markdown
   (corsage, col, manches, jupe) : ◀ le nom du modèle ▶ et un point par modèle (21 variantes : six corsages dont
   le cache-cœur, le bustier et le corsage à basque, cinq manches, quatre cols dont le col marin, six jupes dont la
   jupe crayon et la jupe à volant). **Des couches** : la basque s'évase sous la taille, par-dessus la jupe ; le
   volant, froncé, part à 5 dm sous la taille et dépasse l'ourlet ; chacun a ses pièces (poids 0,5 dans la paie),
   son tissu et sa partie du dessin (la toucher choisit le tissu de ses pièces). La liste des pièces défile.
```

- [ ] **Step 3: Tests, lieu régénéré, commit**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT"`
Expected:
```
Unitaires : 192954 vérifications
TOUT EST VERT : 997 vérifications
```

```bash
C:/dev/jeux/roblox-maker/rojo.exe build -o AtelierCouture.rbxl
git add README.md AtelierCouture.rbxl
git commit -m "Plan 19 terminé : des robes à couches (volant, basque)

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```
