import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/value_objects/transaction_filter.dart';

class TransactionFilterBar extends StatelessWidget {
  final TransactionFilter currentFilter;
  final Function(TransactionFilter) onFilterChanged;

  const TransactionFilterBar({
    super.key,
    required this.currentFilter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Filter by:',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildStatusFilter(context),
                      const SizedBox(width: 8),
                      _buildDateRangeFilter(context),
                      if (currentFilter.hasActiveFilters) ...[
                        const SizedBox(width: 8),
                        _buildClearAllButton(context),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (currentFilter.hasActiveFilters)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Wrap(
                spacing: 8,
                runSpacing: 4,
                children: _buildActiveFilterChips(context),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusFilter(BuildContext context) {
    return PopupMenuButton<String>(
      initialValue: currentFilter.status,
      onSelected: (value) {
        final newFilter = value == 'all'
            ? currentFilter.copyWith(clearStatus: true)
            : currentFilter.copyWith(status: value);
        onFilterChanged(newFilter);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: currentFilter.status != null
              ? Theme.of(context).primaryColor.withOpacity(0.1)
              : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: currentFilter.status != null
                ? Theme.of(context).primaryColor
                : Colors.transparent,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.filter_list,
              size: 16,
              color: currentFilter.status != null
                  ? Theme.of(context).primaryColor
                  : Colors.grey[700],
            ),
            const SizedBox(width: 4),
            Text(
              currentFilter.status != null
                  ? _formatStatus(currentFilter.status!)
                  : 'Status',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: currentFilter.status != null
                    ? Theme.of(context).primaryColor
                    : Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
      itemBuilder: (context) => [
        const PopupMenuItem(value: 'all', child: Text('All')),
        const PopupMenuItem(value: 'success', child: Text('Completed')),
        const PopupMenuItem(value: 'pending', child: Text('Pending')),
        const PopupMenuItem(value: 'failed', child: Text('Failed')),
      ],
    );
  }

  Widget _buildDateRangeFilter(BuildContext context) {
    return PopupMenuButton<TransactionDateRange>(
      onSelected: (value) async {
        if (value == TransactionDateRange.custom) {
          await _showCustomDateRangePicker(context);
        } else {
          final newFilter = currentFilter.copyWith(
            startDate: value.startDate,
            endDate: DateTime.now(),
          );
          onFilterChanged(newFilter);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: (currentFilter.startDate != null || currentFilter.endDate != null)
              ? Theme.of(context).primaryColor.withOpacity(0.1)
              : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: (currentFilter.startDate != null || currentFilter.endDate != null)
                ? Theme.of(context).primaryColor
                : Colors.transparent,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.calendar_today,
              size: 16,
              color: (currentFilter.startDate != null || currentFilter.endDate != null)
                  ? Theme.of(context).primaryColor
                  : Colors.grey[700],
            ),
            const SizedBox(width: 4),
            Text(
              _getDateRangeText(),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: (currentFilter.startDate != null || currentFilter.endDate != null)
                    ? Theme.of(context).primaryColor
                    : Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: TransactionDateRange.last7Days,
          child: Text(TransactionDateRange.last7Days.label),
        ),
        PopupMenuItem(
          value: TransactionDateRange.last30Days,
          child: Text(TransactionDateRange.last30Days.label),
        ),
        PopupMenuItem(
          value: TransactionDateRange.last90Days,
          child: Text(TransactionDateRange.last90Days.label),
        ),
        PopupMenuItem(
          value: TransactionDateRange.custom,
          child: Text(TransactionDateRange.custom.label),
        ),
      ],
    );
  }

  Widget _buildClearAllButton(BuildContext context) {
    return InkWell(
      onTap: () => onFilterChanged(const TransactionFilter.empty()),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.clear,
              size: 16,
              color: Colors.red.shade700,
            ),
            const SizedBox(width: 4),
            Text(
              'Clear All',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.red.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildActiveFilterChips(BuildContext context) {
    final chips = <Widget>[];

    if (currentFilter.status != null) {
      chips.add(_buildActiveChip(
        context,
        'Status: ${_formatStatus(currentFilter.status!)}',
        () => onFilterChanged(currentFilter.copyWith(clearStatus: true)),
      ));
    }

    if (currentFilter.startDate != null || currentFilter.endDate != null) {
      chips.add(_buildActiveChip(
        context,
        'Date: ${_formatDateRange()}',
        () => onFilterChanged(
          currentFilter.copyWith(clearStartDate: true, clearEndDate: true),
        ),
      ));
    }

    return chips;
  }

  Widget _buildActiveChip(BuildContext context, String label, VoidCallback onRemove) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(width: 4),
          InkWell(
            onTap: onRemove,
            child: Icon(
              Icons.close,
              size: 14,
              color: Theme.of(context).primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showCustomDateRangePicker(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: now,
      initialDateRange: DateTimeRange(
        start: currentFilter.startDate ?? now.subtract(const Duration(days: 30)),
        end: currentFilter.endDate ?? now,
      ),
    );

    if (picked != null) {
      final newFilter = currentFilter.copyWith(
        startDate: picked.start,
        endDate: picked.end,
      );
      onFilterChanged(newFilter);
    }
  }

  String _formatStatus(String status) {
    switch (status.toLowerCase()) {
      case 'success':
      case 'completed':
        return 'Completed';
      case 'pending':
        return 'Pending';
      case 'failed':
      case 'expired':
        return 'Failed';
      default:
        return status;
    }
  }

  String _getDateRangeText() {
    if (currentFilter.startDate != null && currentFilter.endDate != null) {
      final days = currentFilter.endDate!.difference(currentFilter.startDate!).inDays;
      if (days == 7) return 'Last 7 Days';
      if (days == 30) return 'Last 30 Days';
      if (days == 90) return 'Last 90 Days';
      return _formatDateRange();
    }
    return 'Date';
  }

  String _formatDateRange() {
    if (currentFilter.startDate != null && currentFilter.endDate != null) {
      final formatter = DateFormat('MMM d');
      return '${formatter.format(currentFilter.startDate!)} - ${formatter.format(currentFilter.endDate!)}';
    } else if (currentFilter.startDate != null) {
      return 'From ${DateFormat('MMM d').format(currentFilter.startDate!)}';
    } else if (currentFilter.endDate != null) {
      return 'Until ${DateFormat('MMM d').format(currentFilter.endDate!)}';
    }
    return '';
  }
}
