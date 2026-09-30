-- Commandes : génère des commandes, toujours réalisables avec le catalogue. Celle d'une cliente (sous-projet 2)
-- vient de ses goûts : un de ses styles, sa teinte, (sous-projet 7) son occasion, jamais un « au plus » dans ses
-- styles ; elle est réalisable avec ce que le joueur a ouvert (déblocages), et ses exigences montent avec son
-- prestige : les occasions à partir du prestige 2, la matière au 3, les traits au 4.
local dossier = script.Parent
local Catalogue = require(dossier:WaitForChild("Catalogue"))
local Notation = require(dossier:WaitForChild("Notation"))
local Deblocages = require(dossier:WaitForChild("Deblocages"))
local Progression = require(dossier:WaitForChild("Progression"))
local Etiquettes = require(dossier:WaitForChild("Etiquettes"))

local Commandes = {}

local NOMS_TAILLES = { "S", "M", "L" }
Commandes.ESSAIS = 30 -- tirages avant le repli

-- Les points s'additionnent (Notation.styles, Etiquettes) : ceux de chaque variante et de chaque tissu (toute la
-- robe dans ce tissu), styles, occasions, chaleur et poids des pièces, sont calculés une fois ; une robe candidate
-- se juge alors en quelques additions, sans rien créer. (Une garniture imposée, sans longueur, ne compte pas : comme
-- dans Notation.styles.)
local K = Catalogue.K
local CLES = table.clone(Catalogue.STYLES)
for _, o in ipairs(Catalogue.OCCASIONS) do
	table.insert(CLES, o)
end
table.insert(CLES, "chaleur")
table.insert(CLES, "poids")
local function zero()
	local t = {}
	for _, c in ipairs(CLES) do
		t[c] = 0
	end
	return t
end
local APPORTS_VARIANTES, APPORTS_TISSUS = {}, {}
for _, v in ipairs(Catalogue.Variantes) do
	local e, a = Etiquettes.variante(v.id), zero()
	for s, pts in pairs(v.style) do
		a[s] = K.pieces * pts
	end
	for _, o in ipairs(Catalogue.OCCASIONS) do
		a[o] = e.occasions[o]
	end
	a.chaleur, a.poids = e.chaleur, e.poids
	APPORTS_VARIANTES[v.id] = a
end
for _, t in ipairs(Catalogue.Tissus) do
	local e, a = Etiquettes.tissu(t.id), zero()
	for s, pts in pairs(t.style) do
		a[s] = K.tissu * pts
	end
	for _, o in ipairs(Catalogue.OCCASIONS) do
		a[o] = e.occasions[o]
	end
	a.chaleur = e.chaleur
	APPORTS_TISSUS[t.id] = a
end
local function apportObjet(idAccessoire, fois)
	local a = zero()
	local def = idAccessoire and Catalogue.accessoire(idAccessoire)
	if def and def.genre == "objet" then
		for s, pts in pairs(def.style) do
			a[s] = K.accessoires * pts * fois
		end
	end
	return a
end

-- Une exigence chiffrée borne une somme de points : jugement = { cle, note (la somme, et le nombre de décorations,
-- → le score de 0 à 100), croissant (le score monte avec la somme), auPlus, valeur }
local function borne(x)
	return math.clamp(x, 0, 100)
end
local NOTES_TRAITS = {
	chaude = { cle = "chaleur", croissant = true, note = function(x)
		return (Etiquettes.traitsIndice(x))
	end },
	legere = { cle = "chaleur", croissant = false, note = function(x)
		return select(2, Etiquettes.traitsIndice(x))
	end },
	travaillee = { cle = "poids", croissant = true, note = function(poids, decorations)
		return (Etiquettes.traitsIndice(Etiquettes.richesse(poids, decorations)))
	end },
	sobre = { cle = "poids", croissant = false, note = function(poids, decorations)
		return select(2, Etiquettes.traitsIndice(Etiquettes.richesse(poids, decorations)))
	end },
}
local function tient(j, score)
	return if j.auPlus then score <= j.valeur + 1e-9 else score >= j.valeur - 1e-9
end

-- Cherche une robe simple qui remplit les exigences : un seul tissu, l'accessoire imposé et, pour une robe travaillée,
-- juste assez d'un même objet ouvert (le premier qui convient, dans l'ordre du catalogue). La qualité est supposée
-- atteignable (≤ 0,9). ouverts (facultatif, Deblocages.ouverts) : seulement avec ce qui est ouvert. Retourne ok et
-- le témoin { croquis, tissu, accessoire, ajout = { id, nombre } ou nil }.
-- Sous-projet 7 : la recherche avance famille par famille (corsage, manches, col, jupe, puis le tissu) et abandonne
-- une branche dès qu'aucune suite ne peut plus tenir une exigence : elle trouve la même robe que l'essai de chaque
-- croquis dans l'ordre, sans les essayer tous.
function Commandes.realisable(exigences, ouverts)
	local accessoireImpose
	for _, e in ipairs(exigences) do
		if e.type == "accessoire" then
			accessoireImpose = e.id
		elseif e.type == "qualite" and e.valeur > 0.9 then
			return false
		end
	end
	if accessoireImpose and (not Catalogue.accessoire(accessoireImpose) or (ouverts and not ouverts.accessoires[accessoireImpose])) then
		return false
	end
	-- Les exigences les plus fermées d'abord, une fois pour toutes : les accessoires (seul le dernier demandé est
	-- posé sur la robe témoin) ; la teinte, la matière et le motif (seuls les tissus ouverts qui les ont restent
	-- candidats) ; restent les exigences chiffrées (la qualité, au plus 0,9, est tenue d'office)
	local jugements, decoratives = {}, {}
	for _, e in ipairs(exigences) do
		if e.type == "accessoire" and e.id ~= accessoireImpose then
			return false
		elseif e.type == "min" or e.type == "max" or e.type == "occasion" then
			-- (relecture du plan 21) une étiquette inconnue, d'une fiche mal écrite : irréalisable, jamais d'erreur au tirage
			if not (if e.type == "occasion" then table.find(Catalogue.OCCASIONS, e.occasion) else table.find(Catalogue.STYLES, e.style)) then
				return false
			end
			table.insert(jugements, { cle = e.style or e.occasion, note = borne, croissant = true, auPlus = e.type == "max", valeur = e.valeur })
		elseif e.type == "trait" and NOTES_TRAITS[e.trait] then
			local t = NOTES_TRAITS[e.trait]
			local j = { cle = t.cle, note = t.note, croissant = t.croissant, valeur = e.valeur }
			table.insert(jugements, j)
			if e.trait == "travaillee" then
				table.insert(decoratives, j)
			end
		end
	end
	-- Deux traits opposés (Légère et Chaude, Sobre et Travaillée) : leur indice ne peut pas être à la fois positif et
	-- négatif ; impossibles d'emblée, sans essayer chaque robe (relecture)
	for _, a in ipairs(jugements) do
		for _, b in ipairs(jugements) do
			if (a.cle == "chaleur" or a.cle == "poids") and a.cle == b.cle and a.croissant and not b.croissant and a.valeur > 1e-9 and b.valeur > 1e-9 then
				return false
			end
		end
	end
	local tissus = {}
	for _, t in ipairs(Catalogue.Tissus) do
		local permis = not ouverts or ouverts.tissus[t.id]
		for _, e in ipairs(exigences) do
			if (e.type == "teinte" and e.teinte ~= t.teinte) or (e.type == "matiere" and e.matiere ~= t.matiere) then
				permis = false
			elseif e.type == "trait" and not NOTES_TRAITS[e.trait] then -- un motif : toute la robe l'a, ou pas du tout
				permis = permis and (if Etiquettes.tissu(t.id).motif == e.trait then 100 else 0) >= e.valeur - 1e-9
			end
		end
		if permis then
			table.insert(tissus, t)
		end
	end
	if #tissus == 0 then
		return false
	end
	local objets = {} -- de quoi rendre la robe travaillée
	if #decoratives > 0 then
		for _, a in ipairs(Catalogue.Accessoires) do
			if a.genre == "objet" and (not ouverts or ouverts.accessoires[a.id]) then
				table.insert(objets, a)
			end
		end
	end
	local base = Etiquettes.decorations(accessoireImpose and { { id = accessoireImpose } })
	local impose = apportObjet(accessoireImpose, 1)

	-- Ce que peuvent encore apporter les familles k à 4, puis le tissu, l'accessoire imposé et les décorations :
	-- reste[k] = { bas = { [cle] = … }, haut = { … } }
	local variantes, reste = {}, {}
	for k, famille in ipairs(Catalogue.FAMILLES) do
		variantes[k] = {}
		for _, v in ipairs(Catalogue.variantesDe(famille)) do
			if not ouverts or ouverts.variantes[v.id] then
				table.insert(variantes[k], v.id)
			end
		end
		if #variantes[k] == 0 then
			return false
		end
	end
	local function extremes(apports)
		local bas, haut = {}, {}
		for _, c in ipairs(CLES) do
			bas[c], haut[c] = math.huge, -math.huge
			for _, a in ipairs(apports) do
				bas[c], haut[c] = math.min(bas[c], a[c]), math.max(haut[c], a[c])
			end
		end
		return bas, haut
	end
	local apportsTissus, apportsObjets = {}, { zero() }
	for _, t in ipairs(tissus) do
		table.insert(apportsTissus, APPORTS_TISSUS[t.id])
	end
	for _, a in ipairs(objets) do
		table.insert(apportsObjets, apportObjet(a.id, Etiquettes.DECORATIONS_PLEINES))
	end
	local basT, hautT = extremes(apportsTissus)
	local basD, hautD = extremes(apportsObjets)
	reste[#Catalogue.FAMILLES + 1] = { bas = {}, haut = {} }
	for _, c in ipairs(CLES) do
		reste[#Catalogue.FAMILLES + 1].bas[c] = basT[c] + impose[c] + basD[c]
		reste[#Catalogue.FAMILLES + 1].haut[c] = hautT[c] + impose[c] + hautD[c]
	end
	for k = #Catalogue.FAMILLES, 1, -1 do
		local apports = {}
		for _, id in ipairs(variantes[k]) do
			table.insert(apports, APPORTS_VARIANTES[id])
		end
		local bas, haut = extremes(apports)
		reste[k] = { bas = {}, haut = {} }
		for _, c in ipairs(CLES) do
			reste[k].bas[c] = bas[c] + reste[k + 1].bas[c]
			reste[k].haut[c] = haut[c] + reste[k + 1].haut[c]
		end
	end
	-- Une somme partielle peut-elle encore tout tenir ? (chaque exigence à son extrême le plus favorable)
	local function possible(somme, r)
		for _, j in ipairs(jugements) do
			local monte = j.croissant ~= (j.auPlus == true)
			local x = somme[j.cle] + (if monte then r.haut[j.cle] else r.bas[j.cle])
			if not tient(j, j.note(x, if monte then Etiquettes.DECORATIONS_PLEINES else base)) then
				return false
			end
		end
		return true
	end
	local function tientTout(somme, decorations)
		for _, j in ipairs(jugements) do
			if not tient(j, j.note(somme[j.cle], decorations)) then
				return false
			end
		end
		return true
	end
	-- Une robe complète : son tissu, puis juste assez de décorations. Les objets ne changent que les styles : un tissu
	-- dont une exigence hors style (occasion, chaleur, poids) échoue est écarté avant d'en essayer aucun (relecture)
	local horsStyles = {}
	for _, j in ipairs(jugements) do
		if not table.find(Catalogue.STYLES, j.cle) then
			table.insert(horsStyles, j)
		end
	end
	local resteDecorations = { bas = basD, haut = hautD }
	local croquis = {}
	local function essayerTissus(partiel)
		for _, t in ipairs(tissus) do
			local somme = {}
			for _, c in ipairs(CLES) do
				somme[c] = partiel[c] + APPORTS_TISSUS[t.id][c] + impose[c]
			end
			if not possible(somme, resteDecorations) then
				continue -- même avec les meilleures décorations, ce tissu ne peut pas tout tenir
			end
			local n = 0
			local function assez()
				for _, j in ipairs(decoratives) do
					if not tient(j, j.note(somme.poids, base + n)) then
						return false
					end
				end
				return true
			end
			while not assez() and base + n < Etiquettes.DECORATIONS_PLEINES do
				n += 1
			end
			if not assez() then
				continue -- même couverte de décorations, cette robe ne serait pas assez travaillée
			end
			local horsStylesTenues = true
			for _, j in ipairs(horsStyles) do
				horsStylesTenues = horsStylesTenues and tient(j, j.note(somme[j.cle], base + n))
			end
			if not horsStylesTenues then
				continue
			elseif n == 0 then
				if tientTout(somme, base) then
					return { croquis = table.clone(croquis), tissu = t.id, accessoire = accessoireImpose }
				end
			else
				for _, a in ipairs(objets) do
					local avec = table.clone(somme)
					for s, pts in pairs(a.style) do
						avec[s] += K.accessoires * pts * n
					end
					if tientTout(avec, base + n) then
						return { croquis = table.clone(croquis), tissu = t.id, accessoire = accessoireImpose, ajout = { id = a.id, nombre = n } }
					end
				end
			end
		end
		return nil
	end
	local function chercher(k, partiel)
		if not possible(partiel, reste[k]) then
			return nil
		elseif k > #Catalogue.FAMILLES then
			return essayerTissus(partiel)
		end
		local famille = Catalogue.FAMILLES[k]
		for _, id in ipairs(variantes[k]) do
			croquis[famille] = id
			local somme = {}
			for _, c in ipairs(CLES) do
				somme[c] = partiel[c] + APPORTS_VARIANTES[id][c]
			end
			local temoin = chercher(k + 1, somme)
			if temoin then
				return temoin
			end
		end
		croquis[famille] = nil
		return nil
	end
	local temoin = chercher(1, zero())
	return temoin ~= nil, temoin
end

local function tirer(liste, rng)
	return liste[rng:NextInteger(1, #liste)]
end

-- Sous-projet 7 : le prestige à partir duquel une commande peut demander chaque occasion et chaque trait (à ce
-- prestige, avec ce qu'ouvrent le prestige et une amitié de niveau 2 avec les clientes déjà venues, chacun atteint 60 :
-- vérifié par les tests ; la Soirée attend la jupe longue évasée), et la matière dominante
Commandes.PRESTIGE_ETIQUETTES = {
	journee = 2, travail = 2, soiree = 4,
	legere = 4, chaude = 4, sobre = 4, travaillee = 4, unie = 4, fleurie = 4, a_motifs = 4,
}
Commandes.PRESTIGE_MATIERE = 3
local GROUPES_TRAITS = { legere = 1, chaude = 1, sobre = 2, travaillee = 2, unie = 3, fleurie = 3, a_motifs = 3 }

-- Deux exigences qu'une commande ne demande jamais ensemble : deux traits d'un même groupe (Légère et Chaude, Sobre et
-- Travaillée, Unie, Fleurie et À motifs), une matière trop chaude pour une robe légère (ou trop légère pour une robe
-- chaude), une robe travaillée et un « au plus » de style (les décorations qu'il lui faut portent des styles)
function Commandes.compatibles(a, b)
	local function sens(x, y)
		if x.type ~= "trait" then
			return true
		elseif y.type == "trait" then
			return GROUPES_TRAITS[x.trait] ~= GROUPES_TRAITS[y.trait]
		elseif y.type == "matiere" then
			local chaleur = Catalogue.MATIERES[y.matiere].chaleur
			return not ((x.trait == "legere" and chaleur >= 0.6) or (x.trait == "chaude" and chaleur <= -0.7))
		elseif y.type == "max" then
			return x.trait ~= "travaillee"
		end
		return true
	end
	return sens(a, b) and sens(b, a)
end

-- plafond : dizaines de points au plus pour le style ou l'occasion demandés (monte avec le prestige) ; ouverts :
-- accessoires et matières qu'on peut demander (nil : tous) ; niveau : niveau de prestige (nil : tout se demande)
local function tirerExigences(rng, cliente, plafond, ouverts, niveau)
	local exigences = {}
	local styleMin = tirer(cliente and cliente.styles or Catalogue.STYLES, rng)
	table.insert(exigences, { type = "min", style = styleMin, valeur = rng:NextInteger(3, plafond) * 10 })
	local autres = { "max", "qualite", "teinte", "accessoire" }
	local occasions, traits, matieres = {}, {}, {}
	for _, o in ipairs(Catalogue.OCCASIONS) do
		if not niveau or niveau >= Commandes.PRESTIGE_ETIQUETTES[o] then
			table.insert(occasions, o)
		end
	end
	for _, t in ipairs(Catalogue.TRAITS) do
		if not niveau or niveau >= Commandes.PRESTIGE_ETIQUETTES[t] then
			table.insert(traits, t)
		end
	end
	for _, t in ipairs(Catalogue.Tissus) do
		if (not ouverts or ouverts.tissus[t.id]) and not table.find(matieres, t.matiere) then
			table.insert(matieres, t.matiere)
		end
	end
	if #occasions > 0 then
		table.insert(autres, "occasion")
	end
	if not niveau or niveau >= Commandes.PRESTIGE_MATIERE then
		table.insert(autres, "matiere")
	end
	if #traits > 0 then
		table.insert(autres, "trait")
	end
	for _ = 2, rng:NextInteger(1, 3) do
		local genre = table.remove(autres, rng:NextInteger(1, #autres))
		local e
		if genre == "max" then
			local style
			repeat
				style = tirer(Catalogue.STYLES, rng)
			until style ~= styleMin and not (cliente and table.find(cliente.styles, style))
			e = { type = "max", style = style, valeur = rng:NextInteger(1, 4) * 10 }
		elseif genre == "qualite" then
			e = { type = "qualite", valeur = rng:NextInteger(6, 9) / 10 }
		elseif genre == "teinte" then
			e = { type = "teinte", teinte = cliente and cliente.teinte or tirer(Catalogue.Tissus, rng).teinte }
		elseif genre == "accessoire" then
			local objets = {}
			for _, a in ipairs(Catalogue.Accessoires) do
				if a.genre == "objet" and (not ouverts or ouverts.accessoires[a.id]) then
					table.insert(objets, a.id)
				end
			end
			e = { type = "accessoire", id = tirer(objets, rng) }
		elseif genre == "occasion" then
			-- celle de la cliente, deux fois sur trois (si elle se demande déjà)
			local prefere = cliente and cliente.occasion and table.find(occasions, cliente.occasion) and rng:NextInteger(1, 3) <= 2
			e = { type = "occasion", occasion = if prefere then cliente.occasion else tirer(occasions, rng), valeur = rng:NextInteger(2, plafond) * 10 }
		elseif genre == "matiere" then
			e = { type = "matiere", matiere = tirer(matieres, rng) }
		else
			local trait = tirer(traits, rng)
			local dizaines = if table.find(Etiquettes.MOTIFS, trait) then rng:NextInteger(5, 10) else rng:NextInteger(2, 6)
			e = { type = "trait", trait = trait, valeur = dizaines * 10 }
		end
		local permise = true
		for _, x in ipairs(exigences) do
			permise = permise and Commandes.compatibles(x, e)
		end
		if permise then
			table.insert(exigences, e)
		end
	end
	return exigences
end

-- Dizaines de points au plus pour le style demandé : 5 au prestige 1, puis une de plus par niveau, 8 au plus
function Commandes.plafond(niveauPrestige)
	return math.min(8, 4 + niveauPrestige)
end

-- rng : un objet Random ; cliente (facultatif) : une fiche de Clientes ; progres (facultatif) : le prestige et
-- les amitiés du joueur (l'état de l'atelier convient). Retourne { taille, mesures, exigences } (anonyme), ou
-- { cliente, taille, exigences } : ses mesures seront prises à l'atelier.
function Commandes.generer(rng, cliente, progres)
	local ouverts = progres and Deblocages.ouverts(progres)
	local niveau = progres and Progression.niveauPrestige(progres.prestige)
	local plafond = niveau and Commandes.plafond(niveau) or 7
	local exigences
	for _ = 1, Commandes.ESSAIS do
		local candidat = tirerExigences(rng, cliente, plafond, ouverts, niveau)
		if Commandes.realisable(candidat, ouverts) then
			exigences = candidat
			break
		end
	end
	-- Repli : un seul style demandé, à 20 puis à 10 ; ceux de la cliente d'abord, puis les autres ; toujours
	-- réalisable avec ce qui est ouvert
	if not exigences then
		local styles = cliente and table.clone(cliente.styles) or {}
		for _, s in ipairs(Catalogue.STYLES) do
			if not table.find(styles, s) then
				table.insert(styles, s)
			end
		end
		for _, valeur in ipairs({ 20, 10 }) do
			for _, s in ipairs(styles) do
				local candidat = { { type = "min", style = s, valeur = valeur } }
				if not exigences and Commandes.realisable(candidat, ouverts) then
					exigences = candidat
				end
			end
		end
		exigences = exigences or { { type = "qualite", valeur = 0.5 } }
	end
	if cliente then
		return { cliente = cliente.id, taille = cliente.taille, exigences = exigences }
	end
	local taille = tirer(NOMS_TAILLES, rng)
	return { taille = taille, mesures = table.clone(Catalogue.TAILLES[taille]), exigences = exigences }
end

return Commandes
