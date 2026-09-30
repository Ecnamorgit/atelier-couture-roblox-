-- Écran des décorations (panneau à droite, la robe sur le mannequin) : choisir une décoration dans la
-- palette, toucher la robe pour la poser, ou toucher une décoration posée pour la sélectionner ; tourner
-- (Q/E), agrandir, supprimer, annuler ; garnitures point par point. Glisser sur la scène fait tourner la vue.
-- La logique est dans Decorateur ; « Présenter à la cliente » envoie la liste (EtatAtelier:decorer).
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local Couture = ReplicatedStorage:WaitForChild("Couture")
local Catalogue = require(Couture:WaitForChild("Catalogue"))
local Deblocages = require(Couture:WaitForChild("Deblocages"))
local Decorateur = require(script.Parent:WaitForChild("Decorateur"))
local Sons = require(script.Parent:WaitForChild("Sons"))

local SEUIL_GLISSER = 8 -- px : au-delà, c'est un glisser (la vue tourne), pas une touche
local DEGRES_PAR_PX = 0.5
local LIGNE_PALETTE = 44

return function(ctx)
	local UiKit, session, contenu, scene = ctx.UiKit, ctx.session, ctx.contenu, ctx.scene
	local C = UiKit.COULEURS
	local connexions = {}
	local deco = Decorateur.nouveau(session.etat:recette(), session.etat.accessoires)
	local rafraichir

	local cout = UiKit.texte({ Name = "Cout", Font = Enum.Font.GothamBold, TextSize = 18, Size = UDim2.new(1, 0, 0, 24), Parent = contenu })
	UiKit.texte({
		Text = "Choisis une décoration, puis touche la robe. Glisse sur la scène pour tourner la vue.",
		TextSize = 14,
		TextColor3 = C.texteDoux,
		Position = UDim2.fromOffset(0, 26),
		Size = UDim2.new(1, 0, 0, 40),
		Parent = contenu,
	})

	-- Palette : objets à l'unité, garnitures au dm. Les souvenirs des événements n'y sont qu'une fois ouverts (fermés,
	-- ils dévoileraient l'histoire)
	local visibles = {}
	for _, a in ipairs(Catalogue.Accessoires) do
		local c = Deblocages.CONDITIONS.accessoires[a.id]
		if not (c and c.evenement) or Deblocages.ouvert(ctx.session.etat, "accessoires", a.id) then
			table.insert(visibles, a)
		end
	end
	local palette = UiKit.creer("ScrollingFrame", {
		Name = "Palette",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 6,
		Position = UDim2.fromOffset(0, 70),
		Size = UDim2.new(1, 0, 0, 3 * LIGNE_PALETTE), -- trois rangées entières, le reste défile
		CanvasSize = UDim2.fromOffset(0, math.ceil(#visibles / 2) * LIGNE_PALETTE),
		Parent = contenu,
	})
	local boutons = {}
	for k, a in ipairs(visibles) do
		local prix = a.genre == "garniture" and ("%d po/dm"):format(a.prix) or ("%d po"):format(a.prix)
		-- fermé : ce qu'il faut pour l'ouvrir à la place du prix
		local detail = if Deblocages.ouvert(ctx.session.etat, "accessoires", a.id) then prix else Deblocages.raison("accessoires", a.id)
		boutons[a.id] = UiKit.boutonDoux({
			Name = "Deco_" .. a.id,
			Text = a.nom .. " · " .. detail,
			TextSize = 14,
			TextWrapped = true,
			Position = UDim2.new(((k - 1) % 2) * 0.5, 0, 0, ((k - 1) // 2) * LIGNE_PALETTE),
			Size = UDim2.new(0.5, -10, 0, LIGNE_PALETTE - 4),
			Parent = palette,
		}, function()
			if not Deblocages.ouvert(ctx.session.etat, "accessoires", a.id) then
				ctx.message(Deblocages.message("accessoires", a.id), C.texteDoux)
				return
			end
			deco:choisir(a.id)
			rafraichir()
		end)
	end

	-- Outils sur la décoration sélectionnée
	local function outil(nom, texte, x, y, largeur, action)
		return UiKit.boutonDoux({ Name = nom, Text = texte, TextSize = 14, Position = UDim2.new(x, 0, 0, y), Size = UDim2.new(largeur, -6, 0, 34), Parent = contenu }, function()
			action()
			rafraichir()
		end)
	end
	outil("Tourner-15", "« 15°", 0, 228, 0.25, function()
		deco:tourner(-15)
	end)
	outil("Tourner15", "15° »", 0.25, 228, 0.25, function()
		deco:tourner(15)
	end)
	outil("Reduire", "Plus petit", 0.5, 228, 0.25, function()
		deco:redimensionner(-0.25)
	end)
	outil("Agrandir", "Plus grand", 0.75, 228, 0.25, function()
		deco:redimensionner(0.25)
	end)
	outil("Supprimer", "Supprimer", 0, 268, 0.5, function()
		deco:supprimer()
	end)
	outil("Annuler", "Annuler", 0.5, 268, 0.5, function()
		deco:annuler()
	end)
	local finir = outil("FinirGarniture", "Finir la garniture", 0, 308, 1, function()
		if not deco:terminerGarniture() then
			ctx.message("Une garniture a besoin de deux points, sur au moins 0,5 dm.", C.erreur)
		end
	end)
	UiKit.bouton({ Name = "Presenter", Text = "Présenter à la cliente", Position = UDim2.fromOffset(0, 350), Size = UDim2.new(1, -6, 0, 44), Parent = contenu }, function()
		local r = session:decorer(deco:resultat())
		if not r.ok then
			ctx.refus(r)
		end
	end, 0.4)
	UiKit.boutonConfirme({ Name = "Recommencer", Text = "Recommencer la robe", TextSize = 14, AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), Size = UDim2.fromOffset(200, 34), Parent = contenu }, function()
		local r = session:recommencer()
		if not r.ok then
			ctx.refus(r)
		end
	end)

	rafraichir = function()
		local n = deco:cout()
		cout.Text = n >= 0 and ("Coût : %d po"):format(n) or ("Remboursement : %d po"):format(-n)
		for id, b in pairs(boutons) do
			b.BackgroundColor3 = id == deco.choix and C.accent or C.secondaire
			b.TextColor3 = id == deco.choix and Color3.new(1, 1, 1) or C.texte
			UiKit.griser(b, not Deblocages.ouvert(ctx.session.etat, "accessoires", id))
		end
		finir.Visible = deco.garniture ~= nil
		scene:montrerDecorations(deco.recette, deco.liste, deco.garniture, deco.selection)
	end

	-- Toucher la scène : une décoration posée (sélection) ou la robe (pose)
	local function toucher(position)
		local camera = Workspace.CurrentCamera
		local rayon = camera:ScreenPointToRay(position.X, position.Y)
		local t = scene:toucher(rayon.Origin, rayon.Direction * 100)
		if not t then
			return
		end
		if t.genre == "decoration" then
			deco:selectionner(t.indice)
		else
			local r = deco:toucher(t.indicePiece, t.copie, t.u, t.v)
			if r.ok then
				Sons.jouer("decoration")
			else
				ctx.refus(r)
			end
		end
		rafraichir()
	end

	-- Appui sur la scène (hors interface) : touche si on ne bouge pas, sinon la vue tourne
	local appui = nil
	table.insert(connexions, UserInputService.InputBegan:Connect(function(input, traite)
		if traite or not ctx.fenetre.Visible then
			return
		end
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			appui = { objet = input, depart = input.Position, dernierX = input.Position.X, glisse = false }
		elseif input.KeyCode == Enum.KeyCode.Q or input.KeyCode == Enum.KeyCode.E then
			deco:tourner(input.KeyCode == Enum.KeyCode.Q and -15 or 15)
			rafraichir()
		end
	end))
	table.insert(connexions, UserInputService.InputChanged:Connect(function(input)
		if not appui then
			return
		end
		local suit = if appui.objet.UserInputType == Enum.UserInputType.Touch
			then input == appui.objet
			else input.UserInputType == Enum.UserInputType.MouseMovement
		if not suit then
			return
		end
		if not appui.glisse and (input.Position - appui.depart).Magnitude > SEUIL_GLISSER then
			appui.glisse = true
		end
		if appui.glisse then
			scene:orbiter((input.Position.X - appui.dernierX) * DEGRES_PAR_PX)
		end
		appui.dernierX = input.Position.X
	end))
	table.insert(connexions, UserInputService.InputEnded:Connect(function(input)
		if not appui then
			return
		end
		local fin = input == appui.objet
			or (appui.objet.UserInputType == Enum.UserInputType.MouseButton1 and input.UserInputType == Enum.UserInputType.MouseButton1)
		if fin then
			local a = appui
			appui = nil
			if not a.glisse then
				toucher(a.depart)
			end
		end
	end))

	rafraichir()
	return function()
		for _, c in ipairs(connexions) do
			c:Disconnect()
		end
	end
end
