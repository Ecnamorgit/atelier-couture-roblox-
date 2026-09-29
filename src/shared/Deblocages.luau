-- Déblocages (sous-projet 2) : ce qui est fermé au départ, et ce qui l'ouvre. Chaque élément du catalogue a au
-- plus une condition : un niveau de prestige, ou un niveau d'amitié avec une cliente. Rien n'est sauvegardé :
-- tout se déduit du prestige et des amitiés (un changement du tableau s'applique aux parties existantes).
local dossier = script.Parent
local Catalogue = require(dossier:WaitForChild("Catalogue"))
local Clientes = require(dossier:WaitForChild("Clientes"))
local Progression = require(dossier:WaitForChild("Progression"))

local Deblocages = {}

-- Prestige qui ouvre chaque matière (cotons et lins sont ouverts au départ) et deux garnitures
Deblocages.PRESTIGE_MATIERES = { laine = 2, satin = 3, velours = 4, soie = 5 }
Deblocages.PRESTIGE_ACCESSOIRES = { ruban_noir = 2, dentelle_noire = 3 }
Deblocages.GENRES = { "variantes", "tissus", "accessoires" }

-- CONDITIONS[genre][id] = { prestige = n } ou { cliente = id, amitie = n } ; absent : ouvert au départ
local CONDITIONS = { variantes = {}, tissus = {}, accessoires = {} }
for _, t in ipairs(Catalogue.Tissus) do
	local niveau = Deblocages.PRESTIGE_MATIERES[t.matiere]
	if niveau then
		CONDITIONS.tissus[t.id] = { prestige = niveau }
	end
end
for id, niveau in pairs(Deblocages.PRESTIGE_ACCESSOIRES) do
	CONDITIONS.accessoires[id] = { prestige = niveau }
end
for _, c in ipairs(Clientes.LISTE) do
	for niveau, d in pairs(c.deblocages) do
		if d.variante then
			CONDITIONS.variantes[d.variante] = { cliente = c.id, amitie = niveau }
		else
			CONDITIONS.accessoires[d.accessoire] = { cliente = c.id, amitie = niveau }
		end
	end
end
Deblocages.CONDITIONS = CONDITIONS

local NOMS = {
	variantes = function(id)
		local v = Catalogue.variante(id)
		return v and v.nom
	end,
	tissus = function(id)
		local t = Catalogue.tissu(id)
		return t and t.nom
	end,
	accessoires = function(id)
		local a = Catalogue.accessoire(id)
		return a and a.nom
	end,
}

-- Le nom affiché d'un élément du catalogue (« Jupe Ample froncée », « Laine bordeaux », « Ruban noir »)
function Deblocages.nom(genre, id)
	local nom = NOMS[genre](id)
	if genre == "variantes" and nom then
		local v = Catalogue.variante(id)
		local suite = utf8.offset(nom, 2)
		local initiale = nom:sub(1, suite - 1)
		initiale = ({ ["À"] = "à", ["É"] = "é" })[initiale] or initiale:lower()
		return ({ corsage = "Corsage", manches = "Manches", col = "Col", jupe = "Jupe" })[v.famille] .. " " .. initiale .. nom:sub(suite)
	end
	return nom or id
end

-- progres : { prestige = points, clientes = { [id] = { amitie = points } } } (l'état de l'atelier convient)
function Deblocages.ouvert(progres, genre, id)
	local c = CONDITIONS[genre][id]
	if not c then
		return true
	end
	if c.prestige then
		return Progression.niveauPrestige(progres.prestige or 0) >= c.prestige
	end
	local fiche = progres.clientes and progres.clientes[c.cliente]
	return Progression.niveauAmitie(fiche and fiche.amitie or 0) >= c.amitie
end

-- « de Colette », « d'Hélène »
local function deCliente(id)
	local prenom = Clientes.get(id).nom:match("^(%S+)")
	local voyelle = prenom:match("^[AEIOUH]") ~= nil or prenom:sub(1, 2) == "É"
	return (voyelle and "d'" or "de ") .. prenom
end

-- Ce qu'il faut pour ouvrir : « Prestige 3 » ou « Amitié d'Hélène : 2 » ; nil si ouvert au départ
function Deblocages.raison(genre, id)
	local c = CONDITIONS[genre][id]
	if not c then
		return nil
	end
	if c.prestige then
		return ("Prestige %d"):format(c.prestige)
	end
	return ("Amitié %s : %d"):format(deCliente(c.cliente), c.amitie)
end

-- Ce qui est ouvert, par genre : { variantes = { [id] = true }, tissus = …, accessoires = … }
function Deblocages.ouverts(progres)
	local out = { variantes = {}, tissus = {}, accessoires = {} }
	for _, v in ipairs(Catalogue.Variantes) do
		out.variantes[v.id] = Deblocages.ouvert(progres, "variantes", v.id) or nil
	end
	for _, t in ipairs(Catalogue.Tissus) do
		out.tissus[t.id] = Deblocages.ouvert(progres, "tissus", t.id) or nil
	end
	for _, a in ipairs(Catalogue.Accessoires) do
		out.accessoires[a.id] = Deblocages.ouvert(progres, "accessoires", a.id) or nil
	end
	return out
end

-- Tout le catalogue est-il ouvert ?
function Deblocages.toutOuvert(progres)
	for _, genre in ipairs(Deblocages.GENRES) do
		for id in pairs(CONDITIONS[genre]) do
			if not Deblocages.ouvert(progres, genre, id) then
				return false
			end
		end
	end
	return true
end

-- Ce qui s'est ouvert entre deux moments (avant, apres : comme pour ouvert) : liste de { genre, id, nom },
-- variantes, puis tissus, puis accessoires, dans l'ordre du catalogue
function Deblocages.nouveaux(avant, apres)
	local out = {}
	local listes = { variantes = Catalogue.Variantes, tissus = Catalogue.Tissus, accessoires = Catalogue.Accessoires }
	for _, genre in ipairs(Deblocages.GENRES) do
		for _, e in ipairs(listes[genre]) do
			if CONDITIONS[genre][e.id] and Deblocages.ouvert(apres, genre, e.id) and not Deblocages.ouvert(avant, genre, e.id) then
				table.insert(out, { genre = genre, id = e.id, nom = Deblocages.nom(genre, e.id) })
			end
		end
	end
	return out
end

return Deblocages
