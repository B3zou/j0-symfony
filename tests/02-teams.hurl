# ─────────────────────────────────────────────────────────────────────────────
# J0 · TP étapes 1 et 2 — Entité Team + TeamController (CRUD complet)
# Attendu : GET/POST /api/teams, GET/PATCH/DELETE /api/teams/{id}, filtre ?country=
# ─────────────────────────────────────────────────────────────────────────────

POST {{host}}/api/teams
Content-Type: application/json
{
  "name": "Test Null Pointers",
  "tag": "TNP",
  "country": "FR"
}
HTTP 201
[Captures]
team_url: header "Location"
[Asserts]
header "Location" matches "^/api/teams/\\d+$"
jsonpath "$.id" isInteger
jsonpath "$.name" == "Test Null Pointers"
jsonpath "$.tag" == "TNP"
jsonpath "$.country" == "FR"
jsonpath "$.players" count == 0

GET {{host}}{{team_url}}
HTTP 200
[Asserts]
jsonpath "$.tag" == "TNP"

# Le tag doit respecter /^[A-Z0-9]{2,5}$/
POST {{host}}/api/teams
Content-Type: application/json
{
  "name": "Test Bad Tag",
  "tag": "bad!",
  "country": "FR"
}
HTTP 422
[Asserts]
jsonpath "$.violations[*].propertyPath" contains "tag"

# Le pays doit être un code ISO 3166-1 alpha-2 valide
POST {{host}}/api/teams
Content-Type: application/json
{
  "name": "Test Bad Country",
  "tag": "TBC",
  "country": "XX"
}
HTTP 422
[Asserts]
jsonpath "$.violations[*].propertyPath" contains "country"

# Nom unique
POST {{host}}/api/teams
Content-Type: application/json
{
  "name": "Test Null Pointers",
  "tag": "TNQ",
  "country": "FR"
}
HTTP 422
[Asserts]
jsonpath "$.violations[*].propertyPath" contains "name"

# Tag unique
POST {{host}}/api/teams
Content-Type: application/json
{
  "name": "Test Other Team",
  "tag": "TNP",
  "country": "BE"
}
HTTP 422
[Asserts]
jsonpath "$.violations[*].propertyPath" contains "tag"

# Champs obligatoires
POST {{host}}/api/teams
Content-Type: application/json
{}
HTTP 422
[Asserts]
jsonpath "$.violations[*].propertyPath" contains "name"
jsonpath "$.violations[*].propertyPath" contains "tag"
jsonpath "$.violations[*].propertyPath" contains "country"

# Un id envoyé par le client est ignoré
POST {{host}}/api/teams
Content-Type: application/json
{
  "id": 424242,
  "name": "Test Lag Busters",
  "tag": "TLB",
  "country": "BE"
}
HTTP 201
[Captures]
team2_url: header "Location"
[Asserts]
jsonpath "$.id" != 424242

POST {{host}}/api/teams
Content-Type: application/json
{
  "name": "Test Async Await",
  "tag": "TAA",
  "country": "BE"
}
HTTP 201

# Filtre sur le pays + tri par nom
GET {{host}}/api/teams?country=BE
HTTP 200
[Asserts]
jsonpath "$" count == 2
jsonpath "$[0].tag" == "TAA"
jsonpath "$[1].tag" == "TLB"
jsonpath "$[*].tag" not contains "TNP"

# Mise à jour partielle
PATCH {{host}}{{team2_url}}
Content-Type: application/json
{
  "country": "CH"
}
HTTP 200
[Asserts]
jsonpath "$.country" == "CH"
jsonpath "$.tag" == "TLB"

PATCH {{host}}{{team2_url}}
Content-Type: application/json
{
  "tag": "trop-long"
}
HTTP 422
[Asserts]
jsonpath "$.violations[*].propertyPath" contains "tag"

# Erreurs en JSON
GET {{host}}/api/teams/999999
HTTP 404
[Asserts]
header "Content-Type" contains "json"

# Suppression
DELETE {{host}}{{team2_url}}
HTTP 204

GET {{host}}{{team2_url}}
HTTP 404
