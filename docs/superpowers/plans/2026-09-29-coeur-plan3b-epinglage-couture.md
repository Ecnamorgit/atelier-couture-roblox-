# Cœur de l'atelier — Plan 3b : épinglage et couture

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rendre jouables l'épinglage (les pièces coupées se posent sur le mannequin, dans leur vrai tissu) et la couture à la machine (on garde l'aiguille sur le pointillé), jusqu'à une robe cousue dont la qualité s'affiche.

**Architecture:**
- **État** : `EtatAtelier` gagne deux étapes (`couture`, `decorations`), l'épinglage, le relevé de couture et la recette de la robe en cours. Le relevé est contrôlé comme le demande la spec §6 : nombre de mesures, écarts, durée. `Session` expose les deux nouvelles actions.
- **Machine à coudre** : sa logique est un module client pur, `MachineCoudre`, testé seul. Les coutures d'une pièce sont des segments droits : le défi vient d'une dérive régulière du tissu, que le joueur corrige en glissant.
- **Scène 3D** : `Scene` construit localement le mannequin aux mesures de la cliente et la robe épinglée, pièce par pièce (`ConstructeurRobe.piece`). Elle tient aussi la caméra fixe du poste.
- **Écrans** : pendant l'épinglage et à la fin, la fenêtre de l'atelier devient un panneau à droite, pour laisser voir le mannequin.

**Tech Stack:** Luau, Rojo 7.7.0-rc.1, simulation Luau 0.650 (`tests/lancer.sh`), Roblox Studio via le connecteur MCP Studio.

**Spec:** `docs/superpowers/specs/2026-09-28-atelier-coeur-design.md` (§3 qualité, §4 étapes 5 et 6, §5 rendu et pannes, §6 contrôles de la couture, §9 génération étalée). Plan précédent : `docs/superpowers/plans/2026-09-29-coeur-plan3a-postes.md`.

## Décisions de ce plan

- **Découpage** : l'ancien « plan 3b » est coupé en deux. Ce plan couvre l'épinglage et la couture ; le **plan 3c** couvrira les décorations, la photo et la livraison. Après la couture, un écran provisoire montre la robe cousue et sa qualité.
- **Dérive du tissu** : toutes les coutures du catalogue sont des segments droits (spec §3 : arêtes du contour, décalées de 0,15 dm). Suivre un segment droit n'est pas un défi en soi. Le tissu « tire » donc d'un côté ou de l'autre selon une dérive lisse et reproductible (graine), que le joueur compense en glissant. L'équilibrage de la dérive relève de la finition (plan 4).
- **« Recommencer la robe » demande une confirmation.** Un seul appui effaçait tout, tissu coupé compris : c'est arrivé par accident dans Studio, un clic au bas d'une liste étant tombé sur ce bouton. La spec veut « Recommencer » disponible à tout moment, ce qui reste vrai ; il faut maintenant un deuxième appui dans les 3 s.
- **Caméra** : fixe sur le mannequin pendant l'épinglage, la couture et l'écran de fin (spec §4 : « Chaque poste a sa caméra fixe »). Elle revient au joueur hors de ces postes, et aussi quand on ferme la fenêtre de l'atelier.

## Global Constraints

- **Dépôt** : `C:\dev\jeux\atelier-couture`, branche `refonte-couture`, créée depuis `corrections-test-studio`, où le plan 3a est fusionné. Ne rien pousser sur GitHub sans demande.
- **Rojo** : `C:/dev/jeux/roblox-maker/rojo.exe`.
- **Contraintes des plans précédents toujours valables** : unité le dm, repère du corps, fins de ligne LF, commits en français terminés par `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`, textes d'au moins 14 px à l'échelle 1 (spec §4), symboles vérifiés à l'écran.
- **Couture** (spec §3 et §6) :
  - une mesure d'écart tous les 0,1 dm de trajet (`Catalogue.PAS_MESURE_COUTURE`) ;
  - note `clamp(1 − (|écart| − 0,05) / 0,25, 0, 1)`, moyenne sur le trajet (`Notation.noteCouture`) ;
  - assistance : note plafonnée à 0,85.
- **Relevé accepté par `EtatAtelier`** : autant de mesures que `longueur / 0,1` à 2 près ; écarts finis dans [−2 ; 2] dm ; durée d'au moins 90 % de `longueur / vitesse maximale` ; vitesse maximale 1,5 dm/s.
- **Étapes** : `accueil` → `carnet` → `achat` → `decoupe` → `epinglage` → `couture` → `decorations` (écran provisoire jusqu'au plan 3c). « Recommencer » efface la robe (découpe, épinglage, couture), garde la commande et remet le filet de 20 po.
- **Rendu** (spec §5 et §9) : une pièce épinglée est construite tout de suite avec la finesse `robe`. Si la mémoire des maillages est pleine, la pièce n'est pas affichée, sans erreur, et le jeu continue.

## Review Focus

- **Couture au doigt sur un vrai téléphone.** Attendu : le doigt qui tient « Coudre » peut glisser hors du bouton sans arrêter la couture, et seul ce doigt dirige l'aiguille. La simulation n'envoie que des objets d'entrée factices, et le connecteur Studio seulement la souris.
- **Téléphone en paysage (échelle environ 0,63).** Attendu : on peut encore tenir l'aiguille. Le plateau fait alors environ 300 px et la tolérance de 0,05 dm environ 2,5 px. À mesurer ; sinon, grossir la vue de la machine à la finition.
- **Épingler vite plusieurs pièces pendant que les maillages se construisent** (environ 0,1 à 0,2 s par pièce). Attendu : l'interface ne se fige pas, chaque pièce apparaît une seule fois, et aucune pièce ne reste sur le mannequin après « Recommencer ».
- **Équilibrage de la dérive.** Attendu : sans corriger, la note est nettement plus basse qu'en corrigeant. Mesuré dans le brouillon : 38 à 94 % sans correction selon la pièce (les coutures courtes sont trop faciles), 100 % en corrigeant. À régler à la finition du plan 4.
- **Espace pour coudre pendant qu'on écrit dans le chat.** Attendu : taper un espace dans le chat ne lance pas la couture (entrée « déjà traitée » ignorée).

## Structure des fichiers

| Fichier | Rôle |
|---|---|
| `src/shared/Catalogue.luau` | + `VITESSE_COUTURE_MAX`, `ECART_MAX_COUTURE` |
| `src/shared/EtatAtelier.luau` | + étapes `couture` et `decorations`, épinglage, relevé de couture, recette de la robe |
| `src/client/Atelier/Session.luau` | + `epingler`, `rendreCouture` |
| `src/client/Atelier/MachineCoudre.luau` | Logique de la machine : aiguille, dérive, pilotage, mesures, vitesses, découd-vite, assistance |
| `src/shared/Pixels.luau` | + `Pixels.decouper` (pièce découpée transparente autour) |
| `src/shared/ConstructeurRobe.luau` | + `ConstructeurRobe.piece` (une pièce seule) |
| `src/client/Atelier/Vignettes.luau` | + `Vignettes.piece` (aperçu de la pièce découpée) |
| `src/client/Atelier/Scene.luau` | Mannequin, robe épinglée, caméra du poste |
| `src/client/Atelier/UiKit.luau` | + `LARGEUR_PANNEAU`, `boutonConfirme` |
| `src/client/Atelier/init.client.luau` | Fenêtre en panneau à droite, scène tenue à jour, caméra rendue quand la fenêtre se ferme |
| `src/client/Atelier/EcranEpinglage.luau`, `EcranCouture.luau` | Nouveaux écrans |
| `src/client/Atelier/EcranSuite.luau` | Écran provisoire de la robe cousue (qualité) |
| `src/client/Atelier/EcranDecoupe.luau` | « Recommencer la robe » à confirmer |
| `tests/unitaires/18_epinglage_couture.luau`, `19_machine_coudre.luau`, `20_scene.luau` | Tests unitaires |
| `tests/unitaires/07_pixels.luau`, `tests/scenario.luau` | Tests complétés |
| `README.md` | État du jeu au plan 3b, limite assumée de la couture |

---

### Task 1: Épinglage, relevé de couture et recette dans `EtatAtelier`

**Files:**
- Modify: `src/shared/Catalogue.luau`
- Modify: `src/shared/EtatAtelier.luau`
- Modify: `src/client/Atelier/Session.luau`
- Test: `tests/unitaires/18_epinglage_couture.luau`

**Interfaces:**
- Consumes: `Patron.trajetCouture(id) -> (segments, longueur)`, `Patron.piecesDuCroquis`, `Notation.noteCouture(ecarts, assistance)`, `Recette.VERSION`, `Catalogue.PAS_MESURE_COUTURE`, `Catalogue.PLAFOND_ASSISTANCE`.
- Produces :
  - constantes : `Catalogue.VITESSE_COUTURE_MAX = 1.5`, `Catalogue.ECART_MAX_COUTURE = 2`, `EtatAtelier.TOLERANCE_MESURES = 2`, `EtatAtelier.DUREE_MIN = 0.9` ;
  - nouveaux champs d'état : `etat.epinglees` ([pièce] = true) et `etat.coutures` ([pièce] = note de 0 à 1) ;
  - `etat:piecesAEpingler()`, `etat:piecesACoudre()` : listes dans l'ordre du croquis ;
  - `etat:epingler(idPiece) -> { ok, reste }` ; la dernière pièce mène à `couture` ;
  - `etat:rendreCouture(idPiece, ecarts, duree, assistance?) -> { ok, note, reste }` ; la dernière mène à `decorations` ;
  - `etat:recette() -> recette | nil` : valide pour `Recette.valider` dès que tout est coupé ; `couture = 0` tant que la pièce n'est pas cousue ; pas d'accessoires ;
  - `Session:epingler(idPiece)`, `Session:rendreCouture(idPiece, ecarts, duree, assistance)`.

- [ ] **Step 1: Écrire les tests**

`tests/unitaires/18_epinglage_couture.luau` :

```lua
local EtatAtelier = U.module("EtatAtelier")
local Session = U.module("Session")
local Patron = U.module("Patron")
local Catalogue = U.module("Catalogue")
local Recette = U.module("Recette")
local Notation = U.module("Notation")

local CROQUIS = { corsage = "corsage_droit", manches = "manches_sans", col = "col_sans", jupe = "jupe_droite" }
local PIECES = { "corsage_droit_devant", "corsage_droit_dos", "jupe_droite_devant", "jupe_droite_dos" }
-- Disposition sans chevauchement des 4 pièces sur un rouleau de 14 dm
local DISPOSITION = {
	corsage_droit_devant = { x = 2.4, y = 2.1, angle = 0 },
	corsage_droit_dos = { x = 7.2, y = 2.1, angle = 0 },
	jupe_droite_devant = { x = 2.5, y = 7.2, angle = 0 },
	jupe_droite_dos = { x = 7.5, y = 7.2, angle = 0 },
}

-- Commande en cours, robe entièrement coupée dans du coton blanc
local function jusquAEpinglage()
	local e = EtatAtelier.nouveau()
	e:nouvelleCommande(Random.new(3))
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
	return e
end

-- Relevé plausible d'une pièce : une mesure tous les 0,1 dm (± delta), durée à la vitesse maximale
local function releve(id, ecart, delta)
	local _, longueur = Patron.trajetCouture(id)
	local n = math.round(longueur / Catalogue.PAS_MESURE_COUTURE) + (delta or 0)
	return table.create(n, ecart or 0), longueur / Catalogue.VITESSE_COUTURE_MAX
end

---------------------------------------------------------------------------
-- Épinglage
---------------------------------------------------------------------------
local e = jusquAEpinglage()
U.verifier(e.etape == "epinglage" and #e:piecesAEpingler() == 4, "après la découpe : 4 pièces à épingler")
U.verifier(e:recette() ~= nil and e:recette().pieces[1].couture == 0, "recette disponible dès la découpe finie, couture à 0")
U.verifier(not e:rendreCouture(PIECES[1], releve(PIECES[1])).ok, "pas de couture avant l'épinglage")
U.verifier(not e:epingler("manche_ballon").ok, "pièce hors du croquis refusée")
U.verifier(not e:epingler(nil).ok and not e:epingler(42).ok, "identifiant invalide refusé")
local r = e:epingler("corsage_droit_devant")
U.verifier(r.ok and r.reste == 3 and e.epinglees.corsage_droit_devant == true, "pièce épinglée")
U.verifier(not e:epingler("corsage_droit_devant").ok, "une pièce ne s'épingle qu'une fois")
U.verifier(e:piecesAEpingler()[1] == "corsage_droit_dos", "pièces à épingler dans l'ordre du croquis")
for i = 2, 4 do
	e:epingler(PIECES[i])
end
U.verifier(e.etape == "couture" and #e:piecesACoudre() == 4, "toutes les pièces épinglées : direction la couture")
U.verifier(not e:epingler(PIECES[1]).ok, "plus d'épinglage pendant la couture")

---------------------------------------------------------------------------
-- Couture : contrôles de vraisemblance (spec §6)
---------------------------------------------------------------------------
local id = PIECES[1]
local ecarts, duree = releve(id)
U.verifier(not e:rendreCouture("manche_ballon", ecarts, duree).ok, "pièce hors du croquis refusée")
U.verifier(not e:rendreCouture(id, "x", duree).ok and not e:rendreCouture(id, nil, duree).ok, "relevé qui n'est pas une liste refusé")
U.verifier(not e:rendreCouture(id, releve(id, 0, 3)).ok, "trois mesures de trop : refusé")
U.verifier(not e:rendreCouture(id, releve(id, 0, -3)).ok, "trois mesures de moins : refusé")
for _, mauvais in ipairs({ 2.5, -2.01, 0 / 0, math.huge, "a" }) do
	local faux = table.clone(ecarts)
	faux[5] = mauvais
	U.verifier(not e:rendreCouture(id, faux, duree).ok, "écart invalide refusé : " .. tostring(mauvais))
end
local troue = table.clone(ecarts)
troue[5] = nil
U.verifier(not e:rendreCouture(id, troue, duree).ok, "mesure manquante refusée")
U.verifier(not e:rendreCouture(id, ecarts, duree * 0.85).ok, "couture trop rapide refusée")
U.verifier(not e:rendreCouture(id, ecarts, 0 / 0).ok and not e:rendreCouture(id, ecarts, nil).ok, "durée invalide refusée")
U.verifier(not e:rendreCouture(id, ecarts, duree, "oui").ok, "assistance qui n'est pas un booléen refusée")
U.verifier(e.coutures[id] == nil, "rien n'est noté après un refus")

r = e:rendreCouture(id, ecarts, duree * 0.95)
U.verifier(r.ok and r.note == 1 and r.reste == 3 and e.coutures[id] == 1, "couture parfaite : note 100 %")
U.verifier(not e:rendreCouture(id, ecarts, duree).ok, "une pièce ne se coud qu'une fois")
local releve2, duree2 = releve(PIECES[2])
r = e:rendreCouture(PIECES[2], releve2, duree2, true)
U.verifier(r.ok and r.note == Catalogue.PLAFOND_ASSISTANCE, "avec l'assistance, la note est plafonnée à 85 %")
r = e:rendreCouture(PIECES[3], releve(PIECES[3], 0.3, 2))
U.verifier(r.ok and r.note == 0, "deux mesures de trop tolérées ; écart de 0,3 dm partout : note 0")
r = e:rendreCouture(PIECES[4], releve(PIECES[4], -0.175, -2))
U.verifier(r.ok and U.proche(r.note, 0.5) and r.reste == 0, "deux mesures de moins tolérées ; écart de 0,175 dm : note 50 %")
U.verifier(e.etape == "decorations" and #e:piecesACoudre() == 0, "toutes les pièces cousues : direction les décorations")
U.verifier(not e:rendreCouture(PIECES[1], ecarts, duree).ok, "plus de couture après la dernière pièce")

---------------------------------------------------------------------------
-- Recette de la robe
---------------------------------------------------------------------------
U.verifier(EtatAtelier.nouveau():recette() == nil, "pas de recette sans commande")
local recette = e:recette()
local ok, erreur = Recette.valider(recette)
U.verifier(ok, "la recette de la robe est valide : " .. tostring(erreur))
U.verifier(#recette.pieces == 4 and #recette.accessoires == 0, "4 pièces, pas encore d'accessoires")
local p1 = recette.pieces[1]
U.verifier(p1.id == "corsage_droit_devant" and p1.tissu == "coton_blanc" and p1.x == 2.4 and p1.y == 2.1 and p1.angle == 0 and p1.couture == 1, "pièce : tissu, position sur le rouleau et note de couture")
U.verifier(recette.mesures.poitrine == e.commande.mesures.poitrine and recette.croquis.jupe == "jupe_droite", "mesures de la cliente et croquis")
recette.mesures.poitrine = 0
recette.pieces[1].couture = 0
U.verifier(e.commande.mesures.poitrine ~= 0 and e.coutures[PIECES[1]] == 1, "la recette est une copie")
-- Qualité : droit-fil parfait partout, moyenne des coutures pondérée par la surface
local aC, aJ = Patron.aire("corsage_droit_devant"), Patron.aire("jupe_droite_devant")
local attendue = (aC * 1 + aC * 0.85 + aJ * 0 + aJ * 0.5) / (2 * aC + 2 * aJ)
U.verifier(U.proche(Notation.bilan(e:recette()).qualite, attendue), "qualité de la robe d'après la recette")

---------------------------------------------------------------------------
-- Recommencer remet l'épinglage et la couture à zéro
---------------------------------------------------------------------------
U.verifier(e:recommencer().ok and e.etape == "carnet", "recommencer la robe")
U.verifier(next(e.epinglees) == nil and next(e.coutures) == nil and e:recette() == nil, "épinglage et couture effacés")
local e2 = jusquAEpinglage()
e2:epingler(PIECES[1])
U.verifier(e2:recommencer().ok and next(e2.epinglees) == nil, "recommencer pendant l'épinglage")

---------------------------------------------------------------------------
-- Session : mêmes actions, écouteurs prévenus après chaque succès
---------------------------------------------------------------------------
local s = Session.nouvelle(1)
s.etat = jusquAEpinglage()
local avis = 0
s:surChangement(function()
	avis += 1
end)
U.verifier(s:epingler(PIECES[1]).ok and avis == 1, "Session:epingler")
U.verifier(not s:epingler(PIECES[1]).ok and avis == 1, "refus : pas d'avis")
for i = 2, 4 do
	s:epingler(PIECES[i])
end
local releve3, duree3 = releve(PIECES[1])
U.verifier(s:rendreCouture(PIECES[1], releve3, duree3, false).ok and avis == 5, "Session:rendreCouture")
```

- [ ] **Step 2: Vérifier qu'ils échouent**

Run: `bash tests/lancer.sh 2>&1 | grep -m1 -E "ÉCHEC|attempt"`
Expected: `attempt to call missing method 'piecesAEpingler' of table`

- [ ] **Step 3: Ajouter les constantes de la couture**

```diff
diff --git a/src/shared/Catalogue.luau b/src/shared/Catalogue.luau
index ee5f9b7..56bfe96 100644
--- a/src/shared/Catalogue.luau
+++ b/src/shared/Catalogue.luau
@@ -13,6 +13,8 @@ Catalogue.VALEUR_COUTURE = 0.15 -- décalage du trajet de couture vers l'intéri
 Catalogue.PAS_MESURE_COUTURE = 0.1 -- une mesure d'écart tous les 0,1 dm de trajet
 Catalogue.K = { pieces = 1, tissu = 2, accessoires = 0.5 } -- poids des jauges de style
 Catalogue.PLAFOND_ASSISTANCE = 0.85
+Catalogue.VITESSE_COUTURE_MAX = 1.5 -- dm de trajet par seconde (vitesse « lapin »)
+Catalogue.ECART_MAX_COUTURE = 2 -- dm : l'aiguille ne s'écarte jamais plus du pointillé
 Catalogue.STUDS_PAR_DM = 0.3 -- échelle du rendu 3D : 1 dm de patron = 0,3 stud
 
 Catalogue.STYLES = { "elegant", "mignon", "romantique", "gothique", "chic", "decontracte" }
```

- [ ] **Step 4: Étendre `EtatAtelier`**

```diff
diff --git a/src/shared/EtatAtelier.luau b/src/shared/EtatAtelier.luau
index 54dac58..23d9520 100644
--- a/src/shared/EtatAtelier.luau
+++ b/src/shared/EtatAtelier.luau
@@ -7,6 +7,8 @@ local Catalogue = require(dossier:WaitForChild("Catalogue"))
 local Patron = require(dossier:WaitForChild("Patron"))
 local Coupon = require(dossier:WaitForChild("Coupon"))
 local Commandes = require(dossier:WaitForChild("Commandes"))
+local Notation = require(dossier:WaitForChild("Notation"))
+local Recette = require(dossier:WaitForChild("Recette"))
 
 local EtatAtelier = {}
 EtatAtelier.__index = EtatAtelier
@@ -14,8 +16,10 @@ EtatAtelier.__index = EtatAtelier
 EtatAtelier.ARGENT_DEPART = 150
 EtatAtelier.FILET = 20 -- argent minimal garanti à chaque nouvelle commande
 EtatAtelier.ACHAT_MAX = 100 -- dm par achat
--- Étapes du plan 3a (le plan 3b ajoute épinglage, couture, décorations et livraison)
-EtatAtelier.ETAPES = { "accueil", "carnet", "achat", "decoupe", "epinglage" }
+EtatAtelier.TOLERANCE_MESURES = 2 -- mesures de couture en plus ou en moins acceptées (spec §6)
+EtatAtelier.DUREE_MIN = 0.9 -- part de la durée minimale d'une couture (trajet / vitesse maximale)
+-- Étapes du plan 3b (le plan 3c ajoute la photo et la livraison après les décorations)
+EtatAtelier.ETAPES = { "accueil", "carnet", "achat", "decoupe", "epinglage", "couture", "decorations" }
 
 local function refus(message)
 	return { ok = false, erreur = message }
@@ -35,6 +39,8 @@ function EtatAtelier.nouveau(argent)
 		tissus = {}, -- [idPiece] = idTissu
 		coupons = {}, -- [idTissu] = Coupon (pendant la découpe)
 		coupees = {}, -- [idPiece] = { x, y, angle }
+		epinglees = {}, -- [idPiece] = true
+		coutures = {}, -- [idPiece] = note de couture (0 à 1)
 	}, EtatAtelier)
 end
 
@@ -57,6 +63,28 @@ function EtatAtelier:piecesAPoser()
 	return out
 end
 
+-- Pièces du croquis pas encore épinglées, dans l'ordre du croquis
+function EtatAtelier:piecesAEpingler()
+	local out = {}
+	for _, id in ipairs(self:piecesDuCroquis()) do
+		if not self.epinglees[id] then
+			table.insert(out, id)
+		end
+	end
+	return out
+end
+
+-- Pièces du croquis pas encore cousues, dans l'ordre du croquis
+function EtatAtelier:piecesACoudre()
+	local out = {}
+	for _, id in ipairs(self:piecesDuCroquis()) do
+		if self.coutures[id] == nil then
+			table.insert(out, id)
+		end
+	end
+	return out
+end
+
 -- Tissus utilisés par le croquis, dans l'ordre d'apparition
 function EtatAtelier:tissusUtilises()
 	local vus, out = {}, {}
@@ -85,6 +113,7 @@ function EtatAtelier:nouvelleCommande(rng)
 	self.commande = Commandes.generer(rng)
 	self.argent = math.max(self.argent, EtatAtelier.FILET)
 	self.croquis, self.tissus, self.coupees, self.coupons = nil, {}, {}, {}
+	self.epinglees, self.coutures = {}, {}
 	self.etape = "carnet"
 	return { ok = true, commande = self.commande }
 end
@@ -184,6 +213,83 @@ function EtatAtelier:couper(idPiece, placement)
 	return { ok = true, reste = #self:piecesAPoser() }
 end
 
+-- Épingle une pièce coupée sur le mannequin ; la dernière mène à la couture
+function EtatAtelier:epingler(idPiece)
+	if self.etape ~= "epinglage" then
+		return refus("Ce n'est pas le moment d'épingler.")
+	end
+	if type(idPiece) ~= "string" or not table.find(self:piecesDuCroquis(), idPiece) then
+		return refus("Cette pièce n'est pas dans le croquis.")
+	end
+	if self.epinglees[idPiece] then
+		return refus("Cette pièce est déjà épinglée.")
+	end
+	self.epinglees[idPiece] = true
+	local reste = #self:piecesAEpingler()
+	if reste == 0 then
+		self.etape = "couture"
+	end
+	return { ok = true, reste = reste }
+end
+
+-- Relevé de couture d'une pièce : ecarts = écarts (dm) de l'aiguille au pointillé, un tous les
+-- 0,1 dm de trajet ; duree = secondes passées à coudre ; assistance = vrai si elle a servi.
+-- Rien ne prouve qu'un relevé est honnête (limite assumée, spec §6) : on vérifie qu'il est vraisemblable.
+function EtatAtelier:rendreCouture(idPiece, ecarts, duree, assistance)
+	if self.etape ~= "couture" then
+		return refus("Ce n'est pas le moment de coudre.")
+	end
+	if type(idPiece) ~= "string" or not table.find(self:piecesDuCroquis(), idPiece) then
+		return refus("Cette pièce n'est pas dans le croquis.")
+	end
+	if self.coutures[idPiece] ~= nil then
+		return refus("Cette pièce est déjà cousue.")
+	end
+	if type(ecarts) ~= "table" or (assistance ~= nil and type(assistance) ~= "boolean") then
+		return refus("Relevé de couture invalide.")
+	end
+	local _, longueur = Patron.trajetCouture(idPiece)
+	local n = #ecarts
+	if math.abs(n - math.round(longueur / Catalogue.PAS_MESURE_COUTURE)) > EtatAtelier.TOLERANCE_MESURES then
+		return refus("Relevé de couture incomplet.")
+	end
+	for i = 1, n do
+		if not fini(ecarts[i]) or math.abs(ecarts[i]) > Catalogue.ECART_MAX_COUTURE then
+			return refus("Relevé de couture invalide.")
+		end
+	end
+	if not fini(duree) or duree < EtatAtelier.DUREE_MIN * longueur / Catalogue.VITESSE_COUTURE_MAX then
+		return refus("Couture trop rapide.")
+	end
+	local note = Notation.noteCouture(ecarts, assistance == true)
+	self.coutures[idPiece] = note
+	local reste = #self:piecesACoudre()
+	if reste == 0 then
+		self.etape = "decorations"
+	end
+	return { ok = true, note = note, reste = reste }
+end
+
+-- Recette de la robe en cours (position des pièces sur le rouleau, notes de couture ; les accessoires
+-- arrivent au plan 3c), ou nil tant que toutes les pièces ne sont pas coupées
+function EtatAtelier:recette()
+	if not self.commande or not self.croquis or #self:piecesAPoser() > 0 then
+		return nil
+	end
+	local pieces = {}
+	for _, id in ipairs(self:piecesDuCroquis()) do
+		local p = self.coupees[id]
+		table.insert(pieces, { id = id, tissu = self.tissus[id], x = p.x, y = p.y, angle = p.angle, couture = self.coutures[id] or 0 })
+	end
+	return {
+		version = Recette.VERSION,
+		mesures = table.clone(self.commande.mesures),
+		croquis = table.clone(self.croquis),
+		pieces = pieces,
+		accessoires = {},
+	}
+end
+
 -- Abandonne la robe en cours (le tissu déjà coupé est perdu), garde la commande
 function EtatAtelier:recommencer()
 	if self.etape == "accueil" then
@@ -191,6 +297,7 @@ function EtatAtelier:recommencer()
 	end
 	consommer(self)
 	self.croquis, self.tissus, self.coupees = nil, {}, {}
+	self.epinglees, self.coutures = {}, {}
 	self.argent = math.max(self.argent, EtatAtelier.FILET) -- jamais bloqué sans argent ni tissu
 	self.etape = "carnet"
 	return { ok = true }
```

- [ ] **Step 5: Étendre `Session`**

```diff
diff --git a/src/client/Atelier/Session.luau b/src/client/Atelier/Session.luau
index f82fed5..38809c2 100644
--- a/src/client/Atelier/Session.luau
+++ b/src/client/Atelier/Session.luau
@@ -53,6 +53,12 @@ end
 function Session:couper(idPiece, placement)
 	return agir(self, "couper", idPiece, placement)
 end
+function Session:epingler(idPiece)
+	return agir(self, "epingler", idPiece)
+end
+function Session:rendreCouture(idPiece, ecarts, duree, assistance)
+	return agir(self, "rendreCouture", idPiece, ecarts, duree, assistance)
+end
 function Session:recommencer()
 	return agir(self, "recommencer")
 end
```

- [ ] **Step 6: Lancer les tests**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT"`
Expected:
```
Unitaires : 104437 vérifications
TOUT EST VERT : 137 vérifications
```

- [ ] **Step 7: Commit**

```bash
git add src/shared/Catalogue.luau src/shared/EtatAtelier.luau src/client/Atelier/Session.luau tests/unitaires/18_epinglage_couture.luau
git commit -m "EtatAtelier : épinglage, relevé de couture contrôlé et recette de la robe

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 2: Logique de la machine à coudre (`MachineCoudre`)

**Files:**
- Create: `src/client/Atelier/MachineCoudre.luau`
- Test: `tests/unitaires/19_machine_coudre.luau`

**Interfaces:**
- Consumes: `Patron.trajetCouture`, `Polygone.longueur`, `Notation.noteCouture`, `Catalogue.PAS_MESURE_COUTURE`, `Catalogue.VITESSE_COUTURE_MAX`, `Catalogue.ECART_MAX_COUTURE` ; `EtatAtelier:rendreCouture` (tâche 1) dans le test.
- Produces :
  - constantes : `MachineCoudre.VITESSES = { tortue = 0.5, normale = 1, lapin = 1.5 }`, `PENTE_MAX = 0.8`, `AMPLITUDE_DERIVE = 0.3`, `DT_MAX = 0.1` ;
  - `MachineCoudre.nouvelle(idPiece, graine?) -> machine`, avec les champs `idPiece`, `segments`, `longueur`, `vitesse`, `assistance`, `assistanceUtilisee`, `parcouru`, `ecarts`, `duree` ;
  - méthodes : `machine:derive(t) -> pente`, `machine:fini()`, `machine:choisirVitesse(nom) -> bool`, `machine:activerAssistance(bool)`, `machine:avancer(dt, direction)` (direction de −1 à 1), `machine:decoudre() -> bool` ;
  - `machine:etat() -> { segment, nbSegments, avance, longueurSegment, ecart, ideal = {x, y}, point = {x, y}, direction = {x, y}, progression }` ;
  - `machine:releve() -> (ecarts, duree, assistanceUtilisee)`, dans l'ordre des paramètres de `rendreCouture` ;
  - `machine:noteProvisoire() -> number?`.

- [ ] **Step 1: Écrire les tests**

`tests/unitaires/19_machine_coudre.luau` :

```lua
local MachineCoudre = U.module("MachineCoudre")
local EtatAtelier = U.module("EtatAtelier")
local Catalogue = U.module("Catalogue")
local Patron = U.module("Patron")
local Polygone = U.module("Polygone")

local ID = "corsage_droit_devant"
local segments, longueur = Patron.trajetCouture(ID)
local PAS = Catalogue.PAS_MESURE_COUTURE

-- Coud toute la pièce à 60 images par seconde ; pilote(machine) donne la direction du joueur
local function coudre(machine, pilote)
	local images = 0
	while not machine:fini() and images < 100000 do
		machine:avancer(1 / 60, pilote and pilote(machine) or 0)
		images += 1
	end
	return images
end

---------------------------------------------------------------------------
-- Départ
---------------------------------------------------------------------------
local m = MachineCoudre.nouvelle(ID, 1)
local e0 = m:etat()
U.verifier(e0.segment == 1 and e0.nbSegments == #segments and e0.avance == 0 and e0.ecart == 0, "départ : début de la première couture")
U.verifier(U.proche(e0.point.x, segments[1].a.x) and U.proche(e0.point.y, segments[1].a.y), "l'aiguille part du début du pointillé")
local l1 = Polygone.longueur(segments[1])
U.verifier(U.proche(e0.direction.x, (segments[1].b.x - segments[1].a.x) / l1) and U.proche(e0.direction.y, (segments[1].b.y - segments[1].a.y) / l1), "direction de la couture")
U.verifier(m.vitesse == "normale" and m:noteProvisoire() == nil and not m:fini(), "vitesse normale, rien de cousu")

---------------------------------------------------------------------------
-- Mesures : une tous les 0,1 dm
---------------------------------------------------------------------------
m:avancer(0.35, 0) -- DT_MAX coupe une image trop longue
U.verifier(#m.ecarts == 1 and U.proche(m:etat().avance, MachineCoudre.DT_MAX * MachineCoudre.VITESSES.normale), "une image trop longue est ramenée à DT_MAX")
for _ = 1, 2 do
	m:avancer(0.1, 0)
end
U.verifier(#m.ecarts == 3 and U.proche(m:etat().avance, 0.3), "0,3 dm cousus : 3 mesures")
U.verifier(U.proche(m.duree, 0.3), "durée : temps passé à coudre")
m:avancer(0, 1)
m:avancer(-1, 1)
m:avancer(0 / 0, 1)
U.verifier(#m.ecarts == 3 and U.proche(m.duree, 0.3), "durée nulle, négative ou invalide : rien ne bouge")
m:avancer(0.05, 0 / 0)
m:avancer(0.05, "gauche")
U.verifier(#m.ecarts == 4, "direction invalide : comptée comme nulle")

---------------------------------------------------------------------------
-- Vitesse
---------------------------------------------------------------------------
U.verifier(not m:choisirVitesse("fusee") and m.vitesse == "normale", "vitesse inconnue refusée")
U.verifier(m:choisirVitesse("lapin") and m.vitesse == "lapin", "vitesse lapin")
local avant = m:etat().avance
m:avancer(0.1, 0)
U.verifier(U.proche(m:etat().avance - avant, 0.1 * Catalogue.VITESSE_COUTURE_MAX), "le lapin coud à la vitesse maximale")

---------------------------------------------------------------------------
-- Coutures enchaînées et découd-vite
---------------------------------------------------------------------------
local c = MachineCoudre.nouvelle(ID, 2)
while c:etat().segment == 1 do
	c:avancer(1 / 60, 0.2)
end
local fin1 = #c.ecarts
U.verifier(fin1 == math.floor(l1 / PAS + 1e-9), "première couture : une mesure par 0,1 dm")
local e2 = c:etat()
U.verifier(e2.segment == 2 and e2.avance == 0 and e2.ecart == 0, "couture suivante : l'aiguille est remise sur le pointillé")
U.verifier(U.proche(e2.point.x, segments[2].a.x) and U.proche(e2.point.y, segments[2].a.y), "l'aiguille part du début de la couture suivante")
c:avancer(0.1, 0)
c:avancer(0.1, 0)
U.verifier(#c.ecarts > fin1, "la deuxième couture a commencé")
U.verifier(c:decoudre() and c:etat().segment == 2 and c:etat().avance == 0 and #c.ecarts == fin1, "découdre : la couture en cours est défaite")
U.verifier(c:decoudre() and c:etat().segment == 1 and #c.ecarts == 0 and c.parcouru == 0, "découdre au début d'une couture : la précédente est défaite")
U.verifier(not c:decoudre(), "rien à découdre au départ")
coudre(c)
U.verifier(c:fini() and c:decoudre() and not c:fini() and c:etat().segment == #segments, "découdre une pièce finie : la dernière couture est à refaire")
coudre(c)
U.verifier(c:fini(), "pièce refinie")

---------------------------------------------------------------------------
-- Dérive, pilotage, assistance
---------------------------------------------------------------------------
local function pire(machine)
	local p = 0
	for _, e in ipairs(machine.ecarts) do
		p = math.max(p, math.abs(e))
	end
	return p
end
local nombre = math.floor(longueur / PAS + 1e-9)

local libre = MachineCoudre.nouvelle(ID, 3)
coudre(libre)
U.verifier(#libre.ecarts == nombre, "pièce entière : une mesure par 0,1 dm de trajet")
U.verifier(pire(libre) > 0.1 and libre:noteProvisoire() < 0.9, "sans corriger, le tissu tire et la couture s'écarte")

local pilote = MachineCoudre.nouvelle(ID, 3)
coudre(pilote, function(machine)
	return -machine:derive(machine.parcouru) / MachineCoudre.PENTE_MAX
end)
U.verifier(pire(pilote) < 0.05 and pilote:noteProvisoire() > 0.99, "en corrigeant la dérive, la couture suit le pointillé")

local rate = MachineCoudre.nouvelle(ID, 3)
coudre(rate, function()
	return 1
end)
U.verifier(U.proche(pire(rate), Catalogue.ECART_MAX_COUTURE) and rate:noteProvisoire() < 0.05, "écart borné à 2 dm même en tirant toujours du même côté")

local aide = MachineCoudre.nouvelle(ID, 3)
aide:activerAssistance(true)
coudre(aide, function()
	return 1 -- l'assistance ignore le joueur
end)
U.verifier(pire(aide) < 1e-9 and aide:noteProvisoire() == Catalogue.PLAFOND_ASSISTANCE, "assistance : couture parfaite, note plafonnée")
local _, _, assiste = aide:releve()
U.verifier(assiste == true, "le relevé dit que l'assistance a servi")

local reprise = MachineCoudre.nouvelle(ID, 4)
reprise:avancer(0.1, 1)
reprise:avancer(0.1, 1)
reprise:activerAssistance(true)
for _ = 1, 30 do
	reprise:avancer(1 / 60, 0)
end
U.verifier(math.abs(reprise:etat().ecart) < 1e-9, "l'assistance ramène l'aiguille sur le pointillé")
reprise:activerAssistance(false)
reprise:avancer(0.1, 0)
U.verifier(select(3, reprise:releve()) == true, "l'assistance reste comptée après l'avoir coupée")
while reprise:decoudre() do
end
U.verifier(select(3, reprise:releve()) == false, "tout décousu sans assistance : elle ne compte plus")

---------------------------------------------------------------------------
-- Reproductible, et accepté par EtatAtelier aux trois vitesses
---------------------------------------------------------------------------
local a, b, autre = MachineCoudre.nouvelle(ID, 7), MachineCoudre.nouvelle(ID, 7), MachineCoudre.nouvelle(ID, 8)
coudre(a)
coudre(b)
coudre(autre)
U.verifier(a.ecarts[20] == b.ecarts[20] and a.ecarts[20] ~= autre.ecarts[20], "même graine, même dérive ; autre graine, autre dérive")

local CROQUIS = { corsage = "corsage_droit", manches = "manches_sans", col = "col_sans", jupe = "jupe_droite" }
local DISPOSITION = {
	corsage_droit_devant = { x = 2.4, y = 2.1, angle = 0 },
	corsage_droit_dos = { x = 7.2, y = 2.1, angle = 0 },
	jupe_droite_devant = { x = 2.5, y = 7.2, angle = 0 },
	jupe_droite_dos = { x = 7.5, y = 7.2, angle = 0 },
}
local etat = EtatAtelier.nouveau()
etat:nouvelleCommande(Random.new(3))
local tissus = {}
for idPiece in pairs(DISPOSITION) do
	tissus[idPiece] = "coton_blanc"
end
etat:validerCroquis(CROQUIS, tissus)
etat:acheter("coton_blanc", 12)
etat:commencerDecoupe()
for _, idPiece in ipairs(etat:piecesDuCroquis()) do
	etat:couper(idPiece, DISPOSITION[idPiece])
end
for _, idPiece in ipairs(etat:piecesDuCroquis()) do
	etat:epingler(idPiece)
end
for k, vitesse in ipairs({ "tortue", "normale", "lapin" }) do
	local idPiece = etat:piecesDuCroquis()[k]
	local machine = MachineCoudre.nouvelle(idPiece, k)
	machine:choisirVitesse(vitesse)
	coudre(machine)
	local r = etat:rendreCouture(idPiece, machine:releve())
	U.verifier(r.ok and U.proche(r.note, machine:noteProvisoire()), "relevé accepté par EtatAtelier à la vitesse " .. vitesse .. " : " .. tostring(r.erreur))
end
```

- [ ] **Step 2: Vérifier qu'ils échouent**

Run: `bash tests/lancer.sh 2>&1 | grep -m1 "membre valide"`
Expected: `MachineCoudre n'est pas un membre valide de Folder « Couture »`

- [ ] **Step 3: Écrire le module**

`src/client/Atelier/MachineCoudre.luau` :

```lua
-- MachineCoudre : logique du mini-jeu de couture (sans affichage), testable seule.
-- L'aiguille suit les coutures de la pièce l'une après l'autre. Le tissu tire d'un côté ou de l'autre
-- (la dérive) ; le joueur corrige en glissant (direction de −1 à 1). On relève l'écart entre l'aiguille
-- et le pointillé tous les 0,1 dm de trajet : c'est ce relevé qui est noté (Notation.noteCouture).
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Couture = ReplicatedStorage:WaitForChild("Couture")
local Catalogue = require(Couture:WaitForChild("Catalogue"))
local Patron = require(Couture:WaitForChild("Patron"))
local Polygone = require(Couture:WaitForChild("Polygone"))
local Notation = require(Couture:WaitForChild("Notation"))

local MachineCoudre = {}
MachineCoudre.__index = MachineCoudre

MachineCoudre.VITESSES = { tortue = 0.5, normale = 1, lapin = Catalogue.VITESSE_COUTURE_MAX } -- dm/s
MachineCoudre.PENTE_MAX = 0.8 -- écart corrigé par dm cousu quand on glisse à fond (direction ±1)
MachineCoudre.AMPLITUDE_DERIVE = 0.3 -- écart pris par dm cousu quand le tissu tire le plus
MachineCoudre.DT_MAX = 0.1 -- s : une image très lente ne fait pas sauter l'aiguille
local PAS_CALCUL = 0.02 -- dm entre deux calculs de l'écart
local PAS = Catalogue.PAS_MESURE_COUTURE

-- graine : fixe la dérive (même graine, même tissu qui tire)
function MachineCoudre.nouvelle(idPiece, graine)
	local segments, longueur = Patron.trajetCouture(idPiece)
	local longueurs = {}
	for k, seg in ipairs(segments) do
		longueurs[k] = Polygone.longueur(seg)
	end
	local rng = Random.new(graine or 0)
	return setmetatable({
		idPiece = idPiece,
		segments = segments,
		longueurs = longueurs,
		longueur = longueur,
		phases = { rng:NextNumber(0, 2 * math.pi), rng:NextNumber(0, 2 * math.pi) },
		vitesse = "normale",
		assistance = false,
		assistanceUtilisee = false,
		k = 1, -- couture en cours
		s = 0, -- dm cousus sur la couture en cours
		e = 0, -- écart de l'aiguille au pointillé (dm), mesuré le long de la normale de la couture
		parcouru = 0, -- dm cousus en tout
		ecarts = {},
		duree = 0,
		debuts = { { parcouru = 0, mesures = 0 } }, -- où en était le relevé au début de chaque couture
	}, MachineCoudre)
end

-- Dérive du tissu (écart pris par dm cousu) après t dm de couture
function MachineCoudre:derive(t)
	local p = self.phases
	return MachineCoudre.AMPLITUDE_DERIVE * (0.6 * math.sin(1.7 * t + p[1]) + 0.4 * math.sin(0.61 * t + p[2]))
end

function MachineCoudre:fini()
	return self.k > #self.segments
end

function MachineCoudre:choisirVitesse(nom)
	if MachineCoudre.VITESSES[nom] then
		self.vitesse = nom
		return true
	end
	return false
end

function MachineCoudre:activerAssistance(actif)
	self.assistance = actif == true
end

-- Coud pendant dt secondes ; direction = correction du joueur (−1 à 1), ignorée avec l'assistance
function MachineCoudre:avancer(dt, direction)
	if self:fini() or type(dt) ~= "number" or not (dt > 0) then
		return
	end
	dt = math.min(dt, MachineCoudre.DT_MAX)
	if type(direction) ~= "number" or direction ~= direction then
		direction = 0
	end
	direction = math.clamp(direction, -1, 1)
	if self.assistance then
		self.assistanceUtilisee = true
	end
	self.duree += dt
	local reste = MachineCoudre.VITESSES[self.vitesse] * dt
	while reste > 1e-12 and not self:fini() do
		local lk = self.longueurs[self.k]
		local ds = math.min(PAS_CALCUL, reste, lk - self.s)
		local pente
		if self.assistance then
			pente = math.clamp(-self.e / math.max(ds, 1e-9), -MachineCoudre.PENTE_MAX, MachineCoudre.PENTE_MAX)
		else
			pente = self:derive(self.parcouru) + direction * MachineCoudre.PENTE_MAX
		end
		self.e = math.clamp(self.e + pente * ds, -Catalogue.ECART_MAX_COUTURE, Catalogue.ECART_MAX_COUTURE)
		self.s += ds
		self.parcouru += ds
		reste -= ds
		while self.parcouru >= (#self.ecarts + 1) * PAS - 1e-9 do
			table.insert(self.ecarts, self.e)
		end
		if self.s >= lk - 1e-9 then
			-- Couture suivante : l'aiguille est remise au début de son pointillé
			self.k += 1
			self.s, self.e = 0, 0
			self.debuts[self.k] = { parcouru = self.parcouru, mesures = #self.ecarts }
		end
	end
end

-- Découd-vite : défait la couture en cours, ou la précédente si on est au début de celle-ci
function MachineCoudre:decoudre()
	local k = self.k
	if k > #self.segments or self.s <= 1e-9 then
		k -= 1
	end
	if k < 1 then
		return false
	end
	local debut = self.debuts[k]
	self.k, self.s, self.e = k, 0, 0
	self.parcouru = debut.parcouru
	for i = #self.ecarts, debut.mesures + 1, -1 do
		self.ecarts[i] = nil
	end
	if self.parcouru == 0 and not self.assistance then
		self.assistanceUtilisee = false -- tout est décousu : l'essai avec l'assistance ne compte plus
	end
	return true
end

-- Position de l'aiguille pour l'affichage (repère du patron, dm)
function MachineCoudre:etat()
	local k = math.min(self.k, #self.segments)
	local seg, lk = self.segments[k], self.longueurs[k]
	local dx, dy = (seg.b.x - seg.a.x) / lk, (seg.b.y - seg.a.y) / lk
	local s = self:fini() and lk or self.s
	local ix, iy = seg.a.x + dx * s, seg.a.y + dy * s
	return {
		segment = k,
		nbSegments = #self.segments,
		avance = s,
		longueurSegment = lk,
		ecart = self.e,
		ideal = { x = ix, y = iy }, -- point du pointillé sous l'aiguille
		point = { x = ix - dy * self.e, y = iy + dx * self.e }, -- aiguille, décalée de l'écart
		direction = { x = dx, y = dy },
		progression = self.parcouru / self.longueur,
	}
end

-- Relevé à envoyer : écarts, durée passée à coudre, et si l'assistance a servi
function MachineCoudre:releve()
	return table.clone(self.ecarts), self.duree, self.assistanceUtilisee
end

-- Note de couture de ce qui est déjà cousu (nil si rien)
function MachineCoudre:noteProvisoire()
	if #self.ecarts == 0 then
		return nil
	end
	return Notation.noteCouture(self.ecarts, self.assistanceUtilisee)
end

return MachineCoudre
```

- [ ] **Step 4: Lancer les tests**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT"`
Expected:
```
Unitaires : 104471 vérifications
TOUT EST VERT : 137 vérifications
```

- [ ] **Step 5: Commit**

```bash
git add src/client/Atelier/MachineCoudre.luau tests/unitaires/19_machine_coudre.luau
git commit -m "Ajoute MachineCoudre : aiguille, dérive du tissu, vitesses, découd-vite et assistance

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 3: Pièce découpée transparente autour (`Pixels.decouper`)

**Files:**
- Modify: `src/shared/Pixels.luau`
- Test: `tests/unitaires/07_pixels.luau` (tests ajoutés à la fin)

**Interfaces:**
- Consumes: `Pixels.imagePiece`, `Pixels.taillePiece`, `Polygone.contient`, `Polygone.boite`.
- Produces : `Pixels.decouper(buf, largeur, hauteur, idPiece) -> buf`. Il agit sur place : alpha à 0 hors du contour, pixels inchangés dans le contour. Le repère est celui de `imagePiece`.

- [ ] **Step 1: Ajouter les tests**

```diff
diff --git a/tests/unitaires/07_pixels.luau b/tests/unitaires/07_pixels.luau
index 85cf218..42019ed 100644
--- a/tests/unitaires/07_pixels.luau
+++ b/tests/unitaires/07_pixels.luau
@@ -89,3 +89,33 @@ local silB, lb, hb = Pixels.silhouette("jupe_evasee_devant")
 local cxB, cyB = math.floor(lb / 2), math.floor(hb / 2)
 U.verifier(alpha(silB, lb, cxB + 20, cyB + 20) == 255, "pièce en biais : flèche en diagonale")
 U.verifier(alpha(silB, lb, cxB, cyB - 40) == 170, "pièce en biais : pas de flèche verticale")
+
+-- Pièce découpée pour l'interface : le vrai tissu dans le contour, transparent autour
+local Polygone = U.module("Polygone")
+local motifSoie = Pixels.motif("soie_rose_fleurs")
+local plein, lp, hp = Pixels.imagePiece(motifSoie, "manche_ballon", { x = 3, y = 2, angle = 30 }, "gauche", 64)
+local reference = buffer.create(buffer.len(plein))
+buffer.copy(reference, 0, plein)
+U.verifier(Pixels.decouper(plein, lp, hp, "manche_ballon") == plein, "découpe sur place")
+local _, _, bm = Pixels.taillePiece("manche_ballon", 64)
+local contourManche = Catalogue.piece("manche_ballon").contour
+local dedans, dehors, fautes = 0, 0, 0
+for j = 0, hp - 1 do
+	local y = bm.minY + (j + 0.5) / hp * (bm.maxY - bm.minY)
+	for i = 0, lp - 1 do
+		local x = bm.minX + (i + 0.5) / lp * (bm.maxX - bm.minX)
+		local k = (j * lp + i) * 4
+		if Polygone.contient(contourManche, x, y) then
+			dedans += 1
+			if buffer.readu32(plein, k) ~= buffer.readu32(reference, k) then
+				fautes += 1
+			end
+		else
+			dehors += 1
+			if buffer.readu8(plein, k + 3) ~= 0 then
+				fautes += 1
+			end
+		end
+	end
+end
+U.verifier(dedans > 0 and dehors > 0 and fautes == 0, "dans le contour : pixel du tissu ; autour : transparent (" .. fautes .. " fautes)")
```

- [ ] **Step 2: Vérifier qu'ils échouent**

Run: `bash tests/lancer.sh 2>&1 | grep -m1 -E "ÉCHEC|attempt"`
Expected: une erreur « attempt to call a nil value » (`Pixels.decouper` n'existe pas).

- [ ] **Step 3: Ajouter la fonction**

```diff
diff --git a/src/shared/Pixels.luau b/src/shared/Pixels.luau
index 7532e22..78bfaa5 100644
--- a/src/shared/Pixels.luau
+++ b/src/shared/Pixels.luau
@@ -141,6 +141,22 @@ function Pixels.imagePiece(motif, idPiece, placement, copie, plafond)
 	return buf, largeur, hauteur
 end
 
+-- Rend transparent tout ce qui est hors du contour de la pièce (sur place) : l'image de imagePiece
+-- devient la pièce découpée telle qu'on la voit dans l'interface. Retourne le même buffer.
+function Pixels.decouper(buf, largeur, hauteur, idPiece)
+	local contour = Catalogue.piece(idPiece).contour
+	local b = Polygone.boite(contour)
+	local l, h = b.maxX - b.minX, b.maxY - b.minY
+	for j = 0, hauteur - 1 do
+		local y = b.minY + (j + 0.5) / hauteur * h
+		for i = 0, largeur - 1 do
+			if not Polygone.contient(contour, b.minX + (i + 0.5) / largeur * l, y) then
+				buffer.writeu8(buf, (j * largeur + i) * 4 + 3, 0)
+			end
+		end
+	end
+	return buf
+end
 
 ---------------------------------------------------------------------------
 -- Silhouette d'un patron en papier (table de découpe) : papier translucide, contour foncé
```

- [ ] **Step 4: Lancer les tests**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT"`
Expected:
```
Unitaires : 104473 vérifications
TOUT EST VERT : 137 vérifications
```

- [ ] **Step 5: Commit**

```bash
git add src/shared/Pixels.luau tests/unitaires/07_pixels.luau
git commit -m "Pixels : pièce découpée, transparente hors du contour

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 4: Pièce seule, aperçu et scène 3D (`Scene`)

**Files:**
- Modify: `src/shared/ConstructeurRobe.luau`
- Modify: `src/client/Atelier/Vignettes.luau`
- Create: `src/client/Atelier/Scene.luau`
- Test: `tests/unitaires/20_scene.luau`

**Interfaces:**
- Consumes: `Mannequin.construire`, `Mannequin.formes`, `Mannequin.HAUTEUR_TAILLE`, `Patron.copies`, `Pixels.decouper` (tâche 3), `etat:recette()` et `etat.epinglees` (tâche 1).
- Produces :
  - `ConstructeurRobe.piece(p, copie, mesures, cadre, finesse) -> MeshPart?`, sans parent, avec `p = { id, tissu, x, y, angle }` ;
  - `Vignettes.piece(idPiece, idTissu, placement, plafond?) -> Content?` : en cache, et nouvel essai après `Vignettes.ESSAI_APRES` en cas d'échec ;
  - `Scene.CADRE`, `Scene.CAMERA`, `Scene.POSTES` ;
  - `Scene.nouvelle(parent?) -> scene`, avec les champs `dossier` (« AtelierLocal ») et `robe` (Model « Robe ») ;
  - `scene:synchroniser(etat)` : mannequin, pièces épinglées et caméra (peut attendre) ; `scene:ouvrir(ouverte, etat)` ; `scene:regarder(actif)` ; `scene:detruire()`.

- [ ] **Step 1: Écrire les tests**

`tests/unitaires/20_scene.luau` :

```lua
local Scene = U.module("Scene")
local Vignettes = U.module("Vignettes")
local ConstructeurRobe = U.module("ConstructeurRobe")
local EtatAtelier = U.module("EtatAtelier")
local Catalogue = U.module("Catalogue")
local Mannequin = U.module("Mannequin")

local Workspace = M.services.Workspace
local camera = Workspace.CurrentCamera
M.budget.images, M.budget.maillages = 64, 7

---------------------------------------------------------------------------
-- Une pièce seule (épinglage)
---------------------------------------------------------------------------
local manche = { id = "manche_ballon", tissu = "soie_rose_fleurs", x = 3, y = 2, angle = 0 }
local part = ConstructeurRobe.piece(manche, "droite", Catalogue.TAILLES.M, CFrame.new(0, 10, 0), "robe")
U.verifier(part ~= nil and part.Name == "Piece_manche_ballon_droite" and part.Parent == nil, "pièce seule, sans parent")
U.verifier(part.TextureContent ~= nil and part.TextureContent.statique and part.Anchored and not part.CanCollide, "pièce seule : texture statique, ancrée")
U.verifier(M.editables.maillages == 0 and M.editables.images == 0, "pièce seule : objets modifiables détruits")
part:Destroy()

---------------------------------------------------------------------------
-- Aperçu d'une pièce découpée
---------------------------------------------------------------------------
local place = { x = 3, y = 2, angle = 0 }
local apercu = Vignettes.piece("manche_ballon", "soie_rose_fleurs", place)
U.verifier(apercu ~= nil and apercu.statique, "aperçu de la pièce découpée en contenu statique")
U.verifier(Vignettes.piece("manche_ballon", "soie_rose_fleurs", { x = 3, y = 2, angle = 0 }) == apercu, "aperçu en cache")
U.verifier(Vignettes.piece("manche_ballon", "soie_rose_fleurs", { x = 3.5, y = 2, angle = 0 }) ~= apercu, "autre place sur le rouleau : autre aperçu")
M.budget.images = 0
U.verifier(Vignettes.piece("manche_ballon", "soie_rose_fleurs", { x = 4, y = 2, angle = 0 }) == nil, "mémoire des images pleine : pas d'aperçu, sans erreur")
M.budget.images = 64

---------------------------------------------------------------------------
-- Scène : mannequin de la cliente, pièces épinglées, caméra fixe
---------------------------------------------------------------------------
local CROQUIS = { corsage = "corsage_droit", manches = "manches_sans", col = "col_sans", jupe = "jupe_droite" }
local PIECES = { "corsage_droit_devant", "corsage_droit_dos", "jupe_droite_devant", "jupe_droite_dos" }
local DISPOSITION = {
	corsage_droit_devant = { x = 2.4, y = 2.1, angle = 0 },
	corsage_droit_dos = { x = 7.2, y = 2.1, angle = 0 },
	jupe_droite_devant = { x = 2.5, y = 7.2, angle = 0 },
	jupe_droite_dos = { x = 7.5, y = 7.2, angle = 0 },
}
local etat = EtatAtelier.nouveau()
local scene = Scene.nouvelle(Workspace)
U.verifier(scene.dossier.Name == "AtelierLocal" and scene.dossier.Parent == Workspace, "dossier de la scène dans le Workspace")
camera.CameraType = Enum.CameraType.Custom
scene:synchroniser(etat)
U.verifier(scene.dossier:FindFirstChild("Mannequin") == nil, "pas de mannequin sans commande")
U.verifier(camera.CameraType == Enum.CameraType.Custom, "à l'accueil, la caméra suit le joueur")

etat:nouvelleCommande(Random.new(3))
etat.commande.mesures = table.clone(Catalogue.TAILLES.S)
local tissus = {}
for _, id in ipairs(PIECES) do
	tissus[id] = "coton_blanc"
end
etat:validerCroquis(CROQUIS, tissus)
etat:acheter("coton_blanc", 12)
etat:commencerDecoupe()
for _, id in ipairs(PIECES) do
	etat:couper(id, DISPOSITION[id])
end
scene:synchroniser(etat)
local mannequin = scene.dossier:FindFirstChild("Mannequin")
U.verifier(mannequin ~= nil, "mannequin posé dès qu'il y a une commande")
local buste = Mannequin.formes(Catalogue.TAILLES.S)[1]
U.verifier(U.proche((mannequin.Buste.Size - buste.taille * Catalogue.STUDS_PAR_DM).Magnitude, 0), "mannequin aux mesures de la cliente")
U.verifier(U.proche((mannequin.Buste.CFrame.Position - (Scene.CADRE * CFrame.new(buste.centre * Catalogue.STUDS_PAR_DM)).Position).Magnitude, 0), "mannequin à sa place dans l'atelier")
U.verifier(#scene.robe:GetChildren() == 0, "rien d'épinglé")
U.verifier(camera.CameraType == Enum.CameraType.Scriptable and camera.CFrame == Scene.CAMERA, "épinglage : caméra fixe sur le mannequin")

etat:epingler("corsage_droit_devant")
scene:synchroniser(etat)
local corsage = scene.robe:FindFirstChild("Piece_corsage_droit_devant_unique")
U.verifier(corsage ~= nil and #scene.robe:GetChildren() == 1, "la pièce épinglée apparaît sur le mannequin")
U.verifier((corsage.CFrame.Position - Scene.CADRE.Position).Magnitude < 3, "pièce posée sur le mannequin")
scene:synchroniser(etat)
U.verifier(scene.robe:FindFirstChild("Piece_corsage_droit_devant_unique") == corsage, "une pièce déjà posée n'est pas reconstruite")
for i = 2, 4 do
	etat:epingler(PIECES[i])
end
scene:synchroniser(etat)
U.verifier(#scene.robe:GetChildren() == 4 and etat.etape == "couture", "robe entièrement épinglée")
U.verifier(camera.CameraType == Enum.CameraType.Scriptable, "couture : caméra toujours fixe")

-- Recommencer : la robe disparaît, le mannequin reste, la caméra revient au joueur
etat:recommencer()
scene:synchroniser(etat)
U.verifier(#scene.robe:GetChildren() == 0 and scene.dossier:FindFirstChild("Mannequin") == mannequin, "recommencer : robe retirée, même mannequin")
U.verifier(camera.CameraType == Enum.CameraType.Custom, "carnet : la caméra suit de nouveau le joueur")

-- Autre cliente : le mannequin change de taille
etat.commande.mesures = table.clone(Catalogue.TAILLES.L)
scene:synchroniser(etat)
local grand = scene.dossier:FindFirstChild("Mannequin")
U.verifier(grand ~= mannequin and mannequin.Parent == nil, "nouvelles mesures : nouveau mannequin")
U.verifier(U.proche((grand.Buste.Size - Mannequin.formes(Catalogue.TAILLES.L)[1].taille * Catalogue.STUDS_PAR_DM).Magnitude, 0), "mannequin taille L")

-- Mémoire des maillages pleine : la pièce n'apparaît pas, sans erreur
local etat2 = EtatAtelier.nouveau()
etat2:nouvelleCommande(Random.new(3))
etat2:validerCroquis(CROQUIS, tissus)
etat2:acheter("coton_blanc", 12)
etat2:commencerDecoupe()
for _, id in ipairs(PIECES) do
	etat2:couper(id, DISPOSITION[id])
end
etat2:epingler(PIECES[1])
local scene2 = Scene.nouvelle(Workspace)
M.budget.maillages = 0
scene2:synchroniser(etat2)
M.budget.maillages = 7
U.verifier(#scene2.robe:GetChildren() == 0 and scene2.dossier:FindFirstChild("Mannequin") ~= nil, "mémoire pleine : pièce absente, scène intacte")

scene2:detruire()
scene:detruire()
U.verifier(scene.dossier.Parent == nil and camera.CameraType == Enum.CameraType.Custom, "scène détruite, caméra rendue")
```

- [ ] **Step 2: Vérifier qu'ils échouent**

Run: `bash tests/lancer.sh 2>&1 | grep -m1 "membre valide"`
Expected: `Scene n'est pas un membre valide de Folder « Couture »`

- [ ] **Step 3: Exporter la construction d'une pièce seule**

```diff
diff --git a/src/shared/ConstructeurRobe.luau b/src/shared/ConstructeurRobe.luau
index f74acf7..d961deb 100644
--- a/src/shared/ConstructeurRobe.luau
+++ b/src/shared/ConstructeurRobe.luau
@@ -87,6 +87,10 @@ local function construirePiece(p, copie, mesures, cadre, finesse)
 	return part
 end
 
+-- Une pièce seule (épinglage) : p = { id, tissu, x, y, angle }, copie = "unique" | "gauche" | "droite".
+-- Retourne la MeshPart sans parent, ou nil si la mémoire des maillages est pleine.
+ConstructeurRobe.piece = construirePiece
+
 ---------------------------------------------------------------------------
 -- Accessoires
 ---------------------------------------------------------------------------
```

- [ ] **Step 4: Aperçu d'une pièce découpée**

```diff
diff --git a/src/client/Atelier/Vignettes.luau b/src/client/Atelier/Vignettes.luau
index cbe1d65..81bee32 100644
--- a/src/client/Atelier/Vignettes.luau
+++ b/src/client/Atelier/Vignettes.luau
@@ -6,6 +6,7 @@ local Couture = ReplicatedStorage:WaitForChild("Couture")
 local Catalogue = require(Couture:WaitForChild("Catalogue"))
 local Pixels = require(Couture:WaitForChild("Pixels"))
 local Editables = require(Couture:WaitForChild("Editables"))
+local Patron = require(Couture:WaitForChild("Patron"))
 
 local Vignettes = {}
 Vignettes.ESSAI_APRES = 5 -- secondes avant de réessayer une image qui n'a pas pu être créée
@@ -48,4 +49,16 @@ function Vignettes.silhouette(idPiece)
 	end)
 end
 
+-- Pièce découpée : le vrai tissu tel qu'il était sous la pièce sur la table, transparent autour.
+-- placement = { x, y, angle } sur le rouleau ; plafond = côté maximal de l'image (128 px par défaut).
+function Vignettes.piece(idPiece, idTissu, placement, plafond)
+	plafond = plafond or 128
+	local cle = ("piece:%s:%s:%s:%s:%s:%d"):format(idPiece, idTissu, placement.x, placement.y, placement.angle, plafond)
+	return figer(cle, function()
+		local copie = Patron.copies(idPiece)[1]
+		local buf, l, h = Pixels.imagePiece(Pixels.motif(idTissu), idPiece, placement, copie, plafond)
+		return Pixels.decouper(buf, l, h, idPiece), l, h
+	end)
+end
+
 return Vignettes
```

- [ ] **Step 5: Écrire `Scene`**

`src/client/Atelier/Scene.luau` :

```lua
-- Scene : le coin de l'atelier en 3D, côté client. Le mannequin aux mesures de la cliente, les pièces
-- épinglées dessus (le vrai tissu découpé), et la caméra fixe des postes autour du mannequin.
-- Au plan 4, la boutique construite par le serveur donnera l'emplacement du mannequin.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Couture = ReplicatedStorage:WaitForChild("Couture")
local Catalogue = require(Couture:WaitForChild("Catalogue"))
local Patron = require(Couture:WaitForChild("Patron"))
local Mannequin = require(Couture:WaitForChild("Mannequin"))
local ConstructeurRobe = require(Couture:WaitForChild("ConstructeurRobe"))

local Scene = {}
Scene.__index = Scene

-- Taille du mannequin dans le monde (studs) ; le devant du corps regarde vers −Z
Scene.CADRE = CFrame.new(0, Mannequin.HAUTEUR_TAILLE * Catalogue.STUDS_PAR_DM, 40)
-- Caméra face au mannequin, décalée pour le laisser à gauche de l'écran (le panneau est à droite)
Scene.CAMERA = CFrame.lookAt(Vector3.new(-1.1, 2.6, 34.6), Vector3.new(-1.1, 2.2, 40))
-- Étapes où la caméra montre le mannequin
Scene.POSTES = { epinglage = true, couture = true, decorations = true }

function Scene.nouvelle(parent)
	local dossier = Instance.new("Folder")
	dossier.Name = "AtelierLocal"
	local robe = Instance.new("Model")
	robe.Name = "Robe"
	robe.Parent = dossier
	dossier.Parent = parent or Workspace
	return setmetatable({ dossier = dossier, robe = robe, mesures = nil, mannequin = nil, pieces = {}, cameraFixe = false, ouverte = true }, Scene)
end

local function memesMesures(a, b)
	return a and b and a.poitrine == b.poitrine and a.taille == b.taille and a.hanches == b.hanches
end

-- Met la scène d'accord avec l'état de l'atelier. Peut attendre (création des maillages) :
-- l'appeler dans une tâche à part pour ne pas bloquer l'interface.
function Scene:synchroniser(etat)
	-- Mannequin aux mesures de la cliente
	local mesures = etat.commande and etat.commande.mesures
	if not memesMesures(mesures, self.mesures) then
		if self.mannequin then
			self.mannequin:Destroy()
			self.mannequin = nil
		end
		self.mesures = mesures and table.clone(mesures)
		if mesures then
			self.mannequin = Mannequin.construire(mesures, Scene.CADRE, self.dossier)
		end
	end
	-- Pièces épinglées
	local recette = etat:recette()
	local voulues = {}
	if recette then
		for _, p in ipairs(recette.pieces) do
			if etat.epinglees[p.id] then
				voulues[p.id] = p
			end
		end
	end
	for id, entree in pairs(self.pieces) do
		if not voulues[id] or entree.mesures ~= self.mesures then
			for _, part in ipairs(entree.parts) do
				part:Destroy()
			end
			self.pieces[id] = nil
		end
	end
	self:regarder(self.ouverte and Scene.POSTES[etat.etape] == true)
	if not recette then
		return
	end
	for _, p in ipairs(recette.pieces) do
		if voulues[p.id] and not self.pieces[p.id] then
			local entree = { parts = {}, mesures = self.mesures }
			self.pieces[p.id] = entree
			for _, copie in ipairs(Patron.copies(p.id)) do
				local part = ConstructeurRobe.piece(p, copie, recette.mesures, Scene.CADRE, "robe")
				if part and self.pieces[p.id] == entree and self.dossier.Parent then
					part.Parent = self.robe
					table.insert(entree.parts, part)
				elseif part then
					part:Destroy() -- la pièce a été retirée pendant sa construction
				end
			end
		end
	end
end

-- Fenêtre de l'atelier fermée : la caméra revient au joueur ; rouverte : elle repart au poste
function Scene:ouvrir(ouverte, etat)
	self.ouverte = ouverte
	self:regarder(ouverte and Scene.POSTES[etat.etape] == true)
end

-- Caméra fixe sur le mannequin (actif), ou rendue au joueur
function Scene:regarder(actif)
	local camera = Workspace.CurrentCamera
	if not camera then
		return
	end
	if actif then
		camera.CameraType = Enum.CameraType.Scriptable
		camera.CFrame = Scene.CAMERA
		self.cameraFixe = true
	elseif self.cameraFixe then
		camera.CameraType = Enum.CameraType.Custom
		self.cameraFixe = false
	end
end

function Scene:detruire()
	self:regarder(false)
	self.pieces = {}
	self.dossier:Destroy()
end

return Scene
```

- [ ] **Step 6: Lancer les tests**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT"`
Expected:
```
Unitaires : 104499 vérifications
TOUT EST VERT : 137 vérifications
```

- [ ] **Step 7: Commit**

```bash
git add src/shared/ConstructeurRobe.luau src/client/Atelier/Vignettes.luau src/client/Atelier/Scene.luau tests/unitaires/20_scene.luau
git commit -m "Scène 3D de l'atelier : mannequin de la cliente, pièces épinglées, caméra du poste

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 5: Écrans d'épinglage et de couture, scénario complet

**Files:**
- Modify: `tests/scenario.luau`
- Modify: `src/client/Atelier/UiKit.luau`
- Create: `src/client/Atelier/EcranEpinglage.luau`
- Create: `src/client/Atelier/EcranCouture.luau`
- Modify: `src/client/Atelier/EcranSuite.luau` (réécriture complète)
- Modify: `src/client/Atelier/EcranDecoupe.luau`
- Modify: `src/client/Atelier/init.client.luau`

**Interfaces:**
- Consumes: tâches 1 à 4 (`Session:epingler`, `Session:rendreCouture`, `MachineCoudre`, `Vignettes.piece`, `Scene`) ; `Notation.bilan`.
- Produces :
  - `UiKit.LARGEUR_PANNEAU = 380`, `UiKit.DELAI_CONFIRMATION = 3`, `UiKit.TEXTE_CONFIRMATION = "Vraiment ? Touche encore"` ;
  - `UiKit.boutonConfirme(props, auClic)` : le premier appui demande confirmation ; un second, au moins 0,4 s plus tard et dans les 3 s, agit ;
  - titres : `4. Épinglage`, `5. Couture`, `La robe est cousue !`. La fenêtre passe en panneau à droite (ancrage X à 1) pour l'épinglage et la robe cousue ;
  - noms stables pour le scénario et Studio :
    - épinglage : `Contenu.Liste.Epingler_<idPiece>` (`Apercu`, `Etat`), `Contenu.Recommencer` ;
    - couture : `Contenu.Plateau` (`Tissu` avec `Piece`, `Pointille` et `Points`, puis `Barre` et `Aiguille`) ;
    - couture, suite : `Contenu.Panneau` (`Pieces.Ligne<i>`, `Note`, `Vitesse_tortue`, `Vitesse_normale`, `Vitesse_lapin`, `Assistance`, `Decoudre`, `Coudre`, `Recommencer`) ;
    - robe cousue : `Contenu.Qualite`, `Contenu.Recommencer` ;
    - scène : `Workspace.AtelierLocal` (`Mannequin`, `Robe`).

- [ ] **Step 1: Compléter le scénario**

```diff
diff --git a/tests/scenario.luau b/tests/scenario.luau
index 568e34d..213dc81 100644
--- a/tests/scenario.luau
+++ b/tests/scenario.luau
@@ -243,12 +243,117 @@ end
 verifier(coupes == 6, "6 pièces coupées (manche et col pliés comptent pour une coupe chacun) : " .. coupes)
 
 ---------------------------------------------------------------------------
--- Suite et recommencer
+-- Épinglage
 ---------------------------------------------------------------------------
-verifier(titre() == "Toutes les pièces sont coupées !", "écran de suite après la dernière coupe")
-verifierTailles("suite")
+local Workspace = M.services.Workspace
+local camera = Workspace.CurrentCamera
+verifier(titre() == "4. Épinglage", "après la dernière coupe : l'épinglage")
+verifier(fenetre.AnchorPoint.X == 1, "la fenêtre se range à droite : le mannequin est visible")
+local scene = Workspace:FindFirstChild("AtelierLocal")
+verifier(scene ~= nil and scene:FindFirstChild("Mannequin") ~= nil, "le mannequin de la cliente est dans l'atelier")
+verifier(camera.CameraType == Enum.CameraType.Scriptable, "caméra fixe sur le mannequin")
+verifierTailles("épinglage")
+cliquer("Fermer")
+verifier(camera.CameraType == Enum.CameraType.Custom, "fenêtre fermée : la caméra revient au joueur")
+cliquer("OuvrirAtelier")
+verifier(camera.CameraType == Enum.CameraType.Scriptable, "fenêtre rouverte : caméra fixe sur le mannequin")
+local robe = scene.Robe
+local liste = fenetre.Contenu.Liste
+local aEpingler = {}
+for _, d in ipairs(liste:GetChildren()) do
+	if d.Name:sub(1, 9) == "Epingler_" then
+		table.insert(aEpingler, d.Name)
+	end
+end
+table.sort(aEpingler)
+verifier(#aEpingler == 6, "6 pièces à épingler (obtenu " .. #aEpingler .. ")")
+-- Les six cartes tiennent dans la liste sans défiler (une carte coupée par le bas cacherait « Recommencer »)
+local hauteurListe = fenetre.Size.Y.Offset + fenetre.Contenu.Size.Y.Offset + liste.Size.Y.Offset
+for _, nom in ipairs(aEpingler) do
+	local carte = liste[nom]
+	verifier(carte.Position.Y.Offset + carte.Size.Y.Offset <= hauteurListe, nom .. " : carte entièrement visible")
+end
+-- « Recommencer la robe » demande une confirmation : un seul appui n'efface rien
+cliquer("Recommencer")
+verifier(titre() == "4. Épinglage" and boutonNomme("Recommencer").Text == "Vraiment ? Touche encore", "recommencer : confirmation demandée")
+M.avancer(4)
+verifier(boutonNomme("Recommencer").Text == "Recommencer la robe", "sans confirmation, le bouton revient à la normale")
+verifier(liste[aEpingler[1]].Apercu.ImageContent.statique == true, "aperçu de la pièce découpée dans le vrai tissu")
+cliquer(aEpingler[1])
+verifier(#robe:GetChildren() >= 1, "la pièce épinglée apparaît sur le mannequin")
+verifier(liste[aEpingler[1]].Etat.Text == "Épinglée", "la pièce est marquée épinglée")
+for i = 2, #aEpingler do
+	cliquer(aEpingler[i])
+end
+verifier(#robe:GetChildren() == 8, "robe entière sur le mannequin, manches et col en double (obtenu " .. #robe:GetChildren() .. ")")
+
+---------------------------------------------------------------------------
+-- Couture
+---------------------------------------------------------------------------
+verifier(titre() == "5. Couture", "tout est épinglé : la couture")
+verifier(fenetre.AnchorPoint.X == 0.5, "la fenêtre revient au centre pour la machine à coudre")
+verifierTailles("couture")
+-- Maintient « Coudre » pendant « duree » secondes, en glissant de « glisse » pixels
+local function coudre(duree, glisse)
+	local appui = { UserInputType = Enum.UserInputType.MouseButton1, Position = Vector3.new(700, 400, 0) }
+	boutonNomme("Coudre").InputBegan:Fire(appui)
+	if glisse then
+		UIS.InputChanged:Fire({ UserInputType = Enum.UserInputType.MouseMovement, Position = Vector3.new(700 + glisse, 400, 0) })
+	end
+	M.avancer(duree)
+	UIS.InputEnded:Fire(appui)
+end
+local panneauC = fenetre.Contenu.Panneau
+local points = fenetre.Contenu.Plateau.Tissu.Points
+local function cousues()
+	local n = 0
+	for _, d in ipairs(panneauC.Pieces:GetChildren()) do
+		if d:IsA("TextLabel") and d.Text:find("%d+ %%$") then
+			n += 1
+		end
+	end
+	return n
+end
+verifier(panneauC.Note.Text == "Couture : —", "rien de cousu au départ")
+verifier(#panneauC.Pieces:GetChildren() == 6, "6 pièces à coudre")
+coudre(2)
+verifier(panneauC.Note.Text:match("^Couture : %d+ %%$") ~= nil, "la note s'affiche en cousant : " .. panneauC.Note.Text)
+verifier(#points:GetChildren() > 0, "les points de couture apparaissent sur le tissu")
+cliquer("Decoudre")
+verifier(panneauC.Note.Text == "Couture : —" and #points:GetChildren() == 0, "découdre défait la couture")
+coudre(60, 400) -- en tirant tout le temps du même côté : couture ratée
+verifier(cousues() == 1, "première pièce cousue")
+local ratee = tonumber(panneauC.Pieces.Ligne1.Text:match("(%d+) %%$"))
+cliquer("Vitesse_lapin")
+verifier(boutonNomme("Vitesse_lapin").BackgroundColor3 == Color3.fromRGB(214, 76, 128), "vitesse lapin choisie")
+-- Deuxième pièce au doigt : un second doigt qui glisse ne dirige pas l'aiguille
+local doigtCoudre = { UserInputType = Enum.UserInputType.Touch, Position = Vector3.new(700, 400, 0) }
+boutonNomme("Coudre").InputBegan:Fire(doigtCoudre)
+UIS.InputChanged:Fire({ UserInputType = Enum.UserInputType.Touch, Position = Vector3.new(1100, 400, 0) })
+M.avancer(30)
+UIS.InputEnded:Fire(doigtCoudre)
+verifier(cousues() == 2, "deuxième pièce cousue au doigt")
+local auDoigt = tonumber(panneauC.Pieces.Ligne2.Text:match("(%d+) %%$"))
+verifier(auDoigt ~= nil and auDoigt > 30, "un second doigt ne dirige pas l'aiguille : " .. tostring(auDoigt))
+cliquer("Assistance")
+verifier(panneauC.Assistance.Text == "Assistance : oui (85 % au plus)", "assistance activée")
+for _ = 3, 6 do
+	coudre(30)
+end
+
+---------------------------------------------------------------------------
+-- Robe cousue, recommencer
+---------------------------------------------------------------------------
+verifier(titre() == "La robe est cousue !", "écran de suite après la dernière couture")
+verifier(fenetre.AnchorPoint.X == 1 and #robe:GetChildren() == 8, "la robe cousue est visible sur le mannequin")
+verifier(texte("Qualité de la robe :") ~= nil, "la qualité de la robe est affichée")
+verifierTailles("robe cousue")
+verifier(ratee ~= nil and ratee < 20, "la couture ratée est mal notée : " .. tostring(ratee))
+cliquer("Recommencer")
+verifier(titre() == "La robe est cousue !", "un appui sur « Recommencer » ne suffit pas")
 cliquer("Recommencer")
 verifier(titre() == "1. Carnet de croquis", "recommencer ramène au carnet avec la même commande")
+verifier(#robe:GetChildren() == 0 and camera.CameraType == Enum.CameraType.Custom, "robe retirée du mannequin, caméra rendue au joueur")
 
 ---------------------------------------------------------------------------
 -- Robe en six tissus : la mise en page tient (lignes d'achat, onglets de la découpe)
```

- [ ] **Step 2: Vérifier qu'il échoue**

Run: `bash tests/lancer.sh 2>&1 | grep -m1 -E "ÉCHEC|attempt"`
Expected: `ÉCHEC : après la dernière coupe : l'épinglage`

- [ ] **Step 3: Panneau et bouton à confirmer dans `UiKit`**

```diff
diff --git a/src/client/Atelier/UiKit.luau b/src/client/Atelier/UiKit.luau
index d9d74d1..22416df 100644
--- a/src/client/Atelier/UiKit.luau
+++ b/src/client/Atelier/UiKit.luau
@@ -13,6 +13,7 @@ UiKit.COULEURS = {
 	erreur = Color3.fromRGB(210, 60, 60),
 }
 UiKit.LARGEUR, UiKit.HAUTEUR = 900, 560 -- taille de référence de la fenêtre (mise à l'échelle sur petit écran)
+UiKit.LARGEUR_PANNEAU = 380 -- fenêtre rangée à droite pendant les postes autour du mannequin
 
 function UiKit.creer(classe, props, enfants)
 	local instance = Instance.new(classe)
@@ -89,6 +90,39 @@ function UiKit.boutonDoux(props, auClic, calme)
 	return UiKit.bouton(fusionner({ BackgroundColor3 = UiKit.COULEURS.secondaire, TextColor3 = UiKit.COULEURS.texte }, props), auClic, calme)
 end
 
+-- Bouton d'une action qu'on ne peut pas annuler (recommencer la robe) : le premier appui demande
+-- confirmation, un second appui (au moins 0,4 s après, dans les 3 s) agit ; sinon il revient à la normale.
+UiKit.DELAI_CONFIRMATION = 3
+UiKit.TEXTE_CONFIRMATION = "Vraiment ? Touche encore"
+function UiKit.boutonConfirme(props, auClic)
+	local b
+	local texte = props.Text
+	local jeton = 0
+	local function normal()
+		b.Text = texte
+		b.BackgroundColor3 = UiKit.COULEURS.secondaire
+		b.TextColor3 = UiKit.COULEURS.texte
+	end
+	b = UiKit.boutonDoux(props, function()
+		jeton += 1
+		if b.Text == UiKit.TEXTE_CONFIRMATION then
+			normal()
+			auClic()
+			return
+		end
+		local moi = jeton
+		b.Text = UiKit.TEXTE_CONFIRMATION
+		b.BackgroundColor3 = UiKit.COULEURS.alerte
+		b.TextColor3 = Color3.new(1, 1, 1)
+		task.delay(UiKit.DELAI_CONFIRMATION, function()
+			if moi == jeton then
+				normal()
+			end
+		end)
+	end, 0.4)
+	return b
+end
+
 -- Échelle d'une fenêtre de taille de référence pour tenir dans l'écran (téléphones)
 function UiKit.echelle(tailleEcran)
 	return math.min(1, (tailleEcran.X - 20) / UiKit.LARGEUR, (tailleEcran.Y - 60) / UiKit.HAUTEUR)
```

- [ ] **Step 4: Écrire l'écran d'épinglage**

`src/client/Atelier/EcranEpinglage.luau` :

```lua
-- Écran d'épinglage (panneau à droite, le mannequin à gauche) : toucher une pièce coupée l'épingle
-- à sa place sur le mannequin, dans son vrai tissu. La dernière pièce épinglée mène à la couture.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Couture = ReplicatedStorage:WaitForChild("Couture")
local Catalogue = require(Couture:WaitForChild("Catalogue"))
local Vignettes = require(script.Parent:WaitForChild("Vignettes"))

local HAUTEUR_CARTE = 54 -- six cartes tiennent sans défiler
local ECART = 4

return function(ctx)
	local UiKit, session = ctx.UiKit, ctx.session
	local C = UiKit.COULEURS
	local etat = session.etat

	UiKit.texte({
		Text = "Touche une pièce pour l'épingler à sa place sur le mannequin.",
		TextSize = 14,
		Size = UDim2.new(1, 0, 0, 36),
		Parent = ctx.contenu,
	})
	local liste = UiKit.creer("ScrollingFrame", {
		Name = "Liste",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Position = UDim2.fromOffset(0, 40),
		Size = UDim2.new(1, 0, 1, -84),
		ScrollBarThickness = 6,
		Parent = ctx.contenu,
	})
	local cartes = {}
	local pieces = etat:piecesDuCroquis()
	for i, id in ipairs(pieces) do
		local def = Catalogue.piece(id)
		local tissu = Catalogue.tissu(etat.tissus[id])
		local carte = UiKit.arrondir(UiKit.creer("TextButton", {
			Name = "Epingler_" .. id,
			Text = "",
			AutoButtonColor = true,
			BackgroundColor3 = C.panneau,
			Position = UDim2.fromOffset(0, (i - 1) * (HAUTEUR_CARTE + ECART)),
			Size = UDim2.new(1, -10, 0, HAUTEUR_CARTE),
			Parent = liste,
		}), 10)
		local apercu = UiKit.creer("ImageLabel", {
			Name = "Apercu",
			BackgroundTransparency = 1,
			BackgroundColor3 = UiKit.couleur(tissu.motif.couleurs[1]),
			ScaleType = Enum.ScaleType.Fit,
			Position = UDim2.fromOffset(6, 4),
			Size = UDim2.fromOffset(46, 46),
			Parent = carte,
		})
		local image = Vignettes.piece(id, etat.tissus[id], etat.coupees[id])
		if image then
			apercu.ImageContent = image
		else
			apercu.BackgroundTransparency = 0 -- mémoire des images pleine : la couleur du tissu
		end
		UiKit.texte({
			Text = def.nom .. (def.pliee and " (×2)" or ""),
			Font = Enum.Font.GothamBold,
			TextSize = 15,
			Position = UDim2.fromOffset(60, 6),
			Size = UDim2.new(1, -68, 0, 20),
			Parent = carte,
		})
		local etatTexte = UiKit.texte({
			Name = "Etat",
			TextSize = 14,
			Position = UDim2.fromOffset(60, 28),
			Size = UDim2.new(1, -68, 0, 20),
			Parent = carte,
		})
		carte.Activated:Connect(function()
			if session.etat.epinglees[id] then
				return
			end
			local r = session:epingler(id)
			if not r.ok then
				ctx.message(r.erreur, C.erreur)
			end
		end)
		cartes[id] = { carte = carte, etat = etatTexte }
	end
	liste.CanvasSize = UDim2.fromOffset(0, #pieces * (HAUTEUR_CARTE + ECART))

	UiKit.boutonConfirme({ Name = "Recommencer", Text = "Recommencer la robe", TextSize = 14, AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), Size = UDim2.fromOffset(200, 34), Parent = ctx.contenu }, function()
		local r = session:recommencer()
		if not r.ok then
			ctx.message(r.erreur, C.erreur)
		end
	end)

	local function rafraichir()
		for id, c in pairs(cartes) do
			local fait = session.etat.epinglees[id] == true
			c.etat.Text = fait and "Épinglée" or "Touche pour épingler"
			c.etat.TextColor3 = fait and C.ok or C.texteDoux
			c.carte.BackgroundColor3 = fait and C.secondaire or C.panneau
			c.carte.AutoButtonColor = not fait
		end
	end
	local desabonner = session:surChangement(rafraichir)
	rafraichir()
	return function()
		desabonner()
	end
end
```

- [ ] **Step 5: Écrire l'écran de couture**

`src/client/Atelier/EcranCouture.luau` :

```lua
-- Écran de couture : la pièce passe sous l'aiguille, une couture après l'autre. On maintient « Coudre »
-- (ou Espace) et on glisse à gauche ou à droite pour garder l'aiguille sur le pointillé.
-- Vitesse tortue ↔ lapin, découd-vite, assistance (note plafonnée). La logique est dans MachineCoudre.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Couture = ReplicatedStorage:WaitForChild("Couture")
local Catalogue = require(Couture:WaitForChild("Catalogue"))
local Polygone = require(Couture:WaitForChild("Polygone"))
local MachineCoudre = require(script.Parent:WaitForChild("MachineCoudre"))
local Vignettes = require(script.Parent:WaitForChild("Vignettes"))

local PX = 80 -- pixels par dm sous l'aiguille : 0,05 dm de tolérance = 4 px
local LARGEUR_PLATEAU = 480
local COURSE = 100 -- px de glisser pour corriger à fond (à l'échelle 1)
local BOIS = Color3.fromRGB(205, 170, 125)
local FIL = Color3.fromRGB(60, 40, 50)
local VITESSES = { { "tortue", "Tortue" }, { "normale", "Normale" }, { "lapin", "Lapin" } }

return function(ctx)
	local UiKit, session, contenu = ctx.UiKit, ctx.session, ctx.contenu
	local C = UiKit.COULEURS
	local connexions = {}
	local machine, boite
	local vitesse, assistance = "normale", false
	local tenu = nil -- appui en cours : { entree, objet, x0, x }
	local points = {} -- un point de couture par mesure

	-- Plateau de la machine : le tissu bouge, l'aiguille reste au centre
	local plateau = UiKit.arrondir(UiKit.creer("Frame", {
		Name = "Plateau",
		BackgroundColor3 = BOIS,
		ClipsDescendants = true,
		Size = UDim2.new(0, LARGEUR_PLATEAU, 1, 0),
		Parent = contenu,
	}), 10)
	local tissu = UiKit.creer("Frame", { Name = "Tissu", AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 1, Parent = plateau })
	local image
	local pointille = UiKit.creer("Frame", { Name = "Pointille", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Parent = tissu })
	local calquePoints = UiKit.creer("Frame", { Name = "Points", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Parent = tissu })
	UiKit.creer("Frame", { Name = "Barre", AnchorPoint = Vector2.new(0.5, 1), BackgroundColor3 = Color3.fromRGB(150, 150, 160), BorderSizePixel = 0, Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(4, 60), Parent = plateau })
	local aiguille = UiKit.arrondir(UiKit.creer("Frame", { Name = "Aiguille", AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 1, Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(12, 12), Parent = plateau }), 6)
	UiKit.creer("UIStroke", { Color = C.erreur, Thickness = 2, Parent = aiguille })

	-- Panneau de commandes
	local panneau = UiKit.creer("Frame", { Name = "Panneau", BackgroundTransparency = 1, Position = UDim2.fromOffset(LARGEUR_PLATEAU + 16, 0), Size = UDim2.new(1, -(LARGEUR_PLATEAU + 16), 1, 0), Parent = contenu })
	local listePieces = UiKit.creer("Frame", { Name = "Pieces", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 144), Parent = panneau })
	local ids = session.etat:piecesDuCroquis()
	local lignes = {}
	for i, id in ipairs(ids) do
		lignes[id] = UiKit.texte({ Name = "Ligne" .. i, TextSize = 14, Position = UDim2.fromOffset(0, (i - 1) * 24), Size = UDim2.new(1, 0, 0, 22), Parent = listePieces })
	end
	local note = UiKit.texte({ Name = "Note", Font = Enum.Font.GothamBold, TextSize = 18, Position = UDim2.fromOffset(0, 150), Size = UDim2.new(1, 0, 0, 24), Parent = panneau })
	UiKit.texte({
		Text = "Maintiens « Coudre » (ou Espace) et glisse à gauche ou à droite : l'aiguille doit rester sur le pointillé.",
		TextSize = 14,
		TextColor3 = C.texteDoux,
		Position = UDim2.fromOffset(0, 178),
		Size = UDim2.new(1, 0, 0, 52),
		Parent = panneau,
	})
	local boutonsVitesse = {}
	local rafraichir
	for k, v in ipairs(VITESSES) do
		boutonsVitesse[v[1]] = UiKit.boutonDoux({ Name = "Vitesse_" .. v[1], Text = v[2], TextSize = 14, Position = UDim2.new((k - 1) / 3, 0, 0, 236), Size = UDim2.new(1 / 3, -6, 0, 34), Parent = panneau }, function()
			vitesse = v[1]
			if machine then
				machine:choisirVitesse(vitesse)
			end
			rafraichir()
		end)
	end
	local boutonAssistance = UiKit.boutonDoux({ Name = "Assistance", TextSize = 14, Position = UDim2.fromOffset(0, 278), Size = UDim2.new(1, -6, 0, 34), Parent = panneau }, function()
		assistance = not assistance
		if machine then
			machine:activerAssistance(assistance)
		end
		rafraichir()
	end)
	local effacerPoints
	UiKit.boutonDoux({ Name = "Decoudre", Text = "Découdre (découd-vite)", TextSize = 14, Position = UDim2.fromOffset(0, 320), Size = UDim2.new(1, -6, 0, 34), Parent = panneau }, function()
		if machine and machine:decoudre() then
			effacerPoints()
			rafraichir()
		end
	end)
	local boutonCoudre = UiKit.bouton({ Name = "Coudre", Text = "Coudre (maintenir)", TextSize = 18, Position = UDim2.fromOffset(0, 362), Size = UDim2.new(1, -6, 0, 58), Parent = panneau })
	UiKit.boutonConfirme({ Name = "Recommencer", Text = "Recommencer la robe", TextSize = 14, AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), Size = UDim2.fromOffset(200, 34), Parent = panneau }, function()
		local r = session:recommencer()
		if not r.ok then
			ctx.message(r.erreur, C.erreur)
		end
	end)

	-- Repère du tissu (px) d'un point du patron (dm)
	local function versTissu(p)
		return (p.x - boite.minX) * PX, (p.y - boite.minY) * PX
	end

	-- Une pièce passe sous l'aiguille : image du vrai tissu, pointillé des coutures
	local function commencerPiece(id)
		machine = MachineCoudre.nouvelle(id, session.rng:NextInteger(1, 1000000))
		machine:choisirVitesse(vitesse)
		machine:activerAssistance(assistance)
		boite = Polygone.boite(Catalogue.piece(id).contour)
		tissu.Size = UDim2.fromOffset((boite.maxX - boite.minX) * PX, (boite.maxY - boite.minY) * PX)
		local etat = session.etat
		if image then
			image:Destroy()
		end
		image = UiKit.creer("ImageLabel", {
			Name = "Piece",
			BackgroundColor3 = UiKit.couleur(Catalogue.tissu(etat.tissus[id]).motif.couleurs[1]),
			Size = UDim2.fromScale(1, 1),
			ZIndex = 0,
			Parent = tissu,
		})
		local contenuImage = Vignettes.piece(id, etat.tissus[id], etat.coupees[id], 256)
		if contenuImage then
			image.ImageContent = contenuImage
			image.BackgroundTransparency = 1
		end -- sinon (mémoire des images pleine) : la couleur du tissu
		pointille:ClearAllChildren()
		for _, seg in ipairs(machine.segments) do
			local ax, ay = versTissu(seg.a)
			local bx, by = versTissu(seg.b)
			local longueur = math.sqrt((bx - ax) ^ 2 + (by - ay) ^ 2)
			local angle = math.deg(math.atan2(by - ay, bx - ax))
			local tirets = math.max(1, math.floor(longueur / (0.2 * PX)))
			for t = 0, tirets - 1 do
				local f = (t + 0.25) / tirets
				UiKit.creer("Frame", {
					AnchorPoint = Vector2.new(0.5, 0.5),
					BackgroundColor3 = FIL,
					BorderSizePixel = 0,
					Position = UDim2.fromOffset(ax + (bx - ax) * f, ay + (by - ay) * f),
					Size = UDim2.fromOffset(0.1 * PX, 2),
					Rotation = angle,
					Parent = pointille,
				})
			end
		end
		effacerPoints()
	end

	effacerPoints = function()
		for i = #points, #machine.ecarts + 1, -1 do
			points[i]:Destroy()
			points[i] = nil
		end
	end

	local function ajouterPoints()
		local e = machine:etat()
		local x, y = versTissu(e.point)
		for i = #points + 1, #machine.ecarts do
			points[i] = UiKit.creer("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = C.accent, BorderSizePixel = 0, Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(4, 4), Parent = calquePoints })
		end
	end

	-- Le tissu tourne pour que la couture en cours monte vers l'aiguille, et se place sous elle
	local function dessiner()
		local e = machine:etat()
		local phi = -math.pi / 2 - math.atan2(e.direction.y, e.direction.x)
		local vx = (e.point.x - (boite.minX + boite.maxX) / 2) * PX
		local vy = (e.point.y - (boite.minY + boite.maxY) / 2) * PX
		local c, s = math.cos(phi), math.sin(phi)
		tissu.Rotation = math.deg(phi)
		tissu.Position = UDim2.new(0.5, -(vx * c - vy * s), 0.5, -(vx * s + vy * c))
	end

	rafraichir = function()
		local etat = session.etat
		for _, id in ipairs(ids) do
			local nom = Catalogue.piece(id).nom
			local n = etat.coutures[id]
			local ligne = lignes[id]
			if n then
				ligne.Text = ("%s — %d %%"):format(nom, math.floor(n * 100 + 0.5))
				ligne.TextColor3 = C.ok
			else
				ligne.Text = nom .. (machine and machine.idPiece == id and " — en cours" or " — à coudre")
				ligne.TextColor3 = machine and machine.idPiece == id and C.texte or C.texteDoux
			end
		end
		local provisoire = machine and machine:noteProvisoire()
		note.Text = provisoire and ("Couture : %d %%"):format(math.floor(provisoire * 100 + 0.5)) or "Couture : —"
		for nom, b in pairs(boutonsVitesse) do
			b.BackgroundColor3 = nom == vitesse and C.accent or C.secondaire
			b.TextColor3 = nom == vitesse and Color3.new(1, 1, 1) or C.texte
		end
		boutonAssistance.Text = assistance and "Assistance : oui (85 % au plus)" or "Assistance : non"
		if machine then
			dessiner()
		end
	end

	-- La pièce est finie : on rend le relevé ; la suivante arrive par l'avis de changement
	local function rendre()
		local r = session:rendreCouture(machine.idPiece, machine:releve())
		if not r.ok then
			ctx.message(r.erreur, C.erreur)
			machine:decoudre()
			effacerPoints()
			rafraichir()
		end
	end

	-- Maintenir « Coudre » (souris ou doigt), ou Espace ; glisser corrige la direction
	local function direction()
		local course = COURSE * plateau.AbsoluteSize.X / LARGEUR_PLATEAU
		-- Glisser vers la droite pousse le tissu à droite : l'écart diminue
		return -math.clamp((tenu.x - tenu.x0) / math.max(course, 1), -1, 1)
	end
	table.insert(connexions, boutonCoudre.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			tenu = { entree = input.UserInputType, objet = input, x0 = input.Position.X, x = input.Position.X }
		end
	end))
	table.insert(connexions, UserInputService.InputBegan:Connect(function(input, traite)
		if not traite and input.KeyCode == Enum.KeyCode.Space and not tenu then
			local souris = UserInputService:GetMouseLocation()
			tenu = { entree = "espace", x0 = souris.X, x = souris.X }
		end
	end))
	-- Au doigt, seul le doigt qui tient « Coudre » dirige l'aiguille ; à la souris, ses mouvements
	table.insert(connexions, UserInputService.InputChanged:Connect(function(input)
		if not tenu then
			return
		end
		local suit = if tenu.entree == Enum.UserInputType.Touch
			then input == tenu.objet
			else input.UserInputType == Enum.UserInputType.MouseMovement
		if suit then
			tenu.x = input.Position.X
		end
	end))
	table.insert(connexions, UserInputService.InputEnded:Connect(function(input)
		if not tenu then
			return
		end
		local fin
		if tenu.entree == "espace" then
			fin = input.KeyCode == Enum.KeyCode.Space
		elseif tenu.entree == Enum.UserInputType.Touch then
			fin = input == tenu.objet
		else
			fin = input.UserInputType == Enum.UserInputType.MouseButton1
		end
		if fin then
			tenu = nil
		end
	end))
	table.insert(connexions, RunService.RenderStepped:Connect(function(dt)
		if not machine or machine:fini() or not tenu then
			return
		end
		machine:avancer(dt, direction())
		ajouterPoints()
		if machine:fini() then
			tenu = nil
			rendre()
		else
			rafraichir()
		end
	end))

	local desabonner = session:surChangement(function(etat)
		if etat.etape == "couture" and etat.coutures[machine.idPiece] ~= nil then
			commencerPiece(etat:piecesACoudre()[1])
		end
		rafraichir()
	end)
	commencerPiece(session.etat:piecesACoudre()[1])
	rafraichir()
	return function()
		desabonner()
		for _, c in ipairs(connexions) do
			c:Disconnect()
		end
	end
end
```

- [ ] **Step 6: Réécrire l'écran provisoire de fin**

`src/client/Atelier/EcranSuite.luau` :

```lua
-- Écran provisoire après la couture (panneau à droite, la robe cousue sur le mannequin) :
-- les décorations, la photo et la livraison arrivent au plan 3c. On peut recommencer une robe.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Couture = ReplicatedStorage:WaitForChild("Couture")
local Notation = require(Couture:WaitForChild("Notation"))

return function(ctx)
	local UiKit = ctx.UiKit
	local recette = ctx.session.etat:recette()
	local qualite = recette and Notation.bilan(recette).qualite or 0
	UiKit.texte({
		Text = "Bravo, la robe est cousue ! Les décorations, la photo et la livraison à la cliente arrivent bientôt.",
		TextSize = 16,
		Size = UDim2.new(1, 0, 0, 90),
		Parent = ctx.contenu,
	})
	UiKit.texte({
		Name = "Qualite",
		Text = ("Qualité de la robe : %d %%"):format(math.floor(qualite * 100 + 0.5)),
		Font = Enum.Font.GothamBold,
		TextSize = 18,
		Position = UDim2.fromOffset(0, 100),
		Size = UDim2.new(1, 0, 0, 28),
		Parent = ctx.contenu,
	})
	UiKit.boutonConfirme({
		Name = "Recommencer",
		Text = "Recommencer une robe",
		Position = UDim2.fromOffset(0, 150),
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

- [ ] **Step 7: « Recommencer la robe » à confirmer à la découpe**

```diff
diff --git a/src/client/Atelier/EcranDecoupe.luau b/src/client/Atelier/EcranDecoupe.luau
index 64b527f..491f128 100644
--- a/src/client/Atelier/EcranDecoupe.luau
+++ b/src/client/Atelier/EcranDecoupe.luau
@@ -92,7 +92,7 @@ return function(ctx)
 			montrerPiece()
 		end
 	end, CALME)
-	UiKit.boutonDoux({ Name = "Recommencer", Text = "Recommencer la robe", TextSize = 14, AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), Size = UDim2.fromOffset(200, 34), Parent = panneau }, function()
+	UiKit.boutonConfirme({ Name = "Recommencer", Text = "Recommencer la robe", TextSize = 14, AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), Size = UDim2.fromOffset(200, 34), Parent = panneau }, function()
 		local r = session:recommencer()
 		if not r.ok then
 			ctx.message(r.erreur, C.erreur)
```

- [ ] **Step 8: Brancher les écrans, le panneau et la scène**

```diff
diff --git a/src/client/Atelier/init.client.luau b/src/client/Atelier/init.client.luau
index 003dc5b..547e9c2 100644
--- a/src/client/Atelier/init.client.luau
+++ b/src/client/Atelier/init.client.luau
@@ -1,28 +1,36 @@
--- Atelier : script de démarrage du client. Construit la fenêtre de l'atelier et affiche l'écran
--- qui correspond à l'étape de la commande en cours (accueil, carnet, achat, découpe, suite).
+-- Atelier : script de démarrage du client. Construit la fenêtre de l'atelier, affiche l'écran
+-- qui correspond à l'étape de la commande en cours et tient la scène 3D (mannequin, robe) à jour.
 local Players = game:GetService("Players")
 
 local UiKit = require(script:WaitForChild("UiKit"))
 local Session = require(script:WaitForChild("Session"))
+local Scene = require(script:WaitForChild("Scene"))
 
 local ECRANS = {
 	accueil = require(script:WaitForChild("EcranAccueil")),
 	carnet = require(script:WaitForChild("EcranCarnet")),
 	achat = require(script:WaitForChild("EcranAchat")),
 	decoupe = require(script:WaitForChild("EcranDecoupe")),
-	epinglage = require(script:WaitForChild("EcranSuite")),
+	epinglage = require(script:WaitForChild("EcranEpinglage")),
+	couture = require(script:WaitForChild("EcranCouture")),
+	decorations = require(script:WaitForChild("EcranSuite")),
 }
 local TITRES = {
 	accueil = "Atelier de couture",
 	carnet = "1. Carnet de croquis",
 	achat = "2. Achat du tissu",
 	decoupe = "3. Table de découpe",
-	epinglage = "Toutes les pièces sont coupées !",
+	epinglage = "4. Épinglage",
+	couture = "5. Couture",
+	decorations = "La robe est cousue !",
 }
+-- Postes autour du mannequin : la fenêtre devient un panneau à droite pour laisser voir la robe
+local EN_PANNEAU = { epinglage = true, decorations = true }
 
 local C = UiKit.COULEURS
 local joueur = Players.LocalPlayer
 local session = Session.nouvelle()
+local scene = Scene.nouvelle()
 
 local gui = UiKit.creer("ScreenGui", {
 	Name = "Atelier",
@@ -117,6 +125,10 @@ local function afficherMessage(texte, couleur)
 	end)
 end
 
+fenetre:GetPropertyChangedSignal("Visible"):Connect(function()
+	scene:ouvrir(fenetre.Visible, session.etat)
+end)
+
 UiKit.bouton({
 	Name = "OuvrirAtelier",
 	Text = "Atelier",
@@ -128,16 +140,41 @@ UiKit.bouton({
 	fenetre.Visible = not fenetre.Visible
 end)
 
+-- Fenêtre au centre, ou panneau à droite (titre et argent sur deux lignes)
+local function disposer(enPanneau)
+	if enPanneau then
+		fenetre.AnchorPoint = Vector2.new(1, 0.5)
+		fenetre.Position = UDim2.new(1, -16, 0.5, 0)
+		fenetre.Size = UDim2.fromOffset(UiKit.LARGEUR_PANNEAU, UiKit.HAUTEUR)
+		titre.Size = UDim2.new(1, -76, 0, 32)
+		argent.Position = UDim2.fromOffset(20, 46)
+		argent.TextXAlignment = Enum.TextXAlignment.Left
+		contenu.Position = UDim2.fromOffset(20, 84)
+		contenu.Size = UDim2.new(1, -40, 1, -118)
+	else
+		fenetre.AnchorPoint = Vector2.new(0.5, 0.5)
+		fenetre.Position = UDim2.fromScale(0.5, 0.5)
+		fenetre.Size = UDim2.fromOffset(UiKit.LARGEUR, UiKit.HAUTEUR)
+		titre.Size = UDim2.new(1, -260, 0, 32)
+		argent.Position = UDim2.new(1, -240, 0, 14)
+		argent.TextXAlignment = Enum.TextXAlignment.Right
+		contenu.Position = UDim2.fromOffset(20, 60)
+		contenu.Size = UDim2.new(1, -40, 1, -94)
+	end
+end
+
 -- Navigation : un écran par étape ; il se reconstruit seul quand l'état change
 local etapeAffichee, fermerEcran
 local function afficher()
 	local etat = session.etat
 	argent.Text = ("%d pièces d'or"):format(etat.argent)
+	task.spawn(scene.synchroniser, scene, etat) -- la construction des pièces 3D peut prendre un moment
 	if etat.etape ~= etapeAffichee then
 		if fermerEcran then
 			fermerEcran()
 		end
 		contenu:ClearAllChildren()
+		disposer(EN_PANNEAU[etat.etape] == true)
 		etapeAffichee = etat.etape
 		titre.Text = TITRES[etat.etape] or etat.etape
 		fermerEcran = ECRANS[etat.etape]({ session = session, contenu = contenu, message = afficherMessage, UiKit = UiKit })
```

- [ ] **Step 9: Lancer les tests**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT"`
Expected:
```
Unitaires : 104499 vérifications
TOUT EST VERT : 198 vérifications
```

- [ ] **Step 10: Commit**

```bash
git add src/client/Atelier tests/scenario.luau
git commit -m "Écrans d'épinglage et de couture : la robe se pose sur le mannequin et se coud

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 6: Vérification dans Studio et README

**Files:**
- Modify: `README.md`
- Modify: `AtelierCouture.rbxl` (régénéré)

**Interfaces:**
- Consumes: tout ce qui précède.
- Produces: une robe jouable jusqu'à la couture. C'est le point de départ du plan 3c.

- [ ] **Step 1: Lancer le jeu dans Studio**

Utiliser l'instance synchronisée par `rojo serve` (ou ouvrir un `AtelierCouture.rbxl` régénéré). Lancer Play avec le connecteur MCP (`start_stop_play`).

- [ ] **Step 2: Aller jusqu'à l'épinglage (`user_mouse_input`, `instance_path`, 0,7 s entre deux clics)**

Cliquer dans l'ordre :
1. `LocalPlayer.PlayerGui.Atelier.Fenetre.Contenu.Clochette` ;
2. `…Contenu.Gauche.Pieces.ToutEnUnTissu`, puis `…Contenu.ChoixTissu.Grille.Tissu_coton_bleu_carreaux` ;
3. `…Contenu.Valider` ;
4. `…Contenu.Lignes.Ligne_coton_bleu_carreaux.Acheter` ;
5. `…Contenu.AllerDecoupe` ;
6. quatre fois `…Contenu.Panneau.Couper`.

Expected: le titre « 4. Épinglage ». La fenêtre est un panneau à droite ; le mannequin est à gauche, en entier ; les quatre cartes montrent la pièce découpée dans le vichy et tiennent sans défiler.

- [ ] **Step 3: Épingler et vérifier la caméra**

1. Cliquer `…Contenu.Liste.Epingler_corsage_droit_devant` et `…Epingler_jupe_droite_devant`.
2. Cliquer `…Fenetre.Fermer`.
3. Lire `workspace.CurrentCamera.CameraType` avec `execute_luau` (Client).
4. Cliquer `…OuvrirAtelier` (dans `PlayerGui.Atelier`), puis épingler les deux pièces restantes.

Expected :
- les pièces apparaissent sur le mannequin (capture d'écran) ;
- fenêtre fermée : `Enum.CameraType.Custom` ; rouverte : `Scriptable` ;
- après la dernière pièce : « 5. Couture ».

- [ ] **Step 4: Coudre**

1. Lire le centre de `…Contenu.Panneau.Coudre` (`AbsolutePosition + AbsoluteSize / 2`).
2. Avec `user_mouse_input` : `moveTo` sur ce centre, `mouseButtonDown`, 1,5 s d'attente, `moveTo` 20 px à droite, 1,5 s, `moveTo` 20 px à gauche, 1,5 s, `mouseButtonUp`.
3. Cliquer `Vitesse_lapin` puis `Assistance`.
4. Maintenir `Coudre` environ 12 s par pièce jusqu'au titre « La robe est cousue ! ».

Expected :
- le tissu (vrai vichy) défile sous l'aiguille rouge au centre, le pointillé monte vers l'aiguille, les points de couture restent sur le tissu, et la note s'affiche (« Couture : NN % ») ;
- au changement de couture, le tissu tourne ;
- à la fin : le panneau à droite, la robe cousue sur le mannequin, « Qualité de la robe : NN % » ;
- aucune erreur dans la sortie (`get_console_output`).

- [ ] **Step 5: Mettre à jour le README**

`README.md` :

````markdown
# Atelier de couture — jeu Roblox

Jeu de couture sur Roblox, inspiré des mécaniques de *Dressmaker* (Cozy Lives / Free Lives, 2026).
On ne choisit pas un vêtement tout fait : on **dessine**, **coupe**, **coud** et **décore** la robe,
et le tissu découpé se voit tel quel sur la robe en 3D.

Le jeu est en cours de refonte, sous-projet par sous-projet
(spec : `docs/superpowers/specs/2026-09-28-atelier-coeur-design.md`, plans : `docs/superpowers/plans/`).

## État actuel (plan 3b)

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
   La qualité de la robe (droit-fil × couture, pondérée par la surface) s'affiche à la fin.
7. La suite (décorations, photo et livraison) arrive au plan 3c ; serveur, boutiques et sauvegarde au plan 4.

« Recommencer la robe » demande une confirmation (deuxième appui) : le tissu déjà coupé est perdu.

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
  de découpe et de la machine à coudre ; `Scene` tient le mannequin, la robe épinglée et la caméra du poste ;
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

- [ ] **Step 6: Tests, lieu régénéré, commit**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT"`
Expected:
```
Unitaires : 104499 vérifications
TOUT EST VERT : 198 vérifications
```

```bash
C:/dev/jeux/roblox-maker/rojo.exe build -o AtelierCouture.rbxl
git add README.md AtelierCouture.rbxl
git commit -m "Plan 3b terminé : épinglage et couture jouables

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```
