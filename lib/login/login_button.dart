import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

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
        margin: const EdgeInsets.symmetric(horizontal: 40),
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: ElevatedButton.icon(
          icon: FaIcon(icon),
          label: Text(text, style: const TextStyle(color: Colors.white)),
          style: TextButton.styleFrom(
            minimumSize: const Size.fromHeight(30),
            backgroundColor: color,
            padding: const EdgeInsets.all(15),
          ),
          onPressed: () => loginMethod(),
        ));
  }
}
