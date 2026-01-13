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
      _showSnackBar("Docteur créé avec succès", AppTheme.successColor);
      _clearForm();
    } else {
      _showSnackBar(result, AppTheme.errorColor);
    }
    setState(() => _isLoading = false);
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _clearForm() {
    _emailController.clear();
    _passwordController.clear();
    _nameController.clear();
    _phoneController.clear();
    _bioController.clear();
    _specialtyController.clear();
  }

  @override
  Widget build(BuildContext context) {
    // Récupération de la taille de l'écran pour la responsivité
    final size = MediaQuery.of(context).size;
    final bool isSmallScreen = size.height < 700;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          // Fond dégradé subtil
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFFEF2F2), Color(0xFFF8FAFC)],
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                _buildHeader(context),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.symmetric(
                      horizontal: size.width > 600 ? size.width * 0.2 : 20,
                      vertical: 16,
                    ),
                    child: Column(
                      children: [
                        _buildSecurityCard(isSmallScreen),
                        SizedBox(height: isSmallScreen ? 20 : 32),
                        _buildFormContainer(isSmallScreen),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.red.withOpacity(0.1))),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            constraints: const BoxConstraints(),
            padding: EdgeInsets.zero,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "ADMINISTRATION",
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.red, letterSpacing: 1),
                ),
                const Text(
                  "Nouveau Praticien",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                ),
              ],
            ),
          ),
          const Icon(Icons.admin_panel_settings_rounded, color: Colors.red, size: 28),
        ],
      ),
    );
  }

  Widget _buildSecurityCard(bool isSmall) {
    return Container(
      padding: EdgeInsets.all(isSmall ? 16 : 20),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.red.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          const Icon(Icons.shield_rounded, color: Colors.red, size: 32),
          const SizedBox(width: 16),
          const Expanded(
            child: Text(
              "Zone réservée à la création de comptes pour le personnel médical de la clinique.",
              style: TextStyle(fontSize: 13, color: Color(0xFF475569), height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormContainer(bool isSmall) {
    return Container(
      padding: EdgeInsets.all(isSmall ? 20 : 28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader("Informations Professionnelles"),
            const SizedBox(height: 20),
            CustomTextField(
              controller: _nameController,
              label: "Nom complet",
              icon: Icons.person_outline_rounded,
              validator: (v) => Validators.validateRequired(v, "Nom"),
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _specialtyController,
              label: "Spécialité",
              icon: Icons.medical_services_outlined,
              validator: (v) => Validators.validateRequired(v, "Spécialité"),
            ),
            const SizedBox(height: 24),
            _buildSectionHeader("Contact & Accès"),
            const SizedBox(height: 20),
            CustomTextField(
              controller: _emailController,
              label: "Email professionnel",
              icon: Icons.alternate_email_rounded,
              keyboardType: TextInputType.emailAddress,
              validator: Validators.validateEmail,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _phoneController,
              label: "Téléphone",
              icon: Icons.phone_android_rounded,
              keyboardType: TextInputType.phone,
              validator: (v) => Validators.validateRequired(v, "Téléphone"),
            ),
            const SizedBox(height: 16),
            _buildPasswordField(),
            const SizedBox(height: 24),
            _buildSectionHeader("Qualifications"),
            const SizedBox(height: 20),
            CustomTextField(
              controller: _bioController,
              label: "Diplômes et parcours",
              icon: Icons.history_edu_rounded,
              validator: (v) => Validators.validateRequired(v, "Diplômes"),
            ),
            const SizedBox(height: 32),
            CustomButton(
              text: "ENREGISTRER LE DOCTEUR",
              onPressed: _createDoctor,
              isLoading: _isLoading,
              backgroundColor: Colors.red[700],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Container(width: 4, height: 16, decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF64748B), letterSpacing: 0.5)),
      ],
    );
  }

  Widget _buildPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomTextField(
          controller: _passwordController,
          label: "Mot de passe",
          icon: Icons.lock_person_outlined,
          isPassword: true,
          validator: Validators.validatePassword,
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(color: Colors.amber[50], borderRadius: BorderRadius.circular(10)),
          child: Row(
            children: [
              Icon(Icons.info_outline_rounded, color: Colors.amber[800], size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "À communiquer au docteur pour sa première connexion.",
                  style: TextStyle(fontSize: 11, color: Colors.amber[900], fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}