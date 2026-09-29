# Cœur de l'atelier — Plan 4b : la sauvegarde

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Sauvegarder la partie de chaque joueur (argent, stock, dix dernières robes, commande en cours) dans le DataStore `AtelierCouture_v2`, avec un verrou de session, des migrations et la reprise de l'ancienne sauvegarde, sans jamais écraser une partie qu'on n'a pas pu lire (spec §6).

**Architecture:**
- **Sauvegarde** (nouveau module serveur) : le format de la partie (v2), les migrations, la conversion entre partie et `EtatAtelier`, et l'accès au DataStore. Il reçoit le DataStore, l'horloge et la fonction d'attente, ce qui permet de tester le verrou dans la simulation.
- **Commande** : lit la partie à l'arrivée du joueur (« L'atelier se prépare » tant qu'elle n'est pas lue), l'écrit à la demande, au départ, et à l'arrêt du serveur. Sans sauvegarde (lieu non publié), elle fonctionne comme au plan 4a.
- **Script du serveur** : branche l'arrivée, le départ, la sauvegarde toutes les 60 s et l'arrêt (`BindToClose`).
- **Client** : la session attend que la partie soit lue, puis affiche un avertissement si elle ne pourra pas être sauvegardée.

**Tech Stack:** Luau, Rojo 7.7.0-rc.1, simulation Luau 0.650 (`tests/lancer.sh`), Roblox Studio via le connecteur MCP Studio.

**Spec:** `docs/superpowers/specs/2026-09-28-atelier-coeur-design.md` (§6 « Sauvegarde », §7 « Sauvegarde : migrations v1 → v2 ; verrou (pris, rafraîchi, volé après 15 s) ; aucune écriture après une lecture ratée », §10 lieu de test publié). Plan précédent : `docs/superpowers/plans/2026-09-29-coeur-plan4a-serveur-commande.md`.

## Décisions de ce plan

- **Format v2** (une clé `joueur_<UserId>`, comme en v1) : `{ version = 2, argent, stock, debloques, recettes, enCours?, verrou? }`.
  - `recettes` : les dix dernières robes livrées.
  - `enCours` : la commande en cours (`etape`, `commande`, `croquis`, `tissus`, `coupees`, `coupons`, `epinglees`, `coutures`, `accessoires`), absente à l'accueil.
  - `debloques` : `{ tissus = {}, variantes = {}, accessoires = {} }`, gardé tel quel. Les déblocages arrivent au sous-projet 2 ; ici, tout le catalogue est ouvert.
- **Verrou de session** `{ jobId, t }` (`t` en secondes, `os.time()`).
  - Pris à la lecture et rafraîchi à chaque sauvegarde (`UpdateAsync`).
  - Si un autre serveur tient la partie depuis moins de 90 s : un essai toutes les 3 s pendant 15 s, puis on prend la main.
  - Rendu au départ du joueur et à l'arrêt du serveur.
  - Un serveur qui trouve le verrou d'un autre (ou une partie d'une version plus récente) n'écrit plus cette partie de toute la session (« perdu »).
- **Lecture ratée, partie illisible, ou d'une version plus récente** : le joueur joue une partie neuve qui ne sera jamais écrite, et il en est prévenu au démarrage (message de 10 s). Sa vraie partie reste intacte.
- **Partie abîmée** (tissu retiré du catalogue, données illisibles) : les entrées de stock et les robes illisibles sont laissées de côté. Une commande en cours illisible est abandonnée, avec un avertissement dans la sortie ; l'argent, le stock et les robes restent.
- **Migrations** : `Sauvegarde.MIGRATIONS[v]` passe du format v au format v + 1, et s'applique au chargement. La v1 (prototype, DataStore `AtelierCouture_v1`, `{ argent, reputation }`) donne l'argent, arrondi à l'entier inférieur et jamais négatif. Elle n'est lue que pour un joueur qui n'a pas encore de partie v2, donc une seule fois.
- **Pas de DataStore** sur un lieu non publié (`game.PlaceId == 0`), ni si `GetDataStore` échoue : un avertissement dans la sortie, et le jeu tourne comme au plan 4a.
- **Moments de sauvegarde** : toutes les 60 s (`task.delay`, qui se relance), au départ du joueur, et à l'arrêt du serveur (toutes les parties en même temps, 25 s au plus). Un joueur qui part pendant la lecture de sa partie la rend aussitôt.
- **Arrivée côté client** : la session réessaie une fois par seconde (30 essais au plus) tant que le serveur répond « L'atelier se prépare ». La fenêtre apparaît quand la partie est lue.
- **Simulation** : un DataStore en mémoire (`M.nouveauMagasin`), dont les données passent par les règles du réseau, avec pannes simulées ; `M.magasins` le branche sur `DataStoreService:GetDataStore`. Le scénario joue sur un lieu « publié » dont la première lecture échoue, puis vérifie la sauvegarde régulière, le départ, le retour et l'arrêt.
- **Vérifié dans Studio pendant la préparation** : sur un lieu local (non publié), un seul avertissement (« Lieu non publié : les parties ne sont pas sauvegardées. ») et le jeu tourne normalement. **Le vrai DataStore** ne se vérifie que sur un lieu publié avec l'accès aux API : c'est au commanditaire de le faire (spec §10), et le README l'explique.

## Global Constraints

- **Dépôt** : `C:\dev\jeux\atelier-couture`, branche `sauvegarde`, créée depuis `main` (où le plan 4a est fusionné). Ne rien pousser sur GitHub sans demande.
- **Rojo** : `C:/dev/jeux/roblox-maker/rojo.exe`.
- **Contraintes des plans précédents toujours valables** : fins de ligne LF, commits en français terminés par `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`, textes d'au moins 14 px à l'échelle 1, le serveur fait foi (le client n'envoie que des actions).
- **Sauvegarde** (spec §6) : DataStore `AtelierCouture_v2`, une clé par joueur, écriture par `UpdateAsync` ; verrou de moins de 90 s gardé par son serveur, essais toutes les 3 s pendant 15 s au plus ; sauvegarde toutes les 60 s, au départ, à l'arrêt (en parallèle, 25 s au plus) ; aucune écriture si la lecture a échoué ; pas de DataStore si `game.PlaceId == 0` ; migrations au chargement ; l'ancienne clé `AtelierCouture_v1` reprise une fois pour l'argent.

## Review Focus

- **Deux serveurs tiennent la partie d'un même joueur** (serveur figé, retour rapide dans un autre serveur). Attendu : le second prend la main après 15 s, et le premier n'écrit plus rien, pas même au départ. Tests : `30_sauvegarde`, « partie tenue ailleurs » et « B a perdu la partie » ; `31_commande_sauvegarde`, « l'ancien serveur ne l'écrase pas ».
- **DataStore en panne à l'arrivée.** Attendu : une partie neuve pour cette session, jamais écrite (la vraie reste intacte), et le joueur prévenu. Tests : `30`, « lecture ratée » ; `31`, « lecture ratée : partie neuve, joueur prévenu » ; scénario, « le joueur est prévenu » et « partie illisible : jamais écrite ».
- **Partie écrite par une version plus récente du jeu** (mise à jour en cours de déploiement). Attendu : ni chargée, ni jamais écrasée. Test : `30`, « version plus récente ».
- **Partie abîmée** (tissu retiré du catalogue, commande illisible, argent non numérique). Attendu : le reste de la partie est gardé, la commande en cours est abandonnée, un avertissement. Test : `30`, « partie abîmée ».
- **Joueur qui part pendant la lecture, arrêt du serveur.** Attendu : le verrou est rendu et la partie écrite ; aucun atelier ne reste. Tests : `31`, « parti pendant le chargement » et « arrêt du serveur » ; scénario, « arrêt du serveur ».

## Structure des fichiers

| Fichier | Rôle |
|---|---|
| `src/server/Sauvegarde.luau` | **Nouveau** : format v2, migrations, partie ↔ `EtatAtelier`, lecture avec verrou, écriture, `pourLeJeu` |
| `src/server/Commande.luau` | + `arrivee`, `enregistrer`, `enregistrerTout`, `depart`, `fermer` ; « L'atelier se prépare » ; avertissement sur `etat` |
| `src/server/init.server.luau` | Réécrit : sauvegarde du jeu, arrivée, départ, toutes les 60 s, arrêt |
| `src/client/Atelier/Session.luau` | `Session.distante(remote, attendre)` attend la partie ; `session.avertissement` |
| `src/client/Atelier/init.client.luau` | `afficherMessage(texte, couleur, duree)` ; avertissement au démarrage |
| `tests/mock.luau` | DataStore en mémoire (`M.nouveauMagasin`, `M.magasins`), `PlaceId` et `JobId` du jeu |
| `tests/unitaires/30_sauvegarde.luau`, `31_commande_sauvegarde.luau`, `32_session_attente.luau` | Tests unitaires |
| `tests/scenario.luau` | Lieu publié, première lecture ratée, sauvegardes, départ, retour, arrêt ; avertissement affiché |
| `README.md`, `AtelierCouture.rbxl` | État du jeu, comment tester la sauvegarde ; lieu régénéré |

---

### Task 1: Le module Sauvegarde

**Files:**
- Modify: `tests/mock.luau` (DataStore en mémoire ; `PlaceId` et `JobId`)
- Create: `src/server/Sauvegarde.luau`
- Test: `tests/unitaires/30_sauvegarde.luau`

**Interfaces:**
- Consumes: `EtatAtelier.nouveau`, `EtatAtelier:exporter`, `EtatAtelier:charger`, `EtatAtelier.ARGENT_DEPART`, `EtatAtelier.ETAPES`, `EtatAtelier.ROBES_GARDEES` (plan 4a) ; `Catalogue.tissu` ; `Recette.valider`.
- Produces:
  - `Sauvegarde.VERSION = 2`, `MAGASIN`, `ANCIEN_MAGASIN`, `VERROU_VIVANT = 90`, `ESSAI_PAS = 3`, `ESSAI_MAX = 15`, `MIGRATIONS`.
  - `Sauvegarde.migrer(partie) -> partie | nil` (nil : version plus récente).
  - `Sauvegarde.depuisEtat(etat, debloques?) -> partie` ; `Sauvegarde.versEtat(partie) -> EtatAtelier`.
  - `Sauvegarde.nouvelle({ magasin, ancien, jobId, horloge?, attendre? })` ; `Sauvegarde.pourLeJeu() -> Sauvegarde | nil`.
  - `sauvegarde:charger(userId) -> partie?, "ok" | "echec"` ; `sauvegarde:enregistrer(userId, partie, liberer?) -> "ok" | "echec" | "perdu"`.
  - Faux Roblox : `M.nouveauMagasin()` (`donnees`, `panne`, `ecritures`, `GetAsync`, `UpdateAsync`) ; `M.magasins` ; `game.PlaceId = 0`, `game.JobId = ""` au départ.

- [ ] **Step 1: Un DataStore dans le faux Roblox**

Dans `tests/mock.luau`, remplacer les deux lignes

```lua
function methodes.GetDataStore()
	local store = {}
```

par :

```lua
-- DataStore en mémoire (sauvegarde) : UpdateAsync et GetAsync comme Roblox (la fonction de UpdateAsync
-- renvoie nil pour annuler l'écriture) ; ce qui est rangé passe par une copie aux règles du réseau.
-- magasin.panne = n : les n prochains appels échouent ; magasin.ecritures compte les écritures.
function M.nouveauMagasin()
	local magasin = { donnees = {}, panne = 0, ecritures = 0 }
	local function tomberEnPanne()
		if magasin.panne > 0 then
			magasin.panne -= 1
			error("DataStore : panne simulée")
		end
	end
	function magasin.GetAsync(_, cle)
		tomberEnPanne()
		return M.transmettre(magasin.donnees[cle])
	end
	function magasin.UpdateAsync(_, cle, transformer)
		tomberEnPanne()
		local nouvelle = transformer(M.transmettre(magasin.donnees[cle]))
		if nouvelle == nil then
			return nil
		end
		magasin.donnees[cle] = M.transmettre(nouvelle)
		magasin.ecritures += 1
		return M.transmettre(nouvelle)
	end
	return magasin
end
-- Sans M.magasins, le DataStore échoue comme dans Studio sans accès aux API ; avec, M.magasins[nom]
function methodes.GetDataStore(_, nom)
	if M.magasins then
		M.magasins[nom] = M.magasins[nom] or M.nouveauMagasin()
		return M.magasins[nom]
	end
	local store = {}
```

Puis, dans `M.initialiser`, juste après `rawget(game, "__props").Name = "Game"`, ajouter :

```lua
	rawget(game, "__props").PlaceId = 0 -- lieu non publié (Studio)
	rawget(game, "__props").JobId = ""
```

- [ ] **Step 2: Écrire le test de la sauvegarde**

`tests/unitaires/30_sauvegarde.luau` :

```lua
local Sauvegarde = U.module("Sauvegarde")
local EtatAtelier = U.module("EtatAtelier")
local Recette = U.module("Recette")
local Patron = U.module("Patron")

-- Deux serveurs (A et B) qui partagent le même DataStore ; horloge simulée ; attendre fait passer le temps
local magasin, ancien = M.nouveauMagasin(), M.nouveauMagasin()
local temps, attentes = 1000000, 0
local function horloge()
	return temps
end
local function attendre(s)
	attentes += 1
	temps += s
end
local A = Sauvegarde.nouvelle({ magasin = magasin, ancien = ancien, jobId = "A", horloge = horloge, attendre = attendre })
local B = Sauvegarde.nouvelle({ magasin = magasin, ancien = ancien, jobId = "B", horloge = horloge, attendre = attendre })

---------------------------------------------------------------------------
-- Nouvelle joueuse, ancienne sauvegarde (v1 → v2), migrations
---------------------------------------------------------------------------
local partie, statut = A:charger(7)
U.verifier(statut == "ok" and partie.version == Sauvegarde.VERSION and partie.argent == EtatAtelier.ARGENT_DEPART, "nouvelle partie : argent de départ")
U.verifier(partie.enCours == nil and #partie.recettes == 0 and next(partie.stock) == nil and type(partie.debloques) == "table", "nouvelle partie : ni commande, ni robe, ni stock")
U.verifier(magasin.donnees.joueur_7.verrou.jobId == "A" and magasin.donnees.joueur_7.verrou.t == temps, "verrou pris par le serveur A")
U.verifier(partie.verrou == nil, "la partie rendue ne contient pas le verrou")

ancien.donnees.joueur_8 = { argent = 480.7, reputation = 12 }
partie = A:charger(8)
U.verifier(partie.argent == 480 and partie.reputation == nil and partie.version == Sauvegarde.VERSION, "v1 → v2 : argent repris, réputation laissée")
ancien.donnees.joueur_8 = { argent = 9999 }
A:enregistrer(8, partie, true)
U.verifier(A:charger(8).argent == 480, "l'ancienne sauvegarde n'est reprise qu'une fois")
U.verifier(Sauvegarde.migrer({ argent = "beaucoup" }).argent == EtatAtelier.ARGENT_DEPART, "argent v1 illisible : argent de départ")
U.verifier(Sauvegarde.migrer({ argent = -50 }).argent == 0, "argent v1 négatif : 0")
U.verifier(Sauvegarde.migrer({ version = Sauvegarde.VERSION + 1 }) == nil, "partie d'une version plus récente : pas migrée")

---------------------------------------------------------------------------
-- Une partie en cours (une robe livrée, la suivante au milieu de la découpe) : sauvée, relue à l'identique
---------------------------------------------------------------------------
local CROQUIS = { corsage = "corsage_droit", manches = "manches_sans", col = "col_sans", jupe = "jupe_droite" }
local ORDRE = { "corsage_droit_devant", "corsage_droit_dos", "jupe_droite_devant", "jupe_droite_dos" }
local PLACES = {
	corsage_droit_devant = { x = 2.4, y = 2.1, angle = 0 },
	corsage_droit_dos = { x = 7.2, y = 2.1, angle = 0 },
	jupe_droite_devant = { x = 2.5, y = 7.2, angle = 0 },
	jupe_droite_dos = { x = 7.5, y = 7.2, angle = 0 },
}
local tissus = {}
for _, id in ipairs(ORDRE) do
	tissus[id] = "coton_blanc"
end
local etat = EtatAtelier.nouveau(1000)
etat:nouvelleCommande(Random.new(2))
etat:validerCroquis(CROQUIS, tissus)
etat:acheter("coton_blanc", 24)
etat:commencerDecoupe()
for _, id in ipairs(ORDRE) do
	etat:couper(id, PLACES[id])
end
for _, id in ipairs(ORDRE) do
	etat:epingler(id)
end
for _, id in ipairs(ORDRE) do
	local _, l = Patron.trajetCouture(id)
	etat:rendreCouture(id, table.create(math.round(l / 0.1), 0.02), l)
end
etat:decorer({})
etat.commande.exigences = { { type = "qualite", valeur = 0.1 } }
U.verifier(etat:livrer().reussie, "une robe livrée (mise en place du test)")
etat:nouvelleCommande(Random.new(3))
etat:validerCroquis(CROQUIS, tissus)
etat:commencerDecoupe()
etat:couper(ORDRE[1], PLACES[ORDRE[1]])
U.verifier(etat.etape == "decoupe" and #etat:piecesAPoser() == 3, "la suivante au milieu de la découpe (mise en place du test)")

local p = Sauvegarde.depuisEtat(etat)
U.verifier(p.enCours ~= nil and p.enCours.etape == "decoupe" and p.enCours.coupons.coton_blanc ~= nil and #p.recettes == 1, "la commande en cours et les robes sont dans la partie")
U.verifier(pcall(M.transmettre, p), "la partie se range dans le DataStore")
U.verifier(A:enregistrer(7, p) == "ok" and magasin.donnees.joueur_7.verrou.jobId == "A", "partie enregistrée, verrou gardé")
temps += 60
A:enregistrer(7, p)
U.verifier(magasin.donnees.joueur_7.verrou.t == temps, "verrou rafraîchi à chaque sauvegarde")
A:enregistrer(7, p, true)
U.verifier(magasin.donnees.joueur_7.verrou == nil, "verrou rendu au départ")
attentes = 0
local relue = Sauvegarde.versEtat(B:charger(7))
U.verifier(attentes == 0 and magasin.donnees.joueur_7.verrou.jobId == "B", "verrou rendu : B prend la partie sans attendre")
U.verifier(relue.etape == "decoupe" and relue.argent == etat.argent and relue.stock.coton_blanc == etat.stock.coton_blanc, "relue : étape, argent, stock")
U.verifier(relue.commande.taille == etat.commande.taille and #relue:piecesAPoser() == 3 and Recette.encoder(relue.robes[1]) == Recette.encoder(etat.robes[1]), "relue : commande, pièces coupées, robe livrée")
U.verifier(relue:couper(ORDRE[2], PLACES[ORDRE[2]]).ok, "la découpe continue")
local accueil = Sauvegarde.depuisEtat(EtatAtelier.nouveau())
U.verifier(accueil.enCours == nil, "à l'accueil, pas de commande en cours")

---------------------------------------------------------------------------
-- Verrou tenu par un serveur vivant : essais toutes les 3 s, puis on prend la main après 15 s
---------------------------------------------------------------------------
attentes = 0
local debut = temps
partie, statut = A:charger(7)
U.verifier(statut == "ok" and temps - debut == Sauvegarde.ESSAI_MAX and attentes == Sauvegarde.ESSAI_MAX / Sauvegarde.ESSAI_PAS, "partie tenue ailleurs : essais toutes les 3 s, prise après 15 s")
U.verifier(magasin.donnees.joueur_7.verrou.jobId == "A", "A a pris la main")
local ecritures = magasin.ecritures
U.verifier(B:enregistrer(7, p) == "perdu" and magasin.ecritures == ecritures, "B a perdu la partie : il ne l'écrase plus")
temps += Sauvegarde.VERROU_VIVANT + 1
attentes = 0
partie, statut = B:charger(7)
U.verifier(statut == "ok" and attentes == 0 and magasin.donnees.joueur_7.verrou.jobId == "B", "verrou périmé (plus de 90 s) : pris sans attendre")

---------------------------------------------------------------------------
-- Protections : lecture ratée, version plus récente, écriture impossible
---------------------------------------------------------------------------
magasin.panne = 1
ecritures = magasin.ecritures
partie, statut = A:charger(9)
U.verifier(partie == nil and statut == "echec" and magasin.ecritures == ecritures, "lecture ratée : échec, rien écrit")
ancien.panne = 1
partie, statut = A:charger(10)
U.verifier(partie == nil and statut == "echec" and magasin.donnees.joueur_10 == nil, "ancienne sauvegarde illisible : échec, rien écrit")
magasin.donnees.joueur_11 = { version = Sauvegarde.VERSION + 1, argent = 5000 }
partie, statut = A:charger(11)
U.verifier(statut == "echec" and magasin.donnees.joueur_11.argent == 5000 and magasin.donnees.joueur_11.verrou == nil, "version plus récente : ni chargée, ni touchée")
U.verifier(A:enregistrer(11, accueil) == "perdu" and magasin.donnees.joueur_11.argent == 5000, "version plus récente : jamais écrasée")
magasin.donnees.joueur_12 = "illisible"
partie, statut = A:charger(12)
U.verifier(statut == "echec" and magasin.donnees.joueur_12 == "illisible", "partie illisible : ni chargée, ni touchée")
magasin.panne = 1
U.verifier(B:enregistrer(7, p) == "echec", "écriture impossible : échec signalé (on réessaiera)")

---------------------------------------------------------------------------
-- Partie abîmée : ce qui est illisible est laissé, le reste est gardé
---------------------------------------------------------------------------
local abimee = Sauvegarde.depuisEtat(etat)
abimee.enCours.croquis = { corsage = "inconnu", manches = "manches_sans", col = "col_sans", jupe = "jupe_droite" }
M.avertissements = {}
local e = Sauvegarde.versEtat(abimee)
U.verifier(e.etape == "accueil" and e.commande == nil and e.argent == etat.argent and e.stock.coton_blanc == etat.stock.coton_blanc and #e.robes == 1, "commande en cours illisible : abandonnée, le reste gardé")
U.verifier(#M.avertissements == 1, "un avertissement")
local s = Sauvegarde.depuisEtat(EtatAtelier.nouveau())
s.argent = 0 / 0
s.stock = { coton_blanc = 12, inconnu = 5, soie_rouge = "x", lin_bleu = -3 }
s.recettes = { etat.robes[1], { version = 1, bidon = true } }
e = Sauvegarde.versEtat(s)
U.verifier(e.argent == EtatAtelier.ARGENT_DEPART, "argent illisible : argent de départ")
U.verifier(e.stock.coton_blanc == 12 and e.stock.inconnu == nil and e.stock.soie_rouge == nil and e.stock.lin_bleu == nil, "stock abîmé : seules les entrées valides restent")
U.verifier(#e.robes == 1, "robe illisible laissée de côté")

---------------------------------------------------------------------------
-- Dans le jeu : pas de DataStore sur un lieu non publié
---------------------------------------------------------------------------
M.avertissements = {}
U.verifier(Sauvegarde.pourLeJeu() == nil and #M.avertissements == 1, "lieu non publié : pas de sauvegarde, un avertissement")
rawget(M.game, "__props").PlaceId = 4242
rawget(M.game, "__props").JobId = "serveur-test"
M.magasins = {}
local jeu = Sauvegarde.pourLeJeu()
U.verifier(jeu ~= nil and jeu.jobId == "serveur-test" and jeu.magasin == M.magasins.AtelierCouture_v2 and jeu.ancien == M.magasins.AtelierCouture_v1, "lieu publié : DataStore v2, et v1 pour la reprise")
M.magasins = nil
rawget(M.game, "__props").PlaceId = 0
rawget(M.game, "__props").JobId = ""
```

- [ ] **Step 3: Lancer les tests, vérifier l'échec**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT|attempt|membre" | head -3`
Expected: échec : une ligne qui finit par `Sauvegarde n'est pas un membre valide de Folder « Couture »` (le module n'existe pas encore)

- [ ] **Step 4: Écrire le module**

`src/server/Sauvegarde.luau` :

```lua
-- Sauvegarde (serveur) : la partie de chaque joueur dans le DataStore « AtelierCouture_v2 », une clé par
-- joueur (spec §6). Écriture par UpdateAsync, avec un verrou de session { jobId, t } : si un autre serveur
-- tient la partie depuis moins de 90 s, on réessaie toutes les 3 s pendant 15 s au plus, puis on prend la
-- main. Aucune écriture si la lecture a échoué, ni sur une partie d'une version plus récente du jeu.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")
local Couture = ReplicatedStorage:WaitForChild("Couture")
local Catalogue = require(Couture:WaitForChild("Catalogue"))
local Recette = require(Couture:WaitForChild("Recette"))
local EtatAtelier = require(Couture:WaitForChild("EtatAtelier"))

local Sauvegarde = {}
Sauvegarde.__index = Sauvegarde

Sauvegarde.VERSION = 2
Sauvegarde.MAGASIN = "AtelierCouture_v2"
Sauvegarde.ANCIEN_MAGASIN = "AtelierCouture_v1" -- le prototype : { argent, reputation }
Sauvegarde.VERROU_VIVANT = 90 -- s : un verrou plus récent appartient à un serveur encore en vie
Sauvegarde.ESSAI_PAS = 3 -- s entre deux essais quand la partie est tenue ailleurs
Sauvegarde.ESSAI_MAX = 15 -- s : au-delà, on prend la main
-- Champs de l'état qui forment la commande en cours (une déconnexion ne perd pas le travail)
local EN_COURS = { "etape", "commande", "croquis", "tissus", "coupees", "coupons", "epinglees", "coutures", "accessoires" }

local function cle(userId)
	return "joueur_" .. tostring(userId)
end

local function nombre(n, defaut)
	if type(n) ~= "number" or n ~= n or n == math.huge or n == -math.huge then
		return defaut
	end
	return n
end

local function copie(v)
	if type(v) ~= "table" then
		return v
	end
	local c = {}
	for k, x in pairs(v) do
		c[k] = copie(x)
	end
	return c
end

-- Migrations : MIGRATIONS[v] passe une partie du format v au format v + 1
Sauvegarde.MIGRATIONS = {
	-- v1 (prototype) : seul l'argent est repris ; une table vide donne une partie neuve
	[1] = function(v1)
		return {
			version = 2,
			argent = math.max(0, math.floor(nombre(v1.argent, EtatAtelier.ARGENT_DEPART))),
			stock = {},
			debloques = { tissus = {}, variantes = {}, accessoires = {} }, -- (sous-projet 2)
			recettes = {},
		}
	end,
}

-- La partie au format actuel, ou nil si elle vient d'une version plus récente du jeu (on n'y touche pas)
function Sauvegarde.migrer(partie)
	local version = nombre(partie.version, 1) -- la v1 n'avait pas de numéro
	if version > Sauvegarde.VERSION then
		return nil
	end
	while version < Sauvegarde.VERSION do
		partie = Sauvegarde.MIGRATIONS[version](partie)
		version = partie.version
	end
	return partie
end

-- La partie d'un état de l'atelier (debloques : ceux de la partie chargée, gardés tels quels)
function Sauvegarde.depuisEtat(etat, debloques)
	local d = etat:exporter()
	local partie = {
		version = Sauvegarde.VERSION,
		argent = d.argent,
		stock = d.stock,
		debloques = copie(debloques) or { tissus = {}, variantes = {}, accessoires = {} },
		recettes = d.robes,
	}
	if d.etape ~= "accueil" then
		partie.enCours = {}
		for _, champ in ipairs(EN_COURS) do
			partie.enCours[champ] = d[champ]
		end
	end
	return partie
end

-- L'état de l'atelier d'une partie. Ce qui est illisible (tissu retiré du catalogue, données abîmées) est
-- laissé de côté ; une commande en cours illisible est abandonnée, l'argent, le stock et les robes restent.
function Sauvegarde.versEtat(partie)
	local base = EtatAtelier.nouveau(math.max(0, nombre(partie.argent, EtatAtelier.ARGENT_DEPART)))
	for id, dm in pairs(type(partie.stock) == "table" and partie.stock or {}) do
		if type(id) == "string" and Catalogue.tissu(id) and nombre(dm, -1) >= 0 then
			base.stock[id] = dm
		end
	end
	for _, r in ipairs(type(partie.recettes) == "table" and partie.recettes or {}) do
		local lue, valide = pcall(Recette.valider, r)
		if lue and valide and #base.robes < EtatAtelier.ROBES_GARDEES then
			table.insert(base.robes, r)
		end
	end
	if type(partie.enCours) ~= "table" then
		return base
	end
	local d = base:exporter()
	for _, champ in ipairs(EN_COURS) do
		if partie.enCours[champ] ~= nil then
			d[champ] = partie.enCours[champ]
		end
	end
	local etat = EtatAtelier.nouveau()
	local ok, erreur = pcall(function()
		etat:charger(d)
		assert(table.find(EtatAtelier.ETAPES, etat.etape), "étape inconnue")
		assert(etat.etape == "accueil" or etat.commande, "commande manquante")
		etat:piecesDuCroquis() -- lit le croquis
		etat:recette() -- lit les pièces coupées, les coutures et les décorations
	end)
	if not ok then
		warn("[Atelier] Commande en cours illisible, abandonnée : " .. tostring(erreur))
		return base
	end
	return etat
end

function Sauvegarde.nouvelle(options)
	return setmetatable({
		magasin = options.magasin,
		ancien = options.ancien,
		jobId = options.jobId,
		horloge = options.horloge or os.time,
		attendre = options.attendre or task.wait,
	}, Sauvegarde)
end

-- Pour le jeu : nil (sans erreur) si le lieu n'est pas publié ou si le DataStore est indisponible
function Sauvegarde.pourLeJeu()
	if game.PlaceId == 0 then
		warn("[Atelier] Lieu non publié : les parties ne sont pas sauvegardées.")
		return nil
	end
	local ok, magasin, ancien = pcall(function()
		return DataStoreService:GetDataStore(Sauvegarde.MAGASIN), DataStoreService:GetDataStore(Sauvegarde.ANCIEN_MAGASIN)
	end)
	if not ok then
		warn("[Atelier] DataStore indisponible, les parties ne sont pas sauvegardées : " .. tostring(magasin))
		return nil
	end
	return Sauvegarde.nouvelle({ magasin = magasin, ancien = ancien, jobId = game.JobId })
end

-- Prend la partie d'un joueur et son verrou. Renvoie la partie (sans le verrou) et "ok", ou nil et "echec"
-- (lecture impossible, partie illisible ou d'une version plus récente) : rien ne sera écrit pour ce joueur.
function Sauvegarde:charger(userId)
	local debut = self.horloge()
	local ancienne = nil -- ancienne sauvegarde (v1), lue une fois pour un joueur sans partie v2
	while true do
		local maintenant = self.horloge()
		local prendre = maintenant - debut >= Sauvegarde.ESSAI_MAX
		local absente, tenue, illisible, partie
		local ok = pcall(function()
			self.magasin:UpdateAsync(cle(userId), function(actuelle)
				absente, tenue, illisible, partie = false, false, false, nil -- (Roblox peut rappeler cette fonction)
				if actuelle == nil then
					if not ancienne then
						absente = true
						return nil
					end
					actuelle = ancienne
				end
				if type(actuelle) ~= "table" then
					illisible = true
					return nil
				end
				local verrou = actuelle.verrou
				if not prendre and type(verrou) == "table" and verrou.jobId ~= self.jobId
					and maintenant - nombre(verrou.t, 0) < Sauvegarde.VERROU_VIVANT then
					tenue = true
					return nil
				end
				local migree = Sauvegarde.migrer(copie(actuelle))
				if not migree then
					illisible = true
					return nil
				end
				migree.verrou = { jobId = self.jobId, t = maintenant }
				partie = migree
				return migree
			end)
		end)
		if not ok or illisible then
			return nil, "echec"
		end
		if absente then
			local lue, v1 = pcall(function()
				return self.ancien and self.ancien:GetAsync(cle(userId))
			end)
			if not lue then
				return nil, "echec"
			end
			ancienne = type(v1) == "table" and v1 or {} -- rien : une partie neuve
		elseif tenue then
			self.attendre(Sauvegarde.ESSAI_PAS)
		else
			partie.verrou = nil
			return partie, "ok"
		end
	end
end

-- Écrit la partie d'un joueur et rafraîchit son verrou (ou le rend, si liberer). Renvoie "ok", "echec"
-- (le DataStore n'a pas répondu : on réessaiera) ou "perdu" (un autre serveur a pris la partie, ou elle
-- vient d'une version plus récente : ne plus l'écraser depuis ce serveur).
function Sauvegarde:enregistrer(userId, partie, liberer)
	local perdu = false
	local ok = pcall(function()
		self.magasin:UpdateAsync(cle(userId), function(actuelle)
			perdu = false
			if type(actuelle) == "table" then
				local verrou = actuelle.verrou
				if (type(verrou) == "table" and verrou.jobId ~= self.jobId) or nombre(actuelle.version, 1) > Sauvegarde.VERSION then
					perdu = true
					return nil
				end
			end
			local d = copie(partie)
			d.version = Sauvegarde.VERSION
			d.verrou = if liberer then nil else { jobId = self.jobId, t = self.horloge() }
			return d
		end)
	end)
	if not ok then
		return "echec"
	end
	return perdu and "perdu" or "ok"
end

return Sauvegarde
```

- [ ] **Step 5: Lancer les tests**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT"`
Expected:
```
Unitaires : 104877 vérifications
TOUT EST VERT : 302 vérifications
```

- [ ] **Step 6: Commit**

```bash
git add tests/mock.luau src/server/Sauvegarde.luau tests/unitaires/30_sauvegarde.luau
git commit -m "La sauvegarde : format v2, migrations, verrou de session, aucune écriture après une lecture ratée

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 2: Le serveur lit et écrit les parties

**Files:**
- Modify: `src/server/Commande.luau` (en-tête, constantes, `nouvelle` à `retirer`, `traiter`)
- Modify: `src/server/init.server.luau` (réécrit)
- Test: `tests/unitaires/31_commande_sauvegarde.luau`, `tests/scenario.luau` (lieu publié, sauvegardes)

**Interfaces:**
- Consumes: `Sauvegarde.nouvelle`, `pourLeJeu`, `charger`, `enregistrer`, `depuisEtat`, `versEtat`, `ESSAI_MAX`, `ESSAI_PAS`, `VERSION` (tâche 1) ; `M.nouveauMagasin`, `M.magasins`, `M.fermeture` (faux Roblox).
- Produces:
  - `Commande.nouvelle(options?)` avec `options = { sauvegarde?, horloge?, attendre? }` ; `Commande.PERIODE_SAUVEGARDE = 60`, `Commande.FERMETURE_MAX = 25`.
  - `Commande:atelier(joueur) -> atelier?` (nil tant que la partie n'est pas lue, avec une sauvegarde) ; atelier = `{ etat, rng, sauvable, debloques? }`.
  - `Commande:arrivee(joueur)`, `Commande:enregistrer(joueur, liberer?) -> statut?`, `Commande:enregistrerTout()`, `Commande:depart(joueur)`, `Commande:retirer(joueur)`, `Commande:fermer()`.
  - `traiter` : `{ ok = false, erreur = "L'atelier se prépare, réessaie dans un instant.", attente = true }` avant la lecture ; la réponse acceptée à `etat` porte `avertissement` (texte) si la partie n'est pas sauvable.

- [ ] **Step 1: Écrire le test du serveur avec sauvegarde**

`tests/unitaires/31_commande_sauvegarde.luau` :

```lua
local Commande = U.module("Commande")
local Sauvegarde = U.module("Sauvegarde")
local EtatAtelier = U.module("EtatAtelier")

-- Des serveurs qui partagent le même DataStore ; horloge simulée ; attendre fait passer le temps
local magasin = M.nouveauMagasin()
local temps, attentes = 2000000, 0
local function sauvegarde(jobId)
	return Sauvegarde.nouvelle({
		magasin = magasin,
		ancien = M.nouveauMagasin(),
		jobId = jobId,
		horloge = function()
			return temps
		end,
		attendre = function(s)
			attentes += 1
			temps += s
		end,
	})
end
local function joueurNumero(nom, userId)
	local j = M.nouveauJoueur(nom)
	rawget(j, "__props").UserId = userId
	return j
end
local function appeler(serveur, joueur, action, ...)
	M.avancer(0.25)
	return serveur:traiter(joueur, action, ...)
end

---------------------------------------------------------------------------
-- Arrivée : l'atelier se prépare le temps de lire la partie
---------------------------------------------------------------------------
local fidele = joueurNumero("Fidele", 501)
local s1 = Commande.nouvelle({ sauvegarde = sauvegarde("S1") })
local r = appeler(s1, fidele, "etat")
U.verifier(not r.ok and r.attente == true and r.erreur == "L'atelier se prépare, réessaie dans un instant.", "avant le chargement : l'atelier se prépare")
s1:arrivee(fidele)
r = appeler(s1, fidele, "etat")
U.verifier(r.ok and r.etat.argent == EtatAtelier.ARGENT_DEPART and r.avertissement == nil, "partie chargée (neuve), sans avertissement")

-- Une commande jusqu'à la découpe
appeler(s1, fidele, "nouvelleCommande")
local CROQUIS = { corsage = "corsage_droit", manches = "manches_sans", col = "col_sans", jupe = "jupe_droite" }
appeler(s1, fidele, "validerCroquis", CROQUIS, {
	corsage_droit_devant = "coton_blanc",
	corsage_droit_dos = "coton_blanc",
	jupe_droite_devant = "coton_blanc",
	jupe_droite_dos = "coton_blanc",
})
appeler(s1, fidele, "acheter", "coton_blanc", 12)
appeler(s1, fidele, "commencerDecoupe")
r = appeler(s1, fidele, "couper", "corsage_droit_devant", { x = 2.4, y = 2.1, angle = 0 })
U.verifier(r.ok and r.etat.etape == "decoupe", "une pièce coupée (mise en place du test)")
local avant = s1:atelier(fidele).etat:exporter()

---------------------------------------------------------------------------
-- Sauvegarde régulière, départ, retour sur un autre serveur
---------------------------------------------------------------------------
s1:enregistrerTout()
local rangee = magasin.donnees.joueur_501
U.verifier(rangee ~= nil and rangee.enCours.etape == "decoupe" and rangee.verrou.jobId == "S1", "sauvegarde régulière : la commande en cours, verrou tenu")
fidele.Parent = nil
s1:depart(fidele)
U.verifier(magasin.donnees.joueur_501.verrou == nil and s1.ateliers[fidele] == nil, "départ : partie écrite, verrou rendu, atelier libéré")
fidele.Parent = M.services.Players
local s2 = Commande.nouvelle({ sauvegarde = sauvegarde("S2") })
attentes = 0
s2:arrivee(fidele)
r = appeler(s2, fidele, "etat")
U.verifier(attentes == 0 and r.ok and r.etat.etape == "decoupe" and r.etat.argent == avant.argent and r.etat.stock.coton_blanc == avant.stock.coton_blanc, "retour : la commande reprend où elle en était")
U.verifier(r.etat.commande.taille == avant.commande.taille and r.etat.coupees.corsage_droit_devant ~= nil, "retour : même commande, pièce déjà coupée")
r = appeler(s2, fidele, "couper", "corsage_droit_dos", { x = 7.2, y = 2.1, angle = 0 })
U.verifier(r.ok, "la découpe continue sur le nouveau serveur")

---------------------------------------------------------------------------
-- Partie prise par un autre serveur : on cesse de l'écrire
---------------------------------------------------------------------------
local s3 = Commande.nouvelle({ sauvegarde = sauvegarde("S3") })
attentes = 0
s3:arrivee(fidele) -- S2 tient encore la partie : S3 attend 15 s, puis prend la main
U.verifier(attentes == Sauvegarde.ESSAI_MAX / Sauvegarde.ESSAI_PAS and magasin.donnees.joueur_501.verrou.jobId == "S3", "un autre serveur prend la main après 15 s")
M.avertissements = {}
local ecritures = magasin.ecritures
U.verifier(s2:enregistrer(fidele) == "perdu" and magasin.ecritures == ecritures and #M.avertissements == 1, "l'ancien serveur ne l'écrase pas, un avertissement")
s2:enregistrerTout()
s2:depart(fidele)
U.verifier(magasin.ecritures == ecritures and magasin.donnees.joueur_501.verrou.jobId == "S3", "il ne l'écrit plus du tout, même au départ")

---------------------------------------------------------------------------
-- Lecture ratée : partie neuve pour cette fois, jamais écrite, le joueur est prévenu
---------------------------------------------------------------------------
local malchance = joueurNumero("Malchance", 502)
magasin.donnees.joueur_502 = { version = Sauvegarde.VERSION, argent = 900, stock = {}, debloques = {}, recettes = {} }
magasin.panne = 1
s3:arrivee(malchance)
r = appeler(s3, malchance, "etat")
U.verifier(r.ok and r.etat.argent == EtatAtelier.ARGENT_DEPART and type(r.avertissement) == "string", "lecture ratée : partie neuve, joueur prévenu")
ecritures = magasin.ecritures
appeler(s3, malchance, "nouvelleCommande")
s3:enregistrerTout()
malchance.Parent = nil
s3:depart(malchance)
U.verifier(magasin.donnees.joueur_502.argent == 900 and magasin.ecritures == ecritures + 1, "sa vraie partie n'est jamais écrasée (seule celle de Fidele est écrite)")

---------------------------------------------------------------------------
-- Joueur parti pendant le chargement : sa partie est rendue tout de suite, pas d'atelier
---------------------------------------------------------------------------
local presse = joueurNumero("Presse", 503)
presse.Parent = nil
s3:arrivee(presse)
U.verifier(s3.ateliers[presse] == nil and magasin.donnees.joueur_503 ~= nil and magasin.donnees.joueur_503.verrou == nil, "parti pendant le chargement : partie rendue, pas d'atelier")

---------------------------------------------------------------------------
-- Arrêt du serveur : toutes les parties écrites, verrous rendus
---------------------------------------------------------------------------
s3:fermer()
U.verifier(magasin.donnees.joueur_501.verrou == nil and magasin.donnees.joueur_501.enCours.etape == "decoupe", "arrêt du serveur : partie écrite, verrou rendu")

---------------------------------------------------------------------------
-- Sans sauvegarde (lieu non publié) : partie neuve tout de suite, comme avant
---------------------------------------------------------------------------
local libre = Commande.nouvelle()
local visiteuse = joueurNumero("Visiteuse", 504)
r = appeler(libre, visiteuse, "etat")
U.verifier(r.ok and r.etat.argent == EtatAtelier.ARGENT_DEPART and r.avertissement == nil, "sans sauvegarde : partie neuve, sans attente ni avertissement")
libre:arrivee(visiteuse)
libre:depart(visiteuse)
U.verifier(libre.ateliers[visiteuse] == nil, "sans sauvegarde : départ sans écriture")
```

- [ ] **Step 2: Lancer les tests, vérifier l'échec**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT|attempt" | head -3`
Expected: échec : une ligne qui finit par `ÉCHEC : avant le chargement : l'atelier se prépare`

- [ ] **Step 3: La Commande lit et écrit les parties**

Dans `src/server/Commande.luau` :

1. Remplacer les sept premières lignes (le commentaire d'en-tête et les `require`, jusqu'à `local Limiteur = require(script.Parent:WaitForChild("Limiteur"))`) par :

```lua
-- Commande (serveur) : l'atelier de chaque joueur, qui fait foi (spec §2). Chaque action du client
-- passe par Commande:traiter : action connue, limite d'appels, règles d'EtatAtelier. Une réponse
-- acceptée emporte l'état (EtatAtelier:exporter), que le client recharge et affiche.
-- Avec une sauvegarde, la partie est lue à l'arrivée du joueur et écrite régulièrement, à son départ
-- et à l'arrêt du serveur ; sans (lieu non publié), chaque joueur commence une partie neuve.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Couture = ReplicatedStorage:WaitForChild("Couture")
local EtatAtelier = require(Couture:WaitForChild("EtatAtelier"))
local Limiteur = require(script.Parent:WaitForChild("Limiteur"))
local Sauvegarde = require(script.Parent:WaitForChild("Sauvegarde"))
```

2. Juste après `Commande.APPELS_PAR_SECONDE = 5 -- par joueur (spec §6)`, ajouter :

```lua
Commande.PERIODE_SAUVEGARDE = 60 -- s entre deux sauvegardes de toutes les parties (spec §6)
Commande.FERMETURE_MAX = 25 -- s : à l'arrêt du serveur, attente maximale des dernières sauvegardes
local PREPARATION = "L'atelier se prépare, réessaie dans un instant."
local SANS_SAUVEGARDE = "Ta partie ne peut pas être sauvegardée pour le moment : tes progrès de cette session seront perdus."
```

3. Remplacer tout le passage qui va de `function Commande.nouvelle()` à la fin de `function Commande:retirer(joueur) … end` (les trois fonctions `nouvelle`, `atelier`, `retirer` et leurs commentaires) par :

```lua
-- options (facultatif) : { sauvegarde = Sauvegarde, horloge = fonction, attendre = fonction }
function Commande.nouvelle(options)
	options = options or {}
	local self = setmetatable({
		ateliers = {}, -- [joueur] = { etat = EtatAtelier, rng = Random, sauvable = bool, debloques = table? }
		limiteur = Limiteur.nouveau(Commande.APPELS_PAR_SECONDE, 1),
		sauvegarde = options.sauvegarde,
		horloge = options.horloge or os.clock,
		attendre = options.attendre or task.wait,
	}, Commande)
	Commande.courante = self -- le serveur en cours (tests du scénario, débogage dans Studio)
	return self
end

-- L'atelier d'un joueur, ou nil tant que sa partie n'est pas lue. Sans sauvegarde, une partie neuve est
-- créée à son premier appel.
function Commande:atelier(joueur)
	local a = self.ateliers[joueur]
	if not a and not self.sauvegarde then
		a = { etat = EtatAtelier.nouveau(), rng = Random.new(), sauvable = false }
		self.ateliers[joueur] = a
	end
	return a
end

-- Arrivée d'un joueur : lit sa partie (peut attendre, jusqu'à 15 s si un autre serveur la tient). Si la
-- lecture échoue, il joue une partie neuve qui ne sera jamais écrite (sa vraie partie reste intacte).
function Commande:arrivee(joueur)
	if not self.sauvegarde then
		self:atelier(joueur)
		return
	end
	local partie, statut = self.sauvegarde:charger(joueur.UserId)
	if joueur.Parent == nil then
		-- parti pendant la lecture : sa partie est rendue tout de suite
		if statut == "ok" then
			self.sauvegarde:enregistrer(joueur.UserId, partie, true)
		end
		return
	end
	if statut ~= "ok" then
		warn(("[Atelier] %s : partie illisible, elle ne sera pas écrite pendant cette session."):format(joueur.Name))
	end
	self.ateliers[joueur] = {
		etat = partie and Sauvegarde.versEtat(partie) or EtatAtelier.nouveau(),
		rng = Random.new(),
		sauvable = statut == "ok",
		debloques = partie and partie.debloques,
	}
end

-- Écrit la partie d'un joueur (et rend son verrou, si liberer). Renvoie le statut de la sauvegarde, ou nil
-- si sa partie n'est pas à écrire. Une partie prise par un autre serveur n'est plus jamais écrite d'ici.
function Commande:enregistrer(joueur, liberer)
	local a = self.ateliers[joueur]
	if not self.sauvegarde or not a or not a.sauvable then
		return nil
	end
	local statut = self.sauvegarde:enregistrer(joueur.UserId, Sauvegarde.depuisEtat(a.etat, a.debloques), liberer)
	if statut == "perdu" then
		a.sauvable = false
		warn(("[Atelier] %s : sa partie est tenue par un autre serveur, elle n'est plus écrite d'ici."):format(joueur.Name))
	elseif statut == "echec" then
		warn(("[Atelier] %s : sauvegarde impossible pour l'instant, on réessaiera."):format(joueur.Name))
	end
	return statut
end

-- Sauvegarde régulière de toutes les parties (chacune dans sa tâche)
function Commande:enregistrerTout()
	for joueur in pairs(self.ateliers) do
		task.spawn(self.enregistrer, self, joueur, false)
	end
end

-- Départ du joueur : partie écrite, verrou rendu, atelier libéré
function Commande:depart(joueur)
	self:enregistrer(joueur, true)
	self:retirer(joueur)
end

-- Atelier libéré, sans écrire
function Commande:retirer(joueur)
	self.ateliers[joueur] = nil
	self.limiteur:oublier(joueur)
end

-- Arrêt du serveur : toutes les parties écrites en même temps, verrous rendus (25 s au plus)
function Commande:fermer()
	local restantes = 0
	for joueur in pairs(self.ateliers) do
		restantes += 1
		task.spawn(function()
			self:enregistrer(joueur, true)
			restantes -= 1
		end)
	end
	local debut = self.horloge()
	while restantes > 0 and self.horloge() - debut < Commande.FERMETURE_MAX do
		self.attendre(0.5)
	end
end
```

4. Dans `Commande:traiter`, juste après `local a = self:atelier(joueur)`, ajouter :

```lua
	if not a then
		return { ok = false, erreur = PREPARATION, attente = true }
	end
```

5. Toujours dans `traiter`, remplacer

```lua
	if reponse.ok then
		reponse.etat = Commande.instantane(a.etat)
	end
```

par :

```lua
	if reponse.ok then
		reponse.etat = Commande.instantane(a.etat)
		if action == "etat" and self.sauvegarde and not a.sauvable then
			reponse.avertissement = SANS_SAUVEGARDE
		end
	end
```

- [ ] **Step 4: Lancer les tests**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT"`
Expected (le scénario joue encore sur un lieu non publié) :
```
Unitaires : 104894 vérifications
TOUT EST VERT : 302 vérifications
```

- [ ] **Step 5: Le scénario joue sur un lieu publié**

Dans `tests/scenario.luau` :

1. Juste avant la ligne `-- Serveur (il fait foi) : démarré avant le client, qui attend sa RemoteFunction « Atelier »`, ajouter :

```lua
-- Lieu publié : les parties sont sauvegardées (DataStores en mémoire du faux Roblox). La première lecture
-- de la partie du joueur échoue : il joue sans sauvegarde, et sa vraie partie n'est jamais écrasée.
rawget(game, "__props").PlaceId = 4242
rawget(game, "__props").JobId = "serveur-scenario"
M.magasins = { AtelierCouture_v2 = M.nouveauMagasin() }
M.magasins.AtelierCouture_v2.panne = 1
```

2. Juste après `verifier(argent() == 150, "150 pièces d'or au départ")`, ajouter :

```lua
local parties = M.magasins.AtelierCouture_v2
local cleJoueur = "joueur_" .. joueur.UserId
verifier(parties.donnees[cleJoueur] == nil and serveur:atelier(joueur) ~= nil and not serveur:atelier(joueur).sauvable, "lecture ratée : le joueur joue sans sauvegarde")
```

3. Juste après `verifier(etatJeu.argent == argentServeur and titre() == "3. Table de découpe", "la copie du client revient à l'état du serveur")`, ajouter :

```lua

---------------------------------------------------------------------------
-- Sauvegarde : la partie illisible n'est jamais écrite ; au retour, la partie est lue, puis écrite
-- régulièrement, au départ et à l'arrêt du serveur, et la commande reprend au retour suivant
---------------------------------------------------------------------------
M.avancer(serveur.PERIODE_SAUVEGARDE + 1)
M.services.Players.PlayerRemoving:Fire(joueur)
verifier(parties.donnees[cleJoueur] == nil and serveur.ateliers[joueur] == nil, "partie illisible : jamais écrite, ni régulièrement ni au départ")
M.services.Players.PlayerAdded:Fire(joueur)
verifier(parties.donnees[cleJoueur] ~= nil and parties.donnees[cleJoueur].verrou.jobId == "serveur-scenario", "retour du joueur : partie lue, verrou pris")
M.avancer(0.5)
verifier(serveur:traiter(joueur, "nouvelleCommande").ok, "une commande commencée sur le serveur")
M.avancer(serveur.PERIODE_SAUVEGARDE + 1)
verifier(parties.donnees[cleJoueur].enCours ~= nil and parties.donnees[cleJoueur].enCours.etape == "carnet", "sauvegarde régulière : la commande en cours")
M.services.Players.PlayerRemoving:Fire(joueur)
verifier(parties.donnees[cleJoueur].verrou == nil and serveur.ateliers[joueur] == nil, "départ du joueur : partie écrite, verrou rendu")
M.services.Players.PlayerAdded:Fire(joueur)
verifier(serveur:atelier(joueur) ~= nil and serveur:atelier(joueur).etat.etape == "carnet", "retour suivant : la commande reprend")
M.fermeture()
verifier(parties.donnees[cleJoueur].verrou == nil and parties.donnees[cleJoueur].enCours.etape == "carnet", "arrêt du serveur : partie écrite, verrou rendu")
```

- [ ] **Step 6: Lancer les tests, vérifier l'échec**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT|attempt" | head -3`
Expected: échec : une ligne qui finit par `ÉCHEC : retour du joueur : partie lue, verrou pris` (unitaires : 104894 vérifications)

- [ ] **Step 7: Brancher la sauvegarde dans le script du serveur**

`src/server/init.server.luau` :

```lua
-- Serveur de l'atelier : il fait foi (spec §2). Une seule RemoteFunction « Atelier », une action par
-- étape (Commande). Les parties sont sauvegardées (Sauvegarde) : lues à l'arrivée du joueur, écrites
-- toutes les 60 s, à son départ et à l'arrêt du serveur. Les boutiques de la rue arrivent au plan 4c.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Commande = require(script:WaitForChild("Commande"))
local Sauvegarde = require(script:WaitForChild("Sauvegarde"))

-- Pas de sauvegarde sur un lieu non publié, ni si le DataStore est indisponible (avertissement)
local commande = Commande.nouvelle({ sauvegarde = Sauvegarde.pourLeJeu() })

local remote = Instance.new("RemoteFunction")
remote.Name = "Atelier"
remote.OnServerInvoke = function(joueur, action, ...)
	return commande:traiter(joueur, action, ...)
end
remote.Parent = ReplicatedStorage

Players.PlayerAdded:Connect(function(joueur)
	commande:arrivee(joueur)
end)
for _, joueur in ipairs(Players:GetPlayers()) do
	task.spawn(commande.arrivee, commande, joueur)
end
Players.PlayerRemoving:Connect(function(joueur)
	commande:depart(joueur)
end)

local function sauvegardeReguliere()
	commande:enregistrerTout()
	task.delay(Commande.PERIODE_SAUVEGARDE, sauvegardeReguliere)
end
task.delay(Commande.PERIODE_SAUVEGARDE, sauvegardeReguliere)
game:BindToClose(function()
	commande:fermer()
end)
```

- [ ] **Step 8: Lancer les tests**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT"`
Expected:
```
Unitaires : 104894 vérifications
TOUT EST VERT : 310 vérifications
```

- [ ] **Step 9: Commit**

```bash
git add src/server/Commande.luau src/server/init.server.luau tests/unitaires/31_commande_sauvegarde.luau tests/scenario.luau
git commit -m "Le serveur lit la partie à l'arrivée et l'écrit toutes les 60 s, au départ et à l'arrêt

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 3: Le client attend sa partie et prévient le joueur

**Files:**
- Modify: `src/client/Atelier/Session.luau` (`ESSAIS_ARRIVEE`, `Session.distante`)
- Modify: `src/client/Atelier/init.client.luau` (`afficherMessage` ; avertissement au démarrage)
- Test: `tests/unitaires/32_session_attente.luau`, `tests/scenario.luau` (avertissement affiché)

**Interfaces:**
- Consumes: la réponse `{ attente = true }` et `avertissement` de `Commande:traiter` (tâche 2) ; `Session.distante`, `Session:actualiser` (plan 4a).
- Produces: `Session.ESSAIS_ARRIVEE = 30` ; `Session.distante(remote, attendre?)` ; `session.avertissement` (texte ou nil) ; `afficherMessage(texte, couleur?, duree?)` dans `init.client.luau`.

- [ ] **Step 1: Écrire le test de l'attente**

`tests/unitaires/32_session_attente.luau` :

```lua
local Session = U.module("Session")
local EtatAtelier = U.module("EtatAtelier")

-- Un serveur qui se prépare pendant « pret - 1 » appels, puis répond (avec un avertissement)
local remote = M.nouvelleInstance("RemoteFunction")
local appels, pret = 0, 3
local AVERTISSEMENT = "Ta partie ne peut pas être sauvegardée pour le moment."
remote.OnServerInvoke = function()
	appels += 1
	if appels < pret then
		return { ok = false, erreur = "L'atelier se prépare, réessaie dans un instant.", attente = true }
	end
	return { ok = true, etat = EtatAtelier.nouveau(777):exporter(), avertissement = AVERTISSEMENT }
end
M.joueurLocal = M.nouveauJoueur("Patiente")
local courante = Session.courante

local attendu = 0
local session = Session.distante(remote, function(s)
	attendu += s
end)
U.verifier(appels == 3 and attendu == 2 and session.etat.argent == 777, "la session attend que le serveur ait lu la partie (un essai par seconde)")
U.verifier(session.avertissement == AVERTISSEMENT, "l'avertissement du serveur est gardé pour l'interface")

-- Un serveur qui ne finit jamais de se préparer : abandon après Session.ESSAIS_ARRIVEE essais, sans erreur
appels, pret = 0, math.huge
local lasse = Session.distante(remote, function() end)
U.verifier(appels == Session.ESSAIS_ARRIVEE and lasse.etat.etape == "accueil" and lasse.avertissement == nil, "serveur jamais prêt : abandon après " .. tostring(Session.ESSAIS_ARRIVEE) .. " essais, état de départ")

-- Un autre refus n'est pas une attente : pas de nouvel essai
appels = 0
remote.OnServerInvoke = function()
	appels += 1
	return { ok = false, erreur = "Doucement !" }
end
Session.distante(remote, function()
	error("ne doit pas attendre")
end)
U.verifier(appels == 1, "un refus qui n'est pas une attente : pas de nouvel essai")
Session.courante = courante
```

- [ ] **Step 2: Lancer les tests, vérifier l'échec**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT|attempt" | head -3`
Expected: échec : une ligne qui finit par `ÉCHEC : la session attend que le serveur ait lu la partie (un essai par seconde)`

- [ ] **Step 3: La session attend la partie**

Dans `src/client/Atelier/Session.luau` :

1. Juste après `local INJOIGNABLE = "Le serveur ne répond pas. Réessaie."`, ajouter :

```lua
Session.ESSAIS_ARRIVEE = 30 -- à l'arrivée, un essai par seconde tant que le serveur lit la partie
```

2. Remplacer la fonction `Session.distante` et son commentaire (de `-- Session distante (le jeu) : remote = la RemoteFunction « Atelier » du serveur. Attend l'état du serveur.` à son `end`) par :

```lua
-- Session distante (le jeu) : remote = la RemoteFunction « Atelier » du serveur. Attend l'état du serveur,
-- le temps qu'il lise la partie du joueur (jusqu'à 15 s si un autre serveur la tenait). avertissement : un
-- message du serveur pour le joueur (sauvegarde impossible), ou nil. attendre (tests) : remplace task.wait.
-- rng ne sert qu'au client (mouvement du tissu à la machine à coudre) : le serveur tire ses commandes.
function Session.distante(remote, attendre)
	local self = setmetatable({ etat = EtatAtelier.nouveau(), remote = remote, rng = Random.new(), ecouteurs = {}, derniere = nil, enCours = false }, Session)
	Session.courante = self
	local reponse = self:actualiser()
	local essais = 1
	while not reponse.ok and reponse.attente and essais < Session.ESSAIS_ARRIVEE do
		(attendre or task.wait)(1)
		essais += 1
		reponse = self:actualiser()
	end
	self.avertissement = reponse.ok and reponse.avertissement or nil
	return self
end
```

- [ ] **Step 4: Lancer les tests**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT"`
Expected:
```
Unitaires : 104898 vérifications
TOUT EST VERT : 310 vérifications
```

- [ ] **Step 5: Le scénario vérifie l'avertissement**

Dans `tests/scenario.luau`, juste après la ligne `verifier(parties.donnees[cleJoueur] == nil and serveur:atelier(joueur) ~= nil and not serveur:atelier(joueur).sauvable, "lecture ratée : le joueur joue sans sauvegarde")`, ajouter :

```lua
verifier(fenetre.Message.Visible and string.find(fenetre.Message.Text, "sauvegardée", 1, true) ~= nil, "le joueur est prévenu que sa partie ne sera pas sauvegardée")
```

- [ ] **Step 6: Lancer les tests, vérifier l'échec**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT|attempt" | head -3`
Expected: échec : une ligne qui finit par `ÉCHEC : le joueur est prévenu que sa partie ne sera pas sauvegardée` (unitaires : 104898 vérifications)

- [ ] **Step 7: Afficher l'avertissement**

Dans `src/client/Atelier/init.client.luau` :

1. Remplacer le début de `afficherMessage`

```lua
local function afficherMessage(texte, couleur)
	jeton += 1
	local moi = jeton
	message.Text = texte
	message.TextColor3 = couleur or C.texte
	message.Visible = true
	task.delay(3, function()
```

par :

```lua
-- Message sous la fenêtre (duree : secondes, 3 par défaut)
local function afficherMessage(texte, couleur, duree)
	jeton += 1
	local moi = jeton
	message.Text = texte
	message.TextColor3 = couleur or C.texte
	message.Visible = true
	task.delay(duree or 3, function()
```

2. À la fin du fichier, après `afficher()`, ajouter :

```lua
-- Partie illisible sur le serveur : le joueur est prévenu que ses progrès ne seront pas sauvegardés
if session.avertissement then
	afficherMessage(session.avertissement, C.erreur, 10)
end
```

- [ ] **Step 8: Lancer les tests**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT"`
Expected:
```
Unitaires : 104898 vérifications
TOUT EST VERT : 311 vérifications
```

- [ ] **Step 9: Commit**

```bash
git add src/client/Atelier/Session.luau src/client/Atelier/init.client.luau tests/unitaires/32_session_attente.luau tests/scenario.luau
git commit -m "Le client attend que sa partie soit lue et prévient le joueur si elle ne peut pas être sauvegardée

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 4: Vérification dans Studio et README

**Files:**
- Modify: `README.md`
- Modify: `AtelierCouture.rbxl` (régénéré)

**Interfaces:**
- Consumes: tout ce qui précède.
- Produces: des parties sauvegardées. C'est le point de départ du plan 4c (boutiques de la rue, vitrines visibles par tous).

- [ ] **Step 1: Sur un lieu non publié**

Construire le lieu du dépôt (`C:/dev/jeux/roblox-maker/rojo.exe build -o <dossier temporaire>/Plan4bDepot.rbxl`), l'ouvrir dans Studio, et vérifier avec `execute_luau` (Edit) que `game.ServerScriptService.Atelier` contient `Commande`, `Limiteur` et `Sauvegarde`, et que `game.PlaceId == 0`.

- [ ] **Step 2: Le jeu tourne sans sauvegarde**

Lancer Play, attendre 3 s, cliquer `Clochette`. Avec `execute_luau`, lire `LogService:GetLogHistory()` côté Server, puis côté Client.

Expected : titre « 1. Carnet de croquis », 150 pièces d'or ; côté serveur, un seul avertissement hors CorePackages : « [Atelier] Lieu non publié : les parties ne sont pas sauvegardées. » ; côté client, aucune alerte (pas d'avertissement de sauvegarde, puisqu'il n'y a pas de sauvegarde). Arrêter Play : aucune erreur à l'arrêt.

- [ ] **Step 3: Mettre à jour le README**

Dans `README.md` :

1. Remplacer

```markdown
## État actuel (plan 4a)

Jouable dans Studio, en solo, sans sauvegarde. Le serveur tient l'atelier de chaque joueur et valide chaque
action (il fait foi) ; le client n'affiche qu'une copie de l'état :
```

par :

```markdown
## État actuel (plan 4b)

Jouable dans Studio, en solo. Le serveur tient l'atelier de chaque joueur et valide chaque action (il fait
foi) ; le client n'affiche qu'une copie de l'état. Dans un jeu publié, la partie est sauvegardée (argent,
stock de tissu, dix dernières robes et commande en cours : une déconnexion ne perd pas le travail) :
```

2. Remplacer

```markdown
9. La suite : sauvegarde (plan 4b), boutiques de la rue et vitrines visibles par tous (plan 4c),
   finition (plan 4d).
```

par :

```markdown
9. La suite : boutiques de la rue et vitrines visibles par tous (plan 4c), finition (plan 4d).
```

3. Remplacer les deux lignes

```markdown
  vraisemblance), toute erreur devient un refus ; chaque réponse acceptée emporte l'état. `Limiteur` compte
  les appels.
```

par :

```markdown
  vraisemblance), toute erreur devient un refus ; chaque réponse acceptée emporte l'état. `Limiteur` compte
  les appels. `Sauvegarde` range la partie de chaque joueur dans le DataStore `AtelierCouture_v2` (une clé
  par joueur, écriture par `UpdateAsync` avec un verrou de session, migrations, reprise de l'argent de
  l'ancienne clé `AtelierCouture_v1`) : lue à l'arrivée, écrite toutes les 60 s, au départ et à l'arrêt du
  serveur. Rien n'est écrit si la lecture a échoué (le joueur est prévenu), ni sur un lieu non publié.
```

4. Juste avant `**Limite assumée (couture)** :`, ajouter :

```markdown
**Tester la sauvegarde** : un lieu non publié (fichier local, `game.PlaceId == 0`) ne sauvegarde pas.
Publier un lieu de test privé et activer « Autoriser l'accès de Studio aux services d'API » (paramètres du
jeu, Sécurité) ; la logique (verrou, migrations, protections) est vérifiée par la simulation.
```

- [ ] **Step 4: Tests, lieu régénéré, commit**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT"`
Expected:
```
Unitaires : 104898 vérifications
TOUT EST VERT : 311 vérifications
```

```bash
C:/dev/jeux/roblox-maker/rojo.exe build -o AtelierCouture.rbxl
git add README.md AtelierCouture.rbxl
git commit -m "Plan 4b terminé : la sauvegarde des parties

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```
