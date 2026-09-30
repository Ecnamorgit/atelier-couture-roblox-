local Vignettes = U.module("Vignettes")

-- Croquis du carnet (sous-projet 5) : gardé en cache, les plus récents seulement (ils occupent la mémoire des images)
do
	local Pixels = U.module("Pixels")
	local croquis = { corsage = "corsage_droit", manches = "manches_sans", col = "col_sans", jupe = "jupe_droite" }
	local peints = 0
	local peindre = Pixels.croquis
	Pixels.croquis = function(...)
		peints += 1
		return peindre(...)
	end
	local premier = Vignettes.croquis(croquis, {}, 100, 130)
	U.verifier(premier ~= nil and premier.statique and Vignettes.croquis(croquis, {}, 100, 130) == premier and peints == 1, "croquis peint une fois, puis gardé")
	for _, id in ipairs({ "coton_blanc", "coton_rose_pois", "lin_naturel", "lin_bleu", "coton_bleu_carreaux", "lin_noir", "coton_jaune_fleurs" }) do
		Vignettes.croquis(croquis, { jupe = id }, 100, 130)
	end
	Vignettes.croquis(croquis, {}, 100, 130)
	U.verifier(peints == 9, "après sept autres croquis, le premier est repeint : on ne garde que les derniers (" .. peints .. " peints)")
	-- Un croquis revu repasse en tête : il reste gardé tant qu'il est parmi les derniers vus
	for _, id in ipairs({ "coton_blanc", "coton_rose_pois", "lin_naturel", "lin_bleu", "coton_bleu_carreaux" }) do
		Vignettes.croquis(croquis, { jupe = id }, 100, 130)
	end
	Vignettes.croquis(croquis, {}, 100, 130) -- revu : en tête
	peints = 0
	for _, id in ipairs({ "lin_noir", "coton_jaune_fleurs", "coton_blanc" }) do
		Vignettes.croquis(croquis, { jupe = id }, 100, 130)
	end
	Vignettes.croquis(croquis, {}, 100, 130)
	U.verifier(peints == 3, "un croquis revu repasse en tête et reste gardé : seuls les trois nouveaux sont peints (" .. peints .. " peints)")
	Pixels.croquis = peindre
end

-- Mémoire des images pleine : rien, sans erreur ; on réessaie quelques secondes plus tard
M.budget.images = 0
U.verifier(Vignettes.silhouette("jupe_droite_devant") == nil and Vignettes.motif("coton_blanc") == nil, "mémoire des images pleine : pas d'image, sans erreur")
M.budget.images = 64
U.verifier(Vignettes.silhouette("jupe_droite_devant") == nil, "juste après un échec, on n'insiste pas")
M.avancer(Vignettes.ESSAI_APRES + 0.5)
local silhouette = Vignettes.silhouette("jupe_droite_devant")
U.verifier(silhouette ~= nil and silhouette.statique, "quelques secondes plus tard, on réessaie : silhouette")
U.verifier(Vignettes.silhouette("jupe_droite_devant") == silhouette, "réussie : gardée en cache")
local motif = Vignettes.motif("coton_blanc")
U.verifier(motif ~= nil and motif.statique, "motif obtenu au nouvel essai")
