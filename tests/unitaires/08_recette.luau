local Catalogue = U.module("Catalogue")
local Recette = U.module("Recette")

local function exemple()
	return {
		croquis = { corsage = "corsage_v", manches = "manches_ballon", col = "col_sans", jupe = "jupe_trapeze" },
		mesures = table.clone(Catalogue.TAILLES.M),
		pieces = {
			{ id = "corsage_v_devant", tissu = "soie_rose_fleurs", x = 3.2, y = 2.5, angle = 45, couture = 0.92 },
			{ id = "corsage_droit_dos", tissu = "soie_rose_fleurs", x = 9.1, y = 2.5, angle = 0, couture = 1 },
			{ id = "manche_ballon", tissu = "satin_rose", x = 2, y = 7, angle = -90, couture = 0.5 },
			{ id = "jupe_trapeze_devant", tissu = "coton_blanc", x = 3.5, y = 12, angle = 0, couture = 0.75 },
			{ id = "jupe_trapeze_dos", tissu = "coton_blanc", x = 10, y = 12, angle = 180, couture = 0.8 },
		},
		accessoires = {
			{ id = "noeud_satin", piece = 1, u = 0.5, v = 0.9, echelle = 1.2, angle = 15 },
			{ id = "bouton_nacre", piece = 3, copie = "droite", u = 0.3, v = 0.4, echelle = 1, angle = 0 },
			{ id = "dentelle_blanche", piece = 4, trajet = { { u = 0, v = 1 }, { u = 0.5, v = 1 }, { u = 1, v = 1 } } },
		},
	}
end

local function egal(a, b, chemin)
	if type(a) ~= type(b) then
		return false, chemin
	end
	if type(a) == "table" then
		for k, v in pairs(a) do
			local ok, ou = egal(v, b[k], chemin .. "." .. tostring(k))
			if not ok then
				return false, ou
			end
		end
		for k in pairs(b) do
			if a[k] == nil then
				return false, chemin .. "." .. tostring(k)
			end
		end
		return true
	elseif type(a) == "number" then
		return math.abs(a - b) <= 1e-9 * math.max(1, math.abs(a)), chemin
	end
	return a == b, chemin
end

-- Aller-retour JSON
local r = exemple()
local texte = Recette.encoder(r)
U.verifier(type(texte) == "string" and texte:sub(1, 1) == "{", "encodage en objet JSON")
local relu = Recette.decoder(texte)
local ok, ou = egal(r, relu, "recette")
U.verifier(ok, "aller-retour JSON sans perte (écart en " .. tostring(ou) .. ")")
U.verifier(Recette.encoder(relu) == texte, "encodage stable (clés triées)")
U.verifier(Recette.decoder(Recette.encoder({ texte = 'a"b\\c\n', liste = {}, vrai = true, faux = false })).texte == 'a"b\\c\n',
	"caractères spéciaux préservés")
U.verifier(not pcall(Recette.encoder, { x = 0 / 0 }), "un nombre non fini ne s'encode pas")

-- Textes invalides : nil et un message, jamais d'erreur
for _, mauvais in ipairs({ "", "{", '{"a":}', '{"a":1}x', "nan", '"sans fin', "[1,2", '{"a" 1}', "-", 12, nil }) do
	local v, message = Recette.decoder(mauvais)
	U.verifier(v == nil and type(message) == "string", "texte invalide refusé : " .. tostring(mauvais))
end
U.verifier(Recette.decoder(string.rep("[", 50) .. string.rep("]", 50)) == nil, "imbrication démesurée refusée")

-- Validation
U.verifier(Recette.valider(exemple()), "recette d'exemple valide")
local cas = {
	{ "pas une table", function() return "x" end },
	{ "croquis invalide", function(x) x.croquis.jupe = "corsage_droit" end },
	{ "pièces absentes", function(x) table.remove(x.pieces) end },
	{ "pièce hors croquis", function(x) x.pieces[1].id = "corsage_droit_devant" end },
	{ "tissu inconnu", function(x) x.pieces[2].tissu = "papier" end },
	{ "x non fini", function(x) x.pieces[1].x = 0 / 0 end },
	{ "angle démesuré", function(x) x.pieces[1].angle = 1e18 end },
	{ "couture > 1", function(x) x.pieces[1].couture = 2 end },
	{ "mesure hors limites", function(x) x.mesures.taille = 40 end },
	{ "mesure manquante", function(x) x.mesures.hanches = nil end },
	{ "taille plus large que la poitrine", function(x) x.mesures.taille = x.mesures.poitrine + 0.5 end },
	{ "accessoire inconnu", function(x) x.accessoires[1].id = "diamant" end },
	{ "pièce 0", function(x) x.accessoires[1].piece = 0 end },
	{ "pièce 1,5", function(x) x.accessoires[1].piece = 1.5 end },
	{ "copie invalide", function(x) x.accessoires[2].copie = "milieu" end },
	{ "u non fini", function(x) x.accessoires[1].u = 0 / 0 end },
	{ "échelle démesurée", function(x) x.accessoires[1].echelle = 10 end },
	{ "garniture d'un point", function(x) x.accessoires[3].trajet = { { u = 0, v = 0 } } end },
	{ "garniture hors pièce", function(x) x.accessoires[3].trajet[2].u = 1.5 end },
	{ "garniture plus courte que 0,5 dm", function(x) x.accessoires[3].trajet = { { u = 0.5, v = 0.5 }, { u = 0.501, v = 0.5 } } end },
	{ "garniture de longueur nulle", function(x) x.accessoires[3].trajet = { { u = 0.5, v = 0.5 }, { u = 0.5, v = 0.5 } } end },
	{ "garniture de 65 points", function(x)
		local t = {}
		for k = 1, 65 do
			t[k] = { u = k / 65, v = 0.5 }
		end
		x.accessoires[3].trajet = t
	end },
	{ "301 accessoires", function(x)
		for _ = 1, 298 do
			table.insert(x.accessoires, { id = "perle", piece = 1, u = 0.5, v = 0.5, echelle = 1, angle = 0 })
		end
	end },
}
for _, c in ipairs(cas) do
	local x = exemple()
	local remplace = c[2](x)
	local okV, message = Recette.valider(remplace or x)
	U.verifier(not okV and type(message) == "string", "recette refusée : " .. c[1])
end
local limite = exemple()
for _ = 1, 297 do
	table.insert(limite.accessoires, { id = "perle", piece = 1, u = 0.5, v = 0.5, echelle = 1, angle = 0 })
end
U.verifier(Recette.valider(limite), "300 accessoires acceptés")

-- Copie par défaut d'un accessoire
local e = exemple()
U.verifier(Recette.copieAccessoire(e, e.accessoires[1]) == "unique", "pièce non pliée : copie unique")
U.verifier(Recette.copieAccessoire(e, e.accessoires[2]) == "droite", "copie donnée explicitement")
U.verifier(Recette.copieAccessoire(e, { id = "perle", piece = 3 }) == "gauche", "pièce pliée : copie gauche par défaut")

-- Relecture finale : validation stricte (filtre du serveur)
local stricts = {
	{ "champ inconnu à la racine", function(x) x.inconnu = string.rep("a", 100) end },
	{ "champ inconnu dans une pièce", function(x) x.pieces[1].bourrage = "x" end },
	{ "champ inconnu dans un accessoire", function(x) x.accessoires[1].bourrage = "x" end },
	{ "champ inconnu dans le croquis", function(x) x.croquis.traine = "x" end },
	{ "champ inconnu dans les mesures", function(x) x.mesures.cou = 3 end },
	{ "champ inconnu dans un point de garniture", function(x) x.accessoires[3].trajet[1].w = 0 end },
	{ "accessoires à trous", function(x) x.accessoires[5] = { id = "perle" } end },
	{ "pièces à trous", function(x) x.pieces[9] = x.pieces[1] end },
	{ "trajet à trous", function(x) x.accessoires[3].trajet[9] = { u = 0, v = 0 } end },
	{ "x démesuré", function(x) x.pieces[1].x = 1e308 end },
	{ "y négatif", function(x) x.pieces[1].y = -5 end },
	{ "y au-delà de 100 dm", function(x) x.pieces[1].y = 150 end },
	{ "version inconnue", function(x) x.version = 2 end },
}
for _, c in ipairs(stricts) do
	local x = exemple()
	c[2](x)
	U.verifier(not Recette.valider(x), "recette refusée : " .. c[1])
end
local v1 = exemple()
v1.version = 1
U.verifier(Recette.valider(v1), "version 1 acceptée")
