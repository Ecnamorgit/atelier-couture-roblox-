# Aiguille & Dentelle — Plan 22 : les étiquettes, jeu

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Faire demander les nouvelles étiquettes par les commandes, au fil du prestige, sans exigences contraires ; donner une occasion préférée à chaque cliente et aux événements ; montrer au carnet les jauges utiles, les étiquettes des tissus et un filtre par occasion.

**Architecture:** `Commandes.generer` tire, en plus des genres d'avant, une occasion, une matière dominante ou un trait selon le niveau de prestige (`Commandes.PRESTIGE_ETIQUETTES`, `Commandes.PRESTIGE_MATIERE`) et écarte les paires contraires (`Commandes.compatibles`) ; `Clientes` et `Histoire` portent les occasions ; `EcranCarnet` montre les jauges des étiquettes demandées et des styles de la cliente, les quatre étiquettes les plus fortes de chaque tissu (`Etiquettes.apportsTissu`, `Etiquettes.nom`) et une seconde rangée de filtres.

**Tech Stack:** Luau, Rojo 7.7.0-rc.1, simulation Luau 0.650 (`tests/lancer.sh`), Roblox Studio via le connecteur MCP Studio.

**Spec:** `docs/superpowers/specs/2026-09-30-robes-gouts-design.md` (section 3, « Des goûts plus fins : seize étiquettes » ; plan 22 de la section 6).

## Décisions de ce plan

- **Au fil du prestige** : Journée et Travail au prestige 2, la matière au 3, la Soirée et les sept traits au 4. La spec disait « occasions au 2 » ; la Soirée attend le 4 : avant la jupe longue évasée (amitié de Victoire, arrivée au 4), aucune robe ne l'atteint à 60. Pour que chaque étiquette atteigne 60 là où elle s'ouvre, la laine passe à 20 points de Travail et le satin à 18 de Soirée.
- **Garde** (spec : « chaque étiquette peut atteindre 60 avec ce qui est ouvert quand elle est demandée ») : ce qui est ouvert = le prestige, et une amitié de niveau 2 (trois belles robes) avec chaque cliente déjà venue ; à amitiés nulles, Travail et Chaude n'atteindraient jamais 60 (manches longues, jupe évasée, col montant s'ouvrent à l'amitié). Le tirage, lui, vérifie toujours la commande avec ce qui est vraiment ouvert.
- **Une occasion, une matière, un trait au plus par commande** (chaque genre se tire une fois) ; valeurs : occasion 20 au plafond de la cliente, trait 20 à 60 (motifs 50 à 100). L'occasion est celle de la cliente deux fois sur trois.
- **Interdits** (`Commandes.compatibles`) : deux traits d'un même groupe, une matière de chaleur ≥ 0,6 avec Légère (laine, velours, brocart), ≤ −0,7 avec Chaude (organza, lin, tulle), Travaillée et un « au plus » de style. Une exigence tirée qui en contredit une autre est laissée (la commande en a une de moins).
- **Occasions des clientes** : Colette, Hélène, Inès, Capucine : la soirée ; Margot, Salomé, Apolline, Maëlle : la journée ; Victoire, Joséphine : le travail.
- **Événements** : à partir de la kermesse, chaque robe qui n'a pas déjà trois exigences demande l'occasion de son événement (le bal d'hiver et la première : la soirée à 40 ; la veillée : la soirée à 20 ; les autres : la journée, à 20 ou 30), vérifiée réalisable au prestige de l'événement par `52_histoire`.
- **Carnet** : jauges = étiquettes des exigences chiffrées, puis styles de la cliente, sans doublon (les six styles pour une robe libre) ; carte de tissu : prix et ses quatre étiquettes les plus fortes (styles et occasions : leurs points ; Légère ou Chaude : 100 × la part de sa matière dans l'indice) ; filtres : « Tous » et les styles, puis les trois occasions sur une seconde rangée.
- **Relecture du plan 21** (mineur reporté) : une occasion ou un style inconnus rendent la commande irréalisable au lieu d'une erreur.
- **Joueur simulé** (`48_equilibrage`) : il juge aussi occasions, traits et matière ; une commande travaillée, qu'aucune robe simple ne remplit, est faite comme sa robe témoin (objets achetés à la mercerie). Équilibrage inchangé (prestige 5 en médiane à la 18e robe, 8 à la 57e, tout ouvert à la 125e).
- **Vérifié pendant la préparation** : le plan a été joué entièrement sur un brouillon tiré de `main` ; dix variantes du brouillon échouent sur la vérification qui les garde. Dans Studio : une commande se tire en 0,4 à 0,6 ms en moyenne (28 ms au pire sur 200, tout ouvert) ; la carte la plus chargée tient en 40 px (60 disponibles) ; le nom de jauge le plus long, 75 px (100) ; la fiche du carnet vue à l'écran.

## Global Constraints

- **Dépôt** : `C:\dev\jeux\atelier-couture`, branche `etiquettes-jeu`, créée depuis `main` (où le plan 21 est fusionné). Selon les règles du commanditaire : la branche testée et relue est fusionnée dans `main` et poussée sur GitHub.
- **Rojo** : `C:/dev/jeux/roblox-maker/rojo.exe`.
- **Contenu original** : aucun nom, texte, image ni son de *Dressmaker*.
- **Contraintes des plans précédents toujours valables** : fins de ligne LF, commits en français terminés par `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`, textes d'au moins 14 px (et aucun texte laissé à « Label »), le serveur fait foi.

## Review Focus

- **Une partie en cours (prestige bas, commandes et lettres déjà tirées).** Attendu : rien ne change avant le prestige 2 ; les commandes sauvegardées gardent leurs exigences. Test : `72_commandes_gouts` (rien avant son prestige) et `30_sauvegarde`.
- **Une cliente au prestige 8 qui tire trente commandes impossibles de suite.** Attendu : le repli (un style à 20 ou 10), jamais d'erreur ni de commande impossible. Test : `46_deblocages_etat` (inchangé) et `72_commandes_gouts`.
- **Une commande travaillée au joueur qui n'a pas d'objets.** Attendu : la mercerie les vend ; le joueur simulé les achète et livre. Test : `48_equilibrage`.
- **Un événement tiré tôt (amitiés nulles).** Attendu : la robe de l'événement reste réalisable avec son occasion. Test : `52_histoire`.
- **La fiche d'une commande à trois exigences chiffrées et deux styles de cliente.** Attendu : cinq jauges, au-dessus du métrage. Test : scénario (« la ligne du métrage est en bas de la colonne, sous les jauges »), `73_carnet_etiquettes`.

---

### Task 1: Les commandes demandent les étiquettes

**Files:**
- Create: `tests/unitaires/72_commandes_gouts.luau`
- Modify: `src/shared/Commandes.luau`, `src/shared/Clientes.luau`, `src/shared/Catalogue.luau`
- Modify: `tests/unitaires/06_commandes.luau`, `tests/unitaires/48_equilibrage.luau`

**Interfaces:**
- Consumes: `Commandes.realisable` (témoin avec `ajout`), `Etiquettes.MOTIFS`, `Catalogue.OCCASIONS`, `Catalogue.TRAITS`, `Catalogue.MATIERES[m].chaleur`, `Etiquettes.calculer` (plan 21).
- Produces: `Commandes.PRESTIGE_ETIQUETTES` (`[occasion ou trait] = niveau`), `Commandes.PRESTIGE_MATIERE` (3), `Commandes.compatibles(a, b)` → booléen ; champ `occasion` de chaque cliente.

- [ ] **Step 1: Écrire les tests**

Créer `tests/unitaires/72_commandes_gouts.luau` :

```lua
-- Sous-projet 7 : les commandes demandent les nouvelles étiquettes au fil du prestige (occasions au 2, matière au 3,
-- traits au 4), jamais deux exigences contradictoires ; chaque cliente a son occasion préférée.
local Commandes = U.module("Commandes")
local Catalogue = U.module("Catalogue")
local Clientes = U.module("Clientes")
local Deblocages = U.module("Deblocages")
local Progression = U.module("Progression")

---------------------------------------------------------------------------
-- Chaque cliente a une occasion préférée ; les trois occasions ont leurs clientes
---------------------------------------------------------------------------
local parOccasion = {}
for _, c in ipairs(Clientes.LISTE) do
	U.verifier(table.find(Catalogue.OCCASIONS, c.occasion) ~= nil, c.id .. " : une occasion préférée")
	parOccasion[c.occasion] = (parOccasion[c.occasion] or 0) + 1
end
U.verifier(parOccasion.journee and parOccasion.soiree and parOccasion.travail, "les trois occasions ont leurs clientes")

---------------------------------------------------------------------------
-- Garde : au prestige où une commande peut la demander, chaque étiquette atteint 60 avec ce qui est ouvert (par le
-- prestige, et par une amitié de niveau 2 avec chaque cliente déjà venue : trois belles robes)
---------------------------------------------------------------------------
local SEUILS = Progression.SEUILS_PRESTIGE
local function ouvertsAu(p)
	local clientes = {}
	for _, c in ipairs(Clientes.LISTE) do
		if c.prestige <= p then
			clientes[c.id] = { amitie = Progression.SEUILS_AMITIE[3] }
		end
	end
	return Deblocages.ouverts({ prestige = SEUILS[p], clientes = clientes })
end
local manquees = {}
for _, liste in ipairs({ Catalogue.OCCASIONS, Catalogue.TRAITS }) do
	for _, id in ipairs(liste) do
		local p = Commandes.PRESTIGE_ETIQUETTES[id]
		local e = if table.find(Catalogue.OCCASIONS, id) then { type = "occasion", occasion = id, valeur = 60 } else { type = "trait", trait = id, valeur = 60 }
		if not (p and p >= 2 and p <= 8 and Commandes.realisable({ e }, ouvertsAu(p))) then
			table.insert(manquees, id .. " (" .. tostring(p) .. ")")
		end
	end
end
U.verifier(#manquees == 0, "au prestige où elle se demande, chaque étiquette atteint 60 (manquées : " .. table.concat(manquees, ", ") .. ")")

---------------------------------------------------------------------------
-- Interdits : deux traits d'un même groupe, une matière contraire à Légère ou Chaude, Travaillée et un « au plus »
---------------------------------------------------------------------------
local function trait(t)
	return { type = "trait", trait = t, valeur = 30 }
end
local function matiere(m)
	return { type = "matiere", matiere = m }
end
local interdits = {
	{ trait("legere"), trait("chaude") }, { trait("sobre"), trait("travaillee") }, { trait("unie"), trait("a_motifs") },
	{ trait("fleurie"), trait("unie") }, { trait("legere"), matiere("velours") }, { matiere("organza"), trait("chaude") },
	{ trait("travaillee"), { type = "max", style = "chic", valeur = 20 } },
}
local permises = {
	{ trait("legere"), matiere("coton") }, { trait("chaude"), matiere("laine") }, { trait("sobre"), { type = "max", style = "chic", valeur = 20 } },
	{ trait("unie"), { type = "occasion", occasion = "soiree", valeur = 30 } }, { trait("legere"), trait("sobre") },
}
local fautes = 0
for _, paire in ipairs(interdits) do
	if Commandes.compatibles(paire[1], paire[2]) or Commandes.compatibles(paire[2], paire[1]) then
		fautes += 1
	end
end
for _, paire in ipairs(permises) do
	if not (Commandes.compatibles(paire[1], paire[2]) and Commandes.compatibles(paire[2], paire[1])) then
		fautes += 1
	end
end
U.verifier(fautes == 0, "interdits : sept paires écartées, cinq permises (" .. fautes .. " en défaut)")

---------------------------------------------------------------------------
-- Au fil du prestige : rien avant son heure, jamais d'interdit, toujours réalisable ; tout finit par se demander ;
-- la cliente demande surtout son occasion
---------------------------------------------------------------------------
local avant, contraires, irrealisables = {}, 0, 0
local vus = {}
local siennes, occasionsDemandees = 0, 0
for niveau = 1, 8 do
	local progres = { prestige = SEUILS[niveau], clientes = {} }
	local ouverts = Deblocages.ouverts(progres)
	local rng = Random.new(720 + niveau)
	for _, c in ipairs(Clientes.LISTE) do
		if c.prestige <= niveau then
			for _ = 1, 12 do
				local commande = Commandes.generer(rng, c, progres)
				local ex = commande.exigences
				if not Commandes.realisable(ex, ouverts) then
					irrealisables += 1
				end
				for i, e in ipairs(ex) do
					vus[e.type] = true
					local id = e.occasion or e.trait
					if (id and niveau < Commandes.PRESTIGE_ETIQUETTES[id]) or (e.type == "matiere" and niveau < Commandes.PRESTIGE_MATIERE) then
						table.insert(avant, ("%s au prestige %d"):format(id or e.matiere, niveau))
					end
					if e.type == "occasion" and niveau >= 3 then
						occasionsDemandees += 1
						siennes += if e.occasion == c.occasion then 1 else 0
					end
					for j = i + 1, #ex do
						if not Commandes.compatibles(e, ex[j]) then
							contraires += 1
						end
					end
				end
			end
		end
	end
end
U.verifier(#avant == 0, "aucune étiquette demandée avant son prestige (en défaut : " .. table.concat(avant, ", ", 1, math.min(#avant, 5)) .. ")")
U.verifier(contraires == 0 and irrealisables == 0, ("jamais d'interdit (%d), toujours réalisable avec ce qui est ouvert (%d)"):format(contraires, irrealisables))
U.verifier(vus.occasion and vus.matiere and vus.trait, "occasions, matières et traits finissent par être demandés")
U.verifier(occasionsDemandees > 0 and siennes / occasionsDemandees >= 0.5, ("la cliente demande surtout son occasion (%d sur %d)"):format(siennes, occasionsDemandees))

-- (relecture du plan 21) Une étiquette inconnue, d'une fiche mal écrite : irréalisable, sans erreur
local okOccasion, occasionInconnue = pcall(Commandes.realisable, { { type = "occasion", occasion = "bal", valeur = 20 } })
local okStyle, styleInconnu = pcall(Commandes.realisable, { { type = "min", style = "punk", valeur = 20 } })
U.verifier(okOccasion and okStyle and not occasionInconnue and not styleInconnu, "une occasion ou un style inconnus : irréalisables, sans erreur")
```

Dans `tests/unitaires/06_commandes.luau`, remplacer :

```lua
	if temoin.accessoire then
		table.insert(recette.accessoires, { id = temoin.accessoire, piece = 1, u = 0.5, v = 0.5, echelle = 1, angle = 0 })
	end
	U.verifier(Notation.verifierExigences(commande.exigences, Notation.bilan(recette)), "la robe témoin remplit la commande " .. n)
end
for _, g in ipairs({ "min", "max", "qualite", "teinte", "accessoire" }) do
```

par :

```lua
	if temoin.accessoire then
		table.insert(recette.accessoires, { id = temoin.accessoire, piece = 1, u = 0.5, v = 0.5, echelle = 1, angle = 0 })
	end
	for _ = 1, temoin.ajout and temoin.ajout.nombre or 0 do -- (sous-projet 7 : les objets d'une robe travaillée)
		table.insert(recette.accessoires, { id = temoin.ajout.id, piece = 1, u = 0.4, v = 0.4, echelle = 1, angle = 0 })
	end
	U.verifier(Notation.verifierExigences(commande.exigences, Notation.bilan(recette)), "la robe témoin remplit la commande " .. n)
end
for _, g in ipairs({ "min", "max", "qualite", "teinte", "accessoire", "occasion", "matiere", "trait" }) do
```

Dans `tests/unitaires/48_equilibrage.luau`, remplacer :

```lua
-- À chaque commande : mesures justes, la robe la moins chère qui la remplit avec ce qui est ouvert (un seul
-- tissu, l'accessoire demandé), qualité 0,8 ; une robe refusée (qualité demandée trop haute) est abandonnée.
```

par :

```lua
-- À chaque commande : mesures justes, la robe la moins chère qui la remplit avec ce qui est ouvert (un seul
-- tissu, l'accessoire demandé), qualité 0,8 ; une robe refusée (qualité demandée trop haute) est abandonnée.
-- (Sous-projet 7 : une robe travaillée, qu'aucune robe simple ne remplit, est la robe témoin de la commande.)
```

Dans `tests/unitaires/48_equilibrage.luau`, remplacer :

```lua
local Deblocages = U.module("Deblocages")
local Progression = U.module("Progression")
```

par :

```lua
local Deblocages = U.module("Deblocages")
local Progression = U.module("Progression")
local Etiquettes = U.module("Etiquettes")
local Commandes = U.module("Commandes")
```

Dans `tests/unitaires/48_equilibrage.luau`, remplacer :

```lua
-- Les styles d'une robe simple, calculés une fois pour toute la simulation (Notation.styles, gardés en mémoire)
local stylesConnus = {}
local function stylesDe(candidate, impose)
	local cle = candidate.rang .. "/" .. (impose or "")
	local styles = stylesConnus[cle]
	if not styles then
		styles = Notation.styles({ croquis = candidate.croquis.croquis, tissus = { [candidate.tissu.id] = 1 }, accessoires = impose and { { id = impose } } or {} })
		stylesConnus[cle] = styles
	end
	return styles
end
```

par :

```lua
-- Le bilan d'une robe simple, calculé une fois pour toute la simulation (Notation.styles et Etiquettes.calculer, gardés
-- en mémoire)
local bilansConnus = {}
local function bilanDe(candidate, impose)
	local cle = candidate.rang .. "/" .. (impose or "")
	local bilan = bilansConnus[cle]
	if not bilan then
		local entree = { croquis = candidate.croquis.croquis, tissus = { [candidate.tissu.id] = 1 }, accessoires = impose and { { id = impose } } or {} }
		local etiquettes = Etiquettes.calculer(entree)
		bilan = {
			styles = Notation.styles(entree),
			occasions = etiquettes.occasions,
			traits = etiquettes.traits,
			qualite = QUALITE,
			teinte = candidate.tissu.teinte,
			matiere = candidate.tissu.matiere,
			accessoires = impose and { [impose] = 1 } or {},
		}
		bilansConnus[cle] = bilan
	end
	return bilan
end
```

Dans `tests/unitaires/48_equilibrage.luau`, remplacer :

```lua
		if ouverts.tissus[t.id] and ouverts.variantes[v.corsage] and ouverts.variantes[v.manches] and ouverts.variantes[v.col] and ouverts.variantes[v.jupe] then
			local bilan = {
				styles = stylesDe(candidate, impose),
				qualite = QUALITE,
				teinte = t.teinte,
				accessoires = impose and { [impose] = 1 } or {},
			}
			if Notation.verifierExigences(etat.commande.exigences, bilan) then
				local cout = candidate.cout + (impose and Catalogue.accessoire(impose).prix or 0)
				return { croquis = v, pieces = c.pieces, dm = c.dm, tissu = t.id, cout = cout, impose = impose }
			end
		end
	end
	return nil
end
```

par :

```lua
		if ouverts.tissus[t.id] and ouverts.variantes[v.corsage] and ouverts.variantes[v.manches] and ouverts.variantes[v.col] and ouverts.variantes[v.jupe] then
			if Notation.verifierExigences(etat.commande.exigences, bilanDe(candidate, impose)) then
				local cout = candidate.cout + (impose and Catalogue.accessoire(impose).prix or 0)
				return { croquis = v, pieces = c.pieces, dm = c.dm, tissu = t.id, cout = cout, impose = impose }
			end
		end
	end
	-- Aucune robe simple : la robe témoin de la commande (une robe travaillée : ses objets ajoutés), si la qualité suffit
	local ok, temoin = Commandes.realisable(etat.commande.exigences, ouverts)
	if ok and temoin.ajout then
		local accessoires = impose and { { id = impose } } or {}
		for _ = 1, temoin.ajout.nombre do
			table.insert(accessoires, { id = temoin.ajout.id })
		end
		local entree = { croquis = temoin.croquis, tissus = { [temoin.tissu] = 1 }, accessoires = accessoires }
		local etiquettes, tissu = Etiquettes.calculer(entree), Catalogue.tissu(temoin.tissu)
		local comptes = { [temoin.ajout.id] = temoin.ajout.nombre }
		if impose then
			comptes[impose] = (comptes[impose] or 0) + 1
		end
		local bilan = { styles = Notation.styles(entree), occasions = etiquettes.occasions, traits = etiquettes.traits, qualite = QUALITE, teinte = tissu.teinte, matiere = tissu.matiere, accessoires = comptes }
		if Notation.verifierExigences(etat.commande.exigences, bilan) then
			local pieces = Patron.piecesDuCroquis(temoin.croquis)
			local dm = Metrage.conseil(pieces)
			local cout = EtatAtelier.prix(temoin.tissu, dm) + (impose and Catalogue.accessoire(impose).prix or 0) + temoin.ajout.nombre * Catalogue.accessoire(temoin.ajout.id).prix
			return { croquis = temoin.croquis, pieces = pieces, dm = dm, tissu = temoin.tissu, cout = cout, impose = impose, ajout = temoin.ajout }
		end
	end
	return nil
end
```

Dans `tests/unitaires/48_equilibrage.luau`, remplacer :

```lua
		local deco = choix.impose and { { id = choix.impose, piece = 1, copie = "unique", u = 0.5, v = 0.5, echelle = 1, angle = 0 } } or {}
		if choix.impose and (e.mercerie[choix.impose] or 0) < 1 then
			assert(e:acheterMercerie(choix.impose, 1).ok) -- (sous-projet 6 : l'accessoire exigé s'achète à la mercerie)
		end
```

par :

```lua
		local deco = choix.impose and { { id = choix.impose, piece = 1, copie = "unique", u = 0.5, v = 0.5, echelle = 1, angle = 0 } } or {}
		if choix.impose and (e.mercerie[choix.impose] or 0) < 1 then
			assert(e:acheterMercerie(choix.impose, 1).ok) -- (sous-projet 6 : l'accessoire exigé s'achète à la mercerie)
		end
		if choix.ajout then
			local deja = if choix.ajout.id == choix.impose then 1 else 0
			local manque = choix.ajout.nombre + deja - (e.mercerie[choix.ajout.id] or 0)
			if manque > 0 then
				assert(e:acheterMercerie(choix.ajout.id, manque).ok)
			end
			for k = 1, choix.ajout.nombre do
				table.insert(deco, { id = choix.ajout.id, piece = 1, copie = "unique", u = 0.1 * k, v = 0.3, echelle = 1, angle = 0 })
			end
		end
```

- [ ] **Step 2: Lancer les tests, vérifier l'échec**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT|attempt|membre" | head -3`
Expected: échec : une ligne qui finit par `ÉCHEC : le générateur produit des exigences « occasion »`

- [ ] **Step 3: Le tirage, les occasions des clientes**

Dans `src/shared/Clientes.luau`, remplacer :

```lua
-- Clientes : les dix clientes qui reviennent à l'atelier (contenu original, rien de Dressmaker). Chacune a ses
-- vraies mesures (dm, proches de sa taille), ses styles et sa teinte préférés (ses commandes en viennent), sa
-- tenue, ses répliques, le prestige qu'il faut pour qu'elle vienne, et ce que son amitié ouvre (sous-projet 2).
```

par :

```lua
-- Clientes : les dix clientes qui reviennent à l'atelier (contenu original, rien de Dressmaker). Chacune a ses
-- vraies mesures (dm, proches de sa taille), ses styles, sa teinte et (sous-projet 7) son occasion préférés (ses
-- commandes en viennent), sa tenue, ses répliques, le prestige qu'il faut pour qu'elle vienne, et ce que son amitié
-- ouvre (sous-projet 2).
```

Dans `src/shared/Clientes.luau`, remplacer :

```lua
		styles = { "romantique", "mignon" },
		teinte = "rose",
```

par :

```lua
		styles = { "romantique", "mignon" },
		teinte = "rose",
		occasion = "soiree",
```

Dans `src/shared/Clientes.luau`, remplacer :

```lua
		styles = { "mignon", "decontracte" },
		teinte = "jaune",
```

par :

```lua
		styles = { "mignon", "decontracte" },
		teinte = "jaune",
		occasion = "journee",
```

Dans `src/shared/Clientes.luau`, remplacer :

```lua
		styles = { "decontracte", "chic" },
		teinte = "vert",
```

par :

```lua
		styles = { "decontracte", "chic" },
		teinte = "vert",
		occasion = "journee",
```

Dans `src/shared/Clientes.luau`, remplacer :

```lua
		styles = { "elegant", "chic" },
		teinte = "blanc",
```

par :

```lua
		styles = { "elegant", "chic" },
		teinte = "blanc",
		occasion = "soiree",
```

Dans `src/shared/Clientes.luau`, remplacer :

```lua
		styles = { "gothique", "elegant" },
		teinte = "noir",
```

par :

```lua
		styles = { "gothique", "elegant" },
		teinte = "noir",
		occasion = "soiree",
```

Dans `src/shared/Clientes.luau`, remplacer :

```lua
		styles = { "chic", "elegant" },
		teinte = "bleu",
```

par :

```lua
		styles = { "chic", "elegant" },
		teinte = "bleu",
		occasion = "travail",
```

Dans `src/shared/Clientes.luau`, remplacer :

```lua
		styles = { "romantique", "chic" },
		teinte = "violet",
```

par :

```lua
		styles = { "romantique", "chic" },
		teinte = "violet",
		occasion = "journee",
```

Dans `src/shared/Clientes.luau`, remplacer :

```lua
		styles = { "chic", "decontracte" },
		teinte = "brun",
```

par :

```lua
		styles = { "chic", "decontracte" },
		teinte = "brun",
		occasion = "travail",
```

Dans `src/shared/Clientes.luau`, remplacer :

```lua
		styles = { "gothique", "romantique" },
		teinte = "rouge",
```

par :

```lua
		styles = { "gothique", "romantique" },
		teinte = "rouge",
		occasion = "soiree",
```

Dans `src/shared/Clientes.luau`, remplacer :

```lua
		styles = { "decontracte", "mignon" },
		teinte = "bleu",
```

par :

```lua
		styles = { "decontracte", "mignon" },
		teinte = "bleu",
		occasion = "journee",
```

Dans `src/shared/Catalogue.luau`, remplacer :

```lua
occasion = { soiree = 16, journee = 2 }, chaleur = -0.1 },
```

par :

```lua
occasion = { soiree = 18, journee = 2 }, chaleur = -0.1 },
```

Dans `src/shared/Catalogue.luau`, remplacer :

```lua
occasion = { travail = 18, journee = 4 }, chaleur = 0.9 },
```

par :

```lua
occasion = { travail = 20, journee = 4 }, chaleur = 0.9 },
```

Dans `src/shared/Commandes.luau`, remplacer :

```lua
-- Commandes : génère des commandes, toujours réalisables avec le catalogue. Celle d'une cliente (sous-projet 2)
-- vient de ses goûts : un de ses styles, sa teinte, jamais un « au plus » dans ses styles ; elle est réalisable
-- avec ce que le joueur a ouvert (déblocages), et ses exigences de style montent avec son prestige.
```

par :

```lua
-- Commandes : génère des commandes, toujours réalisables avec le catalogue. Celle d'une cliente (sous-projet 2)
-- vient de ses goûts : un de ses styles, sa teinte, (sous-projet 7) son occasion, jamais un « au plus » dans ses
-- styles ; elle est réalisable avec ce que le joueur a ouvert (déblocages), et ses exigences montent avec son
-- prestige : les occasions à partir du prestige 2, la matière au 3, les traits au 4.
```

Dans `src/shared/Commandes.luau`, remplacer :

```lua
-- plafond : dizaines de points au plus pour le style demandé (monte avec le prestige) ; ouverts : accessoires
-- qu'on peut demander (nil : tous)
local function tirerExigences(rng, cliente, plafond, ouverts)
	local exigences = {}
	local styleMin = tirer(cliente and cliente.styles or Catalogue.STYLES, rng)
	table.insert(exigences, { type = "min", style = styleMin, valeur = rng:NextInteger(3, plafond) * 10 })
	local autres = { "max", "qualite", "teinte", "accessoire" }
	for _ = 2, rng:NextInteger(1, 3) do
		local genre = table.remove(autres, rng:NextInteger(1, #autres))
		if genre == "max" then
			local style
			repeat
				style = tirer(Catalogue.STYLES, rng)
			until style ~= styleMin and not (cliente and table.find(cliente.styles, style))
			table.insert(exigences, { type = "max", style = style, valeur = rng:NextInteger(1, 4) * 10 })
		elseif genre == "qualite" then
			table.insert(exigences, { type = "qualite", valeur = rng:NextInteger(6, 9) / 10 })
		elseif genre == "teinte" then
			table.insert(exigences, { type = "teinte", teinte = cliente and cliente.teinte or tirer(Catalogue.Tissus, rng).teinte })
		else
			local objets = {}
			for _, a in ipairs(Catalogue.Accessoires) do
				if a.genre == "objet" and (not ouverts or ouverts.accessoires[a.id]) then
					table.insert(objets, a.id)
				end
			end
			table.insert(exigences, { type = "accessoire", id = tirer(objets, rng) })
		end
	end
	return exigences
end
```

par :

```lua
-- Sous-projet 7 : le prestige à partir duquel une commande peut demander chaque occasion et chaque trait (à ce
-- prestige, avec ce qu'ouvrent le prestige et une amitié de niveau 2 avec les clientes déjà venues, chacun atteint 60 :
-- vérifié par les tests ; la Soirée attend la jupe longue évasée), et la matière dominante
Commandes.PRESTIGE_ETIQUETTES = {
	journee = 2, travail = 2, soiree = 4,
	legere = 4, chaude = 4, sobre = 4, travaillee = 4, unie = 4, fleurie = 4, a_motifs = 4,
}
Commandes.PRESTIGE_MATIERE = 3
local GROUPES_TRAITS = { legere = 1, chaude = 1, sobre = 2, travaillee = 2, unie = 3, fleurie = 3, a_motifs = 3 }

-- Deux exigences qu'une commande ne demande jamais ensemble : deux traits d'un même groupe (Légère et Chaude, Sobre et
-- Travaillée, Unie, Fleurie et À motifs), une matière trop chaude pour une robe légère (ou trop légère pour une robe
-- chaude), une robe travaillée et un « au plus » de style (les décorations qu'il lui faut portent des styles)
function Commandes.compatibles(a, b)
	local function sens(x, y)
		if x.type ~= "trait" then
			return true
		elseif y.type == "trait" then
			return GROUPES_TRAITS[x.trait] ~= GROUPES_TRAITS[y.trait]
		elseif y.type == "matiere" then
			local chaleur = Catalogue.MATIERES[y.matiere].chaleur
			return not ((x.trait == "legere" and chaleur >= 0.6) or (x.trait == "chaude" and chaleur <= -0.7))
		elseif y.type == "max" then
			return x.trait ~= "travaillee"
		end
		return true
	end
	return sens(a, b) and sens(b, a)
end

-- plafond : dizaines de points au plus pour le style ou l'occasion demandés (monte avec le prestige) ; ouverts :
-- accessoires et matières qu'on peut demander (nil : tous) ; niveau : niveau de prestige (nil : tout se demande)
local function tirerExigences(rng, cliente, plafond, ouverts, niveau)
	local exigences = {}
	local styleMin = tirer(cliente and cliente.styles or Catalogue.STYLES, rng)
	table.insert(exigences, { type = "min", style = styleMin, valeur = rng:NextInteger(3, plafond) * 10 })
	local autres = { "max", "qualite", "teinte", "accessoire" }
	local occasions, traits, matieres = {}, {}, {}
	for _, o in ipairs(Catalogue.OCCASIONS) do
		if not niveau or niveau >= Commandes.PRESTIGE_ETIQUETTES[o] then
			table.insert(occasions, o)
		end
	end
	for _, t in ipairs(Catalogue.TRAITS) do
		if not niveau or niveau >= Commandes.PRESTIGE_ETIQUETTES[t] then
			table.insert(traits, t)
		end
	end
	for _, t in ipairs(Catalogue.Tissus) do
		if (not ouverts or ouverts.tissus[t.id]) and not table.find(matieres, t.matiere) then
			table.insert(matieres, t.matiere)
		end
	end
	if #occasions > 0 then
		table.insert(autres, "occasion")
	end
	if not niveau or niveau >= Commandes.PRESTIGE_MATIERE then
		table.insert(autres, "matiere")
	end
	if #traits > 0 then
		table.insert(autres, "trait")
	end
	for _ = 2, rng:NextInteger(1, 3) do
		local genre = table.remove(autres, rng:NextInteger(1, #autres))
		local e
		if genre == "max" then
			local style
			repeat
				style = tirer(Catalogue.STYLES, rng)
			until style ~= styleMin and not (cliente and table.find(cliente.styles, style))
			e = { type = "max", style = style, valeur = rng:NextInteger(1, 4) * 10 }
		elseif genre == "qualite" then
			e = { type = "qualite", valeur = rng:NextInteger(6, 9) / 10 }
		elseif genre == "teinte" then
			e = { type = "teinte", teinte = cliente and cliente.teinte or tirer(Catalogue.Tissus, rng).teinte }
		elseif genre == "accessoire" then
			local objets = {}
			for _, a in ipairs(Catalogue.Accessoires) do
				if a.genre == "objet" and (not ouverts or ouverts.accessoires[a.id]) then
					table.insert(objets, a.id)
				end
			end
			e = { type = "accessoire", id = tirer(objets, rng) }
		elseif genre == "occasion" then
			-- celle de la cliente, deux fois sur trois (si elle se demande déjà)
			local prefere = cliente and cliente.occasion and table.find(occasions, cliente.occasion) and rng:NextInteger(1, 3) <= 2
			e = { type = "occasion", occasion = if prefere then cliente.occasion else tirer(occasions, rng), valeur = rng:NextInteger(2, plafond) * 10 }
		elseif genre == "matiere" then
			e = { type = "matiere", matiere = tirer(matieres, rng) }
		else
			local trait = tirer(traits, rng)
			local dizaines = if table.find(Etiquettes.MOTIFS, trait) then rng:NextInteger(5, 10) else rng:NextInteger(2, 6)
			e = { type = "trait", trait = trait, valeur = dizaines * 10 }
		end
		local permise = true
		for _, x in ipairs(exigences) do
			permise = permise and Commandes.compatibles(x, e)
		end
		if permise then
			table.insert(exigences, e)
		end
	end
	return exigences
end
```

Dans `src/shared/Commandes.luau`, remplacer :

```lua
	local ouverts = progres and Deblocages.ouverts(progres)
	local plafond = progres and Commandes.plafond(Progression.niveauPrestige(progres.prestige)) or 7
	local exigences
	for _ = 1, Commandes.ESSAIS do
		local candidat = tirerExigences(rng, cliente, plafond, ouverts)
```

par :

```lua
	local ouverts = progres and Deblocages.ouverts(progres)
	local niveau = progres and Progression.niveauPrestige(progres.prestige)
	local plafond = niveau and Commandes.plafond(niveau) or 7
	local exigences
	for _ = 1, Commandes.ESSAIS do
		local candidat = tirerExigences(rng, cliente, plafond, ouverts, niveau)
```

Dans `src/shared/Commandes.luau`, remplacer :

```lua
		elseif e.type == "min" or e.type == "max" or e.type == "occasion" then
			table.insert(jugements, { cle = e.style or e.occasion, note = borne, croissant = true, auPlus = e.type == "max", valeur = e.valeur })
```

par :

```lua
		elseif e.type == "min" or e.type == "max" or e.type == "occasion" then
			-- (relecture du plan 21) une étiquette inconnue, d'une fiche mal écrite : irréalisable, jamais d'erreur au tirage
			if not (if e.type == "occasion" then table.find(Catalogue.OCCASIONS, e.occasion) else table.find(Catalogue.STYLES, e.style)) then
				return false
			end
			table.insert(jugements, { cle = e.style or e.occasion, note = borne, croissant = true, auPlus = e.type == "max", valeur = e.valeur })
```

- [ ] **Step 4: Lancer les tests**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT"`
Expected:
```
Unitaires : 193024 vérifications
TOUT EST VERT : 998 vérifications
```

- [ ] **Step 5: Commit**

```bash
git add src/shared/Commandes.luau src/shared/Clientes.luau src/shared/Catalogue.luau tests/unitaires/72_commandes_gouts.luau tests/unitaires/06_commandes.luau tests/unitaires/48_equilibrage.luau
git commit -m "Commandes : occasions, matière et traits demandés au fil du prestige, sans exigences contraires ; l'occasion préférée de chaque cliente

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 2: L'occasion des événements

**Files:**
- Modify: `src/shared/Histoire.luau`, `tests/unitaires/52_histoire.luau`

**Interfaces:**
- Consumes: le type d'exigence `occasion` (plan 21).
- Produces: les robes d'événement, à partir de la kermesse, demandent l'occasion de leur événement.

- [ ] **Step 1: Écrire les tests**

Dans `tests/unitaires/52_histoire.luau`, remplacer :

```lua
U.verifier(Histoire.commande("inconnue") == nil and Histoire.get("inconnu") == nil, "identifiant inconnu : rien")
```

par :

```lua
U.verifier(Histoire.commande("inconnue") == nil and Histoire.get("inconnu") == nil, "identifiant inconnu : rien")
-- (sous-projet 7) À partir de la kermesse, chaque robe qui n'a pas déjà trois exigences demande l'occasion de son
-- événement : la soirée au bal d'hiver et à la première, la journée à la kermesse et aux mariages
local sansOccasion, occasionsDe = {}, {}
for rang, ev in ipairs(Histoire.EVENEMENTS) do
	for _, c in ipairs(ev.commandes) do
		local o
		for _, e in ipairs(c.exigences) do
			o = o or e.occasion
		end
		occasionsDe[ev.id] = occasionsDe[ev.id] or o
		if rang >= 2 and not o and #c.exigences < 3 then
			table.insert(sansOccasion, c.id)
		end
	end
end
U.verifier(#sansOccasion == 0, "à partir de la kermesse, chaque robe demande l'occasion de son événement (sans : " .. table.concat(sansOccasion, ", ") .. ")")
U.verifier(occasionsDe.bal_hiver == "soiree" and occasionsDe.premiere == "soiree" and occasionsDe.kermesse == "journee" and occasionsDe.noces_colette == "journee" and occasionsDe.lanternes == nil, "le bal d'hiver et la première : la soirée ; la kermesse et les mariages : la journée")
```

- [ ] **Step 2: Lancer les tests, vérifier l'échec**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT|attempt|membre" | head -3`
Expected: échec : une ligne qui finit par `defile_josephine, defile_victoire)`

- [ ] **Step 3: Les occasions**

Dans `src/shared/Histoire.luau`, remplacer :

```lua
-- Histoire (sous-projets 3 et 4) : les douze événements du quartier, l'un après l'autre. Chacun demande quelques robes à
-- des clientes connues (tenue imposée, répliques qui racontent leur histoire) ; toutes livrées, l'événement a
-- lieu : un épilogue, un souvenir (une décoration nouvelle), du prestige. Contenu original.
```

par :

```lua
-- Histoire (sous-projets 3 et 4) : les douze événements du quartier, l'un après l'autre. Chacun demande quelques robes à
-- des clientes connues (tenue imposée, répliques qui racontent leur histoire) ; toutes livrées, l'événement a
-- lieu : un épilogue, un souvenir (une décoration nouvelle), du prestige. Contenu original. Sous-projet 7 : à partir
-- de la kermesse, chaque robe (qui n'a pas déjà trois exigences) demande l'occasion de son événement.
```

Dans `src/shared/Histoire.luau`, remplacer :

```lua
local function avec(id)
	return { type = "accessoire", id = id }
end
```

par :

```lua
local function avec(id)
	return { type = "accessoire", id = id }
end
local function occasion(o, valeur)
	return { type = "occasion", occasion = o, valeur = valeur }
end
```

Dans `src/shared/Histoire.luau`, remplacer :

```lua
			commande("kermesse_margot", "margot", { min("mignon", 30), teinte("jaune") },
```

par :

```lua
			commande("kermesse_margot", "margot", { min("mignon", 30), teinte("jaune"), occasion("journee", 30) },
```

Dans `src/shared/Histoire.luau`, remplacer :

```lua
			commande("kermesse_salome", "salome", { min("decontracte", 30), teinte("vert") },
```

par :

```lua
			commande("kermesse_salome", "salome", { min("decontracte", 30), teinte("vert"), occasion("journee", 30) },
```

Dans `src/shared/Histoire.luau`, remplacer :

```lua
			commande("vernissage_helene", "helene", { min("chic", 30), avec("perle") },
```

par :

```lua
			commande("vernissage_helene", "helene", { min("chic", 30), avec("perle"), occasion("journee", 20) },
```

Dans `src/shared/Histoire.luau`, remplacer :

```lua
			commande("vernissage_salome", "salome", { min("chic", 30), max("decontracte", 30) },
```

par :

```lua
			commande("vernissage_salome", "salome", { min("chic", 30), max("decontracte", 30), occasion("journee", 20) },
```

Dans `src/shared/Histoire.luau`, remplacer :

```lua
			commande("regates_colette", "colette", { min("mignon", 20), teinte("bleu") },
```

par :

```lua
			commande("regates_colette", "colette", { min("mignon", 20), teinte("bleu"), occasion("journee", 30) },
```

Dans `src/shared/Histoire.luau`, remplacer :

```lua
			commande("regates_helene", "helene", { min("chic", 30), teinte("bleu") },
```

par :

```lua
			commande("regates_helene", "helene", { min("chic", 30), teinte("bleu"), occasion("journee", 30) },
```

Dans `src/shared/Histoire.luau`, remplacer :

```lua
			commande("veillee_ines", "ines", { min("gothique", 30), teinte("noir") },
```

par :

```lua
			commande("veillee_ines", "ines", { min("gothique", 30), teinte("noir"), occasion("soiree", 20) },
```

Dans `src/shared/Histoire.luau`, remplacer :

```lua
			commande("veillee_helene", "helene", { min("elegant", 40), max("mignon", 20) },
```

par :

```lua
			commande("veillee_helene", "helene", { min("elegant", 40), max("mignon", 20), occasion("soiree", 20) },
```

Dans `src/shared/Histoire.luau`, remplacer :

```lua
			commande("mariage_colette", "colette", { min("romantique", 30), teinte("rose") },
```

par :

```lua
			commande("mariage_colette", "colette", { min("romantique", 30), teinte("rose"), occasion("journee", 30) },
```

Dans `src/shared/Histoire.luau`, remplacer :

```lua
			commande("mariage_victoire", "victoire", { min("elegant", 40) },
```

par :

```lua
			commande("mariage_victoire", "victoire", { min("elegant", 40), occasion("journee", 30) },
```

Dans `src/shared/Histoire.luau`, remplacer :

```lua
			commande("kiosque_salome", "salome", { min("chic", 40) },
```

par :

```lua
			commande("kiosque_salome", "salome", { min("chic", 40), occasion("journee", 20) },
```

Dans `src/shared/Histoire.luau`, remplacer :

```lua
			commande("kiosque_ines", "ines", { min("gothique", 40) },
```

par :

```lua
			commande("kiosque_ines", "ines", { min("gothique", 40), occasion("journee", 20) },
```

Dans `src/shared/Histoire.luau`, remplacer :

```lua
			commande("kiosque_victoire", "victoire", { min("chic", 30), teinte("bleu") },
```

par :

```lua
			commande("kiosque_victoire", "victoire", { min("chic", 30), teinte("bleu"), occasion("journee", 20) },
```

Dans `src/shared/Histoire.luau`, remplacer :

```lua
			commande("bal_colette", "colette", { min("romantique", 45) },
```

par :

```lua
			commande("bal_colette", "colette", { min("romantique", 45), occasion("soiree", 40) },
```

Dans `src/shared/Histoire.luau`, remplacer :

```lua
			commande("bal_helene", "helene", { min("elegant", 45) },
```

par :

```lua
			commande("bal_helene", "helene", { min("elegant", 45), occasion("soiree", 40) },
```

Dans `src/shared/Histoire.luau`, remplacer :

```lua
			commande("bal_ines", "ines", { min("gothique", 40) },
```

par :

```lua
			commande("bal_ines", "ines", { min("gothique", 40), occasion("soiree", 40) },
```

Dans `src/shared/Histoire.luau`, remplacer :

```lua
			commande("bal_victoire", "victoire", { min("elegant", 45), teinte("blanc") },
```

par :

```lua
			commande("bal_victoire", "victoire", { min("elegant", 45), teinte("blanc"), occasion("soiree", 40) },
```

Dans `src/shared/Histoire.luau`, remplacer :

```lua
			commande("salon_josephine", "josephine", { min("chic", 30), teinte("brun") },
```

par :

```lua
			commande("salon_josephine", "josephine", { min("chic", 30), teinte("brun"), occasion("journee", 20) },
```

Dans `src/shared/Histoire.luau`, remplacer :

```lua
			commande("salon_apolline", "apolline", { min("romantique", 35), teinte("violet") },
```

par :

```lua
			commande("salon_apolline", "apolline", { min("romantique", 35), teinte("violet"), occasion("journee", 20) },
```

Dans `src/shared/Histoire.luau`, remplacer :

```lua
			commande("salon_salome", "salome", { min("chic", 30), teinte("vert") },
```

par :

```lua
			commande("salon_salome", "salome", { min("chic", 30), teinte("vert"), occasion("journee", 20) },
```

Dans `src/shared/Histoire.luau`, remplacer :

```lua
			commande("premiere_capucine", "capucine", { min("romantique", 35), teinte("rouge") },
```

par :

```lua
			commande("premiere_capucine", "capucine", { min("romantique", 35), teinte("rouge"), occasion("soiree", 40) },
```

Dans `src/shared/Histoire.luau`, remplacer :

```lua
			commande("premiere_ines", "ines", { min("gothique", 40), max("mignon", 20) },
```

par :

```lua
			commande("premiere_ines", "ines", { min("gothique", 40), max("mignon", 20), occasion("soiree", 40) },
```

Dans `src/shared/Histoire.luau`, remplacer :

```lua
			commande("premiere_victoire", "victoire", { min("elegant", 45) },
```

par :

```lua
			commande("premiere_victoire", "victoire", { min("elegant", 45), occasion("soiree", 40) },
```

Dans `src/shared/Histoire.luau`, remplacer :

```lua
			commande("noces_colette", "colette", { min("romantique", 40), teinte("blanc") },
```

par :

```lua
			commande("noces_colette", "colette", { min("romantique", 40), teinte("blanc"), occasion("journee", 20) },
```

Dans `src/shared/Histoire.luau`, remplacer :

```lua
			commande("noces_margot", "margot", { min("mignon", 35), teinte("rose") },
```

par :

```lua
			commande("noces_margot", "margot", { min("mignon", 35), teinte("rose"), occasion("journee", 20) },
```

Dans `src/shared/Histoire.luau`, remplacer :

```lua
			commande("noces_apolline", "apolline", { min("romantique", 35), teinte("violet") },
```

par :

```lua
			commande("noces_apolline", "apolline", { min("romantique", 35), teinte("violet"), occasion("journee", 20) },
```

Dans `src/shared/Histoire.luau`, remplacer :

```lua
			commande("defile_maelle", "maelle", { min("decontracte", 40), teinte("bleu") },
```

par :

```lua
			commande("defile_maelle", "maelle", { min("decontracte", 40), teinte("bleu"), occasion("journee", 20) },
```

Dans `src/shared/Histoire.luau`, remplacer :

```lua
			commande("defile_capucine", "capucine", { min("gothique", 40) },
```

par :

```lua
			commande("defile_capucine", "capucine", { min("gothique", 40), occasion("journee", 20) },
```

Dans `src/shared/Histoire.luau`, remplacer :

```lua
			commande("defile_josephine", "josephine", { min("chic", 40) },
```

par :

```lua
			commande("defile_josephine", "josephine", { min("chic", 40), occasion("journee", 20) },
```

Dans `src/shared/Histoire.luau`, remplacer :

```lua
			commande("defile_victoire", "victoire", { min("elegant", 40), teinte("bleu") },
```

par :

```lua
			commande("defile_victoire", "victoire", { min("elegant", 40), teinte("bleu"), occasion("journee", 20) },
```

- [ ] **Step 4: Lancer les tests**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT"`
Expected:
```
Unitaires : 193026 vérifications
TOUT EST VERT : 998 vérifications
```

- [ ] **Step 5: Commit**

```bash
git add src/shared/Histoire.luau tests/unitaires/52_histoire.luau
git commit -m "Histoire : à partir de la kermesse, chaque robe demande l'occasion de son événement

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 3: Le carnet : jauges, cartes, filtre

**Files:**
- Create: `tests/unitaires/73_carnet_etiquettes.luau`
- Modify: `src/shared/Etiquettes.luau`, `src/client/Atelier/EcranCarnet.luau`, `tests/scenario.luau`

**Interfaces:**
- Consumes: `Notation.fourchette` (étiquettes, plan 21), `Etiquettes.tissu`, `Etiquettes.traitsIndice`.
- Produces: `Etiquettes.nom(cle)` → texte ; `Etiquettes.apportsTissu(idTissu)` → `{ { cle, valeur } }` du plus fort au plus faible. Dans la fiche, `Jauge_<cle>` et `NomJauge_<cle>` ; dans le choix du tissu, `Filtre_<style ou occasion>` et, sur chaque carte ouverte, `Etiquettes`.

- [ ] **Step 1: Écrire les tests**

Créer `tests/unitaires/73_carnet_etiquettes.luau` :

```lua
-- Sous-projet 7 : le carnet montre les jauges des étiquettes demandées et des styles de la cliente (pas seize) ; une
-- carte de tissu, ses quatre étiquettes les plus fortes ; le filtre des tissus s'étend aux occasions.
local Session = U.module("Session")
local UiKit = U.module("UiKit")
local Catalogue = U.module("Catalogue")
local Etiquettes = U.module("Etiquettes")
local EcranCarnet = U.module("EcranCarnet")

---------------------------------------------------------------------------
-- Les noms, les apports d'un tissu
---------------------------------------------------------------------------
local sansNom = {}
for _, liste in ipairs({ Catalogue.STYLES, Catalogue.OCCASIONS, Catalogue.TRAITS }) do
	for _, cle in ipairs(liste) do
		if type(Etiquettes.nom(cle)) ~= "string" then
			table.insert(sansNom, cle)
		end
	end
end
U.verifier(#sansNom == 0 and Etiquettes.nom("soiree") == "Soirée" and Etiquettes.nom("a_motifs") == "À motifs", "chaque étiquette a son nom")
local function premieres(idTissu)
	local noms = {}
	for k, a in ipairs(Etiquettes.apportsTissu(idTissu)) do
		if k <= 4 then
			table.insert(noms, a.cle)
		end
	end
	return table.concat(noms, ",")
end
U.verifier(premieres("organza_blanc") == "legere,soiree,romantique,mignon", "organza blanc : Légère, Soirée, Romantique, Mignon (" .. premieres("organza_blanc") .. ")")
U.verifier(premieres("laine_noire") == "chaude,travail,gothique,chic", "laine noire : Chaude, Travail, Gothique, Chic (" .. premieres("laine_noire") .. ")")
U.verifier(premieres("crepe_noir") == "elegant,chic,travail,soiree", "crêpe noir (ni légère ni chaude ; à égalité, le style d'abord) : Élégant, Chic, Travail, Soirée (" .. premieres("crepe_noir") .. ")")

---------------------------------------------------------------------------
-- La fiche : les jauges demandées, puis les styles de la cliente ; une robe libre : les six styles
---------------------------------------------------------------------------
local session = Session.nouvelle(22)
U.commander(session)
local etat = session.etat
etat.commande.cliente = "colette" -- (romantique et mignon)
etat.commande.exigences = {
	{ type = "min", style = "romantique", valeur = 30 },
	{ type = "occasion", occasion = "soiree", valeur = 40 },
	{ type = "trait", trait = "legere", valeur = 50 },
}
local function contexte()
	local fenetre = UiKit.creer("Frame", { Name = "Fenetre", Size = UDim2.fromOffset(900, 560) })
	local contenu = UiKit.creer("Frame", { Name = "Contenu", Size = UDim2.fromOffset(860, 466), Parent = fenetre })
	return { UiKit = UiKit, session = session, contenu = contenu, fenetre = fenetre, message = function() end, refus = function() end }
end
local function jauges(droite)
	local liste = {}
	for _, d in ipairs(droite:GetChildren()) do
		if d.Name:sub(1, 6) == "Jauge_" then
			table.insert(liste, d)
		end
	end
	table.sort(liste, function(a, b)
		return a.Position.Y.Offset < b.Position.Y.Offset
	end)
	local noms = {}
	for _, j in ipairs(liste) do
		table.insert(noms, (j.Name:gsub("^Jauge_", "")))
	end
	return table.concat(noms, ","), liste
end
local ctx = contexte()
local fermer = EcranCarnet(ctx)
local droite = ctx.contenu.Droite
local ordre, liste = jauges(droite)
U.verifier(ordre == "romantique,soiree,legere,mignon", "la fiche : les trois étiquettes demandées, puis le second style de la cliente (" .. ordre .. ")")
local cibles = 0
for _, j in ipairs(liste) do
	cibles += if j:FindFirstChild("Cible") then 1 else 0
end
U.verifier(cibles == 3 and droite.NomJauge_soiree.Text == "Soirée" and droite.NomJauge_legere.Text == "Légère", "un repère sur chaque jauge demandée, et leurs noms")
U.verifier(droite.Jauge_soiree.Plage.Size.X.Scale > 0 and droite.Jauge_legere.Plage.Size.X.Scale > 0, "les jauges d'occasion et de trait montrent ce que les tissus peuvent donner")

---------------------------------------------------------------------------
-- Le choix du tissu : cartes à quatre étiquettes, filtre par occasion
---------------------------------------------------------------------------
M.avancer(0.5)
droite.Parent.Page.ToutEnUnTissu.Activated:Fire()
local choix = ctx.contenu:FindFirstChild("ChoixTissu")
local function cartes()
	local out = {}
	for _, c in ipairs(choix.Grille:GetChildren()) do
		if c.Name:sub(1, 6) == "Tissu_" then
			out[c.Name:sub(7)] = c
		end
	end
	return out
end
local toutes = cartes()
local n = 0
for _ in pairs(toutes) do
	n += 1
end
U.verifier(choix ~= nil and n == #Catalogue.Tissus, "le choix du tissu montre tous les tissus (" .. n .. ")")
local texteOrganza = toutes.organza_blanc and toutes.organza_blanc:FindFirstChild("Etiquettes")
U.verifier(texteOrganza ~= nil and texteOrganza.Text == "18 po/m · Légère, Soirée, Romantique, Mignon", "organza blanc : « " .. (texteOrganza and texteOrganza.Text or "?") .. " »")
local texteCoton = toutes.coton_blanc.Etiquettes.Text
U.verifier(texteCoton == "4 po/m · Journée, Légère, Décontracté, Travail", "coton blanc : « " .. texteCoton .. " »")
M.avancer(0.5)
choix.Filtre_soiree.Activated:Fire()
local soir, intrus = 0, {}
for id in pairs(cartes()) do
	soir += 1
	if (Catalogue.MATIERES[Catalogue.tissu(id).matiere].occasion.soiree or 0) == 0 then
		table.insert(intrus, id)
	end
end
U.verifier(soir > 0 and soir < n and #intrus == 0 and choix.Filtre_soiree.Position.Y.Offset == 40, ("filtre « Soirée », sur la seconde rangée : %d tissus de soirée (intrus : %s)"):format(soir, table.concat(intrus, ", ")))
fermer()

local libre = Session.nouvelle(23)
libre.etat.livraisons = 10
assert(libre.etat:nouvelleRobeLibre("M").ok)
session = libre
local ctxL = contexte()
local fermerL = EcranCarnet(ctxL)
U.verifier((jauges(ctxL.contenu.Droite)) == table.concat(Catalogue.STYLES, ","), "une robe libre : les six styles")
fermerL()
```

Dans `tests/scenario.luau`, remplacer :

```lua
	local ecarts = {}
	for _, style in ipairs(Catalogue.STYLES) do
		if math.abs(fenetre.Contenu.Droite["Jauge_" .. style].Plage.Size.X.Scale - fOuverts[style].max / 100) > 1e-9 then
			table.insert(ecarts, style)
		end
	end
	verifier(fOuverts.elegant.max < fTous.elegant.max and #ecarts == 0, "au départ, les six jauges s'arrêtent à ce que les tissus ouverts peuvent donner (en défaut : " .. table.concat(ecarts, ", ") .. ")")
```

par :

```lua
	-- (sous-projet 7 : les jauges des étiquettes demandées et des styles de la cliente, pas toujours les six)
	local ecarts, montrees = {}, 0
	for _, jauge in ipairs(fenetre.Contenu.Droite:GetChildren()) do
		local cle = jauge.Name:match("^Jauge_(.+)$")
		if cle then
			montrees += 1
			if math.abs(jauge.Plage.Size.X.Scale - fOuverts[cle].max / 100) > 1e-9 then
				table.insert(ecarts, cle)
			end
		end
	end
	verifier(fOuverts.elegant.max < fTous.elegant.max and montrees >= 2 and #ecarts == 0, "au départ, les jauges s'arrêtent à ce que les tissus ouverts peuvent donner (en défaut : " .. table.concat(ecarts, ", ") .. ")")
```

Dans `tests/scenario.luau`, remplacer :

```lua
verifier(boutonNomme("Tissu_toile_jute") ~= nil and texte("Gratuit · Décontracté") ~= nil, "la toile de jute est gratuite")
```

par :

```lua
verifier(boutonNomme("Tissu_toile_jute") ~= nil and texte("Gratuit · Journée, Travail, Décontracté, Chaude") ~= nil, "la toile de jute est gratuite (et ses quatre étiquettes)")
```

Dans `tests/scenario.luau`, remplacer :

```lua
local derniereJauge = fenetre.Contenu.Droite["Jauge_" .. Catalogue.STYLES[#Catalogue.STYLES]]
```

par :

```lua
local derniereJauge -- (sous-projet 7 : la plus basse des jauges montrées)
for _, j in ipairs(fenetre.Contenu.Droite:GetChildren()) do
	if j.Name:match("^Jauge_") and (not derniereJauge or j.Position.Y.Offset > derniereJauge.Position.Y.Offset) then
		derniereJauge = j
	end
end
```

- [ ] **Step 2: Lancer les tests, vérifier l'échec**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT|attempt|membre" | head -3`
Expected: échec : une ligne qui finit par `attempt to call a nil value`

- [ ] **Step 3: Les étiquettes au carnet**

Dans `src/shared/Etiquettes.luau`, remplacer :

```lua
function Etiquettes.variante(id)
	return VARIANTES[id]
end
function Etiquettes.tissu(id)
	return TISSUS[id]
end
```

par :

```lua
function Etiquettes.variante(id)
	return VARIANTES[id]
end
function Etiquettes.tissu(id)
	return TISSUS[id]
end

-- Le nom d'une étiquette : un style, une occasion ou un trait
function Etiquettes.nom(cle)
	return Catalogue.NOMS_STYLES[cle] or Catalogue.NOMS_OCCASIONS[cle] or Catalogue.NOMS_TRAITS[cle]
end
```

Dans `src/shared/Etiquettes.luau`, remplacer :

```lua
-- Nombre de décorations : accessoires = { { id, longueur? } } (un objet 1 ; une garniture 1 pour 5 dm, sans longueur 0)
```

par :

```lua
-- Ce qu'un tissu apporte à une robe faite toute de lui, du plus fort au plus faible : ses styles et ses occasions (leurs
-- points), Légère ou Chaude (la part de sa matière dans l'indice de chaleur, × 100) ; son motif se voit sur
-- l'échantillon. Retourne { { cle, valeur } } (valeurs non nulles ; à égalité, les styles, puis les occasions)
function Etiquettes.apportsTissu(idTissu)
	local t, a = Catalogue.tissu(idTissu), TISSUS[idTissu]
	local liste = {}
	for _, s in ipairs(Catalogue.STYLES) do
		local v = Catalogue.K.tissu * (t.style[s] or 0)
		if v > 0 then
			table.insert(liste, { cle = s, valeur = v })
		end
	end
	for _, o in ipairs(Catalogue.OCCASIONS) do
		if a.occasions[o] > 0 then
			table.insert(liste, { cle = o, valeur = a.occasions[o] })
		end
	end
	local chaude, legere = Etiquettes.traitsIndice(a.chaleur)
	if chaude > 0 then
		table.insert(liste, { cle = "chaude", valeur = chaude })
	elseif legere > 0 then
		table.insert(liste, { cle = "legere", valeur = legere })
	end
	for i, x in ipairs(liste) do
		x.rang = i
	end
	table.sort(liste, function(x, y)
		return x.valeur > y.valeur or (x.valeur == y.valeur and x.rang < y.rang)
	end)
	return liste
end

-- Nombre de décorations : accessoires = { { id, longueur? } } (un objet 1 ; une garniture 1 pour 5 dm, sans longueur 0)
```

Dans `src/client/Atelier/EcranCarnet.luau`, remplacer :

```lua
local Croquis = require(Couture:WaitForChild("Croquis"))
```

par :

```lua
local Croquis = require(Couture:WaitForChild("Croquis"))
local Etiquettes = require(Couture:WaitForChild("Etiquettes"))
```

Dans `src/client/Atelier/EcranCarnet.luau`, remplacer :

```lua
	local jauges = {}
	local y0 = yExigence + 10
	for i, style in ipairs(Catalogue.STYLES) do
		local y = y0 + (i - 1) * 30
		UiKit.texte({ Text = Catalogue.NOMS_STYLES[style], TextSize = 14, Position = UDim2.fromOffset(12, y), Size = UDim2.fromOffset(100, 20), Parent = droite })
		local fond = UiKit.arrondir(UiKit.creer("Frame", { Name = "Jauge_" .. style, BackgroundColor3 = C.secondaire, Position = UDim2.fromOffset(112, y + 4), Size = UDim2.fromOffset(180, 12), Parent = droite }), 6)
		local plage = UiKit.creer("Frame", { Name = "Plage", BackgroundColor3 = C.accent, BackgroundTransparency = 0.65, BorderSizePixel = 0, Parent = fond })
		local acquis = UiKit.creer("Frame", { Name = "Acquis", BackgroundColor3 = C.accent, BorderSizePixel = 0, Parent = fond })
		for _, e in ipairs(etat.commande.exigences) do
			if e.style == style then
				UiKit.creer("Frame", { Name = "Cible", BackgroundColor3 = C.texte, BorderSizePixel = 0, Position = UDim2.new(e.valeur / 100, -1, 0, -3), Size = UDim2.new(0, 2, 1, 6), Parent = fond })
			end
		end
		jauges[style] = { plage = plage, acquis = acquis }
	end
```

par :

```lua
	-- Les jauges (sous-projet 7) : les étiquettes que la commande demande, puis les styles de la cliente, sans doublon ;
	-- sans rien de chiffré à suivre (une robe libre…), les six styles
	local cles = {}
	for _, e in ipairs(etat.commande.exigences) do
		local cle = e.style or e.occasion or e.trait
		if cle and not table.find(cles, cle) then
			table.insert(cles, cle)
		end
	end
	for _, s in ipairs(fiche and fiche.styles or {}) do
		if not table.find(cles, s) then
			table.insert(cles, s)
		end
	end
	if #cles == 0 then
		cles = table.clone(Catalogue.STYLES)
	end
	local jauges = {}
	local y0 = yExigence + 10
	for i, cle in ipairs(cles) do
		local y = y0 + (i - 1) * 30
		UiKit.texte({ Name = "NomJauge_" .. cle, Text = Etiquettes.nom(cle), TextSize = 14, Position = UDim2.fromOffset(12, y), Size = UDim2.fromOffset(100, 20), Parent = droite })
		local fond = UiKit.arrondir(UiKit.creer("Frame", { Name = "Jauge_" .. cle, BackgroundColor3 = C.secondaire, Position = UDim2.fromOffset(112, y + 4), Size = UDim2.fromOffset(180, 12), Parent = droite }), 6)
		local plage = UiKit.creer("Frame", { Name = "Plage", BackgroundColor3 = C.accent, BackgroundTransparency = 0.65, BorderSizePixel = 0, Parent = fond })
		local acquis = UiKit.creer("Frame", { Name = "Acquis", BackgroundColor3 = C.accent, BorderSizePixel = 0, Parent = fond })
		for _, e in ipairs(etat.commande.exigences) do
			if (e.style or e.occasion or e.trait) == cle then
				UiKit.creer("Frame", { Name = "Cible", BackgroundColor3 = C.texte, BorderSizePixel = 0, Position = UDim2.new(e.valeur / 100, -1, 0, -3), Size = UDim2.new(0, 2, 1, 6), Parent = fond })
			end
		end
		jauges[cle] = { plage = plage, acquis = acquis }
	end
```

Dans `src/client/Atelier/EcranCarnet.luau`, remplacer :

```lua
	-- Choix du tissu de pièces (par-dessus le carnet), filtrable par style. Un bouton sans texte, pas un simple
```

par :

```lua
	-- Choix du tissu de pièces (par-dessus le carnet), filtrable par style ou par occasion. Un bouton sans texte, pas un simple
```

Dans `src/client/Atelier/EcranCarnet.luau`, remplacer :

```lua
			Position = UDim2.fromOffset(0, 44),
			Size = UDim2.new(1, 0, 1, -44),
```

par :

```lua
			Position = UDim2.fromOffset(0, 84),
			Size = UDim2.new(1, 0, 1, -84),
```

Dans `src/client/Atelier/EcranCarnet.luau`, remplacer :

```lua
		UiKit.creer("UIGridLayout", { CellSize = UDim2.fromOffset(200, 96), CellPadding = UDim2.fromOffset(8, 8), Parent = grille })
		local function remplir(filtre)
```

par :

```lua
		UiKit.creer("UIGridLayout", { CellSize = UDim2.fromOffset(200, 112), CellPadding = UDim2.fromOffset(8, 8), Parent = grille })
		-- filtre : { style } ou { occasion } (celle de la matière du tissu), ou nil : tous
		local function remplir(filtre)
```

Dans `src/client/Atelier/EcranCarnet.luau`, remplacer :

```lua
				if not filtre or (t.style[filtre] or 0) > 0 then
```

par :

```lua
				local garde = not filtre
					or (filtre.style and (t.style[filtre.style] or 0) > 0)
					or (filtre.occasion and (Catalogue.MATIERES[t.matiere].occasion[filtre.occasion] or 0) > 0)
				if garde then
```

Dans `src/client/Atelier/EcranCarnet.luau`, remplacer :

```lua
						Size = UDim2.fromOffset(56, 80),
```

par :

```lua
						Size = UDim2.fromOffset(56, 96),
```

Dans `src/client/Atelier/EcranCarnet.luau`, remplacer :

```lua
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
					if ouvert then
						UiKit.texte({ Text = (if t.prix == 0 then "Gratuit" else ("%d po/m"):format(t.prix)) .. " · " .. table.concat(etiquettes, ", "), TextSize = 14, TextColor3 = C.texteDoux, Position = UDim2.fromOffset(72, 50), Size = UDim2.new(1, -80, 0, 36), ZIndex = 13, Parent = carte })
					else
```

par :

```lua
					-- (sous-projet 7) ses quatre étiquettes les plus fortes : styles, occasions, Légère ou Chaude
					local etiquettes = {}
					for k, a in ipairs(Etiquettes.apportsTissu(t.id)) do
						if k <= 4 then
							table.insert(etiquettes, Etiquettes.nom(a.cle))
						end
					end
					if ouvert then
						UiKit.texte({ Name = "Etiquettes", Text = (if t.prix == 0 then "Gratuit" else ("%d po/m"):format(t.prix)) .. " · " .. table.concat(etiquettes, ", "), TextSize = 14, TextColor3 = C.texteDoux, TextYAlignment = Enum.TextYAlignment.Top, Position = UDim2.fromOffset(72, 46), Size = UDim2.new(1, -80, 0, 60), ZIndex = 13, Parent = carte })
					else
```

Dans `src/client/Atelier/EcranCarnet.luau`, remplacer :

```lua
		local filtres = { { nom = "Tous" } }
		for _, s in ipairs(Catalogue.STYLES) do
			table.insert(filtres, { nom = Catalogue.NOMS_STYLES[s], style = s })
		end
		for k, f in ipairs(filtres) do
			UiKit.boutonDoux({ Name = "Filtre_" .. (f.style or "tous"), Text = f.nom, TextSize = 14, Position = UDim2.fromOffset((k - 1) * 106, 0), Size = UDim2.fromOffset(100, 34), ZIndex = 11, Parent = choix }, function()
				remplir(f.style)
			end)
		end
		remplir(nil)
```

par :

```lua
		-- Deux rangées de filtres : « Tous » et les styles, puis les occasions
		local filtres = { { nom = "Tous", x = 0, y = 0 } }
		for k, s in ipairs(Catalogue.STYLES) do
			table.insert(filtres, { nom = Catalogue.NOMS_STYLES[s], style = s, x = k * 106, y = 0 })
		end
		for k, o in ipairs(Catalogue.OCCASIONS) do
			table.insert(filtres, { nom = Catalogue.NOMS_OCCASIONS[o], occasion = o, x = (k - 1) * 106, y = 40 })
		end
		for _, f in ipairs(filtres) do
			UiKit.boutonDoux({ Name = "Filtre_" .. (f.style or f.occasion or "tous"), Text = f.nom, TextSize = 14, Position = UDim2.fromOffset(f.x, f.y), Size = UDim2.fromOffset(100, 34), ZIndex = 11, Parent = choix }, function()
				remplir(if f.style or f.occasion then f else nil)
			end)
		end
		remplir(nil)
```

- [ ] **Step 4: Lancer les tests**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT"`
Expected:
```
Unitaires : 193038 vérifications
TOUT EST VERT : 998 vérifications
```

- [ ] **Step 5: Commit**

```bash
git add src/shared/Etiquettes.luau src/client/Atelier/EcranCarnet.luau tests/unitaires/73_carnet_etiquettes.luau tests/scenario.luau
git commit -m "Carnet : les jauges des étiquettes demandées et des styles de la cliente ; quatre étiquettes par tissu ; filtre par occasion

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

Construire le lieu du dépôt dans un dossier temporaire (`C:/dev/jeux/roblox-maker/rojo.exe build -o <dossier temporaire>/Plan22Depot.rbxl`) et l'ouvrir dans Studio. En édition (`execute_luau`, Edit) : mesurer avec `TextService:GetTextSize` (Gotham, 14 px, 120 px de large) le texte de la carte la plus chargée (prix et quatre étiquettes) et le plus long nom de jauge ; mesurer (`os.clock`) `Commandes.generer` sur 200 commandes au prestige 8 (amitiés au plus haut) puis au prestige 4 (amitiés nulles). Rendre la fiche du carnet dans un `ScreenGui` d'essai de `StarterGui` (une commande de Colette : au moins 30 en Romantique, Soirée 40, Légère 50) et la regarder (`screen_capture`), puis supprimer ce `ScreenGui`. Enfin en Play : attendre 4 s, relever la console.

Expected : la carte tient en 60 px de haut (40 pendant la préparation), le nom le plus long en 100 px (75) ; une commande en moins de 5 ms en moyenne et de 100 ms au pire (0,4 à 0,6 et 28 ms pendant la préparation) ; quatre jauges (Romantique, Soirée, Légère, Mignon) avec un repère sur les trois premières ; aucune alerte de notre code (« Lieu non publié » et les messages internes de Roblox mis à part). Arrêter Play et fermer cette fenêtre de Studio (sans enregistrer).

- [ ] **Step 2: Mettre à jour le README**

Dans `README.md`, remplacer :

```markdown
## État actuel (sous-projet 7 en cours, plans 19 à 21 : des robes à couches, volant et basque ; seize étiquettes)
```

par :

```markdown
## État actuel (sous-projet 7 en cours, plans 19 à 22 : des robes à couches, volant et basque ; seize étiquettes)
```

Dans `README.md`, remplacer :

```markdown
   au-dessus de la tête), avec 1 à 3 exigences tirées de ses styles préférés et de sa teinte. Dix clientes, qui
```

par :

```markdown
   au-dessus de la tête), avec 1 à 3 exigences tirées de ses styles préférés, de sa teinte et de son occasion. Dix clientes, qui
```

Dans `README.md`, remplacer :

```markdown
   À côté du dessin, un tissu par pièce (41 tissus en onze matières, filtre par style, dont la toile de jute,
   gratuite) ; les échantillons des tissus choisis sont épinglés en haut de la page ; « Environ X m de tissu » ;
   « Tracer le patron ». La fiche de la commande, à droite : jauges de style, état des exigences, coût du tissu
```

par :

```markdown
   À côté du dessin, un tissu par pièce (41 tissus en onze matières, filtre par style ou par occasion, dont la
   toile de jute, gratuite ; chaque carte montre les quatre étiquettes les plus fortes du tissu) ; les échantillons
   des tissus choisis sont épinglés en haut de la page ; « Environ X m de tissu » ; « Tracer le patron ». La fiche
   de la commande, à droite : les jauges des étiquettes demandées et des styles de la cliente (les six styles pour
   une robe libre), état des exigences, coût du tissu
```

Dans `README.md`, remplacer :

```markdown
   **Seize étiquettes** (sous-projet 7, plan 21 : le calcul ; les commandes les demanderont au plan 22) : aux six
   styles s'ajoutent trois occasions (Journée, Soirée, Travail : points des variantes et des matières) et sept
   traits calculés d'après la robe : Légère / Chaude (matière, manches, longueur de la jupe), Sobre / Travaillée
   (poids des pièces, décorations), Unie / Fleurie / À motifs (surface de chaque motif) ; et la matière dominante.
   La cliente sait juger ces exigences, le carnet les prévoit, la sauvegarde les garde.
```

par :

```markdown
   **Seize étiquettes** (sous-projet 7) : aux six styles s'ajoutent trois occasions (Journée, Soirée, Travail :
   points des variantes et des matières) et sept traits calculés d'après la robe : Légère / Chaude (matière,
   manches, longueur de la jupe), Sobre / Travaillée (poids des pièces, décorations), Unie / Fleurie / À motifs
   (surface de chaque motif) ; et la matière dominante. Les commandes les demandent au fil du prestige : Journée et
   Travail au 2, la matière (« Matière dominante : crêpe ») au 3, la Soirée et les traits au 4, chacune quand elle
   peut atteindre 60 ; jamais deux exigences contraires (Légère et Chaude, une robe légère en velours, Travaillée
   et un « au plus »…). Chaque cliente a son occasion préférée ; à partir de la kermesse, chaque événement impose
   la sienne (le bal d'hiver : la soirée).
```

- [ ] **Step 3: Tests, lieu régénéré, commit**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT"`
Expected:
```
Unitaires : 193038 vérifications
TOUT EST VERT : 998 vérifications
```

```bash
C:/dev/jeux/roblox-maker/rojo.exe build -o AtelierCouture.rbxl
git add README.md AtelierCouture.rbxl
git commit -m "Plan 22 terminé : les étiquettes, jeu

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```
