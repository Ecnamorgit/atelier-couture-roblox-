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
		return { genre = "robe", indicePiece = 1, copie = scene.copie, u = scene.u or 0.5, v = scene.v or 0.5 }
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
-- (relecture) Une garniture (le ruban) : un point ne suffit pas (la robe ne garderait rien) ; l'anneau désigne « Finir
-- la garniture » ; deux points assez écartés, et le conseil passe
do
	local sr = robeCousue(83)
	local ctxr = contexte(sr)
	local fermerr = EcranDecorations(ctxr)
	M.avancer(0.5)
	ctxr.contenu.Palette.Deco_ruban_rose.Activated:Fire()
	M.avancer(1.6)
	scene.u, scene.v = 0.2, 0.5
	UIS.InputBegan:Fire(appui, false)
	UIS.InputEnded:Fire(appui)
	M.avancer(2.1)
	U.verifier(ctxr.fenetre.Conseil.Text == "Touche la robe pour la poser." and ctxr.guide.cible == ctxr.contenu.FinirGarniture, "un seul point de ruban : le conseil reste, « Finir la garniture » entouré (" .. ctxr.fenetre.Conseil.Text .. ")")
	scene.u = 0.8
	UIS.InputBegan:Fire(appui, false)
	UIS.InputEnded:Fire(appui)
	M.avancer(0.1)
	U.verifier(ctxr.fenetre.Conseil.Text == "Glisse sur la scène pour tourner la vue.", "deux points de ruban : la robe le gardera, le conseil suivant (" .. ctxr.fenetre.Conseil.Text .. ")")
	scene.u, scene.v = nil, nil
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
U.verifier(ctx2.contenu.Apercu.Visible and bandeau2.Text:find("prends la photo", 1, true) ~= nil, "(relecture) la photo prise, l'aperçu cache « Livrer » : le conseil attend (" .. bandeau2.Text .. ")")
ctx2.contenu.Apercu.FermerApercu.Activated:Fire()
M.avancer(0.1)
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

-- (relecture) Une robe libre, sans clavier, qui ne tourne jamais la vue : « ? » montre les conseils ; les outils sans
-- touches ; au bout de 10 s, le conseil de la vue passe ; « Présente-la », sans cliente
do
	local sl = robeCousue(85)
	sl.etat.livraisons = 1
	sl.etat.commande.libre = true
	UIS.KeyboardEnabled = false
	local cl = contexte(sl)
	local fl = EcranDecorations(cl)
	local b = cl.fenetre.Conseil
	M.avancer(0.5)
	cl.fenetre.Aide.Activated:Fire()
	cl.contenu.Palette.Deco_perle.Activated:Fire()
	M.avancer(2.1)
	UIS.InputBegan:Fire(appui, false)
	UIS.InputEnded:Fire(appui)
	M.avancer(2.1)
	U.verifier(b.Text == "Glisse sur la scène pour tourner la vue.", "robe libre : la perle posée, tourner la vue (" .. b.Text .. ")")
	M.avancer(8)
	U.verifier(b.Text == "Glisse sur la scène pour tourner la vue.", "8 s sans tourner la vue : le conseil reste")
	M.avancer(2.1)
	U.verifier(b.Text:find("outils", 1, true) ~= nil and b.Text:find("Q / E", 1, true) == nil, "10 s sans tourner la vue : les outils, sans les touches Q / E au doigt (" .. b.Text .. ")")
	M.avancer(6.1)
	U.verifier(b.Text == "La robe te plaît ? Présente-la.", "une robe libre : présenter, sans cliente (" .. b.Text .. ")")
	UIS.KeyboardEnabled = true
	cl.guide:arreter()
	fl()
end
