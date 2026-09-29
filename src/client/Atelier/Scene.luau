-- Scene : l'atelier en 3D, côté client, dans la boutique du joueur. La cliente en personne, le mannequin à
-- ses mesures, les pièces épinglées dessus (le vrai tissu découpé), l'aperçu des décorations, les réglages
-- de la photo, et la caméra fixe des postes autour du mannequin (qui peut tourner pendant les décorations).
-- Les positions ci-dessous sont dans le repère de la boutique (module Boutique) ; la scène les place à
-- l'origine de la boutique du joueur. Les vitrines de la rue sont posées par le serveur.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Couture = ReplicatedStorage:WaitForChild("Couture")
local Catalogue = require(Couture:WaitForChild("Catalogue"))
local Patron = require(Couture:WaitForChild("Patron"))
local Mannequin = require(Couture:WaitForChild("Mannequin"))
local ConstructeurRobe = require(Couture:WaitForChild("ConstructeurRobe"))
local Boutique = require(Couture:WaitForChild("Boutique"))
local Lighting = game:GetService("Lighting")
local Cliente = require(script.Parent:WaitForChild("Cliente"))

local Scene = {}
Scene.__index = Scene

-- Taille du mannequin (repère de la boutique, studs) ; le devant du corps regarde vers −Z
Scene.CADRE = Boutique.MANNEQUIN
-- Caméra face au mannequin, décalée pour le laisser à gauche de l'écran (le panneau est à droite)
Scene.CAMERA = CFrame.lookAt(Vector3.new(-1.1, 2.6, 34.6), Vector3.new(-1.1, 2.2, 40))
-- Étapes où la caméra montre le mannequin
Scene.POSTES = { epinglage = true, couture = true, decorations = true, photo = true, refus = true }
-- La cliente attend en retrait à côté du mannequin (à gauche à l'écran), tournée vers la caméra ; pieds au sol
Scene.CLIENTE = CFrame.lookAt(Vector3.new(4.6, 0, 42), Vector3.new(-1.1, 0, 34.6))
Scene.DUREE_ADIEU = 3 -- secondes avant qu'elle s'en aille, une fois la commande finie
Scene.PRES_CLIENTE = 3.5 -- studs : la vue qui tourne passe près d'elle, elle s'efface pour ne pas boucher la vue
Scene.PERIODE_AVATARS = 0.2 -- secondes entre deux regards sur les visiteurs, pendant la caméra du poste
Scene.ESSAI_PIECE = 3 -- secondes : une pièce ratée faute de mémoire est réessayée, sans attendre une action
Scene.PAROLES = {
	carnet = "Bonjour ! J'aurais besoin d'une robe.",
	photo = "Voyons voir…",
	refus = "Ce n'est pas tout à fait ce que je voulais.",
	merci = "Merci, elle est parfaite !",
	abandon = "Tant pis… Au revoir.",
}

-- Réglages de la photo
local function rgb(r, g, b)
	return Color3.fromRGB(r, g, b)
end
Scene.DECORS = { rose = rgb(250, 222, 232), bleu = rgb(196, 214, 240), creme = rgb(245, 236, 216), nuit = rgb(38, 38, 58) }
Scene.LUMIERES = {
	jour = { Ambient = rgb(70, 70, 70), OutdoorAmbient = rgb(128, 128, 128), Brightness = 2, ClockTime = 14, ExposureCompensation = 0 },
	doux = { Ambient = rgb(110, 100, 110), OutdoorAmbient = rgb(150, 140, 150), Brightness = 1.5, ClockTime = 16.5, ExposureCompensation = 0.2 },
	soir = { Ambient = rgb(90, 70, 90), OutdoorAmbient = rgb(110, 80, 100), Brightness = 1, ClockTime = 18.3, ExposureCompensation = 0.3 },
}
Scene.MANNEQUINS = { creme = rgb(236, 222, 200), noir = rgb(40, 36, 40), bois = rgb(150, 110, 75) }
local CORPS_MANNEQUIN = { Buste = true, Taille = true, Bassin = true, EpauleDroite = true, EpauleGauche = true, Cou = true }
local PROPRIETES_LUMIERE = { "Ambient", "OutdoorAmbient", "Brightness", "ClockTime", "ExposureCompensation" }
-- Vue de la photo : face au mannequin, centrée (l'interface est cachée pendant la prise)
Scene.CAMERA_PHOTO = CFrame.lookAt(Vector3.new(0, 2.7, 34.2), Vector3.new(0, 2.2, 40))
Scene.CHAMP_PHOTO = 42 -- degrés (vertical) : du sol au cou du mannequin, la robe remplit la photo
Scene.ATTENTE_CAPTURE = 2 -- secondes : si la capture ne répond pas, l'interface revient

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

-- options : { origine = CFrame } l'origine de la boutique du joueur (défaut : l'origine du monde),
-- { etaler = bool } pour la construction des pièces (défaut vrai),
-- { controles = function(actif) } pour remplacer la coupure des commandes de l'avatar (tests)
function Scene.nouvelle(parent, options)
	local origine = options and options.origine or CFrame.new()
	local dossier = Instance.new("Folder")
	dossier.Name = "AtelierLocal"
	local robe = Instance.new("Model")
	robe.Name = "Robe"
	robe.Parent = dossier
	local decorations = Instance.new("Folder")
	decorations.Name = "Decorations"
	decorations.Parent = dossier
	dossier.Parent = parent or Workspace
	local self = setmetatable({
		dossier = dossier,
		robe = robe,
		decorations = decorations,
		origine = origine,
		cadre = origine * Scene.CADRE, -- le cadre de la robe, dans le monde
		mesures = nil,
		mannequin = nil,
		recette = nil,
		pieces = {},
		cameraFixe = false,
		ouverte = true,
		orbite = 0, -- degrés autour du mannequin (décorations)
		cliente = nil, -- la cliente de la commande en cours
		clienteCommande = nil, -- la commande pour laquelle elle est venue
		partante = nil, -- la cliente précédente, qui salue avant de partir
		lumiereOrigine = nil, -- lumière du jeu, gardée pendant la photo
		couleursMannequin = nil, -- couleurs du mannequin, gardées pendant la photo
		champOrigine = nil, -- champ de la caméra, gardé le temps de la prise de vue
		controles = options and options.controles or controlesDuJoueur,
	}, Scene)
	-- Les visiteurs vont et viennent : on les regarde régulièrement pendant la caméra du poste
	local cumul = 0
	self.connexionAvatars = RunService.RenderStepped:Connect(function(dt)
		cumul += dt
		if cumul >= Scene.PERIODE_AVATARS then
			cumul = 0
			if self.cameraFixe then
				self:effacerAvatars()
			end
		end
	end)
	return self
end

local function memesMesures(a, b)
	return a and b and a.poitrine == b.poitrine and a.taille == b.taille and a.hanches == b.hanches
end

-- La cliente en personne : elle entre avec la commande, parle selon l'étape, salue puis s'en va
function Scene:suivreCliente(etat, derniere)
	local commande = etat.commande
	if commande and self.clienteCommande ~= commande then
		-- Notée avant la construction, qui attend Roblox : une synchronisation pendant ce temps ne la refait pas
		self.clienteCommande = commande
		if self.cliente then
			self.cliente:Destroy()
			self.cliente = nil
		end
		if self.partante then
			self.partante:Destroy() -- la précédente part tout de suite
			self.partante = nil
		end
		local modele = Cliente.construire(commande, self.origine * Scene.CLIENTE, self.dossier)
		if self.clienteCommande ~= commande then
			-- La commande a pris fin (ou changé) pendant la construction
			if modele then
				modele:Destroy()
			end
			return
		end
		self.cliente = modele
	end
	if commande then
		Cliente.dire(self.cliente, Scene.PAROLES[etat.etape])
	elseif self.cliente then
		local reussie = derniere and derniere.action == "livrer" and derniere.reponse.reussie
		Cliente.dire(self.cliente, reussie and Scene.PAROLES.merci or Scene.PAROLES.abandon)
		local partante = self.cliente
		self.partante, self.cliente, self.clienteCommande = partante, nil, nil
		task.delay(Scene.DUREE_ADIEU, function()
			partante:Destroy()
			if self.partante == partante then
				self.partante = nil
			end
		end)
	else
		self.clienteCommande = nil -- pas de commande, personne (ou avatar encore en construction)
	end
end

-- Photo : décor derrière le mannequin, lumière, couleur du mannequin (réglages = { decor, lumiere, mannequin })
function Scene:photo(reglages)
	if not self.lumiereOrigine then
		self.lumiereOrigine = {}
		for _, nom in ipairs(PROPRIETES_LUMIERE) do
			self.lumiereOrigine[nom] = Lighting[nom]
		end
	end
	local fond = self.dossier:FindFirstChild("Fond")
	if not fond then
		fond = Instance.new("Part")
		fond.Name = "Fond"
		fond.Anchored = true
		fond.CanCollide = false
		fond.CanQuery = false
		fond.CanTouch = false
		fond.Material = Enum.Material.SmoothPlastic
		fond.Size = Vector3.new(16, 12, 0.4)
		fond.CFrame = self.origine * CFrame.new(Scene.CADRE.Position.X, 5, Scene.CADRE.Position.Z + 3.5)
		fond.Parent = self.dossier
	end
	fond.Color = Scene.DECORS[reglages.decor] or Scene.DECORS.creme
	for nom, valeur in pairs(Scene.LUMIERES[reglages.lumiere] or Scene.LUMIERES.jour) do
		Lighting[nom] = valeur
	end
	if self.mannequin then
		self.couleursMannequin = self.couleursMannequin or {}
		for _, p in ipairs(self.mannequin:GetChildren()) do
			if CORPS_MANNEQUIN[p.Name] then
				self.couleursMannequin[p] = self.couleursMannequin[p] or p.Color
				p.Color = Scene.MANNEQUINS[reglages.mannequin] or Scene.MANNEQUINS.creme
			end
		end
	end
end

-- Cadrage de la prise de vue (actif) : vue centrée sur la robe, bulle de la cliente cachée ;
-- sinon retour à la vue du poste
function Scene:cadrerPhoto(actif)
	local bulle = self.cliente and self.cliente:FindFirstChild("Head") and self.cliente.Head:FindFirstChild("Bulle")
	if bulle then
		bulle.Enabled = not actif
	end
	local camera = Workspace.CurrentCamera
	if actif and camera then
		self.champOrigine = self.champOrigine or camera.FieldOfView
		camera.CameraType = Enum.CameraType.Scriptable
		camera.CFrame = self.origine * Scene.CAMERA_PHOTO
		camera.FieldOfView = Scene.CHAMP_PHOTO
	else
		if camera and self.champOrigine then
			camera.FieldOfView = self.champOrigine
			self.champOrigine = nil
		end
		self:regarder(true)
	end
end

-- Fin de la photo : décor retiré, lumière du jeu et couleur du mannequin rétablies
function Scene:finirPhoto()
	local fond = self.dossier:FindFirstChild("Fond")
	if fond then
		fond:Destroy()
	end
	if self.lumiereOrigine then
		for nom, valeur in pairs(self.lumiereOrigine) do
			Lighting[nom] = valeur
		end
		self.lumiereOrigine = nil
	end
	if self.couleursMannequin then
		for p, couleur in pairs(self.couleursMannequin) do
			p.Color = couleur
		end
		self.couleursMannequin = nil
	end
end

-- Met la scène d'accord avec l'état de l'atelier (derniere = dernière action réussie de la session).
-- Peut attendre (création des maillages) : l'appeler dans une tâche à part pour ne pas bloquer l'interface.
function Scene:synchroniser(etat, derniere)
	self.etatSuivi, self.derniereSuivie = etat, derniere -- pour réessayer une pièce ratée
	self:suivreCliente(etat, derniere)
	if etat.etape ~= "photo" then
		self:finirPhoto()
	end
	-- Mannequin aux mesures de la cliente
	local mesures = etat.commande and etat.commande.mesures
	if not memesMesures(mesures, self.mesures) then
		if self.mannequin then
			self:finirPhoto()
			self.mannequin:Destroy()
			self.mannequin = nil
		end
		self.mesures = mesures and table.clone(mesures)
		if mesures then
			self.mannequin = Mannequin.construire(mesures, self.cadre, self.dossier)
		end
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
			local ratee = false
			for _, copie in ipairs(Patron.copies(p.id)) do
				local part = ConstructeurRobe.piece(p, copie, recette.mesures, self.cadre, "robe")
				if part and self.pieces[p.id] == entree and self.dossier.Parent then
					part.CanQuery = true -- touchée par les rayons des décorations
					part.Parent = self.robe
					table.insert(entree.parts, part)
				elseif part then
					part:Destroy() -- la pièce a été retirée pendant sa construction
				else
					ratee = true -- mémoire des maillages pleine
				end
			end
			-- Pièce ratée : oubliée, et réessayée quelques secondes plus tard (une synchronisation en attente à
			-- la fois ; entre-temps, une action du joueur la réessaie aussi)
			if ratee and self.pieces[p.id] == entree then
				for _, part in ipairs(entree.parts) do
					part:Destroy()
				end
				self.pieces[p.id] = nil
				if not self.reessai then
					self.reessai = true
					task.delay(Scene.ESSAI_PIECE, function()
						self.reessai = false
						if self.dossier.Parent then
							self:synchroniser(self.etatSuivi, self.derniereSuivie)
						end
					end)
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
		local groupe = ConstructeurRobe.accessoire(r, a, self.cadre, self.decorations)
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
			local point = self.cadre:PointToObjectSpace(impact.Position) / Catalogue.STUDS_PAR_DM
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
		local vue = self.origine * Scene.CAMERA
		if self.orbite == 0 then
			camera.CFrame = vue
		else
			-- Même vue, tournée autour de l'axe vertical du mannequin
			local axe = CFrame.new(self.cadre.Position)
			camera.CFrame = axe * CFrame.Angles(0, math.rad(self.orbite), 0) * axe:Inverse() * vue
		end
		self.cameraFixe = true
		self.controles(false)
	elseif self.cameraFixe then
		camera.CameraType = Enum.CameraType.Custom
		self.cameraFixe = false
		self.controles(true)
	end
	self:effacerCliente()
	self:effacerAvatars()
end

-- La caméra du poste tout près de la cliente (vue qui tourne pendant les décorations) : elle s'efface,
-- comme l'avatar du joueur quand la caméra s'en approche ; visible sinon
function Scene:effacerCliente()
	local camera = Workspace.CurrentCamera
	local racine = self.cliente and self.cliente:FindFirstChild("HumanoidRootPart")
	if not racine then
		return
	end
	local proche = self.cameraFixe and camera ~= nil
		and (camera.CFrame.Position - racine.CFrame.Position).Magnitude < Scene.PRES_CLIENTE
	for _, d in ipairs(self.cliente:GetDescendants()) do
		if d:IsA("BasePart") then
			d.LocalTransparencyModifier = proche and 1 or 0
		end
	end
end

-- Pendant la caméra du poste, les autres joueurs entrés dans la boutique sont effacés (pour ce joueur
-- seulement) : ils cacheraient la robe et entreraient dans la photo. L'avatar du joueur est laissé à Roblox,
-- dont les caméras règlent sa transparence.
function Scene:effacerAvatars()
	local moi = Players.LocalPlayer
	for _, j in ipairs(Players:GetPlayers()) do
		local avatar = j ~= moi and j.Character
		local racine = avatar and avatar:FindFirstChild("HumanoidRootPart")
		if racine then
			local p = self.origine:PointToObjectSpace(racine.CFrame.Position)
			local dedans = math.abs(p.X) <= Boutique.LARGEUR / 2 + 1 and p.Z >= Boutique.AVANT - 1 and p.Z <= Boutique.FOND + 1
			for _, d in ipairs(avatar:GetDescendants()) do
				if d:IsA("BasePart") then
					d.LocalTransparencyModifier = if self.cameraFixe and dedans then 1 else 0
				end
			end
		end
	end
end

function Scene:detruire()
	self:finirPhoto()
	self:regarder(false)
	self.connexionAvatars:Disconnect()
	self.pieces = {}
	self.dossier:Destroy()
end

return Scene
