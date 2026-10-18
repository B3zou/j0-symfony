# ─────────────────────────────────────────────────────────────────────────────
# J0 · TD étape 1 — Premier contrôleur : routes, paramètres, méthodes HTTP
# Attendu : src/Controller/PingController.php
# ─────────────────────────────────────────────────────────────────────────────

GET {{host}}/api/ping
HTTP 200
[Asserts]
header "Content-Type" contains "application/json"
jsonpath "$.status" == "ok"
jsonpath "$.league" == "GG League"

# Paramètre de route
GET {{host}}/api/hello/Zer0Day
HTTP 200
[Asserts]
jsonpath "$.message" == "GG Zer0Day !"

GET {{host}}/api/hello/Null_Pointer42
HTTP 200
[Asserts]
jsonpath "$.message" == "GG Null_Pointer42 !"

# Contrainte sur le paramètre : 2 à 30 caractères (lettres, chiffres, _) → sinon 404
GET {{host}}/api/hello/x
HTTP 404

GET {{host}}/api/hello/pas-de-tiret
HTTP 404

# La route n'accepte que GET
POST {{host}}/api/ping
HTTP 405
