-- Sous-projet 7 : le portrait dessiné de chaque cliente. Un buste de face au crayon (128 × 160) : sa tenue, sa peau,
-- sa coiffure ; trois expressions (contente, neutre, déçue) qui ne changent que le visage ; toujours le même dessin.
local Pixels = U.module("Pixels")
local Clientes = U.module("Clientes")

local L, H = Pixels.PORTRAIT_LARGEUR, Pixels.PORTRAIT_HAUTEUR
local function rvb(c)
	return { math.floor(c.R * 255 + 0.5), math.floor(c.G * 255 + 0.5), math.floor(c.B * 255 + 0.5) }
end
local function pixel(buf, x, y)
	local v = buffer.readu32(buf, (y * L + x) * 4)
	return { v % 256, math.floor(v / 256) % 256, math.floor(v / 65536) % 256, math.floor(v / 16777216) % 256 }
end
local function egal(p, c)
	return p[1] == c[1] and p[2] == c[2] and p[3] == c[3] and p[4] == 255
end

-- Chaque cliente a une coiffure connue ; les sept coiffures servent
local coiffures, inconnues = {}, {}
for _, c in ipairs(Clientes.LISTE) do
	if table.find(Pixels.COIFFURES, c.coiffure) then
		coiffures[c.coiffure] = true
	else
		table.insert(inconnues, c.id)
	end
end
local nombre = 0
for _ in pairs(coiffures) do
	nombre += 1
end
U.verifier(#inconnues == 0 and nombre == #Pixels.COIFFURES, ("chaque cliente a sa coiffure, et les %d servent (inconnues : %s)"):format(#Pixels.COIFFURES, table.concat(inconnues, ", ")))

-- Le dessin : sa taille, le fond transparent, la tenue aux épaules, la peau au visage, les cheveux sur le front
local fautes = {}
local images = {}
for _, c in ipairs(Clientes.LISTE) do
	local buf, l, h = Pixels.portrait(c, "neutre")
	images[c.id] = buffer.tostring(buf)
	local ok = l == L and h == H and buffer.len(buf) == L * H * 4
		and pixel(buf, 1, 1)[4] == 0 and pixel(buf, L - 2, 2)[4] == 0
		and egal(pixel(buf, 30, 150), rvb(c.tenue.haut))
		and egal(pixel(buf, 64, 63), rvb(c.tenue.peau))
		and egal(pixel(buf, 64, 38), rvb(c.tenue.cheveux))
	if not ok then
		table.insert(fautes, c.id)
	end
end
U.verifier(#fautes == 0, "128 × 160, fond transparent ; tenue aux épaules, peau au visage, cheveux sur le front (en défaut : " .. table.concat(fautes, ", ") .. ")")
-- Chaque coiffure a sa forme : le chignon au-dessus de la tête, les cheveux longs derrière les épaules, le carré aux
-- joues, la tresse ramenée sur l'épaule, les boucles autour du front, la queue de cheval sur le côté ; les cheveux
-- courts laissent voir le fond
local POINTS = { chignon = { 64, 22 }, longs = { 32, 100 }, carre = { 32, 80 }, tresse = { 36, 88 }, boucles = { 31, 60 }, queue = { 97, 80 } }
local formes = {}
for _, c in ipairs(Clientes.LISTE) do
	local buf = Pixels.portrait(c, "neutre")
	local ok = if c.coiffure == "courts" then pixel(buf, 32, 80)[4] == 0 else egal(pixel(buf, POINTS[c.coiffure][1], POINTS[c.coiffure][2]), rvb(c.tenue.cheveux))
	if not ok then
		table.insert(formes, c.id .. " (" .. c.coiffure .. ")")
	end
end
U.verifier(#formes == 0, "chaque coiffure a sa forme (en défaut : " .. table.concat(formes, ", ") .. ")")
local memes = 0
for i, a in ipairs(Clientes.LISTE) do
	for j = i + 1, #Clientes.LISTE do
		memes += if images[a.id] == images[Clientes.LISTE[j].id] then 1 else 0
	end
end
U.verifier(memes == 0, "dix portraits, tous différents")

-- Toujours le même dessin ; trois expressions, différentes, qui ne touchent que le visage
local colette = Clientes.get("colette")
local expressions = {}
for _, e in ipairs(Pixels.EXPRESSIONS) do
	local buf = Pixels.portrait(colette, e)
	expressions[e] = buf
	U.verifier(buffer.tostring(buf) == buffer.tostring((Pixels.portrait(colette, e))), e .. " : toujours le même dessin")
end
local function differences(a, b)
	local n, horsVisage = 0, 0
	for y = 0, H - 1 do
		for x = 0, L - 1 do
			if buffer.readu32(a, (y * L + x) * 4) ~= buffer.readu32(b, (y * L + x) * 4) then
				n += 1
				if y < 50 or y > 95 or x < 40 or x > 88 then
					horsVisage += 1
				end
			end
		end
	end
	return n, horsVisage
end
local n1, hors1 = differences(expressions.contente, expressions.neutre)
local n2, hors2 = differences(expressions.neutre, expressions.decue)
local n3, hors3 = differences(expressions.contente, expressions.decue)
U.verifier(n1 > 20 and n2 > 20 and n3 > 20 and hors1 + hors2 + hors3 == 0, ("trois expressions différentes, sur le visage seulement (%d, %d, %d pixels)"):format(n1, n2, n3))
-- La bouche : un sourire (le milieu plus bas que les coins), un trait, une moue (le milieu plus haut)
local function crayon(buf, x, y)
	local p = pixel(buf, x, y)
	return p[4] == 255 and p[1] < 100 and p[2] < 90 and p[3] < 100
end
U.verifier(crayon(expressions.contente, 64, 90) and not crayon(expressions.contente, 64, 85), "contente : un sourire")
U.verifier(crayon(expressions.neutre, 64, 87) and not crayon(expressions.neutre, 64, 90), "neutre : un trait")
U.verifier(crayon(expressions.decue, 64, 85) and not crayon(expressions.decue, 64, 90), "déçue : une moue")

-- (relecture) Les traits du visage se lisent sur chaque peau : un contraste d'au moins 3 contre 1 (clairs sur une peau
-- foncée)
local function luminance(c)
	local function lin(v)
		v /= 255
		return if v <= 0.03928 then v / 12.92 else ((v + 0.055) / 1.055) ^ 2.4
	end
	return 0.2126 * lin(c[1]) + 0.7152 * lin(c[2]) + 0.0722 * lin(c[3])
end
local peuPlisibles = {}
for _, c in ipairs(Clientes.LISTE) do
	local buf = Pixels.portrait(c, "neutre")
	local bouche, peau = pixel(buf, 64, 87), rvb(c.tenue.peau)
	local a, b = luminance(bouche), luminance(peau)
	local contraste = (math.max(a, b) + 0.05) / (math.min(a, b) + 0.05)
	if contraste < 3 then
		table.insert(peuPlisibles, ("%s (%.1f)"):format(c.id, contraste))
	end
end
U.verifier(#peuPlisibles == 0, "les traits du visage se lisent sur chaque peau (en défaut : " .. table.concat(peuPlisibles, ", ") .. ")")
