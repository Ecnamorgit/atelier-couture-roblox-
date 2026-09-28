# Spike — rendu EditableImage / EditableMesh (sous-projet 1, étape 1)

- Date : 2026-09-28
- Lieu : `spike/Spike.rbxl` (code jetable, `spike/Spike.client.luau`), Roblox Studio sur PC Windows, en mode Play
- Trois exécutions. La première a révélé la limite des maillages. Les deuxième et troisième ont mesuré le budget
  et la conversion en contenu statique.

## Mesures

| Mesure | PC (Studio) | Téléphone |
|---|---|---|
| motif256Ms (dessin d'un motif 256 × 256 en Luau) | 6 ms | non mesuré |
| decoupe192Ms (image d'une pièce 192 × 192 découpée à 45°) | 3 ms | non mesuré |
| CreateEditableImage + WritePixelsBuffer | OK | non mesuré |
| CreateEditableMesh (devant, dos) | OK | non mesuré |
| CreateMeshPartAsync (devant, dos) | OK, taille 1,88 × 1,80 × 0,74 studs | non mesuré |
| MeshPart.TextureContent = Content.fromObject(image) | OK | non mesuré |
| SurfaceAppearance.ColorMapContent | **ÉCHEC** : « cannot write 'ColorMapContent' (lacking capability Plugin) » | — |
| jupe2PiecesMs (2 pièces, première génération) | 996 ms | non mesuré |
| robe6PiecesConverties (6 pièces : image, maillage, conversion, destruction) | 532 ms (≈ 90 ms par pièce) | non mesuré |
| Budget EditableMesh sans taille fixe | **7 à la fois** (5 de plus quand 2 sont vivants) | non mesuré |
| CreateDataModelContentAsync(maillage) / (image) | `Enum.CreateContentResult.Success` pour les deux | non mesuré |
| CreateMeshPartAsync(contenu statique) | OK | non mesuré |
| Budget après conversion puis destruction de l'EditableMesh | revenu à 5 (la destruction libère le budget) | non mesuré |
| budgetImages256 | 239 images (≈ 60 Mo) ; 158 au 1er passage, avec plus d'objets vivants | non mesuré |
| memoireTotaleAvantMo / ApresMo | 2005 / 2531 Mo (Studio entier) | non mesuré |

## Observations visuelles

- Les moitiés devant et dos se rejoignent sur les côtés : **oui**. `CreateMeshPartAsync` recentre le maillage sur sa
  boîte, et placer la pièce au centre moyen des sommets suffit.
- Imprimé visible à l'extérieur : oui. La doublure (faces inversées) rend l'intérieur visible.
- Bandes du motif inclinées à 45° sur la jupe : **oui**. La découpe tournée se voit bien sur la robe.
- **Détruire l'EditableMesh sans conversion fait disparaître la pièce** : le MeshPart garde sa taille,
  mais sa géométrie n'est plus rendue.
- Une pièce créée depuis le contenu statique, avec une image statique en `TextureContent`, s'affiche normalement
  après la destruction des objets Editable.

## Surprises d'API (à reporter dans le plan 2)

- `AssetService:CreateDataModelContentAsync(content)` renvoie **deux valeurs** : `Enum.CreateContentResult`, puis le `Content`.
- `AssetService:CreateEditableMesh()` renvoie **nil**, sans erreur, quand le budget est atteint. Le moteur écrit
  alors l'avertissement « Failed to create empty EditableMesh … memory budget limits ». Même comportement pour
  `CreateEditableImage`.
- Studio met le débogueur en pause sur les erreurs rattrapées par `pcall`. Le lieu doit utiliser TextChatService
  (sinon l'ancien chat lève une erreur au démarrage), et les tests d'API qui échouent demandent de cliquer sur « Reprendre ».

## Mesures complémentaires

- Module `Pixels` dans Studio (mode Edit, trapèze 6 × 6 dm à 45°, image 192 × 192) :
  - dessin du motif (une fois par tissu, mis en cache) : 4,5 ms (uni) à 15,2 ms (vichy) ;
  - découpe de la pièce : **41,7 à 45,9 ms** dans la version du plan, puis **3,9 à 5,1 ms** après avoir sorti de la boucle
    le calcul de la boîte, du cosinus et du sinus (tâche 10). Les tests d'exactitude au pixel restent verts.

## Décisions (règles fixées avant la mesure)

| Si… | Alors… | Décision retenue |
|---|---|---|
| `CreateEditableImage` ou `CreateEditableMesh` échoue dans Studio | Arrêter (repli : approche C) | Sans objet : les deux fonctionnent. **On garde l'approche A.** |
| `SurfaceAppearance.ColorMapContent` échoue ou rend mal | `MeshPart.TextureContent` et une `Material` proche | **Appliqué** : SurfaceAppearance est impossible en jeu. Le rendu satiné passera par `Material` et `Reflectance`. |
| Budget téléphone < 32 Mo | Plafonds 192 px (pièces) et 64 px (vitrines) | Téléphone non mesuré. La règle est **rendue sans objet** par la conversion immédiate : chaque image Editable ne vit que le temps de sa conversion. On garde 256 / 128 px, à revoir si le test sur téléphone montre un problème. |
| `decoupe192Ms` téléphone > 30 ms | 24 px/dm et découpe étalée | Estimation téléphone : 3 × 3 ≈ 9 ms, donc on garde 32 px/dm. |
| `robe6PiecesMs` téléphone > 600 ms | Une pièce par image et une animation pendant la génération | Estimation téléphone : 532 × 3 ≈ 1,6 s. **Appliqué** : génération d'une pièce par image, avec une animation. |
| `CreateDataModelContentAsync` fonctionne | L'utiliser pour les robes finies | **Étendu à toutes les pièces** : le budget de 7 EditableMesh l'impose. Chaque pièce est construite, convertie en contenu statique, puis ses objets Editable sont détruits aussitôt. |
| `CreateDataModelContentAsync` échoue | Régénération par chaque client | Sans objet. Le contenu statique créé par un client est supposé local à ce client (non vérifié : aucun test à plusieurs joueurs dans ce spike), donc chaque client régénère quand même les vitrines à partir des recettes (spec §5), en convertissant chaque pièce. |
| Les moitiés ne se rejoignent pas | Compenser au plan 2 | Sans objet : placer au centre des sommets suffit. |

## Conséquences pour le plan 2

1. **Chaîne par pièce** : `EditableImage` (découpe) et `EditableMesh` (enroulement), puis `CreateDataModelContentAsync`
   sur les deux, puis `CreateMeshPartAsync(contenuMaillage)`, puis `TextureContent = contenuImage`, puis `Destroy()` des deux
   objets Editable. Au plus 1 maillage et 1 image Editable vivants à la fois.
2. Génération étalée : une pièce par image (`task.wait()`), avec une animation de couture pendant la génération.
3. Matières : `Material` et `Reflectance` selon `Catalogue.MATIERES`, pas de `SurfaceAppearance`.
4. Tester `nil` après chaque `CreateEditable…`, et afficher la pièce en couleur unie si la création échoue (spec §5, Pannes).
5. **Mesure sur téléphone à faire par le commanditaire** avant la fin du plan 2 : publier `spike/Spike.rbxl` en privé
   et envoyer la capture du rapport.
