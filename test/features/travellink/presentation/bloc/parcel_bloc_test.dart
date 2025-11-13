import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:parcel_am/features/travellink/presentation/bloc/parcel/parcel_bloc.dart';
import 'package:parcel_am/features/travellink/presentation/bloc/parcel/parcel_event.dart';
import 'package:parcel_am/features/travellink/presentation/bloc/parcel/parcel_state.dart';
import 'package:parcel_am/features/travellink/domain/models/package_model.dart';

void main() {
  late ParcelBloc parcelBloc;

  setUp(() {
    parcelBloc = ParcelBloc();
  });

  tearDown(() {
    parcelBloc.close();
  });

  group('ParcelBloc', () {
    test('initial state is ParcelInitial', () {
      expect(parcelBloc.state, const ParcelInitial());
    });

    blocTest<ParcelBloc, ParcelState>(
      'emits [ParcelLoading, ParcelListLoaded] when ParcelListRequested is added',
      build: () => parcelBloc,
      act: (bloc) => bloc.add(const ParcelListRequested()),
      wait: const Duration(milliseconds: 600),
      expect: () => [
        const ParcelLoading(),
        const ParcelListLoaded([]),
      ],
    );

    blocTest<ParcelBloc, ParcelState>(
      'emits creating states with progress when ParcelCreateRequested is added',
      build: () => parcelBloc,
      act: (bloc) => bloc.add(ParcelCreateRequested(
        title: 'Test Parcel',
        description: 'Test Description',
        packageType: 'Documents',
        weight: 1.0,
        price: 1000.0,
        urgency: 'Standard',
        origin: LocationInfo(
          name: 'Origin',
          address: 'Origin Address',
          latitude: 0.0,
          longitude: 0.0,
        ),
        destination: LocationInfo(
          name: 'Destination',
          address: 'Destination Address',
          latitude: 0.0,
          longitude: 0.0,
        ),
      )),
      wait: const Duration(milliseconds: 1000),
      expect: () => [
        const ParcelCreating(progress: 0.3),
        const ParcelCreating(progress: 0.6),
        const ParcelCreating(progress: 1.0),
        isA<ParcelCreated>(),
      ],
    );

    test('parcelsStream emits parcel list updates', () async {
      final origin = LocationInfo(
        name: 'Origin',
        address: 'Origin Address',
        latitude: 0.0,
        longitude: 0.0,
      );
      final destination = LocationInfo(
        name: 'Destination',
        address: 'Destination Address',
        latitude: 0.0,
        longitude: 0.0,
      );

      final streamFuture = parcelBloc.parcelsStream.first;

      parcelBloc.add(ParcelCreateRequested(
        title: 'Test Parcel',
        description: 'Test Description',
        packageType: 'Documents',
        weight: 1.0,
        price: 1000.0,
        urgency: 'Standard',
        origin: origin,
        destination: destination,
      ));

      await Future.delayed(const Duration(milliseconds: 1000));

      final parcels = await streamFuture;
      expect(parcels.length, 1);
      expect(parcels.first.title, 'Test Parcel');
    });
  });
}
