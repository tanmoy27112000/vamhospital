import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vamhospital/constant/data.dart';
import 'package:vamhospital/model/user.dart';

class FirestoreService {
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  CollectionReference users = FirebaseFirestore.instance.collection('users');

  //get all user documents
  getAllUserDocs() async {
    allUsers = [];
    await users.get().then(
      (QuerySnapshot snapshot) {
        for (var f in snapshot.docs) {
          // ignore: avoid_print
          Map user = f.data() as Map;
          allUsers.add(
            User(
              fullName: user["fullName"] ?? "",
              location: user["location"],
              mobile: user["mobile"] == null
                  ? 0
                  : int.parse(user["mobile"].toString()),
              userType: user["userType"] ?? "",
            ),
          );
        }
      },
    );
  }
}
