-- Session : accès de l'interface à l'état de l'atelier.
-- Plan 3 : l'état vit dans le client (EtatAtelier en local). Plan 4 : même interface, mais chaque
-- action passe par le serveur. Les écrans ne parlent qu'à la Session, jamais à EtatAtelier directement.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Couture = ReplicatedStorage:WaitForChild("Couture")
local EtatAtelier = require(Couture:WaitForChild("EtatAtelier"))

local Session = {}
Session.__index = Session

-- graine : pour des commandes reproductibles (tests) ; sinon aléatoire
function Session.nouvelle(graine)
	local self = setmetatable({ etat = EtatAtelier.nouveau(), rng = Random.new(graine), ecouteurs = {}, derniere = nil }, Session)
	Session.courante = self -- la session du joueur (tests du scénario, débogage dans Studio)
	return self
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
	local reponse = self.etat[nom](self.etat, ...)
	if reponse.ok then
		self.derniere = { action = nom, reponse = reponse }
		for _, f in ipairs(table.clone(self.ecouteurs)) do
			f(self.etat)
		end
	end
	return reponse
end

function Session:nouvelleCommande()
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
