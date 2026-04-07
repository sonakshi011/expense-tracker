import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'register_screen.dart';

 class LoginScreen extends StatefulWidget {
   const LoginScreen({super.key});

   @override
   State<LoginScreen> createState() => _LoginScreenState();
 }

 class _LoginScreenState extends State<LoginScreen> {
   final TextEditingController _emailController = TextEditingController();
   final TextEditingController _passwordController = TextEditingController();

   final _formKey = GlobalKey<FormState>();
   bool _isLoading = false;
   bool _obscurePassword = true;

   Future<void> _login() async {
     if(!_formKey.currentState!.validate()) return;
     setState(() => _isLoading = true);

     try{
       await FirebaseAuth.instance.signInWithEmailAndPassword(
         email: _emailController.text.trim(),
         password: _passwordController.text.trim(),
       );
     } on FirebaseAuthException catch (e) {

       String message = 'Something went wrong';
       if (e.code == 'user-not-found') {
         message = 'No account found with this email.';
       } else if (e.code == 'wrong-password') {
         message = 'Incorrect password. Please try again.';
       } else if (e.code == 'invalid-email') {
         message = 'Please enter a valid email address.';
       } else if (e.code == 'invalid-credential') {
         message = 'Email or password is incorrect.';
       }
       ScaffoldMessenger.of(context as BuildContext).showSnackBar(
         SnackBar(content: Text(message), backgroundColor: Colors.red),
       );
     } finally {
       setState(() => _isLoading = false);
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
       backgroundColor: Colors.white,
       body: SafeArea(
         child: SingleChildScrollView(
           padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
           child: Form(
             key: _formKey,
             child: Column(
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                 Center(
                   child: Container(
                     padding: const EdgeInsets.all(20),
                     decoration: BoxDecoration(
                       color: Colors.blue.shade50,
                       shape: BoxShape.circle,
                     ),
                     child: Icon(Icons.account_balance_wallet,
                                  size: 60, color: Colors.blue.shade700),
                   ),
                 ),
                 const SizedBox(height: 30),
                 const Text(
                   'Welcome Back!',
                   style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                 ),
                 const SizedBox(height: 6),
                 Text(
                   'Login to continue tracking your expenses',
                   style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                 ),
                 const SizedBox(height: 36),

                 const Text('Email', style: TextStyle(fontWeight: FontWeight.w600)),
                 const SizedBox(height: 8),
         TextFormField(
           controller: _emailController,
           keyboardType: TextInputType.emailAddress,
           decoration: _inputDecoration('Enter your email', Icons.email_outlined),

               validator: (value){
                 if (value == null || value.isEmpty) return 'Email is required';
                 if (!value.contains('@')) return 'Enter a valid email';
                 return null;
               },
         ),
                 const SizedBox(height: 20),

                 const Text('Password', style: TextStyle(fontWeight: FontWeight.w600)),
                 const SizedBox(height: 8),
                 TextFormField(
                   controller: _passwordController,
                   obscureText: _obscurePassword,
                   decoration: _inputDecoration(
                     'Enter your password', Icons.lock_outline,
                   ).copyWith(
                     suffixIcon:IconButton(
                       icon: Icon(
                         _obscurePassword ? Icons.visibility_off : Icons.visibility,
                         color: Colors.grey,
                       ),
                       onPressed: () {
                         setState(() => _obscurePassword = !_obscurePassword);
                       },
                     ),
                   ),
                   validator: (value) {
                     if (value == null || value.isEmpty) return 'Password is required';
                     if (value.length < 6) return 'Password must be at least 6 characters';
                     return null;
                   },
                 ),
                 const SizedBox(height: 32),
               SizedBox(
                 width: double.infinity,
                 height: 52,
                 child: ElevatedButton(
                   onPressed: _isLoading ? null : _login,
                   style: ElevatedButton.styleFrom(
                     backgroundColor: Colors.blue.shade700,
                     shape: RoundedRectangleBorder(
                       borderRadius: BorderRadius.circular(12),

                     ),
                   ),
                   child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Login',
                       style: TextStyle(fontSize: 16, color: Colors.white)),
                   ),
                 ),
         const SizedBox(height: 24),

                 Center(
                   child: GestureDetector(
                     onTap: () {
                       Navigator.push(
                         context,
                         MaterialPageRoute(
                             builder: (_) => const RegisterScreen()),
                       );
                     },
                     child: RichText(
                       text: TextSpan(
                         text: "Don't have an account?" ,
                         style: TextStyle(color: Colors.grey.shade600),
                         children: [
                           TextSpan(
                             text: 'Register',
                             style: TextStyle(color: Colors.blue.shade700, fontWeight: FontWeight.bold,
                             ),
                           ),
                         ],
                       ),
                     ),
                 ),
                 ),
               ],
             ),
           ),
         ),
       ),
     );
   }
   InputDecoration _inputDecoration(String hint, IconData icon) {
     return InputDecoration(
       hintText: hint,
       prefixIcon: Icon(icon, color: Colors.grey),
       filled: true,
       fillColor: Colors.grey.shade100,
       border: OutlineInputBorder(
         borderRadius: BorderRadius.circular(12),
         borderSide: BorderSide.none,
       ),
       focusedBorder: OutlineInputBorder(
         borderRadius: BorderRadius.circular(12),
         borderSide: BorderSide(color: Colors.blue.shade700,width: 1.5),
       ),
       errorBorder: OutlineInputBorder(
         borderRadius: BorderRadius.circular(12),
         borderSide: const BorderSide(color: Colors.red),
       ),
       focusedErrorBorder: OutlineInputBorder(
         borderRadius: BorderRadius.circular(12),
         borderSide: const BorderSide(color: Colors.red),
       ),
     );
   }
 }
