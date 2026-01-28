# Solicitud de Servidores

**Proyecto**: [Nombre del proyecto]
**Solicitante**: [Tu nombre]
**Fecha**: [Fecha]

---

## Qué necesitamos

**3 servidores** para desplegar una aplicación web en tres entornos:

| Entorno | Uso |
|---------|-----|
| DES (Desarrollo) | Pruebas del equipo de desarrollo |
| PRE (Preproducción) | Validación antes de producción |
| PRO (Producción) | Usuarios finales |

---

## Tipo de aplicación

- **Frontend**: Aplicación Angular (se sirve como web estática)
- **Autenticación**: Login con Azure AD (se configurará después)
- **Conexiones externas**: Llamadas a una API backend (URL pendiente de definir)

---

## Lo que necesitamos de vosotros

1. **3 servidores** con capacidad para ejecutar contenedores Docker
2. **3 subdominios** corporativos, uno por entorno (ej: app-des, app-pre, app)
3. **Acceso SSH** para poder desplegar
4. **Puertos 80 y 443** abiertos para tráfico web

---

## Lo que NO necesitamos que hagáis

- No necesitamos que instaléis la aplicación (lo haremos nosotros)
- No necesitamos base de datos (la app no usa BD propia)
- No necesitamos configurar Azure AD (lo haremos con otro equipo cuando tengamos los dominios)

---

## Preguntas que probablemente tengáis

**¿Qué sistema operativo?**
El que uséis habitualmente. Ubuntu está bien.

**¿Cuánta RAM/CPU?**
Lo que consideréis estándar para una web pequeña. El entorno de producción quizás un poco más.

**¿Necesitáis algo especial?**
Solo Docker instalado. El resto lo gestionamos nosotros.

---

## Contacto

[Tu nombre] - [tu email]

Cualquier duda, preguntadme.
