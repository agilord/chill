import 'package:cryptography/cryptography.dart';

Future<void> main() async {
  final values = <String>[];
  for (var i = 0; i <= 255; i++) {
    final hash = await Sha256().hash([i]);
    values.add(hash.bytes
        .take(4)
        .map((e) => e.toRadixString(16).padLeft(2, '0'))
        .join());
  }
  for (var i = 0; i <= 255; i += 6) {
    final line = values.skip(i).take(6).map((e) => '0x$e,').join(' ');
    print('  $line // ');
  }
}
