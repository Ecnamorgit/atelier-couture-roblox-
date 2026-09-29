-- Écran provisoire après la découpe : l'épinglage, la couture, les décorations et la livraison
-- arrivent au plan 3b. On peut recommencer une robe pour la même commande.
return function(ctx)
	local UiKit = ctx.UiKit
	UiKit.texte({
		Text = "Bravo, toutes les pièces sont coupées ! La suite (épinglage sur le mannequin, couture, "
			.. "décorations et livraison) arrive bientôt.",
		TextSize = 18,
		Size = UDim2.new(1, 0, 0, 70),
		Parent = ctx.contenu,
	})
	UiKit.boutonDoux({
		Name = "Recommencer",
		Text = "Recommencer une robe",
		Position = UDim2.fromOffset(0, 90),
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
