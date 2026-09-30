-- Plan 14 : l'annonce de l'accueil montre la qualité arrondie vers le bas, d'accord avec les étoiles de la cliente
-- (une robe à 79,96 % s'annonce « 79 % », avec trois étoiles), à la livraison comme à la vente
local UiKit = U.module("UiKit")
local EtatAtelier = U.module("EtatAtelier")
local EcranAccueil = U.module("EcranAccueil")

local fenetre = Instance.new("Frame")
local contenu = Instance.new("Frame")
contenu.Parent = fenetre
local function annonce(action, qualite)
	contenu:ClearAllChildren()
	local reponse = { ok = true, reussie = true, verse = 50, paie = 50, prix = 50, bilan = { qualite = qualite } }
	local fermer = EcranAccueil({
		UiKit = UiKit,
		contenu = contenu,
		fenetre = fenetre,
		message = function() end,
		refus = function() end,
		session = { etat = EtatAtelier.nouveau(100), derniere = { action = action, reponse = reponse } },
	})
	if fermer then
		fermer()
	end
	local a = contenu:FindFirstChild("Annonce")
	return a and a.Text or ""
end

local livree = annonce("livrer", 0.7996)
U.verifier(string.find(livree, "★★★☆☆", 1, true) ~= nil and string.find(livree, "(qualité 79 %)", 1, true) ~= nil, "livrée à 79,96 % : trois étoiles et « 79 % » (" .. livree .. ")")
livree = annonce("livrer", 0.9)
U.verifier(string.find(livree, "★★★★★", 1, true) ~= nil and string.find(livree, "(qualité 90 %)", 1, true) ~= nil, "livrée à 90 % : cinq étoiles et « 90 % »")
local vendue = annonce("vendre", 0.7996)
U.verifier(string.find(vendue, "(qualité 79 %)", 1, true) ~= nil, "vendue à 79,96 % : « 79 % » (" .. vendue .. ")")
