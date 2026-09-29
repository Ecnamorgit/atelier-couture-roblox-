# Clientes et progression — Plan 5c : les robes libres

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Le prêt-à-porter : après deux commandes livrées, le joueur crée une robe libre (une taille, ni cliente ni exigence), puis la vend (prix selon matières, main d'œuvre, qualité et prestige) ou l'offre à une cliente (amitié) ; la toile de jute, gratuite, pour s'exercer ou vendre sans risque ; l'équilibrage revu avec une robe libre sur quatre.

**Architecture:**
- **Données** : `Catalogue` gagne la toile de jute (matière `jute`, prix 0) ; `Progression` gagne le bonus de vente, le prestige d'une vente et le gain d'un cadeau.
- **Règles** (`EtatAtelier`, serveur) : `nouvelleRobeLibre(taille)`, le prix des matières noté à la découpe, `prixVente`, `vendre`, `offrir(idCliente)` ; `livrer` refuse une robe libre ; compteur `ventes` ; sauvegarde d'une robe libre en cours.
- **Interface** : « Robe libre » et le choix de la taille à l'accueil ; en-tête du carnet ; à la photo, le prix, « Vendre (N po) » et « Offrir à… » ; pas de cliente dans la scène ; annonces de l'accueil ; la vitrine suit aussi les robes vendues ou offertes.
- **Équilibrage** : la simulation fait une robe libre de jute, vendue, toutes les quatre robes.

**Tech Stack:** Luau, Rojo 7.7.0-rc.1, simulation Luau 0.650 (`tests/lancer.sh`), Roblox Studio via le connecteur MCP Studio.

**Spec:** `docs/superpowers/specs/2026-09-29-clientes-progression-design.md` (§4 prestige d'une vente et d'un cadeau, bonus de vente ; §5 robes libres ; §8 `nouvelleRobeLibre`, `vendre`, `offrir` ; §9 photo d'une robe libre ; §10 équilibrage ; §11 plan 5c). Plans précédents : `…plan5a.md`, `…plan5b.md`.

## Décisions de ce plan

- **Robes libres** (spec §5) : ouvertes quand deux commandes ont été livrées (`EtatAtelier.LIBRES_APRES = 2`). Taille S, M ou L ; mesures de la table des tailles ; pas de mesures à prendre, pas d'acompte, droit au carnet. Chaque robe libre prend un numéro de visite (la scène reconnaît la commande à ce numéro).
- **Prix de vente** : (matières + décorations + 6 po par pièce posée) × (0,5 + qualité) × (1 + 6 % par niveau de prestige au-delà du premier), arrondi. Matières : le tissu entamé de chaque rouleau, au prix du tissu, noté quand la dernière pièce est coupée (`commande.matieres`).
- **Vendre** : l'argent, du prestige (prix / 15, arrondi), la robe en vitrine, `ventes` + 1. **Offrir** à une cliente déjà venue (au moins une visite) : amitié +1 à +4 selon le plus haut score de ses deux styles (moins de 30, 30 à 59, 60 à 79, 80 et plus), +2 de prestige, pas d'argent ; la robe part aussi en vitrine (la vitrine montre la dernière robe de l'atelier). Les deux annoncent ce qui vient de s'ouvrir.
- **Toile de jute** (spec §5) : gratuite, brune, un style à peine marqué (décontracté 4), ouverte dès le départ ; rangée en fin de catalogue (l'étagère de la boutique et les tests gardent leurs 24 premiers tissus).
- **Interface** : « Robe libre » à côté de la clochette, puis « Taille : S M L » ; le carnet titre « Robe libre (taille M) : à ton idée. » ; à la photo, « Ta robe libre est prête. », « Prix de vente : N po », « Vendre (N po) » (confirmé par un second appui) et « Offrir à… » (liste des clientes déjà venues, avec l'amitié que la robe leur apporterait) ; la carte de la toile de jute dit « Gratuit ». Aucune cliente n'entre pour une robe libre. Sons : la caisse pour une vente, la fanfare pour un cadeau.
- **Équilibrage** (spec §10, amendé) : avec une robe libre de jute vendue toutes les quatre robes, la simulation (vingt parties, 90 robes) mesure le prestige 2 à la 3e robe au plus tard, le 5 de la 17e à la 22e (médiane 19), tout ouvert de la 51e à la 77e (médiane 61) : les amitiés ne montent qu'avec les commandes, et une robe de jute rapporte peu de prestige. La cible de la spec (tout ouvert entre 30 et 50) supposait trop peu de robes libres : elle passe à 50–80 en médiane, le prestige 5 se juge aussi en médiane (12e–20e, au plus tard la 25e), et le critère de réussite n° 6 est amendé en conséquence (la spec est mise à jour dans ce plan). Les cadeaux et le courrier (plan 5d) permettent d'aller plus vite.
- **Scénario** : Luau limite un bloc à 200 variables locales ; la partie des robes libres est dans un bloc `do … end`.
- **Vérifié pendant la préparation** : le plan a été joué entièrement sur un brouillon tiré de `main` ; neuf variantes du brouillon (robe libre avant l'heure, robe libre livrée, bonus de vente, cadeau à une cliente jamais venue, vitrine, cliente dans la scène, prix des matières, sauvegarde, équilibrage) échouent chacune sur la vérification qui les garde.

## Global Constraints

- **Dépôt** : `C:\dev\jeux\atelier-couture`, branche `robes-libres`, créée depuis `main` (où le plan 5b est fusionné). Selon les règles du commanditaire : la branche testée et relue est fusionnée dans `main` et poussée sur GitHub.
- **Rojo** : `C:/dev/jeux/roblox-maker/rojo.exe`.
- **Contraintes des plans précédents toujours valables** : fins de ligne LF, commits en français terminés par `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`, textes d'au moins 14 px, le serveur fait foi.
- **Contenu original** (spec §1) : aucun nom, texte, son ni image de Dressmaker.
- **Commandes** : tout se joue d'un seul doigt ou à la souris seule.

## Review Focus

- **Vendre ou offrir ce qui n'est pas une robe libre** (commande en cours, appel direct au serveur). Attendu : refus. Test : `50_robes_libres`, « une commande ne se vend ni ne s'offre ».
- **Offrir à une cliente jamais venue, inconnue ou absente de l'appel.** Attendu : refus, rien ne change. Test : `50_robes_libres`, « offrir à une cliente jamais venue ou inconnue : refusé ».
- **Robe libre avant deux commandes livrées, ou taille farfelue.** Attendu : refus. Tests : `50_robes_libres`, « robe libre fermée avant deux commandes livrées », « taille inconnue refusée : … ».
- **Robe libre en cours dans une sauvegarde abîmée** (exigences, cliente, drapeau, matières). Attendu : abandonnée, le reste gardé. Test : `50_robes_libres`, « robe libre abîmée (…) : abandonnée ».
- **Robe de jute** (matières à 0). Attendu : vendue pour sa main d'œuvre, jamais à 0. Test : `50_robes_libres`, « robe de jute : vendue pour sa main d'œuvre ».

## Structure des fichiers

| Fichier | Rôle |
|---|---|
| `src/shared/Catalogue.luau` | Toile de jute ; matière `jute` |
| `src/shared/Progression.luau` | `BONUS_VENTE`, `bonusVente`, `prestigeVente`, `PRESTIGE_CADEAU`, `gainCadeau` |
| `src/shared/EtatAtelier.luau` | `LIBRES_APRES`, `MAIN_OEUVRE`, `ventes`, `nouvelleRobeLibre`, matières notées, `prixVente`, `vendre`, `offrir` ; `livrer` refuse une robe libre |
| `src/server/Sauvegarde.luau`, `src/server/Commande.luau`, `src/client/Atelier/Session.luau` | Robe libre sauvegardée, `ventes` ; actions ; vitrine après une vente ou un cadeau |
| `src/client/Atelier/EcranAccueil.luau`, `EcranCarnet.luau`, `EcranPresentation.luau`, `Scene.luau`, `init.client.luau` | Interface des robes libres |
| `tests/unitaires/50_robes_libres.luau` | **Nouveau** |
| `tests/unitaires/02_…`, `42_…`, `45_…`, `48_equilibrage.luau`, `tests/scenario.luau` | Tests complétés |
| `docs/superpowers/specs/2026-09-29-clientes-progression-design.md` | Cible d'équilibrage amendée |
| `README.md`, `AtelierCouture.rbxl` | État du jeu ; lieu régénéré |

---

### Task 1: La toile de jute ; le prix d'une vente, le gain d'un cadeau

**Files:**
- Modify: `src/shared/Catalogue.luau`, `src/shared/Progression.luau`
- Modify: `tests/unitaires/02_catalogue.luau`, `42_clientes.luau`, `45_deblocages.luau`

**Interfaces:**
- Consumes: `Catalogue.Tissus`, `Catalogue.MATIERES` ; `Deblocages.PRESTIGE_MATIERES` (la jute n'y est pas : ouverte au départ).
- Produces: tissu `toile_jute` (prix 0) ; `Catalogue.MATIERES.jute` ; `Progression.BONUS_VENTE = 0.06`, `bonusVente(niveau)`, `prestigeVente(prix)`, `PRESTIGE_CADEAU = 2`, `gainCadeau(score)`.

- [ ] **Step 1: Écrire les tests**

Dans `tests/unitaires/02_catalogue.luau`, remplacer :

```lua
U.verifier(#Catalogue.Tissus == 24, "24 tissus")
```

par :

```lua
U.verifier(#Catalogue.Tissus == 25, "25 tissus (dont la toile de jute)")
local jute = Catalogue.tissu("toile_jute")
U.verifier(jute ~= nil and jute.prix == 0 and jute.teinte == "brun" and Catalogue.MATIERES[jute.matiere] ~= nil, "la toile de jute : gratuite, brune, rendue comme un tissu")
local plusFaible = math.huge
for _, t in ipairs(Catalogue.Tissus) do
	if t.id ~= "toile_jute" then
		local total = 0
		for _, pts in pairs(t.style) do
			total += pts
		end
		plusFaible = math.min(plusFaible, total)
	end
end
U.verifier((jute.style.decontracte or 0) > 0 and (jute.style.decontracte or 0) < plusFaible, "la toile de jute : un style à peine marqué (décontracté)")
```

Dans `tests/unitaires/45_deblocages.luau`, remplacer :

```lua
	local attendu = t.matiere == "coton" or t.matiere == "lin"
	U.verifier((ouverts.tissus[t.id] == true) == attendu, t.id .. " : ouvert au départ seulement en coton ou en lin")
end
U.verifier(#tissusOuverts == 8, "huit tissus au départ")
```

par :

```lua
	local attendu = t.matiere == "coton" or t.matiere == "lin" or t.matiere == "jute"
	U.verifier((ouverts.tissus[t.id] == true) == attendu, t.id .. " : ouvert au départ seulement en coton, en lin ou en jute")
end
U.verifier(#tissusOuverts == 9, "neuf tissus au départ (dont la toile de jute)")
```

Dans `tests/unitaires/42_clientes.luau`, remplacer :

```lua
U.verifier(Progression.prestigeLivraison(124) == 12 and Progression.prestigeLivraison(125) == 13, "prestige : un dixième de la paie, arrondi")
```

par :

```lua
U.verifier(Progression.prestigeLivraison(124) == 12 and Progression.prestigeLivraison(125) == 13, "prestige : un dixième de la paie, arrondi")
U.verifier(Progression.prestigeVente(37) == 2 and Progression.prestigeVente(38) == 3, "robe vendue : un quinzième du prix, arrondi")
U.verifier(U.proche(Progression.bonusVente(1), 0) and U.proche(Progression.bonusVente(8), 0.42), "bonus de vente : +6 % par niveau au-delà du premier, +42 % au niveau 8")
U.verifier(Progression.gainCadeau(29) == 1 and Progression.gainCadeau(30) == 2 and Progression.gainCadeau(59) == 2 and Progression.gainCadeau(60) == 3 and Progression.gainCadeau(80) == 4 and Progression.gainCadeau(150) == 4, "cadeau : +1 à +4 selon le score de son style préféré")
U.verifier(Progression.PRESTIGE_CADEAU == 2, "cadeau : +2 de prestige")
```

Dans `tests/unitaires/02_catalogue.luau`, remplacer :

```lua
	U.verifier(t.prix >= 4 and t.prix <= 20, t.id .. " : prix entre 4 et 20")
```

par :

```lua
	U.verifier((t.prix >= 4 and t.prix <= 20) or (t.id == "toile_jute" and t.prix == 0), t.id .. " : prix entre 4 et 20 (la toile de jute est gratuite)")
```

- [ ] **Step 2: Lancer les tests, vérifier l'échec**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT|attempt|membre" | head -3`
Expected: échec : une ligne qui finit par `ÉCHEC : 25 tissus (dont la toile de jute)`

- [ ] **Step 3: Écrire le code**

Dans `src/shared/Catalogue.luau`, remplacer :

```lua
	tissu("satin_violet_pois", "Satin violet à pois", "satin", "violet", 12,
		{ type = "pois", couleurs = { { 120, 70, 160 }, { 230, 210, 250 } }, periode = 0.5, rayon = 0.1 }, { mignon = 10, gothique = 8 }),
}
```

par :

```lua
	tissu("satin_violet_pois", "Satin violet à pois", "satin", "violet", 12,
		{ type = "pois", couleurs = { { 120, 70, 160 }, { 230, 210, 250 } }, periode = 0.5, rayon = 0.1 }, { mignon = 10, gothique = 8 }),
	-- La toile de jute (sous-projet 2) : gratuite, pour s'exercer ou vendre sans risque ; un style à peine marqué
	tissu("toile_jute", "Toile de jute", "jute", "brun", 0,
		{ type = "carreaux", couleurs = { { 176, 140, 96 }, { 150, 116, 76 } }, periode = 0.25 }, { decontracte = 4 }),
}
```

Dans `src/shared/Catalogue.luau`, remplacer :

```lua
	lin = { rugosite = 1, reflet = 0, materiau = "Fabric" },
```

par :

```lua
	lin = { rugosite = 1, reflet = 0, materiau = "Fabric" },
	jute = { rugosite = 1, reflet = 0, materiau = "Fabric" },
```

Dans `src/shared/Progression.luau`, remplacer :

```lua
-- Points de prestige d'une robe livrée et payée
function Progression.prestigeLivraison(paie)
	return math.round(paie / 10)
end
```

par :

```lua
-- Points de prestige d'une robe livrée et payée
function Progression.prestigeLivraison(paie)
	return math.round(paie / 10)
end

-- Robes libres (sous-projet 2) : une robe vendue rapporte du prestige (prix / 15) ; son prix monte de 6 % par
-- niveau de prestige au-delà du premier (+42 % au niveau 8)
Progression.BONUS_VENTE = 0.06
function Progression.bonusVente(niveauPrestige)
	return Progression.BONUS_VENTE * (niveauPrestige - 1)
end
function Progression.prestigeVente(prix)
	return math.round(prix / 15)
end

-- Une robe offerte : +2 de prestige, et de l'amitié selon le score de son style préféré le plus haut
-- (moins de 30 : +1 ; 30 à 59 : +2 ; 60 à 79 : +3 ; 80 et plus : +4)
Progression.PRESTIGE_CADEAU = 2
function Progression.gainCadeau(score)
	return if score >= 80 then 4 elseif score >= 60 then 3 elseif score >= 30 then 2 else 1
end
```

- [ ] **Step 4: Lancer les tests**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT"`
Expected:
```
Unitaires : 107346 vérifications
TOUT EST VERT : 584 vérifications
```

- [ ] **Step 5: Commit**

```bash
git add src/shared/Catalogue.luau src/shared/Progression.luau tests/unitaires/02_catalogue.luau tests/unitaires/42_clientes.luau tests/unitaires/45_deblocages.luau
git commit -m "Toile de jute gratuite ; bonus de vente, prestige d'une vente, amitié d'un cadeau

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 2: Les robes libres : créer, vendre, offrir

**Files:**
- Modify: `src/shared/EtatAtelier.luau`
- Modify: `src/server/Sauvegarde.luau`, `src/server/Commande.luau` (actions), `src/client/Atelier/Session.luau`
- Create: `tests/unitaires/50_robes_libres.luau`

**Interfaces:**
- Consumes: `Progression.bonusVente`, `prestigeVente`, `PRESTIGE_CADEAU`, `gainCadeau` (tâche 1) ; `Deblocages.nouveaux` (plan 5b).
- Produces:
  - `EtatAtelier.LIBRES_APRES = 2`, `EtatAtelier.MAIN_OEUVRE = 6` ; champ `ventes` ; `commande.libre`, `commande.matieres` ;
  - `EtatAtelier:nouvelleRobeLibre(taille)` → `{ ok, commande }`, étape « carnet » ; refus « Les robes libres s'ouvrent après deux commandes livrées. », « Taille inconnue. » ;
  - `EtatAtelier:prixVente()` ; `vendre()` → `{ ok, prix, bilan, prestige, nouveaux }` ; `offrir(idCliente)` → `{ ok, cliente, bilan, amitie, prestige, nouveaux }` ; `livrer` d'une robe libre → refus « Une robe libre se vend ou s'offre. » ;
  - actions serveur et `Session:nouvelleRobeLibre(taille)`, `Session:vendre()`, `Session:offrir(idCliente)`.

- [ ] **Step 1: Écrire les tests**

Créer `tests/unitaires/50_robes_libres.luau` :

```lua
local EtatAtelier = U.module("EtatAtelier")
local Catalogue = U.module("Catalogue")
local Patron = U.module("Patron")
local Progression = U.module("Progression")
local Clientes = U.module("Clientes")
local Sauvegarde = U.module("Sauvegarde")

local CROQUIS = { corsage = "corsage_droit", manches = "manches_sans", col = "col_sans", jupe = "jupe_droite" }
local PLACES = {
	corsage_droit_devant = { x = 2.4, y = 2.1, angle = 0 },
	corsage_droit_dos = { x = 7.2, y = 2.1, angle = 0 },
	jupe_droite_devant = { x = 2.5, y = 7.2, angle = 0 },
	jupe_droite_dos = { x = 7.5, y = 7.2, angle = 0 },
}
-- Du carnet à la photo, dans un seul tissu : robe coupée, épinglée, cousue parfaitement, sans décoration
local function jusquALaPhoto(etat, tissu)
	local tissus = {}
	for id in pairs(PLACES) do
		tissus[id] = tissu
	end
	assert(etat:validerCroquis(CROQUIS, tissus).ok)
	assert(etat:acheter(tissu, 12).ok)
	assert(etat:commencerDecoupe().ok)
	for _, id in ipairs(etat:piecesDuCroquis()) do
		assert(etat:couper(id, PLACES[id]).ok)
	end
	for _, id in ipairs(etat:piecesDuCroquis()) do
		assert(etat:epingler(id).ok)
	end
	for _, id in ipairs(etat:piecesDuCroquis()) do
		local _, longueur = Patron.trajetCouture(id)
		assert(etat:rendreCouture(id, table.create(math.round(longueur / 0.1), 0), longueur).ok)
	end
	assert(etat:decorer({}).ok)
end

-- Ouverte après deux commandes livrées ; une taille standard, pas de cliente, pas d'exigence, droit au carnet
local e = EtatAtelier.nouveau(200)
e.livraisons = 1
local r = e:nouvelleRobeLibre("M")
U.verifier(not r.ok and r.erreur == "Les robes libres s'ouvrent après deux commandes livrées." and e.etape == "accueil", "robe libre fermée avant deux commandes livrées")
e.livraisons = 2
for _, mauvaise in ipairs({ "XL", 3, nil }) do
	U.verifier(not e:nouvelleRobeLibre(mauvaise).ok and e.etape == "accueil", "taille inconnue refusée : " .. tostring(mauvaise))
end
local argentAvant = e.argent
r = e:nouvelleRobeLibre("M")
U.verifier(r.ok and e.etape == "carnet" and e.commande.libre and e.commande.cliente == nil and #e.commande.exigences == 0, "robe libre : au carnet, sans cliente ni exigence")
U.verifier(e.commande.mesures.poitrine == Catalogue.TAILLES.M.poitrine and e.commande.acompte == nil and e.argent == argentAvant, "les mesures de sa taille ; pas d'acompte")

-- Une robe libre ne se livre pas ; elle se vend : (matières + décorations + main d'œuvre) × (0,5 + qualité)
jusquALaPhoto(e, "coton_blanc")
U.verifier(e.commande.matieres ~= nil and e.commande.matieres > 0, "le prix du tissu entamé est noté à la découpe (" .. tostring(e.commande.matieres) .. " po)")
r = e:livrer()
U.verifier(not r.ok and r.erreur == "Une robe libre se vend ou s'offre." and e.etape == "photo", "une robe libre ne se livre pas")
local qualite = e:bilan().qualite
local attendu = math.round((e.commande.matieres + 6 * 4) * (0.5 + qualite))
U.verifier(e:prixVente() == attendu, "prix de vente : (matières + main d'œuvre) × (0,5 + qualité) = " .. attendu)
e.prestige = 530
U.verifier(e:prixVente() == math.round((e.commande.matieres + 24) * (0.5 + qualite) * 1.42), "au prestige 8 : +42 %")
e.prestige = 0
local avant = e.argent
r = e:vendre()
U.verifier(r.ok and r.prix == attendu and e.argent == avant + attendu and e.ventes == 1 and e.etape == "accueil", "vendue : le prix dans la caisse")
U.verifier(r.prestige.gain == Progression.prestigeVente(attendu) and e.prestige == r.prestige.gain and #e.robes == 1, "prestige d'un quinzième du prix ; la robe en vitrine")

-- En toile de jute : gratuite, et pourtant vendue (la main d'œuvre)
e:nouvelleRobeLibre("S")
avant = e.argent
jusquALaPhoto(e, "toile_jute")
U.verifier(e.argent == avant and e.commande.matieres == 0, "toile de jute : rien à payer")
U.verifier(e:prixVente() == math.round(24 * (0.5 + e:bilan().qualite)) and e:prixVente() > 0, "robe de jute : vendue pour sa main d'œuvre")

-- Offrir : seulement à une cliente déjà venue ; l'amitié monte selon son style préféré, le prestige de 2
e.clientes.helene = { amitie = 0, vues = 0, derniere = 0 } -- une fiche, mais jamais venue
U.verifier(not e:offrir("helene").ok and not e:offrir("ines").ok and not e:offrir("personne").ok and not e:offrir(nil).ok and e.etape == "photo", "offrir à une cliente jamais venue ou inconnue : refusé")
e.clientes.colette = { amitie = 6, vues = 1, derniere = 1 }
local bilan = e:bilan()
local score = math.max(bilan.styles.romantique or 0, bilan.styles.mignon or 0)
local prestigeAvant = e.prestige
avant = e.argent
r = e:offrir("colette")
U.verifier(r.ok and r.amitie.gain == Progression.gainCadeau(score) and e.clientes.colette.amitie == 6 + r.amitie.gain, "offerte à Colette : l'amitié selon son style préféré (" .. score .. " points)")
U.verifier(r.prestige.gain == 2 and e.prestige == prestigeAvant + 2 and e.argent == avant and e.etape == "accueil" and #e.robes == 2, "cadeau : +2 de prestige, pas d'argent, la robe en vitrine")
U.verifier(r.amitie.niveau == 2 and r.amitie.niveauAvant == 1 and #r.nouveaux == 1 and r.nouveaux[1].id == "jupe_ample", "le cadeau fait passer Colette au niveau 2 : la jupe ample s'ouvre")

-- Vendre ou offrir hors d'une robe libre : refusé
local c = EtatAtelier.nouveau(200)
U.commander(c, Random.new(1))
jusquALaPhoto(c, "coton_blanc")
U.verifier(not c:vendre().ok and not c:offrir("colette").ok and c.etape == "photo", "une commande ne se vend ni ne s'offre")

-- Sauvegarde : la robe libre en cours et les ventes suivent ; une robe libre abîmée est abandonnée
local l = EtatAtelier.nouveau(200)
l.livraisons = 2
l:nouvelleRobeLibre("L")
local relue = Sauvegarde.versEtat(M.transmettre(Sauvegarde.depuisEtat(l)))
U.verifier(relue.etape == "carnet" and relue.commande.libre and relue.commande.taille == "L", "robe libre en cours : relue")
l.ventes = 3
U.verifier(Sauvegarde.versEtat(M.transmettre(Sauvegarde.depuisEtat(l))).ventes == 3, "robes vendues : sauvegardées")
for _, cas in ipairs({ { "exigences", { { type = "qualite", valeur = 0.5 } } }, { "cliente", "colette" }, { "libre", "oui" }, { "matieres", -5 } }) do
	local p = M.transmettre(Sauvegarde.depuisEtat(l))
	p.enCours.commande[cas[1]] = cas[2]
	U.verifier(Sauvegarde.versEtat(p).etape == "accueil", "robe libre abîmée (" .. cas[1] .. ") : abandonnée")
end
U.verifier(Clientes.get("colette") ~= nil, "(la cliente existe)")
```

- [ ] **Step 2: Lancer les tests, vérifier l'échec**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT|attempt|membre" | head -3`
Expected: échec : une ligne qui finit par `attempt to call missing method 'nouvelleRobeLibre' of table`

- [ ] **Step 3: Écrire le code**

Dans `src/shared/EtatAtelier.luau`, remplacer :

```lua
EtatAtelier.PIECES_ACOMPTE = 4 -- la base de l'acompte est celle de la robe la plus simple (quatre pièces)
```

par :

```lua
EtatAtelier.PIECES_ACOMPTE = 4 -- la base de l'acompte est celle de la robe la plus simple (quatre pièces)
EtatAtelier.LIBRES_APRES = 2 -- les robes libres s'ouvrent après deux commandes livrées
EtatAtelier.MAIN_OEUVRE = 6 -- pièces d'or par pièce posée, dans le prix de vente d'une robe libre
```

Dans `src/shared/EtatAtelier.luau`, remplacer :

```lua
		-- points de prestige, robes livrées, visites (numéro de la dernière, pour savoir qui revient)
		clientes = {},
		prestige = 0,
		livraisons = 0,
		visites = 0,
```

par :

```lua
		-- points de prestige, robes livrées, visites (numéro de la dernière, pour savoir qui revient), robes vendues
		clientes = {},
		prestige = 0,
		livraisons = 0,
		visites = 0,
		ventes = 0,
```

Dans `src/shared/EtatAtelier.luau`, remplacer :

```lua
"clientes", "prestige", "livraisons", "visites" }
```

par :

```lua
"clientes", "prestige", "livraisons", "visites", "ventes" }
```

Dans `src/shared/EtatAtelier.luau`, remplacer :

```lua
-- La clochette : une cliente vient (Clientes.prochaine) avec une commande tirée de ses goûts. On prend
-- d'abord ses mesures (étape « mesures ») ; une cliente déjà venue peut les reprendre.
```

par :

```lua
-- Une robe libre (prêt-à-porter) : ni cliente ni exigence ni acompte ; une taille standard, dont le mannequin
-- prend les mesures. On va droit au carnet ; à la photo, on la vend ou on l'offre. Ouverte après deux commandes
-- livrées.
function EtatAtelier:nouvelleRobeLibre(taille)
	if self.etape ~= "accueil" then
		return refus("Une commande est déjà en cours.")
	end
	if self.livraisons < EtatAtelier.LIBRES_APRES then
		return refus("Les robes libres s'ouvrent après deux commandes livrées.")
	end
	if type(taille) ~= "string" or not Catalogue.TAILLES[taille] then
		return refus("Taille inconnue.")
	end
	self.visites += 1 -- (un numéro pour la reconnaître d'une copie à l'autre)
	self.commande = { libre = true, taille = taille, mesures = table.clone(Catalogue.TAILLES[taille]), exigences = {}, numero = self.visites }
	self.argent = math.max(self.argent, EtatAtelier.FILET)
	self.croquis, self.tissus, self.coupees, self.coupons = nil, {}, {}, {}
	self.epinglees, self.coutures, self.accessoires = {}, {}, {}
	self.etape = "carnet"
	return { ok = true, commande = self.commande }
end

-- La clochette : une cliente vient (Clientes.prochaine) avec une commande tirée de ses goûts. On prend
-- d'abord ses mesures (étape « mesures ») ; une cliente déjà venue peut les reprendre.
```

Dans `src/shared/EtatAtelier.luau`, remplacer :

```lua
	if #self:piecesAPoser() == 0 then
		consommer(self)
		self.etape = "epinglage"
```

par :

```lua
	if #self:piecesAPoser() == 0 then
		if self.commande.libre then
			-- le prix des matières d'une robe libre : le tissu entamé de chaque rouleau
			local matieres = 0
			for idTissu, c in pairs(self.coupons) do
				matieres += EtatAtelier.prix(idTissu, c:longueurUtilisee())
			end
			self.commande.matieres = matieres
		end
		consommer(self)
		self.etape = "epinglage"
```

Dans `src/shared/EtatAtelier.luau`, remplacer :

```lua
	local recette = self:recette()
	local bilan = self:bilan()
	local reussie, ratees = Notation.verifierExigences(self.commande.exigences, bilan)
```

par :

```lua
	if self.commande.libre then
		return refus("Une robe libre se vend ou s'offre.")
	end
	local recette = self:recette()
	local bilan = self:bilan()
	local reussie, ratees = Notation.verifierExigences(self.commande.exigences, bilan)
```

Dans `src/shared/EtatAtelier.luau`, remplacer :

```lua
-- Après un refus : retoucher (retour aux décorations) ou abandonner (ni paie ni vitrine)
```

par :

```lua
-- Robes libres : le prestige et les amitiés avant la vente ou le cadeau (pour dire ce qui s'ouvre), le prestige
-- gagné, la robe gardée en vitrine
local function progres(self)
	local avant = { prestige = self.prestige, clientes = {} }
	for id, f in pairs(self.clientes) do
		avant.clientes[id] = { amitie = f.amitie }
	end
	return avant
end
local function gagnerPrestige(self, gain)
	local niveauAvant = Progression.niveauPrestige(self.prestige)
	self.prestige += gain
	return { gain = gain, points = self.prestige, niveau = Progression.niveauPrestige(self.prestige), niveauAvant = niveauAvant }
end
local function garderRobe(self, recette)
	table.insert(self.robes, 1, recette)
	for k = #self.robes, EtatAtelier.ROBES_GARDEES + 1, -1 do
		self.robes[k] = nil
	end
end

-- Prix de vente d'une robe libre : (matières + décorations + main d'œuvre) × (0,5 + qualité), plus le bonus de
-- prestige (6 % par niveau au-delà du premier)
function EtatAtelier:prixVente()
	local recette = self:recette()
	local base = (self.commande.matieres or 0) + EtatAtelier.prixDecorations(recette.pieces, self.accessoires) + EtatAtelier.MAIN_OEUVRE * #recette.pieces
	local bonus = Progression.bonusVente(Progression.niveauPrestige(self.prestige))
	return math.round(base * (0.5 + self:bilan().qualite) * (1 + bonus))
end

-- Vendre la robe libre : le prix, du prestige (prix / 15) ; elle part en vitrine
function EtatAtelier:vendre()
	if self.etape ~= "photo" or not self.commande.libre then
		return refus("Seule une robe libre se vend, une fois présentée.")
	end
	local avant = progres(self)
	local recette, bilan, prix = self:recette(), self:bilan(), self:prixVente()
	self.argent += prix
	self.ventes += 1
	local prestige = gagnerPrestige(self, Progression.prestigeVente(prix))
	garderRobe(self, recette)
	terminer(self)
	return { ok = true, prix = prix, bilan = bilan, prestige = prestige, nouveaux = Deblocages.nouveaux(avant, self) }
end

-- Offrir la robe libre à une cliente déjà venue : son amitié monte selon le score de son style préféré le plus
-- haut (+1 à +4), le prestige de 2 ; pas d'argent. La robe part en vitrine
function EtatAtelier:offrir(idCliente)
	if self.etape ~= "photo" or not self.commande.libre then
		return refus("Seule une robe libre s'offre, une fois présentée.")
	end
	local cliente = type(idCliente) == "string" and Clientes.get(idCliente)
	local fiche = cliente and self.clientes[cliente.id]
	if not fiche or fiche.vues == 0 then
		return refus("On n'offre une robe qu'à une cliente déjà venue.")
	end
	local avant = progres(self)
	local recette, bilan = self:recette(), self:bilan()
	local score = 0
	for _, style in ipairs(cliente.styles) do
		score = math.max(score, bilan.styles[style] or 0)
	end
	local amitieAvant = fiche.amitie
	fiche.amitie += Progression.gainCadeau(score)
	local gainAmitie = { cliente = cliente.id, gain = fiche.amitie - amitieAvant, points = fiche.amitie, niveau = Progression.niveauAmitie(fiche.amitie), niveauAvant = Progression.niveauAmitie(amitieAvant) }
	local prestige = gagnerPrestige(self, Progression.PRESTIGE_CADEAU)
	garderRobe(self, recette)
	terminer(self)
	return { ok = true, cliente = cliente.id, bilan = bilan, amitie = gainAmitie, prestige = prestige, nouveaux = Deblocages.nouveaux(avant, self) }
end

-- Après un refus : retoucher (retour aux décorations) ou abandonner (ni paie ni vitrine)
```

Dans `src/server/Sauvegarde.luau`, remplacer :

```lua
-- ajustement entre 50 et 100 %, acompte entier et raisonnable, 1 à 3 exigences lisibles
local function commandeLisible(c, etape)
	if type(c) ~= "table" or type(c.taille) ~= "string" or not Catalogue.TAILLES[c.taille] then
		return false
	end
```

par :

```lua
-- ajustement entre 50 et 100 %, acompte entier et raisonnable, 1 à 3 exigences lisibles. Une robe libre : ni
-- cliente ni exigence, mesures de sa taille, prix des matières raisonnable
local function commandeLisible(c, etape)
	if type(c) ~= "table" or type(c.taille) ~= "string" or not Catalogue.TAILLES[c.taille] then
		return false
	end
	if c.libre ~= nil then
		return c.libre == true and c.cliente == nil and etape ~= "mesures" and type(c.exigences) == "table" and next(c.exigences) == nil
			and mesuresLisibles(c.mesures) and (c.matieres == nil or (nombre(c.matieres, nil) and c.matieres >= 0 and c.matieres <= 100000))
	end
```

Dans `src/server/Sauvegarde.luau`, remplacer :

```lua
		visites = d.visites,
```

par :

```lua
		visites = d.visites,
		ventes = d.ventes,
```

Dans `src/server/Sauvegarde.luau`, remplacer :

```lua
	base.prestige, base.livraisons, base.visites = entier(partie.prestige), entier(partie.livraisons), entier(partie.visites)
```

par :

```lua
	base.prestige, base.livraisons, base.visites = entier(partie.prestige), entier(partie.livraisons), entier(partie.visites)
	base.ventes = entier(partie.ventes)
```

Dans `src/server/Commande.luau`, remplacer :

```lua
	livrer = function(a)
		return a.etat:livrer()
	end,
```

par :

```lua
	livrer = function(a)
		return a.etat:livrer()
	end,
	nouvelleRobeLibre = function(a, taille)
		return a.etat:nouvelleRobeLibre(taille)
	end,
	vendre = function(a)
		return a.etat:vendre()
	end,
	offrir = function(a, idCliente)
		return a.etat:offrir(idCliente)
	end,
```

Dans `src/client/Atelier/Session.luau`, remplacer :

```lua
function Session:livrer()
	return agir(self, "livrer")
end
```

par :

```lua
function Session:livrer()
	return agir(self, "livrer")
end
function Session:nouvelleRobeLibre(taille)
	return agir(self, "nouvelleRobeLibre", taille)
end
function Session:vendre()
	return agir(self, "vendre")
end
function Session:offrir(idCliente)
	return agir(self, "offrir", idCliente)
end
```

- [ ] **Step 4: Lancer les tests**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT"`
Expected:
```
Unitaires : 107371 vérifications
TOUT EST VERT : 584 vérifications
```

- [ ] **Step 5: Commit**

```bash
git add src/shared/EtatAtelier.luau src/server/Sauvegarde.luau src/server/Commande.luau src/client/Atelier/Session.luau tests/unitaires/50_robes_libres.luau
git commit -m "Robes libres : une taille, pas de cliente ; à la photo, la vendre ou l'offrir

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 3: L'interface des robes libres

**Files:**
- Modify: `src/client/Atelier/EcranAccueil.luau`, `EcranCarnet.luau`, `EcranPresentation.luau`, `Scene.luau`, `init.client.luau`
- Modify: `src/server/Commande.luau` (vitrine)
- Modify: `tests/scenario.luau`

**Interfaces:**
- Consumes: tout ce que produit la tâche 2.
- Produces: boutons `RobeLibre`, `RobeLibre_S/M/L` (cadre `ChoixTaille`) ; texte `Entete` du carnet ; à la photo, texte `PrixVente`, boutons `Vendre`, `Offrir`, cadre `ChoixCliente` (boutons `Offrir_<id>`, `FermerChoixCliente`) ; la vitrine suit `vendre` et `offrir`.

- [ ] **Step 1: Écrire les tests**

Dans `tests/scenario.luau`, remplacer :

```lua
remoteAtelier.OnServerInvoke = serveurLent
cliquer("Clochette")
```

par :

```lua
verifier(fenetre.Contenu:FindFirstChild("RobeLibre") == nil, "aucune commande livrée : pas encore de robe libre")
remoteAtelier.OnServerInvoke = serveurLent
cliquer("Clochette")
```

Dans `tests/scenario.luau`, remplacer :

```lua
-- Prestige 45 avant la livraison : elle fait passer au niveau 3 (les satins et la dentelle noire s'ouvrent)
serveur:atelier(joueur).etat.prestige = 45
```

par :

```lua
-- Prestige 45 avant la livraison : elle fait passer au niveau 3 (les satins et la dentelle noire s'ouvrent) ;
-- une livraison déjà faite : celle-ci est la deuxième, les robes libres s'ouvrent
serveur:atelier(joueur).etat.prestige = 45
serveur:atelier(joueur).etat.livraisons = 1
```

Dans `tests/scenario.luau`, remplacer :

```lua
M.avancer(ScenePoste.DUREE_ADIEU + 0.5)
verifier(laCliente.Parent == nil, "puis elle s'en va")
```

par :

```lua
M.avancer(ScenePoste.DUREE_ADIEU + 0.5)
verifier(laCliente.Parent == nil, "puis elle s'en va")

---------------------------------------------------------------------------
-- Robes libres (après deux commandes livrées) : une taille, pas de cliente ; à la photo, vendre ou offrir
---------------------------------------------------------------------------
do -- (les variables de cette partie restent dans ce bloc : Luau limite un bloc à 200 variables locales)
verifier(boutonNomme("RobeLibre") ~= nil, "deux commandes livrées : « Robe libre » à l'accueil")
cliquer("RobeLibre")
cliquer("RobeLibre_M")
verifier(titre() == "1. Carnet de croquis" and texte("Robe libre (taille M) : à ton idée.") ~= nil, "robe libre : droit au carnet, sans exigence")
verifier(scene:FindFirstChild("Cliente") == nil and serveur:atelier(joueur).etat.commande.libre, "robe libre : personne n'entre")
cliquer("Tissu_corsage_droit_devant")
verifier(boutonNomme("Tissu_toile_jute") ~= nil and texte("Gratuit · Décontracté") ~= nil, "la toile de jute est gratuite")
cliquer("FermerChoix")
-- La robe menée jusqu'à la photo sur le serveur (coupée, épinglée, cousue), sans repasser par tous les postes
local function robeLibreALaPhoto(tissu)
	local e = serveur:atelier(joueur).etat
	e.croquis = { corsage = "corsage_droit", manches = "manches_sans", col = "col_sans", jupe = "jupe_droite" }
	e.tissus = {}
	for _, id in ipairs(e:piecesDuCroquis()) do
		e.tissus[id] = tissu
		e.coupees[id] = { x = 0, y = 0, angle = 0 }
		e.epinglees[id] = true
		e.coutures[id] = 0.9
	end
	e.commande.matieres = if tissu == "toile_jute" then 0 else 10
	e.etape = "photo"
	requireModule(scriptClient.Session).courante:actualiser()
end
robeLibreALaPhoto("coton_blanc")
local prixLibre = serveur:atelier(joueur).etat:prixVente()
verifier(fenetre.Contenu.PrixVente.Text == ("Prix de vente : %d po"):format(prixLibre) and boutonNomme("Vendre").Text == ("Vendre (%d po)"):format(prixLibre), "à la photo : le prix de vente, « Vendre (" .. prixLibre .. " po) »")
verifier(fenetre.Contenu:FindFirstChild("Livrer") == nil, "une robe libre ne se livre pas")
cliquer("Offrir")
verifier(boutonNomme("Offrir_colette") ~= nil and fenetre.Contenu.ChoixCliente:FindFirstChild("Offrir_ines") == nil, "offrir : seulement aux clientes déjà venues")
cliquer("FermerChoixCliente")
verifier(not fenetre.Contenu.ChoixCliente.Visible, "annuler : le choix se ferme")
local avantVente = argent()
cliquer("Vendre")
cliquer("Vendre")
verifier(titre() == "Atelier de couture" and argent() == avantVente + prixLibre and texte(("Robe vendue ! +%d pièces d'or"):format(prixLibre)) ~= nil, "robe vendue : le prix dans la caisse, annoncé")
verifier(M.sonsJoues[#M.sonsJoues] == "Atelier_achat" and serveur:atelier(joueur).etat.ventes == 1, "vendue : la caisse sonne")
M.avancer(1)
verifier(maVitrine:GetAttribute("Recette") == requireModule(dossier.Recette).encoder(serveur:atelier(joueur).etat.robes[1]), "la robe vendue part en vitrine")
-- La suivante, en toile de jute, offerte à Colette
local amitieColette = serveur:atelier(joueur).etat.clientes.colette.amitie
cliquer("RobeLibre")
cliquer("RobeLibre_S")
verifier(texte("Robe libre (taille S) : à ton idée.") ~= nil, "une autre robe libre, taille S")
robeLibreALaPhoto("toile_jute")
cliquer("Offrir")
cliquer("Offrir_colette")
verifier(titre() == "Atelier de couture" and texte("Colette adore la robe que tu lui offres !") ~= nil and texte("Amitié de Colette : +") ~= nil, "offerte à Colette : l'accueil l'annonce")
verifier(serveur:atelier(joueur).etat.clientes.colette.amitie > amitieColette, "son amitié monte")
end
```

- [ ] **Step 2: Lancer les tests, vérifier l'échec**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT|attempt|membre" | head -3`
Expected: échec : une ligne qui finit par `ÉCHEC : un seul bouton « RobeLibre » visible (trouvé 0)`

- [ ] **Step 3: Écrire le code**

Dans `src/client/Atelier/EcranAccueil.luau`, remplacer :

```lua
-- l'amitié et le prestige gagnés, et ce qui vient de s'ouvrir. La jauge de prestige est sous la clochette.
```

par :

```lua
-- l'amitié et le prestige gagnés, et ce qui vient de s'ouvrir (ou la vente, ou le cadeau, d'une robe libre).
-- La jauge de prestige est sous la clochette ; « Robe libre » (après deux commandes livrées) à côté.
```

Dans `src/client/Atelier/EcranAccueil.luau`, remplacer :

```lua
local Deblocages = require(Couture:WaitForChild("Deblocages"))
```

par :

```lua
local Deblocages = require(Couture:WaitForChild("Deblocages"))
local EtatAtelier = require(Couture:WaitForChild("EtatAtelier"))
```

Dans `src/client/Atelier/EcranAccueil.luau`, remplacer :

```lua
	if derniere and derniere.action == "livrer" and derniere.reponse.reussie then
		local r = derniere.reponse
		local fiche = r.amitie and Clientes.get(r.amitie.cliente)
		annonce = ("%s est ravie ! +%d pièces d'or (qualité %d %%). Sa robe est en vitrine."):format(
			fiche and fiche.nom:match("^(%S+)") or "La cliente",
			r.verse or r.paie,
			math.floor(r.bilan.qualite * 100 + 0.5)
		)
		local suite = {}
		if r.acompte and r.acompte > 0 then
			table.insert(suite, ("Acompte de %d déjà reçu"):format(r.acompte))
		end
		table.insert(suite, ligneAmitie(r.amitie))
		if r.prestige then
```

par :

```lua
	local r = derniere and derniere.reponse
	local action = derniere and r.ok and derniere.action
	local suite = {}
	if action == "livrer" and r.reussie then
		local fiche = r.amitie and Clientes.get(r.amitie.cliente)
		annonce = ("%s est ravie ! +%d pièces d'or (qualité %d %%). Sa robe est en vitrine."):format(
			fiche and fiche.nom:match("^(%S+)") or "La cliente",
			r.verse or r.paie,
			math.floor(r.bilan.qualite * 100 + 0.5)
		)
		if r.acompte and r.acompte > 0 then
			table.insert(suite, ("Acompte de %d déjà reçu"):format(r.acompte))
		end
		table.insert(suite, ligneAmitie(r.amitie))
	elseif action == "vendre" then
		annonce = ("Robe vendue ! +%d pièces d'or (qualité %d %%). Elle part en vitrine."):format(r.prix, math.floor(r.bilan.qualite * 100 + 0.5))
	elseif action == "offrir" then
		local fiche = Clientes.get(r.cliente)
		annonce = ("%s adore la robe que tu lui offres ! Elle part en vitrine."):format(fiche and fiche.nom:match("^(%S+)") or "La cliente")
		table.insert(suite, ligneAmitie(r.amitie))
	end
	if annonce then
		if r.prestige then
```

Dans `src/client/Atelier/EcranAccueil.luau`, remplacer :

```lua
		if r.nouveaux and #r.nouveaux > 0 then
			annonce ..= "\nNouveau : " .. Deblocages.resume(r.nouveaux) .. "."
		end
	elseif derniere and derniere.action == "abandonner" then
```

par :

```lua
		if r.nouveaux and #r.nouveaux > 0 then
			annonce ..= "\nNouveau : " .. Deblocages.resume(r.nouveaux) .. "."
		end
	elseif action == "abandonner" then
```

Dans `src/client/Atelier/EcranAccueil.luau`, remplacer :

```lua
	}, sonner)
	-- La jauge de prestige : « Prestige 3 — 62 / 100 »
	local etat = ctx.session.etat
```

par :

```lua
	}, sonner)
	-- Robe libre (après deux commandes livrées) : on choisit une taille, et l'on va droit au carnet
	local etat = ctx.session.etat
	if etat.livraisons >= EtatAtelier.LIBRES_APRES then
		local libre
		libre = UiKit.boutonDoux({ Name = "RobeLibre", Text = "Robe libre", Position = UDim2.fromOffset(276, 110 + decalage), Size = UDim2.fromOffset(200, 50), Parent = ctx.contenu }, function()
			libre.Visible = false
			local choix = UiKit.creer("Frame", { Name = "ChoixTaille", BackgroundTransparency = 1, Position = UDim2.fromOffset(276, 110 + decalage), Size = UDim2.fromOffset(300, 50), Parent = ctx.contenu })
			UiKit.texte({ Text = "Taille :", Font = Enum.Font.GothamBold, Position = UDim2.fromOffset(0, 14), Size = UDim2.fromOffset(70, 22), Parent = choix })
			for k, taille in ipairs({ "S", "M", "L" }) do
				UiKit.bouton({ Name = "RobeLibre_" .. taille, Text = taille, Position = UDim2.fromOffset(70 + (k - 1) * 70, 0), Size = UDim2.fromOffset(60, 50), Parent = choix }, function()
					local rl = ctx.session:nouvelleRobeLibre(taille)
					if not rl.ok then
						ctx.refus(rl)
					end
				end)
			end
		end)
	end
	-- La jauge de prestige : « Prestige 3 — 62 / 100 »
```

Dans `src/client/Atelier/EcranCarnet.luau`, remplacer :

```lua
	local fiche = etat.commande.cliente and Clientes.get(etat.commande.cliente)
	local qui = fiche and fiche.nom:match("^(%S+)") or "La cliente"
	UiKit.texte({ Text = ("%s (taille %s) veut :"):format(qui, etat.commande.taille), Font = Enum.Font.GothamBold, Position = UDim2.fromOffset(12, 8), Size = UDim2.new(1, -24, 0, 22), Parent = droite })
```

par :

```lua
	local fiche = etat.commande.cliente and Clientes.get(etat.commande.cliente)
	local qui = fiche and fiche.nom:match("^(%S+)") or "La cliente"
	local entete = if etat.commande.libre then ("Robe libre (taille %s) : à ton idée."):format(etat.commande.taille) else ("%s (taille %s) veut :"):format(qui, etat.commande.taille)
	UiKit.texte({ Name = "Entete", Text = entete, Font = Enum.Font.GothamBold, Position = UDim2.fromOffset(12, 8), Size = UDim2.new(1, -24, 0, 22), Parent = droite })
```

Dans `src/client/Atelier/EcranCarnet.luau`, remplacer :

```lua
						UiKit.texte({ Text = ("%d po/m · %s"):format(t.prix, table.concat(etiquettes, ", ")), TextSize = 14,
```

par :

```lua
						UiKit.texte({ Text = (if t.prix == 0 then "Gratuit" else ("%d po/m"):format(t.prix)) .. " · " .. table.concat(etiquettes, ", "), TextSize = 14,
```

Dans `src/client/Atelier/EcranPresentation.luau`, remplacer :

```lua
local Catalogue = require(Couture:WaitForChild("Catalogue"))
local Sons = require(script.Parent:WaitForChild("Sons"))
```

par :

```lua
local Catalogue = require(Couture:WaitForChild("Catalogue"))
local Clientes = require(Couture:WaitForChild("Clientes"))
local Progression = require(Couture:WaitForChild("Progression"))
local Sons = require(script.Parent:WaitForChild("Sons"))
```

Dans `src/client/Atelier/EcranPresentation.luau`, remplacer :

```lua
	UiKit.texte({ Text = "La cliente examine ta robe.", TextSize = 16, Size = UDim2.new(1, 0, 0, 24), Parent = contenu })
```

par :

```lua
	local libre = etat.commande.libre
	UiKit.texte({ Text = if libre then "Ta robe libre est prête." else "La cliente examine ta robe.", TextSize = 16, Size = UDim2.new(1, 0, 0, 24), Parent = contenu })
```

Dans `src/client/Atelier/EcranPresentation.luau`, remplacer :

```lua
	UiKit.texte({ Text = "Elle voulait :", TextSize = 14, TextColor3 = C.texteDoux, Position = UDim2.fromOffset(0, 58), Size = UDim2.new(1, 0, 0, 20), Parent = contenu })
```

par :

```lua
	if libre then
		UiKit.texte({ Name = "PrixVente", Text = ("Prix de vente : %d po"):format(etat:prixVente()), Font = Enum.Font.GothamBold, TextSize = 16, Position = UDim2.fromOffset(0, 58), Size = UDim2.new(1, 0, 0, 22), Parent = contenu })
	else
		UiKit.texte({ Text = "Elle voulait :", TextSize = 14, TextColor3 = C.texteDoux, Position = UDim2.fromOffset(0, 58), Size = UDim2.new(1, 0, 0, 20), Parent = contenu })
	end
```

Dans `src/client/Atelier/EcranPresentation.luau`, remplacer :

```lua
	-- Livrer met fin à la commande : loin de « Prendre la photo », et confirmé par un second appui
	UiKit.boutonConfirme({ Name = "Livrer", Text = "Livrer la robe", Position = UDim2.fromOffset(0, 312), Size = UDim2.new(1, -6, 0, 44), Parent = contenu }, function()
		local r = session:livrer()
		if not r.ok then
			ctx.refus(r)
		end
	end, true)
```

par :

```lua
	-- Livrer met fin à la commande : loin de « Prendre la photo », et confirmé par un second appui. Une robe
	-- libre se vend (confirmé aussi) ou s'offre à une cliente déjà venue (choisie dans une liste)
	if libre then
		UiKit.boutonConfirme({ Name = "Vendre", Text = ("Vendre (%d po)"):format(etat:prixVente()), Position = UDim2.fromOffset(0, 312), Size = UDim2.new(0.5, -6, 0, 44), Parent = contenu }, function()
			local r = session:vendre()
			if not r.ok then
				ctx.refus(r)
			end
		end, true)
		local choix = UiKit.arrondir(UiKit.creer("TextButton", { Name = "ChoixCliente", Text = "", AutoButtonColor = false, Visible = false, BackgroundColor3 = C.panneau, Size = UDim2.new(1, 0, 1, 0), ZIndex = 20, Parent = contenu }), 10)
		UiKit.texte({ Text = "Offrir la robe à :", Font = Enum.Font.GothamBold, Size = UDim2.new(1, -110, 0, 34), ZIndex = 21, Parent = choix })
		UiKit.boutonDoux({ Name = "FermerChoixCliente", Text = "Annuler", TextSize = 14, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -6, 0, 0), Size = UDim2.fromOffset(100, 34), ZIndex = 21, Parent = choix }, function()
			choix.Visible = false
		end)
		local n = 0
		for _, c in ipairs(Clientes.LISTE) do
			local fiche = etat.clientes[c.id]
			if fiche and fiche.vues > 0 then
				local score = 0
				for _, style in ipairs(c.styles) do
					score = math.max(score, bilan.styles[style] or 0)
				end
				UiKit.boutonDoux({
					Name = "Offrir_" .. c.id,
					Text = ("%s · amitié +%d"):format(c.nom, Progression.gainCadeau(score)),
					TextSize = 14,
					Position = UDim2.fromOffset(0, 42 + n * 44),
					Size = UDim2.new(1, -6, 0, 38),
					ZIndex = 21,
					Parent = choix,
				}, function()
					local r = session:offrir(c.id)
					if not r.ok then
						choix.Visible = false
						ctx.refus(r)
					end
				end)
				n += 1
			end
		end
		UiKit.boutonDoux({ Name = "Offrir", Text = "Offrir à…", Position = UDim2.new(0.5, 0, 0, 312), Size = UDim2.new(0.5, -6, 0, 44), Parent = contenu }, function()
			if n == 0 then
				ctx.message("Aucune cliente n'est encore venue.", C.texteDoux)
				return
			end
			choix.Visible = true
		end)
	else
		UiKit.boutonConfirme({ Name = "Livrer", Text = "Livrer la robe", Position = UDim2.fromOffset(0, 312), Size = UDim2.new(1, -6, 0, 44), Parent = contenu }, function()
			local r = session:livrer()
			if not r.ok then
				ctx.refus(r)
			end
		end, true)
	end
```

Dans `src/client/Atelier/Scene.luau`, remplacer :

```lua
	local commande = etat.commande
	-- La commande est reconnue à son numéro
```

par :

```lua
	local commande = etat.commande
	if commande and commande.libre then
		commande = nil -- une robe libre : pas de cliente
	end
	-- La commande est reconnue à son numéro
```

Dans `src/client/Atelier/init.client.luau`, remplacer :

```lua
local SONS_ACTIONS = { nouvelleCommande = "clochette", acheter = "achat", couper = "couper", epingler = "epingler", abandonner = "echec" }
```

par :

```lua
local SONS_ACTIONS = { nouvelleCommande = "clochette", acheter = "achat", couper = "couper", epingler = "epingler", abandonner = "echec", vendre = "achat", offrir = "reussite" }
```

Dans `src/server/Commande.luau`, remplacer :

```lua
		elseif action == "livrer" and reponse.reussie then
			self:exposer(joueur) -- la robe livrée part en vitrine
```

par :

```lua
		elseif (action == "livrer" and reponse.reussie) or action == "vendre" or action == "offrir" then
			self:exposer(joueur) -- la robe livrée (ou vendue, ou offerte) part en vitrine
```

- [ ] **Step 4: Lancer les tests**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT"`
Expected:
```
Unitaires : 107371 vérifications
TOUT EST VERT : 615 vérifications
```

- [ ] **Step 5: Commit**

```bash
git add src/client/Atelier/EcranAccueil.luau src/client/Atelier/EcranCarnet.luau src/client/Atelier/EcranPresentation.luau src/client/Atelier/Scene.luau src/client/Atelier/init.client.luau src/server/Commande.luau tests/scenario.luau
git commit -m "Robes libres à l'écran : taille à l'accueil, prix de vente, vendre ou offrir à la photo

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 4: L'équilibrage avec les robes libres

La simulation (vingt parties) passe à une robe libre de jute, vendue, toutes les quatre robes, sur 90 robes ; les cibles « prestige 5 » et « tout ouvert » se jugent en médiane, et la cible « tout ouvert » de la spec est amendée (voir les décisions). Test de caractérisation : il passe dès qu'il est écrit ; la préparation a vérifié qu'il échoue quand on dérègle l'équilibrage (variantes ci-dessus).

**Files:**
- Modify: `tests/unitaires/48_equilibrage.luau`
- Modify: `docs/superpowers/specs/2026-09-29-clientes-progression-design.md` (§1 critère 6, §10)

**Interfaces:**
- Consumes: `EtatAtelier:nouvelleRobeLibre`, `vendre`, `LIBRES_APRES` (tâche 2).
- Produces: la ligne « Équilibrage : … » (commandes livrées, robes libres vendues).

- [ ] **Step 1: Modifier la simulation et la spec**

Dans `tests/unitaires/48_equilibrage.luau`, remplacer :

```lua
-- Équilibrage (spec §10) : un joueur moyen simulé enchaîne les commandes avec les vraies règles de l'atelier.
-- À chaque commande : mesures justes, la robe la moins chère qui la remplit avec ce qui est ouvert (un seul
-- tissu, l'accessoire demandé), qualité 0,8 ; une robe refusée (qualité demandée trop haute) est abandonnée.
```

par :

```lua
-- Équilibrage (spec §10) : un joueur moyen simulé enchaîne les robes avec les vraies règles de l'atelier.
-- À chaque commande : mesures justes, la robe la moins chère qui la remplit avec ce qui est ouvert (un seul
-- tissu, l'accessoire demandé), qualité 0,8 ; une robe refusée (qualité demandée trop haute) est abandonnée.
-- Une robe sur quatre (dès que les robes libres sont ouvertes) : une robe libre en toile de jute, vendue.
```

Dans `tests/unitaires/48_equilibrage.luau`, remplacer :

```lua
local ROBES = 60
```

par :

```lua
local ROBES = 90
```

Dans `tests/unitaires/48_equilibrage.luau`, remplacer :

```lua
local plusPauvre, livrees = math.huge, 0
for n = 1, ROBES do
	assert(e:nouvelleCommande(rng).ok)
```

par :

```lua
local plusPauvre, livrees, commandes, vendues = math.huge, 0, 0, 0
local JUTE = { corsage = "corsage_droit", manches = "manches_sans", col = "col_sans", jupe = "jupe_droite" }
for n = 1, ROBES do
	if n % 4 == 0 and e.livraisons >= EtatAtelier.LIBRES_APRES then
		assert(e:nouvelleRobeLibre("M").ok)
		local tissus = {}
		for _, id in ipairs(Patron.piecesDuCroquis(JUTE)) do
			tissus[id] = "toile_jute"
			e.coupees[id] = { x = 0, y = 0, angle = 0 }
			e.epinglees[id] = true
			e.coutures[id] = QUALITE
		end
		assert(e:validerCroquis(JUTE, tissus).ok)
		e.etape = "decorations"
		assert(e:decorer({}).ok)
		assert(e:vendre().ok)
		vendues += 1
	else
	commandes += 1
	assert(e:nouvelleCommande(rng).ok)
```

Dans `tests/unitaires/48_equilibrage.luau`, remplacer :

```lua
	if reussie then
		livrees += 1
	else
		e.etape = "refus"
		assert(e:abandonner().ok)
	end
	plusPauvre
```

par :

```lua
	if reussie then
		livrees += 1
	else
		e.etape = "refus"
		assert(e:abandonner().ok)
	end
	end
	plusPauvre
```

Dans `tests/unitaires/48_equilibrage.luau`, remplacer :

```lua
toutOuvert = toutOuvertA or math.huge, plusPauvre = plusPauvre, livrees = livrees }
```

par :

```lua
toutOuvert = toutOuvertA or math.huge, plusPauvre = plusPauvre, livrees = livrees, commandes = commandes, vendues = vendues }
```

Dans `tests/unitaires/48_equilibrage.luau`, supprimer la ligne :

```lua
local livrees = serie("livrees")
```

Dans `tests/unitaires/48_equilibrage.luau`, remplacer :

```lua
local bilan = ("%d parties de %d robes : prestige 2
```

par :

```lua
local bilan = ("%d parties de %d robes, une robe libre de jute vendue sur quatre : prestige 2
```

Dans `tests/unitaires/48_equilibrage.luau`, remplacer :

```lua
U.verifier(medianeTout >= 30 and medianeTout <= 50, "tout le catalogue ouvert entre la 30e et la 50e robe, en médiane (" .. bilan .. ")")
```

par :

```lua
U.verifier(medianeTout >= 50 and medianeTout <= 80, "tout le catalogue ouvert entre la 50e et la 80e robe, en médiane (" .. bilan .. ")")
```

Dans `tests/unitaires/48_equilibrage.luau`, remplacer :

```lua
U.verifier(livrees[1] >= ROBES * 0.7, "un joueur moyen livre la plupart de ses commandes, dans chaque partie (" .. bilan .. ")")
```

par :

```lua
local livreesEtVendues = true
for _, p in ipairs(parties) do
	livreesEtVendues = livreesEtVendues and p.livrees >= p.commandes * 0.7 and p.vendues >= ROBES / 4 - 1
end
U.verifier(livreesEtVendues, "un joueur moyen livre la plupart de ses commandes, et vend ses robes libres, dans chaque partie (" .. bilan .. ")")
```

Dans `docs/superpowers/specs/2026-09-29-clientes-progression-design.md`, remplacer :

```markdown
6. Équilibrage vérifié par simulation : un joueur moyen (qualité 0,8) atteint le prestige 2 en 3 robes, le 5 en
   15 environ, et tout est ouvert vers 40 robes (4 à 5 heures).
```

par :

```markdown
6. Équilibrage vérifié par simulation : un joueur moyen (qualité 0,8) atteint le prestige 2 en 3 robes, le 5 en
   15 à 20, et tout est ouvert vers 60 robes (une robe libre sur quatre ; les cadeaux et le courrier permettent
   d'aller plus vite). Amendé au plan 5c : la cible de 40 robes supposait trop peu de robes libres.
```

Dans `docs/superpowers/specs/2026-09-29-clientes-progression-design.md`, remplacer :

```markdown
- **Équilibrage** : un joueur simulé (qualité 0,8, tissus les moins chers qui satisfont la commande) enchaîne 40 robes
  (commandes, et une robe libre de toile de jute vendue toutes les 4) : prestige 2 en 3 robes au plus, 5 entre
  12 et 20 robes, tout ouvert entre 30 et 50 ; l'argent ne descend jamais sous le prix d'une robe simple.
```

par :

```markdown
- **Équilibrage** : un joueur simulé (qualité 0,8, tissus les moins chers qui satisfont la commande) enchaîne 90 robes
  (commandes, et une robe libre de toile de jute vendue toutes les 4), sur vingt parties : prestige 2 en 3 robes au
  plus, 5 entre 12 et 20 robes, tout ouvert entre 50 et 80 en médiane (amendé au plan 5c) ; l'argent ne descend
  jamais sous le prix d'une robe simple.
```

Dans `tests/unitaires/48_equilibrage.luau`, remplacer :

```lua
U.verifier(p5[1] >= 12 and p5[#p5] <= 20, "prestige 5 entre la 12e et la 20e robe, dans chaque partie (" .. bilan .. ")")
```

par :

```lua
U.verifier(medianeP5 >= 12 and medianeP5 <= 20 and p5[#p5] <= 25, "prestige 5 entre la 12e et la 20e robe en médiane, à la 25e au plus tard (" .. bilan .. ")")
```

Dans `docs/superpowers/specs/2026-09-29-clientes-progression-design.md`, remplacer :

```markdown
plus, 5 entre 12 et 20 robes, tout ouvert entre 50 et 80 en médiane (amendé au plan 5c) ; l'argent ne descend
```

par :

```markdown
plus, 5 entre 12 et 20 robes en médiane, tout ouvert entre 50 et 80 en médiane (amendé au plan 5c) ; l'argent ne descend
```

- [ ] **Step 2: Lancer les tests**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Équilibrage|Unitaires|ÉCHEC|TOUT"`
Expected:
```
Équilibrage : 20 parties de 90 robes, une robe libre de jute vendue sur quatre : prestige 2 à la robe 3 au plus tard ; 5 de la 17 à la 22 (médiane 19) ; tout ouvert de la 51 à la 77 (médiane 61) ; au plus bas 241 po
Unitaires : 107371 vérifications
TOUT EST VERT : 615 vérifications
```

- [ ] **Step 3: Commit**

```bash
git add tests/unitaires/48_equilibrage.luau docs/superpowers/specs/2026-09-29-clientes-progression-design.md
git commit -m "Équilibrage avec une robe libre sur quatre ; cible « tout ouvert » amendée (50 à 80 robes)

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 5: Vérification dans Studio et README

**Files:**
- Modify: `README.md`
- Modify: `AtelierCouture.rbxl` (régénéré)

**Interfaces:**
- Consumes: tout ce qui précède.
- Produces: le plan 5c terminé.

- [ ] **Step 1: En Play, par le connecteur MCP**

Construire le lieu du dépôt dans un dossier temporaire (`C:/dev/jeux/roblox-maker/rojo.exe build -o <dossier temporaire>/Plan5cDepot.rbxl`), l'ouvrir dans Studio, lancer Play et attendre 4 s. Puis :

1. Côté client (`execute_luau`), chercher le bouton `RobeLibre` de l'accueil.
2. Appuyer sur E ; régler les rubans aux vraies mesures de Colette (glisser les poignées jusqu'au bord de la silhouette) et valider ; au carnet, cliquer sur « Tissu… » de la première pièce et lire le texte de la carte `Tissu_toile_jute`.
3. Relever les alertes (`get_console_output`).

Expected :
- au lancement (aucune commande livrée) : pas de bouton `RobeLibre` ;
- la carte de la toile de jute : « Gratuit · Décontracté » ;
- aucune alerte de notre code (« Lieu non publié » et les messages internes de Roblox mis à part).

La vente et le cadeau, qui demandent deux commandes livrées, sont joués par le scénario ; les modules du jeu ne sont pas accessibles depuis la barre de commande de Studio.

Arrêter Play et fermer cette fenêtre de Studio (sans enregistrer).

- [ ] **Step 2: À faire par le commanditaire**

- créer une robe libre en toile de jute jusqu'à la photo, la vendre, puis en offrir une autre ;
- dire si les prix de vente et le rythme de l'équilibrage paraissent justes.

Les noter dans le message de fin, sans bloquer le plan.

- [ ] **Step 3: Mettre à jour le README**

Dans `README.md`, remplacer :

```markdown
## État actuel (sous-projet 2 en cours : plans 5a et 5b, les clientes, le prestige et les déblocages)
```

par :

```markdown
## État actuel (sous-projet 2 en cours : plans 5a à 5c, les clientes, le prestige, les déblocages et les robes libres)
```

Dans `README.md`, remplacer :

```markdown
2. **Carnet de croquis** : corsage, manches, col et jupe au choix ; un tissu par pièce (24 tissus, filtre par style).
```

par :

```markdown
2. **Carnet de croquis** : corsage, manches, col et jupe au choix ; un tissu par pièce (25 tissus, filtre par style,
   dont la toile de jute, gratuite).
```

Dans `README.md`, remplacer :

```markdown
   **Équilibrage** (simulé par les tests, sur vingt parties) : un joueur moyen (qualité 0,8) atteint le
   prestige 2 à la 3e robe au plus tard, le 5 vers la 16e, et tout est ouvert vers la 46e (médianes).
9. La suite : robes libres à vendre ou à offrir (plan 5c), courrier et carnet d'adresses (plan 5d).
```

par :

```markdown
   **Robes libres** (après deux commandes livrées) : « Robe libre » à l'accueil, une taille (S, M, L), et l'on
   va droit au carnet, sans cliente ni exigence. À la photo : « Vendre » (prix = (matières + décorations +
   6 po par pièce) × (0,5 + qualité), +6 % par niveau de prestige au-delà du premier ; du prestige, un quinzième
   du prix) ou « Offrir à… » une cliente déjà venue (+1 à +4 d'amitié selon le score de son style préféré,
   +2 de prestige). La robe part en vitrine.
   **Équilibrage** (simulé par les tests, sur vingt parties) : un joueur moyen (qualité 0,8, une robe libre de
   jute vendue sur quatre robes) atteint le prestige 2 à la 3e robe au plus tard, le 5 vers la 19e, et tout est
   ouvert vers la 61e (médianes).
9. La suite : courrier et carnet d'adresses (plan 5d).
```

- [ ] **Step 4: Tests, lieu régénéré, commit**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT"`
Expected:
```
Unitaires : 107371 vérifications
TOUT EST VERT : 615 vérifications
```

```bash
C:/dev/jeux/roblox-maker/rojo.exe build -o AtelierCouture.rbxl
git add README.md AtelierCouture.rbxl
git commit -m "Plan 5c terminé : robes libres, vente, cadeau, toile de jute

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```
