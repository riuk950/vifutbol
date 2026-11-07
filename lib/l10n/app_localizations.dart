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
