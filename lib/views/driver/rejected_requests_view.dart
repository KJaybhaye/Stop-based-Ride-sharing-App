import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:project/controller/ride_controller.dart';
import 'package:project/widgets/ride_box.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class RejectedRequestsView extends StatefulWidget {
  const RejectedRequestsView({Key? key}) : super(key: key);

  @override
  State<RejectedRequestsView> createState() => _RejectedRequestsViewState();
}

class _RejectedRequestsViewState extends State<RejectedRequestsView> {
  RideController rideController = Get.find<RideController>();
  bool loading = true;
  late Timer timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      rideController.getMyRequests();
      rideController.getRejectedRequests();
      timer = Timer.periodic(const Duration(seconds: 1), (Timer t) {
        if(!rideController.isRequestLoading.value){
          rideController.getRejectedRequests();
          timer.cancel();
          setState((){
        loading = rideController.isRequestLoading.value;
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
        ? Center(
            child: CircularProgressIndicator(),
          )
        : ListView.builder(
            shrinkWrap: true,
            itemBuilder: (context, index) {
              DocumentSnapshot user = rideController.allUsers.firstWhere((e) =>
                  rideController.rejectedRequests[index].get('user_id') ==
                  e.id);

              DocumentSnapshot ride = rideController.allRides.firstWhere((e) =>
                  rideController.rejectedRequests[index].get('ride_id') ==
                  e.id);

              return Padding(
                  padding: EdgeInsets.symmetric(vertical: 13, horizontal: 2),
                  child: RideBox(
                    ride: ride,
                    driver: user,
                    showCarDetails: false,
                    request: rideController.rejectedRequests[index],
                  ));
            },
            itemCount: rideController.rejectedRequests.length,
          ));
  }
}
