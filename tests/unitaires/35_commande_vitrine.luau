local Commande = U.module("Commande")
local Sauvegarde = U.module("Sauvegarde")
local Patron = U.module("Patron")
local Recette = U.module("Recette")

-- La vitrine de chaque joueur, telle que le serveur la montre (false : vide)
local exposees = {}
local function vitrine(joueur, recette)
	exposees[joueur] = recette or false
end
local function appeler(serveur, joueur, action, ...)
	M.avancer(0.25)
	return serveur:traiter(joueur, action, ...)
end

---------------------------------------------------------------------------
-- Sans sauvegarde : vitrine vide à l'arrivée, puis la robe livrée ; un refus ne change rien
---------------------------------------------------------------------------
local serveur = Commande.nouvelle({ vitrine = vitrine })
local joueur = M.nouveauJoueur("Exposante")
serveur:arrivee(joueur)
U.verifier(exposees[joueur] == false, "arrivée : vitrine vide")
local CROQUIS = { corsage = "corsage_droit", manches = "manches_sans", col = "col_sans", jupe = "jupe_droite" }
local ORDRE = { "corsage_droit_devant", "corsage_droit_dos", "jupe_droite_devant", "jupe_droite_dos" }
local PLACES = {
	corsage_droit_devant = { x = 2.4, y = 2.1, angle = 0 },
	corsage_droit_dos = { x = 7.2, y = 2.1, angle = 0 },
	jupe_droite_devant = { x = 2.5, y = 7.2, angle = 0 },
	jupe_droite_dos = { x = 7.5, y = 7.2, angle = 0 },
}
local tissus = {}
for _, id in ipairs(ORDRE) do
	tissus[id] = "coton_blanc"
end
serveur:atelier(joueur).etat.argent = 1000
appeler(serveur, joueur, "nouvelleCommande")
appeler(serveur, joueur, "mesurer", U.module("Clientes").get(serveur:atelier(joueur).etat.commande.cliente).mesures)
appeler(serveur, joueur, "validerCroquis", CROQUIS, tissus)
appeler(serveur, joueur, "acheter", "coton_blanc", 12)
appeler(serveur, joueur, "commencerDecoupe")
for _, id in ipairs(ORDRE) do
	appeler(serveur, joueur, "couper", id, PLACES[id])
end
for _, id in ipairs(ORDRE) do
	appeler(serveur, joueur, "epingler", id)
end
for _, id in ipairs(ORDRE) do
	local _, l = Patron.trajetCouture(id)
	appeler(serveur, joueur, "rendreCouture", id, table.create(math.round(l / 0.1), 0.02), l)
end
appeler(serveur, joueur, "decorer", {})
local etat = serveur:atelier(joueur).etat
etat.commande.exigences = { { type = "accessoire", id = "croix_argent" } }
local r = appeler(serveur, joueur, "livrer")
U.verifier(r.ok and not r.reussie and exposees[joueur] == false, "robe refusée : la vitrine ne change pas")
appeler(serveur, joueur, "retoucher")
appeler(serveur, joueur, "decorer", {})
etat.commande.exigences = { { type = "qualite", valeur = 0.1 } }
r = appeler(serveur, joueur, "livrer")
U.verifier(r.ok and r.reussie and exposees[joueur] and Recette.encoder(exposees[joueur]) == Recette.encoder(etat.robes[1]), "robe livrée : elle part en vitrine")

---------------------------------------------------------------------------
-- Avec sauvegarde : à l'arrivée, la dernière robe sauvegardée est en vitrine
---------------------------------------------------------------------------
local magasin = M.nouveauMagasin()
magasin.donnees.joueur_42 = { version = Sauvegarde.VERSION, argent = 300, stock = {}, debloques = {}, recettes = { etat.robes[1] } }
local avecSauvegarde = Commande.nouvelle({
	vitrine = vitrine,
	sauvegarde = Sauvegarde.nouvelle({ magasin = magasin, ancien = M.nouveauMagasin(), jobId = "V" }),
})
local revenue = M.nouveauJoueur("Revenue")
avecSauvegarde:arrivee(revenue)
U.verifier(exposees[revenue] and Recette.encoder(exposees[revenue]) == Recette.encoder(etat.robes[1]), "retour : la dernière robe sauvegardée est en vitrine")

---------------------------------------------------------------------------
-- Une vitrine en panne ne casse pas l'action
---------------------------------------------------------------------------
local fragile = Commande.nouvelle({
	vitrine = function()
		error("vitrine en panne")
	end,
})
local j2 = M.nouveauJoueur("Fragile")
M.avertissements = {}
fragile:arrivee(j2)
U.verifier(appeler(fragile, j2, "etat").ok and #M.avertissements == 1, "vitrine en panne : un avertissement, l'atelier fonctionne")
