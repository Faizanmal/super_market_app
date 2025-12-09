// GS1-128 Barcode Scanner and Parser Service
// Handles barcode scanning and GS1 data extraction

class BarcodeService {
  static final BarcodeService _instance = BarcodeService._internal();
  factory BarcodeService() => _instance;
  BarcodeService._internal();
  
  // GS1 Application Identifiers (AI)
  static const Map<String, AI> _applicationIdentifiers = {
    '01': AI('01', 14, 'GTIN', 'Global Trade Item Number'),
    '10': AI('10', 20, 'BATCH', 'Batch or Lot Number'),
    '17': AI('17', 6, 'EXPIRY', 'Expiration Date (YYMMDD)'),
    '15': AI('15', 6, 'BEST_BEFORE', 'Best Before Date (YYMMDD)'),
    '11': AI('11', 6, 'PRODUCTION', 'Production Date (YYMMDD)'),
    '37': AI('37', 8, 'QUANTITY', 'Count of Trade Items'),
    '310': AI('310', 6, 'NET_WEIGHT_KG', 'Net Weight (kg)'),
    '3202': AI('3202', 6, 'NET_WEIGHT_LB', 'Net Weight (lb)'),
    '21': AI('21', 20, 'SERIAL', 'Serial Number'),
    '240': AI('240', 30, 'ADDITIONAL_ID', 'Additional Product Identification'),
    '421': AI('421', 3, 'SHIP_TO_POST', 'Ship to Postal Code'),
  };
  
  /// Parse GS1-128 barcode data
  GS1BarcodeData parseGS1(String rawData) {
    final Map<String, String> parsedData = {};
    String remainingData = rawData;
    
    // Remove FNC1 character if present
    remainingData = remainingData.replaceAll(String.fromCharCode(29), '');
    
    while (remainingData.isNotEmpty) {
      bool found = false;
      
      // Try to match AI patterns (longer AIs first)
      final sortedAIs = _applicationIdentifiers.keys.toList()
        ..sort((a, b) => b.length.compareTo(a.length));
      
      for (final aiCode in sortedAIs) {
        if (remainingData.startsWith(aiCode)) {
          final ai = _applicationIdentifiers[aiCode]!;
          final dataLength = ai.length;
          
          if (remainingData.length >= aiCode.length + dataLength) {
            final value = remainingData.substring(aiCode.length, aiCode.length + dataLength);
            parsedData[ai.name] = value.trim();
            remainingData = remainingData.substring(aiCode.length + dataLength);
            found = true;
            break;
          } else {
            // Variable length field - read until next AI or end
            final nextAIPos = _findNextAI(remainingData.substring(aiCode.length));
            final value = nextAIPos == -1
                ? remainingData.substring(aiCode.length)
                : remainingData.substring(aiCode.length, aiCode.length + nextAIPos);
            parsedData[ai.name] = value.trim();
            remainingData = nextAIPos == -1
                ? ''
                : remainingData.substring(aiCode.length + nextAIPos);
            found = true;
            break;
          }
        }
      }
      
      if (!found) {
        // Unknown AI or parsing error
        break;
      }
    }
    
    return GS1BarcodeData(
      gtin: parsedData['GTIN'],
      batchNumber: parsedData['BATCH'],
      expiryDate: _parseGS1Date(parsedData['EXPIRY']),
      bestBeforeDate: _parseGS1Date(parsedData['BEST_BEFORE']),
      productionDate: _parseGS1Date(parsedData['PRODUCTION']),
      serialNumber: parsedData['SERIAL'],
      rawData: rawData,
      parsedData: parsedData,
    );
  }
  
  int _findNextAI(String data) {
    for (final aiCode in _applicationIdentifiers.keys) {
      final pos = data.indexOf(aiCode);
      if (pos > 0) return pos;
    }
    return -1;
  }
  
  /// Convert GS1 date (YYMMDD) to DateTime
  DateTime? _parseGS1Date(String? gs1Date) {
    if (gs1Date == null || gs1Date.length != 6) return null;
    
    try {
      final year = int.parse(gs1Date.substring(0, 2));
      final month = int.parse(gs1Date.substring(2, 4));
      final day = int.parse(gs1Date.substring(4, 6));
      
      // Assume 20xx for years 00-50, 19xx for 51-99
      final fullYear = year <= 50 ? 2000 + year : 1900 + year;
      
      return DateTime(fullYear, month, day);
    } catch (e) {
      return null;
    }
  }
  
  /// Validate GTIN checksum
  bool validateGTIN(String gtin) {
    if (gtin.length != 14 && gtin.length != 13 && gtin.length != 12 && gtin.length != 8) {
      return false;
    }
    
    // Pad to 14 digits
    final paddedGtin = gtin.padLeft(14, '0');
    
    int sum = 0;
    for (int i = 0; i < 13; i++) {
      final digit = int.parse(paddedGtin[i]);
      sum += digit * (i.isEven ? 3 : 1);
    }
    
    final checkDigit = (10 - (sum % 10)) % 10;
    return checkDigit == int.parse(paddedGtin[13]);
  }
  
  /// Parse standard EAN/UPC barcode
  StandardBarcodeData parseStandardBarcode(String barcode) {
    String type = 'UNKNOWN';
    
    if (barcode.length == 13) {
      type = 'EAN-13';
    } else if (barcode.length == 8) {
      type = 'EAN-8';
    } else if (barcode.length == 12) {
      type = 'UPC-A';
    }
    
    return StandardBarcodeData(
      code: barcode,
      type: type,
      isValid: validateGTIN(barcode),
    );
  }
  
  /// Parse QR code for shelf location
  ShelfLocationData? parseShelfQR(String qrData) {
    try {
      // Expected format: "SHELF:{store_id}:{location_code}"
      if (qrData.startsWith('SHELF:')) {
        final parts = qrData.split(':');
        if (parts.length >= 3) {
          return ShelfLocationData(
            storeId: int.tryParse(parts[1]),
            locationCode: parts[2],
            rawData: qrData,
          );
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}

// ==================== DATA CLASSES ====================

class AI {
  final String code;
  final int length;
  final String name;
  final String description;
  
  const AI(this.code, this.length, this.name, this.description);
}

class GS1BarcodeData {
  final String? gtin;
  final String? batchNumber;
  final DateTime? expiryDate;
  final DateTime? bestBeforeDate;
  final DateTime? productionDate;
  final String? serialNumber;
  final String rawData;
  final Map<String, String> parsedData;
  
  GS1BarcodeData({
    this.gtin,
    this.batchNumber,
    this.expiryDate,
    this.bestBeforeDate,
    this.productionDate,
    this.serialNumber,
    required this.rawData,
    required this.parsedData,
  });
  
  bool get isValid => gtin != null && batchNumber != null && expiryDate != null;
  
  @override
  String toString() {
    return 'GS1Data{GTIN: $gtin, Batch: $batchNumber, Expiry: $expiryDate}';
  }
}

class StandardBarcodeData {
  final String code;
  final String type;
  final bool isValid;
  
  StandardBarcodeData({
    required this.code,
    required this.type,
    required this.isValid,
  });
  
  @override
  String toString() {
    return 'Barcode{Type: $type, Code: $code, Valid: $isValid}';
  }
}

class ShelfLocationData {
  final int? storeId;
  final String locationCode;
  final String rawData;
  
  ShelfLocationData({
    this.storeId,
    required this.locationCode,
    required this.rawData,
  });
  
  @override
  String toString() {
    return 'ShelfLocation{Store: $storeId, Location: $locationCode}';
  }
}
