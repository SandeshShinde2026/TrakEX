import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class GroupModel {
  final String id;
  final String name;
  final String createdBy;
  final List<String> memberIds;
  final DateTime createdAt;
  final DateTime updatedAt;

  GroupModel({
    required this.id,
    required this.name,
    required this.createdBy,
    required this.memberIds,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'createdBy': createdBy,
      'memberIds': memberIds,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory GroupModel.fromMap(Map<String, dynamic> map) {
    try {
      // Parse timestamp to DateTime
      DateTime parseTimestamp(dynamic timestamp) {
        if (timestamp is Timestamp) {
          return timestamp.toDate();
        } else if (timestamp is DateTime) {
          return timestamp;
        }
        return DateTime.now();
      }

      return GroupModel(
        id: map['id'] ?? '',
        name: map['name'] ?? '',
        createdBy: map['createdBy'] ?? '',
        memberIds: List<String>.from(map['memberIds'] ?? []),
        createdAt: parseTimestamp(map['createdAt']),
        updatedAt: parseTimestamp(map['updatedAt']),
      );
    } catch (e) {
      debugPrint('Error parsing GroupModel: $e');
      return GroupModel(
        id: map['id'] ?? '',
        name: map['name'] ?? '',
        createdBy: map['createdBy'] ?? '',
        memberIds: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }
  }

  factory GroupModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return GroupModel.fromMap({
      ...data,
      'id': doc.id,
    });
  }

  GroupModel copyWith({
    String? id,
    String? name,
    String? createdBy,
    List<String>? memberIds,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return GroupModel(
      id: id ?? this.id,
      name: name ?? this.name,
      createdBy: createdBy ?? this.createdBy,
      memberIds: memberIds ?? this.memberIds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GroupModel &&
        other.id == id &&
        other.name == name &&
        other.createdBy == createdBy &&
        listEquals(other.memberIds, memberIds);
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        createdBy.hashCode ^
        memberIds.hashCode;
  }

  @override
  String toString() {
    return 'GroupModel(id: $id, name: $name, createdBy: $createdBy, memberIds: $memberIds, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  // Utility methods
  bool isMember(String userId) {
    return memberIds.contains(userId);
  }

  bool isCreator(String userId) {
    return createdBy == userId;
  }

  int get memberCount => memberIds.length;
}
