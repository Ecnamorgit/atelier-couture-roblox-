-- Équilibrage (spec §10) : un joueur moyen simulé enchaîne les robes avec les vraies règles de l'atelier.
-- À chaque commande : mesures justes, la robe la moins chère qui la remplit avec ce qui est ouvert (un seul
-- tissu, l'accessoire demandé), qualité 0,8 ; une robe refusée (qualité demandée trop haute) est abandonnée.
-- (Sous-projet 7 : une robe travaillée, qu'aucune robe simple ne remplit, est la robe témoin de la commande.)
-- Une robe sur quatre (dès que les robes libres sont ouvertes) : une robe libre en toile de jute, vendue.
-- Le courrier : quand une lettre attend, le joueur invite sa cliente (la moins avancée en amitié d'abord) au
-- lieu de sonner la clochette.
local EtatAtelier = U.module("EtatAtelier")
local Clientes = U.module("Clientes")
local Catalogue = U.module("Catalogue")
local Patron = U.module("Patron")
local Metrage = U.module("Metrage")
local Notation = U.module("Notation")
local Deblocages = U.module("Deblocages")
local Progression = U.module("Progression")
local Etiquettes = U.module("Etiquettes")
local Commandes = U.module("Commandes")

local QUALITE = 0.8
local ROBES = 160 -- (sous-projet 4 : les quatre dernières clientes arrivent aux prestiges 5 à 8)

local CROQUIS = {}
for _, c in ipairs(Catalogue.variantesDe("corsage")) do
	for _, m in ipairs(Catalogue.variantesDe("manches")) do
		for _, k in ipairs(Catalogue.variantesDe("col")) do
			for _, j in ipairs(Catalogue.variantesDe("jupe")) do
				local croquis = { corsage = c.id, manches = m.id, col = k.id, jupe = j.id }
				local pieces = Patron.piecesDuCroquis(croquis)
				table.insert(CROQUIS, { croquis = croquis, pieces = pieces, dm = Metrage.conseil(pieces) })
			end
		end
	end
end

-- Toutes les robes simples (croquis × tissu), de la moins chère à la plus chère ; à coût égal, dans l'ordre du
-- catalogue (croquis, puis tissu) : la première qui remplit la commande est la moins chère
local CANDIDATES = {}
for i, c in ipairs(CROQUIS) do
	for j, t in ipairs(Catalogue.Tissus) do
		table.insert(CANDIDATES, { croquis = c, tissu = t, cout = EtatAtelier.prix(t.id, c.dm), rang = i * 1000 + j })
	end
end
table.sort(CANDIDATES, function(a, b)
	return a.cout < b.cout or (a.cout == b.cout and a.rang < b.rang)
end)

-- Le bilan d'une robe simple, calculé une fois pour toute la simulation (Notation.styles et Etiquettes.calculer, gardés
-- en mémoire)
local bilansConnus = {}
local function bilanDe(candidate, impose)
	local cle = candidate.rang .. "/" .. (impose or "")
	local bilan = bilansConnus[cle]
	if not bilan then
		local entree = { croquis = candidate.croquis.croquis, tissus = { [candidate.tissu.id] = 1 }, accessoires = impose and { { id = impose } } or {} }
		local etiquettes = Etiquettes.calculer(entree)
		bilan = {
			styles = Notation.styles(entree),
			occasions = etiquettes.occasions,
			traits = etiquettes.traits,
			qualite = QUALITE,
			teinte = candidate.tissu.teinte,
			matiere = candidate.tissu.matiere,
			accessoires = impose and { [impose] = 1 } or {},
		}
		bilansConnus[cle] = bilan
	end
	return bilan
end

-- La robe la moins chère qui remplit la commande avec ce qui est ouvert, ou nil
local function choisir(etat)
	local ouverts = Deblocages.ouverts(etat)
	local impose
	for _, x in ipairs(etat.commande.exigences) do
		if x.type == "accessoire" then
			impose = x.id
		end
	end
	if impose and not ouverts.accessoires[impose] then
		return nil
	end
	for _, candidate in ipairs(CANDIDATES) do
		local c, t = candidate.croquis, candidate.tissu
		local v = c.croquis
		if ouverts.tissus[t.id] and ouverts.variantes[v.corsage] and ouverts.variantes[v.manches] and ouverts.variantes[v.col] and ouverts.variantes[v.jupe] then
			if Notation.verifierExigences(etat.commande.exigences, bilanDe(candidate, impose)) then
				local cout = candidate.cout + (impose and Catalogue.accessoire(impose).prix or 0)
				return { croquis = v, pieces = c.pieces, dm = c.dm, tissu = t.id, cout = cout, impose = impose }
			end
		end
	end
	-- Aucune robe simple : la robe témoin de la commande (une robe travaillée : ses objets ajoutés), si la qualité suffit
	local ok, temoin = Commandes.realisable(etat.commande.exigences, ouverts)
	if ok and temoin.ajout then
		local accessoires = impose and { { id = impose } } or {}
		for _ = 1, temoin.ajout.nombre do
			table.insert(accessoires, { id = temoin.ajout.id })
		end
		local entree = { croquis = temoin.croquis, tissus = { [temoin.tissu] = 1 }, accessoires = accessoires }
		local etiquettes, tissu = Etiquettes.calculer(entree), Catalogue.tissu(temoin.tissu)
		local comptes = { [temoin.ajout.id] = temoin.ajout.nombre }
		if impose then
			comptes[impose] = (comptes[impose] or 0) + 1
		end
		local bilan = { styles = Notation.styles(entree), occasions = etiquettes.occasions, traits = etiquettes.traits, qualite = QUALITE, teinte = tissu.teinte, matiere = tissu.matiere, accessoires = comptes }
		if Notation.verifierExigences(etat.commande.exigences, bilan) then
			local pieces = Patron.piecesDuCroquis(temoin.croquis)
			local dm = Metrage.conseil(pieces)
			local cout = EtatAtelier.prix(temoin.tissu, dm) + (impose and Catalogue.accessoire(impose).prix or 0) + temoin.ajout.nombre * Catalogue.accessoire(temoin.ajout.id).prix
			return { croquis = temoin.croquis, pieces = pieces, dm = dm, tissu = temoin.tissu, cout = cout, impose = impose, ajout = temoin.ajout }
		end
	end
	return nil
end

local robeSimple = EtatAtelier.prix("coton_blanc", Metrage.conseil(Patron.piecesDuCroquis({ corsage = "corsage_droit", manches = "manches_sans", col = "col_sans", jupe = "jupe_droite" })))
-- Une partie simulée (graine de ses tirages) : robe du prestige 2 et du prestige 5, robe où tout est ouvert
-- (math.huge si jamais), argent au plus bas, commandes livrées
local function simuler(graine)
local e = EtatAtelier.nouveau()
local rng = Random.new(graine)
local niveauA, toutOuvertA = {}, nil
local plusPauvre, livrees, commandes, vendues, invitees = math.huge, 0, 0, 0, 0
local JUTE = { corsage = "corsage_droit", manches = "manches_sans", col = "col_sans", jupe = "jupe_droite" }
for n = 1, ROBES do
	if n % 4 == 0 and e.livraisons >= EtatAtelier.LIBRES_APRES then
		assert(e:nouvelleRobeLibre("M").ok)
		local tissus = {}
		for _, id in ipairs(Patron.piecesDuCroquis(JUTE)) do
			tissus[id] = "toile_jute"
			e.coupees[id] = { x = 0, y = 0, angle = 0 }
			e.epinglees[id] = true
			e.coutures[id] = QUALITE
		end
		assert(e:validerCroquis(JUTE, tissus).ok)
		e.etape = "decorations"
		assert(e:decorer({}).ok)
		assert(e:vendre(rng).ok)
		vendues += 1
	else
	commandes += 1
	local lettre
	for i, l in ipairs(e.lettres) do
		if not lettre or e.clientes[l.cliente].amitie < e.clientes[e.lettres[lettre].cliente].amitie then
			lettre = i
		end
	end
	if lettre then
		assert(e:inviter(lettre).ok)
		invitees += 1
	else
		assert(e:nouvelleCommande(rng).ok)
	end
	assert(e:mesurer(Clientes.get(e.commande.cliente).mesures).ok)
	local choix = choisir(e)
	local reussie = false
	if choix and choix.cout <= e.argent then
		local tissus = {}
		for _, id in ipairs(choix.pieces) do
			tissus[id] = choix.tissu
		end
		assert(e:validerCroquis(choix.croquis, tissus).ok)
		assert(e:acheter(choix.tissu, choix.dm).ok)
		e.stock[choix.tissu] -= choix.dm -- tout le métrage est coupé
		for _, id in ipairs(choix.pieces) do
			e.coupees[id] = { x = 0, y = 0, angle = Catalogue.piece(id).biais and 45 or 0 }
			e.epinglees[id] = true
			e.coutures[id] = QUALITE
		end
		e.etape = "decorations"
		local deco = choix.impose and { { id = choix.impose, piece = 1, copie = "unique", u = 0.5, v = 0.5, echelle = 1, angle = 0 } } or {}
		if choix.impose and (e.mercerie[choix.impose] or 0) < 1 then
			assert(e:acheterMercerie(choix.impose, 1).ok) -- (sous-projet 6 : l'accessoire exigé s'achète à la mercerie)
		end
		if choix.ajout then
			local deja = if choix.ajout.id == choix.impose then 1 else 0
			local manque = choix.ajout.nombre + deja - (e.mercerie[choix.ajout.id] or 0)
			if manque > 0 then
				assert(e:acheterMercerie(choix.ajout.id, manque).ok)
			end
			for k = 1, choix.ajout.nombre do
				table.insert(deco, { id = choix.ajout.id, piece = 1, copie = "unique", u = 0.1 * k, v = 0.3, echelle = 1, angle = 0 })
			end
		end
		assert(e:decorer(deco).ok)
		reussie = e:livrer(rng).reussie
	end
	if reussie then
		livrees += 1
	else
		e.etape = "refus"
		assert(e:abandonner().ok)
	end
	end
	plusPauvre = math.min(plusPauvre, e.argent)
	local niveau = Progression.niveauPrestige(e.prestige)
	for k = 2, niveau do
		niveauA[k] = niveauA[k] or n
	end
	if not toutOuvertA and Deblocages.toutOuvert(e) then
		toutOuvertA = n
	end
end
return { prestige2 = niveauA[2] or math.huge, prestige5 = niveauA[5] or math.huge, prestige8 = niveauA[8] or math.huge, toutOuvert = toutOuvertA or math.huge, plusPauvre = plusPauvre, livrees = livrees, commandes = commandes, vendues = vendues, invitees = invitees }
end

-- Vingt parties : les tirages changent d'une partie à l'autre, l'équilibrage se juge sur l'ensemble
local PARTIES = 20
local parties = {}
for graine = 1, PARTIES do
	parties[graine] = simuler(graine)
end
local function serie(cle)
	local valeurs = {}
	for _, p in ipairs(parties) do
		table.insert(valeurs, p[cle])
	end
	table.sort(valeurs)
	return valeurs, valeurs[math.ceil(#valeurs / 2)]
end
local p2 = serie("prestige2")
local p5, medianeP5 = serie("prestige5")
local _, medianeP8 = serie("prestige8")
local tout, medianeTout = serie("toutOuvert")
local pauvres = serie("plusPauvre")
local function texte(v)
	return if v == math.huge then "jamais" else tostring(v)
end
local invitees, medianeInvitees = serie("invitees")
local bilan = ("%d parties de %d robes, une robe libre de jute vendue sur quatre, %s commandes par lettre (médiane) : prestige 2 à la robe %s au plus tard ; 5 de la %s à la %s (médiane %s) ; 8 à la %s (médiane) ; tout ouvert de la %s à la %s (médiane %s) ; au plus bas %d po"):format(PARTIES, ROBES, texte(medianeInvitees), texte(p2[#p2]), texte(p5[1]), texte(p5[#p5]), texte(medianeP5), texte(medianeP8), texte(tout[1]), texte(tout[#tout]), texte(medianeTout), pauvres[1])
print("Équilibrage : " .. bilan)
U.verifier(p2[#p2] <= 3, "prestige 2 en trois robes au plus, dans chaque partie (" .. bilan .. ")")
U.verifier(medianeP8 <= 70, "le prestige 8 (qui ouvre maintenant le tulle et deux décorations) est atteint vers la 70e robe au plus tard, en médiane (" .. bilan .. ")")
U.verifier(medianeP5 >= 12 and medianeP5 <= 20 and p5[#p5] <= 25, "prestige 5 entre la 12e et la 20e robe en médiane, à la 25e au plus tard (" .. bilan .. ")")
U.verifier(medianeTout >= 100 and medianeTout <= 150, "tout le catalogue ouvert entre la 100e et la 150e robe, en médiane : l'amitié des quatre dernières clientes, arrivées aux prestiges 5 à 8, ouvre les dernières variantes (" .. bilan .. ")")
local toutAvantLaFin = 0
for _, n in ipairs(tout) do
	if n <= ROBES then
		toutAvantLaFin += 1
	end
end
U.verifier(toutAvantLaFin >= 16, ("au moins 16 parties sur 20 ouvrent tout avant la %de robe (%d) (%s)"):format(ROBES, toutAvantLaFin, bilan))
U.verifier(medianeInvitees >= 10, "le courrier fait venir des clientes (" .. bilan .. ")")
U.verifier(pauvres[1] >= robeSimple, "l'argent ne descend jamais sous le prix d'une robe simple (" .. bilan .. ")")
local livreesEtVendues = true
for _, p in ipairs(parties) do
	livreesEtVendues = livreesEtVendues and p.livrees >= p.commandes * 0.7 and p.vendues >= ROBES / 4 - 1
end
U.verifier(livreesEtVendues, "un joueur moyen livre la plupart de ses commandes, et vend ses robes libres, dans chaque partie (" .. bilan .. ")")
