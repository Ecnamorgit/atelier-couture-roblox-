local EtatAtelier = U.module("EtatAtelier")
local Notation = U.module("Notation")
local Clientes = U.module("Clientes")
local Sauvegarde = U.module("Sauvegarde")

-- Une robe simple, coupée, épinglée et cousue : prête à présenter
local function robePrete(etat)
	etat.croquis = { corsage = "corsage_droit", manches = "manches_sans", col = "col_sans", jupe = "jupe_droite" }
	etat.tissus = { corsage_droit_devant = "coton_blanc", corsage_droit_dos = "coton_blanc", jupe_droite_devant = "coton_blanc", jupe_droite_dos = "coton_blanc" }
	for id in pairs(etat.tissus) do
		etat.coupees[id] = { x = 0, y = 0, angle = 0 }
		etat.epinglees[id] = true
		etat.coutures[id] = 1
	end
	etat.etape = "decorations"
	etat:decorer({})
	etat.commande.exigences = { { type = "qualite", valeur = 0.1 } }
end

-- La cliente passe commande : un acompte d'un quart de la base de la robe la plus simple, versé tout de suite
local e = EtatAtelier.nouveau(100)
local r = e:nouvelleCommande(Random.new(1))
local acompte = math.floor(0.25 * Notation.base(4, #e.commande.exigences))
U.verifier(r.ok and r.acompte == acompte and e.commande.acompte == acompte and e.argent == 100 + acompte, "acompte d'un quart de la base, versé à la commande (" .. acompte .. " po)")
U.verifier(acompte >= 18 and acompte <= 26, "un acompte de 18 à 26 pièces d'or")
local pauvre = EtatAtelier.nouveau(0)
pauvre:nouvelleCommande(Random.new(2))
U.verifier(pauvre.argent == EtatAtelier.FILET + pauvre.commande.acompte, "le filet de sécurité, puis l'acompte")

-- Robe livrée : la paie, moins l'acompte déjà reçu ; le prestige compte toute la paie
e:mesurer(Clientes.get("colette").mesures)
robePrete(e)
local avant = e.argent
r = e:livrer()
U.verifier(r.ok and r.reussie and r.acompte == acompte and r.verse == r.paie - acompte and e.argent == avant + r.paie - acompte, "livrée : paie moins l'acompte (" .. r.paie .. " − " .. acompte .. ")")
U.verifier(r.prestige.gain == math.floor(r.paie / 10 + 0.5), "le prestige compte toute la paie")

-- Abandon : l'acompte est gardé
pauvre:mesurer(Clientes.get("colette").mesures)
pauvre.etape = "refus"
local argentPauvre = pauvre.argent
U.verifier(pauvre:abandonner().ok and pauvre.argent == argentPauvre, "abandon : l'acompte reste dans la caisse")

-- Paie plus petite que l'acompte (robe bâclée) : rien de plus, rien de repris
local bacle = EtatAtelier.nouveau(0)
bacle:nouvelleCommande(Random.new(3))
bacle.commande.acompte = 999
bacle:mesurer(Clientes.get("colette").mesures)
robePrete(bacle)
local avantBacle = bacle.argent
r = bacle:livrer()
U.verifier(r.ok and r.verse == 0 and bacle.argent == avantBacle, "acompte plus grand que la paie : rien de plus, rien de repris")

-- Sauvegarde : l'acompte suit la commande ; un acompte illisible fait abandonner la commande
local enCours = EtatAtelier.nouveau(100)
enCours:nouvelleCommande(Random.new(4))
enCours:mesurer(Clientes.get("colette").mesures)
local relue = Sauvegarde.versEtat(M.transmettre(Sauvegarde.depuisEtat(enCours)))
U.verifier(relue.commande ~= nil and relue.commande.acompte == enCours.commande.acompte, "l'acompte est sauvegardé avec la commande")
for _, cas in ipairs({ { "acompte", -3 }, { "acompte", 2.5 }, { "acompte", "x" }, { "acompte", 1e9 } }) do
	local p = M.transmettre(Sauvegarde.depuisEtat(enCours))
	p.enCours.commande[cas[1]] = cas[2]
	local r2 = Sauvegarde.versEtat(p)
	U.verifier(r2.etape == "accueil" and r2.commande == nil, cas[1] .. " illisible (" .. tostring(cas[2]) .. ") : commande abandonnée")
end
