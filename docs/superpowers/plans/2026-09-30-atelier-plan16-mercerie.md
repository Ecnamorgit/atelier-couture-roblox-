# Aiguille & Dentelle — Plan 16 : la mercerie

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Acheter la mercerie d'avance, comme dans *Dressmaker* : un stock de décorations (à l'unité, les garnitures par 50 cm), une Mercerie qu'on ouvre depuis l'accueil ou depuis les décorations sans quitter la robe, et des décorations qui puisent dans ce stock au lieu de l'argent.

**Architecture:** `EtatAtelier` gagne un champ `mercerie` (`[idAccessoire] = unités` ou cm), un kit de départ, `acheterMercerie` et `besoinsMercerie` ; `decorer` prend la différence au stock (ce qu'on retire y revient) et refuse ce qui manque ; un événement qui a lieu offre cinq souvenirs. Le serveur ajoute l'action `acheterMercerie` ; la sauvegarde passe en v4 (kit offert aux parties existantes). Côté client : un module `Mercerie` (la boutique par-dessus l'écran), `Decorateur` qui compte le stock au lieu du coût, la palette qui dit ce qu'il reste, « Mercerie » à l'accueil et aux décorations, et le stock d'un accessoire exigé au carnet.

**Tech Stack:** Luau, Rojo 7.7.0-rc.1, simulation Luau 0.650 (`tests/lancer.sh`), Roblox Studio via le connecteur MCP Studio.

**Spec:** `docs/superpowers/specs/2026-09-30-atelier-fidele-design.md` (section 3 ; plan 16 de la section 6).

## Décisions de ce plan

- **Kit de départ** : la spec parle de nœuds et de dentelle, mais ils ne sont pas ouverts au départ (amitié de clientes) ; le kit ne contient que des décorations ouvertes dès la première robe : 10 boutons nacrés, 5 boutons dorés, 10 perles, 3 fleurs roses, 2 fleurs blanches et 1,50 m de ruban rose (60 po au prix du catalogue).
- **Refus** : « Mercerie insuffisante : il te manque Perle ×1. » (plusieurs articles séparés par « ; », une garniture en cm : « Ruban rose, 12 cm ») plutôt que « Il te manque 2 perles. » (pas d'accord du pluriel à tenir pour 40 articles).
- **Ce qui compte** : un objet posé prend une unité ; une garniture prend sa longueur en cm, arrondie au-dessus (comme `prixDecorations` arrondissait le prix). `decorer` compare la nouvelle liste à l'ancienne : on ne reprend pas deux fois ce qui est déjà posé. `recommencer` perd les décorations posées (comme avant : elles étaient payées).
- **Prix** : inchangés, au catalogue (une garniture se vend par 50 cm : 5 fois son prix au dm). Le prix de vente d'une robe libre compte toujours ses décorations (`prixDecorations`, inchangé).
- **Éditeur** : on ne pose pas plus que ce qu'on a (le stock, plus ce que la robe a déjà pris) ; un point de garniture de trop est refusé, et une garniture ne commence pas sous 5 cm. La palette affiche ce qu'il reste à poser (« Perle · ×9 », « Ruban rose · 1,10 m ») et grise un article épuisé (attribut `Epuise`) ; en haut, l'article choisi montre ce que la robe en prend sur ce qu'on a (« Nœud de satin : 1 / 2 », « Ruban rose : 0,40 / 1,50 m »).
- **Mercerie** : un bouton sans texte (qui arrête les appuis) par-dessus le contenu, `ZIndex` 30 ; des casiers sur deux colonnes pour les décorations ouvertes ; une fiche (nom et prix, styles, − / +, « Acheter (6 po) »). Elle se détruit en se fermant. Aux décorations, un achat met la palette à jour sans toucher à la robe.
- **Carnet** : une exigence d'accessoire prend deux lignes, « Avec : Perle » puis « (en stock : 10) » (une seule ligne déborderait de la fiche de 310 px).
- **Sauvegarde** : v4 ; une mercerie illisible est laissée de côté article par article (inconnu, pas un entier positif), ramenée au plafond au-delà ; une partie v4 sans mercerie a une mercerie vide (le kit vient de la migration, une seule fois).
- **Découpage** : les règles d'abord (tâche 1 : le scénario pose le stock sur le serveur, en attendant les écrans), puis le serveur et la sauvegarde (tâche 2), puis les écrans (tâche 3 : le scénario achète par la Mercerie).
- **Vérifié pendant la préparation** : le plan a été joué entièrement sur un brouillon tiré de `main` ; dix-neuf variantes du brouillon (décorer sans stock, rien ne revient au stock, achat d'un article fermé, garniture vendue à l'unité, sans plafond, sans souvenirs, migration sans kit, lecture sans plafond, sans action serveur, objet ou garniture sans limite dans l'éditeur, décorations déjà posées oubliées, palette sans stock, article épuisé choisi, palette qui ne suit pas l'achat, mercerie sous le panneau, E qui sonne, carnet sans stock, quantité ignorée) échouent chacune sur la vérification qui les garde ; l'écran a été rendu dans Studio (libellé raccourci, styles sur leur ligne et trait de séparation ajoutés après l'avoir vu).

## Global Constraints

- **Dépôt** : `C:\dev\jeux\atelier-couture`, branche `mercerie`, créée depuis `main` (où le plan 15 est fusionné). Selon les règles du commanditaire : la branche testée et relue est fusionnée dans `main` et poussée sur GitHub.
- **Rojo** : `C:/dev/jeux/roblox-maker/rojo.exe`.
- **Contenu original** : aucun nom, texte, image ni son de *Dressmaker*.
- **Équilibrage** : les cibles de `48_equilibrage` doivent tenir ; le joueur simulé achète l'accessoire imposé quand il lui manque.
- **Contraintes des plans précédents toujours valables** : fins de ligne LF, commits en français terminés par `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`, textes d'au moins 14 px, le serveur fait foi.

## Review Focus

- **Un client qui envoie plus de décorations que son stock.** Attendu : le serveur refuse, rien ne change. Test : `62_mercerie_serveur` (« au-delà du stock »).
- **Une partie v3 avec une robe en cours déjà décorée.** Attendu : elle garde ses décorations et reçoit le kit entier. Test : `62_mercerie_serveur` (« une robe en cours garde ses décorations »).
- **Une garniture tracée plus loin que le ruban qu'on a.** Attendu : le point de trop est refusé, la garniture reste où elle en est. Test : `22_decorateur` (« un point qui dépasse la mercerie »).
- **Un achat pendant les décorations, puis retirer ou annuler une décoration.** Attendu : la palette suit le stock, la robe ne bouge pas. Test : scénario (« la palette suit l'achat », « de nouveau à poser », « annuler »).
- **La Mercerie ouverte à l'accueil.** Attendu : E ne sonne pas la clochette. Test : scénario (« tant que la mercerie est ouverte »).

---

### Task 1: La mercerie dans les règles (`EtatAtelier`)

**Files:**
- Modify: `src/shared/EtatAtelier.luau`
- Create: `tests/unitaires/61_mercerie.luau`
- Modify: `tests/unitaires/21_decorations_livraison.luau`, `tests/unitaires/27_etat_exporter.luau`, `tests/unitaires/46_deblocages_etat.luau`, `tests/unitaires/48_equilibrage.luau`, `tests/unitaires/50_robes_libres.luau`, `tests/scenario.luau`

**Interfaces:**
- Consumes: `Catalogue.accessoire`, `Notation.longueurGarniture`, `fermes` (locale d'`EtatAtelier`), `refus` (locale), `Histoire.aEuLieu` (existants).
- Produces: `etat.mercerie` (`[idAccessoire] = entier`, dans `CHAMPS`) ; `EtatAtelier.KIT_MERCERIE`, `MERCERIE_MAX_UNITES` (999), `MERCERIE_MAX_CM` (9999), `LOT_GARNITURE` (50), `ACHAT_MERCERIE_MAX` (99), `SOUVENIRS_OFFERTS` (5) ; `EtatAtelier.besoinsMercerie(pieces, accessoires) -> { [id] = entier }` ; `etat:acheterMercerie(id, quantite) -> { ok, prix, quantite }` (quantite : unités, ou cm ajoutés) ; `etat:decorer(liste)` rend `{ ok = true, prix = 0 }` ou le refus « Mercerie insuffisante : il te manque … ».

- [ ] **Step 1: Écrire les tests de la mercerie**

Créer `tests/unitaires/61_mercerie.luau` :

```lua
-- Sous-projet 6 : la mercerie achetée d'avance. Un stock (à l'unité pour les objets, en cm pour les garnitures) ;
-- les décorations y puisent au lieu de l'argent, ce qu'on retire y revient ; un kit de départ ; cinq souvenirs à
-- chaque événement.
local EtatAtelier = U.module("EtatAtelier")
local Catalogue = U.module("Catalogue")
local Deblocages = U.module("Deblocages")
local Notation = U.module("Notation")
local Clientes = U.module("Clientes")
local Histoire = U.module("Histoire")

-- Une robe simple, coupée, épinglée et cousue, aux décorations (sans rien de posé)
local function aDecorer(etat)
	etat.croquis = { corsage = "corsage_droit", manches = "manches_sans", col = "col_sans", jupe = "jupe_droite" }
	etat.tissus = { corsage_droit_devant = "coton_blanc", corsage_droit_dos = "coton_blanc", jupe_droite_devant = "coton_blanc", jupe_droite_dos = "coton_blanc" }
	for id in pairs(etat.tissus) do
		etat.coupees[id] = { x = 0, y = 0, angle = 0 }
		etat.epinglees[id] = true
		etat.coutures[id] = 1
	end
	etat.etape = "decorations"
end

-- Le kit de départ : d'environ 60 po, des décorations ouvertes au départ
do
	local e = EtatAtelier.nouveau(100)
	local valeur, fermes, dedans = 0, {}, true
	for id, q in pairs(EtatAtelier.KIT_MERCERIE) do
		local a = Catalogue.accessoire(id)
		valeur += if a.genre == "garniture" then a.prix * q / 10 else a.prix * q
		if not Deblocages.ouvert(e, "accessoires", id) then
			table.insert(fermes, id)
		end
		dedans = dedans and e.mercerie[id] == q
	end
	U.verifier(dedans, "le kit est dans la mercerie d'une partie neuve")
	U.verifier(valeur >= 50 and valeur <= 75 and #fermes == 0, ("un kit d'environ 60 po (%d), ouvert au départ (fermés : %s)"):format(valeur, table.concat(fermes, ", ")))
	U.verifier(e.mercerie ~= EtatAtelier.KIT_MERCERIE, "une copie du kit (deux parties ne partagent pas leur mercerie)")
end

-- Acheter : ce qui est ouvert, de 1 à 99, les garnitures par 50 cm, au prix du catalogue
do
	local e = EtatAtelier.nouveau(100)
	U.toutOuvrir(e)
	e.mercerie = {}
	local r = e:acheterMercerie("perle", 5)
	U.verifier(r.ok and r.prix == 5 and e.argent == 95 and e.mercerie.perle == 5, "5 perles : 5 po, dans le stock")
	r = e:acheterMercerie("dentelle_blanche", 2)
	U.verifier(r.ok and r.prix == 20 and e.argent == 75 and e.mercerie.dentelle_blanche == 100, "deux fois 50 cm de dentelle blanche (2 po/dm) : 20 po, 100 cm")
	U.verifier(not e:acheterMercerie("perle", 0).ok and not e:acheterMercerie("perle", 100).ok and not e:acheterMercerie("perle", 1.5).ok, "de 1 à 99, un nombre entier")
	U.verifier(not e:acheterMercerie("inconnue", 1).ok and not e:acheterMercerie(nil, 1).ok, "un article inconnu : refusé")
	local r2 = EtatAtelier.nouveau(100):acheterMercerie("croix_argent", 1)
	U.verifier(not r2.ok and string.find(r2.erreur, "Pas encore ouvert", 1, true) == 1, "un article fermé : refusé, avec ce qu'il faut pour l'ouvrir (" .. tostring(r2.erreur) .. ")")
	e.argent = 3
	U.verifier(not e:acheterMercerie("fleur_rose", 2).ok and e.argent == 3 and e.mercerie.fleur_rose == nil, "pas assez d'argent : refusé, rien ne change")
	e.argent = 10000
	e.mercerie.perle = EtatAtelier.MERCERIE_MAX_UNITES - 2
	U.verifier(not e:acheterMercerie("perle", 5).ok and e:acheterMercerie("perle", 2).ok and e.mercerie.perle == EtatAtelier.MERCERIE_MAX_UNITES, "999 unités au plus")
	e.mercerie.ruban_rose = EtatAtelier.MERCERIE_MAX_CM - 60
	U.verifier(not e:acheterMercerie("ruban_rose", 2).ok and e:acheterMercerie("ruban_rose", 1).ok, "9 999 cm au plus")
end

-- Décorer puise dans le stock : pas d'argent ; ce qui manque est refusé ; ce qu'on retire revient au stock
do
	local e = EtatAtelier.nouveau(1000)
	U.toutOuvrir(e)
	U.commander(e, Random.new(21))
	aDecorer(e)
	e.mercerie = { perle = 3, ruban_rose = 20 }
	local argent = e.argent
	local function objet(id)
		return { id = id, piece = 1, u = 0.5, v = 0.5, echelle = 1, angle = 0 }
	end
	local r = e:decorer({ objet("perle"), objet("perle") })
	U.verifier(r.ok and e.argent == argent and e.mercerie.perle == 1, "deux perles posées : prises au stock (il en reste une), pas d'argent")
	e:retourDecorations()
	r = e:decorer({ objet("perle"), objet("perle"), objet("perle"), objet("perle") })
	U.verifier(not r.ok and r.erreur == "Mercerie insuffisante : il te manque Perle ×1." and e.mercerie.perle == 1, "quatre perles pour trois : refusé, ce qui manque dit (" .. tostring(r.erreur) .. ")")
	r = e:decorer({ objet("perle") })
	U.verifier(r.ok and e.mercerie.perle == 2, "une perle retirée revient au stock")
	e:retourDecorations()
	-- Une garniture : ses cm, arrondis au-dessus, pris au stock
	local pieces = e:recette().pieces
	local court = { { u = 0.4, v = 0.5 }, { u = 0.6, v = 0.5 } }
	local cm = math.ceil(Notation.longueurGarniture(pieces[1].id, court) * 10 - 1e-9)
	r = e:decorer({ objet("perle"), { id = "ruban_rose", piece = 1, trajet = court } })
	U.verifier(r.ok and cm <= 20 and e.mercerie.ruban_rose == 20 - cm, ("une garniture de %d cm, prise au stock de ruban (20 cm)"):format(cm))
	e:retourDecorations()
	local long = { { u = 0, v = 0.2 }, { u = 1, v = 0.2 }, { u = 1, v = 0.8 }, { u = 0, v = 0.8 } }
	local cmLong = math.ceil(Notation.longueurGarniture(pieces[1].id, long) * 10 - 1e-9)
	r = e:decorer({ objet("perle"), { id = "ruban_rose", piece = 1, trajet = long } })
	U.verifier(not r.ok and r.erreur == ("Mercerie insuffisante : il te manque Ruban rose, %d cm."):format(cmLong - 20) and e.mercerie.ruban_rose == 20 - cm, "une garniture trop longue pour le stock : refusée (" .. tostring(r.erreur) .. ")")
	U.verifier(Clientes ~= nil, "(modules chargés)")
end

-- Un événement qui a lieu offre des exemplaires de son souvenir
do
	local e = EtatAtelier.nouveau(1000)
	e.livraisons = 3
	local r
	for _ = 1, #Histoire.EVENEMENTS[1].commandes do
		assert(e:commandeHistoire().ok)
		assert(e:mesurer(Clientes.get(e.commande.cliente).mesures).ok)
		aDecorer(e)
		assert(e:decorer({}).ok)
		e.commande.exigences = { { type = "qualite", valeur = 0.1 } }
		r = e:livrer()
	end
	local souvenir = Histoire.EVENEMENTS[1].souvenir
	U.verifier(r.evenement ~= nil and e.mercerie[souvenir] == EtatAtelier.SOUVENIRS_OFFERTS and EtatAtelier.SOUVENIRS_OFFERTS == 5, ("l'événement a lieu : cinq %s dans la mercerie"):format(souvenir))
end
```

- [ ] **Step 2: Adapter les tests qui payaient les décorations**

Dans `tests/unitaires/21_decorations_livraison.luau`, remplacer :

```lua
-- Décorer : liste complète, vérifiée, facturée à la différence
```

par :

```lua
-- Décorer : liste complète, vérifiée, prise à la mercerie à la différence (sous-projet 6)
```

Dans `tests/unitaires/21_decorations_livraison.luau`, remplacer :

```lua
local argent = e.argent
local r = e:decorer({ noeud, perle, dentelle })
U.verifier(r.ok and r.prix == 3 + 1 + 10 and e.argent == argent - 14, "décorations facturées")
```

par :

```lua
local argent = e.argent
e.mercerie = { noeud_satin = 5, perle = 5, dentelle_blanche = 100 }
local r = e:decorer({ noeud, perle, dentelle })
U.verifier(r.ok and e.argent == argent and e.mercerie.noeud_satin == 4 and e.mercerie.perle == 4 and e.mercerie.dentelle_blanche == 50, "décorations prises à la mercerie (5 dm de dentelle : 50 cm), pas d'argent")
```

Dans `tests/unitaires/21_decorations_livraison.luau`, remplacer :

```lua
-- Retour aux décorations, puis retrait de la dentelle : remboursée
U.verifier(e:retourDecorations().ok and e.etape == "decorations", "retour de la photo aux décorations")
r = e:decorer({ noeud, perle })
U.verifier(r.ok and r.prix == -10 and e.argent == argent - 4, "décoration retirée : remboursée")
```

par :

```lua
-- Retour aux décorations, puis retrait de la dentelle : elle revient à la mercerie
U.verifier(e:retourDecorations().ok and e.etape == "decorations", "retour de la photo aux décorations")
r = e:decorer({ noeud, perle })
U.verifier(r.ok and e.argent == argent and e.mercerie.dentelle_blanche == 100 and e.mercerie.noeud_satin == 4, "décoration retirée : revenue à la mercerie")
```

Dans `tests/unitaires/21_decorations_livraison.luau`, remplacer :

```lua
U.verifier(not e:decorer(cheres).ok and e.argent == argent - 4 and #e.accessoires == 2, "pas assez d'argent : refusé, rien ne change")
```

par :

```lua
local rCheres = e:decorer(cheres)
U.verifier(not rCheres.ok and rCheres.erreur == "Mercerie insuffisante : il te manque Broche camée ×60." and e.argent == argent and #e.accessoires == 2 and e.mercerie.noeud_satin == 4, "pas assez dans la mercerie : refusé, rien ne change")
```

Dans `tests/unitaires/21_decorations_livraison.luau`, remplacer :

```lua
U.verifier(r.ok and r.reussie and r.paie == paie and r.verse == paie - r.acompte and e.argent == avant - 3 + r.verse, "robe acceptée : paie = base × (0,5 + qualité), moins l'acompte")
```

par :

```lua
U.verifier(r.ok and r.reussie and r.paie == paie and r.verse == paie - r.acompte and e.argent == avant + r.verse, "robe acceptée : paie = base × (0,5 + qualité), moins l'acompte")
```

Dans `tests/unitaires/21_decorations_livraison.luau`, remplacer :

```lua
local argent4 = e4.argent
e4:decorer({ noeud })
U.verifier(e4:recommencer().ok and #e4.accessoires == 0 and e4.argent == argent4 - 3, "recommencer : les décorations posées sont perdues")
```

par :

```lua
local argent4 = e4.argent
e4.mercerie = { noeud_satin = 2 }
e4:decorer({ noeud })
U.verifier(e4:recommencer().ok and #e4.accessoires == 0 and e4.argent == argent4 and e4.mercerie.noeud_satin == 1, "recommencer : les décorations posées sont perdues (elles ne reviennent pas à la mercerie)")
```

Dans `tests/unitaires/46_deblocages_etat.luau`, remplacer :

```lua
d.clientes.ines.amitie = 18
U.verifier(d:decorer(croix).ok, "amitié d'Inès au niveau 4 : la croix se pose")
```

par :

```lua
d.clientes.ines.amitie = 18
d.mercerie.croix_argent = 1 -- (sous-projet 6 : une croix à la mercerie)
U.verifier(d:decorer(croix).ok, "amitié d'Inès au niveau 4 : la croix se pose")
```

Dans `tests/unitaires/48_equilibrage.luau`, remplacer :

```lua
		local deco = choix.impose and { { id = choix.impose, piece = 1, copie = "unique", u = 0.5, v = 0.5, echelle = 1, angle = 0 } } or {}
		assert(e:decorer(deco).ok)
```

par :

```lua
		local deco = choix.impose and { { id = choix.impose, piece = 1, copie = "unique", u = 0.5, v = 0.5, echelle = 1, angle = 0 } } or {}
		if choix.impose and (e.mercerie[choix.impose] or 0) < 1 then
			assert(e:acheterMercerie(choix.impose, 1).ok) -- (sous-projet 6 : l'accessoire exigé s'achète à la mercerie)
		end
		assert(e:decorer(deco).ok)
```

Dans `tests/unitaires/50_robes_libres.luau`, remplacer :

```lua
		deco[k] = { id = "fleur_rose", piece = 1, copie = "unique", u = 0.5, v = k / (fleurs + 1), echelle = 1, angle = 0 }
	end
	assert(j:retourDecorations().ok and j:decorer(deco).ok)
```

par :

```lua
		deco[k] = { id = "fleur_rose", piece = 1, copie = "unique", u = 0.5, v = k / (fleurs + 1), echelle = 1, angle = 0 }
	end
	j.mercerie.fleur_rose = fleurs -- (sous-projet 6 : les fleurs, à la mercerie)
	assert(j:retourDecorations().ok and j:decorer(deco).ok)
```

Dans `tests/unitaires/27_etat_exporter.luau`, remplacer :

```lua
etat:decorer({ { id = "noeud_satin", piece = 1, copie = "unique", u = 0.4, v = 0.3, echelle = 1, angle = 15 } })
U.verifier(etat.etape == "photo", "robe décorée (mise en place du test)")
```

par :

```lua
etat.mercerie.noeud_satin = 1 -- (sous-projet 6 : à la mercerie)
etat:decorer({ { id = "noeud_satin", piece = 1, copie = "unique", u = 0.4, v = 0.3, echelle = 1, angle = 15 } })
U.verifier(etat.etape == "photo", "robe décorée (mise en place du test)")
```

Dans `tests/scenario.luau`, remplacer :

```lua
local avantDeco = argent()
cliquer("Presenter")
verifier(titre() == "7. Photo et livraison" and argent() == avantDeco - coutRuban, "présenter : décorations payées")
```

par :

```lua
local avantDeco = argent()
serveur:atelier(joueur).etat.mercerie.noeud_satin = 1 -- (sous-projet 6 : le nœud, à la mercerie ; le ruban vient du kit)
local rubanAvant = serveur:atelier(joueur).etat.mercerie.ruban_rose
cliquer("Presenter")
verifier(titre() == "7. Photo et livraison" and argent() == avantDeco and serveur:atelier(joueur).etat.mercerie.noeud_satin == nil and serveur:atelier(joueur).etat.mercerie.ruban_rose < rubanAvant, "présenter : décorations prises à la mercerie, pas d'argent")
```

Dans `tests/scenario.luau`, remplacer :

```lua
verifier(titre() == "6. Décorations", "retouche : retour aux décorations")
cliquer("Deco_croix_argent")
```

par :

```lua
verifier(titre() == "6. Décorations", "retouche : retour aux décorations")
serveur:atelier(joueur).etat.mercerie.croix_argent = 1 -- (sous-projet 6 : la croix, à la mercerie)
cliquer("Deco_croix_argent")
```

- [ ] **Step 3: Lancer les tests, vérifier l'échec**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT|attempt|membre" | head -3`
Expected: échec : une ligne qui finit par `ÉCHEC : décorations prises à la mercerie (5 dm de dentelle : 50 cm), pas d'argent`

- [ ] **Step 4: La mercerie dans `EtatAtelier`**

Dans `src/shared/EtatAtelier.luau`, remplacer :

```lua
EtatAtelier.ETAPES = { "accueil", "mesures", "carnet", "achat", "decoupe", "epinglage", "couture", "decorations", "photo", "refus" }
```

par :

```lua
EtatAtelier.ETAPES = { "accueil", "mesures", "carnet", "achat", "decoupe", "epinglage", "couture", "decorations", "photo", "refus" }
-- Sous-projet 6 : la mercerie, achetée d'avance ([idAccessoire] = unités pour un objet, cm pour une garniture). Toute
-- partie commence avec un kit d'environ 60 po, de décorations ouvertes au départ
EtatAtelier.KIT_MERCERIE = {
	bouton_nacre = 10,
	bouton_dore = 5,
	perle = 10,
	fleur_rose = 3,
	fleur_blanche = 2,
	ruban_rose = 150,
}
EtatAtelier.MERCERIE_MAX_UNITES = 999
EtatAtelier.MERCERIE_MAX_CM = 9999
EtatAtelier.LOT_GARNITURE = 50 -- cm par lot de garniture acheté
EtatAtelier.ACHAT_MERCERIE_MAX = 99 -- unités ou lots par achat
EtatAtelier.SOUVENIRS_OFFERTS = 5 -- exemplaires du souvenir d'un événement qui a lieu
```

Dans `src/shared/EtatAtelier.luau`, remplacer :

```lua
		histoire = { faites = {} }, -- sous-projet 3 : les commandes d'histoire livrées ([idCommande] = true)
	}, EtatAtelier)
```

par :

```lua
		histoire = { faites = {} }, -- sous-projet 3 : les commandes d'histoire livrées ([idCommande] = true)
		mercerie = table.clone(EtatAtelier.KIT_MERCERIE), -- sous-projet 6
	}, EtatAtelier)
```

Dans `src/shared/EtatAtelier.luau`, remplacer :

```lua
local CHAMPS = { "argent", "stock", "etape", "commande", "croquis", "tissus", "coupees", "epinglees", "coutures", "accessoires", "robes", "clientes", "prestige", "livraisons", "visites", "ventes", "lettres", "histoire" }
```

par :

```lua
local CHAMPS = { "argent", "stock", "etape", "commande", "croquis", "tissus", "coupees", "epinglees", "coutures", "accessoires", "robes", "clientes", "prestige", "livraisons", "visites", "ventes", "lettres", "histoire", "mercerie" }
```

Dans `src/shared/EtatAtelier.luau`, remplacer :

```lua
-- Recette de la robe en cours (position des pièces sur le rouleau, notes de couture, décorations),
```

par :

```lua
-- Ce que des décorations prennent à la mercerie : [id] = unités (un objet) ou cm (une garniture, arrondis au-dessus)
function EtatAtelier.besoinsMercerie(pieces, accessoires)
	local out = {}
	for _, a in ipairs(accessoires) do
		local def = Catalogue.accessoire(a.id)
		local q = if def.genre == "garniture" then math.ceil(Notation.longueurGarniture(pieces[a.piece].id, a.trajet) * 10 - 1e-9) else 1
		out[a.id] = (out[a.id] or 0) + q
	end
	return out
end

-- Acheter de la mercerie : ce qui est ouvert, de 1 à 99 unités (un objet) ou lots de 50 cm (une garniture), au prix
-- du catalogue ; 999 unités ou 9 999 cm au plus en stock
function EtatAtelier:acheterMercerie(id, quantite)
	local def = type(id) == "string" and Catalogue.accessoire(id)
	if not def then
		return refus("Article inconnu.")
	end
	if type(quantite) ~= "number" or quantite ~= math.floor(quantite) or quantite < 1 or quantite > EtatAtelier.ACHAT_MERCERIE_MAX then
		return refus("Quantité invalide.")
	end
	local ferme = fermes(self, "accessoires", { id })
	if ferme then
		return ferme
	end
	local garniture = def.genre == "garniture"
	local ajout = if garniture then quantite * EtatAtelier.LOT_GARNITURE else quantite
	local prix = if garniture then def.prix * ajout / 10 else def.prix * quantite
	if (self.mercerie[id] or 0) + ajout > (if garniture then EtatAtelier.MERCERIE_MAX_CM else EtatAtelier.MERCERIE_MAX_UNITES) then
		return refus("Ta mercerie n'a plus de place pour cet article.")
	end
	if prix > self.argent then
		return refus("Pas assez d'argent.")
	end
	self.argent -= prix
	self.mercerie[id] = (self.mercerie[id] or 0) + ajout
	return { ok = true, prix = prix, quantite = ajout }
end

-- Recette de la robe en cours (position des pièces sur le rouleau, notes de couture, décorations),
```

Dans `src/shared/EtatAtelier.luau`, remplacer :

```lua
-- Décorations : la liste complète, envoyée quand on quitte le poste (spec §6). Vérifiée comme une
-- recette (identifiants, 300 objets et 64 points au plus, u et v dans [0 ; 1], échelle et angle
-- bornés) ; on facture la différence avec la liste précédente (ce qu'on retire est remboursé).
```

par :

```lua
-- Décorations : la liste complète, envoyée quand on quitte le poste (spec §6). Vérifiée comme une
-- recette (identifiants, 300 objets et 64 points au plus, u et v dans [0 ; 1], échelle et angle
-- bornés). Sous-projet 6 : la différence avec la liste précédente est prise à la mercerie (ce qu'on retire y
-- revient) ; ce qui manque est refusé.
```

Dans `src/shared/EtatAtelier.luau`, remplacer :

```lua
	local difference = EtatAtelier.prixDecorations(recette.pieces, propres) - EtatAtelier.prixDecorations(recette.pieces, self.accessoires)
	if difference > self.argent then
		return refus("Pas assez d'argent pour ces décorations.")
	end
	self.argent -= difference
	self.accessoires = propres
	self.etape = "photo"
	return { ok = true, prix = difference }
```

par :

```lua
	local avant = EtatAtelier.besoinsMercerie(recette.pieces, self.accessoires)
	local apres = EtatAtelier.besoinsMercerie(recette.pieces, propres)
	local manque, variations = {}, {}
	for _, def in ipairs(Catalogue.Accessoires) do -- (dans l'ordre du catalogue : un message stable)
		local variation = (apres[def.id] or 0) - (avant[def.id] or 0)
		local stock = self.mercerie[def.id] or 0
		if variation > stock then
			table.insert(manque, if def.genre == "garniture" then ("%s, %d cm"):format(def.nom, variation - stock) else ("%s ×%d"):format(def.nom, variation - stock))
		elseif variation ~= 0 then
			variations[def.id] = variation
		end
	end
	if #manque > 0 then
		return refus("Mercerie insuffisante : il te manque " .. table.concat(manque, " ; ") .. ".")
	end
	for id, variation in pairs(variations) do
		local reste = (self.mercerie[id] or 0) - variation
		self.mercerie[id] = if reste > 0 then reste else nil
	end
	self.accessoires = propres
	self.etape = "photo"
	return { ok = true, prix = 0 }
```

Dans `src/shared/EtatAtelier.luau`, remplacer :

```lua
		if ev and Histoire.aEuLieu(self, ev.id) then
			evenement = { id = ev.id, nom = ev.nom, epilogue = ev.epilogue, souvenir = ev.souvenir }
		end
```

par :

```lua
		if ev and Histoire.aEuLieu(self, ev.id) then
			evenement = { id = ev.id, nom = ev.nom, epilogue = ev.epilogue, souvenir = ev.souvenir }
			-- (sous-projet 6) des exemplaires du souvenir, dans la mercerie
			self.mercerie[ev.souvenir] = math.min((self.mercerie[ev.souvenir] or 0) + EtatAtelier.SOUVENIRS_OFFERTS, EtatAtelier.MERCERIE_MAX_UNITES)
		end
```

- [ ] **Step 5: Lancer les tests**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT"`
Expected:
```
Unitaires : 167874 vérifications
TOUT EST VERT : 868 vérifications
```

- [ ] **Step 6: Commit**

```bash
git add src/shared/EtatAtelier.luau tests/unitaires/61_mercerie.luau tests/unitaires/21_decorations_livraison.luau tests/unitaires/27_etat_exporter.luau tests/unitaires/46_deblocages_etat.luau tests/unitaires/48_equilibrage.luau tests/unitaires/50_robes_libres.luau tests/scenario.luau
git commit -m "La mercerie : un stock acheté d'avance, un kit de départ ; les décorations y puisent, ce qu'on retire y revient

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 2: Le serveur et la sauvegarde v4

**Files:**
- Modify: `src/server/Commande.luau`, `src/server/Sauvegarde.luau`
- Create: `tests/unitaires/62_mercerie_serveur.luau`
- Modify: `tests/unitaires/43_sauvegarde_clientes.luau`

**Interfaces:**
- Consumes: `etat:acheterMercerie`, `etat.mercerie`, `EtatAtelier.KIT_MERCERIE`, `MERCERIE_MAX_UNITES`, `MERCERIE_MAX_CM` (tâche 1).
- Produces: l'action serveur `acheterMercerie(idAccessoire, quantite)` ; `Sauvegarde.VERSION = 4`, `Sauvegarde.MIGRATIONS[3]` ; le champ `mercerie` de la partie.

- [ ] **Step 1: Écrire les tests du serveur et de la sauvegarde**

Créer `tests/unitaires/62_mercerie_serveur.luau` :

```lua
-- Sous-projet 6 : la mercerie dans la sauvegarde (format v4, kit offert aux parties existantes) et sur le serveur
-- (achat limité comme les autres actions, décorations vérifiées contre le stock).
local Sauvegarde = U.module("Sauvegarde")
local Commande = U.module("Commande")
local EtatAtelier = U.module("EtatAtelier")

-- Une robe simple, coupée, épinglée et cousue, aux décorations (sans rien de posé)
local function aDecorer(etat)
	etat.croquis = { corsage = "corsage_droit", manches = "manches_sans", col = "col_sans", jupe = "jupe_droite" }
	etat.tissus = { corsage_droit_devant = "coton_blanc", corsage_droit_dos = "coton_blanc", jupe_droite_devant = "coton_blanc", jupe_droite_dos = "coton_blanc" }
	for id in pairs(etat.tissus) do
		etat.coupees[id] = { x = 0, y = 0, angle = 0 }
		etat.epinglees[id] = true
		etat.coutures[id] = 1
	end
	etat.etape = "decorations"
end
local function perle(v)
	return { id = "perle", piece = 1, copie = "unique", u = 0.5, v = v or 0.5, echelle = 1, angle = 0 }
end

---------------------------------------------------------------------------
-- Sauvegarde v4 : la mercerie, relue à l'identique
---------------------------------------------------------------------------
U.verifier(Sauvegarde.VERSION == 4, "format v4")
local e = EtatAtelier.nouveau(300)
e.mercerie = { perle = 12, ruban_rose = 250 }
local relue = Sauvegarde.versEtat(M.transmettre(Sauvegarde.depuisEtat(e)))
U.verifier(relue.mercerie.perle == 12 and relue.mercerie.ruban_rose == 250 and relue.mercerie.bouton_nacre == nil, "mercerie sauvée, relue telle quelle")

-- Mercerie abîmée : ce qui est illisible est laissé de côté ; au-delà du plafond, ramené au plafond
local partie = Sauvegarde.depuisEtat(e)
partie.mercerie = { perle = -3, bouton_nacre = 2.5, fleur_rose = "trois", inconnu = 4, bouton_dore = 5000, dentelle_blanche = 20000, noeud_satin = 0 / 0, fleur_blanche = 4, etoile_brodee = 0 }
local m = Sauvegarde.versEtat(partie).mercerie
U.verifier(m.perle == nil and m.bouton_nacre == nil and m.fleur_rose == nil and m.inconnu == nil and m.noeud_satin == nil and m.etoile_brodee == nil and m.fleur_blanche == 4, "quantités négatives, nulles, fractionnaires ou illisibles, articles inconnus : laissés")
U.verifier(m.bouton_dore == EtatAtelier.MERCERIE_MAX_UNITES and m.dentelle_blanche == EtatAtelier.MERCERIE_MAX_CM, "au-delà du plafond : ramené à 999 unités ou 9 999 cm")
partie.mercerie = "abîmée"
U.verifier(next(Sauvegarde.versEtat(partie).mercerie) == nil, "mercerie illisible : vide")
partie.mercerie = nil
U.verifier(next(Sauvegarde.versEtat(partie).mercerie) == nil, "une partie v4 sans mercerie : vide (le kit vient de la migration, pas de la lecture)")

---------------------------------------------------------------------------
-- Migration v3 → v4 : le kit de mercerie offert ; une robe en cours garde ses décorations
---------------------------------------------------------------------------
local v3 = { version = 3, argent = 300, stock = {}, debloques = {}, recettes = {}, prestige = 0, livraisons = 0, visites = 0, clientes = {} }
local v4 = Sauvegarde.migrer(v3)
local kit = true
for id, q in pairs(EtatAtelier.KIT_MERCERIE) do
	kit = kit and v4.mercerie[id] == q
end
U.verifier(v4.version == 4 and kit and v4.argent == 300 and v4.mercerie ~= EtatAtelier.KIT_MERCERIE, "v3 → v4 : une copie du kit de mercerie, rien d'autre ne change")
U.verifier(Sauvegarde.migrer({ argent = 480 }).mercerie.perle == EtatAtelier.KIT_MERCERIE.perle, "v1 → v4 : les migrations s'enchaînent jusqu'au kit")
local enCours = EtatAtelier.nouveau(1000)
U.commander(enCours, Random.new(8))
aDecorer(enCours)
enCours.mercerie = { perle = 1 }
assert(enCours:decorer({ perle() }).ok)
local p3 = Sauvegarde.depuisEtat(enCours)
p3.version, p3.mercerie = 3, nil -- (une partie d'avant la mercerie)
local reprise = Sauvegarde.versEtat(M.transmettre(Sauvegarde.migrer(p3)))
U.verifier(reprise.etape == "photo" and #reprise.accessoires == 1 and reprise.accessoires[1].id == "perle" and reprise.mercerie.perle == EtatAtelier.KIT_MERCERIE.perle, "une robe en cours garde ses décorations, et reçoit le kit entier")

---------------------------------------------------------------------------
-- Serveur : l'achat, limité comme les autres actions ; les arguments farfelus refusés proprement
---------------------------------------------------------------------------
local serveur = Commande.nouvelle()
local joueur = M.nouveauJoueur("Merciere")
local function appeler(action, ...)
	M.avancer(0.25)
	local r = serveur:traiter(joueur, action, ...)
	local ok, erreur = pcall(M.transmettre, r)
	U.verifier(ok, "réponse à « " .. tostring(action) .. " » transmissible (" .. tostring(erreur) .. ")")
	return r
end
local r = appeler("etat")
U.verifier(r.ok and r.etat.mercerie.perle == EtatAtelier.KIT_MERCERIE.perle, "le client reçoit la mercerie (le kit)")
r = appeler("acheterMercerie", "perle", 3)
U.verifier(r.ok and r.prix == 3 and r.quantite == 3 and r.etat.mercerie.perle == EtatAtelier.KIT_MERCERIE.perle + 3 and r.etat.argent == EtatAtelier.ARGENT_DEPART - 3, "achat à la mercerie, sur le serveur : l'état suit")
local perles = serveur:atelier(joueur).etat.mercerie.perle
for k, cas in ipairs({ { "perle", "trois" }, { "perle", 0 / 0 }, { "perle", math.huge }, { M.services.Workspace, 1 }, { { "perle" }, 1 }, { "croix_argent", 1 } }) do
	r = appeler("acheterMercerie", cas[1], cas[2])
	U.verifier(not r.ok and r.erreur ~= "Action impossible." and serveur:atelier(joueur).etat.mercerie.perle == perles and serveur:atelier(joueur).etat.argent == EtatAtelier.ARGENT_DEPART - 3, "achat farfelu refusé proprement (" .. k .. ") : " .. tostring(r.erreur))
end
M.avancer(2)
local acceptes = 0
for _ = 1, 8 do
	if serveur:traiter(joueur, "acheterMercerie", "bouton_nacre", 1).ok then
		acceptes += 1
	end
end
U.verifier(acceptes == Commande.APPELS_PAR_SECONDE, "rafale d'achats : limitée comme les autres actions (" .. acceptes .. " sur 8)")

---------------------------------------------------------------------------
-- Serveur : des décorations au-delà du stock sont refusées (le client ne peut pas tricher)
---------------------------------------------------------------------------
M.avancer(2)
local a = serveur:atelier(joueur).etat
U.commander(a, Random.new(5))
aDecorer(a)
a.argent, a.mercerie = 1000, { perle = 1 }
r = appeler("decorer", { perle(0.4), perle(0.6) })
U.verifier(not r.ok and r.erreur == "Mercerie insuffisante : il te manque Perle ×1." and a.etape == "decorations" and a.mercerie.perle == 1 and a.argent == 1000, "décorations au-delà du stock : refusées par le serveur, rien ne change (" .. tostring(r.erreur) .. ")")
r = appeler("decorer", { perle() })
U.verifier(r.ok and a.mercerie.perle == nil and r.etat.mercerie.perle == nil and a.argent == 1000, "une perle posée : prise au stock du serveur, pas d'argent")
```

- [ ] **Step 2: Adapter le test du format v3**

Dans `tests/unitaires/43_sauvegarde_clientes.luau`, remplacer :

```lua
U.verifier(Sauvegarde.VERSION == 3, "format v3")
```

par :

```lua
U.verifier(Sauvegarde.VERSION >= 3, "format v3 ou plus récent")
```

Dans `tests/unitaires/43_sauvegarde_clientes.luau`, remplacer :

```lua
local v3 = Sauvegarde.migrer(v2)
U.verifier(v3.version == 3 and v3.prestige == 60 and v3.livraisons == 3 and v3.visites == 0 and next(v3.clientes) == nil and v3.argent == 300, "v2 → v3 : prestige des robes passées, aucune cliente")
U.verifier(Sauvegarde.migrer({ argent = 480 }).version == 3, "v1 → v3 : les migrations s'enchaînent")
```

par :

```lua
local v3 = Sauvegarde.MIGRATIONS[2](v2)
U.verifier(v3.version == 3 and v3.prestige == 60 and v3.livraisons == 3 and v3.visites == 0 and next(v3.clientes) == nil and v3.argent == 300, "v2 → v3 : prestige des robes passées, aucune cliente")
U.verifier(Sauvegarde.migrer({ argent = 480 }).version == Sauvegarde.VERSION, "v1 → dernier format : les migrations s'enchaînent")
```

- [ ] **Step 3: Lancer les tests, vérifier l'échec**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT|attempt|membre" | head -3`
Expected: échec : une ligne qui finit par `ÉCHEC : format v4`

- [ ] **Step 4: L'action et la sauvegarde**

Dans `src/server/Commande.luau`, remplacer :

```lua
	acheter = function(a, idTissu, dm)
		return a.etat:acheter(idTissu, dm)
	end,
```

par :

```lua
	acheter = function(a, idTissu, dm)
		return a.etat:acheter(idTissu, dm)
	end,
	-- (sous-projet 6) la mercerie, achetée d'avance
	acheterMercerie = function(a, idAccessoire, quantite)
		return a.etat:acheterMercerie(idAccessoire, quantite)
	end,
```

Dans `src/server/Sauvegarde.luau`, remplacer :

```lua
Sauvegarde.VERSION = 3
```

par :

```lua
Sauvegarde.VERSION = 4
```

Dans `src/server/Sauvegarde.luau`, remplacer :

```lua
		v2.clientes = {}
		return v2
	end,
}
```

par :

```lua
		v2.clientes = {}
		return v2
	end,
	-- v3 → v4 (sous-projet 6) : la mercerie, achetée d'avance ; chaque partie reçoit le kit de départ (une robe en
	-- cours garde ses décorations, déjà posées)
	[3] = function(v3)
		v3.version = 4
		v3.mercerie = table.clone(EtatAtelier.KIT_MERCERIE)
		return v3
	end,
}
```

Dans `src/server/Sauvegarde.luau`, remplacer :

```lua
		lettres = d.lettres,
		histoire = d.histoire,
	}
```

par :

```lua
		lettres = d.lettres,
		histoire = d.histoire,
		mercerie = d.mercerie,
	}
```

Dans `src/server/Sauvegarde.luau`, remplacer :

```lua
	-- Courrier : trois lettres au plus, d'une cliente connue, avec une commande qu'on peut jouer
```

par :

```lua
	-- Mercerie : des articles connus, en quantités entières et positives, ramenées au plafond ; absente ou illisible :
	-- vide (le kit vient de la migration v3 → v4)
	base.mercerie = {}
	for id, q in pairs(type(partie.mercerie) == "table" and partie.mercerie or {}) do
		local def = type(id) == "string" and Catalogue.accessoire(id)
		if def and nombre(q, 0) >= 1 and q == math.floor(q) then
			base.mercerie[id] = math.min(q, if def.genre == "garniture" then EtatAtelier.MERCERIE_MAX_CM else EtatAtelier.MERCERIE_MAX_UNITES)
		end
	end
	-- Courrier : trois lettres au plus, d'une cliente connue, avec une commande qu'on peut jouer
```

- [ ] **Step 5: Lancer les tests**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT"`
Expected:
```
Unitaires : 167904 vérifications
TOUT EST VERT : 868 vérifications
```

- [ ] **Step 6: Commit**

```bash
git add src/server/Commande.luau src/server/Sauvegarde.luau tests/unitaires/62_mercerie_serveur.luau tests/unitaires/43_sauvegarde_clientes.luau
git commit -m "Mercerie : l'achat sur le serveur, la sauvegarde v4 (kit offert aux parties existantes)

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 3: La Mercerie à l'écran, la palette, l'accueil et le carnet

**Files:**
- Create: `src/client/Atelier/Mercerie.luau`
- Modify: `src/client/Atelier/Decorateur.luau`, `src/client/Atelier/EcranDecorations.luau`, `src/client/Atelier/EcranAccueil.luau`, `src/client/Atelier/EcranCarnet.luau`, `src/client/Atelier/Session.luau`, `src/client/Atelier/init.client.luau`
- Modify: `tests/unitaires/22_decorateur.luau`, `tests/scenario.luau`

**Interfaces:**
- Consumes: `EtatAtelier.besoinsMercerie`, `etat.mercerie`, `EtatAtelier.ACHAT_MERCERIE_MAX` (tâche 1) ; l'action `acheterMercerie` (tâche 2).
- Produces: `Mercerie.metres(cm) -> "1,50"`, `Mercerie.stock(id, quantite) -> "×12" | "1,50 m"`, `Mercerie.ouvrir(ctx, auChangement) -> panneau` (dans `ctx.contenu` : `Mercerie`, `TitreMercerie`, `FermerMercerie`, `Casiers` et ses `Case_<id>`, `Trait`, `Fiche` et ses `Article`, `Styles`, `Quantite`, `QuantiteMoins`, `QuantitePlus`, `AcheterMercerie`) ; `Decorateur.nouveau(recette, prises, stock)`, `deco:majStock(stock)`, `deco:usage(id) -> pris, dispo`, `deco:reste(id)`, `deco:epuise(id)` (`deco:cout()` retiré) ; `session:acheterMercerie(id, quantite)` ; aux décorations, `Usage` (au lieu de `Cout`) et `OuvrirMercerie` ; à l'accueil, `OuvrirMercerie`.

- [ ] **Step 1: Écrire les tests**

Dans `tests/unitaires/22_decorateur.luau`, remplacer :

```lua
local Decorateur = U.module("Decorateur")
local EtatAtelier = U.module("EtatAtelier")
local Recette = U.module("Recette")
```

par :

```lua
local Decorateur = U.module("Decorateur")
local EtatAtelier = U.module("EtatAtelier")
local Recette = U.module("Recette")
local Notation = U.module("Notation")
local Mercerie = U.module("Mercerie")
local MANQUE_NOEUD = "Plus assez de Nœud de satin dans ta mercerie : achètes-en à la Mercerie."
local MANQUE_RUBAN = "Plus assez de Ruban rose dans ta mercerie : achètes-en à la Mercerie."
```

Dans `tests/unitaires/22_decorateur.luau`, remplacer :

```lua
local d = Decorateur.nouveau(recette, {})
U.verifier(#d.liste == 0 and d:cout() == 0 and d.selection == nil, "départ : rien de posé, rien à payer")
```

par :

```lua
local d = Decorateur.nouveau(recette, {}, { noeud_satin = 2 })
U.verifier(#d.liste == 0 and d:usage("noeud_satin") == 0 and d:reste("noeud_satin") == 2 and d.selection == nil, "départ : rien de posé, deux nœuds dans la mercerie")
```

Dans `tests/unitaires/22_decorateur.luau`, remplacer :

```lua
U.verifier(d:cout() == 6, "deux nœuds : 6 po")
```

par :

```lua
local pris, dispo = d:usage("noeud_satin")
U.verifier(pris == 2 and dispo == 2 and d:epuise("noeud_satin"), "deux nœuds posés sur deux : épuisé")
local refus = d:toucher(1, "unique", 0.2, 0.2)
U.verifier(not refus.ok and refus.erreur == MANQUE_NOEUD and #d.liste == 2, "un troisième nœud : refusé, la mercerie est vide")
d:majStock({ noeud_satin = 3 })
U.verifier(d:reste("noeud_satin") == 1 and not d:epuise("noeud_satin"), "un achat (trois nœuds en tout) : il en reste un à poser")
```

Dans `tests/unitaires/22_decorateur.luau`, remplacer :

```lua
local g = Decorateur.nouveau(recette, {})
```

par :

```lua
local g = Decorateur.nouveau(recette, {}, { dentelle_blanche = EtatAtelier.MERCERIE_MAX_CM, perle = 5 })
```

Dans `tests/unitaires/22_decorateur.luau`, remplacer :

```lua
U.verifier(g:cout() == 0 and #g:resultat() == 0, "trop courte : ni coût ni envoi")
```

par :

```lua
U.verifier(g:usage("dentelle_blanche") == 0 and #g:resultat() == 0, "trop courte : rien de pris, rien d'envoyé")
```

Dans `tests/unitaires/22_decorateur.luau`, remplacer :

```lua
U.verifier(g:cout() == 10, "dentelle en cours comptée dans le coût (5 dm à 2 po)")
```

par :

```lua
U.verifier(g:usage("dentelle_blanche") == math.ceil(Notation.longueurGarniture("jupe_droite_devant", g.garniture.trajet) * 10 - 1e-9), "dentelle en cours comptée dans ce que la robe prend")
```

Dans `tests/unitaires/22_decorateur.luau`, remplacer :

```lua
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
```

par :

```lua
-- Mercerie : ce qui est déjà pris compte dans ce qu'on a ; liste acceptée par EtatAtelier
---------------------------------------------------------------------------
local payees = { { id = "noeud_satin", piece = 1, u = 0.5, v = 0.3, echelle = 1, angle = 0 } }
local avec = table.clone(recette)
avec.accessoires = payees
local p = Decorateur.nouveau(avec, payees, {})
pris, dispo = p:usage("noeud_satin")
U.verifier(#p.liste == 1 and pris == 1 and dispo == 1, "un nœud déjà pris (mercerie vide) : un posé sur un")
p:selectionner(1)
p:supprimer()
U.verifier(p:usage("noeud_satin") == 0 and p:reste("noeud_satin") == 1, "retirer un nœud déjà pris : il est de nouveau à poser")
p.liste[1] = nil
U.verifier(#payees == 1, "la liste des décorations prises n'est pas modifiée par l'éditeur")
local final = Decorateur.nouveau(recette, {}, { perle = 1, ruban_rose = 100 })
```

Dans `tests/unitaires/22_decorateur.luau`, remplacer :

```lua
U.verifier(EtatAtelier.prixDecorations(recette.pieces, liste) == final:cout(), "le coût affiché est celui que facturera EtatAtelier")
```

par :

```lua
local besoins = EtatAtelier.besoinsMercerie(recette.pieces, liste)
U.verifier(besoins.perle == (final:usage("perle")) and besoins.ruban_rose == (final:usage("ruban_rose")), "ce que la robe prend est ce qu'EtatAtelier prendra à la mercerie")

---------------------------------------------------------------------------
-- Une garniture ne dépasse pas la mercerie : le point de trop est refusé
---------------------------------------------------------------------------
local function cm(trajet)
	return math.ceil(Notation.longueurGarniture("jupe_droite_devant", trajet) * 10 - 1e-9)
end
local court = cm({ { u = 0, v = 1 }, { u = 0.3, v = 1 } })
local long = cm({ { u = 0, v = 1 }, { u = 0.3, v = 1 }, { u = 0.5, v = 1 } })
assert(court >= 5 and long > court + 1, "(la jupe est assez large pour ce test)")
local s = Decorateur.nouveau(recette, {}, { ruban_rose = court + 1 })
s:choisir("ruban_rose")
U.verifier(s:toucher(4, "unique", 0, 1).ok and s:toucher(4, "unique", 0.3, 1).ok, "ruban : de quoi poser le premier bout")
local trop = s:toucher(4, "unique", 0.5, 1)
U.verifier(not trop.ok and trop.erreur == MANQUE_RUBAN and #s.garniture.trajet == 2, "un point qui dépasse la mercerie : refusé, la garniture reste où elle en est")
pris, dispo = s:usage("ruban_rose")
U.verifier(pris == court and dispo == court + 1 and s:reste("ruban_rose") == 1 and s:epuise("ruban_rose"), "il reste 1 cm : trop peu pour une garniture (épuisé)")
local vide = Decorateur.nouveau(recette, {}, { ruban_rose = 4 })
vide:choisir("ruban_rose")
local premier = vide:toucher(4, "unique", 0, 1)
U.verifier(not premier.ok and premier.erreur == MANQUE_RUBAN and vide.garniture == nil, "moins de 5 cm de ruban : pas même un premier point")

---------------------------------------------------------------------------
-- Mercerie : les quantités en clair
---------------------------------------------------------------------------
U.verifier(Mercerie.metres(150) == "1,50" and Mercerie.metres(5) == "0,05" and Mercerie.metres(0) == "0,00", "des cm en mètres, à la française")
U.verifier(Mercerie.stock("perle", 12) == "×12" and Mercerie.stock("perle", nil) == "×0" and Mercerie.stock("ruban_rose", 250) == "2,50 m", "quantités en clair : ×12, ×0, 2,50 m")
```

Dans `tests/scenario.luau`, remplacer :

```lua
	verifier(gauche <= 2 and droite <= 2, cle .. " : réglé juste, le mannequin épouse la silhouette")
end
cliquer("ValiderMesures")
```

par :

```lua
	verifier(gauche <= 2 and droite <= 2, cle .. " : réglé juste, le mannequin épouse la silhouette")
end
-- (sous-projet 6) Colette veut aussi une perle : au carnet, l'exigence dira ce qu'on en a dans la mercerie
table.insert(serveur:atelier(joueur).etat.commande.exigences, { type = "accessoire", id = "perle" })
cliquer("ValiderMesures")
```

Dans `tests/scenario.luau`, remplacer :

```lua
verifier(titre() == "1. Carnet de croquis", "mesures prises : le carnet")
```

par :

```lua
verifier(titre() == "1. Carnet de croquis", "mesures prises : le carnet")
do -- Sous-projet 6 : une exigence d'accessoire dit ce qu'on en a dans la mercerie (le kit : dix perles)
	local ligne = texte("Avec : Perle")
	verifier(ligne ~= nil and string.find(ligne.Text, "Avec : Perle\n      (en stock : 10)", 1, true) ~= nil and ligne.Size.Y.Offset == 40, "au carnet, l'exigence d'une perle dit « (en stock : 10) », sur une seconde ligne")
end
```

Dans `tests/scenario.luau`, remplacer :

```lua
verifier(contenuD.Cout.Text == "Coût : 0 po", "rien posé : rien à payer")
toucherRobe("Piece_corsage_v_devant_unique", "corsage_v_devant", "unique", 0.5, 0.4)
verifier(#decorations:GetChildren() == 0 and fenetre.Message.Visible, "toucher la robe sans décoration choisie : un message")
cliquer("Deco_noeud_satin")
verifier(boutonNomme("Deco_noeud_satin").BackgroundColor3 == ACCENT, "nœud de satin choisi dans la palette")
toucherRobe("Piece_corsage_v_devant_unique", "corsage_v_devant", "unique", 0.5, 0.4)
verifier(#decorations:GetChildren() == 1 and contenuD.Cout.Text == "Coût : 3 po", "nœud posé sur le corsage : 3 po")
```

par :

```lua
verifier(contenuD.Usage.Text == "Mercerie : choisis une décoration.", "rien de choisi : la ligne de la mercerie l'explique")
verifier(boutonNomme("Deco_perle").Text == "Perle · ×10" and boutonNomme("Deco_ruban_rose").Text == "Ruban rose · 1,50 m", "la palette dit ce qu'il reste dans la mercerie : le kit (dix perles, 1,50 m de ruban)")
toucherRobe("Piece_corsage_v_devant_unique", "corsage_v_devant", "unique", 0.5, 0.4)
verifier(#decorations:GetChildren() == 0 and fenetre.Message.Visible, "toucher la robe sans décoration choisie : un message")
do -- Sous-projet 6 : pas de nœud de satin dans le kit : grisé, on ne peut pas le choisir
	local noeudVide = boutonNomme("Deco_noeud_satin")
	verifier(noeudVide:GetAttribute("Epuise") == true and noeudVide:GetAttribute("Ferme") == false and noeudVide.Text == "Nœud de satin · ×0", "nœud de satin épuisé : grisé, « ×0 »")
end
cliquer("Deco_noeud_satin")
verifier(fenetre.Message.Text == "Plus assez de Nœud de satin dans ta mercerie : achètes-en à la Mercerie." and boutonNomme("Deco_noeud_satin").BackgroundColor3 ~= ACCENT, "toucher un article épuisé : un message, rien n'est choisi")
do -- La mercerie, par-dessus le panneau, sans quitter la robe : deux nœuds de satin
	local argentAvant = argent()
	cliquer("OuvrirMercerie")
	local merc = contenuD:FindFirstChild("Mercerie")
	verifier(merc ~= nil and merc:IsA("TextButton") and merc.Text == "" and merc.ZIndex > 20, "« Mercerie » : la boutique par-dessus le panneau (un bouton sans texte, qui arrête les appuis)")
	verifier(merc.Casiers:FindFirstChild("Case_lanterne_papier") == nil and boutonNomme("Case_perle").Text == "Perle · ×10", "un casier par article ouvert, avec ce qu'on en a")
	cliquer("AcheterMercerie")
	verifier(fenetre.Message.Text == "Choisis d'abord un article." and argent() == argentAvant, "« Acheter » sans article : rien")
	cliquer("Case_noeud_satin")
	verifier(merc.Fiche.Article.Text == "Nœud de satin — 3 po l'unité" and merc.Fiche.Styles.Text == "Mignon +4, Romantique +2" and merc.Fiche.Quantite.Text == "×1" and boutonNomme("AcheterMercerie").Text == "Acheter (3 po)", "la fiche du nœud : son prix, ses styles, la quantité")
	cliquer("QuantitePlus")
	verifier(merc.Fiche.Quantite.Text == "×2" and boutonNomme("AcheterMercerie").Text == "Acheter (6 po)", "+ : deux nœuds, 6 po")
	cliquer("AcheterMercerie")
	verifier(argent() == argentAvant - 6 and serveur:atelier(joueur).etat.mercerie.noeud_satin == 2 and boutonNomme("Case_noeud_satin").Text == "Nœud de satin · ×2" and fenetre.Message.Text == "Acheté : Nœud de satin, ×2 (6 po).", "acheté : 6 po, deux nœuds dans la mercerie")
	verifier(M.sonsJoues[#M.sonsJoues] == "Atelier_achat", "l'achat fait sonner la caisse")
	verifier(boutonNomme("Deco_noeud_satin").Text == "Nœud de satin · ×2" and boutonNomme("Deco_noeud_satin"):GetAttribute("Epuise") == false, "la palette suit l'achat")
	verifierTailles("mercerie")
	cliquer("FermerMercerie")
	verifier(contenuD:FindFirstChild("Mercerie") == nil and titre() == "6. Décorations", "la mercerie se referme : on est toujours aux décorations")
end
cliquer("Deco_noeud_satin")
verifier(boutonNomme("Deco_noeud_satin").BackgroundColor3 == ACCENT and contenuD.Usage.Text == "Nœud de satin : 0 / 2", "nœud de satin choisi : aucun posé, deux dans la mercerie")
toucherRobe("Piece_corsage_v_devant_unique", "corsage_v_devant", "unique", 0.5, 0.4)
verifier(#decorations:GetChildren() == 1 and contenuD.Usage.Text == "Nœud de satin : 1 / 2" and boutonNomme("Deco_noeud_satin").Text == "Nœud de satin · ×1", "nœud posé sur le corsage : un sur deux, il en reste un")
```

Dans `tests/scenario.luau`, remplacer :

```lua
verifier(contenuD.Cout.Text == "Coût : 3 po", "tourner ou agrandir ne coûte rien")
```

par :

```lua
verifier(contenuD.Usage.Text == "Nœud de satin : 1 / 2", "tourner ou agrandir ne prend rien de plus")
```

Dans `tests/scenario.luau`, remplacer :

```lua
local coutRuban = tonumber(contenuD.Cout.Text:match("(%d+) po"))
verifier(#decorations:GetChildren() == 2 and coutRuban and coutRuban > 3, "ruban posé le long de la jupe : " .. contenuD.Cout.Text)
```

par :

```lua
local cmRuban = tonumber(((contenuD.Usage.Text:match("^Ruban rose : (%d,%d%d) / 1,50 m$") or ""):gsub(",", ""))) -- (cm)
verifier(#decorations:GetChildren() == 2 and cmRuban and cmRuban > 0 and boutonNomme("Deco_ruban_rose").Text == ("Ruban rose · %s m"):format(requireModule(scriptClient.Mercerie).metres(150 - (cmRuban or 0))), "ruban posé le long de la jupe, pris sur le mètre et demi du kit : " .. contenuD.Usage.Text)
```

Dans `tests/scenario.luau`, remplacer :

```lua
verifier(#decorations:GetChildren() == 1 and contenuD.Cout.Text == ("Coût : %d po"):format(coutRuban - 3), "nœud touché puis supprimé")
cliquer("Annuler")
verifier(#decorations:GetChildren() == 2 and contenuD.Cout.Text == ("Coût : %d po"):format(coutRuban), "annuler : le nœud revient")
```

par :

```lua
verifier(#decorations:GetChildren() == 1 and boutonNomme("Deco_noeud_satin").Text == "Nœud de satin · ×2", "nœud touché puis supprimé : il est de nouveau à poser")
cliquer("Annuler")
verifier(#decorations:GetChildren() == 2 and boutonNomme("Deco_noeud_satin").Text == "Nœud de satin · ×1", "annuler : le nœud revient")
```

Dans `tests/scenario.luau`, remplacer :

```lua
local avantDeco = argent()
serveur:atelier(joueur).etat.mercerie.noeud_satin = 1 -- (sous-projet 6 : le nœud, à la mercerie ; le ruban vient du kit)
local rubanAvant = serveur:atelier(joueur).etat.mercerie.ruban_rose
cliquer("Presenter")
verifier(titre() == "7. Photo et livraison" and argent() == avantDeco and serveur:atelier(joueur).etat.mercerie.noeud_satin == nil and serveur:atelier(joueur).etat.mercerie.ruban_rose < rubanAvant, "présenter : décorations prises à la mercerie, pas d'argent")
```

par :

```lua
local avantDeco = argent()
cliquer("Presenter")
verifier(titre() == "7. Photo et livraison" and argent() == avantDeco and serveur:atelier(joueur).etat.mercerie.noeud_satin == 1 and serveur:atelier(joueur).etat.mercerie.ruban_rose == 150 - cmRuban, "présenter : décorations prises à la mercerie (un nœud, le ruban), pas d'argent")
```

Dans `tests/scenario.luau`, remplacer :

```lua
verifier(titre() == "6. Décorations" and #decorations:GetChildren() == 2 and contenuD.Cout.Text == "Coût : 0 po", "retour aux décorations : déjà payées")
```

par :

```lua
verifier(titre() == "6. Décorations" and #decorations:GetChildren() == 2 and boutonNomme("Deco_noeud_satin").Text == "Nœud de satin · ×1" and contenuD.Usage.Text == "Mercerie : choisis une décoration.", "retour aux décorations : les décorations posées restent, la mercerie aussi")
```

Dans `tests/scenario.luau`, remplacer :

```lua
verifier(titre() == "6. Décorations", "retouche : retour aux décorations")
serveur:atelier(joueur).etat.mercerie.croix_argent = 1 -- (sous-projet 6 : la croix, à la mercerie)
cliquer("Deco_croix_argent")
```

par :

```lua
verifier(titre() == "6. Décorations", "retouche : retour aux décorations")
-- La croix d'argent manque : on l'achète à la mercerie, sans quitter la robe
cliquer("OuvrirMercerie")
cliquer("Case_croix_argent")
cliquer("AcheterMercerie")
verifier(serveur:atelier(joueur).etat.mercerie.croix_argent == 1 and #decorations:GetChildren() == 2, "une croix d'argent achetée depuis les décorations, la robe telle quelle")
cliquer("FermerMercerie")
cliquer("Deco_croix_argent")
```

Dans `tests/scenario.luau`, remplacer :

```lua
verifier(laCliente.Parent == nil and not gui.Atelier.Dialogue.Visible, "puis elle s'en va, et l'encadré se vide")
```

par :

```lua
verifier(laCliente.Parent == nil and not gui.Atelier.Dialogue.Visible, "puis elle s'en va, et l'encadré se vide")
do -- Sous-projet 6 : la mercerie, depuis l'accueil (à droite de la réputation) ; E ne sonne pas tant qu'elle est ouverte
	local bouton, prestige = boutonNomme("OuvrirMercerie"), fenetre.Contenu.Prestige
	verifier(bouton.Position.X.Offset >= prestige.Position.X.Offset + prestige.Size.X.Offset and bouton.Position.Y.Offset == prestige.Position.Y.Offset, "« Mercerie » à droite de la réputation")
	cliquer("OuvrirMercerie")
	verifier(fenetre.Contenu:FindFirstChild("Mercerie") ~= nil, "la mercerie s'ouvre par-dessus l'accueil")
	M.services.UserInputService.InputBegan:Fire({ KeyCode = Enum.KeyCode.E, UserInputType = Enum.UserInputType.Keyboard }, false)
	verifier(titre() == "Aiguille & Dentelle", "E ne sonne pas la clochette tant que la mercerie est ouverte")
	cliquer("Case_ruban_rose")
	verifier(fenetre.Contenu.Mercerie.Fiche.Quantite.Text == "1 × 50 cm" and fenetre.Contenu.Mercerie.Fiche.Styles.Text == "Mignon +3 (pour 50 cm)" and boutonNomme("AcheterMercerie").Text == "Acheter (5 po)", "le ruban se vend par 50 cm : 5 po, ses styles pour 50 cm")
	local avant, ruban = argent(), serveur:atelier(joueur).etat.mercerie.ruban_rose
	cliquer("AcheterMercerie")
	verifier(argent() == avant - 5 and serveur:atelier(joueur).etat.mercerie.ruban_rose == ruban + 50 and boutonNomme("Case_ruban_rose").Text == ("Ruban rose · %s m"):format(requireModule(scriptClient.Mercerie).metres(ruban + 50)), "50 cm de ruban achetés à l'accueil")
	cliquer("FermerMercerie")
	verifier(fenetre.Contenu:FindFirstChild("Mercerie") == nil, "la mercerie se referme")
end
```

- [ ] **Step 2: Lancer les tests, vérifier l'échec**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT|attempt|membre" | head -3`
Expected: échec : une ligne qui finit par `Mercerie n'est pas un membre valide de Folder « Couture »`

- [ ] **Step 3: La boutique**

Créer `src/client/Atelier/Mercerie.luau` :

```lua
-- Mercerie (sous-projet 6) : la boutique de la mercerie, par-dessus l'écran (depuis l'accueil ou les décorations,
-- sans quitter la robe en cours). Un casier par décoration ouverte, avec ce qu'on en a ; la fiche de l'article
-- choisi (son prix, ses styles, la quantité − / +) et « Acheter ». Un bouton sans texte, pas un cadre : les appuis
-- ne passent pas aux boutons dessous.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Couture = ReplicatedStorage:WaitForChild("Couture")
local Catalogue = require(Couture:WaitForChild("Catalogue"))
local Deblocages = require(Couture:WaitForChild("Deblocages"))
local EtatAtelier = require(Couture:WaitForChild("EtatAtelier"))

local Mercerie = {}

-- Des cm en mètres, à la française : 150 → « 1,50 »
function Mercerie.metres(cm)
	return (("%.2f"):format(cm / 100):gsub("%.", ","))
end

-- Une quantité d'un article, en clair : « ×12 » (un objet, à l'unité) ou « 1,50 m » (une garniture, en cm)
function Mercerie.stock(id, quantite)
	if Catalogue.accessoire(id).genre == "garniture" then
		return Mercerie.metres(quantite or 0) .. " m"
	end
	return ("×%d"):format(quantite or 0)
end

-- Ouvre la mercerie dans ctx.contenu ; auChangement() est appelé après chaque achat. Renvoie le panneau
function Mercerie.ouvrir(ctx, auChangement)
	local UiKit, session = ctx.UiKit, ctx.session
	local C = UiKit.COULEURS
	local ancien = ctx.contenu:FindFirstChild("Mercerie")
	if ancien then
		ancien:Destroy()
	end
	local panneau = UiKit.arrondir(UiKit.creer("TextButton", { Name = "Mercerie", Text = "", AutoButtonColor = false, BackgroundColor3 = Color3.fromRGB(255, 248, 238), Size = UDim2.fromScale(1, 1), ZIndex = 30, Parent = ctx.contenu }), 10)
	UiKit.creer("UIStroke", { Color = C.accent, Thickness = 2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = panneau })
	UiKit.texte({ Name = "TitreMercerie", Text = "Mercerie", Font = Enum.Font.GothamBold, TextSize = 20, Position = UDim2.fromOffset(10, 6), Size = UDim2.new(1, -130, 0, 28), ZIndex = 31, Parent = panneau })
	UiKit.boutonDoux({ Name = "FermerMercerie", Text = "Fermer", TextSize = 14, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -8, 0, 6), Size = UDim2.fromOffset(100, 30), ZIndex = 31, Parent = panneau }, function()
		panneau:Destroy()
	end)
	-- Les casiers : les décorations ouvertes, sur deux colonnes, qui défilent
	local ouverts = {}
	for _, a in ipairs(Catalogue.Accessoires) do
		if Deblocages.ouvert(session.etat, "accessoires", a.id) then
			table.insert(ouverts, a)
		end
	end
	local HAUT_CASE = 36
	local casiers = UiKit.creer("ScrollingFrame", { Name = "Casiers", BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 6, ScrollBarImageColor3 = C.accent, Position = UDim2.fromOffset(8, 42), Size = UDim2.new(1, -16, 1, -184), CanvasSize = UDim2.fromOffset(0, math.ceil(#ouverts / 2) * (HAUT_CASE + 4)), ZIndex = 31, Parent = panneau })
	-- La fiche de l'article choisi, en bas, sous un trait : son nom et son prix, ses styles, la quantité
	UiKit.creer("Frame", { Name = "Trait", BackgroundColor3 = C.accent, BackgroundTransparency = 0.5, BorderSizePixel = 0, Position = UDim2.new(0, 8, 1, -140), Size = UDim2.new(1, -16, 0, 2), ZIndex = 31, Parent = panneau })
	local fiche = UiKit.creer("Frame", { Name = "Fiche", BackgroundTransparency = 1, AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 8, 1, -8), Size = UDim2.new(1, -16, 0, 126), ZIndex = 31, Parent = panneau })
	local article = UiKit.texte({ Name = "Article", Text = "Choisis un article.", Font = Enum.Font.GothamBold, TextSize = 14, Size = UDim2.new(1, 0, 0, 20), ZIndex = 32, Parent = fiche })
	local stylesTexte = UiKit.texte({ Name = "Styles", TextSize = 14, TextColor3 = C.texteDoux, Position = UDim2.fromOffset(0, 20), Size = UDim2.new(1, 0, 0, 20), ZIndex = 32, Parent = fiche })
	local quantiteTexte = UiKit.texte({ Name = "Quantite", Font = Enum.Font.GothamBold, TextSize = 16, TextXAlignment = Enum.TextXAlignment.Center, Position = UDim2.fromOffset(52, 46), Size = UDim2.fromOffset(110, 34), ZIndex = 32, Parent = fiche })
	local choisi, quantite = nil, 1
	local cases, acheter = {}, nil
	local function majFiche()
		for id, b in pairs(cases) do
			b.Text = Catalogue.accessoire(id).nom .. " · " .. Mercerie.stock(id, session.etat.mercerie[id])
			b.BackgroundColor3 = if id == choisi then C.accent else C.secondaire
			b.TextColor3 = if id == choisi then Color3.new(1, 1, 1) else C.texte
		end
		if not choisi then
			quantiteTexte.Text = ""
			acheter.Text = "Acheter"
			return
		end
		local a = Catalogue.accessoire(choisi)
		local styles = {}
		for _, s in ipairs(Catalogue.STYLES) do
			if a.style[s] then
				table.insert(styles, ("%s +%d"):format(Catalogue.NOMS_STYLES[s], a.style[s]))
			end
		end
		local garniture = a.genre == "garniture"
		article.Text = ("%s — %s"):format(a.nom, if garniture then ("%d po les 50 cm"):format(a.prix * 5) else ("%d po l'unité"):format(a.prix))
		-- (les points de style d'une garniture sont comptés pour 50 cm, au prorata)
		stylesTexte.Text = table.concat(styles, ", ") .. (if garniture then " (pour 50 cm)" else "")
		quantiteTexte.Text = if garniture then ("%d × 50 cm"):format(quantite) else ("×%d"):format(quantite)
		acheter.Text = ("Acheter (%d po)"):format(if garniture then a.prix * 5 * quantite else a.prix * quantite)
	end
	for k, a in ipairs(ouverts) do
		cases[a.id] = UiKit.boutonDoux({ Name = "Case_" .. a.id, TextSize = 14, TextWrapped = true, Position = UDim2.new(((k - 1) % 2) * 0.5, 0, 0, ((k - 1) // 2) * (HAUT_CASE + 4)), Size = UDim2.new(0.5, -8, 0, HAUT_CASE), ZIndex = 32, Parent = casiers }, function()
			choisi, quantite = a.id, 1
			majFiche()
		end)
	end
	UiKit.boutonDoux({ Name = "QuantiteMoins", Text = "−", TextSize = 20, Position = UDim2.fromOffset(0, 46), Size = UDim2.fromOffset(44, 34), ZIndex = 32, Parent = fiche }, function()
		quantite = math.max(1, quantite - 1)
		majFiche()
	end)
	UiKit.boutonDoux({ Name = "QuantitePlus", Text = "+", TextSize = 20, Position = UDim2.fromOffset(170, 46), Size = UDim2.fromOffset(44, 34), ZIndex = 32, Parent = fiche }, function()
		quantite = math.min(EtatAtelier.ACHAT_MERCERIE_MAX, quantite + 1)
		majFiche()
	end)
	acheter = UiKit.bouton({ Name = "AcheterMercerie", Text = "Acheter", TextSize = 16, Position = UDim2.fromOffset(0, 88), Size = UDim2.new(1, 0, 0, 36), ZIndex = 32, Parent = fiche }, function()
		if not choisi then
			ctx.message("Choisis d'abord un article.", C.texteDoux)
			return
		end
		local r = session:acheterMercerie(choisi, quantite)
		if not r.ok then
			ctx.refus(r)
			return
		end
		ctx.message(("Acheté : %s, %s (%d po)."):format(Catalogue.accessoire(choisi).nom, Mercerie.stock(choisi, r.quantite), r.prix), C.ok)
		majFiche()
		if auChangement then
			auChangement()
		end
	end, 0.4)
	majFiche()
	return panneau
end

return Mercerie
```

- [ ] **Step 4: L'éditeur, la palette, l'accueil, le carnet, la session**

Dans `src/client/Atelier/Decorateur.luau`, remplacer :

```lua
-- par point (une seule pièce, 64 points au plus), sélection, rotation, taille, suppression, annulation,
-- et le coût à payer (différence avec ce qui est déjà payé, calculée comme EtatAtelier la facturera).
```

par :

```lua
-- par point (une seule pièce, 64 points au plus), sélection, rotation, taille, suppression, annulation.
-- Sous-projet 6 : les décorations se prennent à la mercerie ; on ne pose pas plus que ce qu'on a (le stock, plus ce que
-- la robe a déjà pris), compté comme EtatAtelier le prendra.
```

Dans `src/client/Atelier/Decorateur.luau`, remplacer :

```lua
-- recette : recette de la robe (etat:recette()), avec les décorations déjà posées ;
-- payees : décorations déjà facturées (etat.accessoires)
function Decorateur.nouveau(recette, payees)
	return setmetatable({
		recette = recette,
		payees = copier(payees),
```

par :

```lua
-- recette : recette de la robe (etat:recette()), avec les décorations déjà posées ;
-- prises : décorations déjà prises à la mercerie (etat.accessoires) ; stock : la mercerie (etat.mercerie)
function Decorateur.nouveau(recette, prises, stock)
	return setmetatable({
		recette = recette,
		prises = copier(prises),
		stock = table.clone(stock),
```

Dans `src/client/Atelier/Decorateur.luau`, remplacer :

```lua
local function memoriser(self)
	table.insert(self.historique, copier(self.liste))
end
```

par :

```lua
local function memoriser(self)
	table.insert(self.historique, copier(self.liste))
end

-- La mercerie a changé (un achat) : le nouveau stock
function Decorateur:majStock(stock)
	self.stock = table.clone(stock)
end

-- Ce qu'une liste de décorations prend d'un article (unités, ou cm pour une garniture)
local function besoin(self, liste, id)
	return EtatAtelier.besoinsMercerie(self.recette.pieces, liste)[id] or 0
end

-- Un article pour cette robe : ce que les décorations posées en prennent, et ce qu'on en a (le stock, plus ce que la
-- robe a déjà pris). Une garniture en cours compte dès qu'elle compte pour la robe (deux points, 0,5 dm)
function Decorateur:usage(id)
	return besoin(self, self:resultat(), id), (self.stock[id] or 0) + besoin(self, self.prises, id)
end

-- Ce qu'il reste d'un article à poser
function Decorateur:reste(id)
	local pris, dispo = self:usage(id)
	return dispo - pris
end

-- Plus rien à poser : plus d'unité d'un objet, moins de 0,5 dm d'une garniture
function Decorateur:epuise(id)
	local def = Catalogue.accessoire(id)
	return self:reste(id) < (if def.genre == "garniture" then math.ceil(Recette.LONGUEUR_MIN_GARNITURE * 10 - 1e-9) else 1)
end

local function manque(def)
	return { ok = false, erreur = ("Plus assez de %s dans ta mercerie : achètes-en à la Mercerie."):format(def.nom) }
end
```

Dans `src/client/Atelier/Decorateur.luau`, remplacer :

```lua
	local copieGardee = copie ~= Patron.copies(p.id)[1] and copie or nil
	local def = Catalogue.accessoire(self.choix)
	if def.genre == "objet" then
		memoriser(self)
```

par :

```lua
	local copieGardee = copie ~= Patron.copies(p.id)[1] and copie or nil
	local def = Catalogue.accessoire(self.choix)
	if def.genre == "objet" then
		if self:epuise(def.id) then
			return manque(def)
		end
		memoriser(self)
```

Dans `src/client/Atelier/Decorateur.luau`, remplacer :

```lua
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
```

par :

```lua
	local g = self.garniture
	if not g then
		if self:epuise(def.id) then
			return manque(def)
		end
		self.garniture = { id = self.choix, piece = indicePiece, copie = copieGardee, trajet = { { u = u, v = v } } }
		return { ok = true, action = "point" }
	end
	if g.piece ~= indicePiece or g.copie ~= copieGardee then
		return { ok = false, erreur = "Une garniture reste sur une seule pièce." }
	end
	if #g.trajet >= Recette.MAX_POINTS_GARNITURE then
		return { ok = false, erreur = "Cette garniture a déjà 64 points." }
	end
	-- Un point de trop pour la mercerie : refusé (la garniture reste où elle en est)
	local essai = copier({ g })[1]
	table.insert(essai.trajet, { u = u, v = v })
	local liste = copier(self.liste)
	table.insert(liste, essai)
	if besoin(self, liste, g.id) > (self.stock[g.id] or 0) + besoin(self, self.prises, g.id) then
		return manque(def)
	end
	table.insert(g.trajet, { u = u, v = v })
	return { ok = true, action = "point" }
```

Dans `src/client/Atelier/Decorateur.luau`, supprimer (avec la ligne vide qui suit) :

```lua
-- Pièces d'or à payer (négatif : remboursement)
function Decorateur:cout()
	local pieces = self.recette.pieces
	return EtatAtelier.prixDecorations(pieces, complete(self)) - EtatAtelier.prixDecorations(pieces, self.payees)
end
```

Dans `src/client/Atelier/EcranDecorations.luau`, remplacer :

```lua
-- (Q/E), agrandir, supprimer, annuler ; garnitures point par point. Glisser sur la scène fait tourner la vue.
-- La logique est dans Decorateur ; « Présenter à la cliente » envoie la liste (EtatAtelier:decorer).
```

par :

```lua
-- (Q/E), agrandir, supprimer, annuler ; garnitures point par point. Glisser sur la scène fait tourner la vue.
-- La logique est dans Decorateur ; « Présenter à la cliente » envoie la liste (EtatAtelier:decorer).
-- Sous-projet 6 : la palette dit ce qu'il reste de chaque article dans la mercerie (grisé : épuisé) ; « Mercerie »,
-- en bas, ouvre la boutique par-dessus, sans quitter la robe.
```

Dans `src/client/Atelier/EcranDecorations.luau`, remplacer :

```lua
local Decorateur = require(script.Parent:WaitForChild("Decorateur"))
local Sons = require(script.Parent:WaitForChild("Sons"))
```

par :

```lua
local Decorateur = require(script.Parent:WaitForChild("Decorateur"))
local Mercerie = require(script.Parent:WaitForChild("Mercerie"))
local Sons = require(script.Parent:WaitForChild("Sons"))
```

Dans `src/client/Atelier/EcranDecorations.luau`, remplacer :

```lua
	local deco = Decorateur.nouveau(session.etat:recette(), session.etat.accessoires)
	local rafraichir

	local cout = UiKit.texte({ Name = "Cout", Font = Enum.Font.GothamBold, TextSize = 18, Size = UDim2.new(1, 0, 0, 24), Parent = contenu })
```

par :

```lua
	local deco = Decorateur.nouveau(session.etat:recette(), session.etat.accessoires, session.etat.mercerie)
	local rafraichir

	-- L'article choisi : ce que la robe en prend, sur ce qu'on en a (« Perle : 2 / 12 », « Ruban rose : 0,20 / 1,50 m »)
	local usage = UiKit.texte({ Name = "Usage", Font = Enum.Font.GothamBold, TextSize = 16, Size = UDim2.new(1, 0, 0, 24), Parent = contenu })
```

Dans `src/client/Atelier/EcranDecorations.luau`, remplacer :

```lua
	-- Palette : objets à l'unité, garnitures au dm. Les souvenirs des événements n'y sont qu'une fois ouverts (fermés,
	-- ils dévoileraient l'histoire)
```

par :

```lua
	-- Palette : ce qu'il reste de chaque article (objets à l'unité, garnitures en mètres). Les souvenirs des événements
	-- n'y sont qu'une fois ouverts (fermés, ils dévoileraient l'histoire)
```

Dans `src/client/Atelier/EcranDecorations.luau`, remplacer :

```lua
	for k, a in ipairs(visibles) do
		local prix = a.genre == "garniture" and ("%d po/dm"):format(a.prix) or ("%d po"):format(a.prix)
		-- fermé : ce qu'il faut pour l'ouvrir à la place du prix
		local detail = if Deblocages.ouvert(ctx.session.etat, "accessoires", a.id) then prix else Deblocages.raison("accessoires", a.id)
		boutons[a.id] = UiKit.boutonDoux({
			Name = "Deco_" .. a.id,
			Text = a.nom .. " · " .. detail,
			TextSize = 14,
```

par :

```lua
	for k, a in ipairs(visibles) do
		boutons[a.id] = UiKit.boutonDoux({
			Name = "Deco_" .. a.id,
			TextSize = 14,
```

Dans `src/client/Atelier/EcranDecorations.luau`, remplacer :

```lua
			if not Deblocages.ouvert(ctx.session.etat, "accessoires", a.id) then
				ctx.message(Deblocages.message("accessoires", a.id), C.texteDoux)
				return
			end
			deco:choisir(a.id)
			rafraichir()
```

par :

```lua
			if not Deblocages.ouvert(ctx.session.etat, "accessoires", a.id) then
				ctx.message(Deblocages.message("accessoires", a.id), C.texteDoux)
				return
			end
			if deco:epuise(a.id) then
				ctx.message(("Plus assez de %s dans ta mercerie : achètes-en à la Mercerie."):format(a.nom), C.texteDoux)
				return
			end
			deco:choisir(a.id)
			rafraichir()
```

Dans `src/client/Atelier/EcranDecorations.luau`, remplacer :

```lua
	UiKit.boutonConfirme({ Name = "Recommencer", Text = "Recommencer la robe", TextSize = 14, AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), Size = UDim2.fromOffset(200, 34), Parent = contenu }, function()
		local r = session:recommencer()
		if not r.ok then
			ctx.refus(r)
		end
	end)

	rafraichir = function()
		local n = deco:cout()
		cout.Text = n >= 0 and ("Coût : %d po"):format(n) or ("Remboursement : %d po"):format(-n)
		for id, b in pairs(boutons) do
			b.BackgroundColor3 = id == deco.choix and C.accent or C.secondaire
			b.TextColor3 = id == deco.choix and Color3.new(1, 1, 1) or C.texte
			UiKit.griser(b, not Deblocages.ouvert(ctx.session.etat, "accessoires", id))
		end
```

par :

```lua
	UiKit.boutonConfirme({ Name = "Recommencer", Text = "Recommencer la robe", TextSize = 14, AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), Size = UDim2.fromOffset(200, 34), Parent = contenu }, function()
		local r = session:recommencer()
		if not r.ok then
			ctx.refus(r)
		end
	end)
	-- La mercerie, par-dessus le panneau : un achat met la palette à jour, la robe reste telle quelle
	UiKit.boutonDoux({ Name = "OuvrirMercerie", Text = "Mercerie", TextSize = 14, AnchorPoint = Vector2.new(1, 1), Position = UDim2.fromScale(1, 1), Size = UDim2.fromOffset(124, 34), Parent = contenu }, function()
		Mercerie.ouvrir(ctx, function()
			deco:majStock(session.etat.mercerie)
			rafraichir()
		end)
	end)

	rafraichir = function()
		if deco.choix then
			local def = Catalogue.accessoire(deco.choix)
			local pris, dispo = deco:usage(deco.choix)
			usage.Text = if def.genre == "garniture"
				then ("%s : %s / %s m"):format(def.nom, Mercerie.metres(pris), Mercerie.metres(dispo))
				else ("%s : %d / %d"):format(def.nom, pris, dispo)
		else
			usage.Text = "Mercerie : choisis une décoration."
		end
		for id, b in pairs(boutons) do
			local ouvert = Deblocages.ouvert(ctx.session.etat, "accessoires", id)
			-- fermé : ce qu'il faut pour l'ouvrir à la place de ce qu'il en reste
			b.Text = Catalogue.accessoire(id).nom .. " · " .. (if ouvert then Mercerie.stock(id, deco:reste(id)) else Deblocages.raison("accessoires", id))
			b.BackgroundColor3 = id == deco.choix and C.accent or C.secondaire
			b.TextColor3 = id == deco.choix and Color3.new(1, 1, 1) or C.texte
			UiKit.griser(b, not ouvert)
			-- épuisé : grisé aussi (on en rachète à la mercerie)
			local epuise = ouvert and deco:epuise(id)
			b:SetAttribute("Epuise", epuise)
			if epuise then
				b.BackgroundColor3, b.TextColor3 = C.ferme, C.texteDoux
			end
		end
```

Dans `src/client/Atelier/EcranAccueil.luau`, remplacer :

```lua
	local fond = UiKit.arrondir(UiKit.creer("Frame", { Name = "JaugePrestige", BackgroundColor3 = C.secondaire, Position = UDim2.fromOffset(0, y + 26), Size = UDim2.fromOffset(360, 12), Parent = ctx.contenu }), 6)
```

par :

```lua
	local fond = UiKit.arrondir(UiKit.creer("Frame", { Name = "JaugePrestige", BackgroundColor3 = C.secondaire, Position = UDim2.fromOffset(0, y + 26), Size = UDim2.fromOffset(360, 12), Parent = ctx.contenu }), 6)
	-- (sous-projet 6) la mercerie, par-dessus l'accueil : on y fait ses réserves de décorations
	UiKit.boutonDoux({ Name = "OuvrirMercerie", Text = "Mercerie", Position = UDim2.fromOffset(620, y), Size = UDim2.fromOffset(200, 40), Parent = ctx.contenu }, function()
		Mercerie.ouvrir(ctx)
	end)
```

Dans `src/client/Atelier/EcranAccueil.luau`, remplacer :

```lua
		for _, nom in ipairs({ "Conversation", "Epilogue", "Suite", "CarnetAdresses", "Affiche" }) do
```

par :

```lua
		for _, nom in ipairs({ "Conversation", "Epilogue", "Suite", "CarnetAdresses", "Affiche", "Mercerie" }) do
```

Dans `src/client/Atelier/EcranAccueil.luau`, remplacer :

```lua
	-- conversation, épilogue, suite de l'histoire, carnet d'adresses, affiche des nouveautés) : sonner la clochette
```

par :

```lua
	-- conversation, épilogue, suite de l'histoire, carnet d'adresses, affiche des nouveautés, mercerie) : sonner la clochette
```

Dans `src/client/Atelier/EcranCarnet.luau`, remplacer :

```lua
	local lignesExigences = {}
	for i, e in ipairs(etat.commande.exigences) do
		lignesExigences[i] = UiKit.texte({ Name = "Exigence" .. i, TextSize = 14, Position = UDim2.fromOffset(12, 14 + i * 22), Size = UDim2.new(1, -24, 0, 20), Parent = droite })
	end
	local jauges = {}
	local y0 = 34 + #etat.commande.exigences * 22 + 12
```

par :

```lua
	local lignesExigences = {}
	local yExigence = 36
	for i, e in ipairs(etat.commande.exigences) do
		-- (une exigence d'accessoire dit aussi ce qu'on en a dans la mercerie, sur une seconde ligne)
		local haut = if e.type == "accessoire" then 40 else 20
		lignesExigences[i] = UiKit.texte({ Name = "Exigence" .. i, TextSize = 14, TextYAlignment = Enum.TextYAlignment.Top, Position = UDim2.fromOffset(12, yExigence), Size = UDim2.new(1, -24, 0, haut), Parent = droite })
		yExigence += haut + 2
	end
	local jauges = {}
	local y0 = yExigence + 10
```

Dans `src/client/Atelier/EcranCarnet.luau`, remplacer :

```lua
			if e.type == "qualite" and ajustement and ajustement < 1 then
				texte ..= (" (ajustement %d %%)"):format(math.floor(ajustement * 100 + 0.5))
			end
```

par :

```lua
			if e.type == "qualite" and ajustement and ajustement < 1 then
				texte ..= (" (ajustement %d %%)"):format(math.floor(ajustement * 100 + 0.5))
			elseif e.type == "accessoire" then
				local q = etat.mercerie[e.id] or 0
				texte ..= "\n      (en stock : " .. (if Catalogue.accessoire(e.id).genre == "garniture" then Mercerie.metres(q) .. " m" else tostring(q)) .. ")"
			end
```

Dans `src/client/Atelier/Session.luau`, remplacer :

```lua
function Session:acheter(idTissu, dm)
	return agir(self, "acheter", idTissu, dm)
end
```

par :

```lua
function Session:acheter(idTissu, dm)
	return agir(self, "acheter", idTissu, dm)
end
function Session:acheterMercerie(idAccessoire, quantite)
	return agir(self, "acheterMercerie", idAccessoire, quantite)
end
```

Dans `src/client/Atelier/init.client.luau`, remplacer :

```lua
local SONS_ACTIONS = { nouvelleCommande = "clochette", acheter = "achat", 
```

par :

```lua
local SONS_ACTIONS = { nouvelleCommande = "clochette", acheter = "achat", acheterMercerie = "achat", 
```

Dans `src/client/Atelier/EcranAccueil.luau`, remplacer :

```lua
local Vignettes = require(script.Parent:WaitForChild("Vignettes"))
```

par :

```lua
local Vignettes = require(script.Parent:WaitForChild("Vignettes"))
local Mercerie = require(script.Parent:WaitForChild("Mercerie"))
```

Dans `src/client/Atelier/EcranCarnet.luau`, remplacer :

```lua
local Vignettes = require(script.Parent:WaitForChild("Vignettes"))
```

par :

```lua
local Vignettes = require(script.Parent:WaitForChild("Vignettes"))
local Mercerie = require(script.Parent:WaitForChild("Mercerie"))
```

- [ ] **Step 5: Lancer les tests**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT"`
Expected:
```
Unitaires : 167912 vérifications
TOUT EST VERT : 922 vérifications
```

- [ ] **Step 6: Commit**

```bash
git add src/client/Atelier/Mercerie.luau src/client/Atelier/Decorateur.luau src/client/Atelier/EcranDecorations.luau src/client/Atelier/EcranAccueil.luau src/client/Atelier/EcranCarnet.luau src/client/Atelier/Session.luau src/client/Atelier/init.client.luau tests/unitaires/22_decorateur.luau tests/scenario.luau
git commit -m "La Mercerie à l'écran : depuis l'accueil et les décorations ; la palette dit ce qu'il reste, le carnet ce qu'on a

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

Construire le lieu du dépôt dans un dossier temporaire (`C:/dev/jeux/roblox-maker/rojo.exe build -o <dossier temporaire>/Plan16Depot.rbxl`) et l'ouvrir dans Studio. En Play : attendre 4 s ; capturer l'accueil (« Mercerie » à droite de la réputation) ; cliquer « Mercerie » par `user_mouse_input` (`instance_path`), capturer la boutique, choisir un casier, « + », « Acheter », relever l'argent ; fermer ; relever la console.

Expected : la boutique par-dessus l'accueil (casiers sur deux colonnes, fiche sous un trait), l'argent baisse du prix affiché, le casier montre le nouveau stock ; aucune alerte de notre code (« Lieu non publié » et les messages internes de Roblox mis à part). Arrêter Play et fermer cette fenêtre de Studio (sans enregistrer).

- [ ] **Step 2: Mettre à jour le README**

Dans `README.md`, remplacer :

```markdown
## État actuel (sous-projet 6 en cours, plan 15 : les mesures à molettes)
```

par :

```markdown
## État actuel (sous-projet 6 en cours, plans 15 et 16 : les mesures à molettes, la mercerie)
```

Dans `README.md`, remplacer :

```markdown
   se pose point par point sur une pièce. Glisser sur la scène fait tourner la vue autour du mannequin.
   Le coût s'affiche en direct ; ce qu'on retire est remboursé.
```

par :

```markdown
   se pose point par point sur une pièce. Glisser sur la scène fait tourner la vue autour du mannequin.
   **La mercerie** : les décorations s'achètent d'avance, en stock (à l'unité, les garnitures par 50 cm), dans
   la **Mercerie** qu'on ouvre depuis l'accueil ou depuis les décorations, sans quitter la robe ; toute partie
   commence avec un kit (boutons, perles, fleurs, 1,50 m de ruban rose). La palette dit ce qu'il reste de chaque
   article (« Perle · ×12 », « Ruban rose · 1,50 m ») et grise ce qui est épuisé ; l'article choisi montre ce que
   la robe en prend (« Ruban rose : 0,20 / 1,50 m »). Poser prend au stock, retirer y rend ; au carnet, une
   exigence d'accessoire dit ce qu'on en a. Chaque événement qui a lieu offre cinq exemplaires de son souvenir.
```

Dans `README.md`, remplacer :

```markdown
   (mesures à molettes, compteur de mètres, mercerie en stock, robes plus riches) : à décider.
```

par :

```markdown
   (compteur de mètres, robes plus riches) : à décider.
```

Dans `README.md`, remplacer :

```markdown
  l'ancienne clé `AtelierCouture_v1` ; partie v3 depuis le plan 5a : prestige, fiches des clientes) : lue à l'arrivée, écrite toutes les 60 s, au départ et à l'arrêt du
```

par :

```markdown
  l'ancienne clé `AtelierCouture_v1` ; partie v3 depuis le plan 5a : prestige, fiches des clientes ; v4 depuis
  le plan 16 : la mercerie, et un kit de départ offert aux parties existantes) : lue à l'arrivée, écrite toutes les 60 s, au départ et à l'arrêt du
```

Dans `README.md`, remplacer :

```markdown
un module `Ecran…` par étape (`EcranMesures` : le mannequin à molettes, `Molette` : le réglage d'une
  molette).
```

par :

```markdown
un module `Ecran…` par étape (`EcranMesures` : le mannequin à molettes, `Molette` : le réglage d'une
  molette) ; `Mercerie` : la boutique de la mercerie, par-dessus l'accueil ou les décorations.
```

- [ ] **Step 3: Tests, lieu régénéré, commit**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT"`
Expected:
```
Unitaires : 167912 vérifications
TOUT EST VERT : 922 vérifications
```

```bash
C:/dev/jeux/roblox-maker/rojo.exe build -o AtelierCouture.rbxl
git add README.md AtelierCouture.rbxl
git commit -m "Plan 16 terminé : la mercerie

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```
