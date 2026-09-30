# Aiguille & Dentelle — Plan 24 : les portraits des clientes

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Donner à chaque cliente un portrait dessiné au crayon (trois expressions), montré dans l'encadré de dialogue — donc avec son avis en étoiles — et dans le carnet d'adresses ; une illustration téléversée pourra le remplacer ; l'initiale si la mémoire des images est pleine.

**Architecture:** `Pixels.portrait(cliente, expression)` dessine le buste (128 × 160) d'après la tenue et la nouvelle `coiffure` de la fiche ; `Vignettes.portrait` le fige et le garde en cache ; un module client `Portrait` fait le médaillon (dessin, illustration du champ `image`, ou initiale) et choisit l'expression d'une parole ; `Dialogue`, `Scene`, `init.client` et `EcranAccueil` le montrent.

**Tech Stack:** Luau, Rojo 7.7.0-rc.1, simulation Luau 0.650 (`tests/lancer.sh`), Roblox Studio via le connecteur MCP Studio.

**Spec:** `docs/superpowers/specs/2026-09-30-robes-gouts-design.md` (section 4, « Portraits dessinés » ; plan 24 de la section 6 ; section 5, tests).

## Décisions de ce plan

- **Le dessin** : fond transparent ; les cheveux de derrière, puis les épaules dans le haut de la tenue (encolure ronde), la tresse ramenée devant, le cou, les oreilles, le visage dans la peau, les cheveux du front ; un contour au crayon entre les matières (comme le croquis du carnet). Sept coiffures : carré (frange droite), chignon, cheveux longs (derrière les épaules), courts, tresse, boucles, queue de cheval. Colette : boucles ; Margot et Maëlle : queue ; Salomé : tresse ; Hélène et Joséphine : chignon ; Inès et Capucine : longs ; Victoire : courts ; Apolline : carré.
- **Trois expressions** qui ne changent que le visage : contente (yeux rieurs, sourire, joues roses), neutre (yeux ronds, bouche droite), déçue (sourcils relevés au milieu, moue).
- **Quelle expression** : l'avis en étoiles (4 ou 5 : contente ; 2 ou 3 : neutre ; 1 : déçue), sinon ses mots (merci : contente ; déception : déçue), sinon neutre. Au carnet d'adresses : contente à partir d'une amitié de niveau 3.
- **L'avis** (spec : « dans l'avis, avec les étoiles ») : l'avis en étoiles paraît dans l'encadré de dialogue, où le portrait est désormais ; l'annonce de l'accueil reste une ligne de texte.
- **L'encadré** : le portrait (64 × 80) à gauche, le prénom, le texte et les étoiles à sa droite ; l'encadré est au moins aussi haut que le portrait. Sans cliente connue, comme avant.
- **Repli** : le champ `image` facultatif de la fiche (une illustration téléversée) remplace le dessin ; si la mémoire des images est pleine, l'initiale du prénom dans le médaillon. Le médaillon porte les attributs `Cliente` et `Expression`.
- **Vérifié pendant la préparation** : le plan a été joué entièrement sur un brouillon tiré de `main` ; huit variantes du brouillon échouent sur la vérification qui les garde. Dans Studio : les trente portraits dessinés en 0,57 s (19 ms chacun), vus à l'écran (les cheveux longs couvraient d'abord les épaules comme un bloc : passés derrière) ; deux encadrés vus avec leur portrait.

## Global Constraints

- **Dépôt** : `C:\dev\jeux\atelier-couture`, branche `portraits`, créée depuis `main` (où le plan 23 est fusionné). Selon les règles du commanditaire : la branche testée et relue est fusionnée dans `main` et poussée sur GitHub.
- **Rojo** : `C:/dev/jeux/roblox-maker/rojo.exe`.
- **Contenu original** : aucun nom, texte, image ni son de *Dressmaker* ; les portraits sont dessinés par le code.
- **Contraintes des plans précédents toujours valables** : fins de ligne LF, commits en français terminés par `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`, textes d'au moins 14 px (et aucun texte laissé à « Label »), le serveur fait foi.

## Review Focus

- **La mémoire des images pleine (téléphone).** Attendu : l'initiale dans le médaillon, jamais une erreur ni un cadre vide. Test : `77_portraits_ecrans`.
- **Une cliente sans fiche (« La cliente »).** Attendu : pas de portrait, l'encadré comme avant. Test : `77_portraits_ecrans`.
- **Une longue réplique avec cinq étoiles.** Attendu : texte et étoiles à droite du portrait, dans l'encadré. Test : `77_portraits_ecrans`, scénario.
- **Le carnet d'adresses à dix clientes.** Attendu : un portrait par ligne, la liste défile comme avant. Test : scénario.
- **Le même portrait demandé souvent (chaque parole).** Attendu : dessiné une fois par expression, puis en cache. Test : Studio (tâche 3).

---

### Task 1: Le dessin

**Files:**
- Create: `tests/unitaires/76_portraits.luau`
- Modify: `src/shared/Clientes.luau`, `src/shared/Pixels.luau`, `src/client/Atelier/Vignettes.luau`

**Interfaces:**
- Consumes: la `tenue` de chaque cliente (existante : peau, haut, cheveux), `CRAYON` et `empaqueter` de `Pixels` (existants).
- Produces: le champ `coiffure` de chaque cliente ; `Pixels.PORTRAIT_LARGEUR` (128), `Pixels.PORTRAIT_HAUTEUR` (160), `Pixels.EXPRESSIONS`, `Pixels.COIFFURES`, `Pixels.portrait(cliente, expression)` → buffer, largeur, hauteur ; `Vignettes.portrait(idCliente, expression)` → contenu ou nil.

- [ ] **Step 1: Écrire les tests**

Créer `tests/unitaires/76_portraits.luau` :

```lua
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
```

- [ ] **Step 2: Lancer les tests, vérifier l'échec**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT|attempt|membre|argument" | head -3`
Expected: échec : une ligne qui finit par `invalid argument #1 to 'find' (table expected, got nil)`

- [ ] **Step 3: Coiffures, portrait, vignette**

Dans `src/shared/Clientes.luau`, remplacer :

```lua
-- Clientes : les dix clientes qui reviennent à l'atelier (contenu original, rien de Dressmaker). Chacune a ses
-- vraies mesures (dm, proches de sa taille), ses styles, sa teinte et (sous-projet 7) son occasion préférés (ses
-- commandes en viennent), sa tenue, ses répliques, le prestige qu'il faut pour qu'elle vienne, et ce que son amitié
-- ouvre (sous-projet 2).
```

par :

```lua
-- Clientes : les dix clientes qui reviennent à l'atelier (contenu original, rien de Dressmaker). Chacune a ses
-- vraies mesures (dm, proches de sa taille), ses styles, sa teinte et (sous-projet 7) son occasion préférés (ses
-- commandes en viennent), sa tenue, ses répliques, le prestige qu'il faut pour qu'elle vienne, et ce que son amitié
-- ouvre (sous-projet 2). Sous-projet 7 : sa coiffure (son portrait, voir Pixels.portrait) ; un champ image facultatif
-- (une illustration téléversée) remplacerait le dessin.
```

Dans `src/shared/Clientes.luau`, remplacer :

```lua
		teinte = "rose",
		occasion = "soiree",
```

par :

```lua
		teinte = "rose",
		occasion = "soiree",
		coiffure = "boucles",
```

Dans `src/shared/Clientes.luau`, remplacer :

```lua
		teinte = "jaune",
		occasion = "journee",
```

par :

```lua
		teinte = "jaune",
		occasion = "journee",
		coiffure = "queue",
```

Dans `src/shared/Clientes.luau`, remplacer :

```lua
		teinte = "vert",
		occasion = "journee",
```

par :

```lua
		teinte = "vert",
		occasion = "journee",
		coiffure = "tresse",
```

Dans `src/shared/Clientes.luau`, remplacer :

```lua
		teinte = "blanc",
		occasion = "soiree",
```

par :

```lua
		teinte = "blanc",
		occasion = "soiree",
		coiffure = "chignon",
```

Dans `src/shared/Clientes.luau`, remplacer :

```lua
		teinte = "noir",
		occasion = "soiree",
```

par :

```lua
		teinte = "noir",
		occasion = "soiree",
		coiffure = "longs",
```

Dans `src/shared/Clientes.luau`, remplacer :

```lua
		teinte = "bleu",
		occasion = "travail",
```

par :

```lua
		teinte = "bleu",
		occasion = "travail",
		coiffure = "courts",
```

Dans `src/shared/Clientes.luau`, remplacer :

```lua
		teinte = "violet",
		occasion = "journee",
```

par :

```lua
		teinte = "violet",
		occasion = "journee",
		coiffure = "carre",
```

Dans `src/shared/Clientes.luau`, remplacer :

```lua
		teinte = "brun",
		occasion = "travail",
```

par :

```lua
		teinte = "brun",
		occasion = "travail",
		coiffure = "chignon",
```

Dans `src/shared/Clientes.luau`, remplacer :

```lua
		teinte = "rouge",
		occasion = "soiree",
```

par :

```lua
		teinte = "rouge",
		occasion = "soiree",
		coiffure = "longs",
```

Dans `src/shared/Clientes.luau`, remplacer :

```lua
		teinte = "bleu",
		occasion = "journee",
```

par :

```lua
		teinte = "bleu",
		occasion = "journee",
		coiffure = "queue",
```

Dans `src/shared/Pixels.luau`, remplacer :

```lua
	return buf, largeur, hauteur
end

return Pixels
```

par :

```lua
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
```

Dans `src/client/Atelier/Vignettes.luau`, remplacer :

```lua
local Patron = require(Couture:WaitForChild("Patron"))
```

par :

```lua
local Patron = require(Couture:WaitForChild("Patron"))
local Clientes = require(Couture:WaitForChild("Clientes"))
```

Dans `src/client/Atelier/Vignettes.luau`, remplacer :

```lua
-- Oublie les images des pièces découpées
```

par :

```lua
-- Portrait d'une cliente (sous-projet 7), selon son expression (« contente », « neutre », « decue »)
function Vignettes.portrait(idCliente, expression)
	return figer("portrait:" .. idCliente .. ":" .. expression, function()
		return Pixels.portrait(Clientes.get(idCliente), expression)
	end)
end

-- Oublie les images des pièces découpées
```

- [ ] **Step 4: Lancer les tests**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT"`
Expected:
```
Unitaires : 269400 vérifications
TOUT EST VERT : 1014 vérifications
```

- [ ] **Step 5: Commit**

```bash
git add src/shared/Clientes.luau src/shared/Pixels.luau src/client/Atelier/Vignettes.luau tests/unitaires/76_portraits.luau
git commit -m "Portraits : chaque cliente dessinée au crayon, sa coiffure, trois expressions

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 2: Les portraits à l'écran

**Files:**
- Create: `src/client/Atelier/Portrait.luau`, `tests/unitaires/77_portraits_ecrans.luau`
- Modify: `src/client/Atelier/Dialogue.luau`, `src/client/Atelier/Scene.luau`, `src/client/Atelier/init.client.luau`, `src/client/Atelier/EcranAccueil.luau`, `tests/scenario.luau`

**Interfaces:**
- Consumes: `Vignettes.portrait`, `coiffure` (Task 1) ; `Clientes.get`, les répliques `merci` et `deception` (existantes).
- Produces: `Portrait.expression(fiche, texte, etoiles)` → "contente" | "neutre" | "decue" ; `Portrait.creer(UiKit, props)` → médaillon (`Image`, `Initiale`) ; `Portrait.maj(cadre, idCliente, expression)` ; `Dialogue:dire(nom, texte, etoiles, idCliente)` ; `Dialogue.PORTRAIT` ; `Scene.surParole(prénom, texte, étoiles, idCliente)` ; au carnet d'adresses, `Portrait_<id>`.

- [ ] **Step 1: Écrire les tests**

Créer `tests/unitaires/77_portraits_ecrans.luau` :

```lua
-- Sous-projet 7 : le portrait de la cliente dans l'encadré de dialogue (selon ce qu'elle dit, et son avis en étoiles) ;
-- son illustration si sa fiche en a une ; son initiale dans un médaillon si la mémoire des images est pleine.
local UiKit = U.module("UiKit")
local Dialogue = U.module("Dialogue")
local Portrait = U.module("Portrait")
local Vignettes = U.module("Vignettes")
local Clientes = U.module("Clientes")

local colette = Clientes.get("colette")
U.verifier(Portrait.expression(colette, colette.repliques.merci) == "contente" and Portrait.expression(colette, colette.repliques.deception) == "decue" and Portrait.expression(colette, colette.repliques.arrivee) == "neutre", "l'expression suit ses mots : merci (contente), déception (déçue), le reste (neutre)")
U.verifier(Portrait.expression(colette, "…", 5) == "contente" and Portrait.expression(colette, "…", 4) == "contente" and Portrait.expression(colette, "…", 3) == "neutre" and Portrait.expression(colette, "…", 2) == "neutre" and Portrait.expression(colette, "…", 1) == "decue", "son avis : 4 ou 5 étoiles contente, 2 ou 3 neutre, 1 déçue")

local gui = Instance.new("ScreenGui")
local d = Dialogue.nouveau(gui, UiKit)
local cadre = gui.Dialogue
local portrait = cadre.Portrait
d:dire("Colette", "Bonjour !", nil, "colette")
U.verifier(portrait.Visible and portrait:GetAttribute("Cliente") == "colette" and portrait:GetAttribute("Expression") == "neutre" and (portrait.Image.Visible or portrait.Initiale.Visible), "l'encadré montre son portrait, neutre")
U.verifier(cadre.Texte.Position.X.Offset >= Dialogue.PORTRAIT.X + 14 and cadre.Nom.Position.X.Offset == cadre.Texte.Position.X.Offset and cadre.Size.Y.Offset >= Dialogue.PORTRAIT.Y + 20, "son nom et ses mots à droite du portrait, qui tient dans l'encadré")
d:dire("Colette", colette.repliques.merci, 5, "colette")
U.verifier(portrait:GetAttribute("Expression") == "contente" and cadre.Etoiles.Position.X.Offset >= Dialogue.PORTRAIT.X + 10, "cinq étoiles : contente ; les étoiles aussi à droite du portrait")
d:dire("Colette", colette.repliques.deception, 1, "colette")
U.verifier(portrait:GetAttribute("Expression") == "decue", "une étoile : déçue")
d:dire("La cliente", "Bonjour.")
U.verifier(not portrait.Visible and cadre.Texte.Position.X.Offset < 20, "sans cliente connue : pas de portrait, le texte à gauche")

-- Le dessin (dans la simulation, la mémoire des images répond) ; mémoire pleine : l'initiale ; une illustration
d:dire("Colette", "Bonjour !", nil, "colette")
U.verifier(portrait.Image.Visible and not portrait.Initiale.Visible, "le dessin au crayon")
local portraitDessin = Vignettes.portrait
Vignettes.portrait = function()
	return nil
end
d:dire("Colette", "Encore moi !", nil, "colette")
Vignettes.portrait = portraitDessin
U.verifier(not portrait.Image.Visible and portrait.Initiale.Visible and portrait.Initiale.Text == "C" and portrait.Initiale.TextSize >= 14, "mémoire des images pleine : l'initiale, « C »")
colette.image = "rbxassetid://123456"
d:dire("Colette", "Et avec mon illustration ?", nil, "colette")
colette.image = nil
U.verifier(portrait.Image.Visible and portrait.Image.Image == "rbxassetid://123456", "une illustration dans sa fiche remplace le dessin")
```

Dans `tests/scenario.luau`, remplacer :

```lua
	verifier(dialogue ~= nil and dialogue.Visible and dialogue.Nom.Text == "Colette" and dialogue.Texte.Text == Clientes.get("colette").repliques.presentation and not clienteMesuree.Head.Bulle.Enabled, "fenêtre ouverte : elle se présente dans l'encadré, à son nom, pas dans sa bulle")
```

par :

```lua
	verifier(dialogue ~= nil and dialogue.Visible and dialogue.Nom.Text == "Colette" and dialogue.Texte.Text == Clientes.get("colette").repliques.presentation and not clienteMesuree.Head.Bulle.Enabled, "fenêtre ouverte : elle se présente dans l'encadré, à son nom, pas dans sa bulle")
	verifier(dialogue.Portrait.Visible and dialogue.Portrait:GetAttribute("Cliente") == "colette" and dialogue.Portrait:GetAttribute("Expression") == "neutre", "(sous-projet 7) son portrait dans l'encadré, neutre")
```

Dans `tests/scenario.luau`, remplacer :

```lua
	verifier(gui.Atelier.Dialogue.Visible and gui.Atelier.Dialogue.Texte.Text == Clientes.get("colette").repliques.deception and etoiles.Visible and etoiles.Etoile1.TextColor3 == OR and etoiles.Etoile2.TextColor3 ~= OR, "robe refusée : sa déception dans l'encadré, une étoile")
```

par :

```lua
	verifier(gui.Atelier.Dialogue.Visible and gui.Atelier.Dialogue.Texte.Text == Clientes.get("colette").repliques.deception and etoiles.Visible and etoiles.Etoile1.TextColor3 == OR and etoiles.Etoile2.TextColor3 ~= OR, "robe refusée : sa déception dans l'encadré, une étoile")
	verifier(gui.Atelier.Dialogue.Portrait:GetAttribute("Expression") == "decue", "(sous-projet 7) son portrait, déçue")
```

Dans `tests/scenario.luau`, remplacer :

```lua
verifier(texte("Colette Marchand — amitié niveau 5") ~= nil and fenetre.Contenu.CarnetAdresses:FindFirstChild("Adresse_margot") == nil, "carnet d'adresses : Colette, pas encore Margot")
```

par :

```lua
verifier(texte("Colette Marchand — amitié niveau 5") ~= nil and fenetre.Contenu.CarnetAdresses:FindFirstChild("Adresse_margot") == nil, "carnet d'adresses : Colette, pas encore Margot")
do -- (sous-projet 7) son portrait, contente (amitié de niveau 5), à gauche de sa ligne
	local medaillon = fenetre.Contenu.CarnetAdresses.Liste:FindFirstChild("Portrait_colette")
	local ligne = fenetre.Contenu.CarnetAdresses.Liste.Adresse_colette
	verifier(medaillon ~= nil and medaillon.Visible and medaillon:GetAttribute("Expression") == "contente" and ligne.Position.X.Offset >= medaillon.Size.X.Offset, "carnet d'adresses : le portrait de Colette, contente, devant sa ligne")
end
```

- [ ] **Step 2: Lancer les tests, vérifier l'échec**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT|attempt|membre" | head -3`
Expected: échec : une ligne qui finit par `Portrait n'est pas un membre valide de Folder « Couture »`

- [ ] **Step 3: Le médaillon, l'encadré, le carnet d'adresses**

Créer `src/client/Atelier/Portrait.luau` :

```lua
-- Portrait (sous-projet 7) : le portrait d'une cliente dans un médaillon — l'illustration de sa fiche si elle en a une
-- (champ image), sinon son dessin au crayon (Vignettes.portrait) ; si la mémoire des images est pleine, l'initiale de
-- son prénom. Le médaillon porte les attributs « Cliente » et « Expression » de ce qu'il montre.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Couture = ReplicatedStorage:WaitForChild("Couture")
local Clientes = require(Couture:WaitForChild("Clientes"))
local Vignettes = require(script.Parent:WaitForChild("Vignettes"))

local Portrait = {}
Portrait.FOND = Color3.fromRGB(245, 236, 226)

-- L'expression d'une parole : l'avis en étoiles (4 ou 5 : contente ; 2 ou 3 : neutre ; 1 : déçue), sinon ses mots de
-- remerciement (contente) ou de déception (déçue), sinon neutre
function Portrait.expression(fiche, texte, etoiles)
	if etoiles then
		return if etoiles >= 4 then "contente" elseif etoiles <= 1 then "decue" else "neutre"
	elseif fiche and texte == fiche.repliques.merci then
		return "contente"
	elseif fiche and texte == fiche.repliques.deception then
		return "decue"
	end
	return "neutre"
end

-- Un médaillon vide ; props : Name, Position, Size, ZIndex, Parent (comme un cadre de UiKit)
function Portrait.creer(UiKit, props)
	local cadre = UiKit.arrondir(UiKit.creer("Frame", props), 8)
	cadre.BackgroundColor3 = Portrait.FOND
	cadre.Visible = false
	UiKit.creer("ImageLabel", { Name = "Image", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Visible = false, ZIndex = cadre.ZIndex + 1, Parent = cadre })
	UiKit.texte({
		Name = "Initiale",
		Text = "",
		Font = Enum.Font.GothamBold,
		TextSize = math.max(14, math.floor(cadre.Size.Y.Offset * 0.45)),
		TextColor3 = UiKit.COULEURS.accent,
		TextXAlignment = Enum.TextXAlignment.Center,
		Size = UDim2.fromScale(1, 1),
		Visible = false,
		ZIndex = cadre.ZIndex + 1,
		Parent = cadre,
	})
	return cadre
end

-- Montre cette cliente, avec cette expression (idCliente nil ou inconnue : le médaillon se cache)
function Portrait.maj(cadre, idCliente, expression)
	local fiche = idCliente and Clientes.get(idCliente)
	expression = expression or "neutre"
	cadre.Visible = fiche ~= nil
	cadre.Image.Visible, cadre.Initiale.Visible = false, false
	cadre:SetAttribute("Cliente", fiche and fiche.id)
	cadre:SetAttribute("Expression", fiche and expression)
	if not fiche then
		return
	end
	if fiche.image then
		cadre.Image.Image = fiche.image
		cadre.Image.Visible = true
		return
	end
	local contenu = Vignettes.portrait(fiche.id, expression)
	if contenu then
		cadre.Image.ImageContent = contenu
		cadre.Image.Visible = true
	else
		cadre.Initiale.Text = string.sub(fiche.nom, 1, 1)
		cadre.Initiale.Visible = true
	end
end

return Portrait
```

Dans `src/client/Atelier/Dialogue.luau`, remplacer :

```lua
-- Roblox, par-dessus la fenêtre : il s'efface alors seul après quelques secondes. Un appui le referme jusqu'à sa
-- prochaine parole.
local Dialogue = {}
```

par :

```lua
-- Roblox, par-dessus la fenêtre : il s'efface alors seul après quelques secondes. Un appui le referme jusqu'à sa
-- prochaine parole. Sous-projet 7 : son portrait à gauche, selon ce qu'elle dit (contente, neutre, déçue).
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Clientes = require(ReplicatedStorage:WaitForChild("Couture"):WaitForChild("Clientes"))
local Portrait = require(script.Parent:WaitForChild("Portrait"))

local Dialogue = {}
```

Dans `src/client/Atelier/Dialogue.luau`, remplacer :

```lua
local HAUT_TEXTE = 30 -- sous le prénom
local HAUTEUR_ETOILES = 28
```

par :

```lua
local HAUT_TEXTE = 30 -- sous le prénom
local HAUTEUR_ETOILES = 28
Dialogue.PORTRAIT = Vector2.new(64, 80) -- (sous-projet 7) le portrait, à gauche du texte
```

Dans `src/client/Atelier/Dialogue.luau`, remplacer :

```lua
	self.etoiles = UiKit.creer("Frame", { Name = "Etoiles", BackgroundTransparency = 1, Size = UDim2.fromOffset(5 * 28, HAUTEUR_ETOILES), Visible = false, ZIndex = 41, Parent = self.cadre })
```

par :

```lua
	self.etoiles = UiKit.creer("Frame", { Name = "Etoiles", BackgroundTransparency = 1, Size = UDim2.fromOffset(5 * 28, HAUTEUR_ETOILES), Visible = false, ZIndex = 41, Parent = self.cadre })
	self.portrait = Portrait.creer(UiKit, { Name = "Portrait", Position = UDim2.fromOffset(MARGE, 10), Size = UDim2.fromOffset(Dialogue.PORTRAIT.X, Dialogue.PORTRAIT.Y), ZIndex = 41, Parent = self.cadre })
```

Dans `src/client/Atelier/Dialogue.luau`, remplacer :

```lua
-- La cliente dit ce texte (nil : plus rien à dire) ; etoiles : son avis (1 à 5), ou nil
function Dialogue:dire(nom, texte, etoiles)
```

par :

```lua
-- La cliente dit ce texte (nil : plus rien à dire) ; etoiles : son avis (1 à 5), ou nil ; idCliente (facultatif) : son
-- portrait
function Dialogue:dire(nom, texte, etoiles, idCliente)
```

Dans `src/client/Atelier/Dialogue.luau`, remplacer :

```lua
	if texte then
		local hauteurTexte = self.UiKit.lignes(texte, Dialogue.LARGEUR - 2 * MARGE, Dialogue.TAILLE_TEXTE) * (Dialogue.TAILLE_TEXTE + 4)
		self.nom.Text = nom or ""
		self.texte.Text = texte
		self.texte.Size = UDim2.new(1, -2 * MARGE, 0, hauteurTexte)
		self.etoiles.Visible = etoiles ~= nil
		self.etoiles.Position = UDim2.fromOffset(MARGE - 2, HAUT_TEXTE + hauteurTexte + 2)
		for k = 1, 5 do
			self.etoiles["Etoile" .. k].TextColor3 = if etoiles and k <= etoiles then Dialogue.OR else Dialogue.ETEINTE
		end
		self.cadre.Size = UDim2.fromOffset(Dialogue.LARGEUR, HAUT_TEXTE + hauteurTexte + (if etoiles then HAUTEUR_ETOILES + 4 else 0) + 10)
	end
```

par :

```lua
	if texte then
		local fiche = idCliente and Clientes.get(idCliente)
		Portrait.maj(self.portrait, fiche and fiche.id, Portrait.expression(fiche, texte, etoiles))
		local gauche = if fiche then MARGE + Dialogue.PORTRAIT.X + 10 else MARGE
		local hauteurTexte = self.UiKit.lignes(texte, Dialogue.LARGEUR - gauche - MARGE, Dialogue.TAILLE_TEXTE) * (Dialogue.TAILLE_TEXTE + 4)
		self.nom.Text = nom or ""
		self.nom.Position, self.nom.Size = UDim2.fromOffset(gauche, 8), UDim2.new(1, -gauche - MARGE, 0, 20)
		self.texte.Text = texte
		self.texte.Position = UDim2.fromOffset(gauche, HAUT_TEXTE)
		self.texte.Size = UDim2.new(1, -gauche - MARGE, 0, hauteurTexte)
		self.etoiles.Visible = etoiles ~= nil
		self.etoiles.Position = UDim2.fromOffset(gauche - 2, HAUT_TEXTE + hauteurTexte + 2)
		for k = 1, 5 do
			self.etoiles["Etoile" .. k].TextColor3 = if etoiles and k <= etoiles then Dialogue.OR else Dialogue.ETEINTE
		end
		local hauteur = HAUT_TEXTE + hauteurTexte + (if etoiles then HAUTEUR_ETOILES + 4 else 0) + 10
		if fiche then
			hauteur = math.max(hauteur, 10 + Dialogue.PORTRAIT.Y + 10)
		end
		self.cadre.Size = UDim2.fromOffset(Dialogue.LARGEUR, hauteur)
	end
```

Dans `src/client/Atelier/Scene.luau`, remplacer :

```lua
-- l'encadré de dialogue de l'interface, surParole(prénom, texte, étoiles ou nil), prévenu quand elle dit autre chose
```

par :

```lua
-- l'encadré de dialogue de l'interface, surParole(prénom, texte, étoiles ou nil, identifiant de la cliente ou nil : son
-- portrait), prévenu quand elle dit autre chose
```

Dans `src/client/Atelier/Scene.luau`, remplacer :

```lua
			self.surParole(if fiche then fiche.nom:match("^(%S+)") else "La cliente", texte, etoiles)
```

par :

```lua
			self.surParole(if fiche then fiche.nom:match("^(%S+)") else "La cliente", texte, etoiles, fiche and fiche.id)
```

Dans `src/client/Atelier/init.client.luau`, remplacer :

```lua
scene.surParole = function(nom, texte, etoiles)
	dialogue:dire(nom, texte, etoiles)
end
```

par :

```lua
scene.surParole = function(nom, texte, etoiles, idCliente)
	dialogue:dire(nom, texte, etoiles, idCliente)
end
```

Dans `src/client/Atelier/EcranAccueil.luau`, remplacer :

```lua
local Mercerie = require(script.Parent:WaitForChild("Mercerie"))
```

par :

```lua
local Mercerie = require(script.Parent:WaitForChild("Mercerie"))
local Portrait = require(script.Parent:WaitForChild("Portrait"))
```

Dans `src/client/Atelier/EcranAccueil.luau`, remplacer :

```lua
			UiKit.texte({
				Name = "Adresse_" .. v.cliente.id,
				Text = ("%s — amitié niveau %d (%s) · %s"):format(v.cliente.nom, niveau, points, ouvre),
				TextSize = 16,
				Position = UDim2.fromOffset(0, 4 + (k - 1) * 34),
				Size = UDim2.new(1, -14, 0, 30),
				ZIndex = 21,
				Parent = liste,
			})
```

par :

```lua
			-- (sous-projet 7) son portrait : contente à partir d'une amitié de niveau 3
			local medaillon = Portrait.creer(UiKit, { Name = "Portrait_" .. v.cliente.id, Position = UDim2.fromOffset(0, 2 + (k - 1) * 34), Size = UDim2.fromOffset(24, 30), ZIndex = 21, Parent = liste })
			Portrait.maj(medaillon, v.cliente.id, if niveau >= 3 then "contente" else "neutre")
			UiKit.texte({
				Name = "Adresse_" .. v.cliente.id,
				Text = ("%s — amitié niveau %d (%s) · %s"):format(v.cliente.nom, niveau, points, ouvre),
				TextSize = 16,
				Position = UDim2.fromOffset(30, 4 + (k - 1) * 34),
				Size = UDim2.new(1, -44, 0, 30),
				ZIndex = 21,
				Parent = liste,
			})
```

- [ ] **Step 4: Lancer les tests**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT"`
Expected:
```
Unitaires : 269410 vérifications
TOUT EST VERT : 1017 vérifications
```

- [ ] **Step 5: Commit**

```bash
git add src/client/Atelier/Portrait.luau src/client/Atelier/Dialogue.luau src/client/Atelier/Scene.luau src/client/Atelier/init.client.luau src/client/Atelier/EcranAccueil.luau tests/unitaires/77_portraits_ecrans.luau tests/scenario.luau
git commit -m "Portraits : dans l'encadré de dialogue (selon ses mots et son avis) et dans le carnet d'adresses ; l'illustration ou l'initiale à défaut du dessin

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 3: Studio, README, lieu régénéré

**Files:**
- Modify: `README.md`, `AtelierCouture.rbxl` (régénéré)

**Interfaces:**
- Consumes: tout ce qui précède.
- Produces: rien de nouveau.

- [ ] **Step 1: Dans Studio, par le connecteur MCP**

Construire le lieu du dépôt dans un dossier temporaire (`C:/dev/jeux/roblox-maker/rojo.exe build -o <dossier temporaire>/Plan24Depot.rbxl`) et l'ouvrir dans Studio. En édition (`execute_luau`, Edit) : dans un `ScreenGui` d'essai de `StarterGui`, poser trente médaillons (96 × 120 : dix clientes, trois expressions), mesurer (`os.clock`) le premier passage puis un second passage sur les mêmes portraits, et les regarder (`screen_capture`) ; puis deux encadrés de dialogue (Inès, son merci et cinq étoiles ; Colette, une longue réplique) et les regarder ; supprimer le `ScreenGui`. Enfin en Play : attendre 4 s, relever la console.

Expected : trente portraits dessinés (aucune initiale), chaque coiffure reconnaissable, trois expressions distinctes, les cheveux longs derrière les épaules ; le second passage bien plus rapide que le premier (cache) ; dans l'encadré, le portrait à gauche, le texte et les étoiles à sa droite ; aucune alerte de notre code (« Lieu non publié » et les messages internes de Roblox mis à part). Arrêter Play et fermer cette fenêtre de Studio (sans enregistrer).

- [ ] **Step 2: Mettre à jour le README**

Dans `README.md`, remplacer :

```markdown
## État actuel (sous-projet 7 en cours, plans 19 à 23 : des robes plus riches, à couches ; seize étiquettes)
```

par :

```markdown
## État actuel (sous-projet 7, plans 19 à 24 : des robes plus riches, à couches ; seize étiquettes ; les portraits des clientes)
```

Dans `README.md`, remplacer :

```markdown
   encadré à son prénom, en haut à gauche de l'écran (un appui le referme jusqu'à sa prochaine parole) ;
   fenêtre fermée, dans une bulle au-dessus de sa tête.
```

par :

```markdown
   encadré à son prénom, en haut à gauche de l'écran (un appui le referme jusqu'à sa prochaine parole), avec son
   **portrait** dessiné au crayon (sa coiffure, sa tenue ; contente, neutre ou déçue selon ce qu'elle dit et son
   avis ; une illustration téléversée pourra le remplacer, l'initiale de son prénom si la mémoire des images est
   pleine) ; fenêtre fermée, dans une bulle au-dessus de sa tête.
```

Dans `README.md`, remplacer :

```markdown
   **Carnet d'adresses** : les clientes déjà venues, leur niveau d'amitié (points et seuil suivant) et ce que
   le prochain niveau ouvrira ; la liste défile.
```

par :

```markdown
   **Carnet d'adresses** : les clientes déjà venues, leur portrait (contente à partir d'une amitié de niveau 3),
   leur niveau d'amitié (points et seuil suivant) et ce que le prochain niveau ouvrira ; la liste défile.
```

Dans `README.md`, remplacer :

```markdown
  | `Croquis`, `Pixels` | Dessin de face de chaque modèle (formes des parties, plis, mannequin) ; motifs de tissu, découpe exacte de l'image d'une pièce, silhouette du patron, croquis colorié du carnet |
```

par :

```markdown
  | `Croquis`, `Pixels` | Dessin de face de chaque modèle (formes des parties, plis, mannequin) ; motifs de tissu, découpe exacte de l'image d'une pièce, silhouette du patron, croquis colorié du carnet, portrait au crayon de chaque cliente |
```

Dans `README.md`, remplacer :

```markdown
  l'avatar de la cliente et sa bulle ; `Dialogue`, l'encadré où elle parle fenêtre ouverte ; `Confettis`, la
```

par :

```markdown
  l'avatar de la cliente et sa bulle ; `Dialogue`, l'encadré où elle parle fenêtre ouverte ; `Portrait`, son
  médaillon (dessin, illustration ou initiale) ; `Confettis`, la
```

- [ ] **Step 3: Tests, lieu régénéré, commit**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT"`
Expected:
```
Unitaires : 269410 vérifications
TOUT EST VERT : 1017 vérifications
```

```bash
C:/dev/jeux/roblox-maker/rojo.exe build -o AtelierCouture.rbxl
git add README.md AtelierCouture.rbxl
git commit -m "Plan 24 terminé : les portraits des clientes

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```
