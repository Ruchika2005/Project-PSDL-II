class PhoneUtils {
  /// Normalizes a phone number to the standard format: +91XXXXXXXXXX
  static String normalizePhoneNumber(String phone) {
    if (phone.isEmpty) return phone;

    // Remove all non-digit characters
    String digits = phone.replaceAll(RegExp(r'\D'), '');

    // Case 1: 10-digit number (e.g., 9876543210) -> +919876543210
    if (digits.length == 10) {
      return '+91$digits';
    }

    // Case 2: 12-digit number starting with 91 (e.g., 919876543210) -> +919876543210
    if (digits.length == 12 && digits.startsWith('91')) {
      return '+$digits';
    }

    // Case 3: Number already has + and digits (e.g., +91 98765 43210)
    if (phone.startsWith('+')) {
      return '+$digits';
    }

    // Fallback: return trimmed original if no logic matches
    return phone.trim();
  }
}
