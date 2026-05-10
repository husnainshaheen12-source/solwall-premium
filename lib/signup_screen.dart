import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'utils/auth.dart';

class SignupScreen extends StatefulWidget {
  final Function(bool) changeThemeMode;

  const SignupScreen({super.key, required this.changeThemeMode});

  @override
  SignupScreenState createState() => SignupScreenState();
}

class SignupScreenState extends State<SignupScreen> {
  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  Future<void> signup() async {
    final fullName = fullNameController.text.trim();
    final username = usernameController.text.trim();
    final password = passwordController.text;

    if (fullName.isEmpty || username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("All fields are required")),
      );
      return;
    }

    try {
      await Auth.signup(fullName, username, password);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
      return;
    }

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Signup successful. Please login.")),
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => LoginScreen(changeThemeMode: widget.changeThemeMode),
      ),
    );
  }

  @override
  void dispose() {
    fullNameController.dispose();
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
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
                            'Signup',
                            style: TextStyle(
                                fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 20),
                          TextField(
                            controller: fullNameController,
                            decoration:
                            const InputDecoration(labelText: 'Full Name'),
                          ),
                          TextField(
                            controller: usernameController,
                            decoration:
                            const InputDecoration(labelText: 'Username'),
                          ),
                          TextField(
                            controller: passwordController,
                            decoration:
                            const InputDecoration(labelText: 'Password'),
                            obscureText: true,
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: signup,
                            child: const Text('Sign Up'),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => LoginScreen(
                                      changeThemeMode:
                                      widget.changeThemeMode),
                                ),
                              );
                            },
                            child:
                            const Text("Already have an account? Login"),
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
