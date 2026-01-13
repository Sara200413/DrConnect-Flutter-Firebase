import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:doctor_appointment_app/core/themes/app_theme.dart';
import 'package:doctor_appointment_app/screens/auth/ login_screen.dart';
import 'package:doctor_appointment_app/screens/doctor/doctor_profile_edit_screen.dart';
import 'package:doctor_appointment_app/services/auth_service.dart';

class DoctorDashboardScreen extends StatefulWidget {
  const DoctorDashboardScreen({Key? key}) : super(key: key);

  @override
  State<DoctorDashboardScreen> createState() => _DoctorDashboardScreenState();
}

class _DoctorDashboardScreenState extends State<DoctorDashboardScreen> {
  final String currentDoctorId = FirebaseAuth.instance.currentUser!.uid;
  String _selectedFilter = 'all';

  // --- LOGIQUE MISE À JOUR STATUT ---
  Future<void> _updateStatus(String appointmentId, String newStatus) async {
    try {
      await FirebaseFirestore.instance
          .collection('appointments')
          .doc(appointmentId)
          .update({'status': newStatus});

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(newStatus == 'approved' ? '✅ Rendez-vous confirmé' : '❌ Rendez-vous refusé'),
          backgroundColor: newStatus == 'approved' ? AppTheme.successColor : AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    } catch (e) {
      debugPrint("Erreur update status: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    // Utilisation de MediaQuery pour adapter les tailles
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isSmallScreen = screenWidth < 360;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildSliverAppBar(context),

          // 1. Cartes de Stats
          SliverToBoxAdapter(
            child: _buildStatsSection(isSmallScreen),
          ),

          // 2. Filtres (Chips)
          SliverToBoxAdapter(
            child: _buildFilterSection(),
          ),

          // 3. Liste des RDV
          _buildAppointmentsList(),

          // Espace en bas pour éviter que le dernier élément soit collé
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 140,
      pinned: true,
      elevation: 0,
      backgroundColor: AppTheme.primaryColor,
      automaticallyImplyLeading: false,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
        title: const Text(
          'Mon Planning',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
            ),
          ),
          child: const Center(
            child: Icon(Icons.calendar_month_rounded, size: 80, color: Colors.white10),
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.edit_note_rounded, color: Colors.white, size: 28),
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DoctorProfileEditScreen())),
        ),
        IconButton(
          icon: const Icon(Icons.logout_rounded, color: Colors.white),
          onPressed: () async {
            await AuthService().signOut();
            Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (r) => false);
          },
        ),
      ],
    );
  }

  Widget _buildStatsSection(bool isSmall) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('appointments')
          .where('doctorId', isEqualTo: currentDoctorId)
          .snapshots(),
      builder: (context, snapshot) {
        int total = snapshot.hasData ? snapshot.data!.docs.length : 0;
        int pending = 0;
        if (snapshot.hasData) {
          pending = snapshot.data!.docs.where((d) => d['status'] == 'pending').length;
        }

        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
          child: Row(
            children: [
              Expanded(
                child: _buildStatItem("Total", total.toString(), Icons.analytics_rounded, const Color(0xFF2563EB)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatItem("Nouveaux", pending.toString(), Icons.notification_important_rounded, Colors.orange),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: color.withOpacity(0.06), blurRadius: 15, offset: const Offset(0, 8))
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
              Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      height: 60,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          _buildFilterChip("Tous", 'all'),
          _buildFilterChip("En attente", 'pending'),
          _buildFilterChip("Confirmés", 'approved'),
          _buildFilterChip("Annulés", 'cancelled'),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final bool isSelected = _selectedFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (val) => setState(() => _selectedFilter = value),
        selectedColor: AppTheme.primaryColor,
        backgroundColor: Colors.white,
        labelStyle: TextStyle(color: isSelected ? Colors.white : const Color(0xFF64748B), fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        side: BorderSide(color: isSelected ? Colors.transparent : const Color(0xFFE2E8F0)),
      ),
    );
  }

  Widget _buildAppointmentsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('appointments')
          .where('doctorId', isEqualTo: currentDoctorId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SliverFillRemaining(child: Center(child: CircularProgressIndicator()));
        }

        var docs = snapshot.data!.docs;
        if (_selectedFilter != 'all') {
          docs = docs.where((d) => d['status'] == _selectedFilter).toList();
        }

        if (docs.isEmpty) {
          return const SliverFillRemaining(
            child: Center(child: Text("Aucun rendez-vous trouvé.", style: TextStyle(color: Color(0xFF94A3B8)))),
          );
        }

        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
                  (context, index) => _buildAppointmentCard(docs[index]),
              childCount: docs.length,
            ),
          ),
        );
      },
    );
  }

  Widget _buildAppointmentCard(DocumentSnapshot doc) {
    var data = doc.data() as Map<String, dynamic>;
    DateTime date = (data['date'] as Timestamp).toDate();
    String status = data['status'];

    Color statusColor = status == 'approved' ? AppTheme.successColor : (status == 'cancelled' ? AppTheme.errorColor : Colors.orange);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: CircleAvatar(
              radius: 25,
              backgroundColor: statusColor.withOpacity(0.1),
              child: Text(data['patientName'][0].toUpperCase(), style: TextStyle(color: statusColor, fontWeight: FontWeight.bold)),
            ),
            title: Text(data['patientName'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Row(
                children: [
                  const Icon(Icons.access_time_filled_rounded, size: 14, color: Color(0xFF64748B)),
                  const SizedBox(width: 4),
                  Text("${date.day}/${date.month} à ${date.hour}h00", style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                ],
              ),
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
              child: Text(status.toUpperCase(), style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
          ),
          if (status == 'pending')
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _updateStatus(doc.id, 'cancelled'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.errorColor,
                        side: const BorderSide(color: AppTheme.errorColor),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text("Refuser"),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _updateStatus(doc.id, 'approved'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.successColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text("Accepter"),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}