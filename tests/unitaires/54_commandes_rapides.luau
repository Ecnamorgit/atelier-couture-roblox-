-- Le tirage des commandes reste juste et rapide avec un grand catalogue (sous-projet 4)
local Commandes = U.module("Commandes")
local Catalogue = U.module("Catalogue")
local Notation = U.module("Notation")
local Deblocages = U.module("Deblocages")
local Clientes = U.module("Clientes")
local Progression = U.module("Progression")

-- La référence : le calcul complet (Notation.styles et Notation.verifierExigences) sur chaque robe simple
local function croquisPossibles()
	local out = {}
	for _, c in ipairs(Catalogue.variantesDe("corsage")) do
		for _, m in ipairs(Catalogue.variantesDe("manches")) do
			for _, k in ipairs(Catalogue.variantesDe("col")) do
				for _, j in ipairs(Catalogue.variantesDe("jupe")) do
					table.insert(out, { corsage = c.id, manches = m.id, col = k.id, jupe = j.id })
				end
			end
		end
	end
	return out
end
local CROQUIS = croquisPossibles()
local function reference(exigences, ouverts)
	local impose
	for _, e in ipairs(exigences) do
		if e.type == "accessoire" then
			impose = e.id
		elseif e.type == "qualite" and e.valeur > 0.9 then
			return false
		end
	end
	if ouverts and impose and not ouverts.accessoires[impose] then
		return false
	end
	for _, croquis in ipairs(CROQUIS) do
		for _, t in ipairs(Catalogue.Tissus) do
			local permis = not ouverts or (ouverts.tissus[t.id] and ouverts.variantes[croquis.corsage] and ouverts.variantes[croquis.manches] and ouverts.variantes[croquis.col] and ouverts.variantes[croquis.jupe])
			if permis then
				local bilan = {
					styles = Notation.styles({ croquis = croquis, tissus = { [t.id] = 1 }, accessoires = impose and { { id = impose } } or {} }),
					qualite = 1,
					teinte = t.teinte,
					accessoires = impose and { [impose] = 1 } or {},
				}
				if Notation.verifierExigences(exigences, bilan) then
					return true
				end
			end
		end
	end
	return false
end

-- Mille jeux d'exigences tirés au hasard (dont des impossibles), avec ou sans restriction : même réponse que la
-- référence, et le témoin remplit bien les exigences
local rng = Random.new(54)
local objets = {}
for _, a in ipairs(Catalogue.Accessoires) do
	table.insert(objets, a.id)
end
local PROGRES = {
	{ prestige = 0, clientes = {} },
	{ prestige = 100, clientes = { colette = { amitie = 7 } } },
	{ prestige = 530, clientes = {} },
}
local differences, temoinsFaux = 0, 0
for n = 1, 1000 do
	local exigences = {}
	for _ = 1, rng:NextInteger(1, 3) do
		local genre = rng:NextInteger(1, 5)
		if genre == 1 then
			table.insert(exigences, { type = "min", style = Catalogue.STYLES[rng:NextInteger(1, 6)], valeur = rng:NextInteger(1, 9) * 10 })
		elseif genre == 2 then
			table.insert(exigences, { type = "max", style = Catalogue.STYLES[rng:NextInteger(1, 6)], valeur = rng:NextInteger(0, 5) * 10 })
		elseif genre == 3 then
			table.insert(exigences, { type = "teinte", teinte = Catalogue.TEINTES[rng:NextInteger(1, #Catalogue.TEINTES)] })
		elseif genre == 4 then
			table.insert(exigences, { type = "accessoire", id = objets[rng:NextInteger(1, #objets)] })
		else
			table.insert(exigences, { type = "qualite", valeur = rng:NextInteger(5, 10) / 10 })
		end
	end
	local ouverts = if n % 4 == 0 then nil else Deblocages.ouverts(PROGRES[n % 3 + 1])
	local ok, temoin = Commandes.realisable(exigences, ouverts)
	if ok ~= reference(exigences, ouverts) then
		differences += 1
	end
	if ok then
		local bilan = {
			styles = Notation.styles({ croquis = temoin.croquis, tissus = { [temoin.tissu] = 1 }, accessoires = temoin.accessoire and { { id = temoin.accessoire } } or {} }),
			qualite = 0.9,
			teinte = Catalogue.tissu(temoin.tissu).teinte,
			accessoires = temoin.accessoire and { [temoin.accessoire] = 1 } or {},
		}
		if not Notation.verifierExigences(exigences, bilan) then
			temoinsFaux += 1
		end
	end
end
U.verifier(differences == 0, "mille jeux d'exigences : même réponse que le calcul complet (" .. differences .. " différences)")
U.verifier(temoinsFaux == 0, "le témoin remplit toujours les exigences (" .. temoinsFaux .. " faux)")

-- Une garniture imposée (sans longueur) ne compte pas dans les styles : avec chaque garniture, on demande un peu
-- plus que le meilleur score d'une robe simple dans un style qu'elle porte ; aucune robe ne l'atteint
local meilleur = {}
for _, s in ipairs(Catalogue.STYLES) do
	meilleur[s] = 0
end
for _, croquis in ipairs(CROQUIS) do
	for _, t in ipairs(Catalogue.Tissus) do
		for s, v in pairs(Notation.styles({ croquis = croquis, tissus = { [t.id] = 1 } })) do
			meilleur[s] = math.max(meilleur[s], v)
		end
	end
end
local essais, comptees = 0, {}
for _, a in ipairs(Catalogue.Accessoires) do
	if a.genre == "garniture" then
		for s, pts in pairs(a.style) do
			if pts > 0 and meilleur[s] < 100 then
				essais += 1
				if Commandes.realisable({ { type = "accessoire", id = a.id }, { type = "min", style = s, valeur = meilleur[s] + 0.01 } }) then
					table.insert(comptees, a.id .. " (" .. s .. ")")
				end
			end
		end
	end
end
U.verifier(essais > 0 and #comptees == 0, "une garniture imposée ne compte pas dans les styles (" .. essais .. " essais ; comptées : " .. table.concat(comptees, ", ") .. ")")

-- Rapide : deux cents commandes tirées, tout ouvert, sans recalculer les styles robe par robe (la simulation ne
-- mesure pas le temps réel : on compte les appels au calcul complet)
local tout = { prestige = 530, clientes = {} }
for _, c in ipairs(Clientes.LISTE) do
	tout.clientes[c.id] = { amitie = 25 }
end
local appels = 0
local complet = Notation.styles
Notation.styles = function(...)
	appels += 1
	return complet(...)
end
local rngT = Random.new(7)
for n = 1, 200 do
	Commandes.generer(rngT, Clientes.LISTE[n % #Clientes.LISTE + 1], tout)
end
Notation.styles = complet
U.verifier(appels == 0, "deux cents commandes tirées sans recalculer les styles robe par robe (" .. appels .. " calculs complets)")
U.verifier(Progression.niveauPrestige(530) == 8, "(prestige 8)")
