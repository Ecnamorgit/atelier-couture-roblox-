-- Sous-projet 7 : la jupe à volant et le corsage à basque. Les variantes d'avant ne changent pas de pièces (les
-- recettes gardées restent valides) ; une robe a 12 pièces et 16 copies au plus ; le dessin colorie le volant de son
-- tissu ; la paie compte le poids des pièces ; une robe à volant se fait de bout en bout.
local Catalogue = U.module("Catalogue")
local Patron = U.module("Patron")
local Croquis = U.module("Croquis")
local Pixels = U.module("Pixels")
local Notation = U.module("Notation")
local Metrage = U.module("Metrage")
local Deblocages = U.module("Deblocages")
local EtatAtelier = U.module("EtatAtelier")
local Clientes = U.module("Clientes")

---------------------------------------------------------------------------
-- Les variantes d'avant gardent leurs pièces
---------------------------------------------------------------------------
local AVANT = {
	corsage_droit = { "corsage_droit_devant", "corsage_droit_dos" },
	corsage_v = { "corsage_v_devant", "corsage_droit_dos" },
	corsage_bretelles = { "corsage_bretelles_devant", "corsage_bretelles_dos" },
	corsage_cache_coeur = { "corsage_cache_coeur_devant", "corsage_droit_dos" },
	corsage_bustier = { "corsage_bustier_devant", "corsage_bustier_dos" },
	manches_sans = {},
	manches_ballon = { "manche_ballon" },
	manches_longues = { "manche_longue" },
	manches_courtes = { "manche_courte" },
	manches_trois_quarts = { "manche_trois_quarts" },
	col_sans = {},
	col_claudine = { "col_claudine" },
	col_montant = { "col_montant" },
	col_marin = { "col_marin" },
	jupe_droite = { "jupe_droite_devant", "jupe_droite_dos" },
	jupe_trapeze = { "jupe_trapeze_devant", "jupe_trapeze_dos" },
	jupe_ample = { "jupe_ample_devant", "jupe_ample_dos" },
	jupe_evasee = { "jupe_evasee_devant", "jupe_evasee_dos" },
	jupe_crayon = { "jupe_crayon_devant", "jupe_crayon_dos" },
	-- (plan 23) celles du plan 19
	corsage_basque = { "corsage_droit_devant", "corsage_droit_dos", "basque_devant", "basque_dos" },
	jupe_volant = { "jupe_droite_devant", "jupe_droite_dos", "volant_devant", "volant_dos" },
}
local changees = {}
for id, pieces in pairs(AVANT) do
	local v = Catalogue.variante(id)
	if not v or table.concat(v.pieces, ",") ~= table.concat(pieces, ",") then
		table.insert(changees, id)
	end
end
table.sort(changees)
U.verifier(#changees == 0, "les variantes d'avant gardent leurs pièces (changées : " .. table.concat(changees, ", ") .. ")")
U.verifier(Catalogue.variante("jupe_volant").famille == "jupe" and Catalogue.variante("corsage_basque").famille == "corsage", "deux nouvelles variantes : la jupe à volant, le corsage à basque")

---------------------------------------------------------------------------
-- 12 pièces et 16 copies au plus ; chaque paire de couches d'un croquis est de celles que 67_couches vérifie
---------------------------------------------------------------------------
local listes = {}
for _, famille in ipairs(Catalogue.FAMILLES) do
	listes[famille] = Catalogue.variantesDe(famille)
end
local maxPieces, maxCopies, inconnues = 0, 0, {}
for _, co in ipairs(listes.corsage) do
	for _, ma in ipairs(listes.manches) do
		for _, cl in ipairs(listes.col) do
			for _, ju in ipairs(listes.jupe) do
				local pieces = Patron.piecesDuCroquis({ corsage = co.id, manches = ma.id, col = cl.id, jupe = ju.id })
				local copies = 0
				for _, id in ipairs(pieces) do
					copies += #Patron.copies(id)
				end
				maxPieces, maxCopies = math.max(maxPieces, #pieces), math.max(maxCopies, copies)
				for _, dessus in ipairs(pieces) do
					local eD = Catalogue.piece(dessus).enroulement
					for _, dessous in ipairs(pieces) do
						local eS = Catalogue.piece(dessous).enroulement
						if eD.type == "jupe" and eS.type == "jupe" and eD.cote == eS.cote and (eD.couche or 0) > (eS.couche or 0) then
							local verifiee = (dessus:match("^basque_") and not eS.couche) or (dessus:match("^volant_") and dessous:match("^jupe_droite_"))
								or (dessus:match("^etage_") and dessous:match("^jupe_droite_")) or (dessus:match("^jupe_dessus_") and dessous:match("^jupon_"))
								or (dessus:match("^basque_") and dessous:match("^jupe_dessus_"))
							if not verifiee then
								inconnues[dessus .. " sur " .. dessous] = true
							end
						end
					end
				end
			end
		end
	end
end
local noms = {}
for n in pairs(inconnues) do
	table.insert(noms, n)
end
U.verifier(maxPieces <= 12 and maxCopies <= 16, ("une robe : 12 pièces et 16 copies au plus (%d, %d)"):format(maxPieces, maxCopies))
U.verifier(#noms == 0, "chaque couche d'un croquis est vérifiée par 67_couches (non vérifiées : " .. table.concat(noms, ", ") .. ")")

---------------------------------------------------------------------------
-- Le dessin : le volant a sa partie, son tissu, et le toucher choisit le tissu des volants
---------------------------------------------------------------------------
local AVEC_VOLANT = { corsage = "corsage_basque", manches = "manches_sans", col = "col_sans", jupe = "jupe_volant" }
local volant
for _, p in ipairs(Croquis.parties(AVEC_VOLANT)) do
	if p.pieces and p.pieces[1] == "volant_devant" then
		volant = p
	end
end
U.verifier(volant ~= nil and volant.famille == "jupe" and #volant.pieces == 2, "le volant est une partie du dessin, qui porte ses pièces")
local fam, pieces = Croquis.partieA(AVEC_VOLANT, 50, 83)
local famJupe, piecesJupe = Croquis.partieA(AVEC_VOLANT, 50, 60)
local famBasque, piecesBasque = Croquis.partieA(AVEC_VOLANT, 50, 47)
U.verifier(fam == "jupe" and table.concat(pieces, ",") == "volant_devant,volant_dos", "toucher le volant : ses deux pièces")
U.verifier(famJupe == "jupe" and table.concat(piecesJupe, ",") == "jupe_droite_devant,jupe_droite_dos", "toucher la jupe : ses pièces, pas celles du volant (son tissu reste le sien)")
local famCorps, piecesCorps = Croquis.partieA(AVEC_VOLANT, 50, 30)
U.verifier(famCorps == "corsage" and table.concat(piecesCorps, ",") == "corsage_droit_devant,corsage_droit_dos", "toucher le corps du corsage : ses pièces, pas celles de la basque")
U.verifier(famBasque == "corsage" and table.concat(piecesBasque, ",") == "basque_devant,basque_dos", "toucher la basque : ses deux pièces")
local function pixel(buf, largeur, x, y)
	return buffer.readu32(buf, (y * largeur + x) * 4)
end
local memes = Pixels.croquis(AVEC_VOLANT, { jupe = "coton_blanc", volant_devant = "coton_blanc" }, 100, 130)
local autre = Pixels.croquis(AVEC_VOLANT, { jupe = "coton_blanc", volant_devant = "velours_noir" }, 100, 130)
U.verifier(pixel(memes, 100, 52, 81) == pixel(memes, 100, 50, 60) and pixel(autre, 100, 52, 81) ~= pixel(autre, 100, 50, 60) and pixel(autre, 100, 50, 60) == pixel(memes, 100, 50, 60), "le volant prend le tissu de ses pièces, la jupe garde le sien")

---------------------------------------------------------------------------
-- La paie compte le poids des pièces ; les robes d'avant gardent la leur
---------------------------------------------------------------------------
U.verifier(Notation.poids({ "jupe_droite_devant", "jupe_droite_dos" }) == 2 and Notation.poids(Patron.piecesDuCroquis(AVEC_VOLANT)) == 6, "poids : 2 pour une jupe droite ; 6 pour corsage à basque et jupe à volant (4 pièces et 4 demi-pièces)")
U.verifier(Notation.poids({ { id = "volant_dos" } }) == 0.5, "le poids se lit aussi sur les pièces d'une recette")
U.verifier(Notation.base(2, 1) == 20 + 20 + 15, "Notation.base : 20 + 10 par poids + 15 par exigence")

---------------------------------------------------------------------------
-- Ouvertes au prestige 4 (jupe à volant) et 5 (corsage à basque)
---------------------------------------------------------------------------
local e = EtatAtelier.nouveau()
e.prestige = 49 -- niveau 3
U.verifier(not Deblocages.ouvert(e, "variantes", "jupe_volant") and Deblocages.raison("variantes", "jupe_volant") == "Prestige 4", "la jupe à volant s'ouvre au prestige 4")
U.verifier(Deblocages.raison("variantes", "corsage_basque") == "Prestige 5", "le corsage à basque, au prestige 5")

---------------------------------------------------------------------------
-- Une robe à volant et à basque, de bout en bout : coupée, épinglée, cousue, livrée, payée selon son poids
---------------------------------------------------------------------------
local r = EtatAtelier.nouveau(1000)
U.commander(r, Random.new(3))
local ids = Patron.piecesDuCroquis(AVEC_VOLANT)
local tissus = {}
for _, id in ipairs(ids) do
	tissus[id] = "coton_blanc"
end
assert(r:validerCroquis(AVEC_VOLANT, tissus).ok)
local placements, longueur = Metrage.disposition(ids)
assert(r:acheter("coton_blanc", longueur).ok and r:commencerDecoupe().ok)
for _, id in ipairs(ids) do
	local c = r:couper(id, placements[id])
	assert(c.ok, id .. " : " .. tostring(c.erreur))
end
for _, id in ipairs(ids) do
	assert(r:epingler(id).ok, id)
end
for _, id in ipairs(ids) do
	local _, l = Patron.trajetCouture(id)
	assert(r:rendreCouture(id, table.create(math.round(l / 0.1), 0.02), l).ok, id)
end
assert(r:decorer({}).ok)
r.commande.exigences = { { type = "qualite", valeur = 0.1 } }
local acompte, bilan = r.commande.acompte, r:bilan()
local l = r:livrer()
U.verifier(l.ok and l.reussie and l.paie == Notation.paie(6, 1, bilan.qualite) and l.verse == l.paie - acompte, ("robe à volant et à basque livrée : payée pour un poids de 6 (%s po)"):format(tostring(l.paie)))
U.verifier(Clientes ~= nil, "(modules chargés)")
