-- Écran d'achat : pour chaque tissu du croquis, métrage conseillé, stock, quantité à acheter et coût.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Couture = ReplicatedStorage:WaitForChild("Couture")
local Catalogue = require(Couture:WaitForChild("Catalogue"))
local Metrage = require(Couture:WaitForChild("Metrage"))
local EtatAtelier = require(Couture:WaitForChild("EtatAtelier"))
local Vignettes = require(script.Parent:WaitForChild("Vignettes"))

return function(ctx)
	local UiKit, session, contenu = ctx.UiKit, ctx.session, ctx.contenu
	local C = UiKit.COULEURS
	local etat = session.etat

	UiKit.texte({
		Text = "Le métrage conseillé suffit si tu ranges bien tes pièces. Le tissu en trop reste dans ton stock.",
		TextSize = 14,
		TextColor3 = C.texteDoux,
		Size = UDim2.new(1, 0, 0, 22),
		Parent = contenu,
	})

	-- Une ligne par tissu, dans une liste qui défile au-dessus des boutons du bas
	local HAUTEUR_LIGNE = 84
	local liste = UiKit.creer("ScrollingFrame", {
		Name = "Lignes",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 6,
		Position = UDim2.fromOffset(0, 32),
		Size = UDim2.new(1, 0, 1, -32 - 56),
		CanvasSize = UDim2.fromOffset(0, #etat:tissusUtilises() * HAUTEUR_LIGNE),
		Parent = contenu,
	})
	local lignes = {}
	local quantites = {}
	local function conseil(idTissu)
		local ids = {}
		for _, id in ipairs(etat:piecesDuCroquis()) do
			if etat.tissus[id] == idTissu then
				table.insert(ids, id)
			end
		end
		return Metrage.conseil(ids)
	end

	local function majLigne(idTissu)
		local l = lignes[idTissu]
		local stock = etat.stock[idTissu] or 0
		local q = quantites[idTissu]
		l.infos.Text = ("Conseillé : %d dm · En stock : %d dm"):format(conseil(idTissu), stock)
		l.quantite.Text = ("%d dm"):format(q)
		l.cout.Text = q > 0 and ("%d po"):format(EtatAtelier.prix(idTissu, q)) or "—"
		l.acheter.AutoButtonColor = q > 0
		l.acheter.BackgroundColor3 = q > 0 and C.accent or C.secondaire
	end

	for i, idTissu in ipairs(etat:tissusUtilises()) do
		local t = Catalogue.tissu(idTissu)
		quantites[idTissu] = math.max(0, conseil(idTissu) - (etat.stock[idTissu] or 0))
		local ligne = UiKit.arrondir(UiKit.creer("Frame", { Name = "Ligne_" .. idTissu, BackgroundColor3 = C.panneau, Position = UDim2.fromOffset(0, (i - 1) * HAUTEUR_LIGNE), Size = UDim2.new(1, -10, 0, 76), Parent = liste }), 10)
		local echantillon = UiKit.arrondir(UiKit.creer("ImageLabel", {
			BackgroundColor3 = UiKit.couleur(t.motif.couleurs[1]),
			Position = UDim2.fromOffset(10, 10),
			Size = UDim2.fromOffset(80, 56),
			ScaleType = Enum.ScaleType.Tile,
			TileSize = UDim2.fromOffset(64, 64),
			Parent = ligne,
		}), 6)
		local motif = Vignettes.motif(idTissu)
		if motif then
			echantillon.ImageContent = motif
		end
		UiKit.texte({ Text = ("%s — %d po/m"):format(t.nom, t.prix), Font = Enum.Font.GothamBold, Position = UDim2.fromOffset(102, 10), Size = UDim2.fromOffset(320, 24), Parent = ligne })
		local l = { infos = UiKit.texte({ TextSize = 14, TextColor3 = C.texteDoux, Position = UDim2.fromOffset(102, 40), Size = UDim2.fromOffset(320, 24), Parent = ligne }) }
		UiKit.boutonDoux({ Name = "Moins", Text = "−", TextSize = 22, Position = UDim2.fromOffset(440, 20), Size = UDim2.fromOffset(40, 36), Parent = ligne }, function()
			quantites[idTissu] = math.max(0, quantites[idTissu] - 1)
			majLigne(idTissu)
		end)
		l.quantite = UiKit.texte({ Name = "Quantite", TextXAlignment = Enum.TextXAlignment.Center, Font = Enum.Font.GothamBold, Position = UDim2.fromOffset(484, 26), Size = UDim2.fromOffset(70, 24), Parent = ligne })
		UiKit.boutonDoux({ Name = "Plus", Text = "+", TextSize = 22, Position = UDim2.fromOffset(558, 20), Size = UDim2.fromOffset(40, 36), Parent = ligne }, function()
			quantites[idTissu] = math.min(EtatAtelier.ACHAT_MAX, quantites[idTissu] + 1)
			majLigne(idTissu)
		end)
		l.cout = UiKit.texte({ Name = "Cout", TextXAlignment = Enum.TextXAlignment.Right, Position = UDim2.fromOffset(606, 26), Size = UDim2.fromOffset(70, 24), Parent = ligne })
		l.acheter = UiKit.bouton({ Name = "Acheter", Text = "Acheter", Position = UDim2.new(1, -150, 0, 18), Size = UDim2.fromOffset(136, 40), Parent = ligne }, function()
			local q = quantites[idTissu]
			if q < 1 then
				return
			end
			local r = session:acheter(idTissu, q)
			if r.ok then
				quantites[idTissu] = 0
				majLigne(idTissu)
				ctx.message(("Acheté : %d dm de %s (%d po)."):format(q, t.nom, r.prix), C.ok)
			else
				ctx.refus(r)
			end
		end, 0.4)
		lignes[idTissu] = l
		majLigne(idTissu)
	end

	UiKit.boutonDoux({ Name = "RetourCarnet", Text = "Retour au carnet", AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), Size = UDim2.fromOffset(200, 46), Parent = contenu }, function()
		local r = session:retourCarnet()
		if not r.ok then
			ctx.refus(r)
		end
	end)
	UiKit.bouton({ Name = "AllerDecoupe", Text = "Aller à la découpe", AnchorPoint = Vector2.new(1, 1), Position = UDim2.fromScale(1, 1), Size = UDim2.fromOffset(240, 46), Parent = contenu }, function()
		local r = session:commencerDecoupe()
		if not r.ok then
			ctx.refus(r)
		end
	end)
	return function() end
end
