local Catalogue = U.module("Catalogue")
local Patron = U.module("Patron")
local Coupon = U.module("Coupon")
local Metrage = U.module("Metrage")

-- Pour chaque croquis possible, toutes les pièces dans un seul tissu : la disposition est acceptée par Coupon
local n = 0
for _, c in ipairs(Catalogue.variantesDe("corsage")) do
	for _, m in ipairs(Catalogue.variantesDe("manches")) do
		for _, k in ipairs(Catalogue.variantesDe("col")) do
			for _, j in ipairs(Catalogue.variantesDe("jupe")) do
				local ids = Patron.piecesDuCroquis({ corsage = c.id, manches = m.id, col = k.id, jupe = j.id })
				local placements, longueur = Metrage.disposition(ids)
				local coupon = Coupon.nouveau(longueur)
				for _, id in ipairs(ids) do
					local ok, erreur = coupon:poser(id, placements[id])
					U.verifier(ok, ("%s/%s/%s/%s : %s posée (%s)"):format(c.id, m.id, k.id, j.id, id, tostring(erreur)))
				end
				U.verifier(coupon:longueurUtilisee() == longueur, "la longueur conseillée est celle utilisée")
				U.verifier(longueur <= 40, "une robe tient dans 4 m de tissu")
				n += 1
			end
		end
	end
end
U.verifier(n == 1260, "1 260 croquis vérifiés (sous-projet 7 : avec les corsages à basque et ceinturé, les jupes à volant, à étages, à jupon et à traîne)")

-- Tissu à acheter : le conseil de chaque tissu, moins le stock ; les pièces sans tissu ne comptent pas
local PIECES = { "corsage_droit_devant", "corsage_droit_dos", "jupe_droite_devant", "jupe_droite_dos" }
local liste, total = Metrage.aAcheter(PIECES, { corsage_droit_devant = "coton_blanc", corsage_droit_dos = "coton_blanc", jupe_droite_devant = "soie_rouge" }, { coton_blanc = 3 })
local conseilCoton = Metrage.conseil({ "corsage_droit_devant", "corsage_droit_dos" })
local conseilSoie = Metrage.conseil({ "jupe_droite_devant" })
U.verifier(#liste == 2 and liste[1].tissu == "coton_blanc" and liste[1].conseil == conseilCoton and liste[1].manque == math.max(0, conseilCoton - 3), "à acheter : le conseil du coton, moins son stock")
U.verifier(liste[2].tissu == "soie_rouge" and liste[2].conseil == conseilSoie and liste[2].manque == conseilSoie, "à acheter : la soie, sans stock")
U.verifier(total == liste[1].manque + liste[2].manque, "à acheter : le total")
local _, rien = Metrage.aAcheter(PIECES, { corsage_droit_devant = "coton_blanc" }, { coton_blanc = 99 })
U.verifier(rien == 0, "assez de stock : rien à acheter")
U.verifier(#Metrage.aAcheter(PIECES, {}, {}) == 0, "aucun tissu choisi : rien")

-- Droit-fil parfait : 0° pour une pièce normale, 45° pour une pièce en biais
local p = Metrage.disposition({ "jupe_evasee_devant", "corsage_droit_dos" })
U.verifier(p.jupe_evasee_devant.angle == 45 and p.corsage_droit_dos.angle == 0, "angles de droit-fil parfaits")

-- Cas simples
U.verifier(Metrage.conseil({ "jupe_droite_devant", "jupe_droite_dos" }) == 6, "deux jupes droites côte à côte : 6 dm")
U.verifier(Metrage.conseil({ "manche_longue" }) == 6, "une manche longue pliée : 6 dm")
local _, vide = Metrage.disposition({})
U.verifier(vide == 0, "aucune pièce : 0 dm")
