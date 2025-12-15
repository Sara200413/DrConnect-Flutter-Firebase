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
  Widget _buildPromoBanner(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [AppTheme.primaryColor, AppTheme.primaryColor.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Trouvez votre spécialiste !",
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 5),
                Text(
                  "Réservez 24/7. C'est rapide et sécurisé.",
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white70),
                ),
              ],
            ),
          ),
          const Icon(Icons.calendar_month_rounded, size: 50, color: Colors.white70),
        ],
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Bonjour,", style: Theme.of(context).textTheme.bodyMedium),
                        Text(userName.split(' ').first, style: Theme.of(context).textTheme.headlineMedium),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: _buildPromoBanner(context),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Container(
                  decoration: BoxDecoration(
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 15, offset: const Offset(0, 5))],
                  ),
                  child: TextField(
                    onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
                    decoration: const InputDecoration(
                      hintText: "Rechercher un médecin ou spécialité...",
                      prefixIcon: Icon(Icons.search, color: AppTheme.primaryColor),
                      fillColor: Colors.white,
                    ),
                  ),
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: SizedBox(
                height: 45,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
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
                        selectedColor: AppTheme.primaryColor,
                        backgroundColor: Colors.white,
                        labelStyle: TextStyle(
                            color: isSelected ? Colors.white : AppTheme.darkText,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal
                        ),
                        side: BorderSide(color: isSelected ? Colors.transparent : Colors.grey.shade200),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      ),
                    );
                  },
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                  child: Text("Médecins disponibles", style: Theme.of(context).textTheme.titleLarge)
              ),
            ),

            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('doctors').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const SliverFillRemaining(child: Center(child: CircularProgressIndicator()));
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
                  return const SliverFillRemaining(child: Center(child: Text("Aucun médecin trouvé.")));
                }
                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                        (context, index) {
                      var data = docs[index].data() as Map<String, dynamic>;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        child: _buildDoctorCard(context, data, docs[index].id),
                      );
                    },
                    childCount: docs.length,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDoctorCard(BuildContext context, Map<String, dynamic> data, String docId) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
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
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  height: 60, width: 60,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.person, color: AppTheme.primaryColor, size: 30),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(data['fullName'] ?? '', style: Theme.of(context).textTheme.titleLarge, overflow: TextOverflow.ellipsis),
                      Text(data['specialty'] ?? 'Généraliste', style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 14, color: AppTheme.lightText),
                          const SizedBox(width: 4),
                          Expanded(child: Text(data['clinicName'] ?? '', style: Theme.of(context).textTheme.bodyMedium, overflow: TextOverflow.ellipsis)),
                        ],
                      )
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, size: 16, color: AppTheme.lightText)
              ],
            ),
          ),
        ),
      ),
    );
  }
}