import 'package:cloud_firestore/cloud_firestore.dart';

class UserStruct {
  final String? email;
  final String? displayName;
  final String? photoUrl;
  final String? uid;
  final DateTime? createdTime;
  final String? phoneNumber;
  final String? userName;
  final List<DocumentReference>? followingUsers;

  UserStruct({
    this.email,
    this.displayName,
    this.photoUrl,
    this.uid,
    this.createdTime,
    this.phoneNumber,
    this.userName,
    this.followingUsers,
  });

  factory UserStruct.fromMap(Map<String, dynamic> data) {
    return UserStruct(
      email: data['email'] as String?,
      displayName: data['display_name'] as String?,
      photoUrl: data['photo_url'] as String?,
      uid: data['uid'] as String?,
      createdTime: data['created_time'] as DateTime?,
      phoneNumber: data['phone_number'] as String?,
      userName: data['user_name'] as String?,
      followingUsers: (data['following_users'] as List<dynamic>?)
          ?.cast<DocumentReference>(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'display_name': displayName,
      'photo_url': photoUrl,
      'uid': uid,
      'created_time': createdTime,
      'phone_number': phoneNumber,
      'user_name': userName,
      'following_users': followingUsers,
    };
  }
}
