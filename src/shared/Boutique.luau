-- Boutique : le plan d'une boutique de la rue, en coordonnées locales (le repère de la boutique). Partagé :
-- le serveur la construit à son emplacement, le client y place le mannequin, la caméra et la cliente.
-- Dans ce repère, la façade (sur la rue) est vers −Z, et le mannequin de travail regarde −Z.
local dossier = script.Parent
local Catalogue = require(dossier:WaitForChild("Catalogue"))
local Mannequin = require(dossier:WaitForChild("Mannequin"))

local Boutique = {}
Boutique.NOMBRE = 8 -- emplacements dans la rue (spec §2 ; le serveur est limité à 8 joueurs)
Boutique.LARGEUR = 24 -- studs : x de −12 à 12
Boutique.AVANT, Boutique.FOND = 30, 58 -- z de la façade et du mur du fond
Boutique.HAUTEUR = 12
Boutique.PORTE = { -9, -3 } -- x de l'ouverture de la porte, dans la façade
Boutique.FENETRE = { 4, 11 } -- x de la fenêtre de la vitrine, dans la façade
Boutique.DEMI_RUE = 10 -- studs entre le milieu de la rue et chaque rangée de façades
local X_EMPLACEMENTS = { -45, -15, 15, 45 }

-- Le mannequin de travail (le cadre de la robe : sa taille est à la hauteur de la taille du mannequin)
Boutique.MANNEQUIN = CFrame.new(0, Mannequin.HAUTEUR_TAILLE * Catalogue.STUDS_PAR_DM, 40)
-- Le socle de la vitrine, juste derrière la fenêtre : la robe exposée regarde la rue
Boutique.VITRINE = CFrame.new(7.5, 0.5, 32.5)
-- Là où l'avatar du joueur apparaît : juste passé la porte, tourné vers l'atelier
Boutique.ENTREE = CFrame.lookAt(Vector3.new(-6, 3, 33), Vector3.new(-6, 3, 40))

-- Rue pleine (plus de 8 joueurs : régler Max Players à 8 dans les paramètres du jeu) : l'atelier du joueur
-- sans boutique se place derrière une rangée, hors de la rue et de toute boutique
Boutique.HORS_RUE = CFrame.new(0, 0, 45)

-- Repère de la boutique i (1 à 4 : d'un côté de la rue, 5 à 8 : en face, tournées d'un demi-tour)
function Boutique.emplacement(i)
	assert(type(i) == "number" and i == math.floor(i) and i >= 1 and i <= Boutique.NOMBRE, "emplacement inconnu : " .. tostring(i))
	local x = X_EMPLACEMENTS[(i - 1) % 4 + 1]
	if i <= 4 then
		return CFrame.new(x, 0, Boutique.DEMI_RUE - Boutique.AVANT)
	end
	return CFrame.new(x, 0, Boutique.AVANT - Boutique.DEMI_RUE) * CFrame.Angles(0, math.pi, 0)
end

return Boutique
