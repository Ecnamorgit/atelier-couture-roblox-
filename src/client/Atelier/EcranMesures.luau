-- Écran des mesures (sous-projet 6 : le mannequin à molettes) : un mannequin de couture, de face, et par-dessus, en
-- pointillé, la silhouette de la cliente à ses vraies mesures. Trois molettes (poitrine, taille, hanches) élargissent
-- ou resserrent le mannequin : on les tourne en glissant de haut en bas (souris ou doigt), à la molette de la souris,
-- ou avec − et + (0,1 dm de tour), jusqu'à ce que le mannequin épouse la silhouette ; la mesure s'affiche en
-- centimètres. « Valider les mesures » les envoie au serveur, qui refuse une mesure trop loin de la vraie ; une
-- cliente déjà mesurée peut « Reprendre ses mesures ».
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Couture = ReplicatedStorage:WaitForChild("Couture")
local Catalogue = require(Couture:WaitForChild("Catalogue"))
local Clientes = require(Couture:WaitForChild("Clientes"))
local Molette = require(script.Parent:WaitForChild("Molette"))

local MESURES = { { cle = "poitrine", nom = "Poitrine", y = 110 }, { cle = "taille", nom = "Taille", y = 190 }, { cle = "hanches", nom = "Hanches", y = 270 } }
local LARGEUR = 320 -- px : largeur du cadre du mannequin
local PX = 70 -- px par dm de largeur de face
local FACE = 0.32 -- largeur de face d'un tour : un tour de 9 dm fait 2,9 dm de large, vu de face
local DEPART = 0.7 -- le mannequin part à 70 % de la mesure de sa taille : il faut vraiment mesurer
local MINI = 2 -- dm de tour
local TAILLE_MOLETTE = 64 -- px (au moins 56 : le doigt)
local TOILE = Color3.fromRGB(232, 214, 186) -- la toile du mannequin
local BOIS = Color3.fromRGB(150, 110, 75)
local RUBAN = Color3.fromRGB(250, 210, 70)
local POINTILLE = Color3.fromRGB(110, 70, 96)
local PAS_POINTS = 10 -- px entre deux points du pointillé

return function(ctx)
	local UiKit, session, contenu = ctx.UiKit, ctx.session, ctx.contenu
	local C = UiKit.COULEURS
	local etat = session.etat
	local cliente = Clientes.get(etat.commande.cliente)
	local fiche = etat.clientes[cliente.id]
	local connexions = {}
	local molettes, elements = {}, {}
	local saisie, survol = nil, nil

	UiKit.texte({
		Name = "Consigne",
		Text = ("Mesure %s : tourne chaque molette jusqu'à ce que le mannequin épouse sa silhouette, en pointillé (ou règle-le avec − et +)."):format(cliente.nom),
		TextSize = 16,
		Size = UDim2.new(1, 0, 0, 44),
		Parent = contenu,
	})

	-- Le mannequin : son pied, sa colonne, son cou, et le buste, la taille et les hanches, à la largeur des molettes
	local mannequin = UiKit.arrondir(UiKit.creer("Frame", { Name = "Mannequin", BackgroundColor3 = C.panneau, Position = UDim2.fromOffset(0, 50), Size = UDim2.fromOffset(LARGEUR, 340), Parent = contenu }), 10)
	local centre = LARGEUR / 2
	UiKit.creer("Frame", { Name = "Colonne", BackgroundColor3 = BOIS, BorderSizePixel = 0, Position = UDim2.fromOffset(centre - 4, 300), Size = UDim2.fromOffset(8, 30), Parent = mannequin })
	UiKit.arrondir(UiKit.creer("Frame", { Name = "Pied", BackgroundColor3 = BOIS, BorderSizePixel = 0, Position = UDim2.fromOffset(centre - 40, 326), Size = UDim2.fromOffset(80, 8), Parent = mannequin }), 4)
	UiKit.arrondir(UiKit.creer("Frame", { Name = "Cou", BackgroundColor3 = TOILE, BorderSizePixel = 0, Position = UDim2.fromOffset(centre - 12, 44), Size = UDim2.fromOffset(24, 26), Parent = mannequin }), 6)
	UiKit.arrondir(UiKit.creer("Frame", { Name = "Bouchon", BackgroundColor3 = BOIS, BorderSizePixel = 0, Position = UDim2.fromOffset(centre - 16, 36), Size = UDim2.fromOffset(32, 10), Parent = mannequin }), 5)

	-- La silhouette de la cliente, en pointillé par-dessus le mannequin (comme un calque) : ses bords gauche et droit, à
	-- chaque mesure, et le haut et le bas de chaque bande
	local function pointille(parent, x0, y0, x1, y1)
		local n = math.max(1, math.floor(math.max(math.abs(x1 - x0), math.abs(y1 - y0)) / PAS_POINTS))
		for k = 0, n do
			UiKit.creer("Frame", { Name = "Point", BackgroundColor3 = POINTILLE, BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(x0 + (x1 - x0) * k / n, y0 + (y1 - y0) * k / n), Size = UDim2.fromOffset(3, 3), ZIndex = 5, Parent = parent })
		end
	end
	for _, m in ipairs(MESURES) do
		local largeur = cliente.mesures[m.cle] * FACE * PX
		local calque = UiKit.creer("Frame", { Name = "Calque_" .. m.cle, BackgroundTransparency = 1, Position = UDim2.fromOffset(centre - largeur / 2, m.y - 40), Size = UDim2.fromOffset(largeur, 80), ZIndex = 5, Parent = mannequin })
		pointille(calque, 0, 0, 0, 80)
		pointille(calque, largeur, 0, largeur, 80)
	end

	-- Une bande du mannequin, son mètre ruban, sa molette et sa mesure
	local function maj(cle)
		local e, m = elements[cle], molettes[cle]
		local largeur = m.valeur * FACE * PX
		e.corps.Position = UDim2.fromOffset(centre - largeur / 2, e.y - 40)
		e.corps.Size = UDim2.fromOffset(largeur, 80)
		e.ruban.Position = UDim2.fromOffset(centre - largeur / 2, e.y - 3)
		e.ruban.Size = UDim2.fromOffset(largeur, 6)
		e.fente.Rotation = m:angle()
		e.valeur.Text = ("%s : %d cm"):format(e.nom, math.round(m.valeur * 10))
	end
	local maxi = math.floor(LARGEUR / (FACE * PX) * 10) / 10 -- (le mannequin ne sort pas de son cadre)
	for i, mesure in ipairs(MESURES) do
		local cle = mesure.cle
		molettes[cle] = Molette.nouvelle(Catalogue.TAILLES[cliente.taille][cle] * DEPART, MINI, maxi)
		local corps = UiKit.arrondir(UiKit.creer("Frame", { Name = "Corps_" .. cle, BackgroundColor3 = TOILE, BorderSizePixel = 0, ZIndex = if i == 2 then 3 else 2, Parent = mannequin }), 18) -- (des bandes arrondies : un buste de couturière)
		local ruban = UiKit.creer("Frame", { Name = "Ruban_" .. cle, BackgroundColor3 = RUBAN, BorderSizePixel = 0, ZIndex = 4, Parent = mannequin })
		local y = 50 + mesure.y - TAILLE_MOLETTE / 2
		-- La molette : un bouton rond (un bouton, pas un cadre : l'appui ne passe pas dessous), sa fente qui tourne
		local bouton = UiKit.arrondir(UiKit.creer("TextButton", { Name = "Molette_" .. cle, Text = "", AutoButtonColor = false, BackgroundColor3 = BOIS, Position = UDim2.fromOffset(LARGEUR + 30, y), Size = UDim2.fromOffset(TAILLE_MOLETTE, TAILLE_MOLETTE), Parent = contenu }), TAILLE_MOLETTE / 2)
		UiKit.creer("UIStroke", { Color = Color3.fromRGB(110, 78, 50), Thickness = 3, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = bouton })
		local fente = UiKit.creer("Frame", { Name = "Fente", BackgroundColor3 = Color3.fromRGB(70, 48, 30), BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(6, TAILLE_MOLETTE - 18), Parent = bouton })
		local valeur = UiKit.texte({ Name = "Valeur_" .. cle, Font = Enum.Font.GothamBold, TextSize = 18, Position = UDim2.fromOffset(LARGEUR + 110, y + 14), Size = UDim2.fromOffset(200, 36), Parent = contenu })
		UiKit.boutonDoux({ Name = "Moins_" .. cle, Text = "−", TextSize = 22, Position = UDim2.fromOffset(LARGEUR + 320, y + 14), Size = UDim2.fromOffset(44, 36), Parent = contenu }, function()
			molettes[cle]:crans(-1)
			maj(cle)
		end)
		UiKit.boutonDoux({ Name = "Plus_" .. cle, Text = "+", TextSize = 22, Position = UDim2.fromOffset(LARGEUR + 372, y + 14), Size = UDim2.fromOffset(44, 36), Parent = contenu }, function()
			molettes[cle]:crans(1)
			maj(cle)
		end)
		elements[cle] = { corps = corps, ruban = ruban, fente = fente, valeur = valeur, nom = mesure.nom, y = mesure.y }
		maj(cle)
		-- Glisser sur la molette (souris ou doigt) ; la molette de la souris quand le pointeur est dessus
		table.insert(connexions, bouton.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				saisie = { cle = cle, input = input, y = input.Position.Y }
			end
		end))
		table.insert(connexions, bouton.MouseEnter:Connect(function()
			survol = cle
		end))
		table.insert(connexions, bouton.MouseLeave:Connect(function()
			if survol == cle then
				survol = nil
			end
		end))
	end
	table.insert(connexions, UserInputService.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseWheel then
			if survol and input.Position.Z ~= 0 then
				molettes[survol]:crans(if input.Position.Z > 0 then 1 else -1)
				maj(survol)
			end
			return
		end
		if not saisie then
			return
		end
		local suit = if saisie.input.UserInputType == Enum.UserInputType.Touch then input == saisie.input else input.UserInputType == Enum.UserInputType.MouseMovement
		local taille = mannequin.AbsoluteSize
		if suit and taille and taille.X > 0 then
			local echelle = taille.X / LARGEUR -- (la fenêtre est réduite sur les petits écrans)
			molettes[saisie.cle]:glisser((input.Position.Y - saisie.y) / echelle)
			saisie.y = input.Position.Y
			maj(saisie.cle)
		end
	end))
	table.insert(connexions, UserInputService.InputEnded:Connect(function(input)
		if saisie and (input == saisie.input or (saisie.input.UserInputType == Enum.UserInputType.MouseButton1 and input.UserInputType == Enum.UserInputType.MouseButton1)) then
			saisie = nil
		end
	end))

	UiKit.bouton({ Name = "ValiderMesures", Text = "Valider les mesures", AnchorPoint = Vector2.new(1, 1), Position = UDim2.fromScale(1, 1), Size = UDim2.fromOffset(240, 46), Parent = contenu }, function()
		local r = session:mesurer({ poitrine = molettes.poitrine.valeur, taille = molettes.taille.valeur, hanches = molettes.hanches.valeur })
		if not r.ok then
			ctx.refus(r)
		end
	end, 0.4)
	if fiche and fiche.mesures then
		-- La fiche du carnet : ses mesures de la dernière fois
		local d = fiche.mesures
		UiKit.texte({ Name = "FicheCarnet", Text = ("Au carnet : %d / %d / %d cm (ajustement %d %%)."):format(math.round(d.poitrine * 10), math.round(d.taille * 10), math.round(d.hanches * 10), math.floor((fiche.ajustement or 1) * 100 + 0.5)), TextSize = 14, TextColor3 = C.texteDoux, Position = UDim2.fromOffset(LARGEUR + 30, 380), Size = UDim2.fromOffset(420, 22), Parent = contenu })
		UiKit.boutonDoux({ Name = "ReprendreMesures", Text = "Reprendre ses mesures", AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, LARGEUR + 30, 1, 0), Size = UDim2.fromOffset(240, 46), Parent = contenu }, function()
			local r = session:reprendreMesures()
			if not r.ok then
				ctx.refus(r)
			end
		end, 0.4)
	end

	return function()
		for _, c in ipairs(connexions) do
			c:Disconnect()
		end
	end
end
