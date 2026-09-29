-- Serveur de l'atelier : il fait foi (spec §2). Une seule RemoteFunction « Atelier », une action par
-- étape (Commande). Les parties sont sauvegardées (Sauvegarde) : lues à l'arrivée du joueur, écrites
-- toutes les 60 s, à son départ et à l'arrêt du serveur. Chaque joueur a sa boutique dans la rue
-- (Boutiques), avec sa dernière robe livrée en vitrine.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Commande = require(script:WaitForChild("Commande"))
local Sauvegarde = require(script:WaitForChild("Sauvegarde"))
local Boutiques = require(script:WaitForChild("Boutiques"))

local boutiques = Boutiques.nouvelles(Workspace)
-- Pas de sauvegarde sur un lieu non publié, ni si le DataStore est indisponible (avertissement)
local commande = Commande.nouvelle({
	sauvegarde = Sauvegarde.pourLeJeu(),
	vitrine = function(joueur, recette)
		boutiques:exposer(joueur, recette)
	end,
})

local remote = Instance.new("RemoteFunction")
remote.Name = "Atelier"
remote.OnServerInvoke = function(joueur, action, ...)
	return commande:traiter(joueur, action, ...)
end
remote.Parent = ReplicatedStorage

-- Arrivée : une boutique dans la rue (l'avatar apparaît à son entrée), puis la partie
local function arrivee(joueur)
	boutiques:attribuer(joueur)
	joueur.CharacterAdded:Connect(function()
		task.defer(boutiques.placer, boutiques, joueur) -- après la mise en place par Roblox
	end)
	boutiques:placer(joueur)
	commande:arrivee(joueur)
end
Players.PlayerAdded:Connect(arrivee)
for _, joueur in ipairs(Players:GetPlayers()) do
	task.spawn(arrivee, joueur)
end
Players.PlayerRemoving:Connect(function(joueur)
	commande:depart(joueur)
	boutiques:liberer(joueur)
end)

local function sauvegardeReguliere()
	commande:enregistrerTout()
	task.delay(Commande.PERIODE_SAUVEGARDE, sauvegardeReguliere)
end
task.delay(Commande.PERIODE_SAUVEGARDE, sauvegardeReguliere)
game:BindToClose(function()
	commande:fermer()
end)
