-- Écran d'accueil : la clochette du comptoir (bouton, ou touche E) fait entrer une cliente et crée la
-- commande (elle verse un acompte). Après une livraison, il annonce ce qu'a pensé la cliente précédente,
-- l'amitié et le prestige gagnés, et ce qui vient de s'ouvrir (ou la vente, ou le cadeau, d'une robe libre).
-- La jauge de prestige est sous la clochette ; « Robe libre » (après deux commandes livrées) et « Carnet
-- d'adresses » à côté ; l'événement du quartier en cours (sous-projet 3) et le courrier (après cinq commandes
-- livrées) en dessous. Quand un événement a lieu, son épilogue s'affiche par-dessus.
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Couture = ReplicatedStorage:WaitForChild("Couture")
local Clientes = require(Couture:WaitForChild("Clientes"))
local Progression = require(Couture:WaitForChild("Progression"))
local Deblocages = require(Couture:WaitForChild("Deblocages"))
local EtatAtelier = require(Couture:WaitForChild("EtatAtelier"))
local Catalogue = require(Couture:WaitForChild("Catalogue"))
local Histoire = require(Couture:WaitForChild("Histoire"))

-- « Amitié de Colette : +3 (niveau 2 !) » ; nil sans cliente
local function ligneAmitie(amitie)
	local fiche = amitie and Clientes.get(amitie.cliente)
	if not fiche then
		return nil
	end
	local prenom = fiche.nom:match("^(%S+)")
	local niveau = if amitie.niveau > amitie.niveauAvant then (" (niveau %d !)"):format(amitie.niveau) else ""
	return ("Amitié %s : %s%d%s"):format(Deblocages.de(prenom), amitie.gain >= 0 and "+" or "", amitie.gain, niveau)
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
		local prenom = fiche and fiche.nom:match("^(%S+)") or "La cliente"
		annonce = if r.amitie and r.amitie.gain >= 3
			then ("%s adore la robe que tu lui offres ! Elle part en vitrine."):format(prenom)
			else ("%s te remercie pour la robe. Elle part en vitrine."):format(prenom)
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
			annonce ..= ("\nUne lettre %s est arrivée."):format(Deblocages.de(expeditrice.nom:match("^(%S+)")))
		end
	elseif action == "abandonner" then
		annonce, couleur = "Commande abandonnée : pas de paie cette fois.", C.alerte
		local perte = ligneAmitie(derniere.reponse.amitie)
		if perte then
			annonce ..= "\n" .. perte
		end
	end
	if annonce then
		local taille, hauteur = UiKit.mesureAnnonce(annonce, UiKit.LARGEUR_CONTENU) -- (« Nouveau : » peut tenir sur deux lignes)
		UiKit.texte({ Name = "Annonce", Text = annonce, Font = Enum.Font.GothamBold, TextSize = taille, TextColor3 = couleur, Size = UDim2.new(1, 0, 0, hauteur), Parent = ctx.contenu })
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
			-- « × » : on renonce, rien n'est commencé
			UiKit.boutonDoux({ Name = "AnnulerTaille", Text = "×", TextSize = 18, Position = UDim2.fromOffset(276, 8), Size = UDim2.fromOffset(34, 34), Parent = choix }, function()
				choix:Destroy()
				libre.Visible = true
			end)
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
	-- L'histoire : l'événement en cours ; sa prochaine robe commence par une conversation avec la cliente
	local evenement, ouvert = Histoire.enCours(etat)
	local texteEvenement
	if not evenement then
		texteEvenement = "Tous les événements du quartier ont eu lieu."
	elseif ouvert then
		local faites, total = Histoire.avancee(etat, evenement.id)
		texteEvenement = ("Événement : %s — robes livrées %d / %d"):format(evenement.nom, faites, total)
	elseif etat.livraisons < Histoire.LIVRAISONS_DEPART then
		texteEvenement = ("Bientôt : %s (après trois commandes livrées)"):format(evenement.nom)
	else
		texteEvenement = ("Bientôt : %s (prestige %d)"):format(evenement.nom, evenement.prestige)
	end
	UiKit.texte({ Name = "Evenement", Text = texteEvenement, Font = Enum.Font.GothamBold, Position = UDim2.fromOffset(0, y + 54), Size = UDim2.fromOffset(560, 22), Parent = ctx.contenu })
	if ouvert then
		local def = Histoire.prochaine(etat)
		local cliente = Clientes.get(def.cliente)
		local conversation = UiKit.arrondir(UiKit.creer("TextButton", { Name = "Conversation", Text = "", AutoButtonColor = false, Visible = false, BackgroundColor3 = C.panneau, Size = UDim2.fromScale(1, 1), ZIndex = 20, Parent = ctx.contenu }), 10)
		UiKit.texte({ Name = "Interlocutrice", Text = cliente.nom, Font = Enum.Font.GothamBold, TextSize = 18, Size = UDim2.new(1, -130, 0, 34), ZIndex = 21, Parent = conversation })
		local replique = UiKit.texte({ Name = "Replique", Text = def.repliques.demande, TextSize = 18, Position = UDim2.fromOffset(0, 44), Size = UDim2.new(1, 0, 0, 90), ZIndex = 21, Parent = conversation })
		local suivant, accepter
		suivant = UiKit.bouton({ Name = "SuivantConversation", Text = "Suivant", Position = UDim2.fromOffset(0, 150), Size = UDim2.fromOffset(200, 44), ZIndex = 21, Parent = conversation }, function()
			replique.Text = def.repliques.detail
			suivant.Visible = false
			accepter.Visible = true
		end)
		-- (à droite de « Suivant » : un double clic sur « Suivant » n'accepte pas la commande)
		accepter = UiKit.bouton({ Name = "AccepterCommande", Text = "Accepter la commande", Visible = false, Position = UDim2.fromOffset(220, 150), Size = UDim2.fromOffset(260, 44), ZIndex = 21, Parent = conversation }, function()
			conversation.Visible = false
			accueillie(ctx.session:commandeHistoire())
		end)
		UiKit.boutonDoux({ Name = "PlusTard", Text = "Plus tard", TextSize = 14, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -6, 0, 0), Size = UDim2.fromOffset(110, 34), ZIndex = 21, Parent = conversation }, function()
			conversation.Visible = false
		end)
		UiKit.bouton({ Name = "CommandeHistoire", Text = "Commande de l'événement", TextSize = 16, Position = UDim2.fromOffset(570, y + 48), Size = UDim2.fromOffset(260, 34), Parent = ctx.contenu }, function()
			replique.Text = def.repliques.demande
			suivant.Visible, accepter.Visible = true, false
			conversation.Visible = true
		end)
	end
	-- Une robe d'histoire livrée : la suite de l'histoire de sa cliente (sa réplique « merci »), dans un panneau (la
	-- bulle ne la montre que le temps de son départ) ; sous l'épilogue quand l'événement a lieu
	local faite = r and action == "livrer" and r.histoireFaite and Histoire.commande(r.histoireFaite)
	if faite then
		local suite = UiKit.arrondir(UiKit.creer("TextButton", { Name = "Suite", Text = "", AutoButtonColor = false, BackgroundColor3 = C.panneau, Size = UDim2.fromScale(1, 1), ZIndex = 21, Parent = ctx.contenu }), 10)
		UiKit.texte({ Name = "Interlocutrice", Text = Clientes.get(faite.cliente).nom, Font = Enum.Font.GothamBold, TextSize = 18, Size = UDim2.new(1, -130, 0, 34), ZIndex = 22, Parent = suite })
		UiKit.texte({ Name = "Replique", Text = faite.repliques.merci, TextSize = 18, Position = UDim2.fromOffset(0, 44), Size = UDim2.new(1, 0, 0, 90), ZIndex = 22, Parent = suite })
		UiKit.boutonDoux({ Name = "FermerSuite", Text = "Fermer", TextSize = 14, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -6, 0, 0), Size = UDim2.fromOffset(110, 34), ZIndex = 22, Parent = suite }, function()
			suite.Visible = false
		end)
	end
	-- Un événement vient d'avoir lieu : son épilogue et son souvenir, par-dessus l'accueil
	local eu = r and action == "livrer" and r.evenement
	if eu then
		local epilogue = UiKit.arrondir(UiKit.creer("TextButton", { Name = "Epilogue", Text = "", AutoButtonColor = false, BackgroundColor3 = C.panneau, Size = UDim2.fromScale(1, 1), ZIndex = 22, Parent = ctx.contenu }), 10)
		UiKit.texte({ Name = "TitreEpilogue", Text = Histoire.titreEpilogue(Histoire.get(eu.id)), Font = Enum.Font.GothamBold, TextSize = 20, TextColor3 = C.accent, Size = UDim2.new(1, -130, 0, 34), ZIndex = 23, Parent = epilogue })
		UiKit.texte({ Name = "TexteEpilogue", Text = eu.epilogue, TextSize = 18, Position = UDim2.fromOffset(0, 44), Size = UDim2.new(1, 0, 0, 90), ZIndex = 23, Parent = epilogue })
		local souvenir = Catalogue.accessoire(eu.souvenir)
		UiKit.texte({ Name = "Souvenir", Text = ("Souvenir : %s (une nouvelle décoration). Prestige : +%d."):format(souvenir and souvenir.nom or eu.souvenir, Histoire.PRESTIGE_EVENEMENT), TextSize = 16, Position = UDim2.fromOffset(0, 144), Size = UDim2.new(1, 0, 0, 44), ZIndex = 23, Parent = epilogue })
		UiKit.boutonDoux({ Name = "FermerEpilogue", Text = "Fermer", TextSize = 14, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -6, 0, 0), Size = UDim2.fromOffset(110, 34), ZIndex = 23, Parent = epilogue }, function()
			epilogue.Visible = false
		end)
	end
	-- Le courrier : chaque lettre annonce la première exigence de la commande ; « Inviter » fait venir la cliente
	if etat.livraisons >= EtatAtelier.COURRIER_APRES then
		UiKit.texte({ Name = "Courrier", Text = if #etat.lettres >= EtatAtelier.LETTRES_MAX then "Courrier (boîte pleine) :" elseif #etat.lettres > 0 then "Courrier :" else "Courrier : pas de lettre pour l'instant.", Font = Enum.Font.GothamBold, Position = UDim2.fromOffset(0, y + 88), Size = UDim2.fromOffset(500, 22), Parent = ctx.contenu })
		for i, l in ipairs(etat.lettres) do
			local fiche = Clientes.get(l.cliente)
			local yl = y + 114 + (i - 1) * 44
			UiKit.texte({ Name = "Lettre" .. i, Text = ("%s : « %s »"):format(fiche.nom:match("^(%S+)"), UiKit.exigence(l.commande.exigences[1], Catalogue)), TextSize = 16, Position = UDim2.fromOffset(0, yl + 6), Size = UDim2.fromOffset(600, 22), Parent = ctx.contenu })
			UiKit.boutonDoux({ Name = "Inviter_" .. i, Text = "Inviter", TextSize = 16, Position = UDim2.fromOffset(610, yl), Size = UDim2.fromOffset(120, 40), Parent = ctx.contenu }, function()
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
		-- Sous le titre, une liste qui défile (dix clientes et douze souvenirs ne tiennent pas dans la fenêtre)
		local liste = UiKit.creer("ScrollingFrame", { Name = "Liste", BackgroundTransparency = 1, BorderSizePixel = 0, Position = UDim2.fromOffset(0, 40), Size = UDim2.new(1, 0, 1, -40), ScrollBarThickness = 10, ScrollBarImageColor3 = C.accent, ScrollingDirection = Enum.ScrollingDirection.Y, ZIndex = 21, Parent = carnet })
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
				Position = UDim2.fromOffset(0, 4 + (k - 1) * 34),
				Size = UDim2.new(1, -14, 0, 30),
				ZIndex = 21,
				Parent = liste,
			})
		end
		local bas = 4 + #venues * 34
		-- Les événements qui ont eu lieu, et leurs souvenirs
		local passes = {}
		for _, ev in ipairs(Histoire.EVENEMENTS) do
			if Histoire.aEuLieu(etat, ev.id) then
				local souvenir = Catalogue.accessoire(ev.souvenir)
				table.insert(passes, ("%s — souvenir : %s"):format(ev.nom, souvenir and souvenir.nom or ev.souvenir))
			end
		end
		if #passes > 0 then
			UiKit.texte({ Name = "Souvenirs", Text = "Souvenirs du quartier :\n" .. table.concat(passes, "\n"), TextSize = 16, Position = UDim2.fromOffset(0, bas + 10), Size = UDim2.new(1, -14, 0, 22 * (#passes + 1)), TextYAlignment = Enum.TextYAlignment.Top, ZIndex = 21, Parent = liste })
			bas += 10 + 22 * (#passes + 1)
		end
		liste.CanvasSize = UDim2.fromOffset(0, bas)
		-- (à droite du choix de la taille d'une robe libre, qui s'étend jusqu'à x = 576)
		UiKit.boutonDoux({ Name = "OuvrirCarnetAdresses", Text = "Carnet d'adresses", Position = UDim2.fromOffset(592, ligne), Size = UDim2.fromOffset(220, 50), Parent = ctx.contenu }, function()
			carnet.Visible = true
		end)
	end
	-- E, fenêtre ouverte (pas pendant la saisie dans le chat, ni quand un panneau est ouvert par-dessus l'accueil :
	-- conversation, épilogue, suite de l'histoire, carnet d'adresses) : sonner la clochette
	local function panneauOuvert()
		for _, nom in ipairs({ "Conversation", "Epilogue", "Suite", "CarnetAdresses" }) do
			local p = ctx.contenu:FindFirstChild(nom)
			if p and p.Visible then
				return true
			end
		end
		return false
	end
	local connexion = UserInputService.InputBegan:Connect(function(input, traite)
		if not traite and input.KeyCode == Enum.KeyCode.E and ctx.fenetre.Visible and not panneauOuvert() then
			sonner()
		end
	end)
	return function()
		connexion:Disconnect()
	end
end
