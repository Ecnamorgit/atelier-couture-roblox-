-- Écran d'accueil : la clochette du comptoir (bouton, ou touche E) fait entrer une cliente et crée la
-- commande. Après une livraison, il annonce ce qu'a pensé la cliente précédente.
local UserInputService = game:GetService("UserInputService")

return function(ctx)
	local UiKit = ctx.UiKit
	local C = UiKit.COULEURS
	local decalage = 0
	local derniere = ctx.session.derniere
	local annonce, couleur = nil, C.ok
	if derniere and derniere.action == "livrer" and derniere.reponse.reussie then
		annonce = ("La cliente est ravie ! +%d pièces d'or (qualité %d %%). Sa robe est en vitrine."):format(
			derniere.reponse.paie,
			math.floor(derniere.reponse.bilan.qualite * 100 + 0.5)
		)
	elseif derniere and derniere.action == "abandonner" then
		annonce, couleur = "Commande abandonnée : pas de paie cette fois.", C.alerte
	end
	if annonce then
		UiKit.texte({ Name = "Annonce", Text = annonce, Font = Enum.Font.GothamBold, TextSize = 18, TextColor3 = couleur, Size = UDim2.new(1, 0, 0, 50), Parent = ctx.contenu })
		decalage = 60
	end
	UiKit.texte({
		Text = "Bienvenue dans ton atelier ! Une cliente attend à la porte. Fais sonner la clochette pour "
			.. "prendre sa commande : tu dessineras la robe, achèteras le tissu, découperas, épingleras "
			.. "et coudras les pièces, puis tu la décoreras avant de la livrer.",
		TextSize = 18,
		Position = UDim2.fromOffset(0, decalage),
		Size = UDim2.new(1, 0, 0, 90),
		Parent = ctx.contenu,
	})
	local function sonner()
		local r = ctx.session:nouvelleCommande()
		if not r.ok then
			ctx.refus(r)
		end
	end
	UiKit.bouton({
		Name = "Clochette",
		Text = if UserInputService.KeyboardEnabled then "Sonner la clochette (E)" else "Sonner la clochette",
		Position = UDim2.fromOffset(0, 110 + decalage),
		Size = UDim2.fromOffset(260, 50),
		Parent = ctx.contenu,
	}, sonner)
	-- E, fenêtre ouverte (pas pendant la saisie dans le chat) : sonner la clochette
	local connexion = UserInputService.InputBegan:Connect(function(input, traite)
		if not traite and input.KeyCode == Enum.KeyCode.E and ctx.fenetre.Visible then
			sonner()
		end
	end)
	return function()
		connexion:Disconnect()
	end
end
