# Aiguille & Dentelle — Sous-projet 8 : la couture guidée

## 1. Contexte et objectif

Retour du commanditaire après le sous-projet 7 : « la couture manque d'intérêt : on n'est pas guidé sur comment coudre
droit (zéro tuto), et du coup on met le mode assisté, qui rend le moment inintéressant car automatique ».

Aujourd'hui, la machine tourne le tissu toute seule pour que chaque couture monte vers l'aiguille ; le joueur ne fait que
contrer une dérive invisible en glissant, et l'assistance coud parfaitement à sa place (note plafonnée à 85 %).

Dans *Dressmaker* (guides des joueurs, septembre 2026) : on tient Espace pour faire avancer le tissu, on le **fait
pivoter** (A / D, ou la souris) pour garder le point rouge sur le pointillé, on règle la vitesse en cousant (W / S) ; une
précision s'affiche en direct et réagit dès qu'on s'écarte ; dans les angles, on s'arrête, on pivote, on repart ;
l'assistance « tient la ligne » mais n'est pas parfaite : on peut encore rater. Contenu original : aucun nom, texte,
image ni son de *Dressmaker*.

### Critères de réussite

1. Coudre demande de faire pivoter le tissu : une ligne droite se tient avec de petites corrections, un angle demande de
   s'arrêter et de pivoter ; aller trop vite dans les courbes se paie.
2. L'assistance aide à tourner mais ne coud pas seule : une couturière qui ne s'arrête jamais dans les angles rate encore
   des points ; la note reste plafonnée à 85 %.
3. Le joueur est guidé : à sa première robe, des conseils pas à pas réagissent à ce qu'il fait ; ensuite, un bouton les
   rappelle ; la précision, l'aiguille et les points disent en direct si l'on est sur la ligne ; l'angle qui arrive est
   signalé.
4. Le serveur et la sauvegarde ne changent pas : le relevé (un écart tous les 0,1 dm) reste le même.
5. La jouabilité est vérifiée par des couturières simulées : soigneuse (≥ 90 %), pressée (nettement moins), les mains
   libres (presque rien), assistée sans s'arrêter (sous le plafond, au-dessus de 60 %).

## 2. La machine qui pivote (plan 25)

- **État** : la couture en cours (segment du trajet), l'avance le long du pointillé, l'écart de l'aiguille au pointillé
  (dm) et l'**angle** du tissu par rapport au pointillé (rad).
- **Coudre** (tenir Espace ou « Coudre ») : le tissu avance de v × dt dans le sens de l'aiguille ; l'avance le long du
  pointillé est v × dt × cos(angle) (jamais moins d'un cinquième : le tissu ne recule pas), l'écart grandit de
  v × dt × sin(angle). L'écart est relevé tous les 0,1 dm d'avance, borné à 2 dm (comme aujourd'hui).
- **Pivoter** (A / D, ← / →, boutons ⟲ ⟳, ou glisser en tenant « Coudre ») : l'angle tourne de 90° par seconde au plus,
  qu'on couse ou non (l'aiguille plantée, on pivote dans un angle).
- **Le tissu tire** : en cousant, l'angle dérive doucement (deux sinusoïdes, graine par pièce, comme la dérive
  d'aujourd'hui) ; davantage pour les tissus qui glissent (soie, satin, organza, tulle), moins pour les tissus stables
  (coton, lin, jute, laine).
- **Les angles** : deux coutures qui se suivent (le bout de l'une est le début de l'autre) forment un angle ; à son
  passage, l'angle du tissu se décale de l'angle du trajet. Qui continue de coudre sans pivoter s'écarte vite. Deux
  coutures séparées : l'aiguille est remise au début de la suivante, le tissu droit.
- **Vitesse** : tortue, normale, lapin (boutons et W / S), changée en cousant.
- **L'assistance tient la ligne** : en cousant, elle fait pivoter le tissu vers le pointillé, au plus aux deux tiers de la
  vitesse de pivot, et ne s'arrête pas dans les angles : le joueur garde la vitesse et les arrêts. Note plafonnée à 85 %.
- **Jouabilité** (constantes réglées sur des couturières simulées) : soigneuse (corrige l'angle et l'écart, s'arrête et
  pivote dans les angles, vitesse normale) au moins 90 % ; pressée (lapin, sans s'arrêter) bien moins ; les mains libres
  (ni pivot ni arrêt) presque rien ; assistée sans s'arrêter entre 60 et 85 %.

## 3. Le guidage (plan 26)

- **Le tissu tourne avec l'angle** : la couture monte vers l'aiguille quand on est droit ; elle penche quand on dévie.
- **En direct** : l'aiguille et les points prennent la couleur de l'écart (vert sur la ligne, orange, rouge) ; une jauge
  « Précision » suit la note ; l'angle qui arrive est marqué sur le pointillé, et « Arrête-toi et pivote » s'affiche à
  son approche ; « Parfait ! » salue une couture sans faute.
- **Conseils pas à pas** à la première robe (aucune robe livrée ni vendue) : tenir Espace ; pivoter avec A / D (ou les
  boutons) ; s'arrêter et pivoter dans un angle ; ralentir dans les courbes ; chaque conseil s'efface quand le joueur l'a
  fait. Ensuite, le bouton « ? » les rappelle. Rien n'est sauvegardé.
- **Le tissu** : son nom et s'il glisse (« Soie : elle glisse, tiens-la bien »).

## 4. Tests

- Machine : avance, pivot, coins, coutures séparées, tirage par matière, assistance, découd-vite, relevé accepté par le
  serveur, couturières simulées (§2).
- Écran : touches et boutons, le tissu qui tourne, couleurs, jauge, signal d'angle, conseils (apparition, disparition,
  « ? »), scénario.

## 5. Découpage en plans

1. **Plan 25 — La machine qui pivote** : `MachineCoudre`, contrôles, tirage par matière, assistance, couturières
   simulées, écran adapté.
2. **Plan 26 — Le guidage** : affichage en direct, signal des angles, conseils pas à pas, « ? », tissu qui glisse.

## 6. Hors périmètre

Un tissu d'essai séparé pour s'entraîner (les conseils se font sur la vraie robe, qu'on peut découdre) ; la pédale de la
machine en 3D.
