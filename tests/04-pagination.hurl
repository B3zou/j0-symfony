# ─────────────────────────────────────────────────────────────────────────────
# J0 · TP étape 4 — Pagination de /api/players
# Attendu : 10 joueurs par page (?page=1, 2...), total dans l'en-tête X-Total-Count,
#           400 Bad Request si « page » n'est pas un entier ≥ 1.
# ─────────────────────────────────────────────────────────────────────────────

POST {{host}}/api/players
Content-Type: application/json
{
  "nickname": "Test_Bot01",
  "country": "JP",
  "rating": 1010
}
HTTP 201

POST {{host}}/api/players
Content-Type: application/json
{
  "nickname": "Test_Bot02",
  "country": "JP",
  "rating": 1020
}
HTTP 201

POST {{host}}/api/players
Content-Type: application/json
{
  "nickname": "Test_Bot03",
  "country": "JP",
  "rating": 1030
}
HTTP 201

POST {{host}}/api/players
Content-Type: application/json
{
  "nickname": "Test_Bot04",
  "country": "JP",
  "rating": 1040
}
HTTP 201

POST {{host}}/api/players
Content-Type: application/json
{
  "nickname": "Test_Bot05",
  "country": "JP",
  "rating": 1050
}
HTTP 201

POST {{host}}/api/players
Content-Type: application/json
{
  "nickname": "Test_Bot06",
  "country": "JP",
  "rating": 1060
}
HTTP 201

POST {{host}}/api/players
Content-Type: application/json
{
  "nickname": "Test_Bot07",
  "country": "JP",
  "rating": 1070
}
HTTP 201

POST {{host}}/api/players
Content-Type: application/json
{
  "nickname": "Test_Bot08",
  "country": "JP",
  "rating": 1080
}
HTTP 201

POST {{host}}/api/players
Content-Type: application/json
{
  "nickname": "Test_Bot09",
  "country": "JP",
  "rating": 1090
}
HTTP 201

POST {{host}}/api/players
Content-Type: application/json
{
  "nickname": "Test_Bot10",
  "country": "JP",
  "rating": 1100
}
HTTP 201

POST {{host}}/api/players
Content-Type: application/json
{
  "nickname": "Test_Bot11",
  "country": "JP",
  "rating": 1110
}
HTTP 201

POST {{host}}/api/players
Content-Type: application/json
{
  "nickname": "Test_Bot12",
  "country": "JP",
  "rating": 1120
}
HTTP 201

# Page 1 (par défaut) : 10 joueurs, triés par pseudo ; le total est dans l'en-tête
GET {{host}}/api/players?country=JP
HTTP 200
[Asserts]
header "X-Total-Count" == "12"
jsonpath "$" count == 10
jsonpath "$[0].nickname" == "Test_Bot01"

# Page 2 : les 2 derniers
GET {{host}}/api/players?country=JP&page=2
HTTP 200
[Asserts]
header "X-Total-Count" == "12"
jsonpath "$" count == 2
jsonpath "$[0].nickname" == "Test_Bot11"

# Au-delà de la dernière page : liste vide (ce n'est pas une erreur)
GET {{host}}/api/players?country=JP&page=3
HTTP 200
[Asserts]
jsonpath "$" count == 0

# Numéro de page invalide → 400 Bad Request
GET {{host}}/api/players?page=0
HTTP 400

GET {{host}}/api/players?page=abc
HTTP 400
