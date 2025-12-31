import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_boilerplate/providers/auth_provider.dart';

class RegisterPage extends StatefulWidget {
  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailController = TextEditingController();
  final _fullNameController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign Up')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: <Widget>[
              TextFormField(controller: _fullNameController, decoration: const InputDecoration(labelText: 'Full Name'), validator: (val) => val!.isEmpty ? 'Enter a full name' : null),
              TextFormField(controller: _usernameController, decoration: const InputDecoration(labelText: 'Username'), validator: (val) => val!.isEmpty ? 'Enter a username' : null),
              TextFormField(controller: _emailController, decoration: const InputDecoration(labelText: 'Email'), validator: (val) => val!.isEmpty ? 'Enter an email' : null, keyboardType: TextInputType.emailAddress),
              TextFormField(controller: _passwordController, decoration: const InputDecoration(labelText: 'Password'), obscureText: true, validator: (val) => val!.length < 6 ? 'Password too short' : null),
              const SizedBox(height: 20),
              Consumer<AuthProvider>(
                builder: (context, auth, child) {
                  return auth.isLoading
                      ? const CircularProgressIndicator()
                      : ElevatedButton(
                          onPressed: () async {
                            if (_formKey.currentState!.validate()) {
                              final data = {
                                'fullName': _fullNameController.text,
                                'username': _usernameController.text,
                                'email': _emailController.text,
                                'password': _passwordController.text,
                              };
                              final success = await auth.register(data); // FIX: Pass the data map
                              if (success && mounted) {
                                Navigator.pop(context);
                              } 
                            }
                          },
                          child: const Text('Sign Up'),
                        );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
