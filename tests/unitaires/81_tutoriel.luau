-- Sous-projet 9 : les conseils pas à pas d'un poste. Un bandeau sur la barre de titre, un anneau qui pulse autour de
-- l'élément à toucher ; chaque conseil s'efface quand le geste est fait, ou au bout de sa durée s'il ne demande que de
-- lire ; « ? » les reprend au premier ; les conseils vus ne reviennent pas d'eux-mêmes.
local Tutoriel = U.module("Tutoriel")
local UiKit = U.module("UiKit")

local fenetre = UiKit.creer("Frame", { Name = "Fenetre", Size = UDim2.fromOffset(900, 560) })
local guide = Tutoriel.installer(fenetre, UiKit)
local bandeau, aide = fenetre.Conseil, fenetre.Aide
-- (relecture) L'anneau est un cadre de la fenêtre, recalé sur l'élément désigné à chaque image
local function entoure(element)
	local a = fenetre:FindFirstChild("Anneau")
	return a ~= nil and a.Visible and guide.cible == element and a:GetAttribute("Cible") == element.Name
end
local function sansAnneau()
	local a = fenetre:FindFirstChild("Anneau")
	return a == nil or (not a.Visible and guide.cible == nil)
end
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
U.verifier(bandeau.Visible and bandeau.Text == "Touche la cible." and aide.Visible and entoure(cible), "première robe : le premier conseil, l'élément entouré, « ? »")
M.avancer(0.3)
local avant = fenetre.Anneau.Contour.Transparency
M.avancer(0.4)
U.verifier(fenetre.Anneau.Contour.Transparency ~= avant, "l'anneau pulse")
U.verifier(bandeau.Text == "Touche la cible.", "le geste n'est pas fait : le conseil reste")
geste = true
M.avancer(0.05)
U.verifier(bandeau.Text == "Touche la cible.", "le geste fait, mais le conseil n'est là que depuis 0,75 s : il reste le temps de le lire")
M.avancer(1.3)
U.verifier(bandeau.Text == "Lis ceci." and sansAnneau(), "le geste fait, le conseil lu : le suivant, l'anneau retiré")
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
U.verifier(bandeau.Visible and bandeau.Text == "Touche la cible." and entoure(cible), "« ? » : le premier conseil de nouveau")
-- L'écran refait l'élément désigné : l'anneau le suit
local refaite = UiKit.bouton({ Name = "Cible", Text = "Cible", Size = UDim2.fromOffset(100, 40), Parent = fenetre })
cible:Destroy()
cible = refaite
M.avancer(0.05) -- (le geste n'est pas fait : le conseil reste)
U.verifier(entoure(refaite), "l'élément refait : l'anneau l'entoure de nouveau")

-- Le poste se ferme avant la fin : ses conseils sont vus, le bandeau et « ? » disparaissent
local autre = { etat = { livraisons = 0, ventes = 0 } }
guide:demarrer(autre, "essai", ETAPES)
U.verifier(bandeau.Visible and bandeau.Text == "Touche la cible.", "un autre joueur, à sa première robe : les conseils")
guide:arreter()
U.verifier(not bandeau.Visible and not aide.Visible and autre.tutorielsVus.essai and sansAnneau(), "poste fermé : conseils vus, bandeau, « ? » et anneau retirés")
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

-- (relecture) L'anneau ne dépend pas de ce que l'écran fait de l'élément : dans une liste qui défile, il entoure la
-- partie visible de l'élément (et disparaît s'il n'en reste rien) ; une liste entière se désigne aussi ; un élément caché
-- n'est pas entouré ; une liste vidée garde son anneau
local essai = { etat = { livraisons = 0, ventes = 0 } }
local liste = UiKit.creer("ScrollingFrame", { Name = "Liste", Position = UDim2.fromOffset(100, 200), Size = UDim2.fromOffset(200, 100), Parent = fenetre })
local entree = UiKit.bouton({ Name = "Entree", Text = "Entrée", Size = UDim2.fromOffset(120, 40), Parent = liste })
local designe = entree
guide:demarrer(essai, "liste", { { texte = "Touche l'entrée.", cible = function() return designe end } })
local anneau = fenetre.Anneau
local function rect()
	return anneau.Position.X.Offset, anneau.Position.Y.Offset, anneau.Size.X.Offset, anneau.Size.Y.Offset
end
local m = Tutoriel.MARGE
local x, y, l, h = rect()
U.verifier(entoure(entree) and x == 100 - m and y == 200 - m and l == 120 + 2 * m and h == 40 + 2 * m, ("en haut d'une liste : l'anneau autour de l'entrée, sur la fenêtre (%d, %d, %d, %d)"):format(x, y, l, h))
entree.Position = UDim2.fromOffset(0, 80)
M.avancer(0.05)
x, y, l, h = rect()
U.verifier(entoure(entree) and y == 280 - m and h == 20 + 2 * m, ("l'entrée à moitié sortie de la liste : l'anneau autour de sa partie visible (%d, %d)"):format(y, h))
entree.Position = UDim2.fromOffset(0, 150)
M.avancer(0.05)
U.verifier(not anneau.Visible, "l'entrée hors de la vue : pas d'anneau")
designe = liste
M.avancer(0.05)
x, y, l, h = rect()
U.verifier(entoure(liste) and x == 100 - m and y == 200 - m and l == 200 + 2 * m and h == 100 + 2 * m, "une liste entière désignée : l'anneau autour d'elle")
liste:ClearAllChildren()
M.avancer(0.05)
U.verifier(entoure(liste), "la liste vidée par l'écran : l'anneau reste")
liste.Visible = false
M.avancer(0.05)
U.verifier(not anneau.Visible, "la liste cachée : pas d'anneau")
guide:arreter()
U.verifier(sansAnneau(), "le poste fermé : plus d'anneau")
