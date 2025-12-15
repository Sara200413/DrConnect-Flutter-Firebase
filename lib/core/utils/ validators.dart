class Validators {
  // Valider l'email
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Veuillez entrer un email';
    }
    // Expression régulière pour vérifier le format email
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Format email invalide';
    }
    return null;
  }

  // Valider le mot de passe (min 6 caractères)
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Veuillez entrer un mot de passe';
    }
    if (value.length < 6) {
      return 'Au moins 6 caractères requis';
    }
    return null;
  }

  // Valider un champ requis (Nom, Téléphone...)
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return 'Le champ $fieldName est obligatoire';
    }
    return null;
  }
}