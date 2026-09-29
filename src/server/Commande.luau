-- Commande (serveur) : l'atelier de chaque joueur, qui fait foi (spec §2). Chaque action du client
-- passe par Commande:traiter : action connue, limite d'appels, règles d'EtatAtelier. Une réponse
-- acceptée emporte l'état (EtatAtelier:exporter), que le client recharge et affiche.
-- Avec une sauvegarde, la partie est lue à l'arrivée du joueur et écrite régulièrement, à son départ
-- et à l'arrêt du serveur ; sans (lieu non publié), chaque joueur commence une partie neuve.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Couture = ReplicatedStorage:WaitForChild("Couture")
local EtatAtelier = require(Couture:WaitForChild("EtatAtelier"))
local Limiteur = require(script.Parent:WaitForChild("Limiteur"))
local Sauvegarde = require(script.Parent:WaitForChild("Sauvegarde"))

local Commande = {}
Commande.__index = Commande

Commande.APPELS_PAR_SECONDE = 5 -- par joueur (spec §6)
Commande.PERIODE_SAUVEGARDE = 60 -- s entre deux sauvegardes de toutes les parties (spec §6)
Commande.FERMETURE_MAX = 25 -- s : à l'arrêt du serveur, attente maximale des dernières sauvegardes
local PREPARATION = "L'atelier se prépare, réessaie dans un instant."
local SANS_SAUVEGARDE = "Ta partie ne peut pas être sauvegardée pour le moment : tes progrès de cette session seront perdus."
-- Les relevés de couture ne sont pas limités : leur propre vraisemblance les borne (spec §6)
local SANS_LIMITE = { rendreCouture = true }

local function refus(message)
	return { ok = false, erreur = message }
end

-- Actions permises : le nom envoyé par le client choisit l'une d'elles, jamais une méthode quelconque
local ACTIONS = {
	-- le client demande l'état (à son arrivée)
	etat = function()
		return { ok = true }
	end,
	-- la commande est tirée par le serveur, avec son propre générateur (l'argument du client est ignoré)
	nouvelleCommande = function(a)
		return a.etat:nouvelleCommande(a.rng)
	end,
	validerCroquis = function(a, croquis, tissus)
		return a.etat:validerCroquis(croquis, tissus)
	end,
	retourCarnet = function(a)
		return a.etat:retourCarnet()
	end,
	acheter = function(a, idTissu, dm)
		return a.etat:acheter(idTissu, dm)
	end,
	commencerDecoupe = function(a)
		return a.etat:commencerDecoupe()
	end,
	couper = function(a, idPiece, placement)
		return a.etat:couper(idPiece, placement)
	end,
	epingler = function(a, idPiece)
		return a.etat:epingler(idPiece)
	end,
	rendreCouture = function(a, idPiece, ecarts, duree, assistance)
		return a.etat:rendreCouture(idPiece, ecarts, duree, assistance)
	end,
	decorer = function(a, liste)
		return a.etat:decorer(liste)
	end,
	retourDecorations = function(a)
		return a.etat:retourDecorations()
	end,
	livrer = function(a)
		return a.etat:livrer()
	end,
	retoucher = function(a)
		return a.etat:retoucher()
	end,
	abandonner = function(a)
		return a.etat:abandonner()
	end,
	recommencer = function(a)
		return a.etat:recommencer()
	end,
}

-- options (facultatif) : { sauvegarde = Sauvegarde, horloge = fonction, attendre = fonction }
function Commande.nouvelle(options)
	options = options or {}
	local self = setmetatable({
		ateliers = {}, -- [joueur] = { etat = EtatAtelier, rng = Random, sauvable = bool, debloques = table? }
		limiteur = Limiteur.nouveau(Commande.APPELS_PAR_SECONDE, 1),
		sauvegarde = options.sauvegarde,
		horloge = options.horloge or os.clock,
		attendre = options.attendre or task.wait,
	}, Commande)
	Commande.courante = self -- le serveur en cours (tests du scénario, débogage dans Studio)
	return self
end

-- L'atelier d'un joueur, ou nil tant que sa partie n'est pas lue. Sans sauvegarde, une partie neuve est
-- créée à son premier appel.
function Commande:atelier(joueur)
	local a = self.ateliers[joueur]
	if not a and not self.sauvegarde then
		a = { etat = EtatAtelier.nouveau(), rng = Random.new(), sauvable = false }
		self.ateliers[joueur] = a
	end
	return a
end

-- Arrivée d'un joueur : lit sa partie (peut attendre, jusqu'à 15 s si un autre serveur la tient). Si la
-- lecture échoue, il joue une partie neuve qui ne sera jamais écrite (sa vraie partie reste intacte).
function Commande:arrivee(joueur)
	if not self.sauvegarde then
		self:atelier(joueur)
		return
	end
	local partie, statut = self.sauvegarde:charger(joueur.UserId)
	if joueur.Parent == nil then
		-- parti pendant la lecture : sa partie est rendue tout de suite
		if statut == "ok" then
			self.sauvegarde:enregistrer(joueur.UserId, partie, true)
		end
		return
	end
	if statut ~= "ok" then
		warn(("[Atelier] %s : partie illisible, elle ne sera pas écrite pendant cette session."):format(joueur.Name))
	end
	self.ateliers[joueur] = {
		etat = partie and Sauvegarde.versEtat(partie) or EtatAtelier.nouveau(),
		rng = Random.new(),
		sauvable = statut == "ok",
		debloques = partie and partie.debloques,
	}
end

-- Écrit la partie d'un joueur (et rend son verrou, si liberer). Renvoie le statut de la sauvegarde, ou nil
-- si sa partie n'est pas à écrire. Une partie prise par un autre serveur n'est plus jamais écrite d'ici.
function Commande:enregistrer(joueur, liberer)
	local a = self.ateliers[joueur]
	if not self.sauvegarde or not a or not a.sauvable then
		return nil
	end
	local statut = self.sauvegarde:enregistrer(joueur.UserId, Sauvegarde.depuisEtat(a.etat, a.debloques), liberer)
	if statut == "perdu" then
		a.sauvable = false
		warn(("[Atelier] %s : sa partie est tenue par un autre serveur, elle n'est plus écrite d'ici."):format(joueur.Name))
	elseif statut == "echec" then
		warn(("[Atelier] %s : sauvegarde impossible pour l'instant, on réessaiera."):format(joueur.Name))
	end
	return statut
end

-- Sauvegarde régulière de toutes les parties (chacune dans sa tâche)
function Commande:enregistrerTout()
	for joueur in pairs(self.ateliers) do
		task.spawn(self.enregistrer, self, joueur, false)
	end
end

-- Départ du joueur : partie écrite, verrou rendu, atelier libéré
function Commande:depart(joueur)
	self:enregistrer(joueur, true)
	self:retirer(joueur)
end

-- Atelier libéré, sans écrire
function Commande:retirer(joueur)
	self.ateliers[joueur] = nil
	self.limiteur:oublier(joueur)
end

-- Arrêt du serveur : toutes les parties écrites en même temps, verrous rendus (25 s au plus)
function Commande:fermer()
	local restantes = 0
	for joueur in pairs(self.ateliers) do
		restantes += 1
		task.spawn(function()
			self:enregistrer(joueur, true)
			restantes -= 1
		end)
	end
	local debut = self.horloge()
	while restantes > 0 and self.horloge() - debut < Commande.FERMETURE_MAX do
		self.attendre(0.5)
	end
end

-- L'état envoyé au client : tout, sauf les anciennes robes (seule la plus récente est en vitrine)
function Commande.instantane(etat)
	local d = etat:exporter()
	d.robes = { d.robes[1] }
	return d
end

-- Une action d'un joueur. Ne lève jamais d'erreur : une erreur imprévue devient un refus.
function Commande:traiter(joueur, action, ...)
	local faire = type(action) == "string" and ACTIONS[action]
	if not faire then
		return refus("Action inconnue.")
	end
	if not SANS_LIMITE[action] and not self.limiteur:autoriser(joueur) then
		return refus("Doucement !")
	end
	local a = self:atelier(joueur)
	if not a then
		return { ok = false, erreur = PREPARATION, attente = true }
	end
	local ok, reponse = pcall(faire, a, ...)
	if not ok then
		warn(("[Atelier] %s : erreur dans « %s » : %s"):format(joueur.Name, action, tostring(reponse)))
		return refus("Action impossible.")
	end
	if reponse.ok then
		reponse.etat = Commande.instantane(a.etat)
		if action == "etat" and self.sauvegarde and not a.sauvable then
			reponse.avertissement = SANS_SAUVEGARDE
		end
	end
	return reponse
end

return Commande
