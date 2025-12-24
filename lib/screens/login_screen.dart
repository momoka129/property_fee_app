import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../routes.dart';
import '../providers/app_provider.dart';
import '../models/user_model.dart';
import '../widgets/keyboard_text_field.dart';
import '../widgets/classical_dialog.dart'; // 确保引入了您的通用弹窗组件

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // --- 新增：处理忘记密码逻辑 ---
  Future<void> _handleForgotPassword() async {
    final email = _emailController.text.trim();

    // 1. 校验邮箱是否为空
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your email address first.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 2. 调用 Firebase 发送重置邮件
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

      if (!mounted) return;

      // 3. 发送成功，显示雅致弹窗
      showDialog(
        context: context,
        builder: (context) => ClassicalDialog(
          title: 'Email Sent',
          content:
          'A password reset link has been sent to your email:\n\n$email\n\nPlease check your inbox and follow the instructions to reset your password.',
          confirmText: 'OK',
          cancelText: 'Close', // Optional: can be used as a secondary close button
          onConfirm: () {
            Navigator.of(context).pop();
          },
        ),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      // 错误处理
      String message = 'Failed to send reset email.';
      if (e.code == 'user-not-found') {
        message = 'No user found for this email.';
      } else if (e.code == 'invalid-email') {
        message = 'Invalid email address.';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
  // ---------------------------

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    try {
      final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email, password: password);
      final uid = cred.user?.uid;
      Map<String, dynamic>? userData;
      if (uid != null) {
        final docRef = FirebaseFirestore.instance.collection('accounts').doc(uid);
        final doc = await docRef.get();
        if (doc.exists) {
          userData = doc.data();
        } else {
          final q = await FirebaseFirestore.instance
              .collection('accounts')
              .where('email', isEqualTo: email)
              .limit(1)
              .get();
          if (q.docs.isNotEmpty) {
            final acc = q.docs.first.data();
            userData = Map<String, dynamic>.from(acc);
            await docRef.set({
              'id': uid,
              'email': acc['email'] ?? email,
              'name': acc['name'] ?? '',
              'role': acc['role'] ?? 'resident',
              'propertySimpleAddress': acc['propertySimpleAddress'] ?? '',
              'phoneNumber': acc['phoneNumber'],
              'createdAt': FieldValue.serverTimestamp(),
              'avatar': acc['avatar'],
            });
          }
        }
      }

      final appProvider = Provider.of<AppProvider>(context, listen: false);
      UserModel userModel;
      if (userData != null) {
        final createdAtRaw = userData['createdAt'];
        DateTime createdAt;
        if (createdAtRaw is Timestamp) {
          createdAt = createdAtRaw.toDate();
        } else if (createdAtRaw is String) {
          createdAt = DateTime.tryParse(createdAtRaw) ?? DateTime.now();
        } else {
          createdAt = DateTime.now();
        }
        userModel = UserModel(
          id: uid ?? (userData['id'] ?? ''),
          email: userData['email'] ?? email,
          name: userData['name'] ?? '',
          phoneNumber: userData['phoneNumber'],
          propertySimpleAddress: userData['propertySimpleAddress'] ?? '',
          role: userData['role'] ?? 'resident',
          createdAt: createdAt,
          avatar: userData['avatar'],
        );
      } else {
        userModel = UserModel(
          id: uid ?? '',
          email: email,
          name: cred.user?.displayName ?? '',
          phoneNumber: cred.user?.phoneNumber,
          propertySimpleAddress: '',
          role: 'resident',
          createdAt: DateTime.now(),
          avatar: cred.user?.photoURL,
        );
      }

      appProvider.updateUser(userModel);

      setState(() => _isLoading = false);
      if (!mounted) return;
      if (userModel.role == 'admin') {
        Navigator.pushReplacementNamed(context, AppRoutes.adminHome);
      } else {
        Navigator.pushReplacementNamed(context, AppRoutes.home);
      }
      return;
    } on FirebaseAuthException catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;

      // 之前添加的未注册弹窗逻辑
      if (e.code == 'user-not-found' || e.code == 'invalid-credential') {
        showDialog(
          context: context,
          builder: (context) => ClassicalDialog(
            title: 'Unregistered Account',
            content: 'The email address you entered does not appear to be registered. \nWould you like to register a new account now?',
            confirmText: 'Go to register',
            onConfirm: () {
              Navigator.of(context).pop();
              Navigator.pushNamed(context, AppRoutes.register);
            },
          ),
        );
        return;
      }

      String message = 'Authentication failed';
      if (e.code == 'wrong-password') {
        message = 'Incorrect password.';
      } else if (e.message != null) {
        message = e.message!;
      }
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.red));
      return;
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Login failed: $e'), backgroundColor: Colors.red));
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(
                      Icons.account_balance,
                      size: 80,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Smart Property',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Property Management System',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 48),
                    KeyboardTextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        hintText: 'Enter your email',
                        prefixIcon: Icon(Icons.email_outlined),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email';
                        }
                        if (!value.contains('@')) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    KeyboardTextField(
                      controller: _passwordController,
                      obscureText: !_isPasswordVisible,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        hintText: 'Enter your password',
                        prefixIcon: const Icon(Icons.lock_outlined),
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isPasswordVisible
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          onPressed: () {
                            setState(() {
                              _isPasswordVisible = !_isPasswordVisible;
                            });
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your password';
                        }
                        if (value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),

                    // --- 新增：忘记密码按钮 ---
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _isLoading ? null : _handleForgotPassword,
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.grey.shade700, // 颜色稍微深一点
                        ),
                        child: const Text('Forgot Password?'),
                      ),
                    ),
                    // -----------------------

                    const SizedBox(height: 24),
                    SizedBox(
                      height: 50,
                      child: FilledButton(
                        onPressed: _isLoading ? null : _handleLogin,
                        child: _isLoading
                            ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                            : const Text('Login'),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Don't have an account?"),
                        TextButton(
                          onPressed: () {
                            Navigator.pushNamed(context, AppRoutes.register);
                          },
                          child: const Text('Register'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}