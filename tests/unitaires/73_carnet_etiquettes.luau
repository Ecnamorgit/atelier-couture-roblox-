-- Sous-projet 7 : le carnet montre les jauges des étiquettes demandées et des styles de la cliente (pas seize) ; une
-- carte de tissu, ses quatre étiquettes les plus fortes ; le filtre des tissus s'étend aux occasions.
local Session = U.module("Session")
local UiKit = U.module("UiKit")
local Catalogue = U.module("Catalogue")
local Etiquettes = U.module("Etiquettes")
local EcranCarnet = U.module("EcranCarnet")

---------------------------------------------------------------------------
-- Les noms, les apports d'un tissu
---------------------------------------------------------------------------
local sansNom = {}
for _, liste in ipairs({ Catalogue.STYLES, Catalogue.OCCASIONS, Catalogue.TRAITS }) do
	for _, cle in ipairs(liste) do
		if type(Etiquettes.nom(cle)) ~= "string" then
			table.insert(sansNom, cle)
		end
	end
end
U.verifier(#sansNom == 0 and Etiquettes.nom("soiree") == "Soirée" and Etiquettes.nom("a_motifs") == "À motifs", "chaque étiquette a son nom")
local function premieres(idTissu)
	local noms = {}
	for k, a in ipairs(Etiquettes.apportsTissu(idTissu)) do
		if k <= 4 then
			table.insert(noms, a.cle)
		end
	end
	return table.concat(noms, ",")
end
U.verifier(premieres("organza_blanc") == "legere,soiree,romantique,mignon", "organza blanc : Légère, Soirée, Romantique, Mignon (" .. premieres("organza_blanc") .. ")")
U.verifier(premieres("laine_noire") == "chaude,travail,gothique,chic", "laine noire : Chaude, Travail, Gothique, Chic (" .. premieres("laine_noire") .. ")")
U.verifier(premieres("crepe_noir") == "elegant,chic,travail,soiree", "crêpe noir (ni légère ni chaude ; à égalité, le style d'abord) : Élégant, Chic, Travail, Soirée (" .. premieres("crepe_noir") .. ")")

---------------------------------------------------------------------------
-- La fiche : les jauges demandées, puis les styles de la cliente ; une robe libre : les six styles
---------------------------------------------------------------------------
local session = Session.nouvelle(22)
U.commander(session)
local etat = session.etat
etat.commande.cliente = "colette" -- (romantique et mignon)
etat.commande.exigences = {
	{ type = "min", style = "romantique", valeur = 30 },
	{ type = "occasion", occasion = "soiree", valeur = 40 },
	{ type = "trait", trait = "legere", valeur = 50 },
}
local function contexte()
	local fenetre = UiKit.creer("Frame", { Name = "Fenetre", Size = UDim2.fromOffset(900, 560) })
	local contenu = UiKit.creer("Frame", { Name = "Contenu", Size = UDim2.fromOffset(860, 466), Parent = fenetre })
	return { UiKit = UiKit, session = session, contenu = contenu, fenetre = fenetre, message = function() end, refus = function() end }
end
local function jauges(droite)
	local liste = {}
	for _, d in ipairs(droite:GetChildren()) do
		if d.Name:sub(1, 6) == "Jauge_" then
			table.insert(liste, d)
		end
	end
	table.sort(liste, function(a, b)
		return a.Position.Y.Offset < b.Position.Y.Offset
	end)
	local noms = {}
	for _, j in ipairs(liste) do
		table.insert(noms, (j.Name:gsub("^Jauge_", "")))
	end
	return table.concat(noms, ","), liste
end
local ctx = contexte()
local fermer = EcranCarnet(ctx)
local droite = ctx.contenu.Droite
local ordre, liste = jauges(droite)
U.verifier(ordre == "romantique,soiree,legere,mignon", "la fiche : les trois étiquettes demandées, puis le second style de la cliente (" .. ordre .. ")")
local cibles = 0
for _, j in ipairs(liste) do
	cibles += if j:FindFirstChild("Cible") then 1 else 0
end
U.verifier(cibles == 3 and droite.NomJauge_soiree.Text == "Soirée" and droite.NomJauge_legere.Text == "Légère", "un repère sur chaque jauge demandée, et leurs noms")
U.verifier(droite.Jauge_soiree.Plage.Size.X.Scale > 0 and droite.Jauge_legere.Plage.Size.X.Scale > 0, "les jauges d'occasion et de trait montrent ce que les tissus peuvent donner")

---------------------------------------------------------------------------
-- Le choix du tissu : cartes à quatre étiquettes, filtre par occasion
---------------------------------------------------------------------------
M.avancer(0.5)
droite.Parent.Page.ToutEnUnTissu.Activated:Fire()
local choix = ctx.contenu:FindFirstChild("ChoixTissu")
local function cartes()
	local out = {}
	for _, c in ipairs(choix.Grille:GetChildren()) do
		if c.Name:sub(1, 6) == "Tissu_" then
			out[c.Name:sub(7)] = c
		end
	end
	return out
end
local toutes = cartes()
local n = 0
for _ in pairs(toutes) do
	n += 1
end
U.verifier(choix ~= nil and n == #Catalogue.Tissus, "le choix du tissu montre tous les tissus (" .. n .. ")")
local texteOrganza = toutes.organza_blanc and toutes.organza_blanc:FindFirstChild("Etiquettes")
U.verifier(texteOrganza ~= nil and texteOrganza.Text == "18 po/m · Légère, Soirée, Romantique, Mignon", "organza blanc : « " .. (texteOrganza and texteOrganza.Text or "?") .. " »")
local texteCoton = toutes.coton_blanc.Etiquettes.Text
U.verifier(texteCoton == "4 po/m · Journée, Légère, Décontracté, Travail", "coton blanc : « " .. texteCoton .. " »")
M.avancer(0.5)
choix.Filtre_soiree.Activated:Fire()
local soir, intrus = 0, {}
for id in pairs(cartes()) do
	soir += 1
	if (Catalogue.MATIERES[Catalogue.tissu(id).matiere].occasion.soiree or 0) == 0 then
		table.insert(intrus, id)
	end
end
U.verifier(soir > 0 and soir < n and #intrus == 0 and choix.Filtre_soiree.Position.Y.Offset == 40, ("filtre « Soirée », sur la seconde rangée : %d tissus de soirée (intrus : %s)"):format(soir, table.concat(intrus, ", ")))
fermer()

local libre = Session.nouvelle(23)
libre.etat.livraisons = 10
assert(libre.etat:nouvelleRobeLibre("M").ok)
session = libre
local ctxL = contexte()
local fermerL = EcranCarnet(ctxL)
U.verifier((jauges(ctxL.contenu.Droite)) == table.concat(Catalogue.STYLES, ","), "une robe libre : les six styles")
fermerL()
