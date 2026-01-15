import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Service for monitoring network connectivity
class NetworkMonitorService {
  final Connectivity _connectivity = Connectivity();
  
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  final _connectivityController = StreamController<bool>.broadcast();
  
  bool _isConnected = true;
  
  /// Stream of connectivity changes (true = connected, false = disconnected)
  Stream<bool> get connectivityStream => _connectivityController.stream;
  
  /// Current connectivity status
  bool get isConnected => _isConnected;
  
  /// Initialize network monitoring
  Future<void> initialize() async {
    // Check initial connectivity
    final results = await _connectivity.checkConnectivity();
    _isConnected = _hasInternetConnection(results);

    debugPrint('NetworkMonitor: Initial connectivity: $_isConnected');

    // Listen to connectivity changes
    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      final wasConnected = _isConnected;
      _isConnected = _hasInternetConnection(results);

      if (wasConnected != _isConnected) {
        debugPrint('NetworkMonitor: Connectivity changed: $_isConnected');
        _connectivityController.add(_isConnected);
      }
    });
  }

  /// Check if connectivity result indicates internet connection
  bool _hasInternetConnection(List<ConnectivityResult> results) {
    return results.any((result) =>
      result == ConnectivityResult.mobile ||
      result == ConnectivityResult.wifi ||
      result == ConnectivityResult.ethernet
    );
  }
  
  /// Dispose resources
  void dispose() {
    _subscription?.cancel();
    _connectivityController.close();
  }
}

