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
U.verifier(n == 108, "108 croquis vérifiés")

-- Droit-fil parfait : 0° pour une pièce normale, 45° pour une pièce en biais
local p = Metrage.disposition({ "jupe_evasee_devant", "corsage_droit_dos" })
U.verifier(p.jupe_evasee_devant.angle == 45 and p.corsage_droit_dos.angle == 0, "angles de droit-fil parfaits")

-- Cas simples
U.verifier(Metrage.conseil({ "jupe_droite_devant", "jupe_droite_dos" }) == 6, "deux jupes droites côte à côte : 6 dm")
U.verifier(Metrage.conseil({ "manche_longue" }) == 6, "une manche longue pliée : 6 dm")
local _, vide = Metrage.disposition({})
U.verifier(vide == 0, "aucune pièce : 0 dm")
