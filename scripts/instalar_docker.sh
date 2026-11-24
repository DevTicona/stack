#!/usr/bin/env bash
# ==============================================================================
# Script de instalación limpia y oficial de Docker Engine y Docker Compose
# Compatible con: Debian (11, 12, 13/trixie) y Ubuntu (20.04, 22.04, 24.04+)
# ==============================================================================

set -euo pipefail

echo "=========================================================="
echo "  Instalador limpio de Docker & Docker Compose"
echo "=========================================================="

# 1. Comprobar permisos de root
if [ "$EUID" -ne 0 ]; then
  echo "[!] Por favor ejecuta este script con permisos sudo o como root."
  exit 1
fi

# 2. Detectar distribución y codename
if [ -f /etc/os-release ]; then
  . /etc/os-release
  DISTRO="${ID:-debian}"
  CODENAME="${VERSION_CODENAME:-}"
else
  echo "[!] No se pudo determinar la distribución en /etc/os-release."
  exit 1
fi

if [ -z "$CODENAME" ]; then
  CODENAME=$(lsb_release -cs 2>/dev/null || echo "bookworm")
fi

# Normalizar distribución compatible (Debian/Ubuntu)
if [ "$DISTRO" != "debian" ] && [ "$DISTRO" != "ubuntu" ]; then
  # Si es derivada, usar ID_LIKE si es debian o ubuntu
  if [[ "${ID_LIKE:-}" =~ debian ]]; then
    DISTRO="debian"
  elif [[ "${ID_LIKE:-}" =~ ubuntu ]]; then
    DISTRO="ubuntu"
  else
    echo "[!] Distribución no soportada directamente: $DISTRO"
    exit 1
  fi
fi

# En caso de Debian testing/13 (trixie), fallback a bookworm si trixie no está aún en repos de Docker
if [ "$DISTRO" = "debian" ] && [ "$CODENAME" = "trixie" ]; then
  echo "[*] Detectado Debian testing/trixie. Utilizando repositorio bookworm de Docker por compatibilidad..."
  CODENAME="bookworm"
fi

echo "[*] Sistema detectado: $DISTRO ($CODENAME) - Arquitectura: $(dpkg --print-architecture)"

# 3. Desinstalar paquetes no oficiales o antiguos en conflicto
echo "[*] Removiendo paquetes antiguos o no oficiales en conflicto..."
for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do
  apt-get remove -y "$pkg" 2>/dev/null || true
done

# 4. Instalar dependencias
echo "[*] Instalando dependencias previas..."
apt-get update -y
apt-get install -y ca-certificates curl gnupg lsb-release

# 5. Agregar la clave oficial de Docker usando /etc/apt/keyrings (método moderno y limpio)
echo "[*] Configurando clave GPG oficial de Docker..."
install -m 0755 -d /etc/apt/keyrings
curl -fsSL "https://download.docker.com/linux/$DISTRO/gpg" -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc

# 6. Configurar el repositorio APT oficial
echo "[*] Configurando repositorio oficial de Docker..."
ARCH=$(dpkg --print-architecture)
cat <<EOF > /etc/apt/sources.list.d/docker.list
deb [arch=$ARCH signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/$DISTRO $CODENAME stable
EOF

# 7. Instalar Docker Engine, CLI, Containerd y Compose plugin oficial
echo "[*] Instalando Docker Engine y docker-compose-plugin..."
apt-get update -y
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# 8. Configurar daemon.json con rotación de logs por defecto
echo "[*] Configurando /etc/docker/daemon.json con rotación de logs..."
mkdir -p /etc/docker
cat <<EOF > /etc/docker/daemon.json
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3",
    "compress": "true"
  }
}
EOF

# 9. Iniciar y habilitar servicios
echo "[*] Habilitando y reiniciando servicio Docker..."
systemctl daemon-reload
systemctl enable docker containerd
systemctl restart docker

# 10. Agregar usuario al grupo docker
TARGET_USER="${SUDO_USER:-}"
if [ -z "$TARGET_USER" ] || [ "$TARGET_USER" = "root" ]; then
  TARGET_USER="${USER:-}"
fi
if [ -z "$TARGET_USER" ] || [ "$TARGET_USER" = "root" ]; then
  # Buscar primer usuario regular con UID >= 1000 que tenga shell válida
  TARGET_USER=$(awk -F: '$3 >= 1000 && $3 < 60000 && $7 !~ /(nologin|false)/ {print $1; exit}' /etc/passwd || true)
fi

# Asegurar grupo docker y permisos en socket
groupadd -f docker
if [ -n "$TARGET_USER" ] && [ "$TARGET_USER" != "root" ]; then
  echo "[*] Agregando usuario '$TARGET_USER' al grupo docker..."
  usermod -aG docker "$TARGET_USER"
fi

# Si el socket ya existe, asegurar permisos
if [ -S /var/run/docker.sock ]; then
  chown root:docker /var/run/docker.sock
  chmod 660 /var/run/docker.sock
fi

# 11. Validar instalación
echo ""
echo "=========================================================="
echo "  Verificación de instalación:"
echo "=========================================================="
docker --version || true
docker compose version || true

echo ""
echo "[✓] Instalación completada con éxito."
if [ -n "$TARGET_USER" ] && [ "$TARGET_USER" != "root" ]; then
  echo ""
  echo "=========================================================="
  echo "  [IMPORTANTE] Para usar Docker sin 'sudo' de inmediato:"
  echo "=========================================================="
  echo "  En Linux, las shells activas no heredan nuevos grupos"
  echo "  automáticamente. Ejecuta el siguiente comando en tu"
  echo "  terminal actual:"
  echo ""
  echo "    newgrp docker"
  echo ""
  echo "  O bien cierra sesión y vuelve a iniciarla."
  echo "=========================================================="
fi
