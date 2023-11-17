// import 'package:face_auth_flutter/models/user.dart';
// import 'package:hive_flutter/hive_flutter.dart';

// class HiveBoxes {
//   static const userDetails = "user_details";

//   static Box userDetailsBox() => Hive.box(userDetails);

//   static initialize() async {
//     await Hive.openBox(userDetails);
//   }

//   static clearAllBox() async {
//     await HiveBoxes.userDetailsBox().clear();
//   }
// }

// class LocalDB {
//   static User getUser() => User.fromJson(HiveBoxes.userDetailsBox().toMap());

//   static String getUserName() =>
//       HiveBoxes.userDetailsBox().toMap()[User.nameKey];

//   static String getUserArray() =>
//       HiveBoxes.userDetailsBox().toMap()[User.arrayKey];

//   static setUserDetails(User user) =>
//       HiveBoxes.userDetailsBox().putAll(user.toJson());
// }
import 'package:face_auth_flutter/models/user.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';

class HiveBoxes {
  static const userDetails = "user_details";

  static Box userDetailsBox() => Hive.box(userDetails);

  static initialize() async {
    final documentDirectory = await getApplicationDocumentsDirectory();
    Hive.init(documentDirectory.path);
    await Hive.openBox(userDetails);
  }

  static clearAllBox() async {
    await HiveBoxes.userDetailsBox().clear();
  }
}

class LocalDB {
  static List<User> getUser() {
    final map = HiveBoxes.userDetailsBox().toMap();
    // final listData = map.keys.map((e) => User.fromJson(e.toMap())).toList();
    List<User> listData = [];
    for (var element in map.keys) {
      listData.add(User.fromJson(map[element]));
    }
    return listData;
  }

  static String getUserName() => HiveBoxes.userDetailsBox().toMap()[User.nameKey];

  static String getUserArray() => HiveBoxes.userDetailsBox().toMap()[User.arrayKey];

  static setUserDetails(User user) => HiveBoxes.userDetailsBox().putAll({"${user.name}": user.toJson()});
}
