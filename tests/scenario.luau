-- Scénario : parties complètes pilotées par l'interface + tentatives de triche + contrôles 3D
local nbVerifs = 0
local function verifier(condition, message)
	nbVerifs += 1
	if not condition then
		error("ÉCHEC : " .. message, 2)
	end
end
local function proche(a, b, tol)
	return math.abs(a - b) <= (tol or 1e-6)
end
local function fini(n)
	return n == n and n ~= math.huge and n ~= -math.huge
end

---------------------------------------------------------------------------
-- Démarrage : serveur, joueur, client
---------------------------------------------------------------------------
local game = M.initialiser()
local RS = M.services.ReplicatedStorage
local dossier = M.nouvelleInstance("Folder")
dossier.Name = "Couture"
dossier.Parent = RS
for _, nom in ipairs({ "CoutureData", "Rendu3D" }) do
	local ms = M.nouvelleInstance("ModuleScript")
	ms.Name = nom
	ms.Parent = dossier
end
local scriptServeur = M.nouvelleInstance("Script")
scriptServeur.Name = "AtelierServer"
scriptServeur.Parent = M.services.ServerScriptService
SCRIPTS.AtelierServer(scriptServeur)

local CoutureData = requireModule(dossier.CoutureData)
local Rendu3D = requireModule(dossier.Rendu3D)
local remote = dossier:WaitForChild("CoutureRemote")
local workspace = M.services.Workspace

verifier(workspace:FindFirstChild("Etabli") ~= nil, "l'établi existe")
verifier(workspace.Etabli:FindFirstChild("AtelierPrompt") ~= nil, "l'invite de l'établi existe")
local mannequinAtelier = workspace:FindFirstChild("MannequinAtelier")
verifier(mannequinAtelier ~= nil, "le mannequin de l'atelier existe")
verifier(mannequinAtelier:FindFirstChild(Rendu3D.NOM_VETEMENT) ~= nil, "le mannequin porte la robe d'exemple")

M.ping = 0.03
local joueur = M.nouveauJoueur("Testeur")
local perso = M.personnage("R15")
perso.Parent = workspace
joueur.Character = perso
M.services.Players.PlayerAdded:Fire(joueur)
joueur.CharacterAppearanceLoaded:Fire(perso)
verifier(joueur.leaderstats.Argent.Value == 100, "argent de départ")

rawget(M.services.Players, "__props").LocalPlayer = joueur
M.joueurLocal = joueur
local scriptClient = M.nouvelleInstance("LocalScript")
scriptClient.Name = "AtelierClient"
SCRIPTS.AtelierClient(scriptClient)

local gui = joueur.PlayerGui

---------------------------------------------------------------------------
-- Outils d'interface
---------------------------------------------------------------------------
local function estVisible(inst)
	local i = inst
	while i and i ~= gui do
		if i:IsA("GuiObject") and not i.Visible then
			return false
		end
		i = i.Parent
	end
	return true
end
local function boutons(motif)
	local out = {}
	for _, d in ipairs(gui:GetDescendants()) do
		if d:IsA("TextButton") and estVisible(d) and string.find(d.Text, motif, 1, true) then
			table.insert(out, d)
		end
	end
	return out
end
local function bouton(motif)
	local liste = boutons(motif)
	verifier(#liste == 1, ("un seul bouton « %s » (trouvé %d)"):format(motif, #liste))
	return liste[1]
end
local function cliquer(motif)
	M.avancer(0.25)
	bouton(motif).Activated:Fire()
end
local function texteContenant(motif)
	for _, d in ipairs(gui:GetDescendants()) do
		if d:IsA("TextLabel") and estVisible(d) and string.find(d.Text, motif, 1, true) then
			return d
		end
	end
	return nil
end
verifier(gui.AtelierCouture.Fenetre.Visible, "la fenêtre s'ouvre au démarrage")
verifier(texteContenant("Bienvenue dans ton atelier") ~= nil, "écran d'accueil")
verifier(texteContenant("100 $") ~= nil, "l'argent est affiché")

-- Fermer puis rouvrir par l'invite de l'établi
cliquer("✕")
verifier(not gui.AtelierCouture.Fenetre.Visible, "la croix ferme la fenêtre")
M.services.ProximityPromptService.PromptTriggered:Fire(workspace.Etabli.AtelierPrompt, joueur)
verifier(gui.AtelierCouture.Fenetre.Visible, "l'établi rouvre la fenêtre")
cliquer("Atelier")
verifier(not gui.AtelierCouture.Fenetre.Visible, "le bouton Atelier bascule la fenêtre")
cliquer("Atelier")
verifier(gui.AtelierCouture.Fenetre.Visible, "le bouton Atelier rouvre la fenêtre")

---------------------------------------------------------------------------
-- Contrôles du vêtement 3D
---------------------------------------------------------------------------
local function orthonormee(c)
	local r = c.r
	local cols = {
		Vector3.new(r[1], r[4], r[7]),
		Vector3.new(r[2], r[5], r[8]),
		Vector3.new(r[3], r[6], r[9]),
	}
	for i = 1, 3 do
		if not proche(cols[i].Magnitude, 1, 1e-6) then
			return false
		end
		for j = i + 1, 3 do
			if not proche(cols[i]:Dot(cols[j]), 0, 1e-6) then
				return false
			end
		end
	end
	-- repère direct (déterminant +1)
	return proche(cols[1]:Cross(cols[2]):Dot(cols[3]), 1, 1e-6)
end

local function coins(p)
	local out = {}
	local s = p.Size / 2
	for _, dx in ipairs({ -1, 1 }) do
		for _, dy in ipairs({ -1, 1 }) do
			for _, dz in ipairs({ -1, 1 }) do
				table.insert(out, p.CFrame * Vector3.new(s.X * dx, s.Y * dy, s.Z * dz))
			end
		end
	end
	return out
end

local function controlerVetement(modele, etiquette, sol)
	local vetement = modele:FindFirstChild(Rendu3D.NOM_VETEMENT)
	verifier(vetement ~= nil, etiquette .. " : vêtement présent")
	local torse = modele:FindFirstChild("UpperTorso") or modele:FindFirstChild("Torso")
	local pieces = 0
	local basMin = math.huge
	for _, p in ipairs(vetement:GetDescendants()) do
		if p:IsA("BasePart") then
			pieces += 1
			local c = p.CFrame
			for _, n in ipairs({ c.p.X, c.p.Y, c.p.Z, p.Size.X, p.Size.Y, p.Size.Z }) do
				verifier(fini(n), etiquette .. " : valeurs finies (pas de NaN)")
			end
			for _, n in ipairs(c.r) do
				verifier(fini(n), etiquette .. " : rotation finie")
			end
			verifier(orthonormee(c), etiquette .. " : rotation orthonormée")
			verifier(p.Massless and not p.CanCollide and not p.Anchored, etiquette .. " : pièce sans masse ni collision")
			local soudure = p:FindFirstChildOfClass_("Weld")
			verifier(soudure ~= nil, etiquette .. " : pièce soudée")
			verifier(soudure.Part1 == p, etiquette .. " : Part1 = pièce")
			verifier(soudure.Part0.Parent == modele, etiquette .. " : soudée à une partie du corps")
			local attendu = soudure.Part0.CFrame * soudure.C0
			verifier((attendu.p - c.p).Magnitude < 1e-6, etiquette .. " : C0 cohérent avec la position")
			verifier((c.p - torse.CFrame.p).Magnitude < 5.5, etiquette .. " : pièce près du corps")
			for _, coin in ipairs(coins(p)) do
				basMin = math.min(basMin, coin.Y)
			end
		end
	end
	verifier(pieces > 0, etiquette .. " : au moins une pièce")
	verifier(basMin > sol + 0.05, ("%s : rien ne touche le sol (bas = %.2f)"):format(etiquette, basMin))
	return pieces, vetement
end

-- FindFirstChildOfClass n'est pas utilisé par le jeu : petit utilitaire du test
local function premierEnfantDeClasse(inst, classe)
	for _, e in ipairs(inst:GetChildren()) do
		if e.ClassName == classe then
			return e
		end
	end
	return nil
end
-- branché sur les instances via une fonction locale
local controler = function(modele, etiquette, sol)
	-- remplace l'appel de méthode par la fonction locale
	local vetement = modele:FindFirstChild(Rendu3D.NOM_VETEMENT)
	verifier(vetement ~= nil, etiquette .. " : vêtement présent")
	for _, p in ipairs(vetement:GetDescendants()) do
		if p:IsA("BasePart") then
			rawset(p, "FindFirstChildOfClass_", function(self, classe)
				return premierEnfantDeClasse(self, classe)
			end)
		end
	end
	return controlerVetement(modele, etiquette, sol)
end

---------------------------------------------------------------------------
-- 1. Rendu 3D : toutes les combinaisons
---------------------------------------------------------------------------
local corps = {
	{ "R15", function()
		return M.personnage("R15", 0)
	end, 0 },
	{ "R15 tourné", function()
		return M.personnage("R15", 1.1)
	end, 0 },
	{ "R6", function()
		return M.personnage("R6", 0)
	end, 0 },
	{ "mannequin", function()
		return Rendu3D.creerMannequin(CFrame.new(3, 0, -2) * CFrame.Angles(0, math.pi, 0))
	end, 0 },
}
local toutesDecos = {}
for _, d in ipairs(CoutureData.Decorations) do
	table.insert(toutesDecos, d.id)
end
local combinaisons = 0
for _, c in ipairs(corps) do
	for _, v in ipairs(CoutureData.Vetements) do
		for _, decos in ipairs({ {}, toutesDecos, { "dentelle" }, { "boutons" }, { "ruban" }, { "broderie" } }) do
			for _, qualite in ipairs({ { 1, 1, 0 }, { 0, 0, 3 }, { 0.5, 0.2, 1 } }) do
				local modele = c[2]()
				local spec = {
					vetement = v.id,
					tissu = "soie_rose",
					decorations = decos,
					decoupe = qualite[1],
					couture = qualite[2],
					pivotees = qualite[3],
					graine = 99 + combinaisons,
				}
				verifier(Rendu3D.habiller(modele, spec) ~= nil, "habiller renvoie le vêtement")
				controler(modele, ("%s / %s / %d décos / défaut %.1f"):format(c[1], v.id, #decos, 1 - (qualite[1] + qualite[2]) / 2), c[3])
				combinaisons += 1
			end
		end
	end
end

-- Jupe et robe : les panneaux sous les hanches restent hors des jambes (R15 de face)
for _, id in ipairs({ "jupe", "robe" }) do
	local modele = M.personnage("R15", 0)
	Rendu3D.habiller(modele, { vetement = id, tissu = "coton_rose", decorations = {}, decoupe = 1, couture = 1, pivotees = 0, graine = 3 })
	for _, p in ipairs(modele[Rendu3D.NOM_VETEMENT]:GetChildren()) do
		local pos = p.CFrame.p
		if pos.Y < 2.6 then
			verifier(not (math.abs(pos.X) < 1 and math.abs(pos.Z) < 0.5), id .. " : panneau hors des jambes")
		end
	end
end

-- Le vêtement suit l'orientation du corps
do
	local a, b = M.personnage("R15", 0), M.personnage("R15", 1.1)
	local spec = { vetement = "robe", tissu = "lin_noir", decorations = toutesDecos, decoupe = 0.7, couture = 0.6, pivotees = 1, graine = 5 }
	Rendu3D.habiller(a, spec)
	Rendu3D.habiller(b, spec)
	local pa, pb = a[Rendu3D.NOM_VETEMENT]:GetChildren(), b[Rendu3D.NOM_VETEMENT]:GetChildren()
	verifier(#pa == #pb, "même nombre de pièces quelle que soit l'orientation")
	for i = 1, #pa do
		local la = a.UpperTorso.CFrame:ToObjectSpace(pa[i].CFrame).p
		local lb = b.UpperTorso.CFrame:ToObjectSpace(pb[i].CFrame).p
		verifier((la - lb).Magnitude < 1e-6, "le vêtement tourne avec le corps")
	end
	-- Rhabiller remplace l'ancien vêtement, déshabiller l'enlève
	Rendu3D.habiller(a, spec)
	local n = 0
	for _, e in ipairs(a:GetChildren()) do
		if e.Name == Rendu3D.NOM_VETEMENT then
			n += 1
		end
	end
	verifier(n == 1, "un seul vêtement à la fois")
	Rendu3D.deshabiller(a)
	verifier(a:FindFirstChild(Rendu3D.NOM_VETEMENT) == nil, "déshabiller enlève le vêtement")
	verifier(Rendu3D.habiller(a, nil) == nil, "spec absente : aucun vêtement")
	verifier(Rendu3D.habiller(a, { vetement = "cape", tissu = "x" }) == nil, "spec inconnue : aucun vêtement")
	verifier(Rendu3D.habiller(M.nouvelleInstance("Model"), spec) == nil, "modèle sans torse : aucun vêtement")
end
print(("Rendu 3D : %d combinaisons contrôlées"):format(combinaisons))

---------------------------------------------------------------------------
-- 2. Parties complètes pilotées par l'interface
---------------------------------------------------------------------------
local DISPOSITIONS = {
	jupe = { { 0, 0 }, { 4, 0 }, { 0, 5 } },
	haut = { { 0, 0 }, { 4, 0 }, { 8, 0 }, { 10, 0 } },
	robe = { { 0, 5 }, { 4, 5 }, { 0, 0 }, { 5, 0 }, { 0, 8 } },
}

local function derniereReponse()
	return M.dernierAppel.reponse
end

local function trouverCase(x, y)
	for _, d in ipairs(gui:GetDescendants()) do
		if d:IsA("TextButton") and d.Text == "" and d.Size.X.Offset == 34 and d.Size.Y.Offset == 34 then
			if d.Position.X.Offset == x * 34 and d.Position.Y.Offset == y * 34 then
				return d
			end
		end
	end
	error("case introuvable " .. x .. "," .. y)
end

local function meilleurInstant(p)
	local centre = p.zoneDebut + p.zoneLargeur / 2
	local meilleur, ecart = 0, math.huge
	for i = 0, 3000 do
		local t = i / 1000
		local e = math.abs(CoutureData.positionAiguille(p, t) - centre)
		if e < ecart then
			meilleur, ecart = t, e
		end
	end
	return meilleur
end

local vus = {}
local manche = 0
local argentAvant
local function jouerManche(options)
	manche += 1
	options = options or {}
	cliquer(manche == 1 and "Ouvrir la boutique" or "Client suivant")
	local rep = derniereReponse()
	verifier(rep.ok and rep.commande, "commande reçue : " .. tostring(rep.erreur))
	local commande = rep.commande
	verifier(texteContenant(commande.client) ~= nil, "le nom du client est affiché")
	verifier(texteContenant(commande.texte) ~= nil, "la phrase du client est affichée")
	local vetement = CoutureData.getVetement(commande.vetement)
	vus[vetement.id] = true
	cliquer("Accepter la commande")

	-- Tissu de la bonne couleur (ou volontairement faux)
	local tissuChoisi
	for _, t in ipairs(CoutureData.Tissus) do
		if (t.teinte == commande.teinte) ~= (options.mauvaiseCouleur == true) then
			tissuChoisi = t
			break
		end
	end
	argentAvant = joueur.leaderstats.Argent.Value
	local carte = texteContenant(tissuChoisi.nom).Parent
	verifier(carte:IsA("TextButton"), "carte de tissu cliquable")
	M.avancer(0.25)
	carte.Activated:Fire()
	verifier(derniereReponse().ok, "achat du tissu : " .. tostring(derniereReponse().erreur))
	verifier(joueur.leaderstats.Argent.Value == argentAvant - tissuChoisi.prix, "le tissu est payé")

	-- Découpe
	M.avancer(0.3)
	for i, piece in ipairs(vetement.pieces) do
		local pos = DISPOSITIONS[vetement.id][i]
		cliquer(piece.nom .. " — à placer")
		if options.pivoter == i then
			cliquer("Pivoter")
			local l, h = CoutureData.taillePiece(piece, true)
			-- zone libre en bas à droite pour la pièce pivotée
			pos = { 12 - l, 10 - h }
		end
		trouverCase(pos[1], pos[2]).MouseEnter:Fire()
		trouverCase(pos[1], pos[2]).Activated:Fire()
	end
	local attenduDecoupe = options.pivoter and "Qualité de la découpe" or "Qualité de la découpe : 100 %"
	verifier(texteContenant(attenduDecoupe) ~= nil, "note de découpe affichée")
	M.avancer(0.3)
	cliquer("Couper")
	rep = derniereReponse()
	verifier(rep.ok, "la couture commence : " .. tostring(rep.erreur))
	if not options.pivoter then
		verifier(proche(rep.decoupe, 1), "découpe parfaite validée par le serveur")
	else
		verifier(rep.decoupe < 1, "une pièce pivotée baisse la note de découpe")
	end

	-- Couture
	local params = rep.couture
	local recu = M.horloge
	for s = 1, #vetement.coutures do
		verifier(params.indice == s and params.total == #vetement.coutures, "paramètres de couture cohérents")
		local t = options.couturesRatees and 0 or meilleurInstant(params)
		if options.couturesRatees then
			-- pique au pire moment : le plus loin possible de la zone
			local centre = params.zoneDebut + params.zoneLargeur / 2
			local pire, e = 0, -1
			for i = 0, 3000 do
				local tt = i / 1000
				local d = math.abs(CoutureData.positionAiguille(params, tt) - centre)
				if d > e then
					pire, e = tt, d
				end
			end
			t = pire
		end
		M.avancer(recu + (params.delai or 0) + t - M.horloge)
		if s == 2 then
			-- la touche Espace passe par ContextActionService
			local action = M.actions.AtelierPiquer
			verifier(action ~= nil, "Espace est lié à la piqûre")
			action.f("AtelierPiquer", Enum.UserInputState.Begin, nil)
		else
			bouton("Piquer !").Activated:Fire()
		end
		rep = derniereReponse()
		verifier(rep.ok, "piqûre acceptée : " .. tostring(rep.erreur))
		if options.couturesRatees then
			verifier(rep.precision < 0.5, "piqûre ratée mal notée")
		else
			verifier(rep.precision > 0.97, ("piqûre au bon moment bien notée (%.3f)"):format(rep.precision))
		end
		recu = M.horloge
		if s < #vetement.coutures then
			verifier(rep.suivante ~= nil and not rep.terminee, "couture suivante envoyée")
			params = rep.suivante
		else
			verifier(rep.terminee, "dernière couture terminée")
		end
	end
	M.avancer(1)
	cliquer("Finitions")

	-- Finitions avec aperçu 3D
	local vues = {}
	for _, d in ipairs(gui:GetDescendants()) do
		if d:IsA("ViewportFrame") then
			table.insert(vues, d)
		end
	end
	verifier(#vues == 1, "un aperçu 3D dans les finitions")
	local modeleApercu
	for _, e in ipairs(vues[1]:GetChildren()) do
		if e:IsA("Model") then
			modeleApercu = e
		end
	end
	verifier(modeleApercu ~= nil and modeleApercu:FindFirstChild(Rendu3D.NOM_VETEMENT) ~= nil, "le mannequin de l'aperçu est habillé")
	verifier(vues[1].CurrentCamera ~= nil, "l'aperçu a une caméra")
	local camAvant = vues[1].CurrentCamera.CFrame.p
	M.avancer(0.5)
	verifier((vues[1].CurrentCamera.CFrame.p - camAvant).Magnitude > 0.01, "l'aperçu tourne")
	local nAvant = #modeleApercu[Rendu3D.NOM_VETEMENT]:GetChildren()
	local decosAChoisir = options.sansFinition and {} or { commande.deco or "ruban" }
	for _, id in ipairs(decosAChoisir) do
		cliquer(CoutureData.getDecoration(id).nom)
	end
	if #decosAChoisir > 0 then
		verifier(#modeleApercu[Rendu3D.NOM_VETEMENT]:GetChildren() > nAvant, "l'aperçu se met à jour avec la finition")
	end
	-- Ouvrir / fermer une finition inutile ne change rien
	cliquer("Broderie florale")
	cliquer("Broderie florale")
	argentAvant = joueur.leaderstats.Argent.Value
	cliquer("Livrer au client")
	rep = derniereReponse()
	verifier(rep.ok, "livraison acceptée : " .. tostring(rep.erreur))
	verifier(joueur.leaderstats.Argent.Value == argentAvant - rep.coutFinitions + rep.paiement, "argent mis à jour")
	if options.parfait then
		verifier(rep.etoiles == 5, ("5 étoiles pour un travail parfait (obtenu %d)"):format(rep.etoiles))
	end
	if options.mauvaiseCouleur then
		verifier(rep.notes.couleur < 0.5, "mauvaise couleur pénalisée")
	end
	if options.couturesRatees then
		verifier(rep.etoiles <= 3, "coutures ratées : au plus 3 étoiles")
	end
	verifier(texteContenant(string.rep("★", rep.etoiles)) ~= nil, "étoiles affichées")
	verifier(texteContenant(rep.commentaire) ~= nil, "commentaire du client affiché")

	-- Mannequin de l'atelier et aperçu du résultat
	controler(mannequinAtelier, "mannequin de l'atelier (" .. vetement.id .. ")", 0)
	local vetementMannequin = mannequinAtelier[Rendu3D.NOM_VETEMENT]
	verifier(vetementMannequin ~= nil, "la création est exposée")
	local n = 0
	for _, d in ipairs(gui:GetDescendants()) do
		if d:IsA("ViewportFrame") then
			n += 1
		end
	end
	verifier(n == 1, "un aperçu 3D dans le résultat")

	-- Porter sur l'avatar, retirer, reporter
	cliquer("Porter sur mon avatar")
	verifier(derniereReponse().ok, "porter accepté")
	controler(joueur.Character, "avatar (" .. vetement.id .. ")", 0)
	cliquer("Retirer")
	verifier(joueur.Character:FindFirstChild(Rendu3D.NOM_VETEMENT) == nil, "retirer enlève le vêtement")
	cliquer("Porter sur mon avatar")
	verifier(joueur.Character:FindFirstChild(Rendu3D.NOM_VETEMENT) ~= nil, "porter à nouveau")
	M.avancer(0.5)
	return rep
end

jouerManche({ parfait = true })
jouerManche({ parfait = true })
jouerManche({ pivoter = 1 })
jouerManche({ mauvaiseCouleur = true })
jouerManche({ couturesRatees = true, sansFinition = true })
local tours = 0
while not (vus.jupe and vus.haut and vus.robe) and tours < 20 do
	jouerManche({ parfait = true })
	tours += 1
end
verifier(vus.jupe and vus.haut and vus.robe, "les trois vêtements ont été joués")
print(("Parties jouées par l'interface : %d (argent final %d $, réputation %d)"):format(
	manche,
	joueur.leaderstats.Argent.Value,
	joueur.leaderstats["Réputation"].Value
))

-- Réapparition : le vêtement porté revient sur le nouveau personnage
do
	local nouveau = M.personnage("R6", 0.4)
	nouveau.Parent = workspace
	joueur.Character = nouveau
	joueur.CharacterAppearanceLoaded:Fire(nouveau)
	controler(nouveau, "avatar après réapparition (R6)", 0)
end

---------------------------------------------------------------------------
-- 3. Tentatives de triche (appels directs au serveur)
---------------------------------------------------------------------------
local function appel(action, argument)
	M.avancer(0.25)
	return remote:InvokeServer(action, argument)
end

local r = appel("NouvelleCommande")
verifier(r.ok, "nouvelle commande (triche)")
local vetement = CoutureData.getVetement(r.commande.vetement)
verifier(not remote:InvokeServer("NouvelleCommande").ok, "appels trop rapprochés refusés")
verifier(not appel("CommencerCouture", {}).ok, "pas de couture sans tissu")
verifier(not appel("AcheterTissu", "tissu_en_or").ok, "tissu inconnu refusé")
local argent = joueur.leaderstats.Argent.Value
verifier(appel("AcheterTissu", "coton_blanc").ok, "achat de tissu")
verifier(not appel("AcheterTissu", "coton_blanc").ok, "pas de second achat")
verifier(joueur.leaderstats.Argent.Value == argent - 10, "un seul tissu payé")
verifier(not appel("Livrer", {}).ok, "pas de livraison avant la couture")

-- Découpe incomplète refusée, pièces hors du coupon comptées comme ratées
verifier(not appel("CommencerCouture", { { i = 1, x = 0, y = 0 } }).ok, "découpe incomplète refusée")
local liste = {}
for i = 1, #vetement.pieces do
	table.insert(liste, { i = i, x = 500, y = -3 })
end
verifier(not appel("CommencerCouture", "n'importe quoi").ok, "données de découpe invalides refusées")
r = appel("CommencerCouture", liste)
verifier(r.ok and r.decoupe == 0, "pièces hors du coupon : découpe à 0")
local recuDebut = M.horloge
verifier(not appel("CommencerCouture", liste).ok, "impossible de relancer la couture pour retirer la zone")

-- Annoncer l'instant idéal alors que le temps réel est différent
local p = r.couture
local recu = recuDebut
local ideal = meilleurInstant(p)
local faux = ideal + 1.0 -- on attend 1 s de plus que l'idéal
M.avancer(recu + faux - M.horloge)
local reel = M.horloge - recu - 1.5 * M.ping
r = remote:InvokeServer("Piquer", ideal)
verifier(r.ok, "piqûre traitée")
local tolerance = 0.08 + 0.5 * M.ping
local tempsRetenu = math.clamp(ideal, reel - tolerance, reel + tolerance)
verifier(proche(r.position, CoutureData.positionAiguille(p, tempsRetenu), 1e-6), "le serveur retient son propre chronomètre")
verifier(not proche(r.position, CoutureData.positionAiguille(p, ideal), 0.02), "le temps annoncé par le client est ignoré")

-- Piquer pendant la pause entre deux coutures
local r2 = remote:InvokeServer("Piquer", 0)
verifier(not r2.ok, "piqûre pendant la pause refusée")
-- Précision inventée : impossible, seul un nombre de secondes est accepté
M.avancer(CoutureData.PAUSE_ENTRE_COUTURES + 0.2)
r2 = remote:InvokeServer("Piquer", { precision = 1 })
verifier(r2.ok and r2.precision <= 1, "argument farfelu : le serveur utilise son chronomètre")
verifier(not appel("Livrer", {}).ok, "pas de livraison avant la fin des coutures")
while not r2.terminee do
	M.avancer(CoutureData.PAUSE_ENTRE_COUTURES + 0.3)
	r2 = remote:InvokeServer("Piquer", 0)
	verifier(r2.ok, "coutures suivantes")
end
verifier(not remote:InvokeServer("Piquer", 0).ok, "pas de piqûre après la dernière couture")
argent = joueur.leaderstats.Argent.Value
r = appel("Livrer", { decorations = { "dentelle", "dentelle", "inconnue", 12, { "x" } } })
verifier(r.ok, "livraison avec finitions farfelues")
verifier(r.coutFinitions == 8, "finition en double payée une seule fois, inconnues ignorées")
verifier(not appel("Livrer", {}).ok, "pas de double livraison")
verifier(not appel("Hacker").ok, "action inconnue refusée")
verifier(appel("Retirer").ok and appel("Porter").ok, "porter / retirer par le serveur")

-- Sauvegarde : en Studio sans API, rien ne plante
M.services.Players.PlayerRemoving:Fire(joueur)
M.fermeture()

print(("Triche : toutes les tentatives sont bloquées. Avertissements : %d"):format(#M.avertissements))
for _, a in ipairs(M.avertissements) do
	print("  warn: " .. a)
end
print(("TOUT EST VERT : %d vérifications"):format(nbVerifs))
