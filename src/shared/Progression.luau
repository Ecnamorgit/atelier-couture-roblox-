-- Progression : l'amitié de chaque cliente et le prestige du joueur (sous-projet 2) : seuils, niveaux, gains.
local Progression = {}

Progression.SEUILS_AMITIE = { 0, 3, 7, 12, 18, 25 } -- points pour les niveaux d'amitié 0 à 5
Progression.SEUILS_PRESTIGE = { 0, 20, 50, 100, 170, 260, 380, 530 } -- points pour les niveaux de prestige 1 à 8
Progression.QUALITE_BONUS = 0.8 -- une robe au moins aussi bonne vaut un point d'amitié de plus

-- Le niveau atteint avec ces points (seuils croissants ; le premier seuil donne le niveau « premier »)
local function niveau(points, seuils, premier)
	local n = premier
	for i, seuil in ipairs(seuils) do
		if points >= seuil then
			n = premier + i - 1
		end
	end
	return n
end

function Progression.niveauAmitie(points)
	return niveau(points, Progression.SEUILS_AMITIE, 0)
end

function Progression.niveauPrestige(points)
	return niveau(points, Progression.SEUILS_PRESTIGE, 1)
end

-- Points d'amitié d'une commande : robe acceptée +2 (+1 si sa qualité atteint 80 %), abandonnée −1
function Progression.gainAmitie(reussie, qualite)
	if reussie then
		return 2 + (qualite >= Progression.QUALITE_BONUS - 1e-9 and 1 or 0) -- (à l'arrondi près)
	end
	return -1
end

-- Points de prestige d'une robe livrée et payée
function Progression.prestigeLivraison(paie)
	return math.round(paie / 10)
end

return Progression
