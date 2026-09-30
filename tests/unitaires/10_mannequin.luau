local Catalogue = U.module("Catalogue")
local Polygone = U.module("Polygone")
local Patron = U.module("Patron")
local Mannequin = U.module("Mannequin")

local function dansEllipsoide(p, f)
	local a = f.taille / 2
	local d = p - f.centre
	return (d.X / a.X) ^ 2 + (d.Y / a.Y) ^ 2 + (d.Z / a.Z) ^ 2 < 1
end

-- Tailles du catalogue et silhouettes extrêmes acceptées par Recette.valider
local Recette = U.module("Recette")
local tailles = table.clone(Catalogue.TAILLES)
for _, P in ipairs({ Recette.POITRINE[1], Recette.POITRINE[2] }) do
	for _, T in ipairs({ Recette.TAILLE[1], Recette.TAILLE[2] }) do
		for _, H in ipairs({ Recette.HANCHES[1], Recette.HANCHES[2] }) do
			if T <= P and T <= H then
				tailles[("P%g-T%g-H%g"):format(P, T, H)] = { poitrine = P, taille = T, hanches = H }
			end
		end
	end
end
for nomTaille, mesures in pairs(tailles) do
	local formes = Mannequin.formes(mesures)
	for _, f in ipairs(formes) do
		U.verifier(f.taille.X > 0 and f.taille.Y > 0 and f.taille.Z > 0, f.nom .. " : taille positive")
	end
	-- Aucun point des corsages et des jupes à l'intérieur du buste, de la taille ou du bassin
	local corps = { formes[1], formes[2], formes[3] }
	for id, def in pairs(Catalogue.Pieces) do
		local t = def.enroulement.type
		if t == "corsage" or t == "jupe" then
			local b = Polygone.boite(def.contour)
			for j = 0, 12 do
				local y = math.min(b.minY + (b.maxY - b.minY) * j / 12, b.maxY) -- (l'arrondi ne sort pas de la pièce)
				local x0, x1 = Polygone.etendueLigne(def.contour, y)
				for i = 0, 8 do
					local p = Patron.point(id, "unique", x0 + (x1 - x0) * i / 8, y, mesures)
					for _, f in ipairs(corps) do
						U.verifier(not dansEllipsoide(p, f), ("%s (%s) : le %s ne traverse pas le tissu"):format(id, nomTaille, f.nom))
					end
				end
			end
		end
	end
	-- Aucun point des cols (les deux moitiés) dans le buste : le col marin retombe sur les épaules et dans le dos
	for id, def in pairs(Catalogue.Pieces) do
		if def.enroulement.type == "col" then
			local b = Polygone.boite(def.contour)
			local dedans = 0
			for _, copie in ipairs(Patron.copies(id)) do
				for j = 0, 8 do
					local y = math.min(b.minY + (b.maxY - b.minY) * j / 8, b.maxY)
					local x0, x1 = Polygone.etendueLigne(def.contour, y)
					for i = 0, 8 do
						if dansEllipsoide(Patron.point(id, copie, x0 + (x1 - x0) * i / 8, y, mesures), formes[1]) then
							dedans += 1
						end
					end
				end
			end
			U.verifier(dedans == 0, ("%s (%s) : le col ne traverse pas le buste (%d points dedans)"):format(id, nomTaille, dedans))
		end
	end
	-- Le socle touche le sol
	local socle = formes[#formes]
	U.verifier(U.proche(socle.centre.Y - socle.taille.Y / 2, -Mannequin.HAUTEUR_TAILLE), nomTaille .. " : socle posé au sol")
end

-- Construction (pièces ancrées, sphères déformées en ellipsoïdes)
M.initialiser()
local cadre = CFrame.new(10, Mannequin.HAUTEUR_TAILLE * Catalogue.STUDS_PAR_DM, 5)
local modele = Mannequin.construire(Catalogue.TAILLES.M, cadre, M.services.Workspace)
local formes = Mannequin.formes(Catalogue.TAILLES.M)
U.verifier(modele.Parent == M.services.Workspace and #modele:GetChildren() == #formes, "une pièce par forme")
for _, f in ipairs(formes) do
	local p = modele:FindFirstChild(f.nom)
	U.verifier(p ~= nil and p.Anchored, f.nom .. " : pièce ancrée")
	if f.forme == "ellipsoide" then
		U.verifier(p:FindFirstChild("SpecialMesh") ~= nil, f.nom .. " : sphère déformée")
		U.verifier(U.proche((p.Size - f.taille * Catalogue.STUDS_PAR_DM).Magnitude, 0), f.nom .. " : taille en studs")
	end
end
U.verifier(U.proche(modele.Socle.CFrame.Position.Y, 0.15 * Catalogue.STUDS_PAR_DM, 1e-6), "le socle est au niveau du sol du monde")
