
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
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

  // Microsoft OAuth 2.0 details
  final String _clientId =
      '3f3fab13-4f7d-4494-9edf-24f32e1325b5'; // Replace with your client ID
  final String _redirectUri =
      'com.example.myapp://auth'; // Replace with your redirect URI
  final String _tenantId =
      '73136b73-224c-40dc-8a8d-03e6ab8917d8'; // Replace with your tenant ID (e.g., 'common' for multi-tenant)
  final String _authEndpoint =
      'https://login.microsoftonline.com/73136b73-224c-40dc-8a8d-03e6ab8917d8/oauth2/v2.0/authorize'; // Replace YOUR_TENANT_ID (e.g., 'common')
  final String _tokenEndpoint =
      'https://login.microsoftonline.com/73136b73-224c-40dc-8a8d-03e6ab8917d8/oauth2/v2.0/token'; // Replace YOUR_TENANT_ID (e.g., 'common')
  final String _scopes =
      'openid profile email User.Read'; // Add necessary scopes

  String? _accessToken;
  late WebViewController _webViewController;
  bool _isLoading = false;
  bool _webViewLoaded = false; // Add this line

  Future<User?> _getUserByEmail(String email) async {
    try {
      final db = await widget.database;
      if (db == null) {
        throw Exception("Database is not initialized.");
      }

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

  Future<void> _saveUserToDatabase(User user) async {
    final db = await widget.database;
    if (db != null) {
      await db.insert(
        'users',
        user.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  Future<void> _loginWithMicrosoft() async {
    final String authUrl =
        '$_authEndpoint?client_id=$_clientId&response_type=code&redirect_uri=${Uri.encodeComponent(_redirectUri)}&scope=${Uri.encodeComponent(_scopes)}';

    setState(() {
      _isLoading = true;
      _webViewLoaded = false; // Reset when starting login
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          content: SizedBox(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height * 0.8,
            child: Stack(
              children: [
                WebViewWidget(
                    controller: _webViewController = WebViewController()
                      ..setJavaScriptMode(JavaScriptMode.unrestricted)
                      ..setNavigationDelegate(
                        NavigationDelegate(
                          onPageStarted: (String url
) {
                            setState(() {
                             _webViewLoaded = false; // Start loading again
                            });
                          },
                          onPageFinished: (String url) {
                            setState(() {
                              _webViewLoaded = true; // Finish loading
                            });
                            if (url.startsWith(_redirectUri)) {
                              final uri = Uri.parse(url);
                              final code = uri.queryParameters['code'];
                              if (code != null) {
                                _getAccessToken(code);
                              }
                            }
                          },
                         onWebResourceError: (WebResourceError error){
                             debugPrint("Web resource error: $error");
                          },
                        ),
                      )
                      ..loadRequest(Uri.parse(authUrl))),
                if (_isLoading && !_webViewLoaded) // Show only while webview is loading
                  const Center(child: CircularProgressIndicator()),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _getAccessToken(String code) async {
    setState(() {
      _isLoading = true;
    });
    try {
      final response = await http.post(
        Uri.parse(_tokenEndpoint),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'client_id': _clientId,
          'code': code,
          'redirect_uri': _redirectUri,
          'grant_type': 'authorization_code',
          'client_secret': 'YOUR_CLIENT_SECRET' // Add this field if necessary.
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _accessToken = data['access_token'];
        await _getUserDetails();
      } else {
        throw Exception('Failed to get access token: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error getting access token: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _getUserDetails() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final response = await http.
get(
        Uri.parse('https://graph.microsoft.com/v1.0/me'),
        headers: {
          'Authorization': 'Bearer $_accessToken',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Extract user details
        final String userName = data['displayName'];
        final String userEmail = data['mail'] ?? data['userPrincipalName'];

        // Assume a default role until you fetch it from your backend
        const String userRole = 'user'; // Default role

        User newUser = User(
            name: userName, email: userEmail, password: '', role: userRole);
        await _saveUserToDatabase(newUser);

        Navigator.of(context).pop();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => WelcomeScreen(user: newUser),
          ),
        );
      } else {
        throw Exception('Failed to get user details: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error getting user details: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
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
    //_webViewController.dispose(); //remove dispose for _webViewController
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Stack(children: [
        Padding(
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
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
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
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                ElevatedButton(onPressed: _login, child: const Text('Login')),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loginWithMicrosoft,
                  child: const Text('Login with Microsoft'),
                ),
              ],
            ),
          ),
        ),
        if (_isLoading && !_webViewLoaded) const Center(child: CircularProgressIndicator()), // Add this line in the main screen
      ]),
    );
  }
}
