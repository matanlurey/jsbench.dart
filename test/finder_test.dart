// Copyright 2017, Google Inc.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:jsbench/src/finder.dart';
import 'package:test/test.dart';

void main() {
  test('should do nothing if archives not specified', () {
    final finder = new FileFinder(['output/**.dart.js']);
    expect(finder.include.map((g) => g.pattern), ['output/**.dart.js']);
  });

  test('should create synthetic includes for archives', () {
    final finder = new FileFinder(
      ['output/**.dart.js'],
      archive: ['tar'],
    );
    expect(
      finder.include.map((g) => g.pattern),
      ['output/**.dart.js', 'output/**.tar'],
    );
  });

  test('should find simple files on disk', () {
    final finder = new FileFinder(['test/_out/build/**.dart.js']);
    expect(finder.find(), ['./test/_out/build/foo.dart.js']);
    expect(
      finder.readAsString('./test/_out/build/foo.dart.js'),
      'function foo(){}',
    );
  });

  test('should find files on disk + in archives', () {
    final finder = new FileFinder(
      ['test/_out/build/**.dart.js'],
      archive: ['tar'],
    );
    expect(finder.find(), [
      './test/_out/build/foo.dart.js',
      './test/_out/build/build.tar/bar.dart.js'
    ]);
    expect(
      finder.readAsString('./test/_out/build/foo.dart.js'),
      'function foo(){}',
    );
    expect(
      finder.readAsString('./test/_out/build/build.tar/bar.dart.js'),
      'function bar(){}',
    );
  });
}
