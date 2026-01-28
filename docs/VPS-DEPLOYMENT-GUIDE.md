# Guía de Deployment en VPS Gratuitos

Configuración de 3 servidores Ubuntu gratuitos en Oracle Cloud + dominios con DuckDNS.

---

## Parte 1: Crear Cuenta en Oracle Cloud

### Paso 1.1: Registro

1. Ve a: https://www.oracle.com/cloud/free/
2. Clic en **"Start for free"**
3. Completa el formulario:
   - Email válido
   - País: España (o tu país)
   - **Home Region**: Elige la más cercana (ej: `eu-madrid-1` o `eu-frankfurt-1`)

   > ⚠️ **IMPORTANTE**: La Home Region NO se puede cambiar después. Elige bien.

4. Verificación de email
5. **Verificación de tarjeta**: Oracle pide tarjeta pero **NO cobra nada**. Es solo verificación.
   - Puede aparecer un cargo temporal de $1 que se revierte

### Paso 1.2: Acceder a la Consola

1. Una vez verificado, accede a: https://cloud.oracle.com
2. Introduce tu **Cloud Account Name** (lo elegiste en el registro)
3. Login con tu email y contraseña

---

## Parte 2: Crear las 3 Instancias VM

### Paso 2.1: Crear la Primera VM (DES)

1. En el Dashboard, clic en **"Create a VM instance"**

2. **Name**: `vm-des`

3. **Image and shape**:
   - Clic en **"Edit"**
   - Image: **Canonical Ubuntu 22.04** (o 24.04)
   - Shape: Clic en **"Change shape"**
     - Instance type: **Virtual machine**
     - Shape series: **Ampere** (ARM)
     - Shape: **VM.Standard.A1.Flex**
     - OCPUs: **1**
     - Memory: **6 GB**
   - Clic **"Select shape"**

4. **Networking**:
   - Selecciona tu VCN o deja que cree uno nuevo
   - Subnet: Pública
   - **Public IPv4 address**: ✅ Assign a public IPv4 address

5. **Add SSH keys**:
   - Selecciona **"Generate a key pair for me"**
   - **DESCARGA AMBOS ARCHIVOS** (privado y público)
   - Guárdalos en lugar seguro: `~/.ssh/oracle-des.key`

6. Clic **"Create"**

7. **Espera** a que el estado sea **"RUNNING"**

8. **Anota la IP pública** (ej: `129.154.xxx.xxx`)

### Paso 2.2: Crear Segunda VM (PRE)

Repite el proceso con:
- **Name**: `vm-pre`
- **Shape**: VM.Standard.A1.Flex (1 OCPU, 6GB RAM)
- Descarga las SSH keys: `oracle-pre.key`
- Anota la IP pública

### Paso 2.3: Crear Tercera VM (PRO)

Repite el proceso con:
- **Name**: `vm-pro`
- **Shape**: VM.Standard.A1.Flex (1 OCPU, 6GB RAM)
- Descarga las SSH keys: `oracle-pro.key`
- Anota la IP pública

### Resumen de IPs (ejemplo)

```
vm-des: 129.154.xxx.xxx
vm-pre: 129.154.yyy.yyy
vm-pro: 129.154.zzz.zzz
```

---

## Parte 3: Abrir Puertos (Security Lists)

Por defecto Oracle bloquea todos los puertos excepto el 22 (SSH).

### Paso 3.1: Configurar Security List

1. Ve a **Networking** → **Virtual Cloud Networks**
2. Clic en tu VCN (ej: `vcn-xxxxxxx`)
3. Clic en tu **Subnet** pública
4. Clic en la **Security List** (ej: `Default Security List for vcn-xxx`)
5. Clic en **"Add Ingress Rules"**

### Paso 3.2: Añadir Reglas

Añade estas reglas (una por una o todas juntas):

**Regla 1 - HTTP:**
```
Source Type: CIDR
Source CIDR: 0.0.0.0/0
IP Protocol: TCP
Destination Port Range: 80
Description: HTTP
```

**Regla 2 - HTTPS:**
```
Source Type: CIDR
Source CIDR: 0.0.0.0/0
IP Protocol: TCP
Destination Port Range: 443
Description: HTTPS
```

6. Clic **"Add Ingress Rules"**

---

## Parte 4: Configurar DuckDNS

### Paso 4.1: Crear Cuenta

1. Ve a: https://www.duckdns.org
2. Clic en **"login"** (usa GitHub, Google, Twitter, etc.)
3. Una vez logueado, verás tu **token** en la parte superior
4. **Guarda el token** (lo necesitarás)

### Paso 4.2: Crear los 3 Subdominios

En la página principal de DuckDNS:

1. En el campo **"sub domain"**, escribe: `tuproyecto-des`
   - Clic **"add domain"**
   - Actualiza la IP con la de tu VM DES: `129.154.xxx.xxx`
   - Clic **"update ip"**

2. Repite para: `tuproyecto-pre` → IP de VM PRE

3. Repite para: `tuproyecto-pro` → IP de VM PRO

### Resultado

```
tuproyecto-des.duckdns.org → 129.154.xxx.xxx (DES)
tuproyecto-pre.duckdns.org → 129.154.yyy.yyy (PRE)
tuproyecto-pro.duckdns.org → 129.154.zzz.zzz (PRO)
```

---

## Parte 5: Configurar las VMs

### Paso 5.1: Preparar SSH Keys

```bash
# Mueve las keys a ~/.ssh
mv ~/Downloads/ssh-key-*.key ~/.ssh/

# Renombra para claridad
mv ~/.ssh/ssh-key-2024-*.key ~/.ssh/oracle-des.key
# (repite para pre y pro)

# Permisos correctos
chmod 600 ~/.ssh/oracle-*.key
```

### Paso 5.2: Conectar por SSH

```bash
# Conectar a DES
ssh -i ~/.ssh/oracle-des.key ubuntu@tuproyecto-des.duckdns.org

# Conectar a PRE
ssh -i ~/.ssh/oracle-pre.key ubuntu@tuproyecto-pre.duckdns.org

# Conectar a PRO
ssh -i ~/.ssh/oracle-pro.key ubuntu@tuproyecto-pro.duckdns.org
```

### Paso 5.3: Script de Instalación (ejecutar en CADA VM)

Conéctate a cada VM y ejecuta:

```bash
#!/bin/bash
# setup-vm.sh - Ejecutar en cada VM

# Actualizar sistema
sudo apt update && sudo apt upgrade -y

# Instalar Docker
curl -fsSL https://get.docker.com | sudo sh

# Añadir usuario al grupo docker
sudo usermod -aG docker ubuntu

# Instalar Docker Compose
sudo apt install -y docker-compose

# Abrir firewall interno de Ubuntu
sudo iptables -I INPUT 6 -m state --state NEW -p tcp --dport 80 -j ACCEPT
sudo iptables -I INPUT 6 -m state --state NEW -p tcp --dport 443 -j ACCEPT
sudo netfilter-persistent save

# Crear directorio para la app
mkdir -p ~/app

# Verificar instalación
docker --version
docker-compose --version

echo "✅ VM lista para deploy"
```

> **Nota**: Después de ejecutar, haz `exit` y vuelve a conectar para que el grupo docker se aplique.

---

## Parte 6: Deploy a los Servidores

### Paso 6.1: Archivo de Configuración Local

Crea el archivo con las IPs y dominios de tus servidores:

```bash
# En tu máquina local, crea: ~/.servers-config
cat > ~/.servers-config << 'EOF'
# Configuración de servidores
DES_HOST=tuproyecto-des.duckdns.org
DES_KEY=~/.ssh/oracle-des.key
DES_USER=ubuntu

PRE_HOST=tuproyecto-pre.duckdns.org
PRE_KEY=~/.ssh/oracle-pre.key
PRE_USER=ubuntu

PRO_HOST=tuproyecto-pro.duckdns.org
PRO_KEY=~/.ssh/oracle-pro.key
PRO_USER=ubuntu
EOF
```

### Paso 6.2: Script de Deploy Remoto

Usa el script `scripts/deploy-remote.sh` que incluye el proyecto.

---

## Parte 7: Configurar HTTPS (Opcional pero Recomendado)

### Con Certbot (Let's Encrypt) - En cada VM:

```bash
# Instalar Certbot
sudo apt install -y certbot

# Parar el contenedor temporalmente
docker stop $(docker ps -q)

# Obtener certificado
sudo certbot certonly --standalone -d tuproyecto-des.duckdns.org

# El certificado queda en:
# /etc/letsencrypt/live/tuproyecto-des.duckdns.org/
```

---

## Resumen de Costos

| Concepto | Costo |
|----------|-------|
| Oracle Cloud (3 VMs) | $0/mes - GRATIS SIEMPRE |
| DuckDNS (3 subdominios) | $0/mes - GRATIS |
| Let's Encrypt (HTTPS) | $0/mes - GRATIS |
| **TOTAL** | **$0/mes** |

---

## Troubleshooting

### "No route to host" al conectar SSH
- Espera 2-3 minutos después de crear la VM
- Verifica que la IP pública está asignada

### "Connection refused" en puerto 80
1. Verifica Security List en Oracle Cloud
2. Verifica iptables en la VM: `sudo iptables -L`
3. Verifica que Docker está corriendo: `docker ps`

### DuckDNS no resuelve
- Los DNS pueden tardar 5-10 minutos en propagarse
- Prueba: `ping tuproyecto-des.duckdns.org`

### Error "permission denied" con Docker
```bash
# Salir y volver a entrar por SSH
exit
ssh -i ~/.ssh/oracle-des.key ubuntu@...
```

---

## Siguiente Paso

Una vez configurados los servidores, ejecuta:

```bash
# Desde tu proyecto local
npm run deploy:remote:des
```

Esto construirá la imagen Docker localmente y la desplegará en el servidor DES.
