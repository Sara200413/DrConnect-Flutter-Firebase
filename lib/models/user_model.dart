class UserModel {
  final String uid;
  final String email;
  final String fullName;
  final String phoneNumber;
  final String role;

  UserModel({
    required this.uid,
    required this.email,
    required this.fullName,
    required this.phoneNumber,
    required this.role,
  });
  // Convertir vers Firebase (Objet -> Map)

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'role': role,
    };
  }
  // Convertir depuis Firebase
  factory UserModel.fromMap(Map<String, dynamic> data, String uid) {
    return UserModel(
      uid: uid,
      email: data['email'] ?? '',
      fullName: data['fullName'] ?? '',
      phoneNumber: data['phoneNumber'] ?? '',
      role: data['role'] ?? 'patient',
    );
  }
}