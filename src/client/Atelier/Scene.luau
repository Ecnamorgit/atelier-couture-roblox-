-- Scene : le coin de l'atelier en 3D, côté client. Le mannequin aux mesures de la cliente, les pièces
-- épinglées dessus (le vrai tissu découpé), l'aperçu des décorations, la vitrine de la dernière robe
-- livrée, et la caméra fixe des postes autour du mannequin (qui peut tourner pendant les décorations).
-- Au plan 4, la boutique construite par le serveur donnera l'emplacement du mannequin et de la vitrine.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local Couture = ReplicatedStorage:WaitForChild("Couture")
local Catalogue = require(Couture:WaitForChild("Catalogue"))
local Patron = require(Couture:WaitForChild("Patron"))
local Mannequin = require(Couture:WaitForChild("Mannequin"))
local ConstructeurRobe = require(Couture:WaitForChild("ConstructeurRobe"))
local Recette = require(Couture:WaitForChild("Recette"))
local Vitrines = require(Couture:WaitForChild("Vitrines"))

local Scene = {}
Scene.__index = Scene

-- Taille du mannequin dans le monde (studs) ; le devant du corps regarde vers −Z
Scene.CADRE = CFrame.new(0, Mannequin.HAUTEUR_TAILLE * Catalogue.STUDS_PAR_DM, 40)
-- Caméra face au mannequin, décalée pour le laisser à gauche de l'écran (le panneau est à droite)
Scene.CAMERA = CFrame.lookAt(Vector3.new(-1.1, 2.6, 34.6), Vector3.new(-1.1, 2.2, 40))
-- Étapes où la caméra montre le mannequin
Scene.POSTES = { epinglage = true, couture = true, decorations = true, photo = true, refus = true }
-- Socle de la vitrine (la dernière robe livrée), en retrait du mannequin de travail
Scene.VITRINE = CFrame.new(7, 0.5, 52)

-- Commandes de l'avatar (clavier, stick tactile) : coupées pendant les postes, pour que toucher ou
-- glisser sur la scène ne fasse pas marcher l'avatar. Passe par le PlayerModule de Roblox.
local function controlesDuJoueur(actif)
	local joueur = Players.LocalPlayer
	local scripts = joueur and joueur:FindFirstChild("PlayerScripts")
	local module = scripts and scripts:FindFirstChild("PlayerModule")
	if not module then
		return
	end
	local ok, playerModule = pcall(require, module)
	if ok and type(playerModule) == "table" and playerModule.GetControls then
		local controles = playerModule:GetControls()
		if actif then
			controles:Enable()
		else
			controles:Disable()
		end
	end
end

-- options : { etaler = bool } pour la construction de la vitrine (défaut vrai),
-- { controles = function(actif) } pour remplacer la coupure des commandes de l'avatar (tests)
function Scene.nouvelle(parent, options)
	local dossier = Instance.new("Folder")
	dossier.Name = "AtelierLocal"
	local robe = Instance.new("Model")
	robe.Name = "Robe"
	robe.Parent = dossier
	local decorations = Instance.new("Folder")
	decorations.Name = "Decorations"
	decorations.Parent = dossier
	local vitrines = Instance.new("Folder")
	vitrines.Name = "Vitrines"
	vitrines.Parent = dossier
	local socle = Instance.new("Part")
	socle.Name = "Socle"
	socle.Anchored = true
	socle.Size = Vector3.new(4, 1, 4)
	socle.CFrame = Scene.VITRINE
	socle.Material = Enum.Material.Wood
	socle.Color = Color3.fromRGB(120, 84, 56)
	socle.Parent = vitrines
	dossier.Parent = parent or Workspace
	local self = setmetatable({
		dossier = dossier,
		robe = robe,
		decorations = decorations,
		socle = socle,
		mesures = nil,
		mannequin = nil,
		recette = nil,
		pieces = {},
		cameraFixe = false,
		ouverte = true,
		orbite = 0, -- degrés autour du mannequin (décorations)
		controles = options and options.controles or controlesDuJoueur,
	}, Scene)
	self.vitrines = Vitrines.nouveau(vitrines, function()
		local camera = Workspace.CurrentCamera
		return camera and camera.CFrame.Position or Scene.VITRINE.Position
	end, { etaler = not options or options.etaler ~= false })
	return self
end

local function memesMesures(a, b)
	return a and b and a.poitrine == b.poitrine and a.taille == b.taille and a.hanches == b.hanches
end

-- Met la scène d'accord avec l'état de l'atelier. Peut attendre (création des maillages) :
-- l'appeler dans une tâche à part pour ne pas bloquer l'interface.
function Scene:synchroniser(etat)
	-- Mannequin aux mesures de la cliente
	local mesures = etat.commande and etat.commande.mesures
	if not memesMesures(mesures, self.mesures) then
		if self.mannequin then
			self.mannequin:Destroy()
			self.mannequin = nil
		end
		self.mesures = mesures and table.clone(mesures)
		if mesures then
			self.mannequin = Mannequin.construire(mesures, Scene.CADRE, self.dossier)
		end
	end
	-- Vitrine : la dernière robe livrée
	local derniere = etat.robes and etat.robes[1]
	local texte = derniere and Recette.encoder(derniere) or nil
	if self.socle:GetAttribute("Recette") ~= texte then
		self.socle:SetAttribute("Recette", texte)
	end
	-- Pièces épinglées
	local recette = etat:recette()
	self.recette = recette
	local voulues = {}
	if recette then
		for _, p in ipairs(recette.pieces) do
			if etat.epinglees[p.id] then
				voulues[p.id] = p
			end
		end
	end
	for id, entree in pairs(self.pieces) do
		if not voulues[id] or entree.mesures ~= self.mesures then
			for _, part in ipairs(entree.parts) do
				part:Destroy()
			end
			self.pieces[id] = nil
		end
	end
	if etat.etape ~= "decorations" then
		self.orbite = 0
	end
	-- Décorations : l'écran des décorations montre la liste qu'il édite ; ailleurs, celles de la recette
	if etat.etape == "photo" or etat.etape == "refus" then
		self:montrerDecorations(recette, recette.accessoires, nil)
	elseif etat.etape ~= "decorations" then
		self:montrerDecorations(nil, {}, nil)
	end
	self:regarder(self.ouverte and Scene.POSTES[etat.etape] == true)
	if not recette then
		return
	end
	for _, p in ipairs(recette.pieces) do
		if voulues[p.id] and not self.pieces[p.id] then
			local entree = { parts = {}, mesures = self.mesures }
			self.pieces[p.id] = entree
			for _, copie in ipairs(Patron.copies(p.id)) do
				local part = ConstructeurRobe.piece(p, copie, recette.mesures, Scene.CADRE, "robe")
				if part and self.pieces[p.id] == entree and self.dossier.Parent then
					part.CanQuery = true -- touchée par les rayons des décorations
					part.Parent = self.robe
					table.insert(entree.parts, part)
				elseif part then
					part:Destroy() -- la pièce a été retirée pendant sa construction
				end
			end
		end
	end
end

-- Aperçu des décorations : la liste (format de la recette) et la garniture en cours ; chaque décoration
-- posée garde sa place dans la liste (attribut « Indice ») pour être sélectionnée au toucher.
-- selection (facultatif) : indice de la décoration sélectionnée, surlignée
function Scene:montrerDecorations(recette, liste, garniture, selection)
	self.decorations:ClearAllChildren()
	if not recette then
		return
	end
	local r = table.clone(recette)
	r.accessoires = liste
	local function poser(a, indice)
		local groupe = ConstructeurRobe.accessoire(r, a, Scene.CADRE, self.decorations)
		groupe:SetAttribute("Indice", indice)
		if indice ~= nil and indice == selection then
			local surlignage = Instance.new("Highlight")
			surlignage.Name = "Selection"
			surlignage.FillTransparency = 1
			surlignage.OutlineColor = Color3.fromRGB(255, 220, 60)
			surlignage.Parent = groupe
		end
		for _, d in ipairs(groupe:GetDescendants()) do
			if d:IsA("BasePart") then
				d.CanQuery = true
			end
		end
	end
	for i, a in ipairs(liste) do
		poser(a, i)
	end
	if garniture and #garniture.trajet >= 2 then
		poser(garniture, nil)
	end
end

-- Ce que touche un rayon (repère du monde) : une décoration { genre = "decoration", indice },
-- une pièce de la robe { genre = "piece", indicePiece, copie, u, v }, ou nil
function Scene:toucher(origine, direction)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = { self.robe, self.decorations }
	local impact = Workspace:Raycast(origine, direction, params)
	local i = impact and impact.Instance
	while i and i.Parent ~= self.decorations and i.Parent ~= self.robe do
		i = i.Parent
	end
	if not i then
		return nil
	end
	if i.Parent == self.decorations then
		local indice = i:GetAttribute("Indice")
		return indice and { genre = "decoration", indice = indice } or nil
	end
	local id, copie = i.Name:match("^Piece_(.+)_(%a+)$")
	if not id or not self.recette then
		return nil
	end
	for k, p in ipairs(self.recette.pieces) do
		if p.id == id then
			local point = Scene.CADRE:PointToObjectSpace(impact.Position) / Catalogue.STUDS_PAR_DM
			local u, v = Patron.versUV(id, copie, point, self.recette.mesures)
			return { genre = "piece", indicePiece = k, copie = copie, u = u, v = v }
		end
	end
	return nil
end

-- Tourne la caméra autour du mannequin (degrés), pendant les décorations
function Scene:orbiter(degres)
	self.orbite = (self.orbite + degres) % 360
	if self.cameraFixe then
		self:regarder(true)
	end
end

-- Fenêtre de l'atelier fermée : la caméra revient au joueur ; rouverte : elle repart au poste
function Scene:ouvrir(ouverte, etat)
	self.ouverte = ouverte
	self:regarder(ouverte and Scene.POSTES[etat.etape] == true)
end

-- Caméra fixe sur le mannequin (actif), ou rendue au joueur
function Scene:regarder(actif)
	local camera = Workspace.CurrentCamera
	if not camera then
		return
	end
	if actif then
		camera.CameraType = Enum.CameraType.Scriptable
		if self.orbite == 0 then
			camera.CFrame = Scene.CAMERA
		else
			-- Même vue, tournée autour de l'axe vertical du mannequin
			local axe = CFrame.new(Scene.CADRE.Position)
			camera.CFrame = axe * CFrame.Angles(0, math.rad(self.orbite), 0) * axe:Inverse() * Scene.CAMERA
		end
		self.cameraFixe = true
		self.controles(false)
	elseif self.cameraFixe then
		camera.CameraType = Enum.CameraType.Custom
		self.cameraFixe = false
		self.controles(true)
	end
end

function Scene:detruire()
	self:regarder(false)
	self.vitrines.arreter()
	self.pieces = {}
	self.dossier:Destroy()
end

return Scene
