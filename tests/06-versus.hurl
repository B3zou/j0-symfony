# ─────────────────────────────────────────────────────────────────────────────
# J0 · TP étape 7 — Un service : le simulateur de match
# Attendu : GET /api/teams/{id}/versus/{opponentId}[?seed=42]
#           → un match au meilleur des 5 manches, tiré au sort selon le niveau des équipes.
#           Rien n'est enregistré en base.
# ─────────────────────────────────────────────────────────────────────────────

POST {{host}}/api/teams
Content-Type: application/json
{ "name": "Versus Alpha", "tag": "VSA", "country": "FR" }
HTTP 201
[Captures]
vsa_id: jsonpath "$.id"

POST {{host}}/api/teams
Content-Type: application/json
{ "name": "Versus Beta", "tag": "VSB", "country": "DE" }
HTTP 201
[Captures]
vsb_id: jsonpath "$.id"

POST {{host}}/api/teams
Content-Type: application/json
{ "name": "Versus Empty", "tag": "VSE", "country": "IT" }
HTTP 201
[Captures]
vse_id: jsonpath "$.id"

POST {{host}}/api/players
Content-Type: application/json
{ "nickname": "Vs_One", "country": "FR", "rating": 2000, "team": {{vsa_id}} }
HTTP 201

POST {{host}}/api/players
Content-Type: application/json
{ "nickname": "Vs_Two", "country": "FR", "rating": 1800, "team": {{vsa_id}} }
HTTP 201

POST {{host}}/api/players
Content-Type: application/json
{ "nickname": "Vs_Three", "country": "DE", "rating": 1500, "team": {{vsb_id}} }
HTTP 201

# Un match : les deux équipes (avec leur niveau moyen), le score, le gagnant, le détail des manches
GET {{host}}/api/teams/{{vsa_id}}/versus/{{vsb_id}}
HTTP 200
[Asserts]
header "Content-Type" contains "application/json"
jsonpath "$.teamA.tag" == "VSA"
jsonpath "$.teamA.name" == "Versus Alpha"
jsonpath "$.teamA.rating" == 1900
jsonpath "$.teamB.tag" == "VSB"
jsonpath "$.teamB.rating" == 1500
jsonpath "$.winner" matches "^(VSA|VSB)$"
jsonpath "$.score" count == 2
jsonpath "$.score" contains 3
jsonpath "$.score[0]" <= 3
jsonpath "$.score[1]" <= 3
jsonpath "$.rounds" count >= 3
jsonpath "$.rounds" count <= 5
jsonpath "$.rounds[0]" matches "^(VSA|VSB)$"

# Avec une graine (seed), le tirage est reproductible : deux appels, même résultat
GET {{host}}/api/teams/{{vsa_id}}/versus/{{vsb_id}}?seed=42
HTTP 200
[Captures]
winner1: jsonpath "$.winner"
rounds1: jsonpath "$.rounds" count

GET {{host}}/api/teams/{{vsa_id}}/versus/{{vsb_id}}?seed=42
HTTP 200
[Asserts]
jsonpath "$.winner" == "{{winner1}}"
jsonpath "$.rounds" count == {{rounds1}}

# Une équipe ne joue pas contre elle-même
GET {{host}}/api/teams/{{vsa_id}}/versus/{{vsa_id}}
HTTP 422
[Asserts]
jsonpath "$.violations[*].propertyPath" contains "opponentId"

# Une équipe sans joueur n'a pas de niveau : impossible de simuler
GET {{host}}/api/teams/{{vsa_id}}/versus/{{vse_id}}
HTTP 422
[Asserts]
jsonpath "$.violations[*].propertyPath" contains "opponentId"

GET {{host}}/api/teams/{{vse_id}}/versus/{{vsa_id}}
HTTP 422
[Asserts]
jsonpath "$.violations[*].propertyPath" contains "id"

# Équipe inconnue → 404 en JSON ; identifiant non numérique → aucune route → 404
GET {{host}}/api/teams/{{vsa_id}}/versus/999999
HTTP 404
[Asserts]
header "Content-Type" contains "json"

GET {{host}}/api/teams/999999/versus/{{vsb_id}}
HTTP 404

GET {{host}}/api/teams/{{vsa_id}}/versus/abc
HTTP 404
