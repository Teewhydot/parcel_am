import 'package:equatable/equatable.dart';

/// Entity representing a Nigerian bank from Paystack
class BankInfoEntity extends Equatable {
  final int id;
  final String name;
  final String code;
  final String slug;
  final String country;
  final String currency;
  final String type;
  final bool active;

  const BankInfoEntity({
    required this.id,
    required this.name,
    required this.code,
    required this.slug,
    required this.country,
    required this.currency,
    required this.type,
    required this.active,
  });

  /// Support search/filter by bank name
  bool matchesSearch(String query) {
    final lowerQuery = query.toLowerCase();
    return name.toLowerCase().contains(lowerQuery) ||
           code.toLowerCase().contains(lowerQuery) ||
           slug.toLowerCase().contains(lowerQuery);
  }

  BankInfoEntity copyWith({
    int? id,
    String? name,
    String? code,
    String? slug,
    String? country,
    String? currency,
    String? type,
    bool? active,
  }) {
    return BankInfoEntity(
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

  @override
  List<Object?> get props => [id, name, code, slug, country, currency, type, active];
}
