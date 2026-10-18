# Antisèche HTTP et REST

> Référence : MDN https://developer.mozilla.org/fr/docs/Web/HTTP · Sémantique HTTP : RFC 9110 · Tests : https://hurl.dev/docs/

## Anatomie d'un échange

```http
PATCH /api/teams/3 HTTP/1.1                        ← ligne de requête : méthode, cible (chemin + query), version
Host: localhost:8000                               ← en-têtes
Content-Type: application/json
Accept: application/json
                                                   ← ligne vide
{"country": "BE"}                                  ← corps (facultatif)
```
```http
HTTP/1.1 200 OK                                    ← ligne de statut : version, code, raison
Content-Type: application/json

{"id": 3, "name": "Lag Busters", "tag": "LAG", "country": "BE", "players": []}
```

URL : `http://localhost:8000/api/players?team=1&page=2` = schéma `http` · hôte `localhost` · port `8000` · chemin `/api/players` · query `team=1&page=2`.

## Méthodes

| Méthode | Rôle | Sûre | Idempotente | Corps de requête | Succès typique |
|---|---|---|---|---|---|
| `GET` | lire | ✔ | ✔ | non | `200` |
| `HEAD` | comme GET, sans corps de réponse | ✔ | ✔ | non | `200` |
| `OPTIONS` | méthodes permises, *preflight* CORS | ✔ | ✔ | non | `200` / `204` |
| `POST` | créer (dans une collection) ou action | ✘ | ✘ | oui | `201` + `Location` |
| `PUT` | **remplacer** entièrement | ✘ | ✔ | oui | `200` / `204` (`201` si créé) |
| `PATCH` | modifier **partiellement** | ✘ | ✘ (par définition) | oui | `200` |
| `DELETE` | supprimer | ✘ | ✔ | non | `204` |

**Sûre** = ne modifie pas l'état du serveur. **Idempotente** = N appels identiques laissent le serveur dans le même état qu'un seul (la réponse peut différer :
`DELETE` → `204` puis `404`). Une requête idempotente peut être **rejouée** sans risque après un timeout.

## Codes de statut utiles

| Code | Nom | Quand ? |
|---|---|---|
| `200` | OK | lecture, modification réussie |
| `201` | Created | création (`POST`) ; en-tête `Location` = URI de la nouvelle ressource |
| `204` | No Content | succès sans corps (`DELETE`) |
| `304` | Not Modified | réponse en cache encore valable (`If-None-Match` / `ETag`) |
| `400` | Bad Request | requête **illisible** (JSON cassé, paramètre mal formé) |
| `401` | Unauthorized | **non authentifié** (pas ou mauvais jeton) |
| `403` | Forbidden | authentifié, mais **pas le droit** |
| `404` | Not Found | ressource ou URI inexistante |
| `405` | Method Not Allowed | URI connue, méthode refusée ; en-tête `Allow` obligatoire |
| `409` | Conflict | conflit d'état (version concurrente, doublon métier) |
| `415` | Unsupported Media Type | impossible de **lire** le format envoyé (`Content-Type`) |
| `422` | Unprocessable Content | requête lisible mais **invalide** (règles de validation) |
| `429` | Too Many Requests | limite de débit atteinte ; `Retry-After` |
| `500` | Internal Server Error | bug côté serveur : jamais « normal » |
| `502` / `503` / `504` | Bad Gateway / Service Unavailable / Gateway Timeout | problème d'infrastructure ou de dépendance |

Familles : `1xx` info · `2xx` succès · `3xx` redirection · `4xx` faute du **client** · `5xx` faute du **serveur**. Jamais d'erreur dans un `200` !

## En-têtes utiles

| En-tête | Sens | Exemple |
|---|---|---|
| `Accept` | formats de réponse **souhaités** (négociation) | `Accept: application/json` |
| `Content-Type` | format du **corps envoyé** | `Content-Type: application/json` |
| `Location` | URI de la ressource créée (`201`) ou de la redirection (`3xx`) | `Location: /api/teams/9` |
| `Allow` | méthodes permises sur l'URI (`405`, `OPTIONS`) | `Allow: GET, PATCH, DELETE` |
| `X-Total-Count` | (convention, pas un standard) nombre total d'éléments d'une collection paginée | `X-Total-Count: 42` |
| `Link` | liens typés vers d'autres pages ou ressources (RFC 8288) | `Link: </api/players?page=3>; rel="next"` |
| `Authorization` | identifiants du client | `Authorization: Bearer eyJhbGciOi…` |
| `Cache-Control` | règles de cache | `Cache-Control: public, max-age=60` |
| `ETag` / `If-None-Match` | empreinte d'une représentation / « renvoie-la seulement si elle a changé » | `ETag: "a5d7c9cc79415733"` → `304` |
| `Retry-After` | délai avant de réessayer (`429`, `503`) | `Retry-After: 30` |

## Règles de nommage REST

- Des **noms**, au **pluriel**, en minuscules (`kebab-case` si plusieurs mots) : `/api/teams`, `/api/teams/1`, `/api/prize-pools`.
- La **méthode** est le verbe : ✘ `/getTeams`, `/createPlayer`, `/players/delete?id=3` → ✔ `GET /api/teams`, `POST /api/players`, `DELETE /api/players/3`.
- L'**identifiant** dans le chemin, les **filtres**, le tri et la pagination dans la query : `/api/players?team=1&country=FR&page=2`.
- Une hiérarchie **courte** : `/api/teams/1/players` oui ; `/api/leagues/1/teams/3/players/4/stats` non (préférez un filtre).
- Des erreurs **codées** (`404`, `422`) avec un corps structuré (*problem details*, RFC 9457).
- Une **action** qui n'est pas du CRUD (`/api/teams/1/versus/2`) est possible ; c'est déjà un appel de procédure déguisé : assumez-le, et on en reparlera.

## curl

| Option | Effet |
|---|---|
| `-i` | affiche statut et en-têtes de la réponse (**toujours**) |
| `-I` | requête `HEAD` (en-têtes seulement) |
| `-v` | tout : requête envoyée, en-têtes |
| `-X PATCH` | méthode (inutile pour GET, implicite en POST avec `-d`) |
| `-H 'Content-Type: application/json'` | ajoute un en-tête (répétable) |
| `-d '{"name": "x"}'` / `-d @team.json` | corps littéral / corps lu dans un fichier |
| `-s` | silencieux (pas de barre de progression) |
| `-o /dev/null -w '%{http_code}\n'` | n'affiche que le code de statut |
| `\| jq` · `\| jq '.[].name'` | met en forme / extrait du JSON (`sudo apt install jq`) |

```bash
API=http://localhost:8000
curl -i -X POST $API/api/teams -H 'Content-Type: application/json' -d '{"name": "Async Await", "tag": "ASY", "country": "FR"}'
curl -i -X PATCH $API/api/teams/9 -H 'Content-Type: application/json' -d '{"country": "BE"}'
curl -s "$API/api/players?country=FR&page=2" | jq '.[].nickname'
```

## Lire un test Hurl (les tests du cours)

Un fichier `.hurl` est une suite d'**entrées**. Chaque entrée décrit une requête, puis la réponse attendue. Hurl envoie
la requête, compare, et passe à la suivante ; à la première assertion fausse, le fichier est en échec et Hurl montre la
ligne fautive, la valeur attendue et la valeur reçue.

```hurl
# Une entrée = une requête + la réponse attendue
POST {{host}}/api/teams                       # ① la requête : méthode, URL ({{host}} est une variable), en-têtes, corps
Content-Type: application/json
{
  "name": "Test Null Pointers",
  "tag": "TNP",
  "country": "FR"
}
HTTP 201                                      # ② le statut attendu (sinon : échec immédiat)
[Captures]                                    # ③ on mémorise une valeur de la réponse pour la suite
team_url: header "Location"
[Asserts]                                     # ④ chaque ligne doit être vraie
header "Location" matches "^/api/teams/\\d+$"
jsonpath "$.tag" == "TNP"
jsonpath "$.players" count == 0
jsonpath "$.birthDate" not exists

GET {{host}}{{team_url}}                      # entrée suivante : la variable capturée est réutilisée
HTTP 200
```

- Les prédicats que vous croiserez : `==`, `!=`, `<=`, `contains`, `matches` (expression régulière), `exists`, `not exists`, `isInteger`, `isCollection`, `count`.
- `jsonpath "$.team.tag"` descend dans le JSON ; `$[0]` est le premier élément d'un tableau ; `$[*].nickname` tous les pseudos.
- `make test` lance tous les fichiers de `tests/`, dans l'ordre, sur une base de test vide ; `make test f=02` un seul.
- En échec, lisez `--> 02-teams.hurl:42:6` (fichier, ligne) et `actual value is <…>`. Pour voir la réponse HTTP complète : `make test ERRORS=long`.
