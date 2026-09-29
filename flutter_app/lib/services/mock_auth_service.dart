import '../models/user_model.dart';

class MockAuthService {
  static UserModel? _currentUser;
  static final List<UserModel> _registeredUsers = [];

  static UserModel? get currentUser => _currentUser;
  static bool get isLoggedIn => _currentUser != null;
  static void setCurrentUser(UserModel user) => _currentUser = user;

  static Future<Map<String, dynamic>> register({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String password,
  }) async {
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 1000));

    bool exists = _registeredUsers.any((u) => u.email.toLowerCase() == email.toLowerCase());
    if (exists) {
      return {'success': false, 'message': 'Email address is already registered.'};
    }

    final newUser = UserModel(
      id: 'usr_${DateTime.now().millisecondsSinceEpoch}',
      firstName: firstName,
      lastName: lastName,
      email: email,
      phone: phone,
    );

    _registeredUsers.add(newUser);
    _currentUser = newUser;

    return {'success': true, 'message': 'Account created successfully!', 'user': newUser};
  }

  static Future<Map<String, dynamic>> login(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 900));
    final user = _registeredUsers.firstWhere(
      (u) => u.email.toLowerCase() == email.toLowerCase(),
      orElse: () => UserModel(id: 'usr_demo', firstName: 'John', lastName: 'Doe', email: email, phone: '+1 555-0199'),
    );
    _currentUser = user;
    return {'success': true, 'message': 'Welcome back!', 'user': user};
  }

  static void logout() {
    _currentUser = null;
  }
}
