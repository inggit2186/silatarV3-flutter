/// Phone number formatting utility
/// Handles conversion between database format (without prefix) and display format (with 0 prefix)
library;

class PhoneFormatter {
  /// Format phone number for display
  /// Input: "89623965916" -> Output: "089623965916"
  /// Input: "089623965916" -> Output: "089623965916" (already formatted)
  /// Input: "+6289623965916" -> Output: "089623965916"
  /// Input: "6289623965916" -> Output: "089623965916"
  static String formatForDisplay(String? phone) {
    if (phone == null || phone.isEmpty) return '';

    // Remove any existing prefix (0, +62, 62)
    String cleaned = _stripPrefix(phone);

    // Add 0 prefix for display
    if (cleaned.isNotEmpty) {
      return '0$cleaned';
    }

    return '';
  }

  /// Format phone number for storage (database)
  /// Input: "089623965916" -> Output: "89623965916"
  /// Input: "+6289623965916" -> Output: "89623965916"
  /// Input: "6289623965916" -> Output: "89623965916"
  /// Input: "89623965916" -> Output: "89623965916" (already formatted)
  static String formatForStorage(String? phone) {
    if (phone == null || phone.isEmpty) return '';

    return _stripPrefix(phone);
  }

  /// Strip phone prefix (0, +62, 62)
  static String _stripPrefix(String phone) {
    String cleaned = phone.replaceAll(RegExp(r'[\s\-]'), ''); // Remove spaces and dashes

    // Strip +62 or 62 prefix
    if (cleaned.startsWith('+62')) {
      cleaned = cleaned.substring(3);
    } else if (cleaned.startsWith('62')) {
      cleaned = cleaned.substring(2);
    }
    // Strip 0 prefix
    else if (cleaned.startsWith('0')) {
      cleaned = cleaned.substring(1);
    }

    return cleaned;
  }

  /// Validate phone number format (after stripping prefix)
  /// Should be numeric and reasonable length (10-15 digits)
  static bool isValid(String? phone) {
    if (phone == null || phone.isEmpty) return true; // Optional field

    String cleaned = formatForStorage(phone);

    // Check if contains only digits
    if (!RegExp(r'^\d+$').hasMatch(cleaned)) {
      return false;
    }

    // Check length (Indonesian phone numbers are typically 10-13 digits)
    if (cleaned.length < 10 || cleaned.length > 15) {
      return false;
    }

    return true;
  }
}
