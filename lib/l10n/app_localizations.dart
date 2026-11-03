import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('es')];

  /// Título principal de la aplicación
  ///
  /// In es, this message translates to:
  /// **'vifutbol'**
  String get appTitle;

  /// Pestaña de Jornada en la navegación inferior
  ///
  /// In es, this message translates to:
  /// **'Jornada'**
  String get tabMatchday;

  /// Pestaña de Posiciones en la navegación inferior
  ///
  /// In es, this message translates to:
  /// **'Posiciones'**
  String get tabStandings;

  /// Pestaña de Sedes en la navegación inferior
  ///
  /// In es, this message translates to:
  /// **'Sedes'**
  String get tabVenues;

  /// Pestaña de Perfil en la navegación inferior
  ///
  /// In es, this message translates to:
  /// **'Perfil'**
  String get tabProfile;

  /// Insignia indicadora de entorno de desarrollo
  ///
  /// In es, this message translates to:
  /// **'DEV'**
  String get envDevBadge;

  /// Título o descripción del entorno de desarrollo
  ///
  /// In es, this message translates to:
  /// **'Entorno de Desarrollo'**
  String get envDevelopmentTitle;

  /// Título o descripción del entorno de producción
  ///
  /// In es, this message translates to:
  /// **'Entorno de Producción'**
  String get envProductionTitle;

  /// Mensaje en banner persistente cuando el dispositivo está sin conexión
  ///
  /// In es, this message translates to:
  /// **'Modo sin conexión: mostrando datos guardados en el dispositivo'**
  String get connectivityOfflineMessage;

  /// Mensaje temporal de 3 segundos al recuperar la conexión
  ///
  /// In es, this message translates to:
  /// **'Conexión restaurada'**
  String get connectivityRestoredMessage;

  /// Título del estado de carga
  ///
  /// In es, this message translates to:
  /// **'Cargando datos deportivos...'**
  String get stateLoadingTitle;

  /// Subtítulo del estado de carga
  ///
  /// In es, this message translates to:
  /// **'Por favor espera un momento mientras se sincroniza la información.'**
  String get stateLoadingSubtitle;

  /// Título del estado de contenido
  ///
  /// In es, this message translates to:
  /// **'Contenido deportivo listo'**
  String get stateContentTitle;

  /// Título del estado vacío
  ///
  /// In es, this message translates to:
  /// **'No hay registros disponibles'**
  String get stateEmptyTitle;

  /// Descripción del estado vacío
  ///
  /// In es, this message translates to:
  /// **'Aún no se han programado partidos ni eventos para este torneo.'**
  String get stateEmptyDescription;

  /// Título del estado de error
  ///
  /// In es, this message translates to:
  /// **'Ocurrió un problema'**
  String get stateErrorTitle;

  /// Descripción del estado de error
  ///
  /// In es, this message translates to:
  /// **'No pudimos cargar la información en este momento.'**
  String get stateErrorDescription;

  /// Título del estado de éxito
  ///
  /// In es, this message translates to:
  /// **'Operación completada'**
  String get stateSuccessTitle;

  /// Descripción del estado de éxito
  ///
  /// In es, this message translates to:
  /// **'Los datos se han guardado y actualizado con éxito.'**
  String get stateSuccessDescription;

  /// Etiqueta del botón para reintentar una acción fallida
  ///
  /// In es, this message translates to:
  /// **'Reintentar'**
  String get actionRetry;

  /// Etiqueta del botón de continuar
  ///
  /// In es, this message translates to:
  /// **'Continuar'**
  String get actionContinue;

  /// Etiqueta del botón para actualizar datos
  ///
  /// In es, this message translates to:
  /// **'Actualizar'**
  String get actionRefresh;

  /// Título de bienvenida en la pantalla de autenticación
  ///
  /// In es, this message translates to:
  /// **'Bienvenido a vifutbol'**
  String get authWelcomeTitle;

  /// Subtítulo de bienvenida
  ///
  /// In es, this message translates to:
  /// **'Tu plataforma oficial para gestión de torneos, sedes y estadísticas'**
  String get authWelcomeSubtitle;

  /// Pestaña de inicio de sesión
  ///
  /// In es, this message translates to:
  /// **'Iniciar sesión'**
  String get authLoginTab;

  /// Pestaña de registro
  ///
  /// In es, this message translates to:
  /// **'Crear cuenta'**
  String get authRegisterTab;

  /// Etiqueta para el campo de correo electrónico
  ///
  /// In es, this message translates to:
  /// **'Correo electrónico'**
  String get authEmailLabel;

  /// Pista del campo de correo
  ///
  /// In es, this message translates to:
  /// **'ejemplo@vifutbol.com'**
  String get authEmailHint;

  /// Etiqueta para el campo de contraseña
  ///
  /// In es, this message translates to:
  /// **'Contraseña'**
  String get authPasswordLabel;

  /// Pista del campo de contraseña
  ///
  /// In es, this message translates to:
  /// **'Mínimo 8 caracteres'**
  String get authPasswordHint;

  /// Etiqueta para el campo de nombre completo
  ///
  /// In es, this message translates to:
  /// **'Nombre completo'**
  String get authFullNameLabel;

  /// Pista del campo de nombre
  ///
  /// In es, this message translates to:
  /// **'Tu nombre y apellido'**
  String get authFullNameHint;

  /// Acceso rápido de consulta pública como aficionado
  ///
  /// In es, this message translates to:
  /// **'Continuar como Aficionado'**
  String get authContinueAsFan;

  /// Separador visual entre login y acceso rápido
  ///
  /// In es, this message translates to:
  /// **'o también puedes'**
  String get authOrDivider;

  /// Error cuando el formato del correo es incorrecto
  ///
  /// In es, this message translates to:
  /// **'Ingresa un correo electrónico válido'**
  String get authErrorInvalidEmail;

  /// Error cuando la contraseña es menor a 8 caracteres
  ///
  /// In es, this message translates to:
  /// **'La contraseña debe tener al menos 8 caracteres'**
  String get authErrorPasswordTooShort;

  /// Error cuando el nombre es menor a 2 caracteres
  ///
  /// In es, this message translates to:
  /// **'El nombre debe tener al menos 2 caracteres'**
  String get authErrorNameTooShort;

  /// Error de autenticación por credenciales incorrectas
  ///
  /// In es, this message translates to:
  /// **'Correo o contraseña incorrectos'**
  String get authErrorInvalidCredentials;

  /// Error cuando se intenta login o registro sin red
  ///
  /// In es, this message translates to:
  /// **'Se requiere conexión a internet para iniciar sesión o registrarse'**
  String get authErrorNetworkRequired;

  /// Error por 5 intentos fallidos consecutivos
  ///
  /// In es, this message translates to:
  /// **'Demasiados intentos fallidos. Intenta de nuevo en {seconds} segundos.'**
  String authErrorRateLimited(int seconds);

  /// Título de la pantalla de onboarding de rol
  ///
  /// In es, this message translates to:
  /// **'Selecciona tu Rol Deportivo'**
  String get onboardingTitle;

  /// Subtítulo de la pantalla de onboarding
  ///
  /// In es, this message translates to:
  /// **'Define tu nivel de participación y responsabilidades en los torneos'**
  String get onboardingSubtitle;

  /// Campo opcional para código de organizador o árbitro en producción
  ///
  /// In es, this message translates to:
  /// **'Código de autorización oficial'**
  String get onboardingAuthCodeLabel;

  /// Pista del código de autorización
  ///
  /// In es, this message translates to:
  /// **'Requerido para Organizador o Árbitro en torneos oficiales'**
  String get onboardingAuthCodeHint;

  /// Error cuando el código de torneo es incorrecto
  ///
  /// In es, this message translates to:
  /// **'Código de autorización inválido para el rol seleccionado'**
  String get onboardingErrorInvalidCode;

  /// Botón para finalizar onboarding y acceder al App Shell
  ///
  /// In es, this message translates to:
  /// **'Confirmar y entrar al torneo'**
  String get onboardingConfirmAction;

  /// Título del diálogo al salir con cambios sin guardar
  ///
  /// In es, this message translates to:
  /// **'¿Descartar cambios?'**
  String get onboardingDiscardTitle;

  /// Mensaje del diálogo de descarte
  ///
  /// In es, this message translates to:
  /// **'Si sales ahora, deberás seleccionar tu rol la próxima vez que ingreses a la aplicación.'**
  String get onboardingDiscardMessage;

  /// Botón para confirmar descarte
  ///
  /// In es, this message translates to:
  /// **'Descartar'**
  String get actionDiscard;

  /// Botón para cancelar acción
  ///
  /// In es, this message translates to:
  /// **'Cancelar'**
  String get actionCancel;

  /// Nombre del rol Organizador
  ///
  /// In es, this message translates to:
  /// **'Organizador'**
  String get roleOrganizer;

  /// Nombre del rol Entrenador
  ///
  /// In es, this message translates to:
  /// **'Entrenador'**
  String get roleCoach;

  /// Nombre del rol Árbitro
  ///
  /// In es, this message translates to:
  /// **'Árbitro'**
  String get roleReferee;

  /// Nombre del rol Jugador
  ///
  /// In es, this message translates to:
  /// **'Jugador'**
  String get rolePlayer;

  /// Nombre del rol Aficionado
  ///
  /// In es, this message translates to:
  /// **'Aficionado'**
  String get roleFan;

  /// Descripción del rol Organizador
  ///
  /// In es, this message translates to:
  /// **'Creación de torneos, administración de sedes y aprobación oficial'**
  String get roleDescOrganizer;

  /// Descripción del rol Entrenador
  ///
  /// In es, this message translates to:
  /// **'Gestión de plantilla, convocatoria de jugadores y alineaciones'**
  String get roleDescCoach;

  /// Descripción del rol Árbitro
  ///
  /// In es, this message translates to:
  /// **'Registro de actas arbitrales en vivo, goles, tarjetas y cierres'**
  String get roleDescReferee;

  /// Descripción del rol Jugador
  ///
  /// In es, this message translates to:
  /// **'Consulta de convocatorias propias, historial y estadísticas de rendimiento'**
  String get roleDescPlayer;

  /// Descripción del rol Aficionado
  ///
  /// In es, this message translates to:
  /// **'Seguimiento público de partidos, calendario, noticias y tablas'**
  String get roleDescFan;

  /// Título de sección de rol activo en perfil
  ///
  /// In es, this message translates to:
  /// **'Rol deportivo activo'**
  String get profileActiveRole;

  /// Selector para cambiar de rol activo
  ///
  /// In es, this message translates to:
  /// **'Cambiar rol activo'**
  String get profileSwitchRole;

  /// Encabezado de matriz de capacidades en perfil
  ///
  /// In es, this message translates to:
  /// **'Permisos y capacidades del rol'**
  String get profileCapabilitiesTitle;

  /// Indicador de permiso concedido
  ///
  /// In es, this message translates to:
  /// **'Habilitado'**
  String get capabilityGranted;

  /// Indicador de permiso denegado
  ///
  /// In es, this message translates to:
  /// **'Restringido'**
  String get capabilityDenied;

  /// Capacidad manageTournaments
  ///
  /// In es, this message translates to:
  /// **'Crear y configurar torneos'**
  String get capManageTournaments;

  /// Capacidad manageVenues
  ///
  /// In es, this message translates to:
  /// **'Administrar sedes y canchas'**
  String get capManageVenues;

  /// Capacidad approveRegistrations
  ///
  /// In es, this message translates to:
  /// **'Aprobar inscripciones de equipos'**
  String get capApproveRegistrations;

  /// Capacidad assignReferees
  ///
  /// In es, this message translates to:
  /// **'Designar árbitros para partidos'**
  String get capAssignReferees;

  /// Capacidad manageTeamRoster
  ///
  /// In es, this message translates to:
  /// **'Gestionar plantilla del equipo'**
  String get capManageTeamRoster;

  /// Capacidad manageLineups
  ///
  /// In es, this message translates to:
  /// **'Registrar convocatorias y alineaciones'**
  String get capManageLineups;

  /// Capacidad recordMatchEvents
  ///
  /// In es, this message translates to:
  /// **'Registrar goles y tarjetas en vivo'**
  String get capRecordMatchEvents;

  /// Capacidad closeMatchReport
  ///
  /// In es, this message translates to:
  /// **'Firmar y cerrar acta oficial del partido'**
  String get capCloseMatchReport;

  /// Capacidad viewPersonalStats
  ///
  /// In es, this message translates to:
  /// **'Consultar estadísticas personales y convocatorias'**
  String get capViewPersonalStats;

  /// Capacidad viewPublicContent
  ///
  /// In es, this message translates to:
  /// **'Consultar resultados, sedes y tablas públicas'**
  String get capViewPublicContent;

  /// Botón de cerrar sesión
  ///
  /// In es, this message translates to:
  /// **'Cerrar sesión'**
  String get profileLogoutAction;

  /// Título del diálogo de logout
  ///
  /// In es, this message translates to:
  /// **'¿Cerrar sesión en este dispositivo?'**
  String get profileLogoutDialogTitle;

  /// Mensaje del diálogo de logout
  ///
  /// In es, this message translates to:
  /// **'Se limpiarán los datos de tu sesión local de forma segura.'**
  String get profileLogoutDialogMessage;

  /// Título cuando navega como invitado
  ///
  /// In es, this message translates to:
  /// **'Modo Visitante (Aficionado)'**
  String get profileGuestBannerTitle;

  /// Subtítulo para aficionado invitado
  ///
  /// In es, this message translates to:
  /// **'Inicia sesión o crea una cuenta para participar activamente como Entrenador, Árbitro, Jugador u Organizador.'**
  String get profileGuestBannerSubtitle;

  /// Botón para iniciar sesión desde perfil en modo invitado
  ///
  /// In es, this message translates to:
  /// **'Iniciar sesión o Registrarse'**
  String get profileLoginRegisterButton;

  /// Mensaje de guarda RBAC denegado
  ///
  /// In es, this message translates to:
  /// **'Acceso restringido para tu rol actual'**
  String get rbacAccessRestricted;

  /// Descripción en guarda RBAC denegado
  ///
  /// In es, this message translates to:
  /// **'Esta acción requiere permisos autorizados para el rol requerido.'**
  String get rbacRequiredRoleMessage;

  /// Título principal en la pestaña Sedes
  ///
  /// In es, this message translates to:
  /// **'Directorio de Sedes'**
  String get venuesTitle;

  /// Subtítulo en la pestaña Sedes
  ///
  /// In es, this message translates to:
  /// **'Complejos deportivos y canchas urbanas verificadas'**
  String get venuesSubtitle;

  /// Pista del buscador de sedes
  ///
  /// In es, this message translates to:
  /// **'Buscar por nombre o dirección...'**
  String get venuesSearchHint;

  /// Filtro chip para ver todas las superficies
  ///
  /// In es, this message translates to:
  /// **'Todas las superficies'**
  String get venuesFilterAllSurfaces;

  /// Filtro chip para sedes con canchas iluminadas
  ///
  /// In es, this message translates to:
  /// **'Con iluminación nocturna'**
  String get venuesFilterLightingOnly;

  /// Botón de alternar cálculo de cercanía
  ///
  /// In es, this message translates to:
  /// **'Cercanía'**
  String get venuesProximityAction;

  /// Indicador cuando el catálogo está ordenado por distancia
  ///
  /// In es, this message translates to:
  /// **'Ordenado por cercanía'**
  String get venuesProximityActive;

  /// Botón de acción para crear sede deportiva
  ///
  /// In es, this message translates to:
  /// **'Nueva sede'**
  String get venuesCreateAction;

  /// Botón de acción para editar sede
  ///
  /// In es, this message translates to:
  /// **'Editar sede'**
  String get venuesEditAction;

  /// Título del estado vacío sin sedes
  ///
  /// In es, this message translates to:
  /// **'Aún no hay sedes registradas'**
  String get venuesEmptyTitle;

  /// Subtítulo del estado vacío sin sedes
  ///
  /// In es, this message translates to:
  /// **'No se encontraron sedes deportivas activas para este torneo.'**
  String get venuesEmptySubtitle;

  /// Texto del botón o llamada a la acción para el organizador cuando no hay sedes
  ///
  /// In es, this message translates to:
  /// **'Registra la primera sede deportiva para comenzar a programar partidos.'**
  String get venuesEmptyOrganizerPrompt;

  /// Título del estado vacío tras filtrar sedes
  ///
  /// In es, this message translates to:
  /// **'Sin resultados'**
  String get venuesEmptyFilterTitle;

  /// Subtítulo del estado vacío tras filtrar sedes
  ///
  /// In es, this message translates to:
  /// **'No encontramos sedes que coincidan con los filtros aplicados.'**
  String get venuesEmptyFilterSubtitle;

  /// Botón para restablecer filtros y búsqueda
  ///
  /// In es, this message translates to:
  /// **'Limpiar filtros'**
  String get venuesClearFilters;

  /// Título de la hoja o vista de detalle de sede
  ///
  /// In es, this message translates to:
  /// **'Detalle de la Sede'**
  String get venuesDetailTitle;

  /// Etiqueta para dirección de sede
  ///
  /// In es, this message translates to:
  /// **'Dirección física'**
  String get venuesAddressLabel;

  /// Etiqueta para punto de referencia de sede
  ///
  /// In es, this message translates to:
  /// **'Referencia urbana'**
  String get venuesReferenceLabel;

  /// Etiqueta para coordenadas geográficas
  ///
  /// In es, this message translates to:
  /// **'Coordenadas'**
  String get venuesCoordinatesLabel;

  /// Acción para copiar o consultar indicaciones de llegada
  ///
  /// In es, this message translates to:
  /// **'Cómo llegar'**
  String get venuesGetDirections;

  /// Mensaje snackbar cuando se copian las indicaciones
  ///
  /// In es, this message translates to:
  /// **'Indicaciones copiadas al portapapeles'**
  String get venuesDirectionsCopied;

  /// Contador de canchas internas disponibles
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 cancha disponible} other{{count} canchas disponibles}}'**
  String venuesPitchesCount(int count);

  /// Encabezado de la lista de canchas de la sede
  ///
  /// In es, this message translates to:
  /// **'Canchas internas'**
  String get venuesPitchesSectionTitle;

  /// Botón para agregar una nueva cancha al formulario
  ///
  /// In es, this message translates to:
  /// **'Agregar cancha'**
  String get venuesAddPitchAction;

  /// Botón para remover una cancha del formulario
  ///
  /// In es, this message translates to:
  /// **'Quitar cancha'**
  String get venuesRemovePitchAction;

  /// Campo de nombre de cancha
  ///
  /// In es, this message translates to:
  /// **'Nombre de la cancha'**
  String get venuesPitchNameLabel;

  /// Pista para nombre de cancha
  ///
  /// In es, this message translates to:
  /// **'Ej. Cancha Sintética 1'**
  String get venuesPitchNameHint;

  /// Etiqueta para superficie de cancha
  ///
  /// In es, this message translates to:
  /// **'Tipo de superficie'**
  String get venuesPitchSurfaceLabel;

  /// Etiqueta para formato de cancha
  ///
  /// In es, this message translates to:
  /// **'Modalidad / Formato'**
  String get venuesPitchFormatLabel;

  /// Etiqueta para capacidad de cancha
  ///
  /// In es, this message translates to:
  /// **'Capacidad de espectadores'**
  String get venuesPitchCapacityLabel;

  /// Etiqueta para iluminación de cancha
  ///
  /// In es, this message translates to:
  /// **'Iluminación artificial'**
  String get venuesPitchLightingLabel;

  /// Texto descriptivo para iluminación activa
  ///
  /// In es, this message translates to:
  /// **'Iluminación nocturna disponible'**
  String get venuesPitchLightingYes;

  /// Texto descriptivo para iluminación inactiva
  ///
  /// In es, this message translates to:
  /// **'Sin iluminación nocturna'**
  String get venuesPitchLightingNo;

  /// Etiqueta para estado operativo de cancha
  ///
  /// In es, this message translates to:
  /// **'Disponibilidad operativa'**
  String get venuesPitchStatusLabel;

  /// Etiqueta para estado operativo Activa
  ///
  /// In es, this message translates to:
  /// **'Activa'**
  String get venuesStatusActive;

  /// Etiqueta para estado operativo En mantenimiento
  ///
  /// In es, this message translates to:
  /// **'En mantenimiento'**
  String get venuesStatusMaintenance;

  /// Distancia calculada en kilómetros
  ///
  /// In es, this message translates to:
  /// **'{distance} km'**
  String venuesDistanceKm(String distance);

  /// Aforo o capacidad formateada con numeral tabular
  ///
  /// In es, this message translates to:
  /// **'{count} espectadores'**
  String venuesCapacityCount(int count);

  /// Superficie césped sintético
  ///
  /// In es, this message translates to:
  /// **'Césped Sintético'**
  String get surfaceSyntheticGrass;

  /// Superficie césped natural
  ///
  /// In es, this message translates to:
  /// **'Césped Natural'**
  String get surfaceNaturalGrass;

  /// Superficie tierra o arena
  ///
  /// In es, this message translates to:
  /// **'Tierra / Arena'**
  String get surfaceDirtOrSand;

  /// Superficie cemento o coliseo futsal
  ///
  /// In es, this message translates to:
  /// **'Cemento / Futsal'**
  String get surfaceHardCourt;

  /// Modalidad fútbol 5
  ///
  /// In es, this message translates to:
  /// **'Fútbol 5'**
  String get formatFootball5;

  /// Modalidad fútbol 7
  ///
  /// In es, this message translates to:
  /// **'Fútbol 7'**
  String get formatFootball7;

  /// Modalidad fútbol 8
  ///
  /// In es, this message translates to:
  /// **'Fútbol 8'**
  String get formatFootball8;

  /// Modalidad fútbol 11
  ///
  /// In es, this message translates to:
  /// **'Fútbol 11'**
  String get formatFootball11;

  /// Título del formulario al registrar una sede
  ///
  /// In es, this message translates to:
  /// **'Registrar Sede Deportiva'**
  String get venueFormCreateTitle;

  /// Título del formulario al editar una sede
  ///
  /// In es, this message translates to:
  /// **'Editar Sede Deportiva'**
  String get venueFormEditTitle;

  /// Campo de nombre de la sede
  ///
  /// In es, this message translates to:
  /// **'Nombre del complejo o sede'**
  String get venueFormNameLabel;

  /// Pista de nombre de sede
  ///
  /// In es, this message translates to:
  /// **'Mínimo 3 caracteres'**
  String get venueFormNameHint;

  /// Campo de dirección de la sede
  ///
  /// In es, this message translates to:
  /// **'Dirección urbana'**
  String get venueFormAddressLabel;

  /// Pista de dirección de sede
  ///
  /// In es, this message translates to:
  /// **'Mínimo 5 caracteres'**
  String get venueFormAddressHint;

  /// Campo de referencia urbana
  ///
  /// In es, this message translates to:
  /// **'Punto de referencia o indicaciones'**
  String get venueFormReferenceLabel;

  /// Pista de referencia urbana
  ///
  /// In es, this message translates to:
  /// **'Opcional (ej. frente al parque metropolitano)'**
  String get venueFormReferenceHint;

  /// Campo numérico de latitud
  ///
  /// In es, this message translates to:
  /// **'Latitud'**
  String get venueFormLatitudeLabel;

  /// Campo numérico de longitud
  ///
  /// In es, this message translates to:
  /// **'Longitud'**
  String get venueFormLongitudeLabel;

  /// Instrucción de selección de coordenadas en mapa
  ///
  /// In es, this message translates to:
  /// **'Toca el mapa para fijar coordenadas'**
  String get venueFormPickOnMap;

  /// Botón para guardar sede en formulario
  ///
  /// In es, this message translates to:
  /// **'Guardar sede'**
  String get venueFormSaveAction;

  /// Título de diálogo al salir con cambios de sede sin guardar
  ///
  /// In es, this message translates to:
  /// **'¿Descartar cambios de la sede?'**
  String get venueFormDiscardTitle;

  /// Mensaje de confirmación de descarte de formulario de sede
  ///
  /// In es, this message translates to:
  /// **'Si sales ahora, se perderán los datos y canchas configuradas en este formulario.'**
  String get venueFormDiscardMessage;

  /// Error cuando el nombre de la sede es menor a 3 caracteres
  ///
  /// In es, this message translates to:
  /// **'El nombre debe tener al menos 3 caracteres'**
  String get venueErrorNameTooShort;

  /// Error cuando la dirección de la sede es menor a 5 caracteres
  ///
  /// In es, this message translates to:
  /// **'La dirección debe tener al menos 5 caracteres'**
  String get venueErrorAddressTooShort;

  /// Error de validación para latitud fuera de rango
  ///
  /// In es, this message translates to:
  /// **'Latitud inválida (debe estar entre -90.0 y 90.0)'**
  String get venueErrorInvalidLatitude;

  /// Error de validación para longitud fuera de rango
  ///
  /// In es, this message translates to:
  /// **'Longitud inválida (debe estar entre -180.0 y 180.0)'**
  String get venueErrorInvalidLongitude;

  /// Error cuando la sede no tiene al menos una cancha activa
  ///
  /// In es, this message translates to:
  /// **'Debes agregar al menos 1 cancha interna activa'**
  String get venueErrorPitchRequired;

  /// Error cuando el nombre de la cancha es menor a 2 caracteres
  ///
  /// In es, this message translates to:
  /// **'El nombre de la cancha debe tener al menos 2 caracteres'**
  String get venueErrorPitchNameTooShort;

  /// Error cuando la capacidad de la cancha es menor a 0
  ///
  /// In es, this message translates to:
  /// **'La capacidad no puede ser negativa'**
  String get venueErrorPitchCapacityNegative;

  /// Banner discreto cuando el permiso de ubicación está denegado o revocado
  ///
  /// In es, this message translates to:
  /// **'Ubicación desactivada: mostrando sedes por referencia urbana'**
  String get locationPermissionBanner;

  /// Botón de acción en el banner para activar ubicación
  ///
  /// In es, this message translates to:
  /// **'Activar ubicación'**
  String get locationPermissionEnableAction;

  /// Título del simulador de GPS en entorno de desarrollo
  ///
  /// In es, this message translates to:
  /// **'Simulador GPS (DEV)'**
  String get locationDevSimulatorTitle;

  /// Estado concedido en el simulador GPS
  ///
  /// In es, this message translates to:
  /// **'Concedido'**
  String get locationDevStateGranted;

  /// Estado denegado en el simulador GPS
  ///
  /// In es, this message translates to:
  /// **'Denegado'**
  String get locationDevStateDenied;

  /// Estado revocado en el simulador GPS
  ///
  /// In es, this message translates to:
  /// **'Revocado'**
  String get locationDevStatePermanentlyDenied;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
