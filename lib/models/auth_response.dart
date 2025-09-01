import 'user_model.dart';

class AuthResponse {
  final User user;
  final String token;
  final String tokenType;

  AuthResponse({
    required this.user,
    required this.token,
    required this.tokenType,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      user: User.fromJson(json['user']),
      token: json['token'] ?? '',
      tokenType: json['token_type'] ?? 'Bearer',
    );
  }

  Map<String, dynamic> toJson() {
    return {'user': user.toJson(), 'token': token, 'token_type': tokenType};
  }

  @override
  String toString() {
    return 'AuthResponse{user: $user, token: ${token.length > 10 ? token.substring(0, 10) + "..." : token}, tokenType: $tokenType}';
  }
}
