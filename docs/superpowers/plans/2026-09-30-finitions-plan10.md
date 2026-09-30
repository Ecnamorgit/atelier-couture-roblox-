# Aiguille & Dentelle — Plan 10 : finitions générales

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Traiter des points mineurs reportés qui se voient en jeu : des jauges du carnet qui ne promettent que ce que les tissus ouverts peuvent donner, quatre petites incohérences du récit, une jupe crayon de nouveau bien resserrée (avec un vrai modèle des jambes), une annonce de l'accueil qui laisse toujours la place au courrier, et les derniers points de la relecture du plan 9.

**Architecture:** aucune notion nouvelle : `Notation.fourchette` prend en option les tissus ouverts (le carnet les lui donne), `UiKit.mesureAnnonce` choisit la taille et la hauteur de l'annonce, des textes de `Histoire` et une valeur de `Catalogue` sont retouchés.

**Tech Stack:** Luau, Rojo 7.7.0-rc.1, simulation Luau 0.650 (`tests/lancer.sh`), Roblox Studio via le connecteur MCP Studio.

**Spec:** les specs des sous-projets 2 à 4 (`docs/superpowers/specs/2026-09-29-clientes-progression-design.md`, `…2026-09-30-histoire-evenements-design.md`, `…2026-09-30-ampleur-contenu-design.md`) ; ce plan ne change aucune règle. Les points viennent des registres des plans 5b (fourchette), 6 (récit) et 9 (« minor (deferred) »).

## Décisions de ce plan

- **Retenus** : fourchette du carnet calculée avec les tissus fermés (plan 5b) ; au bal des lanternes, Margot qui danse alors qu'elle tient la limonade, « le bateau de Colette » (on l'y emmène), les flocons « dans la grande salle », « tout le monde » deux fois dans une réplique de Margot (plan 6) ; et du plan 9 : jupe crayon desserrée à cause d'un test qui voyait les jambes comme un seul cercle, annonce de six lignes qui pousse le troisième « Inviter » hors de la fenêtre, test 46 qui ne vérifiait plus la réalisabilité, recherche de « lac » (vraie aussi pour « place »), valeurs recopiées (8,8 dans `Patron`, `UiKit.LARGEUR - 40` dans l'accueil), papillon absent du README.
- **Laissés** : « +0 » d'amitié et message d'abandon (le scénario n'abandonne pas de commande) ; bulle de la première visite d'une cliente d'histoire ; conditions de déblocage en double à la construction (le test 45 compte les sources) ; `UiKit.lignes` non mesurée dans Studio (estimation prudente).
- **Fourchette** : les pièces sans tissu ne comptent que les tissus ouverts ; au départ, la jauge « élégant » d'une robe droite s'arrête à ce que cotons, lins et jute peuvent donner.
- **Jupe crayon** : les jambes du test deviennent deux cylindres de 0,6 dm à ±0,55 dm (ce que le commentaire du test décrivait) ; l'évasement revient à −0,04 : l'ourlet reste hors des jambes pour toutes les silhouettes, et se resserre de nouveau de plus de 0,1 dm en taille M.
- **Annonce** : 18 px tant qu'elle tient en quatre lignes, sinon 14 px (lignes de 19 px) : au pire (six lignes à 18 px), elle ne fait plus que cinq lignes de 14 px, 97 px au lieu de 146.
- **Vérifié pendant la préparation** : le plan a été joué entièrement sur un brouillon tiré de `main` ; sept variantes du brouillon (fourchette avec tous les tissus, carnet sans les tissus ouverts, Margot qui danse, flocons dans la salle, jupe crayon à −0,025, annonce toujours en 18 px, tirage sans contrôle de réalisabilité) échouent chacune sur la vérification qui les garde.

## Global Constraints

- **Dépôt** : `C:\dev\jeux\atelier-couture`, branche `finitions-generales`, créée depuis `main` (où le plan 9 est fusionné). Selon les règles du commanditaire : la branche testée et relue est fusionnée dans `main` et poussée sur GitHub.
- **Rojo** : `C:/dev/jeux/roblox-maker/rojo.exe`.
- **Contraintes des plans précédents toujours valables** : fins de ligne LF, commits en français terminés par `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`, textes d'au moins 14 px, le serveur fait foi.

## Review Focus

- **Carnet d'une couturière débutante.** Attendu : aucune jauge ne dépasse ce que les tissus ouverts peuvent donner. Tests : `05_notation` et scénario, « au départ, la jauge « élégant » s'arrête à ce que les tissus ouverts peuvent donner ».
- **Annonce très longue (niveau de prestige, niveau d'amitié, lettre).** Attendu : 14 px, jamais plus de quatre lignes de 18 px. Test : `55_annonces`, « annonce au pire cas ».
- **Jupe crayon, hanches de 8 à 14 dm.** Attendu : hors des jambes, bien resserrée. Tests : `03_patron`.
- **Récit relu d'un bout à l'autre.** Attendu : pas de contradiction entre épilogues et répliques. Test : `52_histoire`, « le récit tient debout ».
- **Tirage aux prestiges 6 à 8.** Attendu : de vraies commandes, réalisables, sans repli. Test : `46_deblocages_etat`.

---

### Task 1: Des jauges qui ne promettent que les tissus ouverts

**Files:**
- Modify: `src/shared/Notation.luau` (`fourchette`), `src/client/Atelier/EcranCarnet.luau`
- Modify: `tests/unitaires/05_notation.luau`, `tests/scenario.luau`

**Interfaces:**
- Consumes: `Deblocages.ouverts(progres).tissus`.
- Produces: `Notation.fourchette(croquis, choix, accessoires?, tissusOuverts?)`.

- [ ] **Step 1: Écrire les tests**

Dans `tests/unitaires/05_notation.luau`, remplacer :

```lua
U.verifier(U.proche(f2.decontracte.min, 29) and U.proche(f2.decontracte.max, 29), "tous les tissus choisis : fourchette réduite au score")
```

par :

```lua
U.verifier(U.proche(f2.decontracte.min, 29) and U.proche(f2.decontracte.max, 29), "tous les tissus choisis : fourchette réduite au score")
-- Avec les tissus ouverts seulement (une couturière débutante) : la fourchette ne promet pas ce que seuls les
-- tissus fermés donneraient
local ouvertsDepart = U.module("Deblocages").ouverts({ prestige = 0, clientes = {} }).tissus
local fOuverts = Notation.fourchette(croquis, {}, nil, ouvertsDepart)
U.verifier(fOuverts.elegant.max < f.elegant.max and fOuverts.elegant.min >= f.elegant.min, ("tissus ouverts seulement : la fourchette se resserre (élégant au plus %g au lieu de %g)"):format(fOuverts.elegant.max, f.elegant.max))
```

Dans `tests/scenario.luau`, remplacer :

```lua
cliquer("FermerChoix")
-- Pour la suite, une couturière confirmée : tout le catalogue ouvert (prestige et amitiés au plus haut)
```

par :

```lua
cliquer("FermerChoix")
do -- Au départ, les jauges du carnet ne promettent que ce que les tissus ouverts peuvent donner
	local Notation = requireModule(dossier.Notation)
	local etatC = requireModule(scriptClient.Session).courante.etat
	local croquisDepart = { corsage = "corsage_droit", manches = "manches_sans", col = "col_sans", jupe = "jupe_droite" }
	local imposes = Notation.accessoiresImposes(etatC.commande.exigences)
	local fTous = Notation.fourchette(croquisDepart, {}, imposes)
	local fOuverts = Notation.fourchette(croquisDepart, {}, imposes, requireModule(dossier.Deblocages).ouverts(etatC).tissus)
	local plage = fenetre.Contenu.Droite.Jauge_elegant.Plage.Size.X.Scale
	verifier(fOuverts.elegant.max < fTous.elegant.max and math.abs(plage - fOuverts.elegant.max / 100) < 1e-9, "au départ, la jauge « élégant » s'arrête à ce que les tissus ouverts peuvent donner")
end
-- Pour la suite, une couturière confirmée : tout le catalogue ouvert (prestige et amitiés au plus haut)
```

- [ ] **Step 2: Lancer les tests, vérifier l'échec**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT|attempt|membre" | head -3`
Expected: échec : une ligne qui finit par `ÉCHEC : tissus ouverts seulement : la fourchette se resserre (élégant au plus 44 au lieu de 44)`

- [ ] **Step 3: Écrire le code**

Dans `src/shared/Notation.luau`, remplacer :

```lua
function Notation.fourchette(croquis, choix, accessoires)
```

par :

```lua
-- tissusOuverts (facultatif, { [idTissu] = true }, voir Deblocages.ouverts) : les pièces sans tissu ne comptent que
-- les tissus ouverts, la fourchette ne promet rien de plus.
function Notation.fourchette(croquis, choix, accessoires, tissusOuverts)
```

Dans `src/shared/Notation.luau`, remplacer :

```lua
		local mini, maxi = math.huge, -math.huge
		for _, t in ipairs(Catalogue.Tissus) do
			mini, maxi = math.min(mini, t.style[s] or 0), math.max(maxi, t.style[s] or 0)
		end
```

par :

```lua
		local mini, maxi = math.huge, -math.huge
		for _, t in ipairs(Catalogue.Tissus) do
			if not tissusOuverts or tissusOuverts[t.id] then
				mini, maxi = math.min(mini, t.style[s] or 0), math.max(maxi, t.style[s] or 0)
			end
		end
		if mini > maxi then
			mini, maxi = 0, 0
		end
```

Dans `src/client/Atelier/EcranCarnet.luau`, remplacer :

```lua
		local fourchette = Notation.fourchette(croquis, choixPieces, Notation.accessoiresImposes(etat.commande.exigences))
```

par :

```lua
		local fourchette = Notation.fourchette(croquis, choixPieces, Notation.accessoiresImposes(etat.commande.exigences), Deblocages.ouverts(etat).tissus)
```

- [ ] **Step 4: Lancer les tests**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT"`
Expected:
```
Unitaires : 167636 vérifications
TOUT EST VERT : 746 vérifications
```

- [ ] **Step 5: Commit**

```bash
git add src/shared/Notation.luau src/client/Atelier/EcranCarnet.luau tests/unitaires/05_notation.luau tests/scenario.luau
git commit -m "Jauges du carnet : la plage ne compte que les tissus ouverts

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 2: Le récit tient debout

**Files:**
- Modify: `src/shared/Histoire.luau`
- Modify: `tests/unitaires/52_histoire.luau`

**Interfaces:**
- Consumes: `Histoire.get`, `Histoire.commande`.
- Produces: rien de nouveau (textes retouchés).

- [ ] **Step 1: Écrire les tests**

Dans `tests/unitaires/52_histoire.luau`, remplacer :

```lua
and string.find(noces.epilogue, "lac", 1, true) == nil
```

par :

```lua
and string.find(noces.epilogue, "bord du lac", 1, true) == nil
```

Dans `tests/unitaires/52_histoire.luau`, remplacer :

```lua
U.verifier(Histoire.commande("inconnue") == nil and Histoire.get("inconnu") == nil, "identifiant inconnu : rien")
```

par :

```lua
U.verifier(Histoire.commande("inconnue") == nil and Histoire.get("inconnu") == nil, "identifiant inconnu : rien")
-- Le récit tient debout : au bal des lanternes, Margot tient son stand de limonade (elle ne danse pas) ; le bateau
-- des régates n'est pas celui de Colette (on l'y emmène) ; au bal d'hiver, la neige tombe dehors, pas dans la salle ;
-- Margot ne répète pas « tout le monde » dans la même phrase
local function nombre(texte, motif)
	local n, debut = 0, 1
	while true do
		local i = string.find(texte, motif, debut, true)
		if not i then
			return n
		end
		n, debut = n + 1, i + 1
	end
end
U.verifier(string.find(Histoire.get("lanternes").epilogue, "limonade", 1, true) ~= nil and string.find(Histoire.get("lanternes").epilogue, "Margot ont dansé", 1, true) == nil, "bal des lanternes : Margot tient son stand de limonade")
U.verifier(string.find(Histoire.get("regates").epilogue, "bateau de Colette", 1, true) == nil, "régates : le bateau n'est pas celui de Colette")
U.verifier(string.find(Histoire.get("bal_hiver").epilogue, "Dehors", 1, true) ~= nil, "bal d'hiver : la neige tombe dehors")
U.verifier(nombre(Histoire.commande("lanternes_margot").repliques.merci:lower(), "tout le monde") <= 1, "Margot ne répète pas « tout le monde »")
```

- [ ] **Step 2: Lancer les tests, vérifier l'échec**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT|attempt|membre" | head -3`
Expected: échec : une ligne qui finit par `ÉCHEC : bal des lanternes : Margot tient son stand de limonade`

- [ ] **Step 3: Retoucher les textes**

Dans `src/shared/Histoire.luau`, remplacer :

```lua
		epilogue = "Sous les lanternes de papier, Colette et Margot ont dansé jusqu'à minuit. Tout le quartier parle de ton atelier.",
```

par :

```lua
		epilogue = "Sous les lanternes de papier, Colette a dansé jusqu'à minuit, et Margot a vendu toute sa limonade. Tout le quartier parle de ton atelier.",
```

Dans `src/shared/Histoire.luau`, remplacer :

```lua
				"Tout le monde voulait savoir d'où venait ma robe. J'ai donné ton adresse à tout le monde !"),
```

par :

```lua
				"Tout le monde voulait savoir d'où venait ma robe. J'ai donné ton adresse à la moitié du quartier !"),
```

Dans `src/shared/Histoire.luau`, remplacer :

```lua
		epilogue = "Le bateau de Colette a fini deuxième, sous les applaudissements ; sur la rive, Hélène tenait le chronomètre comme une reine.",
```

par :

```lua
		epilogue = "Le bateau qui emmenait Colette a fini deuxième, sous les applaudissements ; sur la rive, Hélène tenait le chronomètre comme une reine.",
```

Dans `src/shared/Histoire.luau`, remplacer :

```lua
		epilogue = "Sous les flocons, tout le quartier a dansé dans la grande salle. Victoire a levé son verre : « À notre couturière. » Ton atelier est devenu le cœur du quartier.",
```

par :

```lua
		epilogue = "Dehors, la neige tombait ; dans la grande salle, tout le quartier a dansé. Victoire a levé son verre : « À notre couturière. » Ton atelier est devenu le cœur du quartier.",
```

- [ ] **Step 4: Lancer les tests**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT"`
Expected:
```
Unitaires : 167640 vérifications
TOUT EST VERT : 746 vérifications
```

- [ ] **Step 5: Commit**

```bash
git add src/shared/Histoire.luau tests/unitaires/52_histoire.luau
git commit -m "Récit : la limonade de Margot, le bateau qui emmène Colette, la neige dehors au bal d'hiver

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 3: Jupe crayon, annonce au pire cas, tests du plan 9

**Files:**
- Modify: `src/shared/Catalogue.luau` (jupe crayon), `src/client/Atelier/UiKit.luau` (`LARGEUR_CONTENU`, `mesureAnnonce`), `src/client/Atelier/EcranAccueil.luau` (annonce), `src/shared/Patron.luau` (poitrine de la taille M lue au catalogue)
- Modify: `tests/unitaires/03_patron.luau`, `46_deblocages_etat.luau`, `55_annonces.luau`, `tests/scenario.luau`

**Interfaces:**
- Consumes: `UiKit.lignes` (plan 9), `Catalogue.TAILLES.M`.
- Produces: `UiKit.LARGEUR_CONTENU` ; `UiKit.mesureAnnonce(texte, largeur) -> taille, hauteur`.

- [ ] **Step 1: Écrire les tests**

Dans `tests/unitaires/03_patron.luau`, remplacer :

```lua
						local horizontale = math.sqrt(p.X * p.X + p.Z * p.Z)
						U.verifier(horizontale > 1.15, id .. " : la jupe ne traverse pas les jambes")
```

par :

```lua
						local jambeDroite = math.sqrt((p.X - 0.55) ^ 2 + p.Z ^ 2)
						local jambeGauche = math.sqrt((p.X + 0.55) ^ 2 + p.Z ^ 2)
						U.verifier(jambeDroite > 0.6 and jambeGauche > 0.6, id .. " : la jupe ne traverse pas les jambes")
```

Dans `tests/unitaires/03_patron.luau`, remplacer :

```lua
U.verifier(horizontale(crayonOurlet) < horizontale(crayonHanches) - 0.05 and horizontale(crayonOurlet) < horizontale(droiteOurlet), "jupe crayon : resserrée à l'ourlet, plus que la jupe droite")
```

par :

```lua
U.verifier(horizontale(crayonOurlet) < horizontale(crayonHanches) - 0.1 and horizontale(crayonOurlet) < horizontale(droiteOurlet), "jupe crayon : resserrée à l'ourlet, plus que la jupe droite")
```

Dans `tests/unitaires/46_deblocages_etat.luau`, remplacer :

```lua
-- Plus tard aussi (prestiges 6, 7 et 8, amitié nulle ou au plus haut) : le tirage trouve une vraie commande (un
-- « au moins » de 30 ou plus dans un de ses styles), jamais le repli (« au moins » 20 ou 10, ou la qualité seule)
```

par :

```lua
-- Plus tard aussi (prestiges 6, 7 et 8, amitié nulle ou au plus haut) : le tirage trouve une vraie commande (un
-- « au moins » de 30 ou plus dans un de ses styles), réalisable avec ce qui est ouvert, jamais le repli (« au
-- moins » 20 ou 10, ou la qualité seule)
```

Dans `tests/unitaires/46_deblocages_etat.luau`, remplacer :

```lua
			local rng = Random.new(prestige + amitie)
			local replis = 0
			for _ = 1, 10 do
				local premiere = Commandes.generer(rng, c, progres).exigences[1]
				if not (premiere.type == "min" and premiere.valeur >= 30 and table.find(c.styles, premiere.style)) then
					replis += 1
				end
			end
			U.verifier(replis == 0, ("%s au prestige %d, amitié %d : de vraies commandes, sans repli (%d replis)"):format(c.id, prestige, amitie, replis))
```

par :

```lua
			local ouverts = Deblocages.ouverts(progres)
			local rng = Random.new(prestige + amitie)
			local replis = 0
			for _ = 1, 10 do
				local commande = Commandes.generer(rng, c, progres)
				local premiere = commande.exigences[1]
				if not (premiere.type == "min" and premiere.valeur >= 30 and table.find(c.styles, premiere.style) and Commandes.realisable(commande.exigences, ouverts)) then
					replis += 1
				end
			end
			U.verifier(replis == 0, ("%s au prestige %d, amitié %d : de vraies commandes, réalisables, sans repli (%d en défaut)"):format(c.id, prestige, amitie, replis))
```

Dans `tests/unitaires/55_annonces.luau`, remplacer :

```lua
U.verifier(UiKit.lignes("Robe livrée !\n" .. nouveau6, 860, 18) == 3, "une ligne courte et une longue : trois lignes")
```

par :

```lua
U.verifier(UiKit.lignes("Robe livrée !\n" .. nouveau6, 860, 18) == 3, "une ligne courte et une longue : trois lignes")
-- Au pire (niveau de prestige, niveau d'amitié et lettre arrivée ensemble), l'annonce passe en 14 px pour laisser la
-- place au courrier : jamais plus haute que quatre lignes de 18 px
local pire = table.concat({
	"Apolline est enchantée : « Elle est si belle que je vais lui écrire un sonnet. » +128 pièces d'or.",
	"Acompte de 23 déjà reçu · Amitié d'Apolline : +3 (niveau 2 !) · Prestige : +21 (niveau 6 !)",
	nouveau6 .. " Et encore : la jupe crayon et le cache-cœur.",
	"Une lettre de Colette est arrivée.",
}, "\n")
local taille, hauteur = UiKit.mesureAnnonce("Robe livrée !", 860)
U.verifier(taille == 18 and hauteur == 26, "annonce courte : 18 px, une ligne")
taille, hauteur = UiKit.mesureAnnonce(pire, 860)
U.verifier(taille == 14 and hauteur <= 4 * 24 + 2, ("annonce au pire cas : 14 px, %d px de haut (98 au plus)"):format(hauteur))
```

Dans `tests/scenario.luau`, remplacer :

```lua
	verifier(string.find(annonce.Text, "Nouveau : Manches courtes", 1, true) ~= nil and annonce.Size.Y.Offset == 24 * requireModule(scriptClient.UiKit).lignes(annonce.Text, fenetre.Size.X.Offset + fenetre.Contenu.Size.X.Offset, 18) + 2 and intro.Position.Y.Offset >= annonce.Size.Y.Offset + 10, "annonce longue (prestige 6) : sa hauteur compte les lignes repliées, l'introduction reste dessous")
```

par :

```lua
	local taille, hauteur = requireModule(scriptClient.UiKit).mesureAnnonce(annonce.Text, fenetre.Size.X.Offset + fenetre.Contenu.Size.X.Offset)
	verifier(string.find(annonce.Text, "Nouveau : Manches courtes", 1, true) ~= nil and annonce.TextSize == taille and annonce.Size.Y.Offset == hauteur and intro.Position.Y.Offset >= hauteur + 10, "annonce longue (prestige 6) : sa hauteur compte les lignes repliées, l'introduction reste dessous")
```

- [ ] **Step 2: Lancer les tests, vérifier l'échec**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT|attempt|membre" | head -3`
Expected: échec : une ligne qui finit par `ÉCHEC : jupe crayon : resserrée à l'ourlet, plus que la jupe droite`

- [ ] **Step 3: La jupe crayon, de nouveau resserrée**

Dans `src/shared/Catalogue.luau`, remplacer :

```lua
		enroulement = { type = "jupe", cote = "devant", evasement = -0.025, fronces = 0 } },
	jupe_crayon_dos = { nom = "Jupe crayon dos", contour = CRAYON, coutures = { 1, 2, 4 },
		enroulement = { type = "jupe", cote = "dos", evasement = -0.025, fronces = 0 } },
```

par :

```lua
		enroulement = { type = "jupe", cote = "devant", evasement = -0.04, fronces = 0 } },
	jupe_crayon_dos = { nom = "Jupe crayon dos", contour = CRAYON, coutures = { 1, 2, 4 },
		enroulement = { type = "jupe", cote = "dos", evasement = -0.04, fronces = 0 } },
```

- [ ] **Step 4: Lancer les tests, vérifier l'échec suivant**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT|attempt|membre" | head -3`
Expected: échec : une ligne qui finit par `attempt to call a nil value`

- [ ] **Step 5: L'annonce mesurée, les valeurs lues à la source**

Dans `src/client/Atelier/UiKit.luau`, remplacer :

```lua
UiKit.LARGEUR_PANNEAU = 380 -- fenêtre rangée à droite pendant les postes autour du mannequin
```

par :

```lua
UiKit.LARGEUR_PANNEAU = 380 -- fenêtre rangée à droite pendant les postes autour du mannequin
UiKit.LARGEUR_CONTENU = UiKit.LARGEUR - 40 -- contenu de la fenêtre centrée (20 px de marge de chaque côté, init.client)
```

Dans `src/client/Atelier/UiKit.luau`, remplacer :

```lua
function UiKit.texte(props)
```

par :

```lua
-- Taille (px) et hauteur de l'annonce de l'accueil dans une largeur donnée : 18 px tant qu'elle tient en quatre
-- lignes, sinon 14 px (lignes de 19 px), pour laisser la place au courrier dessous
function UiKit.mesureAnnonce(texte, largeur)
	local lignes = UiKit.lignes(texte, largeur, 18)
	if lignes <= 4 then
		return 18, 24 * lignes + 2
	end
	return 14, 19 * UiKit.lignes(texte, largeur, 14) + 2
end

function UiKit.texte(props)
```

Dans `src/client/Atelier/EcranAccueil.luau`, remplacer :

```lua
		local hauteur = 24 * UiKit.lignes(annonce, UiKit.LARGEUR - 40, 18) + 2 -- (« Nouveau : » peut tenir sur deux lignes)
		UiKit.texte({ Name = "Annonce", Text = annonce, Font = Enum.Font.GothamBold, TextSize = 18,
```

par :

```lua
		local taille, hauteur = UiKit.mesureAnnonce(annonce, UiKit.LARGEUR_CONTENU) -- (« Nouveau : » peut tenir sur deux lignes)
		UiKit.texte({ Name = "Annonce", Text = annonce, Font = Enum.Font.GothamBold, TextSize = taille,
```

Dans `src/shared/Patron.luau`, remplacer :

```lua
rayon, y = RAYON_COU + v * hauteur * 0.8 * m.poitrine / 8.8,
```

par :

```lua
rayon, y = RAYON_COU + v * hauteur * 0.8 * m.poitrine / Catalogue.TAILLES.M.poitrine,
```

- [ ] **Step 6: Lancer les tests**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT"`
Expected:
```
Unitaires : 167642 vérifications
TOUT EST VERT : 746 vérifications
```

- [ ] **Step 7: Commit**

```bash
git add src/shared/Catalogue.luau src/client/Atelier/UiKit.luau src/client/Atelier/EcranAccueil.luau src/shared/Patron.luau tests/unitaires/03_patron.luau tests/unitaires/46_deblocages_etat.luau tests/unitaires/55_annonces.luau tests/scenario.luau
git commit -m "Jupe crayon resserrée (vraies jambes dans le test) ; annonce en 14 px quand elle est très longue ; tests du plan 9 complétés

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

Construire le lieu du dépôt dans un dossier temporaire (`C:/dev/jeux/roblox-maker/rojo.exe build -o <dossier temporaire>/Plan10Depot.rbxl`) et l'ouvrir dans Studio. En mode édition, par `execute_luau` : construire un mannequin et une robe (corsage droit, sans manches, sans col, jupe crayon, coton blanc) aux hanches de 8 dm (poitrine 8, taille 6) ; la regarder de face par `screen_capture`, puis détruire le dossier. En Play : attendre 4 s, appuyer sur E, régler les rubans aux vraies mesures de Colette et valider ; au carnet, relever la largeur de la plage de la jauge « élégant » (`Plage.Size.X.Scale`) et la comparer à `Notation.fourchette` du croquis de départ avec les tissus ouverts ; relever la console.

Expected : la jupe crayon resserrée à l'ourlet, hors du pied du mannequin ; au carnet, la plage « élégant » égale à la fourchette des tissus ouverts (0,44 sans accessoire imposé) ; aucune alerte de notre code (« Lieu non publié » et les messages internes de Roblox mis à part). Arrêter Play et fermer cette fenêtre de Studio (sans enregistrer).

- [ ] **Step 2: Mettre à jour le README**

Dans `README.md`, remplacer :

```markdown
   Les jauges de style, l'état des exigences, le métrage et le coût du tissu à acheter se mettent à jour en
   direct. Ce qui n'est pas encore ouvert
```

par :

```markdown
   Les jauges de style, l'état des exigences, le métrage et le coût du tissu à acheter se mettent à jour en
   direct (la plage d'une jauge ne compte que les tissus ouverts). Ce qui n'est pas encore ouvert
```

Dans `README.md`, remplacer :

```markdown
7. **Décorations** : 30 objets (boutons, nœuds, fleurs, broches, perles, étoile, croix, couronne, violette,
   boucle, coquillage, et les douze souvenirs
```

par :

```markdown
7. **Décorations** : 30 objets (boutons, nœuds, papillon, fleurs, broches, perles, étoile, croix, couronne,
   violette, boucle, coquillage, et les douze souvenirs
```

Dans `README.md`, remplacer :

```markdown
   **Déblocages** : au départ, cotons et lins, huit variantes et six accessoires.
```

par :

```markdown
   **Déblocages** : au départ, cotons, lins et toile de jute, huit variantes et six accessoires.
```

- [ ] **Step 3: Tests, lieu régénéré, commit**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT"`
Expected:
```
Unitaires : 167642 vérifications
TOUT EST VERT : 746 vérifications
```

```bash
C:/dev/jeux/roblox-maker/rojo.exe build -o AtelierCouture.rbxl
git add README.md AtelierCouture.rbxl
git commit -m "Plan 10 terminé : finitions générales

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```
