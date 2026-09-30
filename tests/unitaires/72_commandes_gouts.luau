-- Sous-projet 7 : les commandes demandent les nouvelles étiquettes au fil du prestige (occasions au 2, matière au 3,
-- traits au 4), jamais deux exigences contradictoires ; chaque cliente a son occasion préférée.
local Commandes = U.module("Commandes")
local Catalogue = U.module("Catalogue")
local Clientes = U.module("Clientes")
local Deblocages = U.module("Deblocages")
local Progression = U.module("Progression")

---------------------------------------------------------------------------
-- Chaque cliente a une occasion préférée ; les trois occasions ont leurs clientes
---------------------------------------------------------------------------
local parOccasion = {}
for _, c in ipairs(Clientes.LISTE) do
	U.verifier(table.find(Catalogue.OCCASIONS, c.occasion) ~= nil, c.id .. " : une occasion préférée")
	parOccasion[c.occasion] = (parOccasion[c.occasion] or 0) + 1
end
U.verifier(parOccasion.journee and parOccasion.soiree and parOccasion.travail, "les trois occasions ont leurs clientes")

---------------------------------------------------------------------------
-- Garde : au prestige où une commande peut la demander, chaque étiquette atteint 60 avec ce qui est ouvert (par le
-- prestige, et par une amitié de niveau 2 avec chaque cliente déjà venue : trois belles robes)
---------------------------------------------------------------------------
local SEUILS = Progression.SEUILS_PRESTIGE
local function ouvertsAu(p)
	local clientes = {}
	for _, c in ipairs(Clientes.LISTE) do
		if c.prestige <= p then
			clientes[c.id] = { amitie = Progression.SEUILS_AMITIE[3] }
		end
	end
	return Deblocages.ouverts({ prestige = SEUILS[p], clientes = clientes })
end
local manquees = {}
for _, liste in ipairs({ Catalogue.OCCASIONS, Catalogue.TRAITS }) do
	for _, id in ipairs(liste) do
		local p = Commandes.PRESTIGE_ETIQUETTES[id]
		local e = if table.find(Catalogue.OCCASIONS, id) then { type = "occasion", occasion = id, valeur = 60 } else { type = "trait", trait = id, valeur = 60 }
		if not (p and p >= 2 and p <= 8 and Commandes.realisable({ e }, ouvertsAu(p))) then
			table.insert(manquees, id .. " (" .. tostring(p) .. ")")
		end
	end
end
U.verifier(#manquees == 0, "au prestige où elle se demande, chaque étiquette atteint 60 (manquées : " .. table.concat(manquees, ", ") .. ")")

---------------------------------------------------------------------------
-- Interdits : deux traits d'un même groupe, une matière contraire à Légère ou Chaude, Travaillée et un « au plus »
---------------------------------------------------------------------------
local function trait(t)
	return { type = "trait", trait = t, valeur = 30 }
end
local function matiere(m)
	return { type = "matiere", matiere = m }
end
local interdits = {
	{ trait("legere"), trait("chaude") }, { trait("sobre"), trait("travaillee") }, { trait("unie"), trait("a_motifs") },
	{ trait("fleurie"), trait("unie") }, { trait("legere"), matiere("velours") }, { matiere("organza"), trait("chaude") },
	{ trait("travaillee"), { type = "max", style = "chic", valeur = 20 } },
}
local permises = {
	{ trait("legere"), matiere("coton") }, { trait("chaude"), matiere("laine") }, { trait("sobre"), { type = "max", style = "chic", valeur = 20 } },
	{ trait("unie"), { type = "occasion", occasion = "soiree", valeur = 30 } }, { trait("legere"), trait("sobre") },
}
local fautes = 0
for _, paire in ipairs(interdits) do
	if Commandes.compatibles(paire[1], paire[2]) or Commandes.compatibles(paire[2], paire[1]) then
		fautes += 1
	end
end
for _, paire in ipairs(permises) do
	if not (Commandes.compatibles(paire[1], paire[2]) and Commandes.compatibles(paire[2], paire[1])) then
		fautes += 1
	end
end
U.verifier(fautes == 0, "interdits : sept paires écartées, cinq permises (" .. fautes .. " en défaut)")

---------------------------------------------------------------------------
-- Au fil du prestige : rien avant son heure, jamais d'interdit, toujours réalisable ; tout finit par se demander ;
-- la cliente demande surtout son occasion
---------------------------------------------------------------------------
local avant, contraires, irrealisables = {}, 0, 0
local vus = {}
local siennes, occasionsDemandees = 0, 0
for niveau = 1, 8 do
	local progres = { prestige = SEUILS[niveau], clientes = {} }
	local ouverts = Deblocages.ouverts(progres)
	local rng = Random.new(720 + niveau)
	for _, c in ipairs(Clientes.LISTE) do
		if c.prestige <= niveau then
			for _ = 1, 12 do
				local commande = Commandes.generer(rng, c, progres)
				local ex = commande.exigences
				if not Commandes.realisable(ex, ouverts) then
					irrealisables += 1
				end
				for i, e in ipairs(ex) do
					vus[e.type] = true
					local id = e.occasion or e.trait
					if (id and niveau < Commandes.PRESTIGE_ETIQUETTES[id]) or (e.type == "matiere" and niveau < Commandes.PRESTIGE_MATIERE) then
						table.insert(avant, ("%s au prestige %d"):format(id or e.matiere, niveau))
					end
					if e.type == "occasion" and niveau >= 3 then
						occasionsDemandees += 1
						siennes += if e.occasion == c.occasion then 1 else 0
					end
					for j = i + 1, #ex do
						if not Commandes.compatibles(e, ex[j]) then
							contraires += 1
						end
					end
				end
			end
		end
	end
end
U.verifier(#avant == 0, "aucune étiquette demandée avant son prestige (en défaut : " .. table.concat(avant, ", ", 1, math.min(#avant, 5)) .. ")")
U.verifier(contraires == 0 and irrealisables == 0, ("jamais d'interdit (%d), toujours réalisable avec ce qui est ouvert (%d)"):format(contraires, irrealisables))
U.verifier(vus.occasion and vus.matiere and vus.trait, "occasions, matières et traits finissent par être demandés")
U.verifier(occasionsDemandees > 0 and siennes / occasionsDemandees >= 0.5, ("la cliente demande surtout son occasion (%d sur %d)"):format(siennes, occasionsDemandees))

-- (relecture du plan 21) Une étiquette inconnue, d'une fiche mal écrite : irréalisable, sans erreur
local okOccasion, occasionInconnue = pcall(Commandes.realisable, { { type = "occasion", occasion = "bal", valeur = 20 } })
local okStyle, styleInconnu = pcall(Commandes.realisable, { { type = "min", style = "punk", valeur = 20 } })
U.verifier(okOccasion and okStyle and not occasionInconnue and not styleInconnu, "une occasion ou un style inconnus : irréalisables, sans erreur")
