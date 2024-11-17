import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:project/controller/ride_controller.dart';
import 'package:project/widgets/ride_box.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class JoinedRidesView extends StatefulWidget {
  const JoinedRidesView({Key? key}) : super(key: key);

  @override
  State<JoinedRidesView> createState() => _JoinedRidesViewState();
}

class _JoinedRidesViewState extends State<JoinedRidesView> {
  RideController rideController = Get.find<RideController>();
  bool loading = true;
  late Timer timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      rideController.getRidesIJoined();
      timer = Timer.periodic(const Duration(seconds: 1), (Timer t) {
        if(!rideController.isRidesLoading.value){
          rideController.getRidesIJoined();
          timer.cancel();
          setState((){
        loading = rideController.isRidesLoading.value;
        });
      }
    });
    });
  }

  @override
  void dispose() {
    super.dispose();
    timer.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() => rideController.isRequestLoading.value
        ? const Center(
            child: const CircularProgressIndicator(),
          )
        : ListView.builder(
            shrinkWrap: true,
            itemBuilder: (context, index) {
              DocumentSnapshot driver = rideController.allUsers.firstWhere(
                  (e) =>
                      rideController.ridesIJoined[index].get('driver') == e.id);

              return Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 13, horizontal: 2),
                  child: RideBox(
                    ride: rideController.ridesIJoined[index],
                    driver: driver,
                    showCarDetails: false,
                    shouldNavigate: true,
                  ));
            },
            itemCount: rideController.ridesIJoined.length,
          ));
  }
}
