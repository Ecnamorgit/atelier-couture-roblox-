# Aiguille & Dentelle — jeu Roblox

Jeu de couture sur Roblox, inspiré des mécaniques de *Dressmaker* (Cozy Lives / Free Lives, 2026).
On ne choisit pas un vêtement tout fait : on **dessine**, **coupe**, **coud** et **décore** la robe,
et le tissu découpé se voit tel quel sur la robe en 3D.

Le jeu est en cours de refonte, sous-projet par sous-projet
(specs : `docs/superpowers/specs/2026-09-28-atelier-coeur-design.md` pour le cœur de l'atelier,
`docs/superpowers/specs/2026-09-29-clientes-progression-design.md` pour les clientes et la progression,
`docs/superpowers/specs/2026-09-30-histoire-evenements-design.md` pour l'histoire,
`docs/superpowers/specs/2026-09-30-ampleur-contenu-design.md` pour l'ampleur du catalogue et du quartier,
`docs/superpowers/specs/2026-09-30-fidelite-dressmaker-design.md` pour la fidélité à la présentation de
*Dressmaker*, `docs/superpowers/specs/2026-09-30-atelier-fidele-design.md` pour l'atelier plus fidèle ; plans :
`docs/superpowers/plans/`).

## État actuel (sous-projet 9 en cours, plan 27 : les premiers pas — le bandeau, l'accueil, les mesures)

Jouable dans Studio. Une rue de 8 boutiques : à son arrivée, chaque joueur reçoit la sienne, à son nom, et
y travaille ; sa dernière robe livrée est exposée dans sa vitrine, sur la rue, où les autres joueurs la
voient. Le serveur tient l'atelier de chaque joueur et valide chaque action (il fait foi) ; le client n'affiche
qu'une copie de l'état. Dans un jeu publié, la partie est sauvegardée (argent, stock de tissu, dix dernières
robes et commande en cours : une déconnexion ne perd pas le travail).

**Les premiers pas** (sous-projet 9) : à la première robe (aucune robe livrée ni vendue), un bandeau sur la barre de
titre de la fenêtre donne un conseil à la fois et entoure d'un anneau l'élément à toucher ; chaque conseil s'efface
quand le geste est fait. Ensuite, le bouton « ? » de la barre de titre les rappelle. Pour l'instant : l'accueil (la
clochette), les mesures (tourner une molette, ajuster les trois bandes, valider) et la couture (ses propres conseils).

Une commande, poste par poste :

1. **Commande** : la clochette (ou E) fait entrer une cliente en personne (un avatar construit en code, son nom
   au-dessus de la tête), avec 1 à 3 exigences tirées de ses styles préférés, de sa teinte et de son occasion. Dix clientes, qui
   reviennent : Colette, Margot et Salomé aux trois premières commandes ; Hélène, Inès et Victoire quand le
   prestige de l'atelier atteint 2, 3 puis 4 ; Apolline, Joséphine, Capucine et Maëlle aux prestiges 5 à 8 ;
   ensuite, celle qu'on n'a pas vue depuis le plus longtemps. Chacune
   parle avec ses propres mots (présentation, arrivée, merci, déception) : fenêtre de l'atelier ouverte, dans un
   encadré à son prénom, en haut à gauche de l'écran (un appui le referme jusqu'à sa prochaine parole), avec son
   **portrait** dessiné au crayon (sa coiffure, sa tenue ; contente, neutre ou déçue selon ce qu'elle dit et son
   avis ; une illustration téléversée pourra le remplacer, l'initiale de son prénom si la mémoire des images est
   pleine) ; fenêtre fermée, dans une bulle au-dessus de sa tête. En passant commande,
   elle verse un **acompte** (un quart de la base d'une robe simple), déduit de la paie ; gardé si on abandonne.
   **Mesures** : à sa première visite, on la mesure sur un mannequin de couture à trois molettes (poitrine,
   taille, hanches), sa silhouette en pointillé par-dessus : on tourne chaque molette (en glissant de haut en bas,
   à la molette de la souris, ou avec − et +, 0,1 dm par cran) jusqu'à ce que le mannequin l'épouse. Le serveur
   refuse une mesure à plus de 1,5 dm de la vraie. Quand elle revient, la fiche donne ses mesures du carnet, et
   « Reprendre ses mesures » les reprend. Le mannequin et le patron suivent les mesures prises ; l'ajustement
   (100 % jusqu'à 0,2 dm d'écart par tour, puis moins, 50 % au pire) multiplie la qualité de la robe.
2. **Carnet de croquis** : une page de carnet (papier, notes de tailleur, crayon). Au centre, la robe dessinée
   au trait, de face, sur un mannequin esquissé : elle change avec chaque modèle et se colorie du motif de chaque
   tissu choisi ; toucher une partie du dessin ouvre le choix de son tissu. Dessous, une ligne par famille
   (corsage, col, manches, jupe) : ◀ le nom du modèle ▶ et un point par modèle (25 variantes : sept corsages dont
   le cache-cœur, le bustier, le corsage à basque et le corsage ceinturé, cinq manches, quatre cols dont le col
   marin, neuf jupes dont la jupe crayon et les jupes à volant, à étages, à jupon et à traîne). **Des couches** : la
   basque s'évase sous la taille, par-dessus la jupe ; le volant, froncé, part à 5 dm sous la taille et dépasse
   l'ourlet ; l'étage, une large bande froncée, couvre le bas de la jupe droite ; le jupon dépasse sous la jupe de
   dessus ; la ceinture se pose à la taille, par-dessus le corsage ; la traîne continue la jupe longue à plat sur
   le sol, vers l'arrière. Chacun a ses pièces (volant, basque et ceinture : poids 0,5 dans la paie), son tissu et
   sa partie du dessin (la toucher choisit le tissu de ses pièces). La liste des pièces défile.
   À côté du dessin, un tissu par pièce (41 tissus en onze matières, filtre par style ou par occasion, dont la
   toile de jute, gratuite ; chaque carte montre les quatre étiquettes les plus fortes du tissu) ; les échantillons
   des tissus choisis sont épinglés en haut de la page ; « Environ X m de tissu » ; « Tracer le patron ». La fiche
   de la commande, à droite : les jauges des étiquettes demandées et des styles de la cliente (les six styles pour
   une robe libre), état des exigences, coût du tissu
   à acheter, à jour en direct (la plage d'une jauge ne compte que les tissus ouverts). Un modèle pas encore
   ouvert est grisé, avec ce qu'il faut pour l'ouvrir (« Prestige 3 », « Amitié d'Hélène : 2 ») ; son patron
   ne se trace pas, et le serveur le refuse aussi.
3. **Achat** : métrage conseillé par tissu, quantité réglable, coût au mètre ; toucher l'échantillon d'un tissu
   montre le rouleau conseillé, avec les pièces rangées dessus. Pour un rouleau entamé, la quantité proposée ne
   compte que le tissu neuf (« Neuf : 9 dm (11 entamés) »).
4. **Table de découpe** : les pièces du patron se glissent (souris ou doigt) et se tournent (boutons, R, molette
   sur la pièce) sur le rouleau, qu'on déroule en le faisant défiler (ou avec A et D). Droit-fil aimanté,
   pièces pliées coupées en double au pli, chevauchements refusés, place proposée (tant qu'on suit les propositions,
   celle que prévoit le métrage conseillé : la robe y tient, même avec de larges étages) ; une ligne marque le tissu
   entamé. **Le tissu entamé** : les pièces coupées laissent leurs trous dans une bande en haut du rouleau, qui reste
   dans le stock ; à la robe suivante dans ce tissu, les trous sont grisés et interdits, on coupe dans leurs vides
   ou dessous (« Proposer une place » les évite). Sous « Couper », le compteur du rouleau : « 1,10 m entamés /
   3,00 m » et « Cette robe : +0,60 m (3 po) ». « Jeter la bande » (deuxième appui pour confirmer) la retire du stock
   tant qu'aucune pièce de ce tissu n'est coupée pour la robe : le rouleau repart neuf. Au-delà de 24 trous ou de
   5 m, la bande est jetée d'elle-même, et on l'annonce. Une robe libre compte en matières ce qu'elle ajoute à la
   bande.
5. **Épinglage** : le mannequin prend les mesures de la cliente ; chaque pièce touchée s'y épingle,
   dans le tissu exactement tel qu'il a été découpé. Les couches (volant, basque) viennent en fin de liste : elles se
   posent par-dessus les autres pièces.
6. **Couture** : on maintient « Coudre » (ou Espace) pour faire avancer le tissu, et on le fait pivoter (A / D,
   ← / →, les boutons ◀ ▶, ou en glissant) pour garder l'aiguille sur le pointillé ; le tissu tire un peu (davantage
   s'il glisse : soie, satin, organza, tulle) ; dans un angle, on s'arrête et on pivote. Vitesse tortue, normale ou
   lapin (W / S), découd-vite ; l'assistance tient la ligne mais ne s'arrête pas dans les angles (note plafonnée à
   85 %). La couture se voit en direct : l'aiguille et les points verts sur la ligne, orange puis rouges quand on
   s'en écarte ; une jauge de précision ; l'angle qui vient est marqué sur le pointillé et annoncé ; « Pivote »
   quand le tissu penche trop ; « Parfait ! » salue une couture sans faute ; le tissu dit s'il glisse. À la
   première robe, des conseils pas à pas (chacun s'efface quand on l'a fait) ; le bouton « ? » les rappelle.
   Une pièce finie n'est rendue qu'avec « Pièce suivante » : la dernière couture se défait encore. La dernière
   pièce cousue, la robe est terminée : une pluie de confettis et un petit son de fête.
7. **Décorations** : 30 objets (boutons, nœuds, papillon, fleurs, broches, perles, étoile, croix, couronne,
   violette, boucle, coquillage, et les douze souvenirs du quartier une fois leur événement passé) et 9 garnitures
   (dentelles, rubans, galons). On touche la robe pour poser, on tourne (Q/E), agrandit, supprime, annule ; une garniture
   se pose point par point sur une pièce. Glisser sur la scène fait tourner la vue autour du mannequin.
   **La mercerie** : les décorations s'achètent d'avance, en stock (à l'unité, les garnitures par 50 cm), dans
   la **Mercerie** qu'on ouvre depuis l'accueil ou depuis les décorations, sans quitter la robe ; toute partie
   commence avec un kit (boutons, perles, fleurs, 1,50 m de ruban rose). La palette dit ce qu'il reste de chaque
   article (« Perle · ×12 », « Ruban rose · 1,50 m ») et grise ce qui est épuisé ; l'article choisi montre ce que
   la robe en prend (« Ruban rose : 0,20 / 1,50 m »). Poser prend au stock, retirer y rend ; au carnet, une
   exigence d'accessoire dit ce qu'on en a. Chaque événement qui a lieu offre cinq exemplaires de son souvenir.
8. **Photo et livraison** : on règle la photo (décor, lumière, couleur du mannequin) et on la prend
   (capture officielle de Roblox, sans l'interface) ; on peut l'enregistrer dans sa galerie. La cliente juge
   la robe (styles, qualité, couleur dominante, accessoires). Acceptée : paie = base × (0,5 + qualité), et la
   robe part en vitrine ; la cliente remercie et s'en va. Refusée : les exigences ratées s'affichent (avec le
   score actuel pour les styles) ; on retouche les décorations ou on abandonne.
   **Seize étiquettes** (sous-projet 7) : aux six styles s'ajoutent trois occasions (Journée, Soirée, Travail :
   points des variantes et des matières) et sept traits calculés d'après la robe : Légère / Chaude (matière,
   manches, longueur de la jupe), Sobre / Travaillée (poids des pièces, décorations), Unie / Fleurie / À motifs
   (surface de chaque motif) ; et la matière dominante. Les commandes les demandent au fil du prestige : Journée et
   Travail au 2, la matière (« Matière dominante : crêpe ») au 3, la Soirée et les traits au 4, chacune quand elle
   peut atteindre 60 ; jamais deux exigences contraires (Légère et Chaude, une robe légère en velours, Travaillée
   et un « au plus »…). Chaque cliente a son occasion préférée ; à partir de la kermesse, chaque événement impose
   la sienne (le bal d'hiver : la soirée).
   **Avis en étoiles** : refusée, une étoile ; acceptée, deux, plus une à 60, 80 et 90 % de qualité (dans
   l'encadré de la cliente et l'annonce de l'accueil) ; rien n'en dépend.
   **Amitié et prestige** : une robe acceptée vaut +2 d'amitié avec la cliente (+1 de plus à 80 % de qualité),
   un abandon −1 ; niveaux 0 à 5 (seuils 3, 7, 12, 18, 25). Elle rapporte aussi du prestige à l'atelier
   (paie / 10) ; niveaux 1 à 8. L'accueil annonce ce qui a été gagné, et montre la jauge de prestige avec le
   titre de la réputation (« Réputation : Appréciée (prestige 3) — 62 / 100 » ; Inconnue, Remarquée, Appréciée,
   Renommée, Réputée, Célèbre, Illustre, Légendaire). Un abandon ne fait jamais perdre un niveau d'amitié.
   **Rang** de la couturière, selon les robes livrées ou vendues : Débutante, Apprentie (5), Couturière (15),
   Première main (30), Maîtresse couturière (60) ; en tête du carnet d'adresses et à la vente, annoncé quand il
   monte (« Nouveau rang : Couturière ! »).
   **Déblocages** : au départ, cotons, lins et toile de jute, huit variantes et six accessoires. Le prestige ouvre les laines (2),
   les satins (3), les velours (4), les soies (5), le crêpe et l'organza (6), le brocart (7) et le tulle (8) ; le
   ruban noir (2), la dentelle noire (3) et deux décorations par niveau du 5 au 8 ; les manches courtes (6) et la
   jupe crayon (7) ; l'amitié de chaque cliente (niveaux 2 et 4) ouvre une variante ou un accessoire de son
   style (celle des quatre dernières : le cache-cœur, les manches trois-quarts, le bustier et le col marin, puis
   une décoration). Avec le bustier, manches et col se portent détachés, épaules nues. Rien n'est sauvegardé :
   tout se déduit du prestige et des amitiés. Les commandes ne demandent que ce qui est ouvert, et leurs
   exigences de style montent avec le prestige. L'accueil annonce ce qui vient de s'ouvrir, et une affiche
   « Nouveautés à l'atelier ! » le montre (une carte par nouveauté, huit au plus, l'échantillon de chaque tissu).
   **Robes libres** (après deux commandes livrées) : « Robe libre » à l'accueil, une taille (S, M, L), et l'on
   va droit au carnet, sans cliente ni exigence. À la photo : « Vendre » (prix = (matières + décorations +
   6 po par pièce) × (0,5 + qualité), +6 % par niveau de prestige au-delà du premier ; du prestige, un quinzième
   de la main d'œuvre, qui ne s'achète pas en décorant) ou « Offrir à… » une cliente déjà venue (+1 à +4 d'amitié selon le score de son style préféré,
   +2 de prestige). La robe part en vitrine.
   **Courrier** (après cinq commandes livrées) : une lettre arrive toutes les deux robes livrées ou vendues, d'une
   cliente déjà venue, et dépasse de la boîte aux lettres du comptoir ; l'accueil montre jusqu'à trois lettres,
   chacune avec la première exigence de la commande qu'elle annonce. « Inviter » fait venir la cliente avec cette
   commande ; livrée et acceptée, elle rapporte un point d'amitié de plus. Les lettres n'expirent pas.
   **Carnet d'adresses** : les clientes déjà venues, leur portrait (contente à partir d'une amitié de niveau 3),
   leur niveau d'amitié (points et seuil suivant) et ce que le prochain niveau ouvrira ; la liste défile.
   **Équilibrage** (simulé par les tests, sur vingt parties) : un joueur moyen (qualité 0,8, une robe libre de
   jute vendue sur quatre robes, les lettres invitées) atteint le prestige 2 à la 3e robe au plus tard, le 5 vers
   la 19e, le 8 vers la 57e, et tout est ouvert vers la 123e (médianes, parties de 160 robes : l'amitié des quatre
   dernières clientes, arrivées aux prestiges 5 à 8, ouvre les dernières variantes). Le tirage d'une commande ne recalcule
   jamais les styles robe par robe (les points de chaque variante et de chaque tissu sont précalculés ; les tissus
   d'une autre teinte, matière ou motif que ceux demandés sont écartés d'abord ; la recherche avance famille par
   famille et abandonne une branche qui ne peut plus tenir une exigence).
9. **L'histoire** : douze événements du quartier se suivent (le bal des lanternes, la kermesse, le vernissage, les
   régates, la veillée des contes, le mariage de Margot, le concert du kiosque, le grand bal d'hiver, le salon du
   livre, la première du théâtre, le mariage de Colette, le grand défilé du quartier). Le premier
   s'annonce après trois commandes livrées, les suivants à leur prestige. « Commande de l'événement » ouvre une
   conversation avec la cliente (pourquoi elle a besoin de cette robe, ce qu'elle voudrait), puis la commande,
   avec une tenue imposée. Toutes les robes livrées, l'événement a lieu : son épilogue fait la une de « La Gazette
   du Dé », le journal du quartier (numéro, jour de l'atelier, titre, texte en deux colonnes), avec un souvenir (une
   des douze décorations nouvelles) et 15 de prestige ; le carnet d'adresses garde les souvenirs. Les commandes
   ordinaires continuent à côté.
   **Le chat** : un chat roux dort sur son coussin près de la fenêtre de chaque boutique ; « Caresser » (touche F)
   le fait ronronner, remuer la queue, et de petits cœurs montent. Pour le plaisir seulement.
10. La suite : porter la robe sur son avatar et les défilés entre joueurs, ou d'autres écarts avec *Dressmaker*
   (robes plus riches, étiquettes de style, portraits des clientes) : à décider.

« Recommencer la robe » (les décorations posées sont perdues ; le tissu coupé reste en trous sur le rouleau) et
« Livrer la robe »
demandent une confirmation (deuxième appui).

**Réseau lent ou coupé** : au-delà de 0,3 s d'attente du serveur, « Un instant… » s'affiche en gris sous la
fenêtre. Un refus passager (serveur occupé ou injoignable, trop d'appels) s'affiche en gris et ne défait
rien : une pièce cousue reste finie, on la rend de nouveau. Une réponse perdue (ou une erreur du serveur) est
rattrapée : le client redemande l'état au serveur, et les actions attendent le temps de cette vérification
(rien n'est fait deux fois). Chaque refus des règles emporte l'état du serveur, qui répare la copie du
client. Si la partie n'est pas encore arrivée au bout d'une minute, le joueur en est prévenu.

**Sons** : une musique d'ambiance, un petit clic à chaque bouton, la clochette, la caisse, les ciseaux, la
machine à coudre (tant qu'on coud, au rythme de la vitesse), le tissu qu'on découd, les décorations, le
déclic de la photo, la fête de la robe terminée, la réaction de la cliente et le ronron du chat. Tout vient de
la bibliothèque libre de Roblox (sons de
l'interface de Roblox, Pro Sound Effects, APM Music ; pour le chat, « cat purring », envoyé par Bloonkii sur
la boutique des créateurs de Roblox) ; le bouton « Son », dans la barre de titre de la
fenêtre, coupe tout.

**Téléphone et clavier** : tant que la fenêtre de l'atelier est ouverte, l'avatar ne bouge pas (le stick et
le bouton de saut ne passent pas sous la fenêtre) ; on la ferme pour se promener dans la rue, et le bouton
« Atelier » la rouvre. La fenêtre se réduit pour tenir dans l'écran.

## Installation

```bash
rojo serve        # dans ce dossier, puis « Connect » depuis le plugin Rojo dans Roblox Studio
# ou
rojo build -o AtelierCouture.rbxl
```

Dans les paramètres du jeu publié, régler **Max Players à 8** : la rue compte 8 boutiques (un joueur de plus
travaillerait hors de la rue, sans vitrine).

Le fichier `AtelierCouture.rbxl` fourni est prêt à ouvrir. Après une modification du code, le régénérer avec
`rojo build -o AtelierCouture.rbxl`. Le rendu 3D des robes utilise les API EditableMesh / EditableImage :
dans un jeu publié, le compte propriétaire doit être vérifié (13 ans et plus) et avoir activé ces API.

## Architecture

- `src/shared/` (ReplicatedStorage.Couture) : logique partagée, sans interface.
  | Module | Rôle |
  |---|---|
  | `Polygone`, `Patron` | Géométrie 2D des pièces, enroulement 3D autour du corps |
  | `Catalogue` | Pièces, variantes, tissus, accessoires, constantes |
  | `Coupon`, `Metrage` | Rouleau de découpe (pli, chevauchements) et métrage conseillé |
  | `Notation`, `Commandes` | Droit-fil, couture, qualité, styles, exigences, paie, ajustement aux mesures ; commandes réalisables, d'après les goûts de la cliente |
  | `Etiquettes` | Occasions et traits calculés (chaleur, richesse, motifs), matière dominante, fourchette du carnet |
  | `Clientes`, `Progression` | Les dix clientes (mesures, tenue, goûts, répliques) et qui vient à la clochette ; amitié, prestige et leurs niveaux ; avis en étoiles, titres de la réputation, rang de la couturière |
  | `Deblocages` | Ce qui est fermé au départ et ce qui l'ouvre (prestige, amitié, événement) ; ce qu'une livraison vient d'ouvrir ; ce que l'amitié d'une cliente ouvrira ensuite |
  | `Histoire` | Les douze événements du quartier : leurs robes, tenues, répliques, épilogues et souvenirs ; l'événement en cours et sa prochaine robe |
  | `Croquis`, `Pixels` | Dessin de face de chaque modèle (formes des parties, plis, mannequin) ; motifs de tissu, découpe exacte de l'image d'une pièce, silhouette du patron, croquis colorié du carnet, portrait au crayon de chaque cliente |
  | `Recette` | Recette d'une robe en JSON et validation complète (filtre du serveur au plan 4) |
  | `Maillage`, `Mannequin`, `Editables`, `ConstructeurRobe`, `Vitrines` | Robe 3D, mannequin, vitrines |
  | `Boutique` | Plan d'une boutique (repère local) et les 8 emplacements de la rue |
  | `EtatAtelier` | État de la commande et règles de chaque étape, relevé de couture vraisemblable, recette de la robe ; copie de l'état en données simples (`exporter`, `charger`) |
- `src/server/` (Script `Atelier` de ServerScriptService et ses modules) : le serveur, qui fait foi.
  `Commande` tient l'atelier de chaque joueur (un `EtatAtelier`) derrière la RemoteFunction `Atelier` :
  actions permises seulement, 5 appels par seconde au plus (sauf les relevés de couture, bornés par leur
  vraisemblance), toute erreur devient un refus ; chaque réponse acceptée emporte l'état. `Limiteur` compte
  les appels. `Sauvegarde` range la partie de chaque joueur dans le DataStore `AtelierCouture_v2` (une clé
  par joueur, écriture par `UpdateAsync` avec un verrou de session, migrations, reprise de l'argent de
  l'ancienne clé `AtelierCouture_v1` ; partie v3 depuis le plan 5a : prestige, fiches des clientes ; v4 depuis
  le plan 16 : la mercerie, et un kit de départ offert aux parties existantes) : lue à l'arrivée, écrite toutes les 60 s, au départ et à l'arrêt du
  serveur. Rien n'est écrit si la lecture a échoué (le joueur est prévenu), ni sur un lieu non publié.
  Une écriture à la fois par joueur (la sauvegarde régulière et celle du départ ne se croisent pas, et un
  retour rapide sur le même serveur attend l'écriture du départ) ; à l'arrêt du serveur, les parties en
  cours de lecture sont attendues ; une partie trop lourde (plus de 3,5 millions de caractères) perd ses
  plus anciennes robes.
  `Boutiques` construit la rue : une boutique par joueur (murs, porte et fenêtre, enseigne à son nom,
  comptoir et clochette, étagère de tissus, table de découpe sur pieds avec son tapis quadrillé, son rouleau
  et ses ciseaux, machine à coudre sur son meuble, avec son volant et sa bobine), et le socle de sa vitrine, qui porte la
  recette de sa dernière robe livrée (attribut `Recette`) ; chaque client construit les robes proches.
  Une boutique impossible à construire n'empêche pas de jouer : l'atelier est alors hors de la rue.
- `src/client/Atelier/` (LocalScript `Atelier` et ses modules) : l'interface.
  `Session` envoie chaque action au serveur (une à la fois) et recharge sur place la copie de l'état qu'il
  renvoie, acceptée ou refusée ; elle signale l'attente à l'interface et redemande l'état après une réponse
  perdue. `TableDecoupe` et `MachineCoudre` sont la logique pure de la table
  de découpe, de la machine à coudre et de l'éditeur de décorations (`Decorateur`) ; `Cliente` construit
  l'avatar de la cliente et sa bulle ; `Dialogue`, l'encadré où elle parle fenêtre ouverte ; `Portrait`, son
  médaillon (dessin, illustration ou initiale) ; `Confettis`, la
  pluie de la robe terminée ; `Chat`, les caresses au chat de l'atelier ; `Scene` tient, dans la boutique du
  joueur, la cliente, le mannequin,
  la robe épinglée, l'aperçu des décorations, les réglages de la photo et la caméra du poste ; `Sons` joue
  les bruits et la musique ; un module `Ecran…` par étape (`EcranMesures` : le mannequin à molettes, `Molette` : le réglage d'une
  molette) ; `Mercerie` : la boutique de la mercerie, par-dessus l'accueil ou les décorations.

**Tester la sauvegarde** : un lieu non publié (fichier local, `game.PlaceId == 0`) ne sauvegarde pas.
Publier un lieu de test privé et activer « Autoriser l'accès de Studio aux services d'API » (paramètres du
jeu, Sécurité) ; la logique (verrou, migrations, protections) est vérifiée par la simulation.

**Limite assumée (couture)** : le relevé de l'aiguille vient du client. `EtatAtelier` vérifie qu'il est
vraisemblable (une mesure tous les 0,1 dm de trajet à 2 près, écarts d'au plus 2 dm, durée compatible avec
la vitesse maximale), mais un tricheur peut s'attribuer une bonne couture. L'enjeu se limite à la qualité
de la robe, donc à un peu d'argent.

## Tests

`bash tests/lancer.sh` (Linux, macOS ou Windows via Git Bash, avec Python 3) exécute le code du jeu dans un
Roblox simulé, validé d'après les définitions officielles de l'API (luau-lsp 1.70.1) :
- les tests unitaires de `tests/unitaires/` (logique, géométrie, rendu avec doublures des API modifiables) ;
- `tests/scenario.luau` : le serveur et le client démarrés comme dans le jeu, une commande jouée de bout en
  bout en cliquant dans l'interface, puis des tentatives de triche (appels directs au serveur).

Ce qu'une simulation ne voit pas (rendu, glisser au doigt, tailles d'écran) se vérifie dans Studio :
bancs d'essai `tests/studio/` et rapport `docs/superpowers/spikes/2026-09-28-rendu-editable.md`.
