# Aiguille & Dentelle — Plan 8c : quatre clientes et quatre événements

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Dernier plan du sous-projet 4 : quatre clientes qui arrivent tard (Apolline au prestige 5, Joséphine au 6, Capucine au 7, Maëlle au 8), dont l'amitié ouvre les quatre dernières variantes et quatre décorations ; quatre événements de fin de partie (le salon du livre, la première du théâtre, le mariage de Colette, le grand défilé du quartier) avec leurs souvenirs ; un carnet d'adresses et un choix « Offrir à… » qui tiennent avec dix clientes ; l'équilibrage revu.

**Architecture:**
- **Clientes** : quatre fiches de plus (mêmes champs que les six premières) ; leurs déblocages d'amitié remplacent les conditions provisoires de prestige 8 du plan 8b (`Deblocages.PRESTIGE_VARIANTES` ne garde que les manches courtes et la jupe crayon).
- **Catalogue** : quatre décorations d'amitié (violette, boucle d'écaille, dentelle rouge, coquillage) et quatre souvenirs (marque-page doré, masque de théâtre, alliance d'or, rosette d'honneur).
- **Histoire** : quatre événements à la suite des huit premiers (prestiges 6, 7, 7, 8).
- **Écrans** : le carnet d'adresses met ses lignes dans une liste qui défile ; « Offrir à… » serre ses boutons.
- **Simulation d'équilibrage** : parties de 160 robes ; le joueur simulé parcourt les robes de la moins chère à la plus chère et garde en mémoire les styles déjà calculés (mêmes choix, trois fois plus vite).

**Tech Stack:** Luau, Rojo 7.7.0-rc.1, simulation Luau 0.650 (`tests/lancer.sh`), Roblox Studio via le connecteur MCP Studio.

**Spec:** `docs/superpowers/specs/2026-09-30-ampleur-contenu-design.md` (§3 les quatre accessoires d'amitié, §5 clientes et événements, §7 équilibrage, §9 plan 8c). Amendée avec ce plan : §1 (39 accessoires en comptant les douze souvenirs), §4 (le bustier se porte avec manches et col détachés, épaules nues : décision de la relecture du plan 8b), §7 (« tout ouvert » mesuré vers la 123e robe).

## Décisions de ce plan

- **Clientes** (contenu original ; toutes vouvoient la couturière) : Apolline Garnier, poétesse (romantique, chic ; violet ; M ; prestige 5 ; cache-cœur puis violette) ; Joséphine Lambert, libraire d'en face (chic, décontracté ; brun ; L ; prestige 6 ; trois-quarts puis boucle d'écaille) ; Capucine Morel, comédienne (gothique, romantique ; rouge ; S ; prestige 7 ; bustier puis dentelle rouge) ; Maëlle Bertin, navigatrice (décontracté, mignon ; bleu ; M ; prestige 8 ; col marin puis coquillage). Mesures à 0,1 ou 0,2 dm de leur taille.
- **Événements** (après le grand bal d'hiver) : le salon du livre (prestige 6 : Joséphine, Apolline, Salomé), la première du théâtre (7 : Capucine, Inès, Victoire), le mariage de Colette (7 : Colette, Margot, Apolline ; la demande du bal d'hiver trouve sa suite), le grand défilé du quartier (8 : Maëlle, Capucine, Joséphine, Victoire ; épilogue de fin). Les exigences ont été réglées pour être réalisables à amitié nulle au prestige de l'événement (test 52) : par exemple, rien au-delà de 20 en gothique avec du rouge au prestige 7, d'où « romantique 35, rouge » pour Capucine à la première.
- **Équilibrage** (spec §7, bornes revues) : avec quatre clientes qui arrivent aux prestiges 5 à 8 et dont l'amitié ouvre les dernières variantes, « tout ouvert » passe de la 63e à la 123e robe en médiane (de la 99e à plus de 160). Les parties simulées passent de 90 à 160 robes, la borne de « tout ouvert » de 50–80 à 100–150 ; le prestige 2, le prestige 5 (19e), le prestige 8 (57e) et l'argent ne bougent pas. Pour tenir le temps de la suite (spec §6, moins d'une minute), le joueur simulé parcourt les robes par coût croissant (la première qui convient est la moins chère : même choix qu'avant, vérifié sur 90 robes) et garde les styles déjà calculés ; la suite prend environ 35 s.
- **Écrans** : carnet d'adresses : titre et « Fermer » fixes, lignes et souvenirs dans une liste qui défile (dix clientes et douze souvenirs font environ 680 px pour 426 visibles) ; « Offrir à… » : boutons de 36 px tous les 40 px (dix tiennent dans 466 px).
- **Suites de la relecture du plan 8b** : commentaire « 108 croquis » de `Commandes`, README (57e robe, sous-projet 5) corrigés ici ; les autres points mineurs restent au registre.
- **Vérifié pendant la préparation** : le plan a été joué entièrement sur un brouillon tiré de `main` ; dans Studio (mode édition), les quatre clientes ont été construites (noms, tenues) et une robe portant les huit décorations nouvelles ; en Play, la première commande (Colette) et aucune alerte ; sept variantes du brouillon (Apolline au prestige 4, Maëlle qui tutoie, amitié de Joséphine aux niveaux inversés, défilé sans Maëlle, souvenir du salon pris à un autre événement, boutons « Offrir » à l'ancien espacement, carnet d'adresses sans hauteur de défilement) échouent chacune sur la vérification qui les garde.

## Global Constraints

- **Dépôt** : `C:\dev\jeux\atelier-couture`, branche `ampleur-clientes`, créée depuis `main` (où le plan 8b est fusionné). Selon les règles du commanditaire : la branche testée et relue est fusionnée dans `main` et poussée sur GitHub.
- **Rojo** : `C:/dev/jeux/roblox-maker/rojo.exe`.
- **Contraintes des plans précédents toujours valables** : fins de ligne LF, commits en français terminés par `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`, textes d'au moins 14 px, le serveur fait foi.
- **Contenu original** : aucun nom, personnage, texte ni motif de Dressmaker.

## Review Focus

- **Une nouvelle cliente dès son arrivée (prestige 5 à 8, amitié nulle).** Attendu : ses commandes sont réalisables avec ce qui est ouvert. Test : `46_deblocages_etat` (boucle sur toutes les clientes, prestiges de `Progression`).
- **Partie sauvegardée avant ce plan (six clientes).** Attendu : relue sans perte ; les nouvelles clientes arrivent à leur prestige. Test : `43_sauvegarde_clientes` (inchangé, fiches par identifiant), et `Clientes.prochaine` (« prestige 5 : Apolline, nouvelle venue, passe avant les habituées »).
- **Joueur déjà au prestige 8 qui avait ouvert les quatre variantes au plan 8b.** Attendu : elles se referment jusqu'à l'amitié de leur cliente (rien n'est sauvegardé, tout se déduit) ; le lieu n'a jamais été publié entre 8b et 8c.
- **Dix clientes et douze souvenirs à l'écran.** Attendu : tout reste lisible et atteignable. Tests : scénario, « dix clientes à qui offrir : toutes dans la fenêtre » et « le carnet d'adresses défile jusqu'au dernier ».
- **Répliques des nouvelles clientes.** Attendu : vouvoiement, français correct, contenu original. Tests : `42_clientes` et `52_histoire` (vouvoiement).

---

### Task 1: Quatre clientes qui arrivent tard

**Files:**
- Modify: `src/shared/Clientes.luau`, `src/shared/Catalogue.luau` (quatre décorations d'amitié), `src/shared/Deblocages.luau` (`PRESTIGE_VARIANTES`)
- Modify: `tests/unitaires/42_clientes.luau`, `45_deblocages.luau`, `02_catalogue.luau`, `46_deblocages_etat.luau`, `48_equilibrage.luau`

**Interfaces:**
- Consumes: les variantes du plan 8b ; `Progression.SEUILS_PRESTIGE`.
- Produces: clientes `apolline`, `josephine`, `capucine`, `maelle` ; accessoires `violette`, `boucle_ecaille`, `dentelle_rouge`, `coquillage`.

- [ ] **Step 1: Écrire les tests**

Dans `tests/unitaires/42_clientes.luau`, remplacer :

```lua
-- Les six clientes : des données valides, des mesures proches de leur taille
---------------------------------------------------------------------------
U.verifier(#Clientes.LISTE == 6, "six clientes")
```

par :

```lua
-- Les dix clientes : des données valides, des mesures proches de leur taille
---------------------------------------------------------------------------
U.verifier(#Clientes.LISTE == 10, "dix clientes")
-- Sous-projet 4 : quatre clientes arrivent tard, aux prestiges 5 à 8, et vouvoient la couturière
local TUTOIEMENT = { " tu ", "Tu ", " toi", " ta ", " ton ", " tes ", " te ", " t'" }
for niveau, id in pairs({ [5] = "apolline", [6] = "josephine", [7] = "capucine", [8] = "maelle" }) do
	local c = Clientes.get(id)
	U.verifier(c ~= nil and c.prestige == niveau, id .. " : arrive au prestige " .. niveau)
	for cle, texte in pairs(c and c.repliques or {}) do
		for _, motif in ipairs(TUTOIEMENT) do
			U.verifier(string.find(" " .. texte, motif, 1, true) == nil, id .. " (" .. cle .. ") : elle vouvoie (« " .. motif .. " »)")
		end
	end
end
```

Dans `tests/unitaires/42_clientes.luau`, remplacer :

```lua
U.verifier(Clientes.prochaine(fiches, 8) == "helene", "plusieurs nouvelles venues possibles : dans l'ordre de la liste")
```

par :

```lua
U.verifier(Clientes.prochaine(fiches, 8) == "helene", "plusieurs nouvelles venues possibles : dans l'ordre de la liste")
local toutesVues = {}
for i, c in ipairs(Clientes.LISTE) do
	if c.prestige <= 4 then
		toutesVues[c.id] = { vues = 1, derniere = i }
	end
end
U.verifier(Clientes.prochaine(toutesVues, 4) == "colette" and Clientes.prochaine(toutesVues, 5) == "apolline" and Clientes.prochaine(toutesVues, 8) == "apolline", "prestige 5 : Apolline, nouvelle venue, passe avant les habituées")
```

Dans `tests/unitaires/45_deblocages.luau`, remplacer :

```lua
-- Tout ouvert : prestige 5 et amitié 4 avec les six clientes
```

par :

```lua
-- Tout ouvert : prestige 8 et amitié 4 avec les dix clientes
```

Dans `tests/unitaires/45_deblocages.luau`, remplacer :

```lua
U.verifier(Deblocages.toutOuvert(tout), "prestige 8 et six amitiés au niveau 4 : tout est ouvert")
```

par :

```lua
U.verifier(Deblocages.toutOuvert(tout), "prestige 8 et dix amitiés au niveau 4 : tout est ouvert")
```

Dans `tests/unitaires/45_deblocages.luau`, remplacer :

```lua
-- Sous-projet 4 : les manches courtes au prestige 6, la jupe crayon au 7 ; les quatre variantes des nouvelles
-- clientes attendent le prestige 8 (le plan 8c les donnera à leur amitié)
for id, niveau in pairs({ manches_courtes = 6, jupe_crayon = 7, corsage_cache_coeur = 8, corsage_bustier = 8, manches_trois_quarts = 8, col_marin = 8 }) do
	U.verifier(Catalogue.variante(id) ~= nil and not Deblocages.ouvert(au(SEUILS_P[niveau] - 1), "variantes", id) and Deblocages.ouvert(au(SEUILS_P[niveau]), "variantes", id), id .. " : ouverte au prestige " .. niveau)
end
```

par :

```lua
-- Sous-projet 4 : les manches courtes au prestige 6, la jupe crayon au 7 ; les quatre autres variantes et quatre
-- décorations s'ouvrent à l'amitié des nouvelles clientes (niveaux 2 et 4), jamais par le prestige seul
for id, niveau in pairs({ manches_courtes = 6, jupe_crayon = 7 }) do
	U.verifier(Catalogue.variante(id) ~= nil and not Deblocages.ouvert(au(SEUILS_P[niveau] - 1), "variantes", id) and Deblocages.ouvert(au(SEUILS_P[niveau]), "variantes", id), id .. " : ouverte au prestige " .. niveau)
end
local AMITIE_NOUVELLES = {
	apolline = { "corsage_cache_coeur", "violette" },
	josephine = { "manches_trois_quarts", "boucle_ecaille" },
	capucine = { "corsage_bustier", "dentelle_rouge" },
	maelle = { "col_marin", "coquillage" },
}
for id, paire in pairs(AMITIE_NOUVELLES) do
	local variante, accessoire = paire[1], paire[2]
	local function amie(points)
		return { prestige = 530, clientes = { [id] = { amitie = points } } }
	end
	U.verifier(not Deblocages.ouvert(amie(6), "variantes", variante) and Deblocages.ouvert(amie(7), "variantes", variante), variante .. " : ouverte par l'amitié de " .. id .. " (niveau 2), pas par le prestige")
	U.verifier(Catalogue.accessoire(accessoire) ~= nil and not Deblocages.ouvert(amie(17), "accessoires", accessoire) and Deblocages.ouvert(amie(18), "accessoires", accessoire), accessoire .. " : ouvert par l'amitié de " .. id .. " (niveau 4)")
end
```

Dans `tests/unitaires/02_catalogue.luau`, remplacer :

```lua
U.verifier(#Catalogue.Accessoires == 31, "31 accessoires (dont les huit souvenirs du quartier et huit décorations de fin de partie)")
```

par :

```lua
U.verifier(#Catalogue.Accessoires == 35, "35 accessoires (dont les huit souvenirs du quartier et douze décorations nouvelles)")
```

Dans `tests/unitaires/46_deblocages_etat.luau`, remplacer :

```lua
	local progres = { prestige = ({ 0, 20, 50, 100 })[c.prestige], clientes = {} }
```

par :

```lua
	local progres = { prestige = Progression.SEUILS_PRESTIGE[c.prestige], clientes = {} }
```

Dans `tests/unitaires/46_deblocages_etat.luau`, remplacer :

```lua
local SEUILS = { 0, 20, 50, 100 }
```

par :

```lua
local SEUILS = Progression.SEUILS_PRESTIGE
```

- [ ] **Step 2: La simulation d'équilibrage, plus longue et plus rapide**

Dans `tests/unitaires/48_equilibrage.luau`, remplacer :

```lua
local ROBES = 90
```

par :

```lua
local ROBES = 160 -- (sous-projet 4 : les quatre dernières clientes arrivent aux prestiges 5 à 8)
```

Dans `tests/unitaires/48_equilibrage.luau`, remplacer :

```lua
-- La robe la moins chère qui remplit la commande avec ce qui est ouvert, ou nil
local function choisir(etat)
	local ouverts = Deblocages.ouverts(etat)
	local impose
	for _, x in ipairs(etat.commande.exigences) do
		if x.type == "accessoire" then
			impose = x.id
		end
	end
	if impose and not ouverts.accessoires[impose] then
		return nil
	end
	local accessoires = impose and { { id = impose } } or {}
	local meilleur
	for _, c in ipairs(CROQUIS) do
		local v = c.croquis
		if ouverts.variantes[v.corsage] and ouverts.variantes[v.manches] and ouverts.variantes[v.col] and ouverts.variantes[v.jupe] then
			for _, t in ipairs(Catalogue.Tissus) do
				local cout = EtatAtelier.prix(t.id, c.dm) + (impose and Catalogue.accessoire(impose).prix or 0)
				if ouverts.tissus[t.id] and (not meilleur or cout < meilleur.cout) then
					local bilan = {
						styles = Notation.styles({ croquis = v, tissus = { [t.id] = 1 }, accessoires = accessoires }),
						qualite = QUALITE,
						teinte = t.teinte,
						accessoires = impose and { [impose] = 1 } or {},
					}
					if Notation.verifierExigences(etat.commande.exigences, bilan) then
						meilleur = { croquis = v, pieces = c.pieces, dm = c.dm, tissu = t.id, cout = cout, impose = impose }
					end
				end
			end
		end
	end
	return meilleur
end
```

par :

```lua
-- Toutes les robes simples (croquis × tissu), de la moins chère à la plus chère ; à coût égal, dans l'ordre du
-- catalogue (croquis, puis tissu) : la première qui remplit la commande est la moins chère
local CANDIDATES = {}
for i, c in ipairs(CROQUIS) do
	for j, t in ipairs(Catalogue.Tissus) do
		table.insert(CANDIDATES, { croquis = c, tissu = t, cout = EtatAtelier.prix(t.id, c.dm), rang = i * 1000 + j })
	end
end
table.sort(CANDIDATES, function(a, b)
	return a.cout < b.cout or (a.cout == b.cout and a.rang < b.rang)
end)

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

-- La robe la moins chère qui remplit la commande avec ce qui est ouvert, ou nil
local function choisir(etat)
	local ouverts = Deblocages.ouverts(etat)
	local impose
	for _, x in ipairs(etat.commande.exigences) do
		if x.type == "accessoire" then
			impose = x.id
		end
	end
	if impose and not ouverts.accessoires[impose] then
		return nil
	end
	for _, candidate in ipairs(CANDIDATES) do
		local c, t = candidate.croquis, candidate.tissu
		local v = c.croquis
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

Dans `tests/unitaires/48_equilibrage.luau`, remplacer :

```lua
U.verifier(medianeTout >= 50 and medianeTout <= 80, "tout le catalogue ouvert entre la 50e et la 80e robe, en médiane (" .. bilan .. ")")
```

par :

```lua
U.verifier(medianeTout >= 100 and medianeTout <= 150, "tout le catalogue ouvert entre la 100e et la 150e robe, en médiane : l'amitié des quatre dernières clientes, arrivées aux prestiges 5 à 8, ouvre les dernières variantes (" .. bilan .. ")")
```

- [ ] **Step 3: Lancer les tests, vérifier l'échec**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT|attempt|membre" | head -3`
Expected: échec : une ligne qui finit par `ÉCHEC : 35 accessoires (dont les huit souvenirs du quartier et douze décorations nouvelles)`

- [ ] **Step 4: Écrire le code**

Dans `src/shared/Clientes.luau`, remplacer :

```lua
-- Clientes : les six clientes qui reviennent à l'atelier (contenu original, rien de Dressmaker). Chacune a ses
```

par :

```lua
-- Clientes : les dix clientes qui reviennent à l'atelier (contenu original, rien de Dressmaker). Chacune a ses
```

Dans `src/shared/Clientes.luau`, remplacer :

```lua
			presentation = "Bonjour ! Victoire Aubry. On m'a dit le plus grand bien de vous.",
			arrivee = "Bonjour ! Je reviens vous confier une robe.",
			merci = "Exactement ce qu'il me fallait. Bravo.",
			deception = "Je m'attendais à mieux, franchement.",
		},
	},
}
```

par :

```lua
			presentation = "Bonjour ! Victoire Aubry. On m'a dit le plus grand bien de vous.",
			arrivee = "Bonjour ! Je reviens vous confier une robe.",
			merci = "Exactement ce qu'il me fallait. Bravo.",
			deception = "Je m'attendais à mieux, franchement.",
		},
	},
	-- Sous-projet 4 : quatre clientes qui arrivent tard (prestiges 5 à 8)
	{
		id = "apolline",
		nom = "Apolline Garnier",
		taille = "M",
		mesures = { poitrine = 8.7, taille = 7.0, hanches = 9.3 },
		styles = { "romantique", "chic" },
		teinte = "violet",
		prestige = 5,
		tenue = { peau = rgb(236, 196, 164), haut = rgb(150, 110, 190), bas = rgb(240, 235, 245), cheveux = rgb(60, 40, 30) },
		deblocages = { [2] = { variante = "corsage_cache_coeur" }, [4] = { accessoire = "violette" } },
		repliques = {
			presentation = "Bonjour. Je m'appelle Apolline, j'écris des poèmes… et j'aimerais qu'une robe m'en inspire un.",
			arrivee = "Me revoici. Votre atelier me donne toujours des idées de vers.",
			merci = "Elle est si belle que je vais lui écrire un sonnet.",
			deception = "Hum… Je ne trouve pas les mots. Et c'est rare, chez moi.",
		},
	},
	{
		id = "josephine",
		nom = "Joséphine Lambert",
		taille = "L",
		mesures = { poitrine = 9.7, taille = 7.9, hanches = 10.1 },
		styles = { "chic", "decontracte" },
		teinte = "brun",
		prestige = 6,
		tenue = { peau = rgb(200, 150, 120), haut = rgb(150, 100, 60), bas = rgb(60, 55, 50), cheveux = rgb(40, 30, 25) },
		deblocages = { [2] = { variante = "manches_trois_quarts" }, [4] = { accessoire = "boucle_ecaille" } },
		repliques = {
			presentation = "Bonjour ! Joséphine, de la librairie d'en face. Je vous regarde coudre depuis ma vitrine.",
			arrivee = "C'est encore moi ! J'ai fermé la boutique une heure pour venir vous voir.",
			merci = "Parfaite. Je la porterai pour les dédicaces.",
			deception = "Ce n'est pas vraiment moi, je crois.",
		},
	},
	{
		id = "capucine",
		nom = "Capucine Morel",
		taille = "S",
		mesures = { poitrine = 8.3, taille = 6.5, hanches = 8.7 },
		styles = { "gothique", "romantique" },
		teinte = "rouge",
		prestige = 7,
		tenue = { peau = rgb(245, 220, 205), haut = rgb(150, 20, 40), bas = rgb(30, 25, 30), cheveux = rgb(20, 15, 15) },
		deblocages = { [2] = { variante = "corsage_bustier" }, [4] = { accessoire = "dentelle_rouge" } },
		repliques = {
			presentation = "Capucine, comédienne. On m'a dit que vous habilliez les grands soirs.",
			arrivee = "Le rideau se lève bientôt : j'ai besoin de vous.",
			merci = "Bravo ! Je vous dois mon entrée en scène.",
			deception = "Le public ne va pas aimer. Moi non plus.",
		},
	},
	{
		id = "maelle",
		nom = "Maëlle Bertin",
		taille = "M",
		mesures = { poitrine = 8.8, taille = 6.9, hanches = 9.5 },
		styles = { "decontracte", "mignon" },
		teinte = "bleu",
		prestige = 8,
		tenue = { peau = rgb(230, 190, 160), haut = rgb(40, 70, 140), bas = rgb(245, 245, 250), cheveux = rgb(200, 150, 80) },
		deblocages = { [2] = { variante = "col_marin" }, [4] = { accessoire = "coquillage" } },
		repliques = {
			presentation = "Bonjour ! Maëlle. Je rentre d'un tour du monde à la voile, et je n'ai plus rien à me mettre !",
			arrivee = "Escale à l'atelier ! Vous avez un moment pour moi ?",
			merci = "Elle est superbe. Je l'emporterai à chaque escale.",
			deception = "Bof… Elle ne tiendrait pas une journée en mer.",
		},
	},
}
```

Dans `src/shared/Catalogue.luau`, remplacer :

```lua
	garniture("dentelle_doree", "Dentelle dorée", 4, { elegant = 4, romantique = 1 }, { largeur = 0.3, couleur = { 220, 190, 110 }, transparence = 0.15 }),
```

par :

```lua
	garniture("dentelle_doree", "Dentelle dorée", 4, { elegant = 4, romantique = 1 }, { largeur = 0.3, couleur = { 220, 190, 110 }, transparence = 0.15 }),
	-- Sous-projet 4 : ce qu'ouvre l'amitié des quatre nouvelles clientes (niveau 4)
	objet("violette", "Violette", 3, { romantique = 3, chic = 1 },
		{ forme = "fleur", taille = 0.45, couleur = { 140, 90, 190 }, reflet = 0 }),
	objet("boucle_ecaille", "Boucle d'écaille", 4, { chic = 3, decontracte = 2 },
		{ forme = "cylindre", taille = 0.45, couleur = { 130, 80, 40 }, reflet = 0.3 }),
	garniture("dentelle_rouge", "Dentelle rouge", 3, { gothique = 3, romantique = 2 }, { largeur = 0.3, couleur = { 160, 20, 40 }, transparence = 0.15 }),
	objet("coquillage", "Coquillage", 3, { decontracte = 3, mignon = 2 },
		{ forme = "boule", taille = 0.35, couleur = { 250, 225, 210 }, reflet = 0.2 }),
```

Dans `src/shared/Deblocages.luau`, remplacer :

```lua
-- Prestige qui ouvre des variantes (sous-projet 4) ; cache-cœur, bustier, trois-quarts et col marin attendent le
-- prestige 8 jusqu'à l'arrivée des nouvelles clientes (plan 8c), dont l'amitié les ouvrira
Deblocages.PRESTIGE_VARIANTES = {
	manches_courtes = 6,
	jupe_crayon = 7,
	corsage_cache_coeur = 8,
	corsage_bustier = 8,
	manches_trois_quarts = 8,
	col_marin = 8,
}
```

par :

```lua
-- Prestige qui ouvre des variantes (sous-projet 4) ; cache-cœur, bustier, trois-quarts et col marin s'ouvrent à
-- l'amitié des nouvelles clientes (Clientes)
Deblocages.PRESTIGE_VARIANTES = {
	manches_courtes = 6,
	jupe_crayon = 7,
}
```

- [ ] **Step 5: Lancer les tests**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Équilibrage|Unitaires|ÉCHEC|TOUT"`
Expected:
```
Équilibrage : 20 parties de 160 robes, une robe libre de jute vendue sur quatre, 73 commandes par lettre (médiane) : prestige 2 à la robe 3 au plus tard ; 5 de la 17 à la 23 (médiane 19) ; 8 à la 57 (médiane) ; tout ouvert de la 99 à la jamais (médiane 123) ; au plus bas 241 po
Unitaires : 159186 vérifications
TOUT EST VERT : 729 vérifications
```

- [ ] **Step 6: Commit**

```bash
git add src/shared/Clientes.luau src/shared/Catalogue.luau src/shared/Deblocages.luau tests/unitaires/42_clientes.luau tests/unitaires/45_deblocages.luau tests/unitaires/02_catalogue.luau tests/unitaires/46_deblocages_etat.luau tests/unitaires/48_equilibrage.luau
git commit -m "Quatre clientes aux prestiges 5 à 8 ; leur amitié ouvre les dernières variantes ; équilibrage sur 160 robes

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 2: Quatre événements de fin de partie

**Files:**
- Modify: `src/shared/Histoire.luau`, `src/shared/Catalogue.luau` (souvenirs)
- Modify: `tests/unitaires/52_histoire.luau`, `02_catalogue.luau`

**Interfaces:**
- Consumes: les clientes de la tâche 1.
- Produces: événements `salon_livre`, `premiere`, `noces_colette`, `defile` ; souvenirs `marque_page`, `masque_theatre`, `alliance_or`, `rosette_honneur`.

- [ ] **Step 1: Écrire les tests**

Dans `tests/unitaires/52_histoire.luau`, remplacer :

```lua
-- Le tableau : huit événements, deux à quatre robes chacun, des clientes connues, des répliques, un souvenir
U.verifier(#Histoire.EVENEMENTS == 8, "huit événements")
```

par :

```lua
-- Le tableau : douze événements, deux à quatre robes chacun, des clientes connues, des répliques, un souvenir
U.verifier(#Histoire.EVENEMENTS == 12, "douze événements")
-- Sous-projet 4 : quatre événements de plus, aux prestiges 6 à 8, où jouent les quatre nouvelles clientes
local joueuses = {}
for rang = 9, #Histoire.EVENEMENTS do
	local ev = Histoire.EVENEMENTS[rang]
	U.verifier(ev.prestige >= 6, ev.id .. " : un événement de fin de partie (prestige 6 à 8)")
	for _, c in ipairs(ev.commandes) do
		joueuses[c.cliente] = true
	end
end
U.verifier(joueuses.apolline and joueuses.josephine and joueuses.capucine and joueuses.maelle, "les quatre nouvelles clientes jouent dans les événements 9 à 12")
```

Dans `tests/unitaires/52_histoire.luau`, remplacer :

```lua
		if c.cliente == "colette" or c.cliente == "helene" or c.cliente == "victoire" then
```

par :

```lua
		if c.cliente == "colette" or c.cliente == "helene" or c.cliente == "victoire" or c.cliente == "apolline" or c.cliente == "josephine" or c.cliente == "capucine" or c.cliente == "maelle" then
```

Dans `tests/unitaires/52_histoire.luau`, remplacer :

```lua
U.verifier(Histoire.enCours(tout) == nil and Histoire.prochaine(tout) == nil and Histoire.eus(tout) == 8, "tout a eu lieu : plus d'événement")
```

par :

```lua
U.verifier(Histoire.enCours(tout) == nil and Histoire.prochaine(tout) == nil and Histoire.eus(tout) == 12, "tout a eu lieu : plus d'événement")
```

Dans `tests/unitaires/02_catalogue.luau`, remplacer :

```lua
U.verifier(#Catalogue.Accessoires == 35, "35 accessoires (dont les huit souvenirs du quartier et douze décorations nouvelles)")
```

par :

```lua
U.verifier(#Catalogue.Accessoires == 39, "39 accessoires (dont les douze souvenirs du quartier et douze décorations nouvelles)")
```

- [ ] **Step 2: Lancer les tests, vérifier l'échec**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT|attempt|membre" | head -3`
Expected: échec : une ligne qui finit par `ÉCHEC : 39 accessoires (dont les douze souvenirs du quartier et douze décorations nouvelles)`

- [ ] **Step 3: Écrire le code**

Dans `src/shared/Histoire.luau`, remplacer :

```lua
-- Histoire (sous-projet 3) : les huit événements du quartier, l'un après l'autre. Chacun demande quelques robes à
```

par :

```lua
-- Histoire (sous-projets 3 et 4) : les douze événements du quartier, l'un après l'autre. Chacun demande quelques robes à
```

Dans `src/shared/Histoire.luau`, remplacer :

```lua
			commande("bal_victoire", "victoire", { min("elegant", 45), teinte("blanc") },
				"J'organise le grand bal d'hiver. Je voudrais être à la hauteur du quartier que vous avez habillé.",
				"Blanche, élégante, digne d'une première neige.",
				"C'était le plus beau bal que le quartier ait connu. Et c'est grâce à vous."),
		},
	},
}
```

par :

```lua
			commande("bal_victoire", "victoire", { min("elegant", 45), teinte("blanc") },
				"J'organise le grand bal d'hiver. Je voudrais être à la hauteur du quartier que vous avez habillé.",
				"Blanche, élégante, digne d'une première neige.",
				"C'était le plus beau bal que le quartier ait connu. Et c'est grâce à vous."),
		},
	},
	-- Sous-projet 4 : quatre événements de fin de partie, avec les quatre dernières clientes
	{
		id = "salon_livre",
		nom = "Le salon du livre",
		prestige = 6,
		souvenir = "marque_page",
		epilogue = "Au salon du livre, Joséphine a vendu tous ses exemplaires, Apolline a lu ses poèmes devant une salle comble, et l'herbier de Salomé est déjà épuisé.",
		commandes = {
			commande("salon_josephine", "josephine", { min("chic", 30), teinte("brun") },
				"J'organise le salon du livre sur la place ! Des auteurs, des lecteurs, et moi au milieu de tout ça.",
				"Chic mais pratique, couleur de vieux cuir.",
				"On m'a prise pour une romancière. J'ai signé trois autographes, par erreur !"),
			commande("salon_apolline", "apolline", { min("romantique", 35), teinte("violet") },
				"Joséphine veut que je lise mes poèmes au salon. À voix haute. Devant des gens.",
				"Romantique, violette comme l'encre de mon stylo.",
				"Ma voix n'a pas tremblé. Enfin, un peu, au début."),
			commande("salon_salome", "salome", { min("chic", 30), teinte("vert") },
				"Je présente mon herbier au salon du livre. Oui, j'en ai fait un livre !",
				"Vert et chic, comme une belle reliure.",
				"Il est déjà épuisé. On me demande une suite !"),
		},
	},
	{
		id = "premiere",
		nom = "La première du théâtre",
		prestige = 7,
		souvenir = "masque_theatre",
		epilogue = "Rideau ! Capucine a salué sous une pluie de roses, Inès a joué la musique de scène, et Victoire jure qu'elle n'a jamais autant applaudi.",
		commandes = {
			commande("premiere_capucine", "capucine", { min("romantique", 35), teinte("rouge") },
				"La première de ma pièce, c'est dans quinze jours. Je joue une reine déchue. Il me faut son costume.",
				"Romantique et tragique, rouge sang, qu'on la voie du dernier rang.",
				"Onze rappels ! La reine déchue a conquis le quartier."),
			commande("premiere_ines", "ines", { min("gothique", 40), max("mignon", 20) },
				"… Capucine m'a demandé la musique de sa pièce. Je jouerai de l'orgue, dans la fosse.",
				"Sombre. Rien de mignon. Personne ne doit me remarquer… sauf à la fin.",
				"À la fin, on m'a fait monter sur scène. Je n'ai pas su quoi faire de mes mains."),
			commande("premiere_victoire", "victoire", { min("elegant", 45) },
				"Je suis la marraine de la première. Il faut que je sois à la hauteur de la loge d'honneur.",
				"Élégante, digne d'un soir de première.",
				"Toute la salle se retournait vers ma loge. Merveilleux."),
		},
	},
	{
		id = "noces_colette",
		nom = "Le mariage de Colette",
		prestige = 7,
		souvenir = "alliance_or",
		epilogue = "Colette a dit oui au bord du lac, là où tout avait commencé. Margot a pleuré plus fort que tout le monde, et Apolline a lu le poème qu'elle leur avait écrit.",
		commandes = {
			commande("noces_colette", "colette", { min("romantique", 40), teinte("blanc") },
				"Ça y est, c'est bientôt le grand jour ! Et vous m'aviez promis ma robe, vous vous souvenez ?",
				"Blanche, la plus romantique du monde. Comme au bal d'hiver, en mieux.",
				"Il a pleuré en me voyant arriver. Moi aussi. Merci pour tout, depuis le début."),
			commande("noces_margot", "margot", { min("mignon", 35), teinte("rose") },
				"À mon tour d'être la témoin ! Colette l'a été pour moi, je lui dois bien ça.",
				"Rose, toute mignonne, assortie aux fleurs de la mariée.",
				"J'ai attrapé le bouquet… et je l'ai lancé à Apolline. Elle était toute rouge !"),
			commande("noces_apolline", "apolline", { min("romantique", 35), teinte("violet") },
				"Colette m'a demandé un poème pour son mariage. Et une robe pour le lire, évidemment.",
				"Romantique, en violet, pour aller avec les mots.",
				"Tout le monde a pleuré au dernier vers. C'était le but."),
		},
	},
	{
		id = "defile",
		nom = "Le grand défilé du quartier",
		prestige = 8,
		souvenir = "rosette_honneur",
		epilogue = "Sur la place, toutes les robes de l'atelier ont défilé, de la première à la dernière. Maëlle a ouvert le défilé, Victoire a remis la rosette : ton atelier est la fierté du quartier.",
		commandes = {
			commande("defile_maelle", "maelle", { min("decontracte", 40), teinte("bleu") },
				"Victoire organise un défilé sur la place, et elle veut que je l'ouvre ! Moi, qui vis en ciré jaune…",
				"Décontractée, bleu océan. Je dois pouvoir marcher sans tomber.",
				"J'ai ouvert le défilé sans tomber une seule fois. Une vraie traversée !"),
			commande("defile_capucine", "capucine", { min("gothique", 40) },
				"Un défilé, c'est un théâtre sans texte. J'en suis, bien sûr.",
				"La plus gothique de vos créations. Qu'on retienne son souffle.",
				"Le silence, puis les applaudissements. Exactement comme je les aime."),
			commande("defile_josephine", "josephine", { min("chic", 40) },
				"Victoire dit que les libraires ont du style, alors je défile aussi. Elle a raison, non ?",
				"Chic, très chic. Pour faire honneur à tous les livres.",
				"On m'a photographiée pour le journal du quartier. En première page !"),
			commande("defile_victoire", "victoire", { min("elegant", 40), teinte("bleu") },
				"Le grand défilé est mon idée. Toutes vos robes, sur la place, devant tout le quartier.",
				"Élégante, en bleu, pour clore le défilé. La dernière robe doit être la plus belle.",
				"Quel triomphe. Tout le quartier connaît votre nom, désormais."),
		},
	},
}
```

Dans `src/shared/Catalogue.luau`, remplacer :

```lua
	objet("flocon_argent", "Flocon d'argent", 6, { elegant = 4, romantique = 1 },
		{ forme = "croix", taille = 0.5, couleur = { 220, 225, 235 }, reflet = 0.5 }),
```

par :

```lua
	objet("flocon_argent", "Flocon d'argent", 6, { elegant = 4, romantique = 1 },
		{ forme = "croix", taille = 0.5, couleur = { 220, 225, 235 }, reflet = 0.5 }),
	objet("marque_page", "Marque-page doré", 4, { chic = 3, elegant = 1 },
		{ forme = "bloc", taille = 0.5, couleur = { 214, 170, 60 }, reflet = 0.3 }),
	objet("masque_theatre", "Masque de théâtre", 5, { gothique = 2, chic = 2, elegant = 1 },
		{ forme = "bloc", taille = 0.55, couleur = { 245, 240, 230 }, reflet = 0.2 }),
	objet("alliance_or", "Alliance d'or", 6, { romantique = 3, elegant = 2 },
		{ forme = "cylindre", taille = 0.35, couleur = { 230, 190, 80 }, reflet = 0.5 }),
	objet("rosette_honneur", "Rosette d'honneur", 7, { elegant = 3, chic = 3 },
		{ forme = "fleur", taille = 0.6, couleur = { 40, 70, 150 }, reflet = 0.2 }),
```

- [ ] **Step 4: Lancer les tests**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT"`
Expected:
```
Unitaires : 159562 vérifications
TOUT EST VERT : 729 vérifications
```

- [ ] **Step 5: Commit**

```bash
git add src/shared/Histoire.luau src/shared/Catalogue.luau tests/unitaires/52_histoire.luau tests/unitaires/02_catalogue.luau
git commit -m "Quatre événements de fin de partie : salon du livre, première du théâtre, mariage de Colette, grand défilé

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 3: Dix clientes à l'écran

**Files:**
- Modify: `src/client/Atelier/EcranAccueil.luau` (carnet d'adresses), `src/client/Atelier/EcranPresentation.luau` (« Offrir à… »)
- Modify: `tests/scenario.luau`

**Interfaces:**
- Consumes: les clientes et les événements des tâches 1 et 2.
- Produces: `CarnetAdresses.Liste` (ScrollingFrame : `Adresse_<id>`, `Souvenirs`) ; boutons `Offrir_<id>` tous les 40 px.

- [ ] **Step 1: Écrire les tests**

Dans `tests/scenario.luau`, remplacer :

```lua
verifier(#manquantes == 0, "robe en variantes nouvelles montrée en 3D à la photo (manquent : " .. table.concat(manquantes, ", ") .. ")")
cliquer("Offrir")
cliquer("Offrir_colette")
```

par :

```lua
verifier(#manquantes == 0, "robe en variantes nouvelles montrée en 3D à la photo (manquent : " .. table.concat(manquantes, ", ") .. ")")
-- Sous-projet 4 : dix clientes déjà venues et douze événements passés (l'état d'avant revient ensuite) ; toutes
-- dans le choix « Offrir à… », puis toutes dans le carnet d'adresses de l'accueil
local avant8c = { clientes = table.clone(serveur:atelier(joueur).etat.clientes), faites = table.clone(serveur:atelier(joueur).etat.histoire.faites) }
do
	local e = serveur:atelier(joueur).etat
	for _, c in ipairs(Clientes.LISTE) do
		local fiche = if e.clientes[c.id] then table.clone(e.clientes[c.id]) else { amitie = 0, vues = 0, derniere = 0 }
		fiche.vues = math.max(1, fiche.vues)
		e.clientes[c.id] = fiche
	end
	for _, ev in ipairs(requireModule(dossier.Histoire).EVENEMENTS) do
		for _, c in ipairs(ev.commandes) do
			e.histoire.faites[c.id] = true
		end
	end
	e.etape = "decorations" -- (l'écran de la photo se refait en y revenant)
	requireModule(scriptClient.Session).courante:actualiser()
	cliquer("Presenter")
	cliquer("Offrir")
	local derniere = boutonNomme("Offrir_maelle")
	verifier(derniere.Position.Y.Offset + derniere.Size.Y.Offset <= fenetre.Size.Y.Offset + fenetre.Contenu.Size.Y.Offset, "dix clientes à qui offrir : toutes dans la fenêtre")
	cliquer("FermerChoixCliente")
end
cliquer("Offrir")
cliquer("Offrir_colette")
```

Dans `tests/scenario.luau`, remplacer :

```lua
verifier(serveur:atelier(joueur).etat.clientes.colette.amitie > amitieColette, "son amitié monte")
end
```

par :

```lua
verifier(serveur:atelier(joueur).etat.clientes.colette.amitie > amitieColette, "son amitié monte")
do
	cliquer("OuvrirCarnetAdresses")
	local liste = fenetre.Contenu.CarnetAdresses:FindFirstChild("Liste")
	local bas = 0
	for _, d in ipairs(liste and liste:GetChildren() or {}) do
		if d:IsA("GuiObject") then
			bas = math.max(bas, d.Position.Y.Offset + d.Size.Y.Offset)
		end
	end
	verifier(liste ~= nil and liste:IsA("ScrollingFrame") and bas > 0 and (if liste.CanvasSize then liste.CanvasSize.Y.Offset else 0) >= bas and liste:FindFirstChild("Adresse_maelle") ~= nil and texte("Le grand défilé du quartier — souvenir : Rosette d'honneur") ~= nil, "dix clientes et douze souvenirs : le carnet d'adresses défile jusqu'au dernier")
	cliquer("FermerCarnetAdresses")
	local e = serveur:atelier(joueur).etat
	for _, c in ipairs(Clientes.LISTE) do
		if c.id ~= "colette" then
			e.clientes[c.id] = avant8c.clientes[c.id]
		end
	end
	e.histoire.faites = avant8c.faites
	requireModule(scriptClient.Session).courante:actualiser()
end
end
```

- [ ] **Step 2: Lancer les tests, vérifier l'échec**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT|attempt|membre" | head -3`
Expected: échec : une ligne qui finit par `ÉCHEC : dix clientes à qui offrir : toutes dans la fenêtre`

- [ ] **Step 3: Écrire le code**

Dans `src/client/Atelier/EcranAccueil.luau`, remplacer :

```lua
		UiKit.boutonDoux({ Name = "FermerCarnetAdresses", Text = "Fermer", TextSize = 14, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -6, 0, 0), Size = UDim2.fromOffset(110, 34), ZIndex = 21, Parent = carnet }, function()
			carnet.Visible = false
		end)
		for k, v in ipairs(venues) do
```

par :

```lua
		UiKit.boutonDoux({ Name = "FermerCarnetAdresses", Text = "Fermer", TextSize = 14, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -6, 0, 0), Size = UDim2.fromOffset(110, 34), ZIndex = 21, Parent = carnet }, function()
			carnet.Visible = false
		end)
		-- Sous le titre, une liste qui défile (dix clientes et douze souvenirs ne tiennent pas dans la fenêtre)
		local liste = UiKit.creer("ScrollingFrame", { Name = "Liste", BackgroundTransparency = 1, BorderSizePixel = 0, Position = UDim2.fromOffset(0, 40), Size = UDim2.new(1, 0, 1, -40), ScrollBarThickness = 10, ScrollingDirection = Enum.ScrollingDirection.Y, ZIndex = 21, Parent = carnet })
		for k, v in ipairs(venues) do
```

Dans `src/client/Atelier/EcranAccueil.luau`, remplacer :

```lua
				Position = UDim2.fromOffset(0, 44 + (k - 1) * 34),
				Size = UDim2.new(1, 0, 0, 30),
				ZIndex = 21,
				Parent = carnet,
			})
		end
```

par :

```lua
				Position = UDim2.fromOffset(0, 4 + (k - 1) * 34),
				Size = UDim2.new(1, -14, 0, 30),
				ZIndex = 21,
				Parent = liste,
			})
		end
		local bas = 4 + #venues * 34
```

Dans `src/client/Atelier/EcranAccueil.luau`, remplacer :

```lua
		if #passes > 0 then
			UiKit.texte({ Name = "Souvenirs", Text = "Souvenirs du quartier :\n" .. table.concat(passes, "\n"), TextSize = 16, Position = UDim2.fromOffset(0, 54 + #venues * 34), Size = UDim2.new(1, 0, 0, 22 * (#passes + 1)), ZIndex = 21, Parent = carnet })
		end
```

par :

```lua
		if #passes > 0 then
			UiKit.texte({ Name = "Souvenirs", Text = "Souvenirs du quartier :\n" .. table.concat(passes, "\n"), TextSize = 16, Position = UDim2.fromOffset(0, bas + 10), Size = UDim2.new(1, -14, 0, 22 * (#passes + 1)), ZIndex = 21, Parent = liste })
			bas += 10 + 22 * (#passes + 1)
		end
		liste.CanvasSize = UDim2.fromOffset(0, bas)
```

Dans `src/client/Atelier/EcranPresentation.luau`, remplacer :

```lua
					Position = UDim2.fromOffset(0, 42 + n * 44),
					Size = UDim2.new(1, -6, 0, 38),
```

par :

```lua
					Position = UDim2.fromOffset(0, 42 + n * 40), -- (dix clientes tiennent dans la fenêtre)
					Size = UDim2.new(1, -6, 0, 36),
```

- [ ] **Step 4: Lancer les tests**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT"`
Expected:
```
Unitaires : 159562 vérifications
TOUT EST VERT : 737 vérifications
```

- [ ] **Step 5: Commit**

```bash
git add src/client/Atelier/EcranAccueil.luau src/client/Atelier/EcranPresentation.luau tests/scenario.luau
git commit -m "Dix clientes à l'écran : carnet d'adresses qui défile, « Offrir à… » resserré

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 4: Studio, README

**Files:**
- Modify: `README.md`, `src/shared/Commandes.luau` (commentaire), `AtelierCouture.rbxl` (régénéré)

**Interfaces:**
- Consumes: tout ce qui précède.
- Produces: rien de nouveau.

- [ ] **Step 1: Dans Studio, par le connecteur MCP**

Construire le lieu du dépôt dans un dossier temporaire (`C:/dev/jeux/roblox-maker/rojo.exe build -o <dossier temporaire>/Plan8cDepot.rbxl`) et l'ouvrir dans Studio.

En mode édition, par `execute_luau` : dans un dossier de `workspace`, construire les quatre nouvelles clientes (`Cliente.construire({ cliente = id, taille = "M" }, cadre, dossier)`, le module est sous `StarterPlayer.StarterPlayerScripts.Atelier`) et une robe (corsage droit, sans manches, sans col, jupe ample, coton blanc) portant les sept objets nouveaux sur le devant du corsage et la dentelle rouge au bas de la jupe ; les regarder par `screen_capture`, puis détruire le dossier.

En Play : attendre 4 s, appuyer sur E ; relever le titre et la cliente entrée, puis la console.

Expected : quatre avatars nommés « Apolline Garnier », « Joséphine Lambert », « Capucine Morel », « Maëlle Bertin », aux couleurs de leur tenue ; la robe et ses huit décorations construites sans erreur ; en Play, « Les mesures » et Colette Marchand ; aucune alerte de notre code (« Lieu non publié » et les messages internes de Roblox mis à part). Arrêter Play et fermer cette fenêtre de Studio (sans enregistrer).

- [ ] **Step 2: Mettre à jour le README et le commentaire des croquis**

Dans `README.md`, remplacer :

```markdown
`docs/superpowers/specs/2026-09-30-histoire-evenements-design.md` pour l'histoire ; plans : `docs/superpowers/plans/`).
```

par :

```markdown
`docs/superpowers/specs/2026-09-30-histoire-evenements-design.md` pour l'histoire,
`docs/superpowers/specs/2026-09-30-ampleur-contenu-design.md` pour l'ampleur du catalogue et du quartier ; plans :
`docs/superpowers/plans/`).
```

Dans `README.md`, remplacer :

```markdown
   au-dessus de la tête), avec 1 à 3 exigences tirées de ses styles préférés et de sa teinte. Six clientes, qui
   reviennent : Colette, Margot et Salomé aux trois premières commandes ; Hélène, Inès et Victoire quand le
   prestige de l'atelier atteint 2, 3 puis 4 ; ensuite, celle qu'on n'a pas vue depuis le plus longtemps. Chacune
```

par :

```markdown
   au-dessus de la tête), avec 1 à 3 exigences tirées de ses styles préférés et de sa teinte. Dix clientes, qui
   reviennent : Colette, Margot et Salomé aux trois premières commandes ; Hélène, Inès et Victoire quand le
   prestige de l'atelier atteint 2, 3 puis 4 ; Apolline, Joséphine, Capucine et Maëlle aux prestiges 5 à 8 ;
   ensuite, celle qu'on n'a pas vue depuis le plus longtemps. Chacune
```

Dans `README.md`, remplacer :

```markdown
   ruban noir (2), la dentelle noire (3) et deux décorations par niveau du 5 au 8 ; les manches courtes (6), la
   jupe crayon (7), et en attendant les nouvelles clientes, le cache-cœur, le bustier, les manches trois-quarts et
   le col marin (8) ; l'amitié de
   chaque cliente (niveaux 2 et 4) ouvre une variante ou un accessoire de son style. Rien n'est sauvegardé :
```

par :

```markdown
   ruban noir (2), la dentelle noire (3) et deux décorations par niveau du 5 au 8 ; les manches courtes (6) et la
   jupe crayon (7) ; l'amitié de chaque cliente (niveaux 2 et 4) ouvre une variante ou un accessoire de son
   style (celle des quatre dernières : le cache-cœur, les manches trois-quarts, le bustier et le col marin, puis
   une décoration). Avec le bustier, manches et col se portent détachés, épaules nues. Rien n'est sauvegardé :
```

Dans `README.md`, remplacer :

```markdown
   **Carnet d'adresses** : les clientes déjà venues, leur niveau d'amitié (points et seuil suivant) et ce que
   le prochain niveau ouvrira.
```

par :

```markdown
   **Carnet d'adresses** : les clientes déjà venues, leur niveau d'amitié (points et seuil suivant) et ce que
   le prochain niveau ouvrira ; la liste défile.
```

Dans `README.md`, remplacer :

```markdown
   la 19e, le 8 vers la 58e, et tout est ouvert vers la 66e (médianes). Le tirage d'une commande ne recalcule
```

par :

```markdown
   la 19e, le 8 vers la 57e, et tout est ouvert vers la 123e (médianes, parties de 160 robes : l'amitié des quatre
   dernières clientes, arrivées aux prestiges 5 à 8, ouvre les dernières variantes). Le tirage d'une commande ne recalcule
```

Dans `README.md`, remplacer :

```markdown
9. **L'histoire** : huit événements du quartier se suivent (le bal des lanternes, la kermesse, le vernissage, les
   régates, la veillée des contes, le mariage de Margot, le concert du kiosque, le grand bal d'hiver). Le premier
```

par :

```markdown
9. **L'histoire** : douze événements du quartier se suivent (le bal des lanternes, la kermesse, le vernissage, les
   régates, la veillée des contes, le mariage de Margot, le concert du kiosque, le grand bal d'hiver, le salon du
   livre, la première du théâtre, le mariage de Colette, le grand défilé du quartier). Le premier
```

Dans `README.md`, remplacer :

```markdown
   avec une tenue imposée. Toutes les robes livrées, l'événement a lieu : son épilogue, un souvenir (une des huit
   décorations nouvelles) et 15 de prestige ; le carnet d'adresses garde les souvenirs. Les commandes ordinaires
```

par :

```markdown
   avec une tenue imposée. Toutes les robes livrées, l'événement a lieu : son épilogue, un souvenir (une des douze
   décorations nouvelles) et 15 de prestige ; le carnet d'adresses garde les souvenirs. Les commandes ordinaires
```

Dans `README.md`, remplacer :

```markdown
10. La suite : sous-projet 4 (porter la robe sur son avatar, défilés).
```

par :

```markdown
10. La suite : sous-projet 5 (porter la robe sur son avatar, défilés entre joueurs), à décider.
```

Dans `README.md`, remplacer :

```markdown
  | `Clientes`, `Progression` | Les six clientes (mesures, tenue, goûts, répliques) et qui vient à la clochette ; amitié, prestige et leurs niveaux |
```

par :

```markdown
  | `Clientes`, `Progression` | Les dix clientes (mesures, tenue, goûts, répliques) et qui vient à la clochette ; amitié, prestige et leurs niveaux |
```

Dans `README.md`, remplacer :

```markdown
  | `Histoire` | Les huit événements du quartier : leurs robes, tenues, répliques, épilogues et souvenirs ; l'événement en cours et sa prochaine robe |
```

par :

```markdown
  | `Histoire` | Les douze événements du quartier : leurs robes, tenues, répliques, épilogues et souvenirs ; l'événement en cours et sa prochaine robe |
```

Dans `src/shared/Commandes.luau`, remplacer :

```lua
-- Toutes les combinaisons de variantes du carnet (3 × 3 × 3 × 4 = 108)
```

par :

```lua
-- Toutes les combinaisons de variantes du carnet (5 × 5 × 4 × 5 = 500)
```

- [ ] **Step 3: Tests, lieu régénéré, commit**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT"`
Expected:
```
Unitaires : 159562 vérifications
TOUT EST VERT : 737 vérifications
```

```bash
C:/dev/jeux/roblox-maker/rojo.exe build -o AtelierCouture.rbxl
git add README.md src/shared/Commandes.luau AtelierCouture.rbxl
git commit -m "Plan 8c terminé : quatre clientes, quatre événements, dix clientes à l'écran ; sous-projet 4 complet

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```
