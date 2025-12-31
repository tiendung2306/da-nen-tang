import 'package:flutter/material.dart';
import 'package:flutter_boilerplate/pages/auth/register_page.dart';
import 'package:flutter_boilerplate/pages/auth/profile_page.dart';
import 'package:flutter_boilerplate/pages/home/home_page.dart';
import 'package:flutter_boilerplate/pages/post_detail/post_detail_page.dart';

class Routes {
  Routes._();

  //static variables
  static const String home = '/home';
  static const String post_detail = '/post_detail';
  static const String register = '/register';
  static const String profile = '/profile';


  static final routes = <String, WidgetBuilder>{
    home: (BuildContext context) => HomePage(),
    post_detail: (BuildContext context) => PostDetailPage(),
    register: (BuildContext context) => RegisterPage(),
    profile: (BuildContext context) => ProfilePage(),
  };
}
