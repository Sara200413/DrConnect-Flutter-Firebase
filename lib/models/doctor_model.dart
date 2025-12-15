class DoctorModel {
  final String uid;
  final String fullName;
  final String specialty;
  final String clinicName;
  final String address;
  final double price;
  final String bio;

  DoctorModel({
    required this.uid,
    required this.fullName,
    required this.specialty,
    required this.clinicName,
    required this.address,
    required this.price,
    this.bio = '',
  });

  // Convertir vers Firebase
  Map<String, dynamic> toMap() {
    return {
      'fullName': fullName,
      'specialty': specialty,
      'clinicName': clinicName,
      'address': address,
      'price': price,
      'bio': bio,
    };
  }
  factory DoctorModel.fromMap(Map<String, dynamic> data, String uid) {
    return DoctorModel(
      uid: uid,
      fullName: data['fullName'] ?? '',
      specialty: data['specialty'] ?? 'Généraliste',
      clinicName: data['clinicName'] ?? '',
      address: data['address'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      bio: data['bio'] ?? 'Non renseigné',
    );
  }
}