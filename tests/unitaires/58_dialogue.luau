-- Sous-projet 5 : l'encadré de dialogue. Tant que la fenêtre de l'atelier est ouverte, ce que dit la cliente se lit
-- dans un encadré à son nom (en haut à gauche, sous les boutons de Roblox), avec son avis en étoiles quand elle en
-- donne un ; un appui le referme jusqu'à sa prochaine parole.
local UiKit = U.module("UiKit")
local Dialogue = U.module("Dialogue")

local gui = Instance.new("ScreenGui")
local d = Dialogue.nouveau(gui, UiKit)
local cadre = gui:FindFirstChild("Dialogue")
U.verifier(cadre ~= nil and cadre:IsA("TextButton") and not cadre.Visible, "un encadré (un bouton : l'appui ne passe pas dessous), caché tant qu'elle n'a rien dit")
U.verifier(cadre.Position.X.Scale == 0 and cadre.Position.Y.Scale == 0 and cadre.Position.Y.Offset < 40, "en haut à gauche, juste sous les boutons de Roblox")

d:dire("Colette", "Bonjour ! J'aurais besoin d'une robe.")
U.verifier(cadre.Visible and cadre.Nom.Text == "Colette" and cadre.Texte.Text == "Bonjour ! J'aurais besoin d'une robe." and not cadre.Etoiles.Visible, "son nom, ses mots ; pas d'étoiles sans avis")
U.verifier(cadre.Nom.TextSize >= 14 and cadre.Texte.TextSize >= 14, "textes d'au moins 14 px")
local hauteurCourte = cadre.Size.Y.Offset
d:dire("Colette", string.rep("Une robe pour le bal des lanternes, avec des manches ballon et un col Claudine. ", 3))
U.verifier(cadre.Size.Y.Offset > hauteurCourte + 30 and cadre.Texte.Size.Y.Offset >= 3 * 16, "un long texte : l'encadré grandit (" .. cadre.Size.Y.Offset .. " px)")

-- L'avis : autant d'étoiles dorées que d'étoiles données, les autres éteintes
local function doree(k)
	return cadre.Etoiles["Etoile" .. k].TextColor3 == Dialogue.OR
end
d:dire("Colette", "Merci, elle est parfaite !", 4)
U.verifier(cadre.Etoiles.Visible and doree(1) and doree(4) and not doree(5), "quatre étoiles sur cinq")
U.verifier(cadre.Etoiles.Position.Y.Offset >= cadre.Texte.Position.Y.Offset + cadre.Texte.Size.Y.Offset and cadre.Etoiles.Position.Y.Offset + cadre.Etoiles.Size.Y.Offset <= cadre.Size.Y.Offset, "les étoiles sous le texte, dans l'encadré")
d:dire("Colette", "Ce n'est pas tout à fait ce que je voulais.", 1)
U.verifier(doree(1) and not doree(2), "une étoile au refus")

-- Fenêtre fermée : l'encadré se cache (la bulle prend le relais) ; rouverte : il revient
d:montrer(false)
U.verifier(not cadre.Visible, "fenêtre fermée : pas d'encadré")
d:dire("Colette", "Me revoilà !")
U.verifier(not cadre.Visible, "fenêtre fermée : même quand elle parle")
d:montrer(true)
U.verifier(cadre.Visible and cadre.Texte.Text == "Me revoilà !", "fenêtre rouverte : l'encadré revient, avec sa dernière parole")

-- Un appui le referme, jusqu'à sa prochaine parole
cadre.Activated:Fire()
U.verifier(not cadre.Visible, "un appui referme l'encadré")
d:montrer(false)
d:montrer(true)
U.verifier(not cadre.Visible, "refermé : il ne revient pas en rouvrant la fenêtre")
d:dire("Colette", "Voyons voir…")
U.verifier(cadre.Visible and cadre.Texte.Text == "Voyons voir…", "une nouvelle parole le rouvre")
d:dire(nil)
U.verifier(not cadre.Visible, "plus rien à dire : l'encadré se cache")

-- La même échelle que la fenêtre (petits écrans)
d:echelle(0.6)
U.verifier(cadre:FindFirstChild("UIScale").Scale == 0.6, "l'encadré se réduit comme la fenêtre")
