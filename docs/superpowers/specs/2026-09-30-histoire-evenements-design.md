# Aiguille & Dentelle — Sous-projet 3 : l'histoire et les événements du quartier

- Date : 30 septembre 2026
- Statut : écrite, relue et validée par l'agent, en autonomie (règles du commanditaire du 29 septembre 2026 : « ressembler le plus possible au jeu existant sur Steam », specs validées seul)
- Suit : `docs/superpowers/specs/2026-09-29-clientes-progression-design.md` (sous-projet 2, clientes et progression)

## 1. Contexte et objectif

Les sous-projets 1 et 2 ont reproduit la fabrication d'une robe et la progression (clientes qui reviennent,
mesures, amitié, prestige, déblocages, robes libres, courrier). Dans *Dressmaker*, tout cela sert une **histoire** :
les commandes des habitants se rassemblent autour d'**événements** de la ville, l'un après l'autre, et chaque
cliente fait avancer sa propre intrigue par ses conversations. Ce sous-projet reproduit cette structure, avec
un contenu entièrement original, et donne au jeu son nom définitif.

### Ce que dit l'analyse de Dressmaker

- L'histoire est une suite de commandes de dix habitants récurrents, regroupées autour d'événements de la ville
  (une quinzaine), débloqués l'un après l'autre ; chaque événement a son thème et ses contraintes de tenue
  (couleurs imposées, motifs voyants…).
- L'histoire avance par les conversations avec les clientes, au fil de leurs commandes ; il n'y a pas de délai
  ni de pénalité : on avance à son rythme.
- Terminer toutes les robes d'un événement le fait avoir lieu (un succès Steam par événement).

### Ce qui est repris, ce qui ne l'est pas

- **Repris** : la structure (événements successifs, commandes d'histoire à tenue imposée, conversations, un
  souvenir de chaque événement), l'absence de délai.
- **Jamais copié** : les événements, les personnages, les dialogues, les noms. Les nôtres : six clientes du
  sous-projet 2, huit événements du quartier, nos textes.

### Critères de réussite

1. Huit événements originaux se suivent ; chacun demande deux à quatre robes à des clientes connues, avec une
   tenue imposée (thème) et quelques répliques qui racontent leur histoire.
2. Livrer toutes les robes d'un événement le fait avoir lieu : un épilogue à l'accueil, un souvenir (une
   décoration nouvelle), du prestige ; l'événement suivant s'annonce.
3. Les commandes ordinaires (clochette, courrier, robes libres) continuent à côté : on choisit quand avancer
   l'histoire.
4. Le serveur fait foi : commandes d'histoire tirées du tableau, jamais d'un appel du client ; progression
   sauvegardée.
5. Le jeu porte son nom définitif, original : **Aiguille & Dentelle**.

## 2. Les événements (contenu original)

Chaque commande d'histoire a une cliente, des exigences fixes (réalisables avec ce qui est ouvert au prestige
de l'événement, amitiés à zéro) et trois répliques : **demande** (pourquoi elle a besoin de cette robe), **détail**
(ce qu'elle voudrait) et **merci** (après la livraison, la suite de son histoire).

| # | id | Événement | Prestige | Commandes (cliente : tenue) | Souvenir |
|---|---|---|---|---|---|
| 1 | `lanternes` | Le bal des lanternes | 1 (après 3 livraisons) | Colette : mignon ≥ 30, rose ; Margot : mignon ≥ 30, fleur rose | Lanterne de papier |
| 2 | `kermesse` | La kermesse du square | 2 | Margot : mignon ≥ 30, jaune ; Salomé : décontracté ≥ 30, vert | Cocarde |
| 3 | `vernissage` | Le vernissage de la galerie | 2 | Hélène : chic ≥ 30, perle ; Salomé : chic ≥ 30, décontracté ≤ 30 | Broche palette |
| 4 | `regates` | Les régates du lac | 3 | Colette : mignon ≥ 20, bleu ; Hélène : chic ≥ 30, bleu | Ancre dorée |
| 5 | `veillee` | La veillée des contes | 3 | Inès : gothique ≥ 30, noir ; Hélène : élégant ≥ 40, mignon ≤ 20 | Plume de corbeau |
| 6 | `mariage` | Le mariage de Margot | 5 | Margot : élégant ≥ 30, blanc, perle ; Colette : romantique ≥ 30, rose ; Victoire : élégant ≥ 40 | Fleur d'oranger |
| 7 | `kiosque` | Le concert du kiosque | 5 | Salomé : chic ≥ 40 ; Inès : gothique ≥ 40 ; Victoire : chic ≥ 30, bleu | Clé de sol |
| 8 | `bal_hiver` | Le grand bal d'hiver | 6 | Colette : romantique ≥ 45 ; Hélène : élégant ≥ 45 ; Inès : gothique ≥ 40 ; Victoire : élégant ≥ 45, blanc | Flocon d'argent |

- Chaque tenue est réalisable avec ce qui est ouvert au prestige de l'événement, amitiés à zéro, souvenirs des
  événements d'avant ouverts (vérifié par une sonde, puis par un test) : le mariage attend le prestige 5, où la
  soie ivoire s'ouvre. Une commande d'histoire peut faire venir une cliente pour la première fois.
- **Arcs des clientes** (grandes lignes, textes au plan) : Colette, romantique, rencontre quelqu'un au bal des
  lanternes et l'emmène aux régates ; Margot organise la kermesse puis se marie ; Salomé, jardinière, expose ses
  herbiers au vernissage puis joue au kiosque ; Hélène, ancienne danseuse, retrouve la scène ; Inès, conteuse,
  anime la veillée puis le concert ; Victoire, qui ouvre le grand bal d'hiver, se révèle la marraine du quartier.
- **Épilogue** : deux phrases par événement, dites à l'accueil quand il a lieu.
- **Souvenirs** : huit décorations nouvelles (objets, formes existantes : boule, bloc, cylindre, nœud, fleur,
  croix), chacune ouverte par son événement ; prix et style dans l'esprit du catalogue.

## 3. Comment avance l'histoire

- L'**événement en cours** est le premier qui n'a pas eu lieu. Il s'annonce à l'accueil dès que ses conditions
  sont remplies (prestige atteint ; le premier après trois livraisons) : « Bientôt : Le bal des lanternes —
  robes livrées 1 / 2 ».
- « Commande de l'événement » fait venir la cliente de la prochaine commande d'histoire de l'événement (dans
  l'ordre du tableau) : une **conversation** s'ouvre (demande, détail ; « Suivant »), puis la commande commence
  comme les autres (visite notée, acompte, mesures, carnet…). La cliente la dit aussi dans sa bulle.
- Livrée et acceptée : la commande est faite ; la cliente dit sa réplique « merci » (au lieu de sa phrase
  habituelle). Refusée puis abandonnée : elle reste à faire (on la reprend quand on veut).
- Toutes les commandes faites : l'événement **a lieu** : épilogue à l'accueil, souvenir ouvert, +15 de prestige ;
  l'événement suivant s'annonce (s'il est ouvert).
- La clochette, le courrier et les robes libres continuent comme avant. Une commande d'histoire rapporte comme
  une commande ordinaire (paie, amitié, prestige).

## 4. Serveur et sauvegarde

- **Nouvelle action** : `commandeHistoire()` — le serveur prend la prochaine commande de l'événement en cours ;
  refus si aucun événement n'est ouvert, ou si une commande est en cours.
- **État** : `histoire = { faites = { [idCommande] = true } }` (ce qui a eu lieu s'en déduit : rien d'autre à
  croire du stockage) ; la commande d'histoire porte `histoire = idCommande`.
- **Sauvegarde** : `histoire` s'ajoute à la partie (champ absent : rien de fait) ; les identifiants inconnus sont
  laissés ; une commande d'histoire en cours d'un identifiant inconnu est abandonnée.
- **Déblocages** : une nouvelle sorte de condition, `{ evenement = id }`, pour les souvenirs.

## 5. Interface

- **Accueil** : une ligne « Événement » (nom, avancée, « Commande de l'événement ») sous la jauge de prestige ;
  quand un événement a lieu, un panneau par-dessus l'accueil (« Le bal des lanternes a eu lieu ! », l'épilogue,
  le souvenir et le prestige, « Fermer ») ; les événements passés et leurs souvenirs en bas du carnet d'adresses.
- **Conversation** : un panneau sur la fenêtre, le nom de la cliente et sa réplique, « Suivant », puis
  « Accepter la commande ».
- **Nom du jeu** : « Aiguille & Dentelle » dans le titre de l'accueil, l'enseigne des boutiques (« Aiguille &
  Dentelle — <joueur> ») et le README.

## 6. Tests

- **Unitaires** : tableau des événements (clientes connues, exigences réalisables au prestige de l'événement,
  répliques non vides, souvenirs dans le catalogue) ; progression (ouverture, ordre, commande faite, abandon,
  événement qui a lieu, récompense, sauvegarde et relecture) ; triche (commande d'histoire hors d'accueil, sans
  événement ouvert).
- **Scénario** : le premier événement s'annonce après trois livraisons ; conversation, commande, livraison ;
  l'événement a lieu, le souvenir s'ouvre.

## 7. Découpage en plans

Un seul plan, **6 — L'histoire** : données (événements, commandes, répliques, souvenirs), règles, action du
serveur, sauvegarde, déblocages des souvenirs ; puis l'interface (accueil, conversation, bulles, épilogue,
souvenirs dans le carnet d'adresses), le nom du jeu et le README. (Les deux moitiés, d'abord prévues en deux
plans, partagent les mêmes fichiers : un seul plan évite de les rebaser l'une sur l'autre.)

## 8. Hors périmètre

Porter la robe sur son avatar, défilés et votes entre joueurs (sous-projet 4) ; musique propre à chaque
événement ; cinématiques ; traduction.
