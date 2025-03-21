// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:project/controller/ride_controller.dart';
// import 'package:project/widgets/ride_box.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';

// class RidesCards extends StatefulWidget {
//   const RidesCards({Key? key}) : super(key: key);

//   @override
//   State<RidesCards> createState() => _RidesCardsState();
// }

// class _RidesCardsState extends State<RidesCards> {
//   RideController rideController = Get.find<RideController>();

//   @override
//   void initState() {
//     super.initState();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Obx(() => rideController.isRidesLoading.value
//         ? Center(
//             child: CircularProgressIndicator(),
//           )
//         : ListView.builder(
//             shrinkWrap: true,
//             itemBuilder: (context, index) {
//               DocumentSnapshot driver = rideController.allUsers.firstWhere(
//                   (e) => rideController.allRides[index].get('driver') == e.id);

//               return Padding(
//                   padding: EdgeInsets.symmetric(vertical: 13),
//                   child: RideBox(
//                       ride: rideController.allRides[index],
//                       driver: driver,
//                       showCarDetails: false));
//             },
//             itemCount: rideController.allRides.length,
//           ));
//   }
// }
