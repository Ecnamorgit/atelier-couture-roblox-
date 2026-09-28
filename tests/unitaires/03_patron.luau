local Catalogue = U.module("Catalogue")
local Polygone = U.module("Polygone")
local Patron = U.module("Patron")

local function fini(n)
	return n == n and n ~= math.huge and n ~= -math.huge
end

-- Pièces d'un croquis, dans l'ordre des familles
local liste = Patron.piecesDuCroquis({ corsage = "corsage_v", manches = "manches_ballon", col = "col_sans", jupe = "jupe_ample" })
U.verifier(#liste == 5 and liste[1] == "corsage_v_devant" and liste[2] == "corsage_droit_dos" and liste[3] == "manche_ballon"
	and liste[4] == "jupe_ample_devant" and liste[5] == "jupe_ample_dos", "pièces du croquis dans l'ordre des familles")
U.verifier(not pcall(Patron.piecesDuCroquis, { corsage = "jupe_droite", manches = "manches_sans", col = "col_sans", jupe = "jupe_droite" }),
	"une variante de la mauvaise famille est refusée")
U.verifier(not pcall(Patron.piecesDuCroquis, { corsage = "corsage_droit", jupe = "jupe_droite" }), "un croquis incomplet est refusé")
U.verifier(not pcall(Patron.piecesDuCroquis, "texte"), "un croquis qui n'est pas une table est refusé")

-- Copies et surface
U.verifier(#Patron.copies("manche_ballon") == 2 and Patron.copies("jupe_droite_devant")[1] == "unique", "copies d'une pièce pliée")
U.verifier(U.proche(Patron.aire("manche_ballon"), 2 * Polygone.aire(Catalogue.piece("manche_ballon").contour)),
	"la surface d'une pièce pliée compte les deux copies")

-- Trajet de couture : côtés + taille d'un rectangle 4,8 × 4,2
local segments, longueur = Patron.trajetCouture("corsage_droit_devant")
U.verifier(#segments == 3 and U.proche(longueur, 4.2 + 4.8 + 4.2), "trajet de couture du corsage droit")
for _, s in ipairs(segments) do
	local milieu = { x = (s.a.x + s.b.x) / 2, y = (s.a.y + s.b.y) / 2 }
	U.verifier(Polygone.contient(Catalogue.piece("corsage_droit_devant").contour, milieu.x, milieu.y),
		"le trajet de couture est à l'intérieur de la pièce")
end

-- Coordonnées (u, v)
local u, v = Patron.uv("jupe_trapeze_devant", 1, 0)
U.verifier(U.proche(u, 0) and U.proche(v, 0), "coin haut gauche du trapèze : u = 0, v = 0")
u, v = Patron.uv("jupe_trapeze_devant", 6, 6)
U.verifier(U.proche(u, 1) and U.proche(v, 1), "coin bas droit du trapèze : u = 1, v = 1")

-- Toutes les pièces, toutes les copies, toutes les tailles : positions finies et direction unitaire
for id, def in pairs(Catalogue.Pieces) do
	local b = Polygone.boite(def.contour)
	for _, taille in pairs(Catalogue.TAILLES) do
		for _, copie in ipairs(Patron.copies(id)) do
			for i = 0, 8 do
				for j = 0, 8 do
					local x = b.minX + (b.maxX - b.minX) * i / 8
					local y = b.minY + (b.maxY - b.minY) * j / 8
					if Polygone.contient(def.contour, x, y) then
						local p, d = Patron.point(id, copie, x, y, taille)
						U.verifier(fini(p.X) and fini(p.Y) and fini(p.Z), id .. " : position finie")
						U.verifier(U.proche(d.Magnitude, 1, 1e-6), id .. " : direction extérieure unitaire")
						if copie == "droite" then
							U.verifier(p.X > -1e-6, id .. " : la copie droite est du côté +X")
						elseif copie == "gauche" then
							U.verifier(p.X < 1e-6, id .. " : la copie gauche est du côté −X")
						end
					end
				end
			end
		end
	end
end

-- Les coutures de côté du devant et du dos se rejoignent (écart < 0,05 dm)
local function bordsJoints(idDevant, idDos, mesures)
	local cD = Catalogue.piece(idDevant).contour
	local cA = Catalogue.piece(idDos).contour
	local b = Polygone.boite(cD)
	for k = 0, 10 do
		local y = b.minY + (b.maxY - b.minY) * k / 10
		local d0, d1 = Polygone.etendueLigne(cD, y)
		local a0, a1 = Polygone.etendueLigne(cA, y)
		local pD1 = Patron.point(idDevant, "unique", d1, y, mesures)
		local pA0 = Patron.point(idDos, "unique", a0, y, mesures)
		local pD0 = Patron.point(idDevant, "unique", d0, y, mesures)
		local pA1 = Patron.point(idDos, "unique", a1, y, mesures)
		if (pD1 - pA0).Magnitude > 0.05 or (pD0 - pA1).Magnitude > 0.05 then
			return false
		end
	end
	return true
end
for _, taille in pairs(Catalogue.TAILLES) do
	for _, j in ipairs(Catalogue.variantesDe("jupe")) do
		U.verifier(bordsJoints(j.pieces[1], j.pieces[2], taille), j.id .. " : coutures de côté jointives")
	end
	for _, c in ipairs(Catalogue.variantesDe("corsage")) do
		U.verifier(bordsJoints(c.pieces[1], c.pieces[2], taille), c.id .. " : coutures de côté jointives")
	end
end

-- La jupe passe hors des jambes (cylindres de 0,6 dm de rayon à ±0,55 dm) sous la ligne des hanches
for _, taille in pairs(Catalogue.TAILLES) do
	for _, j in ipairs(Catalogue.variantesDe("jupe")) do
		for _, id in ipairs(j.pieces) do
			local def = Catalogue.piece(id)
			local b = Polygone.boite(def.contour)
			for k = 0, 20 do
				local y = b.minY + (b.maxY - b.minY) * k / 20
				local x0, x1 = Polygone.etendueLigne(def.contour, y)
				for l = 0, 10 do
					local p = Patron.point(id, "unique", x0 + (x1 - x0) * l / 10, y, taille)
					if p.Y <= -1.8 then
						local horizontale = math.sqrt(p.X * p.X + p.Z * p.Z)
						U.verifier(horizontale > 1.15, id .. " : la jupe ne traverse pas les jambes")
					end
				end
			end
		end
	end
end

-- La jupe recouvre le bas du corsage à la taille
local M = Catalogue.TAILLES.M
local pJupe = Patron.point("jupe_droite_devant", "unique", 2.5, 0, M)
local pCorsage = Patron.point("corsage_droit_devant", "unique", 2.4, 4.2, M)
U.verifier(U.proche(pJupe.Y, 0) and U.proche(pCorsage.Y, 0), "jupe et corsage se rejoignent à la taille")
U.verifier(pJupe.Magnitude > pCorsage.Magnitude, "la jupe passe par-dessus le corsage")

-- Les manches partent de l'épaule, au bord du corsage
local pManche = Patron.point("manche_longue", "droite", 1.6, 0, M)
U.verifier(pManche.Y > 3.5 and pManche.Y < 4.5, "le haut de la manche est à hauteur d'épaule")
local pManche2 = Patron.point("manche_longue", "gauche", 1.6, 0, M)
U.verifier(U.proche(pManche2.X, -pManche.X) and U.proche(pManche2.Y, pManche.Y), "la manche gauche est le miroir de la droite")
