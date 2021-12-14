import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  final String fullName;
  final GeoPoint location;
  final int mobile;
  final String userType;

  User({
    required this.fullName,
    required this.location,
    required this.mobile,
    required this.userType,
  });
}
