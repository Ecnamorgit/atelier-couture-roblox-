-- Pixels : images RVBA en buffer (4 octets par pixel, ligne par ligne), sans objet Roblox.
-- Dessine le motif répétable d'un tissu et « découpe » l'image d'une pièce posée sur le rouleau.
-- Le client copie ensuite ces buffers dans des EditableImage (WritePixelsBuffer).
local dossier = script.Parent
local Catalogue = require(dossier:WaitForChild("Catalogue"))
local Polygone = require(dossier:WaitForChild("Polygone"))
local Croquis = require(dossier:WaitForChild("Croquis"))

local Pixels = {}

local N = Catalogue.TAILLE_MOTIF -- 256
local PX = Catalogue.PX_PAR_DM -- 32
local TAILLE_MAX_PIECE = 256

local function empaqueter(r, g, b)
	return r + g * 256 + b * 65536 + 255 * 16777216
end
Pixels.empaqueter = empaqueter

function Pixels.lire(buf, largeur, x, y)
	local v = buffer.readu32(buf, (y * largeur + x) * 4)
	return v % 256, math.floor(v / 256) % 256, math.floor(v / 65536) % 256
end

local function melanger(a, b, t)
	return {
		math.floor(a[1] + (b[1] - a[1]) * t + 0.5),
		math.floor(a[2] + (b[2] - a[2]) * t + 0.5),
		math.floor(a[3] + (b[3] - a[3]) * t + 0.5),
	}
end

-- Couleur du motif au pixel (px, py) du carreau de 256 × 256
local MOTIFS = {}
function MOTIFS.uni(m, _px, _py)
	return m.couleurs[1]
end
function MOTIFS.rayures(m, px, _py)
	-- Rayures parallèles au droit-fil (elles suivent la longueur du rouleau)
	local p = m.periode * PX
	return (px % p) < m.largeur * PX and m.couleurs[2] or m.couleurs[1]
end
function MOTIFS.carreaux(m, px, py)
	local p = m.periode * PX
	local n = ((px % p) < p / 2 and 1 or 0) + ((py % p) < p / 2 and 1 or 0)
	if n == 0 then
		return m.couleurs[1]
	elseif n == 1 then
		return melanger(m.couleurs[1], m.couleurs[2], 0.5)
	end
	return m.couleurs[2]
end
function MOTIFS.pois(m, px, py)
	local p = m.periode * PX
	local ligne = math.floor(py / p)
	local dx = ((px + (ligne % 2) * p / 2) % p) - p / 2 + 0.5
	local dy = (py % p) - p / 2 + 0.5
	return (dx * dx + dy * dy) <= (m.rayon * PX) ^ 2 and m.couleurs[2] or m.couleurs[1]
end
function MOTIFS.fleurs(m, px, py)
	local p = m.periode * PX
	local ligne = math.floor(py / p)
	local dx = ((px + (ligne % 2) * p / 2) % p) - p / 2 + 0.5
	local dy = (py % p) - p / 2 + 0.5
	local d = math.sqrt(dx * dx + dy * dy)
	if d < p * 0.12 then
		return m.couleurs[3]
	elseif d < p * 0.34 and math.cos(5 * math.atan2(dy, dx)) > 0.1 then
		return m.couleurs[2]
	end
	return m.couleurs[1]
end
function MOTIFS.degrade(m, _px, py)
	-- Aller-retour sur la hauteur du carreau : le haut et le bas se raccordent
	local t = py / N
	return melanger(m.couleurs[1], m.couleurs[2], 1 - math.abs(2 * t - 1))
end

-- Buffer 256 × 256 du motif d'un tissu (répétable dans les deux sens)
function Pixels.motif(idTissu)
	local tissu = Catalogue.tissu(idTissu)
	assert(tissu, "tissu inconnu : " .. tostring(idTissu))
	local dessiner = MOTIFS[tissu.motif.type]
	local buf = buffer.create(N * N * 4)
	for py = 0, N - 1 do
		for px = 0, N - 1 do
			local c = dessiner(tissu.motif, px, py)
			buffer.writeu32(buf, (py * N + px) * 4, empaqueter(c[1], c[2], c[3]))
		end
	end
	return buf
end

-- Dimensions (pixels) de l'image d'une pièce : 32 px par dm, plafonnées à « plafond » par côté
function Pixels.taillePiece(idPiece, plafond)
	local b = Polygone.boite(Catalogue.piece(idPiece).contour)
	local l, h = b.maxX - b.minX, b.maxY - b.minY
	local echelle = math.min(PX, (plafond or TAILLE_MAX_PIECE) / math.max(l, h))
	return math.max(1, math.ceil(l * echelle)), math.max(1, math.ceil(h * echelle)), b
end

-- Position sur le rouleau (dm) du point (x, y) du patron, pour une copie de pièce posée
function Pixels.surRouleau(idPiece, placement, copie, x, y)
	local def = Catalogue.piece(idPiece)
	local p = Polygone.poserPoint({ x = x, y = y }, placement, Polygone.centre(def.contour))
	if copie == "droite" then
		p.x = 2 * Catalogue.PLI - p.x -- copie symétrique, de l'autre côté du pli
	end
	return p
end

-- Pixel du motif sous un point du rouleau (répétition du carreau)
function Pixels.pixelMotif(bx, by)
	return math.floor(bx * PX) % N, math.floor(by * PX) % N
end

-- Image de la pièce découpée : chaque pixel reprend le pixel du motif qui était dessous sur la table.
-- La copie « gauche » (ou « unique ») est la pièce posée ; la « droite » est son symétrique au pli.
-- Retourne buffer, largeur, hauteur.
function Pixels.imagePiece(motif, idPiece, placement, copie, plafond)
	local largeur, hauteur, b = Pixels.taillePiece(idPiece, plafond)
	local l, h = b.maxX - b.minX, b.maxY - b.minY
	local buf = buffer.create(largeur * hauteur * 4)
	-- Même calcul que surRouleau, sorti de la boucle (un appel par pixel coûtait ~15 fois plus cher)
	local cx, cy = (b.minX + b.maxX) / 2, (b.minY + b.maxY) / 2
	local a = math.rad(placement.angle or 0)
	local c, s = math.cos(a), math.sin(a)
	local miroir = copie == "droite"
	for j = 0, hauteur - 1 do
		local dy = b.minY + (j + 0.5) / hauteur * h - cy
		for i = 0, largeur - 1 do
			local dx = b.minX + (i + 0.5) / largeur * l - cx
			local bx = placement.x + c * dx - s * dy
			local by = placement.y + s * dx + c * dy
			if miroir then
				bx = 2 * Catalogue.PLI - bx
			end
			local mx, my = math.floor(bx * PX) % N, math.floor(by * PX) % N
			buffer.writeu32(buf, (j * largeur + i) * 4, buffer.readu32(motif, (my * N + mx) * 4))
		end
	end
	return buf, largeur, hauteur
end

-- Rend transparent tout ce qui est hors du contour de la pièce (sur place) : l'image de imagePiece
-- devient la pièce découpée telle qu'on la voit dans l'interface. Retourne le même buffer.
function Pixels.decouper(buf, largeur, hauteur, idPiece)
	local contour = Catalogue.piece(idPiece).contour
	local b = Polygone.boite(contour)
	local l, h = b.maxX - b.minX, b.maxY - b.minY
	for j = 0, hauteur - 1 do
		local y = b.minY + (j + 0.5) / hauteur * h
		for i = 0, largeur - 1 do
			if not Polygone.contient(contour, b.minX + (i + 0.5) / largeur * l, y) then
				buffer.writeu8(buf, (j * largeur + i) * 4 + 3, 0)
			end
		end
	end
	return buf
end

---------------------------------------------------------------------------
-- Silhouette d'un patron en papier (table de découpe) : papier translucide, contour foncé
-- et flèche de droit-fil (en diagonale pour une pièce à couper dans le biais). Hors de la pièce : transparent.
---------------------------------------------------------------------------
local PAPIER = { 255, 248, 222, 170 }
local TRAIT = { 70, 50, 60, 255 }

local function empaqueterAlpha(r, g, b, a)
	return r + g * 256 + b * 65536 + a * 16777216
end

local function distanceSegment(px, py, a, b)
	local dx, dy = b.x - a.x, b.y - a.y
	local l2 = dx * dx + dy * dy
	local t = l2 > 0 and math.clamp(((px - a.x) * dx + (py - a.y) * dy) / l2, 0, 1) or 0
	local qx, qy = a.x + t * dx - px, a.y + t * dy - py
	return math.sqrt(qx * qx + qy * qy)
end

-- Retourne buffer, largeur, hauteur (même taille et même repère que imagePiece)
function Pixels.silhouette(idPiece, plafond)
	local def = Catalogue.piece(idPiece)
	local largeur, hauteur, b = Pixels.taillePiece(idPiece, plafond)
	local l, h = b.maxX - b.minX, b.maxY - b.minY
	local dmParPx = l / largeur
	local contour = def.contour
	-- Flèche de droit-fil : direction dans le patron qui doit suivre la chaîne du tissu
	local fx, fy = 0, 1
	if def.biais then
		fx, fy = math.sin(math.rad(45)), math.cos(math.rad(45))
	end
	local cx, cy = (b.minX + b.maxX) / 2, (b.minY + b.maxY) / 2
	local demi = math.min(l, h) * 0.35
	local fleche0 = { x = cx - fx * demi, y = cy - fy * demi }
	local fleche1 = { x = cx + fx * demi, y = cy + fy * demi }
	local pointe = demi * 0.25
	local aile1 = { x = fleche1.x - (fx * 0.7 - fy * 0.7) * pointe, y = fleche1.y - (fy * 0.7 + fx * 0.7) * pointe }
	local aile2 = { x = fleche1.x - (fx * 0.7 + fy * 0.7) * pointe, y = fleche1.y - (fy * 0.7 - fx * 0.7) * pointe }
	local epaisseur = 1.5 * dmParPx
	local buf = buffer.create(largeur * hauteur * 4)
	for j = 0, hauteur - 1 do
		local y = b.minY + (j + 0.5) / hauteur * h
		for i = 0, largeur - 1 do
			local x = b.minX + (i + 0.5) / largeur * l
			local valeur = 0
			if Polygone.contient(contour, x, y) then
				local bord = math.huge
				for k, a in ipairs(contour) do
					bord = math.min(bord, distanceSegment(x, y, a, contour[k % #contour + 1]))
				end
				local fleche = math.min(distanceSegment(x, y, fleche0, fleche1), distanceSegment(x, y, fleche1, aile1),
					distanceSegment(x, y, fleche1, aile2))
				local c = (bord <= epaisseur or fleche <= epaisseur * 0.8) and TRAIT or PAPIER
				valeur = empaqueterAlpha(c[1], c[2], c[3], c[4])
			end
			buffer.writeu32(buf, (j * largeur + i) * 4, valeur)
		end
	end
	return buf, largeur, hauteur
end

---------------------------------------------------------------------------
-- Croquis du carnet (sous-projet 5) : la robe de face, chaque partie remplie du motif de son tissu (blanche sans
-- tissu), un trait de crayon autour, les plis en traits fins, le mannequin esquissé derrière. Fond transparent :
-- le papier du carnet est dessous. tissus = { [famille] = idTissu ou nil } (sous-projet 7 : et [idPiece] pour une
-- partie qui porte ses pièces, un volant). Retourne buffer, largeur, hauteur.
---------------------------------------------------------------------------
local BLANC_CROQUIS = { 252, 250, 245 }
local CRAYON = { 64, 50, 56 }
local CRAYON_FIN = { 120, 100, 106 }
local ESQUISSE = { 175, 165, 165, 150 }
local MOTIF_PAR_PX = 2 -- un pixel du dessin couvre deux pixels du motif : on voit les dessins du tissu

function Pixels.croquis(croquis, tissus, largeur, hauteur)
	local parties = Croquis.parties(croquis)
	local ex, ey = largeur / Croquis.LARGEUR, hauteur / Croquis.HAUTEUR
	-- Numéro de la partie visible à chaque pixel (0 : rien), rempli ligne par ligne (la dernière partie gagne)
	local etiquettes = buffer.create(largeur * hauteur)
	for k, partie in ipairs(parties) do
		local poly = partie.polygone
		local n = #poly
		for j = 0, hauteur - 1 do
			local y = (j + 0.5) / ey
			local xs = {}
			for i = 1, n do
				local a, b = poly[i], poly[i % n + 1]
				if (a.y <= y and b.y > y) or (b.y <= y and a.y > y) then
					table.insert(xs, a.x + (y - a.y) * (b.x - a.x) / (b.y - a.y))
				end
			end
			table.sort(xs)
			for m = 1, #xs - 1, 2 do
				for i = math.max(0, math.ceil(xs[m] * ex - 0.5)), math.min(largeur - 1, math.floor(xs[m + 1] * ex - 0.5)) do
					buffer.writeu8(etiquettes, j * largeur + i, k)
				end
			end
		end
	end
	local function etiquette(i, j)
		if i < 0 or j < 0 or i >= largeur or j >= hauteur then
			return 0
		end
		return buffer.readu8(etiquettes, j * largeur + i)
	end
	-- Le motif n'est calculé qu'aux points de la robe (un motif entier, 256 × 256 points par tissu, prendrait
	-- l'essentiel du temps, à chaque modèle ou tissu choisi, sur téléphone)
	local tissuDe = {}
	for cle, id in pairs(tissus) do
		tissuDe[cle] = Catalogue.tissu(id)
	end
	local blanc = empaqueter(BLANC_CROQUIS[1], BLANC_CROQUIS[2], BLANC_CROQUIS[3])
	local crayon = empaqueter(CRAYON[1], CRAYON[2], CRAYON[3])
	local buf = buffer.create(largeur * hauteur * 4)
	for j = 0, hauteur - 1 do
		for i = 0, largeur - 1 do
			local k = buffer.readu8(etiquettes, j * largeur + i)
			local valeur = 0
			if k > 0 then
				if etiquette(i - 1, j) ~= k or etiquette(i + 1, j) ~= k or etiquette(i, j - 1) ~= k or etiquette(i, j + 1) ~= k then
					valeur = crayon
				else
					local partie = parties[k]
					local t = tissuDe[if partie.pieces then partie.pieces[1] else partie.famille]
					if t then
						local c = MOTIFS[t.motif.type](t.motif, (i * MOTIF_PAR_PX) % N, (j * MOTIF_PAR_PX) % N)
						valeur = empaqueter(c[1], c[2], c[3])
					else
						valeur = blanc
					end
				end
			end
			buffer.writeu32(buf, (j * largeur + i) * 4, valeur)
		end
	end
	-- Traits : plis et croisé sur la robe (crayon fin), mannequin esquissé là où la robe ne passe pas
	-- famille : le trait ne passe que sur cette partie de la robe (nil : que hors de la robe, le mannequin)
	local function tracer(segment, couleur, famille)
		local a, b = segment[1], segment[2]
		local pas = math.max(1, math.ceil(math.sqrt(((b.x - a.x) * ex) ^ 2 + ((b.y - a.y) * ey) ^ 2) * 2))
		for t = 0, pas do
			local i = math.floor((a.x + (b.x - a.x) * t / pas) * ex)
			local j = math.floor((a.y + (b.y - a.y) * t / pas) * ey)
			if i >= 0 and j >= 0 and i < largeur and j < hauteur then
				local k = etiquette(i, j)
				if (famille == nil and k == 0) or (famille ~= nil and k > 0 and parties[k].famille == famille) then
					buffer.writeu32(buf, (j * largeur + i) * 4, couleur)
				end
			end
		end
	end
	local fin = empaqueter(CRAYON_FIN[1], CRAYON_FIN[2], CRAYON_FIN[3])
	for _, s in ipairs(Croquis.details(croquis)) do
		tracer(s, fin, s.famille)
	end
	local esquisse = empaqueterAlpha(ESQUISSE[1], ESQUISSE[2], ESQUISSE[3], ESQUISSE[4])
	for _, s in ipairs(Croquis.MANNEQUIN) do
		tracer(s, esquisse, nil)
	end
	return buf, largeur, hauteur
end

---------------------------------------------------------------------------
-- Portrait d'une cliente (sous-projet 7) : un buste de face au crayon, 128 × 160 — ses épaules dans le haut de sa
-- tenue, son visage et son cou dans sa peau, sa coiffure dans ses cheveux ; les yeux, les sourcils et la bouche selon
-- l'expression (« contente », « neutre », « decue »). Fond transparent. Retourne buffer, largeur, hauteur.
---------------------------------------------------------------------------
Pixels.PORTRAIT_LARGEUR, Pixels.PORTRAIT_HAUTEUR = 128, 160
Pixels.EXPRESSIONS = { "contente", "neutre", "decue" }
Pixels.COIFFURES = { "carre", "chignon", "longs", "courts", "tresse", "boucles", "queue" }
local JOUE = { 240, 150, 150 }

local function rvb(c)
	return { math.floor(c.R * 255 + 0.5), math.floor(c.G * 255 + 0.5), math.floor(c.B * 255 + 0.5) }
end
local function dansEllipse(x, y, cx, cy, rx, ry)
	return ((x - cx) / rx) ^ 2 + ((y - cy) / ry) ^ 2 <= 1
end
-- Les cheveux derrière la tête et les épaules (ils descendent plus ou moins bas selon la coiffure)
local function cheveuxDerriere(coiffure, x, y)
	if coiffure == "longs" then
		return dansEllipse(x, y, 64, 62, 36, 40) or (y >= 62 and y <= 136 and x >= 29 and x <= 99)
	elseif coiffure == "carre" then
		return dansEllipse(x, y, 64, 66, 36, 38) and y <= 100
	elseif coiffure == "chignon" then
		return dansEllipse(x, y, 64, 30, 15, 13)
	elseif coiffure == "tresse" then
		return dansEllipse(x, y, 64, 62, 34, 36) and y <= 80
	elseif coiffure == "boucles" then
		for k = 0, 10 do
			local a = math.pi * (0.9 + 1.2 * k / 10)
			if dansEllipse(x, y, 64 + 33 * math.cos(a), 64 + 36 * math.sin(a), 11, 11) then
				return true
			end
		end
		return false
	elseif coiffure == "queue" then
		return (dansEllipse(x, y, 64, 62, 33, 36) and y <= 76) or dansEllipse(x, y, 97, 80, 9, 24)
	end
	return false -- courts : rien derrière
end
-- La tresse, ramenée devant, sur l'épaule droite (à gauche du dessin)
local function tresse(x, y)
	for k = 0, 5 do
		if dansEllipse(x, y, 36 - k * 2, 88 + k * 10, 7, 6) then
			return true
		end
	end
	return false
end
-- La ligne des cheveux sur le front : au-dessus, les cheveux (une frange droite pour le carré)
local function ligneCheveux(coiffure, x)
	if coiffure == "carre" then
		return 52
	end
	local t = (x - 64) / 28
	return 43 + 10 * t * t
end
-- Un trait de crayon : les points à moins d'un demi-pixel du segment
local function trait(buf, largeur, hauteur, a, b, couleur, epaisseur)
	local pas = math.max(1, math.ceil(math.sqrt((b[1] - a[1]) ^ 2 + (b[2] - a[2]) ^ 2) * 2))
	for t = 0, pas do
		local x, y = a[1] + (b[1] - a[1]) * t / pas, a[2] + (b[2] - a[2]) * t / pas
		for dy = -epaisseur, epaisseur do
			for dx = -epaisseur, epaisseur do
				local i, j = math.floor(x + dx + 0.5), math.floor(y + dy + 0.5)
				if i >= 0 and j >= 0 and i < largeur and j < hauteur and dx * dx + dy * dy <= epaisseur * epaisseur + 0.5 then
					buffer.writeu32(buf, (j * largeur + i) * 4, couleur)
				end
			end
		end
	end
end
-- Une courbe y = f(x) de x0 à x1, en petits traits
local function courbe(buf, largeur, hauteur, x0, x1, f, couleur)
	local precedent = { x0, f(x0) }
	for k = 1, 12 do
		local x = x0 + (x1 - x0) * k / 12
		local point = { x, f(x) }
		trait(buf, largeur, hauteur, precedent, point, couleur, 1)
		precedent = point
	end
end

function Pixels.portrait(cliente, expression)
	local L, H = Pixels.PORTRAIT_LARGEUR, Pixels.PORTRAIT_HAUTEUR
	local peau, haut, cheveux = rvb(cliente.tenue.peau), rvb(cliente.tenue.haut), rvb(cliente.tenue.cheveux)
	local coiffure = cliente.coiffure
	-- Chaque pixel reçoit une matière (0 : rien, 1 : tenue, 2 : peau, 3 : cheveux), dans l'ordre du dessin : cheveux de
	-- derrière, épaules, tresse, cou, oreilles, visage, cheveux du front
	local matiere = buffer.create(L * H)
	for j = 0, H - 1 do
		local y = j + 0.5
		for i = 0, L - 1 do
			local x = i + 0.5
			local m = if cheveuxDerriere(coiffure, x, y) then 3 else 0
			local epaules = y >= 120 and math.abs(x - 64) <= 30 + (y - 120) * 1.3 and math.abs(x - 64) <= 56
			if epaules then
				m = if dansEllipse(x, y, 64, 118, 15, 13) then 2 else 1 -- l'encolure
			end
			if coiffure == "tresse" and tresse(x, y) then
				m = 3
			end
			if x >= 55 and x <= 73 and y >= 90 and y <= 124 then
				m = 2 -- le cou
			end
			if dansEllipse(x, y, 37, 72, 5, 8) or dansEllipse(x, y, 91, 72, 5, 8) then
				m = 2 -- les oreilles
			end
			if dansEllipse(x, y, 64, 68, 27, 33) then
				m = if y < ligneCheveux(coiffure, x) then 3 else 2
			end
			buffer.writeu8(matiere, j * L + i, m)
		end
	end
	local function matiereEn(i, j)
		if i < 0 or j < 0 or i >= L or j >= H then
			return 0
		end
		return buffer.readu8(matiere, j * L + i)
	end
	local couleurs = { haut, peau, cheveux }
	local crayon = empaqueter(CRAYON[1], CRAYON[2], CRAYON[3])
	local buf = buffer.create(L * H * 4)
	for j = 0, H - 1 do
		for i = 0, L - 1 do
			local m = matiereEn(i, j)
			local valeur = 0
			if m > 0 then
				if matiereEn(i - 1, j) ~= m or matiereEn(i + 1, j) ~= m or matiereEn(i, j - 1) ~= m or matiereEn(i, j + 1) ~= m then
					valeur = crayon -- le contour, au crayon
				else
					local c = couleurs[m]
					valeur = empaqueter(c[1], c[2], c[3])
				end
			end
			buffer.writeu32(buf, (j * L + i) * 4, valeur)
		end
	end
	-- Le visage : un petit nez, les yeux, les sourcils et la bouche selon l'expression
	trait(buf, L, H, { 64, 73 }, { 62, 80 }, crayon, 0)
	trait(buf, L, H, { 62, 80 }, { 66, 81 }, crayon, 0)
	for _, cx in ipairs({ 53, 75 }) do
		if expression == "contente" then
			courbe(buf, L, H, cx - 4, cx + 4, function(x)
				return 71 - 3 * (1 - ((x - cx) / 4) ^ 2)
			end, crayon) -- des yeux rieurs
		else
			for dy = -3, 3 do
				for dx = -2, 2 do
					if (dx / 2.5) ^ 2 + (dy / 3.5) ^ 2 <= 1 then
						buffer.writeu32(buf, ((70 + dy) * L + cx + dx) * 4, crayon)
					end
				end
			end
		end
		local interieur = if cx < 64 then cx + 5 else cx - 5
		local exterieur = if cx < 64 then cx - 5 else cx + 5
		local hautInterieur = if expression == "decue" then 57 else 61
		trait(buf, L, H, { exterieur, 61 }, { interieur, hautInterieur }, crayon, 0) -- le sourcil
	end
	if expression == "contente" then
		courbe(buf, L, H, 55, 73, function(x)
			return 85 + 5 * (1 - ((x - 64) / 9) ^ 2)
		end, crayon)
		local joue = empaqueter(JOUE[1], JOUE[2], JOUE[3])
		for _, cx in ipairs({ 47, 81 }) do
			for dy = -2, 2 do
				for dx = -4, 4 do
					if buffer.readu8(matiere, (80 + dy) * L + cx + dx) == 2 then
						buffer.writeu32(buf, ((80 + dy) * L + cx + dx) * 4, joue)
					end
				end
			end
		end
	elseif expression == "decue" then
		courbe(buf, L, H, 56, 72, function(x)
			return 90 - 5 * (1 - ((x - 64) / 8) ^ 2)
		end, crayon)
	else
		trait(buf, L, H, { 58, 87 }, { 70, 87 }, crayon, 0)
	end
	return buf, L, H
end

return Pixels
