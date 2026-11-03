// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'vifutbol';

  @override
  String get tabMatchday => 'Jornada';

  @override
  String get tabStandings => 'Posiciones';

  @override
  String get tabVenues => 'Sedes';

  @override
  String get tabProfile => 'Perfil';

  @override
  String get envDevBadge => 'DEV';

  @override
  String get envDevelopmentTitle => 'Entorno de Desarrollo';

  @override
  String get envProductionTitle => 'Entorno de Producción';

  @override
  String get connectivityOfflineMessage =>
      'Modo sin conexión: mostrando datos guardados en el dispositivo';

  @override
  String get connectivityRestoredMessage => 'Conexión restaurada';

  @override
  String get stateLoadingTitle => 'Cargando datos deportivos...';

  @override
  String get stateLoadingSubtitle =>
      'Por favor espera un momento mientras se sincroniza la información.';

  @override
  String get stateContentTitle => 'Contenido deportivo listo';

  @override
  String get stateEmptyTitle => 'No hay registros disponibles';

  @override
  String get stateEmptyDescription =>
      'Aún no se han programado partidos ni eventos para este torneo.';

  @override
  String get stateErrorTitle => 'Ocurrió un problema';

  @override
  String get stateErrorDescription =>
      'No pudimos cargar la información en este momento.';

  @override
  String get stateSuccessTitle => 'Operación completada';

  @override
  String get stateSuccessDescription =>
      'Los datos se han guardado y actualizado con éxito.';

  @override
  String get actionRetry => 'Reintentar';

  @override
  String get actionContinue => 'Continuar';

  @override
  String get actionRefresh => 'Actualizar';

  @override
  String get authWelcomeTitle => 'Bienvenido a vifutbol';

  @override
  String get authWelcomeSubtitle =>
      'Tu plataforma oficial para gestión de torneos, sedes y estadísticas';

  @override
  String get authLoginTab => 'Iniciar sesión';

  @override
  String get authRegisterTab => 'Crear cuenta';

  @override
  String get authEmailLabel => 'Correo electrónico';

  @override
  String get authEmailHint => 'ejemplo@vifutbol.com';

  @override
  String get authPasswordLabel => 'Contraseña';

  @override
  String get authPasswordHint => 'Mínimo 8 caracteres';

  @override
  String get authFullNameLabel => 'Nombre completo';

  @override
  String get authFullNameHint => 'Tu nombre y apellido';

  @override
  String get authContinueAsFan => 'Continuar como Aficionado';

  @override
  String get authOrDivider => 'o también puedes';

  @override
  String get authErrorInvalidEmail => 'Ingresa un correo electrónico válido';

  @override
  String get authErrorPasswordTooShort =>
      'La contraseña debe tener al menos 8 caracteres';

  @override
  String get authErrorNameTooShort =>
      'El nombre debe tener al menos 2 caracteres';

  @override
  String get authErrorInvalidCredentials => 'Correo o contraseña incorrectos';

  @override
  String get authErrorNetworkRequired =>
      'Se requiere conexión a internet para iniciar sesión o registrarse';

  @override
  String authErrorRateLimited(int seconds) {
    return 'Demasiados intentos fallidos. Intenta de nuevo en $seconds segundos.';
  }

  @override
  String get onboardingTitle => 'Selecciona tu Rol Deportivo';

  @override
  String get onboardingSubtitle =>
      'Define tu nivel de participación y responsabilidades en los torneos';

  @override
  String get onboardingAuthCodeLabel => 'Código de autorización oficial';

  @override
  String get onboardingAuthCodeHint =>
      'Requerido para Organizador o Árbitro en torneos oficiales';

  @override
  String get onboardingErrorInvalidCode =>
      'Código de autorización inválido para el rol seleccionado';

  @override
  String get onboardingConfirmAction => 'Confirmar y entrar al torneo';

  @override
  String get onboardingDiscardTitle => '¿Descartar cambios?';

  @override
  String get onboardingDiscardMessage =>
      'Si sales ahora, deberás seleccionar tu rol la próxima vez que ingreses a la aplicación.';

  @override
  String get actionDiscard => 'Descartar';

  @override
  String get actionCancel => 'Cancelar';

  @override
  String get roleOrganizer => 'Organizador';

  @override
  String get roleCoach => 'Entrenador';

  @override
  String get roleReferee => 'Árbitro';

  @override
  String get rolePlayer => 'Jugador';

  @override
  String get roleFan => 'Aficionado';

  @override
  String get roleDescOrganizer =>
      'Creación de torneos, administración de sedes y aprobación oficial';

  @override
  String get roleDescCoach =>
      'Gestión de plantilla, convocatoria de jugadores y alineaciones';

  @override
  String get roleDescReferee =>
      'Registro de actas arbitrales en vivo, goles, tarjetas y cierres';

  @override
  String get roleDescPlayer =>
      'Consulta de convocatorias propias, historial y estadísticas de rendimiento';

  @override
  String get roleDescFan =>
      'Seguimiento público de partidos, calendario, noticias y tablas';

  @override
  String get profileActiveRole => 'Rol deportivo activo';

  @override
  String get profileSwitchRole => 'Cambiar rol activo';

  @override
  String get profileCapabilitiesTitle => 'Permisos y capacidades del rol';

  @override
  String get capabilityGranted => 'Habilitado';

  @override
  String get capabilityDenied => 'Restringido';

  @override
  String get capManageTournaments => 'Crear y configurar torneos';

  @override
  String get capManageVenues => 'Administrar sedes y canchas';

  @override
  String get capApproveRegistrations => 'Aprobar inscripciones de equipos';

  @override
  String get capAssignReferees => 'Designar árbitros para partidos';

  @override
  String get capManageTeamRoster => 'Gestionar plantilla del equipo';

  @override
  String get capManageLineups => 'Registrar convocatorias y alineaciones';

  @override
  String get capRecordMatchEvents => 'Registrar goles y tarjetas en vivo';

  @override
  String get capCloseMatchReport => 'Firmar y cerrar acta oficial del partido';

  @override
  String get capViewPersonalStats =>
      'Consultar estadísticas personales y convocatorias';

  @override
  String get capViewPublicContent =>
      'Consultar resultados, sedes y tablas públicas';

  @override
  String get profileLogoutAction => 'Cerrar sesión';

  @override
  String get profileLogoutDialogTitle => '¿Cerrar sesión en este dispositivo?';

  @override
  String get profileLogoutDialogMessage =>
      'Se limpiarán los datos de tu sesión local de forma segura.';

  @override
  String get profileGuestBannerTitle => 'Modo Visitante (Aficionado)';

  @override
  String get profileGuestBannerSubtitle =>
      'Inicia sesión o crea una cuenta para participar activamente como Entrenador, Árbitro, Jugador u Organizador.';

  @override
  String get profileLoginRegisterButton => 'Iniciar sesión o Registrarse';

  @override
  String get rbacAccessRestricted => 'Acceso restringido para tu rol actual';

  @override
  String get rbacRequiredRoleMessage =>
      'Esta acción requiere permisos autorizados para el rol requerido.';
}
