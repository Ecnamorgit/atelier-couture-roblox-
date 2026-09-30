# Aiguille & Dentelle — Plan 9 : finitions de l'ampleur

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Traiter les points mineurs reportés par les relectures des plans 8a, 8b et 8c : un col marin et une jupe crayon qui restent hors du corps pour toutes les silhouettes acceptées, des tests qui vérifient vraiment ce qu'ils annoncent, un tirage qui refuse un accessoire inconnu, des annonces de l'accueil qui ne débordent plus, un mariage de Colette fidèle à son histoire, une barre de défilement visible dans le carnet d'adresses, un équilibrage qui borne aussi les parties les plus lentes, un README à jour.

**Architecture:** aucune notion nouvelle ; des retouches dans `Patron` (col marin), `Catalogue` (jupe crayon), `Commandes` (accessoire inconnu), `UiKit` (lignes d'un texte replié) et `EcranAccueil` (hauteur de l'annonce), et des tests renforcés.

**Tech Stack:** Luau, Rojo 7.7.0-rc.1, simulation Luau 0.650 (`tests/lancer.sh`), Roblox Studio via le connecteur MCP Studio.

**Spec:** `docs/superpowers/specs/2026-09-30-ampleur-contenu-design.md` (sous-projet 4) ; ce plan ne change aucune règle. Les points viennent des registres des plans 8a, 8b et 8c (« minor (deferred) »).

## Décisions de ce plan

- **Retenus** (effet pour le joueur ou test qui ne vérifiait rien) : col marin dans le buste aux fortes poitrines ; jupe crayon trop près des jambes aux hanches les plus fines ; test des prestiges 6 à 8 tautologique ; témoin du tirage non comparé au calcul complet ; accessoire inconnu jugé réalisable ; conditions de déblocage qui pourraient s'écraser en silence ; « Nouveau : » sur deux lignes qui chevauche le texte suivant ; croquis en variantes nouvelles jamais validé au carnet par le scénario ; `SEUILS_P` recopiés, variable inutilisée ; récit du mariage de Colette (« au bord du lac », « vous m'aviez promis ») ; barre de défilement du carnet d'adresses de la couleur par défaut ; queue de l'équilibrage non bornée ; README (30 objets, 9 garnitures, douze souvenirs, sous-projet 4 terminé) ; carnet d'adresses à dix clientes jamais vu dans Studio. Vus pendant la préparation, en regardant ce carnet dans Studio : Salomé et Apolline portaient le même nom de famille (Garnier ; Apolline devient Roussel), et un blanc séparait les adresses des souvenirs (texte centré dans son cadre ; il est calé en haut).
- **Laissés** : bustier de 3 dm (il pourrait mesurer 3,2 dm si le test des intrusions bornait sa hauteur : sans effet pour le joueur) ; « +0 » d'amitié et message d'abandon (le scénario n'abandonne pas de commande) ; fourchette du carnet avec les tissus fermés ; incohérences mineures du récit ; le plan 8c parle de 466 px pour « Offrir à… » (442 en panneau : le test mesure la fenêtre réelle, 438 px suffisent).
- **Col marin** : sa largeur suit la poitrine (inchangée en taille M, 8,8 dm) ; il ne descend pas moins dans le dos. Mesuré : 64 points dans le buste à la poitrine de 13 dm avant, aucun après.
- **Jupe crayon** : évasement de −0,04 à −0,025 : aux hanches de 8 dm (le minimum d'une recette), l'ourlet reste à 1,16 dm de l'axe (1,15 exigé) ; elle se resserre encore de 0,09 dm à l'ourlet en taille M (le test en exigeait 0,1, il en exige 0,05).
- **Annonces** : `UiKit.lignes(texte, largeur, taille)` estime les lignes repliées (0,6 fois la taille par caractère) ; « Nouveau : » du prestige 6 (93 caractères) compte pour deux lignes.
- **Vérifié pendant la préparation** : le plan a été joué entièrement sur un brouillon tiré de `main` ; dix variantes du brouillon (col marin de largeur fixe, jupe crayon à −0,04, accessoire inconnu accepté, lignes comptées aux seuls retours, tirage sans essais, tissus parcourus à l'envers, barre de défilement sans couleur, épilogue « au bord du lac », Apolline Garnier, souvenirs centrés) échouent chacune sur la vérification qui les garde ; le col marin, la jupe crayon et le carnet d'adresses à dix clientes ont été regardés dans Studio.

## Global Constraints

- **Dépôt** : `C:\dev\jeux\atelier-couture`, branche `ampleur-finitions`, créée depuis `main` (où le plan 8c est fusionné). Selon les règles du commanditaire : la branche testée et relue est fusionnée dans `main` et poussée sur GitHub.
- **Rojo** : `C:/dev/jeux/roblox-maker/rojo.exe`.
- **Contraintes des plans précédents toujours valables** : fins de ligne LF, commits en français terminés par `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`, textes d'au moins 14 px, le serveur fait foi.

## Review Focus

- **Silhouettes extrêmes (poitrine 7 à 13, hanches 8 à 14).** Attendu : aucun col dans le buste, aucune jupe dans les jambes. Tests : `10_mannequin` (« le col ne traverse pas le buste ») et `03_patron` (« la jupe ne traverse pas les jambes »), sur les tailles et les silhouettes extrêmes.
- **Un accessoire demandé qui n'existe pas (sauvegarde abîmée).** Attendu : irréalisable, comme dans le calcul complet. Test : `54_commandes_rapides`.
- **Une condition de déblocage écrite deux fois (un ajout futur).** Attendu : le test le voit. Test : `45_deblocages`, « aucune condition n'en écrase une autre ».
- **Annonce de trois lignes dont une longue.** Attendu : la hauteur de l'étiquette suit. Test : `55_annonces`.
- **Tirage aux prestiges 6 à 8.** Attendu : de vraies commandes, jamais le repli. Test : `46_deblocages_etat`.

---

### Task 1: Col marin et jupe crayon hors du corps, pour toutes les silhouettes

**Files:**
- Modify: `src/shared/Patron.luau` (col marin), `src/shared/Catalogue.luau` (jupe crayon)
- Modify: `tests/unitaires/10_mannequin.luau`, `03_patron.luau`

**Interfaces:**
- Consumes: `Recette.POITRINE`, `Recette.TAILLE`, `Recette.HANCHES` (silhouettes extrêmes).
- Produces: rien de nouveau (mêmes pièces, géométrie retouchée).

- [ ] **Step 1: Écrire les tests**

Dans `tests/unitaires/10_mannequin.luau`, remplacer :

```lua
	-- Le socle touche le sol
	local socle = formes[#formes]
```

par :

```lua
	-- Aucun point des cols (les deux moitiés) dans le buste : le col marin retombe sur les épaules et dans le dos
	for id, def in pairs(Catalogue.Pieces) do
		if def.enroulement.type == "col" then
			local b = Polygone.boite(def.contour)
			local dedans = 0
			for _, copie in ipairs(Patron.copies(id)) do
				for j = 0, 8 do
					local y = math.min(b.minY + (b.maxY - b.minY) * j / 8, b.maxY)
					local x0, x1 = Polygone.etendueLigne(def.contour, y)
					for i = 0, 8 do
						if dansEllipsoide(Patron.point(id, copie, x0 + (x1 - x0) * i / 8, y, mesures), formes[1]) then
							dedans += 1
						end
					end
				end
			end
			U.verifier(dedans == 0, ("%s (%s) : le col ne traverse pas le buste (%d points dedans)"):format(id, nomTaille, dedans))
		end
	end
	-- Le socle touche le sol
	local socle = formes[#formes]
```

Dans `tests/unitaires/03_patron.luau`, remplacer :

```lua
-- La jupe passe hors des jambes (cylindres de 0,6 dm de rayon à ±0,55 dm) sous la ligne des hanches
for _, taille in pairs(Catalogue.TAILLES) do
```

par :

```lua
-- La jupe passe hors des jambes (cylindres de 0,6 dm de rayon à ±0,55 dm) sous la ligne des hanches, pour les
-- tailles du catalogue et les silhouettes extrêmes acceptées par Recette.valider
local Recette = U.module("Recette")
local silhouettes = table.clone(Catalogue.TAILLES)
for _, P in ipairs({ Recette.POITRINE[1], Recette.POITRINE[2] }) do
	for _, T in ipairs({ Recette.TAILLE[1], Recette.TAILLE[2] }) do
		for _, H in ipairs({ Recette.HANCHES[1], Recette.HANCHES[2] }) do
			if T <= P and T <= H then
				silhouettes[("P%g-T%g-H%g"):format(P, T, H)] = { poitrine = P, taille = T, hanches = H }
			end
		end
	end
end
for _, taille in pairs(silhouettes) do
```

Dans `tests/unitaires/03_patron.luau`, remplacer :

```lua
U.verifier(horizontale(crayonOurlet) < horizontale(crayonHanches) - 0.1 and horizontale(crayonOurlet) < horizontale(droiteOurlet), "jupe crayon : resserrée à l'ourlet, plus que la jupe droite")
```

par :

```lua
U.verifier(horizontale(crayonOurlet) < horizontale(crayonHanches) - 0.05 and horizontale(crayonOurlet) < horizontale(droiteOurlet), "jupe crayon : resserrée à l'ourlet, plus que la jupe droite")
```

- [ ] **Step 2: Lancer les tests, vérifier l'échec**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT|attempt|membre" | head -3`
Expected: échec : une ligne qui finit par `ÉCHEC : jupe_crayon_devant : la jupe ne traverse pas les jambes`

- [ ] **Step 3: La jupe crayon, un peu moins resserrée**

Dans `src/shared/Catalogue.luau`, remplacer :

```lua
	-- Jupe crayon : un évasement négatif la resserre sous les hanches (elle reste hors des jambes)
	jupe_crayon_devant = { nom = "Jupe crayon devant", contour = CRAYON, coutures = { 1, 2, 4 },
		enroulement = { type = "jupe", cote = "devant", evasement = -0.04, fronces = 0 } },
	jupe_crayon_dos = { nom = "Jupe crayon dos", contour = CRAYON, coutures = { 1, 2, 4 },
		enroulement = { type = "jupe", cote = "dos", evasement = -0.04, fronces = 0 } },
```

par :

```lua
	-- Jupe crayon : un évasement négatif la resserre sous les hanches (elle reste hors des jambes, même pour les
	-- hanches les plus fines qu'accepte une recette)
	jupe_crayon_devant = { nom = "Jupe crayon devant", contour = CRAYON, coutures = { 1, 2, 4 },
		enroulement = { type = "jupe", cote = "devant", evasement = -0.025, fronces = 0 } },
	jupe_crayon_dos = { nom = "Jupe crayon dos", contour = CRAYON, coutures = { 1, 2, 4 },
		enroulement = { type = "jupe", cote = "dos", evasement = -0.025, fronces = 0 } },
```

- [ ] **Step 4: Lancer les tests, vérifier l'échec suivant**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT|attempt|membre" | head -3`
Expected: échec : une ligne qui finit par `ÉCHEC : col_marin (P13-T5.5-H8) : le col ne traverse pas le buste (64 points dedans)`

- [ ] **Step 5: Le col marin, qui s'élargit avec la poitrine**

Dans `src/shared/Patron.luau`, remplacer :

```lua
local function col(e, u, v, hauteur, _m)
```

par :

```lua
local function col(e, u, v, hauteur, m)
```

Dans `src/shared/Patron.luau`, remplacer :

```lua
		-- À plat sur les épaules comme le Claudine, mais il retombe de plus en plus vers le milieu du dos
		rayon, y = RAYON_COU + v * hauteur * 0.8, HAUTEUR_COU - v * hauteur * (0.3 + 0.6 * u)
```

par :

```lua
		-- À plat sur les épaules comme le Claudine, mais il retombe de plus en plus vers le milieu du dos ; il s'élargit
		-- avec la poitrine (taille M : 8,8 dm) pour rester hors du buste
		rayon, y = RAYON_COU + v * hauteur * 0.8 * m.poitrine / 8.8, HAUTEUR_COU - v * hauteur * (0.3 + 0.6 * u)
```

- [ ] **Step 6: Lancer les tests**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT"`
Expected:
```
Unitaires : 167616 vérifications
TOUT EST VERT : 737 vérifications
```

- [ ] **Step 7: Commit**

```bash
git add src/shared/Patron.luau src/shared/Catalogue.luau tests/unitaires/10_mannequin.luau tests/unitaires/03_patron.luau
git commit -m "Col marin hors du buste et jupe crayon hors des jambes, pour toutes les silhouettes acceptées

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 2: Des tests qui vérifient ce qu'ils annoncent

Renforcements de tests existants (ils passent dès qu'ils sont écrits : le code est juste) ; les variantes de la préparation montrent qu'ils attrapent chacun la faute qu'ils visent.

**Files:**
- Modify: `tests/unitaires/46_deblocages_etat.luau`, `54_commandes_rapides.luau`, `45_deblocages.luau`, `48_equilibrage.luau`, `tests/scenario.luau`

**Interfaces:**
- Consumes: `Commandes.generer`, `Commandes.realisable`, `Deblocages.CONDITIONS`, `Progression.SEUILS_PRESTIGE`, `Histoire.EVENEMENTS`.
- Produces: rien de nouveau.

- [ ] **Step 1: Renforcer les tests**

Dans `tests/unitaires/46_deblocages_etat.luau`, remplacer :

```lua
-- Plus tard aussi (prestiges 6, 7 et 8, amitié nulle ou au plus haut) : réalisables avec ce qui est ouvert
for _, prestige in ipairs({ 260, 380, 530 }) do
	for _, amitie in ipairs({ 0, 25 }) do
		for _, c in ipairs(Clientes.LISTE) do
			local progres = { prestige = prestige, clientes = { [c.id] = { amitie = amitie } } }
			local ouverts = Deblocages.ouverts(progres)
			local rng = Random.new(prestige + amitie)
			local ratees = 0
			for _ = 1, 10 do
				if not Commandes.realisable(Commandes.generer(rng, c, progres).exigences, ouverts) then
					ratees += 1
				end
			end
			U.verifier(ratees == 0, ("%s au prestige %d, amitié %d : commandes réalisables avec ce qui est ouvert"):format(c.id, prestige, amitie))
		end
	end
end
```

par :

```lua
-- Plus tard aussi (prestiges 6, 7 et 8, amitié nulle ou au plus haut) : le tirage trouve une vraie commande (un
-- « au moins » de 30 ou plus dans un de ses styles), jamais le repli (« au moins » 20 ou 10, ou la qualité seule)
for _, prestige in ipairs({ 260, 380, 530 }) do
	for _, amitie in ipairs({ 0, 25 }) do
		for _, c in ipairs(Clientes.LISTE) do
			local progres = { prestige = prestige, clientes = { [c.id] = { amitie = amitie } } }
			local rng = Random.new(prestige + amitie)
			local replis = 0
			for _ = 1, 10 do
				local premiere = Commandes.generer(rng, c, progres).exigences[1]
				if not (premiere.type == "min" and premiere.valeur >= 30 and table.find(c.styles, premiere.style)) then
					replis += 1
				end
			end
			U.verifier(replis == 0, ("%s au prestige %d, amitié %d : de vraies commandes, sans repli (%d replis)"):format(c.id, prestige, amitie, replis))
		end
	end
end
```

Dans `tests/unitaires/54_commandes_rapides.luau`, remplacer :

```lua
				if Notation.verifierExigences(exigences, bilan) then
					return true
				end
			end
		end
	end
	return false
```

par :

```lua
				if Notation.verifierExigences(exigences, bilan) then
					return true, croquis, t.id
				end
			end
		end
	end
	return false
```

Dans `tests/unitaires/54_commandes_rapides.luau`, remplacer :

```lua
	local ok, temoin = Commandes.realisable(exigences, ouverts)
	if ok ~= reference(exigences, ouverts) then
		differences += 1
	end
	if ok then
```

par :

```lua
	local ok, temoin = Commandes.realisable(exigences, ouverts)
	local okRef, croquisRef, tissuRef = reference(exigences, ouverts)
	if ok ~= okRef then
		differences += 1
	elseif ok and (temoin.tissu ~= tissuRef or temoin.croquis.corsage ~= croquisRef.corsage or temoin.croquis.manches ~= croquisRef.manches or temoin.croquis.col ~= croquisRef.col or temoin.croquis.jupe ~= croquisRef.jupe) then
		temoinsAutres += 1
	end
	if ok then
```

Dans `tests/unitaires/54_commandes_rapides.luau`, remplacer :

```lua
local differences, temoinsFaux = 0, 0
```

par :

```lua
local differences, temoinsFaux, temoinsAutres = 0, 0, 0
```

Dans `tests/unitaires/54_commandes_rapides.luau`, remplacer :

```lua
U.verifier(temoinsFaux == 0, "le témoin remplit toujours les exigences (" .. temoinsFaux .. " faux)")
```

par :

```lua
U.verifier(temoinsFaux == 0, "le témoin remplit toujours les exigences (" .. temoinsFaux .. " faux)")
U.verifier(temoinsAutres == 0, "le témoin est la première robe du calcul complet (" .. temoinsAutres .. " autres)")
```

Dans `tests/unitaires/45_deblocages.luau`, remplacer :

```lua
local SEUILS_P = { 0, 20, 50, 100, 170, 260, 380, 530 }
```

par :

```lua
local SEUILS_P = U.module("Progression").SEUILS_PRESTIGE
```

Dans `tests/unitaires/45_deblocages.luau`, remplacer :

```lua
U.verifier(not Deblocages.toutOuvert(depart), "au départ : pas tout")
```

par :

```lua
U.verifier(not Deblocages.toutOuvert(depart), "au départ : pas tout")
-- Aucune condition n'en écrase une autre : autant de conditions que de sources (matières du prestige, décorations
-- et variantes du prestige, amitiés, souvenirs)
local sources = #U.module("Histoire").EVENEMENTS
for _, t in ipairs(Catalogue.Tissus) do
	if Deblocages.PRESTIGE_MATIERES[t.matiere] then
		sources += 1
	end
end
for _, liste in ipairs({ Deblocages.PRESTIGE_ACCESSOIRES, Deblocages.PRESTIGE_VARIANTES }) do
	for _ in pairs(liste) do
		sources += 1
	end
end
for _, c in ipairs(Clientes.LISTE) do
	for _ in pairs(c.deblocages) do
		sources += 1
	end
end
local conditions = 0
for _, genre in ipairs(Deblocages.GENRES) do
	for _ in pairs(Deblocages.CONDITIONS[genre]) do
		conditions += 1
	end
end
U.verifier(conditions == sources, ("aucune condition n'en écrase une autre (%d conditions, %d sources)"):format(conditions, sources))
```

Dans `tests/unitaires/48_equilibrage.luau`, remplacer :

```lua
local p8, medianeP8 = serie("prestige8")
```

par :

```lua
local _, medianeP8 = serie("prestige8")
```

Dans `tests/scenario.luau`, remplacer :

```lua
for _, v in pairs(croquisNouveau) do
	cliquer("Variante_" .. v)
	verifier(boutonNomme("Variante_" .. v).BackgroundColor3 == Color3.fromRGB(214, 76, 128), v .. " choisie au carnet")
end
```

par :

```lua
for _, v in pairs(croquisNouveau) do
	cliquer("Variante_" .. v)
	verifier(boutonNomme("Variante_" .. v).BackgroundColor3 == Color3.fromRGB(214, 76, 128), v .. " choisie au carnet")
end
cliquer("Tissu_corsage_cache_coeur_devant")
cliquer("Tissu_toile_jute")
cliquer("ToutEnUnTissu")
cliquer("Valider")
do
	local croquisServeur = serveur:atelier(joueur).etat.croquis
	verifier(titre() == "2. Achat du tissu" and croquisServeur.corsage == "corsage_cache_coeur" and croquisServeur.manches == "manches_trois_quarts" and croquisServeur.col == "col_marin" and croquisServeur.jupe == "jupe_crayon", "croquis en variantes nouvelles validé au carnet : le serveur l'accepte")
end
```

- [ ] **Step 2: Lancer les tests**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT"`
Expected:
```
Unitaires : 167618 vérifications
TOUT EST VERT : 742 vérifications
```

- [ ] **Step 3: Commit**

```bash
git add tests/unitaires/46_deblocages_etat.luau tests/unitaires/54_commandes_rapides.luau tests/unitaires/45_deblocages.luau tests/unitaires/48_equilibrage.luau tests/scenario.luau
git commit -m "Tests renforcés : tirage sans repli, témoin comparé au calcul complet, conditions jamais écrasées, croquis nouveau validé au carnet

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 3: Accessoire inconnu, annonces longues

**Files:**
- Modify: `src/shared/Commandes.luau` (`realisable`), `src/client/Atelier/UiKit.luau` (`UiKit.lignes`), `src/client/Atelier/EcranAccueil.luau` (hauteur de l'annonce)
- Modify: `tests/unitaires/54_commandes_rapides.luau`
- Create: `tests/unitaires/55_annonces.luau`

**Interfaces:**
- Consumes: `Deblocages.resume`, `Deblocages.nouveaux`.
- Produces: `UiKit.lignes(texte, largeur, taille) -> number`.

- [ ] **Step 1: Écrire les tests**

Dans `tests/unitaires/54_commandes_rapides.luau`, remplacer :

```lua
U.verifier(temoinsAutres == 0, "le témoin est la première robe du calcul complet (" .. temoinsAutres .. " autres)")
```

par :

```lua
U.verifier(temoinsAutres == 0, "le témoin est la première robe du calcul complet (" .. temoinsAutres .. " autres)")
U.verifier(not Commandes.realisable({ { type = "accessoire", id = "inconnu" } }), "un accessoire inconnu : irréalisable, comme dans le calcul complet")
```

Créer `tests/unitaires/55_annonces.luau` :

```lua
-- Les annonces de l'accueil (sous-projet 4 : « Nouveau : » s'allonge aux prestiges 6 à 8) : leur hauteur compte les
-- lignes repliées, pas seulement les retours à la ligne
local UiKit = U.module("UiKit")
local Deblocages = U.module("Deblocages")
local S = U.module("Progression").SEUILS_PRESTIGE

local nouveau6 = "Nouveau : " .. Deblocages.resume(Deblocages.nouveaux({ prestige = S[6] - 1, clientes = {} }, { prestige = S[6], clientes = {} })) .. "."
U.verifier(UiKit.lignes("Robe livrée !", 860, 18) == 1, "une ligne courte : une ligne")
U.verifier(UiKit.lignes("Robe livrée !\nPrestige : +12", 860, 18) == 2, "un retour à la ligne : deux lignes")
U.verifier(UiKit.lignes(nouveau6, 860, 18) == 2, "« Nouveau : » du prestige 6 (" .. utf8.len(nouveau6) .. " caractères) : deux lignes")
U.verifier(UiKit.lignes("Robe livrée !\n" .. nouveau6, 860, 18) == 3, "une ligne courte et une longue : trois lignes")
```

- [ ] **Step 2: Lancer les tests, vérifier l'échec**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT|attempt|membre" | head -3`
Expected: échec : une ligne qui finit par `ÉCHEC : un accessoire inconnu : irréalisable, comme dans le calcul complet`

- [ ] **Step 3: Écrire le code**

Dans `src/shared/Commandes.luau`, remplacer :

```lua
	if ouverts and accessoireImpose and not ouverts.accessoires[accessoireImpose] then
		return false
	end
	-- Les exigences les plus fermées d'abord
```

par :

```lua
	if accessoireImpose and (not Catalogue.accessoire(accessoireImpose) or (ouverts and not ouverts.accessoires[accessoireImpose])) then
		return false
	end
	-- Les exigences les plus fermées d'abord
```

Dans `src/client/Atelier/UiKit.luau`, remplacer :

```lua
function UiKit.texte(props)
```

par :

```lua
-- Nombre de lignes d'un texte replié dans une largeur (px) à une taille de police donnée : estimation prudente
-- (0,6 fois la taille par caractère, en moyenne), en comptant aussi les retours à la ligne
function UiKit.lignes(texte, largeur, taille)
	local parLigne = math.max(1, math.floor(largeur / (taille * 0.6)))
	local n = 0
	for ligne in (texte .. "\n"):gmatch("(.-)\n") do
		n += math.max(1, math.ceil((utf8.len(ligne) or #ligne) / parLigne))
	end
	return n
end

function UiKit.texte(props)
```

Dans `src/client/Atelier/EcranAccueil.luau`, remplacer :

```lua
		local _, retours = annonce:gsub("\n", "")
		local hauteur = 24 * (retours + 1) + 2
```

par :

```lua
		local hauteur = 24 * UiKit.lignes(annonce, UiKit.LARGEUR - 40, 18) + 2 -- (« Nouveau : » peut tenir sur deux lignes)
```

- [ ] **Step 4: Lancer les tests**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT"`
Expected:
```
Unitaires : 167623 vérifications
TOUT EST VERT : 742 vérifications
```

- [ ] **Step 5: Commit**

```bash
git add src/shared/Commandes.luau src/client/Atelier/UiKit.luau src/client/Atelier/EcranAccueil.luau tests/unitaires/54_commandes_rapides.luau tests/unitaires/55_annonces.luau
git commit -m "Accessoire inconnu irréalisable ; l'annonce de l'accueil compte ses lignes repliées

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 4: Le récit, les noms, le carnet d'adresses, les parties les plus lentes

**Files:**
- Modify: `src/shared/Histoire.luau` (mariage de Colette), `src/shared/Clientes.luau` (nom d'Apolline), `src/client/Atelier/EcranAccueil.luau` (barre de défilement, souvenirs calés en haut)
- Modify: `tests/unitaires/52_histoire.luau`, `42_clientes.luau`, `48_equilibrage.luau`, `tests/scenario.luau`

**Interfaces:**
- Consumes: `Histoire.get`, `Histoire.commande`, `CarnetAdresses.Liste` (plan 8c).
- Produces: rien de nouveau.

La borne de l'équilibrage est une caractérisation (18 parties sur 20 ouvrent tout avant la 160e robe ; elle en exige 16) : elle passe dès qu'elle est écrite.

- [ ] **Step 1: Écrire les tests**

Dans `tests/unitaires/52_histoire.luau`, remplacer :

```lua
U.verifier(joueuses.apolline and joueuses.josephine and joueuses.capucine and joueuses.maelle, "les quatre nouvelles clientes jouent dans les événements 9 à 12")
```

par :

```lua
U.verifier(joueuses.apolline and joueuses.josephine and joueuses.capucine and joueuses.maelle, "les quatre nouvelles clientes jouent dans les événements 9 à 12")
-- Le mariage de Colette répond à son histoire : tout a commencé au bal des lanternes, sur le square ; au bal
-- d'hiver, elle avait demandé sa robe (on ne la lui avait pas promise)
local noces = Histoire.get("noces_colette")
local demandeNoces = Histoire.commande("noces_colette").repliques.demande
U.verifier(string.find(noces.epilogue, "lanternes", 1, true) ~= nil and string.find(noces.epilogue, "lac", 1, true) == nil and string.find(demandeNoces, "promis", 1, true) == nil and string.find(demandeNoces, "bal d'hiver", 1, true) ~= nil, "le mariage de Colette répond à son histoire (les lanternes du square, la robe demandée au bal d'hiver)")
```

Dans `tests/scenario.luau`, remplacer :

```lua
	verifier(liste ~= nil and liste:IsA("ScrollingFrame") and bas > 0 and (if liste.CanvasSize then liste.CanvasSize.Y.Offset else 0) >= bas and liste:FindFirstChild("Adresse_maelle") ~= nil and texte("Le grand défilé du quartier — souvenir : Rosette d'honneur") ~= nil, "dix clientes et douze souvenirs : le carnet d'adresses défile jusqu'au dernier")
```

par :

```lua
	verifier(liste ~= nil and liste:IsA("ScrollingFrame") and bas > 0 and (if liste.CanvasSize then liste.CanvasSize.Y.Offset else 0) >= bas and liste:FindFirstChild("Adresse_maelle") ~= nil and texte("Le grand défilé du quartier — souvenir : Rosette d'honneur") ~= nil, "dix clientes et douze souvenirs : le carnet d'adresses défile jusqu'au dernier")
	verifier(liste.ScrollBarImageColor3 == requireModule(scriptClient.UiKit).COULEURS.accent, "la barre de défilement du carnet d'adresses se voit (couleur d'accent, comme les onglets)")
```

Dans `tests/unitaires/48_equilibrage.luau`, remplacer :

```lua
U.verifier(medianeInvitees >= 10, "le courrier fait venir des clientes (" .. bilan .. ")")
```

par :

```lua
local toutAvantLaFin = 0
for _, n in ipairs(tout) do
	if n <= ROBES then
		toutAvantLaFin += 1
	end
end
U.verifier(toutAvantLaFin >= 16, ("au moins 16 parties sur 20 ouvrent tout avant la %de robe (%d) (%s)"):format(ROBES, toutAvantLaFin, bilan))
U.verifier(medianeInvitees >= 10, "le courrier fait venir des clientes (" .. bilan .. ")")
```

Dans `tests/unitaires/42_clientes.luau`, remplacer :

```lua
U.verifier(#Clientes.LISTE == 10, "dix clientes")
```

par :

```lua
U.verifier(#Clientes.LISTE == 10, "dix clientes")
-- Dix noms de famille différents (le carnet d'adresses les montre les uns sous les autres)
local familles = {}
for _, c in ipairs(Clientes.LISTE) do
	local famille = c.nom:match("%s(.+)$")
	U.verifier(famille ~= nil and not familles[famille], c.id .. " : un nom de famille à elle (" .. tostring(famille) .. ")")
	familles[famille or c.id] = true
end
```

Dans `tests/scenario.luau`, remplacer :

```lua
	verifier(liste.ScrollBarImageColor3 == requireModule(scriptClient.UiKit).COULEURS.accent, "la barre de défilement du carnet d'adresses se voit (couleur d'accent, comme les onglets)")
```

par :

```lua
	verifier(liste.ScrollBarImageColor3 == requireModule(scriptClient.UiKit).COULEURS.accent, "la barre de défilement du carnet d'adresses se voit (couleur d'accent, comme les onglets)")
	verifier(liste.Souvenirs.TextYAlignment == Enum.TextYAlignment.Top, "les souvenirs commencent juste sous les adresses (texte calé en haut)")
```

- [ ] **Step 2: Lancer les tests, vérifier l'échec**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT|attempt|membre" | head -3`
Expected: échec : une ligne qui finit par `ÉCHEC : apolline : un nom de famille à elle (Garnier)`

- [ ] **Step 3: Écrire le code**

Dans `src/shared/Histoire.luau`, remplacer :

```lua
		epilogue = "Colette a dit oui au bord du lac, là où tout avait commencé. Margot a pleuré plus fort que tout le monde, et Apolline a lu le poème qu'elle leur avait écrit.",
```

par :

```lua
		epilogue = "Colette a dit oui sous les lanternes du square, là où tout avait commencé. Margot a pleuré plus fort que tout le monde, et Apolline a lu le poème qu'elle leur avait écrit.",
```

Dans `src/shared/Histoire.luau`, remplacer :

```lua
				"Ça y est, c'est bientôt le grand jour ! Et vous m'aviez promis ma robe, vous vous souvenez ?",
```

par :

```lua
				"Ça y est, c'est bientôt le grand jour ! Vous vous souvenez ? Au bal d'hiver, je vous ai demandé ma robe.",
```

Dans `src/client/Atelier/EcranAccueil.luau`, remplacer :

```lua
ScrollBarThickness = 10, ScrollingDirection
```

par :

```lua
ScrollBarThickness = 10, ScrollBarImageColor3 = C.accent, ScrollingDirection
```

Dans `src/shared/Clientes.luau`, remplacer :

```lua
		nom = "Apolline Garnier",
```

par :

```lua
		nom = "Apolline Roussel",
```

Dans `src/client/Atelier/EcranAccueil.luau`, remplacer :

```lua
Size = UDim2.new(1, -14, 0, 22 * (#passes + 1)), ZIndex = 21, Parent = liste })
```

par :

```lua
Size = UDim2.new(1, -14, 0, 22 * (#passes + 1)), TextYAlignment = Enum.TextYAlignment.Top, ZIndex = 21, Parent = liste })
```

- [ ] **Step 4: Lancer les tests**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT"`
Expected:
```
Unitaires : 167635 vérifications
TOUT EST VERT : 744 vérifications
```

- [ ] **Step 5: Commit**

```bash
git add src/shared/Histoire.luau src/shared/Clientes.luau src/client/Atelier/EcranAccueil.luau tests/unitaires/52_histoire.luau tests/unitaires/42_clientes.luau tests/unitaires/48_equilibrage.luau tests/scenario.luau
git commit -m "Le mariage de Colette fidèle à son histoire ; Apolline Roussel ; carnet d'adresses plus lisible ; l'équilibrage borne les parties les plus lentes

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 5: Studio, README, lieu régénéré

**Files:**
- Modify: `README.md`, `AtelierCouture.rbxl` (régénéré)

**Interfaces:**
- Consumes: tout ce qui précède.
- Produces: rien de nouveau.

- [ ] **Step 1: Dans Studio, par le connecteur MCP**

Construire le lieu du dépôt dans un dossier temporaire (`C:/dev/jeux/roblox-maker/rojo.exe build -o <dossier temporaire>/Plan9Depot.rbxl`) et l'ouvrir dans Studio.

En mode édition, par `execute_luau` : dans un dossier de `workspace`, construire deux mannequins et deux robes (corsage droit, sans manches, col marin, jupe crayon, coton blanc), l'une aux mesures de la taille M, l'autre à la poitrine de 12 dm (taille 9, hanches 12) ; les regarder de dos par `screen_capture`, puis détruire le dossier. Puis afficher l'accueil hors partie : un `ScreenGui` dans `StarterGui` avec une fenêtre de 900 × 560 px et son contenu de 860 × 466 px, l'écran `EcranAccueil` (module sous `StarterPlayer.StarterPlayerScripts.Atelier`) appelé avec un contexte de test (`UiKit`, ce contenu, cette fenêtre, `message` et `refus` qui ne font rien, une session dont l'état est `EtatAtelier.nouveau(1000)` avec dix fiches de clientes venues, cinq livraisons et les douze événements passés) ; rendre `CarnetAdresses` visible, faire défiler `Liste` jusqu'en bas (`CanvasPosition`), regarder par `screen_capture`, puis détruire le `ScreenGui`.

En Play : attendre 4 s, appuyer sur E, relever le titre et la console.

Expected : le col marin retombe dans le dos sans entrer dans le buste, plus large sur la forte poitrine ; la jupe crayon resserrée à l'ourlet ; le carnet d'adresses montre les dix clientes, défile jusqu'aux douze souvenirs, sa barre de défilement se voit ; en Play, « Les mesures » ; aucune alerte de notre code (« Lieu non publié » et les messages internes de Roblox mis à part). Arrêter Play et fermer cette fenêtre de Studio (sans enregistrer).

- [ ] **Step 2: Mettre à jour le README**

Dans `README.md`, remplacer :

```markdown
## État actuel (sous-projet 3 terminé côté code, plan 6 : l'histoire et les événements du quartier)
```

par :

```markdown
## État actuel (sous-projet 4 terminé côté code, plans 8a à 9 : l'ampleur du catalogue et du quartier)
```

Dans `README.md`, remplacer :

```markdown
7. **Décorations** : 23 objets (boutons, nœuds, fleurs, broches, perles, étoile, croix, couronne, et les huit
   souvenirs du quartier une fois leur événement passé) et 8 garnitures (dentelles, rubans, galons).
```

par :

```markdown
7. **Décorations** : 30 objets (boutons, nœuds, fleurs, broches, perles, étoile, croix, couronne, violette,
   boucle, coquillage, et les douze souvenirs du quartier une fois leur événement passé) et 9 garnitures
   (dentelles, rubans, galons).
```

- [ ] **Step 3: Tests, lieu régénéré, commit**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT"`
Expected:
```
Unitaires : 167635 vérifications
TOUT EST VERT : 744 vérifications
```

```bash
C:/dev/jeux/roblox-maker/rojo.exe build -o AtelierCouture.rbxl
git add README.md AtelierCouture.rbxl
git commit -m "Plan 9 terminé : finitions de l'ampleur

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```
