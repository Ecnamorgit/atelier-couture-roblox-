# Aiguille & Dentelle — Plan 23 : des robes plus riches (étages, jupon, ceinture, traîne)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ajouter au carnet la jupe à étages, la jupe à jupon, le corsage ceinturé et la jupe à traîne : chaque pièce se coupe, s'épingle, se coud et se voit sur le mannequin, sans qu'une couche traverse celle du dessous.

**Architecture:** De nouvelles pièces et variantes dans `Catalogue` (aucune variante existante ne change de pièces), leurs dessins dans `Croquis`, leur prestige dans `Deblocages`. `Patron` pose une couche de corsage par-dessus le corsage (la ceinture) et couche une traîne à plat passé le sol. La table de découpe propose la place que prévoit le métrage conseillé tant que le joueur suit ses propositions (les larges étages tiennent alors dans la longueur conseillée).

**Tech Stack:** Luau, Rojo 7.7.0-rc.1, simulation Luau 0.650 (`tests/lancer.sh`), Roblox Studio via le connecteur MCP Studio.

**Spec:** `docs/superpowers/specs/2026-09-30-robes-gouts-design.md` (section 2, « Robes plus riches » : traîne, ceinture, couches ; plan 23 de la section 6 ; section 5, tests).

## Décisions de ce plan

- **Jupe à étages** (prestige 5) : la jupe droite et deux étages, larges bandes froncées (9 × 3,6 dm) cousues par le haut à 3 dm sous la taille, en couche 1, qui dépassent l'ourlet de 0,6 dm ; grille 30 × 6 (31 × 7 sommets, sous le plafond de 13 × 17 d'une pièce).
- **Jupe à jupon** (prestige 7) : une jupe de dessus (évasée, 6 dm) sur un jupon légèrement froncé (6,6 dm) qui dépasse. La jupe de dessus est une demi-couche (couche 0,5 : 0,1 dm plus loin) : une basque, en couche 1, passe encore par-dessus. Les pièces de la jupe de dessus viennent d'abord dans la variante : le dessin la colorie de leur tissu.
- **Corsage ceinturé** (prestige 6) : le corsage droit et une ceinture (4,8 × 0,6 dm, poids 0,5), enroulement « corsage » en couche 1 — l'enroulement du corsage prend maintenant la couche (0,2 dm par couche, comme la jupe).
- **Jupe à traîne** (prestige 8) : un devant de jupe longue et une traîne (10 × 11 dm, coupée droit-fil : en biais, elle ne tiendrait pas dans la largeur du rouleau). Passé le sol (`Patron.SOL` = 8,9 dm sous la taille, 0,1 dm au-dessus du sol), la pièce se couche à plat et s'étend vers l'arrière d'autant plus qu'on est au milieu du dos ; son devant (une pièce à part, `traine_devant`, la forme de la jupe longue) se couche au même endroit, pour que les côtés restent cousus jusqu'en bas. Elle reste hors du socle du mannequin et sur le socle de la vitrine (4 × 4 studs).
- **Étiquettes** : étages { romantique 6, mignon 6, décontracté 2 ; journée 8, soirée 2 } ; jupon { mignon 8, romantique 6 ; soirée 6, journée 4 } ; ceinturé { chic 8, élégant 4 ; travail 8, journée 2 } ; traîne { élégant 12, romantique 6, décontracté −6 ; soirée 14 } (une jupe longue pour la chaleur).
- **Table de découpe** : un étage large pouvait se retrouver hors du métrage conseillé en suivant les propositions (la recherche d'une place libre, gloutonne, rangeait un corsage là où l'étage devait passer). Tant que la pièce choisie est la suivante de la table et que les pièces déjà coupées dans ce tissu sont à leur place prévue, la table propose la place de `Metrage.disposition` ; sinon, et sur une bande entamée, la première place libre, comme avant.
- **Plafonds** : au plus 10 pièces et 12 copies par robe (ceinturé ou à basque, manches, col, jupe à jupon ou à étages), sous les 12 et 16 de la spec. 1 260 croquis.
- **Épinglage** : les couches (étage, jupe de dessus, ceinture) viennent déjà en fin de liste (plan 20) ; aucune couche 2.
- **Relecture du plan 22** (mineur reporté) : le scénario joue une commande à occasion de bout en bout (Journée 30, jugée au serveur, affichée avec son score).
- **Vérifié pendant la préparation** : le plan a été joué entièrement sur un brouillon tiré de `main` ; neuf variantes du brouillon échouent sur la vérification qui les garde. Dans Studio : les quatre robes vues sur le mannequin (étages et ceinture, basque et jupon, traîne couchée à l'arrière) ; une robe de dix pièces (ceinturée, à étages ou à jupon) construite en 0,88 s à l'atelier, 0,79 s en vitrine.

## Global Constraints

- **Dépôt** : `C:\dev\jeux\atelier-couture`, branche `robes-riches`, créée depuis `main` (où le plan 22 est fusionné). Selon les règles du commanditaire : la branche testée et relue est fusionnée dans `main` et poussée sur GitHub.
- **Rojo** : `C:/dev/jeux/roblox-maker/rojo.exe`.
- **Contenu original** : aucun nom, texte, image ni son de *Dressmaker*.
- **Contraintes des plans précédents toujours valables** : fins de ligne LF, commits en français terminés par `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`, textes d'au moins 14 px (et aucun texte laissé à « Label »), le serveur fait foi ; aucune variante existante ne change de pièces.

## Review Focus

- **Une robe à basque et à jupon.** Attendu : la basque passe par-dessus la jupe de dessus, elle-même par-dessus le jupon. Test : `67_couches`.
- **Une cliente aux hanches larges, en jupe à traîne, exposée en vitrine.** Attendu : la traîne reste sur le socle de la vitrine. Test : `75_traine` (mesures des clientes, 1,5 dm de plus).
- **Un joueur qui ne suit pas les propositions de la table, ou coupe dans une bande entamée.** Attendu : la table propose la première place libre, comme avant. Test : `16_table_decoupe` (première pièce choisie hors ordre : en haut du rouleau), `66_table_trous`.
- **Les recettes gardées (vitrines, sauvegardes) d'avant le plan.** Attendu : elles restent valides ; aucune variante ne change de pièces. Test : `68_variantes_couches`.
- **Une robe de dix pièces à l'atelier.** Attendu : construite en moins de 1,5 s sur PC. Test : Studio (tâche 3).

---

### Task 1: Étages, jupon, ceinture

**Files:**
- Create: `tests/unitaires/74_robes_riches.luau`
- Modify: `src/shared/Patron.luau`, `src/shared/Catalogue.luau`, `src/shared/Deblocages.luau`, `src/shared/Croquis.luau`, `src/client/Atelier/TableDecoupe.luau`
- Modify: `tests/unitaires/67_couches.luau`, `tests/unitaires/68_variantes_couches.luau`, `tests/unitaires/56_croquis.luau`, `tests/unitaires/02_catalogue.luau`, `tests/unitaires/15_metrage.luau`, `tests/unitaires/45_deblocages.luau`, `tests/unitaires/16_table_decoupe.luau`

**Interfaces:**
- Consumes: l'enroulement « jupe » à couches (plan 19), `Metrage.disposition` (existant), `Croquis` avec les parties qui portent leurs pièces (plan 19).
- Produces: les pièces `etage_devant/dos`, `jupon_devant/dos`, `jupe_dessus_devant/dos`, `ceinture_devant/dos` ; les variantes `jupe_etages`, `jupe_jupon`, `corsage_ceinture` ; l'enroulement « corsage » lit `couche`.

- [ ] **Step 1: Écrire les tests**

Créer `tests/unitaires/74_robes_riches.luau` :

```lua
-- Plan 23 : la jupe à étages, la jupe à jupon, le corsage ceinturé. Chacune a ses pièces, son dessin, ses étiquettes
-- et son prestige ; une robe ceinturée à jupon se fait de bout en bout.
local Catalogue = U.module("Catalogue")
local Patron = U.module("Patron")
local Croquis = U.module("Croquis")
local Notation = U.module("Notation")
local Metrage = U.module("Metrage")
local Deblocages = U.module("Deblocages")
local EtatAtelier = U.module("EtatAtelier")

---------------------------------------------------------------------------
-- Les variantes, leurs pièces, leur prestige
---------------------------------------------------------------------------
local ATTENDUES = {
	jupe_etages = { famille = "jupe", pieces = "jupe_droite_devant,jupe_droite_dos,etage_devant,etage_dos", prestige = "Prestige 5" },
	corsage_ceinture = { famille = "corsage", pieces = "corsage_droit_devant,corsage_droit_dos,ceinture_devant,ceinture_dos", prestige = "Prestige 6" },
	jupe_jupon = { famille = "jupe", pieces = "jupe_dessus_devant,jupe_dessus_dos,jupon_devant,jupon_dos", prestige = "Prestige 7" },
}
local fautes = {}
for id, a in pairs(ATTENDUES) do
	local v = Catalogue.variante(id)
	if not (v and v.famille == a.famille and table.concat(v.pieces, ",") == a.pieces and Deblocages.raison("variantes", id) == a.prestige and v.occasion and Croquis.connue(id)) then
		table.insert(fautes, id)
	end
end
table.sort(fautes)
U.verifier(#fautes == 0, "étages (prestige 5), ceinturé (6), jupon (7) : leurs pièces, leurs occasions, leur dessin (en défaut : " .. table.concat(fautes, ", ") .. ")")
U.verifier(Catalogue.piece("ceinture_devant").poids == 0.5 and Catalogue.piece("etage_dos").poids == nil and Catalogue.piece("jupon_devant").poids == nil, "la ceinture pèse 0,5 ; l'étage et le jupon, 1")

---------------------------------------------------------------------------
-- La ceinture se pose à la taille, par-dessus le corsage ; le jupon dépasse sous la jupe de dessus
---------------------------------------------------------------------------
local M = Catalogue.TAILLES.M
local bas = Patron.point("ceinture_devant", "unique", 2.4, 0.6, M)
local haut = Patron.point("ceinture_devant", "unique", 2.4, 0, M)
U.verifier(math.abs(bas.Y) < 1e-9 and math.abs(haut.Y - 0.6) < 1e-9, ("la ceinture : de la taille à 0,6 dm au-dessus (%.2f, %.2f)"):format(bas.Y, haut.Y))
local ourletJupon = Patron.point("jupon_devant", "unique", 4, 6.6, M)
local ourletDessus = Patron.point("jupe_dessus_devant", "unique", 4, 6, M)
U.verifier(ourletJupon.Y < ourletDessus.Y - 0.5, "le jupon descend plus bas que la jupe de dessus")

---------------------------------------------------------------------------
-- Le dessin : toucher l'étage, le jupon, la ceinture choisit leurs pièces
---------------------------------------------------------------------------
local ETAGES = { corsage = "corsage_ceinture", manches = "manches_sans", col = "col_sans", jupe = "jupe_etages" }
local JUPON = { corsage = "corsage_droit", manches = "manches_sans", col = "col_sans", jupe = "jupe_jupon" }
local function toucher(croquis, x, y)
	local _, pieces = Croquis.partieA(croquis, x, y)
	return table.concat(pieces or {}, ",")
end
U.verifier(toucher(ETAGES, 50, 75) == "etage_devant,etage_dos" and toucher(ETAGES, 50, 55) == "jupe_droite_devant,jupe_droite_dos", "toucher l'étage, la jupe")
U.verifier(toucher(ETAGES, 50, 40) == "ceinture_devant,ceinture_dos" and toucher(ETAGES, 50, 30) == "corsage_droit_devant,corsage_droit_dos", "toucher la ceinture, le corps du corsage")
U.verifier(toucher(JUPON, 50, 85) == "jupon_devant,jupon_dos" and toucher(JUPON, 50, 60) == "jupe_dessus_devant,jupe_dessus_dos", "toucher le jupon qui dépasse, la jupe de dessus")

---------------------------------------------------------------------------
-- Une robe ceinturée à jupon, de bout en bout : coupée, épinglée, cousue, livrée, payée selon son poids
---------------------------------------------------------------------------
local CEINTUREE = { corsage = "corsage_ceinture", manches = "manches_ballon", col = "col_claudine", jupe = "jupe_jupon" }
local r = EtatAtelier.nouveau(3000)
U.commander(r, Random.new(23))
local ids = Patron.piecesDuCroquis(CEINTUREE)
local tissus = {}
for _, id in ipairs(ids) do
	tissus[id] = "coton_blanc"
end
assert(r:validerCroquis(CEINTUREE, tissus).ok)
local placements, longueur = Metrage.disposition(ids)
assert(placements and r:acheter("coton_blanc", longueur).ok and r:commencerDecoupe().ok)
for _, id in ipairs(ids) do
	local c = r:couper(id, placements[id])
	assert(c.ok, id .. " : " .. tostring(c.erreur))
end
for _, id in ipairs(ids) do
	assert(r:epingler(id).ok, id)
end
for _, id in ipairs(ids) do
	local _, l = Patron.trajetCouture(id)
	assert(r:rendreCouture(id, table.create(math.round(l / 0.1), 0.02), l).ok, id)
end
assert(r:decorer({}).ok)
r.commande.exigences = { { type = "qualite", valeur = 0.1 } }
local bilan = r:bilan()
local l = r:livrer()
U.verifier(#ids == 10 and l.ok and l.reussie and l.paie == Notation.paie(9, 1, bilan.qualite), ("robe ceinturée à jupon (dix pièces) livrée : payée pour un poids de 9 (%s po)"):format(tostring(l.paie)))
```

Dans `tests/unitaires/67_couches.luau`, remplacer :

```lua
local paires = { { "volant_devant", "jupe_droite_devant" }, { "volant_dos", "jupe_droite_dos" } }
```

par :

```lua
local paires = {
	{ "volant_devant", "jupe_droite_devant" }, { "volant_dos", "jupe_droite_dos" },
	-- (plan 23) l'étage sur la jupe droite, la jupe de dessus sur le jupon, la basque sur la jupe de dessus
	{ "etage_devant", "jupe_droite_devant" }, { "etage_dos", "jupe_droite_dos" },
	{ "jupe_dessus_devant", "jupon_devant" }, { "jupe_dessus_dos", "jupon_dos" },
	{ "basque_devant", "jupe_dessus_devant" }, { "basque_dos", "jupe_dessus_dos" },
}
```

Dans `tests/unitaires/67_couches.luau`, remplacer :

```lua
U.verifier(recouvertes >= #paires and #ratees == 0, ("chaque couche passe au moins 0,03 dm au-dessus de celle du dessous (%d cas ; en défaut : %s)"):format(recouvertes, table.concat(ratees, " ; ")))
```

par :

```lua
U.verifier(recouvertes >= #paires and #ratees == 0, ("chaque couche passe au moins 0,03 dm au-dessus de celle du dessous (%d cas ; en défaut : %s)"):format(recouvertes, table.concat(ratees, " ; ")))

---------------------------------------------------------------------------
-- (plan 23) La ceinture, une couche de corsage : partout, au moins 0,03 dm au-dessus du corsage droit, à la même
-- hauteur au-dessus de la taille
---------------------------------------------------------------------------
local ceintures = {}
for _, cote in ipairs({ "devant", "dos" }) do
	local dessus, dessous = "ceinture_" .. cote, "corsage_droit_" .. cote
	for nom, mesures in pairs(tailles) do
		for j = 0, 8 do
			local h = hauteur(dessus) * j / 8
			for i = 0, 16 do
				local pD = point(dessus, i / 16, 1 - h / hauteur(dessus), mesures)
				local pS = point(dessous, i / 16, 1 - h / hauteur(dessous), mesures)
				if math.abs(pD.Y - pS.Y) > 1e-9 or rayon(pD) - rayon(pS) < 0.03 then
					ceintures[dessus .. " (" .. nom .. ")"] = true
				end
			end
		end
	end
end
local listeCeintures = {}
for n in pairs(ceintures) do
	table.insert(listeCeintures, n)
end
table.sort(listeCeintures)
U.verifier(#listeCeintures == 0, "la ceinture passe au moins 0,03 dm au-dessus du corsage (en défaut : " .. table.concat(listeCeintures, " ; ") .. ")")
```

Dans `tests/unitaires/68_variantes_couches.luau`, remplacer :

```lua
	jupe_crayon = { "jupe_crayon_devant", "jupe_crayon_dos" },
}
```

par :

```lua
	jupe_crayon = { "jupe_crayon_devant", "jupe_crayon_dos" },
	-- (plan 23) celles du plan 19
	corsage_basque = { "corsage_droit_devant", "corsage_droit_dos", "basque_devant", "basque_dos" },
	jupe_volant = { "jupe_droite_devant", "jupe_droite_dos", "volant_devant", "volant_dos" },
}
```

Dans `tests/unitaires/68_variantes_couches.luau`, remplacer :

```lua
							local verifiee = (dessus:match("^basque_") and not eS.couche) or (dessus:match("^volant_") and dessous:match("^jupe_droite_"))
```

par :

```lua
							local verifiee = (dessus:match("^basque_") and not eS.couche) or (dessus:match("^volant_") and dessous:match("^jupe_droite_"))
								or (dessus:match("^etage_") and dessous:match("^jupe_droite_")) or (dessus:match("^jupe_dessus_") and dessous:match("^jupon_"))
								or (dessus:match("^basque_") and dessous:match("^jupe_dessus_"))
```

Dans `tests/unitaires/56_croquis.luau`, remplacer :

```lua
		if polygone.pieces then
			-- (sous-projet 7) une couche qui porte ses pièces, sous la taille : une basque en part, un volant plus bas
			U.verifier(b.minY >= Croquis.TAILLE - 1e-9, v.id .. " : sa couche est sous la taille")
		elseif
```

par :

```lua
		if polygone.pieces and Catalogue.piece(polygone.pieces[1]).enroulement.type == "corsage" then
			-- (plan 23) une ceinture, par-dessus le corsage, finit à la taille comme lui
			U.verifier(U.proche(b.maxY, Croquis.TAILLE), v.id .. " : sa ceinture finit à la taille")
		elseif polygone.pieces then
			-- (sous-projet 7) une couche qui porte ses pièces, sous la taille : une basque en part, un volant plus bas
			U.verifier(b.minY >= Croquis.TAILLE - 1e-9, v.id .. " : sa couche est sous la taille")
		elseif
```

Dans `tests/unitaires/02_catalogue.luau`, remplacer :

```lua
U.verifier(#Catalogue.Variantes == 21 and parFamille.corsage == 6 and parFamille.manches == 5 and parFamille.col == 4 and parFamille.jupe == 6, "21 variantes : six corsages, cinq manches, quatre cols, six jupes")
```

par :

```lua
U.verifier(#Catalogue.Variantes == 24 and parFamille.corsage == 7 and parFamille.manches == 5 and parFamille.col == 4 and parFamille.jupe == 8, "24 variantes : sept corsages, cinq manches, quatre cols, huit jupes")
```

Dans `tests/unitaires/02_catalogue.luau`, remplacer :

```lua
-- Sous-projet 7 : vingt et une variantes (six corsages, cinq manches, quatre cols, six jupes : 720 croquis)
```

par :

```lua
-- Sous-projet 7 : vingt-quatre variantes (sept corsages, cinq manches, quatre cols, huit jupes : 1 120 croquis)
```

Dans `tests/unitaires/15_metrage.luau`, remplacer :

```lua
U.verifier(n == 720, "720 croquis vérifiés (sous-projet 7 : avec le corsage à basque et la jupe à volant)")
```

par :

```lua
U.verifier(n == 1120, "1 120 croquis vérifiés (sous-projet 7 : avec les corsages à basque et ceinturé, les jupes à volant, à étages et à jupon)")
```

Dans `tests/unitaires/45_deblocages.luau`, remplacer :

```lua
U.verifier(resume6 == "Manches courtes, les crêpes (4), les organzas (4), Papillon de soie, Galon argenté", "prestige 6 en une ligne : les manches courtes, les crêpes et les organzas ensemble (" .. resume6 .. ")")
```

par :

```lua
U.verifier(resume6 == "Manches courtes, Corsage ceinturé, les crêpes (4), les organzas (4), Papillon de soie, Galon argenté", "prestige 6 en une ligne : les manches courtes, le corsage ceinturé (plan 23), les crêpes et les organzas ensemble (" .. resume6 .. ")")
```

Dans `tests/unitaires/16_table_decoupe.luau`, remplacer :

```lua
U.verifier(ok, "corsage, manche pliée et jupe dans 8 dm de lin : " .. tostring(pourquoi))
```

par :

```lua
U.verifier(ok, "corsage, manche pliée et jupe dans 8 dm de lin : " .. tostring(pourquoi))
-- (plan 23) De larges bandes, les deux étages : en suivant les propositions, la robe tient dans le métrage conseillé
local okEtages, pourquoiEtages = suivrePropositions({ corsage = "corsage_bretelles", manches = "manches_courtes", col = "col_marin", jupe = "jupe_etages" }, {
	etage_devant = "lin_bleu",
	etage_dos = "lin_bleu",
	jupe_droite_dos = "lin_bleu",
	corsage_bretelles_devant = "lin_bleu",
	corsage_bretelles_dos = "lin_bleu",
	jupe_droite_devant = "soie_rouge",
	manche_courte = "soie_rouge",
	col_marin = "coton_blanc",
})
U.verifier(okEtages, "deux étages, une jupe et un corsage dans le même lin : dans le métrage conseillé (" .. tostring(pourquoiEtages) .. ")")
```

- [ ] **Step 2: Lancer les tests, vérifier l'échec**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT|attempt|membre" | head -3`
Expected: échec : une ligne qui finit par `ÉCHEC : 24 variantes : sept corsages, cinq manches, quatre cols, huit jupes`

- [ ] **Step 3: Les pièces, les variantes, la ceinture, la table**

Dans `src/shared/Patron.luau`, remplacer :

```lua
	local phi = angleCote(e.cote, u)
	local dehors = Vector3.new(math.cos(phi), 0, math.sin(phi))
	return Vector3.new(r * EX * math.cos(phi), h, r * EZ * math.sin(phi)), dehors
end
```

par :

```lua
	r += (e.couche or 0) * Patron.ECART_COUCHE -- (plan 23) une ceinture, par-dessus le corsage
	local phi = angleCote(e.cote, u)
	local dehors = Vector3.new(math.cos(phi), 0, math.sin(phi))
	return Vector3.new(r * EX * math.cos(phi), h, r * EZ * math.sin(phi)), dehors
end
```

Dans `src/shared/Catalogue.luau`, remplacer :

```lua
local GRILLE_BASQUE = { robe = { colonnes = 12, lignes = 4 }, vitrine = { colonnes = 6, lignes = 2 } }
```

par :

```lua
local GRILLE_BASQUE = { robe = { colonnes = 12, lignes = 4 }, vitrine = { colonnes = 6, lignes = 2 } }
-- Plan 23 : un étage froncé, posé sur le bas de la jupe droite (serré comme le volant : ses fronces se voient ; 31 × 7
-- sommets, sous le plafond d'une pièce)
local GRILLE_ETAGE = { robe = { colonnes = 30, lignes = 6 }, vitrine = { colonnes = 24, lignes = 3 } }
```

Dans `src/shared/Catalogue.luau`, remplacer :

```lua
	basque_dos = { nom = "Basque dos", contour = BASQUE, coutures = { 1 }, poids = 0.5, grille = GRILLE_BASQUE,
		enroulement = { type = "jupe", cote = "dos", depart = 0, couche = 1, evasement = 0, ampleur = 0.35, fronces = 0 } },
}
```

par :

```lua
	basque_dos = { nom = "Basque dos", contour = BASQUE, coutures = { 1 }, poids = 0.5, grille = GRILLE_BASQUE,
		enroulement = { type = "jupe", cote = "dos", depart = 0, couche = 1, evasement = 0, ampleur = 0.35, fronces = 0 } },
	-- Plan 23. L'étage : une large bande froncée, cousue par le haut à 3 dm sous la taille, sur la jupe droite, qu'elle
	-- dépasse de 0,6 dm
	etage_devant = { nom = "Étage devant", contour = rectangle(9, 3.6), coutures = { 1 }, grille = GRILLE_ETAGE,
		enroulement = { type = "jupe", cote = "devant", depart = 3, couche = 1, evasement = 0.03, ampleur = 0.2, fronces = 0.3 } },
	etage_dos = { nom = "Étage dos", contour = rectangle(9, 3.6), coutures = { 1 }, grille = GRILLE_ETAGE,
		enroulement = { type = "jupe", cote = "dos", depart = 3, couche = 1, evasement = 0.03, ampleur = 0.2, fronces = 0.3 } },
	-- Le jupon, légèrement froncé, dépasse de 0,6 dm sous la jupe de dessus ; celle-ci est une demi-couche (0,1 dm plus
	-- loin) : une basque passe encore par-dessus
	jupon_devant = { nom = "Jupon devant", contour = rectangle(8, 6.6), coutures = { 1, 2, 4 },
		enroulement = { type = "jupe", cote = "devant", evasement = 0.3, fronces = 0.1 } },
	jupon_dos = { nom = "Jupon dos", contour = rectangle(8, 6.6), coutures = { 1, 2, 4 },
		enroulement = { type = "jupe", cote = "dos", evasement = 0.3, fronces = 0.1 } },
	jupe_dessus_devant = { nom = "Jupe de dessus devant", contour = rectangle(8, 6), coutures = { 1, 2, 4 },
		enroulement = { type = "jupe", cote = "devant", couche = 0.5, evasement = 0.3, fronces = 0 } },
	jupe_dessus_dos = { nom = "Jupe de dessus dos", contour = rectangle(8, 6), coutures = { 1, 2, 4 },
		enroulement = { type = "jupe", cote = "dos", couche = 0.5, evasement = 0.3, fronces = 0 } },
	-- La ceinture : une bande de corsage à la taille (0,6 dm de haut), par-dessus le corsage, cousue par le bas
	ceinture_devant = { nom = "Ceinture devant", contour = rectangle(4.8, 0.6), coutures = { 3 }, poids = 0.5,
		enroulement = { type = "corsage", cote = "devant", couche = 1 } },
	ceinture_dos = { nom = "Ceinture dos", contour = rectangle(4.8, 0.6), coutures = { 3 }, poids = 0.5,
		enroulement = { type = "corsage", cote = "dos", couche = 1 } },
}
```

Dans `src/shared/Catalogue.luau`, remplacer :

```lua
	{ id = "jupe_volant", famille = "jupe", nom = "À volant",
		pieces = { "jupe_droite_devant", "jupe_droite_dos", "volant_devant", "volant_dos" }, style = { romantique = 8, mignon = 6 },
		occasion = { journee = 6, soiree = 4 } },
}
```

par :

```lua
	{ id = "jupe_volant", famille = "jupe", nom = "À volant",
		pieces = { "jupe_droite_devant", "jupe_droite_dos", "volant_devant", "volant_dos" }, style = { romantique = 8, mignon = 6 },
		occasion = { journee = 6, soiree = 4 } },
	-- Plan 23 : la jupe à étages, la jupe à jupon (la jupe de dessus d'abord : le dessin la colorie de son tissu), le
	-- corsage ceinturé
	{ id = "jupe_etages", famille = "jupe", nom = "À étages",
		pieces = { "jupe_droite_devant", "jupe_droite_dos", "etage_devant", "etage_dos" }, style = { romantique = 6, mignon = 6, decontracte = 2 },
		occasion = { journee = 8, soiree = 2 } },
	{ id = "jupe_jupon", famille = "jupe", nom = "À jupon",
		pieces = { "jupe_dessus_devant", "jupe_dessus_dos", "jupon_devant", "jupon_dos" }, style = { mignon = 8, romantique = 6 },
		occasion = { soiree = 6, journee = 4 } },
	{ id = "corsage_ceinture", famille = "corsage", nom = "Ceinturé",
		pieces = { "corsage_droit_devant", "corsage_droit_dos", "ceinture_devant", "ceinture_dos" }, style = { chic = 8, elegant = 4 },
		occasion = { travail = 8, journee = 2 } },
}
```

Dans `src/shared/Deblocages.luau`, remplacer :

```lua
	jupe_volant = 4, -- (sous-projet 7)
	corsage_basque = 5,
```

par :

```lua
	jupe_volant = 4, -- (sous-projet 7)
	corsage_basque = 5,
	jupe_etages = 5,
	corsage_ceinture = 6,
	jupe_jupon = 7,
```

Dans `src/shared/Croquis.luau`, remplacer :

```lua
			{ { x = 55, y = 77 }, { x = 56, y = 85 } },
			{ { x = 60, y = 77 }, { x = 63, y = 85 } },
		},
	},
}
Croquis.FORMES = FORMES
```

par :

```lua
			{ { x = 55, y = 77 }, { x = 56, y = 85 } },
			{ { x = 60, y = 77 }, { x = 63, y = 85 } },
		},
	},
	-- Plan 23 : l'étage froncé sur le bas de la jupe droite ; le jupon qui dépasse sous la jupe de dessus (dessiné
	-- dessous) ; la ceinture à la taille, par-dessus le corsage
	jupe_etages = {
		parties = {
			P({ 39, 42, 61, 42, 64, 82, 36, 82 }),
			avecPieces({ "etage_devant", "etage_dos" }, P({ 37, 62, 63, 62, 70, 86, 30, 86 })),
		},
		details = { -- les fronces de l'étage
			{ { x = 42, y = 64 }, { x = 37, y = 85 } },
			{ { x = 50, y = 64 }, { x = 50, y = 85 } },
			{ { x = 58, y = 64 }, { x = 63, y = 85 } },
		},
	},
	jupe_jupon = {
		parties = {
			avecPieces({ "jupon_devant", "jupon_dos" }, P({ 30, 76, 70, 76, 73, 87, 27, 87 })),
			P({ 39, 42, 61, 42, 71, 82, 29, 82 }),
		},
	},
	corsage_ceinture = {
		parties = {
			P({ 34, 17, 41, 17, 42, 22, 58, 22, 59, 17, 66, 17, 67, 24, 65, 32, 61, 42, 39, 42, 35, 32, 33, 24 }),
			avecPieces({ "ceinture_devant", "ceinture_dos" }, P({ 38, 38, 62, 38, 61, 42, 39, 42 })),
		},
	},
}
Croquis.FORMES = FORMES
```

Dans `src/client/Atelier/TableDecoupe.luau`, remplacer :

```lua
	local coupon = self:coupon()
```

par :

```lua
	local coupon = self:coupon()
	-- (plan 23) Tant que le joueur suit les propositions (la pièce choisie est la suivante de la table, et chaque pièce
	-- déjà coupée dans ce tissu est à sa place prévue), la place que prévoit le métrage conseillé (Metrage.disposition des
	-- pièces de ce tissu) : la robe tient dans la longueur conseillée, même avec de larges bandes (des étages). Sinon, et
	-- sur une bande entamée, la première place libre
	local ids = {}
	for _, idPiece in ipairs(self.etat:piecesDuCroquis()) do
		if self.etat.tissus[idPiece] == self.tissu then
			table.insert(ids, idPiece)
		end
	end
	local prevues = Metrage.disposition(ids)
	local suivies = self:piecesRestantes()[1] == id and #coupon.trous == 0 and prevues[id] ~= nil
	for idCoupee, pose in pairs(coupon.poses) do
		local prevue = prevues[idCoupee]
		suivies = suivies and prevue ~= nil and math.abs(prevue.x - pose.x) < 1e-6 and math.abs(prevue.y - pose.y) < 1e-6 and prevue.angle == pose.angle
	end
	if suivies and coupon:verifier(id, prevues[id]) then
		self.placement = prevues[id]
		return
	end
```

- [ ] **Step 4: Lancer les tests**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT"`
Expected:
```
Unitaires : 254033 vérifications
TOUT EST VERT : 1008 vérifications
```

- [ ] **Step 5: Commit**

```bash
git add src/shared/Patron.luau src/shared/Catalogue.luau src/shared/Deblocages.luau src/shared/Croquis.luau src/client/Atelier/TableDecoupe.luau tests/unitaires/74_robes_riches.luau tests/unitaires/67_couches.luau tests/unitaires/68_variantes_couches.luau tests/unitaires/56_croquis.luau tests/unitaires/02_catalogue.luau tests/unitaires/15_metrage.luau tests/unitaires/45_deblocages.luau tests/unitaires/16_table_decoupe.luau
git commit -m "Robes plus riches : la jupe à étages, la jupe à jupon, le corsage ceinturé ; la table propose la place du métrage conseillé

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 2: La traîne

**Files:**
- Create: `tests/unitaires/75_traine.luau`
- Modify: `src/shared/Patron.luau`, `src/shared/Catalogue.luau`, `src/shared/Deblocages.luau`, `src/shared/Croquis.luau`
- Modify: `tests/unitaires/02_catalogue.luau`, `tests/unitaires/15_metrage.luau`

**Interfaces:**
- Consumes: `Mannequin.HAUTEUR_TAILLE` (9 dm), `Catalogue.STUDS_PAR_DM`, `Etiquettes.variante` (plan 21).
- Produces: `Patron.SOL` (8,9) ; le champ `traine` de l'enroulement « jupe » ; les pièces `traine_devant`, `traine_dos` ; la variante `jupe_traine`.

- [ ] **Step 1: Écrire les tests**

Créer `tests/unitaires/75_traine.luau` :

```lua
-- Plan 23 : la jupe à traîne. Côté dos, la jupe longue évasée continue au-delà du sol, à plat vers l'arrière : juste
-- au-dessus du sol, hors du socle du mannequin, dans le socle de la vitrine ; ses côtés restent cousus au devant.
local Catalogue = U.module("Catalogue")
local Patron = U.module("Patron")
local Polygone = U.module("Polygone")
local Mannequin = U.module("Mannequin")
local Croquis = U.module("Croquis")
local Deblocages = U.module("Deblocages")
local Clientes = U.module("Clientes")
local Etiquettes = U.module("Etiquettes")

local v = Catalogue.variante("jupe_traine")
U.verifier(v and table.concat(v.pieces, ",") == "traine_devant,traine_dos" and Deblocages.raison("variantes", "jupe_traine") == "Prestige 8" and Croquis.connue("jupe_traine"), "la jupe à traîne : un devant de jupe longue et la traîne ; au prestige 8 ; dessinée")
U.verifier(Patron.SOL < Mannequin.HAUTEUR_TAILLE and Mannequin.HAUTEUR_TAILLE - Patron.SOL <= 0.15, "la traîne se couche juste au-dessus du sol")

-- Les points de la traîne (grille serrée), aux mesures du catalogue et des clientes (à 1,5 dm près)
local mesuresEssai = table.clone(Catalogue.TAILLES)
for _, c in ipairs(Clientes.LISTE) do
	mesuresEssai[c.id] = c.mesures
	mesuresEssai[c.id .. " large"] = { poitrine = c.mesures.poitrine + 1.5, taille = c.mesures.taille + 1.5, hanches = c.mesures.hanches + 1.5 }
end
local contour = Catalogue.piece("traine_dos").contour
local b = Polygone.boite(contour)
local DEMI_SOCLE = 2 -- dm : rayon du socle du mannequin (4 dm de large)
local VITRINE = 2 / Catalogue.STUDS_PAR_DM -- dm : demi-largeur du socle de la vitrine (4 studs)
local bas, dedans, horsSocle, dehorsVitrine = 0, 0, {}, {}
local plusLoin = 0
for nom, m in pairs(mesuresEssai) do
	for j = 0, 44 do
		local y = b.minY + (b.maxY - b.minY) * j / 44
		local x0, x1 = Polygone.etendueLigne(contour, y)
		for i = 0, 20 do
			local p = Patron.point("traine_dos", "unique", x0 + (x1 - x0) * i / 20, y, m)
			if p.Y < -Patron.SOL + 1e-9 then
				bas += 1
				dedans += if math.abs(p.Y + Patron.SOL) < 1e-9 then 1 else 0
			end
			if p.Y < -(Mannequin.HAUTEUR_TAILLE - 0.3) and math.sqrt(p.X ^ 2 + p.Z ^ 2) < DEMI_SOCLE then
				horsSocle[nom] = true
			end
			if math.abs(p.X) > VITRINE or math.abs(p.Z) > VITRINE then
				dehorsVitrine[nom] = true
			end
			if nom == "M" then
				plusLoin = math.max(plusLoin, p.Z)
			end
		end
	end
end
local function noms(t)
	local liste = {}
	for n in pairs(t) do
		table.insert(liste, n)
	end
	table.sort(liste)
	return table.concat(liste, ", ")
end
U.verifier(bas > 0 and dedans == bas, ("au-delà du sol, la traîne est à plat, à 0,1 dm au-dessus (%d points sur %d)"):format(dedans, bas))
U.verifier(noms(horsSocle) == "", "la traîne passe hors du socle du mannequin (en défaut : " .. noms(horsSocle) .. ")")
U.verifier(noms(dehorsVitrine) == "", "la traîne reste sur le socle de la vitrine (en défaut : " .. noms(dehorsVitrine) .. ")")

-- Vers l'arrière : au milieu du dos, l'ourlet de la traîne est 2,1 dm plus loin que la jupe au sol
local M = Catalogue.TAILLES.M
local auSol = Patron.point("traine_dos", "unique", 5, Patron.SOL, M) -- (le milieu de chaque ligne de la traîne est à x = 5)
local milieu = Patron.point("traine_dos", "unique", 5, 11, M)
U.verifier(milieu.Z > auSol.Z + 2.1 * Patron.ELLIPSE.z - 0.05 and math.abs(milieu.X) < 0.05, ("la traîne s'étend vers l'arrière (%.2f dm derrière la jupe)"):format(milieu.Z - auSol.Z))

-- Ses côtés restent cousus au devant : jusqu'au sol, chaque bord de la traîne rejoint le bord du devant, qui est celui
-- de la jupe longue
local ecart = 0
for j = 0, 20 do
	local yd = 9 * j / 20 -- (jusqu'en bas du devant : passé le sol, les deux se couchent au même endroit)
	local x0, x1 = Polygone.etendueLigne(contour, yd)
	local e0, e1 = Polygone.etendueLigne(Catalogue.piece("traine_devant").contour, yd)
	local dosDroit = Patron.point("traine_dos", "unique", x0, yd, M) -- u = 0 : côté −X
	local dosGauche = Patron.point("traine_dos", "unique", x1, yd, M) -- u = 1 : côté +X
	local devantDroit = Patron.point("traine_devant", "unique", e1, yd, M)
	local devantGauche = Patron.point("traine_devant", "unique", e0, yd, M)
	if yd <= Patron.SOL then -- (au-dessus du sol, le devant est celui de la jupe longue)
		local longue = Patron.point("jupe_evasee_devant", "unique", e1, yd, M)
		ecart = math.max(ecart, (longue - devantDroit).Magnitude)
	end
	ecart = math.max(ecart, (dosDroit - devantDroit).Magnitude, (dosGauche - devantGauche).Magnitude)
end
U.verifier(ecart < 1e-6, ("les côtés de la traîne rejoignent ceux du devant (écart %.6f dm)"):format(ecart))

-- Une jupe longue : la traîne rend la robe aussi chaude qu'une jupe évasée
U.verifier(Etiquettes.variante("jupe_traine").chaleur == Etiquettes.variante("jupe_evasee").chaleur, "longueur : la traîne compte comme une jupe longue")
```

Dans `tests/unitaires/02_catalogue.luau`, remplacer :

```lua
-- Sous-projet 7 : vingt-quatre variantes (sept corsages, cinq manches, quatre cols, huit jupes : 1 120 croquis)
```

par :

```lua
-- Sous-projet 7 : vingt-cinq variantes (sept corsages, cinq manches, quatre cols, neuf jupes : 1 260 croquis)
```

Dans `tests/unitaires/02_catalogue.luau`, remplacer :

```lua
U.verifier(#Catalogue.Variantes == 24 and parFamille.corsage == 7 and parFamille.manches == 5 and parFamille.col == 4 and parFamille.jupe == 8, "24 variantes : sept corsages, cinq manches, quatre cols, huit jupes")
```

par :

```lua
U.verifier(#Catalogue.Variantes == 25 and parFamille.corsage == 7 and parFamille.manches == 5 and parFamille.col == 4 and parFamille.jupe == 9, "25 variantes : sept corsages, cinq manches, quatre cols, neuf jupes")
```

Dans `tests/unitaires/15_metrage.luau`, remplacer :

```lua
U.verifier(n == 1120, "1 120 croquis vérifiés (sous-projet 7 : avec les corsages à basque et ceinturé, les jupes à volant, à étages et à jupon)")
```

par :

```lua
U.verifier(n == 1260, "1 260 croquis vérifiés (sous-projet 7 : avec les corsages à basque et ceinturé, les jupes à volant, à étages, à jupon et à traîne)")
```

- [ ] **Step 2: Lancer les tests, vérifier l'échec**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT|attempt|membre" | head -3`
Expected: échec : une ligne qui finit par `ÉCHEC : 25 variantes : sept corsages, cinq manches, quatre cols, neuf jupes`

- [ ] **Step 3: La traîne**

Dans `src/shared/Patron.luau`, remplacer :

```lua
-- Sous-projet 7 : écart de rayon par couche (0,06 dm d'air, plus les fronces du dessous, 0,14 dm au plus)
Patron.ECART_COUCHE = 0.2
```

par :

```lua
-- Sous-projet 7 : écart de rayon par couche (0,06 dm d'air, plus les fronces du dessous, 0,14 dm au plus)
Patron.ECART_COUCHE = 0.2
-- Plan 23 : une traîne se couche 0,1 dm au-dessus du sol (le mannequin a sa taille à 9 dm du sol)
Patron.SOL = 8.9
```

Dans `src/shared/Patron.luau`, remplacer :

```lua
local function jupe(e, u, v, hauteur, m)
	local yd = (e.depart or 0) + v * hauteur
```

par :

```lua
local function jupe(e, u, v, hauteur, m)
	local yd = (e.depart or 0) + v * hauteur
	-- (plan 23) une traîne : passé le sol, la pièce se couche à plat vers l'arrière, d'autant plus loin qu'on est au
	-- milieu du dos (ses côtés restent à l'ourlet, cousus au devant, couché au même endroit)
	local aPlat = 0
	if e.traine and yd > Patron.SOL then
		aPlat, yd = yd - Patron.SOL, Patron.SOL
	end
```

Dans `src/shared/Patron.luau`, remplacer :

```lua
	r += e.fronces * v * 0.5 * (0.5 + 0.5 * math.sin(phi * 16))
	local dehors = Vector3.new(math.cos(phi), 0, math.sin(phi))
	return Vector3.new(r * EX * math.cos(phi), -yd, r * EZ * math.sin(phi)), dehors
end
```

par :

```lua
	r += e.fronces * v * 0.5 * (0.5 + 0.5 * math.sin(phi * 16))
	if aPlat > 0 then
		r += aPlat * math.max(0, math.sin(phi))
		return Vector3.new(r * EX * math.cos(phi), -yd, r * EZ * math.sin(phi)), Vector3.new(0, 1, 0)
	end
	local dehors = Vector3.new(math.cos(phi), 0, math.sin(phi))
	return Vector3.new(r * EX * math.cos(phi), -yd, r * EZ * math.sin(phi)), dehors
end
```

Dans `src/shared/Catalogue.luau`, remplacer :

```lua
-- Plan 23 : un étage froncé, posé sur le bas de la jupe droite
```

par :

```lua
-- Plan 23 : la traîne, la jupe longue évasée côté dos qui continue 2 dm au-delà du sol (coupée droit-fil : en biais,
-- elle ne tiendrait pas dans la largeur du rouleau)
local TRAINE = { { x = 3, y = 0 }, { x = 7, y = 0 }, { x = 10, y = 11 }, { x = 0, y = 11 } }
-- Plan 23 : un étage froncé, posé sur le bas de la jupe droite
```

Dans `src/shared/Catalogue.luau`, remplacer :

```lua
	ceinture_dos = { nom = "Ceinture dos", contour = rectangle(4.8, 0.6), coutures = { 3 }, poids = 0.5,
		enroulement = { type = "corsage", cote = "dos", couche = 1 } },
}
```

par :

```lua
	ceinture_dos = { nom = "Ceinture dos", contour = rectangle(4.8, 0.6), coutures = { 3 }, poids = 0.5,
		enroulement = { type = "corsage", cote = "dos", couche = 1 } },
	-- (le devant de la jupe à traîne est celui de la jupe longue, couché lui aussi passé le sol : ses côtés restent
	-- cousus à ceux de la traîne jusqu'en bas)
	traine_devant = { nom = "Jupe à traîne devant", contour = EVASEE, coutures = { 1, 2, 4 }, biais = true,
		enroulement = { type = "jupe", cote = "devant", evasement = 0.45, fronces = 0, traine = true } },
	traine_dos = { nom = "Traîne", contour = TRAINE, coutures = { 1, 2, 4 },
		enroulement = { type = "jupe", cote = "dos", evasement = 0.45, fronces = 0, traine = true } },
}
```

Dans `src/shared/Catalogue.luau`, remplacer :

```lua
	{ id = "corsage_ceinture", famille = "corsage", nom = "Ceinturé",
		pieces = { "corsage_droit_devant", "corsage_droit_dos", "ceinture_devant", "ceinture_dos" }, style = { chic = 8, elegant = 4 },
		occasion = { travail = 8, journee = 2 } },
}
```

par :

```lua
	{ id = "corsage_ceinture", famille = "corsage", nom = "Ceinturé",
		pieces = { "corsage_droit_devant", "corsage_droit_dos", "ceinture_devant", "ceinture_dos" }, style = { chic = 8, elegant = 4 },
		occasion = { travail = 8, journee = 2 } },
	{ id = "jupe_traine", famille = "jupe", nom = "À traîne",
		pieces = { "traine_devant", "traine_dos" }, style = { elegant = 12, romantique = 6, decontracte = -6 },
		occasion = { soiree = 14 } },
}
```

Dans `src/shared/Deblocages.luau`, remplacer :

```lua
	jupe_jupon = 7,
```

par :

```lua
	jupe_jupon = 7,
	jupe_traine = 8,
```

Dans `src/shared/Croquis.luau`, remplacer :

```lua
	corsage_ceinture = {
		parties = {
```

par :

```lua
	-- La traîne dépasse derrière l'ourlet de la jupe longue (dessinée dessous)
	jupe_traine = {
		parties = {
			avecPieces({ "traine_dos" }, P({ 19, 118, 81, 118, 88, 128, 12, 128 })),
			P({ 39, 42, 61, 42, 66, 60, 81, 124, 19, 124, 34, 60 }),
		},
	},
	corsage_ceinture = {
		parties = {
```

- [ ] **Step 4: Lancer les tests**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT"`
Expected:
```
Unitaires : 269386 vérifications
TOUT EST VERT : 1012 vérifications
```

- [ ] **Step 5: Commit**

```bash
git add src/shared/Patron.luau src/shared/Catalogue.luau src/shared/Deblocages.luau src/shared/Croquis.luau tests/unitaires/75_traine.luau tests/unitaires/02_catalogue.luau tests/unitaires/15_metrage.luau
git commit -m "Robes plus riches : la jupe à traîne, couchée à plat sur le sol vers l'arrière

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 3: Studio, scénario, README, lieu régénéré

**Files:**
- Modify: `tests/scenario.luau`, `README.md`, `AtelierCouture.rbxl` (régénéré)

**Interfaces:**
- Consumes: tout ce qui précède ; le type d'exigence « occasion » (plan 21) et `bilan.occasions` dans la réponse de livraison.
- Produces: rien de nouveau.

- [ ] **Step 1: Dans Studio, par le connecteur MCP**

Construire le lieu du dépôt dans un dossier temporaire (`C:/dev/jeux/roblox-maker/rojo.exe build -o <dossier temporaire>/Plan23Depot.rbxl`) et l'ouvrir dans Studio. En édition (`execute_luau`, Edit) : faire trois recettes de bout en bout avec `EtatAtelier` (prestige 530, amitiés au plus haut ; pièces posées selon `Metrage.disposition`) — corsage ceinturé, manches ballon, col Claudine, jupe à étages (étages en coton rose à pois, ceinture en velours noir, le reste en coton blanc) ; corsage à basque, sans manches ni col, jupe à jupon (jupon en tulle blanc, le reste en satin rose) ; bustier, manches longues, sans col, jupe à traîne (velours rubis) — poser chacune sur un mannequin dans un dossier d'essai, mesurer (`os.clock`) `ConstructeurRobe.construire` (finesse « robe »), regarder les robes de face puis de côté (`screen_capture`), et mesurer une robe de dix pièces (ceinturée à jupon) en finesse « vitrine ». Supprimer le dossier d'essai. Puis en Play : attendre 4 s, relever la console.

Expected : étages, jupon qui dépasse, ceinture noire à la taille, traîne couchée vers l'arrière, sans pièce qui en traverse une autre ; une robe de dix pièces sous 1,5 s (0,88 s à l'atelier et 0,79 s en vitrine pendant la préparation) ; aucune alerte de notre code (« Lieu non publié » et les messages internes de Roblox mis à part). Arrêter Play et fermer cette fenêtre de Studio (sans enregistrer).

- [ ] **Step 2: Une commande à occasion dans le scénario (relecture du plan 22)**

La couverture d'une fonction du plan 22 : le test passe d'emblée.

Dans `tests/scenario.luau`, remplacer :

```lua
-- La cliente veut une croix d'argent : sans elle, la robe sera refusée (posé sur le serveur, qui juge
-- la robe, et sur la copie du client, qui affiche la commande)
local function exigencesTest()
	return { { type = "accessoire", id = "croix_argent" }, { type = "min", style = "romantique", valeur = 1 } }
end
```

par :

```lua
-- La cliente veut une croix d'argent : sans elle, la robe sera refusée (posé sur le serveur, qui juge
-- la robe, et sur la copie du client, qui affiche la commande). (Relecture du plan 22 : et une robe pour la journée, 30
-- au moins ; la robe en soie rose fleurie en a 32)
local function exigencesTest()
	return { { type = "accessoire", id = "croix_argent" }, { type = "min", style = "romantique", valeur = 1 }, { type = "occasion", occasion = "journee", valeur = 30 } }
end
```

Dans `tests/scenario.luau`, remplacer :

```lua
verifier(texte("Au moins 1 en Romantique (actuel :") ~= nil, "le score actuel est affiché à côté d'une exigence de style")
```

par :

```lua
verifier(texte("Au moins 1 en Romantique (actuel :") ~= nil, "le score actuel est affiché à côté d'une exigence de style")
verifier(texte("Pour la journée : au moins 30 (actuel : 32)") ~= nil, "une exigence d'occasion, avec le score actuel de la robe")
```

Dans `tests/scenario.luau`, remplacer :

```lua
verifier(titre() == "Aiguille & Dentelle" and argent() > avantLivraison, "robe acceptée : payée")
```

par :

```lua
verifier(titre() == "Aiguille & Dentelle" and argent() > avantLivraison, "robe acceptée : payée")
verifier(requireModule(scriptClient.Session).courante.derniere.reponse.bilan.occasions.journee >= 30, "la cliente a jugé l'occasion (robe pour la journée)")
```

- [ ] **Step 3: Mettre à jour le README**

Dans `README.md`, remplacer :

```markdown
## État actuel (sous-projet 7 en cours, plans 19 à 22 : des robes à couches, volant et basque ; seize étiquettes)
```

par :

```markdown
## État actuel (sous-projet 7 en cours, plans 19 à 23 : des robes plus riches, à couches ; seize étiquettes)
```

Dans `README.md`, remplacer :

```markdown
   (corsage, col, manches, jupe) : ◀ le nom du modèle ▶ et un point par modèle (21 variantes : six corsages dont
   le cache-cœur, le bustier et le corsage à basque, cinq manches, quatre cols dont le col marin, six jupes dont la
   jupe crayon et la jupe à volant). **Des couches** : la basque s'évase sous la taille, par-dessus la jupe ; le
   volant, froncé, part à 5 dm sous la taille et dépasse l'ourlet ; chacun a ses pièces (poids 0,5 dans la paie),
   son tissu et sa partie du dessin (la toucher choisit le tissu de ses pièces). La liste des pièces défile.
```

par :

```markdown
   (corsage, col, manches, jupe) : ◀ le nom du modèle ▶ et un point par modèle (25 variantes : sept corsages dont
   le cache-cœur, le bustier, le corsage à basque et le corsage ceinturé, cinq manches, quatre cols dont le col
   marin, neuf jupes dont la jupe crayon et les jupes à volant, à étages, à jupon et à traîne). **Des couches** : la
   basque s'évase sous la taille, par-dessus la jupe ; le volant, froncé, part à 5 dm sous la taille et dépasse
   l'ourlet ; l'étage, une large bande froncée, couvre le bas de la jupe droite ; le jupon dépasse sous la jupe de
   dessus ; la ceinture se pose à la taille, par-dessus le corsage ; la traîne continue la jupe longue à plat sur
   le sol, vers l'arrière. Chacun a ses pièces (volant, basque et ceinture : poids 0,5 dans la paie), son tissu et
   sa partie du dessin (la toucher choisit le tissu de ses pièces). La liste des pièces défile.
```

Dans `README.md`, remplacer :

```markdown
   pièces pliées coupées en double au pli, chevauchements refusés, place proposée ; une ligne marque le tissu
```

par :

```markdown
   pièces pliées coupées en double au pli, chevauchements refusés, place proposée (tant qu'on suit les propositions,
   celle que prévoit le métrage conseillé : la robe y tient, même avec de larges étages) ; une ligne marque le tissu
```

- [ ] **Step 4: Tests, lieu régénéré, commit**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT"`
Expected:
```
Unitaires : 269386 vérifications
TOUT EST VERT : 1014 vérifications
```

```bash
C:/dev/jeux/roblox-maker/rojo.exe build -o AtelierCouture.rbxl
git add tests/scenario.luau README.md AtelierCouture.rbxl
git commit -m "Plan 23 terminé : des robes plus riches ; le scénario joue une commande à occasion

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```
