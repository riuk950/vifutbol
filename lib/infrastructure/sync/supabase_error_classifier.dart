import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' show ClientException;
import 'package:supabase_flutter/supabase_flutter.dart'
    show AuthException, PostgrestException;
import 'package:vifutbol/domain/entities/sync_status.dart';

/// Structured non-transient server rejection result safe for persistence (`FR-010`).
class SyncClassifiedRejection {
  final SyncErrorCode code;
  final String safeDetail;

  const SyncClassifiedRejection({required this.code, required this.safeDetail});
}

/// Classifies Supabase / network failures into transient connectivity retries vs
/// non-transient item errors with credential redaction (`FR-006`, `FR-010`).
class SupabaseErrorClassifier {
  const SupabaseErrorClassifier._();

  static final RegExp _jwtPattern = RegExp(
    r'eyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+',
  );
  static final RegExp _bearerPattern = RegExp(
    r'Bearer\s+[A-Za-z0-9._-]+',
    caseSensitive: false,
  );
  static final RegExp _secretFieldPattern = RegExp(
    r'(password|apikey|api_key|access_token|refresh_token|secret)\s*[:=]\s*[^\s,;]+',
    caseSensitive: false,
  );

  /// Redacts tokens, bearer headers, and passwords from error details (`FR-010`).
  static String redactCredentials(String input) {
    var sanitized = input.replaceAll(_jwtPattern, '[REDACTED]');
    sanitized = sanitized.replaceAll(_bearerPattern, 'Bearer [REDACTED]');
    sanitized = sanitized.replaceAllMapped(
      _secretFieldPattern,
      (match) => '${match.group(1)}=[REDACTED]',
    );
    return sanitized.trim();
  }

  /// Returns `true` when [error] represents a temporary network or 5xx outage
  /// that should remain queued for retry instead of marking the item as errored.
  static bool isTransientError(Object error) {
    if (error is SocketException ||
        error is TimeoutException ||
        error is ClientException ||
        error is HandshakeException ||
        error is HttpException) {
      return true;
    }

    if (error is PostgrestException) {
      final code = (error.code ?? '').trim();
      if (code.startsWith('5')) {
        return true;
      }
      final lowerMsg = error.message.toLowerCase();
      return lowerMsg.contains('failed host lookup') ||
          lowerMsg.contains('connection refused') ||
          lowerMsg.contains('timed out') ||
          lowerMsg.contains('network is unreachable') ||
          lowerMsg.contains('socketexception');
    }

    final text = error.toString().toLowerCase();
    return text.contains('socketexception') ||
        text.contains('timeoutexception') ||
        text.contains('clientexception') ||
        text.contains('failed host lookup') ||
        text.contains('network is unreachable');
  }

  /// Maps a non-transient rejection into a domain [SyncErrorCode] and sanitized snippet.
  static SyncClassifiedRejection classifyRejection(Object error) {
    if (error is AuthException) {
      final status = int.tryParse(error.statusCode ?? '');
      if (status == 401 || status == 403) {
        return SyncClassifiedRejection(
          code: SyncErrorCode.permissionDenied,
          safeDetail: redactCredentials(error.message),
        );
      }
      return SyncClassifiedRejection(
        code: SyncErrorCode.unknown,
        safeDetail: redactCredentials(error.message),
      );
    }

    if (error is PostgrestException) {
      final pgCode = (error.code ?? '').trim().toUpperCase();
      final detail = redactCredentials(error.message);

      if (pgCode == '42501' || pgCode == '401' || pgCode == '403') {
        return SyncClassifiedRejection(
          code: SyncErrorCode.permissionDenied,
          safeDetail: detail,
        );
      }
      if (pgCode.startsWith('23') || pgCode == '409') {
        return SyncClassifiedRejection(
          code: SyncErrorCode.constraintViolation,
          safeDetail: detail,
        );
      }
      if (pgCode.startsWith('22') || pgCode == '400' || pgCode == '422') {
        return SyncClassifiedRejection(
          code: SyncErrorCode.validationFailed,
          safeDetail: detail,
        );
      }
      if (pgCode == 'PGRST116' || pgCode == '404') {
        return SyncClassifiedRejection(
          code: SyncErrorCode.notFound,
          safeDetail: detail,
        );
      }
      return SyncClassifiedRejection(
        code: SyncErrorCode.unknown,
        safeDetail: detail,
      );
    }

    return SyncClassifiedRejection(
      code: SyncErrorCode.unknown,
      safeDetail: redactCredentials(error.toString()),
    );
  }
}
