import 'package:clonetalk/shared/bottom_nav.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class HomeWidget extends StatelessWidget {
  const HomeWidget({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: const Center(
        child: Text('Home'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/new');
        },
        child: const FaIcon(FontAwesomeIcons.plus),
      ),
      bottomNavigationBar: const BottomNavBar(),
    );
  }
}
