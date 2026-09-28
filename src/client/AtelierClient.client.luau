-- AtelierClient : interface du prototype
-- commande → tissu → découpe → couture → finitions → livraison
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ContextActionService = game:GetService("ContextActionService")
local ProximityPromptService = game:GetService("ProximityPromptService")

local joueur = Players.LocalPlayer
local dossier = ReplicatedStorage:WaitForChild("Couture")
local CoutureData = require(dossier:WaitForChild("CoutureData"))
local remote = dossier:WaitForChild("CoutureRemote")

local L, H = CoutureData.LARGEUR_COUPON, CoutureData.HAUTEUR_COUPON
local CASE = 34
local LARGEUR_FENETRE, HAUTEUR_FENETRE = 820, 560

local COULEURS = {
	fond = Color3.fromRGB(253, 244, 247),
	panneau = Color3.fromRGB(255, 255, 255),
	accent = Color3.fromRGB(214, 76, 128),
	secondaire = Color3.fromRGB(240, 214, 224),
	texte = Color3.fromRGB(58, 36, 48),
	texteDoux = Color3.fromRGB(130, 100, 115),
	ok = Color3.fromRGB(70, 160, 100),
	alerte = Color3.fromRGB(230, 140, 40),
	erreur = Color3.fromRGB(210, 60, 60),
	or_ = Color3.fromRGB(240, 180, 40),
}

local rng = Random.new()

---------------------------------------------------------------------------
-- Petits utilitaires d'interface
---------------------------------------------------------------------------

local function creer(classe, props, enfants)
	local instance = Instance.new(classe)
	local parent
	for cle, valeur in pairs(props or {}) do
		if cle == "Parent" then
			parent = valeur
		else
			instance[cle] = valeur
		end
	end
	for _, enfant in ipairs(enfants or {}) do
		enfant.Parent = instance
	end
	if parent then
		instance.Parent = parent
	end
	return instance
end

local function arrondir(instance, rayon)
	creer("UICorner", { CornerRadius = UDim.new(0, rayon or 8), Parent = instance })
end

local function fusionner(defaut, props)
	for cle, valeur in pairs(props) do
		defaut[cle] = valeur
	end
	return defaut
end

local function texte(props)
	return creer(
		"TextLabel",
		fusionner({
			BackgroundTransparency = 1,
			Font = Enum.Font.Gotham,
			TextSize = 16,
			TextColor3 = COULEURS.texte,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextWrapped = true,
		}, props)
	)
end

local function bouton(props, auClic)
	local b = creer(
		"TextButton",
		fusionner({
			BackgroundColor3 = COULEURS.accent,
			TextColor3 = Color3.new(1, 1, 1),
			Font = Enum.Font.GothamBold,
			TextSize = 16,
			AutoButtonColor = true,
			Size = UDim2.fromOffset(180, 40),
		}, props)
	)
	arrondir(b, 8)
	if auClic then
		b.Activated:Connect(auClic)
	end
	return b
end

local function couleurTexteSur(fond)
	local luminance = 0.299 * fond.R + 0.587 * fond.G + 0.114 * fond.B
	return luminance > 0.6 and COULEURS.texte or Color3.new(1, 1, 1)
end

---------------------------------------------------------------------------
-- Fenêtre principale
---------------------------------------------------------------------------

local gui = creer("ScreenGui", {
	Name = "AtelierCouture",
	ResetOnSpawn = false,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	Parent = joueur:WaitForChild("PlayerGui"),
})

local boutonAtelier = bouton({
	Name = "BoutonAtelier",
	Text = "✂  Atelier",
	AnchorPoint = Vector2.new(0, 0.5),
	Position = UDim2.new(0, 16, 0.5, 0),
	Size = UDim2.fromOffset(140, 44),
	Parent = gui,
})

local fenetre = creer("Frame", {
	Name = "Fenetre",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromOffset(LARGEUR_FENETRE, HAUTEUR_FENETRE),
	BackgroundColor3 = COULEURS.fond,
	Visible = false,
	Parent = gui,
})
arrondir(fenetre, 14)

-- Réduit la fenêtre sur les petits écrans (téléphones)
local echelle = creer("UIScale", { Parent = fenetre })
local function ajusterEchelle()
	local camera = workspace.CurrentCamera
	local vue = camera and camera.ViewportSize or Vector2.new(1280, 720)
	echelle.Scale = math.min(1, (vue.X - 20) / LARGEUR_FENETRE, (vue.Y - 60) / HAUTEUR_FENETRE)
end
ajusterEchelle()
if workspace.CurrentCamera then
	workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(ajusterEchelle)
end

local titre = texte({
	Font = Enum.Font.GothamBold,
	TextSize = 24,
	Position = UDim2.fromOffset(20, 14),
	Size = UDim2.new(1, -200, 0, 32),
	Parent = fenetre,
})

local argentLabel = texte({
	Font = Enum.Font.GothamBold,
	TextSize = 20,
	TextColor3 = COULEURS.accent,
	TextXAlignment = Enum.TextXAlignment.Right,
	Position = UDim2.new(1, -170, 0, 14),
	Size = UDim2.fromOffset(110, 32),
	Parent = fenetre,
})

bouton({
	Text = "✕",
	Position = UDim2.new(1, -50, 0, 12),
	Size = UDim2.fromOffset(36, 36),
	BackgroundColor3 = COULEURS.secondaire,
	TextColor3 = COULEURS.texte,
	Parent = fenetre,
}, function()
	fenetre.Visible = false
end)

local contenu = creer("Frame", {
	Name = "Contenu",
	BackgroundTransparency = 1,
	Position = UDim2.fromOffset(20, 60),
	Size = UDim2.new(1, -40, 1, -94),
	Parent = fenetre,
})

local message = texte({
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 1, -6),
	Size = UDim2.new(1, -40, 0, 24),
	TextXAlignment = Enum.TextXAlignment.Center,
	Font = Enum.Font.GothamBold,
	Visible = false,
	Parent = fenetre,
})

local jetonMessage = 0
local function afficherMessage(txt, couleur)
	jetonMessage += 1
	local jeton = jetonMessage
	message.Text = txt
	message.TextColor3 = couleur or COULEURS.texte
	message.Visible = true
	task.delay(3, function()
		if jeton == jetonMessage then
			message.Visible = false
		end
	end)
end

task.spawn(function()
	local argent = joueur:WaitForChild("leaderstats"):WaitForChild("Argent")
	local function maj()
		argentLabel.Text = ("%d $"):format(argent.Value)
	end
	maj()
	argent.Changed:Connect(maj)
end)

boutonAtelier.Activated:Connect(function()
	fenetre.Visible = not fenetre.Visible
end)

ProximityPromptService.PromptTriggered:Connect(function(invite)
	if invite.Name == "AtelierPrompt" then
		fenetre.Visible = true
	end
end)

---------------------------------------------------------------------------
-- État de la partie et enchaînement des étapes
---------------------------------------------------------------------------

local etat = {
	commande = nil,
	vetement = nil,
	tissu = nil,
	placements = {},
	decoupe = 0,
	coutures = {},
}

local nettoyages = {}
local jetonEtape = 0

local function aNettoyer(fonction)
	table.insert(nettoyages, fonction)
end

local function lier(connexion)
	aNettoyer(function()
		connexion:Disconnect()
	end)
	return connexion
end

local function nouvelleEtape(nomTitre)
	for _, fonction in ipairs(nettoyages) do
		fonction()
	end
	table.clear(nettoyages)
	jetonEtape += 1
	titre.Text = nomTitre
	contenu:ClearAllChildren()
end

local occupe = false
local function appeler(action, argument)
	if occupe then
		return { ok = false, erreur = "Patiente un instant…" }
	end
	occupe = true
	local ok, reponse = pcall(function()
		return remote:InvokeServer(action, argument)
	end)
	occupe = false
	if not ok then
		return { ok = false, erreur = "Connexion au serveur impossible." }
	end
	if type(reponse) ~= "table" then
		return { ok = false, erreur = "Réponse inattendue du serveur." }
	end
	return reponse
end

local etapeAccueil, etapeCommande, etapeTissu, etapeDecoupe, etapeCouture, etapeFinitions, etapeResultat

local function demanderCommande()
	local reponse = appeler("NouvelleCommande")
	if not reponse.ok then
		afficherMessage(reponse.erreur, COULEURS.erreur)
		return
	end
	etat.commande = reponse.commande
	etat.vetement = CoutureData.getVetement(reponse.commande.vetement)
	etat.tissu = nil
	etat.placements = {}
	etat.decoupe = 0
	etat.coutures = {}
	etapeCommande()
end

---------------------------------------------------------------------------
-- Accueil
---------------------------------------------------------------------------

etapeAccueil = function()
	nouvelleEtape("Atelier de couture")
	texte({
		Text = "Bienvenue dans ton atelier ! Des clients vont te passer commande : choisis le tissu, "
			.. "découpe les pièces du patron, couds-les puis livre le vêtement. "
			.. "Plus le travail est soigné, plus la paie et la réputation montent.",
		TextSize = 18,
		Size = UDim2.new(1, 0, 0, 90),
		Parent = contenu,
	})
	bouton({
		Text = "Ouvrir la boutique",
		Position = UDim2.fromOffset(0, 110),
		Size = UDim2.fromOffset(240, 50),
	}, demanderCommande).Parent = contenu
end

---------------------------------------------------------------------------
-- Commande
---------------------------------------------------------------------------

etapeCommande = function()
	local commande, vetement = etat.commande, etat.vetement
	nouvelleEtape("Nouvelle commande")

	local carte = creer("Frame", {
		BackgroundColor3 = COULEURS.panneau,
		Size = UDim2.new(1, 0, 0, 250),
		Parent = contenu,
	})
	arrondir(carte, 12)

	local portrait = creer("TextLabel", {
		Text = string.sub(commande.client, 1, 1),
		Font = Enum.Font.GothamBold,
		TextSize = 40,
		TextColor3 = Color3.new(1, 1, 1),
		BackgroundColor3 = COULEURS.accent,
		Position = UDim2.fromOffset(20, 20),
		Size = UDim2.fromOffset(90, 90),
		Parent = carte,
	})
	creer("UICorner", { CornerRadius = UDim.new(0.5, 0), Parent = portrait })

	texte({
		Text = commande.client,
		Font = Enum.Font.GothamBold,
		TextSize = 22,
		Position = UDim2.fromOffset(130, 20),
		Size = UDim2.new(1, -150, 0, 28),
		Parent = carte,
	})
	texte({
		Text = "« " .. commande.texte .. " »",
		Font = Enum.Font.GothamMedium,
		TextSize = 18,
		TextYAlignment = Enum.TextYAlignment.Top,
		Position = UDim2.fromOffset(130, 54),
		Size = UDim2.new(1, -150, 0, 60),
		Parent = carte,
	})

	local deco = commande.deco and CoutureData.getDecoration(commande.deco)
	texte({
		Text = ("Vêtement : %s\nCouleur souhaitée : %s\nFinition : %s\nPaie de base : %d $"):format(
			vetement.nom,
			commande.teinte,
			deco and deco.nom or "au choix",
			vetement.prixBase
		),
		TextColor3 = COULEURS.texteDoux,
		TextYAlignment = Enum.TextYAlignment.Top,
		Position = UDim2.fromOffset(130, 124),
		Size = UDim2.new(1, -150, 0, 100),
		Parent = carte,
	})

	bouton({
		Text = "Accepter la commande",
		Position = UDim2.fromOffset(0, 272),
		Size = UDim2.fromOffset(240, 48),
		Parent = contenu,
	}, etapeTissu)
	bouton({
		Text = "Client suivant",
		BackgroundColor3 = COULEURS.secondaire,
		TextColor3 = COULEURS.texte,
		Position = UDim2.fromOffset(256, 272),
		Size = UDim2.fromOffset(180, 48),
		Parent = contenu,
	}, demanderCommande)
end

---------------------------------------------------------------------------
-- 1. Choix du tissu
---------------------------------------------------------------------------

etapeTissu = function()
	nouvelleEtape("1. Choisis le tissu")
	texte({
		Text = ("Couleur demandée : %s. La soie, le velours et le satin coûtent plus cher, "
			.. "mais le client paiera davantage pour un beau tissu."):format(etat.commande.teinte),
		Size = UDim2.new(1, 0, 0, 44),
		Parent = contenu,
	})

	local grille = creer("ScrollingFrame", {
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Position = UDim2.fromOffset(0, 54),
		Size = UDim2.new(1, 0, 1, -54),
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 6,
		Parent = contenu,
	})
	creer("UIGridLayout", {
		CellSize = UDim2.fromOffset(180, 122),
		CellPadding = UDim2.fromOffset(12, 12),
		Parent = grille,
	})

	for _, tissu in ipairs(CoutureData.Tissus) do
		local carte = creer("TextButton", {
			Text = "",
			AutoButtonColor = true,
			BackgroundColor3 = COULEURS.panneau,
			Parent = grille,
		})
		arrondir(carte, 10)
		local echantillon = creer("Frame", {
			BackgroundColor3 = tissu.couleur,
			Position = UDim2.fromOffset(10, 10),
			Size = UDim2.new(1, -20, 0, 56),
			Parent = carte,
		})
		arrondir(echantillon, 6)
		texte({
			Text = tissu.nom,
			Font = Enum.Font.GothamBold,
			Position = UDim2.fromOffset(10, 72),
			Size = UDim2.new(1, -20, 0, 20),
			Parent = carte,
		})
		texte({
			Text = ("%d $  ·  qualité ×%.2f"):format(tissu.prix, tissu.qualite),
			TextSize = 14,
			TextColor3 = COULEURS.texteDoux,
			Position = UDim2.fromOffset(10, 94),
			Size = UDim2.new(1, -20, 0, 18),
			Parent = carte,
		})
		carte.Activated:Connect(function()
			local reponse = appeler("AcheterTissu", tissu.id)
			if not reponse.ok then
				afficherMessage(reponse.erreur, COULEURS.erreur)
				return
			end
			etat.tissu = tissu
			etapeDecoupe()
		end)
	end
end

---------------------------------------------------------------------------
-- 2. Découpe : placer les pièces du patron sur le coupon
---------------------------------------------------------------------------

etapeDecoupe = function()
	nouvelleEtape("2. Place et découpe les pièces du patron")
	local vetement, tissu = etat.vetement, etat.tissu
	local couleurContraste = couleurTexteSur(tissu.couleur)
	local selection = nil
	local pivoteSelection = false
	local survol = nil

	local coupon = creer("Frame", {
		BackgroundColor3 = tissu.couleur,
		BorderSizePixel = 0,
		Size = UDim2.fromOffset(L * CASE, H * CASE),
		Parent = contenu,
	})
	for x = 1, L - 1 do
		creer("Frame", {
			BackgroundColor3 = couleurContraste,
			BackgroundTransparency = 0.8,
			BorderSizePixel = 0,
			Position = UDim2.fromOffset(x * CASE, 0),
			Size = UDim2.new(0, 1, 1, 0),
			Parent = coupon,
		})
	end
	for y = 1, H - 1 do
		creer("Frame", {
			BackgroundColor3 = couleurContraste,
			BackgroundTransparency = 0.8,
			BorderSizePixel = 0,
			Position = UDim2.fromOffset(0, y * CASE),
			Size = UDim2.new(1, 0, 0, 1),
			Parent = coupon,
		})
	end
	texte({
		Text = "↑ Droit-fil du tissu : garde les flèches des pièces vers le haut.",
		TextSize = 14,
		TextColor3 = COULEURS.texteDoux,
		Position = UDim2.fromOffset(0, H * CASE + 8),
		Size = UDim2.fromOffset(L * CASE, 36),
		Parent = contenu,
	})

	local fantome = creer("Frame", {
		BackgroundColor3 = couleurContraste,
		BackgroundTransparency = 0.6,
		BorderSizePixel = 0,
		Visible = false,
		ZIndex = 4,
		Parent = coupon,
	})
	local calquePieces = creer("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 3,
		Parent = coupon,
	})

	-- Panneau de droite
	local panneau = creer("Frame", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(L * CASE + 20, 0),
		Size = UDim2.new(1, -(L * CASE + 20), 1, 0),
		Parent = contenu,
	})
	creer("UIListLayout", {
		Padding = UDim.new(0, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = panneau,
	})
	texte({
		Text = "Clique sur une pièce, puis sur le tissu pour la poser. Clique une pièce posée pour la reprendre.",
		TextSize = 14,
		TextColor3 = COULEURS.texteDoux,
		Size = UDim2.new(1, 0, 0, 36),
		LayoutOrder = 1,
		Parent = panneau,
	})

	local boutonsPieces = {}
	local redessiner

	local function prendre(i)
		local place = etat.placements[i]
		selection = i
		pivoteSelection = place ~= nil and place.pivote or false
		etat.placements[i] = nil
		redessiner()
	end

	for i, piece in ipairs(vetement.pieces) do
		boutonsPieces[i] = bouton({
			Size = UDim2.new(1, 0, 0, 32),
			TextSize = 14,
			LayoutOrder = 1 + i,
			Parent = panneau,
		}, function()
			if selection == i then
				selection = nil
				redessiner()
			else
				prendre(i)
			end
		end)
		boutonsPieces[i].Name = piece.nom
	end

	local function pivoter()
		if selection then
			pivoteSelection = not pivoteSelection
			redessiner()
		end
	end

	bouton({
		Text = "⟳ Pivoter (R)",
		BackgroundColor3 = COULEURS.secondaire,
		TextColor3 = COULEURS.texte,
		Size = UDim2.new(1, 0, 0, 32),
		LayoutOrder = 50,
		Parent = panneau,
	}, pivoter)

	local noteLabel = texte({
		Font = Enum.Font.GothamBold,
		Size = UDim2.new(1, 0, 0, 40),
		LayoutOrder = 60,
		Parent = panneau,
	})
	local boutonCouper = bouton({
		Text = "✂ Couper",
		Size = UDim2.new(1, 0, 0, 44),
		LayoutOrder = 70,
		Parent = panneau,
	})

	local function tailleSelection()
		return CoutureData.taillePiece(vetement.pieces[selection], pivoteSelection)
	end

	local function majFantome()
		if not selection or not survol then
			fantome.Visible = false
			return
		end
		local l, h = tailleSelection()
		local x = math.clamp(survol.x, 0, L - l)
		local y = math.clamp(survol.y, 0, H - h)
		fantome.Position = UDim2.fromOffset(x * CASE, y * CASE)
		fantome.Size = UDim2.fromOffset(l * CASE, h * CASE)
		fantome.Visible = true
	end

	redessiner = function()
		calquePieces:ClearAllChildren()
		local note, details = CoutureData.evaluerDecoupe(vetement, etat.placements)
		etat.decoupe = note
		local toutesPlacees = true

		for i, piece in ipairs(vetement.pieces) do
			local place = etat.placements[i]
			local detail = details[i]
			local b = boutonsPieces[i]
			if selection == i then
				b.Text = ("▶ %s (%d×%d)"):format(piece.nom, CoutureData.taillePiece(piece, pivoteSelection))
				b.BackgroundColor3 = COULEURS.accent
				b.TextColor3 = Color3.new(1, 1, 1)
			elseif place then
				b.Text = "✓ " .. piece.nom
				b.BackgroundColor3 = COULEURS.panneau
				b.TextColor3 = COULEURS.ok
			else
				b.Text = piece.nom .. " — à placer"
				b.BackgroundColor3 = COULEURS.panneau
				b.TextColor3 = COULEURS.texte
			end

			if place then
				local l, h = CoutureData.taillePiece(piece, place.pivote)
				local contour = COULEURS.ok
				if detail.chevauche then
					contour = COULEURS.erreur
				elseif detail.pivote then
					contour = COULEURS.alerte
				end
				local bloc = creer("TextButton", {
					Text = piece.nom .. "\n" .. (place.pivote and "→" or "↑"),
					Font = Enum.Font.GothamBold,
					TextSize = 13,
					TextWrapped = true,
					TextColor3 = couleurContraste,
					AutoButtonColor = true,
					BackgroundColor3 = tissu.couleur:Lerp(couleurContraste, 0.3),
					BackgroundTransparency = 0.15,
					Position = UDim2.fromOffset(place.x * CASE + 2, place.y * CASE + 2),
					Size = UDim2.fromOffset(l * CASE - 4, h * CASE - 4),
					Parent = calquePieces,
				})
				arrondir(bloc, 4)
				creer("UIStroke", {
					Color = contour,
					Thickness = 2,
					ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
					Parent = bloc,
				})
				bloc.Activated:Connect(function()
					prendre(i)
				end)
			else
				toutesPlacees = false
			end
		end

		noteLabel.Text = ("Qualité de la découpe : %d %%"):format(math.floor(note * 100 + 0.5))
		boutonCouper.AutoButtonColor = toutesPlacees
		boutonCouper.BackgroundColor3 = toutesPlacees and COULEURS.accent or COULEURS.secondaire
		majFantome()
	end

	-- Une case = un bouton invisible : survol pour l'aperçu, clic pour poser la pièce
	for y = 0, H - 1 do
		for x = 0, L - 1 do
			local case = creer("TextButton", {
				Text = "",
				BackgroundTransparency = 1,
				AutoButtonColor = false,
				Position = UDim2.fromOffset(x * CASE, y * CASE),
				Size = UDim2.fromOffset(CASE, CASE),
				ZIndex = 1,
				Parent = coupon,
			})
			case.MouseEnter:Connect(function()
				survol = { x = x, y = y }
				majFantome()
			end)
			case.Activated:Connect(function()
				if not selection then
					return
				end
				local l, h = tailleSelection()
				etat.placements[selection] = {
					x = math.clamp(x, 0, L - l),
					y = math.clamp(y, 0, H - h),
					pivote = pivoteSelection,
				}
				selection = nil
				pivoteSelection = false
				redessiner()
			end)
		end
	end
	coupon.MouseLeave:Connect(function()
		survol = nil
		majFantome()
	end)

	lier(UserInputService.InputBegan:Connect(function(input, traite)
		if not traite and fenetre.Visible and input.KeyCode == Enum.KeyCode.R then
			pivoter()
		end
	end))

	boutonCouper.Activated:Connect(function()
		for i = 1, #vetement.pieces do
			if not etat.placements[i] then
				afficherMessage("Place toutes les pièces avant de couper.", COULEURS.alerte)
				return
			end
		end
		etapeCouture()
	end)

	redessiner()
end

---------------------------------------------------------------------------
-- 3. Couture : piquer au bon moment
---------------------------------------------------------------------------

etapeCouture = function()
	nouvelleEtape("3. Couds les pièces")
	local vetement = etat.vetement
	local jeton = jetonEtape
	etat.coutures = {}

	texte({
		Text = "Appuie sur « Piquer ! » (ou Espace) quand l'aiguille passe dans la zone verte.",
		TextColor3 = COULEURS.texteDoux,
		Size = UDim2.new(1, 0, 0, 24),
		Parent = contenu,
	})
	local titreCouture = texte({
		Font = Enum.Font.GothamBold,
		TextSize = 22,
		Position = UDim2.fromOffset(0, 36),
		Size = UDim2.new(1, 0, 0, 30),
		Parent = contenu,
	})
	local barre = creer("Frame", {
		BackgroundColor3 = etat.tissu.couleur,
		Position = UDim2.fromOffset(40, 90),
		Size = UDim2.new(1, -80, 0, 56),
		Parent = contenu,
	})
	arrondir(barre, 8)
	creer("Frame", {
		AnchorPoint = Vector2.new(0, 0.5),
		BackgroundColor3 = couleurTexteSur(etat.tissu.couleur),
		BackgroundTransparency = 0.4,
		BorderSizePixel = 0,
		Position = UDim2.fromScale(0, 0.5),
		Size = UDim2.new(1, 0, 0, 2),
		Parent = barre,
	})
	local zone = creer("Frame", {
		BackgroundColor3 = COULEURS.ok,
		BackgroundTransparency = 0.3,
		BorderSizePixel = 0,
		Parent = barre,
	})
	local aiguille = creer("Frame", {
		AnchorPoint = Vector2.new(0.5, 0),
		BackgroundColor3 = COULEURS.texte,
		BorderSizePixel = 0,
		Size = UDim2.new(0, 4, 1, 16),
		ZIndex = 3,
		Parent = barre,
	})
	local retour = texte({
		Font = Enum.Font.GothamBold,
		TextSize = 24,
		TextXAlignment = Enum.TextXAlignment.Center,
		Position = UDim2.fromOffset(0, 160),
		Size = UDim2.new(1, 0, 0, 30),
		Parent = contenu,
	})
	local historique = texte({
		Text = "",
		TextYAlignment = Enum.TextYAlignment.Top,
		Position = UDim2.fromOffset(40, 200),
		Size = UDim2.new(1, -80, 0, 130),
		Parent = contenu,
	})
	local boutonPiquer = bouton({
		Text = "Piquer !",
		Position = UDim2.new(0.5, -120, 0, 350),
		Size = UDim2.fromOffset(240, 52),
		Parent = contenu,
	})

	local indice = 1
	local t, vitesse = 0, 0.6
	local zoneDebut, zoneLargeur = 0, 0.2
	local enPause, fini = false, false

	local function preparer()
		titreCouture.Text = ("Couture %d / %d : %s"):format(indice, #vetement.coutures, vetement.coutures[indice])
		zoneLargeur = math.max(0.08, 0.2 - 0.025 * (indice - 1))
		zoneDebut = rng:NextNumber(0.05, 0.95 - zoneLargeur)
		zone.Position = UDim2.fromScale(zoneDebut, 0)
		zone.Size = UDim2.fromScale(zoneLargeur, 1)
		vitesse = 0.55 + 0.12 * (indice - 1)
		t = rng:NextNumber(0, 2)
		retour.Text = ""
		enPause = false
	end

	-- Aller-retour de l'aiguille entre 0 et 1
	local function positionAiguille()
		local p = t % 2
		return p > 1 and 2 - p or p
	end

	lier(RunService.RenderStepped:Connect(function(dt)
		if enPause or fini then
			return
		end
		t += dt * vitesse
		aiguille.Position = UDim2.new(positionAiguille(), 0, 0, -8)
	end))

	local function piquer()
		if enPause or fini then
			return
		end
		enPause = true
		local centre = zoneDebut + zoneLargeur / 2
		local demi = zoneLargeur / 2
		local ecart = math.abs(positionAiguille() - centre)
		local precision
		if ecart <= demi then
			precision = 1 - 0.3 * (ecart / demi)
		else
			precision = math.max(0, 0.7 - (ecart - demi) * 4)
		end
		table.insert(etat.coutures, precision)

		if precision >= 0.9 then
			retour.Text, retour.TextColor3 = "Parfait !", COULEURS.ok
		elseif precision >= 0.7 then
			retour.Text, retour.TextColor3 = "Bien !", COULEURS.ok
		elseif precision >= 0.4 then
			retour.Text, retour.TextColor3 = "Un peu de travers…", COULEURS.alerte
		else
			retour.Text, retour.TextColor3 = "Raté !", COULEURS.erreur
		end
		historique.Text ..= ("✓ %s : %d %%\n"):format(vetement.coutures[indice], math.floor(precision * 100 + 0.5))

		task.delay(0.9, function()
			if jeton ~= jetonEtape then
				return
			end
			if indice < #vetement.coutures then
				indice += 1
				preparer()
			else
				fini = true
				local somme = 0
				for _, p in ipairs(etat.coutures) do
					somme += p
				end
				titreCouture.Text = ("Couture terminée : %d %%"):format(math.floor(somme / #etat.coutures * 100 + 0.5))
				boutonPiquer.Text = "Finitions →"
			end
		end)
	end

	boutonPiquer.Activated:Connect(function()
		if fini then
			etapeFinitions()
		else
			piquer()
		end
	end)

	-- Espace pique sans faire sauter le personnage
	ContextActionService:BindActionAtPriority("AtelierPiquer", function(_, etatEntree)
		if not fenetre.Visible then
			return Enum.ContextActionResult.Pass
		end
		if etatEntree == Enum.UserInputState.Begin then
			piquer()
		end
		return Enum.ContextActionResult.Sink
	end, false, Enum.ContextActionPriority.High.Value, Enum.KeyCode.Space)
	aNettoyer(function()
		ContextActionService:UnbindAction("AtelierPiquer")
	end)

	preparer()
end

---------------------------------------------------------------------------
-- 4. Finitions et livraison
---------------------------------------------------------------------------

etapeFinitions = function()
	nouvelleEtape("4. Finitions")
	local commande, tissu = etat.commande, etat.tissu
	local choix = {}

	local somme = 0
	for _, p in ipairs(etat.coutures) do
		somme += p
	end
	local noteCouture = #etat.coutures > 0 and somme / #etat.coutures or 0

	texte({
		Text = ("Tissu : %s\nDécoupe : %d %%\nCouture : %d %%"):format(
			tissu.nom,
			math.floor(etat.decoupe * 100 + 0.5),
			math.floor(noteCouture * 100 + 0.5)
		),
		TextYAlignment = Enum.TextYAlignment.Top,
		Size = UDim2.new(1, 0, 0, 66),
		Parent = contenu,
	})

	local deco = commande.deco and CoutureData.getDecoration(commande.deco)
	texte({
		Text = deco and ("Le client souhaite : %s."):format(deco.nom)
			or "Le client n'a rien demandé de particulier : une petite touche fait toujours plaisir.",
		Font = Enum.Font.GothamBold,
		Position = UDim2.fromOffset(0, 74),
		Size = UDim2.new(1, 0, 0, 24),
		Parent = contenu,
	})

	local coutLabel = texte({
		TextColor3 = COULEURS.texteDoux,
		Position = UDim2.fromOffset(0, 270),
		Size = UDim2.new(1, 0, 0, 24),
		Parent = contenu,
	})

	local function majCout()
		local total = 0
		for _, d in ipairs(CoutureData.Decorations) do
			if choix[d.id] then
				total += d.prix
			end
		end
		coutLabel.Text = ("Coût des finitions : %d $"):format(total)
	end

	for index, d in ipairs(CoutureData.Decorations) do
		local colonne, ligne = (index - 1) % 2, math.floor((index - 1) / 2)
		local b
		b = bouton({
			Text = ("%s  (%d $)"):format(d.nom, d.prix),
			BackgroundColor3 = COULEURS.panneau,
			TextColor3 = COULEURS.texte,
			Position = UDim2.fromOffset(colonne * 300, 110 + ligne * 72),
			Size = UDim2.fromOffset(284, 60),
			Parent = contenu,
		}, function()
			choix[d.id] = not choix[d.id] or nil
			b.BackgroundColor3 = choix[d.id] and COULEURS.accent or COULEURS.panneau
			b.TextColor3 = choix[d.id] and Color3.new(1, 1, 1) or COULEURS.texte
			majCout()
		end)
	end
	majCout()

	bouton({
		Text = "Livrer au client",
		Position = UDim2.fromOffset(0, 320),
		Size = UDim2.fromOffset(240, 50),
		Parent = contenu,
	}, function()
		local placements = {}
		for i = 1, #etat.vetement.pieces do
			local p = etat.placements[i]
			if p then
				table.insert(placements, { i = i, x = p.x, y = p.y, pivote = p.pivote })
			end
		end
		local decorations = {}
		for _, d in ipairs(CoutureData.Decorations) do
			if choix[d.id] then
				table.insert(decorations, d.id)
			end
		end
		local reponse = appeler("Livrer", {
			placements = placements,
			coutures = etat.coutures,
			decorations = decorations,
		})
		if not reponse.ok then
			afficherMessage(reponse.erreur, COULEURS.erreur)
			return
		end
		etat.commande = nil
		etapeResultat(reponse)
	end)
end

---------------------------------------------------------------------------
-- 5. Résultat
---------------------------------------------------------------------------

etapeResultat = function(reponse)
	nouvelleEtape("Livraison")

	texte({
		Text = string.rep("★", reponse.etoiles) .. string.rep("☆", 5 - reponse.etoiles),
		Font = Enum.Font.GothamBold,
		TextSize = 44,
		TextColor3 = COULEURS.or_,
		Size = UDim2.new(1, 0, 0, 52),
		Parent = contenu,
	})
	texte({
		Text = ("+%d $%s"):format(
			reponse.paiement,
			reponse.coutFinitions > 0 and ("   (finitions : −%d $)"):format(reponse.coutFinitions) or ""
		),
		Font = Enum.Font.GothamBold,
		TextSize = 22,
		TextColor3 = COULEURS.ok,
		Position = UDim2.fromOffset(0, 58),
		Size = UDim2.new(1, 0, 0, 28),
		Parent = contenu,
	})
	texte({
		Text = "« " .. reponse.commentaire .. " »",
		Font = Enum.Font.GothamMedium,
		TextSize = 18,
		Position = UDim2.fromOffset(0, 96),
		Size = UDim2.new(1, 0, 0, 48),
		Parent = contenu,
	})

	local lignes = {
		{ "Couleur", reponse.notes.couleur },
		{ "Découpe", reponse.notes.decoupe },
		{ "Couture", reponse.notes.couture },
		{ "Finitions", reponse.notes.finitions },
	}
	for index, ligne in ipairs(lignes) do
		local y = 150 + (index - 1) * 36
		texte({
			Text = ligne[1],
			Position = UDim2.fromOffset(0, y),
			Size = UDim2.fromOffset(110, 26),
			Parent = contenu,
		})
		local fond = creer("Frame", {
			BackgroundColor3 = COULEURS.secondaire,
			Position = UDim2.fromOffset(120, y + 5),
			Size = UDim2.fromOffset(360, 16),
			Parent = contenu,
		})
		arrondir(fond, 8)
		local remplissage = creer("Frame", {
			BackgroundColor3 = ligne[2] >= 0.7 and COULEURS.ok or ligne[2] >= 0.4 and COULEURS.alerte or COULEURS.erreur,
			Size = UDim2.fromScale(math.clamp(ligne[2], 0.02, 1), 1),
			Parent = fond,
		})
		arrondir(remplissage, 8)
		texte({
			Text = ("%d %%"):format(math.floor(ligne[2] * 100 + 0.5)),
			Position = UDim2.fromOffset(492, y),
			Size = UDim2.fromOffset(60, 26),
			Parent = contenu,
		})
	end

	bouton({
		Text = "Client suivant",
		Position = UDim2.fromOffset(0, 310),
		Size = UDim2.fromOffset(240, 50),
		Parent = contenu,
	}, demanderCommande)
end

etapeAccueil()
