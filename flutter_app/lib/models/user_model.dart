class UserModel {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;

  UserModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
  });

  String get fullName {
    final combined = '$firstName $lastName'.trim();
    return combined.isNotEmpty ? combined : (email.isNotEmpty ? email.split('@').first : 'Customer');
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    String fName = json['first_name']?.toString() ?? json['firstName']?.toString() ?? '';
    String lName = json['last_name']?.toString() ?? json['lastName']?.toString() ?? '';

    if (fName.isEmpty && json['name'] != null && json['name'].toString().isNotEmpty) {
      final parts = json['name'].toString().trim().split(' ');
      fName = parts.first;
      if (parts.length > 1) {
        lName = parts.sublist(1).join(' ');
      }
    }

    return UserModel(
      id: json['id']?.toString() ?? '',
      firstName: fName,
      lastName: lName,
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': fullName,
    'first_name': firstName,
    'last_name': lastName,
    'email': email,
    'phone': phone,
  };

  UserModel copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
  }) {
    return UserModel(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
    );
  }
}
