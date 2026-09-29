# Atelier de couture — jeu Roblox

Jeu de couture sur Roblox, inspiré des mécaniques de *Dressmaker* (Cozy Lives / Free Lives, 2026).
On ne choisit pas un vêtement tout fait : on **dessine**, **coupe**, **coud** et **décore** la robe,
et le tissu découpé se voit tel quel sur la robe en 3D.

Le jeu est en cours de refonte, sous-projet par sous-projet
(spec : `docs/superpowers/specs/2026-09-28-atelier-coeur-design.md`, plans : `docs/superpowers/plans/`).

## État actuel (sous-projet 1 terminé côté code, plan 4d-3 ; reste l'essai sur téléphone)

Jouable dans Studio. Une rue de 8 boutiques : à son arrivée, chaque joueur reçoit la sienne, à son nom, et
y travaille ; sa dernière robe livrée est exposée dans sa vitrine, sur la rue, où les autres joueurs la
voient. Le serveur tient l'atelier de chaque joueur et valide chaque action (il fait foi) ; le client n'affiche
qu'une copie de l'état. Dans un jeu publié, la partie est sauvegardée (argent, stock de tissu, dix dernières
robes et commande en cours : une déconnexion ne perd pas le travail) :

1. **Commande** : la clochette (ou E) fait entrer la cliente en personne (un avatar construit en code, taille S, M ou L)
   avec 1 à 3 exigences de style, de couleur, de qualité ou d'accessoire. Elle parle par une bulle.
2. **Carnet de croquis** : corsage, manches, col et jupe au choix ; un tissu par pièce (24 tissus, filtre par style).
   Les jauges de style, l'état des exigences, le métrage et le coût du tissu à acheter se mettent à jour en
   direct.
3. **Achat** : métrage conseillé par tissu, quantité réglable, coût au mètre ; toucher l'échantillon d'un tissu
   montre le rouleau conseillé, avec les pièces rangées dessus.
4. **Table de découpe** : les pièces du patron se glissent (souris ou doigt) et se tournent (boutons, R, molette
   sur la pièce) sur le rouleau, qu'on déroule en le faisant défiler (ou avec A et D). Droit-fil aimanté,
   pièces pliées coupées en double au pli, chevauchements refusés, place proposée ; une ligne marque le tissu
   entamé (couper consomme le rouleau jusqu'au bas de la pièce la plus basse).
5. **Épinglage** : le mannequin prend les mesures de la cliente ; chaque pièce touchée s'y épingle,
   dans le tissu exactement tel qu'il a été découpé.
6. **Couture** : on maintient « Coudre » (ou Espace) et on glisse pour garder l'aiguille sur le pointillé
   pendant que le tissu tire ; vitesse tortue, normale ou lapin, découd-vite, assistance (note plafonnée à 85 %).
   Une pièce finie n'est rendue qu'avec « Pièce suivante » : la dernière couture se défait encore.
7. **Décorations** : 10 objets (boutons, nœuds, fleurs, broche, perle, étoile, croix) et 5 garnitures (dentelles,
   rubans, galon). On touche la robe pour poser, on tourne (Q/E), agrandit, supprime, annule ; une garniture
   se pose point par point sur une pièce. Glisser sur la scène fait tourner la vue autour du mannequin.
   Le coût s'affiche en direct ; ce qu'on retire est remboursé.
8. **Photo et livraison** : on règle la photo (décor, lumière, couleur du mannequin) et on la prend
   (capture officielle de Roblox, sans l'interface) ; on peut l'enregistrer dans sa galerie. La cliente juge
   la robe (styles, qualité, couleur dominante, accessoires). Acceptée : paie = base × (0,5 + qualité), et la
   robe part en vitrine ; la cliente remercie et s'en va. Refusée : les exigences ratées s'affichent (avec le
   score actuel pour les styles) ; on retouche les décorations ou on abandonne.
9. La suite : sous-projet 2, clientes et progression (prise de mesures, clientes qui reviennent, déblocages,
   équilibrage des prix).

« Recommencer la robe » (le tissu coupé et les décorations posées sont perdus) et « Livrer la robe »
demandent une confirmation (deuxième appui).

**Réseau lent ou coupé** : au-delà de 0,3 s d'attente du serveur, « Un instant… » s'affiche en gris sous la
fenêtre. Un refus passager (serveur occupé ou injoignable, trop d'appels) s'affiche en gris et ne défait
rien : une pièce cousue reste finie, on la rend de nouveau. Une réponse perdue (ou une erreur du serveur) est
rattrapée : le client redemande l'état au serveur, et les actions attendent le temps de cette vérification
(rien n'est fait deux fois). Chaque refus des règles emporte l'état du serveur, qui répare la copie du
client. Si la partie n'est pas encore arrivée au bout d'une minute, le joueur en est prévenu.

**Sons** : une musique d'ambiance, un petit clic à chaque bouton, la clochette, la caisse, les ciseaux, la
machine à coudre (tant qu'on coud, au rythme de la vitesse), le tissu qu'on découd, les décorations, le
déclic de la photo et la réaction de la cliente. Tout vient de la bibliothèque libre de Roblox (sons de
l'interface de Roblox, Pro Sound Effects, APM Music) ; le bouton « Son », dans la barre de titre de la
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
  | `Notation`, `Commandes` | Droit-fil, couture, qualité, styles, exigences, paie ; commandes réalisables |
  | `Pixels` | Motifs de tissu, découpe exacte de l'image d'une pièce, silhouette du patron |
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
  l'ancienne clé `AtelierCouture_v1`) : lue à l'arrivée, écrite toutes les 60 s, au départ et à l'arrêt du
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
  l'avatar de la cliente et sa bulle ; `Scene` tient, dans la boutique du joueur, la cliente, le mannequin,
  la robe épinglée, l'aperçu des décorations, les réglages de la photo et la caméra du poste ; `Sons` joue
  les bruits et la musique ; un module `Ecran…` par étape.

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
