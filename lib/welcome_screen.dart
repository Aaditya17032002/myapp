
import 'package:flutter/material.dart';
import 'models/user.dart';

class WelcomeScreen extends StatelessWidget {
  final User user;

  const WelcomeScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar
: AppBar(
        title: const Text('Welcome'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Welcome, ${user.name}!'),
            Text('Your role is: ${user.role}'),
            Text('Your email is: ${user.email}'),
          ],
        ),
      ),
    );
  }
}
