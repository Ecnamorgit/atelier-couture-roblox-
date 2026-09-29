-- Serveur de l'atelier : il fait foi (spec §2). Une seule RemoteFunction « Atelier », une action par
-- étape (Commande). La sauvegarde arrive au plan 4b, les boutiques de la rue au plan 4c.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Commande = require(script:WaitForChild("Commande"))

local commande = Commande.nouvelle()

local remote = Instance.new("RemoteFunction")
remote.Name = "Atelier"
remote.OnServerInvoke = function(joueur, action, ...)
	return commande:traiter(joueur, action, ...)
end
remote.Parent = ReplicatedStorage

Players.PlayerRemoving:Connect(function(joueur)
	commande:retirer(joueur)
end)
