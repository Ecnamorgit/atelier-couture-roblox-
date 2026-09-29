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
	manche_ballon = { nom = "Manche ballon", contour = MANCHE_BALLON, coutures = { 1, 2, 3, 4, 5 }, pliee = true,
		enroulement = { type = "manche", bouffant = 0.25 } },
	manche_longue = { nom = "Manche longue", contour = MANCHE_LONGUE, coutures = { 1, 2, 3, 5 }, pliee = true,
		enroulement = { type = "manche", bouffant = 0 } },
	col_claudine = { nom = "Col Claudine", contour = COL_CLAUDINE, coutures = { 1 }, pliee = true,
		enroulement = { type = "col", forme = "claudine" } },
	-- Col montant : le bord bas (arête 3) est cousu à l'encolure, le haut est libre
	col_montant = { nom = "Col montant", contour = rectangle(2, 0.6), coutures = { 3 }, pliee = true,
		enroulement = { type = "col", forme = "montant" } },
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
}

---------------------------------------------------------------------------
-- Variantes du carnet de croquis (points de style par variante)
---------------------------------------------------------------------------
Catalogue.Variantes = {
	{ id = "corsage_droit", famille = "corsage", nom = "Droit",
		pieces = { "corsage_droit_devant", "corsage_droit_dos" }, style = { chic = 6, decontracte = 6 } },
	{ id = "corsage_v", famille = "corsage", nom = "Décolleté en V",
		pieces = { "corsage_v_devant", "corsage_droit_dos" }, style = { elegant = 8, romantique = 4 } },
	{ id = "corsage_bretelles", famille = "corsage", nom = "À bretelles",
		pieces = { "corsage_bretelles_devant", "corsage_bretelles_dos" }, style = { decontracte = 8, mignon = 4 } },
	{ id = "manches_sans", famille = "manches", nom = "Sans manches", pieces = {}, style = { decontracte = 3 } },
	{ id = "manches_ballon", famille = "manches", nom = "Ballon", pieces = { "manche_ballon" },
		style = { mignon = 8, romantique = 4 } },
	{ id = "manches_longues", famille = "manches", nom = "Longues", pieces = { "manche_longue" },
		style = { elegant = 5, gothique = 5, chic = 3 } },
	{ id = "col_sans", famille = "col", nom = "Sans col", pieces = {}, style = {} },
	{ id = "col_claudine", famille = "col", nom = "Claudine", pieces = { "col_claudine" }, style = { mignon = 6, chic = 2 } },
	{ id = "col_montant", famille = "col", nom = "Montant", pieces = { "col_montant" }, style = { gothique = 6, elegant = 4 } },
	{ id = "jupe_droite", famille = "jupe", nom = "Droite",
		pieces = { "jupe_droite_devant", "jupe_droite_dos" }, style = { chic = 8 } },
	{ id = "jupe_trapeze", famille = "jupe", nom = "Trapèze",
		pieces = { "jupe_trapeze_devant", "jupe_trapeze_dos" }, style = { decontracte = 5, mignon = 4 } },
	{ id = "jupe_ample", famille = "jupe", nom = "Ample froncée",
		pieces = { "jupe_ample_devant", "jupe_ample_dos" }, style = { romantique = 8, mignon = 4 } },
	{ id = "jupe_evasee", famille = "jupe", nom = "Longue évasée",
		pieces = { "jupe_evasee_devant", "jupe_evasee_dos" }, style = { elegant = 10, gothique = 4, decontracte = -4 } },
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
}

-- Rendu 3D par matière : matériau Roblox et reflet (SurfaceAppearance est interdite en jeu, voir le spike)
Catalogue.MATIERES = {
	coton = { rugosite = 0.9, reflet = 0, materiau = "Fabric" },
	lin = { rugosite = 1, reflet = 0, materiau = "Fabric" },
	laine = { rugosite = 1, reflet = 0, materiau = "Fabric" },
	soie = { rugosite = 0.35, reflet = 0.1, materiau = "SmoothPlastic" },
	velours = { rugosite = 0.8, reflet = 0, materiau = "Fabric" },
	satin = { rugosite = 0.25, reflet = 0.15, materiau = "SmoothPlastic" },
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
