# Aiguille & Dentelle — Plan 20 : la chaîne des couches

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Finir le passage des robes à couches dans l'atelier : épingler les couches par-dessus les autres pièces, garder les manches hors des couches, et mesurer la construction des robes riches.

**Architecture:** `EcranEpinglage` range les couches (volant, basque) en fin de liste ; un test garde les manches au-dehors des couches pour les tailles du catalogue et les mesures des clientes ; les commentaires restés d'avant les couches sont remis à jour. Les mesures de construction (atelier et vitrine) sont faites dans Studio.

**Tech Stack:** Luau, Rojo 7.7.0-rc.1, simulation Luau 0.650 (`tests/lancer.sh`), Roblox Studio via le connecteur MCP Studio.

**Spec:** `docs/superpowers/specs/2026-09-30-robes-gouts-design.md` (section 2, « Chaîne et performance » ; plan 20 de la section 6).

## Décisions de ce plan

- **Ce que la spec prévoyait et qui marche déjà** : les bandes larges trouvent leur place à la table et dans le métrage conseillé (les 720 croquis sont vérifiés par `15_metrage`) ; la machine coud une pièce d'un seul bord (comme les cols) ; les listes de pièces de la découpe et de la couture défilent (relecture du plan 19) ; les vitrines ont des images réduites (128 px) et une construction étalée.
- **Plafond 12 pièces / 16 copies** : gardé par le catalogue (`68_variantes_couches` vérifie tous les croquis : 10 et 12 au plus), pas par `Recette.valider` : les pièces d'une recette sont celles de son croquis, un plafond de plus n'y verrait jamais rien.
- **Épinglage** : les couches en fin de liste (un volant épinglé avant sa jupe flottait autour des jambes du mannequin) ; l'ordre reste libre.
- **Manches et couches** : aux silhouettes extrêmes qu'accepte une recette (poitrine 7, hanches 14), une manche longue croise la basque ; ces silhouettes n'existent pas en jeu (mesures des clientes, à 1,5 dm près). Le test garde les tailles du catalogue et les mesures des clientes.
- **Écart des couches** : gardé à 0,2 dm (une épaisseur visible, et la place qu'il faudra aux étages et jupons du plan 23 sur une jupe froncée).
- **Performance** (mesurée dans Studio pendant la préparation, sur PC) : robe à dix pièces 964 ms à l'atelier, 949 ms en vitrine ; robe à six pièces 648 et 533 ms. Images (1 à 5 ms par pièce) et maillages (1 à 3 ms) ne pèsent presque rien : le temps va à la création des pièces 3D par le moteur, que les vitrines étalent déjà sur plusieurs images. Sur téléphone : à mesurer par le commanditaire.
- **Vérifié pendant la préparation** : le plan a été joué entièrement sur un brouillon tiré de `main` ; deux variantes du brouillon (ordre du croquis, couches collées) échouent sur la vérification qui les garde ; avec les silhouettes extrêmes, le test des manches trouve bien le croisement.

## Global Constraints

- **Dépôt** : `C:\dev\jeux\atelier-couture`, branche `chaine-couches`, créée depuis `main` (où le plan 19 est fusionné). Selon les règles du commanditaire : la branche testée et relue est fusionnée dans `main` et poussée sur GitHub.
- **Rojo** : `C:/dev/jeux/roblox-maker/rojo.exe`.
- **Contenu original** : aucun nom, texte, image ni son de *Dressmaker*.
- **Contraintes des plans précédents toujours valables** : fins de ligne LF, commits en français terminés par `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`, textes d'au moins 14 px (et aucun texte laissé à « Label »), le serveur fait foi.

## Review Focus

- **Une robe sans couche.** Attendu : l'épinglage garde l'ordre du croquis. Test : scénario (la robe du scénario, sans couche, s'épingle comme avant).
- **Une robe à couches.** Attendu : basque et volant en fin de liste. Test : `69_ecrans_dix_pieces`.
- **Une cliente aux mesures les plus larges.** Attendu : ses manches restent au-dehors de la basque. Test : `67_couches` (mesures des clientes).

---

### Task 1: Épingler les couches par-dessus ; les manches au-dehors

**Files:**
- Modify: `src/client/Atelier/EcranEpinglage.luau`, `src/shared/Commandes.luau` (commentaire), `src/shared/EtatAtelier.luau` (commentaire)
- Modify: `tests/unitaires/69_ecrans_dix_pieces.luau`, `tests/unitaires/67_couches.luau`, `tests/unitaires/02_catalogue.luau` (commentaire)

**Interfaces:**
- Consumes: `enroulement.couche` des pièces (plan 19) ; `Patron.ELLIPSE` (plan 19).
- Produces: dans l'écran d'épinglage, les cartes `Epingler_<id>` rangées : pièces du dessous, puis couches.

- [ ] **Step 1: Écrire les tests**

Dans `tests/unitaires/69_ecrans_dix_pieces.luau`, remplacer :

```lua
local EcranCouture = U.module("EcranCouture")
```

par :

```lua
local EcranCouture = U.module("EcranCouture")
local EcranEpinglage = U.module("EcranEpinglage")
```

Dans `tests/unitaires/69_ecrans_dix_pieces.luau`, remplacer :

```lua
for _, id in ipairs(ids) do
	assert(session:couper(id, placements[id]).ok, id)
end
```

par :

```lua
for _, id in ipairs(ids) do
	assert(session:couper(id, placements[id]).ok, id)
end

-- (plan 20) L'épinglage : les couches (basque, volant) en fin de liste, elles se posent par-dessus les autres pièces
local ctx3 = contexte()
local fermer3 = EcranEpinglage(ctx3)
local cartes = {}
for _, c in ipairs(ctx3.contenu.Liste:GetChildren()) do
	if c.Name:sub(1, 9) == "Epingler_" then
		table.insert(cartes, c)
	end
end
table.sort(cartes, function(a, b)
	return a.Position.Y.Offset < b.Position.Y.Offset
end)
local ordre = {}
for _, c in ipairs(cartes) do
	table.insert(ordre, (c.Name:gsub("^Epingler_", "")))
end
U.verifier(#ordre == 10 and table.concat(ordre, ",", 7) == "basque_devant,basque_dos,volant_devant,volant_dos", "épinglage : les couches en fin de liste (" .. table.concat(ordre, ", ") .. ")")
fermer3()
```

Dans `tests/unitaires/67_couches.luau`, remplacer :

```lua
---------------------------------------------------------------------------
-- Une grille propre à la pièce
```

par :

```lua
---------------------------------------------------------------------------
-- (plan 20) Les manches passent au-dehors des couches, pour les tailles du catalogue et les mesures des clientes (les
-- silhouettes extrêmes ci-dessus n'existent pas en jeu : poitrine 7 et hanches 14, une manche longue croise la basque)
---------------------------------------------------------------------------
local Clientes = U.module("Clientes")
local reelles = table.clone(Catalogue.TAILLES)
for _, c in ipairs(Clientes.LISTE) do
	reelles[c.id] = c.mesures
end
local couches = {}
for id, def in pairs(Catalogue.Pieces) do
	if def.enroulement.type == "jupe" and def.enroulement.couche then
		couches[def.enroulement.cote] = couches[def.enroulement.cote] or {}
		table.insert(couches[def.enroulement.cote], id)
	end
end
local croisees = {}
for idManche, defManche in pairs(Catalogue.Pieces) do
	if defManche.enroulement.type == "manche" then
		local b = Polygone.boite(defManche.contour)
		for nom, mesures in pairs(reelles) do
			for j = 0, 12 do
				local y = math.min(b.minY + (b.maxY - b.minY) * j / 12, b.maxY)
				local x0, x1 = Polygone.etendueLigne(defManche.contour, y)
				for i = 0, 8 do
					local p = Patron.point(idManche, "droite", x0 + (x1 - x0) * i / 8, y, mesures)
					local yd = -p.Y
					local phi = math.atan2(p.Z / Patron.ELLIPSE.z, p.X / Patron.ELLIPSE.x) % (2 * math.pi)
					local cote = if phi >= math.pi then "devant" else "dos"
					local u = if cote == "devant" then (2 * math.pi - phi) / math.pi else (math.pi - phi) / math.pi
					for _, idCouche in ipairs(couches[cote] or {}) do
						local e = Catalogue.piece(idCouche).enroulement
						local v = (yd - (e.depart or 0)) / hauteur(idCouche)
						if v >= 0 and v <= 1 and rayon(p) < rayon(point(idCouche, math.clamp(u, 0, 1), v, mesures)) + 0.03 then
							croisees[idManche .. " dans " .. idCouche .. " (" .. nom .. ")"] = true
						end
					end
				end
			end
		end
	end
end
local listeCroisees = {}
for n in pairs(croisees) do
	table.insert(listeCroisees, n)
end
table.sort(listeCroisees)
U.verifier(#listeCroisees == 0, "les manches passent au-dehors des couches (en défaut : " .. table.concat(listeCroisees, " ; ") .. ")")

---------------------------------------------------------------------------
-- Une grille propre à la pièce
```

- [ ] **Step 2: Lancer les tests, vérifier l'échec**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT|attempt|membre" | head -3`
Expected: échec : une ligne qui finit par `ÉCHEC : épinglage : les couches en fin de liste (corsage_droit_devant, corsage_droit_dos, basque_devant, basque_dos, manche_ballon, col_claudine, jupe_droite_devant, jupe_droite_dos, volant_devant, volant_dos)`

- [ ] **Step 3: L'ordre d'épinglage, les commentaires**

Dans `src/client/Atelier/EcranEpinglage.luau`, remplacer :

```lua
-- Écran d'épinglage (panneau à droite, le mannequin à gauche) : toucher une pièce coupée l'épingle
-- à sa place sur le mannequin, dans son vrai tissu. La dernière pièce épinglée mène à la couture.
```

par :

```lua
-- Écran d'épinglage (panneau à droite, le mannequin à gauche) : toucher une pièce coupée l'épingle
-- à sa place sur le mannequin, dans son vrai tissu. La dernière pièce épinglée mène à la couture.
-- Sous-projet 7 : les couches (volant, basque) viennent en fin de liste : elles se posent par-dessus les autres.
```

Dans `src/client/Atelier/EcranEpinglage.luau`, remplacer :

```lua
	local cartes = {}
	local pieces = etat:piecesDuCroquis()
```

par :

```lua
	local cartes = {}
	local pieces = {}
	for _, dessus in ipairs({ false, true }) do
		for _, id in ipairs(etat:piecesDuCroquis()) do
			if ((Catalogue.piece(id).enroulement.couche or 0) > 0) == dessus then
				table.insert(pieces, id)
			end
		end
	end
```

Dans `src/shared/Commandes.luau`, remplacer :

```lua
-- Toutes les combinaisons de variantes du carnet (5 × 5 × 4 × 5 = 500)
```

par :

```lua
-- Toutes les combinaisons de variantes du carnet (6 × 5 × 4 × 6 = 720, depuis le sous-projet 7)
```

Dans `tests/unitaires/02_catalogue.luau`, remplacer :

```lua
-- Sous-projet 4 : dix-neuf variantes (cinq corsages, cinq manches, quatre cols, cinq jupes : 500 croquis)
```

par :

```lua
-- Sous-projet 7 : vingt et une variantes (six corsages, cinq manches, quatre cols, six jupes : 720 croquis)
```

Dans `src/shared/EtatAtelier.luau`, remplacer :

```lua
EtatAtelier.MAIN_OEUVRE = 6 -- pièces d'or par pièce posée, dans le prix de vente d'une robe libre
```

par :

```lua
EtatAtelier.MAIN_OEUVRE = 6 -- pièces d'or par pièce posée (par unité de poids : un volant compte moitié), dans le prix de vente d'une robe libre
```

- [ ] **Step 4: Lancer les tests**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT"`
Expected:
```
Unitaires : 192960 vérifications
TOUT EST VERT : 998 vérifications
```

- [ ] **Step 5: Commit**

```bash
git add src/client/Atelier/EcranEpinglage.luau src/shared/Commandes.luau src/shared/EtatAtelier.luau tests/unitaires/69_ecrans_dix_pieces.luau tests/unitaires/67_couches.luau tests/unitaires/02_catalogue.luau
git commit -m "Épinglage : les couches en fin de liste, par-dessus les autres pièces ; les manches gardées au-dehors des couches

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 2: Studio, README, lieu régénéré

**Files:**
- Modify: `README.md`, `AtelierCouture.rbxl` (régénéré)

**Interfaces:**
- Consumes: tout ce qui précède.
- Produces: rien de nouveau.

- [ ] **Step 1: Dans Studio, par le connecteur MCP**

Construire le lieu du dépôt dans un dossier temporaire (`C:/dev/jeux/roblox-maker/rojo.exe build -o <dossier temporaire>/Plan20Depot.rbxl`) et l'ouvrir dans Studio. En édition (`execute_luau`, Edit), mesurer (`os.clock`) `ConstructeurRobe.construire` d'une robe à dix pièces (corsage à basque, manches ballon, col Claudine, jupe à volant) et d'une robe à six pièces (corsage en V, manches ballon, col Claudine, jupe trapèze), en finesse « robe » puis « vitrine », chacune dans un dossier d'essai supprimé ensuite. Puis en Play : attendre 4 s, relever la console.

Expected : une robe à dix pièces sous 1,5 s en finesse « robe » ; aucune alerte de notre code (« Lieu non publié » et les messages internes de Roblox mis à part). Arrêter Play et fermer cette fenêtre de Studio (sans enregistrer).

- [ ] **Step 2: Mettre à jour le README**

Dans `README.md`, remplacer :

```markdown
## État actuel (sous-projet 7 en cours, plan 19 : des robes à couches, volant et basque)
```

par :

```markdown
## État actuel (sous-projet 7 en cours, plans 19 et 20 : des robes à couches, volant et basque)
```

Dans `README.md`, remplacer :

```markdown
5. **Épinglage** : le mannequin prend les mesures de la cliente ; chaque pièce touchée s'y épingle,
   dans le tissu exactement tel qu'il a été découpé.
```

par :

```markdown
5. **Épinglage** : le mannequin prend les mesures de la cliente ; chaque pièce touchée s'y épingle,
   dans le tissu exactement tel qu'il a été découpé. Les couches (volant, basque) viennent en fin de liste : elles se
   posent par-dessus les autres pièces.
```

- [ ] **Step 3: Tests, lieu régénéré, commit**

Run: `bash tests/lancer.sh 2>&1 | grep -E "Unitaires|ÉCHEC|TOUT"`
Expected:
```
Unitaires : 192960 vérifications
TOUT EST VERT : 998 vérifications
```

```bash
C:/dev/jeux/roblox-maker/rojo.exe build -o AtelierCouture.rbxl
git add README.md AtelierCouture.rbxl
git commit -m "Plan 20 terminé : la chaîne des couches

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```
