import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    //return a Scaffold with a body that contains a Text widget and a button which navigates to About
    return Scaffold(
      body: const Center(
        child: Text('Home'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/about');
        },
        child: const Icon(Icons.arrow_forward),
      ),
    );
  }
}
