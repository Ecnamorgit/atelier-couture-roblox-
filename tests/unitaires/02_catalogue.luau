local Catalogue = U.module("Catalogue")
local Polygone = U.module("Polygone")

local styles = {}
for _, s in ipairs(Catalogue.STYLES) do
	styles[s] = true
end
local function stylesValides(t, ou)
	for cle, valeur in pairs(t) do
		U.verifier(styles[cle] == true, ou .. " : style inconnu " .. tostring(cle))
		U.verifier(type(valeur) == "number", ou .. " : points non numériques")
	end
end

-- Pièces
for id, piece in pairs(Catalogue.Pieces) do
	U.verifier(#piece.contour >= 3 and Polygone.aire(piece.contour) > 0.5, id .. " : contour valide")
	local b = Polygone.boite(piece.contour)
	U.verifier(U.proche(b.minX, 0) and U.proche(b.minY, 0), id .. " : contour calé en (0, 0)")
	local largeurMax = piece.pliee and Catalogue.PLI or Catalogue.LARGEUR_ROULEAU
	U.verifier(b.maxX <= largeurMax and b.maxY <= largeurMax, id .. " : tient dans le rouleau (ou sa moitié si pliée)")
	U.verifier(#piece.coutures >= 1, id .. " : au moins une couture")
	for _, i in ipairs(piece.coutures) do
		U.verifier(i >= 1 and i <= #piece.contour, id .. " : indice de couture valide")
	end
	local e = piece.enroulement
	U.verifier(e.type == "corsage" or e.type == "jupe" or e.type == "manche" or e.type == "col", id .. " : enroulement connu")
	U.verifier(e.type ~= "col" or e.forme == "claudine" or e.forme == "montant" or e.forme == "marin", id .. " : forme de col connue")
	if e.type == "corsage" or e.type == "jupe" then
		U.verifier(e.cote == "devant" or e.cote == "dos", id .. " : côté devant ou dos")
		U.verifier(not piece.pliee, id .. " : devant/dos ne sont pas coupés pliés")
	else
		U.verifier(piece.pliee == true, id .. " : manches et cols se coupent pliés")
	end
end

-- Variantes
local ids = {}
for _, v in ipairs(Catalogue.Variantes) do
	U.verifier(not ids[v.id], "variante en double : " .. v.id)
	ids[v.id] = true
	U.verifier(table.find(Catalogue.FAMILLES, v.famille) ~= nil, v.id .. " : famille connue")
	for _, p in ipairs(v.pieces) do
		U.verifier(Catalogue.piece(p) ~= nil, v.id .. " : pièce " .. p .. " définie")
	end
	stylesValides(v.style, v.id)
end
-- Corsage : un devant et un dos de même hauteur (les coutures de côté se rejoignent)
for _, v in ipairs(Catalogue.variantesDe("corsage")) do
	local h1 = Polygone.boite(Catalogue.piece(v.pieces[1]).contour).maxY
	local h2 = Polygone.boite(Catalogue.piece(v.pieces[2]).contour).maxY
	U.verifier(U.proche(h1, h2), v.id .. " : devant et dos de même hauteur")
end
-- Chaque robe possible compte 4 à 10 pièces à poser (sous-projet 7 : le corsage à basque et la jupe à volant en ont quatre)
local minimum, maximum = math.huge, 0
for _, c in ipairs(Catalogue.variantesDe("corsage")) do
	for _, m in ipairs(Catalogue.variantesDe("manches")) do
		for _, k in ipairs(Catalogue.variantesDe("col")) do
			for _, j in ipairs(Catalogue.variantesDe("jupe")) do
				local n = #c.pieces + #m.pieces + #k.pieces + #j.pieces
				minimum, maximum = math.min(minimum, n), math.max(maximum, n)
			end
		end
	end
end
U.verifier(minimum == 4 and maximum == 10, ("4 à 10 pièces par robe (obtenu %d à %d)"):format(minimum, maximum))
-- Sous-projet 7 : vingt-quatre variantes (sept corsages, cinq manches, quatre cols, huit jupes : 1 120 croquis)
local parFamille = {}
for _, v in ipairs(Catalogue.Variantes) do
	parFamille[v.famille] = (parFamille[v.famille] or 0) + 1
end
U.verifier(#Catalogue.Variantes == 24 and parFamille.corsage == 7 and parFamille.manches == 5 and parFamille.col == 4 and parFamille.jupe == 8, "24 variantes : sept corsages, cinq manches, quatre cols, huit jupes")
for _, id in ipairs({ "corsage_cache_coeur", "corsage_bustier", "manches_courtes", "manches_trois_quarts", "col_marin", "jupe_crayon" }) do
	local v = Catalogue.variante(id)
	local points = 0
	for _, p in pairs(v and v.style or {}) do
		points += p
	end
	U.verifier(v ~= nil and points >= 8, id .. " : variante nouvelle, avec du style")
end

-- Tissus
local teintes = {}
for _, t in ipairs(Catalogue.TEINTES) do
	teintes[t] = true
end
local vus = {}
U.verifier(#Catalogue.Tissus == 41, "41 tissus (dont la toile de jute et quatre matières de fin de partie)")
local jute = Catalogue.tissu("toile_jute")
U.verifier(jute ~= nil and jute.prix == 0 and jute.teinte == "brun" and Catalogue.MATIERES[jute.matiere] ~= nil, "la toile de jute : gratuite, brune, rendue comme un tissu")
local plusFaible = math.huge
for _, t in ipairs(Catalogue.Tissus) do
	if t.id ~= "toile_jute" then
		local total = 0
		for _, pts in pairs(t.style) do
			total += pts
		end
		plusFaible = math.min(plusFaible, total)
	end
end
U.verifier((jute.style.decontracte or 0) > 0 and (jute.style.decontracte or 0) < plusFaible, "la toile de jute : un style à peine marqué (décontracté)")
for _, t in ipairs(Catalogue.Tissus) do
	U.verifier(not vus[t.id], "tissu en double : " .. t.id)
	vus[t.id] = true
	U.verifier(teintes[t.teinte] == true, t.id .. " : teinte connue")
	U.verifier((t.prix >= 4 and t.prix <= 26) or (t.id == "toile_jute" and t.prix == 0), t.id .. " : prix entre 4 et 26 (la toile de jute est gratuite)")
	U.verifier(Catalogue.MATIERES[t.matiere] ~= nil, t.id .. " : matière connue")
	stylesValides(t.style, t.id)
	for _, c in ipairs(t.motif.couleurs) do
		U.verifier(#c == 3 and c[1] >= 0 and c[1] <= 255 and c[2] >= 0 and c[2] <= 255 and c[3] >= 0 and c[3] <= 255,
			t.id .. " : couleur RVB valide")
	end
	if t.motif.periode then
		local px = t.motif.periode * Catalogue.PX_PAR_DM
		U.verifier(px == math.floor(px) and Catalogue.TAILLE_MOTIF % px == 0, t.id .. " : période qui divise le motif (raccord)")
	end
end

-- Accessoires
U.verifier(#Catalogue.Accessoires == 39, "39 accessoires (dont les douze souvenirs du quartier et douze décorations nouvelles)")
for _, a in ipairs(Catalogue.Accessoires) do
	U.verifier(a.genre == "objet" or a.genre == "garniture", a.id .. " : genre connu")
	U.verifier(a.prix > 0, a.id .. " : prix positif")
	stylesValides(a.style, a.id)
end

-- Plan 2 : rendu 3D
U.verifier(Catalogue.STUDS_PAR_DM > 0, "échelle du rendu positive")
for nom, m in pairs(Catalogue.MATIERES) do
	U.verifier(m.materiau == "Fabric" or m.materiau == "SmoothPlastic", nom .. " : matériau Roblox connu")
	U.verifier(m.reflet >= 0 and m.reflet <= 1, nom .. " : reflet entre 0 et 1")
end
local FORMES = { boule = true, bloc = true, cylindre = true, noeud = true, fleur = true, croix = true }
for _, a in ipairs(Catalogue.Accessoires) do
	local ap = a.apparence
	U.verifier(type(ap) == "table" and #ap.couleur == 3, a.id .. " : apparence avec couleur")
	if a.genre == "objet" then
		U.verifier(FORMES[ap.forme] == true and ap.taille > 0 and ap.taille <= 1, a.id .. " : forme connue, taille ≤ 1 dm")
	else
		U.verifier(ap.largeur > 0 and ap.largeur <= 0.5 and ap.transparence >= 0 and ap.transparence < 1, a.id .. " : largeur et transparence valides")
	end
end
