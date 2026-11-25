# Data Model: Botones de Quitar Anuncios, Términos, Políticas y FAQ en Perfil (HU 24.2)

**Feature**: `055-profile-legal-support-actions`  
**Date**: 2026-11-25

Esta funcionalidad **no crea ni modifica tablas en Supabase ni cajas en Hive**. Utiliza únicamente tipos inmutables de presentación para estructurar el contenido legal y de soporte localizado en español.

## Presentation Value Types

### 1. `ProfileLegalDocumentType` (`lib/presentation/shell/tabs/profile_legal_document_screen.dart`)
Enumeración de los documentos legales disponibles en solo lectura offline:
- `terms`: Términos y condiciones de uso de ViFutbol.
- `privacyPolicy`: Política de tratamiento de datos personales (conforme a principios de privacidad y protección de datos).

### 2. `LegalDocumentSection` (inmutable, uso interno en `ProfileLegalDocumentScreen`)
- `title` (`String`): Encabezado de sección localizado vía `AppLocalizations`.
- `body` (`String`): Contenido explicativo localizado vía `AppLocalizations`.

### 3. `FaqItem` (inmutable, uso interno en `ProfileFaqScreen`)
- `question` (`String`): Pregunta frecuente localizada vía `AppLocalizations`.
- `answer` (`String`): Respuesta clara localizada vía `AppLocalizations`.

## State & Persistence Constraints

- **Sin persistencia**: `RemoveAdsDialog` no guarda ni sincroniza suscripciones ni preferencias; solo informa disponibilidad futura.
- **Estado temporal de interacción**: `_isActionInProgress` (`bool`, default `false`) en `ProfileLegalSupportSection` controla exclusivamente la prevención de doble tap y se restablece al cerrarse la pantalla o modal destino.
