-- Catalogue : données du jeu (pièces de patron, variantes, tissus, accessoires, constantes).
-- Données seulement : aucune logique ici. Longueurs en décimètres (dm).
local Catalogue = {}

---------------------------------------------------------------------------
-- Constantes
---------------------------------------------------------------------------
Catalogue.LARGEUR_ROULEAU = 14 -- 140 cm
Catalogue.PLI = 7 -- pli au milieu du rouleau pour les pièces coupées pliées
Catalogue.PX_PAR_DM = 32
Catalogue.TAILLE_MOTIF = 256 -- pixels, soit 8 dm de tissu
Catalogue.VALEUR_COUTURE = 0.15 -- décalage du trajet de couture vers l'intérieur
Catalogue.PAS_MESURE_COUTURE = 0.1 -- une mesure d'écart tous les 0,1 dm de trajet
Catalogue.K = { pieces = 1, tissu = 2, accessoires = 0.5 } -- poids des jauges de style
Catalogue.PLAFOND_ASSISTANCE = 0.85
Catalogue.VITESSE_COUTURE_MAX = 1.5 -- dm de trajet par seconde (vitesse « lapin »)
Catalogue.ECART_MAX_COUTURE = 2 -- dm : l'aiguille ne s'écarte jamais plus du pointillé
Catalogue.STUDS_PAR_DM = 0.3 -- échelle du rendu 3D : 1 dm de patron = 0,3 stud

Catalogue.STYLES = { "elegant", "mignon", "romantique", "gothique", "chic", "decontracte" }
Catalogue.NOMS_STYLES = {
	elegant = "Élégant",
	mignon = "Mignon",
	romantique = "Romantique",
	gothique = "Gothique",
	chic = "Chic",
	decontracte = "Décontracté",
}
Catalogue.TEINTES = { "rose", "rouge", "bleu", "vert", "jaune", "violet", "noir", "blanc", "brun" }
-- Sous-projet 7 : trois occasions (points des variantes et des matières, comme les styles) et sept traits calculés
-- d'après la robe (voir Etiquettes)
Catalogue.OCCASIONS = { "journee", "soiree", "travail" }
Catalogue.NOMS_OCCASIONS = { journee = "Journée", soiree = "Soirée", travail = "Travail" }
Catalogue.TRAITS = { "legere", "chaude", "sobre", "travaillee", "unie", "fleurie", "a_motifs" }
Catalogue.NOMS_TRAITS = {
	legere = "Légère",
	chaude = "Chaude",
	sobre = "Sobre",
	travaillee = "Travaillée",
	unie = "Unie",
	fleurie = "Fleurie",
	a_motifs = "À motifs",
}

-- Mensurations (tours en dm) des tailles proposées par les clientes anonymes
Catalogue.TAILLES = {
	S = { poitrine = 8.2, taille = 6.4, hanches = 8.8 },
	M = { poitrine = 8.8, taille = 7.0, hanches = 9.4 },
	L = { poitrine = 9.6, taille = 7.8, hanches = 10.2 },
}

Catalogue.FAMILLES = { "corsage", "manches", "col", "jupe" }

---------------------------------------------------------------------------
-- Pièces de patron
-- contour : polygone (dm), y = 0 en haut de la pièce telle que dessinée
-- coutures : indices des arêtes à coudre (arête i = point i → point i+1)
-- enroulement : comment la pièce entoure le corps (voir Patron)
-- pliee : coupée dans le tissu plié → deux copies miroir (gauche, droite)
-- biais : prévue pour être coupée à 45°
-- Sous-projet 7 : poids (dans la paie, 1 par défaut ; 0,5 pour une petite pièce ajoutée : volant, basque), grille
-- (quadrillage propre à la pièce, par finesse : voir Maillage)
---------------------------------------------------------------------------
local function rectangle(l, h)
	return { { x = 0, y = 0 }, { x = l, y = 0 }, { x = l, y = h }, { x = 0, y = h } }
end

local CORSAGE_V = {
	{ x = 0, y = 0 }, { x = 1.3, y = 0 }, { x = 2.4, y = 2.0 }, { x = 3.5, y = 0 },
	{ x = 4.8, y = 0 }, { x = 4.8, y = 4.2 }, { x = 0, y = 4.2 },
}
local CORSAGE_BRETELLES = {
	{ x = 0.6, y = 0 }, { x = 1.4, y = 0 }, { x = 1.6, y = 1.6 }, { x = 3.2, y = 1.6 }, { x = 3.4, y = 0 },
	{ x = 4.2, y = 0 }, { x = 4.8, y = 1.8 }, { x = 4.8, y = 4.2 }, { x = 0, y = 4.2 }, { x = 0, y = 1.8 },
}
local TRAPEZE = { { x = 1, y = 0 }, { x = 5, y = 0 }, { x = 6, y = 6 }, { x = 0, y = 6 } }
local EVASEE = { { x = 2.4, y = 0 }, { x = 6.4, y = 0 }, { x = 8.8, y = 9 }, { x = 0, y = 9 } }
local MANCHE_BALLON = {
	{ x = 0, y = 0.6 }, { x = 0.8, y = 0.1 }, { x = 1.6, y = 0 }, { x = 2.4, y = 0.1 },
	{ x = 3.2, y = 0.6 }, { x = 3.2, y = 1.8 }, { x = 0, y = 1.8 },
}
local MANCHE_LONGUE = { { x = 0, y = 0.6 }, { x = 1.6, y = 0 }, { x = 3.2, y = 0.6 }, { x = 2.8, y = 5.6 }, { x = 0.4, y = 5.6 } }
local COL_CLAUDINE = { { x = 0, y = 0 }, { x = 2, y = 0 }, { x = 2.4, y = 0.4 }, { x = 2.2, y = 1.2 }, { x = 1, y = 1.4 }, { x = 0, y = 1.2 } }
-- Sous-projet 4 : cache-cœur (encolure croisée, plus basse d'un côté), bustier (sans épaules, haut en cœur),
-- manches courte et trois-quarts, col marin (étroit devant, large dans le dos), jupe crayon (resserrée)
local CORSAGE_CACHE_COEUR = {
	{ x = 0, y = 0 }, { x = 1, y = 0 }, { x = 3, y = 2.6 }, { x = 3.8, y = 0 },
	{ x = 4.8, y = 0 }, { x = 4.8, y = 4.2 }, { x = 0, y = 4.2 },
}
local BUSTIER_DEVANT = {
	{ x = 0, y = 0.4 }, { x = 1.2, y = 0 }, { x = 2.4, y = 0.5 }, { x = 3.6, y = 0 },
	{ x = 4.8, y = 0.4 }, { x = 4.8, y = 3 }, { x = 0, y = 3 },
}
local MANCHE_COURTE = { { x = 0, y = 0.6 }, { x = 1.6, y = 0 }, { x = 3.2, y = 0.6 }, { x = 3, y = 1.8 }, { x = 0.2, y = 1.8 } }
local MANCHE_TROIS_QUARTS = { { x = 0, y = 0.6 }, { x = 1.6, y = 0 }, { x = 3.2, y = 0.6 }, { x = 2.9, y = 4 }, { x = 0.3, y = 4 } }
local COL_MARIN = { { x = 0, y = 0 }, { x = 2.2, y = 0 }, { x = 2.4, y = 1.6 }, { x = 0.8, y = 1.6 } }
local CRAYON = { { x = 0, y = 0 }, { x = 5, y = 0 }, { x = 4.6, y = 6 }, { x = 0.4, y = 6 } }
-- Sous-projet 7 : la basque, courte et évasée, sous la taille, par-dessus la jupe
local BASQUE = { { x = 0.8, y = 0 }, { x = 5.6, y = 0 }, { x = 6.4, y = 1.2 }, { x = 0, y = 1.2 } }
-- Un volant froncé : une bande longue (sa longueur fait le tour, froncée) et basse, cousue par le haut
-- (en vitrine, 24 colonnes : avec 16, chaque sommet tomberait sur un creux des fronces, et le volant serait lisse)
local GRILLE_VOLANT = { robe = { colonnes = 32, lignes = 3 }, vitrine = { colonnes = 24, lignes = 2 } }
local GRILLE_BASQUE = { robe = { colonnes = 12, lignes = 4 }, vitrine = { colonnes = 6, lignes = 2 } }

Catalogue.Pieces = {
	corsage_droit_devant = { nom = "Corsage devant", contour = rectangle(4.8, 4.2), coutures = { 2, 3, 4 },
		enroulement = { type = "corsage", cote = "devant" } },
	corsage_droit_dos = { nom = "Corsage dos", contour = rectangle(4.8, 4.2), coutures = { 2, 3, 4 },
		enroulement = { type = "corsage", cote = "dos" } },
	corsage_v_devant = { nom = "Corsage devant (V)", contour = CORSAGE_V, coutures = { 5, 6, 7 },
		enroulement = { type = "corsage", cote = "devant" } },
	corsage_bretelles_devant = { nom = "Corsage devant (bretelles)", contour = CORSAGE_BRETELLES, coutures = { 7, 8, 9 },
		enroulement = { type = "corsage", cote = "devant" } },
	corsage_bretelles_dos = { nom = "Corsage dos (bretelles)", contour = CORSAGE_BRETELLES, coutures = { 7, 8, 9 },
		enroulement = { type = "corsage", cote = "dos" } },
	corsage_cache_coeur_devant = { nom = "Corsage devant (cache-cœur)", contour = CORSAGE_CACHE_COEUR, coutures = { 5, 6, 7 },
		enroulement = { type = "corsage", cote = "devant" } },
	corsage_bustier_devant = { nom = "Bustier devant", contour = BUSTIER_DEVANT, coutures = { 5, 6, 7 },
		enroulement = { type = "corsage", cote = "devant" } },
	corsage_bustier_dos = { nom = "Bustier dos", contour = rectangle(4.8, 3), coutures = { 2, 3, 4 },
		enroulement = { type = "corsage", cote = "dos" } },
	manche_ballon = { nom = "Manche ballon", contour = MANCHE_BALLON, coutures = { 1, 2, 3, 4, 5 }, pliee = true,
		enroulement = { type = "manche", bouffant = 0.25 } },
	manche_longue = { nom = "Manche longue", contour = MANCHE_LONGUE, coutures = { 1, 2, 3, 5 }, pliee = true,
		enroulement = { type = "manche", bouffant = 0 } },
	manche_courte = { nom = "Manche courte", contour = MANCHE_COURTE, coutures = { 1, 2, 3, 5 }, pliee = true,
		enroulement = { type = "manche", bouffant = 0 } },
	manche_trois_quarts = { nom = "Manche trois-quarts", contour = MANCHE_TROIS_QUARTS, coutures = { 1, 2, 3, 5 }, pliee = true,
		enroulement = { type = "manche", bouffant = 0 } },
	col_claudine = { nom = "Col Claudine", contour = COL_CLAUDINE, coutures = { 1 }, pliee = true,
		enroulement = { type = "col", forme = "claudine" } },
	-- Col montant : le bord bas (arête 3) est cousu à l'encolure, le haut est libre
	col_montant = { nom = "Col montant", contour = rectangle(2, 0.6), coutures = { 3 }, pliee = true,
		enroulement = { type = "col", forme = "montant" } },
	-- Col marin : le bord haut (arête 1) est cousu à l'encolure ; le reste retombe, plus bas dans le dos
	col_marin = { nom = "Col marin", contour = COL_MARIN, coutures = { 1 }, pliee = true,
		enroulement = { type = "col", forme = "marin" } },
	jupe_droite_devant = { nom = "Jupe devant", contour = rectangle(5, 6), coutures = { 1, 2, 4 },
		enroulement = { type = "jupe", cote = "devant", evasement = 0.03, fronces = 0 } },
	jupe_droite_dos = { nom = "Jupe dos", contour = rectangle(5, 6), coutures = { 1, 2, 4 },
		enroulement = { type = "jupe", cote = "dos", evasement = 0.03, fronces = 0 } },
	jupe_trapeze_devant = { nom = "Jupe trapèze devant", contour = TRAPEZE, coutures = { 1, 2, 4 },
		enroulement = { type = "jupe", cote = "devant", evasement = 0.25, fronces = 0 } },
	jupe_trapeze_dos = { nom = "Jupe trapèze dos", contour = TRAPEZE, coutures = { 1, 2, 4 },
		enroulement = { type = "jupe", cote = "dos", evasement = 0.25, fronces = 0 } },
	jupe_ample_devant = { nom = "Jupe ample devant", contour = rectangle(8, 6), coutures = { 1, 2, 4 },
		enroulement = { type = "jupe", cote = "devant", evasement = 0.3, fronces = 0.25 } },
	jupe_ample_dos = { nom = "Jupe ample dos", contour = rectangle(8, 6), coutures = { 1, 2, 4 },
		enroulement = { type = "jupe", cote = "dos", evasement = 0.3, fronces = 0.25 } },
	jupe_evasee_devant = { nom = "Jupe évasée devant", contour = EVASEE, coutures = { 1, 2, 4 }, biais = true,
		enroulement = { type = "jupe", cote = "devant", evasement = 0.45, fronces = 0 } },
	jupe_evasee_dos = { nom = "Jupe évasée dos", contour = EVASEE, coutures = { 1, 2, 4 }, biais = true,
		enroulement = { type = "jupe", cote = "dos", evasement = 0.45, fronces = 0 } },
	-- Jupe crayon : un évasement négatif la resserre sous les hanches (elle reste hors des jambes, même pour les
	-- hanches les plus fines qu'accepte une recette)
	jupe_crayon_devant = { nom = "Jupe crayon devant", contour = CRAYON, coutures = { 1, 2, 4 },
		enroulement = { type = "jupe", cote = "devant", evasement = -0.04, fronces = 0 } },
	jupe_crayon_dos = { nom = "Jupe crayon dos", contour = CRAYON, coutures = { 1, 2, 4 },
		enroulement = { type = "jupe", cote = "dos", evasement = -0.04, fronces = 0 } },
	-- Sous-projet 7 : des couches. Le volant, cousu d'un bord (le haut), part à 5 dm sous la taille, par-dessus la jupe
	-- droite, et descend 0,6 dm plus bas qu'elle ; la basque, par-dessus la jupe, s'évase depuis la taille
	volant_devant = { nom = "Volant devant", contour = rectangle(9, 1.6), coutures = { 1 }, poids = 0.5, grille = GRILLE_VOLANT,
		enroulement = { type = "jupe", cote = "devant", depart = 5, couche = 1, evasement = 0.03, ampleur = 0.3, fronces = 0.35 } },
	volant_dos = { nom = "Volant dos", contour = rectangle(9, 1.6), coutures = { 1 }, poids = 0.5, grille = GRILLE_VOLANT,
		enroulement = { type = "jupe", cote = "dos", depart = 5, couche = 1, evasement = 0.03, ampleur = 0.3, fronces = 0.35 } },
	basque_devant = { nom = "Basque devant", contour = BASQUE, coutures = { 1 }, poids = 0.5, grille = GRILLE_BASQUE,
		enroulement = { type = "jupe", cote = "devant", depart = 0, couche = 1, evasement = 0, ampleur = 0.35, fronces = 0 } },
	basque_dos = { nom = "Basque dos", contour = BASQUE, coutures = { 1 }, poids = 0.5, grille = GRILLE_BASQUE,
		enroulement = { type = "jupe", cote = "dos", depart = 0, couche = 1, evasement = 0, ampleur = 0.35, fronces = 0 } },
}

---------------------------------------------------------------------------
-- Variantes du carnet de croquis (points de style et, sous-projet 7, d'occasion par variante)
---------------------------------------------------------------------------
Catalogue.Variantes = {
	{ id = "corsage_droit", famille = "corsage", nom = "Droit",
		pieces = { "corsage_droit_devant", "corsage_droit_dos" }, style = { chic = 6, decontracte = 6 },
		occasion = { travail = 8, journee = 4 } },
	{ id = "corsage_v", famille = "corsage", nom = "Décolleté en V",
		pieces = { "corsage_v_devant", "corsage_droit_dos" }, style = { elegant = 8, romantique = 4 },
		occasion = { soiree = 6, journee = 2 } },
	{ id = "corsage_bretelles", famille = "corsage", nom = "À bretelles",
		pieces = { "corsage_bretelles_devant", "corsage_bretelles_dos" }, style = { decontracte = 8, mignon = 4 },
		occasion = { journee = 8 } },
	{ id = "corsage_cache_coeur", famille = "corsage", nom = "Cache-cœur",
		pieces = { "corsage_cache_coeur_devant", "corsage_droit_dos" }, style = { romantique = 8, chic = 4 },
		occasion = { journee = 4, soiree = 4 } },
	{ id = "corsage_bustier", famille = "corsage", nom = "Bustier",
		pieces = { "corsage_bustier_devant", "corsage_bustier_dos" }, style = { gothique = 7, elegant = 5 },
		occasion = { soiree = 10 } },
	{ id = "manches_sans", famille = "manches", nom = "Sans manches", pieces = {}, style = { decontracte = 3 },
		occasion = { journee = 4, soiree = 4 } },
	{ id = "manches_ballon", famille = "manches", nom = "Ballon", pieces = { "manche_ballon" },
		style = { mignon = 8, romantique = 4 }, occasion = { journee = 6 } },
	{ id = "manches_longues", famille = "manches", nom = "Longues", pieces = { "manche_longue" },
		style = { elegant = 5, gothique = 5, chic = 3 }, occasion = { travail = 6, soiree = 2 } },
	{ id = "manches_courtes", famille = "manches", nom = "Courtes", pieces = { "manche_courte" },
		style = { decontracte = 6, mignon = 3 }, occasion = { journee = 6, travail = 2 } },
	{ id = "manches_trois_quarts", famille = "manches", nom = "Trois-quarts", pieces = { "manche_trois_quarts" },
		style = { chic = 6, elegant = 4 }, occasion = { travail = 8 } },
	{ id = "col_sans", famille = "col", nom = "Sans col", pieces = {}, style = {}, occasion = { soiree = 4 } },
	{ id = "col_claudine", famille = "col", nom = "Claudine", pieces = { "col_claudine" }, style = { mignon = 6, chic = 2 },
		occasion = { journee = 4, travail = 2 } },
	{ id = "col_montant", famille = "col", nom = "Montant", pieces = { "col_montant" }, style = { gothique = 6, elegant = 4 },
		occasion = { travail = 6, soiree = 2 } },
	{ id = "col_marin", famille = "col", nom = "Marin", pieces = { "col_marin" }, style = { mignon = 5, decontracte = 5 },
		occasion = { journee = 6 } },
	{ id = "jupe_droite", famille = "jupe", nom = "Droite",
		pieces = { "jupe_droite_devant", "jupe_droite_dos" }, style = { chic = 8 }, occasion = { travail = 8 } },
	{ id = "jupe_trapeze", famille = "jupe", nom = "Trapèze",
		pieces = { "jupe_trapeze_devant", "jupe_trapeze_dos" }, style = { decontracte = 5, mignon = 4 },
		occasion = { journee = 8 } },
	{ id = "jupe_ample", famille = "jupe", nom = "Ample froncée",
		pieces = { "jupe_ample_devant", "jupe_ample_dos" }, style = { romantique = 8, mignon = 4 },
		occasion = { journee = 6, soiree = 4 } },
	{ id = "jupe_evasee", famille = "jupe", nom = "Longue évasée",
		pieces = { "jupe_evasee_devant", "jupe_evasee_dos" }, style = { elegant = 10, gothique = 4, decontracte = -4 },
		occasion = { soiree = 10 } },
	{ id = "jupe_crayon", famille = "jupe", nom = "Crayon",
		pieces = { "jupe_crayon_devant", "jupe_crayon_dos" }, style = { chic = 8, elegant = 4, decontracte = -2 },
		occasion = { travail = 10, soiree = 2 } },
	-- Sous-projet 7 : des couches. (Une variante ne change jamais de pièces : les robes gardées et les recettes des
	-- vitrines resteraient invalides ; on en ajoute de nouvelles.)
	{ id = "corsage_basque", famille = "corsage", nom = "À basque",
		pieces = { "corsage_droit_devant", "corsage_droit_dos", "basque_devant", "basque_dos" }, style = { elegant = 6, chic = 6, romantique = 2 },
		occasion = { travail = 8, soiree = 4 } },
	{ id = "jupe_volant", famille = "jupe", nom = "À volant",
		pieces = { "jupe_droite_devant", "jupe_droite_dos", "volant_devant", "volant_dos" }, style = { romantique = 8, mignon = 6 },
		occasion = { journee = 6, soiree = 4 } },
}

---------------------------------------------------------------------------
-- Tissus (prix pour 1 m = 10 dm). motif.periode en dm, doit diviser 8 dm (taille du motif).
-- Couleurs : { rouge, vert, bleu } de 0 à 255.
---------------------------------------------------------------------------
local function tissu(id, nom, matiere, teinte, prix, motif, style)
	return { id = id, nom = nom, matiere = matiere, teinte = teinte, prix = prix, motif = motif, style = style }
end
local BLANC, NOIR = { 246, 242, 234 }, { 34, 30, 38 }

Catalogue.Tissus = {
	tissu("coton_blanc", "Coton blanc", "coton", "blanc", 4, { type = "uni", couleurs = { BLANC } },
		{ decontracte = 10, mignon = 4 }),
	tissu("coton_rose_pois", "Coton rose à pois", "coton", "rose", 6,
		{ type = "pois", couleurs = { { 240, 160, 190 }, BLANC }, periode = 1, rayon = 0.2 }, { mignon = 16, decontracte = 6 }),
	tissu("coton_bleu_carreaux", "Vichy bleu", "coton", "bleu", 6,
		{ type = "carreaux", couleurs = { BLANC, { 90, 130, 200 } }, periode = 0.5 }, { decontracte = 14, mignon = 4 }),
	tissu("coton_jaune_fleurs", "Coton jaune fleuri", "coton", "jaune", 7,
		{ type = "fleurs", couleurs = { { 240, 206, 90 }, BLANC, { 230, 120, 60 } }, periode = 2 }, { mignon = 12, romantique = 8 }),
	tissu("lin_naturel", "Lin naturel", "lin", "brun", 6, { type = "uni", couleurs = { { 200, 180, 150 } } },
		{ decontracte = 16, chic = 4 }),
	tissu("lin_vert_rayures", "Lin rayé vert", "lin", "vert", 7,
		{ type = "rayures", couleurs = { { 226, 234, 214 }, { 90, 140, 90 } }, periode = 1, largeur = 0.3 }, { decontracte = 12, chic = 6 }),
	tissu("lin_bleu", "Lin bleu", "lin", "bleu", 6, { type = "uni", couleurs = { { 110, 150, 200 } } },
		{ decontracte = 10, chic = 8 }),
	tissu("lin_noir", "Lin noir", "lin", "noir", 7, { type = "uni", couleurs = { NOIR } }, { chic = 10, gothique = 6 }),
	tissu("laine_brune_carreaux", "Tweed brun", "laine", "brun", 9,
		{ type = "carreaux", couleurs = { { 150, 110, 80 }, { 100, 70, 50 } }, periode = 1 }, { chic = 14, elegant = 4 }),
	tissu("laine_bordeaux", "Laine bordeaux", "laine", "rouge", 9, { type = "uni", couleurs = { { 120, 30, 50 } } },
		{ gothique = 10, chic = 8 }),
	tissu("laine_verte_carreaux", "Tartan vert", "laine", "vert", 9,
		{ type = "carreaux", couleurs = { { 40, 90, 60 }, { 20, 40, 70 } }, periode = 2 }, { decontracte = 8, chic = 10 }),
	tissu("laine_noire", "Laine noire", "laine", "noir", 8, { type = "uni", couleurs = { NOIR } }, { gothique = 12, chic = 8 }),
	tissu("soie_rose_fleurs", "Soie rose fleurie", "soie", "rose", 16,
		{ type = "fleurs", couleurs = { { 214, 84, 146 }, { 255, 200, 225 }, { 255, 230, 120 } }, periode = 2 },
		{ romantique = 20, elegant = 10 }),
	tissu("soie_ivoire", "Soie ivoire", "soie", "blanc", 15, { type = "uni", couleurs = { { 250, 244, 226 } } },
		{ elegant = 20, romantique = 8 }),
	tissu("soie_bleue_degrade", "Soie bleue dégradée", "soie", "bleu", 17,
		{ type = "degrade", couleurs = { { 40, 70, 160 }, { 160, 200, 240 } } }, { elegant = 16, romantique = 6 }),
	tissu("soie_rouge", "Soie rouge", "soie", "rouge", 16, { type = "uni", couleurs = { { 200, 30, 50 } } },
		{ romantique = 16, elegant = 12 }),
	tissu("velours_violet", "Velours violet", "velours", "violet", 14, { type = "uni", couleurs = { { 90, 40, 120 } } },
		{ gothique = 14, elegant = 12 }),
	tissu("velours_noir", "Velours noir", "velours", "noir", 14, { type = "uni", couleurs = { NOIR } },
		{ gothique = 22, elegant = 6 }),
	tissu("velours_vert", "Velours émeraude", "velours", "vert", 13, { type = "uni", couleurs = { { 20, 110, 80 } } },
		{ elegant = 12, chic = 8 }),
	tissu("velours_rouge", "Velours rubis", "velours", "rouge", 14, { type = "uni", couleurs = { { 150, 20, 40 } } },
		{ elegant = 12, romantique = 10, gothique = 4 }),
	tissu("satin_rose", "Satin rose", "satin", "rose", 12, { type = "uni", couleurs = { { 244, 170, 200 } } },
		{ romantique = 14, mignon = 10 }),
	tissu("satin_noir_rayures", "Satin noir rayé", "satin", "noir", 13,
		{ type = "rayures", couleurs = { NOIR, { 120, 110, 130 } }, periode = 0.5, largeur = 0.1 }, { gothique = 16, chic = 8 }),
	tissu("satin_or_degrade", "Satin or dégradé", "satin", "jaune", 18,
		{ type = "degrade", couleurs = { { 200, 150, 40 }, { 250, 230, 160 } } }, { elegant = 18, chic = 6 }),
	tissu("satin_violet_pois", "Satin violet à pois", "satin", "violet", 12,
		{ type = "pois", couleurs = { { 120, 70, 160 }, { 230, 210, 250 } }, periode = 0.5, rayon = 0.1 }, { mignon = 10, gothique = 8 }),
	-- Sous-projet 4 : quatre matières de fin de partie (crêpe et organza au prestige 6, brocart au 7, tulle au 8)
	tissu("crepe_noir", "Crêpe noir", "crepe", "noir", 19, { type = "uni", couleurs = { { 32, 28, 36 } } },
		{ elegant = 14, chic = 12, gothique = 4 }),
	tissu("crepe_bleu_nuit", "Crêpe bleu nuit", "crepe", "bleu", 18, { type = "uni", couleurs = { { 30, 40, 90 } } },
		{ elegant = 14, chic = 12 }),
	tissu("crepe_ivoire", "Crêpe ivoire", "crepe", "blanc", 18, { type = "uni", couleurs = { { 245, 238, 222 } } },
		{ elegant = 16, chic = 8 }),
	tissu("crepe_rose_poudre", "Crêpe rose poudré", "crepe", "rose", 20, { type = "uni", couleurs = { { 230, 180, 185 } } },
		{ elegant = 10, romantique = 10, chic = 6 }),
	tissu("organza_blanc", "Organza blanc", "organza", "blanc", 18, { type = "uni", couleurs = { { 250, 250, 252 } } },
		{ romantique = 16, mignon = 8 }),
	tissu("organza_rose_pois", "Organza rose à pois", "organza", "rose", 20,
		{ type = "pois", couleurs = { { 250, 200, 215 }, { 255, 255, 255 } }, periode = 0.5, rayon = 0.08 }, { mignon = 16, romantique = 10 }),
	tissu("organza_lavande", "Organza lavande", "organza", "violet", 20, { type = "uni", couleurs = { { 200, 180, 230 } } },
		{ romantique = 14, mignon = 10 }),
	tissu("organza_jaune_fleurs", "Organza jaune fleuri", "organza", "jaune", 22,
		{ type = "fleurs", couleurs = { { 250, 230, 140 }, { 255, 255, 240 }, { 240, 160, 90 } }, periode = 2 }, { romantique = 12, mignon = 12 }),
	tissu("brocart_or", "Brocart or", "brocart", "jaune", 26,
		{ type = "fleurs", couleurs = { { 190, 140, 40 }, { 240, 200, 90 }, { 150, 100, 30 } }, periode = 2 }, { elegant = 22, chic = 6 }),
	tissu("brocart_bordeaux", "Brocart bordeaux", "brocart", "rouge", 24,
		{ type = "fleurs", couleurs = { { 110, 20, 40 }, { 170, 60, 80 }, { 80, 10, 30 } }, periode = 2 }, { elegant = 16, gothique = 10 }),
	tissu("brocart_noir_argent", "Brocart noir et argent", "brocart", "noir", 25,
		{ type = "rayures", couleurs = { { 30, 28, 34 }, { 180, 180, 190 } }, periode = 1, largeur = 0.2 }, { gothique = 18, elegant = 10 }),
	tissu("brocart_vert", "Brocart émeraude", "brocart", "vert", 22,
		{ type = "carreaux", couleurs = { { 20, 90, 60 }, { 60, 140, 100 } }, periode = 1 }, { elegant = 16, chic = 10 }),
	tissu("tulle_blanc", "Tulle blanc", "tulle", "blanc", 20, { type = "uni", couleurs = { { 252, 252, 255 } } },
		{ romantique = 18, elegant = 10 }),
	tissu("tulle_rose", "Tulle rose", "tulle", "rose", 22, { type = "uni", couleurs = { { 250, 190, 210 } } },
		{ romantique = 20, mignon = 8 }),
	tissu("tulle_noir", "Tulle noir", "tulle", "noir", 22, { type = "uni", couleurs = { { 25, 22, 30 } } },
		{ gothique = 16, romantique = 10 }),
	tissu("tulle_bleu_degrade", "Tulle bleu dégradé", "tulle", "bleu", 24,
		{ type = "degrade", couleurs = { { 120, 160, 230 }, { 220, 235, 255 } } }, { romantique = 16, elegant = 12 }),
	-- La toile de jute (sous-projet 2) : gratuite, pour s'exercer ou vendre sans risque ; un style à peine marqué
	tissu("toile_jute", "Toile de jute", "jute", "brun", 0,
		{ type = "carreaux", couleurs = { { 176, 140, 96 }, { 150, 116, 76 } }, periode = 0.25 }, { decontracte = 4 }),
}

-- Par matière : rendu 3D, matériau Roblox et reflet (SurfaceAppearance est interdite en jeu, voir le spike) ;
-- sous-projet 7 : son nom, ses points d'occasion (comme les points de style d'un tissu : K 2, au prorata de la
-- surface) et sa chaleur, de -1 (la plus légère) à 1 (la plus chaude)
Catalogue.MATIERES = {
	coton = { nom = "coton", rugosite = 0.9, reflet = 0, materiau = "Fabric", occasion = { journee = 20, travail = 6 }, chaleur = -0.5 },
	lin = { nom = "lin", rugosite = 1, reflet = 0, materiau = "Fabric", occasion = { journee = 14, travail = 10 }, chaleur = -0.8 },
	jute = { nom = "jute", rugosite = 1, reflet = 0, materiau = "Fabric", occasion = { journee = 10, travail = 8 }, chaleur = 0.1 },
	crepe = { nom = "crêpe", rugosite = 0.7, reflet = 0.02, materiau = "Fabric", occasion = { soiree = 10, travail = 12 }, chaleur = 0 },
	organza = { nom = "organza", rugosite = 0.3, reflet = 0.12, materiau = "SmoothPlastic", occasion = { soiree = 20 }, chaleur = -0.9 },
	brocart = { nom = "brocart", rugosite = 0.4, reflet = 0.15, materiau = "SmoothPlastic", occasion = { soiree = 16, travail = 4 }, chaleur = 0.6 },
	tulle = { nom = "tulle", rugosite = 0.6, reflet = 0.05, materiau = "Fabric", occasion = { soiree = 16, journee = 2 }, chaleur = -0.7 },
	laine = { nom = "laine", rugosite = 1, reflet = 0, materiau = "Fabric", occasion = { travail = 20, journee = 4 }, chaleur = 0.9 },
	soie = { nom = "soie", rugosite = 0.35, reflet = 0.1, materiau = "SmoothPlastic", occasion = { soiree = 14, journee = 6 }, chaleur = -0.4 },
	velours = { nom = "velours", rugosite = 0.8, reflet = 0, materiau = "Fabric", occasion = { soiree = 14, travail = 4 }, chaleur = 0.8 },
	satin = { nom = "satin", rugosite = 0.25, reflet = 0.15, materiau = "SmoothPlastic", occasion = { soiree = 18, journee = 2 }, chaleur = -0.1 },
}

---------------------------------------------------------------------------
-- Accessoires : objets (prix à l'unité) et garnitures (prix au dm, points de style pour 5 dm, au prorata)
---------------------------------------------------------------------------
-- apparence : forme 3D ("boule", "bloc", "cylindre", "noeud", "fleur", "croix"), taille (dm), couleur, reflet
local function objet(id, nom, prix, style, apparence)
	return { id = id, nom = nom, genre = "objet", prix = prix, style = style, apparence = apparence }
end
-- apparence d'une garniture : largeur du ruban (dm), couleur, transparence
local function garniture(id, nom, prix, style, apparence)
	return { id = id, nom = nom, genre = "garniture", prix = prix, style = style, apparence = apparence }
end

Catalogue.Accessoires = {
	objet("bouton_nacre", "Bouton nacré", 1, { chic = 2, elegant = 1 },
		{ forme = "boule", taille = 0.25, couleur = { 248, 244, 236 }, reflet = 0.3 }),
	objet("bouton_dore", "Bouton doré", 2, { elegant = 2, chic = 1 },
		{ forme = "cylindre", taille = 0.28, couleur = { 214, 170, 60 }, reflet = 0.4 }),
	objet("noeud_satin", "Nœud de satin", 3, { mignon = 4, romantique = 2 },
		{ forme = "noeud", taille = 0.9, couleur = { 240, 150, 190 }, reflet = 0.15 }),
	objet("noeud_velours", "Nœud de velours", 4, { gothique = 3, elegant = 2 },
		{ forme = "noeud", taille = 0.9, couleur = { 60, 20, 40 }, reflet = 0 }),
	objet("fleur_rose", "Fleur rose", 3, { romantique = 4, mignon = 2 },
		{ forme = "fleur", taille = 0.6, couleur = { 250, 140, 180 }, reflet = 0 }),
	objet("fleur_blanche", "Fleur blanche", 3, { romantique = 3, elegant = 2 },
		{ forme = "fleur", taille = 0.6, couleur = { 250, 250, 245 }, reflet = 0 }),
	objet("broche_camee", "Broche camée", 8, { elegant = 5, gothique = 2 },
		{ forme = "cylindre", taille = 0.55, couleur = { 240, 200, 180 }, reflet = 0.2 }),
	objet("perle", "Perle", 1, { elegant = 2, romantique = 1 },
		{ forme = "boule", taille = 0.18, couleur = { 250, 246, 240 }, reflet = 0.5 }),
	objet("etoile_brodee", "Étoile brodée", 2, { mignon = 3 },
		{ forme = "bloc", taille = 0.4, couleur = { 250, 220, 90 }, reflet = 0 }),
	objet("croix_argent", "Croix d'argent", 5, { gothique = 5 },
		{ forme = "croix", taille = 0.6, couleur = { 200, 200, 210 }, reflet = 0.5 }),
	garniture("dentelle_blanche", "Dentelle blanche", 2, { romantique = 3, elegant = 2 },
		{ largeur = 0.3, couleur = { 250, 248, 240 }, transparence = 0.15 }),
	garniture("dentelle_noire", "Dentelle noire", 2, { gothique = 4, elegant = 1 },
		{ largeur = 0.3, couleur = { 30, 25, 30 }, transparence = 0.15 }),
	garniture("ruban_rose", "Ruban rose", 1, { mignon = 3 }, { largeur = 0.2, couleur = { 240, 150, 190 }, transparence = 0 }),
	garniture("galon_dore", "Galon doré", 3, { elegant = 3, chic = 2 }, { largeur = 0.15, couleur = { 214, 170, 60 }, transparence = 0 }),
	garniture("ruban_noir", "Ruban noir", 1, { gothique = 2, chic = 2 }, { largeur = 0.2, couleur = { 30, 25, 30 }, transparence = 0 }),
	-- Sous-projet 4 : deux décorations par niveau de prestige, du 5 au 8
	objet("noeud_dore", "Nœud doré", 5, { elegant = 3, chic = 2 },
		{ forme = "noeud", taille = 0.8, couleur = { 214, 170, 60 }, reflet = 0.4 }),
	objet("perle_noire", "Perle noire", 2, { gothique = 2, elegant = 2 },
		{ forme = "boule", taille = 0.18, couleur = { 30, 28, 34 }, reflet = 0.5 }),
	objet("papillon_soie", "Papillon de soie", 5, { romantique = 3, mignon = 2 },
		{ forme = "noeud", taille = 0.7, couleur = { 150, 190, 240 }, reflet = 0.2 }),
	garniture("galon_argent", "Galon argenté", 3, { elegant = 3, chic = 2 }, { largeur = 0.15, couleur = { 200, 200, 210 }, transparence = 0 }),
	objet("broche_etoile", "Broche étoile", 9, { chic = 3, elegant = 3 },
		{ forme = "croix", taille = 0.5, couleur = { 230, 200, 90 }, reflet = 0.4 }),
	garniture("ruban_velours", "Ruban de velours", 2, { gothique = 2, romantique = 2 }, { largeur = 0.2, couleur = { 100, 20, 40 }, transparence = 0 }),
	objet("couronne_fleurs", "Couronne de fleurs", 8, { romantique = 5, mignon = 1 },
		{ forme = "fleur", taille = 0.7, couleur = { 250, 200, 215 }, reflet = 0 }),
	garniture("dentelle_doree", "Dentelle dorée", 4, { elegant = 4, romantique = 1 }, { largeur = 0.3, couleur = { 220, 190, 110 }, transparence = 0.15 }),
	-- Sous-projet 4 : ce qu'ouvre l'amitié des quatre nouvelles clientes (niveau 4)
	objet("violette", "Violette", 3, { romantique = 3, chic = 1 },
		{ forme = "fleur", taille = 0.45, couleur = { 140, 90, 190 }, reflet = 0 }),
	objet("boucle_ecaille", "Boucle d'écaille", 4, { chic = 3, decontracte = 2 },
		{ forme = "cylindre", taille = 0.45, couleur = { 130, 80, 40 }, reflet = 0.3 }),
	garniture("dentelle_rouge", "Dentelle rouge", 3, { gothique = 3, romantique = 2 }, { largeur = 0.3, couleur = { 160, 20, 40 }, transparence = 0.15 }),
	objet("coquillage", "Coquillage", 3, { decontracte = 3, mignon = 2 },
		{ forme = "boule", taille = 0.35, couleur = { 250, 225, 210 }, reflet = 0.2 }),
	-- Les souvenirs des événements du quartier (sous-projet 3) : chacun s'ouvre quand son événement a lieu
	objet("lanterne_papier", "Lanterne de papier", 4, { romantique = 3, mignon = 2 },
		{ forme = "boule", taille = 0.5, couleur = { 245, 150, 70 }, reflet = 0 }),
	objet("cocarde", "Cocarde", 3, { decontracte = 3, mignon = 2 },
		{ forme = "fleur", taille = 0.55, couleur = { 220, 60, 70 }, reflet = 0 }),
	objet("broche_palette", "Broche palette", 5, { chic = 3, elegant = 2 },
		{ forme = "cylindre", taille = 0.5, couleur = { 200, 160, 110 }, reflet = 0.1 }),
	objet("ancre_doree", "Ancre dorée", 5, { chic = 4 },
		{ forme = "croix", taille = 0.55, couleur = { 214, 170, 60 }, reflet = 0.4 }),
	objet("plume_corbeau", "Plume de corbeau", 4, { gothique = 4, elegant = 1 },
		{ forme = "bloc", taille = 0.6, couleur = { 25, 22, 30 }, reflet = 0.1 }),
	objet("fleur_oranger", "Fleur d'oranger", 4, { romantique = 4, elegant = 2 },
		{ forme = "fleur", taille = 0.5, couleur = { 252, 250, 240 }, reflet = 0 }),
	objet("cle_de_sol", "Clé de sol", 6, { elegant = 3, chic = 2 },
		{ forme = "cylindre", taille = 0.45, couleur = { 214, 170, 60 }, reflet = 0.4 }),
	objet("flocon_argent", "Flocon d'argent", 6, { elegant = 4, romantique = 1 },
		{ forme = "croix", taille = 0.5, couleur = { 220, 225, 235 }, reflet = 0.5 }),
	objet("marque_page", "Marque-page doré", 4, { chic = 3, elegant = 1 },
		{ forme = "bloc", taille = 0.5, couleur = { 214, 170, 60 }, reflet = 0.3 }),
	objet("masque_theatre", "Masque de théâtre", 5, { gothique = 2, chic = 2, elegant = 1 },
		{ forme = "bloc", taille = 0.55, couleur = { 245, 240, 230 }, reflet = 0.2 }),
	objet("alliance_or", "Alliance d'or", 6, { romantique = 3, elegant = 2 },
		{ forme = "cylindre", taille = 0.35, couleur = { 230, 190, 80 }, reflet = 0.5 }),
	objet("rosette_honneur", "Rosette d'honneur", 7, { elegant = 3, chic = 3 },
		{ forme = "fleur", taille = 0.6, couleur = { 40, 70, 150 }, reflet = 0.2 }),
}

---------------------------------------------------------------------------
-- Accès par identifiant
---------------------------------------------------------------------------
local function index(liste)
	local t = {}
	for _, e in ipairs(liste) do
		t[e.id] = e
	end
	return t
end
local VARIANTES, TISSUS, ACCESSOIRES = index(Catalogue.Variantes), index(Catalogue.Tissus), index(Catalogue.Accessoires)

function Catalogue.piece(id)
	return Catalogue.Pieces[id]
end
function Catalogue.variante(id)
	return VARIANTES[id]
end
function Catalogue.tissu(id)
	return TISSUS[id]
end
function Catalogue.accessoire(id)
	return ACCESSOIRES[id]
end
function Catalogue.variantesDe(famille)
	local out = {}
	for _, v in ipairs(Catalogue.Variantes) do
		if v.famille == famille then
			table.insert(out, v)
		end
	end
	return out
end

return Catalogue
