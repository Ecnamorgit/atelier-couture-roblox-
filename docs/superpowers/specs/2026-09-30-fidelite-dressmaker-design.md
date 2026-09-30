# Aiguille & Dentelle — Sous-projet 5 : fidélité à Dressmaker (présentation)

## 1. Contexte et objectif

Les sous-projets 1 à 4 ont reproduit les mécaniques de *Dressmaker* et l'ampleur de son contenu. Le commanditaire a
comparé le jeu à quatre vidéos de *Dressmaker* : la boucle de jeu correspond étape par étape, mais **la
présentation** s'en éloigne, et d'abord le carnet de croquis (« je ne vois pas de ressemblance avec le vrai jeu »).
Ce sous-projet rapproche la présentation, sans changer les règles : le carnet de croquis, la parole des clientes,
l'avis en étoiles, la réputation, les confettis, la gazette, l'affiche des nouveautés et le chat de l'atelier.
Contenu original : aucun nom, texte, image ni son de *Dressmaker*.

### Ce que montrent les vidéos (et ce qu'on reprend)

- **Carnet** : une page de carnet (papier, ornements, notes de tailleur, crayon) ; au centre, le **dessin de la
  robe au trait**, vu de face, qui change avec chaque modèle ; il **se colorie** pièce par pièce quand un tissu est
  choisi ; les **échantillons** des tissus choisis sont épinglés en haut à gauche (bords crantés) ; dessous, une
  ligne par famille (corsage, col, manches, jupe) avec **◀ nom du modèle ▶** et des points ; « environ X m de tissu » ;
  un bouton pour tracer le patron. Repris.
- **Clientes** : leurs paroles dans un **encadré de dialogue** avec leur nom ; après la livraison, **un avis en
  étoiles** (1 à 5) ; une **barre de réputation** avec un titre ; un **rang** de couturière à la vente. Repris, avec
  nos titres.
- **Robe terminée** : des **confettis**. Repris.
- **Après un événement** : un **journal du quartier** raconte la soirée. Repris (notre gazette).
- **Nouveau stock** : une **affiche** annonce les nouveautés de la boutique. Repris.
- **Le chat** de l'atelier, qu'on caresse. Repris.
- Laissés pour plus tard (règles ou gros chantiers, à décider avec le commanditaire) : mesures à molettes sur le
  mannequin, compteur de mètres et chutes à la découpe, mercerie achetée d'avance, une vingtaine d'étiquettes de
  style, robes beaucoup plus riches (volants, jupons superposés), portraits dessinés des clientes.

### Critères de réussite

1. Le carnet montre le dessin de la robe choisie, colorié des tissus choisis, et se pilote par ◀ ▶ ; tout ce que
   faisait l'ancien carnet reste possible (tissu par pièce, même tissu partout, jauges, exigences, métrage, coût).
2. Pendant l'atelier, ce que dit la cliente se lit dans un encadré à son nom, toujours à l'écran (plus sous les
   boutons de Roblox, même sur téléphone).
3. Chaque livraison reçoit un avis de 1 à 5 étoiles ; la réputation (le prestige) porte un titre.
4. Confettis à la robe terminée ; gazette à chaque événement ; affiche à chaque nouveauté ; un chat à caresser.
5. Aucune règle ne change (paie, prestige, amitié, déblocages) : les tests des sous-projets 1 à 4 restent verts.

## 2. Le carnet de croquis

### Le dessin

- Un module partagé `Croquis` décrit, pour chaque variante, **sa forme vue de face** : des polygones dans un repère
  de dessin (100 unités de large, 130 de haut), posés sur un gabarit de corps commun (cou, épaules, poitrine,
  taille, hanches). Le corsage va des épaules à la taille, les manches partent des épaules (miroir à droite), le
  col entoure le cou, la jupe part de la taille. Ordre de dessin : jupe, corsage, manches, col.
- Les formes suivent l'esprit de chaque patron : corsage droit (encolure carrée), en V, à bretelles, cache-cœur
  (encolure croisée), bustier (haut en cœur, sans épaules) ; manches ballon, longues, courtes, trois-quarts ;
  col Claudine (deux rabats arrondis), montant (bande autour du cou), marin (deux rabats en V) ; jupe droite
  (au genou), trapèze, ample froncée (avec des plis), longue évasée (à la cheville), crayon (resserrée).
- `Croquis.partieA(croquis, x, y)` dit quelle famille est sous un point du dessin (la plus haute dans l'ordre de
  dessin), ou rien : toucher le dessin choisit le tissu de cette partie.
- `Pixels.croquis(croquis, tissus, largeur, hauteur)` peint l'image (buffer RVBA) : fond transparent (le papier est
  derrière), un mannequin esquissé en gris très clair, chaque partie remplie du **motif de son tissu** (celui de la
  pièce de devant de la famille) ou **blanche** tant qu'il n'y a pas de tissu, un **trait de crayon** foncé autour de
  chaque partie, et quelques traits de détail (plis de la jupe ample, croisé du cache-cœur). Remplissage par
  lignes (pas de test point par point), pour rester rapide sur téléphone.
- Le client met l'image en cache (les dernières seules : elles occupent la mémoire des images). Si la mémoire des
  images est pleine, le dessin est remplacé par un fond papier et un texte ; tout le reste fonctionne.

### La page

- Fond papier crème avec un liseré, quelques ornements et notes au crayon (formes simples dessinées en code), un
  crayon posé sur le côté.
- En haut à gauche, **les échantillons épinglés** : un carré à bords crantés par tissu choisi (quatre au plus).
- Au centre, le dessin ; le toucher ouvre le choix du tissu de la partie touchée (toutes les pièces de sa famille).
- Sous le dessin, **quatre lignes ◀ nom ▶** (Corsage, Col, Manches, Jupe) avec autant de points que de modèles dans
  la famille, le modèle courant en couleur. On passe par tous les modèles : un modèle **fermé** s'affiche en gris
  avec ce qu'il faut pour l'ouvrir (« Amitié de Colette : 2 »), le dessin le montre, mais on ne peut pas tracer son
  patron (le refus dit ce qu'il faut pour l'ouvrir).
- Un bandeau des **pièces** (un petit échantillon par pièce, son nom) garde le choix du tissu pièce par pièce ;
  « Même tissu pour toute la robe » reste.
- « Environ X m de tissu » sous les lignes ; le bouton **« Tracer le patron »** (l'ancien « Valider le croquis »).
- À droite, **la fiche de commande** épinglée : qui commande, les exigences et leur état, les jauges de style, le
  métrage et le coût (comme aujourd'hui).
- Pour une robe libre, la fiche dit « Robe libre (taille M) : à ton idée. ».

## 3. La parole des clientes, l'avis, la réputation

- **Encadré de dialogue** : tant que la fenêtre de l'atelier est ouverte, ce que dit la cliente s'affiche dans un
  encadré à son nom, à gauche de la fenêtre, sous la barre de Roblox ; la bulle au-dessus de sa tête reste pour la
  rue et l'accueil (fenêtre fermée). Même texte, même durée.
- **Avis en étoiles** : à la livraison, la cliente donne de 1 à 5 étoiles, montrées dans l'annonce et l'encadré.
  Refusée : 1 étoile. Acceptée : 2, plus une étoile à 60 %, à 80 % et à 90 % de qualité. (Aucun effet sur la paie,
  l'amitié ou le prestige : c'est l'avis que les règles donnaient déjà.)
- **Réputation** : la jauge de prestige de l'accueil porte un titre par niveau : Inconnue, Remarquée, Appréciée,
  Renommée, Réputée, Célèbre, Illustre, Légendaire.
- **Rang de couturière** à la vente et au carnet d'adresses, selon les robes livrées : Débutante, Apprentie (5),
  Couturière (15), Première main (30), Maîtresse couturière (60).

## 4. Les petites fêtes de l'atelier

- **Confettis** : quand la dernière pièce est cousue (la robe est terminée), une pluie de confettis sur le mannequin
  et un petit son de fête.
- **La gazette** : quand un événement a lieu, l'épilogue devient **la une d'un journal du quartier** (« La Gazette
  du Dé » : titre du journal, date du jour de jeu, titre de l'événement, texte en deux colonnes, souvenir gagné).
- **L'affiche des nouveautés** : quand des tissus, décorations ou modèles s'ouvrent, une affiche « Nouveautés à
  l'atelier ! » les montre (échantillons, noms), en plus de la ligne « Nouveau : » de l'annonce.
- **Le chat** : un chat roux dort sur un coussin près de la fenêtre de chaque boutique ; « Caresser » (touche ou
  invite de proximité) le fait ronronner, remuer la queue, et fait monter de petits cœurs. Pour le plaisir seulement.

## 5. Tests

- `Croquis` : chaque variante a une forme ; toutes les formes restent dans le dessin ; la jupe part de la taille ;
  `partieA` rend la famille sous un point (jupe, corsage, manches, col) et rien hors de la robe ; sans manches, rien
  sur les côtés.
- `Pixels.croquis` : hors de la robe, transparent ; dans une partie sans tissu, blanc ; avec un tissu uni, sa couleur ;
  un trait foncé au bord ; taille de l'image.
- Scénario : le carnet montre le dessin et les échantillons ; ◀ ▶ changent le modèle et le dessin ; un modèle fermé
  est grisé avec sa raison et son patron refusé ; toucher le dessin ouvre le choix du tissu de la partie ; tout le
  parcours existant (tissus, même tissu, tracer le patron) reste jouable.
- Encadré, étoiles, réputation, rang, confettis, gazette, affiche, chat : chacun par un test du scénario ou unitaire
  (fonctions pures : nombre d'étoiles, titre de réputation, rang).

## 6. Découpage en plans

1. **Plan 11 — le carnet de croquis** : `Croquis`, `Pixels.croquis`, page refaite.
2. **Plan 12 — parole, avis, réputation, confettis** : encadré de dialogue, étoiles, titres, rang, confettis.
3. **Plan 13 — gazette, affiche, chat**.

## 7. Hors périmètre

Mesures à molettes, compteur de mètres et chutes, mercerie en stock, étiquettes de style de *Dressmaker*, robes plus
riches, portraits dessinés des clientes : à proposer au commanditaire après ce sous-projet. La robe portée par
l'avatar et les défilés entre joueurs restent un sous-projet possible.
