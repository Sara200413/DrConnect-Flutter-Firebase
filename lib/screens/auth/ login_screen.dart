import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:doctor_appointment_app/core/themes/app_theme.dart';
import 'package:doctor_appointment_app/widgets/shared/custom_button.dart';
import 'package:doctor_appointment_app/widgets/shared/custom_text_field.dart';
import '../../core/utils/ validators.dart';
import 'register_screen.dart';
import '../patient/main_layout.dart';
import '../doctor/doctor_dashboard_screen.dart';
import '../../services/auth_service.dart';
import 'admin_doctor_create_screen.dart';
class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _obscurePassword = true;

  // CODE DE CONTRÔLE ADMINISTRATEUR
  static const String ADMIN_ACCESS_EMAIL = "admin@gmail.com";
  static const String ADMIN_PASSWORD = "sara2004";
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
  // Affiche le pop-up de connexion Admin
  void _showAdminLoginDialog() {
    final adminPassController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Accès Administrateur"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Entrez le mot de passe admin pour créer des comptes Docteurs.", style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 15),
              CustomTextField(
                controller: adminPassController,
                label: "Mot de Passe admin",
                icon: Icons.vpn_key_outlined,
                isPassword: true,
                validator: (v) => Validators.validateRequired(v, "Mot de Passe"),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Annuler")),
            ElevatedButton(
              onPressed: () {
                if (adminPassController.text == ADMIN_PASSWORD) {
                  // Succès du mot de passe Admin
                  Navigator.pop(context); // Ferme la boîte
                  // Redirige vers la page de création de docteur
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminDoctorCreateScreen()));
                } else {
                  // Mot de passe incorrect
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Mot de passe Maître incorrect!"), backgroundColor: AppTheme.errorColor),
                  );
                }
              },
              child: const Text("Accéder"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    if (_emailController.text.trim().toLowerCase() == ADMIN_ACCESS_EMAIL) {

      _showAdminLoginDialog();
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Authentification Normale
      String authResult = await AuthService().loginUser(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (!mounted) return;

      if (authResult == "success") {
        String uid = FirebaseAuth.instance.currentUser!.uid;
        // Chercher le rôle de l'utilisateur dans Firestore
        DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection("users").doc(uid).get();
        if (userDoc.exists) {
          final role = userDoc.get('role');
          if (!mounted) return;
          // Redirection basée sur le rôle
          if (role == 'doctor') {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const DoctorDashboardScreen()),
            );
          } else {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const MainLayout()),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Erreur de profil. Contactez l'assistance.")),
          );
          await AuthService().signOut();
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(authResult), backgroundColor: AppTheme.errorColor),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur: ${e.toString()}"), backgroundColor: AppTheme.errorColor),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [

                  Container(
                    width: 150, height: 150,
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: AppTheme.primaryColor.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10))]),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Image.asset('assets/logo.png', fit: BoxFit.contain, errorBuilder: (context, error, stackTrace) {
                        return const Icon(Icons.medical_services_rounded, size: 60, color: AppTheme.primaryColor);
                      }),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text("Bienvenue", textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 8),
                  Text("Connectez-vous pour continuer", textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 40),

                  CustomTextField(
                    controller: _emailController,
                    label: "Email",
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    validator: (val) {
                      // On permet à l'email Admin de passer la validation d'Email si c'est pour l'Admin Dialog
                      if (val == ADMIN_ACCESS_EMAIL) return null;
                      return Validators.validateEmail(val);
                    },
                  ),
                  const SizedBox(height: 16),

                  CustomTextField(
                    controller: _passwordController,
                    label: "Mot de passe",
                    icon: Icons.lock_outline,
                    isPassword: _obscurePassword,
                    validator: Validators.validatePassword,
                  ),

                  const SizedBox(height: 32),

                  CustomButton(
                    text: "SE CONNECTER",
                    onPressed: _handleLogin,
                    isLoading: _isLoading,
                  ),

                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Pas encore de compte ?"),
                      TextButton(
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen()));
                        },
                        child: const Text("S'inscrire"),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}