import 'package:chill/src/repository/blob/entropy.dart';
import 'package:test/test.dart';

void main() {
  test('entropies', () {
    expect(List.filled(1000, 0).entropy(), 0.0);
    expect(List.generate(1000, (i) => i % 2).entropy(), 0.125);
    expect(List.generate(256, (i) => i).entropy(), 1.0);
  });
}
