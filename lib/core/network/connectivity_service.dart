import 'package:connectivity_plus/connectivity_plus.dart';

/// Reports whether the device has a network connection.
///
/// Abstracted behind an interface, like `LocationService`, so tests can
/// drive connection changes with a fake instead of a platform channel.
abstract class ConnectivityService {
  /// Whether the device has a network connection right now. Needed on top
  /// of [onlineChanges] because that stream only reports *changes* — it
  /// says nothing about the state the app launched in.
  Future<bool> checkOnline();

  /// Emits `true` whenever the device gains a network connection and
  /// `false` whenever it loses it.
  Stream<bool> get onlineChanges;
}

class ConnectivityPlusService implements ConnectivityService {
  const ConnectivityPlusService();

  @override
  Future<bool> checkOnline() async {
    try {
      return _isOnline(await Connectivity().checkConnectivity());
    } catch (_) {
      // Can't tell — assume online so a real fetch decides, rather than
      // wrongly claiming the device is offline.
      return true;
    }
  }

  @override
  Stream<bool> get onlineChanges =>
      Connectivity().onConnectivityChanged.map(_isOnline).handleError((_) {});

  static bool _isOnline(List<ConnectivityResult> results) =>
      results.any((r) => r != ConnectivityResult.none);
}
