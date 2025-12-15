class MyDateUtils {
  // Formater la date pour l'affichage
  static String formatDate(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
  }

  // Formater l'heure
  static String formatTime(int hour) {
    return "${hour.toString().padLeft(2, '0')}:00";
  }

  // Vérifier si deux dates sont le même jour
  static bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }
}