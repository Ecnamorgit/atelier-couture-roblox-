-- Étiquettes (sous-projet 7) : au-delà des six styles, trois occasions et sept traits, notés de 0 à 100 comme les
-- styles.
-- · Occasions (Journée, Soirée, Travail) : elles s'additionnent comme les styles, points des variantes (K 1) et de la
--   matière des tissus (K 2, au prorata de la surface). Les décorations n'en portent pas.
-- · Légère / Chaude : un indice de chaleur dans [-1, 1] = 0,6 × chaleur de la matière (au prorata de la surface)
--   + 0,25 × (2 × manches − 1) + 0,15 × (2 × longueur − 1), où manches = hauteur de la manche / 5,6 dm (0 sans
--   manches) et longueur = (bas de la jupe − 6 dm) / 3 dm, bornée à [0, 1]. Chaude = 100 × l'indice s'il est
--   positif, Légère = 100 × son opposé s'il est négatif.
-- · Sobre / Travaillée : un indice de richesse dans [-1, 1] = (poids des pièces − 4) / 4 + décorations / 8 − 1,
--   chacun des deux termes borné à [0, 1] (un objet compte 1 décoration, une garniture 1 pour 5 dm, au prorata).
--   Travaillée = 100 × l'indice s'il est positif, Sobre = 100 × son opposé s'il est négatif.
-- · Unie / Fleurie / À motifs : la part de la surface dans un tissu uni, fleuri, ou à un autre motif (carreaux, pois,
--   rayures, dégradé), × 100.
-- Les points se décomposent par variante et par tissu (Etiquettes.variante, Etiquettes.tissu) : les commandes et le
-- carnet les additionnent sans rien construire.
local dossier = script.Parent
local Catalogue = require(dossier:WaitForChild("Catalogue"))
local Polygone = require(dossier:WaitForChild("Polygone"))
local Patron = require(dossier:WaitForChild("Patron"))

local Etiquettes = {}

Etiquettes.MANCHE_LONGUE = 5.6 -- dm : une manche de cette hauteur couvre tout le bras
Etiquettes.JUPE_COURTE = 6 -- dm : une jupe qui descend jusque-là est courte…
Etiquettes.JUPE_LONGUE = 9 -- … et longue jusque-là
Etiquettes.POIDS_SIMPLE = 4 -- poids des pièces d'une robe simple (corsage et jupe, deux pièces chacun)…
Etiquettes.POIDS_RICHE = 8 -- … et d'une robe riche
Etiquettes.DECORATIONS_PLEINES = 8 -- au-delà, une décoration de plus ne rend pas la robe plus travaillée
local PART_MATIERE, PART_MANCHES, PART_LONGUEUR = 0.6, 0.25, 0.15

local CLES_TISSU = { "chaleur", table.unpack(Catalogue.OCCASIONS) } -- ce qu'un tissu change, hors motif

-- Trait du motif d'un tissu : uni, fleuri, ou à motifs (tous les autres)
local TRAIT_MOTIF = { uni = "unie", fleurs = "fleurie" }
Etiquettes.MOTIFS = { "unie", "fleurie", "a_motifs" }

local function hauteur(idPiece)
	local b = Polygone.boite(Catalogue.piece(idPiece).contour)
	return b.maxY - b.minY
end

-- Ce qu'apporte chaque variante : { occasions = { [o] = points }, chaleur = son terme de l'indice, poids }
-- (les manches et la jupe portent la chaleur : chaque croquis a exactement une variante de chacune)
local VARIANTES = {}
for _, v in ipairs(Catalogue.Variantes) do
	local apport = { occasions = {}, chaleur = 0, poids = 0 }
	for _, o in ipairs(Catalogue.OCCASIONS) do
		apport.occasions[o] = Catalogue.K.pieces * (v.occasion[o] or 0)
	end
	local manche, bas = 0, 0
	for _, id in ipairs(v.pieces) do
		local def = Catalogue.piece(id)
		apport.poids += def.poids or 1
		if def.enroulement.type == "manche" then
			manche = math.max(manche, hauteur(id))
		elseif def.enroulement.type == "jupe" then
			bas = math.max(bas, (def.enroulement.depart or 0) + hauteur(id))
		end
	end
	if v.famille == "manches" then
		apport.chaleur = PART_MANCHES * (2 * math.min(manche / Etiquettes.MANCHE_LONGUE, 1) - 1)
	elseif v.famille == "jupe" then
		local longueur = math.clamp((bas - Etiquettes.JUPE_COURTE) / (Etiquettes.JUPE_LONGUE - Etiquettes.JUPE_COURTE), 0, 1)
		apport.chaleur = PART_LONGUEUR * (2 * longueur - 1)
	end
	VARIANTES[v.id] = apport
end

-- Ce qu'apporte chaque tissu, pour toute la robe dans ce tissu : { occasions, chaleur, motif = trait du motif }
local TISSUS = {}
for _, t in ipairs(Catalogue.Tissus) do
	local m = Catalogue.MATIERES[t.matiere]
	local apport = { occasions = {}, chaleur = PART_MATIERE * m.chaleur, motif = TRAIT_MOTIF[t.motif.type] or "a_motifs" }
	for _, o in ipairs(Catalogue.OCCASIONS) do
		apport.occasions[o] = Catalogue.K.tissu * (m.occasion[o] or 0)
	end
	TISSUS[t.id] = apport
end

function Etiquettes.variante(id)
	return VARIANTES[id]
end
function Etiquettes.tissu(id)
	return TISSUS[id]
end

-- Les deux traits d'un indice dans [-1, 1] : celui du côté positif (Chaude, Travaillée), puis l'autre (Légère, Sobre)
function Etiquettes.traitsIndice(indice)
	return math.clamp(100 * indice, 0, 100), math.clamp(-100 * indice, 0, 100)
end

-- Indice de richesse d'une robe : poids de ses pièces (Notation.poids), nombre de ses décorations
function Etiquettes.richesse(poids, decorations)
	local pieces = math.clamp((poids - Etiquettes.POIDS_SIMPLE) / (Etiquettes.POIDS_RICHE - Etiquettes.POIDS_SIMPLE), 0, 1)
	return pieces + math.clamp(decorations / Etiquettes.DECORATIONS_PLEINES, 0, 1) - 1
end

-- Nombre de décorations : accessoires = { { id, longueur? } } (un objet 1 ; une garniture 1 pour 5 dm, sans longueur 0)
function Etiquettes.decorations(accessoires)
	local n = 0
	for _, a in ipairs(accessoires or {}) do
		local def = Catalogue.accessoire(a.id)
		assert(def, "accessoire inconnu : " .. tostring(a.id))
		n += if def.genre == "garniture" then (a.longueur or 0) / 5 else 1
	end
	return n
end

-- entree = { croquis, tissus = { [idTissu] = aire }, accessoires = { { id, longueur? } } } (comme Notation.styles)
-- Retourne { occasions = { [occasion] = 0 à 100 }, traits = { [trait] = 0 à 100 } }
function Etiquettes.calculer(entree)
	local occasions, chaleur, poids = {}, 0, 0
	for _, o in ipairs(Catalogue.OCCASIONS) do
		occasions[o] = 0
	end
	for _, famille in ipairs(Catalogue.FAMILLES) do
		local a = VARIANTES[entree.croquis[famille]]
		for _, o in ipairs(Catalogue.OCCASIONS) do
			occasions[o] += a.occasions[o]
		end
		chaleur += a.chaleur
		poids += a.poids
	end
	local motifs = { unie = 0, fleurie = 0, a_motifs = 0 }
	local aireTotale = 0
	for _, aire in pairs(entree.tissus) do
		aireTotale += aire
	end
	if aireTotale > 0 then
		for idTissu, aire in pairs(entree.tissus) do
			local a, part = TISSUS[idTissu], aire / aireTotale
			for _, o in ipairs(Catalogue.OCCASIONS) do
				occasions[o] += a.occasions[o] * part
			end
			chaleur += a.chaleur * part
			motifs[a.motif] += 100 * part
		end
	end
	local traits = {}
	traits.chaude, traits.legere = Etiquettes.traitsIndice(chaleur)
	traits.travaillee, traits.sobre = Etiquettes.traitsIndice(Etiquettes.richesse(poids, Etiquettes.decorations(entree.accessoires)))
	for _, m in ipairs(Etiquettes.MOTIFS) do
		traits[m] = math.clamp(motifs[m], 0, 100)
	end
	for _, o in ipairs(Catalogue.OCCASIONS) do
		occasions[o] = math.clamp(occasions[o], 0, 100)
	end
	return { occasions = occasions, traits = traits }
end

-- Matière dominante (comme la teinte) : surfaces additionnées par matière ; à égalité, celle de la première pièce.
-- pieces = { { id, tissu } } dans l'ordre du croquis
function Etiquettes.matiereDominante(pieces)
	local parMatiere = {}
	for _, p in ipairs(pieces) do
		local m = Catalogue.tissu(p.tissu).matiere
		parMatiere[m] = (parMatiere[m] or 0) + Patron.aire(p.id)
	end
	local matiere, aireMax = nil, -1
	for _, p in ipairs(pieces) do
		local m = Catalogue.tissu(p.tissu).matiere
		if parMatiere[m] > aireMax + 1e-9 then
			matiere, aireMax = m, parMatiere[m]
		end
	end
	return matiere
end

-- Fourchette du carnet : { [occasion ou trait] = { min, max } } selon les tissus encore à choisir. choix = { [idPiece]
-- = idTissu ou nil } ; decorationsImposees : celles que la robe portera forcément (Etiquettes.decorations des
-- accessoires imposés), on peut en ajouter autant qu'on veut ; tissusOuverts (facultatif) : les pièces sans tissu ne
-- comptent que les tissus ouverts.
function Etiquettes.fourchette(croquis, choix, decorationsImposees, tissusOuverts)
	local base = { occasions = {}, chaleur = 0, poids = 0 }
	for _, o in ipairs(Catalogue.OCCASIONS) do
		base.occasions[o] = 0
	end
	for _, famille in ipairs(Catalogue.FAMILLES) do
		local a = VARIANTES[croquis[famille]]
		for _, o in ipairs(Catalogue.OCCASIONS) do
			base.occasions[o] += a.occasions[o]
		end
		base.chaleur += a.chaleur
		base.poids += a.poids
	end
	-- Les extrêmes d'un tissu encore à choisir
	local mini, maxi = { chaleur = math.huge }, { chaleur = -math.huge }
	local motifTous, motifUn = { unie = true, fleurie = true, a_motifs = true }, {}
	local aucun = true
	for _, o in ipairs(Catalogue.OCCASIONS) do
		mini[o], maxi[o] = math.huge, -math.huge
	end
	for _, t in ipairs(Catalogue.Tissus) do
		if not tissusOuverts or tissusOuverts[t.id] then
			aucun = false
			local a = TISSUS[t.id]
			for _, o in ipairs(Catalogue.OCCASIONS) do
				mini[o], maxi[o] = math.min(mini[o], a.occasions[o]), math.max(maxi[o], a.occasions[o])
			end
			mini.chaleur, maxi.chaleur = math.min(mini.chaleur, a.chaleur), math.max(maxi.chaleur, a.chaleur)
			motifUn[a.motif] = true
			for _, m in ipairs(Etiquettes.MOTIFS) do
				motifTous[m] = motifTous[m] and a.motif == m
			end
		end
	end
	if aucun then
		for cle in pairs(mini) do
			mini[cle], maxi[cle] = 0, 0
		end
		motifTous = {}
	end
	-- Chaque pièce, au prorata de sa surface
	local pieces = Patron.piecesDuCroquis(croquis)
	local aireTotale = 0
	for _, id in ipairs(pieces) do
		aireTotale += Patron.aire(id)
	end
	local bas, haut = { chaleur = base.chaleur }, { chaleur = base.chaleur }
	for _, o in ipairs(Catalogue.OCCASIONS) do
		bas[o], haut[o] = base.occasions[o], base.occasions[o]
	end
	for _, m in ipairs(Etiquettes.MOTIFS) do
		bas[m], haut[m] = 0, 0
	end
	for _, id in ipairs(pieces) do
		local part = Patron.aire(id) / aireTotale
		local a = choix[id] and TISSUS[choix[id]]
		for _, cle in ipairs(CLES_TISSU) do
			local v = if a then (if cle == "chaleur" then a.chaleur else a.occasions[cle]) else nil
			bas[cle] += (v or mini[cle]) * part
			haut[cle] += (v or maxi[cle]) * part
		end
		for _, m in ipairs(Etiquettes.MOTIFS) do
			if a then
				local dedans = if a.motif == m then 100 * part else 0
				bas[m] += dedans
				haut[m] += dedans
			else
				bas[m] += if motifTous[m] then 100 * part else 0
				haut[m] += if motifUn[m] then 100 * part else 0
			end
		end
	end
	local out = {}
	for _, o in ipairs(Catalogue.OCCASIONS) do
		out[o] = { min = math.clamp(bas[o], 0, 100), max = math.clamp(haut[o], 0, 100) }
	end
	for _, m in ipairs(Etiquettes.MOTIFS) do
		out[m] = { min = math.clamp(bas[m], 0, 100), max = math.clamp(haut[m], 0, 100) }
	end
	local chaudeBas, legereHaut = Etiquettes.traitsIndice(bas.chaleur)
	local chaudeHaut, legereBas = Etiquettes.traitsIndice(haut.chaleur)
	out.chaude, out.legere = { min = chaudeBas, max = chaudeHaut }, { min = legereBas, max = legereHaut }
	local travailleeBas, sobreHaut = Etiquettes.traitsIndice(Etiquettes.richesse(base.poids, decorationsImposees or 0))
	local travailleeHaut, sobreBas = Etiquettes.traitsIndice(Etiquettes.richesse(base.poids, Etiquettes.DECORATIONS_PLEINES))
	out.travaillee, out.sobre = { min = travailleeBas, max = travailleeHaut }, { min = sobreBas, max = sobreHaut }
	return out
end

return Etiquettes
