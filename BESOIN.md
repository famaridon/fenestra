# Fenestra — Expression de besoin

> Gestionnaire de fenêtres macOS qui reproduit l'expérience de « snap » de Windows et d'Ubuntu.

| | |
|---|---|
| **Statut** | Brouillon v0.1 |
| **Date** | 2026-10-29 |
| **Auteur** | Florent Amaridon |
| **Plateforme** | macOS 26+ · Apple silicon |

---

## 1. Contexte

Sous Windows et Ubuntu, organiser ses fenêtres est immédiat. On glisse une fenêtre vers un bord et elle prend la moitié de l'écran. On redimensionne deux fenêtres collées en tirant la bordure qui les sépare. Un écran vertical se découpe naturellement en haut et bas.

Sur macOS, aucune solution existante ne couvre l'ensemble :

| Solution | Ce qui manque |
|---|---|
| **Collage natif macOS 26** | Délai au glisser sans ⌥. Pas de bordure partagée. Sur un écran vertical, glisser en haut maximise au lieu de donner la moitié haute. Raccourcis peu pratiques (`Fn+Ctrl+flèches`). |
| **Rectangle** | Pas de bordure partagée. Les fenêtres collées restent indépendantes. |
| **Tiling automatique** (KiwiDesk, AeroSpace, yabai…) | Range *toutes* les fenêtres en permanence. Ce n'est pas l'expérience Windows, où l'on choisit ce qu'on colle. Outils jeunes ou configurés par fichier. |

**Fenestra** comble ce manque : un *snap* manuel comme sous Windows, avec les fenêtres collées qui restent **liées** entre elles.

## 2. Objectif

Retrouver sur macOS l'expérience de gestion des fenêtres de Windows 11 et Ubuntu (GNOME). Elle doit être instantanée, à la souris comme au clavier, et adaptée aux configurations multi-écrans avec un écran vertical.

## 3. Utilisateur cible

Un développeur qui passe d'un environnement à l'autre (Windows, Ubuntu, macOS). Il travaille avec plusieurs écrans, dont un écran **en orientation verticale**, et veut des automatismes identiques partout.

## 4. Besoins fonctionnels

Priorités : **P0** = indispensable au MVP · **P1** = attendu en v1 · **P2** = plus tard.

### F1 — Snap par glisser-déposer · P0
- Glisser une fenêtre (par sa barre de titre) jusqu'à ce que **le pointeur touche un bord** déclenche la zone correspondante :
  - bord **gauche / droit** → moitié gauche / droite ;
  - **coins** → quart d'écran ;
  - bord **haut** → plein écran (écran paysage) ou moitié haute (écran vertical, voir F6).
- Un **aperçu translucide** de la zone cible s'affiche **immédiatement**, sans délai ni touche modificatrice.
- Relâcher applique la zone. Ramener le pointeur loin du bord annule l'aperçu.

### F2 — Restauration de la taille d'origine · P0
- « Décoller » une fenêtre collée (en la glissant hors de sa zone) lui rend sa taille d'avant le snap, comme sous Windows.

### F3 — Raccourcis clavier façon `Win + flèches` · P0
- Raccourcis par défaut : `⌃⌥ + ←/→/↑/↓`. Ils sont configurables.
- `←` / `→` : moitié gauche / droite. Appuyer de nouveau du même côté **passe à l'écran voisin**, comme sous Windows.
- `↑` : plein écran (paysage) ou moitié haute (vertical). `↓` : restaure la taille, ou moitié basse sur un écran vertical.
- Raccourcis dédiés pour les quarts et pour envoyer la fenêtre vers l'écran suivant ou précédent.

### F4 — Dispositions composées · P0
- Pouvoir combiner zones et fenêtres, par exemple **deux fenêtres empilées à gauche (quarts haut et bas) et une à droite (moitié)**.
- Ces combinaisons doivent fonctionner aussi bien à la souris (F1) qu'au clavier (F3).

### F5 — Bordure partagée entre fenêtres collées · P1
- Quand deux fenêtres (ou plus) sont collées côte à côte, **tirer la bordure commune redimensionne toutes les fenêtres qui la touchent**. Si l'une s'agrandit, sa voisine rétrécit d'autant, comme les *snap groups* de Windows 11.
- Fonctionne sur les bordures verticales (gauche/droite) **et** horizontales (haut/bas, par exemple entre deux quarts).
- Les **tailles minimales** des applications sont respectées : la bordure s'arrête si une fenêtre ne peut pas rétrécir davantage.
- Le lien entre les fenêtres se rompt dès que l'une d'elles est décollée (F2), déplacée ou fermée.

### F6 — Prise en compte de l'écran vertical · P0
- L'orientation de chaque écran est détectée (hauteur > largeur → vertical).
- Sur un écran vertical, le découpage principal est **haut / bas** au lieu de gauche / droite :
  - glisser vers le bord **haut / bas** → moitié haute / basse ;
  - les bords gauche et droit restent disponibles pour les moitiés gauche/droite (configurable).
- Les raccourcis F3 s'adaptent selon l'orientation.

### F7 — Multi-écrans · P0
- Toutes les fonctions marchent sur chaque écran indépendamment.
- Brancher ou débrancher un écran, ou changer sa résolution, ne doit pas laisser de fenêtre hors de l'écran.

### F8 — Snap Assist · P2
- Après avoir collé une fenêtre sur une moitié, à la souris ou au clavier, proposer les autres fenêtres ouvertes pour remplir l'espace restant, comme sous Windows.
- En option, afficher une miniature de chaque fenêtre. Elle demande l'autorisation d'enregistrement de l'écran ; sans elle, on affiche les icônes des applications.

### F9 — Application et réglages · P0
- App **dans la barre des menus** uniquement, sans icône dans le Dock.
- Au premier lancement, un **accueil** guide l'utilisateur pour accorder l'autorisation d'**Accessibilité** et indique son état en temps réel.
- Réglages : raccourcis, activer ou désactiver chaque zone, marges entre fenêtres (0 par défaut), comportement sur les écrans verticaux.
- Option « Lancer à l'ouverture de session ».
- Liste d'**applications exclues** (aucun snap pour elles).

## 5. Besoins non fonctionnels

| # | Exigence |
|---|---|
| NF1 | **Réactivité** : l'aperçu s'affiche en moins de 50 ms après que le pointeur touche le bord. Pendant le glisser de la bordure (F5), les fenêtres liées suivent sans saccade perceptible. |
| NF2 | **Sobriété** : CPU ≈ 0 % au repos, empreinte mémoire < 50 Mo. |
| NF3 | **Robustesse** : une application qui ne répond pas ou refuse la taille demandée ne doit ni bloquer ni faire planter Fenestra. La taille réelle est toujours relue après chaque redimensionnement. |
| NF4 | **API publiques uniquement** (Accessibilité, AppKit). Pas d'API privées, pas de SIP à désactiver. |
| NF5 | **Coexistence** : Fenestra cohabite avec le collage natif de macOS. Il recommande de désactiver le glisser natif pour éviter un double snap. |
| NF6 | **Confidentialité** : aucune donnée collectée, aucun accès réseau. Les miniatures de Snap Assist restent en mémoire et ne sont jamais enregistrées. |

## 6. Hors périmètre

- **Tiling automatique** de toutes les fenêtres : on garde un snap manuel, comme sous Windows.
- **Gestion des bureaux macOS (Spaces)** : pas d'API publique.
- **Alt+Tab fenêtre par fenêtre** : déjà couvert par [AltTab](https://alt-tab-macos.netlify.app/).
- Distribution sur l'App Store : impossible, car l'app ne peut pas être sandboxée avec l'Accessibilité.

## 7. Contraintes techniques

- **Langage** : Swift 6, SwiftUI pour l'interface et AppKit si besoin.
- **Cible** : macOS 26.0 minimum, Apple silicon.
- **Pilotage des fenêtres** : API d'Accessibilité (`AXUIElement`, `AXObserver`).
- **Événements souris** : `NSEvent.addGlobalMonitorForEvents`, ou `CGEventTap` si l'interception est nécessaire.
- **Repères de coordonnées** : l'Accessibilité utilise une origine en haut à gauche, `NSScreen` une origine en bas à gauche. Une seule couche de conversion, couverte par des tests unitaires.
- **Signature** : certificat *Apple Development*, pour que macOS conserve l'autorisation d'Accessibilité entre deux compilations.
- **Projet** : généré par XcodeGen (`project.yml`). Le `.xcodeproj` n'est pas versionné.
- **Référence** : [Rectangle](https://github.com/rxhanson/Rectangle) (licence MIT) pour la couche Accessibilité.

## 8. Critères d'acceptation du MVP

- [ ] Glisser une fenêtre du Finder, de Safari, de Xcode ou de VS Code contre le bord gauche affiche l'aperçu instantanément. Au relâchement, la fenêtre occupe exactement la moitié gauche.
- [ ] Composer « deux fenêtres à gauche, une à droite » à la souris et au clavier.
- [ ] Sur l'écran vertical, `⌃⌥↑` place la fenêtre sur la moitié haute et `⌃⌥↓` sur la moitié basse.
- [ ] `⌃⌥→` deux fois de suite fait passer la fenêtre sur l'écran de droite.
- [ ] Décoller une fenêtre lui rend sa taille d'origine.
- [ ] Après une recompilation, l'autorisation d'Accessibilité est toujours accordée.

**Critère v1 (F5)** : avec deux fenêtres collées gauche/droite, élargir celle de gauche en tirant son bord droit rétrécit celle de droite d'autant. Les deux fenêtres restent jointives au relâchement.

## 9. Jalons

| Jalon | Contenu |
|---|---|
| **M0** | Squelette : app de la barre des menus, autorisation d'Accessibilité, déplacement d'une fenêtre par code. ✅ *(squelette créé)* |
| **M1** | Moteur de zones (moitiés, quarts, orientation) + raccourcis clavier (F3, F4, F6, F7). |
| **M2** | Snap par glisser avec aperçu (F1) + restauration (F2). |
| **M3** | Bordure partagée (F5). |
| **M4** | Réglages, exclusions, lancement à la connexion (F9). |
| **M5** | Snap Assist (F8). |

## 10. Questions ouvertes

1. Sur un écran vertical, le bord haut doit-il donner la **moitié haute** ou le **plein écran** (comme sous Windows) ? Hypothèse retenue : moitié haute.
2. Faut-il des **tiers d'écran** (⅓ / ⅔), utiles sur un écran ultra-large ?
3. La bordure partagée (F5) doit-elle aussi lier des fenêtres **placées à la main** côte à côte, ou seulement celles collées par Fenestra ?
4. Faut-il des **marges** entre fenêtres par défaut (comme macOS) ou aucune (comme Windows) ?
