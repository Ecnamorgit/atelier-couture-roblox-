# Aiguille & Dentelle — Plan 17 : le tissu entamé

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Garder le tissu coupé sur le rouleau, comme dans *Dressmaker* : les pièces d'une robe laissent leurs trous dans une bande entamée en haut du rouleau ; à la robe suivante dans ce tissu, on coupe dans les vides ou dessous.

**Architecture:** `Coupon.nouveau(longueur, trous)` prend les cases des trous (on ne coupe pas dessus), `Coupon.lireTrous` relit des trous venus d'une sauvegarde, `Coupon:ajout()` dit ce qu'une robe ajoute à la bande. `EtatAtelier` gagne `entames` (`[idTissu] = { bas, trous }`) : la fin de la découpe et « Recommencer » versent les pièces coupées dans la bande au lieu de retirer le tissu du stock ; au-delà de 24 trous la bande est jetée d'elle-même (retirée du stock) ; `jeterEntame` la jette à la demande ; une robe libre compte en matières ce qu'elle ajoute. Le serveur ajoute l'action `jeterEntame` ; la sauvegarde garde les bandes (une bande illisible est oubliée). À l'écran : les trous grisés sur le rouleau, « Proposer une place » qui les évite, le tissu neuf à l'achat et au carnet, l'annonce d'une bande jetée.

**Tech Stack:** Luau, Rojo 7.7.0-rc.1, simulation Luau 0.650 (`tests/lancer.sh`), Roblox Studio via le connecteur MCP Studio.

**Spec:** `docs/superpowers/specs/2026-09-30-atelier-fidele-design.md` (section 4 ; plan 17 de la section 6).

## Décisions de ce plan

- **Découpage entre les plans 17 et 18** : la spec met « trous grisés », « proposer » et l'achat au plan 18 ; sans eux, `main` aurait des trous invisibles et une place proposée sur un trou. Ils passent au plan 17. Le plan 18 garde le compteur en mètres (« 1,30 m entamés / 6,00 m », « Cette robe : +0,80 m (13 po) ») et les boutons « Jeter » (à l'achat et à la table, deuxième appui pour confirmer).
- **La bande** : `bas` est la longueur entamée en dm entiers (le bas du trou le plus bas, arrondi au-dessus, comme l'ancien tissu consommé) ; les trous sont rangés dans l'ordre des pièces (un ordre stable d'une copie à l'autre). Le stock compte la bande ; `stockNeuf(idTissu)` en est le reste.
- **Trous** : une pièce passe sur un trou → « La pièce passe sur un trou du tissu entamé. » ; la même pièce qu'un trou se coupe encore ailleurs (c'est une autre robe). Le symétrique d'une pièce pliée compte aussi.
- **Jeter** : à l'achat, ou à la table tant qu'aucune pièce de ce tissu n'est coupée pour la robe (le rouleau repart neuf, plus court). Au-delà de 24 trous, à la fin de la découpe ou en recommençant : jetée d'elle-même, annoncée (« Trop de trous : la bande entamée est jetée (Coton blanc, 1,30 m). »).
- **Robe libre** : ses matières sont le prix des dm qu'elle ajoute à la bande (rien si elle tient dans ses vides).
- **Sauvegarde** : pas de nouvelle version (un champ absent veut dire des rouleaux neufs). Une bande illisible (trous qui se chevauchent ou hors du rouleau, pièce inconnue, plus de 24 trous, plus longue que le stock, tissu absent du stock) est **oubliée** : le rouleau repart neuf, le stock reste entier (on ne retire pas du tissu sur une donnée abîmée). Le bas est recalculé des trous.
- **Achat** : « Conseillé : 11 dm · Neuf : 9 dm (11 entamés) » pour un rouleau entamé ; la quantité proposée et le tissu à acheter du carnet ne comptent que le tissu neuf.
- **Vérifié pendant la préparation** : le plan a été joué entièrement sur un brouillon tiré de `main` ; dix-neuf variantes du brouillon échouent chacune sur la vérification qui les garde ; la table a été rendue dans Studio avec une bande de quatre trous (gris foncé, « Entamé : 11 / 30 dm », pièce proposée dessous).

## Global Constraints

- **Dépôt** : `C:\dev\jeux\atelier-couture`, branche `tissu-entame`, créée depuis `main` (où le plan 16 est fusionné). Selon les règles du commanditaire : la branche testée et relue est fusionnée dans `main` et poussée sur GitHub.
- **Rojo** : `C:/dev/jeux/roblox-maker/rojo.exe`.
- **Contenu original** : aucun nom, texte, image ni son de *Dressmaker*.
- **Équilibrage** : les cibles de `48_equilibrage` doivent tenir (le joueur simulé ne passe pas par la table : inchangé).
- **Contraintes des plans précédents toujours valables** : fins de ligne LF, commits en français terminés par `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`, textes d'au moins 14 px (et aucun texte laissé à « Label »), le serveur fait foi.

## Review Focus

- **Une sauvegarde abîmée** (trous qui se chevauchent, pièce inconnue, trop de trous, bande plus longue que le stock). Attendu : la bande est oubliée, le stock reste. Test : `65_entames_sauvegarde` (« oubliées »).
- **Une robe coupée au milieu de la découpe, puis reprise** (déconnexion). Attendu : le rouleau garde ses trous et les pièces coupées. Test : `65_entames_sauvegarde` (« reprise au milieu de la découpe »).
- **La 25e pièce dans une bande.** Attendu : la bande est jetée, retirée du stock, et on l'annonce. Tests : `64_bande_entamee` (« 25 trous »), scénario (« annoncée »).
- **Jeter une bande après avoir coupé une pièce de ce tissu.** Attendu : refusé (sinon la pièce coupée sortirait du rouleau). Test : `64_bande_entamee` (« on ne jette plus »).
- **Proposer une place sur un rouleau entamé.** Attendu : jamais sur un trou ; dans un vide assez grand, sinon dessous. Tests : `66_table_trous`, scénario (« Proposer » trouve une place libre).

---

### Task 1: Le rouleau à trous (`Coupon`)

**Files:**
- Modify: `src/shared/Coupon.luau` (réécrit)
- Create: `tests/unitaires/63_coupon_trous.luau`

**Interfaces:**
- Consumes: `Catalogue.piece`, `Catalogue.LARGEUR_ROULEAU`, `Catalogue.PLI`, `Polygone` (existants).
- Produces: `Coupon.nouveau(longueur, trous?)` (trous : `{ { piece, x, y, angle } }`) ; champs `coupon.trous`, `coupon.basTrous` ; `Coupon.lireTrous(trous, longueur) -> liste | nil` ; `coupon:ajout() -> dm` ; `coupon:verifier`, `coupon:poser`, `coupon:longueurUtilisee()` inchangés (la longueur utilisée compte les trous).

- [ ] **Step 1: Écrire les tests**

Créer `tests/unitaires/63_coupon_trous.luau` :

```lua
-- Sous-projet 6 : un rouleau entamé par les robes d'avant. Leurs pièces y ont laissé des trous : on ne coupe pas
-- dessus, on coupe dans les vides ou dessous ; ce qu'une robe ajoute à la bande entamée se compte à part.
local Coupon = U.module("Coupon")

-- Une jupe droite (5 × 6) centrée en (2.5, 3) occupe [0, 5] × [0, 6] ; un corsage (4,8 × 4,2) en (9.6, 2.1) occupe
-- [7.2, 12] × [0, 4.2]
local TROUS = {
	{ piece = "jupe_droite_devant", x = 2.5, y = 3, angle = 0 },
	{ piece = "corsage_droit_devant", x = 9.6, y = 2.1, angle = 0 },
}
local c = Coupon.nouveau(20, TROUS)
U.verifier(#c.trous == 2 and next(c.poses) == nil and c:longueurUtilisee() == 6 and c:ajout() == 0, "deux trous : 6 dm entamés, rien d'ajouté, rien de coupé pour cette robe")
local ok, erreur = c:verifier("jupe_droite_dos", { x = 4, y = 3, angle = 0 })
U.verifier(not ok and erreur == "La pièce passe sur un trou du tissu entamé.", "une pièce sur un trou : refusée (" .. tostring(erreur) .. ")")
U.verifier(c:verifier("jupe_droite_devant", { x = 2.5, y = 9, angle = 0 }), "la même pièce qu'un trou se coupe encore, ailleurs (une autre robe)")

-- Couper dans un vide de la bande : rien n'est ajouté
U.verifier(c:poser("corsage_droit_dos", { x = 9.6, y = 6.4, angle = 0 }) and c:longueurUtilisee() == 9 and c:ajout() == 3, "un corsage sous le trou du corsage (jusqu'à 8,5 dm) : 3 dm ajoutés à la bande")
local v = Coupon.nouveau(20, { TROUS[1], { piece = "jupe_droite_dos", x = 11.5, y = 3, angle = 0 } })
U.verifier(v:poser("col_montant", { x = 6, y = 1, angle = 0 }) and v:ajout() == 0, "un col plié entre deux trous de jupe (et son symétrique) : rien d'ajouté")

-- Sous la bande : ce que la robe ajoute
local s = Coupon.nouveau(20, TROUS)
U.verifier(s:poser("jupe_droite_dos", { x = 2.5, y = 9.1, angle = 0 }) and s:longueurUtilisee() == 13 and s:ajout() == 7, "une jupe sous la bande : 13 dm entamés, 7 ajoutés")

-- Une pièce pliée : son symétrique ne passe pas non plus sur un trou
local p = Coupon.nouveau(10, { { piece = "jupe_droite_devant", x = 11.5, y = 3, angle = 0 } })
local okP, errP = p:verifier("manche_longue", { x = 5, y = 3, angle = 0 })
U.verifier(not okP and errP == "La pièce passe sur un trou du tissu entamé.", "le symétrique d'une manche pliée tomberait sur un trou : refusée")

-- Des trous lus d'une sauvegarde : relus s'ils sont lisibles, sinon rien (la bande sera jetée)
local lus = Coupon.lireTrous(TROUS, 100)
U.verifier(lus ~= nil and #lus == 2 and lus[1].piece == "jupe_droite_devant" and lus[2].y == 2.1 and lus ~= TROUS, "trous lisibles : relus (une copie)")
U.verifier(Coupon.lireTrous({ TROUS[1], { piece = "jupe_droite_devant", x = 2.5, y = 9, angle = 0 } }, 100) ~= nil, "la même pièce deux fois (deux robes) : lisible")
for k, mauvais in ipairs({
	"abîmé",
	{ TROUS[1], { piece = "jupe_droite_dos", x = 4, y = 3, angle = 0 } }, -- deux trous qui se chevauchent
	{ { piece = "inconnue", x = 3, y = 3, angle = 0 } },
	{ { piece = "jupe_droite_devant", x = 0 / 0, y = 3, angle = 0 } },
	{ { piece = "jupe_droite_devant", x = 13, y = 3, angle = 0 } }, -- hors du rouleau
	{ { piece = "jupe_droite_devant", x = 2.5, y = 98, angle = 0 } }, -- plus bas que la longueur
	{ { piece = "manche_longue", x = 7, y = 3, angle = 0 } }, -- pliée, à cheval sur le pli
	{ premier = TROUS[1] }, -- pas une liste
	{ 42 },
}) do
	U.verifier(Coupon.lireTrous(mauvais, 100) == nil, "trous illisibles : rien (" .. k .. ")")
end
U.verifier(#Coupon.lireTrous({}, 100) == 0, "aucun trou : une liste vide")
```

- [ ] **Step 2: Lancer les tests, vérifier l'échec**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT|attempt|membre" | head -3`
Expected: échec : une ligne qui finit par `attempt to get length of a nil value`

- [ ] **Step 3: Réécrire le rouleau**

Le rouleau réécrit remplace l'ancien fichier en entier. Créer `src/shared/Coupon.luau` :

```lua
-- Coupon : un rouleau de tissu sur la table de découpe (14 dm de large, droit-fil le long de y).
-- Vérifie qu'une pièce posée tient dans le rouleau sans chevaucher les pièces déjà coupées.
-- Le chevauchement est détecté sur une grille de cases de 0,1 dm (le centre de chaque case).
-- Sous-projet 6 : le haut du rouleau peut être entamé par les robes d'avant ; leurs pièces y ont laissé des trous,
-- qu'on ne coupe pas deux fois : on coupe dans les vides, ou dessous.
local dossier = script.Parent
local Catalogue = require(dossier:WaitForChild("Catalogue"))
local Polygone = require(dossier:WaitForChild("Polygone"))

local Coupon = {}
Coupon.__index = Coupon

local PAS = 0.1
local EPSILON = 1e-6
local ANGLE_MAX = 3600 -- au-delà, le modulo perd sa précision : un client pourrait fausser le droit-fil
local COLONNES = math.floor(Catalogue.LARGEUR_ROULEAU / PAS + 0.5)
local TROU = "(trou)" -- une case prise par une robe d'avant

local function fini(n)
	return type(n) == "number" and n == n and n ~= math.huge and n ~= -math.huge
end

-- Contours posés sur le rouleau : la pièce, et son symétrique par rapport au pli si elle est pliée.
-- placement = { x, y, angle } : le centre de la boîte du patron va en (x, y), puis rotation de angle degrés.
function Coupon.contoursPoses(idPiece, placement)
	local def = Catalogue.piece(idPiece)
	local pose = Polygone.poser(def.contour, placement, Polygone.centre(def.contour))
	if def.pliee then
		return { pose, Polygone.miroir(pose, Catalogue.PLI) }
	end
	return { pose }
end

local function cellulesDe(contour)
	local b = Polygone.boite(contour)
	local out = {}
	for colonne = math.max(0, math.floor(b.minX / PAS)), math.ceil(b.maxX / PAS) - 1 do
		for ligne = math.max(0, math.floor(b.minY / PAS)), math.ceil(b.maxY / PAS) - 1 do
			if Polygone.contient(contour, (colonne + 0.5) * PAS, (ligne + 0.5) * PAS) then
				table.insert(out, ligne * COLONNES + colonne)
			end
		end
	end
	return out
end

-- Une pièce à une place : connue, place finie, dans le rouleau, d'un côté du pli, sans chevaucher ce qui est déjà
-- pris. Retourne ok, erreur, et les contours et cases occupées si ok
local function place(self, idPiece, placement)
	local def = Catalogue.piece(idPiece)
	if not def then
		return false, "Pièce inconnue."
	end
	if type(placement) ~= "table" or not fini(placement.x) or not fini(placement.y) or not fini(placement.angle)
		or math.abs(placement.angle) > ANGLE_MAX then
		return false, "Position invalide."
	end
	local contours = Coupon.contoursPoses(idPiece, placement)
	local b = Polygone.boite(contours[1])
	if b.minX < -EPSILON or b.maxX > Catalogue.LARGEUR_ROULEAU + EPSILON or b.minY < -EPSILON or b.maxY > self.longueur + EPSILON then
		return false, "La pièce dépasse du tissu."
	end
	-- Pièce pliée : entièrement d'un côté du pli (à gauche ou à droite), son symétrique occupe l'autre côté
	if def.pliee and b.minX < Catalogue.PLI - EPSILON and b.maxX > Catalogue.PLI + EPSILON then
		return false, "Une pièce pliée doit tenir d'un côté du pli."
	end
	local cases = {}
	for _, contour in ipairs(contours) do
		for _, cle in ipairs(cellulesDe(contour)) do
			if self.cellules[cle] == TROU then
				return false, "La pièce passe sur un trou du tissu entamé."
			elseif self.cellules[cle] or cases[cle] then
				return false, "La pièce chevauche une autre pièce."
			end
			cases[cle] = true
		end
	end
	return true, nil, contours, cases
end

-- Prend les cases d'une pièce (valeur : son identifiant, ou TROU) ; renvoie le bas de la pièce
local function prendre(self, contours, cases, valeur)
	for cle in pairs(cases) do
		self.cellules[cle] = valeur
	end
	local bas = 0
	for _, contour in ipairs(contours) do
		bas = math.max(bas, Polygone.boite(contour).maxY)
	end
	return bas
end

-- longueur : longueur déroulée disponible (dm) ; trous (facultatif) : les pièces coupées pour les robes d'avant, en
-- haut du rouleau ({ piece, x, y, angle }), déjà vérifiées (Coupon.lireTrous)
function Coupon.nouveau(longueur, trous)
	local self = setmetatable({ longueur = longueur, cellules = {}, poses = {}, trous = {}, basTrous = 0, basMax = 0 }, Coupon)
	for _, t in ipairs(trous or {}) do
		local pose = { x = t.x, y = t.y, angle = t.angle }
		local cases = {}
		local contours = Coupon.contoursPoses(t.piece, pose)
		for _, contour in ipairs(contours) do
			for _, cle in ipairs(cellulesDe(contour)) do
				cases[cle] = true
			end
		end
		self.basTrous = math.max(self.basTrous, prendre(self, contours, cases, TROU))
		table.insert(self.trous, { piece = t.piece, x = t.x, y = t.y, angle = t.angle })
	end
	self.basMax = self.basTrous
	return self
end

-- Des trous venus d'ailleurs (une sauvegarde) : une liste de pièces connues, à des places finies, dans un rouleau de
-- cette longueur, qui ne se chevauchent pas (une même pièce peut revenir : deux robes). Renvoie la liste relue, ou
-- nil si l'un des trous est illisible
function Coupon.lireTrous(trous, longueur)
	if type(trous) ~= "table" then
		return nil
	end
	local n = 0
	for _ in pairs(trous) do
		n += 1
	end
	if n ~= #trous then
		return nil -- pas une liste
	end
	local essai, out = Coupon.nouveau(longueur), {}
	for _, t in ipairs(trous) do
		if type(t) ~= "table" or type(t.piece) ~= "string" then
			return nil
		end
		local pose = { x = t.x, y = t.y, angle = t.angle }
		local ok, _, contours, cases = place(essai, t.piece, pose)
		if not ok then
			return nil
		end
		prendre(essai, contours, cases, TROU)
		table.insert(out, { piece = t.piece, x = t.x, y = t.y, angle = t.angle })
	end
	return out
end

-- Retourne ok (bool), erreur (string?), et les contours et cases occupées si ok
function Coupon:verifier(idPiece, placement)
	if Catalogue.piece(idPiece) and self.poses[idPiece] then
		return false, "Cette pièce est déjà coupée."
	end
	return place(self, idPiece, placement)
end

function Coupon:poser(idPiece, placement)
	local ok, erreur, contours, cases = self:verifier(idPiece, placement)
	if not ok then
		return false, erreur
	end
	self.basMax = math.max(self.basMax, prendre(self, contours, cases, idPiece))
	self.poses[idPiece] = { x = placement.x, y = placement.y, angle = placement.angle }
	return true
end

-- Longueur de tissu entamée, trous des robes d'avant compris (dm entiers, arrondie au-dessus)
function Coupon:longueurUtilisee()
	return math.ceil(self.basMax - EPSILON)
end

-- Ce que les pièces de cette robe ajoutent à la bande entamée (dm entiers) : rien si elles tiennent dans ses vides
function Coupon:ajout()
	return math.max(0, self:longueurUtilisee() - math.ceil(self.basTrous - EPSILON))
end

return Coupon
```

- [ ] **Step 4: Lancer les tests**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT"`
Expected:
```
Unitaires : 167932 vérifications
TOUT EST VERT : 943 vérifications
```

- [ ] **Step 5: Commit**

```bash
git add src/shared/Coupon.luau tests/unitaires/63_coupon_trous.luau
git commit -m "Coupon : un rouleau entamé, dont les trous ne se coupent pas deux fois ; ce qu'une robe ajoute à la bande

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 2: La bande entamée (`EtatAtelier`)

**Files:**
- Modify: `src/shared/EtatAtelier.luau`
- Create: `tests/unitaires/64_bande_entamee.luau`
- Modify: `tests/unitaires/14_etat_atelier.luau`, `tests/unitaires/30_sauvegarde.luau`

**Interfaces:**
- Consumes: `Coupon.nouveau(longueur, trous)`, `coupon.trous`, `coupon:ajout()` (tâche 1).
- Produces: `etat.entames` (`[idTissu] = { bas, trous }`, dans `CHAMPS`) ; `EtatAtelier.TROUS_MAX` (24) ; `etat:stockNeuf(idTissu) -> dm`, `etat:stocksNeufs() -> { [idTissu] = dm }` ; `etat:jeterEntame(idTissu) -> { ok, dm }` ; `couper` et `recommencer` rendent `jetees = { { tissu, dm } }` quand une bande est jetée d'elle-même ; les rouleaux exportés portent `trous`.

- [ ] **Step 1: Écrire les tests de la bande**

Créer `tests/unitaires/64_bande_entamee.luau` :

```lua
-- Sous-projet 6 : le tissu coupé ne quitte plus le stock ; il laisse une bande entamée en haut du rouleau, avec ses
-- trous. À la robe suivante on coupe dans ses vides ou dessous ; on peut la jeter (elle quitte alors le stock) ; au-delà
-- de 24 trous, elle se jette d'elle-même.
local EtatAtelier = U.module("EtatAtelier")

local CROQUIS = { corsage = "corsage_droit", manches = "manches_sans", col = "col_sans", jupe = "jupe_droite" }
local ORDRE = { "corsage_droit_devant", "corsage_droit_dos", "jupe_droite_devant", "jupe_droite_dos" }
local function tousEn(tissu)
	local out = {}
	for _, id in ipairs(ORDRE) do
		out[id] = tissu
	end
	return out
end
-- Les quatre pièces, rangées en haut du rouleau (jusqu'à 10,2 dm), ou décalées de « dy » vers le bas
local function places(dy)
	return {
		corsage_droit_devant = { x = 2.4, y = 2.1 + dy, angle = 0 },
		corsage_droit_dos = { x = 7.2, y = 2.1 + dy, angle = 0 },
		jupe_droite_devant = { x = 2.5, y = 7.2 + dy, angle = 0 },
		jupe_droite_dos = { x = 7.5, y = 7.2 + dy, angle = 0 },
	}
end
local graine = 0
local function aLaTable(e, dm)
	graine += 1
	U.commander(e, Random.new(graine))
	assert(e:validerCroquis(CROQUIS, tousEn("coton_blanc")).ok)
	if dm then
		assert(e:acheter("coton_blanc", dm).ok)
	end
	assert(e:commencerDecoupe().ok)
end
local function toutCouper(e, p)
	local r
	for _, id in ipairs(ORDRE) do
		r = e:couper(id, p[id])
		assert(r.ok, id .. " : " .. tostring(r.erreur))
	end
	return r
end
local function finir(e) -- (la robe s'arrête là : seul le rouleau compte ici)
	e.etape = "refus"
	assert(e:abandonner().ok)
end

---------------------------------------------------------------------------
-- La première robe : le stock reste, une bande entamée de 11 dm, quatre trous
---------------------------------------------------------------------------
local e = EtatAtelier.nouveau(1000)
U.verifier(type(e.entames) == "table" and next(e.entames) == nil, "une partie neuve : aucun rouleau entamé")
aLaTable(e, 20)
local r = toutCouper(e, places(0))
local b = e.entames.coton_blanc or {}
U.verifier(e.stock.coton_blanc == 20 and b.trous ~= nil and b.bas == 11 and #b.trous == 4 and r.jetees == nil, "robe coupée : le stock reste (20 dm), une bande entamée de 11 dm, quatre trous")
U.verifier(b.trous ~= nil and b.trous[1].piece == "corsage_droit_devant" and b.trous[4].piece == "jupe_droite_dos" and b.trous[3].y == 7.2, "les trous : chaque pièce à sa place, dans un ordre stable")
U.verifier(e:stockNeuf("coton_blanc") == 9 and e:stocksNeufs().coton_blanc == 9 and e:stockNeuf("soie_rouge") == 0, "le tissu neuf : 9 dm (20 moins les 11 entamés)")
local copie = EtatAtelier.nouveau():charger(e:exporter())
U.verifier(copie.entames.coton_blanc.bas == 11 and #copie.entames.coton_blanc.trous == 4, "la bande entamée voyage avec l'état")
finir(e)
U.verifier(e.entames.coton_blanc.bas == 11, "la robe finie, la bande reste")

---------------------------------------------------------------------------
-- La robe suivante : les trous sont pris, on coupe dessous (le rouleau se déroule en rachetant)
---------------------------------------------------------------------------
aLaTable(e)
local rouleau = e.coupons.coton_blanc
U.verifier(rouleau.longueur == 20 and #rouleau.trous == 4 and rouleau:longueurUtilisee() == 11, "à la table : le rouleau de 20 dm, et ses quatre trous")
local surTrou = e:couper("corsage_droit_devant", places(0).corsage_droit_devant)
U.verifier(not surTrou.ok and surTrou.erreur == "La pièce passe sur un trou du tissu entamé.", "couper sur un trou : refusé")
local client = EtatAtelier.nouveau():charger(e:exporter())
U.verifier(#client.coupons.coton_blanc.trous == 4 and not client.coupons.coton_blanc:verifier("corsage_droit_devant", places(0).corsage_droit_devant), "la copie du client a les mêmes trous")
assert(e:acheter("coton_blanc", 2).ok)
r = toutCouper(e, places(11))
b = e.entames.coton_blanc or {}
U.verifier(e.stock.coton_blanc == 22 and b.bas == 22 and #(b.trous or {}) == 8 and e:stockNeuf("coton_blanc") == 0, "sous la bande : elle descend à 22 dm, huit trous, plus de tissu neuf")
finir(e)

---------------------------------------------------------------------------
-- Jeter la bande : à l'achat, ou à la table tant que rien de ce tissu n'est coupé pour cette robe
---------------------------------------------------------------------------
U.verifier(e:jeterEntame("coton_blanc").erreur == "Ce n'est pas le moment de jeter du tissu.", "à l'accueil : pas de bande à jeter")
graine += 1
U.commander(e, Random.new(graine))
assert(e:validerCroquis(CROQUIS, tousEn("coton_blanc")).ok)
U.verifier(e:jeterEntame("tissu_inconnu").erreur == "Tissu inconnu." and e:jeterEntame("soie_rouge").erreur == "Ce rouleau n'est pas entamé." and e:jeterEntame(nil).erreur == "Tissu inconnu.", "tissu inconnu ou rouleau neuf : rien à jeter")
local j = e:jeterEntame("coton_blanc")
U.verifier(j.ok and j.dm == 22 and e.stock.coton_blanc == 0 and e.entames.coton_blanc == nil, "à l'achat : la bande (22 dm) quitte le stock, le rouleau repart neuf")
assert(e:acheter("coton_blanc", 12).ok and e:commencerDecoupe().ok)
toutCouper(e, places(0))
finir(e)
aLaTable(e, 10)
U.verifier(e.coupons.coton_blanc.longueur == 22 and #e.coupons.coton_blanc.trous == 4, "une nouvelle bande, un rouleau de 22 dm")
j = e:jeterEntame("coton_blanc")
U.verifier(j.ok and e.stock.coton_blanc == 11 and e.coupons.coton_blanc.longueur == 11 and #e.coupons.coton_blanc.trous == 0 and e.etape == "decoupe", "à la table, rien de coupé : la bande est jetée, le rouleau repart neuf (11 dm)")
assert(e:couper("corsage_droit_devant", places(0).corsage_droit_devant).ok)
e.entames.coton_blanc = { bas = 1, trous = { { piece = "jupe_droite_devant", x = 2.5, y = 3, angle = 0 } } } -- (une bande d'avant)
local refus = e:jeterEntame("coton_blanc")
U.verifier(not refus.ok and refus.erreur == "Des pièces de ce tissu sont déjà coupées pour cette robe." and e.entames.coton_blanc ~= nil, "une pièce de ce tissu déjà coupée : on ne jette plus")
e.entames.coton_blanc = nil

---------------------------------------------------------------------------
-- Recommencer : les pièces coupées deviennent des trous (le tissu reste sur le rouleau)
---------------------------------------------------------------------------
local rc = EtatAtelier.nouveau(1000)
aLaTable(rc, 12)
assert(rc:couper("jupe_droite_devant", places(0).jupe_droite_devant).ok)
assert(rc:couper("corsage_droit_dos", places(0).corsage_droit_dos).ok)
r = rc:recommencer()
local bandeRc = rc.entames.coton_blanc
U.verifier(r.ok and rc.stock.coton_blanc == 12 and bandeRc ~= nil and bandeRc.bas == 11 and #bandeRc.trous == 2 and rc.etape == "carnet", "recommencer : deux pièces coupées, deux trous ; le stock reste")

---------------------------------------------------------------------------
-- Au-delà de 24 trous, la bande est jetée d'elle-même (et annoncée)
---------------------------------------------------------------------------
-- 20 ou 21 trous de corsages couchés (4,2 × 4,8 dm), trois par rangée : sept rangées, jusqu'à 33,6 dm
local function trous(n)
	local out = {}
	for k = 0, n - 1 do
		table.insert(out, { piece = "corsage_droit_devant", x = 2.1 + 4.2 * (k % 3), y = 2.4 + 4.8 * (k // 3), angle = 90 })
	end
	return out
end
local pleine = EtatAtelier.nouveau(1000)
pleine.stock.coton_blanc = 60
pleine.entames.coton_blanc = { bas = 34, trous = trous(20) }
aLaTable(pleine)
r = toutCouper(pleine, places(34))
local bandePleine = pleine.entames.coton_blanc
U.verifier(r.jetees == nil and bandePleine ~= nil and #bandePleine.trous == 24 and bandePleine.bas == 45, "24 trous : la bande reste (45 dm)")
finir(pleine)
local trop = EtatAtelier.nouveau(1000)
trop.stock.coton_blanc = 60
trop.entames.coton_blanc = { bas = 34, trous = trous(21) }
aLaTable(trop)
r = toutCouper(trop, places(34))
U.verifier(r.jetees ~= nil and #r.jetees == 1 and r.jetees[1].tissu == "coton_blanc" and r.jetees[1].dm == 45 and trop.entames.coton_blanc == nil and trop.stock.coton_blanc == 60 - 45, "25 trous : la bande (45 dm) est jetée d'elle-même, et annoncée")

---------------------------------------------------------------------------
-- Une robe libre : ses matières sont ce qu'elle ajoute à la bande entamée
---------------------------------------------------------------------------
local libre = EtatAtelier.nouveau(1000)
aLaTable(libre, 22)
toutCouper(libre, places(0))
finir(libre)
libre.livraisons = EtatAtelier.LIBRES_APRES
assert(libre:nouvelleRobeLibre("M").ok and libre:validerCroquis(CROQUIS, tousEn("coton_blanc")).ok and libre:commencerDecoupe().ok)
toutCouper(libre, places(11))
U.verifier(libre.commande.matieres == EtatAtelier.prix("coton_blanc", 11) and libre.commande.matieres ~= EtatAtelier.prix("coton_blanc", 22), "robe libre coupée sous une bande de 11 dm : ses matières, les 11 dm qu'elle ajoute")
```

- [ ] **Step 2: Adapter les tests qui retiraient le tissu coupé du stock**

Dans `tests/unitaires/14_etat_atelier.luau`, remplacer :

```lua
U.verifier(e.stock.soie_rouge == 6 - 5 and e.stock.coton_blanc == 12 - 11, "chaque rouleau perd sa longueur entamée (5 et 11 dm)")
```

par :

```lua
U.verifier(e.stock.soie_rouge == 6 and e.stock.coton_blanc == 12 and (e.entames.soie_rouge or {}).bas == 5 and (e.entames.coton_blanc or {}).bas == 11, "chaque rouleau garde son tissu, avec une bande entamée de 5 et de 11 dm (sous-projet 6)")
```

Dans `tests/unitaires/14_etat_atelier.luau`, remplacer :

```lua
U.verifier(e2.etape == "epinglage" and e2.stock.coton_blanc == 12 - 11, "robe coupée, 11 dm consommés")
```

par :

```lua
U.verifier(e2.etape == "epinglage" and e2.stock.coton_blanc == 12 and (e2.entames.coton_blanc or {}).bas == 11, "robe coupée, 11 dm entamés")
```

Dans `tests/unitaires/14_etat_atelier.luau`, remplacer :

```lua
-- Recommencer : le tissu entamé est perdu, la commande reste
```

par :

```lua
-- Recommencer : la commande reste ; la pièce coupée reste sur le rouleau, en trou
```

Dans `tests/unitaires/14_etat_atelier.luau`, remplacer :

```lua
U.verifier(e3.stock.coton_blanc == 12 - 11, "le tissu entamé est perdu")
```

par :

```lua
U.verifier(e3.stock.coton_blanc == 12 and (e3.entames.coton_blanc or {}).bas == 11 and #((e3.entames.coton_blanc or {}).trous or {}) == 1, "la pièce coupée devient un trou de la bande entamée")
```

Dans `tests/unitaires/14_etat_atelier.luau`, remplacer :

```lua
U.verifier(e4:recommencer().ok and e4.stock.soie_rouge == 0, "recommencer : le tissu entamé est perdu")
```

par :

```lua
U.verifier(e4:recommencer().ok and e4.stock.soie_rouge == 12 and (e4.entames.soie_rouge or {}).bas == 12, "recommencer : la jupe coupée devient un trou, la bande entamée descend au bas du rouleau")
```

Dans `tests/unitaires/30_sauvegarde.luau`, remplacer :

```lua
etat:commencerDecoupe()
etat:couper(ORDRE[1], PLACES[ORDRE[1]])
U.verifier(etat.etape == "decoupe" and #etat:piecesAPoser() == 3, "la suivante au milieu de la découpe (mise en place du test)")
```

par :

```lua
etat:commencerDecoupe()
etat:couper(ORDRE[1], { x = 2.4, y = 13.1, angle = 0 }) -- (sous la bande entamée par la première robe)
U.verifier(etat.etape == "decoupe" and #etat:piecesAPoser() == 3, "la suivante au milieu de la découpe (mise en place du test)")
```

Dans `tests/unitaires/30_sauvegarde.luau`, remplacer :

```lua
U.verifier(relue:couper(ORDRE[2], PLACES[ORDRE[2]]).ok, "la découpe continue")
```

par :

```lua
U.verifier(relue:couper(ORDRE[2], { x = 7.2, y = 13.1, angle = 0 }).ok, "la découpe continue")
```

- [ ] **Step 3: Lancer les tests, vérifier l'échec**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT|attempt|membre" | head -3`
Expected: échec : une ligne qui finit par `ÉCHEC : chaque rouleau garde son tissu, avec une bande entamée de 5 et de 11 dm (sous-projet 6)`

- [ ] **Step 4: La bande dans `EtatAtelier`**

Dans `src/shared/EtatAtelier.luau`, remplacer :

```lua
EtatAtelier.SOUVENIRS_OFFERTS = 5 -- exemplaires du souvenir d'un événement qui a lieu
```

par :

```lua
EtatAtelier.SOUVENIRS_OFFERTS = 5 -- exemplaires du souvenir d'un événement qui a lieu
-- Sous-projet 6 : le tissu coupé laisse une bande entamée en haut du rouleau, avec ses trous ; au-delà de 24 trous,
-- elle est jetée d'elle-même
EtatAtelier.TROUS_MAX = 24
```

Dans `src/shared/EtatAtelier.luau`, remplacer :

```lua
local CHAMPS = { "argent", "stock", "etape", "commande", "croquis", "tissus", "coupees", "epinglees", "coutures", "accessoires", "robes", "clientes", "prestige", "livraisons", "visites", "ventes", "lettres", "histoire", "mercerie" }
```

par :

```lua
local CHAMPS = { "argent", "stock", "etape", "commande", "croquis", "tissus", "coupees", "epinglees", "coutures", "accessoires", "robes", "clientes", "prestige", "livraisons", "visites", "ventes", "lettres", "histoire", "mercerie", "entames" }
```

Dans `src/shared/EtatAtelier.luau`, remplacer :

```lua
		mercerie = table.clone(EtatAtelier.KIT_MERCERIE), -- sous-projet 6
	}, EtatAtelier)
```

par :

```lua
		mercerie = table.clone(EtatAtelier.KIT_MERCERIE), -- sous-projet 6
		-- Sous-projet 6 : la bande entamée en haut de chaque rouleau ([idTissu] = { bas = dm, trous = { { piece, x, y,
		-- angle } } }), comptée dans le stock ; absente : un rouleau neuf
		entames = {},
	}, EtatAtelier)
```

Dans `src/shared/EtatAtelier.luau`, remplacer :

```lua
-- Le tissu déjà coupé est perdu : on retire du stock la longueur entamée de chaque rouleau
local function consommer(self)
	for idTissu, coupon in pairs(self.coupons) do
		self.stock[idTissu] = math.max(0, (self.stock[idTissu] or 0) - coupon:longueurUtilisee())
	end
	self.coupons = {}
end
```

par :

```lua
-- Le tissu du stock qui n'est pas entamé (dm)
function EtatAtelier:stockNeuf(idTissu)
	local entame = self.entames[idTissu]
	return math.max(0, (self.stock[idTissu] or 0) - (entame and entame.bas or 0))
end

-- Le tissu neuf de chaque tissu en stock ([idTissu] = dm) : ce que le métrage conseillé compte
function EtatAtelier:stocksNeufs()
	local out = {}
	for idTissu in pairs(self.stock) do
		out[idTissu] = self:stockNeuf(idTissu)
	end
	return out
end

-- Le tissu coupé reste sur le rouleau : les pièces de chaque rouleau deviennent des trous de sa bande entamée, qui
-- descend jusqu'au bas de la plus basse. Au-delà de 24 trous, la bande est jetée (retirée du stock). Renvoie les bandes
-- jetées ({ { tissu, dm } }), ou nil
local function entamer(self)
	local jetees = {}
	for idTissu, coupon in pairs(self.coupons) do
		if next(coupon.poses) then
			local trous, ids = table.clone(coupon.trous), {}
			for idPiece in pairs(coupon.poses) do
				table.insert(ids, idPiece)
			end
			table.sort(ids) -- (un ordre stable, d'une copie à l'autre)
			for _, idPiece in ipairs(ids) do
				local p = coupon.poses[idPiece]
				table.insert(trous, { piece = idPiece, x = p.x, y = p.y, angle = p.angle })
			end
			local bas = coupon:longueurUtilisee()
			if #trous > EtatAtelier.TROUS_MAX then
				self.stock[idTissu] = math.max(0, (self.stock[idTissu] or 0) - bas)
				self.entames[idTissu] = nil
				table.insert(jetees, { tissu = idTissu, dm = bas })
			else
				self.entames[idTissu] = { bas = bas, trous = trous }
			end
		end
	end
	self.coupons = {}
	table.sort(jetees, function(a, b)
		return a.tissu < b.tissu
	end)
	return if #jetees > 0 then jetees else nil
end
```

Dans `src/shared/EtatAtelier.luau`, remplacer :

```lua
	self.coupons = {}
	for _, t in ipairs(self:tissusUtilises()) do
		self.coupons[t] = Coupon.nouveau(math.min(self.stock[t], Recette.LONGUEUR_MAX))
	end
	self.etape = "decoupe"
	return { ok = true }
```

par :

```lua
	self.coupons = {}
	for _, t in ipairs(self:tissusUtilises()) do
		local entame = self.entames[t]
		self.coupons[t] = Coupon.nouveau(math.min(self.stock[t], Recette.LONGUEUR_MAX), entame and entame.trous)
	end
	self.etape = "decoupe"
	return { ok = true }
```

Dans `src/shared/EtatAtelier.luau`, remplacer :

```lua
	self.coupees[idPiece] = coupon.poses[idPiece]
	if #self:piecesAPoser() == 0 then
		if self.commande.libre then
			-- le prix des matières d'une robe libre : le tissu entamé de chaque rouleau
			local matieres = 0
			for idTissu, c in pairs(self.coupons) do
				matieres += EtatAtelier.prix(idTissu, c:longueurUtilisee())
			end
			self.commande.matieres = matieres
		end
		consommer(self)
		self.etape = "epinglage"
	end
	return { ok = true, reste = #self:piecesAPoser() }
```

par :

```lua
	self.coupees[idPiece] = coupon.poses[idPiece]
	local jetees
	if #self:piecesAPoser() == 0 then
		if self.commande.libre then
			-- le prix des matières d'une robe libre : ce qu'elle ajoute à la bande entamée de chaque rouleau
			local matieres = 0
			for idTissu, c in pairs(self.coupons) do
				matieres += EtatAtelier.prix(idTissu, c:ajout())
			end
			self.commande.matieres = matieres
		end
		jetees = entamer(self)
		self.etape = "epinglage"
	end
	return { ok = true, reste = #self:piecesAPoser(), jetees = jetees }
```

Dans `src/shared/EtatAtelier.luau`, remplacer :

```lua
-- Abandonne la robe en cours (le tissu déjà coupé est perdu), garde la commande
function EtatAtelier:recommencer()
```

par :

```lua
-- Abandonne la robe en cours (les pièces déjà coupées deviennent des trous de la bande entamée), garde la commande
function EtatAtelier:recommencer()
```

Dans `src/shared/EtatAtelier.luau`, remplacer :

```lua
	consommer(self)
	self.croquis, self.tissus, self.coupees = nil, {}, {}
	self.epinglees, self.coutures, self.accessoires = {}, {}, {}
	self.argent = math.max(self.argent, EtatAtelier.FILET) -- jamais bloqué sans argent ni tissu
	self.etape = "carnet"
	return { ok = true }
```

par :

```lua
	local jetees = entamer(self)
	self.croquis, self.tissus, self.coupees = nil, {}, {}
	self.epinglees, self.coutures, self.accessoires = {}, {}, {}
	self.argent = math.max(self.argent, EtatAtelier.FILET) -- jamais bloqué sans argent ni tissu
	self.etape = "carnet"
	return { ok = true, jetees = jetees }
end

-- Jette la bande entamée d'un rouleau (elle quitte le stock) : à l'achat, ou à la table tant qu'aucune pièce de ce
-- tissu n'est coupée pour la robe en cours (le rouleau repart neuf)
function EtatAtelier:jeterEntame(idTissu)
	if self.etape ~= "achat" and self.etape ~= "decoupe" then
		return refus("Ce n'est pas le moment de jeter du tissu.")
	end
	if type(idTissu) ~= "string" or not Catalogue.tissu(idTissu) then
		return refus("Tissu inconnu.")
	end
	local entame = self.entames[idTissu]
	if not entame then
		return refus("Ce rouleau n'est pas entamé.")
	end
	local coupon = self.coupons[idTissu]
	if coupon and next(coupon.poses) then
		return refus("Des pièces de ce tissu sont déjà coupées pour cette robe.")
	end
	self.stock[idTissu] = math.max(0, (self.stock[idTissu] or 0) - entame.bas)
	self.entames[idTissu] = nil
	if coupon then
		self.coupons[idTissu] = Coupon.nouveau(math.min(self.stock[idTissu], Recette.LONGUEUR_MAX))
	end
	return { ok = true, dm = entame.bas }
```

Dans `src/shared/EtatAtelier.luau`, remplacer :

```lua
		out[idTissu] = { longueur = coupon.longueur, poses = copie(coupon.poses) }
```

par :

```lua
		out[idTissu] = { longueur = coupon.longueur, poses = copie(coupon.poses), trous = copie(coupon.trous) }
```

Dans `src/shared/EtatAtelier.luau`, remplacer :

```lua
-- Les rouleaux deviennent { longueur, poses }. robes (facultatif) : nombre de robes copiées, les plus
```

par :

```lua
-- Les rouleaux deviennent { longueur, poses, trous }. robes (facultatif) : nombre de robes copiées, les plus
```

Dans `src/shared/EtatAtelier.luau`, remplacer :

```lua
			local coupon = Coupon.nouveau(r.longueur)
			for idPiece, pose in pairs(r.poses) do
```

par :

```lua
			local coupon = Coupon.nouveau(r.longueur, r.trous)
			for idPiece, pose in pairs(r.poses) do
```

- [ ] **Step 5: Lancer les tests**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT"`
Expected:
```
Unitaires : 167952 vérifications
TOUT EST VERT : 943 vérifications
```

- [ ] **Step 6: Commit**

```bash
git add src/shared/EtatAtelier.luau tests/unitaires/64_bande_entamee.luau tests/unitaires/14_etat_atelier.luau tests/unitaires/30_sauvegarde.luau
git commit -m "Le tissu coupé reste sur le rouleau : une bande entamée et ses trous ; jetée à la demande, ou d'elle-même au-delà de 24 trous

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 3: Le serveur et la sauvegarde

**Files:**
- Modify: `src/server/Commande.luau`, `src/server/Sauvegarde.luau`
- Create: `tests/unitaires/65_entames_sauvegarde.luau`

**Interfaces:**
- Consumes: `etat.entames`, `etat:jeterEntame`, `EtatAtelier.TROUS_MAX` (tâche 2) ; `Coupon.lireTrous`, `Coupon.nouveau` (tâche 1).
- Produces: l'action serveur `jeterEntame(idTissu)` ; le champ `entames` de la partie (même version 4).

- [ ] **Step 1: Écrire les tests**

Créer `tests/unitaires/65_entames_sauvegarde.luau` :

```lua
-- Sous-projet 6 : les bandes entamées dans la sauvegarde (une bande illisible est oubliée : le rouleau repart neuf) et
-- sur le serveur (jeter une bande, action limitée comme les autres).
local Sauvegarde = U.module("Sauvegarde")
local Commande = U.module("Commande")
local EtatAtelier = U.module("EtatAtelier")

local JUPE = { piece = "jupe_droite_devant", x = 2.5, y = 3, angle = 0 } -- [0, 5] × [0, 6]
local CORSAGE = { piece = "corsage_droit_devant", x = 9.6, y = 2.1, angle = 0 } -- [7,2, 12] × [0, 4,2]

---------------------------------------------------------------------------
-- Sauvegarde : la bande relue à l'identique ; son bas recalculé de ses trous
---------------------------------------------------------------------------
local e = EtatAtelier.nouveau(300)
e.stock = { coton_blanc = 20, soie_rouge = 3 }
e.entames = { coton_blanc = { bas = 6, trous = { JUPE, CORSAGE } } }
local relue = Sauvegarde.versEtat(M.transmettre(Sauvegarde.depuisEtat(e)))
local b = relue.entames.coton_blanc
U.verifier(b ~= nil and b.bas == 6 and #b.trous == 2 and b.trous[2].piece == "corsage_droit_devant" and b.trous[2].x == 9.6 and relue.entames.soie_rouge == nil, "bande entamée sauvée, relue telle quelle")
local partie = Sauvegarde.depuisEtat(e)
partie.entames.coton_blanc.bas = 99
U.verifier(Sauvegarde.versEtat(partie).entames.coton_blanc.bas == 6, "le bas de la bande est recalculé de ses trous")
partie.entames = nil
U.verifier(next(Sauvegarde.versEtat(partie).entames) == nil, "sans bandes (une partie d'avant) : des rouleaux neufs")

-- Bandes illisibles : oubliées une à une (le rouleau repart neuf, le stock reste)
local function trous(n) -- n corsages couchés, trois par rangée
	local out = {}
	for k = 0, n - 1 do
		table.insert(out, { piece = "corsage_droit_devant", x = 2.1 + 4.2 * (k % 3), y = 2.4 + 4.8 * (k // 3), angle = 90 })
	end
	return out
end
partie.stock = { coton_blanc = 20, soie_rouge = 3, lin_bleu = 60, velours_noir = 40, satin_rose = 40 }
partie.entames = {
	coton_blanc = { bas = 6, trous = { JUPE, { piece = "jupe_droite_dos", x = 4, y = 3, angle = 0 } } }, -- trous qui se chevauchent
	soie_rouge = { bas = 6, trous = { JUPE } }, -- plus bas que les 3 dm en stock
	lin_bleu = { bas = 44, trous = trous(25) }, -- plus de 24 trous
	velours_noir = "abîmée",
	satin_rose = { bas = 34, trous = trous(21) }, -- lisible
	tissu_inconnu = { bas = 6, trous = { JUPE } },
	toile_jute = { bas = 6, trous = { JUPE } }, -- pas en stock
}
local lue = Sauvegarde.versEtat(partie)
U.verifier(lue.entames.coton_blanc == nil and lue.entames.soie_rouge == nil and lue.entames.lin_bleu == nil and lue.entames.velours_noir == nil and lue.entames.tissu_inconnu == nil and lue.entames.toile_jute == nil, "trous qui se chevauchent, bande plus longue que le stock, plus de 24 trous, illisible, tissu inconnu ou absent : oubliées")
U.verifier(lue.entames.satin_rose ~= nil and #lue.entames.satin_rose.trous == 21 and lue.entames.satin_rose.bas == 34 and lue.stock.coton_blanc == 20 and lue.stock.lin_bleu == 60, "la bande lisible reste ; le stock reste entier")

-- Une robe au milieu de la découpe : son rouleau garde ses trous
local c = EtatAtelier.nouveau(1000)
U.commander(c, Random.new(4))
assert(c:validerCroquis({ corsage = "corsage_droit", manches = "manches_sans", col = "col_sans", jupe = "jupe_droite" }, { corsage_droit_devant = "coton_blanc", corsage_droit_dos = "coton_blanc", jupe_droite_devant = "coton_blanc", jupe_droite_dos = "coton_blanc" }).ok)
c.stock.coton_blanc = 30
c.entames.coton_blanc = { bas = 6, trous = { JUPE, CORSAGE } }
assert(c:commencerDecoupe().ok and c:couper("jupe_droite_dos", { x = 2.5, y = 9.1, angle = 0 }).ok)
local reprise = Sauvegarde.versEtat(M.transmettre(Sauvegarde.depuisEtat(c)))
U.verifier(reprise.etape == "decoupe" and #reprise.coupons.coton_blanc.trous == 2 and reprise.coupons.coton_blanc.poses.jupe_droite_dos ~= nil and not reprise.coupons.coton_blanc:verifier("corsage_droit_dos", { x = 9.6, y = 2.1, angle = 0 }), "reprise au milieu de la découpe : le rouleau garde ses trous et la pièce coupée")

---------------------------------------------------------------------------
-- Serveur : jeter une bande ; les arguments farfelus refusés proprement ; action limitée
---------------------------------------------------------------------------
local serveur = Commande.nouvelle()
local joueur = M.nouveauJoueur("Coupeuse")
local function appeler(action, ...)
	M.avancer(0.25)
	local r = serveur:traiter(joueur, action, ...)
	local ok, erreur = pcall(M.transmettre, r)
	U.verifier(ok, "réponse à « " .. tostring(action) .. " » transmissible (" .. tostring(erreur) .. ")")
	return r
end
local a = serveur:atelier(joueur).etat
U.commander(a, Random.new(6))
assert(a:validerCroquis({ corsage = "corsage_droit", manches = "manches_sans", col = "col_sans", jupe = "jupe_droite" }, { corsage_droit_devant = "coton_blanc", corsage_droit_dos = "coton_blanc", jupe_droite_devant = "coton_blanc", jupe_droite_dos = "coton_blanc" }).ok)
a.stock.coton_blanc = 20
a.entames.coton_blanc = { bas = 6, trous = { JUPE, CORSAGE } }
for k, arg in ipairs({ M.services.Workspace, { "coton_blanc" }, 0 / 0, "soie_rouge" }) do
	local r = appeler("jeterEntame", arg)
	U.verifier(not r.ok and r.erreur ~= "Action impossible." and a.entames.coton_blanc ~= nil and a.stock.coton_blanc == 20, "jeter farfelu refusé proprement (" .. k .. ") : " .. tostring(r.erreur))
end
local r = appeler("jeterEntame", "coton_blanc")
U.verifier(r.ok and r.dm == 6 and a.stock.coton_blanc == 14 and a.entames.coton_blanc == nil and r.etat.stock.coton_blanc == 14 and r.etat.entames.coton_blanc == nil, "la bande jetée sur le serveur : 6 dm de moins, l'état suit")
M.avancer(2)
local acceptes = 0
for _ = 1, 8 do
	if serveur:traiter(joueur, "jeterEntame", "coton_blanc").erreur ~= "Doucement !" then
		acceptes += 1
	end
end
U.verifier(acceptes == Commande.APPELS_PAR_SECONDE, "rafale : « jeterEntame » est limitée comme les autres actions (" .. acceptes .. " sur 8)")
```

- [ ] **Step 2: Lancer les tests, vérifier l'échec**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT|attempt|membre" | head -3`
Expected: échec : une ligne qui finit par `ÉCHEC : bande entamée sauvée, relue telle quelle`

- [ ] **Step 3: L'action et la sauvegarde**

Dans `src/server/Commande.luau`, remplacer :

```lua
	-- (sous-projet 6) la mercerie, achetée d'avance
	acheterMercerie = function(a, idAccessoire, quantite)
		return a.etat:acheterMercerie(idAccessoire, quantite)
	end,
```

par :

```lua
	-- (sous-projet 6) la mercerie, achetée d'avance
	acheterMercerie = function(a, idAccessoire, quantite)
		return a.etat:acheterMercerie(idAccessoire, quantite)
	end,
	-- (sous-projet 6) jeter la bande entamée d'un rouleau
	jeterEntame = function(a, idTissu)
		return a.etat:jeterEntame(idTissu)
	end,
```

Dans `src/server/Sauvegarde.luau`, remplacer :

```lua
local Recette = require(Couture:WaitForChild("Recette"))
```

par :

```lua
local Recette = require(Couture:WaitForChild("Recette"))
local Coupon = require(Couture:WaitForChild("Coupon"))
```

Dans `src/server/Sauvegarde.luau`, remplacer :

```lua
		mercerie = d.mercerie,
	}
```

par :

```lua
		mercerie = d.mercerie,
		entames = d.entames,
	}
```

Dans `src/server/Sauvegarde.luau`, remplacer :

```lua
	for id, dm in pairs(type(partie.stock) == "table" and partie.stock or {}) do
		if type(id) == "string" and Catalogue.tissu(id) and nombre(dm, -1) >= 0 then
			base.stock[id] = dm
		end
	end
```

par :

```lua
	for id, dm in pairs(type(partie.stock) == "table" and partie.stock or {}) do
		if type(id) == "string" and Catalogue.tissu(id) and nombre(dm, -1) >= 0 then
			base.stock[id] = dm
		end
	end
	-- Bandes entamées (sous-projet 6) : d'un tissu en stock, des trous lisibles (1 à 24), pas plus bas que le stock ; le
	-- bas est recalculé des trous. Une bande illisible est oubliée : le rouleau repart neuf, le stock reste
	for id, e in pairs(type(partie.entames) == "table" and partie.entames or {}) do
		local trous = type(id) == "string" and base.stock[id] and type(e) == "table" and Coupon.lireTrous(e.trous, Recette.LONGUEUR_MAX)
		if trous and #trous > 0 and #trous <= EtatAtelier.TROUS_MAX then
			local bas = Coupon.nouveau(Recette.LONGUEUR_MAX, trous):longueurUtilisee()
			if bas <= base.stock[id] then
				base.entames[id] = { bas = bas, trous = trous }
			end
		end
	end
```

- [ ] **Step 4: Lancer les tests**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT"`
Expected:
```
Unitaires : 167969 vérifications
TOUT EST VERT : 943 vérifications
```

- [ ] **Step 5: Commit**

```bash
git add src/server/Commande.luau src/server/Sauvegarde.luau tests/unitaires/65_entames_sauvegarde.luau
git commit -m "Tissu entamé : jeter une bande sur le serveur ; les bandes dans la sauvegarde (une bande illisible est oubliée)

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 4: La table, l'achat, le carnet

**Files:**
- Modify: `src/client/Atelier/TableDecoupe.luau`, `src/client/Atelier/EcranDecoupe.luau`, `src/client/Atelier/EcranAchat.luau`, `src/client/Atelier/EcranCarnet.luau`, `src/client/Atelier/init.client.luau`
- Create: `tests/unitaires/66_table_trous.luau`
- Modify: `tests/scenario.luau`

**Interfaces:**
- Consumes: `coupon.trous` (tâche 1) ; `etat.entames`, `etat:stockNeuf`, `etat:stocksNeufs`, `reponse.jetees` (tâche 2).
- Produces: sur le rouleau, `Trou_<k>` (dans `Coupees`) ; à l'achat, le texte `Infos` de chaque ligne ; l'annonce d'une bande jetée (message sous la fenêtre).

- [ ] **Step 1: Écrire les tests**

Créer `tests/unitaires/66_table_trous.luau` :

```lua
-- Sous-projet 6 : à la table, un rouleau entamé. « Proposer » cherche aussi contre les bords des trous : dans un vide
-- de la bande s'il y en a un assez grand, sinon dessous.
local Session = U.module("Session")
local TableDecoupe = U.module("TableDecoupe")

local CROQUIS = { corsage = "corsage_droit", manches = "manches_sans", col = "col_montant", jupe = "jupe_droite" }
local function aLaTable(entame, stock)
	local session = Session.nouvelle(21)
	U.commander(session)
	assert(session:validerCroquis(CROQUIS, { corsage_droit_devant = "coton_blanc", corsage_droit_dos = "coton_blanc", col_montant = "coton_blanc", jupe_droite_devant = "coton_blanc", jupe_droite_dos = "coton_blanc" }).ok)
	session.etat.stock.coton_blanc = stock
	session.etat.entames.coton_blanc = entame
	assert(session:commencerDecoupe().ok)
	return session, TableDecoupe.nouvelle(session.etat)
end

-- Un trou de jupe en haut à gauche : à côté, un vide de 9 dm sur 6 ; dessous, du tissu neuf
local session, t = aLaTable({ bas = 6, trous = { { piece = "jupe_droite_devant", x = 2.5, y = 3, angle = 0 } } }, 30)
U.verifier(t.selection == "jupe_droite_devant" and t:etatPlacement().valide and t.placement.y < 6, "la première jupe est proposée dans le vide, à côté du trou")
local coupees = 0
while t.selection and coupees < 5 do
	local e = t:etatPlacement()
	U.verifier(e.valide, "place proposée valide pour " .. t.selection .. " (" .. tostring(e.erreur) .. ")")
	assert(t:couper(session).ok)
	coupees += 1
end
U.verifier(coupees == 5 and session.etat.etape == "epinglage", "les cinq pièces coupées aux places proposées, sans passer sur le trou")

-- Une bande pleine de trous en haut du rouleau : tout est proposé dessous
local trous = {}
for k = 0, 5 do
	table.insert(trous, { piece = "corsage_droit_devant", x = 2.1 + 4.2 * (k % 3), y = 2.4 + 4.8 * (k // 3), angle = 90 })
end
local session2, t2 = aLaTable({ bas = 10, trous = trous }, 40)
U.verifier(t2:etatPlacement().valide and t2.placement.y > 9.6, "sous une bande pleine, la première pièce est proposée dessous")
U.verifier(session2.etat.coupons.coton_blanc:longueurUtilisee() == 10, "(la bande : 10 dm)")
```

Dans `tests/scenario.luau`, remplacer :

```lua
cliquer("Valider")
verifier(titre() == "2. Achat du tissu", "robe en six tissus : à l'achat")
```

par :

```lua
do -- (sous-projet 6) Le coton blanc est entamé par une robe d'avant : ses 6 dm en stock, tous entamés (deux trous). Au
	-- carnet, le tissu à acheter ne compte que le tissu neuf
	local s = serveur:atelier(joueur).etat
	local function aAcheter()
		M.avancer(0.5)
		SessionModule.courante:actualiser()
		return tonumber(fenetre.Contenu.Droite.Metrage.Text:match("^Tissu à acheter : (%d+) dm"))
	end
	s.stock.coton_blanc, s.entames.coton_blanc = 6, nil
	local neuf = aAcheter()
	s.entames.coton_blanc = { bas = 6, trous = { { piece = "jupe_droite_devant", x = 2.5, y = 3, angle = 0 }, { piece = "corsage_droit_devant", x = 9.6, y = 2.1, angle = 0 } } }
	local entame = aAcheter()
	local conseilCoton = requireModule(dossier.Metrage).conseil({ "corsage_v_devant" })
	verifier(neuf ~= nil and entame == neuf + math.min(6, conseilCoton), ("au carnet, 6 dm de coton tout entamés ne comptent pas : %s dm à acheter au lieu de %s"):format(tostring(entame), tostring(neuf)))
end
cliquer("Valider")
verifier(titre() == "2. Achat du tissu", "robe en six tissus : à l'achat")
do -- L'achat du coton blanc : le conseil ne compte que le tissu neuf
	local l = fenetre.Contenu.Lignes.Ligne_coton_blanc
	local conseilCoton = tonumber(l.Infos.Text:match("^Conseillé : (%d+) dm"))
	verifier(conseilCoton ~= nil and l.Infos.Text == ("Conseillé : %d dm · Neuf : 0 dm (6 entamés)"):format(conseilCoton) and l.Quantite.Text == conseilCoton .. " dm", "coton blanc tout entamé : la quantité proposée est le conseil entier (" .. l.Infos.Text .. ")")
end
```

Dans `tests/scenario.luau`, remplacer :

```lua
verifier(nbOnglets == 6 and ongletsDecoupe.CanvasSize.X.Offset >= finOnglets, "six onglets, tous atteignables")
```

par :

```lua
verifier(nbOnglets == 6 and ongletsDecoupe.CanvasSize.X.Offset >= finOnglets, "six onglets, tous atteignables")
do -- (sous-projet 6) Le rouleau de coton blanc entamé : ses trous sont dessinés, « Proposer » les évite
	cliquer("Onglet_coton_blanc")
	local trousVus = 0
	for _, d in ipairs(fenetre.Contenu.Rouleau.Tissu.Coupees:GetChildren()) do
		trousVus += if d.Name:match("^Trou_") then 1 else 0
	end
	local c = SessionModule.courante.etat.coupons.coton_blanc
	cliquer("Proposer")
	verifier(trousVus == 2 and fenetre.Contenu.Panneau.Statut.Text == "Place libre : tu peux couper." and fenetre.Contenu.Panneau.InfoRouleau.Text == ("Entamé : 6 / %d dm"):format(c.longueur), "coton blanc entamé : deux trous dessinés, « Proposer » trouve une place libre, 6 dm entamés (" .. fenetre.Contenu.Panneau.Statut.Text .. ")")
	-- Une bande jetée d'elle-même (plus de 24 trous) est annoncée
	SessionModule.courante.annonce("couper", { ok = true, jetees = { { tissu = "coton_blanc", dm = 13 } } })
	verifier(fenetre.Message.Visible and fenetre.Message.Text == "Trop de trous : la bande entamée est jetée (Coton blanc, 1,30 m).", "une bande jetée d'elle-même est annoncée")
end
```

- [ ] **Step 2: Lancer les tests, vérifier l'échec**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT|attempt|membre" | head -3`
Expected: échec : une ligne qui finit par `ÉCHEC : la première jupe est proposée dans le vide, à côté du trou`

- [ ] **Step 3: La table, l'achat, le carnet, l'annonce**

Dans `src/client/Atelier/TableDecoupe.luau`, remplacer :

```lua
-- Place proposée : la première place libre, du haut du rouleau vers le bas puis de gauche à droite,
-- contre les bords des pièces déjà coupées, au droit-fil parfait. À défaut : sous tout le reste.
```

par :

```lua
-- Place proposée : la première place libre, du haut du rouleau vers le bas puis de gauche à droite,
-- contre les bords des pièces déjà coupées et des trous du tissu entamé, au droit-fil parfait. À défaut : sous tout
-- le reste.
```

Dans `src/client/Atelier/TableDecoupe.luau`, remplacer :

```lua
	local xs, ys = { 0 }, { 0 }
	local bas = 0
	for idCoupee, pose in pairs(coupon.poses) do
		for _, contour in ipairs(Coupon.contoursPoses(idCoupee, pose)) do
			local b = Polygone.boite(contour)
			table.insert(xs, b.maxX + Metrage.MARGE)
			table.insert(ys, b.maxY + Metrage.MARGE)
			bas = math.max(bas, b.maxY + Metrage.MARGE)
		end
	end
```

par :

```lua
	local xs, ys = { 0 }, { 0 }
	local bas = 0
	local prises = {}
	for idCoupee, pose in pairs(coupon.poses) do
		table.insert(prises, { idCoupee, pose })
	end
	for _, trou in ipairs(coupon.trous) do
		table.insert(prises, { trou.piece, trou })
	end
	for _, p in ipairs(prises) do
		for _, contour in ipairs(Coupon.contoursPoses(p[1], p[2])) do
			local b = Polygone.boite(contour)
			table.insert(xs, b.maxX + Metrage.MARGE)
			table.insert(ys, b.maxY + Metrage.MARGE)
			bas = math.max(bas, b.maxY + Metrage.MARGE)
		end
	end
```

Dans `src/client/Atelier/EcranDecoupe.luau`, remplacer :

```lua
-- Écran de la table de découpe : le rouleau vu de dessus (motif du tissu, pli, pièces déjà coupées,
-- tissu entamé), la pièce sélectionnée à glisser à la souris ou au doigt, la rotation (boutons, R, molette
```

par :

```lua
-- Écran de la table de découpe : le rouleau vu de dessus (motif du tissu, pli, pièces déjà coupées, trous
-- laissés par les robes d'avant, tissu entamé), la pièce sélectionnée à glisser à la souris ou au doigt, la rotation (boutons, R, molette
```

Dans `src/client/Atelier/EcranDecoupe.luau`, remplacer :

```lua
	-- Tissu entamé : couper consomme le rouleau jusqu'au bas de la pièce la plus basse
```

par :

```lua
	-- Tissu entamé : jusqu'au bas de la pièce (ou du trou) le plus bas
```

Dans `src/client/Atelier/EcranDecoupe.luau`, remplacer :

```lua
		-- Pièces déjà coupées dans ce tissu (et leur symétrique si elles sont pliées ; le symétrique
		-- est approché par la même silhouette tournée en sens inverse)
		calque:ClearAllChildren()
		for id, p in pairs(etat.coupees) do
			if etat.tissus[id] == table_.tissu then
				local copies = { { x = p.x, angle = p.angle } }
				if Catalogue.piece(id).pliee then
					table.insert(copies, { x = 2 * Catalogue.PLI - p.x, angle = -p.angle })
				end
				for _, c in ipairs(copies) do
					local img = UiKit.creer("ImageLabel", {
						Name = "Coupee_" .. id,
						BackgroundTransparency = 1,
						AnchorPoint = Vector2.new(0.5, 0.5),
						Position = UDim2.fromOffset(c.x * PX, p.y * PX),
						Size = taillePiece(id),
						Rotation = c.angle,
						ImageColor3 = Color3.fromRGB(120, 120, 120),
						ImageTransparency = 0.3,
						ZIndex = 4,
						Parent = calque,
					})
					local silhouette = Vignettes.silhouette(id)
					if silhouette then
						img.ImageContent = silhouette
					else
						img.BackgroundColor3 = Color3.fromRGB(120, 120, 120)
						img.BackgroundTransparency = 0.5
					end
				end
			end
		end
```

par :

```lua
		-- Pièces déjà coupées dans ce tissu, en gris, et les trous laissés par les robes d'avant, plus sombres (avec le
		-- symétrique d'une pièce pliée, approché par la même silhouette tournée en sens inverse)
		calque:ClearAllChildren()
		local function griser(nom, id, p, gris)
			local copies = { { x = p.x, angle = p.angle } }
			if Catalogue.piece(id).pliee then
				table.insert(copies, { x = 2 * Catalogue.PLI - p.x, angle = -p.angle })
			end
			for _, c in ipairs(copies) do
				local img = UiKit.creer("ImageLabel", {
					Name = nom,
					BackgroundTransparency = 1,
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.fromOffset(c.x * PX, p.y * PX),
					Size = taillePiece(id),
					Rotation = c.angle,
					ImageColor3 = gris,
					ImageTransparency = 0.3,
					ZIndex = 4,
					Parent = calque,
				})
				local silhouette = Vignettes.silhouette(id)
				if silhouette then
					img.ImageContent = silhouette
				else
					img.BackgroundColor3 = gris
					img.BackgroundTransparency = 0.5
				end
			end
		end
		for id, p in pairs(etat.coupees) do
			if etat.tissus[id] == table_.tissu then
				griser("Coupee_" .. id, id, p, Color3.fromRGB(120, 120, 120))
			end
		end
		for k, trou in ipairs(coupon.trous) do
			griser("Trou_" .. k, trou.piece, trou, Color3.fromRGB(70, 66, 66))
		end
```

Dans `src/client/Atelier/EcranAchat.luau`, remplacer :

```lua
	local function majLigne(idTissu)
		local l = lignes[idTissu]
		local stock = etat.stock[idTissu] or 0
		local q = quantites[idTissu]
		l.infos.Text = ("Conseillé : %d dm · En stock : %d dm"):format(conseil(idTissu), stock)
```

par :

```lua
	local function majLigne(idTissu)
		local l = lignes[idTissu]
		local stock = etat.stock[idTissu] or 0
		local entame = etat.entames[idTissu]
		local q = quantites[idTissu]
		-- (sous-projet 6) un rouleau entamé : le tissu neuf, et ce qui est entamé en haut du rouleau
		l.infos.Text = if entame
			then ("Conseillé : %d dm · Neuf : %d dm (%d entamés)"):format(conseil(idTissu), etat:stockNeuf(idTissu), entame.bas)
			else ("Conseillé : %d dm · En stock : %d dm"):format(conseil(idTissu), stock)
```

Dans `src/client/Atelier/EcranAchat.luau`, remplacer :

```lua
		stocksVus[idTissu] = etat.stock[idTissu] or 0
		quantites[idTissu] = math.max(0, conseil(idTissu) - stocksVus[idTissu])
```

par :

```lua
		stocksVus[idTissu] = etat:stockNeuf(idTissu)
		quantites[idTissu] = math.max(0, conseil(idTissu) - stocksVus[idTissu])
```

Dans `src/client/Atelier/EcranAchat.luau`, remplacer :

```lua
		local l = { infos = UiKit.texte({ TextSize = 14, TextColor3 = C.texteDoux,
```

par :

```lua
		local l = { infos = UiKit.texte({ Name = "Infos", TextSize = 14, TextColor3 = C.texteDoux,
```

Dans `src/client/Atelier/EcranAchat.luau`, remplacer :

```lua
	-- Le stock change (achat, ou état réparé par le serveur) : la quantité proposée est ce qui manque encore
	local desabonner = session:surChangement(function()
		for idTissu in pairs(lignes) do
			local stock = etat.stock[idTissu] or 0
			if stock ~= stocksVus[idTissu] then
```

par :

```lua
	-- Le stock change (achat, bande jetée, ou état réparé par le serveur) : la quantité proposée est ce qui manque
	-- encore en tissu neuf
	local desabonner = session:surChangement(function()
		for idTissu in pairs(lignes) do
			local stock = etat:stockNeuf(idTissu)
			if stock ~= stocksVus[idTissu] then
```

Dans `src/client/Atelier/EcranAchat.luau`, remplacer :

```lua
-- Écran d'achat : pour chaque tissu du croquis, métrage conseillé, stock, quantité à acheter et coût.
```

par :

```lua
-- Écran d'achat : pour chaque tissu du croquis, métrage conseillé, stock (le tissu neuf, s'il est entamé), quantité à
-- acheter et coût.
```

Dans `src/client/Atelier/EcranCarnet.luau`, remplacer :

```lua
		-- Tissu à acheter (le stock compte) et son coût
		local aAcheter, dm = Metrage.aAcheter(pieces, tissus, etat.stock)
```

par :

```lua
		-- Tissu à acheter (le stock neuf compte, pas la bande entamée) et son coût
		local aAcheter, dm = Metrage.aAcheter(pieces, tissus, etat:stocksNeufs())
```

Dans `src/client/Atelier/init.client.luau`, remplacer :

```lua
local Chat = require(script:WaitForChild("Chat"))
```

par :

```lua
local Chat = require(script:WaitForChild("Chat"))
local Mercerie = require(script:WaitForChild("Mercerie"))
local Catalogue = require(Couture:WaitForChild("Catalogue"))
```

Dans `src/client/Atelier/init.client.luau`, remplacer :

```lua
session:surAction(function(nom, reponse)
	if nom == "rendreCouture" and session.etat.etape == "decorations" then
```

par :

```lua
session:surAction(function(nom, reponse)
	-- (sous-projet 6) une bande entamée jetée d'elle-même, au-delà de 24 trous : on le dit
	if reponse.jetees then
		local bandes = {}
		for _, j in ipairs(reponse.jetees) do
			table.insert(bandes, ("%s, %s m"):format(Catalogue.tissu(j.tissu).nom, Mercerie.metres(j.dm * 10)))
		end
		afficherMessage(("Trop de trous : la bande entamée est jetée (%s)."):format(table.concat(bandes, " ; ")), C.texteDoux, 6)
	end
	if nom == "rendreCouture" and session.etat.etape == "decorations" then
```

- [ ] **Step 4: Lancer les tests**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT"`
Expected:
```
Unitaires : 167978 vérifications
TOUT EST VERT : 949 vérifications
```

- [ ] **Step 5: Commit**

```bash
git add src/client/Atelier/TableDecoupe.luau src/client/Atelier/EcranDecoupe.luau src/client/Atelier/EcranAchat.luau src/client/Atelier/EcranCarnet.luau src/client/Atelier/init.client.luau tests/unitaires/66_table_trous.luau tests/scenario.luau
git commit -m "Table de découpe : les trous du tissu entamé grisés, « Proposer » les évite ; l'achat et le carnet comptent le tissu neuf

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 5: Studio, README, lieu régénéré

**Files:**
- Modify: `README.md`, `AtelierCouture.rbxl` (régénéré)

**Interfaces:**
- Consumes: tout ce qui précède.
- Produces: rien de nouveau.

- [ ] **Step 1: Dans Studio, par le connecteur MCP**

Construire le lieu du dépôt dans un dossier temporaire (`C:/dev/jeux/roblox-maker/rojo.exe build -o <dossier temporaire>/Plan17Depot.rbxl`) et l'ouvrir dans Studio. En édition (`execute_luau`, Edit), rendre l'écran de la table dans un `ScreenGui` de `StarterGui` avec un faux contexte (une session dont l'état, créé par `EtatAtelier`, est à la découpe d'une robe droite en coton blanc : 30 dm en stock, et la bande de quatre trous d'une robe droite en haut du rouleau) ; faire défiler le rouleau en haut et capturer. Puis en Play : attendre 4 s, capturer l'accueil, relever la console.

Expected : les quatre trous en gris foncé en haut du rouleau, « Entamé : 11 / 30 dm », la pièce proposée sous la bande ; en Play, l'accueil s'affiche ; aucune alerte de notre code (« Lieu non publié » et les messages internes de Roblox mis à part). Arrêter Play, retirer le `ScreenGui` d'essai et fermer cette fenêtre de Studio (sans enregistrer).

- [ ] **Step 2: Mettre à jour le README**

Dans `README.md`, remplacer :

```markdown
## État actuel (sous-projet 6 en cours, plans 15 et 16 : les mesures à molettes, la mercerie)
```

par :

```markdown
## État actuel (sous-projet 6 en cours, plans 15 à 17 : les mesures à molettes, la mercerie, le tissu entamé)
```

Dans `README.md`, remplacer :

```markdown
3. **Achat** : métrage conseillé par tissu, quantité réglable, coût au mètre ; toucher l'échantillon d'un tissu
   montre le rouleau conseillé, avec les pièces rangées dessus.
```

par :

```markdown
3. **Achat** : métrage conseillé par tissu, quantité réglable, coût au mètre ; toucher l'échantillon d'un tissu
   montre le rouleau conseillé, avec les pièces rangées dessus. Pour un rouleau entamé, la quantité proposée ne
   compte que le tissu neuf (« Neuf : 9 dm (11 entamés) »).
```

Dans `README.md`, remplacer :

```markdown
   pièces pliées coupées en double au pli, chevauchements refusés, place proposée ; une ligne marque le tissu
   entamé (couper consomme le rouleau jusqu'au bas de la pièce la plus basse).
```

par :

```markdown
   pièces pliées coupées en double au pli, chevauchements refusés, place proposée ; une ligne marque le tissu
   entamé. **Le tissu entamé** : les pièces coupées laissent leurs trous dans une bande en haut du rouleau, qui reste
   dans le stock ; à la robe suivante dans ce tissu, les trous sont grisés et interdits, on coupe dans leurs vides
   ou dessous (« Proposer une place » les évite). Au-delà de 24 trous, la bande est jetée d'elle-même (elle quitte
   alors le stock), et on l'annonce. Une robe libre compte en matières ce qu'elle ajoute à la bande.
```

Dans `README.md`, remplacer :

```markdown
« Recommencer la robe » (le tissu coupé et les décorations posées sont perdus) et « Livrer la robe »
```

par :

```markdown
« Recommencer la robe » (les décorations posées sont perdues ; le tissu coupé reste en trous sur le rouleau) et
« Livrer la robe »
```

- [ ] **Step 3: Tests, lieu régénéré, commit**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT"`
Expected:
```
Unitaires : 167978 vérifications
TOUT EST VERT : 949 vérifications
```

```bash
C:/dev/jeux/roblox-maker/rojo.exe build -o AtelierCouture.rbxl
git add README.md AtelierCouture.rbxl
git commit -m "Plan 17 terminé : le tissu entamé

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```
