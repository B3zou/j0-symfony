# Antisèche Symfony 7.4 — les bases

> Documentation : https://symfony.com/doc/7.4/ (pages `routing`, `controller`, `doctrine`, `validation`, `serializer`, `service_container`).
> Les commandes Symfony passent par `make sf c="…"` : la console tourne **dans** le conteneur. Profiler : http://localhost:8000/_profiler

## Commandes `make` utiles

| Commande | Effet |
|---|---|
| `make up` · `make down` · `make ps` · `make sh` · `make cc` · `make logs s=api` | démarrer · arrêter · état · shell dans le conteneur · vider le cache · journaux |
| `make sf c="about"` · `make sf c="list"` · `make sf c="list make"` | versions et environnement · toutes les commandes · celles du maker |
| `make sf c="debug:router"` · `c="debug:router api_team_show"` | toutes les routes · le détail d'une route (requirements, format) |
| `make sf c="router:match /api/teams/abc"` | quelle route répond à cette URL, et pourquoi les autres non |
| `make sf c="make:controller PingController --no-template"` | génère un contrôleur (sans gabarit Twig) |
| `make sf c="make:entity Team"` | crée ou **complète** une entité et son repository (questions interactives) |
| `make db-update` | aligne les tables sur les entités (raccourci pédagogique ; en production : migrations) |
| `make sf c="dbal:run-sql 'SELECT * FROM team'"` · `c="doctrine:schema:validate"` | une requête SQL · mapping correct et base synchronisée ? |
| `make sf c="debug:autowiring Entity"` · `c="debug:container App\Service"` | les services injectables dont le type contient « Entity » · vos services |
| `make sf c="debug:serializer 'App\Entity\Team'"` · `c="debug:validator 'App\Entity\Team'"` | groupes · contraintes d'une classe |
| `make test` · `make test f=02` · `make test ERRORS=long` | tous les tests · un fichier · le détail des réponses en échec |

## Arborescence (`api/`)

```text
bin/console        config/packages/*.yaml, routes.yaml, services.yaml        public/index.php (contrôleur frontal)
src/ (App\) : Controller/  Entity/  Repository/  Dto/  Enum/  Service/      var/ (cache, logs)      vendor/ (Composer)      .env
```

## Cycle requête → réponse

```text
HTTP ─► public/index.php ─► Kernel ─► Routeur : quel #[Route] ?   (aucun : 404 · mauvaise méthode : 405 + Allow ; pages HTML)
          ─► Résolveurs d'arguments : services, Request, Team $team (404), #[MapRequestPayload] (415/400/422)…
          ─► Votre action : return JsonResponse / Response   (exception levée → réponse d'erreur, en JSON si format: 'json')
          ─► Réponse HTTP : statut, en-têtes, corps
```

## Routage : `#[Route]` (`use Symfony\Component\Routing\Attribute\Route;`)

```php
#[Route('/api/teams', name: 'api_team_', format: 'json')]      // sur la CLASSE : préfixes d'URL et de nom, erreurs en JSON
final class TeamController extends AbstractController
{
    #[Route('/{id}', name: 'show', methods: ['GET'], requirements: ['id' => Requirement::DIGITS])]
    public function show(Team $team): JsonResponse { … }        // → GET /api/teams/{id}, nom « api_team_show »
}
```

| Option | Rôle |
|---|---|
| `path` (1er argument) | chemin ; `{name}` = paramètre, passé à l'argument de même nom |
| `name` | nom unique (pour `generateUrl()`) ; deux routes de même nom : la dernière **remplace** l'autre, sans erreur |
| `methods` | `['GET']`, `['POST']`… ; absent = toutes les méthodes |
| `requirements` | regex par paramètre : `['name' => '[A-Za-z0-9_]{2,30}']`, `Requirement::DIGITS` (`[0-9]+`), `POSITIVE_INT`, `UUID`… (`use Symfony\Component\Routing\Requirement\Requirement;`) |
| `format` | format de la requête (`json`) : les pages d'erreur de cette route sortent en JSON |

Les routes sont essayées **dans l'ordre** de déclaration : une route `/{id}` sans `requirements` attrape `/top` ou `/search`.
Toute route sous `/api/` apparaît dans la Swagger UI (http://localhost:8000/api) ; `#[OA\…]` (`use OpenApi\Attributes as OA;`) permet d'y ajouter une description.

## Contrôleur : `AbstractController`

```php
return $this->json($data);                                     // 200, Content-Type: application/json (via le Serializer)
return $this->json($team, Response::HTTP_CREATED, ['Location' => $url], ['groups' => ['team:read']]);
return $this->json($team, context: ['groups' => ['team:read']]);       // argument nommé
$url = $this->generateUrl('api_team_show', ['id' => $team->getId()]); // "/api/teams/3" (chemin relatif)
throw $this->createNotFoundException('Équipe introuvable');           // 404
```
Signature : `json(mixed $data, int $status = 200, array $headers = [], array $context = []): JsonResponse`.

## Request et Response (`use Symfony\Component\HttpFoundation\…;`)

| Code | Rôle |
|---|---|
| `$request->query->get('q')` · `->getInt('page', 1)` · `->all()` | paramètres d'URL (`?q=…`) |
| `$request->getContent()` · `$request->toArray()` | corps brut · corps JSON décodé en tableau (illisible → `400`) |
| `$request->headers->get('Content-Type')` · `$request->getMethod()` | en-têtes · méthode |
| `new JsonResponse($data, 200, $headers)` · `new Response(null, Response::HTTP_NO_CONTENT)` | réponse JSON · `204` sans corps |
| `$response->headers->set('X-Total-Count', '42')` | ajouter un en-tête (valeur **chaîne**) |
| `Response::HTTP_OK` (200), `HTTP_CREATED` (201), `HTTP_NO_CONTENT` (204), `HTTP_BAD_REQUEST` (400), `HTTP_NOT_FOUND` (404), `HTTP_UNPROCESSABLE_ENTITY` (422) | constantes de statut |

## Injection de dépendances (autowiring)

```php
public function __construct(                                  // services pour toute la classe
    private readonly EntityManagerInterface $em,
    private readonly TeamRepository $teams,
    private readonly ValidatorInterface $validator,
) {}
public function list(TeamRepository $teams): JsonResponse     // ou en argument d'une action
```
- On **demande** un service par son **type**, Symfony le construit et le fournit. Jamais de `new` pour un service.
- `config/services.yaml` (`autowire: true`, `App\: resource: '../src/'`) : **toute** classe de `src/` est un service injectable, sans configuration.

## Un service, c'est une classe

```php
namespace App\Service;

final class MatchSimulator                                     // src/Service/MatchSimulator.php : rien d'autre à déclarer
{
    public function __construct(private readonly PlayerRepository $players) {}   // un service peut en recevoir d'autres

    public function simulate(Team $a, Team $b): MatchResult { … }                // de la logique métier, sans HTTP dedans
}
// Dans un contrôleur : public function versus(Team $team, Team $opponent, MatchSimulator $simulator) { … }
```
- Un service ne connaît ni `Request` ni `Response` : il reçoit des objets, renvoie des objets, lève des exceptions PHP. C'est le contrôleur qui traduit en HTTP.
- `make sf c="debug:container App\Service"` liste vos services ; `debug:autowiring Match` montre ce qu'on peut demander.

## Résolveurs d'arguments : ce que Symfony remplit avant votre action

| Argument | Rempli avec | Erreurs automatiques |
|---|---|---|
| `Team $team` + route `/{id}` | l'entité chargée par son id (**EntityValueResolver**) | absente → `404` ; paramètre pas nommé `{id}` → `500` (sinon `#[MapEntity(id: 'opponentId')] Team $opponent`) |
| `#[MapRequestPayload] PlayerInput $input` | le corps JSON, dénormalisé **puis validé** | mauvais `Content-Type` → `415` ; JSON illisible → `400` ; mauvais type ou contrainte → `422` |
| `#[MapRequestPayload(serializationContext: ['groups' => ['team:write']])] Team $team` | idem, en n'écrivant que les champs du groupe | idem |
| `#[MapQueryParameter] ?string $country = null` | `?country=FR` (absent → valeur par défaut) ; types `int`, `bool`, `string`, enum… | invalide → `404` par défaut |
| `#[MapQueryParameter(options: ['min_range' => 1, 'max_range' => 50], validationFailedStatusCode: Response::HTTP_BAD_REQUEST)] int $limit = 10` | `?limit=5`, entre 1 et 50 | `?limit=0`, `?limit=abc` → `400` |
| `Request $request`, un service | la requête, le service | |

(`use Symfony\Component\HttpKernel\Attribute\{MapRequestPayload, MapQueryParameter};` · `use Symfony\Bridge\Doctrine\Attribute\MapEntity;`)

## Doctrine : mapping (`use Doctrine\ORM\Mapping as ORM;`)

```php
#[ORM\Entity(repositoryClass: PlayerRepository::class)]     // la classe = une table
class Player
{
    #[ORM\Id] #[ORM\GeneratedValue] #[ORM\Column]
    private ?int $id = null;                                   // attribué par la base
    #[ORM\Column(length: 30, unique: true)]                    // VARCHAR(30) + index unique
    private ?string $nickname = null;
    #[ORM\Column(length: 30, nullable: true)]                  // NULL autorisé
    private ?string $role = null;
    #[ORM\Column]
    private int $rating = 1000;                                // valeur par défaut = valeur initiale PHP
    #[ORM\Column(type: Types::DATE_IMMUTABLE, nullable: true)] // use Doctrine\DBAL\Types\Types;
    private ?\DateTimeImmutable $birthDate = null;
    #[ORM\Column(enumType: Genre::class)]                      // enum PHP « backed », stocké par sa valeur
    private ?Genre $genre = null;
    #[ORM\ManyToOne(inversedBy: 'players')]                    // côté PROPRIÉTAIRE : la colonne team_id
    #[ORM\JoinColumn(onDelete: 'SET NULL')]                    // équipe supprimée → joueur sans équipe (ou 'CASCADE')
    private ?Team $team = null;
}
// Dans Team, côté INVERSE (initialisé dans __construct() : $this->players = new ArrayCollection();)
#[ORM\OneToMany(targetEntity: Player::class, mappedBy: 'team')]
#[ORM\OrderBy(['nickname' => 'ASC'])]
private Collection $players;
```

## Doctrine : lire et écrire

| Code | SQL / effet |
|---|---|
| `$repo->find(3)` | `WHERE id = 3` → objet ou `null` |
| `$repo->findAll()` | tout |
| `$repo->findBy(['country' => 'FR', 'team' => 3], ['nickname' => 'ASC'], 10, 20)` | critères (égalités, `AND`), tri, `LIMIT 10 OFFSET 20` |
| `$repo->findOneBy(['nickname' => 'Zer0Day'])` | un objet ou `null` |
| `$repo->count(['country' => 'FR'])` | `SELECT COUNT(*)` avec les mêmes critères |
| `$em->persist($player)` | « à enregistrer » (nouvel objet) — rien n'est encore écrit |
| `$em->remove($player)` | « à supprimer » |
| `$em->flush()` | **exécute** les `INSERT` / `UPDATE` / `DELETE` (un objet chargé et modifié n'a pas besoin de `persist()`) |

## Le QueryBuilder en six lignes

`findBy()` ne fait que des égalités reliées par `AND`. Dès qu'il faut un `LIKE`, un `OR`, une jointure ou un tri sur
un calcul, on écrit la requête dans le **repository**, avec le QueryBuilder (du SQL orienté objets : on nomme les
propriétés PHP, pas les colonnes).

```php
// Dans PlayerRepository
public function findTopRated(int $limit, ?string $country = null): array
{
    $qb = $this->createQueryBuilder('p')               // « p » : l'alias de Player dans la requête
        ->orderBy('p.rating', 'DESC')
        ->setMaxResults($limit);                        // LIMIT
    if (null !== $country) {
        $qb->andWhere('p.country = :country')           // un paramètre nommé…
           ->setParameter('country', $country);         // … toujours lié ainsi, jamais concaténé (injection SQL)
    }

    return $qb->getQuery()->getResult();                // Player[]
}
```
Autres briques : `->andWhere('LOWER(p.nickname) LIKE :q')->setParameter('q', '%'.mb_strtolower($q).'%')`,
`->leftJoin('p.team', 't')`, `->setFirstResult($offset)`, `->getQuery()->getOneOrNullResult()`,
`->select('COUNT(p.id)')->getQuery()->getSingleScalarResult()`. Pour paginer avec un total : `new Paginator($query)` (`Doctrine\ORM\Tools\Pagination\Paginator`), `count($paginator)`.

## Validator (`use Symfony\Component\Validator\Constraints as Assert;`)

| Contrainte | Exemple |
|---|---|
| `NotBlank` · `NotNull` | ni `null` ni `""` · pas `null` |
| `Length` · `Regex` | `#[Assert\Length(min: 2, max: 30)]` · `#[Assert\Regex('/^[A-Z0-9]{2,5}$/', message: '…')]` |
| `Range` · `Positive` · `PositiveOrZero` | `#[Assert\Range(min: 0, max: 3000)]` |
| `Choice` · `Country` · `Email` | `#[Assert\Choice(choices: [1, 3, 5])]` · code ISO `FR` |
| `LessThan` · `GreaterThan` | `#[Assert\LessThan('-13 years')]` (dates relatives acceptées) |
| `UniqueEntity` (sur la **classe**) | `#[UniqueEntity('nickname')]` — `use Symfony\Bridge\Doctrine\Validator\Constraints\UniqueEntity;` |

```php
$violations = $validator->validate($player);                 // ConstraintViolationListInterface
if (\count($violations) > 0) {
    throw new UnprocessableEntityHttpException((string) $violations, new ValidationFailedException($player, $violations));
}
```
Une violation « faite main » (pour un champ qui n'est pas sur l'entité, comme l'id d'une équipe inconnue) :
```php
new ConstraintViolationList([new ConstraintViolation('L\'équipe n°3 n\'existe pas.', null, [], $input, 'team', 3)]);
```

## Serializer

| Élément | Rôle |
|---|---|
| `#[Groups(['team:read', 'team:write'])]` (`use Symfony\Component\Serializer\Attribute\Groups;`) | le champ n'est lu/écrit que si l'un de ses groupes est demandé |
| `['groups' => ['team:read']]` | contexte : demande un groupe. **Sans** groupe demandé, **tous** les champs sont pris |
| `$serializer->deserialize($json, Team::class, 'json', $context)` | JSON → objet (erreur : `Symfony\Component\Serializer\Exception\ExceptionInterface`) |
| `AbstractNormalizer::OBJECT_TO_POPULATE => $team` | remplit un objet **existant** au lieu d'en créer un (PATCH) |
| `#[Ignore]` · `#[SerializedName('elo')]` | jamais sérialisé · autre nom en JSON |

Référence circulaire (`Team` → `players` → `team` → …) : `500` *A circular reference has been detected*. Remède : des **groupes** qui ne bouclent pas
(`Player::$team` sans `team:read`).

## Exceptions HTTP (`use Symfony\Component\HttpKernel\Exception\…;`)

| Exception | Statut |
|---|---|
| `BadRequestHttpException('…')` | `400` |
| `NotFoundHttpException` (ou `$this->createNotFoundException()`) | `404` |
| `MethodNotAllowedHttpException(['GET', 'PUT'])` | `405` + `Allow` |
| `ConflictHttpException` | `409` |
| `UnprocessableEntityHttpException('…', new ValidationFailedException($objet, $violations))` | `422` + `violations` |
| `HttpException(418, '…')` | n'importe quel code |

## Le format d'erreur obtenu (route avec `format: 'json'`)

```json
{
  "type": "https://symfony.com/errors/validation", "title": "Validation Failed", "status": 422,
  "detail": "name: This value should not be blank.",
  "violations": [{"propertyPath": "name", "title": "This value should not be blank.", "template": "…", "parameters": {…}, "type": "urn:uuid:…"}],
  "class": "Symfony\\Component\\HttpKernel\\Exception\\UnprocessableEntityHttpException", "trace": […]
}
```
Format *problem details* (RFC 9457), `Content-Type: application/json`. Autres erreurs : `"title": "An error occurred"`, `"status": 404`, `"detail": "…"`.
`class` et `trace` n'existent qu'en dev/test (en production, `detail` vaut juste `Not Found`…). Aucune route trouvée (`404`/`405`) : page **HTML**.

## Déboguer

- **Profiler** : l'URL de l'en-tête `X-Debug-Token-Link` d'une réponse (onglets Request/Response, Doctrine, Validator, Serializer, Logs, Exception, Debug), ou http://localhost:8000/_profiler.
- `dump($x);` → onglet **Debug** du profiler (la réponse JSON n'est pas modifiée) · `dd($x);` → affiche et **arrête** (page HTML, `500`).
- `make sf c="router:match /api/…"` (routage) · `make sf c="debug:serializer 'App\Entity\Player'"` (groupes) · `make sf c="doctrine:schema:validate"` (mapping).
- Une `500` : lisez `detail` et `class` dans la réponse. Un changement « sans effet » : relancez la requête (PHP garde un fichier ~2 s), sinon `make cc`.
