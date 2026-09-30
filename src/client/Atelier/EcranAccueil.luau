-- Écran d'accueil : la clochette du comptoir (bouton, ou touche E) fait entrer une cliente et crée la
-- commande (elle verse un acompte). Après une livraison, il annonce ce qu'a pensé la cliente précédente,
-- l'amitié et le prestige gagnés, et ce qui vient de s'ouvrir (ou la vente, ou le cadeau, d'une robe libre).
-- La jauge de prestige est sous la clochette ; « Robe libre » (après deux commandes livrées) et « Carnet
-- d'adresses » à côté ; le courrier (après cinq commandes livrées) en dessous, chaque lettre avec « Inviter ».
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Couture = ReplicatedStorage:WaitForChild("Couture")
local Clientes = require(Couture:WaitForChild("Clientes"))
local Progression = require(Couture:WaitForChild("Progression"))
local Deblocages = require(Couture:WaitForChild("Deblocages"))
local EtatAtelier = require(Couture:WaitForChild("EtatAtelier"))
local Catalogue = require(Couture:WaitForChild("Catalogue"))

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
		local expeditrice = r.lettre and Clientes.get(r.lettre.cliente)
		if expeditrice then
			annonce ..= ("\nUne lettre de %s est arrivée."):format(expeditrice.nom:match("^(%S+)"))
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
	-- L'explication complète tant qu'aucune robe n'est livrée, une ligne ensuite (place pour le courrier)
	local debutant = ctx.session.etat.livraisons == 0
	local hauteurIntro = if debutant then 90 else 26
	UiKit.texte({
		Name = "Intro",
		Text = if debutant
			then "Bienvenue dans ton atelier ! Une cliente attend à la porte. Fais sonner la clochette pour "
				.. "prendre sa commande : tu dessineras la robe, achèteras le tissu, découperas, épingleras "
				.. "et coudras les pièces, puis tu la décoreras avant de la livrer."
			else "Une cliente attend à la porte : fais sonner la clochette.",
		TextSize = 18,
		Position = UDim2.fromOffset(0, decalage),
		Size = UDim2.new(1, 0, 0, hauteurIntro),
		Parent = ctx.contenu,
	})
	local ligne = decalage + hauteurIntro + 20 -- la rangée des boutons
	-- Une cliente entre (clochette ou lettre) : elle verse l'acompte
	local function accueillie(r)
		if not r.ok then
			ctx.refus(r)
		elseif r.acompte and r.acompte > 0 then
			local fiche = Clientes.get(r.cliente)
			ctx.message(("%s verse un acompte de %d pièces d'or."):format(fiche and fiche.nom:match("^(%S+)") or "La cliente", r.acompte), C.ok)
		end
	end
	local function sonner()
		accueillie(ctx.session:nouvelleCommande())
	end
	UiKit.bouton({
		Name = "Clochette",
		Text = if UserInputService.KeyboardEnabled then "Sonner la clochette (E)" else "Sonner la clochette",
		Position = UDim2.fromOffset(0, ligne),
		Size = UDim2.fromOffset(260, 50),
		Parent = ctx.contenu,
	}, sonner)
	-- Robe libre (après deux commandes livrées) : on choisit une taille, et l'on va droit au carnet
	local etat = ctx.session.etat
	if etat.livraisons >= EtatAtelier.LIBRES_APRES then
		local libre
		libre = UiKit.boutonDoux({ Name = "RobeLibre", Text = "Robe libre", Position = UDim2.fromOffset(276, ligne), Size = UDim2.fromOffset(200, 50), Parent = ctx.contenu }, function()
			libre.Visible = false
			local choix = UiKit.creer("Frame", { Name = "ChoixTaille", BackgroundTransparency = 1, Position = UDim2.fromOffset(276, ligne), Size = UDim2.fromOffset(300, 50), Parent = ctx.contenu })
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
	local y = ligne + 66
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
	-- Le courrier : chaque lettre annonce la première exigence de la commande ; « Inviter » fait venir la cliente
	if etat.livraisons >= EtatAtelier.COURRIER_APRES then
		UiKit.texte({ Name = "Courrier", Text = if #etat.lettres > 0 then "Courrier :" else "Courrier : pas de lettre pour l'instant.", Font = Enum.Font.GothamBold, Position = UDim2.fromOffset(0, y + 50), Size = UDim2.fromOffset(500, 22), Parent = ctx.contenu })
		for i, l in ipairs(etat.lettres) do
			local fiche = Clientes.get(l.cliente)
			local yl = y + 76 + (i - 1) * 40
			UiKit.texte({ Name = "Lettre" .. i, Text = ("%s : « %s »"):format(fiche.nom:match("^(%S+)"), UiKit.exigence(l.commande.exigences[1], Catalogue)), TextSize = 16, Position = UDim2.fromOffset(0, yl + 6), Size = UDim2.fromOffset(600, 22), Parent = ctx.contenu })
			UiKit.boutonDoux({ Name = "Inviter_" .. i, Text = "Inviter", TextSize = 16, Position = UDim2.fromOffset(610, yl), Size = UDim2.fromOffset(120, 34), Parent = ctx.contenu }, function()
				accueillie(ctx.session:inviter(i))
			end)
		end
	end
	-- Le carnet d'adresses : les clientes déjà venues, leur amitié, et ce que le prochain niveau ouvrira
	local venues = {}
	for _, c in ipairs(Clientes.LISTE) do
		local f = etat.clientes[c.id]
		if f and f.vues > 0 then
			table.insert(venues, { cliente = c, fiche = f })
		end
	end
	if #venues > 0 then
		local carnet = UiKit.arrondir(UiKit.creer("TextButton", { Name = "CarnetAdresses", Text = "", AutoButtonColor = false, Visible = false, BackgroundColor3 = C.panneau, Size = UDim2.fromScale(1, 1), ZIndex = 20, Parent = ctx.contenu }), 10)
		UiKit.texte({ Text = "Carnet d'adresses", Font = Enum.Font.GothamBold, Size = UDim2.new(1, -130, 0, 34), ZIndex = 21, Parent = carnet })
		UiKit.boutonDoux({ Name = "FermerCarnetAdresses", Text = "Fermer", TextSize = 14, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -6, 0, 0), Size = UDim2.fromOffset(110, 34), ZIndex = 21, Parent = carnet }, function()
			carnet.Visible = false
		end)
		for k, v in ipairs(venues) do
			local niveau = Progression.niveauAmitie(v.fiche.amitie)
			local seuil = Progression.SEUILS_AMITIE[niveau + 2]
			local points = if seuil then ("%d / %d"):format(v.fiche.amitie, seuil) else ("%d, au plus haut"):format(v.fiche.amitie)
			local prochain = Deblocages.prochainDeCliente(v.cliente.id, v.fiche.amitie)
			local ouvre = if prochain then ("prochain : %s (niveau %d)"):format(prochain.nom, prochain.niveau) else "tout ce qu'elle ouvre est ouvert"
			UiKit.texte({
				Name = "Adresse_" .. v.cliente.id,
				Text = ("%s — amitié niveau %d (%s) · %s"):format(v.cliente.nom, niveau, points, ouvre),
				TextSize = 16,
				Position = UDim2.fromOffset(0, 44 + (k - 1) * 34),
				Size = UDim2.new(1, 0, 0, 30),
				ZIndex = 21,
				Parent = carnet,
			})
		end
		-- (à droite du choix de la taille d'une robe libre, qui s'étend jusqu'à x = 576)
		UiKit.boutonDoux({ Name = "OuvrirCarnetAdresses", Text = "Carnet d'adresses", Position = UDim2.fromOffset(592, ligne), Size = UDim2.fromOffset(220, 50), Parent = ctx.contenu }, function()
			carnet.Visible = true
		end)
	end
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
