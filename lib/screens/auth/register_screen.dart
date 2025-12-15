import 'package:flutter/material.dart';
import '../../core/themes/app_theme.dart';
import '../../widgets/shared/custom_button.dart';
import '../../core/utils/ validators.dart';
import '../../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  // Rôle forcé à 'patient' pour la sécurité
  final String _role = "patient";
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Les mots de passe ne correspondent pas!"), backgroundColor: AppTheme.errorColor),
      );
      return;
    }

    setState(() => _isLoading = true);

    // L'appel utilise role: 'patient'
    String result = await AuthService().signUpUser(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
      fullName: _nameController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
      role: _role,
    );

    if (!mounted) return;

    if (result == "success") {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Compte Patient créé avec succès !")),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result), backgroundColor: AppTheme.errorColor),
      );
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text("Créer un compte Patient"),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.primaryColor),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(labelText: "Nom complet", prefixIcon: Icon(Icons.person_outline)),
                          validator: (v) => Validators.validateRequired(v, "Nom"),
                        ),
                        const SizedBox(height: 16),

                        TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(labelText: "Téléphone", prefixIcon: Icon(Icons.phone_outlined)),
                          validator: (v) => Validators.validateRequired(v, "Téléphone"),
                        ),
                        const SizedBox(height: 16),

                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(labelText: "Email", prefixIcon: Icon(Icons.email_outlined)),
                          validator: Validators.validateEmail,
                        ),
                        const SizedBox(height: 16),

                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            labelText: "Mot de passe",
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined), onPressed: () {setState(() => _obscurePassword = !_obscurePassword);},),
                          ),
                          validator: Validators.validatePassword,
                        ),
                        const SizedBox(height: 16),

                        TextFormField(
                          controller: _confirmPasswordController,
                          obscureText: _obscureConfirmPassword,
                          decoration: InputDecoration(
                            labelText: "Confirmer mot de passe",
                            prefixIcon: const Icon(Icons.lock_open_outlined),
                            suffixIcon: IconButton(icon: Icon(_obscureConfirmPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined), onPressed: () {setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);},),
                          ),
                          validator: (v) {
                            if (v != _passwordController.text) return "Les mots de passe ne correspondent pas";
                            return Validators.validatePassword(v);
                          },
                        ),
                        const SizedBox(height: 32),

                        CustomButton(text: "CRÉER COMPTE PATIENT", onPressed: _register, isLoading: _isLoading),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text("Déjà un compte ? ", style: Theme.of(context).textTheme.bodyMedium),
                  TextButton(onPressed: () => Navigator.pop(context),
                      child: Text("Se connecter", style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppTheme.primaryColor,
                          fontWeight: FontWeight.w600))),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }
}