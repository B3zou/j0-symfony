#!/bin/sh
# Préparation de l'API au démarrage du conteneur.
set -e

if [ "$1" = 'frankenphp' ] || [ "$1" = 'php' ] || [ "$1" = 'bin/console' ]; then
	# 1. Dépendances PHP : au premier démarrage, ou si composer.lock a changé
	if [ "${INSTALL_DEPS:-1}" = "1" ]; then
		if [ ! -f vendor/autoload_runtime.php ] || [ composer.lock -nt vendor/.installed ]; then
			echo "Installation des dépendances PHP (composer install)..."
			composer install --prefer-dist --no-progress --no-interaction
			touch vendor/.installed
		fi
	else
		# api-test : on attend que le conteneur api ait installé les dépendances
		until [ -f vendor/.installed ]; do echo "En attente de vendor/ (installé par le conteneur api)..."; sleep 3; done
	fi

	# 2. Attente de PostgreSQL
	ATTEMPTS=60
	until [ $ATTEMPTS -eq 0 ] || php bin/console dbal:run-sql -q "SELECT 1" >/dev/null 2>&1; do
		echo "En attente de la base de données... ($ATTEMPTS)"
		sleep 1
		ATTEMPTS=$((ATTEMPTS - 1))
	done
	if [ $ATTEMPTS -eq 0 ]; then
		echo "❌ Base de données injoignable :"
		php bin/console dbal:run-sql "SELECT 1" || true
	fi

	# 3. Schéma de la base aligné sur les entités (le cours n'utilise pas les migrations)
	php bin/console doctrine:database:create --if-not-exists -n -q || true
	if ! php bin/console doctrine:schema:update --force -n -q; then
		echo "⚠️  Schéma non synchronisé : corrigez vos entités puis lancez « make db-update »."
	fi

	echo "✅ API prête (APP_ENV=${APP_ENV})"
fi

exec docker-php-entrypoint "$@"
