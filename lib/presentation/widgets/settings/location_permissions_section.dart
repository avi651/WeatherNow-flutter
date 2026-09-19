import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:weather_now_flutter/core/constants/app_strings.dart';

import '../../../core/location/location_permission_status.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../di/providers.dart';
import '../../providers/location_permission_status_provider.dart';
import 'settings_section_card.dart';

/// Shows the device's current location-permission status and a way to
/// manage it — requesting it in-app when it's simply never been decided,
/// or opening the relevant system settings screen when only the OS can
/// grant it (permanently denied, or location services themselves off).
class LocationPermissionsSection extends ConsumerWidget {
  const LocationPermissionsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusAsync = ref.watch(locationPermissionStatusProvider);

    return SettingsSectionCard(
      title: AppStrings.locationAndPermissions,
      icon: Icons.location_on_outlined,
      children: [
        statusAsync.when(
          data: (status) => _StatusRow(
            label: _labelFor(status),
            granted: status == LocationPermissionStatus.granted,
          ),
          loading: () => const _StatusRow(
            label: AppStrings.permissionChecking,
            granted: false,
          ),
          error: (_, _) => const _StatusRow(
            label: AppStrings.permissionUnknown,
            granted: false,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        OutlinedButton.icon(
          key: const Key('manageLocationPermissionButton'),
          onPressed: () => _handleTap(ref, statusAsync.value),
          icon: const Icon(Icons.settings_outlined, size: 18),
          label: const Text(AppStrings.manageLocationPermission),
        ),
      ],
    );
  }

  Future<void> _handleTap(
    WidgetRef ref,
    LocationPermissionStatus? status,
  ) async {
    final service = ref.read(locationServiceProvider);

    switch (status) {
      case LocationPermissionStatus.serviceDisabled:
        await service.openLocationSettings();
      case LocationPermissionStatus.deniedForever:
        await service.openAppSettings();
      case LocationPermissionStatus.denied:
      case LocationPermissionStatus.granted:
      case null:
        await service.requestPermission();
    }

    ref.invalidate(locationPermissionStatusProvider);
  }

  String _labelFor(LocationPermissionStatus status) {
    return switch (status) {
      LocationPermissionStatus.granted => AppStrings.permissionAllowed,
      LocationPermissionStatus.denied => AppStrings.permissionNotAllowedYet,
      LocationPermissionStatus.deniedForever => AppStrings.permissionDenied,
      LocationPermissionStatus.serviceDisabled =>
        AppStrings.locationServicesOff,
    };
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({required this.label, required this.granted});

  final String label;
  final bool granted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(
          granted ? Icons.check_circle : Icons.error_outline,
          size: 16,
          color: granted ? Colors.green : theme.colorScheme.error,
        ),
        const SizedBox(width: AppSpacing.xs),
        Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
      ],
    );
  }
}
