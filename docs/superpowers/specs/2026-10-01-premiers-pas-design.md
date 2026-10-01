# Aiguille & Dentelle — Sous-projet 9 : les premiers pas

## 1. Contexte et objectif

Le sous-projet 8 a guidé la couture. Le commanditaire, après avoir estimé le jeu à « environ 70 % », demande : « fais les
tutos des autres postes ». Aujourd'hui, seul l'accueil d'un joueur nouveau explique la suite en un paragraphe ; les
mesures n'ont qu'une consigne fixe, le carnet, la découpe et la photo aucune. Le joueur découvre seul les molettes, les
jauges du carnet, le droit-fil, le glisser des pièces, la pose des décorations.

Objectif : à sa première robe, chaque poste accompagne le joueur pas à pas, comme la couture : un conseil à la fois, qui
s'efface quand le joueur a fait le geste, l'élément à toucher entouré ; ensuite, un bouton « ? » les rappelle. Contenu
original : aucun texte de *Dressmaker*.

### Critères de réussite

1. À la première robe (aucune robe livrée ni vendue), chaque poste (accueil, mesures, carnet, achat, découpe, épinglage,
   décorations, photo) montre ses conseils ; la couture garde les siens (sous-projet 8).
2. Chaque conseil s'efface quand le geste est fait (pas sur un simple délai, sauf pour un conseil qui ne demande que de
   regarder) ; aucun conseil ne peut bloquer le joueur : le poste se termine comme avant, et ses conseils avec lui.
3. Un conseil ne cache rien d'utile : il s'affiche toujours au même endroit, sur la barre de titre de la fenêtre ;
   l'élément qu'il désigne est entouré d'un anneau qui pulse.
4. Le bouton « ? » de la barre de titre rappelle les conseils du poste en cours, à tout moment (la couture comprise).
5. Les conseils vus ne reviennent pas d'eux-mêmes pendant la partie (rien n'est sauvegardé) ; le serveur ne change pas.

## 2. Le bandeau et l'anneau (plan 27)

- **Un module `Tutoriel`** (client) : il tient la liste des conseils d'un poste — chacun un texte, l'élément à entourer
  (facultatif), et ce qui l'efface (une condition lue à chaque image, ou une durée pour un conseil à lire) — et
  passe au suivant quand la condition est remplie. Chaque écran donne ses conseils, qui lisent son propre état (les
  molettes, le croquis en cours, la pièce choisie…).
- **Le bandeau** : sur la barre de titre (il couvre le titre du poste tant qu'un conseil est affiché), fond clair, bord
  de la couleur du jeu, texte d'au moins 14 px ; fenêtre centrée : deux lignes ; panneau à droite : deux lignes plus
  courtes. Un conseil qui ne tient pas est trop long : on le coupe en deux.
- **L'anneau** : un cadre arrondi un peu plus grand que l'élément désigné, qui pulse ; il suit l'élément (enfant de
  celui-ci) et disparaît avec le conseil.
- **« ? »** : dans la barre de titre, près de l'argent ; visible quand le poste a des conseils ; il les reprend au
  premier. Celui de la couture (dans son panneau) laisse place à celui-ci.
- **Première robe** : livraisons + ventes = 0 (la même règle que la couture). Les conseils d'un poste sont « vus » quand
  le joueur les a tous suivis ou quand il quitte le poste ; ils ne reviennent alors qu'avec « ? ».

## 3. Les conseils, poste par poste

Textes indicatifs (les plans les fixent) ; l'élément entouré entre parenthèses.

- **Accueil** : faire sonner la clochette, ou E (la clochette).
- **Mesures** (plan 27) : glisser sur une molette, ou − et + (une molette) ; faire coïncider les trois bandes avec la
  silhouette en pointillé — s'efface quand les trois mesures sont justes à peu près (le mannequin) ; valider (le bouton).
- **Carnet** (plan 28) : choisir un modèle par partie avec ◀ ▶ ; toucher une pièce pour lui choisir un tissu (le dessin)
  ; les jauges de la cliente, à remplir par ses choix (la fiche, conseil à lire) ; tracer le patron (le bouton).
- **Achat** (plan 28) : acheter chaque tissu, le métrage proposé suffit (le premier « Acheter ») ; aller à la découpe.
- **Découpe** (plan 28) : choisir une pièce (la liste) ; la faire glisser sur le tissu (le rouleau) ; la tourner pour
  garder le droit-fil (les boutons de rotation) ; couper (le bouton) ; couper toutes les pièces, « Proposer une place »
  aide, A / D déroulent le rouleau (conseil à lire).
- **Épinglage** (plan 28) : toucher une pièce pour l'épingler (la première carte) ; les épingler toutes.
- **Décorations** (plan 29) : choisir une décoration (la palette) ; toucher la robe pour la poser ; tourner la vue en
  glissant ; les outils (conseil à lire) ; présenter la robe (le bouton).
- **Photo** (plan 29) : choisir un décor et une lumière, prendre la photo (le bouton) ; livrer (le bouton).

## 4. Tests

- `Tutoriel` seul : suite des conseils, condition et durée, anneau posé puis retiré, « vus », « ? », première robe,
  bandeau aux deux dispositions.
- Chaque poste : l'écran ouvert à la première robe montre son premier conseil ; les gestes font passer aux suivants ;
  pas de conseils après une robe livrée ; « ? » les reprend. Le scénario (qui joue une première robe) vérifie le bandeau
  à chaque poste.
- Dans Studio : le bandeau et l'anneau à chaque poste, centré et en panneau ; les textes tiennent.

## 5. Découpage en plans

1. **Plan 27 — Le bandeau et les mesures** : `Tutoriel`, bandeau, anneau, « ? » (la couture y compris), accueil,
   mesures.
2. **Plan 28 — Du carnet à l'épinglage** : carnet, achat, découpe, épinglage.
3. **Plan 29 — Décorations et photo** : décorations, photo ; vérification de tous les postes dans Studio.

## 6. Hors périmètre

- La sauvegarde des conseils vus (une partie neuve sans robe livrée les remontre).
- Un tutoriel de la rue (boutiques, vitrines, chat), de la mercerie, du courrier ou du carnet d'adresses.
- La traduction anglaise (à proposer ensuite).

## 7. Amendements (décidés pendant les plans 27 à 29)

- **L'anneau** n'est pas un enfant de l'élément désigné (§2) : un cadre rangé dans le contenu de l'écran, sous ses
  calques (le choix d'un tissu, l'aperçu du rouleau, la mercerie, l'aperçu de la photo : ZIndex 10 et plus), recalé à
  chaque image sur la partie visible de l'élément (rognée par les listes qui défilent) et refait si l'écran vide son
  contenu. Enfant de l'élément, il était rogné dans les listes, invisible autour d'une liste entière, et passait
  par-dessus les calques (relectures des plans 27 et 28).
- **Le temps de lire** : un conseil reste au moins 2 s, même si son geste est déjà fait ; le geste est lu à chaque image
  et retenu (fait puis défait pendant la lecture, il compte) ; fenêtre fermée, les conseils attendent.
- **« ? »** : le titre du poste ne lui laisse la place que quand il est affiché (au refus, sans conseils, le titre garde
  toute sa largeur).
- **Des conseils toujours vrais** : la touche E (accueil), Q / E (décorations) seulement avec un clavier ; au carnet, le
  conseil des tissus attend un tissu pour chaque partie (sinon « Tracer le patron » est refusé) ; à la découpe,
  « quand la place est libre » ; aux décorations, un ruban compte une fois qu'il a deux points (« Finir la garniture »
  désigné) ; à la photo, « Livrer » une fois l'aperçu refermé ; une robe libre se présente sans cliente.
- **La couture** garde sa bulle de conseils sur le plateau ; son « ? » est celui de la barre de titre.
