import 'package:clonetalk/login/login_button.dart';
import 'package:clonetalk/services/auth.dart';
import 'package:flutter/material.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Login'),
          ElevatedButton(
            onPressed: () {
              Navigator.pushNamed(context, '/about');
            },
            child: const Text('Go to About'),
          ),
          Flexible(
            child: LoginButton(
              icon: Icons.person,
              text: 'Login as Guest',
              color: Colors.blue,
              loginMethod: AuthService().anonLogin,
            ),
          ),
          LoginButton(
              color: Colors.blue,
              text: 'Login with Google',
              loginMethod: AuthService().googleLogin,
              icon: Icons.g_mobiledata)
        ],
      ),
    ));
  }
}
