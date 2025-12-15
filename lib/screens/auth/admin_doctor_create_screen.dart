import 'package:flutter/material.dart';
import '../../core/themes/app_theme.dart';
import '../../widgets/shared/custom_button.dart';
import '../../widgets/shared/custom_text_field.dart';
import '../../core/utils/ validators.dart';
import '../../services/auth_service.dart';

class AdminDoctorCreateScreen extends StatefulWidget {
  const AdminDoctorCreateScreen({Key? key}) : super(key: key);

  @override
  State<AdminDoctorCreateScreen> createState() => _AdminDoctorCreateScreenState();
}

class _AdminDoctorCreateScreenState extends State<AdminDoctorCreateScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _bioController = TextEditingController();
  final _specialtyController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;

  Future<void> _createDoctor() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    String specialty = _specialtyController.text.trim().toLowerCase();

    String result = await AuthService().signUpUser(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
      fullName: _nameController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
      bio: _bioController.text.trim(),
      role: 'doctor',
      specialty: specialty
    );

    if (!mounted) return;

    if (result == "success") {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Docteur créé : ${_emailController.text}"), backgroundColor: AppTheme.successColor),
      );
      _emailController.clear();
      _passwordController.clear();
      _nameController.clear();
      _phoneController.clear();
      _bioController.clear();
      _specialtyController.clear();
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
        title: const Text("ADMIN: Créer Compte Docteur", style: TextStyle(color: AppTheme.errorColor)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.errorColor),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.security, size: 50, color: AppTheme.errorColor),
                const SizedBox(height: 20),
                Text("Utilisez ceci UNIQUEMENT pour les comptes médecins de la clinique.", style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppTheme.errorColor)),
                const SizedBox(height: 30),


                CustomTextField(
                  controller: _nameController, label: "Nom complet du Docteur", icon: Icons.person_outline,
                  validator: (v) => Validators.validateRequired(v, "Nom"),
                ),
                const SizedBox(height: 16),

                CustomTextField(
                  controller: _specialtyController, label: "Spécialité (Ex: Cardiologue)", icon: Icons.work_outline,
                  validator: (v) => Validators.validateRequired(v, "Spécialité"),
                ),
                const SizedBox(height: 16),

                CustomTextField(
                  controller: _emailController, label: "Email Docteur", icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress, validator: Validators.validateEmail,
                ),
                const SizedBox(height: 16),

                CustomTextField(
                  controller: _passwordController, label: "Mot de passe (À NOTER)", icon: Icons.lock_outline, isPassword: true,
                  validator: Validators.validatePassword,
                ),
                const SizedBox(height: 16),

                CustomTextField(
                  controller: _bioController, label: "Diplômes / Qualifications (Ex: Université X, 2010)", icon: Icons.school_outlined,
                  validator: (v) => Validators.validateRequired(v, "Diplômes"),
                ),
                const SizedBox(height: 30),

                CustomButton(
                  text: "CRÉER COMPTE DOCTEUR",
                  onPressed: _createDoctor,
                  isLoading: _isLoading,
                  backgroundColor: AppTheme.errorColor,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}