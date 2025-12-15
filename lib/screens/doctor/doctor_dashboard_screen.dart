import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:doctor_appointment_app/core/themes/app_theme.dart';
import 'package:doctor_appointment_app/screens/auth/ login_screen.dart';
import 'package:doctor_appointment_app/screens/doctor/doctor_profile_edit_screen.dart';
import 'package:doctor_appointment_app/services/auth_service.dart';
import 'package:doctor_appointment_app/core/constants/clinic_hours.dart';

class DoctorDashboardScreen extends StatefulWidget {
  const DoctorDashboardScreen({Key? key}) : super(key: key);

  @override
  State<DoctorDashboardScreen> createState() => _DoctorDashboardScreenState();
}

class _DoctorDashboardScreenState extends State<DoctorDashboardScreen> {
  final String currentDoctorId = FirebaseAuth.instance.currentUser!.uid;

  // Fonction pour accepter/refuser le RDV
  Future<void> _updateStatus(String appointmentId, String newStatus) async {
    await FirebaseFirestore.instance
        .collection('appointments')
        .doc(appointmentId)
        .update({'status': newStatus});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text('Mon Tableau de Bord', style: AppTheme.lightTheme.textTheme.titleLarge),
        backgroundColor: Colors.white,
        elevation: 1,
        actions: [

          IconButton(
            icon: const Icon(Icons.edit, color: AppTheme.primaryColor),
            tooltip: "Modifier mon profil",
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const DoctorProfileEditScreen()));
            },
          ),

          IconButton(
            icon: const Icon(Icons.logout, color: AppTheme.errorColor),
            onPressed: () async {
              await AuthService().signOut();

              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
              );
            },
          )
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('appointments')
            .where('doctorId', isEqualTo: currentDoctorId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.event_busy, size: 80, color: Colors.grey.shade400),
                  const SizedBox(height: 10),
                  Text("Aucun rendez-vous en attente.", style: AppTheme.lightTheme.textTheme.bodyMedium),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var doc = snapshot.data!.docs[index];
              var data = doc.data() as Map<String, dynamic>;
              Timestamp t = data['date'];
              DateTime date = t.toDate();
              String dateStr = "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}"
                  "/${date.year} à ${date.hour.toString().padLeft(2, '0')}h00";
              String status = data['status'];
              Color statusColor = status == 'approved' ? AppTheme.successColor : (status == 'cancelled' ?
              AppTheme.errorColor : AppTheme.primaryColor);
              String statusText = status == 'approved' ? "Confirmé" :
              (status == 'cancelled' ? "Annulé" : "En attente");
              IconData statusIcon = status == 'approved' ? Icons.check_circle :
              (status == 'cancelled' ? Icons.cancel : Icons.access_time);
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                                  child: Text(data['patientName'].substring(0, 1).toUpperCase(), style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
                                ),
                                const SizedBox(width: 10),

                                Flexible(child: Text(data['patientName'] ?? 'Patient', style: Theme.of(context).textTheme.titleLarge, overflow: TextOverflow.ellipsis)),
                              ],
                            ),
                          ),

                          Chip(
                            avatar: Icon(statusIcon, size: 16, color: Colors.white),
                            label: Text(statusText, style: const TextStyle(color: Colors.white, fontSize: 12)),
                            backgroundColor: statusColor,
                          )
                        ],
                      ),

                      const Divider(height: 25),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 16, color: AppTheme.lightText),
                          const SizedBox(width: 8),
                          Text("RDV : $dateStr", style: AppTheme.lightTheme.textTheme.bodyLarge),
                        ],
                      ),

                      if (status == 'pending')
                        Padding(
                          padding: const EdgeInsets.only(top: 20.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              OutlinedButton(
                                onPressed: () => _updateStatus(doc.id, 'cancelled'),
                                style: OutlinedButton.styleFrom(foregroundColor: AppTheme.errorColor, side: const BorderSide(color: AppTheme.errorColor)),
                                child: const Text("Refuser"),
                              ),
                              const SizedBox(width: 10),
                              ElevatedButton(
                                onPressed: () => _updateStatus(doc.id, 'approved'),
                                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.successColor),
                                child: const Text("Accepter"),
                              ),
                            ],
                          ),
                        )
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}