// GS1-128 Barcode Parser
// Extracts Application Identifiers (AI) from GS1-128 barcodes
 
class GS1Parser {
  // Common Application Identifiers
  static const String aiGtin = '01';           // Global Trade Item Number
  static const String aiBatch = '10';          // Batch/Lot Number
  static const String aiProductionDate = '11'; // Production Date (YYMMDD)
  static const String aiDueDate = '12';       // Due Date (YYMMDD)
  static const String aiPackagingDate = '13'; // Packaging Date (YYMMDD)
  static const String aiBestBefore = '15';    // Best Before Date (YYMMDD)
  static const String aiSellBy = '16';        // Sell By Date (YYMMDD)
  static const String aiExpiryDate = '17';    // Expiry Date (YYMMDD)
  static const String aiSerial = '21';         // Serial Number
  static const String aiQuantity = '30';       // Variable Count
  static const String aiPrice = '392n';        // Price

  /// Parse GS1-128 barcode and extract all Application Identifiers
  static Map<String, String> parse(String barcode) {
    final Map<String, String> result = {};
    
    if (barcode.isEmpty) return result;

    // Remove FNC1 characters if present
    String cleanBarcode = barcode.replaceAll(String.fromCharCode(29), '');
    
    int position = 0;
    
    while (position < cleanBarcode.length) {
      // Try to find AI
      String? ai = _findAI(cleanBarcode, position);
      
      if (ai == null) {
        // Skip character if no valid AI found
        position++;
        continue;
      }
      
      position += ai.length;
      
      // Get value length based on AI
      int valueLength = _getValueLength(ai);
      
      if (valueLength == -1) {
        // Variable length - read until separator or end
        int endPos = _findSeparator(cleanBarcode, position);
        String value = cleanBarcode.substring(position, endPos);
        result[ai] = value;
        position = endPos + 1; // Skip separator
      } else {
        // Fixed length
        int endPos = position + valueLength;
        if (endPos > cleanBarcode.length) {
          endPos = cleanBarcode.length;
        }
        String value = cleanBarcode.substring(position, endPos);
        result[ai] = value;
        position = endPos;
      }
    }
    
    return result;
  }

  /// Extract specific data from parsed barcode
  static GS1Data extractData(String barcode) {
    final parsed = parse(barcode);
    
    return GS1Data(
      gtin: parsed[aiGtin],
      batchNumber: parsed[aiBatch],
      serialNumber: parsed[aiSerial],
      expiryDate: _parseDate(parsed[aiExpiryDate]),
      productionDate: _parseDate(parsed[aiProductionDate]),
      bestBeforeDate: _parseDate(parsed[aiBestBefore]),
      sellByDate: _parseDate(parsed[aiSellBy]),
      packagingDate: _parseDate(parsed[aiPackagingDate]),
      rawData: parsed,
    );
  }

  /// Find Application Identifier at current position
  static String? _findAI(String barcode, int position) {
    // Check 2-4 character AIs
    for (int length = 4; length >= 2; length--) {
      if (position + length > barcode.length) continue;
      
      String candidate = barcode.substring(position, position + length);
      
      if (_isValidAI(candidate)) {
        return candidate;
      }
    }
    return null;
  }

  /// Check if string is a valid AI
  static bool _isValidAI(String ai) {
    // Common AIs
    const validAIs = [
      '00', '01', '02', '10', '11', '12', '13', '15', '16', '17',
      '20', '21', '22', '240', '241', '242', '243', '250', '251',
      '30', '310n', '320n', '330n', '340n', '350n', '360n',
      '37', '390n', '391n', '392n', '393n', '400', '401', '402',
      '403', '410', '411', '412', '413', '414', '420', '421',
      '422', '423', '424', '425', '426', '427', '7001', '7002',
      '7003', '7004', '7005', '7006', '7007', '7008', '7009',
      '7010', '8001', '8002', '8003', '8004', '8005', '8006',
      '8007', '8008', '8018', '8020', '8100', '8101', '8102',
      '8110', '90', '91', '92', '93', '94', '95', '96', '97', '98', '99'
    ];
    
    return validAIs.contains(ai) || 
           validAIs.any((valid) => valid.contains('n') && 
                                   ai.startsWith(valid.replaceAll('n', '')));
  }

  /// Get value length for AI (-1 for variable length)
  static int _getValueLength(String ai) {
    const Map<String, int> fixedLengths = {
      '01': 14,  // GTIN
      '02': 14,  // GTIN of contained items
      '11': 6,   // Production date
      '12': 6,   // Due date
      '13': 6,   // Packaging date
      '15': 6,   // Best before
      '16': 6,   // Sell by
      '17': 6,   // Expiry date
      '20': 2,   // Variant
    };
    
    return fixedLengths[ai] ?? -1; // -1 means variable length
  }

  /// Find separator position (FNC1 or end of string)
  static int _findSeparator(String barcode, int startPos) {
    int separatorPos = barcode.indexOf(String.fromCharCode(29), startPos);
    if (separatorPos == -1) {
      return barcode.length;
    }
    return separatorPos;
  }

  /// Parse GS1 date format (YYMMDD) to DateTime
  static DateTime? _parseDate(String? dateStr) {
    if (dateStr == null || dateStr.length != 6) return null;
    
    try {
      int year = int.parse(dateStr.substring(0, 2));
      int month = int.parse(dateStr.substring(2, 4));
      int day = int.parse(dateStr.substring(4, 6));
      
      // Determine century (assume 2000s for year < 50, else 1900s)
      year += (year < 50) ? 2000 : 1900;
      
      return DateTime(year, month, day);
    } catch (e) {
      return null;
    }
  }

  /// Validate GTIN checksum
  static bool validateGTIN(String gtin) {
    if (gtin.length != 14 && gtin.length != 13 && gtin.length != 12 && gtin.length != 8) {
      return false;
    }
    
    // Pad to 14 digits
    String paddedGtin = gtin.padLeft(14, '0');
    
    int sum = 0;
    for (int i = 0; i < 13; i++) {
      int digit = int.parse(paddedGtin[i]);
      sum += digit * ((i % 2 == 0) ? 3 : 1);
    }
    
    int checkDigit = (10 - (sum % 10)) % 10;
    int gtinCheckDigit = int.parse(paddedGtin[13]);
    
    return checkDigit == gtinCheckDigit;
  }
}

/// Data extracted from GS1-128 barcode
class GS1Data {
  final String? gtin;
  final String? batchNumber;
  final String? serialNumber;
  final DateTime? expiryDate;
  final DateTime? productionDate;
  final DateTime? bestBeforeDate;
  final DateTime? sellByDate;
  final DateTime? packagingDate;
  final Map<String, String> rawData;

  GS1Data({
    this.gtin,
    this.batchNumber,
    this.serialNumber,
    this.expiryDate,
    this.productionDate,
    this.bestBeforeDate,
    this.sellByDate,
    this.packagingDate,
    required this.rawData,
  });

  bool get isValid => gtin != null || batchNumber != null;
  
  bool get hasExpiryDate => expiryDate != null || 
                            bestBeforeDate != null || 
                            sellByDate != null;

  DateTime? get effectiveExpiryDate => 
      expiryDate ?? bestBeforeDate ?? sellByDate;

  @override
  String toString() {
    return 'GS1Data('
        'GTIN: $gtin, '
        'Batch: $batchNumber, '
        'Expiry: ${effectiveExpiryDate?.toIso8601String()}, '
        'Production: ${productionDate?.toIso8601String()}'
        ')';
  }
}
