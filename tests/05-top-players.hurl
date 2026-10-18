# ─────────────────────────────────────────────────────────────────────────────
# J0 · TP étape 6 — Une méthode de repository écrite avec le QueryBuilder
# Attendu : GET /api/players/top?limit=3&country=IS  (classement décroissant par rating,
#           limit entre 1 et 50, 10 par défaut, 400 sinon)
#           GET /api/players?q=top_                     (recherche insensible à la casse dans le pseudo)
# ─────────────────────────────────────────────────────────────────────────────

POST {{host}}/api/teams
Content-Type: application/json
{
  "name": "Top Reykjavik",
  "tag": "TRK",
  "country": "IS"
}
HTTP 201
[Captures]
trk_id: jsonpath "$.id"

POST {{host}}/api/teams
Content-Type: application/json
{
  "name": "Top Wellington",
  "tag": "TWL",
  "country": "NZ"
}
HTTP 201
[Captures]
twl_id: jsonpath "$.id"

POST {{host}}/api/players
Content-Type: application/json
{ "nickname": "Top_Delta", "country": "IS", "rating": 2990, "team": {{trk_id}} }
HTTP 201

POST {{host}}/api/players
Content-Type: application/json
{ "nickname": "Top_Foxtrot", "country": "NZ", "rating": 2980 }
HTTP 201

POST {{host}}/api/players
Content-Type: application/json
{ "nickname": "Top_Alpha", "country": "IS", "rating": 2970, "team": {{trk_id}} }
HTTP 201

POST {{host}}/api/players
Content-Type: application/json
{ "nickname": "Top_Bravo", "country": "NZ", "rating": 2960, "team": {{twl_id}} }
HTTP 201

POST {{host}}/api/players
Content-Type: application/json
{ "nickname": "Top_Charlie", "country": "IS", "rating": 2950 }
HTTP 201

POST {{host}}/api/players
Content-Type: application/json
{ "nickname": "Top_Echo", "country": "NZ", "rating": 1005, "team": {{twl_id}} }
HTTP 201

# Les 3 meilleurs, toutes équipes confondues, du plus fort au moins fort
GET {{host}}/api/players/top?limit=3
HTTP 200
[Asserts]
jsonpath "$" count == 3
jsonpath "$[0].nickname" == "Top_Delta"
jsonpath "$[1].nickname" == "Top_Foxtrot"
jsonpath "$[2].nickname" == "Top_Alpha"
jsonpath "$[0].rating" == 2990
# Même représentation qu'ailleurs : l'équipe imbriquée, jamais la date de naissance
jsonpath "$[0].team.tag" == "TRK"
jsonpath "$[0].birthDate" not exists

# Filtre par pays (limite par défaut : 10)
GET {{host}}/api/players/top?country=IS
HTTP 200
[Asserts]
jsonpath "$" count == 3
jsonpath "$[0].nickname" == "Top_Delta"
jsonpath "$[1].nickname" == "Top_Alpha"
jsonpath "$[2].nickname" == "Top_Charlie"

# Le pays est accepté en minuscules
GET {{host}}/api/players/top?country=nz&limit=1
HTTP 200
[Asserts]
jsonpath "$" count == 1
jsonpath "$[0].nickname" == "Top_Foxtrot"

# limit doit être un entier entre 1 et 50
GET {{host}}/api/players/top?limit=0
HTTP 400

GET {{host}}/api/players/top?limit=abc
HTTP 400

GET {{host}}/api/players/top?limit=51
HTTP 400

# Recherche dans le pseudo, insensible à la casse ; la pagination s'applique toujours
GET {{host}}/api/players?q=top_
HTTP 200
[Asserts]
header "X-Total-Count" == "6"
jsonpath "$" count == 6

GET {{host}}/api/players?q=ECHO
HTTP 200
[Asserts]
jsonpath "$" count == 1
jsonpath "$[0].nickname" == "Top_Echo"

# La recherche se combine aux autres filtres
GET {{host}}/api/players?q=top_&country=NZ
HTTP 200
[Asserts]
jsonpath "$" count == 3
