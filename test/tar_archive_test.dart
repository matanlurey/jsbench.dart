// Copyright 2017, Google Inc.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:jsbench/src/finder.dart';
import 'package:test/test.dart';

void main() {
  const tar = const TarArchiveFormat();

  test('should list files in test.json.tar', () {
    final reader = tar.read('test/_files/test.json.tar');
    expect(reader.listFiles(), ['test.json']);
  });

  test('should read files in test.json.tar', () {
    final reader = tar.read('test/_files/test.json.tar');
    expect(reader.readAsString('test.json'), '{"Hello": "World"}\n');
  });
}
