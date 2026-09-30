-- Sous-projet 6 : le tissu coupé ne quitte plus le stock ; il laisse une bande entamée en haut du rouleau, avec ses
-- trous. À la robe suivante on coupe dans ses vides ou dessous ; on peut la jeter (elle quitte alors le stock) ; au-delà
-- de 24 trous, elle se jette d'elle-même.
local EtatAtelier = U.module("EtatAtelier")

local CROQUIS = { corsage = "corsage_droit", manches = "manches_sans", col = "col_sans", jupe = "jupe_droite" }
local ORDRE = { "corsage_droit_devant", "corsage_droit_dos", "jupe_droite_devant", "jupe_droite_dos" }
local function tousEn(tissu)
	local out = {}
	for _, id in ipairs(ORDRE) do
		out[id] = tissu
	end
	return out
end
-- Les quatre pièces, rangées en haut du rouleau (jusqu'à 10,2 dm), ou décalées de « dy » vers le bas
local function places(dy)
	return {
		corsage_droit_devant = { x = 2.4, y = 2.1 + dy, angle = 0 },
		corsage_droit_dos = { x = 7.2, y = 2.1 + dy, angle = 0 },
		jupe_droite_devant = { x = 2.5, y = 7.2 + dy, angle = 0 },
		jupe_droite_dos = { x = 7.5, y = 7.2 + dy, angle = 0 },
	}
end
local graine = 0
local function aLaTable(e, dm)
	graine += 1
	U.commander(e, Random.new(graine))
	assert(e:validerCroquis(CROQUIS, tousEn("coton_blanc")).ok)
	if dm then
		assert(e:acheter("coton_blanc", dm).ok)
	end
	assert(e:commencerDecoupe().ok)
end
local function toutCouper(e, p)
	local r
	for _, id in ipairs(ORDRE) do
		r = e:couper(id, p[id])
		assert(r.ok, id .. " : " .. tostring(r.erreur))
	end
	return r
end
local function finir(e) -- (la robe s'arrête là : seul le rouleau compte ici)
	e.etape = "refus"
	assert(e:abandonner().ok)
end

---------------------------------------------------------------------------
-- La première robe : le stock reste, une bande entamée de 11 dm, quatre trous
---------------------------------------------------------------------------
local e = EtatAtelier.nouveau(1000)
U.verifier(type(e.entames) == "table" and next(e.entames) == nil, "une partie neuve : aucun rouleau entamé")
aLaTable(e, 20)
local r = toutCouper(e, places(0))
local b = e.entames.coton_blanc or {}
U.verifier(e.stock.coton_blanc == 20 and b.trous ~= nil and b.bas == 11 and #b.trous == 4 and r.jetees == nil, "robe coupée : le stock reste (20 dm), une bande entamée de 11 dm, quatre trous")
U.verifier(b.trous ~= nil and b.trous[1].piece == "corsage_droit_devant" and b.trous[4].piece == "jupe_droite_dos" and b.trous[3].y == 7.2, "les trous : chaque pièce à sa place, dans un ordre stable")
U.verifier(e:stockNeuf("coton_blanc") == 9 and e:stocksNeufs().coton_blanc == 9 and e:stockNeuf("soie_rouge") == 0, "le tissu neuf : 9 dm (20 moins les 11 entamés)")
local copie = EtatAtelier.nouveau():charger(e:exporter())
U.verifier(copie.entames.coton_blanc.bas == 11 and #copie.entames.coton_blanc.trous == 4, "la bande entamée voyage avec l'état")
finir(e)
U.verifier(e.entames.coton_blanc.bas == 11, "la robe finie, la bande reste")

---------------------------------------------------------------------------
-- La robe suivante : les trous sont pris, on coupe dessous (le rouleau se déroule en rachetant)
---------------------------------------------------------------------------
aLaTable(e)
local rouleau = e.coupons.coton_blanc
U.verifier(rouleau.longueur == 20 and #rouleau.trous == 4 and rouleau:longueurUtilisee() == 11, "à la table : le rouleau de 20 dm, et ses quatre trous")
local surTrou = e:couper("corsage_droit_devant", places(0).corsage_droit_devant)
U.verifier(not surTrou.ok and surTrou.erreur == "La pièce passe sur un trou du tissu entamé.", "couper sur un trou : refusé")
local client = EtatAtelier.nouveau():charger(e:exporter())
U.verifier(#client.coupons.coton_blanc.trous == 4 and not client.coupons.coton_blanc:verifier("corsage_droit_devant", places(0).corsage_droit_devant), "la copie du client a les mêmes trous")
assert(e:acheter("coton_blanc", 2).ok)
r = toutCouper(e, places(11))
b = e.entames.coton_blanc or {}
U.verifier(e.stock.coton_blanc == 22 and b.bas == 22 and #(b.trous or {}) == 8 and e:stockNeuf("coton_blanc") == 0, "sous la bande : elle descend à 22 dm, huit trous, plus de tissu neuf")
finir(e)

---------------------------------------------------------------------------
-- Jeter la bande : à l'achat, ou à la table tant que rien de ce tissu n'est coupé pour cette robe
---------------------------------------------------------------------------
U.verifier(e:jeterEntame("coton_blanc").erreur == "Ce n'est pas le moment de jeter du tissu.", "à l'accueil : pas de bande à jeter")
graine += 1
U.commander(e, Random.new(graine))
assert(e:validerCroquis(CROQUIS, tousEn("coton_blanc")).ok)
U.verifier(e:jeterEntame("tissu_inconnu").erreur == "Tissu inconnu." and e:jeterEntame("soie_rouge").erreur == "Ce rouleau n'est pas entamé." and e:jeterEntame(nil).erreur == "Tissu inconnu.", "tissu inconnu ou rouleau neuf : rien à jeter")
local j = e:jeterEntame("coton_blanc")
U.verifier(j.ok and j.dm == 22 and e.stock.coton_blanc == 0 and e.entames.coton_blanc == nil, "à l'achat : la bande (22 dm) quitte le stock, le rouleau repart neuf")
assert(e:acheter("coton_blanc", 12).ok and e:commencerDecoupe().ok)
toutCouper(e, places(0))
finir(e)
aLaTable(e, 10)
U.verifier(e.coupons.coton_blanc.longueur == 22 and #e.coupons.coton_blanc.trous == 4, "une nouvelle bande, un rouleau de 22 dm")
j = e:jeterEntame("coton_blanc")
U.verifier(j.ok and e.stock.coton_blanc == 11 and e.coupons.coton_blanc.longueur == 11 and #e.coupons.coton_blanc.trous == 0 and e.etape == "decoupe", "à la table, rien de coupé : la bande est jetée, le rouleau repart neuf (11 dm)")
assert(e:couper("corsage_droit_devant", places(0).corsage_droit_devant).ok)
e.entames.coton_blanc = { bas = 1, trous = { { piece = "jupe_droite_devant", x = 2.5, y = 3, angle = 0 } } } -- (une bande d'avant)
local refus = e:jeterEntame("coton_blanc")
U.verifier(not refus.ok and refus.erreur == "Des pièces de ce tissu sont déjà coupées pour cette robe." and e.entames.coton_blanc ~= nil, "une pièce de ce tissu déjà coupée : on ne jette plus")
e.entames.coton_blanc = nil

---------------------------------------------------------------------------
-- Recommencer : les pièces coupées deviennent des trous (le tissu reste sur le rouleau)
---------------------------------------------------------------------------
local rc = EtatAtelier.nouveau(1000)
aLaTable(rc, 12)
assert(rc:couper("jupe_droite_devant", places(0).jupe_droite_devant).ok)
assert(rc:couper("corsage_droit_dos", places(0).corsage_droit_dos).ok)
r = rc:recommencer()
local bandeRc = rc.entames.coton_blanc
U.verifier(r.ok and rc.stock.coton_blanc == 12 and bandeRc ~= nil and bandeRc.bas == 11 and #bandeRc.trous == 2 and rc.etape == "carnet", "recommencer : deux pièces coupées, deux trous ; le stock reste")

---------------------------------------------------------------------------
-- Au-delà de 24 trous, la bande est jetée d'elle-même (et annoncée)
---------------------------------------------------------------------------
-- 20 ou 21 trous de corsages couchés (4,2 × 4,8 dm), trois par rangée : sept rangées, jusqu'à 33,6 dm
local function trous(n)
	local out = {}
	for k = 0, n - 1 do
		table.insert(out, { piece = "corsage_droit_devant", x = 2.1 + 4.2 * (k % 3), y = 2.4 + 4.8 * (k // 3), angle = 90 })
	end
	return out
end
local pleine = EtatAtelier.nouveau(1000)
pleine.stock.coton_blanc = 60
pleine.entames.coton_blanc = { bas = 34, trous = trous(20) }
aLaTable(pleine)
r = toutCouper(pleine, places(34))
local bandePleine = pleine.entames.coton_blanc
U.verifier(r.jetees == nil and bandePleine ~= nil and #bandePleine.trous == 24 and bandePleine.bas == 45, "24 trous : la bande reste (45 dm)")
finir(pleine)
local trop = EtatAtelier.nouveau(1000)
trop.stock.coton_blanc = 60
trop.entames.coton_blanc = { bas = 34, trous = trous(21) }
aLaTable(trop)
r = toutCouper(trop, places(34))
U.verifier(r.jetees ~= nil and #r.jetees == 1 and r.jetees[1].tissu == "coton_blanc" and r.jetees[1].dm == 45 and trop.entames.coton_blanc == nil and trop.stock.coton_blanc == 60 - 45, "25 trous : la bande (45 dm) est jetée d'elle-même, et annoncée")

---------------------------------------------------------------------------
-- Une robe libre : ses matières sont ce qu'elle ajoute à la bande entamée
---------------------------------------------------------------------------
local libre = EtatAtelier.nouveau(1000)
aLaTable(libre, 22)
toutCouper(libre, places(0))
finir(libre)
libre.livraisons = EtatAtelier.LIBRES_APRES
assert(libre:nouvelleRobeLibre("M").ok and libre:validerCroquis(CROQUIS, tousEn("coton_blanc")).ok and libre:commencerDecoupe().ok)
toutCouper(libre, places(11))
U.verifier(libre.commande.matieres == EtatAtelier.prix("coton_blanc", 11) and libre.commande.matieres ~= EtatAtelier.prix("coton_blanc", 22), "robe libre coupée sous une bande de 11 dm : ses matières, les 11 dm qu'elle ajoute")

---------------------------------------------------------------------------
-- (relecture) Au-delà de 5 m entamés, la bande est jetée d'elle-même : sous elle, un rouleau de 10 m au plus garde
-- toujours de quoi couper une robe ; le tissu neuf ne compte que le rouleau déroulé
---------------------------------------------------------------------------
local Catalogue = U.module("Catalogue")
local Patron = U.module("Patron")
local Metrage = U.module("Metrage")
local Recette = U.module("Recette")
local longue = EtatAtelier.nouveau(1000)
longue.stock.coton_blanc = 80
longue.entames.coton_blanc = { bas = 45, trous = { { piece = "jupe_droite_devant", x = 2.5, y = 42, angle = 0 } } }
aLaTable(longue)
r = toutCouper(longue, places(45))
U.verifier(EtatAtelier.ENTAME_MAX == 50 and r.jetees ~= nil and r.jetees[1].dm == 56 and longue.entames.coton_blanc == nil and longue.stock.coton_blanc == 80 - 56, "une bande de 5,6 m (plus de 5 m) : jetée d'elle-même, et annoncée")
local grand = EtatAtelier.nouveau()
grand.stock.coton_blanc = 150
grand.entames.coton_blanc = { bas = 40, trous = { { piece = "jupe_droite_devant", x = 2.5, y = 37, angle = 0 } } }
U.verifier(grand:stockNeuf("coton_blanc") == Recette.LONGUEUR_MAX - 40, "150 dm en stock, une bande de 40 dm : le neuf du rouleau déroulé (10 m au plus), 60 dm")
local pire, lequel = 0, ""
local listes = {}
for _, famille in ipairs(Catalogue.FAMILLES) do
	listes[famille] = Catalogue.variantesDe(famille)
end
for _, co in ipairs(listes.corsage) do
	for _, ma in ipairs(listes.manches) do
		for _, cl in ipairs(listes.col) do
			for _, ju in ipairs(listes.jupe) do
				local conseil = Metrage.conseil(Patron.piecesDuCroquis({ corsage = co.id, manches = ma.id, col = cl.id, jupe = ju.id }))
				if conseil > pire then
					pire, lequel = conseil, co.id .. ", " .. ma.id .. ", " .. cl.id .. ", " .. ju.id
				end
			end
		end
	end
end
U.verifier(pire <= Recette.LONGUEUR_MAX - EtatAtelier.ENTAME_MAX, ("toute robe d'un seul tissu tient sous une bande de 5 m : au plus %d dm (%s)"):format(pire, lequel))

---------------------------------------------------------------------------
-- (relecture) La copie du client ne reconstruit que les rouleaux qui ont changé
---------------------------------------------------------------------------
local deux = EtatAtelier.nouveau(1000)
graine += 1
U.commander(deux, Random.new(graine))
local deuxTissus = tousEn("coton_blanc")
deuxTissus.corsage_droit_devant, deuxTissus.corsage_droit_dos = "soie_rouge", "soie_rouge"
assert(deux:validerCroquis(CROQUIS, deuxTissus).ok and deux:acheter("coton_blanc", 20).ok and deux:acheter("soie_rouge", 10).ok and deux:commencerDecoupe().ok)
local copieDeux = EtatAtelier.nouveau():charger(deux:exporter())
local soieAvant = copieDeux.coupons.soie_rouge
assert(deux:couper("jupe_droite_devant", places(0).jupe_droite_devant).ok)
copieDeux:charger(deux:exporter())
U.verifier(copieDeux.coupons.soie_rouge == soieAvant and copieDeux.coupons.coton_blanc.poses.jupe_droite_devant ~= nil, "une pièce coupée dans le coton : le rouleau de soie, inchangé, n'est pas reconstruit")
