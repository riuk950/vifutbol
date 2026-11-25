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
  String get tabMatchday => 'Partidos';

  @override
  String get tabMatches => 'Partidos';

  @override
  String get tabStandings => 'Explorar';

  @override
  String get tabExplore => 'Explorar';

  @override
  String get tabVenues => 'Sedes';

  @override
  String get tabNews => 'Noticias';

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
  String get matchdayDateToday => 'Hoy';

  @override
  String get matchdayDateTomorrow => 'Mañana';

  @override
  String matchdayUnscheduledSectionTitle(int count) {
    return 'Por programar ($count)';
  }

  @override
  String get matchdayNoMatchesForDate =>
      'No hay partidos programados para esta fecha.';

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
  String get scheduleMatchPastDateTimeError =>
      'No puedes programar un partido en una fecha u hora pasada.';

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

  @override
  String get segmentedMatches => 'Partidos';

  @override
  String get segmentedNews => 'Noticias';

  @override
  String get matchLiveBadge => 'EN VIVO';

  @override
  String get matchLiveSectionTitle => 'Partidos en Juego';

  @override
  String matchLiveMinute(int minute) {
    return 'Minuto $minute\'';
  }

  @override
  String matchLivePeriod(String period) {
    return 'Periodo: $period';
  }

  @override
  String get matchLiveOfflineBanner => 'Modo sin conexión - Marcador en caché';

  @override
  String get newsFeedTitle => 'Comunicados y Noticias Oficiales';

  @override
  String get newsCategoryAll => 'Todas';

  @override
  String get newsCategoryGeneral => 'Avisos Generales';

  @override
  String get newsCategoryDisciplinary => 'Boletines Disciplinarios';

  @override
  String get newsCategoryRescheduling => 'Reprogramaciones';

  @override
  String get newsFeedEmpty =>
      'No hay noticias ni comunicados oficiales publicados para este torneo.';

  @override
  String get newsCreateButton => 'Nueva Noticia';

  @override
  String get newsCreateDialogTitle => 'Publicar Noticia Oficial';

  @override
  String get newsTitleField => 'Título del Comunicado';

  @override
  String get newsTitleValidation =>
      'El título debe tener entre 3 y 120 caracteres';

  @override
  String get newsBodyField => 'Contenido del Comunicado';

  @override
  String get newsBodyValidation =>
      'El contenido debe tener entre 5 y 3000 caracteres';

  @override
  String get newsCategoryField => 'Categoría';

  @override
  String get newsPinnedField => 'Fijar en la parte superior';

  @override
  String get newsPublishSubmit => 'Publicar Comunicado';

  @override
  String get newsDeleteConfirmTitle => '¿Eliminar comunicado?';

  @override
  String get newsDeleteConfirmMessage =>
      'Esta acción eliminará permanentemente la noticia oficial seleccionada.';

  @override
  String get newsDeletedSuccess => 'Comunicado eliminado correctamente';

  @override
  String get newsPublishedSuccess => 'Comunicado publicado con éxito';

  @override
  String favoriteTeamAdded(String teamName) {
    return '$teamName añadido a tus equipos favoritos';
  }

  @override
  String favoriteTeamRemoved(String teamName) {
    return '$teamName eliminado de tus favoritos';
  }

  @override
  String get favoriteToggleTooltip => 'Marcar como equipo favorito';

  @override
  String favoriteNotificationsEnabled(String teamName) {
    return 'Alertas activadas para $teamName';
  }

  @override
  String favoriteNotificationsDisabled(String teamName) {
    return 'Alertas desactivadas para $teamName';
  }

  @override
  String get alertsTrayTitle => 'Bandeja de Alertas';

  @override
  String get alertsTrayEmpty =>
      'No tienes alertas o notificaciones pendientes.';

  @override
  String get alertsMarkAllRead => 'Marcar todo como leído';

  @override
  String alertsUnreadBadgeTooltip(int count) {
    return '$count alertas no leídas';
  }

  @override
  String get alertsPushDeniedWarning =>
      'Notificaciones del sistema desactivadas. Puedes consultar todas las alertas en esta bandeja.';

  @override
  String get alertTypeUpcoming => 'Próximo Partido';

  @override
  String get alertTypeStarted => 'Partido Iniciado';

  @override
  String get alertTypeGoal => '¡Gol!';

  @override
  String get alertTypeEnded => 'Resultado Final';

  @override
  String get alertTypeNews => 'Nuevo Comunicado';

  @override
  String get backupModalTitle => 'Respaldo del Campeonato';

  @override
  String get backupExportTab => 'Exportar';

  @override
  String get backupImportTab => 'Importar';

  @override
  String get backupExportButton => 'Exportar respaldo';

  @override
  String get backupCopyJsonAction => 'Copiar paquete de respaldo';

  @override
  String get backupCopySuccess =>
      'Copia de respaldo copiada al portapapeles con éxito';

  @override
  String backupSummaryTeams(int count) {
    return '$count equipos inscritos';
  }

  @override
  String backupSummaryPlayers(int count) {
    return '$count jugadores registrados';
  }

  @override
  String backupSummaryMatches(int count) {
    return '$count partidos programados';
  }

  @override
  String backupSummaryReports(int count) {
    return '$count actas oficiales';
  }

  @override
  String backupSummaryNews(int count) {
    return '$count comunicados oficiales';
  }

  @override
  String get backupImportInputLabel => 'Contenido JSON del respaldo';

  @override
  String get backupImportInputHint =>
      'Pega aquí el contenido JSON del archivo de respaldo...';

  @override
  String get backupValidateAction => 'Validar respaldo';

  @override
  String get backupRestoreAction => 'Restaurar campeonato';

  @override
  String get backupInvalidMessage =>
      'El archivo de respaldo no es válido o está incompleto. No se realizaron cambios.';

  @override
  String get backupTwoStepCheckbox =>
      'Confirmo que deseo sobrescribir los datos de este campeonato con el respaldo seleccionado.';

  @override
  String get backupRestoreSuccess =>
      'El campeonato fue restaurado con éxito desde el respaldo.';

  @override
  String get backupActionButton => 'Respaldo del torneo';

  @override
  String get seasonClosureAction => 'Finalizar Campeonato';

  @override
  String get seasonClosureDialogTitle => 'Cierre Oficial de Temporada';

  @override
  String get seasonClosurePendingMatchesError =>
      'Todos los partidos obligatorios deben estar finalizados antes de cerrar el campeonato.';

  @override
  String get seasonClosureTwoStepCheckbox =>
      'Confirmo que deseo proclamar a los campeones y cerrar la temporada en modo histórico permanente.';

  @override
  String get seasonClosureConfirmAction => 'Confirmar Cierre Oficial';

  @override
  String get seasonClosureSuccess =>
      '¡Temporada finalizada! El Cuadro de Honor oficial ha sido publicado.';

  @override
  String get seasonReadOnlyBadge => 'Temporada Finalizada · Consulta Histórica';

  @override
  String get honorRollTitle => 'Cuadro de Honor Oficial';

  @override
  String get honorRollChampion => 'Campeón Oficial';

  @override
  String get honorRollRunnerUp => 'Subcampeón';

  @override
  String get honorRollTopScorer => 'Máximo Goleador';

  @override
  String get honorRollBestDefense => 'Valla Menos Vencida';

  @override
  String honorRollGoalsCount(int count) {
    return '$count goles';
  }

  @override
  String honorRollGoalsAgainstCount(int count) {
    return '$count goles recibidos';
  }

  @override
  String get honorRollNoGoals => 'Sin goles registrados';

  @override
  String get drawerTitle => 'Menú Principal';

  @override
  String get drawerGuestUser => 'Aficionado Invitado';

  @override
  String get drawerGuestEmail => 'Sesión deportiva local';

  @override
  String get drawerCompetitions => 'Competiciones';

  @override
  String get drawerTeams => 'Equipos';

  @override
  String get drawerPlayers => 'Jugadores';

  @override
  String get drawerVenues => 'Sedes';

  @override
  String get searchCompetitionsHint => 'Buscar competiciones...';

  @override
  String get searchTeamsHint => 'Buscar equipos...';

  @override
  String get searchPlayersHint => 'Buscar jugadores...';

  @override
  String get filterAllTournaments => 'Todos';

  @override
  String get noCompetitionsFound =>
      'No se encontraron competiciones con ese criterio.';

  @override
  String get noTeamsFound => 'No se encontraron equipos con ese criterio.';

  @override
  String get noPlayersFound => 'No se encontraron jugadores con ese criterio.';

  @override
  String get createCompetitionAction => 'Crear competición';

  @override
  String get registerTeamAction => 'Inscribir equipo';

  @override
  String get registerPlayerAction => 'Registrar jugador';

  @override
  String get clearSearchAction => 'Limpiar búsqueda';

  @override
  String get tabYesterday => 'Ayer';

  @override
  String get tabToday => 'Hoy';

  @override
  String get tabTomorrow => 'Mañana';

  @override
  String get calendarPickerTooltip => 'Seleccionar fecha del calendario';

  @override
  String get emptyMatchesForDate =>
      'No hay partidos programados para esta fecha';

  @override
  String get emptyMatchesSuggestion =>
      'Prueba seleccionando otro día o consulta el calendario completo.';

  @override
  String get liveMatchBadge => 'EN VIVO';

  @override
  String get finalMatchBadge => 'Final';

  @override
  String get cancelledMatchBadge => 'Cancelado';

  @override
  String organizerPendingMatchesAlert(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count partidos pendientes de programar',
      one: '1 partido pendiente de programar',
    );
    return '$_temp0';
  }

  @override
  String get organizerPendingMatchesAction => 'Programar partidos';

  @override
  String get drawerPanel => 'Panel';

  @override
  String get panelPlaceholderTitle => 'Panel de Control Operativo';

  @override
  String get panelPlaceholderSubtitle =>
      'Herramientas de gestión y métricas disponibles para tu rol deportivo.';

  @override
  String get panelTitleOrganizer => 'Panel de Organización';

  @override
  String get panelTitleCoach => 'Panel Técnico';

  @override
  String get panelTitleReferee => 'Panel Arbitral';

  @override
  String get panelTitlePlayer => 'Ficha del Jugador';

  @override
  String get organizerSummaryTitle => 'Resumen General';

  @override
  String get organizerMetricActiveTournaments => 'Torneos en Curso';

  @override
  String get organizerMetricPendingMatches => 'Partidos por Programar';

  @override
  String get organizerMetricUnseededTournaments => 'Torneos sin Fixture';

  @override
  String get organizerQuickActionsTitle => 'Acciones Rápidas';

  @override
  String get organizerActionGenerateFixture => 'Generar Fixture';

  @override
  String get organizerActionScheduleMatches => 'Programar Partido';

  @override
  String get organizerActionBackup => 'Copia de Seguridad';

  @override
  String get coachSummaryTitle => 'Estado del Equipo';

  @override
  String get coachMetricTotalPlayers => 'Plantilla Total';

  @override
  String get coachMetricEligiblePlayers => 'Habilitados';

  @override
  String get coachMetricSuspendedPlayers => 'Suspendidos';

  @override
  String get coachQuickActionsTitle => 'Acciones Técnicas';

  @override
  String get coachActionMatchLineup => 'Convocatoria para el Próximo Partido';

  @override
  String get coachActionManageRoster => 'Gestionar Plantilla';

  @override
  String get coachNextMatchTitle => 'Próximo Encuentro';

  @override
  String get coachNoUpcomingMatch => 'Sin partidos programados próximamente';

  @override
  String get refereeAssignedMatchesTitle => 'Partidos Asignados';

  @override
  String get refereeActionDigitalReport => 'Acta Digital';

  @override
  String get refereeEmptyMatchesTitle => 'Sin partidos asignados';

  @override
  String get refereeEmptyMatchesMessage =>
      'Actualmente no tienes partidos designados para dirigir.';

  @override
  String get playerStatusTitle => 'Estatus Deportivo';

  @override
  String get playerStatusEligible => 'Habilitado';

  @override
  String get playerStatusSuspended => 'Sancionado';

  @override
  String get playerStatsTitle => 'Estadísticas de Temporada';

  @override
  String get playerStatGoals => 'Goles';

  @override
  String get playerStatAssists => 'Asistencias';

  @override
  String get playerStatYellowCards => 'T. Amarillas';

  @override
  String get playerStatRedCards => 'T. Rojas';

  @override
  String get playerStatMatchesPlayed => 'Partidos';

  @override
  String get playerNextMatchTitle => 'Próximo Partido';

  @override
  String get playerNoUpcomingMatch => 'Sin partido programado próximamente';

  @override
  String get fanRestrictedTitle => 'Acceso Restringido';

  @override
  String get fanRestrictedMessage =>
      'El Panel Administrativo está reservado exclusivamente para Organizadores, Entrenadores, Árbitros y Jugadores federados.';

  @override
  String get fanRestrictedReturnAction => 'Volver a Partidos';

  @override
  String get competitionDetailTabMatches => 'Partidos';

  @override
  String get competitionDetailTabStandings => 'Clasificación';

  @override
  String get competitionDetailTabInfo => 'Información';

  @override
  String get fixtureEmptyMatchesTitle => 'Calendario en Preparación';

  @override
  String get fixtureEmptyMatchesMessage =>
      'Esta competición aún no tiene partidos programados en su calendario oficial.';

  @override
  String get fixturePendingScheduleBadge => 'Pendiente de programación';

  @override
  String fixtureRoundLabel(int roundNumber) {
    return 'Jornada $roundNumber';
  }

  @override
  String get competitionInfoTitle => 'Reglamento Oficial';

  @override
  String get competitionInfoMessage =>
      'El sistema oficial de puntuación, desempates y normas disciplinarias estará disponible próximamente.';

  @override
  String get competitionStandingsSubviewsTitle => 'Vista competitiva';

  @override
  String get competitionStandingsEmptyTitle => 'Sin Clasificación Disponible';

  @override
  String get competitionStandingsEmptyDescription =>
      'La tabla de posiciones se generará cuando se registren los primeros resultados oficiales.';

  @override
  String get competitionBracketsEmptyTitle => 'Sin Llaves Disponibles';

  @override
  String get competitionBracketsEmptyDescription =>
      'El cuadro eliminatorio se generará al definirse los cruces de la fase final.';

  @override
  String get competitionRankingsEmptyTitle => 'Sin Estadísticas Disponibles';

  @override
  String get competitionRankingsEmptyDescription =>
      'Los rankings de goleadores, tarjetas y vallas invictas se actualizarán con los eventos oficiales.';

  @override
  String get competitionMainVenueTitle => 'Sede Principal';

  @override
  String get competitionMainVenueAddress => 'Dirección';

  @override
  String competitionMainVenuePitches(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count canchas disponibles',
      one: '1 cancha disponible',
    );
    return '$_temp0';
  }

  @override
  String get competitionInfoNotFoundTitle => 'Competición No Encontrada';

  @override
  String get competitionInfoNotFoundDescription =>
      'No se pudo cargar la información reglamentaria del campeonato solicitado.';

  @override
  String get teamDetailTabInfo => 'Información';

  @override
  String get teamDetailTabMatches => 'Partidos';

  @override
  String get teamDetailTabSquad => 'Plantilla';

  @override
  String get teamDetailNotFoundTitle => 'Equipo no encontrado';

  @override
  String get teamDetailNotFoundMessage =>
      'No se encontró la información del equipo solicitado en el catálogo local.';

  @override
  String get teamDetailClubProfileTitle => 'Ficha del Club';

  @override
  String get teamDetailOfficialNameLabel => 'Nombre oficial';

  @override
  String get teamDetailShortCodeLabel => 'Código oficial';

  @override
  String get teamDetailCompetitionLabel => 'Competición';

  @override
  String get teamDetailClubColorsLabel => 'Colores distintivos';

  @override
  String get teamDetailPrimaryColorLabel => 'Primario';

  @override
  String get teamDetailSecondaryColorLabel => 'Secundario';

  @override
  String get teamDetailLastMatchTitle => 'Último Partido';

  @override
  String get teamDetailLastMatchEmpty => 'Sin partidos previos disputados';

  @override
  String get teamDetailNextMatchTitle => 'Próximo Partido';

  @override
  String get teamDetailNextMatchEmpty => 'Sin próximos partidos agendados';

  @override
  String get teamDetailOpponentLabel => 'Rival';

  @override
  String get teamDetailVenueLabel => 'Sede / Cancha';

  @override
  String get teamDetailDateLabel => 'Fecha y hora';

  @override
  String get teamDetailHomeConditionBadge => 'Local';

  @override
  String get teamDetailAwayConditionBadge => 'Visitante';

  @override
  String get teamDetailMatchesTabPlaceholderTitle => 'Calendario del Equipo';

  @override
  String get teamDetailMatchesTabPlaceholderMessage =>
      'El historial completo y calendario de próximos partidos del equipo estará disponible en esta sección.';

  @override
  String get teamDetailSquadTabPlaceholderTitle => 'Plantilla Oficial';

  @override
  String get teamDetailSquadTabPlaceholderMessage =>
      'La nómina completa de jugadores con sus dorsales y posiciones tácticas estará disponible en esta sección.';

  @override
  String get teamMatchesUpcomingSectionTitle => 'Próximos Partidos';

  @override
  String get teamMatchesCompletedSectionTitle => 'Resultados Anteriores';

  @override
  String get teamMatchesEmptyGlobalTitle => 'Sin partidos en el calendario';

  @override
  String get teamMatchesEmptyGlobalMessage =>
      'Este equipo aún no tiene encuentros programados ni resultados registrados en la competición.';

  @override
  String get teamMatchesUpcomingEmpty => 'Sin próximos partidos agendados';

  @override
  String get teamMatchesCompletedEmpty =>
      'Sin partidos finalizados registrados';

  @override
  String get teamMatchOutcomeWin => 'Victoria';

  @override
  String get teamMatchOutcomeDraw => 'Empate';

  @override
  String get teamMatchOutcomeLoss => 'Derrota';

  @override
  String get teamMatchDetailModalRefereeLabel => 'Árbitro designado';

  @override
  String get teamMatchDetailModalUnassignedReferee => 'Árbitro sin asignar';

  @override
  String get teamMatchDetailModalUnassignedVenue => 'Cancha por asignar';

  @override
  String get teamMatchDetailModalPendingSchedule => 'Horario pendiente';

  @override
  String get teamSquadGoalkeepersSectionTitle => 'Porteros';

  @override
  String get teamSquadDefendersSectionTitle => 'Defensas';

  @override
  String get teamSquadMidfieldersSectionTitle => 'Centrocampistas';

  @override
  String get teamSquadForwardsSectionTitle => 'Delanteros';

  @override
  String get teamSquadPositionGoalkeeper => 'Portero';

  @override
  String get teamSquadPositionDefender => 'Defensa';

  @override
  String get teamSquadPositionMidfielder => 'Centrocampista';

  @override
  String get teamSquadPositionForward => 'Delantero';

  @override
  String get teamSquadPlayerStatusEligible => 'Habilitado';

  @override
  String get teamSquadPlayerStatusSuspended => 'Suspendido';

  @override
  String get teamSquadEmptyGlobalTitle => 'Plantilla sin jugadores inscritos';

  @override
  String get teamSquadEmptyGlobalMessage =>
      'Este equipo aún no registra jugadores inscritos en su nómina oficial.';

  @override
  String get teamSquadEmptyPositionMessage =>
      'Sin jugadores registrados en esta posición';

  @override
  String get organizerActionPublishNews => 'Publicar Noticia';

  @override
  String get organizerNoEditableTournamentsForNews =>
      'No hay competiciones activas disponibles para publicar comunicados';

  @override
  String get newsTournamentField => 'Competición';

  @override
  String get newsFilterMenuTooltip => 'Filtrar noticias';

  @override
  String get newsFilterSheetTitle => 'Filtrar Noticias';

  @override
  String get newsFilterTournamentSectionTitle => 'Competición';

  @override
  String get newsFilterCategorySectionTitle => 'Categoría de Comunicado';

  @override
  String get newsFilterResetButton => 'Restablecer';

  @override
  String get newsActiveFilterClearSemantics => 'Quitar filtro de categoría';

  @override
  String get newsFeedEmptyCategoryFilter =>
      'No hay comunicados publicados en esta categoría para el torneo seleccionado.';

  @override
  String get competitionFabMenuTooltip => 'Acciones de competición';

  @override
  String get competitionFabGenerateFixtureLabel => 'Generar Fixture';

  @override
  String get selectTournamentForFixtureTitle => 'Generar Fixture';

  @override
  String get selectTournamentForFixtureSubtitle =>
      'Selecciona la competición activa para sortear sus jornadas y partidos.';

  @override
  String selectTournamentEligibleTeamsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count equipos habilitados',
      one: '1 equipo habilitado',
    );
    return '$_temp0';
  }

  @override
  String get organizerNoEditableTournamentsForFixture =>
      'No hay competiciones activas disponibles para generar fixture';

  @override
  String get fixtureMatchPendingLogistics => 'Por programar';

  @override
  String get matchdayScheduleSavedSuccess =>
      'Programación del partido guardada exitosamente.';

  @override
  String get competitionDetailTabTeams => 'Equipos';

  @override
  String get competitionFabAddTeamLabel => 'Agregar Equipo';

  @override
  String get competitionTeamsEmptyTitle => 'Sin equipos inscritos';

  @override
  String get competitionTeamsEmptyDescription =>
      'Aún no hay clubes registrados en esta competición. Usa el botón de acciones para inscribir equipos.';

  @override
  String competitionTeamsHeaderCount(int count) {
    return 'Equipos Inscritos ($count)';
  }

  @override
  String competitionTeamPlayersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count jugadores',
      one: '1 jugador',
    );
    return '$_temp0';
  }

  @override
  String get competitionTeamMoveGroupTooltip => 'Trasladar de grupo';

  @override
  String get competitionTeamRemoveTooltip => 'Quitar del campeonato';

  @override
  String get competitionMoveGroupDialogTitle => 'Trasladar de Grupo';

  @override
  String competitionMoveGroupSuccess(String teamName, String groupName) {
    return '$teamName trasladado a $groupName';
  }

  @override
  String get competitionRemoveTeamConfirmTitle =>
      'Quitar Equipo del Campeonato';

  @override
  String competitionRemoveTeamConfirmMessage(String teamName) {
    return '¿Estás seguro de que deseas retirar a $teamName de esta competición?';
  }

  @override
  String get competitionRemoveTeamConfirmAction => 'Quitar Equipo';

  @override
  String get competitionRemoveTeamSuccess => 'Equipo retirado del campeonato';

  @override
  String get competitionRemoveTeamHasPlayedMatchesError =>
      'No se puede retirar un equipo que ya tiene partidos en curso o finalizados';

  @override
  String get competitionEnrollTeamDialogTitle =>
      'Inscribir Equipo en Competición';

  @override
  String get competitionEnrollTeamExistingClubLabel =>
      'Copiar de club existente (opcional)';

  @override
  String get competitionEnrollTeamNewClubOption => 'Crear nuevo equipo';

  @override
  String get competitionEnrollTeamGroupLabel => 'Grupo asignado';

  @override
  String get competitionEnrollTeamSubmitAction => 'Inscribir Equipo';

  @override
  String competitionEnrollTeamSuccess(String teamName) {
    return 'Equipo $teamName inscrito en la competición';
  }

  @override
  String get organizerCompetitionsSectionTitle => 'Mis Competiciones';

  @override
  String get organizerCompetitionsCreateAction => 'Nueva Competición';

  @override
  String get organizerCompetitionsEmptyTitle =>
      'No tienes competiciones activas';

  @override
  String get organizerCompetitionsEmptySubtitle =>
      'Crea y administra tus torneos, categorías y reglamentos desde este panel.';

  @override
  String get organizerCompetitionsEmptyCreateButton =>
      'Crear mi primera competición';

  @override
  String organizerCompetitionsTeamsCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count equipos inscritos',
      one: '1 equipo inscrito',
    );
    return '$_temp0';
  }

  @override
  String get organizerCompetitionsMenuEdit => 'Editar metadatos';

  @override
  String get organizerCompetitionsMenuStatus => 'Cambiar estado de competición';

  @override
  String get organizerCompetitionsMenuDelete => 'Eliminar competición';

  @override
  String get competitionEditDialogTitle => 'Editar Competición';

  @override
  String get competitionEditNameLabel => 'Nombre del torneo';

  @override
  String get competitionEditCategoryLabel => 'Categoría';

  @override
  String get competitionEditFormatLabel => 'Formato de competición';

  @override
  String get competitionEditSaveButton => 'Guardar cambios';

  @override
  String get competitionEditSavedSuccess =>
      'Competición actualizada exitosamente.';

  @override
  String get competitionLifecycleDialogTitle => 'Cambiar Estado del Torneo';

  @override
  String competitionLifecycleCurrentStatus(String status) {
    return 'Estado actual: $status';
  }

  @override
  String get competitionLifecycleTargetStatus => 'Nuevo estado:';

  @override
  String competitionLifecycleValidationMinTeams(int count) {
    return 'No se puede iniciar el torneo: requiere al menos 2 equipos inscritos (actuales: $count).';
  }

  @override
  String get competitionLifecycleValidationNoFixture =>
      'No se puede iniciar el torneo: debes generar el fixture de partidos previamente.';

  @override
  String get competitionLifecycleActionEnrollTeams => 'Inscribir Equipos';

  @override
  String get competitionLifecycleActionGenerateFixture => 'Generar Fixture';

  @override
  String get competitionLifecycleConfirmButton => 'Confirmar cambio de estado';

  @override
  String competitionLifecycleSuccess(String status) {
    return 'Estado del torneo actualizado a $status.';
  }

  @override
  String get competitionDeleteDialogTitle => 'Eliminar Competición';

  @override
  String competitionDeleteDialogMessage(String name) {
    return '¿Estás seguro de que deseas eliminar permanentemente la competición \"$name\"? Esta acción no se puede deshacer.';
  }

  @override
  String get competitionDeleteBlockedInProgress =>
      'No se puede eliminar una competición en curso o finalizada.';

  @override
  String get competitionDeleteBlockedHasMatches =>
      'No se puede eliminar la competición porque ya cuenta con partidos disputados o en curso.';

  @override
  String get competitionDeleteConfirmButton => 'Eliminar definitivamente';

  @override
  String get competitionDeleteSuccess => 'La competición ha sido eliminada.';

  @override
  String get competitionDeleteCancelButton => 'Cancelar';

  @override
  String get coachNoTeamTitle => 'Sin Equipo Registrado';

  @override
  String get coachNoTeamDescription =>
      'Aún no tienes ningún equipo registrado bajo tu gestión como entrenador.';

  @override
  String get coachActionRegisterTeamEmpty => 'Registrar mi Equipo';

  @override
  String get createTeamDialogTitle => 'Registrar Nuevo Equipo';

  @override
  String get createTeamNameLabel => 'Nombre del Equipo';

  @override
  String get createTeamShortCodeLabel => 'Sigla (2-4 letras)';

  @override
  String get createTeamTournamentLabel => 'Competición (Opcional)';

  @override
  String get createTeamNoTournamentOption => 'Sin torneo asignado';

  @override
  String get createTeamSubmitAction => 'Registrar Equipo';

  @override
  String createTeamSuccessMessage(String name) {
    return 'Equipo \"$name\" registrado exitosamente';
  }

  @override
  String get unauthorizedTeamCreationMessage =>
      'Solo los entrenadores pueden registrar equipos o futbolistas';

  @override
  String get teamEligibilityPendingVerification => 'Pendiente de verificación';

  @override
  String get teamEligibilityQuotaInsufficientTitle =>
      'Cuota reglamentaria insuficiente';

  @override
  String teamEligibilityQuotaInsufficientMessage(int actual) {
    return 'El equipo no cumple la cuota reglamentaria mínima (mínimo 11 jugadores requeridos, actual: $actual)';
  }

  @override
  String get teamEligibilityActionApprove => 'Habilitar Equipo';

  @override
  String get teamEligibilityActionRevoke => 'Inhabilitar';

  @override
  String get teamEligibilityActionUnderstood => 'Entendido';

  @override
  String competitionTeamPlayersIncomplete(int count) {
    return '$count/11 jugadores - Incompleto';
  }

  @override
  String competitionTeamPlayersComplete(int count) {
    return '$count jugadores - Nómina válida';
  }

  @override
  String get competitionFixtureMinEligibleTeamsError =>
      'Se requieren al menos dos equipos habilitados con nómina completa';

  @override
  String get teamEligibilityRevokedSuccess =>
      'El equipo ha sido inhabilitado para el campeonato';

  @override
  String get venuesSectionTitle => 'Sedes Oficiales';

  @override
  String get venuesSectionSubtitle =>
      'Selecciona las sedes donde se disputarán los partidos';

  @override
  String get noVenuesRegistered => 'No hay sedes registradas todavía';

  @override
  String get createNewVenue => 'Crear Nueva Sede';

  @override
  String get venueNameLabel => 'Nombre de la Sede';

  @override
  String get venueAddressLabel => 'Dirección';

  @override
  String get venuePitchesCountLabel => 'Número de Canchas';

  @override
  String get venueNameTooShort => 'El nombre debe tener al menos 3 caracteres';

  @override
  String get venueAddressTooShort =>
      'La dirección debe tener al menos 5 caracteres';

  @override
  String get venuePitchesInvalid => 'Debe tener al menos 1 cancha';

  @override
  String get venueNameDuplicate =>
      'Ya existe una sede con este nombre. Selecciónala de la lista o elige otro nombre.';

  @override
  String get competitionFabAddTeamsLabel => 'Agregar Equipos';

  @override
  String get addTeamsModalTitle => 'Agregar Equipos';

  @override
  String addTeamsModalSubtitle(String tournamentName) {
    return 'Busca clubes registrados e inscríbelos en $tournamentName';
  }

  @override
  String get addTeamsSearchHint => 'Buscar equipo por nombre o sigla...';

  @override
  String get addTeamsActionAdd => 'Agregar';

  @override
  String get addTeamsStatusEnrolledBadge => 'Inscrito';

  @override
  String get addTeamsEmptyCatalogTitle => 'Sin equipos en la plataforma';

  @override
  String get addTeamsEmptyCatalogMessage =>
      'No hay equipos registrados en la plataforma. Los entrenadores deben registrar sus clubes antes de poder inscribirlos en el campeonato.';

  @override
  String get addTeamsDefaultCategoryLabel => 'Categoría libre';

  @override
  String addTeamsCoachMeta(String coachName) {
    return 'DT: $coachName';
  }

  @override
  String addTeamsEmptySearchMessage(String query) {
    return 'No se encontraron equipos con \"$query\"';
  }

  @override
  String get addTeamsClearSearchAction => 'Limpiar búsqueda';

  @override
  String addTeamsEnrollSuccess(String teamName) {
    return '$teamName inscrito (Pendiente de verificación)';
  }

  @override
  String addTeamsEnrollSuccessSkippedPlayers(
    String teamName,
    int skippedCount,
  ) {
    String _temp0 = intl.Intl.pluralLogic(
      skippedCount,
      locale: localeName,
      other:
          'omitieron $skippedCount jugadores ya inscritos en otros clubes del torneo',
      one: 'omitió 1 jugador ya inscrito en otro club del torneo',
    );
    return '$teamName inscrito. Se $_temp0.';
  }

  @override
  String get addTeamsDuplicateError =>
      'Este equipo ya se encuentra inscrito en la competición';

  @override
  String addTeamsPlayersCountMeta(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count jugadores en plantilla',
      one: '1 jugador en plantilla',
      zero: 'Sin plantilla registrada',
    );
    return '$_temp0';
  }

  @override
  String get syncStatusSyncedTooltip => 'Datos sincronizados en la nube';

  @override
  String syncStatusPendingTooltip(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count cambios pendientes por sincronizar',
      one: '1 cambio pendiente por sincronizar',
    );
    return '$_temp0';
  }

  @override
  String get syncStatusSyncingTooltip => 'Sincronizando cambios con la nube';

  @override
  String get syncStatusOfflineOrErrorTooltip =>
      'Sin conexión o error de sincronización';

  @override
  String get syncSheetTitle => 'Estado de sincronización';

  @override
  String get syncConnectionOnline => 'En línea';

  @override
  String get syncConnectionOffline => 'Sin conexión';

  @override
  String get syncStateSyncedTitle => 'Todos los datos están al día';

  @override
  String syncStatePendingTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count operaciones pendientes',
      one: '1 operación pendiente',
    );
    return '$_temp0';
  }

  @override
  String get syncStateSyncingTitle => 'Sincronizando con KickPulse...';

  @override
  String syncStateErrorTitle(int errorCount) {
    String _temp0 = intl.Intl.pluralLogic(
      errorCount,
      locale: localeName,
      other: '$errorCount operaciones requieren revisión',
      one: '1 operación requiere revisión',
    );
    return '$_temp0';
  }

  @override
  String get syncLastSyncedNever => 'Última sincronización: aún sin registrar';

  @override
  String syncLastSyncedAt(String formattedDate) {
    return 'Última sincronización: $formattedDate';
  }

  @override
  String get syncQueueEmptyMessage =>
      'No hay cambios locales pendientes de respaldo en la nube.';

  @override
  String get syncItemStatusQueued => 'En cola';

  @override
  String get syncItemStatusRetrying => 'Reintentando';

  @override
  String get syncItemStatusError => 'Error';

  @override
  String get syncEntityTournament => 'Competición';

  @override
  String get syncEntityVenue => 'Sede deportiva';

  @override
  String get syncEntityTeam => 'Equipo';

  @override
  String get syncEntityMatch => 'Partido';

  @override
  String get syncEntityLineup => 'Alineación';

  @override
  String get syncEntityMatchReport => 'Acta arbitral';

  @override
  String get syncEntityMatchAlert => 'Alerta en vivo';

  @override
  String get syncEntityNews => 'Noticia';

  @override
  String get syncEntityHonorRoll => 'Cuadro de honor';

  @override
  String get syncEntityFavorite => 'Favorito';

  @override
  String get syncActionNow => 'Sincronizar ahora';

  @override
  String get syncActionRetry => 'Reintentar';

  @override
  String get syncActionDiscard => 'Descartar';

  @override
  String get syncErrorPermissionDenied =>
      'No tienes permisos para modificar este recurso en el servidor.';

  @override
  String get syncErrorConstraintViolation =>
      'Conflicto o duplicado con los datos actuales del torneo.';

  @override
  String get syncErrorValidationFailed =>
      'El servidor rechazó los datos por validación de reglas.';

  @override
  String get syncErrorNotFound =>
      'El registro asociado ya no existe en la nube.';

  @override
  String get syncErrorUnknown =>
      'El servidor rechazó la operación y requiere revisión.';

  @override
  String get syncLogoutGuardTitle => 'Cambios pendientes sin sincronizar';

  @override
  String syncLogoutGuardMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Tienes $count cambios guardados localmente que aún no se han respaldado en la nube.',
      one:
          'Tienes 1 cambio guardado localmente que aún no se ha respaldado en la nube.',
    );
    return '$_temp0 ¿Cómo deseas continuar?';
  }

  @override
  String get syncLogoutActionSyncAndExit => 'Sincronizar y salir';

  @override
  String get syncLogoutActionKeepPending => 'Salir conservando pendientes';

  @override
  String get syncLogoutSyncFailedNotice =>
      'No se pudieron sincronizar todos los cambios. Revisa tu conexión o inténtalo desde el panel de estado.';

  @override
  String get capViewCloudSyncIndicator =>
      'Indicador de sincronización en la nube';

  @override
  String get playersDirectoryOfflineRefreshWarning =>
      'Sin conexión a internet. Mostrando nómina local disponible.';

  @override
  String get teamsDirectoryOfflineRefreshWarning =>
      'Sin conexión a internet. Mostrando equipos locales disponibles.';

  @override
  String get teamsDirectoryNoTournamentAssigned => 'Sin torneo asignado';

  @override
  String get teamsDirectoryMultipleTournaments => 'Múltiples torneos';

  @override
  String get profileIncompleteBadge => 'Datos incompletos';

  @override
  String get profileCompleteBadge => 'Perfil completo';

  @override
  String get profileIncompleteBannerTitle => 'Completa tu ficha personal';

  @override
  String get profileIncompleteBannerSubtitle =>
      'Agrega tu información de contacto y datos de rol para mantener tu ficha al día.';

  @override
  String get profileCompleteAction => 'Completar mi perfil';

  @override
  String get completeProfileDialogTitle => 'Completar mi perfil';

  @override
  String get completeProfilePhoneLabel => 'Teléfono de contacto';

  @override
  String get completeProfileDocumentLabel => 'Documento de identidad';

  @override
  String get completeProfileClubLabel => 'Club o escuela';

  @override
  String get completeProfileLicenseLabel => 'Nivel de licencia';

  @override
  String get completeProfileOrganizationLabel => 'Entidad organizadora';

  @override
  String get completeProfileBaseCityLabel => 'Ciudad base';

  @override
  String get completeProfileCityLabel => 'Ciudad';

  @override
  String get completeProfilePreferencesLabel => 'Preferencias (opcional)';

  @override
  String get completeProfileSaveAction => 'Guardar perfil';

  @override
  String get completeProfileSuccessMessage =>
      'Perfil actualizado y sincronizado en la nube.';

  @override
  String get completeProfileOfflineError =>
      'Se requiere conexión a internet para guardar tu perfil.';

  @override
  String get completeProfileDocumentConflictError =>
      'El documento ingresado ya está vinculado a otra cuenta de usuario.';

  @override
  String get completeProfileRequiredFieldError => 'Este campo es obligatorio.';

  @override
  String get completeProfileInvalidPhoneError =>
      'Ingresa un teléfono válido (mínimo 7 dígitos).';

  @override
  String get completeProfileInvalidDocumentError =>
      'Ingresa un documento válido (mínimo 5 caracteres).';

  @override
  String get teamRosterIneligibleIndicator => 'No elegible / Faltan jugadores';

  @override
  String teamRosterQuotaProgress(int current, int min) {
    return '$current/$min jugadores mínimos';
  }

  @override
  String get teamRosterEnableCompetitionAction =>
      'Habilitar para Competiciones';

  @override
  String get teamRosterEnableSuccessMessage =>
      'Equipo habilitado oficialmente para competir.';

  @override
  String teamRosterPendingRequestsHeader(int count) {
    return 'Solicitudes enviadas ($count)';
  }

  @override
  String get teamRosterCancelRequestAction => 'Cancelar invitación';

  @override
  String get teamInvitePlayerModalTitle => 'Invitar Jugador a la Plantilla';

  @override
  String get teamInviteSearchHint => 'Buscar jugador por nombre o documento...';

  @override
  String get teamInviteShirtNumberLabel => 'Dorsal propuesto (1-99)';

  @override
  String get teamInvitePositionLabel => 'Posición táctica';

  @override
  String get teamInviteSendAction => 'Enviar Solicitud';

  @override
  String teamInviteSuccessMessage(String playerName) {
    return 'Solicitud enviada a $playerName.';
  }

  @override
  String teamInviteDuplicateShirtError(int shirt) {
    return 'El dorsal $shirt ya está ocupado en la plantilla o en una solicitud pendiente.';
  }

  @override
  String get teamInviteDuplicatePlayerError =>
      'Este jugador ya pertenece al equipo o tiene una invitación pendiente.';

  @override
  String teamInviteEmptySearchMessage(String query) {
    return 'No se encontraron jugadores registrados con \"$query\"';
  }

  @override
  String get profileTeamRequestsTile => 'Solicitudes de Equipos';

  @override
  String get profileTeamRequestsTitle => 'Invitaciones de Equipos';

  @override
  String get profileTeamRequestsEmpty =>
      'No tienes solicitudes de equipos pendientes.';

  @override
  String get profileTeamRequestAcceptAction => 'Aceptar';

  @override
  String get profileTeamRequestRejectAction => 'Rechazar';

  @override
  String profileTeamRequestAcceptedMessage(String teamName) {
    return 'Te has unido exitosamente a $teamName.';
  }

  @override
  String profileTeamRequestRejectedMessage(String teamName) {
    return 'Invitación de $teamName rechazada.';
  }

  @override
  String get coachRosterSectionTitle => 'Plantilla por Posición';

  @override
  String coachRosterPositionHeader(String position, int count) {
    return '$position ($count)';
  }

  @override
  String coachRosterPositionGoalkeepers(int count) {
    return 'Porteros ($count)';
  }

  @override
  String coachRosterPositionDefenders(int count) {
    return 'Defensas ($count)';
  }

  @override
  String coachRosterPositionMidfielders(int count) {
    return 'Mediocampistas ($count)';
  }

  @override
  String coachRosterPositionForwards(int count) {
    return 'Delanteros ($count)';
  }

  @override
  String get coachRosterPlayerEligible => 'Elegible';

  @override
  String get coachRosterPlayerInactive => 'Inactivo / Sancionado';

  @override
  String get coachRosterEmptyPosition => 'Sin jugadores en esta posición';

  @override
  String get coachRosterNoGoalkeeperAlert =>
      'Alerta táctica: El equipo no tiene porteros registrados.';

  @override
  String get profilePersonalDataTile => 'Datos Personales';

  @override
  String get profilePersonalDataSubtitle =>
      'Información personal, ubicación y posiciones';

  @override
  String get playerPersonalDataTitle => 'Datos Personales';

  @override
  String get playerPersonalDataSubtitle =>
      'Completa tu información personal y deportiva';

  @override
  String get playerPersonalDataDocumentLabel => 'Número de documento';

  @override
  String get playerPersonalDataDocumentHint => 'Ej. 1020304050';

  @override
  String get playerPersonalDataDocumentRequired =>
      'El número de documento es obligatorio';

  @override
  String get playerPersonalDataDocumentInvalid =>
      'El documento debe tener al menos 5 caracteres';

  @override
  String get playerPersonalDataPhoneLabel => 'Teléfono';

  @override
  String get playerPersonalDataPhoneHint => 'Ej. 3001234567';

  @override
  String get playerPersonalDataPhoneRequired => 'El teléfono es obligatorio';

  @override
  String get playerPersonalDataPhoneInvalid =>
      'El teléfono debe tener al menos 7 dígitos';

  @override
  String get playerPersonalDataFirstNameLabel => 'Primer nombre';

  @override
  String get playerPersonalDataFirstNameHint => 'Ej. Juan';

  @override
  String get playerPersonalDataFirstNameRequired =>
      'El primer nombre es obligatorio';

  @override
  String get playerPersonalDataSecondNameLabel => 'Segundo nombre';

  @override
  String get playerPersonalDataSecondNameHint => 'Ej. Carlos (opcional)';

  @override
  String get playerPersonalDataFirstSurnameLabel => 'Primer apellido';

  @override
  String get playerPersonalDataFirstSurnameHint => 'Ej. Pérez';

  @override
  String get playerPersonalDataFirstSurnameRequired =>
      'El primer apellido es obligatorio';

  @override
  String get playerPersonalDataSecondSurnameLabel => 'Segundo apellido';

  @override
  String get playerPersonalDataSecondSurnameHint => 'Ej. Gómez (opcional)';

  @override
  String get playerPersonalDataSexLabel => 'Sexo';

  @override
  String get playerPersonalDataSexRequired => 'Selecciona tu sexo';

  @override
  String get playerPersonalDataSexMale => 'Masculino';

  @override
  String get playerPersonalDataSexFemale => 'Femenino';

  @override
  String get playerPersonalDataSexOther => 'Otro';

  @override
  String get playerPersonalDataBirthDateLabel => 'Fecha de nacimiento';

  @override
  String get playerPersonalDataBirthDateHint => 'AAAA-MM-DD';

  @override
  String get playerPersonalDataBirthDateRequired =>
      'La fecha de nacimiento es obligatoria';

  @override
  String get playerPersonalDataAgeLabel => 'Edad';

  @override
  String playerPersonalDataAgeYears(int age) {
    return '$age años';
  }

  @override
  String get playerPersonalDataBloodTypeLabel => 'Tipo de sangre y RH';

  @override
  String get playerPersonalDataBloodTypeHint => 'Selecciona una opción';

  @override
  String get playerPersonalDataBloodTypeRequired =>
      'Selecciona tu tipo de sangre';

  @override
  String get playerPersonalDataDepartmentLabel => 'Departamento';

  @override
  String get playerPersonalDataDepartmentHint => 'Selecciona tu departamento';

  @override
  String get playerPersonalDataDepartmentRequired =>
      'Selecciona tu departamento';

  @override
  String get playerPersonalDataMunicipalityLabel => 'Municipio';

  @override
  String get playerPersonalDataMunicipalityHint => 'Selecciona tu municipio';

  @override
  String get playerPersonalDataMunicipalityRequired =>
      'Selecciona tu municipio';

  @override
  String get playerPersonalDataSelectDepartmentFirst =>
      'Selecciona primero un departamento';

  @override
  String get playerPersonalDataPositionsLabel => 'Posiciones de juego';

  @override
  String get playerPersonalDataPositionsSubtitle =>
      'Selecciona una o más posiciones en las que juegas';

  @override
  String get playerPersonalDataPositionsRequired =>
      'Debes seleccionar al menos una posición';

  @override
  String get playerPersonalDataSaveButton => 'Guardar datos personales';

  @override
  String get playerPersonalDataSaving => 'Guardando...';

  @override
  String get playerPersonalDataSaveSuccess =>
      'Datos personales actualizados correctamente';

  @override
  String get playerPersonalDataErrorBanner =>
      'No fue posible guardar los datos. Inténtalo nuevamente.';

  @override
  String get playerPersonalDataDocumentAlreadyLinked =>
      'Este número de documento ya está asociado a otro jugador.';

  @override
  String get playerPersonalDataOfflineError =>
      'No hay conexión a internet. Los datos no se pudieron sincronizar.';

  @override
  String get playerPersonalDataUnsavedChangesTitle => '¿Descartar cambios?';

  @override
  String get playerPersonalDataUnsavedChangesMessage =>
      'Tienes cambios sin guardar en tu ficha personal. Si sales ahora, se perderán las modificaciones.';

  @override
  String get playerPersonalDataUnsavedChangesDiscard => 'Descartar';

  @override
  String get playerPersonalDataUnsavedChangesKeepEditing =>
      'Continuar editando';

  @override
  String get playerPositionPOR => 'Portero (POR)';

  @override
  String get playerPositionDFC => 'Defensa Central (DFC)';

  @override
  String get playerPositionLD => 'Lateral Derecho (LD)';

  @override
  String get playerPositionLI => 'Lateral Izquierdo (LI)';

  @override
  String get playerPositionCAD => 'Carrilero Derecho (CAD)';

  @override
  String get playerPositionCAI => 'Carrilero Izquierdo (CAI)';

  @override
  String get playerPositionMCD => 'Mediocentro Defensivo (MCD)';

  @override
  String get playerPositionMC => 'Mediocentro (MC)';

  @override
  String get playerPositionMCO => 'Mediocentro Ofensivo (MCO)';

  @override
  String get playerPositionMD => 'Medio Derecho (MD)';

  @override
  String get playerPositionMI => 'Medio Izquierdo (MI)';

  @override
  String get playerPositionED => 'Extremo Derecho (ED)';

  @override
  String get playerPositionEI => 'Extremo Izquierdo (EI)';

  @override
  String get playerPositionMP => 'Mediapunta (MP)';

  @override
  String get playerPositionDC => 'Delantero Centro (DC)';

  @override
  String get playerTacticalLineGoalkeeper => 'Portería';

  @override
  String get playerTacticalLineDefender => 'Defensa';

  @override
  String get playerTacticalLineMidfielder => 'Mediocampo';

  @override
  String get playerTacticalLineForward => 'Delantera';

  @override
  String get locationPickerSearchPlaceholder => 'Buscar...';

  @override
  String get locationPickerEmptyState => 'No se encontraron resultados';

  @override
  String get locationPickerSelectDepartmentTitle => 'Seleccionar Departamento';

  @override
  String get locationPickerSelectMunicipalityTitle => 'Seleccionar Municipio';

  @override
  String get playerDocumentScanButton => 'Escanear / Capturar Cédula';

  @override
  String get playerDocumentCardTitle => 'Fotos de la Cédula';

  @override
  String get playerDocumentCardSubtitle =>
      'Captura el frente y reverso de tu cédula colombiana para completar tu ficha';

  @override
  String get playerDocumentFrontSideLabel => 'Frente (Cara frontal)';

  @override
  String get playerDocumentBackSideLabel => 'Reverso (Cara posterior)';

  @override
  String get playerDocumentCaptureFrontButton => 'Capturar frente';

  @override
  String get playerDocumentCaptureBackButton => 'Capturar reverso';

  @override
  String get playerDocumentRecaptureButton => 'Repetir foto';

  @override
  String get playerDocumentScanningIndicator => 'Procesando documento...';

  @override
  String get playerDocumentScanSuccessFeedback =>
      'Datos leídos automáticamente de la cédula';

  @override
  String get playerDocumentScanPartialFeedback =>
      'Se completaron algunos datos de la cédula. Por favor verifica y completa los campos faltantes.';

  @override
  String get playerDocumentScanEmptyFeedback =>
      'No se detectaron datos legibles. Puedes ingresar tus datos manualmente.';

  @override
  String get playerDocumentCameraPermissionDenied =>
      'Se requiere permiso de cámara para capturar la cédula.';

  @override
  String get playerDocumentCameraPermissionOpenSettings =>
      'Abrir configuración';

  @override
  String get playerDocumentImagesRequiredError =>
      'Debes capturar ambas caras de tu cédula (frente y reverso) para continuar';

  @override
  String get playerDocumentUploadError =>
      'Error al subir las imágenes de la cédula. Inténtalo nuevamente.';

  @override
  String get playerProfilePhotoSectionTitle => 'Foto de Perfil';

  @override
  String get playerProfilePhotoSectionSubtitle =>
      'Tómate una foto o selecciónala de tu galería para tu carnet digital';

  @override
  String get playerProfilePhotoAction => 'Tomar Foto de Perfil';

  @override
  String get playerProfilePhotoChangeAction => 'Cambiar Foto';

  @override
  String get playerProfilePhotoCameraOption => 'Tomar con la cámara';

  @override
  String get playerProfilePhotoGalleryOption => 'Elegir de la galería';

  @override
  String get playerProfilePhotoPermissionDenied =>
      'Se requiere permiso de cámara o galería para tu foto de perfil.';

  @override
  String get playerProfilePhotoUploadError =>
      'Error al subir la fotografía de perfil. Inténtalo nuevamente.';

  @override
  String get playerPersonalDataSummaryTitle => 'Datos Personales';

  @override
  String get playerPersonalDataEditAction => 'Editar Datos';

  @override
  String playerSummaryAgeFormat(int age) {
    return '$age años';
  }

  @override
  String get playerSummaryAgeUnknown => 'Edad no registrada';

  @override
  String get playerSummaryDemographicsTitle => 'Información Demográfica';

  @override
  String get playerSummaryDemographicsSubtitle =>
      'Datos personales y lugar de residencia';

  @override
  String get playerSummarySexLabel => 'Sexo';

  @override
  String get playerSummaryBirthDateLabel => 'Fecha de Nacimiento';

  @override
  String get playerSummaryBloodTypeLabel => 'Tipo de Sangre';

  @override
  String get playerSummaryDepartmentLabel => 'Departamento';

  @override
  String get playerSummaryMunicipalityLabel => 'Municipio';

  @override
  String get playerSummaryTacticalTitle => 'Perfil Táctico';

  @override
  String get playerSummaryTacticalSubtitle =>
      'Posiciones registradas en el terreno de juego';

  @override
  String get playerSummaryPrimaryPositionLabel => 'Posición Principal';

  @override
  String get playerSummarySecondaryPositionsLabel => 'Posiciones Secundarias';

  @override
  String get playerSummaryNoSecondaryPositions =>
      'Sin posiciones secundarias registradas';

  @override
  String get playerSummaryDocumentationTitle => 'Documento de Identidad';

  @override
  String get playerSummaryDocumentationSubtitle =>
      'Cédula de ciudadanía por ambas caras';

  @override
  String get playerSummaryFrontDocLabel => 'Cara Frontal';

  @override
  String get playerSummaryBackDocLabel => 'Cara Posterior';

  @override
  String get playerSummaryDocNotCaptured => 'No capturada';

  @override
  String get playerSummaryViewerCloseAction => 'Cerrar';

  @override
  String get playerPersonalDataSummarySubtitle =>
      'Consulta tu carnet, ficha demográfica y táctica';

  @override
  String get fixtureRegenerateConfirmTitle => '¿Regenerar el fixture?';

  @override
  String get fixtureRegenerateConfirmMessage =>
      'Esta competición ya tiene un fixture creado. Si continúas, se reemplazarán todos los partidos actuales y sus programaciones tanto en este dispositivo como en la nube.';

  @override
  String get fixtureRegenerateConfirmAction => 'Regenerar Fixture';

  @override
  String get matchLogisticsTbdLabel => 'Por definir';

  @override
  String get scheduleMatchOptionalHint => 'Opcional — puedes asignarlo después';

  @override
  String get profileLegalSupportSectionTitle => 'Preferencias y soporte';

  @override
  String get profileRemoveAdsButton => 'Quitar anuncios';

  @override
  String get profileTermsButton => 'Términos y condiciones';

  @override
  String get profilePrivacyPolicyButton => 'Políticas de tratamiento de datos';

  @override
  String get profileFaqButton => 'Preguntas frecuentes';

  @override
  String get removeAdsDialogTitle => 'Experiencia sin anuncios';

  @override
  String get removeAdsComingSoonBadge => 'Próximamente';

  @override
  String get removeAdsDialogDescription =>
      'Muy pronto podrás disfrutar de ViFutbol sin publicidad mientras sigues marcadores, tablas de posiciones y novedades de tus campeonatos en tiempo real.';

  @override
  String get removeAdsDialogNotice =>
      'La pasarela de pagos se encuentra en preparación. No se realizará ningún cobro en esta versión.';

  @override
  String get removeAdsDialogCloseAction => 'Entendido';

  @override
  String get legalDocumentLastUpdated =>
      'Última actualización: noviembre de 2026';

  @override
  String get termsSection1Title => '1. Aceptación y uso de la plataforma';

  @override
  String get termsSection1Body =>
      'ViFutbol es una plataforma para la gestión de campeonatos, sedes deportivas, equipos, actas de partidos y seguimiento en vivo. Al usar la aplicación aceptas operar bajo estos términos y las reglas deportivas vigentes.';

  @override
  String get termsSection2Title => '2. Roles y responsabilidades';

  @override
  String get termsSection2Body =>
      'Cada usuario accede según su rol asignado (Organizador, Entrenador, Árbitro, Jugador o Aficionado). Las actas oficiales, resultados y sanciones registradas por roles autorizados constituyen la fuente oficial del torneo.';

  @override
  String get termsSection3Title => '3. Operación offline y disponibilidad';

  @override
  String get termsSection3Body =>
      'ViFutbol permite consultar información descargada y operar sin conexión en cancha, sincronizando los cambios pendientes cuando la conectividad se restablece.';

  @override
  String get privacySection1Title => '1. Datos personales recolectados';

  @override
  String get privacySection1Body =>
      'Tratamos los datos suministrados en tu perfil (nombre, correo electrónico, documento de identificación y ficha deportiva de jugador cuando corresponda) exclusivamente para administrar campeonatos, inscripciones y elegibilidad.';

  @override
  String get privacySection2Title => '2. Finalidad y protección';

  @override
  String get privacySection2Body =>
      'Tu información se almacena de forma segura en tu dispositivo para soporte offline y en nuestros servidores autorizados, sin ser comercializada con terceros.';

  @override
  String get privacySection3Title => '3. Derechos del titular';

  @override
  String get privacySection3Body =>
      'Como titular de los datos puedes consultar, actualizar y solicitar la supresión de tu información personal conforme a la normativa aplicable de protección de datos.';

  @override
  String get faqItem1Question =>
      '¿Cómo funciona ViFutbol sin conexión a internet?';

  @override
  String get faqItem1Answer =>
      'La aplicación guarda una copia local de tus torneos, partidos y datos del perfil para que puedas consultarlos en la cancha. Cuando vuelvas a tener conexión, la sincronización actualiza automáticamente los cambios pendientes.';

  @override
  String get faqItem2Question =>
      '¿Puedo cambiar mi rol activo desde el Perfil?';

  @override
  String get faqItem2Answer =>
      'No. Por seguridad e integridad del control de acceso (RBAC), tu rol activo se muestra en modo solo lectura en la tarjeta de identidad del Perfil.';

  @override
  String get faqItem3Question =>
      '¿Cómo completo mis datos deportivos como Jugador?';

  @override
  String get faqItem3Answer =>
      'Si tu rol es Jugador, ingresa a \'Datos personales\' dentro de tu Perfil para completar tu ficha demográfica, posición táctica y documento de identidad.';

  @override
  String get faqItem4Question =>
      '¿Cuándo estará disponible la opción de Quitar anuncios?';

  @override
  String get faqItem4Answer =>
      'Estamos integrando la pasarela de pagos oficial. Muy pronto podrás activar la experiencia sin anuncios directamente desde la sección de Perfil.';

  @override
  String get profileDeleteAccountButton => 'Eliminar cuenta';

  @override
  String get deleteAccountDialogTitle => '¿Eliminar cuenta permanentemente?';

  @override
  String get deleteAccountDialogMessage =>
      'Esta acción es permanente e irreversible. Se eliminarán tu cuenta, tus perfiles deportivos, solicitudes, favoritos y archivos personales tanto de este dispositivo como de la nube.';

  @override
  String get deleteAccountConfirmAction => 'Eliminar cuenta';

  @override
  String get deleteAccountDeletingLabel => 'Eliminando cuenta...';

  @override
  String get deleteAccountOfflineError =>
      'Se requiere conexión a internet para eliminar tu cuenta. Verifica tu conexión e intenta nuevamente.';

  @override
  String get deleteAccountGenericError =>
      'No se pudo eliminar tu cuenta en este momento. Tus datos locales se mantuvieron intactos; intenta nuevamente más tarde.';

  @override
  String get refereePersonalDataTitle => 'Datos del Árbitro';

  @override
  String get refereePersonalDataTile => 'Datos personales y certificación';

  @override
  String get refereePersonalDataSubtitle =>
      'Cédula colombiana, ubicación y documento de certificación arbitral';

  @override
  String get refereeCertificationSectionTitle => 'Certificación Arbitral';

  @override
  String get refereeCertificationLevelLabel =>
      'Categoría o nivel de certificación arbitral';

  @override
  String get refereeCertificationLevelHint =>
      'Ej. Liga Departamental, Nacional, FIFA';

  @override
  String get refereeCertificationDocTitle =>
      'Documento de certificación arbitral';

  @override
  String get refereeCertificationDocSubtitle =>
      'Adjunta una foto o imagen de tu carnet arbitral, certificado de colegio/liga o diploma.';

  @override
  String get refereeCertificationCaptureButton =>
      'Capturar documento de certificación arbitral';

  @override
  String get refereeCertificationReplaceButton => 'Reemplazar documento';

  @override
  String get refereeCertificationCapturedBadge => 'Documento adjunto';

  @override
  String get refereeCertificationDocRequiredError =>
      'Debes adjuntar la imagen de tu documento de certificación arbitral.';

  @override
  String get refereeCertificationLevelRequiredError =>
      'Ingresa tu categoría o nivel de certificación arbitral.';

  @override
  String get refereeAvatarSectionTitle => 'Foto de perfil';

  @override
  String get refereeAvatarSectionSubtitle =>
      'Esta fotografía se mostrará en tu tarjeta de perfil arbitral.';

  @override
  String get refereeAvatarCameraButton => 'Tomar foto de perfil';

  @override
  String get refereeAvatarGalleryButton => 'Seleccionar de galería';

  @override
  String get refereeAvatarChangeButton => 'Cambiar foto';

  @override
  String get refereeAvatarPermissionDeniedError =>
      'Permiso de cámara o galería denegado. Habilítalo en los ajustes del dispositivo o usa la opción alternativa.';

  @override
  String get refereeAvatarGalleryPermissionDeniedError =>
      'No tenemos permiso para acceder a tu galería. Habilítalo en ajustes o usa la cámara.';

  @override
  String get refereeAvatarLoadError =>
      'No se pudo cargar la imagen seleccionada. Intenta con otra fotografía.';

  @override
  String get refereePersonalDataSummaryTitle => 'Perfil Arbitral';

  @override
  String get refereePersonalDataSummarySubtitle =>
      'Consulta tu avatar, datos personales y documentos';

  @override
  String get refereeSummaryCertificationTitle => 'Certificación Arbitral';

  @override
  String get refereeSummaryCertificationSubtitle =>
      'Categoría oficial y soporte documental';

  @override
  String get refereeSummaryPhoneLabel => 'Teléfono';

  @override
  String get refereeSummaryCertificationDocLabel =>
      'Documento de certificación';

  @override
  String get refereeSummaryDocLoadFallback => 'Vista previa no disponible';

  @override
  String get refereeFilterAll => 'Todos';

  @override
  String get refereeFilterInProgress => 'En juego';

  @override
  String get refereeFilterScheduled => 'Programados';

  @override
  String get refereeFilterCompleted => 'Finalizados';

  @override
  String get refereeEmptyFilterMessage =>
      'No tienes partidos en esta categoría.';

  @override
  String get refereeMatchStatusScheduled => 'Programado';

  @override
  String get refereeMatchStatusInProgress => 'En juego';

  @override
  String get refereeMatchStatusCompleted => 'Finalizado';

  @override
  String get refereeMatchStatusPending => 'Pendiente';

  @override
  String get refereeMatchStatusCancelled => 'Cancelado';

  @override
  String get refereeMatchDateUnscheduled => 'Fecha por definir';

  @override
  String get refereeMatchActionManage => 'Gestionar Acta';

  @override
  String get refereeMatchActionViewClosed => 'Ver Acta Finalizada';

  @override
  String get refereeMatchUnauthorizedBanner =>
      'Solo el árbitro asignado a este partido puede iniciar y gestionar el acta.';

  @override
  String get refereeMatchUnconfirmedConvocationBanner =>
      'Uno o ambos equipos no han confirmado convocatoria oficial; se cargó la plantilla inscrita como respaldo.';

  @override
  String get refereeObservationsTitle => 'Observaciones arbitrales';

  @override
  String get refereeObservationsHint =>
      'Registra incidencias, estado de la cancha o notas oficiales del encuentro...';

  @override
  String get refereeObservationsSaveAction => 'Guardar observaciones';

  @override
  String get refereeObservationsSavedMessage =>
      'Observaciones guardadas en el acta';

  @override
  String get refereeObservationsEmpty => 'Sin observaciones registradas.';

  @override
  String get alertTypeRefereeAssigned => 'Asignación arbitral';

  @override
  String get refereeMatchAssignedAlertTitle => 'Nuevo partido asignado';
}
