# Aiguille & Dentelle — Plan 27 : les premiers pas, le bandeau et les mesures

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** À la première robe, chaque poste accompagne le joueur pas à pas : un bandeau sur la barre de titre donne un conseil à la fois, un anneau entoure l'élément à toucher, le conseil s'efface quand le geste est fait ; « ? » les rappelle. Ce plan pose le mécanisme, le branche sur la couture, et fait l'accueil et les mesures.

**Architecture:** Un module client `Tutoriel` : `installer(fenetre, UiKit)` pose le bandeau (`Conseil`) et « ? » (`Aide`) sur la fenêtre et suit les conseils à chaque image ; `demarrer(session, poste, etapes, relancer?)` ouvre les conseils d'un poste (seulement à la première robe, et s'ils ne sont pas déjà vus) ; `arreter()` les ferme quand le poste se ferme (ils sont alors vus). Le script du client l'installe une fois et le passe aux écrans (`ctx.guide`) ; chaque écran donne ses conseils, qui lisent son propre état. La couture garde ses conseils, que « ? » reprend désormais depuis la barre de titre. Rien n'est sauvegardé ; le serveur ne change pas.

**Tech Stack:** Luau, Rojo 7.7.0-rc.1, simulation Luau 0.650 (`tests/lancer.sh`), Roblox Studio via le connecteur MCP Studio.

**Spec:** `docs/superpowers/specs/2026-10-01-premiers-pas-design.md` (sections 1 à 3 ; plan 27 de la section 5).

## Décisions de ce plan

- **Le bandeau** : sur la barre de titre, par-dessus le titre du poste tant qu'un conseil s'affiche (le titre reste dessous, inchangé). Fenêtre centrée : de x = 16 jusqu'à 410 px du bord droit, 48 px de haut, texte de 15 px (deux lignes, environ 120 caractères) ; en panneau : jusqu'à 116 px du bord droit, 36 px, texte de 14 px (deux lignes, environ 70 caractères). Fond clair, bord de la couleur du jeu (sur le bord, pas sur le texte), marges de 10 px.
- **« ? »** : 36 × 36, à 384 px du bord droit (fenêtre centrée, à gauche de l'argent) ou à 92 px (panneau, à gauche de la croix) ; le titre est raccourci d'autant (410 et 116 px). Visible quand le poste ouvert a des conseils.
- **L'anneau** : un cadre arrondi, enfant de l'élément désigné, 6 px plus large de chaque côté, bord de 3 px qui pulse (1,4 s). L'élément est relu à chaque image : si l'écran le refait, l'anneau le suit. Un cadre ne prend pas l'appui : l'élément reste cliquable.
- **Quand un conseil s'efface** : quand sa condition est remplie (lue à chaque image), ou au bout de sa durée s'il ne demande que de lire — jamais avant 2 s, le temps de le lire (la relecture du plan 26 l'a demandé pour la couture : un conseil déjà fait, ou rappelé par « ? », ne doit pas s'effacer en une image) ; le dernier franchi, les conseils sont vus. Quitter le poste les rend vus aussi (le script du client appelle `arreter` avant de fermer l'écran) : ils ne reviennent qu'avec « ? ».
- **La couture** : son « ? » quitte son panneau (la note reprend toute la largeur) ; celui de la barre de titre reprend ses conseils (`demarrer(session, "couture", nil, relancer)`).
- **Les mesures** : (1) tourner une molette — s'efface dès qu'une mesure a changé ; (2) faire coïncider les trois bandes — s'efface quand les trois mesures sont justes à la tolérance de l'ajustement (0,2 dm : `Notation.TOLERANCE_MESURE`) ; (3) valider. **L'accueil** : sonner la clochette (le texte d'accueil du débutant reste).
- **Vérifié pendant la préparation** : le plan a été joué entièrement sur un brouillon tiré de `main` ; quatorze variantes du brouillon échouent sur la vérification qui les garde. Dans Studio : le bandeau sur la barre de titre (fenêtre centrée, aux mesures, l'anneau autour de la molette) et en panneau (quatre conseils types des plans suivants tiennent en deux lignes).

## Global Constraints

- **Dépôt** : `C:\dev\jeux\atelier-couture`, branche `premiers-pas`, créée depuis `main`. Selon les règles du commanditaire : la branche testée et relue est fusionnée dans `main` et poussée sur GitHub.
- **Rojo** : `C:/dev/jeux/roblox-maker/rojo.exe`.
- **Contenu original** : aucun nom, texte, image ni son de *Dressmaker*.
- **Contraintes des plans précédents toujours valables** : fins de ligne LF, commits en français terminés par `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`, textes d'au moins 14 px (et aucun texte laissé à « Label »), le serveur fait foi.

## Review Focus

- **Le joueur valide les mesures sans avoir suivi les conseils.** Attendu : le poste se ferme comme avant, ses conseils sont vus et ne reviennent pas au carnet. Test : scénario (au carnet, ni bandeau ni « ? »).
- **L'écran refait l'élément désigné.** Attendu : l'anneau entoure le nouvel élément. Test : `81_tutoriel`.
- **Un joueur qui a déjà livré une robe.** Attendu : pas de conseils d'eux-mêmes ; « ? » les montre. Test : `81_tutoriel`, `82_premiers_pas`.
- **La couture.** Attendu : « ? » sur la barre de titre reprend ses conseils ; plus de « ? » dans son panneau. Test : `80_guide_couture`.
- **La fenêtre en panneau.** Attendu : un bandeau plus court qui ne cache ni l'argent ni le son ; « ? » près de la croix. Test : `81_tutoriel`.

---

### Task 1: Le bandeau, l'anneau et « ? »

**Files:**
- Create: `src/client/Atelier/Tutoriel.luau`, `tests/unitaires/81_tutoriel.luau`
- Modify: `src/client/Atelier/init.client.luau`, `src/client/Atelier/EcranCouture.luau`, `tests/unitaires/80_guide_couture.luau`

**Interfaces:**
- Consumes: `UiKit` (`texte`, `boutonDoux`, `creer`, `arrondir`, `COULEURS`) ; `session.etat.livraisons`, `session.etat.ventes` (existants) ; les conseils de la couture (`GuideCouture`, plan 26).
- Produces: `Tutoriel.premiereRobe(etat)`, `Tutoriel.AFFICHAGE_MIN`, `Tutoriel.installer(fenetre, UiKit)` → guide ; `guide:disposer(panneau)`, `guide:demarrer(session, poste, etapes, relancer?)`, `guide:relancer()`, `guide:arreter()`, `guide:image(dt)` ; sur la fenêtre : `Conseil`, `Aide` ; autour de l'élément désigné : `Anneau` (et son `Contour`) ; `session.tutorielsVus[poste]` ; `ctx.guide` passé à chaque écran. Une étape : `{ texte, cible = function() → GuiObject ?, fait = function(dt) → booléen ?, duree = s ? }`.

- [ ] **Step 1: Écrire les tests**

Créer `tests/unitaires/81_tutoriel.luau` :

```lua
-- Sous-projet 9 : les conseils pas à pas d'un poste. Un bandeau sur la barre de titre, un anneau qui pulse autour de
-- l'élément à toucher ; chaque conseil s'efface quand le geste est fait, ou au bout de sa durée s'il ne demande que de
-- lire ; « ? » les reprend au premier ; les conseils vus ne reviennent pas d'eux-mêmes.
local Tutoriel = U.module("Tutoriel")
local UiKit = U.module("UiKit")

local fenetre = UiKit.creer("Frame", { Name = "Fenetre", Size = UDim2.fromOffset(900, 560) })
local guide = Tutoriel.installer(fenetre, UiKit)
local bandeau, aide = fenetre.Conseil, fenetre.Aide
U.verifier(not bandeau.Visible and not aide.Visible and bandeau.TextSize >= 14, "installé : rien d'affiché tant qu'aucun poste n'a de conseils")
U.verifier(Tutoriel.premiereRobe({ livraisons = 0, ventes = 0 }) and not Tutoriel.premiereRobe({ livraisons = 1, ventes = 0 }) and not Tutoriel.premiereRobe({ livraisons = 0, ventes = 1 }), "première robe : aucune robe livrée ni vendue")

-- Trois conseils : un geste, une lecture, un dernier
local session = { etat = { livraisons = 0, ventes = 0 } }
local cible = UiKit.bouton({ Name = "Cible", Text = "Cible", Size = UDim2.fromOffset(100, 40), Parent = fenetre })
local geste = false
local ETAPES = {
	{ texte = "Touche la cible.", cible = function() return cible end, fait = function() return geste end },
	{ texte = "Lis ceci.", duree = 2 },
	{ texte = "Le dernier.", fait = function() return geste end },
}
guide:demarrer(session, "essai", ETAPES)
U.verifier(bandeau.Visible and bandeau.Text == "Touche la cible." and aide.Visible and cible:FindFirstChild("Anneau") ~= nil, "première robe : le premier conseil, l'élément entouré, « ? »")
M.avancer(0.3)
local avant = cible.Anneau.Contour.Transparency
M.avancer(0.4)
U.verifier(cible.Anneau.Contour.Transparency ~= avant, "l'anneau pulse")
U.verifier(bandeau.Text == "Touche la cible.", "le geste n'est pas fait : le conseil reste")
geste = true
M.avancer(0.05)
U.verifier(bandeau.Text == "Touche la cible.", "le geste fait, mais le conseil n'est là que depuis 0,75 s : il reste le temps de le lire")
M.avancer(1.3)
U.verifier(bandeau.Text == "Lis ceci." and cible:FindFirstChild("Anneau") == nil, "le geste fait, le conseil lu : le suivant, l'anneau retiré")
M.avancer(1.5)
U.verifier(bandeau.Text == "Lis ceci.", "un conseil à lire reste le temps de sa durée")
M.avancer(0.6)
U.verifier(bandeau.Text == "Le dernier.", "lu : le dernier conseil (son geste est déjà fait, il reste le temps de le lire)")
M.avancer(2.1)
U.verifier(not bandeau.Visible and session.tutorielsVus.essai, ("le dernier lu : les conseils sont finis et vus (%s)"):format(bandeau.Text))
U.verifier(aide.Visible, "« ? » reste, tant que le poste est ouvert")

-- « ? » : les conseils reprennent au premier
geste = false
aide.Activated:Fire()
U.verifier(bandeau.Visible and bandeau.Text == "Touche la cible." and cible:FindFirstChild("Anneau") ~= nil, "« ? » : le premier conseil de nouveau")
-- L'écran refait l'élément désigné : l'anneau le suit
local refaite = UiKit.bouton({ Name = "Cible", Text = "Cible", Size = UDim2.fromOffset(100, 40), Parent = fenetre })
cible:Destroy()
cible = refaite
M.avancer(0.05) -- (le geste n'est pas fait : le conseil reste)
U.verifier(refaite:FindFirstChild("Anneau") ~= nil, "l'élément refait : l'anneau l'entoure de nouveau")

-- Le poste se ferme avant la fin : ses conseils sont vus, le bandeau et « ? » disparaissent
local autre = { etat = { livraisons = 0, ventes = 0 } }
guide:demarrer(autre, "essai", ETAPES)
U.verifier(bandeau.Visible and bandeau.Text == "Touche la cible.", "un autre joueur, à sa première robe : les conseils")
guide:arreter()
U.verifier(not bandeau.Visible and not aide.Visible and autre.tutorielsVus.essai and refaite:FindFirstChild("Anneau") == nil, "poste fermé : conseils vus, bandeau, « ? » et anneau retirés")
guide:demarrer(autre, "essai", ETAPES)
U.verifier(not bandeau.Visible and aide.Visible, "conseils vus : ils ne reviennent pas d'eux-mêmes ; « ? » est là")
aide.Activated:Fire()
U.verifier(bandeau.Visible and bandeau.Text == "Touche la cible.", "« ? » les montre")
guide:arreter()

-- Après une robe livrée : pas de conseils, « ? » les montre
local habitue = { etat = { livraisons = 1, ventes = 0 } }
guide:demarrer(habitue, "essai", ETAPES)
U.verifier(not bandeau.Visible and aide.Visible, "une robe livrée : pas de conseils d'eux-mêmes")
aide.Activated:Fire()
U.verifier(bandeau.Visible and bandeau.Text == "Touche la cible.", "« ? » les montre")
guide:arreter()

-- Un poste qui a ses propres conseils (la couture) : « ? » les reprend
local repris = 0
guide:demarrer(session, "couture", nil, function()
	repris += 1
end)
U.verifier(aide.Visible and not bandeau.Visible, "la couture : « ? » sans bandeau")
aide.Activated:Fire()
U.verifier(repris == 1 and not bandeau.Visible, "« ? » reprend les conseils de la couture")
guide:arreter()
U.verifier(not aide.Visible and session.tutorielsVus.couture == nil, "la couture fermée : « ? » disparaît")

-- Le bandeau et « ? » selon la fenêtre : centrée, ou en panneau à droite
local function egal(u, xs, xo, ys, yo)
	return u.X.Scale == xs and u.X.Offset == xo and u.Y.Scale == ys and u.Y.Offset == yo
end
guide:disposer(true)
U.verifier(egal(bandeau.Size, 1, -116, 0, 36) and bandeau.TextSize >= 14 and egal(aide.Position, 1, -92, 0, 6), "en panneau : un bandeau plus court, « ? » près de la croix")
guide:disposer(false)
U.verifier(egal(bandeau.Size, 1, -410, 0, 48) and egal(aide.Position, 1, -384, 0, 12), "fenêtre centrée : le bandeau à gauche de « ? » et de l'argent")
```

Dans `tests/unitaires/80_guide_couture.luau`, remplacer :

```lua
local EcranCouture = U.module("EcranCouture")
```

par :

```lua
local EcranCouture = U.module("EcranCouture")
local Tutoriel = U.module("Tutoriel")
```

Dans `tests/unitaires/80_guide_couture.luau`, remplacer :

```lua
	local ctx = { UiKit = UiKit, session = session, contenu = contenu, fenetre = fenetre, message = function() end, refus = function() end }
	return ctx, EcranCouture(ctx)
```

par :

```lua
	local ctx = { UiKit = UiKit, session = session, contenu = contenu, fenetre = fenetre, message = function() end, refus = function() end, guide = Tutoriel.installer(fenetre, UiKit) }
	return ctx, EcranCouture(ctx)
```

Dans `tests/unitaires/80_guide_couture.luau`, remplacer :

```lua
local aide = ctx.contenu.Panneau.Aide
```

par :

```lua
local aide = ctx.fenetre.Aide -- (sous-projet 9 : « ? » est sur la barre de titre de la fenêtre)
U.verifier(ctx.contenu.Panneau:FindFirstChild("Aide") == nil and aide.Visible, "« ? » sur la barre de titre, pas dans le panneau")
```

Dans `tests/unitaires/80_guide_couture.luau`, remplacer :

```lua
ctx3.contenu.Panneau.Aide.Activated:Fire()
```

par :

```lua
ctx3.fenetre.Aide.Activated:Fire()
```

- [ ] **Step 2: Lancer les tests, vérifier l'échec**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT|attempt|membre" | head -3`
Expected: échec : une ligne qui finit par `Tutoriel n'est pas un membre valide de Folder « Couture »`

- [ ] **Step 3: Le module, le script du client, la couture**

Créer `src/client/Atelier/Tutoriel.luau` :

```lua
-- Tutoriel (sous-projet 9) : les conseils pas à pas d'un poste, à la première robe. Un bandeau sur la barre de titre dit
-- le conseil en cours, un anneau qui pulse entoure l'élément à toucher ; chaque conseil s'efface quand le geste est fait
-- (une condition lue à chaque image) ou, s'il ne demande que de lire, au bout de sa durée. « ? » les reprend au premier.
-- Rien n'est sauvegardé : les conseils vus ne reviennent pas d'eux-mêmes pendant la partie.
local RunService = game:GetService("RunService")

local Tutoriel = {}
Tutoriel.__index = Tutoriel

Tutoriel.PULSATION = 1.4 -- s : un battement de l'anneau
Tutoriel.MARGE = 6 -- px : l'anneau déborde d'autant autour de l'élément
Tutoriel.AFFICHAGE_MIN = 2 -- s : un conseil reste au moins ce temps, même si son geste est déjà fait (le lire)

-- La première robe : aucune robe livrée ni vendue (la même règle que les conseils de la couture)
function Tutoriel.premiereRobe(etat)
	return etat.livraisons + etat.ventes == 0
end

-- Pose le bandeau et « ? » sur la fenêtre (une fois, par le script du client)
function Tutoriel.installer(fenetre, UiKit)
	local C = UiKit.COULEURS
	local self = setmetatable({ UiKit = UiKit, k = nil, temps = 0 }, Tutoriel)
	self.bandeau = UiKit.arrondir(UiKit.texte({
		Name = "Conseil",
		Text = "",
		TextSize = 15,
		TextColor3 = C.texte,
		BackgroundColor3 = C.panneau,
		BackgroundTransparency = 0,
		Position = UDim2.fromOffset(16, 6),
		Visible = false,
		ZIndex = 20,
		Parent = fenetre,
	}), 10)
	UiKit.creer("UIStroke", { Color = C.accent, Thickness = 2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = self.bandeau })
	UiKit.creer("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10), Parent = self.bandeau })
	self.aide = UiKit.boutonDoux({ Name = "Aide", Text = "?", TextSize = 18, Size = UDim2.fromOffset(36, 36), Visible = false, Parent = fenetre }, function()
		self:relancer()
	end)
	self.connexion = RunService.RenderStepped:Connect(function(dt)
		self:image(dt)
	end)
	self:disposer(false)
	return self
end

-- Fenêtre centrée (deux lignes à gauche de l'argent) ou panneau à droite (deux lignes plus courtes, sur le titre)
function Tutoriel:disposer(panneau)
	if panneau then
		self.bandeau.Size = UDim2.new(1, -116, 0, 36)
		self.bandeau.TextSize = 14
		self.aide.Position = UDim2.new(1, -92, 0, 6)
	else
		self.bandeau.Size = UDim2.new(1, -410, 0, 48)
		self.bandeau.TextSize = 15
		self.aide.Position = UDim2.new(1, -384, 0, 12)
	end
end

function Tutoriel:retirerAnneau()
	if self.anneau then
		self.anneau:Destroy()
	end
	self.anneau, self.contour, self.cible = nil, nil, nil
end

function Tutoriel:poserAnneau(cible)
	local UiKit = self.UiKit
	self.cible = cible
	self.anneau = UiKit.arrondir(UiKit.creer("Frame", {
		Name = "Anneau",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(1, 2 * Tutoriel.MARGE, 1, 2 * Tutoriel.MARGE),
		ZIndex = (cible.ZIndex or 1) + 1,
		Parent = cible,
	}), 12)
	self.contour = UiKit.creer("UIStroke", { Name = "Contour", Color = UiKit.COULEURS.accent, Thickness = 3, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = self.anneau })
end

-- Affiche le conseil k (au-delà du dernier : les conseils sont finis, donc vus)
function Tutoriel:aller(k)
	self:retirerAnneau()
	if not self.etapes or k > #self.etapes then
		self.k = nil
		self.bandeau.Visible = false
		if self.session and self.poste then
			self.session.tutorielsVus[self.poste] = true
		end
		return
	end
	self.k, self.temps = k, 0
	local etape = self.etapes[k]
	self.bandeau.Text = etape.texte
	self.bandeau.Visible = true
	local cible = etape.cible and etape.cible()
	if cible then
		self:poserAnneau(cible)
	end
end

-- Un poste s'ouvre. etapes : { { texte, cible = function() return GuiObject end ?, fait = function(dt) return bool end ?,
-- duree = s ? } } ; relancer (facultatif) : ce que fait « ? » à la place (la couture a ses propres conseils)
function Tutoriel:demarrer(session, poste, etapes, relancer)
	self:arreter()
	session.tutorielsVus = session.tutorielsVus or {}
	self.session, self.poste, self.etapes, self.relance = session, poste, etapes, relancer
	self.aide.Visible = etapes ~= nil or relancer ~= nil
	if etapes and Tutoriel.premiereRobe(session.etat) and not session.tutorielsVus[poste] then
		self:aller(1)
	end
end

-- « ? » : les conseils du poste reprennent au premier
function Tutoriel:relancer()
	if self.relance then
		self.relance()
	elseif self.etapes then
		self:aller(1)
	end
end

-- Le poste se ferme : ses conseils sont vus (même ceux que le joueur n'a pas attendus)
function Tutoriel:arreter()
	if self.session and self.poste and self.etapes then
		self.session.tutorielsVus[self.poste] = true
	end
	self:retirerAnneau()
	self.session, self.poste, self.etapes, self.relance, self.k = nil, nil, nil, nil, nil
	self.bandeau.Visible = false
	self.aide.Visible = false
end

-- Une image : l'anneau suit l'élément désigné (posé de nouveau si l'écran l'a refait) et pulse ; le conseil s'efface quand
-- son geste est fait, ou au bout de sa durée (jamais avant AFFICHAGE_MIN : le temps de le lire)
function Tutoriel:image(dt)
	if not self.k then
		return
	end
	self.temps += dt
	local etape = self.etapes[self.k]
	local cible = etape.cible and etape.cible()
	if cible ~= self.cible then
		self:retirerAnneau()
		if cible then
			self:poserAnneau(cible)
		end
	end
	if self.contour then
		self.contour.Transparency = 0.35 - 0.35 * math.cos(2 * math.pi * self.temps / Tutoriel.PULSATION)
	end
	if self.temps >= Tutoriel.AFFICHAGE_MIN and ((etape.fait and etape.fait(dt)) or (etape.duree and self.temps >= etape.duree)) then
		self:aller(self.k + 1)
	end
end

return Tutoriel
```

Dans `src/client/Atelier/init.client.luau`, remplacer :

```lua
local Mercerie = require(script:WaitForChild("Mercerie"))
```

par :

```lua
local Mercerie = require(script:WaitForChild("Mercerie"))
local Tutoriel = require(script:WaitForChild("Tutoriel"))
```

Dans `src/client/Atelier/init.client.luau`, remplacer :

```lua
}, function()
	fenetre.Visible = false
end)
```

par :

```lua
}, function()
	fenetre.Visible = false
end)
-- (sous-projet 9) Les conseils pas à pas des postes, sur la barre de titre, et « ? » qui les rappelle
local guide = Tutoriel.installer(fenetre, UiKit)
```

Dans `src/client/Atelier/init.client.luau`, remplacer :

```lua
		titre.Size = UDim2.new(1, -76, 0, 32)
```

par :

```lua
		titre.Size = UDim2.new(1, -116, 0, 32)
```

Dans `src/client/Atelier/init.client.luau`, remplacer :

```lua
		titre.Size = UDim2.new(1, -360, 0, 32)
```

par :

```lua
		titre.Size = UDim2.new(1, -410, 0, 32)
```

Dans `src/client/Atelier/init.client.luau`, remplacer :

```lua
		contenu.Position = UDim2.fromOffset(20, 60)
		contenu.Size = UDim2.new(1, -40, 1, -94)
	end
end
```

par :

```lua
		contenu.Position = UDim2.fromOffset(20, 60)
		contenu.Size = UDim2.new(1, -40, 1, -94)
	end
	guide:disposer(panneau)
end
```

Dans `src/client/Atelier/init.client.luau`, remplacer :

```lua
		if fermerEcran then
			fermerEcran()
		end
		contenu:ClearAllChildren()
```

par :

```lua
		guide:arreter() -- (les conseils du poste quitté sont vus)
		if fermerEcran then
			fermerEcran()
		end
		contenu:ClearAllChildren()
```

Dans `src/client/Atelier/init.client.luau`, remplacer :

```lua
		fermerEcran = ECRANS[etat.etape]({ session = session, contenu = contenu, fenetre = fenetre, scene = scene, message = afficherMessage, refus = refus, UiKit = UiKit })
```

par :

```lua
		fermerEcran = ECRANS[etat.etape]({ session = session, contenu = contenu, fenetre = fenetre, scene = scene, message = afficherMessage, refus = refus, UiKit = UiKit, guide = guide })
```

Dans `src/client/Atelier/EcranCouture.luau`, remplacer :

```lua
	local note = UiKit.texte({ Name = "Note", Font = Enum.Font.GothamBold, TextSize = 18, Position = UDim2.fromOffset(0, 124), Size = UDim2.new(1, -46, 0, 22), Parent = panneau })
```

par :

```lua
	local note = UiKit.texte({ Name = "Note", Font = Enum.Font.GothamBold, TextSize = 18, Position = UDim2.fromOffset(0, 124), Size = UDim2.new(1, 0, 0, 22), Parent = panneau })
```

Dans `src/client/Atelier/EcranCouture.luau`, remplacer :

```lua
	local montrerConseil
	UiKit.boutonDoux({ Name = "Aide", Text = "?", TextSize = 18, Position = UDim2.new(1, -40, 0, 120), Size = UDim2.fromOffset(34, 28), Parent = panneau }, function()
		guide = GuideCouture.nouveau() -- les conseils reprennent au premier
		montrerConseil()
	end)
```

par :

```lua
	local montrerConseil
```

Dans `src/client/Atelier/EcranCouture.luau`, remplacer :

```lua
		guide = GuideCouture.nouveau() -- la première robe : les conseils pas à pas
	end
	montrerConseil()
```

par :

```lua
		guide = GuideCouture.nouveau() -- la première robe : les conseils pas à pas
	end
	montrerConseil()
	-- (sous-projet 9) « ? », sur la barre de titre de la fenêtre, reprend ces conseils au premier
	if ctx.guide then
		ctx.guide:demarrer(session, "couture", nil, function()
			guide = GuideCouture.nouveau()
			montrerConseil()
		end)
	end
```

- [ ] **Step 4: Lancer les tests**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT"`
Expected:
```
Unitaires : 269804 vérifications
TOUT EST VERT : 1031 vérifications
```

- [ ] **Step 5: Commit**

```bash
git add src/client/Atelier/Tutoriel.luau src/client/Atelier/init.client.luau src/client/Atelier/EcranCouture.luau tests/unitaires/81_tutoriel.luau tests/unitaires/80_guide_couture.luau
git commit -m "Premiers pas : le bandeau des conseils sur la barre de titre, l'anneau autour de l'élément à toucher, « ? » (la couture y compris)

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 2: L'accueil et les mesures

**Files:**
- Create: `tests/unitaires/82_premiers_pas.luau`
- Modify: `src/client/Atelier/EcranAccueil.luau`, `src/client/Atelier/EcranMesures.luau`, `tests/scenario.luau`

**Interfaces:**
- Consumes: `ctx.guide` et la forme d'une étape (tâche 1) ; `Notation.TOLERANCE_MESURE`, `Clientes.get(id).mesures` (existants).
- Produces: les conseils des postes « accueil » et « mesures ».

- [ ] **Step 1: Écrire les tests**

Créer `tests/unitaires/82_premiers_pas.luau` :

```lua
-- Sous-projet 9 (plan 27) : les premiers pas à l'accueil et aux mesures. À la première robe, le bandeau dit quoi faire et
-- entoure l'élément à toucher ; chaque conseil s'efface quand le geste est fait.
local Tutoriel = U.module("Tutoriel")
local Session = U.module("Session")
local UiKit = U.module("UiKit")
local Clientes = U.module("Clientes")
local EcranAccueil = U.module("EcranAccueil")
local EcranMesures = U.module("EcranMesures")

local function contexte(session)
	local fenetre = UiKit.creer("Frame", { Name = "Fenetre", Size = UDim2.fromOffset(900, 560) })
	local contenu = UiKit.creer("Frame", { Name = "Contenu", Size = UDim2.fromOffset(860, 466), Parent = fenetre })
	return { UiKit = UiKit, session = session, contenu = contenu, fenetre = fenetre, message = function() end, refus = function() end, guide = Tutoriel.installer(fenetre, UiKit) }
end

---------------------------------------------------------------------------
-- L'accueil : la clochette
---------------------------------------------------------------------------
local session = Session.nouvelle(61)
local ctx = contexte(session)
local fermer = EcranAccueil(ctx)
local bandeau = ctx.fenetre.Conseil
U.verifier(bandeau.Visible and bandeau.Text:find("clochette", 1, true) ~= nil and ctx.contenu.Clochette:FindFirstChild("Anneau") ~= nil, "accueil, première robe : sonner la clochette, entourée (" .. bandeau.Text .. ")")
M.avancer(0.5) -- (un bouton qui vient d'apparaître ignore les clics)
ctx.contenu.Clochette.Activated:Fire()
ctx.guide:arreter()
fermer()
U.verifier(session.etat.etape == "mesures" and session.tutorielsVus.accueil, "la cliente entre : les conseils de l'accueil sont vus")

---------------------------------------------------------------------------
-- Les mesures : tourner une molette, ajuster les trois bandes, valider
---------------------------------------------------------------------------
local ctx2 = contexte(session)
local fermer2 = EcranMesures(ctx2)
local contenu = ctx2.contenu
bandeau = ctx2.fenetre.Conseil
U.verifier(bandeau.Visible and bandeau.Text:find("molette", 1, true) ~= nil and contenu.Molette_poitrine:FindFirstChild("Anneau") ~= nil, "mesures : tourner une molette, entourée (" .. bandeau.Text .. ")")
M.avancer(0.5)
U.verifier(bandeau.Text:find("molette", 1, true) ~= nil, "rien tourné : le conseil reste")
contenu.Plus_poitrine.Activated:Fire()
M.avancer(1.6) -- (un conseil reste au moins 2 s, le temps de le lire)
U.verifier(bandeau.Text:find("silhouette", 1, true) ~= nil and contenu.Mannequin:FindFirstChild("Anneau") ~= nil and contenu.Molette_poitrine:FindFirstChild("Anneau") == nil, "une molette tournée : ajuster les bandes, le mannequin entouré (" .. bandeau.Text .. ")")
-- La poitrine juste, la taille et les hanches pas encore : le conseil reste
local cliente = Clientes.get(session.etat.commande.cliente)
local function ajuster(cle)
	for _ = 1, 300 do
		local v = tonumber(contenu["Valeur_" .. cle].Text:match("(%d+) cm")) / 10
		local ecart = cliente.mesures[cle] - v
		if math.abs(ecart) < 0.05 then
			return
		end
		contenu[(if ecart > 0 then "Plus_" else "Moins_") .. cle].Activated:Fire()
	end
end
ajuster("poitrine")
M.avancer(2.1)
U.verifier(bandeau.Text:find("silhouette", 1, true) ~= nil, "une seule bande juste : le conseil reste")
ajuster("taille")
ajuster("hanches")
M.avancer(0.05)
U.verifier(bandeau.Text == "C'est ajusté : valide les mesures." and contenu.ValiderMesures:FindFirstChild("Anneau") ~= nil, "les trois justes : valider, le bouton entouré (" .. bandeau.Text .. ")")
contenu.ValiderMesures.Activated:Fire()
ctx2.guide:arreter()
fermer2()
U.verifier(session.etat.etape == "carnet" and session.tutorielsVus.mesures and session.etat.commande.ajustement == 1, "mesures validées, justes : conseils vus")

---------------------------------------------------------------------------
-- Après une robe livrée : pas de conseils ; « ? » les montre
---------------------------------------------------------------------------
local habituee = Session.nouvelle(62)
habituee.etat.livraisons = 1
assert(habituee:nouvelleCommande().ok and habituee.etat.etape == "mesures")
local ctx3 = contexte(habituee)
local fermer3 = EcranMesures(ctx3)
U.verifier(not ctx3.fenetre.Conseil.Visible and ctx3.fenetre.Aide.Visible, "une robe déjà livrée : pas de conseils, « ? » est là")
M.avancer(0.5)
ctx3.fenetre.Aide.Activated:Fire()
U.verifier(ctx3.fenetre.Conseil.Visible and ctx3.fenetre.Conseil.Text:find("molette", 1, true) ~= nil, "« ? » montre les conseils des mesures")
ctx3.guide:arreter()
fermer3()
```

Dans `tests/scenario.luau`, remplacer :

```lua
verifier(argent() == 150, "150 pièces d'or au départ")
```

par :

```lua
verifier(argent() == 150, "150 pièces d'or au départ")
-- (sous-projet 9) La première robe : un conseil sur la barre de titre, la clochette entourée ; « ? »
verifier(fenetre.Conseil.Visible and fenetre.Conseil.Text:find("clochette", 1, true) ~= nil and boutonNomme("Clochette"):FindFirstChild("Anneau") ~= nil and fenetre.Aide.Visible, "première robe : le conseil de l'accueil (" .. fenetre.Conseil.Text .. ")")
```

Dans `tests/scenario.luau`, remplacer :

```lua
verifier(fenetre.Contenu:FindFirstChild("ReprendreMesures") == nil, "première visite : rien à reprendre")
```

par :

```lua
verifier(fenetre.Contenu:FindFirstChild("ReprendreMesures") == nil, "première visite : rien à reprendre")
verifier(fenetre.Conseil.Visible and fenetre.Conseil.Text:find("molette", 1, true) ~= nil, "(sous-projet 9) première robe : le conseil des mesures (" .. fenetre.Conseil.Text .. ")")
```

Dans `tests/scenario.luau`, remplacer :

```lua
verifier(titre() == "1. Carnet de croquis", "mesures prises : le carnet")
```

par :

```lua
verifier(titre() == "1. Carnet de croquis", "mesures prises : le carnet")
verifier(not fenetre.Conseil.Visible and not fenetre.Aide.Visible, "(sous-projet 9) les mesures quittées : leurs conseils s'en vont avec elles")
```

- [ ] **Step 2: Lancer les tests, vérifier l'échec**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT|attempt|membre" | head -3`
Expected: échec : une ligne qui finit par `ÉCHEC : accueil, première robe : sonner la clochette, entourée ()`

- [ ] **Step 3: Les conseils de l'accueil et des mesures**

Dans `src/client/Atelier/EcranAccueil.luau`, remplacer :

```lua
	UiKit.bouton({
		Name = "Clochette",
```

par :

```lua
	local clochette = UiKit.bouton({
		Name = "Clochette",
```

Dans `src/client/Atelier/EcranAccueil.luau`, remplacer :

```lua
	local connexion = UserInputService.InputBegan:Connect(function(input, traite)
		if not traite and input.KeyCode == Enum.KeyCode.E and ctx.fenetre.Visible and not panneauOuvert() then
			sonner()
		end
	end)
```

par :

```lua
	local connexion = UserInputService.InputBegan:Connect(function(input, traite)
		if not traite and input.KeyCode == Enum.KeyCode.E and ctx.fenetre.Visible and not panneauOuvert() then
			sonner()
		end
	end)
	-- (sous-projet 9) Le premier conseil de la première robe : la clochette
	if ctx.guide then
		ctx.guide:demarrer(ctx.session, "accueil", {
			{
				texte = "Fais sonner la clochette (ou appuie sur E) : ta première cliente entre avec sa commande.",
				cible = function()
					return clochette
				end,
			},
		})
	end
```

Dans `src/client/Atelier/EcranMesures.luau`, remplacer :

```lua
local Clientes = require(Couture:WaitForChild("Clientes"))
```

par :

```lua
local Clientes = require(Couture:WaitForChild("Clientes"))
local Notation = require(Couture:WaitForChild("Notation"))
```

Dans `src/client/Atelier/EcranMesures.luau`, remplacer :

```lua
	UiKit.bouton({ Name = "ValiderMesures",
```

par :

```lua
	local boutonValider = UiKit.bouton({ Name = "ValiderMesures",
```

Dans `src/client/Atelier/EcranMesures.luau`, remplacer :

```lua
	if fiche and fiche.mesures then
		-- La fiche du carnet : ses mesures de la dernière fois
```

par :

```lua
	-- (sous-projet 9) Les conseils de la première robe : tourner une molette, ajuster les trois bandes à la silhouette
	-- (justes à la tolérance de l'ajustement), valider
	if ctx.guide then
		local depart = {}
		for cle, m in pairs(molettes) do
			depart[cle] = m.valeur
		end
		ctx.guide:demarrer(session, "mesures", {
			{
				texte = "Glisse sur une molette, de haut en bas (ou touche − et +) : le mannequin s'élargit ou s'affine.",
				cible = function()
					return elements.poitrine.bouton
				end,
				fait = function()
					for cle, m in pairs(molettes) do
						if m.valeur ~= depart[cle] then
							return true
						end
					end
					return false
				end,
			},
			{
				texte = "Fais coïncider chaque bande avec la silhouette en pointillé : la poitrine, la taille et les hanches.",
				cible = function()
					return mannequin
				end,
				fait = function()
					for cle, m in pairs(molettes) do
						if math.abs(m.valeur - cliente.mesures[cle]) > Notation.TOLERANCE_MESURE + 1e-9 then
							return false
						end
					end
					return true
				end,
			},
			{
				texte = "C'est ajusté : valide les mesures.",
				cible = function()
					return boutonValider
				end,
			},
		})
	end
	if fiche and fiche.mesures then
		-- La fiche du carnet : ses mesures de la dernière fois
```

- [ ] **Step 4: Lancer les tests**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT"`
Expected:
```
Unitaires : 269814 vérifications
TOUT EST VERT : 1035 vérifications
```

- [ ] **Step 5: Commit**

```bash
git add src/client/Atelier/EcranAccueil.luau src/client/Atelier/EcranMesures.luau tests/unitaires/82_premiers_pas.luau tests/scenario.luau
git commit -m "Premiers pas : les conseils de l'accueil (la clochette) et des mesures (tourner une molette, ajuster les trois bandes, valider)

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

Construire le lieu du dépôt dans un dossier temporaire (`C:/dev/jeux/roblox-maker/rojo.exe build -o <dossier temporaire>/Plan27Depot.rbxl`) et l'ouvrir dans Studio (ne toucher à aucune autre fenêtre de Studio). En édition (`execute_luau`, Edit) : dans un `ScreenGui` d'essai de `StarterGui`, une fenêtre comme celle du jeu (titre, argent, son, croix), `Tutoriel.installer`, et l'écran des mesures d'un `EtatAtelier` neuf (une session simulée) ; le regarder (`screen_capture`), puis supprimer le `ScreenGui`. Enfin en Play : attendre 4 s, relever la console.

Expected : le bandeau du premier conseil sur la barre de titre (texte entier, contour sur le bord), « ? » entre le bandeau et l'argent, l'anneau autour de la molette de la poitrine ; aucune alerte de notre code (« Lieu non publié » et les messages internes de Roblox mis à part). Arrêter Play et fermer cette fenêtre de Studio (sans enregistrer).

- [ ] **Step 2: Mettre à jour le README**

Dans `README.md`, remplacer :

```markdown
## État actuel (sous-projet 8, plans 25 et 26 : la couture guidée)
```

par :

```markdown
## État actuel (sous-projet 9 en cours, plan 27 : les premiers pas — le bandeau, l'accueil, les mesures)
```

Dans `README.md`, remplacer :

```markdown
qu'une copie de l'état. Dans un jeu publié, la partie est sauvegardée (argent, stock de tissu, dix dernières
robes et commande en cours : une déconnexion ne perd pas le travail) :
```

par :

```markdown
qu'une copie de l'état. Dans un jeu publié, la partie est sauvegardée (argent, stock de tissu, dix dernières
robes et commande en cours : une déconnexion ne perd pas le travail).

**Les premiers pas** (sous-projet 9) : à la première robe (aucune robe livrée ni vendue), un bandeau sur la barre de
titre de la fenêtre donne un conseil à la fois et entoure d'un anneau l'élément à toucher ; chaque conseil s'efface
quand le geste est fait. Ensuite, le bouton « ? » de la barre de titre les rappelle. Pour l'instant : l'accueil (la
clochette), les mesures (tourner une molette, ajuster les trois bandes, valider) et la couture (ses propres conseils).

Une commande, poste par poste :
```

- [ ] **Step 3: Tests, lieu régénéré, commit**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT"`
Expected:
```
Unitaires : 269814 vérifications
TOUT EST VERT : 1035 vérifications
```

```bash
C:/dev/jeux/roblox-maker/rojo.exe build -o AtelierCouture.rbxl
git add README.md AtelierCouture.rbxl
git commit -m "Plan 27 terminé : les premiers pas, le bandeau et les mesures

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```
