local Polygone = U.module("Polygone")

local carre = { { x = 0, y = 0 }, { x = 4, y = 0 }, { x = 4, y = 2 }, { x = 0, y = 2 } }
local trapeze = { { x = 1, y = 0 }, { x = 5, y = 0 }, { x = 6, y = 6 }, { x = 0, y = 6 } }

-- Aire et boîte
U.verifier(U.proche(Polygone.aire(carre), 8), "aire d'un rectangle 4 × 2")
U.verifier(U.proche(Polygone.aire(trapeze), 30), "aire du trapèze (4 + 6) / 2 × 6")
local b = Polygone.boite(trapeze)
U.verifier(b.minX == 0 and b.maxX == 6 and b.minY == 0 and b.maxY == 6, "boîte englobante")

-- Point dans le polygone
U.verifier(Polygone.contient(carre, 2, 1), "le centre est dedans")
U.verifier(not Polygone.contient(carre, 5, 1), "un point à droite est dehors")
U.verifier(not Polygone.contient(trapeze, 0.2, 0.5), "le coin coupé du trapèze est dehors")

-- Étendue d'une ligne
local x0, x1 = Polygone.etendueLigne(trapeze, 3)
U.verifier(U.proche(x0, 0.5) and U.proche(x1, 5.5), "étendue du trapèze à mi-hauteur")
U.verifier(Polygone.etendueLigne(carre, 5) == nil, "ligne hors du polygone")
local v = { { x = 0, y = 0 }, { x = 1, y = 0 }, { x = 2, y = 2 }, { x = 3, y = 0 }, { x = 4, y = 0 }, { x = 4, y = 4 }, { x = 0, y = 4 } }
local a0, a1 = Polygone.etendueLigne(v, 1)
U.verifier(U.proche(a0, 0) and U.proche(a1, 4), "une encoche en V ne réduit pas l'étendue extérieure")

-- Pose : translation et rotation autour du centre
local centre = Polygone.centre(carre)
local pose = Polygone.poser(carre, { x = 10, y = 20, angle = 90 }, centre)
local p = pose[1] -- (0,0) : décalage (−2, −1) → tourné de 90° → (1, −2)
U.verifier(U.proche(p.x, 11) and U.proche(p.y, 18), "rotation de 90° : (0,0) va en (11, 18)")
U.verifier(U.proche(Polygone.aire(pose), 8), "la pose conserve l'aire")

-- Miroir
local m = Polygone.miroir(carre, 7)
local bm = Polygone.boite(m)
U.verifier(U.proche(bm.minX, 10) and U.proche(bm.maxX, 14), "miroir par rapport à x = 7")
U.verifier(U.proche(Polygone.aire(m), 8), "le miroir conserve l'aire")

-- Arête décalée vers l'intérieur, dans les deux sens de parcours
local haut = Polygone.areteDecalee(carre, 1, 0.15)
U.verifier(U.proche(haut.a.y, 0.15) and U.proche(haut.b.y, 0.15), "arête du haut décalée vers le bas (intérieur)")
local inverse = { carre[4], carre[3], carre[2], carre[1] }
local bas = Polygone.areteDecalee(inverse, 1, 0.15) -- (0,2) → (4,2)
U.verifier(U.proche(bas.a.y, 1.85), "sens inverse : arête du bas décalée vers le haut")
U.verifier(U.proche(Polygone.longueur(haut), 4), "longueur d'un segment")
