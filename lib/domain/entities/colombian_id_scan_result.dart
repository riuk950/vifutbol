// lib/domain/entities/colombian_id_scan_result.dart

import 'package:flutter/foundation.dart';
import 'player_personal_enums.dart';

/// Indicates the scanning/decoding source that yielded the ID data.
enum ColombianIdScanSource {
  /// Extracted primarily from the PDF417 barcode (yellow hologram ID).
  pdf417,

  /// Extracted via ICAO 9303 TD1 MRZ block and OCR heuristics (digital ID).
  mrzOcr,

  /// Partial or hybrid extraction where some fields were decoded and others missing.
  partial,

  /// No readable structured data could be extracted from the images.
  none,
}

/// Represents the structured data extracted from scanning a Colombian ID card.
@immutable
class ColombianIdScanResult {
  const ColombianIdScanResult({
    this.documentId,
    this.firstName,
    this.secondName,
    this.firstSurname,
    this.secondSurname,
    this.sex,
    this.birthDate,
    this.bloodType,
    this.source = ColombianIdScanSource.none,
  });

  /// An empty scan result representing no extracted data.
  static const empty = ColombianIdScanResult();

  /// Cleaned identification number / NUIP (digits only).
  final String? documentId;

  /// Normalized first given name.
  final String? firstName;

  /// Normalized second given name, if present.
  final String? secondName;

  /// Normalized first surname.
  final String? firstSurname;

  /// Normalized second surname, if present.
  final String? secondSurname;

  /// Biological or legal sex.
  final PlayerSex? sex;

  /// Date of birth.
  final DateTime? birthDate;

  /// ABO and Rh blood group.
  final BloodType? bloodType;

  /// Origin mechanism of the scan result.
  final ColombianIdScanSource source;

  /// Whether at least one recognized data field is present.
  bool get hasAnyField =>
      (documentId != null && documentId!.isNotEmpty) ||
      (firstName != null && firstName!.isNotEmpty) ||
      (secondName != null && secondName!.isNotEmpty) ||
      (firstSurname != null && firstSurname!.isNotEmpty) ||
      (secondSurname != null && secondSurname!.isNotEmpty) ||
      sex != null ||
      birthDate != null ||
      bloodType != null;

  ColombianIdScanResult copyWith({
    String? documentId,
    String? firstName,
    String? secondName,
    String? firstSurname,
    String? secondSurname,
    PlayerSex? sex,
    DateTime? birthDate,
    BloodType? bloodType,
    ColombianIdScanSource? source,
  }) {
    return ColombianIdScanResult(
      documentId: documentId ?? this.documentId,
      firstName: firstName ?? this.firstName,
      secondName: secondName ?? this.secondName,
      firstSurname: firstSurname ?? this.firstSurname,
      secondSurname: secondSurname ?? this.secondSurname,
      sex: sex ?? this.sex,
      birthDate: birthDate ?? this.birthDate,
      bloodType: bloodType ?? this.bloodType,
      source: source ?? this.source,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ColombianIdScanResult &&
          runtimeType == other.runtimeType &&
          documentId == other.documentId &&
          firstName == other.firstName &&
          secondName == other.secondName &&
          firstSurname == other.firstSurname &&
          secondSurname == other.secondSurname &&
          sex == other.sex &&
          birthDate == other.birthDate &&
          bloodType == other.bloodType &&
          source == other.source;

  @override
  int get hashCode => Object.hash(
        documentId,
        firstName,
        secondName,
        firstSurname,
        secondSurname,
        sex,
        birthDate,
        bloodType,
        source,
      );

  @override
  String toString() =>
      'ColombianIdScanResult(doc: $documentId, firstName: $firstName, firstSurname: $firstSurname, source: $source)';
}

/// Represents the captured or persisted front and back photos of an ID document.
@immutable
class PlayerDocumentCapture {
  const PlayerDocumentCapture({
    this.frontImagePath,
    this.backImagePath,
    this.frontRemoteUrl,
    this.backRemoteUrl,
  });

  /// Empty state with no captured photos.
  static const empty = PlayerDocumentCapture();

  /// Local path of newly captured front side photo.
  final String? frontImagePath;

  /// Local path of newly captured back side photo.
  final String? backImagePath;

  /// Persisted remote storage URL/path for front side photo.
  final String? frontRemoteUrl;

  /// Persisted remote storage URL/path for back side photo.
  final String? backRemoteUrl;

  /// Whether a front side photo is available (either local or remote).
  bool get hasFront =>
      (frontImagePath != null && frontImagePath!.isNotEmpty) ||
      (frontRemoteUrl != null && frontRemoteUrl!.isNotEmpty);

  /// Whether a back side photo is available (either local or remote).
  bool get hasBack =>
      (backImagePath != null && backImagePath!.isNotEmpty) ||
      (backRemoteUrl != null && backRemoteUrl!.isNotEmpty);

  /// Whether both front and back photos are present.
  bool get isComplete => hasFront && hasBack;

  PlayerDocumentCapture copyWith({
    String? frontImagePath,
    String? backImagePath,
    String? frontRemoteUrl,
    String? backRemoteUrl,
  }) {
    return PlayerDocumentCapture(
      frontImagePath: frontImagePath ?? this.frontImagePath,
      backImagePath: backImagePath ?? this.backImagePath,
      frontRemoteUrl: frontRemoteUrl ?? this.frontRemoteUrl,
      backRemoteUrl: backRemoteUrl ?? this.backRemoteUrl,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlayerDocumentCapture &&
          runtimeType == other.runtimeType &&
          frontImagePath == other.frontImagePath &&
          backImagePath == other.backImagePath &&
          frontRemoteUrl == other.frontRemoteUrl &&
          backRemoteUrl == other.backRemoteUrl;

  @override
  int get hashCode => Object.hash(
        frontImagePath,
        backImagePath,
        frontRemoteUrl,
        backRemoteUrl,
      );

  @override
  String toString() =>
      'PlayerDocumentCapture(hasFront: $hasFront, hasBack: $hasBack, isComplete: $isComplete)';
}
