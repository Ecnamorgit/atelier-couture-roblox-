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
	local a = ctx.guide.anneau
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
