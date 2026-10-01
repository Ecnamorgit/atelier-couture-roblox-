# Aiguille & Dentelle — Plan 28 : les premiers pas, du carnet à l'épinglage

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** À la première robe, le carnet, l'achat, la découpe et l'épinglage donnent leurs conseils pas à pas, avec le bandeau et l'anneau du plan 27.

**Architecture:** Chaque écran appelle `ctx.guide:demarrer(session, poste, etapes)` à la fin de sa construction ; ses conseils lisent son propre état (le croquis et les tissus en cours du carnet, le stock, la place de la pièce sur la table, les pièces coupées et épinglées). Rien d'autre ne change.

**Tech Stack:** Luau, Rojo 7.7.0-rc.1, simulation Luau 0.650 (`tests/lancer.sh`), Roblox Studio via le connecteur MCP Studio.

**Spec:** `docs/superpowers/specs/2026-10-01-premiers-pas-design.md` (section 3 ; plan 28 de la section 5).

## Décisions de ce plan

- **Carnet** : (1) un modèle par partie avec ◀ ▶ (▶ du corsage entouré) — s'efface dès qu'un modèle change ; (2) toucher une partie du dessin, ou sa ligne, pour choisir un tissu (le dessin) — dès qu'un tissu change ; (3) la fiche de la cliente, ses jauges (la fiche, à lire : 7 s) ; (4) tracer le patron (le bouton).
- **Achat** : (1) acheter chaque tissu, le métrage proposé suffit (le premier « Acheter » d'un tissu qui manque) — s'efface quand le stock neuf de chaque tissu atteint le métrage conseillé ; (2) aller à la découpe (le bouton).
- **Découpe** : la table pose déjà chaque pièce à la place que prévoit le métrage (plan 23) : (1) on peut la faire glisser ou la tourner (la pièce) — s'efface au premier déplacement ou au bout de 8 s ; (2) le droit-fil (son indicateur, à lire : 6 s) ; (3) couper (le bouton) — dès qu'une pièce est coupée ; (4) les autres pièces, A / D, les onglets (à lire : 7 s, sans anneau : le scénario compte les enfants de la liste des pièces).
- **Épinglage** (panneau) : (1) toucher une pièce (la première non épinglée) — dès qu'une pièce est épinglée ; (2) les épingler toutes, les couches en dernier (la suivante non épinglée), jusqu'à la couture.
- **Textes** : au plus deux lignes du bandeau (vérifié dans Studio : fenêtre centrée et panneau).
- **L'anneau** (relecture du plan 27) : un cadre de la fenêtre recalé sur l'élément ; une liste qui défile ou que l'écran vide ne le perd pas. Les tests vérifient l'élément désigné (`ctx.guide.cible` et l'attribut `Cible` de l'anneau).
- **Vérifié pendant la préparation** : le plan a été joué entièrement sur un brouillon tiré de `main` (plan 27 fusionné) ; dix variantes du brouillon échouent sur la vérification qui les garde ; dans Studio, tous les conseils des plans 27 à 29 tiennent dans le bandeau.

## Global Constraints

- **Dépôt** : `C:\dev\jeux\atelier-couture`, branche `premiers-pas-atelier`, créée depuis `main`. Selon les règles du commanditaire : la branche testée et relue est fusionnée dans `main` et poussée sur GitHub.
- **Rojo** : `C:/dev/jeux/roblox-maker/rojo.exe`.
- **Contenu original** : aucun nom, texte, image ni son de *Dressmaker*.
- **Contraintes des plans précédents toujours valables** : fins de ligne LF, commits en français terminés par `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`, textes d'au moins 14 px (et aucun texte laissé à « Label »), le serveur fait foi.

## Review Focus

- **Le joueur valide le carnet sans attendre les conseils.** Attendu : le carnet se ferme comme avant ; ses conseils sont vus. Test : `83_premiers_pas_atelier` (vus à la fermeture).
- **Le joueur garde la place proposée et coupe tout de suite.** Attendu : le premier conseil de la découpe s'efface seul (8 s), puis les suivants ; rien ne bloque. Test : `83_premiers_pas_atelier`.
- **Une robe en deux tissus.** Attendu : le conseil de l'achat désigne le « Acheter » d'un tissu qui manque encore, et ne s'efface que quand les deux sont achetés. Test : `83_premiers_pas_atelier`.
- **L'épinglage.** Attendu : l'anneau passe à la pièce suivante à épingler. Test : `83_premiers_pas_atelier`.
- **Le scénario (une première robe entière).** Attendu : le bandeau à chaque poste, et rien de changé au jeu. Test : scénario.

---

### Task 1: Le carnet, l'achat, la découpe et l'épinglage

**Files:**
- Create: `tests/unitaires/83_premiers_pas_atelier.luau`
- Modify: `src/client/Atelier/EcranCarnet.luau`, `src/client/Atelier/EcranAchat.luau`, `src/client/Atelier/EcranDecoupe.luau`, `src/client/Atelier/EcranEpinglage.luau`, `tests/scenario.luau`

**Interfaces:**
- Consumes: `ctx.guide` (`demarrer`, `arreter`), `Tutoriel.installer`, la forme d'une étape `{ texte, cible?, fait?, duree? }` (plan 27) ; `EtatAtelier:tissusUtilises()`, `EtatAtelier:stockNeuf(id)`, `etat.coupees`, `etat.epinglees` (existants).
- Produces: les conseils des postes « carnet », « achat », « decoupe », « epinglage ».

- [ ] **Step 1: Écrire les tests**

Créer `tests/unitaires/83_premiers_pas_atelier.luau` :

```lua
-- Sous-projet 9 (plan 28) : les premiers pas du carnet à l'épinglage. À la première robe, chaque poste donne ses conseils
-- un à un ; chacun s'efface quand le geste est fait (ou, s'il ne demande que de lire, après sa durée).
local Tutoriel = U.module("Tutoriel")
local Session = U.module("Session")
local UiKit = U.module("UiKit")
local Patron = U.module("Patron")
local Metrage = U.module("Metrage")
local EcranCarnet = U.module("EcranCarnet")
local EcranAchat = U.module("EcranAchat")
local EcranDecoupe = U.module("EcranDecoupe")
local EcranEpinglage = U.module("EcranEpinglage")

local CROQUIS = { corsage = "corsage_droit", manches = "manches_sans", col = "col_sans", jupe = "jupe_droite" }
local ids = Patron.piecesDuCroquis(CROQUIS)
local function contexte(session)
	local fenetre = UiKit.creer("Frame", { Name = "Fenetre", Size = UDim2.fromOffset(900, 560) })
	local contenu = UiKit.creer("Frame", { Name = "Contenu", Size = UDim2.fromOffset(860, 466), Parent = fenetre })
	return { UiKit = UiKit, session = session, contenu = contenu, fenetre = fenetre, message = function() end, refus = function() end, guide = Tutoriel.installer(fenetre, UiKit) }
end
-- L'élément que désigne l'anneau (un cadre de la fenêtre, recalé sur lui : plan 27)
local function entoure(ctx, element)
	local a = ctx.fenetre:FindFirstChild("Anneau")
	return a ~= nil and ctx.guide.cible == element and a:GetAttribute("Cible") == element.Name
end
-- Une session de première robe, menée jusqu'à l'étape voulue (en coton blanc)
local function sessionJusqua(graine, etape)
	local session = Session.nouvelle(graine)
	U.commander(session)
	if etape == "carnet" then
		return session
	end
	local tissus = {}
	for _, id in ipairs(ids) do
		tissus[id] = "coton_blanc"
	end
	assert(session:validerCroquis(CROQUIS, tissus).ok)
	session.etat.argent = 1000
	if etape == "achat" then
		return session
	end
	local placements, longueur = Metrage.disposition(ids)
	assert(session:acheter("coton_blanc", longueur).ok and session:commencerDecoupe().ok)
	if etape == "decoupe" then
		return session
	end
	for _, id in ipairs(ids) do
		assert(session:couper(id, placements[id]).ok, id)
	end
	assert(session.etat.etape == "epinglage")
	return session
end

---------------------------------------------------------------------------
-- Le carnet : un modèle, un tissu, la fiche de la cliente, tracer le patron
---------------------------------------------------------------------------
local session = sessionJusqua(71, "carnet")
local ctx = contexte(session)
local fermer = EcranCarnet(ctx)
local bandeau, page = ctx.fenetre.Conseil, ctx.contenu.Page
U.verifier(bandeau.Visible and bandeau.Text:find("modèle", 1, true) ~= nil and entoure(ctx, page.Suivant_corsage), "carnet : choisir un modèle, ▶ entouré (" .. bandeau.Text .. ")")
M.avancer(0.5)
page.Suivant_corsage.Activated:Fire()
M.avancer(1.6)
U.verifier(bandeau.Text:find("tissu", 1, true) ~= nil and entoure(ctx, page.Dessin), "un modèle changé : choisir un tissu, le dessin entouré (" .. bandeau.Text .. ")")
local ligne = nil
for _, c in ipairs(page.Pieces:GetChildren()) do
	if c.Name:sub(1, 6) == "Tissu_" then
		ligne = c
		break
	end
end
ligne.Activated:Fire()
M.avancer(0.5)
ctx.contenu.ChoixTissu.Grille.Tissu_coton_blanc.Activated:Fire()
M.avancer(2.1)
U.verifier(bandeau.Text:find("fiche", 1, true) ~= nil and entoure(ctx, ctx.contenu.Droite), "un tissu choisi : la fiche de la cliente, entourée (" .. bandeau.Text .. ")")
M.avancer(5)
U.verifier(bandeau.Text:find("fiche", 1, true) ~= nil, "un conseil à lire reste le temps de sa durée")
M.avancer(2.2)
U.verifier(bandeau.Text == "Ta robe te plaît ? Trace le patron." and entoure(ctx, page.Valider), "lu : tracer le patron, le bouton entouré (" .. bandeau.Text .. ")")
ctx.guide:arreter()
fermer()
U.verifier(session.tutorielsVus.carnet, "le carnet quitté : ses conseils sont vus")

---------------------------------------------------------------------------
-- L'achat : acheter chaque tissu, puis aller à la découpe
---------------------------------------------------------------------------
local s2 = sessionJusqua(72, "achat")
local ctx2 = contexte(s2)
local fermer2 = EcranAchat(ctx2)
local bandeau2, acheter = ctx2.fenetre.Conseil, ctx2.contenu.Lignes.Ligne_coton_blanc.Acheter
U.verifier(bandeau2.Visible and bandeau2.Text:find("Achète", 1, true) ~= nil and entoure(ctx2, acheter), "achat : acheter le tissu, « Acheter » entouré (" .. bandeau2.Text .. ")")
M.avancer(2.1)
U.verifier(bandeau2.Text:find("Achète", 1, true) ~= nil, "rien acheté : le conseil reste")
acheter.Activated:Fire()
M.avancer(0.1)
U.verifier(bandeau2.Text == "Tout est acheté : va à la découpe." and entoure(ctx2, ctx2.contenu.AllerDecoupe), "le métrage acheté : aller à la découpe, le bouton entouré (" .. bandeau2.Text .. ")")
ctx2.guide:arreter()
fermer2()
-- Une robe en deux tissus : le conseil désigne le tissu qui manque encore, et reste tant qu'il en manque un
do
	local s6 = Session.nouvelle(76)
	U.commander(s6)
	local deux = {}
	for _, id in ipairs(ids) do
		deux[id] = if id:find("^jupe") then "lin_naturel" else "coton_blanc"
	end
	assert(s6:validerCroquis(CROQUIS, deux).ok)
	s6.etat.argent = 1000
	local ctx6 = contexte(s6)
	local fermer6 = EcranAchat(ctx6)
	local lignes6, bandeau6 = ctx6.contenu.Lignes, ctx6.fenetre.Conseil
	M.avancer(2.1)
	lignes6.Ligne_coton_blanc.Acheter.Activated:Fire()
	M.avancer(0.1)
	U.verifier(bandeau6.Text:find("Achète", 1, true) ~= nil and entoure(ctx6, lignes6.Ligne_lin_naturel.Acheter) and not entoure(ctx6, lignes6.Ligne_coton_blanc.Acheter), "deux tissus, un acheté : le conseil reste, l'autre « Acheter » entouré")
	lignes6.Ligne_lin_naturel.Acheter.Activated:Fire()
	M.avancer(0.1)
	U.verifier(bandeau6.Text == "Tout est acheté : va à la découpe.", "les deux achetés : aller à la découpe")
	ctx6.guide:arreter()
	fermer6()
end

---------------------------------------------------------------------------
-- La découpe : la place proposée (glisser, tourner), le droit-fil, couper, les autres pièces
---------------------------------------------------------------------------
local s3 = sessionJusqua(73, "decoupe")
local ctx3 = contexte(s3)
local fermer3 = EcranDecoupe(ctx3)
local bandeau3, panneau = ctx3.fenetre.Conseil, ctx3.contenu.Panneau
local pieceCourante = ctx3.contenu.Rouleau.Tissu.PieceCourante
U.verifier(bandeau3.Visible and bandeau3.Text:find("bonne place", 1, true) ~= nil and entoure(ctx3, pieceCourante), "découpe : la place proposée, la pièce entourée (" .. bandeau3.Text .. ")")
M.avancer(0.5)
panneau.Tourner15.Activated:Fire()
M.avancer(1.6)
U.verifier(bandeau3.Text:find("droit-fil", 1, true) ~= nil and entoure(ctx3, panneau.DroitFil), "la pièce tournée : le droit-fil, entouré (" .. bandeau3.Text .. ")")
panneau["Tourner-15"].Activated:Fire()
M.avancer(6.1)
U.verifier(bandeau3.Text:find("coupe la pièce", 1, true) ~= nil and entoure(ctx3, panneau.Couper), "lu : couper, le bouton entouré (" .. bandeau3.Text .. ")")
panneau.Couper.Activated:Fire()
M.avancer(2.1)
U.verifier(bandeau3.Text:find("Coupe les autres", 1, true) ~= nil and next(s3.etat.coupees) ~= nil, "une pièce coupée : la suite (" .. bandeau3.Text .. ")")
M.avancer(7.1)
U.verifier(not bandeau3.Visible and s3.tutorielsVus.decoupe, "lu : les conseils de la découpe sont finis")
ctx3.guide:arreter()
fermer3()

---------------------------------------------------------------------------
-- L'épinglage : une pièce, puis toutes
---------------------------------------------------------------------------
local s4 = sessionJusqua(74, "epinglage")
local ctx4 = contexte(s4)
local fermer4 = EcranEpinglage(ctx4)
local bandeau4, liste = ctx4.fenetre.Conseil, ctx4.contenu.Liste
U.verifier(bandeau4.Visible and bandeau4.Text:find("épingler", 1, true) ~= nil and entoure(ctx4, liste.Epingler_corsage_droit_devant), "épinglage : la première pièce entourée (" .. bandeau4.Text .. ")")
M.avancer(0.5)
liste.Epingler_corsage_droit_devant.Activated:Fire()
M.avancer(2)
U.verifier(bandeau4.Text:find("toutes", 1, true) ~= nil and entoure(ctx4, liste.Epingler_corsage_droit_dos) and not entoure(ctx4, liste.Epingler_corsage_droit_devant), "une pièce épinglée : toutes les autres, la suivante entourée (" .. bandeau4.Text .. ")")
ctx4.guide:arreter()
fermer4()

-- Après une robe livrée : pas de conseils
local s5 = sessionJusqua(75, "epinglage")
s5.etat.livraisons = 1
local ctx5 = contexte(s5)
local fermer5 = EcranEpinglage(ctx5)
U.verifier(not ctx5.fenetre.Conseil.Visible and ctx5.fenetre.Aide.Visible, "une robe déjà livrée : pas de conseils, « ? » est là")
ctx5.guide:arreter()
fermer5()
```

Dans `tests/scenario.luau`, remplacer :

```lua
verifier(not fenetre.Conseil.Visible and not fenetre.Aide.Visible, "(sous-projet 9) les mesures quittées : leurs conseils s'en vont avec elles")
```

par :

```lua
verifier(fenetre.Conseil.Visible and fenetre.Conseil.Text:find("modèle", 1, true) ~= nil and fenetre.Aide.Visible, "(sous-projet 9) première robe, au carnet : ses conseils (" .. fenetre.Conseil.Text .. ")")
```

Dans `tests/scenario.luau`, remplacer :

```lua
verifier(titre() == "2. Achat du tissu", "le croquis validé mène à l'achat")
```

par :

```lua
verifier(titre() == "2. Achat du tissu", "le croquis validé mène à l'achat")
verifier(fenetre.Conseil.Visible and fenetre.Conseil.Text:find("Achète", 1, true) ~= nil, "(sous-projet 9) première robe, à l'achat : ses conseils (" .. fenetre.Conseil.Text .. ")")
```

Dans `tests/scenario.luau`, remplacer :

```lua
verifier(titre() == "3. Table de découpe", "l'achat mène à la découpe")
```

par :

```lua
verifier(titre() == "3. Table de découpe", "l'achat mène à la découpe")
verifier(fenetre.Conseil.Visible and fenetre.Conseil.Text:find("bonne place", 1, true) ~= nil, "(sous-projet 9) première robe, à la découpe : ses conseils (" .. fenetre.Conseil.Text .. ")")
```

Dans `tests/scenario.luau`, remplacer :

```lua
verifier(titre() == "4. Épinglage", "après la dernière coupe : l'épinglage")
```

par :

```lua
verifier(titre() == "4. Épinglage", "après la dernière coupe : l'épinglage")
verifier(fenetre.Conseil.Visible and fenetre.Conseil.Text:find("épingler", 1, true) ~= nil, "(sous-projet 9) première robe, à l'épinglage : ses conseils, en panneau (" .. fenetre.Conseil.Text .. ")")
```

Dans `tests/scenario.luau`, remplacer :

```lua
verifier(titre() == "6. Décorations", "robe cousue : les décorations")
```

par :

```lua
verifier(titre() == "6. Décorations", "robe cousue : les décorations")
verifier(not fenetre.Conseil.Visible and not fenetre.Aide.Visible, "(sous-projet 9) la couture quittée : son « ? » s'en va avec elle")
```

- [ ] **Step 2: Lancer les tests, vérifier l'échec**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT|attempt|membre" | head -3`
Expected: échec : une ligne qui finit par `ÉCHEC : carnet : choisir un modèle, ▶ entouré ()`

- [ ] **Step 3: Les conseils des quatre postes**

Dans `src/client/Atelier/EcranCarnet.luau`, remplacer :

```lua
	UiKit.bouton({ Name = "Valider", Text = "Tracer le patron",
```

par :

```lua
	local boutonValider = UiKit.bouton({ Name = "Valider", Text = "Tracer le patron",
```

Dans `src/client/Atelier/EcranCarnet.luau`, remplacer :

```lua
	return function()
		desabonner()
		fermerChoix()
	end
end
```

par :

```lua
	-- (sous-projet 9) Les conseils de la première robe : un modèle par partie, un tissu, la fiche de la cliente, le patron
	if ctx.guide then
		local croquisDepart, tissusDepart = table.clone(croquis), table.clone(tissus)
		ctx.guide:demarrer(session, "carnet", {
			{
				texte = "Choisis un modèle pour chaque partie avec ◀ ▶ : le corsage, les manches, le col et la jupe.",
				cible = function()
					return page:FindFirstChild("Suivant_corsage")
				end,
				fait = function()
					for famille, id in pairs(croquis) do
						if croquisDepart[famille] ~= id then
							return true
						end
					end
					return false
				end,
			},
			{
				texte = "Touche une partie du dessin (ou sa ligne dans la liste) pour lui choisir un tissu.",
				cible = function()
					return dessin
				end,
				fait = function()
					for id, t in pairs(tissus) do
						if tissusDepart[id] ~= t then
							return true
						end
					end
					return false
				end,
			},
			{
				texte = "À droite, la fiche dit ce que veut la cliente : tes modèles et tes tissus remplissent ses jauges.",
				cible = function()
					return droite
				end,
				duree = 7,
			},
			{
				texte = "Ta robe te plaît ? Trace le patron.",
				cible = function()
					return boutonValider
				end,
			},
		})
	end
	return function()
		desabonner()
		fermerChoix()
	end
end
```

Dans `src/client/Atelier/EcranAchat.luau`, remplacer :

```lua
	UiKit.bouton({ Name = "AllerDecoupe",
```

par :

```lua
	local boutonDecoupe = UiKit.bouton({ Name = "AllerDecoupe",
```

Dans `src/client/Atelier/EcranAchat.luau`, remplacer :

```lua
	return function()
		desabonner()
		fermerApercu()
	end
end
```

par :

```lua
	-- (sous-projet 9) Les conseils de la première robe : acheter chaque tissu (le métrage proposé), aller à la découpe
	if ctx.guide then
		ctx.guide:demarrer(session, "achat", {
			{
				texte = "Achète chaque tissu : le métrage proposé suffit si tu ranges bien tes pièces.",
				cible = function()
					for _, idTissu in ipairs(session.etat:tissusUtilises()) do
						if lignes[idTissu] and session.etat:stockNeuf(idTissu) < conseil(idTissu) then
							return lignes[idTissu].acheter
						end
					end
					return nil
				end,
				fait = function()
					for _, idTissu in ipairs(session.etat:tissusUtilises()) do
						if session.etat:stockNeuf(idTissu) < conseil(idTissu) then
							return false
						end
					end
					return true
				end,
			},
			{
				texte = "Tout est acheté : va à la découpe.",
				cible = function()
					return boutonDecoupe
				end,
			},
		})
	end
	return function()
		desabonner()
		fermerApercu()
	end
end
```

Dans `src/client/Atelier/EcranDecoupe.luau`, remplacer :

```lua
	rafraichir()
	montrerPiece()
	return function()
		desabonner()
		lierDerouler(false)
```

par :

```lua
	rafraichir()
	montrerPiece()
	-- (sous-projet 9) Les conseils de la première robe : la place que propose la table, le droit-fil, couper, la suite
	if ctx.guide then
		local depart = table_.placement and table.clone(table_.placement)
		local function coupees()
			local n = 0
			for _ in pairs(session.etat.coupees) do
				n += 1
			end
			return n
		end
		local coupeesDepart = coupees()
		ctx.guide:demarrer(session, "decoupe", {
			{
				texte = "La table pose chaque pièce à une bonne place : tu peux la faire glisser sur le tissu, ou la tourner (R, la molette).",
				cible = function()
					return piece
				end,
				fait = function()
					local p = table_.placement
					return p ~= nil and depart ~= nil and (p.x ~= depart.x or p.y ~= depart.y or p.angle ~= depart.angle)
				end,
				duree = 8,
			},
			{
				texte = "Le droit-fil : la flèche de la pièce doit suivre le fil du tissu ; à 100 %, la robe ne perd rien.",
				cible = function()
					return droitFil
				end,
				duree = 6,
			},
			{
				texte = "La place est libre (en vert) : coupe la pièce.",
				cible = function()
					return couper
				end,
				fait = function()
					return coupees() > coupeesDepart
				end,
			},
			{
				texte = "Coupe les autres pièces de la même façon ; A / D déroulent le rouleau, les onglets changent de tissu.",
				duree = 7,
			},
		})
	end
	return function()
		desabonner()
		lierDerouler(false)
```

Dans `src/client/Atelier/EcranEpinglage.luau`, remplacer :

```lua
	local desabonner = session:surChangement(rafraichir)
	rafraichir()
	return function()
		desabonner()
	end
end
```

par :

```lua
	local desabonner = session:surChangement(rafraichir)
	rafraichir()
	-- (sous-projet 9) Les conseils de la première robe : épingler une pièce, puis toutes (les couches en dernier)
	if ctx.guide then
		local function epinglees()
			local n = 0
			for _ in pairs(session.etat.epinglees) do
				n += 1
			end
			return n
		end
		local epingleesDepart = epinglees()
		ctx.guide:demarrer(session, "epinglage", {
			{
				texte = "Touche une pièce pour l'épingler sur le mannequin.",
				cible = function()
					for _, id in ipairs(pieces) do
						if not session.etat.epinglees[id] then
							return liste:FindFirstChild("Epingler_" .. id)
						end
					end
					return nil
				end,
				fait = function()
					return epinglees() > epingleesDepart
				end,
			},
			{
				texte = "Épingle-les toutes ; les couches se posent en dernier, par-dessus.",
				cible = function()
					for _, id in ipairs(pieces) do
						if not session.etat.epinglees[id] then
							return liste:FindFirstChild("Epingler_" .. id)
						end
					end
					return nil
				end,
			},
		})
	end
	return function()
		desabonner()
	end
end
```

- [ ] **Step 4: Lancer les tests**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT"`
Expected:
```
Unitaires : 269845 vérifications
TOUT EST VERT : 1039 vérifications
```

- [ ] **Step 5: Commit**

```bash
git add src/client/Atelier/EcranCarnet.luau src/client/Atelier/EcranAchat.luau src/client/Atelier/EcranDecoupe.luau src/client/Atelier/EcranEpinglage.luau tests/unitaires/83_premiers_pas_atelier.luau tests/scenario.luau
git commit -m "Premiers pas : les conseils du carnet, de l'achat, de la découpe et de l'épinglage

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 2: Studio, README, lieu régénéré

**Files:**
- Modify: `README.md`, `AtelierCouture.rbxl` (régénéré)

**Interfaces:**
- Consumes: tout ce qui précède.
- Produces: rien de nouveau.

- [ ] **Step 1: Dans Studio, par le connecteur MCP**

Construire le lieu du dépôt dans un dossier temporaire (`C:/dev/jeux/roblox-maker/rojo.exe build -o <dossier temporaire>/Plan28Depot.rbxl`) et l'ouvrir dans Studio (ne toucher à aucune autre fenêtre de Studio). En édition (`execute_luau`, Edit) : dans un `ScreenGui` d'essai de `StarterGui`, une fenêtre de 900 px et une de 380 px (en panneau), chacune avec `Tutoriel.installer` ; y mettre tour à tour chaque conseil de ce plan et relever `TextFits` ; regarder (`screen_capture`), puis supprimer le `ScreenGui`. Enfin en Play : attendre 4 s, relever la console.

Expected : chaque conseil tient dans le bandeau ; aucune alerte de notre code (« Lieu non publié » et les messages internes de Roblox mis à part). Arrêter Play et fermer cette fenêtre de Studio (sans enregistrer).

- [ ] **Step 2: Mettre à jour le README**

Dans `README.md`, remplacer :

```markdown
## État actuel (sous-projet 9 en cours, plan 27 : les premiers pas — le bandeau, l'accueil, les mesures)
```

par :

```markdown
## État actuel (sous-projet 9 en cours, plans 27 et 28 : les premiers pas, de l'accueil à l'épinglage)
```

Dans `README.md`, remplacer :

```markdown
quand le geste est fait. Ensuite, le bouton « ? » de la barre de titre les rappelle. Pour l'instant : l'accueil (la
clochette), les mesures (tourner une molette, ajuster les trois bandes, valider) et la couture (ses propres conseils).
```

par :

```markdown
quand le geste est fait. Ensuite, le bouton « ? » de la barre de titre les rappelle. Pour l'instant : l'accueil (la
clochette), les mesures (tourner une molette, ajuster les trois bandes, valider), le carnet (un modèle, un tissu, la
fiche de la cliente, tracer le patron), l'achat (le métrage proposé), la découpe (la place proposée, le droit-fil,
couper), l'épinglage et la couture (ses propres conseils).
```

- [ ] **Step 3: Tests, lieu régénéré, commit**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT"`
Expected:
```
Unitaires : 269845 vérifications
TOUT EST VERT : 1039 vérifications
```

```bash
C:/dev/jeux/roblox-maker/rojo.exe build -o AtelierCouture.rbxl
git add README.md AtelierCouture.rbxl
git commit -m "Plan 28 terminé : les premiers pas, du carnet à l'épinglage

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```
