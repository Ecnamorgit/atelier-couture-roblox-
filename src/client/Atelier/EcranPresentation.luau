-- Présentation (panneau à droite, la robe décorée sur le mannequin, vue de face) : la cliente regarde
-- la robe. On règle la photo (décor, lumière, couleur du mannequin), on la prend (sans l'interface),
-- on peut l'enregistrer dans la galerie ; puis on livre, ou on retourne aux décorations.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CaptureService = game:GetService("CaptureService")
local Couture = ReplicatedStorage:WaitForChild("Couture")
local Catalogue = require(Couture:WaitForChild("Catalogue"))
local Clientes = require(Couture:WaitForChild("Clientes"))
local Progression = require(Couture:WaitForChild("Progression"))
local Sons = require(script.Parent:WaitForChild("Sons"))

local CHOIX = {
	{ cle = "decor", nom = "Décor", prefixe = "Decor_", options = { { "rose", "Rose" }, { "bleu", "Bleu" }, { "creme", "Crème" }, { "nuit", "Nuit" } } },
	{ cle = "lumiere", nom = "Lumière", prefixe = "Lumiere_", options = { { "jour", "Jour" }, { "doux", "Doux" }, { "soir", "Soir" } } },
	{ cle = "mannequin", nom = "Mannequin", prefixe = "Mannequin_", options = { { "creme", "Crème" }, { "noir", "Noir" }, { "bois", "Bois" } } },
}

return function(ctx)
	local UiKit, session, contenu, scene = ctx.UiKit, ctx.session, ctx.contenu, ctx.scene
	local C = UiKit.COULEURS
	local etat = session.etat
	local bilan = etat:bilan() -- (la qualité tient compte de l'ajustement aux mesures de la cliente)
	local reglages = { decor = "creme", lumiere = "jour", mannequin = "creme" }

	local libre = etat.commande.libre
	UiKit.texte({ Text = if libre then "Ta robe libre est prête." else "La cliente examine ta robe.", TextSize = 16, Size = UDim2.new(1, 0, 0, 24), Parent = contenu })
	UiKit.texte({
		Name = "Qualite",
		Text = if libre
			then ("Qualité de la robe : %d %%"):format(math.floor(bilan.qualite * 100 + 0.5))
			else ("Qualité de la robe : %d %% (ajustement %d %%)"):format(math.floor(bilan.qualite * 100 + 0.5), math.floor(bilan.ajustement * 100 + 0.5)),
		Font = Enum.Font.GothamBold,
		TextSize = 18,
		Position = UDim2.fromOffset(0, 28),
		Size = UDim2.new(1, 0, 0, 26),
		Parent = contenu,
	})
	if libre then
		UiKit.texte({ Name = "PrixVente", Text = ("Prix de vente : %d po"):format(etat:prixVente()), Font = Enum.Font.GothamBold, TextSize = 16, Position = UDim2.fromOffset(0, 58), Size = UDim2.new(1, 0, 0, 22), Parent = contenu })
	else
		UiKit.texte({ Text = "Elle voulait :", TextSize = 14, TextColor3 = C.texteDoux, Position = UDim2.fromOffset(0, 58), Size = UDim2.new(1, 0, 0, 20), Parent = contenu })
	end
	for i, e in ipairs(etat.commande.exigences) do
		UiKit.texte({ Text = "· " .. UiKit.exigence(e, Catalogue, bilan.styles), TextSize = 14, Position = UDim2.fromOffset(0, 58 + i * 22), Size = UDim2.new(1, 0, 0, 20), Parent = contenu })
	end

	-- Réglages de la photo
	local boutons = {}
	local function rafraichir()
		for cle, liste in pairs(boutons) do
			for valeur, b in pairs(liste) do
				local actif = reglages[cle] == valeur
				b.BackgroundColor3 = actif and C.accent or C.secondaire
				b.TextColor3 = actif and Color3.new(1, 1, 1) or C.texte
			end
		end
		scene:photo(reglages)
	end
	for ligne, choix in ipairs(CHOIX) do
		local y = 148 + (ligne - 1) * 34
		UiKit.texte({ Text = choix.nom, TextSize = 14, Position = UDim2.fromOffset(0, y + 6), Size = UDim2.fromOffset(84, 20), Parent = contenu })
		boutons[choix.cle] = {}
		local largeur = (UiKit.LARGEUR_PANNEAU - 40 - 84) / #choix.options
		for k, option in ipairs(choix.options) do
			boutons[choix.cle][option[1]] = UiKit.boutonDoux({
				Name = choix.prefixe .. option[1],
				Text = option[2],
				TextSize = 14,
				Position = UDim2.fromOffset(84 + (k - 1) * largeur, y),
				Size = UDim2.fromOffset(largeur - 4, 30),
				Parent = contenu,
			}, function()
				reglages[choix.cle] = option[1]
				rafraichir()
			end)
		end
	end

	-- Aperçu de la photo prise. Un bouton sans texte, pas un simple cadre : dans Roblox, un cadre (même
	-- Active) laisse passer l'appui aux boutons cachés dessous (« Livrer la robe »…). « Fermer » est en
	-- haut, au-dessus des textes : un double appui ne tombe sur aucun bouton une fois l'aperçu refermé.
	local apercu = UiKit.arrondir(UiKit.creer("TextButton", { Name = "Apercu", Text = "", AutoButtonColor = false, Visible = false, BackgroundColor3 = C.panneau, Size = UDim2.new(1, 0, 1, 0), ZIndex = 20, Parent = contenu }), 10)
	local image = UiKit.creer("ImageLabel", { Name = "Image", BackgroundTransparency = 1, ScaleType = Enum.ScaleType.Fit, Position = UDim2.fromOffset(0, 42), Size = UDim2.new(1, 0, 0, 300), ZIndex = 21, Parent = apercu })
	UiKit.bouton({ Name = "EnregistrerPhoto", Text = "Enregistrer dans la galerie", TextSize = 16, Position = UDim2.fromOffset(0, 350), Size = UDim2.new(1, -6, 0, 42), ZIndex = 21, Parent = apercu }, function()
		local photo = image.Image
		local ok = pcall(function()
			CaptureService:PromptSaveCapturesToGallery({ photo }, function(resultats)
				if resultats and resultats[photo] then
					ctx.message("Photo enregistrée dans ta galerie.", C.ok)
				end
			end)
		end)
		if not ok then
			ctx.message("La galerie n'est pas disponible pour le moment.", C.erreur)
		end
	end, 0.4)
	UiKit.boutonDoux({ Name = "FermerApercu", Text = "Fermer", TextSize = 14, Position = UDim2.fromOffset(0, 0), Size = UDim2.new(1, -6, 0, 34), ZIndex = 21, Parent = apercu }, function()
		apercu.Visible = false
	end)

	-- Prise de vue : l'interface est cachée, la vue centrée sur la robe, le temps de la capture.
	-- Si Roblox refuse la capture ou ne répond pas, l'interface revient quand même. Chaque prise a son
	-- numéro : le minuteur ou la réponse tardive d'une prise terminée ne touchent pas à la suivante.
	local interface = ctx.fenetre.Parent
	local prises, enCours = 0, nil -- enCours : numéro de la prise en cours
	local function retablir(numero)
		if enCours == numero then
			enCours = nil
			interface.Enabled = true
			scene:cadrerPhoto(false)
		end
	end
	UiKit.bouton({ Name = "PrendrePhoto", Text = "Prendre la photo", TextSize = 16, Position = UDim2.fromOffset(0, 252), Size = UDim2.new(1, -6, 0, 40), Parent = contenu }, function()
		if enCours then
			return
		end
		prises += 1
		local numero = prises
		enCours = numero
		scene:cadrerPhoto(true)
		interface.Enabled = false
		task.delay(scene.ATTENTE_CAPTURE, function()
			if enCours == numero then
				retablir(numero) -- pas de réponse à temps : l'interface revient, le joueur est prévenu
				ctx.message("La photo n'a pas pu être prise.", C.erreur)
			end
		end)
		Sons.jouer("photo")
		local ok = pcall(function()
			CaptureService:CaptureScreenshot(function(capture)
				if enCours ~= numero then
					return -- prise abandonnée (sans réponse à temps)
				end
				retablir(numero)
				image.Image = capture
				apercu.Visible = true
			end)
		end)
		if not ok then
			retablir(numero)
			ctx.message("La photo n'a pas pu être prise.", C.erreur)
		end
	end, 0.4)

	-- Livrer met fin à la commande : loin de « Prendre la photo », et confirmé par un second appui. Une robe
	-- libre se vend (confirmé aussi) ou s'offre à une cliente déjà venue (choisie dans une liste)
	if libre then
		UiKit.boutonConfirme({ Name = "Vendre", Text = ("Vendre (%d po)"):format(etat:prixVente()), TextSize = 14, Position = UDim2.fromOffset(0, 312), Size = UDim2.new(0.5, -6, 0, 44), Parent = contenu }, function()
			local r = session:vendre()
			if not r.ok then
				ctx.refus(r)
			end
		end, true)
		local choix = UiKit.arrondir(UiKit.creer("TextButton", { Name = "ChoixCliente", Text = "", AutoButtonColor = false, Visible = false, BackgroundColor3 = C.panneau, Size = UDim2.new(1, 0, 1, 0), ZIndex = 20, Parent = contenu }), 10)
		UiKit.texte({ Text = "Offrir la robe à :", Font = Enum.Font.GothamBold, Size = UDim2.new(1, -110, 0, 34), ZIndex = 21, Parent = choix })
		UiKit.boutonDoux({ Name = "FermerChoixCliente", Text = "Annuler", TextSize = 14, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -6, 0, 0), Size = UDim2.fromOffset(100, 34), ZIndex = 21, Parent = choix }, function()
			choix.Visible = false
		end)
		local n = 0
		for _, c in ipairs(Clientes.LISTE) do
			local fiche = etat.clientes[c.id]
			if fiche and fiche.vues > 0 then
				local score = 0
				for _, style in ipairs(c.styles) do
					score = math.max(score, bilan.styles[style] or 0)
				end
				UiKit.boutonDoux({
					Name = "Offrir_" .. c.id,
					Text = ("%s · amitié +%d"):format(c.nom, Progression.gainCadeau(score)),
					TextSize = 14,
					Position = UDim2.fromOffset(0, 42 + n * 40), -- (dix clientes tiennent dans la fenêtre)
					Size = UDim2.new(1, -6, 0, 36),
					ZIndex = 21,
					Parent = choix,
				}, function()
					local r = session:offrir(c.id)
					if not r.ok then
						choix.Visible = false
						ctx.refus(r)
					end
				end)
				n += 1
			end
		end
		UiKit.boutonDoux({ Name = "Offrir", Text = "Offrir à…", Position = UDim2.new(0.5, 0, 0, 312), Size = UDim2.new(0.5, -6, 0, 44), Parent = contenu }, function()
			if n == 0 then
				ctx.message("Aucune cliente n'est encore venue.", C.texteDoux)
				return
			end
			choix.Visible = true
		end)
	else
		UiKit.boutonConfirme({ Name = "Livrer", Text = "Livrer la robe", Position = UDim2.fromOffset(0, 312), Size = UDim2.new(1, -6, 0, 44), Parent = contenu }, function()
			local r = session:livrer()
			if not r.ok then
				ctx.refus(r)
			end
		end, true)
	end
	UiKit.boutonDoux({ Name = "RetourDecorations", Text = "Retour aux décorations", TextSize = 14, Position = UDim2.fromOffset(0, 364), Size = UDim2.new(1, -6, 0, 32), Parent = contenu }, function()
		local r = session:retourDecorations()
		if not r.ok then
			ctx.refus(r)
		end
	end)
	UiKit.boutonConfirme({ Name = "Recommencer", Text = "Recommencer la robe", TextSize = 14, AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), Size = UDim2.fromOffset(200, 34), Parent = contenu }, function()
		local r = session:recommencer()
		if not r.ok then
			ctx.refus(r)
		end
	end)

	-- Fenêtre fermée (le joueur se promène) : décor, lumière et mannequin du jeu ; rouverte : réglages remis
	local connexion = ctx.fenetre:GetPropertyChangedSignal("Visible"):Connect(function()
		if ctx.fenetre.Visible then
			rafraichir()
		else
			scene:finirPhoto()
		end
	end)
	rafraichir()
	return function()
		connexion:Disconnect()
	end
end
