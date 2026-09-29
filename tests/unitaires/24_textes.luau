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
