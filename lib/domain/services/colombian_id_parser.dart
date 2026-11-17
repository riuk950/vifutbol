// lib/domain/services/colombian_id_parser.dart

import '../entities/colombian_id_scan_result.dart';
import '../entities/player_personal_enums.dart';

/// Pure domain utility for decoding and parsing Colombian identity documents
/// (cédula de ciudadanía) from raw PDF417 payloads and ICAO 9303 TD1 MRZ / OCR texts.
class ColombianIdParser {
  const ColombianIdParser._();

  static const Map<String, String> _accentedSpanishNames = {
    'PEREZ': 'Pérez',
    'GOMEZ': 'Gómez',
    'RODRIGUEZ': 'Rodríguez',
    'GONZALEZ': 'González',
    'MARTINEZ': 'Martínez',
    'SANCHEZ': 'Sánchez',
    'LOPEZ': 'López',
    'HERNANDEZ': 'Hernández',
    'DIAZ': 'Díaz',
    'ALVAREZ': 'Álvarez',
    'RAMIREZ': 'Ramírez',
    'GUTIERREZ': 'Gutiérrez',
    'VELASQUEZ': 'Velásquez',
    'JIMENEZ': 'Jiménez',
    'VASQUEZ': 'Vásquez',
    'ANDRES': 'Andrés',
    'MARIA': 'María',
    'JOSE': 'José',
    'JESUS': 'Jesús',
    'SEBASTIAN': 'Sebastián',
    'ANGEL': 'Ángel',
  };

  /// Parses raw PDF417 barcode data from Colombian yellow identity cards.
  static ColombianIdScanResult parsePdf417(String rawPayload) {
    if (rawPayload.trim().isEmpty) return ColombianIdScanResult.empty;

    // Check null-byte delimited structure
    if (rawPayload.contains('\x00')) {
      final tokens = rawPayload
          .split('\x00')
          .map((t) => t.trim())
          .toList();

      return _parsePdf417Tokens(tokens);
    }

    // Check fixed-width RNEC binary payload structure
    if (rawPayload.length >= 170 &&
        (rawPayload.startsWith('PubDSK_') || rawPayload.contains('PubDSK_'))) {
      return _parsePdf417FixedWidth(rawPayload);
    }

    return ColombianIdScanResult.empty;
  }

  static ColombianIdScanResult _parsePdf417Tokens(List<String> tokens) {
    if (tokens.isEmpty) return ColombianIdScanResult.empty;

    // Remove known header tokens if present
    final cleanTokens = List<String>.from(tokens);
    cleanTokens.removeWhere((t) => t.startsWith('PubDSK_'));

    // Find document number token (starts with digits, possibly with leading zeros)
    int docIndex = -1;
    for (int i = 0; i < cleanTokens.length; i++) {
      final token = cleanTokens[i];
      if (token.isNotEmpty && RegExp(r'^\d{6,12}$').hasMatch(token)) {
        docIndex = i;
        break;
      }
    }

    if (docIndex == -1) return ColombianIdScanResult.empty;

    final rawDoc = cleanTokens[docIndex];
    final docId = rawDoc.replaceFirst(RegExp(r'^0+'), '');

    String? firstSurname;
    String? secondSurname;
    String? firstName;
    String? secondName;
    PlayerSex? sex;
    DateTime? birthDate;
    BloodType? bloodType;

    int current = docIndex + 1;

    // 1st Surname
    if (current < cleanTokens.length) {
      if (cleanTokens[current].isNotEmpty && _isNameToken(cleanTokens[current])) {
        firstSurname = _formatName(cleanTokens[current]);
      }
      current++;
    }

    // 2nd Surname
    if (current < cleanTokens.length) {
      if (cleanTokens[current].isNotEmpty && _isNameToken(cleanTokens[current])) {
        secondSurname = _formatName(cleanTokens[current]);
      }
      current++;
    }

    // 1st Name
    if (current < cleanTokens.length) {
      if (cleanTokens[current].isNotEmpty && _isNameToken(cleanTokens[current])) {
        firstName = _formatName(cleanTokens[current]);
      }
      current++;
    }

    // 2nd Name
    if (current < cleanTokens.length) {
      if (cleanTokens[current].isNotEmpty && _isNameToken(cleanTokens[current])) {
        secondName = _formatName(cleanTokens[current]);
      }
      current++;
    }

    // Sex, DOB, and BloodType
    for (int i = current; i < cleanTokens.length; i++) {
      final token = cleanTokens[i].toUpperCase();
      if (token.isEmpty) continue;

      if (sex == null && (token == 'M' || token == 'F')) {
        sex = token == 'M' ? PlayerSex.male : PlayerSex.female;
        continue;
      }

      if (birthDate == null && RegExp(r'^\d{8}$').hasMatch(token)) {
        final parsed = _parseYyyyMmDd(token);
        if (parsed != null) {
          birthDate = parsed;
          continue;
        }
      }

      if (bloodType == null) {
        final parsedBlood = _parseBloodString(token);
        if (parsedBlood != null) {
          bloodType = parsedBlood;
          continue;
        }
      }
    }

    return ColombianIdScanResult(
      documentId: docId.isNotEmpty ? docId : null,
      firstSurname: firstSurname,
      secondSurname: secondSurname,
      firstName: firstName,
      secondName: secondName,
      sex: sex,
      birthDate: birthDate,
      bloodType: bloodType,
      source: ColombianIdScanSource.pdf417,
    );
  }

  static ColombianIdScanResult _parsePdf417FixedWidth(String payload) {
    try {
      final int baseOffset = payload.indexOf('PubDSK_');
      final int start = baseOffset >= 0 ? baseOffset : 0;

      String safeSub(int from, int length) {
        final startIdx = start + from;
        if (startIdx >= payload.length) return '';
        final endIdx = (startIdx + length).clamp(0, payload.length);
        return payload.substring(startIdx, endIdx).trim();
      }

      final rawDoc = safeSub(48, 10);
      final docId = rawDoc.replaceFirst(RegExp(r'^0+'), '');
      final firstSurname = _formatName(safeSub(58, 26));
      final secondSurname = _formatName(safeSub(84, 26));
      final firstName = _formatName(safeSub(110, 26));
      final secondName = _formatName(safeSub(136, 26));

      final rawSex = safeSub(162, 1).toUpperCase();
      final sex = rawSex == 'M'
          ? PlayerSex.male
          : (rawSex == 'F' ? PlayerSex.female : null);

      final rawDob = safeSub(163, 8);
      final birthDate = _parseYyyyMmDd(rawDob);

      final rawBlood = safeSub(171, 5);
      final bloodType = _parseBloodString(rawBlood);

      return ColombianIdScanResult(
        documentId: docId.isNotEmpty ? docId : null,
        firstSurname: firstSurname?.isNotEmpty == true ? firstSurname : null,
        secondSurname: secondSurname?.isNotEmpty == true ? secondSurname : null,
        firstName: firstName?.isNotEmpty == true ? firstName : null,
        secondName: secondName?.isNotEmpty == true ? secondName : null,
        sex: sex,
        birthDate: birthDate,
        bloodType: bloodType,
        source: ColombianIdScanSource.pdf417,
      );
    } catch (_) {
      return ColombianIdScanResult.empty;
    }
  }

  /// Parses ICAO 9303 TD1 3-line MRZ from Colombian digital polycarbonate IDs,
  /// with OCR fallback for printed document number and blood group.
  static ColombianIdScanResult parseMrzAndOcr(
    String fullOcrText, {
    DateTime? referenceDate,
  }) {
    if (fullOcrText.trim().isEmpty) return ColombianIdScanResult.empty;

    // Normalize OCR misrecognized chevrons and spaces
    final normalized = fullOcrText
        .replaceAll('«', '<')
        .replaceAll('<<', '<<');

    final lines = normalized
        .split('\n')
        .map((l) => l.trim().replaceAll(' ', '<'))
        .where((l) => l.isNotEmpty)
        .toList();

    // Look for TD1 MRZ lines
    int line1Idx = -1;
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (line.startsWith('I<COL') || line.startsWith('IDCOL')) {
        line1Idx = i;
        break;
      }
    }

    String? documentId;
    String? firstSurname;
    String? secondSurname;
    String? firstName;
    String? secondName;
    PlayerSex? sex;
    DateTime? birthDate;
    BloodType? bloodType;

    if (line1Idx != -1 && line1Idx + 2 < lines.length) {
      final line1 = lines[line1Idx];
      final line2 = lines[line1Idx + 1];
      final line3 = lines[line1Idx + 2];

      // Line 1: Document number
      final docMatch = RegExp(r'^I[<D]COL([0-9A-Z]{5,15})').firstMatch(line1);
      if (docMatch != null) {
        documentId = docMatch.group(1);
      }

      // Line 2: Date of Birth and Sex
      if (line2.length >= 8) {
        final dobDigits = line2.substring(0, 6);
        if (RegExp(r'^\d{6}$').hasMatch(dobDigits)) {
          birthDate = _parseYyMmDd(dobDigits, referenceDate: referenceDate);
        }

        final sexChar = line2[7].toUpperCase();
        if (sexChar == 'M') {
          sex = PlayerSex.male;
        } else if (sexChar == 'F') {
          sex = PlayerSex.female;
        }
      }

      // Line 3: Names (SURNAME<<FIRST<SECOND)
      final cleanLine3 = line3.replaceAll(RegExp(r'<+$'), '');
      final parts = cleanLine3.split('<<');
      if (parts.isNotEmpty) {
        final surnames = parts[0].split('<').where((s) => s.isNotEmpty).toList();
        if (surnames.isNotEmpty) {
          firstSurname = _formatName(surnames[0]);
          if (surnames.length > 1) {
            secondSurname = _formatName(surnames[1]);
          }
        }
      }
      if (parts.length > 1) {
        final names = parts[1].split('<').where((s) => s.isNotEmpty).toList();
        if (names.isNotEmpty) {
          firstName = _formatName(names[0]);
          if (names.length > 1) {
            secondName = _formatName(names[1]);
          }
        }
      }
    }

    // OCR Heuristics over full text for fallback/complements
    if (documentId == null || documentId.isEmpty) {
      final nuipMatch = RegExp(
        r'(?:NUIP|NÚMERO|DOCUMENTO)?[:\s]*(\d{1,3}(?:\.\d{3}){2,3}|\d{7,10})',
        caseSensitive: false,
      ).firstMatch(fullOcrText);

      if (nuipMatch != null) {
        documentId = nuipMatch.group(1)?.replaceAll('.', '');
      }
    }

    final bloodMatch = RegExp(
      r'\b(O|A|B|AB)\s*(\+|\-|POS(?:ITIVO)?|NEG(?:ATIVO)?)',
      caseSensitive: false,
    ).firstMatch(fullOcrText);

    if (bloodMatch != null) {
      final group = bloodMatch.group(1)!.toUpperCase();
      final signRaw = bloodMatch.group(2)!.toUpperCase();
      final sign = signRaw.startsWith('+') || signRaw.startsWith('POS') ? '+' : '-';
      bloodType = BloodType.fromRaw('$group$sign');
    }

    if (sex == null) {
      final sexMatch = RegExp(
        r'SEXO[:\s]*([MF])\b',
        caseSensitive: false,
      ).firstMatch(fullOcrText);
      if (sexMatch != null) {
        final s = sexMatch.group(1)!.toUpperCase();
        sex = s == 'M' ? PlayerSex.male : PlayerSex.female;
      }
    }

    final hasAny = (documentId != null && documentId.isNotEmpty) ||
        (firstSurname != null && firstSurname.isNotEmpty) ||
        (firstName != null && firstName.isNotEmpty) ||
        birthDate != null ||
        bloodType != null ||
        sex != null;

    if (!hasAny) {
      return ColombianIdScanResult.empty;
    }

    return ColombianIdScanResult(
      documentId: documentId,
      firstSurname: firstSurname,
      secondSurname: secondSurname,
      firstName: firstName,
      secondName: secondName,
      sex: sex,
      birthDate: birthDate,
      bloodType: bloodType,
      source: line1Idx != -1
          ? ColombianIdScanSource.mrzOcr
          : ColombianIdScanSource.partial,
    );
  }

  /// Merges primary (e.g. PDF417) and secondary (e.g. MRZ/OCR) scan results,
  /// prioritizing non-null primary values and filling gaps from secondary.
  static ColombianIdScanResult mergeResults(
    ColombianIdScanResult primary,
    ColombianIdScanResult secondary,
  ) {
    if (!primary.hasAnyField) return secondary;
    if (!secondary.hasAnyField) return primary;

    return ColombianIdScanResult(
      documentId: primary.documentId?.isNotEmpty == true
          ? primary.documentId
          : secondary.documentId,
      firstName: primary.firstName?.isNotEmpty == true
          ? primary.firstName
          : secondary.firstName,
      secondName: primary.secondName?.isNotEmpty == true
          ? primary.secondName
          : secondary.secondName,
      firstSurname: primary.firstSurname?.isNotEmpty == true
          ? primary.firstSurname
          : secondary.firstSurname,
      secondSurname: primary.secondSurname?.isNotEmpty == true
          ? primary.secondSurname
          : secondary.secondSurname,
      sex: primary.sex ?? secondary.sex,
      birthDate: primary.birthDate ?? secondary.birthDate,
      bloodType: primary.bloodType ?? secondary.bloodType,
      source: primary.source != ColombianIdScanSource.none
          ? primary.source
          : secondary.source,
    );
  }

  // --- Helpers ---

  static bool _isNameToken(String token) {
    if (token.isEmpty) return false;
    final upper = token.toUpperCase();
    if (upper == 'M' || upper == 'F') return false;
    if (RegExp(r'^\d+$').hasMatch(upper)) return false;
    if (_parseBloodString(upper) != null) return false;
    return true;
  }

  static String? _formatName(String? raw) {
    if (raw == null) return null;
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;

    final upper = trimmed.toUpperCase();
    if (_accentedSpanishNames.containsKey(upper)) {
      return _accentedSpanishNames[upper]!;
    }

    // Capitalize first letter of each word and lowercase the rest, preserving accents
    return trimmed
        .split(RegExp(r'\s+'))
        .map((word) {
          if (word.isEmpty) return '';
          final wUpper = word.toUpperCase();
          if (_accentedSpanishNames.containsKey(wUpper)) {
            return _accentedSpanishNames[wUpper]!;
          }
          final lower = word.toLowerCase();
          return lower[0].toUpperCase() + lower.substring(1);
        })
        .join(' ');
  }

  static DateTime? _parseYyyyMmDd(String raw) {
    if (raw.length != 8) return null;
    final y = int.tryParse(raw.substring(0, 4));
    final m = int.tryParse(raw.substring(4, 6));
    final d = int.tryParse(raw.substring(6, 8));
    if (y == null || m == null || d == null) return null;
    if (m < 1 || m > 12 || d < 1 || d > 31) return null;
    try {
      return DateTime(y, m, d);
    } catch (_) {
      return null;
    }
  }

  static DateTime? _parseYyMmDd(String raw, {DateTime? referenceDate}) {
    if (raw.length != 6) return null;
    final yy = int.tryParse(raw.substring(0, 2));
    final m = int.tryParse(raw.substring(2, 4));
    final d = int.tryParse(raw.substring(4, 6));
    if (yy == null || m == null || d == null) return null;
    if (m < 1 || m > 12 || d < 1 || d > 31) return null;

    final refYear = referenceDate?.year ?? DateTime.now().year;
    final currentYy = refYear % 100;
    final y = yy > currentYy ? (1900 + yy) : (2000 + yy);

    try {
      return DateTime(y, m, d);
    } catch (_) {
      return null;
    }
  }

  static BloodType? _parseBloodString(String raw) {
    final clean = raw.trim().toUpperCase().replaceAll(' ', '');
    // Standard matches
    final direct = BloodType.fromRaw(clean);
    if (direct != null) return direct;

    // Check variants like O+, O-, A+, etc.
    final match = RegExp(r'(O|A|B|AB)([+-])').firstMatch(clean);
    if (match != null) {
      return BloodType.fromRaw('${match.group(1)}${match.group(2)}');
    }
    return null;
  }
}
