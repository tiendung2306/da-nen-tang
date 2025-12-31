import 'package:flutter/material.dart';
import 'package:flutter_boilerplate/pages/auth/login_page.dart';
import 'package:flutter_boilerplate/pages/auth/register_page.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({Key? key}) : super(key: key);

  @override
  _LandingPageState createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Container(
          width: double.infinity,
          height: MediaQuery.of(context).size.height,
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 50),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              const Text('Welcome', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 30)),
              Column(
                children: <Widget>[
                  MaterialButton(
                    minWidth: double.infinity,
                    height: 60,
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => LoginPage()));
                    },
                    shape: RoundedRectangleBorder(side: const BorderSide(), borderRadius: BorderRadius.circular(50)),
                    child: const Text('Login', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18)),
                  ),
                  const SizedBox(height: 20),
                  MaterialButton(
                    minWidth: double.infinity,
                    height: 60,
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => RegisterPage()));
                    },
                    color: const Color(0xff0095FF),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                    child: const Text('Sign up', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 18)),
                  )
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
