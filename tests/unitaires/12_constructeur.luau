local Catalogue = U.module("Catalogue")
local Patron = U.module("Patron")
local Maillage = U.module("Maillage")
local ConstructeurRobe = U.module("ConstructeurRobe")

local function exemple()
	return {
		croquis = { corsage = "corsage_v", manches = "manches_ballon", col = "col_sans", jupe = "jupe_trapeze" },
		mesures = table.clone(Catalogue.TAILLES.M),
		pieces = {
			{ id = "corsage_v_devant", tissu = "soie_rose_fleurs", x = 3.2, y = 2.5, angle = 45, couture = 0.92 },
			{ id = "corsage_droit_dos", tissu = "soie_rose_fleurs", x = 9.1, y = 2.5, angle = 0, couture = 1 },
			{ id = "manche_ballon", tissu = "satin_rose", x = 2, y = 7, angle = -90, couture = 0.5 },
			{ id = "jupe_trapeze_devant", tissu = "coton_blanc", x = 3.5, y = 12, angle = 0, couture = 0.75 },
			{ id = "jupe_trapeze_dos", tissu = "coton_blanc", x = 10, y = 12, angle = 180, couture = 0.8 },
		},
		accessoires = {
			{ id = "noeud_satin", piece = 1, u = 0.5, v = 0.9, echelle = 1.2, angle = 15 },
			{ id = "bouton_nacre", piece = 3, copie = "droite", u = 0.3, v = 0.4, echelle = 1, angle = 0 },
			{ id = "dentelle_blanche", piece = 4, trajet = { { u = 0, v = 1 }, { u = 0.5, v = 1 }, { u = 1, v = 1 } } },
		},
	}
end

M.initialiser()
M.budget.images, M.budget.maillages = 64, 7
M.editables.maxImages, M.editables.maxMaillages = 0, 0
local e = Catalogue.STUDS_PAR_DM
local cadre = CFrame.new(0, 3, -10)
local progres = {}
local robe = ConstructeurRobe.construire(exemple(), cadre, M.services.Workspace, {
	surProgres = function(fait, total)
		table.insert(progres, { fait, total })
	end,
})

-- 6 pièces (la manche ballon est coupée pliée : deux copies) et 3 accessoires
local pieces, accessoires = {}, {}
for _, enfant in ipairs(robe:GetChildren()) do
	if enfant.ClassName == "MeshPart" then
		pieces[enfant.Name] = enfant
	elseif enfant.Name:sub(1, 11) == "Accessoire_" then
		table.insert(accessoires, enfant)
	end
end
local noms = {}
for nom in pairs(pieces) do
	table.insert(noms, nom)
end
U.verifier(#noms == 6, "6 pièces de tissu (obtenu " .. #noms .. ")")
U.verifier(pieces["Piece_manche_ballon_gauche"] ~= nil and pieces["Piece_manche_ballon_droite"] ~= nil, "deux manches")
U.verifier(#accessoires == 3, "3 accessoires")
U.verifier(robe.Parent == M.services.Workspace and robe.Name == "Robe", "robe rangée sous le parent donné")

-- Chaque pièce : forme et texture statiques, ancrée, sans collision, bien placée
for nom, part in pairs(pieces) do
	U.verifier(rawget(part, "__contenu").statique, nom .. " : forme issue d'un contenu statique")
	U.verifier(part.TextureContent ~= nil and part.TextureContent.statique, nom .. " : texture statique")
	U.verifier(part.Anchored and not part.CanCollide and not part.CanTouch, nom .. " : ancrée, sans collision")
end
local satin = pieces["Piece_manche_ballon_droite"]
U.verifier(satin.Material == Enum.Material.SmoothPlastic and U.proche(satin.Reflectance, 0.15), "satin : lisse et brillant")
U.verifier(pieces["Piece_jupe_trapeze_devant_unique"].Material == Enum.Material.Fabric, "coton : matière tissu")
local donnees = Maillage.piece("jupe_trapeze_devant", "unique", Catalogue.TAILLES.M, "robe")
local centre = Maillage.boite(donnees) * e
local attendu = cadre * CFrame.new(centre)
U.verifier(U.proche((pieces["Piece_jupe_trapeze_devant_unique"].CFrame.Position - attendu.Position).Magnitude, 0, 1e-9),
	"pièce placée au centre de son maillage, dans le repère de la taille")
local image = pieces["Piece_jupe_trapeze_devant_unique"].TextureContent.cliche
U.verifier(image.taille.X <= 256 and image.taille.Y <= 256, "image de robe ≤ 256 px")

-- Mémoire : jamais plus d'un maillage et d'une image modifiables vivants, rien d'oublié
U.verifier(M.editables.maxMaillages == 1 and M.editables.maxImages == 1, "un seul objet modifiable à la fois")
U.verifier(M.editables.maillages == 0 and M.editables.images == 0, "tous les objets modifiables sont détruits")

-- Progression
U.verifier(#progres == 9 and progres[9][1] == 9 and progres[9][2] == 9, "progression : 6 pièces + 3 accessoires")

-- Accessoires : le nœud est posé sur le devant du corsage
local noeud = robe:FindFirstChild("Accessoire_noeud_satin")
local pos, n = Patron.point("corsage_v_devant", "unique", 0.5 * 4.8, 0.9 * 4.2, Catalogue.TAILLES.M)
local voulu = cadre * ((pos + n * 0.05) * e)
local centreNoeud = Vector3.new(0, 0, 0)
local enfants = noeud:GetChildren()
for _, p in ipairs(enfants) do
	centreNoeud += p.CFrame.Position
end
centreNoeud /= #enfants
U.verifier((centreNoeud - voulu).Magnitude < 0.1, "nœud posé sur le corsage")
U.verifier(voulu.Z < cadre.Position.Z, "le nœud est sur le devant (−Z)")
local dentelle = robe:FindFirstChild("Accessoire_dentelle_blanche")
U.verifier(#dentelle:GetChildren() >= 10, "dentelle en ruban de plaques")
for _, plaque in ipairs(dentelle:GetChildren()) do
	U.verifier(U.proche(plaque.Transparency, 0.15), "dentelle légèrement transparente")
end

-- Vitrine : images plus petites
local vitrine = ConstructeurRobe.construire(exemple(), cadre, M.services.Workspace, { finesse = "vitrine" })
local img = vitrine:FindFirstChild("Piece_jupe_trapeze_devant_unique").TextureContent.cliche
U.verifier(img.taille.X <= 128 and img.taille.Y <= 128, "image de vitrine ≤ 128 px")

-- Mémoire des images pleine : pièces en couleur unie, un seul avertissement
M.avertissements = {}
M.budget.images = 0
local unie = ConstructeurRobe.construire(exemple(), cadre, M.services.Workspace, {})
local blanche = unie:FindFirstChild("Piece_jupe_trapeze_devant_unique")
U.verifier(blanche.TextureContent == nil and blanche.Color == Color3.fromRGB(246, 242, 234), "sans image : couleur du tissu")
U.verifier(#M.avertissements == 1, "un seul avertissement pour toute la robe")
M.budget.images = 64

-- Mémoire des maillages pleine : aucune pièce, pas d'erreur
M.budget.maillages = 0
local vide = ConstructeurRobe.construire(exemple(), cadre, M.services.Workspace, {})
local nb = 0
for _, enfant in ipairs(vide:GetChildren()) do
	if enfant.ClassName == "MeshPart" then
		nb += 1
	end
end
U.verifier(nb == 0, "sans mémoire de maillage : aucune pièce, pas d'erreur")
M.budget.maillages = 7

-- Recette invalide refusée
local mauvaise = exemple()
mauvaise.pieces[1].tissu = "papier"
U.verifier(not pcall(ConstructeurRobe.construire, mauvaise, cadre, M.services.Workspace, {}), "recette invalide refusée")

-- Accessoire là où la normale est presque verticale (dessus du col Claudine) : repère sans NaN
local col = exemple()
col.croquis.col = "col_claudine"
table.insert(col.pieces, 4, { id = "col_claudine", tissu = "coton_blanc", x = 2, y = 9, angle = 0, couture = 1 })
col.accessoires = { { id = "perle", piece = 4, copie = "droite", u = 0.5, v = 0.95, echelle = 1, angle = 30 } }
local robeCol = ConstructeurRobe.construire(col, cadre, M.services.Workspace, {})
local perle = robeCol:FindFirstChild("Accessoire_perle"):GetChildren()[1]
local p = perle.CFrame.Position
local l = perle.CFrame.LookVector
U.verifier(p.X == p.X and p.Y == p.Y and p.Z == p.Z and l.X == l.X and l.Y == l.Y and l.Z == l.Z, "perle sur le col : repère fini")

-- Relecture finale : garnitures bornées (au plus 64 plaques chacune, même en zigzag sur une longue jupe)
local zigzag = {
	croquis = { corsage = "corsage_droit", manches = "manches_sans", col = "col_sans", jupe = "jupe_evasee" },
	mesures = table.clone(Catalogue.TAILLES.M),
	pieces = {
		{ id = "corsage_droit_devant", tissu = "coton_blanc", x = 3, y = 3, angle = 0, couture = 1 },
		{ id = "corsage_droit_dos", tissu = "coton_blanc", x = 9, y = 3, angle = 0, couture = 1 },
		{ id = "jupe_evasee_devant", tissu = "coton_blanc", x = 5, y = 12, angle = 45, couture = 1 },
		{ id = "jupe_evasee_dos", tissu = "coton_blanc", x = 5, y = 30, angle = 45, couture = 1 },
	},
	accessoires = {},
}
for _ = 1, 30 do
	local trajet = {}
	for k = 1, 64 do
		table.insert(trajet, { u = k % 2, v = (k - 1) / 63 })
	end
	table.insert(zigzag.accessoires, { id = "ruban_rose", piece = 3, trajet = trajet })
end
local robeZ = ConstructeurRobe.construire(zigzag, cadre, M.services.Workspace, {})
local plaquesMax = 0
for _, enfant in ipairs(robeZ:GetChildren()) do
	if enfant.Name == "Accessoire_ruban_rose" then
		plaquesMax = math.max(plaquesMax, #enfant:GetChildren())
	end
end
U.verifier(plaquesMax > 0 and plaquesMax <= 64, ("une garniture fait au plus 64 plaques (obtenu %d)"):format(plaquesMax))

-- Relecture finale : génération étalée jusque dans les accessoires, et arrêtée si la robe est détruite
local pauses = 0
local etalee = ConstructeurRobe.construire(zigzag, cadre, M.services.Workspace, {
	etaler = true,
	pause = function()
		pauses += 1
	end,
})
U.verifier(pauses > 4 + 30, ("pauses entre les pièces et pendant les accessoires (obtenu %d)"):format(pauses))
U.verifier(#etalee:GetChildren() == 4 + 30, "robe étalée complète")
local coupee
coupee = ConstructeurRobe.construire(zigzag, cadre, M.services.Workspace, {
	etaler = true,
	pause = function()
		pauses += 1
		if coupee == nil and pauses > 0 then
			-- première pause : la robe n'est pas encore rendue, on la détruit via son parent
			for _, r in ipairs(M.services.Workspace:GetChildren()) do
				if r.Name == "Robe" and #r:GetChildren() == 1 then
					r:Destroy()
				end
			end
		end
	end,
})
U.verifier(coupee.Parent == nil and #coupee:GetChildren() == 1, "robe détruite pendant la génération : construction arrêtée")
U.verifier(M.editables.maillages == 0 and M.editables.images == 0, "aucun objet modifiable laissé par l'arrêt")
