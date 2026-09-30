-- Sauvegarde (serveur) : la partie de chaque joueur dans le DataStore « AtelierCouture_v2 », une clé par
-- joueur (spec §6). Écriture par UpdateAsync, avec un verrou de session { jobId, t } : si un autre serveur
-- tient la partie depuis moins de 90 s, on réessaie toutes les 3 s pendant 15 s au plus, puis on prend la
-- main. Aucune écriture si la lecture a échoué, ni sur une partie d'une version plus récente du jeu.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local Couture = ReplicatedStorage:WaitForChild("Couture")
local Catalogue = require(Couture:WaitForChild("Catalogue"))
local Recette = require(Couture:WaitForChild("Recette"))
local EtatAtelier = require(Couture:WaitForChild("EtatAtelier"))
local Clientes = require(Couture:WaitForChild("Clientes"))
local Histoire = require(Couture:WaitForChild("Histoire"))

local Sauvegarde = {}
Sauvegarde.__index = Sauvegarde

Sauvegarde.VERSION = 3
Sauvegarde.MAGASIN = "AtelierCouture_v2"
Sauvegarde.ANCIEN_MAGASIN = "AtelierCouture_v1" -- le prototype : { argent, reputation }
Sauvegarde.VERROU_VIVANT = 90 -- s : un verrou plus récent appartient à un serveur encore en vie
Sauvegarde.ESSAI_PAS = 3 -- s entre deux essais quand la partie est tenue ailleurs
Sauvegarde.ESSAI_MAX = 15 -- s : au-delà, on prend la main
Sauvegarde.ESSAIS_LECTURE = 3 -- une panne passagère du DataStore à la lecture est réessayée
Sauvegarde.TAILLE_MAX = 3500000 -- caractères (JSON) : sous les 4 Mo d'une clé du DataStore, verrou compris
-- Champs de l'état qui forment la commande en cours (une déconnexion ne perd pas le travail)
local EN_COURS = { "etape", "commande", "croquis", "tissus", "coupees", "coupons", "epinglees", "coutures", "accessoires" }

local function cle(userId)
	return "joueur_" .. tostring(userId)
end

local function nombre(n, defaut)
	if type(n) ~= "number" or n ~= n or n == math.huge or n == -math.huge then
		return defaut
	end
	return n
end

local function copie(v)
	if type(v) ~= "table" then
		return v
	end
	local c = {}
	for k, x in pairs(v) do
		c[k] = copie(x)
	end
	return c
end

-- Une exigence de commande qu'on sait juger (catalogue actuel)
local function exigenceLisible(e)
	if type(e) ~= "table" then
		return false
	elseif e.type == "min" or e.type == "max" then
		return table.find(Catalogue.STYLES, e.style) ~= nil and nombre(e.valeur, nil) ~= nil
	elseif e.type == "qualite" then
		return nombre(e.valeur, nil) ~= nil
	elseif e.type == "teinte" then
		return table.find(Catalogue.TEINTES, e.teinte) ~= nil
	elseif e.type == "accessoire" then
		return type(e.id) == "string" and Catalogue.accessoire(e.id) ~= nil
	end
	return false
end

-- Des mesures (dm) dans les bornes d'une recette, la taille pas plus large que la poitrine ni les hanches
-- (comme les exigent la prise de mesures et la recette)
local function mesuresLisibles(m)
	local function borne(v, bornes)
		return nombre(v, nil) ~= nil and v >= bornes[1] and v <= bornes[2]
	end
	return type(m) == "table" and borne(m.poitrine, Recette.POITRINE) and borne(m.taille, Recette.TAILLE) and borne(m.hanches, Recette.HANCHES)
		and m.taille <= m.poitrine and m.taille <= m.hanches
end

-- Une commande sauvegardée qu'on peut jouer jusqu'au bout : taille et cliente connues (une cliente à mesurer à
-- l'étape des mesures), mesures lisibles (sauf à l'étape des mesures, où elles ne sont pas encore prises),
-- ajustement entre 50 et 100 %, acompte entier et raisonnable, 1 à 3 exigences lisibles. Une robe libre : ni
-- cliente ni exigence, mesures de sa taille, prix des matières raisonnable
local function commandeLisible(c, etape)
	if type(c) ~= "table" or type(c.taille) ~= "string" or not Catalogue.TAILLES[c.taille] then
		return false
	end
	if c.libre ~= nil then
		return c.libre == true and c.cliente == nil and etape ~= "mesures" and type(c.exigences) == "table" and next(c.exigences) == nil
			and mesuresLisibles(c.mesures) and (c.matieres == nil or (nombre(c.matieres, nil) and c.matieres >= 0 and c.matieres <= 100000))
	end
	if (c.cliente ~= nil or etape == "mesures") and not Clientes.get(c.cliente) then
		return false
	end
	if not (etape == "mesures" and c.mesures == nil) and not mesuresLisibles(c.mesures) then
		return false
	end
	if c.ajustement ~= nil and not (nombre(c.ajustement, nil) and c.ajustement >= 0.5 and c.ajustement <= 1) then
		return false
	end
	if c.acompte ~= nil and not (nombre(c.acompte, nil) and c.acompte == math.floor(c.acompte) and c.acompte >= 0 and c.acompte <= 1000) then
		return false
	end
	if c.parLettre ~= nil and c.parLettre ~= true then
		return false
	end
	if c.histoire ~= nil and not (type(c.histoire) == "string" and Histoire.commande(c.histoire)) then
		return false
	end
	if type(c.exigences) ~= "table" or #c.exigences < 1 or #c.exigences > 3 then
		return false
	end
	for _, e in ipairs(c.exigences) do
		if not exigenceLisible(e) then
			return false
		end
	end
	return true
end

-- Migrations : MIGRATIONS[v] passe une partie du format v au format v + 1
Sauvegarde.MIGRATIONS = {
	-- v1 (prototype) : seul l'argent est repris ; une table vide donne une partie neuve
	[1] = function(v1)
		return {
			version = 2,
			argent = math.max(0, math.floor(nombre(v1.argent, EtatAtelier.ARGENT_DEPART))),
			stock = {},
			debloques = { tissus = {}, variantes = {}, accessoires = {} }, -- (sous-projet 2)
			recettes = {},
		}
	end,
	-- v2 → v3 (sous-projet 2) : fiches des clientes, prestige ; le travail passé compte (20 points par robe gardée)
	[2] = function(v2)
		local robes = type(v2.recettes) == "table" and #v2.recettes or 0
		v2.version = 3
		v2.prestige = 20 * robes
		v2.livraisons = robes
		v2.visites = 0
		v2.clientes = {}
		return v2
	end,
}

-- La partie au format actuel, ou nil si elle vient d'une version plus récente du jeu (on n'y touche pas)
function Sauvegarde.migrer(partie)
	local version = nombre(partie.version, 1) -- la v1 n'avait pas de numéro
	if version > Sauvegarde.VERSION then
		return nil
	end
	while version < Sauvegarde.VERSION do
		partie = Sauvegarde.MIGRATIONS[version](partie)
		version = partie.version
	end
	return partie
end

-- Taille (JSON) de chaque robe livrée, mesurée une seule fois : une robe livrée ne change plus
local taillesRobes = setmetatable({}, { __mode = "k" })

-- La partie d'un état de l'atelier (debloques : ceux de la partie chargée, gardés tels quels). Trop
-- lourde pour le DataStore (des centaines de garnitures sur chaque robe), elle perd ses plus anciennes
-- robes jusqu'à tenir. La taille se calcule sans réencoder la partie : celle de la partie sans robes,
-- plus celle de chaque robe gardée (et une virgule entre deux).
function Sauvegarde.depuisEtat(etat, debloques)
	local d = etat:exporter()
	local partie = {
		version = Sauvegarde.VERSION,
		argent = d.argent,
		stock = d.stock,
		debloques = copie(debloques) or { tissus = {}, variantes = {}, accessoires = {} },
		recettes = d.robes,
		clientes = d.clientes,
		prestige = d.prestige,
		livraisons = d.livraisons,
		visites = d.visites,
		ventes = d.ventes,
		lettres = d.lettres,
		histoire = d.histoire,
	}
	if d.etape ~= "accueil" then
		partie.enCours = {}
		for _, champ in ipairs(EN_COURS) do
			partie.enCours[champ] = d[champ]
		end
	end
	local recettes = partie.recettes
	partie.recettes = {}
	local taille = #HttpService:JSONEncode(partie)
	for i, robe in ipairs(etat.robes) do
		local t = taillesRobes[robe]
		if not t then
			t = #HttpService:JSONEncode(robe)
			taillesRobes[robe] = t
		end
		taille += t + (if i > 1 then 1 else 0)
		if taille > Sauvegarde.TAILLE_MAX then
			break -- cette robe et les plus anciennes ne tiennent pas
		end
		partie.recettes[i] = recettes[i]
	end
	return partie
end

-- L'état de l'atelier d'une partie. Ce qui est illisible (tissu retiré du catalogue, données abîmées) est
-- laissé de côté ; une commande en cours illisible est abandonnée, l'argent, le stock et les robes restent.
function Sauvegarde.versEtat(partie)
	local base = EtatAtelier.nouveau(math.max(0, nombre(partie.argent, EtatAtelier.ARGENT_DEPART)))
	local function entier(v)
		return math.max(0, math.floor(nombre(v, 0)))
	end
	base.prestige, base.livraisons, base.visites = entier(partie.prestige), entier(partie.livraisons), entier(partie.visites)
	base.ventes = entier(partie.ventes)
	-- Histoire : les commandes livrées, connues du tableau seulement
	local histoire = type(partie.histoire) == "table" and type(partie.histoire.faites) == "table" and partie.histoire.faites or {}
	for id, fait in pairs(histoire) do
		if fait == true and type(id) == "string" and Histoire.commande(id) then
			base.histoire.faites[id] = true
		end
	end
	-- Courrier : trois lettres au plus, d'une cliente connue, avec une commande qu'on peut jouer
	for _, l in ipairs(type(partie.lettres) == "table" and partie.lettres or {}) do
		if type(l) == "table" and type(l.cliente) == "string" and type(l.commande) == "table" and l.commande.cliente == l.cliente
			and commandeLisible(l.commande, "mesures") and #base.lettres < EtatAtelier.LETTRES_MAX then
			table.insert(base.lettres, { cliente = l.cliente, commande = copie(l.commande) })
		end
	end
	-- Fiches des clientes : clientes connues seulement ; des mesures impossibles sont oubliées (on remesurera)
	for id, f in pairs(type(partie.clientes) == "table" and partie.clientes or {}) do
		if type(id) == "string" and Clientes.get(id) and type(f) == "table" then
			local mesures = mesuresLisibles(f.mesures) and copie(f.mesures) or nil
			base.clientes[id] = {
				amitie = entier(f.amitie),
				vues = entier(f.vues),
				derniere = entier(f.derniere),
				mesures = mesures,
				ajustement = mesures and math.clamp(nombre(f.ajustement, 1), 0.5, 1) or nil,
			}
		end
	end
	for id, dm in pairs(type(partie.stock) == "table" and partie.stock or {}) do
		if type(id) == "string" and Catalogue.tissu(id) and nombre(dm, -1) >= 0 then
			base.stock[id] = dm
		end
	end
	for _, r in ipairs(type(partie.recettes) == "table" and partie.recettes or {}) do
		local lue, valide = pcall(Recette.valider, r)
		if lue and valide and #base.robes < EtatAtelier.ROBES_GARDEES then
			table.insert(base.robes, r)
		end
	end
	if type(partie.enCours) ~= "table" then
		return base
	end
	local d = base:exporter()
	for _, champ in ipairs(EN_COURS) do
		if partie.enCours[champ] ~= nil then
			d[champ] = partie.enCours[champ]
		end
	end
	local etat = EtatAtelier.nouveau()
	local ok, erreur = pcall(function()
		etat:charger(d)
		assert(table.find(EtatAtelier.ETAPES, etat.etape), "étape inconnue")
		assert(etat.etape == "accueil" or commandeLisible(etat.commande, etat.etape), "commande illisible")
		-- La fiche de la cliente de la commande, si elle a été perdue : recréée (sa visite en cours compte)
		local id = etat.commande and etat.commande.cliente
		if id and not etat.clientes[id] then
			etat.clientes[id] = { amitie = 0, vues = 1, derniere = etat.visites }
		end
		etat:piecesDuCroquis() -- lit le croquis
		for _, idTissu in pairs(etat.tissus) do
			assert(Catalogue.tissu(idTissu), "tissu inconnu")
		end
		for idTissu in pairs(etat.coupons) do
			assert(Catalogue.tissu(idTissu), "rouleau d'un tissu inconnu")
		end
		local recette = etat:recette() -- lit les pièces coupées, les coutures et les décorations
		if recette then
			assert(Recette.valider(recette))
		end
	end)
	if not ok then
		warn("[Atelier] Commande en cours illisible, abandonnée : " .. tostring(erreur))
		return base
	end
	return etat
end

function Sauvegarde.nouvelle(options)
	return setmetatable({
		magasin = options.magasin,
		ancien = options.ancien,
		jobId = options.jobId,
		horloge = options.horloge or os.time,
		attendre = options.attendre or task.wait,
	}, Sauvegarde)
end

-- Pour le jeu : nil (sans erreur) si le lieu n'est pas publié ou si le DataStore est indisponible
function Sauvegarde.pourLeJeu()
	if game.PlaceId == 0 then
		warn("[Atelier] Lieu non publié : les parties ne sont pas sauvegardées.")
		return nil
	end
	local ok, magasin, ancien = pcall(function()
		return DataStoreService:GetDataStore(Sauvegarde.MAGASIN), DataStoreService:GetDataStore(Sauvegarde.ANCIEN_MAGASIN)
	end)
	if not ok then
		warn("[Atelier] DataStore indisponible, les parties ne sont pas sauvegardées : " .. tostring(magasin))
		return nil
	end
	return Sauvegarde.nouvelle({ magasin = magasin, ancien = ancien, jobId = game.JobId })
end

-- Prend la partie d'un joueur et son verrou. Renvoie la partie (sans le verrou) et "ok", ou nil et "echec"
-- (lecture impossible, partie illisible ou d'une version plus récente) : rien ne sera écrit pour ce joueur.
function Sauvegarde:charger(userId)
	local debut = self.horloge()
	local ancienne = nil -- ancienne sauvegarde (v1), lue une fois pour un joueur sans partie v2
	local pannes = 0
	-- Panne du DataStore : on réessaie (toutes les 3 s), puis on renonce
	local function panne()
		pannes += 1
		if pannes >= Sauvegarde.ESSAIS_LECTURE then
			return true
		end
		self.attendre(Sauvegarde.ESSAI_PAS)
		return false
	end
	while true do
		local maintenant = self.horloge()
		local prendre = maintenant - debut >= Sauvegarde.ESSAI_MAX
		local absente, tenue, illisible, partie
		local ok = pcall(function()
			self.magasin:UpdateAsync(cle(userId), function(actuelle)
				absente, tenue, illisible, partie = false, false, false, nil -- (Roblox peut rappeler cette fonction)
				if actuelle == nil then
					if not ancienne then
						absente = true
						return nil
					end
					actuelle = ancienne
				end
				if type(actuelle) ~= "table" then
					illisible = true
					return nil
				end
				local verrou = actuelle.verrou
				if not prendre and type(verrou) == "table" and verrou.jobId ~= self.jobId
					and maintenant - nombre(verrou.t, 0) < Sauvegarde.VERROU_VIVANT then
					tenue = true
					return nil
				end
				local migree = Sauvegarde.migrer(copie(actuelle))
				if not migree then
					illisible = true
					return nil
				end
				migree.verrou = { jobId = self.jobId, t = maintenant }
				partie = migree
				return migree
			end)
		end)
		if illisible then
			return nil, "echec"
		end
		if not ok then
			if panne() then
				return nil, "echec"
			end
		elseif absente then
			local lue, v1 = pcall(function()
				return self.ancien and self.ancien:GetAsync(cle(userId))
			end)
			if lue then
				ancienne = type(v1) == "table" and v1 or {} -- rien : une partie neuve
			elseif panne() then
				return nil, "echec"
			end
		elseif tenue then
			self.attendre(Sauvegarde.ESSAI_PAS)
		else
			partie.verrou = nil
			return partie, "ok"
		end
	end
end

-- Écrit la partie d'un joueur et rafraîchit son verrou (ou le rend, si liberer). Renvoie "ok", "echec"
-- (le DataStore n'a pas répondu : on réessaiera) ou "perdu" (un autre serveur a pris la partie, ou elle
-- vient d'une version plus récente : ne plus l'écraser depuis ce serveur).
function Sauvegarde:enregistrer(userId, partie, liberer)
	local perdu = false
	local ok = pcall(function()
		self.magasin:UpdateAsync(cle(userId), function(actuelle)
			perdu = false
			if type(actuelle) == "table" then
				local verrou = actuelle.verrou
				if (type(verrou) == "table" and verrou.jobId ~= self.jobId) or nombre(actuelle.version, 1) > Sauvegarde.VERSION then
					perdu = true
					return nil
				end
			end
			local d = copie(partie)
			d.version = Sauvegarde.VERSION
			-- Rendu, le verrou garde le serveur qui le tenait (temps nul : libre pour tous) : un autre serveur
			-- resté en retard, qui se réveillerait après une session plus récente ailleurs, ne l'écrase pas
			d.verrou = { jobId = self.jobId, t = if liberer then 0 else self.horloge() }
			return d
		end)
	end)
	if not ok then
		return "echec"
	end
	return perdu and "perdu" or "ok"
end

return Sauvegarde
