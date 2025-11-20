import 'package:json_annotation/json_annotation.dart';

part 'user.g.dart';

@JsonSerializable(explicitToJson: true, anyMap: true)
class User {
  @JsonKey(required: true, disallowNullValue: true)
  final int id;

  @JsonKey(required: true, disallowNullValue: true)
  final String name;

  @JsonKey(required: true, disallowNullValue: true)
  final String email;

  @JsonKey(
    name: 'createdAt',
    required: true,
    fromJson: _parseDateTime,
    toJson: _dateTimeToJson,
  )
  final DateTime createdAt;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.createdAt,
  });

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    if (value is String) return DateTime.parse(value);
    return DateTime.now();
  }

  static String _dateTimeToJson(DateTime date) => date.toIso8601String();

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);

  Map<String, dynamic> toJson() => _$UserToJson(this);
}
