# Aiguille & Dentelle — Plan 8a : tissus, décorations et rapidité

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Premier plan du sous-projet 4 (l'ampleur du catalogue) : un tirage des commandes qui ne recalcule plus les styles robe par robe (le catalogue va grandir), seize tissus en quatre matières de fin de partie (crêpe et organza au prestige 6, brocart au 7, tulle au 8), huit décorations aux prestiges 5 à 8, et une simulation d'équilibrage qui suit le prestige 8.

**Architecture:**
- **Commandes** : les points de style de chaque croquis, de chaque tissu et de chaque objet imposé sont précalculés (les styles s'additionnent) ; `realisable` juge une robe candidate par quelques additions, avec les mêmes réponses que le calcul complet.
- **Catalogue et déblocages** : quatre matières (rendu dans `Catalogue.MATIERES`), seize tissus, huit accessoires ; `Deblocages.PRESTIGE_MATIERES` et `PRESTIGE_ACCESSOIRES` complétés : chaque niveau de 2 à 8 ouvre quelque chose.
- **Équilibrage** : la simulation mesure aussi le prestige 8.

**Tech Stack:** Luau, Rojo 7.7.0-rc.1, simulation Luau 0.650 (`tests/lancer.sh`), Roblox Studio via le connecteur MCP Studio.

**Spec:** `docs/superpowers/specs/2026-09-30-ampleur-contenu-design.md` (sous-projet 4, commitée avec ce plan : §2 tissus, §3 accessoires (les huit du prestige), §6 rapidité, §7 équilibrage, §9 plan 8a).

## Décisions de ce plan

- **Rapidité** : la simulation remplace l'horloge (`os.clock` y est simulée) : on ne peut pas y chronométrer. Le critère devient structurel : aucun calcul complet des styles au tirage (on compte les appels à `Notation.styles`), et les réponses sont identiques au calcul complet sur mille jeux d'exigences tirés au hasard (y compris des impossibles et plusieurs accessoires demandés). Mesuré : l'ancien tirage faisait 707 143 calculs complets pour 200 commandes ; la suite passe de 31 s à 12 s. Une vérification ciblée s'y ajoute : une garniture imposée, sans longueur, ne compte pas dans les styles (le tirage au hasard ne l'attrapait pas).
- **Tissus** (spec §2) : crêpe (18 à 20 po/m, élégant et chic), organza (18 à 22, romantique et mignon), brocart (22 à 26, élégant avec du gothique ou du chic), tulle (20 à 24, romantique) ; motifs des types existants ; rangés avant la toile de jute (l'étagère de la boutique montre toujours les douze premiers). Rendu : crêpe et tulle en tissu, organza et brocart lisses et un peu brillants.
- **Décorations** (spec §3) : nœud doré et perle noire (prestige 5), papillon de soie et galon argenté (6), broche étoile et ruban de velours (7), couronne de fleurs et dentelle dorée (8). Les quatre décorations d'amitié du §3 arrivent avec les nouvelles clientes (plan 8c).
- **« Tout ouvert »** demande maintenant le prestige 8 : la simulation (vingt parties) mesure « tout ouvert » vers la 66e robe en médiane (62 avant), toujours dans la cible de 50 à 80, et le prestige 8 vers la 58e ; une nouvelle vérification exige le prestige 8 vers la 70e robe au plus tard, en médiane.
- **Vérifié pendant la préparation** : le plan a été joué entièrement sur un brouillon tiré de `main` ; huit variantes du brouillon (accessoire demandé ignoré, teinte ignorée, garniture imposée comptée dans les styles, crêpe au prestige 5, tulle au 7, couronne de fleurs au 7, papillon de soie sans prestige, brocart trop cher) échouent chacune sur la vérification qui les garde. Le bornage des scores de 0 à 100 est gardé par fidélité au calcul complet : aucune exigence (de 0 à 100) ne le rend visible.

## Global Constraints

- **Dépôt** : `C:\dev\jeux\atelier-couture`, branche `ampleur-tissus`, créée depuis `main` (où le plan 7 est fusionné). Selon les règles du commanditaire : la branche testée et relue est fusionnée dans `main` et poussée sur GitHub.
- **Rojo** : `C:/dev/jeux/roblox-maker/rojo.exe`.
- **Contraintes des plans précédents toujours valables** : fins de ligne LF, commits en français terminés par `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`, textes d'au moins 14 px, le serveur fait foi.
- **Contenu original** : aucun nom ni motif de Dressmaker.

## Review Focus

- **Exigences farfelues ou contradictoires au tirage** (deux accessoires, deux teintes, qualité 1). Attendu : même réponse que le calcul complet. Test : `54_commandes_rapides`, « mille jeux d'exigences : même réponse que le calcul complet ».
- **Garniture imposée par une commande** (sans longueur). Attendu : elle ne compte pas dans les styles, comme dans `Notation.styles`. Test : `54_commandes_rapides` (la référence le vérifie sur les mille jeux).
- **Un niveau de prestige qui n'ouvrirait rien.** Attendu : jamais, de 2 à 8. Test : `45_deblocages`, « le prestige N ouvre quelque chose ».
- **Commandes d'une cliente au prestige 6 à 8.** Attendu : toujours réalisables avec ce qui est ouvert. Test : `46_deblocages_etat` et `06_commandes` (inchangés, sur le catalogue agrandi).
- **Économie avec des tissus plus chers.** Attendu : l'argent ne descend jamais sous le prix d'une robe simple. Test : `48_equilibrage`.

---

### Task 1: Un tirage des commandes rapide

**Files:**
- Modify: `src/shared/Commandes.luau` (`realisable`)
- Create: `tests/unitaires/54_commandes_rapides.luau`

**Interfaces:**
- Consumes: `Catalogue.K`, `Catalogue.STYLES`, `Catalogue.FAMILLES`, `Catalogue.variante`, `Catalogue.Tissus`, `Catalogue.accessoire`.
- Produces: `Commandes.realisable(exigences, ouverts?)` inchangée pour ses appelants (mêmes réponses, même témoin), sans appel à `Notation.styles`.

- [ ] **Step 1: Écrire les tests**

Créer `tests/unitaires/54_commandes_rapides.luau` :

```lua
-- Le tirage des commandes reste juste et rapide avec un grand catalogue (sous-projet 4)
local Commandes = U.module("Commandes")
local Catalogue = U.module("Catalogue")
local Notation = U.module("Notation")
local Deblocages = U.module("Deblocages")
local Clientes = U.module("Clientes")
local Progression = U.module("Progression")

-- La référence : le calcul complet (Notation.styles et Notation.verifierExigences) sur chaque robe simple
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
local function reference(exigences, ouverts)
	local impose
	for _, e in ipairs(exigences) do
		if e.type == "accessoire" then
			impose = e.id
		elseif e.type == "qualite" and e.valeur > 0.9 then
			return false
		end
	end
	if ouverts and impose and not ouverts.accessoires[impose] then
		return false
	end
	for _, croquis in ipairs(CROQUIS) do
		for _, t in ipairs(Catalogue.Tissus) do
			local permis = not ouverts or (ouverts.tissus[t.id] and ouverts.variantes[croquis.corsage] and ouverts.variantes[croquis.manches] and ouverts.variantes[croquis.col] and ouverts.variantes[croquis.jupe])
			if permis then
				local bilan = {
					styles = Notation.styles({ croquis = croquis, tissus = { [t.id] = 1 }, accessoires = impose and { { id = impose } } or {} }),
					qualite = 1,
					teinte = t.teinte,
					accessoires = impose and { [impose] = 1 } or {},
				}
				if Notation.verifierExigences(exigences, bilan) then
					return true
				end
			end
		end
	end
	return false
end

-- Mille jeux d'exigences tirés au hasard (dont des impossibles), avec ou sans restriction : même réponse que la
-- référence, et le témoin remplit bien les exigences
local rng = Random.new(54)
local objets = {}
for _, a in ipairs(Catalogue.Accessoires) do
	table.insert(objets, a.id)
end
local PROGRES = {
	{ prestige = 0, clientes = {} },
	{ prestige = 100, clientes = { colette = { amitie = 7 } } },
	{ prestige = 530, clientes = {} },
}
local differences, temoinsFaux = 0, 0
for n = 1, 1000 do
	local exigences = {}
	for _ = 1, rng:NextInteger(1, 3) do
		local genre = rng:NextInteger(1, 5)
		if genre == 1 then
			table.insert(exigences, { type = "min", style = Catalogue.STYLES[rng:NextInteger(1, 6)], valeur = rng:NextInteger(1, 9) * 10 })
		elseif genre == 2 then
			table.insert(exigences, { type = "max", style = Catalogue.STYLES[rng:NextInteger(1, 6)], valeur = rng:NextInteger(0, 5) * 10 })
		elseif genre == 3 then
			table.insert(exigences, { type = "teinte", teinte = Catalogue.TEINTES[rng:NextInteger(1, #Catalogue.TEINTES)] })
		elseif genre == 4 then
			table.insert(exigences, { type = "accessoire", id = objets[rng:NextInteger(1, #objets)] })
		else
			table.insert(exigences, { type = "qualite", valeur = rng:NextInteger(5, 10) / 10 })
		end
	end
	local ouverts = if n % 4 == 0 then nil else Deblocages.ouverts(PROGRES[n % 3 + 1])
	local ok, temoin = Commandes.realisable(exigences, ouverts)
	if ok ~= reference(exigences, ouverts) then
		differences += 1
	end
	if ok then
		local bilan = {
			styles = Notation.styles({ croquis = temoin.croquis, tissus = { [temoin.tissu] = 1 }, accessoires = temoin.accessoire and { { id = temoin.accessoire } } or {} }),
			qualite = 0.9,
			teinte = Catalogue.tissu(temoin.tissu).teinte,
			accessoires = temoin.accessoire and { [temoin.accessoire] = 1 } or {},
		}
		if not Notation.verifierExigences(exigences, bilan) then
			temoinsFaux += 1
		end
	end
end
U.verifier(differences == 0, "mille jeux d'exigences : même réponse que le calcul complet (" .. differences .. " différences)")
U.verifier(temoinsFaux == 0, "le témoin remplit toujours les exigences (" .. temoinsFaux .. " faux)")

-- Une garniture imposée (sans longueur) ne compte pas dans les styles : avec chaque garniture, on demande un peu
-- plus que le meilleur score d'une robe simple dans un style qu'elle porte ; aucune robe ne l'atteint
local meilleur = {}
for _, s in ipairs(Catalogue.STYLES) do
	meilleur[s] = 0
end
for _, croquis in ipairs(CROQUIS) do
	for _, t in ipairs(Catalogue.Tissus) do
		for s, v in pairs(Notation.styles({ croquis = croquis, tissus = { [t.id] = 1 } })) do
			meilleur[s] = math.max(meilleur[s], v)
		end
	end
end
local essais, comptees = 0, {}
for _, a in ipairs(Catalogue.Accessoires) do
	if a.genre == "garniture" then
		for s, pts in pairs(a.style) do
			if pts > 0 and meilleur[s] < 100 then
				essais += 1
				if Commandes.realisable({ { type = "accessoire", id = a.id }, { type = "min", style = s, valeur = meilleur[s] + 0.01 } }) then
					table.insert(comptees, a.id .. " (" .. s .. ")")
				end
			end
		end
	end
end
U.verifier(essais > 0 and #comptees == 0, "une garniture imposée ne compte pas dans les styles (" .. essais .. " essais ; comptées : " .. table.concat(comptees, ", ") .. ")")

-- Rapide : deux cents commandes tirées, tout ouvert, sans recalculer les styles robe par robe (la simulation ne
-- mesure pas le temps réel : on compte les appels au calcul complet)
local tout = { prestige = 530, clientes = {} }
for _, c in ipairs(Clientes.LISTE) do
	tout.clientes[c.id] = { amitie = 25 }
end
local appels = 0
local complet = Notation.styles
Notation.styles = function(...)
	appels += 1
	return complet(...)
end
local rngT = Random.new(7)
for n = 1, 200 do
	Commandes.generer(rngT, Clientes.LISTE[n % #Clientes.LISTE + 1], tout)
end
Notation.styles = complet
U.verifier(appels == 0, "deux cents commandes tirées sans recalculer les styles robe par robe (" .. appels .. " calculs complets)")
U.verifier(Progression.niveauPrestige(530) == 8, "(prestige 8)")
```

- [ ] **Step 2: Lancer les tests, vérifier l'échec**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT|attempt|membre" | head -3`
Expected: échec : une ligne qui finit par `ÉCHEC : deux cents commandes tirées sans recalculer les styles robe par robe (707143 calculs complets)`

- [ ] **Step 3: Écrire le code**

Dans `src/shared/Commandes.luau`, remplacer :

```lua
local CROQUIS = croquisPossibles()
```

par :

```lua
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
```

Dans `src/shared/Commandes.luau`, remplacer :

```lua
	local accessoires = accessoireImpose and { { id = accessoireImpose } } or {}
	for _, croquis in ipairs(CROQUIS) do
		for _, t in ipairs(Catalogue.Tissus) do
			local permis = not ouverts
				or (ouverts.tissus[t.id] and ouverts.variantes[croquis.corsage] and ouverts.variantes[croquis.manches] and ouverts.variantes[croquis.col] and ouverts.variantes[croquis.jupe])
			local bilan = permis and {
				styles = Notation.styles({ croquis = croquis, tissus = { [t.id] = 1 }, accessoires = accessoires }),
				qualite = 1,
				teinte = t.teinte,
				accessoires = accessoireImpose and { [accessoireImpose] = 1 } or {},
			}
			if bilan and Notation.verifierExigences(exigences, bilan) then
				return true, { croquis = croquis, tissu = t.id, accessoire = accessoireImpose }
			end
		end
	end
	return false
```

par :

```lua
	-- Styles, teinte et accessoires à vérifier (la qualité, au plus 0,9, est tenue d'office ; seul le dernier
	-- accessoire demandé est posé sur la robe témoin)
	local aVerifier = {}
	for _, e in ipairs(exigences) do
		if e.type ~= "qualite" then
			table.insert(aVerifier, e)
		end
	end
	local pa = pointsImpose(accessoireImpose)
	for i, croquis in ipairs(CROQUIS) do
		if not ouverts or (ouverts.variantes[croquis.corsage] and ouverts.variantes[croquis.manches] and ouverts.variantes[croquis.col] and ouverts.variantes[croquis.jupe]) then
			local pc = POINTS_CROQUIS[i]
			for _, t in ipairs(Catalogue.Tissus) do
				if not ouverts or ouverts.tissus[t.id] then
					local pt = POINTS_TISSU[t.id]
					local ok = true
					for _, e in ipairs(aVerifier) do
						if e.type == "teinte" then
							ok = t.teinte == e.teinte
						elseif e.type == "accessoire" then
							ok = e.id == accessoireImpose
						else
							local v = math.clamp(pc[e.style] + pt[e.style] + pa[e.style], 0, 100)
							ok = if e.type == "min" then v >= e.valeur - 1e-9 else v <= e.valeur + 1e-9
						end
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
	end
	return false
```

- [ ] **Step 4: Lancer les tests**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT"`
Expected:
```
Unitaires : 107933 vérifications
TOUT EST VERT : 711 vérifications
```

- [ ] **Step 5: Commit**

```bash
git add src/shared/Commandes.luau tests/unitaires/54_commandes_rapides.luau
git commit -m "Tirage des commandes rapide : points de style précalculés, mêmes réponses que le calcul complet

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 2: Quatre matières de fin de partie

**Files:**
- Modify: `src/shared/Catalogue.luau` (tissus, `MATIERES`), `src/shared/Deblocages.luau` (`PRESTIGE_MATIERES`)
- Modify: `tests/unitaires/02_catalogue.luau`, `45_deblocages.luau`

**Interfaces:**
- Consumes: `tissu(id, nom, matiere, teinte, prix, motif, style)` (catalogue).
- Produces: seize tissus (`crepe_*`, `organza_*`, `brocart_*`, `tulle_*`) ; matières `crepe`, `organza`, `brocart`, `tulle` ; `PRESTIGE_MATIERES` : crêpe et organza 6, brocart 7, tulle 8.

- [ ] **Step 1: Écrire les tests**

Dans `tests/unitaires/02_catalogue.luau`, remplacer :

```lua
U.verifier(#Catalogue.Tissus == 25, "25 tissus (dont la toile de jute)")
```

par :

```lua
U.verifier(#Catalogue.Tissus == 41, "41 tissus (dont la toile de jute et quatre matières de fin de partie)")
```

Dans `tests/unitaires/02_catalogue.luau`, remplacer :

```lua
	U.verifier((t.prix >= 4 and t.prix <= 20) or (t.id == "toile_jute" and t.prix == 0), t.id .. " : prix entre 4 et 20 (la toile de jute est gratuite)")
```

par :

```lua
	U.verifier((t.prix >= 4 and t.prix <= 26) or (t.id == "toile_jute" and t.prix == 0), t.id .. " : prix entre 4 et 26 (la toile de jute est gratuite)")
```

Dans `tests/unitaires/45_deblocages.luau`, remplacer :

```lua
U.verifier(Deblocages.ouvert(au(100), "tissus", "velours_noir") and not Deblocages.ouvert(au(100), "tissus", "soie_rouge") and Deblocages.ouvert(au(170), "tissus", "soie_rouge"), "velours au 4, soies au 5")
```

par :

```lua
U.verifier(Deblocages.ouvert(au(100), "tissus", "velours_noir") and not Deblocages.ouvert(au(100), "tissus", "soie_rouge") and Deblocages.ouvert(au(170), "tissus", "soie_rouge"), "velours au 4, soies au 5")
U.verifier(not Deblocages.ouvert(au(259), "tissus", "crepe_noir") and Deblocages.ouvert(au(260), "tissus", "crepe_noir") and Deblocages.ouvert(au(260), "tissus", "organza_blanc"), "crêpe et organza au prestige 6")
U.verifier(not Deblocages.ouvert(au(379), "tissus", "brocart_or") and Deblocages.ouvert(au(380), "tissus", "brocart_or") and not Deblocages.ouvert(au(529), "tissus", "tulle_rose") and Deblocages.ouvert(au(530), "tissus", "tulle_rose"), "brocart au 7, tulle au 8")
-- Chaque niveau de prestige, de 2 à 8, ouvre quelque chose
local SEUILS_P = { 0, 20, 50, 100, 170, 260, 380, 530 }
for niveau = 2, 8 do
	U.verifier(#Deblocages.nouveaux(au(SEUILS_P[niveau] - 1), au(SEUILS_P[niveau])) > 0, "le prestige " .. niveau .. " ouvre quelque chose")
end
```

Dans `tests/unitaires/45_deblocages.luau`, remplacer :

```lua
local tout = { prestige = 170, clientes = {} }
```

par :

```lua
local tout = { prestige = 530, clientes = {} }
```

Dans `tests/unitaires/45_deblocages.luau`, remplacer :

```lua
"prestige 5 et six amitiés au niveau 4 : tout est ouvert")
```

par :

```lua
"prestige 8 et six amitiés au niveau 4 : tout est ouvert")
```

- [ ] **Step 2: Lancer les tests, vérifier l'échec**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT|attempt|membre" | head -3`
Expected: échec : une ligne qui finit par `ÉCHEC : 41 tissus (dont la toile de jute et quatre matières de fin de partie)`

- [ ] **Step 3: Écrire le code**

Dans `src/shared/Catalogue.luau`, remplacer :

```lua
	-- La toile de jute (sous-projet 2) : gratuite, pour s'exercer ou vendre sans risque ; un style à peine marqué
```

par :

```lua
	-- Sous-projet 4 : quatre matières de fin de partie (crêpe et organza au prestige 6, brocart au 7, tulle au 8)
	tissu("crepe_noir", "Crêpe noir", "crepe", "noir", 19, { type = "uni", couleurs = { { 32, 28, 36 } } },
		{ elegant = 14, chic = 12, gothique = 4 }),
	tissu("crepe_bleu_nuit", "Crêpe bleu nuit", "crepe", "bleu", 18, { type = "uni", couleurs = { { 30, 40, 90 } } },
		{ elegant = 14, chic = 12 }),
	tissu("crepe_ivoire", "Crêpe ivoire", "crepe", "blanc", 18, { type = "uni", couleurs = { { 245, 238, 222 } } },
		{ elegant = 16, chic = 8 }),
	tissu("crepe_rose_poudre", "Crêpe rose poudré", "crepe", "rose", 20, { type = "uni", couleurs = { { 230, 180, 185 } } },
		{ elegant = 10, romantique = 10, chic = 6 }),
	tissu("organza_blanc", "Organza blanc", "organza", "blanc", 18, { type = "uni", couleurs = { { 250, 250, 252 } } },
		{ romantique = 16, mignon = 8 }),
	tissu("organza_rose_pois", "Organza rose à pois", "organza", "rose", 20,
		{ type = "pois", couleurs = { { 250, 200, 215 }, { 255, 255, 255 } }, periode = 0.5, rayon = 0.08 }, { mignon = 16, romantique = 10 }),
	tissu("organza_lavande", "Organza lavande", "organza", "violet", 20, { type = "uni", couleurs = { { 200, 180, 230 } } },
		{ romantique = 14, mignon = 10 }),
	tissu("organza_jaune_fleurs", "Organza jaune fleuri", "organza", "jaune", 22,
		{ type = "fleurs", couleurs = { { 250, 230, 140 }, { 255, 255, 240 }, { 240, 160, 90 } }, periode = 2 }, { romantique = 12, mignon = 12 }),
	tissu("brocart_or", "Brocart or", "brocart", "jaune", 26,
		{ type = "fleurs", couleurs = { { 190, 140, 40 }, { 240, 200, 90 }, { 150, 100, 30 } }, periode = 2 }, { elegant = 22, chic = 6 }),
	tissu("brocart_bordeaux", "Brocart bordeaux", "brocart", "rouge", 24,
		{ type = "fleurs", couleurs = { { 110, 20, 40 }, { 170, 60, 80 }, { 80, 10, 30 } }, periode = 2 }, { elegant = 16, gothique = 10 }),
	tissu("brocart_noir_argent", "Brocart noir et argent", "brocart", "noir", 25,
		{ type = "rayures", couleurs = { { 30, 28, 34 }, { 180, 180, 190 } }, periode = 1, largeur = 0.2 }, { gothique = 18, elegant = 10 }),
	tissu("brocart_vert", "Brocart émeraude", "brocart", "vert", 22,
		{ type = "carreaux", couleurs = { { 20, 90, 60 }, { 60, 140, 100 } }, periode = 1 }, { elegant = 16, chic = 10 }),
	tissu("tulle_blanc", "Tulle blanc", "tulle", "blanc", 20, { type = "uni", couleurs = { { 252, 252, 255 } } },
		{ romantique = 18, elegant = 10 }),
	tissu("tulle_rose", "Tulle rose", "tulle", "rose", 22, { type = "uni", couleurs = { { 250, 190, 210 } } },
		{ romantique = 20, mignon = 8 }),
	tissu("tulle_noir", "Tulle noir", "tulle", "noir", 22, { type = "uni", couleurs = { { 25, 22, 30 } } },
		{ gothique = 16, romantique = 10 }),
	tissu("tulle_bleu_degrade", "Tulle bleu dégradé", "tulle", "bleu", 24,
		{ type = "degrade", couleurs = { { 120, 160, 230 }, { 220, 235, 255 } } }, { romantique = 16, elegant = 12 }),
	-- La toile de jute (sous-projet 2) : gratuite, pour s'exercer ou vendre sans risque ; un style à peine marqué
```

Dans `src/shared/Catalogue.luau`, remplacer :

```lua
	jute = { rugosite = 1, reflet = 0, materiau = "Fabric" },
```

par :

```lua
	jute = { rugosite = 1, reflet = 0, materiau = "Fabric" },
	crepe = { rugosite = 0.7, reflet = 0.02, materiau = "Fabric" },
	organza = { rugosite = 0.3, reflet = 0.12, materiau = "SmoothPlastic" },
	brocart = { rugosite = 0.4, reflet = 0.15, materiau = "SmoothPlastic" },
	tulle = { rugosite = 0.6, reflet = 0.05, materiau = "Fabric" },
```

Dans `src/shared/Deblocages.luau`, remplacer :

```lua
Deblocages.PRESTIGE_MATIERES = { laine = 2, satin = 3, velours = 4, soie = 5 }
```

par :

```lua
Deblocages.PRESTIGE_MATIERES = { laine = 2, satin = 3, velours = 4, soie = 5, crepe = 6, organza = 6, brocart = 7, tulle = 8 }
```

- [ ] **Step 4: Lancer les tests**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT"`
Expected:
```
Unitaires : 108210 vérifications
TOUT EST VERT : 711 vérifications
```

- [ ] **Step 5: Commit**

```bash
git add src/shared/Catalogue.luau src/shared/Deblocages.luau tests/unitaires/02_catalogue.luau tests/unitaires/45_deblocages.luau
git commit -m "Seize tissus en quatre matières : crêpe et organza au prestige 6, brocart au 7, tulle au 8

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 3: Huit décorations de fin de partie

**Files:**
- Modify: `src/shared/Catalogue.luau` (accessoires), `src/shared/Deblocages.luau` (`PRESTIGE_ACCESSOIRES`)
- Modify: `tests/unitaires/02_catalogue.luau`, `45_deblocages.luau`

**Interfaces:**
- Consumes: `objet(...)`, `garniture(...)` (catalogue).
- Produces: `noeud_dore`, `perle_noire` (prestige 5), `papillon_soie`, `galon_argent` (6), `broche_etoile`, `ruban_velours` (7), `couronne_fleurs`, `dentelle_doree` (8).

- [ ] **Step 1: Écrire les tests**

Dans `tests/unitaires/02_catalogue.luau`, remplacer :

```lua
U.verifier(#Catalogue.Accessoires == 23, "23 accessoires (dont les huit souvenirs du quartier)")
```

par :

```lua
U.verifier(#Catalogue.Accessoires == 31, "31 accessoires (dont les huit souvenirs du quartier et huit décorations de fin de partie)")
```

Dans `tests/unitaires/45_deblocages.luau`, remplacer :

```lua
for niveau = 2, 8 do
	U.verifier(#Deblocages.nouveaux(au(SEUILS_P[niveau] - 1), au(SEUILS_P[niveau])) > 0, "le prestige " .. niveau .. " ouvre quelque chose")
end
```

par :

```lua
for niveau = 2, 8 do
	U.verifier(#Deblocages.nouveaux(au(SEUILS_P[niveau] - 1), au(SEUILS_P[niveau])) > 0, "le prestige " .. niveau .. " ouvre quelque chose")
end
-- Deux décorations par niveau, du 5 au 8
for niveau, paire in pairs({ [5] = { "noeud_dore", "perle_noire" }, [6] = { "papillon_soie", "galon_argent" }, [7] = { "broche_etoile", "ruban_velours" }, [8] = { "couronne_fleurs", "dentelle_doree" } }) do
	for _, id in ipairs(paire) do
		U.verifier(Catalogue.accessoire(id) ~= nil and not Deblocages.ouvert(au(SEUILS_P[niveau] - 1), "accessoires", id) and Deblocages.ouvert(au(SEUILS_P[niveau]), "accessoires", id), id .. " : ouvert au prestige " .. niveau)
	end
end
```

- [ ] **Step 2: Lancer les tests, vérifier l'échec**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT|attempt|membre" | head -3`
Expected: échec : une ligne qui finit par `ÉCHEC : 31 accessoires (dont les huit souvenirs du quartier et huit décorations de fin de partie)`

- [ ] **Step 3: Écrire le code**

Dans `src/shared/Catalogue.luau`, remplacer :

```lua
	garniture("ruban_noir", "Ruban noir", 1, { gothique = 2, chic = 2 }, { largeur = 0.2, couleur = { 30, 25, 30 }, transparence = 0 }),
```

par :

```lua
	garniture("ruban_noir", "Ruban noir", 1, { gothique = 2, chic = 2 }, { largeur = 0.2, couleur = { 30, 25, 30 }, transparence = 0 }),
	-- Sous-projet 4 : deux décorations par niveau de prestige, du 5 au 8
	objet("noeud_dore", "Nœud doré", 5, { elegant = 3, chic = 2 },
		{ forme = "noeud", taille = 0.8, couleur = { 214, 170, 60 }, reflet = 0.4 }),
	objet("perle_noire", "Perle noire", 2, { gothique = 2, elegant = 2 },
		{ forme = "boule", taille = 0.18, couleur = { 30, 28, 34 }, reflet = 0.5 }),
	objet("papillon_soie", "Papillon de soie", 5, { romantique = 3, mignon = 2 },
		{ forme = "noeud", taille = 0.7, couleur = { 150, 190, 240 }, reflet = 0.2 }),
	garniture("galon_argent", "Galon argenté", 3, { elegant = 3, chic = 2 }, { largeur = 0.15, couleur = { 200, 200, 210 }, transparence = 0 }),
	objet("broche_etoile", "Broche étoile", 9, { chic = 3, elegant = 3 },
		{ forme = "croix", taille = 0.5, couleur = { 230, 200, 90 }, reflet = 0.4 }),
	garniture("ruban_velours", "Ruban de velours", 2, { gothique = 2, romantique = 2 }, { largeur = 0.2, couleur = { 100, 20, 40 }, transparence = 0 }),
	objet("couronne_fleurs", "Couronne de fleurs", 8, { romantique = 5, mignon = 1 },
		{ forme = "fleur", taille = 0.7, couleur = { 250, 200, 215 }, reflet = 0 }),
	garniture("dentelle_doree", "Dentelle dorée", 4, { elegant = 4, romantique = 1 }, { largeur = 0.3, couleur = { 220, 190, 110 }, transparence = 0.15 }),
```

Dans `src/shared/Deblocages.luau`, remplacer :

```lua
Deblocages.PRESTIGE_ACCESSOIRES = { ruban_noir = 2, dentelle_noire = 3 }
```

par :

```lua
Deblocages.PRESTIGE_ACCESSOIRES = {
	ruban_noir = 2,
	dentelle_noire = 3,
	noeud_dore = 5,
	perle_noire = 5,
	papillon_soie = 6,
	galon_argent = 6,
	broche_etoile = 7,
	ruban_velours = 7,
	couronne_fleurs = 8,
	dentelle_doree = 8,
}
```

- [ ] **Step 4: Lancer les tests**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT"`
Expected:
```
Unitaires : 108314 vérifications
TOUT EST VERT : 711 vérifications
```

- [ ] **Step 5: Commit**

```bash
git add src/shared/Catalogue.luau src/shared/Deblocages.luau tests/unitaires/02_catalogue.luau tests/unitaires/45_deblocages.luau
git commit -m "Huit décorations de fin de partie, deux par niveau de prestige du 5 au 8

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 4: L'équilibrage jusqu'au prestige 8, Studio, README

Test de caractérisation : la simulation mesure le prestige 8 ; elle passe dès qu'elle est écrite (le plan l'a mesurée à la 58e robe en médiane).

**Files:**
- Modify: `tests/unitaires/48_equilibrage.luau`
- Modify: `README.md`, `AtelierCouture.rbxl` (régénéré)

**Interfaces:**
- Consumes: tout ce qui précède.
- Produces: la ligne « Équilibrage : … » avec le prestige 8.

- [ ] **Step 1: La simulation suit le prestige 8**

Dans `tests/unitaires/48_equilibrage.luau`, remplacer :

```lua
return { prestige2 = niveauA[2] or math.huge, prestige5 = niveauA[5] or math.huge,
```

par :

```lua
return { prestige2 = niveauA[2] or math.huge, prestige5 = niveauA[5] or math.huge, prestige8 = niveauA[8] or math.huge,
```

Dans `tests/unitaires/48_equilibrage.luau`, remplacer :

```lua
local p5, medianeP5 = serie("prestige5")
```

par :

```lua
local p5, medianeP5 = serie("prestige5")
local p8, medianeP8 = serie("prestige8")
```

Dans `tests/unitaires/48_equilibrage.luau`, remplacer :

```lua
 : prestige 2 à la robe %s au plus tard ; 5 de la %s à la %s (médiane %s) ; tout ouvert
```

par :

```lua
 : prestige 2 à la robe %s au plus tard ; 5 de la %s à la %s (médiane %s) ; 8 à la %s (médiane) ; tout ouvert
```

Dans `tests/unitaires/48_equilibrage.luau`, remplacer :

```lua
texte(p5[1]), texte(p5[#p5]), texte(medianeP5), texte(tout[1])
```

par :

```lua
texte(p5[1]), texte(p5[#p5]), texte(medianeP5), texte(medianeP8), texte(tout[1])
```

Dans `tests/unitaires/48_equilibrage.luau`, remplacer :

```lua
U.verifier(medianeP5 >= 12 and medianeP5 <= 20 and p5[#p5] <= 25,
```

par :

```lua
U.verifier(medianeP8 <= 70, "le prestige 8 (qui ouvre maintenant le tulle et deux décorations) est atteint vers la 70e robe au plus tard, en médiane (" .. bilan .. ")")
U.verifier(medianeP5 >= 12 and medianeP5 <= 20 and p5[#p5] <= 25,
```

- [ ] **Step 2: Lancer les tests**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Équilibrage|Unitaires|ÉCHEC|TOUT"`
Expected:
```
Équilibrage : 20 parties de 90 robes, une robe libre de jute vendue sur quatre, 40 commandes par lettre (médiane) : prestige 2 à la robe 3 au plus tard ; 5 de la 17 à la 23 (médiane 19) ; 8 à la 58 (médiane) ; tout ouvert de la 55 à la 82 (médiane 66) ; au plus bas 241 po
Unitaires : 108315 vérifications
TOUT EST VERT : 711 vérifications
```

- [ ] **Step 3: En Play, par le connecteur MCP**

Construire le lieu du dépôt dans un dossier temporaire (`C:/dev/jeux/roblox-maker/rojo.exe build -o <dossier temporaire>/Plan8aDepot.rbxl`), l'ouvrir dans Studio, lancer Play et attendre 4 s ; appuyer sur E, régler les rubans aux vraies mesures de Colette (glisser les poignées jusqu'au bord de la silhouette) et valider ; au carnet, ouvrir le choix du tissu de la première pièce et lire les textes des cartes `Tissu_crepe_noir` et `Tissu_tulle_rose`. Relever les alertes.

Expected : cartes grisées, « Prestige 6 » et « Prestige 8 » ; aucune alerte de notre code (« Lieu non publié » et les messages internes de Roblox mis à part). Arrêter Play et fermer cette fenêtre de Studio (sans enregistrer).

- [ ] **Step 4: Mettre à jour le README**

Dans `README.md`, remplacer :

```markdown
2. **Carnet de croquis** : corsage, manches, col et jupe au choix ; un tissu par pièce (25 tissus, filtre par style,
   dont la toile de jute, gratuite).
```

par :

```markdown
2. **Carnet de croquis** : corsage, manches, col et jupe au choix ; un tissu par pièce (41 tissus en dix matières,
   filtre par style, dont la toile de jute, gratuite).
```

Dans `README.md`, remplacer :

```markdown
7. **Décorations** : 18 objets (boutons, nœuds, fleurs, broche, perle, étoile, croix, et les huit souvenirs du
   quartier une fois leur événement passé) et 5 garnitures (dentelles,
   rubans, galon).
```

par :

```markdown
7. **Décorations** : 23 objets (boutons, nœuds, fleurs, broches, perles, étoile, croix, couronne, et les huit
   souvenirs du quartier une fois leur événement passé) et 8 garnitures (dentelles, rubans, galons).
```

Dans `README.md`, remplacer :

```markdown
   les satins (3), les velours (4) et les soies (5), le ruban noir (2) et la dentelle noire (3) ; l'amitié de
```

par :

```markdown
   les satins (3), les velours (4), les soies (5), le crêpe et l'organza (6), le brocart (7) et le tulle (8) ; le
   ruban noir (2), la dentelle noire (3) et deux décorations par niveau du 5 au 8 ; l'amitié de
```

Dans `README.md`, remplacer :

```markdown
   jute vendue sur quatre robes, les lettres invitées) atteint le prestige 2 à la 3e robe au plus tard, le 5 vers
   la 19e, et tout est ouvert vers la 62e (médianes).
```

par :

```markdown
   jute vendue sur quatre robes, les lettres invitées) atteint le prestige 2 à la 3e robe au plus tard, le 5 vers
   la 19e, le 8 vers la 58e, et tout est ouvert vers la 66e (médianes). Le tirage d'une commande ne recalcule
   jamais les styles robe par robe (les points de chaque croquis et de chaque tissu sont précalculés).
```

- [ ] **Step 5: Tests, lieu régénéré, commit**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT"`
Expected:
```
Unitaires : 108315 vérifications
TOUT EST VERT : 711 vérifications
```

```bash
C:/dev/jeux/roblox-maker/rojo.exe build -o AtelierCouture.rbxl
git add tests/unitaires/48_equilibrage.luau README.md AtelierCouture.rbxl
git commit -m "Plan 8a terminé : tissus et décorations de fin de partie, tirage rapide, équilibrage jusqu'au prestige 8

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```
