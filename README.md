# Stack Base – Infraestructura Automatizada AGETIC

Este proyecto proporciona una base reproducible para configurar servicios esenciales como **Docker**, **NFS**, **HAProxy** y **Nginx**, junto con herramientas auxiliares para **certificados**, **llaves criptográficas** y **secrets** seguros.

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
│   └── gen_secrets.sh
└── templates/
    ├── haproxy.conf.template
    └── nginx.conf.template
```

---

## ⚙️ Descripción de Archivos

### 🧩 `ansibles/`

Automatiza la configuración del entorno base.

* **docker.yaml**
  Instala y configura Docker y el plugin de Compose.
  Prepara el sistema para levantar contenedores de forma segura y persistente.

  #### ⚠️ Nota sobre compatibilidad Debian 13

  En Debian 13, la instalación falla en las tareas de **agregar clave GPG** y **repositorio de Docker** debido a cambios en el manejo de `apt-key`.
  Se recomienda reemplazar esas tareas por el método actualizado basado en `gpg --dearmor` y repositorio manual:

  ```yaml
  - name: Agregar clave GPG manualmente (Debian 13)
    shell: |
      install -m 0755 -d /etc/apt/keyrings
      curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
      chmod a+r /etc/apt/keyrings/docker.gpg

  - name: Agregar repositorio oficial Docker (Debian 13)
    copy:
      dest: /etc/apt/sources.list.d/docker.list
      content: |
        deb [arch=amd64 signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian bookworm stable
  ```

  Esto sustituye las tareas `apt_key` y `apt_repository` para asegurar compatibilidad con Debian 13.

* **nfs.yaml**
  Configura exportaciones NFS compartidas con permisos controlados y soporte para redes específicas.
  Útil para montar volúmenes entre servicios Capibara, Wara u otros.

Ejemplo:

```bash
ansible-playbook -i hosts ansibles/docker.yaml
ansible-playbook -i hosts ansibles/nfs.yaml
```

---

### 🐳 `docker-compose.yaml`

Define los servicios base del entorno (proxies, registries o utilitarios).
Permite levantar toda la infraestructura con:

```bash
docker compose up -d
```

Ideal para entornos locales o demo antes de despliegues institucionales.

---

## 🧰 Scripts

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

**Ejemplo de dominios integrados:**

```
wara.192.168.26.220.nip.io
capibara.192.168.26.220.nip.io
```

El resultado se guarda en:

```
/etc/haproxy/certs/default.pem
```

---

### 🧬 `scripts/gen_secrets.sh`

Genera cadenas aleatorias seguras (por ejemplo, claves JWT, tokens API o contraseñas).
Usa `openssl` para producir valores en Base64 de longitud configurable.

**Uso:**

```bash
./scripts/gen_secrets.sh <longitud> <cantidad>
```

**Ejemplo:**

```bash
./scripts/gen_secrets.sh 64 3
```

Genera 3 secretos de 64 caracteres cada uno.

Salida:

```
zF1hA...KnB7
K82sE...s9Jq
aHeP9...fWZ1
```

Opcionalmente se puede modificar para imprimir en formato `VAR=value`.

---

## 🧩 Templates

### `templates/haproxy.conf.template`

Plantilla base para HAProxy, usada como proxy frontal de múltiples servicios.
Incluye bloques `frontend`, `backend` y soporte SSL (`/etc/haproxy/certs/default.pem`).

### `templates/nginx.conf.template`

Configuración base de Nginx como proxy inverso interno.
Define cabeceras seguras, compresión, tamaño máximo de payload y soporte para WebSockets.

---

## 🚀 Flujo Recomendado

1. **Preparar el servidor:**

   ```bash
   ansible-playbook -i hosts ansibles/docker.yaml
   ansible-playbook -i hosts ansibles/nfs.yaml
   ```

2. **Generar certificados y llaves:**

   ```bash
   sudo ./scripts/autofirmado.sh
   ./scripts/generar_llaves.sh proxy
   ```

3. **Crear secretos seguros:**

   ```bash
   ./scripts/gen_secrets.sh 64 2
   ```

4. **Desplegar servicios:**

   ```bash
   docker compose up -d
   ```

---

## 🧠 Requisitos Técnicos

* **Sistema:** Debian / Ubuntu Server
* **Dependencias:** `ansible`, `docker`, `docker-compose-plugin`, `openssl`, `bash`
* **Permisos:** sudo o root para generación de certificados

---

## 🧩 Resultados Esperados

* Docker y NFS configurados automáticamente.
* Certificados autofirmados listos en `/etc/haproxy/certs`.
* Claves SSH generadas para autenticación.
* Secrets seguros para variables de entorno.
* Plantillas HAProxy/Nginx listas para uso o personalización.

---

**Autor:** Primo Ticona Callizaya
**Licencia:** Uso interno institucional.
