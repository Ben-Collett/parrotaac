#!/usr/bin/env python3
import unittest
import os
import sys
import tempfile
import shutil
from pathlib import Path
from unittest.mock import patch, MagicMock

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from event_table_builder import (
    get_project_root,
    remove_comments_and_strings,
    find_imports,
    parse_value,
    parse_dart_classes,
    generate_output,
    validate_classes,
    Method,
    Constructor,
    DartClass,
)


class TestGetProjectRoot(unittest.TestCase):
    def test_finds_project_root_with_pubspec(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            project_dir = Path(tmpdir) / "test_project"
            project_dir.mkdir()
            subdir = project_dir / "subdir"
            subdir.mkdir(parents=True)
            (project_dir / "pubspec.yaml").write_text("name: test")

            original_cwd = os.getcwd()
            try:
                os.chdir(subdir)
                result = get_project_root()
                self.assertEqual(result, project_dir)
            finally:
                os.chdir(original_cwd)

    def test_raises_error_when_no_pubspec(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            original_cwd = os.getcwd()
            try:
                os.chdir(tmpdir)
                with self.assertRaises(RuntimeError) as ctx:
                    get_project_root()
                self.assertIn("no project root found", str(ctx.exception))
            finally:
                os.chdir(original_cwd)


class TestRemoveCommentsAndStrings(unittest.TestCase):
    def test_removes_single_line_comments(self):
        content = "void foo() // this is a comment\nint x = 1;"
        result = remove_comments_and_strings(content)
        self.assertNotIn("//", result)
        self.assertIn("int x = 1", result)

    def test_removes_multiline_strings_triple_quote(self):
        content = '''void foo() {
  String s = """this is
  multiline""";
  int x = 1;
}'''
        result = remove_comments_and_strings(content)
        self.assertNotIn(
            """this is
  multiline""",
            result,
        )
        self.assertIn("int x = 1", result)

    def test_preserves_code_between_strings(self):
        content = """void foo() {
  String a = "hello";
  int x = 1;
  String b = "world";
}"""
        result = remove_comments_and_strings(content)
        self.assertIn("int x = 1", result)

    def test_preserves_single_quoted_strings(self):
        content = "String s = 'hello world';"
        result = remove_comments_and_strings(content)
        self.assertIn("'hello world'", result)

    def test_removes_multiline_strings_single_quote(self):
        content = "String s = '''this is\n  multiline''';"
        result = remove_comments_and_strings(content)
        self.assertNotIn("this is", result)


class TestFindImports(unittest.TestCase):
    def test_finds_simple_imports(self):
        content = """import 'package:flutter/material.dart';
import 'dart:async';
import "package:my_app/file.dart";
"""
        result = find_imports(content)
        self.assertIn("package:flutter/material.dart", result)
        self.assertIn("dart:async", result)
        self.assertIn("package:my_app/file.dart", result)

    def test_handles_multiple_imports_on_same_line(self):
        content = "import 'a.dart'; import 'b.dart';"
        result = find_imports(content)
        self.assertEqual(len(result), 2)


class TestParseValue(unittest.TestCase):
    def test_parses_integer(self):
        self.assertEqual(parse_value("42"), 42)
        self.assertEqual(parse_value("0"), 0)
        self.assertEqual(parse_value("-10"), -10)

    def test_parses_float(self):
        self.assertEqual(parse_value("3.14"), 3.14)
        self.assertEqual(parse_value("0.5"), 0.5)

    def test_parses_string_single_quotes(self):
        self.assertEqual(parse_value("'hello'"), "hello")

    def test_parses_string_double_quotes(self):
        self.assertEqual(parse_value('"hello"'), "hello")

    def test_returns_none_for_null(self):
        self.assertIsNone(parse_value("null"))

    def test_returns_true_false_as_strings(self):
        self.assertEqual(parse_value("true"), "true")
        self.assertEqual(parse_value("false"), "false")

    def test_returns_identifier_for_unknown(self):
        self.assertEqual(parse_value("SomeClass"), "SomeClass")
        self.assertEqual(parse_value("constValue"), "constValue")


class TestDartClass(unittest.TestCase):
    def test_class_initialization(self):
        cls = DartClass("MyClass")
        self.assertEqual(cls.name, "MyClass")
        self.assertEqual(cls.constants, {})
        self.assertEqual(cls.methods, [])
        self.assertEqual(cls.constructors, [])
        self.assertEqual(cls.parent_classes, [])

    def test_class_with_constants(self):
        cls = DartClass("TestClass")
        cls.constants["tableId"] = 1
        cls.constants["name"] = "test"
        self.assertEqual(cls.constants["tableId"], 1)
        self.assertEqual(cls.constants["name"], "test")


class TestMethod(unittest.TestCase):
    def test_method_creation(self):
        method = Method(True, "fromJson", ("Map<String, dynamic>",))
        self.assertTrue(method.is_static)
        self.assertEqual(method.name, "fromJson")
        self.assertEqual(method.arg_types, ("Map<String, dynamic>",))

    def test_method_non_static(self):
        method = Method(False, "execute", ("ProjectEventHandler",))
        self.assertFalse(method.is_static)


class TestConstructor(unittest.TestCase):
    def test_constructor_creation(self):
        constr = Constructor("fromJson", ("Map<String, dynamic>",))
        self.assertEqual(constr.name, "fromJson")
        self.assertEqual(constr.arg_types, ("Map<String, dynamic>",))


class TestParseDartClasses(unittest.TestCase):
    def test_parses_simple_class(self):
        content = """
class MyClass {
  int x = 1;
}
"""
        classes = parse_dart_classes(content)
        self.assertEqual(len(classes), 1)
        self.assertEqual(classes[0].name, "MyClass")

    def test_parses_class_with_extends(self):
        content = """
class ChildClass extends ParentClass {
  int x = 1;
}
"""
        classes = parse_dart_classes(content)
        self.assertEqual(len(classes), 1)
        self.assertEqual(classes[0].name, "ChildClass")
        self.assertIn("ParentClass", classes[0].parent_classes)

    def test_parses_class_with_implements(self):
        content = """
class MyClass implements SomeInterface {
  int x = 1;
}
"""
        classes = parse_dart_classes(content)
        self.assertEqual(len(classes), 1)
        self.assertIn("SomeInterface", classes[0].parent_classes)

    def test_parses_multiple_implements(self):
        content = """
class MyClass implements Interface1, Interface2 {
  int x = 1;
}
"""
        classes = parse_dart_classes(content)
        self.assertIn("Interface1", classes[0].parent_classes)
        self.assertIn("Interface2", classes[0].parent_classes)

    def test_parses_abstract_class(self):
        content = """
abstract class AbstractClass {
  void doSomething();
}
"""
        classes = parse_dart_classes(content)
        self.assertEqual(len(classes), 1)
        self.assertEqual(classes[0].name, "AbstractClass")

    def test_parses_constants(self):
        content = """
class MyClass {
  static const tableId = 1;
  static const name = "test";
  static const value = 3.14;
}
"""
        classes = parse_dart_classes(content)
        self.assertEqual(classes[0].constants["tableId"], 1)
        self.assertEqual(classes[0].constants["name"], "test")
        self.assertEqual(classes[0].constants["value"], 3.14)

    def test_parses_factory_constructor(self):
        content = """
class MyClass {
  factory MyClass.fromJson(Map<String, dynamic> json) {
    return MyClass();
  }
}
"""
        classes = parse_dart_classes(content)
        factory_constructors = [
            c for c in classes[0].constructors if c.name == "fromJson"
        ]
        self.assertTrue(len(factory_constructors) > 0)

    def test_parses_multiple_classes(self):
        content = """
class ClassA {
  int a = 1;
}
class ClassB {
  int b = 2;
}
"""
        classes = parse_dart_classes(content)
        self.assertEqual(len(classes), 2)
        self.assertEqual(classes[0].name, "ClassA")
        self.assertEqual(classes[1].name, "ClassB")

    def test_ignores_comments(self):
        content = """
// This is a comment
class MyClass {
  // Another comment
  int x = 1;
}
"""
        classes = parse_dart_classes(content)
        self.assertEqual(len(classes), 1)
        self.assertEqual(classes[0].name, "MyClass")

    def test_parses_nested_braces(self):
        content = """
class MyClass {
  void method() {
    if (true) {
      int x = 1;
    }
  }
}
"""
        classes = parse_dart_classes(content)
        self.assertEqual(len(classes), 1)


class TestValidateClasses(unittest.TestCase):
    def test_validates_implements_base_class(self):
        content = """
abstract class ProjectEvent {
  void execute();
}
class AddEvent extends ProjectEvent {
  static const tableId = 1;
  factory AddEvent.fromJson(Map<String, dynamic> json) => AddEvent();
}
"""
        classes = parse_dart_classes(content)
        validate_classes(classes, "ProjectEvent", "tableId", "fromJson")

    def test_raises_when_no_class_implements_base(self):
        content = """
class MyClass {
  static const tableId = 1;
}
"""
        classes = parse_dart_classes(content)
        with self.assertRaises(ValueError) as ctx:
            validate_classes(classes, "ProjectEvent", "tableId", "fromJson")
        self.assertIn("no classes", str(ctx.exception))

    def test_raises_when_missing_id_constant(self):
        content = """
abstract class ProjectEvent {}
class AddEvent extends ProjectEvent {
  static const name = "test";
}
"""
        classes = parse_dart_classes(content)
        with self.assertRaises(ValueError) as ctx:
            validate_classes(classes, "ProjectEvent", "tableId", "fromJson")
        self.assertIn("missing constant", str(ctx.exception))

    def test_raises_when_id_not_int(self):
        content = """
abstract class ProjectEvent {}
class AddEvent extends ProjectEvent {
  static const tableId = "1";
}
"""
        classes = parse_dart_classes(content)
        with self.assertRaises(ValueError) as ctx:
            validate_classes(classes, "ProjectEvent", "tableId", "fromJson")
        self.assertIn("id type mismatch", str(ctx.exception))

    def test_raises_on_duplicate_ids(self):
        content = """
abstract class ProjectEvent {}
class AddEvent extends ProjectEvent {
  static const tableId = 1;
}
class RemoveEvent extends ProjectEvent {
  static const tableId = 1;
}
"""
        classes = parse_dart_classes(content)
        with self.assertRaises(ValueError) as ctx:
            validate_classes(classes, "ProjectEvent", "tableId", "fromJson")
        self.assertIn("duplicate id", str(ctx.exception))


class TestGenerateOutput(unittest.TestCase):
    def test_generates_jump_table(self):
        content = """
abstract class ProjectEvent {
  Map<String, dynamic> toJson();
}
class AddEvent extends ProjectEvent {
  static const tableId = 1;
  factory AddEvent.fromJson(Map<String, dynamic> json) => AddEvent();
  @override
  Map<String, dynamic> toJson() => {};
}
class RemoveEvent extends ProjectEvent {
  static const tableId = 2;
  factory RemoveEvent.fromJson(Map<String, dynamic> json) => RemoveEvent();
  @override
  Map<String, dynamic> toJson() => {};
}
"""
        classes = parse_dart_classes(content)
        output = generate_output(classes, "ProjectEvent", "tableId", "fromJson")

        self.assertIn("final Map<Type, int> _mapEvent = {", output)
        self.assertIn("AddEvent: 1", output)
        self.assertIn("RemoveEvent: 2", output)
        self.assertIn("Map<String, dynamic> encodeEvent(ProjectEvent event)", output)
        self.assertIn("dynamic decodeEvent(Map<String, dynamic> data)", output)
        self.assertIn("case 1:", output)
        self.assertIn("case 2:", output)

    def test_generates_encode_method(self):
        content = """
abstract class ProjectEvent {
  Map<String, dynamic> toJson();
}
class TestEvent extends ProjectEvent {
  static const tableId = 1;
  factory TestEvent.fromJson(Map<String, dynamic> json) => TestEvent();
  @override
  Map<String, dynamic> toJson() => {"key": "value"};
}
"""
        classes = parse_dart_classes(content)
        output = generate_output(classes, "ProjectEvent", "tableId", "fromJson")

        self.assertIn('return {"t": id, "v": 1, "c": encoded}', output)

    def test_generates_decode_switch(self):
        content = """
abstract class ProjectEvent {}
class Event1 extends ProjectEvent {
  static const tableId = 1;
  factory Event1.fromJson(Map<String, dynamic> json) => Event1();
}
"""
        classes = parse_dart_classes(content)
        output = generate_output(classes, "ProjectEvent", "tableId", "fromJson")

        self.assertIn("return Event1.fromJson(data);", output)
        self.assertIn("default:", output)
        self.assertIn("return null;", output)

    def test_classes_sorted_by_id(self):
        content = """
abstract class ProjectEvent {}
class EventC extends ProjectEvent {
  static const tableId = 3;
  factory EventC.fromJson(Map<String, dynamic> json) => EventC();
}
class EventA extends ProjectEvent {
  static const tableId = 1;
  factory EventA.fromJson(Map<String, dynamic> json) => EventA();
}
class EventB extends ProjectEvent {
  static const tableId = 2;
  factory EventB.fromJson(Map<String, dynamic> json) => EventB();
}
"""
        classes = parse_dart_classes(content)
        output = generate_output(classes, "ProjectEvent", "tableId", "fromJson")

        event_a_pos = output.find("EventA: 1")
        event_b_pos = output.find("EventB: 2")
        event_c_pos = output.find("EventC: 3")

        self.assertLess(event_a_pos, event_b_pos)
        self.assertLess(event_b_pos, event_c_pos)


class TestIntegration(unittest.TestCase):
    def test_full_workflow_with_real_files(self):
        project_root = get_project_root()
        dart_file = (
            project_root
            / "lib/backend/project/code_gen_allowed/event/project_events.dart"
        )

        if dart_file.exists():
            content = dart_file.read_text(encoding="utf-8")
            classes = parse_dart_classes(content)

            implementing = [c for c in classes if "ProjectEvent" in c.parent_classes]
            self.assertGreater(
                len(implementing), 0, "Should find classes implementing ProjectEvent"
            )

            for cls in implementing:
                self.assertIn(
                    "tableId", cls.constants, f"{cls.name} should have tableId"
                )
                self.assertIsInstance(
                    cls.constants["tableId"], int, f"{cls.name} tableId should be int"
                )


if __name__ == "__main__":
    unittest.main()
