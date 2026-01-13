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
    DateTime tomorrow = DateTime.now().add(const Duration(days: 1));
    if (tomorrow.weekday == ClinicHours.closedDay) {
      tomorrow = tomorrow.add(const Duration(days: 1));
    }
    _selectedDate = tomorrow;
    _checkAvailability();
  }

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

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().add(const Duration(days: 1)),
      lastDate: DateTime(2030),
      selectableDayPredicate: (day) => day.weekday != ClinicHours.closedDay,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFF2563EB)),
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

  void _showConfirmationSheet() {
    if (_selectedHour == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(backgroundColor: Colors.red, content: Text("Veuillez choisir une heure")));
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)))),
            const SizedBox(height: 24),
            const Text("Récapitulatif", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
            const SizedBox(height: 20),
            _summaryRow(Icons.person_rounded, "Docteur", "Dr. ${widget.doctorData['fullName']}"),
            _summaryRow(Icons.calendar_month_rounded, "Date", MyDateUtils.formatDate(_selectedDate)),
            _summaryRow(Icons.access_time_filled_rounded, "Heure", MyDateUtils.formatTime(_selectedHour!)),
            _summaryRow(Icons.payments_rounded, "Tarif", "${widget.doctorData['price']} DH"),
            const SizedBox(height: 24),
            CustomButton(
              onPressed: () {
                Navigator.pop(context);
                _processBooking();
              },
              text: "CONFIRMER",
            ),
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
          Icon(icon, color: const Color(0xFF2563EB), size: 18),
          const SizedBox(width: 12),
          Text("$label: ", style: const TextStyle(color: Color(0xFF64748B), fontSize: 13)),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B)), overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }

  Future<void> _processBooking() async {
    setState(() => _isLoading = true);
    try {
      DateTime finalDate = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, _selectedHour!, 0);
      var check = await FirebaseFirestore.instance
          .collection('appointments')
          .where('doctorId', isEqualTo: widget.doctorId)
          .where('date', isEqualTo: Timestamp.fromDate(finalDate))
          .get();

      if (check.docs.any((d) => d['status'] != 'cancelled')) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(backgroundColor: Colors.red, content: Text("Ce créneau est déjà pris.")));
        _checkAvailability();
        return;
      }

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

      if (!mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          icon: const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 50),
          title: const Text("Envoyé !"),
          content: const Text("En attente de validation par le docteur."),
          actions: [
            TextButton(onPressed: () { Navigator.pop(ctx); Navigator.pop(context); }, child: const Text("OK")),
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
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isSmallScreen = screenWidth < 360;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 100,
            pinned: true,
            elevation: 0,
            backgroundColor: const Color(0xFF2563EB),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: const FlexibleSpaceBar(
              centerTitle: true,
              title: Text("Réservation", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              background: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)]),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(isSmallScreen ? 16.0 : 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDoctorHeader(isSmallScreen),
                  const SizedBox(height: 24),
                  const Text("1. Choisir la date", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                  const SizedBox(height: 12),
                  _buildDatePickerButton(isSmallScreen),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("2. Heures disponibles", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                      if (_isLoading) const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildTimeSlotsGrid(isSmallScreen, screenWidth),
                  const SizedBox(height: 120),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomAction(),
    );
  }

  Widget _buildDoctorHeader(bool isSmall) {
    return Container(
      padding: EdgeInsets.all(isSmall ? 16 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 15)],
      ),
      child: Row(
        children: [
          Container(
            height: isSmall ? 50 : 60, width: isSmall ? 50 : 60,
            decoration: BoxDecoration(color: const Color(0xFF2563EB).withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
            child: Icon(Icons.person_rounded, color: const Color(0xFF2563EB), size: isSmall ? 28 : 32),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Dr. ${widget.doctorData['fullName']}", style: TextStyle(fontSize: isSmall ? 16 : 18, fontWeight: FontWeight.bold)),
                Text(widget.doctorData['specialty'] ?? "Médecin", style: const TextStyle(color: Color(0xFF2563EB), fontSize: 12, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDatePickerButton(bool isSmall) {
    return InkWell(
      onTap: _pickDate,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: EdgeInsets.all(isSmall ? 12 : 16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE2E8F0))),
        child: Row(
          children: [
            const Icon(Icons.calendar_month_rounded, color: Color(0xFF2563EB), size: 20),
            const SizedBox(width: 12),
            Text(MyDateUtils.formatDate(_selectedDate), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const Spacer(),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSlotsGrid(bool isSmall, double width) {
    // Calcul de la largeur d'un slot pour qu'il s'adapte à l'écran
    double slotWidth = (width - (isSmall ? 32 : 48) - 24) / 3;

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: ClinicHours.workingHours.map((hour) {
        bool isTaken = _takenHours.contains(hour);
        bool isSelected = _selectedHour == hour;
        return InkWell(
          onTap: isTaken ? null : () => setState(() => _selectedHour = hour),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: slotWidth,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF2563EB) : (isTaken ? const Color(0xFFF1F5F9) : Colors.white),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0)),
            ),
            child: Center(
              child: Text(
                MyDateUtils.formatTime(hour),
                style: TextStyle(color: isSelected ? Colors.white : (isTaken ? Colors.grey : Colors.black), fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBottomAction() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Color(0xFFF1F5F9)))),
      child: CustomButton(
        text: _selectedHour != null ? "RÉSERVER À ${MyDateUtils.formatTime(_selectedHour!)}" : "CHOISIR UNE HEURE",
        onPressed: _selectedHour != null ? _showConfirmationSheet : null,
        isLoading: _isLoading,
      ),
    );
  }
}