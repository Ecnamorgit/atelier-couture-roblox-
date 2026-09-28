-- Pixels : images RVBA en buffer (4 octets par pixel, ligne par ligne), sans objet Roblox.
-- Dessine le motif répétable d'un tissu et « découpe » l'image d'une pièce posée sur le rouleau.
-- Le client copie ensuite ces buffers dans des EditableImage (WritePixelsBuffer).
local dossier = script.Parent
local Catalogue = require(dossier:WaitForChild("Catalogue"))
local Polygone = require(dossier:WaitForChild("Polygone"))

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
	for j = 0, hauteur - 1 do
		local y = b.minY + (j + 0.5) / hauteur * h
		for i = 0, largeur - 1 do
			local x = b.minX + (i + 0.5) / largeur * l
			local p = Pixels.surRouleau(idPiece, placement, copie, x, y)
			local mx, my = Pixels.pixelMotif(p.x, p.y)
			buffer.writeu32(buf, (j * largeur + i) * 4, buffer.readu32(motif, (my * N + mx) * 4))
		end
	end
	return buf, largeur, hauteur
end

return Pixels
