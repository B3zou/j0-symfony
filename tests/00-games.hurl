# ─────────────────────────────────────────────────────────────────────────────
# J0 · Exemple fourni — l'API « faite main » des jeux (src/Controller/GameController.php)
# Ce fichier doit être VERT dès le début : il vérifie votre environnement et montre
# ce qu'on attend d'une API REST. Lancer : make test
# ─────────────────────────────────────────────────────────────────────────────
# Création → 201 Created + en-tête Location vers la nouvelle ressource
POST {{host}}/api/games
Content-Type: application/json
{
  "name": "Test Game Alpha",
  "genre": "sports",
  "teamSize": 3,
  "id": 424242
}
HTTP 201
[Captures]
game_url: header "Location"
game_id: jsonpath "$.id"
[Asserts]
header "Location" matches "^/api/games/\\d+$"
header "Content-Type" contains "application/json"
jsonpath "$.name" == "Test Game Alpha"
jsonpath "$.genre" == "sports"
jsonpath "$.teamSize" == 3
# l'id est choisi par la base, jamais par le client
jsonpath "$.id" != 424242

# Lecture d'un élément
GET {{host}}{{game_url}}
HTTP 200
[Asserts]
jsonpath "$.id" == {{game_id}}
jsonpath "$.name" == "Test Game Alpha"

# Collection : un tableau JSON
GET {{host}}/api/games
HTTP 200
[Asserts]
jsonpath "$" isCollection
jsonpath "$[*].name" contains "Test Game Alpha"

# Mise à jour partielle (PATCH) : seuls les champs envoyés changent
PATCH {{host}}{{game_url}}
Content-Type: application/json
{
  "teamSize": 2
}
HTTP 200
[Asserts]
jsonpath "$.teamSize" == 2
jsonpath "$.name" == "Test Game Alpha"

# Validation → 422 avec la liste des violations
POST {{host}}/api/games
Content-Type: application/json
{
  "name": "",
  "genre": "fps",
  "teamSize": 42
}
HTTP 422
[Asserts]
jsonpath "$.violations[*].propertyPath" contains "name"
jsonpath "$.violations[*].propertyPath" contains "teamSize"

# Mauvais type (genre inconnu) → 422 aussi
POST {{host}}/api/games
Content-Type: application/json
{
  "name": "Test Game Beta",
  "genre": "jeu-de-l-oie",
  "teamSize": 2
}
HTTP 422
[Asserts]
jsonpath "$.violations[0].propertyPath" == "genre"

# Unicité du nom → 422
POST {{host}}/api/games
Content-Type: application/json
{
  "name": "Test Game Alpha",
  "genre": "sports",
  "teamSize": 3
}
HTTP 422
[Asserts]
jsonpath "$.violations[0].propertyPath" == "name"

# PATCH invalide → 422, et rien n'est enregistré
PATCH {{host}}{{game_url}}
Content-Type: application/json
{
  "teamSize": 99
}
HTTP 422

GET {{host}}{{game_url}}
HTTP 200
[Asserts]
jsonpath "$.teamSize" == 2

# Mauvais type de contenu → 415 Unsupported Media Type
POST {{host}}/api/games
Content-Type: text/plain
```
name=Oops
```
HTTP 415

# JSON illisible → 400 Bad Request
POST {{host}}/api/games
Content-Type: application/json
```
{"name": "Oops",
```
HTTP 400

# Ressource inexistante → 404... en JSON (format: 'json' sur la route)
GET {{host}}/api/games/999999
HTTP 404
[Asserts]
header "Content-Type" contains "json"

# L'id doit être un nombre : aucune route ne correspond → 404
GET {{host}}/api/games/abc
HTTP 404

# Méthode non prévue → 405 Method Not Allowed
PUT {{host}}{{game_url}}
Content-Type: application/json
{}
HTTP 405

# Suppression → 204 No Content, puis 404
DELETE {{host}}{{game_url}}
HTTP 204
[Asserts]
bytes count == 0

GET {{host}}{{game_url}}
HTTP 404
