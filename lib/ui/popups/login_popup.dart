import 'package:flutter/material.dart';
import 'package:parrotaac/backend/global_restoration_data.dart';
import 'package:parrotaac/backend/server/login_utils.dart';
import 'package:parrotaac/project_selector_constants.dart';
import 'package:parrotaac/ui/popups/show_restorable_popup.dart';

class LoginButton extends StatelessWidget {
  const LoginButton({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: currentUser,
      builder: (context, value, child) {
        return value == null
            ? ElevatedButton(
                child: const Text("sign in"),
                onPressed: () => showSigninPopup(context),
              )
            : ElevatedButton(onPressed: logout, child: Text("sign out"));
      },
    );
  }
}

class LoginPopup extends StatefulWidget {
  final String? initialEmail;
  const LoginPopup({super.key, this.initialEmail});

  @override
  State<LoginPopup> createState() => _LoginPopupState();
}

class _LoginPopupState extends State<LoginPopup> {
  late final TextEditingController _emailController, _passwordController;
  bool get _isLogin =>
      globalRestorationQuickstore[loginModeKey] ??
      true; // toggle between login and create account
  Future<void> _setIsLogin(bool val) =>
      globalRestorationQuickstore.writeData(loginModeKey, val);

  @override
  void initState() {
    _emailController = TextEditingController(text: widget.initialEmail);
    _emailController.addListener(() async {
      await globalRestorationQuickstore.writeData(
        signInEmailKey,
        _emailController.text,
      );
    });
    _passwordController = TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() async {
    final email = _emailController.text;
    final password = _passwordController.text;

    if (!_isLogin) {
      await createAccountAndSignIn(email, password);
    } else {
      await signIn(email, password);
    }

    if (context.mounted) Navigator.of(context).pop();
  }

  void _toggleForm() async {
    await _setIsLogin(!_isLogin);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isLogin ? "Sign in" : "Create Account"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: "Email",
              prefixIcon: Icon(Icons.person_outlined),
            ),
          ),
          TextField(
            controller: _passwordController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: "Password",
              prefixIcon: Icon(Icons.lock_outlined),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _toggleForm,
          child: Text(
            _isLogin
                ? "Need an account? Sign Up"
                : "Already have an account? Login",
          ),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: Text(_isLogin ? "Sign in" : "Sign Up"),
        ),
      ],
    );
  }
}

Future<void> showSigninPopup(BuildContext context) async {
  String? email = globalRestorationQuickstore[signInEmailKey];

  if (context.mounted) {
    return showRestorableDialog(
      context: context,
      adminLocked: true,
      mainLabel: currentProjectSelectorDialogKey,
      mainLabelValue: ProjectDialog.loginDialog.name,
      fieldLabels: {signInEmailKey},
      builder: (_) => LoginPopup(initialEmail: email),
    );
  }
}
