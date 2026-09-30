# Aiguille & Dentelle — Plan 15 : les mesures à molettes

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Prendre les mesures comme dans *Dressmaker* : un mannequin de couture à trois molettes (poitrine, taille, hanches), la silhouette de la cliente en pointillé par-dessus ; on tourne les molettes jusqu'à ce que le mannequin l'épouse.

**Architecture:** un module client pur `Molette` (du glissement aux crans de 0,1 dm, reste gardé, bornes) ; `EcranMesures` réécrit autour d'un mannequin 2D (bandes arrondies, mètre ruban), d'un calque en pointillé à la vraie silhouette et de trois molettes (glisser, molette de la souris, − / +). La règle ne change pas : `EtatAtelier:mesurer` (1,5 dm d'écart au plus), `reprendreMesures`, `Notation.ajustement` ; seul le message de refus parle de molettes.

**Tech Stack:** Luau, Rojo 7.7.0-rc.1, simulation Luau 0.650 (`tests/lancer.sh`), Roblox Studio via le connecteur MCP Studio.

**Spec:** `docs/superpowers/specs/2026-09-30-atelier-fidele-design.md` (section 2 ; plan 15 de la section 6).

## Décisions de ce plan

- **Glisser** : vers le haut, la molette augmente ; un cran tous les 12 px (à l'échelle de la fenêtre), le reste est gardé d'un glissement à l'autre ; en butée, le glissement en trop est oublié. La molette de la souris agit sur la molette survolée ; − et + restent (0,1 dm).
- **Bornes** : de 2 dm au plus large que le cadre du mannequin permet (14,2 dm) : le mannequin ne sort jamais de son cadre.
- **Silhouette** : en pointillé (points de 3 px tous les 10 px) sur ses bords gauche et droit, à chaque mesure, par-dessus le mannequin ; le mannequin part à 70 % de la taille de la cliente (il faut vraiment mesurer).
- **Fiche** : pour une cliente déjà mesurée, « Au carnet : 89 / 71 / 95 cm (ajustement 100 %) » et « Reprendre ses mesures » ; rien pour une nouvelle cliente (la silhouette reste le défi).
- **Noms gardés** : `Valeur_<mesure>`, `Moins_<mesure>`, `Plus_<mesure>`, `ValiderMesures`, `ReprendreMesures` ; nouveaux : `Mannequin` (et ses `Corps_`, `Ruban_`, `Calque_`), `Molette_<mesure>` (et sa `Fente`), `FicheCarnet`.
- **Vérifié pendant la préparation** : le plan a été joué entièrement sur un brouillon tiré de `main` ; dix variantes du brouillon (reste oublié, sens inversé, butée élastique, fente immobile, second doigt, molette de souris partout, silhouette sans pointillé, mannequin hors du cadre, fiche absente, mesures mélangées) échouent chacune sur la vérification qui les garde ; l'écran a été rendu dans Studio (bandes arrondies ajoutées après l'avoir vu).

## Global Constraints

- **Dépôt** : `C:\dev\jeux\atelier-couture`, branche `mesures-molettes`, créée depuis `main` (où le plan 14 est fusionné). Selon les règles du commanditaire : la branche testée et relue est fusionnée dans `main` et poussée sur GitHub.
- **Rojo** : `C:/dev/jeux/roblox-maker/rojo.exe`.
- **Contenu original** : aucun nom, texte, image ni son de *Dressmaker*.
- **Contraintes des plans précédents toujours valables** : fins de ligne LF, commits en français terminés par `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`, textes d'au moins 14 px, le serveur fait foi.

## Review Focus

- **Deux doigts sur l'écran.** Attendu : seul le doigt qui a pris la molette la tourne ; levé, il ne la tourne plus. Test : scénario (« un second doigt », « doigt levé »).
- **Petits glissements successifs.** Attendu : ils s'additionnent (7 + 7 px font un cran). Test : `60_molette`.
- **Molette tournée au-delà de sa borne.** Attendu : butée, le mannequin reste dans son cadre, et un cran en arrière redescend aussitôt. Tests : `60_molette`, scénario (« tournée trop loin »).
- **Molette de la souris hors d'une molette.** Attendu : rien ne tourne. Test : scénario (« pointeur ailleurs »).
- **Cliente déjà mesurée.** Attendu : ses mesures du carnet, et « Reprendre ses mesures ». Test : scénario (« ses mesures du carnet »).

---

### Task 1: La molette (`Molette`)

**Files:**
- Create: `src/client/Atelier/Molette.luau`
- Create: `tests/unitaires/60_molette.luau`

**Interfaces:**
- Consumes: rien.
- Produces: `Molette.nouvelle(valeur, mini, maxi)`, `molette:crans(n)`, `molette:glisser(dy)`, `molette:regler(valeur)`, `molette:angle()`, `molette.valeur` ; `Molette.PX_PAR_CRAN` (12), `Molette.CRAN` (0,1), `Molette.DEGRES_PAR_CRAN` (15).

- [ ] **Step 1: Écrire les tests**

Créer `tests/unitaires/60_molette.luau` :

```lua
-- Sous-projet 6 : les mesures se prennent en tournant trois molettes sur un mannequin. Une molette : un cran de
-- 0,1 dm tous les 12 px de glissement (vers le haut, elle augmente), entre deux bornes.
local Molette = U.module("Molette")

local m = Molette.nouvelle(6.2, 2, 14)
U.verifier(m.valeur == 6.2, "une molette part de sa valeur")
U.verifier(m:crans(1) == 6.3 and m:crans(-3) == 6, "un cran : 0,1 dm, dans les deux sens")
U.verifier(m:glisser(-12) == 6.1, "glisser de 12 px vers le haut : un cran de plus")
U.verifier(m:glisser(24) == 5.9, "glisser de 24 px vers le bas : deux crans de moins")
-- Le reste est gardé : deux petits glissements de 7 px font un cran (14 px), pas zéro
m:glisser(-7)
U.verifier(m.valeur == 5.9, "7 px : pas encore un cran")
U.verifier(m:glisser(-7) == 6, "7 px de plus : un cran (le reste était gardé)")
-- Des valeurs toujours au dixième près, quel que soit le nombre de crans
for _ = 1, 37 do
	m:crans(1)
end
U.verifier(m.valeur == 9.7 and math.abs(m.valeur * 10 - math.round(m.valeur * 10)) < 1e-9, "au dixième près après 37 crans (" .. m.valeur .. ")")
-- Les bornes : butée, et le glissement en trop est oublié
U.verifier(m:glisser(-12 * 100) == 14, "tournée trop loin : s'arrête à sa borne haute")
U.verifier(m:glisser(12) == 13.9, "en butée, le glissement en trop ne compte pas : un cran vers le bas redescend tout de suite")
U.verifier(m:glisser(12 * 500) == 2 and m:crans(-1) == 2, "borne basse")
-- Régler directement (reprendre les mesures) ; la fente tourne avec la molette
local r = Molette.nouvelle(6, 2, 14)
U.verifier(r:regler(8.93) == 8.9 and r:regler(40) == 14, "régler directement : au dixième, dans les bornes")
local f = Molette.nouvelle(6, 2, 14)
f:crans(2)
U.verifier(f:angle() == 2 * Molette.DEGRES_PAR_CRAN, "la fente tourne d'un angle fixe par cran")
f:crans(-5)
U.verifier(f:angle() == -3 * Molette.DEGRES_PAR_CRAN, "et revient en arrière")
```

- [ ] **Step 2: Lancer les tests, vérifier l'échec**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT|attempt|membre" | head -3`
Expected: échec : une ligne qui finit par `Molette n'est pas un membre valide de Folder « Couture »`

- [ ] **Step 3: Écrire le module**

Créer `src/client/Atelier/Molette.luau` :

```lua
-- Molette (sous-projet 6) : le réglage d'une mesure du mannequin par une molette qu'on fait tourner. Glisser vers le
-- haut l'augmente, vers le bas la diminue : un cran de 0,1 dm tous les PX_PAR_CRAN pixels (le reste est gardé pour
-- le glissement suivant) ; la molette de la souris et les boutons − / + avancent d'un cran. La valeur reste entre
-- ses bornes ; butée contre une borne, le glissement en trop est oublié.
local Molette = {}
Molette.__index = Molette

Molette.PX_PAR_CRAN = 12
Molette.CRAN = 0.1 -- dm de tour
Molette.DEGRES_PAR_CRAN = 15 -- la fente de la molette tourne d'autant à chaque cran

local function arrondi(v)
	return math.round(v * 10) / 10
end

function Molette.nouvelle(valeur, mini, maxi)
	return setmetatable({ valeur = math.clamp(arrondi(valeur), mini, maxi), mini = mini, maxi = maxi, reste = 0, tours = 0 }, Molette)
end

-- Avance de n crans (négatif : recule) ; renvoie la nouvelle valeur
function Molette:crans(n)
	local avant = self.valeur
	self.valeur = math.clamp(arrondi(self.valeur + n * Molette.CRAN), self.mini, self.maxi)
	self.tours += math.round((self.valeur - avant) / Molette.CRAN)
	return self.valeur
end

-- Un glissement de dy pixels (vers le bas positif, comme à l'écran) ; renvoie la nouvelle valeur
function Molette:glisser(dy)
	self.reste -= dy
	local n = if self.reste >= 0 then math.floor(self.reste / Molette.PX_PAR_CRAN) else -math.floor(-self.reste / Molette.PX_PAR_CRAN)
	self.reste -= n * Molette.PX_PAR_CRAN
	self:crans(n)
	if self.valeur == self.mini or self.valeur == self.maxi then
		self.reste = 0 -- en butée : le glissement en trop ne compte pas
	end
	return self.valeur
end

-- Règle directement (reprendre des mesures)
function Molette:regler(valeur)
	self.valeur = math.clamp(arrondi(valeur), self.mini, self.maxi)
	self.reste = 0
	return self.valeur
end

-- L'angle de la fente (degrés) : elle tourne avec la molette
function Molette:angle()
	return self.tours * Molette.DEGRES_PAR_CRAN
end

return Molette
```

- [ ] **Step 4: Lancer les tests**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT"`
Expected:
```
Unitaires : 167854 vérifications
TOUT EST VERT : 837 vérifications
```

- [ ] **Step 5: Commit**

```bash
git add src/client/Atelier/Molette.luau tests/unitaires/60_molette.luau
git commit -m "Molette : régler une mesure en tournant, un cran de 0,1 dm tous les 12 px, entre deux bornes

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 2: Le mannequin à molettes (`EcranMesures`)

**Files:**
- Modify: `src/client/Atelier/EcranMesures.luau` (réécrit), `src/shared/EtatAtelier.luau` (message de refus)
- Modify: `tests/scenario.luau`, `tests/unitaires/28_commande_serveur.luau`

**Interfaces:**
- Consumes: `Molette` (tâche 1) ; `session:mesurer`, `session:reprendreMesures`, `Clientes.get`, `Catalogue.TAILLES` (existants).
- Produces: dans `fenetre.Contenu` : `Consigne`, `Mannequin` (`Corps_<mesure>`, `Ruban_<mesure>`, `Calque_<mesure>` et ses `Point`), `Molette_<mesure>` (`Fente`), `Valeur_<mesure>`, `Moins_<mesure>`, `Plus_<mesure>`, `ValiderMesures`, `FicheCarnet`, `ReprendreMesures`.

- [ ] **Step 1: Écrire les tests**

Dans `tests/unitaires/28_commande_serveur.luau`, remplacer :

```lua
r.erreur == "Mesure invalide : règle chaque ruban au bord de la silhouette." 
```

par :

```lua
r.erreur == "Mesure invalide : tourne chaque molette jusqu'à épouser sa silhouette." 
```

Dans `tests/scenario.luau`, remplacer :

```lua
fenetre.Message.Text == "Mesure invalide : règle chaque ruban au bord de la silhouette.", "rubans pas réglés : mesures refusées, message")
```

par :

```lua
fenetre.Message.Text == "Mesure invalide : tourne chaque molette jusqu'à épouser sa silhouette.", "molettes pas réglées : mesures refusées, message")
```

Dans `tests/scenario.luau`, remplacer :

```lua
-- Au doigt : on glisse la poignée du ruban de la poitrine jusqu'au bord de la silhouette ; un second doigt ne
-- tire pas le ruban, et le doigt levé ne le tire plus
local silhouetteM = fenetre.Contenu.Silhouette
local justePoitrine = ("Poitrine : %d cm"):format(math.round(Clientes.get("colette").mesures.poitrine * 10))
local doigtRuban = { UserInputType = Enum.UserInputType.Touch, Position = Vector3.new(0, 0, 0) }
silhouetteM.Poignee_poitrine.InputBegan:Fire(doigtRuban)
local valeurAvant = texte("Valeur_poitrine").Text
M.services.UserInputService.InputChanged:Fire({ UserInputType = Enum.UserInputType.Touch, Position = Vector3.new(900, 0, 0) })
verifier(texte("Valeur_poitrine").Text == valeurAvant, "un second doigt ne tire pas le ruban")
doigtRuban.Position = Vector3.new(silhouetteM.Ruban_poitrine.AbsolutePosition.X + silhouetteM.Corps_poitrine.Size.X.Offset, 0, 0)
M.services.UserInputService.InputChanged:Fire(doigtRuban)
M.services.UserInputService.InputEnded:Fire(doigtRuban)
verifier(texte("Valeur_poitrine").Text == justePoitrine, "glisser la poignée au doigt jusqu'au bord de la silhouette : la mesure juste")
doigtRuban.Position = Vector3.new(0, 0, 0)
M.services.UserInputService.InputChanged:Fire(doigtRuban)
verifier(texte("Valeur_poitrine").Text == justePoitrine, "doigt levé : le ruban ne bouge plus")
-- La poignée est assez grosse pour le doigt ; tirée trop loin, le ruban s'arrête au bord du cadre
verifier(silhouetteM.Poignee_poitrine.AbsoluteSize.X >= 40 and silhouetteM.Poignee_poitrine.AbsoluteSize.Y >= 40, "poignée d'au moins 40 px (le doigt)")
silhouetteM.Poignee_poitrine.InputBegan:Fire(doigtRuban)
doigtRuban.Position = Vector3.new(2000, 0, 0)
M.services.UserInputService.InputChanged:Fire(doigtRuban)
M.services.UserInputService.InputEnded:Fire(doigtRuban)
local rubanP = silhouetteM.Ruban_poitrine
verifier(rubanP.Position.X.Offset + rubanP.Size.X.Offset <= silhouetteM.Size.X.Offset, "tiré trop loin : le ruban s'arrête au bord du cadre")
```

par :

```lua
-- Sous-projet 6 : le mannequin à molettes. La silhouette de la cliente est en pointillé par-dessus le mannequin
local mannequinM = fenetre.Contenu:FindFirstChild("Mannequin")
local function lue(cle)
	return tonumber(texte("Valeur_" .. cle).Text:match("(%d+) cm")) / 10
end
do
	local calque = mannequinM and mannequinM:FindFirstChild("Calque_poitrine")
	local points = 0
	for _, p in ipairs(calque and calque:GetChildren() or {}) do
		points += if p.Name == "Point" then 1 else 0
	end
	verifier(calque ~= nil and calque.BackgroundTransparency == 1 and points >= 12, "la silhouette de la cliente, en pointillé par-dessus le mannequin (" .. points .. " points)")
end
-- Au doigt : glisser vers le haut sur la molette de la poitrine la tourne, un cran tous les 12 px ; un second doigt
-- ne la tourne pas, et le doigt levé ne la tourne plus
local echelleM = mannequinM.AbsoluteSize.X / mannequinM.Size.X.Offset
local doigtMolette = { UserInputType = Enum.UserInputType.Touch, Position = Vector3.new(0, 300, 0) }
fenetre.Contenu.Molette_poitrine.InputBegan:Fire(doigtMolette)
local avantPoitrine = lue("poitrine")
M.services.UserInputService.InputChanged:Fire({ UserInputType = Enum.UserInputType.Touch, Position = Vector3.new(0, 0, 0) })
verifier(lue("poitrine") == avantPoitrine, "un second doigt ne tourne pas la molette")
doigtMolette.Position = Vector3.new(0, 300 - 12 * 5 * echelleM, 0)
M.services.UserInputService.InputChanged:Fire(doigtMolette)
M.services.UserInputService.InputEnded:Fire(doigtMolette)
verifier(math.abs(lue("poitrine") - (avantPoitrine + 0.5)) < 1e-6, "glisser de 60 px vers le haut : cinq crans, +5 cm (" .. lue("poitrine") .. ")")
doigtMolette.Position = Vector3.new(0, 0, 0)
M.services.UserInputService.InputChanged:Fire(doigtMolette)
verifier(math.abs(lue("poitrine") - (avantPoitrine + 0.5)) < 1e-6, "doigt levé : la molette ne tourne plus")
verifier(fenetre.Contenu.Molette_poitrine.Fente.Rotation ~= 0, "la fente de la molette a tourné")
-- La molette est assez grosse pour le doigt ; tournée trop loin, le mannequin s'arrête au bord de son cadre
verifier(fenetre.Contenu.Molette_poitrine.AbsoluteSize.X >= 56 and fenetre.Contenu.Molette_poitrine.AbsoluteSize.Y >= 56, "molette d'au moins 56 px (le doigt)")
doigtMolette.Position = Vector3.new(0, 300, 0)
fenetre.Contenu.Molette_poitrine.InputBegan:Fire(doigtMolette)
doigtMolette.Position = Vector3.new(0, -5000, 0)
M.services.UserInputService.InputChanged:Fire(doigtMolette)
M.services.UserInputService.InputEnded:Fire(doigtMolette)
local corpsP = mannequinM.Corps_poitrine
verifier(corpsP.Position.X.Offset >= 0 and corpsP.Position.X.Offset + corpsP.Size.X.Offset <= mannequinM.Size.X.Offset, "tournée trop loin : le mannequin s'arrête au bord de son cadre")
-- À la souris : la molette de la souris tourne la molette survolée, et seulement elle
local avantTaille = lue("taille")
fenetre.Contenu.Molette_taille.MouseEnter:Fire()
M.services.UserInputService.InputChanged:Fire({ UserInputType = Enum.UserInputType.MouseWheel, Position = Vector3.new(0, 0, 1) })
verifier(math.abs(lue("taille") - (avantTaille + 0.1)) < 1e-6, "la molette de la souris sur la molette de la taille : un cran")
fenetre.Contenu.Molette_taille.MouseLeave:Fire()
M.services.UserInputService.InputChanged:Fire({ UserInputType = Enum.UserInputType.MouseWheel, Position = Vector3.new(0, 0, 1) })
verifier(math.abs(lue("taille") - (avantTaille + 0.1)) < 1e-6, "pointeur ailleurs : la molette de la souris ne la tourne plus")
```

Dans `tests/scenario.luau`, remplacer :

```lua
	for _, cle in ipairs(MESURES) do
		local function lue()
			return tonumber(texte("Valeur_" .. cle).Text:match("(%d+) cm")) / 10
		end
		local garde = 0
		while math.abs(lue() - vraies[cle]) > 0.05 and garde < 80 do
			garde += 1
			cliquer(if lue() < vraies[cle] then "Plus_" .. cle else "Moins_" .. cle)
		end
	end
```

par :

```lua
	for _, cle in ipairs(MESURES) do
		local garde = 0
		while math.abs(lue(cle) - vraies[cle]) > 0.05 and garde < 120 do
			garde += 1
			cliquer(if lue(cle) < vraies[cle] then "Plus_" .. cle else "Moins_" .. cle)
		end
	end
```

Dans `tests/scenario.luau`, remplacer :

```lua
local silhouette = fenetre.Contenu.Silhouette
for _, cle in ipairs(MESURES) do
	local ruban, corps = silhouette["Ruban_" .. cle], silhouette["Corps_" .. cle]
	local finRuban = ruban.Position.X.Offset + ruban.Size.X.Offset
	local bordCorps = corps.Position.X.Offset + corps.Size.X.Offset
	verifier(math.abs(finRuban - bordCorps) <= 2 and ruban.Position.X.Offset == corps.Position.X.Offset, cle .. " : réglé juste, le ruban s'arrête au bord de la silhouette")
end
```

par :

```lua
for _, cle in ipairs(MESURES) do
	local corps, calque = mannequinM["Corps_" .. cle], mannequinM["Calque_" .. cle]
	local gauche = math.abs(corps.Position.X.Offset - calque.Position.X.Offset)
	local droite = math.abs(corps.Position.X.Offset + corps.Size.X.Offset - (calque.Position.X.Offset + calque.Size.X.Offset))
	verifier(gauche <= 2 and droite <= 2, cle .. " : réglé juste, le mannequin épouse la silhouette")
end
```

Dans `tests/scenario.luau`, remplacer :

```lua
verifier(scene:FindFirstChild("Lettre") == nil, "plus de lettre dans la boîte")
cliquer("ReprendreMesures")
```

par :

```lua
verifier(scene:FindFirstChild("Lettre") == nil, "plus de lettre dans la boîte")
do -- Une cliente déjà mesurée : la fiche donne ses mesures du carnet
	local m = serveur:atelier(joueur).etat.clientes.colette.mesures
	local attendu = ("Au carnet : %d / %d / %d cm"):format(math.round(m.poitrine * 10), math.round(m.taille * 10), math.round(m.hanches * 10))
	verifier(fenetre.Contenu:FindFirstChild("FicheCarnet") ~= nil and string.find(fenetre.Contenu.FicheCarnet.Text, attendu, 1, true) == 1, "déjà mesurée : ses mesures du carnet (" .. attendu .. ")")
end
cliquer("ReprendreMesures")
```

- [ ] **Step 2: Lancer les tests, vérifier l'échec**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT|attempt|membre" | head -3`
Expected: échec : une ligne qui finit par `ÉCHEC : mesures farfelues refusées par le serveur`

- [ ] **Step 3: Réécrire l'écran**

Créer `src/client/Atelier/EcranMesures.luau` :

```lua
-- Écran des mesures (sous-projet 6 : le mannequin à molettes) : un mannequin de couture, de face, et par-dessus, en
-- pointillé, la silhouette de la cliente à ses vraies mesures. Trois molettes (poitrine, taille, hanches) élargissent
-- ou resserrent le mannequin : on les tourne en glissant de haut en bas (souris ou doigt), à la molette de la souris,
-- ou avec − et + (0,1 dm de tour), jusqu'à ce que le mannequin épouse la silhouette ; la mesure s'affiche en
-- centimètres. « Valider les mesures » les envoie au serveur, qui refuse une mesure trop loin de la vraie ; une
-- cliente déjà mesurée peut « Reprendre ses mesures ».
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Couture = ReplicatedStorage:WaitForChild("Couture")
local Catalogue = require(Couture:WaitForChild("Catalogue"))
local Clientes = require(Couture:WaitForChild("Clientes"))
local Molette = require(script.Parent:WaitForChild("Molette"))

local MESURES = { { cle = "poitrine", nom = "Poitrine", y = 110 }, { cle = "taille", nom = "Taille", y = 190 }, { cle = "hanches", nom = "Hanches", y = 270 } }
local LARGEUR = 320 -- px : largeur du cadre du mannequin
local PX = 70 -- px par dm de largeur de face
local FACE = 0.32 -- largeur de face d'un tour : un tour de 9 dm fait 2,9 dm de large, vu de face
local DEPART = 0.7 -- le mannequin part à 70 % de la mesure de sa taille : il faut vraiment mesurer
local MINI = 2 -- dm de tour
local TAILLE_MOLETTE = 64 -- px (au moins 56 : le doigt)
local TOILE = Color3.fromRGB(232, 214, 186) -- la toile du mannequin
local BOIS = Color3.fromRGB(150, 110, 75)
local RUBAN = Color3.fromRGB(250, 210, 70)
local POINTILLE = Color3.fromRGB(110, 70, 96)
local PAS_POINTS = 10 -- px entre deux points du pointillé

return function(ctx)
	local UiKit, session, contenu = ctx.UiKit, ctx.session, ctx.contenu
	local C = UiKit.COULEURS
	local etat = session.etat
	local cliente = Clientes.get(etat.commande.cliente)
	local fiche = etat.clientes[cliente.id]
	local connexions = {}
	local molettes, elements = {}, {}
	local saisie, survol = nil, nil

	UiKit.texte({
		Name = "Consigne",
		Text = ("Mesure %s : tourne chaque molette jusqu'à ce que le mannequin épouse sa silhouette, en pointillé (ou règle-le avec − et +)."):format(cliente.nom),
		TextSize = 16,
		Size = UDim2.new(1, 0, 0, 44),
		Parent = contenu,
	})

	-- Le mannequin : son pied, sa colonne, son cou, et le buste, la taille et les hanches, à la largeur des molettes
	local mannequin = UiKit.arrondir(UiKit.creer("Frame", { Name = "Mannequin", BackgroundColor3 = C.panneau, Position = UDim2.fromOffset(0, 50), Size = UDim2.fromOffset(LARGEUR, 340), Parent = contenu }), 10)
	local centre = LARGEUR / 2
	UiKit.creer("Frame", { Name = "Colonne", BackgroundColor3 = BOIS, BorderSizePixel = 0, Position = UDim2.fromOffset(centre - 4, 300), Size = UDim2.fromOffset(8, 30), Parent = mannequin })
	UiKit.arrondir(UiKit.creer("Frame", { Name = "Pied", BackgroundColor3 = BOIS, BorderSizePixel = 0, Position = UDim2.fromOffset(centre - 40, 326), Size = UDim2.fromOffset(80, 8), Parent = mannequin }), 4)
	UiKit.arrondir(UiKit.creer("Frame", { Name = "Cou", BackgroundColor3 = TOILE, BorderSizePixel = 0, Position = UDim2.fromOffset(centre - 12, 44), Size = UDim2.fromOffset(24, 26), Parent = mannequin }), 6)
	UiKit.arrondir(UiKit.creer("Frame", { Name = "Bouchon", BackgroundColor3 = BOIS, BorderSizePixel = 0, Position = UDim2.fromOffset(centre - 16, 36), Size = UDim2.fromOffset(32, 10), Parent = mannequin }), 5)

	-- La silhouette de la cliente, en pointillé par-dessus le mannequin (comme un calque) : ses bords gauche et droit, à
	-- chaque mesure, et le haut et le bas de chaque bande
	local function pointille(parent, x0, y0, x1, y1)
		local n = math.max(1, math.floor(math.max(math.abs(x1 - x0), math.abs(y1 - y0)) / PAS_POINTS))
		for k = 0, n do
			UiKit.creer("Frame", { Name = "Point", BackgroundColor3 = POINTILLE, BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(x0 + (x1 - x0) * k / n, y0 + (y1 - y0) * k / n), Size = UDim2.fromOffset(3, 3), ZIndex = 5, Parent = parent })
		end
	end
	for _, m in ipairs(MESURES) do
		local largeur = cliente.mesures[m.cle] * FACE * PX
		local calque = UiKit.creer("Frame", { Name = "Calque_" .. m.cle, BackgroundTransparency = 1, Position = UDim2.fromOffset(centre - largeur / 2, m.y - 40), Size = UDim2.fromOffset(largeur, 80), ZIndex = 5, Parent = mannequin })
		pointille(calque, 0, 0, 0, 80)
		pointille(calque, largeur, 0, largeur, 80)
	end

	-- Une bande du mannequin, son mètre ruban, sa molette et sa mesure
	local function maj(cle)
		local e, m = elements[cle], molettes[cle]
		local largeur = m.valeur * FACE * PX
		e.corps.Position = UDim2.fromOffset(centre - largeur / 2, e.y - 40)
		e.corps.Size = UDim2.fromOffset(largeur, 80)
		e.ruban.Position = UDim2.fromOffset(centre - largeur / 2, e.y - 3)
		e.ruban.Size = UDim2.fromOffset(largeur, 6)
		e.fente.Rotation = m:angle()
		e.valeur.Text = ("%s : %d cm"):format(e.nom, math.round(m.valeur * 10))
	end
	local maxi = math.floor(LARGEUR / (FACE * PX) * 10) / 10 -- (le mannequin ne sort pas de son cadre)
	for i, mesure in ipairs(MESURES) do
		local cle = mesure.cle
		molettes[cle] = Molette.nouvelle(Catalogue.TAILLES[cliente.taille][cle] * DEPART, MINI, maxi)
		local corps = UiKit.arrondir(UiKit.creer("Frame", { Name = "Corps_" .. cle, BackgroundColor3 = TOILE, BorderSizePixel = 0, ZIndex = if i == 2 then 3 else 2, Parent = mannequin }), 18) -- (des bandes arrondies : un buste de couturière)
		local ruban = UiKit.creer("Frame", { Name = "Ruban_" .. cle, BackgroundColor3 = RUBAN, BorderSizePixel = 0, ZIndex = 4, Parent = mannequin })
		local y = 50 + mesure.y - TAILLE_MOLETTE / 2
		-- La molette : un bouton rond (un bouton, pas un cadre : l'appui ne passe pas dessous), sa fente qui tourne
		local bouton = UiKit.arrondir(UiKit.creer("TextButton", { Name = "Molette_" .. cle, Text = "", AutoButtonColor = false, BackgroundColor3 = BOIS, Position = UDim2.fromOffset(LARGEUR + 30, y), Size = UDim2.fromOffset(TAILLE_MOLETTE, TAILLE_MOLETTE), Parent = contenu }), TAILLE_MOLETTE / 2)
		UiKit.creer("UIStroke", { Color = Color3.fromRGB(110, 78, 50), Thickness = 3, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = bouton })
		local fente = UiKit.creer("Frame", { Name = "Fente", BackgroundColor3 = Color3.fromRGB(70, 48, 30), BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(6, TAILLE_MOLETTE - 18), Parent = bouton })
		local valeur = UiKit.texte({ Name = "Valeur_" .. cle, Font = Enum.Font.GothamBold, TextSize = 18, Position = UDim2.fromOffset(LARGEUR + 110, y + 14), Size = UDim2.fromOffset(200, 36), Parent = contenu })
		UiKit.boutonDoux({ Name = "Moins_" .. cle, Text = "−", TextSize = 22, Position = UDim2.fromOffset(LARGEUR + 320, y + 14), Size = UDim2.fromOffset(44, 36), Parent = contenu }, function()
			molettes[cle]:crans(-1)
			maj(cle)
		end)
		UiKit.boutonDoux({ Name = "Plus_" .. cle, Text = "+", TextSize = 22, Position = UDim2.fromOffset(LARGEUR + 372, y + 14), Size = UDim2.fromOffset(44, 36), Parent = contenu }, function()
			molettes[cle]:crans(1)
			maj(cle)
		end)
		elements[cle] = { corps = corps, ruban = ruban, fente = fente, valeur = valeur, nom = mesure.nom, y = mesure.y }
		maj(cle)
		-- Glisser sur la molette (souris ou doigt) ; la molette de la souris quand le pointeur est dessus
		table.insert(connexions, bouton.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				saisie = { cle = cle, input = input, y = input.Position.Y }
			end
		end))
		table.insert(connexions, bouton.MouseEnter:Connect(function()
			survol = cle
		end))
		table.insert(connexions, bouton.MouseLeave:Connect(function()
			if survol == cle then
				survol = nil
			end
		end))
	end
	table.insert(connexions, UserInputService.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseWheel then
			if survol and input.Position.Z ~= 0 then
				molettes[survol]:crans(if input.Position.Z > 0 then 1 else -1)
				maj(survol)
			end
			return
		end
		if not saisie then
			return
		end
		local suit = if saisie.input.UserInputType == Enum.UserInputType.Touch then input == saisie.input else input.UserInputType == Enum.UserInputType.MouseMovement
		local taille = mannequin.AbsoluteSize
		if suit and taille and taille.X > 0 then
			local echelle = taille.X / LARGEUR -- (la fenêtre est réduite sur les petits écrans)
			molettes[saisie.cle]:glisser((input.Position.Y - saisie.y) / echelle)
			saisie.y = input.Position.Y
			maj(saisie.cle)
		end
	end))
	table.insert(connexions, UserInputService.InputEnded:Connect(function(input)
		if saisie and (input == saisie.input or (saisie.input.UserInputType == Enum.UserInputType.MouseButton1 and input.UserInputType == Enum.UserInputType.MouseButton1)) then
			saisie = nil
		end
	end))

	UiKit.bouton({ Name = "ValiderMesures", Text = "Valider les mesures", AnchorPoint = Vector2.new(1, 1), Position = UDim2.fromScale(1, 1), Size = UDim2.fromOffset(240, 46), Parent = contenu }, function()
		local r = session:mesurer({ poitrine = molettes.poitrine.valeur, taille = molettes.taille.valeur, hanches = molettes.hanches.valeur })
		if not r.ok then
			ctx.refus(r)
		end
	end, 0.4)
	if fiche and fiche.mesures then
		-- La fiche du carnet : ses mesures de la dernière fois
		local d = fiche.mesures
		UiKit.texte({ Name = "FicheCarnet", Text = ("Au carnet : %d / %d / %d cm (ajustement %d %%)."):format(math.round(d.poitrine * 10), math.round(d.taille * 10), math.round(d.hanches * 10), math.floor((fiche.ajustement or 1) * 100 + 0.5)), TextSize = 14, TextColor3 = C.texteDoux, Position = UDim2.fromOffset(LARGEUR + 30, 380), Size = UDim2.fromOffset(420, 22), Parent = contenu })
		UiKit.boutonDoux({ Name = "ReprendreMesures", Text = "Reprendre ses mesures", AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, LARGEUR + 30, 1, 0), Size = UDim2.fromOffset(240, 46), Parent = contenu }, function()
			local r = session:reprendreMesures()
			if not r.ok then
				ctx.refus(r)
			end
		end, 0.4)
	end

	return function()
		for _, c in ipairs(connexions) do
			c:Disconnect()
		end
	end
end
```

- [ ] **Step 4: Le message de refus**

Dans `src/shared/EtatAtelier.luau`, remplacer :

```lua
local MESURE_INVALIDE = "Mesure invalide : règle chaque ruban au bord de la silhouette."
```

par :

```lua
local MESURE_INVALIDE = "Mesure invalide : tourne chaque molette jusqu'à épouser sa silhouette."
```

- [ ] **Step 5: Lancer les tests**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT"`
Expected:
```
Unitaires : 167854 vérifications
TOUT EST VERT : 868 vérifications
```

- [ ] **Step 6: Commit**

```bash
git add src/client/Atelier/EcranMesures.luau src/shared/EtatAtelier.luau tests/scenario.luau tests/unitaires/28_commande_serveur.luau
git commit -m "Les mesures sur un mannequin à molettes, la silhouette de la cliente en pointillé par-dessus

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 3: Studio, README, lieu régénéré

**Files:**
- Modify: `README.md`, `AtelierCouture.rbxl` (régénéré)

**Interfaces:**
- Consumes: tout ce qui précède.
- Produces: rien de nouveau.

- [ ] **Step 1: Dans Studio, par le connecteur MCP**

Construire le lieu du dépôt dans un dossier temporaire (`C:/dev/jeux/roblox-maker/rojo.exe build -o <dossier temporaire>/Plan15Depot.rbxl`) et l'ouvrir dans Studio. En Play : attendre 4 s, appuyer sur E ; capturer l'écran des mesures ; tourner la molette de la poitrine par `user_mouse_input` (appui sur la molette, déplacement vers le haut, relâcher) et relever la valeur affichée ; régler les trois molettes aux vraies mesures de la cliente (par les boutons +) et valider ; relever la console.

Expected : le mannequin (bandes arrondies, mètre ruban), la silhouette en pointillé, trois molettes rondes à fente ; le glissement vers le haut augmente la poitrine ; mesures validées, le carnet s'ouvre ; aucune alerte de notre code (« Lieu non publié » et les messages internes de Roblox mis à part). Arrêter Play et fermer cette fenêtre de Studio (sans enregistrer).

- [ ] **Step 2: Mettre à jour le README**

Dans `README.md`, remplacer :

```markdown
## État actuel (sous-projet 5 terminé côté code, plans 11 à 14 : la fidélité à la présentation de *Dressmaker*)
```

par :

```markdown
## État actuel (sous-projet 6 en cours, plan 15 : les mesures à molettes)
```

Dans `README.md`, remplacer :

```markdown
   **Mesures** : à sa première visite, on la mesure. Sa silhouette est dessinée à ses vraies mesures ; on règle
   trois rubans (poitrine, taille, hanches) jusqu'au bord de la silhouette, en glissant ou avec − et + (0,1 dm
   près). Le serveur refuse un ruban à plus de 1,5 dm de la vraie mesure. Quand elle revient, « Reprendre ses
   mesures » les reprend du carnet.
```

par :

```markdown
   **Mesures** : à sa première visite, on la mesure sur un mannequin de couture à trois molettes (poitrine,
   taille, hanches), sa silhouette en pointillé par-dessus : on tourne chaque molette (en glissant de haut en bas,
   à la molette de la souris, ou avec − et +, 0,1 dm par cran) jusqu'à ce que le mannequin l'épouse. Le serveur
   refuse une mesure à plus de 1,5 dm de la vraie. Quand elle revient, la fiche donne ses mesures du carnet, et
   « Reprendre ses mesures » les reprend.
```

Dans `README.md`, remplacer :

```markdown
un module `Ecran…` par étape (`EcranMesures` : la silhouette et les rubans).
```

par :

```markdown
un module `Ecran…` par étape (`EcranMesures` : le mannequin à molettes, `Molette` : le réglage d'une
  molette).
```

Dans `README.md`, remplacer :

```markdown
`docs/superpowers/specs/2026-09-30-fidelite-dressmaker-design.md` pour la fidélité à la présentation de
*Dressmaker* ; plans : `docs/superpowers/plans/`).
```

par :

```markdown
`docs/superpowers/specs/2026-09-30-fidelite-dressmaker-design.md` pour la fidélité à la présentation de
*Dressmaker*, `docs/superpowers/specs/2026-09-30-atelier-fidele-design.md` pour l'atelier plus fidèle ; plans :
`docs/superpowers/plans/`).
```

- [ ] **Step 3: Tests, lieu régénéré, commit**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT"`
Expected:
```
Unitaires : 167854 vérifications
TOUT EST VERT : 868 vérifications
```

```bash
C:/dev/jeux/roblox-maker/rojo.exe build -o AtelierCouture.rbxl
git add README.md AtelierCouture.rbxl
git commit -m "Plan 15 terminé : les mesures à molettes

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```
