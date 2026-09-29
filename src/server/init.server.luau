-- Serveur de l'atelier : il fait foi (spec §2). Une seule RemoteFunction « Atelier », une action par
-- étape (Commande). Les parties sont sauvegardées (Sauvegarde) : lues à l'arrivée du joueur, écrites
-- toutes les 60 s, à son départ et à l'arrêt du serveur. Les boutiques de la rue arrivent au plan 4c.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Commande = require(script:WaitForChild("Commande"))
local Sauvegarde = require(script:WaitForChild("Sauvegarde"))

-- Pas de sauvegarde sur un lieu non publié, ni si le DataStore est indisponible (avertissement)
local commande = Commande.nouvelle({ sauvegarde = Sauvegarde.pourLeJeu() })

local remote = Instance.new("RemoteFunction")
remote.Name = "Atelier"
remote.OnServerInvoke = function(joueur, action, ...)
	return commande:traiter(joueur, action, ...)
end
remote.Parent = ReplicatedStorage

Players.PlayerAdded:Connect(function(joueur)
	commande:arrivee(joueur)
end)
for _, joueur in ipairs(Players:GetPlayers()) do
	task.spawn(commande.arrivee, commande, joueur)
end
Players.PlayerRemoving:Connect(function(joueur)
	commande:depart(joueur)
end)

local function sauvegardeReguliere()
	commande:enregistrerTout()
	task.delay(Commande.PERIODE_SAUVEGARDE, sauvegardeReguliere)
end
task.delay(Commande.PERIODE_SAUVEGARDE, sauvegardeReguliere)
game:BindToClose(function()
	commande:fermer()
end)
