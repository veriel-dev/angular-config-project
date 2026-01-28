# Plan: Angular 14 Landing Page con Multi-Entorno y CI/CD

## Resumen

Crear un proyecto Angular 14 con una landing page estática simple, configurando tres entornos (DES, PRE, PRO) y pipelines de CI/CD que requieran un 80% de cobertura de tests para promocionar entre entornos.

---

## 1. Estructura del Proyecto

```
angular-config-project/
├── src/
│   ├── app/
│   │   ├── components/
│   │   │   ├── header/
│   │   │   ├── hero/
│   │   │   ├── features/
│   │   │   ├── cta/
│   │   │   └── footer/
│   │   ├── app.component.ts
│   │   ├── app.component.html
│   │   ├── app.component.spec.ts
│   │   └── app.module.ts
│   ├── environments/
│   │   ├── environment.ts          # Local (default)
│   │   ├── environment.des.ts      # Desarrollo
│   │   ├── environment.pre.ts      # Preproducción
│   │   └── environment.pro.ts      # Producción
│   ├── assets/
│   ├── styles.css
│   ├── index.html
│   └── main.ts
├── .github/
│   └── workflows/
│       ├── deploy-des.yml          # Deploy a DES (push a develop)
│       ├── deploy-pre.yml          # Deploy a PRE (requiere 80% coverage)
│       └── deploy-pro.yml          # Deploy a PRO (requiere 80% coverage)
├── angular.json
├── package.json
├── karma.conf.js
├── tsconfig.json
└── README.md
```

---

## 2. Configuración de Entornos

### Variables por entorno

| Variable | DES | PRE | PRO |
|----------|-----|-----|-----|
| `production` | false | false | true |
| `apiUrl` | `https://api-des.example.com` | `https://api-pre.example.com` | `https://api.example.com` |
| `envName` | `DES` | `PRE` | `PRO` |
| `analyticsEnabled` | false | false | true |

### Configuración en angular.json

Se añadirán configuraciones de build para cada entorno:
- `des` → reemplaza environment.ts con environment.des.ts
- `pre` → reemplaza environment.ts con environment.pre.ts
- `pro` → reemplaza environment.ts con environment.pro.ts

---

## 3. Landing Page - Componentes (Portfolio/Agencia)

Landing estática para agencia/portfolio con secciones:

1. **Header** - Logo de la agencia + navegación (Servicios, Proyectos, Contacto)
2. **Hero** - Headline impactante + subtítulo + CTA "Ver proyectos"
3. **Services** - Grid de 3-4 servicios que ofrece la agencia (cards con icono)
4. **Projects** - Showcase de 3 proyectos destacados (imágenes + descripción)
5. **About** - Breve descripción de la agencia + stats (años, proyectos, clientes)
6. **Contact** - CTA final con formulario simple o enlace de contacto
7. **Footer** - Copyright, redes sociales, enlaces legales

Estilos con **Tailwind CSS** integrado en el build process de Angular.

---

## 4. Estrategia de Testing

### Configuración de Karma/Jasmine
- Cobertura mínima requerida: **80%**
- Reportes: HTML + lcov (para CI)

### karma.conf.js - Thresholds
```javascript
coverageReporter: {
  check: {
    global: {
      statements: 80,
      branches: 80,
      functions: 80,
      lines: 80
    }
  }
}
```

### Tests por componente
- Cada componente tendrá su archivo `.spec.ts`
- Tests unitarios para renderizado y comportamiento básico

---

## 5. Pipelines CI/CD (GitHub Actions) + Netlify

### Estrategia de Despliegue con Netlify

Se crearán **3 sites en Netlify**, uno por entorno:
- `proyecto-des.netlify.app` → Desarrollo
- `proyecto-pre.netlify.app` → Preproducción
- `proyecto-pro.netlify.app` → Producción

Cada site tendrá su propio `NETLIFY_SITE_ID` configurado como secret en GitHub.

### 5.1 deploy-des.yml
- **Trigger**: Push a rama `develop`
- **Pasos**:
  1. Checkout
  2. Setup Node 16
  3. pnpm install
  4. Ejecutar tests
  5. Build con configuración `des`
  6. Deploy a Netlify (site DES)

### 5.2 deploy-pre.yml
- **Trigger**: Manual (workflow_dispatch) o merge a `release/*`
- **Gate**: Cobertura >= 80%
- **Pasos**:
  1. Checkout
  2. Setup Node 16
  3. pnpm install
  4. Ejecutar tests con cobertura
  5. **Verificar cobertura >= 80%** (falla si no cumple)
  6. Build con configuración `pre`
  7. Deploy a Netlify (site PRE)

### 5.3 deploy-pro.yml
- **Trigger**: Manual (workflow_dispatch) desde `main`
- **Gate**: Cobertura >= 80% + Aprobación manual
- **Pasos**:
  1. Checkout
  2. Setup Node 16
  3. pnpm install
  4. Ejecutar tests con cobertura
  5. **Verificar cobertura >= 80%** (falla si no cumple)
  6. Build con configuración `pro`
  7. Deploy a Netlify (site PRO)

### Secrets necesarios en GitHub
```
NETLIFY_AUTH_TOKEN    # Token de API de Netlify
NETLIFY_SITE_ID_DES   # Site ID para DES
NETLIFY_SITE_ID_PRE   # Site ID para PRE
NETLIFY_SITE_ID_PRO   # Site ID para PRO
```

---

## 6. Scripts en package.json

```json
{
  "scripts": {
    "start": "ng serve",
    "build": "ng build",
    "build:des": "ng build --configuration=des",
    "build:pre": "ng build --configuration=pre",
    "build:pro": "ng build --configuration=pro",
    "test": "ng test --no-watch --no-progress --code-coverage",
    "test:watch": "ng test",
    "lint": "ng lint"
  }
}
```

---

## 7. Pasos de Implementación

1. **Inicializar proyecto Angular 14**
   - `pnpm dlx @angular/cli@14 new angular-config-project --directory=. --routing=false --style=css`

2. **Configurar entornos**
   - Crear archivos environment.des.ts, environment.pre.ts, environment.pro.ts
   - Modificar angular.json con las configuraciones de build

3. **Integrar Tailwind CSS**
   - Instalar dependencias
   - Configurar tailwind.config.js y postcss

4. **Crear componentes de la landing**
   - Header, Hero, Features, CTA, Footer
   - Cada uno con su test unitario

5. **Configurar testing con cobertura**
   - Ajustar karma.conf.js con thresholds del 80%

6. **Crear workflows de GitHub Actions**
   - deploy-des.yml, deploy-pre.yml, deploy-pro.yml

7. **Inicializar repositorio Git**
   - git init, .gitignore, commit inicial

---

## 8. Verificación

- [ ] `pnpm install` completa sin errores
- [ ] `pnpm test` ejecuta tests y genera reporte de cobertura
- [ ] `pnpm build:des` genera build para DES
- [ ] `pnpm build:pre` genera build para PRE
- [ ] `pnpm build:pro` genera build para PRO
- [ ] Cobertura de tests >= 80%
- [ ] Workflows de GitHub Actions validan sintaxis correcta

---

## 9. Archivos Críticos a Crear

| Archivo | Descripción |
|---------|-------------|
| `angular.json` | Configuración de builds por entorno |
| `src/environments/*.ts` | Variables de entorno |
| `karma.conf.js` | Thresholds de cobertura |
| `.github/workflows/*.yml` | Pipelines CI/CD |
| `src/app/components/**` | Componentes de la landing |
