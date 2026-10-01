-- Écran d'achat : pour chaque tissu du croquis, métrage conseillé, stock (le tissu neuf, s'il est entamé), quantité à
-- acheter et coût.
-- Toucher l'échantillon d'un tissu montre le rouleau conseillé, avec les pièces rangées dessus.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Couture = ReplicatedStorage:WaitForChild("Couture")
local Catalogue = require(Couture:WaitForChild("Catalogue"))
local Polygone = require(Couture:WaitForChild("Polygone"))
local Metrage = require(Couture:WaitForChild("Metrage"))
local EtatAtelier = require(Couture:WaitForChild("EtatAtelier"))
local Deblocages = require(Couture:WaitForChild("Deblocages"))
local Vignettes = require(script.Parent:WaitForChild("Vignettes"))

local PX_APERCU = 20 -- pixels par dm dans l'aperçu du rouleau (14 dm de large : 280 px)

return function(ctx)
	local UiKit, session, contenu = ctx.UiKit, ctx.session, ctx.contenu
	local C = UiKit.COULEURS
	local etat = session.etat

	UiKit.texte({
		Text = "Le métrage conseillé suffit si tu ranges bien tes pièces. Touche un échantillon pour voir le rouleau.",
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
	local stocksVus = {} -- stock de chaque tissu au dernier calcul de la quantité proposée
	local function piecesDe(idTissu)
		local ids = {}
		for _, id in ipairs(etat:piecesDuCroquis()) do
			if etat.tissus[id] == idTissu then
				table.insert(ids, id)
			end
		end
		return ids
	end
	local function conseil(idTissu)
		return Metrage.conseil(piecesDe(idTissu))
	end

	-- Aperçu du rouleau (par-dessus la liste) : le métrage conseillé, les pièces rangées comme le conseil
	-- les compte (droit-fil parfait), et leur symétrique pour une pièce coupée pliée. Un bouton sans texte,
	-- pas un simple cadre : dans Roblox, un cadre laisse passer l'appui aux boutons cachés dessous.
	-- « Fermer » est en haut, au-dessus de la liste : un double appui ne touche aucun bouton.
	local apercu
	local function fermerApercu()
		if apercu then
			apercu:Destroy()
			apercu = nil
		end
	end
	local function ouvrirApercu(idTissu)
		fermerApercu()
		local t = Catalogue.tissu(idTissu)
		local ids = piecesDe(idTissu)
		local placements, longueur = Metrage.disposition(ids)
		apercu = UiKit.creer("TextButton", { Name = "ApercuRouleau", Text = "", AutoButtonColor = false, BackgroundColor3 = C.fond, BorderSizePixel = 0, Size = UDim2.fromScale(1, 1), ZIndex = 20, Parent = contenu })
		UiKit.texte({ Name = "Titre", Text = ("%s : %d dm conseillés"):format(t.nom, longueur), Font = Enum.Font.GothamBold, Size = UDim2.new(1, -150, 0, 30), ZIndex = 21, Parent = apercu })
		UiKit.boutonDoux({ Name = "FermerRouleau", Text = "Fermer", TextSize = 14, Position = UDim2.new(1, -140, 0, 0), Size = UDim2.fromOffset(140, 30), ZIndex = 21, Parent = apercu }, fermerApercu)
		local vue = UiKit.creer("ScrollingFrame", {
			Name = "Vue",
			BackgroundColor3 = C.secondaire,
			BorderSizePixel = 0,
			Position = UDim2.fromOffset(0, 40),
			Size = UDim2.new(0, 14 * PX_APERCU + 12, 1, -40),
			CanvasSize = UDim2.fromOffset(0, longueur * PX_APERCU),
			ScrollBarThickness = 10,
			ScrollingDirection = Enum.ScrollingDirection.Y,
			ZIndex = 21,
			Parent = apercu,
		})
		local rouleau = UiKit.creer("ImageLabel", {
			Name = "Rouleau",
			BorderSizePixel = 0,
			BackgroundColor3 = UiKit.couleur(t.motif.couleurs[1]),
			ScaleType = Enum.ScaleType.Tile,
			TileSize = UDim2.fromOffset(8 * PX_APERCU, 8 * PX_APERCU),
			Size = UDim2.fromOffset(14 * PX_APERCU, longueur * PX_APERCU),
			ZIndex = 21,
			Parent = vue,
		})
		local motif = Vignettes.motif(idTissu)
		if motif then
			rouleau.ImageContent = motif
		end
		local plie = false
		for _, id in ipairs(ids) do
			local p, b = placements[id], Polygone.boite(Catalogue.piece(id).contour)
			local copies = { { x = p.x, angle = p.angle } }
			if Catalogue.piece(id).pliee then
				plie = true
				table.insert(copies, { x = 2 * Catalogue.PLI - p.x, angle = -p.angle })
			end
			for _, c in ipairs(copies) do
				local img = UiKit.creer("ImageLabel", {
					Name = "Piece_" .. id,
					BackgroundTransparency = 1,
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.fromOffset(c.x * PX_APERCU, p.y * PX_APERCU),
					Size = UDim2.fromOffset((b.maxX - b.minX) * PX_APERCU, (b.maxY - b.minY) * PX_APERCU),
					Rotation = c.angle,
					ImageTransparency = 0.15,
					ZIndex = 23,
					Parent = rouleau,
				})
				local silhouette = Vignettes.silhouette(id)
				if silhouette then
					img.ImageContent = silhouette
				else
					img.BackgroundColor3, img.BackgroundTransparency = Color3.new(1, 1, 1), 0.4
				end
			end
		end
		if plie then
			UiKit.creer("Frame", { Name = "Pli", BackgroundColor3 = C.texte, BackgroundTransparency = 0.4, BorderSizePixel = 0, Position = UDim2.fromOffset(Catalogue.PLI * PX_APERCU - 1, 0), Size = UDim2.new(0, 2, 1, 0), ZIndex = 22, Parent = rouleau })
		end
		UiKit.texte({
			Text = "Les pièces sont posées rang par rang, au droit-fil. À la table de découpe, tu les places toi-même : bien serrées, elles prennent moins de tissu. Le tissu en trop reste dans ton stock.",
			TextSize = 14,
			TextColor3 = C.texteDoux,
			Position = UDim2.fromOffset(14 * PX_APERCU + 30, 40),
			Size = UDim2.new(1, -(14 * PX_APERCU + 30), 0, 80),
			ZIndex = 21,
			Parent = apercu,
		})
	end

	local function majLigne(idTissu)
		local l = lignes[idTissu]
		local stock = etat.stock[idTissu] or 0
		local entame = etat.entames[idTissu]
		local q = quantites[idTissu]
		-- (sous-projet 6) un rouleau entamé : le tissu neuf, et ce qui est entamé en haut du rouleau
		l.infos.Text = if entame
			then ("Conseillé : %d dm · Neuf : %d dm (%d entamés)"):format(conseil(idTissu), etat:stockNeuf(idTissu), entame.bas)
			else ("Conseillé : %d dm · En stock : %d dm"):format(conseil(idTissu), stock)
		l.quantite.Text = ("%d dm"):format(q)
		l.cout.Text = q > 0 and ("%d po"):format(EtatAtelier.prix(idTissu, q)) or "—"
		l.acheter.AutoButtonColor = q > 0
		l.acheter.BackgroundColor3 = q > 0 and C.accent or C.secondaire
	end

	for i, idTissu in ipairs(etat:tissusUtilises()) do
		local t = Catalogue.tissu(idTissu)
		stocksVus[idTissu] = etat:stockNeuf(idTissu)
		quantites[idTissu] = math.max(0, conseil(idTissu) - stocksVus[idTissu])
		local ligne = UiKit.arrondir(UiKit.creer("Frame", { Name = "Ligne_" .. idTissu, BackgroundColor3 = C.panneau, Position = UDim2.fromOffset(0, (i - 1) * HAUTEUR_LIGNE), Size = UDim2.new(1, -10, 0, 76), Parent = liste }), 10)
		local echantillon = UiKit.arrondir(UiKit.creer("ImageButton", {
			Name = "Apercu_" .. idTissu,
			AutoButtonColor = false,
			BackgroundColor3 = UiKit.couleur(t.motif.couleurs[1]),
			Position = UDim2.fromOffset(10, 10),
			Size = UDim2.fromOffset(80, 56),
			ScaleType = Enum.ScaleType.Tile,
			TileSize = UDim2.fromOffset(64, 64),
			Parent = ligne,
		}), 6)
		echantillon.Activated:Connect(function()
			ouvrirApercu(idTissu)
		end)
		local motif = Vignettes.motif(idTissu)
		if motif then
			echantillon.ImageContent = motif
		end
		UiKit.texte({ Text = ("%s — %s"):format(t.nom, if t.prix == 0 then "Gratuit" else ("%d po/m"):format(t.prix)), Font = Enum.Font.GothamBold, Position = UDim2.fromOffset(102, 10), Size = UDim2.fromOffset(320, 24), Parent = ligne })
		-- (deux lignes au besoin : « Conseillé : 27 dm · Neuf : 43 dm (50 entamés) », jusqu'au bouton −)
		local l = { infos = UiKit.texte({ Name = "Infos", TextSize = 14, TextColor3 = C.texteDoux, TextYAlignment = Enum.TextYAlignment.Top, Position = UDim2.fromOffset(102, 36), Size = UDim2.fromOffset(336, 36), Parent = ligne }) }
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
				ctx.message(("Acheté : %d dm %s (%d po)."):format(q, Deblocages.de(t.nom), r.prix), C.ok)
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
	local boutonDecoupe = UiKit.bouton({ Name = "AllerDecoupe", Text = "Aller à la découpe", AnchorPoint = Vector2.new(1, 1), Position = UDim2.fromScale(1, 1), Size = UDim2.fromOffset(240, 46), Parent = contenu }, function()
		local r = session:commencerDecoupe()
		if not r.ok then
			ctx.refus(r)
		end
	end)
	-- Le stock change (achat, bande jetée, ou état réparé par le serveur) : la quantité proposée est ce qui manque
	-- encore en tissu neuf
	local desabonner = session:surChangement(function()
		for idTissu in pairs(lignes) do
			local stock = etat:stockNeuf(idTissu)
			if stock ~= stocksVus[idTissu] then
				stocksVus[idTissu] = stock
				quantites[idTissu] = math.max(0, conseil(idTissu) - stock)
			end
			majLigne(idTissu)
		end
	end)
	-- (sous-projet 9) Les conseils de la première robe : acheter chaque tissu (le métrage proposé), aller à la découpe
	if ctx.guide then
		-- (le métrage conseillé de chaque tissu, calculé une fois : le croquis ne change pas à l'achat)
		local tissusRobe, besoins = session.etat:tissusUtilises(), {}
		for _, idTissu in ipairs(tissusRobe) do
			besoins[idTissu] = conseil(idTissu)
		end
		ctx.guide:demarrer(session, "achat", {
			{
				texte = "Achète chaque tissu : le métrage conseillé suffit si tu ranges bien tes pièces.",
				cible = function()
					for _, idTissu in ipairs(tissusRobe) do
						if lignes[idTissu] and session.etat:stockNeuf(idTissu) < besoins[idTissu] then
							return lignes[idTissu].acheter
						end
					end
					return nil
				end,
				fait = function()
					for _, idTissu in ipairs(tissusRobe) do
						if session.etat:stockNeuf(idTissu) < besoins[idTissu] then
							return false
						end
					end
					return true
				end,
			},
			{
				texte = "Tu as assez de tissu : va à la découpe.",
				cible = function()
					return boutonDecoupe
				end,
			},
		})
	end
	return function()
		desabonner()
		fermerApercu()
	end
end
