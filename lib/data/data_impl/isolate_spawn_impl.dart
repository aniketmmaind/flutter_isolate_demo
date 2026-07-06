import 'dart:isolate';

import 'package:isolate_demo/data/source/calculate_prime.dart';

class IsolateSpawnImpl {
  static primeWorker(SendPort sendPort) {
    final primes = CalculatePrime.calculatePrimeNum(500000);

    sendPort.send(primes);
  }
}
