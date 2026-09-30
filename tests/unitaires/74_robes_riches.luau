-- Plan 23 : la jupe à étages, la jupe à jupon, le corsage ceinturé. Chacune a ses pièces, son dessin, ses étiquettes
-- et son prestige ; une robe ceinturée à jupon se fait de bout en bout.
local Catalogue = U.module("Catalogue")
local Patron = U.module("Patron")
local Croquis = U.module("Croquis")
local Notation = U.module("Notation")
local Metrage = U.module("Metrage")
local Deblocages = U.module("Deblocages")
local EtatAtelier = U.module("EtatAtelier")

---------------------------------------------------------------------------
-- Les variantes, leurs pièces, leur prestige
---------------------------------------------------------------------------
local ATTENDUES = {
	jupe_etages = { famille = "jupe", pieces = "jupe_droite_devant,jupe_droite_dos,etage_devant,etage_dos", prestige = "Prestige 5" },
	corsage_ceinture = { famille = "corsage", pieces = "corsage_droit_devant,corsage_droit_dos,ceinture_devant,ceinture_dos", prestige = "Prestige 6" },
	jupe_jupon = { famille = "jupe", pieces = "jupe_dessus_devant,jupe_dessus_dos,jupon_devant,jupon_dos", prestige = "Prestige 7" },
}
local fautes = {}
for id, a in pairs(ATTENDUES) do
	local v = Catalogue.variante(id)
	if not (v and v.famille == a.famille and table.concat(v.pieces, ",") == a.pieces and Deblocages.raison("variantes", id) == a.prestige and v.occasion and Croquis.connue(id)) then
		table.insert(fautes, id)
	end
end
table.sort(fautes)
U.verifier(#fautes == 0, "étages (prestige 5), ceinturé (6), jupon (7) : leurs pièces, leurs occasions, leur dessin (en défaut : " .. table.concat(fautes, ", ") .. ")")
U.verifier(Catalogue.piece("ceinture_devant").poids == 0.5 and Catalogue.piece("etage_dos").poids == nil and Catalogue.piece("jupon_devant").poids == nil, "la ceinture pèse 0,5 ; l'étage et le jupon, 1")

---------------------------------------------------------------------------
-- La ceinture se pose à la taille, par-dessus le corsage ; le jupon dépasse sous la jupe de dessus
---------------------------------------------------------------------------
local M = Catalogue.TAILLES.M
local bas = Patron.point("ceinture_devant", "unique", 2.4, 0.6, M)
local haut = Patron.point("ceinture_devant", "unique", 2.4, 0, M)
U.verifier(math.abs(bas.Y) < 1e-9 and math.abs(haut.Y - 0.6) < 1e-9, ("la ceinture : de la taille à 0,6 dm au-dessus (%.2f, %.2f)"):format(bas.Y, haut.Y))
local ourletJupon = Patron.point("jupon_devant", "unique", 4, 6.6, M)
local ourletDessus = Patron.point("jupe_dessus_devant", "unique", 4, 6, M)
U.verifier(ourletJupon.Y < ourletDessus.Y - 0.5, "le jupon descend plus bas que la jupe de dessus")

---------------------------------------------------------------------------
-- Le dessin : toucher l'étage, le jupon, la ceinture choisit leurs pièces
---------------------------------------------------------------------------
local ETAGES = { corsage = "corsage_ceinture", manches = "manches_sans", col = "col_sans", jupe = "jupe_etages" }
local JUPON = { corsage = "corsage_droit", manches = "manches_sans", col = "col_sans", jupe = "jupe_jupon" }
local function toucher(croquis, x, y)
	local _, pieces = Croquis.partieA(croquis, x, y)
	return table.concat(pieces or {}, ",")
end
U.verifier(toucher(ETAGES, 50, 75) == "etage_devant,etage_dos" and toucher(ETAGES, 50, 55) == "jupe_droite_devant,jupe_droite_dos", "toucher l'étage, la jupe")
U.verifier(toucher(ETAGES, 50, 40) == "ceinture_devant,ceinture_dos" and toucher(ETAGES, 50, 30) == "corsage_droit_devant,corsage_droit_dos", "toucher la ceinture, le corps du corsage")
U.verifier(toucher(JUPON, 50, 85) == "jupon_devant,jupon_dos" and toucher(JUPON, 50, 60) == "jupe_dessus_devant,jupe_dessus_dos", "toucher le jupon qui dépasse, la jupe de dessus")

---------------------------------------------------------------------------
-- Une robe ceinturée à jupon, de bout en bout : coupée, épinglée, cousue, livrée, payée selon son poids
---------------------------------------------------------------------------
local CEINTUREE = { corsage = "corsage_ceinture", manches = "manches_ballon", col = "col_claudine", jupe = "jupe_jupon" }
local r = EtatAtelier.nouveau(3000)
U.commander(r, Random.new(23))
local ids = Patron.piecesDuCroquis(CEINTUREE)
local tissus = {}
for _, id in ipairs(ids) do
	tissus[id] = "coton_blanc"
end
assert(r:validerCroquis(CEINTUREE, tissus).ok)
local placements, longueur = Metrage.disposition(ids)
assert(placements and r:acheter("coton_blanc", longueur).ok and r:commencerDecoupe().ok)
for _, id in ipairs(ids) do
	local c = r:couper(id, placements[id])
	assert(c.ok, id .. " : " .. tostring(c.erreur))
end
for _, id in ipairs(ids) do
	assert(r:epingler(id).ok, id)
end
for _, id in ipairs(ids) do
	local _, l = Patron.trajetCouture(id)
	assert(r:rendreCouture(id, table.create(math.round(l / 0.1), 0.02), l).ok, id)
end
assert(r:decorer({}).ok)
r.commande.exigences = { { type = "qualite", valeur = 0.1 } }
local bilan = r:bilan()
local l = r:livrer()
U.verifier(#ids == 10 and l.ok and l.reussie and l.paie == Notation.paie(9, 1, bilan.qualite), ("robe ceinturée à jupon (dix pièces) livrée : payée pour un poids de 9 (%s po)"):format(tostring(l.paie)))
