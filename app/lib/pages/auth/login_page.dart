import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_boilerplate/providers/auth_provider.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: <Widget>[
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(labelText: 'Username'),
                validator: (val) => val!.isEmpty ? 'Enter a username' : null,
              ),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
                validator: (val) => val!.length < 6 ? 'Password must be at least 6 characters' : null,
              ),
              const SizedBox(height: 20),
              Consumer<AuthProvider>(
                builder: (context, auth, child) {
                  if (auth.isLoading) {
                    return const CircularProgressIndicator();
                  }
                  return ElevatedButton(
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        // FIX: Pass both username and password
                        final success = await auth.login(
                          _usernameController.text,
                          _passwordController.text,
                        );
                        if (!success && mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(auth.errorMessage ?? 'Login Failed')),
                          );
                        }
                      }
                    },
                    child: const Text('Login'),
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
