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
		if polygone.pieces then
			-- (sous-projet 7) une couche qui porte ses pièces, sous la taille : une basque en part, un volant plus bas
			U.verifier(b.minY >= Croquis.TAILLE - 1e-9, v.id .. " : sa couche est sous la taille")
		elseif v.famille == "jupe" then
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

-- Le dessin peint (Pixels.croquis) : transparent hors de la robe, blanc sans tissu, la couleur d'un tissu uni,
-- un trait de crayon au bord, le mannequin esquissé sous la robe
local Pixels = U.module("Pixels")
local L, H = 200, 260
local buf, l, h = Pixels.croquis(base, {}, L, H)
local function pixel(x, y)
	local i, j = math.floor(x / Croquis.LARGEUR * L), math.floor(y / Croquis.HAUTEUR * H)
	local v = buffer.readu32(buf, (j * L + i) * 4)
	return v % 256, math.floor(v / 256) % 256, math.floor(v / 65536) % 256, math.floor(v / 16777216)
end
U.verifier(l == L and h == H and buffer.len(buf) == L * H * 4, "une image de la taille demandée")
local _, _, _, a = pixel(5, 5)
U.verifier(a == 0, "hors de la robe : transparent (le papier du carnet est derrière)")
local r, g, b, a2 = pixel(50, 62)
U.verifier(a2 == 255 and r >= 245 and g >= 245 and b >= 240, "une partie sans tissu est blanche")
local _, _, _, a3 = pixel(50, 100)
U.verifier(a3 > 0 and a3 < 255, "le pied du mannequin esquissé sous la jupe courte, en gris léger")
local uni
for _, t in ipairs(Catalogue.Tissus) do
	if t.motif.type == "uni" and t.motif.couleurs[1][1] < 200 then
		uni = t
		break
	end
end
buf = Pixels.croquis(base, { jupe = uni.id }, L, H)
r, g, b = pixel(50, 62)
local c = uni.motif.couleurs[1]
U.verifier(r == c[1] and g == c[2] and b == c[3], "la jupe prend la couleur de son tissu (" .. uni.nom .. ")")
r = pixel(50, 32)
U.verifier(r >= 245, "le corsage sans tissu reste blanc")
local trait = false
for di = -2, 2 do
	local rr, gg, bb, aa = pixel(37.5 + di * Croquis.LARGEUR / L, 62)
	trait = trait or (aa == 255 and rr < 100 and gg < 100 and bb < 100)
end
U.verifier(trait, "un trait de crayon foncé au bord de la jupe")

-- Les traits de détail ne passent que sur leur propre partie : le croisé du cache-cœur s'arrête sous le col
do
	local croquisCroise = { corsage = "corsage_cache_coeur", manches = "manches_sans", col = "col_claudine", jupe = "jupe_droite" }
	local image = Pixels.croquis(croquisCroise, {}, L, H)
	local fin, surLeCol = 0, 0
	for j = 0, H - 1 do
		for i = 0, L - 1 do
			local v = buffer.readu32(image, (j * L + i) * 4)
			if v % 256 == 120 and math.floor(v / 256) % 256 == 100 and math.floor(v / 65536) % 256 == 106 and math.floor(v / 16777216) == 255 then
				fin += 1
				if Croquis.partieA(croquisCroise, (i + 0.5) * Croquis.LARGEUR / L, (j + 0.5) * Croquis.HAUTEUR / H) == "col" then
					surLeCol += 1
				end
			end
		end
	end
	U.verifier(fin > 0 and surLeCol == 0, "le croisé du cache-cœur ne passe pas sur le col Claudine (" .. surLeCol .. " points sur " .. fin .. ")")
	for _, s in ipairs(Croquis.details(croquisCroise)) do
		U.verifier(s.famille == "corsage", "chaque trait de détail sait à quelle partie il appartient")
	end
end

-- Rapide sur téléphone : le croquis ne calcule du motif que les points de la robe, pas des motifs entiers
-- (256 × 256 points par tissu), et il en montre exactement les couleurs (un point du dessin, deux du motif)
do
	local fleuri
	for _, t in ipairs(Catalogue.Tissus) do
		if t.motif.type ~= "uni" and t.motif.type ~= "rayures" then
			fleuri = fleuri or t
		end
	end
	local motifsEntiers = 0
	local motifReel = Pixels.motif
	Pixels.motif = function(...)
		motifsEntiers += 1
		return motifReel(...)
	end
	local b = Pixels.croquis(base, { corsage = fleuri.id, jupe = fleuri.id }, L, H)
	Pixels.motif = motifReel
	U.verifier(motifsEntiers == 0, "aucun motif entier calculé pour un croquis (" .. motifsEntiers .. ")")
	local motif, N = Pixels.motif(fleuri.id), Catalogue.TAILLE_MOTIF
	local ecarts = 0
	for _, p in ipairs({ { 100, 150 }, { 90, 120 }, { 110, 100 }, { 100, 70 } }) do -- (jupe et corsage)
		local i, j = p[1], p[2]
		if buffer.readu32(b, (j * L + i) * 4) ~= buffer.readu32(motif, (((j * 2) % N) * N + (i * 2) % N) * 4) then
			ecarts += 1
		end
	end
	U.verifier(ecarts == 0, "les couleurs du motif (" .. fleuri.nom .. ") : " .. ecarts .. " écart(s)")
end
