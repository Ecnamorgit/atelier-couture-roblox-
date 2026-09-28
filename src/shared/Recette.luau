-- Recette : encodage JSON d'une recette de robe (pour les attributs des vitrines et la sauvegarde)
-- et validation complète d'une recette venue du réseau ou d'une sauvegarde.
local dossier = script.Parent
local Catalogue = require(dossier:WaitForChild("Catalogue"))
local Patron = require(dossier:WaitForChild("Patron"))

local Recette = {}

Recette.MAX_ACCESSOIRES = 300
Recette.MAX_POINTS_GARNITURE = 64
Recette.ANGLE_MAX = 3600
Recette.ECHELLE_MIN, Recette.ECHELLE_MAX = 0.5, 3
-- Tours acceptés (dm) ; la taille ne dépasse ni la poitrine ni les hanches
Recette.POITRINE = { 7, 13 }
Recette.TAILLE = { 5.5, 12 }
Recette.HANCHES = { 8, 14 }

local function fini(n)
	return type(n) == "number" and n == n and n ~= math.huge and n ~= -math.huge
end

---------------------------------------------------------------------------
-- JSON (sous-ensemble : tables, chaînes, nombres finis, booléens)
---------------------------------------------------------------------------
local function estTableau(t)
	local n = #t
	for cle in pairs(t) do
		if type(cle) ~= "number" or cle < 1 or cle > n or cle ~= math.floor(cle) then
			return false
		end
	end
	return true
end

local function encoderChaine(s)
	return '"' .. s:gsub('[%c"\\]', function(c)
		if c == '"' then
			return '\\"'
		elseif c == "\\" then
			return "\\\\"
		end
		return string.format("\\u%04x", string.byte(c))
	end) .. '"'
end

local function encoderValeur(v, profondeur)
	assert(profondeur < 20, "recette trop profonde")
	local t = type(v)
	if t == "number" then
		assert(fini(v), "nombre non fini dans la recette")
		if v == math.floor(v) and math.abs(v) < 1e15 then
			return string.format("%d", v)
		end
		return string.format("%.10g", v)
	elseif t == "string" then
		return encoderChaine(v)
	elseif t == "boolean" then
		return v and "true" or "false"
	elseif t == "table" then
		local parties = {}
		if estTableau(v) then
			for _, e in ipairs(v) do
				table.insert(parties, encoderValeur(e, profondeur + 1))
			end
			return "[" .. table.concat(parties, ",") .. "]"
		end
		local cles = {}
		for cle in pairs(v) do
			assert(type(cle) == "string", "clé non textuelle dans la recette")
			table.insert(cles, cle)
		end
		table.sort(cles) -- encodage stable
		for _, cle in ipairs(cles) do
			table.insert(parties, encoderChaine(cle) .. ":" .. encoderValeur(v[cle], profondeur + 1))
		end
		return "{" .. table.concat(parties, ",") .. "}"
	end
	error("valeur non encodable : " .. t)
end

function Recette.encoder(recette)
	return encoderValeur(recette, 0)
end

-- Décodeur : retourne la valeur, ou nil et un message si le texte est invalide
local function decoder(texte)
	local i = 1
	local function espaces()
		i = texte:find("[^ \t\r\n]", i) or #texte + 1
	end
	local valeur
	local function chaine()
		i += 1
		local morceaux = {}
		while true do
			local c = texte:sub(i, i)
			if c == "" then
				error("chaîne non terminée")
			elseif c == '"' then
				i += 1
				return table.concat(morceaux)
			elseif c == "\\" then
				local e = texte:sub(i + 1, i + 1)
				if e == "u" then
					local code = tonumber(texte:sub(i + 2, i + 5), 16)
					assert(code, "échappement \\u invalide")
					table.insert(morceaux, utf8.char(code))
					i += 6
				else
					local simples = { ['"'] = '"', ["\\"] = "\\", ["/"] = "/", n = "\n", t = "\t", r = "\r", b = "\b", f = "\f" }
					assert(simples[e], "échappement invalide")
					table.insert(morceaux, simples[e])
					i += 2
				end
			else
				table.insert(morceaux, c)
				i += 1
			end
		end
	end
	function valeur(profondeur)
		assert(profondeur < 20, "texte trop profond")
		espaces()
		local c = texte:sub(i, i)
		if c == "{" then
			i += 1
			local t = {}
			espaces()
			if texte:sub(i, i) == "}" then
				i += 1
				return t
			end
			while true do
				espaces()
				assert(texte:sub(i, i) == '"', "clé attendue")
				local cle = chaine()
				espaces()
				assert(texte:sub(i, i) == ":", "« : » attendu")
				i += 1
				t[cle] = valeur(profondeur + 1)
				espaces()
				local s = texte:sub(i, i)
				i += 1
				if s == "}" then
					return t
				end
				assert(s == ",", "« , » ou « } » attendu")
			end
		elseif c == "[" then
			i += 1
			local t = {}
			espaces()
			if texte:sub(i, i) == "]" then
				i += 1
				return t
			end
			while true do
				table.insert(t, valeur(profondeur + 1))
				espaces()
				local s = texte:sub(i, i)
				i += 1
				if s == "]" then
					return t
				end
				assert(s == ",", "« , » ou « ] » attendu")
			end
		elseif c == '"' then
			return chaine()
		elseif texte:sub(i, i + 3) == "true" then
			i += 4
			return true
		elseif texte:sub(i, i + 4) == "false" then
			i += 5
			return false
		end
		local nombre = texte:match("^-?%d+%.?%d*[eE]?[-+]?%d*", i)
		assert(nombre and #nombre > 0, "valeur attendue")
		i += #nombre
		local n = tonumber(nombre)
		assert(fini(n), "nombre invalide")
		return n
	end
	local resultat = valeur(0)
	espaces()
	assert(i > #texte, "texte en trop")
	return resultat
end

function Recette.decoder(texte)
	if type(texte) ~= "string" then
		return nil, "pas un texte"
	end
	local ok, resultat = pcall(decoder, texte)
	if not ok then
		return nil, tostring(resultat)
	end
	return resultat
end

---------------------------------------------------------------------------
-- Validation d'une recette (données venues d'un client, d'un attribut ou d'une sauvegarde)
---------------------------------------------------------------------------
local function dans(n, a, b)
	return fini(n) and n >= a and n <= b
end

function Recette.valider(r)
	if type(r) ~= "table" or type(r.croquis) ~= "table" or type(r.pieces) ~= "table" or type(r.mesures) ~= "table" then
		return false, "Recette incomplète."
	end
	local ok, attendues = pcall(Patron.piecesDuCroquis, r.croquis)
	if not ok then
		return false, "Croquis invalide."
	end
	local m = r.mesures
	if not dans(m.poitrine, Recette.POITRINE[1], Recette.POITRINE[2]) or not dans(m.taille, Recette.TAILLE[1], Recette.TAILLE[2])
		or not dans(m.hanches, Recette.HANCHES[1], Recette.HANCHES[2]) or m.taille > m.poitrine or m.taille > m.hanches then
		return false, "Mesures invalides."
	end
	if #r.pieces ~= #attendues then
		return false, "Pièces différentes du croquis."
	end
	for i, p in ipairs(r.pieces) do
		if type(p) ~= "table" or p.id ~= attendues[i] then
			return false, "Pièces différentes du croquis."
		end
		if type(p.tissu) ~= "string" or not Catalogue.tissu(p.tissu) then
			return false, "Tissu inconnu."
		end
		if not fini(p.x) or not fini(p.y) or not dans(p.angle, -Recette.ANGLE_MAX, Recette.ANGLE_MAX) then
			return false, "Position de pièce invalide."
		end
		if not dans(p.couture, 0, 1) then
			return false, "Note de couture invalide."
		end
	end
	local accessoires = r.accessoires or {}
	if type(accessoires) ~= "table" or #accessoires > Recette.MAX_ACCESSOIRES then
		return false, "Trop d'accessoires."
	end
	for _, a in ipairs(accessoires) do
		local def = type(a) == "table" and type(a.id) == "string" and Catalogue.accessoire(a.id)
		if not def then
			return false, "Accessoire inconnu."
		end
		local piece = type(a.piece) == "number" and r.pieces[a.piece]
		if not piece or a.piece ~= math.floor(a.piece) then
			return false, "Accessoire sur une pièce inexistante."
		end
		if a.copie ~= nil and not table.find(Patron.copies(piece.id), a.copie) then
			return false, "Copie de pièce invalide."
		end
		if def.genre == "objet" then
			if not dans(a.u, 0, 1) or not dans(a.v, 0, 1) or not dans(a.echelle, Recette.ECHELLE_MIN, Recette.ECHELLE_MAX)
				or not dans(a.angle, -360, 360) then
				return false, "Accessoire mal placé."
			end
		else
			if type(a.trajet) ~= "table" or #a.trajet < 2 or #a.trajet > Recette.MAX_POINTS_GARNITURE then
				return false, "Garniture invalide."
			end
			for _, pt in ipairs(a.trajet) do
				if type(pt) ~= "table" or not dans(pt.u, 0, 1) or not dans(pt.v, 0, 1) then
					return false, "Garniture mal placée."
				end
			end
		end
	end
	return true
end

-- Copie d'une pièce sur laquelle est posé un accessoire (la première par défaut)
function Recette.copieAccessoire(r, a)
	return a.copie or Patron.copies(r.pieces[a.piece].id)[1]
end

return Recette
