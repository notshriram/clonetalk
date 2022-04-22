import 'package:flutter/material.dart';

class LoginButton extends StatelessWidget {
  final Color color;
  final String text;
  final Function loginMethod;
  final IconData icon;

  const LoginButton(
      {Key? key,
      required this.color,
      required this.text,
      required this.loginMethod,
      required this.icon})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
        margin: const EdgeInsets.symmetric(horizontal: 30),
        child: ElevatedButton.icon(
          icon: Icon(icon, color: Colors.white, size: 30),
          label: Text(text, style: const TextStyle(color: Colors.white)),
          style: TextButton.styleFrom(
            backgroundColor: color,
            padding: const EdgeInsets.symmetric(vertical: 15),
          ),
          onPressed: () => loginMethod(),
        ));
  }
}
