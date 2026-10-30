# Documentation de Fenestra

Site de documentation (anglais et français) construit avec [Astro Starlight](https://starlight.astro.build).

## Commandes

À lancer dans `docs/` (pnpm, Node 22+) :

| Commande | Action |
|---|---|
| `pnpm install` | Installe les dépendances |
| `pnpm dev` | Serveur de développement sur http://localhost:4321 |
| `pnpm build` | Génère le site statique dans `dist/` |
| `pnpm preview` | Prévisualise le build |

Les pages anglaises (langue par défaut, servies à la racine) sont dans `src/content/docs/`, les pages françaises dans `src/content/docs/fr/`, avec la même arborescence : `guide/` pour les utilisateurs, `dev/` pour les développeurs.
Une traduction est reliée à l'original par son chemin : `guide/mouse.md` et `fr/guide/mouse.md` sont la même page. Les slugs sont en anglais dans les deux langues. Une page sans traduction s'affiche en anglais avec un bandeau.

Les liens internes incluent le préfixe `/fenestra` (`base` du site), et `/fenestra/fr` pour les pages françaises.
La barre latérale est déclarée dans `astro.config.mjs` ; ses libellés reprennent le titre de chaque page dans la langue courante.
