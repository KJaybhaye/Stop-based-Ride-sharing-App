import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:project/controller/ride_controller.dart';
import 'package:project/widgets/ride_box.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PendingRequestsView extends StatefulWidget {
  const PendingRequestsView({Key? key}) : super(key: key);

  @override
  State<PendingRequestsView> createState() => _PendingRequestsViewState();
}

class _PendingRequestsViewState extends State<PendingRequestsView> {
  RideController rideController = Get.find<RideController>();
  bool loading = true;
  late Timer timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      rideController.getMyRequests();
      rideController.getPendingRequests();
      timer = Timer.periodic(const Duration(seconds: 1), (Timer t) {
        if(!rideController.isRequestLoading.value){
          rideController.getPendingRequests();
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
              bool one = rideController.allUsers.any((e) =>
                  rideController.pendingRequests[index].get('user_id') == e.id);
              print(one);
              bool two = rideController.allRides.any((e) =>
                  rideController.pendingRequests[index].get('ride_id') == e.id);
              print(two);
              if(!one || !two){
                return null;
              }
              DocumentSnapshot user = rideController.allUsers.firstWhere((e) =>
                  rideController.pendingRequests[index].get('user_id') == e.id) ;

              DocumentSnapshot ride = rideController.allRides.firstWhere((e) =>
                  rideController.pendingRequests[index].get('ride_id') == e.id);
              
              return Padding(
                  padding: EdgeInsets.symmetric(vertical: 13, horizontal: 2),
                  child: RideBox(
                    ride: ride,
                    driver: user,
                    showCarDetails: false,
                    showOptions: true,
                    request: rideController.pendingRequests[index],
                  ));
            },
            itemCount: rideController.pendingRequests.length,
          ));
  }
}
