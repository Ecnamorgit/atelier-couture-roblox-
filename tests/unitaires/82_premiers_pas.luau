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
-- L'élément entouré par l'anneau (un cadre de la fenêtre, recalé sur lui)
local function entoure(ctx, element)
	local a = ctx.fenetre:FindFirstChild("Anneau")
	return a ~= nil and ctx.guide.cible == element and a:GetAttribute("Cible") == element.Name
end

---------------------------------------------------------------------------
-- L'accueil : la clochette (E seulement avec un clavier)
---------------------------------------------------------------------------
local UIS = M.services.UserInputService
UIS.KeyboardEnabled = false
local auDoigt = Session.nouvelle(60)
local ctx0 = contexte(auDoigt)
local fermer0 = EcranAccueil(ctx0)
U.verifier(ctx0.fenetre.Conseil.Text:find("clochette", 1, true) ~= nil and ctx0.fenetre.Conseil.Text:find("appuie sur E", 1, true) == nil, "sans clavier (téléphone) : pas de touche E dans le conseil (" .. ctx0.fenetre.Conseil.Text .. ")")
ctx0.guide:arreter()
fermer0()
UIS.KeyboardEnabled = true
local session = Session.nouvelle(61)
local ctx = contexte(session)
local fermer = EcranAccueil(ctx)
local bandeau = ctx.fenetre.Conseil
U.verifier(bandeau.Text:find("appuie sur E", 1, true) ~= nil, "avec un clavier : la touche E (" .. bandeau.Text .. ")")
U.verifier(bandeau.Visible and bandeau.Text:find("clochette", 1, true) ~= nil and entoure(ctx, ctx.contenu.Clochette), "accueil, première robe : sonner la clochette, entourée (" .. bandeau.Text .. ")")
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
U.verifier(bandeau.Visible and bandeau.Text:find("molette", 1, true) ~= nil and entoure(ctx2, contenu.Molette_poitrine), "mesures : tourner une molette, entourée (" .. bandeau.Text .. ")")
M.avancer(0.5)
U.verifier(bandeau.Text:find("molette", 1, true) ~= nil, "rien tourné : le conseil reste")
contenu.Plus_poitrine.Activated:Fire()
M.avancer(1.6) -- (un conseil reste au moins 2 s, le temps de le lire)
U.verifier(bandeau.Text:find("silhouette", 1, true) ~= nil and entoure(ctx2, contenu.Mannequin), "une molette tournée : ajuster les bandes, le mannequin entouré (" .. bandeau.Text .. ")")
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
U.verifier(bandeau.Text == "Quand le mannequin épouse la silhouette, valide les mesures." and entoure(ctx2, contenu.ValiderMesures), "les trois justes : valider, le bouton entouré (" .. bandeau.Text .. ")")
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
