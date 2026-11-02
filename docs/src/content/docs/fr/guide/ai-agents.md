---
title: Agents IA et scripts
description: Laissez Claude et d'autres agents IA disposer vos fenêtres par MCP, ou scriptez des dispositions complètes depuis le terminal.
---

Fenestra est livré avec un petit outil en ligne de commande, `fenestra`, qui dialogue avec l'app en cours d'exécution. Les agents IA l'utilisent par le **Model Context Protocol (MCP)**, et vous pouvez l'appeler depuis vos scripts. Dans les deux cas, une **disposition** complète — plusieurs fenêtres, sur plusieurs écrans — s'applique **en une seule fois**.

Demandez à Claude par exemple *« prépare-moi pour coder : Xcode sur les deux tiers gauche, Safari à droite, Slack en plein écran sur l'écran du haut »*, et les fenêtres se placent.

Tout reste sur votre Mac : l'outil passe par un socket local que seul votre compte utilisateur peut ouvrir.

## Connecter un agent IA

Ouvrez l'onglet **Agents** des [réglages](/fenestra/fr/guide/settings/). Il affiche la configuration de cet exemplaire de Fenestra, avec un bouton **Copier** :

- **Claude Code** : copiez la commande et lancez-la dans un terminal. Elle ressemble à :

  ```sh
  claude mcp add fenestra -- /Applications/Fenestra.app/Contents/Helpers/fenestra mcp
  ```

- **Claude Desktop, Cursor et autres apps MCP** : copiez le bloc JSON dans le fichier de configuration MCP de l'app (pour Claude Desktop : *Réglages › Développeur › Modifier la config*) :

  ```json
  {
    "mcpServers": {
      "fenestra": {
        "args": ["mcp"],
        "command": "/Applications/Fenestra.app/Contents/Helpers/fenestra"
      }
    }
  }
  ```

Le chemin désigne l'emplacement de Fenestra : copiez de nouveau la configuration si vous déplacez l'app. Si Fenestra n'est pas lancé, l'outil le démarre en arrière-plan.

## Ce qu'un agent peut faire

| Outil | Effet |
|---|---|
| `list_displays` | Les écrans dans l'ordre de lecture (de gauche à droite, puis de haut en bas), avec leur numéro, leur taille et leur orientation. |
| `list_windows` | Les fenêtres que Fenestra peut déplacer, avec leur app, leur titre, leur écran et leur zone. |
| `apply_layout` | Place plusieurs fenêtres d'un coup, voir ci-dessous. |

Les agents suivent les mêmes règles que vous : les fenêtres réduites, en plein écran macOS ou [exclues](/fenestra/fr/guide/settings/#exclusions) ne bougent pas, et rien ne se passe tant que Fenestra est désactivé dans la barre des menus.

## Décrire une disposition

Une disposition est une liste de **placements**. Chacun choisit une fenêtre et indique où la mettre :

| Champ | Signification |
|---|---|
| `app` | Nom de l'app (`Safari`) ou identifiant de bundle (`com.apple.Safari`), sans tenir compte de la casse. Obligatoire. |
| `title` | Une partie du titre de la fenêtre, pour choisir parmi plusieurs fenêtres d'une même app. |
| `display` | `primary` (par défaut, l'écran de la barre des menus), un numéro (`1`, `2`…), ou `left`, `right`, `top`, `bottom`. |
| `zone` | Une zone nommée : `leftHalf`, `rightHalf`, `topHalf`, `bottomHalf`, `topLeft`, `topRight`, `bottomLeft`, `bottomRight`, `maximize`, `leftThird`, `centerThird`, `rightThird`, `leftTwoThirds`, `rightTwoThirds`. |
| `rect` | Ou une zone libre, en fractions de l'écran : `{"x": 0, "y": 0, "width": 0.6, "height": 1}` correspond aux 60 % de gauche. |

Donnez une `zone` ou un `rect`, pas les deux. Avec `launch_apps` à `true`, Fenestra ouvre les apps qui n'ont pas encore de fenêtre et attend leurs fenêtres jusqu'à 10 secondes.

```json
{
  "placements": [
    { "app": "Xcode", "zone": "leftTwoThirds" },
    { "app": "Safari", "title": "GitHub", "zone": "rightThird" },
    { "app": "Terminal", "display": "2", "rect": { "x": 0, "y": 0.5, "width": 1, "height": 0.5 } },
    { "app": "Slack", "display": "top", "zone": "maximize" }
  ],
  "launch_apps": true
}
```

- Chaque fenêtre ne sert **qu'une fois** : indiquez une app deux fois pour placer deux de ses fenêtres (la plus en avant d'abord), ou distinguez-les avec `title`.
- Les fenêtres absentes de la liste **restent où elles sont**.
- Le **premier** placement passe au premier plan.
- Les zones respectent l'**espace entre les fenêtres** des réglages et se [restaurent](/fenestra/fr/guide/keyboard/) comme tout autre snap. Une fenêtre placée avec `rect` n'est pas considérée comme collée.
- La réponse liste les fenêtres placées et, pour chaque placement en échec, la raison (aucune fenêtre correspondante, écran inconnu…).

## Depuis le terminal

Le même outil fonctionne dans les scripts et les raccourcis :

```sh
FENESTRA=/Applications/Fenestra.app/Contents/Helpers/fenestra
$FENESTRA displays
$FENESTRA windows
$FENESTRA layout '{"placements": [{"app": "Xcode", "zone": "leftHalf"}, {"app": "Safari", "zone": "rightHalf"}]}'
$FENESTRA layout - < coder.json
```

Chaque commande affiche son résultat en JSON et se termine avec un code non nul en cas d'erreur.

## Désactiver

Décochez **Autoriser les agents IA et les scripts à disposer les fenêtres** dans l'onglet **Agents** des [réglages](/fenestra/fr/guide/settings/) : Fenestra ferme son socket et l'outil ne peut plus le joindre.
