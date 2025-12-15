import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:doctor_appointment_app/core/themes/app_theme.dart';
import 'package:doctor_appointment_app/widgets/shared/custom_button.dart';
import 'package:doctor_appointment_app/widgets/shared/custom_text_field.dart';
import '../../core/utils/ validators.dart';

class DoctorProfileEditScreen extends StatefulWidget {
  const DoctorProfileEditScreen({Key? key}) : super(key: key);

  @override
  State<DoctorProfileEditScreen> createState() => _DoctorProfileEditScreenState();
}

class _DoctorProfileEditScreenState extends State<DoctorProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _specialtyController = TextEditingController();
  final TextEditingController _clinicController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // Charger les données actuelles depuis Firestore
  Future<void> _loadUserData() async {
    String uid = FirebaseAuth.instance.currentUser!.uid;
    DocumentSnapshot doc = await FirebaseFirestore.instance.collection('doctors').doc(uid).get();

    if (doc.exists) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      setState(() {
        _specialtyController.text = data['specialty'] == 'Non spécifié' ? '' : data['specialty'] ?? '';
        _clinicController.text = data['clinicName'] == 'Non spécifié' ? '' : data['clinicName'] ?? '';
        _addressController.text = data['address'] ?? '';
        _priceController.text = data['price'].toString();
      });
    }
  }

  // Sauvegarder les modifications
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      String uid = FirebaseAuth.instance.currentUser!.uid;

      await FirebaseFirestore.instance.collection('doctors').doc(uid).update({
        'specialty': _specialtyController.text,
        'clinicName': _clinicController.text,
        'address': _addressController.text,
        'price': double.tryParse(_priceController.text) ?? 0,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profil mis à jour avec succès !"), backgroundColor: AppTheme.primaryColor),
      );
      Navigator.pop(context);
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
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text("Modifier mon Profil"),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.medical_services_outlined, size: 80, color: AppTheme.primaryColor),
                const SizedBox(height: 30),

                CustomTextField(
                  controller: _specialtyController,
                  label: "Spécialité",
                  icon: Icons.local_hospital_outlined,
                  validator: (v) => Validators.validateRequired(v, "Spécialité"),
                ),
                const SizedBox(height: 16),

                CustomTextField(
                  controller: _clinicController,
                  label: "Nom du Cabinet / Clinique",
                  icon: Icons.business_outlined,
                  validator: (v) => Validators.validateRequired(v, "Nom du Cabinet"),
                ),
                const SizedBox(height: 16),

                CustomTextField(
                  controller: _addressController,
                  label: "Adresse complète",
                  icon: Icons.location_on_outlined,
                  validator: (v) => Validators.validateRequired(v, "Adresse"),
                ),
                const SizedBox(height: 16),

                CustomTextField(
                  controller: _priceController,
                  label: "Prix Consultation (DH)",
                  icon: Icons.attach_money,
                  keyboardType: TextInputType.number,
                  validator: (v) => Validators.validateRequired(v, "Prix"),
                ),
                const SizedBox(height: 30),

                CustomButton(
                  text: "ENREGISTRER",
                  onPressed: _saveProfile,
                  isLoading: _isLoading,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}