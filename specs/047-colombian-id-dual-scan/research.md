# Phase 0 Research: Escaneo Dual de Cédula Colombiana (HU 21.2)

**Feature**: `047-colombian-id-dual-scan`  
**Date**: 2026-11-17

## 1. Estrategia Dual de Reconocimiento en Dispositivo (On-Device ML Kit)

- **Decodificación PDF417 (Cédula Amarilla con Hologramas)**:
  - Se emplea `google_mlkit_barcode_scanning` configurado específicamente con `[BarcodeFormat.pdf417]` para maximizar velocidad y precisión sobre el código de barras bidimensional del reverso.
  - El parser puro en dominio (`ColombianIdParser`) recibe la cadena/bytes crudos decodificados sin depender del plugin ML Kit, permitiendo pruebas unitarias deterministas al 100%.
  - Soporta extracción posicional estándar RNEC (`PubDSK_1`) y respaldo por tokenización cuando el lector comprime separadores nulos (`\x00`), extrayendo documento, primer/segundo apellido, primer/segundo nombre, sexo (`M`/`F`), fecha de nacimiento (`YYYYMMDD`) y grupo sanguíneo/RH.

- **Reconocimiento MRZ TD1 + OCR (Cédula Digital / Policarbonato)**:
  - Se emplea `google_mlkit_text_recognition` (`TextRecognizer(script: TextRecognitionScript.latin)`) sobre las imágenes frontal y posterior.
  - El analizador MRZ busca el bloque de 3 líneas de 30 caracteres estándar ICAO 9303 TD1 (`I<COL...` o `IDCOL...`), normalizando errores frecuentes de OCR (`«` → `<`, caracteres alfabéticos vs dígitos en zonas numéricas).
  - La fecha `YYMMDD` de la línea 2 resuelve el siglo dinámicamente frente a la fecha actual (si `YY > currentYear % 100` → `1900 + YY`, si no → `2000 + YY`).
  - Heurísticas OCR complementarias sobre el texto impreso identifican NUIP (`\d{1,3}(?:\.\d{3}){2,3}` o dígitos cercanos a `NUIP`/`NÚMERO`) y RH (`(O|A|B|AB)\s*[+-]`).

## 2. Captura Exclusiva con Cámara en Vivo (Q2)

- Por decisión clarificada (Q2 = B), la captura se realiza **únicamente con la cámara en vivo** usando `image_picker` (`ImageSource.camera`, `preferredCameraDevice: CameraDevice.rear`, `maxWidth: 1600`, `imageQuality: 85`), sin botón de galería.
- Los errores de permiso de cámara (`PlatformException` con código `camera_access_denied` / `permission_denied`) se capturan explícitamente, mostrando un mensaje claro en español con opción de abrir la configuración de la aplicación y permitiendo edición manual sin bloquear el formulario.

## 3. Privacidad, Storage y Comportamiento Offline (Q1 & Q3)

- **Obligatoriedad (Q1 = B)**: Ambas caras (frontal y posterior) son obligatorias para guardar `PlayerPersonalDataScreen` y para que `UserAccount.isProfileCompleteForActiveRole` retorne `true` en `UserRole.player`.
- **Almacenamiento Remoto Seguro (Q3 = A)**:
  - Bucket privado `player-documents` en Supabase Storage (`public: false`).
  - Políticas RLS en `storage.objects` restringidas al propietario autenticado (`(storage.foldername(name))[1] = (SELECT auth.uid())::text`).
  - Rutas estables por usuario (`<auth_uid>/document_front.jpg` y `<auth_uid>/document_back.jpg`) subidas con `upsert: true` para evitar acumulación de archivos huérfanos tras recapturas.
  - Cuando Supabase está activo y no hay conexión, se lanza `OfflineAuthOperationFailure` conservando tanto el formulario como las rutas locales de las fotos recién capturadas para reintentar.
  - En modo local/pruebas sin Supabase remoto configurado, las rutas locales se persisten directamente en `RoleProfileData`.

## 4. Desacoplamiento para Pruebas Automatizadas

- La captura fotográfica y la ejecución de ML Kit se abstraen detrás de interfaces de servicio (`IdCameraCapturePort` y `ColombianIdScannerService`), inyectadas vía Riverpod, de modo que todas las pruebas unitarias y de widget puedan simular capturas, escaneos exitosos (PDF417 / MRZ), lecturas parciales y denegación de permisos sin requerir cámara física.
