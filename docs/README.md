# J0 — la journée en un coup d'œil

Aujourd'hui, pas de framework d'API : vous écrivez vous-même une API REST avec Symfony, pour comprendre ce qui se passe
entre une requête HTTP et une ligne en base de données. Tout ce que vous ferez à la main aujourd'hui, vous le verrez
automatisé demain. C'est le but : savoir ce qu'on délègue.

## Les paliers

Les étapes du TP sont marquées 🟢, 🔵 ou 🔴. Avancez à votre rythme : l'objectif est de comprendre, pas de tout finir.

- 🟢 indispensable, très guidé, presque à recopier ;
- 🔵 attendu, avec des indices ;
- 🔴 pour aller plus loin, en autonomie.

## Les tests sont la spécification

Vous n'écrivez pas de tests aujourd'hui : ils sont fournis dans [`tests/`](../tests), et `make test` les exécute sur une
base de test séparée, vide à chaque lancement. Chaque fichier décrit précisément ce que l'API doit faire : les URL,
les codes de statut, la forme du JSON, les en-têtes. Avant chaque étape, ouvrez le fichier correspondant et lisez-le
comme un cahier des charges. En cas de doute sur un comportement attendu, c'est là qu'est la réponse.

| Fichier | Ce qu'il vérifie | Étape |
|---|---|---|
| `00-games.hurl` | l'exemple fourni ; il est vert dès le début | TD, étape 0 |
| `01-ping.hurl` | votre premier contrôleur | TD, étape 1 |
| `02-teams.hurl` | l'entité `Team` et son contrôleur | TP, étapes 1 et 2 |
| `03-players.hurl` | `Player`, sa relation avec `Team`, le DTO, `PUT` | TP, étape 3 |
| `04-pagination.hurl` | la pagination de `/api/players` | TP, étape 4 |
| `05-top-players.hurl` | une requête écrite avec le QueryBuilder | TP, étape 6 |
| `06-versus.hurl` | un service injecté : le simulateur de match | TP, étape 7 |

`make test f=03` ne lance qu'un fichier ; `make test ERRORS=long` affiche les réponses complètes des requêtes en échec.

## Antisèches

- [Symfony : les bases](cheatsheets/symfony-bases.md) : commandes, routage, contrôleur, injection, Doctrine, Validator, Serializer.
- [HTTP et REST](cheatsheets/http-rest.md) : méthodes, codes, en-têtes, curl, lire un test Hurl.

## Et demain ?

Le projet que vous aurez en fin de journée est **votre point de départ de demain**. Les entités `Team` et `Player`,
leurs contraintes et leurs groupes de sérialisation serviront tels quels. Soignez-les.
