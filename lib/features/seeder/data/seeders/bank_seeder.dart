import 'package:flutter/material.dart';
import '../../domain/seeder.dart';

/// Seeder for Nigerian banks.
///
/// Seeds the 'banks' collection with Nigerian bank data
/// required for bank account verification and withdrawals.
class BankSeeder extends Seeder {
  @override
  String get name => 'Nigerian Banks';

  @override
  String get description => 'Banks for account verification and withdrawals';

  @override
  String get collectionName => 'banks';

  @override
  String? get documentIdField => 'code';

  @override
  IconData get icon => Icons.account_balance;

  @override
  List<Map<String, dynamic>> get seedData => _nigerianBanks;

  static const List<Map<String, dynamic>> _nigerianBanks = [
    {'id': 1, 'name': 'Access Bank', 'code': '044', 'slug': 'access-bank', 'country': 'Nigeria', 'currency': 'NGN', 'type': 'nuban'},
    {'id': 2, 'name': 'Access Bank (Diamond)', 'code': '063', 'slug': 'access-bank-diamond', 'country': 'Nigeria', 'currency': 'NGN', 'type': 'nuban'},
    {'id': 3, 'name': 'ALAT by WEMA', 'code': '035A', 'slug': 'alat-by-wema', 'country': 'Nigeria', 'currency': 'NGN', 'type': 'nuban'},
    {'id': 4, 'name': 'Citibank Nigeria', 'code': '023', 'slug': 'citibank-nigeria', 'country': 'Nigeria', 'currency': 'NGN', 'type': 'nuban'},
    {'id': 5, 'name': 'Ecobank Nigeria', 'code': '050', 'slug': 'ecobank-nigeria', 'country': 'Nigeria', 'currency': 'NGN', 'type': 'nuban'},
    {'id': 6, 'name': 'Fidelity Bank', 'code': '070', 'slug': 'fidelity-bank', 'country': 'Nigeria', 'currency': 'NGN', 'type': 'nuban'},
    {'id': 7, 'name': 'First Bank of Nigeria', 'code': '011', 'slug': 'first-bank-of-nigeria', 'country': 'Nigeria', 'currency': 'NGN', 'type': 'nuban'},
    {'id': 8, 'name': 'First City Monument Bank', 'code': '214', 'slug': 'first-city-monument-bank', 'country': 'Nigeria', 'currency': 'NGN', 'type': 'nuban'},
    {'id': 9, 'name': 'Globus Bank', 'code': '00103', 'slug': 'globus-bank', 'country': 'Nigeria', 'currency': 'NGN', 'type': 'nuban'},
    {'id': 10, 'name': 'Guaranty Trust Bank', 'code': '058', 'slug': 'guaranty-trust-bank', 'country': 'Nigeria', 'currency': 'NGN', 'type': 'nuban'},
    {'id': 11, 'name': 'Heritage Bank', 'code': '030', 'slug': 'heritage-bank', 'country': 'Nigeria', 'currency': 'NGN', 'type': 'nuban'},
    {'id': 12, 'name': 'Jaiz Bank', 'code': '301', 'slug': 'jaiz-bank', 'country': 'Nigeria', 'currency': 'NGN', 'type': 'nuban'},
    {'id': 13, 'name': 'Keystone Bank', 'code': '082', 'slug': 'keystone-bank', 'country': 'Nigeria', 'currency': 'NGN', 'type': 'nuban'},
    {'id': 14, 'name': 'Kuda Bank', 'code': '50211', 'slug': 'kuda-bank', 'country': 'Nigeria', 'currency': 'NGN', 'type': 'nuban'},
    {'id': 15, 'name': 'Moniepoint MFB', 'code': '50515', 'slug': 'moniepoint-mfb', 'country': 'Nigeria', 'currency': 'NGN', 'type': 'nuban'},
    {'id': 16, 'name': 'OPay', 'code': '999992', 'slug': 'opay', 'country': 'Nigeria', 'currency': 'NGN', 'type': 'nuban'},
    {'id': 17, 'name': 'Paga', 'code': '100002', 'slug': 'paga', 'country': 'Nigeria', 'currency': 'NGN', 'type': 'nuban'},
    {'id': 18, 'name': 'PalmPay', 'code': '999991', 'slug': 'palmpay', 'country': 'Nigeria', 'currency': 'NGN', 'type': 'nuban'},
    {'id': 19, 'name': 'Parallex Bank', 'code': '104', 'slug': 'parallex-bank', 'country': 'Nigeria', 'currency': 'NGN', 'type': 'nuban'},
    {'id': 20, 'name': 'Polaris Bank', 'code': '076', 'slug': 'polaris-bank', 'country': 'Nigeria', 'currency': 'NGN', 'type': 'nuban'},
    {'id': 21, 'name': 'Providus Bank', 'code': '101', 'slug': 'providus-bank', 'country': 'Nigeria', 'currency': 'NGN', 'type': 'nuban'},
    {'id': 22, 'name': 'Stanbic IBTC Bank', 'code': '221', 'slug': 'stanbic-ibtc-bank', 'country': 'Nigeria', 'currency': 'NGN', 'type': 'nuban'},
    {'id': 23, 'name': 'Standard Chartered Bank', 'code': '068', 'slug': 'standard-chartered-bank', 'country': 'Nigeria', 'currency': 'NGN', 'type': 'nuban'},
    {'id': 24, 'name': 'Sterling Bank', 'code': '232', 'slug': 'sterling-bank', 'country': 'Nigeria', 'currency': 'NGN', 'type': 'nuban'},
    {'id': 25, 'name': 'SunTrust Bank', 'code': '100', 'slug': 'suntrust-bank', 'country': 'Nigeria', 'currency': 'NGN', 'type': 'nuban'},
    {'id': 26, 'name': 'TAJ Bank', 'code': '302', 'slug': 'taj-bank', 'country': 'Nigeria', 'currency': 'NGN', 'type': 'nuban'},
    {'id': 27, 'name': 'Titan Trust Bank', 'code': '102', 'slug': 'titan-trust-bank', 'country': 'Nigeria', 'currency': 'NGN', 'type': 'nuban'},
    {'id': 28, 'name': 'Union Bank of Nigeria', 'code': '032', 'slug': 'union-bank-of-nigeria', 'country': 'Nigeria', 'currency': 'NGN', 'type': 'nuban'},
    {'id': 29, 'name': 'United Bank For Africa', 'code': '033', 'slug': 'united-bank-for-africa', 'country': 'Nigeria', 'currency': 'NGN', 'type': 'nuban'},
    {'id': 30, 'name': 'Unity Bank', 'code': '215', 'slug': 'unity-bank', 'country': 'Nigeria', 'currency': 'NGN', 'type': 'nuban'},
    {'id': 31, 'name': 'VFD Microfinance Bank', 'code': '566', 'slug': 'vfd-microfinance-bank', 'country': 'Nigeria', 'currency': 'NGN', 'type': 'nuban'},
    {'id': 32, 'name': 'Wema Bank', 'code': '035', 'slug': 'wema-bank', 'country': 'Nigeria', 'currency': 'NGN', 'type': 'nuban'},
    {'id': 33, 'name': 'Zenith Bank', 'code': '057', 'slug': 'zenith-bank', 'country': 'Nigeria', 'currency': 'NGN', 'type': 'nuban'},
    {'id': 34, 'name': '9mobile 9Payment Service Bank', 'code': '120001', 'slug': '9mobile-9payment-service-bank', 'country': 'Nigeria', 'currency': 'NGN', 'type': 'nuban'},
    {'id': 35, 'name': 'Carbon', 'code': '565', 'slug': 'carbon', 'country': 'Nigeria', 'currency': 'NGN', 'type': 'nuban'},
    {'id': 36, 'name': 'Rubies MFB', 'code': '125', 'slug': 'rubies-mfb', 'country': 'Nigeria', 'currency': 'NGN', 'type': 'nuban'},
    {'id': 37, 'name': 'LAPO Microfinance Bank', 'code': '50549', 'slug': 'lapo-microfinance-bank', 'country': 'Nigeria', 'currency': 'NGN', 'type': 'nuban'},
    {'id': 38, 'name': 'Eyowo', 'code': '50126', 'slug': 'eyowo', 'country': 'Nigeria', 'currency': 'NGN', 'type': 'nuban'},
    {'id': 39, 'name': 'Sparkle Microfinance Bank', 'code': '51310', 'slug': 'sparkle-microfinance-bank', 'country': 'Nigeria', 'currency': 'NGN', 'type': 'nuban'},
  ];
}
