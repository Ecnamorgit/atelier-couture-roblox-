local Catalogue = U.module("Catalogue")
local Patron = U.module("Patron")
local Notation = U.module("Notation")

-- Droit-fil aux angles de référence
local attendus = { { 0, 1 }, { 45, 0.6 }, { 90, 0.75 }, { 135, 0.6 }, { 180, 1 }, { -90, 0.75 }, { 22.5, 0.8 }, { 360, 1 } }
for _, a in ipairs(attendus) do
	U.verifier(U.proche(Notation.droitFil(a[1], false), a[2]), ("droit-fil à %g° = %g"):format(a[1], a[2]))
end
local biais = { { 45, 1 }, { 135, 1 }, { 0, 0.7 }, { 90, 0.7 }, { 22.5, 0.85 } }
for _, a in ipairs(biais) do
	U.verifier(U.proche(Notation.droitFil(a[1], true), a[2]), ("pièce en biais à %g° = %g"):format(a[1], a[2]))
end

-- Aimantation à 6°
U.verifier(U.proche(Notation.aimanter(4, "jupe_droite_devant"), 0), "4° s'aimante à 0°")
U.verifier(U.proche(Notation.aimanter(-5, "jupe_droite_devant"), 0), "−5° s'aimante à 0°")
U.verifier(U.proche(Notation.aimanter(177, "jupe_droite_devant"), 180), "177° s'aimante à 180°")
U.verifier(U.proche(Notation.aimanter(7, "jupe_droite_devant"), 7), "7° ne s'aimante pas")
U.verifier(U.proche(Notation.aimanter(41, "jupe_evasee_devant"), 45), "pièce en biais : 41° s'aimante à 45°")
U.verifier(U.proche(Notation.aimanter(2, "jupe_evasee_devant"), 2), "pièce en biais : 2° ne s'aimante pas à 0°")

-- Couture : 100 % jusqu'à 0,05 dm, 0 % à 0,30 dm
U.verifier(U.proche(Notation.noteCouture({ 0, 0.05, -0.05 }, false), 1), "couture parfaite")
U.verifier(U.proche(Notation.noteCouture({ 0.3 }, false), 0), "0,30 dm d'écart = 0 %")
U.verifier(U.proche(Notation.noteCouture({ 0.175, -0.175 }, false), 0.5), "0,175 dm d'écart = 50 %")
U.verifier(U.proche(Notation.noteCouture({ 0, 2 }, false), 0.5), "moyenne des mesures")
U.verifier(U.proche(Notation.noteCouture({ 0, 0 }, true), 0.85), "assistance plafonnée à 85 %")
U.verifier(Notation.noteCouture({}, false) == 0, "aucune mesure = 0")

-- Qualité pondérée par la surface
local q = Notation.qualite({ { aire = 30, droitFil = 1, couture = 1 }, { aire = 10, droitFil = 0.6, couture = 0.5 } })
U.verifier(U.proche(q, (30 + 10 * 0.3) / 40), "qualité pondérée par la surface")

-- Styles : croquis tout simple + un seul tissu + un accessoire
local croquis = { corsage = "corsage_droit", manches = "manches_sans", col = "col_sans", jupe = "jupe_droite" }
local s = Notation.styles({ croquis = croquis, tissus = { coton_blanc = 50 }, accessoires = { { id = "noeud_satin" } } })
-- décontracté : variantes 6 + 3 = 9 ; tissu 2 × 10 = 20 ; accessoire 0 → 29
U.verifier(U.proche(s.decontracte, 29), "décontracté = 9 (variantes) + 20 (tissu)")
-- mignon : tissu 2 × 4 = 8 ; nœud 0,5 × 4 = 2 → 10
U.verifier(U.proche(s.mignon, 10), "mignon = 8 (tissu) + 2 (nœud)")
U.verifier(s.gothique == 0, "aucun point gothique")
-- Évasée : décontracté −4 sur la variante, borné à 0
local s2 = Notation.styles({ croquis = { corsage = "corsage_v", manches = "manches_longues", col = "col_montant", jupe = "jupe_evasee" },
	tissus = { velours_noir = 1 }, accessoires = {} })
U.verifier(s2.decontracte == 0, "score borné à 0")
local beaucoup = {}
for _ = 1, 300 do
	table.insert(beaucoup, { id = "croix_argent" })
end
U.verifier(Notation.styles({ croquis = croquis, tissus = {}, accessoires = beaucoup }).gothique == 100, "score borné à 100")

-- Garniture : points par tranche de 5 dm entamée
U.verifier(U.proche(Notation.longueurGarniture("jupe_droite_devant", { { u = 0, v = 1 }, { u = 1, v = 1 } }), 5), "garniture de 5 dm")
local g = Notation.styles({ croquis = croquis, tissus = {}, accessoires = { { id = "ruban_rose", longueur = 5.5 } } })
U.verifier(U.proche(g.mignon, 0.5 * 3 * 2), "5,5 dm de ruban = 2 tranches")

-- Fourchette du carnet
local f = Notation.fourchette(croquis, {})
for _, st in ipairs(Catalogue.STYLES) do
	U.verifier(f[st].min <= f[st].max, st .. " : min ≤ max")
end
U.verifier(U.proche(f.decontracte.acquis, 9), "acquis = points des variantes")
local pieces = Patron.piecesDuCroquis(croquis)
local tous = {}
for _, id in ipairs(pieces) do
	tous[id] = "coton_blanc"
end
local f2 = Notation.fourchette(croquis, tous)
U.verifier(U.proche(f2.decontracte.min, 29) and U.proche(f2.decontracte.max, 29), "tous les tissus choisis : fourchette réduite au score")

-- Bilan d'une recette complète
local recette = {
	croquis = croquis,
	pieces = {
		{ id = "corsage_droit_devant", tissu = "soie_rouge", x = 3, y = 3, angle = 0, couture = 1 },
		{ id = "corsage_droit_dos", tissu = "soie_rouge", x = 9, y = 3, angle = 90, couture = 1 },
		{ id = "jupe_droite_devant", tissu = "coton_blanc", x = 3, y = 3, angle = 0, couture = 0.5 },
		{ id = "jupe_droite_dos", tissu = "coton_blanc", x = 9, y = 3, angle = 0, couture = 1 },
	},
	accessoires = {
		{ id = "bouton_nacre", piece = 1, u = 0.5, v = 0.2, echelle = 1, angle = 0 },
		{ id = "dentelle_blanche", piece = 3, trajet = { { u = 0, v = 1 }, { u = 1, v = 1 } } },
	},
}
local bilan = Notation.bilan(recette)
local aC, aJ = Patron.aire("corsage_droit_devant"), Patron.aire("jupe_droite_devant")
local attendue = (aC * 1 + aC * 0.75 + aJ * 0.5 + aJ * 1) / (2 * aC + 2 * aJ)
U.verifier(U.proche(bilan.qualite, attendue), "qualité du bilan (dos du corsage en travers, jupe mal cousue)")
U.verifier(bilan.teinte == "blanc", "teinte dominante = la plus grande surface (jupe blanche)")
U.verifier(bilan.accessoires.bouton_nacre == 1 and bilan.accessoires.dentelle_blanche == 1, "accessoires comptés")
U.verifier(bilan.nbPieces == 4, "4 pièces")

-- Exigences
local ok, ratees = Notation.verifierExigences({
	{ type = "min", style = "decontracte", valeur = 10 },
	{ type = "max", style = "gothique", valeur = 10 },
	{ type = "qualite", valeur = 0.95 },
	{ type = "teinte", teinte = "rouge" },
	{ type = "accessoire", id = "bouton_nacre" },
}, bilan)
U.verifier(not ok and #ratees == 2 and ratees[1] == 3 and ratees[2] == 4, "qualité et teinte ratées, le reste rempli")

-- Paie
U.verifier(Notation.base(4, 1) == 75 and Notation.base(6, 3) == 125, "base de 75 à 125")
U.verifier(Notation.paie(4, 1, 1) == 113 and Notation.paie(4, 1, 0) == 38, "paie = base × (0,5 + qualité), arrondie")

-- Valeurs invalides venues d'un client : jamais de NaN, jamais 100 %
U.verifier(Notation.droitFil(0 / 0, false) == 0 and Notation.droitFil(math.huge, true) == 0, "angle non fini = droit-fil 0")
local n = Notation.noteCouture({ 0 / 0, 0, math.huge }, false)
U.verifier(n == n and U.proche(n, 1 / 3), "écart non fini = mesure ratée, note jamais NaN")
-- Recette qui cite un tissu ou un accessoire inconnu : erreur franche (le serveur valide avant)
local mauvaise = { croquis = croquis, pieces = { { id = "jupe_droite_devant", tissu = "inconnu", x = 0, y = 0, angle = 0, couture = 1 } } }
U.verifier(not pcall(Notation.bilan, mauvaise), "tissu inconnu : erreur")
U.verifier(not pcall(Notation.styles, { croquis = croquis, tissus = {}, accessoires = { { id = "inconnu" } } }), "accessoire inconnu : erreur")
-- Garniture d'un seul point : longueur nulle, aucun point, pas d'erreur
U.verifier(Notation.longueurGarniture("jupe_droite_devant", { { u = 0.5, v = 0.5 } }) == 0, "garniture d'un point : longueur 0")
local g0 = Notation.styles({ croquis = croquis, tissus = {}, accessoires = { { id = "ruban_rose", longueur = 0 } } })
U.verifier(U.proche(g0.mignon, 0), "garniture de longueur nulle : aucun point")
