class User {
  final int? id;
  final String? name;
  final String? email;
  final DateTime? createdAt;

  // Constructor
  // Gunakan named parameters agar kode lebih mudah dibaca
User({this.id, this.name, this.email, this.createdAt});

  // Factory Constructor untuk Deserialisasi (JSON -> Object)
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: _parseInt(json['id']),
      name: _parseString(json['name']),
      email: _parseString(json['email']),
      createdAt: _parseDateTime(
        // Handle both 'created_at' (snake_case) and 'createdAt' (camelCase)
        json['created_at'] ?? json['createdAt'],
      ),
    );
  }

  // --- Helper Static Methods for Parsing ---

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    if (value is num) return value.toInt();
    return null;
  }

  static String? _parseString(dynamic value) {
    if (value == null) return null;
    if (value is String) return value;
    // Pengecekan tambahan: jika bukan String/null, konversi ke String
    return value.toString();
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        return null; // Return null on parse error
      }
    }
    return null;
  }

  // --- Utility Methods ---

  // Method toJson untuk Serialisasi (Object -> JSON)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      // Convert DateTime to ISO 8601 String format
      'created_at': createdAt?.toIso8601String(),
    };
  }

  // Method copyWith untuk Immutability
  User copyWith({
    int? id,
    String? name,
    String? email,
    DateTime? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // Getter untuk Validasi
  bool get isValid => id != null && name != null && name!.isNotEmpty;

  // --- Overrides for Debugging and Equality ---

  // Override toString untuk debugging
  @override
  String toString() {
    return 'SafeUser(id: $id, name: $name, email: $email, createdAt: $createdAt)';
  }

  // Override operator == untuk perbandingan nilai (Content Equality)
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is User &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          email == other.email &&
          createdAt == other.createdAt;

  // Override hashCode, wajib jika operator == di-override
  @override
  int get hashCode =>
      id.hashCode ^ name.hashCode ^ email.hashCode ^ createdAt.hashCode;
}