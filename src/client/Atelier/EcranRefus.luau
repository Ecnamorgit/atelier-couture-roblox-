-- La cliente refuse la robe (panneau à droite, la robe sur le mannequin) : les exigences ratées.
-- On retouche (retour aux décorations) ou on abandonne la commande (ni paie ni vitrine).
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Couture = ReplicatedStorage:WaitForChild("Couture")
local Catalogue = require(Couture:WaitForChild("Catalogue"))
local Notation = require(Couture:WaitForChild("Notation"))

return function(ctx)
	local UiKit, session, contenu = ctx.UiKit, ctx.session, ctx.contenu
	local C = UiKit.COULEURS
	local etat = session.etat
	local derniere = session.derniere
	local ratees = derniere and derniere.action == "livrer" and derniere.reponse.ratees or {}
	local styles = Notation.bilan(etat:recette()).styles

	UiKit.texte({ Text = "Ce n'est pas ce qu'elle voulait :", TextSize = 16, Size = UDim2.new(1, 0, 0, 24), Parent = contenu })
	for k, i in ipairs(ratees) do
		UiKit.texte({
			Text = "× " .. UiKit.exigence(etat.commande.exigences[i], Catalogue, styles),
			Font = Enum.Font.GothamBold,
			TextSize = 16,
			TextColor3 = C.erreur,
			Position = UDim2.fromOffset(0, 8 + k * 26),
			Size = UDim2.new(1, 0, 0, 24),
			Parent = contenu,
		})
	end
	UiKit.texte({
		Text = "Tu peux ajouter ou retirer des décorations. Le tissu et la couture, eux, ne changent plus.",
		TextSize = 14,
		TextColor3 = C.texteDoux,
		Position = UDim2.fromOffset(0, 130),
		Size = UDim2.new(1, 0, 0, 40),
		Parent = contenu,
	})
	UiKit.bouton({ Name = "Retoucher", Text = "Retoucher la robe", Position = UDim2.fromOffset(0, 186), Size = UDim2.new(1, -6, 0, 46), Parent = contenu }, function()
		local r = session:retoucher()
		if not r.ok then
			ctx.message(r.erreur, C.erreur)
		end
	end)
	UiKit.boutonConfirme({ Name = "Abandonner", Text = "Abandonner la commande", TextSize = 14, Position = UDim2.fromOffset(0, 244), Size = UDim2.new(1, -6, 0, 36), Parent = contenu }, function()
		local r = session:abandonner()
		if not r.ok then
			ctx.message(r.erreur, C.erreur)
		end
	end)
	return function() end
end
