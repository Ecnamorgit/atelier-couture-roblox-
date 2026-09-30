-- Histoire (sous-projet 3) : les huit événements du quartier, l'un après l'autre. Chacun demande quelques robes à
-- des clientes connues (tenue imposée, répliques qui racontent leur histoire) ; toutes livrées, l'événement a
-- lieu : un épilogue, un souvenir (une décoration nouvelle), du prestige. Contenu original.
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

Histoire.EVENEMENTS = {
	{
		id = "lanternes",
		nom = "Le bal des lanternes",
		prestige = 1,
		souvenir = "lanterne_papier",
		epilogue = "Sous les lanternes de papier, Colette et Margot ont dansé jusqu'à minuit. Tout le quartier parle de ton atelier.",
		commandes = {
			commande("lanternes_colette", "colette", { min("mignon", 30), teinte("rose") },
				"Il y a un bal samedi, sous les lanternes du square. J'y vais… et je crois que quelqu'un m'y attend.",
				"Quelque chose de rose et de tendre, qui tourne quand on danse.",
				"Il m'a invitée à danser trois fois ! Je n'oublierai jamais cette robe."),
			commande("lanternes_margot", "margot", { min("mignon", 30), avec("fleur_rose") },
				"Je tiens le stand de limonade au bal des lanternes. Il me faut une tenue qui fasse sourire !",
				"Toute mignonne, avec une fleur rose. Une vraie, en tissu !",
				"Tout le monde voulait savoir d'où venait ma robe. J'ai donné ton adresse à tout le monde !"),
		},
	},
	{
		id = "kermesse",
		nom = "La kermesse du square",
		prestige = 2,
		souvenir = "cocarde",
		epilogue = "La kermesse a battu tous les records : chamboule-tout, tombola et la plus belle limonade du quartier. Margot rayonnait.",
		commandes = {
			commande("kermesse_margot", "margot", { min("mignon", 30), teinte("jaune") },
				"C'est moi qui organise la kermesse, cette année ! Je vais courir partout du matin au soir.",
				"Du jaune, tout mignon, qu'on me repère de loin dans la foule.",
				"Pas une tache, pas un accroc, et on me trouvait tout de suite. Merci, merci !"),
			commande("kermesse_salome", "salome", { min("decontracte", 30), teinte("vert") },
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
			commande("vernissage_helene", "helene", { min("chic", 30), avec("perle") },
				"La galerie m'a invitée au vernissage. Je ne sors plus beaucoup, depuis que j'ai quitté la scène.",
				"Une ligne pure, une perle. Rien qui crie.",
				"Quelqu'un m'a reconnue, ce soir-là. On m'a demandé si je dansais encore…"),
			commande("vernissage_salome", "salome", { min("chic", 30), max("decontracte", 30) },
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
		epilogue = "Le bateau de Colette a fini deuxième, sous les applaudissements ; sur la rive, Hélène tenait le chronomètre comme une reine.",
		commandes = {
			commande("regates_colette", "colette", { min("mignon", 20), teinte("bleu") },
				"Il m'emmène aux régates, sur son bateau ! Je n'ai jamais mis les pieds sur un bateau…",
				"Du bleu, pour aller avec le lac. Et rien qui s'envole au vent.",
				"J'ai même tenu la barre. Il dit que je porte chance. Je crois qu'il a raison."),
			commande("regates_helene", "helene", { min("chic", 30), teinte("bleu") },
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
			commande("veillee_ines", "ines", { min("gothique", 30), teinte("noir") },
				"… On m'a demandé de raconter des histoires à la veillée. Des histoires qui font peur.",
				"Noir. Que je me fonde dans l'ombre, et qu'on ne voie que mon visage.",
				"Les enfants ont crié. Les parents aussi. C'était parfait."),
			commande("veillee_helene", "helene", { min("elegant", 40), max("mignon", 20) },
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
			commande("mariage_colette", "colette", { min("romantique", 30), teinte("rose") },
				"Je suis la témoin de Margot ! Il me faut une robe qui ne vole pas la vedette… mais presque.",
				"Rose, romantique. Assortie aux fleurs de la cérémonie.",
				"J'ai attrapé le bouquet ! Vous savez ce que ça veut dire…"),
			commande("mariage_victoire", "victoire", { min("elegant", 40) },
				"Margot m'a demandé de faire le discours. Je la connais depuis qu'elle est haute comme trois pommes.",
				"Élégante, sobre. C'est son jour, pas le mien.",
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
			commande("kiosque_salome", "salome", { min("chic", 40) },
				"Je joue du violon au concert du kiosque. Devant tout le quartier. Je vais m'évanouir.",
				"Très chic, que j'aie l'air sûre de moi, même si je tremble.",
				"Je n'ai pas raté une note. Enfin, presque pas."),
			commande("kiosque_ines", "ines", { min("gothique", 40) },
				"… Je chante au concert. Une vieille complainte. Il me faut une robe qui en soit digne.",
				"Gothique, dramatique. Que la dernière rangée frissonne.",
				"On m'a demandé un rappel. Deux rappels. Je n'ai jamais été aussi heureuse."),
			commande("kiosque_victoire", "victoire", { min("chic", 30), teinte("bleu") },
				"C'est moi qui présente le concert du kiosque. Il faut que j'annonce tout le monde avec panache.",
				"Chic, en bleu nuit, comme le ciel d'été.",
				"Quelle soirée ! J'ai décidé : cet hiver, le quartier aura son grand bal."),
		},
	},
	{
		id = "bal_hiver",
		nom = "Le grand bal d'hiver",
		prestige = 6,
		souvenir = "flocon_argent",
		epilogue = "Sous les flocons, tout le quartier a dansé dans la grande salle. Victoire a levé son verre : « À notre couturière. » Ton atelier est devenu le cœur du quartier.",
		commandes = {
			commande("bal_colette", "colette", { min("romantique", 45) },
				"Le grand bal d'hiver ! Il va me demander quelque chose ce soir-là, je le sens.",
				"La robe la plus romantique que vous ayez jamais faite.",
				"Il m'a demandée en mariage sous le lustre. J'ai dit oui ! Vous ferez ma robe, n'est-ce pas ?"),
			commande("bal_helene", "helene", { min("elegant", 45) },
				"J'ouvre le bal avec un solo. Mon retour sur scène, le vrai.",
				"Élégante, légère. Une robe de danseuse.",
				"Ils se sont levés pour m'applaudir. Je suis revenue à ma place."),
			commande("bal_ines", "ines", { min("gothique", 40) },
				"… Victoire veut que je raconte le conte de l'hiver à minuit. Au bal. Devant tout le monde.",
				"Noire comme la nuit d'hiver, avec de l'éclat.",
				"Pour une fois, personne n'a eu peur. Ils ont souri. C'est encore mieux."),
			commande("bal_victoire", "victoire", { min("elegant", 45), teinte("blanc") },
				"J'organise le grand bal d'hiver. Je voudrais être à la hauteur du quartier que vous avez habillé.",
				"Blanche, élégante, digne d'une première neige.",
				"C'était le plus beau bal que le quartier ait connu. Et c'est grâce à vous."),
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
