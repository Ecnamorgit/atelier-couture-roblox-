-- Sous-projet 7 : le portrait de la cliente dans l'encadré de dialogue (selon ce qu'elle dit, et son avis en étoiles) ;
-- son illustration si sa fiche en a une ; son initiale dans un médaillon si la mémoire des images est pleine.
local UiKit = U.module("UiKit")
local Dialogue = U.module("Dialogue")
local Portrait = U.module("Portrait")
local Vignettes = U.module("Vignettes")
local Clientes = U.module("Clientes")

local colette = Clientes.get("colette")
U.verifier(Portrait.expression(colette, colette.repliques.merci) == "contente" and Portrait.expression(colette, colette.repliques.deception) == "decue" and Portrait.expression(colette, colette.repliques.arrivee) == "neutre", "l'expression suit ses mots : merci (contente), déception (déçue), le reste (neutre)")
U.verifier(Portrait.expression(colette, "…", 5) == "contente" and Portrait.expression(colette, "…", 4) == "contente" and Portrait.expression(colette, "…", 3) == "neutre" and Portrait.expression(colette, "…", 2) == "neutre" and Portrait.expression(colette, "…", 1) == "decue", "son avis : 4 ou 5 étoiles contente, 2 ou 3 neutre, 1 déçue")

local gui = Instance.new("ScreenGui")
local d = Dialogue.nouveau(gui, UiKit)
local cadre = gui.Dialogue
local portrait = cadre.Portrait
d:dire("Colette", "Bonjour !", nil, "colette")
U.verifier(portrait.Visible and portrait:GetAttribute("Cliente") == "colette" and portrait:GetAttribute("Expression") == "neutre" and (portrait.Image.Visible or portrait.Initiale.Visible), "l'encadré montre son portrait, neutre")
U.verifier(cadre.Texte.Position.X.Offset >= Dialogue.PORTRAIT.X + 14 and cadre.Nom.Position.X.Offset == cadre.Texte.Position.X.Offset and cadre.Size.Y.Offset >= Dialogue.PORTRAIT.Y + 20, "son nom et ses mots à droite du portrait, qui tient dans l'encadré")
d:dire("Colette", colette.repliques.merci, 5, "colette")
U.verifier(portrait:GetAttribute("Expression") == "contente" and cadre.Etoiles.Position.X.Offset >= Dialogue.PORTRAIT.X + 10, "cinq étoiles : contente ; les étoiles aussi à droite du portrait")
d:dire("Colette", colette.repliques.deception, 1, "colette")
U.verifier(portrait:GetAttribute("Expression") == "decue", "une étoile : déçue")
d:dire("La cliente", "Bonjour.")
U.verifier(not portrait.Visible and cadre.Texte.Position.X.Offset < 20, "sans cliente connue : pas de portrait, le texte à gauche")

-- Le dessin (dans la simulation, la mémoire des images répond) ; mémoire pleine : l'initiale ; une illustration
d:dire("Colette", "Bonjour !", nil, "colette")
U.verifier(portrait.Image.Visible and not portrait.Initiale.Visible, "le dessin au crayon")
local portraitDessin = Vignettes.portrait
Vignettes.portrait = function()
	return nil
end
d:dire("Colette", "Encore moi !", nil, "colette")
Vignettes.portrait = portraitDessin
U.verifier(not portrait.Image.Visible and portrait.Initiale.Visible and portrait.Initiale.Text == "C" and portrait.Initiale.TextSize >= 14, "mémoire des images pleine : l'initiale, « C »")
colette.image = "rbxassetid://123456"
d:dire("Colette", "Et avec mon illustration ?", nil, "colette")
colette.image = nil
U.verifier(portrait.Image.Visible and portrait.Image.Image == "rbxassetid://123456", "une illustration dans sa fiche remplace le dessin")
