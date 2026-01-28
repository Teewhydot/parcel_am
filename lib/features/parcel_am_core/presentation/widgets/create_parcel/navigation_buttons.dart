import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/app_button.dart';
import '../../../../../core/widgets/app_spacing.dart';
import '../../../../../core/widgets/app_text.dart';
import '../../../../../core/bloc/base/base_state.dart';
import '../../bloc/parcel/parcel_cubit.dart';
import '../../bloc/parcel/parcel_state.dart';

class NavigationButtons extends StatelessWidget {
  const NavigationButtons({
    super.key,
    required this.currentStep,
    required this.parcelBloc,
    required this.onNext,
    required this.onPrevious,
    required this.onCreateParcel,
    required this.isCreating,
  });

  final int currentStep;
  final ParcelCubit parcelBloc;
  final VoidCallback onNext;
  final VoidCallback onPrevious;
  final VoidCallback onCreateParcel;
  final bool isCreating;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ParcelCubit, BaseState<ParcelData>>(
      bloc: parcelBloc,
      builder: (context, state) {
        final isLoading = state is LoadingState<ParcelData> ||
            state is AsyncLoadingState<ParcelData>;
        return Container(
          padding: AppSpacing.paddingLG,
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(top: BorderSide(color: AppColors.outline)),
          ),
          child: Row(
            children: [
              if (currentStep > 0)
                Expanded(
                  child: AppButton.outline(
                    onPressed: isLoading ? null : onPrevious,
                    child: AppText.bodyMedium('Back', color: AppColors.primary),
                  ),
                ),
              if (currentStep > 0)
                AppSpacing.horizontalSpacing(SpacingSize.md),
              Expanded(
                child: AppButton.primary(
                  onPressed: isLoading
                      ? null
                      : () {
                          if (currentStep == 2) {
                            onCreateParcel();
                          } else {
                            onNext();
                          }
                        },
                  loading: isLoading && currentStep == 2,
                  child: AppText.bodyMedium(
                    currentStep == 2 ? 'Create Parcel' : 'Next',
                    color: AppColors.white,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
