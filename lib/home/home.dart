import 'package:clonetalk/home/home_widget.dart';
import 'package:clonetalk/login/login.dart';
import 'package:clonetalk/services/auth.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    //return a Scaffold with a body that contains a Text widget and a button which navigates to About
    return StreamBuilder(
      stream: AuthService().userStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return const Center(child: Text('Error'));
        } else if (snapshot.hasData) {
          return const HomeWidget();
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}
