local EtatAtelier = U.module("EtatAtelier")
local Session = U.module("Session")
local Patron = U.module("Patron")
local Catalogue = U.module("Catalogue")
local Recette = U.module("Recette")
local Notation = U.module("Notation")

local CROQUIS = { corsage = "corsage_droit", manches = "manches_sans", col = "col_sans", jupe = "jupe_droite" }
local PIECES = { "corsage_droit_devant", "corsage_droit_dos", "jupe_droite_devant", "jupe_droite_dos" }
-- Disposition sans chevauchement des 4 pièces sur un rouleau de 14 dm
local DISPOSITION = {
	corsage_droit_devant = { x = 2.4, y = 2.1, angle = 0 },
	corsage_droit_dos = { x = 7.2, y = 2.1, angle = 0 },
	jupe_droite_devant = { x = 2.5, y = 7.2, angle = 0 },
	jupe_droite_dos = { x = 7.5, y = 7.2, angle = 0 },
}

-- Commande en cours, robe entièrement coupée dans du coton blanc
local function jusquAEpinglage()
	local e = EtatAtelier.nouveau()
	e:nouvelleCommande(Random.new(3))
	local tissus = {}
	for _, id in ipairs(PIECES) do
		tissus[id] = "coton_blanc"
	end
	e:validerCroquis(CROQUIS, tissus)
	e:acheter("coton_blanc", 12)
	e:commencerDecoupe()
	for _, id in ipairs(PIECES) do
		e:couper(id, DISPOSITION[id])
	end
	return e
end

-- Relevé plausible d'une pièce : une mesure tous les 0,1 dm (± delta), durée à la vitesse maximale
local function releve(id, ecart, delta)
	local _, longueur = Patron.trajetCouture(id)
	local n = math.round(longueur / Catalogue.PAS_MESURE_COUTURE) + (delta or 0)
	return table.create(n, ecart or 0), longueur / Catalogue.VITESSE_COUTURE_MAX
end

---------------------------------------------------------------------------
-- Épinglage
---------------------------------------------------------------------------
local e = jusquAEpinglage()
U.verifier(e.etape == "epinglage" and #e:piecesAEpingler() == 4, "après la découpe : 4 pièces à épingler")
U.verifier(e:recette() ~= nil and e:recette().pieces[1].couture == 0, "recette disponible dès la découpe finie, couture à 0")
U.verifier(not e:rendreCouture(PIECES[1], releve(PIECES[1])).ok, "pas de couture avant l'épinglage")
U.verifier(not e:epingler("manche_ballon").ok, "pièce hors du croquis refusée")
U.verifier(not e:epingler(nil).ok and not e:epingler(42).ok, "identifiant invalide refusé")
local r = e:epingler("corsage_droit_devant")
U.verifier(r.ok and r.reste == 3 and e.epinglees.corsage_droit_devant == true, "pièce épinglée")
U.verifier(not e:epingler("corsage_droit_devant").ok, "une pièce ne s'épingle qu'une fois")
U.verifier(e:piecesAEpingler()[1] == "corsage_droit_dos", "pièces à épingler dans l'ordre du croquis")
for i = 2, 4 do
	e:epingler(PIECES[i])
end
U.verifier(e.etape == "couture" and #e:piecesACoudre() == 4, "toutes les pièces épinglées : direction la couture")
U.verifier(not e:epingler(PIECES[1]).ok, "plus d'épinglage pendant la couture")

---------------------------------------------------------------------------
-- Couture : contrôles de vraisemblance (spec §6)
---------------------------------------------------------------------------
local id = PIECES[1]
local ecarts, duree = releve(id)
U.verifier(not e:rendreCouture("manche_ballon", ecarts, duree).ok, "pièce hors du croquis refusée")
U.verifier(not e:rendreCouture(id, "x", duree).ok and not e:rendreCouture(id, nil, duree).ok, "relevé qui n'est pas une liste refusé")
U.verifier(not e:rendreCouture(id, releve(id, 0, 3)).ok, "trois mesures de trop : refusé")
U.verifier(not e:rendreCouture(id, releve(id, 0, -3)).ok, "trois mesures de moins : refusé")
for _, mauvais in ipairs({ 2.5, -2.01, 0 / 0, math.huge, "a" }) do
	local faux = table.clone(ecarts)
	faux[5] = mauvais
	U.verifier(not e:rendreCouture(id, faux, duree).ok, "écart invalide refusé : " .. tostring(mauvais))
end
local troue = table.clone(ecarts)
troue[5] = nil
U.verifier(not e:rendreCouture(id, troue, duree).ok, "mesure manquante refusée")
U.verifier(not e:rendreCouture(id, ecarts, duree * 0.85).ok, "couture trop rapide refusée")
U.verifier(not e:rendreCouture(id, ecarts, 0 / 0).ok and not e:rendreCouture(id, ecarts, nil).ok, "durée invalide refusée")
U.verifier(not e:rendreCouture(id, ecarts, duree, "oui").ok, "assistance qui n'est pas un booléen refusée")
U.verifier(e.coutures[id] == nil, "rien n'est noté après un refus")

r = e:rendreCouture(id, ecarts, duree * 0.95)
U.verifier(r.ok and r.note == 1 and r.reste == 3 and e.coutures[id] == 1, "couture parfaite : note 100 %")
U.verifier(not e:rendreCouture(id, ecarts, duree).ok, "une pièce ne se coud qu'une fois")
local releve2, duree2 = releve(PIECES[2])
r = e:rendreCouture(PIECES[2], releve2, duree2, true)
U.verifier(r.ok and r.note == Catalogue.PLAFOND_ASSISTANCE, "avec l'assistance, la note est plafonnée à 85 %")
r = e:rendreCouture(PIECES[3], releve(PIECES[3], 0.3, 2))
U.verifier(r.ok and r.note == 0, "deux mesures de trop tolérées ; écart de 0,3 dm partout : note 0")
r = e:rendreCouture(PIECES[4], releve(PIECES[4], -0.175, -2))
U.verifier(r.ok and U.proche(r.note, 0.5) and r.reste == 0, "deux mesures de moins tolérées ; écart de 0,175 dm : note 50 %")
U.verifier(e.etape == "decorations" and #e:piecesACoudre() == 0, "toutes les pièces cousues : direction les décorations")
U.verifier(not e:rendreCouture(PIECES[1], ecarts, duree).ok, "plus de couture après la dernière pièce")

---------------------------------------------------------------------------
-- Recette de la robe
---------------------------------------------------------------------------
U.verifier(EtatAtelier.nouveau():recette() == nil, "pas de recette sans commande")
local recette = e:recette()
local ok, erreur = Recette.valider(recette)
U.verifier(ok, "la recette de la robe est valide : " .. tostring(erreur))
U.verifier(#recette.pieces == 4 and #recette.accessoires == 0, "4 pièces, pas encore d'accessoires")
local p1 = recette.pieces[1]
U.verifier(p1.id == "corsage_droit_devant" and p1.tissu == "coton_blanc" and p1.x == 2.4 and p1.y == 2.1 and p1.angle == 0 and p1.couture == 1, "pièce : tissu, position sur le rouleau et note de couture")
U.verifier(recette.mesures.poitrine == e.commande.mesures.poitrine and recette.croquis.jupe == "jupe_droite", "mesures de la cliente et croquis")
recette.mesures.poitrine = 0
recette.pieces[1].couture = 0
U.verifier(e.commande.mesures.poitrine ~= 0 and e.coutures[PIECES[1]] == 1, "la recette est une copie")
-- Qualité : droit-fil parfait partout, moyenne des coutures pondérée par la surface
local aC, aJ = Patron.aire("corsage_droit_devant"), Patron.aire("jupe_droite_devant")
local attendue = (aC * 1 + aC * 0.85 + aJ * 0 + aJ * 0.5) / (2 * aC + 2 * aJ)
U.verifier(U.proche(Notation.bilan(e:recette()).qualite, attendue), "qualité de la robe d'après la recette")

---------------------------------------------------------------------------
-- Recommencer remet l'épinglage et la couture à zéro
---------------------------------------------------------------------------
U.verifier(e:recommencer().ok and e.etape == "carnet", "recommencer la robe")
U.verifier(next(e.epinglees) == nil and next(e.coutures) == nil and e:recette() == nil, "épinglage et couture effacés")
local e2 = jusquAEpinglage()
e2:epingler(PIECES[1])
U.verifier(e2:recommencer().ok and next(e2.epinglees) == nil, "recommencer pendant l'épinglage")

---------------------------------------------------------------------------
-- Session : mêmes actions, écouteurs prévenus après chaque succès
---------------------------------------------------------------------------
local s = Session.nouvelle(1)
s.etat = jusquAEpinglage()
local avis = 0
s:surChangement(function()
	avis += 1
end)
U.verifier(s:epingler(PIECES[1]).ok and avis == 1, "Session:epingler")
U.verifier(not s:epingler(PIECES[1]).ok and avis == 1, "refus : pas d'avis")
for i = 2, 4 do
	s:epingler(PIECES[i])
end
local releve3, duree3 = releve(PIECES[1])
U.verifier(s:rendreCouture(PIECES[1], releve3, duree3, false).ok and avis == 5, "Session:rendreCouture")
