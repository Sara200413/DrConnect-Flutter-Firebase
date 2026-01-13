import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/themes/app_theme.dart';
import 'doctor_details_screen.dart';
import 'doctor_profile_screen.dart';

class PatientHomeScreen extends StatefulWidget {
  const PatientHomeScreen({Key? key}) : super(key: key);

  @override
  State<PatientHomeScreen> createState() => _PatientHomeScreenState();
}

class _PatientHomeScreenState extends State<PatientHomeScreen> {
  String _searchQuery = "";
  String _selectedCategory = "Tout";
  User? user = FirebaseAuth.instance.currentUser;
  String userName = "Patient";

  final List<String> categories = ["Tout", "Cardiologue", "Dentiste", "Pédiatre", "Généraliste", "Ophtalmologue"];

  @override
  void initState() {
    super.initState();
    _fetchUserName();
  }

  Future<void> _fetchUserName() async {
    if (user != null) {
      var doc = await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();
      if (doc.exists) {
        setState(() {
          userName = doc.data()?['fullName'] ?? "Patient";
        });
      }
    }
  }

  // --- DESIGN DE LA BANNIÈRE RESPONSIVE ---
  Widget _buildPromoBanner(BuildContext context, bool isSmall) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: isSmall ? 16 : 24, vertical: 12),
      padding: EdgeInsets.all(isSmall ? 20 : 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(isSmall ? 24 : 32),
        gradient: const LinearGradient(
          colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Votre santé d'abord",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: isSmall ? 18 : 22,
                      fontWeight: FontWeight.bold
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Trouvez un spécialiste et réservez votre consultation en quelques clics.",
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: isSmall ? 12 : 14,
                      height: 1.4
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: EdgeInsets.all(isSmall ? 8 : 12),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(16)),
            child: Icon(Icons.medical_services_outlined, size: isSmall ? 30 : 40, color: Colors.white),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Détection de la taille pour la responsivité
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isSmallScreen = screenWidth < 360;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isLargeScreen = constraints.maxWidth > 800;

            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // 1. Header & Welcome
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(isSmallScreen ? 16 : 24, 24, isSmallScreen ? 16 : 24, 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Bonjour,", style: TextStyle(color: const Color(0xFF64748B), fontSize: isSmallScreen ? 14 : 16)),
                            Text(
                                userName.split(' ').first,
                                style: TextStyle(
                                    color: const Color(0xFF1E293B),
                                    fontSize: isSmallScreen ? 22 : 26,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: -0.5
                                )
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
                          ),
                          child: const Icon(Icons.notifications_none_rounded, color: Color(0xFF2563EB)),
                        ),
                      ],
                    ),
                  ),
                ),

                // 2. Banner
                SliverToBoxAdapter(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: isLargeScreen ? 800 : double.infinity),
                      child: _buildPromoBanner(context, isSmallScreen),
                    ),
                  ),
                ),

                // 3. Search Bar
                SliverToBoxAdapter(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: isLargeScreen ? 800 : double.infinity),
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 16 : 24, vertical: 12),
                        child: Container(
                          decoration: BoxDecoration(
                            boxShadow: [
                              BoxShadow(color: const Color(0xFF2563EB).withOpacity(0.05), blurRadius: 25, offset: const Offset(0, 10))
                            ],
                          ),
                          child: TextField(
                            onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
                            decoration: InputDecoration(
                              hintText: "Médecin, spécialité...",
                              hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
                              prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF2563EB)),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(vertical: 18),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(isSmallScreen ? 20 : 24),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // 4. Categories
                SliverToBoxAdapter(
                  child: Container(
                    height: 60,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 16 : 24),
                      itemCount: categories.length,
                      itemBuilder: (context, index) {
                        final cat = categories[index];
                        final isSelected = _selectedCategory == cat;
                        return Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: ChoiceChip(
                            label: Text(cat),
                            selected: isSelected,
                            onSelected: (val) => setState(() => _selectedCategory = cat),
                            selectedColor: const Color(0xFF2563EB),
                            backgroundColor: Colors.white,
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : const Color(0xFF64748B),
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              fontSize: isSmallScreen ? 13 : 14,
                            ),
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            side: BorderSide(color: isSelected ? Colors.transparent : const Color(0xFFF1F5F9)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        );
                      },
                    ),
                  ),
                ),

                // 5. Title List
                SliverToBoxAdapter(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: isLargeScreen ? 800 : double.infinity),
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(isSmallScreen ? 16 : 24, 20, isSmallScreen ? 16 : 24, 16),
                        child: Text(
                            "Médecins disponibles",
                            style: TextStyle(fontSize: isSmallScreen ? 18 : 20, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))
                        ),
                      ),
                    ),
                  ),
                ),

                // 6. Doctor Stream List
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('doctors').snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: Color(0xFF2563EB))));
                    }
                    var docs = snapshot.data!.docs.where((doc) {
                      var data = doc.data() as Map<String, dynamic>;
                      String name = (data['fullName'] ?? '').toLowerCase();
                      String spec = (data['specialty'] ?? '').toLowerCase();
                      bool matchSearch = name.contains(_searchQuery) || spec.contains(_searchQuery);
                      bool matchCat = _selectedCategory == "Tout" || spec == _selectedCategory.toLowerCase();
                      return matchSearch && matchCat;
                    }).toList();

                    if (docs.isEmpty) {
                      return const SliverFillRemaining(
                          child: Center(child: Text("Aucun médecin trouvé.", style: TextStyle(color: Color(0xFF94A3B8))))
                      );
                    }

                    return SliverPadding(
                      padding: EdgeInsets.symmetric(
                        horizontal: isLargeScreen ? (constraints.maxWidth - 800) / 2 : (isSmallScreen ? 16 : 24),
                      ),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                              (context, index) {
                            var data = docs[index].data() as Map<String, dynamic>;
                            return _buildDoctorCard(context, data, docs[index].id, isSmallScreen);
                          },
                          childCount: docs.length,
                        ),
                      ),
                    );
                  },
                ),

                // 7. IMPORTANT: Espace pour ne pas être caché par la navigation
                const SliverToBoxAdapter(child: SizedBox(height: 120)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildDoctorCard(BuildContext context, Map<String, dynamic> data, String docId, bool isSmall) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isSmall ? 22 : 28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withOpacity(0.03),
            blurRadius: 20,
            offset: const Offset(0, 8),
          )
        ],
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => DoctorProfileScreen(
                      doctorData: data,
                      doctorId: docId,
                    )
                )
            );
          },
          borderRadius: BorderRadius.circular(isSmall ? 22 : 28),
          child: Padding(
            padding: EdgeInsets.all(isSmall ? 16 : 20),
            child: Row(
              children: [
                // Avatar stylisé (S'adapte à la taille)
                Container(
                  height: isSmall ? 65 : 75,
                  width: isSmall ? 65 : 75,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(isSmall ? 18 : 22),
                  ),
                  child: Icon(Icons.person_outline_rounded, color: const Color(0xFF2563EB), size: isSmall ? 32 : 38),
                ),
                const SizedBox(width: 16),
                // Infos Docteur
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          data['fullName'] ?? '',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: isSmall ? 16 : 18, color: const Color(0xFF1E293B)),
                          overflow: TextOverflow.ellipsis
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2563EB).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          (data['specialty'] ?? 'Généraliste').toUpperCase(),
                          style: const TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 0.5),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined, size: 14, color: Color(0xFF94A3B8)),
                          const SizedBox(width: 4),
                          Expanded(
                              child: Text(
                                  data['clinicName'] ?? 'Cabinet Médical',
                                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                  overflow: TextOverflow.ellipsis
                              )
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: Color(0xFFCBD5E1), size: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}