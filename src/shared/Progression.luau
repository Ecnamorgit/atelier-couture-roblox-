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

-- Robes libres (sous-projet 2) : une robe vendue rapporte du prestige (prix / 15) ; son prix monte de 6 % par
-- niveau de prestige au-delà du premier (+42 % au niveau 8)
Progression.BONUS_VENTE = 0.06
function Progression.bonusVente(niveauPrestige)
	return Progression.BONUS_VENTE * (niveauPrestige - 1)
end
function Progression.prestigeVente(prix)
	return math.round(prix / 15)
end

-- Une commande venue par lettre, livrée et acceptée : un point d'amitié de plus
Progression.BONUS_LETTRE = 1

-- Une robe offerte : +2 de prestige, et de l'amitié selon le score de son style préféré le plus haut
-- (moins de 30 : +1 ; 30 à 59 : +2 ; 60 à 79 : +3 ; 80 et plus : +4)
Progression.PRESTIGE_CADEAU = 2
function Progression.gainCadeau(score)
	return if score >= 80 then 4 elseif score >= 60 then 3 elseif score >= 30 then 2 else 1
end

-- Sous-projet 5 : l'avis de la cliente en étoiles, les titres de la réputation, le rang de la couturière. Aucune
-- règle n'en dépend : c'est ce que la livraison disait déjà, montré comme dans les jeux de couture.
-- Étoiles (1 à 5) : robe refusée, une ; acceptée, deux, et une de plus à chaque palier de qualité (80 % est aussi
-- le palier du point d'amitié de plus)
Progression.PALIERS_ETOILES = { 0.6, Progression.QUALITE_BONUS, 0.9 }
function Progression.etoiles(reussie, qualite)
	if not reussie then
		return 1
	end
	local n = 2
	for _, palier in ipairs(Progression.PALIERS_ETOILES) do
		if qualite >= palier - 1e-9 then -- (à l'arrondi près)
			n += 1
		end
	end
	return n
end

-- Titres de la réputation, un par niveau de prestige (1 à 8)
Progression.TITRES_REPUTATION = { "Inconnue", "Remarquée", "Appréciée", "Renommée", "Réputée", "Célèbre", "Illustre", "Légendaire" }
function Progression.titreReputation(niveauPrestige)
	return Progression.TITRES_REPUTATION[math.clamp(niveauPrestige, 1, #Progression.TITRES_REPUTATION)]
end

-- Rang de la couturière selon ses robes livrées ou vendues : le rang atteint, et le suivant (nil au plus haut)
Progression.RANGS = {
	{ robes = 0, nom = "Débutante" },
	{ robes = 5, nom = "Apprentie" },
	{ robes = 15, nom = "Couturière" },
	{ robes = 30, nom = "Première main" },
	{ robes = 60, nom = "Maîtresse couturière" },
}
function Progression.rang(robes)
	local atteint, suivant = Progression.RANGS[1], Progression.RANGS[2]
	for i, r in ipairs(Progression.RANGS) do
		if robes >= r.robes then
			atteint, suivant = r, Progression.RANGS[i + 1]
		end
	end
	return atteint, suivant
end

-- « Apprentie — 7 robes (Couturière à 15) » ; au plus haut, sans le rang suivant
function Progression.texteRang(robes)
	local rang, suivant = Progression.rang(robes)
	local texte = ("%s — %d robe%s"):format(rang.nom, robes, if robes > 1 then "s" else "")
	return if suivant then ("%s (%s à %d)"):format(texte, suivant.nom, suivant.robes) else texte
end

return Progression
