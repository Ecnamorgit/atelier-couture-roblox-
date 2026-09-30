-- Clientes : les dix clientes qui reviennent à l'atelier (contenu original, rien de Dressmaker). Chacune a ses
-- vraies mesures (dm, proches de sa taille), ses styles et sa teinte préférés (ses commandes en viennent), sa
-- tenue, ses répliques, le prestige qu'il faut pour qu'elle vienne, et ce que son amitié ouvre (sous-projet 2).
-- Données, et une règle pure : qui vient à la clochette.

local Clientes = {}

local function rgb(r, g, b)
	return Color3.fromRGB(r, g, b)
end

Clientes.LISTE = {
	{
		id = "colette",
		nom = "Colette Marchand",
		taille = "M",
		mesures = { poitrine = 8.9, taille = 7.1, hanches = 9.5 },
		styles = { "romantique", "mignon" },
		teinte = "rose",
		prestige = 1,
		tenue = { peau = rgb(238, 200, 170), haut = rgb(240, 150, 180), bas = rgb(250, 240, 245), cheveux = rgb(150, 80, 50) },
		deblocages = { [2] = { variante = "jupe_ample" }, [4] = { accessoire = "dentelle_blanche" } },
		repliques = {
			presentation = "Bonjour ! Je suis Colette. On m'a dit que vous faisiez des merveilles.",
			arrivee = "Me revoilà ! J'ai encore besoin de vos doigts de fée.",
			merci = "Elle est ravissante, merci mille fois !",
			deception = "Oh… ce n'est pas tout à fait ce que j'imaginais.",
		},
	},
	{
		id = "margot",
		nom = "Margot Petit",
		taille = "S",
		mesures = { poitrine = 8.1, taille = 6.3, hanches = 8.9 },
		styles = { "mignon", "decontracte" },
		teinte = "jaune",
		prestige = 1,
		tenue = { peau = rgb(250, 214, 180), haut = rgb(250, 210, 80), bas = rgb(120, 180, 220), cheveux = rgb(230, 190, 110) },
		deblocages = { [2] = { accessoire = "noeud_satin" }, [4] = { accessoire = "etoile_brodee" } },
		repliques = {
			presentation = "Coucou ! Moi, c'est Margot. Il me faut une robe toute mignonne !",
			arrivee = "Coucou ! J'ai une nouvelle idée de robe !",
			merci = "Trop jolie ! Je l'adore !",
			deception = "Hum… pas vraiment mon style.",
		},
	},
	{
		id = "salome",
		nom = "Salomé Garnier",
		taille = "L",
		mesures = { poitrine = 9.7, taille = 7.9, hanches = 10.1 },
		styles = { "decontracte", "chic" },
		teinte = "vert",
		prestige = 1,
		tenue = { peau = rgb(170, 120, 90), haut = rgb(110, 160, 110), bas = rgb(200, 180, 150), cheveux = rgb(40, 30, 25) },
		deblocages = { [2] = { variante = "corsage_bretelles" }, [4] = { accessoire = "galon_dore" } },
		repliques = {
			presentation = "Salut ! Salomé. Une robe simple et pratique, c'est possible ?",
			arrivee = "Salut ! Je repasse pour une autre robe.",
			merci = "Parfait, je vais la porter tout l'été.",
			deception = "C'est un peu trop pour moi.",
		},
	},
	{
		id = "helene",
		nom = "Hélène Duval",
		taille = "M",
		mesures = { poitrine = 8.7, taille = 6.8, hanches = 9.3 },
		styles = { "elegant", "chic" },
		teinte = "blanc",
		prestige = 2,
		tenue = { peau = rgb(230, 195, 165), haut = rgb(245, 240, 230), bas = rgb(60, 60, 80), cheveux = rgb(60, 40, 30) },
		deblocages = { [2] = { variante = "col_montant" }, [4] = { accessoire = "broche_camee" } },
		repliques = {
			presentation = "Bonsoir. Hélène Duval. On dit votre atelier prometteur.",
			arrivee = "Bonsoir. J'ai une nouvelle soirée en vue.",
			merci = "Remarquable. Vous avez du talent.",
			deception = "Ce n'est pas à la hauteur, je le crains.",
		},
	},
	{
		id = "ines",
		nom = "Inès Lebrun",
		taille = "S",
		mesures = { poitrine = 8.3, taille = 6.5, hanches = 8.7 },
		styles = { "gothique", "elegant" },
		teinte = "noir",
		prestige = 3,
		tenue = { peau = rgb(240, 220, 205), haut = rgb(30, 25, 35), bas = rgb(90, 40, 90), cheveux = rgb(20, 15, 20) },
		deblocages = { [2] = { variante = "manches_longues" }, [4] = { accessoire = "croix_argent" } },
		repliques = {
			presentation = "… Bonjour. Inès. Du noir, si possible.",
			arrivee = "… Encore moi. Toujours du noir.",
			merci = "Elle est parfaite. Sombre à souhait.",
			deception = "Trop gaie. Beaucoup trop gaie.",
		},
	},
	{
		id = "victoire",
		nom = "Victoire Aubry",
		taille = "L",
		mesures = { poitrine = 9.5, taille = 7.7, hanches = 10.3 },
		styles = { "chic", "elegant" },
		teinte = "bleu",
		prestige = 4,
		tenue = { peau = rgb(120, 80, 60), haut = rgb(60, 90, 170), bas = rgb(230, 230, 235), cheveux = rgb(25, 20, 20) },
		deblocages = { [2] = { variante = "jupe_evasee" }, [4] = { accessoire = "noeud_velours" } },
		repliques = {
			presentation = "Bonjour ! Victoire Aubry. On m'a dit le plus grand bien de vous.",
			arrivee = "Bonjour ! Je reviens vous confier une robe.",
			merci = "Exactement ce qu'il me fallait. Bravo.",
			deception = "Je m'attendais à mieux, franchement.",
		},
	},
	-- Sous-projet 4 : quatre clientes qui arrivent tard (prestiges 5 à 8)
	{
		id = "apolline",
		nom = "Apolline Garnier",
		taille = "M",
		mesures = { poitrine = 8.7, taille = 7.0, hanches = 9.3 },
		styles = { "romantique", "chic" },
		teinte = "violet",
		prestige = 5,
		tenue = { peau = rgb(236, 196, 164), haut = rgb(150, 110, 190), bas = rgb(240, 235, 245), cheveux = rgb(60, 40, 30) },
		deblocages = { [2] = { variante = "corsage_cache_coeur" }, [4] = { accessoire = "violette" } },
		repliques = {
			presentation = "Bonjour. Je m'appelle Apolline, j'écris des poèmes… et j'aimerais qu'une robe m'en inspire un.",
			arrivee = "Me revoici. Votre atelier me donne toujours des idées de vers.",
			merci = "Elle est si belle que je vais lui écrire un sonnet.",
			deception = "Hum… Je ne trouve pas les mots. Et c'est rare, chez moi.",
		},
	},
	{
		id = "josephine",
		nom = "Joséphine Lambert",
		taille = "L",
		mesures = { poitrine = 9.7, taille = 7.9, hanches = 10.1 },
		styles = { "chic", "decontracte" },
		teinte = "brun",
		prestige = 6,
		tenue = { peau = rgb(200, 150, 120), haut = rgb(150, 100, 60), bas = rgb(60, 55, 50), cheveux = rgb(40, 30, 25) },
		deblocages = { [2] = { variante = "manches_trois_quarts" }, [4] = { accessoire = "boucle_ecaille" } },
		repliques = {
			presentation = "Bonjour ! Joséphine, de la librairie d'en face. Je vous regarde coudre depuis ma vitrine.",
			arrivee = "C'est encore moi ! J'ai fermé la boutique une heure pour venir vous voir.",
			merci = "Parfaite. Je la porterai pour les dédicaces.",
			deception = "Ce n'est pas vraiment moi, je crois.",
		},
	},
	{
		id = "capucine",
		nom = "Capucine Morel",
		taille = "S",
		mesures = { poitrine = 8.3, taille = 6.5, hanches = 8.7 },
		styles = { "gothique", "romantique" },
		teinte = "rouge",
		prestige = 7,
		tenue = { peau = rgb(245, 220, 205), haut = rgb(150, 20, 40), bas = rgb(30, 25, 30), cheveux = rgb(20, 15, 15) },
		deblocages = { [2] = { variante = "corsage_bustier" }, [4] = { accessoire = "dentelle_rouge" } },
		repliques = {
			presentation = "Capucine, comédienne. On m'a dit que vous habilliez les grands soirs.",
			arrivee = "Le rideau se lève bientôt : j'ai besoin de vous.",
			merci = "Bravo ! Je vous dois mon entrée en scène.",
			deception = "Le public ne va pas aimer. Moi non plus.",
		},
	},
	{
		id = "maelle",
		nom = "Maëlle Bertin",
		taille = "M",
		mesures = { poitrine = 8.8, taille = 6.9, hanches = 9.5 },
		styles = { "decontracte", "mignon" },
		teinte = "bleu",
		prestige = 8,
		tenue = { peau = rgb(230, 190, 160), haut = rgb(40, 70, 140), bas = rgb(245, 245, 250), cheveux = rgb(200, 150, 80) },
		deblocages = { [2] = { variante = "col_marin" }, [4] = { accessoire = "coquillage" } },
		repliques = {
			presentation = "Bonjour ! Maëlle. Je rentre d'un tour du monde à la voile, et je n'ai plus rien à me mettre !",
			arrivee = "Escale à l'atelier ! Vous avez un moment pour moi ?",
			merci = "Elle est superbe. Je l'emporterai à chaque escale.",
			deception = "Bof… Elle ne tiendrait pas une journée en mer.",
		},
	},
}

local parId = {}
for rang, c in ipairs(Clientes.LISTE) do
	c.rang = rang
	parId[c.id] = c
end

-- La fiche de cliente d'id donné, ou nil
function Clientes.get(id)
	return parId[id]
end

-- La cliente qui vient à la clochette. fiches : { [id] = { vues, derniere } } (visites passées) ;
-- niveauPrestige : le niveau du joueur. Une cliente jamais venue, dont le prestige est atteint, passe avant
-- les autres (dans l'ordre de la liste : les trois premières commandes présentent Colette, Margot, Salomé) ;
-- sinon vient celle qu'on n'a pas vue depuis le plus longtemps.
function Clientes.prochaine(fiches, niveauPrestige)
	for _, c in ipairs(Clientes.LISTE) do
		local f = fiches[c.id]
		if (not f or f.vues == 0) and niveauPrestige >= c.prestige then
			return c.id
		end
	end
	local choisie, plusVieille = nil, math.huge
	for _, c in ipairs(Clientes.LISTE) do
		local f = fiches[c.id]
		if f and f.vues > 0 and f.derniere < plusVieille then
			choisie, plusVieille = c.id, f.derniere
		end
	end
	return choisie or Clientes.LISTE[1].id
end

return Clientes
