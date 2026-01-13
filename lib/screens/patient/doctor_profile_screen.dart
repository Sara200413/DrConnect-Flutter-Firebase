import 'package:flutter/material.dart';
import '../../core/themes/app_theme.dart';
import 'doctor_details_screen.dart';

class DoctorProfileScreen extends StatelessWidget {
  final Map<String, dynamic> doctorData;
  final String doctorId;

  const DoctorProfileScreen({
    Key? key,
    required this.doctorData,
    required this.doctorId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Extraction des données
    final String fullName = doctorData['fullName'] ?? 'Docteur';
    final String specialty = doctorData['specialty'] ?? 'Généraliste';
    final String clinicName = doctorData['clinicName'] ?? 'Cabinet Médical';
    final String address = doctorData['address'] ?? 'Adresse non renseignée';
    final double price = (doctorData['price'] ?? 0).toDouble();
    final String bio = doctorData['bio'] ?? 'Non renseigné';

    // Responsivité : Détection de la taille
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final bool isSmallScreen = screenHeight < 700;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // 1. App Bar adaptative
          SliverAppBar(
            expandedHeight: isSmallScreen ? 200 : 250,
            pinned: true,
            elevation: 0,
            backgroundColor: const Color(0xFF2563EB),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
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
                  // Décorations cercles
                  Positioned(
                    top: -40,
                    right: -40,
                    child: CircleAvatar(radius: 100, backgroundColor: Colors.white.withOpacity(0.05)),
                  ),
                  // Contenu Header
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      CircleAvatar(
                        radius: isSmallScreen ? 35 : 45,
                        backgroundColor: Colors.white,
                        child: Icon(Icons.person_rounded, size: isSmallScreen ? 40 : 50, color: const Color(0xFF2563EB)),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        fullName,
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: isSmallScreen ? 20 : 24,
                            fontWeight: FontWeight.bold
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          specialty.toUpperCase(),
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // 2. Contenu scrollable
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(isSmallScreen ? 16.0 : 24.0),
              child: Column(
                children: [
                  // Carte 1 : Infos clés
                  _buildPremiumCard(
                    child: Column(
                      children: [
                        _buildInfoRow(
                          icon: Icons.payments_rounded,
                          label: 'Tarif Consultation',
                          value: '$price DH',
                          color: const Color(0xFF10B981),
                          isSmall: isSmallScreen,
                        ),
                        const Divider(height: 32, color: Color(0xFFF1F5F9)),
                        _buildInfoRow(
                          icon: Icons.location_on_rounded,
                          label: 'Lieu de consultation',
                          value: "$clinicName\n$address",
                          color: const Color(0xFF2563EB),
                          isSmall: isSmallScreen,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Carte 2 : Bio
                  _buildPremiumCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Expertise & Bio',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.school_rounded, color: Color(0xFF94A3B8), size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                bio,
                                style: const TextStyle(color: Color(0xFF64748B), fontSize: 14, height: 1.5),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 120), // Espace pour le bouton
                ],
              ),
            ),
          ),
        ],
      ),
      bottomSheet: _buildBottomAction(context, isSmallScreen),
    );
  }

  Widget _buildPremiumCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: const Color(0xFF2563EB).withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 10))
        ],
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: child,
    );
  }

  Widget _buildInfoRow({required IconData icon, required String label, required String value, required Color color, required bool isSmall}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
              Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B))),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomAction(BuildContext context, bool isSmall) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 10, 20, isSmall ? 20 : 30),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
      ),
      child: ElevatedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => DoctorDetailsScreen(
                doctorData: doctorData,
                doctorId: doctorId,
              ),
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2563EB),
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
        child: const Text("VOIR LES DISPONIBILITÉS", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
      ),
    );
  }
}