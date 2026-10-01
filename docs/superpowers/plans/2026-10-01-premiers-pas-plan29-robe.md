# Aiguille & Dentelle — Plan 29 : les premiers pas, les décorations et la photo

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** À la première robe, les décorations et la photo donnent leurs conseils pas à pas ; chaque poste de l'atelier a désormais les siens.

**Architecture:** Comme au plan 28 : chaque écran appelle `ctx.guide:demarrer(session, poste, etapes)`. Les décorations retiennent si le joueur a déjà tourné la vue (un drapeau posé au glisser sur la scène) ; la photo compte les prises (existant). Rien d'autre ne change.

**Tech Stack:** Luau, Rojo 7.7.0-rc.1, simulation Luau 0.650 (`tests/lancer.sh`), Roblox Studio via le connecteur MCP Studio.

**Spec:** `docs/superpowers/specs/2026-10-01-premiers-pas-design.md` (section 3 ; plan 29 de la section 5).

## Décisions de ce plan

- **Décorations** (panneau) : (1) choisir dans la palette (la palette) — s'efface dès qu'une décoration est choisie ; (2) toucher la robe pour la poser (la scène : pas d'anneau) — dès qu'une décoration est posée ou qu'une garniture est commencée ; (3) tourner la vue en glissant — dès que la vue a tourné, ou au bout de 10 s ; (4) les outils, Q / E (« 15° » entouré, à lire : 6 s) ; (5) présenter (le bouton).
- **Photo** (panneau, une commande seulement : la première robe n'est jamais une robe libre) : (1) choisir un décor et une lumière, prendre la photo (le bouton) — dès qu'une photo est prise ; (2) livrer, deux appuis (le bouton).
- **L'anneau sous les calques** (relecture du plan 28) : il se range dans le contenu de l'écran, sous la mercerie (décorations) et l'aperçu de la photo ; les tests vérifient l'élément désigné (`ctx.guide.cible`, l'attribut `Cible`).
- **Le refus** n'a pas de conseils : quitter la photo pour le refus retire bandeau et « ? » (le scénario le vérifie : c'est la preuve que le script du client ferme les conseils du poste quitté).
- **Vérifié pendant la préparation** : le plan a été joué entièrement sur un brouillon tiré de `main` (plan 28 fusionné) ; huit variantes du brouillon échouent sur la vérification qui les garde ; dans Studio, tous les conseils tiennent dans le bandeau.

## Global Constraints

- **Dépôt** : `C:\dev\jeux\atelier-couture`, branche `premiers-pas-robe`, créée depuis `main`. Selon les règles du commanditaire : la branche testée et relue est fusionnée dans `main` et poussée sur GitHub.
- **Rojo** : `C:/dev/jeux/roblox-maker/rojo.exe`.
- **Contenu original** : aucun nom, texte, image ni son de *Dressmaker*.
- **Contraintes des plans précédents toujours valables** : fins de ligne LF, commits en français terminés par `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`, textes d'au moins 14 px (et aucun texte laissé à « Label »), le serveur fait foi.

## Review Focus

- **Une garniture (un ruban) plutôt qu'un objet.** Attendu : son premier point suffit pour passer au conseil suivant. Test : `84_premiers_pas_robe`.
- **Le joueur ne tourne jamais la vue.** Attendu : le conseil s'efface au bout de 10 s ; rien ne bloque. Test : `84_premiers_pas_robe` (le conseil reste tant que la vue n'a pas tourné, avant 10 s).
- **La photo qui échoue (Roblox refuse la capture).** Attendu : la prise compte quand même (le joueur a essayé) ; « Livrer » est désigné. Test : par la lecture du code (`prises` augmente avant la capture).
- **Un joueur qui a déjà livré une robe.** Attendu : pas de conseils ; « ? » les montre. Test : `84_premiers_pas_robe`.
- **Le scénario (une première robe entière, puis un refus).** Attendu : le bandeau aux décorations et à la photo ; au refus, ni bandeau ni « ? ». Test : scénario.

---

### Task 1: Les décorations et la photo

**Files:**
- Create: `tests/unitaires/84_premiers_pas_robe.luau`
- Modify: `src/client/Atelier/EcranDecorations.luau`, `src/client/Atelier/EcranPresentation.luau`, `tests/scenario.luau`

**Interfaces:**
- Consumes: `ctx.guide` (`demarrer`, `arreter`, `disposer`), `Tutoriel.installer`, la forme d'une étape (plan 27) ; `Decorateur` (`choix`, `liste`, `garniture`), `scene:orbiter` (existants).
- Produces: les conseils des postes « decorations » et « photo ».

- [ ] **Step 1: Écrire les tests**

Créer `tests/unitaires/84_premiers_pas_robe.luau` :

```lua
-- Sous-projet 9 (plan 29) : les premiers pas des décorations et de la photo. À la première robe : choisir une décoration,
-- la poser, tourner la vue, les outils, présenter ; puis prendre la photo et livrer.
local Tutoriel = U.module("Tutoriel")
local Session = U.module("Session")
local UiKit = U.module("UiKit")
local Patron = U.module("Patron")
local Metrage = U.module("Metrage")
local Catalogue = U.module("Catalogue")
local EcranDecorations = U.module("EcranDecorations")
local EcranPresentation = U.module("EcranPresentation")
local UIS = M.services.UserInputService

local CROQUIS = { corsage = "corsage_droit", manches = "manches_sans", col = "col_sans", jupe = "jupe_droite" }
local ids = Patron.piecesDuCroquis(CROQUIS)
-- Une première robe cousue (en coton blanc) : aux décorations
local function robeCousue(graine)
	local session = Session.nouvelle(graine)
	U.commander(session)
	local tissus = {}
	for _, id in ipairs(ids) do
		tissus[id] = "coton_blanc"
	end
	assert(session:validerCroquis(CROQUIS, tissus).ok)
	session.etat.argent = 1000
	local placements, longueur = Metrage.disposition(ids)
	assert(session:acheter("coton_blanc", longueur).ok and session:commencerDecoupe().ok)
	for _, id in ipairs(ids) do
		assert(session:couper(id, placements[id]).ok, id)
	end
	for _, id in ipairs(ids) do
		assert(session:epingler(id).ok, id)
	end
	for _, id in ipairs(ids) do
		local _, l = Patron.trajetCouture(id)
		assert(session:rendreCouture(id, table.create(math.round(l / Catalogue.PAS_MESURE_COUTURE), 0), l / Catalogue.VITESSE_COUTURE_MAX).ok, id)
	end
	assert(session.etat.etape == "decorations")
	return session
end
-- Une scène factice : toucher tombe sur la robe (la première pièce, en son milieu), et l'on compte les tours de vue
local orbites = 0
local scene
scene = {
	ATTENTE_CAPTURE = 3,
	montrerDecorations = function() end,
	toucher = function()
		return { genre = "robe", indicePiece = 1, copie = scene.copie, u = 0.5, v = 0.5 }
	end,
	orbiter = function()
		orbites += 1
	end,
	photo = function() end,
	cadrerPhoto = function() end,
	finirPhoto = function() end,
}
local function contexte(session)
	local gui = UiKit.creer("ScreenGui", { Name = "Essai" })
	local fenetre = UiKit.creer("Frame", { Name = "Fenetre", Size = UDim2.fromOffset(380, 560), Parent = gui })
	local contenu = UiKit.creer("Frame", { Name = "Contenu", Size = UDim2.fromOffset(340, 442), Parent = fenetre })
	local guide = Tutoriel.installer(fenetre, UiKit)
	guide:disposer(true)
	return { UiKit = UiKit, session = session, contenu = contenu, fenetre = fenetre, scene = scene, message = function() end, refus = function() end, guide = guide }
end
-- L'élément que désigne l'anneau (un cadre de la fenêtre, recalé sur lui : plan 27)
local function entoure(ctx, element)
	local a = ctx.guide.anneau
	return a ~= nil and ctx.guide.cible == element and a:GetAttribute("Cible") == element.Name
end
local SOURIS = Enum.UserInputType.MouseButton1

---------------------------------------------------------------------------
-- Les décorations
---------------------------------------------------------------------------
local session = robeCousue(81)
scene.copie = Patron.copies(session.etat:recette().pieces[1].id)[1] -- (la copie touchée : celle de la première pièce)
local ctx = contexte(session)
local fermer = EcranDecorations(ctx)
local bandeau, contenu = ctx.fenetre.Conseil, ctx.contenu
U.verifier(bandeau.Visible and bandeau.Text == "Choisis une décoration dans la palette." and entoure(ctx, contenu.Palette) and bandeau.TextSize >= 14, "décorations : choisir dans la palette, entourée (" .. bandeau.Text .. ")")
M.avancer(0.5)
contenu.Palette.Deco_perle.Activated:Fire()
M.avancer(1.6)
U.verifier(bandeau.Text == "Touche la robe pour la poser." and not entoure(ctx, contenu.Palette), "une perle choisie : toucher la robe (" .. bandeau.Text .. ")")
local appui = { UserInputType = SOURIS, Position = Vector3.new(300, 300, 0) }
UIS.InputBegan:Fire(appui, false)
UIS.InputEnded:Fire(appui)
M.avancer(2)
U.verifier(bandeau.Text == "Glisse sur la scène pour tourner la vue.", "la perle posée : tourner la vue (" .. bandeau.Text .. ")")
M.avancer(2)
U.verifier(bandeau.Text == "Glisse sur la scène pour tourner la vue.", "la vue pas encore tournée : le conseil reste")
UIS.InputBegan:Fire(appui, false)
UIS.InputChanged:Fire({ UserInputType = Enum.UserInputType.MouseMovement, Position = Vector3.new(360, 300, 0) })
UIS.InputEnded:Fire(appui)
M.avancer(0.1)
U.verifier(orbites > 0 and bandeau.Text:find("outils", 1, true) ~= nil and entoure(ctx, contenu.Tourner15), "la vue tournée : les outils, entourés (" .. bandeau.Text .. ")")
M.avancer(6.1)
U.verifier(ctx.guide.anneau.ZIndex < 10, "(relecture du plan 28) l'anneau reste sous la mercerie et les autres calques")
U.verifier(bandeau.Text == "La robe te plaît ? Présente-la à la cliente." and entoure(ctx, contenu.Presenter), "lu : présenter, le bouton entouré (" .. bandeau.Text .. ")")
ctx.guide:arreter()
fermer()
U.verifier(session.tutorielsVus.decorations, "les décorations quittées : leurs conseils sont vus")
-- Une garniture (le ruban) : son premier point suffit
do
	local sr = robeCousue(83)
	local ctxr = contexte(sr)
	local fermerr = EcranDecorations(ctxr)
	M.avancer(0.5)
	ctxr.contenu.Palette.Deco_ruban_rose.Activated:Fire()
	M.avancer(1.6)
	UIS.InputBegan:Fire(appui, false)
	UIS.InputEnded:Fire(appui)
	M.avancer(2)
	U.verifier(ctxr.fenetre.Conseil.Text == "Glisse sur la scène pour tourner la vue.", "une garniture commencée (un point de ruban) : le conseil suivant (" .. ctxr.fenetre.Conseil.Text .. ")")
	ctxr.guide:arreter()
	fermerr()
end

---------------------------------------------------------------------------
-- La photo et la livraison
---------------------------------------------------------------------------
assert(session:decorer({}).ok and session.etat.etape == "photo")
local ctx2 = contexte(session)
local fermer2 = EcranPresentation(ctx2)
local bandeau2 = ctx2.fenetre.Conseil
U.verifier(bandeau2.Visible and bandeau2.Text:find("prends la photo", 1, true) ~= nil and entoure(ctx2, ctx2.contenu.PrendrePhoto), "photo : prendre la photo, le bouton entouré (" .. bandeau2.Text .. ")")
M.avancer(2.1)
U.verifier(bandeau2.Text:find("prends la photo", 1, true) ~= nil, "pas de photo : le conseil reste")
ctx2.contenu.PrendrePhoto.Activated:Fire()
M.avancer(0.2)
U.verifier(bandeau2.Text == "Livre la robe : touche deux fois « Livrer la robe »." and entoure(ctx2, ctx2.contenu.Livrer), "la photo prise : livrer, le bouton entouré (" .. bandeau2.Text .. ")")
ctx2.guide:arreter()
fermer2()

-- Après une robe livrée : pas de conseils ; « ? » les montre
local habituee = robeCousue(82)
habituee.etat.livraisons = 1
local ctx3 = contexte(habituee)
local fermer3 = EcranDecorations(ctx3)
U.verifier(not ctx3.fenetre.Conseil.Visible and ctx3.fenetre.Aide.Visible, "une robe déjà livrée : pas de conseils, « ? » est là")
M.avancer(0.5)
ctx3.fenetre.Aide.Activated:Fire()
U.verifier(ctx3.fenetre.Conseil.Visible and ctx3.fenetre.Conseil.Text == "Choisis une décoration dans la palette.", "« ? » montre les conseils des décorations")
ctx3.guide:arreter()
fermer3()
```

Dans `tests/scenario.luau`, remplacer :

```lua
verifier(not fenetre.Conseil.Visible and not fenetre.Aide.Visible, "(sous-projet 9) la couture quittée : son « ? » s'en va avec elle")
```

par :

```lua
verifier(fenetre.Conseil.Visible and fenetre.Conseil.Text == "Choisis une décoration dans la palette.", "(sous-projet 9) première robe, aux décorations : leurs conseils, en panneau (" .. fenetre.Conseil.Text .. ")")
```

Dans `tests/scenario.luau`, remplacer :

```lua
verifier(titre() == "7. Photo et livraison" and argent() == avantDeco
```

par :

```lua
verifier(fenetre.Conseil.Visible and fenetre.Conseil.Text:find("prends la photo", 1, true) ~= nil, "(sous-projet 9) première robe, à la photo : ses conseils (" .. fenetre.Conseil.Text .. ")")
verifier(titre() == "7. Photo et livraison" and argent() == avantDeco
```

Dans `tests/scenario.luau`, remplacer :

```lua
verifier(titre() == "La cliente refuse la robe" and texte("Avec : Croix d'argent") ~= nil, "sans la croix d'argent : robe refusée, exigence ratée affichée")
```

par :

```lua
verifier(titre() == "La cliente refuse la robe" and texte("Avec : Croix d'argent") ~= nil, "sans la croix d'argent : robe refusée, exigence ratée affichée")
verifier(not fenetre.Conseil.Visible and not fenetre.Aide.Visible, "(sous-projet 9) la photo quittée pour le refus (sans conseils) : ses conseils et « ? » s'en vont")
```

- [ ] **Step 2: Lancer les tests, vérifier l'échec**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT|attempt|membre" | head -3`
Expected: échec : une ligne qui finit par `ÉCHEC : décorations : choisir dans la palette, entourée ()`

- [ ] **Step 3: Les conseils des décorations et de la photo**

Dans `src/client/Atelier/EcranDecorations.luau`, remplacer :

```lua
	UiKit.bouton({ Name = "Presenter", Text = if ctx.session.etat.commande.libre
```

par :

```lua
	local boutonPresenter = UiKit.bouton({ Name = "Presenter", Text = if ctx.session.etat.commande.libre
```

Dans `src/client/Atelier/EcranDecorations.luau`, remplacer :

```lua
	-- Appui sur la scène (hors interface) : touche si on ne bouge pas, sinon la vue tourne
	local appui = nil
```

par :

```lua
	-- Appui sur la scène (hors interface) : touche si on ne bouge pas, sinon la vue tourne
	local appui = nil
	local vueTournee = false -- (sous-projet 9) le joueur a tourné la vue au moins une fois
```

Dans `src/client/Atelier/EcranDecorations.luau`, remplacer :

```lua
		if appui.glisse then
			scene:orbiter((input.Position.X - appui.dernierX) * DEGRES_PAR_PX)
		end
```

par :

```lua
		if appui.glisse then
			scene:orbiter((input.Position.X - appui.dernierX) * DEGRES_PAR_PX)
			vueTournee = true
		end
```

Dans `src/client/Atelier/EcranDecorations.luau`, remplacer :

```lua
	return function()
		actif = false
		desabonner()
```

par :

```lua
	-- (sous-projet 9) Les conseils de la première robe : choisir une décoration, la poser, tourner la vue, les outils,
	-- présenter
	if ctx.guide then
		local poseesDepart = #deco.liste
		ctx.guide:demarrer(session, "decorations", {
			{
				texte = "Choisis une décoration dans la palette.",
				cible = function()
					return palette
				end,
				fait = function()
					return deco.choix ~= nil
				end,
			},
			{
				texte = "Touche la robe pour la poser.",
				fait = function()
					return #deco.liste > poseesDepart or deco.garniture ~= nil
				end,
			},
			{
				texte = "Glisse sur la scène pour tourner la vue.",
				fait = function()
					return vueTournee
				end,
				duree = 10,
			},
			{
				texte = "Les outils la tournent (Q / E), l'agrandissent ou la retirent.",
				cible = function()
					return contenu:FindFirstChild("Tourner15")
				end,
				duree = 6,
			},
			{
				texte = "La robe te plaît ? Présente-la à la cliente.",
				cible = function()
					return boutonPresenter
				end,
			},
		})
	end
	return function()
		actif = false
		desabonner()
```

Dans `src/client/Atelier/EcranPresentation.luau`, remplacer :

```lua
	else
		UiKit.boutonConfirme({ Name = "Livrer", Text = "Livrer la robe",
```

par :

```lua
	else
		boutonLivrer = UiKit.boutonConfirme({ Name = "Livrer", Text = "Livrer la robe",
```

Dans `src/client/Atelier/EcranPresentation.luau`, remplacer :

```lua
	local prises, enCours = 0, nil -- enCours : numéro de la prise en cours
```

par :

```lua
	local prises, enCours = 0, nil -- enCours : numéro de la prise en cours
	local boutonPhoto, boutonLivrer -- (sous-projet 9 : désignés par les conseils)
```

Dans `src/client/Atelier/EcranPresentation.luau`, remplacer :

```lua
	UiKit.bouton({ Name = "PrendrePhoto", Text = "Prendre la photo",
```

par :

```lua
	boutonPhoto = UiKit.bouton({ Name = "PrendrePhoto", Text = "Prendre la photo",
```

Dans `src/client/Atelier/EcranPresentation.luau`, remplacer :

```lua
	rafraichir()
	return function()
		connexion:Disconnect()
	end
end
```

par :

```lua
	rafraichir()
	-- (sous-projet 9) Les conseils de la première robe (une commande, pas une robe libre) : la photo, puis livrer
	if ctx.guide and not libre then
		ctx.guide:demarrer(session, "photo", {
			{
				texte = "Choisis un décor et une lumière, puis prends la photo.",
				cible = function()
					return boutonPhoto
				end,
				fait = function()
					return prises > 0
				end,
			},
			{
				texte = "Livre la robe : touche deux fois « Livrer la robe ».",
				cible = function()
					return boutonLivrer
				end,
			},
		})
	end
	return function()
		connexion:Disconnect()
	end
end
```

- [ ] **Step 4: Lancer les tests**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT"`
Expected:
```
Unitaires : 269865 vérifications
TOUT EST VERT : 1041 vérifications
```

- [ ] **Step 5: Commit**

```bash
git add src/client/Atelier/EcranDecorations.luau src/client/Atelier/EcranPresentation.luau tests/unitaires/84_premiers_pas_robe.luau tests/scenario.luau
git commit -m "Premiers pas : les conseils des décorations et de la photo ; chaque poste a les siens

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

Construire le lieu du dépôt dans un dossier temporaire (`C:/dev/jeux/roblox-maker/rojo.exe build -o <dossier temporaire>/Plan29Depot.rbxl`) et l'ouvrir dans Studio (ne toucher à aucune autre fenêtre de Studio). En édition (`execute_luau`, Edit) : dans un `ScreenGui` d'essai de `StarterGui`, une fenêtre de 380 px en panneau avec `Tutoriel.installer`, et l'écran des décorations d'une session simulée à la première robe (scène factice) ; le regarder (`screen_capture`), puis supprimer le `ScreenGui`. Enfin en Play : attendre 4 s, relever la console.

Expected : le bandeau « Choisis une décoration dans la palette. » sur la barre de titre du panneau, l'anneau autour de la palette ; aucune alerte de notre code (« Lieu non publié » et les messages internes de Roblox mis à part). Arrêter Play et fermer cette fenêtre de Studio (sans enregistrer).

- [ ] **Step 2: Mettre à jour le README**

Dans `README.md`, remplacer :

```markdown
## État actuel (sous-projet 9 en cours, plans 27 et 28 : les premiers pas, de l'accueil à l'épinglage)
```

par :

```markdown
## État actuel (sous-projet 9, plans 27 à 29 : les premiers pas, à chaque poste)
```

Dans `README.md`, remplacer :

```markdown
quand le geste est fait. Ensuite, le bouton « ? » de la barre de titre les rappelle. Pour l'instant : l'accueil (la
clochette), les mesures (tourner une molette, ajuster les trois bandes, valider), le carnet (un modèle, un tissu, la
fiche de la cliente, tracer le patron), l'achat (le métrage proposé), la découpe (la place proposée, le droit-fil,
couper), l'épinglage et la couture (ses propres conseils).
```

par :

```markdown
quand le geste est fait (jamais avant 2 s : le temps de le lire). Ensuite, le bouton « ? » de la barre de titre les
rappelle. L'accueil (la clochette), les mesures (tourner une molette, ajuster les trois bandes, valider), le carnet (un
modèle, un tissu, la fiche de la cliente, tracer le patron), l'achat (le métrage proposé), la découpe (la place
proposée, le droit-fil, couper), l'épinglage, la couture (ses propres conseils), les décorations (choisir, poser,
tourner la vue, les outils, présenter) et la photo (prendre la photo, livrer).
```

- [ ] **Step 3: Tests, lieu régénéré, commit**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT"`
Expected:
```
Unitaires : 269865 vérifications
TOUT EST VERT : 1041 vérifications
```

```bash
C:/dev/jeux/roblox-maker/rojo.exe build -o AtelierCouture.rbxl
git add README.md AtelierCouture.rbxl
git commit -m "Plan 29 terminé : les premiers pas, à chaque poste

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```
