#!/bin/bash
set -euo pipefail

# === Variables configurables ===
CERT_DIR="/etc/haproxy/certs"
CRT_FILE="$CERT_DIR/default.crt"
KEY_FILE="$CERT_DIR/default.key"
PEM_FILE="$CERT_DIR/default.pem"
SAN_FILE="$(mktemp)"

# Lista de dominios a incluir en el certificado
DOMAINS=(
  "wara.192.168.26.220.nip.io"
  "capibara.192.168.26.220.nip.io"
)

# === Validación de dependencias ===
command -v openssl >/dev/null 2>&1 || { echo "Error: openssl no está instalado."; exit 1; }

# === Crear carpeta destino ===
sudo mkdir -p "$CERT_DIR"

# === Generar bloque SAN dinámico ===
ALT_NAMES=""
i=1
for domain in "${DOMAINS[@]}"; do
  ALT_NAMES+="DNS.$i = $domain"$'\n'
  ((i++))
done

# === Crear archivo de configuración temporal ===
cat > "$SAN_FILE" <<EOF
[req]
default_bits       = 2048
distinguished_name = req_distinguished_name
req_extensions     = req_ext
x509_extensions    = v3_req
prompt             = no

[req_distinguished_name]
C  = BO
ST = LaPaz
L  = LaPaz
O  = AGETIC
CN = ${DOMAINS[0]}

[req_ext]
subjectAltName = @alt_names

[v3_req]
subjectAltName = @alt_names

[alt_names]
$ALT_NAMES
EOF

# === Generar certificado ===
sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout "$KEY_FILE" \
  -out "$CRT_FILE" \
  -config "$SAN_FILE" -extensions v3_req

# === Crear archivo PEM ===
sudo sh -c "cat $CRT_FILE $KEY_FILE > $PEM_FILE"
sudo chmod 600 "$PEM_FILE"

echo "Certificado autofirmado generado:"
echo "  - PEM : $PEM_FILE"
echo "  - CRT : $CRT_FILE"
echo "  - KEY : $KEY_FILE"

rm -f "$SAN_FILE"
