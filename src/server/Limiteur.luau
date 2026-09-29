-- Limiteur : au plus « max » appels par fenêtre glissante de « fenetre » secondes, pour chaque clé
-- (un joueur). Protège le serveur des rafales d'appels (spec §6).
local Limiteur = {}
Limiteur.__index = Limiteur

function Limiteur.nouveau(max, fenetre)
	return setmetatable({ max = max, fenetre = fenetre, appels = {} }, Limiteur)
end

-- Vrai si l'appel est permis (il est alors compté), faux s'il y en a déjà trop dans la fenêtre
function Limiteur:autoriser(cle)
	local maintenant = os.clock()
	local recents = {}
	for _, t in ipairs(self.appels[cle] or {}) do
		if maintenant - t < self.fenetre then
			table.insert(recents, t)
		end
	end
	local permis = #recents < self.max
	if permis then
		table.insert(recents, maintenant)
	end
	self.appels[cle] = recents
	return permis
end

function Limiteur:oublier(cle)
	self.appels[cle] = nil
end

return Limiteur
