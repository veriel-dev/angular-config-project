# Manual de Explotación

Guía para configurar y mantener los servidores de los entornos DES, PRE y PRO.

---

## Índice

1. [Descripción de la Aplicación](#1-descripción-de-la-aplicación)
2. [Arquitectura](#2-arquitectura)
3. [Requisitos del Servidor](#3-requisitos-del-servidor)
4. [Configuración Inicial del Servidor](#4-configuración-inicial-del-servidor)
5. [Configuración de Azure AD](#5-configuración-de-azure-ad)
6. [Variables de Entorno](#6-variables-de-entorno)
7. [Despliegue de la Aplicación](#7-despliegue-de-la-aplicación)
8. [Configuración de Dominios y SSL](#8-configuración-de-dominios-y-ssl)
9. [Monitorización y Logs](#9-monitorización-y-logs)
10. [Procedimientos de Mantenimiento](#10-procedimientos-de-mantenimiento)
11. [Troubleshooting](#11-troubleshooting)
12. [Contactos y Escalado](#12-contactos-y-escalado)

---

## 1. Descripción de la Aplicación

### Propósito

Aplicación web Angular que permite a los usuarios autenticarse mediante Azure AD, consultar datos de una API backend y proporcionar tokens de Azure a sistemas de terceros.

### Flujo de la Aplicación

```
┌──────────┐      ┌──────────────┐      ┌──────────────┐      ┌──────────────┐
│ Usuario  │ ───► │  Angular App │ ───► │   Azure AD   │ ───► │ Token válido │
└──────────┘      └──────────────┘      └──────────────┘      └──────────────┘
                         │                                            │
                         │                                            ▼
                         │                                   ┌──────────────┐
                         │                                   │   API Backend │
                         │◄──────────────────────────────────│   (datos)     │
                         │                                   └──────────────┘
                         │
                         ▼
                  ┌──────────────┐
                  │   Terceros   │ ◄─── Token Azure (delegado)
                  └──────────────┘
```

### Componentes

| Componente | Descripción |
|------------|-------------|
| **Frontend** | Aplicación Angular servida por Nginx |
| **Azure AD** | Proveedor de identidad (autenticación) |
| **API Backend** | Servicio externo que proporciona datos |
| **Terceros** | Sistemas externos que reciben el token de Azure |

---

## 2. Arquitectura

### Diagrama de Entornos

```
                           ┌─────────────────────────────────────────────────┐
                           │                   INTERNET                       │
                           └─────────────────────────────────────────────────┘
                                    │              │              │
                                    ▼              ▼              ▼
┌─────────────────────┐  ┌─────────────────────┐  ┌─────────────────────┐
│        DES          │  │        PRE          │  │        PRO          │
│  (Desarrollo)       │  │  (Preproducción)    │  │  (Producción)       │
├─────────────────────┤  ├─────────────────────┤  ├─────────────────────┤
│ Dominio:            │  │ Dominio:            │  │ Dominio:            │
│ app-des.empresa.com │  │ app-pre.empresa.com │  │ app.empresa.com     │
├─────────────────────┤  ├─────────────────────┤  ├─────────────────────┤
│ Azure AD:           │  │ Azure AD:           │  │ Azure AD:           │
│ Tenant DES          │  │ Tenant PRE          │  │ Tenant PRO          │
├─────────────────────┤  ├─────────────────────┤  ├─────────────────────┤
│ API:                │  │ API:                │  │ API:                │
│ api-des.empresa.com │  │ api-pre.empresa.com │  │ api.empresa.com     │
└─────────────────────┘  └─────────────────────┘  └─────────────────────┘
```

### Flujo de Red

```
Usuario → DNS → Load Balancer (opcional) → Servidor → Docker → Nginx → App
                                                │
                                                └── Puerto 80/443
```

---

## 3. Requisitos del Servidor

### Hardware Mínimo

| Entorno | CPU | RAM | Disco | Justificación |
|---------|-----|-----|-------|---------------|
| DES | 1 vCPU | 1 GB | 20 GB | Desarrollo, bajo tráfico |
| PRE | 1 vCPU | 2 GB | 20 GB | Testing, tráfico moderado |
| PRO | 2 vCPU | 4 GB | 40 GB | Producción, alta disponibilidad |

### Sistema Operativo

- **Recomendado**: Ubuntu Server 22.04 LTS o 24.04 LTS
- **Alternativas**: Debian 12, Rocky Linux 9, Amazon Linux 2023

### Software Requerido

| Software | Versión Mínima | Propósito |
|----------|----------------|-----------|
| Docker | 24.x | Contenedores |
| Docker Compose | 2.x | Orquestación |
| Nginx | (en contenedor) | Servidor web |
| Certbot | 2.x | Certificados SSL |

### Puertos de Red

| Puerto | Protocolo | Dirección | Propósito |
|--------|-----------|-----------|-----------|
| 22 | TCP | Inbound | SSH (administración) |
| 80 | TCP | Inbound | HTTP (redirección a HTTPS) |
| 443 | TCP | Inbound | HTTPS (aplicación) |

### Conectividad Saliente Requerida

| Destino | Puerto | Propósito |
|---------|--------|-----------|
| login.microsoftonline.com | 443 | Autenticación Azure AD |
| graph.microsoft.com | 443 | API Microsoft Graph |
| *.empresa.com (API) | 443 | Backend API |

---

## 4. Configuración Inicial del Servidor

### 4.1 Acceso al Servidor

```bash
# Conectar por SSH
ssh -i /ruta/a/clave.pem usuario@IP_SERVIDOR
```

### 4.2 Actualización del Sistema

```bash
# Ubuntu/Debian
sudo apt update && sudo apt upgrade -y

# Rocky Linux/RHEL
sudo dnf update -y
```

### 4.3 Instalación de Docker

```bash
# Método universal (script oficial)
curl -fsSL https://get.docker.com | sudo sh

# Añadir usuario al grupo docker
sudo usermod -aG docker $USER

# Aplicar cambios (reconectar SSH o ejecutar)
newgrp docker

# Verificar instalación
docker --version
docker compose version
```

### 4.4 Configuración de Firewall

```bash
# Ubuntu (UFW)
sudo ufw allow 22/tcp    # SSH
sudo ufw allow 80/tcp    # HTTP
sudo ufw allow 443/tcp   # HTTPS
sudo ufw enable

# Verificar
sudo ufw status
```

### 4.5 Crear Estructura de Directorios

```bash
# Crear directorios de la aplicación
sudo mkdir -p /opt/app/{config,logs,ssl}
sudo chown -R $USER:$USER /opt/app

# Estructura resultante:
# /opt/app/
# ├── config/     # Archivos de configuración
# ├── logs/       # Logs de la aplicación
# └── ssl/        # Certificados SSL
```

### 4.6 Configurar Timezone

```bash
# Establecer zona horaria
sudo timedatectl set-timezone Europe/Madrid

# Verificar
timedatectl
```

---

## 5. Configuración de Azure AD

### 5.1 Registro de Aplicación en Azure

Para cada entorno (DES, PRE, PRO), registrar una aplicación en Azure Portal:

1. Ir a **Azure Portal** → **Azure Active Directory** → **App registrations**
2. Clic en **New registration**
3. Configurar:

| Campo | DES | PRE | PRO |
|-------|-----|-----|-----|
| Name | App-DES | App-PRE | App-PRO |
| Redirect URI (SPA) | https://app-des.empresa.com | https://app-pre.empresa.com | https://app.empresa.com |
| Supported account types | Single tenant | Single tenant | Single tenant |

### 5.2 Obtener Credenciales

Después de registrar, anotar:

| Valor | Dónde encontrarlo | Ejemplo |
|-------|-------------------|---------|
| **Client ID** | Overview → Application (client) ID | `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx` |
| **Tenant ID** | Overview → Directory (tenant) ID | `yyyyyyyy-yyyy-yyyy-yyyy-yyyyyyyyyyyy` |
| **Authority** | Construir URL | `https://login.microsoftonline.com/{tenant_id}` |

### 5.3 Configurar Permisos API

En **API permissions**, añadir:

| Permiso | Tipo | Descripción |
|---------|------|-------------|
| User.Read | Delegated | Leer perfil del usuario |
| openid | Delegated | Autenticación OpenID |
| profile | Delegated | Información del perfil |
| email | Delegated | Email del usuario |

**Nota**: Si la aplicación provee tokens a terceros, configurar los scopes adicionales necesarios.

### 5.4 Configurar Token

En **Authentication**:

- ✅ Access tokens (for implicit flows)
- ✅ ID tokens (for implicit and hybrid flows)

En **Token configuration**, añadir claims opcionales si es necesario.

---

## 6. Variables de Entorno

### 6.1 Archivo de Configuración

Crear archivo `/opt/app/config/.env` en cada servidor:

```bash
# /opt/app/config/.env

# ===================
# ENTORNO
# ===================
ENVIRONMENT=des|pre|pro
NODE_ENV=development|staging|production

# ===================
# AZURE AD
# ===================
AZURE_CLIENT_ID=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
AZURE_TENANT_ID=yyyyyyyy-yyyy-yyyy-yyyy-yyyyyyyyyyyy
AZURE_AUTHORITY=https://login.microsoftonline.com/{tenant_id}
AZURE_REDIRECT_URI=https://app-des.empresa.com
AZURE_SCOPES=openid profile email User.Read

# ===================
# API BACKEND
# ===================
API_URL=https://api-des.empresa.com
API_TIMEOUT=30000

# ===================
# TERCEROS
# ===================
THIRD_PARTY_ENABLED=true
THIRD_PARTY_CALLBACK_URL=https://tercero.example.com/callback

# ===================
# APLICACIÓN
# ===================
APP_NAME=MiApp
APP_VERSION=1.0.0
LOG_LEVEL=debug|info|warn|error
```

### 6.2 Valores por Entorno

#### DES (Desarrollo)

```bash
ENVIRONMENT=des
NODE_ENV=development
AZURE_CLIENT_ID=<client_id_des>
AZURE_TENANT_ID=<tenant_id_des>
AZURE_REDIRECT_URI=https://app-des.empresa.com
API_URL=https://api-des.empresa.com
LOG_LEVEL=debug
```

#### PRE (Preproducción)

```bash
ENVIRONMENT=pre
NODE_ENV=staging
AZURE_CLIENT_ID=<client_id_pre>
AZURE_TENANT_ID=<tenant_id_pre>
AZURE_REDIRECT_URI=https://app-pre.empresa.com
API_URL=https://api-pre.empresa.com
LOG_LEVEL=info
```

#### PRO (Producción)

```bash
ENVIRONMENT=pro
NODE_ENV=production
AZURE_CLIENT_ID=<client_id_pro>
AZURE_TENANT_ID=<tenant_id_pro>
AZURE_REDIRECT_URI=https://app.empresa.com
API_URL=https://api.empresa.com
LOG_LEVEL=warn
```

### 6.3 Seguridad de Variables

```bash
# Permisos restrictivos para el archivo .env
chmod 600 /opt/app/config/.env

# Solo el usuario de la aplicación puede leerlo
chown appuser:appuser /opt/app/config/.env
```

---

## 7. Despliegue de la Aplicación

### 7.1 Método 1: Transferencia de Imagen Docker (Recomendado)

Desde la máquina de desarrollo:

```bash
# 1. Construir imagen
docker build --build-arg ENVIRONMENT=des -t angular-app-des .

# 2. Guardar imagen
docker save angular-app-des:latest > angular-app-des.tar

# 3. Transferir al servidor
scp angular-app-des.tar usuario@servidor:/opt/app/

# 4. En el servidor, cargar y ejecutar
ssh usuario@servidor << 'EOF'
cd /opt/app
docker load < angular-app-des.tar
docker stop angular-app 2>/dev/null || true
docker rm angular-app 2>/dev/null || true
docker run -d \
  --name angular-app \
  --restart unless-stopped \
  --env-file /opt/app/config/.env \
  -p 80:80 \
  -p 443:443 \
  -v /opt/app/ssl:/etc/nginx/ssl:ro \
  angular-app-des:latest
EOF
```

### 7.2 Método 2: Docker Compose

Crear `/opt/app/docker-compose.yml`:

```yaml
services:
  app:
    image: angular-app-${ENVIRONMENT}:latest
    container_name: angular-app
    restart: unless-stopped
    env_file:
      - ./config/.env
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./ssl:/etc/nginx/ssl:ro
      - ./logs:/var/log/nginx
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 10s
```

Ejecutar:

```bash
cd /opt/app
ENVIRONMENT=des docker compose up -d
```

### 7.3 Verificación Post-Despliegue

```bash
# Verificar contenedor corriendo
docker ps | grep angular-app

# Ver logs
docker logs -f angular-app

# Test de salud
curl -I http://localhost

# Test completo (con dominio)
curl -I https://app-des.empresa.com
```

---

## 8. Configuración de Dominios y SSL

### 8.1 Configuración DNS

Crear registros DNS apuntando a las IPs de los servidores:

| Registro | Tipo | Valor | TTL |
|----------|------|-------|-----|
| app-des.empresa.com | A | IP_SERVIDOR_DES | 300 |
| app-pre.empresa.com | A | IP_SERVIDOR_PRE | 300 |
| app.empresa.com | A | IP_SERVIDOR_PRO | 300 |

### 8.2 Certificados SSL con Let's Encrypt

```bash
# Instalar Certbot
sudo apt install -y certbot

# Parar contenedor temporalmente
docker stop angular-app

# Obtener certificado
sudo certbot certonly --standalone \
  -d app-des.empresa.com \
  --email admin@empresa.com \
  --agree-tos \
  --non-interactive

# Copiar certificados al directorio de la app
sudo cp /etc/letsencrypt/live/app-des.empresa.com/fullchain.pem /opt/app/ssl/
sudo cp /etc/letsencrypt/live/app-des.empresa.com/privkey.pem /opt/app/ssl/
sudo chown -R $USER:$USER /opt/app/ssl

# Reiniciar contenedor
docker start angular-app
```

### 8.3 Renovación Automática

```bash
# Crear script de renovación
cat > /opt/app/renew-ssl.sh << 'EOF'
#!/bin/bash
docker stop angular-app
certbot renew --quiet
cp /etc/letsencrypt/live/*/fullchain.pem /opt/app/ssl/
cp /etc/letsencrypt/live/*/privkey.pem /opt/app/ssl/
docker start angular-app
EOF

chmod +x /opt/app/renew-ssl.sh

# Añadir cron (cada día a las 3:00 AM)
echo "0 3 * * * /opt/app/renew-ssl.sh" | sudo tee -a /etc/crontab
```

---

## 9. Monitorización y Logs

### 9.1 Logs de la Aplicación

```bash
# Ver logs en tiempo real
docker logs -f angular-app

# Últimas 100 líneas
docker logs --tail 100 angular-app

# Logs con timestamp
docker logs -t angular-app

# Logs de un período específico
docker logs --since 2024-01-01T00:00:00 angular-app
```

### 9.2 Logs de Nginx (dentro del contenedor)

```bash
# Acceder al contenedor
docker exec -it angular-app sh

# Ver logs
tail -f /var/log/nginx/access.log
tail -f /var/log/nginx/error.log
```

### 9.3 Métricas del Sistema

```bash
# Uso de recursos del contenedor
docker stats angular-app

# Uso de disco
df -h

# Uso de memoria
free -h

# Procesos
htop
```

### 9.4 Alertas Básicas (Script)

Crear `/opt/app/health-check.sh`:

```bash
#!/bin/bash

WEBHOOK_URL="https://hooks.slack.com/services/xxx"  # O email
APP_URL="https://app-des.empresa.com"

# Check HTTP
HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" $APP_URL)

if [ "$HTTP_STATUS" != "200" ]; then
    curl -X POST -H 'Content-type: application/json' \
        --data '{"text":"⚠️ App DES no responde. Status: '$HTTP_STATUS'"}' \
        $WEBHOOK_URL
fi

# Check container
if ! docker ps | grep -q angular-app; then
    curl -X POST -H 'Content-type: application/json' \
        --data '{"text":"🔴 Contenedor angular-app no está corriendo"}' \
        $WEBHOOK_URL
fi
```

Añadir a cron (cada 5 minutos):

```bash
*/5 * * * * /opt/app/health-check.sh
```

---

## 10. Procedimientos de Mantenimiento

### 10.1 Actualización de la Aplicación

```bash
# 1. Recibir nueva imagen
scp angular-app-des.tar usuario@servidor:/opt/app/

# 2. Backup de la imagen actual (opcional)
docker tag angular-app-des:latest angular-app-des:backup

# 3. Cargar nueva imagen
cd /opt/app
docker load < angular-app-des.tar

# 4. Reiniciar con nueva versión
docker stop angular-app
docker rm angular-app
docker run -d \
  --name angular-app \
  --restart unless-stopped \
  --env-file /opt/app/config/.env \
  -p 80:80 \
  -p 443:443 \
  -v /opt/app/ssl:/etc/nginx/ssl:ro \
  angular-app-des:latest

# 5. Verificar
docker ps
curl -I https://app-des.empresa.com
```

### 10.2 Rollback

```bash
# Si algo falla, volver a la versión anterior
docker stop angular-app
docker rm angular-app
docker run -d \
  --name angular-app \
  --restart unless-stopped \
  --env-file /opt/app/config/.env \
  -p 80:80 \
  -p 443:443 \
  -v /opt/app/ssl:/etc/nginx/ssl:ro \
  angular-app-des:backup  # Usar imagen de backup
```

### 10.3 Limpieza de Docker

```bash
# Eliminar imágenes no usadas
docker image prune -a

# Eliminar contenedores parados
docker container prune

# Eliminar todo lo no usado
docker system prune -a

# Ver uso de disco de Docker
docker system df
```

### 10.4 Backup de Configuración

```bash
# Backup manual
tar -czvf backup-config-$(date +%Y%m%d).tar.gz /opt/app/config/

# Restaurar
tar -xzvf backup-config-20240101.tar.gz -C /
```

---

## 11. Troubleshooting

### 11.1 Contenedor no arranca

```bash
# Ver logs de arranque
docker logs angular-app

# Verificar que la imagen existe
docker images | grep angular-app

# Verificar puertos ocupados
sudo netstat -tlnp | grep -E ':(80|443)'

# Solución: matar proceso que ocupa puerto
sudo fuser -k 80/tcp
```

### 11.2 Error de Azure AD

| Error | Causa | Solución |
|-------|-------|----------|
| AADSTS50011 | Redirect URI no coincide | Verificar URI en Azure Portal |
| AADSTS700016 | App no encontrada | Verificar Client ID |
| AADSTS90002 | Tenant no encontrado | Verificar Tenant ID |

```bash
# Verificar configuración
cat /opt/app/config/.env | grep AZURE
```

### 11.3 Error de conexión a API

```bash
# Probar conectividad desde el servidor
curl -v https://api-des.empresa.com/health

# Verificar DNS
nslookup api-des.empresa.com

# Verificar que el contenedor tiene salida a internet
docker exec angular-app curl -I https://google.com
```

### 11.4 Error SSL

```bash
# Verificar certificados
openssl s_client -connect app-des.empresa.com:443

# Verificar fechas del certificado
openssl x509 -in /opt/app/ssl/fullchain.pem -noout -dates

# Forzar renovación
sudo certbot renew --force-renewal
```

### 11.5 Servidor lento

```bash
# Verificar recursos
docker stats angular-app
free -h
df -h

# Ver procesos que consumen
top

# Reiniciar contenedor
docker restart angular-app
```

---

## 12. Contactos y Escalado

### Niveles de Soporte

| Nivel | Responsable | Contacto | Casos |
|-------|-------------|----------|-------|
| L1 | Operaciones | ops@empresa.com | Monitorización, reinicios |
| L2 | DevOps | devops@empresa.com | Despliegues, configuración |
| L3 | Desarrollo | dev@empresa.com | Bugs, nuevas features |

### Escalado de Incidencias

| Severidad | Descripción | Tiempo Respuesta | Contacto |
|-----------|-------------|------------------|----------|
| P1 - Crítica | PRO caído | 15 min | Llamada + Slack |
| P2 - Alta | PRO degradado | 1 hora | Slack |
| P3 - Media | PRE/DES caído | 4 horas | Email |
| P4 - Baja | Mejoras | 24 horas | Email |

### Información a Incluir en Incidencias

```
Entorno: DES/PRE/PRO
Fecha y hora: YYYY-MM-DD HH:MM
Descripción:
Logs relevantes:
Pasos para reproducir:
Impacto:
```

---

## Anexo A: Checklist de Nuevo Servidor

- [ ] Servidor aprovisionado con SO Ubuntu 22.04+
- [ ] Acceso SSH configurado
- [ ] Sistema actualizado
- [ ] Docker instalado
- [ ] Firewall configurado (22, 80, 443)
- [ ] Directorio /opt/app creado
- [ ] Archivo .env configurado
- [ ] Dominio DNS apuntando al servidor
- [ ] Certificado SSL instalado
- [ ] Imagen Docker transferida
- [ ] Contenedor corriendo
- [ ] Health check OK
- [ ] Monitorización configurada
- [ ] Backup de configuración

---

## Anexo B: Comandos Rápidos

```bash
# Estado del servicio
docker ps | grep angular-app

# Reiniciar
docker restart angular-app

# Ver logs
docker logs -f --tail 100 angular-app

# Entrar al contenedor
docker exec -it angular-app sh

# Uso de recursos
docker stats angular-app

# Parar
docker stop angular-app

# Arrancar
docker start angular-app

# Eliminar y recrear
docker rm -f angular-app && docker run -d ...
```

---

**Última actualización**: Enero 2025
**Versión del documento**: 1.0
