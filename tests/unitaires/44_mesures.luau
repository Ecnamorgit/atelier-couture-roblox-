local EtatAtelier = U.module("EtatAtelier")
local Clientes = U.module("Clientes")
local Notation = U.module("Notation")
local Patron = U.module("Patron")
local Progression = U.module("Progression")

local CROQUIS = { corsage = "corsage_droit", manches = "manches_sans", col = "col_sans", jupe = "jupe_droite" }
local ORDRE = { "corsage_droit_devant", "corsage_droit_dos", "jupe_droite_devant", "jupe_droite_dos" }
local PLACES = {
	corsage_droit_devant = { x = 2.4, y = 2.1, angle = 0 },
	corsage_droit_dos = { x = 7.2, y = 2.1, angle = 0 },
	jupe_droite_devant = { x = 2.5, y = 7.2, angle = 0 },
	jupe_droite_dos = { x = 7.5, y = 7.2, angle = 0 },
}
-- Une robe menée jusqu'à la photo (coton blanc, coutures parfaites) ; la cliente ne demande qu'une qualité
local function jusquALaPhoto(e)
	local tissus = {}
	for _, id in ipairs(ORDRE) do
		tissus[id] = "coton_blanc"
	end
	e.argent = 1000
	assert(e:validerCroquis(CROQUIS, tissus).ok and e:acheter("coton_blanc", 12).ok and e:commencerDecoupe().ok)
	for _, id in ipairs(ORDRE) do
		assert(e:couper(id, PLACES[id]).ok)
	end
	for _, id in ipairs(ORDRE) do
		assert(e:epingler(id).ok)
	end
	for _, id in ipairs(ORDRE) do
		local _, l = Patron.trajetCouture(id)
		assert(e:rendreCouture(id, table.create(math.round(l / 0.1), 0.02), l).ok)
	end
	assert(e:decorer({}).ok)
	e.commande.exigences = { { type = "qualite", valeur = 0.1 } }
end

---------------------------------------------------------------------------
-- Première commande : Colette, à mesurer avant le carnet
---------------------------------------------------------------------------
local e = EtatAtelier.nouveau()
local colette = Clientes.get("colette")
local r = e:nouvelleCommande(Random.new(3))
U.verifier(r.ok and r.cliente == "colette" and r.premiereVisite == true and e.etape == "mesures", "première commande : Colette, à mesurer")
U.verifier(e.commande.cliente == "colette" and e.commande.taille == colette.taille and e.commande.mesures == nil, "sa commande attend ses mesures")
U.verifier(e.clientes.colette.vues == 1 and e.clientes.colette.derniere == 1 and e.visites == 1, "sa visite est notée")
local styleDemande
for _, x in ipairs(e.commande.exigences) do
	if x.type == "min" then
		styleDemande = x.style
	end
end
U.verifier(table.find(colette.styles, styleDemande) ~= nil, "elle demande un de ses styles (" .. tostring(styleDemande) .. ")")
U.verifier(not e:validerCroquis(CROQUIS, {}).ok, "pas de croquis avant les mesures")
U.verifier(not e:reprendreMesures().ok, "première visite : aucune mesure à reprendre")
U.verifier(not e:recommencer().ok and e.etape == "mesures", "rien à recommencer avant les mesures")

-- Mesures farfelues : refusées
local FARFELUES = {
	"tout",
	{},
	{ poitrine = 0 / 0, taille = 7.1, hanches = 9.5 },
	{ poitrine = 8.9, taille = 7.1 },
	{ poitrine = 8.9 + 1.6, taille = 7.1, hanches = 9.5 }, -- trop loin de la silhouette
	{ poitrine = 8.9, taille = "7", hanches = 9.5 },
}
for k, m in ipairs(FARFELUES) do
	r = e:mesurer(m)
	U.verifier(not r.ok and e.etape == "mesures" and e.commande.mesures == nil, "mesures farfelues refusées (" .. k .. ")")
end

-- Mesure fausse de 0,5 dm à la poitrine : ajustement 80 %
r = e:mesurer({ poitrine = 8.9 + 0.5, taille = 7.1, hanches = 9.5 })
U.verifier(r.ok and e.etape == "carnet" and U.proche(r.ajustement, 0.8) and U.proche(e.commande.mesures.poitrine, 9.4), "mesure fausse de 0,5 dm : ajustement 80 %, le patron suit la mesure prise")
U.verifier(U.proche(e.clientes.colette.mesures.poitrine, 9.4) and U.proche(e.clientes.colette.ajustement, 0.8), "ses mesures et l'ajustement sont gardés pour la prochaine fois")
U.verifier(Notation.ajustement(colette.mesures, colette.mesures) == 1 and Notation.ajustement(colette.mesures, { poitrine = 9.1, taille = 6.9, hanches = 9.5 }) == 1, "ajustement : juste à 0,2 dm près")
U.verifier(Notation.ajustement(colette.mesures, { poitrine = 7.4, taille = 5.6, hanches = 8 }) == 0.5, "ajustement : jamais sous 50 %")

---------------------------------------------------------------------------
-- Livraison : la qualité tient compte de l'ajustement ; amitié et prestige
---------------------------------------------------------------------------
jusquALaPhoto(e)
local bilan = e:bilan()
U.verifier(U.proche(bilan.ajustement, 0.8) and bilan.qualite < 0.81, "bilan : ajustement 80 %, la qualité en tient compte (" .. bilan.qualite .. ")")
r = e:livrer()
U.verifier(r.ok and r.reussie and U.proche(r.bilan.ajustement, 0.8), "robe livrée")
U.verifier(r.amitie.cliente == "colette" and r.amitie.gain == Progression.gainAmitie(true, r.bilan.qualite) and e.clientes.colette.amitie == r.amitie.gain, "amitié de Colette : +" .. r.amitie.gain)
U.verifier(r.prestige.gain == Progression.prestigeLivraison(r.paie) and e.prestige == r.prestige.gain and r.prestige.niveau == Progression.niveauPrestige(e.prestige), "prestige : un dixième de la paie")
U.verifier(e.livraisons == 1 and e.etape == "accueil", "une robe livrée")

---------------------------------------------------------------------------
-- Les suivantes : Margot, Salomé ; puis Colette revient, et ses mesures se reprennent d'un clic
---------------------------------------------------------------------------
r = e:nouvelleCommande(Random.new(4))
U.verifier(r.cliente == "margot" and r.premiereVisite and e.commande.taille == "S", "deuxième commande : Margot (taille S)")
e:mesurer(Clientes.get("margot").mesures)
U.verifier(e.etape == "carnet" and e.commande.ajustement == 1, "mesures exactes : ajustement 100 %")
e:recommencer()
e.etape = "refus"
r = e:abandonner()
U.verifier(r.ok and r.amitie.cliente == "margot" and r.amitie.gain == 0 and e.clientes.margot.amitie == 0, "abandon : l'amitié ne descend pas sous 0")
r = e:nouvelleCommande(Random.new(5))
U.verifier(r.cliente == "salome", "troisième : Salomé")
e:mesurer(Clientes.get("salome").mesures)
e.etape = "refus"
e:abandonner()
r = e:nouvelleCommande(Random.new(6))
U.verifier(r.cliente == "colette" and not r.premiereVisite and e.etape == "mesures", "Colette revient")
r = e:reprendreMesures()
U.verifier(r.ok and e.etape == "carnet" and U.proche(e.commande.mesures.poitrine, 9.4) and U.proche(e.commande.ajustement, 0.8), "« Reprendre ses mesures » : celles de sa première visite")
e.clientes.colette.amitie = 10
e.etape = "refus"
r = e:abandonner()
U.verifier(e.clientes.colette.amitie == 9 and r.amitie.gain == -1 and r.amitie.niveau == 2, "abandon : −1 d'amitié")
