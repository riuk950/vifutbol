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
