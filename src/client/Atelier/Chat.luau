-- Chat (sous-projet 5) : le chat roux de chaque boutique, qu'on caresse (invite « Caresser », touche F) : il
-- ronronne, remue la queue et de petits cœurs montent au-dessus de sa tête. Pour le plaisir seulement : rien ne
-- part au serveur, seul le joueur qui le caresse le voit et l'entend.
local RunService = game:GetService("RunService")

local Chat = {}
Chat.DUREE = 2.5 -- secondes de ronron
Chat.COEURS = 5
local ROSE = Color3.fromRGB(236, 92, 146)

-- Les invites « Caresser » de tous les chats de la rue ; sons : le module Sons
function Chat.brancher(ProximityPromptService, Sons)
	return ProximityPromptService.PromptTriggered:Connect(function(invite)
		if invite.Name == "Caresser" and invite.Parent and invite.Parent.Parent then
			Chat.caresser(invite.Parent.Parent, Sons)
		end
	end)
end

-- Une caresse (une à la fois par chat)
function Chat.caresser(chat, Sons)
	local tete, queue = chat:FindFirstChild("Tete"), chat:FindFirstChild("Queue")
	if not tete or chat:GetAttribute("Caresse") then
		return
	end
	chat:SetAttribute("Caresse", true)
	Sons.jouer("ronron")
	-- Les cœurs, au-dessus de la tête, montent en s'effaçant
	local coeurs = Instance.new("BillboardGui")
	coeurs.Name = "Coeurs"
	coeurs.Size = UDim2.fromOffset(90, 110)
	coeurs.StudsOffset = Vector3.new(0, 1.6, 0)
	coeurs.LightInfluence = 0
	coeurs.Parent = tete
	local rng = Random.new()
	local morceaux = {}
	for k = 1, Chat.COEURS do
		local c = Instance.new("TextLabel")
		c.Name = "Coeur" .. k
		c.BackgroundTransparency = 1
		c.Text = "♥"
		c.Font = Enum.Font.GothamBold
		c.TextTransparency = 1 -- (invisible jusqu'à ce qu'il monte)
		c.TextColor3 = ROSE
		c.TextSize = rng:NextInteger(18, 28)
		c.Size = UDim2.fromOffset(30, 30)
		c.AnchorPoint = Vector2.new(0.5, 0.5)
		c.Parent = coeurs
		morceaux[k] = { objet = c, x = rng:NextNumber(0.15, 0.85), depart = (k - 1) / Chat.COEURS }
	end
	-- La queue remue autour de sa base
	local repos = queue and queue.CFrame
	local base = queue and repos * CFrame.new(-queue.Size.X / 2, 0, 0)
	local ecoule, connexion = 0, nil
	connexion = RunService.RenderStepped:Connect(function(dt)
		ecoule += dt
		if ecoule >= Chat.DUREE or not chat.Parent then
			connexion:Disconnect()
			coeurs:Destroy()
			if queue then
				queue.CFrame = repos
			end
			chat:SetAttribute("Caresse", nil)
			return
		end
		if queue then
			queue.CFrame = base * CFrame.Angles(0, math.sin(ecoule * 9) * 0.45, 0) * CFrame.new(queue.Size.X / 2, 0, 0)
		end
		for _, m in ipairs(morceaux) do
			local t = math.clamp((ecoule / Chat.DUREE) * 1.6 - m.depart, 0, 1)
			m.objet.Position = UDim2.fromScale(m.x, 1 - t)
			m.objet.TextTransparency = if t <= 0 then 1 else t * 0.9
		end
	end)
end

return Chat
