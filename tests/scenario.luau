-- Scénario du nouvel atelier : le serveur et le client démarrés comme dans le jeu, une commande jouée
-- de bout en bout en cliquant dans l'interface, comme le ferait un joueur, puis des tentatives de triche.
local nbVerifs = 0
local function verifier(condition, message)
	nbVerifs += 1
	if not condition then
		error("ÉCHEC : " .. message, 2)
	end
end

---------------------------------------------------------------------------
-- Démarrage : modules partagés, joueur, script du client
---------------------------------------------------------------------------
local game = M.initialiser()
local RS = M.services.ReplicatedStorage
local dossier = M.nouvelleInstance("Folder")
dossier.Name = "Couture"
dossier.Parent = RS
for _, nom in ipairs(NOMS_PARTAGES) do
	local ms = M.nouvelleInstance("ModuleScript")
	ms.Name = nom
	ms.Parent = dossier
end
local joueur = M.nouveauJoueur("Testeur")
rawget(M.services.Players, "__props").LocalPlayer = joueur
M.joueurLocal = joueur
-- Lieu publié : les parties sont sauvegardées (DataStores en mémoire du faux Roblox). La partie du joueur
-- a été écrite par une version plus récente du jeu : il joue sans sauvegarde, et elle n'est jamais écrasée.
rawget(game, "__props").PlaceId = 4242
rawget(game, "__props").JobId = "serveur-scenario"
M.magasins = { AtelierCouture_v2 = M.nouveauMagasin() }
M.magasins.AtelierCouture_v2.donnees["joueur_" .. joueur.UserId] = { version = 99, argent = 5000 }
-- Serveur (il fait foi) : démarré avant le client, qui attend sa RemoteFunction « Atelier »
local scriptServeur = M.nouvelleInstance("Script")
scriptServeur.Name = "Atelier"
for _, nom in ipairs(NOMS_SERVEUR) do
	local ms = M.nouvelleInstance("ModuleScript")
	ms.Name = nom
	ms.Parent = scriptServeur
end
scriptServeur.Parent = M.services.ServerScriptService
SCRIPTS.Serveur(scriptServeur)
local serveur = requireModule(scriptServeur.Commande).courante
local scriptClient = M.nouvelleInstance("LocalScript")
scriptClient.Name = "Atelier"
for _, nom in ipairs(NOMS_CLIENT) do
	local ms = M.nouvelleInstance("ModuleScript")
	ms.Name = nom
	ms.Parent = scriptClient
end
SCRIPTS.Atelier(scriptClient)
local Catalogue = requireModule(dossier.Catalogue)
local EtatAtelier = requireModule(dossier.EtatAtelier)

local gui = joueur.PlayerGui
local fenetre = gui.Atelier.Fenetre

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
local function boutonNomme(nom)
	local trouves = {}
	for _, d in ipairs(gui:GetDescendants()) do
		if d:IsA("GuiButton") and d.Name == nom and estVisible(d) then
			table.insert(trouves, d)
		end
	end
	verifier(#trouves == 1, ("un seul bouton « %s » visible (trouvé %d)"):format(nom, #trouves))
	return trouves[1]
end
local function cliquer(nom)
	M.avancer(0.5) -- un joueur ne clique pas plus vite (les boutons ignorent un double clic trop rapide)
	boutonNomme(nom).Activated:Fire()
end
local function texte(nomOuMotif)
	for _, d in ipairs(gui:GetDescendants()) do
		if d:IsA("TextLabel") and estVisible(d) and (d.Name == nomOuMotif or string.find(d.Text, nomOuMotif, 1, true)) then
			return d
		end
	end
	return nil
end
-- Règle de la spec §4 : les textes mesurent au moins 14 px à l'échelle 1
-- Et aucun texte laissé à celui de Roblox (« Label », « Button ») : un texte jamais réglé
local function verifierTailles(ecran)
	local petits, parDefaut = {}, {}
	for _, d in ipairs(gui:GetDescendants()) do
		if (d:IsA("TextLabel") or d:IsA("TextButton")) and estVisible(d) and d.Text ~= "" and d.TextSize < 14 then
			table.insert(petits, d.Name .. "=" .. d.TextSize)
		end
		if (d:IsA("TextLabel") or d:IsA("TextButton")) and estVisible(d) and (d.Text == "Label" or d.Text == "Button") then
			table.insert(parDefaut, d.Name)
		end
	end
	verifier(#petits == 0, ecran .. " : textes d'au moins 14 px ; trop petits : " .. table.concat(petits, ", "))
	verifier(#parDefaut == 0, ecran .. " : aucun texte laissé à celui de Roblox ; en défaut : " .. table.concat(parDefaut, ", "))
end
local function titre()
	return fenetre.Titre.Text
end
local function argent()
	return tonumber(fenetre.Argent.Text:match("^(%d+)"))
end

---------------------------------------------------------------------------
-- Accueil
---------------------------------------------------------------------------
verifier(fenetre.Visible, "la fenêtre s'ouvre au démarrage")
verifier(titre() == "Aiguille & Dentelle", "écran d'accueil")
verifier(argent() == 150, "150 pièces d'or au départ")
local parties = M.magasins.AtelierCouture_v2
local cleJoueur = "joueur_" .. joueur.UserId
verifier(parties.donnees[cleJoueur].version == 99 and serveur:atelier(joueur) ~= nil and not serveur:atelier(joueur).sauvable, "partie illisible : le joueur joue sans sauvegarde")
-- La rue : le serveur a construit la boutique du joueur à l'emplacement qu'il lui a donné
local numeroBoutique = joueur:GetAttribute("Boutique")
local maBoutique = M.services.Workspace.Rue:FindFirstChild("Boutique_" .. tostring(numeroBoutique))
verifier(numeroBoutique == 1 and maBoutique ~= nil and maBoutique:GetAttribute("Proprietaire") == joueur.UserId, "le serveur a construit la boutique du joueur dans la rue")
local maVitrine = M.services.Workspace.Vitrines:FindFirstChild("Vitrine_" .. numeroBoutique)
verifier(maVitrine ~= nil and maVitrine:GetAttribute("Recette") == nil, "sa vitrine, sur la rue, est vide")
-- L'atelier du client est dans sa boutique : les vues attendues sont dans le repère de la boutique
local origineBoutique = requireModule(dossier.Boutique).emplacement(numeroBoutique)
verifier(fenetre.Message.Visible and string.find(fenetre.Message.Text, "sauvegardée", 1, true) ~= nil, "le joueur est prévenu que sa partie ne sera pas sauvegardée")
verifierTailles("accueil")
cliquer("Fermer")
verifier(not fenetre.Visible, "la croix ferme la fenêtre")
cliquer("OuvrirAtelier")
verifier(fenetre.Visible, "le bouton Atelier rouvre la fenêtre")
-- Sons : la musique d'ambiance joue ; le bouton « Son » coupe tout, puis rétablit
local SoundService = M.services.SoundService
local function sonsDepuis(n)
	local out = {}
	for k = n + 1, #(M.sonsJoues or {}) do
		table.insert(out, M.sonsJoues[k])
	end
	return table.concat(out, ",")
end
local function nombreSons()
	return #(M.sonsJoues or {})
end
verifier(SoundService:FindFirstChild("Atelier_musique") ~= nil and SoundService.Atelier_musique.IsPlaying, "la musique d'ambiance joue")
-- « Son » est dans la barre de titre, sans rien chevaucher ; « Atelier » n'apparaît que fenêtre fermée (sur
-- tablette et téléphone, la fenêtre centrée passe sous le bord gauche de l'écran)
local function rectangle(e)
	local W, H = fenetre.Size.X.Offset, fenetre.Size.Y.Offset
	local ancre = e.AnchorPoint or Vector2.new()
	local l, h = e.Size.X.Scale * W + e.Size.X.Offset, e.Size.Y.Scale * H + e.Size.Y.Offset
	local x, y = e.Position.X.Scale * W + e.Position.X.Offset - ancre.X * l, e.Position.Y.Scale * H + e.Position.Y.Offset - ancre.Y * h
	return x, y, x + l, y + h
end
local function chevauche(a, b)
	local ax0, ay0, ax1, ay1 = rectangle(a)
	local bx0, by0, bx1, by1 = rectangle(b)
	return ax0 < bx1 and bx0 < ax1 and ay0 < by1 and by0 < ay1
end
local function sonALaPlace()
	local son = fenetre:FindFirstChild("Son")
	return son ~= nil and not chevauche(son, fenetre.Titre) and not chevauche(son, fenetre.Argent) and not chevauche(son, fenetre.Fermer) and not chevauche(son, fenetre.Contenu) and not chevauche(fenetre.Titre, fenetre.Argent)
end
verifier(sonALaPlace(), "« Son » dans la barre de titre de la fenêtre, sans rien chevaucher")
verifier(not gui.Atelier.OuvrirAtelier.Visible, "fenêtre ouverte : « Atelier » caché (il passerait sur la fenêtre)")
cliquer("Fermer")
verifier(gui.Atelier.OuvrirAtelier.Visible, "fenêtre fermée : « Atelier » pour la rouvrir")
cliquer("OuvrirAtelier")
cliquer("Son")
verifier(boutonNomme("Son").Text == "Son : non" and not SoundService.Atelier_musique.IsPlaying, "« Son » : la musique s'arrête")
local nCoupe = nombreSons()
cliquer("Fermer")
cliquer("OuvrirAtelier")
verifier(nombreSons() == nCoupe, "son coupé : les boutons ne font plus de bruit")
cliquer("Son")
verifier(boutonNomme("Son").Text == "Son : oui" and SoundService.Atelier_musique.IsPlaying, "« Son » de nouveau : la musique reprend")
local nSons = nombreSons()
-- Un serveur lent (0,5 s) : au-delà de 0,3 s, « Un instant… » en gris sous la fenêtre, jusqu'à la réponse ;
-- un message déjà affiché (l'avertissement de la sauvegarde) n'est pas remplacé
local GRIS = Color3.fromRGB(130, 100, 115)
local remoteAtelier = RS.Atelier
local brancheServeur = remoteAtelier.OnServerInvoke
local pendantAttente
local function serveurLent(...)
	M.avancer(0.5)
	pendantAttente = { visible = fenetre.Message.Visible, texte = fenetre.Message.Text, couleur = fenetre.Message.TextColor3 }
	return brancheServeur(...)
end
verifier(fenetre.Contenu:FindFirstChild("RobeLibre") == nil, "aucune commande livrée : pas encore de robe libre")
remoteAtelier.OnServerInvoke = serveurLent
cliquer("Clochette")
remoteAtelier.OnServerInvoke = brancheServeur
verifier(M.dernierAppel ~= nil and M.dernierAppel.action == "nouvelleCommande" and serveur:atelier(joueur).etat.etape == "mesures", "la commande passe par le serveur, qui fait foi")
verifier(pendantAttente ~= nil and pendantAttente.visible and string.find(pendantAttente.texte, "sauvegardée", 1, true) ~= nil, "serveur lent : l'avertissement affiché n'est pas remplacé")
verifier(sonsDepuis(nSons) == "Atelier_clic,Atelier_clochette", "sons : le clic du bouton, puis la clochette (" .. sonsDepuis(nSons) .. ")")
verifier(fenetre.Message.Visible and fenetre.Message.Text == ("Colette verse un acompte de %d pièces d'or."):format(serveur:atelier(joueur).etat.commande.acompte), "la cliente verse un acompte")

---------------------------------------------------------------------------
-- Les mesures : Colette vient pour la première fois ; les rubans partent courts, on les règle au bord de sa
-- silhouette (boutons − et +, au 0,1 dm près)
---------------------------------------------------------------------------
local Clientes = requireModule(dossier.Clientes)
local MESURES = { "poitrine", "taille", "hanches" }
verifier(titre() == "Les mesures" and texte("Colette Marchand") ~= nil, "première visite de Colette : ses mesures")
verifier(fenetre.Contenu:FindFirstChild("ReprendreMesures") == nil, "première visite : rien à reprendre")
verifierTailles("mesures")
local clienteMesuree = M.services.Workspace.AtelierLocal:FindFirstChild("Cliente")
verifier(clienteMesuree ~= nil and clienteMesuree.Head.Nom.Texte.Text == "Colette Marchand", "Colette en personne, son nom au-dessus de la tête")
verifier(clienteMesuree.Head.Bulle.Texte.Text == Clientes.get("colette").repliques.presentation, "elle se présente")
do -- Sous-projet 5 : fenêtre ouverte, elle parle dans l'encadré de dialogue, à son nom ; sa bulle est pour la rue
	local dialogue = gui.Atelier:FindFirstChild("Dialogue")
	verifier(dialogue ~= nil and dialogue.Visible and dialogue.Nom.Text == "Colette" and dialogue.Texte.Text == Clientes.get("colette").repliques.presentation and not clienteMesuree.Head.Bulle.Enabled, "fenêtre ouverte : elle se présente dans l'encadré, à son nom, pas dans sa bulle")
	verifier(dialogue.Portrait.Visible and dialogue.Portrait:GetAttribute("Cliente") == "colette" and dialogue.Portrait:GetAttribute("Expression") == "neutre", "(sous-projet 7) son portrait dans l'encadré, neutre")
	cliquer("Fermer")
	verifier(not dialogue.Visible and clienteMesuree.Head.Bulle.Enabled, "fenêtre fermée : sa bulle, pas d'encadré")
	cliquer("OuvrirAtelier")
	verifier(dialogue.Visible and not clienteMesuree.Head.Bulle.Enabled, "fenêtre rouverte : de nouveau l'encadré")
	dialogue.Activated:Fire()
	verifier(not dialogue.Visible, "un appui referme l'encadré")
end
serveur:atelier(joueur).etat.argent += 1 -- (la réponse au refus emporte un état changé : la scène se resynchronise)
cliquer("ValiderMesures")
serveur:atelier(joueur).etat.argent -= 1
verifier(titre() == "Les mesures" and fenetre.Message.Visible and fenetre.Message.Text == "Mesure invalide : tourne chaque molette jusqu'à ce que le mannequin épouse sa silhouette.", "molettes pas réglées : mesures refusées, message")
verifier(not gui.Atelier.Dialogue.Visible, "la même parole, après une réponse du serveur : l'encadré reste refermé")
-- Sous-projet 6 : le mannequin à molettes. La silhouette de la cliente est en pointillé par-dessus le mannequin
local mannequinM = fenetre.Contenu:FindFirstChild("Mannequin")
local function lue(cle)
	return tonumber(texte("Valeur_" .. cle).Text:match("(%d+) cm")) / 10
end
do
	local calque = mannequinM and mannequinM:FindFirstChild("Calque_poitrine")
	local points = 0
	for _, p in ipairs(calque and calque:GetChildren() or {}) do
		points += if p.Name == "Point" then 1 else 0
	end
	verifier(calque ~= nil and calque.BackgroundTransparency == 1 and points >= 12, "la silhouette de la cliente, en pointillé par-dessus le mannequin (" .. points .. " points)")
end
-- Au doigt : glisser vers le haut sur la molette de la poitrine la tourne, un cran tous les 12 px ; un second doigt
-- ne la tourne pas, et le doigt levé ne la tourne plus
local echelleM = mannequinM.AbsoluteSize.X / mannequinM.Size.X.Offset
local doigtMolette = { UserInputType = Enum.UserInputType.Touch, Position = Vector3.new(0, 300, 0) }
fenetre.Contenu.Molette_poitrine.InputBegan:Fire(doigtMolette)
local avantPoitrine = lue("poitrine")
M.services.UserInputService.InputChanged:Fire({ UserInputType = Enum.UserInputType.Touch, Position = Vector3.new(0, 0, 0) })
verifier(lue("poitrine") == avantPoitrine, "un second doigt ne tourne pas la molette")
doigtMolette.Position = Vector3.new(0, 300 - 12 * 5 * echelleM, 0)
M.services.UserInputService.InputChanged:Fire(doigtMolette)
M.services.UserInputService.InputEnded:Fire(doigtMolette)
verifier(math.abs(lue("poitrine") - (avantPoitrine + 0.5)) < 1e-6, "glisser de 60 px vers le haut : cinq crans, +5 cm (" .. lue("poitrine") .. ")")
doigtMolette.Position = Vector3.new(0, 0, 0)
M.services.UserInputService.InputChanged:Fire(doigtMolette)
verifier(math.abs(lue("poitrine") - (avantPoitrine + 0.5)) < 1e-6, "doigt levé : la molette ne tourne plus")
verifier(fenetre.Contenu.Molette_poitrine.Fente.Rotation ~= 0, "la fente de la molette a tourné")
-- La molette est assez grosse pour le doigt ; tournée trop loin, le mannequin s'arrête au bord de son cadre
verifier(fenetre.Contenu.Molette_poitrine.AbsoluteSize.X >= 56 and fenetre.Contenu.Molette_poitrine.AbsoluteSize.Y >= 56, "molette d'au moins 56 px (le doigt)")
doigtMolette.Position = Vector3.new(0, 300, 0)
fenetre.Contenu.Molette_poitrine.InputBegan:Fire(doigtMolette)
doigtMolette.Position = Vector3.new(0, -5000, 0)
M.services.UserInputService.InputChanged:Fire(doigtMolette)
M.services.UserInputService.InputEnded:Fire(doigtMolette)
local corpsP = mannequinM.Corps_poitrine
verifier(corpsP.Position.X.Offset >= 0 and corpsP.Position.X.Offset + corpsP.Size.X.Offset <= mannequinM.Size.X.Offset, "tournée trop loin : le mannequin s'arrête au bord de son cadre")
-- À la souris : la molette de la souris tourne la molette sous le pointeur, et seulement elle
do
	local avantTaille = lue("taille")
	local mt = fenetre.Contenu.Molette_taille
	local dessus = Vector3.new(mt.AbsolutePosition.X + mt.AbsoluteSize.X / 2, mt.AbsolutePosition.Y + mt.AbsoluteSize.Y / 2, 1)
	M.services.UserInputService.InputChanged:Fire({ UserInputType = Enum.UserInputType.MouseWheel, Position = dessus })
	verifier(math.abs(lue("taille") - (avantTaille + 0.1)) < 1e-6, "la molette de la souris sur la molette de la taille : un cran")
	M.services.UserInputService.InputChanged:Fire({ UserInputType = Enum.UserInputType.MouseWheel, Position = Vector3.new(5, 5, 1) })
	verifier(math.abs(lue("taille") - (avantTaille + 0.1)) < 1e-6, "pointeur ailleurs : la molette de la souris ne la tourne pas")
	-- Un second doigt posé sur une autre molette ne prend pas la main au premier
	local premier = { UserInputType = Enum.UserInputType.Touch, Position = Vector3.new(0, 300, 0) }
	local second = { UserInputType = Enum.UserInputType.Touch, Position = Vector3.new(0, 300, 0) }
	local avantHanches = lue("hanches")
	fenetre.Contenu.Molette_taille.InputBegan:Fire(premier)
	fenetre.Contenu.Molette_hanches.InputBegan:Fire(second)
	premier.Position = Vector3.new(0, 300 - 12 * echelleM, 0)
	M.services.UserInputService.InputChanged:Fire(premier)
	M.services.UserInputService.InputEnded:Fire(premier)
	verifier(math.abs(lue("taille") - (avantTaille + 0.2)) < 1e-6 and lue("hanches") == avantHanches, "un second doigt sur une autre molette ne prend pas la main au premier")
end
local function mesurerCliente()
	local vraies = Clientes.get(serveur:atelier(joueur).etat.commande.cliente).mesures
	for _, cle in ipairs(MESURES) do
		local garde = 0
		while math.abs(lue(cle) - vraies[cle]) > 0.05 and garde < 120 do
			garde += 1
			cliquer(if lue(cle) < vraies[cle] then "Plus_" .. cle else "Moins_" .. cle)
		end
	end
end
mesurerCliente()
for _, cle in ipairs(MESURES) do
	local corps, calque = mannequinM["Corps_" .. cle], mannequinM["Calque_" .. cle]
	local gauche = math.abs(corps.Position.X.Offset - calque.Position.X.Offset)
	local droite = math.abs(corps.Position.X.Offset + corps.Size.X.Offset - (calque.Position.X.Offset + calque.Size.X.Offset))
	verifier(gauche <= 2 and droite <= 2, cle .. " : réglé juste, le mannequin épouse la silhouette")
end
-- (sous-projet 6) Colette veut aussi une perle : au carnet, l'exigence dira ce qu'on en a dans la mercerie
table.insert(serveur:atelier(joueur).etat.commande.exigences, { type = "accessoire", id = "perle" })
cliquer("ValiderMesures")
verifier(serveur:atelier(joueur).etat.commande.ajustement == 1 and serveur:atelier(joueur).etat.clientes.colette.mesures ~= nil, "mesures justes : ajustement 100 %, gardées pour la prochaine fois")

---------------------------------------------------------------------------
-- Carnet de croquis
---------------------------------------------------------------------------
verifier(titre() == "1. Carnet de croquis", "mesures prises : le carnet")
do -- Sous-projet 6 : une exigence d'accessoire dit ce qu'on en a dans la mercerie (le kit : dix perles)
	local ligne = texte("Avec : Perle")
	verifier(ligne ~= nil and string.find(ligne.Text, "Avec : Perle\n      (en stock : 10)", 1, true) ~= nil and ligne.Size.Y.Offset == 40, "au carnet, l'exigence d'une perle dit « (en stock : 10) », sur une seconde ligne")
end
-- Sous-projet 5 : le carnet est une page de croquis. Chaque famille se choisit par ◀ ▶ ; le modèle choisi est
-- dessiné, colorié de ses tissus
local function choisirModele(id)
	local v = Catalogue.variante(id)
	for _ = 1, #Catalogue.variantesDe(v.famille) do
		if fenetre.Contenu.Page["Modele_" .. v.famille].Text:sub(1, #v.nom) == v.nom then
			return
		end
		cliquer("Suivant_" .. v.famille)
	end
	verifier(fenetre.Contenu.Page["Modele_" .. v.famille].Text:sub(1, #v.nom) == v.nom, "modèle trouvé par ▶ : " .. id)
end
do
	local page = fenetre.Contenu:FindFirstChild("Page")
	local dessin = page and page:FindFirstChild("Dessin")
	verifier(dessin ~= nil and dessin:IsA("ImageButton") and dessin.ImageContent ~= nil and dessin.ImageContent.statique, "le carnet montre la robe dessinée")
	verifier(page.Modele_corsage.Text == "Droit" and page.Modele_jupe.Text == "Droite" and #page.Points_jupe:GetChildren() >= #Catalogue.variantesDe("jupe"), "le modèle de chaque famille, et un point par modèle")
	local ACCENT = Color3.fromRGB(214, 76, 128)
	local environDroite = page.Environ.Text
	verifier(string.match(environDroite, "^Environ %d+,%d m de tissu$") ~= nil and page.Points_jupe.Point1.BackgroundColor3 == ACCENT and page.Points_jupe.Point2.BackgroundColor3 ~= ACCENT, "environ X m de tissu, et le point du modèle choisi est marqué (" .. environDroite .. ")")
	local dessinAvant = dessin.ImageContent
	cliquer("Suivant_jupe")
	verifier(page.Modele_jupe.Text == "Trapèze" and dessin.ImageContent ~= dessinAvant and page.Points_jupe.Point2.BackgroundColor3 == ACCENT and page.Points_jupe.Point1.BackgroundColor3 ~= ACCENT, "▶ : le modèle suivant, dessiné, son point marqué")
	cliquer("Precedent_jupe")
	verifier(page.Modele_jupe.Text == "Droite", "◀ : retour au modèle précédent")
	-- Au doigt : sur un téléphone, la fenêtre est réduite de moitié ; ◀ ▶ restent assez grands, lignes espacées
	verifier(page.Suivant_jupe.Size.X.Offset >= 44 and page.Suivant_jupe.Size.Y.Offset >= 34 and page.Precedent_jupe.Size.Y.Offset >= 34 and page.Suivant_jupe.Position.Y.Offset - page.Suivant_manches.Position.Y.Offset >= 36, "◀ ▶ assez grands pour le doigt, lignes espacées")
	local hauteurPage = fenetre.Size.Y.Offset * fenetre.Contenu.Size.Y.Scale + fenetre.Contenu.Size.Y.Offset -- (la page prend la hauteur du contenu)
	verifier(page.Valider.Position.Y.Offset + page.Valider.Size.Y.Offset <= hauteurPage and page.Suivant_jupe.Position.Y.Offset + page.Suivant_jupe.Size.Y.Offset <= page.Valider.Position.Y.Offset, "tout tient dans la page, au-dessus de « Tracer le patron »")
	-- Le dessin se fige en attendant Roblox : deux modèles demandés coup sur coup, seul le dernier s'affiche
	local VignettesCarnet = requireModule(scriptClient.Vignettes)
	local peindre, colAvant = VignettesCarnet.croquis, page.Modele_col.Text
	local revenu = false
	VignettesCarnet.croquis = function(c, ...)
		local image = peindre(c, ...)
		if c.jupe == "jupe_trapeze" and not revenu then
			revenu = true -- pendant que le trapèze se fige, le joueur revient déjà à la jupe droite
			page.Precedent_jupe.Activated:Fire()
		end
		return image
	end
	cliquer("Suivant_jupe")
	verifier(page.Modele_jupe.Text == "Droite" and dessin.ImageContent == dessinAvant, "un dessin arrivé en retard ne remplace pas le dernier demandé")
	VignettesCarnet.croquis = peindre
	-- Mémoire des images pleine (Roblox refuse une image de plus) : un mot à la place du dessin (pas l'ancien), le
	-- carnet marche quand même
	local budgetImages = M.budget.images
	M.budget.images = 0
	cliquer("Suivant_col")
	verifier(dessin.SansDessin.Visible and dessin.ImageTransparency == 1 and page.Modele_col.Text ~= colAvant, "mémoire des images pleine : un mot à la place du dessin, les modèles se choisissent quand même")
	M.budget.images = budgetImages
	cliquer("Precedent_col")
	verifier(not dessin.SansDessin.Visible and dessin.ImageTransparency == 0 and page.Modele_col.Text == colAvant, "le dessin revient")
	-- Déblocages : au départ, ce qui est fermé est grisé, avec ce qu'il faut pour l'ouvrir ; son patron ne se trace pas
	choisirModele("jupe_ample")
	verifier(page.Modele_jupe:GetAttribute("Ferme") == true and page.Modele_jupe.TextColor3 == GRIS and string.find(page.Modele_jupe.Text, "Amitié de Colette : 2", 1, true) ~= nil, "jupe ample fermée au départ : grisée, avec ce qu'il faut pour l'ouvrir")
	verifier(page.Environ.Text ~= environDroite, "le métrage suit le modèle : une jupe froncée demande plus de tissu (" .. page.Environ.Text .. ")")
	cliquer("Valider")
	verifier(fenetre.Message.Visible and fenetre.Message.Text == "Pas encore ouvert : Jupe ample froncée (Amitié de Colette : 2)." and titre() == "1. Carnet de croquis", "tracer le patron d'un modèle fermé : ce qu'il faut pour l'ouvrir")
	choisirModele("jupe_droite")
	verifier(page.Modele_jupe:GetAttribute("Ferme") == false, "la jupe droite, ouverte")
end
cliquer("Tissu_corsage_droit_devant")
local carteSoie = boutonNomme("Tissu_soie_rose_fleurs")
verifier(carteSoie:GetAttribute("Ferme") == true and carteSoie.Raison.Text == "Prestige 5" and boutonNomme("Tissu_coton_blanc"):GetAttribute("Ferme") == false, "soie fermée : la carte grisée dit « Prestige 5 » ; le coton est ouvert")
cliquer("Tissu_soie_rose_fleurs")
verifier(fenetre.Contenu:FindFirstChild("ChoixTissu") ~= nil and fenetre.Message.Text == "Pas encore ouvert : Soie rose fleurie (Prestige 5).", "toucher un tissu fermé : ce qu'il faut pour l'ouvrir, le choix reste ouvert")
cliquer("FermerChoix")
do -- Au départ, les jauges du carnet ne promettent que ce que les tissus ouverts peuvent donner
	local Notation = requireModule(dossier.Notation)
	local etatC = requireModule(scriptClient.Session).courante.etat
	local croquisDepart = { corsage = "corsage_droit", manches = "manches_sans", col = "col_sans", jupe = "jupe_droite" }
	local imposes = Notation.accessoiresImposes(etatC.commande.exigences)
	local fTous = Notation.fourchette(croquisDepart, {}, imposes)
	local fOuverts = Notation.fourchette(croquisDepart, {}, imposes, requireModule(dossier.Deblocages).ouverts(etatC).tissus)
	-- (sous-projet 7 : les jauges des étiquettes demandées et des styles de la cliente, pas toujours les six)
	local ecarts, montrees = {}, 0
	for _, jauge in ipairs(fenetre.Contenu.Droite:GetChildren()) do
		local cle = jauge.Name:match("^Jauge_(.+)$")
		if cle then
			montrees += 1
			if math.abs(jauge.Plage.Size.X.Scale - fOuverts[cle].max / 100) > 1e-9 then
				table.insert(ecarts, cle)
			end
		end
	end
	verifier(fOuverts.elegant.max < fTous.elegant.max and montrees >= 2 and #ecarts == 0, "au départ, les jauges s'arrêtent à ce que les tissus ouverts peuvent donner (en défaut : " .. table.concat(ecarts, ", ") .. ")")
end
-- Pour la suite, une couturière confirmée : tout le catalogue ouvert (prestige et amitiés au plus haut)
local etatServeur = serveur:atelier(joueur).etat
etatServeur.prestige = 530
for _, c in ipairs(Clientes.LISTE) do
	etatServeur.clientes[c.id] = etatServeur.clientes[c.id] or { amitie = 0, vues = 0, derniere = 0 }
	etatServeur.clientes[c.id].amitie = 25
end
requireModule(scriptClient.Session).courante:actualiser()
verifier(requireModule(scriptClient.Session).courante.etat.prestige == 530, "la copie du client suit le serveur")
choisirModele("jupe_ample")
verifier(fenetre.Contenu.Page.Modele_jupe:GetAttribute("Ferme") == false and fenetre.Contenu.Page.Modele_jupe.Text == "Ample froncée", "prestige et amitiés au plus haut : la jupe ample s'ouvre dans le carnet")
choisirModele("jupe_droite")
do -- Les 19 modèles se parcourent, et ▶ revient au premier après le dernier
	local vus, nbVus = {}, 0
	for _, famille in ipairs(Catalogue.FAMILLES) do
		for _ = 1, #Catalogue.variantesDe(famille) do
			local nom = fenetre.Contenu.Page["Modele_" .. famille].Text
			if not vus[nom] then
				vus[nom], nbVus = true, nbVus + 1
			end
			cliquer("Suivant_" .. famille)
		end
	end
	verifier(nbVus == #Catalogue.Variantes and fenetre.Contenu.Page.Modele_corsage.Text == "Droit" and fenetre.Contenu.Page.Modele_jupe.Text == "Droite", "les " .. #Catalogue.Variantes .. " modèles se parcourent par ▶, qui revient au premier (" .. nbVus .. ")")
end
verifierTailles("carnet")
verifier(texte("Colette (taille M) veut") ~= nil, "le carnet dit qui commande, et sa taille")
verifier(M.services.Workspace.AtelierLocal:FindFirstChild("Cliente") == clienteMesuree and clienteMesuree.Parent ~= nil, "mesures validées : la même cliente reste là (pas reconstruite)")
verifier(clienteMesuree.Head.Bulle.Texte.Text == requireModule(scriptClient.Scene).PAROLES.carnet, "première visite, au carnet : elle explique ce qu'elle veut (pas « Me revoilà ! »)")
verifier(gui.Atelier.Dialogue.Texte.Text == requireModule(scriptClient.Scene).PAROLES.carnet and not gui.Atelier.Dialogue.Visible, "la nouvelle parole est passée dans l'encadré ; par-dessus la fenêtre centrée, lue, elle s'est effacée")
verifier(texte("Exigence1") ~= nil and texte("Exigence1").Text ~= "", "les exigences sont affichées")
local ligneMetrage = fenetre.Contenu.Droite:FindFirstChild("Metrage")
verifier(ligneMetrage ~= nil and string.find(ligneMetrage.Text, "Choisis les tissus", 1, true) == 1, "sans tissu : le métrage attend les tissus, dans la colonne de droite")
local derniereJauge -- (sous-projet 7 : la plus basse des jauges montrées)
for _, j in ipairs(fenetre.Contenu.Droite:GetChildren()) do
	if j.Name:match("^Jauge_") and (not derniereJauge or j.Position.Y.Offset > derniereJauge.Position.Y.Offset) then
		derniereJauge = j
	end
end
local hauteurDroite = fenetre.Size.Y.Offset + fenetre.Contenu.Size.Y.Offset + fenetre.Contenu.Droite.Size.Y.Offset -- (tailles relatives)
verifier(ligneMetrage.AnchorPoint.Y == 1 and ligneMetrage.Position.Y.Scale == 1 and derniereJauge.Position.Y.Offset + derniereJauge.Size.Y.Offset < hauteurDroite + ligneMetrage.Position.Y.Offset - ligneMetrage.Size.Y.Offset, "la ligne du métrage est en bas de la colonne, sous les jauges, loin des boutons du carnet")
-- Robe : décolleté en V, manches ballon, col Claudine, jupe trapèze
for _, v in ipairs({ "corsage_v", "manches_ballon", "col_claudine", "jupe_trapeze" }) do
	choisirModele(v)
	verifier(fenetre.Contenu.Page["Modele_" .. Catalogue.variante(v).famille].Text == Catalogue.variante(v).nom, v .. " choisi")
end
-- Toucher le dessin : le choix du tissu de la partie touchée (ici la jupe, ses deux pièces)
do
	local d = fenetre.Contenu.Page.Dessin
	local point = Vector2.new(d.AbsolutePosition.X + d.AbsoluteSize.X * 0.5, d.AbsolutePosition.Y + d.AbsoluteSize.Y * 70 / 130)
	M.avancer(0.5)
	d.Activated:Fire({ Position = Vector3.new(point.X, point.Y, 0) }, 1)
	local ouvert = fenetre.Contenu:FindFirstChild("ChoixTissu")
	verifier(ouvert ~= nil and ouvert:GetAttribute("Famille") == "jupe", "toucher la jupe dessinée : le choix de son tissu")
	cliquer("FermerChoix")
	-- Double clic sur un tissu : le second appui tombe sur le dessin, dessous ; il ne rouvre pas le choix
	M.avancer(0.5)
	d.Activated:Fire({ Position = Vector3.new(point.X, point.Y, 0) }, 1)
	M.avancer(0.5)
	fenetre.Contenu.ChoixTissu.Grille.Tissu_coton_blanc.Activated:Fire()
	d.Activated:Fire({ Position = Vector3.new(point.X, point.Y, 0) }, 1)
	verifier(fenetre.Contenu:FindFirstChild("ChoixTissu") == nil and fenetre.Contenu.Page.Pieces.Tissu_jupe_trapeze_devant.Tissu.Text == "Coton blanc", "double clic sur un tissu : choisi, et le second appui ne rouvre pas le choix")
end
do -- Sous-projet 7 : une jupe à volant et un corsage à basque ; leurs couches ont leurs pièces, leur tissu, leur partie du dessin
	choisirModele("jupe_volant")
	choisirModele("corsage_basque")
	local page = fenetre.Contenu.Page
	local liste = page.Pieces
	local lignes = 0
	for _, e in ipairs(liste:GetChildren()) do
		lignes += if e.Name:sub(1, 6) == "Tissu_" then 1 else 0
	end
	verifier(liste:IsA("ScrollingFrame") and lignes == 10 and liste.CanvasSize.Y.Offset >= 10 * 36 and liste.Position.Y.Offset + liste.Size.Y.Offset <= page.Precedent_corsage.Position.Y.Offset, ("dix pièces : la liste défile, au-dessus des lignes des modèles (%d)"):format(lignes))
	local tout = page:FindFirstChild("ToutEnUnTissu")
	verifier(tout ~= nil and tout.Position.Y.Offset >= liste.Position.Y.Offset + liste.Size.Y.Offset and tout.Position.Y.Offset + tout.Size.Y.Offset <= page.Precedent_corsage.Position.Y.Offset, "« Même tissu pour toute la robe » reste en vue, sous la liste qui défile")
	local d = page.Dessin
	local function toucher(x, y)
		M.avancer(0.5)
		d.Activated:Fire({ Position = Vector3.new(d.AbsolutePosition.X + d.AbsoluteSize.X * x / 100, d.AbsolutePosition.Y + d.AbsoluteSize.Y * y / 130, 0) }, 1)
	end
	local imageAvant = d.ImageContent
	toucher(52, 81)
	local ouvert = fenetre.Contenu:FindFirstChild("ChoixTissu")
	verifier(ouvert ~= nil and ouvert:GetAttribute("Pieces") == "volant_devant,volant_dos", "toucher le volant dessiné : le choix du tissu de ses deux pièces")
	M.avancer(0.5)
	fenetre.Contenu.ChoixTissu.Grille.Tissu_velours_noir.Activated:Fire()
	verifier(liste.Tissu_volant_devant.Tissu.Text == "Velours noir" and liste.Tissu_volant_dos.Tissu.Text == "Velours noir" and liste.Tissu_jupe_droite_devant.Tissu.Text ~= "Velours noir", "le volant prend le velours noir, la jupe garde son tissu")
	verifier(d.ImageContent ~= nil and d.ImageContent ~= imageAvant, "le dessin se colorie du tissu du volant")
	toucher(50, 47)
	verifier(fenetre.Contenu.ChoixTissu:GetAttribute("Pieces") == "basque_devant,basque_dos", "toucher la basque dessinée : ses deux pièces")
	cliquer("FermerChoix")
	choisirModele("corsage_v")
	choisirModele("jupe_trapeze")
end
local pieces = fenetre.Contenu.Page.Pieces
local nbBoutonsTissu = 0
for _, d in ipairs(pieces:GetChildren()) do
	if d.Name:sub(1, 6) == "Tissu_" then
		nbBoutonsTissu += 1
	end
end
verifier(nbBoutonsTissu == 6, "6 pièces à habiller de tissu (obtenu " .. nbBoutonsTissu .. ")")
M.avancer(8)
verifier(not fenetre.Message.Visible, "l'avertissement de la sauvegarde s'est effacé")
pendantAttente = nil
remoteAtelier.OnServerInvoke = serveurLent
cliquer("Valider")
remoteAtelier.OnServerInvoke = brancheServeur
verifier(pendantAttente ~= nil and pendantAttente.visible and pendantAttente.texte == "Un instant…" and pendantAttente.couleur == GRIS, "serveur lent : « Un instant… » en gris pendant l'attente")
verifier(titre() == "1. Carnet de croquis" and fenetre.Message.Visible and fenetre.Message.Text ~= "Un instant…" and fenetre.Message.TextColor3 ~= GRIS, "valider sans tissu : message d'erreur (en rouge), à la place de l'indicateur")
verifier(M.sonsJoues[#M.sonsJoues] == "Atelier_refus", "un refus fait son petit bruit")

-- Choix d'un tissu : filtre « Romantique », soie rose fleurie pour le corsage, puis pour toute la robe
local jaugeAvant = fenetre.Contenu.Droite.Jauge_romantique.Acquis.Size
cliquer("Tissu_corsage_v_devant")
local choix = fenetre.Contenu:FindFirstChild("ChoixTissu")
verifier(choix ~= nil, "le choix du tissu s'ouvre")
-- Dans Roblox, un simple cadre (même Active) laisse passer l'appui aux boutons cachés dessous (Valider,
-- variantes…) ; un bouton sans texte l'arrête (vérifié dans Studio)
verifier(choix:IsA("TextButton") and choix.Text == "" and not choix.AutoButtonColor, "le choix du tissu arrête les appuis : rien ne passe aux boutons cachés dessous")
verifierTailles("choix du tissu")
cliquer("Filtre_gothique")
local grille = fenetre.Contenu.ChoixTissu.Grille
verifier(grille:FindFirstChild("Tissu_velours_noir") ~= nil and grille:FindFirstChild("Tissu_coton_blanc") == nil, "filtre gothique : velours noir, pas de coton blanc")
cliquer("Filtre_romantique")
cliquer("Tissu_soie_rose_fleurs")
verifier(fenetre.Contenu:FindFirstChild("ChoixTissu") == nil, "le choix du tissu se ferme")
verifier(texte("Soie rose fleurie") ~= nil, "le corsage devant est en soie rose fleurie")
local pastille
for _, d in ipairs(pieces:GetDescendants()) do
	pastille = pastille or (d.Name == "Pastille" and d or nil)
end
verifier(pastille:IsA("ImageLabel") and pastille.ImageContent.statique == true, "la pastille de la pièce montre le motif du tissu")
cliquer("ToutEnUnTissu")
local nbSoie = 0
for _, d in ipairs(pieces:GetDescendants()) do
	if d:IsA("TextLabel") and d.Text == "Soie rose fleurie" then
		nbSoie += 1
	end
end
verifier(nbSoie == 6, "toute la robe en soie rose fleurie")
verifier(fenetre.Contenu.Page.Echantillons:FindFirstChild("Echantillon_1") ~= nil and fenetre.Contenu.Page.Echantillons:FindFirstChild("Echantillon_2") == nil, "l'échantillon de la soie est épinglé à la page (un par tissu)")
local jaugeApres = fenetre.Contenu.Droite.Jauge_romantique.Acquis.Size
verifier(jaugeApres.X.Scale > jaugeAvant.X.Scale, "la jauge Romantique monte avec la soie")
-- Métrage et coût en direct : le conseil pour toute la robe (en soie), au prix de la soie
local Metrage = requireModule(dossier.Metrage)
local piecesRobe = requireModule(dossier.Patron).piecesDuCroquis({ corsage = "corsage_v", manches = "manches_ballon", col = "col_claudine", jupe = "jupe_trapeze" })
local dmRobe = Metrage.conseil(piecesRobe)
local prixRobe = EtatAtelier.prix("soie_rose_fleurs", dmRobe)
verifier(ligneMetrage.Text == ("Tissu à acheter : %d dm, %d po (tu as %d po)."):format(dmRobe, prixRobe, argent()), "métrage et coût en direct : " .. ligneMetrage.Text)
-- Pas assez d'argent (copie du client appauvrie le temps du test) : la ligne dit ce qui manque, en rouge
local etatCarnet = requireModule(scriptClient.Session).courante.etat
local argentVrai = etatCarnet.argent
etatCarnet.argent = prixRobe - 10
cliquer("Suivant_jupe") -- aller et retour : même croquis, le carnet se redessine
cliquer("Precedent_jupe")
verifier(ligneMetrage.Text == ("Tissu à acheter : %d dm, %d po — il te manque 10 po."):format(dmRobe, prixRobe) and ligneMetrage.TextColor3 == requireModule(scriptClient.UiKit).COULEURS.erreur, "pas assez d'argent : ce qui manque, en rouge")
etatCarnet.argent = argentVrai
cliquer("Suivant_jupe")
cliquer("Precedent_jupe")
-- L'état change sans action du carnet (réparé par le serveur) : la ligne suit
serveur:atelier(joueur).etat.argent = argentVrai + 1000
M.avancer(0.5)
requireModule(scriptClient.Session).courante:actualiser()
verifier(string.find(ligneMetrage.Text, ("(tu as %d po)"):format(argentVrai + 1000), 1, true) ~= nil, "l'argent change sans action du carnet : la ligne suit")
serveur:atelier(joueur).etat.argent = argentVrai
M.avancer(0.5)
requireModule(scriptClient.Session).courante:actualiser()
cliquer("Valider")

---------------------------------------------------------------------------
-- Achat
---------------------------------------------------------------------------
verifier(titre() == "2. Achat du tissu", "le croquis validé mène à l'achat")
verifierTailles("achat")
boutonNomme("RetourCarnet").Activated:Fire() -- second clic d'un double clic, sur le bouton qui vient d'apparaître
verifier(titre() == "2. Achat du tissu", "un double clic ne déclenche pas le bouton de l'écran suivant")
local ligne = fenetre.Contenu.Lignes:FindFirstChild("Ligne_soie_rose_fleurs")
verifier(ligne ~= nil and #fenetre.Contenu:GetChildren() >= 3, "une ligne par tissu du croquis")
local quantite = tonumber(ligne.Quantite.Text:match("^(%d+)"))
verifier(quantite and quantite > 0, "quantité conseillée pré-remplie")
local aideAchat = texte("métrage conseillé")
verifier(aideAchat ~= nil and #aideAchat.Text <= 110, "l'aide de l'achat tient sur une ligne (" .. (aideAchat and #aideAchat.Text or 0) .. " caractères)")
-- Aperçu du rouleau (toucher l'échantillon) : les pièces de ce tissu rangées comme le conseil les compte.
-- La mémoire des images est pleine jusqu'à la découpe (silhouettes impossibles) : les pièces sont en papier uni.
M.budget.images = 0
cliquer("Apercu_soie_rose_fleurs")
local apercuRouleau = fenetre.Contenu:FindFirstChild("ApercuRouleau")
verifier(apercuRouleau ~= nil and apercuRouleau:IsA("TextButton") and apercuRouleau.Text == "" and not apercuRouleau.AutoButtonColor, "l'aperçu du rouleau s'ouvre et arrête les appuis")
local copiesRobe, copiesVues = 0, 0
for _, id in ipairs(piecesRobe) do
	copiesRobe += if Catalogue.piece(id).pliee then 2 else 1
end
for _, d in ipairs(apercuRouleau.Vue.Rouleau:GetChildren()) do
	if string.sub(d.Name, 1, 6) == "Piece_" then
		copiesVues += 1
	end
end
local tailleRouleau = apercuRouleau.Vue.Rouleau.Size
verifier(tailleRouleau.X.Offset == 14 * 20 and tailleRouleau.Y.Offset == dmRobe * 20 and copiesVues == copiesRobe, "le rouleau conseillé (" .. dmRobe .. " dm), avec ses " .. copiesRobe .. " pièces rangées")
verifier(apercuRouleau.Titre.Text == ("Soie rose fleurie : %d dm conseillés"):format(dmRobe), "le titre donne le métrage conseillé")
verifier(apercuRouleau.Vue.Rouleau["Piece_" .. piecesRobe[1]].BackgroundTransparency < 1, "sans silhouette, les pièces restent visibles (papier uni)")
verifier(apercuRouleau.FermerRouleau.Position.Y.Offset + apercuRouleau.FermerRouleau.Size.Y.Offset <= fenetre.Contenu.Lignes.Position.Y.Offset, "« Fermer » au-dessus de la liste : un double appui ne touche aucun bouton")
verifierTailles("aperçu du rouleau")
cliquer("FermerRouleau")
verifier(fenetre.Contenu:FindFirstChild("ApercuRouleau") == nil, "l'aperçu du rouleau se referme")
cliquer("Plus")
verifier(tonumber(ligne.Quantite.Text:match("^(%d+)")) == quantite + 1, "le bouton + ajoute 1 dm")
cliquer("Moins")
cliquer("AllerDecoupe")
verifier(titre() == "2. Achat du tissu" and fenetre.Message.Visible, "découpe refusée sans tissu")
local avant = argent()
cliquer("Acheter")
verifier(argent() < avant, "l'achat débite l'argent")
verifier(M.sonsJoues[#M.sonsJoues] == "Atelier_achat", "l'achat fait sonner la caisse")
verifier(texte("En stock : " .. quantite .. " dm") ~= nil, "le stock est mis à jour")
-- L'état change sans achat (réparé par le serveur, par exemple) : les lignes suivent
local stockServeur = serveur:atelier(joueur).etat.stock
stockServeur.soie_rose_fleurs = quantite + 7
M.avancer(0.5)
requireModule(scriptClient.Session).courante:actualiser()
verifier(texte("En stock : " .. (quantite + 7) .. " dm") ~= nil, "l'état change sans achat : la ligne suit")
stockServeur.soie_rose_fleurs = 2
M.avancer(0.5)
requireModule(scriptClient.Session).courante:actualiser()
verifier(ligne.Quantite.Text == (quantite - 2) .. " dm", "le stock baisse sans achat : la quantité proposée remonte d'autant")
stockServeur.soie_rose_fleurs = quantite
M.avancer(0.5)
requireModule(scriptClient.Session).courante:actualiser()
cliquer("AllerDecoupe")

---------------------------------------------------------------------------
-- Table de découpe
---------------------------------------------------------------------------
verifier(titre() == "3. Table de découpe", "l'achat mène à la découpe")
verifierTailles("découpe")
verifier(fenetre.Contenu.Rouleau.Tissu.PieceCourante.BackgroundTransparency < 1, "sans silhouette, la pièce reste visible (papier uni)")
M.budget.images = 64
local panneau = fenetre.Contenu.Panneau
verifier(panneau.DroitFil.Text == "Droit-fil : 100 %", "pièce proposée au droit-fil")
cliquer("Tourner15")
verifier(panneau.DroitFil.Text ~= "Droit-fil : 100 %", "tourner de 15° dégrade le droit-fil")
verifier(panneau.Statut.Text == "La pièce dépasse du tissu.", "tournée contre le bord, la pièce dépasse du rouleau")
local function luminance(c)
	return 0.299 * c.R + 0.587 * c.G + 0.114 * c.B
end
verifier(math.abs(luminance(panneau.Couper.TextColor3) - luminance(panneau.Couper.BackgroundColor3)) > 0.35, "« Couper » reste lisible quand la coupe est impossible")
cliquer("Tourner-15")
verifier(panneau.DroitFil.Text == "Droit-fil : 100 %", "retour au droit-fil")
verifier(math.abs(luminance(panneau.Couper.TextColor3) - luminance(panneau.Couper.BackgroundColor3)) > 0.35, "« Couper » lisible quand la coupe est possible")
verifier(fenetre.Contenu.Rouleau.Tissu.PieceCourante.Visible, "la pièce courante est affichée sur le rouleau")
-- Glisser au doigt : le rouleau ne défile pas en même temps, un second doigt ne déplace rien
local UIS = M.services.UserInputService
local rouleau = fenetre.Contenu.Rouleau
local pieceC = rouleau.Tissu.PieceCourante
local doigt = { UserInputType = Enum.UserInputType.Touch, Position = Vector3.new(60, 60, 0) }
pieceC.InputBegan:Fire(doigt)
verifier(rouleau.ScrollingEnabled == false, "pendant qu'on glisse une pièce au doigt, le rouleau ne défile pas")
local positionAvant = pieceC.Position
UIS.InputChanged:Fire({ UserInputType = Enum.UserInputType.Touch, Position = Vector3.new(300, 300, 0) })
verifier(pieceC.Position == positionAvant, "un second doigt ne déplace pas la pièce")
doigt.Position = Vector3.new(70, 60, 0)
UIS.InputChanged:Fire(doigt)
verifier(pieceC.Position ~= positionAvant, "le doigt qui tient la pièce la déplace")
UIS.InputEnded:Fire({ UserInputType = Enum.UserInputType.Touch, Position = Vector3.new(300, 300, 0) })
verifier(rouleau.ScrollingEnabled == false, "le second doigt levé ne lâche pas la pièce")
UIS.InputEnded:Fire(doigt)
verifier(rouleau.ScrollingEnabled == true, "pièce lâchée : le rouleau défile de nouveau")
-- Molette sur la pièce : elle tourne de 15° ; le rouleau ne défile pas tant que la souris est dessus
local angleAvant = pieceC.Rotation
pieceC.MouseEnter:Fire()
verifier(rouleau.ScrollingEnabled == false, "souris sur la pièce : la molette ne fait pas défiler le rouleau")
pieceC.InputChanged:Fire({ UserInputType = Enum.UserInputType.MouseWheel, Position = Vector3.new(0, 0, 1) })
verifier(pieceC.Rotation == angleAvant + 15, "molette vers le haut : la pièce tourne de 15°")
pieceC.InputChanged:Fire({ UserInputType = Enum.UserInputType.MouseWheel, Position = Vector3.new(0, 0, -1) })
verifier(pieceC.Rotation == angleAvant, "molette vers le bas : elle revient")
pieceC.MouseLeave:Fire()
verifier(rouleau.ScrollingEnabled == true, "souris hors de la pièce : le rouleau défile de nouveau")
-- Au doigt, « MouseEnter » arrive au toucher, mais « MouseLeave » souvent bien plus tard : la pièce lâchée,
-- le rouleau défile de nouveau au doigt sans l'attendre
pieceC.MouseEnter:Fire()
local doigtPiece = { UserInputType = Enum.UserInputType.Touch, Position = Vector3.new(60, 60, 0) }
pieceC.InputBegan:Fire(doigtPiece)
UIS.InputEnded:Fire(doigtPiece)
verifier(rouleau.ScrollingEnabled == true, "au doigt, pièce lâchée : le rouleau défile de nouveau, sans attendre MouseLeave")
-- A et D : le rouleau se déroule de 2 dm ou revient ; les touches ne font pas marcher l'avatar
local deroule = M.actions.AtelierDerouler
verifier(deroule ~= nil and table.find(deroule.touches, Enum.KeyCode.A) ~= nil and table.find(deroule.touches, Enum.KeyCode.D) ~= nil, "A et D servent à dérouler tant que la table est affichée")
local defileAvant = rouleau.CanvasPosition.Y
verifier(deroule.f("AtelierDerouler", Enum.UserInputState.Begin, { KeyCode = Enum.KeyCode.D }) == Enum.ContextActionResult.Sink, "D ne fait pas marcher l'avatar")
verifier(rouleau.CanvasPosition.Y == defileAvant + 2 * 36, "D : le rouleau se déroule de 2 dm")
deroule.f("AtelierDerouler", Enum.UserInputState.Begin, { KeyCode = Enum.KeyCode.A })
verifier(rouleau.CanvasPosition.Y == defileAvant, "A : il revient")
-- Fenêtre fermée : A, D et R sont rendus au jeu
cliquer("Fermer")
verifier(M.actions.AtelierDerouler == nil, "fenêtre fermée : A et D rendus à l'avatar")
local rotationFermee = pieceC.Rotation
UIS.InputBegan:Fire({ KeyCode = Enum.KeyCode.R, UserInputType = Enum.UserInputType.Keyboard }, false)
verifier(pieceC.Rotation == rotationFermee, "fenêtre fermée : R ne tourne plus la pièce")
cliquer("OuvrirAtelier")
verifier(M.actions.AtelierDerouler ~= nil, "fenêtre rouverte : A et D déroulent de nouveau")
-- Tissu entamé : rien de coupé, le rouleau est intact
verifier(string.find(panneau.InfoRouleau.Text, "0,00 m entamés / ", 1, true) == 1 and string.find(panneau.InfoRouleau.Text, "\nCette robe : +0,00 m (0 po)", 1, true) ~= nil and not rouleau.Tissu.Entame.Visible, "rien de coupé : rouleau intact (" .. panneau.InfoRouleau.Text .. ")")
verifier(not fenetre.Contenu.Panneau.JeterEntame.Visible, "rouleau neuf : pas de « Jeter la bande »")
cliquer("Proposer")
-- « Plus de tissu » cliqué deux fois très vite : un seul achat
local avantPlus = argent()
cliquer("PlusDeTissu")
boutonNomme("PlusDeTissu").Activated:Fire()
verifier(argent() == avantPlus - EtatAtelier.prix("soie_rose_fleurs", 5), "double clic sur « Plus de tissu » : un seul achat de 5 dm")
cliquer("Proposer")
local coupes, essais = 0, 0
while titre() == "3. Table de découpe" and essais < 20 do
	essais += 1
	if panneau.Statut.Text ~= "Place libre : tu peux couper." then
		cliquer("PlusDeTissu") -- plus assez de rouleau : on en rachète, puis on redemande une place
		cliquer("Proposer")
	else
		local restantes = #panneau.ListePieces:GetChildren()
		cliquer("Couper")
		if titre() == "3. Table de découpe" then
			boutonNomme("Couper").Activated:Fire() -- double clic : la pièce suivante ne doit pas partir sans être placée
		end
		if titre() ~= "3. Table de découpe" or #panneau.ListePieces:GetChildren() < restantes then
			coupes += 1
			if coupes == 1 and titre() == "3. Table de découpe" then
				-- Couper consomme le rouleau jusqu'au bas de la pièce la plus basse : le tissu entamé s'affiche
				local c = requireModule(scriptClient.Session).courante.etat.coupons.soie_rose_fleurs
				local metres = requireModule(scriptClient.Mercerie).metres
				verifier(c:longueurUtilisee() > 0 and c:ajout() == c:longueurUtilisee() and panneau.InfoRouleau.Text == ("%s m entamés / %s m\nCette robe : +%s m (%d po)"):format(metres(c:longueurUtilisee() * 10), metres(c.longueur * 10), metres(c:ajout() * 10), EtatAtelier.prix("soie_rose_fleurs", c:ajout())), "une pièce coupée : le compteur du rouleau, et ce que cette robe y ajoute (" .. panneau.InfoRouleau.Text .. ")")
				verifier(rouleau.Tissu.Entame.Visible and rouleau.Tissu.Entame.Position.Y.Offset == c:longueurUtilisee() * 36, "une ligne marque le tissu entamé sur le rouleau")
			end
		end
		if titre() == "3. Table de découpe" then
			verifier(#fenetre.Contenu.Rouleau.Tissu.Coupees:GetChildren() >= 1, "les pièces coupées restent visibles")
			verifier(panneau.Statut.Text ~= "Cette pièce est déjà coupée.", "après une coupe, la pièce suivante est affichée")
		end
	end
end
verifier(coupes == 6, "6 pièces coupées (manche et col pliés comptent pour une coupe chacun) : " .. coupes)

---------------------------------------------------------------------------
-- Épinglage
---------------------------------------------------------------------------
local Workspace = M.services.Workspace
local camera = Workspace.CurrentCamera
verifier(titre() == "4. Épinglage", "après la dernière coupe : l'épinglage")
verifier(sonALaPlace(), "fenêtre en panneau : « Son » reste dans la barre, sans rien chevaucher")
verifier(fenetre.AnchorPoint.X == 1, "la fenêtre se range à droite : le mannequin est visible")
verifier(M.coreGui[Enum.CoreGuiType.PlayerList] == false, "la liste des joueurs de Roblox ne cache pas le haut du panneau")
local scene = Workspace:FindFirstChild("AtelierLocal")
verifier(scene ~= nil and scene:FindFirstChild("Mannequin") ~= nil, "le mannequin de la cliente est dans l'atelier")
verifier(camera.CameraType == Enum.CameraType.Scriptable, "caméra fixe sur le mannequin")
verifierTailles("épinglage")
cliquer("Fermer")
verifier(camera.CameraType == Enum.CameraType.Custom, "fenêtre fermée : la caméra revient au joueur")
cliquer("OuvrirAtelier")
verifier(camera.CameraType == Enum.CameraType.Scriptable, "fenêtre rouverte : caméra fixe sur le mannequin")
local robe = scene.Robe
local liste = fenetre.Contenu.Liste
local aEpingler = {}
for _, d in ipairs(liste:GetChildren()) do
	if d.Name:sub(1, 9) == "Epingler_" then
		table.insert(aEpingler, d.Name)
	end
end
table.sort(aEpingler)
verifier(#aEpingler == 6, "6 pièces à épingler (obtenu " .. #aEpingler .. ")")
-- Les six cartes tiennent dans la liste sans défiler (une carte coupée par le bas cacherait « Recommencer »)
local hauteurListe = fenetre.Size.Y.Offset + fenetre.Contenu.Size.Y.Offset + liste.Size.Y.Offset
for _, nom in ipairs(aEpingler) do
	local carte = liste[nom]
	verifier(carte.Position.Y.Offset + carte.Size.Y.Offset <= hauteurListe, nom .. " : carte entièrement visible")
end
-- « Recommencer la robe » demande une confirmation : un seul appui n'efface rien
cliquer("Recommencer")
verifier(titre() == "4. Épinglage" and boutonNomme("Recommencer").Text == "Vraiment ? Touche encore", "recommencer : confirmation demandée")
M.avancer(4)
verifier(boutonNomme("Recommencer").Text == "Recommencer la robe", "sans confirmation, le bouton revient à la normale")
verifier(liste[aEpingler[1]].Apercu.ImageContent.statique == true, "aperçu de la pièce découpée dans le vrai tissu")
cliquer(aEpingler[1])
verifier(#robe:GetChildren() >= 1, "la pièce épinglée apparaît sur le mannequin")
verifier(liste[aEpingler[1]].Etat.Text == "Épinglée", "la pièce est marquée épinglée")
for i = 2, #aEpingler do
	cliquer(aEpingler[i])
end
verifier(#robe:GetChildren() == 8, "robe entière sur le mannequin, manches et col en double (obtenu " .. #robe:GetChildren() .. ")")

---------------------------------------------------------------------------
-- Couture
---------------------------------------------------------------------------
verifier(titre() == "5. Couture", "tout est épinglé : la couture")
verifier(fenetre.AnchorPoint.X == 0.5, "la fenêtre revient au centre pour la machine à coudre")
verifierTailles("couture")
-- Maintient « Coudre » pendant « duree » secondes, en glissant de « glisse » pixels
local function coudre(duree, glisse)
	local appui = { UserInputType = Enum.UserInputType.MouseButton1, Position = Vector3.new(700, 400, 0) }
	boutonNomme("Coudre").InputBegan:Fire(appui)
	if glisse then
		UIS.InputChanged:Fire({ UserInputType = Enum.UserInputType.MouseMovement, Position = Vector3.new(700 + glisse, 400, 0) })
	end
	M.avancer(duree)
	UIS.InputEnded:Fire(appui)
end
local panneauC = fenetre.Contenu.Panneau
local points = fenetre.Contenu.Plateau.Tissu.Points
local function cousues()
	local n = 0
	for _, d in ipairs(panneauC.Pieces:GetChildren()) do
		if d:IsA("TextLabel") and d.Text:find("%d+ %%$") then
			n += 1
		end
	end
	return n
end
verifier(panneauC.Note.Text == "Couture : —", "rien de cousu au départ")
verifier(#panneauC.Pieces:GetChildren() == 6, "6 pièces à coudre")
coudre(2)
verifier(panneauC.Note.Text:match("^Couture : %d+ %%$") ~= nil, "la note s'affiche en cousant : " .. panneauC.Note.Text)
verifier(#points:GetChildren() > 0, "les points de couture apparaissent sur le tissu")
cliquer("Decoudre")
verifier(panneauC.Note.Text == "Couture : —" and #points:GetChildren() == 0, "découdre défait la couture")
verifier(M.sonsJoues[#M.sonsJoues] == "Atelier_decoudre", "découdre : le tissu se défait (son)")
-- La machine tourne (son en boucle) tant qu'on tient « Coudre », et s'arrête au lâcher
local appuiSon = { UserInputType = Enum.UserInputType.MouseButton1, Position = Vector3.new(700, 400, 0) }
boutonNomme("Coudre").InputBegan:Fire(appuiSon)
M.avancer(0.5)
verifier(SoundService.Atelier_couture.IsPlaying and SoundService.Atelier_couture.Looped, "on tient « Coudre » : la machine tourne")
UIS.InputEnded:Fire(appuiSon)
M.avancer(0.1)
verifier(not SoundService.Atelier_couture.IsPlaying, "on lâche : la machine s'arrête")
cliquer("Decoudre")
-- Fenêtre fermée pendant qu'on tient « Coudre » : plus rien n'est cousu, Espace rendu au jeu (saut)
verifier(M.actions.AtelierCoudre ~= nil, "Espace sert à coudre tant que la machine est affichée")
boutonNomme("Coudre").InputBegan:Fire({ UserInputType = Enum.UserInputType.MouseButton1, Position = Vector3.new(700, 400, 0) })
fenetre.Fermer.Activated:Fire()
verifier(not fenetre.Visible and M.actions.AtelierCoudre == nil, "fenêtre fermée : Espace n'est plus pris par la couture")
M.avancer(3)
cliquer("OuvrirAtelier")
M.avancer(1)
verifier(panneauC.Note.Text == "Couture : —", "fenêtre fermée : rien n'a été cousu, et l'appui en cours est oublié")
-- Espace (fenêtre ouverte) : coud, sans faire sauter l'avatar
local espace = { KeyCode = Enum.KeyCode.Space, UserInputType = Enum.UserInputType.Keyboard, Position = Vector3.new(0, 0, 0) }
verifier(M.actions.AtelierCoudre.f("AtelierCoudre", Enum.UserInputState.Begin, espace) == Enum.ContextActionResult.Sink, "Espace ne fait pas sauter l'avatar pendant la couture")
M.avancer(2)
M.actions.AtelierCoudre.f("AtelierCoudre", Enum.UserInputState.End, espace)
verifier(panneauC.Note.Text:match("^Couture : %d+ %%$") ~= nil, "Espace coud : " .. panneauC.Note.Text)
cliquer("Decoudre")
-- Pièce finie : rien n'est rendu tant qu'on n'a pas dit « Pièce suivante » ; on peut encore découdre
coudre(60, 400) -- en tirant tout le temps du même côté : couture ratée
verifier(cousues() == 0 and panneauC.Note.Text:match("^Pièce finie : %d+ %%$") ~= nil, "pièce finie mais pas rendue : " .. panneauC.Note.Text)
verifier(boutonNomme("PieceSuivante").Text == "Pièce suivante", "bouton « Pièce suivante » affiché")
cliquer("Decoudre")
verifier(panneauC.Note.Text:match("^Couture : ") ~= nil and not panneauC.PieceSuivante.Visible, "la dernière couture ratée se défait encore")
coudre(60, 400)
-- Serveur injoignable au moment de rendre la pièce : elle reste finie (rien à recoudre), message en gris
remoteAtelier.OnServerInvoke = function()
	error("coupure simulée")
end
cliquer("PieceSuivante")
remoteAtelier.OnServerInvoke = brancheServeur
verifier(cousues() == 0 and panneauC.PieceSuivante.Visible and panneauC.Note.Text:match("^Pièce finie") ~= nil, "serveur injoignable : la pièce reste finie, à rendre de nouveau")
local SessionClient = requireModule(scriptClient.Session)
verifier(fenetre.Message.Visible and fenetre.Message.Text == SessionClient.INJOIGNABLE and fenetre.Message.TextColor3 == GRIS, "refus passager : message en gris")
cliquer("PieceSuivante")
verifier(cousues() == 0 and fenetre.Message.Text == SessionClient.VERIFICATION, "tant que l'atelier vérifie où en est le serveur, la pièce attend")
M.avancer(SessionClient.RESYNCHRO)
cliquer("PieceSuivante")
verifier(cousues() == 1, "première pièce cousue")
local ratee = tonumber(panneauC.Pieces.Ligne1.Text:match("(%d+) %%$"))
cliquer("Vitesse_lapin")
verifier(boutonNomme("Vitesse_lapin").BackgroundColor3 == Color3.fromRGB(214, 76, 128), "vitesse lapin choisie")
-- Deuxième pièce au doigt : un second doigt qui glisse ne dirige pas l'aiguille
local doigtCoudre = { UserInputType = Enum.UserInputType.Touch, Position = Vector3.new(700, 400, 0) }
boutonNomme("Coudre").InputBegan:Fire(doigtCoudre)
UIS.InputChanged:Fire({ UserInputType = Enum.UserInputType.Touch, Position = Vector3.new(1100, 400, 0) })
M.avancer(30)
UIS.InputEnded:Fire(doigtCoudre)
cliquer("PieceSuivante")
verifier(cousues() == 2, "deuxième pièce cousue au doigt")
local auDoigt = tonumber(panneauC.Pieces.Ligne2.Text:match("(%d+) %%$"))
verifier(auDoigt ~= nil and auDoigt > 30, "un second doigt ne dirige pas l'aiguille : " .. tostring(auDoigt))
cliquer("Assistance")
verifier(panneauC.Assistance.Text == "Assistance : oui (85 % au plus)", "assistance activée")
-- L'amitié d'Inès remise à 0 le temps de voir une décoration fermée (serveur et copie du client)
serveur:atelier(joueur).etat.clientes.ines.amitie = 0
requireModule(scriptClient.Session).courante.etat.clientes.ines.amitie = 0
for k = 3, 6 do
	coudre(30)
	verifier(boutonNomme("PieceSuivante").Text == (k == 6 and "Finir la couture" or "Pièce suivante"), "bouton de fin de pièce " .. k)
	cliquer("PieceSuivante")
	verifier(k == 6 or gui.Atelier:FindFirstChild("Confettis") == nil, "pièce " .. k .. " cousue, la robe pas finie : pas encore de confettis")
end

---------------------------------------------------------------------------
-- Décorations
---------------------------------------------------------------------------
verifier(ratee ~= nil and ratee < 20, "la couture ratée est mal notée : " .. tostring(ratee))
verifier(titre() == "6. Décorations", "robe cousue : les décorations")
verifier(fenetre.AnchorPoint.X == 1 and #robe:GetChildren() == 8, "panneau à droite, la robe cousue sur le mannequin")
do -- Sous-projet 5 : la robe terminée, une pluie de confettis par-dessus la fenêtre et un petit son de fête
	local confettis = gui.Atelier:FindFirstChild("Confettis")
	verifier(confettis ~= nil and #confettis:GetChildren() >= 40 and confettis.ZIndex > gui.Atelier.Dialogue.ZIndex and table.find(M.sonsJoues, "Atelier_fete") ~= nil, "robe terminée : des confettis, un son de fête")
	local premier = confettis:GetChildren()[1]
	local hauteurAvant = premier.Position.Y.Scale
	M.avancer(0.5)
	verifier(premier.Position.Y.Scale > hauteurAvant + 0.1, "les confettis tombent")
	M.avancer(3)
	verifier(gui.Atelier:FindFirstChild("Confettis") == nil, "puis ils disparaissent")
end
verifierTailles("décorations")
local SessionModule = requireModule(scriptClient.Session)
local ScenePoste = requireModule(scriptClient.Scene)
local PatronModule = requireModule(dossier.Patron)
local PolygoneModule = requireModule(dossier.Polygone)
local etatJeu = SessionModule.courante.etat
local contenuD = fenetre.Contenu
local decorations = scene.Decorations
local ACCENT = Color3.fromRGB(214, 76, 128)
-- La cliente veut une croix d'argent : sans elle, la robe sera refusée (posé sur le serveur, qui juge
-- la robe, et sur la copie du client, qui affiche la commande). (Relecture du plan 22 : et une robe pour la journée, 30
-- au moins ; la robe en soie rose fleurie en a 32)
local function exigencesTest()
	return { { type = "accessoire", id = "croix_argent" }, { type = "min", style = "romantique", valeur = 1 }, { type = "occasion", occasion = "journee", valeur = 30 } }
end
serveur:atelier(joueur).etat.commande.exigences = exigencesTest()
etatJeu.commande.exigences = exigencesTest()
-- Une décoration fermée : grisée, avec ce qu'il faut pour l'ouvrir ; on ne peut pas la choisir
local croixFermee = boutonNomme("Deco_croix_argent")
verifier(croixFermee:GetAttribute("Ferme") == true and croixFermee.Text == "Croix d'argent · Amitié d'Inès : 4", "croix d'argent fermée : grisée, avec l'amitié qu'il faut")
cliquer("Deco_croix_argent")
verifier(fenetre.Message.Visible and fenetre.Message.Text == "Pas encore ouvert : Croix d'argent (Amitié d'Inès : 4)." and boutonNomme("Deco_croix_argent").BackgroundColor3 ~= ACCENT, "toucher une décoration fermée : ce qu'il faut pour l'ouvrir, rien n'est choisi")
serveur:atelier(joueur).etat.clientes.ines.amitie = 25
etatJeu.clientes.ines.amitie = 25
-- La palette ne montre que des rangées entières (une rangée coupée attirerait les clics à côté)
local palette = contenuD.Palette
verifier(palette.Size.Y.Offset % 44 == 0, "palette : rangées entières")
verifier(palette:FindFirstChild("Deco_lanterne_papier") == nil and palette:FindFirstChild("Deco_fleur_oranger") == nil and palette:FindFirstChild("Deco_perle") ~= nil, "les souvenirs fermés ne sont pas dans la palette (ils ne dévoilent pas l'histoire)")
-- Point de la robe (monde) à la place (u, v) d'une pièce
local function point3D(id, copie, u, v)
	local b = PolygoneModule.boite(Catalogue.piece(id).contour)
	local pos = PatronModule.point(id, copie, b.minX + u * (b.maxX - b.minX), b.minY + v * (b.maxY - b.minY), etatJeu.commande.mesures)
	return origineBoutique * ScenePoste.CADRE * (pos * Catalogue.STUDS_PAR_DM)
end
-- Toucher la scène : le rayon du faux Roblox renvoie l'impact préparé
local function toucherScene(impact)
	M.impacts = { impact }
	local appui = { UserInputType = Enum.UserInputType.MouseButton1, Position = Vector3.new(200, 250, 0) }
	M.avancer(0.5)
	UIS.InputBegan:Fire(appui, false)
	UIS.InputEnded:Fire(appui, false)
end
local function toucherRobe(nomPart, id, copie, u, v)
	toucherScene({ Instance = robe[nomPart], Position = point3D(id, copie, u, v), Normal = Vector3.new(0, 0, -1) })
end
local function centre(groupe)
	local somme, n = Vector3.new(0, 0, 0), 0
	for _, d in ipairs(groupe:GetChildren()) do
		if d:IsA("BasePart") then
			somme += d.CFrame.Position
			n += 1
		end
	end
	return somme / n
end
verifier(contenuD.Usage.Text == "Mercerie : choisis une décoration.", "rien de choisi : la ligne de la mercerie l'explique")
verifier(boutonNomme("Deco_perle").Text == "Perle · ×10" and boutonNomme("Deco_ruban_rose").Text == "Ruban rose · 1,50 m", "la palette dit ce qu'il reste dans la mercerie : le kit (dix perles, 1,50 m de ruban)")
toucherRobe("Piece_corsage_v_devant_unique", "corsage_v_devant", "unique", 0.5, 0.4)
verifier(#decorations:GetChildren() == 0 and fenetre.Message.Visible, "toucher la robe sans décoration choisie : un message")
do -- Sous-projet 6 : pas de nœud de satin dans le kit : grisé, on ne peut pas le choisir
	local noeudVide = boutonNomme("Deco_noeud_satin")
	verifier(noeudVide:GetAttribute("Epuise") == true and noeudVide:GetAttribute("Ferme") == false and noeudVide.Text == "Nœud de satin · ×0", "nœud de satin épuisé : grisé, « ×0 »")
end
cliquer("Deco_noeud_satin")
verifier(fenetre.Message.Text == "Pas assez de Nœud de satin dans ta mercerie : achètes-en à la Mercerie." and boutonNomme("Deco_noeud_satin").BackgroundColor3 ~= ACCENT, "toucher un article épuisé : un message, rien n'est choisi")
do -- La mercerie, par-dessus le panneau, sans quitter la robe : deux nœuds de satin
	local argentAvant = argent()
	cliquer("OuvrirMercerie")
	local merc = contenuD:FindFirstChild("Mercerie")
	verifier(merc ~= nil and merc:IsA("TextButton") and merc.Text == "" and merc.ZIndex > 20, "« Mercerie » : la boutique par-dessus le panneau (un bouton sans texte, qui arrête les appuis)")
	verifier(merc.Casiers:FindFirstChild("Case_lanterne_papier") == nil and boutonNomme("Case_perle").Text == "Perle · ×10", "un casier par article ouvert, avec ce qu'on en a")
	verifierTailles("mercerie, rien de choisi")
	cliquer("AcheterMercerie")
	verifier(fenetre.Message.Text == "Choisis d'abord un article." and argent() == argentAvant, "« Acheter » sans article : rien")
	cliquer("Case_noeud_satin")
	verifier(merc.Fiche.Article.Text == "Nœud de satin — 3 po l'unité" and merc.Fiche.Styles.Text == "Mignon +4, Romantique +2" and merc.Fiche.Quantite.Text == "×1" and boutonNomme("AcheterMercerie").Text == "Acheter (3 po)", "la fiche du nœud : son prix, ses styles, la quantité")
	cliquer("QuantitePlus")
	verifier(merc.Fiche.Quantite.Text == "×2" and boutonNomme("AcheterMercerie").Text == "Acheter (6 po)", "+ : deux nœuds, 6 po")
	cliquer("AcheterMercerie")
	verifier(argent() == argentAvant - 6 and serveur:atelier(joueur).etat.mercerie.noeud_satin == 2 and boutonNomme("Case_noeud_satin").Text == "Nœud de satin · ×2" and fenetre.Message.Text == "Acheté : Nœud de satin, ×2 (6 po).", "acheté : 6 po, deux nœuds dans la mercerie")
	verifier(M.sonsJoues[#M.sonsJoues] == "Atelier_achat", "l'achat fait sonner la caisse")
	verifier(boutonNomme("Deco_noeud_satin").Text == "Nœud de satin · ×2" and boutonNomme("Deco_noeud_satin"):GetAttribute("Epuise") == false, "la palette suit l'achat")
	-- (relecture) Une réponse perdue : l'état arrive plus tard du serveur ; la mercerie et la palette le suivent
	serveur:atelier(joueur).etat.mercerie.perle = 14
	SessionModule.courante:actualiser()
	verifier(boutonNomme("Case_perle").Text == "Perle · ×14" and boutonNomme("Deco_perle").Text == "Perle · ×14", "l'état réparé par le serveur : la mercerie et la palette le suivent")
	serveur:atelier(joueur).etat.mercerie.perle = 10
	SessionModule.courante:actualiser()
	verifierTailles("mercerie")
	cliquer("FermerMercerie")
	verifier(contenuD:FindFirstChild("Mercerie") == nil and titre() == "6. Décorations", "la mercerie se referme : on est toujours aux décorations")
end
cliquer("Deco_noeud_satin")
verifier(boutonNomme("Deco_noeud_satin").BackgroundColor3 == ACCENT and contenuD.Usage.Text == "Nœud de satin : 0 / 2", "nœud de satin choisi : aucun posé, deux dans la mercerie")
toucherRobe("Piece_corsage_v_devant_unique", "corsage_v_devant", "unique", 0.5, 0.4)
verifier(#decorations:GetChildren() == 1 and contenuD.Usage.Text == "Nœud de satin : 1 / 2" and boutonNomme("Deco_noeud_satin").Text == "Nœud de satin · ×1", "nœud posé sur le corsage : un sur deux, il en reste un")
verifier(M.sonsJoues[#M.sonsJoues] == "Atelier_decoration", "une décoration posée fait son petit bruit")
local noeud = decorations:GetChildren()[1]
verifier((centre(noeud) - point3D("corsage_v_devant", "unique", 0.5, 0.4)).Magnitude < 0.3, "le nœud est là où l'on a touché")
local tailleAvant = noeud:GetChildren()[1].Size
cliquer("Agrandir")
verifier(decorations:GetChildren()[1]:GetChildren()[1].Size.X > tailleAvant.X, "le nœud sélectionné grandit")
cliquer("Tourner15")
verifier(contenuD.Usage.Text == "Nœud de satin : 1 / 2", "tourner ou agrandir ne prend rien de plus")
-- Garniture point par point
cliquer("Deco_ruban_rose")
toucherRobe("Piece_jupe_trapeze_devant_unique", "jupe_trapeze_devant", "unique", 0.1, 0.9)
toucherRobe("Piece_jupe_trapeze_devant_unique", "jupe_trapeze_devant", "unique", 0.9, 0.9)
verifier(boutonNomme("FinirGarniture").Visible, "garniture en cours : bouton pour la finir")
cliquer("FinirGarniture")
local cmRuban = tonumber(((contenuD.Usage.Text:match("^Ruban rose : (%d,%d%d) / 1,50 m$") or ""):gsub(",", ""))) -- (cm)
verifier(#decorations:GetChildren() == 2 and cmRuban and cmRuban > 0 and boutonNomme("Deco_ruban_rose").Text == ("Ruban rose · %s m"):format(requireModule(scriptClient.Mercerie).metres(150 - (cmRuban or 0))), "ruban posé le long de la jupe, pris sur le mètre et demi du kit : " .. contenuD.Usage.Text)
-- Toucher une décoration la sélectionne ; supprimer, puis annuler
local partNoeud = decorations:GetChildren()[1]:GetChildren()[1]
toucherScene({ Instance = partNoeud, Position = partNoeud.CFrame.Position, Normal = Vector3.new(0, 0, -1) })
verifier(decorations:GetChildren()[1]:FindFirstChild("Selection") ~= nil and decorations:GetChildren()[2]:FindFirstChild("Selection") == nil, "le nœud touché est surligné : on voit ce que « Supprimer » va retirer")
cliquer("Supprimer")
verifier(#decorations:GetChildren() == 1 and boutonNomme("Deco_noeud_satin").Text == "Nœud de satin · ×2", "nœud touché puis supprimé : il est de nouveau à poser")
cliquer("Annuler")
verifier(#decorations:GetChildren() == 2 and boutonNomme("Deco_noeud_satin").Text == "Nœud de satin · ×1", "annuler : le nœud revient")
-- Glisser sur la scène fait tourner la vue autour du mannequin (sans rien poser)
local glisse = { UserInputType = Enum.UserInputType.MouseButton1, Position = Vector3.new(100, 300, 0) }
UIS.InputBegan:Fire(glisse, false)
UIS.InputChanged:Fire({ UserInputType = Enum.UserInputType.MouseMovement, Position = Vector3.new(220, 300, 0) }, false)
UIS.InputEnded:Fire(glisse, false)
verifier(camera.CFrame ~= origineBoutique * ScenePoste.CAMERA and #decorations:GetChildren() == 2, "glisser fait tourner la vue, sans rien poser")

---------------------------------------------------------------------------
-- Présentation, refus, retouche, livraison
---------------------------------------------------------------------------
local avantDeco = argent()
cliquer("Presenter")
verifier(titre() == "7. Photo et livraison" and argent() == avantDeco and serveur:atelier(joueur).etat.mercerie.noeud_satin == 1 and serveur:atelier(joueur).etat.mercerie.ruban_rose == 150 - cmRuban, "présenter : décorations prises à la mercerie (un nœud, le ruban), pas d'argent")
verifier(camera.CFrame == origineBoutique * ScenePoste.CAMERA, "la cliente voit la robe de face")
verifier(texte("Au moins 1 en Romantique (actuel :") ~= nil, "le score actuel est affiché à côté d'une exigence de style")
verifier(texte("Pour la journée : au moins 30 (actuel : 32)") ~= nil, "une exigence d'occasion, avec le score actuel de la robe")
verifier(#decorations:GetChildren() == 2, "la robe est présentée avec ses décorations")
verifierTailles("présentation")
-- La cliente en personne regarde la robe
local laCliente = scene:FindFirstChild("Cliente")
verifier(laCliente ~= nil and laCliente.Head.Bulle.Texte.Text == ScenePoste.PAROLES.photo, "la cliente est là et regarde la robe")
verifier(texte("(ajustement 100 %)") ~= nil, "la qualité montre l'ajustement aux mesures")
-- Photo : décor, lumière, couleur du mannequin
local Lighting = M.services.Lighting
local heureDuJeu = Lighting.ClockTime
cliquer("Decor_bleu")
cliquer("Lumiere_soir")
cliquer("Mannequin_noir")
verifier(scene.Fond.Color == ScenePoste.DECORS.bleu and Lighting.ClockTime == ScenePoste.LUMIERES.soir.ClockTime and scene.Mannequin.Buste.Color == ScenePoste.MANNEQUINS.noir, "décor bleu, lumière du soir, mannequin noir")
verifier(boutonNomme("Decor_bleu").BackgroundColor3 == ACCENT, "le décor choisi est en surbrillance")
-- Capture refusée par Roblox : l'interface revient, avec un message
M.echecCapture = true
cliquer("PrendrePhoto")
M.echecCapture = nil
verifier(gui.Atelier.Enabled and camera.CFrame == origineBoutique * ScenePoste.CAMERA and fenetre.Message.Visible and fenetre.Message.Text == "La photo n'a pas pu être prise.", "capture refusée : interface rétablie, message")
verifier(not fenetre.Contenu.Apercu.Visible, "capture refusée : pas d'aperçu")
-- Capture qui ne répond pas : l'interface revient au bout d'un moment
M.captureMuette = true
cliquer("PrendrePhoto")
M.captureMuette = nil
verifier(not gui.Atelier.Enabled, "capture en cours : interface cachée")
M.avancer(ScenePoste.ATTENTE_CAPTURE + 0.1)
verifier(gui.Atelier.Enabled and camera.CFrame == origineBoutique * ScenePoste.CAMERA and camera.FieldOfView == 70, "capture sans réponse : l'interface et la vue reviennent")
M.avancer(1) -- le message de la capture refusée, plus haut, s'est effacé
verifier(fenetre.Message.Visible and fenetre.Message.Text == "La photo n'a pas pu être prise.", "capture sans réponse : le joueur est prévenu")
-- La réponse tardive d'une prise abandonnée ne termine pas la suivante
local tardive = M.rappelCapture
M.captureMuette = true
cliquer("PrendrePhoto")
M.captureMuette = nil
tardive("rbxtemp://tardive")
verifier(not gui.Atelier.Enabled and not fenetre.Contenu.Apercu.Visible, "réponse tardive d'une prise abandonnée : la prise en cours continue")
M.rappelCapture("rbxtemp://seconde")
verifier(gui.Atelier.Enabled and fenetre.Contenu.Apercu.Visible and fenetre.Contenu.Apercu.Image.Image == "rbxtemp://seconde", "la prise en cours se termine avec sa propre photo")
cliquer("FermerApercu")
-- Le minuteur d'une prise terminée ne coupe pas la suivante
cliquer("PrendrePhoto")
cliquer("FermerApercu")
M.captureMuette = true
cliquer("PrendrePhoto")
M.captureMuette = nil
M.avancer(1.1) -- le minuteur de la prise précédente (2 s) sonne
verifier(not gui.Atelier.Enabled, "le minuteur d'une prise terminée ne coupe pas la suivante")
M.avancer(1)
verifier(gui.Atelier.Enabled and camera.CFrame == origineBoutique * ScenePoste.CAMERA, "la prise sans réponse se termine à son propre minuteur")
-- Prise de vue : sans l'interface, vue centrée sur la robe ; puis aperçu et enregistrement
local pendant = nil
M.surCapture = function()
	pendant = { interface = gui.Atelier.Enabled, vue = camera.CFrame, bulle = laCliente.Head.Bulle.Enabled, champ = camera.FieldOfView }
end
cliquer("PrendrePhoto")
M.surCapture = nil
verifier(pendant ~= nil and pendant.interface == false and pendant.vue == origineBoutique * ScenePoste.CAMERA_PHOTO and pendant.bulle == false, "photo prise sans l'interface ni la bulle, vue centrée sur la robe")
verifier(table.find(M.sonsJoues, "Atelier_photo") ~= nil and M.sonsJoues[#M.sonsJoues] == "Atelier_photo", "déclic de l'appareil photo")
verifier(pendant.champ == ScenePoste.CHAMP_PHOTO and ScenePoste.CHAMP_PHOTO < 70, "champ resserré sur la robe pendant la prise")
verifier(gui.Atelier.Enabled and camera.CFrame == origineBoutique * ScenePoste.CAMERA and not laCliente.Head.Bulle.Enabled and camera.FieldOfView == 70, "après la photo : interface, vue et champ rétablis ; la bulle reste cachée (fenêtre ouverte : l'encadré parle)")
local apercu = fenetre.Contenu:FindFirstChild("Apercu")
verifier(apercu ~= nil and apercu.Visible and apercu.Image.Image == "rbxtemp://capture/" .. M.captures, "aperçu de la photo")
-- Dans Roblox, un simple cadre (même Active) laisse passer l'appui aux boutons cachés dessous (Livrer…) ;
-- un bouton sans texte l'arrête (vérifié dans Studio)
verifier(apercu:IsA("TextButton") and apercu.Text == "" and not apercu.AutoButtonColor, "l'aperçu arrête les appuis : rien ne passe aux boutons cachés dessous")
-- « Fermer » referme l'aperçu : un second appui trop long tomberait sur ce qui est dessous ; rien n'y est
local fermerA = apercu.FermerApercu
local hautF, basF = fermerA.Position.Y.Offset, fermerA.Position.Y.Offset + fermerA.Size.Y.Offset
local dessous = {}
for _, b in ipairs(fenetre.Contenu:GetChildren()) do
	local pos, ancre = b.Position or UDim2.new(), b.AnchorPoint or Vector2.new()
	if b:IsA("GuiButton") and b ~= apercu and pos.Y.Scale == 0 and ancre.Y == 0 then
		if pos.Y.Offset < basF and pos.Y.Offset + b.Size.Y.Offset > hautF then
			table.insert(dessous, b.Name)
		end
	end
end
verifier(#dessous == 0, "« Fermer » de l'aperçu n'est au-dessus d'aucun bouton ; dessous : " .. table.concat(dessous, ", "))
cliquer("EnregistrerPhoto")
verifier(M.galerie ~= nil and M.galerie[1] == apercu.Image.Image and fenetre.Message.Visible, "photo proposée à la galerie du joueur")
M.echecGalerie = true
cliquer("EnregistrerPhoto")
M.echecGalerie = nil
verifier(fenetre.Message.Visible and fenetre.Message.Text == "La galerie n'est pas disponible pour le moment.", "galerie indisponible : message, sans erreur")
cliquer("FermerApercu")
verifier(not apercu.Visible, "aperçu refermé")
-- Fenêtre fermée pour se promener : décor, lumière et mannequin du jeu ; rouverte : réglages remis
cliquer("Fermer")
verifier(scene:FindFirstChild("Fond") == nil and Lighting.ClockTime == heureDuJeu and scene.Mannequin.Buste.Color ~= ScenePoste.MANNEQUINS.noir, "fenêtre fermée pendant la photo : décor, lumière et mannequin du jeu")
cliquer("OuvrirAtelier")
verifier(scene.Fond.Color == ScenePoste.DECORS.bleu and Lighting.ClockTime == ScenePoste.LUMIERES.soir.ClockTime and scene.Mannequin.Buste.Color == ScenePoste.MANNEQUINS.noir, "fenêtre rouverte : les réglages de la photo reviennent")
cliquer("RetourDecorations")
verifier(scene:FindFirstChild("Fond") == nil and Lighting.ClockTime == heureDuJeu and scene.Mannequin.Buste.Color ~= ScenePoste.MANNEQUINS.noir, "en quittant la présentation : décor, lumière et mannequin rétablis")
verifier(titre() == "6. Décorations" and #decorations:GetChildren() == 2 and boutonNomme("Deco_noeud_satin").Text == "Nœud de satin · ×1" and contenuD.Usage.Text == "Mercerie : choisis une décoration.", "retour aux décorations : les décorations posées restent, la mercerie aussi")
cliquer("Presenter")
-- « Livrer la robe » est loin de « Prendre la photo », et demande une confirmation
local prendre, livrer = boutonNomme("PrendrePhoto"), boutonNomme("Livrer")
verifier(livrer.Position.Y.Offset - (prendre.Position.Y.Offset + prendre.Size.Y.Offset) >= 16, "« Livrer la robe » à distance de « Prendre la photo »")
cliquer("Livrer")
verifier(titre() == "7. Photo et livraison" and livrer.Text == "Vraiment ? Touche encore", "livrer : confirmation demandée")
livrer.Activated:Fire() -- second appui d'un double clic (moins de 0,4 s) : ignoré
verifier(titre() == "7. Photo et livraison", "un double clic trop rapide ne livre pas")
cliquer("Livrer")
verifier(titre() == "La cliente refuse la robe" and texte("Avec : Croix d'argent") ~= nil, "sans la croix d'argent : robe refusée, exigence ratée affichée")
do -- Son avis : une étoile
	local etoiles = gui.Atelier.Dialogue.Etoiles
	local OR = requireModule(scriptClient.Dialogue).OR
	verifier(gui.Atelier.Dialogue.Visible and gui.Atelier.Dialogue.Texte.Text == Clientes.get("colette").repliques.deception and etoiles.Visible and etoiles.Etoile1.TextColor3 == OR and etoiles.Etoile2.TextColor3 ~= OR, "robe refusée : sa déception dans l'encadré, une étoile")
	verifier(gui.Atelier.Dialogue.Portrait:GetAttribute("Expression") == "decue", "(sous-projet 7) son portrait, déçue")
	do -- (la fenêtre en panneau commence à 16 px du bord droit de l'écran)
		local e = fenetre.UIScale.Scale
		local bordFenetre = workspace.CurrentCamera.ViewportSize.X - 16 - requireModule(scriptClient.UiKit).LARGEUR_PANNEAU * e
		local dialogue = gui.Atelier.Dialogue
		verifier(dialogue.Position.X.Offset >= 16 and dialogue.Position.X.Offset + requireModule(scriptClient.Dialogue).LARGEUR * e <= bordFenetre - 16 + 1e-6, "fenêtre en panneau à droite : l'encadré à sa gauche, sur la scène")
	end
end
verifier(M.sonsJoues[#M.sonsJoues] == "Atelier_echec", "robe refusée : un son déçu")
verifierTailles("refus")
cliquer("Retoucher")
verifier(titre() == "6. Décorations", "retouche : retour aux décorations")
-- La croix d'argent manque : on l'achète à la mercerie, sans quitter la robe
cliquer("OuvrirMercerie")
cliquer("Case_croix_argent")
cliquer("AcheterMercerie")
verifier(serveur:atelier(joueur).etat.mercerie.croix_argent == 1 and #decorations:GetChildren() == 2, "une croix d'argent achetée depuis les décorations, la robe telle quelle")
cliquer("FermerMercerie")
cliquer("Deco_croix_argent")
toucherRobe("Piece_corsage_v_devant_unique", "corsage_v_devant", "unique", 0.5, 0.7)
cliquer("Presenter")
local avantLivraison = argent()
-- Image d'une pièce découpée (en cache depuis la couture), à comparer après la livraison
local Vignettes = requireModule(scriptClient.Vignettes)
local etatClient = requireModule(scriptClient.Session).courante.etat
local idVignette = "corsage_v_devant"
local tissuVignette, placeVignette = etatClient.tissus[idVignette], table.clone(etatClient.coupees[idVignette])
local imageAvant = Vignettes.piece(idVignette, tissuVignette, placeVignette, 256)
-- Prestige 45 avant la livraison : elle fait passer au niveau 3 (les satins et la dentelle noire s'ouvrent) ;
-- cinq livraisons déjà faites : celle-ci est la sixième, les robes libres et le courrier sont ouverts, et une
-- lettre arrive
serveur:atelier(joueur).etat.prestige = 45
serveur:atelier(joueur).etat.livraisons = 5
serveur:atelier(joueur).etat.ventes = 24 -- (vingt-neuf robes en tout : celle-ci, la trentième, fait monter le rang)
cliquer("Livrer")
cliquer("Livrer")
verifier(titre() == "Aiguille & Dentelle" and argent() > avantLivraison, "robe acceptée : payée")
verifier(requireModule(scriptClient.Session).courante.derniere.reponse.bilan.occasions.journee >= 30, "la cliente a jugé l'occasion (robe pour la journée)")
verifier(M.sonsJoues[#M.sonsJoues] == "Atelier_reussite", "robe acceptée : une petite fanfare")
verifier(texte("Colette est ravie") ~= nil, "l'accueil annonce la paie")
verifier(texte("Nouveau rang : Première main !") ~= nil, "la trentième robe livrée : « Nouveau rang : Première main ! »")
serveur:atelier(joueur).etat.ventes = 0
do -- Sous-projet 5 : son avis en étoiles, dans l'annonce
	local qualite = requireModule(scriptClient.Session).courante.derniere.reponse.bilan.qualite
	local n = requireModule(dossier.Progression).etoiles(true, qualite)
	verifier(texte("Colette est ravie ! " .. string.rep("★", n) .. string.rep("☆", 5 - n) .. " +") ~= nil, "l'annonce donne son avis : " .. n .. " étoiles sur 5")
end
verifier(texte("Amitié de Colette : +") ~= nil and texte("Prestige : +") ~= nil, "l'accueil annonce l'amitié et le prestige gagnés")
verifier(texte("Acompte de ") ~= nil and texte("(niveau 3 !)") ~= nil and texte("Nouveau : les satins (4), Dentelle noire.") ~= nil, "l'accueil rappelle l'acompte, le niveau de prestige atteint et ce qui vient de s'ouvrir")
do -- Sous-projet 5 : l'affiche des nouveautés, une carte par nouveauté (l'échantillon de chaque tissu)
	local affiche = fenetre.Contenu:FindFirstChild("Affiche")
	local cartes, echantillons = 0, 0
	for _, c in ipairs(affiche and affiche:GetChildren() or {}) do
		if c.Name:match("^Nouveau_") then
			cartes += 1
			echantillons += if c.Image.ImageContent ~= nil and c.Image.ImageContent.statique then 1 else 0
		end
	end
	verifier(affiche ~= nil and affiche.Visible and affiche.TitreAffiche.Text == "Nouveautés à l'atelier !" and cartes == 5 and echantillons == 4 and affiche.Nouveau_dentelle_noire.Nom.Text == "Dentelle noire" and affiche.Nouveau_dentelle_noire.Image:FindFirstChild("UIStroke") ~= nil, "l'affiche des nouveautés : cinq cartes, l'échantillon des quatre satins, un liseré autour (" .. cartes .. ", " .. echantillons .. ")")
	M.services.UserInputService.InputBegan:Fire({ KeyCode = Enum.KeyCode.E, UserInputType = Enum.UserInputType.Keyboard }, false)
	verifier(titre() == "Aiguille & Dentelle", "E ne sonne pas la clochette tant que l'affiche est ouverte")
	cliquer("FermerAffiche")
	verifier(not affiche.Visible, "l'affiche se referme")
end
local prestigeJoueur = serveur:atelier(joueur).etat.prestige
verifier(fenetre.Contenu.Prestige.Text == ("Réputation : Appréciée (prestige 3) — %d / 100"):format(prestigeJoueur), "jauge de prestige : « Réputation : Appréciée (prestige 3) — " .. prestigeJoueur .. " / 100 »")
verifier(math.abs(fenetre.Contenu.JaugePrestige.Rempli.Size.X.Scale - (prestigeJoueur - 50) / 50) < 1e-6, "la jauge se remplit vers le niveau suivant")
verifierTailles("accueil")
serveur:atelier(joueur).etat.prestige = 530 -- (tout reste ouvert pour la suite)
-- Le courrier : une lettre de Colette (la seule cliente déjà venue), qui dépasse de la boîte aux lettres
verifier(texte("Une lettre de Colette est arrivée.") ~= nil and fenetre.Contenu:FindFirstChild("Lettre1") ~= nil and boutonNomme("Inviter_1") ~= nil, "une lettre de Colette arrive, avec « Inviter »")
verifier(boutonNomme("Inviter_1").AbsoluteSize.Y >= 40, "« Inviter » assez haut pour le doigt")
verifier(string.find(fenetre.Contenu.Lettre1.Text, "Colette : « ", 1, true) == 1, "la lettre annonce une exigence de sa commande")
verifier(scene:FindFirstChild("Lettre") ~= nil, "une lettre dépasse de la boîte aux lettres du comptoir")
-- Le carnet d'adresses : les clientes déjà venues, leur amitié, ce que le prochain niveau ouvrira
cliquer("OuvrirCarnetAdresses")
verifier(texte("Colette Marchand — amitié niveau 5") ~= nil and fenetre.Contenu.CarnetAdresses:FindFirstChild("Adresse_margot") == nil, "carnet d'adresses : Colette, pas encore Margot")
do -- (sous-projet 7) son portrait, contente (amitié de niveau 5), à gauche de sa ligne
	local medaillon = fenetre.Contenu.CarnetAdresses.Liste:FindFirstChild("Portrait_colette")
	local ligne = fenetre.Contenu.CarnetAdresses.Liste.Adresse_colette
	verifier(medaillon ~= nil and medaillon.Visible and medaillon:GetAttribute("Expression") == "contente" and ligne.Position.X.Offset >= medaillon.Size.X.Offset, "carnet d'adresses : le portrait de Colette, contente, devant sa ligne")
end
do -- Le rang de la couturière, en tête du carnet d'adresses
	local e = requireModule(scriptClient.Session).courante.etat
	verifier(fenetre.Contenu.CarnetAdresses.TitreAdresses.Text == "Carnet d'adresses — " .. requireModule(dossier.Progression).texteRang(e.livraisons + e.ventes), "carnet d'adresses : le rang de la couturière (" .. fenetre.Contenu.CarnetAdresses.TitreAdresses.Text .. ")")
end
cliquer("FermerCarnetAdresses")
verifier(not fenetre.Contenu.CarnetAdresses.Visible, "carnet d'adresses refermé")
verifier(imageAvant ~= nil and Vignettes.piece(idVignette, tissuVignette, placeVignette, 256) ~= imageAvant, "commande finie : les images des pièces découpées sont oubliées (mémoire)")
M.avancer(1)
verifier(maVitrine:FindFirstChild("Exposition") ~= nil, "le client construit la robe exposée dans la vitrine de la rue")
verifier(maVitrine:GetAttribute("Recette") == requireModule(dossier.Recette).encoder(serveur:atelier(joueur).etat.robes[1]), "la robe livrée part dans la vitrine de la boutique, sur la rue")
verifier(#robe:GetChildren() == 0 and #decorations:GetChildren() == 0 and camera.CameraType == Enum.CameraType.Custom, "atelier libéré, caméra rendue au joueur")
verifier(laCliente.Parent ~= nil and laCliente.Head.Bulle.Texte.Text == Clientes.get("colette").repliques.merci, "Colette remercie")
do -- Son avis en étoiles, dans l'encadré : celles de la qualité de la robe
	local dialogue = gui.Atelier.Dialogue
	local qualite = requireModule(scriptClient.Session).courante.derniere.reponse.bilan.qualite
	local n = requireModule(dossier.Progression).etoiles(true, qualite)
	local OR, dorees = requireModule(scriptClient.Dialogue).OR, 0
	for k = 1, 5 do
		dorees += if dialogue.Etoiles["Etoile" .. k].TextColor3 == OR then 1 else 0
	end
	verifier(dialogue.Visible and dialogue.Texte.Text == Clientes.get("colette").repliques.merci and dialogue.Etoiles.Visible and dorees == n and n >= 2, ("Colette remercie dans l'encadré, avec son avis : %d étoiles (qualité %d %%)"):format(dorees, requireModule(scriptClient.UiKit).pourcent(qualite)))
end
M.avancer(ScenePoste.DUREE_ADIEU + 0.5)
verifier(laCliente.Parent == nil and not gui.Atelier.Dialogue.Visible, "puis elle s'en va, et l'encadré se vide")
do -- Sous-projet 6 : la mercerie, depuis l'accueil (à droite de la réputation) ; E ne sonne pas tant qu'elle est ouverte
	local bouton, prestige = boutonNomme("OuvrirMercerie"), fenetre.Contenu.Prestige
	verifier(bouton.Position.X.Offset >= prestige.Position.X.Offset + prestige.Size.X.Offset and bouton.Position.Y.Offset == prestige.Position.Y.Offset, "« Mercerie » à droite de la réputation")
	cliquer("OuvrirMercerie")
	verifier(fenetre.Contenu:FindFirstChild("Mercerie") ~= nil, "la mercerie s'ouvre par-dessus l'accueil")
	M.services.UserInputService.InputBegan:Fire({ KeyCode = Enum.KeyCode.E, UserInputType = Enum.UserInputType.Keyboard }, false)
	verifier(titre() == "Aiguille & Dentelle", "E ne sonne pas la clochette tant que la mercerie est ouverte")
	cliquer("Case_ruban_rose")
	verifier(fenetre.Contenu.Mercerie.Fiche.Quantite.Text == "1 × 50 cm" and fenetre.Contenu.Mercerie.Fiche.Styles.Text == "Mignon +3 (pour 50 cm)" and boutonNomme("AcheterMercerie").Text == "Acheter (5 po)", "le ruban se vend par 50 cm : 5 po, ses styles pour 50 cm")
	local avant, ruban = argent(), serveur:atelier(joueur).etat.mercerie.ruban_rose
	cliquer("AcheterMercerie")
	verifier(argent() == avant - 5 and serveur:atelier(joueur).etat.mercerie.ruban_rose == ruban + 50 and boutonNomme("Case_ruban_rose").Text == ("Ruban rose · %s m"):format(requireModule(scriptClient.Mercerie).metres(ruban + 50)), "50 cm de ruban achetés à l'accueil")
	cliquer("FermerMercerie")
	verifier(fenetre.Contenu:FindFirstChild("Mercerie") == nil, "la mercerie se referme")
end

---------------------------------------------------------------------------
-- Robes libres (après deux commandes livrées) : une taille, pas de cliente ; à la photo, vendre ou offrir
---------------------------------------------------------------------------
do -- (les variables de cette partie restent dans ce bloc : Luau limite un bloc à 200 variables locales)
verifier(boutonNomme("RobeLibre") ~= nil, "deux commandes livrées : « Robe libre » à l'accueil")
cliquer("RobeLibre")
local boutonL, boutonCarnet = boutonNomme("RobeLibre_L"), boutonNomme("OuvrirCarnetAdresses")
verifier(boutonL.AbsolutePosition.X + boutonL.AbsoluteSize.X <= boutonCarnet.AbsolutePosition.X, "le choix de la taille ne recouvre pas « Carnet d'adresses »")
cliquer("AnnulerTaille")
verifier(fenetre.Contenu:FindFirstChild("ChoixTaille") == nil and boutonNomme("RobeLibre") ~= nil and serveur:atelier(joueur).etat.etape == "accueil", "« × » : on renonce à la robe libre, rien n'est commencé")
cliquer("RobeLibre")
cliquer("RobeLibre_M")
verifier(titre() == "1. Carnet de croquis" and texte("Robe libre (taille M) : à ton idée.") ~= nil, "robe libre : droit au carnet, sans exigence")
verifier(scene:FindFirstChild("Cliente") == nil and serveur:atelier(joueur).etat.commande.libre, "robe libre : personne n'entre")
cliquer("Tissu_corsage_droit_devant")
verifier(boutonNomme("Tissu_toile_jute") ~= nil and texte("Gratuit · Journée, Travail, Décontracté, Chaude") ~= nil, "la toile de jute est gratuite (et ses quatre étiquettes)")
cliquer("Tissu_toile_jute")
cliquer("ToutEnUnTissu")
cliquer("Valider")
verifier(titre() == "2. Achat du tissu" and texte("Toile de jute — Gratuit") ~= nil, "à l'achat aussi, la toile de jute est « Gratuit »")
-- La robe menée jusqu'à la photo sur le serveur (coupée, épinglée, cousue), sans repasser par tous les postes
local function robeLibreALaPhoto(tissu, croquis)
	local e = serveur:atelier(joueur).etat
	e.croquis = croquis or { corsage = "corsage_droit", manches = "manches_sans", col = "col_sans", jupe = "jupe_droite" }
	e.tissus = {}
	for _, id in ipairs(e:piecesDuCroquis()) do
		e.tissus[id] = tissu
		e.coupees[id] = { x = 0, y = 0, angle = 0 }
		e.epinglees[id] = true
		e.coutures[id] = 0.9
	end
	e.commande.matieres = if tissu == "toile_jute" then 0 else 10
	e.etape = "decorations"
	requireModule(scriptClient.Session).courante:actualiser()
	verifier(boutonNomme("Presenter").Text == "Présenter la robe", "robe libre : « Présenter la robe » (pas de cliente)")
	cliquer("Presenter")
	verifier(titre() == "7. Photo et vente" and string.find(fenetre.Contenu.Qualite.Text, "ajustement", 1, true) == nil and boutonNomme("Vendre").TextSize <= 14, "photo d'une robe libre : « 7. Photo et vente », la qualité sans ajustement, « Vendre » en 14 px")
end
robeLibreALaPhoto("coton_blanc")
local prixLibre = serveur:atelier(joueur).etat:prixVente()
verifier(fenetre.Contenu.PrixVente.Text == ("Prix de vente : %d po"):format(prixLibre) and boutonNomme("Vendre").Text == ("Vendre (%d po)"):format(prixLibre), "à la photo : le prix de vente, « Vendre (" .. prixLibre .. " po) »")
verifier(fenetre.Contenu:FindFirstChild("Livrer") == nil, "une robe libre ne se livre pas")
do -- À la vente : le rang de la couturière
	local e = serveur:atelier(joueur).etat
	verifier(fenetre.Contenu.Rang.Text == "Ton rang : " .. requireModule(dossier.Progression).texteRang(e.livraisons + e.ventes), "à la vente : le rang (" .. fenetre.Contenu.Rang.Text .. ")")
	verifier(fenetre.Contenu.Rang.Size.Y.Offset >= 2 * 19 and fenetre.Contenu.Rang.TextYAlignment == Enum.TextYAlignment.Top, "le rang tient sur deux lignes sans déborder sur le prix")
end
cliquer("Offrir")
verifier(boutonNomme("Offrir_colette") ~= nil and fenetre.Contenu.ChoixCliente:FindFirstChild("Offrir_ines") == nil, "offrir : seulement aux clientes déjà venues")
cliquer("FermerChoixCliente")
verifier(not fenetre.Contenu.ChoixCliente.Visible, "annuler : le choix se ferme")
local avantVente = argent()
-- (quatorze robes déjà livrées : celle-ci est la quinzième, la couturière change de rang)
local livraisonsVraies = serveur:atelier(joueur).etat.livraisons
serveur:atelier(joueur).etat.livraisons = 14
cliquer("Vendre")
cliquer("Vendre")
verifier(titre() == "Aiguille & Dentelle" and argent() == avantVente + prixLibre and texte(("Robe vendue ! +%d pièces d'or"):format(prixLibre)) ~= nil, "robe vendue : le prix dans la caisse, annoncé")
verifier(fenetre.Contenu:FindFirstChild("Affiche") == nil, "rien de nouveau : pas d'affiche")
verifier(texte("Nouveau rang : Couturière !") ~= nil, "la quinzième robe : « Nouveau rang : Couturière ! »")
serveur:atelier(joueur).etat.livraisons = livraisonsVraies
verifier(M.sonsJoues[#M.sonsJoues] == "Atelier_achat" and serveur:atelier(joueur).etat.ventes == 1, "vendue : la caisse sonne")
M.avancer(1)
verifier(maVitrine:GetAttribute("Recette") == requireModule(dossier.Recette).encoder(serveur:atelier(joueur).etat.robes[1]), "la robe vendue part en vitrine")
-- La suivante, en toile de jute, offerte à Colette
local amitieColette = serveur:atelier(joueur).etat.clientes.colette.amitie
cliquer("RobeLibre")
cliquer("RobeLibre_S")
verifier(texte("Robe libre (taille S) : à ton idée.") ~= nil, "une autre robe libre, taille S")
-- Celle-ci en variantes nouvelles (sous-projet 4) : choisies au carnet, cousues, montrées en 3D jusqu'à la photo
local croquisNouveau = { corsage = "corsage_cache_coeur", manches = "manches_trois_quarts", col = "col_marin", jupe = "jupe_crayon" }
for _, v in pairs(croquisNouveau) do
	choisirModele(v)
	verifier(fenetre.Contenu.Page["Modele_" .. Catalogue.variante(v).famille].Text == Catalogue.variante(v).nom, v .. " choisie au carnet")
end
cliquer("Tissu_corsage_cache_coeur_devant")
cliquer("Tissu_toile_jute")
cliquer("ToutEnUnTissu")
cliquer("Valider")
do
	local croquisServeur = serveur:atelier(joueur).etat.croquis
	verifier(titre() == "2. Achat du tissu" and croquisServeur.corsage == "corsage_cache_coeur" and croquisServeur.manches == "manches_trois_quarts" and croquisServeur.col == "col_marin" and croquisServeur.jupe == "jupe_crayon", "croquis en variantes nouvelles validé au carnet : le serveur l'accepte")
end
robeLibreALaPhoto("toile_jute", croquisNouveau)
local robeNouvelle, manquantes = scene:FindFirstChild("Robe"), {}
for _, nom in ipairs({ "Piece_corsage_cache_coeur_devant_unique", "Piece_manche_trois_quarts_gauche", "Piece_col_marin_droite", "Piece_jupe_crayon_dos_unique" }) do
	if not (robeNouvelle and robeNouvelle:FindFirstChild(nom, true)) then
		table.insert(manquantes, nom)
	end
end
verifier(#manquantes == 0, "robe en variantes nouvelles montrée en 3D à la photo (manquent : " .. table.concat(manquantes, ", ") .. ")")
-- Sous-projet 4 : dix clientes déjà venues et douze événements passés (l'état d'avant revient ensuite) ; toutes
-- dans le choix « Offrir à… », puis toutes dans le carnet d'adresses de l'accueil
local avant8c = { clientes = table.clone(serveur:atelier(joueur).etat.clientes), faites = table.clone(serveur:atelier(joueur).etat.histoire.faites) }
do
	local e = serveur:atelier(joueur).etat
	for _, c in ipairs(Clientes.LISTE) do
		local fiche = if e.clientes[c.id] then table.clone(e.clientes[c.id]) else { amitie = 0, vues = 0, derniere = 0 }
		fiche.vues = math.max(1, fiche.vues)
		e.clientes[c.id] = fiche
	end
	for _, ev in ipairs(requireModule(dossier.Histoire).EVENEMENTS) do
		for _, c in ipairs(ev.commandes) do
			e.histoire.faites[c.id] = true
		end
	end
	e.etape = "decorations" -- (l'écran de la photo se refait en y revenant)
	requireModule(scriptClient.Session).courante:actualiser()
	cliquer("Presenter")
	cliquer("Offrir")
	local derniere = boutonNomme("Offrir_maelle")
	verifier(derniere.Position.Y.Offset + derniere.Size.Y.Offset <= fenetre.Size.Y.Offset + fenetre.Contenu.Size.Y.Offset, "dix clientes à qui offrir : toutes dans la fenêtre")
	cliquer("FermerChoixCliente")
end
cliquer("Offrir")
cliquer("Offrir_colette")
local gainCadeau = serveur:atelier(joueur).etat.clientes.colette.amitie - amitieColette
verifier(titre() == "Aiguille & Dentelle" and texte(if gainCadeau >= 3 then "Colette adore la robe que tu lui offres !" else "Colette te remercie pour la robe.") ~= nil and texte("Amitié de Colette : +") ~= nil, "offerte à Colette : l'accueil l'annonce, selon ce qu'elle en pense (+" .. gainCadeau .. ")")
verifier(serveur:atelier(joueur).etat.clientes.colette.amitie > amitieColette, "son amitié monte")
do
	cliquer("OuvrirCarnetAdresses")
	local liste = fenetre.Contenu.CarnetAdresses:FindFirstChild("Liste")
	local bas = 0
	for _, d in ipairs(liste and liste:GetChildren() or {}) do
		if d:IsA("GuiObject") then
			bas = math.max(bas, d.Position.Y.Offset + d.Size.Y.Offset)
		end
	end
	verifier(liste ~= nil and liste:IsA("ScrollingFrame") and bas > 0 and (if liste.CanvasSize then liste.CanvasSize.Y.Offset else 0) >= bas and liste:FindFirstChild("Adresse_maelle") ~= nil and texte("Le grand défilé du quartier — souvenir : Rosette d'honneur") ~= nil, "dix clientes et douze souvenirs : le carnet d'adresses défile jusqu'au dernier")
	verifier(liste.ScrollBarImageColor3 == requireModule(scriptClient.UiKit).COULEURS.accent, "la barre de défilement du carnet d'adresses se voit (couleur d'accent, comme les onglets)")
	verifier(liste.Souvenirs.TextYAlignment == Enum.TextYAlignment.Top, "les souvenirs commencent juste sous les adresses (texte calé en haut)")
	cliquer("FermerCarnetAdresses")
	local e = serveur:atelier(joueur).etat
	for _, c in ipairs(Clientes.LISTE) do
		if c.id ~= "colette" then
			e.clientes[c.id] = avant8c.clientes[c.id]
		end
	end
	e.histoire.faites = avant8c.faites
	requireModule(scriptClient.Session).courante:actualiser()
end
end

---------------------------------------------------------------------------
-- Inviter : la cliente de la lettre vient avec sa commande ; livrée, un point d'amitié de plus
---------------------------------------------------------------------------
do
cliquer("Inviter_1")
verifier(titre() == "Les mesures" and serveur:atelier(joueur).etat.commande.parLettre and #serveur:atelier(joueur).etat.lettres == 0, "invitée : Colette vient avec la commande de sa lettre")
verifier(fenetre.Message.Visible and string.find(fenetre.Message.Text, "Colette verse un acompte", 1, true) == 1, "elle verse l'acompte")
M.avancer(0.5)
verifier(scene:FindFirstChild("Lettre") == nil, "plus de lettre dans la boîte")
do -- Une cliente déjà mesurée : la fiche donne ses mesures du carnet
	local m = serveur:atelier(joueur).etat.clientes.colette.mesures
	local attendu = ("Au carnet : %d / %d / %d cm"):format(math.round(m.poitrine * 10), math.round(m.taille * 10), math.round(m.hanches * 10))
	verifier(fenetre.Contenu:FindFirstChild("FicheCarnet") ~= nil and string.find(fenetre.Contenu.FicheCarnet.Text, attendu, 1, true) == 1, "déjà mesurée : ses mesures du carnet (" .. attendu .. ")")
end
cliquer("ReprendreMesures")
verifier(titre() == "1. Carnet de croquis", "ses mesures reprises : le carnet")
-- La robe menée jusqu'à la photo sur le serveur, sans repasser par tous les postes
local e = serveur:atelier(joueur).etat
e.commande.exigences = { { type = "qualite", valeur = 0.1 } }
e.croquis = { corsage = "corsage_droit", manches = "manches_sans", col = "col_sans", jupe = "jupe_droite" }
e.tissus = {}
for _, id in ipairs(e:piecesDuCroquis()) do
	e.tissus[id] = "coton_blanc"
	e.coupees[id] = { x = 0, y = 0, angle = 0 }
	e.epinglees[id] = true
	e.coutures[id] = 0.9
end
e.etape = "photo"
requireModule(scriptClient.Session).courante:actualiser()
cliquer("Livrer")
cliquer("Livrer")
verifier(titre() == "Aiguille & Dentelle" and texte("Colette est ravie") ~= nil and texte("Amitié de Colette : +4") ~= nil, "commande venue par lettre : +4 d'amitié (+3 et +1 de la lettre)")
M.avancer(ScenePoste.DUREE_ADIEU + 0.5)
end

---------------------------------------------------------------------------
-- L'histoire : l'événement du quartier en cours ; une conversation, puis la commande ; la dernière robe livrée
-- le fait avoir lieu (épilogue, souvenir), et le suivant s'annonce
---------------------------------------------------------------------------
do
local Histoire = requireModule(dossier.Histoire)
local e = serveur:atelier(joueur).etat
verifier(texte("Événement : Le bal des lanternes — robes livrées 0 / 2") ~= nil and boutonNomme("CommandeHistoire") ~= nil, "l'événement en cours s'annonce à l'accueil")
e.histoire.faites.lanternes_margot = true -- (la robe de Margot, déjà livrée : celle de Colette sera la dernière)
-- (et trois lettres en attente : la boîte est pleine)
local lettre = { cliente = "colette", commande = { cliente = "colette", taille = "M", exigences = { { type = "min", style = "romantique", valeur = 30 } } } }
e.lettres = { lettre, table.clone(lettre), table.clone(lettre) }
local def = Histoire.commande("lanternes_colette")
cliquer("CommandeHistoire")
local conversation = fenetre.Contenu.Conversation
-- Pendant la conversation, E ne sonne pas la clochette ; « Accepter » n'est pas sous « Suivant » (un double clic
-- n'accepte pas la commande)
M.services.UserInputService.InputBegan:Fire({ KeyCode = Enum.KeyCode.E, UserInputType = Enum.UserInputType.Keyboard }, false)
verifier(e.etape == "accueil" and conversation.Visible, "pendant la conversation, E ne sonne pas la clochette")
local suivantC, accepterC = conversation.SuivantConversation, conversation.AccepterCommande
verifier(accepterC.Position.X.Offset >= suivantC.Position.X.Offset + suivantC.Size.X.Offset, "« Accepter la commande » n'est pas sous « Suivant »")
verifier(conversation.Visible and conversation.Interlocutrice.Text == "Colette Marchand" and conversation.Replique.Text == def.repliques.demande, "une conversation : Colette dit pourquoi elle a besoin d'une robe")
cliquer("SuivantConversation")
verifier(conversation.Replique.Text == def.repliques.detail and boutonNomme("AccepterCommande") ~= nil, "« Suivant » : ce qu'elle voudrait ; puis « Accepter la commande »")
cliquer("AccepterCommande")
verifier(titre() == "Les mesures" and e.commande.histoire == "lanternes_colette" and e.commande.exigences[1].style == def.exigences[1].style, "la commande de l'événement commence, avec la tenue du tableau")
M.avancer(0.5)
verifier(scene.Cliente.Head.Bulle.Texte.Text == def.repliques.demande, "aux mesures, elle redit sa demande")
cliquer("ReprendreMesures")
verifier(scene.Cliente.Head.Bulle.Texte.Text == def.repliques.detail, "au carnet, ce qu'elle voudrait")
-- La robe menée jusqu'à la photo sur le serveur, sans repasser par tous les postes
e.commande.exigences = { { type = "qualite", valeur = 0.1 } }
e.croquis = { corsage = "corsage_droit", manches = "manches_sans", col = "col_sans", jupe = "jupe_droite" }
e.tissus = {}
for _, id in ipairs(e:piecesDuCroquis()) do
	e.tissus[id] = "coton_blanc"
	e.coupees[id] = { x = 0, y = 0, angle = 0 }
	e.epinglees[id] = true
	e.coutures[id] = 0.9
end
e.etape = "photo"
requireModule(scriptClient.Session).courante:actualiser()
local laColette = scene.Cliente
e.prestige = 259 -- (juste sous le prestige 6 : la livraison le fait passer, l'annonce s'allonge)
cliquer("Livrer")
cliquer("Livrer")
verifier(titre() == "Aiguille & Dentelle" and fenetre.Contenu.Epilogue.Visible and texte("Le bal des lanternes a eu lieu !") ~= nil and texte("Souvenir : Lanterne de papier") ~= nil, "la dernière robe livrée : le bal a lieu, épilogue et souvenir")
do -- Sous-projet 5 : l'épilogue est la une de la gazette du quartier
	local une = fenetre.Contenu.Epilogue
	local e1, e2 = Histoire.enColonnes(Histoire.get("lanternes").epilogue)
	verifier(une.UIStroke.ApplyStrokeMode == Enum.ApplyStrokeMode.Border and fenetre.Contenu.Affiche.UIStroke.ApplyStrokeMode == Enum.ApplyStrokeMode.Border, "le filet de la gazette et le cadre de l'affiche entourent le panneau (pas son texte vide)")
	do -- En bas de la une, les nouvelles de l'atelier : sa réputation et le rang de la couturière
		local P, etatNouvelles = requireModule(dossier.Progression), requireModule(scriptClient.Session).courante.etat
		local nouvelles = une:FindFirstChild("Nouvelles")
		verifier(nouvelles ~= nil and une:FindFirstChild("FiletBas") ~= nil and string.find(nouvelles.Text:lower(), P.titreReputation(P.niveauPrestige(etatNouvelles.prestige)):lower(), 1, true) ~= nil and string.find(nouvelles.Text, P.texteRang(etatNouvelles.livraisons + etatNouvelles.ventes), 1, true) ~= nil, "la une : un filet, puis les nouvelles de l'atelier (" .. tostring(nouvelles and nouvelles.Text) .. ")")
	end
	verifier(une.Journal.Text == Histoire.GAZETTE and string.match(une.Date.Text, "^N° 1 — Jour %d+ de l'atelier") ~= nil and une.Colonne1.Text == e1 and une.Colonne2.Text == e2 and une.Colonne2.Position.X.Scale == 0.5, "la une de la gazette : le journal, le numéro et le jour, l'épilogue en deux colonnes")
	verifier(laColette.Head.Bulle.Texte.Text == def.repliques.merci, "Colette raconte la suite")
	-- (le prestige 6 ouvre plus de huit nouveautés : huit cartes, et le reste en une ligne)
	local affiche, cartes = fenetre.Contenu.Affiche, 0
	for _, c in ipairs(affiche:GetChildren()) do
		cartes += if c.Name:match("^Nouveau_") then 1 else 0
	end
	local n = #requireModule(scriptClient.Session).courante.derniere.reponse.nouveaux
	verifier(affiche.Visible and n > 8 and cartes == 8 and affiche.EtEncore.Text == ("Et encore %d autres nouveautés."):format(n - 8), "sous la gazette, l'affiche : huit cartes, et « Et encore " .. (n - 8) .. " autres nouveautés. »")
end
verifierTailles("épilogue")
local inviter3 = boutonNomme("Inviter_3")
verifier(fenetre.Contenu.Courrier.Text == "Courrier (boîte pleine) :" and inviter3.Position.Y.Offset + inviter3.Size.Y.Offset <= 466, "boîte pleine : c'est dit, et les trois lettres tiennent dans la fenêtre")
do -- Le passage au prestige 6 allonge l'annonce (« Nouveau : » sur deux lignes) : sa hauteur compte les lignes
	-- repliées, et l'introduction reste dessous
	local annonce, intro = fenetre.Contenu.Annonce, fenetre.Contenu.Intro
	local taille, hauteur = requireModule(scriptClient.UiKit).mesureAnnonce(annonce.Text, fenetre.Size.X.Offset + fenetre.Contenu.Size.X.Offset)
	verifier(string.find(annonce.Text, "Nouveau : Manches courtes", 1, true) ~= nil and annonce.TextSize == taille and annonce.Size.Y.Offset == hauteur and intro.Position.Y.Offset >= hauteur + 10, "annonce longue (prestige 6) : sa hauteur compte les lignes repliées, l'introduction reste dessous")
end
e.prestige = 530 -- (tout reste ouvert pour la suite)
cliquer("FermerEpilogue")
boutonNomme("FermerSuite").Activated:Fire() -- second appui d'un double clic : il tombe sur le « Fermer » de dessous
local suite = fenetre.Contenu.Suite
verifier(suite.Visible and suite.Interlocutrice.Text == "Colette Marchand" and suite.Replique.Text == def.repliques.merci, "sous l'épilogue : la suite de l'histoire de Colette, lisible")
cliquer("FermerSuite")
verifier(fenetre.Contenu.Affiche.Visible, "sous la suite de l'histoire, l'affiche des nouveautés")
cliquer("FermerAffiche")
verifier(not fenetre.Contenu.Epilogue.Visible and texte("Événement : La kermesse du square — robes livrées 0 / 2") ~= nil, "l'événement suivant s'annonce")
cliquer("OuvrirCarnetAdresses")
verifier(texte("Le bal des lanternes — souvenir : Lanterne de papier") ~= nil, "le carnet d'adresses garde les souvenirs du quartier")
cliquer("FermerCarnetAdresses")
M.avancer(ScenePoste.DUREE_ADIEU + 0.5)
end
do -- Sous-projet 5 : le chat de l'atelier ; une caresse le fait ronronner, remuer la queue, et des cœurs montent
	local chat = maBoutique.Chat
	-- Fenêtre ouverte, pas d'invite « Caresser » (elle passerait dans la vue du poste et sur la photo)
	local invites = M.services.ProximityPromptService
	verifier(fenetre.Visible and invites.Enabled == false, "fenêtre ouverte : pas d'invite de proximité")
	cliquer("Fermer")
	verifier(invites.Enabled == true, "fenêtre fermée : l'invite du chat revient")
	cliquer("OuvrirAtelier")
	local queue = chat.Queue
	local repos = queue.CFrame
	M.services.ProximityPromptService.PromptTriggered:Fire(chat.Corps.Caresser, joueur)
	verifier(M.sonsJoues[#M.sonsJoues] == "Atelier_ronron" and chat.Tete:FindFirstChild("Coeurs") ~= nil, "caresser le chat : il ronronne, des cœurs montent")
	local coeur = chat.Tete.Coeurs:FindFirstChild("Coeur1")
	verifier(coeur ~= nil and coeur.Font == Enum.Font.GothamBold and coeur.TextTransparency == 1, "les cœurs, dans la police du jeu, invisibles avant de monter")
	M.avancer(0.2)
	verifier(queue.CFrame ~= repos, "il remue la queue")
	M.services.ProximityPromptService.PromptTriggered:Fire(chat.Corps.Caresser, joueur)
	local nCoeurs = 0
	for _, c in ipairs(chat.Tete:GetChildren()) do
		nCoeurs += if c.Name == "Coeurs" then 1 else 0
	end
	verifier(nCoeurs == 1, "une caresse à la fois")
	M.avancer(3)
	verifier(chat.Tete:FindFirstChild("Coeurs") == nil and queue.CFrame == repos, "puis il se rendort, la queue au repos")
end
-- La touche E sonne la clochette, fenêtre ouverte seulement (comme au comptoir)
local toucheE = { KeyCode = Enum.KeyCode.E, UserInputType = Enum.UserInputType.Keyboard }
cliquer("Fermer")
UIS.InputBegan:Fire(toucheE, false)
verifier(titre() == "Aiguille & Dentelle", "fenêtre fermée : E ne sonne pas")
cliquer("OuvrirAtelier")
UIS.InputBegan:Fire(toucheE, true)
verifier(titre() == "Aiguille & Dentelle", "E tapé dans le chat : rien")
M.avancer(0.5)
UIS.InputBegan:Fire(toucheE, false)
verifier(scene:FindFirstChild("Cliente") ~= nil and scene.Cliente ~= laCliente, "E : la cliente suivante entre")
verifier(titre() == "Les mesures" and texte("Margot Petit") ~= nil, "nouvelle cliente : Margot, à mesurer")
mesurerCliente()
cliquer("ValiderMesures")
verifier(titre() == "1. Carnet de croquis", "Margot mesurée : le carnet")

---------------------------------------------------------------------------
-- Robe en six tissus : la mise en page tient (lignes d'achat, onglets de la découpe)
---------------------------------------------------------------------------
for _, v in ipairs({ "corsage_v", "manches_ballon", "col_claudine", "jupe_trapeze" }) do
	choisirModele(v)
end
local SIX = {
	{ "corsage_v_devant", "coton_blanc" },
	{ "corsage_droit_dos", "coton_bleu_carreaux" },
	{ "manche_ballon", "coton_jaune_fleurs" },
	{ "col_claudine", "lin_naturel" },
	{ "jupe_trapeze_devant", "lin_vert_rayures" },
	{ "jupe_trapeze_dos", "lin_bleu" },
}
for _, c in ipairs(SIX) do
	cliquer("Tissu_" .. c[1])
	cliquer("Filtre_tous")
	cliquer("Tissu_" .. c[2])
end
do -- (sous-projet 6) Le coton blanc est entamé par une robe d'avant : ses 6 dm en stock, tous entamés (deux trous). Au
	-- carnet, le tissu à acheter ne compte que le tissu neuf
	local s = serveur:atelier(joueur).etat
	local function aAcheter()
		M.avancer(0.5)
		SessionModule.courante:actualiser()
		return tonumber(fenetre.Contenu.Droite.Metrage.Text:match("^Tissu à acheter : (%d+) dm"))
	end
	s.stock.coton_blanc, s.entames.coton_blanc = 6, nil
	local neuf = aAcheter()
	s.entames.coton_blanc = { bas = 6, trous = { { piece = "jupe_droite_devant", x = 2.5, y = 3, angle = 0 }, { piece = "corsage_droit_devant", x = 9.6, y = 2.1, angle = 0 } } }
	local entame = aAcheter()
	local conseilCoton = requireModule(dossier.Metrage).conseil({ "corsage_v_devant" })
	verifier(neuf ~= nil and entame == neuf + math.min(6, conseilCoton), ("au carnet, 6 dm de coton tout entamés ne comptent pas : %s dm à acheter au lieu de %s"):format(tostring(entame), tostring(neuf)))
	-- (relecture du plan 18) le lin bleu aussi est entamé : deux rouleaux entamés à la table
	s.entames.lin_bleu, s.stock.lin_bleu = { bas = 6, trous = { { piece = "jupe_droite_devant", x = 2.5, y = 3, angle = 0 } } }, 6
end
cliquer("Valider")
verifier(titre() == "2. Achat du tissu", "robe en six tissus : à l'achat")
do -- L'achat du coton blanc : le conseil ne compte que le tissu neuf
	local l = fenetre.Contenu.Lignes.Ligne_coton_blanc
	local conseilCoton = tonumber(l.Infos.Text:match("^Conseillé : (%d+) dm"))
	verifier(conseilCoton ~= nil and l.Infos.Text == ("Conseillé : %d dm · Neuf : 0 dm (6 entamés)"):format(conseilCoton) and l.Quantite.Text == conseilCoton .. " dm", "coton blanc tout entamé : la quantité proposée est le conseil entier (" .. l.Infos.Text .. ")")
	verifier(l.Infos.Size.X.Offset >= 336 and l.Infos.Size.Y.Offset >= 34 and l.Infos.Position.Y.Offset + l.Infos.Size.Y.Offset <= l.Size.Y.Offset and l.Infos.Position.X.Offset + l.Infos.Size.X.Offset <= l.Moins.Position.X.Offset, "l'information du tissu a la place de deux lignes, dans la ligne d'achat, avant « − »")
end
local lignesAchat = fenetre.Contenu:FindFirstChild("Lignes")
verifier(lignesAchat ~= nil and lignesAchat:IsA("ScrollingFrame"), "les lignes d'achat sont dans une liste qui défile")
local nbLignes, finLignes = 0, 0
for _, l in ipairs(lignesAchat:GetChildren()) do
	if l.Name:sub(1, 6) == "Ligne_" then
		nbLignes += 1
		finLignes = math.max(finLignes, l.Position.Y.Offset + l.Size.Y.Offset)
	end
end
verifier(nbLignes == 6 and lignesAchat.CanvasSize.Y.Offset >= finLignes, "six lignes, toutes atteignables en faisant défiler")
verifier(lignesAchat.Size.Y.Scale == 1 and lignesAchat.Position.Y.Offset + lignesAchat.Size.Y.Offset <= -fenetre.Contenu.AllerDecoupe.Size.Y.Offset, "la liste s'arrête au-dessus des boutons du bas")
for _, c in ipairs(SIX) do
	M.avancer(0.5)
	lignesAchat["Ligne_" .. c[2]].Acheter.Activated:Fire()
end
cliquer("AllerDecoupe")
verifier(titre() == "3. Table de découpe", "robe en six tissus : à la découpe")
local ongletsDecoupe = fenetre.Contenu.Panneau.Onglets
verifier(ongletsDecoupe:IsA("ScrollingFrame"), "les onglets des tissus défilent")
local nbOnglets, finOnglets = 0, 0
for _, o in ipairs(ongletsDecoupe:GetChildren()) do
	if o.Name:sub(1, 7) == "Onglet_" then
		nbOnglets += 1
		finOnglets = math.max(finOnglets, o.Position.X.Offset + o.Size.X.Offset)
	end
end
verifier(nbOnglets == 6 and ongletsDecoupe.CanvasSize.X.Offset >= finOnglets, "six onglets, tous atteignables")
do -- (sous-projet 6) Le rouleau de coton blanc entamé : ses trous sont dessinés, « Proposer » les évite
	cliquer("Onglet_coton_blanc")
	local trousVus = 0
	for _, d in ipairs(fenetre.Contenu.Rouleau.Tissu.Coupees:GetChildren()) do
		trousVus += if d.Name:match("^Trou_") then 1 else 0
	end
	local c = SessionModule.courante.etat.coupons.coton_blanc
	cliquer("Proposer")
	verifier(trousVus == 2 and fenetre.Contenu.Panneau.Statut.Text == "Place libre : tu peux couper." and fenetre.Contenu.Panneau.InfoRouleau.Text == ("0,60 m entamés / %s m\nCette robe : +0,00 m (0 po)"):format(requireModule(scriptClient.Mercerie).metres(c.longueur * 10)), "coton blanc entamé : deux trous dessinés, « Proposer » trouve une place libre, 6 dm entamés (" .. fenetre.Contenu.Panneau.Statut.Text .. ")")
	-- Une bande jetée d'elle-même (plus de 24 trous) est annoncée
	SessionModule.courante.annonce("couper", { ok = true, jetees = { { tissu = "coton_blanc", dm = 13 } } })
	verifier(fenetre.Message.Visible and fenetre.Message.Text == "Trop de trous : la bande entamée est jetée (Coton blanc, 1,30 m).", "une bande jetée d'elle-même est annoncée")
end
do -- (sous-projet 6) « Jeter la bande » : au deuxième appui, la bande de coton quitte le stock, le rouleau repart neuf
	local s = serveur:atelier(joueur).etat
	local avant = s.stock.coton_blanc
	verifier(boutonNomme("JeterEntame").Visible and boutonNomme("JeterEntame").Position.X.Scale == 1, "coton blanc entamé, rien de coupé : « Jeter la bande », en bas à droite")
	-- (relecture) Une confirmation armée sur un onglet ne passe pas à un autre : changer d'onglet la désarme
	cliquer("JeterEntame")
	cliquer("Onglet_lin_bleu")
	verifier(boutonNomme("JeterEntame").Text == "Jeter la bande", "changer d'onglet désarme « Jeter la bande »")
	cliquer("JeterEntame")
	verifier(s.entames.lin_bleu ~= nil and s.entames.coton_blanc ~= nil, "un seul appui après le changement d'onglet : aucune bande jetée")
	cliquer("Onglet_coton_blanc")
	cliquer("JeterEntame")
	verifier(s.entames.coton_blanc ~= nil and boutonNomme("JeterEntame").Text == "Vraiment ? Touche encore", "premier appui : on demande de confirmer")
	cliquer("JeterEntame")
	local trous = 0
	for _, d in ipairs(fenetre.Contenu.Rouleau.Tissu.Coupees:GetChildren()) do
		trous += if d.Name:match("^Trou_") then 1 else 0
	end
	verifier(s.entames.coton_blanc == nil and s.stock.coton_blanc == avant - 6 and not fenetre.Contenu.Panneau.JeterEntame.Visible and fenetre.Message.Text == "Bande entamée jetée : 0,60 m de Coton blanc.", "second appui : la bande (0,60 m) quitte le stock, le bouton s'en va (" .. fenetre.Message.Text .. ")")
	verifier(trous == 0 and string.find(fenetre.Contenu.Panneau.InfoRouleau.Text, "0,00 m entamés", 1, true) == 1 and fenetre.Contenu.Panneau.Statut.Text == "Place libre : tu peux couper.", "le rouleau repart neuf : plus de trous, une place libre proposée")
	verifier(fenetre.Contenu.Rouleau.Tissu.PieceCourante.Position.Y.Offset < 6 * 36, "la pièce remonte en haut du rouleau neuf (" .. fenetre.Contenu.Rouleau.Tissu.PieceCourante.Position.Y.Offset .. " px)")
	-- (relecture) Une pièce coupée dans le lin bleu entamé : plus de « Jeter la bande » pour ce tissu
	cliquer("Onglet_lin_bleu")
	verifier(boutonNomme("JeterEntame").Visible, "lin bleu entamé, rien de coupé : « Jeter la bande »")
	cliquer("Proposer")
	cliquer("Couper")
	cliquer("Onglet_lin_bleu")
	verifier(s.coupees.jupe_trapeze_dos ~= nil and s.entames.lin_bleu ~= nil and not fenetre.Contenu.Panneau.JeterEntame.Visible, "une pièce coupée dans le lin bleu : plus de « Jeter la bande » pour lui")
end
verifierTailles("découpe à six tissus")

---------------------------------------------------------------------------
-- Triche : appels directs au serveur ; le client n'a qu'une copie de l'état
---------------------------------------------------------------------------
local remoteAtelier = RS.Atelier
local etatServeur = serveur:atelier(joueur).etat
local argentServeur, stockServeur = etatServeur.argent, table.clone(etatServeur.stock)
M.avancer(1)
local rt = remoteAtelier:InvokeServer("voler", 1000)
verifier(not rt.ok and rt.erreur == "Action inconnue.", "triche : action inconnue refusée")
M.avancer(0.5)
rt = remoteAtelier:InvokeServer("livrer")
verifier(not rt.ok and rt.erreur == "Ce n'est pas le moment de livrer.", "triche : action dans le désordre refusée")
M.avancer(0.5)
rt = remoteAtelier:InvokeServer("couper", "jupe_trapeze_devant", { x = 50, y = 2, angle = 0 })
verifier(not rt.ok and rt.erreur == "La pièce dépasse du tissu.", "triche : découpe hors du rouleau refusée")
M.avancer(1.1)
local refuses = 0
for _ = 1, 8 do
	if remoteAtelier:InvokeServer("etat").erreur == "Doucement !" then
		refuses += 1
	end
end
verifier(refuses == 8 - serveur.APPELS_PAR_SECONDE, "triche : rafale d'appels, les appels de trop refusés")
etatJeu.argent = 1000000 -- le client modifie sa copie
M.avancer(1.1)
rt = remoteAtelier:InvokeServer("acheter", "soie_rouge", 100)
verifier(etatServeur.argent == argentServeur - (rt.ok and rt.prix or 0) and (rt.ok or rt.erreur == "Pas assez d'argent."), "triche : l'argent de la copie du client ne compte pas")
etatServeur.argent, etatServeur.stock = argentServeur, stockServeur
M.avancer(1.1)
SessionModule.courante:actualiser()
verifier(etatJeu.argent == argentServeur and titre() == "3. Table de découpe", "la copie du client revient à l'état du serveur")

---------------------------------------------------------------------------
-- Sauvegarde : la partie illisible n'est jamais écrite ; au retour, la partie est lue, puis écrite
-- régulièrement, au départ et à l'arrêt du serveur, et la commande reprend au retour suivant
---------------------------------------------------------------------------
local robeLivree = serveur:atelier(joueur).etat.robes[1]
M.avancer(serveur.PERIODE_SAUVEGARDE + 1)
M.services.Players.PlayerRemoving:Fire(joueur)
verifier(parties.donnees[cleJoueur].version == 99 and parties.donnees[cleJoueur].argent == 5000 and serveur.ateliers[joueur] == nil, "partie illisible : jamais écrite, ni régulièrement ni au départ")
-- La mise à jour arrive : la partie devient lisible
parties.donnees[cleJoueur] = { version = 2, argent = 5000, stock = {}, debloques = {}, recettes = { robeLivree } }
M.services.Players.PlayerAdded:Fire(joueur)
verifier(parties.donnees[cleJoueur].verrou.jobId == "serveur-scenario" and serveur:atelier(joueur).etat.argent == 5000, "retour du joueur : partie lue, verrou pris")
M.avancer(0.5)
verifier(serveur:traiter(joueur, "nouvelleCommande").ok, "une commande commencée sur le serveur")
M.avancer(serveur.PERIODE_SAUVEGARDE + 1)
verifier(parties.donnees[cleJoueur].enCours ~= nil and parties.donnees[cleJoueur].enCours.etape == "mesures", "sauvegarde régulière : la commande en cours")
-- (au moment où l'écriture de sa partie commence, sa boutique est déjà libérée : un joueur qui arrive
-- pendant une écriture lente trouve une place)
local boutiqueAuDepart = nil
serveur.depart = function(self, j)
	boutiqueAuDepart = M.services.Workspace.Rue:FindFirstChild("Boutique_1") ~= nil
	return getmetatable(self).depart(self, j)
end
M.services.Players.PlayerRemoving:Fire(joueur)
serveur.depart = nil
verifier(boutiqueAuDepart == false, "départ du joueur : sa boutique est libérée avant l'écriture de sa partie")
verifier(parties.donnees[cleJoueur].verrou.t == 0 and serveur.ateliers[joueur] == nil, "départ du joueur : partie écrite, verrou rendu")
verifier(M.services.Workspace.Rue:FindFirstChild("Boutique_1") == nil and M.services.Workspace.Vitrines:FindFirstChild("Vitrine_1") == nil, "départ du joueur : sa boutique est retirée de la rue")
M.services.Players.PlayerAdded:Fire(joueur)
verifier(serveur:atelier(joueur) ~= nil and serveur:atelier(joueur).etat.etape == "mesures", "retour suivant : la commande reprend")
verifier(M.services.Workspace.Rue:FindFirstChild("Boutique_1") ~= nil and M.services.Workspace.Vitrines.Vitrine_1:GetAttribute("Recette") ~= nil, "retour : sa boutique est reconstruite, sa dernière robe en vitrine")
M.fermeture()
verifier(parties.donnees[cleJoueur].verrou.t == 0 and parties.donnees[cleJoueur].enCours.etape == "mesures", "arrêt du serveur : partie écrite, verrou rendu")

print(("TOUT EST VERT : %d vérifications"):format(nbVerifs))
