local Scene = U.module("Scene")
local EtatAtelier = U.module("EtatAtelier")
local Patron = U.module("Patron")

local Workspace = M.services.Workspace
local Lighting = M.services.Lighting
M.budget.images, M.budget.maillages = 64, 7

local CROQUIS = { corsage = "corsage_droit", manches = "manches_sans", col = "col_sans", jupe = "jupe_droite" }
local PLACES = {
	corsage_droit_devant = { x = 2.4, y = 2.1, angle = 0 },
	corsage_droit_dos = { x = 7.2, y = 2.1, angle = 0 },
	jupe_droite_devant = { x = 2.5, y = 7.2, angle = 0 },
	jupe_droite_dos = { x = 7.5, y = 7.2, angle = 0 },
}
-- De la commande jusqu'à la présentation (robe cousue parfaitement, sans décoration)
local function jusquALaPhoto(etat)
	local tissus = {}
	for id in pairs(PLACES) do
		tissus[id] = "coton_blanc"
	end
	etat:validerCroquis(CROQUIS, tissus)
	etat:acheter("coton_blanc", 12)
	etat:commencerDecoupe()
	for _, id in ipairs(etat:piecesDuCroquis()) do
		etat:couper(id, PLACES[id])
	end
	for _, id in ipairs(etat:piecesDuCroquis()) do
		etat:epingler(id)
	end
	for _, id in ipairs(etat:piecesDuCroquis()) do
		local _, longueur = Patron.trajetCouture(id)
		etat:rendreCouture(id, table.create(math.round(longueur / 0.1), 0), longueur)
	end
	etat:decorer({})
end
local function bulle(modele)
	local b = modele and modele.Head:FindFirstChild("Bulle")
	return b and b.Texte.Text or nil
end
local function pieds(modele)
	local bas = math.huge
	for _, d in ipairs(modele:GetDescendants()) do
		if d:IsA("BasePart") and d.Name ~= "Cheveux" then
			bas = math.min(bas, d.CFrame.Position.Y - d.Size.Y / 2)
		end
	end
	return bas
end

---------------------------------------------------------------------------
-- La cliente en personne
---------------------------------------------------------------------------
local etat = EtatAtelier.nouveau(1000)
local scene = Scene.nouvelle(Workspace, { etaler = false, controles = function() end })
local function compterClientes()
	local n = 0
	for _, c in ipairs(scene.dossier:GetChildren()) do
		if c.Name == "Cliente" then
			n += 1
		end
	end
	return n
end
scene:synchroniser(etat, nil)
U.verifier(scene.dossier:FindFirstChild("Cliente") == nil, "personne à l'accueil avant la clochette")
etat:nouvelleCommande(Random.new(3))
scene:synchroniser(etat, nil)
local cliente = scene.dossier:FindFirstChild("Cliente")
U.verifier(cliente ~= nil, "la clochette fait entrer la cliente")
U.verifier(math.abs(pieds(cliente) - Scene.CLIENTE.Position.Y) < 1e-6, "elle a les pieds au sol")
U.verifier(bulle(cliente) == Scene.PAROLES.carnet, "au carnet, elle dit ce qu'elle veut")
etat.etape = "achat"
scene:synchroniser(etat, nil)
U.verifier(scene.dossier:FindFirstChild("Cliente") == cliente and bulle(cliente) == nil, "pendant le travail : la même cliente, silencieuse")
etat.etape = "carnet"
jusquALaPhoto(etat)
scene:synchroniser(etat, nil)
U.verifier(etat.etape == "photo" and bulle(cliente) == Scene.PAROLES.photo, "à la présentation, elle regarde la robe")

-- Refus puis livraison acceptée : elle remercie, puis s'en va
etat.commande.exigences = { { type = "accessoire", id = "croix_argent" } }
local r = etat:livrer()
scene:synchroniser(etat, { action = "livrer", reponse = r })
U.verifier(bulle(cliente) == Scene.PAROLES.refus, "robe refusée : elle le dit")
etat:retoucher()
etat.commande.exigences = { { type = "qualite", valeur = 0.5 } }
etat:decorer({})
r = etat:livrer()
scene:synchroniser(etat, { action = "livrer", reponse = r })
U.verifier(r.reussie and bulle(cliente) == Scene.PAROLES.merci and cliente.Parent ~= nil, "robe acceptée : elle remercie")
M.avancer(Scene.DUREE_ADIEU + 0.5)
U.verifier(cliente.Parent == nil and scene.dossier:FindFirstChild("Cliente") == nil, "puis elle s'en va")

-- Nouvelle cliente, abandon : elle s'en va aussi ; une suivante chasse la précédente tout de suite
etat:nouvelleCommande(Random.new(4))
scene:synchroniser(etat, nil)
local deuxieme = scene.dossier:FindFirstChild("Cliente")
U.verifier(deuxieme ~= nil and deuxieme ~= cliente, "nouvelle commande : nouvelle cliente")
etat.etape = "refus"
etat:abandonner()
scene:synchroniser(etat, { action = "abandonner", reponse = { ok = true } })
U.verifier(bulle(deuxieme) == Scene.PAROLES.abandon, "abandon : elle le regrette")
etat:nouvelleCommande(Random.new(5))
scene:synchroniser(etat, nil)
U.verifier(deuxieme.Parent == nil and compterClientes() == 1, "une cliente à la fois : la précédente part dès qu'une autre entre")

-- La construction de l'avatar attend : une autre synchronisation pendant ce temps n'en crée pas une seconde
-- La cliente renonce (robe refusée puis abandonnée) : la commande se termine
local function renoncer()
	etat.etape = "refus"
	local r = etat:abandonner()
	scene:synchroniser(etat, { action = "abandonner", reponse = r })
	return r.ok
end
U.verifier(renoncer() and etat:nouvelleCommande(Random.new(6)).ok, "commande suivante prête")
M.pendantAvatar = function()
	scene:synchroniser(etat, nil)
end
scene:synchroniser(etat, nil)
U.verifier(compterClientes() == 1 and scene.cliente ~= nil and scene.cliente.Parent == scene.dossier, "deux synchronisations pendant la construction : une seule cliente")
-- La commande est abandonnée pendant la construction : l'avatar construit ne reste pas
U.verifier(renoncer(), "elle renonce")
M.avancer(Scene.DUREE_ADIEU + 0.5)
U.verifier(compterClientes() == 0 and etat:nouvelleCommande(Random.new(7)).ok, "elle est partie, commande suivante prête")
M.pendantAvatar = function()
	renoncer()
end
scene:synchroniser(etat, nil)
U.verifier(M.pendantAvatar == nil and compterClientes() == 0 and scene.cliente == nil, "commande abandonnée pendant la construction : personne ne reste")
U.verifier(etat:nouvelleCommande(Random.new(8)).ok, "commande suivante prête")
scene:synchroniser(etat, nil)
U.verifier(compterClientes() == 1, "la cliente suivante entre normalement")

---------------------------------------------------------------------------
-- Photo : décor, lumière, couleur du mannequin, puis tout est rétabli
---------------------------------------------------------------------------
local lumiereAvant = { Lighting.ClockTime, Lighting.Brightness, Lighting.Ambient }
local mannequin = scene.dossier:FindFirstChild("Mannequin")
local busteAvant = mannequin.Buste.Color
scene:photo({ decor = "bleu", lumiere = "soir", mannequin = "noir" })
local fond = scene.dossier:FindFirstChild("Fond")
U.verifier(fond ~= nil and fond.Color == Scene.DECORS.bleu, "décor bleu derrière le mannequin")
U.verifier(fond.CFrame.Position.Z > Scene.CADRE.Position.Z, "le décor est derrière le mannequin (vu de face)")
U.verifier(Lighting.ClockTime == Scene.LUMIERES.soir.ClockTime and Lighting.Brightness == Scene.LUMIERES.soir.Brightness, "lumière du soir")
U.verifier(mannequin.Buste.Color == Scene.MANNEQUINS.noir and mannequin.Pied.Color ~= Scene.MANNEQUINS.noir, "mannequin noir (le pied en bois ne change pas)")
scene:photo({ decor = "rose", lumiere = "jour", mannequin = "creme" })
U.verifier(fond.Color == Scene.DECORS.rose and #scene.dossier:GetChildren() > 0, "changer de décor ne crée pas un second fond")
scene:finirPhoto()
U.verifier(scene.dossier:FindFirstChild("Fond") == nil, "fin de la photo : plus de décor")
U.verifier(Lighting.ClockTime == lumiereAvant[1] and Lighting.Brightness == lumiereAvant[2] and Lighting.Ambient == lumiereAvant[3], "lumière du jeu rétablie")
U.verifier(mannequin.Buste.Color == busteAvant, "mannequin rétabli")
scene:photo({ decor = "nuit", lumiere = "doux", mannequin = "bois" })
etat.etape = "carnet"
scene:synchroniser(etat, nil)
U.verifier(scene.dossier:FindFirstChild("Fond") == nil and Lighting.ClockTime == lumiereAvant[1], "quitter la présentation rétablit tout")
scene:detruire()
