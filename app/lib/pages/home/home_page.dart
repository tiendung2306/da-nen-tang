import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_boilerplate/providers/auth_provider.dart';

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final userInfo = context.watch<AuthProvider>().userInfo;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trang Chủ'),
      ),
      // Add a null check before building the body
      body: userInfo == null
          ? const Center(child: CircularProgressIndicator()) // Show a loader if user info is not ready
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Chào mừng trở lại,',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  Text(
                    userInfo.fullName, // Now it's safe to access fullName
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
    );
  }
}
