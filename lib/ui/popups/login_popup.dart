import 'package:flutter/material.dart';
import 'package:parrotaac/backend/server/login_utils.dart';

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
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => const LoginPopup(),
                  );
                },
              )
            : ElevatedButton(onPressed: logout, child: Text("sign out"));
      },
    );
  }
}

class LoginPopup extends StatefulWidget {
  const LoginPopup({super.key});

  @override
  State<LoginPopup> createState() => _LoginPopupState();
}

class _LoginPopupState extends State<LoginPopup> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLogin = true; // toggle between login and create account

  void _submit() async {
    final email = _emailController.text;
    final password = _passwordController.text;

    if (!_isLogin) {
      await createAccountAndSignIn(email, password);
    } else {
      await signIn(email, password);
    }
    print(currentUser.value);

    if (context.mounted) Navigator.of(context).pop();
  }

  void _toggleForm() {
    setState(() {
      _isLogin = !_isLogin;
      _emailController.clear();
      _passwordController.clear();
    });
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
