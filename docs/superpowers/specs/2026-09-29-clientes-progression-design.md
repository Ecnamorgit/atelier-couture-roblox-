# Atelier de couture — Sous-projet 2 : clientes et progression

- Date : 29 septembre 2026
- Statut : écrite, relue et validée par l'agent, en autonomie (règles du commanditaire du 29 septembre 2026 : « ressembler le plus possible au jeu existant sur Steam », specs validées seul)
- Suit : `docs/superpowers/specs/2026-09-28-atelier-coeur-design.md` (sous-projet 1, terminé)

## 1. Contexte et objectif

Le sous-projet 1 a reproduit la boucle d'une robe : commande → carnet → achat → découpe → épinglage → couture →
décorations → photo et livraison. Dans *Dressmaker*, cette boucle s'inscrit dans une **progression** : des
clientes qui reviennent, qu'on mesure une fois, dont l'amitié débloque des patrons ; un **prestige** qui débloque
tissus et accessoires et fait monter les prix ; des robes **« prêt-à-porter »** qu'on crée librement pour les vendre
ou les offrir ; des invitations par courrier. Ce sous-projet les reproduit, avec un contenu original.

### Ce que dit l'analyse de Dressmaker (guides et avis Steam relus)

- **Mesures** : on mesure trois tours (poitrine, taille, hanches) ; une cliente déjà mesurée se reprend d'un clic.
  Le mannequin est ajusté aux mesures **prises**, et une mesure fausse fait baisser la qualité.
- **Amitié** : chaque cliente a son niveau ; il monte avec ses commandes et les cadeaux (une robe offerte).
  Les niveaux débloquent des patrons dans l'esthétique de la cliente.
- **Prestige** : le rang du joueur, gagné en livrant et en vendant ; il débloque tissus, patrons et accessoires,
  et multiplie le prix de vente (jusqu'à 150 %).
- **Prêt-à-porter** (« off the rack ») : le mode libre, débloqué après les premières commandes. Prix de vente
  ≈ (matières + main d'œuvre) × (qualité + prestige). La **toile de jute** est gratuite : idéale pour s'exercer ou
  vendre sans risque.
- **Acompte** : une commande est payée en partie au début, le reste à la livraison.
- **Courrier** : une fois la boutique lancée, des clientes écrivent ; on les invite quand on veut. Les demandes
  par courrier donnent de l'amitié en plus.

### Ce qui est repris, ce qui ne l'est pas

- **Repris** : les mécaniques ci-dessus.
- **Jamais copié** : les personnages, leurs noms, leurs histoires et dialogues, le pigeon messager, les textes.
  Nos clientes, leurs répliques et la boîte aux lettres sont originales. L'histoire viendra au sous-projet 3.

### Critères de réussite

1. Six clientes reconnaissables (nom au-dessus de la tête, tenue, style préféré) reviennent ; chacune est
   mesurée à sa première visite, puis reprise d'un clic.
2. Une mesure ratée se voit : le mannequin est faux, l'ajustement baisse la qualité.
3. Au départ, une partie du catalogue est ouverte ; le prestige ouvre tissus et accessoires, l'amitié ouvre des
   variantes. Ce qui est fermé se voit, grisé, avec ce qu'il faut pour l'ouvrir.
4. Une robe libre se vend (plus cher avec la qualité et le prestige) ou s'offre à une cliente (amitié).
5. Le serveur fait foi : mesures plausibles, déblocages vérifiés à chaque action, prix et points calculés chez lui.
6. Équilibrage vérifié par simulation : un joueur moyen (qualité 0,8) atteint le prestige 2 en 3 robes, le 5 en
   15 environ, et tout est ouvert vers 40 robes (4 à 5 heures).

## 2. Les clientes

### Les six clientes (contenu original)

| id | Nom | Taille | Styles préférés | Teinte aimée | Arrive |
|---|---|---|---|---|---|
| `colette` | Colette Marchand | M | romantique, mignon | rose | 1re commande |
| `margot` | Margot Petit | S | mignon, décontracté | jaune | 2e commande |
| `salome` | Salomé Garnier | L | décontracté, chic | vert | 3e commande |
| `helene` | Hélène Duval | M | élégant, chic | blanc | prestige 2 |
| `ines` | Inès Lebrun | S | gothique, élégant | noir | prestige 3 |
| `victoire` | Victoire Aubry | L | chic, élégant | bleu | prestige 4 |

- Chaque cliente a ses **mesures réelles**, proches de sa taille (écarts de 0,1 à 0,3 dm), et une **tenue** (couleurs
  de l'avatar construit en code). Son nom s'affiche au-dessus d'elle.
- Ses commandes tirent leurs exigences de **ses** styles et de **sa** teinte ; les valeurs demandées montent avec
  le prestige (commandes plus exigeantes plus tard). Le générateur ne propose que des commandes réalisables avec
  le catalogue **débloqué**.
- Trois répliques originales par cliente (arrivée, merci, déception), dites par sa bulle.

### Qui vient à la clochette

- Les trois premières commandes présentent Colette, Margot, Salomé, dans l'ordre.
- Ensuite, la clochette fait venir une cliente déjà rencontrée ou une nouvelle quand son seuil de prestige est
  atteint (une nouvelle venue passe avant les autres), sinon la cliente qu'on n'a pas vue depuis le plus longtemps.

### Amitié

- Points par cliente ; niveaux 0 à 5 aux seuils 0, 3, 7, 12, 18, 25.
- Robe livrée et acceptée : +2, et +1 si la qualité atteint 80 %. Commande abandonnée : −1 (jamais sous 0).
  Commande venue par lettre : +1 de plus.
- Cadeau (robe libre offerte) : +1 à +4 selon le score de son style préféré le plus haut (moins de 30 : +1 ;
  30 à 59 : +2 ; 60 à 79 : +3 ; 80 et plus : +4).
- Les niveaux 2 et 4 de chaque cliente ouvrent un élément de son style :

| Cliente | Niveau 2 | Niveau 4 |
|---|---|---|
| Colette | jupe ample froncée | dentelle blanche |
| Margot | nœud de satin | étoile brodée |
| Salomé | corsage à bretelles | galon doré |
| Hélène | col montant | broche camée |
| Inès | manches longues | croix d'argent |
| Victoire | jupe longue évasée | nœud de velours |

## 3. La prise de mesures

- **Première visite** d'une cliente : une étape « Mesures » s'intercale entre la clochette et le carnet.
- **Écran** : la silhouette de la cliente de face (2D, dessinée en code à ses vraies mesures), avec trois repères
  (poitrine, taille, hanches). Pour chacun, le joueur fait glisser l'extrémité du ruban jusqu'au bord de la
  silhouette (ou l'ajuste avec − et +, au 0,1 dm près). La mesure lue s'affiche en centimètres. « Valider les
  mesures » les envoie au serveur.
- **Retour d'une cliente** : « Reprendre ses mesures » (un clic) ou « Mesurer de nouveau ».
- **Ajustement** : écart de chaque tour e = |prise − réelle|, en dm. Ajustement = clamp(1 − Σ max(0, e − 0,2) / 1,5 ;
  0,5 ; 1). La qualité de la robe est multipliée par l'ajustement (affiché au bilan : « Ajustement : 96 % »).
- Les rubans partent courts (70 % d'une mesure de sa taille) : valider sans mesurer est refusé par le serveur
  (« Mesure invalide », écart de plus de 1,5 dm).
- **Mannequin et patron** : ils suivent les mesures **prises**. Une mesure fausse se voit donc sur le mannequin,
  à côté de la cliente.
- **Robe libre** : pas de mesures ; le joueur choisit une taille standard (S, M, L).

## 4. Prestige et déblocages

### Prestige

- Points : robe livrée acceptée : arrondi(paie / 10) ; robe vendue : arrondi(prix / 15) ; cadeau : +2.
- Niveaux 1 à 8 aux seuils 0, 20, 50, 100, 170, 260, 380, 530.
- Bonus de vente : +6 % par niveau au-delà du premier (+42 % au niveau 8).

### Ce qui est ouvert au départ, et ce qui s'ouvre

| Quoi | Au départ (prestige 1) | Ensuite |
|---|---|---|
| Tissus | toile de jute, cotons (4), lins (4) | laines au prestige 2, satins au 3, velours au 4, soies au 5 |
| Accessoires | boutons nacré et doré, fleurs rose et blanche, perle, ruban rose | ruban noir au prestige 2, dentelle noire au 3 ; les autres par l'amitié (§2) |
| Variantes | corsage droit, décolleté en V ; sans manches, ballon ; sans col, Claudine ; jupes droite et trapèze | par l'amitié (§2) |

- Chaque élément du catalogue a au plus une condition : un niveau de prestige, ou un niveau d'amitié avec une
  cliente.

- Les déblocages se **déduisent** du prestige et des amitiés : rien d'autre à sauvegarder, et un changement du
  tableau s'applique aux parties existantes.
- Dans le carnet, la palette et la liste des tissus, ce qui est fermé est grisé, avec la raison (« Prestige 3 »,
  « Amitié d'Hélène : 2 »).
- Au bilan d'une livraison ou d'une vente : les points gagnés, un niveau atteint, ce qui vient de s'ouvrir.

## 5. Les robes libres (prêt-à-porter)

- Ouvertes après la 2e commande. À l'accueil, « Robe libre » : choix de la taille, puis carnet sans exigence
  (les jauges n'ont pas de cible), achat, découpe, épinglage, couture, décorations, photo.
- À la photo, deux issues :
  - **Vendre** : prix = arrondi((matières + main d'œuvre) × (0,5 + qualité) × (1 + bonus de prestige)).
    Matières = tissu entamé de chaque rouleau × son prix au dm, plus les décorations ; main d'œuvre = 6 po par
    pièce posée. La robe part en vitrine.
  - **Offrir** à une cliente rencontrée : son amitié monte (§2), le prestige de 2 ; pas d'argent.
- La **toile de jute** (brun, style décontracté faible) est gratuite et ouverte dès le départ.

## 6. Le courrier

- Ouvert après la 5e livraison. Une boîte aux lettres sur le comptoir ; à l'accueil, jusqu'à trois lettres.
- Une lettre arrive toutes les deux livraisons (ou robes vendues), d'une cliente rencontrée tirée au hasard ; elle
  annonce une exigence de la future commande. Les lettres n'expirent pas.
- « Inviter » fait venir la cliente avec cette commande ; livrée et acceptée, elle rapporte +1 d'amitié de plus.

## 7. L'acompte

- Quand une cliente passe commande, le joueur reçoit un acompte de 25 % de la base (arrondi au-dessous).
  À la livraison acceptée : paie − acompte. Abandon : l'acompte est gardé (comme dans Dressmaker).

## 8. Serveur, triche et sauvegarde

- **Nouvelles actions** : `mesurer(prises)`, `reprendreMesures()`, `nouvelleRobeLibre(taille)`, `vendre()`,
  `offrir(idCliente)`, `inviter(indiceLettre)`. La clochette (`nouvelleCommande`) choisit la cliente côté serveur.
- **Vérifications** :
  - mesures : trois nombres finis, dans les bornes d'une recette, à moins de 1,5 dm des vraies (au-delà :
    « Mesure invalide ») ;
  - déblocages : `validerCroquis`, `acheter` et `decorer` refusent ce qui est fermé ;
  - `vendre` et `offrir` seulement à la photo d'une robe libre ; `offrir` à une cliente rencontrée ;
  - prix, points d'amitié et de prestige, acompte : calculés par le serveur.
- **État de l'atelier** : + `prestige` (points), `clientes` (`[id] = { amitie, mesures = { poitrine, taille, hanches }?,
  vues, derniereVisite }`), `lettres` (liste), `livraisons` (compteur), et dans la commande : `cliente`, `libre`,
  `mesures` prises, `acompte`.
- **Sauvegarde v3** : ces champs s'ajoutent à la partie. Migration v2 → v3 : prestige = 20 × nombre de robes
  gardées (le travail passé compte), clientes vides, pas de lettre.

## 9. Interface

- **Accueil** : la clochette ; « Robe libre » (après 2 commandes) ; les lettres (après 5) ; la jauge de prestige
  (« Prestige 3 — 62 / 100 ») ; « Carnet d'adresses » : les clientes rencontrées, leur niveau d'amitié et ce que
  le prochain niveau ouvre.
- **Mesures** : la silhouette, les trois rubans, les valeurs en cm, « Valider les mesures ».
- **Carnet, achat, décorations** : les éléments fermés grisés avec leur raison.
- **Photo d'une robe libre** : « Vendre (N po) » et « Offrir à… ».
- **Bilan** : paie (moins l'acompte), ajustement, amitié gagnée, prestige gagné, déblocages.

## 10. Tests

- **Unitaires** : clientes (données valides, mesures proches de la taille) ; commandes par cliente (réalisables avec
  le catalogue débloqué, styles de la cliente) ; ajustement ; prestige et niveaux ; déblocages ; prix de vente ;
  amitié ; lettres ; acompte ; migration v2 → v3 ; triche (mesures farfelues, variante ou tissu fermés, vendre ou
  offrir hors robe libre, offrir à une inconnue).
- **Scénario** : première visite avec mesures, puis retour avec reprise ; une robe libre vendue, une offerte ; un
  déblocage de prestige qui apparaît dans le carnet ; une lettre acceptée.
- **Équilibrage** : un joueur simulé (qualité 0,8, tissus les moins chers qui satisfont la commande) enchaîne 40 robes
  (commandes, et une robe libre de toile de jute vendue toutes les 4) : prestige 2 en 3 robes au plus, 5 entre
  12 et 20 robes, tout ouvert entre 30 et 50 ; l'argent ne descend jamais sous le prix d'une robe simple.

## 11. Découpage en plans

1. **5a — Les clientes** : les six clientes, la clochette qui les fait venir, leurs répliques et leur nom, la prise de
   mesures et l'ajustement, l'amitié ; sauvegarde v3.
2. **5b — Prestige et déblocages** : points et niveaux, catalogue fermé et grisé, vérifications du serveur, acompte,
   bilan ; simulation d'équilibrage.
3. **5c — Les robes libres** : robe libre, vente, cadeau, toile de jute.
4. **5d — Le courrier** : boîte aux lettres, lettres, invitations, carnet d'adresses ; README.

## 12. Hors périmètre

Histoire, dialogues riches, événements, nom définitif du jeu (sous-projet 3) ; porter la robe sur son avatar,
défilés et votes (sous-projet 4) ; monétisation, traduction.
