-- Plan 23 : la jupe à traîne. Côté dos, la jupe longue évasée continue au-delà du sol, à plat vers l'arrière : juste
-- au-dessus du sol, hors du socle du mannequin, dans le socle de la vitrine ; ses côtés restent cousus au devant.
local Catalogue = U.module("Catalogue")
local Patron = U.module("Patron")
local Polygone = U.module("Polygone")
local Mannequin = U.module("Mannequin")
local Croquis = U.module("Croquis")
local Deblocages = U.module("Deblocages")
local Clientes = U.module("Clientes")
local Etiquettes = U.module("Etiquettes")
local Boutique = U.module("Boutique")

local v = Catalogue.variante("jupe_traine")
U.verifier(v and table.concat(v.pieces, ",") == "traine_devant,traine_dos" and Deblocages.raison("variantes", "jupe_traine") == "Prestige 8" and Croquis.connue("jupe_traine"), "la jupe à traîne : un devant de jupe longue et la traîne ; au prestige 8 ; dessinée")
-- (relecture) Juste au-dessus du plancher de la boutique (le mannequin de l'atelier a sa taille à 9 dm du sol du monde,
-- le plancher dépasse de Boutique.PLANCHER) et du socle de la vitrine (9 dm sous la taille)
local plancher = Mannequin.HAUTEUR_TAILLE - Boutique.PLANCHER / Catalogue.STUDS_PAR_DM
U.verifier(Boutique.MANNEQUIN.Position.Y == Mannequin.HAUTEUR_TAILLE * Catalogue.STUDS_PAR_DM and Patron.SOL <= plancher - 0.1 and Patron.SOL >= plancher - 0.3, ("la traîne se couche juste au-dessus du plancher de la boutique (%.2f dm sous la taille, plancher à %.2f)"):format(Patron.SOL, plancher))

-- Les points de la traîne (grille serrée), aux mesures du catalogue et des clientes (à 1,5 dm près)
local mesuresEssai = table.clone(Catalogue.TAILLES)
for _, c in ipairs(Clientes.LISTE) do
	mesuresEssai[c.id] = c.mesures
	mesuresEssai[c.id .. " large"] = { poitrine = c.mesures.poitrine + 1.5, taille = c.mesures.taille + 1.5, hanches = c.mesures.hanches + 1.5 }
end
local contour = Catalogue.piece("traine_dos").contour
local b = Polygone.boite(contour)
local DEMI_SOCLE = 2 -- dm : rayon du socle du mannequin (4 dm de large)
local VITRINE = 2 / Catalogue.STUDS_PAR_DM -- dm : demi-largeur du socle de la vitrine (4 studs)
local bas, dedans, horsSocle, dehorsVitrine = 0, 0, {}, {}
for nom, m in pairs(mesuresEssai) do
	for j = 0, 44 do
		local y = b.minY + (b.maxY - b.minY) * j / 44
		local x0, x1 = Polygone.etendueLigne(contour, y)
		for i = 0, 20 do
			local p = Patron.point("traine_dos", "unique", x0 + (x1 - x0) * i / 20, y, m)
			if p.Y < -Patron.SOL + 1e-9 then
				bas += 1
				dedans += if math.abs(p.Y + Patron.SOL) < 1e-9 then 1 else 0
			end
			if p.Y < -(Mannequin.HAUTEUR_TAILLE - 0.3) and math.sqrt(p.X ^ 2 + p.Z ^ 2) < DEMI_SOCLE then
				horsSocle[nom] = true
			end
			if math.abs(p.X) > VITRINE or math.abs(p.Z) > VITRINE then
				dehorsVitrine[nom] = true
			end
		end
	end
end
local function noms(t)
	local liste = {}
	for n in pairs(t) do
		table.insert(liste, n)
	end
	table.sort(liste)
	return table.concat(liste, ", ")
end
U.verifier(bas > 0 and dedans == bas, ("au-delà du sol, la traîne est à plat, à 0,1 dm au-dessus (%d points sur %d)"):format(dedans, bas))
U.verifier(noms(horsSocle) == "", "la traîne passe hors du socle du mannequin (en défaut : " .. noms(horsSocle) .. ")")
U.verifier(noms(dehorsVitrine) == "", "la traîne reste sur le socle de la vitrine (en défaut : " .. noms(dehorsVitrine) .. ")")

-- Vers l'arrière : au milieu du dos, l'ourlet de la traîne est 2,1 dm plus loin que la jupe au sol
local M = Catalogue.TAILLES.M
local auSol = Patron.point("traine_dos", "unique", 5, Patron.SOL, M) -- (le milieu de chaque ligne de la traîne est à x = 5)
local milieu = Patron.point("traine_dos", "unique", 5, 11, M)
U.verifier(milieu.Z > auSol.Z + 2.1 * Patron.ELLIPSE.z - 0.05 and math.abs(milieu.X) < 0.05, ("la traîne s'étend vers l'arrière (%.2f dm derrière la jupe)"):format(milieu.Z - auSol.Z))

-- Ses côtés restent cousus au devant : jusqu'au sol, chaque bord de la traîne rejoint le bord du devant, qui est celui
-- de la jupe longue
local ecart = 0
for j = 0, 20 do
	local yd = 9 * j / 20 -- (jusqu'en bas du devant : passé le sol, les deux se couchent au même endroit)
	local x0, x1 = Polygone.etendueLigne(contour, yd)
	local e0, e1 = Polygone.etendueLigne(Catalogue.piece("traine_devant").contour, yd)
	local dosDroit = Patron.point("traine_dos", "unique", x0, yd, M) -- u = 0 : côté −X
	local dosGauche = Patron.point("traine_dos", "unique", x1, yd, M) -- u = 1 : côté +X
	local devantDroit = Patron.point("traine_devant", "unique", e1, yd, M)
	local devantGauche = Patron.point("traine_devant", "unique", e0, yd, M)
	if yd <= Patron.SOL then -- (au-dessus du sol, le devant est celui de la jupe longue)
		local longue = Patron.point("jupe_evasee_devant", "unique", e1, yd, M)
		ecart = math.max(ecart, (longue - devantDroit).Magnitude)
	end
	ecart = math.max(ecart, (dosDroit - devantDroit).Magnitude, (dosGauche - devantGauche).Magnitude)
end
U.verifier(ecart < 1e-6, ("les côtés de la traîne rejoignent ceux du devant (écart %.6f dm)"):format(ecart))

-- (relecture) Le devant ne s'étend pas : son ourlet garde une normale tournée vers l'extérieur, pas vers le ciel
local b2 = Polygone.boite(Catalogue.piece("traine_devant").contour)
local n = Patron.normale("traine_devant", "unique", (b2.minX + b2.maxX) / 2, b2.maxY, M)
local nDos = Patron.normale("traine_dos", "unique", 5, 10.5, M)
U.verifier(math.abs(n.Y) < 0.5 and n.Z < -0.5 and nDos.Y > 0.9, ("l'ourlet du devant regarde devant (%.2f, %.2f, %.2f) ; la traîne couchée, le ciel"):format(n.X, n.Y, n.Z))

-- (relecture) Le dessin : la jupe et sa traîne sont une même partie ; les toucher choisit les deux pièces
local TRAINE = { corsage = "corsage_droit", manches = "manches_sans", col = "col_sans", jupe = "jupe_traine" }
local _, piecesTraine = Croquis.partieA(TRAINE, 50, 126)
local _, piecesJupe = Croquis.partieA(TRAINE, 50, 80)
U.verifier(table.concat(piecesTraine or {}, ",") == "traine_devant,traine_dos" and table.concat(piecesJupe or {}, ",") == "traine_devant,traine_dos", "toucher la traîne ou la jupe : le devant et la traîne ensemble")

-- Une jupe longue : la traîne rend la robe aussi chaude qu'une jupe évasée
U.verifier(Etiquettes.variante("jupe_traine").chaleur == Etiquettes.variante("jupe_evasee").chaleur, "longueur : la traîne compte comme une jupe longue")
