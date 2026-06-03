class StringUtils {
  static String? formatNzPhoneNumber(String? rawPhone) {
    if (rawPhone == null || rawPhone.isEmpty) return rawPhone;

    // 1. Clean the string: remove any existing spaces, dashes, or brackets
    String cleaned = rawPhone.replaceAll(RegExp(r'[^\d+]'), '');

    // 2. If it already starts with +64, just format it with the dash
    if (cleaned.startsWith('+64')) {
      String rest = cleaned.substring(3);
      if (rest.startsWith('0')) rest = rest.substring(1); // Handle weird inputs like +64022
      return '+64-$rest';
    }

    // 3. If it starts with 64 but is missing the '+'
    if (cleaned.startsWith('64')) {
      String rest = cleaned.substring(2);
      if (rest.startsWith('0')) rest = rest.substring(1);
      return '+64-$rest';
    }

    // 4. If it starts with a standard local '0' (e.g., 022)
    if (cleaned.startsWith('0')) {
      return '+64-${cleaned.substring(1)}';
    }

    // 5. If it just starts with the network code (e.g., 223585912)
    return '+64-$cleaned';
  }
}