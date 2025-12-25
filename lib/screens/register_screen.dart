import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pinput/pinput.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/user_model.dart';
import '../routes.dart';
import '../services/firestore_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  String _selectedBuilding = 'Alpha Building';
  String _selectedFloor = 'G';
  String _selectedUnit = '01';
  bool _isLoading = false;

  String? _errorMessage;
  // Temporary toggle to disable address existence check while debugging registration.
  // Set to true to re-enable address validation.
  bool _enableAddressValidation = false;

  @override
  void initState() {
    super.initState();
    // Clear inline error when user edits any input
    _nameController.addListener(_clearError);
    _emailController.addListener(_clearError);
    _passwordController.addListener(_clearError);
    _phoneController.addListener(_clearError);
  }

  @override
  void dispose() {
    _nameController.removeListener(_clearError);
    _emailController.removeListener(_clearError);
    _passwordController.removeListener(_clearError);
    _phoneController.removeListener(_clearError);
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _clearError() {
    if (_errorMessage != null) {
      setState(() {
        _errorMessage = null;
      });
    }
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final phone = _phoneController.text.trim();
    final building = _selectedBuilding;
    final propertyAddress = '$building ${_selectedFloor}${_selectedUnit}';

    try {
      // Check if address is already occupied (can be skipped during debugging)
      final addressExists = _enableAddressValidation
          ? await FirestoreService.checkAddressExists(propertyAddress)
          : false;
      if (addressExists) {
        setState(() => _isLoading = false);
        if (!mounted) return;
        await showDialog<void>(
          context: context,
          builder: (ctx) {
            return AlertDialog(
              title: const Text('Address already in use'),
              content: const Text('This address is already in use and cannot be used to create a resident. Please contact the administrator or choose another address.'),
              actions: [
                TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('OK')),
              ],
            );
          },
        );
        return;
      }

      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(email: email, password: password);
      final uid = cred.user?.uid;

      // Create an accounts document (use uid as doc id if available)
      final accountsRef = FirebaseFirestore.instance.collection('accounts');
      final docRef = uid != null ? accountsRef.doc(uid) : accountsRef.doc();
      final payload = {
        'id': uid ?? docRef.id,
        'email': email,
        'name': name,
        'phoneNumber': phone,
        'propertySimpleAddress': propertyAddress,
        'role': 'user',
        'createdAt': FieldValue.serverTimestamp(),
        'avatar': null,
      };
      // Store only in `accounts` collection per updated requirement
      await docRef.set(payload);

      // Update local app provider user model
      final appProvider = Provider.of<AppProvider>(context, listen: false);
      final userModel = UserModel(
        id: uid ?? (payload['id'] as String),
        email: email,
        name: name,
        phoneNumber: phone,
        propertySimpleAddress: propertyAddress,
        role: 'user',
        createdAt: DateTime.now(),
        avatar: null,
      );
      appProvider.updateUser(userModel);

      setState(() => _isLoading = false);
      if (!mounted) return;
      // Navigate to home
      Navigator.pushReplacementNamed(context, AppRoutes.home);
    } on FirebaseAuthException catch (e) {
      setState(() {
        _isLoading = false;
        String message = 'Registration failed';
        if (e.code == 'email-already-in-use') {
          message = 'This email is already in use.';
        }
        _errorMessage = message;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Registration failed, please try again later.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Full name', prefixIcon: Icon(Icons.person)),
                      validator: (v) => (v == null || v.isEmpty) ? 'Please enter your name' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined)),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Please enter your email';
                        if (!v.contains('@')) return 'Please enter a valid email';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'Password', prefixIcon: Icon(Icons.lock_outline)),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Please enter a password';
                        if (v.length < 6) return 'Password must be at least 6 characters';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    // Phone input with fixed '+60' prefix and 9 separate square boxes using Pinput.
                    FormField<String>(
                      initialValue: _phoneController.text,
                      validator: (v) {
                        if (_phoneController.text.isEmpty) return 'Please enter your phone';
                        if (_phoneController.text.length != 9) return 'Phone must be 9 digits';
                        return null;
                      },
                      builder: (field) {
                        final pinTheme = PinTheme(
                          width: 48,
                          height: 48,
                          textStyle: const TextStyle(fontSize: 16, color: Colors.black),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade400),
                          ),
                        );

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Row(
                                children: [
                                  const Icon(Icons.phone, size: 18),
                                  const SizedBox(width: 8),
                                  Text('Phone', style: Theme.of(context).textTheme.bodySmall),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey.shade400),
                                    borderRadius: BorderRadius.circular(8),
                                    color: Colors.grey.shade100,
                                  ),
                                  child: const Text('+60', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Pinput(
                                    length: 9,
                                    controller: _phoneController,
                                    defaultPinTheme: pinTheme,
                                    focusedPinTheme: pinTheme.copyWith(
                                      decoration: pinTheme.decoration!.copyWith(border: Border.all(color: Theme.of(context).primaryColor)),
                                    ),
                                    submittedPinTheme: pinTheme,
                                    androidSmsAutofillMethod: AndroidSmsAutofillMethod.none,
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                    onChanged: (value) {
                                      field.didChange(value);
                                      // keep controller value synchronized (already handled by controller)
                                      setState(() {});
                                    },
                                  ),
                                ),
                              ],
                            ),
                            if (field.hasError)
                              Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(field.errorText ?? '', style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12)),
                              ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 12),

                    // Building selection (choose one of three buildings inline)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text('Building', style: Theme.of(context).textTheme.bodySmall),
                    ),
                    Wrap(
                      spacing: 8,
                      children: [
                        ChoiceChip(
                          label: const Text('Alpha Building'),
                          selected: _selectedBuilding == 'Alpha Building',
                          onSelected: (_) => setState(() => _selectedBuilding = 'Alpha Building'),
                        ),
                        ChoiceChip(
                          label: const Text('Beta Building'),
                          selected: _selectedBuilding == 'Beta Building',
                          onSelected: (_) => setState(() => _selectedBuilding = 'Beta Building'),
                        ),
                        ChoiceChip(
                          label: const Text('Central Building'),
                          selected: _selectedBuilding == 'Central Building',
                          onSelected: (_) => setState(() => _selectedBuilding = 'Central Building'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Floor + Unit selection (Floor: G..5, Unit: 01/02)
                    Row(
                      children: [
                        Expanded(
                          child: InputDecorator(
                            decoration: const InputDecoration(labelText: 'Floor', border: OutlineInputBorder()),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedFloor,
                                items: const [
                                  DropdownMenuItem(value: 'G', child: Text('G')),
                                  DropdownMenuItem(value: '1', child: Text('1')),
                                  DropdownMenuItem(value: '2', child: Text('2')),
                                  DropdownMenuItem(value: '3', child: Text('3')),
                                  DropdownMenuItem(value: '4', child: Text('4')),
                                  DropdownMenuItem(value: '5', child: Text('5')),
                                ],
                                onChanged: (v) {
                                  if (v == null) return;
                                  setState(() => _selectedFloor = v);
                                },
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: InputDecorator(
                            decoration: const InputDecoration(labelText: 'Unit', border: OutlineInputBorder()),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedUnit,
                                items: const [
                                  DropdownMenuItem(value: '01', child: Text('01')),
                                  DropdownMenuItem(value: '02', child: Text('02')),
                                ],
                                onChanged: (v) {
                                  if (v == null) return;
                                  setState(() => _selectedUnit = v);
                                },
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Avatar removed per user request
                    const SizedBox(height: 20),
                    if (_errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Icon(Icons.error_outline, color: Colors.red),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: TextStyle(color: Colors.red[800]),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close, color: Colors.red),
                                onPressed: () => setState(() => _errorMessage = null),
                              ),
                            ],
                          ),
                        ),
                      ),
                    SizedBox(
                      height: 48,
                      child: FilledButton(
                        onPressed: _isLoading ? null : _handleRegister,
                        child: _isLoading
                            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text('Create account'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: _isLoading ? null : () => Navigator.pushReplacementNamed(context, AppRoutes.login),
                      child: const Text('Already have an account? Login'),
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


