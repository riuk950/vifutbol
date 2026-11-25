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

  /// Pestaña de Partidos en la navegación inferior
  ///
  /// In es, this message translates to:
  /// **'Partidos'**
  String get tabMatchday;

  /// Pestaña de Partidos en la navegación inferior
  ///
  /// In es, this message translates to:
  /// **'Partidos'**
  String get tabMatches;

  /// Pestaña de Explorar en la navegación inferior
  ///
  /// In es, this message translates to:
  /// **'Explorar'**
  String get tabStandings;

  /// Pestaña de Explorar en la navegación inferior
  ///
  /// In es, this message translates to:
  /// **'Explorar'**
  String get tabExplore;

  /// Pestaña de Sedes en la navegación inferior
  ///
  /// In es, this message translates to:
  /// **'Sedes'**
  String get tabVenues;

  /// Pestaña de Noticias en la navegación inferior
  ///
  /// In es, this message translates to:
  /// **'Noticias'**
  String get tabNews;

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

  /// Título principal del módulo de campeonatos en la pestaña Posiciones
  ///
  /// In es, this message translates to:
  /// **'Campeonatos y Reglas'**
  String get tournamentsTitle;

  /// Subtítulo del módulo de campeonatos
  ///
  /// In es, this message translates to:
  /// **'Normativa oficial, formatos de competición y tablas del torneo'**
  String get tournamentsSubtitle;

  /// Botón principal para crear un nuevo campeonato
  ///
  /// In es, this message translates to:
  /// **'Crear Campeonato'**
  String get tournamentsCreateAction;

  /// Botón para editar campeonato o reglas
  ///
  /// In es, this message translates to:
  /// **'Editar Reglas'**
  String get tournamentsEditAction;

  /// Chip de filtro para todos los formatos de campeonato
  ///
  /// In es, this message translates to:
  /// **'Todos los formatos'**
  String get tournamentsFilterAll;

  /// Formato de torneo Liga todos contra todos
  ///
  /// In es, this message translates to:
  /// **'Liga'**
  String get tournamentFormatLeague;

  /// Formato de torneo Copa de eliminación directa
  ///
  /// In es, this message translates to:
  /// **'Copa Eliminatoria'**
  String get tournamentFormatKnockout;

  /// Formato de torneo Mixto con fase de grupos y llaves
  ///
  /// In es, this message translates to:
  /// **'Mixto (Grupos + Eliminatoria)'**
  String get tournamentFormatMixed;

  /// Estado inicial del campeonato con inscripciones abiertas
  ///
  /// In es, this message translates to:
  /// **'Inscripciones Abiertas'**
  String get tournamentStatusOpenRegistration;

  /// Estado del campeonato cuando ya está en disputa
  ///
  /// In es, this message translates to:
  /// **'En Curso'**
  String get tournamentStatusInProgress;

  /// Estado del campeonato cuando ha concluido
  ///
  /// In es, this message translates to:
  /// **'Finalizado'**
  String get tournamentStatusFinished;

  /// Acción del organizador para pasar el campeonato a En Curso
  ///
  /// In es, this message translates to:
  /// **'Iniciar Campeonato (En Curso)'**
  String get tournamentStartAction;

  /// Acción del organizador para marcar el campeonato como Finalizado
  ///
  /// In es, this message translates to:
  /// **'Finalizar Campeonato'**
  String get tournamentFinishAction;

  /// Título cuando no existen campeonatos en el catálogo
  ///
  /// In es, this message translates to:
  /// **'No hay campeonatos registrados'**
  String get tournamentsEmptyTitle;

  /// Subtítulo cuando no existen campeonatos
  ///
  /// In es, this message translates to:
  /// **'Crea el primer campeonato oficial para centralizar su normativa, puntos y llaves.'**
  String get tournamentsEmptySubtitle;

  /// Aviso cuando existe un borrador local de campeonato
  ///
  /// In es, this message translates to:
  /// **'Se recuperó un borrador guardado'**
  String get tournamentsDraftBannerTitle;

  /// Acción para abrir el borrador guardado
  ///
  /// In es, this message translates to:
  /// **'Continuar borrador'**
  String get tournamentsDraftBannerContinue;

  /// Acción para descartar el borrador guardado
  ///
  /// In es, this message translates to:
  /// **'Limpiar borrador'**
  String get tournamentsDraftBannerClear;

  /// Título de la tarjeta de resumen de reglas oficiales
  ///
  /// In es, this message translates to:
  /// **'Normativa Oficial del Torneo'**
  String get tournamentRulesSectionTitle;

  /// Subtítulo del sistema de puntos
  ///
  /// In es, this message translates to:
  /// **'Sistema de Puntuación'**
  String get tournamentScoringTitle;

  /// Etiqueta de puntos por victoria
  ///
  /// In es, this message translates to:
  /// **'Victoria'**
  String get tournamentPointsWin;

  /// Etiqueta de puntos por empate
  ///
  /// In es, this message translates to:
  /// **'Empate'**
  String get tournamentPointsDraw;

  /// Etiqueta de puntos por derrota
  ///
  /// In es, this message translates to:
  /// **'Derrota'**
  String get tournamentPointsLoss;

  /// Formato de cantidad de puntos
  ///
  /// In es, this message translates to:
  /// **'{points} pts'**
  String tournamentPointsValue(int points);

  /// Encabezado de la lista ordenada de criterios de desempate
  ///
  /// In es, this message translates to:
  /// **'Criterios de Desempate en Tabla'**
  String get tournamentTiebreakersTitle;

  /// Criterio de desempate por diferencia de goles
  ///
  /// In es, this message translates to:
  /// **'Diferencia de Gol'**
  String get tiebreakerGoalDifference;

  /// Criterio de desempate por goles a favor
  ///
  /// In es, this message translates to:
  /// **'Goles a Favor'**
  String get tiebreakerGoalsFor;

  /// Criterio de desempate por enfrentamiento directo
  ///
  /// In es, this message translates to:
  /// **'Duelo Directo'**
  String get tiebreakerHeadToHead;

  /// Criterio de desempate por juego limpio
  ///
  /// In es, this message translates to:
  /// **'Fair Play (Menor puntaje de tarjetas)'**
  String get tiebreakerFairPlay;

  /// Encabezado de reglas operativas y disciplinarias
  ///
  /// In es, this message translates to:
  /// **'Disciplina, Plantilla y Tiempo de Juego'**
  String get tournamentDisciplinaryAndSquadTitle;

  /// Etiqueta de límite de tarjetas amarillas
  ///
  /// In es, this message translates to:
  /// **'Suspensión por acumulación de amarillas'**
  String get tournamentYellowCardLimitLabel;

  /// Valor formateado de tarjetas amarillas para suspensión
  ///
  /// In es, this message translates to:
  /// **'{count} tarjetas amarillas'**
  String tournamentYellowCardLimitValue(int count);

  /// Etiqueta de mínimo y máximo de jugadores
  ///
  /// In es, this message translates to:
  /// **'Cupo de jugadores por equipo'**
  String get tournamentSquadRangeLabel;

  /// Etiqueta para el campo de mínimo de jugadores por equipo
  ///
  /// In es, this message translates to:
  /// **'Mín. jugadores'**
  String get tournamentMinPlayersLabel;

  /// Etiqueta para el campo de máximo de jugadores por equipo
  ///
  /// In es, this message translates to:
  /// **'Máx. jugadores'**
  String get tournamentMaxPlayersLabel;

  /// Rango formateado de jugadores por equipo
  ///
  /// In es, this message translates to:
  /// **'Mín. {min} / Máx. {max} jugadores'**
  String tournamentSquadRangeValue(int min, int max);

  /// Etiqueta de duración de cada tiempo
  ///
  /// In es, this message translates to:
  /// **'Duración por tiempo reglamentario'**
  String get tournamentHalfDurationLabel;

  /// Duración formateada por tiempo
  ///
  /// In es, this message translates to:
  /// **'{minutes} min por tiempo'**
  String tournamentHalfDurationValue(int minutes);

  /// Etiqueta de cantidad de vueltas en formato Liga
  ///
  /// In es, this message translates to:
  /// **'Modalidad de vueltas (Liga)'**
  String get tournamentLeagueRoundsLabel;

  /// Liga a una sola vuelta
  ///
  /// In es, this message translates to:
  /// **'1 vuelta (Solo ida)'**
  String get tournamentLeagueSingleRound;

  /// Liga a doble vuelta
  ///
  /// In es, this message translates to:
  /// **'2 vueltas (Ida y vuelta)'**
  String get tournamentLeagueDoubleRound;

  /// Encabezado de configuración de llaves eliminatorias
  ///
  /// In es, this message translates to:
  /// **'Estructura de Llaves Eliminatorias'**
  String get tournamentKnockoutStructureTitle;

  /// Etiqueta para seleccionar la ronda de inicio en eliminatoria
  ///
  /// In es, this message translates to:
  /// **'Ronda inicial de llaves'**
  String get tournamentStartingRoundLabel;

  /// Ronda de Octavos de Final (16 equipos)
  ///
  /// In es, this message translates to:
  /// **'Octavos de Final'**
  String get knockoutRoundOf16;

  /// Ronda de Cuartos de Final (8 equipos)
  ///
  /// In es, this message translates to:
  /// **'Cuartos de Final'**
  String get knockoutQuarterFinals;

  /// Ronda de Semifinal (4 equipos)
  ///
  /// In es, this message translates to:
  /// **'Semifinal'**
  String get knockoutSemiFinals;

  /// Ronda Final (2 equipos)
  ///
  /// In es, this message translates to:
  /// **'Final'**
  String get knockoutFinalMatch;

  /// Opción para definir empates en llaves directamente desde el punto penal
  ///
  /// In es, this message translates to:
  /// **'Desempate directo por penales al finalizar el tiempo reglamentario'**
  String get tournamentDirectPenaltiesLabel;

  /// Opción para cruces eliminatorios de ida y vuelta
  ///
  /// In es, this message translates to:
  /// **'Cruces a doble partido (Ida y vuelta)'**
  String get tournamentTwoLeggedTiesLabel;

  /// Descripción de llave a partido único
  ///
  /// In es, this message translates to:
  /// **'Partido único (Exige ganador en cada llave)'**
  String get tournamentSingleLegTieValue;

  /// Encabezado de configuración de grupos en formato Mixto
  ///
  /// In es, this message translates to:
  /// **'Configuración de Fase de Grupos'**
  String get tournamentGroupStageTitle;

  /// Etiqueta de número de grupos
  ///
  /// In es, this message translates to:
  /// **'Cantidad de grupos'**
  String get tournamentGroupCountLabel;

  /// Etiqueta de clasificados por cada grupo
  ///
  /// In es, this message translates to:
  /// **'Clasificados por grupo'**
  String get tournamentAdvancingPerGroupLabel;

  /// Resumen de fase de grupos
  ///
  /// In es, this message translates to:
  /// **'{groups} grupos · clasifican {advancing} por grupo'**
  String tournamentGroupSummaryValue(int groups, int advancing);

  /// Encabezado de historial de cambios críticos auditados
  ///
  /// In es, this message translates to:
  /// **'Historial de Auditoría y Recálculos'**
  String get tournamentAuditTrailTitle;

  /// Título del asistente de creación de campeonato
  ///
  /// In es, this message translates to:
  /// **'Crear Campeonato'**
  String get tournamentFormCreateTitle;

  /// Título del asistente de edición de campeonato
  ///
  /// In es, this message translates to:
  /// **'Editar Reglas del Campeonato'**
  String get tournamentFormEditTitle;

  /// Campo de nombre del campeonato
  ///
  /// In es, this message translates to:
  /// **'Nombre oficial del campeonato'**
  String get tournamentFormNameLabel;

  /// Pista de nombre del campeonato
  ///
  /// In es, this message translates to:
  /// **'Ej. Torneo Clausura ViFutbol 2026'**
  String get tournamentFormNameHint;

  /// Campo de categoría del campeonato
  ///
  /// In es, this message translates to:
  /// **'Categoría'**
  String get tournamentFormCategoryLabel;

  /// Pista de categoría
  ///
  /// In es, this message translates to:
  /// **'Ej. Libre Masculino'**
  String get tournamentFormCategoryHint;

  /// Etiqueta de fecha de inicio
  ///
  /// In es, this message translates to:
  /// **'Fecha de inicio'**
  String get tournamentFormStartDateLabel;

  /// Etiqueta de fecha de finalización
  ///
  /// In es, this message translates to:
  /// **'Fecha de finalización'**
  String get tournamentFormEndDateLabel;

  /// Selector de formato del torneo
  ///
  /// In es, this message translates to:
  /// **'Formato del campeonato'**
  String get tournamentFormFormatLabel;

  /// Botón para guardar y crear el campeonato
  ///
  /// In es, this message translates to:
  /// **'Crear Campeonato'**
  String get tournamentFormSaveCreateAction;

  /// Botón para guardar edición del campeonato
  ///
  /// In es, this message translates to:
  /// **'Guardar Cambios'**
  String get tournamentFormSaveEditAction;

  /// Banner de advertencia de inmutabilidad cuando el torneo está En Curso
  ///
  /// In es, this message translates to:
  /// **'Campeonato En Curso: alterar el formato o el sistema de puntuación requerirá confirmación administrativa explícita y recálculo auditado.'**
  String get tournamentCriticalRuleLockBanner;

  /// Título del diálogo al modificar formato o puntos estando En Curso
  ///
  /// In es, this message translates to:
  /// **'Confirmación Administrativa y Recálculo Auditado'**
  String get tournamentAuditDialogTitle;

  /// Mensaje del diálogo de auditoría
  ///
  /// In es, this message translates to:
  /// **'Estás modificando reglas críticas de un campeonato En Curso. Ingresa el motivo oficial para registrar la auditoría y autorizar el recálculo de tabla.'**
  String get tournamentAuditDialogMessage;

  /// Etiqueta del campo de motivo en el diálogo de auditoría
  ///
  /// In es, this message translates to:
  /// **'Motivo administrativo de la modificación'**
  String get tournamentAuditReasonLabel;

  /// Pista del campo de motivo de auditoría
  ///
  /// In es, this message translates to:
  /// **'Ej. Resolución oficial del comité disciplinario'**
  String get tournamentAuditReasonHint;

  /// Botón para confirmar modificación auditada
  ///
  /// In es, this message translates to:
  /// **'Confirmar cambio y recalcular'**
  String get tournamentAuditConfirmAction;

  /// Pregunta oficial al intentar salir del formulario con cambios sin guardar
  ///
  /// In es, this message translates to:
  /// **'¿Deseas descartar los cambios o guardar como borrador?'**
  String get tournamentExitDialogTitle;

  /// Mensaje descriptivo del diálogo de salida
  ///
  /// In es, this message translates to:
  /// **'Tienes configuraciones de campeonato sin publicar. Puedes guardar un borrador local para continuar más tarde o descartar los cambios.'**
  String get tournamentExitDialogMessage;

  /// Opción para guardar borrador local y salir
  ///
  /// In es, this message translates to:
  /// **'Guardar borrador'**
  String get tournamentSaveDraftAction;

  /// Opción para descartar cambios y salir
  ///
  /// In es, this message translates to:
  /// **'Descartar cambios'**
  String get tournamentDiscardChangesAction;

  /// Opción para permanecer en el formulario
  ///
  /// In es, this message translates to:
  /// **'Seguir editando'**
  String get tournamentContinueEditingAction;

  /// Error de validación para nombre corto
  ///
  /// In es, this message translates to:
  /// **'El nombre del campeonato debe tener al menos 3 caracteres'**
  String get tournamentErrorInvalidName;

  /// Error de validación para categoría vacía
  ///
  /// In es, this message translates to:
  /// **'Debes ingresar una categoría válida'**
  String get tournamentErrorInvalidCategory;

  /// Error de validación para rango de fechas inválido
  ///
  /// In es, this message translates to:
  /// **'La fecha de finalización no puede ser anterior a la fecha de inicio'**
  String get tournamentErrorInvalidDates;

  /// Error de validación para sistema de puntuación incoherente
  ///
  /// In es, this message translates to:
  /// **'Los puntos deben cumplir: Victoria > Empate >= Derrota >= 0'**
  String get tournamentErrorInvalidPoints;

  /// Error de validación para límite de amarillas
  ///
  /// In es, this message translates to:
  /// **'El límite de tarjetas amarillas debe estar entre 2 y 10'**
  String get tournamentErrorInvalidYellowCards;

  /// Error de validación para cupo de jugadores
  ///
  /// In es, this message translates to:
  /// **'El cupo de jugadores debe cumplir: 5 <= Mínimo <= Máximo <= 35'**
  String get tournamentErrorInvalidSquadSize;

  /// Error de validación para duración por tiempo
  ///
  /// In es, this message translates to:
  /// **'La duración por tiempo debe estar entre 10 y 60 minutos'**
  String get tournamentErrorInvalidHalfDuration;

  /// Error de validación para fase de grupos en formato Mixto
  ///
  /// In es, this message translates to:
  /// **'Configura entre 2 y 8 grupos y entre 1 y 4 clasificados por grupo'**
  String get tournamentErrorInvalidGroupStage;

  /// Error cuando no se ingresa motivo de auditoría
  ///
  /// In es, this message translates to:
  /// **'Debes ingresar un motivo administrativo válido para auditar el cambio'**
  String get tournamentErrorAuditReasonRequired;

  /// Estado de elegibilidad cuando la plantilla no alcanza el mínimo de jugadores
  ///
  /// In es, this message translates to:
  /// **'Pendiente de Cupo'**
  String get teamEligibilityPendingQuota;

  /// Estado de elegibilidad cuando la plantilla cumple el mínimo y espera aprobación
  ///
  /// In es, this message translates to:
  /// **'Listo para Habilitar'**
  String get teamEligibilityReadyForApproval;

  /// Estado oficial de equipo habilitado para competir
  ///
  /// In es, this message translates to:
  /// **'Habilitado'**
  String get teamEligibilityEligible;

  /// Posición portero
  ///
  /// In es, this message translates to:
  /// **'Portero'**
  String get playerPositionGoalkeeper;

  /// Posición defensa
  ///
  /// In es, this message translates to:
  /// **'Defensa'**
  String get playerPositionDefender;

  /// Posición mediocampista
  ///
  /// In es, this message translates to:
  /// **'Mediocampista'**
  String get playerPositionMidfielder;

  /// Posición delantero
  ///
  /// In es, this message translates to:
  /// **'Delantero'**
  String get playerPositionForward;

  /// Abreviatura portero
  ///
  /// In es, this message translates to:
  /// **'POR'**
  String get playerPositionShortGoalkeeper;

  /// Abreviatura defensa
  ///
  /// In es, this message translates to:
  /// **'DEF'**
  String get playerPositionShortDefender;

  /// Abreviatura mediocampista
  ///
  /// In es, this message translates to:
  /// **'MED'**
  String get playerPositionShortMidfielder;

  /// Abreviatura delantero
  ///
  /// In es, this message translates to:
  /// **'DEL'**
  String get playerPositionShortForward;

  /// Forma de emblema escudo clásico
  ///
  /// In es, this message translates to:
  /// **'Escudo Clásico'**
  String get crestShapeShield;

  /// Forma de emblema circular
  ///
  /// In es, this message translates to:
  /// **'Circular'**
  String get crestShapeCircle;

  /// Forma de emblema rombo
  ///
  /// In es, this message translates to:
  /// **'Rombo'**
  String get crestShapeDiamond;

  /// Forma de emblema hexágono
  ///
  /// In es, this message translates to:
  /// **'Hexágono'**
  String get crestShapeHexagon;

  /// Encabezado de la sección de equipos en la vista de torneo
  ///
  /// In es, this message translates to:
  /// **'Equipos Inscritos'**
  String get teamsSectionTitle;

  /// Subtítulo de la sección de equipos
  ///
  /// In es, this message translates to:
  /// **'Equipos habilitados para competir y gestión de plantillas'**
  String get teamsSectionSubtitle;

  /// Botón para registrar nuevo equipo
  ///
  /// In es, this message translates to:
  /// **'Inscribir Equipo'**
  String get teamsRegisterAction;

  /// Resumen de equipos habilitados
  ///
  /// In es, this message translates to:
  /// **'{eligibleCount} de {totalCount} habilitados'**
  String teamsCountSummary(int eligibleCount, int totalCount);

  /// Título cuando no hay equipos registrados
  ///
  /// In es, this message translates to:
  /// **'Sin equipos inscritos'**
  String get teamsEmptyTitle;

  /// Subtítulo cuando no hay equipos registrados
  ///
  /// In es, this message translates to:
  /// **'Inscribe el primer equipo para comenzar a registrar jugadores en este campeonato.'**
  String get teamsEmptySubtitle;

  /// Progreso de cupo de plantilla
  ///
  /// In es, this message translates to:
  /// **'{current} / {min} a {max} jugadores'**
  String teamsQuotaProgress(int current, int min, int max);

  /// Título de la vista de plantilla de equipo
  ///
  /// In es, this message translates to:
  /// **'Plantilla Oficial'**
  String get teamRosterTitle;

  /// Subtítulo de la vista de plantilla de equipo
  ///
  /// In es, this message translates to:
  /// **'Gestión de jugadores y habilitación reglamentaria'**
  String get teamRosterSubtitle;

  /// Botón para inscribir jugador a la plantilla
  ///
  /// In es, this message translates to:
  /// **'Inscribir Jugador'**
  String get teamEnrollPlayerAction;

  /// Botón para aprobar oficialmente la elegibilidad del equipo
  ///
  /// In es, this message translates to:
  /// **'Habilitar Equipo'**
  String get teamApproveEligibilityAction;

  /// Mensaje de éxito tras habilitar equipo
  ///
  /// In es, this message translates to:
  /// **'El equipo ha sido habilitado oficialmente para el campeonato'**
  String get teamEligibilityApprovedSuccess;

  /// Mensaje cuando el equipo no tiene jugadores registrados
  ///
  /// In es, this message translates to:
  /// **'No hay jugadores inscritos en este equipo aún.'**
  String get teamRosterEmpty;

  /// Etiqueta para nombre de equipo
  ///
  /// In es, this message translates to:
  /// **'Nombre del equipo'**
  String get teamFormNameLabel;

  /// Pista para nombre de equipo
  ///
  /// In es, this message translates to:
  /// **'Ej. Atlético Norte FC'**
  String get teamFormNameHint;

  /// Etiqueta para sigla de equipo
  ///
  /// In es, this message translates to:
  /// **'Sigla o Monograma (2 a 4 caracteres)'**
  String get teamFormShortCodeLabel;

  /// Pista para sigla de equipo
  ///
  /// In es, this message translates to:
  /// **'Ej. ATN'**
  String get teamFormShortCodeHint;

  /// Etiqueta para forma del escudo
  ///
  /// In es, this message translates to:
  /// **'Forma del emblema'**
  String get teamFormCrestShapeLabel;

  /// Etiqueta para color primario
  ///
  /// In es, this message translates to:
  /// **'Color primario'**
  String get teamFormPrimaryColorLabel;

  /// Etiqueta para color secundario
  ///
  /// In es, this message translates to:
  /// **'Color secundario'**
  String get teamFormSecondaryColorLabel;

  /// Botón enviar registro de equipo
  ///
  /// In es, this message translates to:
  /// **'Inscribir equipo'**
  String get teamFormSubmitCreate;

  /// Botón guardar cambios de equipo
  ///
  /// In es, this message translates to:
  /// **'Guardar cambios'**
  String get teamFormSubmitEdit;

  /// Etiqueta para nombre completo del jugador
  ///
  /// In es, this message translates to:
  /// **'Nombre completo del jugador'**
  String get playerFormFullNameLabel;

  /// Pista para nombre completo del jugador
  ///
  /// In es, this message translates to:
  /// **'Ej. Carlos Andrés Rodríguez'**
  String get playerFormFullNameHint;

  /// Etiqueta para documento de identidad
  ///
  /// In es, this message translates to:
  /// **'Documento de identidad'**
  String get playerFormDocumentLabel;

  /// Pista para documento de identidad
  ///
  /// In es, this message translates to:
  /// **'Ej. 10203040'**
  String get playerFormDocumentHint;

  /// Etiqueta para selector de posición
  ///
  /// In es, this message translates to:
  /// **'Posición en el campo'**
  String get playerFormPositionLabel;

  /// Etiqueta para dorsal del jugador
  ///
  /// In es, this message translates to:
  /// **'Número de camiseta (Dorsal)'**
  String get playerFormShirtNumberLabel;

  /// Pista para dorsal del jugador
  ///
  /// In es, this message translates to:
  /// **'1 - 99'**
  String get playerFormShirtNumberHint;

  /// Botón para inscribir jugador
  ///
  /// In es, this message translates to:
  /// **'Inscribir jugador'**
  String get playerFormSubmitEnroll;

  /// Botón para guardar jugador editado
  ///
  /// In es, this message translates to:
  /// **'Guardar jugador'**
  String get playerFormSubmitEdit;

  /// Título para confirmar eliminación de jugador
  ///
  /// In es, this message translates to:
  /// **'¿Eliminar jugador de la plantilla?'**
  String get playerRemoveConfirmTitle;

  /// Mensaje de confirmación para retirar jugador
  ///
  /// In es, this message translates to:
  /// **'¿Estás seguro de que deseas retirar a {name} de este equipo?'**
  String playerRemoveConfirmMessage(String name);

  /// Botón de acción para retirar jugador
  ///
  /// In es, this message translates to:
  /// **'Retirar jugador'**
  String get playerRemoveAction;

  /// Error de validación cuando el dorsal ya está ocupado
  ///
  /// In es, this message translates to:
  /// **'El número de camiseta {number} ya está en uso en este equipo.'**
  String teamErrorDuplicateShirtNumber(int number);

  /// Error de validación cuando el jugador ya pertenece a otro equipo del campeonato
  ///
  /// In es, this message translates to:
  /// **'Este jugador ya se encuentra inscrito en otro equipo de este campeonato.'**
  String get teamErrorPlayerAlreadyRegisteredInTournament;

  /// Error cuando el nombre del equipo está repetido en el torneo
  ///
  /// In es, this message translates to:
  /// **'Ya existe un equipo con este nombre en este campeonato'**
  String get teamErrorDuplicateTeamName;

  /// Error cuando el campeonato no está en Inscripciones Abiertas
  ///
  /// In es, this message translates to:
  /// **'Las inscripciones de este campeonato están cerradas'**
  String get teamErrorRegistrationsClosed;

  /// Error cuando se intenta agregar más jugadores del cupo máximo
  ///
  /// In es, this message translates to:
  /// **'El equipo ya alcanzó el cupo máximo de jugadores permitido'**
  String get teamErrorMaxPlayersQuotaReached;

  /// Error al intentar habilitar un equipo que no cumple el mínimo
  ///
  /// In es, this message translates to:
  /// **'El equipo aún no alcanza el mínimo reglamentario de jugadores requerido por el campeonato'**
  String get teamErrorInsufficientPlayersForApproval;

  /// Error cuando el nombre del equipo es muy corto
  ///
  /// In es, this message translates to:
  /// **'El nombre del equipo debe tener al menos 3 caracteres'**
  String get teamErrorInvalidTeamName;

  /// Error cuando la sigla no tiene 2 a 4 caracteres
  ///
  /// In es, this message translates to:
  /// **'La sigla debe tener entre 2 y 4 caracteres'**
  String get teamErrorInvalidShortCode;

  /// Error cuando el nombre del jugador es muy corto
  ///
  /// In es, this message translates to:
  /// **'El nombre del jugador debe tener al menos 3 caracteres'**
  String get teamErrorInvalidPlayerName;

  /// Error cuando el documento tiene menos de 5 caracteres
  ///
  /// In es, this message translates to:
  /// **'El documento de identidad debe tener al menos 5 caracteres'**
  String get teamErrorInvalidDocumentId;

  /// Error cuando el dorsal está fuera del rango 1 a 99
  ///
  /// In es, this message translates to:
  /// **'El número de camiseta debe estar entre 1 y 99'**
  String get teamErrorInvalidShirtNumber;

  /// Título de la pantalla de gestión de convocatoria y seguimiento del entrenador
  ///
  /// In es, this message translates to:
  /// **'Convocatoria y Seguimiento'**
  String get lineupScreenTitle;

  /// Pestaña de convocatoria del partido
  ///
  /// In es, this message translates to:
  /// **'Convocatoria'**
  String get lineupTabConvocation;

  /// Pestaña de seguimiento interno del plantel
  ///
  /// In es, this message translates to:
  /// **'Seguimiento Interno'**
  String get lineupTabTracking;

  /// Pestaña de nómina oficial sincronizada para el acta arbitral
  ///
  /// In es, this message translates to:
  /// **'Acta Arbitral'**
  String get lineupTabRefereeRoster;

  /// Encabezado de la lista de titulares
  ///
  /// In es, this message translates to:
  /// **'Titulares en Cancha'**
  String get lineupStartersHeader;

  /// Encabezado de la lista de suplentes
  ///
  /// In es, this message translates to:
  /// **'Suplentes Habilitados'**
  String get lineupSubstitutesHeader;

  /// Encabezado de jugadores no convocados
  ///
  /// In es, this message translates to:
  /// **'No Convocados'**
  String get lineupNotConvokedHeader;

  /// Etiqueta para jugador titular
  ///
  /// In es, this message translates to:
  /// **'Titular'**
  String get lineupRoleStarter;

  /// Etiqueta para jugador suplente
  ///
  /// In es, this message translates to:
  /// **'Suplente'**
  String get lineupRoleSubstitute;

  /// Etiqueta para jugador no convocado
  ///
  /// In es, this message translates to:
  /// **'No convocado'**
  String get lineupRoleNotConvoked;

  /// Insignia de capitán designado
  ///
  /// In es, this message translates to:
  /// **'Capitán'**
  String get lineupCaptainBadge;

  /// Acción para designar a un jugador titular como capitán
  ///
  /// In es, this message translates to:
  /// **'Hacer Capitán'**
  String get lineupSetCaptainAction;

  /// Insignia de estado de borrador en edición
  ///
  /// In es, this message translates to:
  /// **'Borrador sin Confirmar'**
  String get lineupStatusDraft;

  /// Insignia de convocatoria oficial confirmada
  ///
  /// In es, this message translates to:
  /// **'Oficial Confirmada'**
  String get lineupStatusConfirmed;

  /// Botón de acción para confirmar y publicar la alineación oficial
  ///
  /// In es, this message translates to:
  /// **'Confirmar Convocatoria Oficial'**
  String get lineupConfirmAction;

  /// Botón de acción para actualizar y reconfirmar una convocatoria previa
  ///
  /// In es, this message translates to:
  /// **'Actualizar y Reconfirmar Convocatoria'**
  String get lineupReconfirmAction;

  /// Mensaje de éxito tras confirmar la alineación
  ///
  /// In es, this message translates to:
  /// **'Alineación oficial confirmada y sincronizada con el acta arbitral'**
  String get lineupSuccessConfirmation;

  /// Mensaje informativo de conservación de borrador
  ///
  /// In es, this message translates to:
  /// **'Borrador de convocatoria guardado automáticamente'**
  String get lineupDraftSavedMessage;

  /// Insignia disciplinaria para jugador suspendido por tarjeta roja o acumulación
  ///
  /// In es, this message translates to:
  /// **'Suspendido ({count} {count, plural, =1{fecha} other{fechas}})'**
  String lineupDisciplinarySuspended(int count);

  /// Insignia preventiva para jugador a una tarjeta de la suspensión
  ///
  /// In es, this message translates to:
  /// **'En capilla ({count} TA)'**
  String lineupDisciplinaryWarning(int count);

  /// Insignia para jugador habilitado
  ///
  /// In es, this message translates to:
  /// **'Habilitado'**
  String get lineupDisciplinaryEligible;

  /// Conteo de partidos jugados
  ///
  /// In es, this message translates to:
  /// **'Partidos: {count}'**
  String lineupTrackingMatches(int count);

  /// Conteo de goles anotados
  ///
  /// In es, this message translates to:
  /// **'Goles: {count}'**
  String lineupTrackingGoals(int count);

  /// Conteo de asistencias
  ///
  /// In es, this message translates to:
  /// **'Asistencias: {count}'**
  String lineupTrackingAssists(int count);

  /// Conteo de tarjetas amarillas
  ///
  /// In es, this message translates to:
  /// **'Amarillas: {count}'**
  String lineupTrackingYellowCards(int count);

  /// Conteo de tarjetas rojas
  ///
  /// In es, this message translates to:
  /// **'Rojas: {count}'**
  String lineupTrackingRedCards(int count);

  /// Fechas de suspensión pendientes
  ///
  /// In es, this message translates to:
  /// **'Sanción: {count} {count, plural, =1{fecha} other{fechas}}'**
  String lineupTrackingSuspensionPending(int count);

  /// Botón para editar las estadísticas internas de un jugador
  ///
  /// In es, this message translates to:
  /// **'Actualizar Métricas'**
  String get lineupTrackingEditAction;

  /// Mensaje de éxito tras actualizar métricas de un jugador
  ///
  /// In es, this message translates to:
  /// **'Métricas de seguimiento actualizadas con éxito'**
  String get lineupTrackingSaveSuccess;

  /// Título de la nómina del árbitro
  ///
  /// In es, this message translates to:
  /// **'Nómina Oficial Sincronizada (Acta Arbitral)'**
  String get lineupRefereeRosterTitle;

  /// Mensaje cuando no hay alineación confirmada para el árbitro
  ///
  /// In es, this message translates to:
  /// **'El entrenador aún no ha confirmado la alineación oficial para este partido.'**
  String get lineupRefereeRosterEmpty;

  /// Botón de acción en la pantalla de detalle de equipo para abrir la convocatoria
  ///
  /// In es, this message translates to:
  /// **'Gestionar Convocatoria y Seguimiento'**
  String get lineupOpenAction;

  /// Error cuando el número de titulares no coincide con la modalidad
  ///
  /// In es, this message translates to:
  /// **'Debes seleccionar exactamente {required} titulares (actual: {selected}).'**
  String lineupErrorStartersCount(int required, int selected);

  /// Error cuando no se ha asignado capitán o el capitán no es titular
  ///
  /// In es, this message translates to:
  /// **'Debes designar un capitán dentro de los jugadores titulares.'**
  String get lineupErrorMissingCaptain;

  /// Error al intentar incluir a un jugador sancionado
  ///
  /// In es, this message translates to:
  /// **'No puedes convocar al jugador {name} porque se encuentra suspendido ({count} {count, plural, =1{fecha} other{fechas}}).'**
  String lineupErrorSuspendedPlayer(String name, int count);

  /// Error si el equipo aún no está habilitado
  ///
  /// In es, this message translates to:
  /// **'El equipo debe estar oficialmente Habilitado para confirmar una alineación oficial.'**
  String get lineupErrorTeamNotEligible;

  /// Error si el usuario no tiene permisos
  ///
  /// In es, this message translates to:
  /// **'No tienes permisos para gestionar la convocatoria de este equipo.'**
  String get lineupErrorUnauthorized;

  /// Etiqueta del chip de jornada en el selector horizontal
  ///
  /// In es, this message translates to:
  /// **'Jornada {number}'**
  String matchdayRoundChip(int number);

  /// Filtro para ver todos los partidos
  ///
  /// In es, this message translates to:
  /// **'Todos'**
  String get matchdayFilterAll;

  /// Filtro de partidos pendientes de programación
  ///
  /// In es, this message translates to:
  /// **'Pendiente'**
  String get matchdayFilterPending;

  /// Filtro de partidos programados
  ///
  /// In es, this message translates to:
  /// **'Programado'**
  String get matchdayFilterScheduled;

  /// Filtro de partidos finalizados
  ///
  /// In es, this message translates to:
  /// **'Finalizado'**
  String get matchdayFilterCompleted;

  /// Opción para no filtrar por equipo
  ///
  /// In es, this message translates to:
  /// **'Todos los equipos'**
  String get matchdayFilterTeamAll;

  /// Botón del organizador para generar el fixture oficial
  ///
  /// In es, this message translates to:
  /// **'Generar Fixture'**
  String get matchdayGenerateFixtureButton;

  /// Título del diálogo de confirmación para generar fixture
  ///
  /// In es, this message translates to:
  /// **'Generar Fixture Oficial'**
  String get matchdayGenerateFixtureDialogTitle;

  /// Mensaje de confirmación de generación de fixture
  ///
  /// In es, this message translates to:
  /// **'¿Deseas generar automáticamente el fixture de partidos para este campeonato? Se crearán todas las jornadas correspondientes a los equipos habilitados.'**
  String get matchdayGenerateFixtureDialogMessage;

  /// Botón de confirmación en el diálogo de generación de fixture
  ///
  /// In es, this message translates to:
  /// **'Generar Calendario'**
  String get matchdayGenerateFixtureConfirmButton;

  /// Botón para cancelar la generación de fixture
  ///
  /// In es, this message translates to:
  /// **'Cancelar'**
  String get matchdayGenerateFixtureCancelButton;

  /// Mensaje de éxito tras generar el fixture
  ///
  /// In es, this message translates to:
  /// **'Fixture generado exitosamente ({count} partidos creados).'**
  String matchdayFixtureGeneratedSuccess(int count);

  /// Título de estado vacío en la pestaña de jornada
  ///
  /// In es, this message translates to:
  /// **'No hay partidos en el fixture'**
  String get matchdayEmptyFixtureTitle;

  /// Subtítulo de estado vacío en la pestaña de jornada
  ///
  /// In es, this message translates to:
  /// **'Aún no se ha generado el calendario de partidos para este campeonato.'**
  String get matchdayEmptyFixtureSubtitle;

  /// Mensaje cuando ningún partido coincide con los filtros aplicados
  ///
  /// In es, this message translates to:
  /// **'No hay partidos que coincidan con los filtros seleccionados.'**
  String get matchdayNoMatchesFiltered;

  /// Chip selector de fecha: día de hoy
  ///
  /// In es, this message translates to:
  /// **'Hoy'**
  String get matchdayDateToday;

  /// Chip selector de fecha: día de mañana
  ///
  /// In es, this message translates to:
  /// **'Mañana'**
  String get matchdayDateTomorrow;

  /// Título de la sección de partidos por programar exclusiva para el Organizador
  ///
  /// In es, this message translates to:
  /// **'Por programar ({count})'**
  String matchdayUnscheduledSectionTitle(int count);

  /// Mensaje informativo cuando no existen partidos en la fecha calendario seleccionada
  ///
  /// In es, this message translates to:
  /// **'No hay partidos programados para esta fecha.'**
  String get matchdayNoMatchesForDate;

  /// Estado del partido: pendiente de asignación
  ///
  /// In es, this message translates to:
  /// **'Pendiente de Programación'**
  String get matchStatusPending;

  /// Estado del partido: fecha y recursos asignados
  ///
  /// In es, this message translates to:
  /// **'Programado'**
  String get matchStatusScheduled;

  /// Estado del partido: en disputa activa
  ///
  /// In es, this message translates to:
  /// **'En Juego'**
  String get matchStatusInProgress;

  /// Estado del partido: finalizado con resultado oficial
  ///
  /// In es, this message translates to:
  /// **'Finalizado'**
  String get matchStatusCompleted;

  /// Estado del partido: cancelado
  ///
  /// In es, this message translates to:
  /// **'Cancelado'**
  String get matchStatusCancelled;

  /// Acción para abrir el diálogo de programación de partido
  ///
  /// In es, this message translates to:
  /// **'Programar Partido'**
  String get scheduleMatchAction;

  /// Título del modal de programación de partido
  ///
  /// In es, this message translates to:
  /// **'Programar Partido'**
  String get scheduleMatchDialogTitle;

  /// Etiqueta para seleccionar la fecha del encuentro
  ///
  /// In es, this message translates to:
  /// **'Fecha del Partido'**
  String get scheduleMatchDateLabel;

  /// Etiqueta para seleccionar la hora de inicio del encuentro
  ///
  /// In es, this message translates to:
  /// **'Hora de Inicio'**
  String get scheduleMatchTimeLabel;

  /// Etiqueta del selector de sede deportiva
  ///
  /// In es, this message translates to:
  /// **'Sede Deportiva'**
  String get scheduleMatchVenueLabel;

  /// Etiqueta del selector de cancha específica
  ///
  /// In es, this message translates to:
  /// **'Cancha'**
  String get scheduleMatchPitchLabel;

  /// Etiqueta del selector de árbitro oficial
  ///
  /// In es, this message translates to:
  /// **'Árbitro Oficial'**
  String get scheduleMatchRefereeLabel;

  /// Texto por defecto al elegir sede
  ///
  /// In es, this message translates to:
  /// **'Selecciona una sede'**
  String get scheduleMatchSelectVenuePrompt;

  /// Texto por defecto al elegir cancha
  ///
  /// In es, this message translates to:
  /// **'Selecciona una cancha'**
  String get scheduleMatchSelectPitchPrompt;

  /// Texto por defecto al elegir árbitro
  ///
  /// In es, this message translates to:
  /// **'Selecciona un árbitro'**
  String get scheduleMatchSelectRefereePrompt;

  /// Botón para guardar la programación del partido
  ///
  /// In es, this message translates to:
  /// **'Confirmar Programación'**
  String get scheduleMatchSaveButton;

  /// Notificación de guardado exitoso de partido programado
  ///
  /// In es, this message translates to:
  /// **'Partido programado exitosamente.'**
  String get scheduleMatchSuccessMessage;

  /// Error cuando se intenta programar un partido para una fecha u hora anterior al momento actual
  ///
  /// In es, this message translates to:
  /// **'No puedes programar un partido en una fecha u hora pasada.'**
  String get scheduleMatchPastDateTimeError;

  /// Título de colisión por cruce en la misma cancha
  ///
  /// In es, this message translates to:
  /// **'Conflicto de Cancha'**
  String get scheduleCollisionPitchTitle;

  /// Título de colisión por doble designación del árbitro
  ///
  /// In es, this message translates to:
  /// **'Conflicto de Árbitro'**
  String get scheduleCollisionRefereeTitle;

  /// Título de colisión por doble partido simultáneo del equipo
  ///
  /// In es, this message translates to:
  /// **'Conflicto de Equipo'**
  String get scheduleCollisionTeamTitle;

  /// Mensaje de conflicto cuando la cancha está ocupada
  ///
  /// In es, this message translates to:
  /// **'La cancha {pitchName} ya se encuentra ocupada en el horario seleccionado ({startTime} - {endTime}).'**
  String scheduleCollisionPitchMessage(
    String pitchName,
    String startTime,
    String endTime,
  );

  /// Mensaje de conflicto cuando el árbitro está asignado a otro partido simultáneo
  ///
  /// In es, this message translates to:
  /// **'El árbitro {refereeName} ya tiene otro partido designado en ese horario ({startTime} - {endTime}).'**
  String scheduleCollisionRefereeMessage(
    String refereeName,
    String startTime,
    String endTime,
  );

  /// Mensaje de conflicto cuando un equipo tiene partidos superpuestos
  ///
  /// In es, this message translates to:
  /// **'El equipo {teamName} ya tiene otro partido programado en ese horario ({startTime} - {endTime}).'**
  String scheduleCollisionTeamMessage(
    String teamName,
    String startTime,
    String endTime,
  );

  /// Error cuando el usuario no tiene permisos de organizador
  ///
  /// In es, this message translates to:
  /// **'No tienes permisos de organizador para generar o programar partidos.'**
  String get fixtureErrorUnauthorized;

  /// Error cuando hay menos de 2 equipos habilitados
  ///
  /// In es, this message translates to:
  /// **'Se requieren al menos 2 equipos habilitados para generar el fixture.'**
  String get fixtureErrorInsufficientTeams;

  /// Error al intentar regenerar fixture con actas disputadas
  ///
  /// In es, this message translates to:
  /// **'No se puede regenerar el fixture porque ya existen partidos en juego o finalizados.'**
  String get fixtureErrorRegenerationBlocked;

  /// Error de fecha u hora no válida
  ///
  /// In es, this message translates to:
  /// **'La hora de inicio o duración del partido no son válidas.'**
  String get fixtureErrorInvalidTimes;

  /// Título principal de la pantalla del acta digital del árbitro
  ///
  /// In es, this message translates to:
  /// **'Acta Digital del Árbitro'**
  String get matchReportTitle;

  /// Encabezado de la vista del acta
  ///
  /// In es, this message translates to:
  /// **'Acta del Partido'**
  String get matchReportHeaderTitle;

  /// Periodo de partido: Por Iniciar
  ///
  /// In es, this message translates to:
  /// **'Por Iniciar'**
  String get matchPeriodNotStarted;

  /// Periodo de partido: Primer Tiempo
  ///
  /// In es, this message translates to:
  /// **'Primer Tiempo'**
  String get matchPeriodFirstHalf;

  /// Periodo de partido: Descanso
  ///
  /// In es, this message translates to:
  /// **'Descanso'**
  String get matchPeriodHalfTime;

  /// Periodo de partido: Segundo Tiempo
  ///
  /// In es, this message translates to:
  /// **'Segundo Tiempo'**
  String get matchPeriodSecondHalf;

  /// Periodo de partido: Tiempo Cumplido
  ///
  /// In es, this message translates to:
  /// **'Tiempo Cumplido'**
  String get matchPeriodFullTime;

  /// Periodo de partido: Acta Cerrada
  ///
  /// In es, this message translates to:
  /// **'Acta Cerrada'**
  String get matchPeriodClosed;

  /// Insignia semántica de partido en juego en tiempo real
  ///
  /// In es, this message translates to:
  /// **'EN JUEGO'**
  String get matchStatusLiveBadge;

  /// Insignia de partido finalizado
  ///
  /// In es, this message translates to:
  /// **'FINALIZADO'**
  String get matchStatusFinishedBadge;

  /// Acción para iniciar el primer tiempo del encuentro
  ///
  /// In es, this message translates to:
  /// **'Iniciar Partido'**
  String get matchActionStartMatch;

  /// Acción para pausar el cronómetro e iniciar el descanso
  ///
  /// In es, this message translates to:
  /// **'Fin 1er Tiempo'**
  String get matchActionEndFirstHalf;

  /// Acción para reanudar el cronómetro e iniciar el segundo tiempo
  ///
  /// In es, this message translates to:
  /// **'Iniciar 2do Tiempo'**
  String get matchActionStartSecondHalf;

  /// Acción para finalizar el tiempo reglamentario
  ///
  /// In es, this message translates to:
  /// **'Tiempo Cumplido'**
  String get matchActionEndSecondHalf;

  /// Botón de acción rápida para registrar un gol
  ///
  /// In es, this message translates to:
  /// **'Registrar Gol'**
  String get matchActionRecordGoal;

  /// Botón de acción rápida para registrar una tarjeta amarilla
  ///
  /// In es, this message translates to:
  /// **'Tarjeta Amarilla'**
  String get matchActionRecordYellowCard;

  /// Botón de acción rápida para registrar una tarjeta roja directa
  ///
  /// In es, this message translates to:
  /// **'Tarjeta Roja'**
  String get matchActionRecordRedCard;

  /// Botón de acción rápida para registrar una sustitución táctica
  ///
  /// In es, this message translates to:
  /// **'Sustitución'**
  String get matchActionRecordSubstitution;

  /// Botón para confirmar el cierre definitivo del acta arbitral
  ///
  /// In es, this message translates to:
  /// **'Cerrar Acta Oficial'**
  String get matchActionCloseReport;

  /// Botón en tarjeta de partido para abrir el acta como árbitro u organizador
  ///
  /// In es, this message translates to:
  /// **'Acta Arbitral'**
  String get matchActionOpenRefereeReport;

  /// Botón en tarjeta de partido para consultar el acta en modo lectura
  ///
  /// In es, this message translates to:
  /// **'Ver Acta'**
  String get matchActionViewReport;

  /// Aviso explícito en español cuando se registran incidencias sin conexión a internet
  ///
  /// In es, this message translates to:
  /// **'Modo sin conexión: cambios guardados en el dispositivo'**
  String get matchReportOfflineBanner;

  /// Estado de conectividad en línea
  ///
  /// In es, this message translates to:
  /// **'En línea'**
  String get matchReportOnlineStatus;

  /// Estado de conectividad sin conexión
  ///
  /// In es, this message translates to:
  /// **'Sin conexión'**
  String get matchReportOfflineStatus;

  /// Contador de eventos pendientes en cola offline
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 cambio pendiente de sincronización} other{{count} cambios pendientes de sincronización}}'**
  String matchReportPendingSyncCount(int count);

  /// Mensaje mientras se sincroniza la cola de eventos
  ///
  /// In es, this message translates to:
  /// **'Sincronizando eventos...'**
  String get matchReportSyncingEvents;

  /// Mensaje cuando la cola offline ha sido sincronizada exitosamente
  ///
  /// In es, this message translates to:
  /// **'Todos los eventos sincronizados'**
  String get matchReportAllEventsSynced;

  /// Título del modal para registrar un gol
  ///
  /// In es, this message translates to:
  /// **'Registrar Gol'**
  String get recordGoalDialogTitle;

  /// Etiqueta para seleccionar el equipo anotador
  ///
  /// In es, this message translates to:
  /// **'Equipo anotador'**
  String get recordGoalTeamLabel;

  /// Etiqueta para el minuto de juego del gol
  ///
  /// In es, this message translates to:
  /// **'Minuto del gol'**
  String get recordGoalMinuteLabel;

  /// Etiqueta para seleccionar el jugador anotador
  ///
  /// In es, this message translates to:
  /// **'Jugador anotador'**
  String get recordGoalScorerLabel;

  /// Etiqueta para seleccionar el jugador asistente
  ///
  /// In es, this message translates to:
  /// **'Jugador asistente (opcional)'**
  String get recordGoalAssistantLabel;

  /// Opción cuando un gol no tiene asistencia registrada
  ///
  /// In es, this message translates to:
  /// **'Sin asistencia'**
  String get recordGoalNoAssistantOption;

  /// Botón para confirmar el registro de gol
  ///
  /// In es, this message translates to:
  /// **'Confirmar Gol'**
  String get recordGoalConfirmAction;

  /// Título del modal para registrar tarjetas disciplinarias
  ///
  /// In es, this message translates to:
  /// **'Registrar Tarjeta Disciplinaria'**
  String get recordCardDialogTitle;

  /// Opción de tarjeta amarilla preventiva
  ///
  /// In es, this message translates to:
  /// **'Tarjeta Amarilla'**
  String get recordCardYellowTitle;

  /// Opción de tarjeta roja directa
  ///
  /// In es, this message translates to:
  /// **'Tarjeta Roja Directa'**
  String get recordCardRedTitle;

  /// Etiqueta para seleccionar el jugador amonestado
  ///
  /// In es, this message translates to:
  /// **'Jugador amonestado / sancionado'**
  String get recordCardPlayerLabel;

  /// Botón para confirmar la tarjeta disciplinaria
  ///
  /// In es, this message translates to:
  /// **'Confirmar Tarjeta'**
  String get recordCardConfirmAction;

  /// Aviso de expulsión por doble amarilla
  ///
  /// In es, this message translates to:
  /// **'Segunda Amarilla (Expulsión Automática)'**
  String get recordCardSecondYellowExpulsion;

  /// Título del modal de sustitución de jugadores
  ///
  /// In es, this message translates to:
  /// **'Registrar Sustitución'**
  String get recordSubstitutionDialogTitle;

  /// Etiqueta para seleccionar el jugador que sale
  ///
  /// In es, this message translates to:
  /// **'Jugador que sale'**
  String get recordSubstitutionPlayerOutLabel;

  /// Etiqueta para seleccionar el jugador que entra
  ///
  /// In es, this message translates to:
  /// **'Jugador que entra'**
  String get recordSubstitutionPlayerInLabel;

  /// Botón para confirmar la sustitución
  ///
  /// In es, this message translates to:
  /// **'Confirmar Sustitución'**
  String get recordSubstitutionConfirmAction;

  /// Acción para anular o deshacer una incidencia errónea
  ///
  /// In es, this message translates to:
  /// **'Anular'**
  String get matchEventUndoAction;

  /// Título de diálogo para confirmar anulación de evento
  ///
  /// In es, this message translates to:
  /// **'¿Anular incidencia del acta?'**
  String get matchEventUndoConfirmTitle;

  /// Mensaje explicativo al anular una incidencia en vivo
  ///
  /// In es, this message translates to:
  /// **'Se recalculará el marcador y el estado de sanciones del partido.'**
  String get matchEventUndoConfirmMessage;

  /// Botón de confirmación para anular incidencia
  ///
  /// In es, this message translates to:
  /// **'Anular Incidencia'**
  String get matchEventUndoConfirmButton;

  /// Título del diálogo de confirmación de cierre oficial
  ///
  /// In es, this message translates to:
  /// **'Cierre Definitivo del Acta Oficial'**
  String get closeReportDialogTitle;

  /// Título del resumen de goles y tarjetas antes de cerrar
  ///
  /// In es, this message translates to:
  /// **'Resumen Oficial del Encuentro'**
  String get closeReportSummaryTitle;

  /// Marcador final resumido
  ///
  /// In es, this message translates to:
  /// **'Marcador Final: {score}'**
  String closeReportFinalScore(String score);

  /// Advertencia de inmutabilidad al cerrar el acta
  ///
  /// In es, this message translates to:
  /// **'¿Confirmas el cierre definitivo del acta? Esta acción es irreversible y bloqueará cualquier modificación posterior.'**
  String get closeReportWarningMessage;

  /// Botón para firmar y cerrar el acta oficial
  ///
  /// In es, this message translates to:
  /// **'Confirmar y Cerrar Acta'**
  String get closeReportConfirmButton;

  /// Título de la sección de incidencias del partido
  ///
  /// In es, this message translates to:
  /// **'Línea de Tiempo'**
  String get matchTimelineTitle;

  /// Texto mostrado cuando no se han registrado eventos en el acta
  ///
  /// In es, this message translates to:
  /// **'No hay incidencias registradas aún en el partido.'**
  String get matchTimelineEmpty;

  /// Descripción de gol en la línea de tiempo
  ///
  /// In es, this message translates to:
  /// **'Gol de {player}'**
  String matchEventGoalDescription(String player);

  /// Descripción de asistencia en la línea de tiempo
  ///
  /// In es, this message translates to:
  /// **'Asistencia: {player}'**
  String matchEventAssistantDescription(String player);

  /// Descripción de tarjeta amarilla en línea de tiempo
  ///
  /// In es, this message translates to:
  /// **'Tarjeta Amarilla - {player}'**
  String matchEventYellowCardDescription(String player);

  /// Descripción de expulsión por doble amarilla en línea de tiempo
  ///
  /// In es, this message translates to:
  /// **'Segunda Amarilla y Expulsión - {player}'**
  String matchEventSecondYellowRedDescription(String player);

  /// Descripción de tarjeta roja directa en línea de tiempo
  ///
  /// In es, this message translates to:
  /// **'Tarjeta Roja Directa - {player}'**
  String matchEventDirectRedDescription(String player);

  /// Descripción de sustitución en la línea de tiempo
  ///
  /// In es, this message translates to:
  /// **'Sale {playerOut}, entra {playerIn}'**
  String matchEventSubstitutionDescription(String playerOut, String playerIn);

  /// Descripción de cambio de periodo en la línea de tiempo
  ///
  /// In es, this message translates to:
  /// **'Inicio de {period}'**
  String matchEventPeriodTransitionDescription(String period);

  /// Error cuando el rol no está autorizado para editar el acta
  ///
  /// In es, this message translates to:
  /// **'No tienes permisos de árbitro u organizador para dirigir este partido.'**
  String get matchReportErrorUnauthorized;

  /// Error al intentar editar un acta finalizada
  ///
  /// In es, this message translates to:
  /// **'El acta oficial ya ha sido cerrada y no puede ser modificada.'**
  String get matchReportErrorAlreadyClosed;

  /// Error cuando el partido no está en primer o segundo tiempo
  ///
  /// In es, this message translates to:
  /// **'El partido debe estar en juego para registrar incidencias.'**
  String get matchReportErrorNotInProgress;

  /// Error de validación de minuto de juego
  ///
  /// In es, this message translates to:
  /// **'El minuto debe estar entre 1 y 130.'**
  String get matchReportErrorInvalidMinute;

  /// Error al intentar seleccionar a un jugador expulsado
  ///
  /// In es, this message translates to:
  /// **'El jugador ya fue expulsado y no puede realizar nuevas acciones en el partido.'**
  String get matchReportErrorPlayerExpelled;

  /// Error cuando el asistente coincide con el anotador
  ///
  /// In es, this message translates to:
  /// **'El jugador asistente no puede ser el mismo anotador ni pertenecer al equipo contrario.'**
  String get matchReportErrorInvalidAssistant;

  /// Error cuando los jugadores de la sustitución son inválidos
  ///
  /// In es, this message translates to:
  /// **'El jugador que sale y el que entra deben ser diferentes y no estar expulsados.'**
  String get matchReportErrorInvalidSubstitution;

  /// Chip selector para la vista de Tabla de Posiciones
  ///
  /// In es, this message translates to:
  /// **'Posiciones'**
  String get competitiveViewStandings;

  /// Chip selector para la vista de Llaves Eliminatorias
  ///
  /// In es, this message translates to:
  /// **'Llaves'**
  String get competitiveViewBrackets;

  /// Chip selector para la vista de Rankings Deportivos
  ///
  /// In es, this message translates to:
  /// **'Rankings'**
  String get competitiveViewRankings;

  /// Título de la tarjeta de tabla de posiciones
  ///
  /// In es, this message translates to:
  /// **'Tabla de Posiciones Oficial'**
  String get standingsTableTitle;

  /// Subtítulo explicativo de la tabla de posiciones
  ///
  /// In es, this message translates to:
  /// **'Clasificación determinista calculada a partir de actas oficiales cerradas'**
  String get standingsTableSubtitle;

  /// Columna Posición en tabla
  ///
  /// In es, this message translates to:
  /// **'POS'**
  String get standingsColPos;

  /// Columna Equipo en tabla
  ///
  /// In es, this message translates to:
  /// **'EQUIPO'**
  String get standingsColTeam;

  /// Columna Partidos Jugados
  ///
  /// In es, this message translates to:
  /// **'PJ'**
  String get standingsColPlayed;

  /// Columna Partidos Ganados
  ///
  /// In es, this message translates to:
  /// **'PG'**
  String get standingsColWon;

  /// Columna Partidos Empatados
  ///
  /// In es, this message translates to:
  /// **'PE'**
  String get standingsColDrawn;

  /// Columna Partidos Perdidos
  ///
  /// In es, this message translates to:
  /// **'PP'**
  String get standingsColLost;

  /// Columna Goles a Favor
  ///
  /// In es, this message translates to:
  /// **'GF'**
  String get standingsColGoalsFor;

  /// Columna Goles en Contra
  ///
  /// In es, this message translates to:
  /// **'GC'**
  String get standingsColGoalsAgainst;

  /// Columna Diferencia de Gol
  ///
  /// In es, this message translates to:
  /// **'DG'**
  String get standingsColGoalDifference;

  /// Columna Puntos Totales
  ///
  /// In es, this message translates to:
  /// **'PTS'**
  String get standingsColPoints;

  /// Columna Puntaje Fair Play
  ///
  /// In es, this message translates to:
  /// **'FP'**
  String get standingsColFairPlay;

  /// Mensaje cuando no hay equipos para calcular la tabla
  ///
  /// In es, this message translates to:
  /// **'Aún no hay equipos habilitados en la tabla de posiciones.'**
  String get standingsEmptyTeams;

  /// Etiqueta de cantidad de partidos finalizados computados
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =0{Sin partidos finalizados} =1{1 acta cerrada} other{{count} actas cerradas}}'**
  String standingsCompletedMatchesBadge(int count);

  /// Leyenda de orden de desempate aplicado
  ///
  /// In es, this message translates to:
  /// **'Desempate activo: {criteria}'**
  String standingsTiebreakerCaption(String criteria);

  /// Leyenda de zona de clasificación en la tabla
  ///
  /// In es, this message translates to:
  /// **'Zona de clasificación / podio'**
  String get standingsQualificationZoneLabel;

  /// Indicador de empate en todos los criterios configurados
  ///
  /// In es, this message translates to:
  /// **'Empate técnico'**
  String get standingsTechnicalTieBadge;

  /// Título de la sección de llaves eliminatorias
  ///
  /// In es, this message translates to:
  /// **'Cuadro de Llaves Eliminatorias'**
  String get knockoutBracketTitle;

  /// Subtítulo del cuadro de llaves
  ///
  /// In es, this message translates to:
  /// **'Avance automático de ganadores tras cierre de acta oficial'**
  String get knockoutBracketSubtitle;

  /// Modo de vista por rondas individuales con tarjetas Vs
  ///
  /// In es, this message translates to:
  /// **'Por Rondas'**
  String get knockoutViewModeByRound;

  /// Modo de visor panorámico desplazable en 2D
  ///
  /// In es, this message translates to:
  /// **'Visor 2D'**
  String get knockoutViewModePanoramic;

  /// Etiqueta cuando aún no se conoce el equipo clasificado
  ///
  /// In es, this message translates to:
  /// **'Por definir'**
  String get knockoutTbdTeam;

  /// Etiqueta de resultado de tanda de penales
  ///
  /// In es, this message translates to:
  /// **'Penales: {homePen} - {awayPen}'**
  String knockoutPenaltyShootoutBadge(int homePen, int awayPen);

  /// Etiqueta indicando el ganador que avanza de ronda
  ///
  /// In es, this message translates to:
  /// **'Clasifica: {team}'**
  String knockoutWinnerAdvancesBadge(String team);

  /// Banner del equipo campeón de la final
  ///
  /// In es, this message translates to:
  /// **'Campeón Oficial: {team}'**
  String knockoutChampionBannerTitle(String team);

  /// Título de la tarjeta de rankings deportivos
  ///
  /// In es, this message translates to:
  /// **'Rankings y Estadísticas Deportivas'**
  String get rankingsSectionTitle;

  /// Subtítulo de la tarjeta de rankings
  ///
  /// In es, this message translates to:
  /// **'Líderes individuales y tabla disciplinaria Fair Play'**
  String get rankingsSectionSubtitle;

  /// Pestaña de máximos goleadores
  ///
  /// In es, this message translates to:
  /// **'Goleadores'**
  String get rankingsCategoryScorers;

  /// Pestaña de líderes de asistencias
  ///
  /// In es, this message translates to:
  /// **'Asistencias'**
  String get rankingsCategoryAssists;

  /// Pestaña de tabla disciplinaria Fair Play
  ///
  /// In es, this message translates to:
  /// **'Fair Play'**
  String get rankingsCategoryFairPlay;

  /// Estado vacío de tabla de goleadores
  ///
  /// In es, this message translates to:
  /// **'Aún no se han registrado goles en actas oficiales cerradas.'**
  String get rankingsEmptyScorers;

  /// Estado vacío de tabla de asistencias
  ///
  /// In es, this message translates to:
  /// **'Aún no se han registrado asistencias en actas oficiales cerradas.'**
  String get rankingsEmptyAssists;

  /// Estado vacío de tabla Fair Play
  ///
  /// In es, this message translates to:
  /// **'Aún no hay equipos evaluados en la clasificación Fair Play.'**
  String get rankingsEmptyFairPlay;

  /// Unidad de goles anotados
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 gol} other{{count} goles}}'**
  String rankingsGoalsUnit(int count);

  /// Unidad de asistencias
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 asist.} other{{count} asist.}}'**
  String rankingsAssistsUnit(int count);

  /// Unidad de puntos de penalización Fair Play
  ///
  /// In es, this message translates to:
  /// **'{points} pts FP'**
  String rankingsFairPlayPointsUnit(int points);

  /// Leyenda de ponderación de tarjetas en Fair Play
  ///
  /// In es, this message translates to:
  /// **'Ponderación oficial: Amarilla (-1 pt) · Doble Amarilla/Roja (-3 pts) · Roja Directa (-3 pts)'**
  String get rankingsFairPlayLegend;

  /// Título del perfil de rendimiento del jugador
  ///
  /// In es, this message translates to:
  /// **'Perfil de Rendimiento'**
  String get playerProfileTitle;

  /// Subtítulo del perfil de rendimiento del jugador
  ///
  /// In es, this message translates to:
  /// **'Estadísticas oficiales consolidadas del torneo'**
  String get playerProfileSubtitle;

  /// Botón de acceso directo a mi perfil deportivo
  ///
  /// In es, this message translates to:
  /// **'Mi Perfil Deportivo'**
  String get playerProfileMyProfileButton;

  /// Estado disciplinario habilitado
  ///
  /// In es, this message translates to:
  /// **'Habilitado'**
  String get playerDisciplinaryStatusEnabled;

  /// Estado disciplinario suspendido
  ///
  /// In es, this message translates to:
  /// **'Suspendido'**
  String get playerDisciplinaryStatusSuspended;

  /// Etiqueta métrica de partidos jugados
  ///
  /// In es, this message translates to:
  /// **'Partidos'**
  String get playerMetricMatchesPlayed;

  /// Etiqueta métrica de titularidades
  ///
  /// In es, this message translates to:
  /// **'Titularidades'**
  String get playerMetricStarts;

  /// Etiqueta métrica de goles anotados
  ///
  /// In es, this message translates to:
  /// **'Goles'**
  String get playerMetricGoals;

  /// Etiqueta métrica de asistencias dadas
  ///
  /// In es, this message translates to:
  /// **'Asistencias'**
  String get playerMetricAssists;

  /// Etiqueta métrica de promedio de gol por partido
  ///
  /// In es, this message translates to:
  /// **'Promedio de Gol'**
  String get playerMetricGoalAverage;

  /// Etiqueta métrica de tarjetas amarillas
  ///
  /// In es, this message translates to:
  /// **'Tarjetas Amarillas'**
  String get playerMetricYellowCards;

  /// Etiqueta métrica de tarjetas rojas
  ///
  /// In es, this message translates to:
  /// **'Tarjetas Rojas'**
  String get playerMetricRedCards;

  /// Título de la sección de partidos disputados por el jugador
  ///
  /// In es, this message translates to:
  /// **'Historial Partido por Partido'**
  String get playerMatchBreakdownTitle;

  /// Mensaje exacto cuando un jugador no registra participaciones oficiales
  ///
  /// In es, this message translates to:
  /// **'Aún no registras participaciones en partidos oficiales de este torneo.'**
  String get playerEmptyParticipationsMessage;

  /// Insignia de titular en el partido
  ///
  /// In es, this message translates to:
  /// **'Titular'**
  String get playerStarterBadge;

  /// Insignia de suplente en el partido
  ///
  /// In es, this message translates to:
  /// **'Suplente'**
  String get playerSubstituteBadge;

  /// Título de la ficha de estadísticas detalladas del equipo
  ///
  /// In es, this message translates to:
  /// **'Ficha del Equipo'**
  String get teamDetailedStatsTitle;

  /// Título de la racha de los últimos 5 partidos
  ///
  /// In es, this message translates to:
  /// **'Racha Reciente'**
  String get teamRecentFormTitle;

  /// Mensaje de racha vacía para el equipo
  ///
  /// In es, this message translates to:
  /// **'Aún no hay partidos finalizados para calcular la racha.'**
  String get teamRecentFormEmpty;

  /// Título de la lista de partidos completados por el equipo
  ///
  /// In es, this message translates to:
  /// **'Historial de Resultados'**
  String get teamCompletedMatchesTitle;

  /// Mensaje cuando no hay partidos finalizados para el equipo
  ///
  /// In es, this message translates to:
  /// **'No hay resultados oficiales registrados aún.'**
  String get teamCompletedMatchesEmpty;

  /// Título de los próximos rivales programados del equipo
  ///
  /// In es, this message translates to:
  /// **'Próximos Encuentros'**
  String get teamUpcomingMatchesTitle;

  /// Mensaje cuando no hay partidos futuros programados
  ///
  /// In es, this message translates to:
  /// **'No hay próximos partidos programados.'**
  String get teamUpcomingMatchesEmpty;

  /// Título del listado de plantilla del equipo
  ///
  /// In es, this message translates to:
  /// **'Plantel y Aporte Individual'**
  String get teamSquadStatsTitle;

  /// Mensaje cuando la plantilla está vacía
  ///
  /// In es, this message translates to:
  /// **'No hay jugadores inscritos en este equipo.'**
  String get teamSquadStatsEmpty;

  /// Código de victoria en racha
  ///
  /// In es, this message translates to:
  /// **'V'**
  String get teamFormResultWin;

  /// Código de empate en racha
  ///
  /// In es, this message translates to:
  /// **'E'**
  String get teamFormResultDraw;

  /// Código de derrota en racha
  ///
  /// In es, this message translates to:
  /// **'D'**
  String get teamFormResultLoss;

  /// Etiqueta del selector de partidos en jornada
  ///
  /// In es, this message translates to:
  /// **'Partidos'**
  String get segmentedMatches;

  /// Etiqueta del selector de noticias en jornada
  ///
  /// In es, this message translates to:
  /// **'Noticias'**
  String get segmentedNews;

  /// Insignia semántica para partidos en juego
  ///
  /// In es, this message translates to:
  /// **'EN VIVO'**
  String get matchLiveBadge;

  /// Título de la sección destacada de partidos en juego
  ///
  /// In es, this message translates to:
  /// **'Partidos en Juego'**
  String get matchLiveSectionTitle;

  /// Minuto transcurrido del partido en vivo
  ///
  /// In es, this message translates to:
  /// **'Minuto {minute}\''**
  String matchLiveMinute(int minute);

  /// Periodo del partido en vivo
  ///
  /// In es, this message translates to:
  /// **'Periodo: {period}'**
  String matchLivePeriod(String period);

  /// Aviso de desconexión en seguimiento en vivo
  ///
  /// In es, this message translates to:
  /// **'Modo sin conexión - Marcador en caché'**
  String get matchLiveOfflineBanner;

  /// Título del feed de noticias del torneo
  ///
  /// In es, this message translates to:
  /// **'Comunicados y Noticias Oficiales'**
  String get newsFeedTitle;

  /// Filtro para ver todas las categorías de noticias
  ///
  /// In es, this message translates to:
  /// **'Todas'**
  String get newsCategoryAll;

  /// Categoría avisos generales
  ///
  /// In es, this message translates to:
  /// **'Avisos Generales'**
  String get newsCategoryGeneral;

  /// Categoría boletines disciplinarios
  ///
  /// In es, this message translates to:
  /// **'Boletines Disciplinarios'**
  String get newsCategoryDisciplinary;

  /// Categoría reprogramaciones
  ///
  /// In es, this message translates to:
  /// **'Reprogramaciones'**
  String get newsCategoryRescheduling;

  /// Estado vacío del feed de noticias
  ///
  /// In es, this message translates to:
  /// **'No hay noticias ni comunicados oficiales publicados para este torneo.'**
  String get newsFeedEmpty;

  /// Botón de acción para publicar noticias (solo organizador)
  ///
  /// In es, this message translates to:
  /// **'Nueva Noticia'**
  String get newsCreateButton;

  /// Título del diálogo modal de creación de noticia
  ///
  /// In es, this message translates to:
  /// **'Publicar Noticia Oficial'**
  String get newsCreateDialogTitle;

  /// Campo de título de noticia
  ///
  /// In es, this message translates to:
  /// **'Título del Comunicado'**
  String get newsTitleField;

  /// Error de validación de título de noticia
  ///
  /// In es, this message translates to:
  /// **'El título debe tener entre 3 y 120 caracteres'**
  String get newsTitleValidation;

  /// Campo de contenido de noticia
  ///
  /// In es, this message translates to:
  /// **'Contenido del Comunicado'**
  String get newsBodyField;

  /// Error de validación de contenido de noticia
  ///
  /// In es, this message translates to:
  /// **'El contenido debe tener entre 5 y 3000 caracteres'**
  String get newsBodyValidation;

  /// Selector de categoría de noticia
  ///
  /// In es, this message translates to:
  /// **'Categoría'**
  String get newsCategoryField;

  /// Interruptor para fijar comunicado
  ///
  /// In es, this message translates to:
  /// **'Fijar en la parte superior'**
  String get newsPinnedField;

  /// Botón de confirmación para publicar
  ///
  /// In es, this message translates to:
  /// **'Publicar Comunicado'**
  String get newsPublishSubmit;

  /// Título de confirmación de borrado de noticia
  ///
  /// In es, this message translates to:
  /// **'¿Eliminar comunicado?'**
  String get newsDeleteConfirmTitle;

  /// Mensaje de confirmación de borrado de noticia
  ///
  /// In es, this message translates to:
  /// **'Esta acción eliminará permanentemente la noticia oficial seleccionada.'**
  String get newsDeleteConfirmMessage;

  /// Confirmación tras borrar noticia
  ///
  /// In es, this message translates to:
  /// **'Comunicado eliminado correctamente'**
  String get newsDeletedSuccess;

  /// Confirmación tras publicar noticia
  ///
  /// In es, this message translates to:
  /// **'Comunicado publicado con éxito'**
  String get newsPublishedSuccess;

  /// Notificación al marcar un equipo favorito
  ///
  /// In es, this message translates to:
  /// **'{teamName} añadido a tus equipos favoritos'**
  String favoriteTeamAdded(String teamName);

  /// Notificación al desmarcar un equipo favorito
  ///
  /// In es, this message translates to:
  /// **'{teamName} eliminado de tus favoritos'**
  String favoriteTeamRemoved(String teamName);

  /// Tooltip del icono de favorito
  ///
  /// In es, this message translates to:
  /// **'Marcar como equipo favorito'**
  String get favoriteToggleTooltip;

  /// Mensaje de alertas activadas para equipo
  ///
  /// In es, this message translates to:
  /// **'Alertas activadas para {teamName}'**
  String favoriteNotificationsEnabled(String teamName);

  /// Mensaje de alertas silenciadas para equipo
  ///
  /// In es, this message translates to:
  /// **'Alertas desactivadas para {teamName}'**
  String favoriteNotificationsDisabled(String teamName);

  /// Título de la bandeja interna de alertas
  ///
  /// In es, this message translates to:
  /// **'Bandeja de Alertas'**
  String get alertsTrayTitle;

  /// Estado vacío de la bandeja de alertas
  ///
  /// In es, this message translates to:
  /// **'No tienes alertas o notificaciones pendientes.'**
  String get alertsTrayEmpty;

  /// Botón para marcar todas las alertas como leídas
  ///
  /// In es, this message translates to:
  /// **'Marcar todo como leído'**
  String get alertsMarkAllRead;

  /// Tooltip del badge de alertas no leídas
  ///
  /// In es, this message translates to:
  /// **'{count} alertas no leídas'**
  String alertsUnreadBadgeTooltip(int count);

  /// Aviso informativo si se rechazaron permisos push
  ///
  /// In es, this message translates to:
  /// **'Notificaciones del sistema desactivadas. Puedes consultar todas las alertas en esta bandeja.'**
  String get alertsPushDeniedWarning;

  /// Etiqueta de alerta previa a partido
  ///
  /// In es, this message translates to:
  /// **'Próximo Partido'**
  String get alertTypeUpcoming;

  /// Etiqueta de alerta de pitazo inicial
  ///
  /// In es, this message translates to:
  /// **'Partido Iniciado'**
  String get alertTypeStarted;

  /// Etiqueta de alerta de gol anotado
  ///
  /// In es, this message translates to:
  /// **'¡Gol!'**
  String get alertTypeGoal;

  /// Etiqueta de alerta de pitazo final
  ///
  /// In es, this message translates to:
  /// **'Resultado Final'**
  String get alertTypeEnded;

  /// Etiqueta de alerta de comunicado publicado
  ///
  /// In es, this message translates to:
  /// **'Nuevo Comunicado'**
  String get alertTypeNews;

  /// Título del modal de respaldo y restauración
  ///
  /// In es, this message translates to:
  /// **'Respaldo del Campeonato'**
  String get backupModalTitle;

  /// Pestaña de exportación de respaldo
  ///
  /// In es, this message translates to:
  /// **'Exportar'**
  String get backupExportTab;

  /// Pestaña de importación de respaldo
  ///
  /// In es, this message translates to:
  /// **'Importar'**
  String get backupImportTab;

  /// Botón de exportar respaldo
  ///
  /// In es, this message translates to:
  /// **'Exportar respaldo'**
  String get backupExportButton;

  /// Acción para copiar paquete JSON al portapapeles
  ///
  /// In es, this message translates to:
  /// **'Copiar paquete de respaldo'**
  String get backupCopyJsonAction;

  /// Mensaje de éxito al copiar respaldo
  ///
  /// In es, this message translates to:
  /// **'Copia de respaldo copiada al portapapeles con éxito'**
  String get backupCopySuccess;

  /// Resumen de equipos en respaldo
  ///
  /// In es, this message translates to:
  /// **'{count} equipos inscritos'**
  String backupSummaryTeams(int count);

  /// Resumen de jugadores en respaldo
  ///
  /// In es, this message translates to:
  /// **'{count} jugadores registrados'**
  String backupSummaryPlayers(int count);

  /// Resumen de partidos en respaldo
  ///
  /// In es, this message translates to:
  /// **'{count} partidos programados'**
  String backupSummaryMatches(int count);

  /// Resumen de actas en respaldo
  ///
  /// In es, this message translates to:
  /// **'{count} actas oficiales'**
  String backupSummaryReports(int count);

  /// Resumen de comunicados en respaldo
  ///
  /// In es, this message translates to:
  /// **'{count} comunicados oficiales'**
  String backupSummaryNews(int count);

  /// Etiqueta para campo de texto con respaldo JSON
  ///
  /// In es, this message translates to:
  /// **'Contenido JSON del respaldo'**
  String get backupImportInputLabel;

  /// Pista del campo de respaldo JSON
  ///
  /// In es, this message translates to:
  /// **'Pega aquí el contenido JSON del archivo de respaldo...'**
  String get backupImportInputHint;

  /// Botón para validar el respaldo antes de restaurar
  ///
  /// In es, this message translates to:
  /// **'Validar respaldo'**
  String get backupValidateAction;

  /// Botón para ejecutar la restauración del respaldo
  ///
  /// In es, this message translates to:
  /// **'Restaurar campeonato'**
  String get backupRestoreAction;

  /// Mensaje exacto mostrado cuando el archivo de respaldo es inválido o corrupto
  ///
  /// In es, this message translates to:
  /// **'El archivo de respaldo no es válido o está incompleto. No se realizaron cambios.'**
  String get backupInvalidMessage;

  /// Casilla de verificación de seguridad de dos pasos para restaurar respaldo
  ///
  /// In es, this message translates to:
  /// **'Confirmo que deseo sobrescribir los datos de este campeonato con el respaldo seleccionado.'**
  String get backupTwoStepCheckbox;

  /// Mensaje de éxito tras restaurar respaldo
  ///
  /// In es, this message translates to:
  /// **'El campeonato fue restaurado con éxito desde el respaldo.'**
  String get backupRestoreSuccess;

  /// Botón en la barra de gestión para abrir el modal de respaldo
  ///
  /// In es, this message translates to:
  /// **'Respaldo del torneo'**
  String get backupActionButton;

  /// Botón para iniciar el cierre oficial de la temporada
  ///
  /// In es, this message translates to:
  /// **'Finalizar Campeonato'**
  String get seasonClosureAction;

  /// Título del diálogo de cierre de temporada
  ///
  /// In es, this message translates to:
  /// **'Cierre Oficial de Temporada'**
  String get seasonClosureDialogTitle;

  /// Error al intentar cerrar la temporada con partidos pendientes
  ///
  /// In es, this message translates to:
  /// **'Todos los partidos obligatorios deben estar finalizados antes de cerrar el campeonato.'**
  String get seasonClosurePendingMatchesError;

  /// Casilla de verificación obligatoria para el cierre definitivo de temporada
  ///
  /// In es, this message translates to:
  /// **'Confirmo que deseo proclamar a los campeones y cerrar la temporada en modo histórico permanente.'**
  String get seasonClosureTwoStepCheckbox;

  /// Botón final para confirmar el cierre oficial
  ///
  /// In es, this message translates to:
  /// **'Confirmar Cierre Oficial'**
  String get seasonClosureConfirmAction;

  /// Mensaje de confirmación tras finalizar temporada
  ///
  /// In es, this message translates to:
  /// **'¡Temporada finalizada! El Cuadro de Honor oficial ha sido publicado.'**
  String get seasonClosureSuccess;

  /// Badge informativo de torneo en modo solo lectura permanente
  ///
  /// In es, this message translates to:
  /// **'Temporada Finalizada · Consulta Histórica'**
  String get seasonReadOnlyBadge;

  /// Título del cuadro de honor oficial de la temporada
  ///
  /// In es, this message translates to:
  /// **'Cuadro de Honor Oficial'**
  String get honorRollTitle;

  /// Etiqueta para el campeón del torneo
  ///
  /// In es, this message translates to:
  /// **'Campeón Oficial'**
  String get honorRollChampion;

  /// Etiqueta para el subcampeón del torneo
  ///
  /// In es, this message translates to:
  /// **'Subcampeón'**
  String get honorRollRunnerUp;

  /// Etiqueta para el máximo anotador del torneo
  ///
  /// In es, this message translates to:
  /// **'Máximo Goleador'**
  String get honorRollTopScorer;

  /// Etiqueta para el equipo con la mejor defensa
  ///
  /// In es, this message translates to:
  /// **'Valla Menos Vencida'**
  String get honorRollBestDefense;

  /// Conteo de goles del goleador
  ///
  /// In es, this message translates to:
  /// **'{count} goles'**
  String honorRollGoalsCount(int count);

  /// Conteo de goles recibidos de la valla menos vencida
  ///
  /// In es, this message translates to:
  /// **'{count} goles recibidos'**
  String honorRollGoalsAgainstCount(int count);

  /// Mensaje si no se registraron goles en todo el campeonato
  ///
  /// In es, this message translates to:
  /// **'Sin goles registrados'**
  String get honorRollNoGoals;

  /// Título del menú lateral de navegación
  ///
  /// In es, this message translates to:
  /// **'Menú Principal'**
  String get drawerTitle;

  /// Nombre mostrado para el usuario anónimo o invitado en el drawer
  ///
  /// In es, this message translates to:
  /// **'Aficionado Invitado'**
  String get drawerGuestUser;

  /// Subtítulo mostrado para el usuario anónimo o invitado en el drawer
  ///
  /// In es, this message translates to:
  /// **'Sesión deportiva local'**
  String get drawerGuestEmail;

  /// Opción de competiciones en el menú lateral
  ///
  /// In es, this message translates to:
  /// **'Competiciones'**
  String get drawerCompetitions;

  /// Opción de equipos en el menú lateral
  ///
  /// In es, this message translates to:
  /// **'Equipos'**
  String get drawerTeams;

  /// Opción de jugadores en el menú lateral
  ///
  /// In es, this message translates to:
  /// **'Jugadores'**
  String get drawerPlayers;

  /// Opción de sedes en el menú lateral
  ///
  /// In es, this message translates to:
  /// **'Sedes'**
  String get drawerVenues;

  /// Pista del buscador de competiciones
  ///
  /// In es, this message translates to:
  /// **'Buscar competiciones...'**
  String get searchCompetitionsHint;

  /// Pista del buscador de equipos
  ///
  /// In es, this message translates to:
  /// **'Buscar equipos...'**
  String get searchTeamsHint;

  /// Pista del buscador de jugadores
  ///
  /// In es, this message translates to:
  /// **'Buscar jugadores...'**
  String get searchPlayersHint;

  /// Opción para mostrar todos los torneos en el filtro horizontal
  ///
  /// In es, this message translates to:
  /// **'Todos'**
  String get filterAllTournaments;

  /// Mensaje de estado vacío en el directorio de competiciones
  ///
  /// In es, this message translates to:
  /// **'No se encontraron competiciones con ese criterio.'**
  String get noCompetitionsFound;

  /// Mensaje de estado vacío en el directorio de equipos
  ///
  /// In es, this message translates to:
  /// **'No se encontraron equipos con ese criterio.'**
  String get noTeamsFound;

  /// Mensaje de estado vacío en el directorio de jugadores
  ///
  /// In es, this message translates to:
  /// **'No se encontraron jugadores con ese criterio.'**
  String get noPlayersFound;

  /// Acción para crear un nuevo campeonato desde el directorio
  ///
  /// In es, this message translates to:
  /// **'Crear competición'**
  String get createCompetitionAction;

  /// Acción para inscribir un equipo desde el directorio
  ///
  /// In es, this message translates to:
  /// **'Inscribir equipo'**
  String get registerTeamAction;

  /// Acción para registrar un jugador desde el directorio
  ///
  /// In es, this message translates to:
  /// **'Registrar jugador'**
  String get registerPlayerAction;

  /// Acción para limpiar el texto ingresado en el buscador
  ///
  /// In es, this message translates to:
  /// **'Limpiar búsqueda'**
  String get clearSearchAction;

  /// Etiqueta para la pestaña de partidos de ayer
  ///
  /// In es, this message translates to:
  /// **'Ayer'**
  String get tabYesterday;

  /// Etiqueta para la pestaña de partidos de hoy
  ///
  /// In es, this message translates to:
  /// **'Hoy'**
  String get tabToday;

  /// Etiqueta para la pestaña de partidos de mañana
  ///
  /// In es, this message translates to:
  /// **'Mañana'**
  String get tabTomorrow;

  /// Tooltip para el botón de calendario en la barra superior
  ///
  /// In es, this message translates to:
  /// **'Seleccionar fecha del calendario'**
  String get calendarPickerTooltip;

  /// Mensaje principal cuando no hay partidos en la fecha seleccionada
  ///
  /// In es, this message translates to:
  /// **'No hay partidos programados para esta fecha'**
  String get emptyMatchesForDate;

  /// Sugerencia en el estado vacío de la vista de partidos
  ///
  /// In es, this message translates to:
  /// **'Prueba seleccionando otro día o consulta el calendario completo.'**
  String get emptyMatchesSuggestion;

  /// Insignia para partidos que están en juego
  ///
  /// In es, this message translates to:
  /// **'EN VIVO'**
  String get liveMatchBadge;

  /// Etiqueta para partidos finalizados
  ///
  /// In es, this message translates to:
  /// **'Final'**
  String get finalMatchBadge;

  /// Etiqueta para partidos cancelados
  ///
  /// In es, this message translates to:
  /// **'Cancelado'**
  String get cancelledMatchBadge;

  /// Aviso para el organizador sobre partidos pendientes de fecha y hora
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 partido pendiente de programar} other{{count} partidos pendientes de programar}}'**
  String organizerPendingMatchesAlert(int count);

  /// Botón de acción en el aviso de partidos pendientes
  ///
  /// In es, this message translates to:
  /// **'Programar partidos'**
  String get organizerPendingMatchesAction;

  /// Etiqueta para la opción Panel en el menú lateral
  ///
  /// In es, this message translates to:
  /// **'Panel'**
  String get drawerPanel;

  /// Título del estado preparatorio del panel
  ///
  /// In es, this message translates to:
  /// **'Panel de Control Operativo'**
  String get panelPlaceholderTitle;

  /// Descripción del estado preparatorio del panel
  ///
  /// In es, this message translates to:
  /// **'Herramientas de gestión y métricas disponibles para tu rol deportivo.'**
  String get panelPlaceholderSubtitle;

  /// Título del panel para el rol Organizador
  ///
  /// In es, this message translates to:
  /// **'Panel de Organización'**
  String get panelTitleOrganizer;

  /// Título del panel para el rol Entrenador
  ///
  /// In es, this message translates to:
  /// **'Panel Técnico'**
  String get panelTitleCoach;

  /// Título del panel para el rol Árbitro
  ///
  /// In es, this message translates to:
  /// **'Panel Arbitral'**
  String get panelTitleReferee;

  /// Título del panel para el rol Jugador
  ///
  /// In es, this message translates to:
  /// **'Ficha del Jugador'**
  String get panelTitlePlayer;

  /// Título de la sección de resumen del organizador
  ///
  /// In es, this message translates to:
  /// **'Resumen General'**
  String get organizerSummaryTitle;

  /// Etiqueta para la métrica de torneos activos
  ///
  /// In es, this message translates to:
  /// **'Torneos en Curso'**
  String get organizerMetricActiveTournaments;

  /// Etiqueta para la métrica de partidos pendientes de programación
  ///
  /// In es, this message translates to:
  /// **'Partidos por Programar'**
  String get organizerMetricPendingMatches;

  /// Etiqueta para la métrica de torneos sin fixture generado
  ///
  /// In es, this message translates to:
  /// **'Torneos sin Fixture'**
  String get organizerMetricUnseededTournaments;

  /// Título del bloque de acciones rápidas del organizador
  ///
  /// In es, this message translates to:
  /// **'Acciones Rápidas'**
  String get organizerQuickActionsTitle;

  /// Botón de acción rápida para generar fixture
  ///
  /// In es, this message translates to:
  /// **'Generar Fixture'**
  String get organizerActionGenerateFixture;

  /// Botón de acción rápida para programar partidos
  ///
  /// In es, this message translates to:
  /// **'Programar Partido'**
  String get organizerActionScheduleMatches;

  /// Botón de acción rápida para copia de seguridad
  ///
  /// In es, this message translates to:
  /// **'Copia de Seguridad'**
  String get organizerActionBackup;

  /// Título del bloque de resumen del equipo para el entrenador
  ///
  /// In es, this message translates to:
  /// **'Estado del Equipo'**
  String get coachSummaryTitle;

  /// Etiqueta de total de jugadores en plantilla
  ///
  /// In es, this message translates to:
  /// **'Plantilla Total'**
  String get coachMetricTotalPlayers;

  /// Etiqueta de jugadores habilitados
  ///
  /// In es, this message translates to:
  /// **'Habilitados'**
  String get coachMetricEligiblePlayers;

  /// Etiqueta de jugadores suspendidos
  ///
  /// In es, this message translates to:
  /// **'Suspendidos'**
  String get coachMetricSuspendedPlayers;

  /// Título del bloque de acciones para el entrenador
  ///
  /// In es, this message translates to:
  /// **'Acciones Técnicas'**
  String get coachQuickActionsTitle;

  /// Botón de acción para gestionar la alineación del próximo partido
  ///
  /// In es, this message translates to:
  /// **'Convocatoria para el Próximo Partido'**
  String get coachActionMatchLineup;

  /// Botón de acción para gestionar la plantilla de jugadores
  ///
  /// In es, this message translates to:
  /// **'Gestionar Plantilla'**
  String get coachActionManageRoster;

  /// Título para el card de próximo partido del equipo
  ///
  /// In es, this message translates to:
  /// **'Próximo Encuentro'**
  String get coachNextMatchTitle;

  /// Mensaje cuando no hay próximo partido programado para el equipo
  ///
  /// In es, this message translates to:
  /// **'Sin partidos programados próximamente'**
  String get coachNoUpcomingMatch;

  /// Título de la lista de partidos asignados al árbitro
  ///
  /// In es, this message translates to:
  /// **'Partidos Asignados'**
  String get refereeAssignedMatchesTitle;

  /// Botón de acción para abrir el acta digital del partido
  ///
  /// In es, this message translates to:
  /// **'Acta Digital'**
  String get refereeActionDigitalReport;

  /// Título del estado vacío para el árbitro
  ///
  /// In es, this message translates to:
  /// **'Sin partidos asignados'**
  String get refereeEmptyMatchesTitle;

  /// Descripción del estado vacío para el árbitro
  ///
  /// In es, this message translates to:
  /// **'Actualmente no tienes partidos designados para dirigir.'**
  String get refereeEmptyMatchesMessage;

  /// Título del estado de elegibilidad del jugador
  ///
  /// In es, this message translates to:
  /// **'Estatus Deportivo'**
  String get playerStatusTitle;

  /// Estado de jugador habilitado
  ///
  /// In es, this message translates to:
  /// **'Habilitado'**
  String get playerStatusEligible;

  /// Estado de jugador suspendido o sancionado
  ///
  /// In es, this message translates to:
  /// **'Sancionado'**
  String get playerStatusSuspended;

  /// Título de la sección de estadísticas del jugador
  ///
  /// In es, this message translates to:
  /// **'Estadísticas de Temporada'**
  String get playerStatsTitle;

  /// Etiqueta de goles anotados
  ///
  /// In es, this message translates to:
  /// **'Goles'**
  String get playerStatGoals;

  /// Etiqueta de asistencias realizadas
  ///
  /// In es, this message translates to:
  /// **'Asistencias'**
  String get playerStatAssists;

  /// Etiqueta de tarjetas amarillas
  ///
  /// In es, this message translates to:
  /// **'T. Amarillas'**
  String get playerStatYellowCards;

  /// Etiqueta de tarjetas rojas
  ///
  /// In es, this message translates to:
  /// **'T. Rojas'**
  String get playerStatRedCards;

  /// Etiqueta de partidos jugados
  ///
  /// In es, this message translates to:
  /// **'Partidos'**
  String get playerStatMatchesPlayed;

  /// Título para el próximo partido del jugador
  ///
  /// In es, this message translates to:
  /// **'Próximo Partido'**
  String get playerNextMatchTitle;

  /// Mensaje cuando el jugador no tiene próximo partido
  ///
  /// In es, this message translates to:
  /// **'Sin partido programado próximamente'**
  String get playerNoUpcomingMatch;

  /// Título de la vista restrictiva para aficionados
  ///
  /// In es, this message translates to:
  /// **'Acceso Restringido'**
  String get fanRestrictedTitle;

  /// Mensaje informativo en la vista restrictiva de panel
  ///
  /// In es, this message translates to:
  /// **'El Panel Administrativo está reservado exclusivamente para Organizadores, Entrenadores, Árbitros y Jugadores federados.'**
  String get fanRestrictedMessage;

  /// Botón para retornar a la pantalla de partidos desde la vista restringida
  ///
  /// In es, this message translates to:
  /// **'Volver a Partidos'**
  String get fanRestrictedReturnAction;

  /// Pestaña de Partidos en el detalle de competición
  ///
  /// In es, this message translates to:
  /// **'Partidos'**
  String get competitionDetailTabMatches;

  /// Pestaña de Clasificación en el detalle de competición
  ///
  /// In es, this message translates to:
  /// **'Clasificación'**
  String get competitionDetailTabStandings;

  /// Pestaña de Información en el detalle de competición
  ///
  /// In es, this message translates to:
  /// **'Información'**
  String get competitionDetailTabInfo;

  /// Título de estado vacío en la pestaña de partidos cuando el torneo no tiene fixture
  ///
  /// In es, this message translates to:
  /// **'Calendario en Preparación'**
  String get fixtureEmptyMatchesTitle;

  /// Mensaje de estado vacío en la pestaña de partidos cuando el torneo no tiene fixture
  ///
  /// In es, this message translates to:
  /// **'Esta competición aún no tiene partidos programados en su calendario oficial.'**
  String get fixtureEmptyMatchesMessage;

  /// Insignia indicando que el partido aún no tiene fecha u hora asignada
  ///
  /// In es, this message translates to:
  /// **'Pendiente de programación'**
  String get fixturePendingScheduleBadge;

  /// Encabezado de bloque de jornada en el fixture
  ///
  /// In es, this message translates to:
  /// **'Jornada {roundNumber}'**
  String fixtureRoundLabel(int roundNumber);

  /// Título de la sección de reglamento en la pestaña Información
  ///
  /// In es, this message translates to:
  /// **'Reglamento Oficial'**
  String get competitionInfoTitle;

  /// Mensaje en la pestaña Información sobre el reglamento de la competición
  ///
  /// In es, this message translates to:
  /// **'El sistema oficial de puntuación, desempates y normas disciplinarias estará disponible próximamente.'**
  String get competitionInfoMessage;

  /// Título o accesibilidad del selector de subvistas en la pestaña Clasificación
  ///
  /// In es, this message translates to:
  /// **'Vista competitiva'**
  String get competitionStandingsSubviewsTitle;

  /// Título de estado vacío cuando no hay posiciones en la competición
  ///
  /// In es, this message translates to:
  /// **'Sin Clasificación Disponible'**
  String get competitionStandingsEmptyTitle;

  /// Descripción de estado vacío cuando no hay posiciones en la competición
  ///
  /// In es, this message translates to:
  /// **'La tabla de posiciones se generará cuando se registren los primeros resultados oficiales.'**
  String get competitionStandingsEmptyDescription;

  /// Título de estado vacío cuando el torneo eliminatorio aún no tiene llaves generadas
  ///
  /// In es, this message translates to:
  /// **'Sin Llaves Disponibles'**
  String get competitionBracketsEmptyTitle;

  /// Descripción de estado vacío cuando el torneo eliminatorio aún no tiene llaves generadas
  ///
  /// In es, this message translates to:
  /// **'El cuadro eliminatorio se generará al definirse los cruces de la fase final.'**
  String get competitionBracketsEmptyDescription;

  /// Título de estado vacío cuando no hay estadísticas individuales en la competición
  ///
  /// In es, this message translates to:
  /// **'Sin Estadísticas Disponibles'**
  String get competitionRankingsEmptyTitle;

  /// Descripción de estado vacío cuando no hay estadísticas individuales en la competición
  ///
  /// In es, this message translates to:
  /// **'Los rankings de goleadores, tarjetas y vallas invictas se actualizarán con los eventos oficiales.'**
  String get competitionRankingsEmptyDescription;

  /// Título de la tarjeta resumen de la sede principal del campeonato
  ///
  /// In es, this message translates to:
  /// **'Sede Principal'**
  String get competitionMainVenueTitle;

  /// Etiqueta para la dirección de la sede principal
  ///
  /// In es, this message translates to:
  /// **'Dirección'**
  String get competitionMainVenueAddress;

  /// Cantidad de canchas disponibles en la sede principal
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 cancha disponible} other{{count} canchas disponibles}}'**
  String competitionMainVenuePitches(int count);

  /// Título de estado no encontrado en la pestaña de información
  ///
  /// In es, this message translates to:
  /// **'Competición No Encontrada'**
  String get competitionInfoNotFoundTitle;

  /// Descripción cuando la competición no existe en el catálogo
  ///
  /// In es, this message translates to:
  /// **'No se pudo cargar la información reglamentaria del campeonato solicitado.'**
  String get competitionInfoNotFoundDescription;

  /// Pestaña de Información en el detalle de equipo
  ///
  /// In es, this message translates to:
  /// **'Información'**
  String get teamDetailTabInfo;

  /// Pestaña de Partidos en el detalle de equipo
  ///
  /// In es, this message translates to:
  /// **'Partidos'**
  String get teamDetailTabMatches;

  /// Pestaña de Plantilla en el detalle de equipo
  ///
  /// In es, this message translates to:
  /// **'Plantilla'**
  String get teamDetailTabSquad;

  /// Título de estado de equipo no encontrado
  ///
  /// In es, this message translates to:
  /// **'Equipo no encontrado'**
  String get teamDetailNotFoundTitle;

  /// Mensaje de estado de equipo no encontrado
  ///
  /// In es, this message translates to:
  /// **'No se encontró la información del equipo solicitado en el catálogo local.'**
  String get teamDetailNotFoundMessage;

  /// Título de la tarjeta de ficha institucional del club
  ///
  /// In es, this message translates to:
  /// **'Ficha del Club'**
  String get teamDetailClubProfileTitle;

  /// Etiqueta del nombre oficial del club
  ///
  /// In es, this message translates to:
  /// **'Nombre oficial'**
  String get teamDetailOfficialNameLabel;

  /// Etiqueta del código corto de 3 letras
  ///
  /// In es, this message translates to:
  /// **'Código oficial'**
  String get teamDetailShortCodeLabel;

  /// Etiqueta de la competición a la que pertenece el club
  ///
  /// In es, this message translates to:
  /// **'Competición'**
  String get teamDetailCompetitionLabel;

  /// Etiqueta para la sección de colores distintivos
  ///
  /// In es, this message translates to:
  /// **'Colores distintivos'**
  String get teamDetailClubColorsLabel;

  /// Etiqueta del color primario
  ///
  /// In es, this message translates to:
  /// **'Primario'**
  String get teamDetailPrimaryColorLabel;

  /// Etiqueta del color secundario
  ///
  /// In es, this message translates to:
  /// **'Secundario'**
  String get teamDetailSecondaryColorLabel;

  /// Título de la tarjeta de último partido jugado
  ///
  /// In es, this message translates to:
  /// **'Último Partido'**
  String get teamDetailLastMatchTitle;

  /// Mensaje cuando el equipo no registra partidos finalizados previos
  ///
  /// In es, this message translates to:
  /// **'Sin partidos previos disputados'**
  String get teamDetailLastMatchEmpty;

  /// Título de la tarjeta de próximo partido en agenda
  ///
  /// In es, this message translates to:
  /// **'Próximo Partido'**
  String get teamDetailNextMatchTitle;

  /// Mensaje cuando el equipo no tiene próximos partidos agendados
  ///
  /// In es, this message translates to:
  /// **'Sin próximos partidos agendados'**
  String get teamDetailNextMatchEmpty;

  /// Etiqueta de rival en tarjeta de partido
  ///
  /// In es, this message translates to:
  /// **'Rival'**
  String get teamDetailOpponentLabel;

  /// Etiqueta de sede o cancha en tarjeta de partido
  ///
  /// In es, this message translates to:
  /// **'Sede / Cancha'**
  String get teamDetailVenueLabel;

  /// Etiqueta de fecha y hora en tarjeta de partido
  ///
  /// In es, this message translates to:
  /// **'Fecha y hora'**
  String get teamDetailDateLabel;

  /// Distintivo de condición de local para el equipo
  ///
  /// In es, this message translates to:
  /// **'Local'**
  String get teamDetailHomeConditionBadge;

  /// Distintivo de condición de visitante para el equipo
  ///
  /// In es, this message translates to:
  /// **'Visitante'**
  String get teamDetailAwayConditionBadge;

  /// Título informativo para la pestaña de partidos en preparación
  ///
  /// In es, this message translates to:
  /// **'Calendario del Equipo'**
  String get teamDetailMatchesTabPlaceholderTitle;

  /// Mensaje informativo para la pestaña de partidos en preparación
  ///
  /// In es, this message translates to:
  /// **'El historial completo y calendario de próximos partidos del equipo estará disponible en esta sección.'**
  String get teamDetailMatchesTabPlaceholderMessage;

  /// Título informativo para la pestaña de plantilla en preparación
  ///
  /// In es, this message translates to:
  /// **'Plantilla Oficial'**
  String get teamDetailSquadTabPlaceholderTitle;

  /// Mensaje informativo para la pestaña de plantilla en preparación
  ///
  /// In es, this message translates to:
  /// **'La nómina completa de jugadores con sus dorsales y posiciones tácticas estará disponible en esta sección.'**
  String get teamDetailSquadTabPlaceholderMessage;

  /// Título de la sección de próximos encuentros en la pestaña de partidos del equipo
  ///
  /// In es, this message translates to:
  /// **'Próximos Partidos'**
  String get teamMatchesUpcomingSectionTitle;

  /// Título de la sección de historial de resultados finalizados en la pestaña de partidos del equipo
  ///
  /// In es, this message translates to:
  /// **'Resultados Anteriores'**
  String get teamMatchesCompletedSectionTitle;

  /// Título del estado vacío cuando el equipo no registra partidos próximos ni finalizados
  ///
  /// In es, this message translates to:
  /// **'Sin partidos en el calendario'**
  String get teamMatchesEmptyGlobalTitle;

  /// Mensaje descriptivo del estado vacío global de partidos del equipo
  ///
  /// In es, this message translates to:
  /// **'Este equipo aún no tiene encuentros programados ni resultados registrados en la competición.'**
  String get teamMatchesEmptyGlobalMessage;

  /// Mensaje cuando no hay partidos próximos agendados para el equipo
  ///
  /// In es, this message translates to:
  /// **'Sin próximos partidos agendados'**
  String get teamMatchesUpcomingEmpty;

  /// Mensaje cuando no hay partidos finalizados previos para el equipo
  ///
  /// In es, this message translates to:
  /// **'Sin partidos finalizados registrados'**
  String get teamMatchesCompletedEmpty;

  /// Etiqueta para el badge semántico de partido ganado por el equipo
  ///
  /// In es, this message translates to:
  /// **'Victoria'**
  String get teamMatchOutcomeWin;

  /// Etiqueta para el badge semántico de partido empatado
  ///
  /// In es, this message translates to:
  /// **'Empate'**
  String get teamMatchOutcomeDraw;

  /// Etiqueta para el badge semántico de partido perdido por el equipo
  ///
  /// In es, this message translates to:
  /// **'Derrota'**
  String get teamMatchOutcomeLoss;

  /// Etiqueta de árbitro en el modal de detalle del partido
  ///
  /// In es, this message translates to:
  /// **'Árbitro designado'**
  String get teamMatchDetailModalRefereeLabel;

  /// Texto cuando el árbitro no ha sido asignado al partido
  ///
  /// In es, this message translates to:
  /// **'Árbitro sin asignar'**
  String get teamMatchDetailModalUnassignedReferee;

  /// Texto cuando la cancha no ha sido asignada al partido
  ///
  /// In es, this message translates to:
  /// **'Cancha por asignar'**
  String get teamMatchDetailModalUnassignedVenue;

  /// Texto cuando la fecha y hora del partido están pendientes de programación
  ///
  /// In es, this message translates to:
  /// **'Horario pendiente'**
  String get teamMatchDetailModalPendingSchedule;

  /// Título de la sección de porteros en la pestaña de plantilla
  ///
  /// In es, this message translates to:
  /// **'Porteros'**
  String get teamSquadGoalkeepersSectionTitle;

  /// Título de la sección de defensas en la pestaña de plantilla
  ///
  /// In es, this message translates to:
  /// **'Defensas'**
  String get teamSquadDefendersSectionTitle;

  /// Título de la sección de centrocampistas en la pestaña de plantilla
  ///
  /// In es, this message translates to:
  /// **'Centrocampistas'**
  String get teamSquadMidfieldersSectionTitle;

  /// Título de la sección de delanteros en la pestaña de plantilla
  ///
  /// In es, this message translates to:
  /// **'Delanteros'**
  String get teamSquadForwardsSectionTitle;

  /// Etiqueta para posición táctica de portero
  ///
  /// In es, this message translates to:
  /// **'Portero'**
  String get teamSquadPositionGoalkeeper;

  /// Etiqueta para posición táctica de defensa
  ///
  /// In es, this message translates to:
  /// **'Defensa'**
  String get teamSquadPositionDefender;

  /// Etiqueta para posición táctica de centrocampista
  ///
  /// In es, this message translates to:
  /// **'Centrocampista'**
  String get teamSquadPositionMidfielder;

  /// Etiqueta para posición táctica de delantero
  ///
  /// In es, this message translates to:
  /// **'Delantero'**
  String get teamSquadPositionForward;

  /// Etiqueta semántica para jugador habilitado
  ///
  /// In es, this message translates to:
  /// **'Habilitado'**
  String get teamSquadPlayerStatusEligible;

  /// Etiqueta semántica para jugador suspendido o sancionado
  ///
  /// In es, this message translates to:
  /// **'Suspendido'**
  String get teamSquadPlayerStatusSuspended;

  /// Título del estado vacío cuando el equipo no tiene jugadores inscritos
  ///
  /// In es, this message translates to:
  /// **'Plantilla sin jugadores inscritos'**
  String get teamSquadEmptyGlobalTitle;

  /// Mensaje descriptivo del estado vacío de plantilla sin jugadores
  ///
  /// In es, this message translates to:
  /// **'Este equipo aún no registra jugadores inscritos en su nómina oficial.'**
  String get teamSquadEmptyGlobalMessage;

  /// Mensaje contextual cuando no hay jugadores en una posición táctica específica
  ///
  /// In es, this message translates to:
  /// **'Sin jugadores registrados en esta posición'**
  String get teamSquadEmptyPositionMessage;

  /// Botón de acción rápida en el panel del organizador para publicar comunicados
  ///
  /// In es, this message translates to:
  /// **'Publicar Noticia'**
  String get organizerActionPublishNews;

  /// Mensaje informativo cuando no existen torneos editables para publicar noticias
  ///
  /// In es, this message translates to:
  /// **'No hay competiciones activas disponibles para publicar comunicados'**
  String get organizerNoEditableTournamentsForNews;

  /// Etiqueta para el selector desplegable de torneo en el diálogo de noticias
  ///
  /// In es, this message translates to:
  /// **'Competición'**
  String get newsTournamentField;

  /// Tooltip del botón de tres puntos en el AppBar de la sección de noticias
  ///
  /// In es, this message translates to:
  /// **'Filtrar noticias'**
  String get newsFilterMenuTooltip;

  /// Título de la hoja modal inferior para configuración de filtros de noticias
  ///
  /// In es, this message translates to:
  /// **'Filtrar Noticias'**
  String get newsFilterSheetTitle;

  /// Título de la sección de torneos en la hoja modal de filtros
  ///
  /// In es, this message translates to:
  /// **'Competición'**
  String get newsFilterTournamentSectionTitle;

  /// Título de la sección de categorías en la hoja modal de filtros
  ///
  /// In es, this message translates to:
  /// **'Categoría de Comunicado'**
  String get newsFilterCategorySectionTitle;

  /// Botón para restablecer los filtros de noticias a su estado predeterminado
  ///
  /// In es, this message translates to:
  /// **'Restablecer'**
  String get newsFilterResetButton;

  /// Etiqueta semántica y tooltip para limpiar el chip de filtro activo
  ///
  /// In es, this message translates to:
  /// **'Quitar filtro de categoría'**
  String get newsActiveFilterClearSemantics;

  /// Mensaje de estado vacío cuando el filtro de categoría no arroja noticias
  ///
  /// In es, this message translates to:
  /// **'No hay comunicados publicados en esta categoría para el torneo seleccionado.'**
  String get newsFeedEmptyCategoryFilter;

  /// Tooltip para el botón flotante de acciones en el detalle de competición
  ///
  /// In es, this message translates to:
  /// **'Acciones de competición'**
  String get competitionFabMenuTooltip;

  /// Etiqueta del botón flotante para generar fixture de la competición
  ///
  /// In es, this message translates to:
  /// **'Generar Fixture'**
  String get competitionFabGenerateFixtureLabel;

  /// Título de la hoja modal para seleccionar torneo a generar fixture
  ///
  /// In es, this message translates to:
  /// **'Generar Fixture'**
  String get selectTournamentForFixtureTitle;

  /// Subtítulo explicativo en el selector de torneo para fixture
  ///
  /// In es, this message translates to:
  /// **'Selecciona la competición activa para sortear sus jornadas y partidos.'**
  String get selectTournamentForFixtureSubtitle;

  /// Cantidad de equipos elegibles en el torneo para generación de fixture
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 equipo habilitado} other{{count} equipos habilitados}}'**
  String selectTournamentEligibleTeamsCount(int count);

  /// Aviso cuando no hay torneos en estado editable para generar fixture
  ///
  /// In es, this message translates to:
  /// **'No hay competiciones activas disponibles para generar fixture'**
  String get organizerNoEditableTournamentsForFixture;

  /// Etiqueta en el pie de la tarjeta de partido en la jornada cuando el partido no tiene fecha ni sede asignada
  ///
  /// In es, this message translates to:
  /// **'Por programar'**
  String get fixtureMatchPendingLogistics;

  /// Mensaje de confirmación al guardar la programación de un partido
  ///
  /// In es, this message translates to:
  /// **'Programación del partido guardada exitosamente.'**
  String get matchdayScheduleSavedSuccess;

  /// Pestaña de equipos inscritos en el detalle de competición
  ///
  /// In es, this message translates to:
  /// **'Equipos'**
  String get competitionDetailTabTeams;

  /// Etiqueta del botón flotante para agregar equipo a la competición
  ///
  /// In es, this message translates to:
  /// **'Agregar Equipo'**
  String get competitionFabAddTeamLabel;

  /// Título del estado vacío cuando no hay equipos inscritos en la competición
  ///
  /// In es, this message translates to:
  /// **'Sin equipos inscritos'**
  String get competitionTeamsEmptyTitle;

  /// Descripción del estado vacío en la pestaña de equipos de la competición
  ///
  /// In es, this message translates to:
  /// **'Aún no hay clubes registrados en esta competición. Usa el botón de acciones para inscribir equipos.'**
  String get competitionTeamsEmptyDescription;

  /// Encabezado con conteo de equipos inscritos en la competición
  ///
  /// In es, this message translates to:
  /// **'Equipos Inscritos ({count})'**
  String competitionTeamsHeaderCount(int count);

  /// Cantidad de jugadores inscritos en el equipo
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 jugador} other{{count} jugadores}}'**
  String competitionTeamPlayersCount(int count);

  /// Tooltip del botón para trasladar un equipo de grupo
  ///
  /// In es, this message translates to:
  /// **'Trasladar de grupo'**
  String get competitionTeamMoveGroupTooltip;

  /// Tooltip del botón para quitar un equipo de la competición
  ///
  /// In es, this message translates to:
  /// **'Quitar del campeonato'**
  String get competitionTeamRemoveTooltip;

  /// Título del diálogo para trasladar un equipo de grupo
  ///
  /// In es, this message translates to:
  /// **'Trasladar de Grupo'**
  String get competitionMoveGroupDialogTitle;

  /// Mensaje de confirmación al trasladar un equipo de grupo
  ///
  /// In es, this message translates to:
  /// **'{teamName} trasladado a {groupName}'**
  String competitionMoveGroupSuccess(String teamName, String groupName);

  /// Título del diálogo de confirmación para retirar un equipo
  ///
  /// In es, this message translates to:
  /// **'Quitar Equipo del Campeonato'**
  String get competitionRemoveTeamConfirmTitle;

  /// Mensaje de advertencia para retirar un equipo del torneo
  ///
  /// In es, this message translates to:
  /// **'¿Estás seguro de que deseas retirar a {teamName} de esta competición?'**
  String competitionRemoveTeamConfirmMessage(String teamName);

  /// Texto del botón de confirmación destructiva para quitar equipo
  ///
  /// In es, this message translates to:
  /// **'Quitar Equipo'**
  String get competitionRemoveTeamConfirmAction;

  /// Mensaje de éxito al quitar un equipo del campeonato
  ///
  /// In es, this message translates to:
  /// **'Equipo retirado del campeonato'**
  String get competitionRemoveTeamSuccess;

  /// Mensaje de error cuando se intenta retirar un equipo con partidos disputados o en juego
  ///
  /// In es, this message translates to:
  /// **'No se puede retirar un equipo que ya tiene partidos en curso o finalizados'**
  String get competitionRemoveTeamHasPlayedMatchesError;

  /// Título del diálogo para inscribir equipo en la competición
  ///
  /// In es, this message translates to:
  /// **'Inscribir Equipo en Competición'**
  String get competitionEnrollTeamDialogTitle;

  /// Etiqueta del selector de clubes existentes para pre-cargar datos
  ///
  /// In es, this message translates to:
  /// **'Copiar de club existente (opcional)'**
  String get competitionEnrollTeamExistingClubLabel;

  /// Opción en el desplegable para crear un equipo nuevo desde cero
  ///
  /// In es, this message translates to:
  /// **'Crear nuevo equipo'**
  String get competitionEnrollTeamNewClubOption;

  /// Etiqueta del selector de grupo en el diálogo de inscripción
  ///
  /// In es, this message translates to:
  /// **'Grupo asignado'**
  String get competitionEnrollTeamGroupLabel;

  /// Texto del botón de acción para confirmar la inscripción del equipo
  ///
  /// In es, this message translates to:
  /// **'Inscribir Equipo'**
  String get competitionEnrollTeamSubmitAction;

  /// Mensaje de confirmación al inscribir un equipo en la competición
  ///
  /// In es, this message translates to:
  /// **'Equipo {teamName} inscrito en la competición'**
  String competitionEnrollTeamSuccess(String teamName);

  /// Título de la sección de competiciones del organizador
  ///
  /// In es, this message translates to:
  /// **'Mis Competiciones'**
  String get organizerCompetitionsSectionTitle;

  /// Botón para crear una nueva competición en el panel del organizador
  ///
  /// In es, this message translates to:
  /// **'Nueva Competición'**
  String get organizerCompetitionsCreateAction;

  /// Título del estado vacío cuando el organizador no tiene torneos
  ///
  /// In es, this message translates to:
  /// **'No tienes competiciones activas'**
  String get organizerCompetitionsEmptyTitle;

  /// Subtítulo descriptivo del estado vacío de competiciones
  ///
  /// In es, this message translates to:
  /// **'Crea y administra tus torneos, categorías y reglamentos desde este panel.'**
  String get organizerCompetitionsEmptySubtitle;

  /// Botón de acción en el estado vacío para crear el primer torneo
  ///
  /// In es, this message translates to:
  /// **'Crear mi primera competición'**
  String get organizerCompetitionsEmptyCreateButton;

  /// Cantidad de equipos inscritos en el torneo
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 equipo inscrito} other{{count} equipos inscritos}}'**
  String organizerCompetitionsTeamsCount(num count);

  /// Opción de menú contextual para editar metadatos del torneo
  ///
  /// In es, this message translates to:
  /// **'Editar metadatos'**
  String get organizerCompetitionsMenuEdit;

  /// Opción de menú contextual para cambiar estado de ciclo de vida
  ///
  /// In es, this message translates to:
  /// **'Cambiar estado de competición'**
  String get organizerCompetitionsMenuStatus;

  /// Opción de menú contextual para eliminar competición
  ///
  /// In es, this message translates to:
  /// **'Eliminar competición'**
  String get organizerCompetitionsMenuDelete;

  /// Título del modal de edición de metadatos de la competición
  ///
  /// In es, this message translates to:
  /// **'Editar Competición'**
  String get competitionEditDialogTitle;

  /// Etiqueta para campo de nombre en edición
  ///
  /// In es, this message translates to:
  /// **'Nombre del torneo'**
  String get competitionEditNameLabel;

  /// Etiqueta para campo de categoría en edición
  ///
  /// In es, this message translates to:
  /// **'Categoría'**
  String get competitionEditCategoryLabel;

  /// Etiqueta para campo de formato en edición
  ///
  /// In es, this message translates to:
  /// **'Formato de competición'**
  String get competitionEditFormatLabel;

  /// Botón para guardar cambios de edición de competición
  ///
  /// In es, this message translates to:
  /// **'Guardar cambios'**
  String get competitionEditSaveButton;

  /// Mensaje de éxito al guardar edición de torneo
  ///
  /// In es, this message translates to:
  /// **'Competición actualizada exitosamente.'**
  String get competitionEditSavedSuccess;

  /// Título del modal para cambiar estado del ciclo de vida
  ///
  /// In es, this message translates to:
  /// **'Cambiar Estado del Torneo'**
  String get competitionLifecycleDialogTitle;

  /// Texto que muestra el estado actual del torneo
  ///
  /// In es, this message translates to:
  /// **'Estado actual: {status}'**
  String competitionLifecycleCurrentStatus(String status);

  /// Etiqueta para seleccionar el nuevo estado del torneo
  ///
  /// In es, this message translates to:
  /// **'Nuevo estado:'**
  String get competitionLifecycleTargetStatus;

  /// Mensaje de validación cuando faltan equipos para iniciar torneo
  ///
  /// In es, this message translates to:
  /// **'No se puede iniciar el torneo: requiere al menos 2 equipos inscritos (actuales: {count}).'**
  String competitionLifecycleValidationMinTeams(int count);

  /// Mensaje de validación cuando falta generar fixture para iniciar torneo
  ///
  /// In es, this message translates to:
  /// **'No se puede iniciar el torneo: debes generar el fixture de partidos previamente.'**
  String get competitionLifecycleValidationNoFixture;

  /// Botón de acción rápida para ir a inscribir equipos
  ///
  /// In es, this message translates to:
  /// **'Inscribir Equipos'**
  String get competitionLifecycleActionEnrollTeams;

  /// Botón de acción rápida para ir a generar fixture
  ///
  /// In es, this message translates to:
  /// **'Generar Fixture'**
  String get competitionLifecycleActionGenerateFixture;

  /// Botón para confirmar transición de estado
  ///
  /// In es, this message translates to:
  /// **'Confirmar cambio de estado'**
  String get competitionLifecycleConfirmButton;

  /// Mensaje de confirmación al actualizar estado del torneo
  ///
  /// In es, this message translates to:
  /// **'Estado del torneo actualizado a {status}.'**
  String competitionLifecycleSuccess(String status);

  /// Título del diálogo para eliminar competición
  ///
  /// In es, this message translates to:
  /// **'Eliminar Competición'**
  String get competitionDeleteDialogTitle;

  /// Mensaje de confirmación destructiva para eliminar torneo
  ///
  /// In es, this message translates to:
  /// **'¿Estás seguro de que deseas eliminar permanentemente la competición \"{name}\"? Esta acción no se puede deshacer.'**
  String competitionDeleteDialogMessage(String name);

  /// Mensaje de bloqueo de eliminación si el torneo ya inició o finalizó
  ///
  /// In es, this message translates to:
  /// **'No se puede eliminar una competición en curso o finalizada.'**
  String get competitionDeleteBlockedInProgress;

  /// Mensaje de bloqueo de eliminación si el torneo tiene partidos disputados
  ///
  /// In es, this message translates to:
  /// **'No se puede eliminar la competición porque ya cuenta con partidos disputados o en curso.'**
  String get competitionDeleteBlockedHasMatches;

  /// Botón de confirmación destructiva para eliminar torneo
  ///
  /// In es, this message translates to:
  /// **'Eliminar definitivamente'**
  String get competitionDeleteConfirmButton;

  /// Mensaje de éxito tras eliminar una competición
  ///
  /// In es, this message translates to:
  /// **'La competición ha sido eliminada.'**
  String get competitionDeleteSuccess;

  /// Botón de cancelar en diálogo de eliminación
  ///
  /// In es, this message translates to:
  /// **'Cancelar'**
  String get competitionDeleteCancelButton;

  /// Título cuando el entrenador no tiene ningún equipo registrado
  ///
  /// In es, this message translates to:
  /// **'Sin Equipo Registrado'**
  String get coachNoTeamTitle;

  /// Descripción cuando el entrenador no tiene ningún equipo registrado
  ///
  /// In es, this message translates to:
  /// **'Aún no tienes ningún equipo registrado bajo tu gestión como entrenador.'**
  String get coachNoTeamDescription;

  /// Botón de acción para registrar equipo desde el estado vacío del panel del entrenador
  ///
  /// In es, this message translates to:
  /// **'Registrar mi Equipo'**
  String get coachActionRegisterTeamEmpty;

  /// Título del diálogo para registrar nuevo equipo
  ///
  /// In es, this message translates to:
  /// **'Registrar Nuevo Equipo'**
  String get createTeamDialogTitle;

  /// Etiqueta para el campo de nombre del equipo
  ///
  /// In es, this message translates to:
  /// **'Nombre del Equipo'**
  String get createTeamNameLabel;

  /// Etiqueta para la sigla del equipo
  ///
  /// In es, this message translates to:
  /// **'Sigla (2-4 letras)'**
  String get createTeamShortCodeLabel;

  /// Etiqueta del selector de competición en el registro de equipo
  ///
  /// In es, this message translates to:
  /// **'Competición (Opcional)'**
  String get createTeamTournamentLabel;

  /// Opción en el selector cuando el equipo se crea sin torneo asignado
  ///
  /// In es, this message translates to:
  /// **'Sin torneo asignado'**
  String get createTeamNoTournamentOption;

  /// Botón de confirmación para crear equipo
  ///
  /// In es, this message translates to:
  /// **'Registrar Equipo'**
  String get createTeamSubmitAction;

  /// Mensaje de éxito tras registrar equipo
  ///
  /// In es, this message translates to:
  /// **'Equipo \"{name}\" registrado exitosamente'**
  String createTeamSuccessMessage(String name);

  /// Mensaje de error cuando un rol no autorizado intenta crear equipos o registrar jugadores
  ///
  /// In es, this message translates to:
  /// **'Solo los entrenadores pueden registrar equipos o futbolistas'**
  String get unauthorizedTeamCreationMessage;

  /// Estado cuando la plantilla no ha sido verificada o está incompleta
  ///
  /// In es, this message translates to:
  /// **'Pendiente de verificación'**
  String get teamEligibilityPendingVerification;

  /// Título del diálogo cuando la plantilla tiene menos de 11 jugadores
  ///
  /// In es, this message translates to:
  /// **'Cuota reglamentaria insuficiente'**
  String get teamEligibilityQuotaInsufficientTitle;

  /// Mensaje exacto de advertencia reglamentaria por plantilla menor a 11
  ///
  /// In es, this message translates to:
  /// **'El equipo no cumple la cuota reglamentaria mínima (mínimo 11 jugadores requeridos, actual: {actual})'**
  String teamEligibilityQuotaInsufficientMessage(int actual);

  /// Botón de acción para que el organizador habilite al equipo
  ///
  /// In es, this message translates to:
  /// **'Habilitar Equipo'**
  String get teamEligibilityActionApprove;

  /// Botón de acción para que el organizador inhabilite al equipo
  ///
  /// In es, this message translates to:
  /// **'Inhabilitar'**
  String get teamEligibilityActionRevoke;

  /// Botón de confirmación del diálogo de advertencia de cuota reglamentaria
  ///
  /// In es, this message translates to:
  /// **'Entendido'**
  String get teamEligibilityActionUnderstood;

  /// Etiqueta cuando el equipo tiene menos de 11 jugadores
  ///
  /// In es, this message translates to:
  /// **'{count}/11 jugadores - Incompleto'**
  String competitionTeamPlayersIncomplete(int count);

  /// Etiqueta cuando el equipo tiene 11 o más jugadores
  ///
  /// In es, this message translates to:
  /// **'{count} jugadores - Nómina válida'**
  String competitionTeamPlayersComplete(int count);

  /// Mensaje de error cuando se intenta generar fixture con menos de 2 equipos habilitados
  ///
  /// In es, this message translates to:
  /// **'Se requieren al menos dos equipos habilitados con nómina completa'**
  String get competitionFixtureMinEligibleTeamsError;

  /// Mensaje tras inhabilitar un equipo
  ///
  /// In es, this message translates to:
  /// **'El equipo ha sido inhabilitado para el campeonato'**
  String get teamEligibilityRevokedSuccess;

  /// Título de la sección de sedes en el formulario de torneo
  ///
  /// In es, this message translates to:
  /// **'Sedes Oficiales'**
  String get venuesSectionTitle;

  /// Subtítulo de la sección de sedes en el formulario de torneo
  ///
  /// In es, this message translates to:
  /// **'Selecciona las sedes donde se disputarán los partidos'**
  String get venuesSectionSubtitle;

  /// Mensaje cuando no hay sedes registradas en el sistema
  ///
  /// In es, this message translates to:
  /// **'No hay sedes registradas todavía'**
  String get noVenuesRegistered;

  /// Botón para abrir el formulario modal de creación de sede
  ///
  /// In es, this message translates to:
  /// **'Crear Nueva Sede'**
  String get createNewVenue;

  /// Etiqueta para el campo de nombre de la sede
  ///
  /// In es, this message translates to:
  /// **'Nombre de la Sede'**
  String get venueNameLabel;

  /// Etiqueta para el campo de dirección de la sede
  ///
  /// In es, this message translates to:
  /// **'Dirección'**
  String get venueAddressLabel;

  /// Etiqueta para el campo de número de canchas
  ///
  /// In es, this message translates to:
  /// **'Número de Canchas'**
  String get venuePitchesCountLabel;

  /// Error de validación cuando el nombre de la sede tiene menos de 3 caracteres
  ///
  /// In es, this message translates to:
  /// **'El nombre debe tener al menos 3 caracteres'**
  String get venueNameTooShort;

  /// Error de validación cuando la dirección tiene menos de 5 caracteres
  ///
  /// In es, this message translates to:
  /// **'La dirección debe tener al menos 5 caracteres'**
  String get venueAddressTooShort;

  /// Error de validación cuando el número de canchas es menor a 1
  ///
  /// In es, this message translates to:
  /// **'Debe tener al menos 1 cancha'**
  String get venuePitchesInvalid;

  /// Error de validación cuando ya existe una sede con el mismo nombre
  ///
  /// In es, this message translates to:
  /// **'Ya existe una sede con este nombre. Selecciónala de la lista o elige otro nombre.'**
  String get venueNameDuplicate;

  /// Etiqueta de la acción del menú flotante para agregar equipos a la competición
  ///
  /// In es, this message translates to:
  /// **'Agregar Equipos'**
  String get competitionFabAddTeamsLabel;

  /// Título del modal para buscar e inscribir equipos en la competición
  ///
  /// In es, this message translates to:
  /// **'Agregar Equipos'**
  String get addTeamsModalTitle;

  /// Subtítulo descriptivo del modal de inscripción de equipos
  ///
  /// In es, this message translates to:
  /// **'Busca clubes registrados e inscríbelos en {tournamentName}'**
  String addTeamsModalSubtitle(String tournamentName);

  /// Placeholder del campo de búsqueda en el modal de equipos
  ///
  /// In es, this message translates to:
  /// **'Buscar equipo por nombre o sigla...'**
  String get addTeamsSearchHint;

  /// Etiqueta del botón para inscribir un equipo disponible desde el modal
  ///
  /// In es, this message translates to:
  /// **'Agregar'**
  String get addTeamsActionAdd;

  /// Distintivo y etiqueta de botón deshabilitado cuando el equipo ya está inscrito
  ///
  /// In es, this message translates to:
  /// **'Inscrito'**
  String get addTeamsStatusEnrolledBadge;

  /// Título del estado vacío cuando no hay equipos registrados en el catálogo global
  ///
  /// In es, this message translates to:
  /// **'Sin equipos en la plataforma'**
  String get addTeamsEmptyCatalogTitle;

  /// Mensaje del estado vacío cuando el catálogo global de equipos está vacío
  ///
  /// In es, this message translates to:
  /// **'No hay equipos registrados en la plataforma. Los entrenadores deben registrar sus clubes antes de poder inscribirlos en el campeonato.'**
  String get addTeamsEmptyCatalogMessage;

  /// Etiqueta por defecto cuando el equipo no tiene categoría asignada en el catálogo
  ///
  /// In es, this message translates to:
  /// **'Categoría libre'**
  String get addTeamsDefaultCategoryLabel;

  /// Metadato con el nombre del entrenador del equipo
  ///
  /// In es, this message translates to:
  /// **'DT: {coachName}'**
  String addTeamsCoachMeta(String coachName);

  /// Mensaje del estado vacío cuando la búsqueda no arroja coincidencias
  ///
  /// In es, this message translates to:
  /// **'No se encontraron equipos con \"{query}\"'**
  String addTeamsEmptySearchMessage(String query);

  /// Botón para restablecer la consulta de búsqueda en el modal de equipos
  ///
  /// In es, this message translates to:
  /// **'Limpiar búsqueda'**
  String get addTeamsClearSearchAction;

  /// Confirmación visual tras inscribir un equipo desde el modal
  ///
  /// In es, this message translates to:
  /// **'{teamName} inscrito (Pendiente de verificación)'**
  String addTeamsEnrollSuccess(String teamName);

  /// Aviso cuando un equipo se inscribe pero se omiten jugadores con documento repetido en otro club
  ///
  /// In es, this message translates to:
  /// **'{teamName} inscrito. Se {skippedCount, plural, =1{omitió 1 jugador ya inscrito en otro club del torneo} other{omitieron {skippedCount} jugadores ya inscritos en otros clubes del torneo}}.'**
  String addTeamsEnrollSuccessSkippedPlayers(String teamName, int skippedCount);

  /// Mensaje de error al intentar inscribir un equipo duplicado
  ///
  /// In es, this message translates to:
  /// **'Este equipo ya se encuentra inscrito en la competición'**
  String get addTeamsDuplicateError;

  /// Subtítulo con el conteo de jugadores de la plantilla base en el catálogo
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =0{Sin plantilla registrada} =1{1 jugador en plantilla} other{{count} jugadores en plantilla}}'**
  String addTeamsPlayersCountMeta(int count);

  /// Tooltip accesible del AppBar cuando no hay cambios pendientes
  ///
  /// In es, this message translates to:
  /// **'Datos sincronizados en la nube'**
  String get syncStatusSyncedTooltip;

  /// Tooltip accesible del AppBar cuando existen operaciones pendientes en cola
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 cambio pendiente por sincronizar} other{{count} cambios pendientes por sincronizar}}'**
  String syncStatusPendingTooltip(int count);

  /// Tooltip accesible del AppBar mientras la sincronización está en progreso
  ///
  /// In es, this message translates to:
  /// **'Sincronizando cambios con la nube'**
  String get syncStatusSyncingTooltip;

  /// Tooltip accesible del AppBar cuando el dispositivo está sin red o hay errores
  ///
  /// In es, this message translates to:
  /// **'Sin conexión o error de sincronización'**
  String get syncStatusOfflineOrErrorTooltip;

  /// Título del panel resumen de sincronización
  ///
  /// In es, this message translates to:
  /// **'Estado de sincronización'**
  String get syncSheetTitle;

  /// Indicador de conectividad activa
  ///
  /// In es, this message translates to:
  /// **'En línea'**
  String get syncConnectionOnline;

  /// Indicador de falta de conectividad
  ///
  /// In es, this message translates to:
  /// **'Sin conexión'**
  String get syncConnectionOffline;

  /// Encabezado de estado sincronizado en el panel
  ///
  /// In es, this message translates to:
  /// **'Todos los datos están al día'**
  String get syncStateSyncedTitle;

  /// Encabezado de estado pendiente en el panel
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 operación pendiente} other{{count} operaciones pendientes}}'**
  String syncStatePendingTitle(int count);

  /// Encabezado mientras el envío a la nube está en curso
  ///
  /// In es, this message translates to:
  /// **'Sincronizando con KickPulse...'**
  String get syncStateSyncingTitle;

  /// Encabezado cuando existen ítems rechazados por el servidor
  ///
  /// In es, this message translates to:
  /// **'{errorCount, plural, =1{1 operación requiere revisión} other{{errorCount} operaciones requieren revisión}}'**
  String syncStateErrorTitle(int errorCount);

  /// Texto cuando no hay fecha previa de sincronización
  ///
  /// In es, this message translates to:
  /// **'Última sincronización: aún sin registrar'**
  String get syncLastSyncedNever;

  /// Texto con la fecha/hora formateada de la última sincronización exitosa
  ///
  /// In es, this message translates to:
  /// **'Última sincronización: {formattedDate}'**
  String syncLastSyncedAt(String formattedDate);

  /// Mensaje vacío cuando la cola de sincronización está limpia
  ///
  /// In es, this message translates to:
  /// **'No hay cambios locales pendientes de respaldo en la nube.'**
  String get syncQueueEmptyMessage;

  /// Estado de tarea en espera FIFO
  ///
  /// In es, this message translates to:
  /// **'En cola'**
  String get syncItemStatusQueued;

  /// Estado de tarea tras falla transitoria de red
  ///
  /// In es, this message translates to:
  /// **'Reintentando'**
  String get syncItemStatusRetrying;

  /// Estado de tarea con rechazo no transitorio
  ///
  /// In es, this message translates to:
  /// **'Error'**
  String get syncItemStatusError;

  /// Etiqueta de entidad competición
  ///
  /// In es, this message translates to:
  /// **'Competición'**
  String get syncEntityTournament;

  /// Etiqueta de entidad sede
  ///
  /// In es, this message translates to:
  /// **'Sede deportiva'**
  String get syncEntityVenue;

  /// Etiqueta de entidad equipo
  ///
  /// In es, this message translates to:
  /// **'Equipo'**
  String get syncEntityTeam;

  /// Etiqueta de entidad partido
  ///
  /// In es, this message translates to:
  /// **'Partido'**
  String get syncEntityMatch;

  /// Etiqueta de entidad convocatoria o seguimiento
  ///
  /// In es, this message translates to:
  /// **'Alineación'**
  String get syncEntityLineup;

  /// Etiqueta de entidad acta arbitral
  ///
  /// In es, this message translates to:
  /// **'Acta arbitral'**
  String get syncEntityMatchReport;

  /// Etiqueta de entidad alerta
  ///
  /// In es, this message translates to:
  /// **'Alerta en vivo'**
  String get syncEntityMatchAlert;

  /// Etiqueta de entidad noticia
  ///
  /// In es, this message translates to:
  /// **'Noticia'**
  String get syncEntityNews;

  /// Etiqueta de entidad cuadro de honor
  ///
  /// In es, this message translates to:
  /// **'Cuadro de honor'**
  String get syncEntityHonorRoll;

  /// Etiqueta de entidad equipo favorito
  ///
  /// In es, this message translates to:
  /// **'Favorito'**
  String get syncEntityFavorite;

  /// Botón principal para disparar sincronización manual
  ///
  /// In es, this message translates to:
  /// **'Sincronizar ahora'**
  String get syncActionNow;

  /// Botón por ítem para reintentar envío fallido
  ///
  /// In es, this message translates to:
  /// **'Reintentar'**
  String get syncActionRetry;

  /// Botón por ítem para descartar operación fallida de la cola
  ///
  /// In es, this message translates to:
  /// **'Descartar'**
  String get syncActionDiscard;

  /// Mensaje localizado por rechazo RLS o 401/403
  ///
  /// In es, this message translates to:
  /// **'No tienes permisos para modificar este recurso en el servidor.'**
  String get syncErrorPermissionDenied;

  /// Mensaje localizado por violación de unicidad o llave foránea
  ///
  /// In es, this message translates to:
  /// **'Conflicto o duplicado con los datos actuales del torneo.'**
  String get syncErrorConstraintViolation;

  /// Mensaje localizado por error 400 o 422
  ///
  /// In es, this message translates to:
  /// **'El servidor rechazó los datos por validación de reglas.'**
  String get syncErrorValidationFailed;

  /// Mensaje localizado por registro no encontrado
  ///
  /// In es, this message translates to:
  /// **'El registro asociado ya no existe en la nube.'**
  String get syncErrorNotFound;

  /// Mensaje localizado genérico para rechazo no transitorio
  ///
  /// In es, this message translates to:
  /// **'El servidor rechazó la operación y requiere revisión.'**
  String get syncErrorUnknown;

  /// Título del diálogo al cerrar sesión con tareas pendientes
  ///
  /// In es, this message translates to:
  /// **'Cambios pendientes sin sincronizar'**
  String get syncLogoutGuardTitle;

  /// Mensaje del diálogo de protección de cierre de sesión
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{Tienes 1 cambio guardado localmente que aún no se ha respaldado en la nube.} other{Tienes {count} cambios guardados localmente que aún no se han respaldado en la nube.}} ¿Cómo deseas continuar?'**
  String syncLogoutGuardMessage(int count);

  /// Opción para sincronizar antes de cerrar sesión
  ///
  /// In es, this message translates to:
  /// **'Sincronizar y salir'**
  String get syncLogoutActionSyncAndExit;

  /// Opción para cerrar sesión manteniendo los ítems ligados al usuario
  ///
  /// In es, this message translates to:
  /// **'Salir conservando pendientes'**
  String get syncLogoutActionKeepPending;

  /// Aviso si falla la sincronización previa al cierre de sesión
  ///
  /// In es, this message translates to:
  /// **'No se pudieron sincronizar todos los cambios. Revisa tu conexión o inténtalo desde el panel de estado.'**
  String get syncLogoutSyncFailedNotice;

  /// Permiso RBAC para visualizar el estado de sincronización en el AppBar
  ///
  /// In es, this message translates to:
  /// **'Indicador de sincronización en la nube'**
  String get capViewCloudSyncIndicator;

  /// Aviso informativo al intentar refrescar la lista de jugadores sin conectividad
  ///
  /// In es, this message translates to:
  /// **'Sin conexión a internet. Mostrando nómina local disponible.'**
  String get playersDirectoryOfflineRefreshWarning;

  /// Aviso informativo al intentar refrescar la lista de equipos sin conectividad
  ///
  /// In es, this message translates to:
  /// **'Sin conexión a internet. Mostrando equipos locales disponibles.'**
  String get teamsDirectoryOfflineRefreshWarning;

  /// Etiqueta mostrada cuando un club aún no participa en ningún torneo
  ///
  /// In es, this message translates to:
  /// **'Sin torneo asignado'**
  String get teamsDirectoryNoTournamentAssigned;

  /// Etiqueta mostrada cuando un club participa en más de un torneo
  ///
  /// In es, this message translates to:
  /// **'Múltiples torneos'**
  String get teamsDirectoryMultipleTournaments;

  /// Distintivo ámbar cuando faltan datos obligatorios en el perfil del usuario
  ///
  /// In es, this message translates to:
  /// **'Datos incompletos'**
  String get profileIncompleteBadge;

  /// Distintivo verde cuando los datos obligatorios del perfil están completos
  ///
  /// In es, this message translates to:
  /// **'Perfil completo'**
  String get profileCompleteBadge;

  /// Título del banner de perfil incompleto
  ///
  /// In es, this message translates to:
  /// **'Completa tu ficha personal'**
  String get profileIncompleteBannerTitle;

  /// Subtítulo del banner de perfil incompleto
  ///
  /// In es, this message translates to:
  /// **'Agrega tu información de contacto y datos de rol para mantener tu ficha al día.'**
  String get profileIncompleteBannerSubtitle;

  /// Botón de acción para abrir el formulario de completar perfil
  ///
  /// In es, this message translates to:
  /// **'Completar mi perfil'**
  String get profileCompleteAction;

  /// Título del modal adaptativo de perfil
  ///
  /// In es, this message translates to:
  /// **'Completar mi perfil'**
  String get completeProfileDialogTitle;

  /// Etiqueta del campo de teléfono
  ///
  /// In es, this message translates to:
  /// **'Teléfono de contacto'**
  String get completeProfilePhoneLabel;

  /// Etiqueta del campo de documento de identidad
  ///
  /// In es, this message translates to:
  /// **'Documento de identidad'**
  String get completeProfileDocumentLabel;

  /// Etiqueta del campo de club o escuela para entrenador
  ///
  /// In es, this message translates to:
  /// **'Club o escuela'**
  String get completeProfileClubLabel;

  /// Etiqueta del campo de nivel de licencia para entrenador
  ///
  /// In es, this message translates to:
  /// **'Nivel de licencia'**
  String get completeProfileLicenseLabel;

  /// Etiqueta del campo de entidad organizadora
  ///
  /// In es, this message translates to:
  /// **'Entidad organizadora'**
  String get completeProfileOrganizationLabel;

  /// Etiqueta del campo de ciudad base para organizador
  ///
  /// In es, this message translates to:
  /// **'Ciudad base'**
  String get completeProfileBaseCityLabel;

  /// Etiqueta del campo de ciudad para aficionado
  ///
  /// In es, this message translates to:
  /// **'Ciudad'**
  String get completeProfileCityLabel;

  /// Etiqueta del campo de preferencias para aficionado
  ///
  /// In es, this message translates to:
  /// **'Preferencias (opcional)'**
  String get completeProfilePreferencesLabel;

  /// Botón para guardar el formulario de completar perfil
  ///
  /// In es, this message translates to:
  /// **'Guardar perfil'**
  String get completeProfileSaveAction;

  /// Mensaje de confirmación tras guardar el perfil
  ///
  /// In es, this message translates to:
  /// **'Perfil actualizado y sincronizado en la nube.'**
  String get completeProfileSuccessMessage;

  /// Error cuando se intenta guardar el perfil sin conexión
  ///
  /// In es, this message translates to:
  /// **'Se requiere conexión a internet para guardar tu perfil.'**
  String get completeProfileOfflineError;

  /// Error cuando el documento ingresado pertenece a otra cuenta
  ///
  /// In es, this message translates to:
  /// **'El documento ingresado ya está vinculado a otra cuenta de usuario.'**
  String get completeProfileDocumentConflictError;

  /// Error de validación para campo obligatorio vacío
  ///
  /// In es, this message translates to:
  /// **'Este campo es obligatorio.'**
  String get completeProfileRequiredFieldError;

  /// Error de validación para teléfono inválido
  ///
  /// In es, this message translates to:
  /// **'Ingresa un teléfono válido (mínimo 7 dígitos).'**
  String get completeProfileInvalidPhoneError;

  /// Error de validación para documento inválido
  ///
  /// In es, this message translates to:
  /// **'Ingresa un documento válido (mínimo 5 caracteres).'**
  String get completeProfileInvalidDocumentError;

  /// Indicador cuando el equipo no alcanza los 11 jugadores reglamentarios
  ///
  /// In es, this message translates to:
  /// **'No elegible / Faltan jugadores'**
  String get teamRosterIneligibleIndicator;

  /// Texto del progreso de cuota mínima de jugadores
  ///
  /// In es, this message translates to:
  /// **'{current}/{min} jugadores mínimos'**
  String teamRosterQuotaProgress(int current, int min);

  /// Acción para habilitar un equipo a estado eligible
  ///
  /// In es, this message translates to:
  /// **'Habilitar para Competiciones'**
  String get teamRosterEnableCompetitionAction;

  /// Mensaje tras habilitar el equipo con éxito
  ///
  /// In es, this message translates to:
  /// **'Equipo habilitado oficialmente para competir.'**
  String get teamRosterEnableSuccessMessage;

  /// Encabezado de invitaciones pendientes enviadas por el equipo
  ///
  /// In es, this message translates to:
  /// **'Solicitudes enviadas ({count})'**
  String teamRosterPendingRequestsHeader(int count);

  /// Botón para cancelar una solicitud pendiente enviada a un jugador
  ///
  /// In es, this message translates to:
  /// **'Cancelar invitación'**
  String get teamRosterCancelRequestAction;

  /// Título del modal para buscar e invitar jugadores a un club
  ///
  /// In es, this message translates to:
  /// **'Invitar Jugador a la Plantilla'**
  String get teamInvitePlayerModalTitle;

  /// Placeholder del buscador de jugadores registrados
  ///
  /// In es, this message translates to:
  /// **'Buscar jugador por nombre o documento...'**
  String get teamInviteSearchHint;

  /// Etiqueta para ingresar el número de dorsal
  ///
  /// In es, this message translates to:
  /// **'Dorsal propuesto (1-99)'**
  String get teamInviteShirtNumberLabel;

  /// Etiqueta para seleccionar la posición
  ///
  /// In es, this message translates to:
  /// **'Posición táctica'**
  String get teamInvitePositionLabel;

  /// Botón para enviar la solicitud de incorporación
  ///
  /// In es, this message translates to:
  /// **'Enviar Solicitud'**
  String get teamInviteSendAction;

  /// Mensaje de éxito al enviar solicitud de incorporación
  ///
  /// In es, this message translates to:
  /// **'Solicitud enviada a {playerName}.'**
  String teamInviteSuccessMessage(String playerName);

  /// Error al elegir un dorsal ya asignado
  ///
  /// In es, this message translates to:
  /// **'El dorsal {shirt} ya está ocupado en la plantilla o en una solicitud pendiente.'**
  String teamInviteDuplicateShirtError(int shirt);

  /// Error si el jugador ya está invitado o en plantilla
  ///
  /// In es, this message translates to:
  /// **'Este jugador ya pertenece al equipo o tiene una invitación pendiente.'**
  String get teamInviteDuplicatePlayerError;

  /// Mensaje de búsqueda vacía en catálogo de jugadores
  ///
  /// In es, this message translates to:
  /// **'No se encontraron jugadores registrados con \"{query}\"'**
  String teamInviteEmptySearchMessage(String query);

  /// Opción en el perfil para revisar invitaciones de clubes
  ///
  /// In es, this message translates to:
  /// **'Solicitudes de Equipos'**
  String get profileTeamRequestsTile;

  /// Título de la pantalla de solicitudes recibidas
  ///
  /// In es, this message translates to:
  /// **'Invitaciones de Equipos'**
  String get profileTeamRequestsTitle;

  /// Estado vacío en bandeja de invitaciones de equipos
  ///
  /// In es, this message translates to:
  /// **'No tienes solicitudes de equipos pendientes.'**
  String get profileTeamRequestsEmpty;

  /// Botón para aceptar solicitud de equipo
  ///
  /// In es, this message translates to:
  /// **'Aceptar'**
  String get profileTeamRequestAcceptAction;

  /// Botón para rechazar solicitud de equipo
  ///
  /// In es, this message translates to:
  /// **'Rechazar'**
  String get profileTeamRequestRejectAction;

  /// Confirmación tras aceptar invitación
  ///
  /// In es, this message translates to:
  /// **'Te has unido exitosamente a {teamName}.'**
  String profileTeamRequestAcceptedMessage(String teamName);

  /// Confirmación tras rechazar invitación
  ///
  /// In es, this message translates to:
  /// **'Invitación de {teamName} rechazada.'**
  String profileTeamRequestRejectedMessage(String teamName);

  /// Título de la sección de plantilla agrupada por posición en el panel técnico
  ///
  /// In es, this message translates to:
  /// **'Plantilla por Posición'**
  String get coachRosterSectionTitle;

  /// Encabezado genérico para una línea táctica con conteo de jugadores
  ///
  /// In es, this message translates to:
  /// **'{position} ({count})'**
  String coachRosterPositionHeader(String position, int count);

  /// Encabezado del grupo de porteros con conteo de jugadores
  ///
  /// In es, this message translates to:
  /// **'Porteros ({count})'**
  String coachRosterPositionGoalkeepers(int count);

  /// Encabezado del grupo de defensas con conteo de jugadores
  ///
  /// In es, this message translates to:
  /// **'Defensas ({count})'**
  String coachRosterPositionDefenders(int count);

  /// Encabezado del grupo de mediocampistas con conteo de jugadores
  ///
  /// In es, this message translates to:
  /// **'Mediocampistas ({count})'**
  String coachRosterPositionMidfielders(int count);

  /// Encabezado del grupo de delanteros con conteo de jugadores
  ///
  /// In es, this message translates to:
  /// **'Delanteros ({count})'**
  String coachRosterPositionForwards(int count);

  /// Badge de estado para jugadores disponibles y elegibles
  ///
  /// In es, this message translates to:
  /// **'Elegible'**
  String get coachRosterPlayerEligible;

  /// Badge de estado para jugadores no disponibles o inactivos
  ///
  /// In es, this message translates to:
  /// **'Inactivo / Sancionado'**
  String get coachRosterPlayerInactive;

  /// Estado vacío sutil mostrado cuando una línea táctica no tiene jugadores registrados
  ///
  /// In es, this message translates to:
  /// **'Sin jugadores en esta posición'**
  String get coachRosterEmptyPosition;

  /// Alerta preventiva mostrada cuando el equipo no cuenta con ningún arquero
  ///
  /// In es, this message translates to:
  /// **'Alerta táctica: El equipo no tiene porteros registrados.'**
  String get coachRosterNoGoalkeeperAlert;

  /// Título de la tarjeta de datos personales en el perfil
  ///
  /// In es, this message translates to:
  /// **'Datos Personales'**
  String get profilePersonalDataTile;

  /// Subtítulo de la tarjeta de datos personales en el perfil
  ///
  /// In es, this message translates to:
  /// **'Información personal, ubicación y posiciones'**
  String get profilePersonalDataSubtitle;

  /// Título de la pantalla de datos personales del jugador
  ///
  /// In es, this message translates to:
  /// **'Datos Personales'**
  String get playerPersonalDataTitle;

  /// Subtítulo de la pantalla de datos personales del jugador
  ///
  /// In es, this message translates to:
  /// **'Completa tu información personal y deportiva'**
  String get playerPersonalDataSubtitle;

  /// Etiqueta para el número de documento de identidad del jugador
  ///
  /// In es, this message translates to:
  /// **'Número de documento'**
  String get playerPersonalDataDocumentLabel;

  /// Pista para el número de documento de identidad del jugador
  ///
  /// In es, this message translates to:
  /// **'Ej. 1020304050'**
  String get playerPersonalDataDocumentHint;

  /// Error cuando el documento está vacío
  ///
  /// In es, this message translates to:
  /// **'El número de documento es obligatorio'**
  String get playerPersonalDataDocumentRequired;

  /// Error cuando el documento tiene menos de 5 caracteres
  ///
  /// In es, this message translates to:
  /// **'El documento debe tener al menos 5 caracteres'**
  String get playerPersonalDataDocumentInvalid;

  /// Etiqueta para el teléfono del jugador
  ///
  /// In es, this message translates to:
  /// **'Teléfono'**
  String get playerPersonalDataPhoneLabel;

  /// Pista para el teléfono del jugador
  ///
  /// In es, this message translates to:
  /// **'Ej. 3001234567'**
  String get playerPersonalDataPhoneHint;

  /// Error cuando el teléfono está vacío
  ///
  /// In es, this message translates to:
  /// **'El teléfono es obligatorio'**
  String get playerPersonalDataPhoneRequired;

  /// Error cuando el teléfono tiene menos de 7 dígitos
  ///
  /// In es, this message translates to:
  /// **'El teléfono debe tener al menos 7 dígitos'**
  String get playerPersonalDataPhoneInvalid;

  /// Etiqueta para el primer nombre del jugador
  ///
  /// In es, this message translates to:
  /// **'Primer nombre'**
  String get playerPersonalDataFirstNameLabel;

  /// Pista para el primer nombre del jugador
  ///
  /// In es, this message translates to:
  /// **'Ej. Juan'**
  String get playerPersonalDataFirstNameHint;

  /// Error cuando el primer nombre está vacío
  ///
  /// In es, this message translates to:
  /// **'El primer nombre es obligatorio'**
  String get playerPersonalDataFirstNameRequired;

  /// Etiqueta para el segundo nombre del jugador
  ///
  /// In es, this message translates to:
  /// **'Segundo nombre'**
  String get playerPersonalDataSecondNameLabel;

  /// Pista para el segundo nombre del jugador
  ///
  /// In es, this message translates to:
  /// **'Ej. Carlos (opcional)'**
  String get playerPersonalDataSecondNameHint;

  /// Etiqueta para el primer apellido del jugador
  ///
  /// In es, this message translates to:
  /// **'Primer apellido'**
  String get playerPersonalDataFirstSurnameLabel;

  /// Pista para el primer apellido del jugador
  ///
  /// In es, this message translates to:
  /// **'Ej. Pérez'**
  String get playerPersonalDataFirstSurnameHint;

  /// Error cuando el primer apellido está vacío
  ///
  /// In es, this message translates to:
  /// **'El primer apellido es obligatorio'**
  String get playerPersonalDataFirstSurnameRequired;

  /// Etiqueta para el segundo apellido del jugador
  ///
  /// In es, this message translates to:
  /// **'Segundo apellido'**
  String get playerPersonalDataSecondSurnameLabel;

  /// Pista para el segundo apellido del jugador
  ///
  /// In es, this message translates to:
  /// **'Ej. Gómez (opcional)'**
  String get playerPersonalDataSecondSurnameHint;

  /// Etiqueta para el selector de sexo del jugador
  ///
  /// In es, this message translates to:
  /// **'Sexo'**
  String get playerPersonalDataSexLabel;

  /// Error cuando el sexo no ha sido seleccionado
  ///
  /// In es, this message translates to:
  /// **'Selecciona tu sexo'**
  String get playerPersonalDataSexRequired;

  /// Opción de sexo masculino
  ///
  /// In es, this message translates to:
  /// **'Masculino'**
  String get playerPersonalDataSexMale;

  /// Opción de sexo femenino
  ///
  /// In es, this message translates to:
  /// **'Femenino'**
  String get playerPersonalDataSexFemale;

  /// Opción de sexo otro
  ///
  /// In es, this message translates to:
  /// **'Otro'**
  String get playerPersonalDataSexOther;

  /// Etiqueta para el campo de fecha de nacimiento
  ///
  /// In es, this message translates to:
  /// **'Fecha de nacimiento'**
  String get playerPersonalDataBirthDateLabel;

  /// Pista para fecha de nacimiento
  ///
  /// In es, this message translates to:
  /// **'AAAA-MM-DD'**
  String get playerPersonalDataBirthDateHint;

  /// Error cuando la fecha de nacimiento está vacía
  ///
  /// In es, this message translates to:
  /// **'La fecha de nacimiento es obligatoria'**
  String get playerPersonalDataBirthDateRequired;

  /// Etiqueta para el campo de edad calculada
  ///
  /// In es, this message translates to:
  /// **'Edad'**
  String get playerPersonalDataAgeLabel;

  /// Texto descriptivo de edad en años cumplidos
  ///
  /// In es, this message translates to:
  /// **'{age} años'**
  String playerPersonalDataAgeYears(int age);

  /// Etiqueta para el selector de tipo de sangre
  ///
  /// In es, this message translates to:
  /// **'Tipo de sangre y RH'**
  String get playerPersonalDataBloodTypeLabel;

  /// Pista para el selector de tipo de sangre
  ///
  /// In es, this message translates to:
  /// **'Selecciona una opción'**
  String get playerPersonalDataBloodTypeHint;

  /// Error cuando no se ha seleccionado tipo de sangre
  ///
  /// In es, this message translates to:
  /// **'Selecciona tu tipo de sangre'**
  String get playerPersonalDataBloodTypeRequired;

  /// Etiqueta para el selector de departamento
  ///
  /// In es, this message translates to:
  /// **'Departamento'**
  String get playerPersonalDataDepartmentLabel;

  /// Pista para el selector de departamento
  ///
  /// In es, this message translates to:
  /// **'Selecciona tu departamento'**
  String get playerPersonalDataDepartmentHint;

  /// Error cuando no se ha seleccionado departamento
  ///
  /// In es, this message translates to:
  /// **'Selecciona tu departamento'**
  String get playerPersonalDataDepartmentRequired;

  /// Etiqueta para el selector de municipio
  ///
  /// In es, this message translates to:
  /// **'Municipio'**
  String get playerPersonalDataMunicipalityLabel;

  /// Pista para el selector de municipio
  ///
  /// In es, this message translates to:
  /// **'Selecciona tu municipio'**
  String get playerPersonalDataMunicipalityHint;

  /// Error cuando no se ha seleccionado municipio
  ///
  /// In es, this message translates to:
  /// **'Selecciona tu municipio'**
  String get playerPersonalDataMunicipalityRequired;

  /// Mensaje informativo cuando se intenta seleccionar municipio sin departamento previo
  ///
  /// In es, this message translates to:
  /// **'Selecciona primero un departamento'**
  String get playerPersonalDataSelectDepartmentFirst;

  /// Etiqueta para la sección de posiciones tácticas
  ///
  /// In es, this message translates to:
  /// **'Posiciones de juego'**
  String get playerPersonalDataPositionsLabel;

  /// Subtítulo explicativo de posiciones de juego
  ///
  /// In es, this message translates to:
  /// **'Selecciona una o más posiciones en las que juegas'**
  String get playerPersonalDataPositionsSubtitle;

  /// Error cuando no se ha seleccionado ninguna posición táctica
  ///
  /// In es, this message translates to:
  /// **'Debes seleccionar al menos una posición'**
  String get playerPersonalDataPositionsRequired;

  /// Texto del botón principal para guardar el formulario de datos personales
  ///
  /// In es, this message translates to:
  /// **'Guardar datos personales'**
  String get playerPersonalDataSaveButton;

  /// Texto del botón de guardar durante el procesamiento
  ///
  /// In es, this message translates to:
  /// **'Guardando...'**
  String get playerPersonalDataSaving;

  /// Mensaje de confirmación exitosa al guardar
  ///
  /// In es, this message translates to:
  /// **'Datos personales actualizados correctamente'**
  String get playerPersonalDataSaveSuccess;

  /// Mensaje genérico de error al intentar guardar los datos personales
  ///
  /// In es, this message translates to:
  /// **'No fue posible guardar los datos. Inténtalo nuevamente.'**
  String get playerPersonalDataErrorBanner;

  /// Mensaje de error cuando el documento ya está vinculado a otra cuenta de jugador
  ///
  /// In es, this message translates to:
  /// **'Este número de documento ya está asociado a otro jugador.'**
  String get playerPersonalDataDocumentAlreadyLinked;

  /// Mensaje de error cuando no hay conexión disponible para sincronizar con Supabase
  ///
  /// In es, this message translates to:
  /// **'No hay conexión a internet. Los datos no se pudieron sincronizar.'**
  String get playerPersonalDataOfflineError;

  /// Título del diálogo de confirmación ante cambios sin guardar
  ///
  /// In es, this message translates to:
  /// **'¿Descartar cambios?'**
  String get playerPersonalDataUnsavedChangesTitle;

  /// Mensaje del diálogo de confirmación ante cambios sin guardar
  ///
  /// In es, this message translates to:
  /// **'Tienes cambios sin guardar en tu ficha personal. Si sales ahora, se perderán las modificaciones.'**
  String get playerPersonalDataUnsavedChangesMessage;

  /// Botón para descartar cambios y salir de la pantalla
  ///
  /// In es, this message translates to:
  /// **'Descartar'**
  String get playerPersonalDataUnsavedChangesDiscard;

  /// Botón para permanecer en la pantalla y seguir editando
  ///
  /// In es, this message translates to:
  /// **'Continuar editando'**
  String get playerPersonalDataUnsavedChangesKeepEditing;

  /// Posición de Portero
  ///
  /// In es, this message translates to:
  /// **'Portero (POR)'**
  String get playerPositionPOR;

  /// Posición de Defensa Central
  ///
  /// In es, this message translates to:
  /// **'Defensa Central (DFC)'**
  String get playerPositionDFC;

  /// Posición de Lateral Derecho
  ///
  /// In es, this message translates to:
  /// **'Lateral Derecho (LD)'**
  String get playerPositionLD;

  /// Posición de Lateral Izquierdo
  ///
  /// In es, this message translates to:
  /// **'Lateral Izquierdo (LI)'**
  String get playerPositionLI;

  /// Posición de Carrilero Derecho
  ///
  /// In es, this message translates to:
  /// **'Carrilero Derecho (CAD)'**
  String get playerPositionCAD;

  /// Posición de Carrilero Izquierdo
  ///
  /// In es, this message translates to:
  /// **'Carrilero Izquierdo (CAI)'**
  String get playerPositionCAI;

  /// Posición de Mediocentro Defensivo
  ///
  /// In es, this message translates to:
  /// **'Mediocentro Defensivo (MCD)'**
  String get playerPositionMCD;

  /// Posición de Mediocentro
  ///
  /// In es, this message translates to:
  /// **'Mediocentro (MC)'**
  String get playerPositionMC;

  /// Posición de Mediocentro Ofensivo
  ///
  /// In es, this message translates to:
  /// **'Mediocentro Ofensivo (MCO)'**
  String get playerPositionMCO;

  /// Posición de Medio Derecho
  ///
  /// In es, this message translates to:
  /// **'Medio Derecho (MD)'**
  String get playerPositionMD;

  /// Posición de Medio Izquierdo
  ///
  /// In es, this message translates to:
  /// **'Medio Izquierdo (MI)'**
  String get playerPositionMI;

  /// Posición de Extremo Derecho
  ///
  /// In es, this message translates to:
  /// **'Extremo Derecho (ED)'**
  String get playerPositionED;

  /// Posición de Extremo Izquierdo
  ///
  /// In es, this message translates to:
  /// **'Extremo Izquierdo (EI)'**
  String get playerPositionEI;

  /// Posición de Mediapunta
  ///
  /// In es, this message translates to:
  /// **'Mediapunta (MP)'**
  String get playerPositionMP;

  /// Posición de Delantero Centro
  ///
  /// In es, this message translates to:
  /// **'Delantero Centro (DC)'**
  String get playerPositionDC;

  /// Encabezado de línea táctica para arqueros
  ///
  /// In es, this message translates to:
  /// **'Portería'**
  String get playerTacticalLineGoalkeeper;

  /// Encabezado de línea táctica para defensores
  ///
  /// In es, this message translates to:
  /// **'Defensa'**
  String get playerTacticalLineDefender;

  /// Encabezado de línea táctica para mediocampistas
  ///
  /// In es, this message translates to:
  /// **'Mediocampo'**
  String get playerTacticalLineMidfielder;

  /// Encabezado de línea táctica para delanteros
  ///
  /// In es, this message translates to:
  /// **'Delantera'**
  String get playerTacticalLineForward;

  /// Pista del campo de búsqueda en el selector de ubicación
  ///
  /// In es, this message translates to:
  /// **'Buscar...'**
  String get locationPickerSearchPlaceholder;

  /// Mensaje cuando no hay coincidencias de búsqueda en el selector
  ///
  /// In es, this message translates to:
  /// **'No se encontraron resultados'**
  String get locationPickerEmptyState;

  /// Título del modal para seleccionar departamento
  ///
  /// In es, this message translates to:
  /// **'Seleccionar Departamento'**
  String get locationPickerSelectDepartmentTitle;

  /// Título del modal para seleccionar municipio
  ///
  /// In es, this message translates to:
  /// **'Seleccionar Municipio'**
  String get locationPickerSelectMunicipalityTitle;

  /// Texto del botón principal para escanear y capturar la cédula
  ///
  /// In es, this message translates to:
  /// **'Escanear / Capturar Cédula'**
  String get playerDocumentScanButton;

  /// Título de la tarjeta de captura de imágenes de la cédula
  ///
  /// In es, this message translates to:
  /// **'Fotos de la Cédula'**
  String get playerDocumentCardTitle;

  /// Subtítulo de la tarjeta de captura de imágenes de la cédula
  ///
  /// In es, this message translates to:
  /// **'Captura el frente y reverso de tu cédula colombiana para completar tu ficha'**
  String get playerDocumentCardSubtitle;

  /// Etiqueta para la cara frontal de la cédula
  ///
  /// In es, this message translates to:
  /// **'Frente (Cara frontal)'**
  String get playerDocumentFrontSideLabel;

  /// Etiqueta para la cara posterior de la cédula
  ///
  /// In es, this message translates to:
  /// **'Reverso (Cara posterior)'**
  String get playerDocumentBackSideLabel;

  /// Botón para iniciar la captura de la cara frontal
  ///
  /// In es, this message translates to:
  /// **'Capturar frente'**
  String get playerDocumentCaptureFrontButton;

  /// Botón para iniciar la captura de la cara posterior
  ///
  /// In es, this message translates to:
  /// **'Capturar reverso'**
  String get playerDocumentCaptureBackButton;

  /// Botón para repetir la foto de una cara ya capturada
  ///
  /// In es, this message translates to:
  /// **'Repetir foto'**
  String get playerDocumentRecaptureButton;

  /// Mensaje mientras ML Kit procesa las imágenes de la cédula
  ///
  /// In es, this message translates to:
  /// **'Procesando documento...'**
  String get playerDocumentScanningIndicator;

  /// Mensaje de éxito al extraer datos completos de la cédula
  ///
  /// In es, this message translates to:
  /// **'Datos leídos automáticamente de la cédula'**
  String get playerDocumentScanSuccessFeedback;

  /// Mensaje cuando se obtuvieron datos parciales del documento
  ///
  /// In es, this message translates to:
  /// **'Se completaron algunos datos de la cédula. Por favor verifica y completa los campos faltantes.'**
  String get playerDocumentScanPartialFeedback;

  /// Mensaje cuando no se pudieron extraer datos del documento
  ///
  /// In es, this message translates to:
  /// **'No se detectaron datos legibles. Puedes ingresar tus datos manualmente.'**
  String get playerDocumentScanEmptyFeedback;

  /// Alerta cuando el usuario deniega el permiso de cámara
  ///
  /// In es, this message translates to:
  /// **'Se requiere permiso de cámara para capturar la cédula.'**
  String get playerDocumentCameraPermissionDenied;

  /// Botón para ir a los ajustes del sistema tras denegación de cámara
  ///
  /// In es, this message translates to:
  /// **'Abrir configuración'**
  String get playerDocumentCameraPermissionOpenSettings;

  /// Error al intentar guardar la ficha sin tener capturadas ambas fotos de la cédula
  ///
  /// In es, this message translates to:
  /// **'Debes capturar ambas caras de tu cédula (frente y reverso) para continuar'**
  String get playerDocumentImagesRequiredError;

  /// Error al fallar la subida de fotos a almacenamiento
  ///
  /// In es, this message translates to:
  /// **'Error al subir las imágenes de la cédula. Inténtalo nuevamente.'**
  String get playerDocumentUploadError;

  /// Título de la sección de foto de carnet en el formulario del jugador
  ///
  /// In es, this message translates to:
  /// **'Foto de Perfil'**
  String get playerProfilePhotoSectionTitle;

  /// Subtítulo instructivo para la foto de perfil del carnet
  ///
  /// In es, this message translates to:
  /// **'Tómate una foto o selecciónala de tu galería para tu carnet digital'**
  String get playerProfilePhotoSectionSubtitle;

  /// Botón para tomar o seleccionar la foto de perfil
  ///
  /// In es, this message translates to:
  /// **'Tomar Foto de Perfil'**
  String get playerProfilePhotoAction;

  /// Botón para reemplazar la foto de perfil ya capturada
  ///
  /// In es, this message translates to:
  /// **'Cambiar Foto'**
  String get playerProfilePhotoChangeAction;

  /// Opción para abrir la cámara
  ///
  /// In es, this message translates to:
  /// **'Tomar con la cámara'**
  String get playerProfilePhotoCameraOption;

  /// Opción para elegir foto de la galería
  ///
  /// In es, this message translates to:
  /// **'Elegir de la galería'**
  String get playerProfilePhotoGalleryOption;

  /// Alerta cuando se deniegan permisos para la foto de perfil
  ///
  /// In es, this message translates to:
  /// **'Se requiere permiso de cámara o galería para tu foto de perfil.'**
  String get playerProfilePhotoPermissionDenied;

  /// Error al fallar la subida de la foto de perfil
  ///
  /// In es, this message translates to:
  /// **'Error al subir la fotografía de perfil. Inténtalo nuevamente.'**
  String get playerProfilePhotoUploadError;

  /// Título de la pantalla de resumen de datos personales
  ///
  /// In es, this message translates to:
  /// **'Datos Personales'**
  String get playerPersonalDataSummaryTitle;

  /// Botón en AppBar para editar los datos personales
  ///
  /// In es, this message translates to:
  /// **'Editar Datos'**
  String get playerPersonalDataEditAction;

  /// Formato de edad calculada en años
  ///
  /// In es, this message translates to:
  /// **'{age} años'**
  String playerSummaryAgeFormat(int age);

  /// Texto cuando la fecha de nacimiento no está disponible
  ///
  /// In es, this message translates to:
  /// **'Edad no registrada'**
  String get playerSummaryAgeUnknown;

  /// Título de sección de datos demográficos
  ///
  /// In es, this message translates to:
  /// **'Información Demográfica'**
  String get playerSummaryDemographicsTitle;

  /// Subtítulo de sección de datos demográficos
  ///
  /// In es, this message translates to:
  /// **'Datos personales y lugar de residencia'**
  String get playerSummaryDemographicsSubtitle;

  /// Etiqueta para el sexo del jugador
  ///
  /// In es, this message translates to:
  /// **'Sexo'**
  String get playerSummarySexLabel;

  /// Etiqueta para fecha de nacimiento
  ///
  /// In es, this message translates to:
  /// **'Fecha de Nacimiento'**
  String get playerSummaryBirthDateLabel;

  /// Etiqueta para grupo sanguíneo y RH
  ///
  /// In es, this message translates to:
  /// **'Tipo de Sangre'**
  String get playerSummaryBloodTypeLabel;

  /// Etiqueta para departamento
  ///
  /// In es, this message translates to:
  /// **'Departamento'**
  String get playerSummaryDepartmentLabel;

  /// Etiqueta para municipio
  ///
  /// In es, this message translates to:
  /// **'Municipio'**
  String get playerSummaryMunicipalityLabel;

  /// Título de sección de posiciones de juego
  ///
  /// In es, this message translates to:
  /// **'Perfil Táctico'**
  String get playerSummaryTacticalTitle;

  /// Subtítulo de sección táctica
  ///
  /// In es, this message translates to:
  /// **'Posiciones registradas en el terreno de juego'**
  String get playerSummaryTacticalSubtitle;

  /// Etiqueta de posición principal
  ///
  /// In es, this message translates to:
  /// **'Posición Principal'**
  String get playerSummaryPrimaryPositionLabel;

  /// Etiqueta de posiciones secundarias
  ///
  /// In es, this message translates to:
  /// **'Posiciones Secundarias'**
  String get playerSummarySecondaryPositionsLabel;

  /// Texto cuando no hay posiciones secundarias
  ///
  /// In es, this message translates to:
  /// **'Sin posiciones secundarias registradas'**
  String get playerSummaryNoSecondaryPositions;

  /// Título de sección de fotos de la cédula
  ///
  /// In es, this message translates to:
  /// **'Documento de Identidad'**
  String get playerSummaryDocumentationTitle;

  /// Subtítulo de sección de documentos
  ///
  /// In es, this message translates to:
  /// **'Cédula de ciudadanía por ambas caras'**
  String get playerSummaryDocumentationSubtitle;

  /// Etiqueta de la cara frontal de la cédula
  ///
  /// In es, this message translates to:
  /// **'Cara Frontal'**
  String get playerSummaryFrontDocLabel;

  /// Etiqueta de la cara posterior de la cédula
  ///
  /// In es, this message translates to:
  /// **'Cara Posterior'**
  String get playerSummaryBackDocLabel;

  /// Texto cuando una cara de la cédula no fue capturada
  ///
  /// In es, this message translates to:
  /// **'No capturada'**
  String get playerSummaryDocNotCaptured;

  /// Botón para cerrar el visor interactivo de la cédula
  ///
  /// In es, this message translates to:
  /// **'Cerrar'**
  String get playerSummaryViewerCloseAction;

  /// Subtítulo del botón de datos personales en perfil
  ///
  /// In es, this message translates to:
  /// **'Consulta tu carnet, ficha demográfica y táctica'**
  String get playerPersonalDataSummarySubtitle;

  /// Título del diálogo de confirmación cuando ya existe un fixture generado
  ///
  /// In es, this message translates to:
  /// **'¿Regenerar el fixture?'**
  String get fixtureRegenerateConfirmTitle;

  /// Mensaje de confirmación al regenerar el fixture de una competición
  ///
  /// In es, this message translates to:
  /// **'Esta competición ya tiene un fixture creado. Si continúas, se reemplazarán todos los partidos actuales y sus programaciones tanto en este dispositivo como en la nube.'**
  String get fixtureRegenerateConfirmMessage;

  /// Botón de confirmación para reemplazar el fixture actual
  ///
  /// In es, this message translates to:
  /// **'Regenerar Fixture'**
  String get fixtureRegenerateConfirmAction;

  /// Etiqueta mostrada cuando la sede, cancha o árbitro aún no han sido asignados
  ///
  /// In es, this message translates to:
  /// **'Por definir'**
  String get matchLogisticsTbdLabel;

  /// Texto de ayuda para campos opcionales al programar un partido
  ///
  /// In es, this message translates to:
  /// **'Opcional — puedes asignarlo después'**
  String get scheduleMatchOptionalHint;

  /// Encabezado de la sección de opciones, legal y soporte debajo de permisos en Perfil
  ///
  /// In es, this message translates to:
  /// **'Preferencias y soporte'**
  String get profileLegalSupportSectionTitle;

  /// Botón en Perfil para consultar la opción de quitar anuncios
  ///
  /// In es, this message translates to:
  /// **'Quitar anuncios'**
  String get profileRemoveAdsButton;

  /// Botón en Perfil para abrir los Términos y condiciones
  ///
  /// In es, this message translates to:
  /// **'Términos y condiciones'**
  String get profileTermsButton;

  /// Botón en Perfil para abrir las Políticas de tratamiento de datos
  ///
  /// In es, this message translates to:
  /// **'Políticas de tratamiento de datos'**
  String get profilePrivacyPolicyButton;

  /// Botón en Perfil para abrir las Preguntas frecuentes
  ///
  /// In es, this message translates to:
  /// **'Preguntas frecuentes'**
  String get profileFaqButton;

  /// Título del modal informativo para quitar anuncios
  ///
  /// In es, this message translates to:
  /// **'Experiencia sin anuncios'**
  String get removeAdsDialogTitle;

  /// Insignia que indica disponibilidad próxima de la opción sin anuncios
  ///
  /// In es, this message translates to:
  /// **'Próximamente'**
  String get removeAdsComingSoonBadge;

  /// Descripción del beneficio de la experiencia sin publicidad
  ///
  /// In es, this message translates to:
  /// **'Muy pronto podrás disfrutar de ViFutbol sin publicidad mientras sigues marcadores, tablas de posiciones y novedades de tus campeonatos en tiempo real.'**
  String get removeAdsDialogDescription;

  /// Aviso transparente de que la pasarela está en preparación
  ///
  /// In es, this message translates to:
  /// **'La pasarela de pagos se encuentra en preparación. No se realizará ningún cobro en esta versión.'**
  String get removeAdsDialogNotice;

  /// Botón para cerrar el modal de quitar anuncios
  ///
  /// In es, this message translates to:
  /// **'Entendido'**
  String get removeAdsDialogCloseAction;

  /// Subtítulo de fecha de vigencia de documentos legales
  ///
  /// In es, this message translates to:
  /// **'Última actualización: noviembre de 2026'**
  String get legalDocumentLastUpdated;

  /// Título sección 1 de términos y condiciones
  ///
  /// In es, this message translates to:
  /// **'1. Aceptación y uso de la plataforma'**
  String get termsSection1Title;

  /// Contenido sección 1 de términos y condiciones
  ///
  /// In es, this message translates to:
  /// **'ViFutbol es una plataforma para la gestión de campeonatos, sedes deportivas, equipos, actas de partidos y seguimiento en vivo. Al usar la aplicación aceptas operar bajo estos términos y las reglas deportivas vigentes.'**
  String get termsSection1Body;

  /// Título sección 2 de términos y condiciones
  ///
  /// In es, this message translates to:
  /// **'2. Roles y responsabilidades'**
  String get termsSection2Title;

  /// Contenido sección 2 de términos y condiciones
  ///
  /// In es, this message translates to:
  /// **'Cada usuario accede según su rol asignado (Organizador, Entrenador, Árbitro, Jugador o Aficionado). Las actas oficiales, resultados y sanciones registradas por roles autorizados constituyen la fuente oficial del torneo.'**
  String get termsSection2Body;

  /// Título sección 3 de términos y condiciones
  ///
  /// In es, this message translates to:
  /// **'3. Operación offline y disponibilidad'**
  String get termsSection3Title;

  /// Contenido sección 3 de términos y condiciones
  ///
  /// In es, this message translates to:
  /// **'ViFutbol permite consultar información descargada y operar sin conexión en cancha, sincronizando los cambios pendientes cuando la conectividad se restablece.'**
  String get termsSection3Body;

  /// Título sección 1 de políticas de tratamiento de datos
  ///
  /// In es, this message translates to:
  /// **'1. Datos personales recolectados'**
  String get privacySection1Title;

  /// Contenido sección 1 de políticas de tratamiento de datos
  ///
  /// In es, this message translates to:
  /// **'Tratamos los datos suministrados en tu perfil (nombre, correo electrónico, documento de identificación y ficha deportiva de jugador cuando corresponda) exclusivamente para administrar campeonatos, inscripciones y elegibilidad.'**
  String get privacySection1Body;

  /// Título sección 2 de políticas de tratamiento de datos
  ///
  /// In es, this message translates to:
  /// **'2. Finalidad y protección'**
  String get privacySection2Title;

  /// Contenido sección 2 de políticas de tratamiento de datos
  ///
  /// In es, this message translates to:
  /// **'Tu información se almacena de forma segura en tu dispositivo para soporte offline y en nuestros servidores autorizados, sin ser comercializada con terceros.'**
  String get privacySection2Body;

  /// Título sección 3 de políticas de tratamiento de datos
  ///
  /// In es, this message translates to:
  /// **'3. Derechos del titular'**
  String get privacySection3Title;

  /// Contenido sección 3 de políticas de tratamiento de datos
  ///
  /// In es, this message translates to:
  /// **'Como titular de los datos puedes consultar, actualizar y solicitar la supresión de tu información personal conforme a la normativa aplicable de protección de datos.'**
  String get privacySection3Body;

  /// Pregunta frecuente 1
  ///
  /// In es, this message translates to:
  /// **'¿Cómo funciona ViFutbol sin conexión a internet?'**
  String get faqItem1Question;

  /// Respuesta frecuente 1
  ///
  /// In es, this message translates to:
  /// **'La aplicación guarda una copia local de tus torneos, partidos y datos del perfil para que puedas consultarlos en la cancha. Cuando vuelvas a tener conexión, la sincronización actualiza automáticamente los cambios pendientes.'**
  String get faqItem1Answer;

  /// Pregunta frecuente 2
  ///
  /// In es, this message translates to:
  /// **'¿Puedo cambiar mi rol activo desde el Perfil?'**
  String get faqItem2Question;

  /// Respuesta frecuente 2
  ///
  /// In es, this message translates to:
  /// **'No. Por seguridad e integridad del control de acceso (RBAC), tu rol activo se muestra en modo solo lectura en la tarjeta de identidad del Perfil.'**
  String get faqItem2Answer;

  /// Pregunta frecuente 3
  ///
  /// In es, this message translates to:
  /// **'¿Cómo completo mis datos deportivos como Jugador?'**
  String get faqItem3Question;

  /// Respuesta frecuente 3
  ///
  /// In es, this message translates to:
  /// **'Si tu rol es Jugador, ingresa a \'Datos personales\' dentro de tu Perfil para completar tu ficha demográfica, posición táctica y documento de identidad.'**
  String get faqItem3Answer;

  /// Pregunta frecuente 4
  ///
  /// In es, this message translates to:
  /// **'¿Cuándo estará disponible la opción de Quitar anuncios?'**
  String get faqItem4Question;

  /// Respuesta frecuente 4
  ///
  /// In es, this message translates to:
  /// **'Estamos integrando la pasarela de pagos oficial. Muy pronto podrás activar la experiencia sin anuncios directamente desde la sección de Perfil.'**
  String get faqItem4Answer;
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
