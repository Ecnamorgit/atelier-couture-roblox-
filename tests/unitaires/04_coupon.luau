local Coupon = U.module("Coupon")

-- Une jupe droite (5 × 6) centrée en (2.5, 3) occupe [0, 5] × [0, 6]
local c = Coupon.nouveau(20)
U.verifier(c:poser("jupe_droite_devant", { x = 2.5, y = 3, angle = 0 }), "pose valide dans le coin")
U.verifier(c:longueurUtilisee() == 6, "6 dm consommés")

-- Chevauchement, sortie du rouleau, pièce déjà coupée
local ok, erreur = c:verifier("jupe_droite_dos", { x = 4, y = 3, angle = 0 })
U.verifier(not ok and erreur:find("chevauche") ~= nil, "chevauchement refusé")
ok, erreur = c:verifier("jupe_droite_dos", { x = 12, y = 3, angle = 0 })
U.verifier(not ok and erreur:find("dépasse") ~= nil, "sortie à droite du rouleau refusée")
ok = c:verifier("jupe_droite_dos", { x = 7.5, y = 18, angle = 0 })
U.verifier(not ok, "sortie en bas de la longueur déroulée refusée")
ok, erreur = c:verifier("jupe_droite_devant", { x = 8, y = 10, angle = 0 })
U.verifier(not ok and erreur:find("déjà") ~= nil, "une pièce ne se coupe qu'une fois")
U.verifier(c:poser("jupe_droite_dos", { x = 7.6, y = 3, angle = 0 }), "pièce voisine collée sans chevauchement")

-- Valeurs invalides (exploit)
for _, mauvais in ipairs({ { x = 0 / 0, y = 3, angle = 0 }, { x = math.huge, y = 3, angle = 0 }, { x = 3, y = 3 }, "texte" }) do
	U.verifier(not c:verifier("corsage_droit_dos", mauvais), "placement invalide refusé")
end
U.verifier(not c:verifier("inconnue", { x = 3, y = 12, angle = 0 }), "pièce inconnue refusée")

-- Rotation de 90° : la jupe 5 × 6 devient 6 × 5
local r = Coupon.nouveau(10)
U.verifier(r:poser("jupe_droite_devant", { x = 3, y = 2.5, angle = 90 }), "pièce tournée de 90° qui tient")
U.verifier(r:longueurUtilisee() == 5, "la rotation change la longueur consommée")

-- Pièce pliée : elle occupe aussi son symétrique de l'autre côté du pli (x = 7)
local p = Coupon.nouveau(10)
ok, erreur = p:verifier("manche_longue", { x = 8, y = 3, angle = 0 })
U.verifier(not ok and erreur:find("pli") ~= nil, "une pièce pliée doit tenir d'un côté du pli")
U.verifier(p:poser("manche_longue", { x = 5, y = 3, angle = 0 }), "manche posée contre le pli")
ok, erreur = p:verifier("jupe_droite_devant", { x = 9.5, y = 3, angle = 0 })
U.verifier(not ok and erreur:find("chevauche") ~= nil, "le symétrique de la manche occupe le tissu")

-- Tolérance aux arrondis : une pièce exactement au bord est acceptée
local e = Coupon.nouveau(6)
U.verifier(e:poser("jupe_droite_devant", { x = 11.5, y = 3, angle = 0 }), "pièce au ras du bord droit acceptée")

-- Rouleau vide : toute pièce est refusée
local vide = Coupon.nouveau(0)
U.verifier(not vide:verifier("col_montant", { x = 1, y = 0.3, angle = 0 }), "rouleau de longueur nulle : pièce refusée")
