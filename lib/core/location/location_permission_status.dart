/// The device's current location-permission state, read without
/// triggering a permission request or a position fetch — e.g. for the
/// Settings screen to show a status label.
enum LocationPermissionStatus {
  granted,
  denied,
  deniedForever,
  serviceDisabled,
}
