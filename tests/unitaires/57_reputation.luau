-- Sous-projet 5 : l'avis de la cliente en étoiles, les titres de la réputation, le rang de la couturière. Ce n'est
-- qu'une autre façon de montrer ce que les règles disaient déjà (aucun gain n'en dépend).
local Progression = U.module("Progression")

-- Étoiles : refusée, une ; acceptée, deux, et une de plus à 60, 80 et 90 % de qualité
U.verifier(Progression.etoiles(false, 1) == 1, "robe refusée : une étoile, même parfaite")
U.verifier(Progression.etoiles(true, 0) == 2 and Progression.etoiles(true, 0.59) == 2, "robe acceptée : deux étoiles au moins")
U.verifier(Progression.etoiles(true, 0.6) == 3 and Progression.etoiles(true, 0.79) == 3, "60 % : trois étoiles")
U.verifier(Progression.etoiles(true, 0.8) == 4 and Progression.etoiles(true, 0.89) == 4, "80 % : quatre étoiles")
U.verifier(Progression.etoiles(true, 0.9) == 5 and Progression.etoiles(true, 1) == 5, "90 % : cinq étoiles")
U.verifier(Progression.etoiles(true, 0.8 - 1e-12) == 4, "à l'arrondi près, comme le point d'amitié de 80 %")
do -- Les étoiles suivent l'amitié : quatre étoiles ou plus, c'est le point d'amitié de plus
	local accordes = 0
	for q = 0, 100 do
		local qualite = q / 100
		if (Progression.etoiles(true, qualite) >= 4) == (Progression.gainAmitie(true, qualite) == 3) then
			accordes += 1
		end
	end
	U.verifier(accordes == 101, "quatre étoiles et plus : exactement quand la robe vaut un point d'amitié de plus")
end

-- La qualité affichée ne contredit jamais les étoiles ni le jugement : arrondie vers le bas (79,9 % : « 79 % »)
do
	local UiKit = U.module("UiKit")
	U.verifier(UiKit.pourcent(0.7999) == 79 and UiKit.pourcent(0.8 - 1e-12) == 80 and UiKit.pourcent(1) == 100 and UiKit.pourcent(0) == 0, "le pourcentage affiché, arrondi vers le bas (à l'arrondi près)")
	-- (la même marge que les étoiles : juste sous 80 % de plus que 1e-9, trois étoiles et « 79 % » ; de moins, quatre et « 80 % »)
	U.verifier(UiKit.pourcent(0.8 - 5e-9) == 79 and Progression.etoiles(true, 0.8 - 5e-9) == 3 and UiKit.pourcent(0.8 - 5e-10) == 80 and Progression.etoiles(true, 0.8 - 5e-10) == 4, "la même marge d'arrondi que les étoiles")
	local accords = 0
	for q = 0, 10000 do
		local qualite = q / 10000
		local n, affiche = Progression.etoiles(true, qualite), UiKit.pourcent(qualite)
		if (n >= 3) == (affiche >= 60) and (n >= 4) == (affiche >= 80) and (n >= 5) == (affiche >= 90) then
			accords += 1
		end
	end
	U.verifier(accords == 10001, "les étoiles et le pourcentage affiché sont toujours d'accord (" .. accords .. ")")
end

-- Réputation : un titre par niveau de prestige (1 à 8), tous différents
U.verifier(#Progression.TITRES_REPUTATION == #Progression.SEUILS_PRESTIGE, "un titre par niveau de prestige")
U.verifier(Progression.titreReputation(1) == "Inconnue" and Progression.titreReputation(3) == "Appréciée" and Progression.titreReputation(8) == "Légendaire", "Inconnue au début, Légendaire au plus haut")
do
	local vus, doubles = {}, 0
	for _, t in ipairs(Progression.TITRES_REPUTATION) do
		doubles += if vus[t] then 1 else 0
		vus[t] = true
	end
	U.verifier(doubles == 0, "des titres tous différents")
end
U.verifier(Progression.titreReputation(Progression.niveauPrestige(Progression.SEUILS_PRESTIGE[5])) == Progression.TITRES_REPUTATION[5], "le titre suit le niveau de prestige")

-- Rang : selon les robes livrées ou vendues, le rang et le suivant
local rang, suivant = Progression.rang(0)
U.verifier(rang.nom == "Débutante" and suivant.nom == "Apprentie" and suivant.robes == 5, "aucune robe : débutante ; apprentie à 5 robes")
rang = Progression.rang(4)
U.verifier(rang.nom == "Débutante", "4 robes : encore débutante")
rang, suivant = Progression.rang(5)
U.verifier(rang.nom == "Apprentie" and suivant.nom == "Couturière" and suivant.robes == 15, "5 robes : apprentie ; couturière à 15")
rang = Progression.rang(30)
U.verifier(rang.nom == "Première main", "30 robes : première main")
rang, suivant = Progression.rang(500)
U.verifier(rang.nom == "Maîtresse couturière" and suivant == nil, "60 robes et plus : maîtresse couturière, au plus haut")
U.verifier(Progression.texteRang(7) == "Apprentie — 7 robes (Couturière à 15)", "le rang en clair : son nom, les robes, le suivant")
U.verifier(Progression.texteRang(1) == "Débutante — 1 robe (Apprentie à 5)", "une robe : au singulier")
U.verifier(Progression.texteRang(64) == "Maîtresse couturière — 64 robes", "au plus haut : pas de rang suivant")
