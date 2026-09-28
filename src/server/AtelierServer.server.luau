-- AtelierServer : commandes, argent, validation de la découpe et notation des vêtements livrés.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")

local dossier = ReplicatedStorage:WaitForChild("Couture")
local CoutureData = require(dossier:WaitForChild("CoutureData"))

local ARGENT_DEPART = 100
local POURBOIRE = 15
local DELAI_ENTRE_APPELS = 0.2

local rng = Random.new()

local remote = Instance.new("RemoteFunction")
remote.Name = "CoutureRemote"
remote.Parent = dossier

-- Sauvegarde : désactivée sans erreur si les API ne sont pas autorisées (ex. Studio)
local store
do
	local ok, resultat = pcall(function()
		return DataStoreService:GetDataStore("AtelierCouture_v1")
	end)
	if ok then
		store = resultat
	else
		warn("[Atelier] DataStore indisponible, progression non sauvegardée : " .. tostring(resultat))
	end
end

local etats = {}

local function charger(player)
	if not store then
		return nil
	end
	local ok, data = pcall(function()
		return store:GetAsync("joueur_" .. player.UserId)
	end)
	if ok and type(data) == "table" then
		return data
	end
	return nil
end

local function sauvegarder(player)
	local stats = player:FindFirstChild("leaderstats")
	if not store or not stats then
		return
	end
	local data = { argent = stats.Argent.Value, reputation = stats["Réputation"].Value }
	local ok, err = pcall(function()
		store:SetAsync("joueur_" .. player.UserId, data)
	end)
	if not ok then
		warn("[Atelier] Sauvegarde échouée pour " .. player.Name .. " : " .. tostring(err))
	end
end

local function onPlayerAdded(player)
	etats[player] = { commande = nil, tissu = nil, dernierAppel = 0 }

	local stats = Instance.new("Folder")
	stats.Name = "leaderstats"
	local argent = Instance.new("IntValue")
	argent.Name = "Argent"
	argent.Value = ARGENT_DEPART
	argent.Parent = stats
	local reputation = Instance.new("IntValue")
	reputation.Name = "Réputation"
	reputation.Value = 0
	reputation.Parent = stats

	local data = charger(player)
	if data then
		argent.Value = tonumber(data.argent) or ARGENT_DEPART
		reputation.Value = tonumber(data.reputation) or 0
	end
	stats.Parent = player
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(onPlayerAdded, player)
end

Players.PlayerRemoving:Connect(function(player)
	sauvegarder(player)
	etats[player] = nil
end)

game:BindToClose(function()
	for _, player in ipairs(Players:GetPlayers()) do
		sauvegarder(player)
	end
end)

local function choisir(liste)
	return liste[rng:NextInteger(1, #liste)]
end

local function nouvelleCommande(player, etat)
	local commande = {
		client = choisir(CoutureData.Clients),
		vetement = choisir(CoutureData.Vetements).id,
		teinte = choisir(CoutureData.Teintes).id,
		deco = rng:NextNumber() < 0.6 and choisir(CoutureData.Decorations).id or nil,
	}
	commande.texte = CoutureData.phraseCommande(commande)
	etat.commande = commande
	etat.tissu = nil

	-- Filet de sécurité : toujours de quoi acheter au moins un tissu
	local argent = player.leaderstats.Argent
	local minimum = CoutureData.prixMinimum()
	if argent.Value < minimum then
		argent.Value = minimum
	end

	return { ok = true, commande = commande }
end

local function acheterTissu(player, etat, idTissu)
	if not etat.commande then
		return { ok = false, erreur = "Aucune commande en cours." }
	end
	if etat.tissu then
		return { ok = false, erreur = "Tu as déjà acheté le tissu pour cette commande." }
	end
	local tissu = type(idTissu) == "string" and CoutureData.getTissu(idTissu)
	if not tissu then
		return { ok = false, erreur = "Tissu inconnu." }
	end
	local argent = player.leaderstats.Argent
	if argent.Value < tissu.prix then
		return { ok = false, erreur = "Pas assez d'argent pour ce tissu." }
	end
	argent.Value -= tissu.prix
	etat.tissu = tissu.id
	return { ok = true }
end

-- Le client envoie une liste { i, x, y, pivote } ; on la convertit en table indexée par pièce
local function lirePlacements(liste, vetement)
	local placements = {}
	if type(liste) ~= "table" or #liste > 50 then
		return placements
	end
	for _, entree in ipairs(liste) do
		if type(entree) == "table" and type(entree.i) == "number" then
			local i = entree.i
			if i == math.floor(i) and i >= 1 and i <= #vetement.pieces and placements[i] == nil then
				placements[i] = { x = entree.x, y = entree.y, pivote = entree.pivote == true }
			end
		end
	end
	return placements
end

local REMARQUES = {
	couleur = "Ce n'est pas vraiment la couleur que j'avais demandée…",
	decoupe = "Les pièces sont mal coupées, ça tombe de travers.",
	couture = "Les coutures sont un peu tordues…",
	finitions = "Il manque la finition que j'avais demandée.",
}

local function commentaire(etoiles, notes)
	if etoiles == 5 then
		return "C'est parfait, je l'adore ! Voici un petit pourboire."
	end
	local pire, cle = math.huge, "couture"
	for _, nom in ipairs({ "couleur", "decoupe", "couture", "finitions" }) do
		if notes[nom] < pire then
			pire, cle = notes[nom], nom
		end
	end
	if etoiles >= 3 then
		return "Pas mal ! " .. REMARQUES[cle]
	end
	return "Hum… " .. REMARQUES[cle]
end

local function livrer(player, etat, resultat)
	local commande = etat.commande
	if not commande then
		return { ok = false, erreur = "Aucune commande en cours." }
	end
	if not etat.tissu then
		return { ok = false, erreur = "Achète d'abord un tissu." }
	end
	if type(resultat) ~= "table" then
		return { ok = false, erreur = "Données de livraison invalides." }
	end

	local vetement = CoutureData.getVetement(commande.vetement)
	local tissu = CoutureData.getTissu(etat.tissu)
	local argent = player.leaderstats.Argent
	local reputation = player.leaderstats["Réputation"]

	-- La découpe est recalculée ici : le serveur ne fait pas confiance à la note du client
	local noteDecoupe = CoutureData.evaluerDecoupe(vetement, lirePlacements(resultat.placements, vetement))

	-- Le mini-jeu de couture se joue côté client : on borne simplement chaque précision
	local coutures = type(resultat.coutures) == "table" and resultat.coutures or {}
	local somme = 0
	for i = 1, #vetement.coutures do
		local precision = coutures[i]
		if type(precision) == "number" and precision == precision then
			somme += math.clamp(precision, 0, 1)
		end
	end
	local noteCouture = somme / #vetement.coutures

	-- Finitions : payées au moment de la livraison, dans la limite de l'argent disponible
	local choisies, dejaVues, cout = {}, {}, 0
	if type(resultat.decorations) == "table" then
		for _, id in ipairs(resultat.decorations) do
			local deco = type(id) == "string" and CoutureData.getDecoration(id)
			if deco and not dejaVues[id] and argent.Value - cout >= deco.prix then
				dejaVues[id] = true
				cout += deco.prix
				table.insert(choisies, id)
			end
		end
	end
	argent.Value -= cout

	local noteFinitions
	if commande.deco then
		noteFinitions = dejaVues[commande.deco] and 1 or 0.3
	else
		noteFinitions = #choisies > 0 and 1 or 0.8
	end

	local notes = {
		couleur = tissu.teinte == commande.teinte and 1 or 0.2,
		decoupe = noteDecoupe,
		couture = noteCouture,
		finitions = noteFinitions,
	}
	local total = notes.couleur * 0.25 + notes.decoupe * 0.3 + notes.couture * 0.3 + notes.finitions * 0.15
	local etoiles = math.clamp(math.floor(total * 5 + 0.5), 1, 5)
	local paiement = math.floor(vetement.prixBase * total * tissu.qualite + 0.5)
	if etoiles == 5 then
		paiement += POURBOIRE
	end

	argent.Value += paiement
	reputation.Value += etoiles
	etat.commande = nil
	etat.tissu = nil

	return {
		ok = true,
		etoiles = etoiles,
		paiement = paiement,
		coutFinitions = cout,
		notes = notes,
		commentaire = commentaire(etoiles, notes),
	}
end

remote.OnServerInvoke = function(player, action, argument)
	local etat = etats[player]
	if not etat or not player:FindFirstChild("leaderstats") then
		return { ok = false, erreur = "L'atelier se prépare, réessaie dans un instant." }
	end
	local maintenant = os.clock()
	if maintenant - etat.dernierAppel < DELAI_ENTRE_APPELS then
		return { ok = false, erreur = "Doucement !" }
	end
	etat.dernierAppel = maintenant

	if action == "NouvelleCommande" then
		return nouvelleCommande(player, etat)
	elseif action == "AcheterTissu" then
		return acheterTissu(player, etat, argument)
	elseif action == "Livrer" then
		return livrer(player, etat, argument)
	end
	return { ok = false, erreur = "Action inconnue." }
end

-- Établi avec une invite de proximité pour ouvrir l'atelier (créé s'il n'existe pas déjà)
local etabli = workspace:FindFirstChild("Etabli")
if not etabli then
	etabli = Instance.new("Part")
	etabli.Name = "Etabli"
	etabli.Anchored = true
	etabli.Size = Vector3.new(8, 3, 4)
	etabli.Position = Vector3.new(0, 1.5, -14)
	etabli.Color = Color3.fromRGB(176, 124, 84)
	etabli.Material = Enum.Material.Wood
	etabli.Parent = workspace
end
if etabli:IsA("BasePart") and not etabli:FindFirstChild("AtelierPrompt") then
	local invite = Instance.new("ProximityPrompt")
	invite.Name = "AtelierPrompt"
	invite.ActionText = "Ouvrir l'atelier"
	invite.ObjectText = "Établi de couture"
	invite.HoldDuration = 0
	invite.MaxActivationDistance = 12
	invite.RequiresLineOfSight = false
	invite.Parent = etabli
end
