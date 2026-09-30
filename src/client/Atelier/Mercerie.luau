-- Mercerie (sous-projet 6) : la boutique de la mercerie, par-dessus l'écran (depuis l'accueil ou les décorations,
-- sans quitter la robe en cours). Un casier par décoration ouverte, avec ce qu'on en a ; la fiche de l'article
-- choisi (son prix, ses styles, la quantité − / +) et « Acheter ». Un bouton sans texte, pas un cadre : les appuis
-- ne passent pas aux boutons dessous.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Couture = ReplicatedStorage:WaitForChild("Couture")
local Catalogue = require(Couture:WaitForChild("Catalogue"))
local Deblocages = require(Couture:WaitForChild("Deblocages"))
local EtatAtelier = require(Couture:WaitForChild("EtatAtelier"))

local Mercerie = {}

-- Des cm en mètres, à la française : 150 → « 1,50 »
function Mercerie.metres(cm)
	return (("%.2f"):format(cm / 100):gsub("%.", ","))
end

-- Une quantité d'un article, en clair : « ×12 » (un objet, à l'unité) ou « 1,50 m » (une garniture, en cm)
function Mercerie.stock(id, quantite)
	if Catalogue.accessoire(id).genre == "garniture" then
		return Mercerie.metres(quantite or 0) .. " m"
	end
	return ("×%d"):format(quantite or 0)
end

-- Ouvre la mercerie dans ctx.contenu ; auChangement() est appelé après chaque achat. Renvoie le panneau
function Mercerie.ouvrir(ctx, auChangement)
	local UiKit, session = ctx.UiKit, ctx.session
	local C = UiKit.COULEURS
	local ancien = ctx.contenu:FindFirstChild("Mercerie")
	if ancien then
		ancien:Destroy()
	end
	local panneau = UiKit.arrondir(UiKit.creer("TextButton", { Name = "Mercerie", Text = "", AutoButtonColor = false, BackgroundColor3 = Color3.fromRGB(255, 248, 238), Size = UDim2.fromScale(1, 1), ZIndex = 30, Parent = ctx.contenu }), 10)
	UiKit.creer("UIStroke", { Color = C.accent, Thickness = 2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = panneau })
	UiKit.texte({ Name = "TitreMercerie", Text = "Mercerie", Font = Enum.Font.GothamBold, TextSize = 20, Position = UDim2.fromOffset(10, 6), Size = UDim2.new(1, -130, 0, 28), ZIndex = 31, Parent = panneau })
	UiKit.boutonDoux({ Name = "FermerMercerie", Text = "Fermer", TextSize = 14, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -8, 0, 6), Size = UDim2.fromOffset(100, 30), ZIndex = 31, Parent = panneau }, function()
		panneau:Destroy()
	end)
	-- Les casiers : les décorations ouvertes, sur deux colonnes, qui défilent
	local ouverts = {}
	for _, a in ipairs(Catalogue.Accessoires) do
		if Deblocages.ouvert(session.etat, "accessoires", a.id) then
			table.insert(ouverts, a)
		end
	end
	local HAUT_CASE = 36
	local casiers = UiKit.creer("ScrollingFrame", { Name = "Casiers", BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 6, ScrollBarImageColor3 = C.accent, Position = UDim2.fromOffset(8, 42), Size = UDim2.new(1, -16, 1, -184), CanvasSize = UDim2.fromOffset(0, math.ceil(#ouverts / 2) * (HAUT_CASE + 4)), ZIndex = 31, Parent = panneau })
	-- La fiche de l'article choisi, en bas, sous un trait : son nom et son prix, ses styles, la quantité
	UiKit.creer("Frame", { Name = "Trait", BackgroundColor3 = C.accent, BackgroundTransparency = 0.5, BorderSizePixel = 0, Position = UDim2.new(0, 8, 1, -140), Size = UDim2.new(1, -16, 0, 2), ZIndex = 31, Parent = panneau })
	local fiche = UiKit.creer("Frame", { Name = "Fiche", BackgroundTransparency = 1, AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 8, 1, -8), Size = UDim2.new(1, -16, 0, 126), ZIndex = 31, Parent = panneau })
	local article = UiKit.texte({ Name = "Article", Text = "Choisis un article.", Font = Enum.Font.GothamBold, TextSize = 14, Size = UDim2.new(1, 0, 0, 20), ZIndex = 32, Parent = fiche })
	local stylesTexte = UiKit.texte({ Name = "Styles", TextSize = 14, TextColor3 = C.texteDoux, Position = UDim2.fromOffset(0, 20), Size = UDim2.new(1, 0, 0, 20), ZIndex = 32, Parent = fiche })
	local quantiteTexte = UiKit.texte({ Name = "Quantite", Font = Enum.Font.GothamBold, TextSize = 16, TextXAlignment = Enum.TextXAlignment.Center, Position = UDim2.fromOffset(52, 46), Size = UDim2.fromOffset(110, 34), ZIndex = 32, Parent = fiche })
	local choisi, quantite = nil, 1
	local cases, acheter = {}, nil
	local function majFiche()
		for id, b in pairs(cases) do
			b.Text = Catalogue.accessoire(id).nom .. " · " .. Mercerie.stock(id, session.etat.mercerie[id])
			b.BackgroundColor3 = if id == choisi then C.accent else C.secondaire
			b.TextColor3 = if id == choisi then Color3.new(1, 1, 1) else C.texte
		end
		if not choisi then
			quantiteTexte.Text = ""
			acheter.Text = "Acheter"
			return
		end
		local a = Catalogue.accessoire(choisi)
		local styles = {}
		for _, s in ipairs(Catalogue.STYLES) do
			if a.style[s] then
				table.insert(styles, ("%s +%d"):format(Catalogue.NOMS_STYLES[s], a.style[s]))
			end
		end
		local garniture = a.genre == "garniture"
		article.Text = ("%s — %s"):format(a.nom, if garniture then ("%d po les 50 cm"):format(a.prix * 5) else ("%d po l'unité"):format(a.prix))
		-- (les points de style d'une garniture sont comptés pour 50 cm, au prorata)
		stylesTexte.Text = table.concat(styles, ", ") .. (if garniture then " (pour 50 cm)" else "")
		quantiteTexte.Text = if garniture then ("%d × 50 cm"):format(quantite) else ("×%d"):format(quantite)
		acheter.Text = ("Acheter (%d po)"):format(if garniture then a.prix * 5 * quantite else a.prix * quantite)
	end
	for k, a in ipairs(ouverts) do
		cases[a.id] = UiKit.boutonDoux({ Name = "Case_" .. a.id, TextSize = 14, TextWrapped = true, Position = UDim2.new(((k - 1) % 2) * 0.5, 0, 0, ((k - 1) // 2) * (HAUT_CASE + 4)), Size = UDim2.new(0.5, -8, 0, HAUT_CASE), ZIndex = 32, Parent = casiers }, function()
			choisi, quantite = a.id, 1
			majFiche()
		end)
	end
	UiKit.boutonDoux({ Name = "QuantiteMoins", Text = "−", TextSize = 20, Position = UDim2.fromOffset(0, 46), Size = UDim2.fromOffset(44, 34), ZIndex = 32, Parent = fiche }, function()
		quantite = math.max(1, quantite - 1)
		majFiche()
	end)
	UiKit.boutonDoux({ Name = "QuantitePlus", Text = "+", TextSize = 20, Position = UDim2.fromOffset(170, 46), Size = UDim2.fromOffset(44, 34), ZIndex = 32, Parent = fiche }, function()
		quantite = math.min(EtatAtelier.ACHAT_MERCERIE_MAX, quantite + 1)
		majFiche()
	end)
	acheter = UiKit.bouton({ Name = "AcheterMercerie", Text = "Acheter", TextSize = 16, Position = UDim2.fromOffset(0, 88), Size = UDim2.new(1, 0, 0, 36), ZIndex = 32, Parent = fiche }, function()
		if not choisi then
			ctx.message("Choisis d'abord un article.", C.texteDoux)
			return
		end
		local r = session:acheterMercerie(choisi, quantite)
		if not r.ok then
			ctx.refus(r)
			return
		end
		ctx.message(("Acheté : %s, %s (%d po)."):format(Catalogue.accessoire(choisi).nom, Mercerie.stock(choisi, r.quantite), r.prix), C.ok)
		majFiche()
		if auChangement then
			auChangement()
		end
	end, 0.4)
	majFiche()
	return panneau
end

return Mercerie
