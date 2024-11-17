import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:project/controller/ride_controller.dart';
import 'package:project/widgets/ride_box.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class OngoingRideForDriver extends StatefulWidget {
  const OngoingRideForDriver({Key? key}) : super(key: key);

  @override
  State<OngoingRideForDriver> createState() => _OngoingRideForDriverState();
}

class _OngoingRideForDriverState extends State<OngoingRideForDriver> {
  RideController rideController = Get.find<RideController>();
  bool loading = true;
  late Timer timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      rideController.getOngoingRideForDriver();
      rideController.getMyDocument();
    });
    timer = Timer.periodic(const Duration(seconds: 1), (Timer t) {
        if(!rideController.isRidesLoading.value){
          rideController.getOngoingRideForDriver();
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
            DocumentSnapshot driver = rideController.myDocument!;

            return Padding(
                padding: EdgeInsets.symmetric(vertical: 13),
                child: RideBox(
                  ride: rideController.driverCurrentRide[index],
                  driver: driver,
                  showCarDetails: false,
                  shouldNavigate: true,
                  showStartOption: true,
                ));
          },
          itemCount: rideController.driverCurrentRide.length,
        ));
  }
}
