local Boutique = U.module("Boutique")
local Mannequin = U.module("Mannequin")
local Catalogue = U.module("Catalogue")

-- Un point local de la boutique est-il à l'intérieur de ses murs ?
local function dedans(p)
	return math.abs(p.X) < Boutique.LARGEUR / 2 and p.Z > Boutique.AVANT and p.Z < Boutique.FOND and p.Y >= 0 and p.Y < Boutique.HAUTEUR
end

---------------------------------------------------------------------------
-- La rue : 8 emplacements, quatre de chaque côté, façades tournées vers la rue
---------------------------------------------------------------------------
U.verifier(Boutique.NOMBRE == 8, "8 emplacements (spec §2)")
local coins = {}
for i = 1, Boutique.NOMBRE do
	local o = Boutique.emplacement(i)
	-- Les quatre coins au sol de la boutique, dans le monde
	local c = {}
	for _, x in ipairs({ -Boutique.LARGEUR / 2, Boutique.LARGEUR / 2 }) do
		for _, z in ipairs({ Boutique.AVANT, Boutique.FOND }) do
			table.insert(c, (o * CFrame.new(x, 0, z)).Position)
		end
	end
	coins[i] = c
	local facade = (o * CFrame.new(0, 0, Boutique.AVANT)).Position
	local dehors = (o * CFrame.new(0, 0, Boutique.AVANT - 1)).Position
	U.verifier(math.abs(math.abs(facade.Z) - Boutique.DEMI_RUE) < 1e-6, "façade " .. i .. " au bord de la rue")
	U.verifier(math.abs(dehors.Z) < math.abs(facade.Z), "façade " .. i .. " tournée vers la rue")
	U.verifier(math.abs(o.Position.Y) < 1e-9 and math.abs(o.UpVector.Y - 1) < 1e-9, "boutique " .. i .. " posée à plat, au niveau du sol")
end
-- Pas deux boutiques l'une sur l'autre (boîtes au sol disjointes)
local function boite(c)
	local b = { minX = math.huge, maxX = -math.huge, minZ = math.huge, maxZ = -math.huge }
	for _, p in ipairs(c) do
		b.minX, b.maxX = math.min(b.minX, p.X), math.max(b.maxX, p.X)
		b.minZ, b.maxZ = math.min(b.minZ, p.Z), math.max(b.maxZ, p.Z)
	end
	return b
end
local separees = true
for i = 1, Boutique.NOMBRE do
	for j = i + 1, Boutique.NOMBRE do
		local a, b = boite(coins[i]), boite(coins[j])
		if a.minX < b.maxX and b.minX < a.maxX and a.minZ < b.maxZ and b.minZ < a.maxZ then
			separees = false
		end
	end
end
U.verifier(separees, "aucune boutique ne chevauche une autre")
local ok = pcall(Boutique.emplacement, Boutique.NOMBRE + 1)
U.verifier(not ok, "pas de neuvième emplacement")

---------------------------------------------------------------------------
-- L'intérieur : mannequin, vitrine et entrée à leur place
---------------------------------------------------------------------------
U.verifier(dedans(Boutique.MANNEQUIN.Position) and math.abs(Boutique.MANNEQUIN.Position.Y - Mannequin.HAUTEUR_TAILLE * Catalogue.STUDS_PAR_DM) < 1e-9, "mannequin de travail dans la boutique, à la hauteur de la taille")
U.verifier(dedans(Boutique.VITRINE.Position) and Boutique.VITRINE.Position.Z - Boutique.AVANT < 4, "vitrine juste derrière la façade")
U.verifier(Boutique.VITRINE.LookVector.Z < -0.99, "la vitrine donne sur la rue (la robe exposée regarde l'avant du socle, −Z)")
local v = Boutique.VITRINE.Position
U.verifier(v.X - 2 >= Boutique.FENETRE[1] and v.X + 2 <= Boutique.FENETRE[2], "la vitrine est derrière la fenêtre de la façade")
U.verifier(dedans(Boutique.ENTREE.Position) and Boutique.ENTREE.Position.X >= Boutique.PORTE[1] and Boutique.ENTREE.Position.X <= Boutique.PORTE[2], "on entre par la porte")
U.verifier(Boutique.PORTE[2] < Boutique.FENETRE[1], "porte et fenêtre côte à côte, sans se chevaucher")
