-- Écran de couture : la pièce passe sous l'aiguille, une couture après l'autre. On maintient « Coudre »
-- (ou Espace) pour faire avancer le tissu, et on le fait pivoter (A / D, ← / →, les boutons ◀ ▶, ou en glissant) pour
-- garder l'aiguille sur le pointillé ; dans un angle, on s'arrête et on pivote (sous-projet 8). Vitesse tortue ↔ lapin
-- (W / S), découd-vite, assistance qui tient la ligne (note plafonnée). La logique est dans MachineCoudre.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")
local Couture = ReplicatedStorage:WaitForChild("Couture")
local Catalogue = require(Couture:WaitForChild("Catalogue"))
local Polygone = require(Couture:WaitForChild("Polygone"))
local MachineCoudre = require(script.Parent:WaitForChild("MachineCoudre"))
local GuideCouture = require(script.Parent:WaitForChild("GuideCouture"))
local Vignettes = require(script.Parent:WaitForChild("Vignettes"))
local Sons = require(script.Parent:WaitForChild("Sons"))

local PX = 80 -- pixels par dm sous l'aiguille : 0,05 dm de tolérance = 4 px
local LARGEUR_PLATEAU = 480
local COURSE = 100 -- px de glisser pour pivoter à fond (à l'échelle 1)
local ZONE_MORTE = 10 -- px (à l'échelle 1) : un pouce qui s'écrase en appuyant ne fait pas pivoter le tissu
local BOIS = Color3.fromRGB(205, 170, 125)
local FIL = Color3.fromRGB(60, 40, 50)
local VITESSES = { { "tortue", "Tortue" }, { "normale", "Normale" }, { "lapin", "Lapin" } }
local ACTION_ESPACE = "AtelierCoudre" -- Espace coud (au lieu de sauter) tant que la machine est affichée
local ACTION_PIVOT = "AtelierPivoter" -- A / D, ← / → : pivoter le tissu ; W / S : la vitesse
local TOUCHES_PIVOT = { [Enum.KeyCode.A] = 1, [Enum.KeyCode.Left] = 1, [Enum.KeyCode.D] = -1, [Enum.KeyCode.Right] = -1 }
local TOUCHES_VITESSE = { [Enum.KeyCode.W] = 1, [Enum.KeyCode.Up] = 1, [Enum.KeyCode.S] = -1, [Enum.KeyCode.Down] = -1 }
local RYTHMES = { tortue = 0.8, normale = 1, lapin = 1.3 } -- vitesse du son de la machine
-- (plan 26) L'écart en couleur : vert sur la ligne (la note entière), orange un peu à côté, rouge au-delà
local PRES, LOIN = 0.05, 0.15 -- dm
local SIGNAL_ANGLE = 0.5 -- dm : l'angle qui arrive est annoncé
local PENCHE = math.rad(25) -- au-delà, le pointillé penche trop : « Pivote »
local DUREE_PARFAIT = 1.5 -- s

return function(ctx)
	local UiKit, session, contenu = ctx.UiKit, ctx.session, ctx.contenu
	local C = UiKit.COULEURS
	local connexions = {}
	local machine, boite
	local vitesse, assistance = "normale", false
	local tenu = nil -- appui en cours : { entree, objet, x0, x }
	local pivots = {} -- touches et boutons de pivot tenus : [clé] = sens (1 : ◀, −1 : ▶)
	local points = {} -- un point de couture par mesure

	-- Plateau de la machine : le tissu bouge, l'aiguille reste au centre
	local plateau = UiKit.arrondir(UiKit.creer("Frame", {
		Name = "Plateau",
		BackgroundColor3 = BOIS,
		ClipsDescendants = true,
		Size = UDim2.new(0, LARGEUR_PLATEAU, 1, 0),
		Parent = contenu,
	}), 10)
	local tissu = UiKit.creer("Frame", { Name = "Tissu", AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 1, Parent = plateau })
	local image
	local pointille = UiKit.creer("Frame", { Name = "Pointille", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Parent = tissu })
	local calquePoints = UiKit.creer("Frame", { Name = "Points", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Parent = tissu })
	UiKit.creer("Frame", { Name = "Barre", AnchorPoint = Vector2.new(0.5, 1), BackgroundColor3 = Color3.fromRGB(150, 150, 160), BorderSizePixel = 0, Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(4, 60), Parent = plateau })
	local aiguille = UiKit.arrondir(UiKit.creer("Frame", { Name = "Aiguille", AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 1, Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(12, 12), Parent = plateau }), 6)
	local contourAiguille = UiKit.creer("UIStroke", { Name = "Contour", Color = C.ok, Thickness = 2, Parent = aiguille })
	-- (plan 26) L'angle qui vient, marqué sur le pointillé ; le signal et « Parfait ! » en haut du plateau
	local marqueAngle = UiKit.arrondir(UiKit.creer("Frame", { Name = "Angle", AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 1, Size = UDim2.fromOffset(14, 14), Visible = false, Parent = tissu }), 7)
	UiKit.creer("UIStroke", { Color = C.accent, Thickness = 2, Parent = marqueAngle })
	local signal = UiKit.arrondir(UiKit.texte({ Name = "Signal", Text = "", Font = Enum.Font.GothamBold, TextSize = 16, TextColor3 = Color3.new(1, 1, 1), TextXAlignment = Enum.TextXAlignment.Center, BackgroundColor3 = C.accent, BackgroundTransparency = 0.1, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 10), Size = UDim2.new(1, -40, 0, 30), Visible = false, Parent = plateau }), 8)
	-- (plan 26) Les conseils pas à pas, en bas du plateau : à la première robe, puis sur demande (« ? »)
	local bulle = UiKit.arrondir(UiKit.texte({ Name = "Conseil", Text = "", TextSize = 16, TextXAlignment = Enum.TextXAlignment.Center, BackgroundColor3 = C.panneau, BackgroundTransparency = 0.05, AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -12), Size = UDim2.new(1, -40, 0, 64), Visible = false, Parent = plateau }), 10)
	UiKit.creer("UIStroke", { Color = C.accent, Thickness = 2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = bulle })
	UiKit.creer("UIPadding", { PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12), Parent = bulle })
	local guide = nil
	local parfait = UiKit.arrondir(UiKit.texte({ Name = "Parfait", Text = "Parfait !", Font = Enum.Font.GothamBold, TextSize = 22, TextColor3 = Color3.new(1, 1, 1), TextXAlignment = Enum.TextXAlignment.Center, BackgroundColor3 = C.ok, BackgroundTransparency = 0, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 48), Size = UDim2.fromOffset(160, 36), Visible = false, Parent = plateau }), 18)
	local finParfait = 0

	-- Panneau de commandes
	local panneau = UiKit.creer("Frame", { Name = "Panneau", BackgroundTransparency = 1, Position = UDim2.fromOffset(LARGEUR_PLATEAU + 16, 0), Size = UDim2.new(1, -(LARGEUR_PLATEAU + 16), 1, 0), Parent = contenu })
	-- (une liste qui défile : une robe à couches a jusqu'à dix pièces)
	local ids = session.etat:piecesDuCroquis()
	local listePieces = UiKit.creer("ScrollingFrame", { Name = "Pieces", BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 4, ScrollingDirection = Enum.ScrollingDirection.Y, CanvasSize = UDim2.fromOffset(0, #ids * 24), Position = UDim2.fromOffset(0, 0), Size = UDim2.new(1, 0, 0, 120), Parent = panneau })
	local lignes = {}
	for i, id in ipairs(ids) do
		lignes[id] = UiKit.texte({ Name = "Ligne" .. i, TextSize = 14, Position = UDim2.fromOffset(0, (i - 1) * 24), Size = UDim2.new(1, 0, 0, 22), Parent = listePieces })
	end
	local note = UiKit.texte({ Name = "Note", Font = Enum.Font.GothamBold, TextSize = 18, Position = UDim2.fromOffset(0, 124), Size = UDim2.new(1, -46, 0, 22), Parent = panneau })
	-- (plan 26) la jauge de précision, et le tissu (s'il glisse)
	local montrerConseil
	UiKit.boutonDoux({ Name = "Aide", Text = "?", TextSize = 18, Position = UDim2.new(1, -40, 0, 120), Size = UDim2.fromOffset(34, 28), Parent = panneau }, function()
		guide = GuideCouture.nouveau() -- les conseils reprennent au premier
		montrerConseil()
	end)
	local jauge = UiKit.arrondir(UiKit.creer("Frame", { Name = "Precision", BackgroundColor3 = C.secondaire, BorderSizePixel = 0, Position = UDim2.fromOffset(0, 150), Size = UDim2.new(1, -6, 0, 6), Parent = panneau }), 3)
	local remplissage = UiKit.arrondir(UiKit.creer("Frame", { Name = "Remplissage", BackgroundColor3 = C.ok, BorderSizePixel = 0, Size = UDim2.fromScale(0, 1), Parent = jauge }), 3)
	local ligneTissu = UiKit.texte({ Name = "Tissu", Text = "", TextSize = 14, TextColor3 = C.texteDoux, Position = UDim2.fromOffset(0, 160), Size = UDim2.new(1, 0, 0, 18), Parent = panneau })
	local consigne = UiKit.texte({
		Text = "Tiens « Coudre » (ou Espace) pour avancer ; ◀ ▶ (A / D) font pivoter le tissu : garde l'aiguille sur le pointillé. Dans un angle, arrête-toi et pivote.",
		TextSize = 14,
		TextColor3 = C.texteDoux,
		Position = UDim2.fromOffset(0, 180),
		Size = UDim2.new(1, 0, 0, 52),
		Parent = panneau,
	})
	-- Pièce finie : on peut encore découdre ; elle n'est rendue qu'avec ce bouton (loin de « Coudre »)
	local rendre
	local boutonSuivante = UiKit.bouton({ Name = "PieceSuivante", Text = "Pièce suivante", TextSize = 16, Visible = false, Position = UDim2.fromOffset(0, 182), Size = UDim2.new(1, -6, 0, 42), Parent = panneau }, function()
		if machine and machine:fini() then
			rendre()
		end
	end, 0.4)
	local boutonsVitesse = {}
	local rafraichir
	for k, v in ipairs(VITESSES) do
		boutonsVitesse[v[1]] = UiKit.boutonDoux({ Name = "Vitesse_" .. v[1], Text = v[2], TextSize = 14, Position = UDim2.new((k - 1) / 3, 0, 0, 236), Size = UDim2.new(1 / 3, -6, 0, 34), Parent = panneau }, function()
			vitesse = v[1]
			if machine then
				machine:choisirVitesse(vitesse)
			end
			rafraichir()
		end)
	end
	local boutonAssistance = UiKit.boutonDoux({ Name = "Assistance", TextSize = 14, Position = UDim2.fromOffset(0, 278), Size = UDim2.new(1, -6, 0, 34), Parent = panneau }, function()
		assistance = not assistance
		if machine then
			machine:activerAssistance(assistance)
		end
		rafraichir()
	end)
	local effacerPoints
	UiKit.boutonDoux({ Name = "Decoudre", Text = "Découdre (découd-vite)", TextSize = 14, Position = UDim2.fromOffset(0, 320), Size = UDim2.new(1, -6, 0, 34), Parent = panneau }, function()
		if machine and machine:decoudre() then
			Sons.jouer("decoudre")
			effacerPoints()
			rafraichir()
		end
	end)
	local boutonCoudre = UiKit.bouton({ Name = "Coudre", Text = "Coudre (maintenir)", TextSize = 18, Position = UDim2.fromOffset(0, 362), Size = UDim2.new(1, -124, 0, 58), Parent = panneau })
	-- ◀ ▶ : pivoter le tissu, tenus (au doigt, avec un autre doigt que celui qui tient « Coudre »)
	local boutonsPivot = {
		UiKit.boutonDoux({ Name = "PivoterGauche", Text = "◀", TextSize = 28, Position = UDim2.new(1, -118, 0, 362), Size = UDim2.fromOffset(54, 58), Parent = panneau }),
		UiKit.boutonDoux({ Name = "PivoterDroite", Text = "▶", TextSize = 28, Position = UDim2.new(1, -60, 0, 362), Size = UDim2.fromOffset(54, 58), Parent = panneau }),
	}
	UiKit.boutonConfirme({ Name = "Recommencer", Text = "Recommencer la robe", TextSize = 14, AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), Size = UDim2.fromOffset(200, 34), Parent = panneau }, function()
		local r = session:recommencer()
		if not r.ok then
			ctx.refus(r)
		end
	end)

	-- Repère du tissu (px) d'un point du patron (dm)
	local function versTissu(p)
		return (p.x - boite.minX) * PX, (p.y - boite.minY) * PX
	end

	-- Une pièce passe sous l'aiguille : image du vrai tissu, pointillé des coutures
	local function commencerPiece(id)
		machine = MachineCoudre.nouvelle(id, session.rng:NextInteger(1, 1000000), Catalogue.tissu(session.etat.tissus[id]).matiere)
		machine:choisirVitesse(vitesse)
		machine:activerAssistance(assistance)
		boite = Polygone.boite(Catalogue.piece(id).contour)
		tissu.Size = UDim2.fromOffset((boite.maxX - boite.minX) * PX, (boite.maxY - boite.minY) * PX)
		local etat = session.etat
		if image then
			image:Destroy()
		end
		image = UiKit.creer("ImageLabel", {
			Name = "Piece",
			BackgroundColor3 = UiKit.couleur(Catalogue.tissu(etat.tissus[id]).motif.couleurs[1]),
			Size = UDim2.fromScale(1, 1),
			ZIndex = 0,
			Parent = tissu,
		})
		-- (plan 26) le tissu, et ce qu'il fait sous l'aiguille
		local t = Catalogue.tissu(etat.tissus[id])
		ligneTissu.Text = t.nom .. " : " .. (if machine.glisse >= 1.4 then "un tissu qui glisse, tiens-le bien" elseif machine.glisse <= 0.8 then "un tissu stable" else "un tissu qui tire un peu")
		local contenuImage = Vignettes.piece(id, etat.tissus[id], etat.coupees[id], 256)
		if contenuImage then
			image.ImageContent = contenuImage
			image.BackgroundTransparency = 1
		end -- sinon (mémoire des images pleine) : la couleur du tissu
		pointille:ClearAllChildren()
		for _, seg in ipairs(machine.segments) do
			local ax, ay = versTissu(seg.a)
			local bx, by = versTissu(seg.b)
			local longueur = math.sqrt((bx - ax) ^ 2 + (by - ay) ^ 2)
			local angle = math.deg(math.atan2(by - ay, bx - ax))
			local tirets = math.max(1, math.floor(longueur / (0.2 * PX)))
			for t = 0, tirets - 1 do
				local f = (t + 0.25) / tirets
				UiKit.creer("Frame", {
					AnchorPoint = Vector2.new(0.5, 0.5),
					BackgroundColor3 = FIL,
					BorderSizePixel = 0,
					Position = UDim2.fromOffset(ax + (bx - ax) * f, ay + (by - ay) * f),
					Size = UDim2.fromOffset(0.1 * PX, 2),
					Rotation = angle,
					Parent = pointille,
				})
			end
		end
		effacerPoints()
	end

	effacerPoints = function()
		for i = #points, #machine.ecarts + 1, -1 do
			points[i]:Destroy()
			points[i] = nil
		end
	end

	-- (plan 26) la couleur d'un écart : vert sur la ligne, orange un peu à côté, rouge hors de la ligne
	local function couleurEcart(e)
		local a = math.abs(e)
		return if a <= PRES + 1e-9 then C.ok elseif a <= LOIN then C.alerte else C.erreur
	end
	local function ajouterPoints()
		local e = machine:etat()
		local x, y = versTissu(e.point)
		for i = #points + 1, #machine.ecarts do
			points[i] = UiKit.creer("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = couleurEcart(machine.ecarts[i]), BorderSizePixel = 0, Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(4, 4), Parent = calquePoints })
		end
	end

	-- Le tissu tourne pour que la couture en cours monte vers l'aiguille quand il est droit ; de travers, elle penche
	-- (l'aiguille avance toujours vers le haut de l'écran) ; il se place sous l'aiguille
	local function dessiner()
		local e = machine:etat()
		local phi = -math.pi / 2 - math.atan2(e.direction.y, e.direction.x) - e.angle
		local vx = (e.point.x - (boite.minX + boite.maxX) / 2) * PX
		local vy = (e.point.y - (boite.minY + boite.maxY) / 2) * PX
		local c, s = math.cos(phi), math.sin(phi)
		tissu.Rotation = math.deg(phi)
		tissu.Position = UDim2.new(0.5, -(vx * c - vy * s), 0.5, -(vx * s + vy * c))
		-- (plan 26) en direct : la couleur de l'aiguille, l'angle qui vient, le signal
		plateau:SetAttribute("Angle", math.deg(e.angle))
		plateau:SetAttribute("Ecart", e.ecart)
		contourAiguille.Color = couleurEcart(e.ecart)
		local seg = machine.segments[e.segment]
		marqueAngle.Visible = e.virage ~= nil
		if e.virage then
			local mx, my = versTissu(seg.b)
			marqueAngle.Position = UDim2.fromOffset(mx, my)
		end
		local texte = nil
		-- (relecture) la machine ne tourne le pointillé qu'à l'angle : on coud jusqu'au rond, puis on s'arrête et on pivote
		if e.virage and e.virage.distance < SIGNAL_ANGLE then
			texte = "Un angle arrive : couds jusqu'au rond, puis pivote"
		elseif math.abs(e.angle) > PENCHE then
			texte = "Arrête-toi et pivote : remets le pointillé droit"
		end
		signal.Visible = texte ~= nil and not machine:fini()
		signal.Text = texte or ""
	end

	rafraichir = function()
		local etat = session.etat
		for _, id in ipairs(ids) do
			local nom = Catalogue.piece(id).nom
			local n = etat.coutures[id]
			local ligne = lignes[id]
			if n then
				ligne.Text = ("%s — %d %%"):format(nom, math.floor(n * 100 + 0.5))
				ligne.TextColor3 = C.ok
			else
				ligne.Text = nom .. (machine and machine.idPiece == id and " — en cours" or " — à coudre")
				ligne.TextColor3 = machine and machine.idPiece == id and C.texte or C.texteDoux
			end
		end
		local provisoire = machine and machine:noteProvisoire()
		local finie = machine ~= nil and machine:fini()
		remplissage.Size = UDim2.fromScale(provisoire or 0, 1)
		remplissage.BackgroundColor3 = if (provisoire or 1) >= 0.9 then C.ok elseif provisoire >= 0.6 then C.alerte else C.erreur
		if finie then
			note.Text = ("Pièce finie : %d %%"):format(math.floor(provisoire * 100 + 0.5))
		else
			note.Text = provisoire and ("Couture : %d %%"):format(math.floor(provisoire * 100 + 0.5)) or "Couture : —"
		end
		boutonSuivante.Visible = finie
		boutonSuivante.Text = #session.etat:piecesACoudre() <= 1 and "Finir la couture" or "Pièce suivante"
		consigne.Visible = not finie
		for nom, b in pairs(boutonsVitesse) do
			b.BackgroundColor3 = nom == vitesse and C.accent or C.secondaire
			b.TextColor3 = nom == vitesse and Color3.new(1, 1, 1) or C.texte
		end
		boutonAssistance.Text = assistance and "Assistance : tient la ligne (85 % au plus)" or "Assistance : non"
		if machine then
			dessiner()
		end
	end

	-- On rend le relevé de la pièce finie ; la suivante arrive par l'avis de changement. Refusé, la dernière
	-- couture est à refaire ; refus passager (serveur occupé ou injoignable) : la pièce reste finie, on la
	-- rendra de nouveau.
	rendre = function()
		local r = session:rendreCouture(machine.idPiece, machine:releve())
		if not r.ok then
			ctx.refus(r)
			if not r.passager then
				machine:decoudre()
				effacerPoints()
				rafraichir()
			end
		end
	end

	-- Maintenir « Coudre » (souris ou doigt), ou Espace ; pivoter : A / D, ← / →, ◀ ▶ tenus, ou glisser en tenant « Coudre »
	-- (vers la gauche comme ◀, vers la droite comme ▶)
	local function rotation()
		local r = 0
		for _, sens in pairs(pivots) do
			r += sens
		end
		if tenu and tenu.entree ~= "espace" then
			local echelle = plateau.AbsoluteSize.X / LARGEUR_PLATEAU
			local dx = tenu.x - tenu.x0
			dx = math.sign(dx) * math.max(0, math.abs(dx) - ZONE_MORTE * echelle)
			r -= math.clamp(dx / math.max(COURSE * echelle, 1), -1, 1)
		end
		return math.clamp(r, -1, 1)
	end
	for k, b in ipairs(boutonsPivot) do
		local sens = if k == 1 then 1 else -1
		table.insert(connexions, b.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.Touch then
				pivots[input] = sens
			elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
				pivots.souris = sens
			end
		end))
	end
	table.insert(connexions, boutonCoudre.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			tenu = { entree = input.UserInputType, objet = input, x0 = input.Position.X, x = input.Position.X }
		end
	end))
	-- Espace : lié seulement quand la fenêtre est visible ; l'action est absorbée (pas de saut), et la
	-- saisie dans le chat ne la déclenche pas. Fenêtre fermée : l'appui en cours est oublié.
	local function lierEspace(actif)
		if not actif then
			ContextActionService:UnbindAction(ACTION_ESPACE)
			ContextActionService:UnbindAction(ACTION_PIVOT)
			table.clear(pivots)
			return
		end
		ContextActionService:BindActionAtPriority(ACTION_ESPACE, function(_, etatEntree)
			if etatEntree == Enum.UserInputState.Begin then
				if not tenu then
					local souris = UserInputService:GetMouseLocation()
					tenu = { entree = "espace", x0 = souris.X, x = souris.X }
				end
			elseif tenu and tenu.entree == "espace" then
				tenu = nil -- relâchée ou annulée
			end
			return Enum.ContextActionResult.Sink
		end, false, Enum.ContextActionPriority.High.Value, Enum.KeyCode.Space)
		-- A / D, ← / → pivotent tant qu'on les tient ; W / S changent de vitesse (absorbées : l'avatar ne bouge pas)
		ContextActionService:BindActionAtPriority(ACTION_PIVOT, function(_, etatEntree, objet)
			local sens = TOUCHES_PIVOT[objet.KeyCode]
			if sens then
				pivots[objet.KeyCode] = if etatEntree == Enum.UserInputState.Begin then sens else nil
			elseif etatEntree == Enum.UserInputState.Begin and TOUCHES_VITESSE[objet.KeyCode] then
				local rang = 1
				for k, v in ipairs(VITESSES) do
					rang = if v[1] == vitesse then k else rang
				end
				vitesse = VITESSES[math.clamp(rang + TOUCHES_VITESSE[objet.KeyCode], 1, #VITESSES)][1]
				if machine then
					machine:choisirVitesse(vitesse)
				end
				rafraichir()
			end
			return Enum.ContextActionResult.Sink
		end, false, Enum.ContextActionPriority.High.Value, Enum.KeyCode.A, Enum.KeyCode.D, Enum.KeyCode.Left, Enum.KeyCode.Right, Enum.KeyCode.W, Enum.KeyCode.S, Enum.KeyCode.Up, Enum.KeyCode.Down)
	end
	local function surVisibilite()
		if not ctx.fenetre.Visible then
			tenu = nil
		end
		lierEspace(ctx.fenetre.Visible)
	end
	table.insert(connexions, ctx.fenetre:GetPropertyChangedSignal("Visible"):Connect(surVisibilite))
	surVisibilite()
	-- Au doigt, seul le doigt qui tient « Coudre » dirige l'aiguille ; à la souris, ses mouvements
	table.insert(connexions, UserInputService.InputChanged:Connect(function(input)
		if not tenu then
			return
		end
		local suit = if tenu.entree == Enum.UserInputType.Touch
			then input == tenu.objet
			else input.UserInputType == Enum.UserInputType.MouseMovement
		if suit then
			tenu.x = input.Position.X
		end
	end))
	table.insert(connexions, UserInputService.InputEnded:Connect(function(input)
		if not tenu then
			return
		end
		local fin
		if tenu.entree == "espace" then
			fin = false -- Espace est suivi par l'action liée
		elseif tenu.entree == Enum.UserInputType.Touch then
			fin = input == tenu.objet
		else
			fin = input.UserInputType == Enum.UserInputType.MouseButton1
		end
		if fin then
			tenu = nil
		end
	end))
	-- (un bouton ◀ ▶ relâché, où que ce soit)
	table.insert(connexions, UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			pivots.souris = nil
		else
			pivots[input] = nil
		end
	end))
	-- (plan 26) Le conseil en cours ; les conseils finis, la bulle disparaît (et ne revient qu'avec « ? » pendant cette
	-- partie : rien n'est sauvegardé)
	montrerConseil = function()
		local texte = guide and guide:texte()
		bulle.Visible = texte ~= nil
		bulle.Text = texte or ""
		if guide and not texte then
			guide = nil
			session.conseilsCoutureVus = true
		end
	end
	if session.etat.livraisons + session.etat.ventes == 0 and not session.conseilsCoutureVus then
		guide = GuideCouture.nouveau() -- la première robe : les conseils pas à pas
	end
	montrerConseil()
	-- Le son de la machine suit l'aiguille : il tourne tant qu'on coud, au rythme de la vitesse choisie
	local rythme = nil
	local function sonMachine(cousant)
		local r = cousant and RYTHMES[vitesse] or nil
		if r ~= rythme then
			rythme = r
			Sons.boucle("couture", r ~= nil, r)
		end
	end
	table.insert(connexions, RunService.RenderStepped:Connect(function(dt)
		parfait.Visible = os.clock() < finParfait
		local actif = machine ~= nil and not machine:fini() and ctx.fenetre.Visible
		local cousant = actif and tenu ~= nil
		sonMachine(cousant)
		local r = if actif then rotation() else 0
		if guide and machine then
			guide:suivre(dt, machine, cousant, r)
			montrerConseil()
		end
		if not cousant and r == 0 then
			return
		end
		local avant = machine.k
		machine:avancer(dt, cousant, r) -- (sans coudre : le tissu pivote, l'aiguille plantée)
		if machine.k > avant and machine:coutureParfaite(avant) then
			finParfait = os.clock() + DUREE_PARFAIT -- une couture sans faute
		end
		ajouterPoints()
		if machine:fini() then
			tenu = nil
		end
		rafraichir()
	end))

	local desabonner = session:surChangement(function(etat)
		if etat.etape == "couture" and etat.coutures[machine.idPiece] ~= nil then
			commencerPiece(etat:piecesACoudre()[1])
		end
		rafraichir()
	end)
	commencerPiece(session.etat:piecesACoudre()[1])
	rafraichir()
	return function()
		desabonner()
		lierEspace(false)
		table.clear(pivots)
		sonMachine(false)
		for _, c in ipairs(connexions) do
			c:Disconnect()
		end
	end
end
