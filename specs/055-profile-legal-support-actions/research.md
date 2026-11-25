# Research Findings: Botones de Quitar Anuncios, Términos, Políticas y FAQ en Perfil (HU 24.2)

**Feature**: `055-profile-legal-support-actions`  
**Date**: 2026-11-25

## Decision 1: Encapsulación en `ProfileLegalSupportSection` con guarda anti-doble tap

- **Decision**: Crear un `StatefulWidget` dedicado (`ProfileLegalSupportSection`) en `lib/presentation/shell/tabs/widgets/profile_legal_support_section.dart` que renderiza una `KickPulseCard` con los 4 accesos en orden fijo y mantiene un flag booleano `_isActionInProgress` para bloquear toques concurrentes mientras una navegación o diálogo modal esté abierto/en transición.
- **Rationale**: Mantiene `ProfileTabView` como `ConsumerWidget` sin sobrecargarlo de estado local, garantiza que `await Navigator.of(context).push(...)` y `await RemoveAdsDialog.show(context)` liberen el bloqueo únicamente al cerrarse o completarse la transición (previniendo duplicados incluso ante 2+ taps en el mismo frame), y facilita pruebas unitarias y de widget.
- **Alternatives considered**:
  - *Convertir `ProfileTabView` completo a `ConsumerStatefulWidget`*: Aumenta innecesariamente la complejidad de `ProfileTabView`.
  - *Usar `Timer` fijo de debounce*: Menos determinista en pruebas de widget (`pumpAndSettle`) que un bloqueo ligado al `Future` real de `Navigator.push` / `showDialog`.

## Decision 2: Pantallas dedicadas para Términos, Políticas y FAQ + Diálogo modal para Quitar anuncios

- **Decision**:
  - Crear `ProfileLegalDocumentScreen` (parametrizada por `ProfileLegalDocumentType.terms` y `ProfileLegalDocumentType.privacyPolicy`) con `Scaffold`, `AppBar` (título localizado + botón atrás estándar) y `SingleChildScrollView` con secciones estructuradas en `KickPulseCard`.
  - Crear `ProfileFaqScreen` con `Scaffold`, `AppBar` y lista expandible/legible (`ExpansionTile` o tarjetas de preguntas y respuestas) en español sobre ViFutbol (roles, torneos, modo offline, privacidad y anuncios).
  - Crear `RemoveAdsDialog` (`showDialog`) con estilo `KickPulseColors.surfaceBase`, ícono representativo, insignia "Próximamente" (`KickPulseBadge`), descripción del beneficio sin publicidad y botón de cierre (`Entendido`).
  - Registrar las rutas `/profile/terms`, `/profile/privacy-policy` y `/profile/faq` en `AppRouter` y navegar mediante `MaterialPageRoute` desde `ProfileLegalSupportSection` para funcionar sin fricción tanto en la app completa como en pruebas aisladas de `ProfileTabView`.
- **Rationale**: Responde exactamente a las clarificaciones Q1=B y Q2=A, y sigue las convenciones visuales de `DESIGN.md` y `CompleteProfileDialog`.
- **Alternatives considered**:
  - *Navegación exclusiva con `pushNamed`*: Fallaría en pruebas aisladas de `ProfileTabView` que no montan `AppRouter.router.generator`, obligando a duplicar mapas de rutas en tests.

## Decision 3: Localización centralizada en `lib/l10n/app_es.arb`

- **Decision**: Agregar todas las llaves de UI y contenidos en español (etiquetas de los 4 botones, título de sección, subtítulos, secciones de Términos y condiciones, secciones de Políticas de tratamiento de datos, preguntas y respuestas de FAQ, y textos del modal de Quitar anuncios) en `lib/l10n/app_es.arb` y regenerar `app_localizations.dart` / `app_localizations_es.dart` con `flutter gen-l10n`.
- **Rationale**: Cumple estrictamente el Principio VI de la Constitución (cero textos hardcoded en componentes visuales) y asegura lectura 100% offline.
- **Alternatives considered**:
  - *Constantes Dart en español en archivos de presentación*: Violación directa del Principio VI (Constitución).

## Decision 4: Áreas táctiles, accesibilidad y orden verificable

- **Decision**:
  - Cada fila de acción usará `InkWell` con `ConstrainedBox(constraints: const BoxConstraints(minHeight: 48))` (superando el mínimo de 44 px de `docs/MOBILE_GUIDELINES.md`), ícono en `CircleAvatar` (`KickPulseColors.surfaceElevated`), etiqueta `Expanded` (evitando overflow bajo `TextScaler.linear(1.5)`), e ícono `Icons.chevron_right`.
  - Asignar claves deterministas:
    - `Key('profile_remove_ads_tile')`
    - `Key('profile_terms_tile')`
    - `Key('profile_privacy_policy_tile')`
    - `Key('profile_faq_tile')`
    - `Key('profile_capabilities_section')` (para verificar posición vertical exacta debajo de permisos y arriba del botón de cierre de sesión).
- **Rationale**: Garantiza pruebas deterministas de posición vertical (`tester.getTopLeft`) y cumplimiento estricto de accesibilidad móvil.
