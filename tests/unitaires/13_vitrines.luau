local Catalogue = U.module("Catalogue")
local Recette = U.module("Recette")
local Vitrines = U.module("Vitrines")

local function recette(tissu)
	return {
		croquis = { corsage = "corsage_droit", manches = "manches_sans", col = "col_sans", jupe = "jupe_droite" },
		mesures = table.clone(Catalogue.TAILLES.S),
		pieces = {
			{ id = "corsage_droit_devant", tissu = tissu, x = 3, y = 3, angle = 0, couture = 1 },
			{ id = "corsage_droit_dos", tissu = tissu, x = 9, y = 3, angle = 0, couture = 1 },
			{ id = "jupe_droite_devant", tissu = tissu, x = 3, y = 10, angle = 0, couture = 1 },
			{ id = "jupe_droite_dos", tissu = tissu, x = 9, y = 10, angle = 0, couture = 1 },
		},
		accessoires = {},
	}
end

M.initialiser()
M.budget.images, M.budget.maillages = 64, 7
local ws = M.services.Workspace
local dossier = Instance.new("Folder")
dossier.Name = "Vitrines"
dossier.Parent = ws
local function socle(nom, x)
	local p = Instance.new("Part")
	p.Name = nom
	p.Size = Vector3.new(4, 1, 4)
	p.CFrame = CFrame.new(x, 0.5, 0)
	p.Parent = dossier
	return p
end
local proche, loin = socle("Proche", 10), socle("Loin", 200)
proche:SetAttribute("Recette", Recette.encoder(recette("lin_bleu")))
loin:SetAttribute("Recette", Recette.encoder(recette("soie_rouge")))
socle("SansRecette", 5)

local joueur = Vector3.new(0, 3, 0)
local v = Vitrines.nouveau(dossier, function()
	return joueur
end, { etaler = false })

local function robeDe(s)
	local expo = s:FindFirstChild("Exposition")
	return expo and expo:FindFirstChild("Robe")
end

-- Près du joueur : construite ; loin : rien ; socle sans recette : rien
M.avancer(0.6)
U.verifier(robeDe(proche) ~= nil, "la vitrine proche est construite")
U.verifier(proche.Exposition:FindFirstChild("Mannequin") ~= nil, "avec son mannequin")
U.verifier(robeDe(loin) == nil, "la vitrine lointaine n'est pas construite")
U.verifier(dossier.SansRecette:FindFirstChild("Exposition") == nil, "un socle sans recette reste vide")
local piece = robeDe(proche):FindFirstChild("Piece_jupe_droite_devant_unique")
U.verifier(piece.TextureContent.cliche.taille.X <= 128, "robe de vitrine en images réduites")
U.verifier(M.editables.maillages == 0 and M.editables.images == 0, "aucun objet modifiable gardé")

-- Mannequin posé sur le socle
local cadre = Vitrines.cadre(proche)
U.verifier(U.proche(cadre.Position.Y, 1 + 9 * Catalogue.STUDS_PAR_DM), "taille du mannequin à 2,7 studs au-dessus du socle")

-- Le joueur s'éloigne au-delà de 80 studs : libérée ; il revient : reconstruite
joueur = Vector3.new(100, 3, 0)
M.avancer(0.6)
U.verifier(proche:FindFirstChild("Exposition") == nil, "vitrine libérée au-delà de 80 studs")
joueur = Vector3.new(70, 3, 0) -- entre 60 et 80 : on ne construit pas encore
M.avancer(0.6)
U.verifier(proche:FindFirstChild("Exposition") == nil, "pas de construction entre 60 et 80 studs")
joueur = Vector3.new(0, 3, 0)
M.avancer(0.6)
U.verifier(robeDe(proche) ~= nil, "vitrine reconstruite au retour du joueur")

-- Nouvelle recette : la vitrine est refaite avec le nouveau tissu
proche:SetAttribute("Recette", Recette.encoder(recette("velours_noir")))
M.avancer(0.6)
local nouvelle = robeDe(proche):FindFirstChild("Piece_jupe_droite_devant_unique")
U.verifier(nouvelle ~= piece and nouvelle.Material == Enum.Material.Fabric, "vitrine refaite après changement de recette")
U.verifier(#proche:GetChildren() == 1, "l'ancienne exposition est supprimée")

-- Recette illisible ou invalide : ignorée avec un seul avertissement, sans erreur
M.avertissements = {}
proche:SetAttribute("Recette", "{pas du json")
M.avancer(0.6)
M.avancer(0.6)
U.verifier(proche:FindFirstChild("Exposition") == nil and #M.avertissements == 1, "recette illisible ignorée, un avertissement")
local triche = recette("lin_bleu")
triche.pieces[1].angle = 1e18
proche:SetAttribute("Recette", Recette.encoder(triche))
M.avancer(0.6)
U.verifier(proche:FindFirstChild("Exposition") == nil and #M.avertissements == 2, "recette invalide ignorée")

-- Socle retiré, puis arrêt : tout est libéré
proche:SetAttribute("Recette", Recette.encoder(recette("lin_bleu")))
M.avancer(0.6)
U.verifier(robeDe(proche) ~= nil, "vitrine reconstruite")
v.arreter()
U.verifier(proche:FindFirstChild("Exposition") == nil, "arrêt : vitrines libérées")
M.avancer(0.6)
U.verifier(proche:FindFirstChild("Exposition") == nil, "arrêt : plus de mise à jour")

-- Socle supprimé : l'exposition disparaît avec lui, sans erreur à la mise à jour suivante
local v2 = Vitrines.nouveau(dossier, function()
	return Vector3.new(0, 3, 0)
end, { etaler = false })
local autre = socle("Autre", 15)
autre:SetAttribute("Recette", Recette.encoder(recette("coton_blanc")))
M.avancer(0.6)
U.verifier(robeDe(autre) ~= nil, "vitrine « Autre » construite")
autre:Destroy()
M.avancer(0.6)
U.verifier(autre:FindFirstChild("Exposition") == nil, "socle supprimé : exposition libérée")
v2.arreter()
