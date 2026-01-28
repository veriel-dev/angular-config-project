# Flujo de Despliegue Remoto

Explicación detallada de cómo se despliega la aplicación a un servidor remoto.

---

## Resumen

```
Tu PC (build) → Docker image → SSH/SCP → Servidor → Nginx → Internet → Usuario
```

---

## Paso 1: Construcción local

Al ejecutar:

```bash
npm run remote:des
```

Se ejecuta internamente:

```bash
# 1. Verificación de calidad (si falla, para aquí)
npm run lint
npm run test

# 2. Construye imagen Docker con el build de DES
docker build --build-arg ENVIRONMENT=des -t angular-app-des .
```

**Resultado:** Imagen Docker `angular-app-des:latest` (~30MB)

---

## Paso 2: Transferencia al servidor

```bash
# Guarda la imagen en un archivo .tar
docker save angular-app-des:latest > /tmp/angular-app-des.tar

# La envía al servidor por SSH
scp -i ~/.ssh/oracle-des.key /tmp/angular-app-des.tar ubuntu@tuproyecto-des.duckdns.org:~/app/
```

**Resultado:** El archivo .tar está en el servidor en `~/app/`

---

## Paso 3: Ejecución en el servidor

El script se conecta por SSH y ejecuta:

```bash
# Conectar al servidor
ssh -i ~/.ssh/oracle-des.key ubuntu@tuproyecto-des.duckdns.org

# Ya en el servidor:
cd ~/app

# Cargar la imagen
docker load < angular-app-des.tar

# Parar contenedor anterior (si existe)
docker stop angular-app-des
docker rm angular-app-des

# Arrancar nuevo contenedor
docker run -d \
  --name angular-app-des \
  --restart unless-stopped \
  -p 80:80 \
  angular-app-des:latest
```

---

## Paso 4: Servicio activo

```
┌──────────────────────────────────────────────────────────────┐
│                    SERVIDOR (VPS)                            │
│                                                              │
│  ┌────────────────────────────────────────────────────────┐  │
│  │              Docker Container                          │  │
│  │                                                        │  │
│  │   ┌──────────┐      ┌───────────────────────────────┐  │  │
│  │   │  Nginx   │ ───► │  /usr/share/nginx/html/       │  │  │
│  │   │  :80     │      │  ├── index.html               │  │  │
│  │   └──────────┘      │  ├── main.js                  │  │  │
│  │                     │  ├── styles.css               │  │  │
│  │                     │  └── assets/                  │  │  │
│  │                     └───────────────────────────────┘  │  │
│  └────────────────────────────────────────────────────────┘  │
│                              │                               │
│                         Puerto 80                            │
└──────────────────────────────┼───────────────────────────────┘
                               │
                               ▼
                    IP Pública: 129.154.xxx.xxx
                               │
                               ▼
               DuckDNS: tuproyecto-des.duckdns.org
                               │
                               ▼
                    Usuario escribe en navegador:
                    http://tuproyecto-des.duckdns.org
                               │
                               ▼
                    Ve la landing page
```

---

## Flujo completo

```
Tu PC                           Internet                    Servidor
──────                          ────────                    ────────

1. npm run remote:des
   │
   ├─► Lint ✓
   ├─► Tests ✓
   ├─► docker build
   │
   ▼
2. docker save (.tar)
   │
   └──────────► scp ──────────────────────────────►  ~/app/angular-app-des.tar
                                                           │
3.                              ssh ──────────────────────►│
                                                           ▼
                                                     docker load
                                                     docker run -p 80:80
                                                           │
                                                           ▼
4.                         ◄───────────────────────  Nginx sirviendo en :80
                                                           │
                           tuproyecto-des.duckdns.org ─────┘
```

---

## ¿Por qué Docker y no git pull?

| Método | Ventaja | Desventaja |
|--------|---------|------------|
| **Docker image** | Servidor solo necesita Docker, imagen idéntica a local, reproducible | Transferir ~30MB |
| **Git pull + build** | Menos transferencia inicial | Servidor necesita Node, npm, puede fallar el build |

Usamos Docker porque:
1. El servidor solo necesita Docker instalado
2. La imagen es idéntica a lo que probaste en local
3. No hay sorpresas de "funciona en mi máquina"
4. Rollback fácil: volver a la imagen anterior

---

## Comandos disponibles

### Despliegue local (docker-compose)

```bash
npm run deploy:des      # Deploy a DES local (localhost:4200)
npm run deploy:pre      # Deploy a PRE local (localhost:4300)
npm run deploy:pro      # Deploy a PRO local (localhost:4400)
npm run deploy:check    # Solo verificar calidad
npm run deploy:status   # Ver estado de contenedores
```

### Despliegue remoto (VPS)

```bash
npm run remote:des      # Deploy a servidor DES
npm run remote:pre      # Deploy a servidor PRE
npm run remote:pro      # Deploy a servidor PRO
npm run remote:status   # Ver estado de servidores remotos
npm run remote:setup    # Configurar un servidor nuevo
```

---

## Requisitos para despliegue remoto

1. **Servidores VPS** con Ubuntu y Docker instalado
2. **Dominios** apuntando a las IPs de los servidores (ej: DuckDNS)
3. **SSH keys** configuradas para acceso sin contraseña
4. **Archivo de configuración** `~/.servers-config` con los datos de conexión

Ver `docs/VPS-DEPLOYMENT-GUIDE.md` para la guía completa de configuración.
