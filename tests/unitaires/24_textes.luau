local UiKit = U.module("UiKit")
local Catalogue = U.module("Catalogue")
local Notation = U.module("Notation")

-- Le score affiché ne contredit jamais le jugement de la cliente (arrondi du côté de la comparaison)
local auMoins = { type = "min", style = "elegant", valeur = 30 }
local auPlus = { type = "max", style = "elegant", valeur = 20 }
local function juge(e, score)
	local ok = Notation.verifierExigences({ e }, { styles = { elegant = score }, qualite = 1, teinte = "rose", accessoires = {} })
	return ok
end
U.verifier(not juge(auMoins, 29.5) and UiKit.exigence(auMoins, Catalogue, { elegant = 29.5 }) == "Au moins 30 en Élégant (actuel : 29)", "au moins 30 raté à 29,5 : affiché 29")
U.verifier(juge(auMoins, 30) and UiKit.exigence(auMoins, Catalogue, { elegant = 30 }) == "Au moins 30 en Élégant (actuel : 30)", "au moins 30 atteint à 30 : affiché 30")
U.verifier(not juge(auPlus, 20.4) and UiKit.exigence(auPlus, Catalogue, { elegant = 20.4 }) == "Au plus 20 en Élégant (actuel : 21)", "au plus 20 raté à 20,4 : affiché 21")
U.verifier(juge(auPlus, 20) and UiKit.exigence(auPlus, Catalogue, { elegant = 20 }) == "Au plus 20 en Élégant (actuel : 20)", "au plus 20 tenu à 20 : affiché 20")
U.verifier(UiKit.exigence(auMoins, Catalogue) == "Au moins 30 en Élégant", "sans scores : l'exigence seule (carnet)")
-- (sous-projet 7) Occasions, traits et matière, avec les seize étiquettes du bilan
local soir = { type = "occasion", occasion = "soiree", valeur = 40 }
local motifs = { type = "trait", trait = "a_motifs", valeur = 50 }
U.verifier(UiKit.exigence(soir, Catalogue, { soiree = 39.6, elegant = 80 }) == "Pour la soirée : au moins 40 (actuel : 39)", "occasion : « Pour la soirée : au moins 40 (actuel : 39) »")
U.verifier(UiKit.exigence(motifs, Catalogue, { a_motifs = 50 }) == "Robe à motifs : au moins 50 (actuel : 50)" and UiKit.exigence(motifs, Catalogue) == "Robe à motifs : au moins 50", "trait : « Robe à motifs : au moins 50 »")
U.verifier(UiKit.exigence({ type = "matiere", matiere = "crepe" }, Catalogue) == "Matière dominante : crêpe", "matière : « Matière dominante : crêpe »")
local noms = {}
for _, o in ipairs(Catalogue.OCCASIONS) do
	table.insert(noms, UiKit.exigence({ type = "occasion", occasion = o, valeur = 20 }, Catalogue))
end
for _, t in ipairs(Catalogue.TRAITS) do
	table.insert(noms, UiKit.exigence({ type = "trait", trait = t, valeur = 20 }, Catalogue))
end
U.verifier(not table.concat(noms, "|"):find("nil") and not table.concat(noms, "|"):find("%?"), "chaque occasion et chaque trait ont leur texte : " .. table.concat(noms, " | "))

-- Échelle de la fenêtre (téléphones) : réduite pour tenir, jamais nulle ni négative
U.verifier(UiKit.echelle(Vector2.new(1920, 1080)) == 1, "grand écran : échelle 1")
local telephone = UiKit.echelle(Vector2.new(844, 390))
U.verifier(telephone > 0.5 and telephone < 1, "téléphone couché : la fenêtre se réduit pour tenir (" .. telephone .. ")")
U.verifier(UiKit.echelle(Vector2.new(1, 1)) == 0.35, "écran annoncé à 1 × 1 au démarrage : échelle bornée à 0,35")
