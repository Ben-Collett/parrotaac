utils.py:
data_from_file(file) -> FileData
data_from_content(str) -> FileData
def get_project_root() -> gets the project root checking parent directories searching for the pubsec.yaml, if the home directory is reached then error  displaying no project root found

classes:
FileData: list[DartFunction] functions(top level functions only), list[DartClass] classes, list[DartField] fields(top level fields only)
class: list[DartFunction], annotations: list[str], list[DartField],list[Constructor] constructors
function: name:str, annotations: list[str], static: bool
field: name:str, annotaiotions:list[str], constant: bool
custructor: name:str, is_factory:bool

style:
functions should not exceed two levels of indentation if this is occurs it should be broken out to another function
functions should be no longer then 40 lines long

dependencies:
managed using uv
tree-sitter-language-pack
