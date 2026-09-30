-- Sous-projet 6 : les mesures se prennent en tournant trois molettes sur un mannequin. Une molette : un cran de
-- 0,1 dm tous les 12 px de glissement (vers le haut, elle augmente), entre deux bornes.
local Molette = U.module("Molette")

local m = Molette.nouvelle(6.2, 2, 14)
U.verifier(m.valeur == 6.2, "une molette part de sa valeur")
U.verifier(m:crans(1) == 6.3 and m:crans(-3) == 6, "un cran : 0,1 dm, dans les deux sens")
U.verifier(m:glisser(-12) == 6.1, "glisser de 12 px vers le haut : un cran de plus")
U.verifier(m:glisser(24) == 5.9, "glisser de 24 px vers le bas : deux crans de moins")
-- Le reste est gardé : deux petits glissements de 7 px font un cran (14 px), pas zéro
m:glisser(-7)
U.verifier(m.valeur == 5.9, "7 px : pas encore un cran")
U.verifier(m:glisser(-7) == 6, "7 px de plus : un cran (le reste était gardé)")
-- Des valeurs toujours au dixième près, quel que soit le nombre de crans
for _ = 1, 37 do
	m:crans(1)
end
U.verifier(m.valeur == 9.7 and math.abs(m.valeur * 10 - math.round(m.valeur * 10)) < 1e-9, "au dixième près après 37 crans (" .. m.valeur .. ")")
-- Les bornes : butée, et le glissement en trop est oublié
U.verifier(m:glisser(-12 * 100) == 14, "tournée trop loin : s'arrête à sa borne haute")
U.verifier(m:glisser(12) == 13.9, "en butée, le glissement en trop ne compte pas : un cran vers le bas redescend tout de suite")
U.verifier(m:glisser(12 * 500) == 2 and m:crans(-1) == 2, "borne basse")
-- Régler directement (reprendre les mesures) ; la fente tourne avec la molette
local r = Molette.nouvelle(6, 2, 14)
U.verifier(r:regler(8.93) == 8.9 and r:regler(40) == 14, "régler directement : au dixième, dans les bornes")
local f = Molette.nouvelle(6, 2, 14)
f:crans(2)
U.verifier(f:angle() == 2 * Molette.DEGRES_PAR_CRAN, "la fente tourne d'un angle fixe par cran")
f:crans(-5)
U.verifier(f:angle() == -3 * Molette.DEGRES_PAR_CRAN, "et revient en arrière")
