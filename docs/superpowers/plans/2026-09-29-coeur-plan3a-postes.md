# Cœur de l'atelier — Plan 3a : commande, carnet, achat et découpe

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Remplacer l'ancien jeu par le nouvel atelier et rendre jouables les quatre premiers postes : prendre une commande, dessiner la robe dans le carnet, acheter le tissu, puis découper les pièces sur la table.

**Architecture:**
- **État de la commande** : il vit dans un module pur partagé, `EtatAtelier`. Au plan 3, le client l'utilise en local à travers `Session` ; au plan 4, le serveur le reprendra derrière les échanges réseau.
- **Interface** : c'est un LocalScript `Atelier` (`src/client/Atelier/init.client.luau`) avec un module par écran. La logique non graphique de la table de découpe est isolée dans `TableDecoupe`, testée seule.
- **Tests** : l'interface est vérifiée par un scénario qui clique dans le faux Roblox. Le rendu et le glisser-déposer sont vérifiés dans Studio par le connecteur MCP.
- **Ancien jeu** : `CoutureData`, `Rendu3D`, `AtelierClient`, `AtelierServer` et son scénario sont retirés.

**Tech Stack:** Luau, Rojo 7.7.0-rc.1, simulation Luau 0.650 (`tests/lancer.sh`), Roblox Studio via le connecteur MCP Studio.

**Spec:** `docs/superpowers/specs/2026-09-28-atelier-coeur-design.md` (§3 règles, §4 déroulé et commandes, §6 contrôles). Modules des plans 1 et 2 : `Catalogue`, `Patron`, `Coupon`, `Notation`, `Commandes`, `Pixels`, `Editables`.

## Global Constraints

- **Dépôt** : `C:\dev\jeux\atelier-couture`, branche `refonte-postes`. Ne rien pousser sur GitHub sans demande.
- **Rojo** : `C:/dev/jeux/roblox-maker/rojo.exe`.
- **Contraintes des plans 1 et 2 toujours valables** :
  - unité le dm ;
  - repère du corps ;
  - fins de ligne LF ;
  - commits en français terminés par `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.
- **Argent de départ** : 150 pièces d'or (po). Filet de sécurité : au moins 20 po à chaque nouvelle commande. Prix d'un tissu au mètre, arrondi au-dessus (`ceil(prix × dm / 10)`). Achat de 1 à 100 dm entiers.
- **Étapes du plan 3a** : `accueil` → `carnet` → `achat` → `decoupe` → `epinglage` (écran provisoire en attendant le plan 3b).
- **Retour au carnet** : possible tant qu'aucune pièce n'est coupée. « Recommencer » garde la commande, et le tissu déjà entamé est perdu.
- **Rouleau** :
  - 14 dm de large, un rouleau par tissu, de la longueur en stock ; acheter pendant la découpe l'allonge ;
  - à la fin de la découpe, le stock perd la longueur entamée de chaque rouleau.
- **Proposition de place** : la première place libre en haut du rouleau, contre les bords des pièces déjà coupées, au droit-fil parfait (45° pour une pièce en biais). Une pièce pliée est d'abord proposée contre le pli.
- **Interface** : fenêtre de référence 900 × 560, réduite par `UIScale` sur petit écran. Police Gotham, sans les symboles qu'elle n'a pas (« ✕ », « ⟳ », « ↻ », « ↺ ») ; les boutons de rotation affichent `« 15°`, `« 1°`, `1° »` et `15° »`.
- **Glisser-déposer** : il convertit l'écran en dm avec la taille réelle du rouleau à l'écran (`AbsoluteSize`, qui tient compte de `UIScale`) et garde l'écart entre le doigt et le centre de la pièce.
- **Tests** :
  - `bash tests/lancer.sh` affiche `Unitaires : N vérifications` puis `TOUT EST VERT : M vérifications` (scénario du nouvel atelier) ;
  - `tests/build.py` vide le cache des modules avant le scénario.

## Review Focus

- **Glisser une pièce au doigt sur téléphone** (`UserInputType.Touch`). Attendu : la pièce suit le doigt comme la souris, et le rouleau ne défile pas en même temps. La simulation et le connecteur Studio ne savent envoyer que la souris.
- **Téléphone en paysage** (environ 896 × 414). Attendu : textes lisibles. La fenêtre est réduite vers 0,63, donc un texte de 13 px fait environ 8 px. À mesurer ; sinon, à corriger dans la finition du plan 4.
- **Double clic rapide sur « Couper », « Acheter » ou « Valider ».** Attendu : la seconde action est refusée proprement par `EtatAtelier` (étape, stock, pièce déjà coupée), sans double débit ni erreur.
- **Mémoire des images pleine** (vignettes de tissu et silhouettes). Attendu : les écrans affichent la couleur du tissu à la place du motif, sans erreur (`Vignettes` renvoie nil).
- **Commande dont une exigence est impossible avec les tissus déjà choisis.** Attendu : le carnet l'affiche en « × », et « Valider » reste possible ; la cliente jugera à la livraison (plan 3b).

## Structure des fichiers

| Fichier | Rôle |
|---|---|
| `src/shared/CoutureData.luau`, `src/shared/Rendu3D.luau`, `src/client/AtelierClient.client.luau`, `src/server/AtelierServer.server.luau` | **Supprimés** (ancien jeu) |
| `default.project.json` | Le LocalScript `Atelier` (dossier `src/client/Atelier`) remplace `AtelierClient` ; plus de script serveur |
| `tests/build.py` | Charge aussi les modules du client ; fournit `NOMS_PARTAGES` et `NOMS_CLIENT` ; vide le cache avant le scénario ; replace le dossier des tests unitaires si le monde est réinitialisé |
| `tests/scenario.luau` | Scénario du nouvel atelier (provisoire à la tâche 1, complet à la tâche 6) |
| `tests/unitaires/00_outillage.luau` | Découverte des modules partagés et du client |
| `src/shared/EtatAtelier.luau` | État de la commande : argent, stock, étape, croquis, tissus, rouleaux, pièces coupées |
| `src/shared/Metrage.luau` | Disposition simple des pièces sur un rouleau, métrage conseillé, encombrement d'une pièce tournée |
| `src/shared/Pixels.luau` | + `Pixels.silhouette` (patron en papier : contour, flèche de droit-fil) |
| `src/client/Atelier/init.client.luau` | Fenêtre, argent, messages, navigation selon l'étape |
| `src/client/Atelier/UiKit.luau` | Couleurs, création d'objets, boutons, échelle, texte des exigences |
| `src/client/Atelier/Session.luau` | Accès de l'interface à l'état (local au plan 3) et avis de changement |
| `src/client/Atelier/Vignettes.luau` | Motifs et silhouettes convertis en contenu statique, en cache |
| `src/client/Atelier/TableDecoupe.luau` | Logique de la table : tissu, pièce, position, rotation, validité, proposition, coupe |
| `src/client/Atelier/EcranAccueil.luau`, `EcranCarnet.luau`, `EcranAchat.luau`, `EcranDecoupe.luau`, `EcranSuite.luau` | Un écran par étape |
| `tests/unitaires/14_etat_atelier.luau`, `15_metrage.luau`, `16_table_decoupe.luau` | Tests unitaires |
| `README.md` | Réécrit : état actuel du jeu |

---

### Task 1: Retirer l'ancien jeu et outiller le client

**Files:**
- Delete: `src/shared/CoutureData.luau`, `src/shared/Rendu3D.luau`, `src/client/AtelierClient.client.luau`, `src/server/AtelierServer.server.luau`
- Modify: `default.project.json` (réécriture complète)
- Modify: `tests/build.py`
- Modify: `tests/scenario.luau` (réécriture : scénario provisoire)
- Modify: `tests/unitaires/00_outillage.luau` (réécriture)
- Create: `src/client/Atelier/UiKit.luau`

**Interfaces:**
- Consumes: rien.
- Produces :
  - dans le simulateur, `NOMS_PARTAGES` et `NOMS_CLIENT` (noms des modules de `src/shared/` et de `src/client/Atelier/` hors `init.*`), et `SCRIPTS.Atelier(script)` si `init.client.luau` existe. `U.module(nom)` charge aussi les modules du client ;
  - `UiKit.COULEURS`, `UiKit.LARGEUR`, `UiKit.HAUTEUR`, `UiKit.creer(classe, props, enfants?)`, `UiKit.arrondir(instance, rayon?)`, `UiKit.texte(props)`, `UiKit.bouton(props, auClic?)`, `UiKit.boutonDoux(props, auClic?)`, `UiKit.echelle(tailleEcran: Vector2) -> number`, `UiKit.couleur({r, g, b}) -> Color3`, `UiKit.exigence(exigence, Catalogue) -> string`.

- [ ] **Step 1: Réécrire le test de l'outillage**

`tests/unitaires/00_outillage.luau` :

```lua
-- Vérifie que l'outillage des tests unitaires charge bien les modules partagés et ceux du client
U.verifier(table.find(NOMS_MODULES, "Catalogue") ~= nil, "les modules de src/shared sont découverts")
U.verifier(table.find(NOMS_MODULES, "UiKit") ~= nil, "les modules de src/client/Atelier sont découverts")
U.verifier(U.module("Catalogue").LARGEUR_ROULEAU == 14, "U.module charge un module partagé")
```

- [ ] **Step 2: Vérifier qu'il échoue**

Run: `bash tests/lancer.sh 2>&1 | grep -m1 "ÉCHEC"`
Expected: `ÉCHEC : les modules de src/client/Atelier sont découverts`

- [ ] **Step 3: Retirer l'ancien jeu**

```bash
git rm -q src/shared/CoutureData.luau src/shared/Rendu3D.luau src/client/AtelierClient.client.luau src/server/AtelierServer.server.luau
```

`default.project.json` :

```json
{
  "name": "atelier-couture",
  "tree": {
    "$className": "DataModel",
    "Workspace": {
      "Baseplate": {
        "$className": "Part",
        "$properties": {
          "Anchored": true,
          "Locked": true,
          "Size": [
            256,
            16,
            256
          ],
          "CFrame": [
            0,
            -8,
            0,
            1,
            0,
            0,
            0,
            1,
            0,
            0,
            0,
            1
          ],
          "Color": [
            0.388,
            0.373,
            0.384
          ]
        }
      },
      "SpawnLocation": {
        "$className": "SpawnLocation",
        "$properties": {
          "Anchored": true,
          "Size": [
            12,
            1,
            12
          ],
          "CFrame": [
            0,
            0.5,
            0,
            1,
            0,
            0,
            0,
            1,
            0,
            0,
            0,
            1
          ]
        }
      }
    },
    "TextChatService": {
      "$properties": {
        "ChatVersion": "TextChatService"
      }
    },
    "ReplicatedStorage": {
      "Couture": {
        "$path": "src/shared"
      }
    },
    "StarterPlayer": {
      "StarterPlayerScripts": {
        "Atelier": {
          "$path": "src/client/Atelier"
        }
      }
    }
  }
}
```

`tests/scenario.luau` (provisoire, remplacé à la tâche 6) :

```lua
-- Scénario du nouvel atelier (rempli à la fin du plan 3a)
print("TOUT EST VERT : 0 vérifications")
```

- [ ] **Step 4: Charger les modules du client dans le simulateur**

```diff
diff --git a/tests/build.py b/tests/build.py
index 4593fa6..ec873ae 100644
--- a/tests/build.py
+++ b/tests/build.py
@@ -19,6 +19,9 @@ function U.proche(a, b, tol)
 end
 local dossierUnitaires
 function U.module(nomModule)
+	if dossierUnitaires and dossierUnitaires.Parent ~= M.services.ReplicatedStorage then
+		dossierUnitaires.Parent = M.services.ReplicatedStorage -- un test a réinitialisé le monde
+	end
 	if not dossierUnitaires then
 		M.initialiser()
 		dossierUnitaires = M.nouvelleInstance("Folder")
@@ -46,20 +49,25 @@ out.append("""requireModule = function(ms)
 	end
 	return cache[nom]
 end""")
-# Tous les modules partagés sont chargés automatiquement
-modules = sorted(glob.glob(SRC + "/shared/*.luau"))
+# Modules partagés et modules du client (sauf le script de démarrage) : chargés automatiquement
+modules = sorted(glob.glob(SRC + "/shared/*.luau")) + sorted(
+    c for c in glob.glob(SRC + "/client/Atelier/*.luau") if not os.path.basename(c).startswith("init."))
 for chemin in modules:
     out.append(f"MODULES[\"{nom(chemin)}\"] = function(script)\n" + ENTETE + lire(chemin) + "\nend")
 out.append("local NOMS_MODULES = { " + ", ".join(f"\"{nom(c)}\"" for c in modules) + " }")
+# Noms séparés pour le scénario : modules partagés (ReplicatedStorage.Couture) et modules du client (enfants du LocalScript)
+out.append("local NOMS_PARTAGES = { " + ", ".join(f"\"{nom(c)}\"" for c in modules if "/shared/" in c.replace("\\", "/")) + " }")
+out.append("local NOMS_CLIENT = { " + ", ".join(f"\"{nom(c)}\"" for c in modules if "/client/" in c.replace("\\", "/")) + " }")
 out.append("local SCRIPTS = {}")
-for nomScript, chemin in [("AtelierServer", "server/AtelierServer.server.luau"),
-                          ("AtelierClient", "client/AtelierClient.client.luau")]:
-    out.append(f"SCRIPTS[\"{nomScript}\"] = function(script)\n" + ENTETE + lire(SRC + "/" + chemin) + "\nend")
+for nomScript, chemin in [("Atelier", "client/Atelier/init.client.luau")]:
+    if os.path.exists(SRC + "/" + chemin):
+        out.append(f"SCRIPTS[\"{nomScript}\"] = function(script)\n" + ENTETE + lire(SRC + "/" + chemin) + "\nend")
 # Tests unitaires (tests/unitaires/*.luau), exécutés avant le scénario
 out.append(OUTILS_UNITAIRES)
 for f in sorted(glob.glob(ICI + "/unitaires/*.luau")):
     out.append("do\n" + ENTETE + lire(f) + "\nend")
 out.append("print((\"Unitaires : %d vérifications\"):format(U.compte))")
 out.append("M.avertissements = {} -- le scénario ne voit pas les avertissements des tests unitaires")
+out.append("table.clear(cache) -- le scénario recharge des modules neufs, liés à ses propres instances")
 out.append("do\n" + ENTETE + lire(sim + "scenario.luau") + "\nend")
 open(sim + "run.luau", "w", encoding="utf-8").write("\n".join(out))
```

- [ ] **Step 5: Écrire `UiKit`**

`src/client/Atelier/UiKit.luau` :

```lua
-- UiKit : outils d'interface communs (couleurs, création d'objets, boutons, messages, mise à l'échelle).
local UiKit = {}

UiKit.COULEURS = {
	fond = Color3.fromRGB(253, 244, 247),
	panneau = Color3.fromRGB(255, 255, 255),
	accent = Color3.fromRGB(214, 76, 128),
	secondaire = Color3.fromRGB(240, 214, 224),
	texte = Color3.fromRGB(58, 36, 48),
	texteDoux = Color3.fromRGB(130, 100, 115),
	ok = Color3.fromRGB(70, 160, 100),
	alerte = Color3.fromRGB(230, 140, 40),
	erreur = Color3.fromRGB(210, 60, 60),
}
UiKit.LARGEUR, UiKit.HAUTEUR = 900, 560 -- taille de référence de la fenêtre (mise à l'échelle sur petit écran)

function UiKit.creer(classe, props, enfants)
	local instance = Instance.new(classe)
	local parent
	for cle, valeur in pairs(props or {}) do
		if cle == "Parent" then
			parent = valeur
		else
			instance[cle] = valeur
		end
	end
	for _, enfant in ipairs(enfants or {}) do
		enfant.Parent = instance
	end
	if parent then
		instance.Parent = parent
	end
	return instance
end

function UiKit.arrondir(instance, rayon)
	UiKit.creer("UICorner", { CornerRadius = UDim.new(0, rayon or 8), Parent = instance })
	return instance
end

local function fusionner(defaut, props)
	for cle, valeur in pairs(props or {}) do
		defaut[cle] = valeur
	end
	return defaut
end

function UiKit.texte(props)
	return UiKit.creer("TextLabel", fusionner({
		BackgroundTransparency = 1,
		Font = Enum.Font.Gotham,
		TextSize = 16,
		TextColor3 = UiKit.COULEURS.texte,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextWrapped = true,
	}, props))
end

-- Bouton ; auClic est appelé par Activated (souris, doigt, manette)
function UiKit.bouton(props, auClic)
	local b = UiKit.creer("TextButton", fusionner({
		BackgroundColor3 = UiKit.COULEURS.accent,
		TextColor3 = Color3.new(1, 1, 1),
		Font = Enum.Font.GothamBold,
		TextSize = 16,
		AutoButtonColor = true,
		Size = UDim2.fromOffset(180, 40),
	}, props))
	UiKit.arrondir(b, 8)
	if auClic then
		b.Activated:Connect(auClic)
	end
	return b
end

-- Bouton secondaire (fond clair)
function UiKit.boutonDoux(props, auClic)
	return UiKit.bouton(fusionner({ BackgroundColor3 = UiKit.COULEURS.secondaire, TextColor3 = UiKit.COULEURS.texte }, props), auClic)
end

-- Échelle d'une fenêtre de taille de référence pour tenir dans l'écran (téléphones)
function UiKit.echelle(tailleEcran)
	return math.min(1, (tailleEcran.X - 20) / UiKit.LARGEUR, (tailleEcran.Y - 60) / UiKit.HAUTEUR)
end

-- Couleur Color3 d'un triplet { r, v, b }
function UiKit.couleur(c)
	return Color3.fromRGB(c[1], c[2], c[3])
end

-- Texte lisible d'une exigence de commande
function UiKit.exigence(e, Catalogue)
	if e.type == "min" then
		return ("Au moins %d en %s"):format(e.valeur, Catalogue.NOMS_STYLES[e.style])
	elseif e.type == "max" then
		return ("Au plus %d en %s"):format(e.valeur, Catalogue.NOMS_STYLES[e.style])
	elseif e.type == "qualite" then
		return ("Qualité d'au moins %d %%"):format(math.floor(e.valeur * 100 + 0.5))
	elseif e.type == "teinte" then
		return "Couleur dominante : " .. e.teinte
	elseif e.type == "accessoire" then
		return "Avec : " .. Catalogue.accessoire(e.id).nom
	end
	return "?"
end

return UiKit
```

- [ ] **Step 6: Lancer les tests**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT"`
Expected:
```
Unitaires : 103488 vérifications
TOUT EST VERT : 0 vérifications
```

- [ ] **Step 7: Commit**

```bash
git add -A default.project.json tests/build.py tests/scenario.luau tests/unitaires/00_outillage.luau src/client/Atelier/UiKit.luau src/shared src/client src/server
git commit -m "Retire l'ancien jeu et prépare le client du nouvel atelier

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 2: Module `EtatAtelier` (état de la commande)

**Files:**
- Create: `src/shared/EtatAtelier.luau`
- Test: `tests/unitaires/14_etat_atelier.luau`

**Interfaces:**
- Consumes: `Catalogue.tissu`, `Catalogue.prix` des tissus ; `Patron.piecesDuCroquis` ; `Coupon.nouveau`, `coupon:poser`, `coupon.poses`, `coupon:longueurUtilisee`, `coupon.longueur` ; `Commandes.generer`.
- Produces :
  - constantes `EtatAtelier.ARGENT_DEPART = 150`, `FILET = 20`, `ACHAT_MAX = 100`, `ETAPES` ;
  - `EtatAtelier.nouveau(argent?) -> etat`, avec les champs `argent`, `stock` ([tissu] = dm), `etape`, `commande`, `croquis`, `tissus` ([pièce] = tissu), `coupons` ([tissu] = Coupon), `coupees` ([pièce] = placement) ;
  - `EtatAtelier.prix(idTissu, dm) -> integer` ;
  - `etat:piecesDuCroquis()`, `etat:piecesAPoser()`, `etat:tissusUtilises()` ;
  - actions qui renvoient `{ ok, erreur?, ... }` et ne lèvent jamais d'erreur : `etat:nouvelleCommande(rng) -> { ok, commande }`, `etat:validerCroquis(croquis, tissus)`, `etat:retourCarnet()`, `etat:acheter(idTissu, dm) -> { ok, prix }`, `etat:commencerDecoupe()`, `etat:couper(idPiece, placement) -> { ok, reste }`, `etat:recommencer()`.

- [ ] **Step 1: Écrire les tests**

`tests/unitaires/14_etat_atelier.luau` :

```lua
local EtatAtelier = U.module("EtatAtelier")

local CROQUIS = { corsage = "corsage_droit", manches = "manches_sans", col = "col_sans", jupe = "jupe_droite" }
local function tousEn(tissu)
	return {
		corsage_droit_devant = tissu,
		corsage_droit_dos = tissu,
		jupe_droite_devant = tissu,
		jupe_droite_dos = tissu,
	}
end
-- Disposition sans chevauchement des 4 pièces sur un rouleau de 14 dm
local DISPOSITION = {
	corsage_droit_devant = { x = 2.4, y = 2.1, angle = 0 },
	corsage_droit_dos = { x = 7.2, y = 2.1, angle = 0 },
	jupe_droite_devant = { x = 2.5, y = 7.2, angle = 0 },
	jupe_droite_dos = { x = 7.5, y = 7.2, angle = 0 },
}

-- Démarrage et commande
local e = EtatAtelier.nouveau()
U.verifier(e.argent == 150 and e.etape == "accueil", "départ : 150 pièces d'or, à l'accueil")
local r = e:nouvelleCommande(Random.new(3))
U.verifier(r.ok and e.etape == "carnet" and #r.commande.exigences >= 1, "nouvelle commande : direction le carnet")
U.verifier(not e:nouvelleCommande(Random.new(4)).ok, "une seule commande à la fois")
local pauvre = EtatAtelier.nouveau(3)
pauvre:nouvelleCommande(Random.new(1))
U.verifier(pauvre.argent == EtatAtelier.FILET, "filet de sécurité : au moins 20 pièces d'or")

-- Carnet
U.verifier(not e:acheter("coton_blanc", 5).ok, "pas d'achat avant d'avoir validé le croquis")
U.verifier(not e:validerCroquis("x", nil).ok, "croquis qui n'est pas une table refusé")
U.verifier(not e:validerCroquis({ corsage = "corsage_droit" }, {}).ok, "croquis incomplet refusé")
local manque = tousEn("coton_blanc")
manque.jupe_droite_dos = nil
U.verifier(not e:validerCroquis(CROQUIS, manque).ok, "une pièce sans tissu est refusée")
local inconnu = tousEn("coton_blanc")
inconnu.jupe_droite_dos = "papier"
U.verifier(not e:validerCroquis(CROQUIS, inconnu).ok, "un tissu inconnu est refusé")
local choix = tousEn("coton_blanc")
choix.corsage_droit_devant, choix.corsage_droit_dos = "soie_rouge", "soie_rouge"
U.verifier(e:validerCroquis(CROQUIS, choix).ok and e.etape == "achat", "croquis validé : direction l'achat")
local utilises = e:tissusUtilises()
U.verifier(#utilises == 2 and utilises[1] == "soie_rouge" and utilises[2] == "coton_blanc", "tissus utilisés dans l'ordre des pièces")

-- Achat
U.verifier(EtatAtelier.prix("coton_blanc", 12) == 5 and EtatAtelier.prix("soie_rouge", 10) == 16, "prix au mètre, arrondi au-dessus")
for _, mauvais in ipairs({ 0, 1.5, 101, 0 / 0, "a" }) do
	U.verifier(not e:acheter("coton_blanc", mauvais).ok, "longueur invalide refusée : " .. tostring(mauvais))
end
U.verifier(not e:acheter("papier", 5).ok and not e:acheter(nil, 5).ok, "tissu inconnu refusé")
U.verifier(not e:acheter("soie_rouge", 100).ok, "pas assez d'argent")
U.verifier(not e:commencerDecoupe().ok, "découpe impossible sans tissu")
local achat = e:acheter("coton_blanc", 12)
U.verifier(achat.ok and achat.prix == 5 and e.argent == 145 and e.stock.coton_blanc == 12, "achat : argent débité, stock crédité")
U.verifier(e:acheter("soie_rouge", 6).ok and e.argent == 145 - 10, "deuxième tissu acheté")
U.verifier(e:commencerDecoupe().ok, "découpe possible avec du tissu pour chaque pièce")
U.verifier(e.etape == "decoupe" and e.coupons.coton_blanc.longueur == 12 and e.coupons.soie_rouge.longueur == 6, "un rouleau par tissu, de la longueur en stock")

-- Retour au carnet tant que rien n'est coupé
U.verifier(e:retourCarnet().ok and e.etape == "carnet", "retour au carnet avant la première coupe")
U.verifier(e:validerCroquis(CROQUIS, choix).ok and e:commencerDecoupe().ok, "on revient à la découpe")

-- Découpe
U.verifier(not e:couper("manche_longue", { x = 3, y = 3, angle = 0 }).ok, "pièce hors croquis refusée")
U.verifier(not e:couper(123, nil).ok, "pièce invalide refusée")
U.verifier(not e:couper("corsage_droit_devant", { x = 0 / 0, y = 2, angle = 0 }).ok, "position invalide refusée")
local c1 = e:couper("corsage_droit_devant", DISPOSITION.corsage_droit_devant)
U.verifier(c1.ok and c1.reste == 3 and e.coupees.corsage_droit_devant ~= nil, "première pièce coupée")
U.verifier(not e:retourCarnet().ok, "plus de retour au carnet après une coupe")
U.verifier(not e:couper("corsage_droit_dos", { x = 3, y = 2.1, angle = 0 }).ok, "chevauchement refusé")
U.verifier(not e:couper("jupe_droite_devant", { x = 2.5, y = 9.5, angle = 0 }).ok, "la jupe dépasse des 12 dm de coton")
for _, id in ipairs({ "corsage_droit_dos", "jupe_droite_devant", "jupe_droite_dos" }) do
	U.verifier(e:couper(id, DISPOSITION[id]).ok, id .. " coupée")
end
U.verifier(e.etape == "epinglage", "toutes les pièces coupées : direction l'épinglage")
U.verifier(e.stock.soie_rouge == 6 - 5 and e.stock.coton_blanc == 12 - 11, "chaque rouleau perd sa longueur entamée (5 et 11 dm)")

-- Rouleau trop court : on rachète pendant la découpe
local e2 = EtatAtelier.nouveau()
e2:nouvelleCommande(Random.new(5))
e2:validerCroquis(CROQUIS, tousEn("coton_blanc"))
e2:acheter("coton_blanc", 10)
e2:commencerDecoupe()
U.verifier(e2:couper("corsage_droit_devant", DISPOSITION.corsage_droit_devant).ok, "corsage devant")
U.verifier(not e2:couper("jupe_droite_devant", DISPOSITION.jupe_droite_devant).ok, "la jupe dépasse des 10 dm achetés")
U.verifier(e2:acheter("coton_blanc", 2).ok and e2.coupons.coton_blanc.longueur == 12, "acheter pendant la découpe déroule le rouleau")
for _, id in ipairs({ "corsage_droit_dos", "jupe_droite_devant", "jupe_droite_dos" }) do
	U.verifier(e2:couper(id, DISPOSITION[id]).ok, id .. " coupée")
end
U.verifier(e2.etape == "epinglage" and e2.stock.coton_blanc == 12 - 11, "robe coupée, 11 dm consommés")
U.verifier(not e2:couper("jupe_droite_dos", DISPOSITION.jupe_droite_dos).ok, "plus de découpe après la dernière pièce")

-- Recommencer : le tissu entamé est perdu, la commande reste
local e3 = EtatAtelier.nouveau()
local commande = e3:nouvelleCommande(Random.new(6)).commande
e3:validerCroquis(CROQUIS, tousEn("coton_blanc"))
e3:acheter("coton_blanc", 12)
e3:commencerDecoupe()
e3:couper("jupe_droite_devant", DISPOSITION.jupe_droite_devant)
U.verifier(e3:recommencer().ok and e3.etape == "carnet" and e3.commande == commande, "recommencer : retour au carnet, même commande")
U.verifier(e3.stock.coton_blanc == 12 - 11, "le tissu entamé est perdu")
U.verifier(next(e3.coupees) == nil and e3.croquis == nil, "robe remise à zéro")
U.verifier(not EtatAtelier.nouveau():recommencer().ok, "rien à recommencer sans commande")
```

- [ ] **Step 2: Vérifier qu'ils échouent**

Run: `bash tests/lancer.sh 2>&1 | grep -m1 "membre valide"`
Expected: `EtatAtelier n'est pas un membre valide de Folder « Couture »`

- [ ] **Step 3: Écrire le module**

`src/shared/EtatAtelier.luau` :

```lua
-- EtatAtelier : état d'un joueur à l'atelier et étapes de la commande en cours.
-- Logique pure, sans instance Roblox : le client s'en sert en local (plan 3),
-- puis le serveur la reprend derrière les échanges réseau (plan 4), où elle fait foi.
-- Chaque action renvoie { ok = true, ... } ou { ok = false, erreur = "…" } et ne lève jamais d'erreur.
local dossier = script.Parent
local Catalogue = require(dossier:WaitForChild("Catalogue"))
local Patron = require(dossier:WaitForChild("Patron"))
local Coupon = require(dossier:WaitForChild("Coupon"))
local Commandes = require(dossier:WaitForChild("Commandes"))

local EtatAtelier = {}
EtatAtelier.__index = EtatAtelier

EtatAtelier.ARGENT_DEPART = 150
EtatAtelier.FILET = 20 -- argent minimal garanti à chaque nouvelle commande
EtatAtelier.ACHAT_MAX = 100 -- dm par achat
-- Étapes du plan 3a (le plan 3b ajoute épinglage, couture, décorations et livraison)
EtatAtelier.ETAPES = { "accueil", "carnet", "achat", "decoupe", "epinglage" }

local function refus(message)
	return { ok = false, erreur = message }
end

local function fini(n)
	return type(n) == "number" and n == n and n ~= math.huge and n ~= -math.huge
end

function EtatAtelier.nouveau(argent)
	return setmetatable({
		argent = argent or EtatAtelier.ARGENT_DEPART,
		stock = {}, -- [idTissu] = dm
		etape = "accueil",
		commande = nil,
		croquis = nil,
		tissus = {}, -- [idPiece] = idTissu
		coupons = {}, -- [idTissu] = Coupon (pendant la découpe)
		coupees = {}, -- [idPiece] = { x, y, angle }
	}, EtatAtelier)
end

-- Prix en pièces d'or de « dm » décimètres d'un tissu (prix au mètre, arrondi au-dessus)
function EtatAtelier.prix(idTissu, dm)
	return math.ceil(Catalogue.tissu(idTissu).prix * dm / 10 - 1e-9)
end

function EtatAtelier:piecesDuCroquis()
	return self.croquis and Patron.piecesDuCroquis(self.croquis) or {}
end

function EtatAtelier:piecesAPoser()
	local out = {}
	for _, id in ipairs(self:piecesDuCroquis()) do
		if not self.coupees[id] then
			table.insert(out, id)
		end
	end
	return out
end

-- Tissus utilisés par le croquis, dans l'ordre d'apparition
function EtatAtelier:tissusUtilises()
	local vus, out = {}, {}
	for _, id in ipairs(self:piecesDuCroquis()) do
		local t = self.tissus[id]
		if t and not vus[t] then
			vus[t] = true
			table.insert(out, t)
		end
	end
	return out
end

-- Le tissu déjà coupé est perdu : on retire du stock la longueur entamée de chaque rouleau
local function consommer(self)
	for idTissu, coupon in pairs(self.coupons) do
		self.stock[idTissu] = math.max(0, (self.stock[idTissu] or 0) - coupon:longueurUtilisee())
	end
	self.coupons = {}
end

function EtatAtelier:nouvelleCommande(rng)
	if self.etape ~= "accueil" then
		return refus("Une commande est déjà en cours.")
	end
	self.commande = Commandes.generer(rng)
	self.argent = math.max(self.argent, EtatAtelier.FILET)
	self.croquis, self.tissus, self.coupees, self.coupons = nil, {}, {}, {}
	self.etape = "carnet"
	return { ok = true, commande = self.commande }
end

-- croquis = { corsage, manches, col, jupe } ; tissus = { [idPiece] = idTissu } pour chaque pièce du croquis
function EtatAtelier:validerCroquis(croquis, tissus)
	if self.etape ~= "carnet" and self.etape ~= "achat" then
		return refus("Le croquis ne peut plus être modifié.")
	end
	local ok, pieces = pcall(Patron.piecesDuCroquis, croquis)
	if not ok or type(tissus) ~= "table" then
		return refus("Croquis invalide.")
	end
	local choix = {}
	for _, id in ipairs(pieces) do
		local t = tissus[id]
		if type(t) ~= "string" or not Catalogue.tissu(t) then
			return refus("Choisis un tissu pour chaque pièce.")
		end
		choix[id] = t
	end
	self.croquis = table.clone(croquis)
	self.tissus = choix
	self.etape = "achat"
	return { ok = true }
end

-- Retour au carnet, possible tant qu'aucune pièce n'est coupée
function EtatAtelier:retourCarnet()
	if self.etape ~= "achat" and not (self.etape == "decoupe" and next(self.coupees) == nil) then
		return refus("Des pièces sont déjà coupées.")
	end
	self.coupons = {}
	self.etape = "carnet"
	return { ok = true }
end

function EtatAtelier:acheter(idTissu, dm)
	if self.etape ~= "achat" and self.etape ~= "decoupe" then
		return refus("Ce n'est pas le moment d'acheter du tissu.")
	end
	if type(idTissu) ~= "string" or not Catalogue.tissu(idTissu) then
		return refus("Tissu inconnu.")
	end
	if not fini(dm) or dm ~= math.floor(dm) or dm < 1 or dm > EtatAtelier.ACHAT_MAX then
		return refus("Longueur invalide.")
	end
	local prix = EtatAtelier.prix(idTissu, dm)
	if prix > self.argent then
		return refus("Pas assez d'argent.")
	end
	self.argent -= prix
	self.stock[idTissu] = (self.stock[idTissu] or 0) + dm
	local coupon = self.coupons[idTissu]
	if coupon then
		coupon.longueur += dm -- le rouleau se déroule plus loin pendant la découpe
	end
	return { ok = true, prix = prix }
end

-- Passe à la table de découpe : un rouleau par tissu, de la longueur en stock
function EtatAtelier:commencerDecoupe()
	if self.etape ~= "achat" then
		return refus("Ce n'est pas le moment de découper.")
	end
	for _, t in ipairs(self:tissusUtilises()) do
		if (self.stock[t] or 0) < 1 then
			return refus("Il te manque du tissu : " .. Catalogue.tissu(t).nom .. ".")
		end
	end
	self.coupons = {}
	for _, t in ipairs(self:tissusUtilises()) do
		self.coupons[t] = Coupon.nouveau(self.stock[t])
	end
	self.etape = "decoupe"
	return { ok = true }
end

-- placement = { x, y, angle } sur le rouleau du tissu choisi pour la pièce
function EtatAtelier:couper(idPiece, placement)
	if self.etape ~= "decoupe" then
		return refus("Ce n'est pas le moment de découper.")
	end
	if type(idPiece) ~= "string" or not table.find(self:piecesDuCroquis(), idPiece) then
		return refus("Cette pièce n'est pas dans le croquis.")
	end
	local coupon = self.coupons[self.tissus[idPiece]]
	local ok, erreur = coupon:poser(idPiece, placement)
	if not ok then
		return refus(erreur)
	end
	self.coupees[idPiece] = coupon.poses[idPiece]
	if #self:piecesAPoser() == 0 then
		consommer(self)
		self.etape = "epinglage"
	end
	return { ok = true, reste = #self:piecesAPoser() }
end

-- Abandonne la robe en cours (le tissu déjà coupé est perdu), garde la commande
function EtatAtelier:recommencer()
	if self.etape == "accueil" then
		return refus("Aucune commande en cours.")
	end
	consommer(self)
	self.croquis, self.tissus, self.coupees = nil, {}, {}
	self.etape = "carnet"
	return { ok = true }
end

return EtatAtelier
```

- [ ] **Step 4: Lancer les tests**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT"`
Expected:
```
Unitaires : 103538 vérifications
TOUT EST VERT : 0 vérifications
```

- [ ] **Step 5: Commit**

```bash
git add src/shared/EtatAtelier.luau tests/unitaires/14_etat_atelier.luau
git commit -m "Ajoute EtatAtelier : état et étapes de la commande en cours

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 3: Module `Metrage` (métrage conseillé)

**Files:**
- Create: `src/shared/Metrage.luau`
- Test: `tests/unitaires/15_metrage.luau`

**Interfaces:**
- Consumes: `Catalogue.piece`, `PLI`, `LARGEUR_ROULEAU` ; `Polygone.poser`, `centre`, `boite`.
- Produces :
  - `Metrage.MARGE = 0.1` ;
  - `Metrage.encombrement(idPiece, angle) -> (largeur, hauteur, dx, dy)` : boîte de la pièce tournée, et décalage du coin haut gauche au point de pose ;
  - `Metrage.disposition(ids) -> ({ [id] = { x, y, angle } }, longueur)` : une disposition valide pour `Coupon` ;
  - `Metrage.conseil(ids) -> integer`.

- [ ] **Step 1: Écrire les tests**

`tests/unitaires/15_metrage.luau` :

```lua
local Catalogue = U.module("Catalogue")
local Patron = U.module("Patron")
local Coupon = U.module("Coupon")
local Metrage = U.module("Metrage")

-- Pour chaque croquis possible, toutes les pièces dans un seul tissu : la disposition est acceptée par Coupon
local n = 0
for _, c in ipairs(Catalogue.variantesDe("corsage")) do
	for _, m in ipairs(Catalogue.variantesDe("manches")) do
		for _, k in ipairs(Catalogue.variantesDe("col")) do
			for _, j in ipairs(Catalogue.variantesDe("jupe")) do
				local ids = Patron.piecesDuCroquis({ corsage = c.id, manches = m.id, col = k.id, jupe = j.id })
				local placements, longueur = Metrage.disposition(ids)
				local coupon = Coupon.nouveau(longueur)
				for _, id in ipairs(ids) do
					local ok, erreur = coupon:poser(id, placements[id])
					U.verifier(ok, ("%s/%s/%s/%s : %s posée (%s)"):format(c.id, m.id, k.id, j.id, id, tostring(erreur)))
				end
				U.verifier(coupon:longueurUtilisee() == longueur, "la longueur conseillée est celle utilisée")
				U.verifier(longueur <= 40, "une robe tient dans 4 m de tissu")
				n += 1
			end
		end
	end
end
U.verifier(n == 108, "108 croquis vérifiés")

-- Droit-fil parfait : 0° pour une pièce normale, 45° pour une pièce en biais
local p = Metrage.disposition({ "jupe_evasee_devant", "corsage_droit_dos" })
U.verifier(p.jupe_evasee_devant.angle == 45 and p.corsage_droit_dos.angle == 0, "angles de droit-fil parfaits")

-- Cas simples
U.verifier(Metrage.conseil({ "jupe_droite_devant", "jupe_droite_dos" }) == 6, "deux jupes droites côte à côte : 6 dm")
U.verifier(Metrage.conseil({ "manche_longue" }) == 6, "une manche longue pliée : 6 dm")
local _, vide = Metrage.disposition({})
U.verifier(vide == 0, "aucune pièce : 0 dm")
```

- [ ] **Step 2: Vérifier qu'ils échouent**

Run: `bash tests/lancer.sh 2>&1 | grep -m1 "membre valide"`
Expected: `Metrage n'est pas un membre valide de Folder « Couture »`

- [ ] **Step 3: Écrire le module**

`src/shared/Metrage.luau` :

```lua
-- Metrage : disposition simple des pièces sur un rouleau (rangées de gauche à droite)
-- pour conseiller une longueur de tissu à l'achat. Le joueur reste libre de mieux ranger ses pièces.
local dossier = script.Parent
local Catalogue = require(dossier:WaitForChild("Catalogue"))
local Polygone = require(dossier:WaitForChild("Polygone"))

local Metrage = {}

local MARGE = 0.1 -- dm entre deux pièces
Metrage.MARGE = MARGE

-- Boîte de la pièce posée à l'angle donné : largeur, hauteur, et décalage entre le coin haut gauche
-- de la boîte et le point de pose (centre du patron)
function Metrage.encombrement(idPiece, angle)
	local def = Catalogue.piece(idPiece)
	local pose = Polygone.poser(def.contour, { x = 0, y = 0, angle = angle }, Polygone.centre(def.contour))
	local b = Polygone.boite(pose)
	return b.maxX - b.minX, b.maxY - b.minY, -b.minX, -b.minY
end

-- ids : pièces à couper dans un même tissu. Retourne { [id] = { x, y, angle } } et la longueur utilisée (dm entiers).
function Metrage.disposition(ids)
	local items = {}
	for _, id in ipairs(ids) do
		local def = Catalogue.piece(id)
		local angle = def.biais and 45 or 0 -- droit-fil parfait
		local l, h, dx, dy = Metrage.encombrement(id, angle)
		table.insert(items, { id = id, angle = angle, l = l, h = h, dx = dx, dy = dy, pliee = def.pliee })
	end
	table.sort(items, function(a, b)
		if a.h ~= b.h then
			return a.h > b.h
		end
		return a.id < b.id
	end)
	local placements = {}
	local y, hauteurRangee, x, bas = 0, 0, 0, 0
	local function nouvelleRangee()
		if hauteurRangee > 0 then
			y += hauteurRangee + MARGE
		end
		hauteurRangee, x = 0, 0
	end
	for _, it in ipairs(items) do
		if it.pliee then
			-- Pièce pliée : contre le pli, sur sa propre rangée (son symétrique occupe l'autre côté)
			nouvelleRangee()
			placements[it.id] = { x = Catalogue.PLI - MARGE / 2 - it.l + it.dx, y = y + it.dy, angle = it.angle }
			hauteurRangee = it.h
			bas = math.max(bas, y + it.h)
			nouvelleRangee()
		else
			if x + it.l > Catalogue.LARGEUR_ROULEAU then
				nouvelleRangee()
			end
			placements[it.id] = { x = x + it.dx, y = y + it.dy, angle = it.angle }
			x += it.l + MARGE
			hauteurRangee = math.max(hauteurRangee, it.h)
			bas = math.max(bas, y + it.h)
		end
	end
	return placements, math.ceil(bas - 1e-9)
end

-- Longueur conseillée (dm) pour couper ces pièces dans un même tissu
function Metrage.conseil(ids)
	local _, longueur = Metrage.disposition(ids)
	return longueur
end

return Metrage
```

- [ ] **Step 4: Lancer les tests**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT"`
Expected:
```
Unitaires : 104335 vérifications
TOUT EST VERT : 0 vérifications
```

- [ ] **Step 5: Commit**

```bash
git add src/shared/Metrage.luau tests/unitaires/15_metrage.luau
git commit -m "Ajoute Metrage : disposition simple et métrage conseillé

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 4: Silhouette du patron (`Pixels.silhouette`)

**Files:**
- Modify: `src/shared/Pixels.luau` (fonction ajoutée à la fin)
- Test: `tests/unitaires/07_pixels.luau` (tests ajoutés à la fin)

**Interfaces:**
- Consumes: `Pixels.taillePiece`, `Polygone.contient`, `Catalogue.piece`.
- Produces : `Pixels.silhouette(idPiece, plafond?) -> (buffer, largeur, hauteur)`, avec la même taille et le même repère que `Pixels.imagePiece`. Hors de la pièce : alpha 0 ; papier : (255, 248, 222) alpha 170 ; contour et flèche : (70, 50, 60) alpha 255. La flèche est en diagonale (45°) pour une pièce en biais.

- [ ] **Step 1: Ajouter les tests**

```diff
diff --git a/tests/unitaires/07_pixels.luau b/tests/unitaires/07_pixels.luau
index 1ecc8fb..85cf218 100644
--- a/tests/unitaires/07_pixels.luau
+++ b/tests/unitaires/07_pixels.luau
@@ -72,3 +72,20 @@ for k = 0, 160 * 192 - 1, 37 do
 	end
 end
 U.verifier(differents > 50, "la rotation de la pièce change l'image découpée")
+
+-- Silhouette du patron (table de découpe)
+local function alpha(buf, largeur, i, j)
+	return math.floor(buffer.readu32(buf, (j * largeur + i) * 4) / 16777216)
+end
+local sil, ls, hs = Pixels.silhouette("jupe_trapeze_devant")
+local lt, ht = Pixels.taillePiece("jupe_trapeze_devant")
+U.verifier(ls == lt and hs == ht, "silhouette de la même taille que l'image de la pièce")
+U.verifier(alpha(sil, ls, 2, 2) == 0, "hors de la pièce (coin coupé du trapèze) : transparent")
+U.verifier(alpha(sil, ls, math.floor(ls * 0.25), math.floor(hs * 0.5)) == 170, "dans la pièce : papier translucide")
+U.verifier(alpha(sil, ls, math.floor(ls / 2), math.floor(hs / 2)) == 255, "flèche de droit-fil au centre")
+U.verifier(alpha(sil, ls, 1, hs - 2) == 255, "contour foncé au bord")
+-- Pièce en biais : flèche en diagonale, pas de trait vertical au-dessus du centre
+local silB, lb, hb = Pixels.silhouette("jupe_evasee_devant")
+local cxB, cyB = math.floor(lb / 2), math.floor(hb / 2)
+U.verifier(alpha(silB, lb, cxB + 20, cyB + 20) == 255, "pièce en biais : flèche en diagonale")
+U.verifier(alpha(silB, lb, cxB, cyB - 40) == 170, "pièce en biais : pas de flèche verticale")
```

- [ ] **Step 2: Vérifier qu'ils échouent**

Run: `bash tests/lancer.sh 2>&1 | grep -m1 -E "ÉCHEC|attempt"`
Expected: une erreur « attempt to call a nil value » (`Pixels.silhouette` n'existe pas).

- [ ] **Step 3: Ajouter la fonction**

```diff
diff --git a/src/shared/Pixels.luau b/src/shared/Pixels.luau
index abde3bd..7532e22 100644
--- a/src/shared/Pixels.luau
+++ b/src/shared/Pixels.luau
@@ -141,4 +141,66 @@ function Pixels.imagePiece(motif, idPiece, placement, copie, plafond)
 	return buf, largeur, hauteur
 end
 
+
+---------------------------------------------------------------------------
+-- Silhouette d'un patron en papier (table de découpe) : papier translucide, contour foncé
+-- et flèche de droit-fil (en diagonale pour une pièce à couper dans le biais). Hors de la pièce : transparent.
+---------------------------------------------------------------------------
+local PAPIER = { 255, 248, 222, 170 }
+local TRAIT = { 70, 50, 60, 255 }
+
+local function empaqueterAlpha(r, g, b, a)
+	return r + g * 256 + b * 65536 + a * 16777216
+end
+
+local function distanceSegment(px, py, a, b)
+	local dx, dy = b.x - a.x, b.y - a.y
+	local l2 = dx * dx + dy * dy
+	local t = l2 > 0 and math.clamp(((px - a.x) * dx + (py - a.y) * dy) / l2, 0, 1) or 0
+	local qx, qy = a.x + t * dx - px, a.y + t * dy - py
+	return math.sqrt(qx * qx + qy * qy)
+end
+
+-- Retourne buffer, largeur, hauteur (même taille et même repère que imagePiece)
+function Pixels.silhouette(idPiece, plafond)
+	local def = Catalogue.piece(idPiece)
+	local largeur, hauteur, b = Pixels.taillePiece(idPiece, plafond)
+	local l, h = b.maxX - b.minX, b.maxY - b.minY
+	local dmParPx = l / largeur
+	local contour = def.contour
+	-- Flèche de droit-fil : direction dans le patron qui doit suivre la chaîne du tissu
+	local fx, fy = 0, 1
+	if def.biais then
+		fx, fy = math.sin(math.rad(45)), math.cos(math.rad(45))
+	end
+	local cx, cy = (b.minX + b.maxX) / 2, (b.minY + b.maxY) / 2
+	local demi = math.min(l, h) * 0.35
+	local fleche0 = { x = cx - fx * demi, y = cy - fy * demi }
+	local fleche1 = { x = cx + fx * demi, y = cy + fy * demi }
+	local pointe = demi * 0.25
+	local aile1 = { x = fleche1.x - (fx * 0.7 - fy * 0.7) * pointe, y = fleche1.y - (fy * 0.7 + fx * 0.7) * pointe }
+	local aile2 = { x = fleche1.x - (fx * 0.7 + fy * 0.7) * pointe, y = fleche1.y - (fy * 0.7 - fx * 0.7) * pointe }
+	local epaisseur = 1.5 * dmParPx
+	local buf = buffer.create(largeur * hauteur * 4)
+	for j = 0, hauteur - 1 do
+		local y = b.minY + (j + 0.5) / hauteur * h
+		for i = 0, largeur - 1 do
+			local x = b.minX + (i + 0.5) / largeur * l
+			local valeur = 0
+			if Polygone.contient(contour, x, y) then
+				local bord = math.huge
+				for k, a in ipairs(contour) do
+					bord = math.min(bord, distanceSegment(x, y, a, contour[k % #contour + 1]))
+				end
+				local fleche = math.min(distanceSegment(x, y, fleche0, fleche1), distanceSegment(x, y, fleche1, aile1),
+					distanceSegment(x, y, fleche1, aile2))
+				local c = (bord <= epaisseur or fleche <= epaisseur * 0.8) and TRAIT or PAPIER
+				valeur = empaqueterAlpha(c[1], c[2], c[3], c[4])
+			end
+			buffer.writeu32(buf, (j * largeur + i) * 4, valeur)
+		end
+	end
+	return buf, largeur, hauteur
+end
+
 return Pixels
```

- [ ] **Step 4: Lancer les tests**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT"`
Expected:
```
Unitaires : 104342 vérifications
TOUT EST VERT : 0 vérifications
```

- [ ] **Step 5: Commit**

```bash
git add src/shared/Pixels.luau tests/unitaires/07_pixels.luau
git commit -m "Pixels : silhouette du patron en papier pour la table de découpe

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 5: `Session` et logique de la table de découpe

**Files:**
- Create: `src/client/Atelier/Session.luau`
- Create: `src/client/Atelier/TableDecoupe.luau`
- Test: `tests/unitaires/16_table_decoupe.luau`

**Interfaces:**
- Consumes: `EtatAtelier.*` ; `Catalogue` ; `Notation.aimanter`, `droitFil`, `angleFil` ; `Metrage.encombrement`, `MARGE` ; `Coupon.contoursPoses`, `coupon:verifier` ; `Polygone.boite`.
- Produces :
  - `Session.nouvelle(graine?) -> session`, avec `session.etat` (EtatAtelier) et `session:surChangement(f) -> desabonner`. Actions (même réponse qu'EtatAtelier ; les écouteurs sont appelés après chaque succès) : `nouvelleCommande()`, `validerCroquis(croquis, tissus)`, `retourCarnet()`, `acheter(idTissu, dm)`, `commencerDecoupe()`, `couper(idPiece, placement)`, `recommencer()` ;
  - `TableDecoupe.nouvelle(etat) -> table`, avec les champs `tissu`, `selection`, `placement = { x, y, angle }`. Méthodes : `piecesRestantes(idTissu?)`, `onglets() -> { { tissu, reste } }`, `coupon()`, `choisirTissu(id)`, `selectionner(idPiece)`, `proposer()`, `deplacer(x, y)` (bornée au rouleau), `tourner(degres)` (aimantée), `etatPlacement() -> { valide, erreur?, droitFil }`, `couper(session) -> reponse` (sélectionne ensuite la pièce suivante, puis le tissu suivant).

- [ ] **Step 1: Écrire les tests**

`tests/unitaires/16_table_decoupe.luau` :

```lua
local Session = U.module("Session")
local TableDecoupe = U.module("TableDecoupe")

-- Robe en deux tissus : corsage en soie (avec manches ballon pliées), jupe évasée en biais en coton
local session = Session.nouvelle(11)
session:nouvelleCommande()
local croquis = { corsage = "corsage_droit", manches = "manches_ballon", col = "col_sans", jupe = "jupe_evasee" }
local tissus = {
	corsage_droit_devant = "soie_rouge",
	corsage_droit_dos = "soie_rouge",
	manche_ballon = "soie_rouge",
	jupe_evasee_devant = "coton_blanc",
	jupe_evasee_dos = "coton_blanc",
}
U.verifier(session:validerCroquis(croquis, tissus).ok, "croquis validé")
session.etat.argent = 1000
U.verifier(session:acheter("soie_rouge", 12).ok and session:acheter("coton_blanc", 30).ok, "tissus achetés")
U.verifier(session:commencerDecoupe().ok, "à la table de découpe")

local t = TableDecoupe.nouvelle(session.etat)
U.verifier(t.tissu == "soie_rouge" and t.selection ~= nil, "premier tissu et première pièce sélectionnés")
local onglets = t:onglets()
U.verifier(#onglets == 2 and onglets[1].reste == 3 and onglets[2].reste == 2, "onglets : 3 pièces en soie, 2 en coton")
U.verifier(t:etatPlacement().valide and t:etatPlacement().droitFil == 1, "place proposée valide, droit-fil parfait")

-- Rotation et aimantation
local angle0 = t.placement.angle
t:tourner(4)
U.verifier(t.placement.angle == angle0 % 360, "4° : aimanté au droit-fil")
t:tourner(40)
U.verifier(t:etatPlacement().droitFil < 1, "40° : droit-fil dégradé")
t:tourner(-40)
U.verifier(t:etatPlacement().droitFil == 1, "retour au droit-fil")

-- Déplacement hors du rouleau et position bornée
t:deplacer(-50, 3)
U.verifier(t.placement.x == 0 and not t:etatPlacement().valide, "déplacée contre le bord : pièce qui dépasse, refusée")
U.verifier(t:etatPlacement().erreur ~= nil, "message d'erreur fourni")
t:proposer()
U.verifier(t:etatPlacement().valide, "nouvelle proposition valide")

-- Couper toutes les pièces : la table passe d'elle-même à la pièce et au tissu suivants
local coupes = 0
while session.etat.etape == "decoupe" and coupes < 10 do
	local r = t:couper(session)
	U.verifier(r.ok, "coupe " .. (coupes + 1) .. " : " .. tostring(r.erreur))
	coupes += 1
end
U.verifier(coupes == 5 and session.etat.etape == "epinglage", "5 pièces coupées, direction l'épinglage")
U.verifier(t.selection == nil, "plus rien à sélectionner")
U.verifier(not t:couper(session).ok, "rien à couper")

-- La jupe en biais a été proposée à 45°
U.verifier(session.etat.coupees.jupe_evasee_devant.angle == 45, "jupe en biais coupée à 45°")

-- Place proposée : la première place libre en haut du rouleau, à côté des pièces déjà coupées
local s2 = Session.nouvelle(12)
s2:nouvelleCommande()
s2:validerCroquis({ corsage = "corsage_droit", manches = "manches_sans", col = "col_sans", jupe = "jupe_droite" }, {
	corsage_droit_devant = "lin_bleu",
	corsage_droit_dos = "lin_bleu",
	jupe_droite_devant = "lin_bleu",
	jupe_droite_dos = "lin_bleu",
})
s2:acheter("lin_bleu", 11)
s2:commencerDecoupe()
local t2 = TableDecoupe.nouvelle(s2.etat)
t2:selectionner("corsage_droit_devant")
U.verifier(t2.placement.y < 3, "la première pièce est proposée en haut du rouleau")
U.verifier(t2:couper(s2).ok, "corsage devant coupé")
t2:selectionner("corsage_droit_dos")
U.verifier(t2.placement.y < 3 and t2.placement.x > 4.8, "le dos est proposé à droite du devant, pas en dessous")
U.verifier(t2:couper(s2).ok, "corsage dos coupé")
t2:selectionner("jupe_droite_devant")
U.verifier(t2:couper(s2).ok, "jupe devant coupée à la place proposée")
t2:selectionner("jupe_droite_dos")
U.verifier(t2:couper(s2).ok and s2.etat.etape == "epinglage", "toute la robe tient dans les 11 dm conseillés en suivant les propositions")

-- Une pièce pliée est proposée contre le pli (son symétrique de l'autre côté), pas contre le bord
local s3 = Session.nouvelle(13)
s3:nouvelleCommande()
s3:validerCroquis({ corsage = "corsage_droit", manches = "manches_ballon", col = "col_sans", jupe = "jupe_droite" }, {
	corsage_droit_devant = "lin_bleu",
	corsage_droit_dos = "lin_bleu",
	manche_ballon = "lin_bleu",
	jupe_droite_devant = "lin_bleu",
	jupe_droite_dos = "lin_bleu",
})
s3:acheter("lin_bleu", 20)
s3:commencerDecoupe()
local t3 = TableDecoupe.nouvelle(s3.etat)
t3:selectionner("manche_ballon")
local Coupon = U.module("Coupon")
local Polygone = U.module("Polygone")
local boite = Polygone.boite(Coupon.contoursPoses("manche_ballon", t3.placement)[1])
U.verifier(boite.maxX > 6.8 and boite.maxX <= 7, ("manche pliée proposée contre le pli (bord droit à %.2f dm)"):format(boite.maxX))
```

- [ ] **Step 2: Vérifier qu'ils échouent**

Run: `bash tests/lancer.sh 2>&1 | grep -m1 "membre valide"`
Expected: `Session n'est pas un membre valide de Folder « Couture »`

- [ ] **Step 3: Écrire `Session`**

`src/client/Atelier/Session.luau` :

```lua
-- Session : accès de l'interface à l'état de l'atelier.
-- Plan 3 : l'état vit dans le client (EtatAtelier en local). Plan 4 : même interface, mais chaque
-- action passe par le serveur. Les écrans ne parlent qu'à la Session, jamais à EtatAtelier directement.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Couture = ReplicatedStorage:WaitForChild("Couture")
local EtatAtelier = require(Couture:WaitForChild("EtatAtelier"))

local Session = {}
Session.__index = Session

-- graine : pour des commandes reproductibles (tests) ; sinon aléatoire
function Session.nouvelle(graine)
	local self = setmetatable({ etat = EtatAtelier.nouveau(), rng = Random.new(graine), ecouteurs = {} }, Session)
	return self
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

local function agir(self, nom, ...)
	local reponse = self.etat[nom](self.etat, ...)
	if reponse.ok then
		for _, f in ipairs(table.clone(self.ecouteurs)) do
			f(self.etat)
		end
	end
	return reponse
end

function Session:nouvelleCommande()
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
function Session:recommencer()
	return agir(self, "recommencer")
end

return Session
```

- [ ] **Step 4: Écrire `TableDecoupe`**

`src/client/Atelier/TableDecoupe.luau` :

```lua
-- TableDecoupe : logique de la table de découpe (sans affichage), testable seule.
-- Garde le tissu en cours, la pièce sélectionnée et sa position (x, y, angle) sur le rouleau.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Couture = ReplicatedStorage:WaitForChild("Couture")
local Catalogue = require(Couture:WaitForChild("Catalogue"))
local Notation = require(Couture:WaitForChild("Notation"))
local Metrage = require(Couture:WaitForChild("Metrage"))
local Coupon = require(Couture:WaitForChild("Coupon"))
local Polygone = require(Couture:WaitForChild("Polygone"))

local TableDecoupe = {}
TableDecoupe.__index = TableDecoupe

-- etat : EtatAtelier à l'étape « decoupe »
function TableDecoupe.nouvelle(etat)
	local self = setmetatable({ etat = etat, tissu = nil, selection = nil, placement = nil }, TableDecoupe)
	self:choisirTissu(etat:tissusUtilises()[1])
	return self
end

-- Pièces du tissu en cours qui restent à couper
function TableDecoupe:piecesRestantes(idTissu)
	local out = {}
	for _, id in ipairs(self.etat:piecesAPoser()) do
		if self.etat.tissus[id] == (idTissu or self.tissu) then
			table.insert(out, id)
		end
	end
	return out
end

-- Onglets : { { tissu, reste } } pour chaque tissu du croquis
function TableDecoupe:onglets()
	local out = {}
	for _, t in ipairs(self.etat:tissusUtilises()) do
		table.insert(out, { tissu = t, reste = #self:piecesRestantes(t) })
	end
	return out
end

function TableDecoupe:coupon()
	return self.etat.coupons[self.tissu]
end

function TableDecoupe:choisirTissu(idTissu)
	self.tissu = idTissu
	self:selectionner(self:piecesRestantes()[1])
end

-- Sélectionne une pièce et la pose à la place proposée
function TableDecoupe:selectionner(idPiece)
	self.selection = idPiece
	self.placement = nil
	if idPiece then
		self:proposer()
	end
end

-- Place proposée : la première place libre, du haut du rouleau vers le bas puis de gauche à droite,
-- contre les bords des pièces déjà coupées, au droit-fil parfait. À défaut : sous tout le reste.
function TableDecoupe:proposer()
	local id = self.selection
	if not id then
		return
	end
	local def = Catalogue.piece(id)
	local angle = def.biais and 45 or 0
	local l, h, dx, dy = Metrage.encombrement(id, angle)
	local coupon = self:coupon()
	local limiteX = def.pliee and Catalogue.PLI - Metrage.MARGE / 2 or Catalogue.LARGEUR_ROULEAU
	local xs, ys = { 0 }, { 0 }
	local bas = 0
	for idCoupee, pose in pairs(coupon.poses) do
		for _, contour in ipairs(Coupon.contoursPoses(idCoupee, pose)) do
			local b = Polygone.boite(contour)
			table.insert(xs, b.maxX + Metrage.MARGE)
			table.insert(ys, b.maxY + Metrage.MARGE)
			bas = math.max(bas, b.maxY + Metrage.MARGE)
		end
	end
	table.sort(xs)
	table.sort(ys)
	if def.pliee then
		table.insert(xs, 1, limiteX - l) -- une pièce pliée se pose d'abord contre le pli
	end
	for _, y in ipairs(ys) do
		for _, x in ipairs(xs) do
			if x + l <= limiteX + 1e-9 then
				local placement = { x = x + dx, y = y + dy, angle = angle }
				if coupon:verifier(id, placement) then
					self.placement = placement
					return
				end
			end
		end
	end
	local x = def.pliee and limiteX - l or 0
	self.placement = { x = x + dx, y = bas + dy, angle = angle }
end

function TableDecoupe:deplacer(x, y)
	if self.placement then
		local longueur = self:coupon().longueur
		self.placement.x = math.clamp(x, 0, Catalogue.LARGEUR_ROULEAU)
		self.placement.y = math.clamp(y, 0, longueur)
	end
end

-- Tourne de « degres » puis aligne sur le droit-fil s'il est à moins de 6°
function TableDecoupe:tourner(degres)
	if self.placement then
		local angle = (self.placement.angle + degres) % 360
		self.placement.angle = Notation.aimanter(angle, self.selection) % 360
	end
end

-- { valide, erreur, droitFil (0 à 1) } pour la pièce sélectionnée à sa place actuelle
function TableDecoupe:etatPlacement()
	if not self.placement then
		return { valide = false, erreur = "Aucune pièce sélectionnée.", droitFil = 0 }
	end
	local ok, erreur = self:coupon():verifier(self.selection, self.placement)
	local def = Catalogue.piece(self.selection)
	local droitFil = Notation.droitFil(Notation.angleFil(self.placement.angle, self.selection), def.biais)
	return { valide = ok, erreur = erreur, droitFil = droitFil }
end

-- Coupe la pièce sélectionnée ; en cas de succès, sélectionne la suivante (ou passe au tissu suivant)
function TableDecoupe:couper(session)
	if not self.placement then
		return { ok = false, erreur = "Aucune pièce sélectionnée." }
	end
	local reponse = session:couper(self.selection, table.clone(self.placement))
	if reponse.ok then
		if self.etat.etape ~= "decoupe" then
			self.selection, self.placement = nil, nil
		elseif #self:piecesRestantes() > 0 then
			self:selectionner(self:piecesRestantes()[1])
		else
			for _, o in ipairs(self:onglets()) do
				if o.reste > 0 then
					self:choisirTissu(o.tissu)
					break
				end
			end
		end
	end
	return reponse
end

return TableDecoupe
```

- [ ] **Step 5: Lancer les tests**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT"`
Expected:
```
Unitaires : 104370 vérifications
TOUT EST VERT : 0 vérifications
```

- [ ] **Step 6: Commit**

```bash
git add src/client/Atelier/Session.luau src/client/Atelier/TableDecoupe.luau tests/unitaires/16_table_decoupe.luau
git commit -m "Ajoute Session et la logique de la table de découpe

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 6: Interface du nouvel atelier et scénario complet

**Files:**
- Create: `src/client/Atelier/Vignettes.luau`
- Create: `src/client/Atelier/init.client.luau`
- Create: `src/client/Atelier/EcranAccueil.luau`
- Create: `src/client/Atelier/EcranCarnet.luau`
- Create: `src/client/Atelier/EcranAchat.luau`
- Create: `src/client/Atelier/EcranDecoupe.luau`
- Create: `src/client/Atelier/EcranSuite.luau`
- Modify: `tests/scenario.luau` (réécriture : scénario complet)

**Interfaces:**
- Consumes: `UiKit`, `Session`, `TableDecoupe` (tâches 1 et 5) ; `Catalogue`, `Patron`, `Notation`, `Polygone`, `Metrage`, `EtatAtelier`, `Pixels`, `Editables`.
- Produces :
  - `Vignettes.motif(idTissu) -> Content?` et `Vignettes.silhouette(idPiece) -> Content?` (en cache) ;
  - chaque module `Ecran…` est une fonction `(ctx) -> fermer`, avec `ctx = { session, contenu: Frame, message: (texte, couleur?) -> (), UiKit }` ;
  - noms stables utilisés par le scénario et par la vérification dans Studio :
    - fenêtre : `PlayerGui.Atelier.Fenetre` (`Titre`, `Argent`, `Fermer`, `Contenu`, `Message`) et bouton `OuvrirAtelier` ;
    - accueil : `Clochette` ;
    - carnet : `Gauche.Variante_<id>`, `Gauche.Pieces.Tissu_<idPiece>`, `Gauche.Pieces.ToutEnUnTissu`, `Droite.Jauge_<style>.Acquis`, `Droite.Exigence<i>`, `ChoixTissu.Filtre_<style|tous>`, `ChoixTissu.Grille.Tissu_<idTissu>`, `Valider` ;
    - achat : `Ligne_<idTissu>` (`Moins`, `Quantite`, `Plus`, `Cout`, `Acheter`), `RetourCarnet`, `AllerDecoupe` ;
    - découpe : `Rouleau.Tissu` (`PieceCourante`, `Coupees`, `Pli`), `Panneau` (`Onglets`, `ListePieces`, `DroitFil`, `Statut`, `Tourner-15`, `Tourner-1`, `Tourner1`, `Tourner15`, `Proposer`, `PlusDeTissu`, `Couper`, `Recommencer`) ;
    - suite : `Recommencer`.

- [ ] **Step 1: Écrire le scénario complet**

`tests/scenario.luau` :

```lua
-- Scénario du nouvel atelier : une commande jouée de bout en bout en cliquant dans l'interface
-- (accueil → carnet → achat → découpe → écran de suite), comme le ferait un joueur.
local nbVerifs = 0
local function verifier(condition, message)
	nbVerifs += 1
	if not condition then
		error("ÉCHEC : " .. message, 2)
	end
end

---------------------------------------------------------------------------
-- Démarrage : modules partagés, joueur, script du client
---------------------------------------------------------------------------
local game = M.initialiser()
local RS = M.services.ReplicatedStorage
local dossier = M.nouvelleInstance("Folder")
dossier.Name = "Couture"
dossier.Parent = RS
for _, nom in ipairs(NOMS_PARTAGES) do
	local ms = M.nouvelleInstance("ModuleScript")
	ms.Name = nom
	ms.Parent = dossier
end
local joueur = M.nouveauJoueur("Testeur")
rawget(M.services.Players, "__props").LocalPlayer = joueur
M.joueurLocal = joueur
local scriptClient = M.nouvelleInstance("LocalScript")
scriptClient.Name = "Atelier"
for _, nom in ipairs(NOMS_CLIENT) do
	local ms = M.nouvelleInstance("ModuleScript")
	ms.Name = nom
	ms.Parent = scriptClient
end
SCRIPTS.Atelier(scriptClient)
local Catalogue = requireModule(dossier.Catalogue)

local gui = joueur.PlayerGui
local fenetre = gui.Atelier.Fenetre

---------------------------------------------------------------------------
-- Outils d'interface
---------------------------------------------------------------------------
local function estVisible(inst)
	local i = inst
	while i and i ~= gui do
		if i:IsA("GuiObject") and not i.Visible then
			return false
		end
		i = i.Parent
	end
	return true
end
local function boutonNomme(nom)
	local trouves = {}
	for _, d in ipairs(gui:GetDescendants()) do
		if d:IsA("GuiButton") and d.Name == nom and estVisible(d) then
			table.insert(trouves, d)
		end
	end
	verifier(#trouves == 1, ("un seul bouton « %s » visible (trouvé %d)"):format(nom, #trouves))
	return trouves[1]
end
local function cliquer(nom)
	M.avancer(0.1)
	boutonNomme(nom).Activated:Fire()
end
local function texte(nomOuMotif)
	for _, d in ipairs(gui:GetDescendants()) do
		if d:IsA("TextLabel") and estVisible(d) and (d.Name == nomOuMotif or string.find(d.Text, nomOuMotif, 1, true)) then
			return d
		end
	end
	return nil
end
local function titre()
	return fenetre.Titre.Text
end
local function argent()
	return tonumber(fenetre.Argent.Text:match("^(%d+)"))
end

---------------------------------------------------------------------------
-- Accueil
---------------------------------------------------------------------------
verifier(fenetre.Visible, "la fenêtre s'ouvre au démarrage")
verifier(titre() == "Atelier de couture", "écran d'accueil")
verifier(argent() == 150, "150 pièces d'or au départ")
cliquer("Fermer")
verifier(not fenetre.Visible, "la croix ferme la fenêtre")
cliquer("OuvrirAtelier")
verifier(fenetre.Visible, "le bouton Atelier rouvre la fenêtre")
cliquer("Clochette")

---------------------------------------------------------------------------
-- Carnet de croquis
---------------------------------------------------------------------------
verifier(titre() == "1. Carnet de croquis", "la clochette ouvre le carnet")
verifier(texte("La cliente (taille") ~= nil, "la taille de la cliente est affichée")
verifier(texte("Exigence1") ~= nil and texte("Exigence1").Text ~= "", "les exigences sont affichées")
-- Robe : décolleté en V, manches ballon, col Claudine, jupe trapèze
for _, v in ipairs({ "corsage_v", "manches_ballon", "col_claudine", "jupe_trapeze" }) do
	cliquer("Variante_" .. v)
	verifier(boutonNomme("Variante_" .. v).BackgroundColor3 == Color3.fromRGB(214, 76, 128), v .. " en surbrillance")
end
local pieces = fenetre.Contenu.Gauche.Pieces
local nbBoutonsTissu = 0
for _, d in ipairs(pieces:GetChildren()) do
	if d.Name:sub(1, 6) == "Tissu_" then
		nbBoutonsTissu += 1
	end
end
verifier(nbBoutonsTissu == 6, "6 pièces à habiller de tissu (obtenu " .. nbBoutonsTissu .. ")")
cliquer("Valider")
verifier(titre() == "1. Carnet de croquis" and fenetre.Message.Visible, "valider sans tissu : message d'erreur")

-- Choix d'un tissu : filtre « Romantique », soie rose fleurie pour le corsage, puis pour toute la robe
local jaugeAvant = fenetre.Contenu.Droite.Jauge_romantique.Acquis.Size
cliquer("Tissu_corsage_v_devant")
verifier(fenetre.Contenu:FindFirstChild("ChoixTissu") ~= nil, "le choix du tissu s'ouvre")
cliquer("Filtre_gothique")
local grille = fenetre.Contenu.ChoixTissu.Grille
verifier(grille:FindFirstChild("Tissu_velours_noir") ~= nil and grille:FindFirstChild("Tissu_coton_blanc") == nil, "filtre gothique : velours noir, pas de coton blanc")
cliquer("Filtre_romantique")
cliquer("Tissu_soie_rose_fleurs")
verifier(fenetre.Contenu:FindFirstChild("ChoixTissu") == nil, "le choix du tissu se ferme")
verifier(texte("Soie rose fleurie") ~= nil, "le corsage devant est en soie rose fleurie")
cliquer("ToutEnUnTissu")
local nbSoie = 0
for _, d in ipairs(pieces:GetChildren()) do
	if d:IsA("TextLabel") and d.Text == "Soie rose fleurie" then
		nbSoie += 1
	end
end
verifier(nbSoie == 6, "toute la robe en soie rose fleurie")
local jaugeApres = fenetre.Contenu.Droite.Jauge_romantique.Acquis.Size
verifier(jaugeApres.X.Scale > jaugeAvant.X.Scale, "la jauge Romantique monte avec la soie")
cliquer("Valider")

---------------------------------------------------------------------------
-- Achat
---------------------------------------------------------------------------
verifier(titre() == "2. Achat du tissu", "le croquis validé mène à l'achat")
local ligne = fenetre.Contenu:FindFirstChild("Ligne_soie_rose_fleurs")
verifier(ligne ~= nil and #fenetre.Contenu:GetChildren() >= 3, "une ligne par tissu du croquis")
local quantite = tonumber(ligne.Quantite.Text:match("^(%d+)"))
verifier(quantite and quantite > 0, "quantité conseillée pré-remplie")
cliquer("Plus")
verifier(tonumber(ligne.Quantite.Text:match("^(%d+)")) == quantite + 1, "le bouton + ajoute 1 dm")
cliquer("Moins")
cliquer("AllerDecoupe")
verifier(titre() == "2. Achat du tissu" and fenetre.Message.Visible, "découpe refusée sans tissu")
local avant = argent()
cliquer("Acheter")
verifier(argent() < avant, "l'achat débite l'argent")
verifier(texte("En stock : " .. quantite .. " dm") ~= nil, "le stock est mis à jour")
cliquer("AllerDecoupe")

---------------------------------------------------------------------------
-- Table de découpe
---------------------------------------------------------------------------
verifier(titre() == "3. Table de découpe", "l'achat mène à la découpe")
local panneau = fenetre.Contenu.Panneau
verifier(panneau.DroitFil.Text == "Droit-fil : 100 %", "pièce proposée au droit-fil")
cliquer("Tourner15")
verifier(panneau.DroitFil.Text ~= "Droit-fil : 100 %", "tourner de 15° dégrade le droit-fil")
cliquer("Tourner-15")
verifier(panneau.DroitFil.Text == "Droit-fil : 100 %", "retour au droit-fil")
verifier(fenetre.Contenu.Rouleau.Tissu.PieceCourante.Visible, "la pièce courante est affichée sur le rouleau")
local coupes, essais = 0, 0
while titre() == "3. Table de découpe" and essais < 20 do
	essais += 1
	if panneau.Statut.Text ~= "Place libre : tu peux couper." then
		cliquer("PlusDeTissu") -- plus assez de rouleau : on en rachète, puis on redemande une place
		cliquer("Proposer")
	else
		local restantes = #panneau.ListePieces:GetChildren()
		cliquer("Couper")
		if titre() ~= "3. Table de découpe" or #panneau.ListePieces:GetChildren() < restantes then
			coupes += 1
		end
		if titre() == "3. Table de découpe" then
			verifier(#fenetre.Contenu.Rouleau.Tissu.Coupees:GetChildren() >= 1, "les pièces coupées restent visibles")
			verifier(panneau.Statut.Text ~= "Cette pièce est déjà coupée.", "après une coupe, la pièce suivante est affichée")
		end
	end
end
verifier(coupes == 6, "6 pièces coupées (manche et col pliés comptent pour une coupe chacun) : " .. coupes)

---------------------------------------------------------------------------
-- Suite et recommencer
---------------------------------------------------------------------------
verifier(titre() == "Toutes les pièces sont coupées !", "écran de suite après la dernière coupe")
cliquer("Recommencer")
verifier(titre() == "1. Carnet de croquis", "recommencer ramène au carnet avec la même commande")

print(("TOUT EST VERT : %d vérifications"):format(nbVerifs))
```

- [ ] **Step 2: Vérifier qu'il échoue**

Run: `bash tests/lancer.sh 2>&1 | grep -m1 -E "ÉCHEC|attempt"`
Expected: une erreur « attempt to call a nil value » (`SCRIPTS.Atelier` n'existe pas encore).

- [ ] **Step 3: Écrire `Vignettes`**

`src/client/Atelier/Vignettes.luau` :

```lua
-- Vignettes : images de l'interface (motif d'un tissu, silhouette d'un patron), converties en contenu
-- statique et gardées en cache. Si la mémoire des images est pleine : nil (l'écran affiche une couleur).
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Couture = ReplicatedStorage:WaitForChild("Couture")
local Catalogue = require(Couture:WaitForChild("Catalogue"))
local Pixels = require(Couture:WaitForChild("Pixels"))
local Editables = require(Couture:WaitForChild("Editables"))

local Vignettes = {}

local cache = {}

local function figerBuffer(cle, buf, largeur, hauteur)
	if cache[cle] ~= nil then
		return cache[cle] or nil
	end
	local image = Editables.image(buf, largeur, hauteur)
	local contenu = image and Editables.figer(image)
	if image then
		image:Destroy()
	end
	cache[cle] = contenu or false
	return contenu
end

-- Motif répétable du tissu (256 × 256, soit 8 dm de tissu)
function Vignettes.motif(idTissu)
	if cache["motif:" .. idTissu] ~= nil then
		return cache["motif:" .. idTissu] or nil
	end
	return figerBuffer("motif:" .. idTissu, Pixels.motif(idTissu), Catalogue.TAILLE_MOTIF, Catalogue.TAILLE_MOTIF)
end

-- Silhouette en papier d'une pièce de patron (transparente hors de la pièce)
function Vignettes.silhouette(idPiece)
	if cache["silhouette:" .. idPiece] ~= nil then
		return cache["silhouette:" .. idPiece] or nil
	end
	local buf, l, h = Pixels.silhouette(idPiece, 128)
	return figerBuffer("silhouette:" .. idPiece, buf, l, h)
end

return Vignettes
```

- [ ] **Step 4: Écrire les écrans simples**

`src/client/Atelier/EcranAccueil.luau` :

```lua
-- Écran d'accueil : la clochette du comptoir fait entrer une cliente et crée la commande.
return function(ctx)
	local UiKit = ctx.UiKit
	UiKit.texte({
		Text = "Bienvenue dans ton atelier ! Une cliente attend à la porte. Fais sonner la clochette pour "
			.. "prendre sa commande : tu dessineras la robe dans ton carnet, tu achèteras le tissu, "
			.. "puis tu découperas les pièces du patron.",
		TextSize = 18,
		Size = UDim2.new(1, 0, 0, 90),
		Parent = ctx.contenu,
	})
	UiKit.bouton({
		Name = "Clochette",
		Text = "Sonner la clochette",
		Position = UDim2.fromOffset(0, 110),
		Size = UDim2.fromOffset(260, 50),
		Parent = ctx.contenu,
	}, function()
		local r = ctx.session:nouvelleCommande()
		if not r.ok then
			ctx.message(r.erreur, UiKit.COULEURS.erreur)
		end
	end)
	return function() end
end
```

`src/client/Atelier/EcranSuite.luau` :

```lua
-- Écran provisoire après la découpe : l'épinglage, la couture, les décorations et la livraison
-- arrivent au plan 3b. On peut recommencer une robe pour la même commande.
return function(ctx)
	local UiKit = ctx.UiKit
	UiKit.texte({
		Text = "Bravo, toutes les pièces sont coupées ! La suite (épinglage sur le mannequin, couture, "
			.. "décorations et livraison) arrive bientôt.",
		TextSize = 18,
		Size = UDim2.new(1, 0, 0, 70),
		Parent = ctx.contenu,
	})
	UiKit.boutonDoux({
		Name = "Recommencer",
		Text = "Recommencer une robe",
		Position = UDim2.fromOffset(0, 90),
		Size = UDim2.fromOffset(260, 46),
		Parent = ctx.contenu,
	}, function()
		local r = ctx.session:recommencer()
		if not r.ok then
			ctx.message(r.erreur, UiKit.COULEURS.erreur)
		end
	end)
	return function() end
end
```

- [ ] **Step 5: Écrire le carnet de croquis**

`src/client/Atelier/EcranCarnet.luau` :

```lua
-- Écran du carnet de croquis : variantes des 4 familles, tissu de chaque pièce, jauges de style
-- et exigences de la cliente mises à jour en direct.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Couture = ReplicatedStorage:WaitForChild("Couture")
local Catalogue = require(Couture:WaitForChild("Catalogue"))
local Patron = require(Couture:WaitForChild("Patron"))
local Notation = require(Couture:WaitForChild("Notation"))
local Vignettes = require(script.Parent:WaitForChild("Vignettes"))

local NOMS_FAMILLES = { corsage = "Corsage", manches = "Manches", col = "Col", jupe = "Jupe" }
local CROQUIS_DEPART = { corsage = "corsage_droit", manches = "manches_sans", col = "col_sans", jupe = "jupe_droite" }

-- État d'une exigence d'après la fourchette du carnet : "ok", "non" ou "?" (dépend de la suite)
local function statutExigence(e, fourchette, croquis, tissus)
	if e.type == "min" then
		local f = fourchette[e.style]
		return f.min >= e.valeur and "ok" or (f.max < e.valeur and "non" or "?")
	elseif e.type == "max" then
		local f = fourchette[e.style]
		return f.max <= e.valeur and "ok" or (f.min > e.valeur and "non" or "?")
	elseif e.type == "teinte" then
		local parTeinte, total = {}, 0
		for _, id in ipairs(Patron.piecesDuCroquis(croquis)) do
			if not tissus[id] then
				return "?"
			end
			local t = Catalogue.tissu(tissus[id]).teinte
			parTeinte[t] = (parTeinte[t] or 0) + Patron.aire(id)
			total += Patron.aire(id)
		end
		local meilleure, aire = nil, -1
		for t, a in pairs(parTeinte) do
			if a > aire then
				meilleure, aire = t, a
			end
		end
		return meilleure == e.teinte and "ok" or "non"
	end
	return "?" -- qualité (à la couture) et accessoire (aux décorations)
end

return function(ctx)
	local UiKit, session, contenu = ctx.UiKit, ctx.session, ctx.contenu
	local C = UiKit.COULEURS
	local etat = session.etat
	local croquis = table.clone(etat.croquis or CROQUIS_DEPART)
	local tissus = table.clone(etat.tissus or {})
	local dernierTissu = nil
	local rafraichir

	-- Colonne de gauche : variantes, puis pièces et tissus
	local gauche = UiKit.creer("Frame", { Name = "Gauche", BackgroundTransparency = 1, Size = UDim2.new(0, 540, 1, -56), Parent = contenu })
	local boutonsVariantes = {}
	for i, famille in ipairs(Catalogue.FAMILLES) do
		local y = (i - 1) * 46
		UiKit.texte({ Text = NOMS_FAMILLES[famille], Font = Enum.Font.GothamBold, Position = UDim2.fromOffset(0, y + 8), Size = UDim2.fromOffset(90, 24), Parent = gauche })
		for k, v in ipairs(Catalogue.variantesDe(famille)) do
			boutonsVariantes[v.id] = UiKit.boutonDoux({
				Name = "Variante_" .. v.id,
				Text = v.nom,
				TextSize = 14,
				Position = UDim2.fromOffset(90 + (k - 1) * 112, y),
				Size = UDim2.fromOffset(106, 38),
				Parent = gauche,
			}, function()
				croquis[famille] = v.id
				rafraichir()
			end)
		end
	end
	local listePieces = UiKit.creer("Frame", { Name = "Pieces", BackgroundTransparency = 1, Position = UDim2.fromOffset(0, 190), Size = UDim2.new(1, 0, 1, -190), Parent = gauche })

	-- Colonne de droite : commande, exigences, jauges
	local droite = UiKit.arrondir(UiKit.creer("Frame", { Name = "Droite", BackgroundColor3 = C.panneau, Position = UDim2.new(1, -310, 0, 0), Size = UDim2.new(0, 310, 1, -56), Parent = contenu }), 10)
	UiKit.texte({ Text = ("La cliente (taille %s) veut :"):format(etat.commande.taille), Font = Enum.Font.GothamBold, Position = UDim2.fromOffset(12, 8), Size = UDim2.new(1, -24, 0, 22), Parent = droite })
	local lignesExigences = {}
	for i, e in ipairs(etat.commande.exigences) do
		lignesExigences[i] = UiKit.texte({ Name = "Exigence" .. i, TextSize = 14, Position = UDim2.fromOffset(12, 10 + i * 22), Size = UDim2.new(1, -24, 0, 20), Parent = droite })
	end
	local jauges = {}
	local y0 = 30 + #etat.commande.exigences * 22 + 12
	for i, style in ipairs(Catalogue.STYLES) do
		local y = y0 + (i - 1) * 30
		UiKit.texte({ Text = Catalogue.NOMS_STYLES[style], TextSize = 14, Position = UDim2.fromOffset(12, y), Size = UDim2.fromOffset(100, 20), Parent = droite })
		local fond = UiKit.arrondir(UiKit.creer("Frame", { Name = "Jauge_" .. style, BackgroundColor3 = C.secondaire, Position = UDim2.fromOffset(112, y + 4), Size = UDim2.fromOffset(180, 12), Parent = droite }), 6)
		local plage = UiKit.creer("Frame", { Name = "Plage", BackgroundColor3 = C.accent, BackgroundTransparency = 0.65, BorderSizePixel = 0, Parent = fond })
		local acquis = UiKit.creer("Frame", { Name = "Acquis", BackgroundColor3 = C.accent, BorderSizePixel = 0, Parent = fond })
		local cibles = {}
		for _, e in ipairs(etat.commande.exigences) do
			if e.style == style then
				table.insert(cibles, UiKit.creer("Frame", { Name = "Cible", BackgroundColor3 = C.texte, BorderSizePixel = 0, Position = UDim2.new(e.valeur / 100, -1, 0, -3), Size = UDim2.new(0, 2, 1, 6), Parent = fond }))
			end
		end
		jauges[style] = { plage = plage, acquis = acquis }
	end

	-- Choix du tissu d'une pièce (par-dessus le carnet), filtrable par style
	local choix
	local function fermerChoix()
		if choix then
			choix:Destroy()
			choix = nil
		end
	end
	local function ouvrirChoix(pieces)
		fermerChoix()
		choix = UiKit.arrondir(UiKit.creer("Frame", { Name = "ChoixTissu", BackgroundColor3 = C.fond, Size = UDim2.fromScale(1, 1), ZIndex = 10, Parent = contenu }), 10)
		UiKit.boutonDoux({ Name = "FermerChoix", Text = "Retour", Position = UDim2.new(1, -120, 0, 0), Size = UDim2.fromOffset(110, 34), ZIndex = 11, Parent = choix }, fermerChoix)
		local grille = UiKit.creer("ScrollingFrame", {
			Name = "Grille",
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Position = UDim2.fromOffset(0, 44),
			Size = UDim2.new(1, 0, 1, -44),
			CanvasSize = UDim2.new(),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			ScrollBarThickness = 6,
			ZIndex = 11,
			Parent = choix,
		})
		UiKit.creer("UIGridLayout", { CellSize = UDim2.fromOffset(200, 96), CellPadding = UDim2.fromOffset(8, 8), Parent = grille })
		local function remplir(filtre)
			for _, enfant in ipairs(grille:GetChildren()) do
				if enfant:IsA("TextButton") then
					enfant:Destroy()
				end
			end
			for _, t in ipairs(Catalogue.Tissus) do
				if not filtre or (t.style[filtre] or 0) > 0 then
					local carte = UiKit.arrondir(UiKit.creer("TextButton", { Name = "Tissu_" .. t.id, Text = "", AutoButtonColor = true, BackgroundColor3 = C.panneau, ZIndex = 12, Parent = grille }), 8)
					local motif = Vignettes.motif(t.id)
					local echantillon = UiKit.arrondir(UiKit.creer("ImageLabel", {
						BackgroundColor3 = UiKit.couleur(t.motif.couleurs[1]),
						Position = UDim2.fromOffset(8, 8),
						Size = UDim2.fromOffset(56, 80),
						ScaleType = Enum.ScaleType.Tile,
						TileSize = UDim2.fromOffset(64, 64),
						ZIndex = 13,
						Parent = carte,
					}), 6)
					if motif then
						echantillon.ImageContent = motif
					end
					UiKit.texte({ Text = t.nom, Font = Enum.Font.GothamBold, TextSize = 14, Position = UDim2.fromOffset(72, 8), Size = UDim2.new(1, -80, 0, 36), ZIndex = 13, Parent = carte })
					local styles = {}
					for s, pts in pairs(t.style) do
						table.insert(styles, { s = s, pts = pts })
					end
					table.sort(styles, function(a, b)
						return a.pts > b.pts
					end)
					local etiquettes = {}
					for k = 1, math.min(2, #styles) do
						table.insert(etiquettes, Catalogue.NOMS_STYLES[styles[k].s])
					end
					UiKit.texte({ Text = ("%d po/m · %s"):format(t.prix, table.concat(etiquettes, ", ")), TextSize = 12, TextColor3 = C.texteDoux, Position = UDim2.fromOffset(72, 50), Size = UDim2.new(1, -80, 0, 36), ZIndex = 13, Parent = carte })
					carte.Activated:Connect(function()
						for _, id in ipairs(pieces) do
							tissus[id] = t.id
						end
						dernierTissu = t.id
						fermerChoix()
						rafraichir()
					end)
				end
			end
		end
		local filtres = { { nom = "Tous" } }
		for _, s in ipairs(Catalogue.STYLES) do
			table.insert(filtres, { nom = Catalogue.NOMS_STYLES[s], style = s })
		end
		for k, f in ipairs(filtres) do
			UiKit.boutonDoux({ Name = "Filtre_" .. (f.style or "tous"), Text = f.nom, TextSize = 13, Position = UDim2.fromOffset((k - 1) * 96, 0), Size = UDim2.fromOffset(90, 34), ZIndex = 11, Parent = choix }, function()
				remplir(f.style)
			end)
		end
		remplir(nil)
	end

	rafraichir = function()
		-- Variantes choisies en surbrillance
		for id, b in pairs(boutonsVariantes) do
			local choisie = croquis[Catalogue.variante(id).famille] == id
			b.BackgroundColor3 = choisie and C.accent or C.secondaire
			b.TextColor3 = choisie and Color3.new(1, 1, 1) or C.texte
		end
		-- Pièces du croquis et leur tissu
		listePieces:ClearAllChildren()
		local pieces = Patron.piecesDuCroquis(croquis)
		for i, id in ipairs(pieces) do
			local y = (i - 1) * 36
			local t = tissus[id] and Catalogue.tissu(tissus[id])
			UiKit.texte({ Text = Catalogue.piece(id).nom, TextSize = 14, Position = UDim2.fromOffset(0, y + 6), Size = UDim2.fromOffset(200, 22), Parent = listePieces })
			local pastille = UiKit.arrondir(UiKit.creer("Frame", { Name = "Pastille", BackgroundColor3 = t and UiKit.couleur(t.motif.couleurs[1]) or C.secondaire, Position = UDim2.fromOffset(204, y + 4), Size = UDim2.fromOffset(26, 26), Parent = listePieces }), 13)
			pastille.BackgroundTransparency = t and 0 or 0.5
			UiKit.texte({ Text = t and t.nom or "(aucun tissu)", TextSize = 14, TextColor3 = t and C.texte or C.texteDoux, Position = UDim2.fromOffset(238, y + 6), Size = UDim2.fromOffset(170, 22), Parent = listePieces })
			UiKit.boutonDoux({ Name = "Tissu_" .. id, Text = "Tissu…", TextSize = 14, Position = UDim2.fromOffset(412, y), Size = UDim2.fromOffset(110, 32), Parent = listePieces }, function()
				ouvrirChoix({ id })
			end)
		end
		UiKit.boutonDoux({ Name = "ToutEnUnTissu", Text = "Même tissu pour toute la robe", TextSize = 14, Position = UDim2.fromOffset(0, #pieces * 36 + 4), Size = UDim2.fromOffset(260, 32), Parent = listePieces }, function()
			if dernierTissu then
				for _, id in ipairs(pieces) do
					tissus[id] = dernierTissu
				end
				rafraichir()
			else
				ouvrirChoix(pieces)
			end
		end)
		-- Jauges et exigences
		local choixPieces = {}
		for _, id in ipairs(pieces) do
			choixPieces[id] = tissus[id]
		end
		local fourchette = Notation.fourchette(croquis, choixPieces)
		for style, j in pairs(jauges) do
			local f = fourchette[style]
			j.acquis.Size = UDim2.fromScale(f.min / 100, 1)
			j.plage.Size = UDim2.fromScale(f.max / 100, 1)
		end
		local SYMBOLES = { ok = "✓", non = "×", ["?"] = "…" }
		local COULEURS_STATUT = { ok = C.ok, non = C.erreur, ["?"] = C.texteDoux }
		for i, e in ipairs(etat.commande.exigences) do
			local statut = statutExigence(e, fourchette, croquis, choixPieces)
			lignesExigences[i].Text = SYMBOLES[statut] .. "  " .. UiKit.exigence(e, Catalogue)
			lignesExigences[i].TextColor3 = COULEURS_STATUT[statut]
		end
	end

	UiKit.bouton({ Name = "Valider", Text = "Valider le croquis", AnchorPoint = Vector2.new(1, 1), Position = UDim2.fromScale(1, 1), Size = UDim2.fromOffset(240, 46), Parent = contenu }, function()
		local pieces = Patron.piecesDuCroquis(croquis)
		local choixPieces = {}
		for _, id in ipairs(pieces) do
			choixPieces[id] = tissus[id]
		end
		local r = session:validerCroquis(croquis, choixPieces)
		if not r.ok then
			ctx.message(r.erreur, C.erreur)
		end
	end)

	rafraichir()
	return fermerChoix
end
```

- [ ] **Step 6: Écrire l'écran d'achat**

`src/client/Atelier/EcranAchat.luau` :

```lua
-- Écran d'achat : pour chaque tissu du croquis, métrage conseillé, stock, quantité à acheter et coût.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Couture = ReplicatedStorage:WaitForChild("Couture")
local Catalogue = require(Couture:WaitForChild("Catalogue"))
local Metrage = require(Couture:WaitForChild("Metrage"))
local EtatAtelier = require(Couture:WaitForChild("EtatAtelier"))
local Vignettes = require(script.Parent:WaitForChild("Vignettes"))

return function(ctx)
	local UiKit, session, contenu = ctx.UiKit, ctx.session, ctx.contenu
	local C = UiKit.COULEURS
	local etat = session.etat

	UiKit.texte({
		Text = "Le métrage conseillé suffit si tu ranges bien tes pièces. Le tissu en trop reste dans ton stock.",
		TextSize = 14,
		TextColor3 = C.texteDoux,
		Size = UDim2.new(1, 0, 0, 22),
		Parent = contenu,
	})

	local lignes = {}
	local quantites = {}
	local function conseil(idTissu)
		local ids = {}
		for _, id in ipairs(etat:piecesDuCroquis()) do
			if etat.tissus[id] == idTissu then
				table.insert(ids, id)
			end
		end
		return Metrage.conseil(ids)
	end

	local function majLigne(idTissu)
		local l = lignes[idTissu]
		local stock = etat.stock[idTissu] or 0
		local q = quantites[idTissu]
		l.infos.Text = ("Conseillé : %d dm · En stock : %d dm"):format(conseil(idTissu), stock)
		l.quantite.Text = ("%d dm"):format(q)
		l.cout.Text = q > 0 and ("%d po"):format(EtatAtelier.prix(idTissu, q)) or "—"
		l.acheter.AutoButtonColor = q > 0
		l.acheter.BackgroundColor3 = q > 0 and C.accent or C.secondaire
	end

	for i, idTissu in ipairs(etat:tissusUtilises()) do
		local t = Catalogue.tissu(idTissu)
		quantites[idTissu] = math.max(0, conseil(idTissu) - (etat.stock[idTissu] or 0))
		local ligne = UiKit.arrondir(UiKit.creer("Frame", { Name = "Ligne_" .. idTissu, BackgroundColor3 = C.panneau, Position = UDim2.fromOffset(0, 32 + (i - 1) * 84), Size = UDim2.new(1, 0, 0, 76), Parent = contenu }), 10)
		local echantillon = UiKit.arrondir(UiKit.creer("ImageLabel", {
			BackgroundColor3 = UiKit.couleur(t.motif.couleurs[1]),
			Position = UDim2.fromOffset(10, 10),
			Size = UDim2.fromOffset(80, 56),
			ScaleType = Enum.ScaleType.Tile,
			TileSize = UDim2.fromOffset(64, 64),
			Parent = ligne,
		}), 6)
		local motif = Vignettes.motif(idTissu)
		if motif then
			echantillon.ImageContent = motif
		end
		UiKit.texte({ Text = ("%s — %d po/m"):format(t.nom, t.prix), Font = Enum.Font.GothamBold, Position = UDim2.fromOffset(102, 10), Size = UDim2.fromOffset(320, 24), Parent = ligne })
		local l = { infos = UiKit.texte({ TextSize = 14, TextColor3 = C.texteDoux, Position = UDim2.fromOffset(102, 40), Size = UDim2.fromOffset(320, 24), Parent = ligne }) }
		UiKit.boutonDoux({ Name = "Moins", Text = "−", TextSize = 22, Position = UDim2.fromOffset(440, 20), Size = UDim2.fromOffset(40, 36), Parent = ligne }, function()
			quantites[idTissu] = math.max(0, quantites[idTissu] - 1)
			majLigne(idTissu)
		end)
		l.quantite = UiKit.texte({ Name = "Quantite", TextXAlignment = Enum.TextXAlignment.Center, Font = Enum.Font.GothamBold, Position = UDim2.fromOffset(484, 26), Size = UDim2.fromOffset(70, 24), Parent = ligne })
		UiKit.boutonDoux({ Name = "Plus", Text = "+", TextSize = 22, Position = UDim2.fromOffset(558, 20), Size = UDim2.fromOffset(40, 36), Parent = ligne }, function()
			quantites[idTissu] = math.min(EtatAtelier.ACHAT_MAX, quantites[idTissu] + 1)
			majLigne(idTissu)
		end)
		l.cout = UiKit.texte({ Name = "Cout", TextXAlignment = Enum.TextXAlignment.Right, Position = UDim2.fromOffset(606, 26), Size = UDim2.fromOffset(70, 24), Parent = ligne })
		l.acheter = UiKit.bouton({ Name = "Acheter", Text = "Acheter", Position = UDim2.new(1, -150, 0, 18), Size = UDim2.fromOffset(136, 40), Parent = ligne }, function()
			local q = quantites[idTissu]
			if q < 1 then
				return
			end
			local r = session:acheter(idTissu, q)
			if r.ok then
				quantites[idTissu] = 0
				majLigne(idTissu)
				ctx.message(("Acheté : %d dm de %s (%d po)."):format(q, t.nom, r.prix), C.ok)
			else
				ctx.message(r.erreur, C.erreur)
			end
		end)
		lignes[idTissu] = l
		majLigne(idTissu)
	end

	UiKit.boutonDoux({ Name = "RetourCarnet", Text = "Retour au carnet", AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), Size = UDim2.fromOffset(200, 46), Parent = contenu }, function()
		local r = session:retourCarnet()
		if not r.ok then
			ctx.message(r.erreur, C.erreur)
		end
	end)
	UiKit.bouton({ Name = "AllerDecoupe", Text = "Aller à la découpe", AnchorPoint = Vector2.new(1, 1), Position = UDim2.fromScale(1, 1), Size = UDim2.fromOffset(240, 46), Parent = contenu }, function()
		local r = session:commencerDecoupe()
		if not r.ok then
			ctx.message(r.erreur, C.erreur)
		end
	end)
	return function() end
end
```

- [ ] **Step 7: Écrire la table de découpe**

`src/client/Atelier/EcranDecoupe.luau` :

```lua
-- Écran de la table de découpe : le rouleau vu de dessus (motif du tissu, pli, pièces déjà coupées),
-- la pièce sélectionnée à glisser à la souris ou au doigt, la rotation, le droit-fil et la coupe.
-- La logique (position, aimantation, validité) est dans TableDecoupe.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Couture = ReplicatedStorage:WaitForChild("Couture")
local Catalogue = require(Couture:WaitForChild("Catalogue"))
local Polygone = require(Couture:WaitForChild("Polygone"))
local TableDecoupe = require(script.Parent:WaitForChild("TableDecoupe"))
local Vignettes = require(script.Parent:WaitForChild("Vignettes"))

local PX = 36 -- pixels par dm : le rouleau de 14 dm fait 504 px de large
local ACHAT_RAPIDE = 5 -- dm ajoutés par le bouton « Plus de tissu »

local function taillePiece(idPiece)
	local b = Polygone.boite(Catalogue.piece(idPiece).contour)
	return UDim2.fromOffset((b.maxX - b.minX) * PX, (b.maxY - b.minY) * PX)
end

return function(ctx)
	local UiKit, session, contenu = ctx.UiKit, ctx.session, ctx.contenu
	local C = UiKit.COULEURS
	local table_ = TableDecoupe.nouvelle(session.etat)
	local connexions = {}

	-- Rouleau
	local vue = UiKit.creer("ScrollingFrame", {
		Name = "Rouleau",
		BackgroundColor3 = C.secondaire,
		BorderSizePixel = 0,
		Size = UDim2.new(0, 14 * PX + 12, 1, 0),
		CanvasSize = UDim2.new(),
		ScrollBarThickness = 10,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		Parent = contenu,
	})
	local tissuImage = UiKit.creer("ImageLabel", {
		Name = "Tissu",
		BorderSizePixel = 0,
		ScaleType = Enum.ScaleType.Tile,
		TileSize = UDim2.fromOffset(8 * PX, 8 * PX),
		Parent = vue,
	})
	local pli = UiKit.creer("Frame", { Name = "Pli", BackgroundColor3 = C.texte, BackgroundTransparency = 0.4, BorderSizePixel = 0, Position = UDim2.fromOffset(7 * PX - 1, 0), Size = UDim2.new(0, 2, 1, 0), ZIndex = 2, Parent = tissuImage })
	local calque = UiKit.creer("Frame", { Name = "Coupees", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 3, Parent = tissuImage })
	local piece = UiKit.creer("ImageButton", { Name = "PieceCourante", BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5), AutoButtonColor = false, ZIndex = 5, Parent = tissuImage })

	-- Panneau de droite
	local panneau = UiKit.creer("Frame", { Name = "Panneau", BackgroundTransparency = 1, Position = UDim2.fromOffset(14 * PX + 24, 0), Size = UDim2.new(1, -(14 * PX + 24), 1, 0), Parent = contenu })
	local onglets = UiKit.creer("Frame", { Name = "Onglets", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 34), Parent = panneau })
	local liste = UiKit.creer("Frame", { Name = "ListePieces", BackgroundTransparency = 1, Position = UDim2.fromOffset(0, 40), Size = UDim2.new(1, 0, 0, 158), Parent = panneau })
	local droitFil = UiKit.texte({ Name = "DroitFil", Font = Enum.Font.GothamBold, Position = UDim2.fromOffset(0, 204), Size = UDim2.new(1, 0, 0, 22), Parent = panneau })
	local statut = UiKit.texte({ Name = "Statut", TextSize = 14, Position = UDim2.fromOffset(0, 226), Size = UDim2.new(1, 0, 0, 36), Parent = panneau })

	local rafraichir, placerPiece
	-- Fait défiler le rouleau pour que la pièce sélectionnée soit en vue
	local function montrerPiece()
		if table_.placement then
			vue.CanvasPosition = Vector2.new(0, math.max(0, table_.placement.y * PX - 120))
		end
	end
	local function tourner(degres)
		table_:tourner(degres)
		placerPiece()
	end
	for k, r in ipairs({ { "« 15°", -15 }, { "« 1°", -1 }, { "1° »", 1 }, { "15° »", 15 } }) do
		UiKit.boutonDoux({ Name = "Tourner" .. r[2], Text = r[1], TextSize = 14, Position = UDim2.fromOffset((k - 1) * 82, 266), Size = UDim2.fromOffset(76, 34), Parent = panneau }, function()
			tourner(r[2])
		end)
	end
	UiKit.boutonDoux({ Name = "Proposer", Text = "Proposer une place", TextSize = 14, Position = UDim2.fromOffset(0, 306), Size = UDim2.fromOffset(160, 34), Parent = panneau }, function()
		table_:proposer()
		placerPiece()
		montrerPiece()
	end)
	UiKit.boutonDoux({ Name = "PlusDeTissu", Text = ("Plus de tissu (+%d dm)"):format(ACHAT_RAPIDE), TextSize = 14, Position = UDim2.fromOffset(166, 306), Size = UDim2.fromOffset(160, 34), Parent = panneau }, function()
		local r = session:acheter(table_.tissu, ACHAT_RAPIDE)
		if not r.ok then
			ctx.message(r.erreur, C.erreur)
		end
	end)
	local couper = UiKit.bouton({ Name = "Couper", Text = "Couper", Position = UDim2.fromOffset(0, 348), Size = UDim2.new(1, 0, 0, 44), Parent = panneau }, function()
		local r = table_:couper(session)
		if not r.ok then
			ctx.message(r.erreur, C.erreur)
		elseif session.etat.etape == "decoupe" then
			-- La session a prévenu l'écran avant que la table ne choisisse la pièce suivante : on redessine
			rafraichir()
			montrerPiece()
		end
	end)
	UiKit.boutonDoux({ Name = "Recommencer", Text = "Recommencer la robe", TextSize = 14, AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), Size = UDim2.fromOffset(200, 34), Parent = panneau }, function()
		local r = session:recommencer()
		if not r.ok then
			ctx.message(r.erreur, C.erreur)
		end
	end)

	placerPiece = function()
		local p = table_.placement
		piece.Visible = p ~= nil
		if not p then
			droitFil.Text = ""
			statut.Text = "Toutes les pièces de ce tissu sont coupées."
			return
		end
		local e = table_:etatPlacement()
		piece.Position = UDim2.fromOffset(p.x * PX, p.y * PX)
		piece.Size = taillePiece(table_.selection)
		piece.Rotation = p.angle
		local silhouette = Vignettes.silhouette(table_.selection)
		if silhouette then
			piece.ImageContent = silhouette
		end
		piece.ImageColor3 = e.valide and Color3.new(1, 1, 1) or Color3.fromRGB(255, 120, 120)
		droitFil.Text = ("Droit-fil : %d %%"):format(math.floor(e.droitFil * 100 + 0.5))
		droitFil.TextColor3 = e.droitFil >= 0.999 and C.ok or (e.droitFil >= 0.7 and C.alerte or C.erreur)
		statut.Text = e.valide and "Place libre : tu peux couper." or e.erreur
		statut.TextColor3 = e.valide and C.ok or C.erreur
		couper.BackgroundColor3 = e.valide and C.accent or C.secondaire
		couper.AutoButtonColor = e.valide
	end

	rafraichir = function()
		local etat = session.etat
		if etat.etape ~= "decoupe" then
			return
		end
		local coupon = table_:coupon()
		local tissu = Catalogue.tissu(table_.tissu)
		-- Tissu déroulé
		tissuImage.Size = UDim2.fromOffset(14 * PX, coupon.longueur * PX)
		tissuImage.BackgroundColor3 = UiKit.couleur(tissu.motif.couleurs[1])
		local motif = Vignettes.motif(table_.tissu)
		if motif then
			tissuImage.ImageContent = motif
		end
		vue.CanvasSize = UDim2.fromOffset(0, coupon.longueur * PX)
		local plie = false
		for _, id in ipairs(table_:piecesRestantes()) do
			plie = plie or Catalogue.piece(id).pliee == true
		end
		pli.Visible = plie
		-- Pièces déjà coupées dans ce tissu (et leur symétrique si elles sont pliées ; le symétrique
		-- est approché par la même silhouette tournée en sens inverse)
		calque:ClearAllChildren()
		for id, p in pairs(etat.coupees) do
			if etat.tissus[id] == table_.tissu then
				local copies = { { x = p.x, angle = p.angle } }
				if Catalogue.piece(id).pliee then
					table.insert(copies, { x = 2 * Catalogue.PLI - p.x, angle = -p.angle })
				end
				for _, c in ipairs(copies) do
					local img = UiKit.creer("ImageLabel", {
						Name = "Coupee_" .. id,
						BackgroundTransparency = 1,
						AnchorPoint = Vector2.new(0.5, 0.5),
						Position = UDim2.fromOffset(c.x * PX, p.y * PX),
						Size = taillePiece(id),
						Rotation = c.angle,
						ImageColor3 = Color3.fromRGB(120, 120, 120),
						ImageTransparency = 0.3,
						ZIndex = 4,
						Parent = calque,
					})
					local silhouette = Vignettes.silhouette(id)
					if silhouette then
						img.ImageContent = silhouette
					end
				end
			end
		end
		-- Onglets des tissus
		onglets:ClearAllChildren()
		for k, o in ipairs(table_:onglets()) do
			local actif = o.tissu == table_.tissu
			local b = UiKit.boutonDoux({ Name = "Onglet_" .. o.tissu, Text = ("%s (%d)"):format(Catalogue.tissu(o.tissu).nom, o.reste), TextSize = 13, Position = UDim2.fromOffset((k - 1) * 170, 0), Size = UDim2.fromOffset(164, 32), Parent = onglets }, function()
				table_:choisirTissu(o.tissu)
				rafraichir()
				montrerPiece()
			end)
			b.BackgroundColor3 = actif and C.accent or C.secondaire
			b.TextColor3 = actif and Color3.new(1, 1, 1) or C.texte
		end
		-- Pièces restantes de ce tissu
		liste:ClearAllChildren()
		for k, id in ipairs(table_:piecesRestantes()) do
			local actif = id == table_.selection
			local b = UiKit.boutonDoux({ Name = "Piece_" .. id, Text = Catalogue.piece(id).nom .. (Catalogue.piece(id).pliee and " (pliée)" or ""), TextSize = 13, Position = UDim2.fromOffset(0, (k - 1) * 26), Size = UDim2.new(1, 0, 0, 24), Parent = liste }, function()
				table_:selectionner(id)
				rafraichir()
				montrerPiece()
			end)
			b.BackgroundColor3 = actif and C.accent or C.panneau
			b.TextColor3 = actif and Color3.new(1, 1, 1) or C.texte
		end
		placerPiece()
	end

	-- Glisser la pièce (souris ou doigt). La fenêtre peut être réduite (UIScale sur petit écran) :
	-- on convertit avec la taille réelle du rouleau à l'écran, et on garde l'écart entre le doigt
	-- et le centre de la pièce au moment où on la saisit.
	local glisse, ecartX, ecartY = false, 0, 0
	local function versRouleau(position)
		local pxEcran = tissuImage.AbsoluteSize.X / 14
		local x = (position.X - tissuImage.AbsolutePosition.X) / pxEcran
		local y = (position.Y - tissuImage.AbsolutePosition.Y) / pxEcran
		return x, y
	end
	table.insert(connexions, piece.InputBegan:Connect(function(input)
		if table_.placement and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
			local x, y = versRouleau(input.Position)
			ecartX, ecartY = table_.placement.x - x, table_.placement.y - y
			glisse = true
		end
	end))
	table.insert(connexions, UserInputService.InputChanged:Connect(function(input)
		if glisse and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local x, y = versRouleau(input.Position)
			table_:deplacer(x + ecartX, y + ecartY)
			placerPiece()
		end
	end))
	table.insert(connexions, UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			glisse = false
		end
	end))
	-- R : tourner de 15° (Maj + R : dans l'autre sens)
	table.insert(connexions, UserInputService.InputBegan:Connect(function(input, traite)
		if not traite and input.KeyCode == Enum.KeyCode.R then
			local inverse = UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) or UserInputService:IsKeyDown(Enum.KeyCode.RightShift)
			tourner(inverse and -15 or 15)
		end
	end))

	local desabonner = session:surChangement(function()
		rafraichir()
		montrerPiece()
	end)
	rafraichir()
	montrerPiece()
	return function()
		desabonner()
		for _, c in ipairs(connexions) do
			c:Disconnect()
		end
	end
end
```

- [ ] **Step 8: Écrire le script de démarrage**

`src/client/Atelier/init.client.luau` :

```lua
-- Atelier : script de démarrage du client. Construit la fenêtre de l'atelier et affiche l'écran
-- qui correspond à l'étape de la commande en cours (accueil, carnet, achat, découpe, suite).
local Players = game:GetService("Players")

local UiKit = require(script:WaitForChild("UiKit"))
local Session = require(script:WaitForChild("Session"))

local ECRANS = {
	accueil = require(script:WaitForChild("EcranAccueil")),
	carnet = require(script:WaitForChild("EcranCarnet")),
	achat = require(script:WaitForChild("EcranAchat")),
	decoupe = require(script:WaitForChild("EcranDecoupe")),
	epinglage = require(script:WaitForChild("EcranSuite")),
}
local TITRES = {
	accueil = "Atelier de couture",
	carnet = "1. Carnet de croquis",
	achat = "2. Achat du tissu",
	decoupe = "3. Table de découpe",
	epinglage = "Toutes les pièces sont coupées !",
}

local C = UiKit.COULEURS
local joueur = Players.LocalPlayer
local session = Session.nouvelle()

local gui = UiKit.creer("ScreenGui", {
	Name = "Atelier",
	ResetOnSpawn = false,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	Parent = joueur:WaitForChild("PlayerGui"),
})
local fenetre = UiKit.arrondir(UiKit.creer("Frame", {
	Name = "Fenetre",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromOffset(UiKit.LARGEUR, UiKit.HAUTEUR),
	BackgroundColor3 = C.fond,
	Parent = gui,
}), 14)

-- Mise à l'échelle sur les petits écrans (suit la caméra et la taille de la fenêtre du jeu)
local echelle = UiKit.creer("UIScale", { Parent = fenetre })
local connexionCamera
local function ajuster()
	local camera = workspace.CurrentCamera
	echelle.Scale = UiKit.echelle(camera and camera.ViewportSize or Vector2.new(1280, 720))
end
local function suivreCamera()
	if connexionCamera then
		connexionCamera:Disconnect()
	end
	if workspace.CurrentCamera then
		connexionCamera = workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(ajuster)
	end
	ajuster()
end
suivreCamera()
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(suivreCamera)

local titre = UiKit.texte({
	Name = "Titre",
	Font = Enum.Font.GothamBold,
	TextSize = 24,
	Position = UDim2.fromOffset(20, 14),
	Size = UDim2.new(1, -260, 0, 32),
	Parent = fenetre,
})
local argent = UiKit.texte({
	Name = "Argent",
	Font = Enum.Font.GothamBold,
	TextSize = 20,
	TextColor3 = C.accent,
	TextXAlignment = Enum.TextXAlignment.Right,
	Position = UDim2.new(1, -240, 0, 14),
	Size = UDim2.fromOffset(180, 32),
	Parent = fenetre,
})
UiKit.boutonDoux({
	Name = "Fermer",
	Text = "×",
	TextSize = 26,
	Position = UDim2.new(1, -50, 0, 12),
	Size = UDim2.fromOffset(36, 36),
	Parent = fenetre,
}, function()
	fenetre.Visible = false
end)
local contenu = UiKit.creer("Frame", {
	Name = "Contenu",
	BackgroundTransparency = 1,
	Position = UDim2.fromOffset(20, 60),
	Size = UDim2.new(1, -40, 1, -94),
	Parent = fenetre,
})
local message = UiKit.texte({
	Name = "Message",
	Font = Enum.Font.GothamBold,
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 1, -6),
	Size = UDim2.new(1, -40, 0, 24),
	TextXAlignment = Enum.TextXAlignment.Center,
	Visible = false,
	Parent = fenetre,
})
local jeton = 0
local function afficherMessage(texte, couleur)
	jeton += 1
	local moi = jeton
	message.Text = texte
	message.TextColor3 = couleur or C.texte
	message.Visible = true
	task.delay(3, function()
		if moi == jeton then
			message.Visible = false
		end
	end)
end

UiKit.bouton({
	Name = "OuvrirAtelier",
	Text = "Atelier",
	AnchorPoint = Vector2.new(0, 0.5),
	Position = UDim2.new(0, 16, 0.5, 0),
	Size = UDim2.fromOffset(140, 44),
	Parent = gui,
}, function()
	fenetre.Visible = not fenetre.Visible
end)

-- Navigation : un écran par étape ; il se reconstruit seul quand l'état change
local etapeAffichee, fermerEcran
local function afficher()
	local etat = session.etat
	argent.Text = ("%d pièces d'or"):format(etat.argent)
	if etat.etape ~= etapeAffichee then
		if fermerEcran then
			fermerEcran()
		end
		contenu:ClearAllChildren()
		etapeAffichee = etat.etape
		titre.Text = TITRES[etat.etape] or etat.etape
		fermerEcran = ECRANS[etat.etape]({ session = session, contenu = contenu, message = afficherMessage, UiKit = UiKit })
	end
end
session:surChangement(afficher)
afficher()
```

- [ ] **Step 9: Lancer les tests**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT"`
Expected:
```
Unitaires : 104370 vérifications
TOUT EST VERT : 77 vérifications
```

- [ ] **Step 10: Commit**

```bash
git add src/client/Atelier tests/scenario.luau
git commit -m "Interface du nouvel atelier : accueil, carnet, achat et table de découpe

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 7: Vérification dans Studio et README

**Files:**
- Modify: `README.md` (réécriture complète)
- Modify: `AtelierCouture.rbxl` (régénéré)

**Interfaces:**
- Consumes: tout ce qui précède.
- Produces: le lieu jouable de bout en bout jusqu'à la découpe. C'est le point de départ du plan 3b.

- [ ] **Step 1: Construire et ouvrir le lieu**

Run: `C:/dev/jeux/roblox-maker/rojo.exe build -o AtelierCouture.rbxl`, puis ouvrir `AtelierCouture.rbxl` dans Studio (ou utiliser l'instance synchronisée par `rojo serve`). Lancer Play avec le connecteur MCP (`start_stop_play`).

Expected: la fenêtre « Atelier de couture » s'affiche, avec 150 pièces d'or, sans erreur dans la sortie.

- [ ] **Step 2: Jouer jusqu'à la découpe avec la souris (`user_mouse_input`, `instance_path`)**

Cliquer dans l'ordre :
1. `LocalPlayer.PlayerGui.Atelier.Fenetre.Contenu.Clochette` ;
2. `…Contenu.Gauche.Variante_manches_ballon` ;
3. `…Contenu.Gauche.Pieces.ToutEnUnTissu`, puis `…Contenu.ChoixTissu.Grille.Tissu_coton_bleu_carreaux` ;
4. `…Contenu.Valider` ;
5. `…Contenu.Ligne_coton_bleu_carreaux.Acheter` ;
6. `…Contenu.AllerDecoupe`.

Expected (captures d'écran à chaque écran) :
- le carnet montre les jauges, la plage de chaque style et le repère de l'exigence ;
- le choix du tissu montre les vrais motifs ;
- l'achat montre le métrage conseillé et le coût ;
- la table de découpe montre le vichy répété sur le rouleau, la ligne du pli et le patron en papier avec sa flèche de droit-fil, en haut à gauche ;
- la liste des pièces ne déborde pas sur « Droit-fil » ni « Statut ».

- [ ] **Step 3: Vérifier le glisser-déposer**

1. Lire le centre de la pièce à l'écran avec `execute_luau` (Client) : `local p = game.Players.LocalPlayer.PlayerGui.Atelier.Fenetre.Contenu.Rouleau.Tissu.PieceCourante; local c = p.AbsolutePosition + p.AbsoluteSize / 2; return c.X .. "," .. c.Y`.
2. Avec `user_mouse_input`, faire `moveTo` (centre − 10, centre − 6), `mouseButtonDown`, deux `moveTo` intermédiaires, `moveTo` (centre + 110, centre + 84), puis `mouseButtonUp`.
3. Relire le centre.

Expected: le nouveau centre vaut l'ancien + (120, 90) à 1 px près. La pièce suit le curseur malgré la réduction de la fenêtre, sans sauter au moment de la saisie.

- [ ] **Step 4: Vérifier la rotation et la coupe**

Cliquer `…Panneau.Tourner15`, puis `…Panneau.Couper`.

Expected :
- la pièce tournée contre le bord dépasse du rouleau : elle s'affiche en rouge avec « La pièce dépasse du tissu. » et la coupe est refusée ;
- après l'avoir glissée vers l'intérieur, la coupe réussit : la pièce reste en gris sur le rouleau et la suivante est proposée à sa droite, au droit-fil, avec « Place libre : tu peux couper. ».

- [ ] **Step 5: Réécrire le README**

`README.md` :

````markdown
# Atelier de couture — jeu Roblox

Jeu de couture sur Roblox, inspiré des mécaniques de *Dressmaker* (Cozy Lives / Free Lives, 2026).
On ne choisit pas un vêtement tout fait : on **dessine**, **coupe**, **coud** et **décore** la robe,
et le tissu découpé se voit tel quel sur la robe en 3D.

Le jeu est en cours de refonte, sous-projet par sous-projet
(spec : `docs/superpowers/specs/2026-09-28-atelier-coeur-design.md`, plans : `docs/superpowers/plans/`).

## État actuel (plan 3a)

Jouable dans Studio, en solo, sans sauvegarde (l'état de la partie vit dans le client) :

1. **Commande** : la clochette fait entrer une cliente (taille S, M ou L) avec 1 à 3 exigences de style,
   de couleur, de qualité ou d'accessoire.
2. **Carnet de croquis** : corsage, manches, col et jupe au choix ; un tissu par pièce (24 tissus, filtre par style).
   Les jauges de style et l'état des exigences se mettent à jour en direct.
3. **Achat** : métrage conseillé par tissu, quantité réglable, coût au mètre.
4. **Table de découpe** : les pièces du patron se glissent (souris ou doigt) et se tournent sur le rouleau.
   Droit-fil aimanté, pièces pliées coupées en double au pli, chevauchements refusés, place proposée.
5. La suite (épinglage, couture, décorations, photo et livraison) arrive au plan 3b ; serveur, boutiques
   et sauvegarde au plan 4.

## Installation

```bash
rojo serve        # dans ce dossier, puis « Connect » depuis le plugin Rojo dans Roblox Studio
# ou
rojo build -o AtelierCouture.rbxl
```

Le fichier `AtelierCouture.rbxl` fourni est prêt à ouvrir. Après une modification du code, le régénérer avec
`rojo build -o AtelierCouture.rbxl`. Le rendu 3D des robes utilise les API EditableMesh / EditableImage :
dans un jeu publié, le compte propriétaire doit être vérifié (13 ans et plus) et avoir activé ces API.

## Architecture

- `src/shared/` (ReplicatedStorage.Couture) : logique partagée, sans interface.
  | Module | Rôle |
  |---|---|
  | `Polygone`, `Patron` | Géométrie 2D des pièces, enroulement 3D autour du corps |
  | `Catalogue` | Pièces, variantes, tissus, accessoires, constantes |
  | `Coupon`, `Metrage` | Rouleau de découpe (pli, chevauchements) et métrage conseillé |
  | `Notation`, `Commandes` | Droit-fil, couture, qualité, styles, exigences, paie ; commandes réalisables |
  | `Pixels` | Motifs de tissu, découpe exacte de l'image d'une pièce, silhouette du patron |
  | `Recette` | Recette d'une robe en JSON et validation complète (filtre du serveur au plan 4) |
  | `Maillage`, `Mannequin`, `Editables`, `ConstructeurRobe`, `Vitrines` | Robe 3D, mannequin, vitrines |
  | `EtatAtelier` | État de la commande et règles de chaque étape (repris par le serveur au plan 4) |
- `src/client/Atelier/` (LocalScript `Atelier` et ses modules) : l'interface.
  `Session` fait le lien avec l'état ; `TableDecoupe` est la logique pure de la table ; un module `Ecran…` par étape.

## Tests

`bash tests/lancer.sh` (Linux, macOS ou Windows via Git Bash, avec Python 3) exécute le code du jeu dans un
Roblox simulé, validé d'après les définitions officielles de l'API (luau-lsp 1.70.1) :
- les tests unitaires de `tests/unitaires/` (logique, géométrie, rendu avec doublures des API modifiables) ;
- `tests/scenario.luau` : une commande jouée de bout en bout en cliquant dans l'interface.

Ce qu'une simulation ne voit pas (rendu, glisser au doigt, tailles d'écran) se vérifie dans Studio :
bancs d'essai `tests/studio/` et rapport `docs/superpowers/spikes/2026-09-28-rendu-editable.md`.
````

- [ ] **Step 6: Tests, lieu régénéré, commit**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT"`
Expected:
```
Unitaires : 104370 vérifications
TOUT EST VERT : 77 vérifications
```

```bash
C:/dev/jeux/roblox-maker/rojo.exe build -o AtelierCouture.rbxl
git add README.md AtelierCouture.rbxl
git commit -m "Plan 3a terminé : commande, carnet, achat et découpe jouables

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```
