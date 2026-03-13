the specification for event_table_builder.py (belongs in the same directory as the specification)
each file path is defined relaitve to the root of the project

this is the spec for a python script which generates a jump table for each of the project events.

cli:
  python event_table.py -> generates the jump table file, if it already exist then override it
  python event_table.py -v -> verifies that if python event_table.py was ran the output would match the file that is currently generated at output path.

script_constants:
  output_path = "lib/backend/project/code_gen_allowed/event/event_jump_table.pyg.dart"
  paths_to_parse = ["lib/backend/project/code_gen_allowed/event/project_events.dart"]
  base_class_name = "ProjectEvent"
  ID_FIELD_NAME = "tableId"
  constructor_name = "fromJson"
  ouput_encode_method = "encodeEvent"
  ouput_decode_method = "decodeEvent"

script_classes:
  class Method:
    is_static:bool
    name:str
    arg_types :tuple[str]
  class Constructor:
    name:str
    arg_types = tupe[str]

  class DartClass:
    name 
    constants: Map[str: str|int|float|None] -> maps constant name to its value, if it is mapped to a str, or an int, or a decimal then it should be mapped to the value but if it is mapped to null or a class then it should be mapped to None
    methods
    constructors -> inclused factories
    parent_classes (includes extended classes and implemented mixins)

required helper methods:
  def get_project_root() -> gets the project root checking parent directories searching for the pubsec.yaml, if the home directory is reached then error  displaying no project root found

while parsing caution must be used around comments and mutliline strings
while parsing the dart classes it is verfied that:
  1) one class implements the base class, error messeage: no classes implement base class
  2) each class that implements the base class has the ID_FIELD_NAME defined, error message: missing constant in class_name 
  3) each class that implements base class has a factory or constory or a static method that retuns an instance of the class which matches the counstrumtor_name which takes a dynamic data parameter
  5) each ID_FIELD_NAME is an int, error: id type missmatch class_name
  6) each ID_FIELD_NAME is unique, error: duplicate id class_1:id, class_2:id

example input:
```
class Add extends ProjectEvent{
  TABLE_ID=1
  factory Add.decode(dynamic data)
  @override
  Map<String,dynamic> toJson()
}
class Remove {//extends ProjectEvent{
 TABLE_ID = 3
  factory Add.decode(dynamic data)
  @override
  Map<String,dynamic> toJson()
}

class Swap extends ProjectEvent {
 TABLE_ID = 8
  factory Add.decode(dynamic data)
  @override
  Map<String,dynamic> toJson()
}
"""
class ChangeColor extends ProjectEvent{

 TABLE_ID = 5
  factory Add.decode(dynamic data)
  dynamice encode()
}
"""
```
output should look something like this.

 ```
  import <paths>
  Map<Type,int)> _map = {Add:1,Swap:8}

  Map<String, dynamic> encodeEvent(ProjectEvent event) {
    final type = event.runtimeType;
    final id = _mapEvent[type];

    final encoded = event.toJson();

    return {"t": id, "v": 1, "c": encoded};
  }
  ProjectEvent? decode(Map data){ If(no data["c"] or no data["t"]) return null else switchCase() ... default:null } when decoding only the data["c"] is passed to the fromJson method/constructor
```
if none the program errors displaying the message "no classes in {paths} implement base class {base_class_name}

generate a test.py file generating unit test for each of the functions.

the program is complete when:
- there is 100% test coverage for the python script
- the program can succesfully generate the output file allowing easly encoding and decoding projet events

