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

local INJOIGNABLE = "Le serveur ne répond pas. Réessaie."

-- Session locale ; graine : pour des commandes reproductibles (tests) ; sinon aléatoire
function Session.nouvelle(graine)
	local self = setmetatable({ etat = EtatAtelier.nouveau(), rng = Random.new(graine), ecouteurs = {}, derniere = nil }, Session)
	Session.courante = self -- la session du joueur (tests du scénario, débogage dans Studio)
	return self
end

-- Session distante (le jeu) : remote = la RemoteFunction « Atelier » du serveur. Attend l'état du serveur.
-- rng ne sert qu'au client (mouvement du tissu à la machine à coudre) : le serveur tire ses commandes.
function Session.distante(remote)
	local self = setmetatable({ etat = EtatAtelier.nouveau(), remote = remote, rng = Random.new(), ecouteurs = {}, derniere = nil, enCours = false }, Session)
	Session.courante = self
	self:actualiser()
	return self
end

-- Appel au serveur, sans jamais lever d'erreur
local function appeler(self, nom, ...)
	local ok, reponse = pcall(self.remote.InvokeServer, self.remote, nom, ...)
	if not ok or type(reponse) ~= "table" then
		return { ok = false, erreur = INJOIGNABLE }
	end
	if reponse.ok and type(reponse.etat) == "table" then
		self.etat:charger(reponse.etat)
	end
	return reponse
end

-- Reprend l'état du serveur (à l'arrivée, ou pour réparer une copie abîmée)
function Session:actualiser()
	if self.remote then
		return appeler(self, "etat")
	end
	return { ok = true }
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

-- derniere = { action, reponse } de la dernière action réussie (l'accueil affiche la dernière livraison)
local function agir(self, nom, ...)
	local reponse
	if self.remote then
		if self.enCours then
			return { ok = false, erreur = "Un instant…" } -- une action à la fois (second appui pendant l'attente)
		end
		self.enCours = true
		reponse = appeler(self, nom, ...)
		self.enCours = false
	else
		reponse = self.etat[nom](self.etat, ...)
	end
	if reponse.ok then
		self.derniere = { action = nom, reponse = reponse }
		for _, f in ipairs(table.clone(self.ecouteurs)) do
			f(self.etat)
		end
	end
	return reponse
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
