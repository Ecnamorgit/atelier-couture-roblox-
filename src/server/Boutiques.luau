-- Boutiques (serveur) : la rue commune (spec §2). À son arrivée, le joueur reçoit un emplacement libre, où
-- le serveur construit sa boutique (plan : module Boutique) : murs, porte et fenêtre sur la rue, enseigne à
-- son nom, comptoir et clochette, étagère de tissus, table de découpe, machine à coudre. Derrière la
-- fenêtre, le socle de sa vitrine porte la recette de sa dernière robe livrée (attribut « Recette ») :
-- chaque client construit les robes des vitrines proches (spec §5). Au départ, tout est retiré.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Couture = ReplicatedStorage:WaitForChild("Couture")
local Catalogue = require(Couture:WaitForChild("Catalogue"))
local Recette = require(Couture:WaitForChild("Recette"))
local Boutique = require(Couture:WaitForChild("Boutique"))

local Boutiques = {}
Boutiques.__index = Boutiques

local function rgb(r, g, b)
	return Color3.fromRGB(r, g, b)
end
local MUR, SOL, BOIS, BOIS_CLAIR = rgb(236, 222, 210), rgb(170, 128, 96), rgb(120, 84, 56), rgb(196, 160, 118)

-- parent : où ranger la rue (dossier « Rue ») et les vitrines (dossier « Vitrines », lu par les clients)
function Boutiques.nouvelles(parent)
	local rue = Instance.new("Folder")
	rue.Name = "Rue"
	rue.Parent = parent
	local vitrines = Instance.new("Folder")
	vitrines.Name = "Vitrines"
	vitrines.Parent = parent
	return setmetatable({ rue = rue, vitrines = vitrines, parIndice = {}, parJoueur = {} }, Boutiques)
end

-- Un bloc de la boutique (repère local de la boutique)
local function bloc(modele, origine, nom, position, taille, couleur, options)
	options = options or {}
	local p = Instance.new("Part")
	p.Name = nom
	p.Anchored = true
	p.Size = taille
	p.CFrame = origine * CFrame.new(position)
	p.Color = couleur
	p.Material = options.matiere or Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	if options.forme then
		p.Shape = options.forme
	end
	if options.decor then -- petit objet décoratif : ni collision, ni rayon
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
	end
	if options.transparence then
		p.Transparency = options.transparence
	end
	p.Parent = modele
	return p
end

local function construire(indice, joueur, parent)
	local origine = Boutique.emplacement(indice)
	local modele = Instance.new("Model")
	modele.Name = "Boutique_" .. indice
	modele:SetAttribute("Proprietaire", joueur.UserId)
	local ancre = bloc(modele, origine, "Origine", Vector3.zero, Vector3.new(1, 1, 1), MUR, { decor = true, transparence = 1 })
	modele.PrimaryPart = ancre
	local L, A, F, H = Boutique.LARGEUR, Boutique.AVANT, Boutique.FOND, Boutique.HAUTEUR
	local P, W = Boutique.PORTE, Boutique.FENETRE
	local profondeur, milieu = F - A, (A + F) / 2
	-- Sol et murs (la façade, en z = AVANT, a une porte et une fenêtre)
	-- Le sol dépasse à peine celui du monde : deux surfaces au même niveau scintilleraient
	bloc(modele, origine, "Sol", Vector3.new(0, 0.025, milieu), Vector3.new(L, 0.05, profondeur), SOL, { matiere = Enum.Material.WoodPlanks })
	bloc(modele, origine, "MurFond", Vector3.new(0, H / 2, F + 0.5), Vector3.new(L + 2, H, 1), MUR)
	bloc(modele, origine, "MurGauche", Vector3.new(-L / 2 - 0.5, H / 2, milieu), Vector3.new(1, H, profondeur), MUR)
	bloc(modele, origine, "MurDroit", Vector3.new(L / 2 + 0.5, H / 2, milieu), Vector3.new(1, H, profondeur), MUR)
	local zF = A - 0.5
	local hautOuverture = 8
	bloc(modele, origine, "FacadeGauche", Vector3.new((-L / 2 + P[1]) / 2 - 0.5, H / 2, zF), Vector3.new(P[1] + L / 2 + 1, H, 1), MUR)
	bloc(modele, origine, "FacadeDessusPorte", Vector3.new((P[1] + P[2]) / 2, (hautOuverture + H) / 2, zF), Vector3.new(P[2] - P[1], H - hautOuverture, 1), MUR)
	bloc(modele, origine, "FacadeMilieu", Vector3.new((P[2] + W[1]) / 2, H / 2, zF), Vector3.new(W[1] - P[2], H, 1), MUR)
	bloc(modele, origine, "FacadeSousFenetre", Vector3.new((W[1] + W[2]) / 2, 0.5, zF), Vector3.new(W[2] - W[1], 1, 1), MUR)
	bloc(modele, origine, "FacadeDessusFenetre", Vector3.new((W[1] + W[2]) / 2, (hautOuverture + H) / 2, zF), Vector3.new(W[2] - W[1], H - hautOuverture, 1), MUR)
	bloc(modele, origine, "FacadeDroite", Vector3.new((W[2] + L / 2) / 2 + 0.5, H / 2, zF), Vector3.new(L / 2 - W[2] + 1, H, 1), MUR)
	bloc(modele, origine, "Vitre", Vector3.new((W[1] + W[2]) / 2, (1 + hautOuverture) / 2, zF), Vector3.new(W[2] - W[1], hautOuverture - 1, 0.2), rgb(200, 225, 240), { matiere = Enum.Material.Glass, transparence = 0.7 })
	-- Enseigne au nom du joueur, sur la façade (face à la rue)
	local enseigne = bloc(modele, origine, "Enseigne", Vector3.new(-3, 10, A - 1.2), Vector3.new(14, 2.2, 0.3), BOIS)
	local surface = Instance.new("SurfaceGui")
	surface.Face = Enum.NormalId.Front
	surface.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud -- par défaut, un canevas fixe de 800 × 600 serait écrasé sur la planche
	surface.PixelsPerStud = 40
	surface.Parent = enseigne
	local texte = Instance.new("TextLabel")
	texte.Name = "Texte"
	texte.Size = UDim2.fromScale(1, 1)
	texte.BackgroundTransparency = 1
	texte.Font = Enum.Font.GothamBold
	texte.TextSize = 48
	texte.TextScaled = true -- un long nom tient sur la planche
	texte.TextColor3 = rgb(255, 240, 220)
	local nom = (joueur.DisplayName ~= nil and joueur.DisplayName ~= "") and joueur.DisplayName or joueur.Name
	texte.Text = "Aiguille & Dentelle — " .. nom
	texte.Parent = surface
	-- Comptoir et clochette, contre le mur de gauche
	bloc(modele, origine, "Comptoir", Vector3.new(-9, 1.5, 38), Vector3.new(3, 3, 6), BOIS)
	bloc(modele, origine, "Clochette", Vector3.new(-9, 3.4, 36.5), Vector3.new(0.8, 0.8, 0.8), rgb(230, 190, 70), { forme = Enum.PartType.Ball, matiere = Enum.Material.Metal, decor = true })
	bloc(modele, origine, "BoiteAuxLettres", Boutique.BOITE_AUX_LETTRES.Position, Vector3.new(0.7, 0.8, 1), rgb(70, 110, 170), { matiere = Enum.Material.Metal, decor = true })
	-- Étagère de tissus : un rouleau par tissu (les douze premiers du catalogue)
	bloc(modele, origine, "Etagere", Vector3.new(-11, 3.5, 48), Vector3.new(1.5, 7, 10), BOIS_CLAIR, { matiere = Enum.Material.Wood })
	for k = 1, math.min(12, #Catalogue.Tissus) do
		local t = Catalogue.Tissus[k]
		local c = t.motif.couleurs[1]
		local rangee, colonne = math.floor((k - 1) / 4), (k - 1) % 4
		local rouleau = bloc(modele, origine, "Rouleau_" .. t.id, Vector3.new(-9.9, 1.2 + rangee * 2, 44.5 + colonne * 2.2), Vector3.new(1.8, 0.9, 0.9), rgb(c[1], c[2], c[3]), { forme = Enum.PartType.Cylinder, decor = true })
		-- Un cylindre s'allonge selon X : tourné d'un quart de tour, il est couché le long du mur. Matière lisse :
		-- la matière « tissu » de Roblox assombrit trop les couleurs
		rouleau.CFrame = rouleau.CFrame * CFrame.Angles(0, math.rad(90), 0)
	end
	-- Table de découpe, au fond à gauche : plateau sur quatre pieds, tapis de coupe quadrillé, un rouleau de
	-- tissu et une paire de ciseaux
	local TX, TZ = -6, 51
	local LIGNE = rgb(230, 240, 230)
	bloc(modele, origine, "TableDecoupe", Vector3.new(TX, 2.85, TZ), Vector3.new(6, 0.3, 4), BOIS_CLAIR, { matiere = Enum.Material.Wood })
	for k, c in ipairs({ { -1, -1 }, { 1, -1 }, { -1, 1 }, { 1, 1 } }) do
		bloc(modele, origine, "PiedTable_" .. k, Vector3.new(TX + c[1] * 2.7, 1.35, TZ + c[2] * 1.7), Vector3.new(0.3, 2.7, 0.3), BOIS_CLAIR, { matiere = Enum.Material.Wood })
	end
	bloc(modele, origine, "TapisDecoupe", Vector3.new(TX, 3.025, TZ), Vector3.new(5.4, 0.05, 3.4), rgb(70, 130, 100), { decor = true })
	for k = 1, 5 do -- lignes du tapis, dans la longueur
		bloc(modele, origine, "LigneTapis_" .. k, Vector3.new(TX, 3.055, TZ - 1.7 + k * 3.4 / 6), Vector3.new(5.4, 0.01, 0.03), LIGNE, { decor = true })
	end
	for k = 1, 8 do -- puis en travers
		bloc(modele, origine, "LigneTapis_" .. (5 + k), Vector3.new(TX - 2.7 + k * 0.6, 3.055, TZ), Vector3.new(0.03, 0.01, 3.4), LIGNE, { decor = true })
	end
	bloc(modele, origine, "RouleauTable", Vector3.new(TX - 0.6, 3.35, TZ + 1.2), Vector3.new(3.6, 0.6, 0.6), rgb(232, 170, 190), { forme = Enum.PartType.Cylinder, decor = true })
	for k, angle in ipairs({ 15, -15 }) do -- ciseaux : deux lames croisées…
		local lame = bloc(modele, origine, "Ciseaux_Lame" .. k, Vector3.new(TX + 1.6, 3.07, TZ - 0.8), Vector3.new(1, 0.04, 0.1), rgb(200, 200, 210), { matiere = Enum.Material.Metal, decor = true })
		lame.CFrame = lame.CFrame * CFrame.Angles(0, math.rad(angle), 0)
	end
	for k, dz in ipairs({ -0.15, 0.15 }) do -- … et deux anneaux, à plat sur le tapis
		local anneau = bloc(modele, origine, "Ciseaux_Anneau" .. k, Vector3.new(TX + 2.25, 3.07, TZ - 0.8 + dz), Vector3.new(0.05, 0.28, 0.28), rgb(200, 60, 80), { forme = Enum.PartType.Cylinder, decor = true })
		anneau.CFrame = anneau.CFrame * CFrame.Angles(0, 0, math.rad(90))
	end
	-- Machine à coudre, au fond à droite, sur son meuble : socle, colonne, bras, tête et aiguille (émail crème),
	-- volant sur le côté, bobine de fil sur le bras
	local MX, MZ = 7, 51
	local EMAIL = rgb(240, 236, 228)
	bloc(modele, origine, "Machine", Vector3.new(MX, 2.85, MZ), Vector3.new(4, 0.3, 2.5), BOIS, { matiere = Enum.Material.Wood })
	for k, c in ipairs({ { -1, -1 }, { 1, -1 }, { -1, 1 }, { 1, 1 } }) do
		bloc(modele, origine, "PiedMachine_" .. k, Vector3.new(MX + c[1] * 1.7, 1.35, MZ + c[2] * 1), Vector3.new(0.3, 2.7, 0.3), BOIS, { matiere = Enum.Material.Wood })
	end
	bloc(modele, origine, "SocleMachine", Vector3.new(MX, 3.175, MZ), Vector3.new(2.4, 0.35, 1.1), EMAIL, { decor = true })
	bloc(modele, origine, "ColonneMachine", Vector3.new(MX + 0.85, 3.95, MZ), Vector3.new(0.55, 1.2, 0.8), EMAIL, { decor = true })
	bloc(modele, origine, "BrasMachine", Vector3.new(MX + 0.05, 4.7, MZ), Vector3.new(2.2, 0.45, 0.8), EMAIL, { decor = true })
	bloc(modele, origine, "TeteMachine", Vector3.new(MX - 0.85, 4.2, MZ), Vector3.new(0.5, 0.75, 0.8), EMAIL, { decor = true })
	local aiguille = bloc(modele, origine, "Aiguille", Vector3.new(MX - 0.85, 3.6, MZ - 0.2), Vector3.new(0.5, 0.05, 0.05), rgb(200, 200, 210), { forme = Enum.PartType.Cylinder, matiere = Enum.Material.Metal, decor = true })
	aiguille.CFrame = aiguille.CFrame * CFrame.Angles(0, 0, math.rad(90)) -- debout
	bloc(modele, origine, "Volant", Vector3.new(MX + 1.2, 4.35, MZ), Vector3.new(0.15, 0.9, 0.9), rgb(90, 90, 100), { forme = Enum.PartType.Cylinder, matiere = Enum.Material.Metal, decor = true })
	local bobine = bloc(modele, origine, "Bobine", Vector3.new(MX + 0.4, 5.1, MZ), Vector3.new(0.35, 0.25, 0.25), rgb(210, 50, 90), { forme = Enum.PartType.Cylinder, decor = true })
	bobine.CFrame = bobine.CFrame * CFrame.Angles(0, 0, math.rad(90)) -- debout sur le bras
	-- Le chat de l'atelier (sous-projet 5) : un chat roux qui dort sur son coussin ; « Caresser » (touche F, E sonne
	-- la clochette) le fait ronronner, chez le joueur qui le caresse seulement (module Chat du client)
	local chat = Instance.new("Model")
	chat.Name = "Chat"
	local repere = origine * Boutique.CHAT
	local ROUX, ROUX_FONCE = rgb(222, 132, 62), rgb(186, 96, 40)
	bloc(chat, repere, "Coussin", Vector3.new(0, 0.2, 0), Vector3.new(2.4, 0.4, 2.4), rgb(176, 64, 96), { decor = true })
	local corps = bloc(chat, repere, "Corps", Vector3.new(0, 0.95, 0.15), Vector3.new(1.5, 1.5, 1.5), ROUX, { forme = Enum.PartType.Ball, decor = true })
	bloc(chat, repere, "Tete", Vector3.new(-0.1, 0.9, -0.75), Vector3.new(0.95, 0.95, 0.95), ROUX, { forme = Enum.PartType.Ball, decor = true })
	for k, x in ipairs({ -0.35, 0.15 }) do
		bloc(chat, repere, "Oreille" .. k, Vector3.new(x, 1.42, -0.75), Vector3.new(0.12, 0.32, 0.28), ROUX_FONCE, { forme = Enum.PartType.Wedge, decor = true })
	end
	local queue = bloc(chat, repere, "Queue", Vector3.new(0.5, 0.55, -0.6), Vector3.new(1.3, 0.25, 0.25), ROUX_FONCE, { forme = Enum.PartType.Cylinder, decor = true })
	queue.CFrame = queue.CFrame * CFrame.Angles(0, math.rad(35), 0) -- enroulée devant elle
	local invite = Instance.new("ProximityPrompt")
	invite.Name = "Caresser"
	invite.ActionText = "Caresser"
	invite.ObjectText = "Le chat"
	invite.KeyboardKeyCode = Enum.KeyCode.F
	invite.HoldDuration = 0
	invite.MaxActivationDistance = 10
	invite.RequiresLineOfSight = false
	invite.Parent = corps
	chat.Parent = modele
	modele.Parent = parent
	return modele
end

-- Donne un emplacement libre au joueur (le même s'il en a déjà un) et y construit sa boutique. Renvoie
-- son numéro, ou nil si la rue est pleine. L'attribut « Boutique » du joueur le dit au client (0 : aucune).
function Boutiques:attribuer(joueur)
	local deja = self.parJoueur[joueur]
	if deja then
		return deja.indice
	end
	for indice = 1, Boutique.NOMBRE do
		if not self.parIndice[indice] then
			-- Une panne de construction ne bloque pas l'arrivée : le joueur joue hors de la rue (attribut 0),
			-- et l'emplacement reste libre (boutique et vitrine ne sont posées qu'une fois construites)
			local ok, b = pcall(function()
				local modele = construire(indice, joueur, self.rue)
				local vitrine = Instance.new("Part")
				vitrine.Name = "Vitrine_" .. indice
				vitrine.Anchored = true
				vitrine.Size = Vector3.new(4, 1, 4)
				vitrine.CFrame = Boutique.emplacement(indice) * Boutique.VITRINE
				vitrine.Material = Enum.Material.Wood
				vitrine.Color = BOIS
				vitrine.Parent = self.vitrines
				return { indice = indice, modele = modele, vitrine = vitrine, joueur = joueur }
			end)
			if not ok then
				warn(("[Atelier] %s : boutique %d impossible à construire : %s"):format(joueur.Name, indice, tostring(b)))
				-- Ce qui a pu être posé avant la panne est retiré : l'emplacement reste propre et libre
				for _, reste in ipairs({ { self.rue, "Boutique_" }, { self.vitrines, "Vitrine_" } }) do
					local objet = reste[1]:FindFirstChild(reste[2] .. indice)
					if objet then
						objet:Destroy()
					end
				end
				joueur:SetAttribute("Boutique", 0)
				return nil
			end
			self.parIndice[indice], self.parJoueur[joueur] = b, b
			joueur:SetAttribute("Boutique", indice)
			return indice
		end
	end
	joueur:SetAttribute("Boutique", 0)
	return nil
end

-- Expose une recette dans la vitrine du joueur (nil : vitrine vide)
function Boutiques:exposer(joueur, recette)
	local b = self.parJoueur[joueur]
	if b then
		b.vitrine:SetAttribute("Recette", recette and Recette.encoder(recette) or nil)
	end
end

-- Place l'avatar du joueur à l'entrée de sa boutique
function Boutiques:placer(joueur)
	local b = self.parJoueur[joueur]
	local avatar = joueur.Character
	if b and avatar then
		avatar:PivotTo(Boutique.emplacement(b.indice) * Boutique.ENTREE)
	end
end

-- Départ du joueur : boutique et vitrine retirées, emplacement libéré
function Boutiques:liberer(joueur)
	local b = self.parJoueur[joueur]
	if not b then
		return
	end
	b.modele:Destroy()
	b.vitrine:Destroy()
	self.parIndice[b.indice], self.parJoueur[joueur] = nil, nil
end

return Boutiques
