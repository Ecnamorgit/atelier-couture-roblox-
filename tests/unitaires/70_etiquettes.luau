-- Sous-projet 7 : seize étiquettes. Aux six styles s'ajoutent trois occasions (points des variantes et des matières)
-- et sept traits calculés d'après la robe : Légère / Chaude (matière, manches, longueur), Sobre / Travaillée (poids des
-- pièces, décorations), Unie / Fleurie / À motifs (surface par motif) ; et la matière dominante.
local Catalogue = U.module("Catalogue")
local Etiquettes = U.module("Etiquettes")
local Notation = U.module("Notation")
local Patron = U.module("Patron")

---------------------------------------------------------------------------
-- Données : chaque variante et chaque matière ont leurs occasions ; chaque matière, un nom et une chaleur
---------------------------------------------------------------------------
local fautes = {}
local function occasionsLisibles(t)
	if type(t) ~= "table" then
		return false
	end
	for o, pts in pairs(t) do
		if not table.find(Catalogue.OCCASIONS, o) or type(pts) ~= "number" or pts < 0 then
			return false
		end
	end
	return true
end
for _, v in ipairs(Catalogue.Variantes) do
	if not occasionsLisibles(v.occasion) then
		table.insert(fautes, v.id)
	end
end
for _, t in ipairs(Catalogue.Tissus) do
	local m = Catalogue.MATIERES[t.matiere]
	if not occasionsLisibles(m.occasion) or type(m.nom) ~= "string" or type(m.chaleur) ~= "number" or math.abs(m.chaleur) > 1 then
		table.insert(fautes, t.matiere)
	end
end
U.verifier(#fautes == 0, "chaque variante et chaque matière ont leurs occasions, un nom et une chaleur entre -1 et 1 (en défaut : " .. table.concat(fautes, ", ") .. ")")
U.verifier(#Catalogue.OCCASIONS == 3 and #Catalogue.TRAITS == 7 and Catalogue.NOMS_OCCASIONS.soiree == "Soirée" and Catalogue.NOMS_TRAITS.a_motifs == "À motifs", "trois occasions, sept traits, et leurs noms")

---------------------------------------------------------------------------
-- Une robe : toutes ses pièces dans un tissu (ou selon une fonction de la pièce), droit-fil et couture parfaits
---------------------------------------------------------------------------
local function robe(croquis, tissuDe, accessoires)
	local recette = { croquis = croquis, pieces = {}, accessoires = accessoires or {} }
	for _, id in ipairs(Patron.piecesDuCroquis(croquis)) do
		local tissu = if type(tissuDe) == "function" then tissuDe(id) else tissuDe
		table.insert(recette.pieces, { id = id, tissu = tissu, x = 0, y = 0, angle = Catalogue.piece(id).biais and 45 or 0, couture = 1 })
	end
	return Notation.bilan(recette), recette
end
local SIMPLE = { corsage = "corsage_droit", manches = "manches_sans", col = "col_sans", jupe = "jupe_droite" }
local RICHE = { corsage = "corsage_basque", manches = "manches_ballon", col = "col_claudine", jupe = "jupe_volant" }
local CHAUDE = { corsage = "corsage_droit", manches = "manches_longues", col = "col_sans", jupe = "jupe_evasee" }
local LEGERE = { corsage = "corsage_bustier", manches = "manches_sans", col = "col_sans", jupe = "jupe_droite" }
local function objets(id, n)
	local out = {}
	for _ = 1, n do
		table.insert(out, { id = id, piece = 1, u = 0.5, v = 0.5, echelle = 1, angle = 0 })
	end
	return out
end

---------------------------------------------------------------------------
-- Légère / Chaude : 0,6 × chaleur de la matière + 0,25 × (2 × manches − 1) + 0,15 × (2 × longueur − 1)
---------------------------------------------------------------------------
local b = robe(CHAUDE, "laine_noire")
U.verifier(U.proche(b.traits.chaude, 94) and b.traits.legere == 0, ("laine, manches longues, jupe longue : Chaude 94, Légère 0 (%g, %g)"):format(b.traits.chaude, b.traits.legere))
b = robe(LEGERE, "organza_blanc")
U.verifier(U.proche(b.traits.legere, 94) and b.traits.chaude == 0, ("organza, sans manches, jupe courte : Légère 94, Chaude 0 (%g, %g)"):format(b.traits.legere, b.traits.chaude))
b = robe(RICHE, "coton_blanc")
local attendu = 30 + 25 * (1 - 2 * 1.8 / 5.6) + 15 * (1 - 2 * 0.2)
U.verifier(U.proche(b.traits.legere, attendu), ("coton, manches ballon (1,8 dm), volant jusqu'à 6,6 dm : Légère %.3f (%.3f)"):format(attendu, b.traits.legere))

---------------------------------------------------------------------------
-- Sobre / Travaillée : (poids − 4) / 4 + décorations / 8 − 1 ; un objet compte 1, une garniture 1 pour 5 dm
---------------------------------------------------------------------------
b = robe(SIMPLE, "coton_blanc")
U.verifier(b.traits.sobre == 100 and b.traits.travaillee == 0, "une robe simple sans décoration : Sobre 100")
b = robe(SIMPLE, "coton_blanc", objets("bouton_nacre", 1))
local bG = robe(SIMPLE, "coton_blanc", { { id = "ruban_rose", piece = 3, trajet = { { u = 0, v = 0.5 }, { u = 1, v = 0.5 }, { u = 0, v = 0.5 } } } })
U.verifier(U.proche(b.traits.sobre, 87.5) and U.proche(bG.traits.sobre, 75), ("un bouton : une décoration, Sobre 87,5 ; 10 dm de ruban : deux, Sobre 75 (%g, %g)"):format(b.traits.sobre, bG.traits.sobre))
b = robe(RICHE, "coton_blanc")
U.verifier(Notation.poids(Patron.piecesDuCroquis(RICHE)) == 8 and b.traits.sobre == 0 and b.traits.travaillee == 0, "une robe riche (poids 8) sans décoration : ni sobre ni travaillée")
b = robe(RICHE, "coton_blanc", objets("perle", 4))
local b12 = robe(RICHE, "coton_blanc", objets("perle", 12))
U.verifier(U.proche(b.traits.travaillee, 50) and b12.traits.travaillee == 100, ("quatre perles : Travaillée 50 ; douze : 100, pas plus (%g, %g)"):format(b.traits.travaillee, b12.traits.travaillee))

---------------------------------------------------------------------------
-- Unie / Fleurie / À motifs : la part de la surface de chaque motif
---------------------------------------------------------------------------
b = robe(SIMPLE, function(id)
	return if id:find("^corsage") then "coton_blanc" else "coton_jaune_fleurs"
end)
local partCorsage = 100 * 2 * 4.8 * 4.2 / (2 * 4.8 * 4.2 + 2 * 5 * 6)
U.verifier(U.proche(b.traits.unie, partCorsage) and U.proche(b.traits.fleurie, 100 - partCorsage) and b.traits.a_motifs == 0, ("corsage uni, jupe fleurie : Unie %.2f, Fleurie %.2f (%.2f, %.2f)"):format(partCorsage, 100 - partCorsage, b.traits.unie, b.traits.fleurie))
b = robe(SIMPLE, "coton_bleu_carreaux")
local bD = robe(SIMPLE, "soie_bleue_degrade")
U.verifier(b.traits.a_motifs == 100 and bD.traits.a_motifs == 100 and b.traits.unie == 0, "carreaux, dégradé : À motifs 100")

---------------------------------------------------------------------------
-- Occasions : points des variantes (K 1) et de la matière (K 2), comme les styles
---------------------------------------------------------------------------
b = robe(SIMPLE, "coton_blanc")
U.verifier(b.occasions.journee == 8 + 40 and b.occasions.soiree == 8 and b.occasions.travail == 16 + 12, ("robe simple en coton : Journée 48, Soirée 8, Travail 28 (%g, %g, %g)"):format(b.occasions.journee, b.occasions.soiree, b.occasions.travail))
local compte = 0
for _ in pairs(b.scores) do
	compte += 1
end
U.verifier(compte == 16 and b.scores.elegant == b.styles.elegant and b.scores.journee == 48 and b.scores.sobre == 100, "le bilan réunit les seize étiquettes (" .. compte .. ")")

---------------------------------------------------------------------------
-- Matière dominante : surfaces additionnées par matière ; à égalité, celle de la première pièce
---------------------------------------------------------------------------
b = robe(SIMPLE, function(id)
	return if id:find("^corsage") then "soie_ivoire" else "coton_blanc"
end)
local bEgal = robe(SIMPLE, function(id)
	return if id:find("devant$") then "soie_ivoire" else "coton_blanc"
end)
U.verifier(b.matiere == "coton" and bEgal.matiere == "soie", ("matière dominante : la plus grande surface (coton : %s) ; à égalité, la première pièce (soie : %s)"):format(tostring(b.matiere), tostring(bEgal.matiere)))

---------------------------------------------------------------------------
-- Jugement : au moins la valeur (à l'arrondi près), la matière dominante
---------------------------------------------------------------------------
b = robe(CHAUDE, "laine_noire")
local function juge(e)
	return (Notation.verifierExigences({ e }, b))
end
U.verifier(juge({ type = "trait", trait = "chaude", valeur = 94 }) and not juge({ type = "trait", trait = "chaude", valeur = 95 }) and not juge({ type = "trait", trait = "legere", valeur = 10 }), "trait : au moins la valeur")
U.verifier(juge({ type = "occasion", occasion = "travail", valeur = b.occasions.travail }) and not juge({ type = "occasion", occasion = "travail", valeur = b.occasions.travail + 1 }), "occasion : au moins la valeur")
U.verifier(juge({ type = "matiere", matiere = "laine" }) and not juge({ type = "matiere", matiere = "velours" }), "matière : la matière dominante")

---------------------------------------------------------------------------
-- Carnet : la fourchette des tissus encore à choisir ; tous choisis, elle se réduit au score de la robe
---------------------------------------------------------------------------
local function tous(croquis, tissu)
	local choix = {}
	for _, id in ipairs(Patron.piecesDuCroquis(croquis)) do
		choix[id] = tissu
	end
	return choix
end
local ecarts = {}
for _, croquis in ipairs({ SIMPLE, RICHE, CHAUDE }) do
	for _, t in ipairs(Catalogue.Tissus) do
		local f = Notation.fourchette(croquis, tous(croquis, t.id))
		local bT = robe(croquis, t.id)
		for _, cle in ipairs({ "journee", "soiree", "travail", "chaude", "legere", "unie", "fleurie", "a_motifs" }) do
			local v = bT.scores[cle]
			if not (U.proche(f[cle].min, v) and U.proche(f[cle].max, v)) then
				table.insert(ecarts, ("%s en %s : %s"):format(croquis.jupe, t.id, cle))
			end
		end
	end
end
U.verifier(#ecarts == 0, "tous les tissus choisis : la fourchette se réduit au score (en défaut : " .. table.concat(ecarts, " ; ", 1, math.min(#ecarts, 5)) .. ")")
local function prevoir(e, croquis, choix, ouverts, imposes)
	return Notation.prevision(e, croquis, choix, Notation.fourchette(croquis, choix, imposes, ouverts))
end
local depart = {}
for _, t in ipairs(Catalogue.Tissus) do
	if t.matiere == "coton" or t.matiere == "lin" or t.matiere == "jute" then
		depart[t.id] = true
	end
end
local chaude60 = { type = "trait", trait = "chaude", valeur = 60 }
U.verifier(prevoir(chaude60, CHAUDE, {}) == "?" and prevoir(chaude60, CHAUDE, {}, depart) == "non" and prevoir(chaude60, CHAUDE, tous(CHAUDE, "laine_noire")) == "ok", "Chaude 60 : possible en laine, pas en coton, lin ni jute ; tenue une fois la laine choisie")
U.verifier(prevoir({ type = "occasion", occasion = "soiree", valeur = 60 }, LEGERE, {}) == "non" and prevoir({ type = "occasion", occasion = "soiree", valeur = 50 }, LEGERE, {}) == "?" and prevoir({ type = "occasion", occasion = "soiree", valeur = 50 }, LEGERE, tous(LEGERE, "organza_blanc")) == "ok", "Soirée : 18 de la robe et 40 au plus de la matière (58)")
local sobre60, travaillee60 = { type = "trait", trait = "sobre", valeur = 60 }, { type = "trait", trait = "travaillee", valeur = 60 }
U.verifier(prevoir(sobre60, SIMPLE, {}) == "?" and prevoir(travaillee60, SIMPLE, {}) == "non" and prevoir(travaillee60, RICHE, {}) == "?", "Sobre et Travaillée dépendent des décorations à venir ; une robe simple n'est jamais travaillée")
U.verifier(prevoir(sobre60, RICHE, {}) == "non" and prevoir({ type = "trait", trait = "sobre", valeur = 90 }, SIMPLE, {}, nil, { { id = "broche_camee" } }) == "non", "une robe riche n'est jamais sobre ; une broche imposée compte")
local corsageUni = { corsage_droit_devant = "coton_blanc", corsage_droit_dos = "coton_blanc" }
local unie40, unie50 = { type = "trait", trait = "unie", valeur = 40 }, { type = "trait", trait = "unie", valeur = 50 }
local jupeFleurie = table.clone(corsageUni)
jupeFleurie.jupe_droite_devant, jupeFleurie.jupe_droite_dos = "coton_jaune_fleurs", "coton_jaune_fleurs"
U.verifier(prevoir(unie40, SIMPLE, corsageUni) == "ok" and prevoir(unie50, SIMPLE, corsageUni) == "?" and prevoir(unie50, SIMPLE, jupeFleurie) == "non", "Unie : le corsage uni fait 40 % de la surface")
local matiere = { type = "matiere", matiere = "coton" }
U.verifier(prevoir(matiere, SIMPLE, corsageUni) == "?" and prevoir(matiere, SIMPLE, jupeFleurie) == "ok" and prevoir(matiere, SIMPLE, tous(SIMPLE, "lin_bleu")) == "non", "matière : connue une fois toutes les pièces choisies")
