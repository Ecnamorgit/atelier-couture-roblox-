-- Session : accès de l'interface à l'état de l'atelier. Les écrans ne parlent qu'à la Session, jamais
-- à EtatAtelier directement.
-- Dans le jeu, la session est distante : chaque action passe par le serveur (RemoteFunction « Atelier »),
-- qui fait foi ; sa réponse emporte l'état, rechargé sur place. Une session locale (EtatAtelier dans le
-- client) sert aux tests des écrans.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Couture = ReplicatedStorage:WaitForChild("Couture")
local EtatAtelier = require(Couture:WaitForChild("EtatAtelier"))

local Session = {}
Session.__index = Session

-- Réponse perdue : le serveur a peut-être fait l'action ; on ne dit pas de la refaire, on vérifie d'abord
Session.INJOIGNABLE = "Le serveur n'a pas répondu : on vérifie où en est ton atelier…"
Session.VERIFICATION = "Un instant : on vérifie où en est ton atelier…" -- actions en attente de l'état
Session.OCCUPE = "Un instant…" -- une action à la fois : un appui pendant l'attente du serveur est refusé
Session.PAS_PRETE = "Ta partie n'est pas encore arrivée du serveur : elle apparaîtra à ta prochaine action."
Session.ESSAIS_ARRIVEE = 60 -- à l'arrivée, un essai par seconde tant que le serveur lit la partie (réessais du
-- DataStore et verrou tenu ailleurs compris)
Session.RESYNCHRO = 2 -- s : après une réponse perdue, l'état est redemandé au serveur

-- Session locale ; graine : pour des commandes reproductibles (tests) ; sinon aléatoire
function Session.nouvelle(graine)
	local self = setmetatable({ etat = EtatAtelier.nouveau(), rng = Random.new(graine), ecouteurs = {}, derniere = nil }, Session)
	Session.courante = self -- la session du joueur (tests du scénario, débogage dans Studio)
	return self
end

-- Session distante (le jeu) : remote = la RemoteFunction « Atelier » du serveur. Attend l'état du serveur,
-- le temps qu'il lise la partie du joueur (jusqu'à 15 s si un autre serveur la tenait). avertissement : un
-- message pour le joueur (sauvegarde impossible, partie pas encore arrivée), ou nil. attendre (tests) :
-- remplace task.wait.
-- rng ne sert qu'au client (mouvement du tissu à la machine à coudre) : le serveur tire ses commandes.
function Session.distante(remote, attendre)
	local self = setmetatable({ etat = EtatAtelier.nouveau(), remote = remote, rng = Random.new(), ecouteurs = {}, derniere = nil, enCours = false }, Session)
	Session.courante = self
	local reponse = self:actualiser()
	local essais = 1
	while not reponse.ok and reponse.attente and essais < Session.ESSAIS_ARRIVEE do
		(attendre or task.wait)(1)
		essais += 1
		reponse = self:actualiser()
	end
	-- Partie pas encore là (serveur injoignable ou trop long) : état de départ en attendant ; la première
	-- réponse du serveur, acceptée ou refusée, apportera la vraie partie
	self.avertissement = if reponse.ok then reponse.avertissement else Session.PAS_PRETE
	return self
end

-- Appel au serveur, sans jamais lever d'erreur. L'état joint à la réponse (acceptée ou refusée) est
-- rechargé. Renvoie la réponse, si l'état a changé, et si la réponse est perdue ou illisible (refus
-- passager : le serveur a pu agir sans que son état arrive). L'indicateur d'attente ne peut rien bloquer.
local function appeler(self, nom, ...)
	if self.attente then
		pcall(self.attente, true)
	end
	local ok, reponse = pcall(self.remote.InvokeServer, self.remote, nom, ...)
	if self.attente then
		pcall(self.attente, false)
	end
	local change = false
	if ok and type(reponse) == "table" and type(reponse.etat) == "table" then
		local lu, _, c = pcall(self.etat.charger, self.etat, reponse.etat)
		ok, change = lu, c == true
	end
	if not ok or type(reponse) ~= "table" then
		return { ok = false, erreur = Session.INJOIGNABLE, passager = true }, false, true
	end
	return reponse, change, reponse.resynchroniser == true
end

-- Prévient les écrans que l'état a changé
local function prevenir(self)
	for _, f in ipairs(table.clone(self.ecouteurs)) do
		f(self.etat)
	end
end

-- Une action (ou « etat ») : une à la fois. Les écrans sont prévenus après une action réussie, ou quand
-- l'état joint à une réponse a changé la copie du client. Réponse perdue (ou erreur du serveur, qui a pu
-- agir) : l'état est redemandé au serveur un peu plus tard, et les actions attendent jusque-là (rien
-- n'est fait deux fois).
-- derniere = { action, reponse } de la dernière action réussie (l'accueil affiche la dernière livraison)
local function agir(self, nom, ...)
	local reponse, change, perdue
	if self.remote then
		if self.enCours then
			return { ok = false, erreur = Session.OCCUPE, passager = true }
		end
		if self.resynchro and nom ~= "etat" then
			return { ok = false, erreur = Session.VERIFICATION, passager = true }
		end
		self.enCours = true
		reponse, change, perdue = appeler(self, nom, ...)
		self.enCours = false
	else
		reponse = self.etat[nom](self.etat, ...)
	end
	local action = reponse.ok and nom ~= "etat"
	if action then
		self.derniere = { action = nom, reponse = reponse }
		if self.annonce then
			pcall(self.annonce, nom, reponse) -- (sons de l'interface) : ne peut rien bloquer
		end
	end
	if action or change then
		prevenir(self)
	end
	if perdue and nom ~= "etat" and not self.resynchro then
		self.resynchro = true
		task.delay(Session.RESYNCHRO, function()
			self.resynchro = false
			self:actualiser()
		end)
	end
	return reponse
end

-- Reprend l'état du serveur (à l'arrivée, ou pour réparer une copie abîmée) ; prévient les écrans s'il a
-- changé
function Session:actualiser()
	if self.remote then
		return agir(self, "etat")
	end
	return { ok = true }
end

-- attente(actif) est appelée au début (vrai) et à la fin (faux) de chaque appel au serveur (indicateur)
function Session:surAttente(f)
	self.attente = f
end

-- f(nom, reponse) est appelée après chaque action réussie du joueur (sons de l'interface)
function Session:surAction(f)
	self.annonce = f
end

-- Appelle f(etat) après chaque action réussie ; renvoie une fonction pour se désabonner
function Session:surChangement(f)
	table.insert(self.ecouteurs, f)
	return function()
		local i = table.find(self.ecouteurs, f)
		if i then
			table.remove(self.ecouteurs, i)
		end
	end
end

function Session:nouvelleCommande()
	if self.remote then
		return agir(self, "nouvelleCommande") -- le serveur tire la commande
	end
	return agir(self, "nouvelleCommande", self.rng)
end
function Session:validerCroquis(croquis, tissus)
	return agir(self, "validerCroquis", croquis, tissus)
end
function Session:retourCarnet()
	return agir(self, "retourCarnet")
end
function Session:acheter(idTissu, dm)
	return agir(self, "acheter", idTissu, dm)
end
function Session:commencerDecoupe()
	return agir(self, "commencerDecoupe")
end
function Session:couper(idPiece, placement)
	return agir(self, "couper", idPiece, placement)
end
function Session:epingler(idPiece)
	return agir(self, "epingler", idPiece)
end
function Session:rendreCouture(idPiece, ecarts, duree, assistance)
	return agir(self, "rendreCouture", idPiece, ecarts, duree, assistance)
end
function Session:decorer(liste)
	return agir(self, "decorer", liste)
end
function Session:retourDecorations()
	return agir(self, "retourDecorations")
end
function Session:livrer()
	return agir(self, "livrer")
end
function Session:retoucher()
	return agir(self, "retoucher")
end
function Session:abandonner()
	return agir(self, "abandonner")
end
function Session:recommencer()
	return agir(self, "recommencer")
end

return Session
