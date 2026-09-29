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
local function verifierTailles(ecran)
	local petits = {}
	for _, d in ipairs(gui:GetDescendants()) do
		if (d:IsA("TextLabel") or d:IsA("TextButton")) and estVisible(d) and d.Text ~= "" and d.TextSize < 14 then
			table.insert(petits, d.Name .. "=" .. d.TextSize)
		end
	end
	verifier(#petits == 0, ecran .. " : textes d'au moins 14 px ; trop petits : " .. table.concat(petits, ", "))
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
verifier(titre() == "Atelier de couture", "écran d'accueil")
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
remoteAtelier.OnServerInvoke = serveurLent
cliquer("Clochette")
remoteAtelier.OnServerInvoke = brancheServeur
verifier(M.dernierAppel ~= nil and M.dernierAppel.action == "nouvelleCommande" and serveur:atelier(joueur).etat.etape == "mesures", "la commande passe par le serveur, qui fait foi")
verifier(pendantAttente ~= nil and pendantAttente.visible and string.find(pendantAttente.texte, "sauvegardée", 1, true) ~= nil, "serveur lent : l'avertissement affiché n'est pas remplacé")
verifier(sonsDepuis(nSons) == "Atelier_clic,Atelier_clochette", "sons : le clic du bouton, puis la clochette (" .. sonsDepuis(nSons) .. ")")

---------------------------------------------------------------------------
-- Les mesures : Colette vient pour la première fois ; les rubans partent courts, on les règle au bord de sa
-- silhouette (boutons − et +, au 0,1 dm près)
---------------------------------------------------------------------------
local Clientes = requireModule(dossier.Clientes)
local MESURES = { "poitrine", "taille", "hanches" }
verifier(titre() == "Les mesures" and texte("Colette Marchand") ~= nil, "première visite de Colette : ses mesures")
verifier(fenetre.Contenu:FindFirstChild("ReprendreMesures") == nil, "première visite : rien à reprendre")
verifierTailles("mesures")
cliquer("ValiderMesures")
verifier(titre() == "Les mesures" and fenetre.Message.Visible and fenetre.Message.Text == "Mesure invalide : règle chaque ruban au bord de la silhouette.", "rubans pas réglés : mesures refusées, message")
-- Au doigt : on glisse la poignée du ruban de la poitrine jusqu'au bord de la silhouette ; un second doigt ne
-- tire pas le ruban, et le doigt levé ne le tire plus
local silhouetteM = fenetre.Contenu.Silhouette
local justePoitrine = ("Poitrine : %d cm"):format(math.round(Clientes.get("colette").mesures.poitrine * 10))
local doigtRuban = { UserInputType = Enum.UserInputType.Touch, Position = Vector3.new(0, 0, 0) }
silhouetteM.Poignee_poitrine.InputBegan:Fire(doigtRuban)
local valeurAvant = texte("Valeur_poitrine").Text
M.services.UserInputService.InputChanged:Fire({ UserInputType = Enum.UserInputType.Touch, Position = Vector3.new(900, 0, 0) })
verifier(texte("Valeur_poitrine").Text == valeurAvant, "un second doigt ne tire pas le ruban")
doigtRuban.Position = Vector3.new(silhouetteM.Ruban_poitrine.AbsolutePosition.X + silhouetteM.Corps_poitrine.Size.X.Offset, 0, 0)
M.services.UserInputService.InputChanged:Fire(doigtRuban)
M.services.UserInputService.InputEnded:Fire(doigtRuban)
verifier(texte("Valeur_poitrine").Text == justePoitrine, "glisser la poignée au doigt jusqu'au bord de la silhouette : la mesure juste")
doigtRuban.Position = Vector3.new(0, 0, 0)
M.services.UserInputService.InputChanged:Fire(doigtRuban)
verifier(texte("Valeur_poitrine").Text == justePoitrine, "doigt levé : le ruban ne bouge plus")
local function mesurerCliente()
	local vraies = Clientes.get(serveur:atelier(joueur).etat.commande.cliente).mesures
	for _, cle in ipairs(MESURES) do
		local function lue()
			return tonumber(texte("Valeur_" .. cle).Text:match("(%d+) cm")) / 10
		end
		local garde = 0
		while math.abs(lue() - vraies[cle]) > 0.05 and garde < 80 do
			garde += 1
			cliquer(if lue() < vraies[cle] then "Plus_" .. cle else "Moins_" .. cle)
		end
	end
end
mesurerCliente()
local silhouette = fenetre.Contenu.Silhouette
for _, cle in ipairs(MESURES) do
	local ruban, corps = silhouette["Ruban_" .. cle], silhouette["Corps_" .. cle]
	local finRuban = ruban.Position.X.Offset + ruban.Size.X.Offset
	local bordCorps = corps.Position.X.Offset + corps.Size.X.Offset
	verifier(math.abs(finRuban - bordCorps) <= 2 and ruban.Position.X.Offset == corps.Position.X.Offset, cle .. " : réglé juste, le ruban s'arrête au bord de la silhouette")
end
cliquer("ValiderMesures")
verifier(serveur:atelier(joueur).etat.commande.ajustement == 1 and serveur:atelier(joueur).etat.clientes.colette.mesures ~= nil, "mesures justes : ajustement 100 %, gardées pour la prochaine fois")

---------------------------------------------------------------------------
-- Carnet de croquis
---------------------------------------------------------------------------
verifier(titre() == "1. Carnet de croquis", "mesures prises : le carnet")
verifierTailles("carnet")
verifier(texte("La cliente (taille") ~= nil, "la taille de la cliente est affichée")
verifier(texte("Exigence1") ~= nil and texte("Exigence1").Text ~= "", "les exigences sont affichées")
local ligneMetrage = fenetre.Contenu.Droite:FindFirstChild("Metrage")
verifier(ligneMetrage ~= nil and string.find(ligneMetrage.Text, "Choisis les tissus", 1, true) == 1, "sans tissu : le métrage attend les tissus, dans la colonne de droite")
local derniereJauge = fenetre.Contenu.Droite["Jauge_" .. Catalogue.STYLES[#Catalogue.STYLES]]
local hauteurDroite = fenetre.Size.Y.Offset + fenetre.Contenu.Size.Y.Offset + fenetre.Contenu.Droite.Size.Y.Offset -- (tailles relatives)
verifier(ligneMetrage.AnchorPoint.Y == 1 and ligneMetrage.Position.Y.Scale == 1 and derniereJauge.Position.Y.Offset + derniereJauge.Size.Y.Offset < hauteurDroite + ligneMetrage.Position.Y.Offset - ligneMetrage.Size.Y.Offset, "la ligne du métrage est en bas de la colonne, sous les jauges, loin des boutons du carnet")
-- Robe : décolleté en V, manches ballon, col Claudine, jupe trapèze
for _, v in ipairs({ "corsage_v", "manches_ballon", "col_claudine", "jupe_trapeze" }) do
	cliquer("Variante_" .. v)
	verifier(boutonNomme("Variante_" .. v).BackgroundColor3 == Color3.fromRGB(214, 76, 128), v .. " en surbrillance")
end
local pieces = fenetre.Contenu.Gauche.Pieces
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
local pastille = pieces:FindFirstChild("Pastille")
verifier(pastille:IsA("ImageLabel") and pastille.ImageContent.statique == true, "la pastille de la pièce montre le motif du tissu")
cliquer("ToutEnUnTissu")
local nbSoie = 0
for _, d in ipairs(pieces:GetChildren()) do
	if d:IsA("TextLabel") and d.Text == "Soie rose fleurie" then
		nbSoie += 1
	end
end
verifier(nbSoie == 6, "toute la robe en soie rose fleurie")
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
cliquer("Variante_jupe_trapeze") -- même croquis : le carnet se redessine
verifier(ligneMetrage.Text == ("Tissu à acheter : %d dm, %d po — il te manque 10 po."):format(dmRobe, prixRobe) and ligneMetrage.TextColor3 == requireModule(scriptClient.UiKit).COULEURS.erreur, "pas assez d'argent : ce qui manque, en rouge")
etatCarnet.argent = argentVrai
cliquer("Variante_jupe_trapeze")
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
verifier(string.find(panneau.InfoRouleau.Text, "Entamé : 0 / ", 1, true) == 1 and not rouleau.Tissu.Entame.Visible, "rien de coupé : rouleau intact")
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
				verifier(c:longueurUtilisee() > 0 and panneau.InfoRouleau.Text == ("Entamé : %d / %d dm"):format(c:longueurUtilisee(), c.longueur), "une pièce coupée : le tissu entamé s'affiche")
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
for k = 3, 6 do
	coudre(30)
	verifier(boutonNomme("PieceSuivante").Text == (k == 6 and "Finir la couture" or "Pièce suivante"), "bouton de fin de pièce " .. k)
	cliquer("PieceSuivante")
end

---------------------------------------------------------------------------
-- Décorations
---------------------------------------------------------------------------
verifier(ratee ~= nil and ratee < 20, "la couture ratée est mal notée : " .. tostring(ratee))
verifier(titre() == "6. Décorations", "robe cousue : les décorations")
verifier(fenetre.AnchorPoint.X == 1 and #robe:GetChildren() == 8, "panneau à droite, la robe cousue sur le mannequin")
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
-- la robe, et sur la copie du client, qui affiche la commande)
local function exigencesTest()
	return { { type = "accessoire", id = "croix_argent" }, { type = "min", style = "romantique", valeur = 1 } }
end
serveur:atelier(joueur).etat.commande.exigences = exigencesTest()
etatJeu.commande.exigences = exigencesTest()
-- La palette ne montre que des rangées entières (une rangée coupée attirerait les clics à côté)
local palette = contenuD.Palette
verifier(palette.Size.Y.Offset % 44 == 0, "palette : rangées entières")
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
verifier(contenuD.Cout.Text == "Coût : 0 po", "rien posé : rien à payer")
toucherRobe("Piece_corsage_v_devant_unique", "corsage_v_devant", "unique", 0.5, 0.4)
verifier(#decorations:GetChildren() == 0 and fenetre.Message.Visible, "toucher la robe sans décoration choisie : un message")
cliquer("Deco_noeud_satin")
verifier(boutonNomme("Deco_noeud_satin").BackgroundColor3 == ACCENT, "nœud de satin choisi dans la palette")
toucherRobe("Piece_corsage_v_devant_unique", "corsage_v_devant", "unique", 0.5, 0.4)
verifier(#decorations:GetChildren() == 1 and contenuD.Cout.Text == "Coût : 3 po", "nœud posé sur le corsage : 3 po")
verifier(M.sonsJoues[#M.sonsJoues] == "Atelier_decoration", "une décoration posée fait son petit bruit")
local noeud = decorations:GetChildren()[1]
verifier((centre(noeud) - point3D("corsage_v_devant", "unique", 0.5, 0.4)).Magnitude < 0.3, "le nœud est là où l'on a touché")
local tailleAvant = noeud:GetChildren()[1].Size
cliquer("Agrandir")
verifier(decorations:GetChildren()[1]:GetChildren()[1].Size.X > tailleAvant.X, "le nœud sélectionné grandit")
cliquer("Tourner15")
verifier(contenuD.Cout.Text == "Coût : 3 po", "tourner ou agrandir ne coûte rien")
-- Garniture point par point
cliquer("Deco_ruban_rose")
toucherRobe("Piece_jupe_trapeze_devant_unique", "jupe_trapeze_devant", "unique", 0.1, 0.9)
toucherRobe("Piece_jupe_trapeze_devant_unique", "jupe_trapeze_devant", "unique", 0.9, 0.9)
verifier(boutonNomme("FinirGarniture").Visible, "garniture en cours : bouton pour la finir")
cliquer("FinirGarniture")
local coutRuban = tonumber(contenuD.Cout.Text:match("(%d+) po"))
verifier(#decorations:GetChildren() == 2 and coutRuban and coutRuban > 3, "ruban posé le long de la jupe : " .. contenuD.Cout.Text)
-- Toucher une décoration la sélectionne ; supprimer, puis annuler
local partNoeud = decorations:GetChildren()[1]:GetChildren()[1]
toucherScene({ Instance = partNoeud, Position = partNoeud.CFrame.Position, Normal = Vector3.new(0, 0, -1) })
verifier(decorations:GetChildren()[1]:FindFirstChild("Selection") ~= nil and decorations:GetChildren()[2]:FindFirstChild("Selection") == nil, "le nœud touché est surligné : on voit ce que « Supprimer » va retirer")
cliquer("Supprimer")
verifier(#decorations:GetChildren() == 1 and contenuD.Cout.Text == ("Coût : %d po"):format(coutRuban - 3), "nœud touché puis supprimé")
cliquer("Annuler")
verifier(#decorations:GetChildren() == 2 and contenuD.Cout.Text == ("Coût : %d po"):format(coutRuban), "annuler : le nœud revient")
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
verifier(titre() == "7. Photo et livraison" and argent() == avantDeco - coutRuban, "présenter : décorations payées")
verifier(camera.CFrame == origineBoutique * ScenePoste.CAMERA, "la cliente voit la robe de face")
verifier(texte("Au moins 1 en Romantique (actuel :") ~= nil, "le score actuel est affiché à côté d'une exigence de style")
verifier(#decorations:GetChildren() == 2, "la robe est présentée avec ses décorations")
verifierTailles("présentation")
-- La cliente en personne regarde la robe
local laCliente = scene:FindFirstChild("Cliente")
verifier(laCliente ~= nil and laCliente.Head.Bulle.Texte.Text == ScenePoste.PAROLES.photo, "la cliente est là et regarde la robe")
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
verifier(gui.Atelier.Enabled and camera.CFrame == origineBoutique * ScenePoste.CAMERA and laCliente.Head.Bulle.Enabled and camera.FieldOfView == 70, "après la photo : interface, vue, champ et bulle rétablis")
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
verifier(titre() == "6. Décorations" and #decorations:GetChildren() == 2 and contenuD.Cout.Text == "Coût : 0 po", "retour aux décorations : déjà payées")
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
verifier(M.sonsJoues[#M.sonsJoues] == "Atelier_echec", "robe refusée : un son déçu")
verifierTailles("refus")
cliquer("Retoucher")
verifier(titre() == "6. Décorations", "retouche : retour aux décorations")
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
cliquer("Livrer")
cliquer("Livrer")
verifier(titre() == "Atelier de couture" and argent() > avantLivraison, "robe acceptée : payée")
verifier(M.sonsJoues[#M.sonsJoues] == "Atelier_reussite", "robe acceptée : une petite fanfare")
verifier(texte("La cliente est ravie") ~= nil, "l'accueil annonce la paie")
verifier(imageAvant ~= nil and Vignettes.piece(idVignette, tissuVignette, placeVignette, 256) ~= imageAvant, "commande finie : les images des pièces découpées sont oubliées (mémoire)")
M.avancer(1)
verifier(maVitrine:FindFirstChild("Exposition") ~= nil, "le client construit la robe exposée dans la vitrine de la rue")
verifier(maVitrine:GetAttribute("Recette") == requireModule(dossier.Recette).encoder(serveur:atelier(joueur).etat.robes[1]), "la robe livrée part dans la vitrine de la boutique, sur la rue")
verifier(#robe:GetChildren() == 0 and #decorations:GetChildren() == 0 and camera.CameraType == Enum.CameraType.Custom, "atelier libéré, caméra rendue au joueur")
verifier(laCliente.Parent ~= nil and laCliente.Head.Bulle.Texte.Text == ScenePoste.PAROLES.merci, "la cliente remercie")
M.avancer(ScenePoste.DUREE_ADIEU + 0.5)
verifier(laCliente.Parent == nil, "puis elle s'en va")
-- La touche E sonne la clochette, fenêtre ouverte seulement (comme au comptoir)
local toucheE = { KeyCode = Enum.KeyCode.E, UserInputType = Enum.UserInputType.Keyboard }
cliquer("Fermer")
UIS.InputBegan:Fire(toucheE, false)
verifier(titre() == "Atelier de couture", "fenêtre fermée : E ne sonne pas")
cliquer("OuvrirAtelier")
UIS.InputBegan:Fire(toucheE, true)
verifier(titre() == "Atelier de couture", "E tapé dans le chat : rien")
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
	cliquer("Variante_" .. v)
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
cliquer("Valider")
verifier(titre() == "2. Achat du tissu", "robe en six tissus : à l'achat")
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
