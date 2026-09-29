# Clientes et progression — Plan 5b : prestige, déblocages et acompte

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Une partie du catalogue fermée au départ, ouverte par le prestige et l'amitié des clientes (grisée avec sa raison, refusée par le serveur), des commandes à la mesure de ce qui est ouvert et de plus en plus exigeantes, l'acompte, la jauge de prestige et l'annonce de ce qui s'ouvre ; un équilibrage vérifié par simulation.

**Architecture:**
- **Données** (partagées) : `Deblocages` porte le tableau de la spec §4 (une condition au plus par élément : un niveau de prestige, ou un niveau d'amitié avec une cliente) et en déduit ce qui est ouvert, la raison d'un élément fermé, ce qu'une livraison vient d'ouvrir. Rien n'est sauvegardé.
- **Règles** (`EtatAtelier`, serveur) : `validerCroquis`, `acheter` et `decorer` refusent ce qui est fermé ; un abandon ne fait jamais perdre un niveau d'amitié ; `Commandes.generer` ne demande que ce qui est ouvert, avec un plafond de style qui monte avec le prestige ; la commande verse un acompte, déduit de la paie ; `livrer` dit ce qui vient de s'ouvrir.
- **Interface** : carnet (variantes, cartes de tissu) et palette des décorations grisés avec la raison ; accueil : jauge de prestige, acompte, niveau atteint et nouveautés.
- **Équilibrage** : un test simule un joueur moyen sur 60 commandes avec les vraies règles.

**Tech Stack:** Luau, Rojo 7.7.0-rc.1, simulation Luau 0.650 (`tests/lancer.sh`), Roblox Studio via le connecteur MCP Studio.

**Spec:** `docs/superpowers/specs/2026-09-29-clientes-progression-design.md` (§4 prestige et déblocages, §7 acompte, §8 vérifications du serveur, §9 interface, §10 tests et équilibrage, §11 plan 5b). Plan précédent : `docs/superpowers/plans/2026-09-30-clientes-plan5a.md`.

## Décisions de ce plan

- **Le tableau des déblocages** (spec §4) : laines au prestige 2, satins au 3, velours au 4, soies au 5 ; ruban noir au 2, dentelle noire au 3 ; les niveaux 2 et 4 d'amitié de chaque cliente ouvrent l'élément de son style (`Clientes.LISTE[…].deblocages`, plan 5a). Tout le reste est ouvert au départ (cotons, lins, huit variantes, six accessoires). La toile de jute arrive au plan 5c.
- **Raisons affichées** : « Prestige 3 », « Amitié d'Hélène : 2 » (élision devant une voyelle ou un h) ; le refus du serveur et le message de l'interface disent « Pas encore ouvert : Jupe ample froncée (Amitié de Colette : 2). ».
- **Un abandon ne fait jamais perdre un niveau d'amitié** (écart assumé à la spec §2, qui dit seulement « jamais sous 0 ») : sinon, ce qu'une amitié a ouvert pourrait se refermer au milieu d'une robe. L'abandon coûte toujours son point, sans descendre sous le seuil du niveau atteint.
- **Commandes** : réalisables avec ce qui est ouvert (variantes, tissus, accessoire demandé) ; le style demandé va jusqu'à 50 au prestige 1, puis 10 de plus par niveau, 80 au plus (`Commandes.plafond`). Une commande anonyme (tests) reste tirée dans tout le catalogue, jusqu'à 70.
- **Acompte** (spec §7) : un quart de la base de la robe la plus simple (quatre pièces), arrondi au-dessous : 18 à 26 pièces d'or. Versé à la commande (après le filet de sécurité), déduit de la paie à la livraison (jamais repris si la paie est plus petite), gardé en cas d'abandon ; le prestige compte toute la paie. Sauvegardé avec la commande (un acompte illisible fait abandonner la commande).
- **Tests existants** : ils ne portent pas sur les déblocages ; `U.commander` ouvre désormais tout le catalogue (prestige 530, amitiés 25) d'un état local, et le scénario ouvre tout sur le serveur après avoir vérifié les grisés du carnet.
- **Interface** : un élément fermé garde sa place, grisé (couleur `ferme`, texte doux, attribut `Ferme`) ; le toucher affiche la raison sous la fenêtre sans rien choisir. Carte de tissu fermée : la raison à la place du prix. Palette des décorations : « Croix d'argent · Amitié d'Inès : 4 ».
- **Accueil** : jauge « Prestige 3 — 62 / 100 » sous la clochette (« au plus haut » au niveau 8) ; après une livraison : « Colette est ravie ! +N pièces d'or (qualité N %). … », puis « Acompte de N déjà reçu · Amitié de Colette : +3 · Prestige : +11 (niveau 3 !) », puis « Nouveau : Jupe ample froncée, les satins (4), Dentelle noire. ». À la clochette : « Colette verse un acompte de N pièces d'or. ».
- **Équilibrage** (spec §10) : le joueur simulé ne fait que des commandes (les robes libres, cadeaux et lettres arrivent aux plans 5c et 5d) ; mesuré pendant la préparation : prestige 2 à la 2e robe, 5 à la 16e, tout ouvert à la 45e, jamais sous 284 pièces d'or, 58 robes livrées sur 60. Aucun réglage n'a eu à changer.
- **Vérifié pendant la préparation** : le plan a été joué entièrement sur un brouillon tiré de `main` ; onze variantes du brouillon (trois refus du serveur, plancher de l'amitié, commandes, acompte, deux grisés, jauge, deux dérèglements de l'équilibrage, ce test seul) échouent chacune sur une vérification qui les garde.

## Global Constraints

- **Dépôt** : `C:\dev\jeux\atelier-couture`, branche `deblocages`, créée depuis `main` (où le plan 5a est fusionné). Selon les règles du commanditaire : la branche testée et relue est fusionnée dans `main` et poussée sur GitHub.
- **Rojo** : `C:/dev/jeux/roblox-maker/rojo.exe`.
- **Contraintes des plans précédents toujours valables** : fins de ligne LF, commits en français terminés par `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`, textes d'au moins 14 px, le serveur fait foi.
- **Contenu original** (spec §1) : aucun nom, texte, son ni image de Dressmaker.
- **Commandes** : tout se joue d'un seul doigt ou à la souris seule.

## Review Focus

- **Client qui s'accorde du prestige ou un élément fermé** (copie locale modifiée, appel direct au serveur). Attendu : le serveur refuse, la copie est réparée. Tests : `29_session_distante`, « prestige modifié chez le client : le serveur refuse, la copie est réparée » ; `28_commande_serveur`, « variante fermée refusée par le serveur », « tissu fermé refusé par le serveur », « achat d'un tissu fermé refusé », « accessoire fermé refusé par le serveur ».
- **Amitié qui redescend après un abandon.** Attendu : ce qui est ouvert le reste. Test : `46_deblocages_etat`, « abandon au seuil du niveau 2 : l'amitié reste à 7, la jupe ample reste ouverte ».
- **Commande d'une nouvelle venue, juste à son seuil de prestige.** Attendu : toujours réalisable avec ce qui est ouvert. Test : `46_deblocages_etat`, « … : commande N réalisable dès son arrivée ».
- **Paie plus petite que l'acompte.** Attendu : rien de plus, rien de repris. Test : `47_acompte`, « acompte plus grand que la paie : rien de plus, rien de repris ».
- **Partie sauvegardée avec un acompte abîmé.** Attendu : la commande est abandonnée, le reste de la partie gardé. Test : `47_acompte`, « acompte illisible (…) : commande abandonnée ».

## Structure des fichiers

| Fichier | Rôle |
|---|---|
| `src/shared/Deblocages.luau` | **Nouveau** : conditions, ouvert, raison, message, nouveautés, résumé |
| `src/shared/Commandes.luau` | Commandes réalisables avec ce qui est ouvert ; plafond de style selon le prestige |
| `src/shared/EtatAtelier.luau` | Refus de ce qui est fermé ; amitié qui ne perd pas de niveau ; acompte ; nouveautés à la livraison |
| `src/server/Sauvegarde.luau` | Acompte vérifié à la relecture |
| `src/client/Atelier/UiKit.luau` | Couleur `ferme`, `griser` |
| `src/client/Atelier/EcranCarnet.luau`, `EcranDecorations.luau` | Éléments fermés grisés, avec leur raison |
| `src/client/Atelier/EcranAccueil.luau` | Jauge de prestige, acompte, nouveautés |
| `tests/build.py` | `U.toutOuvrir` ; `U.commander` ouvre tout |
| `tests/unitaires/45_deblocages.luau`, `46_deblocages_etat.luau`, `47_acompte.luau`, `48_equilibrage.luau` | **Nouveaux** |
| `tests/unitaires/14_…`, `21_…`, `28_…`, `29_…`, `tests/scenario.luau` | Tests complétés |
| `README.md`, `AtelierCouture.rbxl` | État du jeu ; lieu régénéré |

---

### Task 1: Le tableau des déblocages

**Files:**
- Create: `src/shared/Deblocages.luau`
- Create: `tests/unitaires/45_deblocages.luau`

**Interfaces:**
- Consumes: `Catalogue.Tissus`, `Catalogue.Variantes`, `Catalogue.Accessoires`, `Catalogue.variante/tissu/accessoire` ; `Clientes.LISTE[…].deblocages`, `Clientes.get` ; `Progression.niveauPrestige`, `Progression.niveauAmitie` (plan 5a).
- Produces:
  - `Deblocages.PRESTIGE_MATIERES`, `PRESTIGE_ACCESSOIRES`, `GENRES` (`"variantes"`, `"tissus"`, `"accessoires"`), `CONDITIONS[genre][id]` = `{ prestige }` ou `{ cliente, amitie }` ;
  - `Deblocages.nom(genre, id)`, `ouvert(progres, genre, id)` (progres : `{ prestige, clientes = { [id] = { amitie } } }`, l'état de l'atelier convient), `raison(genre, id)`, `ouverts(progres)` (ensembles d'id par genre), `toutOuvert(progres)`, `nouveaux(avant, apres)` (liste de `{ genre, id, nom }`).

- [ ] **Step 1: Écrire les tests**

Créer `tests/unitaires/45_deblocages.luau` :

```lua
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
	local attendu = t.matiere == "coton" or t.matiere == "lin"
	U.verifier((ouverts.tissus[t.id] == true) == attendu, t.id .. " : ouvert au départ seulement en coton ou en lin")
end
U.verifier(#tissusOuverts == 8, "huit tissus au départ")
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
		U.verifier((c.prestige ~= nil) ~= (c.cliente ~= nil), id .. " : une seule condition")
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
local avantAmitie = { prestige = 0, clientes = { colette = { amitie = 6 } } }
local apresAmitie = { prestige = 0, clientes = { colette = { amitie = 7 } } }
local n = Deblocages.nouveaux(avantAmitie, apresAmitie)
U.verifier(#n == 1 and n[1].id == "jupe_ample" and n[1].nom == "Jupe ample froncée", "amitié de Colette au niveau 2 : la jupe ample froncée")

-- Tout ouvert : prestige 5 et amitié 4 avec les six clientes
local tout = { prestige = 170, clientes = {} }
for _, c in ipairs(Clientes.LISTE) do
	tout.clientes[c.id] = { amitie = 18 }
end
U.verifier(Deblocages.toutOuvert(tout), "prestige 5 et six amitiés au niveau 4 : tout est ouvert")
tout.clientes.victoire.amitie = 17
U.verifier(not Deblocages.toutOuvert(tout), "une amitié en retard : pas tout")
U.verifier(not Deblocages.toutOuvert(depart), "au départ : pas tout")
```

- [ ] **Step 2: Lancer les tests, vérifier l'échec**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT|attempt|membre" | head -3`
Expected: échec : une ligne qui finit par `Deblocages n'est pas un membre valide de Folder « Couture »` (le module n'existe pas encore)

- [ ] **Step 3: Écrire le module**

Créer `src/shared/Deblocages.luau` :

```lua
-- Déblocages (sous-projet 2) : ce qui est fermé au départ, et ce qui l'ouvre. Chaque élément du catalogue a au
-- plus une condition : un niveau de prestige, ou un niveau d'amitié avec une cliente. Rien n'est sauvegardé :
-- tout se déduit du prestige et des amitiés (un changement du tableau s'applique aux parties existantes).
local dossier = script.Parent
local Catalogue = require(dossier:WaitForChild("Catalogue"))
local Clientes = require(dossier:WaitForChild("Clientes"))
local Progression = require(dossier:WaitForChild("Progression"))

local Deblocages = {}

-- Prestige qui ouvre chaque matière (cotons et lins sont ouverts au départ) et deux garnitures
Deblocages.PRESTIGE_MATIERES = { laine = 2, satin = 3, velours = 4, soie = 5 }
Deblocages.PRESTIGE_ACCESSOIRES = { ruban_noir = 2, dentelle_noire = 3 }
Deblocages.GENRES = { "variantes", "tissus", "accessoires" }

-- CONDITIONS[genre][id] = { prestige = n } ou { cliente = id, amitie = n } ; absent : ouvert au départ
local CONDITIONS = { variantes = {}, tissus = {}, accessoires = {} }
for _, t in ipairs(Catalogue.Tissus) do
	local niveau = Deblocages.PRESTIGE_MATIERES[t.matiere]
	if niveau then
		CONDITIONS.tissus[t.id] = { prestige = niveau }
	end
end
for id, niveau in pairs(Deblocages.PRESTIGE_ACCESSOIRES) do
	CONDITIONS.accessoires[id] = { prestige = niveau }
end
for _, c in ipairs(Clientes.LISTE) do
	for niveau, d in pairs(c.deblocages) do
		if d.variante then
			CONDITIONS.variantes[d.variante] = { cliente = c.id, amitie = niveau }
		else
			CONDITIONS.accessoires[d.accessoire] = { cliente = c.id, amitie = niveau }
		end
	end
end
Deblocages.CONDITIONS = CONDITIONS

local NOMS = {
	variantes = function(id)
		local v = Catalogue.variante(id)
		return v and v.nom
	end,
	tissus = function(id)
		local t = Catalogue.tissu(id)
		return t and t.nom
	end,
	accessoires = function(id)
		local a = Catalogue.accessoire(id)
		return a and a.nom
	end,
}

-- Le nom affiché d'un élément du catalogue (« Jupe Ample froncée », « Laine bordeaux », « Ruban noir »)
function Deblocages.nom(genre, id)
	local nom = NOMS[genre](id)
	if genre == "variantes" and nom then
		local v = Catalogue.variante(id)
		local suite = utf8.offset(nom, 2)
		local initiale = nom:sub(1, suite - 1)
		initiale = ({ ["À"] = "à", ["É"] = "é" })[initiale] or initiale:lower()
		return ({ corsage = "Corsage", manches = "Manches", col = "Col", jupe = "Jupe" })[v.famille] .. " " .. initiale .. nom:sub(suite)
	end
	return nom or id
end

-- progres : { prestige = points, clientes = { [id] = { amitie = points } } } (l'état de l'atelier convient)
function Deblocages.ouvert(progres, genre, id)
	local c = CONDITIONS[genre][id]
	if not c then
		return true
	end
	if c.prestige then
		return Progression.niveauPrestige(progres.prestige or 0) >= c.prestige
	end
	local fiche = progres.clientes and progres.clientes[c.cliente]
	return Progression.niveauAmitie(fiche and fiche.amitie or 0) >= c.amitie
end

-- « de Colette », « d'Hélène »
local function deCliente(id)
	local prenom = Clientes.get(id).nom:match("^(%S+)")
	local voyelle = prenom:match("^[AEIOUH]") ~= nil or prenom:sub(1, 2) == "É"
	return (voyelle and "d'" or "de ") .. prenom
end

-- Ce qu'il faut pour ouvrir : « Prestige 3 » ou « Amitié d'Hélène : 2 » ; nil si ouvert au départ
function Deblocages.raison(genre, id)
	local c = CONDITIONS[genre][id]
	if not c then
		return nil
	end
	if c.prestige then
		return ("Prestige %d"):format(c.prestige)
	end
	return ("Amitié %s : %d"):format(deCliente(c.cliente), c.amitie)
end

-- Ce qui est ouvert, par genre : { variantes = { [id] = true }, tissus = …, accessoires = … }
function Deblocages.ouverts(progres)
	local out = { variantes = {}, tissus = {}, accessoires = {} }
	for _, v in ipairs(Catalogue.Variantes) do
		out.variantes[v.id] = Deblocages.ouvert(progres, "variantes", v.id) or nil
	end
	for _, t in ipairs(Catalogue.Tissus) do
		out.tissus[t.id] = Deblocages.ouvert(progres, "tissus", t.id) or nil
	end
	for _, a in ipairs(Catalogue.Accessoires) do
		out.accessoires[a.id] = Deblocages.ouvert(progres, "accessoires", a.id) or nil
	end
	return out
end

-- Tout le catalogue est-il ouvert ?
function Deblocages.toutOuvert(progres)
	for _, genre in ipairs(Deblocages.GENRES) do
		for id in pairs(CONDITIONS[genre]) do
			if not Deblocages.ouvert(progres, genre, id) then
				return false
			end
		end
	end
	return true
end

-- Ce qui s'est ouvert entre deux moments (avant, apres : comme pour ouvert) : liste de { genre, id, nom },
-- variantes, puis tissus, puis accessoires, dans l'ordre du catalogue
function Deblocages.nouveaux(avant, apres)
	local out = {}
	local listes = { variantes = Catalogue.Variantes, tissus = Catalogue.Tissus, accessoires = Catalogue.Accessoires }
	for _, genre in ipairs(Deblocages.GENRES) do
		for _, e in ipairs(listes[genre]) do
			if CONDITIONS[genre][e.id] and Deblocages.ouvert(apres, genre, e.id) and not Deblocages.ouvert(avant, genre, e.id) then
				table.insert(out, { genre = genre, id = e.id, nom = Deblocages.nom(genre, e.id) })
			end
		end
	end
	return out
end

return Deblocages
```

- [ ] **Step 4: Lancer les tests**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT"`
Expected:
```
Unitaires : 107013 vérifications
TOUT EST VERT : 558 vérifications
```

- [ ] **Step 5: Commit**

```bash
git add src/shared/Deblocages.luau tests/unitaires/45_deblocages.luau
git commit -m "Déblocages : ce qui est fermé au départ, et ce que le prestige et l'amitié ouvrent

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 2: Le serveur refuse ce qui est fermé ; commandes à la mesure du joueur

**Files:**
- Modify: `src/shared/Commandes.luau` (`realisable(exigences, ouverts)`, `plafond`, `generer(rng, cliente, progres)`)
- Modify: `src/shared/EtatAtelier.luau` (`validerCroquis`, `acheter`, `decorer`, `nouvelleCommande`, amitié)
- Modify: `tests/build.py` (`U.toutOuvrir`, `U.commander`), `tests/unitaires/28_commande_serveur.luau`, `29_session_distante.luau`, `tests/scenario.luau`
- Create: `tests/unitaires/46_deblocages_etat.luau`

**Interfaces:**
- Consumes: `Deblocages.ouvert`, `ouverts`, `nom`, `raison` (tâche 1).
- Produces:
  - refus « Pas encore ouvert : <nom> (<raison>). » de `validerCroquis` (variantes puis tissus), `acheter`, `decorer` ;
  - `Commandes.plafond(niveauPrestige)` = min(8, 4 + niveau) ; `Commandes.realisable(exigences, ouverts?)` ; `Commandes.generer(rng, cliente?, progres?)` ;
  - `EtatAtelier:nouvelleCommande` tire la commande avec `self` pour progrès ;
  - l'amitié ne descend jamais sous le seuil du niveau atteint ;
  - tests : `U.toutOuvrir(etat)` ; `U.commander` ouvre tout (hors session distante).

- [ ] **Step 1: Écrire les tests**

Dans `tests/build.py`, remplacer :

```python
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

par :

```python
-- Ouvre tout le catalogue d'un état de l'atelier (prestige et amitiés au plus haut) : pour les tests qui ne
-- portent pas sur les déblocages
function U.toutOuvrir(etat)
	etat.prestige = 530
	for _, c in ipairs(U.module("Clientes").LISTE) do
		local fiche = etat.clientes[c.id] or { amitie = 0, vues = 0, derniere = 0 }
		fiche.amitie = math.max(fiche.amitie, 25)
		etat.clientes[c.id] = fiche
	end
end
-- Passe une commande (état de l'atelier ou session) et prend les mesures exactes de la cliente ; hors session
-- distante (où le serveur fait foi), tout le catalogue est ouvert : la plupart des tests commencent au carnet
function U.commander(x, ...)
	local r = x:nouvelleCommande(...)
	if r.ok then
		local etat = x.etat or x
		if not x.remote then
			U.toutOuvrir(etat)
		end
		x:mesurer(U.module("Clientes").get(etat.commande.cliente).mesures)
	end
	return r
end
```

Dans `tests/unitaires/28_commande_serveur.luau`, remplacer :

```lua
-- Un croquis avec un champ en trop : seules les quatre familles sont gardées sur le serveur (et renvoyées)
```

par :

```lua
-- Déblocages (sous-projet 2) : le serveur refuse une variante ou un tissu encore fermés
local fermee = table.clone(CROQUIS)
fermee.jupe = "jupe_evasee"
local tissusFermee = { corsage_droit_devant = "coton_blanc", corsage_droit_dos = "coton_blanc", jupe_evasee_devant = "coton_blanc", jupe_evasee_dos = "coton_blanc" }
r = appeler(joueur, "validerCroquis", fermee, tissusFermee)
U.verifier(not r.ok and r.erreur == "Pas encore ouvert : Jupe longue évasée (Amitié de Victoire : 2)." and etatDe(joueur).etape == "carnet", "variante fermée refusée par le serveur")
local enSoie = table.clone(tissus)
enSoie.jupe_droite_dos = "soie_rouge"
r = appeler(joueur, "validerCroquis", CROQUIS, enSoie)
U.verifier(not r.ok and r.erreur == "Pas encore ouvert : Soie rouge (Prestige 5)." and etatDe(joueur).etape == "carnet", "tissu fermé refusé par le serveur")
-- Un croquis avec un champ en trop : seules les quatre familles sont gardées sur le serveur (et renvoyées)
```

Dans `tests/unitaires/28_commande_serveur.luau`, remplacer :

```lua
etatDe(joueur).argent = 5
r = appeler(joueur, "acheter", "soie_rouge", 100)
```

par :

```lua
r = appeler(joueur, "acheter", "soie_rouge", 5)
U.verifier(not r.ok and r.erreur == "Pas encore ouvert : Soie rouge (Prestige 5)." and etatDe(joueur).stock.soie_rouge == nil, "achat d'un tissu fermé refusé")
etatDe(joueur).argent = 5
r = appeler(joueur, "acheter", "lin_noir", 100)
```

Dans `tests/unitaires/28_commande_serveur.luau`, remplacer :

```lua
U.verifier(appeler(joueur, "decorer", {}).ok, "robe présentée")
```

par :

```lua
r = appeler(joueur, "decorer", { { id = "croix_argent", piece = 1, copie = "unique", u = 0.5, v = 0.5, echelle = 1, angle = 0 } })
U.verifier(not r.ok and r.erreur == "Pas encore ouvert : Croix d'argent (Amitié d'Inès : 4)." and etatDe(joueur).etape == "decorations", "accessoire fermé refusé par le serveur")
U.verifier(appeler(joueur, "decorer", {}).ok, "robe présentée")
```

Dans `tests/unitaires/29_session_distante.luau`, remplacer :

```lua
r = session:acheter("soie_rouge", 100)
U.verifier(not r.ok and r.erreur == "Pas assez d'argent.", "argent modifié chez le client : le serveur refuse quand même")
```

par :

```lua
r = session:acheter("lin_noir", 100)
U.verifier(not r.ok and r.erreur == "Pas assez d'argent.", "argent modifié chez le client : le serveur refuse quand même")
session.etat.prestige = 530
M.avancer(1)
r = session:acheter("soie_rouge", 1)
U.verifier(not r.ok and r.erreur == "Pas encore ouvert : Soie rouge (Prestige 5)." and session.etat.prestige == 0, "prestige modifié chez le client : le serveur refuse, la copie est réparée")
```

Dans `tests/scenario.luau`, remplacer :

```lua
verifier(titre() == "1. Carnet de croquis", "mesures prises : le carnet")
verifierTailles("carnet")
```

par :

```lua
verifier(titre() == "1. Carnet de croquis", "mesures prises : le carnet")
-- Pour la suite, une couturière confirmée : tout le catalogue ouvert (prestige et amitiés au plus haut)
local etatServeur = serveur:atelier(joueur).etat
etatServeur.prestige = 530
for _, c in ipairs(Clientes.LISTE) do
	etatServeur.clientes[c.id] = etatServeur.clientes[c.id] or { amitie = 0, vues = 0, derniere = 0 }
	etatServeur.clientes[c.id].amitie = 25
end
requireModule(scriptClient.Session).courante:actualiser()
verifier(requireModule(scriptClient.Session).courante.etat.prestige == 530, "la copie du client suit le serveur")
verifierTailles("carnet")
```

Créer `tests/unitaires/46_deblocages_etat.luau` :

```lua
local EtatAtelier = U.module("EtatAtelier")
local Clientes = U.module("Clientes")
local Commandes = U.module("Commandes")
local Deblocages = U.module("Deblocages")
local Catalogue = U.module("Catalogue")

-- Commandes d'un débutant : jamais d'accessoire fermé, un style demandé à 50 au plus, toujours réalisables
-- avec ce qui est ouvert
for n = 1, 30 do
	local e = EtatAtelier.nouveau(1000)
	e.visites, e.clientes.colette = n, { amitie = 0, vues = 1, derniere = n }
	local r = e:nouvelleCommande(Random.new(n))
	local ouverts = Deblocages.ouverts(e)
	U.verifier(r.ok and Commandes.realisable(e.commande.exigences, ouverts), "commande " .. n .. " réalisable avec le catalogue du départ")
	for _, x in ipairs(e.commande.exigences) do
		U.verifier(x.type ~= "min" or x.valeur <= 50, "commande " .. n .. " : style demandé à 50 au plus au prestige 1")
		U.verifier(x.type ~= "accessoire" or ouverts.accessoires[x.id], "commande " .. n .. " : accessoire demandé ouvert")
	end
end
U.verifier(Commandes.plafond(1) == 5 and Commandes.plafond(2) == 6 and Commandes.plafond(4) == 8 and Commandes.plafond(8) == 8, "exigences de style : jusqu'à 50 au prestige 1, 80 au plus à partir du prestige 4")
U.verifier(not Commandes.realisable({ { type = "accessoire", id = "croix_argent" } }, Deblocages.ouverts({ prestige = 0, clientes = {} })), "un accessoire fermé : commande irréalisable")
U.verifier(Commandes.realisable({ { type = "accessoire", id = "croix_argent" } }), "sans restriction : réalisable")

-- Chaque cliente, dès son arrivée (son prestige atteint) : ses commandes sont réalisables avec ce qui est ouvert
local SEUILS = { 0, 20, 50, 100 }
for _, c in ipairs(Clientes.LISTE) do
	local progres = { prestige = SEUILS[c.prestige], clientes = {} }
	local ouverts = Deblocages.ouverts(progres)
	local rng = Random.new(3)
	for n = 1, 20 do
		local commande = Commandes.generer(rng, c, progres)
		U.verifier(Commandes.realisable(commande.exigences, ouverts), c.id .. " : commande " .. n .. " réalisable dès son arrivée")
	end
end

-- Le carnet refuse une variante ou un tissu fermés ; l'amitié les ouvre
local e = EtatAtelier.nouveau(1000)
e:nouvelleCommande(Random.new(1))
e:mesurer(Clientes.get("colette").mesures)
local CROQUIS = { corsage = "corsage_droit", manches = "manches_sans", col = "col_sans", jupe = "jupe_ample" }
local tissus = { corsage_droit_devant = "coton_blanc", corsage_droit_dos = "coton_blanc", jupe_ample_devant = "coton_blanc", jupe_ample_dos = "coton_blanc" }
local r = e:validerCroquis(CROQUIS, tissus)
U.verifier(not r.ok and r.erreur == "Pas encore ouvert : Jupe ample froncée (Amitié de Colette : 2)." and e.etape == "carnet", "jupe ample fermée au départ")
e.clientes.colette.amitie = 7
U.verifier(e:validerCroquis(CROQUIS, tissus).ok, "amitié de Colette au niveau 2 : la jupe ample s'ouvre")
r = e:acheter("velours_noir", 5)
U.verifier(not r.ok and r.erreur == "Pas encore ouvert : Velours noir (Prestige 4)." and e.stock.velours_noir == nil, "velours fermé au prestige 1")
e.prestige = 100
U.verifier(e:acheter("velours_noir", 5).ok, "prestige 4 : le velours s'achète")

-- Un abandon ne fait pas perdre un niveau d'amitié : ce qu'il a ouvert reste ouvert
e.etape = "refus"
r = e:abandonner()
U.verifier(r.ok and e.clientes.colette.amitie == 7 and r.amitie.gain == 0 and Deblocages.ouvert(e, "variantes", "jupe_ample"), "abandon au seuil du niveau 2 : l'amitié reste à 7, la jupe ample reste ouverte")

-- Les décorations fermées sont refusées
local d = EtatAtelier.nouveau(1000)
U.commander(d, Random.new(2))
d.prestige, d.clientes.ines.amitie = 0, 0
d.etape = "decorations"
d.croquis = { corsage = "corsage_droit", manches = "manches_sans", col = "col_sans", jupe = "jupe_droite" }
d.tissus = { corsage_droit_devant = "coton_blanc", corsage_droit_dos = "coton_blanc", jupe_droite_devant = "coton_blanc", jupe_droite_dos = "coton_blanc" }
for id in pairs(d.tissus) do
	d.coupees[id] = { x = 0, y = 0, angle = 0 }
	d.epinglees[id] = true
	d.coutures[id] = 1
end
local croix = { { id = "croix_argent", piece = 1, copie = "unique", u = 0.5, v = 0.5, echelle = 1, angle = 0 } }
r = d:decorer(croix)
U.verifier(not r.ok and r.erreur == "Pas encore ouvert : Croix d'argent (Amitié d'Inès : 4)." and d.etape == "decorations", "croix d'argent fermée sans l'amitié d'Inès")
d.clientes.ines.amitie = 18
U.verifier(d:decorer(croix).ok, "amitié d'Inès au niveau 4 : la croix se pose")
U.verifier(Catalogue.accessoire("croix_argent") ~= nil, "(la croix existe)")
```

- [ ] **Step 2: Lancer les tests, vérifier l'échec**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT|attempt|membre" | head -3`
Expected: échec : une ligne qui finit par `ÉCHEC : variante fermée refusée par le serveur`

- [ ] **Step 3: Écrire le code**

Dans `src/shared/Commandes.luau`, remplacer :

```lua
-- Commandes : génère des commandes, toujours réalisables avec le catalogue. Celle d'une cliente (sous-projet 2)
-- vient de ses goûts : un de ses styles, sa teinte, jamais un « au plus » dans ses styles.
```

par :

```lua
-- Commandes : génère des commandes, toujours réalisables avec le catalogue. Celle d'une cliente (sous-projet 2)
-- vient de ses goûts : un de ses styles, sa teinte, jamais un « au plus » dans ses styles ; elle est réalisable
-- avec ce que le joueur a ouvert (déblocages), et ses exigences de style montent avec son prestige.
```

Dans `src/shared/Commandes.luau`, remplacer :

```lua
local Notation = require(dossier:WaitForChild("Notation"))
```

par :

```lua
local Notation = require(dossier:WaitForChild("Notation"))
local Deblocages = require(dossier:WaitForChild("Deblocages"))
local Progression = require(dossier:WaitForChild("Progression"))
```

Dans `src/shared/Commandes.luau`, remplacer :

```lua
-- Cherche une robe simple (un seul tissu, au plus l'accessoire imposé) qui remplit les exigences.
-- La qualité est supposée atteignable (≤ 0,9). Retourne ok et le témoin { croquis, tissu, accessoire }.
function Commandes.realisable(exigences)
```

par :

```lua
-- Cherche une robe simple (un seul tissu, au plus l'accessoire imposé) qui remplit les exigences.
-- La qualité est supposée atteignable (≤ 0,9). ouverts (facultatif, Deblocages.ouverts) : seulement avec ce
-- qui est ouvert. Retourne ok et le témoin { croquis, tissu, accessoire }.
function Commandes.realisable(exigences, ouverts)
```

Dans `src/shared/Commandes.luau`, remplacer :

```lua
	local accessoires = accessoireImpose and { { id = accessoireImpose } } or {}
```

par :

```lua
	if ouverts and accessoireImpose and not ouverts.accessoires[accessoireImpose] then
		return false
	end
	local accessoires = accessoireImpose and { { id = accessoireImpose } } or {}
```

Dans `src/shared/Commandes.luau`, remplacer :

```lua
	for _, croquis in ipairs(CROQUIS) do
		for _, t in ipairs(Catalogue.Tissus) do
			local bilan = {
```

par :

```lua
	for _, croquis in ipairs(CROQUIS) do
		for _, t in ipairs(Catalogue.Tissus) do
			local permis = not ouverts
				or (ouverts.tissus[t.id] and ouverts.variantes[croquis.corsage] and ouverts.variantes[croquis.manches] and ouverts.variantes[croquis.col] and ouverts.variantes[croquis.jupe])
			local bilan = permis and {
```

Dans `src/shared/Commandes.luau`, remplacer :

```lua
			if Notation.verifierExigences(exigences, bilan) then
```

par :

```lua
			if bilan and Notation.verifierExigences(exigences, bilan) then
```

Dans `src/shared/Commandes.luau`, remplacer :

```lua
local function tirerExigences(rng, cliente)
	local exigences = {}
	local styleMin = tirer(cliente and cliente.styles or Catalogue.STYLES, rng)
	table.insert(exigences, { type = "min", style = styleMin, valeur = rng:NextInteger(3, 7) * 10 })
```

par :

```lua
-- plafond : dizaines de points au plus pour le style demandé (monte avec le prestige) ; ouverts : accessoires
-- qu'on peut demander (nil : tous)
local function tirerExigences(rng, cliente, plafond, ouverts)
	local exigences = {}
	local styleMin = tirer(cliente and cliente.styles or Catalogue.STYLES, rng)
	table.insert(exigences, { type = "min", style = styleMin, valeur = rng:NextInteger(3, plafond) * 10 })
```

Dans `src/shared/Commandes.luau`, remplacer :

```lua
				if a.genre == "objet" then
```

par :

```lua
				if a.genre == "objet" and (not ouverts or ouverts.accessoires[a.id]) then
```

Dans `src/shared/Commandes.luau`, remplacer :

```lua
-- rng : un objet Random ; cliente (facultatif) : une fiche de Clientes. Retourne { taille, mesures, exigences }
-- (anonyme), ou { cliente, taille, exigences } : ses mesures seront prises à l'atelier.
function Commandes.generer(rng, cliente)
	local exigences
	for _ = 1, ESSAIS do
		local candidat = tirerExigences(rng, cliente)
		if Commandes.realisable(candidat) then
```

par :

```lua
-- Dizaines de points au plus pour le style demandé : 5 au prestige 1, puis une de plus par niveau, 8 au plus
function Commandes.plafond(niveauPrestige)
	return math.min(8, 4 + niveauPrestige)
end

-- rng : un objet Random ; cliente (facultatif) : une fiche de Clientes ; progres (facultatif) : le prestige et
-- les amitiés du joueur (l'état de l'atelier convient). Retourne { taille, mesures, exigences } (anonyme), ou
-- { cliente, taille, exigences } : ses mesures seront prises à l'atelier.
function Commandes.generer(rng, cliente, progres)
	local ouverts = progres and Deblocages.ouverts(progres)
	local plafond = progres and Commandes.plafond(Progression.niveauPrestige(progres.prestige)) or 7
	local exigences
	for _ = 1, ESSAIS do
		local candidat = tirerExigences(rng, cliente, plafond, ouverts)
		if Commandes.realisable(candidat, ouverts) then
```

Dans `src/shared/EtatAtelier.luau`, remplacer :

```lua
local Progression = require(dossier:WaitForChild("Progression"))
```

par :

```lua
local Progression = require(dossier:WaitForChild("Progression"))
local Deblocages = require(dossier:WaitForChild("Deblocages"))
```

Dans `src/shared/EtatAtelier.luau`, remplacer :

```lua
local function fini(n)
```

par :

```lua
-- Refus du premier élément encore fermé (déblocages : prestige ou amitié), ou nil
local function fermes(self, genre, ids)
	for _, id in ipairs(ids) do
		if not Deblocages.ouvert(self, genre, id) then
			return refus(("Pas encore ouvert : %s (%s)."):format(Deblocages.nom(genre, id), Deblocages.raison(genre, id)))
		end
	end
	return nil
end

local function fini(n)
```

Dans `src/shared/EtatAtelier.luau`, remplacer :

```lua
	self.commande = Commandes.generer(rng, Clientes.get(id))
```

par :

```lua
	self.commande = Commandes.generer(rng, Clientes.get(id), self)
```

Dans `src/shared/EtatAtelier.luau`, remplacer :

```lua
		choix[id] = t
	end
	-- Seules les quatre familles sont gardées
```

par :

```lua
		choix[id] = t
	end
	local variantes, tissusChoisis = {}, {}
	for _, famille in ipairs(Catalogue.FAMILLES) do
		table.insert(variantes, croquis[famille])
	end
	for _, id in ipairs(pieces) do
		table.insert(tissusChoisis, choix[id])
	end
	local ferme = fermes(self, "variantes", variantes) or fermes(self, "tissus", tissusChoisis)
	if ferme then
		return ferme
	end
	-- Seules les quatre familles sont gardées
```

Dans `src/shared/EtatAtelier.luau`, remplacer :

```lua
	if not fini(dm) or dm ~= math.floor(dm) or dm < 1 or dm > EtatAtelier.ACHAT_MAX then
		return refus("Longueur invalide.")
	end
	local prix = EtatAtelier.prix(idTissu, dm)
```

par :

```lua
	if not fini(dm) or dm ~= math.floor(dm) or dm < 1 or dm > EtatAtelier.ACHAT_MAX then
		return refus("Longueur invalide.")
	end
	local ferme = fermes(self, "tissus", { idTissu })
	if ferme then
		return ferme
	end
	local prix = EtatAtelier.prix(idTissu, dm)
```

Dans `src/shared/EtatAtelier.luau`, remplacer :

```lua
	local ok, erreur = Recette.valider(recette)
	if not ok then
		return refus(erreur)
	end
	local propres = {}
	for i, a in ipairs(liste) do
```

par :

```lua
	local ok, erreur = Recette.valider(recette)
	if not ok then
		return refus(erreur)
	end
	local ids = {}
	for _, a in ipairs(liste) do
		table.insert(ids, a.id)
	end
	local ferme = fermes(self, "accessoires", ids)
	if ferme then
		return ferme
	end
	local propres = {}
	for i, a in ipairs(liste) do
```

Dans `src/shared/EtatAtelier.luau`, remplacer :

```lua
-- L'amitié de la cliente de la commande change (robe acceptée ou abandonnée) ; renvoie le détail pour le bilan
```

par :

```lua
-- L'amitié de la cliente de la commande change (robe acceptée ou abandonnée) ; renvoie le détail pour le bilan.
-- Un abandon ne fait jamais perdre un niveau : ce qu'il a ouvert reste ouvert
```

Dans `src/shared/EtatAtelier.luau`, remplacer :

```lua
	fiche.amitie = math.max(0, avant + Progression.gainAmitie(reussie, qualite))
```

par :

```lua
	local plancher = Progression.SEUILS_AMITIE[Progression.niveauAmitie(avant) + 1]
	fiche.amitie = math.max(plancher, avant + Progression.gainAmitie(reussie, qualite))
```

- [ ] **Step 4: Lancer les tests**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT"`
Expected:
```
Unitaires : 107297 vérifications
TOUT EST VERT : 559 vérifications
```

- [ ] **Step 5: Commit**

```bash
git add src/shared/Commandes.luau src/shared/EtatAtelier.luau tests/build.py tests/unitaires/28_commande_serveur.luau tests/unitaires/29_session_distante.luau tests/unitaires/46_deblocages_etat.luau tests/scenario.luau
git commit -m "Déblocages vérifiés par le serveur ; commandes à la mesure de ce qui est ouvert ; un abandon ne fait pas perdre un niveau d'amitié

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 3: L'acompte

**Files:**
- Modify: `src/shared/EtatAtelier.luau` (`ACOMPTE`, `PIECES_ACOMPTE`, `nouvelleCommande`, `livrer`)
- Modify: `src/server/Sauvegarde.luau` (`commandeLisible`)
- Modify: `tests/unitaires/14_etat_atelier.luau`, `21_decorations_livraison.luau`
- Create: `tests/unitaires/47_acompte.luau`

**Interfaces:**
- Consumes: `Notation.base(nbPieces, nbExigences)`.
- Produces:
  - `EtatAtelier.ACOMPTE = 0.25`, `EtatAtelier.PIECES_ACOMPTE = 4` ; `commande.acompte` ;
  - `nouvelleCommande` → en plus `acompte` ; `livrer` réussi → en plus `acompte` et `verse` (= max(0, paie − acompte), ce qui entre dans la caisse).

- [ ] **Step 1: Écrire les tests**

Dans `tests/unitaires/14_etat_atelier.luau`, remplacer :

```lua
U.verifier(not e:nouvelleCommande(Random.new(4)).ok, "une seule commande à la fois")
local pauvre = EtatAtelier.nouveau(3)
U.commander(pauvre, Random.new(1))
U.verifier(pauvre.argent == EtatAtelier.FILET, "filet de sécurité : au moins 20 pièces d'or")
```

par :

```lua
U.verifier(not e:nouvelleCommande(Random.new(4)).ok, "une seule commande à la fois")
local depart = 150 + e.commande.acompte -- (l'acompte de la cliente)
local pauvre = EtatAtelier.nouveau(3)
U.commander(pauvre, Random.new(1))
U.verifier(pauvre.argent == EtatAtelier.FILET + pauvre.commande.acompte, "filet de sécurité : au moins 20 pièces d'or (puis l'acompte)")
```

Dans `tests/unitaires/14_etat_atelier.luau`, remplacer :

```lua
U.verifier(achat.ok and achat.prix == 5 and e.argent == 145 and e.stock.coton_blanc == 12, "achat : argent débité, stock crédité")
U.verifier(e:acheter("soie_rouge", 6).ok and e.argent == 145 - 10, "deuxième tissu acheté")
```

par :

```lua
U.verifier(achat.ok and achat.prix == 5 and e.argent == depart - 5 and e.stock.coton_blanc == 12, "achat : argent débité, stock crédité")
U.verifier(e:acheter("soie_rouge", 6).ok and e.argent == depart - 5 - 10, "deuxième tissu acheté")
```

Dans `tests/unitaires/14_etat_atelier.luau`, remplacer :

```lua
local e4 = EtatAtelier.nouveau(20)
U.commander(e4, Random.new(7))
```

par :

```lua
local e4 = EtatAtelier.nouveau(20)
U.commander(e4, Random.new(7))
e4.argent = 20 -- (sans l'acompte)
```

Dans `tests/unitaires/14_etat_atelier.luau`, remplacer :

```lua
U.verifier(not e:acheter("soie_rouge", 100).ok, "pas assez d'argent")
```

par :

```lua
U.verifier(not e:acheter("satin_or_degrade", 100).ok, "pas assez d'argent (180 po)")
```

Dans `tests/unitaires/21_decorations_livraison.luau`, remplacer :

```lua
U.verifier(r.ok and r.reussie and r.paie == paie and e.argent == avant - 3 + paie, "robe acceptée : paie = base × (0,5 + qualité)")
```

par :

```lua
U.verifier(r.ok and r.reussie and r.paie == paie and r.verse == paie - r.acompte and e.argent == avant - 3 + r.verse, "robe acceptée : paie = base × (0,5 + qualité), moins l'acompte")
```

Créer `tests/unitaires/47_acompte.luau` :

```lua
local EtatAtelier = U.module("EtatAtelier")
local Notation = U.module("Notation")
local Clientes = U.module("Clientes")
local Sauvegarde = U.module("Sauvegarde")

-- Une robe simple, coupée, épinglée et cousue : prête à présenter
local function robePrete(etat)
	etat.croquis = { corsage = "corsage_droit", manches = "manches_sans", col = "col_sans", jupe = "jupe_droite" }
	etat.tissus = { corsage_droit_devant = "coton_blanc", corsage_droit_dos = "coton_blanc", jupe_droite_devant = "coton_blanc", jupe_droite_dos = "coton_blanc" }
	for id in pairs(etat.tissus) do
		etat.coupees[id] = { x = 0, y = 0, angle = 0 }
		etat.epinglees[id] = true
		etat.coutures[id] = 1
	end
	etat.etape = "decorations"
	etat:decorer({})
	etat.commande.exigences = { { type = "qualite", valeur = 0.1 } }
end

-- La cliente passe commande : un acompte d'un quart de la base de la robe la plus simple, versé tout de suite
local e = EtatAtelier.nouveau(100)
local r = e:nouvelleCommande(Random.new(1))
local acompte = math.floor(0.25 * Notation.base(4, #e.commande.exigences))
U.verifier(r.ok and r.acompte == acompte and e.commande.acompte == acompte and e.argent == 100 + acompte, "acompte d'un quart de la base, versé à la commande (" .. acompte .. " po)")
U.verifier(acompte >= 18 and acompte <= 26, "un acompte de 18 à 26 pièces d'or")
local pauvre = EtatAtelier.nouveau(0)
pauvre:nouvelleCommande(Random.new(2))
U.verifier(pauvre.argent == EtatAtelier.FILET + pauvre.commande.acompte, "le filet de sécurité, puis l'acompte")

-- Robe livrée : la paie, moins l'acompte déjà reçu ; le prestige compte toute la paie
e:mesurer(Clientes.get("colette").mesures)
robePrete(e)
local avant = e.argent
r = e:livrer()
U.verifier(r.ok and r.reussie and r.acompte == acompte and r.verse == r.paie - acompte and e.argent == avant + r.paie - acompte, "livrée : paie moins l'acompte (" .. r.paie .. " − " .. acompte .. ")")
U.verifier(r.prestige.gain == math.floor(r.paie / 10 + 0.5), "le prestige compte toute la paie")

-- Abandon : l'acompte est gardé
pauvre:mesurer(Clientes.get("colette").mesures)
pauvre.etape = "refus"
local argentPauvre = pauvre.argent
U.verifier(pauvre:abandonner().ok and pauvre.argent == argentPauvre, "abandon : l'acompte reste dans la caisse")

-- Paie plus petite que l'acompte (robe bâclée) : rien de plus, rien de repris
local bacle = EtatAtelier.nouveau(0)
bacle:nouvelleCommande(Random.new(3))
bacle.commande.acompte = 999
bacle:mesurer(Clientes.get("colette").mesures)
robePrete(bacle)
local avantBacle = bacle.argent
r = bacle:livrer()
U.verifier(r.ok and r.verse == 0 and bacle.argent == avantBacle, "acompte plus grand que la paie : rien de plus, rien de repris")

-- Sauvegarde : l'acompte suit la commande ; un acompte illisible fait abandonner la commande
local enCours = EtatAtelier.nouveau(100)
enCours:nouvelleCommande(Random.new(4))
enCours:mesurer(Clientes.get("colette").mesures)
local relue = Sauvegarde.versEtat(M.transmettre(Sauvegarde.depuisEtat(enCours)))
U.verifier(relue.commande ~= nil and relue.commande.acompte == enCours.commande.acompte, "l'acompte est sauvegardé avec la commande")
for _, cas in ipairs({ { "acompte", -3 }, { "acompte", 2.5 }, { "acompte", "x" }, { "acompte", 1e9 } }) do
	local p = M.transmettre(Sauvegarde.depuisEtat(enCours))
	p.enCours.commande[cas[1]] = cas[2]
	local r2 = Sauvegarde.versEtat(p)
	U.verifier(r2.etape == "accueil" and r2.commande == nil, cas[1] .. " illisible (" .. tostring(cas[2]) .. ") : commande abandonnée")
end
```

- [ ] **Step 2: Lancer les tests, vérifier l'échec**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT|attempt|membre" | head -3`
Expected: échec : une ligne qui finit par `attempt to perform arithmetic (add) on number and nil` (la commande n'a pas encore d'acompte)

- [ ] **Step 3: Écrire le code**

Dans `src/shared/EtatAtelier.luau`, remplacer :

```lua
EtatAtelier.FILET = 20 -- argent minimal garanti à chaque nouvelle commande
```

par :

```lua
EtatAtelier.FILET = 20 -- argent minimal garanti à chaque nouvelle commande
EtatAtelier.ACOMPTE = 0.25 -- part de la base versée quand la cliente passe commande
EtatAtelier.PIECES_ACOMPTE = 4 -- la base de l'acompte est celle de la robe la plus simple (quatre pièces)
```

Dans `src/shared/EtatAtelier.luau`, remplacer :

```lua
	self.commande.numero = self.visites -- la reconnaît d'une copie à l'autre (la scène garde la même cliente)
	self.argent = math.max(self.argent, EtatAtelier.FILET)
```

par :

```lua
	self.commande.numero = self.visites -- la reconnaît d'une copie à l'autre (la scène garde la même cliente)
	-- L'acompte : un quart de la base, versé tout de suite, déduit de la paie ; gardé en cas d'abandon
	local acompte = math.floor(EtatAtelier.ACOMPTE * Notation.base(EtatAtelier.PIECES_ACOMPTE, #self.commande.exigences))
	self.commande.acompte = acompte
	self.argent = math.max(self.argent, EtatAtelier.FILET) + acompte
```

Dans `src/shared/EtatAtelier.luau`, remplacer :

```lua
	return { ok = true, commande = self.commande, cliente = id, premiereVisite = fiche.vues == 1 }
```

par :

```lua
	return { ok = true, commande = self.commande, cliente = id, premiereVisite = fiche.vues == 1, acompte = acompte }
```

Dans `src/shared/EtatAtelier.luau`, remplacer :

```lua
	local paie = Notation.paie(#recette.pieces, #self.commande.exigences, bilan.qualite)
	self.argent += paie
```

par :

```lua
	local paie = Notation.paie(#recette.pieces, #self.commande.exigences, bilan.qualite)
	local acompte = self.commande.acompte or 0
	local verse = math.max(0, paie - acompte) -- l'acompte est déjà dans la caisse
	self.argent += verse
```

Dans `src/shared/EtatAtelier.luau`, remplacer :

```lua
	return { ok = true, reussie = true, paie = paie, bilan = bilan, ratees = {}, amitie = gainAmitie, prestige = prestige }
```

par :

```lua
	return { ok = true, reussie = true, paie = paie, acompte = acompte, verse = verse, bilan = bilan, ratees = {}, amitie = gainAmitie, prestige = prestige }
```

Dans `src/server/Sauvegarde.luau`, remplacer :

```lua
-- ajustement entre 50 et 100 %, 1 à 3 exigences lisibles
local function commandeLisible(c, etape)
```

par :

```lua
-- ajustement entre 50 et 100 %, acompte entier et raisonnable, 1 à 3 exigences lisibles
local function commandeLisible(c, etape)
```

Dans `src/server/Sauvegarde.luau`, remplacer :

```lua
	if c.ajustement ~= nil and not (nombre(c.ajustement, nil) and c.ajustement >= 0.5 and c.ajustement <= 1) then
		return false
	end
```

par :

```lua
	if c.ajustement ~= nil and not (nombre(c.ajustement, nil) and c.ajustement >= 0.5 and c.ajustement <= 1) then
		return false
	end
	if c.acompte ~= nil and not (nombre(c.acompte, nil) and c.acompte == math.floor(c.acompte) and c.acompte >= 0 and c.acompte <= 1000) then
		return false
	end
```

- [ ] **Step 4: Lancer les tests**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT"`
Expected:
```
Unitaires : 107309 vérifications
TOUT EST VERT : 559 vérifications
```

- [ ] **Step 5: Commit**

```bash
git add src/shared/EtatAtelier.luau src/server/Sauvegarde.luau tests/unitaires/14_etat_atelier.luau tests/unitaires/21_decorations_livraison.luau tests/unitaires/47_acompte.luau
git commit -m "Acompte : versé à la commande, déduit de la paie, gardé à l'abandon

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 4: Grisés, jauge de prestige, annonces

**Files:**
- Modify: `src/shared/Deblocages.luau` (`message`, `resume`)
- Modify: `src/shared/EtatAtelier.luau` (`livrer` → `nouveaux`)
- Modify: `src/client/Atelier/UiKit.luau` (`COULEURS.ferme`, `griser`)
- Modify: `src/client/Atelier/EcranCarnet.luau`, `EcranDecorations.luau`, `EcranAccueil.luau`
- Modify: `tests/unitaires/45_deblocages.luau`, `47_acompte.luau`, `tests/scenario.luau`

**Interfaces:**
- Consumes: `Deblocages.*` (tâche 1) ; `acompte`, `verse` (tâche 3).
- Produces:
  - `Deblocages.message(genre, id)` ; `Deblocages.resume(nouveaux)` (« Jupe ample froncée, les satins (4), Dentelle noire ») ;
  - `livrer` réussi → en plus `nouveaux` ;
  - `UiKit.COULEURS.ferme`, `UiKit.griser(bouton, ferme)` (attribut `Ferme`) ;
  - carnet : cartes de tissu fermées avec un texte `Raison` ; accueil : texte `Prestige` et cadre `JaugePrestige` (enfant `Rempli`).

- [ ] **Step 1: Écrire les tests**

Dans `tests/unitaires/45_deblocages.luau`, remplacer :

```lua
U.verifier(#Deblocages.nouveaux(au(50), au(99)) == 0, "rien de neuf sans changer de niveau")
```

par :

```lua
U.verifier(#Deblocages.nouveaux(au(50), au(99)) == 0, "rien de neuf sans changer de niveau")
U.verifier(Deblocages.resume(nouveaux) == "les satins (4), Dentelle noire", "en une ligne : les satins ensemble (" .. Deblocages.resume(nouveaux) .. ")")
U.verifier(Deblocages.message("tissus", "soie_rouge") == "Pas encore ouvert : Soie rouge (Prestige 5).", "le refus dit ce qu'il faut pour ouvrir")
```

Dans `tests/unitaires/47_acompte.luau`, remplacer :

```lua
-- Abandon : l'acompte est gardé
```

par :

```lua
-- Ce que la livraison a ouvert (prestige 3 atteint, amitié de Colette au niveau 2)
local Deblocages = U.module("Deblocages")
local ouvre = EtatAtelier.nouveau(100)
ouvre:nouvelleCommande(Random.new(5))
ouvre:mesurer(Clientes.get("colette").mesures)
ouvre.prestige, ouvre.clientes.colette.amitie = 45, 6
robePrete(ouvre)
r = ouvre:livrer()
U.verifier(r.ok and r.reussie and ouvre.prestige >= 50 and Deblocages.resume(r.nouveaux) == "Jupe ample froncée, les satins (4), Dentelle noire", "livrée : ce qui vient de s'ouvrir (" .. Deblocages.resume(r.nouveaux or {}) .. ")")

-- Abandon : l'acompte est gardé
```

Dans `tests/scenario.luau`, remplacer :

```lua
verifier(sonsDepuis(nSons) == "Atelier_clic,Atelier_clochette", "sons : le clic du bouton, puis la clochette (" .. sonsDepuis(nSons) .. ")")
```

par :

```lua
verifier(sonsDepuis(nSons) == "Atelier_clic,Atelier_clochette", "sons : le clic du bouton, puis la clochette (" .. sonsDepuis(nSons) .. ")")
verifier(fenetre.Message.Visible and fenetre.Message.Text == ("Colette verse un acompte de %d pièces d'or."):format(serveur:atelier(joueur).etat.commande.acompte), "la cliente verse un acompte")
```

Dans `tests/scenario.luau`, remplacer :

```lua
-- Pour la suite, une couturière confirmée : tout le catalogue ouvert (prestige et amitiés au plus haut)
```

par :

```lua
-- Déblocages : au départ, ce qui est fermé est grisé, avec ce qu'il faut pour l'ouvrir, et ne se choisit pas
local jupeAmple = boutonNomme("Variante_jupe_ample")
verifier(jupeAmple:GetAttribute("Ferme") == true and jupeAmple.TextColor3 == GRIS and boutonNomme("Variante_jupe_droite"):GetAttribute("Ferme") == false, "jupe ample fermée au départ : grisée ; la jupe droite ouverte")
cliquer("Variante_jupe_ample")
verifier(fenetre.Message.Visible and fenetre.Message.Text == "Pas encore ouvert : Jupe ample froncée (Amitié de Colette : 2)." and boutonNomme("Variante_jupe_droite").BackgroundColor3 == Color3.fromRGB(214, 76, 128), "toucher une variante fermée : ce qu'il faut pour l'ouvrir, la jupe droite reste choisie")
cliquer("Tissu_corsage_droit_devant")
local carteSoie = boutonNomme("Tissu_soie_rose_fleurs")
verifier(carteSoie:GetAttribute("Ferme") == true and carteSoie.Raison.Text == "Prestige 5" and boutonNomme("Tissu_coton_blanc"):GetAttribute("Ferme") == false, "soie fermée : la carte grisée dit « Prestige 5 » ; le coton est ouvert")
cliquer("Tissu_soie_rose_fleurs")
verifier(fenetre.Contenu:FindFirstChild("ChoixTissu") ~= nil and fenetre.Message.Text == "Pas encore ouvert : Soie rose fleurie (Prestige 5).", "toucher un tissu fermé : ce qu'il faut pour l'ouvrir, le choix reste ouvert")
cliquer("FermerChoix")
-- Pour la suite, une couturière confirmée : tout le catalogue ouvert (prestige et amitiés au plus haut)
```

Dans `tests/scenario.luau`, remplacer :

```lua
verifier(requireModule(scriptClient.Session).courante.etat.prestige == 530, "la copie du client suit le serveur")
```

par :

```lua
verifier(requireModule(scriptClient.Session).courante.etat.prestige == 530, "la copie du client suit le serveur")
verifier(boutonNomme("Variante_jupe_ample"):GetAttribute("Ferme") == false, "prestige et amitiés au plus haut : la jupe ample s'ouvre dans le carnet")
```

Dans `tests/scenario.luau`, remplacer :

```lua
for k = 3, 6 do
	coudre(30)
```

par :

```lua
-- L'amitié d'Inès remise à 0 le temps de voir une décoration fermée (serveur et copie du client)
serveur:atelier(joueur).etat.clientes.ines.amitie = 0
requireModule(scriptClient.Session).courante.etat.clientes.ines.amitie = 0
for k = 3, 6 do
	coudre(30)
```

Dans `tests/scenario.luau`, remplacer :

```lua
-- La palette ne montre que des rangées entières (une rangée coupée attirerait les clics à côté)
```

par :

```lua
-- Une décoration fermée : grisée, avec ce qu'il faut pour l'ouvrir ; on ne peut pas la choisir
local croixFermee = boutonNomme("Deco_croix_argent")
verifier(croixFermee:GetAttribute("Ferme") == true and croixFermee.Text == "Croix d'argent · Amitié d'Inès : 4", "croix d'argent fermée : grisée, avec l'amitié qu'il faut")
cliquer("Deco_croix_argent")
verifier(fenetre.Message.Visible and fenetre.Message.Text == "Pas encore ouvert : Croix d'argent (Amitié d'Inès : 4)." and boutonNomme("Deco_croix_argent").BackgroundColor3 ~= ACCENT, "toucher une décoration fermée : ce qu'il faut pour l'ouvrir, rien n'est choisi")
serveur:atelier(joueur).etat.clientes.ines.amitie = 25
etatJeu.clientes.ines.amitie = 25
-- La palette ne montre que des rangées entières (une rangée coupée attirerait les clics à côté)
```

Dans `tests/scenario.luau`, remplacer :

```lua
cliquer("Livrer")
cliquer("Livrer")
verifier(titre() == "Atelier de couture" and argent() > avantLivraison, "robe acceptée : payée")
```

par :

```lua
-- Prestige 45 avant la livraison : elle fait passer au niveau 3 (les satins et la dentelle noire s'ouvrent)
serveur:atelier(joueur).etat.prestige = 45
cliquer("Livrer")
cliquer("Livrer")
verifier(titre() == "Atelier de couture" and argent() > avantLivraison, "robe acceptée : payée")
```

Dans `tests/scenario.luau`, remplacer :

```lua
verifier(texte("Amitié de Colette : +") ~= nil and texte("Prestige : +") ~= nil, "l'accueil annonce l'amitié et le prestige gagnés")
```

par :

```lua
verifier(texte("Amitié de Colette : +") ~= nil and texte("Prestige : +") ~= nil, "l'accueil annonce l'amitié et le prestige gagnés")
verifier(texte("Acompte de ") ~= nil and texte("(niveau 3 !)") ~= nil and texte("Nouveau : les satins (4), Dentelle noire.") ~= nil, "l'accueil rappelle l'acompte, le niveau de prestige atteint et ce qui vient de s'ouvrir")
local prestigeJoueur = serveur:atelier(joueur).etat.prestige
verifier(fenetre.Contenu.Prestige.Text == ("Prestige 3 — %d / 100"):format(prestigeJoueur), "jauge de prestige : « Prestige 3 — " .. prestigeJoueur .. " / 100 »")
verifier(math.abs(fenetre.Contenu.JaugePrestige.Rempli.Size.X.Scale - (prestigeJoueur - 50) / 50) < 1e-6, "la jauge se remplit vers le niveau suivant")
verifierTailles("accueil")
serveur:atelier(joueur).etat.prestige = 530 -- (tout reste ouvert pour la suite)
```

- [ ] **Step 2: Lancer les tests, vérifier l'échec**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT|attempt|membre" | head -3`
Expected: échec : une ligne qui finit par `attempt to call a nil value` (`Deblocages.resume` n'existe pas encore)

- [ ] **Step 3: Écrire le code**

Dans `src/shared/Deblocages.luau`, remplacer :

```lua
-- Ce qui est ouvert, par genre : { variantes = { [id] = true }, tissus = …, accessoires = … }
```

par :

```lua
-- Le refus d'un élément fermé : « Pas encore ouvert : Soie rouge (Prestige 5). »
function Deblocages.message(genre, id)
	return ("Pas encore ouvert : %s (%s)."):format(Deblocages.nom(genre, id), Deblocages.raison(genre, id))
end

-- Ce qui est ouvert, par genre : { variantes = { [id] = true }, tissus = …, accessoires = … }
```

Dans `src/shared/Deblocages.luau`, remplacer :

```lua
return Deblocages
```

par :

```lua
local MATIERES = { laine = "les laines", satin = "les satins", velours = "les velours", soie = "les soies" }

-- Ce qui vient de s'ouvrir, en une ligne : les tissus d'une même matière ensemble (« les satins (4), Dentelle
-- noire »)
function Deblocages.resume(nouveaux)
	local parMatiere, ordre, morceaux = {}, {}, {}
	for _, n in ipairs(nouveaux) do
		if n.genre == "tissus" then
			local m = Catalogue.tissu(n.id).matiere
			if not parMatiere[m] then
				parMatiere[m] = {}
				table.insert(ordre, { matiere = m })
			end
			table.insert(parMatiere[m], n.nom)
		end
	end
	for _, n in ipairs(nouveaux) do
		if n.genre == "variantes" then
			table.insert(morceaux, n.nom)
		end
	end
	for _, o in ipairs(ordre) do
		local noms = parMatiere[o.matiere]
		table.insert(morceaux, if #noms > 1 then ("%s (%d)"):format(MATIERES[o.matiere] or o.matiere, #noms) else noms[1])
	end
	for _, n in ipairs(nouveaux) do
		if n.genre == "accessoires" then
			table.insert(morceaux, n.nom)
		end
	end
	return table.concat(morceaux, ", ")
end

return Deblocages
```

Dans `src/shared/EtatAtelier.luau`, remplacer :

```lua
			return refus(("Pas encore ouvert : %s (%s)."):format(Deblocages.nom(genre, id), Deblocages.raison(genre, id)))
```

par :

```lua
			return refus(Deblocages.message(genre, id))
```

Dans `src/shared/EtatAtelier.luau`, remplacer :

```lua
	local paie = Notation.paie(#recette.pieces, #self.commande.exigences, bilan.qualite)
	local acompte = self.commande.acompte or 0
```

par :

```lua
	local avant = { prestige = self.prestige, clientes = {} } -- pour dire ce que la livraison a ouvert
	for id, f in pairs(self.clientes) do
		avant.clientes[id] = { amitie = f.amitie }
	end
	local paie = Notation.paie(#recette.pieces, #self.commande.exigences, bilan.qualite)
	local acompte = self.commande.acompte or 0
```

Dans `src/shared/EtatAtelier.luau`, remplacer :

```lua
	return { ok = true, reussie = true, paie = paie, acompte = acompte, verse = verse, bilan = bilan, ratees = {}, amitie = gainAmitie, prestige = prestige }
```

par :

```lua
	local nouveaux = Deblocages.nouveaux(avant, self)
	return { ok = true, reussie = true, paie = paie, acompte = acompte, verse = verse, bilan = bilan, ratees = {}, amitie = gainAmitie, prestige = prestige, nouveaux = nouveaux }
```

Dans `src/client/Atelier/UiKit.luau`, remplacer :

```lua
	erreur = Color3.fromRGB(210, 60, 60),
}
```

par :

```lua
	erreur = Color3.fromRGB(210, 60, 60),
	ferme = Color3.fromRGB(226, 220, 223), -- un élément du catalogue pas encore ouvert
}
```

Dans `src/client/Atelier/UiKit.luau`, remplacer :

```lua
function UiKit.boutonDoux(props, auClic, calme)
```

par :

```lua
-- Un élément du catalogue pas encore ouvert (déblocages) : grisé, marqué par l'attribut « Ferme »
function UiKit.griser(bouton, ferme)
	bouton:SetAttribute("Ferme", ferme)
	if ferme then
		bouton.BackgroundColor3 = UiKit.COULEURS.ferme
		bouton.TextColor3 = UiKit.COULEURS.texteDoux
	end
end

function UiKit.boutonDoux(props, auClic, calme)
```

Dans `src/client/Atelier/EcranCarnet.luau`, remplacer :

```lua
local Clientes = require(Couture:WaitForChild("Clientes"))
```

par :

```lua
local Clientes = require(Couture:WaitForChild("Clientes"))
local Deblocages = require(Couture:WaitForChild("Deblocages"))
```

Dans `src/client/Atelier/EcranCarnet.luau`, remplacer :

```lua
			}, function()
				croquis[famille] = v.id
				rafraichir()
			end)
```

par :

```lua
			}, function()
				if not Deblocages.ouvert(etat, "variantes", v.id) then
					ctx.message(Deblocages.message("variantes", v.id), C.texteDoux)
					return
				end
				croquis[famille] = v.id
				rafraichir()
			end)
```

Dans `src/client/Atelier/EcranCarnet.luau`, remplacer :

```lua
				if not filtre or (t.style[filtre] or 0) > 0 then
					local carte = UiKit.arrondir(UiKit.creer("TextButton", { Name = "Tissu_" .. t.id, Text = "", AutoButtonColor = true, BackgroundColor3 = C.panneau, ZIndex = 12, Parent = grille }), 8)
```

par :

```lua
				if not filtre or (t.style[filtre] or 0) > 0 then
					local ouvert = Deblocages.ouvert(etat, "tissus", t.id)
					local carte = UiKit.arrondir(UiKit.creer("TextButton", { Name = "Tissu_" .. t.id, Text = "", AutoButtonColor = ouvert, BackgroundColor3 = if ouvert then C.panneau else C.ferme, ZIndex = 12, Parent = grille }), 8)
					carte:SetAttribute("Ferme", not ouvert)
```

Dans `src/client/Atelier/EcranCarnet.luau`, remplacer :

```lua
					UiKit.texte({ Text = ("%d po/m · %s"):format(t.prix, table.concat(etiquettes, ", ")), TextSize = 14, TextColor3 = C.texteDoux, Position = UDim2.fromOffset(72, 50), Size = UDim2.new(1, -80, 0, 36), ZIndex = 13, Parent = carte })
					carte.Activated:Connect(function()
```

par :

```lua
					if ouvert then
						UiKit.texte({ Text = ("%d po/m · %s"):format(t.prix, table.concat(etiquettes, ", ")), TextSize = 14, TextColor3 = C.texteDoux, Position = UDim2.fromOffset(72, 50), Size = UDim2.new(1, -80, 0, 36), ZIndex = 13, Parent = carte })
					else
						UiKit.texte({ Name = "Raison", Text = Deblocages.raison("tissus", t.id), Font = Enum.Font.GothamBold, TextSize = 14, TextColor3 = C.texteDoux, Position = UDim2.fromOffset(72, 50), Size = UDim2.new(1, -80, 0, 36), ZIndex = 13, Parent = carte })
						echantillon.ImageTransparency, echantillon.BackgroundTransparency = 0.6, 0.6
					end
					carte.Activated:Connect(function()
						if not Deblocages.ouvert(etat, "tissus", t.id) then
							ctx.message(Deblocages.message("tissus", t.id), C.texteDoux)
							return
						end
```

Dans `src/client/Atelier/EcranCarnet.luau`, remplacer :

```lua
			b.BackgroundColor3 = choisie and C.accent or C.secondaire
			b.TextColor3 = choisie and Color3.new(1, 1, 1) or C.texte
		end
```

par :

```lua
			b.BackgroundColor3 = choisie and C.accent or C.secondaire
			b.TextColor3 = choisie and Color3.new(1, 1, 1) or C.texte
			UiKit.griser(b, not Deblocages.ouvert(etat, "variantes", id))
		end
```

Dans `src/client/Atelier/EcranDecorations.luau`, remplacer :

```lua
local Catalogue = require(Couture:WaitForChild("Catalogue"))
```

par :

```lua
local Catalogue = require(Couture:WaitForChild("Catalogue"))
local Deblocages = require(Couture:WaitForChild("Deblocages"))
```

Dans `src/client/Atelier/EcranDecorations.luau`, remplacer :

```lua
		local prix = a.genre == "garniture" and ("%d po/dm"):format(a.prix) or ("%d po"):format(a.prix)
		boutons[a.id] = UiKit.boutonDoux({
			Name = "Deco_" .. a.id,
			Text = a.nom .. " · " .. prix,
```

par :

```lua
		local prix = a.genre == "garniture" and ("%d po/dm"):format(a.prix) or ("%d po"):format(a.prix)
		-- fermé : ce qu'il faut pour l'ouvrir à la place du prix
		local detail = if Deblocages.ouvert(ctx.session.etat, "accessoires", a.id) then prix else Deblocages.raison("accessoires", a.id)
		boutons[a.id] = UiKit.boutonDoux({
			Name = "Deco_" .. a.id,
			Text = a.nom .. " · " .. detail,
```

Dans `src/client/Atelier/EcranDecorations.luau`, remplacer :

```lua
		}, function()
			deco:choisir(a.id)
			rafraichir()
		end)
```

par :

```lua
		}, function()
			if not Deblocages.ouvert(ctx.session.etat, "accessoires", a.id) then
				ctx.message(Deblocages.message("accessoires", a.id), C.texteDoux)
				return
			end
			deco:choisir(a.id)
			rafraichir()
		end)
```

Dans `src/client/Atelier/EcranDecorations.luau`, remplacer :

```lua
			b.BackgroundColor3 = id == deco.choix and C.accent or C.secondaire
			b.TextColor3 = id == deco.choix and Color3.new(1, 1, 1) or C.texte
		end
```

par :

```lua
			b.BackgroundColor3 = id == deco.choix and C.accent or C.secondaire
			b.TextColor3 = id == deco.choix and Color3.new(1, 1, 1) or C.texte
			UiKit.griser(b, not Deblocages.ouvert(ctx.session.etat, "accessoires", id))
		end
```

Dans `src/client/Atelier/EcranAccueil.luau`, remplacer :

```lua
-- Écran d'accueil : la clochette du comptoir (bouton, ou touche E) fait entrer une cliente et crée la
-- commande. Après une livraison, il annonce ce qu'a pensé la cliente précédente.
```

par :

```lua
-- Écran d'accueil : la clochette du comptoir (bouton, ou touche E) fait entrer une cliente et crée la
-- commande (elle verse un acompte). Après une livraison, il annonce ce qu'a pensé la cliente précédente,
-- l'amitié et le prestige gagnés, et ce qui vient de s'ouvrir. La jauge de prestige est sous la clochette.
```

Dans `src/client/Atelier/EcranAccueil.luau`, remplacer :

```lua
local Clientes = require(ReplicatedStorage:WaitForChild("Couture"):WaitForChild("Clientes"))
```

par :

```lua
local Couture = ReplicatedStorage:WaitForChild("Couture")
local Clientes = require(Couture:WaitForChild("Clientes"))
local Progression = require(Couture:WaitForChild("Progression"))
local Deblocages = require(Couture:WaitForChild("Deblocages"))
```

Dans `src/client/Atelier/EcranAccueil.luau`, remplacer :

```lua
		local suite = {}
		table.insert(suite, ligneAmitie(r.amitie))
```

par :

```lua
		local suite = {}
		if r.acompte and r.acompte > 0 then
			table.insert(suite, ("Acompte de %d déjà reçu"):format(r.acompte))
		end
		table.insert(suite, ligneAmitie(r.amitie))
```

Dans `src/client/Atelier/EcranAccueil.luau`, remplacer :

```lua
			fiche and fiche.nom:match("^(%S+)") or "La cliente",
			r.paie,
```

par :

```lua
			fiche and fiche.nom:match("^(%S+)") or "La cliente",
			r.verse or r.paie,
```

Dans `src/client/Atelier/EcranAccueil.luau`, remplacer :

```lua
		if #suite > 0 then
			annonce ..= "\n" .. table.concat(suite, " · ")
		end
```

par :

```lua
		if #suite > 0 then
			annonce ..= "\n" .. table.concat(suite, " · ")
		end
		if r.nouveaux and #r.nouveaux > 0 then
			annonce ..= "\nNouveau : " .. Deblocages.resume(r.nouveaux) .. "."
		end
```

Dans `src/client/Atelier/EcranAccueil.luau`, remplacer :

```lua
	if annonce then
		UiKit.texte({ Name = "Annonce", Text = annonce, Font = Enum.Font.GothamBold, TextSize = 18, TextColor3 = couleur, Size = UDim2.new(1, 0, 0, 50), Parent = ctx.contenu })
		decalage = 60
	end
```

par :

```lua
	if annonce then
		local _, retours = annonce:gsub("\n", "")
		local hauteur = 24 * (retours + 1) + 2
		UiKit.texte({ Name = "Annonce", Text = annonce, Font = Enum.Font.GothamBold, TextSize = 18, TextColor3 = couleur, Size = UDim2.new(1, 0, 0, hauteur), Parent = ctx.contenu })
		decalage = hauteur + 10
	end
```

Dans `src/client/Atelier/EcranAccueil.luau`, remplacer :

```lua
	local function sonner()
		local r = ctx.session:nouvelleCommande()
		if not r.ok then
			ctx.refus(r)
		end
	end
```

par :

```lua
	local function sonner()
		local r = ctx.session:nouvelleCommande()
		if not r.ok then
			ctx.refus(r)
		elseif r.acompte and r.acompte > 0 then
			local fiche = Clientes.get(r.cliente)
			ctx.message(("%s verse un acompte de %d pièces d'or."):format(fiche and fiche.nom:match("^(%S+)") or "La cliente", r.acompte), C.ok)
		end
	end
```

Dans `src/client/Atelier/EcranAccueil.luau`, remplacer :

```lua
	-- E, fenêtre ouverte (pas pendant la saisie dans le chat) : sonner la clochette
```

par :

```lua
	-- La jauge de prestige : « Prestige 3 — 62 / 100 »
	local etat = ctx.session.etat
	local niveau = Progression.niveauPrestige(etat.prestige)
	local seuil, suivant = Progression.SEUILS_PRESTIGE[niveau], Progression.SEUILS_PRESTIGE[niveau + 1]
	local y = 110 + decalage + 66
	UiKit.texte({
		Name = "Prestige",
		Text = if suivant then ("Prestige %d — %d / %d"):format(niveau, etat.prestige, suivant) else ("Prestige %d — %d (au plus haut)"):format(niveau, etat.prestige),
		Font = Enum.Font.GothamBold,
		Position = UDim2.fromOffset(0, y),
		Size = UDim2.fromOffset(360, 22),
		Parent = ctx.contenu,
	})
	local fond = UiKit.arrondir(UiKit.creer("Frame", { Name = "JaugePrestige", BackgroundColor3 = C.secondaire, Position = UDim2.fromOffset(0, y + 26), Size = UDim2.fromOffset(360, 12), Parent = ctx.contenu }), 6)
	local part = if suivant then (etat.prestige - seuil) / (suivant - seuil) else 1
	UiKit.creer("Frame", { Name = "Rempli", BackgroundColor3 = C.accent, BorderSizePixel = 0, Size = UDim2.fromScale(math.clamp(part, 0, 1), 1), Parent = fond })
	-- E, fenêtre ouverte (pas pendant la saisie dans le chat) : sonner la clochette
```

- [ ] **Step 4: Lancer les tests**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT"`
Expected:
```
Unitaires : 107312 vérifications
TOUT EST VERT : 584 vérifications
```

- [ ] **Step 5: Commit**

```bash
git add src/shared/Deblocages.luau src/shared/EtatAtelier.luau src/client/Atelier/UiKit.luau src/client/Atelier/EcranCarnet.luau src/client/Atelier/EcranDecorations.luau src/client/Atelier/EcranAccueil.luau tests/unitaires/45_deblocages.luau tests/unitaires/47_acompte.luau tests/scenario.luau
git commit -m "Ce qui est fermé est grisé avec sa raison ; jauge de prestige, acompte et nouveautés à l'accueil

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 5: L'équilibrage, vérifié par simulation

Ce test caractérise l'équilibrage obtenu par les tâches 1 à 4 : il passe dès qu'il est écrit (aucun réglage n'a eu à changer). La préparation a vérifié qu'il échoue quand on dérègle le prestige ou les déblocages (variantes ci-dessus).

**Files:**
- Create: `tests/unitaires/48_equilibrage.luau`

**Interfaces:**
- Consumes: `EtatAtelier` (commande, mesures, croquis, achat, décorations, livraison, abandon), `Deblocages.ouverts`, `Deblocages.toutOuvert`, `Metrage.conseil`, `Notation.styles`, `Notation.verifierExigences`.
- Produces: la ligne « Équilibrage : … » dans la sortie des tests.

- [ ] **Step 1: Écrire la simulation**

Créer `tests/unitaires/48_equilibrage.luau` :

```lua
-- Équilibrage (spec §10) : un joueur moyen simulé enchaîne les commandes avec les vraies règles de l'atelier.
-- À chaque commande : mesures justes, la robe la moins chère qui la remplit avec ce qui est ouvert (un seul
-- tissu, l'accessoire demandé), qualité 0,8 ; une robe refusée (qualité demandée trop haute) est abandonnée.
local EtatAtelier = U.module("EtatAtelier")
local Clientes = U.module("Clientes")
local Catalogue = U.module("Catalogue")
local Patron = U.module("Patron")
local Metrage = U.module("Metrage")
local Notation = U.module("Notation")
local Deblocages = U.module("Deblocages")
local Progression = U.module("Progression")

local QUALITE = 0.8
local ROBES = 60

local CROQUIS = {}
for _, c in ipairs(Catalogue.variantesDe("corsage")) do
	for _, m in ipairs(Catalogue.variantesDe("manches")) do
		for _, k in ipairs(Catalogue.variantesDe("col")) do
			for _, j in ipairs(Catalogue.variantesDe("jupe")) do
				local croquis = { corsage = c.id, manches = m.id, col = k.id, jupe = j.id }
				local pieces = Patron.piecesDuCroquis(croquis)
				table.insert(CROQUIS, { croquis = croquis, pieces = pieces, dm = Metrage.conseil(pieces) })
			end
		end
	end
end

-- La robe la moins chère qui remplit la commande avec ce qui est ouvert, ou nil
local function choisir(etat)
	local ouverts = Deblocages.ouverts(etat)
	local impose
	for _, x in ipairs(etat.commande.exigences) do
		if x.type == "accessoire" then
			impose = x.id
		end
	end
	if impose and not ouverts.accessoires[impose] then
		return nil
	end
	local accessoires = impose and { { id = impose } } or {}
	local meilleur
	for _, c in ipairs(CROQUIS) do
		local v = c.croquis
		if ouverts.variantes[v.corsage] and ouverts.variantes[v.manches] and ouverts.variantes[v.col] and ouverts.variantes[v.jupe] then
			for _, t in ipairs(Catalogue.Tissus) do
				local cout = EtatAtelier.prix(t.id, c.dm) + (impose and Catalogue.accessoire(impose).prix or 0)
				if ouverts.tissus[t.id] and (not meilleur or cout < meilleur.cout) then
					local bilan = {
						styles = Notation.styles({ croquis = v, tissus = { [t.id] = 1 }, accessoires = accessoires }),
						qualite = QUALITE,
						teinte = t.teinte,
						accessoires = impose and { [impose] = 1 } or {},
					}
					if Notation.verifierExigences(etat.commande.exigences, bilan) then
						meilleur = { croquis = v, pieces = c.pieces, dm = c.dm, tissu = t.id, cout = cout, impose = impose }
					end
				end
			end
		end
	end
	return meilleur
end

local e = EtatAtelier.nouveau()
local rng = Random.new(2026)
local robeSimple = EtatAtelier.prix("coton_blanc", Metrage.conseil(Patron.piecesDuCroquis({ corsage = "corsage_droit", manches = "manches_sans", col = "col_sans", jupe = "jupe_droite" })))
local niveauA, toutOuvertA = {}, nil
local plusPauvre, livrees = math.huge, 0
for n = 1, ROBES do
	assert(e:nouvelleCommande(rng).ok)
	assert(e:mesurer(Clientes.get(e.commande.cliente).mesures).ok)
	local choix = choisir(e)
	local reussie = false
	if choix and choix.cout <= e.argent then
		local tissus = {}
		for _, id in ipairs(choix.pieces) do
			tissus[id] = choix.tissu
		end
		assert(e:validerCroquis(choix.croquis, tissus).ok)
		assert(e:acheter(choix.tissu, choix.dm).ok)
		e.stock[choix.tissu] -= choix.dm -- tout le métrage est coupé
		for _, id in ipairs(choix.pieces) do
			e.coupees[id] = { x = 0, y = 0, angle = Catalogue.piece(id).biais and 45 or 0 }
			e.epinglees[id] = true
			e.coutures[id] = QUALITE
		end
		e.etape = "decorations"
		local deco = choix.impose and { { id = choix.impose, piece = 1, copie = "unique", u = 0.5, v = 0.5, echelle = 1, angle = 0 } } or {}
		assert(e:decorer(deco).ok)
		reussie = e:livrer().reussie
	end
	if reussie then
		livrees += 1
	else
		e.etape = "refus"
		assert(e:abandonner().ok)
	end
	plusPauvre = math.min(plusPauvre, e.argent)
	local niveau = Progression.niveauPrestige(e.prestige)
	for k = 2, niveau do
		niveauA[k] = niveauA[k] or n
	end
	if not toutOuvertA and Deblocages.toutOuvert(e) then
		toutOuvertA = n
	end
end
local bilan = ("%d robes livrées sur %d ; prestige 2 à la robe %s, 5 à la %s ; tout ouvert à la %s ; au plus bas %d po"):format(livrees, ROBES, tostring(niveauA[2]), tostring(niveauA[5]), tostring(toutOuvertA), plusPauvre)
print("Équilibrage : " .. bilan)
U.verifier(niveauA[2] ~= nil and niveauA[2] <= 3, "prestige 2 en trois robes au plus (" .. bilan .. ")")
U.verifier(niveauA[5] ~= nil and niveauA[5] >= 12 and niveauA[5] <= 20, "prestige 5 entre la 12e et la 20e robe (" .. bilan .. ")")
U.verifier(toutOuvertA ~= nil and toutOuvertA >= 30 and toutOuvertA <= 50, "tout le catalogue ouvert entre la 30e et la 50e robe (" .. bilan .. ")")
U.verifier(plusPauvre >= robeSimple, "l'argent ne descend jamais sous le prix d'une robe simple (" .. bilan .. ")")
U.verifier(livrees >= ROBES * 0.7, "un joueur moyen livre la plupart de ses commandes (" .. bilan .. ")")
```

- [ ] **Step 2: Lancer les tests**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Équilibrage|Unitaires|ÉCHEC|TOUT"`
Expected:
```
Équilibrage : 58 robes livrées sur 60 ; prestige 2 à la robe 2, 5 à la 16 ; tout ouvert à la 45 ; au plus bas 284 po
Unitaires : 107317 vérifications
TOUT EST VERT : 584 vérifications
```

- [ ] **Step 3: Commit**

```bash
git add tests/unitaires/48_equilibrage.luau
git commit -m "Équilibrage simulé : un joueur moyen, 60 commandes, prestige et déblocages au rythme de la spec

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 6: Vérification dans Studio et README

**Files:**
- Modify: `README.md`
- Modify: `AtelierCouture.rbxl` (régénéré)

**Interfaces:**
- Consumes: tout ce qui précède.
- Produces: le plan 5b terminé.

- [ ] **Step 1: En Play, par le connecteur MCP**

Construire le lieu du dépôt dans un dossier temporaire (`C:/dev/jeux/roblox-maker/rojo.exe build -o <dossier temporaire>/Plan5bDepot.rbxl`), l'ouvrir dans Studio, lancer Play et attendre 4 s. Puis :

1. Côté client (`execute_luau`), lire le texte `Prestige` de l'accueil.
2. Appuyer sur E, attendre 2 s ; lire le message sous la fenêtre.
3. Régler les rubans aux vraies mesures de Colette (glisser les poignées jusqu'au bord de la silhouette, comme au plan 5a) et valider ; au carnet, lire l'attribut `Ferme` et les couleurs de `Variante_jupe_ample`, puis cliquer dessus et lire le message.
4. Relever les alertes (`get_console_output`).

Expected :
- « Prestige 1 — 0 / 20 » ;
- « Colette verse un acompte de N pièces d'or. » ;
- jupe ample : `Ferme` vrai, fond gris ; le clic affiche « Pas encore ouvert : Jupe ample froncée (Amitié de Colette : 2). » ;
- aucune alerte de notre code (« Lieu non publié » et les messages internes de Roblox mis à part).

Arrêter Play et fermer cette fenêtre de Studio (sans enregistrer).

- [ ] **Step 2: À faire par le commanditaire**

- regarder les grisés du carnet et de la palette sur téléphone (lisibilité de la raison) ;
- jouer quelques commandes et dire si la montée du prestige paraît juste.

Les noter dans le message de fin, sans bloquer le plan.

- [ ] **Step 3: Mettre à jour le README**

Dans `README.md`, remplacer :

```markdown
## État actuel (sous-projet 2 en cours : plan 5a, les clientes)
```

par :

```markdown
## État actuel (sous-projet 2 en cours : plans 5a et 5b, les clientes, le prestige et les déblocages)
```

Dans `README.md`, remplacer :

```markdown
   parle par une bulle, avec ses propres mots (présentation, arrivée, merci, déception).
```

par :

```markdown
   parle par une bulle, avec ses propres mots (présentation, arrivée, merci, déception). En passant commande,
   elle verse un **acompte** (un quart de la base d'une robe simple), déduit de la paie ; gardé si on abandonne.
```

Dans `README.md`, remplacer :

```markdown
2. **Carnet de croquis** : corsage, manches, col et jupe au choix ; un tissu par pièce (24 tissus, filtre par style).
   Les jauges de style, l'état des exigences, le métrage et le coût du tissu à acheter se mettent à jour en
   direct.
```

par :

```markdown
2. **Carnet de croquis** : corsage, manches, col et jupe au choix ; un tissu par pièce (24 tissus, filtre par style).
   Les jauges de style, l'état des exigences, le métrage et le coût du tissu à acheter se mettent à jour en
   direct. Ce qui n'est pas encore ouvert est grisé, avec ce qu'il faut pour l'ouvrir (« Prestige 3 »,
   « Amitié d'Hélène : 2 ») ; le serveur le refuse aussi.
```

Dans `README.md`, remplacer :

```markdown
   (paie / 10) ; niveaux 1 à 8. L'accueil annonce ce qui a été gagné.
9. La suite : prestige et déblocages (plan 5b), robes libres à vendre ou à offrir (plan 5c), courrier et
   carnet d'adresses (plan 5d).
```

par :

```markdown
   (paie / 10) ; niveaux 1 à 8. L'accueil annonce ce qui a été gagné, et montre la jauge de prestige
   (« Prestige 3 — 62 / 100 »). Un abandon ne fait jamais perdre un niveau d'amitié.
   **Déblocages** : au départ, cotons et lins, huit variantes et six accessoires. Le prestige ouvre les laines (2),
   les satins (3), les velours (4) et les soies (5), le ruban noir (2) et la dentelle noire (3) ; l'amitié de
   chaque cliente (niveaux 2 et 4) ouvre une variante ou un accessoire de son style. Rien n'est sauvegardé :
   tout se déduit du prestige et des amitiés. Les commandes ne demandent que ce qui est ouvert, et leurs
   exigences de style montent avec le prestige. L'accueil annonce ce qui vient de s'ouvrir.
   **Équilibrage** (simulé par les tests) : un joueur moyen (qualité 0,8) atteint le prestige 2 à la 2e robe,
   le 5 à la 16e, et tout est ouvert vers la 45e.
9. La suite : robes libres à vendre ou à offrir (plan 5c), courrier et carnet d'adresses (plan 5d).
```

Dans `README.md`, remplacer :

```markdown
  | `Clientes`, `Progression` | Les six clientes (mesures, tenue, goûts, répliques) et qui vient à la clochette ; amitié, prestige et leurs niveaux |
```

par :

```markdown
  | `Clientes`, `Progression` | Les six clientes (mesures, tenue, goûts, répliques) et qui vient à la clochette ; amitié, prestige et leurs niveaux |
  | `Deblocages` | Ce qui est fermé au départ et ce qui l'ouvre (prestige, amitié) ; ce qu'une livraison vient d'ouvrir |
```

- [ ] **Step 4: Tests, lieu régénéré, commit**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT"`
Expected:
```
Unitaires : 107317 vérifications
TOUT EST VERT : 584 vérifications
```

```bash
C:/dev/jeux/roblox-maker/rojo.exe build -o AtelierCouture.rbxl
git add README.md AtelierCouture.rbxl
git commit -m "Plan 5b terminé : prestige, déblocages et acompte

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```
