#!/usr/bin/env bash
# gen_secrets.sh
# Uso: ./gen_secrets.sh <longitud> <cantidad>
# Ejemplo: ./gen_secrets.sh 64 3
set -euo pipefail

LEN=${1:-64}       # longitud en caracteres por secreto (por defecto 64)
COUNT=${2:-1}      # cuantas llaves generar (por defecto 1)

# bytes necesarios para producir al menos LEN chars en base64: 4*ceil(bytes/3) >= LEN
BYTES=$(( (LEN*3 + 3) / 4 ))

for i in $(seq 1 "$COUNT"); do
  openssl rand -base64 "$BYTES" | tr -d '\n' | cut -c1-"$LEN"
  # si prefieres formato NAME=valor, usa:
  # echo "SECRET_${i}=$(openssl rand -base64 $BYTES | tr -d '\n' | cut -c1-$LEN)"
  [ "$i" -lt "$COUNT" ] && echo
done
