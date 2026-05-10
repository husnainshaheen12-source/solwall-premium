import 'package:flutter/material.dart';
import 'signup_screen.dart';
import 'utils/auth.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  final Function(bool) changeThemeMode;

  const LoginScreen({super.key, required this.changeThemeMode});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  Future<void> login() async {
    final username = usernameController.text.trim();
    final password = passwordController.text;

    final result = await Auth.login(username, password);

    if (!mounted) return;

    if (result) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => HomeScreen(changeThemeMode: widget.changeThemeMode),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid username or password')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/pad_screenshot_O2Q2F9W0P4.png',
            fit: BoxFit.cover,
          ),
          Center(
            child: SingleChildScrollView(
              child: Column(
                children: [
                const Column(
  children: [
    Text(
      'University of Management and Technology',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 16,
        color: Colors.white,
        fontWeight: FontWeight.w600,
      ),
    ),
    SizedBox(height: 6),
    Text(
      'SolWall Premium',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 32,
        color: Colors.white,
        fontWeight: FontWeight.bold,
      ),
    ),
    SizedBox(height: 4),
    Text(
      'Wallpaper App',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 18,
        color: Colors.white70,
        fontWeight: FontWeight.w500,
      ),
    ),
  ],
),
                  const SizedBox(height: 30),
                  Card(
                    color: const Color.fromARGB(229, 255, 255, 255),
                    margin: const EdgeInsets.symmetric(horizontal: 30),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          const Text(
                            'Login',
                            style: TextStyle(
                                fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 20),
                          TextField(
                            controller: usernameController,
                            decoration: const InputDecoration(
                              labelText: 'Username',
                            ),
                          ),
                          TextField(
                            controller: passwordController,
                            decoration: const InputDecoration(
                              labelText: 'Password',
                            ),
                            obscureText: true,
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: login,
                            child: const Text('Login'),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => SignupScreen(
                                    changeThemeMode: widget.changeThemeMode,
                                  ),
                                ),
                              );
                            },
                            child: const Text("Don't have an account? Sign up"),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
