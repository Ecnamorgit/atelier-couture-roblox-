-- Écran du carnet de croquis (sous-projet 5 : une page de carnet, comme chez une couturière). À gauche, la page :
-- les échantillons des tissus choisis épinglés, la robe dessinée de face et coloriée de ses tissus (la toucher
-- choisit le tissu de la partie touchée), les pièces et leur tissu, une ligne ◀ modèle ▶ par famille, le tissu
-- qu'il faudra environ, et « Tracer le patron ». À droite, la fiche de commande : exigences, jauges de style,
-- métrage et coût du tissu à acheter. Tout se met à jour en direct.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Couture = ReplicatedStorage:WaitForChild("Couture")
local Catalogue = require(Couture:WaitForChild("Catalogue"))
local Patron = require(Couture:WaitForChild("Patron"))
local Notation = require(Couture:WaitForChild("Notation"))
local Metrage = require(Couture:WaitForChild("Metrage"))
local EtatAtelier = require(Couture:WaitForChild("EtatAtelier"))
local Clientes = require(Couture:WaitForChild("Clientes"))
local Deblocages = require(Couture:WaitForChild("Deblocages"))
local Croquis = require(Couture:WaitForChild("Croquis"))
local Vignettes = require(script.Parent:WaitForChild("Vignettes"))
local Mercerie = require(script.Parent:WaitForChild("Mercerie"))

local NOMS_FAMILLES = { corsage = "Corsage", manches = "Manches", col = "Col", jupe = "Jupe" }
local ORDRE_LIGNES = { "corsage", "col", "manches", "jupe" } -- comme sur la page d'un carnet : du haut vers le bas
local CROQUIS_DEPART = { corsage = "corsage_droit", manches = "manches_sans", col = "col_sans", jupe = "jupe_droite" }
local PAPIER = Color3.fromRGB(250, 245, 232)
local LISERE = Color3.fromRGB(196, 168, 150)
local CRAYON = Color3.fromRGB(110, 90, 96)
local L_DESSIN, H_DESSIN = 212, 276 -- pixels de l'image du dessin (100 × 130 unités de croquis)
local HAUT_LIGNES, PAS_LIGNES = 282, 36 -- les lignes ◀ ▶ sous le dessin : assez grandes pour le doigt

return function(ctx)
	local UiKit, session, contenu = ctx.UiKit, ctx.session, ctx.contenu
	local C = UiKit.COULEURS
	local etat = session.etat
	local croquis = table.clone(etat.croquis or CROQUIS_DEPART)
	local tissus = table.clone(etat.tissus or {})
	local dernierTissu = nil
	local rafraichir, ouvrirChoix
	local dessinDemande = 0 -- numéro du dernier dessin demandé

	-- La page du carnet : papier, liseré, quelques notes au crayon dans la marge, un crayon posé
	local page = UiKit.arrondir(UiKit.creer("Frame", { Name = "Page", BackgroundColor3 = PAPIER, Size = UDim2.new(0, 540, 1, 0), Parent = contenu }), 10)
	UiKit.creer("UIStroke", { Color = LISERE, Thickness = 2, Parent = page })
	for _, note in ipairs({ { "poitrine", 14, 196 }, { "taille", 14, 216 }, { "ourlet", 14, 236 } }) do
		UiKit.texte({ Text = note[1], Font = Enum.Font.Kalam, TextSize = 14, TextColor3 = LISERE, Position = UDim2.fromOffset(note[2], note[3]), Size = UDim2.fromOffset(90, 18), Parent = page })
	end
	local crayon = UiKit.creer("Frame", { Name = "Crayon", BackgroundColor3 = Color3.fromRGB(214, 110, 140), BorderSizePixel = 0, Position = UDim2.fromOffset(74, 150), Size = UDim2.fromOffset(6, 100), Rotation = 12, Parent = page })
	UiKit.creer("Frame", { BackgroundColor3 = Color3.fromRGB(236, 206, 170), BorderSizePixel = 0, Position = UDim2.new(0, 0, 1, 0), Size = UDim2.fromOffset(6, 10), Parent = crayon })

	-- Les échantillons des tissus choisis, épinglés en haut à gauche
	local echantillons = UiKit.creer("Frame", { Name = "Echantillons", BackgroundTransparency = 1, Position = UDim2.fromOffset(10, 10), Size = UDim2.fromOffset(90, 180), Parent = page })

	-- La robe dessinée ; la toucher choisit le tissu de la partie touchée
	local dessin = UiKit.creer("ImageButton", { Name = "Dessin", BackgroundTransparency = 1, AutoButtonColor = false, Position = UDim2.fromOffset(106, 2), Size = UDim2.fromOffset(L_DESSIN, H_DESSIN), Parent = page })
	local sansDessin = UiKit.texte({ Name = "SansDessin", Text = "(le dessin ne peut pas s'afficher)", TextSize = 14, TextColor3 = CRAYON, TextXAlignment = Enum.TextXAlignment.Center, Size = UDim2.fromScale(1, 1), Visible = false, Parent = dessin })
	-- (le second appui d'un double clic sur une carte de tissu tombe sur le dessin ou une pièce, dessous : ignoré)
	local choixFerme = -math.huge
	local function appuiDessous()
		if os.clock() - choixFerme < UiKit.DELAI_NOUVEAU then
			return false
		end
		if UiKit.surClic then
			pcall(UiKit.surClic)
		end
		return true
	end
	dessin.Activated:Connect(function(entree)
		local position = entree and entree.Position
		if not position or dessin.AbsoluteSize.X <= 0 or not appuiDessous() then
			return
		end
		local u = (position.X - dessin.AbsolutePosition.X) / dessin.AbsoluteSize.X
		local v = (position.Y - dessin.AbsolutePosition.Y) / dessin.AbsoluteSize.Y
		-- (sous-projet 7 : une couche, un volant, ne choisit que le tissu de ses pièces)
		local famille, piecesTouchees = Croquis.partieA(croquis, u * Croquis.LARGEUR, v * Croquis.HAUTEUR)
		if famille then
			ouvrirChoix(piecesTouchees, famille)
		end
	end)

	-- Les pièces du croquis et leur tissu (une ligne par pièce : la toucher choisit son tissu)
	-- (une liste qui défile, au-dessus des lignes ◀ ▶ : une robe à couches a jusqu'à dix pièces)
	local listePieces = UiKit.creer("ScrollingFrame", { Name = "Pieces", BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 4, ScrollingDirection = Enum.ScrollingDirection.Y, Position = UDim2.fromOffset(334, 6), Size = UDim2.fromOffset(198, HAUT_LIGNES - 6 - 40), Parent = page })

	-- Une ligne ◀ modèle ▶ par famille, avec un point par modèle
	local lignes = {}
	for i, famille in ipairs(ORDRE_LIGNES) do
		local y = HAUT_LIGNES + (i - 1) * PAS_LIGNES
		local modeles = Catalogue.variantesDe(famille)
		UiKit.texte({ Text = NOMS_FAMILLES[famille], Font = Enum.Font.GothamBold, TextSize = 14, TextColor3 = CRAYON, Position = UDim2.fromOffset(14, y + 7), Size = UDim2.fromOffset(70, 20), Parent = page })
		local function tourner(pas)
			local rang = 1
			for k, m in ipairs(modeles) do
				if m.id == croquis[famille] then
					rang = k
				end
			end
			croquis[famille] = modeles[(rang - 1 + pas) % #modeles + 1].id
			rafraichir()
		end
		UiKit.boutonDoux({ Name = "Precedent_" .. famille, Text = "◀", TextSize = 30, TextColor3 = Color3.fromRGB(196, 120, 60), Position = UDim2.fromOffset(84, y), Size = UDim2.fromOffset(48, 34), Parent = page }, function()
			tourner(-1)
		end)
		local nom = UiKit.texte({ Name = "Modele_" .. famille, Font = Enum.Font.GothamBold, TextSize = 16, TextXAlignment = Enum.TextXAlignment.Center, Position = UDim2.fromOffset(136, y + 2), Size = UDim2.fromOffset(338, 18), Parent = page })
		UiKit.boutonDoux({ Name = "Suivant_" .. famille, Text = "▶", TextSize = 30, TextColor3 = Color3.fromRGB(196, 120, 60), Position = UDim2.fromOffset(478, y), Size = UDim2.fromOffset(48, 34), Parent = page }, function()
			tourner(1)
		end)
		local points = UiKit.creer("Frame", { Name = "Points_" .. famille, BackgroundTransparency = 1, Position = UDim2.fromOffset(136, y + 23), Size = UDim2.fromOffset(338, 7), Parent = page })
		UiKit.creer("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Center, Padding = UDim.new(0, 6), Parent = points })
		local pastilles = {}
		for k, m in ipairs(modeles) do
			pastilles[m.id] = UiKit.arrondir(UiKit.creer("Frame", { Name = "Point" .. k, BorderSizePixel = 0, Size = UDim2.fromOffset(7, 7), LayoutOrder = k, Parent = points }), 4)
		end
		lignes[famille] = { nom = nom, pastilles = pastilles }
	end
	local environ = UiKit.texte({ Name = "Environ", Font = Enum.Font.Kalam, TextSize = 16, TextColor3 = Color3.fromRGB(176, 70, 90), Position = UDim2.fromOffset(16, 432), Size = UDim2.fromOffset(270, 24), Parent = page })

	-- La fiche de commande, épinglée à droite : qui commande, exigences, jauges de style, métrage
	local droite = UiKit.arrondir(UiKit.creer("Frame", { Name = "Droite", BackgroundColor3 = C.panneau, Position = UDim2.new(1, -310, 0, 0), Size = UDim2.new(0, 310, 1, 0), Parent = contenu }), 10)
	UiKit.arrondir(UiKit.creer("Frame", { Name = "Epingle", BackgroundColor3 = C.accent, BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0, 4), Size = UDim2.fromOffset(10, 10), Parent = droite }), 5)
	local fiche = etat.commande.cliente and Clientes.get(etat.commande.cliente)
	local qui = fiche and fiche.nom:match("^(%S+)") or "La cliente"
	local entete = if etat.commande.libre then ("Robe libre (taille %s) : à ton idée."):format(etat.commande.taille) else ("%s (taille %s) veut :"):format(qui, etat.commande.taille)
	UiKit.texte({ Name = "Entete", Text = entete, Font = Enum.Font.GothamBold, Position = UDim2.fromOffset(12, 12), Size = UDim2.new(1, -24, 0, 22), Parent = droite })
	local lignesExigences = {}
	local yExigence = 36
	for i, e in ipairs(etat.commande.exigences) do
		-- (une exigence d'accessoire dit aussi ce qu'on en a dans la mercerie, sur une seconde ligne)
		local haut = if e.type == "accessoire" then 40 else 20
		lignesExigences[i] = UiKit.texte({ Name = "Exigence" .. i, TextSize = 14, TextYAlignment = Enum.TextYAlignment.Top, Position = UDim2.fromOffset(12, yExigence), Size = UDim2.new(1, -24, 0, haut), Parent = droite })
		yExigence += haut + 2
	end
	local jauges = {}
	local y0 = yExigence + 10
	for i, style in ipairs(Catalogue.STYLES) do
		local y = y0 + (i - 1) * 30
		UiKit.texte({ Text = Catalogue.NOMS_STYLES[style], TextSize = 14, Position = UDim2.fromOffset(12, y), Size = UDim2.fromOffset(100, 20), Parent = droite })
		local fond = UiKit.arrondir(UiKit.creer("Frame", { Name = "Jauge_" .. style, BackgroundColor3 = C.secondaire, Position = UDim2.fromOffset(112, y + 4), Size = UDim2.fromOffset(180, 12), Parent = droite }), 6)
		local plage = UiKit.creer("Frame", { Name = "Plage", BackgroundColor3 = C.accent, BackgroundTransparency = 0.65, BorderSizePixel = 0, Parent = fond })
		local acquis = UiKit.creer("Frame", { Name = "Acquis", BackgroundColor3 = C.accent, BorderSizePixel = 0, Parent = fond })
		for _, e in ipairs(etat.commande.exigences) do
			if e.style == style then
				UiKit.creer("Frame", { Name = "Cible", BackgroundColor3 = C.texte, BorderSizePixel = 0, Position = UDim2.new(e.valeur / 100, -1, 0, -3), Size = UDim2.new(0, 2, 1, 6), Parent = fond })
			end
		end
		jauges[style] = { plage = plage, acquis = acquis }
	end
	-- Sous les jauges, en bas de la fiche : le tissu à acheter pour ce croquis, et son coût
	local metrage = UiKit.texte({ Name = "Metrage", TextSize = 14, AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 12, 1, -8), Size = UDim2.new(1, -24, 0, 46), Parent = droite })

	-- Choix du tissu de pièces (par-dessus le carnet), filtrable par style. Un bouton sans texte, pas un simple
	-- cadre : dans Roblox, un cadre (même Active) laisse passer l'appui aux boutons cachés dessous (modèles,
	-- « Tracer le patron »…), par exemple entre deux cartes de tissu
	local choix
	local function fermerChoix()
		if choix then
			choix:Destroy()
			choix = nil
			choixFerme = os.clock()
		end
	end
	ouvrirChoix = function(pieces, famille)
		fermerChoix()
		choix = UiKit.arrondir(UiKit.creer("TextButton", { Name = "ChoixTissu", Text = "", AutoButtonColor = false, BackgroundColor3 = C.fond, Size = UDim2.fromScale(1, 1), ZIndex = 10, Parent = contenu }), 10)
		choix:SetAttribute("Famille", famille)
		choix:SetAttribute("Pieces", table.concat(pieces, ","))
		UiKit.boutonDoux({ Name = "FermerChoix", Text = "Retour", Position = UDim2.new(1, -120, 0, 0), Size = UDim2.fromOffset(110, 34), ZIndex = 11, Parent = choix }, fermerChoix)
		local grille = UiKit.creer("ScrollingFrame", {
			Name = "Grille",
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Position = UDim2.fromOffset(0, 44),
			Size = UDim2.new(1, 0, 1, -44),
			CanvasSize = UDim2.new(),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			ScrollBarThickness = 6,
			ZIndex = 11,
			Parent = choix,
		})
		UiKit.creer("UIGridLayout", { CellSize = UDim2.fromOffset(200, 96), CellPadding = UDim2.fromOffset(8, 8), Parent = grille })
		local function remplir(filtre)
			for _, enfant in ipairs(grille:GetChildren()) do
				if enfant:IsA("TextButton") then
					enfant:Destroy()
				end
			end
			for _, t in ipairs(Catalogue.Tissus) do
				if not filtre or (t.style[filtre] or 0) > 0 then
					local ouvert = Deblocages.ouvert(etat, "tissus", t.id)
					local carte = UiKit.arrondir(UiKit.creer("TextButton", { Name = "Tissu_" .. t.id, Text = "", AutoButtonColor = ouvert, BackgroundColor3 = if ouvert then C.panneau else C.ferme, ZIndex = 12, Parent = grille }), 8)
					carte:SetAttribute("Ferme", not ouvert)
					local motif = Vignettes.motif(t.id)
					local echantillon = UiKit.arrondir(UiKit.creer("ImageLabel", {
						BackgroundColor3 = UiKit.couleur(t.motif.couleurs[1]),
						Position = UDim2.fromOffset(8, 8),
						Size = UDim2.fromOffset(56, 80),
						ScaleType = Enum.ScaleType.Tile,
						TileSize = UDim2.fromOffset(64, 64),
						ZIndex = 13,
						Parent = carte,
					}), 6)
					if motif then
						echantillon.ImageContent = motif
					end
					UiKit.texte({ Text = t.nom, Font = Enum.Font.GothamBold, TextSize = 14, Position = UDim2.fromOffset(72, 8), Size = UDim2.new(1, -80, 0, 36), ZIndex = 13, Parent = carte })
					local styles = {}
					for s, pts in pairs(t.style) do
						table.insert(styles, { s = s, pts = pts })
					end
					table.sort(styles, function(a, b)
						return a.pts > b.pts
					end)
					local etiquettes = {}
					for k = 1, math.min(2, #styles) do
						table.insert(etiquettes, Catalogue.NOMS_STYLES[styles[k].s])
					end
					if ouvert then
						UiKit.texte({ Text = (if t.prix == 0 then "Gratuit" else ("%d po/m"):format(t.prix)) .. " · " .. table.concat(etiquettes, ", "), TextSize = 14, TextColor3 = C.texteDoux, Position = UDim2.fromOffset(72, 50), Size = UDim2.new(1, -80, 0, 36), ZIndex = 13, Parent = carte })
					else
						UiKit.texte({ Name = "Raison", Text = Deblocages.raison("tissus", t.id), Font = Enum.Font.GothamBold, TextSize = 14, TextColor3 = C.texteDoux, Position = UDim2.fromOffset(72, 50), Size = UDim2.new(1, -80, 0, 36), ZIndex = 13, Parent = carte })
						echantillon.ImageTransparency, echantillon.BackgroundTransparency = 0.6, 0.6
					end
					carte.Activated:Connect(function()
						if not Deblocages.ouvert(etat, "tissus", t.id) then
							ctx.message(Deblocages.message("tissus", t.id), C.texteDoux)
							return
						end
						for _, id in ipairs(pieces) do
							tissus[id] = t.id
						end
						dernierTissu = t.id
						fermerChoix()
						rafraichir()
					end)
				end
			end
		end
		local filtres = { { nom = "Tous" } }
		for _, s in ipairs(Catalogue.STYLES) do
			table.insert(filtres, { nom = Catalogue.NOMS_STYLES[s], style = s })
		end
		for k, f in ipairs(filtres) do
			UiKit.boutonDoux({ Name = "Filtre_" .. (f.style or "tous"), Text = f.nom, TextSize = 14, Position = UDim2.fromOffset((k - 1) * 106, 0), Size = UDim2.fromOffset(100, 34), ZIndex = 11, Parent = choix }, function()
				remplir(f.style)
			end)
		end
		remplir(nil)
	end

	rafraichir = function()
		local pieces = Patron.piecesDuCroquis(croquis)
		-- Le modèle de chaque famille, grisé avec ce qu'il faut pour l'ouvrir s'il est fermé, et ses points
		for famille, ligne in pairs(lignes) do
			local id = croquis[famille]
			local ouvert = Deblocages.ouvert(etat, "variantes", id)
			ligne.nom.Text = if ouvert then Catalogue.variante(id).nom else ("%s · %s"):format(Catalogue.variante(id).nom, Deblocages.raison("variantes", id))
			ligne.nom.TextColor3 = if ouvert then C.texte else C.texteDoux
			ligne.nom:SetAttribute("Ferme", not ouvert)
			for m, pastille in pairs(ligne.pastilles) do
				pastille.BackgroundColor3 = if m == id then C.accent else LISERE
			end
		end
		-- La robe dessinée, coloriée du tissu de la pièce de devant de chaque famille
		local tissusDessin = {}
		for _, famille in ipairs(Catalogue.FAMILLES) do
			local premiere = Catalogue.variante(croquis[famille]).pieces[1]
			tissusDessin[famille] = premiere and tissus[premiere] or nil
		end
		-- (sous-projet 7) une partie qui porte ses pièces, un volant, prend le tissu de la première
		for _, partie in ipairs(Croquis.parties(croquis)) do
			if partie.pieces then
				tissusDessin[partie.pieces[1]] = tissus[partie.pieces[1]]
			end
		end
		-- L'image se fige en attendant Roblox : à part, pour ne pas faire attendre le reste de l'écran ; seul le
		-- dernier dessin demandé s'affiche (deux modèles choisis coup sur coup peuvent arriver dans le désordre)
		dessinDemande += 1
		local demande, croquisDessin = dessinDemande, table.clone(croquis)
		task.spawn(function()
			local image = Vignettes.croquis(croquisDessin, tissusDessin, L_DESSIN, H_DESSIN)
			if demande ~= dessinDemande then
				return
			end
			if image then
				dessin.ImageContent = image
			end
			-- Mémoire des images pleine : pas de dessin (pas l'ancien non plus), un mot à la place ; le reste marche
			dessin.ImageTransparency = if image then 0 else 1
			sansDessin.Visible = image == nil
		end)
		-- Les échantillons épinglés : un par tissu choisi, dans l'ordre de la robe
		echantillons:ClearAllChildren()
		local deja = {}
		for _, id in ipairs(pieces) do
			local t = tissus[id] and Catalogue.tissu(tissus[id])
			if t and not deja[t.id] and #echantillons:GetChildren() < 4 then
				deja[t.id] = true
				local k = #echantillons:GetChildren() + 1
				local carre = UiKit.creer("ImageLabel", { Name = "Echantillon_" .. k, BackgroundColor3 = UiKit.couleur(t.motif.couleurs[1]), ScaleType = Enum.ScaleType.Tile, TileSize = UDim2.fromOffset(64, 64), Position = UDim2.fromOffset((k % 2 == 0) and 30 or 0, (k - 1) * 40), Size = UDim2.fromOffset(52, 52), Rotation = (k % 2 == 0) and 6 or -5, Parent = echantillons })
				UiKit.creer("UIStroke", { Color = LISERE, Thickness = 2, Parent = carre })
				UiKit.arrondir(UiKit.creer("Frame", { Name = "Epingle", BackgroundColor3 = C.accent, BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0, 3), Size = UDim2.fromOffset(8, 8), Parent = carre }), 4)
				local motif = Vignettes.motif(t.id)
				if motif then
					carre.ImageContent = motif
				end
			end
		end
		-- Les pièces et leur tissu : toucher une ligne choisit le tissu de cette pièce
		listePieces:ClearAllChildren()
		for i, id in ipairs(pieces) do
			local t = tissus[id] and Catalogue.tissu(tissus[id])
			local ligne = UiKit.arrondir(UiKit.creer("TextButton", { Name = "Tissu_" .. id, Text = "", AutoButtonColor = true, BackgroundColor3 = C.panneau, BackgroundTransparency = 0.3, Position = UDim2.fromOffset(0, (i - 1) * 36), Size = UDim2.fromOffset(192, 34), Parent = listePieces }), 6)
			ligne.Activated:Connect(function()
				if appuiDessous() then
					ouvrirChoix({ id })
				end
			end)
			local pastille = UiKit.arrondir(UiKit.creer("ImageLabel", { Name = "Pastille", BackgroundColor3 = t and UiKit.couleur(t.motif.couleurs[1]) or C.secondaire, ScaleType = Enum.ScaleType.Tile, TileSize = UDim2.fromOffset(64, 64), Position = UDim2.fromOffset(4, 4), Size = UDim2.fromOffset(26, 26), Parent = ligne }), 13)
			pastille.BackgroundTransparency = t and 0 or 0.5
			local motif = t and Vignettes.motif(t.id)
			if motif then
				pastille.ImageContent = motif
			end
			UiKit.texte({ Name = "Piece", Text = Catalogue.piece(id).nom, Font = Enum.Font.GothamBold, TextSize = 14, TextTruncate = Enum.TextTruncate.AtEnd, Position = UDim2.fromOffset(36, 1), Size = UDim2.fromOffset(158, 16), Parent = ligne })
			UiKit.texte({ Name = "Tissu", Text = t and t.nom or "(aucun tissu)", TextSize = 14, TextColor3 = t and C.texte or C.texteDoux, TextTruncate = Enum.TextTruncate.AtEnd, Position = UDim2.fromOffset(36, 17), Size = UDim2.fromOffset(158, 16), Parent = ligne })
		end
		listePieces.CanvasSize = UDim2.fromOffset(0, #pieces * 36)
		-- « Même tissu pour toute la robe », sous la liste, toujours en vue
		local ancienTout = page:FindFirstChild("ToutEnUnTissu")
		if ancienTout then
			ancienTout:Destroy()
		end
		UiKit.boutonDoux({ Name = "ToutEnUnTissu", Text = "Même tissu pour toute la robe", TextSize = 14, Position = UDim2.fromOffset(334, listePieces.Position.Y.Offset + listePieces.Size.Y.Offset + 4), Size = UDim2.fromOffset(192, 32), Parent = page }, function()
			if dernierTissu then
				for _, id in ipairs(pieces) do
					tissus[id] = dernierTissu
				end
				rafraichir()
			else
				ouvrirChoix(pieces)
			end
		end)
		-- Le tissu qu'il faudra, à peu près
		environ.Text = ("Environ %s m de tissu"):format((("%.1f"):format(Metrage.conseil(pieces) / 10)):gsub("%.", ","))
		-- Jauges et exigences
		local choixPieces = {}
		for _, id in ipairs(pieces) do
			choixPieces[id] = tissus[id]
		end
		local fourchette = Notation.fourchette(croquis, choixPieces, Notation.accessoiresImposes(etat.commande.exigences), Deblocages.ouverts(etat).tissus)
		for style, j in pairs(jauges) do
			local f = fourchette[style]
			j.acquis.Size = UDim2.fromScale(f.min / 100, 1)
			j.plage.Size = UDim2.fromScale(f.max / 100, 1)
		end
		-- Tissu à acheter (le stock neuf compte, pas la bande entamée) et son coût
		local aAcheter, dm = Metrage.aAcheter(pieces, tissus, etat:stocksNeufs())
		local prix = 0
		for _, t in ipairs(aAcheter) do
			prix += EtatAtelier.prix(t.tissu, t.manque)
		end
		if #aAcheter == 0 then
			metrage.Text, metrage.TextColor3 = "Choisis les tissus : le métrage et le coût s'affichent ici.", C.texteDoux
		elseif prix > etat.argent then
			metrage.Text = ("Tissu à acheter : %d dm, %d po — il te manque %d po."):format(dm, prix, prix - etat.argent)
			metrage.TextColor3 = C.erreur
		else
			metrage.Text, metrage.TextColor3 = ("Tissu à acheter : %d dm, %d po (tu as %d po)."):format(dm, prix, etat.argent), C.texte
		end
		local SYMBOLES = { ok = "✓", non = "×", ["?"] = "…" }
		local COULEURS_STATUT = { ok = C.ok, non = C.erreur, ["?"] = C.texteDoux }
		local ajustement = etat.commande.ajustement
		for i, e in ipairs(etat.commande.exigences) do
			local statut = Notation.prevision(e, croquis, choixPieces, fourchette, ajustement)
			local texte = UiKit.exigence(e, Catalogue)
			if e.type == "qualite" and ajustement and ajustement < 1 then
				texte ..= (" (ajustement %d %%)"):format(math.floor(ajustement * 100 + 0.5))
			elseif e.type == "accessoire" then
				local q = etat.mercerie[e.id] or 0
				texte ..= "\n      (en stock : " .. (if Catalogue.accessoire(e.id).genre == "garniture" then Mercerie.metres(q) .. " m" else tostring(q)) .. ")"
			end
			lignesExigences[i].Text = SYMBOLES[statut] .. "  " .. texte
			lignesExigences[i].TextColor3 = COULEURS_STATUT[statut]
		end
	end

	-- « Tracer le patron » : un modèle fermé ne se trace pas (on dit ce qu'il faut pour l'ouvrir)
	UiKit.bouton({ Name = "Valider", Text = "Tracer le patron", Position = UDim2.fromOffset(296, 428), Size = UDim2.fromOffset(230, 34), Parent = page }, function()
		for _, famille in ipairs(ORDRE_LIGNES) do
			if not Deblocages.ouvert(etat, "variantes", croquis[famille]) then
				ctx.message(Deblocages.message("variantes", croquis[famille]), C.texteDoux)
				return
			end
		end
		local pieces = Patron.piecesDuCroquis(croquis)
		local choixPieces = {}
		for _, id in ipairs(pieces) do
			choixPieces[id] = tissus[id]
		end
		local r = session:validerCroquis(croquis, choixPieces)
		if not r.ok then
			ctx.refus(r)
		end
	end)

	rafraichir()
	-- L'état peut changer sans action du carnet (réparé par le serveur) : argent et stock suivent
	local desabonner = session:surChangement(function(e)
		if e.etape == "carnet" then
			rafraichir()
		end
	end)
	return function()
		desabonner()
		fermerChoix()
	end
end
