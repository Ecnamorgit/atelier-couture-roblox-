# Clientes et progression — Plan 5a : les clientes

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Six clientes qui reviennent (nom, tenue, goûts, répliques), la prise de leurs mesures au ruban et l'ajustement de la robe, l'amitié de chaque cliente et un premier compte de prestige ; la partie passe en v3.

**Architecture:**
- **Données** (partagées) : `Clientes` décrit les six clientes (mesures réelles, tenue, styles, teinte, répliques, ce que l'amitié ouvrira) et choisit qui vient à la clochette (`Clientes.prochaine`) ; `Progression` porte les seuils et les gains d'amitié et de prestige.
- **Règles** (`EtatAtelier`, serveur) : la clochette fait venir une cliente et passe par une nouvelle étape « mesures » avant le carnet ; `mesurer` refuse un ruban mal réglé ; la qualité est multipliée par l'ajustement (`EtatAtelier:bilan`) ; livrer et abandonner changent l'amitié, livrer rapporte du prestige. `Commandes.generer` tire les exigences des goûts de la cliente.
- **Sauvegarde** v3 : fiches des clientes, prestige, livraisons, visites ; migration v2 → v3.
- **Interface** : `EcranMesures` (silhouette et rubans) ; la cliente en personne porte sa tenue et son nom, et parle avec ses mots ; le carnet, la présentation, le refus et l'accueil nomment la cliente, l'ajustement, l'amitié et le prestige.

**Tech Stack:** Luau, Rojo 7.7.0-rc.1, simulation Luau 0.650 (`tests/lancer.sh`), Roblox Studio via le connecteur MCP Studio.

**Spec:** `docs/superpowers/specs/2026-09-29-clientes-progression-design.md` (§2 les clientes, §3 la prise de mesures, §4 prestige (points et niveaux seulement), §8 serveur et sauvegarde, §9 interface, §11 découpage : plan 5a). Sous-projet précédent : `docs/superpowers/specs/2026-09-28-atelier-coeur-design.md`.

## Décisions de ce plan

- **Les six clientes** (spec §2) : contenu original (noms, tenues, répliques). Mesures réelles à 0,1 à 0,3 dm de leur taille. Quatre répliques chacune : **présentation** (première visite, aux mesures), **arrivée** (visites suivantes, et au carnet), **merci**, **déception** (robe refusée) ; l'abandon garde la phrase commune.
- **Qui vient** (spec §2) : `Clientes.prochaine(fiches, niveauPrestige)` : la première de la liste jamais venue dont le prestige est atteint ; sinon celle dont la dernière visite est la plus ancienne. Les trois premières (prestige 1) viennent donc aux trois premières commandes.
- **Mesures** (spec §3) : l'étape « mesures » a lieu **à chaque commande d'une cliente** ; à son retour, « Reprendre ses mesures » (un clic) passe directement au carnet, ou on la mesure de nouveau avec les rubans (c'est le « Mesurer de nouveau » de la spec : pas de bouton de plus). Rubans : départ à 70 % de la mesure de sa taille, pas de 0,1 dm, bornés entre 2 et 15 dm. Le serveur refuse un ruban à plus de 1,5 dm de la vraie mesure (« Mesure invalide : règle chaque ruban au bord de la silhouette. »).
- **Silhouette** : dessinée de face, en code ; chaque bande (poitrine, taille, hanches) est large de `mesure × 0,32 × 70 px` (un tour vu de face), et chaque ruban part de son bord gauche : un ruban juste s'arrête pile au bord droit.
- **Ajustement** (spec §3) : `clamp(1 − Σ max(0, |prise − vraie| − 0,2) / 1,5 ; 0,5 ; 1)`. La qualité jugée (exigences, paie) est celle de `EtatAtelier:bilan()`, multipliée par l'ajustement ; la présentation affiche « Qualité de la robe : 87 % (ajustement 96 %) ».
- **Amitié** (spec §2) : +2 pour une robe acceptée, +1 de plus à 80 % de qualité, −1 pour un abandon (jamais sous 0) ; niveaux 0 à 5. Ce que les niveaux ouvrent arrive au plan 5b.
- **Prestige** (spec §4) : ce plan compte seulement les points d'une livraison (paie / 10, arrondi) et le niveau (1 à 8). Déblocages, commandes plus exigeantes et catalogue débloqué : plan 5b.
- **Commandes** : celle d'une cliente tire son style « au moins » dans ses styles, un « au plus » hors de ses styles, et sa teinte ; elle n'a pas de mesures tant qu'on ne les a pas prises. Une commande anonyme (sans cliente) reste possible pour les tests.
- **Tests existants** : la plupart commencent au carnet ; `U.commander(x, …)` passe la commande et prend les mesures exactes de la cliente (31 appels réécrits).
- **Sauvegarde v3** (spec §8) : `prestige`, `livraisons`, `visites`, `clientes` (`[id] = { amitie, vues, derniere, mesures?, ajustement? }` ; `derniere` est le `derniereVisite` de la spec : le numéro de la visite, comparé à `visites`). Les lettres (`lettres`) arrivent au plan 5d. Migration v2 → v3 : prestige = 20 × robes gardées, livraisons = robes gardées. Une fiche abîmée est réparée (nombres remis à zéro, mesures impossibles oubliées), une cliente inconnue est laissée ; une commande d'une cliente inconnue, ou au carnet sans mesures, est abandonnée.
- **Laissé pour les plans suivants** : lettres (+1 d'amitié, plan 5d), cadeau (plan 5c), carnet d'adresses (plan 5d), jauge de prestige à l'accueil et déblocages (plan 5b).
- **Vérifié pendant la préparation** : le plan a été joué entièrement sur un brouillon tiré de `main` ; huit variantes du brouillon (second doigt, doigt levé, présentation, annonce, ajustement, nom, plancher de l'amitié, migration) échouent chacune sur la vérification qui les garde.

## Global Constraints

- **Dépôt** : `C:\dev\jeux\atelier-couture`, branche `clientes`, créée depuis `main` (où le sous-projet 1 est fusionné). Selon les règles du commanditaire : la branche testée et relue est fusionnée dans `main` et poussée sur GitHub.
- **Rojo** : `C:/dev/jeux/roblox-maker/rojo.exe`.
- **Contraintes des plans précédents toujours valables** : fins de ligne LF, commits en français terminés par `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`, textes d'au moins 14 px, le serveur fait foi.
- **Contenu original** (spec §1) : aucun nom, texte, son ni image de Dressmaker.
- **Commandes** (spec §4 du sous-projet 1) : tout se joue d'un seul doigt ou à la souris seule.

## Review Focus

- **Ruban tiré au doigt, avec un second doigt sur l'écran.** Attendu : seul le doigt qui tient la poignée règle le ruban, et plus rien ne bouge une fois levé. Tests : scénario, « un second doigt ne tire pas le ruban », « glisser la poignée au doigt jusqu'au bord de la silhouette : la mesure juste », « doigt levé : le ruban ne bouge plus ».
- **Mesures farfelues envoyées au serveur** (texte, 99 dm, NaN). Attendu : refus, l'étape reste « mesures ». Test : `28_commande_serveur`, « mesures farfelues refusées par le serveur ».
- **Joueur existant (partie v2 avec des robes).** Attendu : son travail passé compte en prestige, aucune cliente connue. Test : `43_sauvegarde_clientes`, « v2 → v3 : prestige des robes passées, aucune cliente ».
- **Fiche de cliente abîmée dans le DataStore.** Attendu : réparée ou laissée, jamais d'erreur. Tests : `43_sauvegarde_clientes`, « fiche abîmée : nombres remis à zéro, mesures impossibles oubliées », « cliente inconnue ou fiche illisible : laissée ».
- **Joueur qui part pendant les mesures.** Attendu : à son retour, la commande reprend aux mesures. Test : scénario, « retour suivant : la commande reprend ».

## Structure des fichiers

| Fichier | Rôle |
|---|---|
| `src/shared/Clientes.luau` | **Nouveau** : les six clientes ; qui vient à la clochette |
| `src/shared/Progression.luau` | **Nouveau** : seuils et gains d'amitié et de prestige |
| `src/shared/EtatAtelier.luau` | Étape « mesures », `mesurer`, `reprendreMesures`, `bilan`, amitié et prestige ; nouveaux champs |
| `src/shared/Notation.luau` | `ajustement` |
| `src/shared/Commandes.luau` | Commandes d'après les goûts de la cliente |
| `src/server/Sauvegarde.luau` | Partie v3, migration, fiches relues avec soin |
| `src/server/Commande.luau`, `src/client/Atelier/Session.luau` | Actions `mesurer`, `reprendreMesures` |
| `src/client/Atelier/EcranMesures.luau` | **Nouveau** : silhouette, rubans, « Valider les mesures », « Reprendre ses mesures » |
| `src/client/Atelier/init.client.luau` | Écran et titre des mesures |
| `src/client/Atelier/Cliente.luau`, `Scene.luau` | Tenue et nom de la cliente ; ses répliques |
| `src/client/Atelier/EcranCarnet.luau`, `EcranPresentation.luau`, `EcranRefus.luau`, `EcranAccueil.luau` | Nom de la cliente, ajustement, amitié et prestige |
| `tests/build.py` | `U.commander` |
| `tests/unitaires/42_clientes.luau`, `43_sauvegarde_clientes.luau`, `44_mesures.luau` | **Nouveaux** |
| `tests/unitaires/14…39`, `tests/scenario.luau` | Tests passés par les mesures ; cliente nommée |
| `README.md`, `AtelierCouture.rbxl` | État du jeu ; lieu régénéré |

---

### Task 1: Les six clientes et la progression

**Files:**
- Create: `src/shared/Clientes.luau`
- Create: `src/shared/Progression.luau`
- Create: `tests/unitaires/42_clientes.luau`

**Interfaces:**
- Consumes: `Catalogue.TAILLES`, `Catalogue.STYLES`, `Catalogue.Tissus`, `Catalogue.Variantes`, `Catalogue.Accessoires` (sous-projet 1), `Recette.POITRINE`, `Recette.TAILLE`, `Recette.HANCHES` (bornes).
- Produces:
  - `Clientes.LISTE` : `{ id, nom, taille, mesures = { poitrine, taille, hanches }, styles = { s1, s2 }, teinte, prestige, tenue = { peau, haut, bas, cheveux }, deblocages = { [2] = …, [4] = … }, repliques = { presentation, arrivee, merci, deception } }` ;
  - `Clientes.get(id)` → fiche ou `nil` ; `Clientes.prochaine(fiches, niveauPrestige)` → id ;
  - `Progression.SEUILS_AMITIE`, `SEUILS_PRESTIGE`, `QUALITE_BONUS` ; `niveauAmitie(points)` (0 à 5), `niveauPrestige(points)` (1 à 8), `gainAmitie(reussie, qualite)`, `prestigeLivraison(paie)`.

- [ ] **Step 1: Écrire les tests**

Créer `tests/unitaires/42_clientes.luau` :

```lua
local Clientes = U.module("Clientes")
local Progression = U.module("Progression")
local Catalogue = U.module("Catalogue")
local Recette = U.module("Recette")

---------------------------------------------------------------------------
-- Les six clientes : des données valides, des mesures proches de leur taille
---------------------------------------------------------------------------
U.verifier(#Clientes.LISTE == 6, "six clientes")
local vus = {}
for _, c in ipairs(Clientes.LISTE) do
	U.verifier(not vus[c.id] and Clientes.get(c.id) == c, "identifiant unique : " .. c.id)
	vus[c.id] = true
	local m, t = c.mesures, Catalogue.TAILLES[c.taille]
	U.verifier(t ~= nil and m.poitrine >= Recette.POITRINE[1] and m.poitrine <= Recette.POITRINE[2] and m.taille >= Recette.TAILLE[1] and m.hanches <= Recette.HANCHES[2] and m.taille < m.poitrine and m.taille < m.hanches, c.id .. " : mesures possibles pour une recette")
	U.verifier(math.abs(m.poitrine - t.poitrine) <= 0.3 and math.abs(m.taille - t.taille) <= 0.3 and math.abs(m.hanches - t.hanches) <= 0.3, c.id .. " : mesures proches de la taille " .. c.taille)
	U.verifier(#c.styles == 2 and table.find(Catalogue.STYLES, c.styles[1]) and table.find(Catalogue.STYLES, c.styles[2]) and table.find(Catalogue.TEINTES, c.teinte), c.id .. " : styles et teinte du catalogue")
	for niveau, d in pairs(c.deblocages) do
		U.verifier((niveau == 2 or niveau == 4) and ((d.variante and Catalogue.variante(d.variante)) or (d.accessoire and Catalogue.accessoire(d.accessoire))), c.id .. " : ce que l'amitié ouvre existe")
	end
	for _, cle in ipairs({ "presentation", "arrivee", "merci", "deception" }) do
		U.verifier(type(c.repliques[cle]) == "string" and #c.repliques[cle] > 0, c.id .. " : réplique « " .. cle .. " »")
	end
end
U.verifier(Clientes.get("inconnue") == nil, "cliente inconnue : rien")

---------------------------------------------------------------------------
-- Qui vient à la clochette
---------------------------------------------------------------------------
local fiches = {}
U.verifier(Clientes.prochaine(fiches, 1) == "colette", "première commande : Colette")
fiches.colette = { vues = 1, derniere = 1 }
U.verifier(Clientes.prochaine(fiches, 1) == "margot", "deuxième : Margot")
fiches.margot = { vues = 1, derniere = 2 }
U.verifier(Clientes.prochaine(fiches, 1) == "salome", "troisième : Salomé")
fiches.salome = { vues = 1, derniere = 3 }
U.verifier(Clientes.prochaine(fiches, 1) == "colette", "ensuite, celle qu'on n'a pas vue depuis le plus longtemps")
fiches.colette.derniere = 4
U.verifier(Clientes.prochaine(fiches, 1) == "margot", "… puis la suivante")
U.verifier(Clientes.prochaine(fiches, 2) == "helene", "prestige 2 : Hélène, nouvelle venue, passe avant les autres")
U.verifier(Clientes.prochaine(fiches, 8) == "helene", "plusieurs nouvelles venues possibles : dans l'ordre de la liste")

---------------------------------------------------------------------------
-- Niveaux d'amitié et de prestige, gains
---------------------------------------------------------------------------
U.verifier(Progression.niveauAmitie(0) == 0 and Progression.niveauAmitie(2) == 0 and Progression.niveauAmitie(3) == 1 and Progression.niveauAmitie(24) == 4 and Progression.niveauAmitie(25) == 5 and Progression.niveauAmitie(100) == 5, "niveaux d'amitié 0 à 5")
U.verifier(Progression.niveauPrestige(0) == 1 and Progression.niveauPrestige(19) == 1 and Progression.niveauPrestige(20) == 2 and Progression.niveauPrestige(530) == 8 and Progression.niveauPrestige(9999) == 8, "niveaux de prestige 1 à 8")
U.verifier(Progression.gainAmitie(true, 0.79) == 2 and Progression.gainAmitie(true, 0.8) == 3 and Progression.gainAmitie(false, 1) == -1, "amitié : +2, +1 pour une belle robe, −1 pour un abandon")
U.verifier(Progression.prestigeLivraison(124) == 12 and Progression.prestigeLivraison(125) == 13, "prestige : un dixième de la paie, arrondi")
```

- [ ] **Step 2: Lancer les tests, vérifier l'échec**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT|attempt|membre" | head -3`
Expected: échec : une ligne qui finit par `Clientes n'est pas un membre valide de Folder « Couture »` (le module n'existe pas encore)

- [ ] **Step 3: Écrire les modules**

Créer `src/shared/Clientes.luau` :

```lua
-- Clientes : les six clientes qui reviennent à l'atelier (contenu original, rien de Dressmaker). Chacune a ses
-- vraies mesures (dm, proches de sa taille), ses styles et sa teinte préférés (ses commandes en viennent), sa
-- tenue, ses répliques, le prestige qu'il faut pour qu'elle vienne, et ce que son amitié ouvre (sous-projet 2).
-- Données, et une règle pure : qui vient à la clochette.

local Clientes = {}

local function rgb(r, g, b)
	return Color3.fromRGB(r, g, b)
end

Clientes.LISTE = {
	{
		id = "colette",
		nom = "Colette Marchand",
		taille = "M",
		mesures = { poitrine = 8.9, taille = 7.1, hanches = 9.5 },
		styles = { "romantique", "mignon" },
		teinte = "rose",
		prestige = 1,
		tenue = { peau = rgb(238, 200, 170), haut = rgb(240, 150, 180), bas = rgb(250, 240, 245), cheveux = rgb(150, 80, 50) },
		deblocages = { [2] = { variante = "jupe_ample" }, [4] = { accessoire = "dentelle_blanche" } },
		repliques = {
			presentation = "Bonjour ! Je suis Colette. On m'a dit que vous faisiez des merveilles.",
			arrivee = "Me revoilà ! J'ai encore besoin de vos doigts de fée.",
			merci = "Elle est ravissante, merci mille fois !",
			deception = "Oh… ce n'est pas tout à fait ce que j'imaginais.",
		},
	},
	{
		id = "margot",
		nom = "Margot Petit",
		taille = "S",
		mesures = { poitrine = 8.1, taille = 6.3, hanches = 8.9 },
		styles = { "mignon", "decontracte" },
		teinte = "jaune",
		prestige = 1,
		tenue = { peau = rgb(250, 214, 180), haut = rgb(250, 210, 80), bas = rgb(120, 180, 220), cheveux = rgb(230, 190, 110) },
		deblocages = { [2] = { accessoire = "noeud_satin" }, [4] = { accessoire = "etoile_brodee" } },
		repliques = {
			presentation = "Coucou ! Moi, c'est Margot. Il me faut une robe toute mignonne !",
			arrivee = "Coucou ! J'ai une nouvelle idée de robe !",
			merci = "Trop jolie ! Je l'adore !",
			deception = "Hum… pas vraiment mon style.",
		},
	},
	{
		id = "salome",
		nom = "Salomé Garnier",
		taille = "L",
		mesures = { poitrine = 9.7, taille = 7.9, hanches = 10.1 },
		styles = { "decontracte", "chic" },
		teinte = "vert",
		prestige = 1,
		tenue = { peau = rgb(170, 120, 90), haut = rgb(110, 160, 110), bas = rgb(200, 180, 150), cheveux = rgb(40, 30, 25) },
		deblocages = { [2] = { variante = "corsage_bretelles" }, [4] = { accessoire = "galon_dore" } },
		repliques = {
			presentation = "Salut ! Salomé. Une robe simple et pratique, c'est possible ?",
			arrivee = "Salut ! Je repasse pour une autre robe.",
			merci = "Parfait, je vais la porter tout l'été.",
			deception = "C'est un peu trop pour moi.",
		},
	},
	{
		id = "helene",
		nom = "Hélène Duval",
		taille = "M",
		mesures = { poitrine = 8.7, taille = 6.8, hanches = 9.3 },
		styles = { "elegant", "chic" },
		teinte = "blanc",
		prestige = 2,
		tenue = { peau = rgb(230, 195, 165), haut = rgb(245, 240, 230), bas = rgb(60, 60, 80), cheveux = rgb(60, 40, 30) },
		deblocages = { [2] = { variante = "col_montant" }, [4] = { accessoire = "broche_camee" } },
		repliques = {
			presentation = "Bonsoir. Hélène Duval. On dit votre atelier prometteur.",
			arrivee = "Bonsoir. J'ai une nouvelle soirée en vue.",
			merci = "Remarquable. Vous avez du talent.",
			deception = "Ce n'est pas à la hauteur, je le crains.",
		},
	},
	{
		id = "ines",
		nom = "Inès Lebrun",
		taille = "S",
		mesures = { poitrine = 8.3, taille = 6.5, hanches = 8.7 },
		styles = { "gothique", "elegant" },
		teinte = "noir",
		prestige = 3,
		tenue = { peau = rgb(240, 220, 205), haut = rgb(30, 25, 35), bas = rgb(90, 40, 90), cheveux = rgb(20, 15, 20) },
		deblocages = { [2] = { variante = "manches_longues" }, [4] = { accessoire = "croix_argent" } },
		repliques = {
			presentation = "… Bonjour. Inès. Du noir, si possible.",
			arrivee = "… Encore moi. Toujours du noir.",
			merci = "Elle est parfaite. Sombre à souhait.",
			deception = "Trop gaie. Beaucoup trop gaie.",
		},
	},
	{
		id = "victoire",
		nom = "Victoire Aubry",
		taille = "L",
		mesures = { poitrine = 9.5, taille = 7.7, hanches = 10.3 },
		styles = { "chic", "elegant" },
		teinte = "bleu",
		prestige = 4,
		tenue = { peau = rgb(120, 80, 60), haut = rgb(60, 90, 170), bas = rgb(230, 230, 235), cheveux = rgb(25, 20, 20) },
		deblocages = { [2] = { variante = "jupe_evasee" }, [4] = { accessoire = "noeud_velours" } },
		repliques = {
			presentation = "Bonjour ! Victoire Aubry. On m'a dit le plus grand bien de vous.",
			arrivee = "Bonjour ! Je reviens vous confier une robe.",
			merci = "Exactement ce qu'il me fallait. Bravo.",
			deception = "Je m'attendais à mieux, franchement.",
		},
	},
}

local parId = {}
for rang, c in ipairs(Clientes.LISTE) do
	c.rang = rang
	parId[c.id] = c
end

-- La fiche de cliente d'id donné, ou nil
function Clientes.get(id)
	return parId[id]
end

-- La cliente qui vient à la clochette. fiches : { [id] = { vues, derniere } } (visites passées) ;
-- niveauPrestige : le niveau du joueur. Une cliente jamais venue, dont le prestige est atteint, passe avant
-- les autres (dans l'ordre de la liste : les trois premières commandes présentent Colette, Margot, Salomé) ;
-- sinon vient celle qu'on n'a pas vue depuis le plus longtemps.
function Clientes.prochaine(fiches, niveauPrestige)
	for _, c in ipairs(Clientes.LISTE) do
		local f = fiches[c.id]
		if (not f or f.vues == 0) and niveauPrestige >= c.prestige then
			return c.id
		end
	end
	local choisie, plusVieille = nil, math.huge
	for _, c in ipairs(Clientes.LISTE) do
		local f = fiches[c.id]
		if f and f.vues > 0 and f.derniere < plusVieille then
			choisie, plusVieille = c.id, f.derniere
		end
	end
	return choisie or Clientes.LISTE[1].id
end

return Clientes
```

Créer `src/shared/Progression.luau` :

```lua
-- Progression : l'amitié de chaque cliente et le prestige du joueur (sous-projet 2) : seuils, niveaux, gains.
local Progression = {}

Progression.SEUILS_AMITIE = { 0, 3, 7, 12, 18, 25 } -- points pour les niveaux d'amitié 0 à 5
Progression.SEUILS_PRESTIGE = { 0, 20, 50, 100, 170, 260, 380, 530 } -- points pour les niveaux de prestige 1 à 8
Progression.QUALITE_BONUS = 0.8 -- une robe au moins aussi bonne vaut un point d'amitié de plus

-- Le niveau atteint avec ces points (seuils croissants ; le premier seuil donne le niveau « premier »)
local function niveau(points, seuils, premier)
	local n = premier
	for i, seuil in ipairs(seuils) do
		if points >= seuil then
			n = premier + i - 1
		end
	end
	return n
end

function Progression.niveauAmitie(points)
	return niveau(points, Progression.SEUILS_AMITIE, 0)
end

function Progression.niveauPrestige(points)
	return niveau(points, Progression.SEUILS_PRESTIGE, 1)
end

-- Points d'amitié d'une commande : robe acceptée +2 (+1 si sa qualité atteint 80 %), abandonnée −1
function Progression.gainAmitie(reussie, qualite)
	if reussie then
		return 2 + (qualite >= Progression.QUALITE_BONUS and 1 or 0)
	end
	return -1
end

-- Points de prestige d'une robe livrée et payée
function Progression.prestigeLivraison(paie)
	return math.round(paie / 10)
end

return Progression
```

- [ ] **Step 4: Lancer les tests**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT"`
Expected:
```
Unitaires : 105172 vérifications
TOUT EST VERT : 417 vérifications
```

- [ ] **Step 5: Commit**

```bash
git add src/shared/Clientes.luau src/shared/Progression.luau tests/unitaires/42_clientes.luau
git commit -m "Clientes : les six clientes (mesures, tenue, goûts, répliques) et qui vient à la clochette ; amitié et prestige

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 2: L'état de l'atelier et la sauvegarde v3

**Files:**
- Modify: `src/shared/EtatAtelier.luau` (étapes, champs, `CHAMPS`)
- Modify: `src/server/Sauvegarde.luau` (version 3, migration, lecture des fiches)
- Create: `tests/unitaires/43_sauvegarde_clientes.luau`

**Interfaces:**
- Consumes: `Clientes.get` (tâche 1).
- Produces:
  - `EtatAtelier.ETAPES` commence par `"accueil", "mesures", "carnet"` ;
  - champs de l'état (exportés, donc aussi dans la copie du client) : `clientes` (`[id] = { amitie, vues, derniere, mesures?, ajustement? }`), `prestige`, `livraisons`, `visites` ;
  - `Sauvegarde.VERSION = 3` ; `MIGRATIONS[2]` ; `versEtat` relit les fiches ; `commandeLisible(c, etape)` accepte une commande sans mesures à l'étape « mesures ».

- [ ] **Step 1: Écrire les tests**

Créer `tests/unitaires/43_sauvegarde_clientes.luau` :

```lua
local Sauvegarde = U.module("Sauvegarde")
local EtatAtelier = U.module("EtatAtelier")
local Clientes = U.module("Clientes")

---------------------------------------------------------------------------
-- L'état de l'atelier garde les fiches des clientes, le prestige, les livraisons et les visites
---------------------------------------------------------------------------
local e = EtatAtelier.nouveau()
U.verifier(type(e.clientes) == "table" and next(e.clientes) == nil and e.prestige == 0 and e.livraisons == 0 and e.visites == 0, "départ : aucune cliente, prestige 0, rien livré")
e.clientes.colette = { amitie = 5, vues = 2, derniere = 3, mesures = { poitrine = 9, taille = 7.1, hanches = 9.5 }, ajustement = 0.95 }
e.prestige, e.livraisons, e.visites = 42, 2, 3
local copie = EtatAtelier.nouveau():charger(e:exporter())
U.verifier(copie.clientes.colette.amitie == 5 and copie.clientes.colette.mesures.poitrine == 9 and copie.prestige == 42 and copie.livraisons == 2 and copie.visites == 3, "copie de l'état (client) : fiches et prestige compris")

---------------------------------------------------------------------------
-- Sauvegarde v3 : relue à l'identique
---------------------------------------------------------------------------
U.verifier(Sauvegarde.VERSION == 3, "format v3")
local partie = Sauvegarde.depuisEtat(e)
U.verifier(partie.prestige == 42 and partie.livraisons == 2 and partie.visites == 3 and partie.clientes.colette.amitie == 5, "partie : prestige, livraisons, visites, fiches")
local relue = Sauvegarde.versEtat(M.transmettre(partie))
local f = relue.clientes.colette
U.verifier(relue.prestige == 42 and relue.livraisons == 2 and relue.visites == 3 and f.amitie == 5 and f.vues == 2 and f.derniere == 3 and f.mesures.hanches == 9.5 and f.ajustement == 0.95, "relue : prestige, livraisons, visites et fiche de Colette")

---------------------------------------------------------------------------
-- Fiches abîmées : ce qui est illisible est laissé de côté
---------------------------------------------------------------------------
partie.clientes = {
	colette = { amitie = -4, vues = "deux", derniere = 0 / 0, mesures = { poitrine = 30, taille = 7, hanches = 9 }, ajustement = 3 },
	inconnue = { amitie = 99 },
	margot = "abîmée",
	salome = { amitie = 7.6, vues = 1, derniere = 2, mesures = { poitrine = 9.7, taille = 7.9, hanches = 10.1 }, ajustement = 0.2 },
}
partie.prestige, partie.livraisons, partie.visites = "beaucoup", -3, 2.5
relue = Sauvegarde.versEtat(partie)
local c = relue.clientes.colette
U.verifier(c ~= nil and c.amitie == 0 and c.vues == 0 and c.derniere == 0 and c.mesures == nil and c.ajustement == nil, "fiche abîmée : nombres remis à zéro, mesures impossibles oubliées")
U.verifier(relue.clientes.inconnue == nil and relue.clientes.margot == nil, "cliente inconnue ou fiche illisible : laissée")
local s = relue.clientes.salome
U.verifier(s.amitie == 7 and s.mesures.poitrine == 9.7 and s.ajustement == 0.5, "fiche de Salomé : amitié entière, ajustement borné")
U.verifier(relue.prestige == 0 and relue.livraisons == 0 and relue.visites == 2, "prestige, livraisons et visites illisibles : 0 (entiers positifs)")

---------------------------------------------------------------------------
-- Migration v2 → v3 : le travail passé compte (20 points de prestige par robe gardée)
---------------------------------------------------------------------------
local v2 = { version = 2, argent = 300, stock = {}, debloques = {}, recettes = { {}, {}, {} } }
local v3 = Sauvegarde.migrer(v2)
U.verifier(v3.version == 3 and v3.prestige == 60 and v3.livraisons == 3 and v3.visites == 0 and next(v3.clientes) == nil and v3.argent == 300, "v2 → v3 : prestige des robes passées, aucune cliente")
U.verifier(Sauvegarde.migrer({ argent = 480 }).version == 3, "v1 → v3 : les migrations s'enchaînent")

---------------------------------------------------------------------------
-- Une commande à l'étape des mesures (pas encore de mesures) se relit ; une cliente inconnue non
---------------------------------------------------------------------------
local enAttente = EtatAtelier.nouveau()
enAttente.commande = { cliente = "colette", taille = "M", exigences = { { type = "min", style = "romantique", valeur = 30 } } }
enAttente.etape = "mesures"
enAttente.clientes.colette = { amitie = 0, vues = 1, derniere = 1 }
local p2 = Sauvegarde.depuisEtat(enAttente)
local relue2 = Sauvegarde.versEtat(M.transmettre(p2))
U.verifier(relue2.etape == "mesures" and relue2.commande.cliente == "colette" and relue2.commande.mesures == nil, "commande à mesurer : relue telle quelle")
p2.enCours.commande.cliente = "inconnue"
U.verifier(Sauvegarde.versEtat(p2).etape == "accueil", "commande d'une cliente inconnue : abandonnée")
local p3 = Sauvegarde.depuisEtat(enAttente)
p3.enCours.etape = "carnet" -- au carnet, sans mesures : impossible à jouer
U.verifier(Sauvegarde.versEtat(p3).etape == "accueil", "commande au carnet sans mesures : abandonnée")
U.verifier(Clientes.get("colette") ~= nil, "(la cliente existe)")
```

- [ ] **Step 2: Lancer les tests, vérifier l'échec**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT|attempt|membre" | head -3`
Expected: échec : une ligne qui finit par `ÉCHEC : départ : aucune cliente, prestige 0, rien livré`

- [ ] **Step 3: Écrire le code**

Dans `src/shared/EtatAtelier.luau`, remplacer :

```lua
EtatAtelier.ETAPES = { "accueil", "carnet", "achat", "decoupe", "epinglage", "couture", "decorations", "photo", "refus" }
```

par :

```lua
EtatAtelier.ETAPES = { "accueil", "mesures", "carnet", "achat", "decoupe", "epinglage", "couture", "decorations", "photo", "refus" }
```

Dans `src/shared/EtatAtelier.luau`, remplacer :

```lua
		accessoires = {}, -- décorations posées, au format de la recette
		robes = {}, -- recettes des robes livrées, la plus récente en premier
	}, EtatAtelier)
```

par :

```lua
		accessoires = {}, -- décorations posées, au format de la recette
		robes = {}, -- recettes des robes livrées, la plus récente en premier
		-- Sous-projet 2 : fiche de chaque cliente venue ([id] = { amitie, vues, derniere, mesures?, ajustement? }),
		-- points de prestige, robes livrées, visites (numéro de la dernière, pour savoir qui revient)
		clientes = {},
		prestige = 0,
		livraisons = 0,
		visites = 0,
	}, EtatAtelier)
```

Dans `src/shared/EtatAtelier.luau`, remplacer :

```lua
local CHAMPS = { "argent", "stock", "etape", "commande", "croquis", "tissus", "coupees", "epinglees", "coutures", "accessoires", "robes" }
```

par :

```lua
local CHAMPS = { "argent", "stock", "etape", "commande", "croquis", "tissus", "coupees", "epinglees", "coutures", "accessoires", "robes", "clientes", "prestige", "livraisons", "visites" }
```

Dans `src/server/Sauvegarde.luau`, remplacer :

```lua
local EtatAtelier = require(Couture:WaitForChild("EtatAtelier"))
```

par :

```lua
local EtatAtelier = require(Couture:WaitForChild("EtatAtelier"))
local Clientes = require(Couture:WaitForChild("Clientes"))
```

Dans `src/server/Sauvegarde.luau`, remplacer :

```lua
Sauvegarde.VERSION = 2
```

par :

```lua
Sauvegarde.VERSION = 3
```

Dans `src/server/Sauvegarde.luau`, remplacer :

```lua
-- Une commande sauvegardée qu'on peut jouer jusqu'au bout : taille connue, mesures dans les bornes d'une
-- recette, 1 à 3 exigences lisibles
local function commandeLisible(c)
	if type(c) ~= "table" or type(c.taille) ~= "string" or not Catalogue.TAILLES[c.taille] then
		return false
	end
	local m = c.mesures
	local function borne(v, bornes)
		return nombre(v, nil) ~= nil and v >= bornes[1] and v <= bornes[2]
	end
	if type(m) ~= "table" or not borne(m.poitrine, Recette.POITRINE) or not borne(m.taille, Recette.TAILLE) or not borne(m.hanches, Recette.HANCHES) then
		return false
	end
```

par :

```lua
-- Des mesures (dm) dans les bornes d'une recette
local function mesuresLisibles(m)
	local function borne(v, bornes)
		return nombre(v, nil) ~= nil and v >= bornes[1] and v <= bornes[2]
	end
	return type(m) == "table" and borne(m.poitrine, Recette.POITRINE) and borne(m.taille, Recette.TAILLE) and borne(m.hanches, Recette.HANCHES)
end

-- Une commande sauvegardée qu'on peut jouer jusqu'au bout : taille et cliente connues, mesures dans les bornes
-- d'une recette (sauf à l'étape des mesures, où elles ne sont pas encore prises), 1 à 3 exigences lisibles
local function commandeLisible(c, etape)
	if type(c) ~= "table" or type(c.taille) ~= "string" or not Catalogue.TAILLES[c.taille] then
		return false
	end
	if c.cliente ~= nil and not Clientes.get(c.cliente) then
		return false
	end
	if not (etape == "mesures" and c.mesures == nil) and not mesuresLisibles(c.mesures) then
		return false
	end
```

Dans `src/server/Sauvegarde.luau`, remplacer :

```lua
			recettes = {},
		}
	end,
```

par :

```lua
			recettes = {},
		}
	end,
	-- v2 → v3 (sous-projet 2) : fiches des clientes, prestige ; le travail passé compte (20 points par robe gardée)
	[2] = function(v2)
		local robes = type(v2.recettes) == "table" and #v2.recettes or 0
		v2.version = 3
		v2.prestige = 20 * robes
		v2.livraisons = robes
		v2.visites = 0
		v2.clientes = {}
		return v2
	end,
```

Dans `src/server/Sauvegarde.luau`, remplacer :

```lua
		debloques = copie(debloques) or { tissus = {}, variantes = {}, accessoires = {} },
		recettes = d.robes,
	}
```

par :

```lua
		debloques = copie(debloques) or { tissus = {}, variantes = {}, accessoires = {} },
		recettes = d.robes,
		clientes = d.clientes,
		prestige = d.prestige,
		livraisons = d.livraisons,
		visites = d.visites,
	}
```

Dans `src/server/Sauvegarde.luau`, remplacer :

```lua
function Sauvegarde.versEtat(partie)
	local base = EtatAtelier.nouveau(math.max(0, nombre(partie.argent, EtatAtelier.ARGENT_DEPART)))
```

par :

```lua
function Sauvegarde.versEtat(partie)
	local base = EtatAtelier.nouveau(math.max(0, nombre(partie.argent, EtatAtelier.ARGENT_DEPART)))
	local function entier(v)
		return math.max(0, math.floor(nombre(v, 0)))
	end
	base.prestige, base.livraisons, base.visites = entier(partie.prestige), entier(partie.livraisons), entier(partie.visites)
	-- Fiches des clientes : clientes connues seulement ; des mesures impossibles sont oubliées (on remesurera)
	for id, f in pairs(type(partie.clientes) == "table" and partie.clientes or {}) do
		if type(id) == "string" and Clientes.get(id) and type(f) == "table" then
			local mesures = mesuresLisibles(f.mesures) and copie(f.mesures) or nil
			base.clientes[id] = {
				amitie = entier(f.amitie),
				vues = entier(f.vues),
				derniere = entier(f.derniere),
				mesures = mesures,
				ajustement = mesures and math.clamp(nombre(f.ajustement, 1), 0.5, 1) or nil,
			}
		end
	end
```

Dans `src/server/Sauvegarde.luau`, remplacer :

```lua
		assert(etat.etape == "accueil" or commandeLisible(etat.commande), "commande illisible")
```

par :

```lua
		assert(etat.etape == "accueil" or commandeLisible(etat.commande, etat.etape), "commande illisible")
```

- [ ] **Step 4: Lancer les tests**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT"`
Expected:
```
Unitaires : 105187 vérifications
TOUT EST VERT : 417 vérifications
```

- [ ] **Step 5: Commit**

```bash
git add src/shared/EtatAtelier.luau src/server/Sauvegarde.luau tests/unitaires/43_sauvegarde_clientes.luau
git commit -m "Partie v3 : fiches des clientes, prestige, livraisons ; migration v2 → v3, fiches abîmées réparées

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 3: La prise de mesures

**Files:**
- Modify: `src/shared/Notation.luau` (`ajustement`)
- Modify: `src/shared/Commandes.luau` (`generer(rng, cliente)`)
- Modify: `src/shared/EtatAtelier.luau` (`nouvelleCommande`, `mesurer`, `reprendreMesures`, `bilan`, `livrer`, `abandonner`, `recommencer`)
- Modify: `src/server/Commande.luau`, `src/client/Atelier/Session.luau` (actions)
- Create: `src/client/Atelier/EcranMesures.luau`
- Modify: `src/client/Atelier/init.client.luau`
- Modify: `tests/build.py` (`U.commander`), `tests/unitaires/06_commandes.luau`, `14…36` (31 appels), `28_…`, `29_…`, `31_…`, `35_…`, `39_…`, `tests/scenario.luau`
- Create: `tests/unitaires/44_mesures.luau`

**Interfaces:**
- Consumes: `Clientes.get`, `Clientes.prochaine`, `Progression.*` (tâche 1) ; champs `clientes`, `prestige`, `livraisons`, `visites` (tâche 2).
- Produces:
  - `EtatAtelier:nouvelleCommande(rng)` → `{ ok, commande, cliente, premiereVisite }`, étape `"mesures"` ;
  - `EtatAtelier:mesurer(prises)` (prises en dm) → `{ ok, ajustement }`, étape `"carnet"` ; refus `"Mesure invalide : règle chaque ruban au bord de la silhouette."` ;
  - `EtatAtelier:reprendreMesures()` → `{ ok, ajustement }` ; refus `"Ses mesures n'ont jamais été prises."` ;
  - `EtatAtelier:bilan()` → le bilan de `Notation.bilan` avec `ajustement`, et la qualité multipliée ;
  - `livrer()` réussi → en plus `amitie = { cliente, gain, points, niveau, niveauAvant }` et `prestige = { gain, points, niveau, niveauAvant }` ; `abandonner()` → `{ ok, amitie }` ;
  - `commande.cliente`, `commande.mesures` (prises), `commande.ajustement` ;
  - `Notation.ajustement(vraies, prises)` ; `Commandes.generer(rng, cliente?)` ;
  - `Session:mesurer(prises)`, `Session:reprendreMesures()` ; actions serveur `mesurer`, `reprendreMesures` ;
  - `EcranMesures` : `Silhouette` (320 × 340 px) avec `Tete`, `Cou`, `Corps_<cle>`, `Ruban_<cle>`, `Poignee_<cle>` ; `Valeur_<cle>`, `Moins_<cle>`, `Plus_<cle>`, `ValiderMesures`, `ReprendreMesures` (cliente déjà mesurée) ;
  - tests : `U.commander(x, …)` (état ou session) passe la commande et prend les mesures exactes.

- [ ] **Step 1: Écrire les tests**

Les tests qui passent une commande puis travaillent au carnet prennent désormais les mesures exactes (une commande refusée, « not … », reste telle quelle).

Appliquer :

```bash
python - <<'EOF'
import pathlib, re
FICHIERS = ["14_etat_atelier", "16_table_decoupe", "18_epinglage_couture", "19_machine_coudre", "20_scene", "21_decorations_livraison", "23_scene_decorations", "26_scene_cliente_photo", "27_etat_exporter", "30_sauvegarde", "36_scene_origine"]
MOTIF = re.compile(r"(?<!not )\b(\w+):nouvelleCommande\(([^()]*(?:\([^()]*\))?)\)")
total = 0
for nom in FICHIERS:
    p = pathlib.Path("tests/unitaires/" + nom + ".luau")
    s = p.read_text(encoding="utf-8")
    s, n = MOTIF.subn(lambda m: "U.commander(" + m.group(1) + (", " + m.group(2) if m.group(2) else "") + ")", s)
    total += n
    p.write_bytes(s.encode("utf-8"))
print("U.commander :", total)
EOF
```

Sortie attendue : `U.commander : 31`.

Dans `tests/build.py`, remplacer :

```python
function U.proche(a, b, tol)
	return math.abs(a - b) <= (tol or 1e-6)
end
```

par :

```python
function U.proche(a, b, tol)
	return math.abs(a - b) <= (tol or 1e-6)
end
-- Passe une commande (état de l'atelier ou session) et prend les mesures exactes de la cliente : la plupart
-- des tests commencent au carnet
function U.commander(x, ...)
	local r = x:nouvelleCommande(...)
	if r.ok then
		local etat = x.etat or x
		x:mesurer(U.module("Clientes").get(etat.commande.cliente).mesures)
	end
	return r
end
```

Dans `tests/unitaires/06_commandes.luau`, remplacer :

```lua
for _, g in ipairs({ "min", "max", "qualite", "teinte", "accessoire" }) do
	U.verifier(genres[g] == true, "le générateur produit des exigences « " .. g .. " »")
end
```

par :

```lua
for _, g in ipairs({ "min", "max", "qualite", "teinte", "accessoire" }) do
	U.verifier(genres[g] == true, "le générateur produit des exigences « " .. g .. " »")
end

-- Commandes d'une cliente (sous-projet 2) : toujours réalisables, tirées de ses goûts ; ses mesures seront prises
local Clientes = U.module("Clientes")
for _, cliente in ipairs(Clientes.LISTE) do
	local rngCliente = Random.new(7)
	for n = 1, 40 do
		local c = Commandes.generer(rngCliente, cliente)
		U.verifier(c.cliente == cliente.id and c.taille == cliente.taille and c.mesures == nil, cliente.id .. " : sa commande, sans mesures (elles seront prises)")
		U.verifier(Commandes.realisable(c.exigences) and #c.exigences >= 1 and #c.exigences <= 3, cliente.id .. " : commande " .. n .. " réalisable")
		U.verifier(c.exigences[1].type == "min" and table.find(cliente.styles, c.exigences[1].style) ~= nil, cliente.id .. " : elle demande un de ses styles")
		for _, e in ipairs(c.exigences) do
			U.verifier(e.type ~= "max" or table.find(cliente.styles, e.style) == nil, cliente.id .. " : jamais « au plus » dans ses styles")
			U.verifier(e.type ~= "teinte" or e.teinte == cliente.teinte, cliente.id .. " : sa teinte")
		end
	end
end
```

Dans `tests/unitaires/29_session_distante.luau`, remplacer :

```lua
local Session = U.module("Session")
```

par :

```lua
local Session = U.module("Session")
local Clientes = U.module("Clientes")
```

Dans `tests/unitaires/29_session_distante.luau`, remplacer :

```lua
U.verifier(session.etat == objet and session.etat.etape == "carnet", "même objet d'état (les écrans le gardent), à jour")
```

par :

```lua
U.verifier(session.etat == objet and session.etat.etape == "mesures", "même objet d'état (les écrans le gardent), à jour")
```

Dans `tests/unitaires/29_session_distante.luau`, remplacer :

```lua
U.verifier(session.derniere.action == "nouvelleCommande" and session.derniere.reponse.ok, "dernière action retenue (accueil, cliente)")
```

par :

```lua
U.verifier(session.derniere.action == "nouvelleCommande" and session.derniere.reponse.ok, "dernière action retenue (accueil, cliente)")
M.avancer(1)
U.verifier(session:mesurer(Clientes.get(session.etat.commande.cliente).mesures).ok and session.etat.etape == "carnet", "mesures prises : au carnet")
```

Dans `tests/unitaires/39_session_resynchro.luau`, remplacer :

```lua
U.verifier(#attentes == 2 and attentes[1] == true and attentes[2] == false, "attente signalée : début, puis fin")
```

par :

```lua
U.verifier(#attentes == 2 and attentes[1] == true and attentes[2] == false, "attente signalée : début, puis fin")
M.avancer(1)
U.verifier(session:mesurer(U.module("Clientes").get(session.etat.commande.cliente).mesures).ok, "mesures prises")
```

Dans `tests/unitaires/39_session_resynchro.luau`, remplacer :

```lua
U.verifier(session.derniere.action == "nouvelleCommande", "la dernière action reste celle du joueur")
```

par :

```lua
U.verifier(session.derniere.action == "mesurer", "la dernière action reste celle du joueur")
```

Dans `tests/unitaires/28_commande_serveur.luau`, remplacer :

```lua
local Patron = U.module("Patron")
```

par :

```lua
local Patron = U.module("Patron")
local Clientes = U.module("Clientes")
```

Dans `tests/unitaires/28_commande_serveur.luau`, remplacer :

```lua
U.verifier(r.ok and r.etat.etape == "carnet" and r.etat.commande ~= nil, "nouvelle commande tirée par le serveur (l'argument du client est ignoré)")
```

par :

```lua
U.verifier(r.ok and r.etat.etape == "mesures" and r.etat.commande ~= nil and r.etat.commande.cliente == "colette", "nouvelle commande tirée par le serveur (l'argument du client est ignoré) : Colette, à mesurer")
for _, prises in ipairs({ "tout", { poitrine = 99, taille = 7.1, hanches = 9.5 }, { poitrine = 8.9, taille = 7.1, hanches = 0 / 0 } }) do
	r = appeler(joueur, "mesurer", prises)
	U.verifier(not r.ok and r.erreur == "Mesure invalide : règle chaque ruban au bord de la silhouette." and etatDe(joueur).etape == "mesures", "mesures farfelues refusées par le serveur")
end
U.verifier(appeler(joueur, "mesurer", Clientes.get("colette").mesures).ok and etatDe(joueur).etape == "carnet", "mesures prises : au carnet")
```

Dans `tests/unitaires/31_commande_sauvegarde.luau`, remplacer :

```lua
-- Une commande jusqu'à la découpe
appeler(s1, fidele, "nouvelleCommande")
```

par :

```lua
-- Une commande jusqu'à la découpe
appeler(s1, fidele, "nouvelleCommande")
appeler(s1, fidele, "mesurer", U.module("Clientes").get(s1:atelier(fidele).etat.commande.cliente).mesures)
```

Dans `tests/unitaires/35_commande_vitrine.luau`, remplacer :

```lua
appeler(serveur, joueur, "nouvelleCommande")
appeler(serveur, joueur, "validerCroquis", CROQUIS, tissus)
```

par :

```lua
appeler(serveur, joueur, "nouvelleCommande")
appeler(serveur, joueur, "mesurer", U.module("Clientes").get(serveur:atelier(joueur).etat.commande.cliente).mesures)
appeler(serveur, joueur, "validerCroquis", CROQUIS, tissus)
```

Dans `tests/scenario.luau`, remplacer :

```lua
verifier(M.dernierAppel ~= nil and M.dernierAppel.action == "nouvelleCommande" and serveur:atelier(joueur).etat.etape == "carnet", "la commande passe par le serveur, qui fait foi")
```

par :

```lua
verifier(M.dernierAppel ~= nil and M.dernierAppel.action == "nouvelleCommande" and serveur:atelier(joueur).etat.etape == "mesures", "la commande passe par le serveur, qui fait foi")
```

Dans `tests/scenario.luau`, remplacer :

```lua
verifier(sonsDepuis(nSons) == "Atelier_clic,Atelier_clochette", "sons : le clic du bouton, puis la clochette (" .. sonsDepuis(nSons) .. ")")

---------------------------------------------------------------------------
-- Carnet de croquis
---------------------------------------------------------------------------
verifier(titre() == "1. Carnet de croquis", "la clochette ouvre le carnet")
```

par :

```lua
verifier(sonsDepuis(nSons) == "Atelier_clic,Atelier_clochette", "sons : le clic du bouton, puis la clochette (" .. sonsDepuis(nSons) .. ")")

---------------------------------------------------------------------------
-- Les mesures : Colette vient pour la première fois ; les rubans partent courts, on les règle au bord de sa
-- silhouette (boutons − et +, au 0,1 dm près)
---------------------------------------------------------------------------
local Clientes = requireModule(dossier.Clientes)
local MESURES = { "poitrine", "taille", "hanches" }
verifier(titre() == "Les mesures" and texte("Colette Marchand") ~= nil, "première visite de Colette : ses mesures")
verifier(fenetre.Contenu:FindFirstChild("ReprendreMesures") == nil, "première visite : rien à reprendre")
verifierTailles("mesures")
cliquer("ValiderMesures")
verifier(titre() == "Les mesures" and fenetre.Message.Visible and fenetre.Message.Text == "Mesure invalide : règle chaque ruban au bord de la silhouette.", "rubans pas réglés : mesures refusées, message")
-- Au doigt : on glisse la poignée du ruban de la poitrine jusqu'au bord de la silhouette ; un second doigt ne
-- tire pas le ruban, et le doigt levé ne le tire plus
local silhouetteM = fenetre.Contenu.Silhouette
local justePoitrine = ("Poitrine : %d cm"):format(math.round(Clientes.get("colette").mesures.poitrine * 10))
local doigtRuban = { UserInputType = Enum.UserInputType.Touch, Position = Vector3.new(0, 0, 0) }
silhouetteM.Poignee_poitrine.InputBegan:Fire(doigtRuban)
local valeurAvant = texte("Valeur_poitrine").Text
M.services.UserInputService.InputChanged:Fire({ UserInputType = Enum.UserInputType.Touch, Position = Vector3.new(900, 0, 0) })
verifier(texte("Valeur_poitrine").Text == valeurAvant, "un second doigt ne tire pas le ruban")
doigtRuban.Position = Vector3.new(silhouetteM.Ruban_poitrine.AbsolutePosition.X + silhouetteM.Corps_poitrine.Size.X.Offset, 0, 0)
M.services.UserInputService.InputChanged:Fire(doigtRuban)
M.services.UserInputService.InputEnded:Fire(doigtRuban)
verifier(texte("Valeur_poitrine").Text == justePoitrine, "glisser la poignée au doigt jusqu'au bord de la silhouette : la mesure juste")
doigtRuban.Position = Vector3.new(0, 0, 0)
M.services.UserInputService.InputChanged:Fire(doigtRuban)
verifier(texte("Valeur_poitrine").Text == justePoitrine, "doigt levé : le ruban ne bouge plus")
local function mesurerCliente()
	local vraies = Clientes.get(serveur:atelier(joueur).etat.commande.cliente).mesures
	for _, cle in ipairs(MESURES) do
		local function lue()
			return tonumber(texte("Valeur_" .. cle).Text:match("(%d+) cm")) / 10
		end
		local garde = 0
		while math.abs(lue() - vraies[cle]) > 0.05 and garde < 80 do
			garde += 1
			cliquer(if lue() < vraies[cle] then "Plus_" .. cle else "Moins_" .. cle)
		end
	end
end
mesurerCliente()
local silhouette = fenetre.Contenu.Silhouette
for _, cle in ipairs(MESURES) do
	local ruban, corps = silhouette["Ruban_" .. cle], silhouette["Corps_" .. cle]
	local finRuban = ruban.Position.X.Offset + ruban.Size.X.Offset
	local bordCorps = corps.Position.X.Offset + corps.Size.X.Offset
	verifier(math.abs(finRuban - bordCorps) <= 2 and ruban.Position.X.Offset == corps.Position.X.Offset, cle .. " : réglé juste, le ruban s'arrête au bord de la silhouette")
end
cliquer("ValiderMesures")
verifier(serveur:atelier(joueur).etat.commande.ajustement == 1 and serveur:atelier(joueur).etat.clientes.colette.mesures ~= nil, "mesures justes : ajustement 100 %, gardées pour la prochaine fois")

---------------------------------------------------------------------------
-- Carnet de croquis
---------------------------------------------------------------------------
verifier(titre() == "1. Carnet de croquis", "mesures prises : le carnet")
```

Dans `tests/scenario.luau`, remplacer :

```lua
verifier(titre() == "1. Carnet de croquis", "nouvelle cliente")
```

par :

```lua
verifier(titre() == "Les mesures" and texte("Margot Petit") ~= nil, "nouvelle cliente : Margot, à mesurer")
mesurerCliente()
cliquer("ValiderMesures")
verifier(titre() == "1. Carnet de croquis", "Margot mesurée : le carnet")
```

Dans `tests/scenario.luau`, remplacer :

```lua
verifier(parties.donnees[cleJoueur].enCours ~= nil and parties.donnees[cleJoueur].enCours.etape == "carnet", "sauvegarde régulière : la commande en cours")
```

par :

```lua
verifier(parties.donnees[cleJoueur].enCours ~= nil and parties.donnees[cleJoueur].enCours.etape == "mesures", "sauvegarde régulière : la commande en cours")
```

Dans `tests/scenario.luau`, remplacer :

```lua
verifier(serveur:atelier(joueur) ~= nil and serveur:atelier(joueur).etat.etape == "carnet", "retour suivant : la commande reprend")
```

par :

```lua
verifier(serveur:atelier(joueur) ~= nil and serveur:atelier(joueur).etat.etape == "mesures", "retour suivant : la commande reprend")
```

Dans `tests/scenario.luau`, remplacer :

```lua
verifier(parties.donnees[cleJoueur].verrou.t == 0 and parties.donnees[cleJoueur].enCours.etape == "carnet", "arrêt du serveur : partie écrite, verrou rendu")
```

par :

```lua
verifier(parties.donnees[cleJoueur].verrou.t == 0 and parties.donnees[cleJoueur].enCours.etape == "mesures", "arrêt du serveur : partie écrite, verrou rendu")
```

Créer `tests/unitaires/44_mesures.luau` :

```lua
local EtatAtelier = U.module("EtatAtelier")
local Clientes = U.module("Clientes")
local Notation = U.module("Notation")
local Patron = U.module("Patron")
local Progression = U.module("Progression")

local CROQUIS = { corsage = "corsage_droit", manches = "manches_sans", col = "col_sans", jupe = "jupe_droite" }
local ORDRE = { "corsage_droit_devant", "corsage_droit_dos", "jupe_droite_devant", "jupe_droite_dos" }
local PLACES = {
	corsage_droit_devant = { x = 2.4, y = 2.1, angle = 0 },
	corsage_droit_dos = { x = 7.2, y = 2.1, angle = 0 },
	jupe_droite_devant = { x = 2.5, y = 7.2, angle = 0 },
	jupe_droite_dos = { x = 7.5, y = 7.2, angle = 0 },
}
-- Une robe menée jusqu'à la photo (coton blanc, coutures parfaites) ; la cliente ne demande qu'une qualité
local function jusquALaPhoto(e)
	local tissus = {}
	for _, id in ipairs(ORDRE) do
		tissus[id] = "coton_blanc"
	end
	e.argent = 1000
	assert(e:validerCroquis(CROQUIS, tissus).ok and e:acheter("coton_blanc", 12).ok and e:commencerDecoupe().ok)
	for _, id in ipairs(ORDRE) do
		assert(e:couper(id, PLACES[id]).ok)
	end
	for _, id in ipairs(ORDRE) do
		assert(e:epingler(id).ok)
	end
	for _, id in ipairs(ORDRE) do
		local _, l = Patron.trajetCouture(id)
		assert(e:rendreCouture(id, table.create(math.round(l / 0.1), 0.02), l).ok)
	end
	assert(e:decorer({}).ok)
	e.commande.exigences = { { type = "qualite", valeur = 0.1 } }
end

---------------------------------------------------------------------------
-- Première commande : Colette, à mesurer avant le carnet
---------------------------------------------------------------------------
local e = EtatAtelier.nouveau()
local colette = Clientes.get("colette")
local r = e:nouvelleCommande(Random.new(3))
U.verifier(r.ok and r.cliente == "colette" and r.premiereVisite == true and e.etape == "mesures", "première commande : Colette, à mesurer")
U.verifier(e.commande.cliente == "colette" and e.commande.taille == colette.taille and e.commande.mesures == nil, "sa commande attend ses mesures")
U.verifier(e.clientes.colette.vues == 1 and e.clientes.colette.derniere == 1 and e.visites == 1, "sa visite est notée")
local styleDemande
for _, x in ipairs(e.commande.exigences) do
	if x.type == "min" then
		styleDemande = x.style
	end
end
U.verifier(table.find(colette.styles, styleDemande) ~= nil, "elle demande un de ses styles (" .. tostring(styleDemande) .. ")")
U.verifier(not e:validerCroquis(CROQUIS, {}).ok, "pas de croquis avant les mesures")
U.verifier(not e:reprendreMesures().ok, "première visite : aucune mesure à reprendre")
U.verifier(not e:recommencer().ok and e.etape == "mesures", "rien à recommencer avant les mesures")

-- Mesures farfelues : refusées
local FARFELUES = {
	"tout",
	{},
	{ poitrine = 0 / 0, taille = 7.1, hanches = 9.5 },
	{ poitrine = 8.9, taille = 7.1 },
	{ poitrine = 8.9 + 1.6, taille = 7.1, hanches = 9.5 }, -- trop loin de la silhouette
	{ poitrine = 8.9, taille = "7", hanches = 9.5 },
}
for k, m in ipairs(FARFELUES) do
	r = e:mesurer(m)
	U.verifier(not r.ok and e.etape == "mesures" and e.commande.mesures == nil, "mesures farfelues refusées (" .. k .. ")")
end

-- Mesure fausse de 0,5 dm à la poitrine : ajustement 80 %
r = e:mesurer({ poitrine = 8.9 + 0.5, taille = 7.1, hanches = 9.5 })
U.verifier(r.ok and e.etape == "carnet" and U.proche(r.ajustement, 0.8) and U.proche(e.commande.mesures.poitrine, 9.4), "mesure fausse de 0,5 dm : ajustement 80 %, le patron suit la mesure prise")
U.verifier(U.proche(e.clientes.colette.mesures.poitrine, 9.4) and U.proche(e.clientes.colette.ajustement, 0.8), "ses mesures et l'ajustement sont gardés pour la prochaine fois")
U.verifier(Notation.ajustement(colette.mesures, colette.mesures) == 1 and Notation.ajustement(colette.mesures, { poitrine = 9.1, taille = 6.9, hanches = 9.5 }) == 1, "ajustement : juste à 0,2 dm près")
U.verifier(Notation.ajustement(colette.mesures, { poitrine = 7.4, taille = 5.6, hanches = 8 }) == 0.5, "ajustement : jamais sous 50 %")

---------------------------------------------------------------------------
-- Livraison : la qualité tient compte de l'ajustement ; amitié et prestige
---------------------------------------------------------------------------
jusquALaPhoto(e)
local bilan = e:bilan()
U.verifier(U.proche(bilan.ajustement, 0.8) and bilan.qualite < 0.81, "bilan : ajustement 80 %, la qualité en tient compte (" .. bilan.qualite .. ")")
r = e:livrer()
U.verifier(r.ok and r.reussie and U.proche(r.bilan.ajustement, 0.8), "robe livrée")
U.verifier(r.amitie.cliente == "colette" and r.amitie.gain == Progression.gainAmitie(true, r.bilan.qualite) and e.clientes.colette.amitie == r.amitie.gain, "amitié de Colette : +" .. r.amitie.gain)
U.verifier(r.prestige.gain == Progression.prestigeLivraison(r.paie) and e.prestige == r.prestige.gain and r.prestige.niveau == Progression.niveauPrestige(e.prestige), "prestige : un dixième de la paie")
U.verifier(e.livraisons == 1 and e.etape == "accueil", "une robe livrée")

---------------------------------------------------------------------------
-- Les suivantes : Margot, Salomé ; puis Colette revient, et ses mesures se reprennent d'un clic
---------------------------------------------------------------------------
r = e:nouvelleCommande(Random.new(4))
U.verifier(r.cliente == "margot" and r.premiereVisite and e.commande.taille == "S", "deuxième commande : Margot (taille S)")
e:mesurer(Clientes.get("margot").mesures)
U.verifier(e.etape == "carnet" and e.commande.ajustement == 1, "mesures exactes : ajustement 100 %")
e:recommencer()
e.etape = "refus"
r = e:abandonner()
U.verifier(r.ok and r.amitie.cliente == "margot" and r.amitie.gain == 0 and e.clientes.margot.amitie == 0, "abandon : l'amitié ne descend pas sous 0")
r = e:nouvelleCommande(Random.new(5))
U.verifier(r.cliente == "salome", "troisième : Salomé")
e:mesurer(Clientes.get("salome").mesures)
e.etape = "refus"
e:abandonner()
r = e:nouvelleCommande(Random.new(6))
U.verifier(r.cliente == "colette" and not r.premiereVisite and e.etape == "mesures", "Colette revient")
r = e:reprendreMesures()
U.verifier(r.ok and e.etape == "carnet" and U.proche(e.commande.mesures.poitrine, 9.4) and U.proche(e.commande.ajustement, 0.8), "« Reprendre ses mesures » : celles de sa première visite")
e.clientes.colette.amitie = 10
e.etape = "refus"
r = e:abandonner()
U.verifier(e.clientes.colette.amitie == 9 and r.amitie.gain == -1 and r.amitie.niveau == 2, "abandon : −1 d'amitié")
```

- [ ] **Step 2: Lancer les tests, vérifier l'échec**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT|attempt|membre" | head -3`
Expected: échec : une ligne qui finit par `ÉCHEC : colette : sa commande, sans mesures (elles seront prises)` (le générateur ignore encore la cliente)

- [ ] **Step 3: Écrire le code des règles et du serveur**

Dans `src/shared/Notation.luau`, remplacer :

```lua
function Notation.bilan(recette)
```

par :

```lua
-- Ajustement de la robe à la cliente (sous-projet 2) : 1 si les mesures prises sont justes à 0,2 dm près ;
-- chaque écart au-delà coûte (1,5 dm d'écart en tout : 0), jamais sous 50 %
Notation.TOLERANCE_MESURE = 0.2
Notation.PENTE_MESURE = 1.5
function Notation.ajustement(vraies, prises)
	local total = 0
	for _, cle in ipairs({ "poitrine", "taille", "hanches" }) do
		total += math.max(0, math.abs(prises[cle] - vraies[cle]) - Notation.TOLERANCE_MESURE)
	end
	return math.clamp(1 - total / Notation.PENTE_MESURE, 0.5, 1)
end

function Notation.bilan(recette)
```

Dans `src/shared/Commandes.luau`, remplacer :

```lua
-- Commandes : génère des commandes de clientes anonymes, toujours réalisables avec le catalogue.
```

par :

```lua
-- Commandes : génère des commandes, toujours réalisables avec le catalogue. Celle d'une cliente (sous-projet 2)
-- vient de ses goûts : un de ses styles, sa teinte, jamais un « au plus » dans ses styles.
```

Dans `src/shared/Commandes.luau`, remplacer :

```lua
local function tirerExigences(rng)
	local exigences = {}
	local styleMin = tirer(Catalogue.STYLES, rng)
```

par :

```lua
local function tirerExigences(rng, cliente)
	local exigences = {}
	local styleMin = tirer(cliente and cliente.styles or Catalogue.STYLES, rng)
```

Dans `src/shared/Commandes.luau`, remplacer :

```lua
			repeat
				style = tirer(Catalogue.STYLES, rng)
			until style ~= styleMin
```

par :

```lua
			repeat
				style = tirer(Catalogue.STYLES, rng)
			until style ~= styleMin and not (cliente and table.find(cliente.styles, style))
```

Dans `src/shared/Commandes.luau`, remplacer :

```lua
			table.insert(exigences, { type = "teinte", teinte = tirer(Catalogue.Tissus, rng).teinte })
```

par :

```lua
			table.insert(exigences, { type = "teinte", teinte = cliente and cliente.teinte or tirer(Catalogue.Tissus, rng).teinte })
```

Dans `src/shared/Commandes.luau`, remplacer :

```lua
-- rng : un objet Random. Retourne { taille, mesures, exigences }
function Commandes.generer(rng)
	local exigences
	for _ = 1, ESSAIS do
		local candidat = tirerExigences(rng)
```

par :

```lua
-- rng : un objet Random ; cliente (facultatif) : une fiche de Clientes. Retourne { taille, mesures, exigences }
-- (anonyme), ou { cliente, taille, exigences } : ses mesures seront prises à l'atelier.
function Commandes.generer(rng, cliente)
	local exigences
	for _ = 1, ESSAIS do
		local candidat = tirerExigences(rng, cliente)
```

Dans `src/shared/Commandes.luau`, remplacer :

```lua
	exigences = exigences or { { type = "min", style = "decontracte", valeur = 20 } }
	local taille = tirer(NOMS_TAILLES, rng)
```

par :

```lua
	exigences = exigences or { { type = "min", style = cliente and cliente.styles[1] or "decontracte", valeur = 20 } }
	if cliente then
		return { cliente = cliente.id, taille = cliente.taille, exigences = exigences }
	end
	local taille = tirer(NOMS_TAILLES, rng)
```

Dans `src/shared/EtatAtelier.luau`, remplacer :

```lua
local Recette = require(dossier:WaitForChild("Recette"))
```

par :

```lua
local Recette = require(dossier:WaitForChild("Recette"))
local Clientes = require(dossier:WaitForChild("Clientes"))
local Progression = require(dossier:WaitForChild("Progression"))
```

Dans `src/shared/EtatAtelier.luau`, remplacer :

```lua
EtatAtelier.DUREE_MIN = 0.9 -- part de la durée minimale d'une couture (trajet / vitesse maximale)
```

par :

```lua
EtatAtelier.DUREE_MIN = 0.9 -- part de la durée minimale d'une couture (trajet / vitesse maximale)
EtatAtelier.ECART_MESURE_MAX = 1.5 -- dm : une mesure plus loin de la vraie est refusée (ruban pas réglé)
local MESURE_INVALIDE = "Mesure invalide : règle chaque ruban au bord de la silhouette."
```

Dans `src/shared/EtatAtelier.luau`, remplacer :

```lua
function EtatAtelier:nouvelleCommande(rng)
	if self.etape ~= "accueil" then
		return refus("Une commande est déjà en cours.")
	end
	self.commande = Commandes.generer(rng)
	self.argent = math.max(self.argent, EtatAtelier.FILET)
	self.croquis, self.tissus, self.coupees, self.coupons = nil, {}, {}, {}
	self.epinglees, self.coutures, self.accessoires = {}, {}, {}
	self.etape = "carnet"
	return { ok = true, commande = self.commande }
end
```

par :

```lua
-- La clochette : une cliente vient (Clientes.prochaine) avec une commande tirée de ses goûts. On prend
-- d'abord ses mesures (étape « mesures ») ; une cliente déjà venue peut les reprendre.
function EtatAtelier:nouvelleCommande(rng)
	if self.etape ~= "accueil" then
		return refus("Une commande est déjà en cours.")
	end
	local id = Clientes.prochaine(self.clientes, Progression.niveauPrestige(self.prestige))
	local fiche = self.clientes[id] or { amitie = 0, vues = 0, derniere = 0 }
	self.clientes[id] = fiche
	self.visites += 1
	fiche.vues += 1
	fiche.derniere = self.visites
	self.commande = Commandes.generer(rng, Clientes.get(id))
	self.argent = math.max(self.argent, EtatAtelier.FILET)
	self.croquis, self.tissus, self.coupees, self.coupons = nil, {}, {}, {}
	self.epinglees, self.coutures, self.accessoires = {}, {}, {}
	self.etape = "mesures"
	return { ok = true, commande = self.commande, cliente = id, premiereVisite = fiche.vues == 1 }
end

-- Mesures prises au ruban (dm) : trois nombres dans les bornes d'une recette, à moins de 1,5 dm des vraies.
-- Le patron et le mannequin suivent les mesures prises ; l'ajustement (Notation) note leur justesse. Elles
-- sont gardées dans la fiche de la cliente pour sa prochaine visite.
function EtatAtelier:mesurer(prises)
	if self.etape ~= "mesures" then
		return refus("Ce n'est pas le moment de mesurer.")
	end
	if type(prises) ~= "table" then
		return refus(MESURE_INVALIDE)
	end
	local cliente = Clientes.get(self.commande.cliente)
	local propres = {}
	for _, cle in ipairs({ "poitrine", "taille", "hanches" }) do
		local v = prises[cle]
		if not fini(v) or math.abs(v - cliente.mesures[cle]) > EtatAtelier.ECART_MESURE_MAX then
			return refus(MESURE_INVALIDE)
		end
		propres[cle] = math.round(v * 100) / 100
	end
	if propres.poitrine < Recette.POITRINE[1] or propres.poitrine > Recette.POITRINE[2] or propres.taille < Recette.TAILLE[1]
		or propres.taille > Recette.TAILLE[2] or propres.hanches < Recette.HANCHES[1] or propres.hanches > Recette.HANCHES[2]
		or propres.taille > propres.poitrine or propres.taille > propres.hanches then
		return refus(MESURE_INVALIDE)
	end
	local ajustement = Notation.ajustement(cliente.mesures, propres)
	self.commande.mesures, self.commande.ajustement = propres, ajustement
	local fiche = self.clientes[cliente.id]
	fiche.mesures, fiche.ajustement = copie(propres), ajustement
	self.etape = "carnet"
	return { ok = true, ajustement = ajustement }
end

-- Une cliente déjà mesurée : ses mesures de la dernière fois, d'un clic
function EtatAtelier:reprendreMesures()
	if self.etape ~= "mesures" then
		return refus("Ce n'est pas le moment de mesurer.")
	end
	local fiche = self.clientes[self.commande.cliente]
	if not fiche or not fiche.mesures then
		return refus("Ses mesures n'ont jamais été prises.")
	end
	self.commande.mesures, self.commande.ajustement = copie(fiche.mesures), fiche.ajustement or 1
	self.etape = "carnet"
	return { ok = true, ajustement = self.commande.ajustement }
end
```

Dans `src/shared/EtatAtelier.luau`, remplacer :

```lua
-- Fin de la commande : l'atelier est prêt pour la suivante
```

par :

```lua
-- Bilan de la robe en cours (styles, qualité, teinte, accessoires) ; la qualité tient compte de l'ajustement aux
-- mesures de la cliente
function EtatAtelier:bilan()
	local bilan = Notation.bilan(self:recette())
	bilan.ajustement = self.commande and self.commande.ajustement or 1
	bilan.qualite *= bilan.ajustement
	return bilan
end

-- L'amitié de la cliente de la commande change (robe acceptée ou abandonnée) ; renvoie le détail pour le bilan
local function amitie(self, reussie, qualite)
	local id = self.commande and self.commande.cliente
	local fiche = id and self.clientes[id]
	if not fiche then
		return nil
	end
	local avant = fiche.amitie
	fiche.amitie = math.max(0, avant + Progression.gainAmitie(reussie, qualite))
	return { cliente = id, gain = fiche.amitie - avant, points = fiche.amitie, niveau = Progression.niveauAmitie(fiche.amitie), niveauAvant = Progression.niveauAmitie(avant) }
end

-- Fin de la commande : l'atelier est prêt pour la suivante
```

Dans `src/shared/EtatAtelier.luau`, remplacer :

```lua
	local recette = self:recette()
	local bilan = Notation.bilan(recette)
	local reussie, ratees = Notation.verifierExigences(self.commande.exigences, bilan)
```

par :

```lua
	local recette = self:recette()
	local bilan = self:bilan()
	local reussie, ratees = Notation.verifierExigences(self.commande.exigences, bilan)
```

Dans `src/shared/EtatAtelier.luau`, remplacer :

```lua
	local paie = Notation.paie(#recette.pieces, #self.commande.exigences, bilan.qualite)
	self.argent += paie
```

par :

```lua
	local paie = Notation.paie(#recette.pieces, #self.commande.exigences, bilan.qualite)
	self.argent += paie
	local gainAmitie = amitie(self, true, bilan.qualite)
	local niveauAvant = Progression.niveauPrestige(self.prestige)
	local gainPrestige = Progression.prestigeLivraison(paie)
	self.prestige += gainPrestige
	self.livraisons += 1
	local prestige = { gain = gainPrestige, points = self.prestige, niveau = Progression.niveauPrestige(self.prestige), niveauAvant = niveauAvant }
```

Dans `src/shared/EtatAtelier.luau`, remplacer :

```lua
	terminer(self)
	return { ok = true, reussie = true, paie = paie, bilan = bilan, ratees = {} }
```

par :

```lua
	terminer(self)
	return { ok = true, reussie = true, paie = paie, bilan = bilan, ratees = {}, amitie = gainAmitie, prestige = prestige }
```

Dans `src/shared/EtatAtelier.luau`, remplacer :

```lua
	if self.etape ~= "refus" then
		return refus("Il n'y a rien à abandonner.")
	end
	terminer(self)
	return { ok = true }
```

par :

```lua
	if self.etape ~= "refus" then
		return refus("Il n'y a rien à abandonner.")
	end
	local perte = amitie(self, false, 0)
	terminer(self)
	return { ok = true, amitie = perte }
```

Dans `src/shared/EtatAtelier.luau`, remplacer :

```lua
function EtatAtelier:recommencer()
	if self.etape == "accueil" then
		return refus("Aucune commande en cours.")
	end
```

par :

```lua
function EtatAtelier:recommencer()
	if self.etape == "accueil" then
		return refus("Aucune commande en cours.")
	end
	if self.etape == "mesures" then
		return refus("Il n'y a rien à recommencer.")
	end
```

Dans `src/server/Commande.luau`, remplacer :

```lua
	nouvelleCommande = function(a)
		return a.etat:nouvelleCommande(a.rng)
	end,
```

par :

```lua
	nouvelleCommande = function(a)
		return a.etat:nouvelleCommande(a.rng)
	end,
	mesurer = function(a, prises)
		return a.etat:mesurer(prises)
	end,
	reprendreMesures = function(a)
		return a.etat:reprendreMesures()
	end,
```

Dans `src/client/Atelier/Session.luau`, remplacer :

```lua
function Session:validerCroquis(croquis, tissus)
```

par :

```lua
function Session:mesurer(prises)
	return agir(self, "mesurer", prises)
end
function Session:reprendreMesures()
	return agir(self, "reprendreMesures")
end
function Session:validerCroquis(croquis, tissus)
```

- [ ] **Step 4: Écrire l'écran des mesures**

Créer `src/client/Atelier/EcranMesures.luau` :

```lua
-- Écran des mesures (sous-projet 2) : la silhouette de la cliente, de face, dessinée à ses vraies mesures, et
-- trois rubans (poitrine, taille, hanches) qui partent de son bord gauche. On règle chaque ruban jusqu'au bord
-- droit de la silhouette : en faisant glisser sa poignée, ou avec − et + (0,1 dm de tour). La mesure lue
-- s'affiche en centimètres. « Valider les mesures » les envoie au serveur, qui refuse un ruban trop loin ; une
-- cliente déjà mesurée peut « Reprendre ses mesures ».
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Couture = ReplicatedStorage:WaitForChild("Couture")
local Catalogue = require(Couture:WaitForChild("Catalogue"))
local Clientes = require(Couture:WaitForChild("Clientes"))

local MESURES = { { cle = "poitrine", nom = "Poitrine", y = 110 }, { cle = "taille", nom = "Taille", y = 190 }, { cle = "hanches", nom = "Hanches", y = 270 } }
local LARGEUR = 320 -- px : largeur de la silhouette
local PX = 70 -- px par dm de largeur de face
local FACE = 0.32 -- largeur de face d'un tour : un tour de 9 dm fait 2,9 dm de large, vu de face
local DEPART = 0.7 -- les rubans partent à 70 % de la mesure de sa taille : il faut vraiment mesurer
local PAS = 0.1 -- dm de tour par appui sur − ou +
local RUBAN = Color3.fromRGB(250, 210, 70)

local function arrondi(v)
	return math.round(v * 10) / 10
end

return function(ctx)
	local UiKit, session, contenu = ctx.UiKit, ctx.session, ctx.contenu
	local C = UiKit.COULEURS
	local etat = session.etat
	local cliente = Clientes.get(etat.commande.cliente)
	local fiche = etat.clientes[cliente.id]
	local connexions = {}
	local prises, rubans = {}, {}

	UiKit.texte({
		Name = "Consigne",
		Text = ("Mesure %s : fais glisser chaque ruban jusqu'au bord de sa silhouette (ou règle-le avec − et +)."):format(cliente.nom),
		TextSize = 16,
		Size = UDim2.new(1, 0, 0, 44),
		Parent = contenu,
	})

	-- La silhouette : tête, cou, puis buste, taille et hanches, chacun à la largeur de sa vraie mesure
	local silhouette = UiKit.arrondir(UiKit.creer("Frame", { Name = "Silhouette", BackgroundColor3 = C.panneau, Position = UDim2.fromOffset(0, 50), Size = UDim2.fromOffset(LARGEUR, 340), Parent = contenu }), 10)
	local centre = LARGEUR / 2
	UiKit.arrondir(UiKit.creer("Frame", { Name = "Tete", BackgroundColor3 = cliente.tenue.peau, BorderSizePixel = 0, Position = UDim2.fromOffset(centre - 26, 6), Size = UDim2.fromOffset(52, 58), Parent = silhouette }), 26)
	UiKit.creer("Frame", { Name = "Cou", BackgroundColor3 = cliente.tenue.peau, BorderSizePixel = 0, Position = UDim2.fromOffset(centre - 10, 62), Size = UDim2.fromOffset(20, 10), Parent = silhouette })
	for i, m in ipairs(MESURES) do
		local largeur = cliente.mesures[m.cle] * FACE * PX
		UiKit.creer("Frame", {
			Name = "Corps_" .. m.cle,
			BackgroundColor3 = if i < 3 then cliente.tenue.haut else cliente.tenue.bas,
			BorderSizePixel = 0,
			Position = UDim2.fromOffset(centre - largeur / 2, m.y - 40),
			Size = UDim2.fromOffset(largeur, 80),
			Parent = silhouette,
		})
	end

	-- Les rubans, partis du bord gauche de la silhouette, et leurs réglages à droite
	local function maj(cle)
		local r = rubans[cle]
		local largeur = prises[cle] * FACE * PX
		r.ruban.Size = UDim2.fromOffset(largeur, 8)
		r.poignee.Position = UDim2.fromOffset(r.ruban.Position.X.Offset + largeur, r.ruban.Position.Y.Offset + 4)
		r.valeur.Text = ("%s : %d cm"):format(r.nom, math.round(prises[cle] * 10))
	end
	local function regler(cle, valeur)
		prises[cle] = math.clamp(arrondi(valeur), 2, 15)
		maj(cle)
	end
	for _, m in ipairs(MESURES) do
		local cle = m.cle
		prises[cle] = arrondi(Catalogue.TAILLES[cliente.taille][cle] * DEPART)
		local vraieLargeur = cliente.mesures[cle] * FACE * PX
		local ruban = UiKit.creer("Frame", { Name = "Ruban_" .. cle, BackgroundColor3 = RUBAN, BorderSizePixel = 0, Position = UDim2.fromOffset(centre - vraieLargeur / 2, m.y - 4), ZIndex = 3, Parent = silhouette })
		local poignee = UiKit.arrondir(UiKit.creer("TextButton", { Name = "Poignee_" .. cle, Text = "", AutoButtonColor = false, BackgroundColor3 = C.accent, AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(24, 24), ZIndex = 4, Parent = silhouette }), 12)
		local y = 50 + m.y - 18
		local valeur = UiKit.texte({ Name = "Valeur_" .. cle, Font = Enum.Font.GothamBold, TextSize = 18, Position = UDim2.fromOffset(LARGEUR + 30, y), Size = UDim2.fromOffset(220, 36), Parent = contenu })
		UiKit.boutonDoux({ Name = "Moins_" .. cle, Text = "−", TextSize = 22, Position = UDim2.fromOffset(LARGEUR + 260, y), Size = UDim2.fromOffset(44, 36), Parent = contenu }, function()
			regler(cle, prises[cle] - PAS)
		end)
		UiKit.boutonDoux({ Name = "Plus_" .. cle, Text = "+", TextSize = 22, Position = UDim2.fromOffset(LARGEUR + 312, y), Size = UDim2.fromOffset(44, 36), Parent = contenu }, function()
			regler(cle, prises[cle] + PAS)
		end)
		rubans[cle] = { ruban = ruban, poignee = poignee, valeur = valeur, nom = m.nom }
		maj(cle)
		-- Glisser la poignée (souris ou doigt) : la largeur à l'écran, ramenée à l'échelle de la fenêtre
		table.insert(connexions, poignee.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				rubans.saisie = { cle = cle, input = input }
			end
		end))
	end
	table.insert(connexions, UserInputService.InputChanged:Connect(function(input)
		local saisie = rubans.saisie
		if not saisie then
			return
		end
		local suit = if saisie.input.UserInputType == Enum.UserInputType.Touch then input == saisie.input else input.UserInputType == Enum.UserInputType.MouseMovement
		local taille, debut = silhouette.AbsoluteSize, rubans[saisie.cle].ruban.AbsolutePosition
		if suit and taille and debut and taille.X > 0 then
			local echelle = taille.X / LARGEUR
			regler(saisie.cle, (input.Position.X - debut.X) / echelle / (FACE * PX))
		end
	end))
	table.insert(connexions, UserInputService.InputEnded:Connect(function(input)
		local saisie = rubans.saisie
		if saisie and (input == saisie.input or (saisie.input.UserInputType == Enum.UserInputType.MouseButton1 and input.UserInputType == Enum.UserInputType.MouseButton1)) then
			rubans.saisie = nil
		end
	end))

	UiKit.bouton({ Name = "ValiderMesures", Text = "Valider les mesures", AnchorPoint = Vector2.new(1, 1), Position = UDim2.fromScale(1, 1), Size = UDim2.fromOffset(240, 46), Parent = contenu }, function()
		local r = session:mesurer({ poitrine = prises.poitrine, taille = prises.taille, hanches = prises.hanches })
		if not r.ok then
			ctx.refus(r)
		end
	end, 0.4)
	if fiche and fiche.mesures then
		UiKit.texte({ Text = "Ses mesures sont déjà dans ton carnet.", TextSize = 14, TextColor3 = C.texteDoux, Position = UDim2.fromOffset(LARGEUR + 30, 380), Size = UDim2.fromOffset(330, 22), Parent = contenu })
		UiKit.boutonDoux({ Name = "ReprendreMesures", Text = "Reprendre ses mesures", AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, LARGEUR + 30, 1, 0), Size = UDim2.fromOffset(240, 46), Parent = contenu }, function()
			local r = session:reprendreMesures()
			if not r.ok then
				ctx.refus(r)
			end
		end, 0.4)
	end

	return function()
		for _, c in ipairs(connexions) do
			c:Disconnect()
		end
	end
end
```

Dans `src/client/Atelier/init.client.luau`, remplacer :

```lua
	accueil = require(script:WaitForChild("EcranAccueil")),
```

par :

```lua
	accueil = require(script:WaitForChild("EcranAccueil")),
	mesures = require(script:WaitForChild("EcranMesures")),
```

Dans `src/client/Atelier/init.client.luau`, remplacer :

```lua
	accueil = "Atelier de couture",
```

par :

```lua
	accueil = "Atelier de couture",
	mesures = "Les mesures",
```

- [ ] **Step 5: Lancer les tests**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT"`
Expected:
```
Unitaires : 106832 vérifications
TOUT EST VERT : 552 vérifications
```

- [ ] **Step 6: Commit**

```bash
git add src/shared/Notation.luau src/shared/Commandes.luau src/shared/EtatAtelier.luau src/server/Commande.luau src/client/Atelier/Session.luau src/client/Atelier/EcranMesures.luau src/client/Atelier/init.client.luau tests/build.py tests/unitaires tests/scenario.luau
git commit -m "Mesures : la cliente est mesurée au ruban, l'ajustement note la robe ; amitié et prestige à la livraison

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 4: La cliente en personne : tenue, nom, répliques, bilan

**Files:**
- Modify: `src/client/Atelier/Cliente.luau` (`tenue`, étiquette `Nom`)
- Modify: `src/client/Atelier/Scene.luau` (répliques)
- Modify: `src/client/Atelier/EcranCarnet.luau`, `EcranPresentation.luau`, `EcranRefus.luau`, `EcranAccueil.luau`
- Modify: `tests/unitaires/25_cliente.luau`, `26_scene_cliente_photo.luau`, `tests/scenario.luau`

**Interfaces:**
- Consumes: `Clientes.get` (tâche 1) ; `etat.clientes[id].vues` (tâche 2) ; `EtatAtelier:bilan()`, réponses `amitie` et `prestige` de `livrer` et `abandonner` (tâche 3).
- Produces:
  - `Cliente.tenue(commande)` : la tenue de la cliente nommée, sinon celle tirée d'après la commande ;
  - sur la tête d'une cliente nommée, un `BillboardGui` `Nom` avec un `TextLabel` `Texte` (son nom, 16 px) ;
  - bulles : aux mesures, `presentation` (première visite) ou `arrivee` ; au carnet, `arrivee` ; au refus, `deception` ; au départ réussi, `merci` ;
  - carnet : « Colette (taille M) veut : » ; présentation : « Qualité de la robe : N % (ajustement N %) » ; accueil : « Colette est ravie ! … » puis « Amitié de Colette : +N (niveau X !) · Prestige : +N (niveau X !) ».

- [ ] **Step 1: Écrire les tests**

Dans `tests/unitaires/25_cliente.luau`, remplacer :

```lua
M.echecAvatar = false
modele:Destroy()
```

par :

```lua
M.echecAvatar = false
modele:Destroy()

---------------------------------------------------------------------------
-- Une cliente qui revient (sous-projet 2) : sa propre tenue, son nom au-dessus de la tête
---------------------------------------------------------------------------
local Clientes = U.module("Clientes")
local ines = Clientes.get("ines")
local commandeInes = { cliente = "ines", taille = "S", exigences = { { type = "min", style = "gothique", valeur = 30 } } }
local dInes = Cliente.description(commandeInes)
U.verifier(dInes.TorsoColor == ines.tenue.haut and dInes.LeftLegColor == ines.tenue.bas and dInes.HeadColor == ines.tenue.peau, "Inès : sa tenue")
local modeleInes = Cliente.construire(commandeInes, place, Workspace)
local etiquette = modeleInes.Head:FindFirstChild("Nom")
U.verifier(etiquette ~= nil and etiquette:IsA("BillboardGui") and etiquette.Texte.Text == "Inès Lebrun" and etiquette.Texte.TextSize >= 14, "son nom au-dessus de la tête")
U.verifier(modeleInes.Cheveux.Color == ines.tenue.cheveux, "ses cheveux")
modeleInes:Destroy()
local anonyme = Cliente.construire(commande, place, Workspace)
U.verifier(anonyme.Head:FindFirstChild("Nom") == nil, "cliente anonyme (tests) : pas de nom")
anonyme:Destroy()
```

Dans `tests/unitaires/26_scene_cliente_photo.luau`, remplacer :

```lua
local Patron = U.module("Patron")
```

par :

```lua
local Patron = U.module("Patron")
local Clientes = U.module("Clientes")
```

Dans `tests/unitaires/26_scene_cliente_photo.luau`, remplacer :

```lua
U.verifier(bulle(cliente) == Scene.PAROLES.carnet, "au carnet, elle dit ce qu'elle veut")
```

par :

```lua
local colette = Clientes.get(etat.commande.cliente)
U.verifier(colette.id == "colette" and bulle(cliente) == colette.repliques.arrivee, "au carnet, Colette dit ce qu'elle veut, avec ses mots")
```

Dans `tests/unitaires/26_scene_cliente_photo.luau`, remplacer :

```lua
U.verifier(bulle(cliente) == Scene.PAROLES.refus, "robe refusée : elle le dit")
```

par :

```lua
U.verifier(bulle(cliente) == colette.repliques.deception, "robe refusée : elle le dit, avec ses mots")
```

Dans `tests/unitaires/26_scene_cliente_photo.luau`, remplacer :

```lua
U.verifier(r.reussie and bulle(cliente) == Scene.PAROLES.merci and cliente.Parent ~= nil, "robe acceptée : elle remercie")
```

par :

```lua
U.verifier(r.reussie and bulle(cliente) == colette.repliques.merci and cliente.Parent ~= nil, "robe acceptée : elle remercie, avec ses mots")
```

Dans `tests/unitaires/26_scene_cliente_photo.luau`, remplacer :

```lua
U.verifier(deuxieme ~= nil and deuxieme ~= cliente, "nouvelle commande : nouvelle cliente")
```

par :

```lua
U.verifier(deuxieme ~= nil and deuxieme ~= cliente, "nouvelle commande : nouvelle cliente")
etat.etape = "mesures"
scene:synchroniser(etat, nil)
U.verifier(bulle(deuxieme) == Clientes.get(etat.commande.cliente).repliques.presentation, "première visite : aux mesures, elle se présente")
etat.clientes[etat.commande.cliente].vues = 2
scene:synchroniser(etat, nil)
U.verifier(bulle(deuxieme) == Clientes.get(etat.commande.cliente).repliques.arrivee, "elle revient : aux mesures, elle dit ce qu'elle veut")
```

Dans `tests/scenario.luau`, remplacer :

```lua
verifierTailles("mesures")
```

par :

```lua
verifierTailles("mesures")
local clienteMesuree = M.services.Workspace.AtelierLocal:FindFirstChild("Cliente")
verifier(clienteMesuree ~= nil and clienteMesuree.Head.Nom.Texte.Text == "Colette Marchand", "Colette en personne, son nom au-dessus de la tête")
verifier(clienteMesuree.Head.Bulle.Texte.Text == Clientes.get("colette").repliques.presentation, "elle se présente")
```

Dans `tests/scenario.luau`, remplacer :

```lua
verifier(texte("La cliente (taille") ~= nil, "la taille de la cliente est affichée")
```

par :

```lua
verifier(texte("Colette (taille M) veut") ~= nil, "le carnet dit qui commande, et sa taille")
verifier(M.services.Workspace.AtelierLocal.Cliente.Head.Bulle.Texte.Text == Clientes.get("colette").repliques.arrivee, "au carnet, elle explique ce qu'elle veut")
```

Dans `tests/scenario.luau`, remplacer :

```lua
verifier(texte("La cliente est ravie") ~= nil, "l'accueil annonce la paie")
```

par :

```lua
verifier(texte("Colette est ravie") ~= nil, "l'accueil annonce la paie")
verifier(texte("Amitié de Colette : +") ~= nil and texte("Prestige : +") ~= nil, "l'accueil annonce l'amitié et le prestige gagnés")
```

Dans `tests/scenario.luau`, remplacer :

```lua
verifier(laCliente.Parent ~= nil and laCliente.Head.Bulle.Texte.Text == ScenePoste.PAROLES.merci, "la cliente remercie")
```

par :

```lua
verifier(laCliente.Parent ~= nil and laCliente.Head.Bulle.Texte.Text == Clientes.get("colette").repliques.merci, "Colette remercie")
```

Dans `tests/scenario.luau`, remplacer :

```lua
verifier(laCliente ~= nil and laCliente.Head.Bulle.Texte.Text == ScenePoste.PAROLES.photo, "la cliente est là et regarde la robe")
```

par :

```lua
verifier(laCliente ~= nil and laCliente.Head.Bulle.Texte.Text == ScenePoste.PAROLES.photo, "la cliente est là et regarde la robe")
verifier(texte("(ajustement 100 %)") ~= nil, "la qualité montre l'ajustement aux mesures")
```

- [ ] **Step 2: Lancer les tests, vérifier l'échec**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT|attempt|membre" | head -3`
Expected: échec : une ligne qui finit par `ÉCHEC : Inès : sa tenue`

- [ ] **Step 3: Écrire le code**

Dans `src/client/Atelier/Cliente.luau`, remplacer :

```lua
local Players = game:GetService("Players")
```

par :

```lua
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Clientes = require(ReplicatedStorage:WaitForChild("Couture"):WaitForChild("Clientes"))
```

Dans `src/client/Atelier/Cliente.luau`, remplacer :

```lua
function Cliente.description(commande)
	local t = Cliente.TENUES[Cliente.choisir(commande)]
```

par :

```lua
-- La tenue d'une commande : celle de la cliente qui revient (sous-projet 2), sinon tirée d'après la commande
function Cliente.tenue(commande)
	local fiche = commande.cliente and Clientes.get(commande.cliente)
	return fiche and fiche.tenue or Cliente.TENUES[Cliente.choisir(commande)]
end

function Cliente.description(commande)
	local t = Cliente.tenue(commande)
```

Dans `src/client/Atelier/Cliente.luau`, remplacer :

```lua
		cheveux.Color = Cliente.TENUES[Cliente.choisir(commande)].cheveux
```

par :

```lua
		cheveux.Color = Cliente.tenue(commande).cheveux
```

Dans `src/client/Atelier/Cliente.luau`, remplacer :

```lua
		cheveux.Parent = modele
	end
```

par :

```lua
		cheveux.Parent = modele
		-- Son nom au-dessus de la tête (une cliente qui revient)
		local fiche = commande.cliente and Clientes.get(commande.cliente)
		if fiche then
			local etiquette = Instance.new("BillboardGui")
			etiquette.Name = "Nom"
			etiquette.Size = UDim2.fromOffset(200, 26)
			etiquette.StudsOffset = Vector3.new(0, 1.3, 0)
			etiquette.MaxDistance = 40
			local texte = Instance.new("TextLabel")
			texte.Name = "Texte"
			texte.BackgroundTransparency = 1
			texte.Size = UDim2.fromScale(1, 1)
			texte.Font = Enum.Font.GothamBold
			texte.TextSize = 16
			texte.TextColor3 = Color3.fromRGB(255, 255, 255)
			texte.TextStrokeTransparency = 0.4
			texte.Text = fiche.nom
			texte.Parent = etiquette
			etiquette.Parent = tete
		end
	end
```

Dans `src/client/Atelier/Scene.luau`, remplacer :

```lua
local Boutique = require(Couture:WaitForChild("Boutique"))
```

par :

```lua
local Boutique = require(Couture:WaitForChild("Boutique"))
local Clientes = require(Couture:WaitForChild("Clientes"))
```

Dans `src/client/Atelier/Scene.luau`, remplacer :

```lua
-- La cliente en personne : elle entre avec la commande, parle selon l'étape, salue puis s'en va
function Scene:suivreCliente(etat, derniere)
```

par :

```lua
-- Ce que dit la cliente de la commande à cette étape : une cliente qui revient a ses propres répliques
-- (présentation à sa première visite, puis son arrivée ; sa déception au refus)
local function replique(etat)
	local fiche = etat.commande.cliente and Clientes.get(etat.commande.cliente)
	if not fiche then
		return Scene.PAROLES[etat.etape]
	end
	if etat.etape == "mesures" then
		local visite = etat.clientes[fiche.id]
		return if visite and visite.vues > 1 then fiche.repliques.arrivee else fiche.repliques.presentation
	elseif etat.etape == "carnet" then
		return fiche.repliques.arrivee
	elseif etat.etape == "refus" then
		return fiche.repliques.deception
	end
	return Scene.PAROLES[etat.etape]
end

-- La cliente en personne : elle entre avec la commande, parle selon l'étape, salue puis s'en va
function Scene:suivreCliente(etat, derniere)
```

Dans `src/client/Atelier/Scene.luau`, remplacer :

```lua
		self.cliente = modele
	end
	if commande then
		Cliente.dire(self.cliente, Scene.PAROLES[etat.etape])
	elseif self.cliente then
		local reussie = derniere and derniere.action == "livrer" and derniere.reponse.reussie
		Cliente.dire(self.cliente, reussie and Scene.PAROLES.merci or Scene.PAROLES.abandon)
```

par :

```lua
		self.cliente = modele
		self.clienteId = commande.cliente
	end
	if commande then
		Cliente.dire(self.cliente, replique(etat))
	elseif self.cliente then
		local reussie = derniere and derniere.action == "livrer" and derniere.reponse.reussie
		local fiche = self.clienteId and Clientes.get(self.clienteId)
		local merci = fiche and fiche.repliques.merci or Scene.PAROLES.merci
		Cliente.dire(self.cliente, reussie and merci or Scene.PAROLES.abandon)
```

Dans `src/client/Atelier/EcranCarnet.luau`, remplacer :

```lua
	UiKit.texte({ Text = ("La cliente (taille %s) veut :"):format(etat.commande.taille), Font = Enum.Font.GothamBold, Position = UDim2.fromOffset(12, 8), Size = UDim2.new(1, -24, 0, 22), Parent = droite })
```

par :

```lua
	local fiche = etat.commande.cliente and Clientes.get(etat.commande.cliente)
	local qui = fiche and fiche.nom:match("^(%S+)") or "La cliente"
	UiKit.texte({ Text = ("%s (taille %s) veut :"):format(qui, etat.commande.taille), Font = Enum.Font.GothamBold, Position = UDim2.fromOffset(12, 8), Size = UDim2.new(1, -24, 0, 22), Parent = droite })
```

Dans `src/client/Atelier/EcranCarnet.luau`, remplacer :

```lua
local EtatAtelier = require(Couture:WaitForChild("EtatAtelier"))
```

par :

```lua
local EtatAtelier = require(Couture:WaitForChild("EtatAtelier"))
local Clientes = require(Couture:WaitForChild("Clientes"))
```

Dans `src/client/Atelier/EcranPresentation.luau`, remplacer :

```lua
	local bilan = Notation.bilan(etat:recette())
```

par :

```lua
	local bilan = etat:bilan() -- (la qualité tient compte de l'ajustement aux mesures de la cliente)
```

Dans `src/client/Atelier/EcranPresentation.luau`, remplacer :

```lua
		Text = ("Qualité de la robe : %d %%"):format(math.floor(bilan.qualite * 100 + 0.5)),
```

par :

```lua
		Text = ("Qualité de la robe : %d %% (ajustement %d %%)"):format(math.floor(bilan.qualite * 100 + 0.5), math.floor(bilan.ajustement * 100 + 0.5)),
```

Dans `src/client/Atelier/EcranRefus.luau`, remplacer :

```lua
	local styles = Notation.bilan(etat:recette()).styles
```

par :

```lua
	local styles = etat:bilan().styles
```

Dans `src/client/Atelier/EcranAccueil.luau`, remplacer :

```lua
local UserInputService = game:GetService("UserInputService")
```

par :

```lua
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Clientes = require(ReplicatedStorage:WaitForChild("Couture"):WaitForChild("Clientes"))

-- « Amitié de Colette : +3 (niveau 2 !) » ; nil sans cliente
local function ligneAmitie(amitie)
	local fiche = amitie and Clientes.get(amitie.cliente)
	if not fiche then
		return nil
	end
	local prenom = fiche.nom:match("^(%S+)")
	local niveau = if amitie.niveau > amitie.niveauAvant then (" (niveau %d !)"):format(amitie.niveau) else ""
	return ("Amitié de %s : %s%d%s"):format(prenom, amitie.gain >= 0 and "+" or "", amitie.gain, niveau)
end
```

Dans `src/client/Atelier/EcranAccueil.luau`, remplacer :

```lua
	if derniere and derniere.action == "livrer" and derniere.reponse.reussie then
		annonce = ("La cliente est ravie ! +%d pièces d'or (qualité %d %%). Sa robe est en vitrine."):format(
			derniere.reponse.paie,
			math.floor(derniere.reponse.bilan.qualite * 100 + 0.5)
		)
	elseif derniere and derniere.action == "abandonner" then
		annonce, couleur = "Commande abandonnée : pas de paie cette fois.", C.alerte
	end
```

par :

```lua
	if derniere and derniere.action == "livrer" and derniere.reponse.reussie then
		local r = derniere.reponse
		local fiche = r.amitie and Clientes.get(r.amitie.cliente)
		annonce = ("%s est ravie ! +%d pièces d'or (qualité %d %%). Sa robe est en vitrine."):format(
			fiche and fiche.nom:match("^(%S+)") or "La cliente",
			r.paie,
			math.floor(r.bilan.qualite * 100 + 0.5)
		)
		local suite = {}
		table.insert(suite, ligneAmitie(r.amitie))
		if r.prestige then
			table.insert(suite, ("Prestige : +%d%s"):format(r.prestige.gain, if r.prestige.niveau > r.prestige.niveauAvant then (" (niveau %d !)"):format(r.prestige.niveau) else ""))
		end
		if #suite > 0 then
			annonce ..= "\n" .. table.concat(suite, " · ")
		end
	elseif derniere and derniere.action == "abandonner" then
		annonce, couleur = "Commande abandonnée : pas de paie cette fois.", C.alerte
		local perte = ligneAmitie(derniere.reponse.amitie)
		if perte then
			annonce ..= "\n" .. perte
		end
	end
```

Dans `src/client/Atelier/EcranPresentation.luau`, supprimer la ligne :

```lua
local Notation = require(Couture:WaitForChild("Notation"))
```

Dans `src/client/Atelier/EcranRefus.luau`, supprimer la ligne :

```lua
local Notation = require(Couture:WaitForChild("Notation"))
```

- [ ] **Step 4: Lancer les tests**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT"`
Expected:
```
Unitaires : 106838 vérifications
TOUT EST VERT : 557 vérifications
```

- [ ] **Step 5: Commit**

```bash
git add src/client/Atelier/Cliente.luau src/client/Atelier/Scene.luau src/client/Atelier/EcranCarnet.luau src/client/Atelier/EcranPresentation.luau src/client/Atelier/EcranRefus.luau src/client/Atelier/EcranAccueil.luau tests/unitaires/25_cliente.luau tests/unitaires/26_scene_cliente_photo.luau tests/scenario.luau
git commit -m "La cliente en personne : sa tenue, son nom, ses mots ; ajustement, amitié et prestige annoncés

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 5: Vérification dans Studio et README

**Files:**
- Modify: `README.md`
- Modify: `AtelierCouture.rbxl` (régénéré)

**Interfaces:**
- Consumes: tout ce qui précède.
- Produces: le plan 5a terminé.

- [ ] **Step 1: En Play, par le connecteur MCP**

Construire le lieu du dépôt dans un dossier temporaire (`C:/dev/jeux/roblox-maker/rojo.exe build -o <dossier temporaire>/Plan5aDepot.rbxl`), l'ouvrir dans Studio, lancer Play et attendre 4 s. Puis :

1. Appuyer sur E, attendre 2 s ; côté client (`execute_luau`), lire le titre de la fenêtre, le texte de la bulle et de l'étiquette `Nom` de `workspace.AtelierLocal.Cliente`, et la taille absolue de `Silhouette` et de `Corps_poitrine`.
2. Cliquer (`user_mouse_input`) sur `Plus_poitrine` trois fois ; relire `Valeur_poitrine`.
3. Régler les trois rubans aux vraies mesures de Colette (par des clics sur `Plus_…`), cliquer sur « Valider les mesures » ; relire le titre.
4. Relever les alertes (`get_console_output`).

Expected :
- titre « Les mesures », bulle = la présentation de Colette, étiquette « Colette Marchand » ;
- la silhouette et la bande de la poitrine ont une taille non nulle ;
- `Valeur_poitrine` a monté de 3 cm ;
- après validation : « 1. Carnet de croquis » ;
- aucune alerte hors « Lieu non publié : les parties ne sont pas sauvegardées. ».

Arrêter Play et fermer cette fenêtre de Studio (sans enregistrer).

- [ ] **Step 2: À faire par le commanditaire**

Ces vérifications demandent l'interface de Studio ou un téléphone :
- régler les rubans au doigt sur téléphone (poignée assez grosse, silhouette lisible à l'échelle réduite) ;
- regarder les tenues des six clientes et leur nom au-dessus de la tête.

Les noter dans le message de fin, sans bloquer le plan.

- [ ] **Step 3: Mettre à jour le README**

Dans `README.md`, remplacer :

```markdown
(spec : `docs/superpowers/specs/2026-09-28-atelier-coeur-design.md`, plans : `docs/superpowers/plans/`).
```

par :

```markdown
(specs : `docs/superpowers/specs/2026-09-28-atelier-coeur-design.md` pour le cœur de l'atelier,
`docs/superpowers/specs/2026-09-29-clientes-progression-design.md` pour les clientes et la progression ;
plans : `docs/superpowers/plans/`).
```

Dans `README.md`, remplacer :

```markdown
## État actuel (sous-projet 1 terminé côté code, plan 4d-3 ; reste l'essai sur téléphone)
```

par :

```markdown
## État actuel (sous-projet 2 en cours : plan 5a, les clientes)
```

Dans `README.md`, remplacer :

```markdown
1. **Commande** : la clochette (ou E) fait entrer la cliente en personne (un avatar construit en code, taille S, M ou L)
   avec 1 à 3 exigences de style, de couleur, de qualité ou d'accessoire. Elle parle par une bulle.
```

par :

```markdown
1. **Commande** : la clochette (ou E) fait entrer une cliente en personne (un avatar construit en code, son nom
   au-dessus de la tête), avec 1 à 3 exigences tirées de ses styles préférés et de sa teinte. Six clientes, qui
   reviennent : Colette, Margot et Salomé aux trois premières commandes ; Hélène, Inès et Victoire quand le
   prestige de l'atelier atteint 2, 3 puis 4 ; ensuite, celle qu'on n'a pas vue depuis le plus longtemps. Chacune
   parle par une bulle, avec ses propres mots (présentation, arrivée, merci, déception).
   **Mesures** : à sa première visite, on la mesure. Sa silhouette est dessinée à ses vraies mesures ; on règle
   trois rubans (poitrine, taille, hanches) jusqu'au bord de la silhouette, en glissant ou avec − et + (0,1 dm
   près). Le serveur refuse un ruban à plus de 1,5 dm de la vraie mesure. Quand elle revient, « Reprendre ses
   mesures » les reprend du carnet. Le mannequin et le patron suivent les mesures prises ; l'ajustement
   (100 % jusqu'à 0,2 dm d'écart par tour, puis moins, 50 % au pire) multiplie la qualité de la robe.
```

Dans `README.md`, remplacer :

```markdown
   la robe (styles, qualité, couleur dominante, accessoires). Acceptée : paie = base × (0,5 + qualité), et la
   robe part en vitrine ; la cliente remercie et s'en va. Refusée : les exigences ratées s'affichent (avec le
   score actuel pour les styles) ; on retouche les décorations ou on abandonne.
9. La suite : sous-projet 2, clientes et progression (prise de mesures, clientes qui reviennent, déblocages,
   équilibrage des prix).
```

par :

```markdown
   la robe (styles, qualité, couleur dominante, accessoires). Acceptée : paie = base × (0,5 + qualité), et la
   robe part en vitrine ; la cliente remercie et s'en va. Refusée : les exigences ratées s'affichent (avec le
   score actuel pour les styles) ; on retouche les décorations ou on abandonne.
   **Amitié et prestige** : une robe acceptée vaut +2 d'amitié avec la cliente (+1 de plus à 80 % de qualité),
   un abandon −1 ; niveaux 0 à 5 (seuils 3, 7, 12, 18, 25). Elle rapporte aussi du prestige à l'atelier
   (paie / 10) ; niveaux 1 à 8. L'accueil annonce ce qui a été gagné.
9. La suite : prestige et déblocages (plan 5b), robes libres à vendre ou à offrir (plan 5c), courrier et
   carnet d'adresses (plan 5d).
```

Dans `README.md`, remplacer :

```markdown
  | `Notation`, `Commandes` | Droit-fil, couture, qualité, styles, exigences, paie ; commandes réalisables |
```

par :

```markdown
  | `Notation`, `Commandes` | Droit-fil, couture, qualité, styles, exigences, paie, ajustement aux mesures ; commandes réalisables, d'après les goûts de la cliente |
  | `Clientes`, `Progression` | Les six clientes (mesures, tenue, goûts, répliques) et qui vient à la clochette ; amitié, prestige et leurs niveaux |
```

Dans `README.md`, remplacer :

```markdown
  les bruits et la musique ; un module `Ecran…` par étape.
```

par :

```markdown
  les bruits et la musique ; un module `Ecran…` par étape (`EcranMesures` : la silhouette et les rubans).
```

Dans `README.md`, remplacer :

```markdown
  l'ancienne clé `AtelierCouture_v1`) : lue à l'arrivée
```

par :

```markdown
  l'ancienne clé `AtelierCouture_v1` ; partie v3 depuis le plan 5a : prestige, fiches des clientes) : lue à l'arrivée
```

- [ ] **Step 4: Tests, lieu régénéré, commit**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT"`
Expected:
```
Unitaires : 106838 vérifications
TOUT EST VERT : 557 vérifications
```

```bash
C:/dev/jeux/roblox-maker/rojo.exe build -o AtelierCouture.rbxl
git add README.md AtelierCouture.rbxl
git commit -m "Plan 5a terminé : les clientes (mesures, amitié, prestige)

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```
