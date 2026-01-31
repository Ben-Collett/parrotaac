const currentProjectSelectorDialogKey = "current project dialog";
const newProjectNameKey = "selector new project name";
const newRowCountkey = "selector new row count";
const newColCountkey = "selector new col count";
const newProjectImagePathKey = "selector new project image path";
const selectedProjectNamesKey = "selector selected names";
const normalDeleteNameKey = "selector normal delete name";
const signInEmailKey = "email sign in key";
const loginModeKey = "login mode";

enum ProjectDialog {
  createProjectDialog,
  bulkDeleteDialog,
  normalDeleteDialog,
  supportDialog,
  loginDialog;

  static ProjectDialog? fromName(dynamic name) =>
      ProjectDialog.values.where((dial) => dial.name == name).firstOrNull;
}
