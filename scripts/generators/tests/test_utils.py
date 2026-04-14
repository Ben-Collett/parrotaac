from __future__ import annotations

import os
from pathlib import Path
import tempfile

import pytest

from utils import (
    Constructor,
    DartClass,
    DartField,
    DartFunction,
    FileData,
    data_from_content,
    data_from_file,
    get_project_root,
)


class TestDartFunction:
    def test_create_function(self) -> None:
        func = DartFunction("testFunc", ["@override"], True)
        assert func.name == "testFunc"
        assert func.annotations == ["@override"]
        assert func.is_static is True

    def test_function_defaults(self) -> None:
        func = DartFunction("testFunc", [])
        assert func.is_static is False


class TestDartField:
    def test_create_field(self) -> None:
        field = DartField("count", ["@deprecated"], True)
        assert field.name == "count"
        assert field.annotations == ["@deprecated"]
        assert field.is_constant is True

    def test_field_defaults(self) -> None:
        field = DartField("value", [])
        assert field.is_constant is False


class TestConstructor:
    def test_create_constructor(self) -> None:
        cons = Constructor("TestClass", False)
        assert cons.name == "TestClass"
        assert cons.is_factory is False

    def test_create_factory(self) -> None:
        cons = Constructor("TestClass", True)
        assert cons.is_factory is True

    def test_empty_name(self) -> None:
        cons = Constructor("", False)
        assert cons.name == ""


class TestDartClass:
    def test_create_class(self) -> None:
        cls = DartClass(
            ["@sealed"],
            [DartField("x", [])],
            [Constructor("MyClass")],
            [DartFunction("method", [])],
        )
        assert cls.annotations == ["@sealed"]
        assert len(cls.fields) == 1
        assert len(cls.constructors) == 1
        assert len(cls.methods) == 1


class TestFileData:
    def test_create_file_data(self) -> None:
        data = FileData(
            [DartFunction("topFunc", [])],
            [DartClass([], [], [], [])],
            [DartField("global", [])],
        )
        assert len(data.functions) == 1
        assert len(data.classes) == 1
        assert len(data.fields) == 1


class TestDataFromContent:
    def test_parse_empty_file(self) -> None:
        data = data_from_content("")
        assert data.functions == []
        assert data.classes == []
        assert data.fields == []

    def test_parse_simple_class(self) -> None:
        content = """
class MyClass {
  int field1;
  MyClass();
  void method() {}
}
"""
        data = data_from_content(content)
        assert len(data.classes) == 1
        cls = data.classes[0]
        assert len(cls.fields) == 1
        assert cls.fields[0].name == "field1"
        assert len(cls.constructors) == 1
        assert cls.constructors[0].name == "MyClass"
        assert len(cls.methods) == 1

    def test_parse_top_level_function(self) -> None:
        content = "void hello() {}"
        data = data_from_content(content)
        assert len(data.functions) == 1
        assert data.functions[0].name == "hello"

    def test_parse_top_level_field(self) -> None:
        content = "const int count = 5;"
        data = data_from_content(content)
        assert len(data.fields) == 1
        assert data.fields[0].name == "count"
        assert data.fields[0].is_constant is True

    def test_parse_annotation(self) -> None:
        content = """
@override
void method() {}
"""
        data = data_from_content(content)
        assert len(data.functions) == 1
        assert "@override" in data.functions[0].annotations

    def test_parse_static_method(self) -> None:
        content = """
class MyClass {
  static void staticMethod() {}
}
"""
        data = data_from_content(content)
        cls = data.classes[0]
        assert cls.methods[0].is_static is True

    def test_parse_multiple_classes(self) -> None:
        content = """
class A {}
class B {}
"""
        data = data_from_content(content)
        assert len(data.classes) == 2


class TestDataFromFile:
    def test_parse_file(self) -> None:
        with tempfile.NamedTemporaryFile(mode="w", suffix=".dart", delete=False) as f:
            f.write("class Test {}")
            f.flush()
            try:
                data = data_from_file(f.name)
                assert len(data.classes) == 1
            finally:
                os.unlink(f.name)


class TestGetProjectRoot:
    def test_finds_project_root(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            project = Path(tmpdir) / "project"
            project.mkdir()
            (project / "pubspec.yaml").write_text("name: test")
            subdir = project / "lib"
            subdir.mkdir()
            original = os.getcwd()
            try:
                os.chdir(subdir)
                root = get_project_root()
                assert root == project
            finally:
                os.chdir(original)

    def test_raises_when_not_found(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            original = os.getcwd()
            try:
                os.chdir(tmpdir)
                with pytest.raises(ValueError, match="no project root found"):
                    get_project_root()
            finally:
                os.chdir(original)

    def test_nested_directory(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            project = Path(tmpdir) / "myproject"
            project.mkdir()
            (project / "pubspec.yaml").write_text("name: test")
            nested = project / "lib" / "src" / "utils"
            nested.mkdir(parents=True)
            original = os.getcwd()
            try:
                os.chdir(nested)
                root = get_project_root()
                assert root == project
            finally:
                os.chdir(original)
