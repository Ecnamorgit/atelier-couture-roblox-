# Cœur de l'atelier — Plan 4d-1 : robustesse et confort du joueur

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rendre le jeu sûr face à un réseau lent ou coupé, à un serveur qui s'arrête et à une mémoire pleine, et régler les gênes signalées au fil des plans 3 et 4 (photo, livraison, couture), sans rien ajouter au gameplay.

**Architecture:**
- **Serveur** : chaque refus des règles emporte l'état (le client répare sa copie) ; les refus d'un moment sont marqués `passager` ; l'état renvoyé est préparé à l'abri des erreurs, sans copier les anciennes robes. Les sauvegardes d'un joueur passent une à la fois, l'arrivée et l'arrêt du serveur attendent ce qui est en cours, et une partie trop lourde perd ses plus anciennes robes. Une boutique impossible à construire n'empêche pas de jouer.
- **Client** : la `Session` signale l'attente du serveur, recharge l'état joint aux refus et le redemande après une réponse perdue ; l'interface montre « Un instant… » quand l'attente dure et affiche en gris les refus passagers, qui ne défont rien.
- **Photo et scène** : chaque prise de vue a son numéro, « Livrer » demande confirmation, la fenêtre fermée rend la lumière du jeu, une pièce ratée faute de mémoire est reconstruite, les images des pièces sont oubliées une fois la commande finie.

**Tech Stack:** Luau, Rojo 7.7.0-rc.1, simulation Luau 0.650 (`tests/lancer.sh`), Roblox Studio via le connecteur MCP Studio.

**Spec:** `docs/superpowers/specs/2026-09-28-atelier-coeur-design.md` (§2 Réseau, §4 Photo et livraison, §6 Sauvegarde et protections, §7 Tests). Plans précédents : `docs/superpowers/plans/2026-09-29-coeur-plan4a-serveur-commande.md`, `…plan4b-sauvegarde.md`, `…plan4c-boutiques.md`.

## Décisions de ce plan

- **Refus passager** (`passager = true`) : trop d'appels (« Doucement ! »), atelier en préparation, serveur occupé par l'action précédente (« Un instant… »), serveur injoignable ou réponse illisible. Il s'affiche en gris et ne défait rien : à la machine à coudre, la pièce finie reste finie, on la rend de nouveau. Les autres refus restent en rouge.
- **L'état joint aux refus** : un refus des règles d'`EtatAtelier` emporte l'état, comme une réponse acceptée. Le client le recharge et prévient les écrans s'il a changé : sa copie se répare d'elle-même (réponse perdue, partie arrivée après l'abandon de l'attente). Une action inconnue et les refus passagers n'emportent rien. Les relevés de couture, que rien ne limite, ne l'emportent sur un refus que dans la limite de 5 appels par seconde.
- **Réponse perdue ou illisible** : refus passager, et l'état est redemandé au serveur 2 s plus tard (`Session.RESYNCHRO`), une seule fois. `Session:actualiser` passe par la même file qu'une action (une seule à la fois) et prévient les écrans si l'état a changé.
- **Indicateur d'attente** : `Session:surAttente(f)` ; au-delà de 0,3 s, `init.client` affiche « Un instant… » en gris à la place du message, jusqu'à la réponse. Un message déjà affiché (l'avertissement de la sauvegarde, par exemple) n'est pas remplacé.
- **Arrivée** : si la partie n'est toujours pas là au bout des 60 essais, ou si le serveur ne répond pas, le joueur est prévenu (`Session.PAS_PRETE`) ; sa prochaine action apportera la vraie partie.
- **Photo** : chaque prise a son numéro ; le minuteur de 2 s ou la réponse tardive d'une prise terminée ne touchent pas à la suivante. « Livrer la robe » passe 20 px sous « Prendre la photo » et demande un second appui (`UiKit.boutonConfirme`, avec l'allure d'un bouton principal). Fenêtre fermée pendant l'étape photo : décor retiré, lumière et mannequin du jeu ; rouverte, les réglages reviennent. Galerie indisponible : un message, sans erreur.
- **Sauvegarde** :
  - une écriture à la fois par joueur (`Commande.ecritures[UserId]`) : la suivante attend la fin de la précédente, puis écrit l'état du moment ;
  - un joueur de retour sur le même serveur attend la fin de l'écriture de son départ avant la lecture de sa partie ;
  - à l'arrêt, `fermer` attend aussi les parties en cours de lecture (`Commande.chargements`), rendues aussitôt lues ;
  - au-delà de 3 500 000 caractères en JSON (`Sauvegarde.TAILLE_MAX`, sous les 4 Mo d'une clé du DataStore), la partie perd ses plus anciennes robes jusqu'à tenir ;
  - une erreur en préparant la partie ne bloque pas les écritures suivantes.
- **Boutique** : une panne pendant la construction n'empêche pas de jouer : attribut `Boutique` à 0 (l'atelier hors de la rue), emplacement resté libre.
- **Scène** : une pièce ratée faute de mémoire des maillages est oubliée, donc reconstruite à la synchronisation suivante. Les images des pièces découpées (`Vignettes.oublierPieces`) sont oubliées quand l'écran passe à l'accueil ou au carnet ; les motifs de tissu restent en cache.
- **Faux Roblox** : il gagne `HttpService:JSONEncode`, une galerie qui peut échouer (`M.echecGalerie`), et garde le rappel d'une capture muette (`M.rappelCapture`) pour répondre plus tard.
- **Laissé au plan 4d-2** : les écarts à la spec §4, les sons, les réglages mobiles, l'équilibrage, la table et la machine plus réalistes, et les mineurs restants des ledgers.
  - Mineurs restants : pièce fantôme après « Recommencer » ; aperçu des décorations reconstruit à chaque action ; `toucher` qui ignore l'écart de `versUV` ; liste des joueurs coupée ; bornes de `UiKit.echelle` ; lumière de la photo dans l'ombre des murs.
  - L'orientation des accessoires dans la rangée d'en face n'a pas été reproduite : aucune normale verticale sur les pièces actuelles, sur une grille de u et v.
- **Non vérifié pendant la préparation** : Studio. La tâche 7 le fait par le connecteur MCP. Le rendu visuel et l'essai à 3 joueurs restent au commanditaire.

## Global Constraints

- **Dépôt** : `C:\dev\jeux\atelier-couture`, branche `robustesse`, créée depuis `main` (où le plan 4c est fusionné). Ne rien pousser sur GitHub sans demande.
- **Rojo** : `C:/dev/jeux/roblox-maker/rojo.exe`.
- **Contraintes des plans précédents toujours valables** : fins de ligne LF, commits en français terminés par `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`, textes d'au moins 14 px, le serveur fait foi.
- **Protections** (spec §6) : 5 appels par seconde et par joueur (sauf les relevés de couture), toute erreur du serveur devient un refus, jamais d'erreur levée vers le client.
- **Sauvegarde** (spec §6) : UpdateAsync avec verrou de session ; une écriture à l'arrivée, toutes les 60 s, au départ et à l'arrêt (25 s au plus) ; rien n'est écrit si la lecture a échoué.

## Review Focus

- **Réponse perdue alors que le serveur a agi** (réseau coupé au retour). Attendu : un message en gris, rien de fait deux fois, et la copie du client rejoint celle du serveur dans les 2 s. Tests : `39_session_resynchro`, « réponse perdue » et « l'état est redemandé ».
- **Double appui rapide** (double clic, doigt qui tremble) sur « Livrer la robe » ou pendant l'attente du serveur. Attendu : une seule action, jamais de livraison sans le second appui voulu. Tests : scénario, « un double clic trop rapide ne livre pas » ; `29_session_distante`, « le second appui attend ».
- **Retour rapide du joueur sur le même serveur, arrêt du serveur pendant une arrivée.** Attendu : aucune progression perdue, verrou rendu. Tests : `40_sauvegarde_serie`, « retour : la partie lue est celle écrite au départ », « lue après l'arrêt : la partie est rendue aussitôt ».
- **Partie énorme** (appels forgés : 300 garnitures de 64 points sur chacune des 10 robes). Attendu : la partie est encore écrite, sans ses plus anciennes robes. Test : `40_sauvegarde_serie`, « partie trop lourde ».
- **Mémoire pleine sur téléphone** (maillages, images). Attendu : la pièce apparaît dès que la mémoire le permet ; les images des commandes finies ne s'accumulent pas. Tests : `20_scene`, « la pièce ratée est construite à la synchronisation suivante » ; scénario, « les images des pièces découpées sont oubliées ».

## Structure des fichiers

| Fichier | Rôle |
|---|---|
| `src/server/Commande.luau` | Refus passagers, état joint aux refus, instantané protégé ; écritures en série, lectures suivies, arrêt qui les attend |
| `src/server/Sauvegarde.luau` | `TAILLE_MAX` : une partie trop lourde perd ses plus anciennes robes |
| `src/server/Boutiques.luau` | Construction en panne : attribut 0, emplacement libre |
| `src/shared/EtatAtelier.luau` | `exporter(robes)` ; `charger` dit si l'état a changé |
| `src/client/Atelier/Session.luau` | Attente signalée, état des refus rechargé, resynchronisation, `OCCUPE`, `PAS_PRETE` |
| `src/client/Atelier/init.client.luau` | « Un instant… », `ctx.refus`, images des pièces oubliées |
| `src/client/Atelier/Ecran*.luau` | `ctx.refus(r)` ; la couture garde la pièce finie sur un refus passager ; photo et livraison |
| `src/client/Atelier/UiKit.luau` | `boutonConfirme(props, auClic, principal)` |
| `src/client/Atelier/Scene.luau` | Pièce ratée reconstruite |
| `src/client/Atelier/Vignettes.luau` | `oublierPieces()` |
| `tests/mock.luau`, `tests/gen_api.py` | `HttpService:JSONEncode`, galerie en panne, rappel de capture gardé |
| `tests/unitaires/38_reponses_serveur.luau`, `39_session_resynchro.luau`, `40_sauvegarde_serie.luau` | Nouveaux tests |
| `tests/unitaires/20_scene.luau`, `28_…`, `29_…`, `32_…`, `34_boutiques.luau`, `tests/scenario.luau` | Tests complétés |
| `README.md`, `AtelierCouture.rbxl` | État du jeu ; lieu régénéré |

---

### Task 1: Les réponses du serveur

**Files:**
- Modify: `src/server/Commande.luau` (`refus`, `instantane`, `traiter`)
- Modify: `src/shared/EtatAtelier.luau` (`exporter`)
- Create: `tests/unitaires/38_reponses_serveur.luau`
- Modify: `tests/unitaires/28_commande_serveur.luau`

**Interfaces:**
- Consumes: `Commande.nouvelle(options)`, `Commande:traiter(joueur, action, ...)`, `Limiteur:autoriser(joueur)` (plans 4a et 4b).
- Produces:
  - Réponse de `Commande:traiter` : `{ ok = false, erreur, etat? , passager?, attente? }`.
    - Un refus des règles porte `etat` (données de `Commande.instantane`).
    - « Doucement ! » porte `passager = true`, sans `etat`.
    - L'atelier en préparation porte `attente = true, passager = true`.
    - Une action inconnue ne porte ni `etat` ni `passager`.
  - `EtatAtelier:exporter(robes?)` : `robes` = nombre de robes copiées, les plus récentes (toutes par défaut).
  - `Commande.instantane(etat)` = `etat:exporter(1)`.

- [ ] **Step 1: Écrire les tests**

Créer `tests/unitaires/38_reponses_serveur.luau` :

```lua
local Commande = U.module("Commande")

local courant = Commande.courante
local serveur = Commande.nouvelle()
local joueur = M.nouveauJoueur("Reponses")
-- Un appel du client, espacé comme un joueur ; chaque réponse doit pouvoir passer par le réseau
local function appeler(action, ...)
	M.avancer(0.25)
	local r = serveur:traiter(joueur, action, ...)
	U.verifier(pcall(M.transmettre, r), "réponse transmissible : " .. tostring(action))
	return r
end
local etat = serveur:atelier(joueur).etat

---------------------------------------------------------------------------
-- Un refus des règles emporte l'état : le client répare sa copie (réponse perdue, partie arrivée tard)
---------------------------------------------------------------------------
etat.argent = 432
local r = appeler("livrer")
U.verifier(not r.ok and r.erreur == "Ce n'est pas le moment de livrer." and r.etat ~= nil and r.etat.argent == 432 and r.etat.etape == "accueil", "refus des règles : l'état du serveur est joint")
U.verifier(not r.passager, "un refus des règles n'est pas passager (réessayer n'y changerait rien)")
r = appeler("voler")
U.verifier(not r.ok and r.etat == nil and not r.passager, "action inconnue : ni état, ni réessai")

---------------------------------------------------------------------------
-- Refus passagers (réessayer plus tard) : trop d'appels, atelier en préparation
---------------------------------------------------------------------------
M.avancer(1.01)
for _ = 1, Commande.APPELS_PAR_SECONDE do
	serveur:traiter(joueur, "etat")
end
r = serveur:traiter(joueur, "etat")
U.verifier(not r.ok and r.erreur == "Doucement !" and r.passager == true and r.etat == nil, "trop d'appels : refus passager, sans état")
local lent = Commande.nouvelle({ sauvegarde = {} }) -- partie pas encore lue
r = lent:traiter(M.nouveauJoueur("Patiente"), "etat")
U.verifier(not r.ok and r.attente and r.passager == true, "atelier en préparation : refus passager")

---------------------------------------------------------------------------
-- Relevés de couture (non limités) : un refus n'emporte l'état que dans la limite des appels
---------------------------------------------------------------------------
M.avancer(1.01)
local avecEtat = 0
for _ = 1, 10 do
	r = serveur:traiter(joueur, "rendreCouture", "corsage_droit_devant", {}, 1) -- dix relevés au même instant
	U.verifier(not r.ok and r.erreur ~= "Doucement !", "relevé refusé par les règles, jamais limité")
	if r.etat then
		avecEtat += 1
	end
end
U.verifier(avecEtat == Commande.APPELS_PAR_SECONDE, "relevés refusés en rafale : l'état n'est joint qu'aux " .. avecEtat .. " premiers")

---------------------------------------------------------------------------
-- L'état renvoyé : préparé à l'abri des erreurs, sans parcourir les anciennes robes
---------------------------------------------------------------------------
M.avancer(1.01)
local vrai = Commande.instantane
Commande.instantane = function()
	error("panne simulée")
end
local sansErreur, r2 = pcall(serveur.traiter, serveur, joueur, "etat")
Commande.instantane = vrai
U.verifier(sansErreur and not r2.ok and r2.erreur == "Action impossible.", "erreur en préparant l'état renvoyé : refus, pas d'erreur")
-- Une ancienne robe qui se contient elle-même : la copier ne finirait jamais
local boucle = {}
boucle.moi = boucle
etat.robes = { { numero = 1 }, boucle }
local copie = select(2, pcall(Commande.instantane, etat))
U.verifier(type(copie) == "table" and #copie.robes == 1 and copie.robes[1].numero == 1 and copie.robes[1] ~= etat.robes[1], "l'état renvoyé copie la robe en vitrine, sans parcourir les anciennes")
local d = etat:exporter(1)
U.verifier(#d.robes == 1 and d.robes[1].numero == 1, "exporter(1) : une seule robe")
etat.robes = { { numero = 1 }, { numero = 2 } }
U.verifier(#etat:exporter().robes == 2, "exporter() : toutes les robes (sauvegarde)")
Commande.courante = courant
```

Dans `tests/unitaires/28_commande_serveur.luau`, remplacer :

```lua
U.verifier(not r.ok and r.erreur == "Ce n'est pas le moment de livrer." and r.etat == nil, "livrer sans commande : refusé")
```

par :

```lua
U.verifier(not r.ok and r.erreur == "Ce n'est pas le moment de livrer." and r.etat ~= nil and r.etat.etape == "accueil", "livrer sans commande : refusé (avec l'état du serveur)")
```

- [ ] **Step 2: Lancer les tests, vérifier l'échec**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT|attempt" | head -3`
Expected: échec : une ligne qui finit par `ÉCHEC : livrer sans commande : refusé (avec l'état du serveur)` (le test 28, lancé avant le 38 : un refus n'emporte pas encore l'état)

- [ ] **Step 3: Écrire le code**

Dans `src/server/Commande.luau`, remplacer :

```lua
local function refus(message)
	return { ok = false, erreur = message }
end
```

par :

```lua
-- passager : refus d'un moment (trop d'appels, partie pas encore lue), le client pourra réessayer
local function refus(message, passager)
	return { ok = false, erreur = message, passager = passager }
end
```

Dans `src/server/Commande.luau`, remplacer :

```lua
-- L'état envoyé au client : tout, sauf les anciennes robes (seule la plus récente est en vitrine)
function Commande.instantane(etat)
	local d = etat:exporter()
	d.robes = { d.robes[1] }
	return d
end
```

par :

```lua
-- L'état envoyé au client : tout, sauf les anciennes robes (seule la plus récente est en vitrine)
function Commande.instantane(etat)
	return etat:exporter(1)
end
```

Dans `src/server/Commande.luau`, remplacer :

```lua
	if not SANS_LIMITE[action] and not self.limiteur:autoriser(joueur) then
		return refus("Doucement !")
	end
	local a = self:atelier(joueur)
	if not a then
		return { ok = false, erreur = PREPARATION, attente = true }
	end
	local ok, reponse = pcall(faire, a, ...)
	if not ok then
```

par :

```lua
	if not SANS_LIMITE[action] and not self.limiteur:autoriser(joueur) then
		return refus("Doucement !", true)
	end
	local a = self:atelier(joueur)
	if not a then
		return { ok = false, erreur = PREPARATION, attente = true, passager = true }
	end
	local ok, reponse = pcall(function(...)
		local r = faire(a, ...)
		-- Acceptée ou refusée par les règles, la réponse emporte l'état : le client répare ainsi sa copie
		-- (réponse perdue, partie lue après son arrivée). Les relevés de couture, que rien ne limite,
		-- ne l'emportent sur un refus que dans la limite des appels.
		if r.ok or not SANS_LIMITE[action] or self.limiteur:autoriser(joueur) then
			r.etat = Commande.instantane(a.etat)
		end
		return r
	end, ...)
	if not ok then
```

Dans `src/server/Commande.luau`, remplacer :

```lua
	if reponse.ok then
		reponse.etat = Commande.instantane(a.etat)
		if action == "etat" 
```

par :

```lua
	if reponse.ok then
		if action == "etat" 
```

Dans `src/shared/EtatAtelier.luau`, remplacer :

```lua
-- L'état en données simples, sans métatable : ce que le serveur envoie au client après chaque action.
-- Les rouleaux deviennent { longueur, poses }.
function EtatAtelier:exporter()
	local d = {}
	for _, cle in ipairs(CHAMPS) do
		d[cle] = copie(self[cle])
	end
```

par :

```lua
-- L'état en données simples, sans métatable : ce que le serveur envoie au client après chaque action.
-- Les rouleaux deviennent { longueur, poses }. robes (facultatif) : nombre de robes copiées, les plus
-- récentes (toutes par défaut)
function EtatAtelier:exporter(robes)
	local d = {}
	for _, cle in ipairs(CHAMPS) do
		if cle ~= "robes" then
			d[cle] = copie(self[cle])
		end
	end
	d.robes = {}
	for i = 1, math.min(#self.robes, robes or #self.robes) do
		d.robes[i] = copie(self.robes[i])
	end
```

- [ ] **Step 4: Lancer les tests**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT"`
Expected:
```
Unitaires : 105002 vérifications
TOUT EST VERT : 317 vérifications
```

- [ ] **Step 5: Commit**

```bash
git add src/server/Commande.luau src/shared/EtatAtelier.luau tests/unitaires/38_reponses_serveur.luau tests/unitaires/28_commande_serveur.luau
git commit -m "Serveur : l'état joint aux refus des règles, refus passagers, instantané protégé et léger

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 2: La session du client : attente, refus, resynchronisation

**Files:**
- Modify: `src/shared/EtatAtelier.luau` (`charger`)
- Modify: `src/client/Atelier/Session.luau`
- Create: `tests/unitaires/39_session_resynchro.luau`
- Modify: `tests/unitaires/29_session_distante.luau`, `tests/unitaires/32_session_attente.luau`

**Interfaces:**
- Consumes: les réponses de la tâche 1 (`etat` joint aux refus, `passager`).
- Produces:
  - `EtatAtelier:charger(d)` renvoie `self, change` (booléen : un champ ou un rouleau a changé).
  - `Session.OCCUPE = "Un instant…"`, `Session.PAS_PRETE` (texte), `Session.RESYNCHRO = 2`.
  - `Session:surAttente(f)` : `f(true)` au début, `f(false)` à la fin de chaque appel au serveur.
  - Réponse d'une action : `{ ok = false, erreur, passager = true }` quand la session est occupée, le serveur injoignable ou la réponse illisible.
  - `session.avertissement` vaut `Session.PAS_PRETE` si la partie n'est pas arrivée.
  - `Session:actualiser()` prévient les écrans si l'état a changé.

- [ ] **Step 1: Écrire les tests**

Créer `tests/unitaires/39_session_resynchro.luau` :

```lua
local Session = U.module("Session")
local Commande = U.module("Commande")
local EtatAtelier = U.module("EtatAtelier")

---------------------------------------------------------------------------
-- EtatAtelier:charger dit si quelque chose a changé
---------------------------------------------------------------------------
local e = EtatAtelier.nouveau()
local d = e:exporter()
local _, change = e:charger(d)
U.verifier(change == false, "recharger le même état : rien n'a changé")
d.argent += 1
_, change = e:charger(d)
U.verifier(change == true and e.argent == d.argent, "un champ différent : changé")

---------------------------------------------------------------------------
-- Un serveur dont l'appel ou la réponse peuvent se perdre
---------------------------------------------------------------------------
local courante, courant = Session.courante, Commande.courante
local serveur = Commande.nouvelle()
local remote = M.nouvelleInstance("RemoteFunction")
local joueur = M.nouveauJoueur("Resynchro")
M.joueurLocal = joueur
local panne = nil -- "apres" : le serveur agit, la réponse se perd ; "illisible" : état reçu abîmé
remote.OnServerInvoke = function(j, action, ...)
	local r = serveur:traiter(j, action, ...)
	if panne == "apres" then
		error("réponse perdue")
	elseif panne == "illisible" and r.etat then
		r.etat.coupons = "abîmé"
	end
	return r
end
local function cote()
	return serveur:atelier(joueur).etat
end
M.avancer(1)
local session = Session.distante(remote)
local notifications = 0
session:surChangement(function()
	notifications += 1
end)
local attentes = {}
session:surAttente(function(actif)
	table.insert(attentes, actif)
end)

-- L'attente du serveur est signalée (début, fin) : l'interface montre un indicateur si elle dure
M.avancer(1)
U.verifier(session:nouvelleCommande().ok, "nouvelle commande")
U.verifier(#attentes == 2 and attentes[1] == true and attentes[2] == false, "attente signalée : début, puis fin")

-- Réponse perdue : refus passager ; l'état est redemandé au serveur un peu plus tard
local CROQUIS = { corsage = "corsage_droit", manches = "manches_sans", col = "col_sans", jupe = "jupe_droite" }
local TISSUS = { corsage_droit_devant = "coton_blanc", corsage_droit_dos = "coton_blanc", jupe_droite_devant = "coton_blanc", jupe_droite_dos = "coton_blanc" }
panne = "apres"
M.avancer(1)
local avant = notifications
local r = session:validerCroquis(CROQUIS, TISSUS)
panne = nil
U.verifier(not r.ok and r.passager == true and r.erreur == "Le serveur ne répond pas. Réessaie.", "réponse perdue : refus passager")
U.verifier(session.etat.etape == "carnet" and cote().etape == "achat" and notifications == avant, "le serveur a agi, le client ne le sait pas encore")
M.avancer(Session.RESYNCHRO + 0.1)
U.verifier(session.etat.etape == "achat" and notifications == avant + 1, "l'état est redemandé : la copie est réparée, les écrans prévenus")
U.verifier(session.derniere.action == "nouvelleCommande", "la dernière action reste celle du joueur")

-- Réponse illisible : refus passager, sans erreur ; la session n'est pas bloquée
panne = "illisible"
M.avancer(1)
local sansErreur, r2 = pcall(session.acheter, session, "coton_blanc", 5)
panne = nil
U.verifier(sansErreur and not r2.ok and r2.passager == true and not session.enCours, "réponse illisible : refus passager, sans erreur, session libre")
M.avancer(1)
U.verifier(session:acheter("coton_blanc", 1).ok, "l'action suivante passe")
M.avancer(Session.RESYNCHRO + 0.1)
U.verifier(session.etat.stock.coton_blanc == cote().stock.coton_blanc, "copie réparée après la réponse illisible")

-- Un refus emporte l'état du serveur : une copie fausse est réparée, les écrans prévenus
cote().argent = 4321
M.avancer(1)
avant = notifications
r = session:acheter("coton_blanc", 0)
U.verifier(not r.ok and r.erreur == "Longueur invalide." and session.etat.argent == 4321 and notifications == avant + 1, "refus : l'état joint répare la copie, les écrans sont prévenus")
M.avancer(1)
r = session:acheter("coton_blanc", 0)
U.verifier(not r.ok and notifications == avant + 1, "refus sans rien de changé : les écrans ne sont pas dérangés")

-- actualiser prévient les écrans quand l'état a changé
cote().argent = 99
M.avancer(1)
session:actualiser()
U.verifier(session.etat.argent == 99 and notifications == avant + 2, "actualiser : les écrans sont prévenus")

-- Pendant une action, actualiser attend son tour (pas deux appels à la fois)
local pendant
remote.OnServerInvoke = function(j, action, ...)
	pendant = pendant or session:actualiser()
	return serveur:traiter(j, action, ...)
end
M.avancer(1)
session:acheter("coton_blanc", 1)
U.verifier(pendant ~= nil and not pendant.ok and pendant.passager == true and pendant.erreur == Session.OCCUPE, "actualiser pendant une action : « Un instant… »")
Session.courante, Commande.courante = courante, courant
```

Dans `tests/unitaires/29_session_distante.luau`, remplacer :

```lua
U.verifier(pendant ~= nil and not pendant.ok and pendant.erreur == "Un instant…", "le second appui attend : « Un instant… »")
```

par :

```lua
U.verifier(pendant ~= nil and not pendant.ok and pendant.erreur == "Un instant…" and pendant.passager == true, "le second appui attend : « Un instant… » (refus passager)")
```

Dans `tests/unitaires/29_session_distante.luau`, remplacer :

```lua
U.verifier(not r.ok and r.erreur == "Le serveur ne répond pas. Réessaie.", "serveur injoignable : message")
```

par :

```lua
U.verifier(not r.ok and r.erreur == "Le serveur ne répond pas. Réessaie." and r.passager == true, "serveur injoignable : message (refus passager)")
```

Dans `tests/unitaires/29_session_distante.luau`, remplacer :

```lua
U.verifier(autre.etat.etape == "accueil" and autre.etat.argent == EtatAtelier.ARGENT_DEPART, "serveur injoignable à l'arrivée : état de départ, sans erreur")
```

par :

```lua
U.verifier(autre.etat.etape == "accueil" and autre.etat.argent == EtatAtelier.ARGENT_DEPART, "serveur injoignable à l'arrivée : état de départ, sans erreur")
U.verifier(autre.avertissement == Session.PAS_PRETE, "serveur injoignable à l'arrivée : le joueur est prévenu")
```

Dans `tests/unitaires/32_session_attente.luau`, remplacer :

```lua
U.verifier(appels == Session.ESSAIS_ARRIVEE and lasse.etat.etape == "accueil" and lasse.avertissement == nil, "serveur jamais prêt : abandon après " .. tostring(Session.ESSAIS_ARRIVEE) .. " essais, état de départ")
```

par :

```lua
U.verifier(appels == Session.ESSAIS_ARRIVEE and lasse.etat.etape == "accueil", "serveur jamais prêt : abandon après " .. tostring(Session.ESSAIS_ARRIVEE) .. " essais, état de départ")
U.verifier(lasse.avertissement == Session.PAS_PRETE and string.find(Session.PAS_PRETE, "pas encore", 1, true) ~= nil, "serveur jamais prêt : le joueur est prévenu que sa partie n'est pas encore là")
```

- [ ] **Step 2: Lancer les tests, vérifier l'échec**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT|attempt" | head -3`
Expected: échec : une ligne qui finit par `ÉCHEC : le second appui attend : « Un instant… » (refus passager)`

- [ ] **Step 3: `charger` dit si l'état a changé**

Dans `src/shared/EtatAtelier.luau`, remplacer :

```lua
-- Remplace l'état par un état exporté, sur place : les écrans gardent le même objet. Ce qui n'a pas
-- changé garde sa table (la scène reconnaît ainsi la même commande d'une action à l'autre).
function EtatAtelier:charger(d)
	for _, cle in ipairs(CHAMPS) do
		if not pareil(self[cle], d[cle]) then
			self[cle] = copie(d[cle])
		end
	end
	if not pareil(rouleauxExportes(self.coupons), d.coupons) then
```

par :

```lua
-- Remplace l'état par un état exporté, sur place : les écrans gardent le même objet. Ce qui n'a pas
-- changé garde sa table (la scène reconnaît ainsi la même commande d'une action à l'autre).
-- Renvoie l'état et si quelque chose a changé.
function EtatAtelier:charger(d)
	local change = false
	for _, cle in ipairs(CHAMPS) do
		if not pareil(self[cle], d[cle]) then
			self[cle] = copie(d[cle])
			change = true
		end
	end
	if not pareil(rouleauxExportes(self.coupons), d.coupons) then
		change = true
```

Dans `src/shared/EtatAtelier.luau`, remplacer :

```lua
			self.coupons[idTissu] = coupon
		end
	end
	return self
end
```

par :

```lua
			self.coupons[idTissu] = coupon
		end
	end
	return self, change
end
```

- [ ] **Step 4: La session**

Dans `src/client/Atelier/Session.luau`, remplacer :

```lua
local INJOIGNABLE = "Le serveur ne répond pas. Réessaie."
Session.ESSAIS_ARRIVEE = 60 -- à l'arrivée, un essai par seconde tant que le serveur lit la partie (réessais du
-- DataStore et verrou tenu ailleurs compris)
```

par :

```lua
local INJOIGNABLE = "Le serveur ne répond pas. Réessaie."
Session.OCCUPE = "Un instant…" -- une action à la fois : un appui pendant l'attente du serveur est refusé
Session.PAS_PRETE = "Ta partie n'est pas encore arrivée du serveur : elle apparaîtra à ta prochaine action."
Session.ESSAIS_ARRIVEE = 60 -- à l'arrivée, un essai par seconde tant que le serveur lit la partie (réessais du
-- DataStore et verrou tenu ailleurs compris)
Session.RESYNCHRO = 2 -- s : après une réponse perdue, l'état est redemandé au serveur
```

Dans `src/client/Atelier/Session.luau`, remplacer :

```lua
-- le temps qu'il lise la partie du joueur (jusqu'à 15 s si un autre serveur la tenait). avertissement : un
-- message du serveur pour le joueur (sauvegarde impossible), ou nil. attendre (tests) : remplace task.wait.
```

par :

```lua
-- le temps qu'il lise la partie du joueur (jusqu'à 15 s si un autre serveur la tenait). avertissement : un
-- message pour le joueur (sauvegarde impossible, partie pas encore arrivée), ou nil. attendre (tests) :
-- remplace task.wait.
```

Dans `src/client/Atelier/Session.luau`, remplacer :

```lua
	self.avertissement = reponse.ok and reponse.avertissement or nil
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
```

par :

```lua
	-- Partie pas encore là (serveur injoignable ou trop long) : état de départ en attendant ; la première
	-- réponse du serveur, acceptée ou refusée, apportera la vraie partie
	self.avertissement = if reponse.ok then reponse.avertissement else Session.PAS_PRETE
	return self
end

-- Appel au serveur, sans jamais lever d'erreur. L'état joint à la réponse (acceptée ou refusée) est
-- rechargé. Renvoie la réponse, si l'état a changé, et si la réponse est perdue ou illisible (refus
-- passager : le serveur a pu agir sans que son état arrive).
local function appeler(self, nom, ...)
	if self.attente then
		self.attente(true)
	end
	local ok, reponse = pcall(self.remote.InvokeServer, self.remote, nom, ...)
	if self.attente then
		self.attente(false)
	end
	local change = false
	if ok and type(reponse) == "table" and type(reponse.etat) == "table" then
		local lu, _, c = pcall(self.etat.charger, self.etat, reponse.etat)
		ok, change = lu, c == true
	end
	if not ok or type(reponse) ~= "table" then
		return { ok = false, erreur = INJOIGNABLE, passager = true }, false, true
	end
	return reponse, change, false
end

-- Prévient les écrans que l'état a changé
local function prevenir(self)
	for _, f in ipairs(table.clone(self.ecouteurs)) do
		f(self.etat)
	end
end

-- Une action (ou « etat ») : une à la fois. Les écrans sont prévenus après une action réussie, ou quand
-- l'état joint à une réponse a changé la copie du client. Réponse perdue : l'état est redemandé au
-- serveur un peu plus tard.
-- derniere = { action, reponse } de la dernière action réussie (l'accueil affiche la dernière livraison)
local function agir(self, nom, ...)
	local reponse, change, perdue
	if self.remote then
		if self.enCours then
			return { ok = false, erreur = Session.OCCUPE, passager = true }
		end
		self.enCours = true
		reponse, change, perdue = appeler(self, nom, ...)
		self.enCours = false
	else
		reponse = self.etat[nom](self.etat, ...)
	end
	local action = reponse.ok and nom ~= "etat"
	if action then
		self.derniere = { action = nom, reponse = reponse }
	end
	if action or change then
		prevenir(self)
	end
	if perdue and nom ~= "etat" and not self.resynchro then
		self.resynchro = true
		task.delay(Session.RESYNCHRO, function()
			self.resynchro = false
			self:actualiser()
		end)
	end
	return reponse
end

-- Reprend l'état du serveur (à l'arrivée, ou pour réparer une copie abîmée) ; prévient les écrans s'il a
-- changé
function Session:actualiser()
	if self.remote then
		return agir(self, "etat")
	end
	return { ok = true }
end

-- attente(actif) est appelée au début (vrai) et à la fin (faux) de chaque appel au serveur (indicateur)
function Session:surAttente(f)
	self.attente = f
end
```

L'ancienne fonction `agir` est remplacée par celle écrite juste au-dessus. Dans `src/client/Atelier/Session.luau`, supprimer (avec la ligne vide qui suit) :

```lua
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
```

- [ ] **Step 5: Lancer les tests**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT"`
Expected:
```
Unitaires : 105019 vérifications
TOUT EST VERT : 317 vérifications
```

- [ ] **Step 6: Commit**

```bash
git add src/shared/EtatAtelier.luau src/client/Atelier/Session.luau tests/unitaires/39_session_resynchro.luau tests/unitaires/29_session_distante.luau tests/unitaires/32_session_attente.luau
git commit -m "Session : attente signalée, état des refus rechargé, resynchronisation après une réponse perdue

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 3: L'interface : « Un instant… » et refus passagers

**Files:**
- Modify: `src/client/Atelier/init.client.luau`
- Modify: `src/client/Atelier/EcranAccueil.luau`, `EcranAchat.luau`, `EcranCarnet.luau`, `EcranCouture.luau`, `EcranDecorations.luau`, `EcranDecoupe.luau`, `EcranEpinglage.luau`, `EcranPresentation.luau`, `EcranRefus.luau`
- Modify: `tests/scenario.luau`

**Interfaces:**
- Consumes: `Session:surAttente`, `Session.OCCUPE`, `r.passager` (tâche 2).
- Produces:
  - `ctx.refus(r)` pour les écrans : `r.erreur` en rouge, ou en gris (`UiKit.COULEURS.texteDoux`) si `r.passager`.
  - Le message « Un instant… » en gris (`fenetre.Message`) quand l'attente dure plus de 0,3 s.

- [ ] **Step 1: Écrire les tests**

Dans `tests/scenario.luau`, remplacer :

```lua
cliquer("Clochette")
verifier(M.dernierAppel ~= nil and M.dernierAppel.action == "nouvelleCommande" and serveur:atelier(joueur).etat.etape == "carnet", "la commande passe par le serveur, qui fait foi")
```

par :

```lua
-- Un serveur lent (0,5 s) : au-delà de 0,3 s, « Un instant… » en gris sous la fenêtre, jusqu'à la réponse ;
-- un message déjà affiché (l'avertissement de la sauvegarde) n'est pas remplacé
local GRIS = Color3.fromRGB(130, 100, 115)
local remoteAtelier = RS.Atelier
local brancheServeur = remoteAtelier.OnServerInvoke
local pendantAttente
local function serveurLent(...)
	M.avancer(0.5)
	pendantAttente = { visible = fenetre.Message.Visible, texte = fenetre.Message.Text, couleur = fenetre.Message.TextColor3 }
	return brancheServeur(...)
end
remoteAtelier.OnServerInvoke = serveurLent
cliquer("Clochette")
remoteAtelier.OnServerInvoke = brancheServeur
verifier(M.dernierAppel ~= nil and M.dernierAppel.action == "nouvelleCommande" and serveur:atelier(joueur).etat.etape == "carnet", "la commande passe par le serveur, qui fait foi")
verifier(pendantAttente ~= nil and pendantAttente.visible and string.find(pendantAttente.texte, "sauvegardée", 1, true) ~= nil, "serveur lent : l'avertissement affiché n'est pas remplacé")
```

Dans `tests/scenario.luau`, remplacer :

```lua
cliquer("Valider")
verifier(titre() == "1. Carnet de croquis" and fenetre.Message.Visible, "valider sans tissu : message d'erreur")
```

par :

```lua
M.avancer(8)
verifier(not fenetre.Message.Visible, "l'avertissement de la sauvegarde s'est effacé")
pendantAttente = nil
remoteAtelier.OnServerInvoke = serveurLent
cliquer("Valider")
remoteAtelier.OnServerInvoke = brancheServeur
verifier(pendantAttente ~= nil and pendantAttente.visible and pendantAttente.texte == "Un instant…" and pendantAttente.couleur == GRIS, "serveur lent : « Un instant… » en gris pendant l'attente")
verifier(titre() == "1. Carnet de croquis" and fenetre.Message.Visible and fenetre.Message.Text ~= "Un instant…" and fenetre.Message.TextColor3 ~= GRIS, "valider sans tissu : message d'erreur (en rouge), à la place de l'indicateur")
```

Dans `tests/scenario.luau`, remplacer :

```lua
coudre(60, 400)
cliquer("PieceSuivante")
verifier(cousues() == 1, "première pièce cousue")
```

par :

```lua
coudre(60, 400)
-- Serveur injoignable au moment de rendre la pièce : elle reste finie (rien à recoudre), message en gris
remoteAtelier.OnServerInvoke = function()
	error("coupure simulée")
end
cliquer("PieceSuivante")
remoteAtelier.OnServerInvoke = brancheServeur
verifier(cousues() == 0 and panneauC.PieceSuivante.Visible and panneauC.Note.Text:match("^Pièce finie") ~= nil, "serveur injoignable : la pièce reste finie, à rendre de nouveau")
verifier(fenetre.Message.Visible and fenetre.Message.Text == "Le serveur ne répond pas. Réessaie." and fenetre.Message.TextColor3 == GRIS, "refus passager : message en gris")
cliquer("PieceSuivante")
verifier(cousues() == 1, "première pièce cousue")
```

- [ ] **Step 2: Lancer les tests, vérifier l'échec**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT|attempt" | head -3`
Expected: échec : une ligne qui finit par `ÉCHEC : serveur lent : « Un instant… » en gris pendant l'attente`

- [ ] **Step 3: L'indicateur et `ctx.refus`**

Dans `src/client/Atelier/init.client.luau`, remplacer :

```lua
	task.delay(duree or 3, function()
		if moi == jeton then
			message.Visible = false
		end
	end)
end
```

par :

```lua
	task.delay(duree or 3, function()
		if moi == jeton then
			message.Visible = false
		end
	end)
end
-- Refus d'une action : en rouge ; un refus passager (serveur occupé ou injoignable) en gris, sans alarmer
local function refus(r)
	afficherMessage(r.erreur, if r.passager then C.texteDoux else C.erreur)
end
-- Attente du serveur : au-delà de 0,3 s, « Un instant… » en gris sous la fenêtre, jusqu'à la réponse (un
-- message déjà affiché reste)
local DELAI_ATTENTE = 0.3
local appel, jetonAttente = 0, nil
session:surAttente(function(actif)
	appel += 1
	local moi = appel
	if actif then
		task.delay(DELAI_ATTENTE, function()
			if moi == appel and not message.Visible then
				afficherMessage(Session.OCCUPE, C.texteDoux, 60)
				jetonAttente = jeton
			end
		end)
	elseif jetonAttente == jeton then
		message.Visible = false
		jetonAttente = nil
	end
end)
```

Dans `src/client/Atelier/init.client.luau`, remplacer :

```lua
		fermerEcran = ECRANS[etat.etape]({ session = session, contenu = contenu, fenetre = fenetre, scene = scene, message = afficherMessage, UiKit = UiKit })
```

par :

```lua
		fermerEcran = ECRANS[etat.etape]({ session = session, contenu = contenu, fenetre = fenetre, scene = scene, message = afficherMessage, refus = refus, UiKit = UiKit })
```

- [ ] **Step 4: Les écrans affichent les refus par `ctx.refus`**

Les 19 appels `ctx.message(r.erreur, C.erreur)` et celui de l'accueil (`ctx.message(r.erreur, UiKit.COULEURS.erreur)`) deviennent `ctx.refus(r)`. Appliquer :

```bash
sed -i -e 's/ctx\.message(r\.erreur, C\.erreur)/ctx.refus(r)/' -e 's/ctx\.message(r\.erreur, UiKit\.COULEURS\.erreur)/ctx.refus(r)/' src/client/Atelier/Ecran*.luau
grep -c "ctx.refus(r)" src/client/Atelier/Ecran*.luau | tr '\n' ' '
```

Expected : `EcranAccueil.luau:1 EcranAchat.luau:3 EcranCarnet.luau:1 EcranCouture.luau:2 EcranDecorations.luau:3 EcranDecoupe.luau:3 EcranEpinglage.luau:2 EcranPresentation.luau:3 EcranRefus.luau:2` (chemins précédés de `src/client/Atelier/`), soit 20.

- [ ] **Step 5: La couture garde la pièce finie sur un refus passager**

Dans `src/client/Atelier/EcranCouture.luau`, remplacer :

```lua
	-- On rend le relevé de la pièce finie ; la suivante arrive par l'avis de changement
	rendre = function()
		local r = session:rendreCouture(machine.idPiece, machine:releve())
		if not r.ok then
			ctx.refus(r)
			machine:decoudre()
			effacerPoints()
			rafraichir()
		end
	end
```

par :

```lua
	-- On rend le relevé de la pièce finie ; la suivante arrive par l'avis de changement. Refusé, la dernière
	-- couture est à refaire ; refus passager (serveur occupé ou injoignable) : la pièce reste finie, on la
	-- rendra de nouveau.
	rendre = function()
		local r = session:rendreCouture(machine.idPiece, machine:releve())
		if not r.ok then
			ctx.refus(r)
			if not r.passager then
				machine:decoudre()
				effacerPoints()
				rafraichir()
			end
		end
	end
```

- [ ] **Step 6: Lancer les tests**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT"`
Expected:
```
Unitaires : 105019 vérifications
TOUT EST VERT : 323 vérifications
```

- [ ] **Step 7: Commit**

```bash
git add src/client/Atelier tests/scenario.luau
git commit -m "Interface : « Un instant… » quand le serveur tarde, refus passagers en gris, la couture garde la pièce finie

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 4: Photo et livraison

**Files:**
- Modify: `src/client/Atelier/UiKit.luau` (`boutonConfirme`)
- Modify: `src/client/Atelier/EcranPresentation.luau`
- Modify: `tests/mock.luau` (capture muette qui garde son rappel, galerie en panne)
- Modify: `tests/scenario.luau`

**Interfaces:**
- Consumes: `ctx.refus` (tâche 3), `Scene:photo`, `Scene:finirPhoto`, `Scene:cadrerPhoto` (plan 3d).
- Produces:
  - `UiKit.boutonConfirme(props, auClic, principal?)` : `principal` donne l'allure d'un bouton principal (fond `accent`, texte blanc).
  - Faux Roblox : `M.rappelCapture` (rappel d'une capture muette) et `M.echecGalerie`.

- [ ] **Step 1: Écrire les tests**

Dans `tests/mock.luau`, remplacer :

```lua
-- M.echecCapture simule un refus de Roblox, M.captureMuette une capture qui ne répond jamais
function methodes.CaptureScreenshot(_, rappel)
	if M.echecCapture then
		error("CaptureScreenshot : refus simulé")
	end
	if M.captureMuette then
		return
	end
```

par :

```lua
-- M.echecCapture simule un refus de Roblox, M.captureMuette une capture qui ne répond pas (son rappel est
-- gardé dans M.rappelCapture, pour répondre plus tard)
function methodes.CaptureScreenshot(_, rappel)
	if M.echecCapture then
		error("CaptureScreenshot : refus simulé")
	end
	if M.captureMuette then
		M.rappelCapture = rappel
		return
	end
```

Dans `tests/mock.luau`, remplacer :

```lua
function methodes.PromptSaveCapturesToGallery(_, captures, rappel)
	M.galerie = captures
```

par :

```lua
-- M.echecGalerie simule une galerie indisponible
function methodes.PromptSaveCapturesToGallery(_, captures, rappel)
	if M.echecGalerie then
		error("PromptSaveCapturesToGallery : refus simulé")
	end
	M.galerie = captures
```

Dans `tests/scenario.luau`, remplacer :

```lua
verifier(gui.Atelier.Enabled and camera.CFrame == origineBoutique * ScenePoste.CAMERA and camera.FieldOfView == 70, "capture sans réponse : l'interface et la vue reviennent")
```

par :

```lua
verifier(gui.Atelier.Enabled and camera.CFrame == origineBoutique * ScenePoste.CAMERA and camera.FieldOfView == 70, "capture sans réponse : l'interface et la vue reviennent")
-- La réponse tardive d'une prise abandonnée ne termine pas la suivante
local tardive = M.rappelCapture
M.captureMuette = true
cliquer("PrendrePhoto")
M.captureMuette = nil
tardive("rbxtemp://tardive")
verifier(not gui.Atelier.Enabled and not fenetre.Contenu.Apercu.Visible, "réponse tardive d'une prise abandonnée : la prise en cours continue")
M.rappelCapture("rbxtemp://seconde")
verifier(gui.Atelier.Enabled and fenetre.Contenu.Apercu.Visible and fenetre.Contenu.Apercu.Image.Image == "rbxtemp://seconde", "la prise en cours se termine avec sa propre photo")
cliquer("FermerApercu")
-- Le minuteur d'une prise terminée ne coupe pas la suivante
cliquer("PrendrePhoto")
cliquer("FermerApercu")
M.captureMuette = true
cliquer("PrendrePhoto")
M.captureMuette = nil
M.avancer(1.1) -- le minuteur de la prise précédente (2 s) sonne
verifier(not gui.Atelier.Enabled, "le minuteur d'une prise terminée ne coupe pas la suivante")
M.avancer(1)
verifier(gui.Atelier.Enabled and camera.CFrame == origineBoutique * ScenePoste.CAMERA, "la prise sans réponse se termine à son propre minuteur")
```

Dans `tests/scenario.luau`, remplacer :

```lua
cliquer("EnregistrerPhoto")
verifier(M.galerie ~= nil and M.galerie[1] == apercu.Image.Image and fenetre.Message.Visible, "photo proposée à la galerie du joueur")
```

par :

```lua
cliquer("EnregistrerPhoto")
verifier(M.galerie ~= nil and M.galerie[1] == apercu.Image.Image and fenetre.Message.Visible, "photo proposée à la galerie du joueur")
M.echecGalerie = true
cliquer("EnregistrerPhoto")
M.echecGalerie = nil
verifier(fenetre.Message.Visible and fenetre.Message.Text == "La galerie n'est pas disponible pour le moment.", "galerie indisponible : message, sans erreur")
```

Dans `tests/scenario.luau`, remplacer :

```lua
cliquer("RetourDecorations")
verifier(scene:FindFirstChild("Fond") == nil and Lighting.ClockTime == heureDuJeu
```

par :

```lua
-- Fenêtre fermée pour se promener : décor, lumière et mannequin du jeu ; rouverte : réglages remis
cliquer("Fermer")
verifier(scene:FindFirstChild("Fond") == nil and Lighting.ClockTime == heureDuJeu and scene.Mannequin.Buste.Color ~= ScenePoste.MANNEQUINS.noir, "fenêtre fermée pendant la photo : décor, lumière et mannequin du jeu")
cliquer("OuvrirAtelier")
verifier(scene.Fond.Color == ScenePoste.DECORS.bleu and Lighting.ClockTime == ScenePoste.LUMIERES.soir.ClockTime and scene.Mannequin.Buste.Color == ScenePoste.MANNEQUINS.noir, "fenêtre rouverte : les réglages de la photo reviennent")
cliquer("RetourDecorations")
verifier(scene:FindFirstChild("Fond") == nil and Lighting.ClockTime == heureDuJeu
```

Dans `tests/scenario.luau`, remplacer :

```lua
cliquer("Presenter")
cliquer("Livrer")
verifier(titre() == "La cliente refuse la robe" 
```

par :

```lua
cliquer("Presenter")
-- « Livrer la robe » est loin de « Prendre la photo », et demande une confirmation
local prendre, livrer = boutonNomme("PrendrePhoto"), boutonNomme("Livrer")
verifier(livrer.Position.Y.Offset - (prendre.Position.Y.Offset + prendre.Size.Y.Offset) >= 16, "« Livrer la robe » à distance de « Prendre la photo »")
cliquer("Livrer")
verifier(titre() == "7. Photo et livraison" and livrer.Text == "Vraiment ? Touche encore", "livrer : confirmation demandée")
livrer.Activated:Fire() -- second appui d'un double clic (moins de 0,4 s) : ignoré
verifier(titre() == "7. Photo et livraison", "un double clic trop rapide ne livre pas")
cliquer("Livrer")
verifier(titre() == "La cliente refuse la robe" 
```

Dans `tests/scenario.luau`, remplacer :

```lua
local avantLivraison = argent()
cliquer("Livrer")
```

par :

```lua
local avantLivraison = argent()
cliquer("Livrer")
cliquer("Livrer")
```

- [ ] **Step 2: Lancer les tests, vérifier l'échec**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT|attempt" | head -3`
Expected: échec : une ligne qui finit par `ÉCHEC : réponse tardive d'une prise abandonnée : la prise en cours continue`

- [ ] **Step 3: Un bouton confirmé à l'allure d'un bouton principal**

Dans `src/client/Atelier/UiKit.luau`, remplacer :

```lua
-- Bouton d'une action qu'on ne peut pas annuler (recommencer la robe) : le premier appui demande
-- confirmation, un second appui (au moins 0,4 s après, dans les 3 s) agit ; sinon il revient à la normale.
UiKit.DELAI_CONFIRMATION = 3
UiKit.TEXTE_CONFIRMATION = "Vraiment ? Touche encore"
function UiKit.boutonConfirme(props, auClic)
	local b
	local texte = props.Text
	local jeton = 0
	local function normal()
		b.Text = texte
		b.BackgroundColor3 = UiKit.COULEURS.secondaire
		b.TextColor3 = UiKit.COULEURS.texte
	end
	b = UiKit.boutonDoux(props, function()
```

par :

```lua
-- Bouton d'une action qu'on ne peut pas annuler (recommencer, livrer la robe) : le premier appui demande
-- confirmation, un second appui (au moins 0,4 s après, dans les 3 s) agit ; sinon il revient à la normale.
-- principal (facultatif) : l'allure d'un bouton principal (fond de couleur) au lieu d'un bouton doux.
UiKit.DELAI_CONFIRMATION = 3
UiKit.TEXTE_CONFIRMATION = "Vraiment ? Touche encore"
function UiKit.boutonConfirme(props, auClic, principal)
	local b
	local texte = props.Text
	local jeton = 0
	local function normal()
		b.Text = texte
		b.BackgroundColor3 = if principal then UiKit.COULEURS.accent else UiKit.COULEURS.secondaire
		b.TextColor3 = if principal then Color3.new(1, 1, 1) else UiKit.COULEURS.texte
	end
	b = (if principal then UiKit.bouton else UiKit.boutonDoux)(props, function()
```

- [ ] **Step 4: L'écran de la photo**

Dans `src/client/Atelier/EcranPresentation.luau`, remplacer :

```lua
	UiKit.bouton({ Name = "EnregistrerPhoto", Text = "Enregistrer dans la galerie", TextSize = 16, Position = UDim2.fromOffset(0, 312), Size = UDim2.new(1, -6, 0, 42), ZIndex = 21, Parent = apercu }, function()
		CaptureService:PromptSaveCapturesToGallery({ image.Image }, function(resultats)
			if resultats and resultats[image.Image] then
				ctx.message("Photo enregistrée dans ta galerie.", C.ok)
			end
		end)
	end, 0.4)
```

par :

```lua
	UiKit.bouton({ Name = "EnregistrerPhoto", Text = "Enregistrer dans la galerie", TextSize = 16, Position = UDim2.fromOffset(0, 312), Size = UDim2.new(1, -6, 0, 42), ZIndex = 21, Parent = apercu }, function()
		local photo = image.Image
		local ok = pcall(function()
			CaptureService:PromptSaveCapturesToGallery({ photo }, function(resultats)
				if resultats and resultats[photo] then
					ctx.message("Photo enregistrée dans ta galerie.", C.ok)
				end
			end)
		end)
		if not ok then
			ctx.message("La galerie n'est pas disponible pour le moment.", C.erreur)
		end
	end, 0.4)
```

Dans `src/client/Atelier/EcranPresentation.luau`, remplacer :

```lua
	-- Prise de vue : l'interface est cachée, la vue centrée sur la robe, le temps de la capture.
	-- Si Roblox refuse la capture ou ne répond pas, l'interface revient quand même.
	local interface = ctx.fenetre.Parent
	local enCours = false
	local function retablir()
		if enCours then
			enCours = false
			interface.Enabled = true
			scene:cadrerPhoto(false)
		end
	end
	UiKit.bouton({ Name = "PrendrePhoto", Text = "Prendre la photo", TextSize = 16, Position = UDim2.fromOffset(0, 252), Size = UDim2.new(1, -6, 0, 40), Parent = contenu }, function()
		if enCours then
			return
		end
		enCours = true
		scene:cadrerPhoto(true)
		interface.Enabled = false
		task.delay(scene.ATTENTE_CAPTURE, retablir)
		local ok = pcall(function()
			CaptureService:CaptureScreenshot(function(capture)
				retablir()
				image.Image = capture
				apercu.Visible = true
			end)
		end)
		if not ok then
			retablir()
			ctx.message("La photo n'a pas pu être prise.", C.erreur)
		end
	end, 0.4)

	UiKit.bouton({ Name = "Livrer", Text = "Livrer la robe", Position = UDim2.fromOffset(0, 300), Size = UDim2.new(1, -6, 0, 44), Parent = contenu }, function()
		local r = session:livrer()
		if not r.ok then
			ctx.refus(r)
		end
	end, 0.4)
	UiKit.boutonDoux({ Name = "RetourDecorations", Text = "Retour aux décorations", TextSize = 14, Position = UDim2.fromOffset(0, 352), Size = UDim2.new(1, -6, 0, 32), Parent = contenu }, function()
```

par :

```lua
	-- Prise de vue : l'interface est cachée, la vue centrée sur la robe, le temps de la capture.
	-- Si Roblox refuse la capture ou ne répond pas, l'interface revient quand même. Chaque prise a son
	-- numéro : le minuteur ou la réponse tardive d'une prise terminée ne touchent pas à la suivante.
	local interface = ctx.fenetre.Parent
	local prises, enCours = 0, nil -- enCours : numéro de la prise en cours
	local function retablir(numero)
		if enCours == numero then
			enCours = nil
			interface.Enabled = true
			scene:cadrerPhoto(false)
		end
	end
	UiKit.bouton({ Name = "PrendrePhoto", Text = "Prendre la photo", TextSize = 16, Position = UDim2.fromOffset(0, 252), Size = UDim2.new(1, -6, 0, 40), Parent = contenu }, function()
		if enCours then
			return
		end
		prises += 1
		local numero = prises
		enCours = numero
		scene:cadrerPhoto(true)
		interface.Enabled = false
		task.delay(scene.ATTENTE_CAPTURE, retablir, numero)
		local ok = pcall(function()
			CaptureService:CaptureScreenshot(function(capture)
				if enCours ~= numero then
					return -- prise abandonnée (sans réponse à temps)
				end
				retablir(numero)
				image.Image = capture
				apercu.Visible = true
			end)
		end)
		if not ok then
			retablir(numero)
			ctx.message("La photo n'a pas pu être prise.", C.erreur)
		end
	end, 0.4)

	-- Livrer met fin à la commande : loin de « Prendre la photo », et confirmé par un second appui
	UiKit.boutonConfirme({ Name = "Livrer", Text = "Livrer la robe", Position = UDim2.fromOffset(0, 312), Size = UDim2.new(1, -6, 0, 44), Parent = contenu }, function()
		local r = session:livrer()
		if not r.ok then
			ctx.refus(r)
		end
	end, true)
	UiKit.boutonDoux({ Name = "RetourDecorations", Text = "Retour aux décorations", TextSize = 14, Position = UDim2.fromOffset(0, 364), Size = UDim2.new(1, -6, 0, 32), Parent = contenu }, function()
```

Dans `src/client/Atelier/EcranPresentation.luau`, remplacer :

```lua
	rafraichir()
	return function() end
end
```

par :

```lua
	-- Fenêtre fermée (le joueur se promène) : décor, lumière et mannequin du jeu ; rouverte : réglages remis
	local connexion = ctx.fenetre:GetPropertyChangedSignal("Visible"):Connect(function()
		if ctx.fenetre.Visible then
			rafraichir()
		else
			scene:finirPhoto()
		end
	end)
	rafraichir()
	return function()
		connexion:Disconnect()
	end
end
```

- [ ] **Step 5: Lancer les tests**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT"`
Expected:
```
Unitaires : 105019 vérifications
TOUT EST VERT : 345 vérifications
```

- [ ] **Step 6: Commit**

```bash
git add src/client/Atelier/UiKit.luau src/client/Atelier/EcranPresentation.luau tests/mock.luau tests/scenario.luau
git commit -m "Photo : une prise à la fois, « Livrer » confirmé et éloigné, fenêtre fermée sans décor, galerie protégée

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 5: La sauvegarde : une écriture à la fois, taille bornée

**Files:**
- Modify: `tests/gen_api.py`, `tests/mock.luau` (`HttpService:JSONEncode`)
- Create: `tests/unitaires/40_sauvegarde_serie.luau`
- Modify: `src/server/Sauvegarde.luau`
- Modify: `src/server/Commande.luau` (`nouvelle`, `arrivee`, `enregistrer`, `fermer`)

**Interfaces:**
- Consumes:
  - `Commande:traiter` de la tâche 1 ;
  - `Sauvegarde:charger`, `Sauvegarde:enregistrer`, `Sauvegarde.depuisEtat` (plan 4b).
- Produces:
  - `Sauvegarde.TAILLE_MAX = 3500000`.
  - Champs de `Commande` :
    - `ecritures` : `[UserId] = true` pendant une écriture ;
    - `chargements` : `[joueur] = true` pendant une lecture ;
    - `ferme` : vrai une fois `fermer` appelé.

- [ ] **Step 1: Le faux Roblox gagne `HttpService:JSONEncode`**

Dans `tests/gen_api.py`, remplacer :

```python
"StarterGui","Lighting","CaptureService"}
```

par :

```python
"StarterGui","Lighting","CaptureService","HttpService"}
```

Dans `tests/mock.luau`, remplacer :

```lua
		"Lighting",
		"CaptureService",
	}) do
```

par :

```lua
		"Lighting",
		"CaptureService",
		"HttpService",
	}) do
```

Dans `tests/mock.luau`, remplacer :

```lua
-- Sans M.magasins, le DataStore échoue comme dans Studio sans accès aux API ; avec, M.magasins[nom]
```

par :

```lua
-- HttpService:JSONEncode : une table aux clés 1..n devient une liste, les autres tables des objets
local function json(v)
	local t = type(v)
	if t == "table" then
		local n, liste = #v, true
		for k in pairs(v) do
			if type(k) ~= "number" or k < 1 or k > n or k % 1 ~= 0 then
				liste = false
				break
			end
		end
		local morceaux = {}
		if liste then
			for i = 1, n do
				morceaux[i] = json(v[i])
			end
			return "[" .. table.concat(morceaux, ",") .. "]"
		end
		for k, x in pairs(v) do
			table.insert(morceaux, json(tostring(k)) .. ":" .. json(x))
		end
		return "{" .. table.concat(morceaux, ",") .. "}"
	elseif t == "string" then
		-- guillemets, barres obliques inverses (caractère 92) et caractères de contrôle : en \uXXXX
		local oblique = string.char(92)
		return '"' .. (v:gsub('[%c"' .. oblique .. "]", function(c)
			return oblique .. ("u%04x"):format(c:byte())
		end)) .. '"'
	elseif t == "number" then
		return ("%.17g"):format(v)
	elseif t == "boolean" then
		return tostring(v)
	end
	error("JSONEncode : valeur impossible à encoder (" .. t .. ")")
end
function methodes.JSONEncode(_, v)
	return json(v)
end
-- Sans M.magasins, le DataStore échoue comme dans Studio sans accès aux API ; avec, M.magasins[nom]
```

- [ ] **Step 2: Écrire les tests**

Créer `tests/unitaires/40_sauvegarde_serie.luau` :

```lua
local Commande = U.module("Commande")
local Sauvegarde = U.module("Sauvegarde")
local EtatAtelier = U.module("EtatAtelier")
local HttpService = M.services.HttpService

---------------------------------------------------------------------------
-- Une partie trop lourde pour le DataStore perd ses plus anciennes robes, jusqu'à tenir
---------------------------------------------------------------------------
local lourd = EtatAtelier.nouveau()
for i = 1, EtatAtelier.ROBES_GARDEES do
	lourd.robes[i] = { numero = i, bourrage = string.rep("x", 1000) }
end
local limite = Sauvegarde.TAILLE_MAX
Sauvegarde.TAILLE_MAX = 4500
local partie = Sauvegarde.depuisEtat(lourd)
Sauvegarde.TAILLE_MAX = limite
U.verifier(#HttpService:JSONEncode(partie) <= 4500 and #partie.recettes >= 1 and #partie.recettes < EtatAtelier.ROBES_GARDEES, "partie trop lourde : " .. #partie.recettes .. " robes gardées, sous la limite")
U.verifier(partie.recettes[1].numero == 1 and partie.recettes[#partie.recettes].numero == #partie.recettes, "les plus récentes sont gardées")
U.verifier(#Sauvegarde.depuisEtat(lourd).recettes == EtatAtelier.ROBES_GARDEES, "sous la limite : toutes les robes")
U.verifier(limite <= 4000000, "la limite laisse de la place sous les 4 Mo d'une clé du DataStore")

---------------------------------------------------------------------------
-- Un serveur, son DataStore ; attendre fait passer le temps (et laisse le test agir pendant l'attente)
---------------------------------------------------------------------------
local courant = Commande.courante
local magasin = M.nouveauMagasin()
local temps, attentes = 3000000, 0
local pendant = nil
local function attendre(s)
	attentes += 1
	temps += s
	if pendant then
		pendant()
	end
end
local function horloge()
	return temps
end
local sauvegarde = Sauvegarde.nouvelle({ magasin = magasin, ancien = M.nouveauMagasin(), jobId = "S", horloge = horloge, attendre = attendre })
local serveur = Commande.nouvelle({ sauvegarde = sauvegarde, horloge = horloge, attendre = attendre })
local function joueurNumero(nom, userId)
	local j = M.nouveauJoueur(nom)
	rawget(j, "__props").UserId = userId
	return j
end
local function cle(j)
	return "joueur_" .. j.UserId
end

---------------------------------------------------------------------------
-- Une écriture à la fois par joueur : la suivante attend la fin de la précédente
---------------------------------------------------------------------------
local serie = joueurNumero("Serie", 701)
serveur:arrivee(serie)
serveur.ecritures[serie.UserId] = true -- la sauvegarde régulière est en train d'écrire
local ecrituresAvant = magasin.ecritures
local rienPendant = true
attentes = 0
pendant = function()
	rienPendant = rienPendant and magasin.ecritures == ecrituresAvant
	if attentes == 2 then
		serveur:atelier(serie).etat.argent = 777 -- le joueur a joué entre-temps
		serveur.ecritures[serie.UserId] = nil -- l'écriture en cours se termine
	end
end
local statut = serveur:enregistrer(serie, false)
pendant = nil
U.verifier(rienPendant and attentes == 2, "rien n'est écrit tant que l'écriture précédente n'est pas finie")
U.verifier(statut == "ok" and magasin.donnees[cle(serie)].argent == 777 and serveur.ecritures[serie.UserId] == nil, "puis la partie est écrite, avec l'état du moment ; la place est libre")
-- Une erreur en préparant la partie ne bloque pas les écritures suivantes
local vraie = Sauvegarde.depuisEtat
Sauvegarde.depuisEtat = function()
	error("panne simulée")
end
local sansErreur, statutPanne = pcall(serveur.enregistrer, serveur, serie, false)
Sauvegarde.depuisEtat = vraie
U.verifier(sansErreur and statutPanne == "echec" and serveur.ecritures[serie.UserId] == nil, "erreur en préparant la partie : échec, sans bloquer les écritures suivantes")

---------------------------------------------------------------------------
-- De retour sur ce serveur avant la fin de l'écriture de son départ : l'arrivée l'attend
---------------------------------------------------------------------------
serveur:depart(serie)
local retour = joueurNumero("Serie", 701) -- nouvel objet Player, même compte
serveur.ecritures[retour.UserId] = true -- l'écriture du départ n'est pas finie
local lectures = magasin.ecritures
local luPendant = false
attentes = 0
pendant = function()
	luPendant = luPendant or magasin.ecritures ~= lectures
	if attentes == 3 then
		magasin.donnees[cle(retour)].argent = 888 -- l'écriture du départ arrive
		serveur.ecritures[retour.UserId] = nil
	end
end
serveur:arrivee(retour)
pendant = nil
U.verifier(not luPendant and attentes == 3, "la partie n'est pas lue pendant l'écriture du départ")
U.verifier(serveur:atelier(retour).etat.argent == 888, "retour : la partie lue est celle écrite au départ")

---------------------------------------------------------------------------
-- Lecture d'une partie tenue un moment par un autre serveur : le joueur est « en chargement »
---------------------------------------------------------------------------
local lent = joueurNumero("Lent", 703)
magasin.donnees[cle(lent)] = { version = 2, argent = 55, stock = {}, debloques = {}, recettes = {}, verrou = { jobId = "AUTRE", t = temps } }
local pendantLecture = false
pendant = function()
	pendantLecture = pendantLecture or serveur.chargements[lent] == true
end
serveur:arrivee(lent)
pendant = nil
U.verifier(pendantLecture and serveur.chargements[lent] == nil and serveur:atelier(lent).etat.argent == 55, "lecture notée en cours, puis effacée une fois la partie lue")

---------------------------------------------------------------------------
-- Arrêt du serveur pendant la lecture d'une partie : on l'attend ; lue après l'arrêt, elle est rendue
---------------------------------------------------------------------------
local tardif = joueurNumero("Tardif", 702)
serveur.chargements[tardif] = true -- sa partie est en cours de lecture
attentes = 0
pendant = function()
	if attentes == 4 then
		serveur.chargements[tardif] = nil -- la lecture se termine
	end
end
serveur:fermer()
pendant = nil
U.verifier(attentes == 4, "arrêt : on attend la lecture en cours (" .. attentes .. " attentes)")
U.verifier(magasin.donnees[cle(retour)].verrou.t == 0 and magasin.donnees[cle(lent)].verrou.t == 0, "arrêt : les parties des joueurs présents sont écrites et rendues")
serveur:arrivee(tardif)
U.verifier(serveur:atelier(tardif) == nil and magasin.donnees[cle(tardif)] ~= nil and magasin.donnees[cle(tardif)].verrou.t == 0, "lue après l'arrêt : la partie est rendue aussitôt, sans atelier")
U.verifier(serveur.chargements[tardif] == nil, "plus de lecture en cours")
Commande.courante = courant
```

- [ ] **Step 3: Lancer les tests, vérifier l'échec**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT|attempt" | head -3`
Expected: échec : une ligne qui finit par `ÉCHEC : partie trop lourde : 10 robes gardées, sous la limite`

- [ ] **Step 4: Une partie bornée**

Dans `src/server/Sauvegarde.luau`, remplacer :

```lua
local DataStoreService = game:GetService("DataStoreService")
```

par :

```lua
local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
```

Dans `src/server/Sauvegarde.luau`, remplacer :

```lua
Sauvegarde.ESSAIS_LECTURE = 3 -- une panne passagère du DataStore à la lecture est réessayée
```

par :

```lua
Sauvegarde.ESSAIS_LECTURE = 3 -- une panne passagère du DataStore à la lecture est réessayée
Sauvegarde.TAILLE_MAX = 3500000 -- caractères (JSON) : sous les 4 Mo d'une clé du DataStore, verrou compris
```

Dans `src/server/Sauvegarde.luau`, remplacer :

```lua
-- La partie d'un état de l'atelier (debloques : ceux de la partie chargée, gardés tels quels)
function Sauvegarde.depuisEtat(etat, debloques)
```

par :

```lua
-- La partie d'un état de l'atelier (debloques : ceux de la partie chargée, gardés tels quels). Trop
-- lourde pour le DataStore (des centaines de garnitures sur chaque robe), elle perd ses plus anciennes
-- robes jusqu'à tenir.
function Sauvegarde.depuisEtat(etat, debloques)
```

Dans `src/server/Sauvegarde.luau`, remplacer :

```lua
		for _, champ in ipairs(EN_COURS) do
			partie.enCours[champ] = d[champ]
		end
	end
	return partie
end
```

par :

```lua
		for _, champ in ipairs(EN_COURS) do
			partie.enCours[champ] = d[champ]
		end
	end
	while #partie.recettes > 0 and #HttpService:JSONEncode(partie) > Sauvegarde.TAILLE_MAX do
		table.remove(partie.recettes)
	end
	return partie
end
```

- [ ] **Step 5: Écritures en série, lectures suivies, arrêt qui les attend**

Dans `src/server/Commande.luau`, remplacer :

```lua
		ateliers = {}, -- [joueur] = { etat = EtatAtelier, rng = Random, sauvable = bool, debloques = table? }
```

par :

```lua
		ateliers = {}, -- [joueur] = { etat = EtatAtelier, rng = Random, sauvable = bool, debloques = table? }
		ecritures = {}, -- [UserId] = vrai pendant l'écriture de sa partie (une à la fois par joueur)
		chargements = {}, -- [joueur] = vrai pendant la lecture de sa partie
		ferme = false, -- vrai une fois le serveur en train de s'arrêter
```

Dans `src/server/Commande.luau`, remplacer :

```lua
-- Arrivée d'un joueur : lit sa partie (peut attendre, jusqu'à 15 s si un autre serveur la tient). Si la
-- lecture échoue, il joue une partie neuve qui ne sera jamais écrite (sa vraie partie reste intacte).
function Commande:arrivee(joueur)
	if not self.sauvegarde then
		self:atelier(joueur)
		self:exposer(joueur)
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
```

par :

```lua
-- Arrivée d'un joueur : lit sa partie (peut attendre, jusqu'à 15 s si un autre serveur la tient). Si la
-- lecture échoue, il joue une partie neuve qui ne sera jamais écrite (sa vraie partie reste intacte).
-- De retour sur ce serveur avant la fin de l'écriture de son départ, on attend qu'elle soit faite.
function Commande:arrivee(joueur)
	if not self.sauvegarde then
		self:atelier(joueur)
		self:exposer(joueur)
		return
	end
	while self.ecritures[joueur.UserId] do
		self.attendre(0.5)
	end
	self.chargements[joueur] = true
	local partie, statut = self.sauvegarde:charger(joueur.UserId)
	if joueur.Parent == nil or self.ferme then
		-- parti pendant la lecture, ou serveur qui s'arrête : sa partie est rendue tout de suite
		if statut == "ok" then
			self.sauvegarde:enregistrer(joueur.UserId, partie, true)
		end
		self.chargements[joueur] = nil
		return
	end
	self.chargements[joueur] = nil
```

Dans `src/server/Commande.luau`, remplacer :

```lua
-- Écrit la partie d'un joueur (et rend son verrou, si liberer), en « essais » tentatives (1 par défaut ;
-- la sauvegarde régulière réessaie d'elle-même 60 s plus tard). Renvoie le statut de la sauvegarde, ou nil
-- si sa partie n'est pas à écrire. Une partie prise par un autre serveur n'est plus jamais écrite d'ici.
function Commande:enregistrer(joueur, liberer, essais)
	local a = self.ateliers[joueur]
	if not self.sauvegarde or not a or not a.sauvable then
		return nil
	end
	local partie = Sauvegarde.depuisEtat(a.etat, a.debloques)
	local statut
	for essai = 1, essais or 1 do
		statut = self.sauvegarde:enregistrer(joueur.UserId, partie, liberer)
		if statut ~= "echec" or essai == (essais or 1) then
			break
		end
		self.attendre(1)
	end
	if statut == "perdu" then
```

par :

```lua
-- Écrit la partie d'un joueur (et rend son verrou, si liberer), en « essais » tentatives (1 par défaut ;
-- la sauvegarde régulière réessaie d'elle-même 60 s plus tard). Renvoie le statut de la sauvegarde, ou nil
-- si sa partie n'est pas à écrire. Une partie prise par un autre serveur n'est plus jamais écrite d'ici.
-- Une écriture à la fois par joueur : la suivante attend la fin de la précédente, puis écrit l'état du
-- moment (la sauvegarde régulière et celle du départ ne se croisent pas).
function Commande:enregistrer(joueur, liberer, essais)
	local a = self.ateliers[joueur]
	if not self.sauvegarde or not a or not a.sauvable then
		return nil
	end
	local id = joueur.UserId
	while self.ecritures[id] do
		self.attendre(0.5)
	end
	if not a.sauvable then
		return nil -- partie prise par un autre serveur pendant l'attente
	end
	self.ecritures[id] = true
	local ok, statut = pcall(function()
		local partie = Sauvegarde.depuisEtat(a.etat, a.debloques)
		local s
		for essai = 1, essais or 1 do
			s = self.sauvegarde:enregistrer(id, partie, liberer)
			if s ~= "echec" or essai == (essais or 1) then
				break
			end
			self.attendre(1)
		end
		return s
	end)
	self.ecritures[id] = nil
	if not ok then
		warn(("[Atelier] %s : erreur en préparant la sauvegarde : %s"):format(joueur.Name, tostring(statut)))
		statut = "echec"
	end
	if statut == "perdu" then
```

Dans `src/server/Commande.luau`, remplacer :

```lua
-- Arrêt du serveur : toutes les parties écrites en même temps, verrous rendus (25 s au plus)
function Commande:fermer()
	local restantes = 0
```

par :

```lua
-- Arrêt du serveur : toutes les parties écrites en même temps, verrous rendus (25 s au plus). Les parties
-- en cours de lecture sont attendues (rendues aussitôt lues).
function Commande:fermer()
	self.ferme = true
	local restantes = 0
```

Dans `src/server/Commande.luau`, remplacer :

```lua
	while restantes > 0 and self.horloge() - debut < Commande.FERMETURE_MAX do
```

par :

```lua
	while (restantes > 0 or next(self.chargements) ~= nil) and self.horloge() - debut < Commande.FERMETURE_MAX do
```

- [ ] **Step 6: Lancer les tests**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT"`
Expected:
```
Unitaires : 105033 vérifications
TOUT EST VERT : 345 vérifications
```

- [ ] **Step 7: Commit**

```bash
git add tests/gen_api.py tests/mock.luau tests/unitaires/40_sauvegarde_serie.luau src/server/Sauvegarde.luau src/server/Commande.luau
git commit -m "Sauvegarde : une écriture à la fois par joueur, arrivée et arrêt qui attendent, partie bornée sous 4 Mo

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 6: Boutique en panne, pièce ratée, images oubliées

**Files:**
- Modify: `src/server/Boutiques.luau` (`attribuer`)
- Modify: `src/client/Atelier/Scene.luau` (`synchroniser`)
- Modify: `src/client/Atelier/Vignettes.luau`
- Modify: `src/client/Atelier/init.client.luau`
- Modify: `tests/unitaires/20_scene.luau`, `tests/unitaires/34_boutiques.luau`, `tests/scenario.luau`

**Interfaces:**
- Consumes: `Boutiques:attribuer(joueur)` (plan 4c), `Vignettes.piece(idPiece, idTissu, placement, plafond)` (plan 3a).
- Produces: `Vignettes.oublierPieces()` (vide le cache des images de pièces ; motifs et silhouettes gardés).

- [ ] **Step 1: Écrire les tests**

Dans `tests/unitaires/20_scene.luau`, remplacer :

```lua
U.verifier(Vignettes.piece("manche_ballon", "soie_rose_fleurs", { x = 4, y = 2, angle = 0 }) == nil, "mémoire des images pleine : pas d'aperçu, sans erreur")
M.budget.images = 64
```

par :

```lua
U.verifier(Vignettes.piece("manche_ballon", "soie_rose_fleurs", { x = 4, y = 2, angle = 0 }) == nil, "mémoire des images pleine : pas d'aperçu, sans erreur")
M.budget.images = 64
-- Commande finie : les images des pièces découpées sont oubliées (mémoire), pas celles des tissus
local motifSoie = Vignettes.motif("soie_rose_fleurs")
Vignettes.oublierPieces()
local refait = Vignettes.piece("manche_ballon", "soie_rose_fleurs", { x = 3, y = 2, angle = 0 })
U.verifier(refait ~= nil and refait ~= apercu, "images des pièces oubliées : refaites à la demande")
U.verifier(motifSoie ~= nil and Vignettes.motif("soie_rose_fleurs") == motifSoie, "les motifs des tissus restent en cache")
```

Dans `tests/unitaires/20_scene.luau`, remplacer :

```lua
U.verifier(#scene2.robe:GetChildren() == 0 and scene2.dossier:FindFirstChild("Mannequin") ~= nil, "mémoire pleine : pièce absente, scène intacte")
```

par :

```lua
U.verifier(#scene2.robe:GetChildren() == 0 and scene2.dossier:FindFirstChild("Mannequin") ~= nil, "mémoire pleine : pièce absente, scène intacte")
scene2:synchroniser(etat2)
U.verifier(scene2.robe:FindFirstChild("Piece_" .. PIECES[1] .. "_unique") ~= nil, "mémoire libérée : la pièce ratée est construite à la synchronisation suivante")
```

Dans `tests/unitaires/34_boutiques.luau`, remplacer :

```lua
rue:liberer(joueurNumero("Inconnue", 799)) -- sans boutique : sans effet, sans erreur
monde:Destroy()
```

par :

```lua
rue:liberer(joueurNumero("Inconnue", 799)) -- sans boutique : sans effet, sans erreur

---------------------------------------------------------------------------
-- Construction en panne : le joueur joue quand même (hors de la rue), l'emplacement reste libre
---------------------------------------------------------------------------
rue:liberer(joueurs[4])
local vraie = Boutique.emplacement
Boutique.emplacement = function()
	error("panne simulée")
end
local malchanceux = joueurNumero("Malchanceux", 750)
local sansErreur, indice = pcall(rue.attribuer, rue, malchanceux)
Boutique.emplacement = vraie
U.verifier(sansErreur and indice == nil and malchanceux:GetAttribute("Boutique") == 0, "construction en panne : sans erreur, pas de boutique (attribut 0 : le client n'attend pas)")
U.verifier(monde.Rue:FindFirstChild("Boutique_4") == nil and monde.Vitrines:FindFirstChild("Vitrine_4") == nil, "construction en panne : rien de laissé dans la rue")
U.verifier(rue:attribuer(joueurNumero("Suivante", 751)) == 4, "l'emplacement resté libre sert au joueur suivant")
monde:Destroy()
```

Dans `tests/scenario.luau`, remplacer :

```lua
local avantLivraison = argent()
cliquer("Livrer")
cliquer("Livrer")
```

par :

```lua
local avantLivraison = argent()
-- Image d'une pièce découpée (en cache depuis la couture), à comparer après la livraison
local Vignettes = requireModule(scriptClient.Vignettes)
local etatClient = requireModule(scriptClient.Session).courante.etat
local idVignette = "corsage_v_devant"
local tissuVignette, placeVignette = etatClient.tissus[idVignette], table.clone(etatClient.coupees[idVignette])
local imageAvant = Vignettes.piece(idVignette, tissuVignette, placeVignette, 256)
cliquer("Livrer")
cliquer("Livrer")
```

Dans `tests/scenario.luau`, remplacer :

```lua
verifier(texte("La cliente est ravie") ~= nil, "l'accueil annonce la paie")
```

par :

```lua
verifier(texte("La cliente est ravie") ~= nil, "l'accueil annonce la paie")
verifier(imageAvant ~= nil and Vignettes.piece(idVignette, tissuVignette, placeVignette, 256) ~= imageAvant, "commande finie : les images des pièces découpées sont oubliées (mémoire)")
```

- [ ] **Step 2: Lancer les tests, vérifier l'échec**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT|attempt" | head -3`
Expected: échec : une ligne qui finit par `attempt to call a nil value` (`Vignettes.oublierPieces` n'existe pas encore)

- [ ] **Step 3: Écrire le code**

Dans `src/client/Atelier/Vignettes.luau`, remplacer :

```lua
		return Pixels.decouper(buf, l, h, idPiece), l, h
	end)
end
```

par :

```lua
		return Pixels.decouper(buf, l, h, idPiece), l, h
	end)
end

-- Oublie les images des pièces découpées (commande finie ou recommencée) : elles occupent la mémoire des
-- images et ne resserviront pas. Les motifs et les silhouettes restent.
function Vignettes.oublierPieces()
	for _, t in ipairs({ cache, echecs }) do
		for cle in pairs(t) do
			if string.sub(cle, 1, 6) == "piece:" then
				t[cle] = nil
			end
		end
	end
end
```

Dans `src/client/Atelier/Scene.luau`, remplacer :

```lua
			local entree = { parts = {}, mesures = self.mesures }
			self.pieces[p.id] = entree
			for _, copie in ipairs(Patron.copies(p.id)) do
				local part = ConstructeurRobe.piece(p, copie, recette.mesures, self.cadre, "robe")
				if part and self.pieces[p.id] == entree and self.dossier.Parent then
					part.CanQuery = true -- touchée par les rayons des décorations
					part.Parent = self.robe
					table.insert(entree.parts, part)
				elseif part then
					part:Destroy() -- la pièce a été retirée pendant sa construction
				end
			end
```

par :

```lua
			local entree = { parts = {}, mesures = self.mesures }
			self.pieces[p.id] = entree
			local ratee = false
			for _, copie in ipairs(Patron.copies(p.id)) do
				local part = ConstructeurRobe.piece(p, copie, recette.mesures, self.cadre, "robe")
				if part and self.pieces[p.id] == entree and self.dossier.Parent then
					part.CanQuery = true -- touchée par les rayons des décorations
					part.Parent = self.robe
					table.insert(entree.parts, part)
				elseif part then
					part:Destroy() -- la pièce a été retirée pendant sa construction
				else
					ratee = true -- mémoire des maillages pleine
				end
			end
			-- Pièce ratée : oubliée, pour être reconstruite à la prochaine synchronisation
			if ratee and self.pieces[p.id] == entree then
				for _, part in ipairs(entree.parts) do
					part:Destroy()
				end
				self.pieces[p.id] = nil
			end
```

Dans `src/server/Boutiques.luau`, remplacer :

```lua
	for indice = 1, Boutique.NOMBRE do
		if not self.parIndice[indice] then
			local modele = construire(indice, joueur, self.rue)
			local vitrine = Instance.new("Part")
			vitrine.Name = "Vitrine_" .. indice
			vitrine.Anchored = true
			vitrine.Size = Vector3.new(4, 1, 4)
			vitrine.CFrame = Boutique.emplacement(indice) * Boutique.VITRINE
			vitrine.Material = Enum.Material.Wood
			vitrine.Color = BOIS
			vitrine.Parent = self.vitrines
			local b = { indice = indice, modele = modele, vitrine = vitrine, joueur = joueur }
			self.parIndice[indice], self.parJoueur[joueur] = b, b
```

par :

```lua
	for indice = 1, Boutique.NOMBRE do
		if not self.parIndice[indice] then
			-- Une panne de construction ne bloque pas l'arrivée : le joueur joue hors de la rue (attribut 0),
			-- et l'emplacement reste libre (boutique et vitrine ne sont posées qu'une fois construites)
			local ok, b = pcall(function()
				local modele = construire(indice, joueur, self.rue)
				local vitrine = Instance.new("Part")
				vitrine.Name = "Vitrine_" .. indice
				vitrine.Anchored = true
				vitrine.Size = Vector3.new(4, 1, 4)
				vitrine.CFrame = Boutique.emplacement(indice) * Boutique.VITRINE
				vitrine.Material = Enum.Material.Wood
				vitrine.Color = BOIS
				vitrine.Parent = self.vitrines
				return { indice = indice, modele = modele, vitrine = vitrine, joueur = joueur }
			end)
			if not ok then
				warn(("[Atelier] %s : boutique %d impossible à construire : %s"):format(joueur.Name, indice, tostring(b)))
				joueur:SetAttribute("Boutique", 0)
				return nil
			end
			self.parIndice[indice], self.parJoueur[joueur] = b, b
```

Dans `src/client/Atelier/init.client.luau`, remplacer :

```lua
local Session = require(script:WaitForChild("Session"))
local Scene = require(script:WaitForChild("Scene"))
```

par :

```lua
local Session = require(script:WaitForChild("Session"))
local Scene = require(script:WaitForChild("Scene"))
local Vignettes = require(script:WaitForChild("Vignettes"))
```

Dans `src/client/Atelier/init.client.luau`, remplacer :

```lua
		contenu:ClearAllChildren()
		disposer(EN_PANNEAU[etat.etape] == true)
```

par :

```lua
		contenu:ClearAllChildren()
		-- Sans pièce découpée (accueil, carnet), leurs images ne resserviront pas : place en mémoire
		if etat.etape == "accueil" or etat.etape == "carnet" then
			Vignettes.oublierPieces()
		end
		disposer(EN_PANNEAU[etat.etape] == true)
```

- [ ] **Step 4: Lancer les tests**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT"`
Expected:
```
Unitaires : 105039 vérifications
TOUT EST VERT : 346 vérifications
```

- [ ] **Step 5: Commit**

```bash
git add src/server/Boutiques.luau src/client/Atelier/Scene.luau src/client/Atelier/Vignettes.luau src/client/Atelier/init.client.luau tests/unitaires/20_scene.luau tests/unitaires/34_boutiques.luau tests/scenario.luau
git commit -m "Boutique en panne sans blocage, pièce ratée reconstruite, images des pièces oubliées après la commande

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 7: Vérification dans Studio et README

**Files:**
- Modify: `README.md`
- Modify: `AtelierCouture.rbxl` (régénéré)

**Interfaces:**
- Consumes: tout ce qui précède.
- Produces: le plan 4d-1 terminé ; la suite est le plan 4d-2.

- [ ] **Step 1: En Play, par le connecteur MCP**

Construire le lieu du dépôt dans un dossier temporaire (`C:/dev/jeux/roblox-maker/rojo.exe build -o <dossier temporaire>/Plan4d1Depot.rbxl`), l'ouvrir dans Studio, lancer Play, attendre 4 s. Avec `execute_luau` :

1. Côté client, cliquer `Clochette`, puis `Valider` (sans tissu), et lire `PlayerGui.Atelier.Fenetre.Message` (texte et `TextColor3`).
2. Côté serveur, lire `#game:GetService("HttpService"):JSONEncode(Sauvegarde.depuisEtat(EtatAtelier.nouveau()))` (modules `ServerScriptService.Atelier.Sauvegarde` et `ReplicatedStorage.Couture.EtatAtelier`).
3. Relever les alertes des deux côtés (`get_console_output`).

Expected :
- titre « 1. Carnet de croquis » ;
- un message d'erreur en rouge (`TextColor3` différent de 130, 100, 115) ;
- une longueur JSON de l'ordre de 100 caractères, sans erreur ;
- aucune alerte hors « Lieu non publié : les parties ne sont pas sauvegardées. ».

Arrêter Play et fermer cette fenêtre de Studio.

- [ ] **Step 2: À faire par le commanditaire**

Ces vérifications demandent l'interface de Studio ou un lieu publié :
- le rendu : « Un instant… » sur un réseau lent (Studio, paramètres réseau : latence simulée de 500 ms), « Livrer la robe » confirmé ;
- l'essai à 3 joueurs (Test, « Clients et serveur ») ;
- la sauvegarde réelle sur un lieu de test privé publié : départ puis retour rapide sur le même serveur.

Les noter dans le message de fin, sans bloquer le plan.

- [ ] **Step 3: Mettre à jour le README**

Dans `README.md`, remplacer :

```markdown
## État actuel (plan 4c)
```

par :

```markdown
## État actuel (plan 4d-1)
```

Dans `README.md`, remplacer :

```markdown
9. La suite : finition (plan 4d).
```

par :

```markdown
9. La suite : écarts à la spec §4, sons, réglages mobiles, équilibrage, mobilier (plan 4d-2).
```

Dans `README.md`, remplacer :

```markdown
« Recommencer la robe » demande une confirmation (deuxième appui) : le tissu coupé et les décorations
posées sont perdus.
```

par :

```markdown
« Recommencer la robe » (le tissu coupé et les décorations posées sont perdus) et « Livrer la robe »
demandent une confirmation (deuxième appui).

**Réseau lent ou coupé** : au-delà de 0,3 s d'attente du serveur, « Un instant… » s'affiche en gris sous la
fenêtre. Un refus passager (serveur occupé ou injoignable, trop d'appels) s'affiche en gris et ne défait
rien : une pièce cousue reste finie, on la rend de nouveau. Une réponse perdue est rattrapée : le client
redemande l'état au serveur, et chaque refus des règles emporte l'état du serveur, qui répare la copie du
client. Si la partie n'est pas encore arrivée au bout d'une minute, le joueur en est prévenu.
```

Dans `README.md`, remplacer :

```markdown
  serveur. Rien n'est écrit si la lecture a échoué (le joueur est prévenu), ni sur un lieu non publié.
```

par :

```markdown
  serveur. Rien n'est écrit si la lecture a échoué (le joueur est prévenu), ni sur un lieu non publié.
  Une écriture à la fois par joueur (la sauvegarde régulière et celle du départ ne se croisent pas, et un
  retour rapide sur le même serveur attend l'écriture du départ) ; à l'arrêt du serveur, les parties en
  cours de lecture sont attendues ; une partie trop lourde (plus de 3,5 millions de caractères) perd ses
  plus anciennes robes.
```

Dans `README.md`, remplacer :

```markdown
  recette de sa dernière robe livrée (attribut `Recette`) ; chaque client construit les robes proches.
```

par :

```markdown
  recette de sa dernière robe livrée (attribut `Recette`) ; chaque client construit les robes proches.
  Une boutique impossible à construire n'empêche pas de jouer : l'atelier est alors hors de la rue.
```

Dans `README.md`, remplacer :

```markdown
  `Session` envoie chaque action au serveur et recharge sur place la copie de l'état qu'il renvoie ; `TableDecoupe` et `MachineCoudre` sont la logique pure de la table
```

par :

```markdown
  `Session` envoie chaque action au serveur (une à la fois) et recharge sur place la copie de l'état qu'il
  renvoie, acceptée ou refusée ; elle signale l'attente à l'interface et redemande l'état après une réponse
  perdue. `TableDecoupe` et `MachineCoudre` sont la logique pure de la table
```

- [ ] **Step 4: Tests, lieu régénéré, commit**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT"`
Expected:
```
Unitaires : 105039 vérifications
TOUT EST VERT : 346 vérifications
```

```bash
C:/dev/jeux/roblox-maker/rojo.exe build -o AtelierCouture.rbxl
git add README.md AtelierCouture.rbxl
git commit -m "Plan 4d-1 terminé : robustesse et confort du joueur

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```
