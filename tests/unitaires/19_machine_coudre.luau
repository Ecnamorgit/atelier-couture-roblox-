local MachineCoudre = U.module("MachineCoudre")
local EtatAtelier = U.module("EtatAtelier")
local Catalogue = U.module("Catalogue")
local Patron = U.module("Patron")
local Polygone = U.module("Polygone")

local ID = "corsage_droit_devant"
local segments, longueur = Patron.trajetCouture(ID)
local PAS = Catalogue.PAS_MESURE_COUTURE

-- Coud toute la pièce à 60 images par seconde ; pilote(machine) donne la direction du joueur
local function coudre(machine, pilote)
	local images = 0
	while not machine:fini() and images < 100000 do
		machine:avancer(1 / 60, pilote and pilote(machine) or 0)
		images += 1
	end
	return images
end

---------------------------------------------------------------------------
-- Départ
---------------------------------------------------------------------------
local m = MachineCoudre.nouvelle(ID, 1)
local e0 = m:etat()
U.verifier(e0.segment == 1 and e0.nbSegments == #segments and e0.avance == 0 and e0.ecart == 0, "départ : début de la première couture")
U.verifier(U.proche(e0.point.x, segments[1].a.x) and U.proche(e0.point.y, segments[1].a.y), "l'aiguille part du début du pointillé")
local l1 = Polygone.longueur(segments[1])
U.verifier(U.proche(e0.direction.x, (segments[1].b.x - segments[1].a.x) / l1) and U.proche(e0.direction.y, (segments[1].b.y - segments[1].a.y) / l1), "direction de la couture")
U.verifier(m.vitesse == "normale" and m:noteProvisoire() == nil and not m:fini(), "vitesse normale, rien de cousu")

---------------------------------------------------------------------------
-- Mesures : une tous les 0,1 dm
---------------------------------------------------------------------------
m:avancer(0.35, 0) -- DT_MAX coupe une image trop longue
U.verifier(#m.ecarts == 1 and U.proche(m:etat().avance, MachineCoudre.DT_MAX * MachineCoudre.VITESSES.normale), "une image trop longue est ramenée à DT_MAX")
for _ = 1, 2 do
	m:avancer(0.1, 0)
end
U.verifier(#m.ecarts == 3 and U.proche(m:etat().avance, 0.3), "0,3 dm cousus : 3 mesures")
U.verifier(U.proche(m.duree, 0.3), "durée : temps passé à coudre")
m:avancer(0, 1)
m:avancer(-1, 1)
m:avancer(0 / 0, 1)
U.verifier(#m.ecarts == 3 and U.proche(m.duree, 0.3), "durée nulle, négative ou invalide : rien ne bouge")
m:avancer(0.05, 0 / 0)
m:avancer(0.05, "gauche")
U.verifier(#m.ecarts == 4, "direction invalide : comptée comme nulle")

---------------------------------------------------------------------------
-- Vitesse
---------------------------------------------------------------------------
U.verifier(not m:choisirVitesse("fusee") and m.vitesse == "normale", "vitesse inconnue refusée")
U.verifier(m:choisirVitesse("lapin") and m.vitesse == "lapin", "vitesse lapin")
local avant = m:etat().avance
m:avancer(0.1, 0)
U.verifier(U.proche(m:etat().avance - avant, 0.1 * Catalogue.VITESSE_COUTURE_MAX), "le lapin coud à la vitesse maximale")

---------------------------------------------------------------------------
-- Coutures enchaînées et découd-vite
---------------------------------------------------------------------------
local c = MachineCoudre.nouvelle(ID, 2)
while c:etat().segment == 1 do
	c:avancer(1 / 60, 0.2)
end
local fin1 = #c.ecarts
U.verifier(fin1 == math.floor(l1 / PAS + 1e-9), "première couture : une mesure par 0,1 dm")
local e2 = c:etat()
U.verifier(e2.segment == 2 and e2.avance == 0 and e2.ecart == 0, "couture suivante : l'aiguille est remise sur le pointillé")
U.verifier(U.proche(e2.point.x, segments[2].a.x) and U.proche(e2.point.y, segments[2].a.y), "l'aiguille part du début de la couture suivante")
c:avancer(0.1, 0)
c:avancer(0.1, 0)
U.verifier(#c.ecarts > fin1, "la deuxième couture a commencé")
U.verifier(c:decoudre() and c:etat().segment == 2 and c:etat().avance == 0 and #c.ecarts == fin1, "découdre : la couture en cours est défaite")
U.verifier(c:decoudre() and c:etat().segment == 1 and #c.ecarts == 0 and c.parcouru == 0, "découdre au début d'une couture : la précédente est défaite")
U.verifier(not c:decoudre(), "rien à découdre au départ")
coudre(c)
U.verifier(c:fini() and c:decoudre() and not c:fini() and c:etat().segment == #segments, "découdre une pièce finie : la dernière couture est à refaire")
coudre(c)
U.verifier(c:fini(), "pièce refinie")

---------------------------------------------------------------------------
-- Dérive, pilotage, assistance
---------------------------------------------------------------------------
local function pire(machine)
	local p = 0
	for _, e in ipairs(machine.ecarts) do
		p = math.max(p, math.abs(e))
	end
	return p
end
local nombre = math.floor(longueur / PAS + 1e-9)

local libre = MachineCoudre.nouvelle(ID, 3)
coudre(libre)
U.verifier(#libre.ecarts == nombre, "pièce entière : une mesure par 0,1 dm de trajet")
U.verifier(pire(libre) > 0.1 and libre:noteProvisoire() < 0.9, "sans corriger, le tissu tire et la couture s'écarte")

local pilote = MachineCoudre.nouvelle(ID, 3)
coudre(pilote, function(machine)
	return -machine:derive(machine.parcouru) / MachineCoudre.PENTE_MAX
end)
U.verifier(pire(pilote) < 0.05 and pilote:noteProvisoire() > 0.99, "en corrigeant la dérive, la couture suit le pointillé")

local rate = MachineCoudre.nouvelle(ID, 3)
coudre(rate, function()
	return 1
end)
U.verifier(U.proche(pire(rate), Catalogue.ECART_MAX_COUTURE) and rate:noteProvisoire() < 0.05, "écart borné à 2 dm même en tirant toujours du même côté")

local aide = MachineCoudre.nouvelle(ID, 3)
aide:activerAssistance(true)
coudre(aide, function()
	return 1 -- l'assistance ignore le joueur
end)
U.verifier(pire(aide) < 1e-9 and aide:noteProvisoire() == Catalogue.PLAFOND_ASSISTANCE, "assistance : couture parfaite, note plafonnée")
local _, _, assiste = aide:releve()
U.verifier(assiste == true, "le relevé dit que l'assistance a servi")

local reprise = MachineCoudre.nouvelle(ID, 4)
reprise:avancer(0.1, 1)
reprise:avancer(0.1, 1)
reprise:activerAssistance(true)
for _ = 1, 30 do
	reprise:avancer(1 / 60, 0)
end
U.verifier(math.abs(reprise:etat().ecart) < 1e-9, "l'assistance ramène l'aiguille sur le pointillé")
reprise:activerAssistance(false)
reprise:avancer(0.1, 0)
U.verifier(select(3, reprise:releve()) == true, "l'assistance reste comptée après l'avoir coupée")
while reprise:decoudre() do
end
U.verifier(select(3, reprise:releve()) == false, "tout décousu sans assistance : elle ne compte plus")

---------------------------------------------------------------------------
-- Reproductible, et accepté par EtatAtelier aux trois vitesses
---------------------------------------------------------------------------
local a, b, autre = MachineCoudre.nouvelle(ID, 7), MachineCoudre.nouvelle(ID, 7), MachineCoudre.nouvelle(ID, 8)
coudre(a)
coudre(b)
coudre(autre)
U.verifier(a.ecarts[20] == b.ecarts[20] and a.ecarts[20] ~= autre.ecarts[20], "même graine, même dérive ; autre graine, autre dérive")

local CROQUIS = { corsage = "corsage_droit", manches = "manches_sans", col = "col_sans", jupe = "jupe_droite" }
local DISPOSITION = {
	corsage_droit_devant = { x = 2.4, y = 2.1, angle = 0 },
	corsage_droit_dos = { x = 7.2, y = 2.1, angle = 0 },
	jupe_droite_devant = { x = 2.5, y = 7.2, angle = 0 },
	jupe_droite_dos = { x = 7.5, y = 7.2, angle = 0 },
}
local etat = EtatAtelier.nouveau()
U.commander(etat, Random.new(3))
local tissus = {}
for idPiece in pairs(DISPOSITION) do
	tissus[idPiece] = "coton_blanc"
end
etat:validerCroquis(CROQUIS, tissus)
etat:acheter("coton_blanc", 12)
etat:commencerDecoupe()
for _, idPiece in ipairs(etat:piecesDuCroquis()) do
	etat:couper(idPiece, DISPOSITION[idPiece])
end
for _, idPiece in ipairs(etat:piecesDuCroquis()) do
	etat:epingler(idPiece)
end
for k, vitesse in ipairs({ "tortue", "normale", "lapin" }) do
	local idPiece = etat:piecesDuCroquis()[k]
	local machine = MachineCoudre.nouvelle(idPiece, k)
	machine:choisirVitesse(vitesse)
	coudre(machine)
	local r = etat:rendreCouture(idPiece, machine:releve())
	U.verifier(r.ok and U.proche(r.note, machine:noteProvisoire()), "relevé accepté par EtatAtelier à la vitesse " .. vitesse .. " : " .. tostring(r.erreur))
end
