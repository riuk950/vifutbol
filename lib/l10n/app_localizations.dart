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
