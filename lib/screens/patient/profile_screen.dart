import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/themes/app_theme.dart';
import '../../services/auth_service.dart';
import '../auth/ login_screen.dart';
import '../../widgets/shared/custom_button.dart';
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text("Erreur: Utilisateur non connecté."));
    }
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text("Mon Profil", style: Theme.of(context).textTheme.headlineMedium),
        backgroundColor: Colors.white,
        elevation: 1,
        automaticallyImplyLeading: false,
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("Erreur lors du chargement du profil."));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final fullName = data['fullName'] ?? 'Patient';
          final phoneNumber = data['phoneNumber'] ?? 'Non renseigné';
          final email = user.email ?? 'Email inconnu';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                _buildProfileHeader(context, fullName, email),
                const SizedBox(height: 30),

                _buildInfoCard(
                  context,
                  title: "Informations Personnelles",
                  children: [
                    _buildInfoTile(context, Icons.email_outlined, "Email", email),
                    _buildInfoTile(context, Icons.phone_outlined, "Téléphone", phoneNumber),
                  ],
                ),
                const SizedBox(height: 20),

                _buildLogoutButton(context),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, String fullName, String email) {
    return Column(
      children: [
        const CircleAvatar(
          radius: 50,
          backgroundColor: AppTheme.primaryColor,
          child: Icon(Icons.person, size: 50, color: Colors.white),
        ),
        const SizedBox(height: 10),
        Text(fullName, style: Theme.of(context).textTheme.headlineMedium),
        Text(email, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }

  Widget _buildInfoCard(BuildContext context, {required String title, required List<Widget> children}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const Divider(height: 20),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile(BuildContext context, IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppTheme.primaryColor, size: 24),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.bodyMedium),
                Text(value, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return CustomButton(
      text: "SE DÉCONNECTER",
      backgroundColor: AppTheme.errorColor,
      onPressed: () async {
        await AuthService().signOut();

        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (ctx) => const LoginScreen()),
              (route) => false,
        );
      },
    );
  }
}