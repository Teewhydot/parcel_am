import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/bank_info_entity.dart';

class BankInfoModel {
  final int id;
  final String name;
  final String code;
  final String slug;
  final String country;
  final String currency;
  final String type;
  final bool active;

  const BankInfoModel({
    required this.id,
    required this.name,
    required this.code,
    required this.slug,
    required this.country,
    required this.currency,
    required this.type,
    required this.active,
  });

  factory BankInfoModel.fromJson(Map<String, dynamic> json) {
    return BankInfoModel(
      id: json['id'] as int,
      name: json['name'] as String,
      code: json['code'] as String,
      slug: json['slug'] as String? ?? '',
      country: json['country'] as String? ?? 'Nigeria',
      currency: json['currency'] as String? ?? 'NGN',
      type: json['type'] as String? ?? 'nuban',
      active: json['active'] as bool? ?? true,
    );
  }

  factory BankInfoModel.fromFirestore(Map<String, dynamic> data) {
    return BankInfoModel(
      id: data['id'] as int,
      name: data['name'] as String,
      code: data['code'] as String,
      slug: data['slug'] as String? ?? '',
      country: data['country'] as String? ?? 'Nigeria',
      currency: data['currency'] as String? ?? 'NGN',
      type: data['type'] as String? ?? 'nuban',
      active: data['active'] as bool? ?? true,
    );
  }

  factory BankInfoModel.fromEntity(BankInfoEntity entity) {
    return BankInfoModel(
      id: entity.id,
      name: entity.name,
      code: entity.code,
      slug: entity.slug,
      country: entity.country,
      currency: entity.currency,
      type: entity.type,
      active: entity.active,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'slug': slug,
      'country': country,
      'currency': currency,
      'type': type,
      'active': active,
    };
  }

  BankInfoEntity toEntity() {
    return BankInfoEntity(
      id: id,
      name: name,
      code: code,
      slug: slug,
      country: country,
      currency: currency,
      type: type,
      active: active,
    );
  }

  BankInfoModel copyWith({
    int? id,
    String? name,
    String? code,
    String? slug,
    String? country,
    String? currency,
    String? type,
    bool? active,
  }) {
    return BankInfoModel(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
      slug: slug ?? this.slug,
      country: country ?? this.country,
      currency: currency ?? this.currency,
      type: type ?? this.type,
      active: active ?? this.active,
    );
  }
}
