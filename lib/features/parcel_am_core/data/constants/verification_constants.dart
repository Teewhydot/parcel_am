class VerificationConstants {
  static const List<String> genderOptions = ['Male', 'Female', 'Other'];
  
  static const List<String> nigerianStates = [
    'Abia', 'Adamawa', 'Akwa Ibom', 'Anambra', 'Bauchi', 'Bayelsa', 'Benue',
    'Borno', 'Cross River', 'Delta', 'Ebonyi', 'Edo', 'Ekiti', 'Enugu',
    'FCT - Abuja', 'Gombe', 'Imo', 'Jigawa', 'Kaduna', 'Kano', 'Katsina',
    'Kebbi', 'Kogi', 'Kwara', 'Lagos', 'Nasarawa', 'Niger', 'Ogun', 'Ondo',
    'Osun', 'Oyo', 'Plateau', 'Rivers', 'Sokoto', 'Taraba', 'Yobe', 'Zamfara'
  ];
  
  static const String privacyNotice = 
      'Your information is securely stored and only used for verification purposes. '
      'We comply with Nigerian data protection regulations.';
  
  static const String verificationProcessInfo = 
      'Your verification will be reviewed within 24-48 hours. '
      'You\'ll receive a notification once the review is complete.';
  
  static const String successMessage = 
      'Your verification has been submitted successfully! '
      'We\'ll review your information and notify you within 24-48 hours.';
  
  static const List<String> photoTips = [
    'Ensure good lighting',
    'Document should be clearly visible',
    'Avoid glare or shadows',
    'All text must be readable',
    'File size should be under 5MB',
  ];
  
  static const List<String> acceptedAddressDocuments = [
    'Utility bill (electricity, water, gas)',
    'Bank statement',
    'Tenancy agreement',
    'Government-issued document with address',
    'Tax receipt',
  ];
  
  static const Map<String, String> documentTypes = {
    'nin': 'National Identity Number',
    'drivers_license': 'Driver\'s License',
    'passport': 'International Passport',
    'voters_card': 'Voter\'s Card',
  };
  
  static const Map<String, String> vehicleTypes = {
    'car': 'Car',
    'bus': 'Bus',
    'motorcycle': 'Motorcycle',
    'truck': 'Truck',
    'plane': 'Airplane',
  };
  
  static const Map<String, String> packageTypes = {
    'documents': 'Documents',
    'electronics': 'Electronics',
    'clothing': 'Clothing',
    'food': 'Food Items',
    'medical': 'Medical Supplies',
    'fragile': 'Fragile Items',
    'other': 'Other',
  };
  
  static const Map<String, String> urgencyLevels = {
    'urgent': 'Urgent (Within 24 hours)',
    'normal': 'Normal (2-3 days)',
    'flexible': 'Flexible (Within a week)',
  };
  
  static const Map<String, String> paymentMethods = {
    'bank_transfer': 'Bank Transfer',
    'card': 'Debit/Credit Card',
    'mobile_money': 'Mobile Money',
    'cash': 'Cash on Delivery',
  };
  
  static const Map<String, List<String>> popularBanks = {
    'commercial': [
      'Access Bank',
      'First Bank of Nigeria',
      'Guaranty Trust Bank (GTBank)',
      'United Bank for Africa (UBA)',
      'Zenith Bank',
      'Fidelity Bank',
      'Union Bank',
      'Sterling Bank',
      'Stanbic IBTC Bank',
      'Standard Chartered Bank',
      'Ecobank Nigeria',
      'Citibank Nigeria',
      'Heritage Bank',
      'Keystone Bank',
      'Polaris Bank',
      'Unity Bank',
      'Wema Bank',
    ],
    'microfinance': [
      'LAPO Microfinance Bank',
      'AB Microfinance Bank',
      'VFD Microfinance Bank',
    ],
    'digital': [
      'Kuda Bank',
      'Opay',
      'PalmPay',
      'Carbon (formerly Paylater)',
      'Rubies Bank',
      'VBank',
    ],
  };
  
  static String getTimeBasedGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good morning';
    } else if (hour < 17) {
      return 'Good afternoon';
    } else {
      return 'Good evening';
    }
  }
}