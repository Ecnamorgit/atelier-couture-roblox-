-- Cliente : la cliente en personne (client). Un avatar Roblox construit en code, sans aucun modèle
-- externe : la tenue est faite des couleurs du corps (peau, haut, bas) et d'une coiffure simple, tirée
-- d'après la commande ; la silhouette suit sa taille (S, M, L). Elle parle par une bulle.
local Players = game:GetService("Players")

local Cliente = {}

local function rgb(r, g, b)
	return Color3.fromRGB(r, g, b)
end

Cliente.TENUES = {
	{ nom = "Rose poudré", peau = rgb(234, 192, 160), haut = rgb(236, 150, 180), bas = rgb(120, 90, 110), cheveux = rgb(90, 60, 40) },
	{ nom = "Marine", peau = rgb(160, 110, 80), haut = rgb(60, 80, 140), bas = rgb(230, 230, 235), cheveux = rgb(30, 25, 25) },
	{ nom = "Tournesol", peau = rgb(250, 214, 180), haut = rgb(245, 200, 70), bas = rgb(90, 120, 80), cheveux = rgb(200, 150, 70) },
	{ nom = "Prune", peau = rgb(110, 75, 55), haut = rgb(120, 60, 110), bas = rgb(40, 35, 45), cheveux = rgb(20, 15, 15) },
	{ nom = "Menthe", peau = rgb(240, 200, 170), haut = rgb(150, 210, 180), bas = rgb(240, 235, 220), cheveux = rgb(160, 50, 40) },
}
local LARGEURS = { S = 0.9, M = 1, L = 1.12 } -- silhouette selon la taille de la cliente
Cliente.ECHELLE = 0.85 -- un avatar Roblox (≈ 5,2 studs) est plus grand que le mannequin (≈ 4,3 studs)
local EPAULES = 62 -- degrés : bras baissés, mains jointes devant (un avatar sans animation reste bras écartés)

-- Tenue tirée d'après la commande : toujours la même pour une commande donnée
function Cliente.choisir(commande)
	local texte = tostring(commande.taille)
	for _, e in ipairs(commande.exigences or {}) do
		texte ..= "|" .. tostring(e.type) .. tostring(e.style or e.teinte or e.id or "") .. tostring(e.valeur or "")
	end
	local h = 0
	for i = 1, #texte do
		h = (h * 31 + string.byte(texte, i)) % 1000003
	end
	return h % #Cliente.TENUES + 1
end

function Cliente.description(commande)
	local t = Cliente.TENUES[Cliente.choisir(commande)]
	local d = Instance.new("HumanoidDescription")
	d.HeadColor, d.LeftArmColor, d.RightArmColor = t.peau, t.peau, t.peau
	d.TorsoColor = t.haut
	d.LeftLegColor, d.RightLegColor = t.bas, t.bas
	d.WidthScale = LARGEURS[commande.taille] or 1
	d.DepthScale = d.WidthScale
	return d
end

local avertie = false

-- Avatar immobile posé à « cadre » (pieds au sol), ou nil si Roblox ne peut pas le créer
function Cliente.construire(commande, cadre, parent)
	local ok, modele = pcall(function()
		return Players:CreateHumanoidModelFromDescriptionAsync(Cliente.description(commande), Enum.HumanoidRigType.R15)
	end)
	if not ok or not modele then
		if not avertie then
			avertie = true
			warn("[Atelier] Cliente non affichée : " .. tostring(modele))
		end
		return nil
	end
	modele.Name = "Cliente"
	local humanoide = modele:FindFirstChild("Humanoid")
	if humanoide then
		humanoide.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	end
	for nom, signe in pairs({ LeftShoulder = 1, RightShoulder = -1 }) do
		local epaule = modele:FindFirstChild(nom, true)
		if epaule and (epaule:IsA("AnimationConstraint") or epaule:IsA("Motor6D")) then
			epaule.Transform = CFrame.Angles(0, 0, math.rad(EPAULES * signe))
		end
	end
	local racine = modele:FindFirstChild("HumanoidRootPart")
	if racine then
		racine.Anchored = true
	end
	local tete = modele:FindFirstChild("Head")
	if tete then
		local cheveux = Instance.new("Part")
		cheveux.Name = "Cheveux"
		cheveux.Shape = Enum.PartType.Ball
		cheveux.Size = tete.Size * 1.3 -- la tête R15 dépasse sa taille déclarée
		cheveux.Color = Cliente.TENUES[Cliente.choisir(commande)].cheveux
		cheveux.Material = Enum.Material.SmoothPlastic
		cheveux.CanCollide = false
		cheveux.CanQuery = false
		cheveux.CanTouch = false
		cheveux.Massless = true
		cheveux.CFrame = tete.CFrame * CFrame.new(0, tete.Size.Y * 0.22, tete.Size.Z * 0.22) -- dégage le visage
		local soudure = Instance.new("WeldConstraint")
		soudure.Part0, soudure.Part1 = tete, cheveux
		soudure.Parent = cheveux
		cheveux.Parent = modele
	end
	modele:ScaleTo(Cliente.ECHELLE)
	-- Le pivot d'un avatar est sa racine (au niveau des hanches) : on le monte de la hauteur des jambes
	local bas = math.huge
	for _, d in ipairs(modele:GetDescendants()) do
		if d:IsA("BasePart") and d.Name ~= "Cheveux" then
			bas = math.min(bas, d.CFrame.Position.Y - d.Size.Y / 2)
		end
	end
	local hauteur = bas < math.huge and modele:GetPivot().Position.Y - bas or 0
	modele:PivotTo(cadre * CFrame.new(0, hauteur, 0))
	modele.Parent = parent
	return modele
end

-- Bulle de dialogue au-dessus de la tête (texte nil : la bulle disparaît)
function Cliente.dire(modele, texte)
	local tete = modele and modele:FindFirstChild("Head")
	if not tete then
		return
	end
	local ancienne = tete:FindFirstChild("Bulle")
	if ancienne then
		ancienne:Destroy()
	end
	if not texte then
		return
	end
	local bulle = Instance.new("BillboardGui")
	bulle.Name = "Bulle"
	bulle.Size = UDim2.fromOffset(240, 60)
	bulle.StudsOffset = Vector3.new(0, 2.2, 0)
	bulle.AlwaysOnTop = true
	local cadre = Instance.new("TextLabel")
	cadre.Name = "Texte"
	cadre.Size = UDim2.fromScale(1, 1)
	cadre.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	cadre.TextColor3 = Color3.fromRGB(58, 36, 48)
	cadre.Font = Enum.Font.GothamBold
	cadre.TextSize = 16
	cadre.TextWrapped = true
	cadre.Text = texte
	local coin = Instance.new("UICorner")
	coin.CornerRadius = UDim.new(0, 12)
	coin.Parent = cadre
	cadre.Parent = bulle
	bulle.Parent = tete
end

return Cliente
