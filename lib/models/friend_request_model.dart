import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

enum FriendRequestStatus {
  pending,
  accepted,
  rejected,
}

class FriendRequestModel {
  final String id;
  final String senderId;
  final String receiverId;
  final DateTime createdAt;
  final FriendRequestStatus status;
  final String? senderName;
  final String? senderEmail;
  final String? senderPhotoUrl;
  final String? receiverName;
  final String? receiverEmail;
  final String? receiverPhotoUrl;

  FriendRequestModel({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.createdAt,
    required this.status,
    this.senderName,
    this.senderEmail,
    this.senderPhotoUrl,
    this.receiverName,
    this.receiverEmail,
    this.receiverPhotoUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'senderId': senderId,
      'receiverId': receiverId,
      'createdAt': createdAt,
      'status': status.toString().split('.').last,
      'senderName': senderName,
      'senderEmail': senderEmail,
      'senderPhotoUrl': senderPhotoUrl,
      'receiverName': receiverName,
      'receiverEmail': receiverEmail,
      'receiverPhotoUrl': receiverPhotoUrl,
    };
  }

  factory FriendRequestModel.fromMap(Map<String, dynamic> map) {
    try {
      // Parse status from string
      FriendRequestStatus parseStatus(String? statusStr) {
        if (statusStr == 'accepted') return FriendRequestStatus.accepted;
        if (statusStr == 'rejected') return FriendRequestStatus.rejected;
        return FriendRequestStatus.pending;
      }

      // Parse timestamp to DateTime
      DateTime parseTimestamp(dynamic timestamp) {
        if (timestamp is Timestamp) {
          return timestamp.toDate();
        } else if (timestamp is DateTime) {
          return timestamp;
        }
        return DateTime.now();
      }

      return FriendRequestModel(
        id: map['id'] ?? '',
        senderId: map['senderId'] ?? '',
        receiverId: map['receiverId'] ?? '',
        createdAt: parseTimestamp(map['createdAt']),
        status: parseStatus(map['status']),
        senderName: map['senderName'],
        senderEmail: map['senderEmail'],
        senderPhotoUrl: map['senderPhotoUrl'],
        receiverName: map['receiverName'],
        receiverEmail: map['receiverEmail'],
        receiverPhotoUrl: map['receiverPhotoUrl'],
      );
    } catch (e) {
      debugPrint('Error parsing FriendRequestModel: $e');
      return FriendRequestModel(
        id: map['id'] ?? '',
        senderId: map['senderId'] ?? '',
        receiverId: map['receiverId'] ?? '',
        createdAt: DateTime.now(),
        status: FriendRequestStatus.pending,
      );
    }
  }

  factory FriendRequestModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FriendRequestModel.fromMap({
      ...data,
      'id': doc.id,
    });
  }

  FriendRequestModel copyWith({
    String? id,
    String? senderId,
    String? receiverId,
    DateTime? createdAt,
    FriendRequestStatus? status,
    String? senderName,
    String? senderEmail,
    String? senderPhotoUrl,
    String? receiverName,
    String? receiverEmail,
    String? receiverPhotoUrl,
  }) {
    return FriendRequestModel(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      senderName: senderName ?? this.senderName,
      senderEmail: senderEmail ?? this.senderEmail,
      senderPhotoUrl: senderPhotoUrl ?? this.senderPhotoUrl,
      receiverName: receiverName ?? this.receiverName,
      receiverEmail: receiverEmail ?? this.receiverEmail,
      receiverPhotoUrl: receiverPhotoUrl ?? this.receiverPhotoUrl,
    );
  }
}
