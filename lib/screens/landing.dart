import 'package:flutter/material.dart';
import '../models/user.dart';
import 'todo_list_screen.dart';
import 'package:uuid/uuid.dart';
import '../util/firestoreCollections.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  final _uuid = const Uuid();
  User _userLoggingIn = User.blankUser;
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TaskMaster'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 100,
                    child: Text(
                      'Username:',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                  SizedBox(
                    width: 200,
                    child: TextField(
                      controller: _usernameController,
                      decoration: const InputDecoration(
                        hintText: 'Enter your username',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 100,
                    child: Text(
                      'Password:',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                  SizedBox(
                    width: 200,
                    child: TextField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        hintText: 'Enter your password',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                    if (
                        (_usernameController.text != '') &&
                        (_passwordController.text != '')
                        ) {
                            _userLoggingIn = User(
                                id: _uuid.v4(),
                                username: _usernameController.text,
                                name: '',
                                email: '',
                                password: _passwordController.text,
                            );
                            final navigatorContext = context;
                            final userSaved = await FirestoreCollections.saveUser(_userLoggingIn, context);
                            if (userSaved && navigatorContext.mounted) {
                              Navigator.pushReplacement(
                                  navigatorContext,
                                  MaterialPageRoute(builder: (context) => const TodoListScreen()),
                              );
                            }
                            return;
                    }
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Please enter a username and password'),
                        ),
                    );
                    return;
                },
                child: const Text('Sign Up'),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  final navigatorContext = context;
                  final user = await FirestoreCollections.getUser(_usernameController.text, _passwordController.text, context);
                  if (user != null && navigatorContext.mounted) {
                    Navigator.pushReplacement(
                        navigatorContext,
                        MaterialPageRoute(builder: (context) => const TodoListScreen()),
                    );
                  }
                },
                child: const Text('Sign In'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}