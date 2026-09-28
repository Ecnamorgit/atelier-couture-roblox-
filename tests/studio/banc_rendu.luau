-- Banc d'essai du rendu, à exécuter dans Roblox Studio en mode Play, côté client
-- (connecteur MCP Studio : execute_luau, datamodel « Client »). Il n'est pas lancé par tests/lancer.sh.
-- Construit, à 30 studs du point d'apparition :
--   1. une robe complète sur un mannequin (mesure du temps de génération) ;
--   2. un devant de jupe avec une image d'essai : moitié u < 0,5 rouge, quart du haut bleu,
--      et une bille verte au point (0,3 ; 0,3) du patron. Attendu, vu de face : bleu en haut,
--      rouge du côté de la bille verte (à gauche). Sinon, l'image est retournée ou en miroir.
local RS = game:GetService("ReplicatedStorage"):WaitForChild("Couture")
local Catalogue = require(RS.Catalogue)
local Patron = require(RS.Patron)
local Maillage = require(RS.Maillage)
local Mannequin = require(RS.Mannequin)
local Editables = require(RS.Editables)
local ConstructeurRobe = require(RS.ConstructeurRobe)

local e = Catalogue.STUDS_PAR_DM
local ancien = workspace:FindFirstChild("BancRendu")
if ancien then
	ancien:Destroy()
end
local banc = Instance.new("Folder")
banc.Name = "BancRendu"
banc.Parent = workspace
local function cadreAuSol(x, z)
	return CFrame.new(x, 0, z) * CFrame.Angles(0, math.pi, 0) * CFrame.new(0, Mannequin.HAUTEUR_TAILLE * e, 0)
end

-- 1. Robe complète
local recette = {
	croquis = { corsage = "corsage_v", manches = "manches_ballon", col = "col_claudine", jupe = "jupe_trapeze" },
	mesures = table.clone(Catalogue.TAILLES.M),
	pieces = {
		{ id = "corsage_v_devant", tissu = "soie_rose_fleurs", x = 3.2, y = 2.5, angle = 0, couture = 0.92 },
		{ id = "corsage_droit_dos", tissu = "soie_rose_fleurs", x = 9.1, y = 2.5, angle = 0, couture = 1 },
		{ id = "manche_ballon", tissu = "satin_rose", x = 2, y = 7, angle = 0, couture = 0.5 },
		{ id = "col_claudine", tissu = "coton_blanc", x = 2, y = 9, angle = 0, couture = 1 },
		{ id = "jupe_trapeze_devant", tissu = "soie_rose_fleurs", x = 3.5, y = 12, angle = 45, couture = 0.75 },
		{ id = "jupe_trapeze_dos", tissu = "soie_rose_fleurs", x = 10, y = 12, angle = 45, couture = 0.8 },
	},
	accessoires = {
		{ id = "noeud_satin", piece = 1, u = 0.5, v = 0.95, echelle = 1.2, angle = 0 },
		{ id = "bouton_nacre", piece = 1, u = 0.5, v = 0.6, echelle = 1, angle = 0 },
		{ id = "fleur_blanche", piece = 5, u = 0.3, v = 0.5, echelle = 1, angle = 0 },
		{ id = "dentelle_blanche", piece = 5, trajet = { { u = 0, v = 1 }, { u = 0.5, v = 1 }, { u = 1, v = 1 } } },
	},
}
local cadre = cadreAuSol(30, -34)
Mannequin.construire(recette.mesures, cadre, banc)
local t0 = os.clock()
local robe = ConstructeurRobe.construire(recette, cadre, banc, { finesse = "robe", etaler = false })
local robeMs = (os.clock() - t0) * 1000
local pieces = 0
for _, c in ipairs(robe:GetChildren()) do
	if c:IsA("MeshPart") then
		pieces += 1
	end
end
t0 = os.clock()
ConstructeurRobe.construire(recette, cadreAuSol(40, -34), banc, { finesse = "vitrine", etaler = false })
local vitrineMs = (os.clock() - t0) * 1000

-- 2. Test d'orientation de l'image
local cadre2 = cadreAuSol(36, -34)
Mannequin.construire(recette.mesures, cadre2, banc)
local em, centre = Editables.maillage(Maillage.piece("jupe_droite_devant", "unique", recette.mesures, "robe"), e)
local contenu = Editables.figer(em)
em:Destroy()
local part = Editables.piece(contenu)
local L, H = 64, 64
local buf = buffer.create(L * H * 4)
for j = 0, H - 1 do
	for i = 0, L - 1 do
		local r, g, b = 240, 240, 240
		if i < L / 2 then
			r, g, b = 220, 30, 30
		end
		if j < H / 4 then
			r, g, b = 30, 60, 220
		end
		buffer.writeu32(buf, (j * L + i) * 4, r + g * 256 + b * 65536 + 255 * 16777216)
	end
end
local image = Editables.image(buf, L, H)
part.TextureContent = Editables.figer(image)
image:Destroy()
part.Anchored = true
part.CFrame = cadre2 * CFrame.new(centre)
part.Name = "TestOrientation"
part.Parent = banc
local bille = Instance.new("Part")
bille.Shape = Enum.PartType.Ball
bille.Size = Vector3.new(0.15, 0.15, 0.15)
bille.Anchored = true
bille.Material = Enum.Material.Neon
bille.Color = Color3.new(0, 1, 0)
bille.CFrame = cadre2 * CFrame.new(Patron.point("jupe_droite_devant", "unique", 0.3, 0.3, recette.mesures) * e)
bille.Parent = banc

return ("robeMs=%.0f pieces=%d vitrineMs=%.0f"):format(robeMs, pieces, vitrineMs)
