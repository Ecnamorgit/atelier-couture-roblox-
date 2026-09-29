# Cœur de l'atelier — Plan 3c : décorations, présentation et livraison

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Boucler la commande : décorer la robe sur le mannequin, la présenter à la cliente, qui l'accepte (paie, vitrine) ou la refuse (retouche ou abandon), puis passer à la cliente suivante.

**Architecture:**
- **État** : `EtatAtelier` gagne les décorations (liste complète vérifiée comme une recette, facturée à la différence), la livraison (jugement par `Notation`, paie, les 10 dernières robes gardées), la retouche et l'abandon.
- **Éditeur de décorations** : sa logique est un module client pur, `Decorateur`. Le point touché sur la robe 3D redonne sa place sur le patron par `Patron.versUV`.
- **Scène** : `Scene` lance les rayons sur la robe, montre l'aperçu des décorations, tourne la vue autour du mannequin et tient une vitrine locale de la dernière robe livrée (module `Vitrines` du plan 2).
- **Écrans** : décorations, présentation et refus, en panneau à droite ; l'accueil annonce le résultat de la livraison précédente.

**Tech Stack:** Luau, Rojo 7.7.0-rc.1, simulation Luau 0.650 (`tests/lancer.sh`), Roblox Studio via le connecteur MCP Studio.

**Spec:** `docs/superpowers/specs/2026-09-28-atelier-coeur-design.md` (§3 accessoires, commandes et paie, §4 étapes 7 et 8, §5 accessoires et vitrines, §6 contrôles des décorations et de la livraison). Plans précédents : `docs/superpowers/plans/2026-09-29-coeur-plan3a-postes.md`, `docs/superpowers/plans/2026-09-29-coeur-plan3b-epinglage-couture.md`.

## Décisions de ce plan

- **Découpage** : ce plan livre la boucle complète, de la clochette à la vitrine. La photo de l'étape 8 (décor, éclairage, couleur du mannequin, capture `CaptureService`) et la cliente en personne (PNJ, spec §3) sont repoussées à un **plan 3d**. L'étape s'appelle déjà `photo` dans `EtatAtelier`, et son écran s'affiche « 7. Présentation ».
- **Facturation des décorations** (spec §6) : la liste complète est envoyée en quittant le poste, et on facture la différence avec la liste déjà payée. Ce qu'on retire est remboursé. « Recommencer » perd les décorations posées, comme le tissu coupé.
- **Toucher ou glisser** : sur la scène, un appui qui bouge de moins de 8 px pose (ou sélectionne) ; au-delà, c'est un glisser qui fait tourner la vue autour du mannequin (0,5° par pixel). Sur PC, Q et E tournent la décoration sélectionnée (spec §4).
- **Score affiché** : à la présentation et au refus, les exigences de style montrent le score actuel (« Au moins 30 en Élégant (actuel : 24) »). Sans lui, un joueur retouche à l'aveugle ; c'est arrivé dans Studio pendant la préparation de ce plan.
- **Vitrine locale** : un socle à côté du mannequin de travail porte la recette de la dernière robe livrée, et le module `Vitrines` la construit. Au plan 4, la boutique construite par le serveur fournira ce socle et répliquera la recette à tous les joueurs.

## Global Constraints

- **Dépôt** : `C:\dev\jeux\atelier-couture`, branche `refonte-livraison`, créée depuis `corrections-test-studio`, où le plan 3b est fusionné. Ne rien pousser sur GitHub sans demande.
- **Rojo** : `C:/dev/jeux/roblox-maker/rojo.exe`.
- **Contraintes des plans précédents toujours valables** : unité le dm, repère du corps, fins de ligne LF, commits en français terminés par `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`, textes d'au moins 14 px à l'échelle 1, symboles vérifiés à l'écran, double clic protégé (`UiKit.bouton`), « Recommencer » à confirmer.
- **Décorations** (spec §6) : identifiants valides, 300 objets au plus, 64 points par garniture, `u` et `v` dans [0 ; 1], échelle de 0,5 à 3, angle de −360 à 360. Refus si l'argent manque.
- **Prix** : les objets à l'unité ; les garnitures au dm, arrondi au-dessus, par garniture.
- **Livraison** (spec §3) : acceptée si toutes les exigences sont remplies, avec paie = `base × (0,5 + qualité)`, `base = 20 + 10 × pièces + 15 × exigences`. Sinon refus, puis retouche (retour aux décorations) ou abandon (ni paie ni vitrine). Les 10 dernières robes livrées sont gardées, la plus récente en vitrine.
- **Étapes** : `…` → `couture` → `decorations` → `photo` (« Présentation ») → accueil (acceptée) ou `refus` → `decorations` (retouche) ou accueil (abandon).

## Review Focus

- **Toucher la robe au doigt sur un vrai téléphone.** Attendu : un appui court pose la décoration et un glisser fait tourner la vue. Le seuil est de 8 px, alors que le doigt bouge toujours un peu. La simulation et le connecteur Studio n'envoient que des entrées nettes.
- **Précision du toucher sur les pièces fines (col, manches) et au bord des pièces.** Les `MeshPart` gardent la collision `Default`, une enveloppe approchée. Attendu : la décoration se pose sous le doigt. Ce n'est vérifié dans Studio qu'au centre du corsage.
- **Beaucoup de décorations** (jusqu'à 300 objets). L'aperçu est reconstruit en entier à chaque changement. Attendu : pas de saccade notable sur téléphone.
- **Équilibrage de la retouche.** Les décorations comptent peu (Ka = 0,5) : dans Studio, six broches camées n'ont pas suffi à rattraper « au moins 30 en Élégant » sur un satin violet. Attendu : une retouche raisonnable suffit quand l'écart est petit ; le score actuel s'affiche pour guider. À régler à la finition du plan 4.
- **Vitrine construite pendant la robe suivante.** Elle partage le budget des maillages avec la robe en cours (7 simultanés). Attendu : aucune pièce ne manque sur le mannequin de travail.

## Structure des fichiers

| Fichier | Rôle |
|---|---|
| `src/shared/EtatAtelier.luau` | + étapes `photo` et `refus`, `accessoires`, `robes`, `prixDecorations`, `decorer`, `retourDecorations`, `livrer`, `retoucher`, `abandonner` |
| `src/shared/Patron.luau` | + `Patron.versUV` (point 3D touché → place sur le patron) |
| `src/shared/ConstructeurRobe.luau` | + `ConstructeurRobe.accessoire` (un accessoire seul, pour l'aperçu) |
| `src/client/Atelier/Decorateur.luau` | Logique de l'éditeur : palette, pose, garniture point par point, sélection, rotation, taille, suppression, annulation, coût |
| `src/client/Atelier/Scene.luau` | + rayons sur la robe, aperçu des décorations, vue qui tourne, vitrine locale |
| `tests/mock.luau`, `tests/build.py` | Faux Roblox : rayons préparés par les tests (`M.impacts`), `RaycastParams`, `PointToObjectSpace`, `ScreenPointToRay` |
| `src/client/Atelier/Session.luau` | + actions des décorations et de la livraison, `derniere` (dernière action réussie), `Session.courante` |
| `src/client/Atelier/UiKit.luau` | `UiKit.exigence` affiche le score actuel des exigences de style |
| `src/client/Atelier/EcranDecorations.luau`, `EcranPresentation.luau`, `EcranRefus.luau` | Nouveaux écrans |
| `src/client/Atelier/EcranAccueil.luau` | Annonce le résultat de la livraison précédente |
| `src/client/Atelier/EcranSuite.luau` | **Supprimé** (écran provisoire du plan 3b) |
| `src/client/Atelier/init.client.luau` | Branche les nouveaux écrans ; la scène passe aux écrans (`ctx.scene`) |
| `tests/unitaires/21_decorations_livraison.luau`, `22_decorateur.luau`, `23_scene_decorations.luau` | Tests unitaires |
| `tests/unitaires/03_patron.luau`, `12_constructeur.luau`, `tests/scenario.luau` | Tests complétés |
| `README.md` | État du jeu au plan 3c |

---

### Task 1: Décorations et livraison dans `EtatAtelier`

**Files:**
- Modify: `src/shared/EtatAtelier.luau`
- Test: `tests/unitaires/21_decorations_livraison.luau`

**Interfaces:**
- Consumes: `Recette.valider`, `Notation.bilan`, `Notation.verifierExigences`, `Notation.paie`, `Notation.longueurGarniture`, `Catalogue.accessoire`.
- Produces :
  - `EtatAtelier.ROBES_GARDEES = 10` ; `EtatAtelier.ETAPES` gagne `photo` et `refus` ;
  - champs : `etat.accessoires` (décorations payées, format de la recette) et `etat.robes` (recettes livrées, la plus récente en premier) ;
  - `EtatAtelier.prixDecorations(pieces, accessoires) -> integer` ;
  - `etat:decorer(liste) -> { ok, prix }` : `prix` est la différence facturée, négative si remboursement ; mène à `photo` ;
  - `etat:retourDecorations()` ;
  - `etat:livrer() -> { ok, reussie, paie?, bilan, ratees }` : acceptée, retour à `accueil` ; refusée, `refus` ;
  - `etat:retoucher()`, `etat:abandonner()` ;
  - `etat:recette()` porte maintenant les décorations.

- [ ] **Step 1: Écrire les tests**

`tests/unitaires/21_decorations_livraison.luau` :

```lua
local EtatAtelier = U.module("EtatAtelier")
local Patron = U.module("Patron")
local Catalogue = U.module("Catalogue")
local Notation = U.module("Notation")

local CROQUIS = { corsage = "corsage_droit", manches = "manches_sans", col = "col_sans", jupe = "jupe_droite" }
local PIECES = { "corsage_droit_devant", "corsage_droit_dos", "jupe_droite_devant", "jupe_droite_dos" }
local DISPOSITION = {
	corsage_droit_devant = { x = 2.4, y = 2.1, angle = 0 },
	corsage_droit_dos = { x = 7.2, y = 2.1, angle = 0 },
	jupe_droite_devant = { x = 2.5, y = 7.2, angle = 0 },
	jupe_droite_dos = { x = 7.5, y = 7.2, angle = 0 },
}

-- Robe coupée, épinglée et cousue parfaitement, en coton blanc ; exigences choisies par le test
local function jusquAuxDecorations(exigences)
	local e = EtatAtelier.nouveau()
	e:nouvelleCommande(Random.new(3))
	e.commande.exigences = exigences
	local tissus = {}
	for _, id in ipairs(PIECES) do
		tissus[id] = "coton_blanc"
	end
	e:validerCroquis(CROQUIS, tissus)
	e:acheter("coton_blanc", 12)
	e:commencerDecoupe()
	for _, id in ipairs(PIECES) do
		e:couper(id, DISPOSITION[id])
	end
	for _, id in ipairs(PIECES) do
		e:epingler(id)
	end
	for _, id in ipairs(PIECES) do
		local _, longueur = Patron.trajetCouture(id)
		local n = math.round(longueur / Catalogue.PAS_MESURE_COUTURE)
		e:rendreCouture(id, table.create(n, 0), longueur / Catalogue.VITESSE_COUTURE_MAX)
	end
	return e
end

local noeud = { id = "noeud_satin", piece = 1, u = 0.5, v = 0.3, echelle = 1, angle = 0 }
local perle = { id = "perle", piece = 3, u = 0.2, v = 0.8, echelle = 1.5, angle = 30 }
-- Dentelle le long de l'ourlet de la jupe devant (5 dm de large : 5 dm de garniture)
local dentelle = { id = "dentelle_blanche", piece = 3, trajet = { { u = 0, v = 1 }, { u = 1, v = 1 } } }

---------------------------------------------------------------------------
-- Prix des décorations
---------------------------------------------------------------------------
local e = jusquAuxDecorations({ { type = "accessoire", id = "noeud_satin" } })
U.verifier(e.etape == "decorations" and #e.accessoires == 0, "robe cousue : aux décorations, rien de posé")
local recette = e:recette()
U.verifier(EtatAtelier.prixDecorations(recette.pieces, { noeud, perle }) == 3 + 1, "objets : prix à l'unité")
local longueurDentelle = Notation.longueurGarniture("jupe_droite_devant", dentelle.trajet)
U.verifier(U.proche(longueurDentelle, 5), "dentelle de 5 dm")
U.verifier(EtatAtelier.prixDecorations(recette.pieces, { dentelle }) == math.ceil(2 * 5 - 1e-9), "garniture : prix au dm, arrondi au-dessus")

---------------------------------------------------------------------------
-- Décorer : liste complète, vérifiée, facturée à la différence
---------------------------------------------------------------------------
U.verifier(not EtatAtelier.nouveau():decorer({}).ok, "pas de décorations sans robe cousue")
U.verifier(not e:decorer("x").ok and not e:decorer(nil).ok, "liste qui n'est pas une table refusée")
U.verifier(not e:decorer({ { id = "diamant", piece = 1, u = 0.5, v = 0.5, echelle = 1, angle = 0 } }).ok, "accessoire inconnu refusé")
U.verifier(not e:decorer({ { id = "perle", piece = 1, u = 1.5, v = 0.5, echelle = 1, angle = 0 } }).ok, "accessoire hors de la pièce refusé")
U.verifier(not e:decorer({ { id = "perle", piece = 9, u = 0.5, v = 0.5, echelle = 1, angle = 0 } }).ok, "pièce inexistante refusée")
local trop = {}
for k = 1, 301 do
	trop[k] = { id = "perle", piece = 1, u = 0.5, v = 0.5, echelle = 1, angle = 0 }
end
U.verifier(not e:decorer(trop).ok, "301 décorations refusées")
local longue = { id = "ruban_rose", piece = 3, trajet = {} }
for k = 1, 65 do
	longue.trajet[k] = { u = (k - 1) / 64, v = 0.5 }
end
U.verifier(not e:decorer({ longue }).ok, "garniture de 65 points refusée")
U.verifier(e.etape == "decorations" and #e.accessoires == 0, "rien ne change après un refus")

local argent = e.argent
local r = e:decorer({ noeud, perle, dentelle })
U.verifier(r.ok and r.prix == 3 + 1 + 10 and e.argent == argent - 14, "décorations facturées")
U.verifier(e.etape == "photo" and #e.accessoires == 3, "décorations envoyées : direction la photo")
noeud.u = 0.9
U.verifier(e.accessoires[1].u == 0.5, "la liste gardée est une copie")
noeud.u = 0.5
U.verifier(#e:recette().accessoires == 3 and e:recette().accessoires[3].id == "dentelle_blanche", "la recette porte les décorations")

-- Retour aux décorations, puis retrait de la dentelle : remboursée
U.verifier(e:retourDecorations().ok and e.etape == "decorations", "retour de la photo aux décorations")
r = e:decorer({ noeud, perle })
U.verifier(r.ok and r.prix == -10 and e.argent == argent - 4, "décoration retirée : remboursée")
U.verifier(e:retourDecorations().ok, "encore un retour")
local cheres = {}
for k = 1, 60 do
	cheres[k] = { id = "broche_camee", piece = 1, u = 0.5, v = k / 61, echelle = 1, angle = 0 }
end
U.verifier(not e:decorer(cheres).ok and e.argent == argent - 4 and #e.accessoires == 2, "pas assez d'argent : refusé, rien ne change")

---------------------------------------------------------------------------
-- Livraison : la cliente juge la robe
---------------------------------------------------------------------------
U.verifier(not e:livrer().ok, "on livre depuis la photo seulement")
e:decorer({ perle })
local avant = e.argent
r = e:livrer()
U.verifier(r.ok and not r.reussie and #r.ratees == 1 and e.etape == "refus", "nœud de satin exigé mais absent : robe refusée")
U.verifier(e.argent == avant, "refus : pas de paie")
U.verifier(not e:livrer().ok, "une robe refusée ne se relivre pas sans retouche")
U.verifier(e:retoucher().ok and e.etape == "decorations", "retouche : retour aux décorations")
e:decorer({ perle, noeud })
r = e:livrer()
local bilan = Notation.bilan(e.robes[1])
local paie = Notation.paie(4, 1, bilan.qualite)
U.verifier(r.ok and r.reussie and r.paie == paie and e.argent == avant - 3 + paie, "robe acceptée : paie = base × (0,5 + qualité)")
U.verifier(e.etape == "accueil" and e.commande == nil, "robe livrée : retour à l'accueil")
U.verifier(#e.robes == 1 and #e.robes[1].accessoires == 2 and e.robes[1].pieces[1].couture == 1, "la robe livrée part en vitrine (recette gardée)")
U.verifier(next(e.coupees) == nil and next(e.epinglees) == nil and next(e.coutures) == nil and #e.accessoires == 0, "atelier prêt pour la commande suivante")
U.verifier(e:nouvelleCommande(Random.new(9)).ok, "nouvelle commande possible")

-- Abandon après un refus : pas de paie, pas de vitrine
local e2 = jusquAuxDecorations({ { type = "accessoire", id = "croix_argent" } })
e2:decorer({})
local argent2 = e2.argent
U.verifier(not e2:livrer().reussie and e2:abandonner().ok, "robe refusée puis abandonnée")
U.verifier(e2.etape == "accueil" and e2.commande == nil and #e2.robes == 0 and e2.argent == argent2, "abandon : ni paie ni vitrine")
U.verifier(not e2:abandonner().ok and not e2:retoucher().ok, "abandonner et retoucher seulement après un refus")

-- Les 10 dernières robes seulement, la plus récente en premier
local e3 = jusquAuxDecorations({ { type = "qualite", valeur = 0.5 } })
for k = 1, 11 do
	e3.robes[k] = { marque = k }
end
e3:decorer({})
U.verifier(e3:livrer().reussie and #e3.robes == 10 and e3.robes[1].marque == nil and e3.robes[2].marque == 1, "10 robes gardées, la plus récente en tête")

-- Recommencer depuis les décorations : les décorations posées sont perdues, comme le tissu coupé
local e4 = jusquAuxDecorations({ { type = "qualite", valeur = 0.5 } })
local argent4 = e4.argent
e4:decorer({ noeud })
U.verifier(e4:recommencer().ok and #e4.accessoires == 0 and e4.argent == argent4 - 3, "recommencer : les décorations posées sont perdues")
```

- [ ] **Step 2: Vérifier qu'ils échouent**

Run: `bash tests/lancer.sh 2>&1 | grep -m1 -E "ÉCHEC|attempt"`
Expected: `attempt to get length of a nil value` (`etat.accessoires` n'existe pas).

- [ ] **Step 3: Étendre `EtatAtelier`**

```diff
diff --git a/src/shared/EtatAtelier.luau b/src/shared/EtatAtelier.luau
index 23d9520..805cdfd 100644
--- a/src/shared/EtatAtelier.luau
+++ b/src/shared/EtatAtelier.luau
@@ -19,7 +19,8 @@ EtatAtelier.ACHAT_MAX = 100 -- dm par achat
 EtatAtelier.TOLERANCE_MESURES = 2 -- mesures de couture en plus ou en moins acceptées (spec §6)
 EtatAtelier.DUREE_MIN = 0.9 -- part de la durée minimale d'une couture (trajet / vitesse maximale)
 -- Étapes du plan 3b (le plan 3c ajoute la photo et la livraison après les décorations)
-EtatAtelier.ETAPES = { "accueil", "carnet", "achat", "decoupe", "epinglage", "couture", "decorations" }
+EtatAtelier.ROBES_GARDEES = 10 -- robes livrées gardées, la plus récente en vitrine (spec §6)
+EtatAtelier.ETAPES = { "accueil", "carnet", "achat", "decoupe", "epinglage", "couture", "decorations", "photo", "refus" }
 
 local function refus(message)
 	return { ok = false, erreur = message }
@@ -41,6 +42,8 @@ function EtatAtelier.nouveau(argent)
 		coupees = {}, -- [idPiece] = { x, y, angle }
 		epinglees = {}, -- [idPiece] = true
 		coutures = {}, -- [idPiece] = note de couture (0 à 1)
+		accessoires = {}, -- décorations posées, au format de la recette
+		robes = {}, -- recettes des robes livrées, la plus récente en premier
 	}, EtatAtelier)
 end
 
@@ -113,7 +116,7 @@ function EtatAtelier:nouvelleCommande(rng)
 	self.commande = Commandes.generer(rng)
 	self.argent = math.max(self.argent, EtatAtelier.FILET)
 	self.croquis, self.tissus, self.coupees, self.coupons = nil, {}, {}, {}
-	self.epinglees, self.coutures = {}, {}
+	self.epinglees, self.coutures, self.accessoires = {}, {}, {}
 	self.etape = "carnet"
 	return { ok = true, commande = self.commande }
 end
@@ -270,8 +273,37 @@ function EtatAtelier:rendreCouture(idPiece, ecarts, duree, assistance)
 	return { ok = true, note = note, reste = reste }
 end
 
--- Recette de la robe en cours (position des pièces sur le rouleau, notes de couture ; les accessoires
--- arrivent au plan 3c), ou nil tant que toutes les pièces ne sont pas coupées
+-- Copie propre d'une décoration déjà validée (seulement les champs connus)
+local function copieAccessoire(a)
+	local c = { id = a.id, piece = a.piece, copie = a.copie }
+	if a.trajet then
+		c.trajet = {}
+		for k, pt in ipairs(a.trajet) do
+			c.trajet[k] = { u = pt.u, v = pt.v }
+		end
+	else
+		c.u, c.v, c.echelle, c.angle = a.u, a.v, a.echelle, a.angle
+	end
+	return c
+end
+
+-- Prix de décorations posées sur les pièces d'une recette : objets à l'unité, garnitures au dm
+-- (arrondi au-dessus, par garniture)
+function EtatAtelier.prixDecorations(pieces, accessoires)
+	local total = 0
+	for _, a in ipairs(accessoires) do
+		local def = Catalogue.accessoire(a.id)
+		if def.genre == "garniture" then
+			total += math.ceil(def.prix * Notation.longueurGarniture(pieces[a.piece].id, a.trajet) - 1e-9)
+		else
+			total += def.prix
+		end
+	end
+	return total
+end
+
+-- Recette de la robe en cours (position des pièces sur le rouleau, notes de couture, décorations),
+-- ou nil tant que toutes les pièces ne sont pas coupées
 function EtatAtelier:recette()
 	if not self.commande or not self.croquis or #self:piecesAPoser() > 0 then
 		return nil
@@ -286,10 +318,103 @@ function EtatAtelier:recette()
 		mesures = table.clone(self.commande.mesures),
 		croquis = table.clone(self.croquis),
 		pieces = pieces,
-		accessoires = {},
+		accessoires = (function()
+			local out = {}
+			for i, a in ipairs(self.accessoires) do
+				out[i] = copieAccessoire(a)
+			end
+			return out
+		end)(),
 	}
 end
 
+-- Décorations : la liste complète, envoyée quand on quitte le poste (spec §6). Vérifiée comme une
+-- recette (identifiants, 300 objets et 64 points au plus, u et v dans [0 ; 1], échelle et angle
+-- bornés) ; on facture la différence avec la liste précédente (ce qu'on retire est remboursé).
+function EtatAtelier:decorer(liste)
+	if self.etape ~= "decorations" then
+		return refus("Ce n'est pas le moment de décorer.")
+	end
+	if type(liste) ~= "table" then
+		return refus("Décorations invalides.")
+	end
+	local recette = self:recette()
+	recette.accessoires = liste
+	local ok, erreur = Recette.valider(recette)
+	if not ok then
+		return refus(erreur)
+	end
+	local propres = {}
+	for i, a in ipairs(liste) do
+		propres[i] = copieAccessoire(a)
+	end
+	local difference = EtatAtelier.prixDecorations(recette.pieces, propres) - EtatAtelier.prixDecorations(recette.pieces, self.accessoires)
+	if difference > self.argent then
+		return refus("Pas assez d'argent pour ces décorations.")
+	end
+	self.argent -= difference
+	self.accessoires = propres
+	self.etape = "photo"
+	return { ok = true, prix = difference }
+end
+
+-- De la photo, on peut revenir ajuster les décorations
+function EtatAtelier:retourDecorations()
+	if self.etape ~= "photo" then
+		return refus("Ce n'est pas le moment.")
+	end
+	self.etape = "decorations"
+	return { ok = true }
+end
+
+-- Fin de la commande : l'atelier est prêt pour la suivante
+local function terminer(self)
+	self.commande, self.croquis = nil, nil
+	self.tissus, self.coupees, self.coupons = {}, {}, {}
+	self.epinglees, self.coutures, self.accessoires = {}, {}, {}
+	self.etape = "accueil"
+end
+
+-- Livraison : la cliente juge la robe (styles, qualité, couleur, accessoires) d'après sa recette.
+-- Acceptée : paie = base × (0,5 + qualité), la robe part en vitrine. Refusée : retouche ou abandon.
+function EtatAtelier:livrer()
+	if self.etape ~= "photo" then
+		return refus("Ce n'est pas le moment de livrer.")
+	end
+	local recette = self:recette()
+	local bilan = Notation.bilan(recette)
+	local reussie, ratees = Notation.verifierExigences(self.commande.exigences, bilan)
+	if not reussie then
+		self.etape = "refus"
+		return { ok = true, reussie = false, ratees = ratees, bilan = bilan }
+	end
+	local paie = Notation.paie(#recette.pieces, #self.commande.exigences, bilan.qualite)
+	self.argent += paie
+	table.insert(self.robes, 1, recette)
+	for k = #self.robes, EtatAtelier.ROBES_GARDEES + 1, -1 do
+		self.robes[k] = nil
+	end
+	terminer(self)
+	return { ok = true, reussie = true, paie = paie, bilan = bilan, ratees = {} }
+end
+
+-- Après un refus : retoucher (retour aux décorations) ou abandonner (ni paie ni vitrine)
+function EtatAtelier:retoucher()
+	if self.etape ~= "refus" then
+		return refus("Il n'y a rien à retoucher.")
+	end
+	self.etape = "decorations"
+	return { ok = true }
+end
+
+function EtatAtelier:abandonner()
+	if self.etape ~= "refus" then
+		return refus("Il n'y a rien à abandonner.")
+	end
+	terminer(self)
+	return { ok = true }
+end
+
 -- Abandonne la robe en cours (le tissu déjà coupé est perdu), garde la commande
 function EtatAtelier:recommencer()
 	if self.etape == "accueil" then
@@ -297,7 +422,7 @@ function EtatAtelier:recommencer()
 	end
 	consommer(self)
 	self.croquis, self.tissus, self.coupees = nil, {}, {}
-	self.epinglees, self.coutures = {}, {}
+	self.epinglees, self.coutures, self.accessoires = {}, {}, {}
 	self.argent = math.max(self.argent, EtatAtelier.FILET) -- jamais bloqué sans argent ni tissu
 	self.etape = "carnet"
 	return { ok = true }
```

- [ ] **Step 4: Lancer les tests**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT"`
Expected:
```
Unitaires : 104534 vérifications
TOUT EST VERT : 227 vérifications
```

- [ ] **Step 5: Commit**

```bash
git add src/shared/EtatAtelier.luau tests/unitaires/21_decorations_livraison.luau
git commit -m "EtatAtelier : décorations facturées à la différence, livraison, retouche et abandon

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 2: Point touché sur la robe et accessoire seul

**Files:**
- Modify: `src/shared/Patron.luau`
- Modify: `src/shared/ConstructeurRobe.luau`
- Test: `tests/unitaires/03_patron.luau` (tests ajoutés à la fin)
- Test: `tests/unitaires/12_constructeur.luau` (tests ajoutés à la fin)

**Interfaces:**
- Consumes: `Patron.point`, `Polygone.contient`, `Polygone.boite` ; `construireAccessoire` (local à `ConstructeurRobe`).
- Produces :
  - `Patron.versUV(id, copie, point, mesures) -> (u, v, ecart)` : le point est dans le repère du corps, en dm ; `u` et `v` sont pris dans la boîte du patron (comme les accessoires) ; `ecart` est la distance en dm ;
  - `ConstructeurRobe.accessoire(recette, a, cadre, parent) -> Model` : un « Accessoire_<id> » parenté, posé comme dans la robe complète.

- [ ] **Step 1: Ajouter les tests**

```diff
diff --git a/tests/unitaires/03_patron.luau b/tests/unitaires/03_patron.luau
index 57800a0..47d11ad 100644
--- a/tests/unitaires/03_patron.luau
+++ b/tests/unitaires/03_patron.luau
@@ -165,3 +165,36 @@ for id, def in pairs(Catalogue.Pieces) do
 		end
 	end
 end
+
+-- Décorations : un point touché sur la robe 3D (repère du corps) redonne sa place (u, v) sur le patron
+local mesuresL = Catalogue.TAILLES.L
+local rngUV = Random.new(5)
+local essais, pires = 0, 0
+for _, cas in ipairs({
+	{ "corsage_v_devant", "unique" },
+	{ "manche_ballon", "gauche" },
+	{ "manche_ballon", "droite" },
+	{ "jupe_evasee_dos", "unique" },
+	{ "col_claudine", "droite" },
+}) do
+	local id, copie = cas[1], cas[2]
+	local b = Polygone.boite(Catalogue.piece(id).contour)
+	local trouves = 0
+	while trouves < 12 do
+		local u0, v0 = rngUV:NextNumber(0.05, 0.95), rngUV:NextNumber(0.05, 0.95)
+		local x, y = b.minX + u0 * (b.maxX - b.minX), b.minY + v0 * (b.maxY - b.minY)
+		if Polygone.contient(Catalogue.piece(id).contour, x, y) then
+			trouves += 1
+			local p = Patron.point(id, copie, x, y, mesuresL)
+			local u, v, ecart = Patron.versUV(id, copie, p, mesuresL)
+			local q = Patron.point(id, copie, b.minX + u * (b.maxX - b.minX), b.minY + v * (b.maxY - b.minY), mesuresL)
+			essais += 1
+			if (q - p).Magnitude > 0.05 or ecart > 0.05 then
+				pires += 1
+			end
+		end
+	end
+end
+U.verifier(essais == 60 and pires == 0, ("point touché → (u, v) à moins de 0,05 dm près : %d ratés sur %d"):format(pires, essais))
+local _, _, loin = Patron.versUV("corsage_droit_devant", "unique", Vector3.new(0, 30, 0), mesuresL)
+U.verifier(loin > 10, "un point loin de la pièce : grand écart (la touche n'est pas sur cette pièce)")
```

```diff
diff --git a/tests/unitaires/12_constructeur.luau b/tests/unitaires/12_constructeur.luau
index 15082c6..bca0097 100644
--- a/tests/unitaires/12_constructeur.luau
+++ b/tests/unitaires/12_constructeur.luau
@@ -191,3 +191,18 @@ coupee = ConstructeurRobe.construire(zigzag, cadre, M.services.Workspace, {
 })
 U.verifier(coupee.Parent == nil and #coupee:GetChildren() == 1, "robe détruite pendant la génération : construction arrêtée")
 U.verifier(M.editables.maillages == 0 and M.editables.images == 0, "aucun objet modifiable laissé par l'arrêt")
+
+-- Décorations : un accessoire seul, pour l'aperçu pendant qu'on le pose (même place que dans la robe)
+local seul = Instance.new("Folder")
+seul.Parent = M.services.Workspace
+local recetteSeule = exemple()
+local noeudSeul = ConstructeurRobe.accessoire(recetteSeule, recetteSeule.accessoires[1], cadre, seul)
+U.verifier(noeudSeul ~= nil and noeudSeul.Parent == seul and noeudSeul.Name == "Accessoire_noeud_satin", "accessoire seul construit sous le parent donné")
+local centreSeul = Vector3.new(0, 0, 0)
+for _, p in ipairs(noeudSeul:GetChildren()) do
+	centreSeul += p.CFrame.Position
+end
+centreSeul /= #noeudSeul:GetChildren()
+U.verifier((centreSeul - centreNoeud).Magnitude < 1e-6, "accessoire seul : même place que dans la robe complète")
+local dentelleSeule = ConstructeurRobe.accessoire(recetteSeule, recetteSeule.accessoires[3], cadre, seul)
+U.verifier(#dentelleSeule:GetChildren() == #dentelle:GetChildren(), "garniture seule : même ruban")
```

- [ ] **Step 2: Vérifier qu'ils échouent**

Run: `bash tests/lancer.sh 2>&1 | grep -m1 -E "ÉCHEC|attempt"`
Expected: une erreur « attempt to call a nil value » (`Patron.versUV` n'existe pas).

- [ ] **Step 3: Ajouter `Patron.versUV`**

```diff
diff --git a/src/shared/Patron.luau b/src/shared/Patron.luau
index 936294e..58a6918 100644
--- a/src/shared/Patron.luau
+++ b/src/shared/Patron.luau
@@ -158,6 +158,46 @@ function Patron.point(id, copie, x, y, mesures)
 	return position, dehors
 end
 
+-- Place (u, v) sur le patron (boîte normalisée, comme les accessoires) du point de la surface le plus
+-- proche de « point » (repère du corps, dm), et la distance en dm. Sert à poser une décoration là où
+-- l'on touche la robe 3D : recherche sur une grille dans la pièce, puis affinée autour du meilleur point.
+local GRILLE_UV = 24
+function Patron.versUV(id, copie, point, mesures)
+	local contour = Patron.def(id).contour
+	local b = Polygone.boite(contour)
+	local l, h = b.maxX - b.minX, b.maxY - b.minY
+	local function distance(u, v)
+		return (Patron.point(id, copie, b.minX + u * l, b.minY + v * h, mesures) - point).Magnitude
+	end
+	local meilleurU, meilleurV, meilleure = 0.5, 0.5, math.huge
+	for i = 0, GRILLE_UV do
+		for j = 0, GRILLE_UV do
+			local u, v = i / GRILLE_UV, j / GRILLE_UV
+			if Polygone.contient(contour, b.minX + u * l, b.minY + v * h) then
+				local d = distance(u, v)
+				if d < meilleure then
+					meilleurU, meilleurV, meilleure = u, v, d
+				end
+			end
+		end
+	end
+	local pas = 1 / GRILLE_UV
+	for _ = 1, 6 do
+		local bu, bv = meilleurU, meilleurV
+		for di = -2, 2 do
+			for dj = -2, 2 do
+				local u, v = math.clamp(bu + di * pas / 2, 0, 1), math.clamp(bv + dj * pas / 2, 0, 1)
+				local d = distance(u, v)
+				if d < meilleure then
+					meilleurU, meilleurV, meilleure = u, v, d
+				end
+			end
+		end
+		pas /= 2
+	end
+	return meilleurU, meilleurV, meilleure
+end
+
 -- Normale exacte de la surface au point (x, y) du patron, tournée vers l'extérieur
 -- (sert à poser les accessoires à plat sur le tissu)
 function Patron.normale(id, copie, x, y, mesures)
```

- [ ] **Step 4: Exporter la construction d'un accessoire seul**

```diff
diff --git a/src/shared/ConstructeurRobe.luau b/src/shared/ConstructeurRobe.luau
index d961deb..b414aff 100644
--- a/src/shared/ConstructeurRobe.luau
+++ b/src/shared/ConstructeurRobe.luau
@@ -225,6 +225,14 @@ local function construireAccessoire(recette, a, cadre, parent, souffler)
 	return groupe
 end
 
+-- Un accessoire seul (aperçu pendant les décorations) : a = accessoire de la recette (même format),
+-- posé exactement comme dans la robe complète. Retourne le Model « Accessoire_<id> », parenté.
+function ConstructeurRobe.accessoire(recette, a, cadre, parent)
+	return construireAccessoire(recette, a, cadre, parent, function()
+		return true
+	end)
+end
+
 ---------------------------------------------------------------------------
 -- Robe complète
 ---------------------------------------------------------------------------
```

- [ ] **Step 5: Lancer les tests**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT"`
Expected:
```
Unitaires : 104539 vérifications
TOUT EST VERT : 227 vérifications
```

- [ ] **Step 6: Commit**

```bash
git add src/shared/Patron.luau src/shared/ConstructeurRobe.luau tests/unitaires/03_patron.luau tests/unitaires/12_constructeur.luau
git commit -m "Patron.versUV (point touché sur la robe) et ConstructeurRobe.accessoire (aperçu)

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 3: Logique de l'éditeur de décorations (`Decorateur`)

**Files:**
- Create: `src/client/Atelier/Decorateur.luau`
- Test: `tests/unitaires/22_decorateur.luau`

**Interfaces:**
- Consumes: `EtatAtelier.prixDecorations` (tâche 1), `Recette.MAX_ACCESSOIRES`, `Recette.MAX_POINTS_GARNITURE`, `Recette.ECHELLE_MIN`, `Recette.ECHELLE_MAX`, `Patron.copies`, `Catalogue.accessoire`.
- Produces :
  - `Decorateur.nouveau(recette, payees) -> deco`, avec les champs `recette`, `liste`, `choix`, `selection` et `garniture` (`{ id, piece, copie, trajet }` en cours) ;
  - méthodes :
    - `deco:choisir(id) -> bool` ;
    - `deco:toucher(indicePiece, copie, u, v) -> { ok, erreur?, action = "pose" | "point" }` ;
    - `deco:terminerGarniture() -> bool`, `deco:selectionner(indice) -> bool` ;
    - `deco:tourner(degres)`, `deco:redimensionner(delta)`, `deco:supprimer()`, `deco:annuler() -> bool` ;
    - `deco:cout() -> integer` (négatif : remboursement) ;
    - `deco:resultat() -> liste` (garniture en cours comprise).

- [ ] **Step 1: Écrire les tests**

`tests/unitaires/22_decorateur.luau` :

```lua
local Decorateur = U.module("Decorateur")
local EtatAtelier = U.module("EtatAtelier")
local Recette = U.module("Recette")

local recette = {
	version = 1,
	croquis = { corsage = "corsage_droit", manches = "manches_ballon", col = "col_sans", jupe = "jupe_droite" },
	mesures = { poitrine = 8.8, taille = 7.0, hanches = 9.4 },
	pieces = {
		{ id = "corsage_droit_devant", tissu = "coton_blanc", x = 2.4, y = 2.1, angle = 0, couture = 1 },
		{ id = "corsage_droit_dos", tissu = "coton_blanc", x = 7.2, y = 2.1, angle = 0, couture = 1 },
		{ id = "manche_ballon", tissu = "coton_blanc", x = 5, y = 5, angle = 0, couture = 1 },
		{ id = "jupe_droite_devant", tissu = "coton_blanc", x = 2.5, y = 9, angle = 0, couture = 1 },
		{ id = "jupe_droite_dos", tissu = "coton_blanc", x = 7.5, y = 9, angle = 0, couture = 1 },
	},
	accessoires = {},
}

---------------------------------------------------------------------------
-- Objets
---------------------------------------------------------------------------
local d = Decorateur.nouveau(recette, {})
U.verifier(#d.liste == 0 and d:cout() == 0 and d.selection == nil, "départ : rien de posé, rien à payer")
U.verifier(not d:toucher(1, "unique", 0.5, 0.5).ok, "toucher la robe sans accessoire choisi : rien")
U.verifier(not d:choisir("diamant") and d.choix == nil, "accessoire inconnu refusé")
U.verifier(d:choisir("noeud_satin") and d.choix == "noeud_satin", "nœud choisi dans la palette")
local r = d:toucher(1, "unique", 0.5, 0.3)
U.verifier(r.ok and r.action == "pose" and #d.liste == 1 and d.selection == 1, "le nœud est posé et sélectionné")
local a = d.liste[1]
U.verifier(a.id == "noeud_satin" and a.piece == 1 and a.u == 0.5 and a.v == 0.3 and a.echelle == 1 and a.angle == 0 and a.copie == nil, "nœud : pièce, place, taille 1, angle 0")
d:toucher(3, "droite", 0.4, 0.6)
U.verifier(d.liste[2].copie == "droite", "sur une manche : la copie touchée est gardée")
U.verifier(d:cout() == 6, "deux nœuds : 6 po")
d:tourner(45)
d:tourner(170)
U.verifier(d.liste[2].angle == -145, "rotation ramenée entre −180 et 180")
d:redimensionner(0.5)
d:redimensionner(10)
U.verifier(d.liste[2].echelle == Recette.ECHELLE_MAX, "taille bornée à 3")
d:redimensionner(-10)
U.verifier(d.liste[2].echelle == Recette.ECHELLE_MIN, "taille bornée à 0,5")
U.verifier(d:selectionner(1) and d.selection == 1 and not d:selectionner(5), "sélection d'un accessoire posé")
d:supprimer()
U.verifier(#d.liste == 1 and d.liste[1].piece == 3 and d.selection == nil, "accessoire supprimé")
U.verifier(not d:toucher(1, "unique", 1.5, 0.5).ok and not d:toucher(9, "unique", 0.5, 0.5).ok, "touche hors pièce refusée")

---------------------------------------------------------------------------
-- Annuler
---------------------------------------------------------------------------
U.verifier(d:annuler() and #d.liste == 2, "annuler la suppression")
U.verifier(d:annuler() and d.liste[2].echelle == 3, "annuler la dernière taille")
while d:annuler() do
end
U.verifier(#d.liste == 0, "tout annulé")

---------------------------------------------------------------------------
-- Garnitures : point par point, sur une seule pièce
---------------------------------------------------------------------------
local g = Decorateur.nouveau(recette, {})
g:choisir("dentelle_blanche")
r = g:toucher(4, "unique", 0, 1)
U.verifier(r.ok and r.action == "point" and g.garniture ~= nil and #g.liste == 0, "premier point de la dentelle")
U.verifier(not g:terminerGarniture(), "une garniture a besoin de deux points")
U.verifier(not g:toucher(5, "unique", 0.5, 1).ok, "une garniture reste sur une seule pièce")
g:toucher(4, "unique", 0.5, 1)
g:toucher(4, "unique", 1, 1)
U.verifier(g:cout() == 10, "dentelle en cours comptée dans le coût (5 dm à 2 po)")
U.verifier(g:terminerGarniture() and #g.liste == 1 and g.garniture == nil and #g.liste[1].trajet == 3, "dentelle terminée : 3 points")
g:toucher(4, "unique", 0, 0.5)
for k = 1, 63 do
	g:toucher(4, "unique", k / 64, 0.5)
end
U.verifier(not g:toucher(4, "unique", 1, 0.4).ok and #g.garniture.trajet == 64, "64 points au plus")
g:choisir("perle")
U.verifier(g.garniture == nil and #g.liste == 2, "changer d'accessoire termine la garniture en cours")
U.verifier(g:annuler() and #g.liste == 1, "annuler la garniture entière")

---------------------------------------------------------------------------
-- Coût : différence avec ce qui est déjà payé ; liste acceptée par EtatAtelier
---------------------------------------------------------------------------
local payees = { { id = "noeud_satin", piece = 1, u = 0.5, v = 0.3, echelle = 1, angle = 0 } }
local avec = table.clone(recette)
avec.accessoires = payees
local p = Decorateur.nouveau(avec, payees)
U.verifier(#p.liste == 1 and p:cout() == 0, "décorations déjà payées : rien de plus à payer")
p:selectionner(1)
p:supprimer()
U.verifier(p:cout() == -3, "retirer un nœud payé : remboursé")
p.liste[1] = nil
U.verifier(#payees == 1, "la liste payée n'est pas modifiée par l'éditeur")
local final = Decorateur.nouveau(recette, {})
final:choisir("perle")
final:toucher(2, "unique", 0.5, 0.5)
final:choisir("ruban_rose")
final:toucher(4, "unique", 0.1, 0.9)
final:toucher(4, "unique", 0.9, 0.9)
local liste = final:resultat()
local verif = table.clone(recette)
verif.accessoires = liste
U.verifier(#liste == 2 and Recette.valider(verif), "résultat : garniture en cours terminée, recette valide")
U.verifier(EtatAtelier.prixDecorations(recette.pieces, liste) == final:cout(), "le coût affiché est celui que facturera EtatAtelier")
```

- [ ] **Step 2: Vérifier qu'ils échouent**

Run: `bash tests/lancer.sh 2>&1 | grep -m1 "membre valide"`
Expected: `Decorateur n'est pas un membre valide de Folder « Couture »`

- [ ] **Step 3: Écrire le module**

`src/client/Atelier/Decorateur.luau` :

```lua
-- Decorateur : logique de l'éditeur de décorations (sans affichage), testable seule.
-- Tient la liste des décorations au format de la recette : objets posés au toucher, garnitures point
-- par point (une seule pièce, 64 points au plus), sélection, rotation, taille, suppression, annulation,
-- et le coût à payer (différence avec ce qui est déjà payé, calculée comme EtatAtelier la facturera).
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Couture = ReplicatedStorage:WaitForChild("Couture")
local Catalogue = require(Couture:WaitForChild("Catalogue"))
local Patron = require(Couture:WaitForChild("Patron"))
local Recette = require(Couture:WaitForChild("Recette"))
local EtatAtelier = require(Couture:WaitForChild("EtatAtelier"))

local Decorateur = {}
Decorateur.__index = Decorateur

local function copier(liste)
	local out = {}
	for i, a in ipairs(liste) do
		local c = table.clone(a)
		if a.trajet then
			c.trajet = {}
			for k, pt in ipairs(a.trajet) do
				c.trajet[k] = { u = pt.u, v = pt.v }
			end
		end
		out[i] = c
	end
	return out
end

local function dans01(n)
	return type(n) == "number" and n == n and n >= 0 and n <= 1
end

-- recette : recette de la robe (etat:recette()), avec les décorations déjà posées ;
-- payees : décorations déjà facturées (etat.accessoires)
function Decorateur.nouveau(recette, payees)
	return setmetatable({
		recette = recette,
		payees = copier(payees),
		liste = copier(recette.accessoires or {}),
		choix = nil, -- identifiant de l'accessoire choisi dans la palette
		selection = nil, -- indice dans la liste
		garniture = nil, -- garniture en cours : { id, piece, copie, trajet }
		historique = {},
	}, Decorateur)
end

local function memoriser(self)
	table.insert(self.historique, copier(self.liste))
end

function Decorateur:terminerGarniture()
	local g = self.garniture
	if not g or #g.trajet < 2 then
		return false
	end
	memoriser(self)
	table.insert(self.liste, g)
	self.garniture = nil
	return true
end

function Decorateur:choisir(idAccessoire)
	if not Catalogue.accessoire(idAccessoire) then
		return false
	end
	if self.garniture and not self:terminerGarniture() then
		self.garniture = nil -- garniture d'un seul point : abandonnée
	end
	self.choix = idAccessoire
	return true
end

-- On touche la robe : pièce (indice dans la recette), copie touchée, place (u, v) sur le patron
function Decorateur:toucher(indicePiece, copie, u, v)
	local p = type(indicePiece) == "number" and self.recette.pieces[indicePiece]
	if not p or not table.find(Patron.copies(p.id), copie) or not dans01(u) or not dans01(v) then
		return { ok = false, erreur = "Touche la robe pour poser la décoration." }
	end
	if not self.choix then
		return { ok = false, erreur = "Choisis d'abord une décoration." }
	end
	if #self.liste >= Recette.MAX_ACCESSOIRES then
		return { ok = false, erreur = "Il y a déjà trop de décorations." }
	end
	local copieGardee = copie ~= Patron.copies(p.id)[1] and copie or nil
	local def = Catalogue.accessoire(self.choix)
	if def.genre == "objet" then
		memoriser(self)
		table.insert(self.liste, { id = self.choix, piece = indicePiece, copie = copieGardee, u = u, v = v, echelle = 1, angle = 0 })
		self.selection = #self.liste
		return { ok = true, action = "pose" }
	end
	local g = self.garniture
	if not g then
		self.garniture = { id = self.choix, piece = indicePiece, copie = copieGardee, trajet = { { u = u, v = v } } }
		return { ok = true, action = "point" }
	end
	if g.piece ~= indicePiece or g.copie ~= copieGardee then
		return { ok = false, erreur = "Une garniture reste sur une seule pièce." }
	end
	if #g.trajet >= Recette.MAX_POINTS_GARNITURE then
		return { ok = false, erreur = "Cette garniture a déjà 64 points." }
	end
	table.insert(g.trajet, { u = u, v = v })
	return { ok = true, action = "point" }
end

function Decorateur:selectionner(indice)
	if self.liste[indice] then
		self.selection = indice
		return true
	end
	return false
end

local function objetSelectionne(self)
	local a = self.selection and self.liste[self.selection]
	return a and not a.trajet and a or nil
end

-- Tourne l'objet sélectionné (angle ramené entre −180 et 180)
function Decorateur:tourner(degres)
	if objetSelectionne(self) then
		memoriser(self)
		local a = objetSelectionne(self)
		a.angle = ((a.angle + degres + 180) % 360) - 180
	end
end

-- Agrandit ou réduit l'objet sélectionné (taille bornée comme dans la recette)
function Decorateur:redimensionner(delta)
	if objetSelectionne(self) then
		memoriser(self)
		local a = objetSelectionne(self)
		a.echelle = math.clamp(a.echelle + delta, Recette.ECHELLE_MIN, Recette.ECHELLE_MAX)
	end
end

function Decorateur:supprimer()
	if self.selection and self.liste[self.selection] then
		memoriser(self)
		table.remove(self.liste, self.selection)
		self.selection = nil
	end
end

-- Annule le dernier point de la garniture en cours, sinon la dernière modification de la liste
function Decorateur:annuler()
	local g = self.garniture
	if g then
		table.remove(g.trajet)
		if #g.trajet == 0 then
			self.garniture = nil
		end
		return true
	end
	local precedente = table.remove(self.historique)
	if not precedente then
		return false
	end
	self.liste = precedente
	self.selection = nil
	return true
end

-- Liste complète, garniture en cours comprise si elle a au moins deux points
local function complete(self)
	local liste = copier(self.liste)
	local g = self.garniture
	if g and #g.trajet >= 2 then
		table.insert(liste, copier({ g })[1])
	end
	return liste
end

-- Pièces d'or à payer (négatif : remboursement)
function Decorateur:cout()
	local pieces = self.recette.pieces
	return EtatAtelier.prixDecorations(pieces, complete(self)) - EtatAtelier.prixDecorations(pieces, self.payees)
end

-- Liste à envoyer (EtatAtelier:decorer)
function Decorateur:resultat()
	return complete(self)
end

return Decorateur
```

- [ ] **Step 4: Lancer les tests**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT"`
Expected:
```
Unitaires : 104569 vérifications
TOUT EST VERT : 227 vérifications
```

- [ ] **Step 5: Commit**

```bash
git add src/client/Atelier/Decorateur.luau tests/unitaires/22_decorateur.luau
git commit -m "Ajoute Decorateur : palette, pose, garnitures point par point, annulation et coût

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 4: Rayons, aperçu des décorations, vue qui tourne et vitrine (`Scene`)

**Files:**
- Modify: `tests/mock.luau`
- Modify: `tests/build.py`
- Modify: `src/client/Atelier/Scene.luau`
- Test: `tests/unitaires/23_scene_decorations.luau`

**Interfaces:**
- Consumes: `Patron.versUV`, `ConstructeurRobe.accessoire` (tâche 2) ; `etat:decorer`, `etat:livrer`, `etat.robes` (tâche 1) ; `Vitrines.nouveau`, `Recette.encoder`.
- Produces :
  - faux Roblox : `M.impacts` (file des impacts renvoyés par `Workspace:Raycast`), `M.dernierRayon`, `RaycastParams.new()`, `CFrame:PointToObjectSpace`, `Camera:ScreenPointToRay` et `ViewportPointToRay` ;
  - `Scene.POSTES` gagne `photo` et `refus` ; nouvelle constante `Scene.VITRINE` ;
  - `Scene.nouvelle(parent?, { etaler? })`, avec les champs `decorations` (Folder) et `socle` (Part portant l'attribut « Recette ») ;
  - méthodes :
    - `scene:montrerDecorations(recette?, liste, garniture?)` ;
    - `scene:toucher(origine, direction) -> { genre = "decoration", indice } | { genre = "piece", indicePiece, copie, u, v } | nil` ;
    - `scene:orbiter(degres)` ;
  - les pièces de la robe sont touchables (`CanQuery`) ;
  - hors des décorations, la scène montre les décorations de la recette (présentation, refus) ou aucune.

- [ ] **Step 1: Préparer les rayons dans le faux Roblox**

```diff
diff --git a/tests/mock.luau b/tests/mock.luau
index a8abb64..ebfc1f6 100644
--- a/tests/mock.luau
+++ b/tests/mock.luau
@@ -125,6 +125,9 @@ end
 function CFM.PointToWorldSpace(c, v)
 	return c * v
 end
+function CFM.PointToObjectSpace(c, v)
+	return CFM.Inverse(c) * v
+end
 CF.__index = function(c, k)
 	if CFM[k] then
 		return CFM[k]
@@ -585,6 +588,19 @@ end
 function methodes.UnbindAction(_, nom)
 	M.actions[nom] = nil
 end
+-- Rayons : aucune géométrie simulée. Un test range les impacts voulus dans M.impacts (une file) ;
+-- Workspace:Raycast renvoie le premier (ou nil) et garde le rayon et ses paramètres dans M.dernierRayon.
+function methodes.Raycast(_, origine, direction, params)
+	assert(typeDe(origine) == "Vector3" and typeDe(direction) == "Vector3", "Raycast : Vector3 attendus")
+	M.dernierRayon = { origine = origine, direction = direction, params = params }
+	return table.remove(M.impacts, 1)
+end
+function methodes.ViewportPointToRay(_, x, y)
+	return { Origin = Vector3.new(x, y, 0), Direction = Vector3.new(0, 0, 1) }
+end
+function methodes.ScreenPointToRay(_, x, y)
+	return { Origin = Vector3.new(x, y, 0), Direction = Vector3.new(0, 0, 1) }
+end
 function methodes.GetMouseLocation(_)
 	return M.souris or Vector2.new(0, 0)
 end
@@ -665,6 +681,7 @@ function M.initialiser()
 	M.joueurs = {}
 	M.actions = {}
 	M.coreGui = {} -- [Enum.CoreGuiType] = activé (StarterGui:SetCoreGuiEnabled)
+	M.impacts = {}
 	local game = nouvelleInstance("DataModel")
 	rawget(game, "__props").Name = "Game"
 	M.game = game
@@ -893,6 +910,11 @@ M.env = {
 	typeof = typeDe,
 	task = task,
 	Content = Content,
+	RaycastParams = {
+		new = function()
+			return { FilterType = Enum.RaycastFilterType.Exclude, FilterDescendantsInstances = {} }
+		end,
+	},
 }
 
 return M
```

```diff
diff --git a/tests/build.py b/tests/build.py
index ec873ae..5d67f83 100644
--- a/tests/build.py
+++ b/tests/build.py
@@ -4,8 +4,8 @@ ICI = os.path.dirname(os.path.abspath(__file__))
 sim = S + "/sim/"
 def lire(p): return open(p, encoding="utf-8").read()
 def nom(chemin): return os.path.basename(chemin)[: -len(".luau")]
-ENTETE = """local game, workspace, os, Vector3, Vector2, CFrame, Color3, UDim, UDim2, Enum, Random, Instance, typeof, task, require, warn, Content =
-	M.game, M.services and M.services.Workspace, M.os, G.Vector3, G.Vector2, G.CFrame, G.Color3, G.UDim, G.UDim2, G.Enum, G.Random, G.Instance, G.typeof, G.task, requireModule, avertir, G.Content
+ENTETE = """local game, workspace, os, Vector3, Vector2, CFrame, Color3, UDim, UDim2, Enum, Random, Instance, typeof, task, require, warn, Content, RaycastParams =
+	M.game, M.services and M.services.Workspace, M.os, G.Vector3, G.Vector2, G.CFrame, G.Color3, G.UDim, G.UDim2, G.Enum, G.Random, G.Instance, G.typeof, G.task, requireModule, avertir, G.Content, G.RaycastParams
 """
 OUTILS_UNITAIRES = """local U = { compte = 0 }
 function U.verifier(condition, message)
```

- [ ] **Step 2: Écrire les tests**

`tests/unitaires/23_scene_decorations.luau` :

```lua
local Scene = U.module("Scene")
local EtatAtelier = U.module("EtatAtelier")
local Catalogue = U.module("Catalogue")
local Patron = U.module("Patron")
local Recette = U.module("Recette")

local Workspace = M.services.Workspace
local camera = Workspace.CurrentCamera
M.budget.images, M.budget.maillages = 64, 7
local E = Catalogue.STUDS_PAR_DM

-- Robe coupée, épinglée et cousue (corsage droit, manches ballon, jupe droite), aux décorations
local CROQUIS = { corsage = "corsage_droit", manches = "manches_ballon", col = "col_sans", jupe = "jupe_droite" }
local PLACES = {
	corsage_droit_devant = { x = 2.4, y = 2.1, angle = 0 },
	corsage_droit_dos = { x = 9.6, y = 2.1, angle = 0 },
	manche_ballon = { x = 5.35, y = 6.5, angle = 0 },
	jupe_droite_devant = { x = 2.5, y = 12, angle = 0 },
	jupe_droite_dos = { x = 7.5, y = 12, angle = 0 },
}
local etat = EtatAtelier.nouveau(1000)
etat:nouvelleCommande(Random.new(3))
local tissus = {}
for id in pairs(PLACES) do
	tissus[id] = "coton_blanc"
end
etat:validerCroquis(CROQUIS, tissus)
etat:acheter("coton_blanc", 20)
etat:commencerDecoupe()
for _, id in ipairs(etat:piecesDuCroquis()) do
	assert(etat:couper(id, PLACES[id]).ok, id)
end
for _, id in ipairs(etat:piecesDuCroquis()) do
	etat:epingler(id)
end
for _, id in ipairs(etat:piecesDuCroquis()) do
	local _, longueur = Patron.trajetCouture(id)
	etat:rendreCouture(id, table.create(math.round(longueur / 0.1), 0), longueur)
end
U.verifier(etat.etape == "decorations", "robe prête à décorer")

local scene = Scene.nouvelle(Workspace, { etaler = false })
scene:synchroniser(etat)
local corsage = scene.robe:FindFirstChild("Piece_corsage_droit_devant_unique")
local mancheDroite = scene.robe:FindFirstChild("Piece_manche_ballon_droite")
U.verifier(corsage ~= nil and corsage.CanQuery and mancheDroite ~= nil and mancheDroite.CanQuery, "les pièces de la robe se touchent (rayons)")

---------------------------------------------------------------------------
-- Toucher la robe : pièce, copie et place sur le patron
---------------------------------------------------------------------------
local function surLaRobe(id, copie, u, v)
	local b = Catalogue.piece(id).contour
	local minX, maxX, minY, maxY = math.huge, -math.huge, math.huge, -math.huge
	for _, p in ipairs(b) do
		minX, maxX, minY, maxY = math.min(minX, p.x), math.max(maxX, p.x), math.min(minY, p.y), math.max(maxY, p.y)
	end
	local pos = Patron.point(id, copie, minX + u * (maxX - minX), minY + v * (maxY - minY), etat.commande.mesures)
	return Scene.CADRE * (pos * E), pos
end
local ou, voulu = surLaRobe("manche_ballon", "droite", 0.4, 0.5)
M.impacts = { { Instance = mancheDroite, Position = ou, Normal = Vector3.new(0, 0, -1) } }
local t = scene:toucher(Vector3.new(0, 3, 30), Vector3.new(0, 0, 50))
U.verifier(t ~= nil and t.genre == "piece" and t.indicePiece == 3 and t.copie == "droite", "touche sur la manche droite : 3e pièce du croquis, copie droite")
local b = Catalogue.piece("manche_ballon").contour
local minX, maxX, minY, maxY = math.huge, -math.huge, math.huge, -math.huge
for _, p in ipairs(b) do
	minX, maxX, minY, maxY = math.min(minX, p.x), math.max(maxX, p.x), math.min(minY, p.y), math.max(maxY, p.y)
end
local retrouve = Patron.point("manche_ballon", "droite", minX + t.u * (maxX - minX), minY + t.v * (maxY - minY), etat.commande.mesures)
U.verifier((retrouve - voulu).Magnitude < 0.05, "la place touchée est retrouvée sur le patron")
local params = M.dernierRayon.params
U.verifier(params.FilterType == Enum.RaycastFilterType.Include and table.find(params.FilterDescendantsInstances, scene.robe) ~= nil, "le rayon ne vise que la robe et ses décorations")
U.verifier(scene:toucher(Vector3.new(0, 3, 30), Vector3.new(0, 0, 50)) == nil, "rien touché : rien")
M.impacts = { { Instance = Workspace, Position = Vector3.new(0, 0, 0), Normal = Vector3.new(0, 1, 0) } }
U.verifier(scene:toucher(Vector3.new(0, 3, 30), Vector3.new(0, 0, 50)) == nil, "impact hors de la robe : rien")

---------------------------------------------------------------------------
-- Aperçu des décorations
---------------------------------------------------------------------------
local recette = etat:recette()
local liste = {
	{ id = "noeud_satin", piece = 1, u = 0.5, v = 0.3, echelle = 1, angle = 0 },
	{ id = "perle", piece = 3, copie = "droite", u = 0.4, v = 0.5, echelle = 1, angle = 0 },
}
scene:montrerDecorations(recette, liste, { id = "dentelle_blanche", piece = 4, trajet = { { u = 0, v = 1 }, { u = 1, v = 1 } } })
local enfants = scene.decorations:GetChildren()
U.verifier(#enfants == 3, "deux décorations posées et la garniture en cours")
local perle = enfants[2]
U.verifier(perle.Name == "Accessoire_perle" and perle:GetAttribute("Indice") == 2 and enfants[3]:GetAttribute("Indice") == nil, "chaque décoration posée connaît sa place dans la liste")
local partPerle = perle:GetChildren()[1]
U.verifier(partPerle.CanQuery, "une décoration se touche (pour la sélectionner)")
M.impacts = { { Instance = partPerle, Position = partPerle.CFrame.Position, Normal = Vector3.new(0, 0, -1) } }
t = scene:toucher(Vector3.new(0, 3, 30), Vector3.new(0, 0, 50))
U.verifier(t ~= nil and t.genre == "decoration" and t.indice == 2, "touche sur la perle : décoration n° 2")
scene:montrerDecorations(recette, { liste[1] }, nil)
U.verifier(#scene.decorations:GetChildren() == 1, "l'aperçu suit la liste")
scene:montrerDecorations(nil, {}, nil)
U.verifier(#scene.decorations:GetChildren() == 0, "sans robe : aucun aperçu")

---------------------------------------------------------------------------
-- Caméra qui tourne autour du mannequin (décorations)
---------------------------------------------------------------------------
U.verifier(camera.CFrame == Scene.CAMERA, "départ : caméra de face")
local centre = Scene.CADRE.Position
local function distanceAxe(p)
	return Vector3.new(p.X - centre.X, 0, p.Z - centre.Z).Magnitude
end
scene:orbiter(90)
local oeil = camera.CFrame.Position
U.verifier(math.abs(distanceAxe(oeil) - distanceAxe(Scene.CAMERA.Position)) < 1e-6 and math.abs(oeil.Y - Scene.CAMERA.Position.Y) < 1e-6, "la caméra tourne autour du mannequin, à la même distance")
U.verifier((oeil - Scene.CAMERA.Position).Magnitude > 1, "la caméra a bien tourné")
scene:orbiter(-90)
U.verifier((camera.CFrame.Position - Scene.CAMERA.Position).Magnitude < 1e-6, "retour de face")
scene:orbiter(45)
etat:decorer({})
scene:synchroniser(etat)
U.verifier(camera.CFrame == Scene.CAMERA, "en quittant les décorations, la caméra revient de face")

---------------------------------------------------------------------------
-- Vitrine : la dernière robe livrée
---------------------------------------------------------------------------
U.verifier(scene.socle ~= nil and scene.socle:GetAttribute("Recette") == nil, "vitrine vide avant la première livraison")
etat.commande.exigences = { { type = "qualite", valeur = 0.5 } }
U.verifier(etat:livrer().reussie, "robe livrée")
scene:synchroniser(etat)
U.verifier(scene.socle:GetAttribute("Recette") == Recette.encoder(etat.robes[1]), "la robe livrée part en vitrine")
U.verifier(#scene.robe:GetChildren() == 0 and scene.dossier:FindFirstChild("Mannequin") == nil, "le mannequin de travail est libéré pour la cliente suivante")
M.avancer(1)
U.verifier(scene.socle:FindFirstChild("Exposition") ~= nil, "la vitrine se construit quand on est près")
scene:detruire()
U.verifier(scene.dossier.Parent == nil, "scène détruite")
```

- [ ] **Step 3: Vérifier qu'ils échouent**

Run: `bash tests/lancer.sh 2>&1 | grep -m1 -E "ÉCHEC|attempt"`
Expected: `ÉCHEC : les pièces de la robe se touchent (rayons)`

- [ ] **Step 4: Étendre `Scene`**

```diff
diff --git a/src/client/Atelier/Scene.luau b/src/client/Atelier/Scene.luau
index efd553e..36b66d4 100644
--- a/src/client/Atelier/Scene.luau
+++ b/src/client/Atelier/Scene.luau
@@ -1,6 +1,7 @@
 -- Scene : le coin de l'atelier en 3D, côté client. Le mannequin aux mesures de la cliente, les pièces
--- épinglées dessus (le vrai tissu découpé), et la caméra fixe des postes autour du mannequin.
--- Au plan 4, la boutique construite par le serveur donnera l'emplacement du mannequin.
+-- épinglées dessus (le vrai tissu découpé), l'aperçu des décorations, la vitrine de la dernière robe
+-- livrée, et la caméra fixe des postes autour du mannequin (qui peut tourner pendant les décorations).
+-- Au plan 4, la boutique construite par le serveur donnera l'emplacement du mannequin et de la vitrine.
 local ReplicatedStorage = game:GetService("ReplicatedStorage")
 local Workspace = game:GetService("Workspace")
 local Couture = ReplicatedStorage:WaitForChild("Couture")
@@ -8,6 +9,8 @@ local Catalogue = require(Couture:WaitForChild("Catalogue"))
 local Patron = require(Couture:WaitForChild("Patron"))
 local Mannequin = require(Couture:WaitForChild("Mannequin"))
 local ConstructeurRobe = require(Couture:WaitForChild("ConstructeurRobe"))
+local Recette = require(Couture:WaitForChild("Recette"))
+local Vitrines = require(Couture:WaitForChild("Vitrines"))
 
 local Scene = {}
 Scene.__index = Scene
@@ -17,16 +20,50 @@ Scene.CADRE = CFrame.new(0, Mannequin.HAUTEUR_TAILLE * Catalogue.STUDS_PAR_DM, 4
 -- Caméra face au mannequin, décalée pour le laisser à gauche de l'écran (le panneau est à droite)
 Scene.CAMERA = CFrame.lookAt(Vector3.new(-1.1, 2.6, 34.6), Vector3.new(-1.1, 2.2, 40))
 -- Étapes où la caméra montre le mannequin
-Scene.POSTES = { epinglage = true, couture = true, decorations = true }
+Scene.POSTES = { epinglage = true, couture = true, decorations = true, photo = true, refus = true }
+-- Socle de la vitrine (la dernière robe livrée), en retrait du mannequin de travail
+Scene.VITRINE = CFrame.new(7, 0.5, 52)
 
-function Scene.nouvelle(parent)
+-- options : { etaler = bool } pour la construction de la vitrine (défaut vrai)
+function Scene.nouvelle(parent, options)
 	local dossier = Instance.new("Folder")
 	dossier.Name = "AtelierLocal"
 	local robe = Instance.new("Model")
 	robe.Name = "Robe"
 	robe.Parent = dossier
+	local decorations = Instance.new("Folder")
+	decorations.Name = "Decorations"
+	decorations.Parent = dossier
+	local vitrines = Instance.new("Folder")
+	vitrines.Name = "Vitrines"
+	vitrines.Parent = dossier
+	local socle = Instance.new("Part")
+	socle.Name = "Socle"
+	socle.Anchored = true
+	socle.Size = Vector3.new(4, 1, 4)
+	socle.CFrame = Scene.VITRINE
+	socle.Material = Enum.Material.Wood
+	socle.Color = Color3.fromRGB(120, 84, 56)
+	socle.Parent = vitrines
 	dossier.Parent = parent or Workspace
-	return setmetatable({ dossier = dossier, robe = robe, mesures = nil, mannequin = nil, pieces = {}, cameraFixe = false, ouverte = true }, Scene)
+	local self = setmetatable({
+		dossier = dossier,
+		robe = robe,
+		decorations = decorations,
+		socle = socle,
+		mesures = nil,
+		mannequin = nil,
+		recette = nil,
+		pieces = {},
+		cameraFixe = false,
+		ouverte = true,
+		orbite = 0, -- degrés autour du mannequin (décorations)
+	}, Scene)
+	self.vitrines = Vitrines.nouveau(vitrines, function()
+		local camera = Workspace.CurrentCamera
+		return camera and camera.CFrame.Position or Scene.VITRINE.Position
+	end, { etaler = not options or options.etaler ~= false })
+	return self
 end
 
 local function memesMesures(a, b)
@@ -48,8 +85,15 @@ function Scene:synchroniser(etat)
 			self.mannequin = Mannequin.construire(mesures, Scene.CADRE, self.dossier)
 		end
 	end
+	-- Vitrine : la dernière robe livrée
+	local derniere = etat.robes and etat.robes[1]
+	local texte = derniere and Recette.encoder(derniere) or nil
+	if self.socle:GetAttribute("Recette") ~= texte then
+		self.socle:SetAttribute("Recette", texte)
+	end
 	-- Pièces épinglées
 	local recette = etat:recette()
+	self.recette = recette
 	local voulues = {}
 	if recette then
 		for _, p in ipairs(recette.pieces) do
@@ -66,6 +110,15 @@ function Scene:synchroniser(etat)
 			self.pieces[id] = nil
 		end
 	end
+	if etat.etape ~= "decorations" then
+		self.orbite = 0
+	end
+	-- Décorations : l'écran des décorations montre la liste qu'il édite ; ailleurs, celles de la recette
+	if etat.etape == "photo" or etat.etape == "refus" then
+		self:montrerDecorations(recette, recette.accessoires, nil)
+	elseif etat.etape ~= "decorations" then
+		self:montrerDecorations(nil, {}, nil)
+	end
 	self:regarder(self.ouverte and Scene.POSTES[etat.etape] == true)
 	if not recette then
 		return
@@ -77,6 +130,7 @@ function Scene:synchroniser(etat)
 			for _, copie in ipairs(Patron.copies(p.id)) do
 				local part = ConstructeurRobe.piece(p, copie, recette.mesures, Scene.CADRE, "robe")
 				if part and self.pieces[p.id] == entree and self.dossier.Parent then
+					part.CanQuery = true -- touchée par les rayons des décorations
 					part.Parent = self.robe
 					table.insert(entree.parts, part)
 				elseif part then
@@ -87,6 +141,72 @@ function Scene:synchroniser(etat)
 	end
 end
 
+-- Aperçu des décorations : la liste (format de la recette) et la garniture en cours ; chaque décoration
+-- posée garde sa place dans la liste (attribut « Indice ») pour être sélectionnée au toucher
+function Scene:montrerDecorations(recette, liste, garniture)
+	self.decorations:ClearAllChildren()
+	if not recette then
+		return
+	end
+	local r = table.clone(recette)
+	r.accessoires = liste
+	local function poser(a, indice)
+		local groupe = ConstructeurRobe.accessoire(r, a, Scene.CADRE, self.decorations)
+		groupe:SetAttribute("Indice", indice)
+		for _, d in ipairs(groupe:GetDescendants()) do
+			if d:IsA("BasePart") then
+				d.CanQuery = true
+			end
+		end
+	end
+	for i, a in ipairs(liste) do
+		poser(a, i)
+	end
+	if garniture and #garniture.trajet >= 2 then
+		poser(garniture, nil)
+	end
+end
+
+-- Ce que touche un rayon (repère du monde) : une décoration { genre = "decoration", indice },
+-- une pièce de la robe { genre = "piece", indicePiece, copie, u, v }, ou nil
+function Scene:toucher(origine, direction)
+	local params = RaycastParams.new()
+	params.FilterType = Enum.RaycastFilterType.Include
+	params.FilterDescendantsInstances = { self.robe, self.decorations }
+	local impact = Workspace:Raycast(origine, direction, params)
+	local i = impact and impact.Instance
+	while i and i.Parent ~= self.decorations and i.Parent ~= self.robe do
+		i = i.Parent
+	end
+	if not i then
+		return nil
+	end
+	if i.Parent == self.decorations then
+		local indice = i:GetAttribute("Indice")
+		return indice and { genre = "decoration", indice = indice } or nil
+	end
+	local id, copie = i.Name:match("^Piece_(.+)_(%a+)$")
+	if not id or not self.recette then
+		return nil
+	end
+	for k, p in ipairs(self.recette.pieces) do
+		if p.id == id then
+			local point = Scene.CADRE:PointToObjectSpace(impact.Position) / Catalogue.STUDS_PAR_DM
+			local u, v = Patron.versUV(id, copie, point, self.recette.mesures)
+			return { genre = "piece", indicePiece = k, copie = copie, u = u, v = v }
+		end
+	end
+	return nil
+end
+
+-- Tourne la caméra autour du mannequin (degrés), pendant les décorations
+function Scene:orbiter(degres)
+	self.orbite = (self.orbite + degres) % 360
+	if self.cameraFixe then
+		self:regarder(true)
+	end
+end
+
 -- Fenêtre de l'atelier fermée : la caméra revient au joueur ; rouverte : elle repart au poste
 function Scene:ouvrir(ouverte, etat)
 	self.ouverte = ouverte
@@ -101,7 +221,13 @@ function Scene:regarder(actif)
 	end
 	if actif then
 		camera.CameraType = Enum.CameraType.Scriptable
-		camera.CFrame = Scene.CAMERA
+		if self.orbite == 0 then
+			camera.CFrame = Scene.CAMERA
+		else
+			-- Même vue, tournée autour de l'axe vertical du mannequin
+			local axe = CFrame.new(Scene.CADRE.Position)
+			camera.CFrame = axe * CFrame.Angles(0, math.rad(self.orbite), 0) * axe:Inverse() * Scene.CAMERA
+		end
 		self.cameraFixe = true
 	elseif self.cameraFixe then
 		camera.CameraType = Enum.CameraType.Custom
@@ -111,6 +237,7 @@ end
 
 function Scene:detruire()
 	self:regarder(false)
+	self.vitrines.arreter()
 	self.pieces = {}
 	self.dossier:Destroy()
 end
```

- [ ] **Step 5: Lancer les tests**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT"`
Expected:
```
Unitaires : 104593 vérifications
TOUT EST VERT : 227 vérifications
```

- [ ] **Step 6: Commit**

```bash
git add tests/mock.luau tests/build.py src/client/Atelier/Scene.luau tests/unitaires/23_scene_decorations.luau
git commit -m "Scène : rayons sur la robe, aperçu des décorations, vue qui tourne, vitrine locale

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 5: Écrans des décorations, de la présentation et du refus ; scénario complet

**Files:**
- Modify: `tests/scenario.luau`
- Modify: `src/client/Atelier/Session.luau`
- Modify: `src/client/Atelier/UiKit.luau`
- Create: `src/client/Atelier/EcranDecorations.luau`
- Create: `src/client/Atelier/EcranPresentation.luau`
- Create: `src/client/Atelier/EcranRefus.luau`
- Modify: `src/client/Atelier/EcranAccueil.luau`
- Delete: `src/client/Atelier/EcranSuite.luau`
- Modify: `src/client/Atelier/init.client.luau`

**Interfaces:**
- Consumes: tâches 1 à 4 ; `Notation.bilan`.
- Produces :
  - `Session:decorer(liste)`, `Session:retourDecorations()`, `Session:livrer()`, `Session:retoucher()`, `Session:abandonner()` ;
  - `session.derniere = { action, reponse }` (dernière action réussie) et `Session.courante` (la session du joueur) ;
  - `UiKit.exigence(e, Catalogue, styles?)` ;
  - titres : `6. Décorations`, `7. Présentation`, `La cliente refuse la robe` (tous trois en panneau à droite) ;
  - noms stables pour le scénario et Studio :
    - décorations : `Contenu.Cout`, `Contenu.Palette.Deco_<id>`, `Tourner-15`, `Tourner15`, `Reduire`, `Agrandir`, `Supprimer`, `Annuler`, `FinirGarniture`, `Presenter`, `Recommencer` ;
    - présentation : `Contenu.Qualite`, `Livrer`, `RetourDecorations`, `Recommencer` ;
    - refus : `Retoucher`, `Abandonner` ;
    - accueil : `Contenu.Annonce` ;
    - scène : `Workspace.AtelierLocal.Decorations` et `Vitrines.Socle`.

- [ ] **Step 1: Compléter le scénario**

```diff
diff --git a/tests/scenario.luau b/tests/scenario.luau
index ffdadb7..540843f 100644
--- a/tests/scenario.luau
+++ b/tests/scenario.luau
@@ -369,18 +369,115 @@ for k = 3, 6 do
 end
 
 ---------------------------------------------------------------------------
--- Robe cousue, recommencer
+-- Décorations
 ---------------------------------------------------------------------------
-verifier(titre() == "La robe est cousue !", "écran de suite après la dernière couture")
-verifier(fenetre.AnchorPoint.X == 1 and #robe:GetChildren() == 8, "la robe cousue est visible sur le mannequin")
-verifier(texte("Qualité de la robe :") ~= nil, "la qualité de la robe est affichée")
-verifierTailles("robe cousue")
 verifier(ratee ~= nil and ratee < 20, "la couture ratée est mal notée : " .. tostring(ratee))
-cliquer("Recommencer")
-verifier(titre() == "La robe est cousue !", "un appui sur « Recommencer » ne suffit pas")
-cliquer("Recommencer")
-verifier(titre() == "1. Carnet de croquis", "recommencer ramène au carnet avec la même commande")
-verifier(#robe:GetChildren() == 0 and camera.CameraType == Enum.CameraType.Custom, "robe retirée du mannequin, caméra rendue au joueur")
+verifier(titre() == "6. Décorations", "robe cousue : les décorations")
+verifier(fenetre.AnchorPoint.X == 1 and #robe:GetChildren() == 8, "panneau à droite, la robe cousue sur le mannequin")
+verifierTailles("décorations")
+local SessionModule = requireModule(scriptClient.Session)
+local ScenePoste = requireModule(scriptClient.Scene)
+local PatronModule = requireModule(dossier.Patron)
+local PolygoneModule = requireModule(dossier.Polygone)
+local etatJeu = SessionModule.courante.etat
+local contenuD = fenetre.Contenu
+local decorations = scene.Decorations
+local ACCENT = Color3.fromRGB(214, 76, 128)
+-- La cliente veut une croix d'argent : sans elle, la robe sera refusée
+etatJeu.commande.exigences = { { type = "accessoire", id = "croix_argent" }, { type = "min", style = "romantique", valeur = 1 } }
+-- La palette ne montre que des rangées entières (une rangée coupée attirerait les clics à côté)
+local palette = contenuD.Palette
+verifier(palette.Size.Y.Offset % 44 == 0, "palette : rangées entières")
+-- Point de la robe (monde) à la place (u, v) d'une pièce
+local function point3D(id, copie, u, v)
+	local b = PolygoneModule.boite(Catalogue.piece(id).contour)
+	local pos = PatronModule.point(id, copie, b.minX + u * (b.maxX - b.minX), b.minY + v * (b.maxY - b.minY), etatJeu.commande.mesures)
+	return ScenePoste.CADRE * (pos * Catalogue.STUDS_PAR_DM)
+end
+-- Toucher la scène : le rayon du faux Roblox renvoie l'impact préparé
+local function toucherScene(impact)
+	M.impacts = { impact }
+	local appui = { UserInputType = Enum.UserInputType.MouseButton1, Position = Vector3.new(200, 250, 0) }
+	M.avancer(0.5)
+	UIS.InputBegan:Fire(appui, false)
+	UIS.InputEnded:Fire(appui, false)
+end
+local function toucherRobe(nomPart, id, copie, u, v)
+	toucherScene({ Instance = robe[nomPart], Position = point3D(id, copie, u, v), Normal = Vector3.new(0, 0, -1) })
+end
+local function centre(groupe)
+	local somme, n = Vector3.new(0, 0, 0), 0
+	for _, d in ipairs(groupe:GetChildren()) do
+		somme += d.CFrame.Position
+		n += 1
+	end
+	return somme / n
+end
+verifier(contenuD.Cout.Text == "Coût : 0 po", "rien posé : rien à payer")
+toucherRobe("Piece_corsage_v_devant_unique", "corsage_v_devant", "unique", 0.5, 0.4)
+verifier(#decorations:GetChildren() == 0 and fenetre.Message.Visible, "toucher la robe sans décoration choisie : un message")
+cliquer("Deco_noeud_satin")
+verifier(boutonNomme("Deco_noeud_satin").BackgroundColor3 == ACCENT, "nœud de satin choisi dans la palette")
+toucherRobe("Piece_corsage_v_devant_unique", "corsage_v_devant", "unique", 0.5, 0.4)
+verifier(#decorations:GetChildren() == 1 and contenuD.Cout.Text == "Coût : 3 po", "nœud posé sur le corsage : 3 po")
+local noeud = decorations:GetChildren()[1]
+verifier((centre(noeud) - point3D("corsage_v_devant", "unique", 0.5, 0.4)).Magnitude < 0.3, "le nœud est là où l'on a touché")
+local tailleAvant = noeud:GetChildren()[1].Size
+cliquer("Agrandir")
+verifier(decorations:GetChildren()[1]:GetChildren()[1].Size.X > tailleAvant.X, "le nœud sélectionné grandit")
+cliquer("Tourner15")
+verifier(contenuD.Cout.Text == "Coût : 3 po", "tourner ou agrandir ne coûte rien")
+-- Garniture point par point
+cliquer("Deco_ruban_rose")
+toucherRobe("Piece_jupe_trapeze_devant_unique", "jupe_trapeze_devant", "unique", 0.1, 0.9)
+toucherRobe("Piece_jupe_trapeze_devant_unique", "jupe_trapeze_devant", "unique", 0.9, 0.9)
+verifier(boutonNomme("FinirGarniture").Visible, "garniture en cours : bouton pour la finir")
+cliquer("FinirGarniture")
+local coutRuban = tonumber(contenuD.Cout.Text:match("(%d+) po"))
+verifier(#decorations:GetChildren() == 2 and coutRuban and coutRuban > 3, "ruban posé le long de la jupe : " .. contenuD.Cout.Text)
+-- Toucher une décoration la sélectionne ; supprimer, puis annuler
+local partNoeud = decorations:GetChildren()[1]:GetChildren()[1]
+toucherScene({ Instance = partNoeud, Position = partNoeud.CFrame.Position, Normal = Vector3.new(0, 0, -1) })
+cliquer("Supprimer")
+verifier(#decorations:GetChildren() == 1 and contenuD.Cout.Text == ("Coût : %d po"):format(coutRuban - 3), "nœud touché puis supprimé")
+cliquer("Annuler")
+verifier(#decorations:GetChildren() == 2 and contenuD.Cout.Text == ("Coût : %d po"):format(coutRuban), "annuler : le nœud revient")
+-- Glisser sur la scène fait tourner la vue autour du mannequin (sans rien poser)
+local glisse = { UserInputType = Enum.UserInputType.MouseButton1, Position = Vector3.new(100, 300, 0) }
+UIS.InputBegan:Fire(glisse, false)
+UIS.InputChanged:Fire({ UserInputType = Enum.UserInputType.MouseMovement, Position = Vector3.new(220, 300, 0) }, false)
+UIS.InputEnded:Fire(glisse, false)
+verifier(camera.CFrame ~= ScenePoste.CAMERA and #decorations:GetChildren() == 2, "glisser fait tourner la vue, sans rien poser")
+
+---------------------------------------------------------------------------
+-- Présentation, refus, retouche, livraison
+---------------------------------------------------------------------------
+local avantDeco = argent()
+cliquer("Presenter")
+verifier(titre() == "7. Présentation" and argent() == avantDeco - coutRuban, "présenter : décorations payées")
+verifier(camera.CFrame == ScenePoste.CAMERA, "la cliente voit la robe de face")
+verifier(texte("Au moins 1 en Romantique (actuel :") ~= nil, "le score actuel est affiché à côté d'une exigence de style")
+verifier(#decorations:GetChildren() == 2, "la robe est présentée avec ses décorations")
+verifierTailles("présentation")
+cliquer("RetourDecorations")
+verifier(titre() == "6. Décorations" and #decorations:GetChildren() == 2 and contenuD.Cout.Text == "Coût : 0 po", "retour aux décorations : déjà payées")
+cliquer("Presenter")
+cliquer("Livrer")
+verifier(titre() == "La cliente refuse la robe" and texte("Avec : Croix d'argent") ~= nil, "sans la croix d'argent : robe refusée, exigence ratée affichée")
+verifierTailles("refus")
+cliquer("Retoucher")
+verifier(titre() == "6. Décorations", "retouche : retour aux décorations")
+cliquer("Deco_croix_argent")
+toucherRobe("Piece_corsage_v_devant_unique", "corsage_v_devant", "unique", 0.5, 0.7)
+cliquer("Presenter")
+local avantLivraison = argent()
+cliquer("Livrer")
+verifier(titre() == "Atelier de couture" and argent() > avantLivraison, "robe acceptée : payée")
+verifier(texte("La cliente est ravie") ~= nil, "l'accueil annonce la paie")
+verifier(scene.Vitrines.Socle:GetAttribute("Recette") ~= nil, "la robe livrée part en vitrine")
+verifier(#robe:GetChildren() == 0 and #decorations:GetChildren() == 0 and camera.CameraType == Enum.CameraType.Custom, "atelier libéré, caméra rendue au joueur")
+cliquer("Clochette")
+verifier(titre() == "1. Carnet de croquis", "nouvelle cliente")
 
 ---------------------------------------------------------------------------
 -- Robe en six tissus : la mise en page tient (lignes d'achat, onglets de la découpe)
```

- [ ] **Step 2: Vérifier qu'il échoue**

Run: `bash tests/lancer.sh 2>&1 | grep -m1 -E "ÉCHEC|attempt"`
Expected: `ÉCHEC : robe cousue : les décorations`

- [ ] **Step 3: Actions de la session**

```diff
diff --git a/src/client/Atelier/Session.luau b/src/client/Atelier/Session.luau
index 38809c2..ddbc6e5 100644
--- a/src/client/Atelier/Session.luau
+++ b/src/client/Atelier/Session.luau
@@ -10,7 +10,8 @@ Session.__index = Session
 
 -- graine : pour des commandes reproductibles (tests) ; sinon aléatoire
 function Session.nouvelle(graine)
-	local self = setmetatable({ etat = EtatAtelier.nouveau(), rng = Random.new(graine), ecouteurs = {} }, Session)
+	local self = setmetatable({ etat = EtatAtelier.nouveau(), rng = Random.new(graine), ecouteurs = {}, derniere = nil }, Session)
+	Session.courante = self -- la session du joueur (tests du scénario, débogage dans Studio)
 	return self
 end
 
@@ -25,9 +26,11 @@ function Session:surChangement(f)
 	end
 end
 
+-- derniere = { action, reponse } de la dernière action réussie (l'accueil affiche la dernière livraison)
 local function agir(self, nom, ...)
 	local reponse = self.etat[nom](self.etat, ...)
 	if reponse.ok then
+		self.derniere = { action = nom, reponse = reponse }
 		for _, f in ipairs(table.clone(self.ecouteurs)) do
 			f(self.etat)
 		end
@@ -59,6 +62,21 @@ end
 function Session:rendreCouture(idPiece, ecarts, duree, assistance)
 	return agir(self, "rendreCouture", idPiece, ecarts, duree, assistance)
 end
+function Session:decorer(liste)
+	return agir(self, "decorer", liste)
+end
+function Session:retourDecorations()
+	return agir(self, "retourDecorations")
+end
+function Session:livrer()
+	return agir(self, "livrer")
+end
+function Session:retoucher()
+	return agir(self, "retoucher")
+end
+function Session:abandonner()
+	return agir(self, "abandonner")
+end
 function Session:recommencer()
 	return agir(self, "recommencer")
 end
```

- [ ] **Step 4: Score actuel dans le texte des exigences**

```diff
diff --git a/src/client/Atelier/UiKit.luau b/src/client/Atelier/UiKit.luau
index 22416df..f096451 100644
--- a/src/client/Atelier/UiKit.luau
+++ b/src/client/Atelier/UiKit.luau
@@ -133,12 +133,14 @@ function UiKit.couleur(c)
 	return Color3.fromRGB(c[1], c[2], c[3])
 end
 
--- Texte lisible d'une exigence de commande
-function UiKit.exigence(e, Catalogue)
+-- Texte lisible d'une exigence de commande ; styles (facultatif) : scores actuels de la robe,
+-- ajoutés aux exigences de style pour savoir ce qu'il reste à faire
+function UiKit.exigence(e, Catalogue, styles)
+	local actuel = styles and e.style and (" (actuel : %d)"):format(math.floor(styles[e.style] + 0.5)) or ""
 	if e.type == "min" then
-		return ("Au moins %d en %s"):format(e.valeur, Catalogue.NOMS_STYLES[e.style])
+		return ("Au moins %d en %s"):format(e.valeur, Catalogue.NOMS_STYLES[e.style]) .. actuel
 	elseif e.type == "max" then
-		return ("Au plus %d en %s"):format(e.valeur, Catalogue.NOMS_STYLES[e.style])
+		return ("Au plus %d en %s"):format(e.valeur, Catalogue.NOMS_STYLES[e.style]) .. actuel
 	elseif e.type == "qualite" then
 		return ("Qualité d'au moins %d %%"):format(math.floor(e.valeur * 100 + 0.5))
 	elseif e.type == "teinte" then
```

- [ ] **Step 5: Écrire l'écran des décorations**

`src/client/Atelier/EcranDecorations.luau` :

```lua
-- Écran des décorations (panneau à droite, la robe sur le mannequin) : choisir une décoration dans la
-- palette, toucher la robe pour la poser, ou toucher une décoration posée pour la sélectionner ; tourner
-- (Q/E), agrandir, supprimer, annuler ; garnitures point par point. Glisser sur la scène fait tourner la vue.
-- La logique est dans Decorateur ; « Présenter à la cliente » envoie la liste (EtatAtelier:decorer).
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local Couture = ReplicatedStorage:WaitForChild("Couture")
local Catalogue = require(Couture:WaitForChild("Catalogue"))
local Decorateur = require(script.Parent:WaitForChild("Decorateur"))

local SEUIL_GLISSER = 8 -- px : au-delà, c'est un glisser (la vue tourne), pas une touche
local DEGRES_PAR_PX = 0.5
local LIGNE_PALETTE = 44

return function(ctx)
	local UiKit, session, contenu, scene = ctx.UiKit, ctx.session, ctx.contenu, ctx.scene
	local C = UiKit.COULEURS
	local connexions = {}
	local deco = Decorateur.nouveau(session.etat:recette(), session.etat.accessoires)
	local rafraichir

	local cout = UiKit.texte({ Name = "Cout", Font = Enum.Font.GothamBold, TextSize = 18, Size = UDim2.new(1, 0, 0, 24), Parent = contenu })
	UiKit.texte({
		Text = "Choisis une décoration, puis touche la robe. Glisse sur la scène pour tourner la vue.",
		TextSize = 14,
		TextColor3 = C.texteDoux,
		Position = UDim2.fromOffset(0, 26),
		Size = UDim2.new(1, 0, 0, 40),
		Parent = contenu,
	})

	-- Palette : objets à l'unité, garnitures au dm
	local palette = UiKit.creer("ScrollingFrame", {
		Name = "Palette",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 6,
		Position = UDim2.fromOffset(0, 70),
		Size = UDim2.new(1, 0, 0, 3 * LIGNE_PALETTE), -- trois rangées entières, le reste défile
		CanvasSize = UDim2.fromOffset(0, math.ceil(#Catalogue.Accessoires / 2) * LIGNE_PALETTE),
		Parent = contenu,
	})
	local boutons = {}
	for k, a in ipairs(Catalogue.Accessoires) do
		local prix = a.genre == "garniture" and ("%d po/dm"):format(a.prix) or ("%d po"):format(a.prix)
		boutons[a.id] = UiKit.boutonDoux({
			Name = "Deco_" .. a.id,
			Text = a.nom .. " · " .. prix,
			TextSize = 14,
			TextWrapped = true,
			Position = UDim2.new(((k - 1) % 2) * 0.5, 0, 0, ((k - 1) // 2) * LIGNE_PALETTE),
			Size = UDim2.new(0.5, -10, 0, LIGNE_PALETTE - 4),
			Parent = palette,
		}, function()
			deco:choisir(a.id)
			rafraichir()
		end)
	end

	-- Outils sur la décoration sélectionnée
	local function outil(nom, texte, x, y, largeur, action)
		return UiKit.boutonDoux({ Name = nom, Text = texte, TextSize = 14, Position = UDim2.new(x, 0, 0, y), Size = UDim2.new(largeur, -6, 0, 34), Parent = contenu }, function()
			action()
			rafraichir()
		end)
	end
	outil("Tourner-15", "« 15°", 0, 228, 0.25, function()
		deco:tourner(-15)
	end)
	outil("Tourner15", "15° »", 0.25, 228, 0.25, function()
		deco:tourner(15)
	end)
	outil("Reduire", "Plus petit", 0.5, 228, 0.25, function()
		deco:redimensionner(-0.25)
	end)
	outil("Agrandir", "Plus grand", 0.75, 228, 0.25, function()
		deco:redimensionner(0.25)
	end)
	outil("Supprimer", "Supprimer", 0, 268, 0.5, function()
		deco:supprimer()
	end)
	outil("Annuler", "Annuler", 0.5, 268, 0.5, function()
		deco:annuler()
	end)
	local finir = outil("FinirGarniture", "Finir la garniture", 0, 308, 1, function()
		if not deco:terminerGarniture() then
			ctx.message("Une garniture a besoin d'au moins deux points.", C.erreur)
		end
	end)
	UiKit.bouton({ Name = "Presenter", Text = "Présenter à la cliente", Position = UDim2.fromOffset(0, 350), Size = UDim2.new(1, -6, 0, 44), Parent = contenu }, function()
		local r = session:decorer(deco:resultat())
		if not r.ok then
			ctx.message(r.erreur, C.erreur)
		end
	end, 0.4)
	UiKit.boutonConfirme({ Name = "Recommencer", Text = "Recommencer la robe", TextSize = 14, AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), Size = UDim2.fromOffset(200, 34), Parent = contenu }, function()
		local r = session:recommencer()
		if not r.ok then
			ctx.message(r.erreur, C.erreur)
		end
	end)

	rafraichir = function()
		local n = deco:cout()
		cout.Text = n >= 0 and ("Coût : %d po"):format(n) or ("Remboursement : %d po"):format(-n)
		for id, b in pairs(boutons) do
			b.BackgroundColor3 = id == deco.choix and C.accent or C.secondaire
			b.TextColor3 = id == deco.choix and Color3.new(1, 1, 1) or C.texte
		end
		finir.Visible = deco.garniture ~= nil
		scene:montrerDecorations(deco.recette, deco.liste, deco.garniture)
	end

	-- Toucher la scène : une décoration posée (sélection) ou la robe (pose)
	local function toucher(position)
		local camera = Workspace.CurrentCamera
		local rayon = camera:ScreenPointToRay(position.X, position.Y)
		local t = scene:toucher(rayon.Origin, rayon.Direction * 100)
		if not t then
			return
		end
		if t.genre == "decoration" then
			deco:selectionner(t.indice)
		else
			local r = deco:toucher(t.indicePiece, t.copie, t.u, t.v)
			if not r.ok then
				ctx.message(r.erreur, C.erreur)
			end
		end
		rafraichir()
	end

	-- Appui sur la scène (hors interface) : touche si on ne bouge pas, sinon la vue tourne
	local appui = nil
	table.insert(connexions, UserInputService.InputBegan:Connect(function(input, traite)
		if traite or not ctx.fenetre.Visible then
			return
		end
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			appui = { objet = input, depart = input.Position, dernierX = input.Position.X, glisse = false }
		elseif input.KeyCode == Enum.KeyCode.Q or input.KeyCode == Enum.KeyCode.E then
			deco:tourner(input.KeyCode == Enum.KeyCode.Q and -15 or 15)
			rafraichir()
		end
	end))
	table.insert(connexions, UserInputService.InputChanged:Connect(function(input)
		if not appui then
			return
		end
		local suit = if appui.objet.UserInputType == Enum.UserInputType.Touch
			then input == appui.objet
			else input.UserInputType == Enum.UserInputType.MouseMovement
		if not suit then
			return
		end
		if not appui.glisse and (input.Position - appui.depart).Magnitude > SEUIL_GLISSER then
			appui.glisse = true
		end
		if appui.glisse then
			scene:orbiter((input.Position.X - appui.dernierX) * DEGRES_PAR_PX)
		end
		appui.dernierX = input.Position.X
	end))
	table.insert(connexions, UserInputService.InputEnded:Connect(function(input)
		if not appui then
			return
		end
		local fin = input == appui.objet
			or (appui.objet.UserInputType == Enum.UserInputType.MouseButton1 and input.UserInputType == Enum.UserInputType.MouseButton1)
		if fin then
			local a = appui
			appui = nil
			if not a.glisse then
				toucher(a.depart)
			end
		end
	end))

	rafraichir()
	return function()
		for _, c in ipairs(connexions) do
			c:Disconnect()
		end
	end
end
```

- [ ] **Step 6: Écrire les écrans de présentation et de refus**

`src/client/Atelier/EcranPresentation.luau` :

```lua
-- Présentation (panneau à droite, la robe décorée sur le mannequin, vue de face) : la cliente regarde
-- la robe. On la livre, ou on retourne aux décorations. La photo (décor, éclairage) arrive au plan 3d.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Couture = ReplicatedStorage:WaitForChild("Couture")
local Catalogue = require(Couture:WaitForChild("Catalogue"))
local Notation = require(Couture:WaitForChild("Notation"))

return function(ctx)
	local UiKit, session, contenu = ctx.UiKit, ctx.session, ctx.contenu
	local C = UiKit.COULEURS
	local etat = session.etat
	local bilan = Notation.bilan(etat:recette())

	UiKit.texte({ Text = "La cliente examine ta robe.", TextSize = 16, Size = UDim2.new(1, 0, 0, 24), Parent = contenu })
	UiKit.texte({
		Name = "Qualite",
		Text = ("Qualité de la robe : %d %%"):format(math.floor(bilan.qualite * 100 + 0.5)),
		Font = Enum.Font.GothamBold,
		TextSize = 18,
		Position = UDim2.fromOffset(0, 32),
		Size = UDim2.new(1, 0, 0, 26),
		Parent = contenu,
	})
	UiKit.texte({ Text = "Elle voulait :", TextSize = 14, TextColor3 = C.texteDoux, Position = UDim2.fromOffset(0, 70), Size = UDim2.new(1, 0, 0, 20), Parent = contenu })
	for i, e in ipairs(etat.commande.exigences) do
		UiKit.texte({ Text = "· " .. UiKit.exigence(e, Catalogue, bilan.styles), TextSize = 14, Position = UDim2.fromOffset(0, 70 + i * 22), Size = UDim2.new(1, 0, 0, 20), Parent = contenu })
	end
	UiKit.bouton({ Name = "Livrer", Text = "Livrer la robe", Position = UDim2.fromOffset(0, 190), Size = UDim2.new(1, -6, 0, 46), Parent = contenu }, function()
		local r = session:livrer()
		if not r.ok then
			ctx.message(r.erreur, C.erreur)
		end
	end, 0.4)
	UiKit.boutonDoux({ Name = "RetourDecorations", Text = "Retour aux décorations", TextSize = 14, Position = UDim2.fromOffset(0, 246), Size = UDim2.new(1, -6, 0, 36), Parent = contenu }, function()
		local r = session:retourDecorations()
		if not r.ok then
			ctx.message(r.erreur, C.erreur)
		end
	end)
	UiKit.boutonConfirme({ Name = "Recommencer", Text = "Recommencer la robe", TextSize = 14, AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), Size = UDim2.fromOffset(200, 34), Parent = contenu }, function()
		local r = session:recommencer()
		if not r.ok then
			ctx.message(r.erreur, C.erreur)
		end
	end)
	return function() end
end
```

`src/client/Atelier/EcranRefus.luau` :

```lua
-- La cliente refuse la robe (panneau à droite, la robe sur le mannequin) : les exigences ratées.
-- On retouche (retour aux décorations) ou on abandonne la commande (ni paie ni vitrine).
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Couture = ReplicatedStorage:WaitForChild("Couture")
local Catalogue = require(Couture:WaitForChild("Catalogue"))
local Notation = require(Couture:WaitForChild("Notation"))

return function(ctx)
	local UiKit, session, contenu = ctx.UiKit, ctx.session, ctx.contenu
	local C = UiKit.COULEURS
	local etat = session.etat
	local derniere = session.derniere
	local ratees = derniere and derniere.action == "livrer" and derniere.reponse.ratees or {}
	local styles = Notation.bilan(etat:recette()).styles

	UiKit.texte({ Text = "Ce n'est pas ce qu'elle voulait :", TextSize = 16, Size = UDim2.new(1, 0, 0, 24), Parent = contenu })
	for k, i in ipairs(ratees) do
		UiKit.texte({
			Text = "× " .. UiKit.exigence(etat.commande.exigences[i], Catalogue, styles),
			Font = Enum.Font.GothamBold,
			TextSize = 16,
			TextColor3 = C.erreur,
			Position = UDim2.fromOffset(0, 8 + k * 26),
			Size = UDim2.new(1, 0, 0, 24),
			Parent = contenu,
		})
	end
	UiKit.texte({
		Text = "Tu peux ajouter ou retirer des décorations. Le tissu et la couture, eux, ne changent plus.",
		TextSize = 14,
		TextColor3 = C.texteDoux,
		Position = UDim2.fromOffset(0, 130),
		Size = UDim2.new(1, 0, 0, 40),
		Parent = contenu,
	})
	UiKit.bouton({ Name = "Retoucher", Text = "Retoucher la robe", Position = UDim2.fromOffset(0, 186), Size = UDim2.new(1, -6, 0, 46), Parent = contenu }, function()
		local r = session:retoucher()
		if not r.ok then
			ctx.message(r.erreur, C.erreur)
		end
	end)
	UiKit.boutonConfirme({ Name = "Abandonner", Text = "Abandonner la commande", TextSize = 14, Position = UDim2.fromOffset(0, 244), Size = UDim2.new(1, -6, 0, 36), Parent = contenu }, function()
		local r = session:abandonner()
		if not r.ok then
			ctx.message(r.erreur, C.erreur)
		end
	end)
	return function() end
end
```

- [ ] **Step 7: Accueil, écran provisoire retiré, branchement**

```diff
diff --git a/src/client/Atelier/EcranAccueil.luau b/src/client/Atelier/EcranAccueil.luau
index d69052b..aeaae00 100644
--- a/src/client/Atelier/EcranAccueil.luau
+++ b/src/client/Atelier/EcranAccueil.luau
@@ -1,18 +1,36 @@
 -- Écran d'accueil : la clochette du comptoir fait entrer une cliente et crée la commande.
+-- Après une livraison, il annonce ce qu'a pensé la cliente précédente.
 return function(ctx)
 	local UiKit = ctx.UiKit
+	local C = UiKit.COULEURS
+	local decalage = 0
+	local derniere = ctx.session.derniere
+	local annonce, couleur = nil, C.ok
+	if derniere and derniere.action == "livrer" and derniere.reponse.reussie then
+		annonce = ("La cliente est ravie ! +%d pièces d'or (qualité %d %%). Sa robe est en vitrine."):format(
+			derniere.reponse.paie,
+			math.floor(derniere.reponse.bilan.qualite * 100 + 0.5)
+		)
+	elseif derniere and derniere.action == "abandonner" then
+		annonce, couleur = "Commande abandonnée : pas de paie cette fois.", C.alerte
+	end
+	if annonce then
+		UiKit.texte({ Name = "Annonce", Text = annonce, Font = Enum.Font.GothamBold, TextSize = 18, TextColor3 = couleur, Size = UDim2.new(1, 0, 0, 50), Parent = ctx.contenu })
+		decalage = 60
+	end
 	UiKit.texte({
 		Text = "Bienvenue dans ton atelier ! Une cliente attend à la porte. Fais sonner la clochette pour "
-			.. "prendre sa commande : tu dessineras la robe dans ton carnet, tu achèteras le tissu, "
-			.. "puis tu découperas les pièces du patron.",
+			.. "prendre sa commande : tu dessineras la robe, achèteras le tissu, découperas, épingleras "
+			.. "et coudras les pièces, puis tu la décoreras avant de la livrer.",
 		TextSize = 18,
+		Position = UDim2.fromOffset(0, decalage),
 		Size = UDim2.new(1, 0, 0, 90),
 		Parent = ctx.contenu,
 	})
 	UiKit.bouton({
 		Name = "Clochette",
 		Text = "Sonner la clochette",
-		Position = UDim2.fromOffset(0, 110),
+		Position = UDim2.fromOffset(0, 110 + decalage),
 		Size = UDim2.fromOffset(260, 50),
 		Parent = ctx.contenu,
 	}, function()
```

```bash
git rm -q src/client/Atelier/EcranSuite.luau
```

```diff
diff --git a/src/client/Atelier/init.client.luau b/src/client/Atelier/init.client.luau
index e9c6efb..caaf619 100644
--- a/src/client/Atelier/init.client.luau
+++ b/src/client/Atelier/init.client.luau
@@ -13,7 +13,9 @@ local ECRANS = {
 	decoupe = require(script:WaitForChild("EcranDecoupe")),
 	epinglage = require(script:WaitForChild("EcranEpinglage")),
 	couture = require(script:WaitForChild("EcranCouture")),
-	decorations = require(script:WaitForChild("EcranSuite")),
+	decorations = require(script:WaitForChild("EcranDecorations")),
+	photo = require(script:WaitForChild("EcranPresentation")),
+	refus = require(script:WaitForChild("EcranRefus")),
 }
 local TITRES = {
 	accueil = "Atelier de couture",
@@ -22,10 +24,12 @@ local TITRES = {
 	decoupe = "3. Table de découpe",
 	epinglage = "4. Épinglage",
 	couture = "5. Couture",
-	decorations = "La robe est cousue !",
+	decorations = "6. Décorations",
+	photo = "7. Présentation",
+	refus = "La cliente refuse la robe",
 }
 -- Postes autour du mannequin : la fenêtre devient un panneau à droite pour laisser voir la robe
-local EN_PANNEAU = { epinglage = true, decorations = true }
+local EN_PANNEAU = { epinglage = true, decorations = true, photo = true, refus = true }
 
 local C = UiKit.COULEURS
 local joueur = Players.LocalPlayer
@@ -180,7 +184,7 @@ local function afficher()
 		disposer(EN_PANNEAU[etat.etape] == true)
 		etapeAffichee = etat.etape
 		titre.Text = TITRES[etat.etape] or etat.etape
-		fermerEcran = ECRANS[etat.etape]({ session = session, contenu = contenu, fenetre = fenetre, message = afficherMessage, UiKit = UiKit })
+		fermerEcran = ECRANS[etat.etape]({ session = session, contenu = contenu, fenetre = fenetre, scene = scene, message = afficherMessage, UiKit = UiKit })
 	end
 end
 session:surChangement(afficher)
```

- [ ] **Step 8: Lancer les tests**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT"`
Expected:
```
Unitaires : 104593 vérifications
TOUT EST VERT : 266 vérifications
```

- [ ] **Step 9: Commit**

```bash
git add -A src/client/Atelier tests/scenario.luau
git commit -m "Écrans des décorations, de la présentation et du refus : la commande est bouclée

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 6: Vérification dans Studio et README

**Files:**
- Modify: `README.md`
- Modify: `AtelierCouture.rbxl` (régénéré)

**Interfaces:**
- Consumes: tout ce qui précède.
- Produces: la boucle complète, de la clochette à la vitrine. C'est le point de départ du plan 3d (photo et cliente en personne) et du plan 4 (serveur).

- [ ] **Step 1: Aller jusqu'aux décorations dans Studio**

Lancer Play avec le connecteur MCP. Faire une robe en coton à carreaux en suivant la tâche 6 du plan 3b :
1. commande, carnet (`ToutEnUnTissu`, puis `Tissu_coton_bleu_carreaux`), achat, découpe (quatre fois « Couper ») ;
2. épinglage des quatre pièces ;
3. couture en vitesse lapin avec l'assistance : maintenir `Coudre` environ 12 s, puis `PieceSuivante`, pour chaque pièce.

Expected : titre « 6. Décorations » ; panneau à droite ; palette de trois rangées entières ; « Coût : 0 po ».

- [ ] **Step 2: Poser une décoration avec le vrai rayon de Roblox**

1. Lire la position à l'écran du devant du corsage avec `execute_luau` (Client) : `workspace.CurrentCamera:WorldToScreenPoint(workspace.AtelierLocal.Robe.Piece_corsage_droit_devant_unique.Position)`.
2. Cliquer `…Contenu.Palette.Deco_noeud_satin`.
3. Avec `user_mouse_input`, cliquer à ce point de l'écran.
4. Relire la position à l'écran du centre de `workspace.AtelierLocal.Decorations.Accessoire_noeud_satin`.

Expected : « Coût : 3 po » ; le nœud est à moins de 5 px du point cliqué (vérifié dans le brouillon : au pixel près).

- [ ] **Step 3: Tourner la vue**

Avec `user_mouse_input` : `mouseButtonDown` sur la scène à gauche du panneau, trois `moveTo` de 60 px vers la droite, puis `mouseButtonUp`.

Expected : on voit le mannequin de profil (capture d'écran), et le coût est inchangé.

- [ ] **Step 4: Présenter et livrer**

1. Cliquer `…Contenu.Presenter`.
   Expected : « 7. Présentation » ; argent débité de 3 po ; vue de face ; qualité et exigences affichées, avec le score actuel pour les exigences de style.
2. Cliquer `…Contenu.Livrer`.
   Expected : robe acceptée (accueil, « La cliente est ravie ! + N pièces d'or ») ou refusée (« La cliente refuse la robe », exigences ratées en rouge avec leur score).
3. Si elle est refusée : cliquer `Retoucher`, puis `Abandonner` deux fois depuis un nouveau refus.
   Expected : retour à l'accueil, « Commande abandonnée » en orange.

- [ ] **Step 5: Vitrine**

Après une livraison acceptée, ou à défaut en posant avec `execute_luau` l'attribut « Recette » d'une recette d'exemple (`Recette.encoder`) sur `workspace.AtelierLocal.Vitrines.Socle` : fermer la fenêtre et regarder vers le mannequin.

Expected : la robe exposée sur son socle, en retrait du mannequin de travail ; aucune erreur dans la sortie.

- [ ] **Step 6: Mettre à jour le README**

`README.md` :

````markdown
# Atelier de couture — jeu Roblox

Jeu de couture sur Roblox, inspiré des mécaniques de *Dressmaker* (Cozy Lives / Free Lives, 2026).
On ne choisit pas un vêtement tout fait : on **dessine**, **coupe**, **coud** et **décore** la robe,
et le tissu découpé se voit tel quel sur la robe en 3D.

Le jeu est en cours de refonte, sous-projet par sous-projet
(spec : `docs/superpowers/specs/2026-09-28-atelier-coeur-design.md`, plans : `docs/superpowers/plans/`).

## État actuel (plan 3c)

Jouable dans Studio, en solo, sans sauvegarde (l'état de la partie vit dans le client) :

1. **Commande** : la clochette fait entrer une cliente (taille S, M ou L) avec 1 à 3 exigences de style,
   de couleur, de qualité ou d'accessoire.
2. **Carnet de croquis** : corsage, manches, col et jupe au choix ; un tissu par pièce (24 tissus, filtre par style).
   Les jauges de style et l'état des exigences se mettent à jour en direct.
3. **Achat** : métrage conseillé par tissu, quantité réglable, coût au mètre.
4. **Table de découpe** : les pièces du patron se glissent (souris ou doigt) et se tournent sur le rouleau.
   Droit-fil aimanté, pièces pliées coupées en double au pli, chevauchements refusés, place proposée.
5. **Épinglage** : le mannequin prend les mesures de la cliente ; chaque pièce touchée s'y épingle,
   dans le tissu exactement tel qu'il a été découpé.
6. **Couture** : on maintient « Coudre » (ou Espace) et on glisse pour garder l'aiguille sur le pointillé
   pendant que le tissu tire ; vitesse tortue, normale ou lapin, découd-vite, assistance (note plafonnée à 85 %).
   Une pièce finie n'est rendue qu'avec « Pièce suivante » : la dernière couture se défait encore.
7. **Décorations** : 10 objets (boutons, nœuds, fleurs, broche, perle, étoile, croix) et 5 garnitures (dentelles,
   rubans, galon). On touche la robe pour poser, on tourne (Q/E), agrandit, supprime, annule ; une garniture
   se pose point par point sur une pièce. Glisser sur la scène fait tourner la vue autour du mannequin.
   Le coût s'affiche en direct ; ce qu'on retire est remboursé.
8. **Présentation et livraison** : la cliente juge la robe (styles, qualité, couleur dominante, accessoires).
   Acceptée : paie = base × (0,5 + qualité), et la robe part en vitrine. Refusée : les exigences ratées
   s'affichent (avec le score actuel pour les styles) ; on retouche les décorations ou on abandonne.
9. La suite : photo (décor, éclairage, capture) et cliente en personne au plan 3d ; serveur, boutiques et
   sauvegarde au plan 4.

« Recommencer la robe » demande une confirmation (deuxième appui) : le tissu coupé et les décorations
posées sont perdus.

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
  | `EtatAtelier` | État de la commande et règles de chaque étape, relevé de couture vraisemblable, recette de la robe (repris par le serveur au plan 4) |
- `src/client/Atelier/` (LocalScript `Atelier` et ses modules) : l'interface.
  `Session` fait le lien avec l'état ; `TableDecoupe` et `MachineCoudre` sont la logique pure de la table
  de découpe, de la machine à coudre et de l'éditeur de décorations (`Decorateur`) ; `Scene` tient le
  mannequin, la robe épinglée, l'aperçu des décorations, la vitrine et la caméra du poste ;
  un module `Ecran…` par étape.

**Limite assumée (couture)** : le relevé de l'aiguille vient du client. `EtatAtelier` vérifie qu'il est
vraisemblable (une mesure tous les 0,1 dm de trajet à 2 près, écarts d'au plus 2 dm, durée compatible avec
la vitesse maximale), mais un tricheur peut s'attribuer une bonne couture. L'enjeu se limite à la qualité
de la robe, donc à un peu d'argent.

## Tests

`bash tests/lancer.sh` (Linux, macOS ou Windows via Git Bash, avec Python 3) exécute le code du jeu dans un
Roblox simulé, validé d'après les définitions officielles de l'API (luau-lsp 1.70.1) :
- les tests unitaires de `tests/unitaires/` (logique, géométrie, rendu avec doublures des API modifiables) ;
- `tests/scenario.luau` : une commande jouée de bout en bout en cliquant dans l'interface.

Ce qu'une simulation ne voit pas (rendu, glisser au doigt, tailles d'écran) se vérifie dans Studio :
bancs d'essai `tests/studio/` et rapport `docs/superpowers/spikes/2026-09-28-rendu-editable.md`.
````

- [ ] **Step 7: Tests, lieu régénéré, commit**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT"`
Expected:
```
Unitaires : 104593 vérifications
TOUT EST VERT : 266 vérifications
```

```bash
C:/dev/jeux/roblox-maker/rojo.exe build -o AtelierCouture.rbxl
git add README.md AtelierCouture.rbxl
git commit -m "Plan 3c terminé : décorations, présentation et livraison jouables

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```
