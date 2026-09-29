-- Écran du carnet de croquis : variantes des 4 familles, tissu de chaque pièce, jauges de style,
-- exigences de la cliente, métrage et coût du tissu à acheter, mis à jour en direct.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Couture = ReplicatedStorage:WaitForChild("Couture")
local Catalogue = require(Couture:WaitForChild("Catalogue"))
local Patron = require(Couture:WaitForChild("Patron"))
local Notation = require(Couture:WaitForChild("Notation"))
local Metrage = require(Couture:WaitForChild("Metrage"))
local EtatAtelier = require(Couture:WaitForChild("EtatAtelier"))
local Clientes = require(Couture:WaitForChild("Clientes"))
local Deblocages = require(Couture:WaitForChild("Deblocages"))
local Vignettes = require(script.Parent:WaitForChild("Vignettes"))

local NOMS_FAMILLES = { corsage = "Corsage", manches = "Manches", col = "Col", jupe = "Jupe" }
local CROQUIS_DEPART = { corsage = "corsage_droit", manches = "manches_sans", col = "col_sans", jupe = "jupe_droite" }

return function(ctx)
	local UiKit, session, contenu = ctx.UiKit, ctx.session, ctx.contenu
	local C = UiKit.COULEURS
	local etat = session.etat
	local croquis = table.clone(etat.croquis or CROQUIS_DEPART)
	local tissus = table.clone(etat.tissus or {})
	local dernierTissu = nil
	local rafraichir

	-- Colonne de gauche : variantes, puis pièces et tissus
	local gauche = UiKit.creer("Frame", { Name = "Gauche", BackgroundTransparency = 1, Size = UDim2.new(0, 540, 1, -56), Parent = contenu })
	local boutonsVariantes = {}
	for i, famille in ipairs(Catalogue.FAMILLES) do
		local y = (i - 1) * 46
		UiKit.texte({ Text = NOMS_FAMILLES[famille], Font = Enum.Font.GothamBold, Position = UDim2.fromOffset(0, y + 8), Size = UDim2.fromOffset(90, 24), Parent = gauche })
		for k, v in ipairs(Catalogue.variantesDe(famille)) do
			boutonsVariantes[v.id] = UiKit.boutonDoux({
				Name = "Variante_" .. v.id,
				Text = v.nom,
				TextSize = 14,
				Position = UDim2.fromOffset(90 + (k - 1) * 112, y),
				Size = UDim2.fromOffset(106, 38),
				Parent = gauche,
			}, function()
				if not Deblocages.ouvert(etat, "variantes", v.id) then
					ctx.message(Deblocages.message("variantes", v.id), C.texteDoux)
					return
				end
				croquis[famille] = v.id
				rafraichir()
			end)
		end
	end
	local listePieces = UiKit.creer("Frame", { Name = "Pieces", BackgroundTransparency = 1, Position = UDim2.fromOffset(0, 190), Size = UDim2.new(1, 0, 1, -190), Parent = gauche })

	-- Colonne de droite : commande, exigences, jauges
	local droite = UiKit.arrondir(UiKit.creer("Frame", { Name = "Droite", BackgroundColor3 = C.panneau, Position = UDim2.new(1, -310, 0, 0), Size = UDim2.new(0, 310, 1, -56), Parent = contenu }), 10)
	local fiche = etat.commande.cliente and Clientes.get(etat.commande.cliente)
	local qui = fiche and fiche.nom:match("^(%S+)") or "La cliente"
	UiKit.texte({ Text = ("%s (taille %s) veut :"):format(qui, etat.commande.taille), Font = Enum.Font.GothamBold, Position = UDim2.fromOffset(12, 8), Size = UDim2.new(1, -24, 0, 22), Parent = droite })
	local lignesExigences = {}
	for i, e in ipairs(etat.commande.exigences) do
		lignesExigences[i] = UiKit.texte({ Name = "Exigence" .. i, TextSize = 14, Position = UDim2.fromOffset(12, 10 + i * 22), Size = UDim2.new(1, -24, 0, 20), Parent = droite })
	end
	local jauges = {}
	local y0 = 30 + #etat.commande.exigences * 22 + 12
	for i, style in ipairs(Catalogue.STYLES) do
		local y = y0 + (i - 1) * 30
		UiKit.texte({ Text = Catalogue.NOMS_STYLES[style], TextSize = 14, Position = UDim2.fromOffset(12, y), Size = UDim2.fromOffset(100, 20), Parent = droite })
		local fond = UiKit.arrondir(UiKit.creer("Frame", { Name = "Jauge_" .. style, BackgroundColor3 = C.secondaire, Position = UDim2.fromOffset(112, y + 4), Size = UDim2.fromOffset(180, 12), Parent = droite }), 6)
		local plage = UiKit.creer("Frame", { Name = "Plage", BackgroundColor3 = C.accent, BackgroundTransparency = 0.65, BorderSizePixel = 0, Parent = fond })
		local acquis = UiKit.creer("Frame", { Name = "Acquis", BackgroundColor3 = C.accent, BorderSizePixel = 0, Parent = fond })
		local cibles = {}
		for _, e in ipairs(etat.commande.exigences) do
			if e.style == style then
				table.insert(cibles, UiKit.creer("Frame", { Name = "Cible", BackgroundColor3 = C.texte, BorderSizePixel = 0, Position = UDim2.new(e.valeur / 100, -1, 0, -3), Size = UDim2.new(0, 2, 1, 6), Parent = fond }))
			end
		end
		jauges[style] = { plage = plage, acquis = acquis }
	end
	-- Sous les jauges, en bas de la colonne : le tissu à acheter pour ce croquis, et son coût
	local metrage = UiKit.texte({ Name = "Metrage", TextSize = 14, AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 12, 1, -8), Size = UDim2.new(1, -24, 0, 46), Parent = droite })

	-- Choix du tissu d'une pièce (par-dessus le carnet), filtrable par style. Un bouton sans texte, pas un
	-- simple cadre : dans Roblox, un cadre (même Active) laisse passer l'appui aux boutons cachés dessous
	-- (variantes, « Valider le croquis »…), par exemple entre deux cartes de tissu
	local choix
	local function fermerChoix()
		if choix then
			choix:Destroy()
			choix = nil
		end
	end
	local function ouvrirChoix(pieces)
		fermerChoix()
		choix = UiKit.arrondir(UiKit.creer("TextButton", { Name = "ChoixTissu", Text = "", AutoButtonColor = false, BackgroundColor3 = C.fond, Size = UDim2.fromScale(1, 1), ZIndex = 10, Parent = contenu }), 10)
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
						UiKit.texte({ Text = ("%d po/m · %s"):format(t.prix, table.concat(etiquettes, ", ")), TextSize = 14, TextColor3 = C.texteDoux, Position = UDim2.fromOffset(72, 50), Size = UDim2.new(1, -80, 0, 36), ZIndex = 13, Parent = carte })
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
		-- Variantes choisies en surbrillance
		for id, b in pairs(boutonsVariantes) do
			local choisie = croquis[Catalogue.variante(id).famille] == id
			b.BackgroundColor3 = choisie and C.accent or C.secondaire
			b.TextColor3 = choisie and Color3.new(1, 1, 1) or C.texte
			UiKit.griser(b, not Deblocages.ouvert(etat, "variantes", id))
		end
		-- Pièces du croquis et leur tissu
		listePieces:ClearAllChildren()
		local pieces = Patron.piecesDuCroquis(croquis)
		for i, id in ipairs(pieces) do
			local y = (i - 1) * 36
			local t = tissus[id] and Catalogue.tissu(tissus[id])
			UiKit.texte({ Text = Catalogue.piece(id).nom, TextSize = 14, Position = UDim2.fromOffset(0, y + 6), Size = UDim2.fromOffset(200, 22), Parent = listePieces })
			local pastille = UiKit.arrondir(UiKit.creer("ImageLabel", { Name = "Pastille", BackgroundColor3 = t and UiKit.couleur(t.motif.couleurs[1]) or C.secondaire, ScaleType = Enum.ScaleType.Tile, TileSize = UDim2.fromOffset(64, 64), Position = UDim2.fromOffset(204, y + 4), Size = UDim2.fromOffset(26, 26), Parent = listePieces }), 13)
			pastille.BackgroundTransparency = t and 0 or 0.5
			local motif = t and Vignettes.motif(t.id)
			if motif then
				pastille.ImageContent = motif
			end
			UiKit.texte({ Text = t and t.nom or "(aucun tissu)", TextSize = 14, TextColor3 = t and C.texte or C.texteDoux, Position = UDim2.fromOffset(238, y + 6), Size = UDim2.fromOffset(170, 22), Parent = listePieces })
			UiKit.boutonDoux({ Name = "Tissu_" .. id, Text = "Tissu…", TextSize = 14, Position = UDim2.fromOffset(412, y), Size = UDim2.fromOffset(110, 32), Parent = listePieces }, function()
				ouvrirChoix({ id })
			end)
		end
		UiKit.boutonDoux({ Name = "ToutEnUnTissu", Text = "Même tissu pour toute la robe", TextSize = 14, Position = UDim2.fromOffset(0, #pieces * 36 + 4), Size = UDim2.fromOffset(260, 32), Parent = listePieces }, function()
			if dernierTissu then
				for _, id in ipairs(pieces) do
					tissus[id] = dernierTissu
				end
				rafraichir()
			else
				ouvrirChoix(pieces)
			end
		end)
		-- Jauges et exigences
		local choixPieces = {}
		for _, id in ipairs(pieces) do
			choixPieces[id] = tissus[id]
		end
		local fourchette = Notation.fourchette(croquis, choixPieces, Notation.accessoiresImposes(etat.commande.exigences))
		for style, j in pairs(jauges) do
			local f = fourchette[style]
			j.acquis.Size = UDim2.fromScale(f.min / 100, 1)
			j.plage.Size = UDim2.fromScale(f.max / 100, 1)
		end
		-- Tissu à acheter (le stock compte) et son coût
		local aAcheter, dm = Metrage.aAcheter(pieces, tissus, etat.stock)
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
			end
			lignesExigences[i].Text = SYMBOLES[statut] .. "  " .. texte
			lignesExigences[i].TextColor3 = COULEURS_STATUT[statut]
		end
	end

	UiKit.bouton({ Name = "Valider", Text = "Valider le croquis", AnchorPoint = Vector2.new(1, 1), Position = UDim2.fromScale(1, 1), Size = UDim2.fromOffset(240, 46), Parent = contenu }, function()
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
