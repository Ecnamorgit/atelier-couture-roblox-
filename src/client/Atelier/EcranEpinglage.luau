-- Écran d'épinglage (panneau à droite, le mannequin à gauche) : toucher une pièce coupée l'épingle
-- à sa place sur le mannequin, dans son vrai tissu. La dernière pièce épinglée mène à la couture.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Couture = ReplicatedStorage:WaitForChild("Couture")
local Catalogue = require(Couture:WaitForChild("Catalogue"))
local Vignettes = require(script.Parent:WaitForChild("Vignettes"))

local HAUTEUR_CARTE = 54 -- six cartes tiennent sans défiler
local ECART = 4

return function(ctx)
	local UiKit, session = ctx.UiKit, ctx.session
	local C = UiKit.COULEURS
	local etat = session.etat

	UiKit.texte({
		Text = "Touche une pièce pour l'épingler à sa place sur le mannequin.",
		TextSize = 14,
		Size = UDim2.new(1, 0, 0, 36),
		Parent = ctx.contenu,
	})
	local liste = UiKit.creer("ScrollingFrame", {
		Name = "Liste",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Position = UDim2.fromOffset(0, 40),
		Size = UDim2.new(1, 0, 1, -84),
		ScrollBarThickness = 6,
		Parent = ctx.contenu,
	})
	local cartes = {}
	local pieces = etat:piecesDuCroquis()
	for i, id in ipairs(pieces) do
		local def = Catalogue.piece(id)
		local tissu = Catalogue.tissu(etat.tissus[id])
		local carte = UiKit.arrondir(UiKit.creer("TextButton", {
			Name = "Epingler_" .. id,
			Text = "",
			AutoButtonColor = true,
			BackgroundColor3 = C.panneau,
			Position = UDim2.fromOffset(0, (i - 1) * (HAUTEUR_CARTE + ECART)),
			Size = UDim2.new(1, -10, 0, HAUTEUR_CARTE),
			Parent = liste,
		}), 10)
		local apercu = UiKit.creer("ImageLabel", {
			Name = "Apercu",
			BackgroundTransparency = 1,
			BackgroundColor3 = UiKit.couleur(tissu.motif.couleurs[1]),
			ScaleType = Enum.ScaleType.Fit,
			Position = UDim2.fromOffset(6, 4),
			Size = UDim2.fromOffset(46, 46),
			Parent = carte,
		})
		local image = Vignettes.piece(id, etat.tissus[id], etat.coupees[id])
		if image then
			apercu.ImageContent = image
		else
			apercu.BackgroundTransparency = 0 -- mémoire des images pleine : la couleur du tissu
		end
		UiKit.texte({
			Text = def.nom .. (def.pliee and " (×2)" or ""),
			Font = Enum.Font.GothamBold,
			TextSize = 15,
			Position = UDim2.fromOffset(60, 6),
			Size = UDim2.new(1, -68, 0, 20),
			Parent = carte,
		})
		local etatTexte = UiKit.texte({
			Name = "Etat",
			TextSize = 14,
			Position = UDim2.fromOffset(60, 28),
			Size = UDim2.new(1, -68, 0, 20),
			Parent = carte,
		})
		carte.Activated:Connect(function()
			if session.etat.epinglees[id] then
				return
			end
			local r = session:epingler(id)
			if not r.ok then
				ctx.message(r.erreur, C.erreur)
			end
		end)
		cartes[id] = { carte = carte, etat = etatTexte }
	end
	liste.CanvasSize = UDim2.fromOffset(0, #pieces * (HAUTEUR_CARTE + ECART))

	UiKit.boutonConfirme({ Name = "Recommencer", Text = "Recommencer la robe", TextSize = 14, AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), Size = UDim2.fromOffset(200, 34), Parent = ctx.contenu }, function()
		local r = session:recommencer()
		if not r.ok then
			ctx.message(r.erreur, C.erreur)
		end
	end)

	local function rafraichir()
		for id, c in pairs(cartes) do
			local fait = session.etat.epinglees[id] == true
			c.etat.Text = fait and "Épinglée" or "Touche pour épingler"
			c.etat.TextColor3 = fait and C.ok or C.texteDoux
			c.carte.BackgroundColor3 = fait and C.secondaire or C.panneau
			c.carte.AutoButtonColor = not fait
		end
	end
	local desabonner = session:surChangement(rafraichir)
	rafraichir()
	return function()
		desabonner()
	end
end
