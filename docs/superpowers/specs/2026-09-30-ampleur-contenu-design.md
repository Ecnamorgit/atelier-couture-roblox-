# Aiguille & Dentelle — Sous-projet 4 : l'ampleur du catalogue et du quartier

- Date : 30 septembre 2026
- Statut : écrite, relue et validée par l'agent, en autonomie (règles du commanditaire du 29 septembre 2026 : « ressembler le plus possible au jeu existant sur Steam », specs validées seul)
- Suit : `docs/superpowers/specs/2026-09-30-histoire-evenements-design.md` (sous-projet 3)

## 1. Contexte et objectif

Les sous-projets 1 à 3 ont reproduit les mécaniques de *Dressmaker* : la fabrication d'une robe, les clientes, la
progression, les robes libres, le courrier et l'histoire. Il manque l'**ampleur** : *Dressmaker* propose plus de
150 pièces de patron, 450 tissus, 350 accessoires, dix clientes récurrentes et une quinzaine d'événements. Le
nôtre en a 17 pièces (13 variantes), 25 tissus, 23 accessoires, six clientes et huit événements, et les niveaux
de prestige 6 à 8 n'ouvrent plus rien. Ce sous-projet agrandit le catalogue et le quartier, sans changer les
règles, avec un contenu original.

### Ce qui est repris, ce qui ne l'est pas

- **Repris** : l'idée d'un grand catalogue qui s'ouvre tout au long de la partie, de nouvelles clientes qui
  arrivent tard, et de nouveaux événements pour elles.
- **Jamais copié** : noms, motifs, personnages et textes de *Dressmaker*.
- **Hors de portée** : les chiffres de *Dressmaker* (des centaines d'éléments modélisés). On vise une partie qui
  garde de la nouveauté jusqu'au prestige 8 et jusqu'à la dixième cliente.

### Critères de réussite

1. Chaque niveau de prestige de 2 à 8 ouvre quelque chose (tissus ou décorations).
2. 41 tissus (16 de plus, en quatre matières nouvelles), 39 accessoires (12 de plus, et les 4 souvenirs des nouveaux événements), 19 variantes (6 de plus).
3. Dix clientes (quatre de plus, arrivant aux prestiges 5 à 8), chacune avec ses goûts, ses mesures, sa tenue, ses
   répliques et deux déblocages d'amitié.
4. Douze événements (quatre de plus, autour des nouvelles clientes), avec leurs souvenirs.
5. Les commandes restent rapides à tirer malgré un catalogue plus grand ; l'équilibrage est revérifié par la
   simulation.

## 2. Tissus

Quatre matières nouvelles, quatre tissus chacune (motifs des types existants : uni, pois, carreaux, rayures,
fleurs, dégradé ; teintes existantes) :

| Matière | Prestige | Styles dominants | Prix (po/m) | Rendu |
|---|---|---|---|---|
| crêpe | 6 | élégant, chic | 18 à 20 | mat, souple |
| organza | 6 | romantique, mignon | 18 à 22 | brillant léger |
| brocart | 7 | élégant, gothique | 22 à 26 | brillant |
| tulle | 8 | romantique, élégant | 20 à 24 | léger (opaque : une robe transparente laisserait voir le mannequin) |

## 3. Accessoires

Douze de plus : huit objets et quatre garnitures, dans les formes existantes (boule, bloc, cylindre, nœud, fleur,
croix) ; huit ouverts par le prestige (deux par niveau, de 5 à 8), quatre par l'amitié des nouvelles clientes.

## 4. Variantes

Six de plus, dans les enroulements existants (corsage, manche, col, jupe) :

| Famille | Variante | Pièces | Ouverte par |
|---|---|---|---|
| corsage | cache-cœur | devant croisé, dos droit | amitié de la 7e cliente, niveau 2 |
| corsage | bustier | devant et dos sans épaule | amitié de la 9e cliente, niveau 2 |
| manches | courtes | une manche courte pliée | prestige 6 |
| manches | trois-quarts | une manche mi-longue pliée | amitié de la 8e cliente, niveau 2 |
| col | marin | un col large plié | amitié de la 10e cliente, niveau 2 |
| jupe | crayon | devant et dos ajustés | prestige 7 |

Les quatre variantes promises à l'amitié des nouvelles clientes s'ouvrent au prestige 8 tant que ces clientes
n'existent pas (plan 8b) ; le plan 8c les rend à leur amitié. Avec le bustier, manches et col se portent
détachés, épaules nues : c'est voulu (relecture du plan 8b, vu dans Studio).

## 5. Les nouvelles clientes et leurs événements

Quatre clientes originales (noms, tenues, répliques écrits au plan), arrivant aux prestiges 5, 6, 7 et 8, avec des
goûts qui croisent les styles déjà présents ; leurs déblocages d'amitié (niveaux 2 et 4) ouvrent les variantes du
§4 et quatre accessoires du §3. Quatre événements (9 à 12), aux prestiges 6 à 8, font jouer ces clientes et
d'anciennes, avec leurs souvenirs (quatre objets de plus, en dehors des douze du §3).

## 6. Rapidité

Le catalogue plus grand multiplie les croquis possibles (5 × 5 × 4 × 5 = 500 au lieu de 108) et les tissus (41 au lieu de 25). Le
tirage d'une commande (`Commandes.realisable`) ne recalcule plus les styles pièce par pièce : il précalcule les
points de chaque croquis et de chaque tissu (les styles s'additionnent), et vérifie d'abord les exigences les
plus fermées. Cible : aucun calcul complet des styles robe par robe au tirage (vérifié en comptant les
appels : la simulation ne mesure pas le temps réel), la suite de tests sous une minute.

## 7. Équilibrage

La simulation (vingt parties) est reprise avec le nouveau catalogue et les nouvelles clientes : prestige 2 en
3 robes au plus, 5 vers la 19e robe, 8 atteint, et « tout ouvert » mesuré puis fixé en médiane ; les bornes sont
revues au plan si le nouveau contenu les déplace, en disant pourquoi. Mesuré au plan 8c : prestige 8 vers la 57e
robe, « tout ouvert » vers la 123e (médianes, parties simulées de 160 robes) : l'amitié des quatre dernières
clientes ouvre les dernières variantes ; bornes 100 à 150.

## 8. Tests

- Catalogue : nombres d'éléments, conditions (une seule par élément, prestiges 2 à 8 tous utilisés), tissus et
  accessoires dessinables, variantes coupables (pièces dans le rouleau, coutures), commandes réalisables au
  prestige de chaque cliente.
- Rapidité : tirage de commandes sans calcul complet des styles, mêmes réponses que le calcul complet.
- Clientes et événements : comme aux sous-projets 2 et 3 (données, tenues réalisables, répliques, vouvoiement).
- Scénario : un élément ouvert au prestige 6, une robe avec une variante nouvelle jusqu'à la photo.

## 9. Découpage en plans

1. **8a — Tissus, décorations et rapidité** : quatre matières, les huit accessoires du prestige (les quatre de l'amitié
   viennent avec leurs clientes, plan 8c), conditions de prestige 5 à 8,
   `realisable` rapide ; équilibrage revu.
2. **8b — Six variantes** : pièces de patron, découpe, couture, rendu 3D, styles.
3. **8c — Quatre clientes et quatre événements** : données, répliques, souvenirs, amitiés ; équilibrage revu.

## 10. Hors périmètre

Porter sa robe sur son avatar, défilés et votes entre joueurs (un sous-projet 5 possible, propre à Roblox, à
décider avec le commanditaire) ; nouveaux types de motifs ; traduction.
