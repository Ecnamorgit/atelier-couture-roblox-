-- Écran de la table de découpe : le rouleau vu de dessus (motif du tissu, pli, pièces déjà coupées,
-- tissu entamé), la pièce sélectionnée à glisser à la souris ou au doigt, la rotation (boutons, R, molette
-- sur la pièce), le déroulé (défilement, A et D), le droit-fil et la coupe.
-- La logique (position, aimantation, validité) est dans TableDecoupe.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")
local Couture = ReplicatedStorage:WaitForChild("Couture")
local Catalogue = require(Couture:WaitForChild("Catalogue"))
local Polygone = require(Couture:WaitForChild("Polygone"))
local TableDecoupe = require(script.Parent:WaitForChild("TableDecoupe"))
local Vignettes = require(script.Parent:WaitForChild("Vignettes"))

local PX = 36 -- pixels par dm : le rouleau de 14 dm fait 504 px de large
local ACHAT_RAPIDE = 5 -- dm ajoutés par le bouton « Plus de tissu »
local CALME = 0.4 -- s : un double clic ne coupe pas la pièce suivante, n'achète pas deux fois
local PAPIER = Color3.fromRGB(255, 248, 222) -- à défaut de silhouette (mémoire des images pleine)
local DEROULER = 2 -- dm par appui sur A ou D
local ACTION_DEROULER = "AtelierDerouler" -- A et D déroulent le rouleau (au lieu de faire marcher l'avatar)

local function taillePiece(idPiece)
	local b = Polygone.boite(Catalogue.piece(idPiece).contour)
	return UDim2.fromOffset((b.maxX - b.minX) * PX, (b.maxY - b.minY) * PX)
end

return function(ctx)
	local UiKit, session, contenu = ctx.UiKit, ctx.session, ctx.contenu
	local C = UiKit.COULEURS
	local table_ = TableDecoupe.nouvelle(session.etat)
	local connexions = {}

	-- Rouleau
	local vue = UiKit.creer("ScrollingFrame", {
		Name = "Rouleau",
		BackgroundColor3 = C.secondaire,
		BorderSizePixel = 0,
		Size = UDim2.new(0, 14 * PX + 12, 1, 0),
		CanvasSize = UDim2.new(),
		ScrollBarThickness = 10,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		Parent = contenu,
	})
	local tissuImage = UiKit.creer("ImageLabel", {
		Name = "Tissu",
		BorderSizePixel = 0,
		ScaleType = Enum.ScaleType.Tile,
		TileSize = UDim2.fromOffset(8 * PX, 8 * PX),
		Parent = vue,
	})
	local pli = UiKit.creer("Frame", { Name = "Pli", BackgroundColor3 = C.texte, BackgroundTransparency = 0.4, BorderSizePixel = 0, Position = UDim2.fromOffset(7 * PX - 1, 0), Size = UDim2.new(0, 2, 1, 0), ZIndex = 2, Parent = tissuImage })
	local calque = UiKit.creer("Frame", { Name = "Coupees", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 3, Parent = tissuImage })
	-- Tissu entamé : couper consomme le rouleau jusqu'au bas de la pièce la plus basse
	local ligneEntame = UiKit.creer("Frame", { Name = "Entame", BackgroundColor3 = C.alerte, BorderSizePixel = 0, AnchorPoint = Vector2.new(0, 0.5), Size = UDim2.new(1, 0, 0, 3), ZIndex = 4, Visible = false, Parent = tissuImage })
	local piece = UiKit.creer("ImageButton", { Name = "PieceCourante", BackgroundTransparency = 1, BackgroundColor3 = PAPIER, AnchorPoint = Vector2.new(0.5, 0.5), AutoButtonColor = false, ZIndex = 5, Parent = tissuImage })

	-- Panneau de droite
	local panneau = UiKit.creer("Frame", { Name = "Panneau", BackgroundTransparency = 1, Position = UDim2.fromOffset(14 * PX + 24, 0), Size = UDim2.new(1, -(14 * PX + 24), 1, 0), Parent = contenu })
	-- Onglets des tissus : une barre qui défile quand il y a plus de deux tissus
	local onglets = UiKit.creer("ScrollingFrame", { Name = "Onglets", BackgroundTransparency = 1, BorderSizePixel = 0, ScrollingDirection = Enum.ScrollingDirection.X, ScrollBarThickness = 10, ScrollBarImageColor3 = C.accent, Size = UDim2.new(1, 0, 0, 44), Parent = panneau })
	local liste = UiKit.creer("Frame", { Name = "ListePieces", BackgroundTransparency = 1, Position = UDim2.fromOffset(0, 46), Size = UDim2.new(1, 0, 0, 156), Parent = panneau })
	local droitFil = UiKit.texte({ Name = "DroitFil", Font = Enum.Font.GothamBold, Position = UDim2.fromOffset(0, 204), Size = UDim2.new(0.5, 0, 0, 22), Parent = panneau })
	local infoRouleau = UiKit.texte({ Name = "InfoRouleau", TextSize = 14, TextColor3 = C.texteDoux, TextXAlignment = Enum.TextXAlignment.Right, Position = UDim2.new(0.5, 0, 0, 204), Size = UDim2.new(0.5, 0, 0, 22), Parent = panneau })
	local statut = UiKit.texte({ Name = "Statut", TextSize = 14, Position = UDim2.fromOffset(0, 226), Size = UDim2.new(1, 0, 0, 36), Parent = panneau })

	local rafraichir, placerPiece
	-- Fait défiler le rouleau pour que la pièce sélectionnée soit en vue
	local function montrerPiece()
		if table_.placement then
			vue.CanvasPosition = Vector2.new(0, math.max(0, table_.placement.y * PX - 120))
		end
	end
	local function tourner(degres)
		table_:tourner(degres)
		placerPiece()
	end
	for k, r in ipairs({ { "« 15°", -15 }, { "« 1°", -1 }, { "1° »", 1 }, { "15° »", 15 } }) do
		UiKit.boutonDoux({ Name = "Tourner" .. r[2], Text = r[1], TextSize = 14, Position = UDim2.fromOffset((k - 1) * 82, 266), Size = UDim2.fromOffset(76, 34), Parent = panneau }, function()
			tourner(r[2])
		end)
	end
	UiKit.boutonDoux({ Name = "Proposer", Text = "Proposer une place", TextSize = 14, Position = UDim2.fromOffset(0, 306), Size = UDim2.fromOffset(160, 34), Parent = panneau }, function()
		table_:proposer()
		placerPiece()
		montrerPiece()
	end)
	UiKit.boutonDoux({ Name = "PlusDeTissu", Text = ("Plus de tissu (+%d dm)"):format(ACHAT_RAPIDE), TextSize = 14, Position = UDim2.fromOffset(166, 306), Size = UDim2.fromOffset(160, 34), Parent = panneau }, function()
		local r = session:acheter(table_.tissu, ACHAT_RAPIDE)
		if not r.ok then
			ctx.refus(r)
		end
	end, CALME)
	local couper = UiKit.bouton({ Name = "Couper", Text = "Couper", Position = UDim2.fromOffset(0, 348), Size = UDim2.new(1, 0, 0, 44), Parent = panneau }, function()
		local r = table_:couper(session)
		if not r.ok then
			ctx.refus(r)
		elseif session.etat.etape == "decoupe" then
			-- La session a prévenu l'écran avant que la table ne choisisse la pièce suivante : on redessine
			rafraichir()
			montrerPiece()
		end
	end, CALME)
	UiKit.boutonConfirme({ Name = "Recommencer", Text = "Recommencer la robe", TextSize = 14, AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), Size = UDim2.fromOffset(200, 34), Parent = panneau }, function()
		local r = session:recommencer()
		if not r.ok then
			ctx.refus(r)
		end
	end)

	placerPiece = function()
		local p = table_.placement
		piece.Visible = p ~= nil
		if not p then
			droitFil.Text = ""
			statut.Text = "Toutes les pièces de ce tissu sont coupées."
			return
		end
		local e = table_:etatPlacement()
		piece.Position = UDim2.fromOffset(p.x * PX, p.y * PX)
		piece.Size = taillePiece(table_.selection)
		piece.Rotation = p.angle
		local silhouette = Vignettes.silhouette(table_.selection)
		if silhouette then
			piece.ImageContent = silhouette
		end
		piece.BackgroundTransparency = silhouette and 1 or 0.35 -- sans silhouette : la boîte de la pièce, en papier
		piece.ImageColor3 = e.valide and Color3.new(1, 1, 1) or Color3.fromRGB(255, 120, 120)
		droitFil.Text = ("Droit-fil : %d %%"):format(math.floor(e.droitFil * 100 + 0.5))
		droitFil.TextColor3 = e.droitFil >= 0.999 and C.ok or (e.droitFil >= 0.7 and C.alerte or C.erreur)
		statut.Text = e.valide and "Place libre : tu peux couper." or e.erreur
		statut.TextColor3 = e.valide and C.ok or C.erreur
		couper.BackgroundColor3 = e.valide and C.accent or C.secondaire
		couper.TextColor3 = e.valide and Color3.new(1, 1, 1) or C.texteDoux
		couper.AutoButtonColor = e.valide
	end

	rafraichir = function()
		local etat = session.etat
		if etat.etape ~= "decoupe" then
			return
		end
		local coupon = table_:coupon()
		local tissu = Catalogue.tissu(table_.tissu)
		-- Tissu déroulé
		tissuImage.Size = UDim2.fromOffset(14 * PX, coupon.longueur * PX)
		tissuImage.BackgroundColor3 = UiKit.couleur(tissu.motif.couleurs[1])
		local motif = Vignettes.motif(table_.tissu)
		if motif then
			tissuImage.ImageContent = motif
		end
		vue.CanvasSize = UDim2.fromOffset(0, coupon.longueur * PX)
		local entame = coupon:longueurUtilisee()
		infoRouleau.Text = ("Entamé : %d / %d dm"):format(entame, coupon.longueur)
		ligneEntame.Visible = entame > 0
		ligneEntame.Position = UDim2.fromOffset(0, entame * PX)
		local plie = false
		for _, id in ipairs(table_:piecesRestantes()) do
			plie = plie or Catalogue.piece(id).pliee == true
		end
		pli.Visible = plie
		-- Pièces déjà coupées dans ce tissu (et leur symétrique si elles sont pliées ; le symétrique
		-- est approché par la même silhouette tournée en sens inverse)
		calque:ClearAllChildren()
		for id, p in pairs(etat.coupees) do
			if etat.tissus[id] == table_.tissu then
				local copies = { { x = p.x, angle = p.angle } }
				if Catalogue.piece(id).pliee then
					table.insert(copies, { x = 2 * Catalogue.PLI - p.x, angle = -p.angle })
				end
				for _, c in ipairs(copies) do
					local img = UiKit.creer("ImageLabel", {
						Name = "Coupee_" .. id,
						BackgroundTransparency = 1,
						AnchorPoint = Vector2.new(0.5, 0.5),
						Position = UDim2.fromOffset(c.x * PX, p.y * PX),
						Size = taillePiece(id),
						Rotation = c.angle,
						ImageColor3 = Color3.fromRGB(120, 120, 120),
						ImageTransparency = 0.3,
						ZIndex = 4,
						Parent = calque,
					})
					local silhouette = Vignettes.silhouette(id)
					if silhouette then
						img.ImageContent = silhouette
					else
						img.BackgroundColor3 = Color3.fromRGB(120, 120, 120)
						img.BackgroundTransparency = 0.5
					end
				end
			end
		end
		-- Onglets des tissus
		onglets:ClearAllChildren()
		for k, o in ipairs(table_:onglets()) do
			local actif = o.tissu == table_.tissu
			local b = UiKit.boutonDoux({ Name = "Onglet_" .. o.tissu, Text = ("%s (%d)"):format(Catalogue.tissu(o.tissu).nom, o.reste), TextSize = 14, Position = UDim2.fromOffset((k - 1) * 170, 0), Size = UDim2.fromOffset(164, 32), Parent = onglets }, function()
				table_:choisirTissu(o.tissu)
				rafraichir()
				montrerPiece()
			end)
			b.BackgroundColor3 = actif and C.accent or C.secondaire
			b.TextColor3 = actif and Color3.new(1, 1, 1) or C.texte
		end
		onglets.CanvasSize = UDim2.fromOffset(#table_:onglets() * 170, 0)
		-- Pièces restantes de ce tissu
		liste:ClearAllChildren()
		for k, id in ipairs(table_:piecesRestantes()) do
			local actif = id == table_.selection
			local b = UiKit.boutonDoux({ Name = "Piece_" .. id, Text = Catalogue.piece(id).nom .. (Catalogue.piece(id).pliee and " (pliée)" or ""), TextSize = 14, Position = UDim2.fromOffset(0, (k - 1) * 26), Size = UDim2.new(1, 0, 0, 24), Parent = liste }, function()
				table_:selectionner(id)
				rafraichir()
				montrerPiece()
			end)
			b.BackgroundColor3 = actif and C.accent or C.panneau
			b.TextColor3 = actif and Color3.new(1, 1, 1) or C.texte
		end
		placerPiece()
	end

	-- Glisser la pièce (souris ou doigt). La fenêtre peut être réduite (UIScale sur petit écran) :
	-- on convertit avec la taille réelle du rouleau à l'écran, et on garde l'écart entre le doigt
	-- et le centre de la pièce au moment où on la saisit. Pendant la saisie, le rouleau ne défile pas,
	-- et seul le doigt qui tient la pièce la déplace.
	local saisie, ecartX, ecartY = nil, 0, 0
	local survol = false -- souris sur la pièce : la molette la tourne, le rouleau ne défile pas
	local function versRouleau(position)
		local pxEcran = tissuImage.AbsoluteSize.X / 14
		local x = (position.X - tissuImage.AbsolutePosition.X) / pxEcran
		local y = (position.Y - tissuImage.AbsolutePosition.Y) / pxEcran
		return x, y
	end
	local function lacher()
		-- Au doigt, « MouseLeave » n'arrive souvent qu'au toucher suivant : la pièce lâchée, plus de survol
		if saisie and saisie.UserInputType == Enum.UserInputType.Touch then
			survol = false
		end
		saisie = nil
		vue.ScrollingEnabled = not survol
	end
	table.insert(connexions, piece.InputBegan:Connect(function(input)
		if table_.placement and not saisie and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
			local x, y = versRouleau(input.Position)
			ecartX, ecartY = table_.placement.x - x, table_.placement.y - y
			saisie = input
			vue.ScrollingEnabled = false
		end
	end))
	table.insert(connexions, UserInputService.InputChanged:Connect(function(input)
		if not saisie then
			return
		end
		local suit = if saisie.UserInputType == Enum.UserInputType.Touch
			then input == saisie
			else input.UserInputType == Enum.UserInputType.MouseMovement
		if suit then
			local x, y = versRouleau(input.Position)
			table_:deplacer(x + ecartX, y + ecartY)
			placerPiece()
		end
	end))
	table.insert(connexions, UserInputService.InputEnded:Connect(function(input)
		if saisie and (input == saisie or (saisie.UserInputType == Enum.UserInputType.MouseButton1 and input.UserInputType == Enum.UserInputType.MouseButton1)) then
			lacher()
		end
	end))
	-- Molette sur la pièce : tourner de 15° (vers le haut : sens des aiguilles d'une montre)
	table.insert(connexions, piece.MouseEnter:Connect(function()
		survol = true
		vue.ScrollingEnabled = false
	end))
	table.insert(connexions, piece.MouseLeave:Connect(function()
		survol = false
		vue.ScrollingEnabled = saisie == nil
	end))
	table.insert(connexions, piece.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseWheel and ctx.fenetre.Visible and table_.placement then
			tourner(input.Position.Z > 0 and 15 or -15)
		end
	end))
	-- R (fenêtre ouverte) : tourner de 15° (Maj + R : dans l'autre sens)
	table.insert(connexions, UserInputService.InputBegan:Connect(function(input, traite)
		if not traite and ctx.fenetre.Visible and input.KeyCode == Enum.KeyCode.R then
			local inverse = UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) or UserInputService:IsKeyDown(Enum.KeyCode.RightShift)
			tourner(inverse and -15 or 15)
		end
	end))
	-- A et D : dérouler le rouleau (2 dm plus loin) ou revenir. Liées seulement quand la fenêtre est
	-- visible, et absorbées : l'avatar ne marche pas pendant ce temps.
	local function lierDerouler(actif)
		if not actif then
			ContextActionService:UnbindAction(ACTION_DEROULER)
			return
		end
		ContextActionService:BindActionAtPriority(ACTION_DEROULER, function(_, etatEntree, input)
			if etatEntree == Enum.UserInputState.Begin then
				local sens = input.KeyCode == Enum.KeyCode.D and 1 or -1
				local y = math.clamp(vue.CanvasPosition.Y + sens * DEROULER * PX, 0, vue.CanvasSize.Y.Offset)
				vue.CanvasPosition = Vector2.new(0, y)
			end
			return Enum.ContextActionResult.Sink
		end, false, Enum.ContextActionPriority.High.Value, Enum.KeyCode.A, Enum.KeyCode.D)
	end
	local function surVisibilite()
		lierDerouler(ctx.fenetre.Visible)
	end
	table.insert(connexions, ctx.fenetre:GetPropertyChangedSignal("Visible"):Connect(surVisibilite))
	surVisibilite()

	local desabonner = session:surChangement(function()
		rafraichir()
		montrerPiece()
	end)
	rafraichir()
	montrerPiece()
	return function()
		desabonner()
		lierDerouler(false)
		for _, c in ipairs(connexions) do
			c:Disconnect()
		end
	end
end
