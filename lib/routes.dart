import 'package:clonetalk/home/home.dart';
import 'package:clonetalk/about/about.dart';
import 'package:clonetalk/login/login.dart';
import 'package:clonetalk/profile/profile.dart';
import 'package:flutter/material.dart';

var appRoutes = <String, WidgetBuilder>{
  '/': (BuildContext context) => const HomeScreen(),
  '/about': (BuildContext context) => const AboutScreen(),
  '/login': (BuildContext context) => const LoginScreen(),
  '/profile': (BuildContext context) => const ProfileScreen(),
};
