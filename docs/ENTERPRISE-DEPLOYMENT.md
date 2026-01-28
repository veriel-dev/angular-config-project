# Despliegue en Entorno Empresarial

Este documento describe cómo sería la arquitectura y el flujo de despliegue de esta aplicación en un entorno empresarial real.

---

## Arquitectura Típica

```
                         ┌─────────────────┐
                         │   Load Balancer │
                         │  (AWS ALB/Nginx)│
                         └────────┬────────┘
                                  │
         ┌────────────────────────┼────────────────────────┐
         │                        │                        │
         ▼                        ▼                        ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   DES Server    │    │   PRE Server    │    │   PRO Server    │
│  (dev.empresa)  │    │ (pre.empresa)   │    │  (www.empresa)  │
│                 │    │                 │    │                 │
│  ┌───────────┐  │    │  ┌───────────┐  │    │  ┌───────────┐  │
│  │  Docker   │  │    │  │  Docker   │  │    │  │  Docker   │  │
│  │  Swarm /  │  │    │  │  Swarm /  │  │    │  │  Swarm /  │  │
│  │  K8s      │  │    │  │  K8s      │  │    │  │  K8s      │  │
│  └───────────┘  │    │  └───────────┘  │    │  └───────────┘  │
└─────────────────┘    └─────────────────┘    └─────────────────┘
        │                      │                      │
        └──────────────────────┼──────────────────────┘
                               │
                    ┌──────────┴──────────┐
                    │  Container Registry │
                    │  (ECR/GCR/Harbor)   │
                    └──────────┬──────────┘
                               │
                    ┌──────────┴──────────┐
                    │    CI/CD Pipeline   │
                    │  (Jenkins/GitLab/   │
                    │   GitHub Actions)   │
                    └─────────────────────┘
```

---

## Componentes Clave

| Componente | Opciones | Función |
|------------|----------|---------|
| **Orquestador** | Kubernetes, Docker Swarm, AWS ECS | Gestiona contenedores, scaling automático, health checks |
| **Container Registry** | AWS ECR, Google GCR, Harbor, Nexus | Almacena imágenes Docker versionadas |
| **CI/CD** | Jenkins, GitLab CI, GitHub Actions, Azure DevOps | Automatiza build, test, deploy |
| **Secrets Management** | HashiCorp Vault, AWS Secrets Manager, Azure Key Vault | Gestiona credenciales y certificados |
| **Monitoring** | Prometheus + Grafana, Datadog, New Relic | Métricas, dashboards y alertas |
| **Logging** | ELK Stack (Elasticsearch, Logstash, Kibana), Loki, Splunk | Centraliza y analiza logs |
| **Load Balancer** | Nginx, AWS ALB, Traefik, HAProxy | Distribuye tráfico, SSL termination |
| **CDN** | CloudFront, Cloudflare, Akamai | Cache de assets estáticos |

---

## Flujo de Despliegue Empresarial

```
1. Developer → Push a develop
        ↓
2. CI Pipeline:
   - Ejecuta linting
   - Ejecuta tests unitarios
   - Verifica cobertura (>= 80%)
   - Análisis de seguridad (SAST)
   - Build imagen Docker
   - Push a Registry (tag: commit-sha + latest-des)
        ↓
3. Deploy a DES (automático)
   - Pull imagen del registry
   - Rolling update en el cluster
   - Health check verification
   - Smoke tests automáticos
        ↓
4. QA valida en DES
   - Tests manuales
   - Tests de regresión
        ↓
5. Merge a release/* → Deploy a PRE
   - Requiere aprobación de Tech Lead
   - Tests de integración (E2E)
   - Tests de carga/rendimiento
   - Tests de seguridad (DAST)
        ↓
6. QA/Product valida en PRE
   - User Acceptance Testing (UAT)
   - Validación de producto
        ↓
7. Merge a main → Deploy a PRO
   - Requiere múltiples aprobaciones (QA + Product + Tech Lead)
   - Blue/Green deployment o Canary release
   - Monitorización intensiva post-deploy
   - Rollback automático si fallan health checks
```

---

## Estrategias de Despliegue en Producción

### Blue/Green Deployment

```
┌─────────────────────────────────────────────────────────┐
│                    Load Balancer                        │
└─────────────────────┬───────────────────────────────────┘
                      │
         ┌────────────┴────────────┐
         │                         │
         ▼                         ▼
┌─────────────────┐      ┌─────────────────┐
│   BLUE (v1.0)   │      │  GREEN (v1.1)   │
│   [ACTIVE]      │      │  [STANDBY]      │
│                 │      │                 │
│  100% traffic   │      │   0% traffic    │
└─────────────────┘      └─────────────────┘

Después del switch:

┌─────────────────┐      ┌─────────────────┐
│   BLUE (v1.0)   │      │  GREEN (v1.1)   │
│   [STANDBY]     │      │  [ACTIVE]       │
│                 │      │                 │
│   0% traffic    │      │  100% traffic   │
└─────────────────┘      └─────────────────┘
```

**Ventajas:**
- Rollback instantáneo
- Zero downtime
- Fácil de implementar

**Desventajas:**
- Requiere doble infraestructura
- Mayor coste

### Canary Deployment

```
┌─────────────────────────────────────────────────────────┐
│                    Load Balancer                        │
└─────────────────────┬───────────────────────────────────┘
                      │
         ┌────────────┴────────────┐
         │                         │
         ▼                         ▼
┌─────────────────┐      ┌─────────────────┐
│  STABLE (v1.0)  │      │  CANARY (v1.1)  │
│                 │      │                 │
│   95% traffic   │      │   5% traffic    │
└─────────────────┘      └─────────────────┘

Progresión gradual: 5% → 25% → 50% → 100%
```

**Ventajas:**
- Menor riesgo
- Detecta problemas con tráfico real
- Rollback rápido

**Desventajas:**
- Más complejo de implementar
- Requiere buena observabilidad

---

## Configuración de Kubernetes (Ejemplo)

### Deployment

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: angular-app
  namespace: production
spec:
  replicas: 3
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0
  selector:
    matchLabels:
      app: angular-app
  template:
    metadata:
      labels:
        app: angular-app
        version: v1.0.0
    spec:
      containers:
      - name: angular-app
        image: registry.empresa.com/angular-app:v1.0.0
        ports:
        - containerPort: 80
        resources:
          requests:
            memory: "128Mi"
            cpu: "100m"
          limits:
            memory: "256Mi"
            cpu: "200m"
        livenessProbe:
          httpGet:
            path: /health
            port: 80
          initialDelaySeconds: 10
          periodSeconds: 30
        readinessProbe:
          httpGet:
            path: /health
            port: 80
          initialDelaySeconds: 5
          periodSeconds: 10
```

### Service

```yaml
apiVersion: v1
kind: Service
metadata:
  name: angular-app-service
  namespace: production
spec:
  selector:
    app: angular-app
  ports:
  - port: 80
    targetPort: 80
  type: ClusterIP
```

### Ingress

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: angular-app-ingress
  namespace: production
  annotations:
    kubernetes.io/ingress.class: nginx
    cert-manager.io/cluster-issuer: letsencrypt-prod
spec:
  tls:
  - hosts:
    - www.empresa.com
    secretName: angular-app-tls
  rules:
  - host: www.empresa.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: angular-app-service
            port:
              number: 80
```

---

## Pipeline CI/CD (GitHub Actions - Empresarial)

```yaml
name: Enterprise CI/CD Pipeline

on:
  push:
    branches: [develop, release/*, main]
  pull_request:
    branches: [develop, main]

env:
  REGISTRY: registry.empresa.com
  IMAGE_NAME: angular-app

jobs:
  # ============================================
  # STAGE 1: Build & Test
  # ============================================
  build-and-test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '18'
          cache: 'npm'

      - name: Install dependencies
        run: npm ci

      - name: Lint
        run: npm run lint

      - name: Test with coverage
        run: npm run test -- --browsers=ChromeHeadless

      - name: Check coverage threshold
        run: |
          COVERAGE=$(cat coverage/angular-config-project/coverage-summary.json | jq '.total.lines.pct')
          if (( $(echo "$COVERAGE < 80" | bc -l) )); then
            echo "Coverage $COVERAGE% is below 80%"
            exit 1
          fi

      - name: Security scan (SAST)
        uses: snyk/actions/node@master
        with:
          args: --severity-threshold=high

  # ============================================
  # STAGE 2: Build Docker Image
  # ============================================
  build-image:
    needs: build-and-test
    runs-on: ubuntu-latest
    outputs:
      image-tag: ${{ steps.meta.outputs.tags }}
    steps:
      - uses: actions/checkout@v4

      - name: Set environment
        id: set-env
        run: |
          if [[ $GITHUB_REF == refs/heads/develop ]]; then
            echo "ENV=des" >> $GITHUB_OUTPUT
          elif [[ $GITHUB_REF == refs/heads/release/* ]]; then
            echo "ENV=pre" >> $GITHUB_OUTPUT
          elif [[ $GITHUB_REF == refs/heads/main ]]; then
            echo "ENV=pro" >> $GITHUB_OUTPUT
          fi

      - name: Login to Registry
        uses: docker/login-action@v3
        with:
          registry: ${{ env.REGISTRY }}
          username: ${{ secrets.REGISTRY_USERNAME }}
          password: ${{ secrets.REGISTRY_PASSWORD }}

      - name: Build and push
        uses: docker/build-push-action@v5
        with:
          context: .
          push: true
          build-args: |
            ENVIRONMENT=${{ steps.set-env.outputs.ENV }}
          tags: |
            ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:${{ github.sha }}
            ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:latest-${{ steps.set-env.outputs.ENV }}

  # ============================================
  # STAGE 3: Deploy to DES (automatic)
  # ============================================
  deploy-des:
    needs: build-image
    if: github.ref == 'refs/heads/develop'
    runs-on: ubuntu-latest
    environment: development
    steps:
      - name: Deploy to Kubernetes (DES)
        uses: azure/k8s-deploy@v4
        with:
          namespace: development
          manifests: |
            k8s/deployment.yaml
            k8s/service.yaml
          images: |
            ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:${{ github.sha }}

  # ============================================
  # STAGE 4: Deploy to PRE (requires approval)
  # ============================================
  deploy-pre:
    needs: build-image
    if: startsWith(github.ref, 'refs/heads/release/')
    runs-on: ubuntu-latest
    environment:
      name: preproduction
      url: https://pre.empresa.com
    steps:
      - name: Deploy to Kubernetes (PRE)
        uses: azure/k8s-deploy@v4
        with:
          namespace: preproduction
          manifests: |
            k8s/deployment.yaml
            k8s/service.yaml
          images: |
            ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:${{ github.sha }}

      - name: Run E2E tests
        run: npm run test:e2e

      - name: Run load tests
        run: npm run test:load

  # ============================================
  # STAGE 5: Deploy to PRO (requires multiple approvals)
  # ============================================
  deploy-pro:
    needs: build-image
    if: github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest
    environment:
      name: production
      url: https://www.empresa.com
    steps:
      - name: Blue/Green Deploy to Kubernetes (PRO)
        uses: azure/k8s-deploy@v4
        with:
          namespace: production
          strategy: blue-green
          manifests: |
            k8s/deployment.yaml
            k8s/service.yaml
          images: |
            ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:${{ github.sha }}

      - name: Smoke tests
        run: |
          curl -f https://www.empresa.com/health || exit 1

      - name: Notify deployment
        uses: slackapi/slack-github-action@v1
        with:
          payload: |
            {
              "text": "Deployed to production: ${{ github.sha }}"
            }
```

---

## Herramientas Recomendadas por Área

### Infraestructura como Código (IaC)

| Herramienta | Uso |
|-------------|-----|
| **Terraform** | Provisionar infraestructura cloud |
| **Pulumi** | IaC con lenguajes de programación |
| **AWS CDK** | IaC específico para AWS |
| **Ansible** | Configuración de servidores |

### Seguridad

| Herramienta | Uso |
|-------------|-----|
| **Snyk** | Análisis de vulnerabilidades en dependencias |
| **SonarQube** | Análisis de código estático |
| **Trivy** | Escaneo de imágenes Docker |
| **OWASP ZAP** | Tests de seguridad dinámicos |

### Observabilidad

| Herramienta | Uso |
|-------------|-----|
| **Prometheus** | Métricas |
| **Grafana** | Dashboards |
| **Jaeger** | Distributed tracing |
| **PagerDuty** | Alertas y on-call |

---

## Costes Estimados (AWS)

| Componente | Servicio AWS | Coste mensual aprox. |
|------------|--------------|---------------------|
| Kubernetes | EKS | ~$73 (control plane) |
| Nodos (3x t3.medium) | EC2 | ~$90 |
| Load Balancer | ALB | ~$20 |
| Container Registry | ECR | ~$5 |
| Monitoring | CloudWatch | ~$10 |
| **Total DES** | | **~$200/mes** |
| **Total PRE** | | **~$200/mes** |
| **Total PRO** | | **~$400/mes** (HA) |

*Nota: Los costes varían según región y uso.*

---

## Checklist de Producción

- [ ] SSL/TLS configurado con renovación automática
- [ ] Health checks configurados
- [ ] Autoscaling configurado (HPA en K8s)
- [ ] Backups automatizados
- [ ] Logs centralizados
- [ ] Métricas y alertas configuradas
- [ ] Runbooks documentados
- [ ] Plan de disaster recovery
- [ ] Tests de carga ejecutados
- [ ] Análisis de seguridad pasado
- [ ] Documentación actualizada
