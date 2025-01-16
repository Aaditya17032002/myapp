import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'models/user.dart';
import 'welcome_screen.dart';

class LoginScreen extends StatefulWidget {
  final Future<Database>? database;

  const LoginScreen({super.key, required this.database});

  @override
  LoginScreenState createState() => LoginScreenState();
}

class LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  Future<User?> _getUserByEmail(String email) async {
    try {
      final db = await widget.database;
      if (db == null) throw Exception("Database is not initialized.");

      List<Map<String, dynamic>> maps = await db.query(
        'users',
        where: 'email = ?',
        whereArgs: [email],
      );

      return maps.isNotEmpty ? User.fromMap(maps.first) : null;
    } catch (e) {
      debugPrint("Error retrieving user: $e");
      return null;
    }
  }

  void _login() async {
    if (_formKey.currentState!.validate()) {
      FocusScope.of(context).unfocus(); // Close keyboard
      String email = _emailController.text.trim();
      String password = _passwordController.text.trim();

      try {
        User? user = await _getUserByEmail(email);

        if (user != null && user.password == password) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => WelcomeScreen(user: user)),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invalid email or password')),
          );
        }
      } catch (e) {
        debugPrint("Error during login: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('An error occurred. Please try again.')),
        );
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Please enter your email';
                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                    return 'Please enter a valid email address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Please enter your password';
                  return null;
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(onPressed: _login, child: const Text('Login')),
            ],
          ),
        ),
      ),
    );
  }
}
