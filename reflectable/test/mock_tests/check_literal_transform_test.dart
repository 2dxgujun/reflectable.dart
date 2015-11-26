// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library reflectable.check_literal_transform_test;

/// Test the literal output of the transformation for a few simple cases.

import "package:reflectable/test_transform.dart";
import "package:reflectable/transformer.dart";
import "package:unittest/unittest.dart";
import 'package:barback/src/transformer/barback_settings.dart';

var useReflect = [
  {
    "a|main.dart": """
import 'package:reflectable/reflectable.dart';

class MyReflectable extends Reflectable {
  const MyReflectable(): super(newInstanceCapability);
}

@MyReflectable()
class A {}

main() {
  InstanceMirror instanceMirror = myReflectable.reflect(new A());
}
"""
  },
  {
    "a|main_reflectable_original_main.dart": """
import 'package:reflectable/reflectable.dart';

class MyReflectable extends Reflectable {
  const MyReflectable(): super(newInstanceCapability);
}

@MyReflectable()
class A {}

main() {
  InstanceMirror instanceMirror = myReflectable.reflect(new A());
}
""",
    "a|main.dart": """
// This file has been generated by the reflectable package.
// https://github.com/dart-lang/reflectable.

library reflectable_generated_main_library;

import "dart:core";
import "main_reflectable_original_main.dart" as original show main;
import 'main_reflectable_original_main.dart' as prefix0;

import "package:reflectable/mirrors.dart" as m;
import "package:reflectable/src/reflectable_transformer_based.dart" as r;
import "package:reflectable/reflectable.dart" show isTransformed;

export "main_reflectable_original_main.dart" hide main;

main() {
  _initializeReflectable();
  return original.main();
}

final _data = {
  const prefix0.MyReflectable(): new r.ReflectorData(<m.TypeMirror>[
    new r.NonGenericClassMirrorImpl(
        r"A",
        r".A",
        7,
        0,
        const prefix0.MyReflectable(),
        const <int>[-1],
        const <int>[],
        const <int>[],
        -1,
        {},
        {},
        {r"": () => new prefix0.A()},
        -1,
        0,
        const <int>[],
        null)
  ], <m.DeclarationMirror>[
    new r.MethodMirrorImpl(r"", 64, 0, -1, prefix0.A, null, const <int>[],
        const prefix0.MyReflectable(), null)
  ], <m.ParameterMirror>[], const <Type>[
    prefix0.A
  ], {}, {}, null)
};

_initializeReflectable() {
  if (!isTransformed) {
    throw new UnsupportedError(
        "The transformed code is running with the untransformed "
        "reflectable package. Remember to set your package-root to "
        "'build/.../packages'.");
  }
  r.data = _data;
}
"""
  }
];

checkTransform(List maps) async {
  Map<String, String> inputs = maps[0];
  Map<String, String> expectedOutputs = maps[1];
  TestAggregateTransform transform = new TestAggregateTransform(inputs);
  ReflectableTransformer transformer =
      new ReflectableTransformer.asPlugin(new BarbackSettings({
    "entry_points": ["main.dart"],
    "formatted": true,
  }, BarbackMode.RELEASE));

  // Test `declareOutputs`.
  TestDeclaringTransform declaringTransform =
      new TestDeclaringTransform(inputs);
  await transformer.declareOutputs(declaringTransform);
  expect(declaringTransform.outputs, new Set.from(expectedOutputs.keys));
  expect(declaringTransform.consumed, new Set.from([]));

  // Test `apply`.
  await transformer.apply(transform);
  Map<String, String> outputs = await transform.outputMap();
  expect(transform.messages.isEmpty, true);
  expect(outputs.length, expectedOutputs.length);
  outputs.forEach((key, value) {
    // The error message is nicer when the strings are compared separately
    // instead of comparing Maps.
    expect(value, expectedOutputs[key]);
  });
}

main() async {
  test("Check transforms", () async {
    await checkTransform(useReflect);
  });
}
