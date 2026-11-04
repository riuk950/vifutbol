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

  @override
  String get teamEligibilityPendingQuota => 'Pendiente de Cupo';

  @override
  String get teamEligibilityReadyForApproval => 'Listo para Habilitar';

  @override
  String get teamEligibilityEligible => 'Habilitado';

  @override
  String get playerPositionGoalkeeper => 'Portero';

  @override
  String get playerPositionDefender => 'Defensa';

  @override
  String get playerPositionMidfielder => 'Mediocampista';

  @override
  String get playerPositionForward => 'Delantero';

  @override
  String get playerPositionShortGoalkeeper => 'POR';

  @override
  String get playerPositionShortDefender => 'DEF';

  @override
  String get playerPositionShortMidfielder => 'MED';

  @override
  String get playerPositionShortForward => 'DEL';

  @override
  String get crestShapeShield => 'Escudo Clásico';

  @override
  String get crestShapeCircle => 'Circular';

  @override
  String get crestShapeDiamond => 'Rombo';

  @override
  String get crestShapeHexagon => 'Hexágono';

  @override
  String get teamsSectionTitle => 'Equipos Inscritos';

  @override
  String get teamsSectionSubtitle =>
      'Equipos habilitados para competir y gestión de plantillas';

  @override
  String get teamsRegisterAction => 'Inscribir Equipo';

  @override
  String teamsCountSummary(int eligibleCount, int totalCount) {
    return '$eligibleCount de $totalCount habilitados';
  }

  @override
  String get teamsEmptyTitle => 'Sin equipos inscritos';

  @override
  String get teamsEmptySubtitle =>
      'Inscribe el primer equipo para comenzar a registrar jugadores en este campeonato.';

  @override
  String teamsQuotaProgress(int current, int min, int max) {
    return '$current / $min a $max jugadores';
  }

  @override
  String get teamRosterTitle => 'Plantilla Oficial';

  @override
  String get teamRosterSubtitle =>
      'Gestión de jugadores y habilitación reglamentaria';

  @override
  String get teamEnrollPlayerAction => 'Inscribir Jugador';

  @override
  String get teamApproveEligibilityAction => 'Habilitar Equipo';

  @override
  String get teamEligibilityApprovedSuccess =>
      'El equipo ha sido habilitado oficialmente para el campeonato';

  @override
  String get teamRosterEmpty =>
      'No hay jugadores inscritos en este equipo aún.';

  @override
  String get teamFormNameLabel => 'Nombre del equipo';

  @override
  String get teamFormNameHint => 'Ej. Atlético Norte FC';

  @override
  String get teamFormShortCodeLabel => 'Sigla o Monograma (2 a 4 caracteres)';

  @override
  String get teamFormShortCodeHint => 'Ej. ATN';

  @override
  String get teamFormCrestShapeLabel => 'Forma del emblema';

  @override
  String get teamFormPrimaryColorLabel => 'Color primario';

  @override
  String get teamFormSecondaryColorLabel => 'Color secundario';

  @override
  String get teamFormSubmitCreate => 'Inscribir equipo';

  @override
  String get teamFormSubmitEdit => 'Guardar cambios';

  @override
  String get playerFormFullNameLabel => 'Nombre completo del jugador';

  @override
  String get playerFormFullNameHint => 'Ej. Carlos Andrés Rodríguez';

  @override
  String get playerFormDocumentLabel => 'Documento de identidad';

  @override
  String get playerFormDocumentHint => 'Ej. 10203040';

  @override
  String get playerFormPositionLabel => 'Posición en el campo';

  @override
  String get playerFormShirtNumberLabel => 'Número de camiseta (Dorsal)';

  @override
  String get playerFormShirtNumberHint => '1 - 99';

  @override
  String get playerFormSubmitEnroll => 'Inscribir jugador';

  @override
  String get playerFormSubmitEdit => 'Guardar jugador';

  @override
  String get playerRemoveConfirmTitle => '¿Eliminar jugador de la plantilla?';

  @override
  String playerRemoveConfirmMessage(String name) {
    return '¿Estás seguro de que deseas retirar a $name de este equipo?';
  }

  @override
  String get playerRemoveAction => 'Retirar jugador';

  @override
  String teamErrorDuplicateShirtNumber(int number) {
    return 'El número de camiseta $number ya está en uso en este equipo.';
  }

  @override
  String get teamErrorPlayerAlreadyRegisteredInTournament =>
      'Este jugador ya se encuentra inscrito en otro equipo de este campeonato.';

  @override
  String get teamErrorDuplicateTeamName =>
      'Ya existe un equipo con este nombre en este campeonato';

  @override
  String get teamErrorRegistrationsClosed =>
      'Las inscripciones de este campeonato están cerradas';

  @override
  String get teamErrorMaxPlayersQuotaReached =>
      'El equipo ya alcanzó el cupo máximo de jugadores permitido';

  @override
  String get teamErrorInsufficientPlayersForApproval =>
      'El equipo aún no alcanza el mínimo reglamentario de jugadores requerido por el campeonato';

  @override
  String get teamErrorInvalidTeamName =>
      'El nombre del equipo debe tener al menos 3 caracteres';

  @override
  String get teamErrorInvalidShortCode =>
      'La sigla debe tener entre 2 y 4 caracteres';

  @override
  String get teamErrorInvalidPlayerName =>
      'El nombre del jugador debe tener al menos 3 caracteres';

  @override
  String get teamErrorInvalidDocumentId =>
      'El documento de identidad debe tener al menos 5 caracteres';

  @override
  String get teamErrorInvalidShirtNumber =>
      'El número de camiseta debe estar entre 1 y 99';

  @override
  String get lineupScreenTitle => 'Convocatoria y Seguimiento';

  @override
  String get lineupTabConvocation => 'Convocatoria';

  @override
  String get lineupTabTracking => 'Seguimiento Interno';

  @override
  String get lineupTabRefereeRoster => 'Acta Arbitral';

  @override
  String get lineupStartersHeader => 'Titulares en Cancha';

  @override
  String get lineupSubstitutesHeader => 'Suplentes Habilitados';

  @override
  String get lineupNotConvokedHeader => 'No Convocados';

  @override
  String get lineupRoleStarter => 'Titular';

  @override
  String get lineupRoleSubstitute => 'Suplente';

  @override
  String get lineupRoleNotConvoked => 'No convocado';

  @override
  String get lineupCaptainBadge => 'Capitán';

  @override
  String get lineupSetCaptainAction => 'Hacer Capitán';

  @override
  String get lineupStatusDraft => 'Borrador sin Confirmar';

  @override
  String get lineupStatusConfirmed => 'Oficial Confirmada';

  @override
  String get lineupConfirmAction => 'Confirmar Convocatoria Oficial';

  @override
  String get lineupReconfirmAction => 'Actualizar y Reconfirmar Convocatoria';

  @override
  String get lineupSuccessConfirmation =>
      'Alineación oficial confirmada y sincronizada con el acta arbitral';

  @override
  String get lineupDraftSavedMessage =>
      'Borrador de convocatoria guardado automáticamente';

  @override
  String lineupDisciplinarySuspended(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'fechas',
      one: 'fecha',
    );
    return 'Suspendido ($count $_temp0)';
  }

  @override
  String lineupDisciplinaryWarning(int count) {
    return 'En capilla ($count TA)';
  }

  @override
  String get lineupDisciplinaryEligible => 'Habilitado';

  @override
  String lineupTrackingMatches(int count) {
    return 'Partidos: $count';
  }

  @override
  String lineupTrackingGoals(int count) {
    return 'Goles: $count';
  }

  @override
  String lineupTrackingAssists(int count) {
    return 'Asistencias: $count';
  }

  @override
  String lineupTrackingYellowCards(int count) {
    return 'Amarillas: $count';
  }

  @override
  String lineupTrackingRedCards(int count) {
    return 'Rojas: $count';
  }

  @override
  String lineupTrackingSuspensionPending(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'fechas',
      one: 'fecha',
    );
    return 'Sanción: $count $_temp0';
  }

  @override
  String get lineupTrackingEditAction => 'Actualizar Métricas';

  @override
  String get lineupTrackingSaveSuccess =>
      'Métricas de seguimiento actualizadas con éxito';

  @override
  String get lineupRefereeRosterTitle =>
      'Nómina Oficial Sincronizada (Acta Arbitral)';

  @override
  String get lineupRefereeRosterEmpty =>
      'El entrenador aún no ha confirmado la alineación oficial para este partido.';

  @override
  String get lineupOpenAction => 'Gestionar Convocatoria y Seguimiento';

  @override
  String lineupErrorStartersCount(int required, int selected) {
    return 'Debes seleccionar exactamente $required titulares (actual: $selected).';
  }

  @override
  String get lineupErrorMissingCaptain =>
      'Debes designar un capitán dentro de los jugadores titulares.';

  @override
  String lineupErrorSuspendedPlayer(String name, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'fechas',
      one: 'fecha',
    );
    return 'No puedes convocar al jugador $name porque se encuentra suspendido ($count $_temp0).';
  }

  @override
  String get lineupErrorTeamNotEligible =>
      'El equipo debe estar oficialmente Habilitado para confirmar una alineación oficial.';

  @override
  String get lineupErrorUnauthorized =>
      'No tienes permisos para gestionar la convocatoria de este equipo.';

  @override
  String matchdayRoundChip(int number) {
    return 'Jornada $number';
  }

  @override
  String get matchdayFilterAll => 'Todos';

  @override
  String get matchdayFilterPending => 'Pendiente';

  @override
  String get matchdayFilterScheduled => 'Programado';

  @override
  String get matchdayFilterCompleted => 'Finalizado';

  @override
  String get matchdayFilterTeamAll => 'Todos los equipos';

  @override
  String get matchdayGenerateFixtureButton => 'Generar Fixture';

  @override
  String get matchdayGenerateFixtureDialogTitle => 'Generar Fixture Oficial';

  @override
  String get matchdayGenerateFixtureDialogMessage =>
      '¿Deseas generar automáticamente el fixture de partidos para este campeonato? Se crearán todas las jornadas correspondientes a los equipos habilitados.';

  @override
  String get matchdayGenerateFixtureConfirmButton => 'Generar Calendario';

  @override
  String get matchdayGenerateFixtureCancelButton => 'Cancelar';

  @override
  String matchdayFixtureGeneratedSuccess(int count) {
    return 'Fixture generado exitosamente ($count partidos creados).';
  }

  @override
  String get matchdayEmptyFixtureTitle => 'No hay partidos en el fixture';

  @override
  String get matchdayEmptyFixtureSubtitle =>
      'Aún no se ha generado el calendario de partidos para este campeonato.';

  @override
  String get matchdayNoMatchesFiltered =>
      'No hay partidos que coincidan con los filtros seleccionados.';

  @override
  String get matchStatusPending => 'Pendiente de Programación';

  @override
  String get matchStatusScheduled => 'Programado';

  @override
  String get matchStatusInProgress => 'En Juego';

  @override
  String get matchStatusCompleted => 'Finalizado';

  @override
  String get matchStatusCancelled => 'Cancelado';

  @override
  String get scheduleMatchAction => 'Programar Partido';

  @override
  String get scheduleMatchDialogTitle => 'Programar Partido';

  @override
  String get scheduleMatchDateLabel => 'Fecha del Partido';

  @override
  String get scheduleMatchTimeLabel => 'Hora de Inicio';

  @override
  String get scheduleMatchVenueLabel => 'Sede Deportiva';

  @override
  String get scheduleMatchPitchLabel => 'Cancha';

  @override
  String get scheduleMatchRefereeLabel => 'Árbitro Oficial';

  @override
  String get scheduleMatchSelectVenuePrompt => 'Selecciona una sede';

  @override
  String get scheduleMatchSelectPitchPrompt => 'Selecciona una cancha';

  @override
  String get scheduleMatchSelectRefereePrompt => 'Selecciona un árbitro';

  @override
  String get scheduleMatchSaveButton => 'Confirmar Programación';

  @override
  String get scheduleMatchSuccessMessage => 'Partido programado exitosamente.';

  @override
  String get scheduleCollisionPitchTitle => 'Conflicto de Cancha';

  @override
  String get scheduleCollisionRefereeTitle => 'Conflicto de Árbitro';

  @override
  String get scheduleCollisionTeamTitle => 'Conflicto de Equipo';

  @override
  String scheduleCollisionPitchMessage(
    String pitchName,
    String startTime,
    String endTime,
  ) {
    return 'La cancha $pitchName ya se encuentra ocupada en el horario seleccionado ($startTime - $endTime).';
  }

  @override
  String scheduleCollisionRefereeMessage(
    String refereeName,
    String startTime,
    String endTime,
  ) {
    return 'El árbitro $refereeName ya tiene otro partido designado en ese horario ($startTime - $endTime).';
  }

  @override
  String scheduleCollisionTeamMessage(
    String teamName,
    String startTime,
    String endTime,
  ) {
    return 'El equipo $teamName ya tiene otro partido programado en ese horario ($startTime - $endTime).';
  }

  @override
  String get fixtureErrorUnauthorized =>
      'No tienes permisos de organizador para generar o programar partidos.';

  @override
  String get fixtureErrorInsufficientTeams =>
      'Se requieren al menos 2 equipos habilitados para generar el fixture.';

  @override
  String get fixtureErrorRegenerationBlocked =>
      'No se puede regenerar el fixture porque ya existen partidos en juego o finalizados.';

  @override
  String get fixtureErrorInvalidTimes =>
      'La hora de inicio o duración del partido no son válidas.';

  @override
  String get matchReportTitle => 'Acta Digital del Árbitro';

  @override
  String get matchReportHeaderTitle => 'Acta del Partido';

  @override
  String get matchPeriodNotStarted => 'Por Iniciar';

  @override
  String get matchPeriodFirstHalf => 'Primer Tiempo';

  @override
  String get matchPeriodHalfTime => 'Descanso';

  @override
  String get matchPeriodSecondHalf => 'Segundo Tiempo';

  @override
  String get matchPeriodFullTime => 'Tiempo Cumplido';

  @override
  String get matchPeriodClosed => 'Acta Cerrada';

  @override
  String get matchStatusLiveBadge => 'EN JUEGO';

  @override
  String get matchStatusFinishedBadge => 'FINALIZADO';

  @override
  String get matchActionStartMatch => 'Iniciar Partido';

  @override
  String get matchActionEndFirstHalf => 'Fin 1er Tiempo';

  @override
  String get matchActionStartSecondHalf => 'Iniciar 2do Tiempo';

  @override
  String get matchActionEndSecondHalf => 'Tiempo Cumplido';

  @override
  String get matchActionRecordGoal => 'Registrar Gol';

  @override
  String get matchActionRecordYellowCard => 'Tarjeta Amarilla';

  @override
  String get matchActionRecordRedCard => 'Tarjeta Roja';

  @override
  String get matchActionRecordSubstitution => 'Sustitución';

  @override
  String get matchActionCloseReport => 'Cerrar Acta Oficial';

  @override
  String get matchActionOpenRefereeReport => 'Acta Arbitral';

  @override
  String get matchActionViewReport => 'Ver Acta';

  @override
  String get matchReportOfflineBanner =>
      'Modo sin conexión: cambios guardados en el dispositivo';

  @override
  String get matchReportOnlineStatus => 'En línea';

  @override
  String get matchReportOfflineStatus => 'Sin conexión';

  @override
  String matchReportPendingSyncCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count cambios pendientes de sincronización',
      one: '1 cambio pendiente de sincronización',
    );
    return '$_temp0';
  }

  @override
  String get matchReportSyncingEvents => 'Sincronizando eventos...';

  @override
  String get matchReportAllEventsSynced => 'Todos los eventos sincronizados';

  @override
  String get recordGoalDialogTitle => 'Registrar Gol';

  @override
  String get recordGoalTeamLabel => 'Equipo anotador';

  @override
  String get recordGoalMinuteLabel => 'Minuto del gol';

  @override
  String get recordGoalScorerLabel => 'Jugador anotador';

  @override
  String get recordGoalAssistantLabel => 'Jugador asistente (opcional)';

  @override
  String get recordGoalNoAssistantOption => 'Sin asistencia';

  @override
  String get recordGoalConfirmAction => 'Confirmar Gol';

  @override
  String get recordCardDialogTitle => 'Registrar Tarjeta Disciplinaria';

  @override
  String get recordCardYellowTitle => 'Tarjeta Amarilla';

  @override
  String get recordCardRedTitle => 'Tarjeta Roja Directa';

  @override
  String get recordCardPlayerLabel => 'Jugador amonestado / sancionado';

  @override
  String get recordCardConfirmAction => 'Confirmar Tarjeta';

  @override
  String get recordCardSecondYellowExpulsion =>
      'Segunda Amarilla (Expulsión Automática)';

  @override
  String get recordSubstitutionDialogTitle => 'Registrar Sustitución';

  @override
  String get recordSubstitutionPlayerOutLabel => 'Jugador que sale';

  @override
  String get recordSubstitutionPlayerInLabel => 'Jugador que entra';

  @override
  String get recordSubstitutionConfirmAction => 'Confirmar Sustitución';

  @override
  String get matchEventUndoAction => 'Anular';

  @override
  String get matchEventUndoConfirmTitle => '¿Anular incidencia del acta?';

  @override
  String get matchEventUndoConfirmMessage =>
      'Se recalculará el marcador y el estado de sanciones del partido.';

  @override
  String get matchEventUndoConfirmButton => 'Anular Incidencia';

  @override
  String get closeReportDialogTitle => 'Cierre Definitivo del Acta Oficial';

  @override
  String get closeReportSummaryTitle => 'Resumen Oficial del Encuentro';

  @override
  String closeReportFinalScore(String score) {
    return 'Marcador Final: $score';
  }

  @override
  String get closeReportWarningMessage =>
      '¿Confirmas el cierre definitivo del acta? Esta acción es irreversible y bloqueará cualquier modificación posterior.';

  @override
  String get closeReportConfirmButton => 'Confirmar y Cerrar Acta';

  @override
  String get matchTimelineTitle => 'Línea de Tiempo';

  @override
  String get matchTimelineEmpty =>
      'No hay incidencias registradas aún en el partido.';

  @override
  String matchEventGoalDescription(String player) {
    return 'Gol de $player';
  }

  @override
  String matchEventAssistantDescription(String player) {
    return 'Asistencia: $player';
  }

  @override
  String matchEventYellowCardDescription(String player) {
    return 'Tarjeta Amarilla - $player';
  }

  @override
  String matchEventSecondYellowRedDescription(String player) {
    return 'Segunda Amarilla y Expulsión - $player';
  }

  @override
  String matchEventDirectRedDescription(String player) {
    return 'Tarjeta Roja Directa - $player';
  }

  @override
  String matchEventSubstitutionDescription(String playerOut, String playerIn) {
    return 'Sale $playerOut, entra $playerIn';
  }

  @override
  String matchEventPeriodTransitionDescription(String period) {
    return 'Inicio de $period';
  }

  @override
  String get matchReportErrorUnauthorized =>
      'No tienes permisos de árbitro u organizador para dirigir este partido.';

  @override
  String get matchReportErrorAlreadyClosed =>
      'El acta oficial ya ha sido cerrada y no puede ser modificada.';

  @override
  String get matchReportErrorNotInProgress =>
      'El partido debe estar en juego para registrar incidencias.';

  @override
  String get matchReportErrorInvalidMinute =>
      'El minuto debe estar entre 1 y 130.';

  @override
  String get matchReportErrorPlayerExpelled =>
      'El jugador ya fue expulsado y no puede realizar nuevas acciones en el partido.';

  @override
  String get matchReportErrorInvalidAssistant =>
      'El jugador asistente no puede ser el mismo anotador ni pertenecer al equipo contrario.';

  @override
  String get matchReportErrorInvalidSubstitution =>
      'El jugador que sale y el que entra deben ser diferentes y no estar expulsados.';

  @override
  String get competitiveViewStandings => 'Posiciones';

  @override
  String get competitiveViewBrackets => 'Llaves';

  @override
  String get competitiveViewRankings => 'Rankings';

  @override
  String get standingsTableTitle => 'Tabla de Posiciones Oficial';

  @override
  String get standingsTableSubtitle =>
      'Clasificación determinista calculada a partir de actas oficiales cerradas';

  @override
  String get standingsColPos => 'POS';

  @override
  String get standingsColTeam => 'EQUIPO';

  @override
  String get standingsColPlayed => 'PJ';

  @override
  String get standingsColWon => 'PG';

  @override
  String get standingsColDrawn => 'PE';

  @override
  String get standingsColLost => 'PP';

  @override
  String get standingsColGoalsFor => 'GF';

  @override
  String get standingsColGoalsAgainst => 'GC';

  @override
  String get standingsColGoalDifference => 'DG';

  @override
  String get standingsColPoints => 'PTS';

  @override
  String get standingsColFairPlay => 'FP';

  @override
  String get standingsEmptyTeams =>
      'Aún no hay equipos habilitados en la tabla de posiciones.';

  @override
  String standingsCompletedMatchesBadge(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count actas cerradas',
      one: '1 acta cerrada',
      zero: 'Sin partidos finalizados',
    );
    return '$_temp0';
  }

  @override
  String standingsTiebreakerCaption(String criteria) {
    return 'Desempate activo: $criteria';
  }

  @override
  String get standingsQualificationZoneLabel => 'Zona de clasificación / podio';

  @override
  String get standingsTechnicalTieBadge => 'Empate técnico';

  @override
  String get knockoutBracketTitle => 'Cuadro de Llaves Eliminatorias';

  @override
  String get knockoutBracketSubtitle =>
      'Avance automático de ganadores tras cierre de acta oficial';

  @override
  String get knockoutViewModeByRound => 'Por Rondas';

  @override
  String get knockoutViewModePanoramic => 'Visor 2D';

  @override
  String get knockoutTbdTeam => 'Por definir';

  @override
  String knockoutPenaltyShootoutBadge(int homePen, int awayPen) {
    return 'Penales: $homePen - $awayPen';
  }

  @override
  String knockoutWinnerAdvancesBadge(String team) {
    return 'Clasifica: $team';
  }

  @override
  String knockoutChampionBannerTitle(String team) {
    return 'Campeón Oficial: $team';
  }

  @override
  String get rankingsSectionTitle => 'Rankings y Estadísticas Deportivas';

  @override
  String get rankingsSectionSubtitle =>
      'Líderes individuales y tabla disciplinaria Fair Play';

  @override
  String get rankingsCategoryScorers => 'Goleadores';

  @override
  String get rankingsCategoryAssists => 'Asistencias';

  @override
  String get rankingsCategoryFairPlay => 'Fair Play';

  @override
  String get rankingsEmptyScorers =>
      'Aún no se han registrado goles en actas oficiales cerradas.';

  @override
  String get rankingsEmptyAssists =>
      'Aún no se han registrado asistencias en actas oficiales cerradas.';

  @override
  String get rankingsEmptyFairPlay =>
      'Aún no hay equipos evaluados en la clasificación Fair Play.';

  @override
  String rankingsGoalsUnit(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count goles',
      one: '1 gol',
    );
    return '$_temp0';
  }

  @override
  String rankingsAssistsUnit(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count asist.',
      one: '1 asist.',
    );
    return '$_temp0';
  }

  @override
  String rankingsFairPlayPointsUnit(int points) {
    return '$points pts FP';
  }

  @override
  String get rankingsFairPlayLegend =>
      'Ponderación oficial: Amarilla (-1 pt) · Doble Amarilla/Roja (-3 pts) · Roja Directa (-3 pts)';

  @override
  String get playerProfileTitle => 'Perfil de Rendimiento';

  @override
  String get playerProfileSubtitle =>
      'Estadísticas oficiales consolidadas del torneo';

  @override
  String get playerProfileMyProfileButton => 'Mi Perfil Deportivo';

  @override
  String get playerDisciplinaryStatusEnabled => 'Habilitado';

  @override
  String get playerDisciplinaryStatusSuspended => 'Suspendido';

  @override
  String get playerMetricMatchesPlayed => 'Partidos';

  @override
  String get playerMetricStarts => 'Titularidades';

  @override
  String get playerMetricGoals => 'Goles';

  @override
  String get playerMetricAssists => 'Asistencias';

  @override
  String get playerMetricGoalAverage => 'Promedio de Gol';

  @override
  String get playerMetricYellowCards => 'Tarjetas Amarillas';

  @override
  String get playerMetricRedCards => 'Tarjetas Rojas';

  @override
  String get playerMatchBreakdownTitle => 'Historial Partido por Partido';

  @override
  String get playerEmptyParticipationsMessage =>
      'Aún no registras participaciones en partidos oficiales de este torneo.';

  @override
  String get playerStarterBadge => 'Titular';

  @override
  String get playerSubstituteBadge => 'Suplente';

  @override
  String get teamDetailedStatsTitle => 'Ficha del Equipo';

  @override
  String get teamRecentFormTitle => 'Racha Reciente';

  @override
  String get teamRecentFormEmpty =>
      'Aún no hay partidos finalizados para calcular la racha.';

  @override
  String get teamCompletedMatchesTitle => 'Historial de Resultados';

  @override
  String get teamCompletedMatchesEmpty =>
      'No hay resultados oficiales registrados aún.';

  @override
  String get teamUpcomingMatchesTitle => 'Próximos Encuentros';

  @override
  String get teamUpcomingMatchesEmpty =>
      'No hay próximos partidos programados.';

  @override
  String get teamSquadStatsTitle => 'Plantel y Aporte Individual';

  @override
  String get teamSquadStatsEmpty =>
      'No hay jugadores inscritos en este equipo.';

  @override
  String get teamFormResultWin => 'V';

  @override
  String get teamFormResultDraw => 'E';

  @override
  String get teamFormResultLoss => 'D';
}
