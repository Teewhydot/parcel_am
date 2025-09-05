import 'package:flutter/services.dart';

class NigerianPhoneFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    
    // Remove all non-digit characters except +
    final digitsOnly = text.replaceAll(RegExp(r'[^\d+]'), '');
    
    // If user starts typing without +234, add it
    String formatted = digitsOnly;
    
    if (digitsOnly.isEmpty) {
      formatted = '+234 ';
    } else if (digitsOnly == '+') {
      formatted = '+234 ';
    } else if (digitsOnly.startsWith('+234')) {
      // Format +234XXXXXXXXXX to +234 XXX XXX XXXX
      final digits = digitsOnly.substring(4);
      formatted = '+234';
      
      if (digits.isNotEmpty) {
        formatted += ' ${digits.substring(0, digits.length.clamp(0, 3))}';
        
        if (digits.length > 3) {
          formatted += ' ${digits.substring(3, digits.length.clamp(3, 6))}';
          
          if (digits.length > 6) {
            formatted += ' ${digits.substring(6, digits.length.clamp(6, 10))}';
          }
        }
      } else {
        formatted += ' ';
      }
    } else if (digitsOnly.startsWith('234')) {
      // Handle case where user types 234XXXXXXXXXX
      final digits = digitsOnly.substring(3);
      formatted = '+234';
      
      if (digits.isNotEmpty) {
        formatted += ' ${digits.substring(0, digits.length.clamp(0, 3))}';
        
        if (digits.length > 3) {
          formatted += ' ${digits.substring(3, digits.length.clamp(3, 6))}';
          
          if (digits.length > 6) {
            formatted += ' ${digits.substring(6, digits.length.clamp(6, 10))}';
          }
        }
      } else {
        formatted += ' ';
      }
    } else if (digitsOnly.startsWith('0')) {
      // Handle Nigerian local format 0XXXXXXXXXX
      final digits = digitsOnly.substring(1);
      formatted = '+234';
      
      if (digits.isNotEmpty) {
        formatted += ' ${digits.substring(0, digits.length.clamp(0, 3))}';
        
        if (digits.length > 3) {
          formatted += ' ${digits.substring(3, digits.length.clamp(3, 6))}';
          
          if (digits.length > 6) {
            formatted += ' ${digits.substring(6, digits.length.clamp(6, 10))}';
          }
        }
      } else {
        formatted += ' ';
      }
    } else if (digitsOnly.length <= 10 && !digitsOnly.startsWith('+')) {
      // Handle case where user types the number without country code or 0
      formatted = '+234';
      
      if (digitsOnly.isNotEmpty) {
        formatted += ' ${digitsOnly.substring(0, digitsOnly.length.clamp(0, 3))}';
        
        if (digitsOnly.length > 3) {
          formatted += ' ${digitsOnly.substring(3, digitsOnly.length.clamp(3, 6))}';
          
          if (digitsOnly.length > 6) {
            formatted += ' ${digitsOnly.substring(6, digitsOnly.length.clamp(6, 10))}';
          }
        }
      } else {
        formatted += ' ';
      }
    }
    
    // Limit to Nigerian phone format: +234 XXX XXX XXXX (max 18 characters)
    if (formatted.length > 18) {
      formatted = formatted.substring(0, 18);
    }
    
    final selection = TextSelection.collapsed(offset: formatted.length);
    
    return TextEditingValue(
      text: formatted,
      selection: selection,
    );
  }
}

class OTPFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    
    // Remove all non-digit characters
    final digitsOnly = text.replaceAll(RegExp(r'[^\d]'), '');
    
    // Limit to 6 digits
    final formatted = digitsOnly.length > 6 
        ? digitsOnly.substring(0, 6)
        : digitsOnly;
    
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}