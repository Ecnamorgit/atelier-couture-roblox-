-- Déblocages (sous-projet 2) : ce qui est fermé au départ, et ce qui l'ouvre. Chaque élément du catalogue a au
-- plus une condition : un niveau de prestige, un niveau d'amitié avec une cliente, ou (sous-projet 3) un
-- événement du quartier qui a eu lieu (ses souvenirs). Rien n'est sauvegardé : tout se déduit du prestige, des
-- amitiés et de l'histoire (un changement du tableau s'applique aux parties existantes).
local dossier = script.Parent
local Catalogue = require(dossier:WaitForChild("Catalogue"))
local Clientes = require(dossier:WaitForChild("Clientes"))
local Progression = require(dossier:WaitForChild("Progression"))
local Histoire = require(dossier:WaitForChild("Histoire"))

local Deblocages = {}

-- Prestige qui ouvre chaque matière (cotons, lins et jute sont ouverts au départ) et des décorations
Deblocages.PRESTIGE_MATIERES = { laine = 2, satin = 3, velours = 4, soie = 5, crepe = 6, organza = 6, brocart = 7, tulle = 8 }
Deblocages.PRESTIGE_ACCESSOIRES = {
	ruban_noir = 2,
	dentelle_noire = 3,
	noeud_dore = 5,
	perle_noire = 5,
	papillon_soie = 6,
	galon_argent = 6,
	broche_etoile = 7,
	ruban_velours = 7,
	couronne_fleurs = 8,
	dentelle_doree = 8,
}
-- Prestige qui ouvre des variantes (sous-projet 4) ; cache-cœur, bustier, trois-quarts et col marin s'ouvrent à
-- l'amitié des nouvelles clientes (Clientes)
Deblocages.PRESTIGE_VARIANTES = {
	manches_courtes = 6,
	jupe_crayon = 7,
}
Deblocages.GENRES = { "variantes", "tissus", "accessoires" }

-- CONDITIONS[genre][id] = { prestige = n }, { cliente = id, amitie = n } ou { evenement = id } ; absent : ouvert
-- au départ
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
for id, niveau in pairs(Deblocages.PRESTIGE_VARIANTES) do
	CONDITIONS.variantes[id] = { prestige = niveau }
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
for _, ev in ipairs(Histoire.EVENEMENTS) do
	CONDITIONS.accessoires[ev.souvenir] = { evenement = ev.id }
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

-- progres : { prestige = points, clientes = { [id] = { amitie = points } }, histoire = { faites } } (l'état de
-- l'atelier convient)
function Deblocages.ouvert(progres, genre, id)
	local c = CONDITIONS[genre][id]
	if not c then
		return true
	end
	if c.evenement then
		return Histoire.aEuLieu(progres, c.evenement)
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
	elseif c.evenement then
		return "Souvenir d'un événement du quartier" -- (sans dire lequel : l'histoire n'est pas dévoilée)
	end
	return ("Amitié %s : %d"):format(deCliente(c.cliente), c.amitie)
end

-- Le refus d'un élément fermé : « Pas encore ouvert : Soie rouge (Prestige 5). »
function Deblocages.message(genre, id)
	return ("Pas encore ouvert : %s (%s)."):format(Deblocages.nom(genre, id), Deblocages.raison(genre, id))
end

-- Ce que l'amitié d'une cliente ouvrira ensuite : { niveau, nom }, ou nil si tout ce qu'elle ouvre l'est déjà
function Deblocages.prochainDeCliente(id, points)
	local cliente = Clientes.get(id)
	local niveau = Progression.niveauAmitie(points)
	for _, k in ipairs({ 2, 4 }) do
		local d = cliente.deblocages[k]
		if d and k > niveau then
			return { niveau = k, nom = if d.variante then Deblocages.nom("variantes", d.variante) else Deblocages.nom("accessoires", d.accessoire) }
		end
	end
	return nil
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

-- Tout ce que le prestige et l'amitié ouvrent est-il ouvert ? (Les souvenirs viennent de l'histoire, à part.)
function Deblocages.toutOuvert(progres)
	for _, genre in ipairs(Deblocages.GENRES) do
		for id, c in pairs(CONDITIONS[genre]) do
			if not c.evenement and not Deblocages.ouvert(progres, genre, id) then
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

local MATIERES = {
	laine = "les laines",
	satin = "les satins",
	velours = "les velours",
	soie = "les soies",
	crepe = "les crêpes",
	organza = "les organzas",
	brocart = "les brocarts",
	tulle = "les tulles",
}

-- Ce qui vient de s'ouvrir, en une ligne : les tissus d'une même matière ensemble (« les satins (4), Dentelle
-- noire »)
function Deblocages.resume(nouveaux)
	local parMatiere, ordre, morceaux = {}, {}, {}
	for _, n in ipairs(nouveaux) do
		if n.genre == "tissus" then
			local m = Catalogue.tissu(n.id).matiere
			if not parMatiere[m] then
				parMatiere[m] = {}
				table.insert(ordre, { matiere = m })
			end
			table.insert(parMatiere[m], n.nom)
		end
	end
	for _, n in ipairs(nouveaux) do
		if n.genre == "variantes" then
			table.insert(morceaux, n.nom)
		end
	end
	for _, o in ipairs(ordre) do
		local noms = parMatiere[o.matiere]
		table.insert(morceaux, if #noms > 1 then ("%s (%d)"):format(MATIERES[o.matiere] or o.matiere, #noms) else noms[1])
	end
	for _, n in ipairs(nouveaux) do
		if n.genre == "accessoires" then
			table.insert(morceaux, n.nom)
		end
	end
	return table.concat(morceaux, ", ")
end

return Deblocages
