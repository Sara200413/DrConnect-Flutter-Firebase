import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/themes/app_theme.dart';
import '../../core/utils/date_utils.dart';

class PatientAppointmentsScreen extends StatelessWidget {
  const PatientAppointmentsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

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
              SliverAppBar(
                expandedHeight: isSmallScreen ? 100 : 120,
                pinned: true,
                elevation: 0,
                backgroundColor: const Color(0xFF2563EB),
                automaticallyImplyLeading: false,
                flexibleSpace: FlexibleSpaceBar(
                  centerTitle: false,
                  titlePadding: EdgeInsets.only(left: isSmallScreen ? 16 : 24, bottom: 16),
                  title: Text(
                    "Mes Rendez-vous",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: isSmallScreen ? 18 : 20,
                      letterSpacing: -0.5,
                    ),
                  ),
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                ),
              ),

              // 2. Liste des rendez-vous
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('appointments')
                    .where('patientId', isEqualTo: currentUserId)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SliverFillRemaining(
                      child: Center(child: CircularProgressIndicator(color: Color(0xFF2563EB))),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return _buildEmptyState(isSmallScreen);
                  }

                  var appointments = snapshot.data!.docs;

                  return SliverPadding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isLargeScreen ? (constraints.maxWidth - 700) / 2 : (isSmallScreen ? 12 : 20),
                      vertical: 20,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                            (context, index) {
                          var data = appointments[index].data() as Map<String, dynamic>;
                          return _buildAppointmentCard(context, data, isSmallScreen);
                        },
                        childCount: appointments.length,
                      ),
                    ),
                  );
                },
              ),

              // 3. Espace pour la navigation flottante (IMPORTANT)
              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAppointmentCard(BuildContext context, Map<String, dynamic> data, bool isSmall) {
    Timestamp t = data['date'];
    DateTime date = t.toDate();
    String status = data['status'];

    Color statusColor;
    String statusLabel;
    IconData statusIcon;

    if (status == 'approved') {
      statusColor = const Color(0xFF10B981);
      statusLabel = "CONFIRMÉ";
      statusIcon = Icons.check_circle_rounded;
    } else if (status == 'cancelled') {
      statusColor = const Color(0xFFEF4444);
      statusLabel = "REFUSÉ";
      statusIcon = Icons.cancel_rounded;
    } else {
      statusColor = const Color(0xFF2563EB);
      statusLabel = "EN ATTENTE";
      statusIcon = Icons.access_time_filled_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isSmall ? 20 : 28),
        boxShadow: [
          BoxShadow(color: const Color(0xFF2563EB).withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 5)),
        ],
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(isSmall ? 16 : 20),
            child: Row(
              children: [
                Container(
                  width: isSmall ? 50 : 60,
                  height: isSmall ? 50 : 60,
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(isSmall ? 14 : 18),
                  ),
                  child: Icon(Icons.person_rounded, color: statusColor, size: isSmall ? 24 : 30),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Dr. ${data['doctorName']}",
                        style: TextStyle(
                          fontSize: isSmall ? 16 : 18,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1E293B),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      // Utilisation d'un Wrap au lieu d'une Row pour éviter l'overflow
                      Wrap(
                        spacing: 12,
                        runSpacing: 4,
                        children: [
                          _iconInfo(Icons.calendar_month_rounded, MyDateUtils.formatDate(date), isSmall),
                          _iconInfo(Icons.access_time_rounded, MyDateUtils.formatTime(date.hour), isSmall),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Row(
            children: [
              _buildHalfCircle(true, statusColor),
              Expanded(child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Divider(color: statusColor.withOpacity(0.08), thickness: 1, height: 1),
              )),
              _buildHalfCircle(false, statusColor),
            ],
          ),

          Padding(
            padding: EdgeInsets.symmetric(horizontal: isSmall ? 16 : 20, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(statusIcon, color: statusColor, size: isSmall ? 16 : 18),
                    const SizedBox(width: 6),
                    Text(
                      statusLabel,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.w800,
                        fontSize: isSmall ? 10 : 11,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    "Détails",
                    style: TextStyle(color: const Color(0xFF64748B), fontWeight: FontWeight.bold, fontSize: isSmall ? 11 : 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _iconInfo(IconData icon, String text, bool isSmall) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: isSmall ? 12 : 14, color: Colors.grey[400]),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(color: Colors.grey[600], fontSize: isSmall ? 11 : 13)),
      ],
    );
  }

  Widget _buildHalfCircle(bool isLeft, Color color) {
    return Container(
      width: 10,
      height: 20,
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: isLeft
            ? const BorderRadius.only(topRight: Radius.circular(10), bottomRight: Radius.circular(10))
            : const BorderRadius.only(topLeft: Radius.circular(10), bottomLeft: Radius.circular(10)),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
    );
  }

  Widget _buildEmptyState(bool isSmall) {
    return SliverFillRemaining(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy_rounded, size: isSmall ? 60 : 80, color: const Color(0xFFCBD5E1)),
            const SizedBox(height: 16),
            const Text(
              "Aucun rendez-vous",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
            ),
            const Text("Vos consultations apparaîtront ici.", style: TextStyle(color: Color(0xFF64748B))),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }
}