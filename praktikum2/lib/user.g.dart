// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

User _$UserFromJson(Map json) {
  $checkKeys(
    json,
    requiredKeys: const ['id', 'name', 'email', 'createdAt'],
    disallowNullValues: const ['id', 'name', 'email'],
  );
  return User(
    id: (json['id'] as num).toInt(),
    name: json['name'] as String,
    email: json['email'] as String,
    createdAt: User._parseDateTime(json['createdAt']),
  );
}

Map<String, dynamic> _$UserToJson(User instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'email': instance.email,
  'createdAt': User._dateTimeToJson(instance.createdAt),
};
