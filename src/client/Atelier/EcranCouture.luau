-- Écran de couture : la pièce passe sous l'aiguille, une couture après l'autre. On maintient « Coudre »
-- (ou Espace) et on glisse à gauche ou à droite pour garder l'aiguille sur le pointillé.
-- Vitesse tortue ↔ lapin, découd-vite, assistance (note plafonnée). La logique est dans MachineCoudre.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")
local Couture = ReplicatedStorage:WaitForChild("Couture")
local Catalogue = require(Couture:WaitForChild("Catalogue"))
local Polygone = require(Couture:WaitForChild("Polygone"))
local MachineCoudre = require(script.Parent:WaitForChild("MachineCoudre"))
local Vignettes = require(script.Parent:WaitForChild("Vignettes"))

local PX = 80 -- pixels par dm sous l'aiguille : 0,05 dm de tolérance = 4 px
local LARGEUR_PLATEAU = 480
local COURSE = 100 -- px de glisser pour corriger à fond (à l'échelle 1)
local BOIS = Color3.fromRGB(205, 170, 125)
local FIL = Color3.fromRGB(60, 40, 50)
local VITESSES = { { "tortue", "Tortue" }, { "normale", "Normale" }, { "lapin", "Lapin" } }
local ACTION_ESPACE = "AtelierCoudre" -- Espace coud (au lieu de sauter) tant que la machine est affichée

return function(ctx)
	local UiKit, session, contenu = ctx.UiKit, ctx.session, ctx.contenu
	local C = UiKit.COULEURS
	local connexions = {}
	local machine, boite
	local vitesse, assistance = "normale", false
	local tenu = nil -- appui en cours : { entree, objet, x0, x }
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
	UiKit.creer("UIStroke", { Color = C.erreur, Thickness = 2, Parent = aiguille })

	-- Panneau de commandes
	local panneau = UiKit.creer("Frame", { Name = "Panneau", BackgroundTransparency = 1, Position = UDim2.fromOffset(LARGEUR_PLATEAU + 16, 0), Size = UDim2.new(1, -(LARGEUR_PLATEAU + 16), 1, 0), Parent = contenu })
	local listePieces = UiKit.creer("Frame", { Name = "Pieces", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 144), Parent = panneau })
	local ids = session.etat:piecesDuCroquis()
	local lignes = {}
	for i, id in ipairs(ids) do
		lignes[id] = UiKit.texte({ Name = "Ligne" .. i, TextSize = 14, Position = UDim2.fromOffset(0, (i - 1) * 24), Size = UDim2.new(1, 0, 0, 22), Parent = listePieces })
	end
	local note = UiKit.texte({ Name = "Note", Font = Enum.Font.GothamBold, TextSize = 18, Position = UDim2.fromOffset(0, 150), Size = UDim2.new(1, 0, 0, 24), Parent = panneau })
	local consigne = UiKit.texte({
		Text = "Maintiens « Coudre » (ou Espace) et glisse à gauche ou à droite : l'aiguille doit rester sur le pointillé.",
		TextSize = 14,
		TextColor3 = C.texteDoux,
		Position = UDim2.fromOffset(0, 178),
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
			effacerPoints()
			rafraichir()
		end
	end)
	local boutonCoudre = UiKit.bouton({ Name = "Coudre", Text = "Coudre (maintenir)", TextSize = 18, Position = UDim2.fromOffset(0, 362), Size = UDim2.new(1, -6, 0, 58), Parent = panneau })
	UiKit.boutonConfirme({ Name = "Recommencer", Text = "Recommencer la robe", TextSize = 14, AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), Size = UDim2.fromOffset(200, 34), Parent = panneau }, function()
		local r = session:recommencer()
		if not r.ok then
			ctx.message(r.erreur, C.erreur)
		end
	end)

	-- Repère du tissu (px) d'un point du patron (dm)
	local function versTissu(p)
		return (p.x - boite.minX) * PX, (p.y - boite.minY) * PX
	end

	-- Une pièce passe sous l'aiguille : image du vrai tissu, pointillé des coutures
	local function commencerPiece(id)
		machine = MachineCoudre.nouvelle(id, session.rng:NextInteger(1, 1000000))
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

	local function ajouterPoints()
		local e = machine:etat()
		local x, y = versTissu(e.point)
		for i = #points + 1, #machine.ecarts do
			points[i] = UiKit.creer("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = C.accent, BorderSizePixel = 0, Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(4, 4), Parent = calquePoints })
		end
	end

	-- Le tissu tourne pour que la couture en cours monte vers l'aiguille, et se place sous elle
	local function dessiner()
		local e = machine:etat()
		local phi = -math.pi / 2 - math.atan2(e.direction.y, e.direction.x)
		local vx = (e.point.x - (boite.minX + boite.maxX) / 2) * PX
		local vy = (e.point.y - (boite.minY + boite.maxY) / 2) * PX
		local c, s = math.cos(phi), math.sin(phi)
		tissu.Rotation = math.deg(phi)
		tissu.Position = UDim2.new(0.5, -(vx * c - vy * s), 0.5, -(vx * s + vy * c))
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
		boutonAssistance.Text = assistance and "Assistance : oui (85 % au plus)" or "Assistance : non"
		if machine then
			dessiner()
		end
	end

	-- On rend le relevé de la pièce finie ; la suivante arrive par l'avis de changement
	rendre = function()
		local r = session:rendreCouture(machine.idPiece, machine:releve())
		if not r.ok then
			ctx.message(r.erreur, C.erreur)
			machine:decoudre()
			effacerPoints()
			rafraichir()
		end
	end

	-- Maintenir « Coudre » (souris ou doigt), ou Espace ; glisser corrige la direction
	local function direction()
		local course = COURSE * plateau.AbsoluteSize.X / LARGEUR_PLATEAU
		-- Glisser vers la droite pousse le tissu à droite : l'écart diminue
		return -math.clamp((tenu.x - tenu.x0) / math.max(course, 1), -1, 1)
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
	table.insert(connexions, RunService.RenderStepped:Connect(function(dt)
		if not machine or machine:fini() or not tenu or not ctx.fenetre.Visible then
			return
		end
		machine:avancer(dt, direction())
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
		for _, c in ipairs(connexions) do
			c:Disconnect()
		end
	end
end
