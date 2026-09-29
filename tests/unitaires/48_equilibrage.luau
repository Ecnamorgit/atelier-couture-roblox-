-- Équilibrage (spec §10) : un joueur moyen simulé enchaîne les commandes avec les vraies règles de l'atelier.
-- À chaque commande : mesures justes, la robe la moins chère qui la remplit avec ce qui est ouvert (un seul
-- tissu, l'accessoire demandé), qualité 0,8 ; une robe refusée (qualité demandée trop haute) est abandonnée.
local EtatAtelier = U.module("EtatAtelier")
local Clientes = U.module("Clientes")
local Catalogue = U.module("Catalogue")
local Patron = U.module("Patron")
local Metrage = U.module("Metrage")
local Notation = U.module("Notation")
local Deblocages = U.module("Deblocages")
local Progression = U.module("Progression")

local QUALITE = 0.8
local ROBES = 60

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
	local accessoires = impose and { { id = impose } } or {}
	local meilleur
	for _, c in ipairs(CROQUIS) do
		local v = c.croquis
		if ouverts.variantes[v.corsage] and ouverts.variantes[v.manches] and ouverts.variantes[v.col] and ouverts.variantes[v.jupe] then
			for _, t in ipairs(Catalogue.Tissus) do
				local cout = EtatAtelier.prix(t.id, c.dm) + (impose and Catalogue.accessoire(impose).prix or 0)
				if ouverts.tissus[t.id] and (not meilleur or cout < meilleur.cout) then
					local bilan = {
						styles = Notation.styles({ croquis = v, tissus = { [t.id] = 1 }, accessoires = accessoires }),
						qualite = QUALITE,
						teinte = t.teinte,
						accessoires = impose and { [impose] = 1 } or {},
					}
					if Notation.verifierExigences(etat.commande.exigences, bilan) then
						meilleur = { croquis = v, pieces = c.pieces, dm = c.dm, tissu = t.id, cout = cout, impose = impose }
					end
				end
			end
		end
	end
	return meilleur
end

local robeSimple = EtatAtelier.prix("coton_blanc", Metrage.conseil(Patron.piecesDuCroquis({ corsage = "corsage_droit", manches = "manches_sans", col = "col_sans", jupe = "jupe_droite" })))
-- Une partie simulée (graine de ses tirages) : robe du prestige 2 et du prestige 5, robe où tout est ouvert
-- (math.huge si jamais), argent au plus bas, commandes livrées
local function simuler(graine)
local e = EtatAtelier.nouveau()
local rng = Random.new(graine)
local niveauA, toutOuvertA = {}, nil
local plusPauvre, livrees = math.huge, 0
for n = 1, ROBES do
	assert(e:nouvelleCommande(rng).ok)
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
		assert(e:decorer(deco).ok)
		reussie = e:livrer().reussie
	end
	if reussie then
		livrees += 1
	else
		e.etape = "refus"
		assert(e:abandonner().ok)
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
return { prestige2 = niveauA[2] or math.huge, prestige5 = niveauA[5] or math.huge, toutOuvert = toutOuvertA or math.huge, plusPauvre = plusPauvre, livrees = livrees }
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
local tout, medianeTout = serie("toutOuvert")
local pauvres = serie("plusPauvre")
local livrees = serie("livrees")
local function texte(v)
	return if v == math.huge then "jamais" else tostring(v)
end
local bilan = ("%d parties de %d robes : prestige 2 à la robe %s au plus tard ; 5 de la %s à la %s (médiane %s) ; tout ouvert de la %s à la %s (médiane %s) ; au plus bas %d po"):format(PARTIES, ROBES, texte(p2[#p2]), texte(p5[1]), texte(p5[#p5]), texte(medianeP5), texte(tout[1]), texte(tout[#tout]), texte(medianeTout), pauvres[1])
print("Équilibrage : " .. bilan)
U.verifier(p2[#p2] <= 3, "prestige 2 en trois robes au plus, dans chaque partie (" .. bilan .. ")")
U.verifier(p5[1] >= 12 and p5[#p5] <= 20, "prestige 5 entre la 12e et la 20e robe, dans chaque partie (" .. bilan .. ")")
U.verifier(medianeTout >= 30 and medianeTout <= 50, "tout le catalogue ouvert entre la 30e et la 50e robe, en médiane (" .. bilan .. ")")
U.verifier(pauvres[1] >= robeSimple, "l'argent ne descend jamais sous le prix d'une robe simple (" .. bilan .. ")")
U.verifier(livrees[1] >= ROBES * 0.7, "un joueur moyen livre la plupart de ses commandes, dans chaque partie (" .. bilan .. ")")
