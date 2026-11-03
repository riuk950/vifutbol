<!--
Sync Impact Report
- Version change: 1.1.0 → 2.0.0
- Modified principles:
  - II. Integridad Relacional y Fuente de Verdad Transparente (NON-NEGOTIABLE) → II. Integridad de Datos y Fuente de Verdad Transparente (NON-NEGOTIABLE) (decoupled from specific database/storage engines)
  - III. Tests como Puerta de Calidad (NON-NEGOTIABLE) → III. Pruebas Automatizadas como Puerta de Calidad (NON-NEGOTIABLE) (decoupled from specific test runners and mocking libraries)
  - IV. Arquitectura por Capas y Separación de Responsabilidades → IV. Arquitectura Limpia y Separación de Responsabilidades (decoupled from specific state, routing, and persistence libraries)
  - VII. Resiliencia y Experiencia Móvil (docs/MOBILE_GUIDELINES.md) → VII. Resiliencia y Experiencia Móvil (docs/MOBILE_GUIDELINES.md) (decoupled from specific storage tools)
- Modified sections:
  - Stack Tecnológico y Entornos de Ejecución → Restricciones Arquitectónicas y Entornos Operativos (made 100% technology-agnostic)
  - Flujo de Desarrollo y Puertas de Calidad → Flujo de Desarrollo y Puertas de Calidad (removed framework-specific CLI commands)
- Removed sections:
  - Technology-specific package, SDK, database, and infrastructure bindings
- Follow-up TODOs: None
-->
# vifutbol Constitution

## Core Principles

### I. La Spec Manda (Spec-Driven Development) (NON-NEGOTIABLE)
Toda funcionalidad, cambio arquitectónico o regla de campeonato DEBE originarse en una especificación detallada (`spec.md`, `plan.md`, `tasks.md`) antes de escribir código de producción. Al redactar `spec.md`, DEBEN evaluarse los puntos aplicables de `docs/MOBILE_GUIDELINES.md` y, si falta definir un comportamiento, consultarlo antes de asumirlo. Ningún cambio de código DEBE implementarse fuera del alcance definido y validado en la especificación activa.

*Justificación*: Garantiza la alineación exacta entre las reglas deportivas (ligas, copas eliminatorias, cálculo de estadísticas y logística de sedes), el comportamiento móvil y la implementación, evitando desviaciones de alcance y retrabajo.

### II. Integridad de Datos y Fuente de Verdad Transparente (NON-NEGOTIABLE)
El modelo de datos DEBE garantizar integridad referencial estricta entre torneos, equipos, jugadores, partidos, goles, asistencias, tarjetas y sedes geolocalizadas. Las tablas de posiciones y métricas de rendimiento DEBEN calcularse de forma determinista a partir de los eventos oficiales registrados, manteniendo consistencia entre el almacenamiento remoto y el almacenamiento local offline.

*Justificación*: `vifutbol` centraliza la organización deportiva como única fuente de verdad transparente para todos los actores; cualquier inconsistencia en resultados o estadísticas compromete la credibilidad del campeonato.

### III. Pruebas Automatizadas como Puerta de Calidad (NON-NEGOTIABLE)
Todo modelo del dominio, caso de uso, gestor de estado y adaptador de infraestructura DEBE contar con pruebas automatizadas que verifiquen su comportamiento de forma aislada antes de dar por completada una tarea. Ninguna especificación DEBE marcarse como finalizada si la suite de pruebas falla o carece de cobertura sobre la nueva lógica introducida.

*Justificación*: Protege el cálculo automático de tablas de posiciones, las reglas de negocio de los torneos y la sincronización de datos frente a regresiones.

### IV. Arquitectura Limpia y Separación de Responsabilidades
El sistema DEBE estructurarse en capas claramente desacopladas (Dominio, Casos de Uso, Gestión de Estado/Presentación e Infraestructura). La capa de dominio NO DEBE depender de detalles de infraestructura (bases de datos, red, almacenamiento local) ni de la interfaz de usuario.

*Justificación*: Permite validar las reglas deportivas con independencia de la tecnología subyacente, facilita el mantenimiento y permite evolucionar o sustituir adaptadores sin afectar el núcleo del negocio.

### V. Segregación de Roles y Fidelidad al Sistema de Diseño
Cada flujo funcional DEBE hacer cumplir estrictamente los permisos correspondientes a los cinco roles del sistema (`Organizador`, `Entrenador`, `Árbitro`, `Jugador`, `Aficionado`), garantizando que solo los roles autorizados registren o modifiquen actas oficiales de partidos, goles, tarjetas y configuraciones de torneos. Toda interfaz de usuario DEBE adherirse a los tokens visuales, tipográficos y patrones de componentes definidos en `DESIGN.md`.

*Justificación*: Asegura el control operativo de cada actor en el torneo y ofrece una experiencia visual consistente, legible en tiempo real y accesible en dispositivos móviles.

### VI. Convenciones de Idioma y Nomenclatura (Language & Naming Conventions) (NON-NEGOTIABLE)
El proyecto DEBE mantener una separación estricta de idiomas entre el código técnico y la interfaz de usuario:

- **Technical Codebase (English)**: Todos los identificadores, nombres de clases, firmas de métodos, nombres de variables, nombres de archivos, rutas de carpetas, mensajes de commit y pruebas automatizadas DEBEN escribirse en **inglés**.
- **User Interface (Spanish)**: Todos los textos visibles para el usuario, mensajes de validación y etiquetas de interfaz DEBEN presentarse en **español**, centralizados mediante mecanismos estándar de internacionalización y localización (`l10n`). Ningún texto de interfaz DEBE codificarse directamente (*hardcoded*) en los componentes visuales.

*Justificación*: Mantiene un estándar de ingeniería uniforme en inglés mientras garantiza una experiencia de usuario consistente y fácil de mantener en español.

### VII. Resiliencia y Experiencia Móvil (`docs/MOBILE_GUIDELINES.md`)
Toda especificación (`spec.md`) e implementación móvil DEBE contemplar y definir explícitamente los criterios aplicables de `docs/MOBILE_GUIDELINES.md`, sin ampliar automáticamente el alcance más allá de los puntos pertinentes confirmados:

- **Ciclo de Vida y Conservación de Estado**: Definir qué ocurre con operaciones en curso, formularios, selecciones y desplazamiento al pasar a segundo plano, recrear pantallas o reabrir la aplicación, distinguiendo estado temporal de datos persistentes.
- **Conectividad, Persistencia y Consistencia**: Contemplar ausencia de conexión, red lenta, desconexiones durante operaciones y recuperación entre almacenamiento local y remoto, previniendo duplicados y conflictos.
- **Estados de Interfaz, Navegación e Interacción**: Cubrir explícitamente estados de carga, contenido, vacío, error y éxito; manejar salidas con cambios sin guardar; y proteger formularios y acciones contra pulsaciones repetidas que generen operaciones duplicadas.
- **Adaptación Visual, Accesibilidad y Permisos**: Respetar áreas del sistema, escalado de texto, lectores de pantalla, contraste (sin depender solo del color o gestos), permisos rechazados/revocados y formatos regionales (fechas, zonas horarias, números).
- **Rendimiento, Segundo Plano y Privacidad**: Mantener la interfaz receptiva durante operaciones de red/almacenamiento, gestionar la reanudación segura de tareas e impedir la exposición de datos sensibles en registros (*logs*) o mensajes de error.

*Justificación*: El uso real en canchas y sedes deportivas implica conectividad intermitente, interrupciones frecuentes y operación bajo condiciones móviles variables.

## Restricciones Arquitectónicas y Entornos Operativos

El diseño e implementación del sistema DEBEN cumplir las siguientes directrices agnósticas de tecnología:

- **Capacidad Offline-First y Sincronización**: El sistema DEBE permitir la consulta de datos previamente descargados y definir políticas claras de sincronización y resolución de conflictos frente al servidor central.
- **Rendimiento de Consultas y Estadísticas**: Las operaciones de lectura y agregación de métricas deportivas DEBEN optimizarse para ofrecer respuestas en tiempo real sin bloquear la interfaz.
- **Aislamiento de Entornos**: El sistema DEBE soportar configuraciones separadas y aisladas para entornos de desarrollo y producción sin mezclar credenciales ni datos operativos.
- **Trazabilidad e Identificación Única**: Toda entidad de negocio y evento deportivo DEBE poseer identificadores únicos inmutables para garantizar idempotencia en operaciones de red y respaldo.

## Flujo de Desarrollo y Puertas de Calidad

El ciclo de vida de cada funcionalidad DEBE superar las siguientes puertas de calidad antes de darse por completado:

1. **Especificación y Planificación**: Creación y validación de `spec.md`, `plan.md` y `tasks.md` incorporando los requisitos, decisiones y criterios de aceptación derivados de `docs/MOBILE_GUIDELINES.md`.
2. **Nomenclatura y Localización**: Verificación de que todo el código técnico, pruebas y commits estén en inglés, y que los textos de usuario estén en español centralizados mediante `l10n`.
3. **Análisis Estático**: El código DEBE superar las herramientas de análisis estático y reglas de estilo del proyecto con cero errores y cero advertencias.
4. **Pruebas Automatizadas y Validación Móvil**: Ejecución exitosa de toda la suite de pruebas automatizadas, complementada con pruebas en dispositivo, emulador o simulador para los escenarios móviles aplicables (interrupciones, conectividad, permisos y tamaños de pantalla).
5. **Cumplimiento de Diseño y Roles**: Verificación de que la interfaz respete los tokens de `DESIGN.md` y las reglas de autorización de los cinco roles del sistema.

## Governance

Esta Constitución rige por encima de cualquier otra práctica o convención informal del proyecto:

- **Procedimiento de Enmienda**: Cualquier modificación a los principios o reglas de gobernanza DEBE documentarse en `.specify/memory/constitution.md`, justificando el cambio y actualizando los artefactos afectados.
- **Política de Versionado**: Se aplica versionado semántico (`MAJOR.MINOR.PATCH`):
  - `MAJOR`: Eliminación o redefinición incompatible de principios innegociables o cambios estructurales de gobernanza.
  - `MINOR`: Adición de nuevos principios, secciones o expansión sustancial de reglas existentes.
  - `PATCH`: Aclaraciones de redacción, correcciones tipográficas o mejoras sin cambio semántico.
- **Revisión de Cumplimiento**: Toda especificación, plan de implementación, lista de tareas y revisión de código DEBE verificar explícitamente el cumplimiento de los siete principios fundamentales antes de su aprobación.

**Version**: 2.0.0 | **Ratified**: 2026-10-28 | **Last Amended**: 2026-10-28
