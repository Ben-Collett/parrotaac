import sys
from pathlib import Path
from utils import get_project_root, data_from_file, DartClass, FileData

OUTPUT_PATH = "lib/backend/project/code_gen_allowed/event/event_jump_table.pyg.dart"
PATHS_TO_PARSE = ["lib/backend/project/code_gen_allowed/event/project_events.dart"]
BASE_CLASS_NAME = "ProjectEvent"
ID_FIELD_NAME = "tableId"
CONSTRUCTOR_NAME = "fromJson"
OUTPUT_ENCODE_METHOD = "encodeEvent"
OUTPUT_DECODE_METHOD = "decodeEvent"


def get_project_paths() -> list[Path]:
    root = get_project_root()
    return [root / p for p in PATHS_TO_PARSE]


def get_output_path() -> Path:
    root = get_project_root()
    return root / OUTPUT_PATH


def find_class_extending_base(
    file_data: FileData, base_class_name: str
) -> list[DartClass]:
    result = []
    for cls in file_data.classes:
        if base_class_name in cls.extends:
            result.append(cls)
    return result


def validate_classes(classes: list[DartClass]) -> tuple[bool, str]:
    if not classes:
        return (
            False,
            f"no classes in {PATHS_TO_PARSE} implement base class {BASE_CLASS_NAME}",
        )

    for cls in classes:
        has_id_field = any(
            f.name == ID_FIELD_NAME and f.is_constant for f in cls.fields
        )
        if not has_id_field:
            return False, f"missing constant in {cls.name}.{ID_FIELD_NAME}"

        has_from_json = any(m.name == CONSTRUCTOR_NAME for m in cls.methods) or any(
            c.name == CONSTRUCTOR_NAME for c in cls.constructors
        )
        if not has_from_json:
            return False, f"missing {CONSTRUCTOR_NAME} method in {cls.name}"

    return True, ""


def generate_jump_table(classes: list[DartClass]) -> str:
    import_lines = [
        "import 'package:parrotaac/backend/project/code_gen_allowed/event/project_events.dart';"
    ]

    map_entries = []
    for cls in classes:
        for field in cls.fields:
            if field.name == ID_FIELD_NAME and field.is_constant:
                map_entries.append(f"  {cls.name}: {cls.name}.{field.name},")
                break

    map_lines = "\n".join(map_entries)
    map_event = f"final Map<Type, int> _mapEvent = {{\n{map_lines}\n}};"

    encode_func = f"""Map<String, dynamic> {OUTPUT_ENCODE_METHOD}(ProjectEvent event) {{
  final type = event.runtimeType;
  final id = _mapEvent[type];

  final encoded = event.toJson();

  return {{"t": id, "v": 1, "c": encoded}};
}}"""

    decode_cases = []
    for cls in classes:
        for field in cls.fields:
            if field.name == ID_FIELD_NAME and field.is_constant:
                decode_cases.append(f"    case {cls.name}.{field.name}:")
                decode_cases.append(
                    f"      return {cls.name}.{CONSTRUCTOR_NAME}(data);"
                )
                break

    decode_switch = "\n".join(decode_cases)
    decode_func = f"""dynamic {OUTPUT_DECODE_METHOD}(Map<String, dynamic> data) {{
  final id = data["t"] as int?;
  data = data["c"];

  switch (id) {{
{decode_switch}
    default:
      return null;
  }}
}}
"""

    all_lines = (
        [
            "// GENERATED CODE - DO NOT MODIFY BY HAND",
        ]
        + import_lines
        + [
            "",
            map_event,
            "",
            encode_func,
            "",
            decode_func,
        ]
    )

    return "\n".join(all_lines)


def run() -> None:
    paths = get_project_paths()
    all_classes: list[DartClass] = []

    for path in paths:
        file_data = data_from_file(str(path))
        classes = find_class_extending_base(file_data, BASE_CLASS_NAME)
        all_classes.extend(classes)

    is_valid, error_msg = validate_classes(all_classes)
    if not is_valid:
        print(error_msg, file=sys.stderr)
        sys.exit(1)

    output = generate_jump_table(all_classes)

    if len(sys.argv) > 1 and sys.argv[1] == "-p":
        for path in PATHS_TO_PARSE:
            print(f"{path}\n")
        print(output)
    elif len(sys.argv) > 1 and sys.argv[1] == "-V":
        output_path = get_output_path()
        if not output_path.exists():
            print(f"file at {output_path} does not exist", file=sys.stderr)
            sys.exit(1)

        existing = output_path.read_text()
        if existing != output:
            print("verification failed - output does not match", file=sys.stderr)
            sys.exit(1)
    else:
        output_path = get_output_path()
        output_path.parent.mkdir(parents=True, exist_ok=True)
        output_path.write_text(output)


if __name__ == "__main__":
    run()
