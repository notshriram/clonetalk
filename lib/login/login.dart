import 'package:clonetalk/login/login_button.dart';
import 'package:clonetalk/services/auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Container(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            RichText(
                text: TextSpan(children: [
              TextSpan(
                  text: 'Clone',
                  style: GoogleFonts.poppins(
                      fontSize: 40,
                      fontWeight: FontWeight.w300,
                      color: Colors.indigo)),
              TextSpan(
                  text: 'talk.',
                  style: GoogleFonts.poppins(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: Colors.amber)),
            ])),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/about');
              },
              child: const Text('Go to About'),
            ),
            LoginButton(
              icon: FontAwesomeIcons.person,
              text: 'Login as Guest',
              color: Colors.purple,
              loginMethod: AuthService().anonLogin,
            ),
            LoginButton(
                color: Colors.blue,
                text: 'Login with Google',
                loginMethod: AuthService().googleLogin,
                icon: FontAwesomeIcons.google)
            //set padding
          ],
        ),
      ),
    ));
  }
}
