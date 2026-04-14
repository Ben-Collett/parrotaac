import subprocess
import sys
from pathlib import Path
from unittest.mock import MagicMock

import pytest

sys.path.insert(0, str(Path(__file__).parent.parent))

import event_table as et
from utils import DartClass, DartField, DartFunction


class TestFindClassExtendingBase:
    def test_finds_class_with_extends(self):
        mock_file_data = MagicMock()
        mock_file_data.classes = [
            DartClass("TestClass", [], [], [], [], ["BaseClass"]),
            DartClass("OtherClass", [], [], [], ["NotBase"]),
        ]
        result = et.find_class_extending_base(mock_file_data, "BaseClass")
        assert len(result) == 1
        assert result[0].name == "TestClass"

    def test_returns_empty_list_when_no_match(self):
        mock_file_data = MagicMock()
        mock_file_data.classes = [
            DartClass("OtherClass", [], [], [], ["NotBase"]),
        ]
        result = et.find_class_extending_base(mock_file_data, "BaseClass")
        assert len(result) == 0


class TestValidateClasses:
    def test_returns_error_when_no_classes(self):
        is_valid, error = et.validate_classes([])
        assert is_valid is False
        assert "no classes" in error

    def test_returns_error_when_missing_id_field(self):
        cls = DartClass("TestClass", [], [], [], [])
        is_valid, error = et.validate_classes([cls])
        assert is_valid is False
        assert "missing constant" in error

    def test_returns_error_when_missing_from_json(self):
        cls = DartClass(
            "TestClass",
            [],
            [DartField("tableId", [], True)],
            [],
            [],
        )
        is_valid, error = et.validate_classes([cls])
        assert is_valid is False
        assert "missing fromJson" in error

    def test_passes_with_valid_class(self):
        cls = DartClass(
            "TestClass",
            [],
            [DartField("tableId", [], True)],
            [],
            [DartFunction("fromJson", [], False)],
        )
        is_valid, error = et.validate_classes([cls])
        assert is_valid is True
        assert error == ""


class TestGenerateJumpTable:
    def test_generates_correct_output(self):
        classes = [
            DartClass(
                "AddEvent",
                [],
                [DartField("tableId", [], True)],
                [],
                [DartFunction("fromJson", [], False)],
            ),
            DartClass(
                "RemoveEvent",
                [],
                [DartField("tableId", [], True)],
                [],
                [DartFunction("fromJson", [], False)],
            ),
        ]
        result = et.generate_jump_table(classes)
        assert "AddEvent.tableId" in result
        assert "RemoveEvent.tableId" in result
        assert "case AddEvent.tableId:" in result
        assert "case RemoveEvent.tableId:" in result
        assert "AddEvent.fromJson(data)" in result
        assert "RemoveEvent.fromJson(data)" in result
        assert "import 'package:parrotaac" in result
        assert "encodeEvent" in result
        assert "decodeEvent" in result


class TestConstants:
    def test_output_path(self):
        assert (
            et.OUTPUT_PATH
            == "lib/backend/project/code_gen_allowed/event/event_jump_table.pyg.dart"
        )

    def test_paths_to_parse(self):
        assert et.PATHS_TO_PARSE == [
            "lib/backend/project/code_gen_allowed/event/project_events.dart"
        ]

    def test_base_class_name(self):
        assert et.BASE_CLASS_NAME == "ProjectEvent"

    def test_id_field_name(self):
        assert et.ID_FIELD_NAME == "tableId"

    def test_constructor_name(self):
        assert et.CONSTRUCTOR_NAME == "fromJson"


class TestGetProjectPaths:
    @pytest.mark.parametrize("root", [Path("/fake/project")])
    def test_returns_list_of_paths(self, root, monkeypatch):
        monkeypatch.setattr("event_table.get_project_root", lambda: root)
        paths = et.get_project_paths()
        assert len(paths) == 1
        assert "project_events.dart" in str(paths[0])


class TestGetOutputPath:
    def test_returns_output_path(self, monkeypatch):
        monkeypatch.setattr(
            "event_table.get_project_root", lambda: Path("/fake/project")
        )
        path = et.get_output_path()
        assert "event_jump_table.pyg.dart" in str(path)


class TestRunIntegration:
    def test_print_mode_outputs_code(self):
        script_path = Path(__file__).parent.parent / "event_table.py"
        project_root = Path(__file__).parent.parent.parent
        result = subprocess.run(
            [sys.executable, str(script_path), "-p"],
            cwd=str(project_root),
            capture_output=True,
            text=True,
        )
        assert "GENERATED CODE" in result.stdout, result.stderr
        assert "encodeEvent" in result.stdout
        assert "decodeEvent" in result.stdout

    def test_generate_writes_file(self):
        script_path = Path(__file__).parent.parent / "event_table.py"
        project_root = Path(__file__).parent.parent.parent
        result = subprocess.run(
            [sys.executable, str(script_path)],
            cwd=str(project_root),
            capture_output=True,
            text=True,
        )
        assert result.returncode == 0, result.stderr
