# Aiguille & Dentelle — Sous-projet 7 : des robes plus riches et des goûts plus fins (présentation)

## 1. Contexte et objectif

Les sous-projets 5 et 6 ont rapproché la présentation et l'atelier de *Dressmaker*. Restent trois écarts vus dans les
vidéos : des robes plus riches (volants, basques, étages, jupons, traînes, ceintures), des goûts plus fins (des
étiquettes chiffrées au-delà des six styles) et des portraits dessinés des clientes. Le commanditaire a validé les
recommandations de la proposition (`proposition_sp6_robes.md`, questions 1 à 5). Contenu original : aucun nom, texte,
image ni son de *Dressmaker*. La robe portée par l'avatar et les défilés restent hors périmètre (à sa décision).

### Critères de réussite

1. Le carnet garde quatre lignes (corsage, col, manches, jupe) ; de nouvelles variantes apportent des couches : jupe à
   volant, corsage à basque (plan 19), puis jupe à étages, jupe à jupon, jupe à traîne, corsage ceinturé (plan 23).
   Chaque pièce se coupe, s'épingle, se coud et se voit sur le mannequin comme les autres ; une couche ne traverse
   jamais celle du dessous.
2. Les robes et recettes existantes (vitrines, sauvegardes) restent valides : **aucune variante existante ne change de
   pièces**.
3. Seize étiquettes chiffrées : les six styles, trois occasions, sept traits calculés ; les commandes en demandent de
   nouvelles au fil du prestige ; les cibles de l'équilibrage tiennent.
4. Chaque cliente a un portrait dessiné (trois expressions) dans l'encadré, l'avis et le carnet d'adresses.
5. Une robe de 12 pièces se construit en moins de 1,5 s sur PC (mesuré) ; le commanditaire mesure sur téléphone.

## 2. Robes plus riches (plans 19, 20, 23)

- **Couches** : l'enroulement « jupe » gagne deux champs facultatifs : `depart` (dm sous la taille où commence la
  pièce, 0 par défaut) et `couche` (0 par défaut ; chaque couche ajoute 0,06 dm de rayon, plus l'amplitude des
  fronces des couches du dessous). La basque est une jupe courte et évasée en couche 1 ; un étage, une jupe posée plus
  bas en couche 1 ; un jupon, une jupe en couche 0 sous une jupe en couche 1.
- **Volant** : une bande froncée (enroulement « jupe », `depart` > 0, couche au-dessus de sa jupe), cousue d'un seul
  bord (le haut, comme un col). Dessinée à l'horizontale (sa longueur fait le tour du corps), elle se coupe en travers
  du rouleau à 0°, avec le même droit-fil que les autres pièces (le fil suit la hauteur du patron). Sa grille de
  maillage est propre à la pièce (champ `grille`, par exemple 32 × 3).
- **Traîne** (plan 23) : au-delà du sol (9 dm sous la taille), la jupe dos continue à plat vers l'arrière ; elle évite
  le trépied du mannequin et reste dans la vitrine.
- **Ceinture** (plan 23) : une bande de type corsage autour de la taille, en couche 1 (variante « corsage ceinturé »).
- **Croquis** : un polygone du dessin peut porter sa `piece` ; il prend alors le tissu de cette pièce (un volant d'un
  autre tissu se voit) ; toucher le dessin choisit le tissu de la pièce touchée.
- **Paie** : chaque pièce a un `poids` (1 par défaut ; 0,5 pour un volant, une ceinture, une basque) ; `Notation.base`
  compte les poids au lieu du nombre de pièces. Les robes actuelles gardent leur paie.
- **Plafond** : 12 pièces et 16 copies par robe (`Recette.valider`).
- **Chaîne et performance** (plan 20) : les bandes larges (volants) trouvent leur place à la table et dans le métrage
  conseillé, l'épinglage et la machine suivent les pièces cousues d'un seul bord, les vitrines construisent les robes
  riches sans geler (images réduites, construction étalée) ; mesures sur PC dans le plan, sur téléphone par le
  commanditaire.
- **Commandes** : `Commandes.realisable` est réécrite par famille (les points s'additionnent) pour rester rapide avec
  environ 1 400 croquis.

## 3. Des goûts plus fins : seize étiquettes (plans 21, 22)

- **Six styles** : inchangés.
- **Trois occasions** : Journée, Soirée, Travail ; notées par matière (11 matières × 3) et par variante.
- **Sept traits calculés** (sans saisie) : Légère / Chaude (matière, manches, longueur), Sobre / Travaillée (poids des
  pièces et décorations), Unie / Fleurie / À motifs (surface par type de motif).
- **Exigences** : la première reste un style de la cliente ; les nouveaux types s'ouvrent au fil du prestige
  (occasions au prestige 2, matière « en X » au prestige 3, traits au prestige 4) ; une table d'interdits écarte les
  paires impossibles (Légère et Chaude, Sobre et Travaillée, Unie et À motifs…).
- **Clientes et histoire** : chaque cliente a une occasion préférée ; un événement impose la sienne (le bal : Soirée).
- **Interface** : la fiche du carnet montre les jauges demandées et les styles de la cliente (pas seize jauges) ; une
  carte de tissu montre ses quatre étiquettes les plus fortes ; le filtre des tissus s'étend aux occasions.
- **Sauvegarde** : les anciennes commandes et lettres restent valides ; les nouveaux types d'exigence sont acceptés.
- **Garde** : un test vérifie que chaque étiquette peut atteindre 60 avec ce qui est ouvert quand elle est demandée.

## 4. Portraits dessinés (plan 24)

- `Pixels.portrait(cliente, expression)` dessine au crayon un buste de face (128 × 160) : peau, coiffure (nouveau champ
  `coiffure` de chaque cliente), yeux et bouche selon l'expression (contente, neutre, déçue), encolure de sa tenue.
  `Vignettes` le fige et le garde en cache.
- Il paraît dans l'encadré de dialogue, dans l'avis (avec les étoiles) et dans le carnet d'adresses.
- Un champ `image` facultatif remplace le dessin (pour des illustrations téléversées plus tard) ; si la mémoire
  d'images est pleine, l'initiale dans un médaillon.

## 5. Tests

- Couches : pour chaque variante, l'extérieur dépasse l'intérieur d'au moins 0,03 dm partout ; les jambes et le
  trépied sont évités ; la traîne reste dans la vitrine. Recettes existantes toujours valides ; plafond 12 / 16.
- Chaîne : un volant se coupe en travers à 0° (droit-fil parfait), se coud d'un bord ; paie pondérée.
- Étiquettes : valeurs des traits, occasions, exigences nouvelles (juge, interdits), `realisable` par famille,
  sauvegarde, atteignabilité (60), équilibrage.
- Portraits : dessin déterministe, trois expressions distinctes, repli sans mémoire d'images.
- Scénario : une robe à volant de bout en bout ; une commande à occasion ; un portrait dans l'encadré.

## 6. Découpage en plans

1. **Plan 19 — Couches** : `depart`, `couche`, volant, grille par pièce, croquis pièce par pièce, jupe à volant,
   corsage à basque, poids des pièces.
2. **Plan 20 — Chaîne et performance** : bandes larges à la table, couture d'un bord, plafond 12 / 16, vitrines, mesures.
3. **Plan 21 — Étiquettes, données** : occasions, traits, `Notation`, `Commandes` par famille, `Sauvegarde`.
4. **Plan 22 — Étiquettes, jeu** : fiche, cartes de tissu, goûts des clientes, histoire, équilibrage.
5. **Plan 23 — Contenu** : étages, jupon, traîne, ceinturé, déblocages.
6. **Plan 24 — Portraits**.

## 7. Hors périmètre

Robe portée par l'avatar et défilés (piste C) : à la décision du commanditaire. Une cinquième ligne au carnet
(« Taille ») : écartée (question 1).
