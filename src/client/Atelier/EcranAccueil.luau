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
local Vignettes = require(script.Parent:WaitForChild("Vignettes"))

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

-- Le rang de la couturière vient de monter (robes livrées ou vendues) : « Nouveau rang : Couturière ! » ; sinon nil
local function nouveauRang(etat)
	local robes = etat.livraisons + etat.ventes
	local rang = Progression.rang(robes)
	return if rang ~= Progression.rang(robes - 1) then ("Nouveau rang : %s !"):format(rang.nom) else nil
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
		annonce = ("%s est ravie ! %s +%d pièces d'or (qualité %d %%). Sa robe est en vitrine."):format(
			fiche and fiche.nom:match("^(%S+)") or "La cliente",
			UiKit.etoiles(Progression.etoiles(true, r.bilan.qualite)),
			r.verse or r.paie,
			UiKit.pourcent(r.bilan.qualite)
		)
		if r.acompte and r.acompte > 0 then
			table.insert(suite, ("Acompte de %d déjà reçu"):format(r.acompte))
		end
		table.insert(suite, ligneAmitie(r.amitie))
		table.insert(suite, nouveauRang(ctx.session.etat))
	elseif action == "vendre" then
		annonce = ("Robe vendue ! +%d pièces d'or (qualité %d %%). Elle part en vitrine."):format(r.prix, UiKit.pourcent(r.bilan.qualite))
		table.insert(suite, nouveauRang(ctx.session.etat))
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
	-- La jauge de prestige, et le titre de la réputation : « Réputation : Appréciée (prestige 3) — 62 / 100 »
	local niveau = Progression.niveauPrestige(etat.prestige)
	local seuil, suivant = Progression.SEUILS_PRESTIGE[niveau], Progression.SEUILS_PRESTIGE[niveau + 1]
	local y = ligne + 66
	local reputation = ("Réputation : %s (prestige %d)"):format(Progression.titreReputation(niveau), niveau)
	UiKit.texte({
		Name = "Prestige",
		Text = if suivant then ("%s — %d / %d"):format(reputation, etat.prestige, suivant) else ("%s — %d, au plus haut"):format(reputation, etat.prestige),
		Font = Enum.Font.GothamBold,
		Position = UDim2.fromOffset(0, y),
		Size = UDim2.fromOffset(600, 22),
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
	-- La gazette, la suite de l'histoire et l'affiche s'empilent, leurs « Fermer » au même coin : le second appui
	-- d'un double clic sur celui du dessus ne ferme pas aussi le panneau de dessous
	local panneauFerme = -math.huge
	local function fermerPanneau(panneau)
		return function()
			if os.clock() - panneauFerme < UiKit.DELAI_NOUVEAU then
				return
			end
			panneauFerme = os.clock()
			panneau.Visible = false
		end
	end
	-- Des nouveautés viennent de s'ouvrir : l'affiche « Nouveautés à l'atelier ! », une carte par nouveauté (huit au
	-- plus), avec l'échantillon de chaque tissu ; sous la gazette et la suite de l'histoire, s'il y en a
	local nouveaux = r and (action == "livrer" or action == "vendre" or action == "offrir") and r.nouveaux
	if nouveaux and #nouveaux > 0 then
		local CARTES, GENRES = 8, { tissus = "Tissu", variantes = "Modèle", accessoires = "Décoration" }
		local affiche = UiKit.arrondir(UiKit.creer("TextButton", { Name = "Affiche", Text = "", AutoButtonColor = false, BackgroundColor3 = Color3.fromRGB(255, 244, 218), Size = UDim2.fromScale(1, 1), ZIndex = 20, Parent = ctx.contenu }), 10)
		UiKit.creer("UIStroke", { Color = C.accent, Thickness = 3, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = affiche })
		UiKit.texte({ Name = "TitreAffiche", Text = "Nouveautés à l'atelier !", Font = Enum.Font.GothamBlack, TextSize = 30, TextColor3 = C.accent, TextXAlignment = Enum.TextXAlignment.Center, Position = UDim2.fromOffset(0, 14), Size = UDim2.new(1, 0, 0, 40), ZIndex = 21, Parent = affiche })
		UiKit.texte({ Name = "SousTitre", Text = "Ta réputation grandit : voici ce qui vient d'arriver.", TextSize = 16, TextXAlignment = Enum.TextXAlignment.Center, Position = UDim2.fromOffset(0, 56), Size = UDim2.new(1, 0, 0, 22), ZIndex = 21, Parent = affiche })
		for k, n in ipairs(nouveaux) do
			if k > CARTES then
				break
			end
			local ligneCarte, colonne = (k - 1) // 4, (k - 1) % 4
			local carte = UiKit.arrondir(UiKit.creer("Frame", { Name = "Nouveau_" .. n.id, BackgroundColor3 = Color3.new(1, 1, 1), Position = UDim2.new(colonne * 0.25, 8, 0, 92 + ligneCarte * 152), Size = UDim2.new(0.25, -16, 0, 142), ZIndex = 21, Parent = affiche }), 8)
			local tissu = n.genre == "tissus" and Catalogue.tissu(n.id)
			local image = UiKit.arrondir(UiKit.creer("ImageLabel", { Name = "Image", BackgroundColor3 = if tissu then UiKit.couleur(tissu.motif.couleurs[1]) else C.secondaire, ScaleType = Enum.ScaleType.Tile, TileSize = UDim2.fromOffset(64, 64), AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 10), Size = UDim2.fromOffset(76, 76), ZIndex = 22, Parent = carte }), 8)
			UiKit.creer("UIStroke", { Color = Color3.fromRGB(226, 208, 196), Thickness = 1, Parent = image }) -- (un tissu blanc sur la carte blanche)
			local motif = tissu and Vignettes.motif(n.id)
			if motif then
				image.ImageContent = motif
			end
			if not tissu then
				UiKit.texte({ Name = "Genre", Text = GENRES[n.genre] or "", Font = Enum.Font.GothamBold, TextSize = 14, TextColor3 = C.accent, TextXAlignment = Enum.TextXAlignment.Center, Size = UDim2.fromScale(1, 1), ZIndex = 23, Parent = image })
			end
			UiKit.texte({ Name = "Nom", Text = n.nom, Font = Enum.Font.GothamBold, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Center, Position = UDim2.fromOffset(6, 92), Size = UDim2.new(1, -12, 0, 40), ZIndex = 22, Parent = carte })
		end
		if #nouveaux > CARTES then
			UiKit.texte({ Name = "EtEncore", Text = ("Et encore %d autres nouveautés."):format(#nouveaux - CARTES), Font = Enum.Font.GothamBold, TextSize = 16, TextXAlignment = Enum.TextXAlignment.Center, Position = UDim2.new(0, 0, 1, -34), Size = UDim2.new(1, 0, 0, 24), ZIndex = 21, Parent = affiche })
		end
		UiKit.boutonDoux({ Name = "FermerAffiche", Text = "Fermer", TextSize = 14, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -8, 0, 8), Size = UDim2.fromOffset(100, 32), ZIndex = 22, Parent = affiche }, fermerPanneau(affiche))
	end
	-- Une robe d'histoire livrée : la suite de l'histoire de sa cliente (sa réplique « merci »), dans un panneau
	-- (l'encadré de dialogue ne la montre que le temps de son départ) ; sous l'épilogue quand l'événement a lieu
	local faite = r and action == "livrer" and r.histoireFaite and Histoire.commande(r.histoireFaite)
	if faite then
		local suite = UiKit.arrondir(UiKit.creer("TextButton", { Name = "Suite", Text = "", AutoButtonColor = false, BackgroundColor3 = C.panneau, Size = UDim2.fromScale(1, 1), ZIndex = 21, Parent = ctx.contenu }), 10)
		UiKit.texte({ Name = "Interlocutrice", Text = Clientes.get(faite.cliente).nom, Font = Enum.Font.GothamBold, TextSize = 18, Size = UDim2.new(1, -130, 0, 34), ZIndex = 22, Parent = suite })
		UiKit.texte({ Name = "Replique", Text = faite.repliques.merci, TextSize = 18, Position = UDim2.fromOffset(0, 44), Size = UDim2.new(1, 0, 0, 90), ZIndex = 22, Parent = suite })
		UiKit.boutonDoux({ Name = "FermerSuite", Text = "Fermer", TextSize = 14, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -6, 0, 0), Size = UDim2.fromOffset(110, 34), ZIndex = 22, Parent = suite }, fermerPanneau(suite))
	end
	-- Un événement vient d'avoir lieu : la une de la gazette du quartier, par-dessus l'accueil (le journal, son numéro
	-- et le jour de l'atelier, le titre, l'épilogue en deux colonnes, le souvenir gagné)
	local eu = r and action == "livrer" and r.evenement
	if eu then
		local ev = Histoire.get(eu.id)
		local PAPIER, ENCRE = Color3.fromRGB(244, 238, 222), Color3.fromRGB(44, 36, 32)
		local epilogue = UiKit.arrondir(UiKit.creer("TextButton", { Name = "Epilogue", Text = "", AutoButtonColor = false, BackgroundColor3 = PAPIER, Size = UDim2.fromScale(1, 1), ZIndex = 22, Parent = ctx.contenu }), 4)
		UiKit.creer("UIStroke", { Color = ENCRE, Thickness = 2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = epilogue })
		UiKit.texte({ Name = "Journal", Text = Histoire.GAZETTE, Font = Enum.Font.Garamond, TextSize = 42, TextColor3 = ENCRE, TextXAlignment = Enum.TextXAlignment.Center, Position = UDim2.fromOffset(0, 8), Size = UDim2.new(1, 0, 0, 46), ZIndex = 23, Parent = epilogue })
		UiKit.texte({ Name = "Date", Text = ("N° %d — Jour %d de l'atelier — Édition du quartier"):format(ev.rang, etat.livraisons + etat.ventes), Font = Enum.Font.Garamond, TextSize = 16, TextColor3 = ENCRE, TextXAlignment = Enum.TextXAlignment.Center, Position = UDim2.fromOffset(0, 56), Size = UDim2.new(1, 0, 0, 20), ZIndex = 23, Parent = epilogue })
		for k, y in ipairs({ 80, 84 }) do -- le double filet sous le titre du journal
			UiKit.creer("Frame", { Name = "Filet" .. k, BackgroundColor3 = ENCRE, BorderSizePixel = 0, Position = UDim2.new(0, 16, 0, y), Size = UDim2.new(1, -32, 0, k), ZIndex = 23, Parent = epilogue })
		end
		UiKit.texte({ Name = "TitreEpilogue", Text = Histoire.titreEpilogue(ev), Font = Enum.Font.Merriweather, TextSize = 26, TextColor3 = ENCRE, TextXAlignment = Enum.TextXAlignment.Center, Position = UDim2.fromOffset(16, 96), Size = UDim2.new(1, -32, 0, 36), ZIndex = 23, Parent = epilogue })
		local colonne1, colonne2 = Histoire.enColonnes(eu.epilogue)
		UiKit.texte({ Name = "Colonne1", Text = colonne1, Font = Enum.Font.Merriweather, TextSize = 20, TextColor3 = ENCRE, TextYAlignment = Enum.TextYAlignment.Top, Position = UDim2.fromOffset(24, 146), Size = UDim2.new(0.5, -40, 0, 170), ZIndex = 23, Parent = epilogue })
		UiKit.creer("Frame", { Name = "Separation", BackgroundColor3 = ENCRE, BorderSizePixel = 0, Position = UDim2.new(0.5, -1, 0, 146), Size = UDim2.fromOffset(1, 160), ZIndex = 23, Parent = epilogue })
		UiKit.texte({ Name = "Colonne2", Text = colonne2, Font = Enum.Font.Merriweather, TextSize = 20, TextColor3 = ENCRE, TextYAlignment = Enum.TextYAlignment.Top, Position = UDim2.new(0.5, 16, 0, 146), Size = UDim2.new(0.5, -40, 0, 170), ZIndex = 23, Parent = epilogue })
		-- En bas de la une, les nouvelles de l'atelier : sa réputation et le rang de la couturière
		UiKit.texte({ Name = "Nouvelles", Text = ("À l'atelier : réputation %s ; rang : %s."):format(Progression.titreReputation(Progression.niveauPrestige(etat.prestige)):lower(), Progression.texteRang(etat.livraisons + etat.ventes)), Font = Enum.Font.Merriweather, TextSize = 16, TextColor3 = ENCRE, TextXAlignment = Enum.TextXAlignment.Center, Position = UDim2.new(0, 16, 1, -92), Size = UDim2.new(1, -32, 0, 36), ZIndex = 23, Parent = epilogue })
		UiKit.creer("Frame", { Name = "FiletBas", BackgroundColor3 = ENCRE, BorderSizePixel = 0, Position = UDim2.new(0, 16, 1, -100), Size = UDim2.new(1, -32, 0, 1), ZIndex = 23, Parent = epilogue })
		local souvenir = Catalogue.accessoire(eu.souvenir)
		UiKit.texte({ Name = "Souvenir", Text = ("Souvenir : %s (une nouvelle décoration). Prestige : +%d."):format(souvenir and souvenir.nom or eu.souvenir, Histoire.PRESTIGE_EVENEMENT), Font = Enum.Font.GothamBold, TextSize = 16, TextColor3 = C.accent, TextXAlignment = Enum.TextXAlignment.Center, Position = UDim2.new(0, 16, 1, -54), Size = UDim2.new(1, -32, 0, 24), ZIndex = 23, Parent = epilogue })
		UiKit.boutonDoux({ Name = "FermerEpilogue", Text = "Fermer", TextSize = 14, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -8, 0, 8), Size = UDim2.fromOffset(100, 32), ZIndex = 24, Parent = epilogue }, fermerPanneau(epilogue))
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
		-- En tête : le rang de la couturière (robes livrées ou vendues)
		UiKit.texte({ Name = "TitreAdresses", Text = "Carnet d'adresses — " .. Progression.texteRang(etat.livraisons + etat.ventes), Font = Enum.Font.GothamBold, Size = UDim2.new(1, -130, 0, 34), ZIndex = 21, Parent = carnet })
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
	-- conversation, épilogue, suite de l'histoire, carnet d'adresses, affiche des nouveautés) : sonner la clochette
	local function panneauOuvert()
		for _, nom in ipairs({ "Conversation", "Epilogue", "Suite", "CarnetAdresses", "Affiche" }) do
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
