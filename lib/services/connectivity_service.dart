import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class OfflineException implements Exception {
  final String message;
  const OfflineException([this.message = 'No internet connection available']);

  @override
  String toString() => 'OfflineException: $message';
}

abstract class ConnectivityService {
  Future<bool> isConnected();
}

class ConnectivityPlusService implements ConnectivityService {
  final Connectivity _connectivity;

  ConnectivityPlusService({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity();

  @override
  Future<bool> isConnected() async {
    final results = await _connectivity.checkConnectivity();
    return results.any((r) => r != ConnectivityResult.none);
  }
}

final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  return ConnectivityPlusService();
});
