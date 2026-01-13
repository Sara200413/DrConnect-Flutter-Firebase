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
      return const Scaffold(body: Center(child: Text("Utilisateur non connecté.")));
    }

    // Responsivité : Détection de la taille
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isSmallScreen = screenWidth < 360;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isLargeScreen = constraints.maxWidth > 800;

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // 1. Header adaptatif
              _buildSliverHeader(context, isSmallScreen),

              // 2. Contenu des données (Firestore)
              SliverToBoxAdapter(
                child: FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.only(top: 80.0),
                        child: Center(child: CircularProgressIndicator(color: Color(0xFF2563EB))),
                      );
                    }
                    if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
                      return const Center(child: Text("Erreur de chargement."));
                    }

                    final data = snapshot.data!.data() as Map<String, dynamic>;
                    final fullName = data['fullName'] ?? 'Patient';
                    final phoneNumber = data['phoneNumber'] ?? 'Non renseigné';
                    final email = user.email ?? 'Email inconnu';

                    return Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: isLargeScreen ? 700 : double.infinity),
                        child: Padding(
                          padding: EdgeInsets.all(isSmallScreen ? 16.0 : 24.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Nom et Email (Ajusté pour l'avatar flottant)
                              const SizedBox(height: 30),
                              Center(
                                child: Column(
                                  children: [
                                    Text(
                                      fullName,
                                      style: TextStyle(
                                          fontSize: isSmallScreen ? 20 : 24,
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFF1E293B)
                                      ),
                                      textAlign: TextAlign.center,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      email,
                                      style: TextStyle(color: const Color(0xFF64748B), fontSize: isSmallScreen ? 12 : 14),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 32),

                              // Section Informations
                              _buildSectionTitle("Détails du compte", isSmallScreen),
                              const SizedBox(height: 12),
                              _buildInfoCard(
                                children: [
                                  _buildInfoTile(Icons.alternate_email_rounded, "Adresse Email", email, const Color(0xFF2563EB), isSmallScreen),
                                  _buildInfoTile(Icons.phone_iphone_rounded, "Numéro de Téléphone", phoneNumber, const Color(0xFF10B981), isSmallScreen),
                                ],
                              ),

                              const SizedBox(height: 24),

                              // Section Sécurité
                              _buildSectionTitle("Sécurité", isSmallScreen),
                              const SizedBox(height: 12),
                              _buildInfoCard(
                                children: [
                                  _buildInfoTile(Icons.verified_rounded, "Statut du compte", "Vérifié", const Color(0xFF8B5CF6), isSmallScreen),
                                ],
                              ),

                              const SizedBox(height: 40),

                              // Bouton de déconnexion
                              _buildLogoutButton(context),

                              // 3. IMPORTANT: Espace pour ne pas être caché par la navigation flottante
                              const SizedBox(height: 120),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // --- WIDGETS DE DESIGN ---

  Widget _buildSliverHeader(BuildContext context, bool isSmall) {
    return SliverAppBar(
      expandedHeight: isSmall ? 140 : 160,
      pinned: true,
      elevation: 0,
      backgroundColor: const Color(0xFF2563EB),
      automaticallyImplyLeading: false,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          alignment: Alignment.bottomCenter,
          clipBehavior: Clip.none, // Permet à l'avatar de déborder
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                ),
              ),
            ),
            // Avatar Circulaire (Ajusté pour la responsivité)
            Positioned(
              bottom: -40,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(color: Color(0xFFF8FAFC), shape: BoxShape.circle),
                child: Container(
                  width: isSmall ? 80 : 90,
                  height: isSmall ? 80 : 90,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: const Color(0xFF2563EB).withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10))
                    ],
                  ),
                  child: Icon(Icons.person_rounded, size: isSmall ? 40 : 45, color: const Color(0xFF2563EB)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isSmall) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
            fontSize: isSmall ? 11 : 12,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF94A3B8),
            letterSpacing: 1.2
        ),
      ),
    );
  }

  Widget _buildInfoCard({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: const Color(0xFF2563EB).withOpacity(0.02), blurRadius: 15, offset: const Offset(0, 5)),
        ],
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value, Color color, bool isSmall) {
    return Padding(
      padding: EdgeInsets.all(isSmall ? 16.0 : 20.0),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(isSmall ? 10 : 12),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: isSmall ? 18 : 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: const Color(0xFF64748B), fontSize: isSmall ? 11 : 12)),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(fontSize: isSmall ? 14 : 15, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B)),
                  overflow: TextOverflow.ellipsis,
                ),
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
      backgroundColor: const Color(0xFFEF4444),
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