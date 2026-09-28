-- Rendu3D : construit le vêtement en 3D (pièces soudées au corps) sur le mannequin
-- ou sur un avatar R15 / R6. Utilisé par le serveur (mannequin de l'atelier, avatar)
-- et par le client (aperçu dans l'interface).
local CoutureData = require(script.Parent:WaitForChild("CoutureData"))

local Rendu3D = {}

Rendu3D.NOM_VETEMENT = "VetementAtelier"

local BLANC_NACRE = Color3.fromRGB(248, 244, 236)
local JAUNE_COEUR = Color3.fromRGB(255, 214, 90)
local COULEURS_FLEURS = {
	Color3.fromRGB(255, 140, 180),
	Color3.fromRGB(140, 190, 255),
	Color3.fromRGB(255, 255, 255),
	Color3.fromRGB(190, 140, 230),
	Color3.fromRGB(255, 170, 90),
}

local function partie(modele, nom)
	local p = modele:FindFirstChild(nom)
	if p and p:IsA("BasePart") then
		return p
	end
	return nil
end

-- Points d'accroche du vêtement. « taille » est le repère de la taille (ceinture),
-- l'avant du corps est vers -Z comme pour les avatars Roblox.
local function accroches(modele)
	local haut, bas = partie(modele, "UpperTorso"), partie(modele, "LowerTorso")
	if haut and bas then
		-- Avatar R15
		local cuisse, tibia, pied = partie(modele, "LeftUpperLeg"), partie(modele, "LeftLowerLeg"), partie(modele, "LeftFoot")
		local jambes = (cuisse and cuisse.Size.Y or 1.2) + (tibia and tibia.Size.Y or 1.2) + (pied and pied.Size.Y or 0.3)
		return {
			torse = haut,
			bassin = bas,
			separes = true,
			taille = bas.CFrame * CFrame.new(0, bas.Size.Y / 2, 0),
			rx = bas.Size.X / 2,
			rz = bas.Size.Z / 2,
			hanches = bas.Size.Y,
			jambes = jambes,
			bras = { partie(modele, "LeftUpperArm"), partie(modele, "RightUpperArm") },
		}
	end

	local torse = partie(modele, "Torso")
	if torse then
		-- Avatar R6 ou mannequin de l'atelier
		local jambe = partie(modele, "Left Leg")
		local hanches = torse.Size.Y * 0.3
		return {
			torse = torse,
			bassin = torse,
			separes = false,
			taille = torse.CFrame * CFrame.new(0, -torse.Size.Y / 2 + hanches, 0),
			rx = torse.Size.X / 2,
			rz = torse.Size.Z / 2,
			hanches = hanches,
			jambes = jambe and jambe.Size.Y or modele:GetAttribute("LongueurJambes") or 2,
			bras = { partie(modele, "Left Arm"), partie(modele, "Right Arm") },
		}
	end
	return nil
end

-- Crée une pièce de tissu soudée à « accroche ». Le CFrame est aussi posé directement
-- pour que le rendu soit juste dans un ViewportFrame, où la physique ne tourne pas.
local function nouvellePiece(conteneur, accroche, cfMonde, taille, apparence, forme)
	local piece = Instance.new("Part")
	piece.Name = "Piece"
	if forme then
		piece.Shape = forme
	end
	piece.Size = taille
	piece.CFrame = cfMonde
	piece.Anchored = false
	piece.CanCollide = false
	piece.CanQuery = false
	piece.CanTouch = false
	piece.Massless = true
	piece.TopSurface = Enum.SurfaceType.Smooth
	piece.BottomSurface = Enum.SurfaceType.Smooth
	piece.Color = apparence.couleur
	piece.Material = apparence.materiau
	piece.Reflectance = apparence.reflet or 0
	piece.Transparency = apparence.transparence or 0
	piece.Parent = conteneur

	local soudure = Instance.new("Weld")
	soudure.Part0 = accroche
	soudure.Part1 = piece
	soudure.C0 = accroche.CFrame:ToObjectSpace(cfMonde)
	soudure.Parent = piece
	return piece
end

local function apparenceUnie(couleur, materiau, reflet, transparence)
	return { couleur = couleur, materiau = materiau or Enum.Material.SmoothPlastic, reflet = reflet, transparence = transparence }
end

local function pointEllipse(forme, angle, t)
	local y = forme.yHaut + (forme.yBas - forme.yHaut) * t
	local rx = forme.rxHaut + (forme.rxBas - forme.rxHaut) * t
	local rz = forme.rzHaut + (forme.rzBas - forme.rzHaut) * t
	return Vector3.new(rx * math.cos(angle), y, rz * math.sin(angle)), rx, rz
end

local function normaleEllipse(angle, rx, rz)
	return Vector3.new(math.cos(angle) / rx, 0, math.sin(angle) / rz).Unit
end

-- Point à la surface d'une jupe (angle -pi/2 = devant, t = 0 à la taille, 1 à l'ourlet)
local function pointSurface(forme, angle, t, decollement)
	local point, rx, rz = pointEllipse(forme, angle, t)
	return point + normaleEllipse(angle, rx, rz) * (decollement or 0.07)
end

-- Anneau de panneaux autour de la taille : jupe, ceinture, dentelle…
-- Les coordonnées de « forme » sont relatives au repère de la taille.
local function anneau(ctx, conteneur, forme, apparence, options)
	local n = options.panneaux
	local rng = options.rng
	local defaut = options.defaut or 0
	local pas = math.pi * 2 / n
	for i = 1, n do
		local angle = (i - 1) * pas + rng:NextNumber(-1, 1) * defaut * 0.25
		local allongement = 1 + rng:NextNumber(-1, 1) * defaut * 0.2
		local haut = pointEllipse(forme, angle, 0)
		local bas, rxBas, rzBas = pointEllipse(forme, angle, allongement)
		local axe = haut - bas
		local dessus = axe.Unit
		local dehors = normaleEllipse(angle, rxBas, rzBas)
		dehors = (dehors - dessus * dehors:Dot(dessus)).Unit
		local droite = dessus:Cross(dehors)

		-- Largeur : la corde entre les panneaux voisins, avec un recouvrement
		local corde = (pointEllipse(forme, angle + pas / 2, 1) - pointEllipse(forme, angle - pas / 2, 1)).Magnitude
		local cordeHaut = (pointEllipse(forme, angle + pas / 2, 0) - pointEllipse(forme, angle - pas / 2, 0)).Magnitude
		local largeur = math.max(corde, cordeHaut) * 1.2

		local ap = apparence
		if options.nuance and i % 2 == 0 then
			ap = options.nuance
		end
		local cfLocal = CFrame.fromMatrix((haut + bas) / 2, droite, dessus, dehors)
		nouvellePiece(
			conteneur,
			ctx.bassin,
			ctx.taille * cfLocal,
			Vector3.new(largeur, axe.Magnitude, options.epaisseur or 0.06),
			ap
		)
	end
end

-- Coque autour d'une partie du corps (corsage, haut). cfLocal est relatif à la partie.
local function coque(conteneur, accroche, cfLocal, taille, apparence, rng, defaut)
	local travers = CFrame.Angles(rng:NextNumber(-1, 1) * defaut * 0.12, 0, rng:NextNumber(-1, 1) * defaut * 0.12)
	return nouvellePiece(conteneur, accroche, accroche.CFrame * cfLocal * travers, taille, apparence)
end

local function fleur(conteneur, accroche, cfMonde, rng)
	nouvellePiece(
		conteneur,
		accroche,
		cfMonde,
		Vector3.new(0.2, 0.2, 0.2),
		apparenceUnie(COULEURS_FLEURS[rng:NextInteger(1, #COULEURS_FLEURS)]),
		Enum.PartType.Ball
	)
	nouvellePiece(
		conteneur,
		accroche,
		cfMonde * CFrame.new(0, 0, -0.07),
		Vector3.new(0.09, 0.09, 0.09),
		apparenceUnie(JAUNE_COEUR),
		Enum.PartType.Ball
	)
end

function Rendu3D.deshabiller(modele)
	local ancien = modele:FindFirstChild(Rendu3D.NOM_VETEMENT)
	if ancien then
		ancien:Destroy()
	end
end

-- spec = { vetement, tissu, decorations = { ids }, decoupe, couture, pivotees, graine }
function Rendu3D.habiller(modele, spec)
	Rendu3D.deshabiller(modele)
	if type(spec) ~= "table" then
		return nil
	end
	local vetement = CoutureData.getVetement(spec.vetement)
	local tissu = CoutureData.getTissu(spec.tissu)
	local ctx = accroches(modele)
	if not vetement or not tissu or not ctx then
		return nil
	end

	local rng = Random.new(tonumber(spec.graine) or 1)
	local defaut = CoutureData.defautVetement(tonumber(spec.decoupe) or 1, tonumber(spec.couture) or 1)
	local decos = {}
	for _, id in ipairs(type(spec.decorations) == "table" and spec.decorations or {}) do
		decos[id] = true
	end

	local conteneur = Instance.new("Model")
	conteneur.Name = Rendu3D.NOM_VETEMENT
	conteneur.Parent = modele

	local materiau = tissu.brillant and Enum.Material.SmoothPlastic or Enum.Material.Fabric
	local reflet = tissu.brillant and 0.12 or 0
	local apTissu = apparenceUnie(tissu.couleur, materiau, reflet)
	-- Une pièce coupée hors du droit-fil tombe mal : la couleur paraît irrégulière
	local nuance = (tonumber(spec.pivotees) or 0) > 0
			and apparenceUnie(tissu.couleur:Lerp(Color3.new(0, 0, 0), 0.2), materiau, reflet)
		or nil
	local couleurRuban = (tissu.couleur.R + tissu.couleur.G + tissu.couleur.B) / 3 > 0.6
			and Color3.fromRGB(196, 58, 110)
		or BLANC_NACRE

	local torse = ctx.torse
	local margeCoque = Vector3.new(0.14, 0.06, 0.14)
	local jupe -- forme de la jupe, si le vêtement en a une
	local ourlet -- hauteur de l'ourlet (sous la taille) pour un haut

	if vetement.id == "haut" then
		if ctx.separes then
			coque(conteneur, torse, CFrame.new(), torse.Size + margeCoque, apTissu, rng, defaut)
			coque(conteneur, ctx.bassin, CFrame.new(), ctx.bassin.Size + Vector3.new(0.16, 0.02, 0.16), nuance or apTissu, rng, defaut)
		else
			coque(conteneur, torse, CFrame.new(), torse.Size + margeCoque, apTissu, rng, defaut)
		end
		ourlet = -ctx.hanches
		-- Manches courtes
		for _, bras in ipairs(ctx.bras) do
			if bras then
				local longueur = bras.Size.Y * 0.45 * (1 + rng:NextNumber(-1, 1) * defaut * 0.4)
				coque(
					conteneur,
					bras,
					CFrame.new(0, bras.Size.Y / 2 - longueur / 2 + 0.03, 0),
					Vector3.new(bras.Size.X + 0.1, longueur, bras.Size.Z + 0.1),
					nuance or apTissu,
					rng,
					defaut
				)
			end
		end
	else
		if vetement.id == "robe" then
			-- Corsage : du haut du buste jusqu'à la taille
			if ctx.separes then
				coque(conteneur, torse, CFrame.new(), torse.Size + margeCoque, apTissu, rng, defaut)
			else
				local hauteur = torse.Size.Y - ctx.hanches
				coque(
					conteneur,
					torse,
					CFrame.new(0, ctx.hanches / 2, 0),
					Vector3.new(torse.Size.X, hauteur, torse.Size.Z) + margeCoque,
					apTissu,
					rng,
					defaut
				)
			end
		end

		local longueur = ctx.hanches + ctx.jambes * (vetement.id == "robe" and 0.65 or 0.42)
		local rxHaut, rzHaut = ctx.rx + 0.1, ctx.rz + 0.12
		jupe = {
			yHaut = 0.05,
			yBas = -longueur,
			rxHaut = rxHaut,
			rzHaut = rzHaut,
			rxBas = rxHaut + longueur * 0.3,
			rzBas = rzHaut + longueur * 0.45,
		}
		anneau(ctx, conteneur, jupe, apTissu, { panneaux = 18, rng = rng, defaut = defaut, nuance = nuance })

		-- Ceinture en tissu (remplacée par le ruban s'il est choisi)
		if not decos.ruban then
			anneau(ctx, conteneur, {
				yHaut = 0.14,
				yBas = -0.1,
				rxHaut = rxHaut + 0.05,
				rzHaut = rzHaut + 0.05,
				rxBas = rxHaut + 0.05,
				rzBas = rzHaut + 0.05,
			}, apparenceUnie(tissu.couleur:Lerp(Color3.new(0, 0, 0), 0.1), materiau, reflet), {
				panneaux = 14,
				rng = rng,
				epaisseur = 0.08,
			})
		end
	end

	-- Dentelle : à l'ourlet de la jupe, ou en bas du haut
	if decos.dentelle then
		local apDentelle = apparenceUnie(BLANC_NACRE, Enum.Material.Fabric, 0, 0.15)
		local forme
		if jupe then
			local yBas = jupe.yBas * (1 + defaut * 0.1)
			forme = {
				yHaut = yBas + 0.12,
				yBas = yBas - 0.25,
				rxHaut = jupe.rxBas + 0.03,
				rzHaut = jupe.rzBas + 0.03,
				rxBas = jupe.rxBas + 0.12,
				rzBas = jupe.rzBas + 0.14,
			}
		else
			forme = {
				yHaut = ourlet + 0.12,
				yBas = ourlet - 0.2,
				rxHaut = ctx.rx + 0.12,
				rzHaut = ctx.rz + 0.12,
				rxBas = ctx.rx + 0.2,
				rzBas = ctx.rz + 0.2,
			}
		end
		anneau(ctx, conteneur, forme, apDentelle, { panneaux = 18, rng = rng, epaisseur = 0.04 })
	end

	-- Ruban de satin noué devant la taille
	if decos.ruban then
		local rxR, rzR = ctx.rx + 0.17, ctx.rz + 0.19
		local apRuban = apparenceUnie(couleurRuban, Enum.Material.SmoothPlastic, 0.15)
		anneau(ctx, conteneur, {
			yHaut = 0.12,
			yBas = -0.1,
			rxHaut = rxR,
			rzHaut = rzR,
			rxBas = rxR,
			rzBas = rzR,
		}, apRuban, { panneaux = 14, rng = rng, epaisseur = 0.08 })
		local noeud = ctx.taille * CFrame.new(0, 0.01, -(rzR + 0.08))
		nouvellePiece(conteneur, ctx.bassin, noeud * CFrame.new(-0.2, 0, 0) * CFrame.Angles(0, 0, 0.4), Vector3.new(0.38, 0.24, 0.06), apRuban)
		nouvellePiece(conteneur, ctx.bassin, noeud * CFrame.new(0.2, 0, 0) * CFrame.Angles(0, 0, -0.4), Vector3.new(0.38, 0.24, 0.06), apRuban)
		nouvellePiece(conteneur, ctx.bassin, noeud * CFrame.new(0, 0, -0.03), Vector3.new(0.14, 0.14, 0.14), apRuban, Enum.PartType.Ball)
	end

	-- Boutons nacrés : sur le devant du buste, ou le long du devant de la jupe
	if decos.boutons then
		local apBouton = apparenceUnie(BLANC_NACRE, Enum.Material.SmoothPlastic, 0.3)
		for i = 1, 3 do
			if vetement.id == "jupe" then
				local point = pointSurface(jupe, -math.pi / 2, 0.12 + (i - 1) * 0.16)
				nouvellePiece(conteneur, ctx.bassin, ctx.taille * CFrame.new(point), Vector3.new(0.16, 0.16, 0.16), apBouton, Enum.PartType.Ball)
			else
				local y = torse.Size.Y * (0.28 - (i - 1) * 0.22)
				local cf = torse.CFrame * CFrame.new(0, y, -(torse.Size.Z / 2 + 0.09))
				nouvellePiece(conteneur, torse, cf, Vector3.new(0.16, 0.16, 0.16), apBouton, Enum.PartType.Ball)
			end
		end
	end

	-- Broderie florale : petites fleurs sur le devant
	if decos.broderie then
		for _ = 1, 6 do
			if jupe then
				local point = pointSurface(jupe, -math.pi / 2 + rng:NextNumber(-0.9, 0.9), rng:NextNumber(0.35, 0.85), 0.06)
				fleur(conteneur, ctx.bassin, ctx.taille * CFrame.new(point), rng)
			else
				local x = rng:NextNumber(-0.35, 0.35) * torse.Size.X
				local y = rng:NextNumber(-0.3, 0.3) * torse.Size.Y
				fleur(conteneur, torse, torse.CFrame * CFrame.new(x, y, -(torse.Size.Z / 2 + 0.1)), rng)
			end
		end
	end

	return conteneur
end

-- Mannequin de couturière (pièces ancrées, nommées comme un avatar R6)
function Rendu3D.creerMannequin(cfBase)
	local modele = Instance.new("Model")
	modele.Name = "Mannequin"
	modele:SetAttribute("LongueurJambes", 2.6)

	local creme = Color3.fromRGB(236, 222, 200)
	local bois = Color3.fromRGB(120, 84, 56)
	local vertical = CFrame.Angles(0, 0, math.pi / 2)

	local function bloc(nom, taille, cf, couleur, materiau, forme)
		local p = Instance.new("Part")
		p.Name = nom
		p.Anchored = true
		if forme then
			p.Shape = forme
		end
		p.Size = taille
		p.CFrame = cfBase * cf
		p.Color = couleur
		p.Material = materiau
		p.TopSurface = Enum.SurfaceType.Smooth
		p.BottomSurface = Enum.SurfaceType.Smooth
		p.Parent = modele
		return p
	end

	bloc("Socle", Vector3.new(0.3, 2.6, 2.6), CFrame.new(0, 0.15, 0) * vertical, bois, Enum.Material.Wood, Enum.PartType.Cylinder)
	bloc("Pied", Vector3.new(2.9, 0.3, 0.3), CFrame.new(0, 1.75, 0) * vertical, bois, Enum.Material.Wood, Enum.PartType.Cylinder)
	local torse = bloc("Torso", Vector3.new(2, 2, 1), CFrame.new(0, 4.2, 0), creme, Enum.Material.Fabric)
	bloc("Left Arm", Vector3.new(0.9, 1.3, 0.9), CFrame.new(-1.45, 4.55, 0), creme, Enum.Material.Fabric)
	bloc("Right Arm", Vector3.new(0.9, 1.3, 0.9), CFrame.new(1.45, 4.55, 0), creme, Enum.Material.Fabric)
	bloc("Cou", Vector3.new(0.6, 0.5, 0.5), CFrame.new(0, 5.45, 0) * vertical, creme, Enum.Material.Fabric, Enum.PartType.Cylinder)
	bloc("Tete", Vector3.new(1.1, 1.1, 1.1), CFrame.new(0, 6.2, 0), creme, Enum.Material.Fabric, Enum.PartType.Ball)
	modele.PrimaryPart = torse
	return modele
end

return Rendu3D
