local Catalogue = U.module("Catalogue")
local Polygone = U.module("Polygone")
local Patron = U.module("Patron")
local Maillage = U.module("Maillage")

local M = Catalogue.TAILLES.M

for id, def in pairs(Catalogue.Pieces) do
	for _, copie in ipairs(Patron.copies(id)) do
		local m = Maillage.piece(id, copie, M, "robe")
		local nSommets, nFaces = #m.positions, #m.faces
		U.verifier(nSommets <= 13 * 17 and nSommets == #m.normales and nSommets == #m.uvs, id .. " : sommets cohérents")
		U.verifier(nFaces >= 20, id .. " : au moins 20 triangles")
		local aireMaillage = 0
		for _, f in ipairs(m.faces) do
			for _, k in ipairs(f) do
				U.verifier(k >= 1 and k <= nSommets, id .. " : indice de sommet valide")
			end
			-- Centre du triangle dans la pièce (en coordonnées du patron)
			local a, b, c = m.patron[f[1]], m.patron[f[2]], m.patron[f[3]]
			U.verifier(Polygone.contient(def.contour, (a.x + b.x + c.x) / 3, (a.y + b.y + c.y) / 3), id .. " : triangle dans la pièce")
			aireMaillage += math.abs((b.x - a.x) * (c.y - a.y) - (c.x - a.x) * (b.y - a.y)) / 2
			-- Tourné vers l'extérieur
			local P = m.positions
			local n = (P[f[2]] - P[f[1]]):Cross(P[f[3]] - P[f[1]])
			U.verifier(n.Magnitude > 1e-9, id .. " : triangle non dégénéré")
			U.verifier(n:Dot(m.normales[f[1]] + m.normales[f[2]] + m.normales[f[3]]) > 0, id .. " : triangle tourné vers l'extérieur")
		end
		for _, uv in ipairs(m.uvs) do
			U.verifier(uv[1] >= -1e-9 and uv[1] <= 1 + 1e-9 and uv[2] >= -1e-9 and uv[2] <= 1 + 1e-9, id .. " : UV dans [0, 1]")
		end
		-- Le maillage couvre la pièce (encoches approchées : à 20 % près)
		local aire = Polygone.aire(def.contour)
		U.verifier(math.abs(aireMaillage - aire) / aire < 0.2, ("%s : couverture %.0f %%"):format(id, 100 * aireMaillage / aire))
	end
end

-- Le décolleté en V retire des triangles ; aucun triangle au fond du V
local v = Maillage.piece("corsage_v_devant", "unique", M, "robe")
local droit = Maillage.piece("corsage_droit_devant", "unique", M, "robe")
U.verifier(#v.faces < #droit.faces, "le décolleté en V retire des triangles")
for _, f in ipairs(v.faces) do
	local a, b, c = v.patron[f[1]], v.patron[f[2]], v.patron[f[3]]
	local cx, cy = (a.x + b.x + c.x) / 3, (a.y + b.y + c.y) / 3
	U.verifier(not (cy < 1.5 and math.abs(cx - 2.4) < 0.5), "aucun triangle dans le V")
end

-- Finesse de vitrine : moins de sommets
local fin, grossier = Maillage.piece("jupe_ample_devant", "unique", M, "robe"), Maillage.piece("jupe_ample_devant", "unique", M, "vitrine")
U.verifier(#grossier.positions < #fin.positions and #grossier.positions <= 7 * 9, "la vitrine a un maillage plus léger")
U.verifier(not pcall(Maillage.piece, "jupe_ample_devant", "unique", M, "ultra"), "finesse inconnue refusée")

-- Boîte englobante
local centre, taille = Maillage.boite(fin)
U.verifier(taille.X > 0 and taille.Y > 0 and taille.Z > 0, "boîte de taille positive")
U.verifier(centre.Y < 0, "une jupe est sous la taille")
