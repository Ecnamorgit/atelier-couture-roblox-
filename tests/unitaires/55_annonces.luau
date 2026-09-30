-- Les annonces de l'accueil (sous-projet 4 : « Nouveau : » s'allonge aux prestiges 6 à 8) : leur hauteur compte les
-- lignes repliées, pas seulement les retours à la ligne
local UiKit = U.module("UiKit")
local Deblocages = U.module("Deblocages")
local S = U.module("Progression").SEUILS_PRESTIGE

local nouveau6 = "Nouveau : " .. Deblocages.resume(Deblocages.nouveaux({ prestige = S[6] - 1, clientes = {} }, { prestige = S[6], clientes = {} })) .. "."
U.verifier(UiKit.lignes("Robe livrée !", 860, 18) == 1, "une ligne courte : une ligne")
U.verifier(UiKit.lignes("Robe livrée !\nPrestige : +12", 860, 18) == 2, "un retour à la ligne : deux lignes")
U.verifier(UiKit.lignes(nouveau6, 860, 18) == 2, "« Nouveau : » du prestige 6 (" .. utf8.len(nouveau6) .. " caractères) : deux lignes")
U.verifier(UiKit.lignes("Robe livrée !\n" .. nouveau6, 860, 18) == 3, "une ligne courte et une longue : trois lignes")
-- Au pire (niveau de prestige, niveau d'amitié et lettre arrivée ensemble), l'annonce passe en 14 px pour laisser la
-- place au courrier : jamais plus haute que quatre lignes de 18 px
local pire = table.concat({
	"Apolline est enchantée : « Elle est si belle que je vais lui écrire un sonnet. » +128 pièces d'or.",
	"Acompte de 23 déjà reçu · Amitié d'Apolline : +3 (niveau 2 !) · Prestige : +21 (niveau 6 !)",
	nouveau6 .. " Et encore : la jupe crayon et le cache-cœur.",
	"Une lettre de Colette est arrivée.",
}, "\n")
local taille, hauteur = UiKit.mesureAnnonce("Robe livrée !", 860)
U.verifier(taille == 18 and hauteur == 26, "annonce courte : 18 px, une ligne")
taille, hauteur = UiKit.mesureAnnonce(pire, 860)
U.verifier(taille == 14 and hauteur <= 4 * 24 + 2, ("annonce au pire cas : 14 px, %d px de haut (98 au plus)"):format(hauteur))
