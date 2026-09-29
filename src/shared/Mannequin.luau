-- Mannequin : buste de couturière sur pied, dimensionné selon les mesures de la cliente.
-- Repère du corps (dm) comme Patron : origine au centre de la taille, Y vers le haut, devant vers −Z.
-- Le corps est un peu plus fin que les vêtements (aisance de Patron) : rien ne traverse le tissu.
local dossier = script.Parent
local Catalogue = require(dossier:WaitForChild("Catalogue"))

local Mannequin = {}

Mannequin.HAUTEUR_TAILLE = 9 -- dm entre le sol et la taille
local EX, EZ = 1.12, 0.88 -- même ellipse que Patron
local FINESSE = 0.95 -- le corps est 5 % plus fin que les tours mesurés
local CREME = { 236, 222, 200 }
local BOIS = { 120, 84, 56 }

-- Formes du mannequin : { nom, forme = "ellipsoide" | "cylindre", centre (dm), taille (dm), couleur }
-- Un cylindre est vertical : taille.Y = hauteur, taille.X = diamètre.
function Mannequin.formes(mesures)
	local rP = mesures.poitrine / (2 * math.pi) * FINESSE
	local rT = mesures.taille / (2 * math.pi) * FINESSE
	local rH = mesures.hanches / (2 * math.pi) * FINESSE
	local epaule = rP * EX + 0.25
	local bas = Mannequin.HAUTEUR_TAILLE
	-- Trois ellipsoïdes (buste, taille, bassin) : la silhouette suit aussi une taille très marquée
	return {
		{ nom = "Buste", forme = "ellipsoide", centre = Vector3.new(0, 2.4, 0), taille = Vector3.new(2 * rP * EX, 3.8, 2 * rP * EZ), couleur = CREME },
		{ nom = "Taille", forme = "ellipsoide", centre = Vector3.new(0, 0, 0), taille = Vector3.new(2 * rT * EX, 2, 2 * rT * EZ), couleur = CREME },
		{ nom = "Bassin", forme = "ellipsoide", centre = Vector3.new(0, -2, 0), taille = Vector3.new(2 * rH * EX, 3, 2 * rH * EZ), couleur = CREME },
		{ nom = "EpauleDroite", forme = "ellipsoide", centre = Vector3.new(epaule, 3.9, 0), taille = Vector3.new(0.9, 0.9, 0.9), couleur = CREME },
		{ nom = "EpauleGauche", forme = "ellipsoide", centre = Vector3.new(-epaule, 3.9, 0), taille = Vector3.new(0.9, 0.9, 0.9), couleur = CREME },
		{ nom = "Cou", forme = "cylindre", centre = Vector3.new(0, 4.55, 0), taille = Vector3.new(0.9, 0.9, 0.9), couleur = CREME },
		{ nom = "Bouton", forme = "ellipsoide", centre = Vector3.new(0, 5.15, 0), taille = Vector3.new(0.7, 0.5, 0.7), couleur = BOIS },
		{ nom = "Pied", forme = "cylindre", centre = Vector3.new(0, -(3.5 + bas) / 2, 0), taille = Vector3.new(0.4, bas - 3.5, 0.4), couleur = BOIS },
		{ nom = "Socle", forme = "cylindre", centre = Vector3.new(0, -bas + 0.15, 0), taille = Vector3.new(4, 0.3, 4), couleur = BOIS },
	}
end

-- Construit le mannequin (pièces ancrées) ; cadre = CFrame de la taille dans le monde (studs)
function Mannequin.construire(mesures, cadre, parent)
	local e = Catalogue.STUDS_PAR_DM
	local modele = Instance.new("Model")
	modele.Name = "Mannequin"
	for _, f in ipairs(Mannequin.formes(mesures)) do
		local p = Instance.new("Part")
		p.Name = f.nom
		p.Anchored = true
		p.CanCollide = f.nom == "Socle"
		p.CanTouch = false
		p.Material = Enum.Material.SmoothPlastic
		p.Color = Color3.fromRGB(f.couleur[1], f.couleur[2], f.couleur[3])
		if f.forme == "cylindre" then
			p.Shape = Enum.PartType.Cylinder -- l'axe du cylindre est X : on le couche à la verticale
			p.Size = Vector3.new(f.taille.Y, f.taille.X, f.taille.Z) * e
			p.CFrame = cadre * CFrame.new(f.centre * e) * CFrame.Angles(0, 0, math.pi / 2)
		else
			p.Size = f.taille * e
			p.CFrame = cadre * CFrame.new(f.centre * e)
			local sphere = Instance.new("SpecialMesh")
			sphere.MeshType = Enum.MeshType.Sphere
			sphere.Parent = p
		end
		p.Parent = modele
	end
	modele.Parent = parent
	return modele
end

return Mannequin
