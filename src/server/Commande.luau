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
Commande.ESSAIS_ECRITURE = 3 -- au départ et à l'arrêt, une panne passagère du DataStore est réessayée
local PREPARATION = "L'atelier se prépare, réessaie dans un instant."
local SANS_SAUVEGARDE = "Ta partie ne peut pas être sauvegardée pour le moment : tes progrès de cette session seront perdus."
-- Les relevés de couture ne sont pas limités : leur propre vraisemblance les borne (spec §6)
local SANS_LIMITE = { rendreCouture = true }

-- passager : refus d'un moment (trop d'appels, partie pas encore lue), le client pourra réessayer
local function refus(message, passager)
	return { ok = false, erreur = message, passager = passager }
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
	mesurer = function(a, prises)
		return a.etat:mesurer(prises)
	end,
	reprendreMesures = function(a)
		return a.etat:reprendreMesures()
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
		return a.etat:livrer(a.rng)
	end,
	inviter = function(a, indice)
		return a.etat:inviter(indice)
	end,
	commandeHistoire = function(a)
		return a.etat:commandeHistoire()
	end,
	nouvelleRobeLibre = function(a, taille)
		return a.etat:nouvelleRobeLibre(taille)
	end,
	vendre = function(a)
		return a.etat:vendre(a.rng)
	end,
	offrir = function(a, idCliente)
		return a.etat:offrir(idCliente)
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

-- options (facultatif) : { sauvegarde = Sauvegarde, horloge = fonction, attendre = fonction,
-- vitrine = function(joueur, recette?) } (vitrine : montre la dernière robe livrée du joueur, ou rien)
function Commande.nouvelle(options)
	options = options or {}
	local self = setmetatable({
		ateliers = {}, -- [joueur] = { etat = EtatAtelier, rng = Random, sauvable = bool, debloques = table? }
		ecritures = {}, -- [UserId] = vrai pendant l'écriture de sa partie (une à la fois par joueur)
		departs = {}, -- [UserId] = vrai pendant son départ (écriture comprise, même quand elle attend)
		chargements = {}, -- [joueur] = vrai pendant la lecture de sa partie
		ferme = false, -- vrai une fois le serveur en train de s'arrêter
		limiteur = Limiteur.nouveau(Commande.APPELS_PAR_SECONDE, 1),
		sauvegarde = options.sauvegarde,
		vitrine = options.vitrine,
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

-- Montre la dernière robe livrée du joueur dans sa vitrine (une panne de la vitrine ne gêne pas l'atelier)
function Commande:exposer(joueur)
	local a = self.ateliers[joueur]
	if not self.vitrine or not a then
		return
	end
	local ok, erreur = pcall(self.vitrine, joueur, a.etat.robes[1])
	if not ok then
		warn(("[Atelier] %s : vitrine non mise à jour : %s"):format(joueur.Name, tostring(erreur)))
	end
end

-- Arrivée d'un joueur : lit sa partie (peut attendre, jusqu'à 15 s si un autre serveur la tient). Si la
-- lecture échoue, il joue une partie neuve qui ne sera jamais écrite (sa vraie partie reste intacte).
-- De retour sur ce serveur avant la fin de l'écriture de son départ, on attend qu'elle soit faite.
function Commande:arrivee(joueur)
	if not self.sauvegarde then
		self:atelier(joueur)
		self:exposer(joueur)
		return
	end
	while self.ecritures[joueur.UserId] or self.departs[joueur.UserId] do
		self.attendre(0.5)
	end
	self.chargements[joueur] = true
	local partie, statut = self.sauvegarde:charger(joueur.UserId)
	if joueur.Parent == nil or self.ferme then
		-- parti pendant la lecture, ou serveur qui s'arrête : sa partie est rendue tout de suite
		if statut == "ok" then
			self.sauvegarde:enregistrer(joueur.UserId, partie, true)
		end
		self.chargements[joueur] = nil
		return
	end
	self.chargements[joueur] = nil
	if statut ~= "ok" then
		warn(("[Atelier] %s : partie illisible, elle ne sera pas écrite pendant cette session."):format(joueur.Name))
	end
	self.ateliers[joueur] = {
		etat = partie and Sauvegarde.versEtat(partie) or EtatAtelier.nouveau(),
		rng = Random.new(),
		sauvable = statut == "ok",
		debloques = partie and partie.debloques,
	}
	self:exposer(joueur)
end

-- Écrit la partie d'un joueur (et rend son verrou, si liberer), en « essais » tentatives (1 par défaut ;
-- la sauvegarde régulière réessaie d'elle-même 60 s plus tard). Renvoie le statut de la sauvegarde, ou nil
-- si sa partie n'est pas à écrire. Une partie prise par un autre serveur n'est plus jamais écrite d'ici.
-- Une écriture à la fois par joueur : la suivante attend la fin de la précédente, puis écrit l'état du
-- moment (la sauvegarde régulière et celle du départ ne se croisent pas).
function Commande:enregistrer(joueur, liberer, essais)
	local a = self.ateliers[joueur]
	if not self.sauvegarde or not a or not a.sauvable then
		return nil
	end
	local id = joueur.UserId
	while self.ecritures[id] do
		self.attendre(0.5)
	end
	if not a.sauvable then
		return nil -- partie prise par un autre serveur pendant l'attente
	end
	-- Le joueur est parti ou le serveur s'arrête pendant l'attente : cette écriture rend le verrou, elle
	-- aussi (sinon elle le reprendrait après celle du départ ou de l'arrêt)
	if self.ateliers[joueur] ~= a or self.ferme then
		liberer = true
	end
	self.ecritures[id] = true
	local ok, statut = pcall(function()
		local partie = Sauvegarde.depuisEtat(a.etat, a.debloques)
		local s
		for essai = 1, essais or 1 do
			s = self.sauvegarde:enregistrer(id, partie, liberer)
			if s ~= "echec" or essai == (essais or 1) then
				break
			end
			self.attendre(1)
		end
		return s
	end)
	self.ecritures[id] = nil
	if not ok then
		warn(("[Atelier] %s : erreur en préparant la sauvegarde : %s"):format(joueur.Name, tostring(statut)))
		statut = "echec"
	end
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
	if self.ferme then
		return -- l'arrêt écrit déjà tout, et rend les verrous
	end
	for joueur in pairs(self.ateliers) do
		task.spawn(self.enregistrer, self, joueur, false)
	end
end

-- Départ du joueur : partie écrite, verrou rendu, atelier libéré
function Commande:depart(joueur)
	local id = joueur.UserId
	self.departs[id] = true -- un retour rapide sur ce serveur attend la fin du départ
	local ok, erreur = pcall(self.enregistrer, self, joueur, true, Commande.ESSAIS_ECRITURE)
	if not ok then
		warn(("[Atelier] %s : erreur en écrivant sa partie au départ : %s"):format(joueur.Name, tostring(erreur)))
	end
	self:retirer(joueur)
	self.departs[id] = nil
end

-- Atelier libéré, sans écrire
function Commande:retirer(joueur)
	self.ateliers[joueur] = nil
	self.limiteur:oublier(joueur)
end

-- Arrêt du serveur : toutes les parties écrites en même temps, verrous rendus (25 s au plus). Les parties
-- en cours de lecture sont attendues (rendues aussitôt lues).
function Commande:fermer()
	self.ferme = true
	local restantes = 0
	for joueur in pairs(self.ateliers) do
		restantes += 1
		task.spawn(function()
			self:enregistrer(joueur, true, Commande.ESSAIS_ECRITURE)
			restantes -= 1
		end)
	end
	local debut = self.horloge()
	while (restantes > 0 or next(self.chargements) ~= nil) and self.horloge() - debut < Commande.FERMETURE_MAX do
		self.attendre(0.5)
	end
end

-- L'état envoyé au client : tout, sauf les anciennes robes (seule la plus récente est en vitrine)
function Commande.instantane(etat)
	return etat:exporter(1)
end

-- Une action d'un joueur. Ne lève jamais d'erreur : une erreur imprévue devient un refus.
function Commande:traiter(joueur, action, ...)
	local faire = type(action) == "string" and ACTIONS[action]
	if not faire then
		return refus("Action inconnue.")
	end
	if not SANS_LIMITE[action] and not self.limiteur:autoriser(joueur) then
		return refus("Doucement !", true)
	end
	local a = self:atelier(joueur)
	if not a then
		return { ok = false, erreur = PREPARATION, attente = true, passager = true }
	end
	local ok, reponse = pcall(function(...)
		local r = faire(a, ...)
		-- Acceptée ou refusée par les règles, la réponse emporte l'état : le client répare ainsi sa copie
		-- (réponse perdue, partie lue après son arrivée). Les relevés de couture, que rien ne limite,
		-- ne l'emportent sur un refus que dans la limite des appels.
		if r.ok or not SANS_LIMITE[action] or self.limiteur:autoriser(joueur) then
			r.etat = Commande.instantane(a.etat)
		end
		return r
	end, ...)
	if not ok then
		warn(("[Atelier] %s : erreur dans « %s » : %s"):format(joueur.Name, action, tostring(reponse)))
		-- L'action a pu être faite avant l'erreur : refus passager, et le client redemandera l'état
		return { ok = false, erreur = "Action impossible.", passager = true, resynchroniser = true }
	end
	if reponse.ok then
		if action == "etat" and self.sauvegarde and not a.sauvable then
			reponse.avertissement = SANS_SAUVEGARDE
		elseif (action == "livrer" and reponse.reussie) or action == "vendre" or action == "offrir" then
			self:exposer(joueur) -- la robe livrée (ou vendue, ou offerte) part en vitrine
		end
	end
	return reponse
end

return Commande
