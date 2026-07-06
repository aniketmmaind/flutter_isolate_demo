class CalculatePrime {
  static List<int> calculatePrimeNum(int limit) {
    List<int> primeList = [];

    for (int i = 2; i <= limit; i++) {
      if (_isPrime(i)) {
        primeList.add(i);
      }
    }

    return primeList;
  }

  static Future<List<int>> calculatePrimeNumF(int limit) async {
    List<int> primeList = [];

    for (int i = 2; i <= limit; i++) {
      if (_isPrime(i)) {
        primeList.add(i);
      }
    }

    return primeList;
  }

  static bool _isPrime(int n) {
    if (n < 2) return false;
    if (n % 2 == 0) return n == 2;

    for (int i = 3; i * i < n; i += 2) {
      if (n % i == 0) return false;
    }
    return true;
  }
}
