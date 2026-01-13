import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:doctor_appointment_app/core/themes/app_theme.dart';
import 'package:doctor_appointment_app/widgets/shared/custom_button.dart';
import 'package:doctor_appointment_app/widgets/shared/custom_text_field.dart';
import 'package:doctor_appointment_app/core/utils/ validators.dart';

class DoctorProfileEditScreen extends StatefulWidget {
  const DoctorProfileEditScreen({Key? key}) : super(key: key);

  @override
  State<DoctorProfileEditScreen> createState() => _DoctorProfileEditScreenState();
}

class _DoctorProfileEditScreenState extends State<DoctorProfileEditScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _specialtyController = TextEditingController();
  final TextEditingController _clinicController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();

  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic));

    _loadUserData();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _specialtyController.dispose();
    _clinicController.dispose();
    _addressController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      String uid = FirebaseAuth.instance.currentUser!.uid;
      DocumentSnapshot doc = await FirebaseFirestore.instance.collection('doctors').doc(uid).get();

      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        setState(() {
          _specialtyController.text = data['specialty'] == 'Non spécifié' ? '' : data['specialty'] ?? '';
          _clinicController.text = data['clinicName'] == 'Non spécifié' ? '' : data['clinicName'] ?? '';
          _addressController.text = data['address'] ?? '';
          _priceController.text = (data['price'] ?? 0).toString();
        });
      }
    } catch (e) {
      debugPrint("Erreur chargement: $e");
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      String uid = FirebaseAuth.instance.currentUser!.uid;

      await FirebaseFirestore.instance.collection('doctors').doc(uid).update({
        'specialty': _specialtyController.text.trim(),
        'clinicName': _clinicController.text.trim(),
        'address': _addressController.text.trim(),
        'price': double.tryParse(_priceController.text) ?? 0,
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Profil mis à jour avec succès !"),
          backgroundColor: AppTheme.successColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(20),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erreur lors de la sauvegarde: $e"),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final bool isWide = constraints.maxWidth > 600;

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildSliverAppBar(context),

              SliverToBoxAdapter(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: isWide ? 600 : double.infinity),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _buildInfoCard(),
                                const SizedBox(height: 24),
                                _buildFormSection(),
                                const SizedBox(height: 32),
                                CustomButton(
                                  text: "ENREGISTRER LES MODIFICATIONS",
                                  onPressed: _isLoading ? null : _saveProfile,
                                  isLoading: _isLoading,
                                ),
                                // Espace supplémentaire pour le clavier et les petits écrans
                                const SizedBox(height: 100),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 160,
      pinned: true,
      elevation: 0,
      stretch: true,
      backgroundColor: AppTheme.primaryColor,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground],
        centerTitle: true,
        title: const Text(
          'Mon Profil',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppTheme.primaryColor, Color(0xFF1D4ED8)],
            ),
          ),
          child: Opacity(
            opacity: 0.2,
            child: const Icon(Icons.badge_rounded, size: 100, color: Colors.white),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: AppTheme.primaryColor, size: 28),
          const SizedBox(width: 16),
          const Expanded(
            child: Text(
              'Ces informations permettent aux patients de vous trouver facilement.',
              style: TextStyle(color: Color(0xFF1E40AF), fontSize: 13, height: 1.4, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          CustomTextField(
            controller: _specialtyController,
            label: "Votre Spécialité",
            icon: Icons.local_hospital_rounded,
            validator: (v) => Validators.validateRequired(v, "Spécialité"),
          ),
          const SizedBox(height: 20),
          CustomTextField(
            controller: _clinicController,
            label: "Nom du cabinet",
            icon: Icons.business_rounded,
            validator: (v) => Validators.validateRequired(v, "Cabinet"),
          ),
          const SizedBox(height: 20),
          CustomTextField(
            controller: _addressController,
            label: "Adresse complète",
            icon: Icons.location_on_rounded,
            validator: (v) => Validators.validateRequired(v, "Adresse"),
          ),
          const SizedBox(height: 20),
          CustomTextField(
            controller: _priceController,
            label: "Prix consultation (DH)",
            icon: Icons.payments_rounded,
            keyboardType: TextInputType.number,
            validator: (v) => Validators.validateRequired(v, "Prix"),
          ),
        ],
      ),
    );
  }
}