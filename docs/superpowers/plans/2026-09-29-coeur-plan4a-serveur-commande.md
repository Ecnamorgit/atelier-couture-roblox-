# Cœur de l'atelier — Plan 4a : la commande tenue par le serveur

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Faire tenir l'atelier de chaque joueur par le serveur, qui fait foi (spec §1 critère 5, §2, §6) : une seule RemoteFunction « Atelier », les actions permises seulement, une limite d'appels, et un client qui n'affiche qu'une copie de l'état renvoyée par le serveur.

**Architecture:**
- **Serveur** (nouveau, `src/server/` → Script `Atelier` de ServerScriptService) : `Commande` garde un `EtatAtelier` et un générateur par joueur. `Commande:traiter(joueur, action, …)` n'accepte que les actions de sa liste, applique la limite d'appels (`Limiteur`) et appelle la règle d'`EtatAtelier` sous `pcall`. Une réponse acceptée emporte l'état (`EtatAtelier:exporter`).
- **État partagé** : `EtatAtelier` gagne `exporter()` (l'état en données simples, transmissibles par le réseau) et `charger(d)` (rechargement sur place ; ce qui n'a pas changé garde sa table).
- **Client** : `Session.distante(remote)` envoie chaque action au serveur et recharge l'état reçu. Les écrans ne changent pas : ils ne parlent qu'à la Session (plan 3a). La session locale reste pour les tests des écrans.

**Tech Stack:** Luau, Rojo 7.7.0-rc.1, simulation Luau 0.650 (`tests/lancer.sh`), Roblox Studio via le connecteur MCP Studio.

**Spec:** `docs/superpowers/specs/2026-09-28-atelier-coeur-design.md` (§1 critère 5 « Le serveur calcule […]. Le client n'envoie jamais de note », §2 répartition des rôles et modules `Commande`, §6 « Échanges » et « Ce que le serveur vérifie », §7 « Triche »). Plans précédents : `docs/superpowers/plans/2026-09-29-coeur-plan3a-postes.md` à `…plan3d-cliente-photo.md`.

## Décisions de ce plan

- **Découpage du plan 4** (spec §8, étapes 5 et 6). Ce plan-ci, **4a**, couvre la commande tenue par le serveur. Suivront **4b**, la sauvegarde (`Sauvegarde` : DataStore `AtelierCouture_v2`, verrou de session, migrations, reprise de `enCours`) ; **4c**, les boutiques de la rue (`Boutiques` : 8 emplacements, construction par le serveur, vitrines répliquées et visibles par tous) ; **4d**, la finition (sons, réglages mobiles, équilibrage, mineurs reportés). En 4a, un joueur qui part perd son atelier, comme aujourd'hui.
- **Noms des actions** : ce sont les méthodes d'`EtatAtelier` (`nouvelleCommande`, `validerCroquis`, `acheter`, `couper`, `epingler`, `rendreCouture`, `decorer`, `livrer`, `retoucher`, `abandonner`, `recommencer`, plus `retourCarnet`, `commencerDecoupe`, `retourDecorations`), et `etat` pour demander l'état à l'arrivée. La spec les écrit avec une majuscule (`ValiderCroquis`…) ; garder les noms du code évite une table de traduction. Le serveur n'appelle que les actions de sa liste, jamais une méthode quelconque (`exporter`, `charger`, `__index`… sont refusées).
- **État renvoyé** : chaque réponse acceptée emporte l'état exporté. Seule la robe en vitrine part (le serveur garde les dix dernières). Le client le recharge **sur place** : les écrans gardent le même objet `session.etat`, et une partie qui n'a pas changé garde sa table. La scène reconnaît ainsi la même commande d'une action à l'autre et ne refait pas entrer la cliente.
- **Hasard** : la commande est tirée par le serveur, avec son générateur ; l'argument envoyé par le client est ignoré. Le client garde un générateur local pour le mouvement du tissu à la machine à coudre, qui ne décide de rien.
- **Limite d'appels** (spec §6) : au plus 5 par seconde et par joueur, en fenêtre glissante ; au-delà, « Doucement ! ». `rendreCouture` n'y est pas soumise : sa propre vraisemblance la borne.
- **Robustesse** : une erreur imprévue dans une action devient un refus « Action impossible. », avec un avertissement dans la sortie du serveur ; le serveur continue. Côté client : une action à la fois (« Un instant… » pour un second appui pendant l'attente) ; un serveur injoignable donne « Le serveur ne répond pas. Réessaie. », sans erreur.
- **Simulation** : le banc de tests charge maintenant aussi `src/server/`. Le scénario démarre le serveur avant le client et joue toute la commande à travers la RemoteFunction ; le faux Roblox copie tout ce qui passe le réseau et refuse ce que Roblox refuserait. Limite : dans la simulation, serveur et client partagent les mêmes modules (un seul espace de noms ; `build.py` refuse deux modules de même nom).
- **Vérifié dans Studio pendant la préparation** : commande complète à travers le vrai réseau (découpe, coutures notées 85 % par le serveur, refus avec le score actuel, abandon), tentatives de triche depuis la barre de commande du client (action inconnue, action dans le désordre, rafale : 3 refus sur 8, Instance, table mixte, texte ou NaN à la place des décorations : refus propres), aucune erreur ni alerte côté serveur ou client.

## Global Constraints

- **Dépôt** : `C:\dev\jeux\atelier-couture`, branche `serveur-commande`, créée depuis `main` (où les plans 1 à 3d et le correctif du choix du tissu sont fusionnés). Ne rien pousser sur GitHub sans demande.
- **Rojo** : `C:/dev/jeux/roblox-maker/rojo.exe`.
- **Contraintes des plans précédents toujours valables** : unité le dm, repère du corps, fins de ligne LF, commits en français terminés par `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`, textes d'au moins 14 px à l'échelle 1, symboles vérifiés à l'écran, double clic protégé (`UiKit.bouton`), « Recommencer » à confirmer.
- **Échanges** (spec §6) : une seule `RemoteFunction` nommée `Atelier` ; chaque réponse est de la forme `{ ok = bool, erreur = string?, … }` ; au plus 5 appels par seconde et par joueur, sauf `rendreCouture`.
- **Le serveur fait foi** (spec §1, §2) : argent, stock, commande et étape vivent sur le serveur ; le client n'envoie jamais de note ni d'argent, seulement des actions et leurs arguments, tous vérifiés par `EtatAtelier`.

## Review Focus

- **Arguments farfelus venus du réseau** (une Instance, une table mixte, un texte à la place d'un nombre, NaN, une pièce qui n'existe pas). Attendu : un refus propre, jamais d'erreur côté serveur. Test : `28_commande_serveur`, « décorations farfelues refusées proprement » et les refus d'achat et de découpe.
- **Double appui pendant la réponse du serveur.** Attendu : une seule action envoyée, et « Un instant… » pour le second appui. Test : `29_session_distante`, « le second appui attend ».
- **Serveur injoignable, ou erreur dans une action.** Attendu : un message, aucune erreur, et la session repart ensuite. Tests : `29`, « serveur injoignable », et `28`, « erreur imprévue ».
- **Rafales d'appels.** Attendu : « Doucement ! » au-delà de 5 par seconde, pour ce joueur seulement ; les relevés de couture non limités. Tests : `28`, « rafale », et scénario, « triche : rafale d'appels ».
- **Copie du client modifiée à la main** (argent gonflé, par exemple). Attendu : le serveur décide seul, et `actualiser` rend la vraie copie. Tests : `29`, « argent modifié chez le client », et scénario, « triche : l'argent de la copie du client ne compte pas ».

---

### Task 1: L'état de l'atelier en données simples

**Files:**
- Modify: `src/shared/EtatAtelier.luau` (en-tête ; aides après `fini` ; `exporter` et `charger` à la fin)
- Test: `tests/unitaires/27_etat_exporter.luau`

**Interfaces:**
- Consumes: `EtatAtelier` (plans 3a à 3c), `Coupon.nouveau(longueur)`, `Coupon:poser(idPiece, placement)`, `Coupon:verifier`, `Coupon:longueurUtilisee()` (plan 1).
- Produces:
  - `EtatAtelier:exporter() -> table` : `{ argent, stock, etape, commande, croquis, tissus, coupees, epinglees, coutures, accessoires, robes, coupons = { [idTissu] = { longueur, poses } } }`, sans métatable ni table partagée avec l'état, transmissible par le réseau.
  - `EtatAtelier:charger(d) -> self` : remplace l'état sur place ; ce qui n'a pas changé garde sa table ; les rouleaux sont reconstruits en objets `Coupon`.

- [ ] **Step 1: Écrire le test**

`tests/unitaires/27_etat_exporter.luau` :

```lua
local EtatAtelier = U.module("EtatAtelier")
local Patron = U.module("Patron")
local Recette = U.module("Recette")

local CROQUIS = { corsage = "corsage_droit", manches = "manches_sans", col = "col_sans", jupe = "jupe_droite" }
local PLACES = {
	corsage_droit_devant = { x = 2.4, y = 2.1, angle = 0 },
	corsage_droit_dos = { x = 7.2, y = 2.1, angle = 0 },
	jupe_droite_devant = { x = 2.5, y = 7.2, angle = 0 },
	jupe_droite_dos = { x = 7.5, y = 7.2, angle = 0 },
}
local ORDRE = { "corsage_droit_devant", "corsage_droit_dos", "jupe_droite_devant", "jupe_droite_dos" }
-- Copie « réseau » d'un état exporté, rechargée dans un état neuf
local function recopie(etat)
	return EtatAtelier.nouveau():charger(M.transmettre(etat:exporter()))
end

---------------------------------------------------------------------------
-- Pendant la découpe : rouleaux, pièces coupées, stock
---------------------------------------------------------------------------
local etat = EtatAtelier.nouveau(1000)
etat:nouvelleCommande(Random.new(3))
local tissus = {}
for id in pairs(PLACES) do
	tissus[id] = "coton_blanc"
end
etat:validerCroquis(CROQUIS, tissus)
etat:acheter("coton_blanc", 12)
etat:commencerDecoupe()
etat:couper(ORDRE[1], PLACES[ORDRE[1]])
etat:couper(ORDRE[2], PLACES[ORDRE[2]])

local ok, erreur = pcall(M.transmettre, etat:exporter())
U.verifier(ok, "l'état exporté passe par le réseau (" .. tostring(erreur) .. ")")
local copie = recopie(etat)
U.verifier(getmetatable(copie) == EtatAtelier, "la copie est un état de l'atelier (ses méthodes marchent)")
U.verifier(copie.argent == etat.argent and copie.stock.coton_blanc == 12 and copie.etape == "decoupe", "argent, stock et étape")
U.verifier(copie.commande.taille == etat.commande.taille and #copie.commande.exigences == #etat.commande.exigences, "commande")
U.verifier(#copie:piecesAPoser() == 2 and copie.coupees[ORDRE[1]].x == PLACES[ORDRE[1]].x, "pièces déjà coupées")
local rouleau = copie.coupons.coton_blanc
U.verifier(rouleau ~= nil and rouleau.longueur == etat.coupons.coton_blanc.longueur and rouleau.poses[ORDRE[2]] ~= nil, "rouleau : longueur et pièces posées")
local posee, pourquoi = rouleau:verifier(ORDRE[3], { x = 2.5, y = 6.0, angle = 0 }) -- recouvre le corsage devant
U.verifier(not posee and pourquoi == "La pièce chevauche une autre pièce.", "le rouleau rechargé connaît la place occupée")
U.verifier(rouleau:longueurUtilisee() == etat.coupons.coton_blanc:longueurUtilisee(), "longueur entamée identique")
-- La copie continue la commande exactement comme l'original
local r1, r2 = etat:couper(ORDRE[3], PLACES[ORDRE[3]]), copie:couper(ORDRE[3], PLACES[ORDRE[3]])
U.verifier(r1.ok and r2.ok and r1.reste == r2.reste, "la découpe continue à l'identique")

-- L'export ne partage rien avec l'état
local export = etat:exporter()
export.stock.coton_blanc = 0
export.commande.exigences = {}
export.coupons.coton_blanc.poses = {}
U.verifier(etat.stock.coton_blanc == 12 and #etat.commande.exigences > 0 and etat.coupons.coton_blanc.poses[ORDRE[1]] ~= nil, "modifier l'export ne touche pas l'état")

---------------------------------------------------------------------------
-- Robe finie, décorée, puis livrée : recette et robes gardées
---------------------------------------------------------------------------
etat:couper(ORDRE[4], PLACES[ORDRE[4]])
for _, id in ipairs(ORDRE) do
	etat:epingler(id)
end
for _, id in ipairs(ORDRE) do
	local _, longueur = Patron.trajetCouture(id)
	etat:rendreCouture(id, table.create(math.round(longueur / 0.1), 0.02), longueur)
end
etat:decorer({ { id = "noeud_satin", piece = 1, copie = "unique", u = 0.4, v = 0.3, echelle = 1, angle = 15 } })
U.verifier(etat.etape == "photo", "robe décorée (mise en place du test)")
local photo = recopie(etat)
U.verifier(Recette.encoder(photo:recette()) == Recette.encoder(etat:recette()), "même recette : pièces, coutures, décorations")
etat.commande.exigences = { { type = "qualite", valeur = 0.1 } }
U.verifier(etat:livrer().reussie, "robe livrée (mise en place du test)")
local apres = recopie(etat)
U.verifier(apres.etape == "accueil" and apres.commande == nil and apres.croquis == nil, "commande terminée")
U.verifier(#apres.robes == 1 and Recette.encoder(apres.robes[1]) == Recette.encoder(etat.robes[1]), "robe livrée gardée")

---------------------------------------------------------------------------
-- Rechargement sur place : les écrans gardent l'objet ; ce qui n'a pas changé garde sa table
---------------------------------------------------------------------------
local client = EtatAtelier.nouveau()
local serveur = EtatAtelier.nouveau(500)
serveur:nouvelleCommande(Random.new(8))
client:charger(serveur:exporter())
local objet, commande = client, client.commande
serveur:validerCroquis(CROQUIS, tissus)
serveur:acheter("coton_blanc", 10)
U.verifier(client:charger(serveur:exporter()) == objet, "charger renvoie le même objet")
U.verifier(client.commande == commande, "même commande : même table (la scène garde sa cliente)")
U.verifier(client.etape == "achat" and client.argent == serveur.argent and client.stock.coton_blanc == 10, "le reste est à jour")
serveur.etape = "refus"
serveur:abandonner()
serveur:nouvelleCommande(Random.new(9))
client:charger(serveur:exporter())
U.verifier(client.commande ~= commande and client.commande.taille == serveur.commande.taille, "nouvelle commande : nouvelle table")
client.commande.taille = "XXL"
U.verifier(serveur.commande.taille ~= "XXL", "l'état chargé ne partage rien avec la source")
```

- [ ] **Step 2: Lancer les tests, vérifier l'échec**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT|attempt|membre" | head -3`
Expected: échec : une ligne qui finit par `attempt to call missing method 'exporter' of table`

- [ ] **Step 3: Exporter et recharger l'état**

Dans `src/shared/EtatAtelier.luau` :

1. Remplacer les trois premières lignes de commentaire (`-- EtatAtelier : état d'un joueur…` jusqu'à `…où elle fait foi.`) par :

```lua
-- EtatAtelier : état d'un joueur à l'atelier et étapes de la commande en cours.
-- Logique pure, sans instance Roblox. Le serveur la tient pour chaque joueur et elle y fait foi ;
-- le client en garde une copie, rechargée après chaque action (exporter / charger).
```

2. Juste après la fonction `local function fini(n) … end`, ajouter :

```lua
-- Copie profonde de données simples (tables, nombres, textes, booléens)
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

-- Égalité profonde de données simples
local function pareil(a, b)
	if type(a) ~= "table" or type(b) ~= "table" then
		return a == b
	end
	for k, x in pairs(a) do
		if not pareil(x, b[k]) then
			return false
		end
	end
	for k in pairs(b) do
		if a[k] == nil then
			return false
		end
	end
	return true
end

-- Champs de l'état échangés avec le serveur (les rouleaux à part : ce sont des objets Coupon)
local CHAMPS = { "argent", "stock", "etape", "commande", "croquis", "tissus", "coupees", "epinglees", "coutures", "accessoires", "robes" }
```

3. Juste avant la dernière ligne, `return EtatAtelier`, ajouter :

```lua
local function rouleauxExportes(coupons)
	local out = {}
	for idTissu, coupon in pairs(coupons) do
		out[idTissu] = { longueur = coupon.longueur, poses = copie(coupon.poses) }
	end
	return out
end

-- L'état en données simples, sans métatable : ce que le serveur envoie au client après chaque action.
-- Les rouleaux deviennent { longueur, poses }.
function EtatAtelier:exporter()
	local d = {}
	for _, cle in ipairs(CHAMPS) do
		d[cle] = copie(self[cle])
	end
	d.coupons = rouleauxExportes(self.coupons)
	return d
end

-- Remplace l'état par un état exporté, sur place : les écrans gardent le même objet. Ce qui n'a pas
-- changé garde sa table (la scène reconnaît ainsi la même commande d'une action à l'autre).
function EtatAtelier:charger(d)
	for _, cle in ipairs(CHAMPS) do
		if not pareil(self[cle], d[cle]) then
			self[cle] = copie(d[cle])
		end
	end
	if not pareil(rouleauxExportes(self.coupons), d.coupons) then
		self.coupons = {}
		for idTissu, r in pairs(d.coupons) do
			local coupon = Coupon.nouveau(r.longueur)
			for idPiece, pose in pairs(r.poses) do
				coupon:poser(idPiece, pose)
			end
			self.coupons[idTissu] = coupon
		end
	end
	return self
end
```

- [ ] **Step 4: Lancer les tests**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT"`
Expected:
```
Unitaires : 104720 vérifications
TOUT EST VERT : 295 vérifications
```

- [ ] **Step 5: Commit**

```bash
git add src/shared/EtatAtelier.luau tests/unitaires/27_etat_exporter.luau
git commit -m "L'état de l'atelier s'exporte en données simples et se recharge sur place

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 2: Le serveur de l'atelier

**Files:**
- Modify: `tests/build.py` (modules et script du serveur dans la simulation)
- Modify: `default.project.json` (ServerScriptService)
- Create: `src/server/Limiteur.luau`, `src/server/Commande.luau`, `src/server/init.server.luau`
- Test: `tests/unitaires/28_commande_serveur.luau`

**Interfaces:**
- Consumes: `EtatAtelier.nouveau()`, ses actions, `EtatAtelier:exporter()` (tâche 1) ; `EtatAtelier.ARGENT_DEPART`.
- Produces:
  - `Limiteur.nouveau(max, fenetre)`, `Limiteur:autoriser(cle) -> boolean`, `Limiteur:oublier(cle)`.
  - `Commande.nouvelle()` (et `Commande.courante`), `Commande.APPELS_PAR_SECONDE = 5`, `Commande:atelier(joueur) -> { etat, rng }`, `Commande:retirer(joueur)`, `Commande.instantane(etat)`, `Commande:traiter(joueur, action, ...) -> { ok, erreur?, etat?, … }` ; champ `ateliers[joueur]`.
  - RemoteFunction `ReplicatedStorage.Atelier`, créée par le Script `ServerScriptService.Atelier` ; `OnServerInvoke = function(joueur, action, ...)`.
  - Simulation : `NOMS_SERVEUR` et `SCRIPTS.Serveur` (dans `tests/build.py`).

- [ ] **Step 1: Charger le serveur dans la simulation et dans Rojo**

Dans `tests/build.py`, remplacer

```python
# Modules partagés et modules du client (sauf le script de démarrage) : chargés automatiquement
modules = sorted(glob.glob(SRC + "/shared/*.luau")) + sorted(
    c for c in glob.glob(SRC + "/client/Atelier/*.luau") if not os.path.basename(c).startswith("init."))
```

par :

```python
# Modules partagés, du client et du serveur (sauf les scripts de démarrage) : chargés automatiquement
def sansDemarrage(dossier):
    return sorted(c for c in glob.glob(SRC + dossier + "/*.luau") if not os.path.basename(c).startswith("init."))
modules = sorted(glob.glob(SRC + "/shared/*.luau")) + sansDemarrage("/client/Atelier") + sansDemarrage("/server")
# Un seul espace de noms dans la simulation : deux modules ne peuvent pas porter le même nom
doublons = sorted({nom(c) for c in modules if [nom(m) for m in modules].count(nom(c)) > 1})
assert not doublons, "modules de même nom : " + ", ".join(doublons)
```

Juste après la ligne `out.append("local NOMS_CLIENT = { " + …)`, ajouter :

```python
out.append("local NOMS_SERVEUR = { " + ", ".join(f"\"{nom(c)}\"" for c in modules if "/server/" in c.replace("\\", "/")) + " }")
```

Et remplacer `for nomScript, chemin in [("Atelier", "client/Atelier/init.client.luau")]:` par :

```python
for nomScript, chemin in [("Atelier", "client/Atelier/init.client.luau"), ("Serveur", "server/init.server.luau")]:
```

Dans `default.project.json`, juste avant `"StarterPlayer": {`, ajouter :

```json
    "ServerScriptService": {
      "Atelier": {
        "$path": "src/server"
      }
    },
```

- [ ] **Step 2: Écrire le test du serveur**

`tests/unitaires/28_commande_serveur.luau` :

```lua
local Commande = U.module("Commande")
local EtatAtelier = U.module("EtatAtelier")
local Patron = U.module("Patron")

local serveur = Commande.nouvelle()
U.verifier(Commande.courante == serveur, "le serveur en cours est connu (scénario, débogage)")
local joueur = M.nouveauJoueur("Couturiere")
-- Un appel du client, espacé comme un joueur (sous la limite de 5 par seconde) ; chaque réponse doit
-- pouvoir passer par le réseau
local function appeler(qui, action, ...)
	M.avancer(0.25)
	local reponse = serveur:traiter(qui, action, ...)
	local ok, erreur = pcall(M.transmettre, reponse)
	U.verifier(ok, "réponse à « " .. tostring(action) .. " » transmissible (" .. tostring(erreur) .. ")")
	return reponse
end
local function etatDe(qui)
	return serveur:atelier(qui).etat
end

---------------------------------------------------------------------------
-- Arrivée : l'état de départ, envoyé au client
---------------------------------------------------------------------------
local r = appeler(joueur, "etat")
U.verifier(r.ok and r.etat.etape == "accueil" and r.etat.argent == EtatAtelier.ARGENT_DEPART, "le client reçoit l'état de départ")

---------------------------------------------------------------------------
-- Actions inconnues, dans le désordre, ou aux arguments farfelus : refusées, sans rien changer
---------------------------------------------------------------------------
for _, action in ipairs({ "voler", "nouveau", "charger", "exporter", "__index", 42, true }) do
	r = appeler(joueur, action)
	U.verifier(not r.ok and r.erreur == "Action inconnue." and r.etat == nil, "action inconnue refusée : " .. tostring(action))
end
r = appeler(joueur)
U.verifier(not r.ok and r.erreur == "Action inconnue.", "appel sans action refusé")
r = appeler(joueur, "livrer")
U.verifier(not r.ok and r.erreur == "Ce n'est pas le moment de livrer." and r.etat == nil, "livrer sans commande : refusé")
U.verifier(etatDe(joueur).argent == EtatAtelier.ARGENT_DEPART and etatDe(joueur).etape == "accueil", "rien n'a changé")

---------------------------------------------------------------------------
-- Une commande menée par le serveur ; chaque réponse emporte l'état
---------------------------------------------------------------------------
r = appeler(joueur, "nouvelleCommande", { NextInteger = "tricherie" })
U.verifier(r.ok and r.etat.etape == "carnet" and r.etat.commande ~= nil, "nouvelle commande tirée par le serveur (l'argument du client est ignoré)")
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
U.verifier(appeler(joueur, "validerCroquis", CROQUIS, tissus).ok, "croquis validé")
-- Achats refusés : longueur farfelue, argent insuffisant
for _, dm in ipairs({ 0, -5, 2.5, 1e9, "10" }) do
	r = appeler(joueur, "acheter", "coton_blanc", dm)
	U.verifier(not r.ok and r.erreur == "Longueur invalide.", "achat refusé : " .. tostring(dm) .. " dm")
end
etatDe(joueur).argent = 5
r = appeler(joueur, "acheter", "soie_rouge", 100)
U.verifier(not r.ok and r.erreur == "Pas assez d'argent." and etatDe(joueur).argent == 5, "achat trop cher refusé")
etatDe(joueur).argent = 1000
r = appeler(joueur, "acheter", "coton_blanc", 12)
U.verifier(r.ok and r.etat.stock.coton_blanc == 12 and r.etat.argent == 1000 - r.prix, "achat : stock et argent dans l'état renvoyé")
U.verifier(appeler(joueur, "commencerDecoupe").ok, "découpe commencée")
-- Découpe : hors du rouleau, position farfelue, pièce hors du croquis, pièce coupée deux fois
r = appeler(joueur, "couper", ORDRE[1], { x = -3, y = 2, angle = 0 })
U.verifier(not r.ok and r.erreur == "La pièce dépasse du tissu.", "découpe hors du rouleau refusée")
r = appeler(joueur, "couper", ORDRE[1], { x = "2", y = 2, angle = 0 })
U.verifier(not r.ok and r.erreur == "Position invalide.", "position farfelue refusée")
r = appeler(joueur, "couper", "manche_longue", PLACES[ORDRE[1]])
U.verifier(not r.ok and r.erreur == "Cette pièce n'est pas dans le croquis.", "pièce hors du croquis refusée")
U.verifier(appeler(joueur, "couper", ORDRE[1], PLACES[ORDRE[1]]).ok, "première pièce coupée")
r = appeler(joueur, "couper", ORDRE[1], PLACES[ORDRE[3]])
U.verifier(not r.ok and r.erreur == "Cette pièce est déjà coupée.", "pièce coupée deux fois refusée")
r = appeler(joueur, "couper", ORDRE[2], PLACES[ORDRE[1]])
U.verifier(not r.ok and r.erreur == "La pièce chevauche une autre pièce.", "découpe superposée refusée")
for k = 2, 4 do
	r = appeler(joueur, "couper", ORDRE[k], PLACES[ORDRE[k]])
end
U.verifier(r.ok and r.etat.etape == "epinglage", "toutes les pièces coupées : épinglage")
for _, id in ipairs(ORDRE) do
	r = appeler(joueur, "epingler", id)
end
U.verifier(r.ok and r.etat.etape == "couture", "pièces épinglées : couture")
-- Couture : trop rapide, mauvais nombre de mesures ; pas de limite d'appels (sa propre vraisemblance)
local _, longueur = Patron.trajetCouture(ORDRE[1])
local releve = table.create(math.round(longueur / 0.1), 0.02)
r = appeler(joueur, "rendreCouture", ORDRE[1], releve, 0.01)
U.verifier(not r.ok and r.erreur == "Couture trop rapide.", "couture trop rapide refusée")
r = appeler(joueur, "rendreCouture", ORDRE[1], table.create(#releve + 5, 0), longueur)
U.verifier(not r.ok and r.erreur == "Relevé de couture incomplet.", "mauvais nombre de mesures refusé")
local limitees = 0
for _ = 1, 10 do
	r = serveur:traiter(joueur, "rendreCouture", ORDRE[1], releve, 0.01) -- dix appels au même instant
	if r.erreur == "Doucement !" then
		limitees += 1
	end
end
U.verifier(limitees == 0, "« rendreCouture » n'est pas soumise à la limite d'appels")
for _, id in ipairs(ORDRE) do
	local _, l = Patron.trajetCouture(id)
	r = appeler(joueur, "rendreCouture", id, table.create(math.round(l / 0.1), 0.02), l)
end
U.verifier(r.ok and r.etat.etape == "decorations", "robe cousue : décorations")
-- Arguments farfelus (une Instance, une table mixte, un texte, NaN…) : refusés proprement, jamais d'erreur.
-- Le message n'est vérifié que lorsqu'il ne dépend pas de la conversion faite par le réseau de Roblox
-- (le faux Roblox passe une Instance ou une table mixte telle quelle ; Roblox les convertit).
local FARFELUS = {
	{ M.services.Workspace },
	{ { 1, 2, x = 3 } },
	{ "tout", "Décorations invalides." },
	{ { { id = "bouton_nacre", piece = 1, copie = "unique", u = 0 / 0, v = 0.5, echelle = 1, angle = 0 } }, "Accessoire mal placé." },
	{ { { id = "bouton_nacre", piece = 99, copie = "unique", u = 0.5, v = 0.5, echelle = 1, angle = 0 } }, "Accessoire sur une pièce inexistante." },
}
for k, cas in ipairs(FARFELUS) do
	M.avancer(0.25)
	r = serveur:traiter(joueur, "decorer", cas[1])
	U.verifier(not r.ok and r.erreur ~= "Action impossible." and (cas[2] == nil or r.erreur == cas[2]), "décorations farfelues refusées proprement (" .. k .. ") : " .. tostring(r.erreur))
end
-- 301 décorations : refusées, rien n'est facturé
local trop = {}
for k = 1, 301 do
	trop[k] = { id = "bouton_nacre", piece = 1, copie = "unique", u = 0.5, v = 0.5, echelle = 1, angle = 0 }
end
local argentAvant = etatDe(joueur).argent
r = appeler(joueur, "decorer", trop)
U.verifier(not r.ok and etatDe(joueur).argent == argentAvant and etatDe(joueur).etape == "decorations", "301 décorations refusées, rien facturé")
U.verifier(appeler(joueur, "decorer", {}).ok, "robe présentée")
etatDe(joueur).commande.exigences = { { type = "qualite", valeur = 0.1 } }
r = appeler(joueur, "livrer")
U.verifier(r.ok and r.reussie and r.paie > 0 and r.etat.etape == "accueil" and #r.etat.robes == 1, "robe livrée et payée")

-- L'état envoyé ne garde que la robe en vitrine (le serveur garde les dix dernières)
table.insert(etatDe(joueur).robes, 1, table.clone(etatDe(joueur).robes[1]))
r = appeler(joueur, "etat")
U.verifier(#etatDe(joueur).robes == 2 and #r.etat.robes == 1, "seule la robe en vitrine part chez le client")

---------------------------------------------------------------------------
-- Rafale : au plus 5 appels par seconde et par joueur
---------------------------------------------------------------------------
M.avancer(2)
local acceptes = 0
for _ = 1, 8 do
	r = serveur:traiter(joueur, "etat")
	if r.ok then
		acceptes += 1
	else
		U.verifier(r.erreur == "Doucement !", "rafale : message « Doucement ! »")
	end
end
U.verifier(acceptes == Commande.APPELS_PAR_SECONDE, "rafale : " .. acceptes .. " appels acceptés sur 8 au même instant")
local autre = M.nouveauJoueur("Voisine")
U.verifier(serveur:traiter(autre, "etat").ok, "la rafale d'un joueur ne gêne pas les autres")
M.avancer(1.01)
U.verifier(serveur:traiter(joueur, "etat").ok, "une seconde plus tard, c'est de nouveau permis")

---------------------------------------------------------------------------
-- Erreur imprévue dans une action : refus propre, avertissement, le serveur continue
---------------------------------------------------------------------------
local vraie = EtatAtelier.nouvelleCommande
EtatAtelier.nouvelleCommande = function()
	error("panne simulée")
end
M.avertissements = {}
r = appeler(joueur, "nouvelleCommande")
EtatAtelier.nouvelleCommande = vraie
U.verifier(not r.ok and r.erreur == "Action impossible." and #M.avertissements == 1, "erreur imprévue : refus propre et un avertissement")
U.verifier(appeler(joueur, "nouvelleCommande").ok, "le serveur continue après l'erreur")

---------------------------------------------------------------------------
-- Départ du joueur : son atelier est libéré
---------------------------------------------------------------------------
serveur:retirer(joueur)
U.verifier(serveur.ateliers[joueur] == nil, "atelier libéré au départ")
r = appeler(joueur, "etat")
U.verifier(r.ok and r.etat.etape == "accueil" and r.etat.argent == EtatAtelier.ARGENT_DEPART, "un joueur qui revient repart de zéro (la sauvegarde arrive au plan 4b)")
```

- [ ] **Step 3: Lancer les tests, vérifier l'échec**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT|attempt|membre" | head -3`
Expected: échec : une ligne qui finit par `Commande n'est pas un membre valide de Folder « Couture »` (le module n'existe pas encore)

- [ ] **Step 4: Écrire le serveur**

`src/server/Limiteur.luau` :

```lua
-- Limiteur : au plus « max » appels par fenêtre glissante de « fenetre » secondes, pour chaque clé
-- (un joueur). Protège le serveur des rafales d'appels (spec §6).
local Limiteur = {}
Limiteur.__index = Limiteur

function Limiteur.nouveau(max, fenetre)
	return setmetatable({ max = max, fenetre = fenetre, appels = {} }, Limiteur)
end

-- Vrai si l'appel est permis (il est alors compté), faux s'il y en a déjà trop dans la fenêtre
function Limiteur:autoriser(cle)
	local maintenant = os.clock()
	local recents = {}
	for _, t in ipairs(self.appels[cle] or {}) do
		if maintenant - t < self.fenetre then
			table.insert(recents, t)
		end
	end
	local permis = #recents < self.max
	if permis then
		table.insert(recents, maintenant)
	end
	self.appels[cle] = recents
	return permis
end

function Limiteur:oublier(cle)
	self.appels[cle] = nil
end

return Limiteur
```

`src/server/Commande.luau` :

```lua
-- Commande (serveur) : l'atelier de chaque joueur, qui fait foi (spec §2). Chaque action du client
-- passe par Commande:traiter : action connue, limite d'appels, règles d'EtatAtelier. Une réponse
-- acceptée emporte l'état (EtatAtelier:exporter), que le client recharge et affiche.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Couture = ReplicatedStorage:WaitForChild("Couture")
local EtatAtelier = require(Couture:WaitForChild("EtatAtelier"))
local Limiteur = require(script.Parent:WaitForChild("Limiteur"))

local Commande = {}
Commande.__index = Commande

Commande.APPELS_PAR_SECONDE = 5 -- par joueur (spec §6)
-- Les relevés de couture ne sont pas limités : leur propre vraisemblance les borne (spec §6)
local SANS_LIMITE = { rendreCouture = true }

local function refus(message)
	return { ok = false, erreur = message }
end

-- Actions permises : le nom envoyé par le client choisit l'une d'elles, jamais une méthode quelconque
local ACTIONS = {
	-- le client demande l'état (à son arrivée)
	etat = function()
		return { ok = true }
	end,
	-- la commande est tirée par le serveur, avec son propre générateur (l'argument du client est ignoré)
	nouvelleCommande = function(a)
		return a.etat:nouvelleCommande(a.rng)
	end,
	validerCroquis = function(a, croquis, tissus)
		return a.etat:validerCroquis(croquis, tissus)
	end,
	retourCarnet = function(a)
		return a.etat:retourCarnet()
	end,
	acheter = function(a, idTissu, dm)
		return a.etat:acheter(idTissu, dm)
	end,
	commencerDecoupe = function(a)
		return a.etat:commencerDecoupe()
	end,
	couper = function(a, idPiece, placement)
		return a.etat:couper(idPiece, placement)
	end,
	epingler = function(a, idPiece)
		return a.etat:epingler(idPiece)
	end,
	rendreCouture = function(a, idPiece, ecarts, duree, assistance)
		return a.etat:rendreCouture(idPiece, ecarts, duree, assistance)
	end,
	decorer = function(a, liste)
		return a.etat:decorer(liste)
	end,
	retourDecorations = function(a)
		return a.etat:retourDecorations()
	end,
	livrer = function(a)
		return a.etat:livrer()
	end,
	retoucher = function(a)
		return a.etat:retoucher()
	end,
	abandonner = function(a)
		return a.etat:abandonner()
	end,
	recommencer = function(a)
		return a.etat:recommencer()
	end,
}

function Commande.nouvelle()
	local self = setmetatable({
		ateliers = {}, -- [joueur] = { etat = EtatAtelier, rng = Random }
		limiteur = Limiteur.nouveau(Commande.APPELS_PAR_SECONDE, 1),
	}, Commande)
	Commande.courante = self -- le serveur en cours (tests du scénario, débogage dans Studio)
	return self
end

-- L'atelier d'un joueur, créé à son premier appel (la sauvegarde le chargera au plan 4b)
function Commande:atelier(joueur)
	local a = self.ateliers[joueur]
	if not a then
		a = { etat = EtatAtelier.nouveau(), rng = Random.new() }
		self.ateliers[joueur] = a
	end
	return a
end

-- Départ du joueur : son atelier est libéré
function Commande:retirer(joueur)
	self.ateliers[joueur] = nil
	self.limiteur:oublier(joueur)
end

-- L'état envoyé au client : tout, sauf les anciennes robes (seule la plus récente est en vitrine)
function Commande.instantane(etat)
	local d = etat:exporter()
	d.robes = { d.robes[1] }
	return d
end

-- Une action d'un joueur. Ne lève jamais d'erreur : une erreur imprévue devient un refus.
function Commande:traiter(joueur, action, ...)
	local faire = type(action) == "string" and ACTIONS[action]
	if not faire then
		return refus("Action inconnue.")
	end
	if not SANS_LIMITE[action] and not self.limiteur:autoriser(joueur) then
		return refus("Doucement !")
	end
	local a = self:atelier(joueur)
	local ok, reponse = pcall(faire, a, ...)
	if not ok then
		warn(("[Atelier] %s : erreur dans « %s » : %s"):format(joueur.Name, action, tostring(reponse)))
		return refus("Action impossible.")
	end
	if reponse.ok then
		reponse.etat = Commande.instantane(a.etat)
	end
	return reponse
end

return Commande
```

`src/server/init.server.luau` :

```lua
-- Serveur de l'atelier : il fait foi (spec §2). Une seule RemoteFunction « Atelier », une action par
-- étape (Commande). La sauvegarde arrive au plan 4b, les boutiques de la rue au plan 4c.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Commande = require(script:WaitForChild("Commande"))

local commande = Commande.nouvelle()

local remote = Instance.new("RemoteFunction")
remote.Name = "Atelier"
remote.OnServerInvoke = function(joueur, action, ...)
	return commande:traiter(joueur, action, ...)
end
remote.Parent = ReplicatedStorage

Players.PlayerRemoving:Connect(function(joueur)
	commande:retirer(joueur)
end)
```

- [ ] **Step 5: Lancer les tests**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT"`
Expected:
```
Unitaires : 104819 vérifications
TOUT EST VERT : 295 vérifications
```

- [ ] **Step 6: Commit**

```bash
git add tests/build.py default.project.json src/server tests/unitaires/28_commande_serveur.luau
git commit -m "Le serveur de l'atelier : une action permise à la fois, limite d'appels, l'état dans chaque réponse

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 3: Le client passe par le serveur

**Files:**
- Modify: `src/client/Atelier/Session.luau` (réécrit : session locale gardée, session distante ajoutée)
- Modify: `src/client/Atelier/init.client.luau:3` et `:39`
- Test: `tests/unitaires/29_session_distante.luau`, `tests/scenario.luau` (démarrage du serveur, exigences posées sur le serveur, triche)

**Interfaces:**
- Consumes: `EtatAtelier:charger(d)` (tâche 1) ; `Commande.nouvelle()`, `Commande:traiter`, `Commande:atelier`, `Commande.courante`, `Commande.APPELS_PAR_SECONDE`, RemoteFunction `ReplicatedStorage.Atelier`, `NOMS_SERVEUR`, `SCRIPTS.Serveur` (tâche 2).
- Produces:
  - `Session.distante(remote) -> Session` (attend l'état du serveur ; `session.rng` local) ; `Session:actualiser() -> reponse`. Les méthodes d'action gardent leurs noms et leurs réponses ; en plus : `{ ok = false, erreur = "Un instant…" }` pendant une autre action, `{ ok = false, erreur = "Le serveur ne répond pas. Réessaie." }` si l'appel échoue.
  - `Session.nouvelle(graine)` inchangée (session locale des tests des écrans).

- [ ] **Step 1: Écrire le test de la session distante**

`tests/unitaires/29_session_distante.luau` :

```lua
local Session = U.module("Session")
local Commande = U.module("Commande")
local EtatAtelier = U.module("EtatAtelier")

-- Un serveur et sa RemoteFunction, comme dans le jeu (le faux Roblox copie tout ce qui passe le réseau)
local serveur = Commande.nouvelle()
local remote = M.nouvelleInstance("RemoteFunction")
remote.Name = "Atelier"
local function brancher()
	remote.OnServerInvoke = function(joueur, action, ...)
		return serveur:traiter(joueur, action, ...)
	end
end
brancher()
local joueur = M.nouveauJoueur("Distante")
M.joueurLocal = joueur
local function cote()
	return serveur:atelier(joueur).etat
end

---------------------------------------------------------------------------
-- Arrivée : la session demande l'état au serveur
---------------------------------------------------------------------------
cote().argent = 321 -- (au plan 4b, l'argent viendra de la sauvegarde)
M.avancer(1)
local session = Session.distante(remote)
U.verifier(Session.courante == session, "la session du joueur est connue")
U.verifier(session.etat.argent == 321 and session.etat.etape == "accueil", "l'état vient du serveur dès l'arrivée")
U.verifier(typeof(session.rng) == "Random", "hasard local gardé pour la machine à coudre (le serveur ne s'en sert pas)")

---------------------------------------------------------------------------
-- Une action : le serveur décide, le client recharge l'état sur place
---------------------------------------------------------------------------
local notifications = 0
session:surChangement(function()
	notifications += 1
end)
local objet = session.etat
M.avancer(1)
local r = session:nouvelleCommande()
U.verifier(r.ok and notifications == 1, "nouvelle commande acceptée, l'interface prévenue une fois")
U.verifier(session.etat == objet and session.etat.etape == "carnet", "même objet d'état (les écrans le gardent), à jour")
U.verifier(session.etat.commande ~= nil and session.etat.commande.taille == cote().commande.taille, "la commande est celle du serveur")
U.verifier(session.derniere.action == "nouvelleCommande" and session.derniere.reponse.ok, "dernière action retenue (accueil, cliente)")
local commande = session.etat.commande
M.avancer(1)
session:validerCroquis({ corsage = "corsage_droit", manches = "manches_sans", col = "col_sans", jupe = "jupe_droite" }, {
	corsage_droit_devant = "coton_blanc",
	corsage_droit_dos = "coton_blanc",
	jupe_droite_devant = "coton_blanc",
	jupe_droite_dos = "coton_blanc",
})
M.avancer(1)
r = session:acheter("coton_blanc", 10)
U.verifier(r.ok and session.etat.stock.coton_blanc == 10 and session.etat.argent == cote().argent, "achat : stock et argent du serveur")
U.verifier(session.etat.commande == commande, "la commande garde sa table d'une action à l'autre (la scène garde sa cliente)")

---------------------------------------------------------------------------
-- Refus du serveur : message, rien ne change, l'interface n'est pas prévenue
---------------------------------------------------------------------------
local avant = notifications
M.avancer(1)
r = session:acheter("coton_blanc", 0)
U.verifier(not r.ok and r.erreur == "Longueur invalide." and notifications == avant and session.etat.stock.coton_blanc == 10, "refus : message, état inchangé")

---------------------------------------------------------------------------
-- Le client ne peut rien s'accorder : l'état local n'est qu'une copie
---------------------------------------------------------------------------
cote().argent = 5
session.etat.argent = 99999
M.avancer(1)
r = session:acheter("soie_rouge", 100)
U.verifier(not r.ok and r.erreur == "Pas assez d'argent.", "argent modifié chez le client : le serveur refuse quand même")
cote().argent = 500
session:actualiser()
U.verifier(session.etat.argent == 500, "actualiser : l'état revient à celui du serveur")

---------------------------------------------------------------------------
-- Une action à la fois : un second appui pendant que le serveur répond est refusé
---------------------------------------------------------------------------
local appelsServeur, pendant = 0, nil
remote.OnServerInvoke = function(j, action, ...)
	appelsServeur += 1
	if appelsServeur == 1 then
		pendant = session:acheter("coton_blanc", 1) -- le joueur appuie encore pendant l'attente
	end
	return serveur:traiter(j, action, ...)
end
M.avancer(1)
r = session:acheter("coton_blanc", 2)
brancher()
U.verifier(r.ok and appelsServeur == 1, "le premier achat passe, un seul appel au serveur")
U.verifier(pendant ~= nil and not pendant.ok and pendant.erreur == "Un instant…", "le second appui attend : « Un instant… »")
U.verifier(session.etat.stock.coton_blanc == 12, "un seul achat compté")

---------------------------------------------------------------------------
-- Serveur injoignable : message, pas d'erreur ; la session repart ensuite
---------------------------------------------------------------------------
remote.OnServerInvoke = function()
	error("coupure simulée")
end
r = session:acheter("coton_blanc", 1)
U.verifier(not r.ok and r.erreur == "Le serveur ne répond pas. Réessaie.", "serveur injoignable : message")
brancher()
M.avancer(1)
U.verifier(session:acheter("coton_blanc", 1).ok, "la session repart quand le serveur répond")
local autre = Session.distante((function()
	local muet = M.nouvelleInstance("RemoteFunction")
	muet.OnServerInvoke = function()
		error("coupure simulée")
	end
	return muet
end)())
U.verifier(autre.etat.etape == "accueil" and autre.etat.argent == EtatAtelier.ARGENT_DEPART, "serveur injoignable à l'arrivée : état de départ, sans erreur")
Session.courante = session
```

- [ ] **Step 2: Lancer les tests, vérifier l'échec**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT|attempt" | head -3`
Expected: échec : une ligne qui finit par `attempt to call a nil value` (`Session.distante` n'existe pas encore)

- [ ] **Step 3: Réécrire la Session**

`src/client/Atelier/Session.luau` :

```lua
-- Session : accès de l'interface à l'état de l'atelier. Les écrans ne parlent qu'à la Session, jamais
-- à EtatAtelier directement.
-- Dans le jeu, la session est distante : chaque action passe par le serveur (RemoteFunction « Atelier »),
-- qui fait foi ; sa réponse emporte l'état, rechargé sur place. Une session locale (EtatAtelier dans le
-- client) sert aux tests des écrans.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Couture = ReplicatedStorage:WaitForChild("Couture")
local EtatAtelier = require(Couture:WaitForChild("EtatAtelier"))

local Session = {}
Session.__index = Session

local INJOIGNABLE = "Le serveur ne répond pas. Réessaie."

-- Session locale ; graine : pour des commandes reproductibles (tests) ; sinon aléatoire
function Session.nouvelle(graine)
	local self = setmetatable({ etat = EtatAtelier.nouveau(), rng = Random.new(graine), ecouteurs = {}, derniere = nil }, Session)
	Session.courante = self -- la session du joueur (tests du scénario, débogage dans Studio)
	return self
end

-- Session distante (le jeu) : remote = la RemoteFunction « Atelier » du serveur. Attend l'état du serveur.
-- rng ne sert qu'au client (mouvement du tissu à la machine à coudre) : le serveur tire ses commandes.
function Session.distante(remote)
	local self = setmetatable({ etat = EtatAtelier.nouveau(), remote = remote, rng = Random.new(), ecouteurs = {}, derniere = nil, enCours = false }, Session)
	Session.courante = self
	self:actualiser()
	return self
end

-- Appel au serveur, sans jamais lever d'erreur
local function appeler(self, nom, ...)
	local ok, reponse = pcall(self.remote.InvokeServer, self.remote, nom, ...)
	if not ok or type(reponse) ~= "table" then
		return { ok = false, erreur = INJOIGNABLE }
	end
	if reponse.ok and type(reponse.etat) == "table" then
		self.etat:charger(reponse.etat)
	end
	return reponse
end

-- Reprend l'état du serveur (à l'arrivée, ou pour réparer une copie abîmée)
function Session:actualiser()
	if self.remote then
		return appeler(self, "etat")
	end
	return { ok = true }
end

-- Appelle f(etat) après chaque action réussie ; renvoie une fonction pour se désabonner
function Session:surChangement(f)
	table.insert(self.ecouteurs, f)
	return function()
		local i = table.find(self.ecouteurs, f)
		if i then
			table.remove(self.ecouteurs, i)
		end
	end
end

-- derniere = { action, reponse } de la dernière action réussie (l'accueil affiche la dernière livraison)
local function agir(self, nom, ...)
	local reponse
	if self.remote then
		if self.enCours then
			return { ok = false, erreur = "Un instant…" } -- une action à la fois (second appui pendant l'attente)
		end
		self.enCours = true
		reponse = appeler(self, nom, ...)
		self.enCours = false
	else
		reponse = self.etat[nom](self.etat, ...)
	end
	if reponse.ok then
		self.derniere = { action = nom, reponse = reponse }
		for _, f in ipairs(table.clone(self.ecouteurs)) do
			f(self.etat)
		end
	end
	return reponse
end

function Session:nouvelleCommande()
	if self.remote then
		return agir(self, "nouvelleCommande") -- le serveur tire la commande
	end
	return agir(self, "nouvelleCommande", self.rng)
end
function Session:validerCroquis(croquis, tissus)
	return agir(self, "validerCroquis", croquis, tissus)
end
function Session:retourCarnet()
	return agir(self, "retourCarnet")
end
function Session:acheter(idTissu, dm)
	return agir(self, "acheter", idTissu, dm)
end
function Session:commencerDecoupe()
	return agir(self, "commencerDecoupe")
end
function Session:couper(idPiece, placement)
	return agir(self, "couper", idPiece, placement)
end
function Session:epingler(idPiece)
	return agir(self, "epingler", idPiece)
end
function Session:rendreCouture(idPiece, ecarts, duree, assistance)
	return agir(self, "rendreCouture", idPiece, ecarts, duree, assistance)
end
function Session:decorer(liste)
	return agir(self, "decorer", liste)
end
function Session:retourDecorations()
	return agir(self, "retourDecorations")
end
function Session:livrer()
	return agir(self, "livrer")
end
function Session:retoucher()
	return agir(self, "retoucher")
end
function Session:abandonner()
	return agir(self, "abandonner")
end
function Session:recommencer()
	return agir(self, "recommencer")
end

return Session
```

- [ ] **Step 4: Lancer les tests**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT"`
Expected (le scénario joue encore en local) :
```
Unitaires : 104837 vérifications
TOUT EST VERT : 295 vérifications
```

- [ ] **Step 5: Le scénario démarre le serveur et joue contre lui**

Dans `tests/scenario.luau` :

1. Remplacer les deux premières lignes de commentaire (`-- Scénario du nouvel atelier : une commande jouée…` et la suivante) par :

```lua
-- Scénario du nouvel atelier : le serveur et le client démarrés comme dans le jeu, une commande jouée
-- de bout en bout en cliquant dans l'interface, comme le ferait un joueur, puis des tentatives de triche.
```

2. Juste avant `local scriptClient = M.nouvelleInstance("LocalScript")`, ajouter :

```lua
-- Serveur (il fait foi) : démarré avant le client, qui attend sa RemoteFunction « Atelier »
local scriptServeur = M.nouvelleInstance("Script")
scriptServeur.Name = "Atelier"
for _, nom in ipairs(NOMS_SERVEUR) do
	local ms = M.nouvelleInstance("ModuleScript")
	ms.Name = nom
	ms.Parent = scriptServeur
end
scriptServeur.Parent = M.services.ServerScriptService
SCRIPTS.Serveur(scriptServeur)
local serveur = requireModule(scriptServeur.Commande).courante
```

3. Dans la partie « Accueil », juste après `cliquer("Clochette")`, ajouter :

```lua
verifier(M.dernierAppel ~= nil and M.dernierAppel.action == "nouvelleCommande" and serveur:atelier(joueur).etat.etape == "carnet", "la commande passe par le serveur, qui fait foi")
```

4. Dans la partie « Décorations », remplacer

```lua
-- La cliente veut une croix d'argent : sans elle, la robe sera refusée
etatJeu.commande.exigences = { { type = "accessoire", id = "croix_argent" }, { type = "min", style = "romantique", valeur = 1 } }
```

par :

```lua
-- La cliente veut une croix d'argent : sans elle, la robe sera refusée (posé sur le serveur, qui juge
-- la robe, et sur la copie du client, qui affiche la commande)
local function exigencesTest()
	return { { type = "accessoire", id = "croix_argent" }, { type = "min", style = "romantique", valeur = 1 } }
end
serveur:atelier(joueur).etat.commande.exigences = exigencesTest()
etatJeu.commande.exigences = exigencesTest()
```

5. À la fin, juste avant `print(("TOUT EST VERT : %d vérifications"):format(nbVerifs))`, ajouter :

```lua
---------------------------------------------------------------------------
-- Triche : appels directs au serveur ; le client n'a qu'une copie de l'état
---------------------------------------------------------------------------
local remoteAtelier = RS.Atelier
local etatServeur = serveur:atelier(joueur).etat
local argentServeur, stockServeur = etatServeur.argent, table.clone(etatServeur.stock)
M.avancer(1)
local rt = remoteAtelier:InvokeServer("voler", 1000)
verifier(not rt.ok and rt.erreur == "Action inconnue.", "triche : action inconnue refusée")
M.avancer(0.5)
rt = remoteAtelier:InvokeServer("livrer")
verifier(not rt.ok and rt.erreur == "Ce n'est pas le moment de livrer.", "triche : action dans le désordre refusée")
M.avancer(0.5)
rt = remoteAtelier:InvokeServer("couper", "jupe_trapeze_devant", { x = 50, y = 2, angle = 0 })
verifier(not rt.ok and rt.erreur == "La pièce dépasse du tissu.", "triche : découpe hors du rouleau refusée")
M.avancer(1.1)
local refuses = 0
for _ = 1, 8 do
	if remoteAtelier:InvokeServer("etat").erreur == "Doucement !" then
		refuses += 1
	end
end
verifier(refuses == 8 - serveur.APPELS_PAR_SECONDE, "triche : rafale d'appels, les appels de trop refusés")
etatJeu.argent = 1000000 -- le client modifie sa copie
M.avancer(1.1)
rt = remoteAtelier:InvokeServer("acheter", "soie_rouge", 100)
verifier(etatServeur.argent == argentServeur - (rt.ok and rt.prix or 0) and (rt.ok or rt.erreur == "Pas assez d'argent."), "triche : l'argent de la copie du client ne compte pas")
etatServeur.argent, etatServeur.stock = argentServeur, stockServeur
M.avancer(1.1)
SessionModule.courante:actualiser()
verifier(etatJeu.argent == argentServeur and titre() == "3. Table de découpe", "la copie du client revient à l'état du serveur")
```

- [ ] **Step 6: Lancer les tests, vérifier l'échec**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT|attempt" | head -3`
Expected: échec : une ligne qui finit par `ÉCHEC : la commande passe par le serveur, qui fait foi` (unitaires : 104837 vérifications)

- [ ] **Step 7: Brancher le client sur le serveur**

Dans `src/client/Atelier/init.client.luau` :
- après `local Players = game:GetService("Players")`, ajouter `local ReplicatedStorage = game:GetService("ReplicatedStorage")` ;
- remplacer `local session = Session.nouvelle()` par :

```lua
-- Chaque action passe par le serveur, qui fait foi (attend sa RemoteFunction, puis l'état du joueur)
local session = Session.distante(ReplicatedStorage:WaitForChild("Atelier"))
```

- [ ] **Step 8: Lancer les tests**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT"`
Expected:
```
Unitaires : 104837 vérifications
TOUT EST VERT : 302 vérifications
```

- [ ] **Step 9: Commit**

```bash
git add src/client/Atelier/Session.luau src/client/Atelier/init.client.luau tests/unitaires/29_session_distante.luau tests/scenario.luau
git commit -m "Le client passe par le serveur : session distante, état rechargé sur place, triche refusée

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 4: Vérification dans Studio et README

**Files:**
- Modify: `README.md`
- Modify: `AtelierCouture.rbxl` (régénéré)

**Interfaces:**
- Consumes: tout ce qui précède.
- Produces: une commande complète tenue par le serveur. C'est le point de départ du plan 4b (sauvegarde).

- [ ] **Step 1: Le serveur est là**

Servir le dépôt avec Rojo (`C:/dev/jeux/roblox-maker/rojo.exe serve --port 34872`) et reconnecter le plugin. Avec `execute_luau` (Edit), lister `game.ServerScriptService.Atelier` et ses enfants.

Expected : `Script` avec `Commande` et `Limiteur` (ModuleScript).

- [ ] **Step 2: Une commande complète à travers le vrai réseau**

Lancer Play et faire une robe en coton à carreaux comme à la tâche 6 du plan 3c : carnet `ToutEnUnTissu` puis `Tissu_coton_bleu_carreaux`, `Valider`, `Acheter`, `AllerDecoupe`, quatre fois `Couper`, les quatre `Epingler_…`, puis la couture en vitesse lapin avec l'assistance (maintenir `Coudre` environ 13 s, puis `PieceSuivante`, pour chaque pièce). Entre-temps, avec `execute_luau` (Client) : `game.ReplicatedStorage.Atelier:InvokeServer("etat")`.

Expected : l'état renvoyé suit l'interface (étape, argent, stock, rouleau) ; au bout de la couture, « 6. Décorations », et les coutures notées 0,85 par le serveur.

- [ ] **Step 3: Présenter, livrer**

Cliquer `Presenter`, puis `Livrer`.

Expected : robe acceptée (accueil, paie) ou refusée (« La cliente refuse la robe », exigences ratées avec leur score actuel, bulle de refus). Si elle est refusée, garder cet écran pour l'étape 4.

- [ ] **Step 4: Tentatives de triche depuis le client**

Avec `execute_luau` (Client), en espaçant les appels de 0,3 s (`task.wait(0.3)`) :
1. `InvokeServer("voler", 1000)` → « Action inconnue. » ;
2. une action dans le désordre, comme `InvokeServer("acheter", "soie_rouge", 5)` à l'écran du refus → refus de l'étape ;
3. après `task.wait(1.2)`, huit `InvokeServer("etat")` sans attente → 3 réponses « Doucement ! » ;
4. si la robe a été refusée : `InvokeServer("retoucher")`, puis `InvokeServer("decorer", …)` avec `workspace`, `{ 1, 2, x = 3 }`, `"tout"`, une décoration à `u = 0/0` et une sur la pièce 99 → refus propres (« Décorations invalides. », « Accessoire inconnu. », « Accessoire mal placé. », « Accessoire sur une pièce inexistante. ») ; puis `InvokeServer("decorer", {})` et `InvokeServer("livrer")` pour revenir au refus.

Expected : aucune réponse « Action impossible. ». Avec `execute_luau` (Server), lire `LogService:GetLogHistory()` : aucune erreur ni alerte hors CorePackages.

- [ ] **Step 5: Finir la commande**

Cliquer `Abandonner` deux fois (ou, après une robe acceptée, `Clochette`), puis arrêter Play.

Expected : accueil, bulle « Tant pis… Au revoir. » ; côté client, `LogService` sans erreur ni alerte hors CorePackages.

- [ ] **Step 6: Mettre à jour le README**

Dans `README.md` :

1. Remplacer

```markdown
## État actuel (plan 3d)

Jouable dans Studio, en solo, sans sauvegarde (l'état de la partie vit dans le client) :
```

par :

```markdown
## État actuel (plan 4a)

Jouable dans Studio, en solo, sans sauvegarde. Le serveur tient l'atelier de chaque joueur et valide chaque
action (il fait foi) ; le client n'affiche qu'une copie de l'état :
```

2. Remplacer `9. La suite : serveur, boutiques et sauvegarde au plan 4.` par :

```markdown
9. La suite : sauvegarde (plan 4b), boutiques de la rue et vitrines visibles par tous (plan 4c),
   finition (plan 4d).
```

3. Dans le tableau de `src/shared/`, remplacer la ligne de `EtatAtelier` par :

```markdown
  | `EtatAtelier` | État de la commande et règles de chaque étape, relevé de couture vraisemblable, recette de la robe ; copie de l'état en données simples (`exporter`, `charger`) |
```

4. Remplacer

```markdown
- `src/client/Atelier/` (LocalScript `Atelier` et ses modules) : l'interface.
  `Session` fait le lien avec l'état ;
```

par :

```markdown
- `src/server/` (Script `Atelier` de ServerScriptService et ses modules) : le serveur, qui fait foi.
  `Commande` tient l'atelier de chaque joueur (un `EtatAtelier`) derrière la RemoteFunction `Atelier` :
  actions permises seulement, 5 appels par seconde au plus (sauf les relevés de couture, bornés par leur
  vraisemblance), toute erreur devient un refus ; chaque réponse acceptée emporte l'état. `Limiteur` compte
  les appels.
- `src/client/Atelier/` (LocalScript `Atelier` et ses modules) : l'interface.
  `Session` envoie chaque action au serveur et recharge sur place la copie de l'état qu'il renvoie ;
```

5. Remplacer `- \`tests/scenario.luau\` : une commande jouée de bout en bout en cliquant dans l'interface.` par :

```markdown
- `tests/scenario.luau` : le serveur et le client démarrés comme dans le jeu, une commande jouée de bout en
  bout en cliquant dans l'interface, puis des tentatives de triche (appels directs au serveur).
```

- [ ] **Step 7: Tests, lieu régénéré, commit**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT"`
Expected:
```
Unitaires : 104837 vérifications
TOUT EST VERT : 302 vérifications
```

```bash
C:/dev/jeux/roblox-maker/rojo.exe build -o AtelierCouture.rbxl
git add README.md AtelierCouture.rbxl
git commit -m "Plan 4a terminé : la commande tenue par le serveur

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```
