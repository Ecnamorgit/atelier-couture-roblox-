# Aiguille & Dentelle — Sous-projet 6 : l'atelier plus fidèle (présentation)

## 1. Contexte et objectif

Le sous-projet 5 a rapproché la présentation de *Dressmaker*. Restaient trois écarts de **mécanique**, vus dans les
vidéos et laissés hors périmètre : les mesures prises sur un mannequin à molettes, le tissu entamé qui reste sur le
rouleau (avec un compteur en mètres), et la mercerie achetée d'avance. Le commanditaire a choisi ce sous-projet et
validé les recommandations de la proposition (`proposition_sp6_atelier.md`, section 6). Contenu original : aucun nom,
texte, image ni son de *Dressmaker*.

### Critères de réussite

1. On prend les mesures en réglant trois molettes sur un mannequin, jusqu'à ce qu'il épouse la silhouette de la
   cliente en pointillé ; la règle (écart, ajustement) ne change pas.
2. La mercerie s'achète d'avance, en stock ; les décorations puisent dans ce stock ; on peut acheter sans quitter la
   robe en cours.
3. Le tissu coupé laisse une bande entamée, avec ses trous, en haut du rouleau : on peut couper dans ses vides à la
   robe suivante, ou la jeter ; un compteur en mètres dit ce qui est entamé et ce que la robe y ajoute.
4. Les parties existantes se chargent (migration), reçoivent un kit de mercerie ; les tests des sous-projets 1 à 5
   restent verts, l'équilibrage reste dans ses cibles.

## 2. Mesures à molettes (plan 15)

- **Écran** : le mannequin, de face, en 2D, porte trois molettes (poitrine, taille, hanches) ; il s'élargit à chaque
  cran. La silhouette de la cliente est dessinée **en pointillé par-dessus** : on règle jusqu'à ce que le mannequin
  l'épouse. Un mètre ruban affiche la mesure en cm. Une fiche épinglée montre les valeurs du mannequin ; pour une
  cliente déjà mesurée, les valeurs du carnet et « Reprendre ses mesures ». La fiche **ne donne pas** les chiffres
  d'une nouvelle cliente (la silhouette reste le défi).
- **Gestes** : glisser de haut en bas sur une molette (0,1 dm tous les 12 px), la molette de la souris, les boutons
  − / + (0,1 dm). Molettes d'au moins 56 px ; le défilement de l'écran est bloqué pendant qu'on glisse.
- **Code** : un module pur `Molette` (du glissement aux crans, bornes), testé ; `EcranMesures` réécrit ;
  `EtatAtelier:mesurer`, `reprendreMesures` et `Notation.ajustement` inchangés ; le mannequin 3D n'est reconstruit
  qu'à la validation. Aucune donnée nouvelle.

## 3. Mercerie (plan 16)

- **Règles** : un stock `mercerie = { [idAccessoire] = quantité }` (à l'unité pour les objets, en cm pour les
  garnitures ; au plus 999 unités ou 9 999 cm). `acheterMercerie(id, quantite)` vend ce qui est ouvert, de 1 à 99
  unités, les garnitures par 50 cm, au prix du catalogue. `decorer` puise dans le stock au lieu de l'argent et
  refuse ce qui manque (« Il te manque 2 perles. ») ; ce qu'on retire **revient au stock**, sans revente.
- **Souvenirs** : quand un événement a lieu, son souvenir est offert en cinq exemplaires.
- **Kit de départ** : environ 60 po de mercerie (boutons, perles, nœuds, fleurs, 1 m de ruban, 1 m de dentelle) pour
  toute partie neuve, et pour les parties existantes par la **migration v3 → v4** ; une robe en cours garde ses
  décorations.
- **Écrans** : une **Mercerie** par-dessus l'écran (un bouton sans texte, qui arrête les appuis) : casiers sur deux
  colonnes, fiche de l'article (style, quantité − / +, « Acheter (8 po) »). On l'ouvre depuis l'accueil et depuis
  les décorations, sans quitter la robe. La palette des décorations affiche « Perle · ×12 », et « 0,20 / 3,50 m »
  pendant la pose d'une garniture ; un article épuisé est grisé. Au carnet, une exigence d'accessoire indique
  « (en stock : 0) ».
- **Serveur** : nouvelle action `acheterMercerie` (limitée comme les autres) ; `decorer` vérifie le stock.
- **Équilibrage** : le joueur simulé achète l'accessoire imposé ; les cibles actuelles doivent tenir.

## 4. Tissu entamé et compteur (plans 17 et 18)

- **Règles** : la fin de la découpe ne fait plus baisser le stock. Chaque tissu garde une **bande entamée** en haut du
  rouleau, avec ses **trous** (les pièces coupées) : `entames = { [idTissu] = { bas, trous = { { piece, x, y, angle } } } }`.
  À la robe suivante dans ce tissu, les trous sont grisés et interdits ; on coupe dans les vides ou sous la bande.
  `jeterEntame(idTissu)` (deuxième appui pour confirmer) retire la bande du stock : à l'achat, ou à la table tant
  qu'aucune pièce de ce tissu n'est coupée pour la robe en cours. Au-delà de 24 trous, la bande est jetée d'elle-même,
  et on l'annonce. `recommencer` transforme les pièces coupées en trous.
- **Compteur** : « 1,30 m entamés / 6,00 m » ; en direct, « Cette robe : +0,80 m (13 po) » ; à l'achat, « dont 1,3 m
  entamé » ; le métrage conseillé ne compte que le tissu neuf. Pour une robe libre, les matières sont ce que la robe
  ajoute à la bande.
- **Code** : `Coupon.nouveau(longueur, trous)` ; `TableDecoupe:proposer` essaie aussi les bords des trous ; la fonction
  locale `consommer` est remplacée par `jeterEntame` (serveur : `Commande`). `entames` rejoint `CHAMPS`, `exporter`,
  `charger` et `Sauvegarde` ; une bande illisible est jetée à la lecture ; un champ absent veut dire un rouleau neuf.
- **Téléphone** : jusqu'à 48 silhouettes grises de plus sur le rouleau ; vérifiées au banc d'essai.
- **Repli** : si la bande à trous se révèle trop lourde, le plan 18 peut se réduire au compteur en mètres.

## 5. Tests

- `Molette` : crans, bornes, sens du glissement ; scénario : régler les trois molettes et valider, reprendre les mesures.
- Mercerie : achat (prix, bornes, fermé), `decorer` avec stock (refus, retour au stock), migration v3 → v4 et kit,
  souvenirs, serveur (action limitée, triche), équilibrage ; scénario : acheter depuis les décorations, palette.
- Tissu entamé : `Coupon` à trous, bande conservée et réutilisée, `jeterEntame`, plafond de 24 trous, `recommencer`,
  matières d'une robe libre, sauvegarde ; scénario : couper dans les vides, jeter, compteur.

## 6. Découpage en plans

1. **Plan 15 — mesures à molettes**.
2. **Plan 16 — mercerie** (règles et écrans ensemble : une règle qui puise dans un stock ne peut pas partir sans
   l'écran pour le remplir ; stock, achat, `decorer`, souvenirs, sauvegarde v4 et kit, serveur, équilibrage,
   boutique, accès depuis l'accueil et les décorations, palette, carnet).
3. **Plan 17 — tissu entamé : règles** (`Coupon` à trous, `entames`, `jeterEntame`, matières, sauvegarde).
4. **Plan 18 — compteur et table** (mètres, « Cette robe », trous grisés, « Jeter », achat, `proposer`).

## 7. Hors périmètre

Robes plus riches, étiquettes de style, portraits (piste B) ; robe portée et défilés (piste C) : plus tard, au choix
du commanditaire.
