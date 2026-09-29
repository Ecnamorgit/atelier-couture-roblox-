-- Écran d'accueil : la clochette du comptoir (bouton, ou touche E) fait entrer une cliente et crée la
-- commande (elle verse un acompte). Après une livraison, il annonce ce qu'a pensé la cliente précédente,
-- l'amitié et le prestige gagnés, et ce qui vient de s'ouvrir (ou la vente, ou le cadeau, d'une robe libre).
-- La jauge de prestige est sous la clochette ; « Robe libre » (après deux commandes livrées) à côté.
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Couture = ReplicatedStorage:WaitForChild("Couture")
local Clientes = require(Couture:WaitForChild("Clientes"))
local Progression = require(Couture:WaitForChild("Progression"))
local Deblocages = require(Couture:WaitForChild("Deblocages"))
local EtatAtelier = require(Couture:WaitForChild("EtatAtelier"))

-- « Amitié de Colette : +3 (niveau 2 !) » ; nil sans cliente
local function ligneAmitie(amitie)
	local fiche = amitie and Clientes.get(amitie.cliente)
	if not fiche then
		return nil
	end
	local prenom = fiche.nom:match("^(%S+)")
	local niveau = if amitie.niveau > amitie.niveauAvant then (" (niveau %d !)"):format(amitie.niveau) else ""
	return ("Amitié de %s : %s%d%s"):format(prenom, amitie.gain >= 0 and "+" or "", amitie.gain, niveau)
end

return function(ctx)
	local UiKit = ctx.UiKit
	local C = UiKit.COULEURS
	local decalage = 0
	local derniere = ctx.session.derniere
	local annonce, couleur = nil, C.ok
	local r = derniere and derniere.reponse
	local action = derniere and r.ok and derniere.action
	local suite = {}
	if action == "livrer" and r.reussie then
		local fiche = r.amitie and Clientes.get(r.amitie.cliente)
		annonce = ("%s est ravie ! +%d pièces d'or (qualité %d %%). Sa robe est en vitrine."):format(
			fiche and fiche.nom:match("^(%S+)") or "La cliente",
			r.verse or r.paie,
			math.floor(r.bilan.qualite * 100 + 0.5)
		)
		if r.acompte and r.acompte > 0 then
			table.insert(suite, ("Acompte de %d déjà reçu"):format(r.acompte))
		end
		table.insert(suite, ligneAmitie(r.amitie))
	elseif action == "vendre" then
		annonce = ("Robe vendue ! +%d pièces d'or (qualité %d %%). Elle part en vitrine."):format(r.prix, math.floor(r.bilan.qualite * 100 + 0.5))
	elseif action == "offrir" then
		local fiche = Clientes.get(r.cliente)
		annonce = ("%s adore la robe que tu lui offres ! Elle part en vitrine."):format(fiche and fiche.nom:match("^(%S+)") or "La cliente")
		table.insert(suite, ligneAmitie(r.amitie))
	end
	if annonce then
		if r.prestige then
			table.insert(suite, ("Prestige : +%d%s"):format(r.prestige.gain, if r.prestige.niveau > r.prestige.niveauAvant then (" (niveau %d !)"):format(r.prestige.niveau) else ""))
		end
		if #suite > 0 then
			annonce ..= "\n" .. table.concat(suite, " · ")
		end
		if r.nouveaux and #r.nouveaux > 0 then
			annonce ..= "\nNouveau : " .. Deblocages.resume(r.nouveaux) .. "."
		end
	elseif action == "abandonner" then
		annonce, couleur = "Commande abandonnée : pas de paie cette fois.", C.alerte
		local perte = ligneAmitie(derniere.reponse.amitie)
		if perte then
			annonce ..= "\n" .. perte
		end
	end
	if annonce then
		local _, retours = annonce:gsub("\n", "")
		local hauteur = 24 * (retours + 1) + 2
		UiKit.texte({ Name = "Annonce", Text = annonce, Font = Enum.Font.GothamBold, TextSize = 18, TextColor3 = couleur, Size = UDim2.new(1, 0, 0, hauteur), Parent = ctx.contenu })
		decalage = hauteur + 10
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
		elseif r.acompte and r.acompte > 0 then
			local fiche = Clientes.get(r.cliente)
			ctx.message(("%s verse un acompte de %d pièces d'or."):format(fiche and fiche.nom:match("^(%S+)") or "La cliente", r.acompte), C.ok)
		end
	end
	UiKit.bouton({
		Name = "Clochette",
		Text = if UserInputService.KeyboardEnabled then "Sonner la clochette (E)" else "Sonner la clochette",
		Position = UDim2.fromOffset(0, 110 + decalage),
		Size = UDim2.fromOffset(260, 50),
		Parent = ctx.contenu,
	}, sonner)
	-- Robe libre (après deux commandes livrées) : on choisit une taille, et l'on va droit au carnet
	local etat = ctx.session.etat
	if etat.livraisons >= EtatAtelier.LIBRES_APRES then
		local libre
		libre = UiKit.boutonDoux({ Name = "RobeLibre", Text = "Robe libre", Position = UDim2.fromOffset(276, 110 + decalage), Size = UDim2.fromOffset(200, 50), Parent = ctx.contenu }, function()
			libre.Visible = false
			local choix = UiKit.creer("Frame", { Name = "ChoixTaille", BackgroundTransparency = 1, Position = UDim2.fromOffset(276, 110 + decalage), Size = UDim2.fromOffset(300, 50), Parent = ctx.contenu })
			UiKit.texte({ Text = "Taille :", Font = Enum.Font.GothamBold, Position = UDim2.fromOffset(0, 14), Size = UDim2.fromOffset(70, 22), Parent = choix })
			for k, taille in ipairs({ "S", "M", "L" }) do
				UiKit.bouton({ Name = "RobeLibre_" .. taille, Text = taille, Position = UDim2.fromOffset(70 + (k - 1) * 70, 0), Size = UDim2.fromOffset(60, 50), Parent = choix }, function()
					local rl = ctx.session:nouvelleRobeLibre(taille)
					if not rl.ok then
						ctx.refus(rl)
					end
				end)
			end
		end)
	end
	-- La jauge de prestige : « Prestige 3 — 62 / 100 »
	local niveau = Progression.niveauPrestige(etat.prestige)
	local seuil, suivant = Progression.SEUILS_PRESTIGE[niveau], Progression.SEUILS_PRESTIGE[niveau + 1]
	local y = 110 + decalage + 66
	UiKit.texte({
		Name = "Prestige",
		Text = if suivant then ("Prestige %d — %d / %d"):format(niveau, etat.prestige, suivant) else ("Prestige %d — %d (au plus haut)"):format(niveau, etat.prestige),
		Font = Enum.Font.GothamBold,
		Position = UDim2.fromOffset(0, y),
		Size = UDim2.fromOffset(360, 22),
		Parent = ctx.contenu,
	})
	local fond = UiKit.arrondir(UiKit.creer("Frame", { Name = "JaugePrestige", BackgroundColor3 = C.secondaire, Position = UDim2.fromOffset(0, y + 26), Size = UDim2.fromOffset(360, 12), Parent = ctx.contenu }), 6)
	local part = if suivant then (etat.prestige - seuil) / (suivant - seuil) else 1
	UiKit.creer("Frame", { Name = "Rempli", BackgroundColor3 = C.accent, BorderSizePixel = 0, Size = UDim2.fromScale(math.clamp(part, 0, 1), 1), Parent = fond })
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
