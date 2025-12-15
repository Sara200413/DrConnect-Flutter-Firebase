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

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text("Mes Rendez-vous", style: Theme.of(context).textTheme.headlineMedium),
        backgroundColor: Colors.white,
        elevation: 1,
        automaticallyImplyLeading: false,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('appointments')
            .where('patientId', isEqualTo: currentUserId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.calendar_today_outlined, size: 80, color: Colors.grey.shade400),
                  const SizedBox(height: 10),
                  Text("Vous n'avez aucun rendez-vous.", style: Theme.of(context).textTheme.bodyLarge),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var data = snapshot.data!.docs[index].data() as Map<String, dynamic>;

              Timestamp t = data['date'];
              DateTime date = t.toDate();

              String status = data['status'];
              Color color = AppTheme.primaryColor;
              String text = "En attente";
              IconData icon = Icons.access_time;

              if (status == 'approved') {
                color = AppTheme.successColor;
                text = "Confirmé";
                icon = Icons.check_circle;
              } else if (status == 'cancelled') {
                color = AppTheme.errorColor;
                text = "Refusé";
                icon = Icons.cancel;
              }

              return Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: color, size: 30),
                  ),
                  title: Text("Dr. ${data['doctorName']}", style: Theme.of(context).textTheme.titleLarge),
                  subtitle: Text(
                    "${MyDateUtils.formatDate(date)} à ${MyDateUtils.formatTime(date.hour)}",
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  trailing: Chip(
                    label: Text(text, style: const TextStyle(color: Colors.white, fontSize: 12)),
                    backgroundColor: color,
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
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