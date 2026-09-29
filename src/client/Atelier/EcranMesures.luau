-- Écran des mesures (sous-projet 2) : la silhouette de la cliente, de face, dessinée à ses vraies mesures, et
-- trois rubans (poitrine, taille, hanches) qui partent de son bord gauche. On règle chaque ruban jusqu'au bord
-- droit de la silhouette : en faisant glisser sa poignée, ou avec − et + (0,1 dm de tour). La mesure lue
-- s'affiche en centimètres. « Valider les mesures » les envoie au serveur, qui refuse un ruban trop loin ; une
-- cliente déjà mesurée peut « Reprendre ses mesures ».
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Couture = ReplicatedStorage:WaitForChild("Couture")
local Catalogue = require(Couture:WaitForChild("Catalogue"))
local Clientes = require(Couture:WaitForChild("Clientes"))

local MESURES = { { cle = "poitrine", nom = "Poitrine", y = 110 }, { cle = "taille", nom = "Taille", y = 190 }, { cle = "hanches", nom = "Hanches", y = 270 } }
local LARGEUR = 320 -- px : largeur de la silhouette
local PX = 70 -- px par dm de largeur de face
local FACE = 0.32 -- largeur de face d'un tour : un tour de 9 dm fait 2,9 dm de large, vu de face
local DEPART = 0.7 -- les rubans partent à 70 % de la mesure de sa taille : il faut vraiment mesurer
local PAS = 0.1 -- dm de tour par appui sur − ou +
local RUBAN = Color3.fromRGB(250, 210, 70)

local function arrondi(v)
	return math.round(v * 10) / 10
end

return function(ctx)
	local UiKit, session, contenu = ctx.UiKit, ctx.session, ctx.contenu
	local C = UiKit.COULEURS
	local etat = session.etat
	local cliente = Clientes.get(etat.commande.cliente)
	local fiche = etat.clientes[cliente.id]
	local connexions = {}
	local prises, rubans = {}, {}

	UiKit.texte({
		Name = "Consigne",
		Text = ("Mesure %s : fais glisser chaque ruban jusqu'au bord de sa silhouette (ou règle-le avec − et +)."):format(cliente.nom),
		TextSize = 16,
		Size = UDim2.new(1, 0, 0, 44),
		Parent = contenu,
	})

	-- La silhouette : tête, cou, puis buste, taille et hanches, chacun à la largeur de sa vraie mesure
	local silhouette = UiKit.arrondir(UiKit.creer("Frame", { Name = "Silhouette", BackgroundColor3 = C.panneau, Position = UDim2.fromOffset(0, 50), Size = UDim2.fromOffset(LARGEUR, 340), Parent = contenu }), 10)
	local centre = LARGEUR / 2
	UiKit.arrondir(UiKit.creer("Frame", { Name = "Tete", BackgroundColor3 = cliente.tenue.peau, BorderSizePixel = 0, Position = UDim2.fromOffset(centre - 26, 6), Size = UDim2.fromOffset(52, 58), Parent = silhouette }), 26)
	UiKit.creer("Frame", { Name = "Cou", BackgroundColor3 = cliente.tenue.peau, BorderSizePixel = 0, Position = UDim2.fromOffset(centre - 10, 62), Size = UDim2.fromOffset(20, 10), Parent = silhouette })
	for i, m in ipairs(MESURES) do
		local largeur = cliente.mesures[m.cle] * FACE * PX
		UiKit.creer("Frame", {
			Name = "Corps_" .. m.cle,
			BackgroundColor3 = if i < 3 then cliente.tenue.haut else cliente.tenue.bas,
			BorderSizePixel = 0,
			Position = UDim2.fromOffset(centre - largeur / 2, m.y - 40),
			Size = UDim2.fromOffset(largeur, 80),
			Parent = silhouette,
		})
	end

	-- Les rubans, partis du bord gauche de la silhouette, et leurs réglages à droite
	local function maj(cle)
		local r = rubans[cle]
		local largeur = prises[cle] * FACE * PX
		r.ruban.Size = UDim2.fromOffset(largeur, 8)
		r.poignee.Position = UDim2.fromOffset(r.ruban.Position.X.Offset + largeur, r.ruban.Position.Y.Offset + 4)
		r.valeur.Text = ("%s : %d cm"):format(r.nom, math.round(prises[cle] * 10))
	end
	local function regler(cle, valeur)
		prises[cle] = math.clamp(arrondi(valeur), 2, 15)
		maj(cle)
	end
	for _, m in ipairs(MESURES) do
		local cle = m.cle
		prises[cle] = arrondi(Catalogue.TAILLES[cliente.taille][cle] * DEPART)
		local vraieLargeur = cliente.mesures[cle] * FACE * PX
		local ruban = UiKit.creer("Frame", { Name = "Ruban_" .. cle, BackgroundColor3 = RUBAN, BorderSizePixel = 0, Position = UDim2.fromOffset(centre - vraieLargeur / 2, m.y - 4), ZIndex = 3, Parent = silhouette })
		local poignee = UiKit.arrondir(UiKit.creer("TextButton", { Name = "Poignee_" .. cle, Text = "", AutoButtonColor = false, BackgroundColor3 = C.accent, AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(24, 24), ZIndex = 4, Parent = silhouette }), 12)
		local y = 50 + m.y - 18
		local valeur = UiKit.texte({ Name = "Valeur_" .. cle, Font = Enum.Font.GothamBold, TextSize = 18, Position = UDim2.fromOffset(LARGEUR + 30, y), Size = UDim2.fromOffset(220, 36), Parent = contenu })
		UiKit.boutonDoux({ Name = "Moins_" .. cle, Text = "−", TextSize = 22, Position = UDim2.fromOffset(LARGEUR + 260, y), Size = UDim2.fromOffset(44, 36), Parent = contenu }, function()
			regler(cle, prises[cle] - PAS)
		end)
		UiKit.boutonDoux({ Name = "Plus_" .. cle, Text = "+", TextSize = 22, Position = UDim2.fromOffset(LARGEUR + 312, y), Size = UDim2.fromOffset(44, 36), Parent = contenu }, function()
			regler(cle, prises[cle] + PAS)
		end)
		rubans[cle] = { ruban = ruban, poignee = poignee, valeur = valeur, nom = m.nom }
		maj(cle)
		-- Glisser la poignée (souris ou doigt) : la largeur à l'écran, ramenée à l'échelle de la fenêtre
		table.insert(connexions, poignee.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				rubans.saisie = { cle = cle, input = input }
			end
		end))
	end
	table.insert(connexions, UserInputService.InputChanged:Connect(function(input)
		local saisie = rubans.saisie
		if not saisie then
			return
		end
		local suit = if saisie.input.UserInputType == Enum.UserInputType.Touch then input == saisie.input else input.UserInputType == Enum.UserInputType.MouseMovement
		local taille, debut = silhouette.AbsoluteSize, rubans[saisie.cle].ruban.AbsolutePosition
		if suit and taille and debut and taille.X > 0 then
			local echelle = taille.X / LARGEUR
			regler(saisie.cle, (input.Position.X - debut.X) / echelle / (FACE * PX))
		end
	end))
	table.insert(connexions, UserInputService.InputEnded:Connect(function(input)
		local saisie = rubans.saisie
		if saisie and (input == saisie.input or (saisie.input.UserInputType == Enum.UserInputType.MouseButton1 and input.UserInputType == Enum.UserInputType.MouseButton1)) then
			rubans.saisie = nil
		end
	end))

	UiKit.bouton({ Name = "ValiderMesures", Text = "Valider les mesures", AnchorPoint = Vector2.new(1, 1), Position = UDim2.fromScale(1, 1), Size = UDim2.fromOffset(240, 46), Parent = contenu }, function()
		local r = session:mesurer({ poitrine = prises.poitrine, taille = prises.taille, hanches = prises.hanches })
		if not r.ok then
			ctx.refus(r)
		end
	end, 0.4)
	if fiche and fiche.mesures then
		UiKit.texte({ Text = "Ses mesures sont déjà dans ton carnet.", TextSize = 14, TextColor3 = C.texteDoux, Position = UDim2.fromOffset(LARGEUR + 30, 380), Size = UDim2.fromOffset(330, 22), Parent = contenu })
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
