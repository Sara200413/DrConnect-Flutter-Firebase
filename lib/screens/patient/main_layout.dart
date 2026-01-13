import 'package:flutter/material.dart';
import '../../core/themes/app_theme.dart';
import 'patient_home_screen.dart';
import 'patient_appointments_screen.dart';
import 'profile_screen.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({Key? key}) : super(key: key);

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;

  // Liste des écrans
  final List<Widget> _screens = const [
    PatientHomeScreen(),
    PatientAppointmentsScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    // Récupération des dimensions pour adapter le design
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isSmallDevice = screenWidth < 360;

    return Scaffold(
      extendBody: true, // Le contenu passe derrière la barre flottante
      backgroundColor: const Color(0xFFF8FAFC),
      body: _screens[_currentIndex],
      bottomNavigationBar: _buildFloatingNavigationBar(screenWidth, isSmallDevice),
    );
  }

  Widget _buildFloatingNavigationBar(double width, bool isSmall) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isLargeScreen = constraints.maxWidth > 600;

        return Container(
          // Largeur adaptative : Plus l'écran est petit, plus les marges sont fines
          width: isLargeScreen ? 450 : double.infinity,
          margin: EdgeInsets.fromLTRB(
              isLargeScreen ? (constraints.maxWidth - 450) / 2 : (isSmall ? 12 : 20),
              0,
              isLargeScreen ? (constraints.maxWidth - 450) / 2 : (isSmall ? 12 : 20),
              isSmall ? 16 : 24 // Marge en bas
          ),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.96),
            borderRadius: BorderRadius.circular(isSmall ? 24 : 32),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2563EB).withOpacity(0.08),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
            border: Border.all(color: Colors.white.withOpacity(0.6), width: 1.5),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(isSmall ? 24 : 32),
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: isSmall ? 4 : 8, horizontal: 8),
              child: BottomNavigationBar(
                currentIndex: _currentIndex,
                onTap: (index) => setState(() => _currentIndex = index),
                backgroundColor: Colors.transparent,
                elevation: 0,
                selectedItemColor: const Color(0xFF2563EB),
                unselectedItemColor: const Color(0xFF94A3B8),
                showSelectedLabels: !isSmall, // Cacher le texte sur les micro-écrans
                showUnselectedLabels: false,
                type: BottomNavigationBarType.fixed,
                selectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                  letterSpacing: 0.1,
                ),
                items: [
                  _buildNavItem(Icons.home_rounded, Icons.home_outlined, 'Accueil', 0, isSmall),
                  _buildNavItem(Icons.calendar_month_rounded, Icons.calendar_month_outlined, 'Mes RDV', 1, isSmall),
                  _buildNavItem(Icons.person_rounded, Icons.person_outline_rounded, 'Profil', 2, isSmall),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  BottomNavigationBarItem _buildNavItem(IconData activeIcon, IconData inactiveIcon, String label, int index, bool isSmall) {
    bool isSelected = _currentIndex == index;
    return BottomNavigationBarItem(
      icon: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: EdgeInsets.all(isSmall ? 8 : 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2563EB).withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(isSmall ? 12 : 16),
        ),
        child: Icon(isSelected ? activeIcon : inactiveIcon, size: isSmall ? 22 : 26),
      ),
      label: label,
    );
  }
}