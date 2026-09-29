local Session = U.module("Session")
local TableDecoupe = U.module("TableDecoupe")

-- Robe en deux tissus : corsage en soie (avec manches ballon pliées), jupe évasée en biais en coton
local session = Session.nouvelle(11)
session:nouvelleCommande()
local croquis = { corsage = "corsage_droit", manches = "manches_ballon", col = "col_sans", jupe = "jupe_evasee" }
local tissus = {
	corsage_droit_devant = "soie_rouge",
	corsage_droit_dos = "soie_rouge",
	manche_ballon = "soie_rouge",
	jupe_evasee_devant = "coton_blanc",
	jupe_evasee_dos = "coton_blanc",
}
U.verifier(session:validerCroquis(croquis, tissus).ok, "croquis validé")
session.etat.argent = 1000
U.verifier(session:acheter("soie_rouge", 12).ok and session:acheter("coton_blanc", 30).ok, "tissus achetés")
U.verifier(session:commencerDecoupe().ok, "à la table de découpe")

local t = TableDecoupe.nouvelle(session.etat)
U.verifier(t.tissu == "soie_rouge" and t.selection ~= nil, "premier tissu et première pièce sélectionnés")
local onglets = t:onglets()
U.verifier(#onglets == 2 and onglets[1].reste == 3 and onglets[2].reste == 2, "onglets : 3 pièces en soie, 2 en coton")
U.verifier(t:etatPlacement().valide and t:etatPlacement().droitFil == 1, "place proposée valide, droit-fil parfait")

-- Rotation et aimantation
local angle0 = t.placement.angle
t:tourner(4)
U.verifier(t.placement.angle == angle0 % 360, "4° : aimanté au droit-fil")
t:tourner(40)
U.verifier(t:etatPlacement().droitFil < 1, "40° : droit-fil dégradé")
t:tourner(-40)
U.verifier(t:etatPlacement().droitFil == 1, "retour au droit-fil")

-- Déplacement hors du rouleau et position bornée
t:deplacer(-50, 3)
U.verifier(t.placement.x == 0 and not t:etatPlacement().valide, "déplacée contre le bord : pièce qui dépasse, refusée")
U.verifier(t:etatPlacement().erreur ~= nil, "message d'erreur fourni")
t:proposer()
U.verifier(t:etatPlacement().valide, "nouvelle proposition valide")

-- Couper toutes les pièces : la table passe d'elle-même à la pièce et au tissu suivants
local coupes = 0
while session.etat.etape == "decoupe" and coupes < 10 do
	local r = t:couper(session)
	U.verifier(r.ok, "coupe " .. (coupes + 1) .. " : " .. tostring(r.erreur))
	coupes += 1
end
U.verifier(coupes == 5 and session.etat.etape == "epinglage", "5 pièces coupées, direction l'épinglage")
U.verifier(t.selection == nil, "plus rien à sélectionner")
U.verifier(not t:couper(session).ok, "rien à couper")

-- La jupe en biais a été proposée à 45°
U.verifier(session.etat.coupees.jupe_evasee_devant.angle == 45, "jupe en biais coupée à 45°")

-- Place proposée : la première place libre en haut du rouleau, à côté des pièces déjà coupées
local s2 = Session.nouvelle(12)
s2:nouvelleCommande()
s2:validerCroquis({ corsage = "corsage_droit", manches = "manches_sans", col = "col_sans", jupe = "jupe_droite" }, {
	corsage_droit_devant = "lin_bleu",
	corsage_droit_dos = "lin_bleu",
	jupe_droite_devant = "lin_bleu",
	jupe_droite_dos = "lin_bleu",
})
s2:acheter("lin_bleu", 11)
s2:commencerDecoupe()
local t2 = TableDecoupe.nouvelle(s2.etat)
t2:selectionner("corsage_droit_devant")
U.verifier(t2.placement.y < 3, "la première pièce est proposée en haut du rouleau")
U.verifier(t2:couper(s2).ok, "corsage devant coupé")
t2:selectionner("corsage_droit_dos")
U.verifier(t2.placement.y < 3 and t2.placement.x > 4.8, "le dos est proposé à droite du devant, pas en dessous")
U.verifier(t2:couper(s2).ok, "corsage dos coupé")
t2:selectionner("jupe_droite_devant")
U.verifier(t2:couper(s2).ok, "jupe devant coupée à la place proposée")
t2:selectionner("jupe_droite_dos")
U.verifier(t2:couper(s2).ok and s2.etat.etape == "epinglage", "toute la robe tient dans les 11 dm conseillés en suivant les propositions")

-- Une pièce pliée est proposée contre le pli (son symétrique de l'autre côté), pas contre le bord
local s3 = Session.nouvelle(13)
s3:nouvelleCommande()
s3:validerCroquis({ corsage = "corsage_droit", manches = "manches_ballon", col = "col_sans", jupe = "jupe_droite" }, {
	corsage_droit_devant = "lin_bleu",
	corsage_droit_dos = "lin_bleu",
	manche_ballon = "lin_bleu",
	jupe_droite_devant = "lin_bleu",
	jupe_droite_dos = "lin_bleu",
})
s3:acheter("lin_bleu", 20)
s3:commencerDecoupe()
local t3 = TableDecoupe.nouvelle(s3.etat)
t3:selectionner("manche_ballon")
local Coupon = U.module("Coupon")
local Polygone = U.module("Polygone")
local boite = Polygone.boite(Coupon.contoursPoses("manche_ballon", t3.placement)[1])
U.verifier(boite.maxX > 6.8 and boite.maxX <= 7, ("manche pliée proposée contre le pli (bord droit à %.2f dm)"):format(boite.maxX))

-- En suivant les places proposées, la robe tient dans le métrage conseillé, même à plusieurs tissus
local EtatAtelier = U.module("EtatAtelier")
local Metrage = U.module("Metrage")
local Catalogue = U.module("Catalogue")
local function suivrePropositions(croquisEssai, tissusEssai)
	local e = EtatAtelier.nouveau(100000)
	e:nouvelleCommande(Random.new(1))
	if not e:validerCroquis(croquisEssai, tissusEssai).ok then
		return false, "croquis refusé"
	end
	for _, tissu in ipairs(e:tissusUtilises()) do
		local ids = {}
		for _, id in ipairs(e:piecesDuCroquis()) do
			if tissusEssai[id] == tissu then
				table.insert(ids, id)
			end
		end
		e:acheter(tissu, Metrage.conseil(ids))
	end
	e:commencerDecoupe()
	local tableEssai = TableDecoupe.nouvelle(e)
	local faux = {
		couper = function(_, id, placement)
			return e:couper(id, placement)
		end,
	}
	for _ = 1, 12 do
		if e.etape ~= "decoupe" then
			break
		end
		local r = tableEssai:couper(faux)
		if not r.ok then
			return false, r.erreur
		end
	end
	return e.etape == "epinglage", "pièces restantes"
end
local ok, pourquoi = suivrePropositions({ corsage = "corsage_v", manches = "manches_ballon", col = "col_sans", jupe = "jupe_trapeze" }, {
	corsage_v_devant = "lin_bleu",
	manche_ballon = "lin_bleu",
	jupe_trapeze_devant = "lin_bleu",
	corsage_droit_dos = "coton_blanc",
	jupe_trapeze_dos = "coton_blanc",
})
U.verifier(ok, "corsage, manche pliée et jupe dans 8 dm de lin : " .. tostring(pourquoi))
local rng = Random.new(42)
local echecs, premier = 0, nil
for _ = 1, 150 do
	local croquisEssai = {}
	for _, famille in ipairs(Catalogue.FAMILLES) do
		local variantes = Catalogue.variantesDe(famille)
		croquisEssai[famille] = variantes[rng:NextInteger(1, #variantes)].id
	end
	local tissusEssai = {}
	for _, id in ipairs(U.module("Patron").piecesDuCroquis(croquisEssai)) do
		tissusEssai[id] = ({ "lin_bleu", "coton_blanc", "soie_rouge" })[rng:NextInteger(1, 3)]
	end
	local reussi = suivrePropositions(croquisEssai, tissusEssai)
	if not reussi then
		echecs += 1
		premier = premier or croquisEssai
	end
end
U.verifier(echecs == 0, ("150 robes à 3 tissus : %d dépassent le métrage conseillé"):format(echecs))
