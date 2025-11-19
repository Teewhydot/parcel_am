class PhoneNumberUtils {
  static String formatPhoneNumber(String phoneNumber) {
    // Remove any non-digit characters
    final digitsOnly = phoneNumber.replaceAll(RegExp(r'\D'), '');
    
    // Check if it starts with 234 (Nigeria country code)
    if (digitsOnly.startsWith('234')) {
      return '+$digitsOnly';
    }
    
    // Check if it starts with 0 (local Nigerian format)
    if (digitsOnly.startsWith('0') && digitsOnly.length == 11) {
      return '+234${digitsOnly.substring(1)}';
    }
    
    // Check if it's already in the correct format without +
    if (digitsOnly.length == 13 && digitsOnly.startsWith('234')) {
      return '+$digitsOnly';
    }
    
    // Check if it's just the number without country code or 0
    if (digitsOnly.length == 10) {
      return '+234$digitsOnly';
    }
    
    // Return as is if format is unclear
    return phoneNumber;
  }

  static bool isValidNigerianNumber(String phoneNumber) {
    // Nigerian phone numbers: +234XXXXXXXXXX or 0XXXXXXXXXX
    final regex = RegExp(r'^(\+234|0)[789]\d{9}$');
    return regex.hasMatch(phoneNumber);
  }

  static bool isTestPhoneNumber(String phoneNumber) {
    // Test phone numbers for development
    return phoneNumber == '+2349000000000' || phoneNumber == '09000000000';
  }
}
