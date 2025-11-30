import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SignupPage extends StatelessWidget {
  const SignupPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SafeArea(
        child: Padding(
          padding: .all(20),
          child: Column(
            mainAxisAlignment: .center,
            crossAxisAlignment: .center,
            spacing: 50,
            children: [
              Column(
                spacing: 10,
                children: [
                  Text(
                    'Memoria',
                    style: Theme.of(context).textTheme.displayLarge,
                  ),
                  Card(
                    color: Colors.white,
                    child: Image.network(
                      'https://static.thenounproject.com/png/4545700-200.png',
                    ),
                  ),
                  Text(
                    'Will you remember?',
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                ],
              ),
              SignupForm(),
            ],
          ),
        ),
      ),
    );
  }
}

class SignupForm extends StatefulWidget {
  const SignupForm({super.key});

  @override
  State<SignupForm> createState() => _SignupFormState();
}

enum ErrorFieldType { email, password }

class _SignupFormState extends State<SignupForm> {
  final emailEC = TextEditingController();
  final passwordEC = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final minCharacterCount = 8;

  String? emailError;
  String? passwordError;
  bool fieldsCompleted = false;

  void onChanged(String _) {
    setState(() {
      fieldsCompleted = emailEC.text.isNotEmpty && passwordEC.text.isNotEmpty;
    });
  }

  void tryCleanUpError(ErrorFieldType type) {
    setState(() {
      switch (type) {
        case ErrorFieldType.email:
          emailError = null;
          break;
        case ErrorFieldType.password:
          passwordError = null;
          break;
      }
    });
  }

  Future<void> SignIn() async {
    try {
      if (!_formKey.currentState!.validate()) {
        return;
      }

      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: emailEC.text,
            password: passwordEC.text,
          );

      emailError = null;
      passwordError = null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        passwordError = 'The password provided is too weak.';
      } else if (e.code == 'email-already-in-use') {
        emailError = 'The account already exists for that email.';
      }
    } catch (e) {
      print(e);
    }
  }

  @override
  void initState() {
    super.initState();

    emailEC.addListener(() => tryCleanUpError(ErrorFieldType.email));
    passwordEC.addListener(() => tryCleanUpError(ErrorFieldType.password));
  }

  @override
  void dispose() {
    // Clean up the controller when the widget is removed from the
    // widget tree.
    passwordEC.dispose();
    emailEC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        spacing: 10,
        children: [
          Card(
            color: Colors.transparent,
            child: TextFormField(
              controller: emailEC,
              onChanged: onChanged,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(25.0)),
                ),
                hintText: 'Enter email',
                errorText: emailError,
              ),
            ),
          ),
          Card(
            color: Colors.transparent,
            child: TextFormField(
              obscureText: true,
              onChanged: onChanged,
              controller: passwordEC,
              validator: (value) {
                if (value == null || value.length < minCharacterCount) {
                  return "Minimum of 8 characters";
                }
              },
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(25.0)),
                ),
                hintText: 'Enter password',
                errorText: passwordError,
              ),
            ),
          ),
          ElevatedButton(
            style: ButtonStyle(
              backgroundColor: .fromMap({
                WidgetState.disabled: Theme.of(context).colorScheme.onSecondary,
                WidgetState.hovered: Theme.of(context).colorScheme.onPrimary,
                WidgetState.any: Theme.of(context).colorScheme.inversePrimary,
              }),
            ),
            onPressed: !fieldsCompleted
                ? null
                : () async {
                    await SignIn();
                  },
            child: const Text('Sign in'),
          ),
        ],
      ),
    );
  }
}
