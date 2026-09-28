-- AtelierServer : commandes, argent, validation de la découpe, mini-jeu de couture
-- arbitré par le serveur, notation, mannequin de l'atelier et vêtement porté par l'avatar.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")

local dossier = ReplicatedStorage:WaitForChild("Couture")
local CoutureData = require(dossier:WaitForChild("CoutureData"))
local Rendu3D = require(dossier:WaitForChild("Rendu3D"))

local ARGENT_DEPART = 100
local POURBOIRE = 15
local DELAI_ENTRE_APPELS = 0.2
-- Marge acceptée entre le temps annoncé par le client et le temps mesuré par le serveur
local TOLERANCE_PIQURE = 0.08

local rng = Random.new()

local remote = Instance.new("RemoteFunction")
remote.Name = "CoutureRemote"
remote.Parent = dossier

---------------------------------------------------------------------------
-- Atelier : établi et mannequin
---------------------------------------------------------------------------

local etabli = workspace:FindFirstChild("Etabli")
if not etabli then
	etabli = Instance.new("Part")
	etabli.Name = "Etabli"
	etabli.Anchored = true
	etabli.Size = Vector3.new(8, 3, 4)
	etabli.CFrame = CFrame.new(0, 1.5, -14)
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

-- Le mannequin présente la dernière création livrée (une robe d'exemple au départ)
local mannequin = Rendu3D.creerMannequin(CFrame.new(7, 0, -14) * CFrame.Angles(0, math.pi, 0))
mannequin.Name = "MannequinAtelier"
mannequin.Parent = workspace
Rendu3D.habiller(mannequin, {
	vetement = "robe",
	tissu = "soie_rose",
	decorations = { "dentelle", "ruban" },
	decoupe = 1,
	couture = 1,
	pivotees = 0,
	graine = 7,
})

---------------------------------------------------------------------------
-- Joueurs et sauvegarde
---------------------------------------------------------------------------

-- Sauvegarde : désactivée sans erreur si les API ne sont pas autorisées (ex. Studio)
local store
if game.PlaceId == 0 then
	-- Lieu jamais publié (fichier ouvert dans Studio) : GetDataStore lèverait une erreur
	-- qui met le débogueur de Studio en pause à chaque Play
	warn("[Atelier] Lieu non publié : progression non sauvegardée.")
else
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
-- Joueurs dont la sauvegarde a été lue sans erreur : seuls ceux-là peuvent être réécrits.
-- Sinon, une panne passagère du DataStore au chargement ferait écraser la vraie
-- progression par l'argent de départ au moment de quitter.
local chargementReussi = {}
local dejaSauve = {}

-- Retourne (true, données ou nil) si la lecture a abouti, false sinon
local function charger(player)
	if not store then
		return false
	end
	for essai = 1, 3 do
		local ok, data = pcall(function()
			return store:GetAsync("joueur_" .. player.UserId)
		end)
		if ok then
			return true, type(data) == "table" and data or nil
		end
		warn("[Atelier] Lecture de la sauvegarde impossible pour " .. player.Name .. " : " .. tostring(data))
		-- API désactivées (Studio) : inutile de réessayer
		if string.find(tostring(data), "API", 1, true) then
			return false
		end
		if essai < 3 then
			task.wait(essai)
		end
	end
	return false
end

local function sauvegarder(player)
	local stats = player:FindFirstChild("leaderstats")
	if not store or not stats or not chargementReussi[player] then
		return
	end
	local data = { argent = stats.Argent.Value, reputation = stats["Réputation"].Value }
	local ok, err = pcall(function()
		store:SetAsync("joueur_" .. player.UserId, data)
	end)
	if not ok then
		warn("[Atelier] Sauvegarde non effectuée pour " .. player.Name .. " : " .. tostring(err))
	end
end

-- Remet le vêtement porté après une réapparition (une fois l'apparence et la taille appliquées)
local function rhabiller(player)
	local etat = etats[player]
	local personnage = player.Character
	if etat and etat.porte and etat.dernierVetement and personnage then
		Rendu3D.habiller(personnage, etat.dernierVetement)
	end
end

local function onPlayerAdded(player)
	etats[player] = {
		commande = nil,
		tissu = nil,
		decoupe = nil,
		pivotees = 0,
		couture = nil,
		dernierVetement = nil,
		porte = false,
		dernierAppel = -math.huge,
	}

	player.CharacterAppearanceLoaded:Connect(function()
		rhabiller(player)
	end)

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

	local lu, data = charger(player)
	if player.Parent ~= Players then
		return -- parti pendant le chargement
	end
	chargementReussi[player] = lu or nil
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
	if not dejaSauve[player] then
		dejaSauve[player] = true
		sauvegarder(player)
	end
	etats[player] = nil
	chargementReussi[player] = nil
	dejaSauve[player] = nil
end)

-- À la fermeture du serveur : sauvegardes en parallèle (le délai de BindToClose est limité)
game:BindToClose(function()
	local restants = 0
	for _, player in ipairs(Players:GetPlayers()) do
		if not dejaSauve[player] then
			dejaSauve[player] = true
			restants += 1
			task.spawn(function()
				sauvegarder(player)
				restants -= 1
			end)
		end
	end
	local limite = os.clock() + 25
	while restants > 0 and os.clock() < limite do
		task.wait(0.1)
	end
end)

---------------------------------------------------------------------------
-- Actions du joueur
---------------------------------------------------------------------------

local function choisir(liste)
	return liste[rng:NextInteger(1, #liste)]
end

local function nouvelleCommande(player, etat)
	local commande = {
		client = choisir(CoutureData.Clients),
		vetement = choisir(CoutureData.Vetements).id,
		teinte = choisir(CoutureData.Teintes).id,
		deco = rng:NextNumber() < 0.6 and choisir(CoutureData.Decorations).id or nil,
		graine = rng:NextInteger(1, 1000000),
	}
	commande.texte = CoutureData.phraseCommande(commande)
	etat.commande = commande
	etat.tissu = nil
	etat.decoupe = nil
	etat.pivotees = 0
	etat.couture = nil

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

-- Prépare la couture suivante ; elle commence après « delai » secondes
local function preparerCouture(etat, vetement, indice, delai)
	local parametres = CoutureData.parametresCouture(vetement, indice, rng)
	etat.couture.parametres = parametres
	etat.couture.debut = os.clock() + delai
	local envoi = table.clone(parametres)
	envoi.delai = delai
	return envoi
end

-- La découpe est validée ici, à partir des positions des pièces : le serveur ne fait
-- pas confiance à une note envoyée par le client.
local function commencerCouture(etat, liste)
	if not etat.commande or not etat.tissu then
		return { ok = false, erreur = "Aucune commande en cours." }
	end
	if etat.couture then
		return { ok = false, erreur = "La couture a déjà commencé." }
	end
	local vetement = CoutureData.getVetement(etat.commande.vetement)
	local note, details = CoutureData.evaluerDecoupe(vetement, lirePlacements(liste, vetement))
	for _, detail in ipairs(details) do
		if not detail.placee then
			return { ok = false, erreur = "Place toutes les pièces avant de couper." }
		end
	end
	local pivotees = 0
	for _, detail in ipairs(details) do
		if detail.pivote then
			pivotees += 1
		end
	end
	etat.decoupe = note
	etat.pivotees = pivotees
	etat.couture = { precisions = {} }
	return { ok = true, decoupe = note, couture = preparerCouture(etat, vetement, 1, 0) }
end

-- Le moment de la piqûre est mesuré par le serveur. Le temps annoncé par le client
-- n'est retenu qu'à TOLERANCE près (pour absorber la variation du ping) : impossible
-- d'annoncer une précision, ni de choisir librement l'instant.
local function piquer(player, etat, tempsClient)
	local couture = etat.couture
	if not couture or not couture.parametres then
		return { ok = false, erreur = "Aucune couture en cours." }
	end
	local ping = 0
	pcall(function()
		ping = math.clamp(player:GetNetworkPing(), 0, 0.5)
	end)
	local tempsServeur = os.clock() - couture.debut - 1.5 * ping
	if tempsServeur < -0.15 then
		return { ok = false, erreur = "L'aiguille n'est pas encore prête." }
	end
	local tolerance = TOLERANCE_PIQURE + 0.5 * ping
	local temps = tempsServeur
	if type(tempsClient) == "number" and tempsClient == tempsClient then
		temps = math.clamp(tempsClient, tempsServeur - tolerance, tempsServeur + tolerance)
	end
	temps = math.max(temps, 0)

	local parametres = couture.parametres
	local position = CoutureData.positionAiguille(parametres, temps)
	local precision = CoutureData.precisionPiqure(parametres, position)
	table.insert(couture.precisions, precision)

	local reponse = { ok = true, precision = precision, position = position }
	if parametres.indice < parametres.total then
		local vetement = CoutureData.getVetement(etat.commande.vetement)
		reponse.suivante = preparerCouture(etat, vetement, parametres.indice + 1, CoutureData.PAUSE_ENTRE_COUTURES)
	else
		couture.parametres = nil
		reponse.terminee = true
	end
	return reponse
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
	if not commande or not etat.tissu then
		return { ok = false, erreur = "Aucune commande en cours." }
	end
	local vetement = CoutureData.getVetement(commande.vetement)
	local couture = etat.couture
	if not couture or #couture.precisions < #vetement.coutures then
		return { ok = false, erreur = "Termine d'abord toutes les coutures." }
	end

	local tissu = CoutureData.getTissu(etat.tissu)
	local argent = player.leaderstats.Argent
	local reputation = player.leaderstats["Réputation"]

	local somme = 0
	for _, precision in ipairs(couture.precisions) do
		somme += precision
	end
	local noteCouture = somme / #couture.precisions

	-- Finitions : payées au moment de la livraison, dans la limite de l'argent disponible
	local choisies, dejaVues, cout = {}, {}, 0
	local demandees = type(resultat) == "table" and resultat.decorations
	if type(demandees) == "table" and #demandees <= 2 * #CoutureData.Decorations then
		for _, id in ipairs(demandees) do
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
		decoupe = etat.decoupe,
		couture = noteCouture,
		finitions = noteFinitions,
	}
	local total, etoiles = CoutureData.noteFinale(notes)
	local paiement = math.floor(vetement.prixBase * total * tissu.qualite + 0.5)
	if etoiles == 5 then
		paiement += POURBOIRE
	end

	argent.Value += paiement
	reputation.Value += etoiles

	-- Le vêtement livré est exposé sur le mannequin de l'atelier
	local vetementFini = {
		vetement = vetement.id,
		tissu = tissu.id,
		decorations = choisies,
		decoupe = notes.decoupe,
		couture = noteCouture,
		pivotees = etat.pivotees,
		graine = commande.graine,
	}
	etat.dernierVetement = vetementFini
	Rendu3D.habiller(mannequin, vetementFini)

	etat.commande = nil
	etat.tissu = nil
	etat.decoupe = nil
	etat.couture = nil

	return {
		ok = true,
		etoiles = etoiles,
		paiement = paiement,
		coutFinitions = cout,
		notes = notes,
		commentaire = commentaire(etoiles, notes),
		vetement = vetementFini,
	}
end

local function porter(player, etat)
	if not etat.dernierVetement then
		return { ok = false, erreur = "Livre d'abord un vêtement." }
	end
	local personnage = player.Character
	if not personnage or not Rendu3D.habiller(personnage, etat.dernierVetement) then
		return { ok = false, erreur = "Ton avatar n'est pas encore prêt, réessaie." }
	end
	etat.porte = true
	return { ok = true }
end

local function retirer(player, etat)
	etat.porte = false
	if player.Character then
		Rendu3D.deshabiller(player.Character)
	end
	return { ok = true }
end

remote.OnServerInvoke = function(player, action, argument)
	local etat = etats[player]
	if not etat or not player:FindFirstChild("leaderstats") then
		return { ok = false, erreur = "L'atelier se prépare, réessaie dans un instant." }
	end

	-- La piqûre a sa propre protection (pause obligatoire entre deux coutures)
	if action == "Piquer" then
		return piquer(player, etat, argument)
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
	elseif action == "CommencerCouture" then
		return commencerCouture(etat, argument)
	elseif action == "Livrer" then
		return livrer(player, etat, argument)
	elseif action == "Porter" then
		return porter(player, etat)
	elseif action == "Retirer" then
		return retirer(player, etat)
	end
	return { ok = false, erreur = "Action inconnue." }
end
