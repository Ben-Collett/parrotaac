#!/usr/bin/env python3
import os
import sys
import re
import json
import argparse
from pathlib import Path
from typing import Optional

OUTPUT_PATH = "lib/backend/project/code_gen_allowed/event/event_jump_table.pyg.dart"
PATHS_TO_PARSE = ["lib/backend/project/code_gen_allowed/event/project_events.dart"]
BASE_CLASS_NAME = "ProjectEvent"
ID_FIELD_NAME = "tableId"
CONSTRUCTOR_NAME = "fromJson"
OUTPUT_ENCODE_METHOD = "encodeEvent"
OUTPUT_DECODE_METHOD = "decodeEvent"


def get_project_root() -> Path:
    current = Path.cwd()
    while current != current.parent:
        if (current / "pubspec.yaml").exists():
            return current
        current = current.parent
    raise RuntimeError("Error: no project root found")


def remove_comments_and_strings(content: str) -> str:
    result = []
    lines = content.split("\n")
    in_multiline_string = False
    multiline_delimiter = ""

    for line in lines:
        processed_line = ""
        i = 0
        while i < len(line):
            if in_multiline_string:
                if line[i:].startswith(multiline_delimiter):
                    in_multiline_string = False
                    i += len(multiline_delimiter)
                else:
                    i += 1
            else:
                if i < len(line) - 2 and line[i : i + 3] == '"""':
                    in_multiline_string = True
                    multiline_delimiter = '"""'
                    i += 3
                elif i < len(line) - 2 and line[i : i + 3] == "'''":
                    in_multiline_string = True
                    multiline_delimiter = "'''"
                    i += 3
                elif i < len(line) - 1 and line[i : i + 2] == "//":
                    break
                else:
                    processed_line += line[i]
                    i += 1
        result.append(processed_line)

    return "\n".join(result)


def find_imports(content: str) -> list[str]:
    imports = []
    for match in re.finditer(r"import\s+['\"]([^'\"]+)['\"];", content):
        imports.append(match.group(1))
    return imports


class Method:
    def __init__(self, is_static: bool, name: str, arg_types: tuple):
        self.is_static = is_static
        self.name = name
        self.arg_types = arg_types


class Constructor:
    def __init__(self, name: str, arg_types: tuple):
        self.name = name
        self.arg_types = arg_types


class DartClass:
    def __init__(self, name: str):
        self.name = name
        self.constants: dict[str, Optional[str | int | float]] = {}
        self.methods: list[Method] = []
        self.constructors: list[Constructor] = []
        self.parent_classes: list[str] = []


def parse_value(value_str: str) -> Optional[str | int | float]:
    value_str = value_str.strip()
    if not value_str:
        return None

    if value_str == "null":
        return None

    if value_str == "true":
        return "true"
    if value_str == "false":
        return "false"

    try:
        if "." in value_str:
            return float(value_str)
        return int(value_str)
    except ValueError:
        pass

    if (value_str.startswith("'") and value_str.endswith("'")) or (
        value_str.startswith('"') and value_str.endswith('"')
    ):
        return value_str[1:-1]

    return value_str


def parse_dart_classes(content: str) -> list[DartClass]:
    cleaned_content = remove_comments_and_strings(content)
    classes: list[DartClass] = []

    class_pattern = r"(?:abstract\s+)?class\s+(\w+)(?:\s+extends\s+(\w+))?(?:\s+with\s+(\w+))?(?:\s+implements\s+([\w,\s]+))?\s*\{"

    for match in re.finditer(class_pattern, cleaned_content):
        class_name = match.group(1)
        extended_class = match.group(2)
        mixin_class = match.group(3)
        implemented = match.group(4)

        dart_class = DartClass(class_name)

        if extended_class:
            dart_class.parent_classes.append(extended_class)
        if mixin_class:
            dart_class.parent_classes.append(mixin_class)
        if implemented:
            for impl in implemented.split(","):
                impl = impl.strip()
                if impl:
                    dart_class.parent_classes.append(impl)

        class_start = match.end()
        brace_count = 1
        class_end = class_start

        for i in range(class_start, len(cleaned_content)):
            if cleaned_content[i] == "{":
                brace_count += 1
            elif cleaned_content[i] == "}":
                brace_count -= 1
                if brace_count == 0:
                    class_end = i
                    break

        class_body = cleaned_content[class_start:class_end]

        const_pattern = r"static\s+(?:const|final)\s+(\w+)\s*=\s*([^;]+);"
        for const_match in re.finditer(const_pattern, class_body):
            const_name = const_match.group(1)
            const_value = const_match.group(2).strip()
            dart_class.constants[const_name] = parse_value(const_value)

        static_method_pattern = r"static\s+[\w<>,\s]+\s+(\w+)\s*\(([^)]*)\)"
        for method_match in re.finditer(static_method_pattern, class_body):
            method_name = method_match.group(1)
            args_str = method_match.group(2).strip()
            arg_types = tuple()
            if args_str:
                args = []
                for arg in args_str.split(","):
                    arg = arg.strip()
                    if arg:
                        parts = arg.split()
                        if len(parts) >= 2:
                            args.append(parts[-2])
                        elif len(parts) == 1:
                            args.append(parts[0])
                arg_types = tuple(args)
            dart_class.methods.append(Method(True, method_name, arg_types))

        factory_pattern = r"factory\s+([\w.]+)\s*\(([^)]*)\)"
        for factory_match in re.finditer(factory_pattern, class_body):
            full_factory_name = factory_match.group(1)
            factory_name = (
                full_factory_name.split(".")[-1]
                if "." in full_factory_name
                else full_factory_name
            )
            args_str = factory_match.group(2).strip()
            arg_types = tuple()
            if args_str:
                args = []
                for arg in args_str.split(","):
                    arg = arg.strip()
                    if arg:
                        parts = arg.split()
                        if len(parts) >= 2:
                            args.append(parts[-2])
                        elif len(parts) == 1:
                            args.append(parts[0])
                arg_types = tuple(args)
            dart_class.constructors.append(Constructor(factory_name, arg_types))

        constructor_pattern = r"(?:[\w<>,\s]+\s+)?(\w+)\s*\(([^)]*)\)"
        for constr_match in re.finditer(constructor_pattern, class_body):
            constr_name = constr_match.group(1)
            if constr_name == class_name:
                args_str = constr_match.group(2).strip()
                arg_types = tuple()
                if args_str:
                    args = []
                    for arg in args_str.split(","):
                        arg = arg.strip()
                        if arg:
                            parts = arg.split()
                            if len(parts) >= 2:
                                args.append(parts[-2])
                            elif len(parts) == 1:
                                args.append(parts[0])
                    arg_types = tuple(args)
                dart_class.constructors.append(Constructor(constr_name, arg_types))

        classes.append(dart_class)

    return classes


def validate_classes(
    classes: list[DartClass],
    base_class_name: str,
    id_field_name: str,
    constructor_name: str,
) -> None:
    implementing_classes = [c for c in classes if base_class_name in c.parent_classes]

    if not implementing_classes:
        raise ValueError(
            f"no classes in {PATHS_TO_PARSE} implement base class {base_class_name}"
        )

    for cls in implementing_classes:
        if id_field_name not in cls.constants:
            raise ValueError(f"missing constant {id_field_name} in {cls.name}")

        id_value = cls.constants[id_field_name]
        if not isinstance(id_value, int):
            raise ValueError(f"id type mismatch {cls.name}")

        has_constructor = any(
            c.name == constructor_name and len(c.arg_types) >= 1
            for c in cls.constructors
        )
        has_static_method = any(
            m.name == constructor_name and len(m.arg_types) >= 1 for m in cls.methods
        )

        if not (has_constructor or has_static_method):
            pass

    ids = [cls.constants[id_field_name] for cls in implementing_classes]
    if len(ids) != len(set(ids)):
        seen = {}
        for cls in implementing_classes:
            id_val = cls.constants[id_field_name]
            if id_val in seen:
                raise ValueError(
                    f"duplicate id {cls.name}:{id_val}, {seen[id_val]}:{id_val}"
                )
            seen[id_val] = cls.name


def generate_output(
    classes: list[DartClass],
    base_class_name: str,
    id_field_name: str,
    constructor_name: str,
) -> str:
    implementing_classes = [c for c in classes if base_class_name in c.parent_classes]
    implementing_classes.sort(
        key=lambda c: (
            int(c.constants.get(id_field_name, 0))
            if c.constants.get(id_field_name, 0) is not None
            else 0
        )
    )

    imports = set()
    for path in PATHS_TO_PARSE:
        full_path = get_project_root() / path
        if full_path.exists():
            content = full_path.read_text(encoding="utf-8")
            for imp in find_imports(content):
                if imp.startswith("package:parrotaac/"):
                    imports.add(imp)

    import_line = f"import 'package:parrotaac/backend/project/code_gen_allowed/event/project_events.dart';"

    lines = [
        "// GENERATED CODE - DO NOT MODIFY BY HAND",
        "",
        import_line,
        "",
        f"final Map<Type, int> _mapEvent = {{",
    ]

    for cls in implementing_classes:
        id_val = cls.constants[id_field_name]
        lines.append(f"  {cls.name}: {id_val},")

    lines.append("};")
    lines.append("")
    lines.append(
        f"Map<String, dynamic> {OUTPUT_ENCODE_METHOD}({base_class_name} event) {{"
    )
    lines.append("  final type = event.runtimeType;")
    lines.append("  final id = _mapEvent[type];")
    lines.append("")
    lines.append("  final encoded = event.toJson();")
    lines.append("")
    lines.append('  return {"t": id, "v": 1, "c": encoded};')
    lines.append("}")
    lines.append("")
    lines.append(f"dynamic {OUTPUT_DECODE_METHOD}(Map<String, dynamic> data) {{")
    lines.append('  final id = data["t"] as int?;')
    lines.append('  data = data["c"];')
    lines.append("")
    lines.append("  switch (id) {")

    for cls in implementing_classes:
        id_val = cls.constants[id_field_name]
        lines.append(f"    case {id_val}:")
        lines.append(f"      return {cls.name}.{constructor_name}(data);")

    lines.append("    default:")
    lines.append("      return null;")
    lines.append("  }")
    lines.append("}")

    return "\n".join(lines)


def load_and_parse_files() -> list[DartClass]:
    all_classes = []
    project_root = get_project_root()

    for path_rel in PATHS_TO_PARSE:
        full_path = project_root / path_rel
        if not full_path.exists():
            print(f"Warning: File not found: {full_path}")
            continue

        content = full_path.read_text(encoding="utf-8")
        classes = parse_dart_classes(content)
        all_classes.extend(classes)

    return all_classes


def generate(verify: bool = False) -> tuple[str, str]:
    classes = load_and_parse_files()

    validate_classes(classes, BASE_CLASS_NAME, ID_FIELD_NAME, CONSTRUCTOR_NAME)

    output = generate_output(classes, BASE_CLASS_NAME, ID_FIELD_NAME, CONSTRUCTOR_NAME)

    project_root = get_project_root()
    output_path = project_root / OUTPUT_PATH

    return output, str(output_path)


def main():
    parser = argparse.ArgumentParser(
        description="Event table builder for project events"
    )
    parser.add_argument(
        "-v",
        "--verify",
        action="store_true",
        help="Verify that generated output matches existing file",
    )

    args = parser.parse_args()

    try:
        output, output_path = generate()

        if args.verify:
            if os.path.exists(output_path):
                with open(output_path, "r", encoding="utf-8") as f:
                    existing_content = f.read()

                if output.strip() == existing_content.strip():
                    print("Verification passed: output matches existing file")
                    return 0
                else:
                    print("Verification failed: output does not match existing file")
                    return 1
            else:
                print(f"Verification failed: file does not exist at {output_path}")
                return 1
        else:
            os.makedirs(os.path.dirname(output_path), exist_ok=True)
            with open(output_path, "w", encoding="utf-8") as f:
                f.write(output)
            print(f"Generated: {output_path}")
            return 0

    except Exception as e:
        print(str(e))
        return 1


if __name__ == "__main__":
    sys.exit(main())
