#!/bin/bash
# Inicializa la base de datos creando tablas y poblando datos iniciales

set -e

docker-compose run --rm \
  --name db-init \
  --no-deps \
  -v .env:/home/node/app/.env:ro \
  nombre-servicio-backend \
  npm run setup
