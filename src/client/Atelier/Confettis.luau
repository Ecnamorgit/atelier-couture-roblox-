-- Confettis (sous-projet 5) : la robe terminée (dernière pièce cousue), une pluie de confettis tombe sur l'écran,
-- puis disparaît. Des petits rectangles de couleur qui tournent en tombant, dans l'interface (pas des particules
-- dans la scène : ils se voient par-dessus la fenêtre de l'atelier, sur tous les appareils).
local RunService = game:GetService("RunService")

local Confettis = {}
Confettis.NOMBRE = 60
Confettis.DUREE = 2.5 -- secondes
Confettis.COULEURS = {
	Color3.fromRGB(236, 92, 146), -- rose
	Color3.fromRGB(246, 196, 72), -- or
	Color3.fromRGB(120, 204, 170), -- menthe
	Color3.fromRGB(118, 172, 236), -- ciel
	Color3.fromRGB(186, 146, 226), -- lilas
}

-- Lance une pluie de confettis dans parent (un ScreenGui) ; renvoie le cadre, détruit à la fin
function Confettis.lancer(parent, graine)
	local rng = Random.new(graine or math.floor(os.clock() * 1000))
	local cadre = Instance.new("Frame")
	cadre.Name = "Confettis"
	cadre.BackgroundTransparency = 1
	cadre.Size = UDim2.fromScale(1, 1)
	cadre.ZIndex = 50
	cadre.Parent = parent
	local morceaux = {}
	for k = 1, Confettis.NOMBRE do
		local m = Instance.new("Frame")
		m.Name = "Confetti" .. k
		m.BorderSizePixel = 0
		m.BackgroundColor3 = Confettis.COULEURS[rng:NextInteger(1, #Confettis.COULEURS)]
		m.AnchorPoint = Vector2.new(0.5, 0.5)
		m.Size = UDim2.fromOffset(rng:NextInteger(6, 10), rng:NextInteger(10, 16))
		m.Rotation = rng:NextNumber(0, 360)
		m.ZIndex = 51
		local c = { objet = m, x = rng:NextNumber(0.02, 0.98), y = -rng:NextNumber(0.02, 0.4), chute = rng:NextNumber(0.45, 0.75), derive = rng:NextNumber(-0.06, 0.06), tour = rng:NextNumber(-300, 300) }
		m.Position = UDim2.fromScale(c.x, c.y)
		m.Parent = cadre
		morceaux[k] = c
	end
	local ecoule, connexion = 0, nil
	connexion = RunService.RenderStepped:Connect(function(dt)
		ecoule += dt
		if ecoule >= Confettis.DUREE or not cadre.Parent then
			connexion:Disconnect()
			cadre:Destroy()
			return
		end
		for _, c in ipairs(morceaux) do
			c.y += c.chute * dt
			c.x += c.derive * dt
			c.objet.Position = UDim2.fromScale(c.x, c.y)
			c.objet.Rotation += c.tour * dt
		end
	end)
	return cadre
end

return Confettis
