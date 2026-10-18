# GG League · J0 — une API REST faite main avec Symfony

Bienvenue dans la première journée du cours sur les API. Pendant quatre jours, vous allez construire les API d'une
ligue e-sport fictive, la **GG League** : ses jeux, ses équipes, ses joueurs. Aujourd'hui, vous écrivez tout vous-même
avec Symfony : les routes, les contrôleurs, les entités Doctrine, la validation. C'est volontairement artisanal.
Demain, un framework fera une bonne partie de ce travail à votre place, et vous saurez exactement ce qu'il fait.

Ce dépôt contient tout ce qu'il faut pour la journée : l'environnement Docker, un projet Symfony presque vide, un
contrôleur d'exemple, et les tests qui vous guideront.

```
  navigateur (Swagger UI) ──▶ ┌──────────────────────────────┐
  curl, Postman            ──▶ │  api · Symfony 7.4           │ ──▶ PostgreSQL 17
  make test (Hurl)         ──▶ │  http://localhost:8000/api   │
                               └──────────────────────────────┘
```

Les supports de la journée sont dans [`docs/`](docs/README.md) : le TD du matin, le TP de l'après-midi, deux antisèches.

## Installation (à faire avant le cours si possible)

### Prérequis

| | Linux | macOS | Windows |
|---|---|---|---|
| Docker | Docker Engine + plugin Compose v2 | Docker Desktop | Docker Desktop **avec WSL 2** |
| Git, make | paquets `git`, `make` | `xcode-select --install` | dans WSL : `sudo apt install git make` |

Sous Windows, travaillez **dans WSL** (terminal Ubuntu) et clonez le dépôt dans le système de fichiers Linux
(`~/…`, pas `/mnt/c/…`) : c'est dix fois plus rapide. Avant de cloner : `git config --global core.autocrlf input`.

Prévoyez 4 Go de mémoire pour Docker et 3 Go d'espace disque.

### Récupérer le projet

1. Sur GitHub, faites un **fork privé** de ce dépôt et donnez-y accès à l'enseignant.
2. Clonez **votre fork**, puis déclarez le dépôt de l'enseignant comme `upstream` (il servira si un énoncé ou un test
   doit être corrigé en cours de journée) :

```bash
git clone <url de VOTRE fork> j0-symfony
cd j0-symfony
git remote add upstream <url du dépôt de l'enseignant>
```

### Vérifier et installer

```bash
make doctor     # vérifie Docker, les ports, git, les fins de ligne
make install    # construit l'image (2 à 5 min la première fois) et démarre tout
```

Quand c'est terminé :

| | |
|---|---|
| Votre API, avec sa documentation interactive (Swagger UI) | http://localhost:8000/api |
| Le profiler Symfony (ce qui s'est passé pour chaque requête) | http://localhost:8000/_profiler |
| PostgreSQL (DBeaver, DataGrip…) | `localhost:5433`, base `app`, utilisateur `app`, mot de passe `app` |

```bash
make test       # le fichier 00-games doit être VERT ; les autres sont le programme de la journée
```

## Au quotidien

```bash
make help                  # toutes les commandes
make up / make down        # démarrer / arrêter (les données sont conservées)
make sf c="debug:router"   # une commande de la console Symfony, exécutée dans le conteneur
make db-update             # mettre à jour les tables après avoir modifié une entité
make db-reset              # repartir d'une base vide (et recharger les données de démo si vous les avez)
make test                  # tous les tests ; make test f=02 pour un seul fichier
make test ERRORS=long      # le détail complet (en-têtes, corps) des réponses en échec
make logs s=api            # les journaux de l'API
```

## Rendre son travail

Il n'y a pas de rendu formel. Commitez à chaque étape et poussez sur votre fork, au minimum en fin de matinée et en
fin de journée. L'enseignant suit votre progression sur votre dépôt et avec `make test`.

```bash
git add -A && git commit -m "J0 : TeamController" && git push
```

Le projet que vous aurez à 17h30 est le point de départ de demain : gardez-le propre et fonctionnel.

## Problèmes fréquents

| Symptôme | Solution |
|---|---|
| `make doctor` : port 8000 ou 5433 déjà utilisé | Créez un fichier `.env` à la racine avec par exemple `API_PORT=8080` et/ou `DB_PORT=5434`. Si vous avez un autre projet Compose du même nom, ajoutez aussi `COMPOSE_PROJECT_NAME=j0-<votre-nom>`. |
| `/bin/sh^M: bad interpreter` | Fins de ligne Windows : `git config --global core.autocrlf input`, puis reclonez. |
| Linux : des fichiers créés par Docker ne sont pas modifiables | `sudo chown -R $USER: .` |
| L'API répond 500 après une modification | `make logs s=api` pour lire l'erreur, puis `make cc`. Une table manque ? `make db-update`. |
| La Swagger UI est vide ou ne s'affiche pas | `make restart` ; si cela persiste, `make composer c="install"` puis `make cc`. |
| Tout semble cassé | `make down && make up`. En dernier recours : `docker compose down -v` (efface la base) puis `make install`. |
