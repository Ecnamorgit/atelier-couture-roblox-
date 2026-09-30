# Aiguille & Dentelle — Plan 21 : les étiquettes, données

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Donner aux robes seize étiquettes chiffrées (six styles, trois occasions, sept traits calculés) et une matière dominante, que la cliente sait juger, que le carnet prévoit, que les commandes savent rendre réalisables et que la sauvegarde garde.

**Architecture:** Un module partagé `Etiquettes` calcule occasions et traits d'une robe, les décompose par variante et par tissu (pour les commandes et le carnet) et donne la matière dominante ; `Catalogue` porte les données (occasions des variantes et des matières, chaleur des matières, noms). `Notation.bilan`, `verifierExigences`, `fourchette` et `prevision` prennent les nouveaux types d'exigence ; `Commandes.realisable` est réécrite famille par famille ; `Sauvegarde` et `UiKit.exigence` les acceptent. Aucune commande ne les demande encore (plan 22).

**Tech Stack:** Luau, Rojo 7.7.0-rc.1, simulation Luau 0.650 (`tests/lancer.sh`), Roblox Studio via le connecteur MCP Studio.

**Spec:** `docs/superpowers/specs/2026-09-30-robes-gouts-design.md` (section 3, « Des goûts plus fins : seize étiquettes » ; plan 21 de la section 6).

## Décisions de ce plan

- **Occasions** (Journée, Soirée, Travail) : elles s'additionnent comme les styles, points des variantes (K 1, champ `occasion` de chaque variante) et de la matière (K 2, au prorata de la surface ; champ `occasion` de `Catalogue.MATIERES`). Tout ouvert, chacune atteint 68 au plus ; les décorations n'en portent pas.
- **Légère / Chaude** : indice de chaleur dans [-1, 1] = 0,6 × chaleur de la matière (de -0,9 pour l'organza à 0,9 pour la laine) + 0,25 × (2 × manches − 1) + 0,15 × (2 × longueur − 1) ; manches = hauteur de la manche / 5,6 dm, longueur = (bas de la jupe − 6) / 3 bornée à [0, 1] (le volant descend à 6,6 dm). Chaude = 100 × l'indice positif, Légère = 100 × son opposé.
- **Sobre / Travaillée** : indice de richesse = (poids − 4) / 4 + décorations / 8 − 1, chaque terme borné à [0, 1] (la spec disait « poids et décorations » sans chiffres : une robe simple pèse 4, la plus riche d'aujourd'hui 8 ; huit décorations suffisent). Un objet compte 1 décoration, une garniture 1 pour 5 dm, au prorata (comme ses points de style).
- **Unie / Fleurie / À motifs** : la part de la surface dans un tissu uni, fleuri, ou à un autre motif, × 100.
- **Matière dominante** : comme la teinte (surfaces additionnées, à égalité la première pièce).
- **Témoin d'une commande** : toujours une robe simple (un seul tissu, l'accessoire imposé) ; pour Travaillée, juste assez d'un même objet ouvert, le premier du catalogue qui garde les autres exigences (les objets ajoutés comptent dans les styles). Le témoin porte alors `ajout = { id, nombre }`.
- **Recherche par famille** : corsage, manches, col, jupe, puis le tissu ; chaque exigence chiffrée borne une somme de points, et une branche est abandonnée dès que la meilleure suite possible ne la tient plus. Elle trouve la même robe que l'essai de chaque croquis dans l'ordre (vérifié contre le calcul complet, anciens et nouveaux types).
- **Textes** : « Pour la soirée : au moins 40 », « Robe légère : au moins 40 », « Matière dominante : crêpe » ; le chiffre actuel vient de `bilan.scores` (les seize étiquettes ensemble).
- **Coût** : la recherche répond en 0,1 à 0,3 ms dans Studio (mesuré pendant la préparation, tout ouvert, jeux possibles ou non) ; la référence complète de `71_commandes_etiquettes` ajoute une vingtaine de secondes à la suite des tests.
- **Vérifié pendant la préparation** : le plan a été joué entièrement sur un brouillon tiré de `main` ; treize variantes du brouillon (chaleur, longueur, décorations, égalité, fourchette, jugement, élagage, témoin, filtres des tissus, sauvegarde, texte) échouent sur la vérification qui les garde.

## Global Constraints

- **Dépôt** : `C:\dev\jeux\atelier-couture`, branche `etiquettes-donnees`, créée depuis `main` (où les plans 19 et 20 sont fusionnés). Selon les règles du commanditaire : la branche testée et relue est fusionnée dans `main` et poussée sur GitHub.
- **Rojo** : `C:/dev/jeux/roblox-maker/rojo.exe`.
- **Contenu original** : aucun nom, texte, image ni son de *Dressmaker*.
- **Contraintes des plans précédents toujours valables** : fins de ligne LF, commits en français terminés par `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`, textes d'au moins 14 px (et aucun texte laissé à « Label »), le serveur fait foi.

## Review Focus

- **Une commande ancienne (styles seulement).** Attendu : même réponse et même témoin qu'avant. Test : `54_commandes_rapides` (mille jeux, inchangé) et `71_commandes_etiquettes`.
- **Travaillée avec un « au plus » de style.** Attendu : les objets ajoutés au témoin comptent dans les styles ; aucun témoin ne dépasse le plafond. Test : `71_commandes_etiquettes` (le témoin cousu, jugé par `Notation.bilan`).
- **Deux matières à surface égale.** Attendu : la matière de la première pièce. Test : `70_etiquettes`.
- **Au carnet, une décoration imposée.** Attendu : elle compte pour Sobre (la fourchette ne promet pas une robe plus sobre qu'elle ne peut l'être). Test : `70_etiquettes`.
- **Une sauvegarde avec une étiquette inconnue.** Attendu : la commande est abandonnée au chargement, le reste gardé. Test : `30_sauvegarde`.

---

### Task 1: Les étiquettes : données et calcul

**Files:**
- Create: `src/shared/Etiquettes.luau`, `tests/unitaires/70_etiquettes.luau`
- Modify: `src/shared/Catalogue.luau`, `src/shared/Notation.luau`

**Interfaces:**
- Consumes: `Catalogue.Variantes`, `Catalogue.Tissus`, `Catalogue.MATIERES`, `Patron.aire`, `Patron.piecesDuCroquis`, `Polygone.boite` (existants).
- Produces: `Catalogue.OCCASIONS`, `NOMS_OCCASIONS`, `TRAITS`, `NOMS_TRAITS` ; `occasion` de chaque variante ; `nom`, `occasion`, `chaleur` de chaque matière. `Etiquettes.variante(id)` → `{ occasions, chaleur, poids }` ; `Etiquettes.tissu(id)` → `{ occasions, chaleur, motif }` ; `Etiquettes.traitsIndice(i)` → positif, négatif ; `Etiquettes.richesse(poids, decorations)` ; `Etiquettes.decorations(accessoires)` ; `Etiquettes.calculer(entree)` → `{ occasions, traits }` ; `Etiquettes.matiereDominante(pieces)` ; `Etiquettes.fourchette(croquis, choix, decorationsImposees, tissusOuverts)` ; `Etiquettes.MOTIFS`, `Etiquettes.DECORATIONS_PLEINES` (8). `Notation.bilan` → aussi `occasions`, `traits`, `scores`, `matiere` ; `Notation.fourchette` → aussi `[occasion ou trait] = { min, max }` ; exigences `{ type = "occasion", occasion, valeur }`, `{ type = "trait", trait, valeur }`, `{ type = "matiere", matiere }`.

- [ ] **Step 1: Écrire les tests**

Créer `tests/unitaires/70_etiquettes.luau` :

```lua
-- Sous-projet 7 : seize étiquettes. Aux six styles s'ajoutent trois occasions (points des variantes et des matières)
-- et sept traits calculés d'après la robe : Légère / Chaude (matière, manches, longueur), Sobre / Travaillée (poids des
-- pièces, décorations), Unie / Fleurie / À motifs (surface par motif) ; et la matière dominante.
local Catalogue = U.module("Catalogue")
local Etiquettes = U.module("Etiquettes")
local Notation = U.module("Notation")
local Patron = U.module("Patron")

---------------------------------------------------------------------------
-- Données : chaque variante et chaque matière ont leurs occasions ; chaque matière, un nom et une chaleur
---------------------------------------------------------------------------
local fautes = {}
local function occasionsLisibles(t)
	if type(t) ~= "table" then
		return false
	end
	for o, pts in pairs(t) do
		if not table.find(Catalogue.OCCASIONS, o) or type(pts) ~= "number" or pts < 0 then
			return false
		end
	end
	return true
end
for _, v in ipairs(Catalogue.Variantes) do
	if not occasionsLisibles(v.occasion) then
		table.insert(fautes, v.id)
	end
end
for _, t in ipairs(Catalogue.Tissus) do
	local m = Catalogue.MATIERES[t.matiere]
	if not occasionsLisibles(m.occasion) or type(m.nom) ~= "string" or type(m.chaleur) ~= "number" or math.abs(m.chaleur) > 1 then
		table.insert(fautes, t.matiere)
	end
end
U.verifier(#fautes == 0, "chaque variante et chaque matière ont leurs occasions, un nom et une chaleur entre -1 et 1 (en défaut : " .. table.concat(fautes, ", ") .. ")")
U.verifier(#Catalogue.OCCASIONS == 3 and #Catalogue.TRAITS == 7 and Catalogue.NOMS_OCCASIONS.soiree == "Soirée" and Catalogue.NOMS_TRAITS.a_motifs == "À motifs", "trois occasions, sept traits, et leurs noms")

---------------------------------------------------------------------------
-- Une robe : toutes ses pièces dans un tissu (ou selon une fonction de la pièce), droit-fil et couture parfaits
---------------------------------------------------------------------------
local function robe(croquis, tissuDe, accessoires)
	local recette = { croquis = croquis, pieces = {}, accessoires = accessoires or {} }
	for _, id in ipairs(Patron.piecesDuCroquis(croquis)) do
		local tissu = if type(tissuDe) == "function" then tissuDe(id) else tissuDe
		table.insert(recette.pieces, { id = id, tissu = tissu, x = 0, y = 0, angle = Catalogue.piece(id).biais and 45 or 0, couture = 1 })
	end
	return Notation.bilan(recette), recette
end
local SIMPLE = { corsage = "corsage_droit", manches = "manches_sans", col = "col_sans", jupe = "jupe_droite" }
local RICHE = { corsage = "corsage_basque", manches = "manches_ballon", col = "col_claudine", jupe = "jupe_volant" }
local CHAUDE = { corsage = "corsage_droit", manches = "manches_longues", col = "col_sans", jupe = "jupe_evasee" }
local LEGERE = { corsage = "corsage_bustier", manches = "manches_sans", col = "col_sans", jupe = "jupe_droite" }
local function objets(id, n)
	local out = {}
	for _ = 1, n do
		table.insert(out, { id = id, piece = 1, u = 0.5, v = 0.5, echelle = 1, angle = 0 })
	end
	return out
end

---------------------------------------------------------------------------
-- Légère / Chaude : 0,6 × chaleur de la matière + 0,25 × (2 × manches − 1) + 0,15 × (2 × longueur − 1)
---------------------------------------------------------------------------
local b = robe(CHAUDE, "laine_noire")
U.verifier(U.proche(b.traits.chaude, 94) and b.traits.legere == 0, ("laine, manches longues, jupe longue : Chaude 94, Légère 0 (%g, %g)"):format(b.traits.chaude, b.traits.legere))
b = robe(LEGERE, "organza_blanc")
U.verifier(U.proche(b.traits.legere, 94) and b.traits.chaude == 0, ("organza, sans manches, jupe courte : Légère 94, Chaude 0 (%g, %g)"):format(b.traits.legere, b.traits.chaude))
b = robe(RICHE, "coton_blanc")
local attendu = 30 + 25 * (1 - 2 * 1.8 / 5.6) + 15 * (1 - 2 * 0.2)
U.verifier(U.proche(b.traits.legere, attendu), ("coton, manches ballon (1,8 dm), volant jusqu'à 6,6 dm : Légère %.3f (%.3f)"):format(attendu, b.traits.legere))

---------------------------------------------------------------------------
-- Sobre / Travaillée : (poids − 4) / 4 + décorations / 8 − 1 ; un objet compte 1, une garniture 1 pour 5 dm
---------------------------------------------------------------------------
b = robe(SIMPLE, "coton_blanc")
U.verifier(b.traits.sobre == 100 and b.traits.travaillee == 0, "une robe simple sans décoration : Sobre 100")
b = robe(SIMPLE, "coton_blanc", objets("bouton_nacre", 1))
local bG = robe(SIMPLE, "coton_blanc", { { id = "ruban_rose", piece = 3, trajet = { { u = 0, v = 0.5 }, { u = 1, v = 0.5 }, { u = 0, v = 0.5 } } } })
U.verifier(U.proche(b.traits.sobre, 87.5) and U.proche(bG.traits.sobre, 75), ("un bouton : une décoration, Sobre 87,5 ; 10 dm de ruban : deux, Sobre 75 (%g, %g)"):format(b.traits.sobre, bG.traits.sobre))
b = robe(RICHE, "coton_blanc")
U.verifier(Notation.poids(Patron.piecesDuCroquis(RICHE)) == 8 and b.traits.sobre == 0 and b.traits.travaillee == 0, "une robe riche (poids 8) sans décoration : ni sobre ni travaillée")
b = robe(RICHE, "coton_blanc", objets("perle", 4))
local b12 = robe(RICHE, "coton_blanc", objets("perle", 12))
U.verifier(U.proche(b.traits.travaillee, 50) and b12.traits.travaillee == 100, ("quatre perles : Travaillée 50 ; douze : 100, pas plus (%g, %g)"):format(b.traits.travaillee, b12.traits.travaillee))

---------------------------------------------------------------------------
-- Unie / Fleurie / À motifs : la part de la surface de chaque motif
---------------------------------------------------------------------------
b = robe(SIMPLE, function(id)
	return if id:find("^corsage") then "coton_blanc" else "coton_jaune_fleurs"
end)
local partCorsage = 100 * 2 * 4.8 * 4.2 / (2 * 4.8 * 4.2 + 2 * 5 * 6)
U.verifier(U.proche(b.traits.unie, partCorsage) and U.proche(b.traits.fleurie, 100 - partCorsage) and b.traits.a_motifs == 0, ("corsage uni, jupe fleurie : Unie %.2f, Fleurie %.2f (%.2f, %.2f)"):format(partCorsage, 100 - partCorsage, b.traits.unie, b.traits.fleurie))
b = robe(SIMPLE, "coton_bleu_carreaux")
local bD = robe(SIMPLE, "soie_bleue_degrade")
U.verifier(b.traits.a_motifs == 100 and bD.traits.a_motifs == 100 and b.traits.unie == 0, "carreaux, dégradé : À motifs 100")

---------------------------------------------------------------------------
-- Occasions : points des variantes (K 1) et de la matière (K 2), comme les styles
---------------------------------------------------------------------------
b = robe(SIMPLE, "coton_blanc")
U.verifier(b.occasions.journee == 8 + 40 and b.occasions.soiree == 8 and b.occasions.travail == 16 + 12, ("robe simple en coton : Journée 48, Soirée 8, Travail 28 (%g, %g, %g)"):format(b.occasions.journee, b.occasions.soiree, b.occasions.travail))
local compte = 0
for _ in pairs(b.scores) do
	compte += 1
end
U.verifier(compte == 16 and b.scores.elegant == b.styles.elegant and b.scores.journee == 48 and b.scores.sobre == 100, "le bilan réunit les seize étiquettes (" .. compte .. ")")

---------------------------------------------------------------------------
-- Matière dominante : surfaces additionnées par matière ; à égalité, celle de la première pièce
---------------------------------------------------------------------------
b = robe(SIMPLE, function(id)
	return if id:find("^corsage") then "soie_ivoire" else "coton_blanc"
end)
local bEgal = robe(SIMPLE, function(id)
	return if id:find("devant$") then "soie_ivoire" else "coton_blanc"
end)
U.verifier(b.matiere == "coton" and bEgal.matiere == "soie", ("matière dominante : la plus grande surface (coton : %s) ; à égalité, la première pièce (soie : %s)"):format(tostring(b.matiere), tostring(bEgal.matiere)))

---------------------------------------------------------------------------
-- Jugement : au moins la valeur (à l'arrondi près), la matière dominante
---------------------------------------------------------------------------
b = robe(CHAUDE, "laine_noire")
local function juge(e)
	return (Notation.verifierExigences({ e }, b))
end
U.verifier(juge({ type = "trait", trait = "chaude", valeur = 94 }) and not juge({ type = "trait", trait = "chaude", valeur = 95 }) and not juge({ type = "trait", trait = "legere", valeur = 10 }), "trait : au moins la valeur")
U.verifier(juge({ type = "occasion", occasion = "travail", valeur = b.occasions.travail }) and not juge({ type = "occasion", occasion = "travail", valeur = b.occasions.travail + 1 }), "occasion : au moins la valeur")
U.verifier(juge({ type = "matiere", matiere = "laine" }) and not juge({ type = "matiere", matiere = "velours" }), "matière : la matière dominante")

---------------------------------------------------------------------------
-- Carnet : la fourchette des tissus encore à choisir ; tous choisis, elle se réduit au score de la robe
---------------------------------------------------------------------------
local function tous(croquis, tissu)
	local choix = {}
	for _, id in ipairs(Patron.piecesDuCroquis(croquis)) do
		choix[id] = tissu
	end
	return choix
end
local ecarts = {}
for _, croquis in ipairs({ SIMPLE, RICHE, CHAUDE }) do
	for _, t in ipairs(Catalogue.Tissus) do
		local f = Notation.fourchette(croquis, tous(croquis, t.id))
		local bT = robe(croquis, t.id)
		for _, cle in ipairs({ "journee", "soiree", "travail", "chaude", "legere", "unie", "fleurie", "a_motifs" }) do
			local v = bT.scores[cle]
			if not (U.proche(f[cle].min, v) and U.proche(f[cle].max, v)) then
				table.insert(ecarts, ("%s en %s : %s"):format(croquis.jupe, t.id, cle))
			end
		end
	end
end
U.verifier(#ecarts == 0, "tous les tissus choisis : la fourchette se réduit au score (en défaut : " .. table.concat(ecarts, " ; ", 1, math.min(#ecarts, 5)) .. ")")
local function prevoir(e, croquis, choix, ouverts, imposes)
	return Notation.prevision(e, croquis, choix, Notation.fourchette(croquis, choix, imposes, ouverts))
end
local depart = {}
for _, t in ipairs(Catalogue.Tissus) do
	if t.matiere == "coton" or t.matiere == "lin" or t.matiere == "jute" then
		depart[t.id] = true
	end
end
local chaude60 = { type = "trait", trait = "chaude", valeur = 60 }
U.verifier(prevoir(chaude60, CHAUDE, {}) == "?" and prevoir(chaude60, CHAUDE, {}, depart) == "non" and prevoir(chaude60, CHAUDE, tous(CHAUDE, "laine_noire")) == "ok", "Chaude 60 : possible en laine, pas en coton, lin ni jute ; tenue une fois la laine choisie")
U.verifier(prevoir({ type = "occasion", occasion = "soiree", valeur = 60 }, LEGERE, {}) == "non" and prevoir({ type = "occasion", occasion = "soiree", valeur = 50 }, LEGERE, {}) == "?" and prevoir({ type = "occasion", occasion = "soiree", valeur = 50 }, LEGERE, tous(LEGERE, "organza_blanc")) == "ok", "Soirée : 18 de la robe et 40 au plus de la matière (58)")
local sobre60, travaillee60 = { type = "trait", trait = "sobre", valeur = 60 }, { type = "trait", trait = "travaillee", valeur = 60 }
U.verifier(prevoir(sobre60, SIMPLE, {}) == "?" and prevoir(travaillee60, SIMPLE, {}) == "non" and prevoir(travaillee60, RICHE, {}) == "?", "Sobre et Travaillée dépendent des décorations à venir ; une robe simple n'est jamais travaillée")
U.verifier(prevoir(sobre60, RICHE, {}) == "non" and prevoir({ type = "trait", trait = "sobre", valeur = 90 }, SIMPLE, {}, nil, { { id = "broche_camee" } }) == "non", "une robe riche n'est jamais sobre ; une broche imposée compte")
local corsageUni = { corsage_droit_devant = "coton_blanc", corsage_droit_dos = "coton_blanc" }
local unie40, unie50 = { type = "trait", trait = "unie", valeur = 40 }, { type = "trait", trait = "unie", valeur = 50 }
local jupeFleurie = table.clone(corsageUni)
jupeFleurie.jupe_droite_devant, jupeFleurie.jupe_droite_dos = "coton_jaune_fleurs", "coton_jaune_fleurs"
U.verifier(prevoir(unie40, SIMPLE, corsageUni) == "ok" and prevoir(unie50, SIMPLE, corsageUni) == "?" and prevoir(unie50, SIMPLE, jupeFleurie) == "non", "Unie : le corsage uni fait 40 % de la surface")
local matiere = { type = "matiere", matiere = "coton" }
U.verifier(prevoir(matiere, SIMPLE, corsageUni) == "?" and prevoir(matiere, SIMPLE, jupeFleurie) == "ok" and prevoir(matiere, SIMPLE, tous(SIMPLE, "lin_bleu")) == "non", "matière : connue une fois toutes les pièces choisies")
```

- [ ] **Step 2: Lancer les tests, vérifier l'échec**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT|attempt|membre" | head -3`
Expected: échec : une ligne qui finit par `Etiquettes n'est pas un membre valide de Folder « Couture »`

- [ ] **Step 3: Le module, les données, la notation**

Créer `src/shared/Etiquettes.luau` :

```lua
-- Étiquettes (sous-projet 7) : au-delà des six styles, trois occasions et sept traits, notés de 0 à 100 comme les
-- styles.
-- · Occasions (Journée, Soirée, Travail) : elles s'additionnent comme les styles, points des variantes (K 1) et de la
--   matière des tissus (K 2, au prorata de la surface). Les décorations n'en portent pas.
-- · Légère / Chaude : un indice de chaleur dans [-1, 1] = 0,6 × chaleur de la matière (au prorata de la surface)
--   + 0,25 × (2 × manches − 1) + 0,15 × (2 × longueur − 1), où manches = hauteur de la manche / 5,6 dm (0 sans
--   manches) et longueur = (bas de la jupe − 6 dm) / 3 dm, bornée à [0, 1]. Chaude = 100 × l'indice s'il est
--   positif, Légère = 100 × son opposé s'il est négatif.
-- · Sobre / Travaillée : un indice de richesse dans [-1, 1] = (poids des pièces − 4) / 4 + décorations / 8 − 1,
--   chacun des deux termes borné à [0, 1] (un objet compte 1 décoration, une garniture 1 pour 5 dm, au prorata).
--   Travaillée = 100 × l'indice s'il est positif, Sobre = 100 × son opposé s'il est négatif.
-- · Unie / Fleurie / À motifs : la part de la surface dans un tissu uni, fleuri, ou à un autre motif (carreaux, pois,
--   rayures, dégradé), × 100.
-- Les points se décomposent par variante et par tissu (Etiquettes.variante, Etiquettes.tissu) : les commandes et le
-- carnet les additionnent sans rien construire.
local dossier = script.Parent
local Catalogue = require(dossier:WaitForChild("Catalogue"))
local Polygone = require(dossier:WaitForChild("Polygone"))
local Patron = require(dossier:WaitForChild("Patron"))

local Etiquettes = {}

Etiquettes.MANCHE_LONGUE = 5.6 -- dm : une manche de cette hauteur couvre tout le bras
Etiquettes.JUPE_COURTE = 6 -- dm : une jupe qui descend jusque-là est courte…
Etiquettes.JUPE_LONGUE = 9 -- … et longue jusque-là
Etiquettes.POIDS_SIMPLE = 4 -- poids des pièces d'une robe simple (corsage et jupe, deux pièces chacun)…
Etiquettes.POIDS_RICHE = 8 -- … et d'une robe riche
Etiquettes.DECORATIONS_PLEINES = 8 -- au-delà, une décoration de plus ne rend pas la robe plus travaillée
local PART_MATIERE, PART_MANCHES, PART_LONGUEUR = 0.6, 0.25, 0.15

local CLES_TISSU = { "chaleur", table.unpack(Catalogue.OCCASIONS) } -- ce qu'un tissu change, hors motif

-- Trait du motif d'un tissu : uni, fleuri, ou à motifs (tous les autres)
local TRAIT_MOTIF = { uni = "unie", fleurs = "fleurie" }
Etiquettes.MOTIFS = { "unie", "fleurie", "a_motifs" }

local function hauteur(idPiece)
	local b = Polygone.boite(Catalogue.piece(idPiece).contour)
	return b.maxY - b.minY
end

-- Ce qu'apporte chaque variante : { occasions = { [o] = points }, chaleur = son terme de l'indice, poids }
-- (les manches et la jupe portent la chaleur : chaque croquis a exactement une variante de chacune)
local VARIANTES = {}
for _, v in ipairs(Catalogue.Variantes) do
	local apport = { occasions = {}, chaleur = 0, poids = 0 }
	for _, o in ipairs(Catalogue.OCCASIONS) do
		apport.occasions[o] = Catalogue.K.pieces * (v.occasion[o] or 0)
	end
	local manche, bas = 0, 0
	for _, id in ipairs(v.pieces) do
		local def = Catalogue.piece(id)
		apport.poids += def.poids or 1
		if def.enroulement.type == "manche" then
			manche = math.max(manche, hauteur(id))
		elseif def.enroulement.type == "jupe" then
			bas = math.max(bas, (def.enroulement.depart or 0) + hauteur(id))
		end
	end
	if v.famille == "manches" then
		apport.chaleur = PART_MANCHES * (2 * math.min(manche / Etiquettes.MANCHE_LONGUE, 1) - 1)
	elseif v.famille == "jupe" then
		local longueur = math.clamp((bas - Etiquettes.JUPE_COURTE) / (Etiquettes.JUPE_LONGUE - Etiquettes.JUPE_COURTE), 0, 1)
		apport.chaleur = PART_LONGUEUR * (2 * longueur - 1)
	end
	VARIANTES[v.id] = apport
end

-- Ce qu'apporte chaque tissu, pour toute la robe dans ce tissu : { occasions, chaleur, motif = trait du motif }
local TISSUS = {}
for _, t in ipairs(Catalogue.Tissus) do
	local m = Catalogue.MATIERES[t.matiere]
	local apport = { occasions = {}, chaleur = PART_MATIERE * m.chaleur, motif = TRAIT_MOTIF[t.motif.type] or "a_motifs" }
	for _, o in ipairs(Catalogue.OCCASIONS) do
		apport.occasions[o] = Catalogue.K.tissu * (m.occasion[o] or 0)
	end
	TISSUS[t.id] = apport
end

function Etiquettes.variante(id)
	return VARIANTES[id]
end
function Etiquettes.tissu(id)
	return TISSUS[id]
end

-- Les deux traits d'un indice dans [-1, 1] : celui du côté positif (Chaude, Travaillée), puis l'autre (Légère, Sobre)
function Etiquettes.traitsIndice(indice)
	return math.clamp(100 * indice, 0, 100), math.clamp(-100 * indice, 0, 100)
end

-- Indice de richesse d'une robe : poids de ses pièces (Notation.poids), nombre de ses décorations
function Etiquettes.richesse(poids, decorations)
	local pieces = math.clamp((poids - Etiquettes.POIDS_SIMPLE) / (Etiquettes.POIDS_RICHE - Etiquettes.POIDS_SIMPLE), 0, 1)
	return pieces + math.clamp(decorations / Etiquettes.DECORATIONS_PLEINES, 0, 1) - 1
end

-- Nombre de décorations : accessoires = { { id, longueur? } } (un objet 1 ; une garniture 1 pour 5 dm, sans longueur 0)
function Etiquettes.decorations(accessoires)
	local n = 0
	for _, a in ipairs(accessoires or {}) do
		local def = Catalogue.accessoire(a.id)
		assert(def, "accessoire inconnu : " .. tostring(a.id))
		n += if def.genre == "garniture" then (a.longueur or 0) / 5 else 1
	end
	return n
end

-- entree = { croquis, tissus = { [idTissu] = aire }, accessoires = { { id, longueur? } } } (comme Notation.styles)
-- Retourne { occasions = { [occasion] = 0 à 100 }, traits = { [trait] = 0 à 100 } }
function Etiquettes.calculer(entree)
	local occasions, chaleur, poids = {}, 0, 0
	for _, o in ipairs(Catalogue.OCCASIONS) do
		occasions[o] = 0
	end
	for _, famille in ipairs(Catalogue.FAMILLES) do
		local a = VARIANTES[entree.croquis[famille]]
		for _, o in ipairs(Catalogue.OCCASIONS) do
			occasions[o] += a.occasions[o]
		end
		chaleur += a.chaleur
		poids += a.poids
	end
	local motifs = { unie = 0, fleurie = 0, a_motifs = 0 }
	local aireTotale = 0
	for _, aire in pairs(entree.tissus) do
		aireTotale += aire
	end
	if aireTotale > 0 then
		for idTissu, aire in pairs(entree.tissus) do
			local a, part = TISSUS[idTissu], aire / aireTotale
			for _, o in ipairs(Catalogue.OCCASIONS) do
				occasions[o] += a.occasions[o] * part
			end
			chaleur += a.chaleur * part
			motifs[a.motif] += 100 * part
		end
	end
	local traits = {}
	traits.chaude, traits.legere = Etiquettes.traitsIndice(chaleur)
	traits.travaillee, traits.sobre = Etiquettes.traitsIndice(Etiquettes.richesse(poids, Etiquettes.decorations(entree.accessoires)))
	for _, m in ipairs(Etiquettes.MOTIFS) do
		traits[m] = math.clamp(motifs[m], 0, 100)
	end
	for _, o in ipairs(Catalogue.OCCASIONS) do
		occasions[o] = math.clamp(occasions[o], 0, 100)
	end
	return { occasions = occasions, traits = traits }
end

-- Matière dominante (comme la teinte) : surfaces additionnées par matière ; à égalité, celle de la première pièce.
-- pieces = { { id, tissu } } dans l'ordre du croquis
function Etiquettes.matiereDominante(pieces)
	local parMatiere = {}
	for _, p in ipairs(pieces) do
		local m = Catalogue.tissu(p.tissu).matiere
		parMatiere[m] = (parMatiere[m] or 0) + Patron.aire(p.id)
	end
	local matiere, aireMax = nil, -1
	for _, p in ipairs(pieces) do
		local m = Catalogue.tissu(p.tissu).matiere
		if parMatiere[m] > aireMax + 1e-9 then
			matiere, aireMax = m, parMatiere[m]
		end
	end
	return matiere
end

-- Fourchette du carnet : { [occasion ou trait] = { min, max } } selon les tissus encore à choisir. choix = { [idPiece]
-- = idTissu ou nil } ; decorationsImposees : celles que la robe portera forcément (Etiquettes.decorations des
-- accessoires imposés), on peut en ajouter autant qu'on veut ; tissusOuverts (facultatif) : les pièces sans tissu ne
-- comptent que les tissus ouverts.
function Etiquettes.fourchette(croquis, choix, decorationsImposees, tissusOuverts)
	local base = { occasions = {}, chaleur = 0, poids = 0 }
	for _, o in ipairs(Catalogue.OCCASIONS) do
		base.occasions[o] = 0
	end
	for _, famille in ipairs(Catalogue.FAMILLES) do
		local a = VARIANTES[croquis[famille]]
		for _, o in ipairs(Catalogue.OCCASIONS) do
			base.occasions[o] += a.occasions[o]
		end
		base.chaleur += a.chaleur
		base.poids += a.poids
	end
	-- Les extrêmes d'un tissu encore à choisir
	local mini, maxi = { chaleur = math.huge }, { chaleur = -math.huge }
	local motifTous, motifUn = { unie = true, fleurie = true, a_motifs = true }, {}
	local aucun = true
	for _, o in ipairs(Catalogue.OCCASIONS) do
		mini[o], maxi[o] = math.huge, -math.huge
	end
	for _, t in ipairs(Catalogue.Tissus) do
		if not tissusOuverts or tissusOuverts[t.id] then
			aucun = false
			local a = TISSUS[t.id]
			for _, o in ipairs(Catalogue.OCCASIONS) do
				mini[o], maxi[o] = math.min(mini[o], a.occasions[o]), math.max(maxi[o], a.occasions[o])
			end
			mini.chaleur, maxi.chaleur = math.min(mini.chaleur, a.chaleur), math.max(maxi.chaleur, a.chaleur)
			motifUn[a.motif] = true
			for _, m in ipairs(Etiquettes.MOTIFS) do
				motifTous[m] = motifTous[m] and a.motif == m
			end
		end
	end
	if aucun then
		for cle in pairs(mini) do
			mini[cle], maxi[cle] = 0, 0
		end
		motifTous = {}
	end
	-- Chaque pièce, au prorata de sa surface
	local pieces = Patron.piecesDuCroquis(croquis)
	local aireTotale = 0
	for _, id in ipairs(pieces) do
		aireTotale += Patron.aire(id)
	end
	local bas, haut = { chaleur = base.chaleur }, { chaleur = base.chaleur }
	for _, o in ipairs(Catalogue.OCCASIONS) do
		bas[o], haut[o] = base.occasions[o], base.occasions[o]
	end
	for _, m in ipairs(Etiquettes.MOTIFS) do
		bas[m], haut[m] = 0, 0
	end
	for _, id in ipairs(pieces) do
		local part = Patron.aire(id) / aireTotale
		local a = choix[id] and TISSUS[choix[id]]
		for _, cle in ipairs(CLES_TISSU) do
			local v = if a then (if cle == "chaleur" then a.chaleur else a.occasions[cle]) else nil
			bas[cle] += (v or mini[cle]) * part
			haut[cle] += (v or maxi[cle]) * part
		end
		for _, m in ipairs(Etiquettes.MOTIFS) do
			if a then
				local dedans = if a.motif == m then 100 * part else 0
				bas[m] += dedans
				haut[m] += dedans
			else
				bas[m] += if motifTous[m] then 100 * part else 0
				haut[m] += if motifUn[m] then 100 * part else 0
			end
		end
	end
	local out = {}
	for _, o in ipairs(Catalogue.OCCASIONS) do
		out[o] = { min = math.clamp(bas[o], 0, 100), max = math.clamp(haut[o], 0, 100) }
	end
	for _, m in ipairs(Etiquettes.MOTIFS) do
		out[m] = { min = math.clamp(bas[m], 0, 100), max = math.clamp(haut[m], 0, 100) }
	end
	local chaudeBas, legereHaut = Etiquettes.traitsIndice(bas.chaleur)
	local chaudeHaut, legereBas = Etiquettes.traitsIndice(haut.chaleur)
	out.chaude, out.legere = { min = chaudeBas, max = chaudeHaut }, { min = legereBas, max = legereHaut }
	local travailleeBas, sobreHaut = Etiquettes.traitsIndice(Etiquettes.richesse(base.poids, decorationsImposees or 0))
	local travailleeHaut, sobreBas = Etiquettes.traitsIndice(Etiquettes.richesse(base.poids, Etiquettes.DECORATIONS_PLEINES))
	out.travaillee, out.sobre = { min = travailleeBas, max = travailleeHaut }, { min = sobreBas, max = sobreHaut }
	return out
end

return Etiquettes
```

Dans `src/shared/Catalogue.luau`, remplacer :

```lua
Catalogue.TEINTES = { "rose", "rouge", "bleu", "vert", "jaune", "violet", "noir", "blanc", "brun" }
```

par :

```lua
Catalogue.TEINTES = { "rose", "rouge", "bleu", "vert", "jaune", "violet", "noir", "blanc", "brun" }
-- Sous-projet 7 : trois occasions (points des variantes et des matières, comme les styles) et sept traits calculés
-- d'après la robe (voir Etiquettes)
Catalogue.OCCASIONS = { "journee", "soiree", "travail" }
Catalogue.NOMS_OCCASIONS = { journee = "Journée", soiree = "Soirée", travail = "Travail" }
Catalogue.TRAITS = { "legere", "chaude", "sobre", "travaillee", "unie", "fleurie", "a_motifs" }
Catalogue.NOMS_TRAITS = {
	legere = "Légère",
	chaude = "Chaude",
	sobre = "Sobre",
	travaillee = "Travaillée",
	unie = "Unie",
	fleurie = "Fleurie",
	a_motifs = "À motifs",
}
```

Dans `src/shared/Catalogue.luau`, remplacer :

```lua
-- Variantes du carnet de croquis (points de style par variante)
---------------------------------------------------------------------------
Catalogue.Variantes = {
	{ id = "corsage_droit", famille = "corsage", nom = "Droit",
		pieces = { "corsage_droit_devant", "corsage_droit_dos" }, style = { chic = 6, decontracte = 6 } },
	{ id = "corsage_v", famille = "corsage", nom = "Décolleté en V",
		pieces = { "corsage_v_devant", "corsage_droit_dos" }, style = { elegant = 8, romantique = 4 } },
	{ id = "corsage_bretelles", famille = "corsage", nom = "À bretelles",
		pieces = { "corsage_bretelles_devant", "corsage_bretelles_dos" }, style = { decontracte = 8, mignon = 4 } },
	{ id = "corsage_cache_coeur", famille = "corsage", nom = "Cache-cœur",
		pieces = { "corsage_cache_coeur_devant", "corsage_droit_dos" }, style = { romantique = 8, chic = 4 } },
	{ id = "corsage_bustier", famille = "corsage", nom = "Bustier",
		pieces = { "corsage_bustier_devant", "corsage_bustier_dos" }, style = { gothique = 7, elegant = 5 } },
	{ id = "manches_sans", famille = "manches", nom = "Sans manches", pieces = {}, style = { decontracte = 3 } },
	{ id = "manches_ballon", famille = "manches", nom = "Ballon", pieces = { "manche_ballon" },
		style = { mignon = 8, romantique = 4 } },
	{ id = "manches_longues", famille = "manches", nom = "Longues", pieces = { "manche_longue" },
		style = { elegant = 5, gothique = 5, chic = 3 } },
	{ id = "manches_courtes", famille = "manches", nom = "Courtes", pieces = { "manche_courte" },
		style = { decontracte = 6, mignon = 3 } },
	{ id = "manches_trois_quarts", famille = "manches", nom = "Trois-quarts", pieces = { "manche_trois_quarts" },
		style = { chic = 6, elegant = 4 } },
	{ id = "col_sans", famille = "col", nom = "Sans col", pieces = {}, style = {} },
	{ id = "col_claudine", famille = "col", nom = "Claudine", pieces = { "col_claudine" }, style = { mignon = 6, chic = 2 } },
	{ id = "col_montant", famille = "col", nom = "Montant", pieces = { "col_montant" }, style = { gothique = 6, elegant = 4 } },
	{ id = "col_marin", famille = "col", nom = "Marin", pieces = { "col_marin" }, style = { mignon = 5, decontracte = 5 } },
	{ id = "jupe_droite", famille = "jupe", nom = "Droite",
		pieces = { "jupe_droite_devant", "jupe_droite_dos" }, style = { chic = 8 } },
	{ id = "jupe_trapeze", famille = "jupe", nom = "Trapèze",
		pieces = { "jupe_trapeze_devant", "jupe_trapeze_dos" }, style = { decontracte = 5, mignon = 4 } },
	{ id = "jupe_ample", famille = "jupe", nom = "Ample froncée",
		pieces = { "jupe_ample_devant", "jupe_ample_dos" }, style = { romantique = 8, mignon = 4 } },
	{ id = "jupe_evasee", famille = "jupe", nom = "Longue évasée",
		pieces = { "jupe_evasee_devant", "jupe_evasee_dos" }, style = { elegant = 10, gothique = 4, decontracte = -4 } },
	{ id = "jupe_crayon", famille = "jupe", nom = "Crayon",
		pieces = { "jupe_crayon_devant", "jupe_crayon_dos" }, style = { chic = 8, elegant = 4, decontracte = -2 } },
	-- Sous-projet 7 : des couches. (Une variante ne change jamais de pièces : les robes gardées et les recettes des
	-- vitrines resteraient invalides ; on en ajoute de nouvelles.)
	{ id = "corsage_basque", famille = "corsage", nom = "À basque",
		pieces = { "corsage_droit_devant", "corsage_droit_dos", "basque_devant", "basque_dos" }, style = { elegant = 6, chic = 6, romantique = 2 } },
	{ id = "jupe_volant", famille = "jupe", nom = "À volant",
		pieces = { "jupe_droite_devant", "jupe_droite_dos", "volant_devant", "volant_dos" }, style = { romantique = 8, mignon = 6 } },
}
```

par :

```lua
-- Variantes du carnet de croquis (points de style et, sous-projet 7, d'occasion par variante)
---------------------------------------------------------------------------
Catalogue.Variantes = {
	{ id = "corsage_droit", famille = "corsage", nom = "Droit",
		pieces = { "corsage_droit_devant", "corsage_droit_dos" }, style = { chic = 6, decontracte = 6 },
		occasion = { travail = 8, journee = 4 } },
	{ id = "corsage_v", famille = "corsage", nom = "Décolleté en V",
		pieces = { "corsage_v_devant", "corsage_droit_dos" }, style = { elegant = 8, romantique = 4 },
		occasion = { soiree = 6, journee = 2 } },
	{ id = "corsage_bretelles", famille = "corsage", nom = "À bretelles",
		pieces = { "corsage_bretelles_devant", "corsage_bretelles_dos" }, style = { decontracte = 8, mignon = 4 },
		occasion = { journee = 8 } },
	{ id = "corsage_cache_coeur", famille = "corsage", nom = "Cache-cœur",
		pieces = { "corsage_cache_coeur_devant", "corsage_droit_dos" }, style = { romantique = 8, chic = 4 },
		occasion = { journee = 4, soiree = 4 } },
	{ id = "corsage_bustier", famille = "corsage", nom = "Bustier",
		pieces = { "corsage_bustier_devant", "corsage_bustier_dos" }, style = { gothique = 7, elegant = 5 },
		occasion = { soiree = 10 } },
	{ id = "manches_sans", famille = "manches", nom = "Sans manches", pieces = {}, style = { decontracte = 3 },
		occasion = { journee = 4, soiree = 4 } },
	{ id = "manches_ballon", famille = "manches", nom = "Ballon", pieces = { "manche_ballon" },
		style = { mignon = 8, romantique = 4 }, occasion = { journee = 6 } },
	{ id = "manches_longues", famille = "manches", nom = "Longues", pieces = { "manche_longue" },
		style = { elegant = 5, gothique = 5, chic = 3 }, occasion = { travail = 6, soiree = 2 } },
	{ id = "manches_courtes", famille = "manches", nom = "Courtes", pieces = { "manche_courte" },
		style = { decontracte = 6, mignon = 3 }, occasion = { journee = 6, travail = 2 } },
	{ id = "manches_trois_quarts", famille = "manches", nom = "Trois-quarts", pieces = { "manche_trois_quarts" },
		style = { chic = 6, elegant = 4 }, occasion = { travail = 8 } },
	{ id = "col_sans", famille = "col", nom = "Sans col", pieces = {}, style = {}, occasion = { soiree = 4 } },
	{ id = "col_claudine", famille = "col", nom = "Claudine", pieces = { "col_claudine" }, style = { mignon = 6, chic = 2 },
		occasion = { journee = 4, travail = 2 } },
	{ id = "col_montant", famille = "col", nom = "Montant", pieces = { "col_montant" }, style = { gothique = 6, elegant = 4 },
		occasion = { travail = 6, soiree = 2 } },
	{ id = "col_marin", famille = "col", nom = "Marin", pieces = { "col_marin" }, style = { mignon = 5, decontracte = 5 },
		occasion = { journee = 6 } },
	{ id = "jupe_droite", famille = "jupe", nom = "Droite",
		pieces = { "jupe_droite_devant", "jupe_droite_dos" }, style = { chic = 8 }, occasion = { travail = 8 } },
	{ id = "jupe_trapeze", famille = "jupe", nom = "Trapèze",
		pieces = { "jupe_trapeze_devant", "jupe_trapeze_dos" }, style = { decontracte = 5, mignon = 4 },
		occasion = { journee = 8 } },
	{ id = "jupe_ample", famille = "jupe", nom = "Ample froncée",
		pieces = { "jupe_ample_devant", "jupe_ample_dos" }, style = { romantique = 8, mignon = 4 },
		occasion = { journee = 6, soiree = 4 } },
	{ id = "jupe_evasee", famille = "jupe", nom = "Longue évasée",
		pieces = { "jupe_evasee_devant", "jupe_evasee_dos" }, style = { elegant = 10, gothique = 4, decontracte = -4 },
		occasion = { soiree = 10 } },
	{ id = "jupe_crayon", famille = "jupe", nom = "Crayon",
		pieces = { "jupe_crayon_devant", "jupe_crayon_dos" }, style = { chic = 8, elegant = 4, decontracte = -2 },
		occasion = { travail = 10, soiree = 2 } },
	-- Sous-projet 7 : des couches. (Une variante ne change jamais de pièces : les robes gardées et les recettes des
	-- vitrines resteraient invalides ; on en ajoute de nouvelles.)
	{ id = "corsage_basque", famille = "corsage", nom = "À basque",
		pieces = { "corsage_droit_devant", "corsage_droit_dos", "basque_devant", "basque_dos" }, style = { elegant = 6, chic = 6, romantique = 2 },
		occasion = { travail = 8, soiree = 4 } },
	{ id = "jupe_volant", famille = "jupe", nom = "À volant",
		pieces = { "jupe_droite_devant", "jupe_droite_dos", "volant_devant", "volant_dos" }, style = { romantique = 8, mignon = 6 },
		occasion = { journee = 6, soiree = 4 } },
}
```

Dans `src/shared/Catalogue.luau`, remplacer :

```lua
-- Rendu 3D par matière : matériau Roblox et reflet (SurfaceAppearance est interdite en jeu, voir le spike)
Catalogue.MATIERES = {
	coton = { rugosite = 0.9, reflet = 0, materiau = "Fabric" },
	lin = { rugosite = 1, reflet = 0, materiau = "Fabric" },
	jute = { rugosite = 1, reflet = 0, materiau = "Fabric" },
	crepe = { rugosite = 0.7, reflet = 0.02, materiau = "Fabric" },
	organza = { rugosite = 0.3, reflet = 0.12, materiau = "SmoothPlastic" },
	brocart = { rugosite = 0.4, reflet = 0.15, materiau = "SmoothPlastic" },
	tulle = { rugosite = 0.6, reflet = 0.05, materiau = "Fabric" },
	laine = { rugosite = 1, reflet = 0, materiau = "Fabric" },
	soie = { rugosite = 0.35, reflet = 0.1, materiau = "SmoothPlastic" },
	velours = { rugosite = 0.8, reflet = 0, materiau = "Fabric" },
	satin = { rugosite = 0.25, reflet = 0.15, materiau = "SmoothPlastic" },
}
```

par :

```lua
-- Par matière : rendu 3D, matériau Roblox et reflet (SurfaceAppearance est interdite en jeu, voir le spike) ;
-- sous-projet 7 : son nom, ses points d'occasion (comme les points de style d'un tissu : K 2, au prorata de la
-- surface) et sa chaleur, de -1 (la plus légère) à 1 (la plus chaude)
Catalogue.MATIERES = {
	coton = { nom = "coton", rugosite = 0.9, reflet = 0, materiau = "Fabric", occasion = { journee = 20, travail = 6 }, chaleur = -0.5 },
	lin = { nom = "lin", rugosite = 1, reflet = 0, materiau = "Fabric", occasion = { journee = 14, travail = 10 }, chaleur = -0.8 },
	jute = { nom = "jute", rugosite = 1, reflet = 0, materiau = "Fabric", occasion = { journee = 10, travail = 8 }, chaleur = 0.1 },
	crepe = { nom = "crêpe", rugosite = 0.7, reflet = 0.02, materiau = "Fabric", occasion = { soiree = 10, travail = 12 }, chaleur = 0 },
	organza = { nom = "organza", rugosite = 0.3, reflet = 0.12, materiau = "SmoothPlastic", occasion = { soiree = 20 }, chaleur = -0.9 },
	brocart = { nom = "brocart", rugosite = 0.4, reflet = 0.15, materiau = "SmoothPlastic", occasion = { soiree = 16, travail = 4 }, chaleur = 0.6 },
	tulle = { nom = "tulle", rugosite = 0.6, reflet = 0.05, materiau = "Fabric", occasion = { soiree = 16, journee = 2 }, chaleur = -0.7 },
	laine = { nom = "laine", rugosite = 1, reflet = 0, materiau = "Fabric", occasion = { travail = 18, journee = 4 }, chaleur = 0.9 },
	soie = { nom = "soie", rugosite = 0.35, reflet = 0.1, materiau = "SmoothPlastic", occasion = { soiree = 14, journee = 6 }, chaleur = -0.4 },
	velours = { nom = "velours", rugosite = 0.8, reflet = 0, materiau = "Fabric", occasion = { soiree = 14, travail = 4 }, chaleur = 0.8 },
	satin = { nom = "satin", rugosite = 0.25, reflet = 0.15, materiau = "SmoothPlastic", occasion = { soiree = 16, journee = 2 }, chaleur = -0.1 },
}
```

Dans `src/shared/Notation.luau`, remplacer :

```lua
-- Notation : droit-fil, couture, qualité, jauges de style, exigences des commandes et paie.
-- Utilisé par le serveur (qui fait foi) et par le client (affichage en direct).
local dossier = script.Parent
local Catalogue = require(dossier:WaitForChild("Catalogue"))
local Polygone = require(dossier:WaitForChild("Polygone"))
local Patron = require(dossier:WaitForChild("Patron"))
```

par :

```lua
-- Notation : droit-fil, couture, qualité, jauges de style (et, sous-projet 7, d'occasion et de trait : voir
-- Etiquettes), exigences des commandes et paie.
-- Utilisé par le serveur (qui fait foi) et par le client (affichage en direct).
local dossier = script.Parent
local Catalogue = require(dossier:WaitForChild("Catalogue"))
local Polygone = require(dossier:WaitForChild("Polygone"))
local Patron = require(dossier:WaitForChild("Patron"))
local Etiquettes = require(dossier:WaitForChild("Etiquettes"))
```

Dans `src/shared/Notation.luau`, remplacer :

```lua
-- Jauges du carnet : choix = { [idPiece] = idTissu ou nil } ; accessoires = accessoires imposés par
-- la commande ({ { id } }, voir accessoiresImposes), qui seront forcément sur la robe.
-- Retourne { [style] = { acquis, min, max } } : acquis = points des variantes seules,
-- min / max = fourchette possible selon les tissus encore à choisir.
```

par :

```lua
-- Jauges du carnet : choix = { [idPiece] = idTissu ou nil } ; accessoires = accessoires imposés par
-- la commande ({ { id } }, voir accessoiresImposes), qui seront forcément sur la robe.
-- Retourne { [style] = { acquis, min, max } } : acquis = points des variantes seules,
-- min / max = fourchette possible selon les tissus encore à choisir. Sous-projet 7 : aussi { [occasion ou trait] =
-- { min, max } } (Etiquettes.fourchette : les décorations à venir comptent pour Sobre et Travaillée).
```

Dans `src/shared/Notation.luau`, remplacer :

```lua
		out[s] = {
			acquis = base[s],
			min = math.clamp(brutAcquis + bas, 0, 100),
			max = math.clamp(brutAcquis + haut, 0, 100),
		}
	end
	return out
end
```

par :

```lua
		out[s] = {
			acquis = base[s],
			min = math.clamp(brutAcquis + bas, 0, 100),
			max = math.clamp(brutAcquis + haut, 0, 100),
		}
	end
	for cle, f in pairs(Etiquettes.fourchette(croquis, choix, Etiquettes.decorations(accessoires), tissusOuverts)) do
		out[cle] = f
	end
	return out
end
```

Dans `src/shared/Notation.luau`, remplacer :

```lua
-- Prévision du carnet pour une exigence : "ok", "non", ou "?" (dépend des tissus encore à choisir,
-- de la couture ou des décorations). fourchette = Notation.fourchette(croquis, choix, imposés).
function Notation.prevision(e, croquis, choix, fourchette, ajustement)
	if e.type == "qualite" and ajustement and e.valeur > ajustement then
		return "non" -- la qualité est multipliée par l'ajustement : celle-ci est hors d'atteinte
	elseif e.type == "min" then
		local f = fourchette[e.style]
		return f.min >= e.valeur - 1e-9 and "ok" or (f.max < e.valeur - 1e-9 and "non" or "?")
	elseif e.type == "max" then
		local f = fourchette[e.style]
		return f.max <= e.valeur + 1e-9 and "ok" or (f.min > e.valeur + 1e-9 and "non" or "?")
	elseif e.type == "teinte" then
		local pieces = {}
		for _, id in ipairs(Patron.piecesDuCroquis(croquis)) do
			if not choix[id] then
				return "?"
			end
			table.insert(pieces, { id = id, tissu = choix[id] })
		end
		return Notation.teinteDominante(pieces) == e.teinte and "ok" or "non"
	end
	return "?" -- qualité (à la couture) et accessoire (aux décorations)
end
```

par :

```lua
-- Prévision du carnet pour une exigence : "ok", "non", ou "?" (dépend des tissus encore à choisir,
-- de la couture ou des décorations). fourchette = Notation.fourchette(croquis, choix, imposés).
function Notation.prevision(e, croquis, choix, fourchette, ajustement)
	if e.type == "qualite" and ajustement and e.valeur > ajustement then
		return "non" -- la qualité est multipliée par l'ajustement : celle-ci est hors d'atteinte
	elseif e.type == "min" or e.type == "occasion" or e.type == "trait" then
		local f = fourchette[e.style or e.occasion or e.trait]
		return f.min >= e.valeur - 1e-9 and "ok" or (f.max < e.valeur - 1e-9 and "non" or "?")
	elseif e.type == "max" then
		local f = fourchette[e.style]
		return f.max <= e.valeur + 1e-9 and "ok" or (f.min > e.valeur + 1e-9 and "non" or "?")
	elseif e.type == "teinte" or e.type == "matiere" then
		local pieces = {}
		for _, id in ipairs(Patron.piecesDuCroquis(croquis)) do
			if not choix[id] then
				return "?"
			end
			table.insert(pieces, { id = id, tissu = choix[id] })
		end
		if e.type == "matiere" then
			return Etiquettes.matiereDominante(pieces) == e.matiere and "ok" or "non"
		end
		return Notation.teinteDominante(pieces) == e.teinte and "ok" or "non"
	end
	return "?" -- qualité (à la couture) et accessoire (aux décorations)
end
```

Dans `src/shared/Notation.luau`, remplacer :

```lua
-- recette = { croquis, pieces = { { id, tissu, x, y, angle, couture } }, accessoires = { … } }
-- Retourne { styles, qualite, teinte, accessoires = { [id] = nombre }, nbPieces }
```

par :

```lua
-- recette = { croquis, pieces = { { id, tissu, x, y, angle, couture } }, accessoires = { … } }
-- Retourne { styles, qualite, teinte, accessoires = { [id] = nombre }, nbPieces } ; sous-projet 7 : occasions,
-- traits (Etiquettes.calculer), matiere (la matière dominante) et scores (les seize étiquettes ensemble, pour les
-- textes : styles, occasions et traits)
```

Dans `src/shared/Notation.luau`, remplacer :

```lua
	return {
		styles = Notation.styles({ croquis = recette.croquis, tissus = tissus, accessoires = accessoires }),
		qualite = Notation.qualite(piecesNotees),
		teinte = teinte,
		accessoires = comptes,
		nbPieces = #recette.pieces,
	}
end
```

par :

```lua
	local entree = { croquis = recette.croquis, tissus = tissus, accessoires = accessoires }
	local styles, etiquettes = Notation.styles(entree), Etiquettes.calculer(entree)
	local scores = table.clone(styles)
	for cle, v in pairs(etiquettes.occasions) do
		scores[cle] = v
	end
	for cle, v in pairs(etiquettes.traits) do
		scores[cle] = v
	end
	return {
		styles = styles,
		occasions = etiquettes.occasions,
		traits = etiquettes.traits,
		scores = scores,
		qualite = Notation.qualite(piecesNotees),
		teinte = teinte,
		matiere = Etiquettes.matiereDominante(recette.pieces),
		accessoires = comptes,
		nbPieces = #recette.pieces,
	}
end
```

Dans `src/shared/Notation.luau`, remplacer :

```lua
-- exigences : { { type = "min"|"max", style, valeur } | { type = "qualite", valeur }
--              | { type = "teinte", teinte } | { type = "accessoire", id } }
-- Retourne ok, et la liste des indices des exigences ratées
```

par :

```lua
-- exigences : { { type = "min"|"max", style, valeur } | { type = "qualite", valeur }
--              | { type = "teinte", teinte } | { type = "accessoire", id }
--              | (sous-projet 7) { type = "occasion", occasion, valeur } | { type = "trait", trait, valeur } (au moins)
--              | { type = "matiere", matiere } (la matière dominante) }
-- Retourne ok, et la liste des indices des exigences ratées
```

Dans `src/shared/Notation.luau`, remplacer :

```lua
		elseif e.type == "accessoire" then
			ok = (bilan.accessoires[e.id] or 0) > 0
		else
			error("exigence inconnue : " .. tostring(e.type))
```

par :

```lua
		elseif e.type == "accessoire" then
			ok = (bilan.accessoires[e.id] or 0) > 0
		elseif e.type == "occasion" then
			ok = bilan.occasions[e.occasion] >= e.valeur - 1e-9
		elseif e.type == "trait" then
			ok = bilan.traits[e.trait] >= e.valeur - 1e-9
		elseif e.type == "matiere" then
			ok = bilan.matiere == e.matiere
		else
			error("exigence inconnue : " .. tostring(e.type))
```

- [ ] **Step 4: Lancer les tests**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT"`
Expected:
```
Unitaires : 192985 vérifications
TOUT EST VERT : 998 vérifications
```

- [ ] **Step 5: Commit**

```bash
git add src/shared/Etiquettes.luau src/shared/Catalogue.luau src/shared/Notation.luau tests/unitaires/70_etiquettes.luau
git commit -m "Étiquettes : occasions et traits calculés, matière dominante ; la cliente les juge, le carnet les prévoit

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 2: Des commandes réalisables, famille par famille

**Files:**
- Create: `tests/unitaires/71_commandes_etiquettes.luau`
- Modify: `src/shared/Commandes.luau`

**Interfaces:**
- Consumes: `Etiquettes.variante`, `Etiquettes.tissu`, `Etiquettes.traitsIndice`, `Etiquettes.richesse`, `Etiquettes.decorations`, `Etiquettes.DECORATIONS_PLEINES`, `Etiquettes.MOTIFS`, `Catalogue.OCCASIONS`, `Catalogue.TRAITS` (Task 1) ; `Notation.bilan`, `Notation.verifierExigences` pour les nouveaux types (Task 1).
- Produces: `Commandes.realisable(exigences, ouverts)` → `ok, { croquis, tissu, accessoire, ajout = { id, nombre } ou nil }` ; mêmes réponses qu'avant pour les anciens types.

- [ ] **Step 1: Écrire les tests**

Créer `tests/unitaires/71_commandes_etiquettes.luau` :

```lua
-- Sous-projet 7 : Commandes.realisable sait juger les occasions, les traits et la matière. La recherche avance famille
-- par famille ; elle répond comme l'essai complet de chaque robe simple, et son témoin tient les exigences.
local Commandes = U.module("Commandes")
local Catalogue = U.module("Catalogue")
local Notation = U.module("Notation")
local Etiquettes = U.module("Etiquettes")
local Deblocages = U.module("Deblocages")
local Patron = U.module("Patron")

-- La référence : chaque robe simple dans l'ordre du carnet, jugée par le calcul complet (Notation.styles,
-- Etiquettes.calculer) ; pour une robe travaillée, juste assez d'un même objet ouvert, le premier qui convient
local CROQUIS = {}
for _, c in ipairs(Catalogue.variantesDe("corsage")) do
	for _, m in ipairs(Catalogue.variantesDe("manches")) do
		for _, k in ipairs(Catalogue.variantesDe("col")) do
			for _, j in ipairs(Catalogue.variantesDe("jupe")) do
				table.insert(CROQUIS, { corsage = c.id, manches = m.id, col = k.id, jupe = j.id })
			end
		end
	end
end
local function bilanSimple(croquis, t, accessoires)
	local entree = { croquis = croquis, tissus = { [t.id] = 1 }, accessoires = accessoires }
	local e = Etiquettes.calculer(entree)
	local comptes = {}
	for _, a in ipairs(accessoires) do
		comptes[a.id] = (comptes[a.id] or 0) + 1
	end
	return { styles = Notation.styles(entree), occasions = e.occasions, traits = e.traits, qualite = 0.9, teinte = t.teinte, matiere = t.matiere, accessoires = comptes }
end
local function reference(exigences, ouverts)
	local impose
	local travaillee = {}
	for _, e in ipairs(exigences) do
		if e.type == "accessoire" then
			impose = e.id
		elseif e.type == "qualite" and e.valeur > 0.9 then
			return false
		elseif e.type == "trait" and e.trait == "travaillee" then
			table.insert(travaillee, e)
		end
	end
	if impose and (not Catalogue.accessoire(impose) or (ouverts and not ouverts.accessoires[impose])) then
		return false
	end
	local base = impose and { { id = impose } } or {}
	for _, croquis in ipairs(CROQUIS) do
		if not ouverts or (ouverts.variantes[croquis.corsage] and ouverts.variantes[croquis.manches] and ouverts.variantes[croquis.col] and ouverts.variantes[croquis.jupe]) then
			for _, t in ipairs(Catalogue.Tissus) do
				if not ouverts or ouverts.tissus[t.id] then
					-- Combien de décorations en plus ? (le nombre seul compte pour Travaillée)
					local simple = bilanSimple(croquis, t, base)
					local n = if Notation.verifierExigences(travaillee, simple) then 0 else nil
					for essai = 1, if n then 0 else Etiquettes.DECORATIONS_PLEINES do
						local avec = table.clone(base)
						for _ = 1, essai do
							table.insert(avec, { id = "perle" })
						end
						if Notation.verifierExigences(travaillee, bilanSimple(croquis, t, avec)) then
							n = essai
							break
						end
					end
					if n == 0 then
						if Notation.verifierExigences(exigences, simple) then
							return true, croquis, t.id
						end
					elseif n then
						for _, a in ipairs(Catalogue.Accessoires) do
							if a.genre == "objet" and (not ouverts or ouverts.accessoires[a.id]) then
								local avec = table.clone(base)
								for _ = 1, n do
									table.insert(avec, { id = a.id })
								end
								if Notation.verifierExigences(exigences, bilanSimple(croquis, t, avec)) then
									return true, croquis, t.id, { id = a.id, nombre = n }
								end
							end
						end
					end
				end
			end
		end
	end
	return false
end

-- Le témoin, cousu pour de vrai : toutes les pièces dans son tissu, l'accessoire imposé et les objets ajoutés
local function recetteTemoin(temoin)
	local recette = { croquis = temoin.croquis, pieces = {}, accessoires = {} }
	for _, id in ipairs(Patron.piecesDuCroquis(temoin.croquis)) do
		table.insert(recette.pieces, { id = id, tissu = temoin.tissu, x = 0, y = 0, angle = Catalogue.piece(id).biais and 45 or 0, couture = 0.9 })
	end
	if temoin.accessoire then
		table.insert(recette.accessoires, { id = temoin.accessoire, piece = 1, u = 0.5, v = 0.5, echelle = 1, angle = 0 })
	end
	for _ = 1, temoin.ajout and temoin.ajout.nombre or 0 do
		table.insert(recette.accessoires, { id = temoin.ajout.id, piece = 1, u = 0.4, v = 0.4, echelle = 1, angle = 0 })
	end
	return recette
end

---------------------------------------------------------------------------
-- Quatre cents jeux d'exigences tirés au hasard, anciennes et nouvelles (dont des impossibles), avec ou sans
-- restriction : même réponse que la référence, même témoin, et le témoin cousu remplit les exigences
---------------------------------------------------------------------------
local MATIERES = {}
for m in pairs(Catalogue.MATIERES) do
	table.insert(MATIERES, m)
end
table.sort(MATIERES)
local PROGRES = {
	{ prestige = 0, clientes = {} },
	{ prestige = 100, clientes = { colette = { amitie = 7 } } },
	{ prestige = 530, clientes = {} },
}
local rng = Random.new(71)
local differences, autres, faux, genres = {}, 0, 0, {}
for n = 1, 400 do
	local exigences = {}
	for _ = 1, rng:NextInteger(1, 3) do
		local genre = rng:NextInteger(1, 8)
		if genre == 1 then
			table.insert(exigences, { type = "min", style = Catalogue.STYLES[rng:NextInteger(1, 6)], valeur = rng:NextInteger(1, 8) * 10 })
		elseif genre == 2 then
			table.insert(exigences, { type = "max", style = Catalogue.STYLES[rng:NextInteger(1, 6)], valeur = rng:NextInteger(0, 5) * 10 })
		elseif genre == 3 then
			table.insert(exigences, { type = "teinte", teinte = Catalogue.TEINTES[rng:NextInteger(1, #Catalogue.TEINTES)] })
		elseif genre == 4 then
			table.insert(exigences, { type = "accessoire", id = Catalogue.Accessoires[rng:NextInteger(1, #Catalogue.Accessoires)].id })
		elseif genre == 5 then
			table.insert(exigences, { type = "occasion", occasion = Catalogue.OCCASIONS[rng:NextInteger(1, 3)], valeur = rng:NextInteger(1, 8) * 10 })
		elseif genre == 6 then
			table.insert(exigences, { type = "trait", trait = Catalogue.TRAITS[rng:NextInteger(1, 7)], valeur = rng:NextInteger(1, 10) * 10 })
		elseif genre == 7 then
			table.insert(exigences, { type = "matiere", matiere = MATIERES[rng:NextInteger(1, #MATIERES)] })
		else
			table.insert(exigences, { type = "qualite", valeur = rng:NextInteger(5, 10) / 10 })
		end
	end
	local ouverts = if n % 4 == 0 then nil else Deblocages.ouverts(PROGRES[n % 3 + 1])
	local ok, temoin = Commandes.realisable(exigences, ouverts)
	local okRef, croquisRef, tissuRef, ajoutRef = reference(exigences, ouverts)
	if ok ~= okRef then
		table.insert(differences, n)
	elseif ok then
		genres[temoin.ajout and "ajout" or "simple"] = true
		local memeAjout = (temoin.ajout == nil and ajoutRef == nil) or (temoin.ajout and ajoutRef and temoin.ajout.id == ajoutRef.id and temoin.ajout.nombre == ajoutRef.nombre)
		if temoin.tissu ~= tissuRef or not memeAjout or temoin.croquis.corsage ~= croquisRef.corsage or temoin.croquis.manches ~= croquisRef.manches or temoin.croquis.col ~= croquisRef.col or temoin.croquis.jupe ~= croquisRef.jupe then
			autres += 1
		end
		if not Notation.verifierExigences(exigences, Notation.bilan(recetteTemoin(temoin))) then
			faux += 1
		end
	else
		genres.impossible = true
	end
end
U.verifier(#differences == 0, "quatre cents jeux d'exigences : même réponse que le calcul complet (en défaut : " .. table.concat(differences, ", ") .. ")")
U.verifier(autres == 0 and faux == 0, ("le témoin est la première robe du calcul complet (%d autres) et, cousu, remplit les exigences (%d faux)"):format(autres, faux))
U.verifier(genres.simple and genres.ajout and genres.impossible, "des jeux réalisables simplement, avec des décorations ajoutées, et impossibles")

---------------------------------------------------------------------------
-- Tout ouvert, chaque étiquette atteint 60 (les motifs 100) et chaque matière peut dominer
---------------------------------------------------------------------------
local manquees = {}
for _, o in ipairs(Catalogue.OCCASIONS) do
	if not Commandes.realisable({ { type = "occasion", occasion = o, valeur = 60 } }) then
		table.insert(manquees, o)
	end
end
for _, t in ipairs(Catalogue.TRAITS) do
	local valeur = if table.find(Etiquettes.MOTIFS, t) then 100 else 60
	if not Commandes.realisable({ { type = "trait", trait = t, valeur = valeur } }) then
		table.insert(manquees, t)
	end
end
for _, m in ipairs(MATIERES) do
	if not Commandes.realisable({ { type = "matiere", matiere = m } }) then
		table.insert(manquees, m)
	end
end
U.verifier(#manquees == 0, "tout ouvert, chaque occasion et chaque trait atteignent 60, chaque matière peut dominer (manquées : " .. table.concat(manquees, ", ") .. ")")
local ok, temoin = Commandes.realisable({ { type = "trait", trait = "travaillee", valeur = 60 } })
U.verifier(ok and temoin.ajout and temoin.ajout.nombre == 7 and Notation.poids(Patron.piecesDuCroquis(temoin.croquis)) == 7, "Travaillée 60 : la première robe assez riche (poids 7 : corsage droit, manches ballon, col Claudine, jupe à volant) et sept objets")
U.verifier(not Commandes.realisable({ { type = "trait", trait = "travaillee", valeur = 60 } }, Deblocages.ouverts({ prestige = 0, clientes = {} })), "au départ, sans volant ni basque, aucune robe n'est assez travaillée")
U.verifier(not Commandes.realisable({ { type = "trait", trait = "chaude", valeur = 10 }, { type = "trait", trait = "legere", valeur = 10 } }), "Légère et Chaude à la fois : impossible")
```

- [ ] **Step 2: Lancer les tests, vérifier l'échec**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT|attempt|membre" | head -3`
Expected: échec : une ligne qui finit par `387, 391, 395, 397, 400)`

- [ ] **Step 3: La recherche famille par famille**

Dans `src/shared/Commandes.luau`, remplacer :

```lua
local Progression = require(dossier:WaitForChild("Progression"))
```

par :

```lua
local Progression = require(dossier:WaitForChild("Progression"))
local Etiquettes = require(dossier:WaitForChild("Etiquettes"))
```

Dans `src/shared/Commandes.luau`, remplacer :

```lua
-- Toutes les combinaisons de variantes du carnet (6 × 5 × 4 × 6 = 720, depuis le sous-projet 7)
local function croquisPossibles()
	local out = {}
	for _, c in ipairs(Catalogue.variantesDe("corsage")) do
		for _, m in ipairs(Catalogue.variantesDe("manches")) do
			for _, k in ipairs(Catalogue.variantesDe("col")) do
				for _, j in ipairs(Catalogue.variantesDe("jupe")) do
					table.insert(out, { corsage = c.id, manches = m.id, col = k.id, jupe = j.id })
				end
			end
		end
	end
	return out
end
local CROQUIS = croquisPossibles()

-- Les styles s'additionnent (Notation.styles) : les points bruts de chaque croquis, de chaque tissu (toute la robe
-- dans ce tissu) et de chaque objet imposé sont calculés une fois ; une robe candidate se juge alors en quelques
-- additions, sans rien créer. (Une garniture imposée, sans longueur, ne compte pas : comme dans Notation.styles.)
local K = Catalogue.K
local POINTS_CROQUIS = {}
for i, croquis in ipairs(CROQUIS) do
	local points = {}
	for _, s in ipairs(Catalogue.STYLES) do
		points[s] = 0
	end
	for _, famille in ipairs(Catalogue.FAMILLES) do
		for s, pts in pairs(Catalogue.variante(croquis[famille]).style) do
			points[s] += K.pieces * pts
		end
	end
	POINTS_CROQUIS[i] = points
end
local POINTS_TISSU = {}
for _, t in ipairs(Catalogue.Tissus) do
	local points = {}
	for _, s in ipairs(Catalogue.STYLES) do
		points[s] = K.tissu * (t.style[s] or 0)
	end
	POINTS_TISSU[t.id] = points
end
local function pointsImpose(idAccessoire)
	local points = {}
	local def = idAccessoire and Catalogue.accessoire(idAccessoire)
	for _, s in ipairs(Catalogue.STYLES) do
		points[s] = if def and def.genre == "objet" then K.accessoires * (def.style[s] or 0) else 0
	end
	return points
end

-- Cherche une robe simple (un seul tissu, au plus l'accessoire imposé) qui remplit les exigences.
-- La qualité est supposée atteignable (≤ 0,9). ouverts (facultatif, Deblocages.ouverts) : seulement avec ce
-- qui est ouvert. Retourne ok et le témoin { croquis, tissu, accessoire }.
function Commandes.realisable(exigences, ouverts)
	local accessoireImpose
	for _, e in ipairs(exigences) do
		if e.type == "accessoire" then
			accessoireImpose = e.id
		elseif e.type == "qualite" and e.valeur > 0.9 then
			return false
		end
	end
	if accessoireImpose and (not Catalogue.accessoire(accessoireImpose) or (ouverts and not ouverts.accessoires[accessoireImpose])) then
		return false
	end
	-- Les exigences les plus fermées d'abord, une fois pour toutes : les accessoires (seul le dernier demandé est
	-- posé sur la robe témoin) et la teinte (seuls les tissus ouverts de cette teinte restent candidats) ;
	-- restent les styles, à vérifier robe par robe (la qualité, au plus 0,9, est tenue d'office)
	local aVerifier = {}
	for _, e in ipairs(exigences) do
		if e.type == "accessoire" and e.id ~= accessoireImpose then
			return false
		elseif e.type == "min" or e.type == "max" then
			table.insert(aVerifier, e)
		end
	end
	local tissus = {}
	for _, t in ipairs(Catalogue.Tissus) do
		local permis = not ouverts or ouverts.tissus[t.id]
		for _, e in ipairs(exigences) do
			if e.type == "teinte" and e.teinte ~= t.teinte then
				permis = false
			end
		end
		if permis then
			table.insert(tissus, t)
		end
	end
	if #tissus == 0 then
		return false
	end
	local pa = pointsImpose(accessoireImpose)
	for i, croquis in ipairs(CROQUIS) do
		if not ouverts or (ouverts.variantes[croquis.corsage] and ouverts.variantes[croquis.manches] and ouverts.variantes[croquis.col] and ouverts.variantes[croquis.jupe]) then
			local pc = POINTS_CROQUIS[i]
			for _, t in ipairs(tissus) do
				local pt = POINTS_TISSU[t.id]
				local ok = true
				for _, e in ipairs(aVerifier) do
					local v = math.clamp(pc[e.style] + pt[e.style] + pa[e.style], 0, 100)
					ok = if e.type == "min" then v >= e.valeur - 1e-9 else v <= e.valeur + 1e-9
					if not ok then
						break
					end
				end
				if ok then
					return true, { croquis = croquis, tissu = t.id, accessoire = accessoireImpose }
				end
			end
		end
	end
	return false
end
```

par :

```lua
-- Les points s'additionnent (Notation.styles, Etiquettes) : ceux de chaque variante et de chaque tissu (toute la
-- robe dans ce tissu), styles, occasions, chaleur et poids des pièces, sont calculés une fois ; une robe candidate
-- se juge alors en quelques additions, sans rien créer. (Une garniture imposée, sans longueur, ne compte pas : comme
-- dans Notation.styles.)
local K = Catalogue.K
local CLES = table.clone(Catalogue.STYLES)
for _, o in ipairs(Catalogue.OCCASIONS) do
	table.insert(CLES, o)
end
table.insert(CLES, "chaleur")
table.insert(CLES, "poids")
local function zero()
	local t = {}
	for _, c in ipairs(CLES) do
		t[c] = 0
	end
	return t
end
local APPORTS_VARIANTES, APPORTS_TISSUS = {}, {}
for _, v in ipairs(Catalogue.Variantes) do
	local e, a = Etiquettes.variante(v.id), zero()
	for s, pts in pairs(v.style) do
		a[s] = K.pieces * pts
	end
	for _, o in ipairs(Catalogue.OCCASIONS) do
		a[o] = e.occasions[o]
	end
	a.chaleur, a.poids = e.chaleur, e.poids
	APPORTS_VARIANTES[v.id] = a
end
for _, t in ipairs(Catalogue.Tissus) do
	local e, a = Etiquettes.tissu(t.id), zero()
	for s, pts in pairs(t.style) do
		a[s] = K.tissu * pts
	end
	for _, o in ipairs(Catalogue.OCCASIONS) do
		a[o] = e.occasions[o]
	end
	a.chaleur = e.chaleur
	APPORTS_TISSUS[t.id] = a
end
local function apportObjet(idAccessoire, fois)
	local a = zero()
	local def = idAccessoire and Catalogue.accessoire(idAccessoire)
	if def and def.genre == "objet" then
		for s, pts in pairs(def.style) do
			a[s] = K.accessoires * pts * fois
		end
	end
	return a
end

-- Une exigence chiffrée borne une somme de points : jugement = { cle, note (la somme, et le nombre de décorations,
-- → le score de 0 à 100), croissant (le score monte avec la somme), auPlus, valeur }
local function borne(x)
	return math.clamp(x, 0, 100)
end
local NOTES_TRAITS = {
	chaude = { cle = "chaleur", croissant = true, note = function(x)
		return (Etiquettes.traitsIndice(x))
	end },
	legere = { cle = "chaleur", croissant = false, note = function(x)
		return select(2, Etiquettes.traitsIndice(x))
	end },
	travaillee = { cle = "poids", croissant = true, note = function(poids, decorations)
		return (Etiquettes.traitsIndice(Etiquettes.richesse(poids, decorations)))
	end },
	sobre = { cle = "poids", croissant = false, note = function(poids, decorations)
		return select(2, Etiquettes.traitsIndice(Etiquettes.richesse(poids, decorations)))
	end },
}
local function tient(j, score)
	return if j.auPlus then score <= j.valeur + 1e-9 else score >= j.valeur - 1e-9
end

-- Cherche une robe simple qui remplit les exigences : un seul tissu, l'accessoire imposé et, pour une robe travaillée,
-- juste assez d'un même objet ouvert (le premier qui convient, dans l'ordre du catalogue). La qualité est supposée
-- atteignable (≤ 0,9). ouverts (facultatif, Deblocages.ouverts) : seulement avec ce qui est ouvert. Retourne ok et
-- le témoin { croquis, tissu, accessoire, ajout = { id, nombre } ou nil }.
-- Sous-projet 7 : la recherche avance famille par famille (corsage, manches, col, jupe, puis le tissu) et abandonne
-- une branche dès qu'aucune suite ne peut plus tenir une exigence : elle trouve la même robe que l'essai de chaque
-- croquis dans l'ordre, sans les essayer tous.
function Commandes.realisable(exigences, ouverts)
	local accessoireImpose
	for _, e in ipairs(exigences) do
		if e.type == "accessoire" then
			accessoireImpose = e.id
		elseif e.type == "qualite" and e.valeur > 0.9 then
			return false
		end
	end
	if accessoireImpose and (not Catalogue.accessoire(accessoireImpose) or (ouverts and not ouverts.accessoires[accessoireImpose])) then
		return false
	end
	-- Les exigences les plus fermées d'abord, une fois pour toutes : les accessoires (seul le dernier demandé est
	-- posé sur la robe témoin) ; la teinte, la matière et le motif (seuls les tissus ouverts qui les ont restent
	-- candidats) ; restent les exigences chiffrées (la qualité, au plus 0,9, est tenue d'office)
	local jugements, decoratives = {}, {}
	for _, e in ipairs(exigences) do
		if e.type == "accessoire" and e.id ~= accessoireImpose then
			return false
		elseif e.type == "min" or e.type == "max" or e.type == "occasion" then
			table.insert(jugements, { cle = e.style or e.occasion, note = borne, croissant = true, auPlus = e.type == "max", valeur = e.valeur })
		elseif e.type == "trait" and NOTES_TRAITS[e.trait] then
			local t = NOTES_TRAITS[e.trait]
			local j = { cle = t.cle, note = t.note, croissant = t.croissant, valeur = e.valeur }
			table.insert(jugements, j)
			if e.trait == "travaillee" then
				table.insert(decoratives, j)
			end
		end
	end
	local tissus = {}
	for _, t in ipairs(Catalogue.Tissus) do
		local permis = not ouverts or ouverts.tissus[t.id]
		for _, e in ipairs(exigences) do
			if (e.type == "teinte" and e.teinte ~= t.teinte) or (e.type == "matiere" and e.matiere ~= t.matiere) then
				permis = false
			elseif e.type == "trait" and not NOTES_TRAITS[e.trait] then -- un motif : toute la robe l'a, ou pas du tout
				permis = permis and (if Etiquettes.tissu(t.id).motif == e.trait then 100 else 0) >= e.valeur - 1e-9
			end
		end
		if permis then
			table.insert(tissus, t)
		end
	end
	if #tissus == 0 then
		return false
	end
	local objets = {} -- de quoi rendre la robe travaillée
	if #decoratives > 0 then
		for _, a in ipairs(Catalogue.Accessoires) do
			if a.genre == "objet" and (not ouverts or ouverts.accessoires[a.id]) then
				table.insert(objets, a)
			end
		end
	end
	local base = Etiquettes.decorations(accessoireImpose and { { id = accessoireImpose } })
	local impose = apportObjet(accessoireImpose, 1)

	-- Ce que peuvent encore apporter les familles k à 4, puis le tissu, l'accessoire imposé et les décorations :
	-- reste[k] = { bas = { [cle] = … }, haut = { … } }
	local variantes, reste = {}, {}
	for k, famille in ipairs(Catalogue.FAMILLES) do
		variantes[k] = {}
		for _, v in ipairs(Catalogue.variantesDe(famille)) do
			if not ouverts or ouverts.variantes[v.id] then
				table.insert(variantes[k], v.id)
			end
		end
		if #variantes[k] == 0 then
			return false
		end
	end
	local function extremes(apports)
		local bas, haut = {}, {}
		for _, c in ipairs(CLES) do
			bas[c], haut[c] = math.huge, -math.huge
			for _, a in ipairs(apports) do
				bas[c], haut[c] = math.min(bas[c], a[c]), math.max(haut[c], a[c])
			end
		end
		return bas, haut
	end
	local apportsTissus, apportsObjets = {}, { zero() }
	for _, t in ipairs(tissus) do
		table.insert(apportsTissus, APPORTS_TISSUS[t.id])
	end
	for _, a in ipairs(objets) do
		table.insert(apportsObjets, apportObjet(a.id, Etiquettes.DECORATIONS_PLEINES))
	end
	local basT, hautT = extremes(apportsTissus)
	local basD, hautD = extremes(apportsObjets)
	reste[#Catalogue.FAMILLES + 1] = { bas = {}, haut = {} }
	for _, c in ipairs(CLES) do
		reste[#Catalogue.FAMILLES + 1].bas[c] = basT[c] + impose[c] + basD[c]
		reste[#Catalogue.FAMILLES + 1].haut[c] = hautT[c] + impose[c] + hautD[c]
	end
	for k = #Catalogue.FAMILLES, 1, -1 do
		local apports = {}
		for _, id in ipairs(variantes[k]) do
			table.insert(apports, APPORTS_VARIANTES[id])
		end
		local bas, haut = extremes(apports)
		reste[k] = { bas = {}, haut = {} }
		for _, c in ipairs(CLES) do
			reste[k].bas[c] = bas[c] + reste[k + 1].bas[c]
			reste[k].haut[c] = haut[c] + reste[k + 1].haut[c]
		end
	end
	-- Une somme partielle peut-elle encore tout tenir ? (chaque exigence à son extrême le plus favorable)
	local function possible(somme, r)
		for _, j in ipairs(jugements) do
			local monte = j.croissant ~= (j.auPlus == true)
			local x = somme[j.cle] + (if monte then r.haut[j.cle] else r.bas[j.cle])
			if not tient(j, j.note(x, if monte then Etiquettes.DECORATIONS_PLEINES else base)) then
				return false
			end
		end
		return true
	end
	local function tientTout(somme, decorations)
		for _, j in ipairs(jugements) do
			if not tient(j, j.note(somme[j.cle], decorations)) then
				return false
			end
		end
		return true
	end
	-- Une robe complète : son tissu, puis juste assez de décorations
	local croquis = {}
	local function essayerTissus(partiel)
		for _, t in ipairs(tissus) do
			local somme = {}
			for _, c in ipairs(CLES) do
				somme[c] = partiel[c] + APPORTS_TISSUS[t.id][c] + impose[c]
			end
			local n = 0
			local function assez()
				for _, j in ipairs(decoratives) do
					if not tient(j, j.note(somme.poids, base + n)) then
						return false
					end
				end
				return true
			end
			while not assez() and base + n < Etiquettes.DECORATIONS_PLEINES do
				n += 1
			end
			if not assez() then
				continue -- même couverte de décorations, cette robe ne serait pas assez travaillée
			elseif n == 0 then
				if tientTout(somme, base) then
					return { croquis = table.clone(croquis), tissu = t.id, accessoire = accessoireImpose }
				end
			else
				for _, a in ipairs(objets) do
					local avec = table.clone(somme)
					for s, pts in pairs(a.style) do
						avec[s] += K.accessoires * pts * n
					end
					if tientTout(avec, base + n) then
						return { croquis = table.clone(croquis), tissu = t.id, accessoire = accessoireImpose, ajout = { id = a.id, nombre = n } }
					end
				end
			end
		end
		return nil
	end
	local function chercher(k, partiel)
		if not possible(partiel, reste[k]) then
			return nil
		elseif k > #Catalogue.FAMILLES then
			return essayerTissus(partiel)
		end
		local famille = Catalogue.FAMILLES[k]
		for _, id in ipairs(variantes[k]) do
			croquis[famille] = id
			local somme = {}
			for _, c in ipairs(CLES) do
				somme[c] = partiel[c] + APPORTS_VARIANTES[id][c]
			end
			local temoin = chercher(k + 1, somme)
			if temoin then
				return temoin
			end
		end
		croquis[famille] = nil
		return nil
	end
	local temoin = chercher(1, zero())
	return temoin ~= nil, temoin
end
```

- [ ] **Step 4: Lancer les tests**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT"`
Expected:
```
Unitaires : 192992 vérifications
TOUT EST VERT : 998 vérifications
```

- [ ] **Step 5: Commit**

```bash
git add src/shared/Commandes.luau tests/unitaires/71_commandes_etiquettes.luau
git commit -m "Commandes : réalisables avec occasions, traits et matière ; recherche famille par famille

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 3: Sauvegarde et textes

**Files:**
- Modify: `src/server/Sauvegarde.luau`, `src/client/Atelier/UiKit.luau`, `src/client/Atelier/EcranPresentation.luau`, `src/client/Atelier/EcranRefus.luau`
- Modify: `tests/unitaires/24_textes.luau`, `tests/unitaires/30_sauvegarde.luau`

**Interfaces:**
- Consumes: `Catalogue.OCCASIONS`, `Catalogue.TRAITS`, `Catalogue.MATIERES[m].nom`, `bilan.scores` (Task 1).
- Produces: `UiKit.exigence(e, Catalogue, scores)` (scores : les seize étiquettes ; les styles seuls restent acceptés) ; une commande sauvegardée garde ses exigences d'occasion, de trait et de matière.

- [ ] **Step 1: Écrire les tests**

Dans `tests/unitaires/24_textes.luau`, remplacer :

```lua
U.verifier(UiKit.exigence(auMoins, Catalogue) == "Au moins 30 en Élégant", "sans scores : l'exigence seule (carnet)")
```

par :

```lua
U.verifier(UiKit.exigence(auMoins, Catalogue) == "Au moins 30 en Élégant", "sans scores : l'exigence seule (carnet)")
-- (sous-projet 7) Occasions, traits et matière, avec les seize étiquettes du bilan
local soir = { type = "occasion", occasion = "soiree", valeur = 40 }
local motifs = { type = "trait", trait = "a_motifs", valeur = 50 }
U.verifier(UiKit.exigence(soir, Catalogue, { soiree = 39.6, elegant = 80 }) == "Pour la soirée : au moins 40 (actuel : 39)", "occasion : « Pour la soirée : au moins 40 (actuel : 39) »")
U.verifier(UiKit.exigence(motifs, Catalogue, { a_motifs = 50 }) == "Robe à motifs : au moins 50 (actuel : 50)" and UiKit.exigence(motifs, Catalogue) == "Robe à motifs : au moins 50", "trait : « Robe à motifs : au moins 50 »")
U.verifier(UiKit.exigence({ type = "matiere", matiere = "crepe" }, Catalogue) == "Matière dominante : crêpe", "matière : « Matière dominante : crêpe »")
local noms = {}
for _, o in ipairs(Catalogue.OCCASIONS) do
	table.insert(noms, UiKit.exigence({ type = "occasion", occasion = o, valeur = 20 }, Catalogue))
end
for _, t in ipairs(Catalogue.TRAITS) do
	table.insert(noms, UiKit.exigence({ type = "trait", trait = t, valeur = 20 }, Catalogue))
end
U.verifier(not table.concat(noms, "|"):find("nil") and not table.concat(noms, "|"):find("%?"), "chaque occasion et chaque trait ont leur texte : " .. table.concat(noms, " | "))
```

Dans `tests/unitaires/30_sauvegarde.luau`, remplacer :

```lua
abandonnee(etat, function(c)
	c.commande.exigences = { { type = "min", style = "punk", valeur = 20 } }
end, "style inconnu")
```

par :

```lua
abandonnee(etat, function(c)
	c.commande.exigences = { { type = "min", style = "punk", valeur = 20 } }
end, "style inconnu")
-- (sous-projet 7) Occasions, traits et matières : les nouveaux types se relisent, les inconnus sont refusés
abandonnee(etat, function(c)
	c.commande.exigences = { { type = "occasion", occasion = "bal", valeur = 20 } }
end, "occasion inconnue")
abandonnee(etat, function(c)
	c.commande.exigences = { { type = "trait", trait = "brillante", valeur = 20 } }
end, "trait inconnu")
abandonnee(etat, function(c)
	c.commande.exigences = { { type = "trait", trait = "legere", valeur = "beaucoup" } }
end, "valeur de trait illisible")
abandonnee(etat, function(c)
	c.commande.exigences = { { type = "matiere", matiere = "cuir" } }
end, "matière inconnue")
do
	local q = Sauvegarde.depuisEtat(etat)
	q.enCours.commande.exigences = { { type = "occasion", occasion = "soiree", valeur = 30 }, { type = "trait", trait = "a_motifs", valeur = 50 }, { type = "matiere", matiere = "crepe" } }
	M.avertissements = {}
	local relue = Sauvegarde.versEtat(q)
	U.verifier(relue.etape == etat.etape and relue.commande ~= nil and #relue.commande.exigences == 3 and relue.commande.exigences[3].matiere == "crepe" and #M.avertissements == 0, "occasion, trait et matière : la commande se relit")
end
```

- [ ] **Step 2: Lancer les tests, vérifier l'échec**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT|attempt|membre" | head -3`
Expected: échec : une ligne qui finit par `ÉCHEC : occasion : « Pour la soirée : au moins 40 (actuel : 39) »`

- [ ] **Step 3: Sauvegarde, textes, écrans**

Dans `src/server/Sauvegarde.luau`, remplacer :

```lua
	elseif e.type == "accessoire" then
		return type(e.id) == "string" and Catalogue.accessoire(e.id) ~= nil
	end
	return false
end
```

par :

```lua
	elseif e.type == "accessoire" then
		return type(e.id) == "string" and Catalogue.accessoire(e.id) ~= nil
	elseif e.type == "occasion" then -- (sous-projet 7)
		return table.find(Catalogue.OCCASIONS, e.occasion) ~= nil and nombre(e.valeur, nil) ~= nil
	elseif e.type == "trait" then
		return table.find(Catalogue.TRAITS, e.trait) ~= nil and nombre(e.valeur, nil) ~= nil
	elseif e.type == "matiere" then
		return type(e.matiere) == "string" and Catalogue.MATIERES[e.matiere] ~= nil
	end
	return false
end
```

Dans `src/client/Atelier/UiKit.luau`, remplacer :

```lua
function UiKit.exigence(e, Catalogue, styles)
	-- Arrondi du côté de la comparaison : le chiffre affiché ne contredit jamais le jugement de la cliente
	local actuel = ""
	if styles and e.style then
		local arrondi = e.type == "max" and math.ceil(styles[e.style] - 1e-9) or math.floor(styles[e.style] + 1e-9)
		actuel = (" (actuel : %d)"):format(arrondi)
	end
	if e.type == "min" then
```

par :

```lua
-- Sous-projet 7 : scores = les seize étiquettes d'une robe (bilan.scores : styles, occasions et traits)
local POUR = { journee = "la journée", soiree = "la soirée", travail = "le travail" }
local ROBE = { legere = "légère", chaude = "chaude", sobre = "sobre", travaillee = "travaillée", unie = "unie", fleurie = "fleurie", a_motifs = "à motifs" }
function UiKit.exigence(e, Catalogue, scores)
	-- Arrondi du côté de la comparaison : le chiffre affiché ne contredit jamais le jugement de la cliente
	local actuel = ""
	local cle = e.style or e.occasion or e.trait
	if scores and cle and scores[cle] then
		local arrondi = e.type == "max" and math.ceil(scores[cle] - 1e-9) or math.floor(scores[cle] + 1e-9)
		actuel = (" (actuel : %d)"):format(arrondi)
	end
	if e.type == "min" then
```

Dans `src/client/Atelier/UiKit.luau`, remplacer :

```lua
	elseif e.type == "accessoire" then
		return "Avec : " .. Catalogue.accessoire(e.id).nom
	end
	return "?"
```

par :

```lua
	elseif e.type == "accessoire" then
		return "Avec : " .. Catalogue.accessoire(e.id).nom
	elseif e.type == "occasion" then
		return ("Pour %s : au moins %d"):format(POUR[e.occasion], e.valeur) .. actuel
	elseif e.type == "trait" then
		return ("Robe %s : au moins %d"):format(ROBE[e.trait], e.valeur) .. actuel
	elseif e.type == "matiere" then
		return "Matière dominante : " .. Catalogue.MATIERES[e.matiere].nom
	end
	return "?"
```

Dans `src/client/Atelier/EcranPresentation.luau`, remplacer :

```lua
UiKit.exigence(e, Catalogue, bilan.styles)
```

par :

```lua
UiKit.exigence(e, Catalogue, bilan.scores)
```

Dans `src/client/Atelier/EcranRefus.luau`, remplacer :

```lua
	local styles = etat:bilan().styles
```

par :

```lua
	local scores = etat:bilan().scores
```

Dans `src/client/Atelier/EcranRefus.luau`, remplacer :

```lua
			Text = "× " .. UiKit.exigence(etat.commande.exigences[i], Catalogue, styles),
```

par :

```lua
			Text = "× " .. UiKit.exigence(etat.commande.exigences[i], Catalogue, scores),
```

- [ ] **Step 4: Lancer les tests**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT"`
Expected:
```
Unitaires : 193001 vérifications
TOUT EST VERT : 998 vérifications
```

- [ ] **Step 5: Commit**

```bash
git add src/server/Sauvegarde.luau src/client/Atelier/UiKit.luau src/client/Atelier/EcranPresentation.luau src/client/Atelier/EcranRefus.luau tests/unitaires/24_textes.luau tests/unitaires/30_sauvegarde.luau
git commit -m "Étiquettes : la sauvegarde garde les nouvelles exigences ; leurs textes, avec le score actuel

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 4: Studio, README, lieu régénéré

**Files:**
- Modify: `README.md`, `AtelierCouture.rbxl` (régénéré)

**Interfaces:**
- Consumes: tout ce qui précède.
- Produces: rien de nouveau.

- [ ] **Step 1: Dans Studio, par le connecteur MCP**

Construire le lieu du dépôt dans un dossier temporaire (`C:/dev/jeux/roblox-maker/rojo.exe build -o <dossier temporaire>/Plan21Depot.rbxl`) et l'ouvrir dans Studio. En édition (`execute_luau`, Edit), mesurer (`os.clock`, moyenne de cinq appels) `Commandes.realisable` tout ouvert sur trois jeux impossibles (« au moins 100 en Gothique et en Mignon » ; « Légère 60, en velours » ; « Soirée 69 ») et deux possibles (« Travaillée 60 » ; « Travaillée 100 et au plus 10 en Élégant ») ; mesurer avec `TextService:GetTextSize` (GothamBold, 16 px, comme au refus) le plus long des nouveaux textes d'exigence avec son score (« × Pour la journée : au moins 100 (actuel : 100) »). Puis en Play : attendre 4 s, relever la console.

Expected : les trois premiers jeux impossibles, les deux autres possibles, chaque recherche sous 50 ms (0,1 à 0,3 ms pendant la préparation) ; le texte le plus long sous 340 px, la largeur du contenu du panneau (324 px pendant la préparation) ; aucune alerte de notre code (« Lieu non publié » et les messages internes de Roblox mis à part). Arrêter Play et fermer cette fenêtre de Studio (sans enregistrer).

- [ ] **Step 2: Mettre à jour le README**

Dans `README.md`, remplacer :

```markdown
## État actuel (sous-projet 7 en cours, plans 19 et 20 : des robes à couches, volant et basque)
```

par :

```markdown
## État actuel (sous-projet 7 en cours, plans 19 à 21 : des robes à couches, volant et basque ; seize étiquettes)
```

Dans `README.md`, remplacer :

```markdown
   la robe (styles, qualité, couleur dominante, accessoires). Acceptée : paie = base × (0,5 + qualité), et la
   robe part en vitrine ; la cliente remercie et s'en va. Refusée : les exigences ratées s'affichent (avec le
   score actuel pour les styles) ; on retouche les décorations ou on abandonne.
```

par :

```markdown
   la robe (styles, qualité, couleur dominante, accessoires). Acceptée : paie = base × (0,5 + qualité), et la
   robe part en vitrine ; la cliente remercie et s'en va. Refusée : les exigences ratées s'affichent (avec le
   score actuel pour les styles) ; on retouche les décorations ou on abandonne.
   **Seize étiquettes** (sous-projet 7, plan 21 : le calcul ; les commandes les demanderont au plan 22) : aux six
   styles s'ajoutent trois occasions (Journée, Soirée, Travail : points des variantes et des matières) et sept
   traits calculés d'après la robe : Légère / Chaude (matière, manches, longueur de la jupe), Sobre / Travaillée
   (poids des pièces, décorations), Unie / Fleurie / À motifs (surface de chaque motif) ; et la matière dominante.
   La cliente sait juger ces exigences, le carnet les prévoit, la sauvegarde les garde.
```

Dans `README.md`, remplacer :

```markdown
jamais les styles robe par robe (les points de chaque croquis et de chaque tissu sont précalculés ; les tissus
   d'une autre teinte que celle demandée sont écartés d'abord).
```

par :

```markdown
jamais les styles robe par robe (les points de chaque variante et de chaque tissu sont précalculés ; les tissus
   d'une autre teinte, matière ou motif que ceux demandés sont écartés d'abord ; la recherche avance famille par
   famille et abandonne une branche qui ne peut plus tenir une exigence).
```

Dans `README.md`, remplacer :

```markdown
  | `Notation`, `Commandes` | Droit-fil, couture, qualité, styles, exigences, paie, ajustement aux mesures ; commandes réalisables, d'après les goûts de la cliente |
```

par :

```markdown
  | `Notation`, `Commandes` | Droit-fil, couture, qualité, styles, exigences, paie, ajustement aux mesures ; commandes réalisables, d'après les goûts de la cliente |
  | `Etiquettes` | Occasions et traits calculés (chaleur, richesse, motifs), matière dominante, fourchette du carnet |
```

- [ ] **Step 3: Tests, lieu régénéré, commit**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT"`
Expected:
```
Unitaires : 193001 vérifications
TOUT EST VERT : 998 vérifications
```

```bash
C:/dev/jeux/roblox-maker/rojo.exe build -o AtelierCouture.rbxl
git add README.md AtelierCouture.rbxl
git commit -m "Plan 21 terminé : les étiquettes, données

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```
