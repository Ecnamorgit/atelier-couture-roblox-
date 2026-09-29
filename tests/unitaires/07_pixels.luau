local Catalogue = U.module("Catalogue")
local Polygone = U.module("Polygone")
local Pixels = U.module("Pixels")

-- Motifs : bonne taille, raccord bord à bord
local N = Catalogue.TAILLE_MOTIF
for _, t in ipairs(Catalogue.Tissus) do
	local buf = Pixels.motif(t.id)
	U.verifier(buffer.len(buf) == N * N * 4, t.id .. " : motif de 256 × 256")
	local r, g, b = Pixels.lire(buf, N, 0, 0)
	U.verifier(r >= 0 and r <= 255 and g >= 0 and g <= 255 and b >= 0 and b <= 255, t.id .. " : couleur valide")
end
local uni = Pixels.motif("coton_blanc")
local r, g, b = Pixels.lire(uni, N, 100, 7)
U.verifier(r == 246 and g == 242 and b == 234, "un tissu uni a sa couleur partout")
-- Rayures : parallèles au droit-fil → la couleur ne dépend que de x
local rayures = Pixels.motif("lin_vert_rayures")
U.verifier(select(1, Pixels.lire(rayures, N, 3, 0)) == select(1, Pixels.lire(rayures, N, 3, 200)), "les rayures suivent la longueur")
U.verifier(select(1, Pixels.lire(rayures, N, 0, 0)) ~= select(1, Pixels.lire(rayures, N, 20, 0)), "deux bandes de couleurs différentes")
-- Dégradé : il se raccorde en haut et en bas du carreau
local degrade = Pixels.motif("soie_bleue_degrade")
U.verifier(select(3, Pixels.lire(degrade, N, 5, 0)) == 160 and select(3, Pixels.lire(degrade, N, 5, 128)) == 240,
	"dégradé : couleur 1 en haut, couleur 2 au milieu")

-- Taille de l'image d'une pièce : 32 px/dm, plafonnée
local l, h = Pixels.taillePiece("jupe_droite_devant")
U.verifier(l == 160 and h == 192, "jupe droite 5 × 6 dm → 160 × 192 px")
l, h = Pixels.taillePiece("jupe_evasee_devant")
U.verifier(math.max(l, h) == 256, "pièce de 9 dm plafonnée à 256 px")
l, h = Pixels.taillePiece("jupe_droite_devant", 128)
U.verifier(math.max(l, h) == 128, "plafond de vitrine à 128 px")

-- Exactitude de la découpe : le pixel de la pièce = le pixel du motif sous ce point sur la table
local motif = Pixels.motif("soie_rose_fleurs")
local cas = {
	{ id = "jupe_trapeze_devant", placement = { x = 4, y = 5, angle = 0 }, copie = "unique" },
	{ id = "jupe_trapeze_devant", placement = { x = 6.3, y = 7.1, angle = 45 }, copie = "unique" },
	{ id = "jupe_droite_dos", placement = { x = 5, y = 4, angle = 90 }, copie = "unique" },
	{ id = "corsage_v_devant", placement = { x = 3, y = 3, angle = 180 }, copie = "unique" },
	{ id = "manche_ballon", placement = { x = 3, y = 2, angle = 0 }, copie = "gauche" },
	{ id = "manche_ballon", placement = { x = 3, y = 2, angle = 0 }, copie = "droite" },
}
local rng = Random.new(7)
for _, c in ipairs(cas) do
	local img, largeur, hauteur = Pixels.imagePiece(motif, c.id, c.placement, c.copie)
	local bo = Polygone.boite(Catalogue.piece(c.id).contour)
	for _ = 1, 50 do
		local i, j = rng:NextInteger(0, largeur - 1), rng:NextInteger(0, hauteur - 1)
		-- Calcul indépendant : centre du pixel → patron → table → motif
		local x = bo.minX + (i + 0.5) / largeur * (bo.maxX - bo.minX)
		local y = bo.minY + (j + 0.5) / hauteur * (bo.maxY - bo.minY)
		local centre = { x = (bo.minX + bo.maxX) / 2, y = (bo.minY + bo.maxY) / 2 }
		local a = math.rad(c.placement.angle)
		local bx = c.placement.x + math.cos(a) * (x - centre.x) - math.sin(a) * (y - centre.y)
		local by = c.placement.y + math.sin(a) * (x - centre.x) + math.cos(a) * (y - centre.y)
		if c.copie == "droite" then
			bx = 14 - bx
		end
		local mx, my = math.floor(bx * 32) % 256, math.floor(by * 32) % 256
		local r1, g1, b1 = Pixels.lire(img, largeur, i, j)
		local r2, g2, b2 = Pixels.lire(motif, 256, mx, my)
		U.verifier(r1 == r2 and g1 == g2 and b1 == b2, ("%s à %g° (%s) : pixel (%d, %d) exact"):format(c.id, c.placement.angle, c.copie, i, j))
	end
end
-- Une rotation change vraiment l'image (le motif fleuri n'est pas symétrique par rotation de 45°)
local a0 = Pixels.imagePiece(motif, "jupe_droite_devant", { x = 4, y = 4, angle = 0 }, "unique")
local a45 = Pixels.imagePiece(motif, "jupe_droite_devant", { x = 4, y = 4, angle = 45 }, "unique")
local differents = 0
for k = 0, 160 * 192 - 1, 37 do
	if buffer.readu32(a0, k * 4) ~= buffer.readu32(a45, k * 4) then
		differents += 1
	end
end
U.verifier(differents > 50, "la rotation de la pièce change l'image découpée")

-- Silhouette du patron (table de découpe)
local function alpha(buf, largeur, i, j)
	return math.floor(buffer.readu32(buf, (j * largeur + i) * 4) / 16777216)
end
local sil, ls, hs = Pixels.silhouette("jupe_trapeze_devant")
local lt, ht = Pixels.taillePiece("jupe_trapeze_devant")
U.verifier(ls == lt and hs == ht, "silhouette de la même taille que l'image de la pièce")
U.verifier(alpha(sil, ls, 2, 2) == 0, "hors de la pièce (coin coupé du trapèze) : transparent")
U.verifier(alpha(sil, ls, math.floor(ls * 0.25), math.floor(hs * 0.5)) == 170, "dans la pièce : papier translucide")
U.verifier(alpha(sil, ls, math.floor(ls / 2), math.floor(hs / 2)) == 255, "flèche de droit-fil au centre")
U.verifier(alpha(sil, ls, 1, hs - 2) == 255, "contour foncé au bord")
-- Pièce en biais : flèche en diagonale, pas de trait vertical au-dessus du centre
local silB, lb, hb = Pixels.silhouette("jupe_evasee_devant")
local cxB, cyB = math.floor(lb / 2), math.floor(hb / 2)
U.verifier(alpha(silB, lb, cxB + 20, cyB + 20) == 255, "pièce en biais : flèche en diagonale")
U.verifier(alpha(silB, lb, cxB, cyB - 40) == 170, "pièce en biais : pas de flèche verticale")
