class ServerProfile {
  final String id;
  final String name;
  final String baseUrl;
  final String username;
  final bool savePassword;
  final bool autoLogin;

  const ServerProfile({
    required this.id,
    required this.name,
    required this.baseUrl,
    required this.username,
    this.savePassword = true,
    this.autoLogin = false,
  });

  ServerProfile copyWith({
    String? name,
    String? baseUrl,
    String? username,
    bool? savePassword,
    bool? autoLogin,
  }) {
    return ServerProfile(
      id: id,
      name: name ?? this.name,
      baseUrl: baseUrl ?? this.baseUrl,
      username: username ?? this.username,
      savePassword: savePassword ?? this.savePassword,
      autoLogin: autoLogin ?? this.autoLogin,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'baseUrl': baseUrl,
        'username': username,
        'savePassword': savePassword,
        'autoLogin': autoLogin,
      };

  factory ServerProfile.fromJson(Map<String, dynamic> json) => ServerProfile(
        id: json['id'] as String,
        name: json['name'] as String? ?? '',
        baseUrl: json['baseUrl'] as String,
        username: json['username'] as String? ?? '',
        savePassword: json['savePassword'] as bool? ?? true,
        autoLogin: json['autoLogin'] as bool? ?? false,
      );
}
