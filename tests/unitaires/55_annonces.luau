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
