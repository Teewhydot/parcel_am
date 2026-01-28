import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/bloc/managers/bloc_manager.dart';
import '../../../../core/routes/routes.dart';
import '../../../../core/services/navigation_service/nav_config.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_spacing.dart';
import '../../../../core/widgets/app_text.dart';
import '../../../../core/bloc/base/base_state.dart';
import '../../../../core/helpers/user_extensions.dart';
import '../../../../injection_container.dart';
import '../bloc/parcel/parcel_cubit.dart';
import '../bloc/parcel/parcel_state.dart';
import '../widgets/parcel_list/parcel_card.dart';
import '../widgets/parcel_list/parcel_empty_state.dart';
import '../widgets/parcel_list/parcel_error_state.dart';

class ParcelListScreen extends StatefulWidget {
  const ParcelListScreen({super.key});

  @override
  State<ParcelListScreen> createState() => _ParcelListScreenState();
}

class _ParcelListScreenState extends State<ParcelListScreen> {
  late ParcelCubit _parcelBloc;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _parcelBloc = ParcelCubit();

    _currentUserId = context.currentUserId;
    if (_currentUserId != null) {
      _parcelBloc.loadUserParcels(_currentUserId!);
    }
  }

  @override
  void dispose() {
    _parcelBloc.close();
    super.dispose();
  }

  void _refreshParcels() {
    if (_currentUserId != null) {
      _parcelBloc.loadUserParcels(_currentUserId!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _parcelBloc,
      child: Scaffold(
        appBar: AppBar(
          title: AppText.titleLarge('My Parcels'),
          backgroundColor: AppColors.surface,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _refreshParcels,
            ),
          ],
        ),
        body: BlocManager<ParcelCubit, BaseState<ParcelData>>(
          bloc: _parcelBloc,
          builder: (context, state) {
            if (state is LoadingState<ParcelData>) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is ErrorState<ParcelData>) {
              return ParcelErrorState(
                errorMessage: state.errorMessage,
                onRetry: _refreshParcels,
              );
            }

            final parcels = state.data?.userParcels ?? [];

            if (parcels.isEmpty) {
              return const ParcelEmptyState();
            }

            return RefreshIndicator(
              onRefresh: () async {
                _refreshParcels();
              },
              child: ListView.builder(
                padding: AppSpacing.paddingLG,
                itemCount: parcels.length,
                itemBuilder: (context, index) {
                  final parcel = parcels[index];
                  return ParcelListCard(parcel: parcel);
                },
              ),
            );
          },
          child: const SizedBox.shrink(),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            sl<NavigationService>().navigateTo(Routes.createParcel);
          },
          backgroundColor: AppColors.primary,
          child: const Icon(Icons.add, color: AppColors.white),
        ),
      ),
    );
  }
}
