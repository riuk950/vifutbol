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

  @override
  String get venuesTitle => 'Directorio de Sedes';

  @override
  String get venuesSubtitle =>
      'Complejos deportivos y canchas urbanas verificadas';

  @override
  String get venuesSearchHint => 'Buscar por nombre o dirección...';

  @override
  String get venuesFilterAllSurfaces => 'Todas las superficies';

  @override
  String get venuesFilterLightingOnly => 'Con iluminación nocturna';

  @override
  String get venuesProximityAction => 'Cercanía';

  @override
  String get venuesProximityActive => 'Ordenado por cercanía';

  @override
  String get venuesCreateAction => 'Nueva sede';

  @override
  String get venuesEditAction => 'Editar sede';

  @override
  String get venuesEmptyTitle => 'Aún no hay sedes registradas';

  @override
  String get venuesEmptySubtitle =>
      'No se encontraron sedes deportivas activas para este torneo.';

  @override
  String get venuesEmptyOrganizerPrompt =>
      'Registra la primera sede deportiva para comenzar a programar partidos.';

  @override
  String get venuesEmptyFilterTitle => 'Sin resultados';

  @override
  String get venuesEmptyFilterSubtitle =>
      'No encontramos sedes que coincidan con los filtros aplicados.';

  @override
  String get venuesClearFilters => 'Limpiar filtros';

  @override
  String get venuesDetailTitle => 'Detalle de la Sede';

  @override
  String get venuesAddressLabel => 'Dirección física';

  @override
  String get venuesReferenceLabel => 'Referencia urbana';

  @override
  String get venuesCoordinatesLabel => 'Coordenadas';

  @override
  String get venuesGetDirections => 'Cómo llegar';

  @override
  String get venuesDirectionsCopied => 'Indicaciones copiadas al portapapeles';

  @override
  String venuesPitchesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count canchas disponibles',
      one: '1 cancha disponible',
    );
    return '$_temp0';
  }

  @override
  String get venuesPitchesSectionTitle => 'Canchas internas';

  @override
  String get venuesAddPitchAction => 'Agregar cancha';

  @override
  String get venuesRemovePitchAction => 'Quitar cancha';

  @override
  String get venuesPitchNameLabel => 'Nombre de la cancha';

  @override
  String get venuesPitchNameHint => 'Ej. Cancha Sintética 1';

  @override
  String get venuesPitchSurfaceLabel => 'Tipo de superficie';

  @override
  String get venuesPitchFormatLabel => 'Modalidad / Formato';

  @override
  String get venuesPitchCapacityLabel => 'Capacidad de espectadores';

  @override
  String get venuesPitchLightingLabel => 'Iluminación artificial';

  @override
  String get venuesPitchLightingYes => 'Iluminación nocturna disponible';

  @override
  String get venuesPitchLightingNo => 'Sin iluminación nocturna';

  @override
  String get venuesPitchStatusLabel => 'Disponibilidad operativa';

  @override
  String get venuesStatusActive => 'Activa';

  @override
  String get venuesStatusMaintenance => 'En mantenimiento';

  @override
  String venuesDistanceKm(String distance) {
    return '$distance km';
  }

  @override
  String venuesCapacityCount(int count) {
    return '$count espectadores';
  }

  @override
  String get surfaceSyntheticGrass => 'Césped Sintético';

  @override
  String get surfaceNaturalGrass => 'Césped Natural';

  @override
  String get surfaceDirtOrSand => 'Tierra / Arena';

  @override
  String get surfaceHardCourt => 'Cemento / Futsal';

  @override
  String get formatFootball5 => 'Fútbol 5';

  @override
  String get formatFootball7 => 'Fútbol 7';

  @override
  String get formatFootball8 => 'Fútbol 8';

  @override
  String get formatFootball11 => 'Fútbol 11';

  @override
  String get venueFormCreateTitle => 'Registrar Sede Deportiva';

  @override
  String get venueFormEditTitle => 'Editar Sede Deportiva';

  @override
  String get venueFormNameLabel => 'Nombre del complejo o sede';

  @override
  String get venueFormNameHint => 'Mínimo 3 caracteres';

  @override
  String get venueFormAddressLabel => 'Dirección urbana';

  @override
  String get venueFormAddressHint => 'Mínimo 5 caracteres';

  @override
  String get venueFormReferenceLabel => 'Punto de referencia o indicaciones';

  @override
  String get venueFormReferenceHint =>
      'Opcional (ej. frente al parque metropolitano)';

  @override
  String get venueFormLatitudeLabel => 'Latitud';

  @override
  String get venueFormLongitudeLabel => 'Longitud';

  @override
  String get venueFormPickOnMap => 'Toca el mapa para fijar coordenadas';

  @override
  String get venueFormSaveAction => 'Guardar sede';

  @override
  String get venueFormDiscardTitle => '¿Descartar cambios de la sede?';

  @override
  String get venueFormDiscardMessage =>
      'Si sales ahora, se perderán los datos y canchas configuradas en este formulario.';

  @override
  String get venueErrorNameTooShort =>
      'El nombre debe tener al menos 3 caracteres';

  @override
  String get venueErrorAddressTooShort =>
      'La dirección debe tener al menos 5 caracteres';

  @override
  String get venueErrorInvalidLatitude =>
      'Latitud inválida (debe estar entre -90.0 y 90.0)';

  @override
  String get venueErrorInvalidLongitude =>
      'Longitud inválida (debe estar entre -180.0 y 180.0)';

  @override
  String get venueErrorPitchRequired =>
      'Debes agregar al menos 1 cancha interna activa';

  @override
  String get venueErrorPitchNameTooShort =>
      'El nombre de la cancha debe tener al menos 2 caracteres';

  @override
  String get venueErrorPitchCapacityNegative =>
      'La capacidad no puede ser negativa';

  @override
  String get locationPermissionBanner =>
      'Ubicación desactivada: mostrando sedes por referencia urbana';

  @override
  String get locationPermissionEnableAction => 'Activar ubicación';

  @override
  String get locationDevSimulatorTitle => 'Simulador GPS (DEV)';

  @override
  String get locationDevStateGranted => 'Concedido';

  @override
  String get locationDevStateDenied => 'Denegado';

  @override
  String get locationDevStatePermanentlyDenied => 'Revocado';

  @override
  String get tournamentsTitle => 'Campeonatos y Reglas';

  @override
  String get tournamentsSubtitle =>
      'Normativa oficial, formatos de competición y tablas del torneo';

  @override
  String get tournamentsCreateAction => 'Crear Campeonato';

  @override
  String get tournamentsEditAction => 'Editar Reglas';

  @override
  String get tournamentsFilterAll => 'Todos los formatos';

  @override
  String get tournamentFormatLeague => 'Liga';

  @override
  String get tournamentFormatKnockout => 'Copa Eliminatoria';

  @override
  String get tournamentFormatMixed => 'Mixto (Grupos + Eliminatoria)';

  @override
  String get tournamentStatusOpenRegistration => 'Inscripciones Abiertas';

  @override
  String get tournamentStatusInProgress => 'En Curso';

  @override
  String get tournamentStatusFinished => 'Finalizado';

  @override
  String get tournamentStartAction => 'Iniciar Campeonato (En Curso)';

  @override
  String get tournamentFinishAction => 'Finalizar Campeonato';

  @override
  String get tournamentsEmptyTitle => 'No hay campeonatos registrados';

  @override
  String get tournamentsEmptySubtitle =>
      'Crea el primer campeonato oficial para centralizar su normativa, puntos y llaves.';

  @override
  String get tournamentsDraftBannerTitle => 'Se recuperó un borrador guardado';

  @override
  String get tournamentsDraftBannerContinue => 'Continuar borrador';

  @override
  String get tournamentsDraftBannerClear => 'Limpiar borrador';

  @override
  String get tournamentRulesSectionTitle => 'Normativa Oficial del Torneo';

  @override
  String get tournamentScoringTitle => 'Sistema de Puntuación';

  @override
  String get tournamentPointsWin => 'Victoria';

  @override
  String get tournamentPointsDraw => 'Empate';

  @override
  String get tournamentPointsLoss => 'Derrota';

  @override
  String tournamentPointsValue(int points) {
    return '$points pts';
  }

  @override
  String get tournamentTiebreakersTitle => 'Criterios de Desempate en Tabla';

  @override
  String get tiebreakerGoalDifference => 'Diferencia de Gol';

  @override
  String get tiebreakerGoalsFor => 'Goles a Favor';

  @override
  String get tiebreakerHeadToHead => 'Duelo Directo';

  @override
  String get tiebreakerFairPlay => 'Fair Play (Menor puntaje de tarjetas)';

  @override
  String get tournamentDisciplinaryAndSquadTitle =>
      'Disciplina, Plantilla y Tiempo de Juego';

  @override
  String get tournamentYellowCardLimitLabel =>
      'Suspensión por acumulación de amarillas';

  @override
  String tournamentYellowCardLimitValue(int count) {
    return '$count tarjetas amarillas';
  }

  @override
  String get tournamentSquadRangeLabel => 'Cupo de jugadores por equipo';

  @override
  String get tournamentMinPlayersLabel => 'Mín. jugadores';

  @override
  String get tournamentMaxPlayersLabel => 'Máx. jugadores';

  @override
  String tournamentSquadRangeValue(int min, int max) {
    return 'Mín. $min / Máx. $max jugadores';
  }

  @override
  String get tournamentHalfDurationLabel => 'Duración por tiempo reglamentario';

  @override
  String tournamentHalfDurationValue(int minutes) {
    return '$minutes min por tiempo';
  }

  @override
  String get tournamentLeagueRoundsLabel => 'Modalidad de vueltas (Liga)';

  @override
  String get tournamentLeagueSingleRound => '1 vuelta (Solo ida)';

  @override
  String get tournamentLeagueDoubleRound => '2 vueltas (Ida y vuelta)';

  @override
  String get tournamentKnockoutStructureTitle =>
      'Estructura de Llaves Eliminatorias';

  @override
  String get tournamentStartingRoundLabel => 'Ronda inicial de llaves';

  @override
  String get knockoutRoundOf16 => 'Octavos de Final';

  @override
  String get knockoutQuarterFinals => 'Cuartos de Final';

  @override
  String get knockoutSemiFinals => 'Semifinal';

  @override
  String get knockoutFinalMatch => 'Final';

  @override
  String get tournamentDirectPenaltiesLabel =>
      'Desempate directo por penales al finalizar el tiempo reglamentario';

  @override
  String get tournamentTwoLeggedTiesLabel =>
      'Cruces a doble partido (Ida y vuelta)';

  @override
  String get tournamentSingleLegTieValue =>
      'Partido único (Exige ganador en cada llave)';

  @override
  String get tournamentGroupStageTitle => 'Configuración de Fase de Grupos';

  @override
  String get tournamentGroupCountLabel => 'Cantidad de grupos';

  @override
  String get tournamentAdvancingPerGroupLabel => 'Clasificados por grupo';

  @override
  String tournamentGroupSummaryValue(int groups, int advancing) {
    return '$groups grupos · clasifican $advancing por grupo';
  }

  @override
  String get tournamentAuditTrailTitle => 'Historial de Auditoría y Recálculos';

  @override
  String get tournamentFormCreateTitle => 'Crear Campeonato';

  @override
  String get tournamentFormEditTitle => 'Editar Reglas del Campeonato';

  @override
  String get tournamentFormNameLabel => 'Nombre oficial del campeonato';

  @override
  String get tournamentFormNameHint => 'Ej. Torneo Clausura ViFutbol 2026';

  @override
  String get tournamentFormCategoryLabel => 'Categoría';

  @override
  String get tournamentFormCategoryHint => 'Ej. Libre Masculino';

  @override
  String get tournamentFormStartDateLabel => 'Fecha de inicio';

  @override
  String get tournamentFormEndDateLabel => 'Fecha de finalización';

  @override
  String get tournamentFormFormatLabel => 'Formato del campeonato';

  @override
  String get tournamentFormSaveCreateAction => 'Crear Campeonato';

  @override
  String get tournamentFormSaveEditAction => 'Guardar Cambios';

  @override
  String get tournamentCriticalRuleLockBanner =>
      'Campeonato En Curso: alterar el formato o el sistema de puntuación requerirá confirmación administrativa explícita y recálculo auditado.';

  @override
  String get tournamentAuditDialogTitle =>
      'Confirmación Administrativa y Recálculo Auditado';

  @override
  String get tournamentAuditDialogMessage =>
      'Estás modificando reglas críticas de un campeonato En Curso. Ingresa el motivo oficial para registrar la auditoría y autorizar el recálculo de tabla.';

  @override
  String get tournamentAuditReasonLabel =>
      'Motivo administrativo de la modificación';

  @override
  String get tournamentAuditReasonHint =>
      'Ej. Resolución oficial del comité disciplinario';

  @override
  String get tournamentAuditConfirmAction => 'Confirmar cambio y recalcular';

  @override
  String get tournamentExitDialogTitle =>
      '¿Deseas descartar los cambios o guardar como borrador?';

  @override
  String get tournamentExitDialogMessage =>
      'Tienes configuraciones de campeonato sin publicar. Puedes guardar un borrador local para continuar más tarde o descartar los cambios.';

  @override
  String get tournamentSaveDraftAction => 'Guardar borrador';

  @override
  String get tournamentDiscardChangesAction => 'Descartar cambios';

  @override
  String get tournamentContinueEditingAction => 'Seguir editando';

  @override
  String get tournamentErrorInvalidName =>
      'El nombre del campeonato debe tener al menos 3 caracteres';

  @override
  String get tournamentErrorInvalidCategory =>
      'Debes ingresar una categoría válida';

  @override
  String get tournamentErrorInvalidDates =>
      'La fecha de finalización no puede ser anterior a la fecha de inicio';

  @override
  String get tournamentErrorInvalidPoints =>
      'Los puntos deben cumplir: Victoria > Empate >= Derrota >= 0';

  @override
  String get tournamentErrorInvalidYellowCards =>
      'El límite de tarjetas amarillas debe estar entre 2 y 10';

  @override
  String get tournamentErrorInvalidSquadSize =>
      'El cupo de jugadores debe cumplir: 5 <= Mínimo <= Máximo <= 35';

  @override
  String get tournamentErrorInvalidHalfDuration =>
      'La duración por tiempo debe estar entre 10 y 60 minutos';

  @override
  String get tournamentErrorInvalidGroupStage =>
      'Configura entre 2 y 8 grupos y entre 1 y 4 clasificados por grupo';

  @override
  String get tournamentErrorAuditReasonRequired =>
      'Debes ingresar un motivo administrativo válido para auditar el cambio';
}
