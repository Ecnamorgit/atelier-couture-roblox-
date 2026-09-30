-- Histoire (sous-projets 3 et 4) : les douze événements du quartier, l'un après l'autre. Chacun demande quelques robes à
-- des clientes connues (tenue imposée, répliques qui racontent leur histoire) ; toutes livrées, l'événement a
-- lieu : un épilogue, un souvenir (une décoration nouvelle), du prestige. Contenu original. Sous-projet 7 : à partir
-- de la kermesse, chaque robe (qui n'a pas déjà trois exigences) demande l'occasion de son événement.
local dossier = script.Parent
local Progression = require(dossier:WaitForChild("Progression"))

local Histoire = {}
Histoire.LIVRAISONS_DEPART = 3 -- le premier événement s'annonce après trois commandes livrées
Histoire.PRESTIGE_EVENEMENT = 15 -- prestige gagné quand un événement a lieu

local function commande(id, cliente, exigences, demande, detail, merci)
	return { id = id, cliente = cliente, exigences = exigences, repliques = { demande = demande, detail = detail, merci = merci } }
end
local function min(style, valeur)
	return { type = "min", style = style, valeur = valeur }
end
local function max(style, valeur)
	return { type = "max", style = style, valeur = valeur }
end
local function teinte(t)
	return { type = "teinte", teinte = t }
end
local function avec(id)
	return { type = "accessoire", id = id }
end
local function occasion(o, valeur)
	return { type = "occasion", occasion = o, valeur = valeur }
end

Histoire.EVENEMENTS = {
	{
		id = "lanternes",
		nom = "Le bal des lanternes",
		prestige = 1,
		souvenir = "lanterne_papier",
		epilogue = "Sous les lanternes de papier, Colette a dansé jusqu'à minuit, et Margot a vendu toute sa limonade. Tout le quartier parle de ton atelier.",
		commandes = {
			commande("lanternes_colette", "colette", { min("mignon", 30), teinte("rose") },
				"Il y a un bal samedi, sous les lanternes du square. J'y vais… et je crois que quelqu'un m'y attend.",
				"Quelque chose de rose et de tendre, qui tourne quand on danse.",
				"Il m'a invitée à danser trois fois ! Je n'oublierai jamais cette robe."),
			commande("lanternes_margot", "margot", { min("mignon", 30), avec("fleur_rose") },
				"Je tiens le stand de limonade au bal des lanternes. Il me faut une tenue qui fasse sourire !",
				"Toute mignonne, avec une fleur rose. Une vraie, en tissu !",
				"Tout le monde voulait savoir d'où venait ma robe. J'ai donné ton adresse à la moitié du quartier !"),
		},
	},
	{
		id = "kermesse",
		nom = "La kermesse du square",
		prestige = 2,
		souvenir = "cocarde",
		epilogue = "La kermesse a battu tous les records : chamboule-tout, tombola et la plus belle limonade du quartier. Margot rayonnait.",
		commandes = {
			commande("kermesse_margot", "margot", { min("mignon", 30), teinte("jaune"), occasion("journee", 30) },
				"C'est moi qui organise la kermesse, cette année ! Je vais courir partout du matin au soir.",
				"Du jaune, tout mignon, qu'on me repère de loin dans la foule.",
				"Pas une tache, pas un accroc, et on me trouvait tout de suite. Merci, merci !"),
			commande("kermesse_salome", "salome", { min("decontracte", 30), teinte("vert"), occasion("journee", 30) },
				"Je tiens le stand des plantes à la kermesse. Les gens m'écoutent mieux quand je suis bien habillée.",
				"Vert, comme mes boutures. Et qui ne craint pas la terre.",
				"J'ai tout vendu, même les cactus. Ta robe y est pour quelque chose."),
		},
	},
	{
		id = "vernissage",
		nom = "Le vernissage de la galerie",
		prestige = 2,
		souvenir = "broche_palette",
		epilogue = "À la galerie, les herbiers de Salomé ont fait sensation, et l'on a surpris Hélène à parler de danse pour la première fois depuis des années.",
		commandes = {
			commande("vernissage_helene", "helene", { min("chic", 30), avec("perle"), occasion("journee", 20) },
				"La galerie m'a invitée au vernissage. Je ne sors plus beaucoup, depuis que j'ai quitté la scène.",
				"Une ligne pure, une perle. Rien qui crie.",
				"Quelqu'un m'a reconnue, cet après-midi-là. On m'a demandé si je dansais encore…"),
			commande("vernissage_salome", "salome", { min("chic", 30), max("decontracte", 30), occasion("journee", 20) },
				"Tu ne devineras jamais : la galerie expose mes herbiers ! Il faut que j'aie l'air d'une artiste.",
				"Chic, pour une fois. Pas mes habits de jardin.",
				"On m'a acheté trois planches ! J'ai presque oublié que j'avais peur."),
		},
	},
	{
		id = "regates",
		nom = "Les régates du lac",
		pluriel = true, -- « ont eu lieu »
		prestige = 3,
		souvenir = "ancre_doree",
		epilogue = "Le bateau qui emmenait Colette a fini deuxième, sous les applaudissements ; sur la rive, Hélène tenait le chronomètre comme une reine.",
		commandes = {
			commande("regates_colette", "colette", { min("mignon", 20), teinte("bleu"), occasion("journee", 30) },
				"Il m'emmène aux régates, sur son bateau ! Je n'ai jamais mis les pieds sur un bateau…",
				"Du bleu, pour aller avec le lac. Et rien qui s'envole au vent.",
				"J'ai même tenu la barre. Il dit que je porte chance. Je crois qu'il a raison."),
			commande("regates_helene", "helene", { min("chic", 30), teinte("bleu"), occasion("journee", 30) },
				"Le club nautique m'a demandé de donner le départ des régates. Il paraît que j'ai de l'allure.",
				"Chic, en bleu marine si possible. Je veux qu'on me voie du bout du ponton.",
				"J'ai donné le départ… et j'ai dansé au bal du soir. Je n'avais pas dansé depuis dix ans."),
		},
	},
	{
		id = "veillee",
		nom = "La veillée des contes",
		prestige = 3,
		souvenir = "plume_corbeau",
		epilogue = "À la lueur des bougies, Inès a raconté l'histoire de la couturière des ombres. Personne n'a osé rentrer seul.",
		commandes = {
			commande("veillee_ines", "ines", { min("gothique", 30), teinte("noir"), occasion("soiree", 20) },
				"… On m'a demandé de raconter des histoires à la veillée. Des histoires qui font peur.",
				"Noir. Que je me fonde dans l'ombre, et qu'on ne voie que mon visage.",
				"Les enfants ont crié. Les parents aussi. C'était parfait."),
			commande("veillee_helene", "helene", { min("elegant", 40), max("mignon", 20), occasion("soiree", 20) },
				"Inès m'a demandé de danser pendant son conte. Une danse lente, à la bougie.",
				"Élégant, sombre, rien de mignon. Il faut que la robe bouge avec moi.",
				"Les gens pleuraient à la fin. Je remonte sur scène le mois prochain."),
		},
	},
	{
		id = "mariage",
		nom = "Le mariage de Margot",
		prestige = 5,
		souvenir = "fleur_oranger",
		epilogue = "Margot a dit oui sous une pluie de pétales. Colette a attrapé le bouquet, et Victoire a porté un toast à « l'atelier qui habille tout le quartier ».",
		commandes = {
			commande("mariage_margot", "margot", { min("elegant", 30), teinte("blanc"), avec("perle") },
				"Je me marie ! Au printemps ! Et c'est toi qui fais ma robe, c'est décidé depuis la kermesse.",
				"Blanche, élégante, avec des perles. Je veux pleurer en me voyant.",
				"J'ai pleuré. Tout le monde a pleuré. C'était la plus belle journée de ma vie."),
			commande("mariage_colette", "colette", { min("romantique", 30), teinte("rose"), occasion("journee", 30) },
				"Je suis la témoin de Margot ! Il me faut une robe qui ne vole pas la vedette… mais presque.",
				"Rose, romantique. Assortie aux fleurs de la cérémonie.",
				"J'ai attrapé le bouquet ! Vous savez ce que ça veut dire…"),
			commande("mariage_victoire", "victoire", { min("elegant", 40), occasion("journee", 30) },
				"Margot m'a demandé de faire le discours. Je la connais depuis qu'elle est haute comme trois pommes.",
				"Élégante, discrète. C'est son jour, pas le mien.",
				"Mon discours a fait rire et pleurer. Et l'on m'a demandé qui était ma couturière."),
		},
	},
	{
		id = "kiosque",
		nom = "Le concert du kiosque",
		prestige = 5,
		souvenir = "cle_de_sol",
		epilogue = "Salomé au violon, Inès au chant : le kiosque n'avait jamais été aussi plein. Victoire a promis d'organiser le grand bal d'hiver.",
		commandes = {
			commande("kiosque_salome", "salome", { min("chic", 40), occasion("journee", 20) },
				"Je joue du violon au concert du kiosque. Devant tout le quartier. Je vais m'évanouir.",
				"Très chic, que j'aie l'air sûre de moi, même si je tremble.",
				"Je n'ai pas raté une note. Enfin, presque pas."),
			commande("kiosque_ines", "ines", { min("gothique", 40), occasion("journee", 20) },
				"… Je chante au concert. Une vieille complainte. Il me faut une robe qui en soit digne.",
				"Gothique, dramatique. Que la dernière rangée frissonne.",
				"On m'a demandé un rappel. Deux rappels. Je n'ai jamais été aussi heureuse."),
			commande("kiosque_victoire", "victoire", { min("chic", 30), teinte("bleu"), occasion("journee", 20) },
				"C'est moi qui présente le concert du kiosque. Il faut que j'annonce tout le monde avec panache.",
				"Chic, en bleu, comme le ciel d'été.",
				"Quel concert ! J'ai décidé : cet hiver, le quartier aura son grand bal."),
		},
	},
	{
		id = "bal_hiver",
		nom = "Le grand bal d'hiver",
		prestige = 6,
		souvenir = "flocon_argent",
		epilogue = "Dehors, la neige tombait ; dans la grande salle, tout le quartier a dansé. Victoire a levé son verre : « À notre couturière. » Ton atelier est devenu le cœur du quartier.",
		commandes = {
			commande("bal_colette", "colette", { min("romantique", 45), occasion("soiree", 40) },
				"Le grand bal d'hiver ! Il va me demander quelque chose ce soir-là, je le sens.",
				"La robe la plus romantique que vous ayez jamais faite.",
				"Il m'a demandée en mariage sous le lustre. J'ai dit oui ! Vous ferez ma robe, n'est-ce pas ?"),
			commande("bal_helene", "helene", { min("elegant", 45), occasion("soiree", 40) },
				"J'ouvre le bal avec un solo. Mon retour sur scène, le vrai.",
				"Élégante, fluide. Une robe de danseuse.",
				"Ils se sont levés pour m'applaudir. Je suis revenue à ma place."),
			commande("bal_ines", "ines", { min("gothique", 40), occasion("soiree", 40) },
				"… Victoire veut que je raconte le conte de l'hiver à minuit. Au bal. Devant tout le monde.",
				"Noire comme la nuit d'hiver, avec de l'éclat.",
				"Pour une fois, personne n'a eu peur. Ils ont souri. C'est encore mieux."),
			commande("bal_victoire", "victoire", { min("elegant", 45), teinte("blanc"), occasion("soiree", 40) },
				"J'organise le grand bal d'hiver. Je voudrais être à la hauteur du quartier que vous avez habillé.",
				"Blanche, élégante, digne d'une première neige.",
				"C'était le plus beau bal que le quartier ait connu. Et c'est grâce à vous."),
		},
	},
	-- Sous-projet 4 : quatre événements de fin de partie, avec les quatre dernières clientes
	{
		id = "salon_livre",
		nom = "Le salon du livre",
		prestige = 6,
		souvenir = "marque_page",
		epilogue = "Au salon du livre, Joséphine a vendu tous ses exemplaires, Apolline a lu ses poèmes devant une salle comble, et l'herbier de Salomé est déjà épuisé.",
		commandes = {
			commande("salon_josephine", "josephine", { min("chic", 30), teinte("brun"), occasion("journee", 20) },
				"J'organise le salon du livre sur la place ! Des auteurs, des lecteurs, et moi au milieu de tout ça.",
				"Chic mais pratique, couleur de vieux cuir.",
				"On m'a prise pour une romancière. J'ai signé trois autographes, par erreur !"),
			commande("salon_apolline", "apolline", { min("romantique", 35), teinte("violet"), occasion("journee", 20) },
				"Joséphine veut que je lise mes poèmes au salon. À voix haute. Devant des gens.",
				"Romantique, violette comme l'encre de mon stylo.",
				"Ma voix n'a pas tremblé. Enfin, un peu, au début."),
			commande("salon_salome", "salome", { min("chic", 30), teinte("vert"), occasion("journee", 20) },
				"Je présente mon herbier au salon du livre. Oui, j'en ai fait un livre !",
				"Vert et chic, comme une belle reliure.",
				"Il est déjà épuisé. On me demande une suite !"),
		},
	},
	{
		id = "premiere",
		nom = "La première du théâtre",
		prestige = 7,
		souvenir = "masque_theatre",
		epilogue = "Rideau ! Capucine a salué sous une pluie de roses, Inès a joué la musique de scène, et Victoire jure qu'elle n'a jamais autant applaudi.",
		commandes = {
			commande("premiere_capucine", "capucine", { min("romantique", 35), teinte("rouge"), occasion("soiree", 40) },
				"La première de ma pièce, c'est dans quinze jours. Je joue une reine déchue. Il me faut son costume.",
				"Romantique et tragique, rouge sang, qu'on la voie du dernier rang.",
				"Onze rappels ! La reine déchue a conquis le quartier."),
			commande("premiere_ines", "ines", { min("gothique", 40), max("mignon", 20), occasion("soiree", 40) },
				"… Capucine m'a demandé la musique de sa pièce. Je jouerai de l'orgue, dans la fosse.",
				"Sombre. Rien de mignon. Personne ne doit me remarquer… sauf à la fin.",
				"À la fin, on m'a fait monter sur scène. Je n'ai pas su quoi faire de mes mains."),
			commande("premiere_victoire", "victoire", { min("elegant", 45), occasion("soiree", 40) },
				"Je suis la marraine de la première. Il faut que je sois à la hauteur de la loge d'honneur.",
				"Élégante, digne d'un soir de première.",
				"Toute la salle se retournait vers ma loge. Merveilleux."),
		},
	},
	{
		id = "noces_colette",
		nom = "Le mariage de Colette",
		prestige = 7,
		souvenir = "alliance_or",
		epilogue = "Colette a dit oui sous les lanternes du square, là où tout avait commencé. Margot a pleuré plus fort que tout le monde, et Apolline a lu le poème qu'elle leur avait écrit.",
		commandes = {
			commande("noces_colette", "colette", { min("romantique", 40), teinte("blanc"), occasion("journee", 20) },
				"Ça y est, c'est bientôt le grand jour ! Vous vous souvenez ? Au bal d'hiver, je vous ai demandé ma robe.",
				"Blanche, la plus romantique du monde. Comme au bal d'hiver, en mieux.",
				"Il a pleuré en me voyant arriver. Moi aussi. Merci pour tout, depuis le début."),
			commande("noces_margot", "margot", { min("mignon", 35), teinte("rose"), occasion("journee", 20) },
				"À mon tour d'être la témoin ! Colette l'a été pour moi, je lui dois bien ça.",
				"Rose, toute mignonne, assortie aux fleurs de la mariée.",
				"J'ai attrapé le bouquet… et je l'ai lancé à Apolline. Elle était toute rouge !"),
			commande("noces_apolline", "apolline", { min("romantique", 35), teinte("violet"), occasion("journee", 20) },
				"Colette m'a demandé un poème pour son mariage. Et une robe pour le lire, évidemment.",
				"Romantique, en violet, pour aller avec les mots.",
				"Tout le monde a pleuré au dernier vers. C'était le but."),
		},
	},
	{
		id = "defile",
		nom = "Le grand défilé du quartier",
		prestige = 8,
		souvenir = "rosette_honneur",
		epilogue = "Sur la place, toutes les robes de l'atelier ont défilé, de la première à la dernière. Maëlle a ouvert le défilé, Victoire a remis la rosette : ton atelier est la fierté du quartier.",
		commandes = {
			commande("defile_maelle", "maelle", { min("decontracte", 40), teinte("bleu"), occasion("journee", 20) },
				"Victoire organise un défilé sur la place, et elle veut que je l'ouvre ! Moi, qui vis en ciré jaune…",
				"Décontractée, bleu océan. Je dois pouvoir marcher sans tomber.",
				"J'ai ouvert le défilé sans tomber une seule fois. Une vraie traversée !"),
			commande("defile_capucine", "capucine", { min("gothique", 40), occasion("journee", 20) },
				"Un défilé, c'est un théâtre sans texte. J'en suis, bien sûr.",
				"La plus gothique de vos créations. Qu'on retienne son souffle.",
				"Le silence, puis les applaudissements. Exactement comme je les aime."),
			commande("defile_josephine", "josephine", { min("chic", 40), occasion("journee", 20) },
				"Victoire dit que les libraires ont du style, alors je défile aussi. Elle a raison, non ?",
				"Chic, très chic. Pour faire honneur à tous les livres.",
				"On m'a photographiée pour le journal du quartier. En première page !"),
			commande("defile_victoire", "victoire", { min("elegant", 40), teinte("bleu"), occasion("journee", 20) },
				"Le grand défilé est mon idée. Toutes vos robes, sur la place, devant tout le quartier.",
				"Élégante, en bleu, pour clore le défilé. La dernière robe doit être la plus belle.",
				"Quel triomphe. Tout le quartier connaît votre nom, désormais."),
		},
	},
}

local parId, commandes = {}, {}
for rang, ev in ipairs(Histoire.EVENEMENTS) do
	ev.rang = rang
	parId[ev.id] = ev
	for _, c in ipairs(ev.commandes) do
		commandes[c.id] = { commande = c, evenement = ev }
	end
end

-- L'événement d'identifiant donné, ou nil
function Histoire.get(id)
	return parId[id]
end

-- La commande d'histoire d'identifiant donné, et son événement ; nil si inconnue
function Histoire.commande(id)
	local c = commandes[id]
	if not c then
		return nil
	end
	return c.commande, c.evenement
end

-- progres : { histoire = { faites = { [idCommande] = true } } } (l'état de l'atelier convient)
local function faites(progres)
	return progres.histoire and progres.histoire.faites or {}
end

-- Robes faites et robes demandées pour un événement
function Histoire.avancee(progres, idEvenement)
	local ev, f, n = parId[idEvenement], faites(progres), 0
	for _, c in ipairs(ev.commandes) do
		if f[c.id] then
			n += 1
		end
	end
	return n, #ev.commandes
end

-- Un événement a eu lieu quand toutes ses robes sont faites
function Histoire.aEuLieu(progres, idEvenement)
	local n, total = Histoire.avancee(progres, idEvenement)
	return n == total
end

-- L'événement en cours (le premier qui n'a pas eu lieu), et s'il est ouvert : son prestige atteint (et, pour le
-- premier, trois commandes livrées) ; nil si tous ont eu lieu. etat : prestige, livraisons, histoire
function Histoire.enCours(etat)
	for _, ev in ipairs(Histoire.EVENEMENTS) do
		if not Histoire.aEuLieu(etat, ev.id) then
			local ouvert = Progression.niveauPrestige(etat.prestige or 0) >= ev.prestige and (etat.livraisons or 0) >= Histoire.LIVRAISONS_DEPART
			return ev, ouvert
		end
	end
	return nil, false
end

-- La prochaine commande de l'événement en cours (la première pas encore faite), ou nil s'il n'est pas ouvert
function Histoire.prochaine(etat)
	local ev, ouvert = Histoire.enCours(etat)
	if not ouvert then
		return nil
	end
	local f = faites(etat)
	for _, c in ipairs(ev.commandes) do
		if not f[c.id] then
			return c, ev
		end
	end
	return nil
end

-- « Le bal des lanternes a eu lieu ! », « Les régates du lac ont eu lieu ! »
function Histoire.titreEpilogue(ev)
	return ("%s %s eu lieu !"):format(ev.nom, if ev.pluriel then "ont" else "a")
end

-- Sous-projet 5 : quand un événement a lieu, son épilogue fait la une du journal du quartier, en deux colonnes
Histoire.GAZETTE = "La Gazette du Dé"

-- Le texte en deux colonnes : coupé à la fin de la phrase la plus proche du milieu, si elle n'en est pas à plus
-- d'un cinquième du texte (sinon, à l'espace le plus proche du milieu) ; jamais devant « ; : ! ? » » ni après
-- « « » (la typographie française les sépare d'une espace) ; renvoie les deux morceaux (le second est vide pour
-- un seul mot)
function Histoire.enColonnes(texte)
	local milieu = #texte / 2
	-- p : la position d'un espace
	local function coupable(p)
		return not (texte:sub(p + 1, p + 1):match("[;:!?]") or texte:sub(p + 1, p + 2) == "»" or texte:sub(p - 2, p - 1) == "«")
	end
	local function finDePhrase(p)
		return texte:sub(p - 1, p - 1):match("[%.!?]") ~= nil or (texte:sub(p - 2, p - 1) == "»" and texte:sub(p - 4, p - 4):match("[%.!?]") ~= nil)
	end
	local phrase, espace
	local function plusPres(p, q)
		return not q or math.abs(p - milieu) < math.abs(q - milieu)
	end
	for p in texte:gmatch("() ") do
		if coupable(p) then
			if finDePhrase(p) and math.abs(p - milieu) <= #texte / 5 and plusPres(p, phrase) then
				phrase = p
			end
			if plusPres(p, espace) then
				espace = p
			end
		end
	end
	local coupe = phrase or espace
	if not coupe then
		return texte, ""
	end
	return texte:sub(1, coupe - 1), texte:sub(coupe + 1)
end

-- Nombre d'événements qui ont eu lieu
function Histoire.eus(progres)
	local n = 0
	for _, ev in ipairs(Histoire.EVENEMENTS) do
		if Histoire.aEuLieu(progres, ev.id) then
			n += 1
		end
	end
	return n
end

return Histoire
