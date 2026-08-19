import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Domain remains free of Flutter and Riverpod dependencies', () {
    final domainDirectory = Directory('lib/domain');
    final dartFiles = domainDirectory
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'));

    for (final file in dartFiles) {
      final source = file.readAsStringSync();
      expect(source, isNot(contains('package:flutter')));
      expect(source, isNot(contains('riverpod')));
    }
  });
}
