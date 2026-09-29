local Boutiques = U.module("Boutiques")
local Boutique = U.module("Boutique")
local Scene = U.module("Scene")
local Recette = U.module("Recette")
local Catalogue = U.module("Catalogue")

local monde = M.nouvelleInstance("Folder")
monde.Name = "MondeTest"
monde.Parent = M.services.Workspace
local rue = Boutiques.nouvelles(monde)
U.verifier(monde:FindFirstChild("Rue") ~= nil and monde:FindFirstChild("Vitrines") ~= nil, "la rue et ses vitrines")
local function joueurNumero(nom, userId)
	local j = M.nouveauJoueur(nom)
	rawget(j, "__props").UserId = userId
	rawget(j, "__props").DisplayName = nom
	return j
end
local function proche(a, b)
	return (a.Position - b.Position).Magnitude < 1e-6 and a.LookVector:Dot(b.LookVector) > 1 - 1e-6
end

---------------------------------------------------------------------------
-- Attribution : un emplacement libre par joueur, 8 au plus
---------------------------------------------------------------------------
local joueurs = {}
local suite = true
for k = 1, Boutique.NOMBRE do
	joueurs[k] = joueurNumero("Couturiere" .. k, 700 + k)
	if rue:attribuer(joueurs[k]) ~= k or joueurs[k]:GetAttribute("Boutique") ~= k then
		suite = false
	end
end
U.verifier(suite, "les joueurs reçoivent les emplacements dans l'ordre, notés sur le joueur (attribut « Boutique »)")
local neuvieme = joueurNumero("Neuvieme", 709)
U.verifier(rue:attribuer(neuvieme) == nil and neuvieme:GetAttribute("Boutique") == 0, "rue pleine : pas de boutique (attribut 0)")
U.verifier(rue:attribuer(joueurs[2]) == 2, "un joueur garde sa boutique")

---------------------------------------------------------------------------
-- Construction : à son emplacement, au nom du joueur, meublée
---------------------------------------------------------------------------
local b3 = monde.Rue:FindFirstChild("Boutique_3")
U.verifier(b3 ~= nil and b3:GetAttribute("Proprietaire") == joueurs[3].UserId and proche(b3:GetPivot(), Boutique.emplacement(3)), "boutique 3 à son emplacement, à sa propriétaire")
local meubles = true
for _, nom in ipairs({ "Sol", "MurFond", "MurGauche", "MurDroit", "Vitre", "Comptoir", "Clochette", "Etagere", "TableDecoupe", "Machine", "Enseigne" }) do
	if not b3:FindFirstChild(nom) then
		meubles = false
	end
end
U.verifier(meubles, "sol, murs, vitre, comptoir et clochette, étagère, table de découpe, machine, enseigne")
local surfaceEnseigne = b3.Enseigne:FindFirstChild("SurfaceGui")
local texteEnseigne = surfaceEnseigne and surfaceEnseigne:FindFirstChild("Texte")
U.verifier(texteEnseigne ~= nil and string.find(texteEnseigne.Text, "Couturiere3", 1, true) ~= nil and texteEnseigne.TextSize >= 14, "enseigne au nom de la joueuse")
U.verifier(surfaceEnseigne.SizingMode == Enum.SurfaceGuiSizingMode.PixelsPerStud and texteEnseigne.TextScaled, "enseigne lisible : dessinée à l'échelle de la planche, le texte s'adapte à la longueur du nom")
local sol = b3.Sol
local basSol = Boutique.emplacement(3):PointToObjectSpace(sol.CFrame.Position).Y - sol.Size.Y / 2
local hautSol = basSol + sol.Size.Y
U.verifier(basSol >= -1e-6 and hautSol > 0.01 and hautSol <= 0.1, "le sol de la boutique dépasse à peine le sol du monde (deux surfaces au même niveau scintillent)")
local rouleaux = 0
for _, p in ipairs(b3:GetChildren()) do
	if p.Name:sub(1, 8) == "Rouleau_" then
		rouleaux += 1
	end
end
U.verifier(rouleaux >= 6, "des rouleaux de tissu sur l'étagère (" .. rouleaux .. ")")
local unRouleau = b3:FindFirstChild("Rouleau_" .. Catalogue.Tissus[1].id)
U.verifier(unRouleau.Shape == Enum.PartType.Cylinder and unRouleau.Size.X >= 1.5 and unRouleau.Material ~= Enum.Material.Fabric, "rouleaux assez longs (un cylindre s'allonge selon X), en matière lisse (la matière tissu assombrit trop)")

-- Rien ne gêne l'atelier : caméra du poste (même quand elle tourne), photo, cliente, entrée par la porte
local o = Boutique.emplacement(3)
local points = {
	camera = Scene.CAMERA.Position,
	photo = Scene.CAMERA_PHOTO.Position,
	mannequin = Scene.CADRE.Position,
	cliente = Scene.CLIENTE.Position + Vector3.new(0, 2, 0),
	entree = Boutique.ENTREE.Position,
}
for a = 0, 350, 10 do
	local axe = CFrame.new(Scene.CADRE.Position)
	points["orbite" .. a] = (axe * CFrame.Angles(0, math.rad(a), 0) * axe:Inverse() * Scene.CAMERA).Position
end
for z = Boutique.AVANT - 2, Boutique.ENTREE.Position.Z, 0.5 do
	points["porte" .. z] = Vector3.new(Boutique.ENTREE.Position.X, 3, z)
end
local genes = {}
for nomPoint, local_ in pairs(points) do
	local monde_ = o * local_
	for _, p in ipairs(b3:GetDescendants()) do
		if p:IsA("BasePart") and p.CanCollide and p.Name ~= "Origine" then
			local rel = p.CFrame:PointToObjectSpace(monde_)
			if math.abs(rel.X) <= p.Size.X / 2 and math.abs(rel.Y) <= p.Size.Y / 2 and math.abs(rel.Z) <= p.Size.Z / 2 then
				table.insert(genes, nomPoint .. " dans " .. p.Name)
			end
		end
	end
end
table.sort(genes)
U.verifier(#genes == 0, "rien ne gêne la caméra, la cliente ni l'entrée : " .. table.concat(genes, ", "))

---------------------------------------------------------------------------
-- Vitrine : vide, puis la dernière robe livrée
---------------------------------------------------------------------------
local vitrine = monde.Vitrines:FindFirstChild("Vitrine_3")
U.verifier(vitrine ~= nil and vitrine:IsA("BasePart") and proche(vitrine.CFrame, o * Boutique.VITRINE) and vitrine:GetAttribute("Recette") == nil, "vitrine vide, derrière la fenêtre de la boutique 3")
local robe = { version = 1, mesures = { poitrine = 8.8, taille = 7, hanches = 9.4 }, croquis = {}, pieces = {}, accessoires = {} }
rue:exposer(joueurs[3], robe)
U.verifier(vitrine:GetAttribute("Recette") == Recette.encoder(robe), "la robe livrée part en vitrine")
rue:exposer(joueurs[3], nil)
U.verifier(vitrine:GetAttribute("Recette") == nil, "vitrine vidée")
rue:exposer(neuvieme, robe) -- sans boutique : sans effet, sans erreur

---------------------------------------------------------------------------
-- Arrivée de l'avatar : à l'entrée de sa boutique
---------------------------------------------------------------------------
local avatar = M.nouvelleInstance("Model")
local racine = M.nouvelleInstance("Part")
racine.Name = "HumanoidRootPart"
racine.CFrame = CFrame.new(0, 3, 0)
racine.Parent = avatar
avatar.PrimaryPart = racine
rawget(joueurs[3], "__props").Character = avatar
rue:placer(joueurs[3])
U.verifier(proche(racine.CFrame, o * Boutique.ENTREE), "l'avatar arrive à l'entrée de sa boutique")
rue:placer(neuvieme) -- sans boutique ni avatar : sans effet, sans erreur

---------------------------------------------------------------------------
-- Départ : la boutique est retirée et l'emplacement libéré
---------------------------------------------------------------------------
rue:liberer(joueurs[3])
U.verifier(monde.Rue:FindFirstChild("Boutique_3") == nil and monde.Vitrines:FindFirstChild("Vitrine_3") == nil, "départ : boutique et vitrine retirées")
U.verifier(rue:attribuer(neuvieme) == 3 and monde.Rue.Boutique_3:GetAttribute("Proprietaire") == neuvieme.UserId, "l'emplacement libéré revient au joueur suivant")
rue:liberer(joueurNumero("Inconnue", 799)) -- sans boutique : sans effet, sans erreur
monde:Destroy()
