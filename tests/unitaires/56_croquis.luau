-- Le croquis du carnet (sous-projet 5) : la robe dessinée de face, variante par variante
local Croquis = U.module("Croquis")
local Catalogue = U.module("Catalogue")
local Polygone = U.module("Polygone")

-- Chaque variante du catalogue a sa forme, dans le dessin ; les corsages finissent à la taille, les jupes en
-- partent
for _, v in ipairs(Catalogue.Variantes) do
	local forme = Croquis.FORMES[v.id]
	U.verifier(forme ~= nil and Croquis.connue(v.id), v.id .. " : une forme dans le croquis")
	local dedans = true
	for _, polygone in ipairs(forme and forme.parties or {}) do
		local b = Polygone.boite(polygone)
		dedans = dedans and b.minX >= 0 and b.maxX <= Croquis.LARGEUR and b.minY >= 0 and b.maxY <= Croquis.HAUTEUR
		if v.famille == "jupe" then
			U.verifier(U.proche(b.minY, Croquis.TAILLE), v.id .. " : la jupe part de la taille")
		elseif v.famille == "corsage" then
			U.verifier(U.proche(b.maxY, Croquis.TAILLE), v.id .. " : le corsage finit à la taille")
		end
	end
	U.verifier(dedans, v.id .. " : la forme tient dans le dessin")
	local pieces = #v.pieces > 0
	U.verifier((#(forme and forme.parties or {}) > 0) == pieces, v.id .. " : dessinée si elle a des pièces (« sans » : rien)")
end

-- Les parties dans l'ordre de dessin : jupe, corsage, manches (deux, en miroir), col
local base = { corsage = "corsage_droit", manches = "manches_sans", col = "col_sans", jupe = "jupe_droite" }
local parties = Croquis.parties(base)
U.verifier(#parties == 2 and parties[1].famille == "jupe" and parties[2].famille == "corsage", "robe simple : la jupe puis le corsage")
local habillee = { corsage = "corsage_v", manches = "manches_ballon", col = "col_claudine", jupe = "jupe_ample" }
parties = Croquis.parties(habillee)
local familles = {}
for _, p in ipairs(parties) do
	table.insert(familles, p.famille)
end
U.verifier(table.concat(familles, ",") == "jupe,corsage,manches,manches,col,col", "manches et col en deux moitiés, dessinés par-dessus (" .. table.concat(familles, ",") .. ")")
local gauche, droite = Polygone.boite(parties[3].polygone), Polygone.boite(parties[4].polygone)
U.verifier(U.proche(gauche.minX, Croquis.LARGEUR - droite.maxX) and gauche.maxX <= Croquis.LARGEUR / 2 and droite.minX >= Croquis.LARGEUR / 2, "les deux manches se répondent en miroir")
U.verifier(#Croquis.details(habillee) == 3 and #Croquis.details(base) == 0, "les fronces de la jupe ample en traits de crayon")

-- Toucher le dessin : la partie sous le doigt
U.verifier(Croquis.partieA(base, 50, 60) == "jupe" and Croquis.partieA(base, 50, 32) == "corsage", "toucher la jupe, le corsage")
U.verifier(Croquis.partieA(base, 25, 25) == nil and Croquis.partieA(base, 5, 5) == nil, "sans manches : rien sur les côtés ; hors de la robe : rien")
U.verifier(Croquis.partieA(habillee, 27, 24) == "manches" and Croquis.partieA(habillee, 73, 24) == "manches", "toucher une manche, à gauche comme à droite")
U.verifier(Croquis.partieA(habillee, 43, 18) == "col" and Croquis.partieA(habillee, 57, 18) == "col", "toucher le col Claudine : il est dessus")
U.verifier(Croquis.partieA({ corsage = "corsage_droit", manches = "manches_sans", col = "col_sans", jupe = "jupe_evasee" }, 50, 120) == "jupe" and Croquis.partieA(base, 50, 120) == nil, "la jupe longue descend à la cheville, la droite s'arrête au genou")
