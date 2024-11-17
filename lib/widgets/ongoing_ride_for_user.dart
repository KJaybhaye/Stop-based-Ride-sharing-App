import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:project/controller/ride_controller.dart';
import 'package:project/widgets/ride_box.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class OngoingRideForUser extends StatefulWidget {
  const OngoingRideForUser({Key? key}) : super(key: key);

  @override
  State<OngoingRideForUser> createState() => _OngoingRideForUserState();
}

class _OngoingRideForUserState extends State<OngoingRideForUser> {
  RideController rideController = Get.find<RideController>();
  bool loading = true;
  late Timer timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      rideController.getRidesIJoined();
      rideController.getOngoingRideForUser();
      rideController.getMyDocument();
    });
    timer = Timer.periodic(const Duration(seconds: 1), (Timer t) {
        if(!rideController.isRidesLoading.value){
          rideController.getOngoingRideForUser();
          timer.cancel();
          setState((){
        loading = rideController.isRidesLoading.value;
        });
      }
    });
  }
  @override
  void dispose() {
    super.dispose();
    timer.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() => ListView.builder(
          shrinkWrap: true,
          itemBuilder: (context, index) {
            DocumentSnapshot driver = rideController.allUsers.firstWhere((e) =>
                rideController.userCurrentRide[index].get('driver') == e.id);

            return Padding(
                padding: EdgeInsets.symmetric(vertical: 13),
                child: RideBox(
                  ride: rideController.userCurrentRide[index],
                  driver: driver,
                  showCarDetails: false,
                  shouldNavigate: true,
                  showStartOption: true,
                ));
          },
          itemCount: rideController.userCurrentRide.length,
        ));
  }
}
