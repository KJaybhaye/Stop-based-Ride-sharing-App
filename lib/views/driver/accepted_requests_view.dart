import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:project/controller/ride_controller.dart';
import 'package:project/widgets/ride_box.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AcceptedRequestsView extends StatefulWidget {
  const AcceptedRequestsView({Key? key}) : super(key: key);

  @override
  State<AcceptedRequestsView> createState() => _AcceptedRequestsViewState();
}

class _AcceptedRequestsViewState extends State<AcceptedRequestsView> {
  RideController rideController = Get.find<RideController>();
  bool loading = true;
  late Timer timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      rideController.getMyRequests();
      rideController.getAcceptedRequests();
      timer = Timer.periodic(const Duration(seconds: 1), (Timer t) {
        if(!rideController.isRequestLoading.value){
          rideController.getAcceptedRequests();
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
                  rideController.acceptedRequests[index].get('user_id') ==
                  e.id);

              DocumentSnapshot ride = rideController.allRides.firstWhere((e) =>
                  rideController.acceptedRequests[index].get('ride_id') ==
                  e.id);

              return Padding(
                  padding: EdgeInsets.symmetric(vertical: 13, horizontal: 2),
                  child: RideBox(
                    ride: ride,
                    driver: user,
                    showCarDetails: false,
                    request: rideController.acceptedRequests[index],
                    showRejectOption: true,
                  ));
            },
            itemCount: rideController.acceptedRequests.length,
          ));
  }
}
