-- Sous-projet 7 : des couches. Une pièce de jupe peut partir plus bas que la taille (depart), se poser par-dessus
-- d'autres (couche) et s'évaser depuis son propre haut (ampleur) : le volant, la basque. Une couche ne traverse jamais
-- celle du dessous : partout où deux pièces du même côté sont à la même hauteur, celle du dessus est plus loin du corps
-- d'au moins 0,03 dm.
local Catalogue = U.module("Catalogue")
local Patron = U.module("Patron")
local Polygone = U.module("Polygone")
local Maillage = U.module("Maillage")
local Recette = U.module("Recette")

-- Point (u, v) d'une pièce (u d'un bord à l'autre de la ligne, v du haut au bas), et son rayon (dm, dans l'ellipse)
local function point(id, u, v, mesures)
	local b = Polygone.boite(Catalogue.piece(id).contour)
	local y = b.minY + v * (b.maxY - b.minY)
	local x0, x1 = Polygone.etendueLigne(Catalogue.piece(id).contour, y)
	return Patron.point(id, "unique", x0 + u * (x1 - x0), y, mesures)
end
local function rayon(p)
	return math.sqrt((p.X / Patron.ELLIPSE.x) ^ 2 + (p.Z / Patron.ELLIPSE.z) ^ 2)
end
local function hauteur(id)
	local b = Polygone.boite(Catalogue.piece(id).contour)
	return b.maxY - b.minY
end

-- Tailles du catalogue et silhouettes extrêmes qu'accepte une recette
local tailles = table.clone(Catalogue.TAILLES)
for _, P in ipairs(Recette.POITRINE) do
	for _, T in ipairs(Recette.TAILLE) do
		for _, H in ipairs(Recette.HANCHES) do
			if T <= P and T <= H then
				tailles[("P%g-T%g-H%g"):format(P, T, H)] = { poitrine = P, taille = T, hanches = H }
			end
		end
	end
end

-- Le plus petit écart (dm de rayon) entre « dessus » et « dessous » là où ils sont à la même hauteur (nil : jamais)
local function ecartMin(dessus, dessous, mesures)
	local eD, eS = Catalogue.piece(dessus).enroulement, Catalogue.piece(dessous).enroulement
	local hD, hS = hauteur(dessus), hauteur(dessous)
	local pire
	for j = 0, 16 do
		local yd = (eD.depart or 0) + hD * j / 16
		local vS = (yd - (eS.depart or 0)) / hS
		if vS >= 0 and vS <= 1 then
			for i = 0, 32 do
				local e = rayon(point(dessus, i / 32, j / 16, mesures)) - rayon(point(dessous, i / 32, vS, mesures))
				pire = if pire then math.min(pire, e) else e
			end
		end
	end
	return pire
end

---------------------------------------------------------------------------
-- Un volant part plus bas que la taille, et descend plus bas que sa jupe
---------------------------------------------------------------------------
local M = Catalogue.TAILLES.M
local haut, bas = point("volant_devant", 0.5, 0, M), point("volant_devant", 0.5, 1, M)
U.verifier(math.abs(haut.Y + 5) < 1e-9 and math.abs(bas.Y + 6.6) < 1e-9, ("le volant part à 5 dm sous la taille, jusqu'à 6,6 dm (%.2f, %.2f)"):format(-haut.Y, -bas.Y))
U.verifier(rayon(bas) > rayon(haut) + 0.3, "le volant s'évase depuis son haut")

---------------------------------------------------------------------------
-- Une couche ne traverse pas celle du dessous : le volant sur la jupe droite, la basque sur toutes les jupes
---------------------------------------------------------------------------
local paires = { { "volant_devant", "jupe_droite_devant" }, { "volant_dos", "jupe_droite_dos" } }
for id, def in pairs(Catalogue.Pieces) do
	if def.enroulement.type == "jupe" and not def.enroulement.couche then
		table.insert(paires, { "basque_" .. def.enroulement.cote, id })
	end
end
table.sort(paires, function(a, b)
	return a[1] .. a[2] < b[1] .. b[2]
end)
local recouvertes, ratees = 0, {}
for _, paire in ipairs(paires) do
	for nom, mesures in pairs(tailles) do
		local e = ecartMin(paire[1], paire[2], mesures)
		if e then
			recouvertes += 1
			if e < 0.03 then
				table.insert(ratees, ("%s sur %s (%s) : %.3f"):format(paire[1], paire[2], nom, e))
			end
		end
	end
end
U.verifier(recouvertes >= #paires and #ratees == 0, ("chaque couche passe au moins 0,03 dm au-dessus de celle du dessous (%d cas ; en défaut : %s)"):format(recouvertes, table.concat(ratees, " ; ")))

---------------------------------------------------------------------------
-- Une grille propre à la pièce : le volant, froncé serré, en 32 × 3 (24 × 2 en vitrine, où ses fronces se voient encore)
---------------------------------------------------------------------------
local maillage = Maillage.piece("volant_devant", "unique", M, "robe")
local vitrine = Maillage.piece("volant_devant", "unique", M, "vitrine")
local jupe = Maillage.piece("jupe_droite_devant", "unique", M, "robe")
U.verifier(#maillage.positions == 33 * 4 and #vitrine.positions == 25 * 3 and #jupe.positions == 13 * 17, ("grille du volant : 33 × 4 points (vitrine 25 × 3) ; la jupe garde 13 × 17 (%d, %d, %d)"):format(#maillage.positions, #vitrine.positions, #jupe.positions))
-- (relecture) en vitrine, l'ourlet du volant ondule encore : ses fronces ne tombent pas toutes sur les creux
local mini, maxi = math.huge, 0
for k = #vitrine.positions - 24, #vitrine.positions do
	local r = rayon(vitrine.positions[k])
	mini, maxi = math.min(mini, r), math.max(maxi, r)
end
U.verifier(maxi - mini > 0.1, ("en vitrine, l'ourlet du volant ondule (%.3f dm d'écart)"):format(maxi - mini))
U.verifier(not pcall(Maillage.piece, "volant_devant", "unique", M, "inconnue"), "une finesse inconnue est refusée")

---------------------------------------------------------------------------
-- Les petites pièces ajoutées pèsent moitié ; les autres, un
---------------------------------------------------------------------------
U.verifier(Catalogue.piece("volant_devant").poids == 0.5 and Catalogue.piece("basque_dos").poids == 0.5 and Catalogue.piece("jupe_droite_devant").poids == nil, "volant et basque : poids 0,5 ; les autres pièces, sans poids (1)")
