import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lapboost_app/models/sql_service.dart';
import 'package:lapboost_app/screens/main_page.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final firstNameController = TextEditingController(),
      lastNameController = TextEditingController(),
      phoneNumberController = TextEditingController(),
      usernameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool isLogin = true;

  var isObscured = true.obs;

  // This method is for login form
  Widget loginForm() {
    return Column(
      children: [
        emailField(),
        const SizedBox(height: 16),
        passwordField(),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () {
            setState(() {
              isLogin = false; // Switch to register screen
              emailController.clear();
              passwordController.clear();
              isObscured.value = true;
            });
          },
          style: TextButton.styleFrom(),
          child: const Text(
            'Don\'t have an account? Register',
            style: TextStyle(
                decoration: TextDecoration.underline,
                decorationColor: Color(0xFF33ddc5),
                color: Color(0xFF33ddc5)),
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: () async {
            if (_formKey.currentState!.validate()) {
              final user = await SqlService.getUser(
                emailController.text.trim(),
                passwordController.text.trim(),
              );

              if (user != null) {
                // Navigate to MainPage if user is found
                Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (context) => MainPage(
                        user: user,
                      ),
                    ),
                    (route) => false);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Unable to find User')),
                );
              }
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF33ddc5),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            textStyle:
                const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          child: const Text('Sign in'),
        ),
      ],
    );
  }

  // This method is for register form
  Widget registerForm() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 16, 0, 16),
          child: Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: firstNameController,
                  decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'First Name',
                      errorStyle: TextStyle(color: Colors.red),
                      prefixIcon: Icon(Icons.person)),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please write your first name';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(
                width: 8,
              ),
              Expanded(
                child: TextFormField(
                  controller: lastNameController,
                  decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Last Name',
                      errorStyle: TextStyle(color: Colors.red),
                      prefixIcon: Icon(Icons.badge)),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please write your last name';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: TextFormField(
            controller: phoneNumberController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Phone No.',
                errorStyle: TextStyle(color: Colors.red),
                prefixIcon: Icon(Icons.phone)),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please write your phone number';
              } else if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
                return 'Please enter a valid phone number (only numbers)';
              } else if (value.length != 11) {
                return 'Please enter a valid Egyptian phone number';
              }
              return null;
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: TextFormField(
            controller: usernameController,
            decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Username',
                errorStyle: TextStyle(color: Colors.red),
                prefixIcon: Icon(Icons.account_circle_rounded)),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please write a username';
              }
              return null;
            },
          ),
        ),
        emailField(),
        const SizedBox(height: 16),
        passwordField(),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () {
            setState(() {
              isLogin = true; // Switch back to login screen
              emailController.clear();
              passwordController.clear();
              firstNameController.clear();
              lastNameController.clear();
              phoneNumberController.clear();
              isObscured.value = true;
            });
          },
          style: TextButton.styleFrom(),
          child: const Text(
            'Already have an account? Login',
            style: TextStyle(
                decoration: TextDecoration.underline,
                decorationColor: Color(0xFF33ddc5),
                color: Color(0xFF33ddc5)),
          ),
        ),
        ElevatedButton(
          onPressed: () async {
            if (_formKey.currentState!.validate()) {
              signUp(
                  emailController.text,
                  passwordController.text,
                  usernameController.text,
                  firstNameController.text,
                  lastNameController.text,
                  phoneNumberController.text);
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF33ddc5),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            textStyle:
                const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          child: const Text('Sign up'),
        ),
      ],
    );
  }

  Widget emailField() {
    return TextFormField(
      controller: emailController,
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        labelText: 'Email',
        prefixIcon: Icon(Icons.account_box),
        errorStyle: TextStyle(color: Colors.red),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter an email';
        } else if (!RegExp(
                r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
            .hasMatch(value)) {
          return 'Please enter a valid email';
        }
        return null;
      },
    );
  }

  Widget passwordField() {
    return Obx(() {
      return TextFormField(
        controller: passwordController,
        obscureText: isObscured.value,
        decoration: InputDecoration(
          border: const OutlineInputBorder(),
          labelText: 'Password',
          prefixIcon: const Icon(Icons.lock),
          suffixIcon: IconButton(
            onPressed: () {
              isObscured.value = !(isObscured.value);
            },
            icon: Icon(
              isObscured.value
                  ? Icons.remove_red_eye_outlined
                  : Icons.visibility_off_outlined,
            ),
          ),
          errorStyle: const TextStyle(color: Colors.red),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter a password';
          }
          return null;
        },
      );
    });
  }

  Future<void> signUp(
    String email,
    String password,
    String username,
    String firstName,
    String lastName,
    String phoneNumber,
  ) async {
    final conn = await SqlService.getConnection();
    //Check if user already exists
    final result = await conn.query('''
    SELECT Email FROM customers
    WHERE Email="$email" OR Mobile_Number="$phoneNumber" OR Social_Media_Handle='@$username'
    ''');
    //Add user
    if (result.isEmpty) {
      await conn.query('''
      INSERT INTO customers (Customer_FirstName,Customer_LastName,Mobile_Number,Email,Password,Social_Media_Handle)
VALUES ('$firstName', '$lastName',$phoneNumber,'$email','$password', '@$username');
      ''');
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account created successfully!')));
      setState(() {
        isLogin = true; // Go back to login
        emailController.clear();
        passwordController.clear();
        usernameController.clear();
        phoneNumberController.clear();
        firstNameController.clear();
        lastNameController.clear();
        isObscured.value = true;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User credentials already exist')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Welcome to the LapBoost App!'),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const Text(
                    'LapBoost',
                    style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  isLogin ? loginForm() : registerForm(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
