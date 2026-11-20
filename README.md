# 🏆 vifutbol

**vifutbol** es una plataforma integral para la gestión de campeonatos de fútbol, diseñada para centralizar la organización deportiva y proporcionar una fuente de verdad transparente para todos los actores involucrados.

La aplicación permite gestionar desde la creación del torneo y el registro de jugadores, hasta el seguimiento en tiempo real de resultados, estadísticas detalladas y la logística de partidos dentro de una ciudad.

## 🏟️ Características Principales

- **Gestión de Campeonatos:** Creación de múltiples tipos de torneos (ligas, copas eliminatorias) con reglas personalizadas.
- **Control de Resultados y Estadística:** Registro preciso de goles, asistencias y tarjetas con cálculo automático de tablas de posiciones.
... **Seguimiento Multicanal:** Visualización de estadísticas de jugadores, historial de partidos y cronogramas detallados.
- **Geolocalización Deportiva:** Gestión de sedes y canchas locales en el contexto urbano.
- **Actualizaciones en Tiempo Real:** Feed de noticias, alertas de próximos partidos y estados del torneo.

## 👥 Roles del Sistema

| Rol | Responsabilidades Clave |
| :--- | :--- |
| **Organizador** | Configuración de torneos, reglas, registro oficial de equipos/jugadores y gestión de sedes. |
| **Entrenador** | Gestión del equipo, listado de convocatorias y seguimiento interno de rendimiento. |
| **Árbitro** | Reporte oficial de resultados, goles, asistencias y tarjetas en tiempo real. |
| **Jugador** | Perfilo personal de rendimiento, visualización de estadísticas propias y del equipo. |
| **Aficionado** | Consulta de tablas de posiciones, noticias, resultados y calendario público. |

## 🛠️ Infraestructura Tecnológica

- **Base de Datos:** Supabase (PostgreSQL).
- **Despliegue:** Servidor remoto accesible vía VPN (oracle free tier VM).
- **Enfoque de Desarrollo:** Énfasis en la integridad relacional de los datos y el rendimiento de las consultas SQL para estadísticas deportivas.

## 🚀 Guía del Agente y Constitución

Este proyecto sigue un flujo de trabajo estructurado para garantizar la calidad del código y la integridad de los datos:

- **`agents.md`**: Contiene el contexto general del proyecto y las directrices de la IA.
- **`constitution.md`**: Define los principios innegociables (La Spec manda, Integridad de Datos, Tests como Puerta).
- **Metodología**: El desarrollo se realiza mediante la creación de especificaciones detalladas (**Specs**) que deben ser completadas y validadas con pruebas antes de avanzar.


## 🏗️ Arquitectura

El proyecto implementa bajo las directrices de mobiaia.ai y sus skills de arquitectura.

## 🚀 Setup

**Requisitos:** Flutter ≥ 3.11.0 · Dart ≥ 3.11.0

```bash
# 1. Clonar el repositorio
git clone <repo-url>
cd valora_code

# 2. Instalar dependencias
flutter pub get

# 3. Ejecutar en modo debug
flutter run
```

La aplicacion tiene diferentes ambientes para desarrollo y produccion.

*   **Development (Oracle Cloud):** `flutter run --flavor dev --target lib/env/main.dev.dart --dart-define-from-file=.env.dev`
*   **Production (Supabase Cloud):** `flutter run --flavor prod --target lib/env/main.prod.dart --dart-define-from-file=.env.prod`
*   **Modo Local / Offline (sin backend remoto):** `flutter run --flavor dev --target lib/env/main.dev.dart` (si se omiten las variables o el servidor no es alcanzable, la app conmuta automáticamente a almacenamiento local con Hive sin bloquear la experiencia de usuario).

### ⚙️ Configuración de Variables de Entorno (Supabase)

El suministro de credenciales se gestiona de forma aislada por entorno utilizando archivos `.env.dev` y `.env.prod` (ignorados por git):

1. **Desarrollo (Servidor Oracle Cloud Self-Hosted):**
   ```bash
   cp .env.dev.example .env.dev
   ```
   Configura las variables correspondientes al host de desarrollo (`https://supabase.artbusinesstechnology.com`) y ejecuta:
   ```bash
   flutter run --flavor dev --target lib/env/main.dev.dart --dart-define-from-file=.env.dev
   ```

2. **Producción (Servidor Oficial Supabase Cloud):**
   ```bash
   cp .env.prod.example .env.prod
   ```
   Configura las credenciales de tu proyecto de producción (`https://<project-ref>.supabase.co`) y ejecuta:
   ```bash
   flutter run --flavor prod --target lib/env/main.prod.dart --dart-define-from-file=.env.prod
   ```

---

## 🧪 Tests

```bash
# Correr todos los tests
flutter test

# Con cobertura
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

**90 tests** cubriendo: modelos del dominio, casos de uso, providers y adaptadores de infraestructura.

---

## 📦 Dependencias principales

| Paquete | Uso |
|---|---|
| `supabase_flutter: ^2.18.3` | coneccion a backend |
| `riverpod: ^3.4.3` | Gestión de estado |
| `hive ^2.3.2` + `hive_flutter` | Persistencia local offline |
| `fluro: ^2.0.5` | Navegación |
| `file_picker ^10.0.2` | Importar backup desde el sistema de archivos |
| `uuid ^4.6.0` | Generación de IDs únicos |
| `mocktail ^1.2.1` | Mocks en tests |

---

## 🎨 Diseño

- Basate en DESING.md en la raiz del proyecto.


---

## 🚀 CI/CD, Firmado Android y Firebase App Distribution (DEV / PROD)

El repositorio cuenta con pipelines automatizados en GitHub Actions que ejecutan `flutter analyze` y `flutter test` como puerta de calidad obligatoria antes de compilar y distribuir APKs firmados:

- **DEV (`develop`)**: `.github/workflows/ci-cd-dev.yml` → Compila `--flavor dev -t lib/main_dev.dart` (`com.vifutbol.vifutbol.dev`, etiqueta `vifutbol DEV`, banner DEV visible) y distribuye al grupo `testers-dev`.
- **PROD (`main`)**: `.github/workflows/ci-cd-prod.yml` → Compila `--flavor prod -t lib/main_prod.dart` (`com.vifutbol.vifutbol`, etiqueta `vifutbol`, sin banner DEV) y distribuye al grupo `testers-prod`.

### 1. Generar el Keystore de Release y convertirlo a Base64

```bash
keytool -genkey -v -keystore upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

Convierte el archivo `.jks` a una sola línea Base64 para guardarlo como secreto:

```bash
# macOS
base64 -i upload-keystore.jks | tr -d '\n' | pbcopy

# Linux
base64 -w 0 upload-keystore.jks
```

> ⚠️ Nunca subas `*.jks`, `*.keystore`, `android/key.properties`, `.env.dev` ni `.env.prod` a Git (están bloqueados en `.gitignore`).

### 2. Configurar Firebase App Distribution

1. En **Firebase Console**, registra **dos apps Android** para permitir instalación en paralelo en el mismo dispositivo:
   - **DEV**: package name `com.vifutbol.vifutbol.dev` → copia su **App ID** en `FIREBASE_APP_ID_DEV`.
   - **PROD**: package name `com.vifutbol.vifutbol` → copia su **App ID** en `FIREBASE_APP_ID_PROD`.
2. En **App Distribution → Testers & Groups**, crea los grupos `testers-dev` y `testers-prod`.
3. En **Google Cloud IAM / Firebase**, crea una Service Account con rol **Firebase App Distribution Admin**, descarga su clave JSON y guárdala en `FIREBASE_SERVICE_ACCOUNT_JSON`.

### 3. GitHub Secrets requeridos (`Settings → Secrets and variables → Actions`)

| Categoría | Nombre del Secret | Propósito |
|---|---|---|
| **Entorno DEV** | `ENV_DEV_FILE` | Contenido completo multilínea de `.env.dev` |
| **Entorno PROD** | `ENV_PROD_FILE` | Contenido completo multilínea de `.env.prod` |
| **Firma Android** | `ANDROID_KEYSTORE_BASE64` | Keystore `.jks` codificado en Base64 (sin saltos de línea) |
| **Firma Android** | `ANDROID_KEYSTORE_PASSWORD` | Contraseña del keystore (`storePassword`) |
| **Firma Android** | `ANDROID_KEY_PASSWORD` | Contraseña del alias (`keyPassword`) |
| **Firma Android** | `ANDROID_KEY_ALIAS` | Alias de la llave (ej. `upload`) |
| **Firebase** | `FIREBASE_SERVICE_ACCOUNT_JSON` | JSON completo de la Service Account con rol App Distribution Admin |
| **Firebase** | `FIREBASE_APP_ID_DEV` | App ID de Android DEV (`com.vifutbol.vifutbol.dev`) |
| **Firebase** | `FIREBASE_APP_ID_PROD` | App ID de Android PROD (`com.vifutbol.vifutbol`) |
