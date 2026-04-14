depends on utils.py 
each file path should be defined relaitve to the root of the project

this is the spec for a python script which generates a jump table for each of the project events.

cli:
  python event_table.py -> generates the jump table file, if it already exist then override it
  python event_table.py -V -> verifies that if python event_table.py was ran the output would match the file that is currently generated at output path.
  python event_table.py -p -> print the generated files instead of writing them to disk using the following format
```
<file path>

<file content>
```

script_constants:
  output_path = "lib/backend/project/code_gen_allowed/event/event_jump_table.pyg.dart"
  paths_to_parse = ["lib/backend/project/code_gen_allowed/event/project_events.dart"]
  base_class_name = "ProjectEvent"
  ID_FIELD_NAME = "tableId"
  constructor_name = "fromJson"
  output_encode_method = "encodeEvent"
  output_decode_method = "decodeEvent"

while parsing the dart classes it is verified that:
  1) one class implements the base class, error message: no classes implement base class
  2) each class that implements the base class has the constant ID_FIELD_NAME defined, error message: missing constant in class_name 
  3) each class that implements base class has a factory or constory or a static method that returns an instance of the class which matches the counstrumtor_name which takes a dynamic data parameter

example input:
```
class Add extends ProjectEvent{
  static const TABLE_ID=1
  factory Add.decode(dynamic data)
  @override
  Map<String,dynamic> toJson()
}
"""
class ChangeColor extends ProjectEvent{
  static const TABLE_ID = 5
  factory ChangeColor.decode(dynamic data)
  @override
  Map<String,dynamic> toJson()
}
"""
```
output should look something like this pseudo code

 ```
  import <paths>
  Map<Type,int)> _map = {Add:Add.TABLE_ID,ChangeColor:ChangeColor.TABLE_ID}

  Map<String, dynamic> encodeEvent(ProjectEvent event) {
    final type = event.runtimeType;
    final id = _mapEvent[type];

    final encoded = event.toJson();

    return {"t": id, "v": 1, "c": encoded};
  }
  ProjectEvent? decode(Map data){ If(no data["c"] or no data["t"]) return null else switch data["t"]... case Add.TABLE_ID ... default:null } when decoding only the data["c"] is passed to the fromJson method/constructor
```
if none the program errors displaying the message "no classes in {paths} implement base class {base_class_name}

generate a event_builder_test.py file generating unit test for each of the functions.

the program is complete when:
- there is 100% test coverage for the python script
- the program can successfully generate the output file allowing easily encoding and decoding project events

