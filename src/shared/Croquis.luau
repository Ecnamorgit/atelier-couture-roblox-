-- Croquis (sous-projet 5) : la robe dessinée de face dans le carnet, comme sur une page de carnet de couturière.
-- Chaque variante a sa forme vue de face : des polygones dans un repère de dessin de 100 unités de large et 130 de
-- haut (x vers la droite, y vers le bas), posés sur un gabarit commun : cou (y 8 à 14), épaules (y 17, x 34 et 66),
-- taille (y 42, x 39 à 61). Les formes « symétriques » sont dessinées à gauche et reprises en miroir à droite.
-- Données, et deux fonctions pures : les parties à dessiner, et la partie sous un point (toucher le dessin).
local dossier = script.Parent
local Catalogue = require(dossier:WaitForChild("Catalogue"))
local Polygone = require(dossier:WaitForChild("Polygone"))

local Croquis = {}
Croquis.LARGEUR, Croquis.HAUTEUR = 100, 130
Croquis.TAILLE = 42 -- hauteur de la taille : la jupe en part, le corsage y finit
Croquis.ORDRE = { "jupe", "corsage", "manches", "col" } -- ordre de dessin (le dernier est dessus)

local function P(liste)
	local points = {}
	for i = 1, #liste, 2 do
		table.insert(points, { x = liste[i], y = liste[i + 1] })
	end
	return points
end

-- Sous-projet 7 : une partie qui porte ses pièces (un volant, une basque) prend leur tissu, et la toucher choisit le
-- tissu de ces pièces seulement ; sans pièces, une partie prend le tissu de la première pièce de la variante
local function avecPieces(pieces, polygone)
	polygone.pieces = pieces
	return polygone
end

-- FORMES[idVariante] = { parties = { polygone, ... }, symetrique = bool, details = { { a, b }, ... } }
-- (details : traits de crayon sur la pièce, plis ou croisé ; repris en miroir si la forme est symétrique)
local FORMES = {
	-- Corsages : des épaules à la taille
	corsage_droit = { parties = { P({ 34, 17, 41, 17, 42, 22, 58, 22, 59, 17, 66, 17, 67, 24, 65, 32, 61, 42, 39, 42, 35, 32, 33, 24 }) } },
	corsage_v = { parties = { P({ 34, 17, 43, 17, 50, 31, 57, 17, 66, 17, 67, 24, 65, 32, 61, 42, 39, 42, 35, 32, 33, 24 }) } },
	corsage_bretelles = { parties = { P({ 37, 16, 40, 16, 41, 24, 59, 24, 60, 16, 63, 16, 66, 26, 65, 32, 61, 42, 39, 42, 35, 32, 34, 26 }) } },
	corsage_cache_coeur = {
		parties = { P({ 34, 17, 42, 17, 55, 33, 58, 17, 66, 17, 67, 24, 65, 32, 61, 42, 39, 42, 35, 32, 33, 24 }) },
		details = { { { x = 58, y = 17 }, { x = 44, y = 40 } } }, -- le pan croisé
	},
	corsage_bustier = { parties = { P({ 34, 27, 42, 23, 50, 27, 58, 23, 66, 27, 65, 32, 61, 42, 39, 42, 35, 32 }) } },
	-- Manches : parties de l'épaule gauche (reprises en miroir)
	manches_sans = { parties = {} },
	manches_ballon = { symetrique = true, parties = { P({ 34, 17, 29, 17, 25, 21, 24, 27, 28, 31, 34, 29, 35, 24 }) } },
	manches_longues = { symetrique = true, parties = { P({ 34, 17, 30, 18, 26, 30, 22, 52, 27, 53, 31, 34, 34, 25 }) } },
	manches_courtes = { symetrique = true, parties = { P({ 34, 17, 29, 18, 26, 26, 27, 30, 33, 29, 34, 24 }) } },
	manches_trois_quarts = { symetrique = true, parties = { P({ 34, 17, 30, 18, 26, 30, 23, 42, 28, 43, 31, 32, 34, 25 }) } },
	-- Cols : autour du cou
	col_sans = { parties = {} },
	col_claudine = { symetrique = true, parties = { P({ 46, 13, 41, 15, 39, 19, 42, 22, 47, 21, 50, 16 }) } },
	col_montant = { parties = { P({ 45, 9, 55, 9, 56, 15, 44, 15 }) } },
	col_marin = { symetrique = true, parties = { P({ 46, 13, 37, 16, 39, 22, 50, 32 }) } },
	-- Jupes : de la taille à l'ourlet
	jupe_droite = { parties = { P({ 39, 42, 61, 42, 64, 82, 36, 82 }) } },
	jupe_trapeze = { parties = { P({ 39, 42, 61, 42, 71, 84, 29, 84 }) } },
	jupe_ample = {
		parties = { P({ 39, 42, 61, 42, 68, 52, 77, 88, 23, 88, 32, 52 }) },
		details = { -- les fronces
			{ { x = 45, y = 46 }, { x = 38, y = 87 } },
			{ { x = 50, y = 46 }, { x = 50, y = 88 } },
			{ { x = 55, y = 46 }, { x = 62, y = 87 } },
		},
	},
	jupe_evasee = { parties = { P({ 39, 42, 61, 42, 66, 60, 81, 124, 19, 124, 34, 60 }) } },
	jupe_crayon = { parties = { P({ 39, 42, 61, 42, 63, 52, 61, 84, 39, 84, 37, 52 }) } },
	-- Sous-projet 7 : des couches, dessinées par-dessus (un volant sous la jupe droite, une basque sous le corsage droit)
	corsage_basque = {
		parties = {
			P({ 34, 17, 41, 17, 42, 22, 58, 22, 59, 17, 66, 17, 67, 24, 65, 32, 61, 42, 39, 42, 35, 32, 33, 24 }),
			avecPieces({ "basque_devant", "basque_dos" }, P({ 39, 42, 61, 42, 67, 50, 33, 50 })),
		},
	},
	jupe_volant = {
		parties = {
			P({ 39, 42, 61, 42, 64, 82, 36, 82 }),
			avecPieces({ "volant_devant", "volant_dos" }, P({ 36, 75, 64, 75, 69, 86, 31, 86 })),
		},
		details = { -- les fronces du volant
			{ { x = 40, y = 77 }, { x = 37, y = 85 } },
			{ { x = 45, y = 77 }, { x = 44, y = 85 } },
			{ { x = 50, y = 77 }, { x = 50, y = 85 } },
			{ { x = 55, y = 77 }, { x = 56, y = 85 } },
			{ { x = 60, y = 77 }, { x = 63, y = 85 } },
		},
	},
	-- Plan 23 : l'étage froncé sur le bas de la jupe droite ; le jupon qui dépasse sous la jupe de dessus (dessiné
	-- dessous) ; la ceinture à la taille, par-dessus le corsage
	jupe_etages = {
		parties = {
			P({ 39, 42, 61, 42, 64, 82, 36, 82 }),
			avecPieces({ "etage_devant", "etage_dos" }, P({ 37, 62, 63, 62, 70, 86, 30, 86 })),
		},
		details = { -- les fronces de l'étage
			{ { x = 42, y = 64 }, { x = 37, y = 85 } },
			{ { x = 50, y = 64 }, { x = 50, y = 85 } },
			{ { x = 58, y = 64 }, { x = 63, y = 85 } },
		},
	},
	jupe_jupon = {
		parties = {
			avecPieces({ "jupon_devant", "jupon_dos" }, P({ 30, 76, 70, 76, 73, 87, 27, 87 })),
			P({ 39, 42, 61, 42, 71, 82, 29, 82 }),
		},
	},
	-- La traîne dépasse derrière l'ourlet de la jupe longue (dessinée dessous)
	jupe_traine = {
		parties = {
			avecPieces({ "traine_dos" }, P({ 19, 118, 81, 118, 88, 128, 12, 128 })),
			P({ 39, 42, 61, 42, 66, 60, 81, 124, 19, 124, 34, 60 }),
		},
	},
	corsage_ceinture = {
		parties = {
			P({ 34, 17, 41, 17, 42, 22, 58, 22, 59, 17, 66, 17, 67, 24, 65, 32, 61, 42, 39, 42, 35, 32, 33, 24 }),
			avecPieces({ "ceinture_devant", "ceinture_dos" }, P({ 38, 38, 62, 38, 61, 42, 39, 42 })),
		},
	},
}
Croquis.FORMES = FORMES

-- Le mannequin esquissé derrière la robe (traits gris clair) : tête, cou, buste, pied, trépied
Croquis.MANNEQUIN = {
	{ { x = 48, y = 2 }, { x = 52, y = 2 } },
	{ { x = 47, y = 5 }, { x = 47, y = 14 } },
	{ { x = 53, y = 5 }, { x = 53, y = 14 } },
	{ { x = 47, y = 14 }, { x = 34, y = 17 } },
	{ { x = 53, y = 14 }, { x = 66, y = 17 } },
	{ { x = 34, y = 17 }, { x = 34, y = 30 } },
	{ { x = 66, y = 17 }, { x = 66, y = 30 } },
	{ { x = 34, y = 30 }, { x = 39, y = 42 } },
	{ { x = 66, y = 30 }, { x = 61, y = 42 } },
	{ { x = 39, y = 42 }, { x = 35, y = 54 } },
	{ { x = 61, y = 42 }, { x = 65, y = 54 } },
	{ { x = 35, y = 54 }, { x = 65, y = 54 } },
	{ { x = 50, y = 54 }, { x = 50, y = 122 } },
	{ { x = 50, y = 122 }, { x = 40, y = 128 } },
	{ { x = 50, y = 122 }, { x = 60, y = 128 } },
}

local function miroirSegment(s)
	return { { x = Croquis.LARGEUR - s[1].x, y = s[1].y }, { x = Croquis.LARGEUR - s[2].x, y = s[2].y } }
end

-- Parties à dessiner pour un croquis { corsage, manches, col, jupe }, dans l'ordre de dessin :
-- { { famille, polygone, pieces? } } (une manche ou un rabat de col symétrique donne deux parties ; pieces : celles
-- d'une partie qui porte les siennes)
function Croquis.parties(croquis)
	local out = {}
	for _, famille in ipairs(Croquis.ORDRE) do
		local forme = FORMES[croquis[famille]]
		assert(forme, "forme de croquis inconnue : " .. tostring(croquis[famille]))
		for _, polygone in ipairs(forme.parties) do
			table.insert(out, { famille = famille, polygone = polygone, pieces = polygone.pieces })
			if forme.symetrique then
				table.insert(out, { famille = famille, polygone = Polygone.miroir(polygone, Croquis.LARGEUR / 2), pieces = polygone.pieces })
			end
		end
	end
	return out
end

-- Traits de détail (plis, croisé) du croquis : { { a, b, famille } }
function Croquis.details(croquis)
	local out = {}
	for _, famille in ipairs(Croquis.ORDRE) do
		local forme = FORMES[croquis[famille]]
		for _, s in ipairs(forme.details or {}) do
			-- chaque trait sait à quelle partie il appartient : il ne se trace que sur elle
			table.insert(out, { s[1], s[2], famille = famille })
			if forme.symetrique then
				local m = miroirSegment(s)
				table.insert(out, { m[1], m[2], famille = famille })
			end
		end
	end
	return out
end

-- La famille dessinée sous le point (x, y) du dessin (la plus haute dans l'ordre de dessin), ou nil ; et les pièces de
-- cette partie : les siennes (un volant), sinon celles de la variante moins celles d'une autre partie (toucher la jupe
-- ne change pas le tissu de son volant)
function Croquis.partieA(croquis, x, y)
	local parties = Croquis.parties(croquis)
	for i = #parties, 1, -1 do
		if Polygone.contient(parties[i].polygone, x, y) then
			local p = parties[i]
			if p.pieces then
				return p.famille, p.pieces
			end
			local portees = {}
			for _, autre in ipairs(parties) do
				if autre.famille == p.famille and autre.pieces then
					for _, id in ipairs(autre.pieces) do
						portees[id] = true
					end
				end
			end
			local pieces = {}
			for _, id in ipairs(Catalogue.variante(croquis[p.famille]).pieces) do
				if not portees[id] then
					table.insert(pieces, id)
				end
			end
			return p.famille, pieces
		end
	end
	return nil
end

-- Chaque variante du catalogue a sa forme (vérifié par les tests) ; utile au chargement des écrans
function Croquis.connue(idVariante)
	return FORMES[idVariante] ~= nil and Catalogue.variante(idVariante) ~= nil
end

return Croquis
