-- La machine à coudre (sous-projet 8) : on fait avancer le tissu sous l'aiguille et on le fait pivoter pour suivre le
-- pointillé ; dans un angle, on s'arrête et on pivote ; l'assistance tient la ligne sans s'arrêter.
local MachineCoudre = U.module("MachineCoudre")
local EtatAtelier = U.module("EtatAtelier")
local Catalogue = U.module("Catalogue")
local Patron = U.module("Patron")

local ID = "corsage_droit_devant" -- coutures : le côté droit, le bas, le côté gauche (deux angles droits)
local segments, longueur = Patron.trajetCouture(ID)
local PAS = Catalogue.PAS_MESURE_COUTURE

---------------------------------------------------------------------------
-- Départ, avance, vitesse
---------------------------------------------------------------------------
local m = MachineCoudre.nouvelle(ID, 1)
local e0 = m:etat()
U.verifier(e0.segment == 1 and e0.nbSegments == #segments and e0.avance == 0 and e0.ecart == 0 and e0.angle == 0, "départ : début de la première couture, le tissu droit")
U.verifier(U.proche(e0.point.x, segments[1].a.x) and U.proche(e0.point.y, segments[1].a.y), "l'aiguille part du début du pointillé")
U.verifier(m.vitesse == "normale" and m:noteProvisoire() == nil and not m:fini(), "vitesse normale, rien de cousu")
m:avancer(1, true, 0)
U.verifier(U.proche(m:etat().avance, MachineCoudre.DT_MAX * MachineCoudre.VITESSES.normale, 1e-3), "une image trop longue est ramenée à DT_MAX")
m:avancer(0.1, true, 0)
m:avancer(0.1, true, 0)
local function uneParPas(machine)
	return #machine.ecarts == math.floor(machine.parcouru / PAS + 1e-9)
end
U.verifier(uneParPas(m) and #m.ecarts >= 2 and U.proche(m.duree, 0.3), "une mesure par 0,1 dm d'avance ; la durée compte le temps passé à coudre")
local mesures, parcouru = #m.ecarts, m.parcouru
m:avancer(0, true, 0)
m:avancer(-1, true, 0)
m:avancer(0 / 0, true, 0)
U.verifier(#m.ecarts == mesures and m.parcouru == parcouru and U.proche(m.duree, 0.3), "durée nulle, négative ou invalide : rien ne bouge")
m:avancer(0.1, true, 0 / 0)
U.verifier(m.parcouru > parcouru and uneParPas(m), "pivot invalide : compté comme nul")
U.verifier(not m:choisirVitesse("fusee") and m.vitesse == "normale" and m:choisirVitesse("lapin") and m.vitesse == "lapin", "vitesse inconnue refusée ; lapin")

---------------------------------------------------------------------------
-- Pivoter : sans coudre, l'aiguille plantée ; en cousant de travers, l'aiguille s'écarte
---------------------------------------------------------------------------
local p = MachineCoudre.nouvelle(ID, 2)
p:avancer(0.5, false, 1)
local apres = p:etat()
U.verifier(U.proche(apres.angle, MachineCoudre.ROTATION_MAX * MachineCoudre.DT_MAX) and apres.avance == 0 and #p.ecarts == 0 and p.duree == 0, "pivoter sans coudre : le tissu tourne (90° par seconde au plus), rien n'est cousu")
local droit, travers = MachineCoudre.nouvelle(ID, 2), MachineCoudre.nouvelle(ID, 2)
travers.angle = math.rad(30)
for _ = 1, 30 do
	droit:avancer(1 / 60, true, 0)
	travers:avancer(1 / 60, true, 0)
end
U.verifier(math.abs(droit.e) < 0.05 and travers.e > 0.2 and travers.s < droit.s, ("de travers, l'aiguille s'écarte et avance moins le long du pointillé (%.3f dm, %.3f)"):format(travers.e, droit.e))

---------------------------------------------------------------------------
-- Les angles : le pointillé tourne ; deux coutures séparées : on reprend au début, le tissu droit
---------------------------------------------------------------------------
local virage = MachineCoudre.nouvelle(ID, 3):virage(1)
U.verifier(virage ~= nil and U.proche(math.abs(virage), math.pi / 2, 1e-6), "corsage : un angle droit entre le côté et le bas")
local a = MachineCoudre.nouvelle(ID, 3)
while a:etat().segment == 1 do
	a:avancer(1 / 60, true, math.clamp(-(a.angle + 2 * a.e) * 3, -1, 1))
end
U.verifier(math.abs(math.abs(a.angle) - math.pi / 2) < 0.2, ("passé l'angle, le tissu est de travers d'un angle droit (%.0f°)"):format(math.deg(a.angle)))
local avantPivot = a.e
for _ = 1, 30 do
	a:avancer(1 / 60, true, 0)
end
U.verifier(math.abs(a.e - avantPivot) > 0.2, "qui coud sans pivoter s'écarte vite")
local separee = MachineCoudre.nouvelle("jupe_trapeze_devant", 4) -- coutures : le haut, le côté droit, puis le côté gauche
U.verifier(separee:virage(1) ~= nil and separee:virage(2) == nil, "jupe trapèze : un angle entre le haut et le côté ; le côté gauche est une couture séparée")
separee.k, separee.s, separee.e, separee.angle = 2, separee.longueurs[2] - 0.01, 0.3, 0.4
separee:avancer(1 / 60, true, 0)
local e3 = separee:etat()
U.verifier(e3.segment == 3 and math.abs(e3.ecart) < 0.005 and math.abs(e3.angle) < 0.01, "couture séparée : l'aiguille reprend au début de son pointillé, le tissu droit")

---------------------------------------------------------------------------
-- Couturières simulées (60 images par seconde) : la soigneuse corrige l'angle et l'écart, s'arrête et pivote dans les
-- angles ; la pressée coud au lapin sans s'arrêter ; les mains libres ne pivotent jamais ; l'assistée laisse faire
-- l'assistance, sans s'arrêter
---------------------------------------------------------------------------
local function couturiere(machine, facon)
	local arret, images = false, 0
	while not machine:fini() and images < 200000 do
		local voulu = math.clamp(-2 * machine.e, -0.4, 0.4)
		local rotation = if facon == "mains libres" or facon == "assistee" then 0 else math.clamp((voulu - machine.angle) * 3, -1, 1)
		local cousant = true
		if facon == "soigneuse" then
			if math.abs(machine.angle) > math.rad(20) then
				arret = true
			elseif math.abs(machine.angle - voulu) < math.rad(3) then
				arret = false -- (repart une fois tournée vers l'angle voulu, qui dépend de l'écart)
			end
			cousant = not arret
		end
		machine:avancer(1 / 60, cousant, rotation)
		images += 1
	end
	U.verifier(machine:fini(), ("la couturière %s finit la pièce %s"):format(facon, machine.idPiece))
	return machine:noteProvisoire() or 0
end
-- (le col Claudine, une seule couture courte et droite, se coud presque sans pivoter : il ne compte pas pour les mains
-- libres, qui doivent rater les pièces à angles et à courbes)
local PIECES = { "corsage_droit_devant", "manche_ballon", "jupe_trapeze_devant", "col_claudine" }
local notes = {}
for _, facon in ipairs({ "soigneuse", "pressee", "mains libres", "assistee" }) do
	local pire, total, n = 1, 0, 0
	for k, id in ipairs(PIECES) do
		if not (facon == "mains libres" and id == "col_claudine") then
			for graine = 1, 3 do
				local machine = MachineCoudre.nouvelle(id, 10 * k + graine, "coton")
				machine:choisirVitesse(if facon == "pressee" then "lapin" else "normale")
				machine:activerAssistance(facon == "assistee")
				local note = couturiere(machine, facon)
				pire, total, n = math.min(pire, note), total + note, n + 1
			end
		end
	end
	notes[facon] = { pire = pire, moyenne = total / n }
end
local resume = ("soigneuse %.2f (pire %.2f), pressée %.2f, mains libres %.2f, assistée %.2f (pire %.2f)"):format(notes.soigneuse.moyenne, notes.soigneuse.pire, notes.pressee.moyenne, notes["mains libres"].moyenne, notes.assistee.moyenne, notes.assistee.pire)
U.verifier(notes.soigneuse.pire >= 0.9, "la soigneuse coud à 90 % au moins (" .. resume .. ")")
U.verifier(notes.pressee.moyenne <= notes.soigneuse.moyenne - 0.15, "la pressée coud nettement moins bien (" .. resume .. ")")
U.verifier(notes["mains libres"].moyenne <= 0.35, "les mains libres ratent les pièces à angles et à courbes (" .. resume .. ")")
-- (relecture) la soie, qui glisse, se coud aussi à la main : la soigneuse y coud à 90 % au moins
local pireSoie = 1
for k, id in ipairs(PIECES) do
	for graine = 1, 3 do
		pireSoie = math.min(pireSoie, couturiere(MachineCoudre.nouvelle(id, 10 * k + graine, "soie"), "soigneuse"))
	end
end
U.verifier(pireSoie >= 0.9, ("la soigneuse coud la soie à 90 %% au moins (pire %.2f)"):format(pireSoie))
U.verifier(notes.assistee.moyenne >= 0.6 and notes.assistee.pire >= 0.5 and notes.assistee.moyenne <= Catalogue.PLAFOND_ASSISTANCE + 1e-9 and notes.assistee.moyenne < notes.soigneuse.moyenne, "l'assistance aide sans tout faire : 60 à 85 % en moyenne sans s'arrêter (" .. resume .. ")")

-- L'assistance ne s'arrête pas dans les angles : qui coud sans s'arrêter y rate encore des points
local assistee = MachineCoudre.nouvelle(ID, 21, "coton")
assistee:activerAssistance(true)
couturiere(assistee, "assistee")
local horsLigne = 0
for _, e in ipairs(assistee.ecarts) do
	horsLigne += if math.abs(e) > 0.15 then 1 else 0
end
U.verifier(horsLigne >= 5, ("assistée sans s'arrêter : des points hors de la ligne dans les angles (%d)"):format(horsLigne))

-- Les tissus qui glissent tirent davantage : les mains libres s'écartent plus vite sur la soie que sur le coton
local function ecartLibre(matiere)
	local machine = MachineCoudre.nouvelle("jupe_droite_devant", 5, matiere)
	for _ = 1, 120 do
		machine:avancer(1 / 60, true, 0)
	end
	return math.abs(machine.angle)
end
U.verifier(MachineCoudre.GLISSE.soie > MachineCoudre.GLISSE.coton and ecartLibre("soie") > ecartLibre("coton") and MachineCoudre.nouvelle(ID, 1, "inconnue").glisse == 1, "la soie glisse plus que le coton ; une matière inconnue, comme d'habitude")

---------------------------------------------------------------------------
-- Découd-vite, assistance comptée
---------------------------------------------------------------------------
local c = MachineCoudre.nouvelle(ID, 6)
while c:etat().segment == 1 do
	c:avancer(1 / 60, true, 0)
end
local fin1 = #c.ecarts
for _ = 1, 20 do
	c:avancer(1 / 60, true, 0)
end
local angleDebut2 = c.debuts[2].angle
U.verifier(c:decoudre() and c:etat().segment == 2 and c:etat().avance == 0 and #c.ecarts == fin1 and c.angle == angleDebut2, "découdre : la couture en cours est défaite, on reprend à l'angle")
U.verifier(c:decoudre() and c:etat().segment == 1 and #c.ecarts == 0 and c.parcouru == 0 and c.angle == 0 and c.e == 0, "découdre au début d'une couture : la précédente est défaite")
U.verifier(not c:decoudre(), "rien à découdre au départ")
local aide = MachineCoudre.nouvelle(ID, 7)
aide:activerAssistance(true)
aide:avancer(0.1, true, 0)
aide:activerAssistance(false)
aide:avancer(0.1, true, 0)
U.verifier(select(3, aide:releve()) == true, "l'assistance reste comptée après l'avoir coupée")
while aide:decoudre() do
end
U.verifier(select(3, aide:releve()) == false, "tout décousu sans assistance : elle ne compte plus")

---------------------------------------------------------------------------
-- Reproductible, et accepté par EtatAtelier aux trois vitesses
---------------------------------------------------------------------------
local r1, r2, autre = MachineCoudre.nouvelle(ID, 8), MachineCoudre.nouvelle(ID, 8), MachineCoudre.nouvelle(ID, 9)
couturiere(r1, "mains libres")
couturiere(r2, "mains libres")
couturiere(autre, "mains libres")
U.verifier(r1.ecarts[20] == r2.ecarts[20] and r1.ecarts[20] ~= autre.ecarts[20] and #r1.ecarts == math.floor(longueur / PAS + 1e-9), "même graine, même tirage ; autre graine, autre tirage ; une mesure par 0,1 dm")

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
	local machine = MachineCoudre.nouvelle(idPiece, k, "coton")
	machine:choisirVitesse(vitesse)
	couturiere(machine, "soigneuse")
	local r = etat:rendreCouture(idPiece, machine:releve())
	U.verifier(r.ok and U.proche(r.note, machine:noteProvisoire()), "relevé accepté par EtatAtelier à la vitesse " .. vitesse .. " : " .. tostring(r.erreur))
end
