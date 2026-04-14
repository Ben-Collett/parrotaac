from __future__ import annotations

import os
from pathlib import Path
from typing import Optional

from tree_sitter_language_pack import get_parser


def _create_parser():
    parser = get_parser("dart")
    return parser


def _find_identifier(node):
    if node.type == "identifier":
        return node.text.decode()
    for child in node.children:
        result = _find_identifier(child)
        if result:
            return result
    return None


def _find_identifiers(node):
    results = []
    if node.type == "identifier":
        results.append(node.text.decode())
    for child in node.children:
        results.extend(_find_identifiers(child))
    return results


def _has_keyword(node, keyword: str):
    if not node:
        return False
    for child in node.children:
        if child.type == keyword:
            return True
    for child in node.children:
        if _has_keyword(child, keyword):
            return True
    return False


def _get_annotations(root, node) -> list[str]:
    annotations = []
    for child in root.children:
        if child.type == "annotation" and child.end_byte < node.start_byte:
            annotations.append(child.text.decode())
    return annotations


def _parse_class(root, node) -> Optional[DartClass]:
    if node.type != "class_definition":
        return None
    annotations = _get_annotations(root, node)
    class_name = None
    for child in node.children:
        if child.type == "identifier":
            class_name = child.text.decode()
            break
    if not class_name:
        return None
    extends = []
    for child in node.children:
        if child.type == "superclass":
            for sub in child.children:
                if sub.type == "type_identifier":
                    extends.append(sub.text.decode().strip())
                    break
    cls = DartClass(class_name, annotations, [], [Constructor(class_name)], [], extends)
    class_body = None
    for child in node.children:
        if child.type == "class_body":
            class_body = child
            break
    if class_body:
        for item in class_body.children:
            if item.type == "declaration":
                is_const = _has_keyword(item, "const_builtin")
                for c in item.children:
                    if c.type == "initialized_identifier_list":
                        for init_id in c.children:
                            if init_id.type == "initialized_identifier":
                                name = _find_identifier(init_id)
                                if name:
                                    cls.fields.append(DartField(name, [], is_const))
                    elif c.type == "static_final_declaration_list":
                        for decl in c.children:
                            if decl.type == "static_final_declaration":
                                name = _find_identifier(decl)
                                if name:
                                    cls.fields.append(DartField(name, [], is_const))
                    elif c.type == "static_final_declaration":
                        name = _find_identifier(c)
                        if name:
                            cls.fields.append(DartField(name, [], is_const))
            elif item.type == "method_signature":
                is_factory = _has_keyword(item, "factory")
                func_annots = _get_annotations(root, item)
                is_static = _has_keyword(item, "static") if not is_factory else False
                ids = _find_identifiers(item)
                if is_factory and len(ids) >= 2:
                    func_name = ids[1]
                else:
                    func_name = ids[0] if ids else class_name
                if is_factory:
                    cls.constructors.append(Constructor(func_name, True))
                else:
                    cls.methods.append(DartFunction(func_name, func_annots, is_static))
            elif item.type == "constructor_signature":
                name = _find_identifier(item) or class_name
                is_factory = _has_keyword(item, "factory")
                cls.constructors.append(Constructor(name, is_factory))
    return cls


def _parse_file(tree) -> FileData:
    root = tree.root_node
    functions: list[DartFunction] = []
    classes: list[DartClass] = []
    fields: list[DartField] = []
    for node in root.children:
        if node.type == "class_definition":
            cls = _parse_class(root, node)
            if cls:
                classes.append(cls)
        elif node.type == "function_signature":
            name = _find_identifier(node)
            if name:
                annotations = _get_annotations(root, node)
                functions.append(DartFunction(name, annotations, False))
        elif node.type == "initialized_identifier_list":
            for init_id in node.children:
                if init_id.type == "initialized_identifier":
                    name = _find_identifier(init_id)
                    if name:
                        is_constant = True
                        fields.append(DartField(name, [], is_constant))
        elif node.type in ("static_final_declaration", "static_final_declaration_list"):
            name = _find_identifier(node)
            if name:
                is_constant = True
                fields.append(DartField(name, [], is_constant))
    return FileData(functions, classes, fields)


def data_from_file(file: str) -> FileData:
    parser = _create_parser()
    content = Path(file).read_text()
    tree = parser.parse(bytes(content, "utf8"))
    return _parse_file(tree)


def data_from_content(content: str) -> FileData:
    parser = _create_parser()
    tree = parser.parse(bytes(content, "utf8"))
    return _parse_file(tree)


def get_project_root() -> Path:
    current = Path.cwd()
    home = Path.home()
    while current != home:
        if (current / "pubspec.yaml").exists():
            return current
        if current.parent == current:
            raise ValueError("no project root found")
        current = current.parent
    raise ValueError("no project root found")


class DartFunction:
    def __init__(
        self, name: str, annotations: list[str], is_static: bool = False
    ) -> None:
        self.name = name
        self.annotations = annotations
        self.is_static = is_static


class DartField:
    def __init__(
        self, name: str, annotations: list[str], is_constant: bool = False
    ) -> None:
        self.name = name
        self.annotations = annotations
        self.is_constant = is_constant


class Constructor:
    def __init__(self, name: str, is_factory: bool = False) -> None:
        self.name = name
        self.is_factory = is_factory


class DartClass:
    def __init__(
        self,
        name: str,
        annotations: list[str],
        fields: list[DartField],
        constructors: list[Constructor],
        methods: list[DartFunction],
        extends: list[str] = None,
    ) -> None:
        self.name = name
        self.annotations = annotations
        self.fields = fields
        self.constructors = constructors
        self.methods = methods
        self.extends = extends if extends else []


class FileData:
    def __init__(
        self,
        functions: list[DartFunction],
        classes: list[DartClass],
        fields: list[DartField],
    ) -> None:
        self.functions = functions
        self.classes = classes
        self.fields = fields
