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

*   **Development:** `flutter run --flavor dev --target lib/env/main.dev.dart --dart-define=SUPABASE_URL=https://supabase.artbusinesstechnology.com --dart-define=SUPABASE_ANON_KEY=<tu_anon_key>`
*   **Modo Local / Offline (sin backend remoto):** `flutter run --flavor dev --target lib/env/main.dev.dart` (si se omiten las variables o el servidor no es alcanzable, la app conmuta automáticamente a almacenamiento local con Hive sin bloquear la experiencia de usuario).
*   **Production:** `flutter run --flavor prod --target lib/env/main.prod.dart --dart-define=SUPABASE_URL=<prod_url> --dart-define=SUPABASE_ANON_KEY=<prod_anon_key>`

### ⚙️ Configuración de Variables de Entorno (Supabase)
Copia la plantilla de variables de entorno `.env.example` a `.env` (ignorado en git):
```bash
cp .env.example .env
```
Y ejecuta inyectando los valores:
```bash
flutter run --flavor dev --target lib/env/main.dev.dart \
  --dart-define=SUPABASE_URL=https://supabase.artbusinesstechnology.com \
  --dart-define=SUPABASE_ANON_KEY=tu_dev_anon_key
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
