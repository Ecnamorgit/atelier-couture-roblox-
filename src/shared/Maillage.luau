-- Maillage : quadrillage d'une pièce de patron en triangles, enroulée autour du corps.
-- Données pures (dm, repère du corps) : le client les copie ensuite dans un EditableMesh.
-- Chaque ligne du quadrillage va d'un bord à l'autre de la pièce : les bords de côté,
-- le haut et le bas suivent exactement le contour ; les encoches (décolleté) sont approchées
-- en retirant les triangles dont le centre tombe hors de la pièce.
local dossier = script.Parent
local Catalogue = require(dossier:WaitForChild("Catalogue"))
local Polygone = require(dossier:WaitForChild("Polygone"))
local Patron = require(dossier:WaitForChild("Patron"))

local Maillage = {}

Maillage.FINESSES = {
	robe = { colonnes = 12, lignes = 16 },
	vitrine = { colonnes = 6, lignes = 8 },
}

-- Retourne { positions = {Vector3}, normales = {Vector3}, uvs = { {u, v} }, patron = { {x, y} },
--            faces = { {i1, i2, i3} } } ; faces tournées vers l'extérieur.
-- uv : coordonnées dans la boîte du patron (0,0 en haut à gauche), comme l'image de Pixels.imagePiece.
function Maillage.piece(idPiece, copie, mesures, finesse)
	local def = Catalogue.piece(idPiece)
	assert(def, "pièce inconnue : " .. tostring(idPiece))
	local grille = Maillage.FINESSES[finesse or "robe"]
	assert(grille, "finesse inconnue : " .. tostring(finesse))
	local b = Polygone.boite(def.contour)
	local l, h = b.maxX - b.minX, b.maxY - b.minY
	local out = { positions = {}, normales = {}, uvs = {}, patron = {}, faces = {} }
	local indices = {}
	for j = 0, grille.lignes do
		local y = b.minY + h * j / grille.lignes
		local x0, x1 = Polygone.etendueLigne(def.contour, y)
		indices[j] = {}
		if x0 then
			for i = 0, grille.colonnes do
				local x = x0 + (x1 - x0) * i / grille.colonnes
				table.insert(out.positions, (Patron.point(idPiece, copie, x, y, mesures)))
				table.insert(out.normales, Patron.normale(idPiece, copie, x, y, mesures))
				table.insert(out.uvs, { (x - b.minX) / l, (y - b.minY) / h })
				table.insert(out.patron, { x = x, y = y })
				indices[j][i] = #out.positions
			end
		end
	end
	local function ajouter(a, c, d)
		local pa, pc, pd = out.patron[a], out.patron[c], out.patron[d]
		if not Polygone.contient(def.contour, (pa.x + pc.x + pd.x) / 3, (pa.y + pc.y + pd.y) / 3) then
			return
		end
		local P = out.positions
		local n = (P[c] - P[a]):Cross(P[d] - P[a])
		if n.Magnitude < 1e-9 then
			return -- triangle dégénéré (ligne réduite à un point)
		end
		local moyenne = out.normales[a] + out.normales[c] + out.normales[d]
		if n:Dot(moyenne) < 0 then
			c, d = d, c
		end
		table.insert(out.faces, { a, c, d })
	end
	for j = 0, grille.lignes - 1 do
		for i = 0, grille.colonnes - 1 do
			local a, bb = indices[j][i], indices[j][i + 1]
			local c, d = indices[j + 1][i], indices[j + 1][i + 1]
			if a and bb and c and d then
				ajouter(a, c, bb)
				ajouter(bb, c, d)
			end
		end
	end
	return out
end

-- Boîte englobante des positions (dm) : centre et taille
function Maillage.boite(donnees)
	local mn = Vector3.new(math.huge, math.huge, math.huge)
	local mx = Vector3.new(-math.huge, -math.huge, -math.huge)
	for _, p in ipairs(donnees.positions) do
		mn = Vector3.new(math.min(mn.X, p.X), math.min(mn.Y, p.Y), math.min(mn.Z, p.Z))
		mx = Vector3.new(math.max(mx.X, p.X), math.max(mx.Y, p.Y), math.max(mx.Z, p.Z))
	end
	return (mn + mx) / 2, mx - mn
end

return Maillage
