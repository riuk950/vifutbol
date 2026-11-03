import 'package:vifutbol/domain/failures/app_failure.dart';

/// Sealed class hierarchy representing the 5 fundamental UI states
/// required by docs/MOBILE_GUIDELINES.md and FR-006.
sealed class UiViewState<T> {
  const UiViewState();
}

/// Loading state indicating an operation or initial synchronization is in progress.
class UiLoadingState<T> extends UiViewState<T> {
  final String? message;

  const UiLoadingState({this.message});
}

/// Content state with populated data ready for user interaction.
class UiContentState<T> extends UiViewState<T> {
  final T data;

  const UiContentState(this.data);
}

/// Empty state when no data records or matches exist for the view.
class UiEmptyState<T> extends UiViewState<T> {
  final String? message;
  final String? description;

  const UiEmptyState({this.message, this.description});
}

/// Error state presenting a sanitized user error and an optional retry action.
class UiErrorState<T> extends UiViewState<T> {
  final AppFailure failure;
  final bool canRetry;

  const UiErrorState(this.failure, {this.canRetry = true});
}

/// Success state providing confirmation feedback after a mutation or save.
class UiSuccessState<T> extends UiViewState<T> {
  final T data;
  final String? message;

  const UiSuccessState(this.data, {this.message});
}
