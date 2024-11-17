import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:project/controller/ride_controller.dart';
import 'package:project/widgets/ride_box.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HistoryRidesForDriver extends StatefulWidget {
  const HistoryRidesForDriver({Key? key}) : super(key: key);

  @override
  State<HistoryRidesForDriver> createState() => _HistoryRidesForDriverState();
}

class _HistoryRidesForDriverState extends State<HistoryRidesForDriver> {
  RideController rideController = Get.find<RideController>();
  bool loading = true;
  late Timer timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      rideController.getRidesICancelled();
      rideController.getRidesIEnded();
      rideController.getRideHistoryForDriver();
      rideController.getMyDocument();
    });
    timer = Timer.periodic(const Duration(seconds: 1), (Timer t) {
        if(!rideController.isRidesLoading.value){
          rideController.getRideHistoryForDriver();
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
                padding: EdgeInsets.symmetric(vertical: 13, horizontal: 2),
                child: RideBox(
                  ride: rideController.driverHistory[index],
                  driver: driver,
                  showCarDetails: false,
                  shouldNavigate: true,
                  hasEnded: true,
                ));
          },
          itemCount: rideController.driverHistory.length,
        ));
  }
}
