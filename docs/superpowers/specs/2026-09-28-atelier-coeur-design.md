# Atelier de couture — Sous-projet 1 : le cœur de l'atelier

- Date : 28 septembre 2026
- Statut : design validé en conversation, spec à relire
- Nom du jeu : « Atelier de couture » (provisoire, nom définitif au sous-projet 3)

## 1. Contexte et objectif

Le but est de reproduire sur Roblox les **mécaniques** du jeu Steam *Dressmaker* (Cozy Lives / Free Lives,
sorti le 21 septembre 2026) dans un jeu **public**. Le prototype actuel (grille de cases, barre de rythme,
robe en panneaux) en est très éloigné. Le cœur du jeu est donc reconstruit, en gardant l'outillage du dépôt :
Rojo, simulation de tests, serveur qui fait foi, sauvegarde protégée.

### Ce qui est reproduit, ce qui ne l'est pas

- **Reproduit fidèlement** : la boucle commande → carnet de croquis → achat de tissu → découpe (droit-fil / biais)
  → épinglage → couture à la machine → décorations → photo et livraison ; les jauges de style ; le principe
  « ce qu'on découpe sur le tissu est exactement ce qu'on voit sur la robe » ; la tolérance aux erreurs (reprise,
  recommencer, pas de chronomètre).
- **Jamais copié** : le nom « Dressmaker », les personnages, la ville, les dialogues, les illustrations, la musique,
  les sons, les noms de succès. Tout le contenu est original.

### Découpage en sous-projets

1. **Le cœur de l'atelier** (ce document) : une robe complète de bout en bout, commandes anonymes,
   une boutique par joueur, vitrines, sauvegarde.
2. **Clientes et progression** : prise de mesures (mini-jeu), clientes récurrentes, amitié et prestige,
   déblocages, commandes par courrier, prêt-à-porter.
3. **Contenu** : nom du jeu, casting et histoire originaux, événements, décor de la rue.
4. **Bonus Roblox** : porter la robe sur son avatar, défilés et votes à plusieurs.

Chaque sous-projet a sa propre spec, son plan et sa réalisation.

### Contraintes posées par le commanditaire

- Jeu publié pour des joueurs : tactile (téléphone, tablette) et souris/clavier, sessions courtes.
- Tous les graphismes sont produits en code (maillages et images générés) et avec les outils de génération
  de Roblox Studio. Aucun artiste.
- Le compte qui publie sera vérifié (13 ans et plus, pièce d'identité) et activera les API
  EditableMesh / EditableImage.
- Une boutique par joueur, dans une rue commune.
- Une robe « normale » prend **5 à 8 minutes**.
- Hypothèse : interface d'abord en français, traduction plus tard.

### Critères de réussite du sous-projet 1

1. Sur PC et sur téléphone, un joueur fait une robe complète en 5 à 8 minutes.
2. La position et l'angle d'une pièce sur le tissu se retrouvent exactement sur la robe 3D,
   y compris un imprimé tourné ou à l'envers.
3. La robe finie est sauvegardée et exposée dans la vitrine de la boutique, visible par les autres joueurs.
4. Tout tient dans les budgets de la section 9 avec 8 joueurs.
5. Le serveur calcule la découpe, le style, la qualité et la paie. Le client n'envoie jamais de note.

## 2. Architecture

### Le monde

- Une rue commune avec **8 emplacements** de boutique. Le serveur est limité à 8 joueurs.
- À l'arrivée, le joueur reçoit un emplacement libre. Le serveur y construit sa boutique :
  comptoir avec clochette, étagères de tissus, table de découpe, machine à coudre, mannequin, vitrine.
  Au départ du joueur, l'emplacement est vidé et libéré.
- Toute la fabrication se passe chez soi. Les autres joueurs voient la vitrine : la dernière robe finie.

### Répartition des rôles

| Côté | Rôle |
|---|---|
| Serveur (fait foi) | Emplacements ; argent ; stock de tissu ; commande et étape en cours ; validation de chaque action ; calcul de la découpe, du style, de la qualité et de la paie ; sauvegarde |
| Client | Interface, caméras, mini-jeux, génération du rendu 3D (robe en cours et vitrines) |
| Partagé | Catalogues, géométrie des pièces, formules de note |

### La recette de la robe

Une robe n'est **jamais** stockée ni transmise en 3D. On manipule sa **recette** :

```lua
{
	version = 1,
	mesures = { poitrine = 8.8, taille = 7.0, hanches = 9.4 }, -- décimètres
	pieces = {
		{ id = "jupe_trapeze_devant", tissu = "soie_fleurs_rose", x = 3.2, y = 1.0, angle = 45,
		  couture = 0.92, pliee = true },
		-- …
	},
	accessoires = {
		{ id = "noeud_satin", piece = 2, u = 0.40, v = 0.10, echelle = 1, angle = 0 },
		{ id = "dentelle", piece = 3, trajet = { { u = 0, v = 1 }, { u = 0.5, v = 1 }, { u = 1, v = 1 } } },
	},
}
```

Tout client peut régénérer la robe à partir de sa recette, et toujours à l'identique.
C'est ce qui rend les vitrines visibles par tous, puisque les objets Editable ne se répliquent pas.

### Modules

| Module | Côté | Rôle | Dépend de |
|---|---|---|---|
| `Catalogue` | partagé | Pièces, tissus, accessoires, styles, prix (données seulement) | — |
| `Patron` | partagé | Contour 2D, droit-fil, bords à coudre, trajets de couture, fonction d'enroulement 3D | `Catalogue` |
| `Notation` | partagé | Droit-fil, qualité, jauges de style, exigences, paie | `Catalogue`, `Patron` |
| `Coupon` | partagé | Rouleau de tissu : placement, chevauchement, métrage | `Patron` |
| `TextureTissu` | client | Motif répétable d'un tissu ; image d'une pièce découpée | `Catalogue`, `Patron` |
| `ConstructeurRobe` | client | Recette → robe 3D (maillages, matières, accessoires) ; niveaux de détail | `Patron`, `TextureTissu` |
| `Boutiques` | serveur | Attribution et construction des emplacements, vitrines | — |
| `Commande` | serveur | Machine à états d'une commande, validation des actions | `Notation`, `Coupon` |
| `Sauvegarde` | serveur | DataStore, verrou de session, migrations | — |
| `Ui*` | client | Un module par poste (Carnet, Achat, Decoupe, Epinglage, Couture, Decorations, Photo) | modules partagés |

Les modules partagés n'utilisent que des types de données Roblox (Vector3, CFrame, Color3), jamais d'instances.
On peut donc les tester seuls dans la simulation.

Le code du prototype actuel (`CoutureData`, `Rendu3D`, `AtelierClient`, `AtelierServer`) est remplacé.
On garde : l'anti-rafale des appels, la protection de sauvegarde (aucune écriture après une lecture ratée,
pas de DataStore sur un lieu non publié), la simulation de tests et le chat TextChatService.

## 3. Contenu et règles

### Unités et rouleau

- Unité de longueur : le **décimètre (dm)**. 1 dm de tissu = 32 pixels de texture.
- Un rouleau fait 14 dm de large (le standard de 140 cm). Le joueur le déroule sur la longueur achetée.
  Le droit-fil (la chaîne) est parallèle à la longueur du rouleau.

### Pièces de patron

Quatre familles, 13 variantes au départ :

| Famille | Variantes | Pièces à poser |
|---|---|---|
| Corsage | droit, décolleté en V, à bretelles | 1 à 2 |
| Manches | sans, ballon courtes, longues | 0 ou 1 (coupée dans le tissu plié = les deux manches) |
| Col | sans, Claudine, montant | 0 ou 1 |
| Jupe | droite, trapèze, ample froncée, longue évasée | 1 à 2 (devant et dos, ou une pièce coupée pliée) |

Une robe compte **4 à 6 pièces à poser**. Une pièce `pliee = true` se coupe dans le tissu plié en deux
dans sa largeur (pli au milieu du rouleau, à x = 7 dm). Posée d'un côté, elle occupe aussi sa forme
symétrique de l'autre côté du pli. On obtient deux pièces miroir (manche gauche et droite, devant et dos),
et le tissu est consommé sous les deux.

Chaque définition de pièce contient :

- `contour` : un polygone 2D en dm, sens trigonométrique ;
- `droitFil` : l'angle de la flèche dans le repère de la pièce ;
- `biais` : vrai si la pièce est prévue pour être coupée en biais (à 45°) ;
- `coutures` : les bords à coudre (indices d'arêtes du contour). Le trajet de couture est décalé de
  **0,15 dm** vers l'intérieur (la valeur de couture) ;
- `enroulement` : le nom de la fonction 3D et ses paramètres (voir la section 5) ;
- `style` : les points par style, qui peuvent être négatifs.

### Tissus (environ 24 au départ)

- 6 matières : coton, lin, laine, soie, velours, satin. La matière fixe le rendu (mat, satiné, velouté),
  la rugosité et le reflet.
- 6 motifs dessinés en code : uni, rayures, carreaux, pois, fleurs, dégradé. Un motif a des couleurs
  et une échelle.
- Chaque tissu a une **teinte** (rose, rouge, bleu, vert, jaune, violet, noir, blanc, brun),
  un **prix au mètre** (de 4 à 20 pièces d'or au départ) et des points par style.
- Le stock est compté en décimètres de longueur. Ce qui n'a pas été coupé reste en stock,
  il n'y a pas de chutes de forme libre.

### Accessoires (environ 15)

- **Objets** : boutons, nœuds, fleurs, broches, perles. Chacun a un prix unitaire et des points de style.
  Ils se posent librement sur la robe.
- **Garnitures** : dentelle, ruban, galon. On les pose en ligne, point par point : 64 points au plus
  par garniture, prix au décimètre.

### Styles

Il y a 6 styles : élégant, mignon, romantique, gothique, chic, décontracté.
Le score d'un style va de 0 à 100 :

```
score = clamp( Kp · Σ points des pièces
             + Kt · Σ ( points du tissu × part de surface de ce tissu )
             + Ka · Σ points des accessoires , 0, 100 )
```

Le tissu pèse le plus, comme dans Dressmaker. `Kp`, `Kt` et `Ka` sont des constantes de `Catalogue`
réglées à l'équilibrage (valeurs de départ : Kp = 1, Kt = 2, Ka = 0,5).
Dans le carnet, la jauge montre la cible (trait), la part acquise par les pièces (plein)
et la fourchette possible selon les tissus encore à choisir (hachures).

### Qualité

Pour chaque pièce, **qualité = droit-fil × couture**.

- **Droit-fil** d'une pièce normale, selon l'angle θ entre sa flèche et la chaîne, modulo 180° :
  100 % à 0°, 60 % à 45°, 75 % à 90°, en interpolation linéaire entre ces points.
- **Droit-fil** d'une pièce `biais` : 100 % à 45° et 135°, 70 % à 0° et 90°, linéaire entre les deux.
- **Aimantation** : à moins de 6° d'un angle à 100 %, la pièce s'aligne exactement sur lui.
- **Couture** : c'est la moyenne, sur chaque mesure du trajet, de `clamp(1 − (|écart| − 0,05) / 0,25, 0, 1)`,
  l'écart étant en dm. Donc 100 % jusqu'à 0,05 dm d'écart et 0 % à 0,30 dm ou plus.
  Avec l'assistance couture, la note est plafonnée à **0,85**.
- **Qualité de la robe** : la moyenne des pièces pondérée par leur surface. Les accessoires ne comptent pas.

### Commandes (sous-projet 1 : clientes anonymes)

- La cliente est un PNJ avatar tiré parmi quelques tenues construites en code.
- Sa taille est tirée parmi S, M et L (mesures fixes). La prise de mesures arrive au sous-projet 2.
- Elle a 1 à 3 exigences, prises parmi :
  - « au moins X » en un style ;
  - « au plus Y » en un autre ;
  - une qualité minimale ;
  - une couleur dominante (la teinte du tissu qui couvre la plus grande surface de la robe) ;
  - un accessoire imposé.
- Le générateur ne propose que des commandes **réalisables** avec le catalogue débloqué :
  il vérifie qu'au moins une combinaison les satisfait.
- **À la livraison** :
  - si toutes les exigences sont remplies : paie = `base × (0,5 + qualité)`, avec
    `base = 20 + 10 × pièces à poser + 15 × exigences` (de 75 à 125 au départ) ;
  - si au moins une est ratée : refus et retouche possible ; si on abandonne, pas de paie et le tissu coupé est perdu.
- L'argent de départ est de 150 pièces d'or. Il existe un filet de sécurité : on a toujours de quoi acheter
  le tissu le moins cher pour une robe simple.

## 4. Déroulé et commandes

| Étape | Action | PC | Mobile | Durée cible |
|---|---|---|---|---|
| 1. Commande | Sonner la clochette ; la cliente entre ; carte des exigences | E ou clic | appui | 20 s |
| 2. Carnet | Choisir les variantes des 4 familles, attribuer un tissu à chaque pièce ; jauges, métrage et coût en direct | clic | appui | 60 s |
| 3. Achat | Liste filtrable par style, métrage conseillé pré-rempli, aperçu du rouleau | clic | appui | 20 s |
| 4. Découpe | Vue de dessus du rouleau ; glisser et tourner chaque pièce ; % de droit-fil ; chevauchement en rouge ; dérouler ; « Couper » | glisser, molette ou R pour tourner, A/D pour dérouler | glisser, boutons ↺ ↻ et « dérouler » | 60–90 s |
| 5. Épinglage | Vue du mannequin ; toucher une pièce coupée l'envoie à sa place, avec le vrai tissu en aperçu | clic | appui | 20 s |
| 6. Couture | Une passe par pièce, coutures enchaînées ; maintenir « Coudre » et garder l'aiguille sur le pointillé ; vitesse tortue ↔ lapin ; découd-vite ; assistance | Espace + souris | maintenir le bouton + glisser | 90–120 s |
| 7. Décorations | Caméra orbitale ; choisir, toucher la robe pour poser, tourner, redimensionner, annuler ; garnitures point par point | clic, Q/E pour tourner | appui, curseurs | 60 s |
| 8. Photo et livraison | Décor, éclairage, couleur du mannequin, capture ; jugement de la cliente ; la robe part en vitrine | clic | appui | 20 s |

- Chaque poste a sa caméra fixe. On revient à la caméra normale en quittant le poste.
- On peut reprendre une pièce tant qu'elle n'est pas coupée. « Recommencer la robe » est disponible à tout moment.
  Il n'y a pas de chronomètre.
- Tout se joue d'un seul doigt ou à la souris seule. Les textes mesurent au moins 14 px à l'échelle 1.
  Les symboles utilisés sont vérifiés à l'écran (la police Gotham n'a pas « ✕ » ni « ⟳ »).

## 5. Rendu 3D

### Images de tissu

- `TextureTissu.motif(idTissu)` renvoie une `EditableImage` de 256 × 256 px, répétable (8 dm × 8 dm),
  toujours identique pour un même tissu. Elle est créée à la demande et gardée en cache (LRU).
- Une vignette de 64 × 64 px sert à l'interface.

### Image d'une pièce découpée

- Taille : la boîte englobante de la pièce × 32 px/dm, plafonnée à 256 px par côté
  (plafond de 128 px pour une vitrine).
- Pour chaque pixel de la pièce, on calcule sa position sur le rouleau avec la transformation
  inverse (position, angle, repli), puis on lit le motif en répétition. L'écriture se fait par
  `WritePixelsBuffer`.
- **Exigence d'exactitude** : le pixel (i, j) de l'image de la pièce est égal au pixel du motif
  situé sous ce point de la pièce sur la table. C'est vérifié par les tests.

### Maillage d'une pièce

- Le contour 2D est quadrillé (12 × 16 cases pour la robe en cours, 6 × 8 pour une vitrine).
  Seuls les triangles à l'intérieur du contour sont gardés, et le contour est ajouté exactement.
- Chaque point (u, v) du patron passe par la fonction d'`enroulement` de sa famille, paramétrée
  par les mesures :
  - **jupe** : un cône évasé, ou un cône avec ondulation pour la jupe froncée ; tour de hanches
    en haut, évasement vers l'ourlet ;
  - **corsage** : un cylindre elliptique qui passe du tour de poitrine au tour de taille ;
  - **manche** : un tube conique autour du bras ;
  - **col** : un anneau autour du cou.
- Les coordonnées de texture sont les coordonnées 2D du patron, normalisées. Les normales sont
  calculées sur la surface.
- Une face intérieure (doublure plus sombre) est ajoutée : on ne voit jamais à travers la robe.
- Le maillage est créé avec `AssetService:CreateEditableMesh`, puis transformé en `MeshPart`
  (`CreateMeshPartAsync`). La pièce est soudée au mannequin.

### Matières

- La texture est appliquée par une `SurfaceAppearance` (image de couleur générée) avec une rugosité
  et un reflet par matière. À valider pendant le test de faisabilité ; à défaut, on utilise
  `MeshPart.TextureContent` avec une `Material` Roblox proche.
- Les vignettes de l'interface (ViewportFrame) utilisent une matière lisse et un éclairage clair :
  on a constaté que `Fabric` y rend trop sombre.

### Accessoires

- Ce sont des objets Roblox ordinaires : pièces assemblées, ou maillages générés une fois avec les outils
  de Studio et rangés dans `ReplicatedStorage`.
- Leur position est enregistrée sur le patron (pièce, u, v). La fonction d'enroulement donne le point
  et la normale exacts, ils suivent donc la robe quelle que soit la taille.
- Une garniture est un ruban de petites pièces le long de son trajet.

### Vitrines et niveaux de détail

- Chaque client construit les vitrines à partir des recettes (répliquées par le serveur dans un attribut
  de la boutique), en qualité réduite.
- Une vitrine n'est construite que si le joueur est à moins de 60 studs, et elle est libérée au-delà de 80 studs.
- Si la conversion en contenu statique (`AssetService:CreateDataModelContentAsync`) s'avère utilisable
  (test de faisabilité), une robe finie est convertie pour libérer la mémoire Editable.

### Pannes

- Si une création Editable échoue (budget mémoire atteint), la pièce est affichée en couleur unie
  (couleur dominante du tissu) et un avertissement est journalisé une fois. Le jeu continue.
- Une erreur dans le rendu d'une vitrine est isolée (`pcall`) et ne touche ni les autres vitrines
  ni la boutique du joueur.

## 6. Serveur, triche et sauvegarde

### Échanges

- Une seule `RemoteFunction` `Atelier`, avec une action par étape : `Commande`, `ValiderCroquis`,
  `Acheter`, `Couper`, `Epingler`, `RendreCouture`, `Decorer`, `Livrer`, `Retoucher`, `Recommencer`.
- Chaque réponse est de la forme `{ ok = bool, erreur = string? , … }`.
- Il y a une limite d'appels par joueur : au plus 5 par seconde, sauf `RendreCouture` qui est limité
  par sa propre plausibilité.
- `Commande` gère une machine à états par joueur. Une action hors séquence est refusée. Les retours
  permis sont : retouche après refus, et recommencer à tout moment.

### Ce que le serveur vérifie

- **Croquis** : les variantes existent et sont débloquées ; un tissu en stock ou achetable est attribué
  à chaque pièce.
- **Achat** : le tissu existe, la longueur est entière et entre 1 et 100 dm, et le joueur a l'argent.
- **Découpe** : la pièce vient du croquis validé et n'est pas encore coupée ; `x`, `y` et `angle`
  sont des nombres finis ; la pièce transformée est dans la largeur du rouleau ; elle ne chevauche
  pas une pièce déjà coupée sur ce rouleau ; la longueur consommée est en stock.
  Le serveur recalcule le droit-fil.
- **Couture** : le client envoie le relevé des écarts de l'aiguille, une mesure tous les 0,1 dm
  de trajet, et la durée. Le serveur contrôle :
  - le nombre de mesures (longueur / 0,1, à ±2 près) ;
  - des écarts dans [−2 ; 2] dm ;
  - une durée d'au moins 90 % de longueur / vitesse maximale.
  
  Il applique le plafond de l'assistance si elle était active.
  **Limite assumée** : un tricheur peut s'attribuer une bonne couture. L'enjeu se limite à la qualité,
  donc à un peu d'argent. C'est écrit dans le README.
- **Décorations** : la pose se fait côté client. La liste complète est envoyée en une fois par `Decorer`
  quand le joueur quitte le poste, et de nouveau après chaque retouche. Le serveur vérifie :
  identifiants valides, 300 objets au plus, 64 points par garniture, `u` et `v` dans [0 ; 1],
  échelle et angle bornés. Il facture la différence avec la liste précédente et refuse si l'argent manque.
- **Livraison** : style, qualité, exigences et paie sont calculés à partir de la recette.

### Sauvegarde (DataStore `AtelierCouture_v2`, une clé par joueur)

- **Contenu** :
  - `version` ;
  - `argent` ;
  - `stock` (dm par tissu) ;
  - `debloques` (tissus, variantes, accessoires) ;
  - `recettes` : les 10 dernières robes, la plus récente en vitrine ;
  - `enCours` : l'étape, la commande et la recette partielle. Une déconnexion ne perd pas le travail.
- **Écriture** par `UpdateAsync`, avec un **verrou de session** `{ jobId, t }` :
  - si un autre serveur tient un verrou de moins de 90 s, on réessaie toutes les 3 s pendant 15 s au plus,
    puis on prend la main ;
  - le verrou est rafraîchi à chaque sauvegarde et relâché au départ du joueur.
- **Moments de sauvegarde** : toutes les 60 s, au départ du joueur, et à l'arrêt du serveur
  (en parallèle, 25 s au plus).
- **Protections déjà en place, gardées** : aucune écriture si la lecture a échoué ; pas de DataStore
  si `game.PlaceId == 0`.
- **Migrations** : une fonction par version de format, appliquée au chargement.
  L'ancienne clé `AtelierCouture_v1` (argent, réputation) est reprise une fois pour l'argent.

### Modération

- Les joueurs ne créent que des combinaisons d'éléments du catalogue : pas de texte libre ni d'image importée.
- La photo passe par la capture officielle (`CaptureService`).
- Un éventuel nom de robe (plus tard) passera par `TextService:FilterStringAsync`.

## 7. Tests

### Simulation automatique (`tests/lancer.sh`)

- Mettre à jour les définitions de l'API Roblox du simulateur (version de luau-lsp récente), et ajouter
  des doublures d'`AssetService`, `EditableImage` et `EditableMesh` au faux Roblox.
- **Tests de la logique pure** :
  - **Patron** : contours fermés et non croisés ; enroulement fini ; jupe hors des jambes ; bords cousus
    jointifs entre pièces voisines (écart de moins de 0,05 dm).
  - **Découpe exacte** : pour des angles de 0°, 45°, 90° et 180°, pièce pliée ou non, le pixel de l'image
    de la pièce est égal au pixel du motif sous ce point sur la table.
  - **Coupon** : chevauchement détecté ; sortie du rouleau refusée ; métrage juste.
  - **Notation** : droit-fil aux angles de référence et aimantation ; couture (seuils 0,05 et 0,30) ;
    plafond de l'assistance ; jauges ; exigences ; paie.
  - **Commandes** : chaque commande générée est réalisable.
  - **Sauvegarde** : migrations v1 → v2 ; verrou (pris, rafraîchi, volé après 15 s) ; aucune écriture
    après une lecture ratée.
- **Parcours complet par l'interface** : une robe de chaque famille, jusqu'à la vitrine.
- **Triche** :
  - découpe hors rouleau ou superposée ;
  - pièce coupée deux fois ;
  - couture trop rapide ou avec un mauvais nombre de mesures ;
  - 301 décorations ;
  - actions dans le désordre ;
  - rafales d'appels.

### Studio (par le connecteur Studio MCP)

- Une robe complète à la souris ; une robe en émulation téléphone.
- 3 joueurs simultanés (« Clients et serveur ») : attribution des boutiques, vitrines visibles par tous,
  départ d'un joueur.
- Mesures : durée de génération d'une robe, images par seconde, mémoire.

### Sur appareil réel (fait par le commanditaire)

Un lieu de test privé publié, joué sur son téléphone, avec les mesures remontées dans la sortie.

## 8. Ordre de réalisation

1. **Test de faisabilité** : une jupe en soie imprimée, coupée à 45°, générée sur PC puis sur téléphone.
   - **Mesures** : netteté, temps de génération, mémoire, rendu de `SurfaceAppearance` avec une image générée,
     utilité de `CreateDataModelContentAsync` pour les vitrines.
   - **Décision** : garder les réglages de ce document, ou ajuster les résolutions et le mode des vitrines.
   - Le code du test vit dans `spike/` et n'est gardé que s'il est propre (base de `TextureTissu` et `Patron`).
2. **Fondations** : `Catalogue`, `Patron`, `Coupon`, `Notation` et leurs tests.
3. **Chaîne de rendu** : `TextureTissu`, `ConstructeurRobe`, niveaux de détail, vitrines.
4. **Postes de jeu**, chacun jouable avant le suivant : Carnet, Achat, Découpe, Épinglage, Couture,
   Décorations, Photo et livraison.
5. **Serveur** : `Boutiques`, `Commande`, `Sauvegarde` (verrou, migrations).
6. **Finition** : caméras, sons (générés ou de la bibliothèque Roblox libre de droits), réglages mobiles,
   équilibrage des prix et des jauges, README.

## 9. Objectifs de performance

| Mesure | PC | Téléphone moyen |
|---|---|---|
| Génération d'une robe complète (robe en cours) | < 200 ms | < 600 ms |
| Images par seconde, 8 vitrines visibles | 60 | 30 |
| Mémoire Editable par client | < 32 Mo | < 32 Mo |

Un calcul de plus de 50 ms d'affilée est découpé sur plusieurs images (`task.wait()` entre les pièces),
pour ne jamais figer l'interface.

## 10. Ce que le commanditaire doit faire

- Vérifier l'identité du compte ou du groupe propriétaire et activer l'option des API Editable.
- Publier un lieu de test privé (le code, lui, est prêt à publier).
- Tester sur son téléphone et me transmettre les mesures affichées.
- Garder l'analyse HTTPS d'Avast désactivée pour Roblox Studio (exception), sinon Studio ne démarre pas.

## 11. Hors périmètre du sous-projet 1

Prise de mesures, clientes nommées et récurrentes, amitié, prestige, déblocages progressifs,
courrier, prêt-à-porter, histoire, nom définitif, porter la robe sur l'avatar, défilés, votes,
monétisation, traduction.

## Sources de l'analyse de Dressmaker

- Page Steam : https://store.steampowered.com/app/4019220/Dressmaker/ (et actualités, patchs 403 et 410)
- Succès Steam : https://steamcommunity.com/stats/4019220/achievements/
- Free Lives : https://freelives.net/games/dressmaker/
- Wikipédia : https://en.wikipedia.org/wiki/Dressmaker_(video_game)
- Prototype et journaux de développement : https://elyaradine.itch.io/dressmaker
- Presse : PC Gamer, Creative Bloq, Engadget, Screenhub, Checkpoint Gaming
- Guides, discussions et avis de joueurs Steam
- API Editable sur Roblox : https://devforum.roblox.com/t/client-beta-in-experience-mesh-image-apis-now-available-in-published-experiences/3267293
