local Histoire = U.module("Histoire")
local Clientes = U.module("Clientes")
local Catalogue = U.module("Catalogue")
local Commandes = U.module("Commandes")
local Deblocages = U.module("Deblocages")
local Progression = U.module("Progression")

-- Le tableau : douze événements, deux à quatre robes chacun, des clientes connues, des répliques, un souvenir
U.verifier(#Histoire.EVENEMENTS == 12, "douze événements")
-- Sous-projet 4 : quatre événements de plus, aux prestiges 6 à 8, où jouent les quatre nouvelles clientes
local joueuses = {}
for rang = 9, #Histoire.EVENEMENTS do
	local ev = Histoire.EVENEMENTS[rang]
	U.verifier(ev.prestige >= 6, ev.id .. " : un événement de fin de partie (prestige 6 à 8)")
	for _, c in ipairs(ev.commandes) do
		joueuses[c.cliente] = true
	end
end
U.verifier(joueuses.apolline and joueuses.josephine and joueuses.capucine and joueuses.maelle, "les quatre nouvelles clientes jouent dans les événements 9 à 12")
-- Le mariage de Colette répond à son histoire : tout a commencé au bal des lanternes, sur le square ; au bal
-- d'hiver, elle avait demandé sa robe (on ne la lui avait pas promise)
local noces = Histoire.get("noces_colette")
local demandeNoces = Histoire.commande("noces_colette").repliques.demande
U.verifier(string.find(noces.epilogue, "lanternes", 1, true) ~= nil and string.find(noces.epilogue, "bord du lac", 1, true) == nil and string.find(demandeNoces, "promis", 1, true) == nil and string.find(demandeNoces, "bal d'hiver", 1, true) ~= nil, "le mariage de Colette répond à son histoire (les lanternes du square, la robe demandée au bal d'hiver)")
local ids, faites = {}, {}
local precedent = 0
for rang, ev in ipairs(Histoire.EVENEMENTS) do
	U.verifier(Histoire.get(ev.id) == ev and ev.rang == rang and ev.nom ~= "" and ev.epilogue ~= "", ev.id .. " : nom et épilogue")
	U.verifier(ev.prestige >= precedent and ev.prestige <= 8, ev.id .. " : prestige croissant")
	precedent = ev.prestige
	U.verifier(#ev.commandes >= 2 and #ev.commandes <= 4, ev.id .. " : deux à quatre robes")
	local souvenir = Catalogue.accessoire(ev.souvenir)
	U.verifier(souvenir ~= nil and souvenir.genre == "objet" and Deblocages.CONDITIONS.accessoires[ev.souvenir].evenement == ev.id, ev.id .. " : son souvenir, ouvert par lui")
	-- Chaque robe est réalisable avec ce qui est ouvert au prestige de l'événement, amitiés à zéro, les
	-- événements d'avant ayant eu lieu (leurs souvenirs ouverts)
	local progres = { prestige = Progression.SEUILS_PRESTIGE[ev.prestige], clientes = {}, histoire = { faites = table.clone(faites) } }
	local ouverts = Deblocages.ouverts(progres)
	for _, c in ipairs(ev.commandes) do
		U.verifier(not ids[c.id], c.id .. " : identifiant unique")
		ids[c.id] = true
		local cliente = Clientes.get(c.cliente)
		U.verifier(cliente ~= nil and cliente.prestige <= ev.prestige, c.id .. " : une cliente arrivée à ce prestige")
		U.verifier(#c.exigences >= 1 and #c.exigences <= 3 and Commandes.realisable(c.exigences, ouverts), c.id .. " : tenue réalisable avec ce qui est ouvert")
		U.verifier(c.repliques.demande ~= "" and c.repliques.detail ~= "" and c.repliques.merci ~= "", c.id .. " : ses répliques")
		local commande, evenement = Histoire.commande(c.id)
		U.verifier(commande == c and evenement == ev, c.id .. " : retrouvée par son identifiant")
	end
	for _, c in ipairs(ev.commandes) do
		faites[c.id] = true
	end
end
U.verifier(Histoire.commande("inconnue") == nil and Histoire.get("inconnu") == nil, "identifiant inconnu : rien")
-- (sous-projet 7) À partir de la kermesse, chaque robe qui n'a pas déjà trois exigences demande l'occasion de son
-- événement : la soirée au bal d'hiver et à la première, la journée à la kermesse et aux mariages
local sansOccasion, occasionsDe = {}, {}
for rang, ev in ipairs(Histoire.EVENEMENTS) do
	for _, c in ipairs(ev.commandes) do
		local o
		for _, e in ipairs(c.exigences) do
			o = o or e.occasion
		end
		occasionsDe[ev.id] = occasionsDe[ev.id] or o
		if rang >= 2 and not o and #c.exigences < 3 then
			table.insert(sansOccasion, c.id)
		end
	end
end
U.verifier(#sansOccasion == 0, "à partir de la kermesse, chaque robe demande l'occasion de son événement (sans : " .. table.concat(sansOccasion, ", ") .. ")")
U.verifier(occasionsDe.bal_hiver == "soiree" and occasionsDe.premiere == "soiree" and occasionsDe.kermesse == "journee" and occasionsDe.noces_colette == "journee" and occasionsDe.lanternes == nil, "le bal d'hiver et la première : la soirée ; la kermesse et les mariages : la journée")
-- (relecture) Les répliques ne contredisent pas la commande : une robe de journée n'est pas pour « ce soir-là » ni pour
-- une soirée ; ce qu'elle voudrait ne nomme pas un trait qu'elle ne demande pas (« légère », « sobre »…)
local contredites = {}
for _, ev in ipairs(Histoire.EVENEMENTS) do
	for _, c in ipairs(ev.commandes) do
		local demandes = {}
		for _, e in ipairs(c.exigences) do
			demandes[e.occasion or e.trait or ""] = true
		end
		local textes = string.lower(c.repliques.detail .. " " .. c.repliques.merci)
		if demandes.journee and (string.find(textes, "soirée", 1, true) or string.find(textes, "ce soir", 1, true)) then
			table.insert(contredites, c.id .. " (soir)")
		end
		for _, trait in ipairs({ "légère", "chaude", "sobre", "travaillée", "fleurie" }) do
			if string.find(string.lower(c.repliques.detail), trait, 1, true) and not demandes[Catalogue.TRAITS[table.find({ "légère", "chaude", "sobre", "travaillée", "unie", "fleurie" }, trait)]] then
				table.insert(contredites, c.id .. " (" .. trait .. ")")
			end
		end
	end
end
U.verifier(#contredites == 0, "les répliques ne contredisent pas la commande (en défaut : " .. table.concat(contredites, ", ") .. ")")
-- Le récit tient debout : au bal des lanternes, Margot tient son stand de limonade (elle ne danse pas) ; le bateau
-- des régates n'est pas celui de Colette (on l'y emmène) ; au bal d'hiver, la neige tombe dehors, pas dans la salle ;
-- Margot ne répète pas « tout le monde » dans la même phrase
local function nombre(texte, motif)
	local n, debut = 0, 1
	while true do
		local i = string.find(texte, motif, debut, true)
		if not i then
			return n
		end
		n, debut = n + 1, i + 1
	end
end
U.verifier(string.find(Histoire.get("lanternes").epilogue, "limonade", 1, true) ~= nil and string.find(Histoire.get("lanternes").epilogue, "Margot ont dansé", 1, true) == nil, "bal des lanternes : Margot tient son stand de limonade")
U.verifier(string.find(Histoire.get("regates").epilogue, "bateau de Colette", 1, true) == nil, "régates : le bateau n'est pas celui de Colette")
U.verifier(string.find(Histoire.get("bal_hiver").epilogue, "Dehors", 1, true) ~= nil, "bal d'hiver : la neige tombe dehors")

-- Sous-projet 5 : la gazette du quartier donne l'épilogue en deux colonnes, coupé à la fin de la phrase la plus
-- proche du milieu (à défaut, à l'espace le plus proche)
local a, b = Histoire.enColonnes("Un. Deux trois quatre. Cinq six. Sept huit neuf dix.")
U.verifier(a == "Un. Deux trois quatre." and b == "Cinq six. Sept huit neuf dix.", "coupé à la fin de la phrase la plus proche du milieu")
a, b = Histoire.enColonnes("Une très longue première phrase qui prend presque toute la place du texte. Fin.")
U.verifier(math.abs(#a - #b) <= 8 and a .. " " .. b == "Une très longue première phrase qui prend presque toute la place du texte. Fin.", "une fin de phrase trop loin du milieu : coupé à l'espace le plus proche")
a, b = Histoire.enColonnes("une seule phrase sans point final assez longue")
U.verifier(a .. " " .. b == "une seule phrase sans point final assez longue" and math.abs(#a - #b) <= 8, "sans phrase : coupé à l'espace le plus proche du milieu")
a, b = Histoire.enColonnes("Court")
U.verifier(a == "Court" and b == "", "un mot : une seule colonne")
-- (typographie française : une espace avant « ; : ! ? » » et après « « » ; la colonne ne commence ni ne finit mal)
local function bienCoupe(x, y)
	return not (y:sub(1, 1):match("[;:!?]") or y:sub(1, 2) == "»" or x:sub(-2) == "«")
end
for _, ev in ipairs(Histoire.EVENEMENTS) do
	a, b = Histoire.enColonnes(ev.epilogue)
	U.verifier(a ~= "" and b ~= "" and a .. " " .. b == ev.epilogue and #a <= 0.75 * #ev.epilogue and #b <= 0.75 * #ev.epilogue, ev.id .. " : l'épilogue en deux colonnes équilibrées (" .. #a .. " et " .. #b .. ")")
	U.verifier(bienCoupe(a, b), ev.id .. " : la seconde colonne ne commence pas par une ponctuation (« " .. b:sub(1, 12) .. "… »)")
end
a, b = Histoire.enColonnes("Tout le quartier était là ; la fanfare jouait sous les arbres du square.")
U.verifier(bienCoupe(a, b) and a .. " " .. b == "Tout le quartier était là ; la fanfare jouait sous les arbres du square.", "pas de coupe devant un point-virgule")
a, b = Histoire.enColonnes("Elle a dit à tout le monde « Quelle robe ! » avant de danser toute la nuit.")
U.verifier(bienCoupe(a, b), "pas de coupe devant un « ! » ni un « » », ni après un « « »")
a, b = Histoire.enColonnes("Margot riait fort. « Quelle fête pour la couturière. » Et le bal continua jusqu'à l'aube.")
U.verifier(a == "Margot riait fort. « Quelle fête pour la couturière. »" and b == "Et le bal continua jusqu'à l'aube.", "une fin de phrase entre guillemets : coupé après le « » »")
U.verifier(Histoire.GAZETTE == "La Gazette du Dé", "le journal du quartier")
U.verifier(nombre(Histoire.commande("lanternes_margot").repliques.merci:lower(), "tout le monde") <= 1, "Margot ne répète pas « tout le monde »")
U.verifier(Histoire.titreEpilogue(Histoire.get("lanternes")) == "Le bal des lanternes a eu lieu !" and Histoire.titreEpilogue(Histoire.get("regates")) == "Les régates du lac ont eu lieu !", "l'épilogue s'accorde : « a eu lieu », « ont eu lieu »")
local TUTOIEMENT = { " tu ", "Tu ", " toi", " ta ", " ton ", " tes ", " te ", " t'" }
for _, ev in ipairs(Histoire.EVENEMENTS) do
	for _, c in ipairs(ev.commandes) do
		if c.cliente == "colette" or c.cliente == "helene" or c.cliente == "victoire" or c.cliente == "apolline" or c.cliente == "josephine" or c.cliente == "capucine" or c.cliente == "maelle" then
			for cle, texte in pairs(c.repliques) do
				for _, motif in ipairs(TUTOIEMENT) do
					U.verifier(string.find(" " .. texte, motif, 1, true) == nil, c.id .. " (" .. cle .. ") : elle vouvoie, comme d'habitude (« " .. motif .. " »)")
				end
			end
		end
	end
end

-- La progression : le premier événement après trois livraisons ; dans l'ordre ; le suivant à son prestige
local etat = { prestige = 0, livraisons = 0, histoire = { faites = {} } }
local ev, ouvert = Histoire.enCours(etat)
U.verifier(ev.id == "lanternes" and not ouvert and Histoire.prochaine(etat) == nil, "au départ : le bal des lanternes, pas encore ouvert")
etat.livraisons = 3
ev, ouvert = Histoire.enCours(etat)
local suivante = Histoire.prochaine(etat)
U.verifier(ouvert and suivante.id == "lanternes_colette", "trois livraisons : il s'annonce, Colette d'abord")
etat.histoire.faites.lanternes_colette = true
U.verifier(Histoire.prochaine(etat).id == "lanternes_margot" and select(1, Histoire.avancee(etat, "lanternes")) == 1, "puis Margot ; une robe sur deux")
U.verifier(not Deblocages.ouvert(etat, "accessoires", "lanterne_papier") and Deblocages.raison("accessoires", "lanterne_papier") == "Souvenir d'un événement du quartier", "souvenir fermé tant que l'événement n'a pas eu lieu (sans dévoiler lequel)")
etat.histoire.faites.lanternes_margot = true
U.verifier(Histoire.aEuLieu(etat, "lanternes") and Histoire.eus(etat) == 1 and Deblocages.ouvert(etat, "accessoires", "lanterne_papier"), "les deux robes livrées : le bal a lieu, la lanterne s'ouvre")
ev, ouvert = Histoire.enCours(etat)
U.verifier(ev.id == "kermesse" and not ouvert, "la kermesse attend le prestige 2")
etat.prestige = 20
ev, ouvert = Histoire.enCours(etat)
U.verifier(ouvert and Histoire.prochaine(etat).id == "kermesse_margot", "prestige 2 : la kermesse s'annonce")
local tout = { prestige = 530, livraisons = 99, histoire = { faites = faites } }
U.verifier(Histoire.enCours(tout) == nil and Histoire.prochaine(tout) == nil and Histoire.eus(tout) == 12, "tout a eu lieu : plus d'événement")

-- « Tout ouvert » (équilibrage) ne compte pas les souvenirs, qui viennent de l'histoire
local progresTout = { prestige = 530, clientes = {} }
for _, c in ipairs(Clientes.LISTE) do
	progresTout.clientes[c.id] = { amitie = 25 }
end
U.verifier(Deblocages.toutOuvert(progresTout) and not Deblocages.ouvert(progresTout, "accessoires", "flocon_argent"), "tout ouvert par le prestige et l'amitié, sans les souvenirs")
