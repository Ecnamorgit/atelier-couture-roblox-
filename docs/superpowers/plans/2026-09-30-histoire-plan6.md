# Aiguille & Dentelle — Plan 6 : l'histoire et les événements du quartier

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Donner au jeu son histoire : huit événements originaux du quartier, l'un après l'autre, chacun avec deux à quatre robes d'histoire (tenue imposée, conversation avec la cliente, suite de son histoire) ; toutes livrées, l'événement a lieu (épilogue, souvenir, prestige). Le jeu prend son nom : **Aiguille & Dentelle**.

**Architecture:**
- **Données** (partagées) : `Histoire` porte les huit événements (robes, tenues, répliques, épilogues, souvenirs) et dit l'événement en cours et sa prochaine robe ; `Catalogue` gagne les huit souvenirs (des objets de décoration) ; `Deblocages` gagne une sorte de condition, `{ evenement = id }`.
- **Règles** (`EtatAtelier`, serveur) : champ `histoire = { faites }` ; `commandeHistoire()` fait venir la cliente de la prochaine robe de l'événement (même accueil que la clochette) ; livrée, la robe est faite ; la dernière de l'événement le fait avoir lieu (15 de prestige en plus, souvenir ouvert, `evenement` dans la réponse). Sauvegarde de l'histoire.
- **Interface** : à l'accueil, l'événement en cours et « Commande de l'événement », une conversation (« Suivant », « Accepter la commande »), l'épilogue quand l'événement a lieu, les souvenirs dans le carnet d'adresses ; la cliente dit sa demande et son détail dans sa bulle, puis la suite de son histoire en partant ; le titre et les enseignes portent le nom du jeu.

**Tech Stack:** Luau, Rojo 7.7.0-rc.1, simulation Luau 0.650 (`tests/lancer.sh`), Roblox Studio via le connecteur MCP Studio.

**Spec:** `docs/superpowers/specs/2026-09-30-histoire-evenements-design.md` (sous-projet 3, commitée avec ce plan). Sous-projets précédents : `…2026-09-28-atelier-coeur-design.md`, `…2026-09-29-clientes-progression-design.md`.

## Décisions de ce plan

- **Contenu original** : huit événements (le bal des lanternes, la kermesse du square, le vernissage de la galerie, les régates du lac, la veillée des contes, le mariage de Margot, le concert du kiosque, le grand bal d'hiver), vingt robes d'histoire, soixante répliques, huit épilogues et huit souvenirs, écrits pour ce jeu.
- **Tenues** : chaque robe d'histoire est réalisable avec ce qui est ouvert au prestige de son événement, amitiés à zéro, souvenirs des événements d'avant ouverts. Une sonde (le meilleur score de chaque tenue, robe d'un seul tissu) a fixé les valeurs ; le mariage attend le prestige 5, où la soie ivoire s'ouvre. Un test vérifie chaque tenue.
- **Ouverture** : l'événement en cours est le premier qui n'a pas eu lieu ; il est ouvert quand son prestige est atteint et que trois commandes ont été livrées. Les robes d'un événement se font dans l'ordre du tableau. Une robe d'histoire abandonnée reste à faire. Une robe d'histoire peut faire venir une cliente pour la première fois.
- **Récompense** : 15 de prestige quand l'événement a lieu (dans le prestige de la livraison), et son souvenir s'ouvre (une condition `{ evenement = id }` des déblocages : rien de plus à sauvegarder). « Tout ouvert » (équilibrage) ne compte pas les souvenirs, qui viennent de l'histoire.
- **Bulles** : pour une robe d'histoire, la cliente dit sa demande aux mesures (après sa présentation, la première fois), son détail au carnet, et la suite de son histoire en partant.
- **Accueil** : la ligne de l'événement sous la jauge de prestige (« Événement : Le bal des lanternes — robes livrées 1 / 2 », ou « Bientôt : … (prestige 3) », ou « (après trois commandes livrées) », ou « Tous les événements du quartier ont eu lieu. ») ; le courrier descend d'une ligne. L'épilogue s'affiche dans un panneau par-dessus l'accueil (un texte d'épilogue est trop long pour l'annonce).
- **Nom du jeu** : « Aiguille & Dentelle » (titre de l'accueil, enseigne « Aiguille & Dentelle — <joueur> », README) ; le lieu et le dépôt gardent leur nom de fichier.
- **Un seul plan** au lieu des deux prévus d'abord (6a, 6b) : les deux moitiés touchent les mêmes fichiers.
- **Vérifié pendant la préparation** : le plan a été joué entièrement sur un brouillon tiré de `main` ; huit variantes du brouillon (souvenir ouvert d'avance, ordre des robes, trois livraisons d'abord, une commande à la fois, prestige de l'événement, histoire sauvegardée, bulle du carnet, épilogue) échouent chacune sur une vérification qui les garde.

## Global Constraints

- **Dépôt** : `C:\dev\jeux\atelier-couture`, branche `histoire`, créée depuis `main` (où le sous-projet 2 est fusionné). Selon les règles du commanditaire : la branche testée et relue est fusionnée dans `main` et poussée sur GitHub.
- **Rojo** : `C:/dev/jeux/roblox-maker/rojo.exe`.
- **Contraintes des plans précédents toujours valables** : fins de ligne LF, commits en français terminés par `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`, textes d'au moins 14 px, le serveur fait foi.
- **Contenu original** (spec §1) : aucun événement, personnage, dialogue ni nom de Dressmaker.
- **Commandes** : tout se joue d'un seul doigt ou à la souris seule.

## Review Focus

- **Commande d'histoire demandée hors d'accueil, ou sans événement ouvert** (appel direct au serveur). Attendu : refus. Tests : `53_histoire_etat`, « aucune commande d'histoire avant trois livraisons », « une commande à la fois », « la kermesse attend le prestige 2 ».
- **Robe d'histoire abandonnée.** Attendu : elle reste à faire, on la reprend. Test : `53_histoire_etat`, « abandonnée : pas faite », « on la reprend quand on veut ».
- **Histoire abîmée dans la sauvegarde** (identifiant inconnu, valeur illisible, commande d'histoire inconnue en cours, partie sans histoire). Attendu : laissé, abandonnée, ou rien de fait. Tests : `53_histoire_etat`, « commandes inconnues ou illisibles : laissées », « commande d'une histoire inconnue : abandonnée », « partie sans histoire : rien de fait ».
- **Tenue d'histoire impossible avec ce qui est ouvert.** Attendu : jamais. Test : `52_histoire`, « … : tenue réalisable avec ce qui est ouvert ».
- **Épilogue et conversation sur petit écran** (textes longs). Attendu : lisibles, 14 px au moins. Test : scénario, `verifierTailles("épilogue")`.

## Structure des fichiers

| Fichier | Rôle |
|---|---|
| `src/shared/Histoire.luau` | **Nouveau** : les huit événements ; l'événement en cours et sa prochaine robe |
| `src/shared/Catalogue.luau` | Les huit souvenirs |
| `src/shared/Deblocages.luau` | Condition `{ evenement = id }` ; « tout ouvert » sans les souvenirs |
| `src/shared/EtatAtelier.luau` | `histoire`, `commandeHistoire`, livraison d'une robe d'histoire, événement qui a lieu |
| `src/server/Sauvegarde.luau`, `src/server/Commande.luau`, `src/client/Atelier/Session.luau` | Histoire sauvegardée ; action `commandeHistoire` |
| `src/client/Atelier/EcranAccueil.luau`, `Scene.luau`, `init.client.luau`, `src/server/Boutiques.luau` | Événement, conversation, épilogue, souvenirs ; bulles ; nom du jeu |
| `tests/unitaires/52_histoire.luau`, `53_histoire_etat.luau` | **Nouveaux** |
| `tests/unitaires/02_…`, `34_…`, `45_…`, `tests/scenario.luau` | Tests complétés |
| `README.md`, `AtelierCouture.rbxl`, `docs/superpowers/specs/2026-09-30-histoire-evenements-design.md` | Le jeu et son nom ; lieu régénéré ; spec |

---

### Task 1: Les événements du quartier (données, souvenirs, déblocages)

**Files:**
- Create: `src/shared/Histoire.luau`
- Modify: `src/shared/Catalogue.luau` (souvenirs), `src/shared/Deblocages.luau`
- Create: `tests/unitaires/52_histoire.luau`
- Modify: `tests/unitaires/02_catalogue.luau`, `45_deblocages.luau`

**Interfaces:**
- Consumes: `Progression.niveauPrestige`, `SEUILS_PRESTIGE` ; `Commandes.realisable(exigences, ouverts)`, `Deblocages.ouverts` (plans 5a, 5b).
- Produces:
  - `Histoire.EVENEMENTS` (`{ id, nom, prestige, souvenir, epilogue, commandes = { { id, cliente, exigences, repliques = { demande, detail, merci } } }, rang }`), `LIVRAISONS_DEPART = 3`, `PRESTIGE_EVENEMENT = 15` ;
  - `Histoire.get(id)`, `commande(id)` → commande, événement ; `avancee(progres, id)` → faites, total ; `aEuLieu(progres, id)` ; `enCours(etat)` → événement, ouvert ; `prochaine(etat)` → commande, événement ; `eus(progres)` ;
  - huit accessoires : `lanterne_papier`, `cocarde`, `broche_palette`, `ancre_doree`, `plume_corbeau`, `fleur_oranger`, `cle_de_sol`, `flocon_argent` ;
  - `Deblocages.CONDITIONS.accessoires[souvenir] = { evenement = id }` ; `ouvert` et `raison` (« Souvenir : Le bal des lanternes ») les comprennent ; `toutOuvert` les laisse de côté.

- [ ] **Step 1: Écrire les tests**

Dans `tests/unitaires/02_catalogue.luau`, remplacer :

```lua
U.verifier(#Catalogue.Accessoires == 15, "15 accessoires")
```

par :

```lua
U.verifier(#Catalogue.Accessoires == 23, "23 accessoires (dont les huit souvenirs du quartier)")
```

Dans `tests/unitaires/45_deblocages.luau`, remplacer :

```lua
		U.verifier((c.prestige ~= nil) ~= (c.cliente ~= nil), id .. " : une seule condition")
```

par :

```lua
		local sortes = (c.prestige and 1 or 0) + (c.cliente and 1 or 0) + (c.evenement and 1 or 0)
		U.verifier(sortes == 1, id .. " : une seule condition")
```

Créer `tests/unitaires/52_histoire.luau` :

```lua
local Histoire = U.module("Histoire")
local Clientes = U.module("Clientes")
local Catalogue = U.module("Catalogue")
local Commandes = U.module("Commandes")
local Deblocages = U.module("Deblocages")
local Progression = U.module("Progression")

-- Le tableau : huit événements, deux à quatre robes chacun, des clientes connues, des répliques, un souvenir
U.verifier(#Histoire.EVENEMENTS == 8, "huit événements")
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
U.verifier(not Deblocages.ouvert(etat, "accessoires", "lanterne_papier") and Deblocages.raison("accessoires", "lanterne_papier") == "Souvenir : Le bal des lanternes", "souvenir fermé tant que l'événement n'a pas eu lieu")
etat.histoire.faites.lanternes_margot = true
U.verifier(Histoire.aEuLieu(etat, "lanternes") and Histoire.eus(etat) == 1 and Deblocages.ouvert(etat, "accessoires", "lanterne_papier"), "les deux robes livrées : le bal a lieu, la lanterne s'ouvre")
ev, ouvert = Histoire.enCours(etat)
U.verifier(ev.id == "kermesse" and not ouvert, "la kermesse attend le prestige 2")
etat.prestige = 20
ev, ouvert = Histoire.enCours(etat)
U.verifier(ouvert and Histoire.prochaine(etat).id == "kermesse_margot", "prestige 2 : la kermesse s'annonce")
local tout = { prestige = 530, livraisons = 99, histoire = { faites = faites } }
U.verifier(Histoire.enCours(tout) == nil and Histoire.prochaine(tout) == nil and Histoire.eus(tout) == 8, "tout a eu lieu : plus d'événement")

-- « Tout ouvert » (équilibrage) ne compte pas les souvenirs, qui viennent de l'histoire
local progresTout = { prestige = 530, clientes = {} }
for _, c in ipairs(Clientes.LISTE) do
	progresTout.clientes[c.id] = { amitie = 25 }
end
U.verifier(Deblocages.toutOuvert(progresTout) and not Deblocages.ouvert(progresTout, "accessoires", "flocon_argent"), "tout ouvert par le prestige et l'amitié, sans les souvenirs")
```

- [ ] **Step 2: Lancer les tests, vérifier l'échec**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT|attempt|membre" | head -3`
Expected: échec : une ligne qui finit par `ÉCHEC : 23 accessoires (dont les huit souvenirs du quartier)`

- [ ] **Step 3: Écrire le module et le code**

Créer `src/shared/Histoire.luau` :

```lua
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
				"J'ai attrapé le bouquet ! Tu sais ce que ça veut dire…"),
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
				"La robe la plus romantique que tu aies jamais faite.",
				"Il m'a demandée en mariage sous le lustre. J'ai dit oui ! Tu feras ma robe, hein ?"),
			commande("bal_helene", "helene", { min("elegant", 45) },
				"J'ouvre le bal avec un solo. Mon retour sur scène, le vrai.",
				"Élégante, légère. Une robe de danseuse.",
				"Ils se sont levés pour m'applaudir. Je suis revenue à ma place."),
			commande("bal_ines", "ines", { min("gothique", 40) },
				"… Victoire veut que je raconte le conte de l'hiver à minuit. Au bal. Devant tout le monde.",
				"Noire comme la nuit d'hiver, avec de l'éclat.",
				"Pour une fois, personne n'a eu peur. Ils ont souri. C'est encore mieux."),
			commande("bal_victoire", "victoire", { min("elegant", 45), teinte("blanc") },
				"J'organise le grand bal d'hiver. Je voudrais être à la hauteur du quartier que tu as habillé.",
				"Blanche, élégante, digne d'une première neige.",
				"C'était le plus beau bal que le quartier ait connu. Et c'est grâce à toi."),
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
```

Dans `src/shared/Catalogue.luau`, remplacer :

```lua
	garniture("ruban_noir", "Ruban noir", 1, { gothique = 2, chic = 2 }, { largeur = 0.2, couleur = { 30, 25, 30 }, transparence = 0 }),
}
```

par :

```lua
	garniture("ruban_noir", "Ruban noir", 1, { gothique = 2, chic = 2 }, { largeur = 0.2, couleur = { 30, 25, 30 }, transparence = 0 }),
	-- Les souvenirs des événements du quartier (sous-projet 3) : chacun s'ouvre quand son événement a lieu
	objet("lanterne_papier", "Lanterne de papier", 4, { romantique = 3, mignon = 2 },
		{ forme = "boule", taille = 0.5, couleur = { 245, 150, 70 }, reflet = 0 }),
	objet("cocarde", "Cocarde", 3, { decontracte = 3, mignon = 2 },
		{ forme = "fleur", taille = 0.55, couleur = { 220, 60, 70 }, reflet = 0 }),
	objet("broche_palette", "Broche palette", 5, { chic = 3, elegant = 2 },
		{ forme = "cylindre", taille = 0.5, couleur = { 200, 160, 110 }, reflet = 0.1 }),
	objet("ancre_doree", "Ancre dorée", 5, { chic = 4 },
		{ forme = "croix", taille = 0.55, couleur = { 214, 170, 60 }, reflet = 0.4 }),
	objet("plume_corbeau", "Plume de corbeau", 4, { gothique = 4, elegant = 1 },
		{ forme = "bloc", taille = 0.6, couleur = { 25, 22, 30 }, reflet = 0.1 }),
	objet("fleur_oranger", "Fleur d'oranger", 4, { romantique = 4, elegant = 2 },
		{ forme = "fleur", taille = 0.5, couleur = { 252, 250, 240 }, reflet = 0 }),
	objet("cle_de_sol", "Clé de sol", 6, { elegant = 3, chic = 2 },
		{ forme = "cylindre", taille = 0.45, couleur = { 214, 170, 60 }, reflet = 0.4 }),
	objet("flocon_argent", "Flocon d'argent", 6, { elegant = 4, romantique = 1 },
		{ forme = "croix", taille = 0.5, couleur = { 220, 225, 235 }, reflet = 0.5 }),
}
```

Dans `src/shared/Deblocages.luau`, remplacer :

```lua
-- Déblocages (sous-projet 2) : ce qui est fermé au départ, et ce qui l'ouvre. Chaque élément du catalogue a au
-- plus une condition : un niveau de prestige, ou un niveau d'amitié avec une cliente. Rien n'est sauvegardé :
-- tout se déduit du prestige et des amitiés (un changement du tableau s'applique aux parties existantes).
```

par :

```lua
-- Déblocages (sous-projet 2) : ce qui est fermé au départ, et ce qui l'ouvre. Chaque élément du catalogue a au
-- plus une condition : un niveau de prestige, un niveau d'amitié avec une cliente, ou (sous-projet 3) un
-- événement du quartier qui a eu lieu (ses souvenirs). Rien n'est sauvegardé : tout se déduit du prestige, des
-- amitiés et de l'histoire (un changement du tableau s'applique aux parties existantes).
```

Dans `src/shared/Deblocages.luau`, remplacer :

```lua
local Progression = require(dossier:WaitForChild("Progression"))
```

par :

```lua
local Progression = require(dossier:WaitForChild("Progression"))
local Histoire = require(dossier:WaitForChild("Histoire"))
```

Dans `src/shared/Deblocages.luau`, remplacer :

```lua
-- CONDITIONS[genre][id] = { prestige = n } ou { cliente = id, amitie = n } ; absent : ouvert au départ
```

par :

```lua
-- CONDITIONS[genre][id] = { prestige = n }, { cliente = id, amitie = n } ou { evenement = id } ; absent : ouvert
-- au départ
```

Dans `src/shared/Deblocages.luau`, remplacer :

```lua
Deblocages.CONDITIONS = CONDITIONS
```

par :

```lua
for _, ev in ipairs(Histoire.EVENEMENTS) do
	CONDITIONS.accessoires[ev.souvenir] = { evenement = ev.id }
end
Deblocages.CONDITIONS = CONDITIONS
```

Dans `src/shared/Deblocages.luau`, remplacer :

```lua
-- progres : { prestige = points, clientes = { [id] = { amitie = points } } } (l'état de l'atelier convient)
function Deblocages.ouvert(progres, genre, id)
	local c = CONDITIONS[genre][id]
	if not c then
		return true
	end
```

par :

```lua
-- progres : { prestige = points, clientes = { [id] = { amitie = points } }, histoire = { faites } } (l'état de
-- l'atelier convient)
function Deblocages.ouvert(progres, genre, id)
	local c = CONDITIONS[genre][id]
	if not c then
		return true
	end
	if c.evenement then
		return Histoire.aEuLieu(progres, c.evenement)
	end
```

Dans `src/shared/Deblocages.luau`, remplacer :

```lua
	if c.prestige then
		return ("Prestige %d"):format(c.prestige)
	end
	return ("Amitié %s : %d"):format(deCliente(c.cliente), c.amitie)
```

par :

```lua
	if c.prestige then
		return ("Prestige %d"):format(c.prestige)
	elseif c.evenement then
		return ("Souvenir : %s"):format(Histoire.get(c.evenement).nom)
	end
	return ("Amitié %s : %d"):format(deCliente(c.cliente), c.amitie)
```

Dans `src/shared/Deblocages.luau`, remplacer :

```lua
-- Tout le catalogue est-il ouvert ?
function Deblocages.toutOuvert(progres)
	for _, genre in ipairs(Deblocages.GENRES) do
		for id in pairs(CONDITIONS[genre]) do
			if not Deblocages.ouvert(progres, genre, id) then
```

par :

```lua
-- Tout ce que le prestige et l'amitié ouvrent est-il ouvert ? (Les souvenirs viennent de l'histoire, à part.)
function Deblocages.toutOuvert(progres)
	for _, genre in ipairs(Deblocages.GENRES) do
		for id, c in pairs(CONDITIONS[genre]) do
			if not c.evenement and not Deblocages.ouvert(progres, genre, id) then
```

- [ ] **Step 4: Lancer les tests**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT"`
Expected:
```
Unitaires : 107633 vérifications
TOUT EST VERT : 635 vérifications
```

- [ ] **Step 5: Commit**

```bash
git add src/shared/Histoire.luau src/shared/Catalogue.luau src/shared/Deblocages.luau tests/unitaires/52_histoire.luau tests/unitaires/02_catalogue.luau tests/unitaires/45_deblocages.luau
git commit -m "Histoire : les huit événements du quartier, leurs robes, répliques et souvenirs

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 2: Les règles de l'histoire (commande, livraison, sauvegarde)

**Files:**
- Modify: `src/shared/EtatAtelier.luau`
- Modify: `src/server/Sauvegarde.luau`, `src/server/Commande.luau`, `src/client/Atelier/Session.luau`
- Create: `tests/unitaires/53_histoire_etat.luau`

**Interfaces:**
- Consumes: `Histoire.prochaine`, `commande`, `aEuLieu`, `PRESTIGE_EVENEMENT` (tâche 1) ; `accueillir` (plan 5d).
- Produces:
  - champ `histoire = { faites = { [idCommande] = true } }` ; `commande.histoire` ;
  - `EtatAtelier:commandeHistoire()` → comme `nouvelleCommande` ; refus « Aucun événement ne s'annonce pour l'instant. » ;
  - `livrer` d'une robe d'histoire : faite ; la dernière de l'événement → réponse `evenement = { id, nom, epilogue, souvenir }` et 15 de prestige en plus ;
  - action serveur `commandeHistoire` ; `Session:commandeHistoire()`.

- [ ] **Step 1: Écrire les tests**

Créer `tests/unitaires/53_histoire_etat.luau` :

```lua
local EtatAtelier = U.module("EtatAtelier")
local Clientes = U.module("Clientes")
local Histoire = U.module("Histoire")
local Deblocages = U.module("Deblocages")
local Sauvegarde = U.module("Sauvegarde")

-- Une robe simple, coupée, épinglée et cousue, présentée ; la cliente ne demande qu'un peu de qualité
local function robePrete(etat)
	etat.croquis = { corsage = "corsage_droit", manches = "manches_sans", col = "col_sans", jupe = "jupe_droite" }
	etat.tissus = { corsage_droit_devant = "coton_blanc", corsage_droit_dos = "coton_blanc", jupe_droite_devant = "coton_blanc", jupe_droite_dos = "coton_blanc" }
	for id in pairs(etat.tissus) do
		etat.coupees[id] = { x = 0, y = 0, angle = 0 }
		etat.epinglees[id] = true
		etat.coutures[id] = 1
	end
	etat.etape = "decorations"
	assert(etat:decorer({}).ok)
	etat.commande.exigences = { { type = "qualite", valeur = 0.1 } }
end
-- La commande de l'événement, mesurée et livrée ; renvoie la réponse de la livraison
local function robeHistoireLivree(etat)
	assert(etat:commandeHistoire().ok)
	assert(etat:mesurer(Clientes.get(etat.commande.cliente).mesures).ok)
	robePrete(etat)
	return etat:livrer()
end

-- Rien avant trois commandes livrées
local e = EtatAtelier.nouveau(500)
local r = e:commandeHistoire()
U.verifier(not r.ok and r.erreur == "Aucun événement ne s'annonce pour l'instant." and e.etape == "accueil", "aucune commande d'histoire avant trois livraisons")

-- Le bal des lanternes : Colette d'abord, avec la tenue du tableau ; même accueil que la clochette
e.livraisons = 3
local argent = e.argent
r = e:commandeHistoire()
local def = Histoire.commande("lanternes_colette")
U.verifier(r.ok and e.etape == "mesures" and e.commande.cliente == "colette" and e.commande.histoire == "lanternes_colette", "la commande de l'événement : Colette, à mesurer")
U.verifier(#e.commande.exigences == #def.exigences and e.commande.exigences ~= def.exigences and e.commande.exigences[1].style == def.exigences[1].style, "sa tenue : celle du tableau (une copie)")
U.verifier(r.acompte > 0 and e.argent == argent + r.acompte and e.clientes.colette.vues == 1, "elle verse l'acompte ; sa visite est notée")
U.verifier(not e:commandeHistoire().ok, "une commande à la fois")
e:mesurer(Clientes.get("colette").mesures)
robePrete(e)
r = e:livrer()
U.verifier(r.reussie and e.histoire.faites.lanternes_colette and r.evenement == nil, "livrée : faite ; le bal attend encore une robe")

-- Margot : la dernière robe fait avoir lieu le bal (épilogue, souvenir, prestige en plus)
local prestigeAvant = e.prestige
r = robeHistoireLivree(e)
U.verifier(r.reussie and r.evenement ~= nil and r.evenement.id == "lanternes" and r.evenement.souvenir == "lanterne_papier" and r.evenement.epilogue == Histoire.get("lanternes").epilogue, "la dernière robe livrée : le bal des lanternes a lieu")
U.verifier(r.prestige.gain == math.round(r.paie / 10) + Histoire.PRESTIGE_EVENEMENT and e.prestige == prestigeAvant + r.prestige.gain, "prestige de la livraison, et 15 de plus pour l'événement")
local ouvre = false
for _, n in ipairs(r.nouveaux) do
	ouvre = ouvre or n.id == "lanterne_papier"
end
U.verifier(ouvre and Deblocages.ouvert(e, "accessoires", "lanterne_papier"), "le souvenir s'ouvre, et c'est annoncé")
e.prestige = 19
U.verifier(not e:commandeHistoire().ok, "la kermesse attend le prestige 2")

-- Abandonnée, une robe d'histoire reste à faire
e.prestige = 20
assert(e:commandeHistoire().ok)
local id = e.commande.histoire
e:mesurer(Clientes.get(e.commande.cliente).mesures)
e.etape = "refus"
assert(e:abandonner().ok)
U.verifier(not e.histoire.faites[id], "abandonnée : pas faite")
U.verifier(e:commandeHistoire().ok and e.commande.histoire == id, "on la reprend quand on veut")

-- Sauvegarde : l'histoire suit la partie ; ce qui est inconnu est laissé ; la commande d'histoire en cours aussi
local p = M.transmettre(Sauvegarde.depuisEtat(e))
local relue = Sauvegarde.versEtat(p)
U.verifier(relue.histoire.faites.lanternes_colette and relue.histoire.faites.lanternes_margot and relue.commande.histoire == id, "l'histoire et la commande d'histoire en cours sont sauvegardées")
p.histoire.faites.inconnue, p.histoire.faites.kermesse_salome = true, "oui"
relue = Sauvegarde.versEtat(p)
U.verifier(relue.histoire.faites.inconnue == nil and relue.histoire.faites.kermesse_salome == nil and relue.histoire.faites.lanternes_colette, "commandes inconnues ou illisibles : laissées")
p.enCours.commande.histoire = "inconnue"
U.verifier(Sauvegarde.versEtat(p).etape == "accueil", "commande d'une histoire inconnue : abandonnée")
local vieille = M.transmettre(Sauvegarde.depuisEtat(EtatAtelier.nouveau(100)))
vieille.histoire = nil
U.verifier(next(Sauvegarde.versEtat(vieille).histoire.faites) == nil, "partie sans histoire : rien de fait")
```

- [ ] **Step 2: Lancer les tests, vérifier l'échec**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT|attempt|membre" | head -3`
Expected: échec : une ligne qui finit par `attempt to call missing method 'commandeHistoire' of table`

- [ ] **Step 3: Écrire le code**

Dans `src/shared/EtatAtelier.luau`, remplacer :

```lua
local Deblocages = require(dossier:WaitForChild("Deblocages"))
```

par :

```lua
local Deblocages = require(dossier:WaitForChild("Deblocages"))
local Histoire = require(dossier:WaitForChild("Histoire"))
```

Dans `src/shared/EtatAtelier.luau`, remplacer :

```lua
"ventes", "lettres" }
```

par :

```lua
"ventes", "lettres", "histoire" }
```

Dans `src/shared/EtatAtelier.luau`, remplacer :

```lua
		lettres = {}, -- le courrier : { { cliente, commande } }, trois au plus
```

par :

```lua
		lettres = {}, -- le courrier : { { cliente, commande } }, trois au plus
		histoire = { faites = {} }, -- sous-projet 3 : les commandes d'histoire livrées ([idCommande] = true)
```

Dans `src/shared/EtatAtelier.luau`, remplacer :

```lua
-- Le courrier : après cinq commandes livrées, une lettre arrive toutes les deux robes (livrées ou vendues), d'une
```

par :

```lua
-- La commande de l'événement en cours (sous-projet 3) : sa prochaine robe, de la cliente et avec la tenue du
-- tableau de l'histoire (jamais d'un appel du client) ; même accueil que la clochette
function EtatAtelier:commandeHistoire()
	if self.etape ~= "accueil" then
		return refus("Une commande est déjà en cours.")
	end
	local def = Histoire.prochaine(self)
	if not def then
		return refus("Aucun événement ne s'annonce pour l'instant.")
	end
	local cliente = Clientes.get(def.cliente)
	return accueillir(self, def.cliente, { cliente = def.cliente, taille = cliente.taille, exigences = copie(def.exigences), histoire = def.id })
end

-- Le courrier : après cinq commandes livrées, une lettre arrive toutes les deux robes (livrées ou vendues), d'une
```

Dans `src/shared/EtatAtelier.luau`, remplacer :

```lua
	local avant = { prestige = self.prestige, clientes = {} } -- pour dire ce que la livraison a ouvert
	for id, f in pairs(self.clientes) do
		avant.clientes[id] = { amitie = f.amitie }
	end
	local paie = Notation.paie(#recette.pieces, #self.commande.exigences, bilan.qualite)
```

par :

```lua
	local avant = { prestige = self.prestige, clientes = {}, histoire = { faites = table.clone(self.histoire.faites) } } -- pour dire ce que la livraison a ouvert
	for id, f in pairs(self.clientes) do
		avant.clientes[id] = { amitie = f.amitie }
	end
	-- Une robe d'histoire livrée : faite ; la dernière de son événement le fait avoir lieu (épilogue, souvenir,
	-- prestige en plus)
	local evenement
	if self.commande.histoire then
		self.histoire.faites[self.commande.histoire] = true
		local _, ev = Histoire.commande(self.commande.histoire)
		if ev and Histoire.aEuLieu(self, ev.id) then
			evenement = { id = ev.id, nom = ev.nom, epilogue = ev.epilogue, souvenir = ev.souvenir }
		end
	end
	local paie = Notation.paie(#recette.pieces, #self.commande.exigences, bilan.qualite)
```

Dans `src/shared/EtatAtelier.luau`, remplacer :

```lua
	local gainPrestige = Progression.prestigeLivraison(paie)
	self.prestige += gainPrestige
```

par :

```lua
	local gainPrestige = Progression.prestigeLivraison(paie) + (if evenement then Histoire.PRESTIGE_EVENEMENT else 0)
	self.prestige += gainPrestige
```

Dans `src/shared/EtatAtelier.luau`, remplacer :

```lua
	return { ok = true, reussie = true, paie = paie, acompte = acompte, verse = verse, bilan = bilan, ratees = {}, amitie = gainAmitie, prestige = prestige, nouveaux = nouveaux, lettre = courrier(self, rng) }
```

par :

```lua
	return { ok = true, reussie = true, paie = paie, acompte = acompte, verse = verse, bilan = bilan, ratees = {}, amitie = gainAmitie, prestige = prestige, nouveaux = nouveaux, lettre = courrier(self, rng), evenement = evenement }
```

Dans `src/server/Sauvegarde.luau`, remplacer :

```lua
local Clientes = require(Couture:WaitForChild("Clientes"))
```

par :

```lua
local Clientes = require(Couture:WaitForChild("Clientes"))
local Histoire = require(Couture:WaitForChild("Histoire"))
```

Dans `src/server/Sauvegarde.luau`, remplacer :

```lua
	if c.parLettre ~= nil and c.parLettre ~= true then
		return false
	end
```

par :

```lua
	if c.parLettre ~= nil and c.parLettre ~= true then
		return false
	end
	if c.histoire ~= nil and not (type(c.histoire) == "string" and Histoire.commande(c.histoire)) then
		return false
	end
```

Dans `src/server/Sauvegarde.luau`, remplacer :

```lua
		lettres = d.lettres,
```

par :

```lua
		lettres = d.lettres,
		histoire = d.histoire,
```

Dans `src/server/Sauvegarde.luau`, remplacer :

```lua
	-- Courrier : trois lettres au plus, d'une cliente connue, avec une commande qu'on peut jouer
```

par :

```lua
	-- Histoire : les commandes livrées, connues du tableau seulement
	local histoire = type(partie.histoire) == "table" and type(partie.histoire.faites) == "table" and partie.histoire.faites or {}
	for id, fait in pairs(histoire) do
		if fait == true and type(id) == "string" and Histoire.commande(id) then
			base.histoire.faites[id] = true
		end
	end
	-- Courrier : trois lettres au plus, d'une cliente connue, avec une commande qu'on peut jouer
```

Dans `src/server/Commande.luau`, remplacer :

```lua
	inviter = function(a, indice)
		return a.etat:inviter(indice)
	end,
```

par :

```lua
	inviter = function(a, indice)
		return a.etat:inviter(indice)
	end,
	commandeHistoire = function(a)
		return a.etat:commandeHistoire()
	end,
```

Dans `src/client/Atelier/Session.luau`, remplacer :

```lua
function Session:inviter(indice)
	return agir(self, "inviter", indice)
end
```

par :

```lua
function Session:inviter(indice)
	return agir(self, "inviter", indice)
end
function Session:commandeHistoire()
	return agir(self, "commandeHistoire")
end
```

- [ ] **Step 4: Lancer les tests**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT"`
Expected:
```
Unitaires : 107649 vérifications
TOUT EST VERT : 635 vérifications
```

- [ ] **Step 5: Commit**

```bash
git add src/shared/EtatAtelier.luau src/server/Sauvegarde.luau src/server/Commande.luau src/client/Atelier/Session.luau tests/unitaires/53_histoire_etat.luau
git commit -m "Robes d'histoire : la cliente de l'événement vient, la dernière robe le fait avoir lieu

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 3: L'histoire à l'écran, et le nom du jeu

**Files:**
- Modify: `src/client/Atelier/EcranAccueil.luau`, `Scene.luau`, `init.client.luau`
- Modify: `src/server/Boutiques.luau` (enseigne)
- Modify: `tests/unitaires/34_boutiques.luau`, `tests/scenario.luau`

**Interfaces:**
- Consumes: tout ce que produisent les tâches 1 et 2.
- Produces: accueil : texte `Evenement`, bouton `CommandeHistoire`, cadre `Conversation` (textes `Interlocutrice`, `Replique`, boutons `SuivantConversation`, `AccepterCommande`, `PlusTard`), cadre `Epilogue` (textes `TitreEpilogue`, `TexteEpilogue`, `Souvenir`, bouton `FermerEpilogue`), texte `Souvenirs` du carnet d'adresses ; titre de l'accueil « Aiguille & Dentelle » ; enseigne « Aiguille & Dentelle — <joueur> ».

- [ ] **Step 1: Écrire les tests**

Dans `tests/unitaires/34_boutiques.luau`, remplacer :

```lua
U.verifier(texteEnseigne ~= nil and string.find(texteEnseigne.Text, "Couturiere3", 1, true) ~= nil and texteEnseigne.TextSize >= 14, "enseigne au nom de la joueuse")
```

par :

```lua
U.verifier(texteEnseigne ~= nil and string.find(texteEnseigne.Text, "Couturiere3", 1, true) ~= nil and texteEnseigne.TextSize >= 14, "enseigne au nom de la joueuse")
U.verifier(string.find(texteEnseigne.Text, "Aiguille & Dentelle — ", 1, true) == 1, "l'enseigne porte le nom du jeu : « Aiguille & Dentelle — Couturiere3 »")
```

Dans `tests/scenario.luau`, remplacer :

```lua
verifier(titre() == "Atelier de couture" and texte("Colette est ravie") ~= nil and texte("Amitié de Colette : +4") ~= nil, "commande venue par lettre : +4 d'amitié (+3 et +1 de la lettre)")
M.avancer(ScenePoste.DUREE_ADIEU + 0.5)
end
```

par :

```lua
verifier(titre() == "Atelier de couture" and texte("Colette est ravie") ~= nil and texte("Amitié de Colette : +4") ~= nil, "commande venue par lettre : +4 d'amitié (+3 et +1 de la lettre)")
M.avancer(ScenePoste.DUREE_ADIEU + 0.5)
end

---------------------------------------------------------------------------
-- L'histoire : l'événement du quartier en cours ; une conversation, puis la commande ; la dernière robe livrée
-- le fait avoir lieu (épilogue, souvenir), et le suivant s'annonce
---------------------------------------------------------------------------
do
local Histoire = requireModule(dossier.Histoire)
local e = serveur:atelier(joueur).etat
verifier(texte("Événement : Le bal des lanternes — robes livrées 0 / 2") ~= nil and boutonNomme("CommandeHistoire") ~= nil, "l'événement en cours s'annonce à l'accueil")
e.histoire.faites.lanternes_margot = true -- (la robe de Margot, déjà livrée : celle de Colette sera la dernière)
local def = Histoire.commande("lanternes_colette")
cliquer("CommandeHistoire")
local conversation = fenetre.Contenu.Conversation
verifier(conversation.Visible and conversation.Interlocutrice.Text == "Colette Marchand" and conversation.Replique.Text == def.repliques.demande, "une conversation : Colette dit pourquoi elle a besoin d'une robe")
cliquer("SuivantConversation")
verifier(conversation.Replique.Text == def.repliques.detail and boutonNomme("AccepterCommande") ~= nil, "« Suivant » : ce qu'elle voudrait ; puis « Accepter la commande »")
cliquer("AccepterCommande")
verifier(titre() == "Les mesures" and e.commande.histoire == "lanternes_colette" and e.commande.exigences[1].style == def.exigences[1].style, "la commande de l'événement commence, avec la tenue du tableau")
M.avancer(0.5)
verifier(scene.Cliente.Head.Bulle.Texte.Text == def.repliques.demande, "aux mesures, elle redit sa demande")
cliquer("ReprendreMesures")
verifier(scene.Cliente.Head.Bulle.Texte.Text == def.repliques.detail, "au carnet, ce qu'elle voudrait")
-- La robe menée jusqu'à la photo sur le serveur, sans repasser par tous les postes
e.commande.exigences = { { type = "qualite", valeur = 0.1 } }
e.croquis = { corsage = "corsage_droit", manches = "manches_sans", col = "col_sans", jupe = "jupe_droite" }
e.tissus = {}
for _, id in ipairs(e:piecesDuCroquis()) do
	e.tissus[id] = "coton_blanc"
	e.coupees[id] = { x = 0, y = 0, angle = 0 }
	e.epinglees[id] = true
	e.coutures[id] = 0.9
end
e.etape = "photo"
requireModule(scriptClient.Session).courante:actualiser()
local laColette = scene.Cliente
cliquer("Livrer")
cliquer("Livrer")
verifier(titre() == "Aiguille & Dentelle" and fenetre.Contenu.Epilogue.Visible and texte("Le bal des lanternes a eu lieu !") ~= nil and texte("Souvenir : Lanterne de papier") ~= nil, "la dernière robe livrée : le bal a lieu, épilogue et souvenir")
verifier(texte(Histoire.get("lanternes").epilogue) ~= nil and laColette.Head.Bulle.Texte.Text == def.repliques.merci, "l'épilogue ; Colette raconte la suite")
verifierTailles("épilogue")
cliquer("FermerEpilogue")
verifier(not fenetre.Contenu.Epilogue.Visible and texte("Événement : La kermesse du square — robes livrées 0 / 2") ~= nil, "l'événement suivant s'annonce")
cliquer("OuvrirCarnetAdresses")
verifier(texte("Le bal des lanternes — souvenir : Lanterne de papier") ~= nil, "le carnet d'adresses garde les souvenirs du quartier")
cliquer("FermerCarnetAdresses")
M.avancer(ScenePoste.DUREE_ADIEU + 0.5)
end
```

Le titre de l'accueil devient le nom du jeu dans tout le scénario. Appliquer :

```bash
python - <<'EOF'
import pathlib
p = pathlib.Path("tests/scenario.luau")
s = p.read_text(encoding="utf-8")
print("titres :", s.count('titre() == "Atelier de couture"'))
p.write_bytes(s.replace('titre() == "Atelier de couture"', 'titre() == "Aiguille & Dentelle"').encode("utf-8"))
EOF
```

Sortie attendue : `titres : 7`.

- [ ] **Step 2: Lancer les tests, vérifier l'échec**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT|attempt|membre" | head -3`
Expected: échec : une ligne qui finit par `ÉCHEC : l'enseigne porte le nom du jeu : « Aiguille & Dentelle — Couturiere3 »`

- [ ] **Step 3: Écrire le code**

Dans `src/client/Atelier/EcranAccueil.luau`, remplacer :

```lua
-- d'adresses » à côté ; le courrier (après cinq commandes livrées) en dessous, chaque lettre avec « Inviter ».
```

par :

```lua
-- d'adresses » à côté ; l'événement du quartier en cours (sous-projet 3) et le courrier (après cinq commandes
-- livrées) en dessous. Quand un événement a lieu, son épilogue s'affiche par-dessus.
```

Dans `src/client/Atelier/EcranAccueil.luau`, remplacer :

```lua
local Catalogue = require(Couture:WaitForChild("Catalogue"))
```

par :

```lua
local Catalogue = require(Couture:WaitForChild("Catalogue"))
local Histoire = require(Couture:WaitForChild("Histoire"))
```

Dans `src/client/Atelier/EcranAccueil.luau`, remplacer :

```lua
		UiKit.texte({ Name = "Courrier", Text = if #etat.lettres > 0 then "Courrier :" else "Courrier : pas de lettre pour l'instant.", Font = Enum.Font.GothamBold, Position = UDim2.fromOffset(0, y + 50), Size = UDim2.fromOffset(500, 22), Parent = ctx.contenu })
```

par :

```lua
		UiKit.texte({ Name = "Courrier", Text = if #etat.lettres > 0 then "Courrier :" else "Courrier : pas de lettre pour l'instant.", Font = Enum.Font.GothamBold, Position = UDim2.fromOffset(0, y + 88), Size = UDim2.fromOffset(500, 22), Parent = ctx.contenu })
```

Dans `src/client/Atelier/EcranAccueil.luau`, remplacer :

```lua
			local yl = y + 76 + (i - 1) * 40
```

par :

```lua
			local yl = y + 114 + (i - 1) * 40
```

Dans `src/client/Atelier/EcranAccueil.luau`, remplacer :

```lua
	-- Le courrier : chaque lettre annonce la première exigence de la commande ; « Inviter » fait venir la cliente
```

par :

```lua
	-- L'histoire : l'événement en cours ; sa prochaine robe commence par une conversation avec la cliente
	local evenement, ouvert = Histoire.enCours(etat)
	local texteEvenement
	if not evenement then
		texteEvenement = "Tous les événements du quartier ont eu lieu."
	elseif ouvert then
		local faites, total = Histoire.avancee(etat, evenement.id)
		texteEvenement = ("Événement : %s — robes livrées %d / %d"):format(evenement.nom, faites, total)
	elseif etat.livraisons < Histoire.LIVRAISONS_DEPART then
		texteEvenement = ("Bientôt : %s (après trois commandes livrées)"):format(evenement.nom)
	else
		texteEvenement = ("Bientôt : %s (prestige %d)"):format(evenement.nom, evenement.prestige)
	end
	UiKit.texte({ Name = "Evenement", Text = texteEvenement, Font = Enum.Font.GothamBold, Position = UDim2.fromOffset(0, y + 54), Size = UDim2.fromOffset(560, 22), Parent = ctx.contenu })
	if ouvert then
		local def = Histoire.prochaine(etat)
		local cliente = Clientes.get(def.cliente)
		local conversation = UiKit.arrondir(UiKit.creer("TextButton", { Name = "Conversation", Text = "", AutoButtonColor = false, Visible = false, BackgroundColor3 = C.panneau, Size = UDim2.fromScale(1, 1), ZIndex = 20, Parent = ctx.contenu }), 10)
		UiKit.texte({ Name = "Interlocutrice", Text = cliente.nom, Font = Enum.Font.GothamBold, TextSize = 18, Size = UDim2.new(1, -130, 0, 34), ZIndex = 21, Parent = conversation })
		local replique = UiKit.texte({ Name = "Replique", Text = def.repliques.demande, TextSize = 18, Position = UDim2.fromOffset(0, 44), Size = UDim2.new(1, 0, 0, 90), ZIndex = 21, Parent = conversation })
		local suivant, accepter
		suivant = UiKit.bouton({ Name = "SuivantConversation", Text = "Suivant", Position = UDim2.fromOffset(0, 150), Size = UDim2.fromOffset(200, 44), ZIndex = 21, Parent = conversation }, function()
			replique.Text = def.repliques.detail
			suivant.Visible = false
			accepter.Visible = true
		end)
		accepter = UiKit.bouton({ Name = "AccepterCommande", Text = "Accepter la commande", Visible = false, Position = UDim2.fromOffset(0, 150), Size = UDim2.fromOffset(260, 44), ZIndex = 21, Parent = conversation }, function()
			conversation.Visible = false
			accueillie(ctx.session:commandeHistoire())
		end)
		UiKit.boutonDoux({ Name = "PlusTard", Text = "Plus tard", TextSize = 14, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -6, 0, 0), Size = UDim2.fromOffset(110, 34), ZIndex = 21, Parent = conversation }, function()
			conversation.Visible = false
		end)
		UiKit.bouton({ Name = "CommandeHistoire", Text = "Commande de l'événement", TextSize = 16, Position = UDim2.fromOffset(570, y + 48), Size = UDim2.fromOffset(260, 34), Parent = ctx.contenu }, function()
			replique.Text = def.repliques.demande
			suivant.Visible, accepter.Visible = true, false
			conversation.Visible = true
		end)
	end
	-- Un événement vient d'avoir lieu : son épilogue et son souvenir, par-dessus l'accueil
	local eu = r and action == "livrer" and r.evenement
	if eu then
		local epilogue = UiKit.arrondir(UiKit.creer("TextButton", { Name = "Epilogue", Text = "", AutoButtonColor = false, BackgroundColor3 = C.panneau, Size = UDim2.fromScale(1, 1), ZIndex = 22, Parent = ctx.contenu }), 10)
		UiKit.texte({ Name = "TitreEpilogue", Text = ("%s a eu lieu !"):format(eu.nom), Font = Enum.Font.GothamBold, TextSize = 20, TextColor3 = C.accent, Size = UDim2.new(1, -130, 0, 34), ZIndex = 23, Parent = epilogue })
		UiKit.texte({ Name = "TexteEpilogue", Text = eu.epilogue, TextSize = 18, Position = UDim2.fromOffset(0, 44), Size = UDim2.new(1, 0, 0, 90), ZIndex = 23, Parent = epilogue })
		local souvenir = Catalogue.accessoire(eu.souvenir)
		UiKit.texte({ Name = "Souvenir", Text = ("Souvenir : %s (une nouvelle décoration). Prestige : +%d."):format(souvenir and souvenir.nom or eu.souvenir, Histoire.PRESTIGE_EVENEMENT), TextSize = 16, Position = UDim2.fromOffset(0, 144), Size = UDim2.new(1, 0, 0, 44), ZIndex = 23, Parent = epilogue })
		UiKit.boutonDoux({ Name = "FermerEpilogue", Text = "Fermer", TextSize = 14, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -6, 0, 0), Size = UDim2.fromOffset(110, 34), ZIndex = 23, Parent = epilogue }, function()
			epilogue.Visible = false
		end)
	end
	-- Le courrier : chaque lettre annonce la première exigence de la commande ; « Inviter » fait venir la cliente
```

Dans `src/client/Atelier/EcranAccueil.luau`, remplacer :

```lua
				ZIndex = 21,
				Parent = carnet,
			})
		end
```

par :

```lua
				ZIndex = 21,
				Parent = carnet,
			})
		end
		-- Les événements qui ont eu lieu, et leurs souvenirs
		local passes = {}
		for _, ev in ipairs(Histoire.EVENEMENTS) do
			if Histoire.aEuLieu(etat, ev.id) then
				local souvenir = Catalogue.accessoire(ev.souvenir)
				table.insert(passes, ("%s — souvenir : %s"):format(ev.nom, souvenir and souvenir.nom or ev.souvenir))
			end
		end
		if #passes > 0 then
			UiKit.texte({ Name = "Souvenirs", Text = "Souvenirs du quartier :\n" .. table.concat(passes, "\n"), TextSize = 16, Position = UDim2.fromOffset(0, 54 + #venues * 34), Size = UDim2.new(1, 0, 0, 22 * (#passes + 1)), ZIndex = 21, Parent = carnet })
		end
```

Dans `src/client/Atelier/Scene.luau`, remplacer :

```lua
local Clientes = require(Couture:WaitForChild("Clientes"))
```

par :

```lua
local Clientes = require(Couture:WaitForChild("Clientes"))
local Histoire = require(Couture:WaitForChild("Histoire"))
```

Dans `src/client/Atelier/Scene.luau`, remplacer :

```lua
	local visite = etat.clientes[fiche.id]
	local revient = visite ~= nil and visite.vues > 1
	if etat.etape == "mesures" then
```

par :

```lua
	local visite = etat.clientes[fiche.id]
	local revient = visite ~= nil and visite.vues > 1
	-- Une commande d'histoire : sa demande aux mesures (après sa présentation, la première fois), son détail au carnet
	local histoire = etat.commande.histoire and Histoire.commande(etat.commande.histoire)
	if histoire and etat.etape == "mesures" and revient then
		return histoire.repliques.demande
	elseif histoire and etat.etape == "carnet" then
		return histoire.repliques.detail
	end
	if etat.etape == "mesures" then
```

Dans `src/client/Atelier/Scene.luau`, remplacer :

```lua
		self.clienteId = commande.cliente
```

par :

```lua
		self.clienteId = commande.cliente
		self.clienteHistoire = commande.histoire
```

Dans `src/client/Atelier/Scene.luau`, remplacer :

```lua
		local merci = fiche and fiche.repliques.merci or Scene.PAROLES.merci
```

par :

```lua
		local histoire = self.clienteHistoire and Histoire.commande(self.clienteHistoire)
		local merci = histoire and histoire.repliques.merci or fiche and fiche.repliques.merci or Scene.PAROLES.merci
```

Dans `src/client/Atelier/init.client.luau`, remplacer :

```lua
	accueil = "Atelier de couture",
```

par :

```lua
	accueil = "Aiguille & Dentelle",
```

Dans `src/client/Atelier/init.client.luau`, remplacer :

```lua
offrir = "reussite", inviter = "clochette" }
```

par :

```lua
offrir = "reussite", inviter = "clochette", commandeHistoire = "clochette" }
```

Dans `src/server/Boutiques.luau`, remplacer :

```lua
	texte.Text = "L'atelier de " .. nom
```

par :

```lua
	texte.Text = "Aiguille & Dentelle — " .. nom
```

- [ ] **Step 4: Lancer les tests**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT"`
Expected:
```
Unitaires : 107650 vérifications
TOUT EST VERT : 657 vérifications
```

- [ ] **Step 5: Commit**

```bash
git add src/client/Atelier/EcranAccueil.luau src/client/Atelier/Scene.luau src/client/Atelier/init.client.luau src/server/Boutiques.luau tests/unitaires/34_boutiques.luau tests/scenario.luau
git commit -m "L'histoire à l'écran : événement, conversation, épilogue, souvenirs ; le jeu s'appelle Aiguille & Dentelle

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 4: Vérification dans Studio et README

**Files:**
- Modify: `README.md`
- Modify: `AtelierCouture.rbxl` (régénéré)

**Interfaces:**
- Consumes: tout ce qui précède.
- Produces: le sous-projet 3 terminé côté code.

- [ ] **Step 1: En Play, par le connecteur MCP**

Construire le lieu du dépôt dans un dossier temporaire (`C:/dev/jeux/roblox-maker/rojo.exe build -o <dossier temporaire>/Plan6Depot.rbxl`), l'ouvrir dans Studio, lancer Play et attendre 4 s. Puis :

1. Côté client (`execute_luau`), lire le titre de la fenêtre et le texte `Evenement` de l'accueil.
2. Côté serveur, lire le texte de l'enseigne de `workspace.Rue.Boutique_1`.
3. Relever les alertes (`get_console_output`).

Expected :
- titre « Aiguille & Dentelle » ; « Bientôt : Le bal des lanternes (après trois commandes livrées) » ;
- enseigne « Aiguille & Dentelle — <nom du joueur> » ;
- aucune alerte de notre code (« Lieu non publié » et les messages internes de Roblox mis à part).

La conversation, la commande d'histoire et l'épilogue, qui demandent trois commandes livrées, sont joués par le scénario. Arrêter Play et fermer cette fenêtre de Studio (sans enregistrer).

- [ ] **Step 2: À faire par le commanditaire**

- jouer le bal des lanternes jusqu'à son épilogue ; lire les conversations ;
- dire si le nom « Aiguille & Dentelle » convient (il se change dans `init.client.luau`, `Boutiques.luau` et le README).

Les noter dans le message de fin, sans bloquer le plan.

- [ ] **Step 3: Mettre à jour le README**

Dans `README.md`, remplacer :

```markdown
# Atelier de couture — jeu Roblox
```

par :

```markdown
# Aiguille & Dentelle — jeu Roblox
```

Dans `README.md`, remplacer :

```markdown
`docs/superpowers/specs/2026-09-29-clientes-progression-design.md` pour les clientes et la progression ;
plans : `docs/superpowers/plans/`).
```

par :

```markdown
`docs/superpowers/specs/2026-09-29-clientes-progression-design.md` pour les clientes et la progression,
`docs/superpowers/specs/2026-09-30-histoire-evenements-design.md` pour l'histoire ; plans : `docs/superpowers/plans/`).
```

Dans `README.md`, remplacer :

```markdown
## État actuel (sous-projet 2 terminé côté code, plans 5a à 5d : clientes, prestige, déblocages, robes libres, courrier)
```

par :

```markdown
## État actuel (sous-projet 3 terminé côté code, plan 6 : l'histoire et les événements du quartier)
```

Dans `README.md`, remplacer :

```markdown
9. La suite : sous-projet 3 (histoire, dialogues, événements, nom définitif du jeu), puis sous-projet 4 (porter
   la robe, défilés).
```

par :

```markdown
9. **L'histoire** : huit événements du quartier se suivent (le bal des lanternes, la kermesse, le vernissage, les
   régates, la veillée des contes, le mariage de Margot, le concert du kiosque, le grand bal d'hiver). Le premier
   s'annonce après trois commandes livrées, les suivants à leur prestige. « Commande de l'événement » ouvre une
   conversation avec la cliente (pourquoi elle a besoin de cette robe, ce qu'elle voudrait), puis la commande,
   avec une tenue imposée. Toutes les robes livrées, l'événement a lieu : son épilogue, un souvenir (une des huit
   décorations nouvelles) et 15 de prestige ; le carnet d'adresses garde les souvenirs. Les commandes ordinaires
   continuent à côté.
10. La suite : sous-projet 4 (porter la robe sur son avatar, défilés).
```

Dans `README.md`, remplacer :

```markdown
  | `Deblocages` | Ce qui est fermé au départ et ce qui l'ouvre (prestige, amitié) ; ce qu'une livraison vient d'ouvrir ; ce que l'amitié d'une cliente ouvrira ensuite |
```

par :

```markdown
  | `Deblocages` | Ce qui est fermé au départ et ce qui l'ouvre (prestige, amitié, événement) ; ce qu'une livraison vient d'ouvrir ; ce que l'amitié d'une cliente ouvrira ensuite |
  | `Histoire` | Les huit événements du quartier : leurs robes, tenues, répliques, épilogues et souvenirs ; l'événement en cours et sa prochaine robe |
```

- [ ] **Step 4: Tests, lieu régénéré, commit**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT"`
Expected:
```
Unitaires : 107650 vérifications
TOUT EST VERT : 657 vérifications
```

```bash
C:/dev/jeux/roblox-maker/rojo.exe build -o AtelierCouture.rbxl
git add README.md AtelierCouture.rbxl
git commit -m "Plan 6 terminé : sous-projet 3 (l'histoire et les événements du quartier) complet

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```
