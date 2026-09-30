-- Sous-projet 6 : les bandes entamées dans la sauvegarde (une bande illisible est oubliée : le rouleau repart neuf) et
-- sur le serveur (jeter une bande, action limitée comme les autres).
local Sauvegarde = U.module("Sauvegarde")
local Commande = U.module("Commande")
local EtatAtelier = U.module("EtatAtelier")

local JUPE = { piece = "jupe_droite_devant", x = 2.5, y = 3, angle = 0 } -- [0, 5] × [0, 6]
local CORSAGE = { piece = "corsage_droit_devant", x = 9.6, y = 2.1, angle = 0 } -- [7,2, 12] × [0, 4,2]

---------------------------------------------------------------------------
-- Sauvegarde : la bande relue à l'identique ; son bas recalculé de ses trous
---------------------------------------------------------------------------
local e = EtatAtelier.nouveau(300)
e.stock = { coton_blanc = 20, soie_rouge = 3 }
e.entames = { coton_blanc = { bas = 6, trous = { JUPE, CORSAGE } } }
local relue = Sauvegarde.versEtat(M.transmettre(Sauvegarde.depuisEtat(e)))
local b = relue.entames.coton_blanc
U.verifier(b ~= nil and b.bas == 6 and #b.trous == 2 and b.trous[2].piece == "corsage_droit_devant" and b.trous[2].x == 9.6 and relue.entames.soie_rouge == nil, "bande entamée sauvée, relue telle quelle")
local partie = Sauvegarde.depuisEtat(e)
partie.entames.coton_blanc.bas = 99
U.verifier(Sauvegarde.versEtat(partie).entames.coton_blanc.bas == 6, "le bas de la bande est recalculé de ses trous")
partie.entames = nil
U.verifier(next(Sauvegarde.versEtat(partie).entames) == nil, "sans bandes (une partie d'avant) : des rouleaux neufs")

-- Bandes illisibles : oubliées une à une (le rouleau repart neuf, le stock reste)
local function trous(n) -- n corsages couchés, trois par rangée
	local out = {}
	for k = 0, n - 1 do
		table.insert(out, { piece = "corsage_droit_devant", x = 2.1 + 4.2 * (k % 3), y = 2.4 + 4.8 * (k // 3), angle = 90 })
	end
	return out
end
partie.stock = { coton_blanc = 20, soie_rouge = 3, lin_bleu = 60, velours_noir = 40, satin_rose = 40 }
partie.entames = {
	coton_blanc = { bas = 6, trous = { JUPE, { piece = "jupe_droite_dos", x = 4, y = 3, angle = 0 } } }, -- trous qui se chevauchent
	soie_rouge = { bas = 6, trous = { JUPE } }, -- plus bas que les 3 dm en stock
	lin_bleu = { bas = 44, trous = trous(25) }, -- plus de 24 trous
	velours_noir = "abîmée",
	satin_rose = { bas = 34, trous = trous(21) }, -- lisible
	tissu_inconnu = { bas = 6, trous = { JUPE } },
	toile_jute = { bas = 6, trous = { JUPE } }, -- pas en stock
}
local lue = Sauvegarde.versEtat(partie)
U.verifier(lue.entames.coton_blanc == nil and lue.entames.soie_rouge == nil and lue.entames.lin_bleu == nil and lue.entames.velours_noir == nil and lue.entames.tissu_inconnu == nil and lue.entames.toile_jute == nil, "trous qui se chevauchent, bande plus longue que le stock, plus de 24 trous, illisible, tissu inconnu ou absent : oubliées")
U.verifier(lue.entames.satin_rose ~= nil and #lue.entames.satin_rose.trous == 21 and lue.entames.satin_rose.bas == 34 and lue.stock.coton_blanc == 20 and lue.stock.lin_bleu == 60, "la bande lisible reste ; le stock reste entier")

-- Une robe au milieu de la découpe : son rouleau garde ses trous
local c = EtatAtelier.nouveau(1000)
U.commander(c, Random.new(4))
assert(c:validerCroquis({ corsage = "corsage_droit", manches = "manches_sans", col = "col_sans", jupe = "jupe_droite" }, { corsage_droit_devant = "coton_blanc", corsage_droit_dos = "coton_blanc", jupe_droite_devant = "coton_blanc", jupe_droite_dos = "coton_blanc" }).ok)
c.stock.coton_blanc = 30
c.entames.coton_blanc = { bas = 6, trous = { JUPE, CORSAGE } }
assert(c:commencerDecoupe().ok and c:couper("jupe_droite_dos", { x = 2.5, y = 9.1, angle = 0 }).ok)
local reprise = Sauvegarde.versEtat(M.transmettre(Sauvegarde.depuisEtat(c)))
U.verifier(reprise.etape == "decoupe" and #reprise.coupons.coton_blanc.trous == 2 and reprise.coupons.coton_blanc.poses.jupe_droite_dos ~= nil and not reprise.coupons.coton_blanc:verifier("corsage_droit_dos", { x = 9.6, y = 2.1, angle = 0 }), "reprise au milieu de la découpe : le rouleau garde ses trous et la pièce coupée")

---------------------------------------------------------------------------
-- Serveur : jeter une bande ; les arguments farfelus refusés proprement ; action limitée
---------------------------------------------------------------------------
local serveur = Commande.nouvelle()
local joueur = M.nouveauJoueur("Coupeuse")
local function appeler(action, ...)
	M.avancer(0.25)
	local r = serveur:traiter(joueur, action, ...)
	local ok, erreur = pcall(M.transmettre, r)
	U.verifier(ok, "réponse à « " .. tostring(action) .. " » transmissible (" .. tostring(erreur) .. ")")
	return r
end
local a = serveur:atelier(joueur).etat
U.commander(a, Random.new(6))
assert(a:validerCroquis({ corsage = "corsage_droit", manches = "manches_sans", col = "col_sans", jupe = "jupe_droite" }, { corsage_droit_devant = "coton_blanc", corsage_droit_dos = "coton_blanc", jupe_droite_devant = "coton_blanc", jupe_droite_dos = "coton_blanc" }).ok)
a.stock.coton_blanc = 20
a.entames.coton_blanc = { bas = 6, trous = { JUPE, CORSAGE } }
for k, arg in ipairs({ M.services.Workspace, { "coton_blanc" }, 0 / 0, "soie_rouge" }) do
	local r = appeler("jeterEntame", arg)
	U.verifier(not r.ok and r.erreur ~= "Action impossible." and a.entames.coton_blanc ~= nil and a.stock.coton_blanc == 20, "jeter farfelu refusé proprement (" .. k .. ") : " .. tostring(r.erreur))
end
local r = appeler("jeterEntame", "coton_blanc")
U.verifier(r.ok and r.dm == 6 and a.stock.coton_blanc == 14 and a.entames.coton_blanc == nil and r.etat.stock.coton_blanc == 14 and r.etat.entames.coton_blanc == nil, "la bande jetée sur le serveur : 6 dm de moins, l'état suit")
M.avancer(2)
local acceptes = 0
for _ = 1, 8 do
	if serveur:traiter(joueur, "jeterEntame", "coton_blanc").erreur ~= "Doucement !" then
		acceptes += 1
	end
end
U.verifier(acceptes == Commande.APPELS_PAR_SECONDE, "rafale : « jeterEntame » est limitée comme les autres actions (" .. acceptes .. " sur 8)")
