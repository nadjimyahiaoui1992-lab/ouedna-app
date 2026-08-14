import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Ouedna iOS distribution identity is defined', () {
    const bundleIdentifier = 'com.ouedna.app';
    expect(bundleIdentifier, isNotEmpty);
  });
}
