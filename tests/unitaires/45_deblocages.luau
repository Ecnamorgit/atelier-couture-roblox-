local Deblocages = U.module("Deblocages")
local Catalogue = U.module("Catalogue")
local Clientes = U.module("Clientes")

local depart = { prestige = 0, clientes = {} }
local ouverts = Deblocages.ouverts(depart)

-- Au départ (prestige 1) : cotons et lins, les variantes de base, six accessoires (spec §4)
local tissusOuverts = {}
for _, t in ipairs(Catalogue.Tissus) do
	if ouverts.tissus[t.id] then
		table.insert(tissusOuverts, t.id)
	end
	local attendu = t.matiere == "coton" or t.matiere == "lin" or t.matiere == "jute"
	U.verifier((ouverts.tissus[t.id] == true) == attendu, t.id .. " : ouvert au départ seulement en coton, en lin ou en jute")
end
U.verifier(#tissusOuverts == 9, "neuf tissus au départ (dont la toile de jute)")
local VARIANTES_DEPART = { "corsage_droit", "corsage_v", "manches_sans", "manches_ballon", "col_sans", "col_claudine", "jupe_droite", "jupe_trapeze" }
for _, v in ipairs(Catalogue.Variantes) do
	U.verifier((ouverts.variantes[v.id] == true) == (table.find(VARIANTES_DEPART, v.id) ~= nil), v.id .. " : ouverte au départ ou par l'amitié")
end
local ACCESSOIRES_DEPART = { "bouton_nacre", "bouton_dore", "fleur_rose", "fleur_blanche", "perle", "ruban_rose" }
for _, a in ipairs(Catalogue.Accessoires) do
	U.verifier((ouverts.accessoires[a.id] == true) == (table.find(ACCESSOIRES_DEPART, a.id) ~= nil), a.id .. " : ouvert au départ ou non")
end

-- Chaque élément a au plus une condition, et chaque élément fermé a la sienne
for _, genre in ipairs(Deblocages.GENRES) do
	for id, c in pairs(Deblocages.CONDITIONS[genre]) do
		local sortes = (c.prestige and 1 or 0) + (c.cliente and 1 or 0) + (c.evenement and 1 or 0)
		U.verifier(sortes == 1, id .. " : une seule condition")
		U.verifier(c.prestige == nil or (c.prestige >= 2 and c.prestige <= 8), id .. " : un niveau de prestige possible")
		U.verifier(c.cliente == nil or (Clientes.get(c.cliente) ~= nil and (c.amitie == 2 or c.amitie == 4)), id .. " : une cliente et un niveau d'amitié")
	end
end

-- Raisons affichées
U.verifier(Deblocages.raison("tissus", "laine_bordeaux") == "Prestige 2" and Deblocages.raison("tissus", "soie_rouge") == "Prestige 5", "raison : le prestige")
U.verifier(Deblocages.raison("accessoires", "dentelle_noire") == "Prestige 3" and Deblocages.raison("accessoires", "ruban_noir") == "Prestige 2", "garnitures noires : prestige 2 et 3")
U.verifier(Deblocages.raison("variantes", "col_montant") == "Amitié d'Hélène : 2", "raison : l'amitié d'Hélène (élision)")
U.verifier(Deblocages.raison("variantes", "manches_longues") == "Amitié d'Inès : 2", "raison : l'amitié d'Inès")
U.verifier(Deblocages.raison("accessoires", "dentelle_blanche") == "Amitié de Colette : 4", "raison : l'amitié de Colette")
U.verifier(Deblocages.raison("tissus", "coton_blanc") == nil, "ouvert au départ : pas de raison")
U.verifier(Deblocages.nom("variantes", "corsage_bretelles") == "Corsage à bretelles" and Deblocages.nom("variantes", "jupe_ample") == "Jupe ample froncée" and Deblocages.nom("tissus", "satin_rose") == "Satin rose", "noms affichés")

-- Le prestige ouvre les matières, dans l'ordre : laines (2), satins (3), velours (4), soies (5)
local function au(points)
	return { prestige = points, clientes = {} }
end
U.verifier(not Deblocages.ouvert(au(19), "tissus", "laine_noire") and Deblocages.ouvert(au(20), "tissus", "laine_noire"), "laines au prestige 2 (20 points)")
U.verifier(not Deblocages.ouvert(au(49), "tissus", "satin_rose") and Deblocages.ouvert(au(50), "tissus", "satin_rose"), "satins au prestige 3")
U.verifier(Deblocages.ouvert(au(100), "tissus", "velours_noir") and not Deblocages.ouvert(au(100), "tissus", "soie_rouge") and Deblocages.ouvert(au(170), "tissus", "soie_rouge"), "velours au 4, soies au 5")
U.verifier(not Deblocages.ouvert(au(259), "tissus", "crepe_noir") and Deblocages.ouvert(au(260), "tissus", "crepe_noir") and Deblocages.ouvert(au(260), "tissus", "organza_blanc"), "crêpe et organza au prestige 6")
U.verifier(not Deblocages.ouvert(au(379), "tissus", "brocart_or") and Deblocages.ouvert(au(380), "tissus", "brocart_or") and not Deblocages.ouvert(au(529), "tissus", "tulle_rose") and Deblocages.ouvert(au(530), "tissus", "tulle_rose"), "brocart au 7, tulle au 8")
-- Chaque niveau de prestige, de 2 à 8, ouvre quelque chose
local SEUILS_P = { 0, 20, 50, 100, 170, 260, 380, 530 }
for niveau = 2, 8 do
	U.verifier(#Deblocages.nouveaux(au(SEUILS_P[niveau] - 1), au(SEUILS_P[niveau])) > 0, "le prestige " .. niveau .. " ouvre quelque chose")
end
-- Deux décorations par niveau, du 5 au 8
for niveau, paire in pairs({ [5] = { "noeud_dore", "perle_noire" }, [6] = { "papillon_soie", "galon_argent" }, [7] = { "broche_etoile", "ruban_velours" }, [8] = { "couronne_fleurs", "dentelle_doree" } }) do
	for _, id in ipairs(paire) do
		U.verifier(Catalogue.accessoire(id) ~= nil and not Deblocages.ouvert(au(SEUILS_P[niveau] - 1), "accessoires", id) and Deblocages.ouvert(au(SEUILS_P[niveau]), "accessoires", id), id .. " : ouvert au prestige " .. niveau)
	end
end

-- L'amitié ouvre les variantes et accessoires de la cliente
local amie = { prestige = 0, clientes = { colette = { amitie = 7 } } }
U.verifier(Deblocages.ouvert(amie, "variantes", "jupe_ample") and not Deblocages.ouvert(amie, "accessoires", "dentelle_blanche"), "amitié de Colette au niveau 2 : la jupe ample, pas encore la dentelle")
amie.clientes.colette.amitie = 18
U.verifier(Deblocages.ouvert(amie, "accessoires", "dentelle_blanche"), "niveau 4 : la dentelle blanche")
U.verifier(not Deblocages.ouvert({ prestige = 0, clientes = { margot = { amitie = 25 } } }, "variantes", "jupe_ample"), "l'amitié d'une autre cliente n'ouvre pas celle de Colette")

-- Ce qui vient de s'ouvrir
local nouveaux = Deblocages.nouveaux(au(49), au(50))
local noms = {}
for _, n in ipairs(nouveaux) do
	table.insert(noms, n.nom)
end
U.verifier(#nouveaux == 5 and nouveaux[1].genre == "tissus" and nouveaux[5].id == "dentelle_noire", "prestige 3 : quatre satins et la dentelle noire (" .. table.concat(noms, ", ") .. ")")
U.verifier(#Deblocages.nouveaux(au(50), au(99)) == 0, "rien de neuf sans changer de niveau")
U.verifier(Deblocages.resume(nouveaux) == "les satins (4), Dentelle noire", "en une ligne : les satins ensemble (" .. Deblocages.resume(nouveaux) .. ")")
-- Chaque matière ouverte par le prestige a son nom au pluriel dans l'annonce (« les crêpes (4) », pas « crepe (4) »)
local resume6 = Deblocages.resume(Deblocages.nouveaux(au(SEUILS_P[6] - 1), au(SEUILS_P[6])))
U.verifier(resume6 == "Manches courtes, les crêpes (4), les organzas (4), Papillon de soie, Galon argenté", "prestige 6 en une ligne : les manches courtes, les crêpes et les organzas ensemble (" .. resume6 .. ")")
for matiere in pairs(Deblocages.PRESTIGE_MATIERES) do
	local tissus = {}
	for _, t in ipairs(Catalogue.Tissus) do
		if t.matiere == matiere then
			table.insert(tissus, { genre = "tissus", id = t.id, nom = t.nom })
		end
	end
	U.verifier(string.sub(Deblocages.resume(tissus), 1, 4) == "les ", matiere .. " : son nom au pluriel dans l'annonce (" .. Deblocages.resume(tissus) .. ")")
end
U.verifier(Deblocages.message("tissus", "soie_rouge") == "Pas encore ouvert : Soie rouge (Prestige 5).", "le refus dit ce qu'il faut pour ouvrir")
local prochain = Deblocages.prochainDeCliente("colette", 0)
U.verifier(prochain ~= nil and prochain.niveau == 2 and prochain.nom == "Jupe ample froncée", "carnet d'adresses : l'amitié de Colette ouvrira ensuite la jupe ample (niveau 2)")
prochain = Deblocages.prochainDeCliente("colette", 7)
U.verifier(prochain ~= nil and prochain.niveau == 4 and prochain.nom == "Dentelle blanche", "… puis la dentelle blanche (niveau 4)")
U.verifier(Deblocages.prochainDeCliente("colette", 18) == nil, "au niveau 4, tout ce qu'elle ouvre est ouvert")
local avantAmitie = { prestige = 0, clientes = { colette = { amitie = 6 } } }
local apresAmitie = { prestige = 0, clientes = { colette = { amitie = 7 } } }
local n = Deblocages.nouveaux(avantAmitie, apresAmitie)
U.verifier(#n == 1 and n[1].id == "jupe_ample" and n[1].nom == "Jupe ample froncée", "amitié de Colette au niveau 2 : la jupe ample froncée")

-- Tout ouvert : prestige 5 et amitié 4 avec les six clientes
local tout = { prestige = 530, clientes = {} }
for _, c in ipairs(Clientes.LISTE) do
	tout.clientes[c.id] = { amitie = 18 }
end
U.verifier(Deblocages.toutOuvert(tout), "prestige 8 et six amitiés au niveau 4 : tout est ouvert")
tout.clientes.victoire.amitie = 17
U.verifier(not Deblocages.toutOuvert(tout), "une amitié en retard : pas tout")
U.verifier(not Deblocages.toutOuvert(depart), "au départ : pas tout")
-- Sous-projet 4 : les manches courtes au prestige 6, la jupe crayon au 7 ; les quatre variantes des nouvelles
-- clientes attendent le prestige 8 (le plan 8c les donnera à leur amitié)
for id, niveau in pairs({ manches_courtes = 6, jupe_crayon = 7, corsage_cache_coeur = 8, corsage_bustier = 8, manches_trois_quarts = 8, col_marin = 8 }) do
	U.verifier(Catalogue.variante(id) ~= nil and not Deblocages.ouvert(au(SEUILS_P[niveau] - 1), "variantes", id) and Deblocages.ouvert(au(SEUILS_P[niveau]), "variantes", id), id .. " : ouverte au prestige " .. niveau)
end
