import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

class NetworkService {
  NetworkService() : _connectivity = Connectivity();

  final Connectivity _connectivity;

  Stream<bool> get onlineChanges => _connectivity.onConnectivityChanged
      .map((results) => results.any((result) => result != ConnectivityResult.none))
      .distinct();

  Future<bool> get isOnline async {
    final results = await _connectivity.checkConnectivity();
    return results.any((result) => result != ConnectivityResult.none);
  }
}
