# Stack Base – Infraestructura Automatizada AGETIC

Este proyecto proporciona una base reproducible para configurar servicios esenciales como **Docker**, **Docker Compose**, **NFS**, **HAProxy** y **Nginx**, junto con herramientas auxiliares para **certificados**, **llaves criptográficas** y **secrets** seguros.

---

## 📁 Estructura General

```
stack-base/
├── ansibles/
│   ├── docker.yaml
│   └── nfs.yaml
├── docker-compose.yaml
├── scripts/
│   ├── autofirmado.sh
│   ├── generar_secrets.sh
│   └── instalar_docker.sh
└── templates/
    ├── haproxy.conf.template
    └── nginx.conf.template
```

---

## ⚙️ Descripción de Archivos

### 🧩 `ansibles/`

Automatiza la configuración del entorno base mediante playbooks de Ansible.

* **docker.yaml**
  Instala y configura de forma limpia **Docker Engine**, **containerd**, y el plugin oficial **docker-compose-plugin** (`docker compose`).
  
  **Mejoras y compatibilidad:**
  - Desinstala previamente paquetes viejos o en conflicto (`docker.io`, `docker-compose`, `podman-docker`, `runc`).
  - Cumple con las especificaciones modernas de APT usando `/etc/apt/keyrings/docker.asc` (sin el comando obsoleto `apt-key`), haciéndolo 100% compatible con **Debian 11/12/13** y **Ubuntu 20.04/22.04/24.04+**.
  - Instala `docker-compose-plugin` directamente desde el repositorio oficial de Docker.
  - Configura `/etc/docker/daemon.json` con rotación automática de logs (`json-file`, 10m, 3 ficheros comprimidos).
  - Agrega el usuario del sistema al grupo `docker`.

* **nfs.yaml**
  Configura exportaciones NFS compartidas con permisos controlados y soporte para redes específicas.

**Ejecución con Ansible:**

```bash
ansible-playbook -i hosts ansibles/docker.yaml
ansible-playbook -i hosts ansibles/nfs.yaml
```

---

## 🧰 Scripts

### 🐳 `scripts/instalar_docker.sh`

Script Bash autónomo para **instalación limpia y directa** de Docker Engine y Docker Compose (plugin oficial) sin necesidad de Ansible.

**Características:**
* Purga paquetes antiguos conflictivos.
* Detecta automáticamente si el sistema es Debian o Ubuntu y su arquitectura (`amd64`, etc.).
* Agrega las llaves y repositorios oficiales de Docker de forma segura en `/etc/apt/keyrings/docker.asc`.
* Instala `docker-ce`, `docker-ce-cli`, `containerd.io`, `docker-buildx-plugin` y `docker-compose-plugin`.
* Configura la rotación de logs en `/etc/docker/daemon.json` y habilita los servicios.
* Añade automáticamente al usuario ejecutor al grupo `docker`.

**Uso:**

```bash
sudo ./scripts/instalar_docker.sh
```

---

### 🔐 `scripts/autofirmado.sh`

Genera certificados **autofirmados con SAN** (Subject Alternative Name) para múltiples dominios.
Pensado para HAProxy o Nginx en entornos internos.

**Características:**
* Crea `.crt`, `.key` y `.pem`.
* Incluye varios dominios (nip.io, sslip.io o personalizados).
* Configurable para cualquier red o entorno.

**Uso:**

```bash
sudo ./scripts/autofirmado.sh
```

El resultado se guarda en:
```
/etc/haproxy/certs/default.pem
```

---

### 🧬 `scripts/generar_secrets.sh`

Genera cadenas aleatorias seguras (claves JWT, tokens API o contraseñas) usando `openssl`.

**Uso:**

```bash
./scripts/generar_secrets.sh <longitud> <cantidad>
```

**Ejemplo:**

```bash
./scripts/generar_secrets.sh 64 3
```

---

### 🐳 `docker-compose.yaml`

Define los servicios base del entorno (proxies, registries o utilitarios).
Permite levantar toda la infraestructura con el comando moderno de compose:

```bash
docker compose up -d
```

---

### 🧩 Templates

* **`templates/haproxy.conf.template`**: Plantilla base para HAProxy, usada como proxy frontal de múltiples servicios con soporte SSL.
* **`templates/nginx.conf.template`**: Configuración base de Nginx como proxy inverso interno con compresión y WebSockets.

---

## 🚀 Flujo Recomendado

1. **Instalar Docker y Docker Compose:**
   
   * *Opción A (Mediante Script directo):*
     ```bash
     sudo ./scripts/instalar_docker.sh
     ```
   
   * *Opción B (Mediante Ansible):*
     ```bash
     ansible-playbook -i hosts ansibles/docker.yaml
     ansible-playbook -i hosts ansibles/nfs.yaml
     ```

2. **Generar certificados:**
   ```bash
   sudo ./scripts/autofirmado.sh
   ```

3. **Crear secretos:**
   ```bash
   ./scripts/generar_secrets.sh 64 2
   ```

4. **Desplegar servicios:**
   ```bash
   docker compose up -d
   ```

---

## ⚠️ Solución de Problemas Frecuentes

### Error: `permission denied while trying to connect to the docker API at unix:///var/run/docker.sock`

Si tras instalar Docker intentas correr `docker ps` y obtienes este error, se debe a que la sesión activa de tu terminal se inició antes de que tu usuario fuera incorporado al grupo `docker`.

Para resolverlo de inmediato en tu terminal actual sin reiniciar el equipo ni la sesión:

```bash
newgrp docker
docker ps
```

O bien cierra sesión e inicia sesión nuevamente (o reconecta tu sesión SSH).

---

## 🧠 Requisitos Técnicos

* **Sistema:** Debian (11, 12, 13) o Ubuntu (20.04, 22.04, 24.04+)
* **Dependencias:** `curl`, `ca-certificates`, `gnupg`, `openssl`, `bash` (opcional: `ansible`)
* **Permisos:** sudo o root

---

**Autor:** Primo Ticona Callizaya  
**Licencia:** Uso interno institucional.
