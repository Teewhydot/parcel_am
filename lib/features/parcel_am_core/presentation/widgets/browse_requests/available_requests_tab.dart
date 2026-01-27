import 'package:dartz/dartz.dart' show Either;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../../../../../core/errors/failures.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/app_input.dart';
import '../../../../../core/widgets/app_text.dart';
import '../../../domain/entities/parcel_entity.dart';
import '../../bloc/parcel/parcel_cubit.dart';
import 'route_filter_tabs.dart';
import 'request_card.dart';
import 'empty_state.dart';
import 'error_state.dart';

class AvailableRequestsTab extends StatefulWidget {
  const AvailableRequestsTab({super.key});

  @override
  State<AvailableRequestsTab> createState() => _AvailableRequestsTabState();
}

class _AvailableRequestsTabState extends State<AvailableRequestsTab> {
  int _selectedRouteIndex = 0;
  final List<String> _routes = ['All Routes', 'Lagos', 'Abuja', 'Port Harcourt'];
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ParcelEntity> _filterParcels(List<ParcelEntity> parcels) {
    var filtered = parcels;

    if (_selectedRouteIndex > 0) {
      final selectedRoute = _routes[_selectedRouteIndex];
      filtered = filtered.where((parcel) {
        final origin = parcel.route.origin.toLowerCase();
        final destination = parcel.route.destination.toLowerCase();
        final route = selectedRoute.toLowerCase();
        return origin.contains(route) || destination.contains(route);
      }).toList();
    }

    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((parcel) {
        final origin = parcel.route.origin.toLowerCase();
        final destination = parcel.route.destination.toLowerCase();
        final description = (parcel.description ?? '').toLowerCase();
        final category = (parcel.category ?? '').toLowerCase();

        return origin.contains(_searchQuery) ||
            destination.contains(_searchQuery) ||
            description.contains(_searchQuery) ||
            category.contains(_searchQuery);
      }).toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: AppInput(
            controller: _searchController,
            hintText: 'Search by route or package type...',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                    },
                  )
                : null,
          ),
        ),
        RouteFilterTabs(
          routes: _routes,
          selectedIndex: _selectedRouteIndex,
          onSelected: (index) => setState(() => _selectedRouteIndex = index),
        ),
        Expanded(
          child: StreamBuilder<Either<Failure, List<ParcelEntity>>>(
            stream: context.read<ParcelCubit>().watchAvailableParcels(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return ErrorState(
                  message: snapshot.error.toString(),
                  onRetry: () => setState(() {}),
                );
              }

              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              return snapshot.data!.fold(
                (failure) => ErrorState(message: failure.failureMessage),
                (availableParcels) {
                  final filteredParcels = _filterParcels(availableParcels);

                  if (availableParcels.isEmpty) {
                    return const EmptyState(
                      icon: Icons.inventory_2_outlined,
                      title: 'No requests available',
                      subtitle: 'Check back later for new delivery requests',
                    );
                  }

                  if (filteredParcels.isEmpty) {
                    return const EmptyState(
                      icon: Icons.search_off,
                      title: 'No matching requests',
                      subtitle: 'Try adjusting your filters or search',
                    );
                  }

                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: AppText.bodyMedium(
                            '${filteredParcels.length} request${filteredParcels.length == 1 ? '' : 's'} available',
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ),
                      Expanded(
                        child: AnimationLimiter(
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: filteredParcels.length,
                            itemBuilder: (context, index) {
                              final parcel = filteredParcels[index];
                              return AnimationConfiguration.staggeredList(
                                position: index,
                                duration: const Duration(milliseconds: 375),
                                child: SlideAnimation(
                                  verticalOffset: 50.0,
                                  child: FadeInAnimation(
                                    child: RequestCard(parcel: parcel),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
