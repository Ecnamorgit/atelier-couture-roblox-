local EtatAtelier = U.module("EtatAtelier")
local Patron = U.module("Patron")
local Recette = U.module("Recette")

local CROQUIS = { corsage = "corsage_droit", manches = "manches_sans", col = "col_sans", jupe = "jupe_droite" }
local PLACES = {
	corsage_droit_devant = { x = 2.4, y = 2.1, angle = 0 },
	corsage_droit_dos = { x = 7.2, y = 2.1, angle = 0 },
	jupe_droite_devant = { x = 2.5, y = 7.2, angle = 0 },
	jupe_droite_dos = { x = 7.5, y = 7.2, angle = 0 },
}
local ORDRE = { "corsage_droit_devant", "corsage_droit_dos", "jupe_droite_devant", "jupe_droite_dos" }
-- Copie « réseau » d'un état exporté, rechargée dans un état neuf
local function recopie(etat)
	return EtatAtelier.nouveau():charger(M.transmettre(etat:exporter()))
end

---------------------------------------------------------------------------
-- Pendant la découpe : rouleaux, pièces coupées, stock
---------------------------------------------------------------------------
local etat = EtatAtelier.nouveau(1000)
etat:nouvelleCommande(Random.new(3))
local tissus = {}
for id in pairs(PLACES) do
	tissus[id] = "coton_blanc"
end
etat:validerCroquis(CROQUIS, tissus)
etat:acheter("coton_blanc", 12)
etat:commencerDecoupe()
etat:couper(ORDRE[1], PLACES[ORDRE[1]])
etat:couper(ORDRE[2], PLACES[ORDRE[2]])

local ok, erreur = pcall(M.transmettre, etat:exporter())
U.verifier(ok, "l'état exporté passe par le réseau (" .. tostring(erreur) .. ")")
local copie = recopie(etat)
U.verifier(getmetatable(copie) == EtatAtelier, "la copie est un état de l'atelier (ses méthodes marchent)")
U.verifier(copie.argent == etat.argent and copie.stock.coton_blanc == 12 and copie.etape == "decoupe", "argent, stock et étape")
U.verifier(copie.commande.taille == etat.commande.taille and #copie.commande.exigences == #etat.commande.exigences, "commande")
U.verifier(#copie:piecesAPoser() == 2 and copie.coupees[ORDRE[1]].x == PLACES[ORDRE[1]].x, "pièces déjà coupées")
local rouleau = copie.coupons.coton_blanc
U.verifier(rouleau ~= nil and rouleau.longueur == etat.coupons.coton_blanc.longueur and rouleau.poses[ORDRE[2]] ~= nil, "rouleau : longueur et pièces posées")
local posee, pourquoi = rouleau:verifier(ORDRE[3], { x = 2.5, y = 6.0, angle = 0 }) -- recouvre le corsage devant
U.verifier(not posee and pourquoi == "La pièce chevauche une autre pièce.", "le rouleau rechargé connaît la place occupée")
U.verifier(rouleau:longueurUtilisee() == etat.coupons.coton_blanc:longueurUtilisee(), "longueur entamée identique")
-- La copie continue la commande exactement comme l'original
local r1, r2 = etat:couper(ORDRE[3], PLACES[ORDRE[3]]), copie:couper(ORDRE[3], PLACES[ORDRE[3]])
U.verifier(r1.ok and r2.ok and r1.reste == r2.reste, "la découpe continue à l'identique")

-- L'export ne partage rien avec l'état
local export = etat:exporter()
export.stock.coton_blanc = 0
export.commande.exigences = {}
export.coupons.coton_blanc.poses = {}
U.verifier(etat.stock.coton_blanc == 12 and #etat.commande.exigences > 0 and etat.coupons.coton_blanc.poses[ORDRE[1]] ~= nil, "modifier l'export ne touche pas l'état")

---------------------------------------------------------------------------
-- Robe finie, décorée, puis livrée : recette et robes gardées
---------------------------------------------------------------------------
etat:couper(ORDRE[4], PLACES[ORDRE[4]])
for _, id in ipairs(ORDRE) do
	etat:epingler(id)
end
for _, id in ipairs(ORDRE) do
	local _, longueur = Patron.trajetCouture(id)
	etat:rendreCouture(id, table.create(math.round(longueur / 0.1), 0.02), longueur)
end
etat:decorer({ { id = "noeud_satin", piece = 1, copie = "unique", u = 0.4, v = 0.3, echelle = 1, angle = 15 } })
U.verifier(etat.etape == "photo", "robe décorée (mise en place du test)")
local photo = recopie(etat)
U.verifier(Recette.encoder(photo:recette()) == Recette.encoder(etat:recette()), "même recette : pièces, coutures, décorations")
etat.commande.exigences = { { type = "qualite", valeur = 0.1 } }
U.verifier(etat:livrer().reussie, "robe livrée (mise en place du test)")
local apres = recopie(etat)
U.verifier(apres.etape == "accueil" and apres.commande == nil and apres.croquis == nil, "commande terminée")
U.verifier(#apres.robes == 1 and Recette.encoder(apres.robes[1]) == Recette.encoder(etat.robes[1]), "robe livrée gardée")

---------------------------------------------------------------------------
-- Rechargement sur place : les écrans gardent l'objet ; ce qui n'a pas changé garde sa table
---------------------------------------------------------------------------
local client = EtatAtelier.nouveau()
local serveur = EtatAtelier.nouveau(500)
serveur:nouvelleCommande(Random.new(8))
client:charger(serveur:exporter())
local objet, commande = client, client.commande
serveur:validerCroquis(CROQUIS, tissus)
serveur:acheter("coton_blanc", 10)
U.verifier(client:charger(serveur:exporter()) == objet, "charger renvoie le même objet")
U.verifier(client.commande == commande, "même commande : même table (la scène garde sa cliente)")
U.verifier(client.etape == "achat" and client.argent == serveur.argent and client.stock.coton_blanc == 10, "le reste est à jour")
serveur.etape = "refus"
serveur:abandonner()
serveur:nouvelleCommande(Random.new(9))
client:charger(serveur:exporter())
U.verifier(client.commande ~= commande and client.commande.taille == serveur.commande.taille, "nouvelle commande : nouvelle table")
client.commande.taille = "XXL"
U.verifier(serveur.commande.taille ~= "XXL", "l'état chargé ne partage rien avec la source")
