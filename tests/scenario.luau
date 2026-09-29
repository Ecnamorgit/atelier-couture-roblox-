-- Scénario du nouvel atelier : une commande jouée de bout en bout en cliquant dans l'interface
-- (accueil → carnet → achat → découpe → écran de suite), comme le ferait un joueur.
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
verifierTailles("accueil")
cliquer("Fermer")
verifier(not fenetre.Visible, "la croix ferme la fenêtre")
cliquer("OuvrirAtelier")
verifier(fenetre.Visible, "le bouton Atelier rouvre la fenêtre")
cliquer("Clochette")

---------------------------------------------------------------------------
-- Carnet de croquis
---------------------------------------------------------------------------
verifier(titre() == "1. Carnet de croquis", "la clochette ouvre le carnet")
verifierTailles("carnet")
verifier(texte("La cliente (taille") ~= nil, "la taille de la cliente est affichée")
verifier(texte("Exigence1") ~= nil and texte("Exigence1").Text ~= "", "les exigences sont affichées")
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
cliquer("Valider")
verifier(titre() == "1. Carnet de croquis" and fenetre.Message.Visible, "valider sans tissu : message d'erreur")

-- Choix d'un tissu : filtre « Romantique », soie rose fleurie pour le corsage, puis pour toute la robe
local jaugeAvant = fenetre.Contenu.Droite.Jauge_romantique.Acquis.Size
cliquer("Tissu_corsage_v_devant")
verifier(fenetre.Contenu:FindFirstChild("ChoixTissu") ~= nil, "le choix du tissu s'ouvre")
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
cliquer("Plus")
verifier(tonumber(ligne.Quantite.Text:match("^(%d+)")) == quantite + 1, "le bouton + ajoute 1 dm")
cliquer("Moins")
cliquer("AllerDecoupe")
verifier(titre() == "2. Achat du tissu" and fenetre.Message.Visible, "découpe refusée sans tissu")
local avant = argent()
M.budget.images = 0 -- mémoire des images pleine en arrivant à la découpe (silhouettes impossibles)
cliquer("Acheter")
verifier(argent() < avant, "l'achat débite l'argent")
verifier(texte("En stock : " .. quantite .. " dm") ~= nil, "le stock est mis à jour")
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
		end
		if titre() == "3. Table de découpe" then
			verifier(#fenetre.Contenu.Rouleau.Tissu.Coupees:GetChildren() >= 1, "les pièces coupées restent visibles")
			verifier(panneau.Statut.Text ~= "Cette pièce est déjà coupée.", "après une coupe, la pièce suivante est affichée")
		end
	end
end
verifier(coupes == 6, "6 pièces coupées (manche et col pliés comptent pour une coupe chacun) : " .. coupes)

---------------------------------------------------------------------------
-- Suite et recommencer
---------------------------------------------------------------------------
verifier(titre() == "Toutes les pièces sont coupées !", "écran de suite après la dernière coupe")
verifierTailles("suite")
cliquer("Recommencer")
verifier(titre() == "1. Carnet de croquis", "recommencer ramène au carnet avec la même commande")

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

print(("TOUT EST VERT : %d vérifications"):format(nbVerifs))
