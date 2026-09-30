# Clientes et progression — Plan 5d : le courrier et le carnet d'adresses

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Finir le sous-projet 2 : le courrier (des lettres de clientes déjà venues, qu'on invite quand on veut, avec un point d'amitié de plus), la boîte aux lettres du comptoir, le carnet d'adresses (amitiés et prochains déblocages), l'équilibrage revu avec le courrier et le README du sous-projet.

**Architecture:**
- **Règles** (`EtatAtelier`, serveur) : champ `lettres` ; après une livraison ou une vente, le courrier tire une lettre (toutes les deux robes, après cinq commandes livrées, trois au plus) ; `inviter(indice)` fait venir la cliente avec la commande de sa lettre (même accueil que la clochette : visite notée, acompte, mesures) ; la commande venue par lettre rapporte un point d'amitié de plus. Le tirage vient de l'appelant (`livrer(rng)`, `vendre(rng)`), le serveur passe le sien.
- **Sauvegarde** : les lettres suivent la partie ; illisibles, elles sont laissées ; trois au plus.
- **Interface** : l'accueil montre le courrier (chaque lettre et « Inviter ») et le carnet d'adresses ; l'annonce dit qu'une lettre est arrivée ; une lettre dépasse de la boîte aux lettres du comptoir (construite par le serveur, montrée par la scène).
- **Équilibrage** : la simulation invite les lettres.

**Tech Stack:** Luau, Rojo 7.7.0-rc.1, simulation Luau 0.650 (`tests/lancer.sh`), Roblox Studio via le connecteur MCP Studio.

**Spec:** `docs/superpowers/specs/2026-09-29-clientes-progression-design.md` (§2 amitié : +1 pour une commande venue par lettre ; §6 le courrier ; §8 `inviter(indiceLettre)`, champ `lettres` ; §9 accueil : lettres, carnet d'adresses ; §11 plan 5d). Plans précédents : `…plan5a.md` à `…plan5c.md`.

## Décisions de ce plan

- **Le courrier** (spec §6) : ouvert quand cinq commandes ont été livrées (`EtatAtelier.COURRIER_APRES = 5`). Après chaque livraison acceptée ou vente, si le total des robes livrées et vendues est pair et qu'il y a moins de trois lettres (`LETTRES_MAX = 3`), une lettre arrive, d'une cliente déjà venue (au moins une visite) tirée au hasard, avec la commande qu'elle passera (tirée à ce moment, pour son prestige et ses goûts). Les lettres n'expirent pas. Sans tirage (appel sans `rng`), pas de lettre : les tests existants ne changent pas.
- **Inviter** (spec §6, §8) : `inviter(indice)` prend la lettre, fait entrer la cliente (sa visite est notée, elle verse l'acompte, on la mesure), marque la commande `parLettre` ; livrée et acceptée, elle rapporte `Progression.BONUS_LETTRE = 1` point d'amitié de plus. La clochette et l'invitation partagent le même accueil (`accueillir`).
- **Accueil** : la longue explication tant qu'aucune robe n'est livrée, une ligne ensuite (place pour le courrier) ; sous la jauge de prestige, « Courrier : » et chaque lettre (« Colette : « Romantique d'au moins 40 % » » et « Inviter »), ou « pas de lettre pour l'instant » ; « Carnet d'adresses » à côté de « Robe libre », avec, pour chaque cliente déjà venue, « Colette Marchand — amitié niveau 2 (9 / 12) · prochain : Dentelle blanche (niveau 4) ». L'annonce ajoute « Une lettre de Colette est arrivée. ».
- **Boîte aux lettres** : un bloc bleu sur le comptoir (`Boutique.BOITE_AUX_LETTRES`), construit par le serveur ; la scène du joueur y fait dépasser une lettre blanche tant que le courrier en contient.
- **Équilibrage** : le joueur simulé invite une lettre quand il y en a (la cliente la moins avancée en amitié d'abord). Mesuré : environ 40 commandes par lettre sur 90 robes, tout ouvert vers la 62e robe en médiane (les lettres viennent d'une cliente tirée au hasard, comme le veut la spec : elles n'accélèrent pas l'ouverture de tout). La cible amendée au plan 5c (50–80 en médiane) tient.
- **Vérifié pendant la préparation** : le plan a été joué entièrement sur un brouillon tiré de `main` ; huit variantes du brouillon (bonus de la lettre, ouverture du courrier, trois lettres au plus, une lettre toutes les deux robes, lettres sauvegardées, lettre dans la boîte, carnet d'adresses, courrier dans l'équilibrage) échouent chacune sur une vérification qui les garde (celle de la parité, dès la simulation d'équilibrage : des lettres à chaque robe empêchent de rencontrer toutes les clientes).

## Global Constraints

- **Dépôt** : `C:\dev\jeux\atelier-couture`, branche `courrier`, créée depuis `main` (où le plan 5c est fusionné). Selon les règles du commanditaire : la branche testée et relue est fusionnée dans `main` et poussée sur GitHub.
- **Rojo** : `C:/dev/jeux/roblox-maker/rojo.exe`.
- **Contraintes des plans précédents toujours valables** : fins de ligne LF, commits en français terminés par `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`, textes d'au moins 14 px, le serveur fait foi.
- **Contenu original** (spec §1) : pas de pigeon messager ni de texte de Dressmaker ; notre boîte aux lettres et nos lettres.
- **Commandes** : tout se joue d'un seul doigt ou à la souris seule.

## Review Focus

- **Indice de lettre farfelu envoyé au serveur** (0, trop grand, fractionnaire, texte, NaN). Attendu : refus, le courrier ne change pas. Test : `51_courrier`, « lettre inexistante : refusé (…) ».
- **Inviter pendant une commande.** Attendu : refus. Test : `51_courrier`, « une commande à la fois ».
- **Courrier plein.** Attendu : trois lettres au plus, rien de perdu. Test : `51_courrier`, « trois lettres au plus ».
- **Lettres abîmées dans la sauvegarde** (cliente inconnue, commande sans exigence, cliente différente, pas une table, trop nombreuses). Attendu : laissées, trois au plus. Test : `51_courrier`, « lettres illisibles laissées, trois au plus ».
- **Invitation, puis la cliente livrée.** Attendu : la lettre disparaît de la boîte, +1 d'amitié. Tests : scénario, « plus de lettre dans la boîte », « commande venue par lettre : +4 d'amitié (+3 et +1 de la lettre) ».

## Structure des fichiers

| Fichier | Rôle |
|---|---|
| `src/shared/EtatAtelier.luau` | `COURRIER_APRES`, `LETTRES_MAX`, `lettres`, `accueillir`, `inviter`, `courrier` ; `livrer(rng)`, `vendre(rng)` ; +1 d'amitié par lettre |
| `src/shared/Progression.luau` | `BONUS_LETTRE` |
| `src/shared/Deblocages.luau` | `prochainDeCliente` |
| `src/shared/Boutique.luau`, `src/server/Boutiques.luau` | Boîte aux lettres du comptoir |
| `src/server/Sauvegarde.luau`, `src/server/Commande.luau`, `src/client/Atelier/Session.luau` | Lettres sauvegardées ; action `inviter` ; tirage du serveur |
| `src/client/Atelier/Scene.luau`, `EcranAccueil.luau`, `init.client.luau` | Lettre dans la boîte ; courrier, carnet d'adresses, annonce ; son de l'invitation |
| `tests/unitaires/51_courrier.luau` | **Nouveau** |
| `tests/unitaires/45_…`, `48_equilibrage.luau`, `tests/scenario.luau` | Tests complétés |
| `README.md`, `AtelierCouture.rbxl` | Sous-projet 2 terminé ; lieu régénéré |

---

### Task 1: Le courrier : lettres, invitations

**Files:**
- Modify: `src/shared/Progression.luau`, `src/shared/EtatAtelier.luau`
- Modify: `src/server/Sauvegarde.luau`, `src/server/Commande.luau`, `src/client/Atelier/Session.luau`
- Create: `tests/unitaires/51_courrier.luau`

**Interfaces:**
- Consumes: `Commandes.generer(rng, cliente, progres)` (plan 5b) ; `EtatAtelier.livraisons`, `ventes` (plans 5a, 5c).
- Produces:
  - `EtatAtelier.COURRIER_APRES = 5`, `EtatAtelier.LETTRES_MAX = 3` ; champ `lettres` (`{ { cliente, commande } }`) ; `commande.parLettre` ;
  - `EtatAtelier:livrer(rng?)`, `EtatAtelier:vendre(rng?)` → en plus `lettre` (la lettre arrivée, ou nil) ;
  - `EtatAtelier:inviter(indice)` → comme `nouvelleCommande` ; refus « Cette lettre n'existe pas. » ;
  - `Progression.BONUS_LETTRE = 1` ;
  - action serveur `inviter` ; `Session:inviter(indice)` ; hors du jeu, la session tire elle-même les lettres.

- [ ] **Step 1: Écrire les tests**

Créer `tests/unitaires/51_courrier.luau` :

```lua
local EtatAtelier = U.module("EtatAtelier")
local Clientes = U.module("Clientes")
local Progression = U.module("Progression")
local Sauvegarde = U.module("Sauvegarde")

-- Une robe simple, coupée, épinglée et cousue, présentée ; la cliente ne demande qu'un peu de qualité
local function robePrete(etat)
	etat.croquis = { corsage = "corsage_droit", manches = "manches_sans", col = "col_sans", jupe = "jupe_droite" }
	etat.tissus = { corsage_droit_devant = "coton_blanc", corsage_droit_dos = "coton_blanc", jupe_droite_devant = "coton_blanc", jupe_droite_dos = "coton_blanc" }
	for id in pairs(etat.tissus) do
		etat.coupees[id] = { x = 0, y = 0, angle = 0 }
		etat.epinglees[id] = true
		etat.coutures[id] = 1
	end
	etat.etape = "decorations"
	assert(etat:decorer({}).ok)
	etat.commande.exigences = { { type = "qualite", valeur = 0.1 } }
end
-- Une commande de la clochette, mesurée et livrée ; renvoie la réponse de la livraison
local function commandeLivree(etat, rng)
	assert(etat:nouvelleCommande(rng).ok)
	assert(etat:mesurer(Clientes.get(etat.commande.cliente).mesures).ok)
	robePrete(etat)
	return etat:livrer(rng)
end

-- Le courrier s'ouvre après cinq commandes livrées ; une lettre toutes les deux robes (livrées ou vendues)
local e = EtatAtelier.nouveau(500)
local rng = Random.new(8)
e.livraisons = 3
local r = commandeLivree(e, rng)
U.verifier(r.reussie and e.livraisons == 4 and r.lettre == nil and #e.lettres == 0, "quatre commandes livrées : pas encore de courrier")
r = commandeLivree(e, rng)
U.verifier(e.livraisons == 5 and r.lettre == nil and #e.lettres == 0, "cinquième : pas de lettre (une toutes les deux robes)")
r = commandeLivree(e, rng)
local lettre = e.lettres[1]
U.verifier(e.livraisons == 6 and r.lettre ~= nil and #e.lettres == 1 and lettre == r.lettre, "sixième : une lettre arrive")
U.verifier(e.clientes[lettre.cliente] ~= nil and e.clientes[lettre.cliente].vues > 0 and lettre.commande.cliente == lettre.cliente and #lettre.commande.exigences >= 1, "d'une cliente déjà venue, avec la commande qu'elle passera")
U.verifier(EtatAtelier.nouveau(500):livrer() ~= nil, "(livrer sans commande : refusé, sans erreur)")
local sansTirage = EtatAtelier.nouveau(500)
sansTirage.livraisons = 5
U.verifier(commandeLivree(sansTirage, Random.new(1)).lettre ~= nil, "(le tirage vient de l'appelant)")
sansTirage.livraisons = 7
sansTirage:nouvelleCommande(Random.new(2))
sansTirage:mesurer(Clientes.get(sansTirage.commande.cliente).mesures)
robePrete(sansTirage)
U.verifier(sansTirage:livrer().lettre == nil, "sans tirage : pas de lettre")

-- Trois lettres au plus ; elles n'expirent pas
e.lettres = { lettre, lettre, lettre }
e.livraisons = 7
r = commandeLivree(e, rng)
U.verifier(r.lettre == nil and #e.lettres == 3, "trois lettres au plus")
e.lettres = { lettre }

-- Inviter : la cliente de la lettre vient avec sa commande (mesures, acompte) ; la lettre est retirée
for _, mauvais in ipairs({ 0, 2, 1.5, "1", 0 / 0 }) do
	r = e:inviter(mauvais)
	U.verifier(not r.ok and r.erreur == "Cette lettre n'existe pas." and #e.lettres == 1 and e.etape == "accueil", "lettre inexistante : refusé (" .. tostring(mauvais) .. ")")
end
local fiche = e.clientes[lettre.cliente]
local vues, argentAvant = fiche.vues, e.argent
r = e:inviter(1)
U.verifier(r.ok and e.etape == "mesures" and e.commande == lettre.commande and e.commande.parLettre == true and #e.lettres == 0, "invitée : elle vient avec la commande de sa lettre")
U.verifier(fiche.vues == vues + 1 and r.acompte > 0 and e.argent == argentAvant + r.acompte, "sa visite est notée, elle verse l'acompte")
U.verifier(not e:inviter(1).ok, "une commande à la fois")
-- Livrée et acceptée : un point d'amitié de plus
e:mesurer(Clientes.get(lettre.cliente).mesures)
robePrete(e)
local amitieAvant = fiche.amitie
r = e:livrer(rng)
U.verifier(r.reussie and r.amitie.gain == Progression.gainAmitie(true, r.bilan.qualite) + 1 and fiche.amitie == amitieAvant + r.amitie.gain, "commande venue par lettre : +1 d'amitié de plus")

-- Une robe libre vendue compte aussi pour le courrier
local v = EtatAtelier.nouveau(500)
v.livraisons, v.ventes = 5, 0
v.clientes.colette = { amitie = 0, vues = 1, derniere = 1 }
v:nouvelleRobeLibre("M")
robePrete(v)
v.commande.exigences = {}
r = v:vendre(Random.new(3))
U.verifier(r.ok and v.ventes == 1 and r.lettre ~= nil and r.lettre.cliente == "colette", "robe vendue : la sixième robe apporte une lettre")

-- Sauvegarde : les lettres suivent ; illisibles, elles sont laissées ; trois au plus
local s = EtatAtelier.nouveau(100)
s.clientes.colette = { amitie = 0, vues = 1, derniere = 1 }
s.lettres = { { cliente = "colette", commande = { cliente = "colette", taille = "M", exigences = { { type = "min", style = "romantique", valeur = 30 } } } } }
local relue = Sauvegarde.versEtat(M.transmettre(Sauvegarde.depuisEtat(s)))
U.verifier(#relue.lettres == 1 and relue.lettres[1].cliente == "colette" and relue.lettres[1].commande.exigences[1].style == "romantique", "les lettres sont sauvegardées")
local p = M.transmettre(Sauvegarde.depuisEtat(s))
p.lettres = {
	{ cliente = "inconnue", commande = { cliente = "inconnue", taille = "M", exigences = { { type = "qualite", valeur = 0.5 } } } },
	{ cliente = "colette", commande = { cliente = "colette", taille = "M", exigences = {} } },
	{ cliente = "colette", commande = { cliente = "margot", taille = "S", exigences = { { type = "qualite", valeur = 0.5 } } } },
	"abîmée",
	p.lettres[1], p.lettres[1], p.lettres[1], p.lettres[1],
}
relue = Sauvegarde.versEtat(p)
U.verifier(#relue.lettres == 3 and relue.lettres[1].cliente == "colette", "lettres illisibles laissées, trois au plus")
```

- [ ] **Step 2: Lancer les tests, vérifier l'échec**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT|attempt|membre" | head -3`
Expected: échec : une ligne qui finit par `attempt to get length of a nil value` (le courrier n'existe pas encore)

- [ ] **Step 3: Écrire le code**

Dans `src/shared/Progression.luau`, remplacer :

```lua
-- Une robe offerte : +2 de prestige
```

par :

```lua
-- Une commande venue par lettre, livrée et acceptée : un point d'amitié de plus
Progression.BONUS_LETTRE = 1

-- Une robe offerte : +2 de prestige
```

Dans `src/shared/EtatAtelier.luau`, remplacer :

```lua
EtatAtelier.MAIN_OEUVRE = 6 -- pièces d'or par pièce posée, dans le prix de vente d'une robe libre
```

par :

```lua
EtatAtelier.MAIN_OEUVRE = 6 -- pièces d'or par pièce posée, dans le prix de vente d'une robe libre
EtatAtelier.COURRIER_APRES = 5 -- le courrier s'ouvre après cinq commandes livrées
EtatAtelier.LETTRES_MAX = 3
```

Dans `src/shared/EtatAtelier.luau`, remplacer :

```lua
		visites = 0,
		ventes = 0,
```

par :

```lua
		visites = 0,
		ventes = 0,
		lettres = {}, -- le courrier : { { cliente, commande } }, trois au plus
```

Dans `src/shared/EtatAtelier.luau`, remplacer :

```lua
"clientes", "prestige", "livraisons", "visites", "ventes" }
```

par :

```lua
"clientes", "prestige", "livraisons", "visites", "ventes", "lettres" }
```

Dans `src/shared/EtatAtelier.luau`, remplacer :

```lua
-- La clochette : une cliente vient (Clientes.prochaine) avec une commande tirée de ses goûts. On prend
-- d'abord ses mesures (étape « mesures ») ; une cliente déjà venue peut les reprendre.
function EtatAtelier:nouvelleCommande(rng)
	if self.etape ~= "accueil" then
		return refus("Une commande est déjà en cours.")
	end
	local id = Clientes.prochaine(self.clientes, Progression.niveauPrestige(self.prestige))
	local fiche = self.clientes[id] or { amitie = 0, vues = 0, derniere = 0 }
	self.clientes[id] = fiche
	self.visites += 1
	fiche.vues += 1
	fiche.derniere = self.visites
	self.commande = Commandes.generer(rng, Clientes.get(id), self)
	self.commande.numero = self.visites -- la reconnaît d'une copie à l'autre (la scène garde la même cliente)
```

par :

```lua
-- Une cliente entre avec sa commande : sa visite est notée, elle verse l'acompte, on prend d'abord ses mesures
-- (étape « mesures ») ; une cliente déjà venue peut les reprendre
local function accueillir(self, id, commande)
	local fiche = self.clientes[id] or { amitie = 0, vues = 0, derniere = 0 }
	self.clientes[id] = fiche
	self.visites += 1
	fiche.vues += 1
	fiche.derniere = self.visites
	self.commande = commande
	self.commande.numero = self.visites -- la reconnaît d'une copie à l'autre (la scène garde la même cliente)
```

Dans `src/shared/EtatAtelier.luau`, remplacer :

```lua
	self.etape = "mesures"
	return { ok = true, commande = self.commande, cliente = id, premiereVisite = fiche.vues == 1, acompte = acompte }
end
```

par :

```lua
	self.etape = "mesures"
	return { ok = true, commande = self.commande, cliente = id, premiereVisite = fiche.vues == 1, acompte = acompte }
end

-- La clochette : une cliente vient (Clientes.prochaine) avec une commande tirée de ses goûts
function EtatAtelier:nouvelleCommande(rng)
	if self.etape ~= "accueil" then
		return refus("Une commande est déjà en cours.")
	end
	local id = Clientes.prochaine(self.clientes, Progression.niveauPrestige(self.prestige))
	return accueillir(self, id, Commandes.generer(rng, Clientes.get(id), self))
end

-- Inviter la cliente d'une lettre (indice dans le courrier) : elle vient avec la commande annoncée ; livrée et
-- acceptée, elle rapporte un point d'amitié de plus
function EtatAtelier:inviter(indice)
	if self.etape ~= "accueil" then
		return refus("Une commande est déjà en cours.")
	end
	local lettre = type(indice) == "number" and self.lettres[indice] or nil
	if not lettre then
		return refus("Cette lettre n'existe pas.")
	end
	table.remove(self.lettres, indice)
	lettre.commande.parLettre = true
	return accueillir(self, lettre.cliente, lettre.commande)
end

-- Le courrier : après cinq commandes livrées, une lettre arrive toutes les deux robes (livrées ou vendues), d'une
-- cliente déjà venue tirée au hasard, avec la commande qu'elle passera (on en voit la première exigence). Trois
-- lettres au plus ; elles n'expirent pas. Renvoie la lettre arrivée, ou nil
local function courrier(self, rng)
	if not rng or self.livraisons < EtatAtelier.COURRIER_APRES or #self.lettres >= EtatAtelier.LETTRES_MAX or (self.livraisons + self.ventes) % 2 ~= 0 then
		return nil
	end
	local venues = {}
	for _, c in ipairs(Clientes.LISTE) do
		local f = self.clientes[c.id]
		if f and f.vues > 0 then
			table.insert(venues, c)
		end
	end
	if #venues == 0 then
		return nil
	end
	local cliente = venues[rng:NextInteger(1, #venues)]
	local lettre = { cliente = cliente.id, commande = Commandes.generer(rng, cliente, self) }
	table.insert(self.lettres, lettre)
	return lettre
end
```

Dans `src/shared/EtatAtelier.luau`, remplacer :

```lua
	local plancher = Progression.SEUILS_AMITIE[Progression.niveauAmitie(avant) + 1]
	fiche.amitie = math.max(plancher, avant + Progression.gainAmitie(reussie, qualite))
```

par :

```lua
	local plancher = Progression.SEUILS_AMITIE[Progression.niveauAmitie(avant) + 1]
	local lettre = if reussie and self.commande.parLettre then Progression.BONUS_LETTRE else 0
	fiche.amitie = math.max(plancher, avant + Progression.gainAmitie(reussie, qualite) + lettre)
```

Dans `src/shared/EtatAtelier.luau`, remplacer :

```lua
-- Livraison : la cliente juge la robe (styles, qualité, couleur, accessoires) d'après sa recette.
-- Acceptée : paie = base × (0,5 + qualité), la robe part en vitrine. Refusée : retouche ou abandon.
function EtatAtelier:livrer()
```

par :

```lua
-- Livraison : la cliente juge la robe (styles, qualité, couleur, accessoires) d'après sa recette.
-- Acceptée : paie = base × (0,5 + qualité), la robe part en vitrine. Refusée : retouche ou abandon.
-- rng (facultatif) : de quoi tirer une lettre, si le courrier en apporte une
function EtatAtelier:livrer(rng)
```

Dans `src/shared/EtatAtelier.luau`, remplacer :

```lua
	local nouveaux = Deblocages.nouveaux(avant, self)
	return { ok = true, reussie = true, paie = paie, acompte = acompte, verse = verse, bilan = bilan, ratees = {}, amitie = gainAmitie, prestige = prestige, nouveaux = nouveaux }
```

par :

```lua
	local nouveaux = Deblocages.nouveaux(avant, self)
	return { ok = true, reussie = true, paie = paie, acompte = acompte, verse = verse, bilan = bilan, ratees = {}, amitie = gainAmitie, prestige = prestige, nouveaux = nouveaux, lettre = courrier(self, rng) }
```

Dans `src/shared/EtatAtelier.luau`, remplacer :

```lua
-- seule (ce qu'elle rapporterait sans matières ni décorations, / 15) : il ne s'achète pas en décorant
function EtatAtelier:vendre()
```

par :

```lua
-- seule (ce qu'elle rapporterait sans matières ni décorations, / 15) : il ne s'achète pas en décorant.
-- rng : de quoi tirer une lettre, comme pour livrer
function EtatAtelier:vendre(rng)
```

Dans `src/shared/EtatAtelier.luau`, remplacer :

```lua
	return { ok = true, prix = prix, bilan = bilan, prestige = prestige, nouveaux = Deblocages.nouveaux(avant, self) }
```

par :

```lua
	return { ok = true, prix = prix, bilan = bilan, prestige = prestige, nouveaux = Deblocages.nouveaux(avant, self), lettre = courrier(self, rng) }
```

Dans `src/server/Sauvegarde.luau`, remplacer :

```lua
		ventes = d.ventes,
```

par :

```lua
		ventes = d.ventes,
		lettres = d.lettres,
```

Dans `src/server/Sauvegarde.luau`, remplacer :

```lua
	base.ventes = entier(partie.ventes)
```

par :

```lua
	base.ventes = entier(partie.ventes)
	-- Courrier : trois lettres au plus, d'une cliente connue, avec une commande qu'on peut jouer
	for _, l in ipairs(type(partie.lettres) == "table" and partie.lettres or {}) do
		if type(l) == "table" and type(l.cliente) == "string" and type(l.commande) == "table" and l.commande.cliente == l.cliente
			and commandeLisible(l.commande, "mesures") and #base.lettres < EtatAtelier.LETTRES_MAX then
			table.insert(base.lettres, { cliente = l.cliente, commande = copie(l.commande) })
		end
	end
```

Dans `src/server/Sauvegarde.luau`, remplacer :

```lua
	if c.acompte ~= nil and not (nombre(c.acompte, nil) and c.acompte == math.floor(c.acompte) and c.acompte >= 0 and c.acompte <= 1000) then
		return false
	end
```

par :

```lua
	if c.acompte ~= nil and not (nombre(c.acompte, nil) and c.acompte == math.floor(c.acompte) and c.acompte >= 0 and c.acompte <= 1000) then
		return false
	end
	if c.parLettre ~= nil and c.parLettre ~= true then
		return false
	end
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
		return a.etat:livrer(a.rng)
	end,
	inviter = function(a, indice)
		return a.etat:inviter(indice)
	end,
```

Dans `src/server/Commande.luau`, remplacer :

```lua
	vendre = function(a)
		return a.etat:vendre()
	end,
```

par :

```lua
	vendre = function(a)
		return a.etat:vendre(a.rng)
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
-- (hors du jeu, la session tire elle-même les lettres du courrier)
function Session:livrer()
	return agir(self, "livrer", if self.remote then nil else self.rng)
end
function Session:inviter(indice)
	return agir(self, "inviter", indice)
end
```

Dans `src/client/Atelier/Session.luau`, remplacer :

```lua
function Session:vendre()
	return agir(self, "vendre")
end
```

par :

```lua
function Session:vendre()
	return agir(self, "vendre", if self.remote then nil else self.rng)
end
```

- [ ] **Step 4: Lancer les tests**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT"`
Expected:
```
Unitaires : 107392 vérifications
TOUT EST VERT : 615 vérifications
```

- [ ] **Step 5: Commit**

```bash
git add src/shared/Progression.luau src/shared/EtatAtelier.luau src/server/Sauvegarde.luau src/server/Commande.luau src/client/Atelier/Session.luau tests/unitaires/51_courrier.luau
git commit -m "Courrier : des lettres de clientes déjà venues, qu'on invite ; un point d'amitié de plus

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 2: Courrier, carnet d'adresses et boîte aux lettres à l'écran

**Files:**
- Modify: `src/shared/Boutique.luau`, `src/server/Boutiques.luau`, `src/shared/Deblocages.luau`
- Modify: `src/client/Atelier/Scene.luau`, `EcranAccueil.luau`, `init.client.luau`
- Modify: `tests/unitaires/45_deblocages.luau`, `tests/scenario.luau`

**Interfaces:**
- Consumes: `lettres`, `inviter`, réponse `lettre` (tâche 1).
- Produces:
  - `Boutique.BOITE_AUX_LETTRES` ; pièce `BoiteAuxLettres` de la boutique ; pièce `Lettre` de la scène ;
  - `Deblocages.prochainDeCliente(id, points)` → `{ niveau, nom }` ou nil ;
  - accueil : texte `Intro`, textes `Courrier`, `Lettre<i>`, boutons `Inviter_<i>`, `OuvrirCarnetAdresses`, cadre `CarnetAdresses` (textes `Adresse_<id>`, bouton `FermerCarnetAdresses`).

- [ ] **Step 1: Écrire les tests**

Dans `tests/unitaires/45_deblocages.luau`, remplacer :

```lua
U.verifier(Deblocages.message("tissus", "soie_rouge") == "Pas encore ouvert : Soie rouge (Prestige 5).", "le refus dit ce qu'il faut pour ouvrir")
```

par :

```lua
U.verifier(Deblocages.message("tissus", "soie_rouge") == "Pas encore ouvert : Soie rouge (Prestige 5).", "le refus dit ce qu'il faut pour ouvrir")
local prochain = Deblocages.prochainDeCliente("colette", 0)
U.verifier(prochain ~= nil and prochain.niveau == 2 and prochain.nom == "Jupe ample froncée", "carnet d'adresses : l'amitié de Colette ouvrira ensuite la jupe ample (niveau 2)")
prochain = Deblocages.prochainDeCliente("colette", 7)
U.verifier(prochain ~= nil and prochain.niveau == 4 and prochain.nom == "Dentelle blanche", "… puis la dentelle blanche (niveau 4)")
U.verifier(Deblocages.prochainDeCliente("colette", 18) == nil, "au niveau 4, tout ce qu'elle ouvre est ouvert")
```

Dans `tests/scenario.luau`, remplacer :

```lua
-- une livraison déjà faite : celle-ci est la deuxième, les robes libres s'ouvrent
serveur:atelier(joueur).etat.prestige = 45
serveur:atelier(joueur).etat.livraisons = 1
```

par :

```lua
-- cinq livraisons déjà faites : celle-ci est la sixième, les robes libres et le courrier sont ouverts, et une
-- lettre arrive
serveur:atelier(joueur).etat.prestige = 45
serveur:atelier(joueur).etat.livraisons = 5
```

Dans `tests/scenario.luau`, remplacer :

```lua
verifierTailles("accueil")
serveur:atelier(joueur).etat.prestige = 530 -- (tout reste ouvert pour la suite)
```

par :

```lua
verifierTailles("accueil")
serveur:atelier(joueur).etat.prestige = 530 -- (tout reste ouvert pour la suite)
-- Le courrier : une lettre de Colette (la seule cliente déjà venue), qui dépasse de la boîte aux lettres
verifier(texte("Une lettre de Colette est arrivée.") ~= nil and fenetre.Contenu:FindFirstChild("Lettre1") ~= nil and boutonNomme("Inviter_1") ~= nil, "une lettre de Colette arrive, avec « Inviter »")
verifier(string.find(fenetre.Contenu.Lettre1.Text, "Colette : « ", 1, true) == 1, "la lettre annonce une exigence de sa commande")
verifier(scene:FindFirstChild("Lettre") ~= nil, "une lettre dépasse de la boîte aux lettres du comptoir")
-- Le carnet d'adresses : les clientes déjà venues, leur amitié, ce que le prochain niveau ouvrira
cliquer("OuvrirCarnetAdresses")
verifier(texte("Colette Marchand — amitié niveau 5") ~= nil and fenetre.Contenu.CarnetAdresses:FindFirstChild("Adresse_margot") == nil, "carnet d'adresses : Colette, pas encore Margot")
cliquer("FermerCarnetAdresses")
verifier(not fenetre.Contenu.CarnetAdresses.Visible, "carnet d'adresses refermé")
```

Dans `tests/scenario.luau`, remplacer :

```lua
verifier(serveur:atelier(joueur).etat.clientes.colette.amitie > amitieColette, "son amitié monte")
end
```

par :

```lua
verifier(serveur:atelier(joueur).etat.clientes.colette.amitie > amitieColette, "son amitié monte")
end

---------------------------------------------------------------------------
-- Inviter : la cliente de la lettre vient avec sa commande ; livrée, un point d'amitié de plus
---------------------------------------------------------------------------
do
cliquer("Inviter_1")
verifier(titre() == "Les mesures" and serveur:atelier(joueur).etat.commande.parLettre and #serveur:atelier(joueur).etat.lettres == 0, "invitée : Colette vient avec la commande de sa lettre")
verifier(fenetre.Message.Visible and string.find(fenetre.Message.Text, "Colette verse un acompte", 1, true) == 1, "elle verse l'acompte")
M.avancer(0.5)
verifier(scene:FindFirstChild("Lettre") == nil, "plus de lettre dans la boîte")
cliquer("ReprendreMesures")
verifier(titre() == "1. Carnet de croquis", "ses mesures reprises : le carnet")
-- La robe menée jusqu'à la photo sur le serveur, sans repasser par tous les postes
local e = serveur:atelier(joueur).etat
e.commande.exigences = { { type = "qualite", valeur = 0.1 } }
e.croquis = { corsage = "corsage_droit", manches = "manches_sans", col = "col_sans", jupe = "jupe_droite" }
e.tissus = {}
for _, id in ipairs(e:piecesDuCroquis()) do
	e.tissus[id] = "coton_blanc"
	e.coupees[id] = { x = 0, y = 0, angle = 0 }
	e.epinglees[id] = true
	e.coutures[id] = 0.9
end
e.etape = "photo"
requireModule(scriptClient.Session).courante:actualiser()
cliquer("Livrer")
cliquer("Livrer")
verifier(titre() == "Atelier de couture" and texte("Colette est ravie") ~= nil and texte("Amitié de Colette : +4") ~= nil, "commande venue par lettre : +4 d'amitié (+3 et +1 de la lettre)")
M.avancer(ScenePoste.DUREE_ADIEU + 0.5)
end
```

- [ ] **Step 2: Lancer les tests, vérifier l'échec**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT|attempt|membre" | head -3`
Expected: échec : une ligne qui finit par `attempt to call a nil value` (`Deblocages.prochainDeCliente` n'existe pas encore)

- [ ] **Step 3: Écrire le code**

Dans `src/shared/Boutique.luau`, remplacer :

```lua
Boutique.VITRINE = CFrame.new(7.5, 0.5, 32.5)
```

par :

```lua
Boutique.VITRINE = CFrame.new(7.5, 0.5, 32.5)
-- La boîte aux lettres, sur le comptoir (le courrier, sous-projet 2)
Boutique.BOITE_AUX_LETTRES = CFrame.new(-9, 3.4, 40)
```

Dans `src/server/Boutiques.luau`, remplacer :

```lua
	bloc(modele, origine, "Clochette", Vector3.new(-9, 3.4, 36.5), Vector3.new(0.8, 0.8, 0.8), rgb(230, 190, 70), { forme = Enum.PartType.Ball, matiere = Enum.Material.Metal, decor = true })
```

par :

```lua
	bloc(modele, origine, "Clochette", Vector3.new(-9, 3.4, 36.5), Vector3.new(0.8, 0.8, 0.8), rgb(230, 190, 70), { forme = Enum.PartType.Ball, matiere = Enum.Material.Metal, decor = true })
	bloc(modele, origine, "BoiteAuxLettres", Boutique.BOITE_AUX_LETTRES.Position, Vector3.new(0.7, 0.8, 1), rgb(70, 110, 170), { matiere = Enum.Material.Metal, decor = true })
```

Dans `src/client/Atelier/Scene.luau`, remplacer :

```lua
function Scene:synchroniser(etat, derniere)
	self:suivreCliente(etat, derniere)
```

par :

```lua
-- Une lettre dépasse de la boîte aux lettres du comptoir tant que le courrier en contient
function Scene:montrerCourrier(nombre)
	local lettre = self.dossier:FindFirstChild("Lettre")
	if nombre > 0 and not lettre then
		lettre = Instance.new("Part")
		lettre.Name = "Lettre"
		lettre.Anchored, lettre.CanCollide, lettre.CastShadow = true, false, false
		lettre.Size = Vector3.new(0.05, 0.45, 0.7)
		lettre.Color = Color3.fromRGB(250, 246, 236)
		lettre.CFrame = self.origine * Boutique.BOITE_AUX_LETTRES * CFrame.new(0, 0.55, 0)
		lettre.Parent = self.dossier
	elseif nombre == 0 and lettre then
		lettre:Destroy()
	end
end

function Scene:synchroniser(etat, derniere)
	self:suivreCliente(etat, derniere)
	self:montrerCourrier(etat.lettres and #etat.lettres or 0)
```

Dans `src/shared/Deblocages.luau`, remplacer :

```lua
-- Ce qui est ouvert, par genre : { variantes = { [id] = true }, tissus = …, accessoires = … }
```

par :

```lua
-- Ce que l'amitié d'une cliente ouvrira ensuite : { niveau, nom }, ou nil si tout ce qu'elle ouvre l'est déjà
function Deblocages.prochainDeCliente(id, points)
	local cliente = Clientes.get(id)
	local niveau = Progression.niveauAmitie(points)
	for _, k in ipairs({ 2, 4 }) do
		local d = cliente.deblocages[k]
		if d and k > niveau then
			return { niveau = k, nom = if d.variante then Deblocages.nom("variantes", d.variante) else Deblocages.nom("accessoires", d.accessoire) }
		end
	end
	return nil
end

-- Ce qui est ouvert, par genre : { variantes = { [id] = true }, tissus = …, accessoires = … }
```

Dans `src/client/Atelier/EcranAccueil.luau`, remplacer :

```lua
-- La jauge de prestige est sous la clochette ; « Robe libre » (après deux commandes livrées) à côté.
```

par :

```lua
-- La jauge de prestige est sous la clochette ; « Robe libre » (après deux commandes livrées) et « Carnet
-- d'adresses » à côté ; le courrier (après cinq commandes livrées) en dessous, chaque lettre avec « Inviter ».
```

Dans `src/client/Atelier/EcranAccueil.luau`, remplacer :

```lua
		if r.nouveaux and #r.nouveaux > 0 then
			annonce ..= "\nNouveau : " .. Deblocages.resume(r.nouveaux) .. "."
		end
```

par :

```lua
		if r.nouveaux and #r.nouveaux > 0 then
			annonce ..= "\nNouveau : " .. Deblocages.resume(r.nouveaux) .. "."
		end
		local expeditrice = r.lettre and Clientes.get(r.lettre.cliente)
		if expeditrice then
			annonce ..= ("\nUne lettre de %s est arrivée."):format(expeditrice.nom:match("^(%S+)"))
		end
```

Dans `src/client/Atelier/EcranAccueil.luau`, remplacer :

```lua
	UiKit.texte({
		Text = "Bienvenue dans ton atelier ! Une cliente attend à la porte. Fais sonner la clochette pour "
			.. "prendre sa commande : tu dessineras la robe, achèteras le tissu, découperas, épingleras "
			.. "et coudras les pièces, puis tu la décoreras avant de la livrer.",
		TextSize = 18,
		Position = UDim2.fromOffset(0, decalage),
		Size = UDim2.new(1, 0, 0, 90),
		Parent = ctx.contenu,
	})
	local function sonner()
		local r = ctx.session:nouvelleCommande()
		if not r.ok then
			ctx.refus(r)
		elseif r.acompte and r.acompte > 0 then
			local fiche = Clientes.get(r.cliente)
			ctx.message(("%s verse un acompte de %d pièces d'or."):format(fiche and fiche.nom:match("^(%S+)") or "La cliente", r.acompte), C.ok)
		end
	end
```

par :

```lua
	-- L'explication complète tant qu'aucune robe n'est livrée, une ligne ensuite (place pour le courrier)
	local debutant = ctx.session.etat.livraisons == 0
	local hauteurIntro = if debutant then 90 else 26
	UiKit.texte({
		Name = "Intro",
		Text = if debutant
			then "Bienvenue dans ton atelier ! Une cliente attend à la porte. Fais sonner la clochette pour "
				.. "prendre sa commande : tu dessineras la robe, achèteras le tissu, découperas, épingleras "
				.. "et coudras les pièces, puis tu la décoreras avant de la livrer."
			else "Une cliente attend à la porte : fais sonner la clochette.",
		TextSize = 18,
		Position = UDim2.fromOffset(0, decalage),
		Size = UDim2.new(1, 0, 0, hauteurIntro),
		Parent = ctx.contenu,
	})
	local ligne = decalage + hauteurIntro + 20 -- la rangée des boutons
	-- Une cliente entre (clochette ou lettre) : elle verse l'acompte
	local function accueillie(r)
		if not r.ok then
			ctx.refus(r)
		elseif r.acompte and r.acompte > 0 then
			local fiche = Clientes.get(r.cliente)
			ctx.message(("%s verse un acompte de %d pièces d'or."):format(fiche and fiche.nom:match("^(%S+)") or "La cliente", r.acompte), C.ok)
		end
	end
	local function sonner()
		accueillie(ctx.session:nouvelleCommande())
	end
```

Dans `src/client/Atelier/EcranAccueil.luau`, remplacer :

```lua
		Position = UDim2.fromOffset(0, 110 + decalage),
```

par :

```lua
		Position = UDim2.fromOffset(0, ligne),
```

Dans `src/client/Atelier/EcranAccueil.luau`, remplacer :

```lua
Name = "RobeLibre", Text = "Robe libre", Position = UDim2.fromOffset(276, 110 + decalage),
```

par :

```lua
Name = "RobeLibre", Text = "Robe libre", Position = UDim2.fromOffset(276, ligne),
```

Dans `src/client/Atelier/EcranAccueil.luau`, remplacer :

```lua
Name = "ChoixTaille", BackgroundTransparency = 1, Position = UDim2.fromOffset(276, 110 + decalage),
```

par :

```lua
Name = "ChoixTaille", BackgroundTransparency = 1, Position = UDim2.fromOffset(276, ligne),
```

Dans `src/client/Atelier/EcranAccueil.luau`, remplacer :

```lua
	local y = 110 + decalage + 66
```

par :

```lua
	local y = ligne + 66
```

Dans `src/client/Atelier/EcranAccueil.luau`, remplacer :

```lua
	UiKit.creer("Frame", { Name = "Rempli", BackgroundColor3 = C.accent, BorderSizePixel = 0, Size = UDim2.fromScale(math.clamp(part, 0, 1), 1), Parent = fond })
```

par :

```lua
	UiKit.creer("Frame", { Name = "Rempli", BackgroundColor3 = C.accent, BorderSizePixel = 0, Size = UDim2.fromScale(math.clamp(part, 0, 1), 1), Parent = fond })
	-- Le courrier : chaque lettre annonce la première exigence de la commande ; « Inviter » fait venir la cliente
	if etat.livraisons >= EtatAtelier.COURRIER_APRES then
		UiKit.texte({ Name = "Courrier", Text = if #etat.lettres > 0 then "Courrier :" else "Courrier : pas de lettre pour l'instant.", Font = Enum.Font.GothamBold, Position = UDim2.fromOffset(0, y + 50), Size = UDim2.fromOffset(500, 22), Parent = ctx.contenu })
		for i, l in ipairs(etat.lettres) do
			local fiche = Clientes.get(l.cliente)
			local yl = y + 76 + (i - 1) * 40
			UiKit.texte({ Name = "Lettre" .. i, Text = ("%s : « %s »"):format(fiche.nom:match("^(%S+)"), UiKit.exigence(l.commande.exigences[1], Catalogue)), TextSize = 16, Position = UDim2.fromOffset(0, yl + 6), Size = UDim2.fromOffset(600, 22), Parent = ctx.contenu })
			UiKit.boutonDoux({ Name = "Inviter_" .. i, Text = "Inviter", TextSize = 16, Position = UDim2.fromOffset(610, yl), Size = UDim2.fromOffset(120, 34), Parent = ctx.contenu }, function()
				accueillie(ctx.session:inviter(i))
			end)
		end
	end
	-- Le carnet d'adresses : les clientes déjà venues, leur amitié, et ce que le prochain niveau ouvrira
	local venues = {}
	for _, c in ipairs(Clientes.LISTE) do
		local f = etat.clientes[c.id]
		if f and f.vues > 0 then
			table.insert(venues, { cliente = c, fiche = f })
		end
	end
	if #venues > 0 then
		local carnet = UiKit.arrondir(UiKit.creer("TextButton", { Name = "CarnetAdresses", Text = "", AutoButtonColor = false, Visible = false, BackgroundColor3 = C.panneau, Size = UDim2.fromScale(1, 1), ZIndex = 20, Parent = ctx.contenu }), 10)
		UiKit.texte({ Text = "Carnet d'adresses", Font = Enum.Font.GothamBold, Size = UDim2.new(1, -130, 0, 34), ZIndex = 21, Parent = carnet })
		UiKit.boutonDoux({ Name = "FermerCarnetAdresses", Text = "Fermer", TextSize = 14, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -6, 0, 0), Size = UDim2.fromOffset(110, 34), ZIndex = 21, Parent = carnet }, function()
			carnet.Visible = false
		end)
		for k, v in ipairs(venues) do
			local niveau = Progression.niveauAmitie(v.fiche.amitie)
			local seuil = Progression.SEUILS_AMITIE[niveau + 2]
			local points = if seuil then ("%d / %d"):format(v.fiche.amitie, seuil) else ("%d, au plus haut"):format(v.fiche.amitie)
			local prochain = Deblocages.prochainDeCliente(v.cliente.id, v.fiche.amitie)
			local ouvre = if prochain then ("prochain : %s (niveau %d)"):format(prochain.nom, prochain.niveau) else "tout ce qu'elle ouvre est ouvert"
			UiKit.texte({
				Name = "Adresse_" .. v.cliente.id,
				Text = ("%s — amitié niveau %d (%s) · %s"):format(v.cliente.nom, niveau, points, ouvre),
				TextSize = 16,
				Position = UDim2.fromOffset(0, 44 + (k - 1) * 34),
				Size = UDim2.new(1, 0, 0, 30),
				ZIndex = 21,
				Parent = carnet,
			})
		end
		UiKit.boutonDoux({ Name = "OuvrirCarnetAdresses", Text = "Carnet d'adresses", Position = UDim2.fromOffset(492, ligne), Size = UDim2.fromOffset(220, 50), Parent = ctx.contenu }, function()
			carnet.Visible = true
		end)
	end
```

Dans `src/client/Atelier/EcranAccueil.luau`, remplacer :

```lua
local EtatAtelier = require(Couture:WaitForChild("EtatAtelier"))
```

par :

```lua
local EtatAtelier = require(Couture:WaitForChild("EtatAtelier"))
local Catalogue = require(Couture:WaitForChild("Catalogue"))
```

Dans `src/client/Atelier/init.client.luau`, remplacer :

```lua
vendre = "achat", offrir = "reussite" }
```

par :

```lua
vendre = "achat", offrir = "reussite", inviter = "clochette" }
```

- [ ] **Step 4: Lancer les tests**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT"`
Expected:
```
Unitaires : 107395 vérifications
TOUT EST VERT : 632 vérifications
```

- [ ] **Step 5: Commit**

```bash
git add src/shared/Boutique.luau src/server/Boutiques.luau src/shared/Deblocages.luau src/client/Atelier/Scene.luau src/client/Atelier/EcranAccueil.luau src/client/Atelier/init.client.luau tests/unitaires/45_deblocages.luau tests/scenario.luau
git commit -m "Courrier à l'accueil, carnet d'adresses, une lettre dans la boîte du comptoir

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 3: L'équilibrage avec le courrier

Test de caractérisation : il passe dès qu'il est écrit ; la préparation a vérifié qu'il échoue quand le courrier ne fait venir personne (variantes ci-dessus).

**Files:**
- Modify: `tests/unitaires/48_equilibrage.luau`

**Interfaces:**
- Consumes: `livrer(rng)`, `vendre(rng)`, `inviter`, `lettres` (tâche 1).
- Produces: la ligne « Équilibrage : … » (avec les commandes venues par lettre).

- [ ] **Step 1: Modifier la simulation**

Dans `tests/unitaires/48_equilibrage.luau`, remplacer :

```lua
-- Une robe sur quatre (dès que les robes libres sont ouvertes) : une robe libre en toile de jute, vendue.
```

par :

```lua
-- Une robe sur quatre (dès que les robes libres sont ouvertes) : une robe libre en toile de jute, vendue.
-- Le courrier : quand une lettre attend, le joueur invite sa cliente (la moins avancée en amitié d'abord) au
-- lieu de sonner la clochette.
```

Dans `tests/unitaires/48_equilibrage.luau`, remplacer :

```lua
local plusPauvre, livrees, commandes, vendues = math.huge, 0, 0, 0
```

par :

```lua
local plusPauvre, livrees, commandes, vendues, invitees = math.huge, 0, 0, 0, 0
```

Dans `tests/unitaires/48_equilibrage.luau`, remplacer :

```lua
		assert(e:vendre().ok)
```

par :

```lua
		assert(e:vendre(rng).ok)
```

Dans `tests/unitaires/48_equilibrage.luau`, remplacer :

```lua
	commandes += 1
	assert(e:nouvelleCommande(rng).ok)
```

par :

```lua
	commandes += 1
	local lettre
	for i, l in ipairs(e.lettres) do
		if not lettre or e.clientes[l.cliente].amitie < e.clientes[e.lettres[lettre].cliente].amitie then
			lettre = i
		end
	end
	if lettre then
		assert(e:inviter(lettre).ok)
		invitees += 1
	else
		assert(e:nouvelleCommande(rng).ok)
	end
```

Dans `tests/unitaires/48_equilibrage.luau`, remplacer :

```lua
		reussie = e:livrer().reussie
```

par :

```lua
		reussie = e:livrer(rng).reussie
```

Dans `tests/unitaires/48_equilibrage.luau`, remplacer :

```lua
livrees = livrees, commandes = commandes, vendues = vendues }
```

par :

```lua
livrees = livrees, commandes = commandes, vendues = vendues, invitees = invitees }
```

Dans `tests/unitaires/48_equilibrage.luau`, remplacer :

```lua
local bilan = ("%d parties de %d robes, une robe libre de jute vendue sur quatre : prestige 2 à la robe %s au plus tard ; 5 de la %s à la %s (médiane %s) ; tout ouvert de la %s à la %s (médiane %s) ; au plus bas %d po"):format(PARTIES, ROBES, texte(p2[#p2]), texte(p5[1]), texte(p5[#p5]), texte(medianeP5), texte(tout[1]), texte(tout[#tout]), texte(medianeTout), pauvres[1])
```

par :

```lua
local invitees, medianeInvitees = serie("invitees")
local bilan = ("%d parties de %d robes, une robe libre de jute vendue sur quatre, %s commandes par lettre (médiane) : prestige 2 à la robe %s au plus tard ; 5 de la %s à la %s (médiane %s) ; tout ouvert de la %s à la %s (médiane %s) ; au plus bas %d po"):format(PARTIES, ROBES, texte(medianeInvitees), texte(p2[#p2]), texte(p5[1]), texte(p5[#p5]), texte(medianeP5), texte(tout[1]), texte(tout[#tout]), texte(medianeTout), pauvres[1])
```

Dans `tests/unitaires/48_equilibrage.luau`, remplacer :

```lua
U.verifier(pauvres[1] >= robeSimple,
```

par :

```lua
U.verifier(medianeInvitees >= 10, "le courrier fait venir des clientes (" .. bilan .. ")")
U.verifier(pauvres[1] >= robeSimple,
```

- [ ] **Step 2: Lancer les tests**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Équilibrage|Unitaires|ÉCHEC|TOUT"`
Expected:
```
Équilibrage : 20 parties de 90 robes, une robe libre de jute vendue sur quatre, 40 commandes par lettre (médiane) : prestige 2 à la robe 3 au plus tard ; 5 de la 17 à la 23 (médiane 19) ; tout ouvert de la 51 à la 82 (médiane 62) ; au plus bas 241 po
Unitaires : 107396 vérifications
TOUT EST VERT : 632 vérifications
```

- [ ] **Step 3: Commit**

```bash
git add tests/unitaires/48_equilibrage.luau
git commit -m "Équilibrage avec le courrier : le joueur simulé invite les lettres

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 4: Vérification dans Studio et README

**Files:**
- Modify: `README.md`
- Modify: `AtelierCouture.rbxl` (régénéré)

**Interfaces:**
- Consumes: tout ce qui précède.
- Produces: le sous-projet 2 terminé côté code.

- [ ] **Step 1: En Play, par le connecteur MCP**

Construire le lieu du dépôt dans un dossier temporaire (`C:/dev/jeux/roblox-maker/rojo.exe build -o <dossier temporaire>/Plan5dDepot.rbxl`), l'ouvrir dans Studio, lancer Play et attendre 4 s. Puis :

1. Côté client (`execute_luau`), lire le texte `Intro` de l'accueil, et chercher `Courrier` et `OuvrirCarnetAdresses`.
2. Côté serveur, lire la position de `BoiteAuxLettres` de `workspace.Rue.Boutique_1` dans le repère `Boutique.emplacement(1)`.
3. Relever les alertes (`get_console_output`).

Expected :
- la longue explication de l'accueil ; ni courrier ni carnet d'adresses (aucune livraison, aucune cliente) ;
- boîte aux lettres vers (−9 ; 3,4 ; 40), sur le comptoir ;
- aucune alerte de notre code (« Lieu non publié » et les messages internes de Roblox mis à part).

Le courrier et le carnet d'adresses remplis, qui demandent cinq commandes livrées, sont joués par le scénario. Arrêter Play et fermer cette fenêtre de Studio (sans enregistrer).

- [ ] **Step 2: À faire par le commanditaire**

- jouer jusqu'au courrier (cinq commandes livrées), inviter une lettre, ouvrir le carnet d'adresses ;
- regarder la boîte aux lettres sur le comptoir et la lettre qui en dépasse.

Les noter dans le message de fin, sans bloquer le plan.

- [ ] **Step 3: Mettre à jour le README**

Dans `README.md`, remplacer :

```markdown
## État actuel (sous-projet 2 en cours : plans 5a à 5c, les clientes, le prestige, les déblocages et les robes libres)
```

par :

```markdown
## État actuel (sous-projet 2 terminé côté code, plans 5a à 5d : clientes, prestige, déblocages, robes libres, courrier)
```

Dans `README.md`, remplacer :

```markdown
   **Équilibrage** (simulé par les tests, sur vingt parties) : un joueur moyen (qualité 0,8, une robe libre de
   jute vendue sur quatre robes) atteint le prestige 2 à la 3e robe au plus tard, le 5 vers la 19e, et tout est
   ouvert vers la 61e (médianes).
9. La suite : courrier et carnet d'adresses (plan 5d).
```

par :

```markdown
   **Courrier** (après cinq commandes livrées) : une lettre arrive toutes les deux robes livrées ou vendues, d'une
   cliente déjà venue, et dépasse de la boîte aux lettres du comptoir ; l'accueil montre jusqu'à trois lettres,
   chacune avec la première exigence de la commande qu'elle annonce. « Inviter » fait venir la cliente avec cette
   commande ; livrée et acceptée, elle rapporte un point d'amitié de plus. Les lettres n'expirent pas.
   **Carnet d'adresses** : les clientes déjà venues, leur niveau d'amitié (points et seuil suivant) et ce que
   le prochain niveau ouvrira.
   **Équilibrage** (simulé par les tests, sur vingt parties) : un joueur moyen (qualité 0,8, une robe libre de
   jute vendue sur quatre robes, les lettres invitées) atteint le prestige 2 à la 3e robe au plus tard, le 5 vers
   la 19e, et tout est ouvert vers la 62e (médianes).
9. La suite : sous-projet 3 (histoire, dialogues, événements, nom définitif du jeu), puis sous-projet 4 (porter
   la robe, défilés).
```

Dans `README.md`, remplacer :

```markdown
  | `Deblocages` | Ce qui est fermé au départ et ce qui l'ouvre (prestige, amitié) ; ce qu'une livraison vient d'ouvrir |
```

par :

```markdown
  | `Deblocages` | Ce qui est fermé au départ et ce qui l'ouvre (prestige, amitié) ; ce qu'une livraison vient d'ouvrir ; ce que l'amitié d'une cliente ouvrira ensuite |
```

- [ ] **Step 4: Tests, lieu régénéré, commit**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT"`
Expected:
```
Unitaires : 107396 vérifications
TOUT EST VERT : 632 vérifications
```

```bash
C:/dev/jeux/roblox-maker/rojo.exe build -o AtelierCouture.rbxl
git add README.md AtelierCouture.rbxl
git commit -m "Plan 5d terminé : sous-projet 2 (clientes et progression) complet

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```
