import 'package:flutter/material.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign In'), centerTitle: true),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Login Screen - Coming in Task 1.2'),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () {
                Navigator.of(context).pushReplacementNamed('/register');
              },
              child: const Text('Go to Register'),
            ),
          ],
        ),
      ),
    );
  }
}
