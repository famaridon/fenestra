# Documentation de Fenestra

Site de documentation (français) construit avec [Astro Starlight](https://starlight.astro.build).

## Commandes

À lancer dans `docs/` (pnpm, Node 22+) :

| Commande | Action |
|---|---|
| `pnpm install` | Installe les dépendances |
| `pnpm dev` | Serveur de développement sur http://localhost:4321 |
| `pnpm build` | Génère le site statique dans `dist/` |
| `pnpm preview` | Prévisualise le build |

Les pages sont dans `src/content/docs/` (`guide/` pour les utilisateurs, `dev/` pour les développeurs).
La barre latérale est déclarée dans `astro.config.mjs`.
