-- Sous-projet 6 : un rouleau entamé par les robes d'avant. Leurs pièces y ont laissé des trous : on ne coupe pas
-- dessus, on coupe dans les vides ou dessous ; ce qu'une robe ajoute à la bande entamée se compte à part.
local Coupon = U.module("Coupon")

-- Une jupe droite (5 × 6) centrée en (2.5, 3) occupe [0, 5] × [0, 6] ; un corsage (4,8 × 4,2) en (9.6, 2.1) occupe
-- [7.2, 12] × [0, 4.2]
local TROUS = {
	{ piece = "jupe_droite_devant", x = 2.5, y = 3, angle = 0 },
	{ piece = "corsage_droit_devant", x = 9.6, y = 2.1, angle = 0 },
}
local c = Coupon.nouveau(20, TROUS)
U.verifier(#c.trous == 2 and next(c.poses) == nil and c:longueurUtilisee() == 6 and c:ajout() == 0, "deux trous : 6 dm entamés, rien d'ajouté, rien de coupé pour cette robe")
local ok, erreur = c:verifier("jupe_droite_dos", { x = 4, y = 3, angle = 0 })
U.verifier(not ok and erreur == "La pièce passe sur un trou du tissu entamé.", "une pièce sur un trou : refusée (" .. tostring(erreur) .. ")")
U.verifier(c:verifier("jupe_droite_devant", { x = 2.5, y = 9, angle = 0 }), "la même pièce qu'un trou se coupe encore, ailleurs (une autre robe)")

-- Couper dans un vide de la bande : rien n'est ajouté
U.verifier(c:poser("corsage_droit_dos", { x = 9.6, y = 6.4, angle = 0 }) and c:longueurUtilisee() == 9 and c:ajout() == 3, "un corsage sous le trou du corsage (jusqu'à 8,5 dm) : 3 dm ajoutés à la bande")
local v = Coupon.nouveau(20, { TROUS[1], { piece = "jupe_droite_dos", x = 11.5, y = 3, angle = 0 } })
U.verifier(v:poser("col_montant", { x = 6, y = 1, angle = 0 }) and v:ajout() == 0, "un col plié entre deux trous de jupe (et son symétrique) : rien d'ajouté")

-- Sous la bande : ce que la robe ajoute
local s = Coupon.nouveau(20, TROUS)
U.verifier(s:poser("jupe_droite_dos", { x = 2.5, y = 9.1, angle = 0 }) and s:longueurUtilisee() == 13 and s:ajout() == 7, "une jupe sous la bande : 13 dm entamés, 7 ajoutés")

-- Une pièce pliée : son symétrique ne passe pas non plus sur un trou
local p = Coupon.nouveau(10, { { piece = "jupe_droite_devant", x = 11.5, y = 3, angle = 0 } })
local okP, errP = p:verifier("manche_longue", { x = 5, y = 3, angle = 0 })
U.verifier(not okP and errP == "La pièce passe sur un trou du tissu entamé.", "le symétrique d'une manche pliée tomberait sur un trou : refusée")

-- Des trous lus d'une sauvegarde : relus s'ils sont lisibles, sinon rien (la bande sera jetée)
local lus = Coupon.lireTrous(TROUS, 100)
U.verifier(lus ~= nil and #lus == 2 and lus[1].piece == "jupe_droite_devant" and lus[2].y == 2.1 and lus ~= TROUS, "trous lisibles : relus (une copie)")
U.verifier(Coupon.lireTrous({ TROUS[1], { piece = "jupe_droite_devant", x = 2.5, y = 9, angle = 0 } }, 100) ~= nil, "la même pièce deux fois (deux robes) : lisible")
for k, mauvais in ipairs({
	"abîmé",
	{ TROUS[1], { piece = "jupe_droite_dos", x = 4, y = 3, angle = 0 } }, -- deux trous qui se chevauchent
	{ { piece = "inconnue", x = 3, y = 3, angle = 0 } },
	{ { piece = "jupe_droite_devant", x = 0 / 0, y = 3, angle = 0 } },
	{ { piece = "jupe_droite_devant", x = 13, y = 3, angle = 0 } }, -- hors du rouleau
	{ { piece = "jupe_droite_devant", x = 2.5, y = 98, angle = 0 } }, -- plus bas que la longueur
	{ { piece = "manche_longue", x = 7, y = 3, angle = 0 } }, -- pliée, à cheval sur le pli
	{ premier = TROUS[1] }, -- pas une liste
	{ 42 },
}) do
	U.verifier(Coupon.lireTrous(mauvais, 100) == nil, "trous illisibles : rien (" .. k .. ")")
end
U.verifier(#Coupon.lireTrous({}, 100) == 0, "aucun trou : une liste vide")
