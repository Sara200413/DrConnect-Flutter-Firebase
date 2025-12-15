import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/themes/app_theme.dart';
import '../../core/constants/clinic_hours.dart';
import '../../core/utils/date_utils.dart';
import '../../widgets/shared/custom_button.dart';
class DoctorDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> doctorData;
  final String doctorId;
  const DoctorDetailsScreen({Key? key, required this.doctorData, required this.doctorId}) : super(key: key);
  @override
  State<DoctorDetailsScreen> createState() => _DoctorDetailsScreenState();
}
class _DoctorDetailsScreenState extends State<DoctorDetailsScreen> {
  DateTime _selectedDate = DateTime.now();
  int? _selectedHour;
  bool _isLoading = false;
  List<int> _takenHours = [];

  @override
  void initState() {
    super.initState();
    // Logique: Commencer à demain, sauter Dimanche
    DateTime tomorrow = DateTime.now().add(const Duration(days: 1));
    if (tomorrow.weekday == ClinicHours.closedDay) {
      tomorrow = tomorrow.add(const Duration(days: 1));
    }
    _selectedDate = tomorrow;
    _checkAvailability();
  }
  // Vérifie les créneaux déjà pris (pending ou approved)
  Future<void> _checkAvailability() async {
    setState(() {
      _takenHours = [];
      _selectedHour = null;
      _isLoading = true;
    });
    DateTime start = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, 0, 0);
    DateTime end = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, 23, 59);

    try {
      var snapshot = await FirebaseFirestore.instance
          .collection('appointments')
          .where('doctorId', isEqualTo: widget.doctorId)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(end))
          .get();

      List<int> busy = [];
      for (var doc in snapshot.docs) {
        // Bloque le créneau si le statut n'est PAS 'cancelled' (donc pending ou approved)
        if (doc['status'] != 'cancelled') {
          DateTime date = (doc['date'] as Timestamp).toDate();
          busy.add(date.hour);
        }
      }
      setState(() {
        _takenHours = busy;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }
  // Sélecteur de date
  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().add(const Duration(days: 1)),
      lastDate: DateTime(2030),
      selectableDayPredicate: (day) => day.weekday != ClinicHours.closedDay, // Bloque Dimanche
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(primary: AppTheme.primaryColor),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _selectedDate = picked);
      _checkAvailability();
    }
  }
  // Affiche la boîte de confirmation modale (Bottom Sheet)
  void _showConfirmationSheet() {
    if (_selectedHour == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(backgroundColor: AppTheme.errorColor, content: Text("Veuillez choisir une heure")));
      return;
    }
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Confirmer le rendez-vous", style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 20),
            _summaryRow(Icons.person, "Médecin", "Dr. ${widget.doctorData['fullName']}"),
            _summaryRow(Icons.calendar_today, "Date", MyDateUtils.formatDate(_selectedDate)),
            _summaryRow(Icons.access_time, "Heure", MyDateUtils.formatTime(_selectedHour!)),
            _summaryRow(Icons.attach_money, "Prix", "${widget.doctorData['price']} DH"),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: CustomButton(
                onPressed: () {
                  Navigator.pop(context);
                  _processBooking();
                },
                text: "Valider la réservation",
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.lightText),
          const SizedBox(width: 10),
          Text("$label : ", style: Theme.of(context).textTheme.bodyMedium),
          Text(value, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Future<void> _processBooking() async {
    setState(() => _isLoading = true);
    try {
      DateTime finalDate = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, _selectedHour!, 0);
      //  Double Check Anti-Doublon
      var check = await FirebaseFirestore.instance
          .collection('appointments')
          .where('doctorId', isEqualTo: widget.doctorId)
          .where('date', isEqualTo: Timestamp.fromDate(finalDate))
          .get();

      if (check.docs.any((d) => d['status'] != 'cancelled')) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(backgroundColor: AppTheme.errorColor, content: Text("Oups ! Ce créneau est déjà pris.")));
        _checkAvailability();
        return;
      }
      //  Booking
      String uid = FirebaseAuth.instance.currentUser!.uid;
      var userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();

      await FirebaseFirestore.instance.collection('appointments').add({
        'doctorId': widget.doctorId,
        'doctorName': widget.doctorData['fullName'],
        'patientId': uid,
        'patientName': userDoc.data()?['fullName'] ?? 'Patient',
        'date': Timestamp.fromDate(finalDate),
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Succès
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          icon: const Icon(Icons.check_circle, color: AppTheme.successColor, size: 50),
          title: const Text("Réservation envoyée"),
          content: const Text("Vous pouvez suivre le statut dans 'Mes RDV'."),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context);
              },
              child: const Text("Super"),
            )
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erreur: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Prendre RDV"), backgroundColor: Colors.white, foregroundColor: AppTheme.darkText, elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(radius: 30, backgroundColor: AppTheme.primaryColor.withOpacity(0.1), child: const Icon(Icons.person, color: AppTheme.primaryColor, size: 30)),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text("Dr. ${widget.doctorData['fullName']}", style: Theme.of(context).textTheme.titleLarge, overflow: TextOverflow.ellipsis), // FIX DÉBORDEMENT
                            Text(widget.doctorData['specialty'] ?? "Spécialité inconnue", style: Theme.of(context).textTheme.bodyMedium, overflow: TextOverflow.ellipsis), // FIX DÉBORDEMENT
                            const SizedBox(height: 5),
                            Row(
                              children: [
                                const Icon(Icons.attach_money, color: AppTheme.successColor, size: 18),
                                const SizedBox(width: 4),
                                Text("${widget.doctorData['price']} DH", style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold, color: AppTheme.successColor)),
                              ],
                            ),
                          ]),
                        ),
                      ],
                    ),
                    const Divider(height: 30),
                    Text("Qualifications & Parcours", style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.school_outlined, color: AppTheme.primaryColor, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            widget.doctorData['bio'] ?? 'Diplômes non renseignés',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),

                    const Divider(height: 30),
                    Text("Lieu de Consultation", style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.location_on, color: AppTheme.primaryColor, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(widget.doctorData['clinicName'] ?? "Clinique Inconnue", style: Theme.of(context).textTheme.bodyLarge),
                              Text(widget.doctorData['address'] ?? "Adresse non renseignée", style: Theme.of(context).textTheme.bodyMedium),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 40),

            Text(" Choisissez le jour", style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 10),
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: AppTheme.primaryColor, width: 1.5),
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.white,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(MyDateUtils.formatDate(_selectedDate), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
                    const Icon(Icons.calendar_today, color: AppTheme.primaryColor),
                  ],
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(top: 5.0, left: 5.0),
              child: Text("Dimanche est fermé", style: TextStyle(fontSize: 12, color: AppTheme.errorColor)),
            ),

            const SizedBox(height: 30),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Horaires disponibles", style: Theme.of(context).textTheme.titleLarge),
                if (_isLoading) const SizedBox(width: 15, height: 15, child: CircularProgressIndicator(strokeWidth: 2)),
              ],
            ),
            const SizedBox(height: 15),

            Wrap(
              spacing: 12, runSpacing: 12,
              children: ClinicHours.workingHours.map((hour) {
                bool isTaken = _takenHours.contains(hour);
                bool isSelected = _selectedHour == hour;
                return ChoiceChip(
                  label: Text(MyDateUtils.formatTime(hour)),
                  selected: isSelected,
                  onSelected: isTaken ? null : (v) => setState(() => _selectedHour = v ? hour : null),
                  selectedColor: AppTheme.primaryColor,
                  backgroundColor: Colors.white,
                  disabledColor: Colors.grey.shade100,
                  labelStyle: TextStyle(
                      color: isSelected ? Colors.white : (isTaken ? Colors.grey : AppTheme.darkText),
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal
                  ),
                  side: BorderSide(color: isTaken ? Colors.grey.shade300 : Colors.grey.shade200),
                );
              }).toList(),
            ),
            if (_takenHours.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text("Les créneaux grisés sont réservés.", style: Theme.of(context).textTheme.bodyMedium),
              ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: const Offset(0,-5))]),
        child: CustomButton(
          text: _selectedHour != null ? "Confirmer pour ${MyDateUtils.formatTime(_selectedHour!)}" : "Choisir une heure",
          onPressed: _selectedHour != null ? _showConfirmationSheet : null,
          isLoading: _isLoading,
        ),
      ),
    );
  }
}