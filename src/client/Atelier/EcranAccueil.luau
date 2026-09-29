-- Écran d'accueil : la clochette du comptoir fait entrer une cliente et crée la commande.
return function(ctx)
	local UiKit = ctx.UiKit
	UiKit.texte({
		Text = "Bienvenue dans ton atelier ! Une cliente attend à la porte. Fais sonner la clochette pour "
			.. "prendre sa commande : tu dessineras la robe dans ton carnet, tu achèteras le tissu, "
			.. "puis tu découperas les pièces du patron.",
		TextSize = 18,
		Size = UDim2.new(1, 0, 0, 90),
		Parent = ctx.contenu,
	})
	UiKit.bouton({
		Name = "Clochette",
		Text = "Sonner la clochette",
		Position = UDim2.fromOffset(0, 110),
		Size = UDim2.fromOffset(260, 50),
		Parent = ctx.contenu,
	}, function()
		local r = ctx.session:nouvelleCommande()
		if not r.ok then
			ctx.message(r.erreur, UiKit.COULEURS.erreur)
		end
	end)
	return function() end
end
