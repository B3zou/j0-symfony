# J0 · TP — Le registre de la ligue, fait main

> Durée : l'après-midi, 13h30 – 17h30. Seul, entraide autorisée.
> Paliers : 🟢 indispensable et très guidé · 🔵 attendu, avec des indices · 🔴 pour aller plus loin.
> Antisèches : [Symfony, les bases](cheatsheets/symfony-bases.md) · [HTTP et REST](cheatsheets/http-rest.md)

Ce matin vous avez lu une API. Cet après-midi vous en écrivez une : les **équipes** de la ligue, leurs **joueurs**, avec
tout ce qu'une vraie API doit savoir faire : créer, lire, filtrer, paginer, modifier, supprimer, refuser proprement ce
qui est invalide. Puis, pour ceux qui y arrivent, deux choses que `findBy()` et un contrôleur seul ne savent pas faire :
une **requête sur mesure** dans un repository, et un **service** qui porte de la logique métier.

**Ce que vous devez avoir à 17h30**

- `make test` vert pour `02`, `03`, `04` au moins ; `05` et `06` si vous êtes allé au bout ;
- dans `docs/mon-tp.md` : les réponses aux quelques questions posées en chemin, et trois lignes de bilan ;
- un commit par étape, poussé sur votre fork.

Ce projet est **votre point de départ de demain**. Gardez-le fonctionnel : si une étape casse tout, revenez au dernier
commit plutôt que de bricoler.

**Les étapes**

| | Étape | Durée | Test |
|---|---|---|---|
| 🟢 | 1. L'entité `Team` | 45 min | |
| 🟢→🔵 | 2. `TeamController` | 60 min | `02-teams` |
| 🔵 | 3. `Player`, la relation, le DTO | 75 min | `03-players` |
| 🔵 | 4. Pagination | 30 min | `04-pagination` |
| 🔵 | 5. Données de démo | 10 min | |
| 🔵 | 6. Une requête sur mesure dans le repository | 30 min | `05-top-players` |
| 🔵 | 7. Un service : le simulateur de match | 40 min | `06-versus` |
| 🔴 | 8. Bonus au choix | | |

C'est plus que l'après-midi ne contient : c'est voulu. Les étapes 1 à 4 sont le cœur ; 6 et 7 sont là pour que
personne ne s'ennuie, et vous pourrez les reprendre plus tard, le dépôt reste à vous.

**Avant chaque étape, lisez le fichier de test.** Il dit exactement ce qu'on attend : les URL, les codes, la forme du
JSON. Les énoncés ci-dessous expliquent le *pourquoi* et donnent les *outils* ; le *quoi* précis est dans le test.

---

## Étape 1 — 🟢 L'entité `Team` (45 min)

Une équipe a un **nom** unique, un **tag** unique de 2 à 5 caractères (`NUL`, `404`…) et un **pays**, sous forme de
code ISO à deux lettres (`FR`). Rien d'autre pour l'instant.

### 1.1 Générer l'entité

```bash
make sf c="make:entity Team"
```

Le maker pose des questions ; `↵` signifie « Entrée », on garde la valeur proposée entre crochets.

| Question | Réponse |
|---|---|
| `New property name (press <return> to stop adding fields)` | `name` |
| `Field type (enter ? to see all types) [string]` | `↵` |
| `Field length [255]` | `50` |
| `Can this field be null in the database (nullable) (yes/no) [no]` | `↵` |
| `Add another property?` | `tag`, puis `↵`, `5`, `↵` |
| `Add another property?` | `country`, puis `↵`, `2`, `↵` |
| `Add another property?` | `↵` pour terminer |

Deux fichiers sont créés : `src/Entity/Team.php` (les propriétés, leurs getters et setters) et
`src/Repository/TeamRepository.php`. Le message final propose `make:migration` : ignorez-le aujourd'hui (voir le
raccourci expliqué dans le TD).

Pour les suivantes, vous pouvez éviter les questions : `make sf c="make:entity Team --field=name:string:50 --field=tag:string:5 --field=country:string:2"`.

### 1.2 Compléter : contraintes, unicité, groupes

Le maker a produit le squelette. À vous d'ajouter ce que la base et l'API doivent garantir. Complétez `Team.php` pour
obtenir exactement ceci, en gardant les getters et setters générés :

```php
<?php

namespace App\Entity;

use App\Repository\TeamRepository;
use Doctrine\ORM\Mapping as ORM;
use Symfony\Bridge\Doctrine\Validator\Constraints\UniqueEntity;
use Symfony\Component\Serializer\Attribute\Groups;
use Symfony\Component\Validator\Constraints as Assert;

/** Une équipe (« roster ») de la ligue. */
#[ORM\Entity(repositoryClass: TeamRepository::class)]
#[UniqueEntity('name', message: 'Ce nom d\'équipe est déjà pris.')]
#[UniqueEntity('tag', message: 'Ce tag est déjà utilisé.')]
class Team
{
    #[ORM\Id]
    #[ORM\GeneratedValue]
    #[ORM\Column]
    #[Groups(['team:read'])]
    private ?int $id = null;

    /** Nom complet de l'équipe (unique). */
    #[ORM\Column(length: 50, unique: true)]
    #[Assert\NotBlank]
    #[Assert\Length(min: 2, max: 50)]
    #[Groups(['team:read', 'team:write'])]
    private ?string $name = null;

    /** Abréviation affichée sur les scoreboards : 2 à 5 majuscules ou chiffres (ex. « NUL »). */
    #[ORM\Column(length: 5, unique: true)]
    #[Assert\NotBlank]
    #[Assert\Regex('/^[A-Z0-9]{2,5}$/', message: 'Le tag doit faire 2 à 5 caractères en majuscules ou chiffres.')]
    #[Groups(['team:read', 'team:write'])]
    private ?string $tag = null;

    /** Pays de l'équipe, code ISO 3166-1 alpha-2 (ex. « FR »). */
    #[ORM\Column(length: 2)]
    #[Assert\NotBlank]
    #[Assert\Country]
    #[Groups(['team:read', 'team:write'])]
    private ?string $country = null;

    // … getters et setters générés par le maker
}
```

Trois familles d'attributs, trois rôles. `#[ORM\Column(length: 50, unique: true)]` fabrique une colonne `VARCHAR(50)`
et un **index unique** en base. `#[Assert\NotBlank]`, `Length`, `Regex`, `Country` sont les règles que le Validator
vérifie : si elles échouent, l'API répond `422` avec la liste des violations. `#[UniqueEntity('tag')]`, posé sur la
**classe**, va chercher en base s'il existe déjà une équipe avec ce tag, **avant** d'écrire.

Pourquoi deux protections pour l'unicité ? Parce qu'elles ne font pas la même chose. `unique: true` est le dernier
rempart : la base refusera le doublon, mais votre API répondra alors `500`, ce qui n'est pas une réponse. `#[UniqueEntity]`
vérifie avant et produit un `422` lisible. Il faut les deux.

Enfin `#[Groups(…)]` : le Serializer ne **lit** (JSON de réponse) ou n'**écrit** (JSON reçu) un champ que si l'on demande
l'un de ses groupes. L'id n'a que `team:read` : un client ne choisit jamais son id, et un `"id": 424242` envoyé sera
ignoré. Le test le vérifie. On verra à l'étape 2 pourquoi les groupes deviennent vite indispensables.

### 1.3 Créer la table

```bash
make db-update
```

La commande affiche le SQL exécuté : un `CREATE TABLE team (…)` et deux `CREATE UNIQUE INDEX`. Relancez-la **après
chaque modification** d'un `#[ORM\…]`. Puis vérifiez :

```bash
make sf c="dbal:run-sql 'SELECT * FROM team'"     # [OK] The query yielded an empty result set.
make sf c="doctrine:schema:validate"              # deux [OK] : mapping correct, base synchronisée
```

Commitez : `git add -A && git commit -m "J0 : entité Team" && git push`.

---

## Étape 2 — 🟢→🔵 `TeamController` (60 min) → `02-teams.hurl`

Lisez `tests/02-teams.hurl`. Il attend `GET` et `POST` sur `/api/teams`, `GET`, `PATCH` et `DELETE` sur
`/api/teams/{id}`, un filtre `?country=BE`, un tri par nom, et vérifie la validation (tag, pays, unicité, champs
obligatoires), l'id ignoré, le `404` en JSON.

### 2.1 🟢 Le squelette

Copiez `GameController.php` en `TeamController.php` et adaptez l'en-tête :

```php
#[Route('/api/teams', name: 'api_team_', format: 'json')]
final class TeamController extends AbstractController
{
    private const READ = ['groups' => ['team:read']];     // ce que l'API renvoie
    private const WRITE = ['groups' => ['team:write']];   // ce que le client a le droit d'envoyer

    public function __construct(private readonly EntityManagerInterface $em) {}

    // list(), show(), create(), update(), delete() : à adapter, voir ci-dessous
}
```

Remplacez `Game` par `Team` partout : la classe, le repository, le nom de route `api_team_show` dans `generateUrl()`.
Rechargez la Swagger UI : une section « default » avec vos cinq routes doit apparaître (ajoutez `#[OA\Tag(name: 'Équipes')]`
sur la classe si vous voulez votre propre section, c'est facultatif).

### 2.2 🟢 Lire et écrire avec un groupe

Les groupes sont une **liste blanche** : quand on en demande un, seuls les champs qui le portent sont lus ou écrits.
Il faut donc dire au Serializer quel groupe utiliser, à chaque fois.

Pour **lire** (objet → JSON), on passe le groupe dans le quatrième argument de `json()`, le **contexte** :

```php
return $this->json($team, context: self::READ);                    // argument nommé : on saute $status et $headers

return $this->json($team, Response::HTTP_CREATED, [                // dans create() : les quatre arguments
    'Location' => $this->generateUrl('api_team_show', ['id' => $team->getId()]),
], self::READ);
```

Pour **écrire** avec `#[MapRequestPayload]` (JSON → objet), le contexte se donne dans l'attribut :

```php
public function create(#[MapRequestPayload(serializationContext: self::WRITE)] Team $team): JsonResponse
```

Et dans le PATCH, on ajoute le groupe au contexte existant (`+` réunit deux tableaux PHP) :

```php
$serializer->deserialize($request->getContent(), Team::class, 'json', self::WRITE + [
    AbstractNormalizer::OBJECT_TO_POPULATE => $team,
]);
```

Pourquoi des groupes ici, alors que `Game` s'en passe ? Sans groupe demandé, le Serializer prend **tout** : chaque getter
en lecture, chaque setter en écriture. Pour `Game`, quatre champs simples, c'est acceptable. Pour `Team`, dès l'étape 3,
une équipe aura des joueurs, qui ont une équipe, qui a des joueurs… Sans groupes : `500`, *A circular reference has been
detected*. Et plus généralement, un jour, un champ sensible sortirait de l'API sans que personne ne l'ait décidé. Les
groupes, c'est décider.

### 2.3 🔵 Le filtre `?country=` et le tri

Inspirez-vous de la modification `?genre=` du TD : un argument `#[MapQueryParameter] ?string $country = null`, un
tableau de critères vide ou `['country' => …]`, et `findBy($criteria, ['name' => 'ASC'])`. Le test attend
`?country=BE` → deux équipes, `TAA` avant `TLB`. Acceptez aussi `?country=be` (`strtoupper()`).

### 2.4 🔵 `show()`, `update()`, `delete()`

Comme dans `GameController`, avec le contexte `self::READ` pour les réponses. N'oubliez pas
`requirements: ['id' => Requirement::DIGITS]` sur les routes `/{id}`.

### Vérifier

```bash
API=http://localhost:8000
curl -i -X POST $API/api/teams -H 'Content-Type: application/json' -d '{"name": "Null Pointers", "tag": "NUL", "country": "FR"}'  # 201 + Location
curl -i -X POST $API/api/teams -H 'Content-Type: application/json' -d '{"name": "Bad", "tag": "bad!", "country": "XX"}'         # 422 : tag, country
curl -s "$API/api/teams?country=FR"                                                                   # [{"id":1,"name":"Null Pointers",…}]
curl -i -X PATCH $API/api/teams/1 -H 'Content-Type: application/json' -d '{"country": "BE"}'         # 200
curl -i $API/api/teams/999999                                                                         # 404, Content-Type: application/json
```

Puis `make test f=02`. Le fichier échoue **encore**, mais seulement à une ligne :

```text
 22 | jsonpath "$.players" count == 0
    |                      ^^^^^ missing value to apply filter
```

Une équipe doit lister ses **joueurs** : c'est l'objet de l'étape 3. Tout le reste est vert ? Commitez :
`git add -A && git commit -m "J0 : TeamController" && git push`.

---

## Étape 3 — 🔵 `Player` et la relation avec `Team` (75 min) → `03-players.hurl`

Un joueur a un **pseudo** unique, un pays, un **rôle** facultatif, un **classement** Elo entre 0 et 3000 (1000 par
défaut), une **date de naissance** (une donnée personnelle, on y reviendra) et une **équipe** facultative : sans équipe,
c'est un agent libre.

Lisez `tests/03-players.hurl` en entier. Trois choses à remarquer : l'équipe est **envoyée par son id** (`"team": 3`)
mais **renvoyée imbriquée** (`{"name": …, "tag": …}`) ; `birthDate` n'est **jamais** renvoyée ; et `PUT` remplace
**tout** le joueur.

### 3.1 🟢 Générer l'entité et la relation

`make sf c="make:entity Player"`, puis :

| Propriété | Type (à taper) | Longueur | Nullable |
|---|---|---|---|
| `nickname` | `↵` (string) | 30 | `↵` (no) |
| `country` | `↵` (string) | 2 | `↵` (no) |
| `role` | `↵` (string) | 30 | **`yes`** |
| `rating` | `integer` | (pas demandée) | `↵` (no) |
| `birthDate` | `date_immutable` | (pas demandée) | **`yes`** |
| `team` | `ManyToOne` | voir ci-dessous | |

Pour `team`, le maker pose quatre questions : la classe liée (`Team`), si la propriété peut être nulle (`↵`, oui : un
agent libre), s'il doit ajouter une propriété `players` dans `Team` pour accéder aux joueurs depuis l'équipe (`↵`, oui),
et son nom (`↵`, `players`).

Le maker a modifié **deux** fichiers. `Player.php`, côté **propriétaire** de la relation : `#[ORM\ManyToOne(inversedBy:
'players')]`, c'est lui qui porte la colonne `team_id`. Et `Team.php`, côté **inverse** : `#[ORM\OneToMany(targetEntity:
Player::class, mappedBy: 'team')]`, avec `getPlayers()`, `addPlayer()`, `removePlayer()` et une `ArrayCollection`
initialisée dans le constructeur.

### 3.2 🔵 Contraintes, groupes, suppression d'une équipe

Complétez les deux entités d'après ce tableau, en vous inspirant de `Team` pour la syntaxe :

| Champ | Mapping et contraintes | Groupes |
|---|---|---|
| `Player` (classe) | `#[UniqueEntity('nickname', message: 'Ce pseudo est déjà pris.')]` | |
| `Player::$id` | | `player:read` |
| `Player::$nickname` | `unique: true` ; `NotBlank` ; `Length(min: 2, max: 30)` | `player:read`, `player:write`, `team:read` |
| `Player::$country` | `NotBlank` ; `Country` | `player:read`, `player:write` |
| `Player::$role` | `Length(max: 30)` | `player:read`, `player:write`, `team:read` |
| `Player::$rating` | `private int $rating = 1000;` (getter : `int`) ; `Range(min: 0, max: 3000)` | `player:read`, `player:write`, `team:read` |
| `Player::$birthDate` | `LessThan('-13 years', message: 'Un joueur doit avoir au moins 13 ans.')` | **`player:write` seulement** |
| `Player::$team` | `#[ORM\JoinColumn(onDelete: 'SET NULL')]` | `player:read`, `player:write` |
| `Team::$name`, `Team::$tag` | | **ajoutez** `player:read` |
| `Team::$players` | `#[ORM\OrderBy(['nickname' => 'ASC'])]` (conseillé) | `team:read` |

Lisez maintenant ce tableau **en colonnes**, groupe par groupe. Avec `team:read`, une équipe sort avec
`players: [{nickname, role, rating}]`, mais **sans** `players[].team`. Avec `player:read`, un joueur sort avec
`team: {name, tag}`, mais **sans** `team.players` ni `team.country`. Aucun chemin ne revient à son point de départ :
pas de boucle, donc pas de `500`.

`birthDate` n'a pas `player:read` : elle ne sortira jamais de l'API. C'est une donnée personnelle, et une API qui
renvoie plus que nécessaire est une des failles les plus courantes. Le groupe `player:write` ne sert pas encore
aujourd'hui (on écrit via un DTO, juste en dessous) ; il servira demain.

`onDelete: 'SET NULL'` : supprimer une équipe rend ses joueurs agents libres. Sans lui, `DELETE /api/teams/1` sur une
équipe qui a des joueurs répond `500`, *Foreign key violation*.

`make db-update` : une table `player`, une clé étrangère `team_id … ON DELETE SET NULL`.

### 3.3 🔵 Pourquoi un DTO pour écrire ?

Le client envoie `"team": 3`, mais `Player::$team` attend un **objet** `Team`. Si vous recevez directement l'entité
(`#[MapRequestPayload] Player $player`), le Serializer ne sait pas qu'il faut chercher l'équipe n°3 en base : il
fabrique une équipe **vide**, et Doctrine plante au `flush()` (`500`, *A new entity was found through the relationship
'App\Entity\Player#team'*).

Le fond du problème : **le contrat de l'API n'est pas le modèle de la base.** On décrit donc ce que le client envoie
dans une petite classe dédiée, un **DTO** (*Data Transfer Object*). Créez `api/src/Dto/PlayerInput.php` :

```php
<?php

namespace App\Dto;

/** Ce que le client envoie pour créer (POST) ou remplacer (PUT) un joueur. */
final class PlayerInput
{
    public string $nickname = '';
    public string $country = '';
    public ?string $role = null;
    public int $rating = 1000;
    public ?\DateTimeImmutable $birthDate = null;   // format attendu : "2002-04-12"
    public ?int $team = null;                       // id de l'équipe, ou null pour un agent libre
}
```

Les **types** protègent déjà l'API : `"rating": "beaucoup"` donne un `422` automatique. Les **règles métier** (pseudo
unique, âge minimum…) restent sur l'entité : on la validera après l'avoir remplie.

### 3.4 🔵 `PlayerController`

Routes attendues : `GET /api/players` (filtres `?team=ID` et `?country=FR`, tri par pseudo), `GET /api/players/{id}`,
`POST /api/players`, `PUT /api/players/{id}`, `DELETE /api/players/{id}`. Préfixe de nom : `api_player_`. Réponses
avec le groupe `player:read`.

Le cœur du contrôleur est une méthode **privée** `apply()`, partagée par `POST` et `PUT`, qui recopie le DTO dans
l'entité et la valide :

```php
public function __construct(
    private readonly EntityManagerInterface $em,
    private readonly TeamRepository $teams,         // pour retrouver l'équipe à partir de son id
    private readonly ValidatorInterface $validator, // pour valider l'entité une fois remplie
) {}

#[Route('', name: 'create', methods: ['POST'])]
public function create(#[MapRequestPayload] PlayerInput $input): JsonResponse
{
    $player = $this->apply(new Player(), $input);
    // À vous : persist, flush, 201 + Location (groupe player:read)
}

private function apply(Player $player, PlayerInput $input): Player
{
    // 1. recopier le DTO dans l'entité : $player->setNickname($input->nickname)->setCountry(…)…
    // 2. si $input->team n'est pas null : $this->teams->find($input->team) ; introuvable → 422 sur « team »
    // 3. $player->setTeam($team)   (null = agent libre)
    // 4. valider l'entité : $this->validator->validate($player) ; des violations → 422
    return $player;
}
```

Pour le point 2, il faut fabriquer une erreur `422` « à la main », au **même format** que les autres, sur le champ
`team` :

```php
use Symfony\Component\Validator\ConstraintViolation;
use Symfony\Component\Validator\ConstraintViolationList;

$violations = new ConstraintViolationList([
    //                     message                                      modèle, paramètres, racine, champ, valeur invalide
    new ConstraintViolation(sprintf('L\'équipe n°%d n\'existe pas.', $input->team), null, [], $input, 'team', $input->team),
]);
throw new UnprocessableEntityHttpException((string) $violations, new ValidationFailedException($input, $violations));
```

Vous lèverez la même exception au point 4 : factorisez-la dans une méthode privée
`fail(ConstraintViolationListInterface $violations, object $subject): never`.

Pour `list()` : deux `#[MapQueryParameter]` (`?int $team`, `?string $country`) et un tableau de critères.
`findBy(['team' => 3])` fonctionne tel quel : Doctrine compare `team_id`.

### 3.5 🔵 `PUT` : remplacement complet

`PUT` envoie la **représentation entière** du joueur : un champ absent reprend sa valeur **par défaut**, celle du DTO.
Le test envoie un `PUT` **sans** `team` : le joueur devient agent libre (`"team": null`). C'est toute la différence avec
`PATCH`, qui ne touche que les champs envoyés.

`replace(Player $player, #[MapRequestPayload] PlayerInput $input)` : `apply()` sur le joueur **existant**, puis
`flush()`. Pas de `persist()` : Doctrine le connaît déjà.

Question pour `mon-tp.md` : pourquoi `PUT` est-il idempotent, et pas forcément `PATCH` ?

### Vérifier

```bash
curl -i -X POST $API/api/players -H 'Content-Type: application/json' \
     -d '{"nickname": "Zer0Day", "country": "FR", "role": "striker", "rating": 2450, "birthDate": "2002-04-12", "team": 1}'
# 201 {"id":1,"nickname":"Zer0Day","country":"FR","role":"striker","rating":2450,"team":{"name":"Null Pointers","tag":"NUL"}}  ← pas de birthDate
curl -s $API/api/teams/1        # … "players":[{"nickname":"Zer0Day","role":"striker","rating":2450}]
curl -s -X POST $API/api/players -H 'Content-Type: application/json' -d '{"nickname": "Ghost", "country": "FR", "team": 999999}'   # 422 sur team
```

`make test` : `02-teams` et `03-players` verts. Commitez : `git add -A && git commit -m "J0 : Player, relation, DTO" && git push`.

---

## Étape 4 — 🔵 Pagination (30 min) → `04-pagination.hurl`

`GET /api/players` doit renvoyer **10** joueurs par page, triés par pseudo ; `?page=2` donne la suite ; le **total** est
dans l'en-tête `X-Total-Count` ; `?page=0` ou `?page=abc` répondent `400`. Lisez `tests/04-pagination.hurl`.

Les briques :

- `findBy()` accepte deux arguments de plus : `findBy($criteria, $orderBy, $limit, $offset)`. Pour la page `$page`,
  quel `$offset` ?
- Le total, **avec les mêmes critères** : `$players->count($criteria)`.
- Le paramètre `page` : un entier, au moins 1, `1` par défaut, et `400` sinon :
  `#[MapQueryParameter(options: ['min_range' => 1], validationFailedStatusCode: Response::HTTP_BAD_REQUEST)] int $page = 1`
  (`options` est passé à `filter_var()`, avec le filtre `FILTER_VALIDATE_INT` déduit du type `int`).
- L'en-tête : troisième argument de `json()`, avec une valeur **chaîne** : `['X-Total-Count' => (string) $total]`.

Deux pièges. Sans `validationFailedStatusCode`, `?page=abc` répond `404`, la valeur par défaut. Sans `min_range`,
`?page=0` donne un offset de `-10` et un `500`, *Offset must be a positive integer or zero*.

Question pour `mon-tp.md` : pourquoi mettre le total dans un **en-tête** plutôt que dans le corps ? Indice : le corps
reste un simple tableau. Demain, vous verrez l'autre choix (`totalItems` dans le corps), et vous pourrez comparer.

`curl -i "$API/api/players?page=1"` montre `X-Total-Count`, puis `make test` : `00` à `04` verts. Commitez.

---

## Étape 5 — 🔵 Données de démo (10 min)

Jusqu'ici vous avez créé vos données à la main. Pour la suite, il en faut davantage, et les mêmes pour tout le monde.
Un fichier de **fixtures** est fourni :

```bash
cp docs/ressources/AppFixtures.php api/src/DataFixtures/
make db-reset
```

`make db-reset` recrée la base et charge les fixtures dès que le dossier `src/DataFixtures/` existe : 5 jeux, 8 équipes
et 26 joueurs, avec des identifiants stables (Null Pointers est toujours l'équipe n°1). Ouvrez le fichier, il n'a rien de
mystérieux : des `new Team()`, des setters, `persist()`, un `flush()` à la fin. Vérifiez dans la Swagger UI que
`GET /api/teams` renvoie bien 8 équipes.

Ces fixtures resserviront demain. Commitez-les.

---

## Étape 6 — 🔵 Une requête sur mesure dans le repository (30 min) → `05-top-players.hurl`

`findBy()` ne sait faire que des égalités reliées par `AND`. Dès qu'on veut trier par un classement, limiter le nombre
de résultats, ou chercher « contient », il faut écrire la requête soi-même. Et le bon endroit pour l'écrire, c'est le
**repository** : c'est sa raison d'être. Le contrôleur, lui, ne doit pas savoir à quoi ressemble une requête.

Lisez `tests/05-top-players.hurl`. Deux choses sont attendues : `GET /api/players/top?limit=3&country=IS`, les meilleurs
joueurs par classement décroissant ; et `?q=top_` sur `GET /api/players`, une recherche dans le pseudo qui ignore la casse.

### 6.1 Le classement

Dans `PlayerRepository`, ajoutez une méthode avec le **QueryBuilder** (voir l'antisèche, section « Le QueryBuilder en
six lignes ») :

```php
/** @return Player[] les $limit meilleurs joueurs (optionnellement d'un pays), du plus fort au moins fort */
public function findTopRated(int $limit, ?string $country = null): array
```

`createQueryBuilder('p')`, `orderBy('p.rating', 'DESC')` (et `addOrderBy('p.nickname', 'ASC')` pour départager les
égalités), `setMaxResults($limit)`, et si un pays est demandé, `andWhere('p.country = :country')` avec `setParameter`.
Jamais de valeur concaténée dans la chaîne de requête : toujours un paramètre nommé.

Puis la route, dans `PlayerController` :

```php
#[Route('/top', name: 'top', methods: ['GET'])]
public function top(
    PlayerRepository $players,
    #[MapQueryParameter(options: ['min_range' => 1, 'max_range' => 50], validationFailedStatusCode: Response::HTTP_BAD_REQUEST)] int $limit = 10,
    #[MapQueryParameter] ?string $country = null,
): JsonResponse
```

Un piège vous attend, et il est instructif : `/api/players/top` ressemble à `/api/players/{id}`. Si votre route `show()`
n'avait pas `requirements: ['id' => Requirement::DIGITS]`, elle attraperait `top` et répondrait `500` (*invalid input
syntax for type integer: "top"*). Vérifiez avec `make sf c="router:match /api/players/top"`.

### 6.2 La recherche

La liste a maintenant trois filtres (`team`, `country`, `q`) et une pagination : `findBy()` et `count()` ne suffisent
plus pour `q`. Déplacez toute la requête de `list()` dans le repository :

```php
/** @return array{items: Player[], total: int} */
public function search(?string $q, ?int $team, ?string $country, int $page, int $perPage): array
```

Les conditions s'ajoutent une à une (`andWhere` seulement si le filtre est présent) ; pour `q` :
`andWhere('LOWER(p.nickname) LIKE :q')->setParameter('q', '%'.mb_strtolower($q).'%')`. Le tri reste `nickname ASC`,
la pagination se fait avec `setFirstResult()` et `setMaxResults()`. Pour le total avec les mêmes conditions, le plus
simple est `Doctrine\ORM\Tools\Pagination\Paginator` : `$paginator = new Paginator($qb->getQuery())`, puis
`count($paginator)` pour le total et `iterator_to_array($paginator)` pour les éléments.

`list()` devient trois lignes : lire les paramètres, appeler `search()`, renvoyer. `make test` : `04` doit rester vert
(la pagination passe désormais par `search()`), `05` passe au vert. Commitez.

---

## Étape 7 — 🔵 Un service : le simulateur de match (40 min) → `06-versus.hurl`

Jusqu'ici, toute la logique est dans les contrôleurs. Ça tient tant qu'elle se résume à « lire, valider, enregistrer ».
Dès qu'il y a une vraie règle métier, on la sort dans une classe à part, un **service**, pour trois raisons : le
contrôleur reste lisible, la règle est réutilisable (depuis une commande console, un autre contrôleur, un test), et elle
ne connaît rien à HTTP, ce qui la rend facile à tester.

Le service du jour simule un match **au meilleur des 5 manches** entre deux équipes. Chaque manche est tirée au sort,
avec une probabilité qui dépend du niveau moyen des joueurs : si l'équipe A a une moyenne de 1900 et l'équipe B de
1500, A gagne chaque manche avec une probabilité de 1900 / (1900 + 1500) ≈ 56 %. Le match s'arrête quand une équipe a
3 manches. Rien n'est enregistré.

Lisez `tests/06-versus.hurl` pour la forme exacte de la réponse et les cas d'erreur.

### 7.1 Le service

Créez `api/src/Service/MatchSimulator.php`. Aucune déclaration à faire ailleurs : toute classe de `src/` est un service
(c'est le `App\: resource: '../src/'` de `services.yaml`).

```php
namespace App\Service;

final class MatchSimulator
{
    public function simulate(Team $a, Team $b, ?int $seed = null): MatchResult
}
```

Et `MatchResult`, une petite classe sans comportement, juste la forme de la réponse :

```php
namespace App\Service;

final readonly class MatchResult
{
    public function __construct(
        public array $teamA,    // ['id' => …, 'name' => …, 'tag' => …, 'rating' => moyenne entière]
        public array $teamB,
        public array $score,    // [3, 1]
        public string $winner,  // le tag de l'équipe gagnante
        public array $rounds,   // ['VSA', 'VSA', 'VSB', 'VSA'] : le tag du gagnant de chaque manche
    ) {}
}
```

Pour le tirage, PHP fournit `Random\Randomizer`. Sans graine, `new Randomizer()` ; avec une graine,
`new Randomizer(new \Random\Engine\Mt19937($seed))` : la même graine donne toujours la même suite de tirages, ce qui
rend le service **testable** (le test fait deux appels avec `?seed=42` et attend le même résultat).
`$randomizer->nextFloat()` renvoie un nombre entre 0 et 1.

Si une équipe n'a aucun joueur, sa moyenne n'existe pas : le service lève une `\InvalidArgumentException`. Idem si les
deux équipes sont la même. Il ne connaît pas les codes HTTP ; c'est le contrôleur qui traduira.

### 7.2 La route

Dans `TeamController`, une route avec **deux** paramètres d'URL, donc deux entités chargées automatiquement :

```php
#[Route('/{id}/versus/{opponentId}', name: 'versus', methods: ['GET'], requirements: ['id' => Requirement::DIGITS, 'opponentId' => Requirement::DIGITS])]
public function versus(
    Team $team,
    #[MapEntity(id: 'opponentId')] Team $opponent,     // use Symfony\Bridge\Doctrine\Attribute\MapEntity;
    MatchSimulator $simulator,                          // le service, injecté comme n'importe quel autre
    #[MapQueryParameter] ?int $seed = null,
): JsonResponse
```

`#[MapEntity(id: 'opponentId')]` dit à Symfony quel paramètre d'URL utiliser pour charger la seconde équipe (par défaut
il cherche `{id}`). Une équipe inconnue : `404`, sans code.

Avant d'appeler le service, le contrôleur vérifie ce qui relève de la requête et répond `422` au même format que
partout ailleurs (une `ConstraintViolationList` fabriquée à la main, comme à l'étape 3) : même équipe deux fois → violation
sur `opponentId` ; équipe sans joueur → violation sur `id` ou `opponentId` selon l'équipe concernée. Puis
`return $this->json($simulator->simulate($team, $opponent, $seed));` : un objet `readonly` avec des propriétés publiques
se sérialise sans groupe.

Essayez plusieurs fois `curl -s $API/api/teams/1/versus/2` : le résultat change. Avec `?seed=7`, il ne change plus.
`make test` : `06` vert. Commitez.

Question pour `mon-tp.md` : `GET /api/teams/1/versus/2` est-il « REST » ? Ce n'est pas une ressource qu'on lit, c'est un
calcul qu'on déclenche. Notez votre avis, on y reviendra quand on parlera de RPC.

---

## Étape 8 — 🔴 Bonus au choix

Sans test automatique ; après chaque bonus, `make test` doit rester vert.

- **Un joueur au hasard.** `POST /api/teams/{id}/players/random` crée un joueur dans l'équipe, avec un pseudo tiré
  d'une liste, le pays de l'équipe, un rôle et un classement aléatoires, et répond `201` + `Location`. La génération
  va dans un service `App\Service\PlayerFactory` avec une méthode `random(Team $team): Player` ; le contrôleur ne fait
  que persister. Si le pseudo tiré existe déjà, le service en choisit un autre (il peut recevoir `PlayerRepository`).
- **Un service pour les `422`.** Le bloc « valider, puis lever `UnprocessableEntityHttpException` » se répète dans trois
  contrôleurs. Déplacez-le dans `App\Validation\EntityValidator` avec une méthode `validateOrFail(object $entity): void`,
  et injectez-la. Doc : https://symfony.com/doc/7.4/service_container.html
- **L'en-tête `Link`.** Comme l'API de GitHub : `Link: </api/players?page=3>; rel="next", </api/players?page=1>; rel="prev"`,
  en conservant les filtres (`generateUrl()` accepte des paramètres en plus). Format : https://www.rfc-editor.org/rfc/rfc8288
- **Documenter.** Ajoutez `#[OA\Tag]`, `#[OA\Response]` et `#[OA\Parameter]` sur vos routes (`use OpenApi\Attributes as OA;`),
  en vous inspirant de `GameController`, et regardez la Swagger UI changer. Doc : https://zircote.github.io/swagger-php/
- **Votre propre test.** Écrivez `tests/perso/equipe-supprimee.hurl` : supprimer une équipe rend ses joueurs agents
  libres. Lancez-le contre l'API de dev : `docker compose run --rm --no-deps hurl --test --variable host=http://api perso/`.
  Doc : https://hurl.dev/docs/
- **Pour demain.** `wc -l api/src/Controller/*.php api/src/Dto/*.php` : notez le total dans `mon-tp.md`. Vous le
  comparerez demain.

---

## Fin de journée (15 min)

`make test` : vert jusqu'où vous êtes allé. À la fin de `docs/mon-tp.md`, écrivez **trois lignes** : ce qui vous a semblé
**répétitif** aujourd'hui, d'un contrôleur à l'autre, d'une action à l'autre. Gardez-les : demain matin commence par là.

Commit final et push : `git add -A && git commit -m "J0 : API faite main (Team, Player, pagination, top, versus)" && git push`.

---

## Si vous êtes bloqué : les pièges fréquents

| Symptôme | Cause probable | Remède |
|---|---|---|
| `500` `relation "team" does not exist` | table pas créée | `make db-update` (après chaque modification d'un `#[ORM\…]`) |
| `500` *A circular reference has been detected when serializing the object of class "App\Entity\Team"* | `json()` **sans** `context: self::READ` : tout est sérialisé, `Team` → `players` → `team` → … | passez le groupe ; `Player::$team` ne doit **pas** avoir `team:read` |
| Un champ manque dans la réponse | il ne porte pas le groupe demandé | comparez le groupe de `json()` et les `#[Groups]` du champ (`make sf c="debug:serializer 'App\Entity\Team'"`) |
| `birthDate` apparaît dans la réponse | pas de groupe dans `json()` (tout sort), ou `player:read` sur `birthDate` | groupe `player:read` dans `json()`, et `birthDate` en `player:write` seulement |
| `GET /api/teams/abc` → page HTML `404` | aucune route ne correspond (`DIGITS`) : le `format: 'json'` ne s'applique pas | normal ; `make sf c="router:match /api/teams/abc"` explique |
| `GET /api/teams/999999` → `404` en **HTML** (le test attend du JSON) | `format: 'json'` oublié sur le `#[Route]` de la classe | ajoutez-le |
| `/api/players/top` → `500` *invalid input syntax for type integer: "top"* | `/{id}` sans `requirements` : elle attrape tout | `requirements: ['id' => Requirement::DIGITS]` |
| Une route a disparu de `debug:router` ou de la Swagger UI | deux routes ont le même `name` : la dernière chargée remplace l'autre, sans erreur | un préfixe de nom par contrôleur (`api_team_`, `api_player_`) |
| Votre route n'apparaît pas dans la Swagger UI | elle n'est pas sous `/api/`, ou le cache n'est pas à jour | vérifiez le `#[Route]` de la classe ; `make cc` |
| `415 Unsupported Media Type` | `Content-Type` absent ou faux sur un POST | `-H 'Content-Type: application/json'` |
| `422` « should not be blank » sur **tous** les champs, alors que vous les envoyez | `curl -d` sans `-H 'Content-Type: …'` : envoyé comme un formulaire | ajoutez l'en-tête |
| `POST` → `500` *Parameter "id" for route "api_team_show" must match "[0-9]+" ("" given)* ; ou `PATCH` → `200` mais un `GET` montre l'ancienne valeur | `flush()` oublié : aucune requête SQL n'est partie | `$this->em->flush()` |
| `500` *Unique violation: duplicate key value* | `unique: true` sans `#[UniqueEntity]` | `#[UniqueEntity('…')]` sur la classe |
| `500` *Controller "…::show" requires the "$team" argument that could not be resolved* | le paramètre de route ne s'appelle pas `{id}` | `{id}`, ou `#[MapEntity(id: 'opponentId')] Team $opponent` |
| `500` *A new entity was found through the relationship 'App\Entity\Player#team'* | l'entité reçue directement avec `"team": 3` : une équipe vide est fabriquée | le DTO `PlayerInput` et `$this->teams->find()` |
| `DELETE` d'une équipe → `500` *Foreign key violation* | `onDelete: 'SET NULL'` absent | ajoutez-le, puis `make db-update` |
| `?page=abc` → `404` ; `?page=0` → `500` | `#[MapQueryParameter]` sans `validationFailedStatusCode` ni `min_range` | voir l'étape 4 |
| `500` *Cannot autowire service "App\Service\MatchSimulator"* | le constructeur demande quelque chose qui n'est pas un service (un scalaire, une entité) | un service ne reçoit que des services ; les données passent en argument de méthode |
| Le simulateur donne toujours le même résultat | `Randomizer` créé une fois avec une graine fixe | créez-le à chaque appel, avec une graine seulement si elle est fournie |
| Vous avez modifié le code, la réponse n'a pas changé | PHP sert encore l'ancienne version du fichier (environ 2 s) ; plus rarement, le cache Symfony | relancez la requête ; sinon `make cc` |

Pour voir le détail d'une requête (SQL, validation, exception, journaux) : l'URL de l'en-tête `X-Debug-Token-Link`, ou
http://localhost:8000/_profiler. Pour afficher une variable : `dump($x);` (visible dans le profiler, onglet **Debug**) ;
`dd($x);` affiche et **arrête** tout. Les journaux du conteneur : `make logs s=api`. Une `500` : lisez `detail` et `class`
dans la réponse JSON, c'est souvent suffisant.

---

## À retenir

- Une requête traverse : **routeur** (`#[Route]` : chemin, méthodes, `requirements`) → **résolveurs d'arguments**
  (services, entité par id, `#[MapRequestPayload]`, `#[MapQueryParameter]`) → **votre action** → une `Response`.
  Beaucoup d'erreurs (`404`, `405`, `415`, `400`, `422`) sont produites avant votre code.
- L'**injection de dépendances** : on demande un service par son **type**, Symfony le construit et le fournit. Toute
  classe de `src/` est un service : un repository, un simulateur, ce que vous voulez.
- **Doctrine** : `persist()` prépare, `flush()` écrit ; une relation a un côté **propriétaire** (la clé étrangère) et un
  côté **inverse**. Le **repository** est l'endroit où vivent les requêtes ; le QueryBuilder prend le relais de `findBy()`.
- **Validator** → `422` + `violations` ; **Serializer** + **groupes** = liste blanche de ce qui entre et sort (pas de
  boucle, pas de fuite de `birthDate`) ; un **DTO** sépare le contrat de l'API du modèle de la base.
- Un **service** porte la logique métier, sans HTTP dedans ; le contrôleur traduit en codes et en JSON.
- Vous avez écrit à la main ce que **tout** framework d'API doit faire : routes CRUD, codes, `Location`, filtres,
  pagination, erreurs. Demain, un framework le fera pour vous, et vous saurez ce qu'il fait.

## Pour aller plus loin

- Contrôleurs et résolveurs d'arguments : https://symfony.com/doc/7.4/controller.html · Routage : https://symfony.com/doc/7.4/routing.html
- Doctrine (entités, repository, QueryBuilder, migrations) : https://symfony.com/doc/7.4/doctrine.html · Relations : https://symfony.com/doc/7.4/doctrine/associations.html
- Validation : https://symfony.com/doc/7.4/validation.html · Sérialisation : https://symfony.com/doc/7.4/serializer.html
- Le conteneur de services : https://symfony.com/doc/7.4/service_container.html · Le profiler : https://symfony.com/doc/7.4/profiler.html
- Les tests Hurl : https://hurl.dev/docs/ · OpenAPI avec Nelmio : https://symfony.com/bundles/NelmioApiDocBundle/current/index.html
