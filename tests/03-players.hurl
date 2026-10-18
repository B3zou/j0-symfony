# ─────────────────────────────────────────────────────────────────────────────
# J0 · TP étape 3 — Player : relation avec Team, DTO d'entrée, PUT
# Attendu : GET/POST /api/players, GET/PUT/DELETE /api/players/{id}, filtre ?team=
# ─────────────────────────────────────────────────────────────────────────────

POST {{host}}/api/teams
Content-Type: application/json
{
  "name": "Test Kernel Panic",
  "tag": "TKP",
  "country": "FR"
}
HTTP 201
[Captures]
team_id: jsonpath "$.id"
team_url: header "Location"

# L'équipe est désignée par son identifiant
POST {{host}}/api/players
Content-Type: application/json
{
  "nickname": "Test_Zer0Day",
  "country": "FR",
  "role": "striker",
  "rating": 1850,
  "birthDate": "2002-04-12",
  "team": {{team_id}}
}
HTTP 201
[Captures]
player_url: header "Location"
[Asserts]
header "Location" matches "^/api/players/\\d+$"
jsonpath "$.id" isInteger
jsonpath "$.nickname" == "Test_Zer0Day"
jsonpath "$.rating" == 1850
# L'équipe est renvoyée IMBRIQUÉE, réduite à son nom et son tag
jsonpath "$.team.name" == "Test Kernel Panic"
jsonpath "$.team.tag" == "TKP"
jsonpath "$.team.country" not exists
jsonpath "$.team.players" not exists
# Donnée personnelle : acceptée en écriture, jamais renvoyée
jsonpath "$.birthDate" not exists

GET {{host}}{{player_url}}
HTTP 200
[Asserts]
jsonpath "$.birthDate" not exists
jsonpath "$.team.tag" == "TKP"

# Côté équipe, les joueurs apparaissent (pseudo, rôle, classement)
GET {{host}}{{team_url}}
HTTP 200
[Asserts]
jsonpath "$.players" count == 1
jsonpath "$.players[0].nickname" == "Test_Zer0Day"
jsonpath "$.players[0].rating" == 1850
jsonpath "$.players[0].team" not exists

# Valeur par défaut du classement : 1000
POST {{host}}/api/players
Content-Type: application/json
{
  "nickname": "Test_Mutex",
  "country": "BE",
  "team": {{team_id}}
}
HTTP 201
[Asserts]
jsonpath "$.rating" == 1000

# Agent libre : pas d'équipe
POST {{host}}/api/players
Content-Type: application/json
{
  "nickname": "Test_FreeAgent",
  "country": "CA",
  "rating": 2100
}
HTTP 201
[Asserts]
jsonpath "$.team" == null

# Équipe inexistante → 422 sur le champ « team »
POST {{host}}/api/players
Content-Type: application/json
{
  "nickname": "Test_Ghost",
  "country": "FR",
  "team": 999999
}
HTTP 422
[Asserts]
jsonpath "$.violations[*].propertyPath" contains "team"

# Mauvais type → 422
POST {{host}}/api/players
Content-Type: application/json
{
  "nickname": "Test_Typo",
  "country": "FR",
  "rating": "beaucoup"
}
HTTP 422
[Asserts]
jsonpath "$.violations[*].propertyPath" contains "rating"

# Règles de l'entité : classement 0..3000, au moins 13 ans
POST {{host}}/api/players
Content-Type: application/json
{
  "nickname": "Test_Kid",
  "country": "FR",
  "rating": 5000,
  "birthDate": "2020-01-01"
}
HTTP 422
[Asserts]
jsonpath "$.violations[*].propertyPath" contains "rating"
jsonpath "$.violations[*].propertyPath" contains "birthDate"

# Pseudo unique
POST {{host}}/api/players
Content-Type: application/json
{
  "nickname": "Test_Zer0Day",
  "country": "FR"
}
HTTP 422
[Asserts]
jsonpath "$.violations[*].propertyPath" contains "nickname"

# Filtre par équipe
GET {{host}}/api/players?team={{team_id}}
HTTP 200
[Asserts]
jsonpath "$" count == 2
jsonpath "$[*].nickname" contains "Test_Mutex"
jsonpath "$[*].nickname" not contains "Test_FreeAgent"

# PUT = remplacement COMPLET : sans « team », le joueur devient agent libre
PUT {{host}}{{player_url}}
Content-Type: application/json
{
  "nickname": "Test_Zer0Day",
  "country": "FR",
  "role": "playmaker",
  "rating": 1900
}
HTTP 200
[Asserts]
jsonpath "$.role" == "playmaker"
jsonpath "$.rating" == 1900
jsonpath "$.team" == null

GET {{host}}{{team_url}}
HTTP 200
[Asserts]
jsonpath "$.players" count == 1

# Suppression
DELETE {{host}}{{player_url}}
HTTP 204

GET {{host}}{{player_url}}
HTTP 404
