-- Commande (serveur) : l'atelier de chaque joueur, qui fait foi (spec §2). Chaque action du client
-- passe par Commande:traiter : action connue, limite d'appels, règles d'EtatAtelier. Une réponse
-- acceptée emporte l'état (EtatAtelier:exporter), que le client recharge et affiche.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Couture = ReplicatedStorage:WaitForChild("Couture")
local EtatAtelier = require(Couture:WaitForChild("EtatAtelier"))
local Limiteur = require(script.Parent:WaitForChild("Limiteur"))

local Commande = {}
Commande.__index = Commande

Commande.APPELS_PAR_SECONDE = 5 -- par joueur (spec §6)
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

function Commande.nouvelle()
	local self = setmetatable({
		ateliers = {}, -- [joueur] = { etat = EtatAtelier, rng = Random }
		limiteur = Limiteur.nouveau(Commande.APPELS_PAR_SECONDE, 1),
	}, Commande)
	Commande.courante = self -- le serveur en cours (tests du scénario, débogage dans Studio)
	return self
end

-- L'atelier d'un joueur, créé à son premier appel (la sauvegarde le chargera au plan 4b)
function Commande:atelier(joueur)
	local a = self.ateliers[joueur]
	if not a then
		a = { etat = EtatAtelier.nouveau(), rng = Random.new() }
		self.ateliers[joueur] = a
	end
	return a
end

-- Départ du joueur : son atelier est libéré
function Commande:retirer(joueur)
	self.ateliers[joueur] = nil
	self.limiteur:oublier(joueur)
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
	local ok, reponse = pcall(faire, a, ...)
	if not ok then
		warn(("[Atelier] %s : erreur dans « %s » : %s"):format(joueur.Name, action, tostring(reponse)))
		return refus("Action impossible.")
	end
	if reponse.ok then
		reponse.etat = Commande.instantane(a.etat)
	end
	return reponse
end

return Commande
