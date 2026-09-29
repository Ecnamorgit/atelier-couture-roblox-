-- Écran provisoire après la couture (panneau à droite, la robe cousue sur le mannequin) :
-- les décorations, la photo et la livraison arrivent au plan 3c. On peut recommencer une robe.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Couture = ReplicatedStorage:WaitForChild("Couture")
local Notation = require(Couture:WaitForChild("Notation"))

return function(ctx)
	local UiKit = ctx.UiKit
	local recette = ctx.session.etat:recette()
	local qualite = recette and Notation.bilan(recette).qualite or 0
	UiKit.texte({
		Text = "Bravo, la robe est cousue ! Les décorations, la photo et la livraison à la cliente arrivent bientôt.",
		TextSize = 16,
		Size = UDim2.new(1, 0, 0, 90),
		Parent = ctx.contenu,
	})
	UiKit.texte({
		Name = "Qualite",
		Text = ("Qualité de la robe : %d %%"):format(math.floor(qualite * 100 + 0.5)),
		Font = Enum.Font.GothamBold,
		TextSize = 18,
		Position = UDim2.fromOffset(0, 100),
		Size = UDim2.new(1, 0, 0, 28),
		Parent = ctx.contenu,
	})
	UiKit.boutonConfirme({
		Name = "Recommencer",
		Text = "Recommencer une robe",
		Position = UDim2.fromOffset(0, 150),
		Size = UDim2.fromOffset(260, 46),
		Parent = ctx.contenu,
	}, function()
		local r = ctx.session:recommencer()
		if not r.ok then
			ctx.message(r.erreur, UiKit.COULEURS.erreur)
		end
	end)
	return function() end
end
