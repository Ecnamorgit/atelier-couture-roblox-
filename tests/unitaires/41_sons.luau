local Sons = U.module("Sons")
U.verifier(Sons.IDS.fete ~= nil, "un son de fête (la robe terminée)")
local Session = U.module("Session")

local SoundService = M.services.SoundService
local function son(nom)
	return SoundService:FindFirstChild("Atelier_" .. nom)
end
M.sonsJoues = {}

---------------------------------------------------------------------------
-- Un son ponctuel : un objet Sound de SoundService, créé une fois, rejoué à chaque fois
---------------------------------------------------------------------------
Sons.jouer("clochette")
local clochette = son("clochette")
U.verifier(clochette ~= nil and clochette.SoundId == "rbxassetid://" .. Sons.IDS.clochette, "la clochette est un son de SoundService, à son identifiant")
U.verifier(M.sonsJoues[#M.sonsJoues] == "Atelier_clochette", "la clochette sonne")
Sons.jouer("clochette")
U.verifier(son("clochette") == clochette and #M.sonsJoues == 2, "rejouée, avec le même objet")
for nom, id in pairs(Sons.IDS) do
	U.verifier(type(id) == "number" and id > 0, "identifiant du son « " .. nom .. " »")
end

---------------------------------------------------------------------------
-- Une boucle (machine à coudre) : lancée, vitesse réglée, arrêtée
---------------------------------------------------------------------------
Sons.boucle("couture", true, 1.3)
local couture = son("couture")
U.verifier(couture.Looped and couture.IsPlaying and couture.PlaybackSpeed == 1.3, "la machine tourne, au rythme demandé")
local joues = #M.sonsJoues
Sons.boucle("couture", true, 1.3)
U.verifier(#M.sonsJoues == joues, "déjà lancée : pas relancée à chaque image")
Sons.boucle("couture", false)
U.verifier(not couture.IsPlaying, "la machine s'arrête")

---------------------------------------------------------------------------
-- Couper le son : rien ne joue, les boucles s'arrêtent ; la musique reprend au retour
---------------------------------------------------------------------------
Sons.boucle("musique", true)
U.verifier(son("musique").IsPlaying and son("musique").Volume < son("clochette").Volume, "la musique joue, plus bas que les bruits")
Sons.activer(false)
U.verifier(not Sons.actif and not son("musique").IsPlaying, "son coupé : la musique s'arrête")
joues = #M.sonsJoues
Sons.jouer("achat")
Sons.boucle("couture", true)
U.verifier(#M.sonsJoues == joues and not couture.IsPlaying, "son coupé : ni bruit ni machine")
Sons.activer(true)
U.verifier(son("musique").IsPlaying, "son rétabli : la musique reprend")
Sons.boucle("musique", false)

---------------------------------------------------------------------------
-- La session annonce chaque action réussie (pour les sons de l'interface)
---------------------------------------------------------------------------
local courante = Session.courante
local session = Session.nouvelle(3)
local annonces = {}
session:surAction(function(nom, reponse)
	table.insert(annonces, { nom = nom, ok = reponse.ok })
end)
session:nouvelleCommande()
session:acheter("coton_blanc", 0) -- refusé
U.verifier(#annonces == 1 and annonces[1].nom == "nouvelleCommande" and annonces[1].ok, "une action réussie est annoncée, pas un refus")
Session.courante = courante
