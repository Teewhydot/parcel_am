import 'package:equatable/equatable.dart';

class TransactionFilter extends Equatable {
  final String? status;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? searchQuery;

  const TransactionFilter({
    this.status,
    this.startDate,
    this.endDate,
    this.searchQuery,
  });

  const TransactionFilter.empty()
      : status = null,
        startDate = null,
        endDate = null,
        searchQuery = null;

  TransactionFilter copyWith({
    String? status,
    DateTime? startDate,
    DateTime? endDate,
    String? searchQuery,
    bool clearStatus = false,
    bool clearStartDate = false,
    bool clearEndDate = false,
    bool clearSearchQuery = false,
  }) {
    return TransactionFilter(
      status: clearStatus ? null : (status ?? this.status),
      startDate: clearStartDate ? null : (startDate ?? this.startDate),
      endDate: clearEndDate ? null : (endDate ?? this.endDate),
      searchQuery: clearSearchQuery ? null : (searchQuery ?? this.searchQuery),
    );
  }

  bool get hasActiveFilters =>
      status != null || startDate != null || endDate != null || (searchQuery?.isNotEmpty ?? false);

  @override
  List<Object?> get props => [status, startDate, endDate, searchQuery];
}

enum TransactionDateRange {
  last7Days,
  last30Days,
  last90Days,
  custom,
}

extension TransactionDateRangeExtension on TransactionDateRange {
  String get label {
    switch (this) {
      case TransactionDateRange.last7Days:
        return 'Last 7 Days';
      case TransactionDateRange.last30Days:
        return 'Last 30 Days';
      case TransactionDateRange.last90Days:
        return 'Last 90 Days';
      case TransactionDateRange.custom:
        return 'Custom Range';
    }
  }

  DateTime? get startDate {
    final now = DateTime.now();
    switch (this) {
      case TransactionDateRange.last7Days:
        return now.subtract(const Duration(days: 7));
      case TransactionDateRange.last30Days:
        return now.subtract(const Duration(days: 30));
      case TransactionDateRange.last90Days:
        return now.subtract(const Duration(days: 90));
      case TransactionDateRange.custom:
        return null;
    }
  }
}
