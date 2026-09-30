-- Sous-projet 7 : Commandes.realisable sait juger les occasions, les traits et la matière. La recherche avance famille
-- par famille ; elle répond comme l'essai complet de chaque robe simple, et son témoin tient les exigences.
local Commandes = U.module("Commandes")
local Catalogue = U.module("Catalogue")
local Notation = U.module("Notation")
local Etiquettes = U.module("Etiquettes")
local Deblocages = U.module("Deblocages")
local Patron = U.module("Patron")

-- La référence : chaque robe simple dans l'ordre du carnet, jugée par le calcul complet (Notation.styles,
-- Etiquettes.calculer) ; pour une robe travaillée, juste assez d'un même objet ouvert, le premier qui convient
local CROQUIS = {}
for _, c in ipairs(Catalogue.variantesDe("corsage")) do
	for _, m in ipairs(Catalogue.variantesDe("manches")) do
		for _, k in ipairs(Catalogue.variantesDe("col")) do
			for _, j in ipairs(Catalogue.variantesDe("jupe")) do
				table.insert(CROQUIS, { corsage = c.id, manches = m.id, col = k.id, jupe = j.id })
			end
		end
	end
end
local function bilanSimple(croquis, t, accessoires)
	local entree = { croquis = croquis, tissus = { [t.id] = 1 }, accessoires = accessoires }
	local e = Etiquettes.calculer(entree)
	local comptes = {}
	for _, a in ipairs(accessoires) do
		comptes[a.id] = (comptes[a.id] or 0) + 1
	end
	return { styles = Notation.styles(entree), occasions = e.occasions, traits = e.traits, qualite = 0.9, teinte = t.teinte, matiere = t.matiere, accessoires = comptes }
end
local function reference(exigences, ouverts)
	local impose
	local travaillee = {}
	for _, e in ipairs(exigences) do
		if e.type == "accessoire" then
			impose = e.id
		elseif e.type == "qualite" and e.valeur > 0.9 then
			return false
		elseif e.type == "trait" and e.trait == "travaillee" then
			table.insert(travaillee, e)
		end
	end
	if impose and (not Catalogue.accessoire(impose) or (ouverts and not ouverts.accessoires[impose])) then
		return false
	end
	local base = impose and { { id = impose } } or {}
	for _, croquis in ipairs(CROQUIS) do
		if not ouverts or (ouverts.variantes[croquis.corsage] and ouverts.variantes[croquis.manches] and ouverts.variantes[croquis.col] and ouverts.variantes[croquis.jupe]) then
			for _, t in ipairs(Catalogue.Tissus) do
				if not ouverts or ouverts.tissus[t.id] then
					-- Combien de décorations en plus ? (le nombre seul compte pour Travaillée)
					local simple = bilanSimple(croquis, t, base)
					local n = if Notation.verifierExigences(travaillee, simple) then 0 else nil
					for essai = 1, if n then 0 else Etiquettes.DECORATIONS_PLEINES do
						local avec = table.clone(base)
						for _ = 1, essai do
							table.insert(avec, { id = "perle" })
						end
						if Notation.verifierExigences(travaillee, bilanSimple(croquis, t, avec)) then
							n = essai
							break
						end
					end
					if n == 0 then
						if Notation.verifierExigences(exigences, simple) then
							return true, croquis, t.id
						end
					elseif n then
						for _, a in ipairs(Catalogue.Accessoires) do
							if a.genre == "objet" and (not ouverts or ouverts.accessoires[a.id]) then
								local avec = table.clone(base)
								for _ = 1, n do
									table.insert(avec, { id = a.id })
								end
								if Notation.verifierExigences(exigences, bilanSimple(croquis, t, avec)) then
									return true, croquis, t.id, { id = a.id, nombre = n }
								end
							end
						end
					end
				end
			end
		end
	end
	return false
end

-- Le témoin, cousu pour de vrai : toutes les pièces dans son tissu, l'accessoire imposé et les objets ajoutés
local function recetteTemoin(temoin)
	local recette = { croquis = temoin.croquis, pieces = {}, accessoires = {} }
	for _, id in ipairs(Patron.piecesDuCroquis(temoin.croquis)) do
		table.insert(recette.pieces, { id = id, tissu = temoin.tissu, x = 0, y = 0, angle = Catalogue.piece(id).biais and 45 or 0, couture = 0.9 })
	end
	if temoin.accessoire then
		table.insert(recette.accessoires, { id = temoin.accessoire, piece = 1, u = 0.5, v = 0.5, echelle = 1, angle = 0 })
	end
	for _ = 1, temoin.ajout and temoin.ajout.nombre or 0 do
		table.insert(recette.accessoires, { id = temoin.ajout.id, piece = 1, u = 0.4, v = 0.4, echelle = 1, angle = 0 })
	end
	return recette
end

---------------------------------------------------------------------------
-- Quatre cents jeux d'exigences tirés au hasard, anciennes et nouvelles (dont des impossibles), avec ou sans
-- restriction : même réponse que la référence, même témoin, et le témoin cousu remplit les exigences
---------------------------------------------------------------------------
local MATIERES = {}
for m in pairs(Catalogue.MATIERES) do
	table.insert(MATIERES, m)
end
table.sort(MATIERES)
local PROGRES = {
	{ prestige = 0, clientes = {} },
	{ prestige = 100, clientes = { colette = { amitie = 7 } } },
	{ prestige = 530, clientes = {} },
}
local rng = Random.new(71)
local differences, autres, faux, genres = {}, 0, 0, {}
for n = 1, 400 do
	local exigences = {}
	for _ = 1, rng:NextInteger(1, 3) do
		local genre = rng:NextInteger(1, 8)
		if genre == 1 then
			table.insert(exigences, { type = "min", style = Catalogue.STYLES[rng:NextInteger(1, 6)], valeur = rng:NextInteger(1, 8) * 10 })
		elseif genre == 2 then
			table.insert(exigences, { type = "max", style = Catalogue.STYLES[rng:NextInteger(1, 6)], valeur = rng:NextInteger(0, 5) * 10 })
		elseif genre == 3 then
			table.insert(exigences, { type = "teinte", teinte = Catalogue.TEINTES[rng:NextInteger(1, #Catalogue.TEINTES)] })
		elseif genre == 4 then
			table.insert(exigences, { type = "accessoire", id = Catalogue.Accessoires[rng:NextInteger(1, #Catalogue.Accessoires)].id })
		elseif genre == 5 then
			table.insert(exigences, { type = "occasion", occasion = Catalogue.OCCASIONS[rng:NextInteger(1, 3)], valeur = rng:NextInteger(1, 8) * 10 })
		elseif genre == 6 then
			table.insert(exigences, { type = "trait", trait = Catalogue.TRAITS[rng:NextInteger(1, 7)], valeur = rng:NextInteger(1, 10) * 10 })
		elseif genre == 7 then
			table.insert(exigences, { type = "matiere", matiere = MATIERES[rng:NextInteger(1, #MATIERES)] })
		else
			table.insert(exigences, { type = "qualite", valeur = rng:NextInteger(5, 10) / 10 })
		end
	end
	local ouverts = if n % 4 == 0 then nil else Deblocages.ouverts(PROGRES[n % 3 + 1])
	local ok, temoin = Commandes.realisable(exigences, ouverts)
	local okRef, croquisRef, tissuRef, ajoutRef = reference(exigences, ouverts)
	if ok ~= okRef then
		table.insert(differences, n)
	elseif ok then
		genres[temoin.ajout and "ajout" or "simple"] = true
		local memeAjout = (temoin.ajout == nil and ajoutRef == nil) or (temoin.ajout and ajoutRef and temoin.ajout.id == ajoutRef.id and temoin.ajout.nombre == ajoutRef.nombre)
		if temoin.tissu ~= tissuRef or not memeAjout or temoin.croquis.corsage ~= croquisRef.corsage or temoin.croquis.manches ~= croquisRef.manches or temoin.croquis.col ~= croquisRef.col or temoin.croquis.jupe ~= croquisRef.jupe then
			autres += 1
		end
		if not Notation.verifierExigences(exigences, Notation.bilan(recetteTemoin(temoin))) then
			faux += 1
		end
	else
		genres.impossible = true
	end
end
U.verifier(#differences == 0, "quatre cents jeux d'exigences : même réponse que le calcul complet (en défaut : " .. table.concat(differences, ", ") .. ")")
U.verifier(autres == 0 and faux == 0, ("le témoin est la première robe du calcul complet (%d autres) et, cousu, remplit les exigences (%d faux)"):format(autres, faux))
U.verifier(genres.simple and genres.ajout and genres.impossible, "des jeux réalisables simplement, avec des décorations ajoutées, et impossibles")

---------------------------------------------------------------------------
-- Tout ouvert, chaque étiquette atteint 60 (les motifs 100) et chaque matière peut dominer
---------------------------------------------------------------------------
local manquees = {}
for _, o in ipairs(Catalogue.OCCASIONS) do
	if not Commandes.realisable({ { type = "occasion", occasion = o, valeur = 60 } }) then
		table.insert(manquees, o)
	end
end
for _, t in ipairs(Catalogue.TRAITS) do
	local valeur = if table.find(Etiquettes.MOTIFS, t) then 100 else 60
	if not Commandes.realisable({ { type = "trait", trait = t, valeur = valeur } }) then
		table.insert(manquees, t)
	end
end
for _, m in ipairs(MATIERES) do
	if not Commandes.realisable({ { type = "matiere", matiere = m } }) then
		table.insert(manquees, m)
	end
end
U.verifier(#manquees == 0, "tout ouvert, chaque occasion et chaque trait atteignent 60, chaque matière peut dominer (manquées : " .. table.concat(manquees, ", ") .. ")")
local ok, temoin = Commandes.realisable({ { type = "trait", trait = "travaillee", valeur = 60 } })
U.verifier(ok and temoin.ajout and temoin.ajout.nombre == 7 and Notation.poids(Patron.piecesDuCroquis(temoin.croquis)) == 7, "Travaillée 60 : la première robe assez riche (poids 7 : corsage droit, manches ballon, col Claudine, jupe à volant) et sept objets")
U.verifier(not Commandes.realisable({ { type = "trait", trait = "travaillee", valeur = 60 } }, Deblocages.ouverts({ prestige = 0, clientes = {} })), "au départ, sans volant ni basque, aucune robe n'est assez travaillée")
U.verifier(not Commandes.realisable({ { type = "trait", trait = "chaude", valeur = 10 }, { type = "trait", trait = "legere", valeur = 10 } }), "Légère et Chaude à la fois : impossible")
