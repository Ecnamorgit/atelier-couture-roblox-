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
	texte.Text = "L'atelier de " .. nom
	texte.Parent = surface
	-- Comptoir et clochette, contre le mur de gauche
	bloc(modele, origine, "Comptoir", Vector3.new(-9, 1.5, 38), Vector3.new(3, 3, 6), BOIS)
	bloc(modele, origine, "Clochette", Vector3.new(-9, 3.4, 36.5), Vector3.new(0.8, 0.8, 0.8), rgb(230, 190, 70), { forme = Enum.PartType.Ball, matiere = Enum.Material.Metal, decor = true })
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
	-- Table de découpe et machine à coudre, au fond
	bloc(modele, origine, "TableDecoupe", Vector3.new(-6, 1.5, 51), Vector3.new(6, 3, 4), BOIS_CLAIR, { matiere = Enum.Material.Wood })
	bloc(modele, origine, "Machine", Vector3.new(7, 1.5, 51), Vector3.new(4, 3, 2.5), BOIS, { matiere = Enum.Material.Wood })
	bloc(modele, origine, "CorpsMachine", Vector3.new(7, 3.6, 51), Vector3.new(1.6, 1.2, 0.8), rgb(60, 60, 70), { matiere = Enum.Material.Metal, decor = true })
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
			local modele = construire(indice, joueur, self.rue)
			local vitrine = Instance.new("Part")
			vitrine.Name = "Vitrine_" .. indice
			vitrine.Anchored = true
			vitrine.Size = Vector3.new(4, 1, 4)
			vitrine.CFrame = Boutique.emplacement(indice) * Boutique.VITRINE
			vitrine.Material = Enum.Material.Wood
			vitrine.Color = BOIS
			vitrine.Parent = self.vitrines
			local b = { indice = indice, modele = modele, vitrine = vitrine, joueur = joueur }
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
