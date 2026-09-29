-- Présentation (panneau à droite, la robe décorée sur le mannequin, vue de face) : la cliente regarde
-- la robe. On la livre, ou on retourne aux décorations. La photo (décor, éclairage) arrive au plan 3d.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Couture = ReplicatedStorage:WaitForChild("Couture")
local Catalogue = require(Couture:WaitForChild("Catalogue"))
local Notation = require(Couture:WaitForChild("Notation"))

return function(ctx)
	local UiKit, session, contenu = ctx.UiKit, ctx.session, ctx.contenu
	local C = UiKit.COULEURS
	local etat = session.etat
	local bilan = Notation.bilan(etat:recette())

	UiKit.texte({ Text = "La cliente examine ta robe.", TextSize = 16, Size = UDim2.new(1, 0, 0, 24), Parent = contenu })
	UiKit.texte({
		Name = "Qualite",
		Text = ("Qualité de la robe : %d %%"):format(math.floor(bilan.qualite * 100 + 0.5)),
		Font = Enum.Font.GothamBold,
		TextSize = 18,
		Position = UDim2.fromOffset(0, 32),
		Size = UDim2.new(1, 0, 0, 26),
		Parent = contenu,
	})
	UiKit.texte({ Text = "Elle voulait :", TextSize = 14, TextColor3 = C.texteDoux, Position = UDim2.fromOffset(0, 70), Size = UDim2.new(1, 0, 0, 20), Parent = contenu })
	for i, e in ipairs(etat.commande.exigences) do
		UiKit.texte({ Text = "· " .. UiKit.exigence(e, Catalogue, bilan.styles), TextSize = 14, Position = UDim2.fromOffset(0, 70 + i * 22), Size = UDim2.new(1, 0, 0, 20), Parent = contenu })
	end
	UiKit.bouton({ Name = "Livrer", Text = "Livrer la robe", Position = UDim2.fromOffset(0, 190), Size = UDim2.new(1, -6, 0, 46), Parent = contenu }, function()
		local r = session:livrer()
		if not r.ok then
			ctx.message(r.erreur, C.erreur)
		end
	end, 0.4)
	UiKit.boutonDoux({ Name = "RetourDecorations", Text = "Retour aux décorations", TextSize = 14, Position = UDim2.fromOffset(0, 246), Size = UDim2.new(1, -6, 0, 36), Parent = contenu }, function()
		local r = session:retourDecorations()
		if not r.ok then
			ctx.message(r.erreur, C.erreur)
		end
	end)
	UiKit.boutonConfirme({ Name = "Recommencer", Text = "Recommencer la robe", TextSize = 14, AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), Size = UDim2.fromOffset(200, 34), Parent = contenu }, function()
		local r = session:recommencer()
		if not r.ok then
			ctx.message(r.erreur, C.erreur)
		end
	end)
	return function() end
end
