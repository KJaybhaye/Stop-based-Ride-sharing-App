import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:project/widgets/ride_box.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_obx_widget.dart';

import '../controller/ride_controller.dart';

class UpcomingRidesForUser extends StatefulWidget {
  const UpcomingRidesForUser({Key? key}) : super(key: key);

  @override
  State<UpcomingRidesForUser> createState() => _UpcomingRidesForUserState();
}

class _UpcomingRidesForUserState extends State<UpcomingRidesForUser> {
  RideController rideController = Get.find<RideController>();
  bool loading = true;
  late Timer timer;

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      rideController.getRidesIJoined();
      rideController.getUpcomingRidesForUser();
      rideController.getMyDocument();
    });
    timer = Timer.periodic(const Duration(seconds: 1), (Timer t) {
        if(!rideController.isRidesLoading.value){
          rideController.getUpcomingRidesForUser();
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
                rideController.upcomingRidesForUser[index].get('driver') ==
                e.id);

            return Padding(
                padding: EdgeInsets.symmetric(vertical: 13),
                child: RideBox(
                  ride: rideController.upcomingRidesForUser[index],
                  driver: driver,
                  showCarDetails: false,
                  shouldNavigate: true,
                  showCode: true,
                ));
          },
          itemCount: rideController.upcomingRidesForUser.length,
        ));
  }
}
