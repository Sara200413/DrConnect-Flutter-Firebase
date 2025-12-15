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
    final String fullName = doctorData['fullName'] ?? 'Docteur';
    final String specialty = doctorData['specialty'] ?? 'Généraliste';
    final String clinicName = doctorData['clinicName'] ?? '';
    final String address = doctorData['address'] ?? '';
    final double price = (doctorData['price'] ?? 0).toDouble();
    final String bio = doctorData['bio'] ?? 'Non renseigné';

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: CustomScrollView(
        slivers: [

          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(fullName, style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white)),
              centerTitle: true,
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.primaryColor, Color(0xFF4A90E2)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      Container(
                        width: 90, height: 90,
                        decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 15)]),
                        child: const Icon(Icons.person, size: 50, color: AppTheme.primaryColor),
                      ),
                      const SizedBox(height: 10),
                      Text(specialty, style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.white70)),
                    ],
                  ),
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.all(20),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20)],
                  ),
                  child: Column(
                    children: [
                      _buildInfoRow(context, icon: Icons.payments_outlined, label: 'Prix de consultation', value: '$price DH', valueColor: AppTheme.successColor, iconColor: AppTheme.successColor),
                      const Divider(height: 30),
                      _buildInfoRow(context, icon: Icons.local_hospital_outlined, label: 'Cabinet / Clinique', value: clinicName, iconColor: AppTheme.primaryColor),
                      const SizedBox(height: 16),
                      _buildInfoRow(context, icon: Icons.location_on_outlined, label: 'Adresse Complète', value: address, iconColor: AppTheme.errorColor),
                    ],
                  ),
                ),

                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20)],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Qualifications & Formation', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 16),
                      _buildDetailTile(context,
                        icon: Icons.school_outlined,
                        title: 'Parcours',
                        subtitle: bio,
                      ),
                      const SizedBox(height: 12),
                      _buildDetailTile(context,
                        icon: Icons.access_time_outlined,
                        title: 'Expérience',
                        subtitle: 'Plus de 10 ans en pratique clinique',
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => DoctorDetailsScreen(
                          doctorData: doctorData,
                          doctorId: doctorId,
                        )));
                      },
                      child: const Text('VOIR DISPONIBILITÉS & RÉSERVER'),
                    ),
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildInfoRow(BuildContext context, {required IconData icon, required String label, required String value, Color? valueColor, Color? iconColor}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: (iconColor ?? AppTheme.primaryColor).withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: iconColor ?? AppTheme.primaryColor, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 4),
              Text(value, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600, color: valueColor ?? AppTheme.darkText)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailTile(BuildContext context, {required IconData icon, required String title, required String subtitle}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 24, color: AppTheme.primaryColor.withOpacity(0.8)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}