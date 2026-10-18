# J0 · TD — Premiers pas dans un projet Symfony

> Durée : environ 1h30, juste après le cours. Seul ou à deux, l'entraide est bienvenue.
> Antisèches : [Symfony, les bases](cheatsheets/symfony-bases.md) · [HTTP et REST](cheatsheets/http-rest.md)

Ce matin, vous ne construisez presque rien : vous apprenez à lire. Vous allez visiter un projet Symfony, écrire un
tout petit contrôleur pour voir une route naître, puis décortiquer ligne à ligne le contrôleur d'exemple que vous
imiterez cet après-midi. Si à midi vous savez expliquer ce que fait chaque ligne de `GameController.php`, le TP se
passera bien.

Trois réflexes à prendre dès maintenant, et à garder toute la journée :

- **`make test` après chaque étape.** Les fichiers de `tests/` sont le contrat de votre API : ils disent exactement ce
  qu'on attend. Lisez le fichier de test *avant* de coder, revenez-y au moindre doute.
- **La Swagger UI** (http://localhost:8000/api) pour essayer une route sans taper de commande. Et `curl` quand on veut
  voir les en-têtes bruts.
- **Un commit et un push par étape** : `git add -A && git commit -m "J0 : …" && git push`.

Un mot sur un raccourci que nous prenons aujourd'hui : `make db-update` aligne les tables de la base sur vos entités
(`doctrine:schema:update --force`). C'est pratique pour apprendre, et interdit en production, où l'on écrit des
**migrations** versionnées (`make:migration` puis `doctrine:migrations:migrate`). On en reparle en fin de semaine.

---

## Étape 0 — Visiter le projet (30 min)

### Ce qu'on cherche à comprendre

Où vit le code, par où entre une requête, comment on parle à Symfony, et où regarder quand quelque chose ne va pas.

### 0.1 Vérifier que tout tourne

Si ce n'est pas déjà fait : `make doctor` puis `make install` (voir le [README](../README.md)). Puis :

```bash
make test
```

Le fichier `00-games.hurl` doit être **vert** : c'est l'exemple fourni, il prouve que votre environnement fonctionne.
Les fichiers `01` à `06` sont **rouges**, avec un `404` : c'est normal, les routes n'existent pas encore. Ce sont les
étapes de la journée.

Hurl vous dit pour chaque échec la ligne du test, la valeur attendue et la valeur obtenue. Quand ce n'est pas assez,
`make test ERRORS=long` affiche la réponse HTTP complète. Retenez aussi que les tests tournent sur une **base séparée**,
recréée vide à chaque lancement : vos essais à la main ne les perturbent jamais, et réciproquement.

### 0.2 L'arborescence

Le code de l'API est dans `api/`, monté dans le conteneur sous `/app`.

```text
api/
├── bin/console        la console Symfony (make sf c="…" la lance dans le conteneur)
├── config/            la configuration : packages/*.yaml (un fichier par outil), routes.yaml, services.yaml
├── public/index.php   le « contrôleur frontal » : TOUTES les requêtes HTTP entrent par ce fichier
├── src/               VOTRE code (espace de noms App\) : Controller/, Entity/, Repository/, Enum/…
├── var/               cache et journaux, générés (dans un volume Docker : vide de votre côté, c'est normal)
├── vendor/            les bibliothèques installées par Composer : on ne les modifie jamais
├── composer.json      la liste de ces bibliothèques (Symfony, Doctrine…)
└── .env               les variables d'environnement : APP_ENV=dev, DATABASE_URL…
```

Ouvrez trois fichiers, juste pour les voir :

- `api/public/index.php` : neuf lignes. Il crée le `Kernel`, qui traite la requête. C'est tout.
- `api/config/services.yaml` : `autowire: true` et `App\: resource: '../src/'`. Ces deux lignes font de **chaque
  classe** de `src/` un **service** que Symfony sait construire et fournir à qui le demande. Vous verrez à l'étape 2
  à quel point c'est pratique.
- `api/config/routes.yaml` : `resource: routing.controllers`, autrement dit « lis les attributs `#[Route]` des
  contrôleurs ». Il n'y a pas de fichier de routes à tenir à jour : la route vit à côté du code qu'elle déclenche.

### 0.3 La console

```bash
make sf c="about"          # Symfony 7.4.x, Environment dev, Debug true
make sf c="list"           # toutes les commandes, rangées par préfixe : debug:, doctrine:, make:…
make sf c="debug:router"   # toutes les routes de l'application
```

Dans la sortie de `debug:router`, repérez les cinq routes de l'exemple, et laissez les autres de côté (`_profiler…`
et `_wdt…` sont les outils de développement, `app.swagger…` la documentation) :

```text
  api_game_list      GET      /api/games
  api_game_show      GET      /api/games/{id}
  api_game_create    POST     /api/games
  api_game_update    PATCH    /api/games/{id}
  api_game_delete    DELETE   /api/games/{id}
```

`make sf c="debug:router api_game_show"` donne le détail d'une route : ses `Requirements` (`id: [0-9]+`), ses
`Defaults` (`_format: json`). Gardez cette commande sous le coude, on y revient à l'étape 2.

### 0.4 La Swagger UI

Ouvrez http://localhost:8000/api. Vous voyez la documentation de votre API, générée automatiquement à partir des
routes : un bloc « Jeux » avec les cinq opérations, et en bas les **schémas** `Game` et `Genre` déduits de l'entité.

Cette page a deux usages aujourd'hui. D'abord **essayer** : dépliez `POST /api/games`, cliquez *Try it out*, remplissez
le corps (`{"name": "Rocket League", "genre": "sports", "teamSize": 3}`) et *Execute*. Vous voyez la requête envoyée,
le code de retour, les en-têtes (dont `Location`) et le corps. Ensuite **vérifier** : à chaque route que vous
écrirez, rechargez cette page, elle doit y apparaître. Si elle n'y est pas, Symfony ne la connaît pas.

Deux détails utiles. L'interface n'est qu'un habillage du fichier http://localhost:8000/api/docs.json, la spécification
**OpenAPI** de votre API : ouvrez-le, c'est ce format que les outils comme Postman savent importer. Et les descriptions
que vous lisez sur `GET /api/games/{id}` viennent d'attributs `#[OA\…]` posés dans le contrôleur : ils sont facultatifs,
la route apparaît sans eux ; ils la rendent juste plus parlante.

### 0.5 Le profiler

En environnement `dev`, Symfony enregistre **chaque requête** : le SQL exécuté, la validation, la sérialisation, les
journaux, l'exception éventuelle.

```bash
curl -i http://localhost:8000/api/games
```

Dans la réponse, parmi les en-têtes, cherchez `X-Debug-Token-Link: http://localhost:8000/_profiler/ffc075`. Ouvrez
cette URL dans le navigateur et parcourez les onglets **Request / Response**, **Doctrine** (la requête SQL), **Logs**.
La page http://localhost:8000/_profiler liste les dernières requêtes. Pour une API, c'est l'outil de débogage numéro un :
la « barre de debug » ne s'affiche que sur des pages HTML.

> **À retenir.** Une requête entre par `public/index.php`, le routeur choisit une méthode de contrôleur d'après les
> `#[Route]`, la méthode renvoie une `Response`. La console (`make sf`), la Swagger UI et le profiler sont vos trois
> fenêtres sur ce qui se passe.

---

## Étape 1 — Un premier contrôleur (30 min) → `01-ping.hurl`

### Ce qu'on cherche à comprendre

Comment une URL devient un appel de méthode PHP : le chemin, les paramètres, les méthodes HTTP, et ce qui se passe
quand rien ne correspond.

Ouvrez `tests/01-ping.hurl`. Il attend deux routes : `GET /api/ping` qui répond `{"status": "ok", "league": "GG League"}`,
et `GET /api/hello/Zer0Day` qui répond `{"message": "GG Zer0Day !"}`. Il vérifie aussi deux refus : un pseudo trop
court ou avec un tiret donne `404`, un `POST` sur `/api/ping` donne `405`.

### 1.1 Générer

```bash
make sf c="make:controller PingController --no-template"
```

`--no-template` : pas de gabarit Twig, on fait une API. À la question sur les tests PHPUnit, tapez Entrée. Le maker
crée `api/src/Controller/PingController.php` :

```php
final class PingController extends AbstractController
{
    #[Route('/ping', name: 'app_ping')]
    public function index(): JsonResponse
    {
        return $this->json([
            'message' => 'Welcome to your new controller!',
            'path' => 'src/Controller/PingController.php',
        ]);
    }
}
```

Essayez `curl -i http://localhost:8000/ping` : `200`. Puis `curl -i -X DELETE http://localhost:8000/ping` : `200`
aussi. Sans `methods`, une route accepte **toutes** les méthodes (`make sf c="debug:router app_ping"` affiche
`Method | ANY`). Ce n'est presque jamais ce qu'on veut.

### 1.2 Adapter : préfixe, nom, méthode, format

Remplacez la classe par celle-ci, et lisez les commentaires numérotés en dessous :

```php
#[Route('/api', name: 'api_', format: 'json')]                // ①
final class PingController extends AbstractController         // ②
{
    #[Route('/ping', name: 'ping', methods: ['GET'])]         // ③
    public function ping(): JsonResponse                      // ④
    {
        return $this->json(['status' => 'ok', 'league' => 'GG League']);   // ⑤
    }
}
```

① Un `#[Route]` sur la **classe** donne un préfixe d'URL (`/api`) et un préfixe de **nom** (`api_`) à toutes les
méthodes. `format: 'json'` demande que les **erreurs** de ces routes (404, 422…) soient rendues en JSON plutôt qu'en
page HTML. ② `AbstractController` apporte des raccourcis : `json()`, `generateUrl()`, `createNotFoundException()`.
③ L'URL complète est `/api/ping`, le nom complet `api_ping`, et seule la méthode `GET` est acceptée. ④ Une **action**
est une méthode publique qui renvoie une `Response` ; `JsonResponse` en est une. ⑤ `json()` transforme un tableau ou
un objet en JSON, avec le statut `200` et `Content-Type: application/json` par défaut.

Vérifiez avec `make sf c="debug:router"` : `app_ping` a disparu, `api_ping` est là. Rechargez la Swagger UI : votre
route y figure, dans une section « default » puisqu'elle n'a pas de tag.

### 1.3 Un paramètre de route

Ajoutez une seconde action. Le `return` est à vous :

```php
#[Route('/hello/{name}', name: 'hello', methods: ['GET'], requirements: ['name' => '[A-Za-z0-9_]{2,30}'])]
public function hello(string $name): JsonResponse      // {name} dans l'URL → argument $name (même nom)
{
    // À vous : {"message": "GG Zer0Day !"}   (sprintf('GG %s !', $name), ou une concaténation avec .)
}
```

`requirements` est une **expression régulière** : de 2 à 30 lettres, chiffres ou `_`. Si l'URL ne la respecte pas, la
route **ne correspond pas**, tout simplement.

```bash
curl -i http://localhost:8000/api/hello/Zer0Day      # 200 {"message":"GG Zer0Day !"}
curl -i http://localhost:8000/api/hello/x            # 404... en HTML !
make sf c="router:match /api/hello/x"                # Route "api_hello" almost matches but requirement for "name" does not match
```

Pourquoi du HTML et pas du JSON ? Parce qu'**aucune** route n'a été trouvée : le `format: 'json'` d'une route ne peut pas
s'appliquer à une requête qui n'atteint aucune route. C'est normal, et le test s'en contente (il ne regarde que le statut).

### 1.4 Les méthodes HTTP

`curl -i -X POST http://localhost:8000/api/ping` répond `405 Method Not Allowed`, avec l'en-tête **`Allow: GET`** : l'URI
existe, mais pas avec ce verbe. Le corps est une page HTML, ne lisez que le statut.

> **À retenir.** Une route, c'est un chemin (avec ses `{paramètres}` et leurs `requirements`), des méthodes et un nom.
> Aucune route ne correspond : `404`. Le chemin existe mais pas la méthode : `405` + `Allow`. Ces deux erreurs sont
> produites **avant** votre code, par le routeur.

`make test f=01` : vert. Commitez : `git add -A && git commit -m "J0 : PingController" && git push`.

---

## Étape 2 — Lire `GameController` ligne à ligne (30 min)

### Ce qu'on cherche à comprendre

Tout ce qu'il faut pour écrire un CRUD REST à la main : charger une entité depuis l'URL, recevoir et valider du JSON,
écrire en base, renvoyer le bon code. Cet après-midi, vous ferez la même chose pour `Team` et `Player` ; autant que
chaque ligne soit claire maintenant.

Ouvrez `api/src/Entity/Game.php` et `api/src/Controller/GameController.php` côte à côte.

### 2.1 Lecture guidée

**L'entité.** Dans `Game.php`, deux familles d'attributs cohabitent. `#[ORM\…]` décrit la **table** pour Doctrine
(colonne, longueur, unicité). `#[Assert\…]` décrit les **règles de validation** pour le Validator : ce sont elles qui
produiront des `422`. Sur la classe, `#[UniqueEntity('name')]` vérifie l'unicité **avant** d'écrire en base. Et notez
qu'il n'y a pas de `setId()` : l'identifiant est attribué par la base, jamais par le client.

**L'injection de dépendances.** Vous n'écrirez jamais `new EntityManager(…)`. Vous **demandez** un service par son
**type**, et Symfony le fournit : c'est l'*autowiring*. Cela marche dans le constructeur, pour toute la classe, ou en
argument d'une action, pour cette action seulement.

```php
public function __construct(private readonly EntityManagerInterface $em) {}   // pour toute la classe
public function list(GameRepository $games): JsonResponse                     // pour cette action
```

`make sf c="debug:autowiring EntityManager"` liste ce qu'on peut demander.

**`list()`.** `findBy([], ['name' => 'ASC'])` : des critères (aucun) et un tri, soit `SELECT … FROM game ORDER BY name`.
Puis `$this->json($list)` : le Serializer produit un champ JSON par **getter**.

**`show(Game $game)`.** C'est la ligne la plus magique du fichier. Symfony lit `{id}` dans l'URL, charge le jeu en base
et le passe en argument : c'est l'**EntityValueResolver**. Si le jeu n'existe pas, `404` en JSON, sans une ligne de code.
Et `requirements: ['id' => Requirement::DIGITS]` refuse `/api/games/abc` **avant** même d'interroger la base.

**`create(#[MapRequestPayload] Game $game)`.** Avant d'entrer dans la méthode, `#[MapRequestPayload]` fait trois choses :
il vérifie le `Content-Type` (sinon `415`), transforme le JSON en objet `Game` (JSON illisible : `400` ; mauvais type :
`422`), puis **valide** l'objet avec les `#[Assert]` (`422` avec la liste des `violations`). Ensuite seulement,
`persist()` marque l'objet « à enregistrer » et `flush()` envoie l'`INSERT` ; l'id est connu après le `flush()`. La
réponse est `201` avec un en-tête `Location` construit par `generateUrl('api_game_show', …)`.

**`update()`** (PATCH). Pas de `MapRequestPayload` ici : on ne crée pas un objet, on **complète** l'objet existant avec
les champs reçus, grâce à l'option `OBJECT_TO_POPULATE` du Serializer. Puis on valide **nous-mêmes** et, s'il y a des
violations, on lève `UnprocessableEntityHttpException` avec une `ValidationFailedException` dedans : même format `422`
qu'au-dessus. Enfin `flush()` suffit : Doctrine sait que l'objet qu'il a chargé a changé.

**`delete()`.** `remove()` puis `flush()`, et `new Response(null, Response::HTTP_NO_CONTENT)` : un `204`, sans corps.

### 2.2 Chaque requête, son code

Créez un fichier `docs/mon-tp.md` dans votre dépôt (il vous servira toute la journée), recopiez-y ce tableau et
remplissez-le en jouant les requêtes. Faites les premières depuis la Swagger UI (*Try it out*), puis passez à `curl`
pour les cas que l'interface ne sait pas produire (mauvais `Content-Type`, JSON cassé). Remplacez `1` par l'id renvoyé
dans `Location`. La première ligne est faite.

| # | Requête | Code obtenu | Pourquoi ? |
|---|---|---|---|
| 1 | `POST /api/games` valide | `201` | créé ; `Location: /api/games/1` ; l'id vient de la base |
| 2 | le **même** POST, une seconde fois | | |
| 3 | `GET /api/games` | | |
| 4 | `GET /api/games/999999` | | |
| 5 | `GET /api/games/abc` | | |
| 6 | `PATCH /api/games/1` avec `{"teamSize": 2}` | | |
| 7 | `PATCH` avec `{"teamSize": 99}`, puis `GET` | | |
| 8 | `PATCH` avec `{"teamSize": "deux"}` | | |
| 9 | `POST` avec `Content-Type: text/plain` | | |
| 10 | `POST` d'un JSON mal formé | | |
| 11 | `POST` **sans** `-H 'Content-Type: …'` | | |
| 12 | `PUT /api/games/1` | | |
| 13 | `DELETE /api/games/1`, **deux fois** | | |

```bash
API=http://localhost:8000
curl -i -X POST $API/api/games -H 'Content-Type: application/json' -d '{"name": "Rocket League", "genre": "sports", "teamSize": 3}'  # 1 et 2
curl -i $API/api/games                                                                               # 3
curl -i $API/api/games/999999                                                                        # 4
curl -i $API/api/games/abc                                                                           # 5
curl -i -X PATCH $API/api/games/1 -H 'Content-Type: application/json' -d '{"teamSize": 2}'           # 6 (puis 99, puis "deux")
curl -i -X POST $API/api/games -H 'Content-Type: text/plain' -d 'name=Oops'                          # 9
curl -i -X POST $API/api/games -H 'Content-Type: application/json' -d '{"name": "Oops",'             # 10
curl -i -X POST $API/api/games -d '{"name": "Valorant", "genre": "fps", "teamSize": 5}'              # 11
curl -i -X PUT $API/api/games/1 -H 'Content-Type: application/json' -d '{}'                          # 12
curl -i -X DELETE $API/api/games/1                                                                   # 13 (deux fois)
```

<details>
<summary>Correction (à ouvrir après avoir rempli)</summary>

2 : `422`, `propertyPath: name`, « Ce jeu existe déjà. » (`#[UniqueEntity]`). 3 : `200`, un tableau trié par nom.
4 : `404` en **JSON** (EntityValueResolver). 5 : `404` en **HTML** : aucune route ne correspond (`DIGITS`). 6 : `200`.
7 : `422` (`Range`), et le `GET` montre que **rien** n'a été enregistré (pas de `flush()`). 8 : `400` (« Corps de requête
invalide ») alors qu'un POST avec `"teamSize": "cinq"` donne `422` : le PATCH fait main n'a pas les finesses de
`#[MapRequestPayload]`. 9 : `415`. 10 : `400`. 11 : `422` sur **tous** les champs : sans `-H`, curl envoie
`application/x-www-form-urlencoded`, Symfony lit un formulaire… sans aucun champ attendu. 12 : `405` +
`Allow: GET, PATCH, DELETE`. 13 : `204` (sans corps) puis `404`.
</details>

Rejouer `DELETE` laisse le serveur dans le même état (le jeu n'existe pas) : `DELETE` est **idempotente**, même si la
seconde réponse est un `404`. Rejouer un `POST` crée un doublon, ou échoue grâce à une contrainte d'unicité (ligne 2) :
`POST` ne l'est pas.

### 2.3 Une petite modification guidée : `?genre=fps`

Pour finir, une modification qui n'est pas testée, juste pour mettre les mains dedans. Modifiez `list()` pour filtrer
par genre. `#[MapQueryParameter]` lit `?genre=` dans l'URL et le convertit en `Genre` (l'enum) :

```php
use App\Enum\Genre;
use Symfony\Component\HttpKernel\Attribute\MapQueryParameter;

public function list(
    GameRepository $games,
    #[MapQueryParameter] ?Genre $genre = null,                 // ?genre=fps → Genre::Fps ; absent → null
): JsonResponse {
    $criteria = null !== $genre ? ['genre' => $genre] : [];    // [] = aucun filtre
    $list = $games->findBy($criteria, ['name' => 'ASC']);

    return $this->json($list);
}
```

Créez un jeu `fps` et un jeu `sports`, puis essayez `curl -s "$API/api/games?genre=fps"` (un seul jeu) et
`curl -i "$API/api/games?genre=zzz"`. Rechargez la Swagger UI : le paramètre `genre` est apparu sur `GET /api/games`,
avec la liste des valeurs possibles.

`?genre=zzz` donne `404` : c'est le comportement par défaut de `#[MapQueryParameter]`. Une valeur **mal formée** est
plutôt une requête invalide : écrivez `#[MapQueryParameter(validationFailedStatusCode: Response::HTTP_BAD_REQUEST)]`
et vérifiez que vous obtenez `400`.

> **À retenir.** Une requête traverse le **routeur**, puis les **résolveurs d'arguments** (un service, une entité
> chargée par son id, le corps JSON désérialisé et validé, un paramètre d'URL), puis **votre action**, qui renvoie
> une `Response`. Beaucoup d'erreurs (`404`, `405`, `415`, `400`, `422`) sont produites avant votre code.
> `persist()` prépare, `flush()` écrit.

`make test` : `00-games` toujours vert (sans `?genre`, la liste n'a pas changé), `01-ping` vert. Commitez.

---

## Fin du TD

Vous avez tout vu : une route, un contrôleur, une entité, le repository, la validation, la sérialisation. Cet
après-midi, vous assemblez ces briques pour les équipes et les joueurs, puis vous allez un cran plus loin avec une
requête sur mesure et un service. Avant la pause : commit, push, et relisez une fois `GameController.php` sans les
commentaires, pour vérifier que vous n'avez plus besoin d'eux.
