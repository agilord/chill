import 'dart:math';

final _log256 = log(256);

extension EntropyExt on List<int> {
  double entropy() {
    final counts = List.filled(256, 0);
    for (final b in this) {
      counts[b]++;
    }
    double r = 0.0;
    for (var i = 0; i < 256; i++) {
      final c = counts[i];
      if (c == 0) continue;
      final p = c / length;
      r -= p * log(p) / _log256;
    }
    return r;
  }
}
